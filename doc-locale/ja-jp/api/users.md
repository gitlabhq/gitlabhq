---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ユーザーAPI
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このREST APIでは、[アカウントの管理](../user/profile/_index.md)や[他のユーザーの管理](../user/profile/account/create_accounts.md)ができます。

## ユーザーをリストする

ユーザーのリストを取得します。

[ページネーション](rest/_index.md#offset-based-pagination)パラメーター`page`と`per_page`を取り、ユーザーのリストを制限します。

### 標準ユーザーとして

{{< history >}}

- キーセットページネーションは、GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/419556)されました。

{{< /history >}}

```plaintext
GET /users
```

サポートされている属性:

| 属性              | 型     | 必須 | 説明 |
|:-----------------------|:---------|:---------|:------------|
| `username`             | 文字列   | いいえ       | 特定のユーザー名を持つ1つのユーザーを取得します。 |
| `search`               | 文字列   | いいえ       | 名前、ユーザー名、または公開メールアドレスでユーザーを検索します。 |
| `active`               | ブール値  | いいえ       | アクティブユーザーのみをフィルタリングします。デフォルトは`false`です。 |
| `external`             | ブール値  | いいえ       | 外部ユーザーのみをフィルタリングします。デフォルトは`false`です。 |
| `blocked`              | ブール値  | いいえ       | ブロックされたユーザーのみをフィルタリングします。デフォルトは`false`です。 |
| `humans`               | ブール値  | いいえ       | ボットまたは内部ユーザーではない標準ユーザーのみをフィルタリングします。デフォルトは`false`です。 |
| `created_after`        | 日時 | いいえ       | 指定された時刻以降に作成されたユーザーを返します。 |
| `created_before`       | 日時 | いいえ       | 指定された時刻より前に作成されたユーザーを返します。 |
| `exclude_active`       | ブール値  | いいえ       | アクティブではないユーザーのみをフィルタリングします。デフォルトは`false`です。 |
| `exclude_external`     | ブール値  | いいえ       | 外部ユーザーではないユーザーのみをフィルタリングします。デフォルトは`false`です。 |
| `exclude_humans`       | ブール値  | いいえ       | ボットまたは内部ユーザーのみをフィルタリングします。デフォルトは`false`です。 |
| `exclude_internal`     | ブール値  | いいえ       | 内部ユーザーではないユーザーのみをフィルタリングします。デフォルトは`false`です。 |
| `without_project_bots` | ブール値  | いいえ       | プロジェクトボットのないユーザーをフィルタリングします。デフォルトは`false`です。 |

応答の例:

```json
[
  {
    "id": 1,
    "username": "john_smith",
    "name": "John Smith",
    "state": "active",
    "locked": false,
    "avatar_url": "http://localhost:3000/uploads/user/avatar/1/cd8.jpeg",
    "web_url": "http://localhost:3000/john_smith"
  },
  {
    "id": 2,
    "username": "jack_smith",
    "name": "Jack Smith",
    "state": "blocked",
    "locked": false,
    "avatar_url": "http://gravatar.com/../e32131cd8.jpeg",
    "web_url": "http://localhost:3000/jack_smith"
  }
]
```

このエンドポイントは、[キーセットページネーション](rest/_index.md#keyset-based-pagination)をサポートしています。GitLab 17.0以降では、応答の数が50,000件以上の場合にはキーセットページネーションが必要です。

`?search=`を使用して、名前、ユーザー名、または公開メールアドレスでユーザーを検索することもできます。たとえば`/users?search=John`などです。検索対象に応じて、次のようになります。

- 公開メールアドレスを検索する場合、完全一致する結果を取得するには、完全なメールアドレスを使用する必要があります。
- 名前またはユーザー名を検索する場合、これはあいまい検索であるため、完全一致する結果を得る必要はありません。

さらに、ユーザー名でユーザーを検索できます。

```plaintext
GET /users?username=:username
```

次に例を示します。

```plaintext
GET /users?username=jack_smith
```

{{< alert type="note" >}}

ユーザー名の検索では大文字と小文字は区別されません。

{{< /alert >}}

`blocked`状態と`active`状態に基づいてユーザーをフィルタリングできます。`active=false`と`blocked=false`はサポートされていません。

```plaintext
GET /users?active=true
```

```plaintext
GET /users?blocked=true
```

さらに、`external=true`を使用して外部ユーザーのみを検索できます。`external=false`はサポートされていません。

```plaintext
GET /users?external=true
```

GitLabは、[アラートボット](../operations/incident_management/integrations.md)や[サポートボット](../user/project/service_desk/configure.md#support-bot-user)などのボットユーザーをサポートしています。`exclude_internal=true`パラメーターを使用して、ユーザーリストから次の種類の[内部ユーザー](../administration/internal_users.md)を除外できます。

- アラートボット
- サポートボット

ただしこのアクションでは、[プロジェクトのボットユーザー](../user/project/settings/project_access_tokens.md#bot-users-for-projects)または[グループのボットユーザー](../user/group/settings/group_access_tokens.md#bot-users-for-groups)は除外されません。

```plaintext
GET /users?exclude_internal=true
```

ユーザーリストから外部ユーザーを除外するには、パラメーター`exclude_external=true`を使用できます。

```plaintext
GET /users?exclude_external=true
```

[プロジェクトのボットユーザー](../user/project/settings/project_access_tokens.md#bot-users-for-projects)と[グループのボットユーザー](../user/group/settings/group_access_tokens.md#bot-users-for-groups)を除外するには、パラメーター`without_project_bots=true`を使用できます。

```plaintext
GET /users?without_project_bots=true
```

### 管理者として

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 応答の`created_by`フィールドはGitLab 15.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93092)されました。
- 応答の`scim_identities`フィールドはGitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/324247)されました。
- 応答の`auditors`フィールドはGitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/418023)されました。
- 応答の`email_reset_offered_at`フィールドはGitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137610)されました。

{{< /history >}}

```plaintext
GET /users
```

