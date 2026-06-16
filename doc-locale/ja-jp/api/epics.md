---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: エピックAPI（非推奨）
description: 公式のGitLabエピックAPIドキュメントを確認してください。プログラムによってグループ内のエピックを効率的に一覧表示、作成、更新、削除する方法をご確認ください。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

> [!warning]
> エピックREST APIはGitLab 17.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/460668)になり、APIのv5で削除される予定です。GitLab 17.4から18.0までのバージョンで、[エピックの新しい外観](../user/group/epics/_index.md#epics-as-work-items)が有効になっている場合は、GitLab 18.1以降で、代わりに作業アイテムAPIを使用してください。詳細については、[作業アイテムにエピックAPIを移行する](graphql/epic_work_items_api_migration_guide.md)を参照してください。これは破壊的な変更です。

エピックへのすべてのAPIコールは認証する必要があります。

ユーザーがプライベートグループのメンバーでない場合、そのグループへの`GET`リクエストは`404`ステータスコードを返します。

エピック機能が利用できない場合、`403`ステータスコードが返されます。

## 従来のエピックIDとWorkItem ID {#legacy-epic-ids-and-workitem-ids}

従来のエピックIDはWorkItem IDと同じではありません。`iid`のみが一致します。ただし、エピックに対応するWorkItem IDを取得するには、レスポンスに`work_item_id`が含まれます。

このIDはWorkItem GraphQL APIで使用できます。例えば、`work_item_id`はWorkItem GraphQL API上でGlobal ID `gid://gitlab/WorkItem/123`となります。

## エピックイシューAPI {#epic-issues-api}

The [エピックイシューAPI](epic_issues.md)を使用すると、エピックに関連付けられたイシューを操作できます。

## マイルストーン日付インテグレーション {#milestone-dates-integration}

開始日と期日は関連するイシューのマイルストーンから動的に取得できるため、ユーザーが編集権限を持っている場合に限り、追加のフィールドが表示されます。これらには、2つのブール型フィールド`start_date_is_fixed`と`due_date_is_fixed`、および4つの日付フィールド`start_date_fixed`、`start_date_from_inherited_source`、`due_date_fixed`、`due_date_from_inherited_source`が含まれます。

- `due_date`を優先して、`end_date`は非推奨になりました。
- `start_date_from_milestones`は、`start_date_from_inherited_source`に非推奨となりました。
- `due_date_from_milestones`は、`due_date_from_inherited_source`に非推奨となりました。

## すべてのグループエピックを一覧表示 {#list-all-group-epics}

指定されたグループとそのサブグループのすべてのエピックを一覧表示します。

レスポンスは[ページ付けされています](rest/_index.md#pagination)。デフォルトでは20件の結果が返されます。

> [!note]
> `references.relative`は、エピックがリクエストされているグループに対して相対的です。エピックがそのoriginグループからフェッチされる場合、`relative`形式は`short`形式と同じです。エピックが複数のグループにわたってリクエストされる場合、`relative`形式は`full`形式と同じであると想定されます。

```plaintext
GET /groups/:id/epics
GET /groups/:id/epics?author_id=5
GET /groups/:id/epics?labels=bug,reproduced
GET /groups/:id/epics?state=opened
```

| 属性           | 型             | 必須   | 説明                                                                                                                 |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------- |
| `id`                | 整数または文字列   | はい        | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)               |
| `author_id`         | 整数          | いいえ         | 指定されたユーザー`id`によって作成されたエピックを返します。                                                                                 |
| `author_username`   | 文字列           | いいえ         | 指定された`username`を持つユーザーによって作成されたエピックを返します。 |
| `labels`            | 文字列           | いいえ         | コンマ区切りのラベル名リストに一致するエピックを返します。エピックグループまたは親グループのラベル名を使用できます。 |
| `with_labels_details` | ブール値        | いいえ         | `true`の場合、レスポンスではラベルフィールドの各ラベルに関する詳細（`:name`、`:color`、`:description`、`:description_html`、`:text_color`）が返されます。デフォルトは`false`です。 |
| `order_by`          | 文字列           | いいえ         | `created_at`、`updated_at`、または`title`フィールドで並べ替えられたエピックを返します。デフォルトは`created_at`です。                              |
| `sort`              | 文字列           | いいえ         | `asc`または`desc`の順序でソートされたエピックを返します。デフォルトは`desc`です。                                                             |
| `search`            | 文字列           | いいえ         | エピックの`title`と`description`に対して検索します。                                                                        |
| `state`             | 文字列           | いいえ         | エピックの`state`に対して検索します。可能なフィルター: `opened`、`closed`、`all`。デフォルト: `all`                          |
| `created_after`     | 日時         | いいえ         | 指定された時刻以降に作成されたエピックを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `created_before`    | 日時         | いいえ         | 指定された時刻以前に作成されたエピックを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `updated_after`     | 日時         | いいえ         | 指定された時刻以降に更新されたエピックを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `updated_before`    | 日時         | いいえ         | 指定された時刻以前に更新されたエピックを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。 |
| `include_ancestor_groups` | ブール値    | いいえ         | リクエストされたグループの祖先からのエピックを含めます。デフォルトは`false`です。                                                      |
| `include_descendant_groups` | ブール値  | いいえ         | リクエストされたグループの子孫からのエピックを含めます。デフォルトは`true`です。                                                     |
| `my_reaction_emoji` | 文字列           | いいえ         | 認証済みユーザーによって指定された絵文字でリアクションされたエピックを返します。`None`はリアクションが付けられていないエピックを返します。`Any`は少なくとも1つのリアクションが付けられたエピックを返します。 |
| `not` | ハッシュ | いいえ | 指定されたパラメータに一致しないエピックを返します。以下を受け入れます: `author_id`、`author_username`、`labels`。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics"
```

レスポンス例: 

```json
[
  {
  "id": 29,
  "work_item_id": 1032,
  "iid": 4,
  "group_id": 7,
  "parent_id": 23,
  "parent_iid": 3,
  "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "state": "opened",
  "confidential": "false",
  "web_url": "http://gitlab.example.com/groups/test/-/epics/4",
  "reference": "&4",
  "references": {
    "short": "&4",
    "relative": "&4",
    "full": "test&4"
  },
  "author": {
    "id": 10,
    "name": "Lu Mayer",
    "username": "kam",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/kam"
  },
  "start_date": null,
  "start_date_is_fixed": false,
  "start_date_fixed": null,
  "start_date_from_milestones": null,       //deprecated in favor of start_date_from_inherited_source
  "start_date_from_inherited_source": null,
  "end_date": "2018-07-31",                 //deprecated in favor of due_date
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31", //deprecated in favor of start_date_from_inherited_source
  "due_date_from_inherited_source": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "closed_at": "2018-08-18T12:22:05.239Z",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "color": "#1068bf",
  "_links":{
      "self": "http://gitlab.example.com/api/v4/groups/7/epics/4",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/7/epics/4/issues",
      "group":"http://gitlab.example.com/api/v4/groups/7",
      "parent":"http://gitlab.example.com/api/v4/groups/7/epics/3"
  }
  },
  {
  "id": 50,
  "work_item_id": 1035,
  "iid": 35,
  "group_id": 17,
  "parent_id": 19,
  "parent_iid": 1,
  "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "state": "opened",
  "web_url": "http://gitlab.example.com/groups/test/sample/-/epics/35",
  "reference": "&4",
  "references": {
    "short": "&4",
    "relative": "sample&4",
    "full": "test/sample&4"
  },
  "author": {
    "id": 10,
    "name": "Lu Mayer",
    "username": "kam",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/kam"
  },
  "start_date": null,
  "start_date_is_fixed": false,
  "start_date_fixed": null,
  "start_date_from_milestones": null,       //deprecated in favor of start_date_from_inherited_source
  "start_date_from_inherited_source": null,
  "end_date": "2018-07-31",                 //deprecated in favor of due_date
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31", //deprecated in favor of start_date_from_inherited_source
  "due_date_from_inherited_source": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "closed_at": "2018-08-18T12:22:05.239Z",
  "imported": false,
  "imported_from": "none",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "color": "#1068bf",
  "_links":{
      "self": "http://gitlab.example.com/api/v4/groups/17/epics/35",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/17/epics/35/issues",
      "group":"http://gitlab.example.com/api/v4/groups/17",
      "parent":"http://gitlab.example.com/api/v4/groups/17/epics/1"
  }
  }
]
```

## エピックを取得する {#retrieve-an-epic}

指定されたグループのエピックを取得する。

```plaintext
GET /groups/:id/epics/:epic_iid
```

| 属性           | 型             | 必須   | 説明                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 整数または文字列   | はい        | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)                |
| `epic_iid`          | 整数または文字列   | はい        | エピックの内部ID。  |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5"
```

レスポンス例: 

```json
{
  "id": 30,
  "work_item_id": 1099,
  "iid": 5,
  "group_id": 7,
  "parent_id": null,
  "parent_iid": null,
  "title": "Ea cupiditate dolores ut vero consequatur quasi veniam voluptatem et non.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "state": "opened",
  "imported": false,
  "imported_from": "none",
  "web_url": "http://gitlab.example.com/groups/test/-/epics/5",
  "reference": "&5",
  "references": {
    "short": "&5",
    "relative": "&5",
    "full": "test&5"
  },
  "author":{
    "id": 7,
    "name": "Pamella Huel",
    "username": "arnita",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/arnita"
  },
  "start_date": null,
  "start_date_is_fixed": false,
  "start_date_fixed": null,
  "start_date_from_milestones": null,       //deprecated in favor of start_date_from_inherited_source
  "start_date_from_inherited_source": null,
  "end_date": "2018-07-31",                 //deprecated in favor of due_date
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31", //deprecated in favor of start_date_from_inherited_source
  "due_date_from_inherited_source": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "closed_at": "2018-08-18T12:22:05.239Z",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "color": "#1068bf",
  "subscribed": true,
  "_links":{
      "self": "http://gitlab.example.com/api/v4/groups/7/epics/5",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/7/epics/5/issues",
      "group":"http://gitlab.example.com/api/v4/groups/7",
      "parent": null
  }
}
```

## エピックを作成する {#create-an-epic}

指定されたグループにエピックを作成します。

> [!note]
> GitLab [11.3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/6448)以降、`start_date`と`end_date`は複合値を表すようになったため、直接割り当てるべきではありません。代わりに`*_is_fixed`と`*_fixed`フィールドを介して設定できます。

```plaintext
POST /groups/:id/epics
```

| 属性           | 型             | 必須   | 説明                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 整数または文字列   | はい        | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)                |
| `title`             | 文字列           | はい        | エピックのタイトル |
| `labels`            | 文字列           | いいえ         | コンマ区切りのラベルリスト |
| `description`       | 文字列           | いいえ         | エピックの説明。1,048,576文字に制限されています。  |
| `color`             | 文字列           | いいえ         | エピックの色。`epic_highlight_color`という機能フラグの背後にあります（デフォルトで無効）。 |
| `confidential`      | ブール値          | いいえ         | そのエピックが機密であるべきかどうか |
| `created_at`        | 文字列           | いいえ         | エピックが作成された日時。日付時刻文字列、ISO 8601形式。例: `2016-03-11T03:45:40Z`。管理者またはプロジェクト/グループオーナーの権限が必要です。 |
| `start_date_is_fixed` | ブール値        | いいえ         | 開始日が`start_date_fixed`から取得されるべきか、またはマイルストーンから取得されるべきか。 |
| `start_date_fixed`  | 文字列           | いいえ         | エピックの固定開始日。 |
| `due_date_is_fixed` | ブール値          | いいえ         | 期日が`due_date_fixed`から取得されるべきか、またはマイルストーンから取得されるべきか。 |
| `due_date_fixed`    | 文字列           | いいえ         | エピックの固定期日。 |
| `parent_id`         | 整数または文字列   | いいえ         | 親エピックのID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics?title=Epic&description=Epic%20description&parent_id=29"
```

レスポンス例: 

```json
{
  "id": 33,
  "work_item_id": 1020,
  "iid": 6,
  "group_id": 7,
  "parent_id": 29,
  "parent_iid": 4,
  "title": "Epic",
  "description": "Epic description",
  "state": "opened",
  "imported": false,
  "imported_from": "none",
  "confidential": "false",
  "web_url": "http://gitlab.example.com/groups/test/-/epics/6",
  "reference": "&6",
  "references": {
    "short": "&6",
    "relative": "&6",
    "full": "test&6"
  },
  "author": {
    "name" : "Alexandra Bashirian",
    "avatar_url" : null,
    "state" : "active",
    "web_url" : "https://gitlab.example.com/eileen.lowe",
    "id" : 18,
    "username" : "eileen.lowe"
  },
  "start_date": null,
  "start_date_is_fixed": false,
  "start_date_fixed": null,
  "start_date_from_milestones": null,       //deprecated in favor of start_date_from_inherited_source
  "start_date_from_inherited_source": null,
  "end_date": "2018-07-31",                 //deprecated in favor of due_date
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31", //deprecated in favor of start_date_from_inherited_source
  "due_date_from_inherited_source": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "closed_at": "2018-08-18T12:22:05.239Z",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "color": "#1068bf",
  "_links":{
    "self": "http://gitlab.example.com/api/v4/groups/7/epics/6",
    "epic_issues": "http://gitlab.example.com/api/v4/groups/7/epics/6/issues",
    "group":"http://gitlab.example.com/api/v4/groups/7",
    "parent": "http://gitlab.example.com/api/v4/groups/7/epics/4"
  }
}
```

## エピックを更新する {#update-an-epic}

指定されたグループのエピックを更新します。

```plaintext
PUT /groups/:id/epics/:epic_iid
```

| 属性           | 型             | 必須   | 説明                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 整数または文字列   | はい        | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)                |
| `epic_iid`          | 整数または文字列   | はい        | エピックの内部ID  |
| `add_labels`        | 文字列           | いいえ         | イシューに追加するラベル名のカンマ区切りリスト。 |
| `confidential`      | ブール値          | いいえ         | そのエピックが機密であるべきかどうか |
| `description`       | 文字列           | いいえ         | エピックの説明。1,048,576文字に制限されています。  |
| `due_date_fixed`    | 文字列           | いいえ         | エピックの固定期日。 |
| `due_date_is_fixed` | ブール値          | いいえ         | 期日が`due_date_fixed`から取得されるべきか、またはマイルストーンから取得されるべきか。 |
| `labels`            | 文字列           | いいえ         | イシューのラベル名のカンマ区切りリスト。すべてのラベルの割り当てを解除するには、空の文字列を設定します。 |
| `parent_id`         | 整数または文字列   | いいえ         | 親エピックのID。 |
| `remove_labels`     | 文字列           | いいえ         | イシューから削除するラベル名のカンマ区切りリスト。 |
| `start_date_fixed`  | 文字列           | いいえ         | エピックの固定開始日。 |
| `start_date_is_fixed` | ブール値        | いいえ         | 開始日が`start_date_fixed`から取得されるべきか、またはマイルストーンから取得されるべきか。 |
| `state_event`       | 文字列           | いいえ         | エピックのステートイベント。`close`を設定してエピックをクローズし、`reopen`を設定して再オープンします。 |
| `title`             | 文字列           | いいえ         | エピックのタイトル |
| `updated_at`        | 文字列           | いいえ         | エピックが更新された日時。日付時刻文字列、ISO 8601形式。例: `2016-03-11T03:45:40Z`。管理者またはプロジェクト/グループオーナーの権限が必要です。 |
| `color`             | 文字列           | いいえ         | エピックの色。`epic_highlight_color`という機能フラグの背後にあります（デフォルトで無効）。 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5?title=New%20Title&parent_id=29"
```

