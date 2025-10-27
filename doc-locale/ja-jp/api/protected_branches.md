---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 保護ブランチAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、リポジトリの[ブランチ保護](../user/project/repository/branches/protected.md)を管理します。

GitLab PremiumとGitLab Ultimateでは、ブランチへのプッシュに対する、よりきめ細かい保護がサポートされています。管理者は、特定のユーザーの代わりに、デプロイキーのみに保護ブランチを変更およびプッシュする権限を付与できます。

## 有効なアクセスレベル {#valid-access-levels}

`ProtectedRefAccess.allowed_access_levels`メソッドは、次のアクセスレベルを定義します。

- `0`: アクセスなし
- `30`: デベロッパーロール
- `40`: メンテナーロール
- `60`: 管理者

## 保護ブランチのリスト {#list-protected-branches}

{{< history >}}

- デプロイキー情報は、GitLab 16.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116846)。

{{< /history >}}

UIで定義されているように、プロジェクトから[保護されたブランチ](../user/project/repository/branches/protected.md)のリストを取得します。ワイルドカードが設定されている場合、そのワイルドカードに一致するブランチの正確な名前の代わりに、ワイルドカードが返されます。

```plaintext
GET /projects/:id/protected_branches
```

サポートされている属性:

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `search`  | 文字列            | いいえ       | 検索する保護ブランチの名前または名前の一部。 |

