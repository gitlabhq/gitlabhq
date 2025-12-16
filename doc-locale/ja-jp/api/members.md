---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループおよびプロジェクトメンバーAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、グループメンバーやプロジェクトメンバーとやり取りします。

## ロール {#roles}

ユーザーまたはグループに割り当てられた[ロール](../user/permissions.md)は、`Gitlab::Access`モジュールで`access_level`として定義されています。

- アクセスなし（`0`）
- 最小アクセス（`5`）
- ゲスト（`10`）
- プランナー（`15`）
- レポーター（`20`）
- デベロッパー（`30`）
- メンテナー（`40`）
- オーナー（`50`）
- 管理者（`60`）

## 既知の問題 {#known-issues}

- `group_saml_identity`属性と`group_scim_identity`属性は、[SSOが有効なグループ](../user/group/saml_sso/_index.md)のグループオーナーのみに表示されます。
- APIリクエストがグループ自体、またはそのグループのサブグループまたはプロジェクトに送信される場合、`email`属性は、グループの[エンタープライズユーザー](../user/enterprise_user/_index.md)のグループオーナーのみに表示されます。

## グループまたはプロジェクトのすべてのメンバーをリストする {#list-all-members-of-a-group-or-project}

認証済みユーザーが表示可能なグループメンバーまたはプロジェクトメンバーのリストを取得します。祖先グループを介した継承メンバーや招待グループのメンバーではなく、直接メンバーのみを返します。

この関数は、ページネーションパラメータ`page`および`per_page`を受け取り、ユーザーのリストを制限します。

```plaintext
GET /groups/:id/members
GET /projects/:id/members
```

| 属性        | 型              | 必須 | 説明 |
|------------------|-------------------|----------|-------------|
| `id`             | 整数または文字列 | はい      | プロジェクトまたはグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `query`          | 文字列            | いいえ       | 指定された名前、メール、またはユーザー名に基づいて結果をフィルタリングします。クエリのスコープを広げるには、部分的な値を使用します。 |
| `user_ids`       | 整数の配列 | いいえ       | 指定されたユーザーIDで結果をフィルタリングします。 |
| `skip_users`     | 整数の配列 | いいえ       | スキップされたユーザーを結果から除外します。 |
| `show_seat_info` | ブール値           | いいえ       | ユーザーのシート情報を表示します。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members"
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
  }
]
```

## 継承メンバーと招待メンバーを含めて、グループまたはプロジェクトのすべてのメンバーをリストする {#list-all-members-of-a-group-or-project-including-inherited-and-invited-members}

{{< history >}}

- GitLab 16.10で`webui_members_inherited_users`[フラグ](../administration/feature_flags/_index.md)とともに、現在のユーザーが共有グループまたは共有プロジェクトのメンバーである場合に、招待されたプライベートグループのメンバーを返すように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/219230)されました。デフォルトでは無効になっています。
- GitLab 17.0の[GitLab.comとGitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230)で`webui_members_inherited_users`機能フラグが有効になりました。
- 機能フラグ`webui_members_inherited_users`は、GitLab 17.4で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163627)されました。招待グループのメンバーは、デフォルトで表示されます。

{{< /history >}}

認証済みユーザーが表示可能なグループメンバーまたはプロジェクトメンバーのリストを、祖先グループ経由で継承されたメンバー、招待されたユーザー、権限を含めて取得します。

ユーザーがこのグループまたはプロジェクト、および1つ以上の祖先グループのメンバーである場合、`access_level`がもっとも高いメンバーシップのみが返されます。これは、ユーザーの有効な権限を表します。

招待グループのメンバーは、次のいずれかの場合に返されます:

- 招待グループが公開されている。
- リクエスタも招待グループのメンバーである。
- リクエスタが共有グループまたは共有プロジェクトのメンバーである。

{{< alert type="note" >}}

招待グループのメンバーは、共有グループまたは共有プロジェクトでメンバーシップを共有しています。つまり、リクエスタが共有グループまたは共有プロジェクトのメンバーであるが、招待プライベートグループのメンバーではない場合、このエンドポイントを使用すると、リクエスタは、招待プライベートグループのメンバーを含む、すべての共有グループまたは共有プロジェクトのメンバーを取得できます。

{{< /alert >}}

この関数は、ページネーションパラメータ`page`および`per_page`を受け取り、ユーザーのリストを制限します。

```plaintext
GET /groups/:id/members/all
GET /projects/:id/members/all
```

| 属性        | 型              | 必須 | 説明 |
|------------------|-------------------|----------|-------------|
| `id`             | 整数または文字列 | はい      | プロジェクトまたはグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `query`          | 文字列            | いいえ       | 指定された名前、メール、またはユーザー名に基づいて結果をフィルタリングします。クエリのスコープを広げるには、部分的な値を使用します。 |
| `user_ids`       | 整数の配列 | いいえ       | 指定されたユーザーIDで結果をフィルタリングします。 |
| `show_seat_info` | ブール値           | いいえ       | ユーザーのシート情報を表示します。 |
| `state`          | 文字列            | いいえ       | メンバー状態（`awaiting`または`active`のいずれか）で結果をフィルタリングします。PremiumおよびUltimateのみ |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/all"
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

## グループまたはプロジェクトのメンバーを取得する {#get-a-member-of-a-group-or-project}

グループまたはプロジェクトのメンバーを取得します。祖先グループを介した継承メンバーではなく、直接メンバーのみを返します。

```plaintext
GET /groups/:id/members/:user_id
GET /projects/:id/members/:user_id
```

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトまたはグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id` | 整数           | はい      | メンバーのユーザーID。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:user_id"

curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/:user_id"
```

グループメンバーのカスタムロールを更新または削除するには、空の`member_role_id`値を渡します:

```shell
# Updates a project membership
curl --request PUT --header "Content-Type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --data '{"member_role_id": null, "access_level": 10}' "https://gitlab.example.com/api/v4/projects/<project_id>/members/<user_id>"

# Updates a group membership
curl --request PUT --header "Content-Type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --data '{"member_role_id": null, "access_level": 10}' "https://gitlab.example.com/api/v4/groups/<group_id>/members/<user_id>"
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

## 継承メンバーと招待メンバーを含めて、グループまたはプロジェクトのメンバーを取得する {#get-a-member-of-a-group-or-project-including-inherited-and-invited-members}

{{< history >}}

- GitLab 12.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17744)されました。
- GitLab 16.10で`webui_members_inherited_users`[フラグ](../administration/feature_flags/_index.md)とともに、現在のユーザーが共有グループまたは共有プロジェクトのメンバーである場合に、招待されたプライベートグループのメンバーを返すように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/219230)されました。デフォルトでは無効になっています。
- GitLab 17.0の[GitLab.comおよびGitLab Self-Managedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/219230)。
- 機能フラグ`webui_members_inherited_users`は、GitLab 17.4で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163627)されました。招待グループのメンバーは、デフォルトで表示されます。

{{< /history >}}

