---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 機能フラグAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab Premium 12.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/9566)されました。
- 13.5でGitLab Freeに[移行](https://gitlab.com/gitlab-org/gitlab/-/issues/212318)しました。

{{< /history >}}

このAPIを使用して、GitLabの[機能フラグ](../operations/feature_flags.md)を操作します。

前提要件: 

- デベロッパーロール以上が必要です。

## プロジェクトの機能フラグを一覧表示します {#list-feature-flags-for-a-project}

リクエストされたプロジェクトのすべての機能フラグを取得します。

```plaintext
GET /projects/:id/feature_flags
```

結果のページネーションを制御するには、`page`および`per_page` [ページネーション](rest/_index.md#offset-based-pagination)パラメータを使用します。

| 属性           | 型             | 必須   | 説明                                                                                                                 |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------- |
| `id`                | 整数または文字列   | はい        | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。                                            |
| `scope`             | 文字列           | いいえ         | 機能フラグの状態（`enabled`、`disabled`のいずれか）。                                                              |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/feature_flags"
```

レスポンス例:

```json
[
   {
      "name":"merge_train",
      "description":"This feature is about merge train",
      "active": true,
      "version": "new_version_flag",
      "created_at":"2019-11-04T08:13:51.423Z",
      "updated_at":"2019-11-04T08:13:51.423Z",
      "scopes":[],
      "strategies": [
        {
          "id": 1,
          "name": "userWithId",
          "parameters": {
            "userIds": "user1"
          },
          "scopes": [
            {
              "id": 1,
              "environment_scope": "production"
            }
          ],
          "user_list": null
        }
      ]
   },
   {
      "name":"new_live_trace",
      "description":"This is a new live trace feature",
      "active": true,
      "version": "new_version_flag",
      "created_at":"2019-11-04T08:13:10.507Z",
      "updated_at":"2019-11-04T08:13:10.507Z",
      "scopes":[],
      "strategies": [
        {
          "id": 2,
          "name": "default",
          "parameters": {},
          "scopes": [
            {
              "id": 2,
              "environment_scope": "staging"
            }
          ],
          "user_list": null
        }
      ]
   },
   {
      "name":"user_list",
      "description":"This feature is about user list",
      "active": true,
      "version": "new_version_flag",
      "created_at":"2019-11-04T08:13:10.507Z",
      "updated_at":"2019-11-04T08:13:10.507Z",
      "scopes":[],
      "strategies": [
        {
          "id": 2,
          "name": "gitlabUserList",
          "parameters": {},
          "scopes": [
            {
              "id": 2,
              "environment_scope": "staging"
            }
          ],
          "user_list": {
            "id": 1,
            "iid": 1,
            "name": "My user list",
            "user_xids": "user1,user2,user3"
          }
        }
      ]
   }
]
```

## 単一の機能フラグを取得します {#get-a-single-feature-flag}

単一の機能フラグを取得します。

```plaintext
GET /projects/:id/feature_flags/:feature_flag_name
```

結果のページネーションを制御するには、`page`および`per_page` [ページネーション](rest/_index.md#offset-based-pagination)パラメータを使用します。

| 属性           | 型             | 必須   | 説明                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 整数または文字列   | はい        | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。       |
| `feature_flag_name` | 文字列           | はい        | 機能フラグの名前。                                                          |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/feature_flags/awesome_feature"
```

レスポンス例:

```json
{
  "name": "awesome_feature",
  "description": null,
  "active": true,
  "version": "new_version_flag",
  "created_at": "2020-05-13T19:56:33.119Z",
  "updated_at": "2020-05-13T19:56:33.119Z",
  "scopes": [],
  "strategies": [
    {
      "id": 36,
      "name": "default",
      "parameters": {},
      "scopes": [
        {
          "id": 37,
          "environment_scope": "production"
        }
      ],
      "user_list": null
    }
  ]
}
```

## 機能フラグを作成する {#create-a-feature-flag}

新しい機能フラグを作成します。

```plaintext
POST /projects/:id/feature_flags
```

| 属性           | 型             | 必須   | 説明                                                                                                                                                                                                                                                                              |
| ------------------- | ---------------- | ---------- |------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`                | 整数または文字列   | はい        | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。                                                                                                                                                                                                     |
| `name`              | 文字列           | はい        | 機能フラグの名前。                                                                                                                                                                                                                                                            |
| `version`           | 文字列           | はい        | **非推奨**機能フラグのバージョン。`new_version_flag`である必要があります。レガシー機能フラグを作成するには、省略します。                                                                                                                                                                        |
| `description`       | 文字列           | いいえ         | 機能フラグの説明。                                                                                                                                                                                                                                                     |
| `active`            | ブール値          | いいえ         | フラグのアクティブな状態。デフォルトはtrueです。                                                                                                                                                                                                                                          |
| `strategies`        | 戦略JSONオブジェクトの配列 | いいえ         | 機能フラグの[戦略](../operations/feature_flags.md#feature-flag-strategies)。                                                                                                                                                                                     |
| `strategies:name`   | JSON             | いいえ         | 戦略名。`default`、`gradualRolloutUserId`、`userWithId`、または`gitlabUserList`を指定できます。[GitLab 13.5](https://gitlab.com/gitlab-org/gitlab/-/issues/36380)以降では、[`flexibleRollout`](https://docs.getunleash.io/user_guide/activation_strategy/#gradual-rollout)を指定できます。 |
| `strategies:parameters` | JSON         | いいえ         | 戦略パラメータ。                                                                                                                                                                                                                                                                 |
| `strategies:scopes` | JSON             | いいえ         | 戦略のスコープ。                                                                                                                                                                                                                                                             |
| `strategies:scopes:environment_scope` | 文字列 | いいえ | スコープの環境スコープ。                                                                                                                                                                                                                                                      |
| `strategies:user_list_id` | 整数または文字列 | いいえ     | 機能フラグユーザーリストのID。戦略が`gitlabUserList`の場合。                                                                                                                                                                                                                   |

```shell
curl "https://gitlab.example.com/api/v4/projects/1/feature_flags" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-type: application/json" \
     --data @- << EOF
{
  "name": "awesome_feature",
  "version": "new_version_flag",
  "strategies": [{ "name": "default", "parameters": {}, "scopes": [{ "environment_scope": "production" }] }]
}
EOF
```

レスポンス例:

```json
{
  "name": "awesome_feature",
  "description": null,
  "active": true,
  "version": "new_version_flag",
  "created_at": "2020-05-13T19:56:33.119Z",
  "updated_at": "2020-05-13T19:56:33.119Z",
  "scopes": [],
  "strategies": [
    {
      "id": 36,
      "name": "default",
      "parameters": {},
      "scopes": [
        {
          "id": 37,
          "environment_scope": "production"
        }
      ]
    }
  ]
}
```

## 機能フラグを更新する {#update-a-feature-flag}

機能フラグを更新します。

```plaintext
PUT /projects/:id/feature_flags/:feature_flag_name
```

| 属性           | 型             | 必須   | 説明                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 整数または文字列   | はい        | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。   |
| `feature_flag_name` | 文字列           | はい        | 機能フラグの現在の名前。                                                  |
| `description`       | 文字列           | いいえ         | 機能フラグの説明。                                                   |
| `active`            | ブール値          | いいえ         | フラグのアクティブな状態。                                                          |
| `name`              | 文字列           | いいえ         | 機能フラグの新しい名前。                                                      |
| `strategies`        | 戦略JSONオブジェクトの配列 | いいえ         | 機能フラグの[戦略](../operations/feature_flags.md#feature-flag-strategies)。 |
| `strategies:id`     | JSON             | いいえ         | 機能フラグ戦略ID。                                                          |
| `strategies:name`   | JSON             | いいえ         | 戦略名。                                                                     |
| `strategies:_destroy` | ブール値         | いいえ         | trueの場合、戦略を削除します。                                                        |
| `strategies:parameters` | JSON         | いいえ         | 戦略パラメータ。                                                               |
| `strategies:scopes` | JSON             | いいえ         | 戦略のスコープ。                                                           |
| `strategies:scopes:id` | JSON          | いいえ         | 環境スコープID。                                                              |
| `strategies:scopes:environment_scope` | 文字列 | いいえ | スコープの環境スコープ。                                                    |
| `strategies:scopes:_destroy` | ブール値 | いいえ | trueの場合、スコープを削除します。                                                                    |
| `strategies:user_list_id` | 整数または文字列 | いいえ     | 機能フラグユーザーリストのID。戦略が`gitlabUserList`の場合。                 |

```shell
curl "https://gitlab.example.com/api/v4/projects/1/feature_flags/awesome_feature" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-type: application/json" \
     --data @- << EOF
{
  "strategies": [{ "name": "gradualRolloutUserId", "parameters": { "groupId": "default", "percentage": "25" }, "scopes": [{ "environment_scope": "staging" }] }]
}
EOF
```

レスポンス例:

```json
{
  "name": "awesome_feature",
  "description": null,
  "active": true,
  "version": "new_version_flag",
  "created_at": "2020-05-13T20:10:32.891Z",
  "updated_at": "2020-05-13T20:10:32.891Z",
  "scopes": [],
  "strategies": [
    {
      "id": 38,
      "name": "gradualRolloutUserId",
      "parameters": {
        "groupId": "default",
        "percentage": "25"
      },
      "scopes": [
        {
          "id": 40,
          "environment_scope": "staging"
        }
      ]
    },
    {
      "id": 37,
      "name": "default",
      "parameters": {},
      "scopes": [
        {
          "id": 39,
          "environment_scope": "production"
        }
      ]
    }
  ]
}
```

## 機能フラグを削除する {#delete-a-feature-flag}

機能フラグを削除します。

```plaintext
DELETE /projects/:id/feature_flags/:feature_flag_name
```

| 属性           | 型             | 必須   | 説明                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | 整数または文字列   | はい        | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。       |
| `feature_flag_name` | 文字列           | はい        | 機能フラグの名前。                                                          |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --request DELETE "https://gitlab.example.com/api/v4/projects/1/feature_flags/awesome_feature"
```