成功した場合は、[`200 OK`](rest/troubleshooting.md#status-codes)と以下のレスポンス属性が返されます。

| 属性                                        | 型    | 説明 |
|--------------------------------------------------|---------|-------------|
| `allow_force_push`                               | ブール値 | `true`の場合、このブランチで強制プッシュが許可されます。 |
| `code_owner_approval_required`                   | ブール値 | `true`の場合、このブランチへのプッシュにはコードオーナーの承認が必要です。 |
| `id`                                             | 整数 | 保護ブランチのID。 |
| `inherited`                                      | ブール値 | `true`の場合、保護設定は親グループから継承されます。PremiumおよびUltimateのみ。 |
| `merge_access_levels`                            | 配列   | マージアクセスレベルの設定の配列。 |
| `merge_access_levels[].access_level`             | 整数 | マージのアクセスレベル。 |
| `merge_access_levels[].access_level_description` | 文字列  | アクセスレベルの人にとって読みやすい説明。 |
| `merge_access_levels[].group_id`                 | 整数 | マージアクセスを持つグループのID。PremiumおよびUltimateのみ。 |
| `merge_access_levels[].id`                       | 整数 | マージアクセスレベルの設定のID。 |
| `merge_access_levels[].user_id`                  | 整数 | マージアクセスを持つユーザーのID。PremiumおよびUltimateのみ。 |
| `name`                                           | 文字列  | 保護ブランチの名前。 |
| `push_access_levels`                             | 配列   | プッシュアクセスレベルの設定の配列。 |
| `push_access_levels[].access_level`              | 整数 | プッシュのアクセスレベル。 |
| `push_access_levels[].access_level_description`  | 文字列  | アクセスレベルの人にとって読みやすい説明。 |
| `push_access_levels[].deploy_key_id`             | 整数 | プッシュアクセスを持つデプロイキーのID。 |
| `push_access_levels[].group_id`                  | 整数 | プッシュアクセスを持つグループのID。PremiumおよびUltimateのみ。 |
| `push_access_levels[].id`                        | 整数 | プッシュアクセスレベルの設定のID。 |
| `push_access_levels[].user_id`                   | 整数 | プッシュアクセスを持つユーザーのID。PremiumおよびUltimateのみ。 |

次のリクエストの例では、プロジェクトIDは`5`です。

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches"
```

次の応答例を示します。

- IDが`100`と`101`の2つの保護ブランチ。
- IDが`1001`、`1002`、および`1003`の`push_access_levels`。
- IDが`2001`と`2002`の`merge_access_levels`。

```json
[
  {
    "id": 100,
    "name": "main",
    "push_access_levels": [
      {
        "id":  1001,
        "access_level": 40,
        "access_level_description": "Maintainers"
      },
      {
        "id": 1002,
        "access_level": 40,
        "access_level_description": "Deploy key",
        "deploy_key_id": 1
      }
    ],
    "merge_access_levels": [
      {
        "id":  2001,
        "access_level": 40,
        "access_level_description": "Maintainers"
      }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false
  },
  {
    "id": 101,
    "name": "release/*",
    "push_access_levels": [
      {
        "id":  1003,
        "access_level": 40,
        "access_level_description": "Maintainers"
      }
    ],
    "merge_access_levels": [
      {
        "id":  2002,
        "access_level": 40,
        "access_level_description": "Maintainers"
      }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false
  }
]
```

GitLab PremiumまたはUltimateのユーザーには、`user_id`、`group_id`、および`inherited`のパラメータも表示されます。`inherited`パラメータが存在する場合、設定はプロジェクトのグループから継承されました。

次の応答例を示します。

- ID `100`の1つの保護ブランチ。
- IDが`1001`と`1002`の`push_access_levels`。
- IDが`2001`の`merge_access_levels`。

```json
[
  {
    "id": 101,
    "name": "main",
    "push_access_levels": [
      {
        "id":  1001,
        "access_level": 40,
        "user_id": null,
        "group_id": null,
        "access_level_description": "Maintainers"
      },
      {
        "id": 1002,
        "access_level": 40,
        "access_level_description": "Deploy key",
        "deploy_key_id": 1,
        "user_id": null,
        "group_id": null
      }
    ],
    "merge_access_levels": [
      {
        "id":  2001,
        "access_level": null,
        "user_id": null,
        "group_id": 1234,
        "access_level_description": "Example Merge Group"
      }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false,
    "inherited": true
  }
]
```

## 単一の保護ブランチまたはワイルドカード保護ブランチを取得します {#get-a-single-protected-branch-or-wildcard-protected-branch}

単一の保護ブランチまたはワイルドカード保護ブランチを取得します。

```plaintext
GET /projects/:id/protected_branches/:name
```

サポートされている属性:

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`    | 文字列            | はい      | ブランチまたはワイルドカードの名前。 |

成功した場合は、[`200 OK`](rest/troubleshooting.md#status-codes)と以下のレスポンス属性が返されます。

| 属性                                        | 型    | 説明 |
|--------------------------------------------------|---------|-------------|
| `allow_force_push`                               | ブール値 | `true`の場合、このブランチで強制プッシュが許可されます。 |
| `code_owner_approval_required`                   | ブール値 | `true`の場合、このブランチへのプッシュにはコードオーナーの承認が必要です。 |
| `id`                                             | 整数 | 保護ブランチのID。 |
| `merge_access_levels`                            | 配列   | マージアクセスレベルの設定の配列。 |
| `merge_access_levels[].access_level`             | 整数 | マージのアクセスレベル。 |
| `merge_access_levels[].access_level_description` | 文字列  | アクセスレベルの人にとって読みやすい説明。 |
| `merge_access_levels[].group_id`                 | 整数 | マージアクセスを持つグループのID。PremiumおよびUltimateのみ。 |
| `merge_access_levels[].id`                       | 整数 | マージアクセスレベルの設定のID。 |
| `merge_access_levels[].user_id`                  | 整数 | マージアクセスを持つユーザーのID。PremiumおよびUltimateのみ。 |
| `name`                                           | 文字列  | 保護ブランチの名前。 |
| `push_access_levels`                             | 配列   | プッシュアクセスレベルの設定の配列。 |
| `push_access_levels[].access_level`              | 整数 | プッシュのアクセスレベル。 |
| `push_access_levels[].access_level_description`  | 文字列  | アクセスレベルの人にとって読みやすい説明。 |
| `push_access_levels[].group_id`                  | 整数 | プッシュアクセスを持つグループのID。PremiumおよびUltimateのみ。 |
| `push_access_levels[].id`                        | 整数 | プッシュアクセスレベルの設定のID。 |
| `push_access_levels[].user_id`                   | 整数 | プッシュアクセスを持つユーザーのID。PremiumおよびUltimateのみ。 |

次のリクエストの例では、プロジェクトIDは`5`、ブランチ名は`main`です。

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches/main"
```

レスポンス例:

```json
{
  "id": 101,
  "name": "main",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": 40,
      "access_level_description": "Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": 40,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

GitLab PremiumまたはUltimateのユーザーには、`user_id`および`group_id`のパラメータも表示されます。

レスポンス例:

```json
{
  "id": 101,
  "name": "main",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": null,
      "user_id": null,
      "group_id": 1234,
      "access_level_description": "Example Merge Group"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

## リポジトリのブランチを保護する {#protect-repository-branches}

{{< history >}}

- `deploy_key_id`の設定がGitLab 17.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166598)されました。

{{< /history >}}

単一のリポジトリブランチ、またはワイルドカード保護ブランチを使用して複数のプロジェクトリポジトリブランチを保護します。

```plaintext
POST /projects/:id/protected_branches
```

サポートされている属性:

| 属性                      | 型              | 必須 | 説明 |
|--------------------------------|-------------------|----------|-------------|
| `id`                           | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`                         | 文字列            | はい      | ブランチまたはワイルドカードの名前。 |
| `allow_force_push`             | ブール値           | いいえ       | `true`の場合、このブランチにプッシュできるメンバーは、強制プッシュもできます。デフォルトは`false`です。 |
| `allowed_to_merge`             | 配列             | いいえ       | マージアクセスレベルの配列。それぞれが`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`の形式のハッシュで記述されています。PremiumおよびUltimateのみ。 |
| `allowed_to_push`              | 配列             | いいえ       | プッシュアクセスレベルの配列。それぞれが`{user_id: integer}`、`{group_id: integer}`、`{deploy_key_id: integer}`、または`{access_level: integer}`の形式のハッシュで記述されています。PremiumおよびUltimateのみ。 |
| `allowed_to_unprotect`         | 配列             | いいえ       | 保護解除アクセスレベルの配列。それぞれが`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`の形式のハッシュで記述されています。アクセスレベル`No access`は、このフィールドでは使用できません。PremiumおよびUltimateのみ。 |
| `code_owner_approval_required` | ブール値           | いいえ       | `true`の場合、[`CODEOWNERS`ファイル](../user/project/codeowners/_index.md)の項目と一致する場合、このブランチへのプッシュを防ぎます。デフォルトは`false`です。PremiumおよびUltimateのみ。 |
| `merge_access_level`           | 整数           | いいえ       | マージを許可するアクセスレベル。デフォルトは`40`（メンテナーロール）です。 |
| `push_access_level`            | 整数           | いいえ       | プッシュを許可するアクセスレベル。デフォルトは`40`（メンテナーロール）です。 |
| `unprotect_access_level`       | 整数           | いいえ       | 保護解除を許可するアクセスレベル。デフォルトは`40`（メンテナーロール）です。 |

成功した場合は、[`201 Created`](rest/troubleshooting.md#status-codes)と以下のレスポンス属性が返されます。

| 属性                                            | 型    | 説明 |
|------------------------------------------------------|---------|-------------|
| `allow_force_push`                                   | ブール値 | `true`の場合、このブランチで強制プッシュが許可されます。 |
| `code_owner_approval_required`                       | ブール値 | `true`の場合、このブランチへのプッシュにはコードオーナーの承認が必要です。 |
| `id`                                                 | 整数 | 保護ブランチのID。 |
| `merge_access_levels`                                | 配列   | マージアクセスレベルの設定の配列。 |
| `merge_access_levels[].access_level`                 | 整数 | マージのアクセスレベル。 |
| `merge_access_levels[].access_level_description`     | 文字列  | アクセスレベルの人にとって読みやすい説明。 |
| `merge_access_levels[].group_id`                     | 整数 | マージアクセスを持つグループのID。PremiumおよびUltimateのみ。 |
| `merge_access_levels[].id`                           | 整数 | マージアクセスレベルの設定のID。 |
| `merge_access_levels[].user_id`                      | 整数 | マージアクセスを持つユーザーのID。PremiumおよびUltimateのみ。 |
| `name`                                               | 文字列  | 保護ブランチの名前。 |
| `push_access_levels`                                 | 配列   | プッシュアクセスレベルの設定の配列。 |
| `push_access_levels[].access_level`                  | 整数 | プッシュのアクセスレベル。 |
| `push_access_levels[].access_level_description`      | 文字列  | アクセスレベルの人にとって読みやすい説明。 |
| `push_access_levels[].deploy_key_id`                 | 整数 | プッシュアクセスを持つデプロイキーのID。 |
| `push_access_levels[].group_id`                      | 整数 | プッシュアクセスを持つグループのID。PremiumおよびUltimateのみ。 |
| `push_access_levels[].id`                            | 整数 | プッシュアクセスレベルの設定のID。 |
| `push_access_levels[].user_id`                       | 整数 | プッシュアクセスを持つユーザーのID。PremiumおよびUltimateのみ。 |
| `unprotect_access_levels`                            | 配列   | 保護解除アクセスレベルの設定の配列。 |
| `unprotect_access_levels[].access_level`             | 整数 | 保護解除のアクセスレベル。 |
| `unprotect_access_levels[].access_level_description` | 文字列  | アクセスレベルの人にとって読みやすい説明。 |
| `unprotect_access_levels[].group_id`                 | 整数 | 保護解除アクセスを持つグループのID。PremiumおよびUltimateのみ。 |
| `unprotect_access_levels[].id`                       | 整数 | 保護解除アクセスレベルの設定のID。 |
| `unprotect_access_levels[].user_id`                  | 整数 | 保護解除アクセスを持つユーザーのID。PremiumおよびUltimateのみ。 |

次のリクエストの例では、プロジェクトIDは`5`で、ブランチ名は`*-stable`です。

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches?name=*-stable&push_access_level=30&merge_access_level=30&unprotect_access_level=40"
```

応答の例を次に示します。

- ID `101`の保護ブランチ。
- IDが`1001`の`push_access_levels`。
- IDが`2001`の`merge_access_levels`。
- IDが`3001`の`unprotect_access_levels`。

```json
{
  "id": 101,
  "name": "*-stable",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": 30,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": 30,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "unprotect_access_levels": [
    {
      "id":  3001,
      "access_level": 40,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

GitLab PremiumまたはUltimateのユーザーには、`user_id`と`group_id`のパラメータも表示されます。

次の応答例を示します。

- ID `101`の保護ブランチ。
- IDが`1001`の`push_access_levels`。
- IDが`2001`の`merge_access_levels`。
- IDが`3001`の`unprotect_access_levels`。

```json
{
  "id": 1,
  "name": "*-stable",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": 30,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": 30,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "unprotect_access_levels": [
    {
      "id":  3001,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

### ユーザープッシュアクセスとグループマージアクセスの例 {#example-with-user-push-access-and-group-merge-access}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

`allowed_to_push` / `allowed_to_merge` / `allowed_to_unprotect`配列の要素は、`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`の形式をとる必要があります。各ユーザーはプロジェクトへのアクセス権を持ち、各グループは[このプロジェクトを共有](../user/project/members/sharing_projects_groups.md)する必要があります。これらのアクセスレベルにより、保護ブランチへのアクセスをよりきめ細かく制御できます。詳細については、[グループ権限を設定する](../user/project/repository/branches/protected.md#with-group-permissions)を参照してください。

次のリクエストの例では、ユーザープッシュアクセスとグループマージアクセスを持つ保護ブランチを作成します。`user_id`は`2`で、`group_id`は`3`です。

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches?name=*-stable&allowed_to_push%5B%5D%5Buser_id%5D=2&allowed_to_merge%5B%5D%5Bgroup_id%5D=3"
```

次の応答例を示します。

- ID `101`の保護ブランチ。
- IDが`1001`の`push_access_levels`。
- IDが`2001`の`merge_access_levels`。
- IDが`3001`の`unprotect_access_levels`。

```json
{
  "id": 101,
  "name": "*-stable",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": null,
      "user_id": 2,
      "group_id": null,
      "access_level_description": "Administrator"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": null,
      "user_id": null,
      "group_id": 3,
      "access_level_description": "Example Merge Group"
    }
  ],
  "unprotect_access_levels": [
    {
      "id":  3001,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

### デプロイキーアクセスの例 {#example-with-deploy-key-access}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166598)されました。

{{< /history >}}

`allowed_to_push`配列の要素は、`{user_id: integer}`、`{group_id: integer}`、`{deploy_key_id: integer}`、または`{access_level: integer}`の形式をとる必要があります。デプロイキーは、プロジェクトに対して有効になっており、プロジェクトリポジトリへの書き込みアクセス権を持っている必要があります。その他の要件については、[保護ブランチへのプッシュをアクセスするためにデプロイキーを許可する](../user/project/repository/branches/protected.md#enable-deploy-key-access)を参照してください。

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches?name=*-stable&allowed_to_push[][deploy_key_id]=1"
```

次の応答例を示します。

- ID `101`の保護ブランチ。
- IDが`1001`の`push_access_levels`。
- IDが`2001`の`merge_access_levels`。
- IDが`3001`の`unprotect_access_levels`。

```json
{
  "id": 101,
  "name": "*-stable",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": null,
      "user_id": null,
      "group_id": null,
      "deploy_key_id": 1,
      "access_level_description": "Deploy"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "unprotect_access_levels": [
    {
      "id":  3001,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

### プッシュとマージを許可するアクセスの例 {#example-with-allow-to-push-and-allow-to-merge-access}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 13.9でGitLab Premiumに移行しました。

{{< /history >}}

リクエスト例:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "main",
    "allowed_to_push": [
      {"access_level": 30}
    ],
    "allowed_to_merge": [
      {"access_level": 30},
      {"access_level": 40}
    ]
  }' \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches"
```

次の応答例を示します。

- ID `105`の保護ブランチ。
- IDが`1001`の`push_access_levels`。
- IDが`2001`と`2002`の`merge_access_levels`。
- IDが`3001`の`unprotect_access_levels`。

```json
{
    "id": 105,
    "name": "main",
    "push_access_levels": [
        {
            "id": 1001,
            "access_level": 30,
            "access_level_description": "Developers + Maintainers",
            "user_id": null,
            "group_id": null
        }
    ],
    "merge_access_levels": [
        {
            "id": 2001,
            "access_level": 30,
            "access_level_description": "Developers + Maintainers",
            "user_id": null,
            "group_id": null
        },
        {
            "id": 2002,
            "access_level": 40,
            "access_level_description": "Maintainers",
            "user_id": null,
            "group_id": null
        }
    ],
    "unprotect_access_levels": [
        {
            "id": 3001,
            "access_level": 40,
            "access_level_description": "Maintainers",
            "user_id": null,
            "group_id": null
        }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false
}
```

### 保護解除アクセスアクセスレベルの例 {#examples-with-unprotect-access-levels}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

特定のグループのみがブランチを保護解除できる保護ブランチを作成するには：

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "production",
    "allowed_to_unprotect": [
      {"group_id": 789}
    ]
  }' \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches"
```

複数の種類のユーザーがブランチを保護解除できるようにするには：

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "main",
    "allowed_to_unprotect": [
      {"user_id": 123},
      {"group_id": 456},
      {"access_level": 40}
    ]
  }' \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches"
```

この設定では、これらのユーザーはブランチを保護解除できます。

- ID `123`のユーザー。
- ID `456`のグループのメンバー。
- 少なくともメンテナーロール（アクセスレベル40）を持つユーザー。

## リポジトリのブランチの保護を解除する {#unprotect-repository-branches}

指定された保護ブランチまたはワイルドカード保護ブランチを保護解除します。

```plaintext
DELETE /projects/:id/protected_branches/:name
```

サポートされている属性:

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`    | 文字列            | はい      | ブランチの名前。 |

成功すると、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

次のリクエストの例では、プロジェクトIDは`5`で、ブランチ名は`*-stable`です。

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches/*-stable"
```

## 保護ブランチを更新する {#update-a-protected-branch}

{{< history >}}

- `deploy_key_id`の設定がGitLab 17.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166598)されました。

{{< /history >}}

保護ブランチを更新します。

```plaintext
PATCH /projects/:id/protected_branches/:name
```

サポートされている属性:

| 属性                      | 型              | 必須 | 説明 |
|--------------------------------|-------------------|----------|-------------|
| `id`                           | 整数または文字列 | はい      | プロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`                         | 文字列            | はい      | ブランチまたはワイルドカードの名前。 |
| `allow_force_push`             | ブール値           | いいえ       | `true`の場合、このブランチにプッシュできるメンバーは、強制プッシュもできます。 |
| `allowed_to_merge`             | 配列             | いいえ       | マージアクセスレベルの配列。それぞれが`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`の形式のハッシュで記述されています。PremiumおよびUltimateのみ。 |
| `allowed_to_push`              | 配列             | いいえ       | プッシュアクセスレベルの配列。それぞれが`{user_id: integer}`、`{group_id: integer}`、`{deploy_key_id: integer}`、または`{access_level: integer}`の形式のハッシュで記述されています。PremiumおよびUltimateのみ。 |
| `allowed_to_unprotect`         | 配列             | いいえ       | 保護解除アクセスレベルの配列。それぞれが`{user_id: integer}`、`{group_id: integer}`、`{access_level: integer}`、または既存のアクセスレベルを削除するための`{id: integer, _destroy: true}`の形式のハッシュで記述されています。アクセスレベル`No access`は、このフィールドでは使用できません。PremiumおよびUltimateのみ。 |
| `code_owner_approval_required` | ブール値           | いいえ       | `true`の場合、[`CODEOWNERS`ファイル](../user/project/codeowners/_index.md)の項目と一致する場合、このブランチへのプッシュを防ぎます。PremiumおよびUltimateのみ。 |

成功した場合は、[`200 OK`](rest/troubleshooting.md#status-codes)と以下のレスポンス属性が返されます。

| 属性                                            | 型    | 説明 |
|------------------------------------------------------|---------|-------------|
| `allow_force_push`                                   | ブール値 | `true`の場合、このブランチで強制プッシュが許可されます。 |
| `code_owner_approval_required`                       | ブール値 | `true`の場合、このブランチへのプッシュにはコードオーナーの承認が必要です。 |
| `id`                                                 | 整数 | 保護ブランチのID。 |
| `merge_access_levels`                                | 配列   | マージアクセスレベルの設定の配列。 |
| `merge_access_levels[].access_level`                 | 整数 | マージのアクセスレベル。 |
| `merge_access_levels[].access_level_description`     | 文字列  | アクセスレベルの人にとって読みやすい説明。 |
| `merge_access_levels[].group_id`                     | 整数 | マージアクセスを持つグループのID。PremiumおよびUltimateのみ。 |
| `merge_access_levels[].id`                           | 整数 | マージアクセスレベルの設定のID。 |
| `merge_access_levels[].user_id`                      | 整数 | マージアクセスを持つユーザーのID。PremiumおよびUltimateのみ。 |
| `name`                                               | 文字列  | 保護ブランチの名前。 |
| `push_access_levels`                                 | 配列   | プッシュアクセスレベルの設定の配列。 |
| `push_access_levels[].access_level`                  | 整数 | プッシュのアクセスレベル。 |
| `push_access_levels[].access_level_description`      | 文字列  | アクセスレベルの人にとって読みやすい説明。 |
| `push_access_levels[].deploy_key_id`                 | 整数 | プッシュアクセスを持つデプロイキーのID。 |
| `push_access_levels[].group_id`                      | 整数 | プッシュアクセスを持つグループのID。PremiumおよびUltimateのみ。 |
| `push_access_levels[].id`                            | 整数 | プッシュアクセスレベルの設定のID。 |
| `push_access_levels[].user_id`                       | 整数 | プッシュアクセスを持つユーザーのID。PremiumおよびUltimateのみ。 |
| `unprotect_access_levels`                            | 配列   | 保護解除アクセスレベルの設定の配列。 |
| `unprotect_access_levels[].access_level`             | 整数 | 保護解除のアクセスレベル。 |
| `unprotect_access_levels[].access_level_description` | 文字列  | アクセスレベルの人にとって読みやすい説明。 |
| `unprotect_access_levels[].group_id`                 | 整数 | 保護解除アクセスを持つグループのID。PremiumおよびUltimateのみ。 |
| `unprotect_access_levels[].id`                       | 整数 | 保護解除アクセスレベルの設定のID。 |
| `unprotect_access_levels[].user_id`                  | 整数 | 保護解除アクセスレベルを持つユーザーのID。PremiumおよびUltimateのみ。 |

リクエスト例:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches/feature-branch?allow_force_push=true&code_owner_approval_required=true"
```

`allowed_to_push`、`allowed_to_merge`、および`allowed_to_unprotect`の配列内の要素は、`user_id`、`group_id`、または`access_level`のいずれかであり、`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`の形式を取ります。

`allowed_to_push`には追加の要素`deploy_key_id`が含まれており、`{deploy_key_id: integer}`の形式を取ります。

更新するには:

- `user_id`: 更新されたユーザーがプロジェクトへのアクセスレベルを持っていることを確認してください。それぞれのハッシュで、`access_level`の`id`も渡す必要があります。
- `group_id`: 更新されたグループが[このプロジェクトを共有している](../user/project/members/sharing_projects_groups.md)ことを確認してください。それぞれのハッシュで、`access_level`の`id`も渡す必要があります。
- `deploy_key_id`: デプロイキーがプロジェクトで有効になっていること、およびプロジェクトリポジトリへの書き込みアクセスレベルを持っていることを確認してください。

削除するには、`_destroy`を`true`に設定して渡す必要があります。次の例を参照してください。

### 例: `push_access_level`レコードを作成する {#example-create-a-push_access_level-record}

```shell
curl --header 'Content-Type: application/json' --request PATCH \
  --data '{"allowed_to_push": [{"access_level": 40}]}' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/22034114/protected_branches/main"
```

レスポンス例:

```json
{
   "name": "main",
   "push_access_levels": [
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "Maintainers",
         "user_id": null,
         "group_id": null
      }
   ]
}
```

### 例: `push_access_level`レコードを更新する {#example-update-a-push_access_level-record}

```shell
curl --header 'Content-Type: application/json' --request PATCH \
  --data '{"allowed_to_push": [{"id": 12, "access_level": 0}]}' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/22034114/protected_branches/main"
```

レスポンス例:

```json
{
   "name": "main",
   "push_access_levels": [
      {
         "id": 12,
         "access_level": 0,
         "access_level_description": "No One",
         "user_id": null,
         "group_id": null
      }
   ]
}
```

### 例: `push_access_level`レコードを削除する {#example-delete-a-push_access_level-record}

```shell
curl --header 'Content-Type: application/json' --request PATCH \
  --data '{"allowed_to_push": [{"id": 12, "_destroy": true}]}' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/22034114/protected_branches/main"
```

レスポンス例:

```json
{
   "name": "main",
   "push_access_levels": []
}
```

### 例: `unprotect_access_level`レコードを更新する {#example-update-an-unprotect_access_level-record}

前提要件: 

- このAPIを呼び出すユーザーは、`allowed_to_unprotect`設定に含まれている必要があります。
- `user_id`で指定されたユーザーは、プロジェクトメンバーである必要があります。
- `group_id`で指定されたグループは、プロジェクトへのアクセスレベルを持っている必要があります。

既存の保護ブランチを誰が保護解除できるかを変更するには、既存のアクセスレベルレコードの`id`を含めます。次に例を示します。

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "allowed_to_unprotect": [
      {"id": 17486, "user_id": 3791}
    ]
  }' \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches/main"
```

特定のアクセスレベルを削除するには、`_destroy: true`を使用します。

## 関連トピック {#related-topics}

- [保護ブランチ](../user/project/repository/branches/protected.md)
- [ブランチ](../user/project/repository/branches/_index.md)
- [ブランチAPI](branches.md)
