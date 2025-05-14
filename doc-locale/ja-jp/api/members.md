---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: グループおよびプロジェクトメンバーAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、グループメンバーやプロジェクトメンバーとやり取りします。

## ロール

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

## 既知のイシュー

- `group_saml_identity`属性は、[SSOが有効なグループ](../user/group/saml_sso/_index.md)のグループオーナーのみに表示されます。
- APIリクエストがグループ自体、またはそのグループのサブグループまたはプロジェクトに送信される場合、`email`属性は、グループの[エンタープライズユーザー](../user/enterprise_user/_index.md)のグループオーナーのみに表示されます。

## グループまたはプロジェクトのすべてのメンバーをリストする

認証済みユーザーが表示できるグループまたはプロジェクトのメンバーのリストを取得します。祖先グループを介した継承メンバーではなく、直接メンバーのみを返します。

この関数は、ページネーションパラメーター`page`および`per_page`を受け取り、ユーザーのリストを制限します。

```plaintext
GET /groups/:id/members
GET /projects/:id/members
```

| 属性        | 型              | 必須 | 説明 |
|------------------|-------------------|----------|-------------|
| `id`             | 整数または文字列 | はい      | プロジェクトまたはグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `query`          | 文字列            | いいえ       | 指定された名前、メールアドレス、またはユーザー名に基づいて結果をフィルターします。クエリのスコープを広げるには、部分的な値を使用します。 |
| `user_ids`       | 整数の配列 | いいえ       | 指定されたユーザーIDに関する結果をフィルターします。 |
| `skip_users`     | 整数の配列 | いいえ       | スキップされたユーザーを結果から除外します。 |
| `show_seat_info` | ブール値           | いいえ       | ユーザーのシート情報を表示します。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members"
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members"
```

応答の例:

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

## 継承メンバーと招待メンバーを含めて、グループまたはプロジェクトのすべてのメンバーをリストする

{{< history >}}

- 現在のユーザーがGitLab 16.10の共有グループまたは共有プロジェクトのメンバーであり、`webui_members_inherited_users`という名前の[フラグ](../administration/feature_flags.md)が付いている場合、招待プライベートグループのメンバーを返すように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/219230)されました。デフォルトで無効になっています。
- 機能フラグ`webui_members_inherited_users`は、GitLab 17.0の[GitLab.comとGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/219230)になりました。
- 機能フラグ`webui_members_inherited_users`は、GitLab 17.4で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163627)されました。招待グループのメンバーは、デフォルトで表示されます。

{{< /history >}}

祖先グループを介した継承メンバー、招待ユーザー、権限を含めて、認証済みユーザーが表示できるグループメンバーまたはプロジェクトメンバーのリストを取得します。

ユーザーがこのグループまたはプロジェクトのメンバーであり、1つまたは複数の祖先グループのメンバーでもある場合、最高の`access_level`を持つメンバーシップのみが返されます。これは、ユーザーの有効な権限を表します。

招待グループのメンバーは、次のいずれかの場合に返されます。

- 招待グループが公開されている。
- リクエスタも招待グループのメンバーである。
- リクエスタが共有グループまたは共有プロジェクトのメンバーである。

{{< alert type="note" >}}

招待グループメンバーは、共有グループまたは共有プロジェクトでメンバーシップを共有しています。つまり、リクエスタが共有グループまたは共有プロジェクトのメンバーであるが、招待プライベートグループのメンバーではない場合、このエンドポイントを使用すると、リクエスタは、招待プライベートグループメンバーを含めて、すべての共有グループまたは共有プロジェクトのメンバーを取得できます。

{{< /alert >}}

この関数は、ページネーションパラメーター`page`および`per_page`を受け取り、ユーザーのリストを制限します。

```plaintext
GET /groups/:id/members/all
GET /projects/:id/members/all
```

| 属性        | 型              | 必須 | 説明 |
|------------------|-------------------|----------|-------------|
| `id`             | 整数または文字列 | はい      | プロジェクトまたはグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `query`          | 文字列            | いいえ       | 指定された名前、メールアドレス、またはユーザー名に基づいて結果をフィルターします。クエリのスコープを広げるには、部分的な値を使用します。 |
| `user_ids`       | 整数の配列 | いいえ       | 指定されたユーザーIDに関する結果をフィルターします。 |
| `show_seat_info` | ブール値           | いいえ       | ユーザーのシート情報を表示します。 |
| `state`          | 文字列            | いいえ       | メンバーの状態（`awaiting`と`active`のいずれか）で結果をフィルターします。PremiumおよびUltimateのみ。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/all"
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/all"
```

