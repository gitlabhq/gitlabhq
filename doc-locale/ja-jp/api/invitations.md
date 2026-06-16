---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 招待API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、招待を管理し、ユーザーを[グループ](../user/group/_index.md#add-users-to-a-group)または[プロジェクト](../user/project/members/_index.md)に追加します。

## グループまたはプロジェクトにメンバーを追加する {#add-a-member-to-a-group-or-project}

新しいメンバーを追加します。ユーザーIDを指定するか、メールでユーザーを招待できます。

前提条件: 

- グループの場合、グループのオーナーロールが必要です。
- プロジェクトの場合:
  - プロジェクトのメンテナーまたはオーナーロールが必要です。
  - [グループメンバーシップのロック](../user/group/access_and_permissions.md#prevent-members-from-being-added-to-projects-in-a-group)を無効にする必要があります。
- GitLab Self-Managedインスタンスの場合:
  - [新規ユーザーアカウントの作成が許可されていない](../administration/settings/sign_up_restrictions.md#disable-new-user-account-creation)場合、管理者がユーザーを追加する必要があります。
  - [ユーザー招待が許可されていない](../administration/settings/visibility_and_access_controls.md#prevent-invitations-to-groups-and-projects)場合、管理者がユーザーを追加する必要があります。
  - [ロールのプロモートに対する管理者承認が有効になっている](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions)場合、管理者が招待を承認する必要があります。

```plaintext
POST /groups/:id/invitations
POST /projects/:id/invitations
```

| 属性        | 型              | 必須                          | 説明 |
| ---------------- | ----------------- | --------------------------------- | ----------- |
| `id`             | 整数または文字列 | はい                               | IDまたは[プロジェクトまたはグループのURLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `email`          | 文字列            | はい（`user_id`が指定されていない場合） | 新しいメンバーのメール、またはコンマで区切られた複数のメール。 |
| `user_id`        | 整数または文字列 | はい（`email`が指定されていない場合）   | 新しいメンバーのID、またはコンマで区切られた複数のID。 |
| `access_level`   | 整数           | はい                               | 有効な[アクセスレベル](../user/permissions.md#default-roles)。使用可能な値: `0`（アクセスなし）、`5`（最小アクセス）、`10`（ゲスト）、`15`（プランナー）、`20`（レポーター）、`25`（セキュリティマネージャー）、`30`（デベロッパー）、`40`（メンテナー）、または`50`（オーナー）。デフォルトは`30`です。 |
| `expires_at`     | 文字列            | いいえ                                | `YEAR-MONTH-DAY`形式の日付文字列 |
| `invite_source`  | 文字列            | いいえ                                | メンバー作成プロセスを開始する招待のソース。 |
| `member_role_id` | 整数           | いいえ                                | 新しいメンバーに指定されたカスタムロールを割り当てます。GitLab 16.6で([導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134100))。Ultimateのみです。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/invitations" \
  --data "email=test@example.com&user_id=1&access_level=30"
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/invitations" \
  --data "email=test@example.com&user_id=1&access_level=30"
```

レスポンス例:

すべてのメールが正常に送信された場合:

```json
{  "status":  "success"  }
```

メールの送信中にエラーが発生した場合:

```json
{
  "status": "error",
  "message": {
               "test@example.com": "Invite email has already been taken",
               "test2@example.com": "User already exists in source",
               "test_username": "Access level is not included in the list"
             }
}
```

**請求対象でないプロモーションの管理**を有効にするには、最初に`enable_member_promotion_management`アプリケーション設定を有効にする必要があります。

レスポンス例: 

```json
{
  "queued_users": {
    "username_1": "Request queued for administrator approval."
  },
  "status": "success"
}
```

## グループまたはプロジェクトの保留中の招待をすべてリスト表示する {#list-all-pending-invitations-for-a-group-or-project}

認証済みユーザーが閲覧できるすべての保留中の招待をリスト表示します。直接メンバーへの招待のみを返し、継承された祖先のグループを介した招待は返しません。

この関数は、メンバーのリストを制限するためにページネーションパラメータ`page`と`per_page`を取ります。

```plaintext
GET /groups/:id/invitations
GET /projects/:id/invitations
```

| 属性  | 型           | 必須 | 説明 |
|------------|----------------|----------|-------------|
| `id`       | 整数または文字列 | はい      | IDまたは[プロジェクトまたはグループのURLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `page`     | 整数        | いいえ       | 取得するページ |
| `per_page` | 整数        | いいえ       | ページごとに返すメンバー招待の数 |
| `query`    | 文字列         | いいえ       | 招待メールで招待されたメンバーをクエリするためのクエリ文字列。クエリテキストはメールアドレスと正確に一致する必要があります。空の場合、すべての招待を返します。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/invitations?query=member@example.org"
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/invitations?query=member@example.org"
```

レスポンス例: 

```json
 [
   {
     "id": 1,
     "invite_email": "member@example.org",
     "created_at": "2020-10-22T14:13:35Z",
     "access_level": 30,
     "expires_at": "2020-11-22T14:13:35Z",
     "user_name": "Raymond Smith",
     "created_by_name": "Administrator"
   },
]
```

## グループまたはプロジェクトへの招待を更新する {#update-an-invitation-to-a-group-or-project}

グループまたはプロジェクトへの保留中の招待を更新します。

```plaintext
PUT /groups/:id/invitations/:email
PUT /projects/:id/invitations/:email
```

| 属性      | 型              | 必須 | 説明 |
| -------------- | ----------------- | -------- | ----------- |
| `id`           | 整数または文字列 | はい      | プロジェクトまたはグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `email`        | 文字列            | はい      | 以前に招待が送信されたメールアドレス。 |
| `access_level` | 整数           | いいえ       | 有効な[アクセスレベル](../user/permissions.md#default-roles)。使用可能な値: `0`（アクセスなし）、`5`（最小アクセス）、`10`（ゲスト）、`15`（プランナー）、`20`（レポーター）、`25`（セキュリティマネージャー）、`30`（デベロッパー）、`40`（メンテナー）、または`50`（オーナー）。デフォルトは`30`です。 |
| `expires_at`   | 文字列            | いいえ       | ISO 8601形式 (`YYYY-MM-DDTHH:MM:SSZ`) の日付文字列。 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/55/invitations/email@example.org?access_level=40"
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/55/invitations/email@example.org?access_level=40"
```

レスポンス例: 

```json
{
  "expires_at": "2012-10-22T14:13:35Z",
  "access_level": 40,
}
```

## グループまたはプロジェクトへの招待を削除する {#delete-an-invitation-to-a-group-or-project}

指定されたメールアドレスへの保留中の招待を削除します。

```plaintext
DELETE /groups/:id/invitations/:email
DELETE /projects/:id/invitations/:email
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | IDまたは[プロジェクトまたはグループのURLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `email`   | 文字列         | はい      | 以前に招待が送信されたメールアドレス |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/55/invitations/email@example.org"
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/55/invitations/email@example.org"
```

- 成功すると`204`が返されますが、コンテンツは返されません。
- 招待を削除する権限がない場合は`403` forbiddenを返します。
- 権限があり、そのメールアドレスの招待が見つからない場合は`404` not foundを返します。
- リクエストが有効だったが招待を削除できなかった場合は`409`を返します。
