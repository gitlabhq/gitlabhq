---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループインテグレーションAPI
description: "グループのインテグレーションをREST APIでセットアップし、管理します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/328496)されました。

{{< /history >}}

このAPIを使用して、グループとそのサブグループの[インテグレーション](../user/project/integrations/_index.md)を管理します。

前提条件: 

- グループのメンテナーロールまたはオーナーロールを持っている必要があります。

## すべてのアクティブなインテグレーションをリスト表示 {#list-all-active-integrations}

すべてのアクティブなグループインテグレーションのリストを取得します。`vulnerability_events`フィールドはGitLab Enterprise Editionでのみ利用可能です。

```plaintext
GET /groups/:id/integrations
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

## Asana {#asana}

### Asanaをセットアップ {#set-up-asana}

グループのAsanaインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/asana
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `api_key` | 文字列 | はい | ユーザーAPIトークン。ユーザーはタスクへのアクセス権を持っている必要があります。すべてのコメントはこのユーザーに帰属します。 |
| `restrict_to_branch` | 文字列 | いいえ | 自動検査されるブランチのコンマ区切りリスト。すべてのブランチを含めるには空白のままにします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Asanaを無効にする {#disable-asana}

グループのAsanaインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/asana
```

### Asana設定を取得 {#get-asana-settings}

グループのAsanaインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/asana
```

## Assembla {#assembla}

### Assemblaをセットアップ {#set-up-assembla}

グループのAssemblaインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/assembla
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `token` | 文字列 | はい | この認証トークン。 |
| `subdomain` | 文字列 | いいえ | サブドメイン設定。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Assemblaを無効にする {#disable-assembla}

グループのAssemblaインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/assembla
```

### Assembla設定を取得 {#get-assembla-settings}

グループのAssemblaインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/assembla
```

## Atlassian Bamboo {#atlassian-bamboo}

### Atlassian Bambooをセットアップ {#set-up-atlassian-bamboo}

グループのAtlassian Bambooインテグレーションをセットアップします。

Bambooで自動リビジョンラベリングとリポジトリトリガーを設定する必要があります。

```plaintext
PUT /groups/:id/integrations/bamboo
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `bamboo_url` | 文字列 | はい | BambooルートURL（例: `https://bamboo.example.com`）。 |
| `enable_ssl_verification` | ブール値 | いいえ | SSL検証を有効にします。デフォルトは`true` (有効) です。 |
| `build_key` | 文字列 | はい | Bambooビルドプランキー (例: `KEY`)。 |
| `username` | 文字列 | はい | BambooサーバーへのAPIアクセス権を持つユーザー。 |
| `password` | 文字列 | はい | ユーザーのパスワード。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Atlassian Bambooを無効にする {#disable-atlassian-bamboo}

グループのAtlassian Bambooインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/bamboo
```

### Atlassian Bamboo設定を取得 {#get-atlassian-bamboo-settings}

グループのAtlassian Bambooインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/bamboo
```

## Bugzilla {#bugzilla}

### Bugzillaをセットアップ {#set-up-bugzilla}

グループのBugzillaインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/bugzilla
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | 文字列 | はい |  新しいイシューのURL。 |
| `issues_url` | 文字列 | はい | イシューのURL。 |
| `project_url` | 文字列 | はい | プロジェクトのURL。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Bugzillaを無効にする {#disable-bugzilla}

グループのBugzillaインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/bugzilla
```

### Bugzilla設定を取得 {#get-bugzilla-settings}

グループのBugzillaインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/bugzilla
```

## Buildkite {#buildkite}

### Buildkiteをセットアップ {#set-up-buildkite}

グループのBuildkiteインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/buildkite
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `token` | 文字列 | はい | BuildkiteプロジェクトGitLabトークン。 |
| `project_url` | 文字列 | はい | パイプラインURL（例: `https://buildkite.com/example/pipeline`）。 |
| `enable_ssl_verification` | ブール値 | いいえ | **非推奨**: SSL検証は常に有効になっているため、このパラメータは影響しません。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Buildkiteを無効にする {#disable-buildkite}

グループのBuildkiteインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/buildkite
```

### Buildkite設定を取得 {#get-buildkite-settings}

グループのBuildkiteインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/buildkite
```

## Campfire Classic {#campfire-classic}

Campfire Classicとインテグレーションできます。ただし、Campfire ClassicはBasecampによって[販売が終了した](https://gitlab.com/gitlab-org/gitlab/-/issues/329337)古いプロダクトです。

### Campfire Classicをセットアップ {#set-up-campfire-classic}

グループのCampfire Classicインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/campfire
```

パラメータは以下のとおりです:

| パラメータ     | 型    | 必須 | 説明                                                                                 |
|---------------|---------|----------|---------------------------------------------------------------------------------------------|
| `token`       | 文字列  | はい     | Campfire ClassicからのAPI認証トークン。トークンを取得するには、Campfire Classicにサインインして**My info**を選択します。 |
| `subdomain`   | 文字列  | いいえ    | サインインしているときの`.campfirenow.com`サブドメイン。 |
| `room`        | 文字列  | いいえ    | Campfire ClassicルームURLのID部分。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Campfire Classicを無効にする {#disable-campfire-classic}

グループのCampfire Classicインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/campfire
```

### Campfire Classic設定を取得 {#get-campfire-classic-settings}

グループのCampfire Classicインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/campfire
```

## ClickUp {#clickup}

### ClickUpをセットアップ {#set-up-clickup}

グループのClickUpインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/clickup
```

パラメータは以下のとおりです:

| パラメータ     | 型   | 必須 | 説明    |
| ------------- | ------ | -------- | -------------- |
| `issues_url`  | 文字列 | はい     | イシューのURL。     |
| `project_url` | 文字列 | はい     | プロジェクトのURL。   |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### ClickUpを無効にする {#disable-clickup}

グループのClickUpインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/clickup
```

### ClickUp設定を取得 {#get-clickup-settings}

グループのClickUpインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/clickup
```

## Confluenceワークスペース {#confluence-workspace}

### Confluenceワークスペースをセットアップ {#set-up-confluence-workspace}

グループのConfluenceワークスペースインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/confluence
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `confluence_url` | 文字列 | はい | `atlassian.net`でホストされているConfluenceワークスペースのURL。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Confluenceワークスペースを無効にする {#disable-confluence-workspace}

グループのConfluenceワークスペースインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/confluence
```

### Confluenceワークスペース設定を取得 {#get-confluence-workspace-settings}

グループのConfluenceワークスペースインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/confluence
```

## カスタムイシュートラッカー {#custom-issue-tracker}

### カスタムイシュートラッカーをセットアップ {#set-up-a-custom-issue-tracker}

グループのカスタムイシュートラッカーをセットアップします。

```plaintext
PUT /groups/:id/integrations/custom-issue-tracker
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | 文字列 | はい |  新しいイシューのURL。 |
| `issues_url` | 文字列 | はい | イシューのURL。 |
| `project_url` | 文字列 | はい | プロジェクトのURL。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### カスタムイシュートラッカーを無効にする {#disable-a-custom-issue-tracker}

グループのカスタムイシュートラッカーを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/custom-issue-tracker
```

### カスタムイシュートラッカー設定を取得 {#get-custom-issue-tracker-settings}

グループのカスタムイシュートラッカー設定を取得します。

```plaintext
GET /groups/:id/integrations/custom-issue-tracker
```

## Datadog {#datadog}

### Datadogをセットアップ {#set-up-datadog}

グループのDatadogインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/datadog
```

パラメータは以下のとおりです:

| パラメータ              | 型    | 必須 | 説明                                                                                                                                                                            |
|------------------------|---------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `api_key`              | 文字列  | はい     | Datadogでの認証に使用されるAPIキー。                                                                                                                                          |
| `api_url`              | 文字列  | いいえ    | (詳細)URLはDatadogサイトの完全なURL。                                                                                                                                          |
| `datadog_env`          | 文字列  | いいえ    | セルフマネージドデプロイメントの場合、Datadogに送信されるすべてのデータに`env%`タグを設定します。                                                                                                      |
| `datadog_service`      | 文字列  | いいえ    | このGitLabインスタンスからのすべてのデータをDatadogでタグ付けします。複数のセルフマネージドデプロイメントを管理する場合に使用できます。                                                                          |
| `datadog_site`         | 文字列  | いいえ    | データを送信するDatadogサイト。EUサイトにデータを送信するには、`datadoghq.eu`を使用します。                                                                                                      |
| `datadog_tags`         | 文字列  | いいえ    | Datadogでのカスタムタグ。1行に1つのタグを`key:value\nkey2:value2`の形式で指定します。                                                                                                 |
| `archive_trace_events` | ブール値 | いいえ    | 有効にすると、ジョブログがDatadogによって収集され、パイプライン実行トレースとともに表示されます。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Datadogを無効にする {#disable-datadog}

グループのDatadogインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/datadog
```

### Datadog設定を取得 {#get-datadog-settings}

グループのDatadogインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/datadog
```

## Diffblue Cover {#diffblue-cover}

### Diffblue Coverをセットアップ {#set-up-diffblue-cover}

グループのDiffblue Coverインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/diffblue-cover
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `diffblue_license_key` | 文字列 | はい | Diffblue Coverライセンスキー。 |
| `diffblue_access_token_name` | 文字列 | はい | Diffblue Coverがパイプラインで使用するアクセストークン名。 |
| `diffblue_access_token_secret` | 文字列  | はい | Diffblue Coverがパイプラインで使用するアクセストークンシークレット。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Diffblue Coverを無効にする {#disable-diffblue-cover}

グループのDiffblue Coverインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/diffblue-cover
```

### Diffblue Cover設定を取得 {#get-diffblue-cover-settings}

グループのDiffblue Coverインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/diffblue-cover
```

## Discord通知 {#discord-notifications}

### Discord通知をセットアップ {#set-up-discord-notifications}

グループのDiscord通知をセットアップします。

```plaintext
PUT /groups/:id/integrations/discord
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Discord Webhook（例: `https://discord.com/api/webhooks/...`）。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `confidential_issue_channel` | 文字列 | いいえ | 機密イシューイベントの通知を受け取るためのWebhookオーバーライド。 |
| `confidential_note_events` | ブール値 | いいえ | 機密メモイベントの通知を有効にします。 |
| `confidential_note_channel` | 文字列 | いいえ | 機密メモイベントの通知を受け取るためのWebhookオーバーライド。 |
| `deployment_events` | ブール値 | いいえ | デプロイイベントの通知を有効にします。 |
| `deployment_channel` | 文字列 | いいえ | デプロイイベントの通知を受け取るためのWebhookオーバーライド。 |
| `group_confidential_mentions_events` | ブール値 | いいえ | グループ機密メンションイベントの通知を有効にします。 |
| `group_confidential_mentions_channel` | 文字列 | いいえ | グループ機密メンションイベントの通知を受け取るためのWebhookオーバーライド。 |
| `group_mentions_events` | ブール値 | いいえ | グループメンションイベントの通知を有効にします。 |
| `group_mentions_channel` | 文字列 | いいえ | グループメンションイベントの通知を受け取るためのWebhookオーバーライド。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `issue_channel` | 文字列 | いいえ | イシューイベントの通知を受け取るためのWebhookオーバーライド。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `merge_request_channel` | 文字列 | いいえ | マージリクエストイベントの通知を受け取るためのWebhookオーバーライド。 |
| `note_events` | ブール値 | いいえ | メモイベントの通知を有効にします。 |
| `note_channel` | 文字列 | いいえ | メモイベントの通知を受け取るためのWebhookオーバーライド。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_when_pipeline_status_changes` | ブール値 | いいえ | 参照のパイプラインステータスが変更された場合にのみ通知を送信します。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `pipeline_channel` | 文字列 | いいえ | パイプラインイベントの通知を受け取るためのWebhookオーバーライド。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `push_channel` | 文字列 | いいえ | プッシュイベントの通知を受け取るためのWebhookオーバーライド。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `tag_push_channel` | 文字列 | いいえ | タグプッシュイベントの通知を受け取るためのWebhookオーバーライド。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `wiki_page_channel` | 文字列 | いいえ | Wikiページイベントの通知を受け取るためのWebhookオーバーライド。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Discord通知を無効にする {#disable-discord-notifications}

グループのDiscord通知を無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/discord
```

### Discord通知設定を取得 {#get-discord-notifications-settings}

グループのDiscord通知設定を取得します。

```plaintext
GET /groups/:id/integrations/discord
```

## Drone {#drone}

### Droneをセットアップ {#set-up-drone}

グループのDroneインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/drone-ci
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `token` | 文字列 | はい | Drone CIプロジェクト固有のトークン。 |
| `drone_url` | 文字列 | はい | `http://drone.example.com`。 |
| `enable_ssl_verification` | ブール値 | いいえ | SSL検証を有効にします。デフォルトは`true` (有効) です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Droneを無効にする {#disable-drone}

グループのDroneインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/drone-ci
```

### Drone設定を取得 {#get-drone-settings}

グループのDroneインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/drone-ci
```

## プッシュ時にメールを送信 {#emails-on-push}

### プッシュ時にメールを送信をセットアップ {#set-up-emails-on-push}

グループのプッシュ時にメールを送信インテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/emails-on-push
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `recipients` | 文字列 | はい | 空白で区切られたメール。 |
| `disable_diffs` | ブール値 | いいえ | code差分を無効にします。 |
| `send_from_committer_email` | ブール値 | いいえ | コミッターから送信します。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。通知は常にタグプッシュに対して発行されます。デフォルト値は`all`です。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### プッシュ時にメールを送信を無効にする {#disable-emails-on-push}

グループのプッシュ時にメールを送信インテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/emails-on-push
```

### プッシュ時にメールを送信設定を取得 {#get-emails-on-push-settings}

グループのプッシュ時にメールを送信インテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/emails-on-push
```

## エンジニアリングワークフロー管理 (EWM) {#engineering-workflow-management-ewm}

### EWMをセットアップ {#set-up-ewm}

グループのEWMインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/ewm
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | 文字列 | はい | 新しいイシューのURL。 |
| `project_url`   | 文字列 | はい | プロジェクトのURL。 |
| `issues_url`    | 文字列 | はい | イシューのURL。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### EWMを無効にする {#disable-ewm}

グループのEWMインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/ewm
```

### EWM設定を取得 {#get-ewm-settings}

グループのEWMインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/ewm
```

## 外部Wiki {#external-wiki}

### 外部Wikiをセットアップ {#set-up-an-external-wiki}

グループの外部Wikiをセットアップします。

```plaintext
PUT /groups/:id/integrations/external-wiki
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `external_wiki_url` | 文字列 | はい | 外部WikiのURL。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### 外部Wikiを無効にする {#disable-an-external-wiki}

グループの外部Wikiを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/external-wiki
```

### 外部Wiki設定を取得 {#get-external-wiki-settings}

グループの外部Wiki設定を取得します。

```plaintext
GET /groups/:id/integrations/external-wiki
```

## GitGuardian {#gitguardian}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- `api_url`パラメータはGitLab 19.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/599742)。

{{< /history >}}

> [!flag]
> GitLab Self-Managedでは、デフォルトでこの機能が利用可能です。機能を非表示にするには、管理者に`git_guardian_integration`という名前の[機能フラグを無効](../administration/feature_flags/_index.md)にするように依頼してください。GitLab.comでは、この機能は利用できません。GitLab Dedicatedでは、この機能は利用可能です。

[GitGuardian](https://www.gitguardian.com/)は、ソースcodeリポジトリ内にあるAPIキーやパスワードなどの機密データを検出するサイバーセキュリティサービスです。これはGitリポジトリをスキャンし、ポリシー違反をアラートし、ハッカーがそれらを悪用する前に組織がセキュリティイシューを修正するのに役立ちます。

GitLabを設定して、GitGuardianポリシーに基づいてコミットを拒否できます。

既知のイシューとトラブルシューティング手順については、[GitGuardianトラブルシューティング](../user/project/integrations/git_guardian.md#troubleshooting)を参照してください。

### GitGuardianをセットアップ {#set-up-gitguardian}

グループのGitGuardianインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/git-guardian
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明                                   |
| --------- | ---- | -------- |-----------------------------------------------|
| `token` | 文字列 | はい | GitGuardianAPIトークン (`scan`スコープ付き)。 |
| `api_url` | 文字列 | いいえ | GitGuardianAPIベースURL。`https://api.gitguardian.com`がデフォルトです。EU地域には`https://api.eu1.gitguardian.com`を、またはセルフホスト型GitGuardianインスタンスのURLを使用します。HTTPSを使用する必要があります。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### GitGuardianを無効にする {#disable-gitguardian}

グループのGitGuardianインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/git-guardian
```

### GitGuardian設定を取得 {#get-gitguardian-settings}

グループのGitGuardianインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/git-guardian
```

## GitHub {#github}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

### GitHubをセットアップ {#set-up-github}

グループのGitHubインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/github
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `token` | 文字列 | はい | GitHubAPIトークン (`repo:status` OAuthスコープ付き)。 |
| `repository_url` | 文字列 | はい | GitHubリポジトリURL。 |
| `static_context` | ブール値 | いいえ | GitLabインスタンスのホスト名を[ステータスチェック名](../user/project/integrations/github.md#static-or-dynamic-status-check-names)に追加します。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### GitHubを無効にする {#disable-github}

グループのGitHubインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/github
```

### GitHub設定を取得 {#get-github-settings}

グループのGitHubインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/github
```

## Jira Cloudアプリ用GitLab {#gitlab-for-jira-cloud-app}

Jira Cloudアプリ用GitLabインテグレーションは、[Jiraでのグループリンクおよびリンク解除](../integration/jira/connect-app.md#configure-the-gitlab-for-jira-cloud-app)によって自動的に有効化または無効化されます。GitLabインテグレーションフォームまたはAPIを使用してインテグレーションを有効または無効にすることはできません。

### グループのインテグレーションを更新 {#update-integration-for-a-group}

このAPIエンドポイントを使用して、Jiraでグループリンクによって作成したインテグレーションを更新します。

```plaintext
PUT /groups/:id/integrations/jira-cloud-app
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `jira_cloud_app_service_ids` | 文字列 | いいえ | Jiraサービス管理サービスID。複数のIDを区切るにはコンマ（`,`）を使用します。 |
| `jira_cloud_app_enable_deployment_gating` | ブール値 | いいえ | Jiraサービス管理からのブロックされたGitLabデプロイに対するデプロイゲートを有効にします。 |
| `jira_cloud_app_deployment_gating_environments` | 文字列 | いいえ | デプロイゲートを有効にする環境（本番環境、ステージング、テスト、または開発）。デプロイゲートが有効になっている場合、必須です。複数の環境を区切るにはコンマ（`,`）を使用します。 |

### Jira Cloudアプリ用GitLab設定を取得 {#get-gitlab-for-jira-cloud-app-settings}

グループのJira Cloudアプリ用GitLabインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/jira-cloud-app
```

## Slackアプリ用GitLab {#gitlab-for-slack-app}

### Slackアプリ用GitLabをセットアップ {#set-up-gitlab-for-slack-app}

グループのSlackアプリ用GitLabインテグレーションを更新します。

GitLab Slackアプリは、GitLab API単独では取得できないOAuth 2.0トークンを必要とするため、APIを介して作成することはできません。代わりに、GitLab UIから[アプリをインストールする](../user/project/integrations/gitlab_slack_application.md#install-the-gitlab-for-slack-app)必要があります。その後、このAPIエンドポイントを使用してインテグレーションを更新できます。

```plaintext
PUT /groups/:id/integrations/gitlab-slack-application
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `channel` | 文字列 | いいえ | 他のチャンネルが設定されていない場合に使用するデフォルトチャンネル。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_when_pipeline_status_changes` | ブール値 | いいえ | 参照のパイプラインステータスが変更された場合にのみ通知を送信します。 |
| `notify_only_default_branch` | ブール値 | いいえ | **非推奨**: このパラメータは`branches_to_be_notified`に置き換えられました。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `alert_events` | ブール値 | いいえ | アラートイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | メモイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密メモイベントの通知を有効にします。 |
| `deployment_events` | ブール値 | いいえ | デプロイイベントの通知を有効にします。 |
| `incidents_events` | ブール値 | いいえ | インシデントイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `vulnerability_events` | ブール値 | いいえ | 脆弱性イベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `labels_to_be_notified` | 文字列 | いいえ | 通知を送信するラベル。設定されていない場合、すべてのイベントの通知を受信します。 |
| `labels_to_be_notified_behavior` | 文字列 | いいえ | 通知されるラベル。有効なオプションは`match_any`と`match_all`です。`match_any`がデフォルトです。 |
| `push_channel` | 文字列 | いいえ | プッシュイベントの通知を受信するチャンネル名。 |
| `issue_channel` | 文字列 | いいえ | イシューイベントの通知を受信するチャンネル名。 |
| `confidential_issue_channel` | 文字列 | いいえ | 機密イシューイベントの通知を受信するチャンネル名。 |
| `merge_request_channel` | 文字列 | いいえ | マージリクエストイベントの通知を受信するチャンネル名。 |
| `note_channel` | 文字列 | いいえ | メモイベントの通知を受信するチャンネル名。 |
| `confidential_note_channel` | 文字列 | いいえ | 機密メモイベントの通知を受信するチャンネル名。 |
| `tag_push_channel` | 文字列 | いいえ | タグプッシュイベントの通知を受信するチャンネル名。 |
| `pipeline_channel` | 文字列 | いいえ | パイプラインイベントの通知を受信するチャンネル名。 |
| `wiki_page_channel` | 文字列 | いいえ | Wikiページイベントの通知を受信するチャンネル名。 |
| `deployment_channel` | 文字列 | いいえ | デプロイイベントの通知を受信するチャンネル名。 |
| `incident_channel` | 文字列 | いいえ | インシデントイベントの通知を受信するチャンネル名。 |
| `vulnerability_channel` | 文字列 | いいえ | 脆弱性イベントの通知を受信するチャンネル名。 |
| `alert_channel` | 文字列 | いいえ | アラートイベントの通知を受信するチャンネル名。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Slackアプリ用GitLabを無効にする {#disable-gitlab-for-slack-app}

グループのSlackアプリ用GitLabインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/gitlab-slack-application
```

### Slackアプリ用GitLab設定を取得 {#get-gitlab-for-slack-app-settings}

グループのSlackアプリ用GitLabインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/gitlab-slack-application
```

## Google Chat {#google-chat}

### Google Chatをセットアップ {#set-up-google-chat}

グループのGoogle Chatインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/hangouts-chat
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Hangouts Chat Webhook（例: `https://chat.googleapis.com/v1/spaces...`）。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_when_pipeline_status_changes` | ブール値 | いいえ | 参照のパイプラインステータスが変更された場合にのみ通知を送信します。 |
| `notify_only_default_branch` | ブール値 | いいえ | **非推奨**: このパラメータは`branches_to_be_notified`に置き換えられました。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | メモイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密メモイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Google Chatを無効にする {#disable-google-chat}

グループのGoogle Chatインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/hangouts-chat
```

### Google Chat設定を取得 {#get-google-chat-settings}

グループのGoogle Chatインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/hangouts-chat
```

## Googleアーティファクト管理 {#google-artifact-management}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- ステータス: ベータ版

{{< /details >}}

この機能は[ベータ版](../policy/development_stages_support.md)です。

### Googleアーティファクト管理をセットアップ {#set-up-google-artifact-management}

グループのGoogleアーティファクト管理インテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/google-cloud-platform-artifact-registry
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `artifact_registry_project_id` | 文字列 | はい | Google CloudプロジェクトのID。 |
| `artifact_registry_location` | 文字列 | はい | Artifact Registryリポジトリの場所。 |
| `artifact_registry_repositories` | 文字列 | はい | アーティファクトレジストリのリポジトリ。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Googleアーティファクト管理を無効にする {#disable-google-artifact-management}

グループのGoogleアーティファクト管理インテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/google-cloud-platform-artifact-registry
```

### Googleアーティファクト管理設定を取得 {#get-google-artifact-management-settings}

グループのGoogleアーティファクト管理インテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/google-cloud-platform-artifact-registry
```

## Google Cloud Identity and Access Management (IAM) {#google-cloud-identity-and-access-management-iam}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- ステータス: ベータ版

{{< /details >}}

この機能は[ベータ版](../policy/development_stages_support.md)です。

### Google Cloud Identity and Access Managementをセットアップ {#set-up-google-cloud-identity-and-access-management}

グループのGoogle Cloud Identity and Access Managementインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/google-cloud-platform-workload-identity-federation
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `workload_identity_federation_project_id` | 文字列 | はい | ワークロードアイデンティティフェデレーションのGoogle CloudプロジェクトID。 |
| `workload_identity_federation_project_number` | 整数 | はい | ワークロードアイデンティティフェデレーションのGoogle Cloudプロジェクト番号。 |
| `workload_identity_pool_id` | 文字列 | はい | ワークロードIDプールのID。 |
| `workload_identity_pool_provider_id` | 文字列 | はい | Workload IdentityプールプロバイダID。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Google Cloud Identity and Access Managementを無効にする {#disable-google-cloud-identity-and-access-management}

グループのGoogle Cloud Identity and Access Managementインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/google-cloud-platform-workload-identity-federation
```

### Google Cloud Identity and Access Managementを取得 {#get-google-cloud-identity-and-access-management}

グループのGoogle Cloud Identity and Access Managementの設定を取得します。

```plaintext
GET /groups/:id/integration/google-cloud-platform-workload-identity-federation
```

## Harbor {#harbor}

### Harborをセットアップ {#set-up-harbor}

グループのHarborインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/harbor
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `url` | 文字列 | はい | GitLabプロジェクトにリンクされているHarborインスタンスへのベースURL。例: `https://demo.goharbor.io`。 |
| `project_name` | 文字列 | はい | Harborインスタンス内のプロジェクト名。例: `testproject`。 |
| `username` | 文字列 | はい | Harborインターフェースで作成されたユーザー名。 |
| `password` | 文字列 | はい | ユーザーのパスワード。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Harborを無効にする {#disable-harbor}

グループのHarborインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/harbor
```

### Harbor設定を取得 {#get-harbor-settings}

グループのHarborインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/harbor
```

## irker (IRCゲートウェイ) {#irker-irc-gateway}

### irkerをセットアップ {#set-up-irker}

グループのirkerインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/irker
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `recipients` | 文字列 | はい | 空白で区切られた受信者またはチャンネル。 |
| `default_irc_uri` | 文字列 | いいえ | `irc://irc.network.net:6697/`。 |
| `server_host` | 文字列 | いいえ | localhost。 |
| `server_port` | 整数 | いいえ | 6659。 |
| `colorize_messages` | ブール値 | いいえ | メッセージを色分けします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### irkerを無効にする {#disable-irker}

グループのirkerインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/irker
```

### irker設定を取得 {#get-irker-settings}

グループのirkerインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/irker
```

## JetBrains TeamCity {#jetbrains-teamcity}

### JetBrains TeamCityをセットアップ {#set-up-jetbrains-teamcity}

グループのJetBrains TeamCityインテグレーションをセットアップします。

TeamCityのビルド構成では、`%build.vcs.number%`のビルド番号フォーマットを使用する必要があります。VCSルートの詳細設定で、すべてのブランチに対してモニタリングを設定し、マージリクエストがビルドできるようにします。

```plaintext
PUT /groups/:id/integrations/teamcity
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `teamcity_url` | 文字列 | はい | TeamCityルートURL（例: `https://teamcity.example.com`）。 |
| `enable_ssl_verification` | ブール値 | いいえ | SSL検証を有効にします。デフォルトは`true` (有効) です。 |
| `build_type` | 文字列 | はい | ビルド構成ID。 |
| `username` | 文字列 | はい | 手動ビルドをトリガーする権限を持つユーザー。 |
| `password` | 文字列 | はい | ユーザーのパスワード。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### JetBrains TeamCityを無効にする {#disable-jetbrains-teamcity}

グループのJetBrains TeamCityインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/teamcity
```

### JetBrains TeamCity設定を取得 {#get-jetbrains-teamcity-settings}

グループのJetBrains TeamCityインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/teamcity
```

## Jira {#jira}

### Jiraをセットアップ {#set-up-jira}

グループのJiraインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/jira
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `url`           | 文字列 | はい | このGitLabプロジェクトにリンクされているJiraプロジェクトへのURL（例: `https://jira.example.com`）。 |
| `api_url`   | 文字列 | いいえ | JiraインスタンスAPIへのベースURL。設定されていない場合、Web URL値が使用されます（例: `https://jira-api.example.com`）。 |
| `username`      | 文字列 | いいえ   | Jiraで使用するメールまたはユーザー名。Jira Cloudの場合はメールを、Jira Data CenterおよびJira Serverの場合はユーザー名を使用します。Basic認証（`jira_auth_type`が`0`）を使用する場合に必須です。 |
| `password`      | 文字列 | はい  | Jiraで使用するJira APIトークン、パスワード、またはパーソナルアクセストークン。Basic認証（`jira_auth_type`が`0`）の場合、Jira CloudにはAPIトークンを、Jira Data CenterまたはJira Serverにはパスワードを使用します。Jiraパーソナルアクセストークン認証（`jira_auth_type`が`1`）の場合、パーソナルアクセストークンを使用します。Jira Cloudサービスアカウント認証の場合、APIトークンを使用します。 |
| `jira_auth_type`| 整数 | いいえ  | Jiraで使用する認証方法。`0`はBasic認証、`1`はJiraパーソナルアクセストークン、`2`はJira Cloudサービスアカウントに使用します。`0`がデフォルトです。 |
| `jira_issue_prefix` | 文字列 | いいえ | Jiraイシューキーに一致するプレフィックス。 |
| `jira_issue_regex` | 文字列 | いいえ | Jiraイシューキーに一致する正規表現。 |
| `jira_issue_transition_automatic` | ブール値 | いいえ | [自動イシュー移行](../integration/jira/issues.md#automatic-issue-transitions)を有効にします。有効な場合、`jira_issue_transition_id`よりも優先されます。`false`がデフォルトです。 |
| `jira_issue_transition_id` | 文字列 | いいえ | [カスタムイシュー移行](../integration/jira/issues.md#custom-issue-transitions)の1つ以上の移行のID。`jira_issue_transition_automatic`が有効な場合、無視されます。デフォルトは空白の文字列であり、カスタム移行を無効にします。 |
| `commit_events` | ブール値 | いいえ | コミットイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `comment_on_event_enabled` | ブール値 | いいえ | 各GitLabイベント（コミットまたはマージリクエスト）でJiraイシューにコメントを有効にします。 |
| `issues_enabled` | ブール値 | いいえ | GitLabでJiraイシューの表示を有効にします。 |
| `project_keys` | 文字列の配列 | いいえ | Jiraプロジェクトのキー。`issues_enabled`が`true`の場合、この設定はGitLabでイシューを表示するJiraプロジェクトを指定します。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Jiraを無効にする {#disable-jira}

グループのJiraインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/jira
```

### Jira設定を取得 {#get-jira-settings}

グループのJiraインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/jira
```

## Linear {#linear}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198297)されました。

{{< /history >}}

### Linearをセットアップ {#set-up-linear}

グループのLinearインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/linear
```

パラメータは以下のとおりです:

| パラメータ     | 型   | 必須 | 説明    |
| ------------- | ------ | -------- | -------------- |
| `workspace_url`  | 文字列 | はい     | イシューのURL。     |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Linearを無効にする {#disable-linear}

グループのLinearインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/linear
```

### Linear設定を取得 {#get-linear-settings}

グループのLinearインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/linear
```

## Matrix通知 {#matrix-notifications}

### Matrix通知をセットアップ {#set-up-matrix-notifications}

グループのMatrix通知をセットアップします。

```plaintext
PUT /groups/:id/integrations/matrix
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `hostname`   | 文字列 | いいえ | Matrixサーバーのカスタムホスト名。デフォルト値は`https://matrix.org`です。 |
| `token`   | 文字列 | はい | Matrixアクセストークン（例: `syt-zyx57W2v1u123ew11`）。 |
| `room` | 文字列 | はい | ターゲットルームの固有識別子（形式: `!qPKKM111FFKKsfoCVy:matrix.org`）。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_when_pipeline_status_changes` | ブール値 | いいえ | 参照のパイプラインステータスが変更された場合にのみ通知を送信します。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | メモイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密メモイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Matrix通知を無効にする {#disable-matrix-notifications}

グループのMatrix通知を無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/matrix
```

### Matrix通知設定を取得 {#get-matrix-notifications-settings}

グループのMatrix通知設定を取得します。

```plaintext
GET /groups/:id/integrations/matrix
```

## Mattermost通知 {#mattermost-notifications}

### Mattermost通知を設定します {#set-up-mattermost-notifications}

グループのMattermost通知を設定します。

```plaintext
PUT /groups/:id/integrations/mattermost
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Mattermost通知Webhook（例: `http://mattermost.example.com/hooks/...`）。 |
| `username` | 文字列 | いいえ | Mattermost通知ユーザー名。 |
| `channel` | 文字列 | いいえ | 他のチャンネルが設定されていない場合に使用するデフォルトチャンネル。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_when_pipeline_status_changes` | ブール値 | いいえ | 参照のパイプラインステータスが変更された場合にのみ通知を送信します。 |
| `notify_only_default_branch` | ブール値 | いいえ | **非推奨**: このパラメータは`branches_to_be_notified`に置き換えられました。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `labels_to_be_notified` | 文字列 | いいえ | 通知を送信するラベル。すべてのイベントの通知を受信するには、空白のままにします。 |
| `labels_to_be_notified_behavior` | 文字列 | いいえ | 通知されるラベル。有効なオプションは`match_any`と`match_all`です。デフォルト値は`match_any`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | メモイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密メモイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `push_channel` | 文字列 | いいえ | プッシュイベントの通知を受信するチャンネル名。 |
| `issue_channel` | 文字列 | いいえ | イシューイベントの通知を受信するチャンネル名。 |
| `confidential_issue_channel` | 文字列 | いいえ | 機密イシューイベントの通知を受信するチャンネル名。 |
| `merge_request_channel` | 文字列 | いいえ | マージリクエストイベントの通知を受信するチャンネル名。 |
| `note_channel` | 文字列 | いいえ | ノートイベントの通知を受信するチャンネル名。 |
| `confidential_note_channel` | 文字列 | いいえ | 機密ノートイベントの通知を受信するチャンネル名。 |
| `tag_push_channel` | 文字列 | いいえ | タグプッシュイベントの通知を受信するチャンネル名。 |
| `pipeline_channel` | 文字列 | いいえ | パイプラインイベントの通知を受信するチャンネル名。 |
| `wiki_page_channel` | 文字列 | いいえ | Wikiページイベントの通知を受信するチャンネル名。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Mattermost通知を無効にします {#disable-mattermost-notifications}

グループのMattermost通知を無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/mattermost
```

### Mattermost通知設定を取得します {#get-mattermost-notifications-settings}

グループのMattermost通知設定を取得します。

```plaintext
GET /groups/:id/integrations/mattermost
```

## Mattermostスラッシュコマンド {#mattermost-slash-commands}

### Mattermostスラッシュコマンドを設定します {#set-up-mattermost-slash-commands}

グループのMattermostスラッシュコマンドを設定します。

```plaintext
PUT /groups/:id/integrations/mattermost-slash-commands
```

パラメータは以下のとおりです:

| パラメータ | 型   | 必須 | 説明           |
| --------- | ------ | -------- | --------------------- |
| `token`   | 文字列 | はい      | Mattermostトークン。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Mattermostスラッシュコマンドを無効にします {#disable-mattermost-slash-commands}

グループのMattermostスラッシュコマンドを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/mattermost-slash-commands
```

### Mattermostスラッシュコマンド設定を取得します {#get-mattermost-slash-commands-settings}

グループのMattermostスラッシュコマンド設定を取得します。

```plaintext
GET /groups/:id/integrations/mattermost-slash-commands
```

## Microsoft Teams通知 {#microsoft-teams-notifications}

### Microsoft Teams通知を設定します {#set-up-microsoft-teams-notifications}

グループのMicrosoft Teams通知を設定します。

```plaintext
PUT /groups/:id/integrations/microsoft-teams
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Microsoft Teams Webhook（例: `https://outlook.office.com/webhook/...`）。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_when_pipeline_status_changes` | ブール値 | いいえ | 参照のパイプラインステータスが変更された場合にのみ通知を送信します。 |
| `notify_only_default_branch` | ブール値 | いいえ | **非推奨**: このパラメータは`branches_to_be_notified`に置き換えられました。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | メモイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密メモイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Microsoft Teams通知を無効にします {#disable-microsoft-teams-notifications}

グループのMicrosoft Teams通知を無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/microsoft-teams
```

### Microsoft Teams通知設定を取得します {#get-microsoft-teams-notifications-settings}

グループのMicrosoft Teams通知設定を取得します。

```plaintext
GET /groups/:id/integrations/microsoft-teams
```

## モックCI {#mock-ci}

このインテグレーションは開発環境でのみ利用可能です。モックCIサーバーの例については、[`gitlab-org/gitlab-mock-ci-service`](https://gitlab.com/gitlab-org/gitlab-mock-ci-service)を参照してください。

### モックCIを設定します {#set-up-mock-ci}

グループのモックCIインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/mock-ci
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `mock_service_url` | 文字列 | はい | モックCIインテグレーションのURL。 |
| `enable_ssl_verification` | ブール値 | いいえ | SSL検証を有効にします。デフォルトは`true` (有効) です。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### モックCIを無効にします {#disable-mock-ci}

グループのモックCIインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/mock-ci
```

### モックCI設定を取得します {#get-mock-ci-settings}

グループのモックCIインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/mock-ci
```

## Packagist {#packagist}

### Packagistを設定します {#set-up-packagist}

グループのPackagistインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/packagist
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `username` | 文字列 | はい | Packagistアカウントのユーザー名。 |
| `token` | 文字列 | はい | PackagistサーバーへのAPIトークン。 |
| `server` | ブール値 | いいえ | PackagistサーバーのURL。デフォルトの`<https://packagist.org>`には空白のままにしてください。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Packagistを無効にします {#disable-packagist}

グループのPackagistインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/packagist
```

### Packagist設定を取得します {#get-packagist-settings}

グループのPackagistインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/packagist
```

## Phorge {#phorge}

### Phorgeを設定します {#set-up-phorge}

グループのPhorgeインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/phorge
```

パラメータは以下のとおりです:

| パラメータ       | 型   | 必須 | 説明           |
|-----------------|--------|----------|-----------------------|
| `issues_url`    | 文字列 | はい     | イシューのURL。     |
| `project_url`   | 文字列 | はい     | プロジェクトのURL。   |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Phorgeを無効にします {#disable-phorge}

グループのPhorgeインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/phorge
```

### Phorge設定を取得します {#get-phorge-settings}

グループのPhorgeインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/phorge
```

## パイプラインステータスメール {#pipeline-status-emails}

### パイプラインステータスメールを設定します {#set-up-pipeline-status-emails}

グループのパイプラインステータスメールを設定します。

```plaintext
PUT /groups/:id/integrations/pipelines-email
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `recipients` | 文字列 | はい | 受信者のメールアドレスのコンマ区切りリスト。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `notify_only_default_branch` | ブール値 | いいえ | デフォルトブランチの通知を送信します。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### パイプラインステータスメールを無効にします {#disable-pipeline-status-emails}

グループのパイプラインステータスメールを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/pipelines-email
```

### パイプラインステータスメール設定を取得します {#get-pipeline-status-emails-settings}

グループのパイプラインステータスメール設定を取得します。

```plaintext
GET /groups/:id/integrations/pipelines-email
```

## Pivotal Tracker {#pivotal-tracker}

### Pivotal Trackerを設定します {#set-up-pivotal-tracker}

グループのPivotal Trackerインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/pivotaltracker
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `token` | 文字列 | はい | Pivotal Trackerトークン。 |
| `restrict_to_branch` | ブール値 | いいえ | 自動的に検査するブランチのコンマ区切りリスト。すべてのブランチを含めるには空白のままにします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Pivotal Trackerを無効にします {#disable-pivotal-tracker}

グループのPivotal Trackerインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/pivotaltracker
```

### Pivotal Tracker設定を取得します {#get-pivotal-tracker-settings}

グループのPivotal Trackerインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/pivotaltracker
```

## Pumble {#pumble}

### Pumbleを設定します {#set-up-pumble}

グループのPumbleインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/pumble
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Pumble Webhook（例: `https://api.pumble.com/workspaces/x/...`）。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルトは`default`です。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密メモイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | メモイベントの通知を有効にします。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_when_pipeline_status_changes` | ブール値 | いいえ | 参照のパイプラインステータスが変更された場合にのみ通知を送信します。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Pumbleを無効にします {#disable-pumble}

グループのPumbleインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/pumble
```

### Pumble設定を取得します {#get-pumble-settings}

グループのPumbleインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/pumble
```

## Pushover {#pushover}

### Pushoverを設定します {#set-up-pushover}

グループのPushoverインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/pushover
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `api_key` | 文字列 | はい | アプリケーションキー。 |
| `user_key` | 文字列 | はい | ユーザーキー。 |
| `priority` | 文字列 | はい | 優先度。 |
| `device` | 文字列 | いいえ | すべてのアクティブなデバイスを含めるには空白のままにしてください。 |
| `sound` | 文字列 | いいえ | 通知のサウンド。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Pushoverを無効にします {#disable-pushover}

グループのPushoverインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/pushover
```

### Pushover設定を取得します {#get-pushover-settings}

グループのPushoverインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/pushover
```

## Redmine {#redmine}

### Redmineを設定します {#set-up-redmine}

グループのRedmineインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/redmine
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | 文字列 | はい | 新しいイシューのURL。 |
| `project_url` | 文字列 | はい | プロジェクトのURL。 |
| `issues_url` | 文字列 | はい | イシューのURL。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Redmineを無効にします {#disable-redmine}

グループのRedmineインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/redmine
```

### Redmine設定を取得します {#get-redmine-settings}

グループのRedmineインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/redmine
```

## Slack通知 {#slack-notifications}

### Slack通知を設定します {#set-up-slack-notifications}

グループのSlack通知を設定します。

```plaintext
PUT /groups/:id/integrations/slack
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Slack通知Webhook（例: `https://hooks.slack.com/services/...`）。 |
| `username` | 文字列 | いいえ | Slack通知ユーザー名。 |
| `channel` | 文字列 | いいえ | 他のチャンネルが設定されていない場合に使用するデフォルトチャンネル。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_when_pipeline_status_changes` | ブール値 | いいえ | 参照のパイプラインステータスが変更された場合にのみ通知を送信します。 |
| `notify_only_default_branch` | ブール値 | いいえ | **非推奨**: このパラメータは`branches_to_be_notified`に置き換えられました。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `labels_to_be_notified` | 文字列 | いいえ | 通知を送信するラベル。すべてのイベントの通知を受信するには、空白のままにします。 |
| `labels_to_be_notified_behavior` | 文字列 | いいえ | 通知されるラベル。有効なオプションは`match_any`と`match_all`です。デフォルト値は`match_any`です。 |
| `alert_channel` | 文字列 | いいえ | アラートイベントの通知を受信するチャンネル名。 |
| `alert_events` | ブール値 | いいえ | アラートイベントの通知を有効にします。 |
| `commit_events` | ブール値 | いいえ | コミットイベントの通知を有効にします。 |
| `confidential_issue_channel` | 文字列 | いいえ | 機密イシューイベントの通知を受信するチャンネル名。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `confidential_note_channel` | 文字列 | いいえ | 機密ノートイベントの通知を受信するチャンネル名。 |
| `confidential_note_events` | ブール値 | いいえ | 機密メモイベントの通知を有効にします。 |
| `deployment_channel` | 文字列 | いいえ | デプロイイベントの通知を受信するチャンネル名。 |
| `deployment_events` | ブール値 | いいえ | デプロイイベントの通知を有効にします。 |
| `incident_channel` | 文字列 | いいえ | インシデントイベントの通知を受信するチャンネル名。 |
| `incidents_events` | ブール値 | いいえ | インシデントイベントの通知を有効にします。 |
| `issue_channel` | 文字列 | いいえ | イシューイベントの通知を受信するチャンネル名。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `job_events` | ブール値 | いいえ | ジョブイベントの通知を有効にします。 |
| `merge_request_channel` | 文字列 | いいえ | マージリクエストイベントの通知を受信するチャンネル名。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `note_channel` | 文字列 | いいえ | ノートイベントの通知を受信するチャンネル名。 |
| `note_events` | ブール値 | いいえ | メモイベントの通知を有効にします。 |
| `pipeline_channel` | 文字列 | いいえ | パイプラインイベントの通知を受信するチャンネル名。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `push_channel` | 文字列 | いいえ | プッシュイベントの通知を受信するチャンネル名。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `tag_push_channel` | 文字列 | いいえ | タグプッシュイベントの通知を受信するチャンネル名。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `wiki_page_channel` | 文字列 | いいえ | Wikiページイベントの通知を受信するチャンネル名。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Slack通知を無効にします {#disable-slack-notifications}

グループのSlack通知を無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/slack
```

### Slack通知設定を取得します {#get-slack-notifications-settings}

グループのSlack通知設定を取得します。

```plaintext
GET /groups/:id/integrations/slack
```

## スカッシュTM {#squash-tm}

### スカッシュTMを設定します {#set-up-squash-tm}

グループのスカッシュTMインテグレーション設定を設定します。

```plaintext
PUT /groups/:id/integrations/squash-tm
```

パラメータは以下のとおりです:

| パラメータ               | 型   | 必須 | 説明                   |
|-------------------------|--------|----------|-------------------------------|
| `url`                   | 文字列 | はい      | スカッシュTM WebhookのURL。 |
| `token`                 | 文字列 | いいえ       | シークレットトークン。                 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### スカッシュTMを無効にします {#disable-squash-tm}

グループのスカッシュTMインテグレーションを無効にします。インテグレーション設定は保持されます。

```plaintext
DELETE /groups/:id/integrations/squash-tm
```

### スカッシュTM設定を取得します {#get-squash-tm-settings}

グループのスカッシュTMインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/squash-tm
```

## Telegram {#telegram}

### Telegramを設定します {#set-up-telegram}

グループのTelegramインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/telegram
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `hostname`   | 文字列 | いいえ | Telegram APIのカスタムホスト名。デフォルト値は`https://api.telegram.org`です。 |
| `token`   | 文字列 | はい | Telegramボットトークン（例: `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`）。 |
| `room` | 文字列 | はい | ターゲットチャットの固有識別子、またはターゲットチャンネルのユーザー名（形式: `@channelusername`）。 |
| `thread` | 整数 | いいえ | ターゲットメッセージスレッド（フォーラムスーパーグループのトピック）の固有識別子。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_when_pipeline_status_changes` | ブール値 | いいえ | 参照のパイプラインステータスが変更された場合にのみ通知を送信します。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | はい | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | はい | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | はい | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | はい | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | はい | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | はい | メモイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | はい | 機密メモイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | はい | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | はい | Wikiページイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Telegramを無効にします {#disable-telegram}

グループのTelegramインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/telegram
```

### Telegram設定を取得します {#get-telegram-settings}

グループのTelegramインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/telegram
```

## Unify Circuit {#unify-circuit}

### Unify Circuitを設定します {#set-up-unify-circuit}

グループのUnify Circuitインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/unify-circuit
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Unify Circuit Webhook（例: `https://circuit.com/rest/v2/webhooks/incoming/...`）。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_when_pipeline_status_changes` | ブール値 | いいえ | 参照のパイプラインステータスが変更された場合にのみ通知を送信します。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | メモイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密メモイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Unify Circuitを無効にします {#disable-unify-circuit}

グループのUnify Circuitインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/unify-circuit
```

### Unify Circuit設定を取得します {#get-unify-circuit-settings}

グループのUnify Circuitインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/unify-circuit
```

## Webex Teams {#webex-teams}

### Webex Teamsを設定します {#set-up-webex-teams}

グループのWebex Teamsを設定します。

```plaintext
PUT /groups/:id/integrations/webex-teams
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Webex Teams Webhook（例: `https://api.ciscospark.com/v1/webhooks/incoming/...`）。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_when_pipeline_status_changes` | ブール値 | いいえ | 参照のパイプラインステータスが変更された場合にのみ通知を送信します。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | メモイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密メモイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Webex Teamsを無効にします {#disable-webex-teams}

グループのWebex Teamsを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/webex-teams
```

### Webex Teams設定を取得します {#get-webex-teams-settings}

グループのWebex Teams設定を取得します。

```plaintext
GET /groups/:id/integrations/webex-teams
```

## YouTrack {#youtrack}

### YouTrackを設定します {#set-up-youtrack}

グループのYouTrackインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/youtrack
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `issues_url` | 文字列 | はい | イシューのURL。 |
| `project_url` | 文字列 | はい | プロジェクトのURL。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### YouTrackを無効にします {#disable-youtrack}

グループのYouTrackインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/youtrack
```

### YouTrack設定を取得します {#get-youtrack-settings}

グループのYouTrackインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/youtrack
```
