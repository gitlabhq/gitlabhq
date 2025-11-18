---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: External commit statuses
description: How external CI/CD systems integrate with GitLab pipelines using commit statuses.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

External commit statuses allow external CI/CD systems like Jenkins, CircleCI, or custom deployment tools to integrate with GitLab pipelines. External systems post commit statuses back to GitLab, and the status results appear alongside CI/CD jobs in merge requests and commit views.

When external systems post commit statuses using the [Commits API](../../api/commits.md#set-commit-pipeline-status), GitLab handles these statuses by either adding them to existing pipelines or creating new pipelines to contain them.

## Pipeline selection

When you post a commit status from an external system, a find-or-create approach is used:

1. GitLab searches for the most recent `non-archived` CI pipeline for the given commit SHA and ref. You can also search directly for a pipeline by including the `pipeline_id` parameter.
1. If GitLab finds a suitable pipeline, it appends the new job status to that pipeline. For jobs appended to existing pipelines, `CI_PIPELINE_SOURCE` matches the pipeline source (for example, `push` or `merge_request_event`).
1. If no suitable pipeline exists, GitLab creates a new pipeline to contain the job. For new pipelines, `CI_PIPELINE_SOURCE` is `external`.

External job statuses appear in an `external` stage in the pipeline, separate from other GitLab CI/CD stages.

{{< alert type="warning" >}}

When duplicate pipelines exist for the same commit, external status placement becomes ambiguous. GitLab selects the latest pipeline using `newest_first`, but with concurrent pipeline creation, this can lead to external statuses appearing in unexpected pipelines or becoming invisible in merge request views.

Configure [workflow rules](../yaml/workflow.md) to avoid duplicate pipelines or target a pipeline directly with `pipeline_id`.

{{< /alert >}}

## Job updates and retries

When you post commit statuses from external systems:

- If a `running` or `pending` job with the same `name` `user` and `sha` already exists in the target pipeline, GitLab updates its status.
  - If a different user updates a job with the same `name` the job is retried. This creates a new job and hides the old job from the current pipeline.
- You can retry a job that is not `running` or `pending` with the same `name` but different `status` (for example, send `success` for a job marked `failed`). This creates a new job and hides the old job from the current pipeline.
- Different external services can add jobs to the same SHA and pipeline by using a unique job `name`.

If an update is already in progress for a SHA/ref combination, a `409` error is returned.
Retry the request to handle this error.

## Troubleshooting

### External statuses not visible in merge requests

If external CI statuses don't appear in merge request pipelines:

1. Check if you have both merge request and branch pipelines running for the same commit.
1. Verify your [workflow rules](../yaml/workflow.md) prevent duplicate pipelines.
1. Confirm the external system is posting to the correct ref.
1. If the commit is associated with a merge request, ensure the API call targets the commit in the merge request's source branch.

For more information, see [avoid duplicate pipelines](../jobs/job_rules.md#avoid-duplicate-pipelines).
