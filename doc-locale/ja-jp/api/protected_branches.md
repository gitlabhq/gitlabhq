---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 保護ブランチAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[保護ブランチ](../user/project/repository/branches/protected.md)を管理します。

PremiumとUltimateは、ブランチへのプッシュに対するよりきめ細かな保護をサポートしています。管理者は、特定のユーザーではなく、デプロイキーに対してのみ、保護ブランチの変更およびプッシュの権限を付与できます。

## 有効なアクセスレベル {#valid-access-levels}

`ProtectedRefAccess.allowed_access_levels`メソッドは、プッシュ、マージ、および保護解除の設定全体で使用される次のアクセスレベルを定義します。

- `0`: アクセスなし - プッシュおよびマージアクセスレベルにのみ有効です。保護解除アクセスレベルには無効です。
- `30`: デベロッパー
- `40`: メンテナー
- `60`: 管理者 - GitLab Self-Managedにのみ有効です。

ロールベースのアクセスレベルに加えて、次によってアクセスを割り当てることができます:

- ユーザー (`user_id`): プッシュ、マージ、および保護解除アクセスレベルに有効です。
- グループ (`group_id`): プッシュ、マージ、および保護解除アクセスレベルに有効です。グループはプロジェクトに対して、デベロッパー、メンテナー、またはオーナーのロールを持っている必要があります。
- デプロイキー (`deploy_key_id`): プッシュアクセスレベルにのみ有効です。

