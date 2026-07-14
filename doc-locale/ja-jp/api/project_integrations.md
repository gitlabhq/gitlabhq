---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクトインテグレーションAPI
description: "プロジェクトのREST APIを使用したインテグレーションのセットアップと管理を行います。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、プロジェクトの[インテグレーション](../user/project/integrations/_index.md)を管理します。

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。

## すべてのアクティブなインテグレーションをリスト表示 {#list-all-active-integrations}

{{< history >}}

- `vulnerability_events`フィールドはGitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131831)されました。
- `inherited`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154915)されました。デフォルトでは無効になっています。
- `inherited`フィールドはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

すべてのアクティブなプロジェクトインテグレーションのリストを取得します。`vulnerability_events`フィールドはGitLab Enterprise Editionでのみ利用可能です。

```plaintext
GET /projects/:id/integrations
```

レスポンス例: 

```json
[
  {
    "id": 75,
    "title": "Jenkins CI",
    "slug": "jenkins",
    "created_at": "2019-11-20T11:20:25.297Z",
    "updated_at": "2019-11-20T12:24:37.498Z",
    "active": true,
    "commit_events": true,
    "push_events": true,
    "issues_events": true,
    "alert_events": true,
    "confidential_issues_events": true,
    "merge_requests_events": true,
    "tag_push_events": false,
    "deployment_events": false,
    "note_events": true,
    "confidential_note_events": true,
    "pipeline_events": true,
    "wiki_page_events": true,
    "job_events": true,
    "comment_on_event_enabled": true,
    "inherited": false,
    "vulnerability_events": true
  },
  {
    "id": 76,
    "title": "Alerts endpoint",
    "slug": "alerts",
    "created_at": "2019-11-20T11:20:25.297Z",
    "updated_at": "2019-11-20T12:24:37.498Z",
    "active": true,
    "commit_events": true,
    "push_events": true,
    "issues_events": true,
    "alert_events": true,
    "confidential_issues_events": true,
    "merge_requests_events": true,
    "tag_push_events": true,
    "deployment_events": false,
    "note_events": true,
    "confidential_note_events": true,
    "pipeline_events": true,
    "wiki_page_events": true,
    "job_events": true,
    "comment_on_event_enabled": true,
    "inherited": false,
    "vulnerability_events": true
  }
]
```

## Apple App Store Connect {#apple-app-store-connect}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Apple App Store Connectをセットアップ {#set-up-apple-app-store-connect}

