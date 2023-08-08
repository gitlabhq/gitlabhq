---
status: proposed
creation-date: "2023-03-07"
authors: [ "@ajwalker"  ]
coach: [ "@ayufan" ]
approvers: [ "@DarrenEastman", "@engineering-manager" ]
owning-stage: "~devops::<stage>"
participating-stages: []
---

# GitLab Runner Admissions Controller

The GitLab `admission controller` (inspired by the [Kubernetes admission controller concept](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)) is a proposed technical solution to intercept jobs before they're persisted or added to the build queue for execution.

An admission controller can be registered to the GitLab instance and receive a payload containing jobs to be created. Admission controllers can be _mutating_, _validating_, or both.

- When _mutating_, mutatable job information can be modified and sent back to the GitLab instance. Jobs can be modified to conform to organizational policy, security requirements, or have, for example, their tag list modified so that they're routed to specific runners.
- When _validating_, a job can be denied execution.

## Motivation

To comply with the segregation of duties, organizational policy, or security requirements, customers in financial services, the US federal government market segment, or other highly regulated industries must ensure that only authorized users can use runners associated with particular CI job environments.

In this context, using the term environments is not equivalent to the definition of the environment used in the GitLab CI environments and deployments documentation. Using the definition from the [SLSA guide](https://slsa.dev/spec/v0.1/terminology), an environment is the "machine, container, VM, or similar in which the job runs."

An additional requirement comes from the Remote Computing Enablement (RCE) group at [Lawrence Livermore National Laboratory](https://hpc.llnl.gov/). In this example, users must have a user ID on the target Runner CI build environment for the CI job to run. To simplify administration across the entire user base, RCE needs to be able to associate a Runner with a GitLab user entity.

### Current GitLab CI job handling mechanism

Before going further, it is helpful to level-set the current job handling mechanism in GitLab CI and GitLab Runners.

- First, a runner associated with a GitLab instance continuously queries the GitLab instance API to check if there is a new job that it could run.
- With every push to a project repository on GitLab with a `.gitlab-ci.yml` file present, the CI service present on the GitLab instance catches the event and triggers a new CI job.
- The CI job enters a pending state in the queue until a Runner requests a job from the instance.
- On the request from a runner to the API for a job, the database is queried to verify that the job parameters matches that of the runner. In other words, when runners poll a GitLab instance for a job to execute they're assigned a job if it matches the specified criteria.
- If the job matches the runner in question, then the GitLab instance connects the job to the runner and changes the job state to running. In other words, GitLab connects the `job` object with the `Runner` object.
- A runner can be configured to run un-tagged jobs. Tags are the primary mechanism used today to enable customers to have some control of which Runners run certain types of jobs.
- So while runners are scoped to the instance, group, or project, there are no additional access control mechanisms today that can easily be expanded on to deny access to a runner based on a user or group identifier.

The current CI jobs queue logic is as follows. **Note - in the code ww still use the very old `build` naming construct, but we've migrated from `build` to `job` in the product and documentation.

```ruby
jobs = 
  if runner.instance_type?
   jobs_for_shared_runner
  elsif runner.group_type?
    jobs_for_group_runner
  else
    jobs_for_project_runner
  end

# select only jobs that have tags known to the runner
jobs = jobs.matches_tag_ids(runner.tags.ids)

# select builds that have at least one tag if required
unless runner.run_untagged?
  jobs = jobs.with_any_tags
end

```

## Goals

- Implement an initial solution that provides an easy-to-configure and use mechanism to `allow`, `deny` or `redirect` CI job execution on a specific runner entity based on some basic job details (like user, group or project membership).

## Non-Goals

- A re-design of the CI job queueing mechanism is not in the scope of this blueprint.

## Proposal

Implement a mechanism, `admission controllers`, to intercept CI jobs, allowing them to either mutate jobs, validate them or do both. An admission controller is a mutating webhook that can modify the CI job or reject the job according to a policy. The webhook is called before the job is inserted into the CI jobs queue.

### Guiding principles

- The webhook payload schema will be part of our public facing APIs.
- We must maintain backwards compatibility when extending the webhook payload.
- Controllers should be idempotent.

### How will the admissions controller work?

**Scenario 1**: I want to deny access to a certain runner.

1. Configure an admissions controller to only accept jobs from specific projects.
1. When a job is created the `project information` (`project_id`, `job_id`, `api_token`) will be used to query GitLab for specific details.
1. If the `project information` matches the allow list, then the job payload is not modified and the job is able to run on the target runner.
1. If the `project information` does not match the allow list, then the job payload is not modified and the job is dropped.
1. The job tags are not changed.
1. Admission controller may optionally send back an arbitrary text description of why a decline decision was made.

**Scenario 2**: Large runner fleet with using a common configuration and tags.

Each runner has a tag such as `zone_a`, `zone_b`. In this scenario the customer does not know where a specific job can run as some users have access to `zone_a`, and some to `zone_b`. The customer does not want to fail a job that should run on `zone_a`, but instead redirect a job if it is not correctly tagged to run in `zone_a.`

1. Configure an admissions controller to mutate jobs based on `user_id`.
1. When a job is created the `project information` (`project_id`, `job_id`, `api_token`) will be used to query GitLab for specific details.
1. If the `user_id` matches then the admissions controller modifies the job tag list. `zone_a` is added to the tag list as the controller has detected that the user triggering the job should have their jobs run IN `zone_a`.

### MVC

#### Admission controller

1. A single admission controller can be registered at the instance level only.
1. The admission controller must respond within 30 seconds.
1. The admission controller will receive an array of individual jobs. These jobs may or may not be related to each other. The response must contain only responses to the jobs made as part of the request.

#### Job Lifecycle

1. The lifecycle of a job will be updated to include a new `validating` state.

   ```mermaid
   stateDiagram-v2
      created --> validating
      state validating {
          [*] --> accept
          [*] --> reject
      }
      reject --> failed
      accept --> pending
      pending --> running: picked by runner
      running --> executed
      state executed {
          [*] --> failed
          [*] --> success
          [*] --> canceled
      }
      executed --> created: retry
   ```

1. When the state is `validating`, the mutating webhook payload is sent to the admission controller.
1. For jobs where the webhook times out (30 seconds) their status should be set as though the admission was denied. This should
be rare in typical circumstances.
1. Jobs with denied admission can be retried. Retried jobs will be resent to the admission controller along with any mutations that they received previously.
1. [`allow_failure`](../../../ci/yaml/index.md#allow_failure) should be updated to support jobs that fail on denied admissions, for example:

   ```yaml
   job:
     script:
       - echo "I will fail admission"
     allow_failure:
       on_denied_admission: true
   ```

1. The UI should be updated to display the reason for any job mutations (if provided).
1. A table in the database should be created to store the mutations. Any changes that were made, like tags, should be persisted and attached to `ci_builds` with `acts_as_taggable :admission_tags`.

#### Payload

1. The payload is comprised of individual job entries consisting of:
   - Job ID.
   - [Predefined variables](../../../ci/variables/predefined_variables.md)
   - Job tag list.
1. The response payload is comprised of individual job entries consisting of:
   - Job ID.
   - Admission state: `accepted` or `denied`.
   - Mutations: Only `tags` is supported for now. The tags provided replaces the original tag list.
   - Reason: A controller can provide a reason for admission and mutation.

##### Example request

```json
[
  {
    "id": 123,
    "variables": {
      # predefined variables: https://docs.gitlab.com/ee/ci/variables/predefined_variables.html
      "CI_PROJECT_ID": 123,
      "CI_PROJECT_NAME": "something",
      "GITLAB_USER_ID": 98123,
      ...
    },
    "tags": [ "docker", "windows" ]
  },
  {
    "id": 245,
    "variables": {
      "CI_PROJECT_ID": 245,
      "CI_PROJECT_NAME": "foobar",
      "GITLAB_USER_ID": 98123,
      ...
    },
    "tags": [ "linux", "eu-west" ]
  },
  {
    "id": 666,
    "variables": {
      "CI_PROJECT_ID": 666,
      "CI_PROJECT_NAME": "do-bad-things",
      "GITLAB_USER_ID": 98123,
      ...
    },
    "tags": [ "secure-runner" ]
  },
]
```

##### Example response

```json
[
  {
    "id": 123,
    "admission": "accepted",
    "reason": "it's always-allow-day-wednesday"
  },
  {
    "id": 245,
    "admission": "accepted",
    "mutations": {
      "tags": [ "linux", "us-west" ]
    },
    "reason": "user is US employee: retagged region"
  },
  {
    "id": 666,
    "admission": "rejected",
    "reason": "you have no power here"
  },
]
```

### MVC +

1. Multiple admissions controllers on groups and project levels.
1. Passing job definition through a chain of the controllers (starting on the project, through all defined group controllers up to the instance controller).
1. Each level gets the definition modified by the previous controller in the chain and makes decisions based on the current state.
1. Modification reasons, if reported by multiple controllers, are concatenated.
1. Usage of the admission controller is optional, so we can have a chain containing project+instance, project+group+parent group+instance, project+group, group+instance, etc

### Implementation Details

1. _placeholder for steps required to code the admissions controller MVC_

## Technical issues to resolve

| issue | resolution|
| ------ | ------ |
|We may have conflicting tag-sets as mutating controller can make it possible to define AND, OR and NONE logical definition of tags. This can get quite complex quickly.     |        |
|Rule definition for the queue web hook|
|What data to send to the admissions controller? Is it a subset or all of the [predefined variables](../../../ci/variables/predefined_variables.md)?|
|Is the `queueing web hook` able to run at GitLab.com scale? On GitLab.com we would trigger millions of webhooks per second and the concern is that would overload Sidekiq or be used to abuse the system.