詳細については、[リポジトリブランチの保護の例](#protect-repository-branches)を参照してください。

> [!note]
> ブランチの保護設定が永続的にロックされるのを避けるために、少なくとも1人のユーザーまたはグループが常にブランチに対する保護解除権限を保持するようにしてください。詳細については、[誰がブランチの保護を解除できるかを制御する](../user/project/repository/branches/protected.md#control-who-can-unprotect-branches)を参照してください。

## 保護ブランチを一覧表示 {#list-protected-branches}

{{< history >}}

- デプロイキー情報がGitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116846)されました。

{{< /history >}}

UIで定義されているプロジェクトから[保護ブランチ](../user/project/repository/branches/protected.md)のリストを取得します。ワイルドカードが設定されている場合、そのワイルドカードに一致するブランチの正確な名前の代わりに、それが返されます。

```plaintext
GET /projects/:id/protected_branches
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `search`  | 文字列            | いいえ       | 検索する保護ブランチの名前またはその一部。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                                        | 型    | 説明 |
|--------------------------------------------------|---------|-------------|
| `allow_force_push`                               | ブール値 | `true`の場合、このブランチでの強制プッシュが許可されます。 |
| `code_owner_approval_required`                   | ブール値 | `true`の場合、このブランチへのプッシュにはコードオーナーの承認が必要です。 |
| `id`                                             | 整数 | 保護ブランチのID。 |
| `inherited`                                      | ブール値 | `true`の場合、保護設定は親グループから継承されます。PremiumおよびUltimateのみです。 |
| `merge_access_levels`                            | 配列   | マージアクセスレベル設定の配列。 |
| `merge_access_levels[].access_level`             | 整数 | マージのアクセスレベル。 |
| `merge_access_levels[].access_level_description` | 文字列  | アクセスレベルの人間が読める説明。 |
| `merge_access_levels[].group_id`                 | 整数 | マージアクセスレベルを持つグループのID。PremiumおよびUltimateのみです。 |
| `merge_access_levels[].id`                       | 整数 | マージアクセスレベル設定のID。 |
| `merge_access_levels[].user_id`                  | 整数 | マージアクセスレベルを持つユーザーのID。PremiumおよびUltimateのみです。 |
| `name`                                           | 文字列  | 保護ブランチの名前。 |
| `push_access_levels`                             | 配列   | プッシュアクセスレベル設定の配列。 |
| `push_access_levels[].access_level`              | 整数 | プッシュのアクセスレベル。 |
| `push_access_levels[].access_level_description`  | 文字列  | アクセスレベルの人間が読める説明。 |
| `push_access_levels[].deploy_key_id`             | 整数 | プッシュアクセスレベルを持つデプロイキーのID。 |
| `push_access_levels[].group_id`                  | 整数 | プッシュアクセスレベルを持つグループのID。PremiumおよびUltimateのみです。 |
| `push_access_levels[].id`                        | 整数 | プッシュアクセスレベル設定のID。 |
| `push_access_levels[].user_id`                   | 整数 | プッシュアクセスレベルを持つユーザーのID。PremiumおよびUltimateのみです。 |

次の例のリクエストでは、プロジェクトIDは`5`です。

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches"
```

次の例のレスポンスには以下が含まれます:

- IDが`100`と`101`の2つの保護ブランチ。
- IDが`1001`、`1002`、`1003`の`push_access_levels`。
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

PremiumまたはUltimateのGitLabユーザーは、`user_id`、`group_id`、および`inherited`パラメータも参照できます。`inherited`パラメータが存在する場合、設定はプロジェクトのグループから継承されました。

次の例のレスポンスには以下が含まれます:

- IDが`100`の1つの保護ブランチ。
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

## 保護ブランチまたはワイルドカード保護ブランチを取得する {#retrieve-a-protected-branch-or-wildcard-protected-branch}

指定された保護ブランチまたはワイルドカード保護ブランチを取得します。

```plaintext
GET /projects/:id/protected_branches/:name
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`    | 文字列            | はい      | ブランチまたはワイルドカードの名前。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                                        | 型    | 説明 |
|--------------------------------------------------|---------|-------------|
| `allow_force_push`                               | ブール値 | `true`の場合、このブランチでの強制プッシュが許可されます。 |
| `code_owner_approval_required`                   | ブール値 | `true`の場合、このブランチへのプッシュにはコードオーナーの承認が必要です。 |
| `id`                                             | 整数 | 保護ブランチのID。 |
| `merge_access_levels`                            | 配列   | マージアクセスレベル設定の配列。 |
| `merge_access_levels[].access_level`             | 整数 | マージのアクセスレベル。 |
| `merge_access_levels[].access_level_description` | 文字列  | アクセスレベルの人間が読める説明。 |
| `merge_access_levels[].group_id`                 | 整数 | マージアクセスレベルを持つグループのID。PremiumおよびUltimateのみです。 |
| `merge_access_levels[].id`                       | 整数 | マージアクセスレベル設定のID。 |
| `merge_access_levels[].user_id`                  | 整数 | マージアクセスレベルを持つユーザーのID。PremiumおよびUltimateのみです。 |
| `name`                                           | 文字列  | 保護ブランチの名前。 |
| `push_access_levels`                             | 配列   | プッシュアクセスレベル設定の配列。 |
| `push_access_levels[].access_level`              | 整数 | プッシュのアクセスレベル。 |
| `push_access_levels[].access_level_description`  | 文字列  | アクセスレベルの人間が読める説明。 |
| `push_access_levels[].group_id`                  | 整数 | プッシュアクセスレベルを持つグループのID。PremiumおよびUltimateのみです。 |
| `push_access_levels[].id`                        | 整数 | プッシュアクセスレベル設定のID。 |
| `push_access_levels[].user_id`                   | 整数 | プッシュアクセスレベルを持つユーザーのID。PremiumおよびUltimateのみです。 |

次の例のリクエストでは、プロジェクトIDは`5`、ブランチ名は`main`です:

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

PremiumまたはUltimateのGitLabユーザーは、`user_id`と`group_id`パラメータも参照できます。

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

## リポジトリブランチを保護する {#protect-repository-branches}

{{< history >}}

- `deploy_key_id`の設定はGitLab 17.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166598)されました。
- `deploy_key_id`の設定は、GitLab 18.10でPremiumからFreeに[移動](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224542)されました。

{{< /history >}}