レスポンス例: 

```json
{
  "id": 33,
  "work_item_id": 1019,
  "iid": 6,
  "group_id": 7,
  "parent_id": 29,
  "parent_iid": 4,
  "title": "New Title",
  "description": "Epic description",
  "state": "opened",
  "imported": false,
  "imported_from": "none",
  "confidential": "false",
  "web_url": "http://gitlab.example.com/groups/test/-/epics/6",
  "reference": "&6",
  "references": {
    "short": "&6",
    "relative": "&6",
    "full": "test&6"
  },
  "author": {
    "name" : "Alexandra Bashirian",
    "avatar_url" : null,
    "state" : "active",
    "web_url" : "https://gitlab.example.com/eileen.lowe",
    "id" : 18,
    "username" : "eileen.lowe"
  },
  "start_date": null,
  "start_date_is_fixed": false,
  "start_date_fixed": null,
  "start_date_from_milestones": null,       //deprecated in favor of start_date_from_inherited_source
  "start_date_from_inherited_source": null,
  "end_date": "2018-07-31",                 //deprecated in favor of due_date
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31", //deprecated in favor of start_date_from_inherited_source
  "due_date_from_inherited_source": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "closed_at": "2018-08-18T12:22:05.239Z",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "color": "#1068bf"
}
```

