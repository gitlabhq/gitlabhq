---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Control the job concurrency in GitLab CI/CD
title: Resource group
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

By default, pipelines in GitLab CI/CD run concurrently. Concurrency is an important factor to improve
the feedback loop in merge requests, however, there are some situations that
you may want to limit the concurrency on deployment
jobs to run them one by one.
Use resource groups to strategically control
the concurrency of the jobs for optimizing your continuous deployments workflow with safety.

## Add a resource group

You can add only one resource to a resource group.

Provided that you have the following pipeline configuration (`.gitlab-ci.yml` file in your repository):

```yaml
build:
  stage: build
  script: echo "Your build script"

deploy:
  stage: deploy
  script: echo "Your deployment script"
  environment: production
```

Every time you push a new commit to a branch, it runs a new pipeline that has
two jobs `build` and `deploy`. But if you push multiple commits in a short interval, multiple
pipelines start running simultaneously, for example:

- The first pipeline runs the jobs `build` -> `deploy`
- The second pipeline runs the jobs `build` -> `deploy`

In this case, the `deploy` jobs across different pipelines could run concurrently
to the `production` environment. Running multiple deployment scripts to the same
infrastructure could harm/confuse the instance and leave it in a corrupted state in the worst case.

To ensure that a `deploy` job runs once at a time, you can specify
[`resource_group` keyword](../yaml/_index.md#resource_group) to the concurrency sensitive job:

```yaml
deploy:
  ...
  resource_group: production
```

With this configuration, the safety on the deployments is assured while you
can still run `build` jobs concurrently for maximizing the pipeline efficiency.

## Prerequisites

- The basic knowledge of the [GitLab CI/CD pipelines](../pipelines/_index.md)
- The basic knowledge of the [GitLab Environments and Deployments](../environments/_index.md)
- At least the Developer role for the project to configure CI/CD pipelines.

## Process modes

You can choose a process mode to strategically control the job concurrency for your deployment preferences.
The following modes are supported:

- **Unordered:** This is the default process mode that limits the concurrency on running jobs.
  It's the easiest option to use when you don't care about the execution order
  of the jobs. It starts processing the jobs whenever a job is ready to run.
- **Oldest first:** This process mode limits the concurrency of the jobs. When a resource is free,
  it picks the first job from the list of upcoming jobs (`created`, `scheduled`, or `waiting_for_resource` state)
  that are sorted by pipeline ID in ascending order.

  This mode is efficient when you want to ensure that the jobs are executed from the oldest pipeline.
  It is less efficient compared to the `unordered` mode in terms of the pipeline efficiency,
  but safer for continuous deployments.

- **Newest first:** This process mode limits the concurrency of the jobs. When a resource is free,
  it picks the first job from the list of upcoming jobs (`created`, `scheduled` or `waiting_for_resource` state)
  that are sorted by pipeline ID in descending order.

  This mode is efficient when you want to ensure that the jobs are executed from the newest pipeline and
  prevent all of the old deploy jobs with the [prevent outdated deployment jobs](../environments/deployment_safety.md#prevent-outdated-deployment-jobs) feature.
  This is the most efficient option in terms of the pipeline efficiency, but you must ensure that each deployment job is idempotent.

### Change the process mode

To change the process mode of a resource group, you must use the API and
send a request to [edit an existing resource group](../../api/resource_groups.md#edit-an-existing-resource-group)
by specifying the `process_mode`:

- `unordered`
- `oldest_first`
- `newest_first`

### An example of difference between the process modes

Consider the following `.gitlab-ci.yml`, where we have two jobs `build` and `deploy`
each running in their own stage, and the `deploy` job has a resource group set to
`production`:

```yaml
build:
  stage: build
  script: echo "Your build script"

deploy:
  stage: deploy
  script: echo "Your deployment script"
  environment: production
  resource_group: production
```

If three commits are pushed to the project in a short interval, that means that three
pipelines run almost at the same time:

- The first pipeline runs the jobs `build` -> `deploy`. Let's call this deployment job `deploy-1`.
- The second pipeline runs the jobs `build` -> `deploy`. Let's call this deployment job `deploy-2`.
- The third pipeline runs the jobs `build` -> `deploy`. Let's call this deployment job `deploy-3`.

Depending on the process mode of the resource group:

- If the process mode is set to `unordered`:
  - `deploy-1`, `deploy-2`, and `deploy-3` do not run concurrently.
  - There is no guarantee on the job execution order, for example, `deploy-1` could run before or after `deploy-3` runs.
- If the process mode is `oldest_first`:
  - `deploy-1`, `deploy-2`, and `deploy-3` do not run concurrently.
  - `deploy-1` runs first, `deploy-2` runs second, and `deploy-3` runs last.
- If the process mode is `newest_first`:
  - `deploy-1`, `deploy-2`, and `deploy-3` do not run concurrently.
  - `deploy-3` runs first, `deploy-2` runs second and `deploy-1` runs last.

## Pipeline-level concurrency control with cross-project/parent-child pipelines

You can define `resource_group` for downstream pipelines that are sensitive to concurrent
executions. The [`trigger` keyword](../yaml/_index.md#trigger) can trigger downstream pipelines and the
[`resource_group` keyword](../yaml/_index.md#resource_group) can co-exist with it. `resource_group` is efficient to control the
concurrency of deployment pipelines, while other jobs can continue to run concurrently.

The following example has two pipeline configurations in a project. When a pipeline starts running,
non-sensitive jobs are executed first and aren't affected by concurrent executions in other
pipelines. However, GitLab ensures that there are no other deployment pipelines running before
triggering a deployment (child) pipeline. If other deployment pipelines are running, GitLab waits
until those pipelines finish before running another one.

```yaml
# .gitlab-ci.yml (parent pipeline)

build:
  stage: build
  script: echo "Building..."

test:
  stage: test
  script: echo "Testing..."

deploy:
  stage: deploy
  trigger:
    include: deploy.gitlab-ci.yml
    strategy: depend
  resource_group: AWS-production
```

```yaml
# deploy.gitlab-ci.yml (child pipeline)

stages:
  - provision
  - deploy

provision:
  stage: provision
  script: echo "Provisioning..."

deployment:
  stage: deploy
  script: echo "Deploying..."
  environment: production
```

You must define [`strategy: depend`](../yaml/_index.md#triggerstrategy)
with the `trigger` keyword. This ensures that the lock isn't released until the downstream pipeline
finishes.

## Related topics

- [API documentation](../../api/resource_groups.md)
- [Log documentation](../../administration/logs/_index.md#ci_resource_groups_jsonlog)
- [GitLab for safe deployments](../environments/deployment_safety.md)

## Troubleshooting

### Avoid dead locks in pipeline configurations

Because [`oldest_first` process mode](#process-modes) enforces the jobs to be executed in a pipeline order,
there is a case that it doesn't work well with the other CI features.

For example, when you run [a child pipeline](../pipelines/downstream_pipelines.md#parent-child-pipelines)
that requires the same resource group with the parent pipeline,
a dead lock could happen. Here is an example of a _bad_ setup:

```yaml
# BAD
test:
  stage: test
  trigger:
    include: child-pipeline-requires-production-resource-group.yml
    strategy: depend

deploy:
  stage: deploy
  script: echo
  resource_group: production
  environment: production
```

In a parent pipeline, it runs the `test` job that subsequently runs a child pipeline,
and the [`strategy: depend` option](../yaml/_index.md#triggerstrategy) makes the `test` job wait until the child pipeline has finished.
The parent pipeline runs the `deploy` job in the next stage, that requires a resource from the `production` resource group.
If the process mode is `oldest_first`, it executes the jobs from the oldest pipelines, meaning the `deploy` job is executed next.

However, a child pipeline also requires a resource from the `production` resource group.
Because the child pipeline is newer than the parent pipeline, the child pipeline
waits until the `deploy` job is finished, something that never happens.

In this case, you should specify the `resource_group` keyword in the parent pipeline configuration instead:

```yaml
# GOOD
test:
  stage: test
  trigger:
    include: child-pipeline.yml
    strategy: depend
  resource_group: production # Specify the resource group in the parent pipeline

deploy:
  stage: deploy
  script: echo
  resource_group: production
  environment: production
```

### Jobs get stuck in "Waiting for resource"

Sometimes, a job hangs with the message `Waiting for resource: <resource_group>`. To resolve,
first check that the resource group is working correctly:

1. Go to the job details page.
1. If the resource is assigned to a job, select **View job currently using resource** and check the job status.

   - If the status is `running` or `pending`, the feature is working correctly. Wait until the job finishes and releases the resource.
   - If the status is `created` and the [process mode](#process-modes) is either **Oldest first** or **Newest first**, the feature is working correctly.
     Visit the pipeline page of the job and check which upstream stage or job is blocking the execution.
   - If none of the above conditions are met, the feature might not be working correctly. [Report the issue to GitLab](#report-an-issue).

1. If **View job currently using resource** is not available, the resource is not assigned to a job. Instead, check the resource's upcoming jobs.

   1. Get the resource's upcoming jobs with the [REST API](../../api/resource_groups.md#list-upcoming-jobs-for-a-specific-resource-group).
   1. Verify that the resource group's [process mode](#process-modes) is **Oldest first**.
   1. Find the first job in the list of upcoming jobs, and get the job details [with GraphQL](#get-job-details-through-graphql).
   1. If the first job's pipeline is an older pipeline, try to cancel the pipeline or the job itself.
   1. Optional. Repeat this process if the next upcoming job is still in an older pipeline that should no longer run.
   1. If the problem persists, [report the issue to GitLab](#report-an-issue).

#### Race conditions in complex or busy pipelines

If you can't resolve your issue with the solutions above, you might be encountering a known race condition issue. The race condition happens in complex or busy pipelines.
For example, you might encounter the race condition if you have:

- A pipeline with multiple child pipelines.
- A single project with multiple pipelines running simultaneously.

If you think you are running into this problem, [report the issue to GitLab](#report-an-issue) and leave a comment on [issue 436988](https://gitlab.com/gitlab-org/gitlab/-/issues/436988) with a link to your new issue.
To confirm the problem, GitLab might ask for additional details such
as your full pipeline configuration.

As a temporary workaround, you can:

- Start a new pipeline.
- Re-run a finished job that has the same resource group as the stuck job.

  For example, if you have a `setup_job` and a `deploy_job` with the same resource group,
  the `setup_job` might finish while the `deploy_job` is stuck at "waiting for resource".
  Re-run the `setup_job` to restart the whole process and allow `deploy_job` to finish.

#### Get job details through GraphQL

You can get job information from the GraphQL API. You should use the GraphQL API if you use [pipeline-level concurrency control with cross-project/parent-child pipelines](#pipeline-level-concurrency-control-with-cross-projectparent-child-pipelines) because the trigger jobs are not accessible from the UI.

To get job information from the GraphQL API:

1. Go to the pipeline details page.
1. Select the **Jobs** tab and find the ID of the stuck job.
1. Go to the [interactive GraphQL explorer](../../api/graphql/_index.md#interactive-graphql-explorer).
1. Run the following query:

   ```graphql
   {
     project(fullPath: "<fullpath-to-your-project>") {
       name
       job(id: "gid://gitlab/Ci::Build/<job-id>") {
         name
         status
         detailedStatus {
           action {
             path
             buttonTitle
           }
         }
       }
     }
   }
   ```

    The `job.detailedStatus.action.path` field contains the job ID using the resource.

1. Run the following query and check `job.status` field according to the criteria above. You can also visit the pipeline page from `pipeline.path` field.

   ```graphql
   {
     project(fullPath: "<fullpath-to-your-project>") {
       name
       job(id: "gid://gitlab/Ci::Build/<job-id-currently-using-the-resource>") {
         name
         status
         pipeline {
           path
         }
       }
     }
   }
   ```

### Report an issue

[Open a new issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new) with the following information:

- The ID of the affected job.
- The job status.
- How often the problem occurs.
- Steps to reproduce the problem.

  You can also [contact support](https://about.gitlab.com/support/#contact-support) for further assistance, or to get in touch with the development team.
