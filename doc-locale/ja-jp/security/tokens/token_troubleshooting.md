---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLabトークンのトラブルシューティング
---

GitLabのトークンを操作する際に、以下の問題が発生する可能性があります。

## 期限切れのアクセストークン {#expired-access-tokens}

既存のアクセストークンが使用中で`expires_at`値に達すると、トークンは期限切れとなり、以下のようになります:

- 認証に使用できなくなります。
- UIに表示されません。

このトークンを使用して行われたリクエストは、`401 Unauthorized`レスポンスを返します。短期間に同じIPアドレスから大量の不正なリクエストが行われると、GitLab.comから`403 Forbidden`レスポンスが返されます。

認証リクエストの制限に関する詳細については、[Gitとコンテナレジストリの認証失敗によるBAN](../../user/gitlab_com/_index.md#git-and-container-registry-failed-authentication-ban)を参照してください。

### ログから期限切れのアクセストークンを特定する {#identify-expired-access-tokens-from-logs}

{{< history >}}

- GitLab 17.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/464652)。

{{< /history >}}

前提条件: 

これを行うには、次の手順に従います。

- 管理者である必要があります。
- [`api_json.log`](../../administration/logs/_index.md#api_jsonlog)ファイルへのアクセス権があること。

期限切れのアクセストークンによって失敗している`401 Unauthorized`リクエストを特定するには、`api_json.log`ファイル内の以下のフィールドを使用します:

| フィールド名                | 説明 |
|---------------------------|-------------|
| `meta.auth_fail_reason`   | リクエストが拒否された理由。可能な値: `token_expired`、`token_revoked`、`insufficient_scope`、および`impersonation_disabled`。 |
| `meta.auth_fail_token_id` | 試行されたトークンのタイプとIDを記述する文字列。 |

ユーザーが期限切れのトークンを使用しようとすると、`meta.auth_fail_reason`は`token_expired`になります。以下はログエントリからの抜粋です:

```json
{
  "status": 401,
  "method": "GET",
  "path": "/api/v4/user",
  ...
  "meta.auth_fail_reason": "token_expired",
  "meta.auth_fail_token_id": "PersonalAccessToken/12",
}
```

`meta.auth_fail_token_id`は、ID 12のアクセストークンが使用されたことを示します。GitLab 18.9以降、失敗したリクエストに使用されたトークンに関連付けられたユーザー名も`meta.user`に入力された状態になります。

このトークンに関する詳細情報を見つけるには、[パーソナルアクセストークンAPI](../../api/personal_access_tokens.md#retrieve-a-personal-access-token)を使用してください。また、APIを使用して[トークンをローテーション](../../api/personal_access_tokens.md#rotate-a-personal-access-token)することもできます。

### 期限切れのアクセストークンを置き換える {#replace-expired-access-tokens}

トークンを置き換えるには:

1. このトークンが以前使用された可能性のある場所を確認し、まだトークンを使用している可能性のある自動化から削除します。
   - パーソナルアクセストークンについては、[API](../../api/personal_access_tokens.md#list-all-personal-access-tokens)を使用して最近期限切れになったトークンをリストします。たとえば、`https://gitlab.com/api/v4/personal_access_tokens`にアクセスし、特定の`expires_at`日付を持つトークンを見つけます。
   - プロジェクトアクセストークンについては、[プロジェクトアクセストークンAPI](../../api/project_access_tokens.md#list-all-project-access-tokens)を使用して最近期限切れになったトークンをリストします。
   - グループアクセストークンについては、[グループアクセストークンAPI](../../api/group_access_tokens.md#list-all-group-access-tokens)を使用して最近期限切れになったトークンをリストします。
1. 新しいアクセストークンを作成します:
   - パーソナルアクセストークンについては、[UIを使用](../../user/profile/personal_access_tokens.md#create-a-personal-access-token)するか、[ユーザートークンAPI](../../api/user_tokens.md#create-a-personal-access-token)を使用します。
   - プロジェクトアクセストークンについては、[UIを使用](../../user/project/settings/project_access_tokens.md#create-a-project-access-token)するか、[プロジェクトアクセストークンAPI](../../api/project_access_tokens.md#create-a-project-access-token)を使用します。
   - グループアクセストークンについては、[UIを使用](../../user/group/settings/group_access_tokens.md#create-a-group-access-token)するか、[グループアクセストークンAPI](../../api/group_access_tokens.md#create-a-group-access-token)を使用します。
1. 古いアクセストークンを新しいアクセストークンに置き換えます。このプロセスは、トークンの使用方法によって異なります。例えば、シークレットとして設定されている場合や、アプリケーションに組み込まれている場合などです。このトークンから行われたリクエストは、`401`レスポンスを返すべきではありません。

### トークンのライフタイムを延長する {#extend-token-lifetime}

このスクリプトを使用して、特定のトークンの有効期限を遅らせます。

GitLab 16.0以降、すべてのアクセストークンには有効期限があります。GitLab 16.0以降をデプロイすると、期限のないアクセストークンはデプロイ日から1年後に有効期限が切れます。

この日付が近づいていて、まだトークンローテーションされていないトークンがある場合、このスクリプトを使用して有効期限を遅らせ、ユーザーがトークンをローテーションする時間を増やすことができます。

#### 特定のトークンのライフタイムを延長する {#extend-lifetime-for-specific-tokens}

このスクリプトは、指定された日付に期限が切れるすべてのトークンのライフタイムを延長します。これには以下が含まれます:

- パーソナルアクセストークン
- グループアクセストークン
- プロジェクトアクセストークン

グループアクセストークンおよびプロジェクトアクセストークンの場合、このスクリプトは、GitLab 16.0以降にアップグレードする際に自動的に有効期限が設定された場合にのみ、これらのトークンのライフタイムを延長します。グループアクセストークンまたはプロジェクトアクセストークンが有効期限付きで生成された場合、またはローテーションされた場合、そのトークンの有効性はリソースへの有効なメンバーシップに依存するため、このスクリプトを使用してトークンのライフタイムを延長することはできません。

スクリプトを使用するには:

{{< tabs >}}

{{< tab title="Railsコンソールセッション" >}}

1. ターミナルウィンドウで、`sudo gitlab-rails console`を使用してRailsコンソールセッションを開始します。
1. 以下のセクションから`extend_expiring_tokens.rb`スクリプト全体を貼り付けます。必要に応じて、`expiring_date`を別の日付に変更します。
1. <kbd>Enter</kbd>キーを押します。

{{< /tab >}}

{{< tab title="Railsランナー" >}}

1. ターミナルウィンドウで、インスタンスに接続します。
1. 以下のセクションから`extend_expiring_tokens.rb`スクリプト全体をコピーし、インスタンス上のファイルとして保存します:
   - 名前を`extend_expiring_tokens.rb`にします
   - 必要に応じて、`expiring_date`を別の日付に変更します。
   - このファイルは`git:git`がアクセスできる必要があります。
1. このコマンドを実行し、`/path/to/extend_expiring_tokens.rb`を`extend_expiring_tokens.rb`ファイルの完全なパスに変更します:

   ```shell
   sudo gitlab-rails runner /path/to/extend_expiring_tokens.rb
   ```

詳細については、[Railsランナーのトラブルシューティングセクション](../../administration/operations/rails_console.md#troubleshooting)を参照してください。

{{< /tab >}}

{{< /tabs >}}

##### `extend_expiring_tokens.rb` {#extend_expiring_tokensrb}

```ruby
expiring_date = Date.new(2024, 5, 30)
new_expires_at = 6.months.from_now

total_updated = PersonalAccessToken
                  .not_revoked
                  .without_impersonation
                  .where(expires_at: expiring_date.to_date)
                  .update_all(expires_at: new_expires_at.to_date)

puts "Updated #{total_updated} tokens with new expiry date #{new_expires_at}"
```

## パーソナルアクセストークンを復元する {#restore-a-personal-access-token}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Self-ManagedインスタンスまたはGitLab Dedicatedインスタンスでは、管理者は誤って失効したパーソナルアクセストークンを復元することができます。GitLab.comでは、復元は利用できません。

> [!warning]
> 
> 以下のコマンドを実行すると、データが直接変更されます。正しく実行されなかったり、適切な条件下で実行されなかったりすると、問題を引き起こす可能性があります。念のため、まずはインスタンスのバックアップを準備したテスト環境でこれらのコマンドを実行してください。

1. [Railsコンソール](../../administration/operations/rails_console.md#starting-a-rails-console-session)を開きます。
1. トークンを復元する:

   ```ruby
   token = PersonalAccessToken.find_by_token('<token_string>')
   token.update!(revoked:false)
   ```

   たとえば、`token-string-here123`のトークンを復元するには:

   ```ruby
   token = PersonalAccessToken.find_by_token('token-string-here123')
   token.update!(revoked:false)
   ```

## 特定の日付で期限切れになるパーソナルアクセストークン、プロジェクトアクセストークン、およびグループアクセストークンを特定する {#identify-personal-project-and-group-access-tokens-expiring-on-a-certain-date}

有効期限のないアクセストークンは無期限に有効であるため、アクセストークンが漏洩した場合、セキュリティリスクとなります。

このリスクを管理するために、GitLab 16.0以降にアップグレードすると、[パーソナル](../../user/profile/personal_access_tokens.md) 、[プロジェクト](../../user/project/settings/project_access_tokens.md) 、または[グループ](../../user/group/settings/group_access_tokens.md)のアクセストークンで有効期限がないものは、自動的にアップグレード日から1年後に有効期限が設定されます。

GitLab 17.3以降では、既存のトークンに対するこの自動的な有効期限設定は元に戻され、[新しいアクセストークンの有効期限の強制を無効にする](../../administration/settings/account_and_limit_settings.md#require-expiration-dates-for-new-access-tokens)ことができます。

日付が変更されたため、トークンの有効期限がいつなのかがわからない場合、その日にGitLabにサインインしようとすると予期しない認証エラーが発生する可能性があります。

この問題を管理するには、GitLab 17.2以降にアップグレードする必要があります。これらのバージョンには、[トークンの有効期限を分析、延長、または削除するのに役立つツール](../../administration/raketasks/tokens/_index.md)が含まれているためです。

ツールを実行できない場合は、GitLab Self-Managedインスタンスでスクリプトを実行して、以下のいずれかのトークンを特定することもできます:

- 特定の日付に期限が切れる。
- 有効期限がない。

これらのスクリプトは、ターミナルウィンドウから以下のいずれかで実行します:

- A [Railsコンソールセッション](../../administration/operations/rails_console.md#starting-a-rails-console-session)。
- [Railsランナー](../../administration/operations/rails_console.md#using-the-rails-runner)を使用します。

実行する特定のスクリプトは、GitLab 16.0以降にアップグレードしたかどうかに応じて異なります:

- GitLab 16.0以降にまだアップグレードしていない場合は、有効期限のないトークンを特定します。
- GitLab 16.0以降にアップグレードした場合は、スクリプトを使用して以下のいずれかを特定します:
  - [特定の日付に期限が切れるトークン](#find-all-tokens-expiring-on-a-specific-date)。
  - [特定の月に期限が切れるトークン](#find-tokens-expiring-in-a-given-month)。
  - [多くのトークンが期限切れになる日付](#identify-dates-when-many-tokens-expire)。

この問題の影響を受けるトークンを特定したら、必要に応じて特定のトークンのライフタイムを延長するための最終スクリプトを実行できます。

これらのスクリプトは、以下の形式で結果を返します:

```plaintext
Expired group access token in Group ID 25, Token ID: 8, Name: Example Token, Scopes: ["read_api", "create_runner"], Last used:
Expired project access token in Project ID 2, Token ID: 9, Name: Test Token, Scopes: ["api", "read_registry", "write_registry"], Last used: 2022-02-11 13:22:14 UTC
```

これに関する詳細については、[インシデント18003](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18003)を参照してください。

### 特定の日付に期限が切れるすべてのトークンを見つける {#find-all-tokens-expiring-on-a-specific-date}

このスクリプトは、特定の日付に期限が切れるトークンを見つけます。

前提条件: 

- お使いのインスタンスがGitLab 16.0にアップグレードされた正確な日付を知っている必要があります。

使用するには:

{{< tabs >}}

{{< tab title="Railsコンソールセッション" >}}

1. ターミナルウィンドウで、インスタンスに接続します。
1. `sudo gitlab-rails console`を使用してRailsコンソールセッションを開始します。
1. 必要に応じて、以下のセクションの`expired_tokens.rb`全体、またはその次のセクションの`expired_tokens_date_range.rb`スクリプトをコピーしてコンソールに貼り付けます。`expires_at_date`を、お使いのインスタンスがGitLab 16.0にアップグレードされた日から1年後の日付に変更します。
1. <kbd>Enter</kbd>キーを押します。

{{< /tab >}}

{{< tab title="Railsランナー" >}}

1. ターミナルウィンドウで、インスタンスに接続します。
1. 必要に応じて、以下のセクションの`expired_tokens.rb`全体、またはその次のセクションの`expired_tokens_date_range.rb`スクリプトをコピーし、インスタンス上のファイルとして保存します:
   - 名前を`expired_tokens.rb`にします
   - `expires_at_date`を、お使いのインスタンスがGitLab 16.0にアップグレードされた日から1年後の日付に変更します。
   - このファイルは`git:git`がアクセスできる必要があります。
1. このコマンドを実行し、`expired_tokens.rb`をファイルの完全なパスに変更します:

   ```shell
   sudo gitlab-rails runner /path/to/expired_tokens.rb
   ```

詳細については、[Railsランナーのトラブルシューティングセクション](../../administration/operations/rails_console.md#troubleshooting)を参照してください。

{{< /tab >}}

{{< /tabs >}}

#### `expired_tokens.rb` {#expired_tokensrb}

このスクリプトを使用するには、お使いのGitLabインスタンスがGitLab 16.0にアップグレードされた正確な日付を知っている必要があります。

```ruby
# Change this value to the date one year after your GitLab instance was upgraded.

expires_at_date = "2024-05-22"

# Check for expiring personal access tokens
PersonalAccessToken.for_user_types(:human).where(expires_at: expires_at_date).find_each do |token|
  if token.user.blocked?
    next
    # Hide unusable, blocked PATs from output
  end

  puts "Expired personal access token ID: #{token.id}, User Email: #{token.user.email}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
end

# Check for expiring project and group access tokens
PersonalAccessToken.project_access_token.where(expires_at: expires_at_date).find_each do |token|
  token.user.members.each do |member|
    type = member.is_a?(GroupMember) ? 'Group' : 'Project'

    puts "Expired #{type} access token in #{type} ID #{member.source_id}, Token ID: #{token.id}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
  end
end
```

> [!note]
> ブロックされたユーザーに属するトークンを非表示にし、削除するには、`if token.user.blocked?`のすぐ下に`token.destroy!`を追加します。ただし、このアクションは[APIメソッド](../../api/personal_access_tokens.md#revoke-a-personal-access-token)とは異なり、監査イベントを残しません。

### 特定の月に期限が切れるトークンを見つける {#find-tokens-expiring-in-a-given-month}

このスクリプトは、特定の月に期限が切れるトークンを見つけます。お使いのインスタンスがGitLab 16.0にアップグレードされた正確な日付を知る必要はありません。使用するには:

{{< tabs >}}

{{< tab title="Railsコンソールセッション" >}}

1. ターミナルウィンドウで、`sudo gitlab-rails console`を使用してRailsコンソールセッションを開始します。
1. 次のセクションの`expired_tokens_date_range.rb`スクリプト全体を貼り付けます。必要に応じて、`date_range`を別の範囲に変更します。
1. <kbd>Enter</kbd>キーを押します。

{{< /tab >}}

{{< tab title="Railsランナー" >}}

1. ターミナルウィンドウで、インスタンスに接続します。
1. 次のセクションの`expired_tokens_date_range.rb`スクリプト全体をコピーし、インスタンス上のファイルとして保存します:
   - 名前を`expired_tokens_date_range.rb`にします
   - 必要に応じて、`date_range`を別の範囲に変更します。
   - このファイルは`git:git`がアクセスできる必要があります。
1. このコマンドを実行し、`/path/to/expired_tokens_date_range.rb`を`expired_tokens_date_range.rb`ファイルの完全なパスに変更します:

   ```shell
   sudo gitlab-rails runner /path/to/expired_tokens_date_range.rb
   ```

詳細については、[Railsランナーのトラブルシューティングセクション](../../administration/operations/rails_console.md#troubleshooting)を参照してください。

{{< /tab >}}

{{< /tabs >}}

#### `expired_tokens_date_range.rb` {#expired_tokens_date_rangerb}

```ruby
# This script enables you to search for tokens that expire within a
# certain date range (like 1.month) from the current date. Use it if
# you're unsure when exactly your GitLab 16.0 upgrade completed.

date_range = 1.month

# Check for personal access tokens
PersonalAccessToken.for_user_types(:human).where(expires_at: Date.today .. Date.today + date_range).find_each do |token|
  puts "Expired personal access token ID: #{token.id}, User Email: #{token.user.email}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
end

# Check for expiring project and group access tokens
PersonalAccessToken.project_access_token.where(expires_at: Date.today .. Date.today + date_range).find_each do |token|
  token.user.members.each do |member|
    type = member.is_a?(GroupMember) ? 'Group' : 'Project'

    puts "Expired #{type} access token in #{type} ID #{member.source_id}, Token ID: #{token.id}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
  end
end
```

### 多くのトークンが期限切れになる日付を特定する {#identify-dates-when-many-tokens-expire}

このスクリプトは、ほとんどのトークンが期限切れになる日付を特定します。このページ上の他のスクリプトと組み合わせて、期限が近づいている大量のトークンを特定し、ライフタイムを延長するために使用できます。これは、チームがまだトークンローテーションを設定していない場合に役立ちます。

スクリプトは以下の形式で結果を返します:

```plaintext
42 Personal access tokens will expire at 2024-06-27
17 Personal access tokens will expire at 2024-09-23
3 Personal access tokens will expire at 2024-08-13
```

使用するには:

{{< tabs >}}

{{< tab title="Railsコンソールセッション" >}}

1. ターミナルウィンドウで、`sudo gitlab-rails console`を使用してRailsコンソールセッションを開始します。
1. スクリプト`dates_when_most_of_tokens_expire.rb`全体を貼り付けます。
1. <kbd>Enter</kbd>キーを押します。

{{< /tab >}}

{{< tab title="Railsランナー" >}}

1. ターミナルウィンドウで、インスタンスに接続します。
1. この`dates_when_most_of_tokens_expire.rb`スクリプト全体をコピーし、インスタンス上のファイルとして保存します:
   - 名前を`dates_when_most_of_tokens_expire.rb`にします
   - このファイルは`git:git`がアクセスできる必要があります。
1. このコマンドを実行し、`/path/to/dates_when_most_of_tokens_expire.rb`を`dates_when_most_of_tokens_expire.rb`ファイルの完全なパスに変更します:

   ```shell
   sudo gitlab-rails runner /path/to/dates_when_most_of_tokens_expire.rb
   ```

詳細については、[Railsランナーのトラブルシューティングセクション](../../administration/operations/rails_console.md#troubleshooting)を参照してください。

{{< /tab >}}

{{< /tabs >}}

#### `dates_when_most_of_tokens_expire.rb` {#dates_when_most_of_tokens_expirerb}

```ruby
PersonalAccessToken
  .select(:expires_at, Arel.sql('count(*)'))
  .where('expires_at >= NOW()')
  .group(:expires_at)
  .order(Arel.sql('count(*) DESC'))
  .limit(10)
  .each do |token|
    puts "#{token.count} Personal access tokens will expire at #{token.expires_at}"
  end
```

### 有効期限のないトークンを見つける {#find-tokens-with-no-expiration-date}

このスクリプトは、有効期限がないトークン、すなわち`expires_at`が`NULL`であるトークンを見つけます。GitLabバージョン16.0以降にまだアップグレードしていないユーザーの場合、トークンの`expires_at`値は`NULL`であり、これを使用して有効期限を追加すべきトークンを特定できます。

このスクリプトは、[Railsコンソール](../../administration/operations/rails_console.md)または[Railsランナー](../../administration/operations/rails_console.md#using-the-rails-runner)のいずれかで使用できます:

{{< tabs >}}

{{< tab title="Railsコンソールセッション" >}}

1. ターミナルウィンドウで、インスタンスに接続します。
1. `sudo gitlab-rails console`を使用してRailsコンソールセッションを開始します。
1. 以下のセクションから`tokens_with_no_expiry.rb`スクリプト全体を貼り付けます。
1. <kbd>Enter</kbd>キーを押します。

{{< /tab >}}

{{< tab title="Railsランナー" >}}

1. ターミナルウィンドウで、インスタンスに接続します。
1. 以下のセクションからこの`tokens_with_no_expiry.rb`スクリプト全体をコピーし、インスタンス上のファイルとして保存します:
   - 名前を`tokens_with_no_expiry.rb`にします
   - このファイルは`git:git`がアクセスできる必要があります。
1. このコマンドを実行し、`tokens_with_no_expiry.rb`をファイルの完全なパスに変更します:

   ```shell
   sudo gitlab-rails runner /path/to/tokens_with_no_expiry.rb
   ```

詳細については、[Railsランナーのトラブルシューティングセクション](../../administration/operations/rails_console.md#troubleshooting)を参照してください。

{{< /tab >}}

{{< /tabs >}}

#### `tokens_with_no_expiry.rb` {#tokens_with_no_expiryrb}

このスクリプトは、`expires_at`に値が設定されていないトークンを見つけます。

   ```ruby
   # This script finds tokens which do not have an expires_at value set.

   # Check for expiring personal access tokens
   PersonalAccessToken.for_user_types(:human).where(expires_at: nil).find_each do |token|
     puts "Expires_at is nil for personal access token ID: #{token.id}, User Email: #{token.user.email}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
   end

   # Check for expiring project and group access tokens
   PersonalAccessToken.project_access_token.where(expires_at: nil).find_each do |token|
     token.user.members.each do |member|
       type = member.is_a?(GroupMember) ? 'Group' : 'Project'

       puts "Expires_at is nil for #{type} access token in #{type} ID #{member.source_id}, Token ID: #{token.id}, Name: #{token.name}, Scopes: #{token.scopes}, Last used: #{token.last_used_at}"
     end
   end
   ```