祖先グループを通じて継承または招待されたメンバーを含め、グループまたはプロジェクトのメンバーを取得します。詳細については、対応する[すべての継承メンバーをリストするためのエンドポイント](#list-all-members-of-a-group-or-project-including-inherited-and-invited-members)を参照してください。

{{< alert type="note" >}}

招待グループのメンバーは、共有グループまたは共有プロジェクトでメンバーシップを共有しています。つまり、リクエスタが共有グループまたは共有プロジェクトのメンバーであるが、招待プライベートグループのメンバーではない場合、このエンドポイントを使用すると、リクエスタは、招待プライベートグループのメンバーを含む、すべての共有グループまたは共有プロジェクトのメンバーを取得できます。

{{< /alert >}}

```plaintext
GET /groups/:id/members/all/:user_id
GET /projects/:id/members/all/:user_id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id`      | 整数または文字列 | はい | プロジェクトまたはグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id` | 整数 | はい   | メンバーのユーザーID。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/all/:user_id"
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

## グループのすべての請求対象メンバーをリストする {#list-all-billable-members-of-a-group}

請求対象としてカウントされるグループメンバーのリストを取得します。このリストには、サブグループとプロジェクトのメンバーが含まれています。

前提要件: 

- [請求権限](../user/free_user_limit.md)に示されているように、課金権限のAPIエンドポイントにアクセスするには、オーナーロールが必要です。
- このAPIエンドポイントは、トップレベルグループでのみ機能します。サブグループでは機能しません。

この関数は、[ページネーション](rest/_index.md#pagination)パラメータ`page`および`per_page`を受け取り、ユーザーのリストを制限します。

`search`パラメータを使用して名前で請求対象グループメンバーを検索し、`sort`を使用して結果を並べ替えます。

```plaintext
GET /groups/:id/billable_members
```

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `search`  | 文字列            | いいえ       | 名前、ユーザー名、または公開メールアドレスでグループメンバーを検索するためのクエリ文字列。 |
| `sort`    | 文字列            | いいえ       | 並べ替え属性と順序を指定するパラメータを含むクエリ文字列。以下にサポートされている値を示します。 |

`sort`属性でサポートされている値は次のとおりです:

| 値                   | 説明                  |
| ----------------------- | ---------------------------- |
| `access_level_asc`      | アクセスレベル、昇順      |
| `access_level_desc`     | アクセスレベル、降順     |
| `last_joined`           | 最終参加者                  |
| `name_asc`              | 名前、昇順              |
| `name_desc`             | 名前、降順             |
| `oldest_joined`         | 最古の参加者                |
| `oldest_sign_in`        | 最古のサインイン               |
| `recent_sign_in`        | 最近のサインイン               |
| `last_activity_on_asc`  | 最終活動日、昇順  |
| `last_activity_on_desc` | 最終活動日、降順 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/billable_members"
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
    "last_activity_on": "2021-01-27",
    "membership_type": "group_member",
    "removable": true,
    "created_at": "2021-01-03T12:16:02.000Z",
    "last_login_at": "2022-10-09T01:33:06.000Z"
  },
  {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "email": "john@example.com",
    "last_activity_on": "2021-01-25",
    "membership_type": "group_member",
    "removable": true,
    "created_at": "2021-01-04T18:46:42.000Z",
    "last_login_at": "2022-09-29T22:18:46.000Z"
  },
  {
    "id": 3,
    "username": "foo_bar",
    "name": "Foo bar",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "last_activity_on": "2021-01-20",
    "membership_type": "group_invite",
    "removable": false,
    "created_at": "2021-01-09T07:12:31.000Z",
    "last_login_at": "2022-10-10T07:28:56.000Z"
  }
]
```

## グループの請求対象メンバーのメンバーシップをリストする {#list-memberships-for-a-billable-member-of-a-group}

グループの請求対象メンバーについて、メンバーシップのリストを取得します。

前提要件: 

- 応答は、直接メンバーシップのみを表します。継承されたメンバーシップは含まれていません。
- このAPIエンドポイントは、トップレベルグループでのみ機能します。サブグループでは機能しません。
- このAPIエンドポイントを使用するには、グループのメンバーシップを管理するための権限が必要です。

ユーザーがメンバーであるすべてのプロジェクトとグループをリストします。グループ階層内のプロジェクトとグループのみが含まれます。たとえば、リクエストされたグループが`Top-Level Group`で、リクエストされたユーザーが`Top-Level Group / Subgroup One`と`Other Group / Subgroup Two`の両方の直接メンバーである場合、`Other Group / Subgroup Two`は`Top-Level Group`階層にないため、`Top-Level Group / Subgroup One`のみが返されます。

このAPIエンドポイントは、[ページネーション](rest/_index.md#pagination)パラメータ`page`と`per_page`を受け取り、メンバーシップのリストを制限します。

```plaintext
GET /groups/:id/billable_members/:user_id/memberships
```

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id` | 整数           | はい      | 請求対象メンバーのユーザーID。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/billable_members/:user_id/memberships"
```

レスポンス例:

```json
[
  {
    "id": 168,
    "source_id": 131,
    "source_full_name": "Top-Level Group / Subgroup One",
    "source_members_url": "https://gitlab.example.com/groups/root-group/sub-group-one/-/group_members",
    "created_at": "2021-03-31T17:28:44.812Z",
    "expires_at": "2022-03-21",
    "access_level": {
      "string_value": "Developer",
      "integer_value": 30
    }
  },
  {
    "id": 169,
    "source_id": 63,
    "source_full_name": "Top-Level Group / Subgroup One / My Project",
    "source_members_url": "https://gitlab.example.com/root-group/sub-group-one/my-project/-/project_members",
    "created_at": "2021-03-31T17:29:14.934Z",
    "expires_at": null,
    "access_level": {
      "string_value": "Maintainer",
      "integer_value": 40
    }
  }
]
```

## グループの請求対象メンバーの間接メンバーシップをリストする {#list-indirect-memberships-for-a-billable-member-of-a-group}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/386583)されました。

{{< /history >}}

グループの請求対象メンバーの間接的なメンバーシップのリストを取得します。

前提要件: 

- このAPIエンドポイントは、トップレベルグループでのみ機能します。サブグループでは機能しません。
- このAPIエンドポイントを使用するには、グループのメンバーシップを管理するための権限が必要です。

ユーザーがメンバーであることに加えて、リクエストされたトップレベルグループに招待されたすべてのプロジェクトとグループをリストします。たとえば、リクエストされたグループが`Top-Level Group`で、リクエストされたユーザーが`Other Group / Subgroup Two`（`Top-Level Group`に招待された）の直接メンバーである場合、`Other Group / Subgroup Two`のみが返されます。

応答は、間接メンバーシップのみをリストします。直接メンバーシップは含まれません。

このAPIエンドポイントは、[ページネーション](rest/_index.md#pagination)パラメータ`page`と`per_page`を受け取り、メンバーシップのリストを制限します。

```plaintext
GET /groups/:id/billable_members/:user_id/indirect
```

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id` | 整数           | はい      | 請求対象メンバーのユーザーID。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/billable_members/:user_id/indirect"
```

レスポンス例:

```json
[
  {
    "id": 168,
    "source_id": 132,
    "source_full_name": "Invited Group / Subgroup One",
    "source_members_url": "https://gitlab.example.com/groups/invited-group/sub-group-one/-/group_members",
    "created_at": "2021-03-31T17:28:44.812Z",
    "expires_at": "2022-03-21",
    "access_level": {
      "string_value": "Developer",
      "integer_value": 30
    }
  }
]
```

## グループから請求対象メンバーを削除する {#remove-a-billable-member-from-a-group}

{{< history >}}

- GitLab 13.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/217851)されました。

{{< /history >}}

グループとそのサブグループおよびプロジェクトから請求対象メンバーを削除します。

削除の対象となるユーザーがグループメンバーである必要はありません。たとえば、ユーザーがグループ内のプロジェクトに直接追加された場合でも、このAPIを使用してユーザーを削除できます。

{{< alert type="note" >}}

メンバーの削除は非同期的に処理されるため、変更は数分以内に完了します。

{{< /alert >}}

```plaintext
DELETE /groups/:id/billable_members/:user_id
```

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id` | 整数           | はい      | メンバーのユーザーID。 |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/billable_members/:user_id"
```

## グループ内のユーザーのメンバーシップ状態を変更する {#change-membership-state-of-a-user-in-a-group}

{{< history >}}

- GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86705)されました。

{{< /history >}}

グループ内のユーザーのメンバーシップ状態を変更します。

ユーザーが[無料ユーザーの制限](../user/free_user_limit.md)を超えている場合、グループまたはプロジェクトのユーザーメンバーシップ状態を`awaiting`または`active`に変更すると、ユーザーはそのグループまたはプロジェクトにアクセスできるようになります。この変更は、すべてのサブグループおよびプロジェクトに適用されます。

```plaintext
PUT /groups/:id/members/:user_id/state
```

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id` | 整数           | はい      | メンバーのユーザーID。 |
| `state`   | 文字列            | はい      | ユーザーの新しい状態。状態は`awaiting`か`active`のいずれかです。 |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:user_id/state?state=active"
```

レスポンス例:

```json
{
  "success":true
}
```

## グループまたはプロジェクトにメンバーを追加する {#add-a-member-to-a-group-or-project}

グループまたはプロジェクトにメンバーを追加します。

```plaintext
POST /groups/:id/members
POST /projects/:id/members
```

| 属性        | 型              | 必須                           | 説明 |
|------------------|-------------------|------------------------------------|-------------|
| `id`             | 整数または文字列 | はい                                | プロジェクトまたはグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`        | 整数または文字列 | はい（`username`が指定されていない場合） | 新しいメンバーのユーザーID、またはカンマで区切られた複数のID。 |
| `username`       | 文字列            | はい（`user_id`が指定されていない場合）  | 新しいメンバーのユーザー名、またはカンマで区切られた複数のユーザー名。 |
| `access_level`   | 整数           | はい                                | [有効なアクセスレベル](access_requests.md#valid-access-levels)。 |
| `expires_at`     | 文字列            | いいえ                                 | `YEAR-MONTH-DAY`形式の日付文字列。 |
| `invite_source`  | 文字列            | いいえ                                 | メンバー作成プロセスを開始する招待のソース。GitLabのチームメンバーは、この機密情報イシュー（`https://gitlab.com/gitlab-org/gitlab/-/issues/327120>`）で詳細情報を確認できます。 |
| `member_role_id` | 整数           | いいえ                                 | Ultimateのみ。カスタムメンバーロールのID。 |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1&access_level=30" "https://gitlab.example.com/api/v4/groups/:id/members"
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1&access_level=30" "https://gitlab.example.com/api/v4/projects/:id/members"
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

{{< alert type="note" >}}

[ロールのプロモーションに対する管理者の承認](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions)が有効になっている場合、既存のユーザーを請求対象のロールにプロモートするメンバーシップリクエストには、管理者による承認が必要です。

{{< /alert >}}

**Manage Non-Billable Promotions**（請求対象でないプロモーションの管理）を有効にするには、最初に`enable_member_promotion_management`アプリケーション設定を有効にする必要があります。

単一のユーザーをキューに入れる例:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1&access_level=30" "https://gitlab.example.com/api/v4/groups/:id/members"
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1&access_level=30" "https://gitlab.example.com/api/v4/projects/:id/members"
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
     --data "user_id=1,2&access_level=30" "https://gitlab.example.com/api/v4/groups/:id/members"
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1,2&access_level=30" "https://gitlab.example.com/api/v4/projects/:id/members"
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

## グループまたはプロジェクトのメンバーを編集する {#edit-a-member-of-a-group-or-project}

グループまたはプロジェクトのメンバーを更新します。

```plaintext
PUT /groups/:id/members/:user_id
PUT /projects/:id/members/:user_id
```

| 属性        | 型              | 必須 | 説明 |
|------------------|-------------------|----------|-------------|
| `id`             | 整数または文字列 | はい      | プロジェクトまたはグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`        | 整数           | はい      | メンバーのユーザーID。 |
| `access_level`   | 整数           | はい      | [有効なアクセスレベル](access_requests.md#valid-access-levels)。 |
| `expires_at`     | 文字列            | いいえ       | `YEAR-MONTH-DAY`形式の日付文字列。 |
| `member_role_id` | 整数           | いいえ       | Ultimateのみ。カスタムメンバーロールのID。値を指定しない場合は、すべてのロールを削除します。 |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:user_id?access_level=40"
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

{{< alert type="note" >}}

[ロールのプロモーションに対する管理者の承認](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions)が有効になっている場合、既存のユーザーを請求対象のロールにプロモートするメンバーシップリクエストには、管理者による承認が必要です。

{{< /alert >}}

**Manage non-billable promotions**（請求対象でないプロモーションの管理）を有効にするには、最初に`enable_member_promotion_management`アプリケーション設定を有効にする必要があります。

レスポンス例:

```json
{
  "message":{
    "username_1":"Request queued for administrator approval."
  }
}
```

### グループのメンバーにオーバーライドフラグを設定する {#set-override-flag-for-a-member-of-a-group}

デフォルトでは、LDAPグループメンバーのアクセスレベルは、グループ同期を通してLDAPによって指定された値に設定されます。このエンドポイントを呼び出すことで、アクセスレベルのオーバーライドを許可できます。

```plaintext
POST /groups/:id/members/:user_id/override
```

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id` | 整数           | はい      | メンバーのユーザーID。 |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:user_id/override"
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
  "override": true
}
```

### グループのメンバーに対するオーバーライドを削除する {#remove-override-for-a-member-of-a-group}

オーバーライドフラグをfalseに設定し、LDAPグループ同期が、アクセスレベルをLDAPで指定された値にリセットできるようにします。

```plaintext
DELETE /groups/:id/members/:user_id/override
```

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id` | 整数           | はい      | メンバーのユーザーID。 |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:user_id/override"
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
  "override": false
}
```

## グループまたはプロジェクトからメンバーを削除する {#remove-a-member-from-a-group-or-project}

ユーザーにロールが明示的に割り当てられているグループまたはプロジェクトから、ユーザーを削除します。

削除の対象となるユーザーがグループメンバーである必要があります。たとえば、ユーザーがグループ内のプロジェクトに直接追加されたが、このグループには明示的に追加されていない場合、このAPIを使用してユーザーを削除することはできません。代替アプローチについては、[グループから請求対象メンバーを削除する](#remove-a-billable-member-from-a-group)を参照してください。

```plaintext
DELETE /groups/:id/members/:user_id
DELETE /projects/:id/members/:user_id
```

| 属性            | 型              | 必須 | 説明 |
|----------------------|-------------------|----------|-------------|
| `id`                 | 整数または文字列 | はい      | プロジェクトまたはグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`            | 整数           | はい      | メンバーのユーザーID。 |
| `skip_subresources`  | ブール値           | false    | サブグループおよびプロジェクトの削除されたメンバーの直接メンバーシップを削除することをスキップするかどうか。デフォルトは`false`です。 |
| `unassign_issuables` | ブール値           | false    | 特定のグループまたはプロジェクト内で、イシューまたはマージリクエストから、削除されたメンバーの割り当てを解除する必要があるかどうか。デフォルトは`false`です。 |

