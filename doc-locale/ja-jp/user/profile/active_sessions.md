---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アクティブセッション
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、あなたのアカウントにログインしたすべてのデバイスをリストします。セッションをレビューし、認識できないものは失効できます。

## すべてのアクティブなセッションをリスト {#list-all-active-sessions}

すべてのアクティブなセッションをリストするには:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで、**アクティブなセッション**を選択します。

![アクティブセッションリスト](img/active_sessions_list_v12_7.png)

## アクティブなセッションの制限 {#active-sessions-limit}

GitLabでは、ユーザーは一度に最大100個のアクティブなセッションを持つことができます。アクティブなセッションの数が100を超えると、最も古いものが削除されます。

## セッションを失効する {#revoke-a-session}

アクティブなセッションを失効するには:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで、**アクティブなセッション**を選択します。
1. セッションの横にある**取り消し**を選択します。現在のセッションは、GitLabからサインアウトされるため、失効できません。

{{< alert type="note" >}}

セッションが失効すると、すべてのデバイスのすべての**ログイン情報を記憶する**トークンが失効します。**ログイン情報を記憶する**の詳細については、[サインインに使用されるCookie](_index.md#cookies-used-for-sign-in)を参照してください。

{{< /alert >}}

## Railsコンソールからセッションを失効する {#revoke-sessions-through-the-rails-console}

Railsコンソールからユーザーセッションを失効することもできます。これを使用して、複数のセッションを同時に失効できます。

### すべてのユーザーのすべてのセッションを失効する {#revoke-all-sessions-for-all-users}

すべてのユーザーのすべてのセッションを失効するには:

1. [Railsコンソールセッションを開始します](../../administration/operations/rails_console.md#starting-a-rails-console-session)。
1. オプション。次のコマンドですべてのアクティブなセッションをリストします:

   ```ruby
   ActiveSession.list(User.all)
   ```
   
1. 次のコマンドですべてのセッションを失効します:

   ```ruby
   ActiveSession.destroy_all
   ```

1. 次のコマンドでセッションが閉じていることを確認します:

   ```ruby
   # Show all users with active sessions
    puts "=== Currently Logged In Users ==="
    User.find_each do |user|
        sessions = ActiveSession.list(user)
        if sessions.any?
            puts "\n#{user.username} (#{user.name}):"
            sessions.each do |session|
                puts "  - IP: #{session.ip_address}, Browser: #{session.browser}, Last active: #{session.updated_at}"
            end
        end
    end
   ```

### ユーザーのすべてのセッションを失効する {#revoke-all-sessions-for-a-user}

特定のユーザーのすべてのセッションを失効するには:

1. [Railsコンソールセッションを開始します](../../administration/operations/rails_console.md#starting-a-rails-console-session)。
1. 次のコマンドでユーザーを見つけます:

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

1. オプション。次のコマンドを使用して、ユーザーのすべてのアクティブなセッションをリストします:

   ```ruby
   ActiveSession.list(user)
   ```

1. 次のコマンドですべてのセッションを失効します:

   ```ruby
   ActiveSession.list(user).each { |session| ActiveSession.destroy_session(user, session.session_private_id) }
   ```

1. 次のコマンドですべてのセッションが閉じていることを確認します:

   ```ruby
   # If all sessions are closed, returns an empty array.
   ActiveSession.list(user)
   ```
