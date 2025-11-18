---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: エピックAPI（非推奨）
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

エピックREST APIは、GitLab 17.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/460668)となり、APIのv5で削除される予定です。GitLab 17.4から18.0までのバージョンで、[エピックの新しい外観](../user/group/epics/_index.md#epics-as-work-items)が有効になっている場合は、GitLab 18.1以降で、代わりに作業アイテムAPIを使用してください。詳細については、[作業アイテムにエピックAPIを移行する](graphql/epic_work_items_api_migration_guide.md)を参照してください。これは破壊的な変更です。

{{< /alert >}}

エピックに対するすべてのAPIコールは認証されている必要があります。

ユーザーがプライベートグループのメンバーではない場合、そのグループに対する`GET`リクエストの結果として、`404`ステータスコードが返されます。

エピック機能が利用できない場合、`403`ステータスcodeが返されます。

## 従来のエピックIDとWorkItem ID {#legacy-epic-ids-and-workitem-ids}

従来のエピックIDはWorkItem IDと同じではありません。`iid`のみが一致します。ただし、エピックに対応するWorkItem IDを取得するには、レスポンスに`work_item_id`が含まれています。

このIDはWorkItem GraphQL APIに使用できます。例：`work_item_id`はWorkItem GraphQL APIのグローバルID `gid://gitlab/WorkItem/123`になります。

## エピックイシューAPI {#epic-issues-api}

[エピックイシューAPI](epic_issues.md)を使用すると、エピックに関連付けられたイシューを操作できます。

## マイルストーン日付インテグレーション {#milestone-dates-integration}

開始日と期日は関連するイシューのマイルストーンから動的に取得できるため、ユーザーが編集権限を持っている場合、追加のフィールドが表示されます。これには、2つのブール値フィールド`start_date_is_fixed`と`due_date_is_fixed`、および4つの日付フィールド`start_date_fixed`、`start_date_from_inherited_source`、`due_date_fixed`、`due_date_from_inherited_source`が含まれます。

- `due_date`を優先して、`end_date`は非推奨になりました。
- `start_date_from_inherited_source`を優先して、`start_date_from_milestones`は非推奨になりました。
- `due_date_from_inherited_source`を優先して、`due_date_from_milestones`は非推奨になりました。

## エピックのページネーション {#epics-pagination}

APIの結果はページネーションされるため、デフォルトでは、`GET`リクエストは一度に20件の結果を返します。

詳細については、[ページネーション](rest/_index.md#pagination)を参照してください。

{{< alert type="warning" >}}

[GitLab 12.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20354)以降、レスポンスの`reference`属性は、`references`の代わりに非推奨になりました。

{{< /alert >}}

{{< alert type="note" >}}

`references.relative`は、リクエストされているエピックの祖先グループに対する相対的なものです。エピックがoriginグループからフェッチされる場合、`relative`形式は`short`形式と同じです。エピックがグループ間でリクエストされる場合、`relative`形式は`full`形式と同じになると予想されます。

{{< /alert >}}

## グループのエピックをリスト表示 {#list-epics-for-a-group}

リクエストされたグループとそのサブグループのすべてのエピックを取得します。

```plaintext
GET /groups/:id/epics
GET /groups/:id/epics?author_id=5
GET /groups/:id/epics?labels=bug,reproduced
GET /groups/:id/epics?state=opened
```

| 属性           | 型             | 必須   | 説明                                                                                                                 |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------- |
| `id`                | 整数または文字列   | はい        | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)               |
| `author_id`         | 整数          | いいえ         | 指定されたユーザー`id`によって作成されたエピックを返します                                                                                 |
| `author_username`   | 文字列           | いいえ         | 指定された`username`のユーザーによって作成されたエピックを返します。 |
| `labels`            | 文字列           | いいえ         | カンマ区切りのラベル名と一致するエピックを返します。エピックグループまたは親グループからのラベル名を使用できます |
| `with_labels_details` | ブール値        | いいえ         | `true`の場合、レスポンスではラベルフィールドの各ラベルに関する詳細（`:name`、`:color`、`:description`、`:description_html`、`:text_color`）が返されます。デフォルトは`false`です。 |
| `order_by`          | 文字列           | いいえ         | `created_at`、`updated_at`、または`title`フィールドでソートされたエピックを返します。デフォルトは`created_at`です                              |
| `sort`              | 文字列           | いいえ         | `asc`または`desc`順にソートされたエピックを返します。デフォルトは`desc`です                                                             |
| `search`            | 文字列           | いいえ         | `title`と`description`に対してエピックを検索します                                                                        |
| `state`             | 文字列           | いいえ         | `state`に対してエピックを検索します。可能なフィルター：`opened`、`closed`、および`all`、デフォルト：`all`                          |
| `created_after`     | 日時         | いいえ         | 指定時刻以降に作成されたエピックを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します |
| `created_before`    | 日時         | いいえ         | 指定時刻以前に作成されたエピックを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します |
| `updated_after`     | 日時         | いいえ         | 指定時刻以降に更新されたエピックを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します |
| `updated_before`    | 日時         | いいえ         | 指定時刻以前に更新されたエピックを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します |
| `include_ancestor_groups` | ブール値    | いいえ         | リクエストされたグループの祖先からのエピックを含めます。デフォルトは`false`です                                                      |
| `include_descendant_groups` | ブール値  | いいえ         | リクエストされたグループの子孫からのエピックを含めます。デフォルトは`true`です                                                     |
| `my_reaction_emoji` | 文字列           | いいえ         | 指定された絵文字で認証済みユーザーによってリアクションされたエピックを返します。`None`は、リアクションが付与されていないエピックを返します。`Any`は、少なくとも1つのリアクションが付与されたエピックを返します。 |
| `not` | ハッシュ | いいえ | 指定されたパラメータに一致しないエピックを返します。`author_id`、`author_username`、`labels`を指定できます。 |

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

## 単一のエピック {#single-epic}

単一のエピックを取得します。

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

## 新しいエピック {#new-epic}

新しいエピックを作成します。

{{< alert type="note" >}}

GitLab [11.3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/6448)以降、`start_date`と`end_date`は複合値を表すようになったため、直接割り当てるべきではありません。代わりに、`*_is_fixed`フィールドと`*_fixed`フィールドを使用して設定できます。

{{< /alert >}}

```plaintext
POST /groups/:id/epics
```

| 属性           | 型             | 必須   | 説明                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 整数または文字列   | はい        | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)                |
| `title`             | 文字列           | はい        | エピックのタイトル。 |
| `labels`            | 文字列           | いいえ         | カンマ区切りのラベルのリスト |
| `description`       | 文字列           | いいえ         | エピックの説明。1,048,576文字に制限されています。  |
| `color`             | 文字列           | いいえ         | エピックの色。`epic_highlight_color`というfeature flag（デフォルトでは無効）の背後 |
| `confidential`      | ブール値          | いいえ         | エピックを機密にするかどうか |
| `created_at`        | 文字列           | いいえ         | エピックが作成されたとき。日時文字列（ISO 8601形式）。たとえば`2016-03-11T03:45:40Z`などです。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |
| `start_date_is_fixed` | ブール値        | いいえ         | 開始日を`start_date_fixed`から取得するか、マイルストーンから取得するか |
| `start_date_fixed`  | 文字列           | いいえ         | エピックの固定開始日 |
| `due_date_is_fixed` | ブール値          | いいえ         | 期日を`due_date_fixed`から取得するか、マイルストーンから取得するか |
| `due_date_fixed`    | 文字列           | いいえ         | エピックの固定期日 |
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

