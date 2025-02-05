---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GraphQL API removed items
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

GraphQL is a versionless API, unlike the REST API.
Occasionally, items have to be updated or removed from the GraphQL API.
According to our [process for removing items](_index.md#deprecation-and-removal-process), here are the items that have been removed.

For deprecations, see the [Deprecations by version page](../../update/deprecations.md).

## GitLab 17.0

Fields removed in GitLab 17.0.

### GraphQL Fields

| Field name | GraphQL type | Deprecated in | Removal MR | Use instead |
|---|---|---|---|---|
| `architectureName` | `CiRunner` | 16.2 | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | Use this field in `manager` object instead. |
| `executorName` | `CiRunner` | 16.2 | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | Use this field in `manager` object instead. |
| `ipAddress` | `CiRunner` | 16.2 | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | Use this field in `manager` object instead. |
| `platformName` | `CiRunner` | 16.2 | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | Use this field in `manager` object instead. |
| `revision` | `CiRunner` | 16.2 | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | Use this field in `manager` object instead. |
| `version` | `CiRunner` | 16.2 | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | Use this field in `manager` object instead. |

## GitLab 16.0

Fields removed in GitLab 16.0.

### GraphQL Fields

| Field name | GraphQL type | Deprecated in | Removal MR | Use instead |
|---|---|---|---|---|
| `name` | `PipelineSecurityReportFinding` | [15.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89571) | [!119055](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119055) | `title` |
| `external` | `ReleaseAssetLink` | 15.9 | [!111750](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111750) | None |
| `confidence` | `PipelineSecurityReportFinding` | 15.4 | [!118617](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118617) | None |
| `PAUSED` | `CiRunnerStatus` | 14.8 | [!118635](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118635) | `CiRunner.paused: true` |
| `ACTIVE` | `CiRunnerStatus` | 14.8 | [!118635](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118635) | `CiRunner.paused: false` |

### GraphQL Mutations

| Argument name        | Mutation                 | Deprecated in                                                       | Use instead                                    |
| -------------------- | --------------------     |---------------------------------------------------------------------|------------------------------------------------|
| -                    | `vulnerabilityFindingDismiss` | [15.5](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/99170) | `vulnerabilityDismiss` or `securityFindingDismiss` |
| -                    | `apiFuzzingCiConfigurationCreate` | [15.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87241) | `todos`                                        |
| -                    | `CiCdSettingsUpdate` | [15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/361801) | `ProjectCiCdSettingsUpdate` |

## GitLab 15.0

Fields removed in GitLab 15.0.

### GraphQL Mutations

[Removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85382) in GitLab 15.0:

| Argument name        | Mutation                 | Deprecated in | Use instead                |
| -------------------- | --------------------     | ------------- | -------------------------- |
| -                    | `clusterAgentTokenDelete`| 14.7          | `clusterAgentTokenRevoke`  |

### GraphQL Fields

[Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/342882) in GitLab 15.0:

| Argument name        | Field name          | Deprecated in | Use instead                |
| -------------------- | --------------------| ------------- | -------------------------- |
| -                    | `pipelines`         | 14.5          | None                       |

### GraphQL Types

| Field name                                 | GraphQL type             | Deprecated in | Use instead                                                                        |
| ------------------------------------------ | ------------------------ | ------------- | ---------------------------------------------------------------------------------- |
| `defaultMergeCommitMessageWithDescription` | `GraphQL::Types::String` | 14.5          | None. Define a [merge commit template](../../user/project/merge_requests/commit_templates.md) in your project and use `defaultMergeCommitMessage`. |