プロジェクトのApple App Store Connectインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/apple_app_store
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `app_store_issuer_id` | 文字列 | はい | Apple App Store Connect発行者ID。 |
| `app_store_key_id` | 文字列 | はい | Apple App Store ConnectキーID。 |
| `app_store_private_key_file_name` | 文字列 | はい | Apple App Store Connectプライベートキーのファイル名。 |
| `app_store_private_key` | 文字列 | はい | Apple App Store Connectプライベートキー。 |
| `app_store_protected_refs` | ブール値 | いいえ | 保護されたブランチとタグのみで変数を設定します。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Apple App Store Connectを無効化 {#disable-apple-app-store-connect}

プロジェクトのApple App Store Connectインテグレーションを無効化します。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/apple_app_store
```

### Apple App Store Connectの設定を取得 {#get-apple-app-store-connect-settings}

プロジェクトのApple App Store Connectインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/apple_app_store
```

## Asana {#asana}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Asanaをセットアップ {#set-up-asana}

プロジェクトのAsanaインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/asana
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `api_key` | 文字列 | はい | ユーザーAPIトークン。ユーザーはタスクにアクセスできる必要があります。すべてのコメントはこのユーザーに帰属します。 |
| `restrict_to_branch` | 文字列 | いいえ | 自動的に検査されるブランチのコンマ区切りリスト。すべてのブランチを含める場合は空のままにします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Asanaを無効化 {#disable-asana}

プロジェクトのAsanaインテグレーションを無効化します。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/asana
```

### Asanaの設定を取得 {#get-asana-settings}

プロジェクトのAsanaインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/asana
```

## Assembla {#assembla}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Assemblaをセットアップ {#set-up-assembla}

プロジェクトのAssemblaインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/assembla
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `token` | 文字列 | はい | 認証トークン。 |
| `subdomain` | 文字列 | いいえ | サブドメインの設定。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Assemblaを無効化 {#disable-assembla}

プロジェクトのAssemblaインテグレーションを無効化します。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/assembla
```

### Assemblaの設定を取得 {#get-assembla-settings}

プロジェクトのAssemblaインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/assembla
```

## AtlassianBamboo {#atlassian-bamboo}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### AtlassianBambooをセットアップ {#set-up-atlassian-bamboo}

プロジェクトのAtlassianBambooインテグレーションをセットアップします。

Bambooで自動リビジョンラベリングとリポジトリトリガーを設定する必要があります。

```plaintext
PUT /projects/:id/integrations/bamboo
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `bamboo_url` | 文字列 | はい | BambooルートURL（例: `https://bamboo.example.com`）。 |
| `enable_ssl_verification` | ブール値 | いいえ | SSL検証を有効にします。デフォルトは`true`（有効）です。 |
| `build_key` | 文字列 | はい | Bambooビルドプランキー（例: `KEY`）。 |
| `username` | 文字列 | はい | BambooサーバーへのAPIアクセス権を持つユーザー。 |
| `password` | 文字列 | はい | ユーザーのパスワード。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### AtlassianBambooを無効化 {#disable-atlassian-bamboo}

プロジェクトのAtlassianBambooインテグレーションを無効化します。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/bamboo
```

### AtlassianBambooの設定を取得 {#get-atlassian-bamboo-settings}

プロジェクトのAtlassianBambooインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/bamboo
```

## Bugzilla {#bugzilla}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Bugzillaをセットアップ {#set-up-bugzilla}

プロジェクトのBugzillaインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/bugzilla
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | 文字列 | はい |  新規イシューのURL。 |
| `issues_url` | 文字列 | はい | イシューのURL。 |
| `project_url` | 文字列 | はい | プロジェクトのURL。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Bugzillaを無効化 {#disable-bugzilla}

プロジェクトのBugzillaインテグレーションを無効化します。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/bugzilla
```

### Bugzillaの設定を取得 {#get-bugzilla-settings}

プロジェクトのBugzillaインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/bugzilla
```

## Buildkite {#buildkite}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Buildkiteをセットアップ {#set-up-buildkite}

プロジェクトのBuildkiteインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/buildkite
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `token` | 文字列 | はい | GitLabリポジトリを含むBuildkiteパイプラインを作成した後に取得するトークン。 |
| `project_url` | 文字列 | はい | パイプラインURL（例: `https://buildkite.com/example/pipeline`）。 |
| `enable_ssl_verification` | ブール値 | いいえ | **非推奨**: SSL検証は常に有効なため、このパラメータは効果がありません。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Buildkiteを無効化 {#disable-buildkite}

プロジェクトのBuildkiteインテグレーションを無効化します。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/buildkite
```

### Buildkiteの設定を取得 {#get-buildkite-settings}

プロジェクトのBuildkiteインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/buildkite
```

## Campfire Classic {#campfire-classic}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

Campfire Classicと統合できます。ただし、Campfire ClassicはBasecampによって[販売終了](https://gitlab.com/gitlab-org/gitlab/-/issues/329337)された古い製品です。

### Campfire Classicをセットアップ {#set-up-campfire-classic}

プロジェクトのCampfire Classicインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/campfire
```

パラメータは以下のとおりです:

| パラメータ     | 型    | 必須 | 説明                                                                                 |
|---------------|---------|----------|---------------------------------------------------------------------------------------------|
| `token`       | 文字列  | はい     | Campfire ClassicからのAPI認証トークン。トークンを取得するには、Campfire Classicにサインインして**My info**を選択します。 |
| `subdomain`   | 文字列  | いいえ    | サインインしているときの`.campfirenow.com`サブドメイン。 |
| `room`        | 文字列  | いいえ    | Campfire ClassicルームURLのID部分。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Campfire Classicを無効化 {#disable-campfire-classic}

プロジェクトのCampfire Classicインテグレーションを無効化します。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/campfire
```

### Campfire Classicの設定を取得 {#get-campfire-classic-settings}

プロジェクトのCampfire Classicインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/campfire
```

## ClickUp {#clickup}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120732)されました。
- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### ClickUpをセットアップ {#set-up-clickup}

プロジェクトのClickUpインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/clickup
```

パラメータは以下のとおりです:

| パラメータ     | 型   | 必須 | 説明    |
| ------------- | ------ | -------- | -------------- |
| `issues_url`  | 文字列 | はい     | イシューのURL。     |
| `project_url` | 文字列 | はい     | プロジェクトのURL。   |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### ClickUpを無効化 {#disable-clickup}

プロジェクトのClickUpインテグレーションを無効化します。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/clickup
```

### ClickUpの設定を取得 {#get-clickup-settings}

プロジェクトのClickUpインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/clickup
```

## Confluenceワークスペース {#confluence-workspace}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

プロジェクトのWikiとしてConfluence Cloudワークスペースを使用します。

### Confluenceワークスペースをセットアップ {#set-up-confluence-workspace}

プロジェクトのConfluenceワークスペースインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/confluence
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `confluence_url` | 文字列 | はい | `atlassian.net`でホストされているConfluenceワークスペースのURL。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Confluenceワークスペースを無効化 {#disable-confluence-workspace}

プロジェクトのConfluenceワークスペースインテグレーションを無効化します。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/confluence
```

### Confluenceワークスペースの設定を取得 {#get-confluence-workspace-settings}

プロジェクトのConfluenceワークスペースインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/confluence
```

## カスタムイシュートラッカー {#custom-issue-tracker}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### カスタムイシュートラッカーをセットアップ {#set-up-a-custom-issue-tracker}

プロジェクトのカスタムイシュートラッカーをセットアップします。

```plaintext
PUT /projects/:id/integrations/custom-issue-tracker
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | 文字列 | はい |  新規イシューのURL。 |
| `issues_url` | 文字列 | はい | イシューのURL。 |
| `project_url` | 文字列 | はい | プロジェクトのURL。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### カスタムイシュートラッカーを無効化 {#disable-a-custom-issue-tracker}

プロジェクトのカスタムイシュートラッカーを無効化します。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/custom-issue-tracker
```

### カスタムイシュートラッカーの設定を取得 {#get-custom-issue-tracker-settings}

プロジェクトのカスタムイシュートラッカーの設定を取得します。

```plaintext
GET /projects/:id/integrations/custom-issue-tracker
```

## Datadog {#datadog}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Datadogをセットアップ {#set-up-datadog}

プロジェクトのDatadogインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/datadog
```

パラメータは以下のとおりです:

| パラメータ              | 型    | 必須 | 説明                                                                                                                                                                            |
|------------------------|---------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `api_key`              | 文字列  | はい     | Datadogでの認証に使用される[APIキー](https://docs.datadoghq.com/account_management/api-app-keys/)。 |
| `datadog_ci_visibility`| ブール値 | はい     | Datadogでパイプラインおよびジョブイベントの収集を有効にし、パイプライン実行トレースを表示します。 |
| `api_url`              | 文字列  | いいえ    | Datadogサイトの完全なURL。 |
| `datadog_env`          | 文字列  | いいえ    | 自己管理型デプロイの場合、Datadogに送信されるすべてのデータ用の`env%`タグ。 |
| `datadog_service`      | 文字列  | いいえ    | Datadogでそこからのすべてのデータにタグ付けするGitLabインスタンス。複数の自己管理型デプロイを管理する場合に使用できます。 |
| `datadog_site`         | 文字列  | いいえ    | データを送信するDatadogサイト。EUサイトにデータを送信するには、`datadoghq.eu`を使用します。 |
| `datadog_tags`         | 文字列  | いいえ    | Datadogでのカスタムタグ。`key:value\nkey2:value2`の形式で1行につき1つのタグを指定します。 |
| `archive_trace_events` | ブール値 | いいえ    | 有効にすると、ジョブログがDatadogによって収集され、パイプライン実行トレースとともに表示されます（GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/346339)）。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Datadogを無効化 {#disable-datadog}

プロジェクトのDatadogインテグレーションを無効化します。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/datadog
```

### Datadogの設定を取得 {#get-datadog-settings}

プロジェクトのDatadogインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/datadog
```

## Diffblue Cover {#diffblue-cover}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Diffblue Coverをセットアップ {#set-up-diffblue-cover}

プロジェクトのDiffblue Coverインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/diffblue-cover
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `diffblue_license_key` | 文字列 | はい | Diffblue Coverライセンスキー。 |
| `diffblue_access_token_name` | 文字列 | はい | Diffblue Coverがパイプラインで使用するアクセストークン名。 |
| `diffblue_access_token_secret` | 文字列  | はい | Diffblue Coverがパイプラインで使用するアクセストークンシークレット。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Diffblue Coverを無効化 {#disable-diffblue-cover}

プロジェクトのDiffblue Coverインテグレーションを無効化します。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/diffblue-cover
```

### Diffblue Coverの設定を取得 {#get-diffblue-cover-settings}

プロジェクトのDiffblue Coverインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/diffblue-cover
```

## Discord通知 {#discord-notifications}

{{< history >}}

- `_channel`パラメータはGitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125621)されました。
- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Discord通知をセットアップ {#set-up-discord-notifications}

プロジェクトのDiscord通知をセットアップします。

```plaintext
PUT /projects/:id/integrations/discord
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Discord Webhook（例: `https://discord.com/api/webhooks/...`）。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `confidential_issue_channel` | 文字列 | いいえ | 機密イシューイベントの通知を受信するWebhookオーバーライド。 |
| `confidential_note_events` | ブール値 | いいえ | 機密ノートイベントの通知を有効にします。 |
| `confidential_note_channel` | 文字列 | いいえ | 機密ノートイベントの通知を受信するWebhookオーバーライド。 |
| `deployment_events` | ブール値 | いいえ | デプロイイベントの通知を有効にします。 |
| `deployment_channel` | 文字列 | いいえ | デプロイイベントの通知を受信するWebhookオーバーライド。 |
| `group_confidential_mentions_events` | ブール値 | いいえ | グループの機密メンションイベントの通知を有効にします。 |
| `group_confidential_mentions_channel` | 文字列 | いいえ | グループの機密メンションイベントの通知を受信するWebhookオーバーライド。 |
| `group_mentions_events` | ブール値 | いいえ | グループメンションイベントの通知を有効にします。 |
| `group_mentions_channel` | 文字列 | いいえ | グループメンションイベントの通知を受信するWebhookオーバーライド。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `issue_channel` | 文字列 | いいえ | イシューイベントの通知を受信するWebhookオーバーライド。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `merge_request_channel` | 文字列 | いいえ | マージリクエストイベントの通知を受信するWebhookオーバーライド。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `note_channel` | 文字列 | いいえ | ノートイベントの通知を受信するWebhookオーバーライド。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_when_pipeline_status_changes` | ブール値 | いいえ | リファレンスのパイプラインステータスが変更された場合にのみ通知を送信します。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `pipeline_channel` | 文字列 | いいえ | パイプラインイベントの通知を受信するWebhookオーバーライド。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `push_channel` | 文字列 | いいえ | プッシュイベントの通知を受信するWebhookオーバーライド。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `tag_push_channel` | 文字列 | いいえ | タグプッシュイベントの通知を受信するWebhookオーバーライド。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `wiki_page_channel` | 文字列 | いいえ | Wikiページイベントの通知を受信するWebhookオーバーライド。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Discord通知を無効化 {#disable-discord-notifications}

プロジェクトのDiscord通知を無効化します。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/discord
```

### Discord通知の設定を取得 {#get-discord-notifications-settings}

プロジェクトのDiscord通知の設定を取得します。

```plaintext
GET /projects/:id/integrations/discord
```

## Drone {#drone}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Droneをセットアップ {#set-up-drone}

プロジェクトのDroneインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/drone-ci
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `token` | 文字列 | はい | Drone CIトークン。 |
| `drone_url` | 文字列 | はい | Drone CI URL（例: `http://drone.example.com`）。 |
| `enable_ssl_verification` | ブール値 | いいえ | SSL検証を有効にします。デフォルトは`true`（有効）です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Droneを無効化 {#disable-drone}

プロジェクトのDroneインテグレーションを無効化します。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/drone-ci
```

### Droneの設定を取得 {#get-drone-settings}

プロジェクトのDroneインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/drone-ci
```

## プッシュ時にメールを送信 {#emails-on-push}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### プッシュ時にメールを送信をセットアップ {#set-up-emails-on-push}

プロジェクトのプッシュ時にメールを送信インテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/emails-on-push
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `recipients` | 文字列 | はい | 空白で区切られたメールアドレス。 |
| `disable_diffs` | ブール値 | いいえ | コード差分を無効にします。 |
| `send_from_committer_email` | ブール値 | いいえ | コミッターから送信します。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。通知はタグプッシュに対して常に起動されます。デフォルト値は`all`です。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### プッシュ時にメールを送信を無効化 {#disable-emails-on-push}

プロジェクトのプッシュ時にメールを送信インテグレーションを無効化します。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/emails-on-push
```

### プッシュ時にメールを送信の設定を取得 {#get-emails-on-push-settings}

プロジェクトのプッシュ時にメールを送信インテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/emails-on-push
```

## EngineeringワークフローManagement (EWM) {#engineering-workflow-management-ewm}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### EWMをセットアップ {#set-up-ewm}

プロジェクトのEWMインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/ewm
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | 文字列 | はい | 新規イシューのURL。 |
| `project_url`   | 文字列 | はい | プロジェクトのURL。 |
| `issues_url`    | 文字列 | はい | イシューのURL。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### EWMを無効化 {#disable-ewm}

プロジェクトのEWMインテグレーションを無効化します。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/ewm
```

### EWMの設定を取得 {#get-ewm-settings}

プロジェクトのEWMインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/ewm
```

## 外部Wiki {#external-wiki}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### 外部Wikiをセットアップ {#set-up-an-external-wiki}

プロジェクトの外部Wikiをセットアップします。

```plaintext
PUT /projects/:id/integrations/external-wiki
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `external_wiki_url` | 文字列 | はい | 外部WikiのURL。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### 外部Wikiを無効化 {#disable-an-external-wiki}

プロジェクトの外部Wikiを無効化します。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/external-wiki
```

### 外部Wikiの設定を取得 {#get-external-wiki-settings}

プロジェクトの外部Wikiの設定を取得します。

```plaintext
GET /projects/:id/integrations/external-wiki
```

## GitGuardian {#gitguardian}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.9で`git_guardian_integration`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/435706)されました。デフォルトでは有効になっています。GitLab.comで無効になりました。
- GitLab.com 17.7の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/438695#note_2226917025)になりました。
- GitLab 17.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176391)になりました。機能フラグ`git_guardian_integration`は削除されました。
- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。
- `api_url`パラメータはGitLab 19.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/599742)されました。

{{< /history >}}

[GitGuardian](https://www.gitguardian.com/)は、ソースコードリポジトリ内のAPIキーやパスワードなどの機密データを検出するサイバーセキュリティサービスです。これはGitリポジトリをスキャンし、ポリシー違反についてアラートを出し、ハッカーが悪用する前にセキュリティイシューを修正するのに組織を支援します。

GitLabがGitGuardianポリシーに基づいてコミットを拒否するように設定できます。

既知のイシューとトラブルシューティングの手順については、[GitGuardianトラブルシューティング](../user/project/integrations/git_guardian.md#troubleshooting)を参照してください。

### GitGuardianをセットアップ {#set-up-gitguardian}

プロジェクトのGitGuardianインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/git-guardian
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明                                   |
| --------- | ---- | -------- |-----------------------------------------------|
| `token` | 文字列 | はい | `scan`スコープを持つGitGuardian APIトークン。 |
| `api_url` | 文字列 | いいえ | GitGuardian APIベースURL。`https://api.gitguardian.com`がデフォルトです。EUリージョンには`https://api.eu1.gitguardian.com`を使用するか、自己ホスト型GitGuardianインスタンスのURLを使用します。HTTPSを使用する必要があります。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### GitGuardianを無効化 {#disable-gitguardian}

プロジェクトのGitGuardianインテグレーションを無効化します。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/git-guardian
```

### GitGuardianの設定を取得 {#get-gitguardian-settings}

プロジェクトのGitGuardianインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/git-guardian
```

## GitHub {#github}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### GitHubをセットアップ {#set-up-github}

プロジェクトのGitHubインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/github
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `token` | 文字列 | はい | `repo:status` OAuthスコープを持つGitHub APIトークン。 |
| `repository_url` | 文字列 | はい | GitHubリポジトリURL。 |
| `static_context` | ブール値 | いいえ | GitLabインスタンスのホスト名を[ステータスチェック名](../user/project/integrations/github.md#static-or-dynamic-status-check-names)に追加します。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### GitHubを無効化 {#disable-github}

プロジェクトのGitHubインテグレーションを無効化します。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/github
```

### GitHubの設定を取得 {#get-github-settings}

プロジェクトのGitHubインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/github
```

## GitLab for Jira Cloudアプリ {#gitlab-for-jira-cloud-app}

GitLab for Jira Cloudアプリのインテグレーションは、[Jiraでのグループリンクおよびリンク解除](../integration/jira/connect-app.md#configure-the-gitlab-for-jira-cloud-app)を通じて自動的に有効または無効になります。GitLabインテグレーションフォームまたはAPIを使用して、インテグレーションを有効または無効にすることはできません。

### プロジェクトのインテグレーションを更新 {#update-integration-for-a-project}

このAPIエンドポイントを使用して、Jiraでグループリンクによって作成したインテグレーションを更新します。

```plaintext
PUT /projects/:id/integrations/jira-cloud-app
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `jira_cloud_app_service_ids` | 文字列 | いいえ | Jira Service ManagementサービスID。複数のIDを区切るにはカンマ（`,`）を使用します。 |
| `jira_cloud_app_enable_deployment_gating` | ブール値 | いいえ | Jira Service ManagementからのブロックされたGitLabデプロイに対してデプロイゲートを有効にします。 |
| `jira_cloud_app_deployment_gating_environments` | 文字列 | いいえ | デプロイゲートを有効にする環境（本番環境、ステージング、テスト、または開発）。デプロイゲートが有効になっている場合に必要です。複数の環境を区切るにはカンマ（`,`）を使用します。 |

### GitLab for Jira Cloudアプリの設定を取得 {#get-gitlab-for-jira-cloud-app-settings}

プロジェクトのGitLab for Jira Cloudアプリインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/jira-cloud-app
```

## GitLab for Slackアプリ {#gitlab-for-slack-app}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### GitLab for Slackアプリをセットアップ {#set-up-gitlab-for-slack-app}

プロジェクトのGitLab for Slackアプリインテグレーションを更新します。

インテグレーションにはGitLab API単独では取得できないOAuth 2.0トークンが必要なため、APIを介してGitLab for Slackアプリを作成することはできません。代わりに、GitLab UIから[アプリをインストール](../user/project/integrations/gitlab_slack_application.md#install-the-gitlab-for-slack-app)する必要があります。その後、このAPIエンドポイントを使用してインテグレーションを更新できます。

```plaintext
PUT /projects/:id/integrations/gitlab-slack-application
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `channel` | 文字列 | いいえ | 他のチャンネルが設定されていない場合に使用するデフォルトのチャンネル。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_when_pipeline_status_changes` | ブール値 | いいえ | リファレンスのパイプラインステータスが変更された場合にのみ通知を送信します。 |
| `notify_only_default_branch` | ブール値 | いいえ | **非推奨**: このパラメータは`branches_to_be_notified`に置き換えられました。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `alert_events` | ブール値 | いいえ | アラートイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密ノートイベントの通知を有効にします。 |
| `deployment_events` | ブール値 | いいえ | デプロイイベントの通知を有効にします。 |
| `incidents_events` | ブール値 | いいえ | インシデントイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `vulnerability_events` | ブール値 | いいえ | 脆弱性イベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `labels_to_be_notified` | 文字列 | いいえ | ラベルの通知を送信します。設定されていない場合、すべてのイベントの通知を受け取ります。 |
| `labels_to_be_notified_behavior` | 文字列 | いいえ | ラベルの通知対象。有効なオプションは`match_any`と`match_all`です。`match_any`がデフォルトです。 |
| `push_channel` | 文字列 | いいえ | プッシュイベントの通知を受け取るチャンネルの名前。 |
| `issue_channel` | 文字列 | いいえ | イシューイベントの通知を受け取るチャンネルの名前。 |
| `confidential_issue_channel` | 文字列 | いいえ | 機密イシューイベントの通知を受け取るチャンネルの名前。 |
| `merge_request_channel` | 文字列 | いいえ | マージリクエストイベントの通知を受け取るチャンネルの名前。 |
| `note_channel` | 文字列 | いいえ | ノートイベントの通知を受け取るチャンネルの名前。 |
| `confidential_note_channel` | 文字列 | いいえ | 機密ノートイベントの通知を受け取るチャンネルの名前。 |
| `tag_push_channel` | 文字列 | いいえ | タグプッシュイベントの通知を受け取るチャンネルの名前。 |
| `pipeline_channel` | 文字列 | いいえ | パイプラインイベントの通知を受け取るチャンネルの名前。 |
| `wiki_page_channel` | 文字列 | いいえ | Wikiページイベントの通知を受け取るチャンネルの名前。 |
| `deployment_channel` | 文字列 | いいえ | デプロイイベントの通知を受け取るチャンネルの名前。 |
| `incident_channel` | 文字列 | いいえ | インシデントイベントの通知を受け取るチャンネルの名前。 |
| `vulnerability_channel` | 文字列 | いいえ | 脆弱性イベントの通知を受け取るチャンネルの名前。 |
| `alert_channel` | 文字列 | いいえ | アラートイベントの通知を受け取るチャンネルの名前。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### GitLab for Slackアプリを無効にする {#disable-gitlab-for-slack-app}

プロジェクトのGitLab for Slackアプリインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/gitlab-slack-application
```

### GitLab for Slackアプリの設定を取得 {#get-gitlab-for-slack-app-settings}

プロジェクトのGitLab for Slackアプリインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/gitlab-slack-application
```

## Google Chat {#google-chat}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Google Chatをセットアップする {#set-up-google-chat}

プロジェクトのGoogle Chatインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/hangouts-chat
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Hangouts Chat Webhook（例: `https://chat.googleapis.com/v1/spaces...`）。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_when_pipeline_status_changes` | ブール値 | いいえ | リファレンスのパイプラインステータスが変更された場合にのみ通知を送信します。 |
| `notify_only_default_branch` | ブール値 | いいえ | **非推奨**: このパラメータは`branches_to_be_notified`に置き換えられました。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密ノートイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Google Chatを無効にする {#disable-google-chat}

プロジェクトのGoogle Chatインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/hangouts-chat
```

### Google Chatの設定を取得 {#get-google-chat-settings}

プロジェクトのGoogle Chatインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/hangouts-chat
```

## Google Artifact Management {#google-artifact-management}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 16.9で`google_cloud_support_feature_flag`[フラグ](../administration/feature_flags/_index.md)とともに[ベータ版](../policy/development_stages_support.md)機能として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/425066)されました。デフォルトでは無効になっています。
- GitLab 17.1の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472)になりました。機能フラグ`google_cloud_support_feature_flag`は削除されました。
- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

この機能は[ベータ版](../policy/development_stages_support.md)です。

### Google Artifact Managementをセットアップする {#set-up-google-artifact-management}

プロジェクトのGoogle Artifact Managementインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/google-cloud-platform-artifact-registry
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `artifact_registry_project_id` | 文字列 | はい | Google CloudプロジェクトのID。 |
| `artifact_registry_location` | 文字列 | はい | Artifact Registryリポジトリの場所。 |
| `artifact_registry_repositories` | 文字列 | はい | Artifactレジストリのリポジトリ。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Google Artifact Managementを無効にする {#disable-google-artifact-management}

プロジェクトのGoogle Artifact Managementインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/google-cloud-platform-artifact-registry
```

### Google Artifact Managementの設定を取得 {#get-google-artifact-management-settings}

プロジェクトのGoogle Artifact Managementインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/google-cloud-platform-artifact-registry
```

## Google Cloud Identity and Access Management（IAM） {#google-cloud-identity-and-access-management-iam}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 16.10で[導入](../policy/development_stages_support.md)された、`google_cloud_support_feature_flag`という名前の[フラグ](../administration/feature_flags/_index.md)付きベータ機能。デフォルトでは無効になっています。
- GitLab 17.1の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472)になりました。機能フラグ`google_cloud_support_feature_flag`は削除されました。
- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

この機能は[ベータ版](../policy/development_stages_support.md)です。

### Google Cloud Identity and Access Managementをセットアップする {#set-up-google-cloud-identity-and-access-management}

プロジェクトのGoogle Cloud Identity and Access Managementインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/google-cloud-platform-workload-identity-federation
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `workload_identity_federation_project_id` | 文字列 | はい | Workload Identity Federation（ワークロードアイデンティティフェデレーション）のGoogle CloudプロジェクトID。 |
| `workload_identity_federation_project_number` | 整数 | はい | Workload Identity Federation（ワークロードアイデンティティフェデレーション）のGoogle Cloudプロジェクト番号。 |
| `workload_identity_pool_id` | 文字列 | はい | ワークロードIDプールのID。 |
| `workload_identity_pool_provider_id` | 文字列 | はい | Workload Identityプールプロバイダ（Workload Identityプールプロバイダ）のID。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Google Cloud Identity and Access Managementを無効にする {#disable-google-cloud-identity-and-access-management}

プロジェクトのGoogle Cloud Identity and Access Managementインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/google-cloud-platform-workload-identity-federation
```

### Google Cloud Identity and Access Managementを取得 {#get-google-cloud-identity-and-access-management}

プロジェクトのGoogle Cloud Identity and Access Managementの設定を取得します。

```plaintext
GET /projects/:id/integration/google-cloud-platform-workload-identity-federation
```

## Google Play {#google-play}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Google Playをセットアップする {#set-up-google-play}

プロジェクトのGoogle Playインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/google-play
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `package_name` | 文字列 | はい | Google Playのアプリのパッケージ名。 |
| `service_account_key` | 文字列 | はい | Google Playサービスアカウントキー。 |
| `service_account_key_file_name` | 文字列 | はい | Google Playサービスアカウントキーのファイル名。 |
| `google_play_protected_refs` | ブール値 | いいえ | 保護されたブランチとタグのみで変数を設定します。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Google Playを無効にする {#disable-google-play}

プロジェクトのGoogle Playインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/google-play
```

### Google Playの設定を取得 {#get-google-play-settings}

プロジェクトのGoogle Playインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/google-play
```

## Harbor {#harbor}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Harborをセットアップする {#set-up-harbor}

プロジェクトのHarborインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/harbor
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `url` | 文字列 | はい | GitLabプロジェクトにリンクされたHarborインスタンスへのベースURL。例: `https://demo.goharbor.io`。 |
| `project_name` | 文字列 | はい | Harborインスタンス内のプロジェクト名。例: `testproject`。 |
| `username` | 文字列 | はい | Harborインターフェースで作成されたユーザー名。 |
| `password` | 文字列 | はい | ユーザーのパスワード。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Harborを無効にする {#disable-harbor}

プロジェクトのHarborインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/harbor
```

### Harborの設定を取得 {#get-harbor-settings}

プロジェクトのHarborインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/harbor
```

## irker (IRCゲートウェイ) {#irker-irc-gateway}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### irkerをセットアップする {#set-up-irker}

プロジェクトのirkerインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/irker
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `recipients` | 文字列 | はい | チャンネルまたはメールアドレスのカンマ区切りリスト。 |
| `default_irc_uri` | 文字列 | いいえ | 各受信者の前に付加するURI。デフォルト値は`irc://irc.network.net:6697/`です。 |
| `server_host` | 文字列 | いいえ | irkerデーモンのホスト名。デフォルト値は`localhost`です。 |
| `server_port` | 整数 | いいえ | irkerデーモンのポート。デフォルト値は`6659`です。 |
| `colorize_messages` | ブール値 | いいえ | メッセージを色分けします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### irkerを無効にする {#disable-irker}

プロジェクトのirkerインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/irker
```

### irkerの設定を取得 {#get-irker-settings}

プロジェクトのirkerインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/irker
```

## Jenkins {#jenkins}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Jenkinsをセットアップする {#set-up-jenkins}

プロジェクト用のJenkinsインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/jenkins
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `jenkins_url` | 文字列 | はい | JenkinsサーバーのURL。 |
| `enable_ssl_verification` | ブール値 | いいえ | SSL検証を有効にします。デフォルトは`true`（有効）です。 |
| `project_name` | 文字列 | はい | Jenkinsプロジェクト名。 |
| `username` | 文字列 | いいえ | Jenkinsサーバーのユーザー名。 |
| `password` | 文字列 | いいえ | Jenkinsサーバーのパスワード。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Jenkinsを無効にする {#disable-jenkins}

プロジェクトのJenkinsインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/jenkins
```

### Jenkins設定を取得する {#get-jenkins-settings}

プロジェクトのJenkinsインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/jenkins
```

## JetBrains TeamCity {#jetbrains-teamcity}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### JetBrains TeamCityをセットアップする {#set-up-jetbrains-teamcity}

プロジェクト用のJetBrains TeamCityインテグレーションをセットアップします。

TeamCityのビルド設定では、`%build.vcs.number%`のビルド番号形式を使用する必要があります。VCSルートの詳細設定で、すべてのブランチのモニタリングを設定し、マージリクエストをビルドできるようにします。

```plaintext
PUT /projects/:id/integrations/teamcity
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `teamcity_url` | 文字列 | はい | TeamCityルートURL (例: `https://teamcity.example.com`)。 |
| `enable_ssl_verification` | ブール値 | いいえ | SSL検証を有効にします。デフォルトは`true`（有効）です。 |
| `build_type` | 文字列 | はい | TeamCityプロジェクトのビルド設定ID。 |
| `username` | 文字列 | はい | 手動ビルドをトリガーする権限を持つユーザー。 |
| `password` | 文字列 | はい | ユーザーのパスワード。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### JetBrains TeamCityを無効にする {#disable-jetbrains-teamcity}

プロジェクトのJetBrains TeamCityインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/teamcity
```

### JetBrains TeamCity設定を取得する {#get-jetbrains-teamcity-settings}

プロジェクトのJetBrains TeamCityインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/teamcity
```

## Jiraイシュー {#jira-issues}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Jiraイシューをセットアップする {#set-up-jira-issues}

プロジェクトの[Jiraイシューインテグレーション](../integration/jira/configure.md)をセットアップします。

```plaintext
PUT /projects/:id/integrations/jira
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `url`           | 文字列 | はい | このGitLabプロジェクトにリンクされているJiraプロジェクトのURL (例: `https://jira.example.com`)。 |
| `api_url`   | 文字列 | いいえ | JiraインスタンスAPIへのベースURL。設定されていない場合、Web URL値が使用されます (例: `https://jira-api.example.com`)。 |
| `username`      | 文字列 | いいえ   | Jiraで使用するメールまたはユーザー名。Jira Cloudにはメールを、Jira Data CenterおよびJira Serverにはユーザー名を使用します。Basic認証 (`jira_auth_type`が`0`) を使用する場合に必須です。 |
| `password`      | 文字列 | はい  | Jiraで使用するJira APIトークン、パスワード、またはパーソナルアクセストークン。基本認証 (`jira_auth_type`が`0`) の場合、Jira CloudにはAPIトークンを、Jira Data CenterまたはJira Serverにはパスワードを使用します。Jiraパーソナルアクセストークン認証 (`jira_auth_type`が`1`) の場合、パーソナルアクセストークンを使用します。Jira Cloudサービスアカウント認証の場合、APIトークンを使用します。 |
| `jira_auth_type`| 整数 | いいえ  | Jiraで使用する認証方法。Basic認証には`0`、Jiraパーソナルアクセストークンには`1`、Jira Cloudサービスアカウントには`2`を使用します。`0`がデフォルトです。 |
| `jira_issue_prefix` | 文字列 | いいえ | Jiraイシューキーに一致するプレフィックス。 |
| `jira_issue_regex` | 文字列 | いいえ | Jiraイシューキーに一致する正規表現。 |
| `jira_issue_transition_automatic` | ブール値 | いいえ | 自動イシュー[移行](../integration/jira/issues.md#automatic-issue-transitions)を有効にする。有効な場合、`jira_issue_transition_id`より優先されます。`false`がデフォルトです。 |
| `jira_issue_transition_id` | 文字列 | いいえ | [カスタムイシュー移行](../integration/jira/issues.md#custom-issue-transitions)の1つまたは複数の移行ID。`jira_issue_transition_automatic`が有効な場合は無視されます。デフォルトは空の文字列で、カスタム移行を無効にします。 |
| `commit_events` | ブール値 | いいえ | コミットイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `comment_on_event_enabled` | ブール値 | いいえ | 各GitLabイベント (コミットまたはマージリクエスト) でJiraイシューにコメントを有効にします。 |
| `issues_enabled` | ブール値 | いいえ | GitLabでJiraイシューの表示を有効にする。GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/267015)されました。 |
| `project_keys` | 文字列の配列 | いいえ | Jiraプロジェクトのキー。`issues_enabled`が`true`の場合、この設定は、GitLabでイシューを表示するJiraプロジェクトを指定します。GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/267015)されました。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |
| `vulnerabilities_enabled` | ブール値 | いいえ | GitLab EEでのみ利用可能です。`true`に設定すると、GitLabの脆弱性に対してJiraイシューが作成されます。|
| `vulnerabilities_issuetype` | 数値 | いいえ | GitLab EEでのみ利用可能です。脆弱性からイシューを作成する際に使用するJiraイシュータイプのID。 |
| `project_key` | 文字列 | いいえ | GitLab EEでのみ利用可能です。脆弱性からイシューを作成する際に使用するプロジェクトのキー。脆弱性からイシューを作成するためにインテグレーションを使用する場合、このパラメータは必須です。 |
| `customize_jira_issue_enabled` | ブール値 | いいえ | GitLab EEでのみ利用可能です。`true`に設定すると、脆弱性からJiraイシューを作成する際に、Jiraインスタンスで事前入力されたフォームが開きます。 |

### Jiraを無効にする {#disable-jira}

プロジェクトのJiraイシューインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/jira
```

### Jira設定を取得する {#get-jira-settings}

プロジェクトのJiraイシューインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/jira
```

## Linear {#linear}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198297)されました。

{{< /history >}}

### Linearをセットアップする {#set-up-linear}

グループ用のLinearインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/linear
```

パラメータは以下のとおりです:

| パラメータ     | 型   | 必須 | 説明    |
| ------------- | ------ | -------- | -------------- |
| `workspace_url`  | 文字列 | はい     | イシューのURL。     |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Linearを無効にする {#disable-linear}

グループ用のLinearインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/linear
```

### Linear設定を取得する {#get-linear-settings}

グループのLinearインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/linear
```

## Matrix通知 {#matrix-notifications}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Matrix通知をセットアップする {#set-up-matrix-notifications}

プロジェクト用のMatrix通知をセットアップします。

```plaintext
PUT /projects/:id/integrations/matrix
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `hostname`   | 文字列 | いいえ | Matrixサーバーのカスタムホスト名。デフォルト値は`https://matrix.org`です。 |
| `token`   | 文字列 | はい | Matrixアクセストークン (例: `syt-zyx57W2v1u123ew11`)。 |
| `room` | 文字列 | はい | ターゲットルームの固有識別子 (形式: `!qPKKM111FFKKsfoCVy:matrix.org`)。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_when_pipeline_status_changes` | ブール値 | いいえ | リファレンスのパイプラインステータスが変更された場合にのみ通知を送信します。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密ノートイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Matrix通知を無効にする {#disable-matrix-notifications}

プロジェクトのMatrix通知を無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/matrix
```

### Matrix通知設定を取得する {#get-matrix-notifications-settings}

プロジェクトのMatrix通知設定を取得します。

```plaintext
GET /projects/:id/integrations/matrix
```

## Mattermost通知 {#mattermost-notifications}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Mattermost通知をセットアップする {#set-up-mattermost-notifications}

プロジェクト用のMattermost通知をセットアップします。

```plaintext
PUT /projects/:id/integrations/mattermost
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Mattermost通知Webhook (例: `http://mattermost.example.com/hooks/...`)。 |
| `username` | 文字列 | いいえ | Mattermost通知ユーザー名。 |
| `channel` | 文字列 | いいえ | 他のチャンネルが設定されていない場合に使用するデフォルトのチャンネル。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_when_pipeline_status_changes` | ブール値 | いいえ | リファレンスのパイプラインステータスが変更された場合にのみ通知を送信します。 |
| `notify_only_default_branch` | ブール値 | いいえ | **非推奨**: このパラメータは`branches_to_be_notified`に置き換えられました。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `labels_to_be_notified` | 文字列 | いいえ | ラベルの通知を送信します。すべてのイベントの通知を受信するには、空白のままにします。 |
| `labels_to_be_notified_behavior` | 文字列 | いいえ | ラベルの通知対象。有効なオプションは`match_any`と`match_all`です。デフォルト値は`match_any`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密ノートイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `push_channel` | 文字列 | いいえ | プッシュイベントの通知を受信するチャンネルの名前。 |
| `issue_channel` | 文字列 | いいえ | イシューイベントの通知を受信するチャンネルの名前。 |
| `confidential_issue_channel` | 文字列 | いいえ | 機密イシューイベントの通知を受信するチャンネルの名前。 |
| `merge_request_channel` | 文字列 | いいえ | マージリクエストイベントの通知を受信するチャンネルの名前。 |
| `note_channel` | 文字列 | いいえ | ノートイベントの通知を受信するチャンネルの名前。 |
| `confidential_note_channel` | 文字列 | いいえ | 機密ノートイベントの通知を受信するチャンネルの名前。 |
| `tag_push_channel` | 文字列 | いいえ | タグプッシュイベントの通知を受信するチャンネルの名前。 |
| `pipeline_channel` | 文字列 | いいえ | パイプラインイベントの通知を受信するチャンネルの名前。 |
| `wiki_page_channel` | 文字列 | いいえ | Wikiページイベントの通知を受信するチャンネルの名前。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Mattermost通知を無効にする {#disable-mattermost-notifications}

プロジェクトのMattermost通知を無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/mattermost
```

### Mattermost通知設定を取得する {#get-mattermost-notifications-settings}

プロジェクトのMattermost通知設定を取得します。

```plaintext
GET /projects/:id/integrations/mattermost
```

## Mattermostスラッシュコマンド {#mattermost-slash-commands}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Mattermostスラッシュコマンドをセットアップする {#set-up-mattermost-slash-commands}

プロジェクト用のMattermostスラッシュコマンドをセットアップします。

```plaintext
PUT /projects/:id/integrations/mattermost-slash-commands
```

パラメータは以下のとおりです:

| パラメータ | 型   | 必須 | 説明           |
| --------- | ------ | -------- | --------------------- |
| `token`   | 文字列 | はい      | Mattermostトークン。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Mattermostスラッシュコマンドを無効にする {#disable-mattermost-slash-commands}

プロジェクトのMattermostスラッシュコマンドを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/mattermost-slash-commands
```

### Mattermostスラッシュコマンド設定を取得する {#get-mattermost-slash-commands-settings}

プロジェクトのMattermostスラッシュコマンド設定を取得します。

```plaintext
GET /projects/:id/integrations/mattermost-slash-commands
```

## Microsoft Teams通知 {#microsoft-teams-notifications}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Microsoft Teams通知をセットアップする {#set-up-microsoft-teams-notifications}

プロジェクト用のMicrosoft Teams通知をセットアップします。

```plaintext
PUT /projects/:id/integrations/microsoft-teams
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Microsoft Teams Webhook (例: `https://outlook.office.com/webhook/...`)。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_when_pipeline_status_changes` | ブール値 | いいえ | リファレンスのパイプラインステータスが変更された場合にのみ通知を送信します。 |
| `notify_only_default_branch` | ブール値 | いいえ | **非推奨**: このパラメータは`branches_to_be_notified`に置き換えられました。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密ノートイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Microsoft Teams通知を無効にする {#disable-microsoft-teams-notifications}

プロジェクトのMicrosoft Teams通知を無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/microsoft-teams
```

### Microsoft Teams通知設定を取得する {#get-microsoft-teams-notifications-settings}

プロジェクトのMicrosoft Teams通知設定を取得します。

```plaintext
GET /projects/:id/integrations/microsoft-teams
```

## モックCI {#mock-ci}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

このインテグレーションは開発環境でのみ利用可能です。例のモックCIサーバーについては、[`gitlab-org/gitlab-mock-ci-service`](https://gitlab.com/gitlab-org/gitlab-mock-ci-service)を参照してください。

### モックCIをセットアップする {#set-up-mock-ci}

プロジェクト用のモックCIインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/mock-ci
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `mock_service_url` | 文字列 | はい | モックCIインテグレーションのURL。 |
| `enable_ssl_verification` | ブール値 | いいえ | SSL検証を有効にします。デフォルトは`true`（有効）です。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### モックCIを無効にする {#disable-mock-ci}

プロジェクトのモックCIインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/mock-ci
```

### モックCI設定を取得する {#get-mock-ci-settings}

プロジェクトのモックCIインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/mock-ci
```

## Packagist {#packagist}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Packagistをセットアップする {#set-up-packagist}

プロジェクト用のPackagistインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/packagist
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `username` | 文字列 | はい | Packagistアカウントのユーザー名。 |
| `token` | 文字列 | はい | PackagistサーバーのAPIトークン。 |
| `server` | ブール値 | いいえ | PackagistサーバーのURL。デフォルト値は`https://packagist.org`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Packagistを無効にする {#disable-packagist}

プロジェクトのPackagistインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/packagist
```

### Packagist設定を取得する {#get-packagist-settings}

プロジェクトのPackagistインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/packagist
```

## Phorge {#phorge}

{{< history >}}

- GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145863)されました。
- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Phorgeをセットアップする {#set-up-phorge}

プロジェクト用のPhorgeインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/phorge
```

パラメータは以下のとおりです:

| パラメータ       | 型   | 必須 | 説明           |
|-----------------|--------|----------|-----------------------|
| `issues_url`    | 文字列 | はい     | イシューのURL。     |
| `project_url`   | 文字列 | はい     | プロジェクトのURL。   |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Phorgeを無効にする {#disable-phorge}

プロジェクトのPhorgeインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/phorge
```

### Phorge設定を取得する {#get-phorge-settings}

プロジェクトのPhorgeインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/phorge
```

## パイプラインステータスメール {#pipeline-status-emails}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### パイプラインステータスメールをセットアップする {#set-up-pipeline-status-emails}

プロジェクト用のパイプラインステータスメールをセットアップします。

```plaintext
PUT /projects/:id/integrations/pipelines-email
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `recipients` | 文字列 | はい | 受信者メールアドレスのカンマ区切りリスト。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `notify_only_default_branch` | ブール値 | いいえ | デフォルトブランチの通知を送信します。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### パイプラインステータスメールを無効にする {#disable-pipeline-status-emails}

プロジェクト用のパイプラインステータスメールを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/pipelines-email
```

### パイプラインステータスメール設定を取得する {#get-pipeline-status-emails-settings}

プロジェクト用のパイプラインステータスメール設定を取得します。

```plaintext
GET /projects/:id/integrations/pipelines-email
```

## Pivotal Tracker {#pivotal-tracker}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Pivotal Trackerをセットアップする {#set-up-pivotal-tracker}

プロジェクト用のPivotal Trackerインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/pivotaltracker
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `token` | 文字列 | はい | Pivotal Trackerトークン。 |
| `restrict_to_branch` | ブール値 | いいえ | 自動的に検査するブランチのカンマ区切りリスト。すべてのブランチを含める場合は空のままにします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Pivotal Trackerを無効にする {#disable-pivotal-tracker}

プロジェクトのPivotal Trackerインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/pivotaltracker
```

### Pivotal Tracker設定を取得する {#get-pivotal-tracker-settings}

プロジェクトのPivotal Trackerインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/pivotaltracker
```

## Pumble {#pumble}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Pumbleをセットアップする {#set-up-pumble}

プロジェクト用のPumbleインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/pumble
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Pumble Webhook (例: `https://api.pumble.com/workspaces/x/...`)。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルトは`default`です。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密ノートイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Pumbleを無効にする {#disable-pumble}

プロジェクトのPumbleインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/pumble
```

### Pumble設定を取得する {#get-pumble-settings}

プロジェクトのPumbleインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/pumble
```

## Pushover {#pushover}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Pushoverをセットアップする {#set-up-pushover}

プロジェクト用のPushoverインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/pushover
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `api_key` | 文字列 | はい | アプリケーションキー。 |
| `user_key` | 文字列 | はい | ユーザーキー。 |
| `priority` | 文字列 | はい | 優先度。 |
| `device` | 文字列 | いいえ | すべての有効なデバイスで空白のままにします。 |
| `sound` | 文字列 | いいえ | 通知のサウンド。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Pushoverを無効にする {#disable-pushover}

プロジェクトのPushoverインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/pushover
```

### Pushover設定を取得する {#get-pushover-settings}

プロジェクトのPushoverインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/pushover
```

## Redmine {#redmine}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Redmineをセットアップする {#set-up-redmine}

プロジェクト用のRedmineインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/redmine
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | 文字列 | はい | 新規イシューのURL。 |
| `project_url` | 文字列 | はい | プロジェクトのURL。 |
| `issues_url` | 文字列 | はい | イシューのURL。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Redmineを無効にする {#disable-redmine}

プロジェクトのRedmineインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/redmine
```

### Redmine設定を取得する {#get-redmine-settings}

プロジェクトのRedmineインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/redmine
```

## Slack通知 {#slack-notifications}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Slack通知をセットアップする {#set-up-slack-notifications}

プロジェクト用のSlack通知をセットアップします。

```plaintext
PUT /projects/:id/integrations/slack
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Slack通知Webhook (例: `https://hooks.slack.com/services/...`)。 |
| `username` | 文字列 | いいえ | Slack通知ユーザー名。 |
| `channel` | 文字列 | いいえ | 他のチャンネルが設定されていない場合に使用するデフォルトのチャンネル。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_when_pipeline_status_changes` | ブール値 | いいえ | リファレンスのパイプラインステータスが変更された場合にのみ通知を送信します。 |
| `notify_only_default_branch` | ブール値 | いいえ | **非推奨**: このパラメータは`branches_to_be_notified`に置き換えられました。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `labels_to_be_notified` | 文字列 | いいえ | ラベルの通知を送信します。すべてのイベントの通知を受信するには、空白のままにします。 |
| `labels_to_be_notified_behavior` | 文字列 | いいえ | ラベルの通知対象。有効なオプションは`match_any`と`match_all`です。デフォルト値は`match_any`です。 |
| `alert_channel` | 文字列 | いいえ | アラートイベントの通知を受信するチャンネルの名前。 |
| `alert_events` | ブール値 | いいえ | アラートイベントの通知を有効にします。 |
| `commit_events` | ブール値 | いいえ | コミットイベントの通知を有効にします。 |
| `confidential_issue_channel` | 文字列 | いいえ | 機密イシューイベントの通知を受信するチャンネルの名前。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `confidential_note_channel` | 文字列 | いいえ | 機密ノートイベントの通知を受信するチャンネルの名前。 |
| `confidential_note_events` | ブール値 | いいえ | 機密ノートイベントの通知を有効にします。 |
| `deployment_channel` | 文字列 | いいえ | デプロイイベントの通知を受信するチャンネルの名前。 |
| `deployment_events` | ブール値 | いいえ | デプロイイベントの通知を有効にします。 |
| `incident_channel` | 文字列 | いいえ | インシデントイベントの通知を受信するチャンネルの名前。 |
| `incidents_events` | ブール値 | いいえ | インシデントイベントの通知を有効にします。 |
| `issue_channel` | 文字列 | いいえ | イシューイベントの通知を受信するチャンネルの名前。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `job_events` | ブール値 | いいえ | ジョブイベントの通知を有効にします。 |
| `merge_request_channel` | 文字列 | いいえ | マージリクエストイベントの通知を受信するチャンネルの名前。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `note_channel` | 文字列 | いいえ | ノートイベントの通知を受信するチャンネルの名前。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `pipeline_channel` | 文字列 | いいえ | パイプラインイベントの通知を受信するチャンネルの名前。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `push_channel` | 文字列 | いいえ | プッシュイベントの通知を受信するチャンネルの名前。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `tag_push_channel` | 文字列 | いいえ | タグプッシュイベントの通知を受信するチャンネルの名前。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `wiki_page_channel` | 文字列 | いいえ | Wikiページイベントの通知を受信するチャンネルの名前。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Slack通知を無効にする {#disable-slack-notifications}

プロジェクトのSlack通知を無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/slack
```

### Slack通知設定を取得する {#get-slack-notifications-settings}

プロジェクトのSlack通知設定を取得します。

```plaintext
GET /projects/:id/integrations/slack
```

## Squash TM {#squash-tm}

{{< history >}}

- GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/337855)されました。
- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Squash TMをセットアップする {#set-up-squash-tm}

プロジェクト用のSquash TMインテグレーション設定をセットアップします。

```plaintext
PUT /projects/:id/integrations/squash-tm
```

パラメータは以下のとおりです:

| パラメータ               | 型   | 必須 | 説明                   |
|-------------------------|--------|----------|-------------------------------|
| `url`                   | 文字列 | はい      | Squash TM WebhookのURL。 |
| `token`                 | 文字列 | いいえ       | シークレットトークン。                 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Squash TMを無効にする {#disable-squash-tm}

プロジェクトのSquash TMインテグレーションを無効にします。インテグレーションの設定は保持されます。

```plaintext
DELETE /projects/:id/integrations/squash-tm
```

### Squash TM設定を取得する {#get-squash-tm-settings}

プロジェクトのSquash TMインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/squash-tm
```

## Telegram {#telegram}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Telegramをセットアップする {#set-up-telegram}

プロジェクトのTelegramインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/telegram
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `hostname`   | 文字列 | いいえ | Telegram APIのカスタムホスト名 (GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/461313))。デフォルト値は`https://api.telegram.org`です。 |
| `token`   | 文字列 | はい | Telegramボットのトークン（例: `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`）。 |
| `room` | 文字列 | はい | ターゲットチャットの固有識別子、またはターゲットチャンネルのユーザー名（`@channelusername`の形式）。 |
| `thread` | 整数 | いいえ | ターゲットメッセージスレッドの固有識別子（フォーラムスーパーグループ内のトピック）。GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/441097)されました。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_when_pipeline_status_changes` | ブール値 | いいえ | リファレンスのパイプラインステータスが変更された場合にのみ通知を送信します。 |
| `branches_to_be_notified` | 文字列 | いいえ | ブランチへの通知を送信 ([GitLab 16.5で導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134361))。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | はい | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | はい | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | はい | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | はい | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | はい | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | はい | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | はい | 機密ノートイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | はい | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | はい | Wikiページイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Telegramを無効にする {#disable-telegram}

プロジェクトのTelegramインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/telegram
```

### Telegramの設定を取得 {#get-telegram-settings}

プロジェクトのTelegramインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/telegram
```

## Unify Circuit {#unify-circuit}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Unify Circuitをセットアップする {#set-up-unify-circuit}

プロジェクトのUnify Circuitインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/unify-circuit
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Unify Circuit Webhook（例: `https://circuit.com/rest/v2/webhooks/incoming/...`）。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_when_pipeline_status_changes` | ブール値 | いいえ | リファレンスのパイプラインステータスが変更された場合にのみ通知を送信します。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密ノートイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Unify Circuitを無効にする {#disable-unify-circuit}

プロジェクトのUnify Circuitインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/unify-circuit
```

### Unify Circuitの設定を取得 {#get-unify-circuit-settings}

プロジェクトのUnify Circuitインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/unify-circuit
```

## Webex Teams {#webex-teams}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Webex Teamsをセットアップする {#set-up-webex-teams}

プロジェクトのWebex Teamsをセットアップします。

```plaintext
PUT /projects/:id/integrations/webex-teams
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Webex Teams Webhook（例: `https://api.ciscospark.com/v1/webhooks/incoming/...`）。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密ノートイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Webex Teamsを無効にする {#disable-webex-teams}

プロジェクトのWebex Teamsを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/webex-teams
```

### Webex Teamsの設定を取得 {#get-webex-teams-settings}

プロジェクトのWebex Teams設定を取得します。

```plaintext
GET /projects/:id/integrations/webex-teams
```

## YouTrack {#youtrack}

{{< history >}}

- `use_inherited_settings`パラメータはGitLab 17.2で[フラグ](../administration/feature_flags/_index.md) `integration_api_inheritance`とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータはGitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### YouTrackをセットアップする {#set-up-youtrack}

プロジェクトのYouTrackインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/youtrack
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `issues_url` | 文字列 | はい | イシューのURL。 |
| `project_url` | 文字列 | はい | プロジェクトのURL。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### YouTrackを無効にする {#disable-youtrack}

プロジェクトのYouTrackインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/youtrack
```

### YouTrackの設定を取得 {#get-youtrack-settings}

プロジェクトのYouTrackインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/youtrack
```
