---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Users APIのレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- APIのレート制限は、[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/452349)GitLab 17.1で、`rate_limiting_user_endpoints`という名前の[フラグ](../feature_flags/_index.md)が付けられています。デフォルトでは無効になっています。
- [追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054) GitLab 17.10でカスタマイズ可能なレート制限。
- GitLab 18.1で[一般公開](https://gitlab.com/gitlab-org/gitlab/-/issues/524831)になりました。機能フラグ`rate_limiting_user_endpoints`は削除されました。

{{< /history >}}

次の[Users API](../../api/users.md)へのリクエストについて、IPアドレスおよびユーザーごとの1分あたりのレート制限を構成できます。

| 制限                                                           | デフォルト |
|-----------------------------------------------------------------|---------|
| [`GET /users/:id/followers`](../../api/user_follow_unfollow.md#list-all-accounts-that-follow-a-user) | 毎分100 |
| [`GET /users/:id/following`](../../api/user_follow_unfollow.md#list-all-accounts-followed-by-a-user) | 毎分100 |
| [`GET /users/:id/status`](../../api/users.md#get-the-status-of-a-user)                               | 毎分240 |
| [`GET /users/:id/keys`](../../api/user_keys.md#list-all-ssh-keys-for-a-user)                         | 毎分120 |
| [`GET /users/:id/keys/:key_id`](../../api/user_keys.md#get-an-ssh-key)                               | 毎分120 |
| [`GET /users/:id/gpg_keys`](../../api/user_keys.md#list-all-gpg-keys-for-a-user)                     | 毎分120 |
| [`GET /users/:id/gpg_keys/:key_id`](../../api/user_keys.md#get-a-gpg-key-for-a-user)                 | 毎分120 |

レート制限を変更するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. **Users API rate limit**（Users APIレート制限）を展開します。
1. 利用可能なレート制限の値を設定します。レート制限は、認証されたリクエストの場合はユーザーごと、認証されていないリクエストの場合はIPアドレスごとに、1分あたりで適用されます。`0`を入力して、レート制限を無効にします。
1. **変更を保存**を選択します。

各レート制限:

- リクエストが認証されている場合、ユーザーごとに適用されます。
- リクエストが認証されていない場合、IPアドレスごとに適用されます。
- `0`に設定して、レート制限を無効にできます。

ログ:

- レート制限を超えるリクエストは、`auth.log`ファイルに記録されます。
- レート制限の変更は、`audit_json.log`ファイルに記録されます。

例: 

`GET /users/:id/followers`に150のレート制限を設定し、1分間に155件のリクエストを送信すると、最後の5件のリクエストがブロックされます。1分後には、レート制限を超えるまでリクエストを送信し続けることができます。
