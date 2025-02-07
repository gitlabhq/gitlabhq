---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting downstream pipelines
---

## Trigger job fails and does not create multi-project pipeline

With multi-project pipelines, the trigger job fails and does not create the downstream pipeline if:

- The downstream project is not found.
- The user that creates the upstream pipeline does not have [permission](../../user/permissions.md)
  to create pipelines in the downstream project.
- The downstream pipeline targets a protected branch and the user does not have permission
  to run pipelines against the protected branch. See [pipeline security for protected branches](_index.md#pipeline-security-on-protected-branches)
  for more information.

To identify which user is having permission issues in the downstream project, you can check the trigger job using the following command in the [Rails console](../../administration/operations/rails_console.md) and look at the `user_id` attribute.

```ruby
Ci::Bridge.find(<job_id>)
```

## Job in child pipeline is not created when the pipeline runs

If the parent pipeline is a [merge request pipeline](merge_request_pipelines.md),
the child pipeline must [use `workflow:rules` or `rules` to ensure the jobs run](downstream_pipelines.md#run-child-pipelines-with-merge-request-pipelines).

If no jobs in the child pipeline can run due to missing or incorrect `rules` configuration:

- The child pipeline fails to start.
- The parent pipeline's trigger job fails with: `downstream pipeline can not be created, the resulting pipeline would have been empty. Review the`[`rules`](../yaml/_index.md#rules)`configuration for the relevant jobs.`

## Variable with `$` character does not get passed to a downstream pipeline properly

You cannot use [`$$` to escape the `$` character in a CI/CD variable](../variables/_index.md#use-the--character-in-cicd-variables),
when [passing a CI/CD variable to a downstream pipeline](downstream_pipelines.md#pass-cicd-variables-to-a-downstream-pipeline).
The downstream pipeline still treats the `$` as the start of a variable reference.

Instead, use the [`variables:expand` keyword](../yaml/_index.md#variablesexpand) to
set the variable value to not be expanded. This variable can then be passed to the downstream pipeline
without the `$` being interpreted as a variable reference.

## `Ref is ambiguous`

You cannot trigger a multi-project pipeline with a tag when a branch exists with the same
name. The downstream pipeline fails to create with the error: `downstream pipeline can not be created, Ref is ambiguous`.

Only trigger multi-project pipelines with tag names that do not match branch names.

## `403 Forbidden` error when downloading a job artifact from an upstream pipeline

In GitLab 15.9 and later, CI/CD job tokens are scoped to the project that the pipeline executes under. Therefore, the job token in a downstream pipeline cannot be used to access an upstream project by default.

To resolve this, [add the downstream project to the job token scope allowlist](../jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist).
