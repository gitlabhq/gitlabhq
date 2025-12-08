---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 機能フラグユーザーリストAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/205409)されたのは、[GitLab Premium](https://about.gitlab.com/pricing/) 12.10です。
- [移行](https://gitlab.com/gitlab-org/gitlab/-/issues/212318)したのは13.5のGitLab Freeです。

{{< /history >}}

このAPIを使用して、GitLabの機能フラグの[ユーザーリスト](../operations/feature_flags.md#user-list)を操作します。

前提要件: 

- デベロッパーロール以上が必要です。

{{< alert type="note" >}}

すべてのユーザーの機能フラグを操作するには、[Feature flag API](feature_flags.md)を参照してください。

{{< /alert >}}

## プロジェクトのすべての機能フラグユーザーリストをリスト表示します {#list-all-feature-flag-user-lists-for-a-project}

リクエストされたプロジェクトのすべての機能フラグユーザーリストを取得します。

```plaintext
GET /projects/:id/feature_flags_user_lists
```

結果のページネーションを制御するには、`page`および`per_page` [ページネーション](rest/_index.md#offset-based-pagination)パラメータを使用します。

| 属性 | 型           | 必須 | 説明                                                                      |
| --------- | -------------- | -------- | -------------------------------------------------------------------------------- |
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `search`  | 文字列         | いいえ       | 検索条件に一致するユーザーリストを返します。                                  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists"
```

レスポンス例:

```json
[
   {
      "name": "user_list",
      "user_xids": "user1,user2",
      "id": 1,
      "iid": 1,
      "project_id": 1,
      "created_at": "2020-02-04T08:13:51.423Z",
      "updated_at": "2020-02-04T08:13:51.423Z"
   },
   {
      "name": "test_users",
      "user_xids": "user3,user4,user5",
      "id": 2,
      "iid": 2,
      "project_id": 1,
      "created_at": "2020-02-04T08:13:10.507Z",
      "updated_at": "2020-02-04T08:13:10.507Z"
   }
]
```

## 機能フラグユーザーリストを作成します {#create-a-feature-flag-user-list}

機能フラグユーザーリストを作成します。

```plaintext
POST /projects/:id/feature_flags_user_lists
```

| 属性           | 型             | 必須   | 説明                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 整数または文字列   | はい        | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。       |
| `name`              | 文字列           | はい        | リストの名前。 |
| `user_xids`         | 文字列           | はい        | 外部ユーザーIDのカンマ区切りリスト。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists" \
  --data @- << EOF
{
    "name": "my_user_list",
    "user_xids": "user1,user2,user3"
}
EOF
```

レスポンス例:

```json
{
   "name": "my_user_list",
   "user_xids": "user1,user2,user3",
   "id": 1,
   "iid": 1,
   "project_id": 1,
   "created_at": "2020-02-04T08:32:27.288Z",
   "updated_at": "2020-02-04T08:32:27.288Z"
}
```

## 機能フラグのユーザーリストを取得 {#get-a-feature-flag-user-list}

機能フラグユーザーリストを取得します。

```plaintext
GET /projects/:id/feature_flags_user_lists/:iid
```

結果のページネーションを制御するには、`page`および`per_page` [ページネーション](rest/_index.md#offset-based-pagination)パラメータを使用します。

| 属性           | 型             | 必須   | 説明                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 整数または文字列   | はい        | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。       |
| `iid`               | 整数または文字列   | はい        | プロジェクトの機能フラグユーザーリストの内部ID。                               |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists/1"
```

レスポンス例:

```json
{
   "name": "my_user_list",
   "user_xids": "123,456",
   "id": 1,
   "iid": 1,
   "project_id": 1,
   "created_at": "2020-02-04T08:13:10.507Z",
   "updated_at": "2020-02-04T08:13:10.507Z"
}
```

## 機能フラグユーザーリストを更新します {#update-a-feature-flag-user-list}

機能フラグユーザーリストを更新します。

```plaintext
PUT /projects/:id/feature_flags_user_lists/:iid
```

| 属性           | 型             | 必須   | 説明                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 整数または文字列   | はい        | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。       |
| `iid`               | 整数または文字列   | はい        | プロジェクトの機能フラグユーザーリストの内部ID。                               |
| `name`              | 文字列           | いいえ         | リストの名前。                                                          |
| `user_xids`         | 文字列           | いいえ         | 外部ユーザーIDのカンマ区切りリスト。                                                    |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists/1" \
  --data @- << EOF
{
    "user_xids": "user2,user3,user4"
}
EOF
```

レスポンス例:

```json
{
   "name": "my_user_list",
   "user_xids": "user2,user3,user4",
   "id": 1,
   "iid": 1,
   "project_id": 1,
   "created_at": "2020-02-04T08:32:27.288Z",
   "updated_at": "2020-02-05T09:33:17.179Z"
}
```

## 機能フラグユーザーリストを削除します {#delete-feature-flag-user-list}

機能フラグユーザーリストを削除します。

```plaintext
DELETE /projects/:id/feature_flags_user_lists/:iid
```

| 属性           | 型             | 必須   | 説明                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 整数または文字列   | はい        | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。       |
| `iid`               | 整数または文字列   | はい        | プロジェクトの機能フラグユーザーリストの内部ID                                |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/feature_flags_user_lists/1"
```
