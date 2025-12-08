---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループインテグレーションAPI
description: "REST APIを使用して、グループのインテグレーションを設定および管理します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/328496)されました。

{{< /history >}}

このAPIを使用して、グループとそのサブグループの[integrations](../user/project/integrations/_index.md)を管理します。

前提要件: 

- グループのメンテナーロール以上を持っている必要があります。

## アクティブなインテグレーションをすべてリストする {#list-all-active-integrations}

アクティブなグループインテグレーションのリストを取得します。`vulnerability_events`フィールドは、GitLab Enterprise Editionでのみ使用できます。

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

### Asanaを設定 {#set-up-asana}

グループのAsanaインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/asana
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `api_key` | 文字列 | はい | ユーザーAPIトークン。ユーザーはタスクにアクセスできる必要があります。すべてのコメントは、このユーザーに帰属します。 |
| `restrict_to_branch` | 文字列 | いいえ | 自動的に検査されるブランチのカンマ区切りリスト。すべてのブランチを含めるには、空白のままにします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Asanaを無効にする {#disable-asana}

グループのAsanaインテグレーションを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /groups/:id/integrations/asana
```

### Asanaの設定を取得 {#get-asana-settings}

グループのAsanaインテグレーションの設定を取得します。

```plaintext
GET /groups/:id/integrations/asana
```

## Assembla {#assembla}

### Assemblaを設定 {#set-up-assembla}

グループのAssemblaインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/assembla
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `token` | 文字列 | はい | 認証トークン。 |
| `subdomain` | 文字列 | いいえ | サブドメイン設定。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Assemblaを無効にする {#disable-assembla}

グループのAssemblaインテグレーションを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /groups/:id/integrations/assembla
```

### Assemblaの設定を取得 {#get-assembla-settings}

グループのAssemblaインテグレーションの設定を取得します。

```plaintext
GET /groups/:id/integrations/assembla
```

## Atlassian Bamboo {#atlassian-bamboo}

### Atlassian Bambooを設定 {#set-up-atlassian-bamboo}

グループのAtlassian Bambooインテグレーションを設定します。

Bambooで自動リビジョンラベルとリポジトリトリガーを構成する必要があります。

```plaintext
PUT /groups/:id/integrations/bamboo
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `bamboo_url` | 文字列 | はい | BambooルートURL（例: `https://bamboo.example.com`）。 |
| `enable_ssl_verification` | ブール値 | いいえ | SSL検証を有効にします。デフォルトは`true`（有効）。 |
| `build_key` | 文字列 | はい | Bambooビルドプランキー（例: `KEY`）。 |
| `username` | 文字列 | はい | BambooサーバーへのAPIアクセスを持つユーザー。 |
| `password` | 文字列 | はい | ユーザーのパスワード。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Atlassian Bambooを無効にする {#disable-atlassian-bamboo}

グループのAtlassian Bambooインテグレーションを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /groups/:id/integrations/bamboo
```

### Atlassian Bambooの設定を取得 {#get-atlassian-bamboo-settings}

グループのAtlassian Bambooインテグレーションの設定を取得します。

```plaintext
GET /groups/:id/integrations/bamboo
```

## Bugzilla {#bugzilla}

### Bugzillaを設定 {#set-up-bugzilla}

グループのBugzillaインテグレーションを設定します。

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

グループのBugzillaインテグレーションを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /groups/:id/integrations/bugzilla
```

### Bugzillaの設定を取得 {#get-bugzilla-settings}

グループのBugzillaインテグレーションの設定を取得します。

```plaintext
GET /groups/:id/integrations/bugzilla
```

## Buildkite {#buildkite}

### Buildkiteを設定 {#set-up-buildkite}

グループのBuildkiteインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/buildkite
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `token` | 文字列 | はい | BuildkiteプロジェクトGitLabトークン。 |
| `project_url` | 文字列 | はい | パイプラインURL（例: `https://buildkite.com/example/pipeline`）。 |
| `enable_ssl_verification` | ブール値 | いいえ | **非推奨**: SSL検証は常に有効になっているため、このパラメータは無効です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグ付けプッシュイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Buildkiteを無効にする {#disable-buildkite}

グループのBuildkiteインテグレーションを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /groups/:id/integrations/buildkite
```

### Buildkiteの設定を取得 {#get-buildkite-settings}

グループのBuildkiteインテグレーションの設定を取得します。

```plaintext
GET /groups/:id/integrations/buildkite
```

## Campfire Classic {#campfire-classic}

Campfire Classicとインテグレーションできます。ただし、Campfire Classicは、Basecampでは[販売されなくなった](https://gitlab.com/gitlab-org/gitlab/-/issues/329337)古い製品です。

### Campfire Classicを設定 {#set-up-campfire-classic}

グループのCampfire Classicインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/campfire
```

パラメータは以下のとおりです:

| パラメータ     | 型    | 必須 | 説明                                                                                 |
|---------------|---------|----------|---------------------------------------------------------------------------------------------|
| `token`       | 文字列  | はい     | Campfire ClassicからのAPI認証トークン。トークンを取得するには、Campfire Classicにサインインして、**My info**（個人情報）を選択します。 |
| `subdomain`   | 文字列  | いいえ    | サインインしているときの`.campfirenow.com`サブドメイン。 |
| `room`        | 文字列  | いいえ    | Campfire ClassicルームURLのID部分。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Campfire Classicを無効にする {#disable-campfire-classic}

グループのCampfire Classicインテグレーションを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /groups/:id/integrations/campfire
```

### Campfire Classicの設定を取得 {#get-campfire-classic-settings}

グループのCampfire Classicインテグレーションの設定を取得します。

```plaintext
GET /groups/:id/integrations/campfire
```

## ClickUp {#clickup}

### ClickUpを設定 {#set-up-clickup}

グループのClickUpインテグレーションを設定します。

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

グループのClickUpインテグレーションを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /groups/:id/integrations/clickup
```

### ClickUpの設定を取得 {#get-clickup-settings}

グループのClickUpインテグレーションの設定を取得します。

```plaintext
GET /groups/:id/integrations/clickup
```

## Confluenceワークスペース {#confluence-workspace}

### Confluenceワークスペースを設定 {#set-up-confluence-workspace}

グループのConfluenceワークスペースインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/confluence
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `confluence_url` | 文字列 | はい | `atlassian.net`でホストされているConfluenceワークスペースのURL。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Confluenceワークスペースを無効にする {#disable-confluence-workspace}

グループのConfluenceワークスペースインテグレーションを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /groups/:id/integrations/confluence
```

### Confluenceワークスペースの設定を取得 {#get-confluence-workspace-settings}

グループのConfluenceワークスペースインテグレーションの設定を取得します。

```plaintext
GET /groups/:id/integrations/confluence
```

## カスタムイシュートラッカー {#custom-issue-tracker}

### カスタムイシュートラッカーを設定 {#set-up-a-custom-issue-tracker}

グループのカスタムイシュートラッカーを設定します。

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

グループのカスタムイシュートラッカーを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /groups/:id/integrations/custom-issue-tracker
```

### カスタムイシュートラッカーの設定を取得 {#get-custom-issue-tracker-settings}

グループのカスタムイシュートラッカーの設定を取得します。

```plaintext
GET /groups/:id/integrations/custom-issue-tracker
```

## Datadog {#datadog}

### Datadogを設定 {#set-up-datadog}

グループのDatadogインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/datadog
```

パラメータは以下のとおりです:

| パラメータ              | 型    | 必須 | 説明                                                                                                                                                                            |
|------------------------|---------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `api_key`              | 文字列  | はい     | Datadogとの認証に使用されるAPIキー。                                                                                                                                          |
| `api_url`              | 文字列  | いいえ    | （詳細）Datadogサイトの完全なURL。                                                                                                                                          |
| `datadog_env`          | 文字列  | いいえ    | セルフマネージドデプロイの場合、Datadogに送信されるすべてのデータに対して`env%`タグを設定します。                                                                                                      |
| `datadog_service`      | 文字列  | いいえ    | このGitLabインスタンスからのすべてのデータにDatadogでタグを付けます。複数のセルフマネージドデプロイを管理する場合に使用できます。                                                                          |
| `datadog_site`         | 文字列  | いいえ    | データの送信先となるDatadogサイト。EUサイトにデータを送信するには、`datadoghq.eu`を使用します。                                                                                                      |
| `datadog_tags`         | 文字列  | いいえ    | Datadogのカスタムタグ。形式`key:value\nkey2:value2`で、1行に1つのタグを指定します                                                                                                 |
| `archive_trace_events` | ブール値 | いいえ    | 有効にすると、ジョブログはDatadogによって収集され、パイプライン実行トレースとともに表示されます。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Datadogを無効にする {#disable-datadog}

グループのDatadogインテグレーションを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /groups/:id/integrations/datadog
```

### Datadogの設定を取得 {#get-datadog-settings}

グループのDatadogインテグレーションの設定を取得します。

```plaintext
GET /groups/:id/integrations/datadog
```

## Diffblue Cover {#diffblue-cover}

### Diffblue Coverを設定 {#set-up-diffblue-cover}

グループのDiffblue Coverインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/diffblue-cover
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `diffblue_license_key` | 文字列 | はい | Diffblue Coverライセンスキー。 |
| `diffblue_access_token_name` | 文字列 | はい | パイプラインでDiffblue Coverが使用するアクセストークン名。 |
| `diffblue_access_token_secret` | 文字列  | はい | パイプラインでDiffblue Coverが使用するアクセストークンシークレット。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Diffblue Coverを無効にする {#disable-diffblue-cover}

グループのDiffblue Coverインテグレーションを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /groups/:id/integrations/diffblue-cover
```

### Diffblue Coverの設定を取得 {#get-diffblue-cover-settings}

グループのDiffblue Coverインテグレーションの設定を取得します。

```plaintext
GET /groups/:id/integrations/diffblue-cover
```

## Discord通知 {#discord-notifications}

### Discord通知の設定 {#set-up-discord-notifications}

グループのDiscord通知を設定します。

```plaintext
PUT /groups/:id/integrations/discord
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Discord Webhook（例: `https://discord.com/api/webhooks/...`）。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密性の高いイシューイベントの通知を有効にします。 |
| `confidential_issue_channel` | 文字列 | いいえ | 機密性の高いイシューイベントの通知を受信するWebhookのオーバーライド。 |
| `confidential_note_events` | ブール値 | いいえ | 機密性の高いノートイベントの通知を有効にします。 |
| `confidential_note_channel` | 文字列 | いいえ | 機密性の高いノートイベントの通知を受信するWebhookのオーバーライド。 |
| `deployment_events` | ブール値 | いいえ | デプロイイベントの通知を有効にします。 |
| `deployment_channel` | 文字列 | いいえ | デプロイイベントの通知を受信するWebhookのオーバーライド。 |
| `group_confidential_mentions_events` | ブール値 | いいえ | グループの機密メンションイベントの通知を有効にします。 |
| `group_confidential_mentions_channel` | 文字列 | いいえ | グループの機密メンションイベントの通知を受信するWebhookのオーバーライド。 |
| `group_mentions_events` | ブール値 | いいえ | グループのメンションイベントの通知を有効にします。 |
| `group_mentions_channel` | 文字列 | いいえ | グループのメンションイベントの通知を受信するWebhookのオーバーライド。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `issue_channel` | 文字列 | いいえ | イシューイベントの通知を受信するWebhookのオーバーライド。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `merge_request_channel` | 文字列 | いいえ | マージリクエストイベントの通知を受信するWebhookのオーバーライド。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `note_channel` | 文字列 | いいえ | ノートイベントの通知を受信するWebhookのオーバーライド。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `pipeline_channel` | 文字列 | いいえ | パイプラインイベントの通知を受信するWebhookのオーバーライド。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `push_channel` | 文字列 | いいえ | プッシュイベントの通知を受信するWebhookのオーバーライド。 |
| `tag_push_events` | ブール値 | いいえ | タグ付けプッシュイベントの通知を有効にします。 |
| `tag_push_channel` | 文字列 | いいえ | タグ付けプッシュイベントの通知を受信するWebhookのオーバーライド。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページのイベントの通知を有効にします。 |
| `wiki_page_channel` | 文字列 | いいえ | Wikiページのイベントの通知を受信するWebhookのオーバーライド。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Discord通知を無効にする {#disable-discord-notifications}

グループのDiscord通知を無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /groups/:id/integrations/discord
```

### Discord通知の設定を取得 {#get-discord-notifications-settings}

グループのDiscord通知の設定を取得します。

```plaintext
GET /groups/:id/integrations/discord
```

## Drone {#drone}

### Droneを設定 {#set-up-drone}

グループのDroneインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/drone-ci
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `token` | 文字列 | はい | Drone CIプロジェクト固有のトークン。 |
| `drone_url` | 文字列 | はい | `http://drone.example.com`。 |
| `enable_ssl_verification` | ブール値 | いいえ | SSL検証を有効にします。デフォルトは`true`（有効）。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグ付けプッシュイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Droneを無効にする {#disable-drone}

グループのDroneインテグレーションを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /groups/:id/integrations/drone-ci
```

### Drone設定を取得 {#get-drone-settings}

グループのDroneインテグレーションの設定を取得します。

```plaintext
GET /groups/:id/integrations/drone-ci
```

## プッシュ時にメールを送信 {#emails-on-push}

### プッシュ時にメールを送信する設定 {#set-up-emails-on-push}

グループのプッシュ時にメールを送信するインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/emails-on-push
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `recipients` | 文字列 | はい | 空白で区切られたメール。 |
| `disable_diffs` | ブール値 | いいえ | コード差分を無効にします。 |
| `send_from_committer_email` | ブール値 | いいえ | コミッターから送信します。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、および`default_and_protected`です。タグのプッシュでは、通知が常にトリガーされます。デフォルト値は`all`です。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### プッシュ時にメールを送信する設定を無効にする {#disable-emails-on-push}

グループのプッシュ時にメールを送信するインテグレーションを無効にします。インテグレーションの設定がリセットされました。

```plaintext
DELETE /groups/:id/integrations/emails-on-push
```

### プッシュ時にメールを送信する設定を取得 {#get-emails-on-push-settings}

グループのプッシュ時にメールを送信するインテグレーションの設定を取得します。

```plaintext
GET /groups/:id/integrations/emails-on-push
```

## Engineering Workflow Management（EWM） {#engineering-workflow-management-ewm}

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
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### EWMを無効にする {#disable-ewm}

グループのEWMインテグレーションを無効にします。インテグレーションの設定がリセットされました。

```plaintext
DELETE /groups/:id/integrations/ewm
```

### EWM設定を取得 {#get-ewm-settings}

グループのEWMインテグレーションの設定を取得します。

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
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### 外部Wikiを無効にする {#disable-an-external-wiki}

グループの外部Wikiを無効にします。インテグレーションの設定がリセットされました。

```plaintext
DELETE /groups/:id/integrations/external-wiki
```

### 外部Wikiの設定を取得 {#get-external-wiki-settings}

グループの外部Wikiの設定を取得します。

```plaintext
GET /groups/:id/integrations/external-wiki
```

## GitGuardian {#gitguardian}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="flag" >}}

GitLab Self-Managedでは、デフォルトでこの機能を利用できます。機能を非表示にするには、管理者に`git_guardian_integration`という名前の[機能フラグを無効](../administration/feature_flags/_index.md)にするように依頼してください。GitLab.comでは、この機能は利用できません。GitLab Dedicatedでは、この機能を利用できます。

{{< /alert >}}

[GitGuardian](https://www.gitguardian.com/)は、ソースコードリポジトリ内のAPIキーやパスワードなどの機密データを検出するサイバーセキュリティサービスです。Gitリポジトリをスキャンし、違反についてアラートをトリガーし、ハッカーがエクスプロイトする前に組織がセキュリティ上のイシューを修正するのを支援します。

GitGuardianポリシーに基づいてコミットを拒否するようにGitLabを設定できます。

### 既知の問題 {#known-issues}

- プッシュが遅延したり、タイムアウトしたりする可能性があります。GitGuardianインテグレーションでは、プッシュはサードパーティに送信され、GitLabはGitGuardianとの接続またはGitGuardianプロセスを制御できません。
- [GitGuardian API limitation](https://api.gitguardian.com/docs#operation/multiple_scan)により、インテグレーションは1 MBを超えるファイルを無視します。これらはスキャンされません。
- プッシュされたファイルのファイル名が256文字を超えると、プッシュは完了しません。詳細については、[GitGuardian API documentation](https://api.gitguardian.com/docs#operation/multiple_scan)を参照してください。

[integration page](../user/project/integrations/git_guardian.md#troubleshooting)のトラブルシューティングの手順では、これらの問題の一部を軽減する方法を示します。

### GitGuardianをセットアップ {#set-up-gitguardian}

グループのGitGuardianインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/git-guardian
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明                                   |
| --------- | ---- | -------- |-----------------------------------------------|
| `token` | 文字列 | はい | `scan`スコープを持つGitGuardian APIトークン。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### GitGuardianを無効にする {#disable-gitguardian}

グループのGitGuardianインテグレーションを無効にします。インテグレーションの設定がリセットされました。

```plaintext
DELETE /groups/:id/integrations/git-guardian
```

### GitGuardian設定を取得 {#get-gitguardian-settings}

グループのGitGuardianインテグレーションの設定を取得します。

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
| `token` | 文字列 | はい | `repo:status` OAuthスコープを持つ。 |
| `repository_url` | 文字列 | はい | GitHubリポジトリのURL。 |
| `static_context` | ブール値 | いいえ | [status check name](../user/project/integrations/github.md#static-or-dynamic-status-check-names)にGitLabインスタンスのホスト名を追加します。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### GitHubを無効にする {#disable-github}

グループのGitHubインテグレーションを無効にします。インテグレーションの設定がリセットされました。

```plaintext
DELETE /groups/:id/integrations/github
```

### GitHub設定を取得 {#get-github-settings}

グループのGitHubインテグレーションの設定を取得します。

```plaintext
GET /groups/:id/integrations/github
```

## Jira Cloudアプリ版 {#gitlab-for-jira-cloud-app}

[Jiraでのグループリンクとリンク解除](../integration/jira/connect-app.md#configure-the-gitlab-for-jira-cloud-app)により、GitLab for Jira Cloudアプリインテグレーションは自動的に有効または無効になります。APIまたはGitLabインテグレーションフォームを使用して、インテグレーションを有効または無効にすることはできません。

### グループのインテグレーションを更新 {#update-integration-for-a-group}

このAPIエンドポイントを使用して、Jiraのグループリンクで作成するインテグレーションを更新します。

```plaintext
PUT /groups/:id/integrations/jira-cloud-app
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `jira_cloud_app_service_ids` | 文字列 | いいえ | Jira Service ManagementサービスID。複数のIDを区切るには、カンマ（`,`）を使用します。 |
| `jira_cloud_app_enable_deployment_gating` | ブール値 | いいえ | Jira Service ManagementからのブロックされたGitLabデプロイのデプロイゲーティングを有効にします。 |
| `jira_cloud_app_deployment_gating_environments` | 文字列 | いいえ | デプロイゲーティングを有効にするステージング（本番環境、ステージング、テスト、または開発）のステージング。デプロイゲーティングが有効になっている場合は必須です。複数のステージングを区切るには、カンマ（`,`）を使用します。 |

### Jira CloudアプリのGitLabを取得 {#get-gitlab-for-jira-cloud-app-settings}

グループのJira Cloudアプリ設定のGitLabを取得します。

```plaintext
GET /groups/:id/integrations/jira-cloud-app
```

## GitLab for Slackアプリ {#gitlab-for-slack-app}

### GitLab for Slackアプリを設定 {#set-up-gitlab-for-slack-app}

グループのSlackアプリのGitLabを更新します。

このインテグレーションにはAPIから取得できないOAuth 2.0トークンが必要なため、APIからSlackアプリのGitLabを作成することはできません。代わりに、GitLab UIから[アプリをインストール](../user/project/integrations/gitlab_slack_application.md#install-the-gitlab-for-slack-app)する必要があります。次に、このAPIエンドポイントを使用してインテグレーションを更新できます。

```plaintext
PUT /groups/:id/integrations/gitlab-slack-application
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `channel` | 文字列 | いいえ | 他のチャンネルが設定されていない場合に使用するデフォルトチャンネル。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_default_branch` | ブール値 | いいえ | **非推奨**: このパラメータは、`branches_to_be_notified`に置き換えられました。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `alert_events` | ブール値 | いいえ | アラートイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密ノートイベントの通知を有効にします。 |
| `deployment_events` | ブール値 | いいえ | デプロイメントイベントの通知を有効にします。 |
| `incidents_events` | ブール値 | いいえ | インシデントイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `vulnerability_events` | ブール値 | いいえ | 脆弱性イベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `labels_to_be_notified` | 文字列 | いいえ | 通知を送信するラベル。設定されていない場合は、すべてのイベントの通知を受信します。 |
| `labels_to_be_notified_behavior` | 文字列 | いいえ | 通知されるラベル。有効なオプションは、`match_any`と`match_all`です。`match_any`がデフォルトです。 |
| `push_channel` | 文字列 | いいえ | プッシュイベントの通知を受信するチャンネルの名前。 |
| `issue_channel` | 文字列 | いいえ | イシューイベントの通知を受信するチャンネルの名前。 |
| `confidential_issue_channel` | 文字列 | いいえ | 機密イシューイベントの通知を受信するチャンネルの名前。 |
| `merge_request_channel` | 文字列 | いいえ | マージリクエストイベントの通知を受信するチャンネルの名前。 |
| `note_channel` | 文字列 | いいえ | ノートイベントの通知を受信するチャンネルの名前。 |
| `confidential_note_channel` | 文字列 | いいえ | 機密ノートイベントの通知を受信するチャンネルの名前。 |
| `tag_push_channel` | 文字列 | いいえ | タグプッシュイベントの通知を受信するチャンネルの名前。 |
| `pipeline_channel` | 文字列 | いいえ | パイプラインイベントの通知を受信するチャンネルの名前。 |
| `wiki_page_channel` | 文字列 | いいえ | Wikiページイベントの通知を受信するチャンネルの名前。 |
| `deployment_channel` | 文字列 | いいえ | デプロイメントイベントの通知を受信するチャンネルの名前。 |
| `incident_channel` | 文字列 | いいえ | インシデントイベントの通知を受信するチャンネルの名前。 |
| `vulnerability_channel` | 文字列 | いいえ | 脆弱性イベントの通知を受信するチャンネルの名前。 |
| `alert_channel` | 文字列 | いいえ | アラートイベントの通知を受信するチャンネルの名前。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### GitLab for Slackアプリを無効にする {#disable-gitlab-for-slack-app}

グループのSlackアプリのGitLabインテグレーションを無効にします。インテグレーションの設定がリセットされました。

```plaintext
DELETE /groups/:id/integrations/gitlab-slack-application
```

### SlackアプリのGitLabを取得 {#get-gitlab-for-slack-app-settings}

グループのSlackアプリ設定のGitLabを取得します。

```plaintext
GET /groups/:id/integrations/gitlab-slack-application
```

## Google Chat {#google-chat}

### をセットアップ {#set-up-google-chat}

グループのインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/hangouts-chat
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | HangoutsチャットWebhook（例: `https://chat.googleapis.com/v1/spaces...`）。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_default_branch` | ブール値 | いいえ | **非推奨**: このパラメータは、`branches_to_be_notified`に置き換えられました。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密ノートイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### を無効にする {#disable-google-chat}

グループのインテグレーションを無効にします。インテグレーションの設定がリセットされました。

```plaintext
DELETE /groups/:id/integrations/hangouts-chat
```

### 設定を取得 {#get-google-chat-settings}

グループのインテグレーションの設定を取得します。

```plaintext
GET /groups/:id/integrations/hangouts-chat
```

## Google Artifact Management {#google-artifact-management}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- ステータス: ベータ

{{< /details >}}

この機能は[ベータ版](../policy/development_stages_support.md)です。

### Google Artifact Management {#set-up-google-artifact-management}

グループのGoogleアーティファクト管理インテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/google-cloud-platform-artifact-registry
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `artifact_registry_project_id` | 文字列 | はい | Google CloudプロジェクトのID。 |
| `artifact_registry_location` | 文字列 | はい | Artifact Registryリポジトリの場所。 |
| `artifact_registry_repositories` | 文字列 | はい | Artifact Registryのリポジトリ。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Google Artifact Management {#disable-google-artifact-management}

グループのGoogleアーティファクト管理インテグレーションを無効にします。インテグレーションの設定がリセットされました。

```plaintext
DELETE /groups/:id/integrations/google-cloud-platform-artifact-registry
```

### Googleアーティファクト管理を取得 {#get-google-artifact-management-settings}

グループのGoogleアーティファクト管理設定を取得します。

```plaintext
GET /groups/:id/integrations/google-cloud-platform-artifact-registry
```

## Google Cloud Identity and Access Management（IAM） {#google-cloud-identity-and-access-management-iam}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- ステータス: ベータ

{{< /details >}}

この機能は[ベータ版](../policy/development_stages_support.md)です。

### をセットアップ {#set-up-google-cloud-identity-and-access-management}

グループのインテグレーションをセットアップします。

```plaintext
PUT /groups/:id/integrations/google-cloud-platform-workload-identity-federation
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `workload_identity_federation_project_id` | 文字列 | はい | のGoogle CloudプロジェクトID。 |
| `workload_identity_federation_project_number` | 整数 | はい | のGoogle Cloudプロジェクト番号。 |
| `workload_identity_pool_id` | 文字列 | はい | のID。 |
| `workload_identity_pool_provider_id` | 文字列 | はい |  プロバイダーのID。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### を無効にする {#disable-google-cloud-identity-and-access-management}

グループのGoogle Cloud Identity and Access Managementインテグレーションを無効にします。インテグレーションの設定がリセットされました。

```plaintext
DELETE /groups/:id/integrations/google-cloud-platform-workload-identity-federation
```

### を取得 {#get-google-cloud-identity-and-access-management}

グループのGoogle Cloudアイデンティティとアクセス管理の設定を取得します。

```plaintext
GET /groups/:id/integration/google-cloud-platform-workload-identity-federation
```

## Harbor {#harbor}

### Harborを設定する {#set-up-harbor}

グループのHarborインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/harbor
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `url` | 文字列 | はい | GitLabプロジェクトにリンクされているHarborインスタンスへの基本URL。たとえば`https://demo.goharbor.io`などです。 |
| `project_name` | 文字列 | はい | Harborインスタンス内のプロジェクトの名前。たとえば`testproject`などです。 |
| `username` | 文字列 | はい | Harborインターフェースで作成されたユーザー名。 |
| `password` | 文字列 | はい | ユーザーのパスワード。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Harborを無効にする {#disable-harbor}

グループのHarborインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/harbor
```

### Harborの設定を取得する {#get-harbor-settings}

グループのHarborインテグレーションの設定を取得します。

```plaintext
GET /groups/:id/integrations/harbor
```

## irker（IRCゲートウェイ） {#irker-irc-gateway}

### irkerを設定する {#set-up-irker}

グループのirkerインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/irker
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `recipients` | 文字列 | はい | 空白で区切られた受信者またはチャンネル。 |
| `default_irc_uri` | 文字列 | いいえ | `irc://irc.network.net:6697/`。 |
| `server_host` | 文字列 | いいえ | localhost。 |
| `server_port` | 整数 | いいえ | 6659\. |
| `colorize_messages` | ブール値 | いいえ | メッセージをカラー化します。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### irkerを無効にする {#disable-irker}

グループのirkerインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/irker
```

### irkerの設定を取得する {#get-irker-settings}

グループのirkerインテグレーションの設定を取得します。

```plaintext
GET /groups/:id/integrations/irker
```

## JetBrains TeamCity {#jetbrains-teamcity}

### JetBrains TeamCityを設定する {#set-up-jetbrains-teamcity}

グループのJetBrains TeamCityインテグレーションを設定します。

TeamCityのビルド設定では、ビルド番号の形式`%build.vcs.number%`を使用する必要があります。VCSルートの詳細設定で、すべてのブランチのモニタリングを設定して、マージリクエストをビルドできるようにします。

```plaintext
PUT /groups/:id/integrations/teamcity
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `teamcity_url` | 文字列 | はい | TeamCityルートURL（例: `https://teamcity.example.com`）。 |
| `enable_ssl_verification` | ブール値 | いいえ | SSL検証を有効にします。デフォルトは`true`（有効）。 |
| `build_type` | 文字列 | はい | ビルド設定ID。 |
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

### JetBrains TeamCityの設定を取得する {#get-jetbrains-teamcity-settings}

グループのJetBrains TeamCityインテグレーションの設定を取得します。

```plaintext
GET /groups/:id/integrations/teamcity
```

## Jira {#jira}

### Jiraを設定する {#set-up-jira}

グループのJiraインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/jira
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `url`           | 文字列 | はい | このGitLabプロジェクトにリンクされているJiraプロジェクトのURL（例: `https://jira.example.com`）。 |
| `api_url`   | 文字列 | いいえ | JiraインスタンスAPIへの基本URL。設定されていない場合は、Web URL値が使用されます（例: `https://jira-api.example.com`）。 |
| `username`      | 文字列 | いいえ   | Jiraで使用されるメールまたはユーザー名。Jira Cloudの場合はメールを使用し、Jira Data CenterおよびJira Serverの場合はユーザー名を使用します。Basic認証（`jira_auth_type`が`0`）を使用する場合は必須です。 |
| `password`      | 文字列 | はい  | Jiraで使用されるJira APIトークン、パスワード、またはパーソナルアクセストークン。認証方式がBasic認証（`jira_auth_type`が`0`）の場合は、Jira Cloudの場合はAPIトークンを使用し、Jira Data CenterまたはJira Serverの場合はパスワードを使用します。認証方式がJiraパーソナルアクセストークン（`jira_auth_type`が`1`）の場合は、パーソナルアクセストークンを使用します。 |
| `active`        | ブール値 | いいえ  | インテグレーションをアクティブ化または非アクティブ化します。デフォルトは`false`（非アクティブ化）。 |
| `jira_auth_type`| 整数 | いいえ  | Jiraで使用する認証方式。`0`はBasic認証を意味します。`1`はJiraパーソナルアクセストークンを意味します。`0`がデフォルトです。 |
| `jira_issue_prefix` | 文字列 | いいえ | Jiraイシューキーに一致するプレフィックス。 |
| `jira_issue_regex` | 文字列 | いいえ | Jiraイシューキーに一致する正規表現。 |
| `jira_issue_transition_automatic` | ブール値 | いいえ | [イシューの自動移行](../integration/jira/issues.md#automatic-issue-transitions)を有効にします。有効になっている場合は、`jira_issue_transition_id`よりも優先されます。`false`がデフォルトです。 |
| `jira_issue_transition_id` | 文字列 | いいえ | [カスタムイシューの移行](../integration/jira/issues.md#custom-issue-transitions)の1つ以上のID。`jira_issue_transition_automatic`が有効になっている場合は無視されます。デフォルトでは空の文字列になり、カスタム移行が無効になります。 |
| `commit_events` | ブール値 | いいえ | コミットイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `comment_on_event_enabled` | ブール値 | いいえ | 各GitLabイベント（コミットまたはマージリクエスト）で、Jiraイシューのコメントを有効にします。 |
| `issues_enabled` | ブール値 | いいえ | GitLabでJiraイシューの表示を有効にします。 |
| `project_keys` | 文字列の配列 | いいえ | Jiraプロジェクトのキー。`issues_enabled`が`true`の場合、この設定は、GitLabでイシューを表示するJiraプロジェクトを指定します。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Jiraを無効にする {#disable-jira}

グループのJiraインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/jira
```

### Jiraの設定を取得する {#get-jira-settings}

グループのJiraインテグレーションの設定を取得します。

```plaintext
GET /groups/:id/integrations/jira
```

## Linear {#linear}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198297)されました。

{{< /history >}}

### Linearを設定する {#set-up-linear}

グループのLinearインテグレーションを設定します。

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

### Linearの設定を取得する {#get-linear-settings}

グループのLinearインテグレーションの設定を取得します。

```plaintext
GET /groups/:id/integrations/linear
```

## Matrix通知 {#matrix-notifications}

### Matrix通知を設定する {#set-up-matrix-notifications}

グループのMatrix通知を設定します。

```plaintext
PUT /groups/:id/integrations/matrix
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `hostname`   | 文字列 | いいえ | Matrixサーバーのカスタムホスト名。デフォルト値は`https://matrix.org`です。 |
| `token`   | 文字列 | はい | Matrixアクセストークン（例: `syt-zyx57W2v1u123ew11`）。 |
| `room` | 文字列 | はい | ターゲットルームの一意の識別子（`!qPKKM111FFKKsfoCVy:matrix.org`形式）。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密性の高いイシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密性の高いノートイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Matrix通知を無効にする {#disable-matrix-notifications}

グループのMatrix通知を無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/matrix
```

### Matrix通知の設定を取得する {#get-matrix-notifications-settings}

グループのMatrix通知の設定を取得します。

```plaintext
GET /groups/:id/integrations/matrix
```

## Mattermost通知 {#mattermost-notifications}

### Mattermostの通知を設定する {#set-up-mattermost-notifications}

グループのMattermost通知を設定します。

```plaintext
PUT /groups/:id/integrations/mattermost
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Mattermost通知Webhook（例: `http://mattermost.example.com/hooks/...`）。 |
| `username` | 文字列 | いいえ | Mattermost通知ユーザー名。 |
| `channel` | 文字列 | いいえ | 他のチャンネルが設定されていない場合に使用するデフォルトのチャンネル。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_default_branch` | ブール値 | いいえ | **非推奨**: このパラメータは、`branches_to_be_notified`に置き換えられました。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `labels_to_be_notified` | 文字列 | いいえ | 通知を送信するラベル。すべてのイベントの通知を受信するには、空白のままにします。 |
| `labels_to_be_notified_behavior` | 文字列 | いいえ | 通知するラベル。有効なオプションは、`match_any`と`match_all`です。デフォルト値は`match_any`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密性の高いイシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密性の高いノートイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `push_channel` | 文字列 | いいえ | プッシュイベントの通知を受信するチャンネルの名前。 |
| `issue_channel` | 文字列 | いいえ | イシューイベントの通知を受信するチャンネルの名前。 |
| `confidential_issue_channel` | 文字列 | いいえ | 機密性の高いイシューイベントの通知を受信するチャンネルの名前。 |
| `merge_request_channel` | 文字列 | いいえ | マージリクエストイベントの通知を受信するチャンネルの名前。 |
| `note_channel` | 文字列 | いいえ | ノートイベントの通知を受信するチャンネルの名前。 |
| `confidential_note_channel` | 文字列 | いいえ | 機密性の高いノートイベントの通知を受信するチャンネルの名前。 |
| `tag_push_channel` | 文字列 | いいえ | タグプッシュイベントの通知を受信するチャンネルの名前。 |
| `pipeline_channel` | 文字列 | いいえ | パイプラインイベントの通知を受信するチャンネルの名前。 |
| `wiki_page_channel` | 文字列 | いいえ | Wikiページイベントの通知を受信するチャンネルの名前。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Mattermostの通知を無効にする {#disable-mattermost-notifications}

グループのMattermost通知を無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/mattermost
```

### Mattermost通知の設定を取得する {#get-mattermost-notifications-settings}

グループのMattermost通知の設定を取得します。

```plaintext
GET /groups/:id/integrations/mattermost
```

## Mattermostのスラッシュコマンド {#mattermost-slash-commands}

### Mattermostのスラッシュコマンドを設定する {#set-up-mattermost-slash-commands}

グループのMattermostスラッシュコマンドをセットアップします。

```plaintext
PUT /groups/:id/integrations/mattermost-slash-commands
```

パラメータは以下のとおりです:

| パラメータ | 型   | 必須 | 説明           |
| --------- | ------ | -------- | --------------------- |
| `token`   | 文字列 | はい      | Mattermostトークン。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Mattermostのスラッシュコマンドを無効にする {#disable-mattermost-slash-commands}

グループのMattermostスラッシュコマンドを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/mattermost-slash-commands
```

### Mattermostスラッシュコマンドの設定を取得する {#get-mattermost-slash-commands-settings}

グループのMattermostスラッシュコマンドの設定を取得します。

```plaintext
GET /groups/:id/integrations/mattermost-slash-commands
```

## Microsoft Teams通知 {#microsoft-teams-notifications}

### Microsoft Teamsの通知を設定する {#set-up-microsoft-teams-notifications}

グループのMicrosoft Teams通知を設定します。

```plaintext
PUT /groups/:id/integrations/microsoft-teams
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Microsoft Teams Webhook（例: `https://outlook.office.com/webhook/...`）。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_default_branch` | ブール値 | いいえ | **非推奨**: このパラメータは、`branches_to_be_notified`に置き換えられました。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密性の高いイシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | 注記イベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密性の高い注記イベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Microsoft Teamsの通知を無効にする {#disable-microsoft-teams-notifications}

グループのMicrosoft Teams通知を無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/microsoft-teams
```

### Microsoft Teams通知の設定を取得します {#get-microsoft-teams-notifications-settings}

グループのMicrosoft Teams通知の設定を取得します。

```plaintext
GET /groups/:id/integrations/microsoft-teams
```

## モックCI {#mock-ci}

このインテグレーションは、開発環境でのみ利用可能です。モックCIサーバーの例については、[`gitlab-org/gitlab-mock-ci-service`](https://gitlab.com/gitlab-org/gitlab-mock-ci-service)を参照してください。

### モックCIを設定します {#set-up-mock-ci}

グループのモックCIインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/mock-ci
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `mock_service_url` | 文字列 | はい | モックCIインテグレーションのURL。 |
| `enable_ssl_verification` | ブール値 | いいえ | SSL検証を有効にします。`true`（有効）がデフォルトです。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### モックCIを無効にします {#disable-mock-ci}

グループのモックCIインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/mock-ci
```

### モックCI設定を取得します {#get-mock-ci-settings}

グループのモックCIインテグレーションの設定を取得します。

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
| `server` | ブール値 | いいえ | PackagistサーバーのURL。デフォルトの`<https://packagist.org>`の場合は空白のままにします。 |
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

グループのPackagistインテグレーションの設定を取得します。

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

グループのPhorgeインテグレーションの設定を取得します。

```plaintext
GET /groups/:id/integrations/phorge
```

## パイプラインステータス {#pipeline-status-emails}

### パイプラインのステータスメールを設定する {#set-up-pipeline-status-emails}

グループのパイプラインステータスメールを設定します。

```plaintext
PUT /groups/:id/integrations/pipelines-email
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `recipients` | 文字列 | はい | 受信者のメールアドレスのカンマ区切りリスト。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `notify_only_default_branch` | ブール値 | いいえ | デフォルトブランチの通知を送信します。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### パイプラインステータスメールを無効にします {#disable-pipeline-status-emails}

グループのパイプラインステータスメールを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/pipelines-email
```

### パイプラインステータスメール設定を取得します {#get-pipeline-status-emails-settings}

グループのパイプラインステータスメールの設定を取得します。

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
| `restrict_to_branch` | ブール値 | いいえ | 自動的に検査するブランチのカンマ区切りリスト。すべてのブランチを含めるには、空白のままにします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Pivotal Trackerを無効にします {#disable-pivotal-tracker}

グループのPivotal Trackerインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/pivotaltracker
```

### Pivotal Tracker設定を取得します {#get-pivotal-tracker-settings}

グループのPivotal Trackerインテグレーションの設定を取得します。

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
| `webhook` | 文字列 | はい | PumbleWebhook（例: `https://api.pumble.com/workspaces/x/...`）。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、および`default_and_protected`です。デフォルトは`default`です。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密性の高いイシューイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密性の高い注記イベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | 注記イベントの通知を有効にします。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
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

グループのPumbleインテグレーションの設定を取得します。

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
| `device` | 文字列 | いいえ | すべてのアクティブなデバイスの場合は空白のままにします。 |
| `sound` | 文字列 | いいえ | 通知のサウンド。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Pushoverを無効にします {#disable-pushover}

グループのPushoverインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/pushover
```

### Pushover設定を取得します {#get-pushover-settings}

グループのPushoverインテグレーションの設定を取得します。

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

グループのRedmineインテグレーションの設定を取得します。

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
| `username` | 文字列 | いいえ | Slack通知のユーザー名。 |
| `channel` | 文字列 | いいえ | 他のチャンネルが構成されていない場合に使用するデフォルトチャンネル。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_default_branch` | ブール値 | いいえ | **非推奨**: このパラメータは、`branches_to_be_notified`に置き換えられました。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `labels_to_be_notified` | 文字列 | いいえ | 通知を送信するラベル。すべてのイベントの通知を受信するには、空白のままにします。 |
| `labels_to_be_notified_behavior` | 文字列 | いいえ | 通知を受信するラベル。有効なオプションは、`match_any`と`match_all`です。デフォルト値は`match_any`です。 |
| `alert_channel` | 文字列 | いいえ | アラートイベントの通知を受信するチャンネルの名前。 |
| `alert_events` | ブール値 | いいえ | アラートイベントの通知を有効にします。 |
| `commit_events` | ブール値 | いいえ | コミットイベントの通知を有効にします。 |
| `confidential_issue_channel` | 文字列 | いいえ | 機密性の高いイシューイベントの通知を受信するチャンネルの名前。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密性の高いイシューイベントの通知を有効にします。 |
| `confidential_note_channel` | 文字列 | いいえ | 機密性の高い注記イベントの通知を受信するチャンネルの名前。 |
| `confidential_note_events` | ブール値 | いいえ | 機密性の高い注記イベントの通知を有効にします。 |
| `deployment_channel` | 文字列 | いいえ | デプロイイベントの通知を受信するチャンネルの名前。 |
| `deployment_events` | ブール値 | いいえ | デプロイイベントの通知を有効にします。 |
| `incident_channel` | 文字列 | いいえ | インシデントイベントの通知を受信するチャンネルの名前。 |
| `incidents_events` | ブール値 | いいえ | インシデントイベントの通知を有効にします。 |
| `issue_channel` | 文字列 | いいえ | イシューイベントの通知を受信するチャンネルの名前。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `job_events` | ブール値 | いいえ | ジョブイベントの通知を有効にします。 |
| `merge_request_channel` | 文字列 | いいえ | マージリクエストイベントの通知を受信するチャンネルの名前。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `note_channel` | 文字列 | いいえ | 注記イベントの通知を受信するチャンネルの名前。 |
| `note_events` | ブール値 | いいえ | 注記イベントの通知を有効にします。 |
| `pipeline_channel` | 文字列 | いいえ | パイプラインイベントの通知を受信するチャンネルの名前。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `push_channel` | 文字列 | いいえ | プッシュイベントの通知を受信するチャンネルの名前。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `tag_push_channel` | 文字列 | いいえ | タグプッシュイベントの通知を受信するチャンネルの名前。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `wiki_page_channel` | 文字列 | いいえ | Wikiページイベントの通知を受信するチャンネルの名前。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Slack通知を無効にします {#disable-slack-notifications}

グループのSlack通知を無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/slack
```

### Slack通知設定を取得します {#get-slack-notifications-settings}

グループのSlack通知の設定を取得します。

```plaintext
GET /groups/:id/integrations/slack
```

## Slackのスラッシュコマンド {#slack-slash-commands}

### Slackスラッシュコマンドを設定します {#set-up-slack-slash-commands}

グループのSlackスラッシュコマンドを設定します。

```plaintext
PUT /groups/:id/integrations/slack-slash-commands
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `token` | 文字列 | はい | Slackトークン。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Slackスラッシュコマンドを無効にします {#disable-slack-slash-commands}

グループのSlackスラッシュコマンドを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /groups/:id/integrations/slack-slash-commands
```

### Slackスラッシュコマンド設定を取得します {#get-slack-slash-commands-settings}

グループのSlackスラッシュコマンドの設定を取得します。

```plaintext
GET /groups/:id/integrations/slack-slash-commands
```

レスポンス例:

```json
{
  "id": 4,
  "title": "Slack slash commands",
  "slug": "slack-slash-commands",
  "created_at": "2017-06-27T05:51:39-07:00",
  "updated_at": "2017-06-27T05:51:39-07:00",
  "active": true,
  "push_events": true,
  "issues_events": true,
  "confidential_issues_events": true,
  "merge_requests_events": true,
  "tag_push_events": true,
  "note_events": true,
  "job_events": true,
  "pipeline_events": true,
  "comment_on_event_enabled": false,
  "inherited": false,
  "properties": {
    "token": "<your_access_token>"
  }
}
```

## Squash TM {#squash-tm}

### Squash TMを設定します {#set-up-squash-tm}

グループのSquash TMインテグレーションの設定を設定します。

```plaintext
PUT /groups/:id/integrations/squash-tm
```

パラメータは以下のとおりです:

| パラメータ               | 型   | 必須 | 説明                   |
|-------------------------|--------|----------|-------------------------------|
| `url`                   | 文字列 | はい      | Squash TMWebhookのURL。 |
| `token`                 | 文字列 | いいえ       | シークレットトークン。                 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Squash TMを無効にします {#disable-squash-tm}

グループのSquash TMインテグレーションを無効にします。インテグレーションの設定は保持されます。

```plaintext
DELETE /groups/:id/integrations/squash-tm
```

### Squash TM設定を取得します {#get-squash-tm-settings}

グループのSquash TMインテグレーションの設定を取得します。

```plaintext
GET /groups/:id/integrations/squash-tm
```

## Telegram {#telegram}

### Telegramを設定 {#set-up-telegram}

グループのTelegramインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/telegram
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `hostname`   | 文字列 | いいえ | Telegram APIのカスタムホスト名。デフォルト値は`https://api.telegram.org`です。 |
| `token`   | 文字列 | はい | Telegramボットトークン（例: `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`）。 |
| `room` | 文字列 | はい | ターゲットチャットまたはターゲットチャンネルのユーザー名の一意の識別子（形式: `@channelusername`）。 |
| `thread` | 整数 | いいえ | ターゲットメッセージスレッドの一意の識別子（フォーラムスーパーグループのトピック）。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | はい | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | はい | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | はい | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | はい | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | はい | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | はい | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | はい | 機密ノートイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | はい | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | はい | Wikiページのイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Telegramを無効化 {#disable-telegram}

グループのTelegramインテグレーションを無効にします。インテグレーション設定がリセットされました。

```plaintext
DELETE /groups/:id/integrations/telegram
```

### Telegram設定を取得 {#get-telegram-settings}

グループのTelegramインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/telegram
```

## Unify Circuit {#unify-circuit}

### Unify Circuitを設定 {#set-up-unify-circuit}

グループのUnify Circuitインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/unify-circuit
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Unify Circuit Webhook（例: `https://circuit.com/rest/v2/webhooks/incoming/...`）。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密ノートイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページのイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Unify Circuitを無効化 {#disable-unify-circuit}

グループのUnify Circuitインテグレーションを無効にします。インテグレーション設定がリセットされました。

```plaintext
DELETE /groups/:id/integrations/unify-circuit
```

### Unify Circuit設定を取得 {#get-unify-circuit-settings}

グループのUnify Circuitインテグレーション設定を取得します。

```plaintext
GET /groups/:id/integrations/unify-circuit
```

## Webex Teams {#webex-teams}

### Webex Teamsを設定 {#set-up-webex-teams}

グループのWebex Teamsを設定します。

```plaintext
PUT /groups/:id/integrations/webex-teams
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Webex Teams Webhook（例: `https://api.ciscospark.com/v1/webhooks/incoming/...`）。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密ノートイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページのイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Webex Teamsを無効化 {#disable-webex-teams}

グループのWebex Teamsを無効にします。インテグレーション設定がリセットされました。

```plaintext
DELETE /groups/:id/integrations/webex-teams
```

### Webex Teams設定を取得 {#get-webex-teams-settings}

グループのWebex Teamsの設定を取得します。

```plaintext
GET /groups/:id/integrations/webex-teams
```

## YouTrack {#youtrack}

### YouTrackを設定 {#set-up-youtrack}

グループのYouTrackインテグレーションを設定します。

```plaintext
PUT /groups/:id/integrations/youtrack
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `issues_url` | 文字列 | はい | イシューのURL。 |
| `project_url` | 文字列 | はい | プロジェクトのURL。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### YouTrackを無効化 {#disable-youtrack}

グループのYouTrackインテグレーションを無効にします。インテグレーション設定がリセットされました。

```plaintext
DELETE /groups/:id/integrations/youtrack
```

### YouTrack設定を取得 {#get-youtrack-settings}

グループのYouTrackインテグレーションの設定を取得します。

```plaintext
GET /groups/:id/integrations/youtrack
```
