---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: エピックリンクAPI
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

エピックREST APIは、GitLab 17.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/460668)となり、APIのv5で削除される予定です。GitLab 17.4から18.0までのバージョンで、[エピックの新しい外観](../user/group/epics/_index.md#epics-as-work-items)が有効になっている場合は、GitLab 18.1以降で、代わりに作業アイテムAPIを使用してください。詳細については、[作業アイテムにエピックAPIを移行する](graphql/epic_work_items_api_migration_guide.md)を参照してください。これは破壊的な変更です。

{{< /alert >}}

親と子エピックの[エピック関係](../user/group/epics/manage_epics.md#multi-level-child-epics)を管理します。

APIコールに対するすべての`epic_links`は、認証されている必要があります。

ユーザーがプライベートグループのメンバーではない場合、そのグループに対する`GET`リクエストの結果は、`404`ステータスコードになります。

複数レベルのエピックは、[GitLab Ultimate](https://about.gitlab.com/pricing/)でのみ使用できます。複数レベルのエピック機能が利用できない場合、`403`ステータスコードが返されます。

## 特定のエピックに関連付けられたエピックを一覧表示する {#list-epics-related-to-a-given-epic}

エピックのすべての子エピックを取得します。

```plaintext
GET /groups/:id/epics/:epic_iid/epics
```

| 属性  | 型           | 必須 | 説明                                                                                                   |
| ---------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------- |
| `id`       | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `epic_iid` | 整数        | はい      | エピックの内部ID                                                                                  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/epics"
```

レスポンス例:

```json
[
  {
    "id": 29,
    "iid": 6,
    "group_id": 1,
    "parent_id": 5,
    "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
    "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
    "author": {
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
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
    "labels": []
  }
]
```

## 子エピックを割り当てる {#assign-a-child-epic}

2つのエピック間の関連付けを作成し、一方を親エピック、もう一方を子エピックとして指定します。親エピックは、複数の子エピックを持つことができます。新しい子エピックがすでに別のエピックに属している場合、その以前の親から割り当て解除されます。

```plaintext
POST /groups/:id/epics/:epic_iid/epics/:child_epic_id
```

| 属性       | 型           | 必須 | 説明                                                                                                        |
| --------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------ |
| `id`            | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)      |
| `epic_iid`      | 整数        | はい      | エピックの内部ID                                                                                       |
| `child_epic_id` | 整数        | はい      | 子エピックのグローバルID。内部IDは、他のグループのエピックと競合する可能性があるため、使用できません。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/epics/6"

```

レスポンス例:

```json
{
  "id": 6,
  "iid": 38,
  "group_id": 1,
  "parent_id": 5,
  "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "author": {
    "id": 10,
    "name": "Lu Mayer",
    "username": "kam",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
    "web_url": "http://localhost:3001/kam"
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
  "labels": []
}
```

## 子エピックを作成して割り当てる {#create-and-assign-a-child-epic}

新しいエピックを作成し、指定された親エピックに関連付けます。応答はLinkedEpicオブジェクトです。

```plaintext
POST /groups/:id/epics/:epic_iid/epics
```

| 属性       | 型           | 必須 | 説明                                                                                                        |
| --------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------ |
| `id`            | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)      |
| `epic_iid`      | 整数        | はい      | （将来の親）エピックの内部ID。                                                                       |
| `title`         | 文字列         | はい      | 新しく作成されたエピックのタイトル。                                                                                 |
| `confidential`  | ブール値        | いいえ       | エピックを機密にするかどうか。`confidential_epics`機能フラグが無効になっている場合、パラメータは無視されます。親エピックの機密状態にデフォルト設定されます。  |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/epics?title=Newpic"
```

レスポンス例:

```json
{
  "id": 24,
  "iid": 2,
  "title": "child epic",
  "group_id": 49,
  "parent_id": 23,
  "has_children": false,
  "has_issues": false,
  "reference":  "&2",
  "url": "http://localhost/groups/group16/-/epics/2",
  "relation_url": "http://localhost/groups/group16/-/epics/1/links/24"
}
```

## 子エピックの順序を変更する {#re-order-a-child-epic}

```plaintext
PUT /groups/:id/epics/:epic_iid/epics/:child_epic_id
```

| 属性        | 型           | 必須 | 説明                                                                                                        |
| ---------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------ |
| `id`             | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。     |
| `epic_iid`       | 整数        | はい      | エピックの内部ID                                                                                       |
| `child_epic_id`  | 整数        | はい      | 子エピックのグローバルID。内部IDは、他のグループのエピックと競合する可能性があるため、使用できません。 |
| `move_before_id` | 整数        | いいえ       | 子エピックの前に配置する必要がある兄弟エピックのグローバルID。                                       |
| `move_after_id`  | 整数        | いいえ       | 子エピックの後に配置する必要がある兄弟エピックのグローバルID。                                        |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/4/epics/5"
```

レスポンス例:

```json
[
  {
    "id": 29,
    "iid": 6,
    "group_id": 1,
    "parent_id": 5,
    "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
    "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
    "author": {
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
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
    "labels": []
  }
]
```

## 子エピックの割り当てを解除する {#unassign-a-child-epic}

親エピックから子エピックの割り当てを解除します。

```plaintext
DELETE /groups/:id/epics/:epic_iid/epics/:child_epic_id
```

| 属性       | 型           | 必須 | 説明                                                                                                        |
| --------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------ |
| `id`            | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。     |
| `epic_iid`      | 整数        | はい      | エピックの内部ID                                                                                       |
| `child_epic_id` | 整数        | はい      | 子エピックのグローバルID。内部IDは、他のグループのエピックと競合する可能性があるため、使用できません。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/4/epics/5"
```

レスポンス例:

```json
{
  "id": 5,
  "iid": 38,
  "group_id": 1,
  "parent_id": null,
  "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "author": {
    "id": 10,
    "name": "Lu Mayer",
    "username": "kam",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
    "web_url": "http://localhost:3001/kam"
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
  "labels": []
}
```
