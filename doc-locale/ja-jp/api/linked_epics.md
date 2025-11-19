---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: リンクされたエピック 
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 14.9で`related_epics_widget`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/352493)されました。デフォルトでは有効になっています。
- GitLab 15.0で[機能フラグ`related_epics_widget`](https://gitlab.com/gitlab-org/gitlab/-/issues/357089)が削除されました。

{{< /history >}}

{{< alert type="warning" >}}

エピックREST APIは、GitLab 17.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/460668)となり、APIのv5で削除される予定です。GitLab 17.4から18.0までのバージョンで、[エピックの新しい外観](../user/group/epics/_index.md#epics-as-work-items)が有効になっている場合は、GitLab 18.1以降で、代わりに作業アイテムAPIを使用してください。詳細については、[作業アイテムにエピックAPIを移行する](graphql/epic_work_items_api_migration_guide.md)を参照してください。これは破壊的な変更です。

{{< /alert >}}

リンクされたエピック機能がGitLabプランで利用できない場合、`403`のステータスコードが返されます。

## グループからリンクされたエピックリンクをリスト表示 {#list-related-epic-links-from-a-group}

指定されたグループのリンクされたエピックリンクのリストを、グループ内およびサブグループ内で、ユーザー認可に従ってフィルタリングして取得します。関連するリンクされたエピックリンクにアクセスするには、ユーザーが`source_epic`と`target_epic`にアクセスできる必要があります。

```plaintext
GET /groups/:id/related_epic_links
```

サポートされている属性は以下のとおりです:

| 属性  | 型           | 必須               | 説明                                                               |
| ---------- | -------------- | ---------------------- | ------------------------------------------------------------------------- |
| `id`       | 整数または文字列 | はい | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |
| `created_after` | 文字列 | いいえ | 指定された時刻以降に作成されたリンクされたエピックリンクを返します。形式: ISO 8601（`YYYY-MM-DDTHH:MM:SSZ`）  |
| `created_before` | 文字列 | いいえ | 指定された時刻以前に作成されたリンクされたエピックリンクを返します。形式: ISO 8601（`YYYY-MM-DDTHH:MM:SSZ`） |
| `updated_after` | 文字列 | いいえ | 指定された時刻以降に更新されたリンクされたエピックリンクを返します。形式: ISO 8601（`YYYY-MM-DDTHH:MM:SSZ`）  |
| `updated_before` | 文字列 | いいえ | 指定された時刻以前に更新されたリンクされたエピックリンクを返します。形式: ISO 8601（`YYYY-MM-DDTHH:MM:SSZ`） |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/related_epic_links"
```

レスポンス例:

```json
[
  {
    "id": 1,
    "created_at": "2022-01-31T15:10:44.988Z",
    "updated_at": "2022-01-31T15:10:44.988Z",
    "link_type": "relates_to",
    "source_epic": {
      "id": 21,
      "iid": 1,
      "color": "#1068bf",
      "text_color": "#FFFFFF",
      "group_id": 26,
      "parent_id": null,
      "parent_iid": null,
      "title": "Aspernatur recusandae distinctio omnis et qui est iste.",
      "description": "some description",
      "confidential": false,
      "author": {
        "id": 15,
        "username": "trina",
        "name": "Theresia Robel",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/085e28df717e16484cbf6ceca75e9a93?s=80&d=identicon",
        "web_url": "http://gitlab.example.com/trina"
      },
      "start_date": null,
      "end_date": null,
      "due_date": null,
      "state": "opened",
      "web_url": "http://gitlab.example.com/groups/flightjs/-/epics/1",
      "references": {
        "short": "&1",
        "relative": "&1",
        "full": "flightjs&1"
      },
      "created_at": "2022-01-31T15:10:44.988Z",
      "updated_at": "2022-03-16T09:32:35.712Z",
      "closed_at": null,
      "labels": [],
      "upvotes": 0,
      "downvotes": 0,
      "_links": {
        "self": "http://gitlab.example.com/api/v4/groups/26/epics/1",
        "epic_issues": "http://gitlab.example.com/api/v4/groups/26/epics/1/issues",
        "group": "http://gitlab.example.com/api/v4/groups/26",
        "parent": null
      }
    },
    "target_epic": {
      "id": 25,
      "iid": 5,
      "color": "#1068bf",
      "text_color": "#FFFFFF",
      "group_id": 26,
      "parent_id": null,
      "parent_iid": null,
      "title": "Aut assumenda id nihil distinctio fugiat vel numquam est.",
      "description": "some description",
      "confidential": false,
      "author": {
        "id": 3,
        "username": "valerie",
        "name": "Erika Wolf",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/9ef7666abb101418a4716a8ed4dded80?s=80&d=identicon",
        "web_url": "http://gitlab.example.com/valerie"
      },
      "start_date": null,
      "end_date": null,
      "due_date": null,
      "state": "opened",
      "web_url": "http://gitlab.example.com/groups/flightjs/-/epics/5",
      "references": {
        "short": "&5",
        "relative": "&5",
        "full": "flightjs&5"
      },
      "created_at": "2022-01-31T15:10:45.080Z",
      "updated_at": "2022-03-16T09:32:35.842Z",
      "closed_at": null,
      "labels": [],
      "upvotes": 0,
      "downvotes": 0,
      "_links": {
        "self": "http://gitlab.example.com/api/v4/groups/26/epics/5",
        "epic_issues": "http://gitlab.example.com/api/v4/groups/26/epics/5/issues",
        "group": "http://gitlab.example.com/api/v4/groups/26",
        "parent": null
      }
    },
  }
]
```

## エピックからリンクされたエピックをリスト表示 {#list-linked-epics-from-an-epic}

指定されたエピックのリンクされたエピックのリストを、ユーザー認可に従ってフィルタリングして取得します。

```plaintext
GET /groups/:id/epics/:epic_iid/related_epics
```

サポートされている属性は以下のとおりです:

| 属性  | 型           | 必須               | 説明                                                               |
| ---------- | -------------- | ---------------------- | ------------------------------------------------------------------------- |
| `epic_iid` | 整数        | はい | グループのエピックの内部ID                                             |
| `id`       | 整数または文字列 | はい | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |

リクエスト例:

```shell
curl --request GET \
 --header "PRIVATE-TOKEN: <your_access_token>" \
 --url "https://gitlab.example.com/api/v4/groups/:id/epics/:epic_iid/related_epics"
```

レスポンス例:

```json
[
   {
      "id":2,
      "iid":2,
      "color":"#1068bf",
      "text_color":"#FFFFFF",
      "group_id":2,
      "parent_id":null,
      "parent_iid":null,
      "title":"My title 2",
      "description":null,
      "confidential":false,
      "author":{
         "id":3,
         "username":"user3",
         "name":"Sidney Jones4",
         "state":"active",
         "avatar_url":"https://www.gravatar.com/avatar/82797019f038ab535a84c6591e7bc936?s=80u0026d=identicon",
         "web_url":"http://localhost/user3"
      },
      "start_date":null,
      "end_date":null,
      "due_date":null,
      "state":"opened",
      "web_url":"http://localhost/groups/group1/-/epics/2",
      "references":{
         "short":"u00262",
         "relative":"u00262",
         "full":"group1u00262"
      },
      "created_at":"2022-03-10T18:35:24.479Z",
      "updated_at":"2022-03-10T18:35:24.479Z",
      "closed_at":null,
      "labels":[

      ],
      "upvotes":0,
      "downvotes":0,
      "_links":{
         "self":"http://localhost/api/v4/groups/2/epics/2",
         "epic_issues":"http://localhost/api/v4/groups/2/epics/2/issues",
         "group":"http://localhost/api/v4/groups/2",
         "parent":null
      },
      "related_epic_link_id":1,
      "link_type":"relates_to",
      "link_created_at":"2022-03-10T18:35:24.496+00:00",
      "link_updated_at":"2022-03-10T18:35:24.496+00:00"
   }
]
```

## リンクされたエピックリンクを作成 {#create-a-related-epic-link}

{{< history >}}

- GitLab 15.8で、グループに必要な最小ロールがレポーターからゲストに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/381308)されました。

{{< /history >}}

2つのエピック間の双方向の関係を作成します。ユーザーは両方のグループに対して少なくともゲストロールを持っている必要があります。

```plaintext
POST /groups/:id/epics/:epic_iid/related_epics
```

サポートされている属性は以下のとおりです:

| 属性           | 型           | 必須                    | 説明                           |
|---------------------|----------------|-----------------------------|---------------------------------------|
| `epic_iid`          | 整数        | はい      | グループのエピックの内部ID。        |
| `id`                | 整数または文字列 | はい      | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |
| `target_epic_iid`   | 整数または文字列 | はい      | 対象グループのエピックの内部ID。 |
| `target_group_id`   | 整数または文字列 | はい      | ターゲットグループのまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `link_type`         | 文字列         | いいえ      | 関係のタイプ（`relates_to`、`blocks`、`is_blocked_by`）は、`relates_to`がデフォルトです。 |

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/26/epics/1/related_epics?target_group_id=26&target_epic_iid=5"
```

レスポンス例:

```json
{
  "id": 1,
  "created_at": "2022-01-31T15:10:44.988Z",
  "updated_at": "2022-01-31T15:10:44.988Z",
  "link_type": "relates_to",
  "source_epic": {
    "id": 21,
    "iid": 1,
    "color": "#1068bf",
    "text_color": "#FFFFFF",
    "group_id": 26,
    "parent_id": null,
    "parent_iid": null,
    "title": "Aspernatur recusandae distinctio omnis et qui est iste.",
    "description": "some description",
    "confidential": false,
    "author": {
      "id": 15,
      "username": "trina",
      "name": "Theresia Robel",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/085e28df717e16484cbf6ceca75e9a93?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/trina"
    },
    "start_date": null,
    "end_date": null,
    "due_date": null,
    "state": "opened",
    "web_url": "http://gitlab.example.com/groups/flightjs/-/epics/1",
    "references": {
      "short": "&1",
      "relative": "&1",
      "full": "flightjs&1"
    },
    "created_at": "2022-01-31T15:10:44.988Z",
    "updated_at": "2022-03-16T09:32:35.712Z",
    "closed_at": null,
    "labels": [],
    "upvotes": 0,
    "downvotes": 0,
    "_links": {
      "self": "http://gitlab.example.com/api/v4/groups/26/epics/1",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/26/epics/1/issues",
      "group": "http://gitlab.example.com/api/v4/groups/26",
      "parent": null
    }
  },
  "target_epic": {
    "id": 25,
    "iid": 5,
    "color": "#1068bf",
    "text_color": "#FFFFFF",
    "group_id": 26,
    "parent_id": null,
    "parent_iid": null,
    "title": "Aut assumenda id nihil distinctio fugiat vel numquam est.",
    "description": "some description",
    "confidential": false,
    "author": {
      "id": 3,
      "username": "valerie",
      "name": "Erika Wolf",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/9ef7666abb101418a4716a8ed4dded80?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/valerie"
    },
    "start_date": null,
    "end_date": null,
    "due_date": null,
    "state": "opened",
    "web_url": "http://gitlab.example.com/groups/flightjs/-/epics/5",
    "references": {
      "short": "&5",
      "relative": "&5",
      "full": "flightjs&5"
    },
    "created_at": "2022-01-31T15:10:45.080Z",
    "updated_at": "2022-03-16T09:32:35.842Z",
    "closed_at": null,
    "labels": [],
    "upvotes": 0,
    "downvotes": 0,
    "_links": {
      "self": "http://gitlab.example.com/api/v4/groups/26/epics/5",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/26/epics/5/issues",
      "group": "http://gitlab.example.com/api/v4/groups/26",
      "parent": null
    }
  },
}
```

## リンクされたエピックリンクを削除 {#delete-a-related-epic-link}

{{< history >}}

- GitLab 15.8で、グループに必要な最小ロールがレポーターからゲストに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/381308)されました。