単一のリポジトリブランチ、または複数のプロジェクトリポジトリブランチをワイルドカード保護ブランチを使用して保護します。

```plaintext
POST /projects/:id/protected_branches
```

サポートされている属性は以下のとおりです: 

| 属性                      | 型              | 必須 | 説明 |
|--------------------------------|-------------------|----------|-------------|
| `id`                           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`                         | 文字列            | はい      | ブランチまたはワイルドカードの名前。 |
| `allow_force_push`             | ブール値           | いいえ       | `true`の場合、このブランチにプッシュできるメンバーは強制プッシュもできます。デフォルトは`false`です。 |
| `allowed_to_merge`             | 配列             | いいえ       | マージアクセスレベルの配列。それぞれは`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`の形式のハッシュで記述されます。PremiumおよびUltimateのみです。 |
| `allowed_to_push`              | 配列             | いいえ       | プッシュアクセスレベルの配列。それぞれは`{user_id: integer}`、`{group_id: integer}`、`{deploy_key_id: integer}`、または`{access_level: integer}`の形式のハッシュで記述されます。`user_id`、`group_id`、および`access_level`はPremiumとUltimateのみです。 |
| `allowed_to_unprotect`         | 配列             | いいえ       | 保護解除アクセスレベルの配列。それぞれは`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`の形式のハッシュで記述されます。アクセスレベル`No access`はこのフィールドでは使用できません。PremiumおよびUltimateのみです。 |
| `code_owner_approval_required` | ブール値           | いいえ       | `true`の場合、[`CODEOWNERS`ファイル](../user/project/codeowners/_index.md)内の項目に一致する場合、このブランチへのプッシュを禁止します。デフォルトは`false`です。PremiumおよびUltimateのみです。 |
| `merge_access_level`           | 整数           | いいえ       | マージが許可されるアクセスレベル。デフォルトは`40` (メンテナーロール) です。 |
| `push_access_level`            | 整数           | いいえ       | プッシュが許可されるアクセスレベル。デフォルトは`40` (メンテナーロール) です。 |
| `unprotect_access_level`       | 整数           | いいえ       | 保護解除が許可されるアクセスレベル。デフォルトは`40` (メンテナーロール) です。`0` (アクセスなし) は無効です。 |

アクセスレベルを設定する場合:

- `allowed_to_push`と`allowed_to_merge`に対して複数のアクセスレベルを同時に設定できます。
- 最も緩いアクセスレベルによって、誰がそのアクションを実行できるかが決まります。
- `allowed_to_push`、`allowed_to_merge`、または`allowed_to_unprotect`配列に`id`を含めないでください。`id`フィールドは既存のアクセスレベルレコードを識別し、[保護ブランチ](#update-a-protected-branch)を更新する場合にのみ有効です。既存のレコードと一致しない`id`を含めると、APIは`404 Not Found`を返します。

この動作は、**なし** (`access_level: 0`) を選択すると他のロール選択を自動的にクリアするUIとは異なります。

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                                            | 型    | 説明 |
|------------------------------------------------------|---------|-------------|
| `allow_force_push`                                   | ブール値 | `true`の場合、このブランチでの強制プッシュが許可されます。 |
| `code_owner_approval_required`                       | ブール値 | `true`の場合、このブランチへのプッシュにはコードオーナーの承認が必要です。 |
| `id`                                                 | 整数 | 保護ブランチのID。 |
| `merge_access_levels`                                | 配列   | マージアクセスレベル設定の配列。 |
| `merge_access_levels[].access_level`                 | 整数 | マージのアクセスレベル。 |
| `merge_access_levels[].access_level_description`     | 文字列  | アクセスレベルの人間が読める説明。 |
| `merge_access_levels[].group_id`                     | 整数 | マージアクセスレベルを持つグループのID。PremiumおよびUltimateのみです。 |
| `merge_access_levels[].id`                           | 整数 | マージアクセスレベル設定のID。 |
| `merge_access_levels[].user_id`                      | 整数 | マージアクセスレベルを持つユーザーのID。PremiumおよびUltimateのみです。 |
| `name`                                               | 文字列  | 保護ブランチの名前。 |
| `push_access_levels`                                 | 配列   | プッシュアクセスレベル設定の配列。 |
| `push_access_levels[].access_level`                  | 整数 | プッシュのアクセスレベル。 |
| `push_access_levels[].access_level_description`      | 文字列  | アクセスレベルの人間が読める説明。 |
| `push_access_levels[].deploy_key_id`                 | 整数 | プッシュアクセスレベルを持つデプロイキーのID。 |
| `push_access_levels[].group_id`                      | 整数 | プッシュアクセスレベルを持つグループのID。PremiumおよびUltimateのみです。 |
| `push_access_levels[].id`                            | 整数 | プッシュアクセスレベル設定のID。 |
| `push_access_levels[].user_id`                       | 整数 | プッシュアクセスレベルを持つユーザーのID。PremiumおよびUltimateのみです。 |
| `unprotect_access_levels`                            | 配列   | 保護解除アクセスレベル設定の配列。 |
| `unprotect_access_levels[].access_level`             | 整数 | 保護解除のアクセスレベル。 |
| `unprotect_access_levels[].access_level_description` | 文字列  | アクセスレベルの人間が読める説明。 |
| `unprotect_access_levels[].group_id`                 | 整数 | 保護解除アクセスレベルを持つグループのID。PremiumおよびUltimateのみです。 |
| `unprotect_access_levels[].id`                       | 整数 | 保護解除アクセスレベル設定のID。 |
| `unprotect_access_levels[].user_id`                  | 整数 | 保護解除アクセスレベルを持つユーザーのID。PremiumおよびUltimateのみです。 |

次の例のリクエストでは、プロジェクトIDは`5`、ブランチ名は`*-stable`です。

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches?name=*-stable&push_access_level=30&merge_access_level=30&unprotect_access_level=40"
```

