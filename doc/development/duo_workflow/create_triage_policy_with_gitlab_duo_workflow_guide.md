---
title: Create triage policies with the assistance of GitLab Duo Agent Platform
---

{{< history >}}

- [Name changed](https://gitlab.com/gitlab-org/gitlab/-/issues/551382) from `Workflow` to `Agent Platform` in GitLab 18.2.

{{< /history >}}

## Summary

This guide provides comprehensive instructions for writing triage automation policies in [triage-ops](https://gitlab.com/gitlab-org/quality/triage-ops) using GitLab Duo Agent Platform. You will be able to self service label migrations after a department re-org by following this page.

Todo: include instructions for writing policies to perform other types of automated tasks.

## Purpose

Triage policies are used when team members migrate labels across existing issues, merge requests, and epics using [GitLab-triage](https://gitlab.com/gitlab-org/ruby/gems/gitlab-triage). This tool automates triaging through [policies defined in YAML](https://gitlab.com/gitlab-org/ruby/gems/gitlab-triage#what-is-a-triage-policy). To optimize operational efficiency and ensure seamless implementation, we recommend self-servicing the label migration MRs using [GitLab Duo Agent Platform](../../user/duo_agent_platform/_index.md).

## Before you start

Follow the [GitLab Duo Agent Platform documentation](../../user/duo_agent_platform/_index.md) to learn how to set up and access GitLab Duo Agent Platform in your code editor.

## Build your prompt

You need to be specific about your requirements in the prompt to produce the best result.

Example prompt:

> Write a one-off label migration in `policies/one-off/auth-migration.yml` to apply a ~"DevOps::software supply chain security" label to issues, MRs, and epics currently labeled with ~"group::authentication". Target only open resources. Exclude any resource that already has the ~"DevOps::software supply chain security" label.
>
> Link the new one-off policy in `.gitlab/ci/one-off.yml` to run the policy in CI. Create two jobs: a dry-run and an actual job. The job names must follow the instructions listed in `one-off.yml`.
>
> Read instructions and example YAML files in `policies/one-off/duo-workflow-guide-and-example-policies` to ensure correct syntax.

See sections below for recommended information to include in the prompt.

### File name and location

Specify a policy file name inside the [`policies`](https://gitlab.com/gitlab-org/quality/triage-ops/-/tree/master/policies?ref_type=heads) directory except for `generated` directory.

For example, label migration policies go in [`policies/one-off`](https://gitlab.com/gitlab-org/quality/triage-ops/-/tree/master/policies/one-off) directory.

Example prompt snippet: `write a one-off label migration in policies/one-off/auth-migration.yml to...`

### Migration target

Define your migration target through `conditions` in the policy.

Example prompt snippet: `issues, MRs, and epics that are currently labeled with group::authentication`

Note: the gem only answers to [these specific conditions](https://gitlab.com/gitlab-org/ruby/gems/gitlab-triage#conditions-field).

### Action

Define the desired outcome of the automation, such as which label to apply to the targets.

Example prompt snippet: `apply a devops::software supply chain security label to issues, MRs, and epics...`

Note: the gem only performs [these actions](https://gitlab.com/gitlab-org/ruby/gems/gitlab-triage#actions-field).

### Reference material

GitLab Duo Agent Platform requires reference materials, preferably with examples, to write these files.

Example prompt snippet: `Read instructions and example yml files in policies/one-off/duo-workflow-guide-and-example-policies to ensure the result has the correct syntax.`

### CI jobs for label migration

For testing and executing migration policies, create CI jobs in the MR pipeline. Instruct Workflow to create these jobs:

Example prompt snippet: `Link the new one-off policy in .gitlab/ci/one-off.yml to run the policy in CI. Create two jobs: a dry-run and an actual job. The job names must follow the instructions listed in one-off.yml.`

### Policy Refinement

You can start another workflow to refine the policy if some policy condition was missing.

Example prompt:

> Update the policy you created in `policies/one-off/auth-migration.yml` by adding a new condition to skip resources currently labeled with ~"workflow::completed" using the forbidden_labels field

### Resulting policy written by GitLab Duo Agent Platform

The 2 prompts above generated the following policy:

```yaml
.common_conditions: &common_conditions
  state: opened
  labels:
    - "group::authentication"
  forbidden_labels:
    - "devops::software supply chain security"
    - "workflow::completed"

.common_actions: &common_actions
  labels:
    - "devops::software supply chain security"

resource_rules:
  epics:
    rules:
      - name: (Epics) Add devops::software supply chain security label to group::authentication epics
        conditions:
          <<: *common_conditions
        actions:
          <<: *common_actions
  issues:
    rules:
      - name: (Issues) Add devops::software supply chain security label to group::authentication issues
        conditions:
          <<: *common_conditions
        actions:
          <<: *common_actions
  merge_requests:
    rules:
      - name: (Merge Requests) Add devops::software supply chain security label to group::authentication MRs
        conditions:
          <<: *common_conditions
        actions:
          <<: *common_actions
```

## After a triage policy is written

Submit the code changes to an MR using [this merge request template for one-off label migration](https://gitlab.com/gitlab-org/quality/triage-ops/-/blob/master/.gitlab/merge_request_templates/One-off-label-migration.md). If you have followed the instructions above, your MR should include 2 jobs under the `one-off` stage. Run the dry-run job in your merge request pipeline to validate the policy. Once the policy is validated, you can execute the label migration job (the one without the `dry-run` job name suffix).

You are welcome to request a code review to confirm the migration policy was correctly written. However, if you are confident with the result of the label migration, you can choose to skip the code review step.

Reminder, please do not merge the MR when a migration is done.

## Best practices and troubleshooting tips

Use the dry-run job to verify your policy's accuracy.

If a specified condition is ignored in the dry run, check for syntax errors in the condition field.

If the syntax looks correct, you may have used an invalid condition. The GitLab-triage gem ignores such conditions without generating an error message, so you need to review all condition keywords in the policy and compare them with the [GitLab-triage documentation](https://gitlab.com/gitlab-org/ruby/gems/gitlab-triage#defining-a-policy). It only answers to [these conditions](https://gitlab.com/gitlab-org/ruby/gems/gitlab-triage#conditions-field) and [these actions](https://gitlab.com/gitlab-org/ruby/gems/gitlab-triage#actions-field).

For example, when writing a triage policy to post comments in your targeted resources:

> In `./policies/groups/gitlab-com/csmerm/label_regression_for_on_track_with_no_activity.yml`, write a policy to apply regression label on issues labeled with ~"SP Objective::Status::On Track" when there has been no update on the issue in more than 8 days.

May produce this result with an incorrect field `last_updated_at`:

```yaml
resource_rules:
  issues:
    rules:
      - name: Mark as regression when on track issues have no activity for 8+ days
        conditions:
          last_updated_at: 8d-ago
        actions:
          labels:
            - regression
```

The correct way of specifying that condition is:

```yaml
conditions:
  ruby: resource[:updated_at] < 8.days.ago.strftime('%Y-%m-%dT00:00:00.000Z')
```

After finding the solution, include this policy in the reference materials linked in your #reference-material prompt to help Workflow avoid similar mistakes.

## Demo

Watch [this video](https://www.youtube.com/watch?v=AoCD4hh2nhc) on GitLab Unfiltered for demo.
