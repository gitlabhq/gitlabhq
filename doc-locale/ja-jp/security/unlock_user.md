---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ロックされたユーザーアカウント
---

ユーザーがサインインに数回失敗すると、GitLabはユーザーアカウントをロックします。

## GitLab.comのユーザー {#gitlabcom-users}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

2要素認証が有効になっている場合、アカウントはサインインに3回失敗するとロックされます。アカウントは30分後に自動的にロック解除されます。

2FAが有効になっていない場合、ユーザーアカウントは24時間以内にサインインに3回失敗するとロックされます。アカウントは、次のいずれかの状態になるまでロックされたままになります:

- ユーザーが再度サインインし、[メール認証コード](email_verification.md)で本人確認を行います。
- GitLabサポートがユーザーの身元を確認し、手動でアカウントのロックを解除します。

## GitLab Self-ManagedおよびGitLab Dedicatedのユーザー {#gitlab-self-managed-and-gitlab-dedicated-users}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 設定可能なロックされたユーザーポリシーが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/27048)されました（GitLab 16.5）。

{{< /history >}}

デフォルトでは、ユーザーアカウントはサインインに10回失敗するとロックされます。アカウントは10分後に自動的にロック解除されます。

GitLab 16.5以降、管理者は[アプリケーション設定API](../api/settings.md#update-application-settings)を使用して、`max_login_attempts`または`failed_login_attempts_unlock_period_in_minutes`設定を変更できます。

管理者は、次のタスクを使用して、アカウントをすぐにロック解除できます:

### 管理者エリアからユーザーアカウントのロックを解除する {#unlock-user-accounts-from-the-admin-area}

前提要件

- GitLab Self-Managedの管理者である必要があります。

管理者エリアからアカウントのロックを解除するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 検索バーを使用して、ロックされたユーザーを見つけます。
1. **ユーザー管理**ドロップダウンリストから、**ロック解除**を選択します。

これでユーザーはサインインできます。

### コマンドラインからユーザーアカウントのロックを解除する {#unlock-user-accounts-from-the-command-line}

前提要件

- GitLab Self-Managedの管理者である必要があります。

コマンドラインからアカウントのロックを解除するには、次の手順に従います:

1. SSHでGitLabサーバーに接続します。
1. Ruby on Railsコンソールを起動します:

   ```shell
   ## For Omnibus GitLab
   sudo gitlab-rails console -e production

   ## For installations from source
   sudo -u git -H bundle exec rails console -e production
   ```

1. ロックを解除するユーザーを見つけます。メールアドレスで検索できます:

   ```ruby
   user = User.find_by(email: 'admin@local.host')
   ```

   または、IDで検索できます:

   ```ruby
   user = User.where(id: 1).first
   ```

1. ユーザーのロックを解除します:

   ```ruby
   user.unlock_access!
   ```

1. <kbd>Control</kbd>+<kbd>d</kbd>でコンソールを終了します。

これでユーザーはサインインできます。