例のレスポンスには以下が含まれます:

- IDが`101`の保護ブランチ。
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

PremiumまたはUltimateのGitLabユーザーは、`user_id`と`group_id`パラメータも参照できます:

次の例のレスポンスには以下が含まれます:

- IDが`101`の保護ブランチ。
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

### ユーザープッシュアクセスレベルとグループマージアクセスレベルの例 {#example-with-user-push-access-and-group-merge-access}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

`allowed_to_push` / `allowed_to_merge` / `allowed_to_unprotect`配列の要素は、`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`の形式である必要があります。各ユーザーはプロジェクトへのアクセス権を持ち、各グループは[このプロジェクトを共有している](../user/project/members/sharing_projects_groups.md)必要があります。これらのアクセスレベルにより、保護ブランチへのアクセスをよりきめ細かく制御できます。詳細については、[グループ権限を設定する](../user/project/repository/branches/protected.md#with-group-permissions)を参照してください。

次の例のリクエストは、ユーザープッシュアクセスレベルとグループマージアクセスレベルを持つ保護ブランチを作成します。`user_id`は`2`、`group_id`は`3`です。

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches?name=*-stable&allowed_to_push%5B%5D%5Buser_id%5D=2&allowed_to_merge%5B%5D%5Bgroup_id%5D=3"
```

次の例のレスポンスには以下が含まれます:

- IDが`101`の保護ブランチ。
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

### デプロイキーアクセスレベルの例 {#example-with-deploy-key-access}

{{< history >}}

- GitLab 17.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166598)されました。
- GitLab 18.10でPremiumからFreeに[移動](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224542)されました。

{{< /history >}}

`allowed_to_push`配列の要素は、`{user_id: integer}`、`{group_id: integer}`、`{deploy_key_id: integer}`、または`{access_level: integer}`の形式である必要があります。デプロイキーはプロジェクトで有効になっており、プロジェクトリポジトリへの書き込みアクセス権を持っている必要があります。その他の要件については、[デプロイキーが保護ブランチにプッシュすることを許可する](../user/project/repository/branches/protected.md#enable-deploy-key-access)を参照してください。

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches?name=*-stable&allowed_to_push[][deploy_key_id]=1"
```

次の例のレスポンスには以下が含まれます:

- IDが`101`の保護ブランチ。
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

### プッシュを許可し、マージを許可するアクセスレベルの例 {#example-with-allow-to-push-and-allow-to-merge-access}

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

次の例のレスポンスには以下が含まれます:

- IDが`105`の保護ブランチ。
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

### 保護解除アクセスレベルの例 {#examples-with-unprotect-access-levels}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

特定のグループのみがブランチの保護を解除できる保護ブランチを作成するには:

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

複数の種類のユーザーがブランチの保護を解除できるようにするには:

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

この設定により、以下のユーザーはブランチの保護を解除できます:

- IDが`123`のユーザー。
- IDが`456`のグループのメンバー。
- メンテナーまたはオーナーのロール (アクセスレベル40) を持つユーザー。

## リポジトリブランチの保護を解除する {#unprotect-repository-branches}

指定された保護ブランチまたはワイルドカード保護ブランチの保護を解除します。

```plaintext
DELETE /projects/:id/protected_branches/:name
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`    | 文字列            | はい      | ブランチの名前。 |

成功した場合、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

次の例のリクエストでは、プロジェクトIDは`5`、ブランチ名は`*-stable`です:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches/*-stable"
```

## 保護ブランチを更新する {#update-a-protected-branch}

{{< history >}}

- `deploy_key_id`の設定はGitLab 17.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166598)されました。

{{< /history >}}

保護ブランチを更新します。

```plaintext
PATCH /projects/:id/protected_branches/:name
```

サポートされている属性は以下のとおりです: 

| 属性                      | 型              | 必須 | 説明 |
|--------------------------------|-------------------|----------|-------------|
| `id`                           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`                         | 文字列            | はい      | ブランチまたはワイルドカードの名前。 |
| `allow_force_push`             | ブール値           | いいえ       | `true`の場合、このブランチにプッシュできるメンバーは強制プッシュもできます。 |
| `allowed_to_merge`             | 配列             | いいえ       | マージアクセスレベルの配列。それぞれは`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`の形式のハッシュで記述されます。PremiumおよびUltimateのみです。 |
| `allowed_to_push`              | 配列             | いいえ       | プッシュアクセスレベルの配列。それぞれは`{user_id: integer}`、`{group_id: integer}`、`{deploy_key_id: integer}`、または`{access_level: integer}`の形式のハッシュで記述されます。`user_id`、`group_id`、および`access_level`はPremiumとUltimateのみです。 |
| `allowed_to_unprotect`         | 配列             | いいえ       | 保護解除アクセスレベルの配列。それぞれは`{user_id: integer}`、`{group_id: integer}`、`{access_level: integer}`、または既存のアクセスレベルを削除するための`{id: integer, _destroy: true}`の形式のハッシュで記述されます。アクセスレベル`No access`はこのフィールドでは使用できません。PremiumおよびUltimateのみです。 |
| `code_owner_approval_required` | ブール値           | いいえ       | `true`の場合、[`CODEOWNERS`ファイル](../user/project/codeowners/_index.md)内の項目に一致する場合、このブランチへのプッシュを禁止します。PremiumおよびUltimateのみです。 |

複数の値を設定した場合にアクセスレベルがどのように相互作用するかについては、[リポジトリブランチを保護する](#protect-repository-branches)を参照してください。

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                                            | 型    | 説明 |
|------------------------------------------------------|---------|-------------|
| `allow_force_push`                                   | ブール値 | `true`の場合、このブランチでの強制プッシュが許可されます。 |
| `code_owner_approval_required`                       | ブール値 | `true`の場合、このブランチへのプッシュにはコードオーナーの承認が必要です。 |
| `id`                                                 | 整数 | 保護ブランチのID。 |
| `merge_access_levels`                                | 配列   | マージアクセスレベル設定の配列。 |
| `merge_access_levels[].access_level`                 | 整数 | マージのアクセスレベル。 |
| `merge_access_levels[].access_level_description`     | 文字列  | アクセスレベルの人間が読める説明。 |
| `merge_access_levels[].group_id`                     | 整数 | マージアクセスレベルを持つグループのID。PremiumおよびUltimateのみです。 |
| `merge_access_levels[].id`                           | 整数 | マージアクセスレベル設定のID。 |
| `merge_access_levels[].user_id`                      | 整数 | マージアクセスレベルを持つユーザーのID。PremiumおよびUltimateのみです。 |
| `name`                                               | 文字列  | 保護ブランチの名前。 |
| `push_access_levels`                                 | 配列   | プッシュアクセスレベル設定の配列。 |
| `push_access_levels[].access_level`                  | 整数 | プッシュのアクセスレベル。 |
| `push_access_levels[].access_level_description`      | 文字列  | アクセスレベルの人間が読める説明。 |
| `push_access_levels[].deploy_key_id`                 | 整数 | プッシュアクセスレベルを持つデプロイキーのID。 |
| `push_access_levels[].group_id`                      | 整数 | プッシュアクセスレベルを持つグループのID。PremiumおよびUltimateのみです。 |
| `push_access_levels[].id`                            | 整数 | プッシュアクセスレベル設定のID。 |
| `push_access_levels[].user_id`                       | 整数 | プッシュアクセスレベルを持つユーザーのID。PremiumおよびUltimateのみです。 |
| `unprotect_access_levels`                            | 配列   | 保護解除アクセスレベル設定の配列。 |
| `unprotect_access_levels[].access_level`             | 整数 | 保護解除のアクセスレベル。 |
| `unprotect_access_levels[].access_level_description` | 文字列  | アクセスレベルの人間が読める説明。 |
| `unprotect_access_levels[].group_id`                 | 整数 | 保護解除アクセスレベルを持つグループのID。PremiumおよびUltimateのみです。 |
| `unprotect_access_levels[].id`                       | 整数 | 保護解除アクセスレベル設定のID。 |
| `unprotect_access_levels[].user_id`                  | 整数 | 保護解除アクセスレベルを持つユーザーのID。PremiumおよびUltimateのみです。 |

リクエスト例: 

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches/feature-branch?allow_force_push=true&code_owner_approval_required=true"
```

`allowed_to_push`、`allowed_to_merge`、および`allowed_to_unprotect`配列の要素は、`user_id`、`group_id`、または`access_level`のいずれかであり、`{user_id: integer}`、`{group_id: integer}`、または`{access_level: integer}`の形式である必要があります。

`allowed_to_push`には、`{deploy_key_id: integer}`の形式を取る追加の要素`deploy_key_id`が含まれます。

更新するには:

- `user_id`: 更新されたユーザーがプロジェクトへのアクセス権を持っていることを確認してください。アクセスレベルレコードの`id`をハッシュに含めます。
- `group_id`: 更新されたグループが[このプロジェクトを共有している](../user/project/members/sharing_projects_groups.md)ことを確認してください。アクセスレベルレコードの`id`をハッシュに含めます。
- `deploy_key_id`: デプロイキーがプロジェクトで有効になっており、プロジェクトリポジトリへの書き込みアクセス権を持っていることを確認してください。

既存のアクセスレベルレコードの他のフィールドを更新するには、レコードの`id`をハッシュに含めます。

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

前提条件: 

- このAPIを呼び出すユーザーは、`allowed_to_unprotect`の設定に含まれている必要があります。
- `user_id`で指定されたユーザーは、プロジェクトメンバーである必要があります。
- `group_id`で指定されたグループは、プロジェクトへのアクセス権を持っている必要があります。

既存の保護ブランチの保護を解除できるユーザーを変更するには、既存のアクセスレベルレコードの`id`を含めます。例: 

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
