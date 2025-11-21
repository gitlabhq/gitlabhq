---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ネームスペースAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 課金関連フィールドの表示レベルは、`restrict_namespace_api_billing_fields`という[フラグ](../administration/feature_flags/_index.md)でGitLab 18.3で変更されました。デフォルトでは無効になっています。

{{< /history >}}

このAPIは、ユーザーとグループの編成に使用される特別なリソースカテゴリであるネームスペースを操作するために使用します。詳細については、[namespaces](../user/namespace/_index.md)を参照してください。

このAPIは、[ページネーション](rest/_index.md#pagination)を使用して結果をフィルタリングします。

## すべてのネームスペースをリスト表示 {#list-all-namespaces}

{{< history >}}

- `top_level_only`[導入](https://gitlab.com/gitlab-org/customers-gitlab-com/-/issues/7600) GitLab 16.8。

{{< /history >}}

現在のユーザーが利用できるすべてのネームスペースをリスト表示します。ユーザーが管理者の場合、このエンドポイントはインスタンス内のすべてのネームスペースを返します。

```plaintext
GET /namespaces
```

| 属性          | 型    | 必須 | 説明                                                                             |
|--------------------|---------|----------|-----------------------------------------------------------------------------------------|
| `search`           | 文字列  | いいえ       | 名前またはパスに指定された値を含むネームスペースのみを返します。         |
| `owned_only`       | ブール値 | いいえ       | `true`の場合、現在のユーザーによるネームスペースのみを返します。                                 |
| `top_level_only`   | ブール値 | いいえ       | GitLab 16.8以降、`true`の場合、トップレベルのネームスペースのみを返します。                 |
| `full_path_search` | ブール値 | いいえ       | `true`の場合、`search`パラメータはネームスペースの完全なパスに対して照合されます。 |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/namespaces"
```

レスポンス例:

```json
[
  {
    "id": 1,
    "name": "user1",
    "path": "user1",
    "kind": "user",
    "full_path": "user1",
    "parent_id": null,
    "avatar_url": "https://secure.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/user1",
    "billable_members_count": 1,
    "plan": "ultimate",
    "end_date": null,
    "trial_ends_on": null,
    "trial": false,
    "root_repository_size": 100,
    "projects_count": 3
  },
  {
    "id": 2,
    "name": "group1",
    "path": "group1",
    "kind": "group",
    "full_path": "group1",
    "parent_id": null,
    "avatar_url": null,
    "web_url": "https://gitlab.example.com/groups/group1",
    "members_count_with_descendants": 2,
    "billable_members_count": 2,
    "plan": "ultimate",
    "end_date": null,
    "trial_ends_on": null,
    "trial": false,
    "root_repository_size": 100,
    "projects_count": 3
  },
  {
    "id": 3,
    "name": "bar",
    "path": "bar",
    "kind": "group",
    "full_path": "foo/bar",
    "parent_id": 9,
    "avatar_url": null,
    "web_url": "https://gitlab.example.com/groups/foo/bar",
    "members_count_with_descendants": 5,
    "billable_members_count": 5,
    "end_date": null,
    "trial_ends_on": null,
    "trial": false,
    "root_repository_size": 100,
    "projects_count": 3
  }
]
```

グループオーナーまたはGitLab.comでは、追加の属性が返される場合があります:

```json
[
  {
    ...
    "max_seats_used": 3,
    "max_seats_used_changed_at":"2025-05-15T12:00:02.000Z",
    "seats_in_use": 2,
    "projects_count": 1,
    "root_repository_size":0,
    "members_count_with_descendants":26,
    "plan": "free",
    ...
  }
]
```

## ネームスペースの詳細を取得 {#get-details-on-a-namespace}

指定されたネームスペースの詳細を取得します。

```plaintext
GET /namespaces/:id
```

| 属性 | 型           | 必須 | 説明 |
| --------- | -------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | IDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)のネームスペース |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/namespaces/2"
```

レスポンス例:

```json
{
  "id": 2,
  "name": "group1",
  "path": "group1",
  "kind": "group",
  "full_path": "group1",
  "parent_id": null,
  "avatar_url": null,
  "web_url": "https://gitlab.example.com/groups/group1",
  "members_count_with_descendants": 2,
  "billable_members_count": 2,
  "max_seats_used": 0,
  "seats_in_use": 0,
  "plan": "default",
  "end_date": null,
  "trial_ends_on": null,
  "trial": false,
  "root_repository_size": 100,
  "projects_count": 3
}
```

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/namespaces/group1"
```

レスポンス例:

```json
{
  "id": 2,
  "name": "group1",
  "path": "group1",
  "kind": "group",
  "full_path": "group1",
  "parent_id": null,
  "avatar_url": null,
  "web_url": "https://gitlab.example.com/groups/group1",
  "members_count_with_descendants": 2,
  "billable_members_count": 2,
  "max_seats_used": 0,
  "seats_in_use": 0,
  "plan": "default",
  "end_date": null,
  "trial_ends_on": null,
  "trial": false,
  "root_repository_size": 100
}
```

## ネームスペースの可用性を確認 {#verify-namespace-availability}

指定されたネームスペースがすでに存在するかどうかを確認します。ネームスペースが存在する場合、エンドポイントは代替名を提案します。

```plaintext
GET /namespaces/:namespace/exists
```

| 属性   | 型    | 必須 | 説明 |
| ----------- | ------- | -------- | ----------- |
| `namespace` | 文字列  | はい      | ネームスペースのパス。 |
| `parent_id` | 整数 | いいえ       | 親ネームスペースのID。指定されていない場合、トップレベルのネームスペースのみを返します。 |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/namespaces/my-group/exists?parent_id=1"
```

レスポンス例:

```json
{
    "exists": true,
    "suggests": [
        "my-group1"
    ]
}
```
