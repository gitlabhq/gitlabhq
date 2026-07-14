---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: REST APIを使用してGitLabのインスタンス、グループ、プロジェクトの監査イベントを取得する。
title: 監査イベントAPI
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.9で、[作成者メールがレスポンスボディに追加されました](https://gitlab.com/gitlab-org/gitlab/-/issues/386322)。

{{< /history >}}

## インスタンス監査イベント {#instance-audit-events}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して[インスタンス監査イベント](../administration/compliance/audit_event_reports.md)を取得します。

APIを使用して監査イベントを取得するには、管理者として[認証する](rest/authentication.md)必要があります。

### すべてのインスタンス監査イベントを一覧表示 {#list-all-instance-audit-events}

{{< history >}}

- キーセットページネーションのサポートがGitLab 15.11で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/367528)。
- インスタンス監査イベントのエンティティタイプ`Gitlab::Audit::InstanceScope`がGitLab 16.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/418185)。

{{< /history >}}

利用可能なすべてのインスタンス監査イベントを一覧表示します。各クエリで最大30日間に制限されます。

```plaintext
GET /audit_events
```

| 属性 | 型 | 必須 | 説明                                                                                                     |
| --------- | ---- | -------- |-----------------------------------------------------------------------------------------------------------------|
| `created_after` | 文字列 | いいえ | 指定された日時以降に作成された監査イベントを返します。形式: ISO 8601（`YYYY-MM-DDTHH:MM:SSZ`）               |
| `created_before` | 文字列 | いいえ | 指定された日時以前に作成された監査イベントを返します。形式: ISO 8601（`YYYY-MM-DDTHH:MM:SSZ`）              |
| `entity_type` | 文字列 | いいえ | 指定されたエンティティタイプの監査イベントを返します。有効な値は、`User`、`Group`、`Project`、または`Gitlab::Audit::InstanceScope`です。 |
| `entity_id` | 整数 | いいえ | 指定されたエンティティIDの監査イベントを返します。`entity_type`属性が存在する必要があります。                    |

