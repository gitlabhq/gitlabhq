---
stage: Verify
group: Testing
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
---

# Pipeline artifacts **(FREE)**

Pipeline artifacts are files created by GitLab after a pipeline finishes. These are different than [job artifacts](job_artifacts.md) because they are not explicitly managed by the `.gitlab-ci.yml` definitions.

Pipeline artifacts are used by the [test coverage visualization feature](../../user/project/merge_requests/test_coverage_visualization.md) to collect coverage information. It uses the [`artifacts: reports`](../yaml/index.md#artifactsreports) CI/CD keyword.

## Storage

Pipeline artifacts are saved to disk or object storage. They count towards a project's [storage usage quota](../../user/usage_quotas.md#storage-usage-quota). The **Artifacts** on the Usage Quotas page is the sum of all job artifacts and pipeline artifacts.

## When pipeline artifacts are deleted

Pipeline artifacts are deleted either:

- Seven days after creation.
- After another pipeline runs successfully, if they are from the most recent successful
  pipeline.

This deletion may take up to two days.