## エピックの更新 {#update-epic}

エピックを更新します。

```plaintext
PUT /groups/:id/epics/:epic_iid
```

| 属性           | 型             | 必須   | 説明                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 整数または文字列   | はい        | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)                |
| `epic_iid`          | 整数または文字列   | はい        | エピックの内部ID  |
| `add_labels`        | 文字列           | いいえ         | イシューに追加するラベル名のカンマ区切りリスト。 |
| `confidential`      | ブール値          | いいえ         | エピックを機密にするかどうか |
| `description`       | 文字列           | いいえ         | エピックの説明。1,048,576文字に制限されています。  |
| `due_date_fixed`    | 文字列           | いいえ         | エピックの固定期日 |
| `due_date_is_fixed` | ブール値          | いいえ         | 期日を`due_date_fixed`から取得するか、マイルストーンから取得するか |
| `labels`            | 文字列           | いいえ         | イシューのラベル名のカンマ区切りリスト。すべてのラベルの割り当てを解除するには、空の文字列に設定します。 |
| `parent_id`         | 整数または文字列   | いいえ         | 親エピックのID。 |
| `remove_labels`     | 文字列           | いいえ         | イシューから削除するラベル名のカンマ区切りリスト。 |
| `start_date_fixed`  | 文字列           | いいえ         | エピックの固定開始日 |
| `start_date_is_fixed` | ブール値        | いいえ         | 開始日を`start_date_fixed`から取得するか、マイルストーンから取得するか |
| `state_event`       | 文字列           | いいえ         | エピックのステータスイベント。`close`を設定してエピックを閉じ、`reopen`を設定して再度開きます |
| `title`             | 文字列           | いいえ         | エピックのタイトル |
| `updated_at`        | 文字列           | いいえ         | エピックが更新されたとき。日時文字列（ISO 8601形式）。たとえば`2016-03-11T03:45:40Z`などです。管理者権限またはプロジェクト・グループオーナー権限が必要です。 |
| `color`             | 文字列           | いいえ         | エピックの色。`epic_highlight_color`というfeature flag（デフォルトでは無効）の背後 |

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

## エピックを削除 {#delete-epic}

{{< history >}}

- GitLab 16.11で[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/452189)されました。GitLab 16.10以前では、エピックを削除すると、そのすべての子エピックとその子孫も削除されます。必要に応じて、削除する前に、親エピックから子エピックを削除できます。

{{< /history >}}

エピックを削除します

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

## To Doアイテムを作成する {#create-a-to-do-item}

エピックに関する現在のユーザーのTo-Doアイテムを手動で作成します。そのエピックに関してユーザーのTo-Doアイテムがすでに存在する場合、ステータスコード`304`が返されます。

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
