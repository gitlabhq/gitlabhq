---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabトークンのトラブルシューティング
---

GitLabのトークンを使用する際に、以下の問題が発生する可能性があります。

## 期限切れのアクセストークン {#expired-access-tokens}

既存のアクセストークンが使用中で、`expires_at`値に達すると、トークンは期限切れになり、次のようになります:

- 認証に使用できなくなります。
- UIに表示されません。

このトークンを使用して行われたリクエストは、`401 Unauthorized`応答を返します。同じIPアドレスから短期間に多数の認証されていないリクエストが送信されると、GitLab.comから`403 Forbidden`応答が返されます。

認証リクエストの制限の詳細については、[Gitとコンテナレジストリの認証失敗](../../user/gitlab_com/_index.md#git-and-container-registry-failed-authentication-ban)を参照してください。

### ログから期限切れのアクセストークンを特定する {#identify-expired-access-tokens-from-logs}

{{< history >}}

- GitLab 17.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/464652)。

{{< /history >}}

前提要件: 

これを行うには、次の手順に従います:

- 管理者であること。
- [`api_json.log`](../../administration/logs/_index.md#api_jsonlog)ファイルへのアクセス権を持っていること。

期限切れのアクセストークンが原因で失敗している`401 Unauthorized`リクエストを特定するには、`api_json.log`ファイルの次のフィールドを使用します:

| フィールド名                | 説明 |
|---------------------------|-------------|
| `meta.auth_fail_reason`   | リクエストが拒否された理由。使用できる値は、`token_expired`、`token_revoked`、`insufficient_scope`、および`impersonation_disabled`です。 |
| `meta.auth_fail_token_id` | 試行されたトークンのタイプとIDを説明する文字列。 |

ユーザーが期限切れのトークンを使用しようとすると、`meta.auth_fail_reason`は`token_expired`になります。次に、ログエントリからの抜粋を示します:

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

`meta.auth_fail_token_id`IDが12のアクセストークンが使用されたことを示します。

このトークンの詳細については、[パーソナルアクセストークン](../../api/personal_access_tokens.md#get-details-on-a-personal-access-token)を使用してください。を使用して[トークンローテーション](../../api/personal_access_tokens.md#rotate-a-personal-access-token)することもできます。

### 期限切れのアクセストークンを置き換える {#replace-expired-access-tokens}

トークンを置き換えるには、次の手順を実行します:

1. このトークンが以前に使用された可能性がある場所を確認し、トークンをまだ使用している可能性のある自動化から削除します。
   - パーソナルアクセストークンの場合は、[API](../../api/personal_access_tokens.md#list-all-personal-access-tokens)を使用して、最近期限切れになったトークンを一覧表示します。たとえば、`https://gitlab.com/api/v4/personal_access_tokens`に移動し、特定の`expires_at`日付のトークンを見つけます。
   - プロジェクトアクセストークンの場合は、[プロジェクトアクセストークン](../../api/project_access_tokens.md#list-all-project-access-tokens)を使用して、最近期限切れになったトークンを一覧表示します。
   - グループアクセストークンの場合は、[グループアクセストークン](../../api/group_access_tokens.md#list-all-group-access-tokens)を使用して、最近期限切れになったトークンを一覧表示します。
1. 新しいアクセストークンを作成します:
   - パーソナルアクセストークンの場合は、[UI](../../user/profile/personal_access_tokens.md#create-a-personal-access-token)または[ユーザートークン](../../api/user_tokens.md#create-a-personal-access-token)を使用します。
   - プロジェクトアクセストークンの場合は、[UI](../../user/project/settings/project_access_tokens.md#create-a-project-access-token)または[プロジェクトアクセストークン](../../api/project_access_tokens.md#create-a-project-access-token)を使用します。
   - グループアクセストークンの場合は、[UI](../../user/group/settings/group_access_tokens.md#create-a-group-access-token)または[グループアクセストークン](../../api/group_access_tokens.md#create-a-group-access-token)を使用します。
1. 古いアクセストークンを新しいアクセストークンに置き換えます。このプロセスは、シークレットとして構成されている場合やアプリケーションに埋め込まれている場合など、トークンの使用方法によって異なります。このトークンから作成されたリクエストは、`401`応答を返さなくなります。

### トークンのライフタイムを延長する {#extend-token-lifetime}

このスクリプトを使用して、特定のトークンの有効期限を遅らせます。

GitLab 16.0以降、すべてのアクセストークンに有効期限が設定されています。少なくともGitLab 16.0をデプロイすると、有効期限のないすべてのアクセストークンは、デプロイ日から1年後に有効期限切れになります。

この日付が近づいていて、まだローテーションされていないトークンがある場合は、このスクリプトを使用して有効期限を遅らせ、ユーザーがトークンをローテーションする時間を増やすことができます。

#### 特定のトークンのライフタイムを延長する {#extend-lifetime-for-specific-tokens}

このスクリプトは、指定された日付に有効期限が切れるすべてのトークンのライフタイムを延長します。対象は以下を含みます:

- パーソナルアクセストークン
- グループアクセストークン
- プロジェクトアクセストークン

グループおよびプロジェクトアクセストークンの場合、このスクリプトは、GitLab 16.0以降へのアップグレード時に有効期限が自動的に設定された場合にのみ、これらのトークンのライフタイムを延長します。グループまたはプロジェクトアクセストークンが有効期限付きで生成された場合、またはローテーションされた場合、そのトークンの有効性はリソースへの有効なメンバーシップに依存するため、このスクリプトを使用してトークンのライフタイムを延長することはできません。

スクリプトを使用するには、次の手順を実行します:

{{< tabs >}}

{{< tab title="Railsコンソールセッション" >}}

1. ターミナルウィンドウで、`sudo gitlab-rails console`を使用してRailsコンソールセッションを開始します。
1. 次のセクションから`extend_expiring_tokens.rb`スクリプト全体を貼り付けます。必要に応じて、`expiring_date`を別の日付に変更します。
1. <kbd>Enter</kbd>キーを押します。

{{< /tab >}}

{{< tab title="Rails Runner" >}}

1. ターミナルウィンドウで、インスタンスに接続します。
1. 次のセクションから`extend_expiring_tokens.rb`スクリプト全体をコピーし、インスタンス上のファイルとして保存します:
   - 名前を`extend_expiring_tokens.rb`にします。
   - 必要に応じて、`expiring_date`を別の日付に変更します。
   - ファイルは`git:git`からアクセスできる必要があります。
1. 次のコマンドを実行します。`/path/to/extend_expiring_tokens.rb`の部分は、実際の`extend_expiring_tokens.rb`ファイルへのフルパスに変更してください:

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

## 特定の日付に有効期限が切れるパーソナル、プロジェクト、およびグループアクセストークンを特定する {#identify-personal-project-and-group-access-tokens-expiring-on-a-certain-date}

有効期限のないアクセストークンは無期限に有効であるため、アクセストークンが漏洩した場合、セキュリティリスクとなります。

このリスクを管理するために、GitLab 16.0以降にアップグレードすると、有効期限のない[personal](../../user/profile/personal_access_tokens.md) 、[project](../../user/project/settings/project_access_tokens.md) 、または[group](../../user/group/settings/group_access_tokens.md)アクセストークンには、アップグレード日から1年後の有効期限が自動的に設定されます。

GitLab 17.3以降、既存のトークンに対するこの自動設定は元に戻され、[新しいアクセストークンの有効期限の適用を無効にすることができます](../../administration/settings/account_and_limit_settings.md#require-expiration-dates-for-new-access-tokens)。

日付が変更されたためにトークンの有効期限がいつ切れるかわからない場合は、その日付にGitLabにサインインしようとすると、予期しない認証の失敗が発生する可能性があります。

このイシューを管理するには、GitLab 17.2以降にアップグレードする必要があります。これらのバージョンには、[トークンの有効期限日付の分析、延長、または削除を支援するツール](../../administration/raketasks/tokens/_index.md)が含まれているためです。

ツールを実行できない場合は、GitLab Self-Managedインスタンスでスクリプトを実行して、次のいずれかのトークンを特定することもできます:

- 特定の日付に有効期限が切れます。
- 有効期限が設定されていません。

これらのスクリプトは、ターミナルウィンドウで次のいずれかで実行します:

- [Railsコンソールセッション](../../administration/operations/rails_console.md#starting-a-rails-console-session)。
- [Rails Runner](../../administration/operations/rails_console.md#using-the-rails-runner)を使用する。

実行する特定のスクリプトは、GitLab 16.0以降にアップグレードしたかどうかによって異なります:

- GitLab 16.0以降にまだアップグレードしていない場合は、有効期限のないトークンを特定します。
- GitLab 16.0以降にアップグレードした場合は、スクリプトを使用して次のいずれかを特定します:
  - [特定の日付に有効期限が切れるトークン](#find-all-tokens-expiring-on-a-specific-date)。
  - [特定の月に有効期限が切れるトークン](#find-tokens-expiring-in-a-given-month)。
  - [多数のトークンが有効期限切れになる日付](#identify-dates-when-many-tokens-expire)。

このイシューの影響を受けるトークンを特定したら、必要に応じて最後のスクリプトを実行して、特定のトークンのライフタイムを延長できます。

これらのスクリプトは、次の形式で結果を返します:

```plaintext
Expired group access token in Group ID 25, Token ID: 8, Name: Example Token, Scopes: ["read_api", "create_runner"], Last used:
Expired project access token in Project ID 2, Token ID: 9, Name: Test Token, Scopes: ["api", "read_registry", "write_registry"], Last used: 2022-02-11 13:22:14 UTC
```

詳細については、[インシデント18003](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18003)を参照してください。

### 特定の日付に有効期限が切れるすべてのトークンを検索する {#find-all-tokens-expiring-on-a-specific-date}

このスクリプトは、特定の日付に有効期限が切れるトークンを検索します。

前提要件: 

- インスタンスがGitLab 16.0にアップグレードされた正確な日付を知っている必要があります。

使用するには、次の手順に従います:

{{< tabs >}}

{{< tab title="Railsコンソールセッション" >}}

1. ターミナルウィンドウで、インスタンスに接続します。
1. `sudo gitlab-rails console`を使用してRailsコンソールセッションを開始します。
1. 必要に応じて、次のセクションから`expired_tokens.rb`全体をコピーするか、その後のセクションから`expired_tokens_date_range.rb`スクリプトをコピーして、コンソールに貼り付けます。`expires_at_date`を、インスタンスがGitLab 16.0にアップグレードされてから1年後の日付に変更します。
1. <kbd>Enter</kbd>キーを押します。

{{< /tab >}}

{{< tab title="Rails Runner" >}}

1. ターミナルウィンドウで、インスタンスに接続します。
1. 必要に応じて、次のセクションから`expired_tokens.rb`全体をコピーするか、その後のセクションから`expired_tokens_date_range.rb`スクリプトをコピーして、インスタンス上のファイルとして保存します:
   - 名前を`expired_tokens.rb`にします。
   - `expires_at_date`を、インスタンスがGitLab 16.0にアップグレードされてから1年後の日付に変更します。
   - ファイルは`git:git`からアクセスできる必要があります。
1. 次のコマンドを実行します。パスの部分は、実際の`expired_tokens.rb`ファイルへのフルパスに変更してください:

   ```shell
   sudo gitlab-rails runner /path/to/expired_tokens.rb
   ```

詳細については、[Railsランナーのトラブルシューティングセクション](../../administration/operations/rails_console.md#troubleshooting)を参照してください。

{{< /tab >}}

{{< /tabs >}}

#### `expired_tokens.rb` {#expired_tokensrb}

このスクリプトを使用するには、GitLabインスタンスがGitLab 16.0にアップグレードされた正確な日付を知っている必要があります。

```ruby
# Change this value to the date one year after your GitLab instance was upgraded.

expires_at_date = "2024-05-22"

# Check for expiring personal access tokens
PersonalAccessToken.owner_is_human.where(expires_at: expires_at_date).find_each do |token|
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

{{< alert type="note" >}}

ブロックされたユーザーに属するトークンを削除するには、`token.destroy!`のすぐ下に`if token.user.blocked?`を追加します。ただし、このアクションでは監査イベントは作成されません。[メソッド](../../api/personal_access_tokens.md#revoke-a-personal-access-token)とは異なります。

{{< /alert >}}

### 特定の月に有効期限が切れるトークンを検索する {#find-tokens-expiring-in-a-given-month}

このスクリプトは、特定の月に有効期限が切れるトークンを検索します。インスタンスがGitLab 16.0にアップグレードされた正確な日付を知る必要はありません。使用するには、次の手順に従います:

{{< tabs >}}

{{< tab title="Railsコンソールセッション" >}}

1. ターミナルウィンドウで、`sudo gitlab-rails console`を使用してRailsコンソールセッションを開始します。
1. 次のセクションから`expired_tokens_date_range.rb`スクリプト全体を貼り付けます。必要に応じて、`date_range`を別の範囲に変更します。
1. <kbd>Enter</kbd>キーを押します。

{{< /tab >}}

{{< tab title="Rails Runner" >}}

1. ターミナルウィンドウで、インスタンスに接続します。
1. 次のセクションから`expired_tokens_date_range.rb`スクリプト全体をコピーし、インスタンス上のファイルとして保存します:
   - 名前を`expired_tokens_date_range.rb`にします。
   - 必要に応じて、`date_range`を別の範囲に変更します。
   - ファイルは`git:git`からアクセスできる必要があります。
1. 次のコマンドを実行します。`/path/to/expired_tokens_date_range.rb`の部分は、実際の`expired_tokens_date_range.rb`ファイルへのフルパスに変更してください:

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
PersonalAccessToken.owner_is_human.where(expires_at: Date.today .. Date.today + date_range).find_each do |token|
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

### 多数のトークンが有効期限切れになる日付を特定する {#identify-dates-when-many-tokens-expire}

このスクリプトは、ほとんどのトークンが有効期限切れになる日付を特定します。チームがまだトークンローテーションを設定していない場合に備えて、このページの他のスクリプトと組み合わせて使用​​して、有効期限日が近づいている可能性のある大量のトークンを特定して拡張できます。

スクリプトは次の形式で結果を返します:

```plaintext
42 Personal access tokens will expire at 2024-06-27
17 Personal access tokens will expire at 2024-09-23
3 Personal access tokens will expire at 2024-08-13
```

使用するには、次の手順に従います:

{{< tabs >}}

{{< tab title="Railsコンソールセッション" >}}

1. ターミナルウィンドウで、`sudo gitlab-rails console`を使用してRailsコンソールセッションを開始します。
1. `dates_when_most_of_tokens_expire.rb`スクリプト全体を貼り付けます。
1. <kbd>Enter</kbd>キーを押します。

{{< /tab >}}

{{< tab title="Rails Runner" >}}

1. ターミナルウィンドウで、インスタンスに接続します。
1. この`dates_when_most_of_tokens_expire.rb`スクリプト全体をコピーし、インスタンス上のファイルとして保存します:
   - 名前を`dates_when_most_of_tokens_expire.rb`にします。
   - ファイルは`git:git`からアクセスできる必要があります。
1. 次のコマンドを実行します。`/path/to/dates_when_most_of_tokens_expire.rb`の部分は、実際の`dates_when_most_of_tokens_expire.rb`ファイルへのフルパスに変更してください:

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

### 有効期限のないトークンを検索する {#find-tokens-with-no-expiration-date}

このスクリプトは、有効期限のないトークンを検索します。`expires_at`は`NULL`です。まだGitLabバージョン16.0以降にアップグレードしていないユーザーの場合、トークン`expires_at`値は`NULL`であり、有効期限を追加するトークンを特定するために使用できます。

このスクリプトは、[Railsコンソール](../../administration/operations/rails_console.md)または[Railsランナー](../../administration/operations/rails_console.md#using-the-rails-runner)のいずれかで使用できます:

{{< tabs >}}

{{< tab title="Railsコンソールセッション" >}}

1. ターミナルウィンドウで、インスタンスに接続します。
1. `sudo gitlab-rails console`を使用してRailsコンソールセッションを開始します。
1. 次のセクションから`tokens_with_no_expiry.rb`スクリプト全体を貼り付けます。
1. <kbd>Enter</kbd>キーを押します。

{{< /tab >}}

{{< tab title="Rails Runner" >}}

1. ターミナルウィンドウで、インスタンスに接続します。
1. 次のセクションからこの`tokens_with_no_expiry.rb`スクリプト全体をコピーし、インスタンス上のファイルとして保存します:
   - 名前を`tokens_with_no_expiry.rb`にします。
   - ファイルは`git:git`からアクセスできる必要があります。
1. 次のコマンドを実行します。パスの部分は、実際の`tokens_with_no_expiry.rb`ファイルへのフルパスに変更してください:

   ```shell
   sudo gitlab-rails runner /path/to/tokens_with_no_expiry.rb
   ```

詳細については、[Railsランナーのトラブルシューティングセクション](../../administration/operations/rails_console.md#troubleshooting)を参照してください。

{{< /tab >}}

{{< /tabs >}}

#### `tokens_with_no_expiry.rb` {#tokens_with_no_expiryrb}

このスクリプトは、`expires_at`に値が設定されていないトークンを検索します。

   ```ruby
   # This script finds tokens which do not have an expires_at value set.

   # Check for expiring personal access tokens
   PersonalAccessToken.owner_is_human.where(expires_at: nil).find_each do |token|
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
