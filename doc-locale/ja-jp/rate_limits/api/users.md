---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Users APIレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.1で、`rate_limiting_user_endpoints`[フラグ](../../administration/feature_flags/_index.md)とともに、ユーザーAPIに対するレート制限が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/452349)されました。デフォルトでは無効になっています。
- GitLab 17.10で、カスタマイズ可能なレート制限が[追加されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054)。
- GitLab 18.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/524831)になりました。機能フラグ`rate_limiting_user_endpoints`は削除されました。

{{< /history >}}

> [!note]
> GitLab 18.0以降にアップグレードすると、このAPIの構成可能なレート制限は`0`に設定されます。管理者は必要に応じてレート制限を調整できます。影響を受けるレート制限に関する情報については、[プロジェクト、グループ、ユーザーAPIのレート制限に関する発表](https://about.gitlab.com/blog/rate-limitations-announced-for-projects-groups-and-users-apis/#rate-limitation-details)を参照してください。

次の[ユーザーAPI](../../api/users.md)へのリクエストについて、IPアドレスごとおよびユーザーごとの1分あたりのレート制限を設定できます。

| 制限                                                           | デフォルト |
|-----------------------------------------------------------------|---------|
| [`GET /users/:id/followers`](../../api/user_follow_unfollow.md#list-all-accounts-that-follow-a-user) | 1分あたり100 |
| [`GET /users/:id/following`](../../api/user_follow_unfollow.md#list-all-accounts-followed-by-a-user) | 1分あたり100 |
| [`GET /users/:id/status`](../../api/users.md#retrieve-the-status-of-a-user)                               | 1分あたり240 |
| [`GET /users/:id/keys`](../../api/user_keys.md#list-all-ssh-keys-for-a-user)                         | 1分あたり120 |
| [`GET /users/:id/keys/:key_id`](../../api/user_keys.md#retrieve-an-ssh-key-for-a-user)                               | 1分あたり120 |
| [`GET /users/:id/gpg_keys`](../../api/user_keys.md#list-all-gpg-keys-for-a-user)                     | 1分あたり120 |
| [`GET /users/:id/gpg_keys/:key_id`](../../api/user_keys.md#retrieve-a-gpg-key-for-a-user)                 | 1分あたり120 |

前提条件: 

- 管理者アクセス権。

レート制限を変更するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **ネットワーク**を選択します。
1. **ユーザーAPIレート制限**を展開します。
1. 利用可能なレート制限に値を設定します。レート制限は、認証されたリクエストの場合はユーザーごとに、認証されていないリクエストの場合はIPアドレスごとに1分あたりの制限となります。レート制限を無効にするには、`0`と入力します。
1. **変更を保存**を選択します。

各レート制限:

- リクエストが認証されている場合、ユーザーごとに適用されます。
- リクエストが認証されていない場合、IPアドレスごとに適用されます。
- レート制限を無効にするには、`0`に設定できます。

ログ:

- レート制限を超過したリクエストは、`auth.log`ファイルに記録されます。
- レート制限の変更は、`audit_json.log`ファイルに記録されます。

例: 

`GET /users/:id/followers`のレート制限を150に設定し、1分間に155件のリクエストを送信した場合、最後の5件のリクエストはブロックされます。1分後、再度レート制限を超過するまでリクエストの送信を続けることができます。