> [!warning]
> オフセットベースのページネーションはGitLab 17.8で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186194)になり、19.0での削除が予定されています。代わりに[キーセットページネーション](rest/_index.md#keyset-based-pagination)を使用してください。これは破壊的な変更です。

このエンドポイントは、オフセットベースと[キーセットベースの](rest/_index.md#keyset-based-pagination)ページネーションの両方をサポートしています。結果のページを連続してリクエストする場合は、キーセットページネーションを使用する必要があります。

詳細については、[ページネーション](rest/_index.md#pagination)を参照してください。

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/audit_events"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "author_id": 1,
    "entity_id": 6,
    "entity_type": "Project",
    "details": {
      "custom_message": "Project archived",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "target_id": "flightjs/flight",
      "target_type": "Project",
      "target_details": "flightjs/flight",
      "ip_address": "127.0.0.1",
      "entity_path": "flightjs/flight"
    },
    "created_at": "2019-08-30T07:00:41.885Z"
  },
  {
    "id": 2,
    "author_id": 1,
    "entity_id": 60,
    "entity_type": "Group",
    "details": {
      "add": "group",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "target_id": "flightjs",
      "target_type": "Group",
      "target_details": "flightjs",
      "ip_address": "127.0.0.1",
      "entity_path": "flightjs"
    },
    "created_at": "2019-08-27T18:36:44.162Z"
  },
  {
    "id": 3,
    "author_id": 51,
    "entity_id": 51,
    "entity_type": "User",
    "details": {
      "change": "email address",
      "from": "hello@flightjs.com",
      "to": "maintainer@flightjs.com",
      "author_name": "Andreas",
      "author_email": "admin@example.com",
      "target_id": 51,
      "target_type": "User",
      "target_details": "Andreas",
      "ip_address": null,
      "entity_path": "Andreas"
    },
    "created_at": "2019-08-22T16:34:25.639Z"
  },
  {
    "id": 4,
    "author_id": 43,
    "entity_id": 1,
    "entity_type": "Gitlab::Audit::InstanceScope",
    "details": {
      "author_name": "Administrator",
      "author_class": "User",
      "target_id": 32,
      "target_type": "AuditEvents::Streaming::InstanceHeader",
      "target_details": "unknown",
      "custom_message": "Created custom HTTP header with key X-arg.",
      "ip_address": "127.0.0.1",
      "entity_path": "gitlab_instance"
    },
    "ip_address": "127.0.0.1",
    "author_name": "Administrator",
    "entity_path": "gitlab_instance",
    "target_details": "unknown",
    "created_at": "2023-08-01T11:29:44.764Z",
    "target_type": "AuditEvents::Streaming::InstanceHeader",
    "target_id": 32,
    "event_type": "audit_events_streaming_instance_headers_create"
  }
]
```

### インスタンス監査イベントを取得する {#retrieve-an-instance-audit-event}

指定されたインスタンス監査イベントを取得します。

```plaintext
GET /audit_events/:id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数 | はい | 監査イベントのID |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/audit_events/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "author_id": 1,
  "entity_id": 6,
  "entity_type": "Project",
  "details": {
    "custom_message": "Project archived",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "target_id": "flightjs/flight",
    "target_type": "Project",
    "target_details": "flightjs/flight",
    "ip_address": "127.0.0.1",
    "entity_path": "flightjs/flight"
  },
  "created_at": "2019-08-30T07:00:41.885Z"
}
```

## グループ監査イベント {#group-audit-events}

{{< history >}}

- キーセットページネーションのサポートがGitLab 15.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/333968)。

{{< /history >}}

このAPIを使用して[グループ監査イベント](../user/compliance/audit_events.md#group-audit-events)を取得します。

次のユーザーの場合:

- オーナーロールを持つユーザーは、すべてのユーザーのグループ監査イベントを取得できます。
- デベロッパーまたはメンテナーロールを持つユーザーは、個人のアクションに基づいたグループ監査イベントに限定されます。

> [!warning]
> オフセットベースのページネーションはGitLab 17.8で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186194)になり、19.0での削除が予定されています。代わりに[キーセットページネーション](rest/_index.md#keyset-based-pagination)を使用してください。これは破壊的な変更です。

このエンドポイントは、オフセットベースと[キーセットベースの](rest/_index.md#keyset-based-pagination)ページネーションの両方をサポートしています。連続する結果ページをリクエストする場合は、キーセットページネーションが推奨されます。

### すべてのグループ監査イベントを一覧表示 {#list-all-group-audit-events}

{{< history >}}

- キーセットページネーションのサポートがGitLab 15.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/333968)。

{{< /history >}}

指定されたグループのすべての監査イベントを一覧表示します。

```plaintext
GET /groups/:id/audit_events
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `created_after` | 文字列 | いいえ | 指定された日時以降に作成されたグループ監査イベントを返します。形式: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ)`  |
| `created_before` | 文字列 | いいえ | 指定された日時以前に作成されたグループ監査イベントを返します。形式: ISO 8601（`YYYY-MM-DDTHH:MM:SSZ`） |

APIの結果はページネーションされるため、デフォルトでは、`GET`リクエストは一度に20件の結果を返します。

詳細については、[ページネーション](rest/_index.md#pagination)を参照してください。

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/groups/60/audit_events"
```

レスポンス例: 

```json
[
  {
    "id": 2,
    "author_id": 1,
    "entity_id": 60,
    "entity_type": "Group",
    "details": {
      "custom_message": "Group marked for deletion",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "target_id": "flightjs",
      "target_type": "Group",
      "target_details": "flightjs",
      "ip_address": "127.0.0.1",
      "entity_path": "flightjs"
    },
    "created_at": "2019-08-28T19:36:44.162Z"
  },
  {
    "id": 1,
    "author_id": 1,
    "entity_id": 60,
    "entity_type": "Group",
    "details": {
      "add": "group",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "target_id": "flightjs",
      "target_type": "Group",
      "target_details": "flightjs",
      "ip_address": "127.0.0.1",
      "entity_path": "flightjs"
    },
    "created_at": "2019-08-27T18:36:44.162Z"
  }
]
```

### グループ監査イベントを取得する {#retrieve-a-group-audit-event}

指定されたグループの監査イベントを取得します。グループオーナーと管理者のみが使用できます。

```plaintext
GET /groups/:id/audit_events/:audit_event_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `audit_event_id` | 整数 | はい | 監査イベントのID |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/groups/60/audit_events/2"
```

レスポンス例: 

