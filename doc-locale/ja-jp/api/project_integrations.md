---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトインテグレーションAPI
description: "REST APIを使用して、プロジェクトのインテグレーションを設定および管理します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、プロジェクトの[インテグレーション](../user/project/integrations/_index.md)を管理します。

前提要件: 

- プロジェクトのメンテナー以上のロールを持っている必要があります。

## すべてのアクティブなインテグレーションをリスト表示 {#list-all-active-integrations}

{{< history >}}

- `vulnerability_events`フィールドは、GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131831)されました。
- `inherited`フィールドは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154915)されました。デフォルトでは無効になっています。
- `inherited`フィールドは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

すべてのアクティブなプロジェクトインテグレーションのリストを取得します。`vulnerability_events`フィールドは、GitLab Enterprise Editionでのみ使用できます。

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

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Apple App Store Connectを設定 {#set-up-apple-app-store-connect}

プロジェクトのApple App Store Connectインテグレーションを設定します。

```plaintext
PUT /projects/:id/integrations/apple_app_store
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `app_store_issuer_id` | 文字列 | はい | Apple App Store Connect Issuer ID。 |
| `app_store_key_id` | 文字列 | はい | Apple App Store ConnectキーID。 |
| `app_store_private_key_file_name` | 文字列 | はい | Apple App Store Connectの秘密キーファイル名。 |
| `app_store_private_key` | 文字列 | はい | Apple App Store Connectの秘密キー。 |
| `app_store_protected_refs` | ブール値 | いいえ | 保護されたブランチとタグでのみ変数を設定します。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Apple App Store Connectを無効化 {#disable-apple-app-store-connect}

プロジェクトのApple App Store Connectインテグレーションを無効にします。インテグレーション設定がリセットされました。

```plaintext
DELETE /projects/:id/integrations/apple_app_store
```

### Apple App Store Connect設定を取得 {#get-apple-app-store-connect-settings}

プロジェクトのApple App Store Connectインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/apple_app_store
```

## Asana {#asana}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Asanaを設定 {#set-up-asana}

プロジェクトのAsanaインテグレーションを設定します。

```plaintext
PUT /projects/:id/integrations/asana
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `api_key` | 文字列 | はい | ユーザーAPIトークン。ユーザーはタスクにアクセスできる必要があります。すべてのコメントは、このユーザーに起因します。 |
| `restrict_to_branch` | 文字列 | いいえ | 自動的に検査されるブランチのコンマ区切りリスト。すべてのブランチを含めるには、空白のままにします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Asanaを無効にする {#disable-asana}

プロジェクトのAsanaインテグレーションを無効にします。インテグレーション設定がリセットされました。

```plaintext
DELETE /projects/:id/integrations/asana
```

### Asana設定を取得 {#get-asana-settings}

プロジェクトのAsanaインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/asana
```

## Assembla {#assembla}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Assemblaを設定 {#set-up-assembla}

プロジェクトのAssemblaインテグレーションを設定します。

```plaintext
PUT /projects/:id/integrations/assembla
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `token` | 文字列 | はい | 認証トークン。 |
| `subdomain` | 文字列 | いいえ | サブドメイン設定。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Assemblaを無効にする {#disable-assembla}

プロジェクトのAssemblaインテグレーションを無効にします。インテグレーション設定がリセットされました。

```plaintext
DELETE /projects/:id/integrations/assembla
```

### Assembla設定を取得 {#get-assembla-settings}

プロジェクトのAssemblaインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/assembla
```

## Atlassian Bamboo {#atlassian-bamboo}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Atlassian Bambooを設定 {#set-up-atlassian-bamboo}

プロジェクトのAtlassian Bambooインテグレーションを設定します。

Bambooで自動リビジョンラベルとリポジトリトリガーを構成する必要があります。

```plaintext
PUT /projects/:id/integrations/bamboo
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `bamboo_url` | 文字列 | はい | BambooルートURL（例：`https://bamboo.example.com`）。 |
| `enable_ssl_verification` | ブール値 | いいえ | SSL検証を有効にします。デフォルトは`true`（有効）です。 |
| `build_key` | 文字列 | はい | Bambooビルドプランキー（例：`KEY`）。 |
| `username` | 文字列 | はい | BambooサーバーへのAPIアクセスを持つユーザー。 |
| `password` | 文字列 | はい | ユーザーのパスワード。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Atlassian Bambooを無効にする {#disable-atlassian-bamboo}

プロジェクトのAtlassian Bambooインテグレーションを無効にします。インテグレーション設定がリセットされました。

```plaintext
DELETE /projects/:id/integrations/bamboo
```

### Atlassian Bamboo設定を取得 {#get-atlassian-bamboo-settings}

プロジェクトのAtlassian Bambooインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/bamboo
```

## Bugzilla {#bugzilla}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Bugzillaを設定 {#set-up-bugzilla}

プロジェクトのBugzillaインテグレーションを設定します。

```plaintext
PUT /projects/:id/integrations/bugzilla
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | 文字列 | はい |  新しいイシューのURL。 |
| `issues_url` | 文字列 | はい | イシューのURL。 |
| `project_url` | 文字列 | はい | プロジェクトのURL。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Bugzillaを無効にする {#disable-bugzilla}

プロジェクトのBugzillaインテグレーションを無効にします。インテグレーション設定がリセットされました。

```plaintext
DELETE /projects/:id/integrations/bugzilla
```

### Bugzilla設定を取得 {#get-bugzilla-settings}

プロジェクトのBugzillaインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/bugzilla
```

## Buildkite {#buildkite}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Buildkiteを設定 {#set-up-buildkite}

プロジェクトのBuildkiteインテグレーションを設定します。

```plaintext
PUT /projects/:id/integrations/buildkite
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `token` | 文字列 | はい | GitLabリポジトリでBuildkiteパイプラインを作成した後に取得するトークン。 |
| `project_url` | 文字列 | はい | パイプラインのURL（例：`https://buildkite.com/example/pipeline`）。 |
| `enable_ssl_verification` | ブール値 | いいえ | **非推奨**: SSL検証は常に有効になっているため、このパラメータは無効です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Buildkiteを無効にする {#disable-buildkite}

プロジェクトのBuildkiteインテグレーションを無効にします。インテグレーション設定がリセットされました。

```plaintext
DELETE /projects/:id/integrations/buildkite
```

### Buildkite設定を取得 {#get-buildkite-settings}

プロジェクトのBuildkiteインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/buildkite
```

## Campfire Classic {#campfire-classic}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

Campfire Classicとインテグレーションできます。ただし、Campfire Classicは、Basecampによって[販売されなくなった](https://gitlab.com/gitlab-org/gitlab/-/issues/329337)古い製品です。

### Campfire Classicを設定 {#set-up-campfire-classic}

プロジェクトのCampfire Classicインテグレーションを設定します。

```plaintext
PUT /projects/:id/integrations/campfire
```

パラメータは以下のとおりです:

| パラメータ     | 型    | 必須 | 説明                                                                                 |
|---------------|---------|----------|---------------------------------------------------------------------------------------------|
| `token`       | 文字列  | はい     | Campfire ClassicからのAPI認証トークン。トークンを取得するには、Campfire Classicにサインインし、**My info**（個人情報）を選択します。 |
| `subdomain`   | 文字列  | いいえ    | サインインしているときの`.campfirenow.com`サブドメイン。 |
| `room`        | 文字列  | いいえ    | Campfire ClassicルームURLのID部分。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Campfire Classicを無効にする {#disable-campfire-classic}

プロジェクトのCampfire Classicインテグレーションを無効にします。インテグレーション設定がリセットされました。

```plaintext
DELETE /projects/:id/integrations/campfire
```

### Campfire Classic設定を取得 {#get-campfire-classic-settings}

プロジェクトのCampfire Classicインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/campfire
```

## ClickUp {#clickup}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120732)されました。
- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### ClickUpを設定 {#set-up-clickup}

プロジェクトのClickUpインテグレーションを設定します。

```plaintext
PUT /projects/:id/integrations/clickup
```

パラメータは以下のとおりです:

| パラメータ     | 型   | 必須 | 説明    |
| ------------- | ------ | -------- | -------------- |
| `issues_url`  | 文字列 | はい     | イシューのURL。     |
| `project_url` | 文字列 | はい     | プロジェクトのURL。   |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### ClickUpを無効にする {#disable-clickup}

プロジェクトのClickUpインテグレーションを無効にします。インテグレーション設定がリセットされました。

```plaintext
DELETE /projects/:id/integrations/clickup
```

### ClickUp設定を取得 {#get-clickup-settings}

プロジェクトのClickUpインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/clickup
```

## Confluenceワークスペース {#confluence-workspace}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)されました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

プロジェクトのWikiとしてConfluence Cloudワークスペースを使用します。

### Confluenceワークスペースを設定 {#set-up-confluence-workspace}

プロジェクトのConfluenceワークスペースインテグレーションを設定します。

```plaintext
PUT /projects/:id/integrations/confluence
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `confluence_url` | 文字列 | はい | `atlassian.net`でホストされているConfluenceワークスペースのURL。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Confluenceワークスペースを無効にする {#disable-confluence-workspace}

プロジェクトのConfluenceワークスペースインテグレーションを無効にします。インテグレーション設定がリセットされました。

```plaintext
DELETE /projects/:id/integrations/confluence
```

### Confluenceワークスペース設定を取得 {#get-confluence-workspace-settings}

プロジェクトのConfluenceワークスペースインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/confluence
```

## カスタムイシュートラッカー {#custom-issue-tracker}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### カスタムイシュートラッカーを設定 {#set-up-a-custom-issue-tracker}

プロジェクトのカスタムイシュートラッカーを設定します。

```plaintext
PUT /projects/:id/integrations/custom-issue-tracker
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | 文字列 | はい |  新しいイシューのURL。 |
| `issues_url` | 文字列 | はい | イシューのURL。 |
| `project_url` | 文字列 | はい | プロジェクトのURL。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### カスタムイシュートラッカーを無効にする {#disable-a-custom-issue-tracker}

プロジェクトのカスタムイシュートラッカーを無効にします。インテグレーション設定がリセットされました。

```plaintext
DELETE /projects/:id/integrations/custom-issue-tracker
```

### カスタムイシュートラッカー設定を取得 {#get-custom-issue-tracker-settings}

プロジェクトのカスタムイシュートラッカー設定を取得します。

```plaintext
GET /projects/:id/integrations/custom-issue-tracker
```

## Datadog {#datadog}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Datadogを設定 {#set-up-datadog}

プロジェクトのDatadogインテグレーションを設定します。

```plaintext
PUT /projects/:id/integrations/datadog
```

パラメータは以下のとおりです:

| パラメータ              | 型    | 必須 | 説明                                                                                                                                                                            |
|------------------------|---------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `api_key`              | 文字列  | はい     | Datadogとの認証に使用される[APIキー](https://docs.datadoghq.com/account_management/api-app-keys/)。 |
| `datadog_ci_visibility`| ブール値 | はい     | パイプライン実行トレーシングを表示するために、Datadogでパイプラインイベントとジョブイベントの収集を有効にします。 |
| `api_url`              | 文字列  | いいえ    | Datadogサイトの完全なURL。 |
| `datadog_env`          | 文字列  | いいえ    | セルフマネージドデプロイの場合、Datadogに送信されるすべてのデータの`env%`タグ。 |
| `datadog_service`      | 文字列  | いいえ    | Datadog内のすべてのデータをタグ付けするGitLabインスタンス。いくつかのセルフマネージドデプロイを管理する場合に使用できます。 |
| `datadog_site`         | 文字列  | いいえ    | データの送信先となるDatadogサイト。EUサイトにデータを送信するには、`datadoghq.eu`を使用します。 |
| `datadog_tags`         | 文字列  | いいえ    | Datadogのカスタムタグ。形式`key:value\nkey2:value2`で、1行に1つのタグを指定します。 |
| `archive_trace_events` | ブール値 | いいえ    | 有効にすると、ジョブログがDatadogによって収集され、パイプライン実行トレーシングとともに表示されます（GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/346339)）。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Datadogを無効にする {#disable-datadog}

プロジェクトのDatadogインテグレーションを無効にします。インテグレーション設定がリセットされました。

```plaintext
DELETE /projects/:id/integrations/datadog
```

### Datadog設定を取得 {#get-datadog-settings}

プロジェクトのDatadogインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/datadog
```

## Diffblue Cover {#diffblue-cover}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Diffblue Coverを設定 {#set-up-diffblue-cover}

プロジェクトのDiffblue Coverインテグレーションを設定します。

```plaintext
PUT /projects/:id/integrations/diffblue-cover
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `diffblue_license_key` | 文字列 | はい | Diffblue Coverライセンスキー。 |
| `diffblue_access_token_name` | 文字列 | はい | パイプラインでDiffblue Coverによって使用されるアクセストークン名。 |
| `diffblue_access_token_secret` | 文字列  | はい | パイプラインでDiffblue Coverによって使用されるアクセストークンシークレット。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Diffblue Coverを無効にする {#disable-diffblue-cover}

プロジェクトのDiffblue Coverインテグレーションを無効にします。インテグレーション設定がリセットされました。

```plaintext
DELETE /projects/:id/integrations/diffblue-cover
```

### Diffblue Cover設定を取得 {#get-diffblue-cover-settings}

プロジェクトのDiffblue Coverインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/diffblue-cover
```

## Discordの通知 {#discord-notifications}

{{< history >}}

- `_channel`パラメータ（GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125621)）。
- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Discordの通知を設定 {#set-up-discord-notifications}

プロジェクトのDiscord通知を設定します。

```plaintext
PUT /projects/:id/integrations/discord
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Discord Webhook（例：`https://discord.com/api/webhooks/...`）。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `confidential_issue_channel` | 文字列 | いいえ | 機密イシューイベントの通知を受信するWebhookのオーバーライド。 |
| `confidential_note_events` | ブール値 | いいえ | 機密メモイベントの通知を有効にします。 |
| `confidential_note_channel` | 文字列 | いいえ | 機密メモイベントの通知を受信するWebhookのオーバーライド。 |
| `deployment_events` | ブール値 | いいえ | デプロイイベントの通知を有効にします。 |
| `deployment_channel` | 文字列 | いいえ | デプロイイベントの通知を受信するWebhookのオーバーライド。 |
| `group_confidential_mentions_events` | ブール値 | いいえ | グループの機密メンションイベントの通知を有効にします。 |
| `group_confidential_mentions_channel` | 文字列 | いいえ | グループの機密メンションイベントの通知を受信するWebhookのオーバーライド。 |
| `group_mentions_events` | ブール値 | いいえ | グループメンションイベントの通知を有効にします。 |
| `group_mentions_channel` | 文字列 | いいえ | グループメンションイベントの通知を受信するWebhookのオーバーライド。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `issue_channel` | 文字列 | いいえ | イシューイベントの通知を受信するWebhookのオーバーライド。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `merge_request_channel` | 文字列 | いいえ | マージリクエストイベントの通知を受信するWebhookのオーバーライド。 |
| `note_events` | ブール値 | いいえ | メモイベントの通知を有効にします。 |
| `note_channel` | 文字列 | いいえ | メモイベントの通知を受信するWebhookのオーバーライド。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | ブロックされたパイプラインの通知を送信します。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `pipeline_channel` | 文字列 | いいえ | パイプラインイベントの通知を受信するWebhookのオーバーライド。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `push_channel` | 文字列 | いいえ | プッシュイベントの通知を受信するWebhookのオーバーライド。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `tag_push_channel` | 文字列 | いいえ | タグプッシュイベントの通知を受信するWebhookのオーバーライド。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `wiki_page_channel` | 文字列 | いいえ | Wikiページイベントの通知を受信するWebhookのオーバーライド。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Discord通知を無効にする {#disable-discord-notifications}

プロジェクトのDiscord通知を無効にします。インテグレーション設定がリセットされました。

```plaintext
DELETE /projects/:id/integrations/discord
```

### Discord通知設定を取得 {#get-discord-notifications-settings}

プロジェクトのDiscord通知設定を取得します。

```plaintext
GET /projects/:id/integrations/discord
```

## Drone {#drone}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Droneを設定 {#set-up-drone}

プロジェクトのDroneインテグレーションを設定します。

```plaintext
PUT /projects/:id/integrations/drone-ci
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `token` | 文字列 | はい | Drone CIトークン。 |
| `drone_url` | 文字列 | はい | Drone CI URL（例：`http://drone.example.com`）。 |
| `enable_ssl_verification` | ブール値 | いいえ | SSL認証を有効にします。デフォルトは`true`（有効）です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグ付けプッシュイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Droneを無効にする {#disable-drone}

プロジェクトのDroneインテグレーションを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /projects/:id/integrations/drone-ci
```

### Drone設定を取得 {#get-drone-settings}

プロジェクトのDroneインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/drone-ci
```

## プッシュ時にメールを送信 {#emails-on-push}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### プッシュ時にメールを送信 {#set-up-emails-on-push}

プロジェクトのプッシュ時にメールを送信インテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/emails-on-push
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `recipients` | 文字列 | はい | メールは空白で区切ります。 |
| `disable_diffs` | ブール値 | いいえ | コードの差分を無効にします。 |
| `send_from_committer_email` | ブール値 | いいえ | コミッターから送信。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグ付けプッシュイベントの通知を有効にします。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、および`default_and_protected`です。通知は、タグ付けのプッシュで常にトリガーされます。デフォルト値は`all`です。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### プッシュ時にメールを送信を無効にする {#disable-emails-on-push}

プロジェクトのプッシュ時にメールを送信インテグレーションを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /projects/:id/integrations/emails-on-push
```

### プッシュ時にメールを送信設定を取得 {#get-emails-on-push-settings}

プロジェクトのプッシュ時にメールを送信インテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/emails-on-push
```

## EngineeringワークフローManagement（EWM） {#engineering-workflow-management-ewm}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### EWMをセットアップ {#set-up-ewm}

プロジェクトのEWMインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/ewm
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | 文字列 | はい | 新しいイシューのURL。 |
| `project_url`   | 文字列 | はい | プロジェクトのURL。 |
| `issues_url`    | 文字列 | はい | イシューのURL。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### EWMを無効にする {#disable-ewm}

プロジェクトのEWMインテグレーションを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /projects/:id/integrations/ewm
```

### EWM設定を取得 {#get-ewm-settings}

プロジェクトのEWMインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/ewm
```

## 外部 {#external-wiki}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

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

### 外部Wikiを無効にする {#disable-an-external-wiki}

プロジェクトの外部Wikiを無効にします。インテグレーションの設定はリセットされます。

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
- GitLab 17.7の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/438695#note_2226917025)になりました。
- GitLab 17.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176391)になりました。機能フラグ`git_guardian_integration`は削除されました。
- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

[GitGuardian](https://www.gitguardian.com/)は、APIキーやパスワードなどの機密データをソースコードリポジトリで検出するサイバーセキュリティサービスです。Gitリポジトリをスキャンし、ポリシー違反についてアラートを送信し、ハッカーが悪用する前に組織がセキュリティを修正するのを支援します。

GitGuardianのポリシーに基づいてコミットを拒否するようにGitLabを構成できます。

### 既知の問題 {#known-issues}

- プッシュが遅延したり、タイムアウトしたりする可能性があります。GitGuardianインテグレーションでは、プッシュはサードパーティに送信され、GitLabはGitGuardianとの接続またはGitGuardianのプロセスを制御できません。
- [GitGuardian API limitation](https://api.gitguardian.com/docs#operation/multiple_scan)により、インテグレーションはサイズが1 MBを超えるファイルを無視します。それらはスキャンされません。
- プッシュされたファイルの名前が256文字を超える長さのプッシュは完了しません。詳細については、[GitGuardian API documentation](https://api.gitguardian.com/docs#operation/multiple_scan)を参照してください。

[integration page](../user/project/integrations/git_guardian.md#troubleshooting)のトラブルシューティングの手順は、これらの問題のいくつかを緩和する方法を示しています。

### GitGuardianをセットアップ {#set-up-gitguardian}

プロジェクトのGitGuardianインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/git-guardian
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明                                   |
| --------- | ---- | -------- |-----------------------------------------------|
| `token` | 文字列 | はい | `scan`スコープを持つGitGuardian APIトークン。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### GitGuardianを無効にする {#disable-gitguardian}

プロジェクトのGitGuardianインテグレーションを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /projects/:id/integrations/git-guardian
```

### GitGuardian設定を取得 {#get-gitguardian-settings}

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

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### GitHubをセットアップ {#set-up-github}

プロジェクトのGitHubインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/github
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `token` | 文字列 | はい | `repo:status` OAuth 2.0スコープを持つGitHub APIトークン。 |
| `repository_url` | 文字列 | はい | GitHubリポジトリURL。 |
| `static_context` | ブール値 | いいえ | [ステータスチェック名](../user/project/integrations/github.md#static-or-dynamic-status-check-names)に、GitLabインスタンスのホスト名を追加します。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### GitHubを無効にする {#disable-github}

プロジェクトのGitHubインテグレーションを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /projects/:id/integrations/github
```

### GitHub設定を取得 {#get-github-settings}

プロジェクトのGitHubインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/github
```

## GitLab for Jira Cloudアプリ {#gitlab-for-jira-cloud-app}

GitLab for Jira Cloudアプリインテグレーションは、[Jiraでのグループリンクとリンク解除](../integration/jira/connect-app.md#configure-the-gitlab-for-jira-cloud-app)によって自動的に有効または無効になります。GitLab統合フォームまたはAPIを使用して統合を有効または無効にすることはできません。

### プロジェクトのインテグレーションを更新する {#update-integration-for-a-project}

このAPIエンドポイントを使用して、Jiraでグループのリンクを使用して作成するインテグレーションを更新します。

```plaintext
PUT /projects/:id/integrations/jira-cloud-app
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `jira_cloud_app_service_ids` | 文字列 | いいえ | Jira Service ManagementサービスID。複数のIDを区切るには、コンマ（`,`）を使用します。 |
| `jira_cloud_app_enable_deployment_gating` | ブール値 | いいえ | Jira Service ManagementからのブロックされたGitLabデプロイに対してデプロイゲーティングを有効にします。 |
| `jira_cloud_app_deployment_gating_environments` | 文字列 | いいえ | デプロイゲーティングを有効にする環境（本番環境、ステージング、テスト、または開発）。デプロイゲーティングが有効になっている場合は必須です。複数の環境を区切るには、コンマ（`,`）を使用します。 |

### Jira Cloudアプリの設定を取得 {#get-gitlab-for-jira-cloud-app-settings}

プロジェクトのJira Cloudアプリの統合設定を取得します。

```plaintext
GET /projects/:id/integrations/jira-cloud-app
```

## GitLab for Slackアプリ {#gitlab-for-slack-app}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### GitLab for Slackアプリの設定 {#set-up-gitlab-for-slack-app}

プロジェクトのSlackアプリの統合を更新します。

統合には、GitLab APIだけでは取得できないOAuth 2.0トークンが必要なため、APIを介してSlackアプリのGitLabを作成することはできません。代わりに、GitLab UIから[アプリをインストールする](../user/project/integrations/gitlab_slack_application.md#install-the-gitlab-for-slack-app)必要があります。次に、このAPIエンドポイントを使用して統合を更新できます。

```plaintext
PUT /projects/:id/integrations/gitlab-slack-application
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `channel` | 文字列 | いいえ | 他のチャンネルが構成されていない場合に使用するデフォルトのチャンネル。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 壊れたパイプラインの通知を送信します。 |
| `notify_only_default_branch` | ブール値 | いいえ | **非推奨**: このパラメータは`branches_to_be_notified`に置き換えられました。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `alert_events` | ブール値 | いいえ | アラートイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密性の高いイシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密性の高いノートイベントの通知を有効にします。 |
| `deployment_events` | ブール値 | いいえ | デプロイイベントの通知を有効にします。 |
| `incidents_events` | ブール値 | いいえ | インシデントイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグ付けプッシュイベントの通知を有効にします。 |
| `vulnerability_events` | ブール値 | いいえ | 脆弱性イベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `labels_to_be_notified` | 文字列 | いいえ | 通知を送信するラベル。設定されていない場合は、すべてのイベントの通知を受信します。 |
| `labels_to_be_notified_behavior` | 文字列 | いいえ | 通知されるラベル。有効なオプションは、`match_any`と`match_all`です。`match_any`がデフォルトです。 |
| `push_channel` | 文字列 | いいえ | プッシュイベントの通知を受信するチャンネルの名前。 |
| `issue_channel` | 文字列 | いいえ | イシューイベントの通知を受信するチャンネルの名前。 |
| `confidential_issue_channel` | 文字列 | いいえ | 機密性の高いイシューイベントの通知を受信するチャンネルの名前。 |
| `merge_request_channel` | 文字列 | いいえ | マージリクエストイベントの通知を受信するチャンネルの名前。 |
| `note_channel` | 文字列 | いいえ | ノートイベントの通知を受信するチャンネルの名前。 |
| `confidential_note_channel` | 文字列 | いいえ | 機密性の高いノートイベントの通知を受信するチャンネルの名前。 |
| `tag_push_channel` | 文字列 | いいえ | タグ付けプッシュイベントの通知を受信するチャンネルの名前。 |
| `pipeline_channel` | 文字列 | いいえ | パイプラインイベントの通知を受信するチャンネルの名前。 |
| `wiki_page_channel` | 文字列 | いいえ | Wikiページイベントの通知を受信するチャンネルの名前。 |
| `deployment_channel` | 文字列 | いいえ | デプロイイベントの通知を受信するチャンネルの名前。 |
| `incident_channel` | 文字列 | いいえ | インシデントイベントの通知を受信するチャンネルの名前。 |
| `vulnerability_channel` | 文字列 | いいえ | 脆弱性イベントの通知を受信するチャンネルの名前。 |
| `alert_channel` | 文字列 | いいえ | アラートイベントの通知を受信するチャンネルの名前。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### GitLab for Slackアプリの場合: {#disable-gitlab-for-slack-app}

プロジェクトのSlackアプリの統合を無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /projects/:id/integrations/gitlab-slack-application
```

### Slackアプリの設定を取得 {#get-gitlab-for-slack-app-settings}

プロジェクトのSlackアプリの統合設定を取得します。

```plaintext
GET /projects/:id/integrations/gitlab-slack-application
```

## Google Chat {#google-chat}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Google Chatをセットアップ {#set-up-google-chat}

プロジェクトのGoogle Chatインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/hangouts-chat
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | HangoutsチャットWebhook（例：`https://chat.googleapis.com/v1/spaces...`）。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 壊れたパイプラインの通知を送信します。 |
| `notify_only_default_branch` | ブール値 | いいえ | **非推奨**: このパラメータは`branches_to_be_notified`に置き換えられました。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密性の高いイシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグ付けプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密性の高いノートイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Google Chatを無効にする {#disable-google-chat}

プロジェクトのGoogle Chatインテグレーションを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /projects/:id/integrations/hangouts-chat
```

### Google Chat設定を取得 {#get-google-chat-settings}

プロジェクトのGoogle Chatインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/hangouts-chat
```

## Google Artifact Management {#google-artifact-management}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/425066) GitLab 16.9で、[ベータ](../policy/development_stages_support.md)機能として、`google_cloud_support_feature_flag`[という名前のフラグ](../administration/feature_flags/_index.md)が付けられました。デフォルトでは無効になっています。
- GitLab 17.1の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472)になりました。機能フラグ`google_cloud_support_feature_flag`は削除されました。
- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

この機能は[ベータ版](../policy/development_stages_support.md)です。

### Google Artifact Managementを設定 {#set-up-google-artifact-management}

プロジェクトのGoogle Artifact Management統合をセットアップします。

```plaintext
PUT /projects/:id/integrations/google-cloud-platform-artifact-registry
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `artifact_registry_project_id` | 文字列 | はい | Google CloudプロジェクトのID。 |
| `artifact_registry_location` | 文字列 | はい | Artifact Registryリポジトリの場所。 |
| `artifact_registry_repositories` | 文字列 | はい | アーティファクトレジストリのリポジトリ。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Google Artifact Managementを無効にする {#disable-google-artifact-management}

プロジェクトのGoogleアーティファクト管理インテグレーションを無効にします。インテグレーション設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/google-cloud-platform-artifact-registry
```

### Googleアーティファクト管理設定の取得 {#get-google-artifact-management-settings}

プロジェクトのGoogleアーティファクト管理インテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/google-cloud-platform-artifact-registry
```

## Google Cloud Identity and Access Management（IAM） {#google-cloud-identity-and-access-management-iam}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 16.10で、[ベータ](../policy/development_stages_support.md)機能として`google_cloud_support_feature_flag`という名前の[フラグ付き](../administration/feature_flags/_index.md)で導入されました。デフォルトでは無効になっています。
- GitLab 17.1の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472)になりました。機能フラグ`google_cloud_support_feature_flag`は削除されました。
- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

この機能は[ベータ版](../policy/development_stages_support.md)です。

### Google Cloud Identity and Access Managementのセットアップ {#set-up-google-cloud-identity-and-access-management}

プロジェクトのGoogle Cloud Identity and Access Managementインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/google-cloud-platform-workload-identity-federation
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `workload_identity_federation_project_id` | 文字列 | はい | ワークロードアイデンティティフェデレーションのGoogle CloudプロジェクトID。 |
| `workload_identity_federation_project_number` | 整数 | はい | ワークロードアイデンティティフェデレーションのGoogle Cloudプロジェクト番号。 |
| `workload_identity_pool_id` | 文字列 | はい | ワークロードIDプールのID。 |
| `workload_identity_pool_provider_id` | 文字列 | はい | ワークロードIDプールプロバイダのID。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Google Cloud Identity and Access Managementを無効にする {#disable-google-cloud-identity-and-access-management}

プロジェクトのGoogle Cloud Identity and Access Managementインテグレーションを無効にします。インテグレーション設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/google-cloud-platform-workload-identity-federation
```

### Google Cloud Identity and Access Managementの取得 {#get-google-cloud-identity-and-access-management}

プロジェクトのGoogle Cloud Identity and Access Managementの設定を取得します。

```plaintext
GET /projects/:id/integration/google-cloud-platform-workload-identity-federation
```

## Google Play {#google-play}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Google Playを設定 {#set-up-google-play}

プロジェクトのGoogle Playインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/google-play
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `package_name` | 文字列 | はい | Google Playでのアプリのパッケージ名。 |
| `service_account_key` | 文字列 | はい | Google Playサービスアカウントキー。 |
| `service_account_key_file_name` | 文字列 | はい | Google Playサービスアカウントキーのファイル名。 |
| `google_play_protected_refs` | ブール値 | いいえ | 保護ブランチとタグでのみ、変数を設定します。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Google Playを無効にする {#disable-google-play}

プロジェクトのGoogle Playインテグレーションを無効にします。インテグレーション設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/google-play
```

### Google Play設定を取得 {#get-google-play-settings}

プロジェクトのGoogle Playインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/google-play
```

## Harbor {#harbor}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Harborを設定 {#set-up-harbor}

プロジェクトのHarborインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/harbor
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `url` | 文字列 | はい | GitLabプロジェクトにリンクされているHarborインスタンスへのベースURL。たとえば`https://demo.goharbor.io`などです。 |
| `project_name` | 文字列 | はい | Harborインスタンスでのプロジェクトの名前。たとえば`testproject`などです。 |
| `username` | 文字列 | はい | Harborインターフェースで作成されたユーザー名。 |
| `password` | 文字列 | はい | ユーザーのパスワード。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Harborを無効にする {#disable-harbor}

プロジェクトのHarborインテグレーションを無効にします。インテグレーション設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/harbor
```

### Harbor設定を取得 {#get-harbor-settings}

プロジェクトのHarborインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/harbor
```

## irker（IRCゲートウェイ） {#irker-irc-gateway}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### irkerを設定 {#set-up-irker}

プロジェクトのirkerインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/irker
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `recipients` | 文字列 | はい | チャンネルまたはメールアドレスのカンマ区切りリスト。 |
| `default_irc_uri` | 文字列 | いいえ | 各受信者の前に追加するURI。デフォルト値は`irc://irc.network.net:6697/`です。 |
| `server_host` | 文字列 | いいえ | irkerデーモンホスト名。デフォルト値は`localhost`です。 |
| `server_port` | 整数 | いいえ | irkerデーモンポート。デフォルト値は`6659`です。 |
| `colorize_messages` | ブール値 | いいえ | メッセージをカラー表示します。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### irkerを無効にする {#disable-irker}

プロジェクトのirkerインテグレーションを無効にします。インテグレーション設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/irker
```

### irker設定を取得 {#get-irker-settings}

プロジェクトのirkerインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/irker
```

## Jenkins {#jenkins}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Jenkinsを設定 {#set-up-jenkins}

プロジェクトのJenkinsインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/jenkins
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `jenkins_url` | 文字列 | はい | JenkinsサーバーのURL。 |
| `enable_ssl_verification` | ブール値 | いいえ | SSL検証を有効にします。デフォルトは`true`（有効）。 |
| `project_name` | 文字列 | はい | Jenkinsプロジェクトの名前。 |
| `username` | 文字列 | いいえ | Jenkinsサーバーのユーザー名。 |
| `password` | 文字列 | いいえ | Jenkinsサーバーのパスワード。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグ付けプッシュイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Jenkinsを無効にする {#disable-jenkins}

プロジェクトのJenkinsインテグレーションを無効にします。インテグレーション設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/jenkins
```

### Jenkins設定を取得 {#get-jenkins-settings}

プロジェクトのJenkinsインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/jenkins
```

## JetBrains TeamCity {#jetbrains-teamcity}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### JetBrains TeamCityを設定 {#set-up-jetbrains-teamcity}

プロジェクトのJetBrains TeamCityインテグレーションをセットアップします。

TeamCityのビルド構成では、ビルド番号形式`%build.vcs.number%`を使用する必要があります。マージリクエストをビルドできるように、VCSルートの詳細設定で、すべてのブランチのモニタリングを構成します。

```plaintext
PUT /projects/:id/integrations/teamcity
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `teamcity_url` | 文字列 | はい | TeamCityルートURL（例：`https://teamcity.example.com`）。 |
| `enable_ssl_verification` | ブール値 | いいえ | SSL検証を有効にします。デフォルトは`true`（有効）。 |
| `build_type` | 文字列 | はい | TeamCityプロジェクトのビルド構成ID。 |
| `username` | 文字列 | はい | 手動ビルドをトリガーする権限を持つユーザー。 |
| `password` | 文字列 | はい | ユーザーのパスワード。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### JetBrains TeamCityを無効にする {#disable-jetbrains-teamcity}

プロジェクトのJetBrains TeamCityインテグレーションを無効にします。インテグレーション設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/teamcity
```

### JetBrains TeamCity設定を取得 {#get-jetbrains-teamcity-settings}

プロジェクトのJetBrains TeamCityインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/teamcity
```

## Jiraイシュー {#jira-issues}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Jiraイシューを設定 {#set-up-jira-issues}

プロジェクトの[Jiraイシューインテグレーション](../integration/jira/configure.md)をセットアップします。

```plaintext
PUT /projects/:id/integrations/jira
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `url`           | 文字列 | はい | このGitLabプロジェクトにリンクされているJiraプロジェクトのURL（例：`https://jira.example.com`）。 |
| `api_url`   | 文字列 | いいえ | JiraインスタンスAPIへのベースURL。Web URLの値は、設定されていない場合に使用されます（例：`https://jira-api.example.com`）。 |
| `username`      | 文字列 | いいえ   | Jiraで使用するメールまたはユーザー名。Jira Cloudにはメールを使用し、Jira Data CenterとJira Serverにはユーザー名を使用します。基本認証（`jira_auth_type`が`0`）を使用する場合は必須。 |
| `password`      | 文字列 | はい  | Jiraで使用するAPIトークン、パスワード、またはパーソナルアクセストークン。基本認証（`jira_auth_type`が`0`）を使用する場合は、Jira CloudにはAPIトークンを使用し、Jira Data CenterまたはJira Serverにはパスワードを使用します。Jiraパーソナルアクセストークン（`jira_auth_type`が`1`）の場合、パーソナルアクセストークンを使用します。 |
| `active`        | ブール値 | いいえ  | インテグレーションをアクティブ化または非アクティブ化します。デフォルトは`false`（非アクティブ化）。 |
| `jira_auth_type`| 整数 | いいえ  | Jiraで使用する認証方式。基本認証には`0`を使用し、Jiraパーソナルアクセストークンには`1`を使用します。`0`がデフォルトです。 |
| `jira_issue_prefix` | 文字列 | いいえ | Jiraイシューキーに一致するプレフィックス。 |
| `jira_issue_regex` | 文字列 | いいえ | Jiraイシューキーに一致する正規表現。 |
| `jira_issue_transition_automatic` | ブール値 | いいえ | イシューの[自動移行](../integration/jira/issues.md#automatic-issue-transitions)を有効にします。有効にした場合、`jira_issue_transition_id`よりも優先されます。`false`がデフォルトです。 |
| `jira_issue_transition_id` | 文字列 | いいえ | [カスタムイシュー移行](../integration/jira/issues.md#custom-issue-transitions)の1つまたは複数のID。`jira_issue_transition_automatic`が有効になっている場合は無視されます。デフォルトは空白の文字列で、カスタム移行が無効になります。 |
| `commit_events` | ブール値 | いいえ | コミットイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `comment_on_event_enabled` | ブール値 | いいえ | 各GitLabイベント（コミットまたはマージリクエスト）で、Jiraイシューのコメントを有効にします。 |
| `issues_enabled` | ブール値 | いいえ | GitLabでJiraイシューの表示を有効にします。GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/267015)されました。 |
| `project_keys` | 文字列の配列 | いいえ | Jiraプロジェクトのキー。`issues_enabled`が`true`の場合、この設定は、GitLabでイシューを表示するJiraプロジェクトを指定します。GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/267015)されました。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |
| `vulnerabilities_enabled` | ブール値 | いいえ | GitLab EEでのみ利用可能です。`true`に設定すると、GitLabの脆弱性に対してJiraイシューが作成されます。|
| `vulnerabilities_issuetype` | 数値 | いいえ | GitLab EEでのみ利用可能です。脆弱性からイシューを作成するときに使用するJiraイシュータイプのID。 |
| `project_key` | 文字列 | いいえ | GitLab EEでのみ利用可能です。脆弱性からイシューを作成するときに使用するプロジェクトのキー。脆弱性からイシューを作成するためにインテグレーションを使用している場合、このパラメータは必須です。 |
| `customize_jira_issue_enabled` | ブール値 | いいえ | GitLab EEでのみ利用可能です。`true`に設定すると、脆弱性からJiraイシューを作成するときに、Jiraインスタンスに事前入力されたフォームが開きます。 |

### Jiraを無効にする {#disable-jira}

プロジェクトのJiraイシューインテグレーションを無効にします。インテグレーション設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/jira
```

### Jira設定を取得 {#get-jira-settings}

プロジェクトのJiraイシューインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/jira
```

## Linear {#linear}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198297)されました。

{{< /history >}}

### Linearを設定 {#set-up-linear}

グループのLinearインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/linear
```

パラメータは以下のとおりです:

| パラメータ     | 型   | 必須 | 説明    |
| ------------- | ------ | -------- | -------------- |
| `workspace_url`  | 文字列 | はい     | イシューのURL。     |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Linearを無効にする {#disable-linear}

グループのLinearインテグレーションを無効にします。インテグレーション設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/linear
```

### Linear設定を取得 {#get-linear-settings}

グループのLinearインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/linear
```

## Matrix通知 {#matrix-notifications}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Matrix通知を設定 {#set-up-matrix-notifications}

プロジェクトのMatrix通知をセットアップします。

```plaintext
PUT /projects/:id/integrations/matrix
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `hostname`   | 文字列 | いいえ | Matrixサーバーのカスタムホスト名。デフォルト値は`https://matrix.org`です。 |
| `token`   | 文字列 | はい | Matrixアクセストークン（例：`syt-zyx57W2v1u123ew11`）。 |
| `room` | 文字列 | はい | ターゲットルームの一意の識別子（`!qPKKM111FFKKsfoCVy:matrix.org`形式）。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 壊れたパイプラインの通知を送信します。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密ノートイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページのイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Matrix通知を無効にする {#disable-matrix-notifications}

プロジェクトのMatrix通知を無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/matrix
```

### Matrix通知の設定を取得 {#get-matrix-notifications-settings}

プロジェクトのMatrix通知の設定を取得します。

```plaintext
GET /projects/:id/integrations/matrix
```

## Mattermostの通知 {#mattermost-notifications}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Mattermostの通知の設定 {#set-up-mattermost-notifications}

プロジェクトのMattermost通知をセットアップします。

```plaintext
PUT /projects/:id/integrations/mattermost
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Mattermost通知Webhook（例：`http://mattermost.example.com/hooks/...`）。 |
| `username` | 文字列 | いいえ | Mattermost通知のユーザー名。 |
| `channel` | 文字列 | いいえ | 他のチャンネルが構成されていない場合に使用するデフォルトチャンネル。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 壊れたパイプラインの通知を送信します。 |
| `notify_only_default_branch` | ブール値 | いいえ | **非推奨**: このパラメータは、`branches_to_be_notified`に置き換えられました。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、`default_and_protected`です。デフォルト値は`default`です。 |
| `labels_to_be_notified` | 文字列 | いいえ | 通知を送信するラベル。すべてのイベントの通知を受信するには、空白のままにします。 |
| `labels_to_be_notified_behavior` | 文字列 | いいえ | 通知を受け取るラベル。有効なオプションは、`match_any`と`match_all`です。デフォルト値は`match_any`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密ノートイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページのイベントの通知を有効にします。 |
| `push_channel` | 文字列 | いいえ | プッシュイベントの通知を受信するチャンネルの名前。 |
| `issue_channel` | 文字列 | いいえ | イシューイベントの通知を受信するチャンネルの名前。 |
| `confidential_issue_channel` | 文字列 | いいえ | 機密イシューイベントの通知を受信するチャンネルの名前。 |
| `merge_request_channel` | 文字列 | いいえ | マージリクエストイベントの通知を受信するチャンネルの名前。 |
| `note_channel` | 文字列 | いいえ | ノートイベントの通知を受信するチャンネルの名前。 |
| `confidential_note_channel` | 文字列 | いいえ | 機密ノートイベントの通知を受信するチャンネルの名前。 |
| `tag_push_channel` | 文字列 | いいえ | タグプッシュイベントの通知を受信するチャンネルの名前。 |
| `pipeline_channel` | 文字列 | いいえ | パイプラインイベントの通知を受信するチャンネルの名前。 |
| `wiki_page_channel` | 文字列 | いいえ | Wikiページのイベントの通知を受信するチャンネルの名前。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Mattermostの通知を無効にします {#disable-mattermost-notifications}

プロジェクトのMattermost通知を無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/mattermost
```

### Mattermost通知の設定を取得 {#get-mattermost-notifications-settings}

プロジェクトのMattermost通知の設定を取得します。

```plaintext
GET /projects/:id/integrations/mattermost
```

## Mattermostのスラッシュコマンド {#mattermost-slash-commands}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Mattermostのスラッシュコマンドを設定 {#set-up-mattermost-slash-commands}

プロジェクトのMattermostスラッシュコマンドをセットアップします。

```plaintext
PUT /projects/:id/integrations/mattermost-slash-commands
```

パラメータは以下のとおりです:

| パラメータ | 型   | 必須 | 説明           |
| --------- | ------ | -------- | --------------------- |
| `token`   | 文字列 | はい      | Mattermostトークン。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Mattermostのスラッシュコマンドを無効にします {#disable-mattermost-slash-commands}

プロジェクトのMattermostスラッシュコマンドを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/mattermost-slash-commands
```

### Mattermostスラッシュコマンドの設定を取得 {#get-mattermost-slash-commands-settings}

プロジェクトのMattermostスラッシュコマンドの設定を取得します。

```plaintext
GET /projects/:id/integrations/mattermost-slash-commands
```

## Microsoft Teamsの通知 {#microsoft-teams-notifications}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Microsoft Teams通知を選択します {#set-up-microsoft-teams-notifications}

プロジェクトのMicrosoft Teams通知をセットアップします。

```plaintext
PUT /projects/:id/integrations/microsoft-teams
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Microsoft Teams Webhook（例：`https://outlook.office.com/webhook/...`）。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 壊れたパイプラインの通知を送信します。 |
| `notify_only_default_branch` | ブール値 | いいえ | **非推奨**: このパラメータは、`branches_to_be_notified`に置き換えられました。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密ノートイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページのイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Microsoft Teams通知を選択します {#disable-microsoft-teams-notifications}

プロジェクトのMicrosoft Teams通知を無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/microsoft-teams
```

### Microsoft Teams通知の設定を取得 {#get-microsoft-teams-notifications-settings}

プロジェクトのMicrosoft Teams通知の設定を取得します。

```plaintext
GET /projects/:id/integrations/microsoft-teams
```

## モックCI {#mock-ci}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

このインテグレーションは、開発環境でのみ使用できます。Mock CIサーバーの例については、[`gitlab-org/gitlab-mock-ci-service`](https://gitlab.com/gitlab-org/gitlab-mock-ci-service)を参照してください。

### Mock CIのセットアップ {#set-up-mock-ci}

プロジェクトのMock CIインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/mock-ci
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `mock_service_url` | 文字列 | はい | Mock CIインテグレーションのURL。 |
| `enable_ssl_verification` | ブール値 | いいえ | SSL検証を有効にします。`true`がデフォルトです（有効）。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Mock CIの無効化 {#disable-mock-ci}

プロジェクトのMock CIインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/mock-ci
```

### Mock CIの設定を取得 {#get-mock-ci-settings}

プロジェクトのMock CIインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/mock-ci
```

## Packagist {#packagist}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Packagistのセットアップ {#set-up-packagist}

プロジェクトのPackagistインテグレーションをセットアップします。

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

### Packagistの無効化 {#disable-packagist}

プロジェクトのPackagistインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/packagist
```

### Packagistの設定を取得 {#get-packagist-settings}

プロジェクトのPackagistインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/packagist
```

## Phorge {#phorge}

{{< history >}}

- GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145863)されました。
- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Phorgeのセットアップ {#set-up-phorge}

プロジェクトのPhorgeインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/phorge
```

パラメータは以下のとおりです:

| パラメータ       | 型   | 必須 | 説明           |
|-----------------|--------|----------|-----------------------|
| `issues_url`    | 文字列 | はい     | イシューのURL。     |
| `project_url`   | 文字列 | はい     | プロジェクトのURL。   |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Phorgeの無効化 {#disable-phorge}

プロジェクトのPhorgeインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/phorge
```

### Phorgeの設定を取得 {#get-phorge-settings}

プロジェクトのPhorgeインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/phorge
```

## パイプラインステータスメール {#pipeline-status-emails}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### パイプラインステータスメールを設定 {#set-up-pipeline-status-emails}

プロジェクトのパイプラインステータスのメールをセットアップします。

```plaintext
PUT /projects/:id/integrations/pipelines-email
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `recipients` | 文字列 | はい | コンマ区切りの受信者のメールアドレスのリスト。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 壊れたパイプラインの通知を送信します。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、`default_and_protected`です。デフォルト値は`default`です。 |
| `notify_only_default_branch` | ブール値 | いいえ | デフォルトブランチの通知を送信します。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### パイプラインステータスのメールを無効にする {#disable-pipeline-status-emails}

プロジェクトのパイプラインステータスのメールを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/pipelines-email
```

### パイプラインステータスのメールの設定を取得 {#get-pipeline-status-emails-settings}

プロジェクトのパイプラインステータスのメールの設定を取得します。

```plaintext
GET /projects/:id/integrations/pipelines-email
```

## Pivotal Tracker {#pivotal-tracker}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Pivotal Trackerのセットアップ {#set-up-pivotal-tracker}

プロジェクトのPivotal Trackerインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/pivotaltracker
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `token` | 文字列 | はい | Pivotal Trackerのトークン。 |
| `restrict_to_branch` | ブール値 | いいえ | 自動的に検査するブランチのコンマ区切りリスト。すべてのブランチを含めるには、空白のままにします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Pivotal Trackerの無効化 {#disable-pivotal-tracker}

プロジェクトのPivotal Trackerインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/pivotaltracker
```

### Pivotal Trackerの設定を取得 {#get-pivotal-tracker-settings}

プロジェクトのPivotal Trackerインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/pivotaltracker
```

## Pumble {#pumble}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Pumbleのセットアップ {#set-up-pumble}

プロジェクトのPumbleインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/pumble
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Pumble Webhook（例：`https://api.pumble.com/workspaces/x/...`）。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、`default_and_protected`です。デフォルトは`default`です。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密ノートイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 壊れたパイプラインの通知を送信します。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグプッシュイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページのイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Pumbleの無効化 {#disable-pumble}

プロジェクトのPumbleインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/pumble
```

### Pumbleの設定を取得 {#get-pumble-settings}

プロジェクトのPumbleインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/pumble
```

## Pushover {#pushover}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Pushoverのセットアップ {#set-up-pushover}

プロジェクトのPushoverインテグレーションをセットアップします。

```plaintext
PUT /projects/:id/integrations/pushover
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `api_key` | 文字列 | はい | アプリケーションキー。 |
| `user_key` | 文字列 | はい | ユーザーキー。 |
| `priority` | 文字列 | はい | 優先度。 |
| `device` | 文字列 | いいえ | すべてのアクティブなデバイスの場合は、空白のままにします。 |
| `sound` | 文字列 | いいえ | 通知のサウンド。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルトの設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Pushoverの無効化 {#disable-pushover}

プロジェクトのPushoverインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/pushover
```

### Pushoverの設定を取得 {#get-pushover-settings}

プロジェクトのPushoverインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/pushover
```

## Redmine {#redmine}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Redmineのセットアップ {#set-up-redmine}

プロジェクトのRedmineインテグレーションをセットアップします。

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

### Redmineの無効化 {#disable-redmine}

プロジェクトのRedmineインテグレーションを無効にします。インテグレーションの設定がリセットされます。

```plaintext
DELETE /projects/:id/integrations/redmine
```

### Redmineの設定を取得 {#get-redmine-settings}

プロジェクトのRedmineインテグレーションの設定を取得します。

```plaintext
GET /projects/:id/integrations/redmine
```

## Slack通知 {#slack-notifications}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Slack通知のセットアップ {#set-up-slack-notifications}

プロジェクトのSlack通知をセットアップします。

```plaintext
PUT /projects/:id/integrations/slack
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Slack通知Webhook（例：`https://hooks.slack.com/services/...`）。 |
| `username` | 文字列 | いいえ | Slack通知のユーザー名。 |
| `channel` | 文字列 | いいえ | 他のチャンネルが構成されていない場合に使用するデフォルトチャンネル。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `notify_only_default_branch` | ブール値 | いいえ | **非推奨**: このパラメータは、`branches_to_be_notified`に置き換えられました。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `labels_to_be_notified` | 文字列 | いいえ | 通知を送信するラベル。すべてのイベントの通知を受信するには、空白のままにします。 |
| `labels_to_be_notified_behavior` | 文字列 | いいえ | 通知を受信するラベル。有効なオプションは、`match_any`および`match_all`です。デフォルト値は`match_any`です。 |
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
| `tag_push_channel` | 文字列 | いいえ | タグ付けプッシュイベントの通知を受信するチャンネルの名前。 |
| `tag_push_events` | ブール値 | いいえ | タグ付けプッシュイベントの通知を有効にします。 |
| `wiki_page_channel` | 文字列 | いいえ | Wikiページのイベントの通知を受信するチャンネルの名前。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページのイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Slack通知を無効にする {#disable-slack-notifications}

プロジェクトのSlack通知を無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /projects/:id/integrations/slack
```

### Slack通知設定を取得 {#get-slack-notifications-settings}

プロジェクトのSlack通知設定を取得します。

```plaintext
GET /projects/:id/integrations/slack
```

## Slackのスラッシュコマンド {#slack-slash-commands}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Slackスラッシュコマンドを設定 {#set-up-slack-slash-commands}

プロジェクトのSlackスラッシュコマンドを設定します。

```plaintext
PUT /projects/:id/integrations/slack-slash-commands
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `token` | 文字列 | はい | Slackトークン。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Slackスラッシュコマンドを無効にする {#disable-slack-slash-commands}

プロジェクトのSlackスラッシュコマンドを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /projects/:id/integrations/slack-slash-commands
```

### Slackスラッシュコマンド設定を取得 {#get-slack-slash-commands-settings}

プロジェクトのSlackスラッシュコマンド設定を取得します。

```plaintext
GET /projects/:id/integrations/slack-slash-commands
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

{{< history >}}

- GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/337855)されました。
- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Squash TMを設定 {#set-up-squash-tm}

プロジェクトのSquash TMインテグレーション設定を設定します。

```plaintext
PUT /projects/:id/integrations/squash-tm
```

パラメータは以下のとおりです:

| パラメータ               | 型   | 必須 | 説明                   |
|-------------------------|--------|----------|-------------------------------|
| `url`                   | 文字列 | はい      | Squash TM WebhookのURL。 |
| `token`                 | 文字列 | いいえ       | シークレットトークン。                 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Squash TMを無効にする {#disable-squash-tm}

プロジェクトのSquash TMインテグレーションを無効にします。インテグレーションの設定は保持されます。

```plaintext
DELETE /projects/:id/integrations/squash-tm
```

### Squash TM設定を取得 {#get-squash-tm-settings}

プロジェクトのSquash TMインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/squash-tm
```

## Telegram {#telegram}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Telegramを設定 {#set-up-telegram}

プロジェクトのTelegramインテグレーションを設定します。

```plaintext
PUT /projects/:id/integrations/telegram
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `hostname`   | 文字列 | いいえ | Telegram APIのカスタムホスト名（GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/461313)）。デフォルト値は`https://api.telegram.org`です。 |
| `token`   | 文字列 | はい | Telegramボットトークン（例：`123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`）。 |
| `room` | 文字列 | はい | ターゲットチャットの固有識別子、またはターゲットチャンネルのユーザー名（`@channelusername`形式）。 |
| `thread` | 整数 | いいえ | ターゲットメッセージスレッドの固有識別子（フォーラムスーパーグループのトピック）。GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/441097)されました。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ（GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134361)）。有効なオプションは、`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | はい | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | はい | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | はい | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | はい | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | はい | タグ付けプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | はい | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | はい | 機密ノートイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | はい | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | はい | Wikiページのイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Telegramを無効にする {#disable-telegram}

プロジェクトのTelegramインテグレーションを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /projects/:id/integrations/telegram
```

### Telegram設定を取得 {#get-telegram-settings}

プロジェクトのTelegramインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/telegram
```

## Unify Circuit {#unify-circuit}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Unify Circuitを設定 {#set-up-unify-circuit}

プロジェクトのUnify Circuitインテグレーションを設定します。

```plaintext
PUT /projects/:id/integrations/unify-circuit
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Unify Circuit Webhook（例：`https://circuit.com/rest/v2/webhooks/incoming/...`）。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグ付けプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密ノートイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページのイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Unify Circuitを無効にする {#disable-unify-circuit}

プロジェクトのUnify Circuitインテグレーションを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /projects/:id/integrations/unify-circuit
```

### Unify Circuit設定を取得 {#get-unify-circuit-settings}

プロジェクトのUnify Circuitインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/unify-circuit
```

## Webex Teams {#webex-teams}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### Webex Teamsを設定 {#set-up-webex-teams}

プロジェクトのWebex Teamsを設定します。

```plaintext
PUT /projects/:id/integrations/webex-teams
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 文字列 | はい | Webex Teams Webhook（例：`https://api.ciscospark.com/v1/webhooks/incoming/...`）。 |
| `notify_only_broken_pipelines` | ブール値 | いいえ | 破損したパイプラインの通知を送信します。 |
| `branches_to_be_notified` | 文字列 | いいえ | 通知を送信するブランチ。有効なオプションは、`all`、`default`、`protected`、および`default_and_protected`です。デフォルト値は`default`です。 |
| `push_events` | ブール値 | いいえ | プッシュイベントの通知を有効にします。 |
| `issues_events` | ブール値 | いいえ | イシューイベントの通知を有効にします。 |
| `confidential_issues_events` | ブール値 | いいえ | 機密イシューイベントの通知を有効にします。 |
| `merge_requests_events` | ブール値 | いいえ | マージリクエストイベントの通知を有効にします。 |
| `tag_push_events` | ブール値 | いいえ | タグ付けプッシュイベントの通知を有効にします。 |
| `note_events` | ブール値 | いいえ | ノートイベントの通知を有効にします。 |
| `confidential_note_events` | ブール値 | いいえ | 機密ノートイベントの通知を有効にします。 |
| `pipeline_events` | ブール値 | いいえ | パイプラインイベントの通知を有効にします。 |
| `wiki_page_events` | ブール値 | いいえ | Wikiページのイベントの通知を有効にします。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### Webex Teamsを無効にする {#disable-webex-teams}

プロジェクトのWebex Teamsを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /projects/:id/integrations/webex-teams
```

### Webex Teams設定を取得 {#get-webex-teams-settings}

プロジェクトのWebex Teams設定を取得します。

```plaintext
GET /projects/:id/integrations/webex-teams
```

## YouTrack {#youtrack}

{{< history >}}

- `use_inherited_settings`パラメータは、GitLab 17.2で`integration_api_inheritance`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)されました。デフォルトでは無効になっています。
- `use_inherited_settings`パラメータは、GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)になりました。機能フラグ`integration_api_inheritance`は削除されました。

{{< /history >}}

### YouTrackを設定 {#set-up-youtrack}

プロジェクトのYouTrackインテグレーションを設定します。

```plaintext
PUT /projects/:id/integrations/youtrack
```

パラメータは以下のとおりです:

| パラメータ | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `issues_url` | 文字列 | はい | イシューのURL。 |
| `project_url` | 文字列 | はい | プロジェクトのURL。 |
| `use_inherited_settings` | ブール値 | いいえ | デフォルト設定を継承するかどうかを示します。`false`がデフォルトです。 |

### YouTrackを無効にする {#disable-youtrack}

プロジェクトのYouTrackインテグレーションを無効にします。インテグレーションの設定はリセットされます。

```plaintext
DELETE /projects/:id/integrations/youtrack
```

### YouTrack設定を取得 {#get-youtrack-settings}

プロジェクトのYouTrackインテグレーション設定を取得します。

```plaintext
GET /projects/:id/integrations/youtrack
```
