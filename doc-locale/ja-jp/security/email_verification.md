---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アカウントメール検証
description: メールメール認証でユーザーの身元を確認します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.2で`require_email_verification`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86352)されました。デフォルトでは無効になっています。
- GitLab 18.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/519123)になりました。機能フラグ`require_email_verification`は削除されました。

{{< /history >}}

アカウントメール認証は、GitLabアカウントのセキュリティをさらに強化するレイヤーを提供します。特定の条件が満たされると、アカウントはロックされます。アカウントがロックされた場合は、メールアドレスを確認するか、パスワードをリセットしてGitLabにサインインする必要があります。

{{< alert type="note" >}}

GitLab Self-Managedでは、この機能はデフォルトで無効になっています。`require_email_verification_on_account_locked`属性を有効にするには、[Application設定API](../api/settings.md)を使用します。

{{< /alert >}}

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>デモについては、[Require email verification - demo](https://www.youtube.com/watch?v=wU6BVEGB3Y0)を参照してください。

GitLab.comで、認証メールが届かない場合は、サポートチームに連絡する前に**Resend Code**を選択してください。

## 2FA（2FA）なしのアカウント {#accounts-without-two-factor-authentication-2fa}

アカウントがロックされるのは、次のいずれかの場合です:

- 24時間以内に3回以上サインインに失敗した場合。
- ユーザーが新しいIPアドレスからサインインしようとした場合。

2FAなしでロックされたアカウントは、自動的にロック解除されません。

サインインに成功すると、6桁の認証コードが記載されたメールが、アカウントのプライマリメールアドレスに送信されます。プライマリメールアドレスにアクセスできない場合は、代わりに、セカンダリメールアドレスに認証コードを送信できます。

認証コードは60分後に期限切れになります。

アカウントのロックを解除するには、サインインして認証コードを入力します。[パスワードをリセットする](https://gitlab.com/users/password/new)こともできます。

## 2FAまたはOAuthを使用するアカウント {#accounts-with-2fa-or-oauth}

アカウントがロックされるのは、サインインの試行に10回以上失敗した場合、または[設定可能なロックされたユーザーポリシー](unlock_user.md#gitlab-self-managed-and-gitlab-dedicated-users)で定義された量を超えた場合です。

2FAまたはOAuthを使用するアカウントは、10分後、または[設定可能なロックされたユーザーポリシー](unlock_user.md#gitlab-self-managed-and-gitlab-dedicated-users)で定義された量を超えると、自動的にロック解除されます。手動でアカウントのロックを解除するには、パスワードをリセットします。