リクエストの例:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:user_id"
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/:user_id"
```

## グループのメンバーを承認する {#approve-a-member-for-a-group}

グループとそのサブグループおよびプロジェクトに対して、保留中のユーザーを承認します。

```plaintext
PUT /groups/:id/members/:member_id/approve
```

| 属性   | 型              | 必須 | 説明 |
|-------------|-------------------|----------|-------------|
| `id`        | 整数または文字列 | はい      | トップレベルグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `member_id` | 整数           | はい      | メンバーのID。 |

リクエストの例:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:member_id/approve"
```

## グループの保留中のすべてのメンバーを承認する {#approve-all-pending-members-for-a-group}

グループとそのサブグループおよびプロジェクトに対して、保留中のすべてのユーザーを承認します。

```plaintext
POST /groups/:id/members/approve_all
```

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | トップレベルグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

リクエストの例:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/approve_all"
```

## グループとそのサブグループおよびプロジェクトの保留中のメンバーをリストする {#list-pending-members-of-a-group-and-its-subgroups-and-projects}

グループとそのサブグループおよびプロジェクトについて、`awaiting`状態のすべてのメンバーと、招待されているがGitLabアカウントを持っていないメンバーのリストを取得します。

前提要件: 

- このAPIエンドポイントは、トップレベルグループでのみ機能します。サブグループでは機能しません。
- このAPIエンドポイントには、グループのメンバーを管理するための権限が必要です。

このリクエストは、トップレベルグループの階層内のすべてのグループおよびプロジェクトから、一致するすべてのグループメンバーとプロジェクトメンバーを返します。

メンバーがまだGitLabアカウントにサインアップしていない招待ユーザーである場合、招待メールアドレスが返されます。

このAPIエンドポイントは、[ページネーション](rest/_index.md#pagination)パラメータ`page`と`per_page`を受け取り、メンバーのリストを制限します。

```plaintext
GET /groups/:id/pending_members
```

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/pending_members"
```

レスポンス例:

```json
[
  {
    "id": 168,
    "name": "Alex Garcia",
    "username": "alex_garcia",
    "email": "alex@example.com",
    "avatar_url": "http://example.com/uploads/user/avatar/1/cd8.jpeg",
    "web_url": "http://example.com/alex_garcia",
    "approved": false,
    "invited": false
  },
  {
    "id": 169,
    "email": "sidney@example.com",
    "avatar_url": "http://gravatar.com/../e346561cd8.jpeg",
    "approved": false,
    "invited": true
  },
  {
    "id": 170,
    "email": "zhang@example.com",
    "avatar_url": "http://gravatar.com/../e32131cd8.jpeg",
    "approved": true,
    "invited": true
  }
]
```

## プロジェクトにグループアクセスを付与する {#give-a-group-access-to-a-project}

[プロジェクトをグループで共有する](projects.md#share-a-project-with-a-group)を参照してください。
