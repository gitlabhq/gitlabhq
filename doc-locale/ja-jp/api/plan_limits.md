---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プラン制限API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このAPIを使用して、既存のサブスクリプションプランのアプリケーション制限を操作します。

既存のプランはGitLabエディションによって異なります。Community Editionでは、`default`プランのみが利用可能です。Enterprise Editionでは、追加のプランも利用可能です。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

## 現在のプラン制限を取得 {#get-current-plan-limits}

GitLabインスタンス上のプランの現在の制限を一覧表示します。

```plaintext
GET /application/plan_limits
```

| 属性                         | 型    | 必須 | 説明 |
| --------------------------------- | ------- | -------- | ----------- |
| `plan_name`                       | 文字列  | いいえ       | 制限を取得するプランの名前。デフォルトは`default`です。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/plan_limits"
```

レスポンス例:

```json
{
  "ci_instance_level_variables": 25,
  "ci_pipeline_size": 0,
  "ci_active_jobs": 0,
  "ci_project_subscriptions": 2,
  "ci_pipeline_schedules": 10,
  "ci_needs_size_limit": 50,
  "ci_registered_group_runners": 1000,
  "ci_registered_project_runners": 1000,
  "dotenv_size": 5120,
  "dotenv_variables": 20,
  "conan_max_file_size": 3221225472,
  "enforcement_limit": 10000,
  "generic_packages_max_file_size": 5368709120,
  "helm_max_file_size": 5242880,
  "notification_limit": 10000,
  "maven_max_file_size": 3221225472,
  "npm_max_file_size": 524288000,
  "nuget_max_file_size": 524288000,
  "pipeline_hierarchy_size": 1000,
  "pypi_max_file_size": 3221225472,
  "terraform_module_max_file_size": 1073741824,
  "storage_size_limit": 15000
}
```

## プラン制限の変更 {#change-plan-limits}

GitLabインスタンス上のプランの制限を変更します。

```plaintext
PUT /application/plan_limits
```

| 属性                         | 型    | 必須 | 説明 |
| --------------------------------- | ------- | -------- | ----------- |
| `plan_name`                       | 文字列  | はい      | 更新するプランの名前。 |
| `ci_instance_level_variables`     | 整数 | いいえ       | 定義できるインスタンスレベルのCI/CD変数の最大数。 |
| `ci_pipeline_size`                | 整数 | いいえ       | 1つのパイプラインにおけるジョブの最大数。GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895)されました。 |
| `ci_active_jobs`                  | 整数 | いいえ       | 現在アクティブなパイプライン内のジョブの合計数。GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895)されました。 |
| `ci_project_subscriptions`        | 整数 | いいえ       | プロジェクトとの間のパイプラインサブスクリプションの最大数。GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895)されました。 |
| `ci_pipeline_schedules`           | 整数 | いいえ       | パイプラインスケジュールの最大数。GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895)されました。 |
| `ci_needs_size_limit`             | 整数 | いいえ       | ジョブが持つことのできる[`needs`](../ci/yaml/needs.md)の依存関係の最大数。GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895)されました。 |
| `ci_registered_group_runners`     | 整数 | いいえ       | 過去7日間にグループ内で作成またはアクティブにできるRunnerの最大数。GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895)されました。 |
| `ci_registered_project_runners`   | 整数 | いいえ       | 過去7日間にプロジェクト内で作成またはアクティブにできるRunnerの最大数。GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895)されました。 |
| `dotenv_size`                     | 整数 | いいえ       | dotenvアーティファクトの最大サイズ（バイト）。GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/432529)されました。 |
| `dotenv_variables`                | 整数 | いいえ       | dotenvアーティファクト内の変数の最大数。GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/432529)されました。 |
| `conan_max_file_size`             | 整数 | いいえ       | Conanパッケージファイルの最大サイズ（バイト単位）。 |
| `enforcement_limit`               | 整数 | いいえ       | ルートネームスペース制限の適用に対する最大ストレージサイズ（MiB単位）。 |
| `generic_packages_max_file_size`  | 整数 | いいえ       | 汎用パッケージファイルの最大サイズ（バイト単位）。 |
| `helm_max_file_size`              | 整数 | いいえ       | 最大Helmチャートファイルサイズ（バイト単位）。 |
| `maven_max_file_size`             | 整数 | いいえ       | Mavenパッケージファイルの最大サイズ（バイト単位）。 |
| `notification_limit`              | 整数 | いいえ       | ルートネームスペース制限通知に対する最大ストレージサイズ（MiB単位）。 |
| `npm_max_file_size`               | 整数 | いいえ       | 最大NPMパッケージファイルサイズ（バイト単位）。 |
| `nuget_max_file_size`             | 整数 | いいえ       | 最大NuGetパッケージファイルサイズ（バイト単位）。 |
| `pipeline_hierarchy_size`         | 整数 | いいえ       | パイプラインの階層ツリー内のダウンストリームパイプラインの最大数。デフォルト値: `1000`。1000を超える値は[推奨されません](../administration/instance_limits.md#limit-pipeline-hierarchy-size)。 |
| `pypi_max_file_size`              | 整数 | いいえ       | 最大PyPiパッケージファイルサイズ（バイト単位）。 |
| `terraform_module_max_file_size`  | 整数 | いいえ       | 最大Terraformモジュールパッケージファイルサイズ（バイト単位）。 |
| `storage_size_limit`              | 整数 | いいえ       | MiB単位のルートネームスペースの最大ストレージサイズ。 |
| `web_hook_calls`                  | 整数 | いいえ       | トップレベルのネームスペースごとに、Webhookを1分間に呼び出すことができる最大回数。GitLab 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/571738)。 |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/plan_limits?plan_name=default&conan_max_file_size=3221225472"
```

レスポンス例:

```json
{
  "ci_instance_level_variables": 25,
  "ci_pipeline_size": 0,
  "ci_active_jobs": 0,
  "ci_project_subscriptions": 2,
  "ci_pipeline_schedules": 10,
  "ci_needs_size_limit": 50,
  "ci_registered_group_runners": 1000,
  "ci_registered_project_runners": 1000,
  "conan_max_file_size": 3221225472,
  "dotenv_variables": 20,
  "dotenv_size": 5120,
  "generic_packages_max_file_size": 5368709120,
  "helm_max_file_size": 5242880,
  "maven_max_file_size": 3221225472,
  "npm_max_file_size": 524288000,
  "nuget_max_file_size": 524288000,
  "pipeline_hierarchy_size": 1000,
  "pypi_max_file_size": 3221225472,
  "terraform_module_max_file_size": 1073741824
}
```