```json
{
  "id": 2,
  "author_id": 1,
  "entity_id": 60,
  "entity_type": "Group",
  "details": {
    "custom_message": "Group marked for deletion",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "target_id": "flightjs",
    "target_type": "Group",
    "target_details": "flightjs",
    "ip_address": "127.0.0.1",
    "entity_path": "flightjs"
  },
  "created_at": "2019-08-28T19:36:44.162Z"
}
```

## プロジェクト監査イベント {#project-audit-events}

このAPIを使用して[プロジェクト監査イベント](../user/compliance/audit_events.md#project-audit-events)を取得します。

メンテナーロール（またはそれ以上）を持つユーザーは、すべてのユーザーのプロジェクト監査イベントを取得できます。デベロッパーロールを持つユーザーは、個人のアクションに基づいたプロジェクト監査イベントに限定されます。

### すべてのプロジェクト監査イベントを一覧表示 {#list-all-project-audit-events}

{{< history >}}

- キーセットページネーションのサポートがGitLab 15.10で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/367528)。

{{< /history >}}

指定されたプロジェクトのすべての監査イベントを一覧表示します。

```plaintext
GET /projects/:id/audit_events
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `created_after` | 文字列 | いいえ | 指定された日時以降に作成されたプロジェクト監査イベントを返します。形式: ISO 8601（`YYYY-MM-DDTHH:MM:SSZ`）  |
| `created_before` | 文字列 | いいえ | 指定された日時以前に作成されたプロジェクト監査イベントを返します。形式: ISO 8601（`YYYY-MM-DDTHH:MM:SSZ`） |

> [!warning]
> オフセットベースのページネーションはGitLab 17.8で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186194)になり、19.0での削除が予定されています。代わりに[キーセットページネーション](rest/_index.md#keyset-based-pagination)を使用してください。これは破壊的な変更です。

APIの結果はページネーションされるため、デフォルトでは、`GET`リクエストは一度に20件の結果を返します。連続する結果ページをリクエストする場合は、[キーセットページネーション](rest/_index.md#keyset-based-pagination)を使用する必要があります。

詳細については、[ページネーション](rest/_index.md#pagination)を参照してください。

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/projects/7/audit_events"
```

レスポンス例: 

```json
[
  {
    "id": 5,
    "author_id": 1,
    "entity_id": 7,
    "entity_type": "Project",
    "details": {
        "change": "prevent merge request approval from committers",
        "from": "",
        "to": "true",
        "author_name": "Administrator",
        "author_email": "admin@example.com",
        "target_id": 7,
        "target_type": "Project",
        "target_details": "twitter/typeahead-js",
        "ip_address": "127.0.0.1",
        "entity_path": "twitter/typeahead-js"
    },
    "created_at": "2020-05-26T22:55:04.230Z"
  },
  {
      "id": 4,
      "author_id": 1,
      "entity_id": 7,
      "entity_type": "Project",
      "details": {
          "change": "prevent merge request approval from authors",
          "from": "false",
          "to": "true",
          "author_name": "Administrator",
          "author_email": "admin@example.com",
          "target_id": 7,
          "target_type": "Project",
          "target_details": "twitter/typeahead-js",
          "ip_address": "127.0.0.1",
          "entity_path": "twitter/typeahead-js"
      },
      "created_at": "2020-05-26T22:55:04.218Z"
  }
]
```

### プロジェクト監査イベントを取得する {#retrieve-a-project-audit-event}

指定されたプロジェクトの監査イベントを取得します。プロジェクトのデベロッパーロール以上のユーザーのみが利用可能です。

```plaintext
GET /projects/:id/audit_events/:audit_event_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `audit_event_id` | 整数 | はい | 監査イベントのID |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/projects/7/audit_events/5"
```

レスポンス例: 

```json
{
  "id": 5,
  "author_id": 1,
  "entity_id": 7,
  "entity_type": "Project",
  "details": {
      "change": "prevent merge request approval from committers",
      "from": "",
      "to": "true",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "target_id": 7,
      "target_type": "Project",
      "target_details": "twitter/typeahead-js",
      "ip_address": "127.0.0.1",
      "entity_path": "twitter/typeahead-js"
  },
  "created_at": "2020-05-26T22:55:04.230Z"
}
```
