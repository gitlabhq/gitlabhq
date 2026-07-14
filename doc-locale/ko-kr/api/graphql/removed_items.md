---
stage: Developer Experience
group: API Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GraphQL API 제거된 항목
description: "GitLab GraphQL API에서 더 이상 사용되지 않는 항목 및 제거된 항목의 목록입니다."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GraphQL은 REST API와 달리 버전이 없는 API입니다. 가끔 GraphQL API에서 항목을 업데이트하거나 제거해야 합니다. 당사의 [항목 제거 프로세스](_index.md#deprecation-and-removal-process)에 따라 제거된 항목은 다음과 같습니다.

더 이상 사용되지 않는 항목을 확인하려면 [버전별 더 이상 사용되지 않는 항목 페이지](../../update/deprecations.md)를 참고하세요.

## GitLab 17.0 {#gitlab-170}

GitLab 17.0에서 제거된 필드입니다.

### GraphQL 필드 {#graphql-fields}

| 필드 이름         | GraphQL 유형 | 지원 중단 버전 | 제거 MR                                                              | 대신 사용 |
|--------------------|--------------|---------------|-------------------------------------------------------------------------|-------------|
| `architectureName` | `CiRunner`   | 16.2          | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | 대신 `manager` 객체의 이 필드를 사용하세요. |
| `executorName`     | `CiRunner`   | 16.2          | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | 대신 `manager` 객체의 이 필드를 사용하세요. |
| `ipAddress`        | `CiRunner`   | 16.2          | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | 대신 `manager` 객체의 이 필드를 사용하세요. |
| `platformName`     | `CiRunner`   | 16.2          | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | 대신 `manager` 객체의 이 필드를 사용하세요. |
| `revision`         | `CiRunner`   | 16.2          | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | 대신 `manager` 객체의 이 필드를 사용하세요. |
| `version`          | `CiRunner`   | 16.2          | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | 대신 `manager` 객체의 이 필드를 사용하세요. |

## GitLab 16.0 {#gitlab-160}

GitLab 16.0에서 제거된 필드입니다.

### GraphQL 필드 {#graphql-fields-1}

| 필드 이름   | GraphQL 유형                    | 지원 중단 버전                                                       | 제거 MR                                                              | 대신 사용 |
|--------------|---------------------------------|---------------------------------------------------------------------|-------------------------------------------------------------------------|-------------|
| `name`       | `PipelineSecurityReportFinding` | [15.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89571) | [!119055](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119055) | `title`     |
| `external`   | `ReleaseAssetLink`              | 15.9                                                                | [!111750](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111750) | 없음        |
| `confidence` | `PipelineSecurityReportFinding` | 15.4                                                                | [!118617](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118617) | 없음        |
| `PAUSED`     | `CiRunnerStatus`                | 14.8                                                                | [!118635](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118635) | `CiRunner.paused: true` |
| `ACTIVE`     | `CiRunnerStatus`                | 14.8                                                                | [!118635](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118635) | `CiRunner.paused: false` |

### GraphQL 변이 {#graphql-mutations}

| 인수 이름 | 변이                          | 지원 중단 버전                                                       | 대신 사용 |
|---------------|-----------------------------------|---------------------------------------------------------------------|-------------|
| -             | `vulnerabilityFindingDismiss`     | [15.5](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/99170) | `vulnerabilityDismiss` 또는 `securityFindingDismiss` |
| -             | `apiFuzzingCiConfigurationCreate` | [15.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87241) | `todos`     |
| -             | `CiCdSettingsUpdate`              | [15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/361801)        | `ProjectCiCdSettingsUpdate` |

## GitLab 15.0 {#gitlab-150}

GitLab 15.0에서 제거된 필드입니다.

### GraphQL 변이 {#graphql-mutations-1}

[제거됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85382) GitLab 15.0:

| 인수 이름 | 변이                  | 지원 중단 버전 | 대신 사용 |
|---------------|---------------------------|---------------|-------------|
| -             | `clusterAgentTokenDelete` | 14.7          | `clusterAgentTokenRevoke` |

### GraphQL 필드 {#graphql-fields-2}

[제거됨](https://gitlab.com/gitlab-org/gitlab/-/issues/342882) GitLab 15.0:

| 인수 이름 | 필드 이름  | 지원 중단 버전 | 대신 사용 |
|---------------|-------------|---------------|-------------|
| -             | `pipelines` | 14.5          | 없음        |

### GraphQL 유형 {#graphql-types}

| 필드 이름                                 | GraphQL 유형             | 지원 중단 버전 | 대신 사용 |
|--------------------------------------------|--------------------------|---------------|-------------|
| `defaultMergeCommitMessageWithDescription` | `GraphQL::Types::String` | 14.5          | 없음. 프로젝트에서 [머지 커밋 템플릿](../../user/project/merge_requests/commit_templates.md)을 정의하고 `defaultMergeCommitMessage`을 사용하세요. |
