---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクトメンバーAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このエンドポイントを使用して、プロジェクトメンバーとやり取りします。

グループメンバーについては、[グループメンバーAPI](group_members.md)を参照してください。

## 既知の問題 {#known-issues}

- `group_saml_identity`属性と`group_scim_identity`属性は、[SSOが有効なグループ](../user/group/saml_sso/_index.md)のグループオーナーのみに表示されます。
- `email`属性は、APIリクエストがグループ自体、またはそのグループのサブグループまたはプロジェクトに送信される場合、グループの[エンタープライズユーザー](../user/enterprise_user/_index.md)のグループオーナーのみに表示されます。

## プロジェクトのすべての直接メンバーを一覧表示 {#list-all-direct-members-of-a-project}

認証済みユーザーが表示できる、指定されたプロジェクトのすべての直接メンバーを一覧表示します。[プロジェクトの全メンバーを一覧表示](#list-all-members-of-a-project)を使用して、継承されたメンバーを一覧表示します。

この関数は、ページネーションパラメータ`page`および`per_page`を受け取り、ユーザーのリストを制限します。

```plaintext
GET /projects/:id/members
```

| 属性        | 型              | 必須 | 説明 |
|------------------|-------------------|----------|-------------|
| `id`             | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `query`          | 文字列            | いいえ       | 指定された名前、メール、またはユーザー名に基づいて結果をフィルタリングします。クエリのスコープを広げるには、部分的な値を使用します。 |
| `user_ids`       | 整数の配列 | いいえ       | 指定されたユーザーIDで結果をフィルタリングします。 |
| `skip_users`     | 整数の配列 | いいえ       | スキップされたユーザーを結果から除外します。 |
| `show_seat_info` | ブール値           | いいえ       | ユーザーのシート情報を表示します。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "username": "raymond_smith",
    "name": "Raymond Smith",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "created_at": "2012-09-22T14:13:35Z",
    "created_by": {
      "id": 2,
      "username": "john_doe",
      "name": "John Doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-10-22",
    "access_level": 30,
    "group_saml_identity": null,
    "is_using_seat": true
  },
  {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "created_at": "2012-09-22T14:13:35Z",
    "created_by": {
      "id": 1,
      "username": "raymond_smith",
      "name": "Raymond Smith",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-10-22",
    "access_level": 30,
    "email": "john@example.com",
    "group_saml_identity": {
      "extern_uid":"ABC-1234567890",
      "provider": "group_saml",
      "saml_provider_id": 10
    }
  }
]
```

## プロジェクトのすべてのメンバーをリストする {#list-all-members-of-a-project}

{{< history >}}

- GitLab 16.10で`webui_members_inherited_users`[フラグ](../administration/feature_flags/_index.md)とともに、現在のユーザーが共有グループまたは共有プロジェクトのメンバーである場合に、招待されたプライベートグループのメンバーを返すように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/219230)されました。デフォルトでは無効になっています。
- GitLab 17.0の[GitLab.comとGitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230)で`webui_members_inherited_users`機能フラグが有効になりました。
- 機能フラグ`webui_members_inherited_users`は、GitLab 17.4で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163627)されました。招待グループのメンバーは、デフォルトで表示されます。

{{< /history >}}

認証済みユーザーが表示できるすべてのプロジェクトメンバー（継承されたメンバー、招待されたユーザー、および祖先グループを通じた権限を含む）を一覧表示します。

ユーザーがこのプロジェクト、および1つ以上の祖先グループのメンバーである場合、`access_level`が最も高いメンバーシップのみが返されます。これは、ユーザーの有効な権限を表します。

招待グループのメンバーは、次のいずれかの場合に返されます。

- 招待グループが公開されている。
- リクエスタも招待グループのメンバーである。
- リクエスタが共有グループまたは共有プロジェクトのメンバーである。

> [!note]
> 招待されたグループメンバーは、共有グループまたはプロジェクトで共有メンバーシップを持っています。つまり、リクエスタが共有グループまたは共有プロジェクトのメンバーであるが、招待プライベートグループのメンバーではない場合、このエンドポイントを使用すると、リクエスタは、招待プライベートグループのメンバーを含む、すべての共有グループまたは共有プロジェクトのメンバーを取得できます。

この関数は、ページネーションパラメータ`page`および`per_page`を受け取り、ユーザーのリストを制限します。

```plaintext
GET /projects/:id/members/all
```

| 属性        | 型              | 必須 | 説明 |
|------------------|-------------------|----------|-------------|
| `id`             | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `query`          | 文字列            | いいえ       | 指定された名前、メール、またはユーザー名に基づいて結果をフィルタリングします。クエリのスコープを広げるには、部分的な値を使用します。 |
| `user_ids`       | 整数の配列 | いいえ       | 指定されたユーザーIDで結果をフィルタリングします。 |
| `show_seat_info` | ブール値           | いいえ       | ユーザーのシート情報を表示します。 |
| `state`          | 文字列            | いいえ       | メンバー状態（`awaiting`または`active`のいずれか）で結果をフィルタリングします。PremiumおよびUltimateのみです。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/all"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "username": "raymond_smith",
    "name": "Raymond Smith",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "created_at": "2012-09-22T14:13:35Z",
    "created_by": {
      "id": 2,
      "username": "john_doe",
      "name": "John Doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-10-22",
    "access_level": 30,
    "group_saml_identity": null
  },
  {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "created_at": "2012-09-22T14:13:35Z",
    "created_by": {
      "id": 1,
      "username": "raymond_smith",
      "name": "Raymond Smith",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-10-22",
    "access_level": 30,
    "email": "john@example.com",
    "group_saml_identity": {
      "extern_uid":"ABC-1234567890",
      "provider": "group_saml",
      "saml_provider_id": 10
    }
  },
  {
    "id": 3,
    "username": "foo_bar",
    "name": "Foo bar",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "created_at": "2012-10-22T14:13:35Z",
    "created_by": {
      "id": 2,
      "username": "john_doe",
      "name": "John Doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-11-22",
    "access_level": 30,
    "group_saml_identity": null
  }
]
```

## プロジェクトの直接メンバーを取得する {#retrieve-a-direct-member-of-a-project}

指定されたプロジェクトの直接メンバーを取得する。[プロジェクトのメンバーを取得する](#retrieve-a-member-of-a-project)を使用して、継承されたメンバーを取得する。

```plaintext
GET /projects/:id/members/:user_id
```

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id` | 整数           | はい      | メンバーのユーザーID。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/:user_id"
```

グループメンバーのカスタムロールを更新または削除するには、空の`member_role_id`値を渡します。

```shell
# Updates a project membership
curl --request PUT --header "Content-Type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --data '{"member_role_id": null, "access_level": 10}' \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/members/<user_id>"
```

レスポンス例: 

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "access_level": 30,
  "email": "john@example.com",
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "expires_at": null,
  "group_saml_identity": null
}
```

## プロジェクトのメンバーを取得する {#retrieve-a-member-of-a-project}

{{< history >}}

- GitLab 12.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17744)されました。
- GitLab 16.10で`webui_members_inherited_users`[フラグ](../administration/feature_flags/_index.md)とともに、現在のユーザーが共有グループまたは共有プロジェクトのメンバーである場合に、招待されたプライベートグループのメンバーを返すように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/219230)されました。デフォルトでは無効になっています。
- GitLab 17.0の[GitLab.comおよびGitLab Self-Managedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/219230)。
- 機能フラグ`webui_members_inherited_users`は、GitLab 17.4で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163627)されました。招待グループのメンバーは、デフォルトで表示されます。

{{< /history >}}

継承された、または祖先グループを通じて招待されたメンバーを含む、プロジェクトの指定されたメンバーを取得する。詳細については、[プロジェクトの全メンバーを一覧表示](#list-all-members-of-a-project)を参照してください。

> [!note]
> 招待されたグループメンバーは、共有グループまたはプロジェクトで共有メンバーシップを持っています。つまり、リクエスタが共有グループまたは共有プロジェクトのメンバーであるが、招待プライベートグループのメンバーではない場合、このエンドポイントを使用すると、リクエスタは、招待プライベートグループのメンバーを含む、すべての共有グループまたは共有プロジェクトのメンバーを取得できます。

```plaintext
GET /projects/:id/members/all/:user_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id` | 整数 | はい   | メンバーのユーザーID。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/all/:user_id"
```

レスポンス例: 

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "access_level": 30,
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "email": "john@example.com",
  "expires_at": null,
  "group_saml_identity": null
}
```

## プロジェクトにメンバーを追加する {#add-a-member-to-a-project}

指定されたプロジェクトに直接メンバーを追加します。

グループにプロジェクトへのアクセス権を付与するには、[プロジェクトをグループと共有する](projects.md#share-a-project-with-a-group)を参照してください。

```plaintext
POST /projects/:id/members
```

| 属性        | 型              | 必須                           | 説明 |
| ---------------- | ----------------- | ---------------------------------- | ----------- |
| `id`             | 整数または文字列 | はい                                | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`        | 整数または文字列 | はい（`username`が指定されていない場合） | 新しいメンバーのユーザーID、またはカンマで区切られた複数のID。 |
| `username`       | 文字列            | はい（`user_id`が指定されていない場合）  | 新しいメンバーのユーザー名、またはカンマで区切られた複数のユーザー名。 |
| `access_level`   | 整数           | はい                                | 有効な[アクセスレベル](../user/permissions.md#default-roles)。使用可能な値: `0` (アクセスなし)、`5` (最小アクセス)、`10` (ゲスト)、`15` (プランナー)、`20` (レポーター)、`25` (セキュリティマネージャー)、`30` (デベロッパー)、`40` (メンテナー)、または`50` (オーナー)。デフォルトは`30`です。 |
| `expires_at`     | 文字列            | いいえ                                 | `YEAR-MONTH-DAY`形式の日付文字列。 |
| `invite_source`  | 文字列            | いいえ                                 | メンバー作成プロセスを開始する招待のソース。GitLabのチームメンバーは、この機密情報イシュー（`https://gitlab.com/gitlab-org/gitlab/-/issues/327120`）で詳細情報を確認できます。 |
| `member_role_id` | 整数           | いいえ                                 | Ultimateのみ。カスタムメンバーロールのID。 |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1&access_level=30" \
     --url "https://gitlab.example.com/api/v4/projects/:id/members"
```

レスポンス例: 

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "expires_at": "2012-10-22",
  "access_level": 30,
  "email": "john@example.com",
  "group_saml_identity": null
}
```

> [!note]
> [役割プロモートの管理者承認](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions)がオンになっている場合、既存のユーザーを請求対象ロールにプロモートするメンバーシップリクエストには管理者の承認が必要です。

**請求対象でないプロモーションの管理**を有効にするには、最初に`enable_member_promotion_management`アプリケーション設定を有効にする必要があります。

単一のユーザーをキューに入れる例:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1&access_level=30" \
     --url "https://gitlab.example.com/api/v4/projects/:id/members"
```

```json
{
  "message":{
    "username_1":"Request queued for administrator approval."
  }
}
```

複数のユーザーをキューに入れる例:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1,2&access_level=30" \
     --url "https://gitlab.example.com/api/v4/projects/:id/members"
```

```json
{
  "queued_users": {
    "username_1": "Request queued for administrator approval.",
    "username_2": "Request queued for administrator approval."
  },
  "status": "success"
}
```

## プロジェクトのメンバーを更新 {#update-a-member-of-a-project}

指定されたプロジェクトのメンバーを更新します。

```plaintext
PUT /projects/:id/members/:user_id
```

| 属性        | 型              | 必須 | 説明 |
| ---------------- | ----------------- | -------- | ----------- |
| `id`             | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`        | 整数           | はい      | メンバーのユーザーID。 |
| `access_level`   | 整数           | はい       | 有効な[アクセスレベル](../user/permissions.md#default-roles)。使用可能な値: `0` (アクセスなし)、`5` (最小アクセス)、`10` (ゲスト)、`15` (プランナー)、`20` (レポーター)、`25` (セキュリティマネージャー)、`30` (デベロッパー)、`40` (メンテナー)、または`50` (オーナー)。デフォルトは`30`です。 |
| `expires_at`     | 文字列            | いいえ       | `YEAR-MONTH-DAY`形式の日付文字列。 |
| `member_role_id` | 整数           | いいえ       | Ultimateのみ。カスタムメンバーロールのID。値を指定しない場合は、すべてのロールを削除します。 |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/:user_id?access_level=40"
```

レスポンス例: 

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "expires_at": "2012-10-22",
  "access_level": 40,
  "email": "john@example.com",
  "group_saml_identity": null
}
```

> [!note]
> [役割プロモートの管理者承認](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions)がオンになっている場合、既存のユーザーを請求対象ロールにプロモートするメンバーシップリクエストには管理者の承認が必要です。

**請求対象でないプロモーションの管理**を有効にするには、最初に`enable_member_promotion_management`アプリケーション設定を有効にする必要があります。

レスポンス例: 

```json
{
  "message":{
    "username_1":"Request queued for administrator approval."
  }
}
```

## プロジェクトの直接メンバーを削除 {#remove-a-direct-member-of-a-project}

指定されたプロジェクトの直接メンバーを削除します。

たとえば、ユーザーがグループ内のプロジェクトに直接追加されたが、このグループには明示的に追加されていない場合、このエンドポイントを使用して削除することはできません。詳細については、[グループから請求対象メンバーを削除する](group_members.md#remove-a-billable-group-member)を参照してください。

```plaintext
DELETE /projects/:id/members/:user_id
```

| 属性            | 型              | 必須 | 説明 |
|----------------------|-------------------|----------|-------------|
| `id`                 | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`            | 整数           | はい      | メンバーのユーザーID。 |
| `skip_subresources`  | ブール値           | false    | サブグループおよびプロジェクトの削除されたメンバーの直接メンバーシップを削除することをスキップするかどうか。デフォルトは`false`です。 |
| `unassign_issuables` | ブール値           | false    | 特定のプロジェクト内で、イシューまたはマージリクエストから、削除されたメンバーの割り当てを解除する必要があるかどうか。デフォルトは`false`です。 |

リクエスト例: 

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/:user_id"
```
