---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GraphQL API removed items

GraphQL is a versionless API, unlike the REST API.
Occasionally, items have to be updated or removed from the GraphQL API.
According to our [process for removing items](index.md#deprecation-and-removal-process), here are the items that have been removed.

## GitLab 13.6

Fields removed in [GitLab 13.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/44866):

| Field name           | GraphQL type             | Deprecated in | Use instead                |
| -------------------- | --------------------     | ------------- | -------------------------- |
| `date`               | `Timelog` **(STARTER)**  | 12.10         | `spentAt`                  |
| `designs`            | `Issue`, `EpicIssue`     | 12.2          | `designCollection`         |
| `latestPipeline`     | `Commit`                 | 12.5          | `pipelines`                |
| `mergeCommitMessage` | `MergeRequest`           | 11.8          | `latestMergeCommitMessage` |
| `token`              | `GrafanaIntegration`     | 12.7          | None. Plaintext tokens no longer supported for security reasons. |