## エピックを削除する {#delete-an-epic}

{{< history >}}

- GitLab 16.11で[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/452189)されました。GitLab 16.10以前では、エピックを削除すると、そのすべての子エピックとその子孫も削除されます。必要に応じて、親エピックを削除する前に、子エピックを親エピックから削除できます。

{{< /history >}}

指定されたグループからエピックを削除します。

```plaintext
DELETE /groups/:id/epics/:epic_iid
```

| 属性           | 型             | 必須   | 説明                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 整数または文字列   | はい        | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)                |
| `epic_iid`          | 整数または文字列   | はい        | エピックの内部ID。  |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5"
```

## エピックのTo-Doアイテムを作成する {#create-a-to-do-item-for-an-epic}

指定されたエピックで現在のユーザーのTo-Doアイテムを作成します。そのエピックでユーザーのTo-Doアイテムがすでに存在する場合、ステータスコード304が返されます。

```plaintext
POST /groups/:id/epics/:epic_iid/todo
```

| 属性   | 型    | 必須 | 説明                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | 整数または文字列 | はい   | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)  |
| `epic_iid` | 整数 | はい          | グループのエピックの内部ID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/todo"
```

レスポンス例: 

```json
{
  "id": 112,
  "group": {
    "id": 1,
    "name": "Gitlab",
    "path": "gitlab",
    "kind": "group",
    "full_path": "base/gitlab",
    "parent_id": null
  },
  "author": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/root"
  },
  "action_name": "marked",
  "target_type": "epic",
  "target": {
    "id": 30,
    "iid": 5,
    "group_id": 1,
    "title": "Ea cupiditate dolores ut vero consequatur quasi veniam voluptatem et non.",
    "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
    "author":{
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/arnita"
    },
    "web_url": "http://gitlab.example.com/groups/test/-/epics/5",
    "reference": "&5",
    "references": {
      "short": "&5",
      "relative": "&5",
      "full": "test&5"
    },
    "start_date": null,
    "end_date": null,
    "created_at": "2018-01-21T06:21:13.165Z",
    "updated_at": "2018-01-22T12:41:41.166Z",
    "closed_at": "2018-08-18T12:22:05.239Z"
  },
  "target_url": "https://gitlab.example.com/groups/epics/5",
  "body": "Vel voluptas atque dicta mollitia adipisci qui at.",
  "state": "pending",
  "created_at": "2016-07-01T11:09:13.992Z"
}
```
