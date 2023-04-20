---
stage: Verify
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Pipeline artifacts **(FREE)**

Pipeline artifacts are files created by GitLab after a pipeline finishes. Pipeline artifacts are
different to [job artifacts](../jobs/job_artifacts.md) because they are not explicitly managed by
`.gitlab-ci.yml` definitions.

Pipeline artifacts are used by the [test coverage visualization feature](../testing/test_coverage_visualization.md)
to collect coverage information.

## Storage

Pipeline artifacts are saved to disk or object storage. They count towards a project's [storage usage quota](../../user/usage_quotas.md#storage-usage-quota).
The **Artifacts** on the Usage Quotas page is the sum of all job artifacts and pipeline artifacts.

## When pipeline artifacts are deleted

Pipeline artifacts from:

- The latest pipeline are kept forever.
- Pipelines superseded by a newer pipeline are deleted seven days after their creation date.

It can take up to two days for GitLab to delete pipeline artifacts from when they are due to be
deleted.