{{< /history >}}

2つのエピック間の双方向の関係を削除します。ユーザーは両方のグループに対して少なくともゲストロールを持っている必要があります。

```plaintext
DELETE /groups/:id/epics/:epic_iid/related_epics/:related_epic_link_id
```

サポートされている属性は以下のとおりです:

| 属性                | 型           | 必須                    | 説明                           |
|--------------------------|----------------|-----------------------------|---------------------------------------|
| `epic_iid`               | 整数        | はい      | グループのエピックの内部ID。        |
| `id`                     | 整数または文字列 | はい      | IDまたは[URLエンコードされた](rest/_index.md#namespaced-paths)パス。 |
| `related_epic_link_id`   | 整数または文字列 | はい      | リンクされたエピックリンクの内部ID。 |

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/26/epics/1/related_epics/1"
```

レスポンス例:

```json
{
  "id": 1,
  "created_at": "2022-01-31T15:10:44.988Z",
  "updated_at": "2022-01-31T15:10:44.988Z",
  "link_type": "relates_to",
  "source_epic": {
    "id": 21,
    "iid": 1,
    "color": "#1068bf",
    "text_color": "#FFFFFF",
    "group_id": 26,
    "parent_id": null,
    "parent_iid": null,
    "title": "Aspernatur recusandae distinctio omnis et qui est iste.",
    "description": "some description",
    "confidential": false,
    "author": {
      "id": 15,
      "username": "trina",
      "name": "Theresia Robel",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/085e28df717e16484cbf6ceca75e9a93?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/trina"
    },
    "start_date": null,
    "end_date": null,
    "due_date": null,
    "state": "opened",
    "web_url": "http://gitlab.example.com/groups/flightjs/-/epics/1",
    "references": {
      "short": "&1",
      "relative": "&1",
      "full": "flightjs&1"
    },
    "created_at": "2022-01-31T15:10:44.988Z",
    "updated_at": "2022-03-16T09:32:35.712Z",
    "closed_at": null,
    "labels": [],
    "upvotes": 0,
    "downvotes": 0,
    "_links": {
      "self": "http://gitlab.example.com/api/v4/groups/26/epics/1",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/26/epics/1/issues",
      "group": "http://gitlab.example.com/api/v4/groups/26",
      "parent": null
    }
  },
  "target_epic": {
    "id": 25,
    "iid": 5,
    "color": "#1068bf",
    "text_color": "#FFFFFF",
    "group_id": 26,
    "parent_id": null,
    "parent_iid": null,
    "title": "Aut assumenda id nihil distinctio fugiat vel numquam est.",
    "description": "some description",
    "confidential": false,
    "author": {
      "id": 3,
      "username": "valerie",
      "name": "Erika Wolf",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/9ef7666abb101418a4716a8ed4dded80?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/valerie"
    },
    "start_date": null,
    "end_date": null,
    "due_date": null,
    "state": "opened",
    "web_url": "http://gitlab.example.com/groups/flightjs/-/epics/5",
    "references": {
      "short": "&5",
      "relative": "&5",
      "full": "flightjs&5"
    },
    "created_at": "2022-01-31T15:10:45.080Z",
    "updated_at": "2022-03-16T09:32:35.842Z",
    "closed_at": null,
    "labels": [],
    "upvotes": 0,
    "downvotes": 0,
    "_links": {
      "self": "http://gitlab.example.com/api/v4/groups/26/epics/5",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/26/epics/5/issues",
      "group": "http://gitlab.example.com/api/v4/groups/26",
      "parent": null
    }
  },
}
```