[すべてのユーザーが利用できるパラメーター](#as-a-regular-user)の他に、管理者のみが利用できる次の属性があります。

サポートされている属性:

| 属性          | 型    | 必須 | 説明 |
|:-------------------|:--------|:---------|:------------|
| `search`           | 文字列  | いいえ       | 名前、ユーザー名、公開メールアドレス、または非公開メールアドレスでユーザーを検索します。 |
| `extern_uid`       | 文字列  | いいえ       | 特定の外部認証プロバイダーの固有識別子（UID）を持つ1つのユーザーを取得します。 |
| `provider`         | 文字列  | いいえ       | 外部プロバイダー。 |
| `order_by`         | 文字列  | いいえ       | `id`、`name`、`username`、`created_at`、または`updated_at`フィールドでユーザーを並べ替えて返します。デフォルトは`id`です。 |
| `sort`             | 文字列  | いいえ       | `asc`または`desc`の順にソートされたユーザーを返します。デフォルトは`desc`です。 |
| `two_factor`       | 文字列  | いいえ       | 2要素認証でユーザーをフィルタリングします。フィルターの値は`enabled`または`disabled`です。デフォルトでは、すべてのユーザーが返されます。 |
| `without_projects` | ブール値 | いいえ       | プロジェクトのないユーザーをフィルタリングします。デフォルトは`false`です。これは、プロジェクトの有無にかかわらず、すべてのユーザーが返されることを意味します。 |
| `admins`           | ブール値 | いいえ       | 管理者のみを返します。デフォルトは`false`です。 |
| `auditors`         | ブール値 | いいえ       | 監査担当者ユーザーのみを返します。デフォルトは`false`です。含まれていない場合、すべてのユーザーが返されます。PremiumおよびUltimateのみ。 |
| `saml_provider_id` | 数値  | いいえ       | 指定されたSAMLプロバイダーIDで作成されたユーザーのみを返します。含まれていない場合、すべてのユーザーが返されます。PremiumおよびUltimateのみ。 |
| `skip_ldap`        | ブール値 | いいえ       | LDAPユーザーをスキップします。PremiumおよびUltimateのみ。 |

応答の例:

```json
[
  {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "locked": false,
    "avatar_url": "http://localhost:3000/uploads/user/avatar/1/index.jpg",
    "web_url": "http://localhost:3000/john_smith",
    "created_at": "2012-05-23T08:00:58Z",
    "is_admin": false,
    "bio": "",
    "location": null,
    "skype": "",
    "linkedin": "",
    "twitter": "",
    "discord": "",
    "website_url": "",
    "organization": "",
    "job_title": "",
    "last_sign_in_at": "2012-06-01T11:41:01Z",
    "confirmed_at": "2012-05-23T09:05:22Z",
    "theme_id": 1,
    "last_activity_on": "2012-05-23",
    "color_scheme_id": 2,
    "projects_limit": 100,
    "current_sign_in_at": "2012-06-02T06:36:55Z",
    "note": "DMCA Request: 2018-11-05 | DMCA Violation | Abuse | https://gitlab.zendesk.com/agent/tickets/123",
    "identities": [
      {"provider": "github", "extern_uid": "2435223452345"},
      {"provider": "bitbucket", "extern_uid": "john.smith"},
      {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"}
    ],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": true,
    "external": false,
    "private_profile": false,
    "current_sign_in_ip": "196.165.1.102",
    "last_sign_in_ip": "172.127.2.22",
    "namespace_id": 1,
    "created_by": null,
    "email_reset_offered_at": null
  },
  {
    "id": 2,
    "username": "jack_smith",
    "email": "jack@example.com",
    "name": "Jack Smith",
    "state": "blocked",
    "locked": false,
    "avatar_url": "http://localhost:3000/uploads/user/avatar/2/index.jpg",
    "web_url": "http://localhost:3000/jack_smith",
    "created_at": "2012-05-23T08:01:01Z",
    "is_admin": false,
    "bio": "",
    "location": null,
    "skype": "",
    "linkedin": "",
    "twitter": "",
    "discord": "",
    "website_url": "",
    "organization": "",
    "job_title": "",
    "last_sign_in_at": null,
    "confirmed_at": "2012-05-30T16:53:06.148Z",
    "theme_id": 1,
    "last_activity_on": "2012-05-23",
    "color_scheme_id": 3,
    "projects_limit": 100,
    "current_sign_in_at": "2014-03-19T17:54:13Z",
    "identities": [],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": true,
    "external": false,
    "private_profile": false,
    "current_sign_in_ip": "10.165.1.102",
    "last_sign_in_ip": "172.127.2.22",
    "namespace_id": 2,
    "created_by": null,
    "email_reset_offered_at": null
  }
]
```

[GitLab PremiumまたはUltimate](https://about.gitlab.com/pricing/)のユーザーには、`shared_runners_minutes_limit`、`extra_shared_runners_minutes_limit`、`is_auditor`、`using_license_seat`パラメーターも表示されます。

```json
[
  {
    "id": 1,
    ...
    "shared_runners_minutes_limit": 133,
    "extra_shared_runners_minutes_limit": 133,
    "is_auditor": false,
    "using_license_seat": true
    ...
  }
]
```

[GitLab PremiumまたはUltimate](https://about.gitlab.com/pricing/)のユーザーには、`group_saml`プロバイダーオプションと`provisioned_by_group_id`パラメーターも表示されます。

```json
[
  {
    "id": 1,
    ...
    "identities": [
      {"provider": "github", "extern_uid": "2435223452345"},
      {"provider": "bitbucket", "extern_uid": "john.smith"},
      {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"},
      {"provider": "group_saml", "extern_uid": "123789", "saml_provider_id": 10}
    ],
    "provisioned_by_group_id": 123789
    ...
  }
]
```

`?search=`を使用して、名前、ユーザー名、またはメールアドレスでユーザーを検索することもできます。たとえば`/users?search=John`などです。検索対象に応じて、次のようになります。

- メールアドレスを検索する場合、完全一致する結果を取得するには、完全なメールアドレスを使用する必要があります。管理者は公開メールアドレスと非公開メールアドレスの両方を検索できます。
- 名前またはユーザー名を検索する場合、これはあいまい検索であるため、完全一致する結果を得る必要はありません。

外部固有識別子（UID）とプロバイダーを使用してユーザーを検索できます。

```plaintext
GET /users?extern_uid=:extern_uid&provider=:provider
```

次に例を示します。

```plaintext
GET /users?extern_uid=1234567&provider=github
```

[GitLab PremiumまたはUltimate](https://about.gitlab.com/pricing/)のユーザーは、`scim`プロバイダーを使用できます。

```plaintext
GET /users?extern_uid=1234567&provider=scim
```

作成日時範囲でユーザーを検索するには、以下を使用します。

```plaintext
GET /users?created_before=2001-01-02T00:00:00.060Z&created_after=1999-01-02T00:00:00.060
```

プロジェクトのないユーザーを検索するには、`/users?without_projects=true`を使用します。

[カスタム属性](custom_attributes.md)でフィルタリングするには、以下を使用します。

```plaintext
GET /users?custom_attributes[key]=value&custom_attributes[other_key]=other_value
```

応答にユーザーの[カスタム属性](custom_attributes.md)を含めるには、以下を使用します。

```plaintext
GET /users?with_custom_attributes=true
```

`created_by`パラメーターを使用して、ユーザーアカウントが以下のように作成されたかどうかを確認できます。

- [管理者により手動](../user/profile/account/create_accounts.md#create-users-in-admin-area)で作成される。
- [プロジェクトボットユーザー](../user/project/settings/project_access_tokens.md#bot-users-for-projects)として作成される。

返された値が`null`の場合、アカウントを自分自身で登録したユーザーによってそのアカウントが作成されています。

## 1つのユーザーを取得する

1つのユーザーを取得します。

### 標準ユーザーとして

標準ユーザーとして1つのユーザーを取得します。

前提要件:

- このエンドポイントを使用するには、サインインする必要があります。

```plaintext
GET /users/:id
```

サポートされている属性:

| 属性 | 型    | 必須 | 説明 |
|:----------|:--------|:---------|:------------|
| `id`      | 整数 | はい      | ユーザーのID |

応答の例:

```json
{
  "id": 1,
  "username": "john_smith",
  "name": "John Smith",
  "state": "active",
  "locked": false,
  "avatar_url": "http://localhost:3000/uploads/user/avatar/1/cd8.jpeg",
  "web_url": "http://localhost:3000/john_smith",
  "created_at": "2012-05-23T08:00:58Z",
  "bio": "",
  "bot": false,
  "location": null,
  "public_email": "john@example.com",
  "skype": "",
  "linkedin": "",
  "twitter": "",
  "discord": "",
  "website_url": "",
  "organization": "",
  "job_title": "Operations Specialist",
  "pronouns": "he/him",
  "work_information": null,
  "followers": 1,
  "following": 1,
  "local_time": "3:38 PM",
  "is_followed": false
}
```

### 管理者として

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 応答の`created_by`フィールドはGitLab 15.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93092)されました。
- 応答の`email_reset_offered_at`フィールドはGitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137610)されました。

{{< /history >}}

管理者として1つのユーザーを取得します。

```plaintext
GET /users/:id
```

サポートされている属性:

| 属性 | 型    | 必須 | 説明 |
|:----------|:--------|:---------|:------------|
| `id`      | 整数 | はい      | ユーザーのID |

応答の例:

```json
{
  "id": 1,
  "username": "john_smith",
  "email": "john@example.com",
  "name": "John Smith",
  "state": "active",
  "locked": false,
  "avatar_url": "http://localhost:3000/uploads/user/avatar/1/index.jpg",
  "web_url": "http://localhost:3000/john_smith",
  "created_at": "2012-05-23T08:00:58Z",
  "is_admin": false,
  "bio": "",
  "location": null,
  "public_email": "john@example.com",
  "skype": "",
  "linkedin": "",
  "twitter": "",
  "discord": "",
  "website_url": "",
  "organization": "",
  "job_title": "Operations Specialist",
  "pronouns": "he/him",
  "work_information": null,
  "followers": 1,
  "following": 1,
  "local_time": "3:38 PM",
  "last_sign_in_at": "2012-06-01T11:41:01Z",
  "confirmed_at": "2012-05-23T09:05:22Z",
  "theme_id": 1,
  "last_activity_on": "2012-05-23",
  "color_scheme_id": 2,
  "projects_limit": 100,
  "current_sign_in_at": "2012-06-02T06:36:55Z",
  "note": "DMCA Request: 2018-11-05 | DMCA Violation | Abuse | https://gitlab.zendesk.com/agent/tickets/123",
  "identities": [
    {"provider": "github", "extern_uid": "2435223452345"},
    {"provider": "bitbucket", "extern_uid": "john.smith"},
    {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"}
  ],
  "can_create_group": true,
  "can_create_project": true,
  "two_factor_enabled": true,
  "external": false,
  "private_profile": false,
  "commit_email": "john-codes@example.com",
  "current_sign_in_ip": "196.165.1.102",
  "last_sign_in_ip": "172.127.2.22",
  "plan": "gold",
  "trial": true,
  "sign_in_count": 1337,
  "namespace_id": 1,
  "created_by": null,
  "email_reset_offered_at": null
}
```

{{< alert type="note" >}}

`plan`パラメーターと`trial`パラメーターは、GitLab Enterpriseエディションでのみ使用できます。

{{< /alert >}}

[GitLab PremiumまたはUltimate](https://about.gitlab.com/pricing/)のユーザーには、`shared_runners_minutes_limit`、`is_auditor`、`extra_shared_runners_minutes_limit`パラメーターも表示されます。

```json
{
  "id": 1,
  "username": "john_smith",
  "is_auditor": false,
  "shared_runners_minutes_limit": 133,
  "extra_shared_runners_minutes_limit": 133,
  ...
}
```

[GitLab.com PremiumまたはUltimate](https://about.gitlab.com/pricing/)のユーザーには、`group_saml`オプションと`provisioned_by_group_id`パラメーターも表示されます。

```json
{
  "id": 1,
  "username": "john_smith",
  "shared_runners_minutes_limit": 133,
  "extra_shared_runners_minutes_limit": 133,
  "identities": [
    {"provider": "github", "extern_uid": "2435223452345"},
    {"provider": "bitbucket", "extern_uid": "john.smith"},
    {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"},
    {"provider": "group_saml", "extern_uid": "123789", "saml_provider_id": 10}
  ],
  "provisioned_by_group_id": 123789
  ...
}
```

[GitLab.com PremiumまたはUltimate](https://about.gitlab.com/pricing/)のユーザーには、`scim_identities`パラメーターも表示されます。

```json
{
  ...
  "extra_shared_runners_minutes_limit": null,
  "scim_identities": [
      {"extern_uid": "2435223452345", "group_id": "3", "active": true},
      {"extern_uid": "john.smith", "group_id": "42", "active": false}
    ]
  ...
}
```

管理者は`created_by`パラメーターを使用して、ユーザーアカウントが次のように作成されたかどうかを確認できます。

- [管理者により手動](../user/profile/account/create_accounts.md#create-users-in-admin-area)で作成される。
- [プロジェクトボットユーザー](../user/project/settings/project_access_tokens.md#bot-users-for-projects)として作成される。

返された値が`null`の場合、アカウントを自分自身で登録したユーザーによってそのアカウントが作成されています。

応答にユーザーの[カスタム属性](custom_attributes.md)を含めるには、以下を使用します。

```plaintext
GET /users/:id?with_custom_attributes=true
```

## 現在のユーザーを取得する

現在のユーザーを取得します。

### 標準ユーザーとして

ユーザーの詳細を取得します。

```plaintext
GET /user
```

応答の例:

```json
{
  "id": 1,
  "username": "john_smith",
  "email": "john@example.com",
  "name": "John Smith",
  "state": "active",
  "locked": false,
  "avatar_url": "http://localhost:3000/uploads/user/avatar/1/index.jpg",
  "web_url": "http://localhost:3000/john_smith",
  "created_at": "2012-05-23T08:00:58Z",
  "bio": "",
  "location": null,
  "public_email": "john@example.com",
  "skype": "",
  "linkedin": "",
  "twitter": "",
  "discord": "",
  "website_url": "",
  "organization": "",
  "job_title": "",
  "pronouns": "he/him",
  "bot": false,
  "work_information": null,
  "followers": 0,
  "following": 0,
  "local_time": "3:38 PM",
  "last_sign_in_at": "2012-06-01T11:41:01Z",
  "confirmed_at": "2012-05-23T09:05:22Z",
  "theme_id": 1,
  "last_activity_on": "2012-05-23",
  "color_scheme_id": 2,
  "projects_limit": 100,
  "current_sign_in_at": "2012-06-02T06:36:55Z",
  "identities": [
    {"provider": "github", "extern_uid": "2435223452345"},
    {"provider": "bitbucket", "extern_uid": "john_smith"},
    {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"}
  ],
  "can_create_group": true,
  "can_create_project": true,
  "two_factor_enabled": true,
  "external": false,
  "private_profile": false,
  "commit_email": "admin@example.com",
}
```

[GitLab PremiumまたはUltimate](https://about.gitlab.com/pricing/)のユーザーには、`shared_runners_minutes_limit`、`extra_shared_runners_minutes_limit`パラメーターも表示されます。

### 管理者として

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 応答の`created_by`フィールドはGitLab 15.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93092)されました。
- 応答の`email_reset_offered_at`フィールドはGitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137610)されました。

{{< /history >}}

ユーザーの詳細、または別のユーザーの詳細を取得します。

```plaintext
GET /user
```

サポートされている属性:

| 属性 | 型    | 必須 | 説明 |
|:----------|:--------|:---------|:------------|
| `sudo`    | 整数 | いいえ       | 特定のユーザーの権限で呼び出しを実行するための、このユーザーのID。 |

```json
{
  "id": 1,
  "username": "john_smith",
  "email": "john@example.com",
  "name": "John Smith",
  "state": "active",
  "locked": false,
  "avatar_url": "http://localhost:3000/uploads/user/avatar/1/index.jpg",
  "web_url": "http://localhost:3000/john_smith",
  "created_at": "2012-05-23T08:00:58Z",
  "is_admin": true,
  "bio": "",
  "location": null,
  "public_email": "john@example.com",
  "skype": "",
  "linkedin": "",
  "twitter": "",
  "discord": "",
  "website_url": "",
  "organization": "",
  "job_title": "",
  "last_sign_in_at": "2012-06-01T11:41:01Z",
  "confirmed_at": "2012-05-23T09:05:22Z",
  "theme_id": 1,
  "last_activity_on": "2012-05-23",
  "color_scheme_id": 2,
  "projects_limit": 100,
  "current_sign_in_at": "2012-06-02T06:36:55Z",
  "identities": [
    {"provider": "github", "extern_uid": "2435223452345"},
    {"provider": "bitbucket", "extern_uid": "john_smith"},
    {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"}
  ],
  "can_create_group": true,
  "can_create_project": true,
  "two_factor_enabled": true,
  "external": false,
  "private_profile": false,
  "commit_email": "john-codes@example.com",
  "current_sign_in_ip": "196.165.1.102",
  "last_sign_in_ip": "172.127.2.22",
  "namespace_id": 1,
  "created_by": null,
  "email_reset_offered_at": null,
  "note": null
}
```

[GitLab PremiumまたはUltimate](https://about.gitlab.com/pricing/)のユーザーには、次のパラメーターも表示されます。

- `shared_runners_minutes_limit`
- `extra_shared_runners_minutes_limit`
- `is_auditor`
- `provisioned_by_group_id`
- `using_license_seat`

## ユーザーを作成する

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 監査担当者ユーザーを作成する機能は、GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/366404)されました。

{{< /history >}}

ユーザーを作成します。

前提要件:

- 管理者である必要があります。

ユーザーを作成するときには、次のうち少なくとも1つを指定する必要があります。

- `password`
- `reset_password`
- `force_random_password`

`reset_password`と`force_random_password`の両方が`false`の場合、`password`が必要です。

`force_random_password`と`reset_password`は`password`よりも優先されます。また、`reset_password`と`force_random_password`を組み合わせて使用することもできます。

{{< alert type="note" >}}

`private_profile`は、[新しいユーザーのプロファイルをデフォルトで非公開に設定](../administration/settings/account_and_limit_settings.md#set-profiles-of-new-users-to-private-by-default)の値にデフォルト設定されます。`bio`は、デフォルトでは`null`ではなく`""`に設定されます。

{{< /alert >}}

```plaintext
POST /users
```

サポートされている属性:

| 属性                            | 必須 | 説明 |
|:-------------------------------------|:---------|:------------|
| `admin`                              | いいえ       | ユーザーは管理者です。有効な値は`true`または`false`です。デフォルトはfalseです。 |
| `auditor`                            | いいえ       | ユーザーは監査担当者です。有効な値は`true`または`false`です。デフォルトはfalseです。GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/366404)されました。PremiumおよびUltimateのみ。 |
| `avatar`                             | いいえ       | ユーザーのアバターの画像ファイル |
| `bio`                                | いいえ       | ユーザーの経歴 |
| `can_create_group`                   | いいえ       | ユーザーがトップレベルグループを作成できるかどうか（trueまたはfalse）。 |
| `color_scheme_id`                    | いいえ       | ファイルビューアーのユーザーの配色（詳細については、[ユーザー設定のドキュメント](../user/profile/preferences.md#change-the-syntax-highlighting-theme)を参照してください）。 |
| `commit_email`                       | いいえ       | ユーザーのコミットメールアドレス |
| `email`                              | はい      | メール       |
| `extern_uid`                         | いいえ       | 外部固有識別子（UID） |
| `external`                           | いいえ       | ユーザーを外部としてフラグ設定します（trueまたはfalse（デフォルト））。 |
| `extra_shared_runners_minutes_limit` | いいえ       | 管理者のみが設定できます。このユーザーの追加のコンピューティング時間です。PremiumおよびUltimateのみ。 |
| `force_random_password`              | いいえ       | ユーザーパスワードをランダムな値に設定します（trueまたはfalse（デフォルト））。 |
| `group_id_for_saml`                  | いいえ       | SAMLが設定されているグループのID |
| `linkedin`                           | いいえ       | LinkedIn    |
| `location`                           | いいえ       | ユーザーの場所 |
| `name`                               | はい      | 名前        |
| `note`                               | いいえ       | このユーザーの管理者ノート |
| `organization`                       | いいえ       | 組織名 |
| `password`                           | いいえ       | パスワード    |
| `private_profile`                    | いいえ       | ユーザーのプロファイルは非公開です（trueまたはfalse）。デフォルト値は、[設定](../administration/settings/account_and_limit_settings.md#set-profiles-of-new-users-to-private-by-default)によって決まります。 |
| `projects_limit`                     | いいえ       | ユーザーが作成できるプロジェクトの数 |
| `pronouns`                           | いいえ       | ユーザーの代名詞 |
| `provider`                           | いいえ       | 外部プロバイダー名 |
| `public_email`                       | いいえ       | ユーザーの公開メールアドレス |
| `reset_password`                     | いいえ       | ユーザーパスワードリセットリンクを送信します（trueまたはfalse（デフォルト））。 |
| `shared_runners_minutes_limit`       | いいえ       | 管理者のみが設定できます。このユーザーの1か月あたりのコンピューティング時間の最大数。`nil`（デフォルト、システムのデフォルトを継承）、`0`（無制限）、または`> 0`のいずれかですPremiumおよびUltimateのみ。 |
| `skip_confirmation`                  | いいえ       | 確認をスキップします（trueまたはfalse（デフォルト））。 |
| `skype`                              | いいえ       | Skype ID    |
| `theme_id`                           | いいえ       | ユーザーのGitLabテーマ（詳細については、[ユーザー設定のドキュメント](../user/profile/preferences.md#change-the-color-theme)を参照してください）。 |
| `twitter`                            | いいえ       | X（旧Twitter）アカウント |
| `discord`                            | いいえ       | Discordアカウント |
| `username`                           | はい      | ユーザー名    |
| `view_diffs_file_by_file`            | いいえ       | ユーザーに対し1ページあたり1つのファイル差分のみを表示することを示すフラグ。 |
| `website_url`                        | いいえ       | WebサイトのURL |

## ユーザーを変更する

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 監査担当者ユーザーを変更する機能は、GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/366404)されました。

{{< /history >}}

既存のユーザーを変更します。

前提要件:

- 管理者である必要があります。

`email`フィールドは、ユーザーのプライマリメールアドレスです。このフィールドを変更する場合、そのユーザーに既に追加されているセカンダリメールアドレスのみに変更できます。同じユーザーにさらにメールアドレスを追加するには、[メールエンドポイントを追加](user_email_addresses.md#add-an-email-address)を使用します。

```plaintext
PUT /users/:id
```

サポートされている属性:

| 属性                            | 必須 | 説明 |
|:-------------------------------------|:---------|:------------|
| `admin`                              | いいえ       | ユーザーは管理者です。有効な値は`true`または`false`です。デフォルトはfalseです。 |
| `auditor`                            | いいえ       | ユーザーは監査担当者です。有効な値は`true`または`false`です。デフォルトはfalseです。GitLab 15.3[で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/366404)されました。（デフォルト）PremiumとUltimateのみ。 |
| `avatar`                             | いいえ       | ユーザーのアバターの画像ファイル |
| `bio`                                | いいえ       | ユーザーの経歴 |
| `can_create_group`                   | いいえ       | ユーザーがグループを作成できるかどうか（trueまたはfalse）。 |
| `color_scheme_id`                    | いいえ       | ファイルビューアーのユーザーの配色（詳細については、[ユーザー設定のドキュメント](../user/profile/preferences.md#change-the-syntax-highlighting-theme)を参照してください）。 |
| `commit_email`                       | いいえ       | ユーザーのコミットメール。非公開のコミットメールを使用するには、`_private`に設定します。GitLab 15.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/375148)されました。 |
| `email`                              | いいえ       | メール       |
| `extern_uid`                         | いいえ       | 外部固有識別子（UID） |
| `external`                           | いいえ       | ユーザーを外部としてフラグ設定します（trueまたはfalse（デフォルト））。 |
| `extra_shared_runners_minutes_limit` | いいえ       | 管理者のみが設定できます。このユーザーの追加のコンピューティング時間です。PremiumおよびUltimateのみ。 |
| `group_id_for_saml`                  | いいえ       | SAMLが設定されているグループのID |
| `id`                                 | はい      | ユーザーのID |
| `linkedin`                           | いいえ       | LinkedIn    |
| `location`                           | いいえ       | ユーザーの場所 |
| `name`                               | いいえ       | 名前        |
| `note`                               | いいえ       | このユーザーの管理ノート |
| `organization`                       | いいえ       | 組織名 |
| `password`                           | いいえ       | パスワード    |
| `private_profile`                    | いいえ       | ユーザーのプロファイルは非公開です（trueまたはfalse）。 |
| `projects_limit`                     | いいえ       | 各ユーザーが作成できるプロジェクト数を制限します |
| `pronouns`                           | いいえ       | 代名詞    |
| `provider`                           | いいえ       | 外部プロバイダー名 |
| `public_email`                       | いいえ       | ユーザーの公開メール（すでに検証済みである必要があります）。 |
| `shared_runners_minutes_limit`       | いいえ       | 管理者のみが設定できます。このユーザーの1か月あたりのコンピューティング時間の最大数。`nil`（デフォルト、システムのデフォルトを継承）、`0`（無制限）、または`> 0`のいずれかですPremiumおよびUltimateのみ。 |
| `skip_reconfirmation`                | いいえ       | 確認をスキップします（trueまたはfalse（デフォルト））。 |
| `skype`                              | いいえ       | Skype ID    |
| `theme_id`                           | いいえ       | ユーザーのGitLabテーマ（詳細については、[ユーザー設定のドキュメント](../user/profile/preferences.md#change-the-color-theme)を参照してください）。 |
| `twitter`                            | いいえ       | X（旧Twitter）アカウント |
| `discord`                            | いいえ       | Discordアカウント |
| `username`                           | いいえ       | ユーザー名    |
| `view_diffs_file_by_file`            | いいえ       | ユーザーに対し1ページあたり1つのファイル差分のみを表示することを示すフラグ。 |
| `website_url`                        | いいえ       | WebサイトのURL |

ユーザーのパスワードを更新すると、次回のサインイン時にパスワードの変更が強制的に適用されます。

`409`（競合）が適切な場合でも、`404`エラーが返されます。たとえば、メールアドレスを既存のアドレスに変更する場合などです。

## ユーザーを削除する

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ユーザーを削除します。

前提要件:

- 管理者である必要があります。

戻り値:

- 操作が成功した場合は、`204 No Content`ステータスコード。
- リソースが見つからなかった場合は`404`。
- ユーザーをソフト削除できない場合は`409`。

```plaintext
DELETE /users/:id
```

サポートされている属性:

| 属性     | 型    | 必須 | 説明 |
|:--------------|:--------|:---------|:------------|
| `id`          | 整数 | はい      | ユーザーのID |
| `hard_delete` | ブール値 | いいえ       | trueの場合、通常は[Ghostユーザーに移動](../user/profile/account/delete_account.md#associated-records)されるコントリビュートは削除され、このユーザーのみが所有するグループも削除されます。 |

## 自分のユーザーステータスを取得する

自分のユーザーステータスを取得します。

前提要件:

- 認証済みである必要があります。

```plaintext
GET /user/status
```

リクエストの例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/user/status"
```

応答の例:

```json
{
  "emoji":"coffee",
  "availability":"busy",
  "message":"I crave coffee :coffee:",
  "message_html": "I crave coffee <gl-emoji title=\"hot beverage\" data-name=\"coffee\" data-unicode-version=\"4.0\">☕</gl-emoji>",
  "clear_status_at": null
}
```

## ユーザーのステータスを取得する

ユーザーのステータスを取得します。このエンドポイントには認証なしでアクセスできます。

```plaintext
GET /users/:id_or_username/status
```

サポートされている属性:

| 属性        | 型   | 必須 | 説明 |
|:-----------------|:-------|:---------|:------------|
| `id_or_username` | 文字列 | はい      | ステータスを取得するユーザーのIDまたはユーザー名 |

リクエストの例:

```shell
curl "https://gitlab.example.com/users/<username>/status"
```

応答の例:

```json
{
  "emoji":"coffee",
  "availability":"busy",
  "message":"I crave coffee :coffee:",
  "message_html": "I crave coffee <gl-emoji title=\"hot beverage\" data-name=\"coffee\" data-unicode-version=\"4.0\">☕</gl-emoji>",
  "clear_status_at": null
}
```

## ユーザーのステータスを設定する

ユーザーのステータスを設定します。

前提要件:

- 認証済みである必要があります。

```plaintext
PUT /user/status
PATCH /user/status
```

サポートされている属性:

| 属性            | 型   | 必須 | 説明 |
|:---------------------|:-------|:---------|:------------|
| `emoji`              | 文字列 | いいえ       | ステータスとして使用する絵文字の名前。省略した場合、`speech_balloon`が使用されます。絵文字の名前は、[Gemojioneインデックス](https://github.com/bonusly/gemojione/blob/master/config/index.json)で指定されている名前のいずれかにできます。 |
| `message`            | 文字列 | いいえ       | ステータスとして設定するメッセージ。絵文字コードを含めることもできます。100文字以下でなければなりません。 |
| `clear_status_after` | 文字列 | いいえ       | 特定の期間の経過後にステータスを自動的にクリーンアップします。使用できる値は`30_minutes`、`3_hours`、`8_hours`、`1_day`、`3_days`、`7_days`、`30_days`です。 |

`PUT`と`PATCH`の違いは次のとおりです。

- `PUT`を使用すると、渡されないパラメーターは`null`に設定され、クリアされます。
- `PATCH`を使用すると、渡されないパラメーターは無視されます。フィールドをクリアするには、明示的に`null`を渡します。

リクエストの例:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" --data "clear_status_after=1_day" --data "emoji=coffee" \
     --data "message=I crave coffee" "https://gitlab.example.com/api/v4/user/status"
```

応答の例:

```json
{
  "emoji":"coffee",
  "message":"I crave coffee",
  "message_html": "I crave coffee",
  "clear_status_at":"2021-02-15T10:49:01.311Z"
}
```

## ユーザー設定を取得する

ユーザー設定を取得します。

前提要件:

- 認証済みである必要があります。

```plaintext
GET /user/preferences
```

応答の例:

```json
{
  "id": 1,
  "user_id": 1,
  "view_diffs_file_by_file": true,
  "show_whitespace_in_diffs": false,
  "pass_user_identities_to_ci_jwt": false
}
```

## ユーザー設定を更新する

ユーザー設定を更新します。

前提要件:

- 認証済みである必要があります。

```plaintext
PUT /user/preferences
```

```json
{
  "id": 1,
  "user_id": 1,
  "view_diffs_file_by_file": true,
  "show_whitespace_in_diffs": false,
  "pass_user_identities_to_ci_jwt": false
}
```

サポートされている属性:

| 属性                        | 必須 | 説明 |
|:---------------------------------|:---------|:------------|
| `view_diffs_file_by_file`        | はい      | ユーザーに対し1ページあたり1つのファイル差分のみを表示することを示すフラグ。 |
| `show_whitespace_in_diffs`       | はい      | ユーザーに対して差分に空白の変更を表示することを示すフラグ。 |
| `pass_user_identities_to_ci_jwt` | はい      | ユーザーが自身の外部IDをCI情報として渡すことを示すフラグ。この属性には、外部システムでユーザーを識別または承認するのに十分な情報が含まれていません。これはGitLabの内部属性であり、サードパーティーサービスに渡してはなりません。詳細と例については、[トークンペイロード](../ci/secrets/id_token_authentication.md#token-payload)を参照してください。 |

## 自分のアバターをアップロードする

{{< history >}}

- GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148130)されました。

{{< /history >}}

自分のアバターをアップロードします。

前提要件:

- 認証済みである必要があります。

```plaintext
PUT /user/avatar
```

サポートされている属性:

| 属性 | 型   | 必須 | 説明 |
|:----------|:-------|:---------|:------------|
| `avatar`  | 文字列 | はい      | アップロードするファイル。理想的な画像サイズは192 x 192ピクセルです。ファイルの最大許容サイズは200 KiBです。 |

ファイルシステムからアバターをアップロードするには、`--form`引数を使用します。これにより、cURLはヘッダー`Content-Type: multipart/form-data`を使用してデータを送信します。`file=`パラメーターは、ファイルシステムの画像ファイルを指しており、先頭に`@`を付ける必要があります。次に例を示します。

リクエストの例:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "avatar=@avatar.png" \
     --url "https://gitlab.example.com/api/v4/user/avatar"
```

応答の例:

```json
{
  "avatar_url": "http://gdk.test:3000/uploads/-/system/user/avatar/76/avatar.png",
}
```

戻り値:

- 成功した場合は`200`。
- ファイルサイズが200 KiBを超える場合は`400 Bad Request`。

## 割り当てられたイシュー、マージリクエスト、およびレビューの数を取得する

割り当てられたイシュー、マージリクエスト、およびレビューの数を取得します。

前提要件:

- 認証済みである必要があります。

サポートされている属性:

| 属性                         | 型   | 説明 |
|:----------------------------------|:-------|:------------|
| `assigned_issues`                 | 数値 | 現在のユーザーに割り当てられているオープンイシューの数。 |
| `assigned_merge_requests`         | 数値 | 現在のユーザーに割り当てられているアクティブなマージリクエストの数。 |
| `merge_requests`                  | 数値 | GitLab 13.8で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/50026)になりました。`assigned_merge_requests`と同等であり、これにより置き換えられました。 |
| `review_requested_merge_requests` | 数値 | 現在のユーザーがレビューをリクエストされたマージリクエストの数。 |
| `todos`                           | 数値 | 現在のユーザーの保留中のto-doアイテムの数。 |

```plaintext
GET /user_counts
```

リクエストの例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/user_counts"
```

応答の例:

```json
{
  "merge_requests": 4,
  "assigned_issues": 15,
  "assigned_merge_requests": 11,
  "review_requested_merge_requests": 0,
  "todos": 1
}
```

## ユーザーのプロジェクト、グループ、イシュー、およびマージリクエストの数を取得する

ユーザーの以下のアイテムの数のリストを取得します。

- プロジェクト。
- グループ。
- イシュー。
- マージリクエスト。

管理者は任意のユーザーをクエリできますが、管理者以外のユーザーは自分自身のみをクエリできます。

```plaintext
GET /users/:id/associations_count
```

サポートされている属性:

| 属性 | 型    | 必須 | 説明 |
|:----------|:--------|:---------|:------------|
| `id`      | 整数 | はい      | ユーザーのID |

応答の例:

```json
{
  "groups_count": 2,
  "projects_count": 3,
  "issues_count": 8,
  "merge_requests_count": 5
}
```

## ユーザーのアクティビティをリストする

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

前提要件:

- 非公開プロファイルを持つユーザーのアクティビティを表示するには、管理者である必要があります。

公開プロファイルを持つユーザーの最終アクティビティの日付を、最も古いものから最も新しいものの順で取得します。

ユーザーイベントのタイムスタンプ（`last_activity_on`と`current_sign_in_at`）を更新するアクティビティは次のとおりです。

- Git HTTP/SSHアクティビティ（クローン、プッシュなど）
- GitLabにログインしているユーザー
- ダッシュボード、プロジェクト、イシュー、およびマージリクエストに関連するページにアクセスしているユーザー
- APIを使用しているユーザー
- GraphQL APIを使用しているユーザー

デフォルトでは、公開プロファイルを持つユーザーの過去6か月間のアクティビティが表示されます。ただし、`from`パラメーターを使用してこれを変更できます。

```plaintext
GET /user/activities
```

サポートされている属性:

| 属性 | 型   | 必須 | 説明 |
|:----------|:-------|:---------|:------------|
| `from`    | 文字列 | いいえ       | `YEAR-MM-DD`形式の日付文字列。たとえば`2016-03-11`などです。デフォルトは6か月前です。 |

リクエストの例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/user/activities"
```

応答の例:

```json
[
  {
    "username": "user1",
    "last_activity_on": "2015-12-14",
    "last_activity_at": "2015-12-14"
  },
  {
    "username": "user2",
    "last_activity_on": "2015-12-15",
    "last_activity_at": "2015-12-15"
  },
  {
    "username": "user3",
    "last_activity_on": "2015-12-16",
    "last_activity_at": "2015-12-16"
  }
]
```

`last_activity_at`は非推奨です。代わりに`last_activity_on`を使用してください。

## ユーザーがメンバーであるプロジェクトとグループをリストする

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

前提要件:

- 管理者である必要があります。

ユーザーがメンバーであるすべてのプロジェクトとグループをリストします。

メンバーシップの`source_id`、`source_name`、`source_type`、および`access_level`を返します。ソースのタイプは、`Namespace`（グループを表す）または`Project`になります。応答は直接メンバーシップのみを表します。サブグループなどの継承されたメンバーシップは含まれません。アクセスレベルは整数値で表されます。詳細については、[アクセスレベルの値](access_requests.md#valid-access-levels)の意味を参照してください。

```plaintext
GET /users/:id/memberships
```

サポートされている属性:

| 属性 | 型    | 必須 | 説明 |
|:----------|:--------|:---------|:------------|
| `id`      | 整数 | はい      | 指定されたユーザーのID |
| `type`    | 文字列  | いいえ       | メンバーシップをタイプでフィルタリングします。`Project`または`Namespace`のいずれかになります |

リクエストの例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/:user_id/memberships"
```

応答の例:

```json
[
  {
    "source_id": 1,
    "source_name": "Project one",
    "source_type": "Project",
    "access_level": "20"
  },
  {
    "source_id": 3,
    "source_name": "Group three",
    "source_type": "Namespace",
    "access_level": "20"
  }
]
```

戻り値:

- 成功した場合は`200 OK`。
- ユーザーが見つからない場合は`404 User Not Found`。
- 管理者によってリクエストされなかった場合は`403 Forbidden`。
- リクエストされたタイプがサポートされていない場合は`400 Bad Request`。

## ユーザーの2要素認証を無効にする

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/295260)されました。

{{< /history >}}

前提要件:

- 管理者である必要があります。

指定されたユーザーの2要素認証（2FA）を無効にします。

管理者はこのAPIを使用して、自分自身のユーザーアカウントまたは他の管理者の2FAを無効にすることはできません。管理者の2FAを無効にするには、代わりに[Railsコンソールを使用](../security/two_factor_authentication.md#for-a-single-user)します。

```plaintext
PATCH /users/:id/disable_two_factor
```

サポートされている属性:

| 属性 | 型    | 必須 | 説明 |
|:----------|:--------|:---------|:------------|
| `id`      | 整数 | はい      | ユーザーのID |

リクエストの例:

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/1/disable_two_factor"
```

戻り値:

- 成功した場合は`204 No content`。
- 指定されたユーザーの2要素認証が有効になっていない場合は`400 Bad request`。
- 管理者として認証されていない場合は`403 Forbidden`。
- ユーザーが見つからない場合は`404 User Not Found`。

## ユーザーにリンクされたRunnerを作成する

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

現在のユーザーにリンクされたRunnerを作成します。

前提要件:

- 管理者であるか、またはターゲットネームスペースまたはターゲットプロジェクトのオーナーロールを持っている必要があります。
- `instance_type`の場合、GitLabインスタンスの管理者である必要があります。
- オーナーロールが設定されている`group_type`または`project_type`の場合、管理者は[Runner登録の制限](../administration/settings/continuous_integration.md#restrict-runner-registration-by-all-users-in-an-instance)を有効にしてはなりません。
- `create_runner`スコープが設定されたアクセストークン。

`token`は再度取得することができないため、応答にこの値を必ずコピーまたは保存してください。

```plaintext
POST /user/runners
```

サポートされている属性:

| 属性          | 型         | 必須 | 説明 |
|:-------------------|:-------------|:---------|:------------|
| `runner_type`      | 文字列       | はい      | Runnerのスコープを指定します（`instance_type`、`group_type`、または `project_type`）。 |
| `group_id`         | 整数      | いいえ       | Runnerが作成されるグループのID。`runner_type`が`group_type`の場合は必須です。 |
| `project_id`       | 整数      | いいえ       | Runnerが作成されるプロジェクトのID。`runner_type`が`project_type`の場合は必須です。 |
| `description`      | 文字列       | いいえ       | Runnerの説明。 |
| `paused`           | ブール値      | いいえ       | Runnerが新規ジョブを無視する必要があるかどうかを指定します。 |
| `locked`           | ブール値      | いいえ       | 現在のプロジェクトに対してRunnerをロックする必要があるかどうかを指定します。 |
| `run_untagged`     | ブール値      | いいえ       | タグ付けされていないジョブをRunnerが処理する必要があるかどうかを指定します。 |
| `tag_list`         | 文字列配列 | いいえ       | Runnerタグのリスト。 |
| `access_level`     | 文字列       | いいえ       | Runnerのアクセスレベル（`not_protected`または`ref_protected`）。 |
| `maximum_timeout`  | 整数      | いいえ       | Runnerがジョブを実行できる時間（秒単位）を制限する最大タイムアウト。 |
| `maintenance_note` | 文字列       | いいえ       | Runnerの自由形式のメンテナンスノート（1024文字）。 |

リクエストの例:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --data "runner_type=instance_type" \
     "https://gitlab.example.com/api/v4/user/runners"
```

応答の例:

```json
{
    "id": 9171,
    "token": "<access-token>",
    "token_expires_at": null
}
```

## ユーザーから認証IDを削除する

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ユーザーの認証IDに関連付けられているプロバイダー名を使用して、その認証IDを削除します。

前提要件:

- 管理者である必要があります。

```plaintext
DELETE /users/:id/identities/:provider
```

サポートされている属性:

| 属性  | 型    | 必須 | 説明 |
|:-----------|:--------|:---------|:------------|
| `id`       | 整数 | はい      | ユーザーのID |
| `provider` | 文字列  | はい      | 外部プロバイダー名 |

## サポートPINを作成する

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175040)されました。

{{< /history >}}

ユーザーアカウントのサポートPINを作成します。PINは作成後7日で有効期限切れになります。GitLabサポートは、ユーザーの身元を確認するためにこのPINを求めることがあります。

前提要件:

- 認証済みである必要があります。

```plaintext
POST /user/support_pin
```

リクエストの例:

```shell
curl --request POST |
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/user/support_pin"
```

応答の例:

```json
{
  "pin":"123456",
  "expires_at":"2025-02-27T22:06:57Z"
}
```

## サポートPINの詳細を取得する

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175040)されました。

{{< /history >}}

アカウントのサポートPINの詳細を取得します。GitLabサポートは、ユーザーの身元を確認するためにこのPINを求めることがあります。

前提要件:

- 認証済みである必要があります。

```plaintext
GET /user/support_pin
```

リクエストの例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/user/support_pin"
```

応答の例:

```json
{
  "pin":"123456",
  "expires_at":"2025-02-27T22:06:57Z"
}
```

## ユーザーのサポートPINを取得する

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175040)されました。

{{< /history >}}

指定されたユーザーのサポートPINの詳細を取得します。GitLabサポートは、ユーザーの身元を確認するためにこのPINを求めることがあります。

前提要件:

- 管理者である必要があります。

```plaintext
GET /users/:id/support_pin
```

リクエストの例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/1234/support_pin"
```

応答の例:

```json
{
  "pin":"123456",
  "expires_at":"2025-02-27T22:06:57Z"
}
```

サポートされている属性:

| 属性              | 型     | 必須 | 説明 |
|:-----------------------|:---------|:---------|:------------|
| `id`             | 整数   | はい       | ユーザーアカウントのID |
