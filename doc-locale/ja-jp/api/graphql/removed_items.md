---
stage: Developer Experience
group: API
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GraphQL APIの削除された項目
description: "GitLab GraphQL APIで非推奨となり、削除された項目の一覧です。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GraphQLはREST APIとは異なり、バージョンなしのAPIです。GraphQL APIの項目は、更新または削除されることがあります。当社の[項目削除プロセス](_index.md#deprecation-and-removal-process)に基づき、削除された項目を以下に示します。

非推奨については、[バージョン別非推奨一覧](../../update/deprecations.md)をご覧ください。

## GitLab 17.0 {#gitlab-170}

GitLab 17.0で削除されたフィールド。

### GraphQLフィールド {#graphql-fields}

| フィールド名         | GraphQLの型 | 非推奨になったバージョン | 削除マージリクエスト                                                              | 代わりに使用するもの |
|--------------------|--------------|---------------|-------------------------------------------------------------------------|-------------|
| `architectureName` | `CiRunner`   | 16.2          | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | 代わりに`manager`オブジェクト内の同名のフィールドを使用します。 |
| `executorName`     | `CiRunner`   | 16.2          | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | 代わりに`manager`オブジェクト内の同名のフィールドを使用します。 |
| `ipAddress`        | `CiRunner`   | 16.2          | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | 代わりに`manager`オブジェクト内の同名のフィールドを使用します。 |
| `platformName`     | `CiRunner`   | 16.2          | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | 代わりに`manager`オブジェクト内の同名のフィールドを使用します。 |
| `revision`         | `CiRunner`   | 16.2          | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | 代わりに`manager`オブジェクト内の同名のフィールドを使用します。 |
| `version`          | `CiRunner`   | 16.2          | [!124751](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124751) | 代わりに`manager`オブジェクト内の同名のフィールドを使用します。 |

## GitLab 16.0 {#gitlab-160}

GitLab 16.0で削除されたフィールド。

### GraphQLフィールド {#graphql-fields-1}

| フィールド名   | GraphQLの型                    | 非推奨になったバージョン                                                       | 削除マージリクエスト                                                              | 代わりに使用するもの |
|--------------|---------------------------------|---------------------------------------------------------------------|-------------------------------------------------------------------------|-------------|
| `name`       | `PipelineSecurityReportFinding` | [15.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89571) | [!119055](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119055) | `title`     |
| `external`   | `ReleaseAssetLink`              | 15.9                                                                | [!111750](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111750) | なし        |
| `confidence` | `PipelineSecurityReportFinding` | 15.4                                                                | [!118617](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118617) | なし        |
| `PAUSED`     | `CiRunnerStatus`                | 14.8                                                                | [!118635](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118635) | `CiRunner.paused: true` |
| `ACTIVE`     | `CiRunnerStatus`                | 14.8                                                                | [!118635](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118635) | `CiRunner.paused: false` |

### GraphQLミューテーション {#graphql-mutations}

| 引数名 | ミューテーション                          | 非推奨になったバージョン                                                       | 代わりに使用するもの |
|---------------|-----------------------------------|---------------------------------------------------------------------|-------------|
| -             | `vulnerabilityFindingDismiss`     | [15.5](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/99170) | `vulnerabilityDismiss`または`securityFindingDismiss` |
| -             | `apiFuzzingCiConfigurationCreate` | [15.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87241) | `todos`     |
| -             | `CiCdSettingsUpdate`              | [15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/361801)        | `ProjectCiCdSettingsUpdate` |

## GitLab 15.0 {#gitlab-150}

GitLab 15.0で削除されたフィールド。

### GraphQLミューテーション {#graphql-mutations-1}

[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85382)されたGitLab 15.0:

| 引数名 | ミューテーション                  | 非推奨になったバージョン | 代わりに使用するもの |
|---------------|---------------------------|---------------|-------------|
| -             | `clusterAgentTokenDelete` | 14.7          | `clusterAgentTokenRevoke` |

### GraphQLフィールド {#graphql-fields-2}

[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/342882)されたGitLab 15.0:

| 引数名 | フィールド名  | 非推奨になったバージョン | 代わりに使用するもの |
|---------------|-------------|---------------|-------------|
| -             | `pipelines` | 14.5          | なし        |

### GraphQLの型 {#graphql-types}

| フィールド名                                 | GraphQLの型             | 非推奨になったバージョン | 代わりに使用するもの |
|--------------------------------------------|--------------------------|---------------|-------------|
| `defaultMergeCommitMessageWithDescription` | `GraphQL::Types::String` | 14.5          | なし。プロジェクトで[マージコミットテンプレート](../../user/project/merge_requests/commit_templates.md)を定義し、`defaultMergeCommitMessage`を使用します。 |
