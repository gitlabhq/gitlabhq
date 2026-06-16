---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 機能フラグAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このAPIは、GitLabの開発で使用されるFlipperベースの機能フラグを管理するためのものです。

すべてのメソッドには管理者の認可が必要です。

このAPIは、booleanとpercentage-of-timeゲート値のみをサポートしていることに注意してください。

## すべての機能フラグをリストする {#list-all-feature-flags}

永続化されたすべての機能フラグと、そのゲート値を一覧表示します。

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

## すべての機能フラグ定義をリストする {#list-all-feature-flag-definitions}

すべての機能フラグ定義を一覧表示します。

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

## 機能フラグを作成または更新する {#create-or-update-a-feature-flag}

機能フラグのゲート値を作成または更新します。指定された名前の機能フラグがまだ存在しない場合、それは作成されます。値はboolean、または時間のパーセンテージを示す整数にすることができます。

> [!warning]
> 開発中の機能を有効にする前に、[セキュリティと安定性のリスク](../administration/feature_flags/_index.md#risks-when-enabling-features-still-in-development)を理解しておく必要があります。

```plaintext
POST /features/:name
```

| 属性       | 型           | 必須 | 説明                                                                                                                                                                                      |
|-----------------|----------------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `name`          | 文字列         | はい      | 作成または更新する機能フラグの名前                                                                                                                                                          |
| `value`         | 整数または文字列 | はい      | `true`または`false`で有効/無効を設定するか、時間の割合を示す整数                                                                                                                        |
| `key`           | 文字列         | いいえ       | `percentage_of_actors`または`percentage_of_time` （デフォルト）                                                                                                                                         |
| `feature_group` | 文字列         | いいえ       | 機能フラググループ名                                                                                                                                                                             |
| `user`          | 文字列         | いいえ       | GitLabのユーザー名、またはカンマ区切りの複数のユーザー名                                                                                                                                          |
| `group`         | 文字列         | いいえ       | GitLabグループのパス。例: `gitlab-org`、またはカンマ区切りの複数のグループパス                                                                                                         |
| `namespace`     | 文字列         | いいえ       | GitLabグループまたはユーザーネームスペースのパス。例: `john-doe`、またはカンマ区切りの複数のネームスペースパス。GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/353117)されました。 |
| `project`       | 文字列         | いいえ       | プロジェクトパス。例: `gitlab-org/gitlab-foss`、またはカンマ区切りの複数のプロジェクトパス                                                                                                 |
| `repository`    | 文字列         | いいえ       | リポジトリパス。例: `gitlab-org/gitlab-test.git`、`gitlab-org/gitlab-test.wiki.git`、`snippets/21.git`など。複数のリポジトリパスはカンマで区切ります              |
| `runner`        | 文字列         | いいえ       | Runner ID、またはカンマ区切りの複数のRunner ID                                                                                                                                               |
| `force`         | ブール値        | いいえ       | YAML定義などの機能フラグ検証チェックをスキップします                                                                                                                                   |

単一のAPIコールで、`feature_group`、`user`、`group`、`namespace`、`project`、`repository`、`runner`の機能を有効または無効にできます。

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

### アクターのロールアウトの割合を設定する {#set-percentage-of-actors-rollout}

アクターのパーセンテージへのロールアウト。

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

## 機能を削除する {#delete-a-feature}

機能フラグゲートを削除します。機能フラグが存在するかどうかにかかわらず、同じレスポンスを返します。

```plaintext
DELETE /features/:name
```
