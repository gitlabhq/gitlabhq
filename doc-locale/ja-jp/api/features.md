---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 機能フラグAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このAPIは、GitLabの開発で使用されるFlipperベースの機能フラグを管理するためのものです。

すべてのメソッドで管理者認可が必要です。

このAPIは、ブール値と時間ゲートの割合の値のみをサポートしていることに注意してください。

## すべての機能をリスト表示 {#list-all-features}

すべての永続化された機能のリストを、そのゲートの値とともに取得します。

```plaintext
GET /features
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/features"
```

レスポンス例:

```json
[
  {
    "name": "experimental_feature",
    "state": "off",
    "gates": [
      {
        "key": "boolean",
        "value": false
      }
    ],
    "definition": null
  },
  {
    "name": "my_user_feature",
    "state": "on",
    "gates": [
      {
        "key": "percentage_of_actors",
        "value": 34
      }
    ],
    "definition": {
      "name": "my_user_feature",
      "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40880",
      "rollout_issue_url": "https://gitlab.com/gitlab-org/gitlab/-/issues/244905",
      "group": "group::ci",
      "type": "development",
      "default_enabled": false
    }
  },
  {
    "name": "new_library",
    "state": "on",
    "gates": [
      {
        "key": "boolean",
        "value": true
      }
    ],
    "definition": null
  }
]
```

## すべての機能定義をリスト表示 {#list-all-feature-definitions}

すべての機能定義のリストを取得します。

```plaintext
GET /features/definitions
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/features/definitions"
```

レスポンス例:

```json
[
  {
    "name": "geo_pages_deployment_replication",
    "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/68662",
    "rollout_issue_url": "https://gitlab.com/gitlab-org/gitlab/-/issues/337676",
    "milestone": "14.3",
    "log_state_changes": null,
    "type": "development",
    "group": "group::geo",
    "default_enabled": true
  }
]
```

## 機能を設定または作成 {#set-or-create-a-feature}

機能のゲート値を設定します。指定された名前の機能がまだ存在しない場合は、作成されます。値は、ブール値、または時間の割合を示す整数にすることができます。

{{< alert type="warning" >}}

開発中の機能を有効にする前に、[セキュリティと安定性のリスク](../administration/feature_flags/_index.md#risks-when-enabling-features-still-in-development)を理解しておく必要があります。

{{< /alert >}}

```plaintext
POST /features/:name
```

| 属性       | 型           | 必須 | 説明                                                                                                                                                                                      |
|-----------------|----------------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `name`          | 文字列         | はい      | 作成または更新する機能の名前                                                                                                                                                          |
| `value`         | 整数または文字列 | はい      | 有効/無効にする場合は`true`または`false`、時間の割合を示す場合は整数                                                                                                                        |
| `key`           | 文字列         | いいえ       | `percentage_of_actors`または`percentage_of_time`（デフォルト）。                                                                                                                                         |
| `feature_group` | 文字列         | いいえ       | 機能グループ名                                                                                                                                                                             |
| `user`          | 文字列         | いいえ       | GitLabのユーザー名、またはカンマで区切られた複数のユーザー名                                                                                                                                          |
| `group`         | 文字列         | いいえ       | GitLabグループのパス（例: `gitlab-org`）、またはカンマで区切られた複数のグループパス                                                                                                         |
| `namespace`     | 文字列         | いいえ       | GitLabのグループまたはユーザーネームスペースのパス（例: `john-doe`）、またはカンマで区切られた複数のネームスペースパス。GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/353117)されました。 |
| `project`       | 文字列         | いいえ       | プロジェクトのパス（例: `gitlab-org/gitlab-foss`）、またはカンマで区切られた複数のプロジェクトパス                                                                                                 |
| `repository`    | 文字列         | いいえ       | リポジトリのパス（例: `gitlab-org/gitlab-test.git`、`gitlab-org/gitlab-test.wiki.git`、`snippets/21.git`など）。カンマを使用して、複数のリポジトリパスを区切ります              |
| `force`         | ブール値        | いいえ       | YAML定義などの機能フラグ検証チェックをスキップします                                                                                                                                   |

1回のAPIコールで、`feature_group`、`user`、`group`、`namespace`、`project`、および`repository`の機能を有効または無効にできます。

```shell
curl --request POST \
  --data "value=30" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/features/new_library"
```

レスポンス例:

```json
{
  "name": "new_library",
  "state": "conditional",
  "gates": [
    {
      "key": "boolean",
      "value": false
    },
    {
      "key": "percentage_of_time",
      "value": 30
    }
  ],
  "definition": {
    "name": "my_user_feature",
    "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40880",
    "rollout_issue_url": "https://gitlab.com/gitlab-org/gitlab/-/issues/244905",
    "group": "group::ci",
    "type": "development",
    "default_enabled": false
  }
}
```

### アクターロールアウトの割合を設定 {#set-percentage-of-actors-rollout}

アクターの割合へのロールアウト。

```plaintext
POST https://gitlab.example.com/api/v4/features/my_user_feature?private_token=<your_access_token>
Content-Type: application/x-www-form-urlencoded
value=42&key=percentage_of_actors&
```

レスポンス例:

```json
{
  "name": "my_user_feature",
  "state": "conditional",
  "gates": [
    {
      "key": "boolean",
      "value": false
    },
    {
      "key": "percentage_of_actors",
      "value": 42
    }
  ],
  "definition": {
    "name": "my_user_feature",
    "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40880",
    "rollout_issue_url": "https://gitlab.com/gitlab-org/gitlab/-/issues/244905",
    "group": "group::ci",
    "type": "development",
    "default_enabled": false
  }
}
```

`my_user_feature`をアクターの`42%`にロールアウトします。

## 機能を削除 {#delete-a-feature}

機能ゲートを削除します。ゲートが存在する場合と存在しない場合で、応答は同じです。

```plaintext
DELETE /features/:name
```
