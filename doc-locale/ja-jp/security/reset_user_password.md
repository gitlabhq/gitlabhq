---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ユーザーパスワードをリセットする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ユーザーパスワードをリセットするには、UI、Rakeタスク、Railsコンソール、[ユーザーAPI](../api/users.md#modify-a-user)のいずれかを使用します。

## 前提要件 {#prerequisites}

- インスタンスの管理者である。
- パスワードは、すべての[パスワード要件](../user/profile/user_passwords.md#password-requirements)を満たしている必要があります。

## UIを使用する {#use-the-ui}

UIでユーザーパスワードをリセットするには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 更新するユーザーアカウントを特定し、**編集**を選択します。
1. **パスワード**セクションで、新しいパスワードを入力して確認します。
1. **変更を保存**を選択します。

GitLabはユーザーパスワードを更新します。

## Rakeタスクを使用する {#use-a-rake-task}

Rakeタスクを使用してユーザーパスワードをリセットするには、次の手順に従います:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake "gitlab:password:reset"
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
bundle exec rake "gitlab:password:reset"
```

{{< /tab >}}

{{< /tabs >}}

GitLabは、ユーザー名、パスワード、パスワードの確認を要求します。入力が完了すると、ユーザーパスワードが更新されます。

Rakeタスクは、引数としてユーザー名を受け入れます。たとえば、ユーザー名が`sidneyjones`のユーザーのパスワードをリセットするには、次の手順に従います:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

  ```shell
  sudo gitlab-rake "gitlab:password:reset[sidneyjones]"
  ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

  ```shell
  bundle exec rake "gitlab:password:reset[sidneyjones]"
  ```

{{< /tab >}}

{{< /tabs >}}

## Railsコンソールを使用する {#use-a-rails-console}

Railsコンソールを使用してユーザーパスワードをリセットするには、次の手順に従います:

前提要件:

- リセット対象のユーザーに関連付けられているユーザー名、ユーザーID、またはメールアドレスを把握している必要があります。

1. [Railsコンソールセッション](../administration/operations/rails_console.md#starting-a-rails-console-session)を開始します。
1. 次のいずれかの方法でユーザーを見つけます:

   - ユーザー名:

     ```ruby
     user = User.find_by_username 'exampleuser'
     ```

   - ユーザーID:

     ```ruby
     user = User.find(123)
     ```

   - メールアドレス:

     ```ruby
     user = User.find_by(email: 'user@example.com')
     ```

1. `user.password`と`user.password_confirmation`の値を設定して、パスワードをリセットします。たとえば、新しいランダムパスワードを設定するには、次のようにします:

   ```ruby
   new_password = ::User.random_password
   user.password = new_password
   user.password_confirmation = new_password
   user.password_automatically_set = false
   ```

   新しいパスワードに特定の値を設定するには、次のようにします:

   ```ruby
   new_password = 'examplepassword'
   user.password = new_password
   user.password_confirmation = new_password
   user.password_automatically_set = false
   ```

1. オプション。管理者がパスワードを変更したことをユーザーに通知します:

   ```ruby
   user.send_only_admin_changed_your_password_notification!
   ```

1. 変更を保存します:

   ```ruby
   user.save!
   ```

1. コンソールを終了します:

   ```ruby
   exit
   ```

## rootパスワードをリセットする {#reset-the-root-password}

前述の[Rakeタスク](#use-a-rake-task)または[Railsコンソール](#use-a-rails-console)の手順で、rootパスワードをリセットできます。

- rootアカウント名が変更されていない場合は、ユーザー名として`root`を使用します。
- rootアカウント名が変更されており、新しいユーザー名が不明な場合は、ユーザーID `1`でRailsコンソールを使用できる場合があります。ほとんどの場合、最初のユーザーがデフォルトの管理者アカウントです。

## トラブルシューティング {#troubleshooting}

ユーザーパスワードをリセットする際に問題が発生した場合は、次の情報を参考にして対処してください。

### メール確認の問題 {#email-confirmation-issues}

新しいパスワードが機能しない場合は、メール確認の問題である可能性があります。この問題は、Railsコンソールで修正を試みることができます。たとえば、新しい`root`パスワードが機能しない場合は、次のようにします:

1. [Railsコンソール](../administration/operations/rails_console.md)を起動します。
1. ユーザーを検索して、再確認をスキップします:

   ```ruby
   user = User.find(1)
   user.skip_reconfirmation!
   ```

1. もう一度サインインを試みます。

### パスワード要件を満たしていない {#unmet-password-requirements}

パスワードが短すぎる、弱すぎる、または複雑さの要件を満たしていない可能性があります。設定しようとしているパスワードが、すべての[パスワード要件](../user/profile/user_passwords.md#password-requirements)を満たしていることを確認してください。

### パスワードの有効期限切れ {#expired-password}

ユーザーパスワードがすでに期限切れになっている場合は、有効期限の更新が必要になることがあります。詳細については、[LDAPユーザーによるSSHを使用したGit fetchでのパスワードの有効期限切れエラー](../topics/git/troubleshooting_git.md#password-expired-error-on-git-fetch-with-ssh-for-ldap-user)を参照してください。
