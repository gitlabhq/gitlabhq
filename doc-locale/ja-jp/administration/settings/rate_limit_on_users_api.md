---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ユーザーAPIのレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- ユーザーAPIのレート制限は、GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/452349)され、`rate_limiting_user_endpoints`という名前の[フラグ](../feature_flags/_index.md)があります。デフォルトでは無効になっています。
- GitLab 17.10で、カスタマイズ可能なレート制限が[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054)されました。
- GitLab 18.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/524831)になりました。機能フラグ`rate_limiting_user_endpoints`は削除されました。

{{< /history >}}

> [!note] 
> 
> GitLab 18.0以降にアップグレードする際、このAPIの構成可能なレート制限は`0`に設定されます。管理者は、必要に応じてレート制限を調整できます。影響を受けるレート制限に関する情報については、[プロジェクト、グループ、およびユーザーAPIに対して発表されたレート制限](https://about.gitlab.com/blog/rate-limitations-announced-for-projects-groups-and-users-apis/#rate-limitation-details)を参照してください。

以下の[Users API](../../api/users.md)へのリクエストについて、IPアドレスごと、およびユーザーごとの1分あたりのレート制限を構成できます。

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

- 管理者アクセス権が必要です。

レート制限を変更するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **Users API rate limit**を展開します。
1. 利用可能なレート制限の値を設定します。レート制限は、認証されたリクエストでは1分あたり、ユーザーごと、認証されていないリクエストではIPアドレスごとに適用されます。レート制限を無効にするには、`0`を入力します。
1. **変更を保存**を選択します。

各レート制限:

- リクエストが認証された場合、ユーザーごとに適用されます。
- リクエストが認証されていない場合、IPアドレスごとに適用されます。
- レート制限を無効にするには、`0`に設定できます。

ログ:

- レート制限を超過したリクエストは、`auth.log`ファイルにログが記録されます。
- レート制限の変更は、`audit_json.log`ファイルにログが記録されます。

例: 

`GET /users/:id/followers`に対して150のレート制限を設定し、1分間に155のリクエストを送信した場合、最後の5つのリクエストはブロックされます。1分後、再びレート制限を超えるまで、リクエストの送信を続けることができます。
