---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 招待API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このを使用して、招待を管理し、ユーザーを[グループ](../user/group/_index.md#add-users-to-a-group)または[プロジェクト](../user/project/members/_index.md)に追加します。

## 有効なアクセスレベル {#valid-access-levels}

招待を送信するには、メールを送信するプロジェクトまたはグループへのアクセス権が必要です。有効なアクセスレベルは、`Gitlab::Access`モジュールで定義されています:

- アクセスなし（`0`）
- 最小アクセス（`5`）
- ゲスト（`10`）
- プランナー（`15`）
- レポーター（`20`）
- デベロッパー（`30`）
- メンテナー（`40`）
- オーナー（`50`）

## グループまたはプロジェクトにメンバーを追加する {#add-a-member-to-a-group-or-project}

新しいメンバーを追加します。ユーザーを指定するか、メールでユーザーを招待できます。

前提要件: 

- グループの場合、グループのオーナーロールが必要です。
- プロジェクトの場合:
  - プロジェクトのオーナーまたはメンテナーのロールが必要です。
  - [グループメンバーシップのロック]( ../user/group/access_and_permissions.md#prevent-members-from-being-added-to-projects-in-a-group)を無効にする必要があります。
- GitLab Self-Managedインスタンスの場合:
  - [新規サインアップが無効になっている](../administration/settings/sign_up_restrictions.md#disable-new-sign-ups)場合、管理者がユーザーを追加する必要があります。
  - [ユーザー招待が許可されていない](../administration/settings/visibility_and_access_controls.md#prevent-invitations-to-groups-and-projects)場合、管理者がユーザーを追加する必要があります。
  - 管理者によるロールの昇格の[承認が有効になっている](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions)場合、管理者は招待を承認する必要があります。

```plaintext
POST /groups/:id/invitations
POST /projects/:id/invitations
```

| 属性        | 型           | 必須                          | 説明 |
|------------------|----------------|-----------------------------------|-------------|
| `id`             | 整数または文字列 | はい                               | プロジェクトまたはグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `email`          | 文字列         | はい（`user_id`が指定されていない場合） | 新しいメンバーのメール、またはコンマで区切られた複数のメール。 |
| `user_id`        | 整数または文字列 | はい（`email`が指定されていない場合）   | 新しいメンバーのID、またはカンマで区切られた複数のID。 |
| `access_level`   | 整数        | はい                               | 有効なアクセスレベル。 |
| `expires_at`     | 文字列         | いいえ                                | `YEAR-MONTH-DAY`形式の日付文字列。 |
| `invite_source`  | 文字列         | いいえ                                | メンバー作成プロセスを開始する招待のソース。 |
| `member_role_id` | 整数        | いいえ                                | 指定されたカスタムロールに新しいメンバーを割り当てます。GitLab 16.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134100)。Ultimateのみです。 |

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

**Manage non-billable promotions**（請求対象でないプロモーションの管理）を有効にするには、最初に`enable_member_promotion_management`アプリケーション設定を有効にする必要があります。

レスポンス例:

```json
{
  "queued_users": {
    "username_1": "Request queued for administrator approval."
  },
  "status": "success"
}
```

## グループまたはプロジェクトの保留中のすべての招待をリストします {#list-all-invitations-pending-for-a-group-or-project}

認証済みユーザーが表示可能なグループ・プロジェクトメンバーのリストを取得します。直接のメンバーへの招待のみを返し、祖先のグループから継承したものではありません。

この関数は、ページネーションパラメータ`page`および`per_page`を受け取り、メンバーのリストを制限します。

```plaintext
GET /groups/:id/invitations
GET /projects/:id/invitations
```

| 属性  | 型           | 必須 | 説明 |
|------------|----------------|----------|-------------|
| `id`       | 整数または文字列 | はい      | プロジェクトまたはグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `page`     | 整数        | いいえ       | 取得するページ。 |
| `per_page` | 整数        | いいえ       | ページごとに返すメンバー招待の数 |
| `query`    | 文字列         | いいえ       | 招待メールで招待されたメンバーを検索するクエリ文字列。クエリテキストは、メールアドレスと完全に一致する必要があります。空の場合、すべての招待を返します。 |

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

## グループまたはプロジェクトへの招待を更新します {#update-an-invitation-to-a-group-or-project}

保留中の招待のアクセスレベルまたはアクセス有効期限日を更新します。

```plaintext
PUT /groups/:id/invitations/:email
PUT /projects/:id/invitations/:email
```

| 属性      | 型           | 必須 | 説明 |
|----------------|----------------|----------|-------------|
| `id`           | 整数または文字列 | はい      | プロジェクトまたはグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `email`        | 文字列         | はい      | 招待が以前に送信されたメールアドレス。 |
| `access_level` | 整数        | いいえ       | 有効なアクセスレベル（デフォルト：`30`、デベロッパーロール）。 |
| `expires_at`   | 文字列         | いいえ       |  8601形式の日付文字列（`YYYY-MM-DDTHH:MM:SSZ`）。 |

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

## グループまたはプロジェクトへの招待を削除します {#delete-an-invitation-to-a-group-or-project}

メールアドレスで保留中の招待を削除します。

```plaintext
DELETE /groups/:id/invitations/:email
DELETE /projects/:id/invitations/:email
```

| 属性 | 型           | 必須 | 説明 |
|-----------|----------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトまたはグループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `email`   | 文字列         | はい      | 招待が以前に送信されたメールアドレス |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/55/invitations/email@example.org"
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/55/invitations/email@example.org"
```

- 成功すると`204`が返されますが、コンテンツは返されません。
- 招待を削除する権限がない場合は、`403` forbiddenを返します。
- 権限があり、そのメールアドレスの招待が見つからない場合は、`404`が見つからないことを返します。
- リクエストは有効だが、招待を削除できなかった場合は、`409`を返します。