応答の例:

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

## グループまたはプロジェクトのメンバーを取得する

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

応答の例:

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

## 継承メンバーと招待メンバーを含めて、グループまたはプロジェクトのメンバーを取得する

{{< history >}}

- GitLab 12.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17744)されました。
- 現在のユーザーがGitLab 16.10の共有グループまたは共有プロジェクトのメンバーであり、`webui_members_inherited_users`という名前の[フラグ](../administration/feature_flags.md)が付いている場合、招待プライベートグループのメンバーを返すように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/219230)されました。デフォルトで無効になっています。
- GitLab 17.0の[GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/219230)になりました。
- 機能フラグ`webui_members_inherited_users`は、GitLab 17.4で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163627)されました。招待グループのメンバーは、デフォルトで表示されます。

{{< /history >}}

祖先グループを介して継承または招待されたメンバーを含めて、グループまたはプロジェクトのメンバーを取得します。詳細については、[すべての継承メンバーをリストする対応エンドポイント](#list-all-members-of-a-group-or-project-including-inherited-and-invited-members)を参照してください。

{{< alert type="note" >}}

招待グループメンバーは、共有グループまたは共有プロジェクトでメンバーシップを共有しています。つまり、リクエスタが共有グループまたは共有プロジェクトのメンバーであるが、招待プライベートグループのメンバーではない場合、このエンドポイントを使用すると、リクエスタは、招待プライベートグループメンバーを含めて、すべての共有グループまたは共有プロジェクトのメンバーを取得できます。

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

応答の例:

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

## グループのすべての請求可能メンバーをリストする

請求可能としてカウントされるグループメンバーのリストを取得します。このリストには、サブグループとプロジェクトのメンバーが含まれます。

前提要件:

- [請求権限](../user/free_user_limit.md)に示されているように、請求権限のAPIエンドポイントにアクセスするには、オーナーロールが必要です。
- このAPIエンドポイントは、トップレベルグループのみで機能します。サブグループでは機能しません。

この関数は、[ページネーション](rest/_index.md#pagination)パラメーター`page`と`per_page`を受け取り、ユーザーのリストを制限します。

`search`パラメーターを使用して、名前で請求可能グループメンバーを検索し、`sort`を使用して、結果を並べ替えます。

```plaintext
GET /groups/:id/billable_members
```

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `search`  | 文字列            | いいえ       | 名前、ユーザー名、または公開メールアドレスでグループメンバーを検索するためのクエリ文字列。 |
| `sort`    | 文字列            | いいえ       | 並べ替えの属性と順序を指定するパラメーターを含むクエリ文字列。以下のサポートされている値を参照してください。 |

`sort`属性でサポートされている値は次のとおりです。

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

応答の例:

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

## グループの請求可能メンバーのメンバーシップをリストする

グループの請求可能メンバーについて、メンバーシップのリストを取得します。

前提要件:

- 応答は直接メンバーシップのみを表します。継承メンバーシップは含まれません。
- このAPIエンドポイントは、トップレベルグループのみで機能します。サブグループでは機能しません。
- このAPIエンドポイントには、グループのメンバーシップを管理するための権限が必要です。

ユーザーがメンバーであるすべてのプロジェクトとグループをリストします。グループ階層内のプロジェクトとグループのみが含まれます。たとえば、リクエストされたグループが`Top-Level Group`であり、リクエストされたユーザーが`Top-Level Group / Subgroup One`と`Other Group / Subgroup Two`の両方の直接メンバーである場合、`Other Group / Subgroup Two`は`Top-Level Group`階層内にないため、`Top-Level Group / Subgroup One`のみが返されます。

このAPIエンドポイントは、[ページネーション](rest/_index.md#pagination)パラメーター`page`と`per_page`を受け取り、メンバーシップのリストを制限します。

```plaintext
GET /groups/:id/billable_members/:user_id/memberships
```

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id` | 整数           | はい      | 請求可能メンバーのユーザーID。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/billable_members/:user_id/memberships"
```

応答の例:

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

## グループの請求可能メンバーの間接メンバーシップをリストする

{{< details >}}

- 状態: Experiment版

{{< /details >}}

{{< history >}}

- GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/386583)されました。

{{< /history >}}

グループの請求可能メンバーについて、間接メンバーシップのリストを取得します。

前提要件:

- このAPIエンドポイントは、トップレベルグループのみで機能します。サブグループでは機能しません。
- このAPIエンドポイントには、グループのメンバーシップを管理するための権限が必要です。

ユーザーがメンバーであることに加えて、リクエストされたトップレベルグループに招待された、すべてのプロジェクトとグループをリストします。たとえば、リクエストされたグループが`Top-Level Group`であり、リクエストされたユーザーが`Other Group / Subgroup Two`（`Top-Level Group`に招待された）の直接メンバーである場合、`Other Group / Subgroup Two`のみが返されます。

応答は、間接メンバーシップのみをリストします。直接メンバーシップは含まれません。

このAPIエンドポイントは、[ページネーション](rest/_index.md#pagination)パラメーター`page`と`per_page`を受け取り、メンバーシップのリストを制限します。

```plaintext
GET /groups/:id/billable_members/:user_id/indirect
```

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id` | 整数           | はい      | 請求可能メンバーのユーザーID。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/billable_members/:user_id/indirect"
```

応答の例:

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

## グループから請求可能メンバーを削除する

{{< history >}}

- GitLab 13.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/217851)されました。

{{< /history >}}

グループとそのサブグループおよびプロジェクトから請求可能メンバーを削除します。

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

## グループ内のユーザーのメンバーシップ状態を変更する

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
| `state`   | 文字列            | はい      | ユーザーの新しい状態。状態は、`awaiting`と`active`のいずれかです。 |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:user_id/state?state=active"
```

応答の例:

```json
{
  "success":true
}
```

## グループまたはプロジェクトにメンバーを追加する

グループまたはプロジェクトにメンバーを追加します。

```plaintext
POST /groups/:id/members
POST /projects/:id/members
```

| 属性        | 型              | 必須                           | 説明 |
|------------------|-------------------|------------------------------------|-------------|
| `id`             | 整数または文字列 | はい                                | プロジェクトまたはグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`        | 整数または文字列 | はい（`username`が指定されていない場合） | 新しいメンバーのユーザーID、またはコンマで区切られた複数のID。 |
| `username`       | 文字列            | はい（`user_id`が指定されていない場合）  | 新しいメンバーのユーザー名、またはコンマで区切られた複数のユーザー名。 |
| `access_level`   | 整数           | はい                                | [有効なアクセスレベル](access_requests.md#valid-access-levels)。 |
| `expires_at`     | 文字列            | いいえ                                 | `YEAR-MONTH-DAY`形式の日付文字列。 |
| `invite_source`  | 文字列            | いいえ                                 | メンバー作成プロセスを開始する招待のソース。GitLabチームのメンバーは、この機密情報イシュー（`https://gitlab.com/gitlab-org/gitlab/-/issues/327120>`）で詳細情報を確認できます。 |
| `member_role_id` | 整数           | いいえ                                 | メンバーロールのID。Ultimateのみ。 |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1&access_level=30" "https://gitlab.example.com/api/v4/groups/:id/members"
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1&access_level=30" "https://gitlab.example.com/api/v4/projects/:id/members"
```

応答の例:

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

[ロールの昇格に対する管理者承認](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions)がオンになっている場合、既存のユーザーを請求可能ロールに昇格させるメンバーシップリクエストには、管理者承認が必要です。

{{< /alert >}}

**請求可能でない昇格の管理**を有効にするには、最初に`enable_member_promotion_management`アプリケーション設定を有効にする必要があります。

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

## グループまたはプロジェクトのメンバーを編集する

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
| `member_role_id` | 整数           | いいえ       | メンバーロールのID。Ultimateのみ。 |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:user_id?access_level=40"
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/:user_id?access_level=40"
```

応答の例:

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

[ロールの昇格に対する管理者承認](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions)がオンになっている場合、既存のユーザーを請求可能ロールに昇格させるメンバーシップリクエストには、管理者承認が必要です。

{{< /alert >}}

**請求可能でない昇格の管理**を有効にするには、最初に`enable_member_promotion_management`アプリケーション設定を有効にする必要があります。

応答の例:

```json
{
  "message":{
    "username_1":"Request queued for administrator approval."
  }
}
```

### グループのメンバーにオーバーライドフラグを設定する

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

応答の例:

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

### グループのメンバーに対するオーバーライドを削除する

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

応答の例:

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

## グループまたはプロジェクトからメンバーを削除する

ユーザーにロールが明示的に割り当てられているグループまたはプロジェクトから、ユーザーを削除します。

削除の対象となるユーザーがグループメンバーである必要があります。たとえば、ユーザーがグループ内のプロジェクトに直接追加されたが、このグループには明示的に追加されていない場合、このAPIを使用してユーザーを削除することはできません。代替アプローチについては、[グループから請求可能メンバーを削除する](#remove-a-billable-member-from-a-group)を参照してください。

```plaintext
DELETE /groups/:id/members/:user_id
DELETE /projects/:id/members/:user_id
```

| 属性            | 型              | 必須 | 説明 |
|----------------------|-------------------|----------|-------------|
| `id`                 | 整数または文字列 | はい      | プロジェクトまたはグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `user_id`            | 整数           | はい      | メンバーのユーザーID。 |
| `skip_subresources`  | ブール値           | false    | サブグループおよびプロジェクトの削除されたメンバーの直接メンバーシップを削除することをスキップするかどうか。デフォルトは`false`です。 |
| `unassign_issuables` | ブール値           | false    | 特定のグループまたはプロジェクト内で、イシューリクエストまたはマージリクエストから、削除されたメンバーの割り当てを解除する必要があるかどうか。デフォルトは`false`です。 |

リクエストの例:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/members/:user_id"
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/:user_id"
```

## グループのメンバーを承認する

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

## グループの保留中のすべてのメンバーを承認する

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

## グループとそのサブグループおよびプロジェクトの保留中のメンバーをリストする

グループとそのサブグループおよびプロジェクトについて、`awaiting`状態のすべてのメンバーと、招待されているがGitLabアカウントを持っていないメンバーのリストを取得します。

前提要件:

- このAPIエンドポイントは、トップレベルグループのみで機能します。サブグループでは機能しません。
- このAPIエンドポイントには、グループのメンバーを管理するための権限が必要です。

このリクエストは、トップレベルグループの階層内のすべてのグループおよびプロジェクトから、一致するすべてのグループメンバーとプロジェクトメンバーを返します。

メンバーがまだGitLabアカウントにサインアップしていない招待ユーザーである場合、招待メールアドレスが返されます。

このAPIエンドポイントは、[ページネーション](rest/_index.md#pagination)パラメーター`page`と`per_page`を受け取り、メンバーのリストを制限します。

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

応答の例:

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

## プロジェクトにグループアクセスを付与する

[プロジェクトをグループで共有する](projects.md#share-a-project-with-a-group)を参照してください
