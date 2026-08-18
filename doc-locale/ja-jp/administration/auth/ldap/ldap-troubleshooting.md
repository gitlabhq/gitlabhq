---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: LDAPのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

管理者である場合は、次の情報を使用してLDAPのトラブルシューティングを行います。

## 一般的な問題とワークフロー {#common-problems--workflows}

### 接続 {#connection}

#### 接続が拒否されました {#connection-refused}

LDAPサーバーへの接続を試行したときに`Connection Refused`エラーメッセージが表示される場合は、GitLabで使用されているLDAPの`port`と`encryption`設定を確認してください。一般的な組み合わせは`encryption: 'plain'`および`port: 389`、または`encryption: 'simple_tls'`および`port: 636`です。

#### 接続タイムアウト {#connection-times-out}

GitLabがLDAPエンドポイントに到達できない場合、次のようなメッセージが表示されます:

```plaintext
Could not authenticate you from Ldapmain because "Connection timed out - user specified timeout".
```

LDAPプロバイダーやエンドポイントがオフラインであるか、またはGitLabからアクセスできない場合、LDAPユーザーは認証してサインインすることはできません。GitLabは、LDAPの停止中に認証を提供するために、LDAPユーザーの認証情報をキャッシュしたり保存したりしません。

このエラーが表示される場合は、LDAPプロバイダーまたは管理者にお問い合わせください。

#### 参照エラー {#referral-error}

ログに`LDAP search error: Referral`が表示される場合、またはLDAPグループ同期のトラブルシューティング時に、このエラーは設定の問題を示している可能性があります。LDAPの設定ファイル`/etc/gitlab/gitlab.rb` (Omnibus) または`config/gitlab.yml` (ソース) はYAML形式であり、インデントに注意が必要です。`group_base`および`admin_group`設定キーがサーバー識別子より2スペースインデントされていることを確認してください。デフォルトの識別子は`main`で、スニペットの例は次のとおりです:

```yaml
main: # 'main' is the GitLab 'provider ID' of this LDAP server
  label: 'LDAP'
  host: 'ldap.example.com'
  # ...
  group_base: 'cn=my_group,ou=groups,dc=example,dc=com'
  admin_group: 'my_admin_group'
```

#### LDAPのクエリ {#query-ldap}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

以下を使用して、RailsコンソールでLDAPを検索できます。実行したい内容に応じて、[ユーザー](#query-a-user-in-ldap)や[グループ](#query-a-group-in-ldap)を直接クエリするか、あるいは[`ldapsearch`](#ldapsearch)を使用する方がより適切かもしれません。

```ruby
adapter = Gitlab::Auth::Ldap::Adapter.new('ldapmain')
options = {
    # :base is required
    # use .base or .group_base
    base: adapter.config.group_base,

    # :filter is optional
    # 'cn' looks for all "cn"s under :base
    # '*' is the search string - here, it's a wildcard
    filter: Net::LDAP::Filter.eq('cn', '*'),

    # :attributes is optional
    # the attributes we want to get returned
    attributes: %w(dn cn memberuid member submember uniquemember memberof)
}
adapter.ldap_search(options)
```

フィルターでOIDを使用する場合は、`Net::LDAP::Filter.eq`を`Net::LDAP::Filter.construct`に置き換えてください:

```ruby
adapter = Gitlab::Auth::Ldap::Adapter.new('ldapmain')
options = {
    # :base is required
    # use .base or .group_base
    base: adapter.config.base,

    # :filter is optional
    # This filter includes OID 1.2.840.113556.1.4.1941
    # It will search for all direct and nested members of the group gitlab_grp in the LDAP directory
    filter: Net::LDAP::Filter.construct("(memberOf:1.2.840.113556.1.4.1941:=CN=gitlab_grp,DC=example,DC=com)"),

    # :attributes is optional
    # the attributes we want to get returned
    attributes: %w(dn cn memberuid member submember uniquemember memberof)
}
adapter.ldap_search(options)
```

これがどのように実行されるかの例については、[`Adapter`モジュールを確認してください](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ee/gitlab/auth/ldap/adapter.rb)。

### ユーザーサインイン {#user-sign-ins}

#### ユーザーが見つかりません {#no-users-are-found}

テストにより[接続が確認済み](#ldap-check)であるにもかかわらず、GitLabがLDAPユーザーを出力に表示しない場合、以下のいずれかが原因である可能性が高いです:

- `bind_dn`ユーザーには、ユーザーツリーをたどるための十分な権限がありません。
- ユーザーは[設定された`base`](_index.md#configure-ldap)の範囲内にありません。
- [設定された`user_filter`](_index.md#set-up-ldap-user-filter)がユーザーへのアクセスをブロックしています。

この場合、`/etc/gitlab/gitlab.rb`内の既存のLDAP設定を使用して[ldapsearch](#ldapsearch)を使うことで、上記のうちどれが該当するか確認できます。

#### ユーザーがサインインできません {#users-cannot-sign-in}

ユーザーがサインインできない理由はいくつか考えられます。まず、次の質問をご自身に問いかけてください:

- ユーザーはLDAPで[設定された`base`](_index.md#configure-ldap)の範囲内にありますか？サインインするには、ユーザーはこの`base`の範囲内にいる必要があります。
- ユーザーは[設定された`user_filter`](_index.md#set-up-ldap-user-filter)を通過しますか？設定されていない場合は、この質問は無視できます。設定されている場合は、サインインを許可されるにはユーザーもこのフィルターを通過する必要があります。
  - [`user_filter`](#debug-ldap-user-filter)のデバッグに関するドキュメントを参照してください。

前の質問が両方とも問題ない場合は、問題を再現しながらログ自体を調べてください。

- ユーザーにサインインを試してもらい、それが失敗するようにしてください。
- サインインに関するエラーやその他のメッセージがないか、[出力を確認してください](#gitlab-logs)。このページに記載されている他のエラーメッセージのいずれかが表示される場合があります。その場合は、そのセクションが問題の解決に役立ちます。

ログが問題の根本原因にたどり着かない場合は、[Railsコンソール](#rails-console)を使用して[このユーザーをクエリ](#query-a-user-in-ldap)し、GitLabがLDAPサーバー上のこのユーザーを読み取れるかどうかを確認してください。

さらに調査するために、[ユーザー同期をデバッグする](#sync-all-users)ことも役立ちます。

#### ユーザーにエラー`Invalid login or password.`が表示されます {#users-see-an-error-invalid-login-or-password}

{{< history >}}

- GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/438144)されました。

{{< /history >}}

このエラーが表示される場合、ユーザーは**LDAP**サインインフォームではなく、**標準**サインインフォームを使用してサインインしようとしている可能性があります。

解決するには、ユーザーに**LDAP**サインインフォームにLDAPユーザー名とパスワードを入力するように依頼してください。

#### サインイン時の無効な認証情報 {#invalid-credentials-on-sign-in}

使用されているサインイン認証情報がLDAPで正確である場合、問題のユーザーについて以下のことが真であることを確認してください:

- バインドしているユーザーが、ユーザーのツリーを読み取り、たどるための十分な権限を持っていることを確認してください。
- `user_filter`が有効なユーザーをブロックしていないことを確認してください。
- [LDAPチェックコマンド](#ldap-check)を実行して、LDAPの設定が正しく、[GitLabがユーザーを認識できる](#no-users-are-found)ことを確認してください。

#### LDAPアカウントのアクセスが拒否されました {#access-denied-for-your-ldap-account}

[監査担当者レベルのアクセス](../../auditor_users.md)を持つユーザーに影響を与える可能性のある[バグ](https://gitlab.com/gitlab-org/gitlab/-/issues/235930)があります。Premium/Ultimateからダウングレードする際、監査担当者ユーザーがサインインしようとすると、`Access denied for your LDAP account`というメッセージが表示される場合があります。

回避策として、影響を受けるユーザーのアクセスレベルを変更します。

前提条件: 

- 管理者アクセス権。

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**概要** > **ユーザー**を選択します。
1. 影響を受けるユーザーの名前を選択します。
1. 右上隅で、**編集**を選択します。
1. ユーザーのアクセスレベルを`Regular`から`Administrator`に変更します (またはその逆)。
1. ページの下部にある**変更を保存**を選択します。
1. 右上隅で、再度**編集**を選択します。
1. ユーザーの元のアクセスレベル (`Regular`または`Administrator`) を復元し、再度**変更を保存**を選択します。

ユーザーはサインインできるようになりました。

#### メールはすでに使用されています {#email-has-already-been-taken}

ユーザーが正しいLDAP認証情報でサインインしようとするとアクセスが拒否され、[production.log](../../logs/_index.md#productionlog)に次のようなエラーが表示されます:

```plaintext
(LDAP) Error saving user <USER DN> (email@example.com): ["Email has already been taken"]
```

このエラーは、LDAPのメールアドレス`email@example.com`を指しています。メールアドレスはGitLabで一意である必要があり、LDAPはユーザーのプライマリメール (多数のセカンダリメールのいずれかではなく) にリンクされます。別のユーザー (または同じユーザー) がメール`email@example.com`をセカンダリメールとして設定しており、このエラーが発生しています。

この競合するメールアドレスがどこから来ているかは、[Railsコンソール](#rails-console)を使用して確認できます。コンソールで、以下を実行します:

```ruby
# This searches for an email among the primary AND secondary emails
user = User.find_by_any_email('email@example.com')
user.username
```

これにより、どのユーザーがこのメールアドレスを持っているかがわかります。ここでのステップは2つあります:

- LDAPでサインインするときにこのユーザーの新しいGitLabユーザー名/ユーザーを作成するには、競合を削除するためにセカンダリメールを削除します。
- LDAPで使用するためにこのユーザーの既存のGitLabユーザー名/ユーザーを使用するには、このメールをセカンダリメールから削除し、プライマリメールにして、GitLabがこのプロファイルをLDAP識別子に関連付けられるようにします。

ユーザーはこれらのステップのいずれかを[自身のプロファイル](../../../user/profile/_index.md#access-your-user-profile)で行うことも、管理者が行うこともできます。

#### プロジェクト制限エラー {#projects-limit-errors}

以下のエラーは、制限または制約が有効になっているものの、関連するデータフィールドにデータが含まれていないことを示しています:

- `Projects limit can't be blank`。
- `Projects limit is not a number`。

これを解決するには、次の手順に従います:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. 以下の両方を展開します:
   - **アカウントと制限**。
   - **新しいユーザーアカウントの制限**。
1. 例えば、**デフォルトのプロジェクトの制限**または**Allowed domains for new user accounts**フィールドを確認し、適切な値が設定されていることを確認してください。

#### LDAPユーザーフィルターのデバッグ {#debug-ldap-user-filter}

[`ldapsearch`](#ldapsearch)を使用すると、設定した[ユーザーフィルター](_index.md#set-up-ldap-user-filter)が期待どおりのユーザーを返すことを確認するためにテストできます。

```shell
ldapsearch -H ldaps://$host:$port -D "$bind_dn" -y bind_dn_password.txt  -b "$base" "$user_filter" sAMAccountName
```

- `$`で始まる変数は、LDAPセクションの設定ファイルからの変数を指します。
- プレーン認証方法を使用している場合は、`ldaps://`を`ldap://`に置き換えてください。ポート`389`はデフォルトの`ldap://`ポートであり、`636`はデフォルトの`ldaps://`ポートです。
- `bind_dn`ユーザーのパスワードは`bind_dn_password.txt`にあると仮定しています。

#### 全ユーザーを同期 {#sync-all-users}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

手動[ユーザー同期](ldap_synchronization.md#user-sync)の出力は、GitLabがLDAPに対してユーザーを同期しようとしたときに何が起こるかを示します。[Railsコンソール](#rails-console)を開き、以下を実行します:

```ruby
Rails.logger.level = Logger::DEBUG

LdapSyncWorker.new.perform
```

次に、[出力の読み方](#example-console-output-after-a-user-sync)を学びます。

##### ユーザー同期後のコンソール出力例 {#example-console-output-after-a-user-sync}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

[手動ユーザー同期](#sync-all-users)の出力は非常に冗長で、単一ユーザーの成功した同期は次のようになります:

```shell
Syncing user John, email@example.com
  Identity Load (0.9ms)  SELECT  "identities".* FROM "identities" WHERE "identities"."user_id" = 20 AND (provider LIKE 'ldap%') LIMIT 1
Instantiating Gitlab::Auth::Ldap::Person with LDIF:
dn: cn=John Smith,ou=people,dc=example,dc=com
cn: John Smith
mail: email@example.com
memberof: cn=admin_staff,ou=people,dc=example,dc=com
uid: John

  UserSyncedAttributesMetadata Load (0.9ms)  SELECT  "user_synced_attributes_metadata".* FROM "user_synced_attributes_metadata" WHERE "user_synced_attributes_metadata"."user_id" = 20 LIMIT 1
   (0.3ms)  BEGIN
  Namespace Load (1.0ms)  SELECT  "namespaces".* FROM "namespaces" WHERE "namespaces"."owner_id" = 20 AND "namespaces"."type" IS NULL LIMIT 1
  Route Load (0.8ms)  SELECT  "routes".* FROM "routes" WHERE "routes"."source_id" = 27 AND "routes"."source_type" = 'Namespace' LIMIT 1
  Ci::Runner Load (1.1ms)  SELECT "ci_runners".* FROM "ci_runners" INNER JOIN "ci_runner_namespaces" ON "ci_runners"."id" = "ci_runner_namespaces"."runner_id" WHERE "ci_runner_namespaces"."namespace_id" = 27
   (0.7ms)  COMMIT
   (0.4ms)  BEGIN
  Route Load (0.8ms)  SELECT "routes".* FROM "routes" WHERE (LOWER("routes"."path") = LOWER('John'))
  Namespace Load (1.0ms)  SELECT  "namespaces".* FROM "namespaces" WHERE "namespaces"."id" = 27 LIMIT 1
  Route Exists (0.9ms)  SELECT  1 AS one FROM "routes" WHERE LOWER("routes"."path") = LOWER('John') AND "routes"."id" != 50 LIMIT 1
  User Update (1.1ms)  UPDATE "users" SET "updated_at" = '2019-10-17 14:40:59.751685', "last_credential_check_at" = '2019-10-17 14:40:59.738714' WHERE "users"."id" = 20
```

ここには多くの情報が含まれているため、デバッグに役立つ可能性のある点を確認していきましょう。

まず、GitLabは以前にLDAPでサインインしたすべてのユーザーを検索し、それらにイテレーションを行います。各ユーザーの同期は、GitLabに現在存在するユーザーのユーザー名とメールを含む次の行から始まります:

```shell
Syncing user John, email@example.com
```

特定のユーザーのGitLabメールが出力に見つからない場合、そのユーザーはまだLDAPでサインインしていません。

次に、GitLabは`identities`テーブルを検索し、このユーザーと設定されたLDAPプロバイダー間の既存のリンクを探します:

```sql
  Identity Load (0.9ms)  SELECT  "identities".* FROM "identities" WHERE "identities"."user_id" = 20 AND (provider LIKE 'ldap%') LIMIT 1
```

識別子オブジェクトには、GitLabがLDAPでユーザーを検索するために使用するDNが含まれています。DNが見つからない場合、代わりにメールが使用されます。このユーザーがLDAPで見つかったことがわかります:

```shell
Instantiating Gitlab::Auth::Ldap::Person with LDIF:
dn: cn=John Smith,ou=people,dc=example,dc=com
cn: John Smith
mail: email@example.com
memberof: cn=admin_staff,ou=people,dc=example,dc=com
uid: John
```

DNまたはメールのいずれかでLDAPにユーザーが見つからなかった場合、代わりに次のメッセージが表示されることがあります:

```shell
LDAP search error: No Such Object
```

この場合、ユーザーはブロックされます:

```shell
  User Update (0.4ms)  UPDATE "users" SET "state" = $1, "updated_at" = $2 WHERE "users"."id" = $3  [["state", "ldap_blocked"], ["updated_at", "2019-10-18 15:46:22.902177"], ["id", 20]]
```

LDAPでユーザーが見つかった後、残りの出力はGitLabデータベースをすべての変更で更新します。

#### LDAPでユーザーをクエリする {#query-a-user-in-ldap}

これは、GitLabがLDAPにアクセスして特定のユーザーを読み取れることをテストします。これにより、GitLab UIでサイレントに失敗しているように見える、LDAPへの接続またはクエリの潜在的なエラーが明らかになることがあります。

```ruby
Rails.logger.level = Logger::DEBUG

adapter = Gitlab::Auth::Ldap::Adapter.new('ldapmain') # If `main` is the LDAP provider
Gitlab::Auth::Ldap::Person.find_by_uid('<uid>', adapter)
```

### マージリクエスト承認ルール {#merge-request-approval-rules}

LDAP接続の問題が発生すると、同期操作中にユーザーがマージリクエスト承認ルールから削除されることがあります。これにより、承認ルールが空になり、無効とマークされる可能性があります。

#### LDAP接続が失われると、承認ルールは失敗します {#approval-rules-fail-when-ldap-connectivity-is-lost}

LDAPサーバーが一時的に利用できなくなるか、バインドアカウントが失敗した場合:

- LDAPベースの承認ルールで設定されたユーザーは、次の同期サイクル中に削除されることがあります。
- 残りのユーザーがいない承認ルールは[無効](../../../user/project/merge_requests/approvals/_index.md#invalid-rules)になります。
- 標準の承認ルールは**自動承認**とマークされ、マージをブロックしなくなります。
- マージリクエスト承認ポリシールールは**アクションが必要**とマークされ、引き続きマージをブロックします。

標準の承認ルールがサイレントにバイパスされるのを防ぐには:

- LDAPサーバーが高可用性と信頼性の高い接続性を備えていることを確認してください。
- LDAP同期操作の失敗を監視します。
- 重要なセキュリティ要件には、標準の承認ルールの代わりに[マージリクエスト承認ポリシー](../../../user/application_security/policies/merge_request_approval_policies.md)を使用してください。承認ポリシーはより強力な強制を提供し、オープンに失敗することはありません。

承認ルールの動作に関する詳細については、[無効なルール](../../../user/project/merge_requests/approvals/_index.md#invalid-rules)を参照してください。

LDAPの問題によりユーザーが承認ルールから削除された場合、LDAP接続が復元されても自動的に再追加されません。手動で承認ルールを復元するか、バックアップからリカバリする必要がある場合があります。

### グループメンバーシップ {#group-memberships}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

#### メンバーシップが付与されていません {#memberships-not-granted}

特定のユーザーがLDAPグループ同期を通じてGitLabグループに追加されるべきだと考えることがあるかもしれませんが、何らかの理由でそれが起こらない場合があります。状況をデバッグするためにいくつかのことを確認できます。

- LDAP設定に`group_base`が指定されていることを確認してください。[この設定](ldap_synchronization.md#group-sync)は、グループ同期が適切に機能するために必要です。
- 正しい[LDAPグループリンクがGitLabグループに追加されている](ldap_synchronization.md#add-group-links)ことを確認してください。
- ユーザーがLDAP識別子を持っていることを確認します:
  1. 管理者ユーザーとしてGitLabにサインインします。
  1. 右上隅で、**管理者**を選択します。
  1. 左側のサイドバーで、**概要** > **ユーザー**を選択します。
  1. ユーザーを検索します。
  1. ユーザー名を選択してユーザーを開きます。**編集**は選択しないでください。
  1. **識別子**タブを選択します。LDAP DNが`Identifier`として含まれるLDAP識別子が存在するはずです。そうでない場合、このユーザーはまだLDAPでサインインしていないため、まずサインインする必要があります。
- 1時間、または[設定された間隔](ldap_synchronization.md#adjust-ldap-sync-schedule)グループの同期を待機しました。処理を高速化するには、GitLabグループの**管理** > **メンバー**に移動して**Sync now**を押す (1つのグループを同期) か、[グループ同期Rakeタスクを実行](../../raketasks/ldap.md#run-a-group-sync)する (すべてのグループを同期) かのいずれかの方法があります。

すべてのチェックが問題ない場合は、Railsコンソールでより高度なデバッグに進んでください。

1. [Railsコンソール](#rails-console)を開きます。
1. テストするGitLabグループを選択します。このグループには、すでにLDAPグループリンクが設定されている必要があります。
1. デバッグログを有効にし、選択したGitLabグループを見つけ、[それをLDAPと同期](#sync-one-group)させます。
1. 同期の出力を確認してください。[ログ出力例](#example-console-output-after-a-group-sync)で、出力の読み方を参照してください。
1. ユーザーが追加されない理由がまだわからない場合は、[LDAPグループを直接クエリ](#query-a-group-in-ldap)して、リストされているメンバーを確認してください。
1. ユーザーのDNまたはUIDは、クエリされたグループのリストのいずれかに含まれていますか？ここにあるDNまたはUIDのいずれかは、以前に確認したLDAP識別子の「識別子」と一致する必要があります。そうでない場合、ユーザーはLDAPグループに存在しないようです。

#### LDAP同期が有効になっている場合、サービスアカウントユーザーをグループに追加できません {#cannot-add-service-account-user-to-group-when-ldap-sync-is-enabled}

グループでLDAP同期が有効になっている場合、「招待」ダイアログを使用して新しいグループメンバーを招待することはできません。

GitLab 16.8以降でこの問題を解決するには、[グループメンバーAPIエンドポイント](../../../api/group_members.md#add-a-group-member)を使用してサービスアカウントをグループに招待したり、グループから削除したりできます。

#### 管理者権限が付与されていません {#administrator-privileges-not-granted}

[LDAPグループに管理者ロールを割り当てる](ldap_synchronization.md#assign-an-admin-role-to-an-ldap-group)場合でも、設定されたユーザーに正しい管理者権限が付与されない場合は、以下の条件が真であることを確認してください:

- [`group_base`も設定されています](ldap_synchronization.md#group-sync)。
- `gitlab.rb`内の設定された`admin_group`は、DNまたは配列ではなくCNであること。
- このCNは、設定された`group_base`のスコープ内にあります。
- `admin_group`のメンバーは、すでにLDAP認証情報を使用してGitLabにサインインしています。GitLabは、アカウントがすでにLDAPに接続されているユーザーにのみ管理者アクセスを許可します。

以前の条件がすべて真であり、ユーザーがまだアクセスできない場合は、Railsコンソールで[手動グループ同期を実行](#sync-all-groups)し、[出力](#example-console-output-after-a-group-sync)を確認して、GitLabが`admin_group`を同期するときに何が起こるかを確認してください。

#### Sync nowボタンがUIでスタックする {#sync-now-button-stuck-in-the-ui}

グループの**グループ** > **メンバー**ページにある**Sync now**ボタンがスタックすることがあります。ボタンは、押されてページがリロードされた後にスタックします。その後、ボタンを再度選択することはできません。

**Sync now**ボタンは多くの理由でスタックすることがあり、特定の場合にはデバッグが必要です。以下に、考えられる2つの原因と問題への解決策を示します。

##### 無効なメンバーシップ {#invalid-memberships}

グループの一部のメンバーまたはリクエスタメンバーが無効である場合、**Sync now**ボタンはスタックします。この問題の可視性を改善するための進捗状況は、[関連するイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/348226)で追跡できます。[Railsコンソール](#rails-console)を使用して、この問題が**Sync now**ボタンがスタックする原因となっているかどうかを確認できます:

```ruby
# Find the group in question
group = Group.find_by(name: 'my_gitlab_group')

# Look for errors on the Group itself
group.valid?
group.errors.map(&:full_messages)

# Look for errors among the group's members and requesters
group.requesters.map(&:valid?)
group.requesters.map(&:errors).map(&:full_messages)
group.members.map(&:valid?)
group.members.map(&:errors).map(&:full_messages)
```

表示されたエラーは問題を特定し、解決策を示すことができます。例えば、サポートチームは次のエラーを確認しています:

```ruby
irb(main):018:0> group.members.map(&:errors).map(&:full_messages)
=> [["The member's email address is not allowed for this group. Go to the group's 'Settings > General' page, and check 'Restrict membership by email domain'."]]
```

このエラーは、管理者が[ドメインごとのメールによるグループメンバーシップを制限](../../../user/group/access_and_permissions.md#restrict-group-access-by-domain)することを選択したが、ドメインに誤入力があったことを示しています。ドメイン設定が修正された後、**Sync now**ボタンは再び機能しました。

##### Sidekiqノード上のLDAP設定の欠落 {#missing-ldap-configuration-on-sidekiq-nodes}

GitLabが複数のノードにスケールされ、Sidekiqを実行しているノード上の[`/etc/gitlab/gitlab.rb`](../../sidekiq/_index.md#configure-ldap-and-user-or-group-synchronization)からLDAP設定が欠落している場合、**Sync now**ボタンはスタックします。この場合、Sidekiqジョブが消えてしまうようです。

LDAPはSidekiqノードに必要です。LDAPには、ローカルLDAP設定を必要とする、非同期で実行される複数のジョブがあるためです:

- [ユーザー同期](ldap_synchronization.md#user-sync)。
- [グループ同期](ldap_synchronization.md#group-sync)。

不足しているLDAP設定が問題であるかどうかは、Sidekiqを実行している各ノードで[LDAPをチェックするRakeタスク](#ldap-check)を実行することでテストできます。このノードでLDAPが正しく設定されている場合、LDAPサーバーに接続し、ユーザーを返します。

この問題を解決するには、Sidekiqノードで[LDAPを設定](../../sidekiq/_index.md#configure-ldap-and-user-or-group-synchronization)します。設定したら、[LDAPをチェックするRakeタスク](#ldap-check)を実行して、GitLabノードがLDAPに接続できることを確認してください。

#### 全グループを同期 {#sync-all-groups}

> [!note]
> デバッグが不要な場合にすべてのグループを手動で同期するには、代わりに[Rakeタスクを使用](../../raketasks/ldap.md#run-a-group-sync)してください。

手動[グループ同期](ldap_synchronization.md#group-sync)の出力は、GitLabがLDAPに対してLDAPグループメンバーシップを同期するときに何が起こるかを示します。[Railsコンソール](#rails-console)を開き、以下を実行します:

```ruby
Rails.logger.level = Logger::DEBUG

LdapAllGroupsSyncWorker.new.perform
```

次に、[出力の読み方](#example-console-output-after-a-group-sync)を学びます。

##### グループ同期後のコンソール出力例 {#example-console-output-after-a-group-sync}

ユーザー同期の出力と同様に、[手動グループ同期](#sync-all-groups)の出力も非常に冗長です。しかし、多くの役立つ情報が含まれています。

実際に同期が開始される点を示します:

```shell
Started syncing 'ldapmain' provider for 'my_group' group
```

次のエントリは、GitLabがLDAPサーバーで認識するすべてのユーザーDNの配列を示しています。これらのDNは単一のLDAPグループのユーザーであり、GitLabグループのユーザーではありません。このGitLabグループに複数のLDAPグループがリンクされている場合、これと同様の複数のログエントリ (各LDAPグループごとに1つ) が表示されます。このログエントリにLDAPユーザーDNが表示されない場合、検索時にLDAPがユーザーを返していません。ユーザーが実際にLDAPグループに存在することを確認してください。

```shell
Members in 'ldap_group_1' LDAP group: ["uid=john0,ou=people,dc=example,dc=com",
"uid=mary0,ou=people,dc=example,dc=com", "uid=john1,ou=people,dc=example,dc=com",
"uid=mary1,ou=people,dc=example,dc=com", "uid=john2,ou=people,dc=example,dc=com",
"uid=mary2,ou=people,dc=example,dc=com", "uid=john3,ou=people,dc=example,dc=com",
"uid=mary3,ou=people,dc=example,dc=com", "uid=john4,ou=people,dc=example,dc=com",
"uid=mary4,ou=people,dc=example,dc=com"]
```

各エントリの直後に、解決されたメンバーアクセスレベルのハッシュが表示されます。このハッシュは、GitLabがこのグループへのアクセス権を持つべきだと考えるすべてのユーザーDNと、そのアクセスレベル（ロール）を表します。このハッシュは追加的であり、追加のLDAPグループ検索に基づいて、より多くのDNが追加されたり、既存のエントリが変更されたりする可能性があります。このエントリの最後の出現は、GitLabがグループに追加すべきだと考えるユーザーを正確に示しているはずです。

> [!note]
> 10は`Guest`、20は`Reporter`、25は`Security Manager`、30は`Developer`、40は`Maintainer`、50は`Owner`です。

```shell
Resolved 'my_group' group member access: {"uid=john0,ou=people,dc=example,dc=com"=>30,
"uid=mary0,ou=people,dc=example,dc=com"=>30, "uid=john1,ou=people,dc=example,dc=com"=>30,
"uid=mary1,ou=people,dc=example,dc=com"=>30, "uid=john2,ou=people,dc=example,dc=com"=>30,
"uid=mary2,ou=people,dc=example,dc=com"=>30, "uid=john3,ou=people,dc=example,dc=com"=>30,
"uid=mary3,ou=people,dc=example,dc=com"=>30, "uid=john4,ou=people,dc=example,dc=com"=>30,
"uid=mary4,ou=people,dc=example,dc=com"=>30}
```

次のような警告が表示されることは珍しくありません。これらは、GitLabがユーザーをグループに追加しようとしたが、そのユーザーがGitLabで見つからなかったことを示しています。通常、これは懸念事項ではありません。

特定のユーザーがすでにGitLabに存在すると考えるのに、このエントリが表示される場合は、GitLabに保存されているDNの不一致が原因である可能性があります。ユーザーのLDAP識別子を更新するには、[ユーザーDNとメールが変更されました](#user-dn-and-email-have-changed)を参照してください。

```shell
User with DN `uid=john0,ou=people,dc=example,dc=com` should have access
to 'my_group' group but there is no user in GitLab with that
identity. Membership will be updated when the user signs in for
the first time.
```

最後に、次のエントリは、このグループの同期が完了したことを示しています:

```shell
Finished syncing all providers for 'my_group' group
```

設定されたすべてのグループリンクが同期されると、GitLabは管理者または外部ユーザーを同期します:

```shell
Syncing admin users for 'ldapmain' provider
```

出力は単一グループの場合と同様に見え、その後にこの行が同期が完了したことを示します:

```shell
Finished syncing admin users for 'ldapmain' provider
```

[管理者ロールを割り当てていない](ldap_synchronization.md#assign-an-admin-role-to-an-ldap-group)場合、次のメッセージが表示されます:

```shell
No `admin_group` configured for 'ldapmain' provider. Skipping
```

#### 1つのグループを同期 {#sync-one-group}

 [すべてのグループの同期](#sync-all-groups)は、単一のGitLabグループのメンバーシップのトラブルシューティングのみに関心がある場合、多くのノイズを出力に生成する可能性があります。その場合、このグループを同期し、そのデバッグ出力を確認する方法は次のとおりです:

```ruby
Rails.logger.level = Logger::DEBUG

# Find the GitLab group.
# If the output is `nil`, the group could not be found.
# If a bunch of group attributes are in the output, your group was found successfully.
group = Group.find_by(name: 'my_gitlab_group')

# Sync this group against LDAP
EE::Gitlab::Auth::Ldap::Sync::Group.execute_all_providers(group)
```

出力は、[すべてのグループを同期したとき](#example-console-output-after-a-group-sync)に得られるものと似ています。

#### LDAPでグループをクエリする {#query-a-group-in-ldap}

GitLabがLDAPグループを読み取り、そのすべてのメンバーを確認できることを確認したい場合は、以下を実行できます:

```ruby
# Find the adapter and the group itself
adapter = Gitlab::Auth::Ldap::Adapter.new('ldapmain') # If `main` is the LDAP provider
ldap_group = EE::Gitlab::Auth::Ldap::Group.find_by_cn('group_cn_here', adapter)

# Find the members of the LDAP group
ldap_group.member_dns
ldap_group.member_uids
```

#### LDAP同期はグループからグループ作成者を削除しません {#ldap-synchronization-does-not-remove-group-creator-from-group}

 [LDAP同期](ldap_synchronization.md)は、ユーザーがグループに存在しない場合、LDAPグループの作成者をそのグループから削除するはずです。LDAP同期を実行してもこれが実行されない場合:

1. ユーザーをLDAPグループに追加します。
1. LDAPグループ同期が完了するまで待機します。
1. ユーザーをLDAPグループから削除します。

### ユーザーDNとメールが変更されました {#user-dn-and-email-have-changed}

プライマリメール**と** DNの両方がLDAPで変更された場合、GitLabはユーザーの正しいLDAPレコードを識別できません。その結果、GitLabはそのユーザーをブロックします。GitLabがLDAPレコードを見つけられるように、ユーザーの既存のGitLabプロファイルを以下のいずれかで更新します:

- 新しいプライマリメール。
- DN値。

次のスクリプトは、提供されたすべてのユーザーのメールを更新し、ブロックされたりアカウントにアクセスできなくなったりしないようにします。

> [!note]
> 次のスクリプトでは、新しいメールアドレスを持つ新しいアカウントが最初に削除されている必要があります。メールアドレスはGitLabで一意である必要があります。

[Railsコンソール](#rails-console)に移動し、以下を実行します:

```ruby
# Each entry must include the old username and the new email
emails = {
  'ORIGINAL_USERNAME' => 'NEW_EMAIL_ADDRESS',
  ...
}

emails.each do |username, email|
  user = User.find_by_username(username)
  user.email = email
  user.skip_reconfirmation!
  user.save!
end
```

その後、[UserSyncを実行](#sync-all-users)して、これらの各ユーザーの最新のDNを同期できます。

## AzureActivedirectoryV2から`Invalid grant`のため認証できませんでした {#could-not-authenticate-from-azureactivedirectoryv2-because-invalid-grant}

LDAPからSAMLに変換するときに、Azureで次のようなエラーが発生する場合があります:

```plaintext
Authentication failure! invalid_credentials: OAuth2::Error, invalid_grant.
```

この問題は、以下の両方が当てはまる場合に発生します:

- SAMLが設定された後も、ユーザーにLDAP識別子がまだ存在している。
- それらのユーザーに対してLDAPを無効にしている。

LDAPとAzureの両方のメタデータがログに記録され、それがAzureでエラーを生成します。

単一ユーザーの回避策は、**管理者** > **識別子**でユーザーからLDAP識別子を削除することです。

複数のLDAP識別子を削除するには、以下の`Could not authenticate you from Ldapmain because "Unknown provider"`エラーに対する回避策のいずれかを使用してください。

## エラー: `Could not authenticate you from Ldapmain because "Unknown provider"` {#error-could-not-authenticate-you-from-ldapmain-because-unknown-provider}

LDAPサーバーで認証するときに、次のエラーが発生する可能性があります:

```plaintext
Could not authenticate you from Ldapmain because "Unknown provider (ldapsecondary). available providers: ["ldapmain"]".
```

このエラーは、以前にLDAPサーバーで認証されたアカウントを使用している場合に発生します。そのLDAPサーバーがGitLab設定から名前が変更または削除されている場合です。例: 

- 最初から、GitLab設定の`ldap_servers`に`main`と`secondary`が設定されています。
- `secondary`設定が削除または`main`に名前が変更されました。
- サインインを試みるユーザーは`secondary`の`identify`レコードを持っていますが、それはもはや設定されていません。

[Railsコンソール](../../operations/rails_console.md)を使用して、影響を受けるユーザーを一覧表示し、どのLDAPサーバーの識別子を持っているかを確認します:

```ruby
ldap_identities = Identity.where(provider: "ldapsecondary")
ldap_identities.each do |identity|
  u=User.find_by_id(identity.user_id)
  ui=Identity.where(user_id: identity.user_id)
  puts "user: #{u.username}\n   #{u.email}\n   last activity: #{u.last_activity_on}\n   #{identity.provider} ID: #{identity.id} external: #{identity.extern_uid}"
  puts "   all identities:"
  ui.each do |alli|
    puts "    - #{alli.provider} ID: #{alli.id} external: #{alli.extern_uid}"
  end
end;nil
```

このエラーは2つの方法で解決できます。

### LDAPサーバーへの参照の名前を変更する {#rename-references-to-the-ldap-server}

この解決策は、LDAPサーバーが互いのレプリカであり、影響を受けるユーザーが設定されたLDAPサーバーを使用してサインインできる場合に適しています。例えば、ロードバランサーがLDAPの高可用性を管理するために使用され、個別のセカンダリサインインオプションが不要になった場合などです。

> [!note]
> LDAPサーバーが互いのレプリカでない場合、この解決策は影響を受けるユーザーがサインインできないようにします。

もはや設定されていないLDAPサーバーへの[参照の名前を変更する](../../raketasks/ldap.md#other-options)には、以下を実行します:

```shell
sudo gitlab-rake gitlab:ldap:rename_provider[ldapsecondary,ldapmain]
```

### 削除されたLDAPサーバーに関連する`identity`レコードを削除します {#remove-the-identity-records-that-relate-to-the-removed-ldap-server}

前提条件: 

- `auto_link_ldap_user`が有効になっていることを確認してください。

この解決策では、識別子が削除された後、影響を受けるユーザーは設定されたLDAPサーバーでサインインでき、新しい`identity`レコードがGitLabによって作成されます。

削除されたLDAPサーバーが`ldapsecondary`であったため、[Railsコンソール](../../operations/rails_console.md)で、すべての`ldapsecondary`識別子を削除します:

```ruby
ldap_identities = Identity.where(provider: "ldapsecondary")
ldap_identities.each do |identity|
  puts "Destroying identity: #{identity.id} #{identity.provider}: #{identity.extern_uid}"
  identity.destroy!
rescue => e
  puts 'Error generated when destroying identity:\n ' + e.to_s
end; nil
```

## 期限切れのライセンスが複数のLDAPサーバーでエラーを引き起こす {#expired-license-causes-errors-with-multiple-ldap-servers}

[複数のLDAPサーバー](_index.md#use-multiple-ldap-servers)を使用するには、有効なライセンスが必要です。期限切れのライセンスは次の原因となります:

- Webインターフェースでの`502`エラー。
- ログ内の次のエラー（実際の戦略名は`/etc/gitlab/gitlab.rb`で設定されている名前に依存します）:

  ```plaintext
  Could not find a strategy with name `Ldapsecondary'. Please ensure it is required or explicitly set it using the :strategy_class option. (Devise::OmniAuth::StrategyNotFound)
  ```

このエラーを解決するには、WebインターフェースなしでGitLabインスタンスに新しいライセンスを適用する必要があります:

1. すべての非プライマリLDAPサーバーのGitLab設定行を削除またはコメントアウトします。
1. [GitLabを再構成](../../restart_gitlab.md#reconfigure-a-linux-package-installation)して、一時的に1つのLDAPサーバーのみを使用するようにします。
1. [Railsコンソールを開きライセンスキーを追加](../../license_file.md#add-a-license-through-the-console)します。
1. GitLab設定で追加のLDAPサーバーを再度有効にし、GitLabを再構成します。

## ユーザーがグループから削除され、再度追加される {#users-are-being-removed-from-group-and-re-added-again}

グループ同期中にユーザーがグループに追加され、次の同期で削除されるということが繰り返し発生している場合、ユーザーが複数または冗長なLDAP識別子を持っていないことを確認してください。

それらの識別子の1つが、もはや使用されていない古いLDAPプロバイダー用に追加されたものである場合、[削除されたLDAPサーバーに関連する`identity`レコードを削除](#remove-the-identity-records-that-relate-to-the-removed-ldap-server)してください。

## デバッグツール {#debugging-tools}

### LDAPチェック {#ldap-check}

[LDAPをチェックするRakeタスク](../../raketasks/ldap.md#check)は、GitLabがLDAPへの接続を正常に確立し、ユーザーを読み取ることさえできるかどうかを判断するのに役立つ貴重なツールです。

接続を確立できない場合、それは設定の問題か、ファイアウォールが接続をブロックしているかのどちらかが原因である可能性が高いです。

- ファイアウォールが接続をブロックしておらず、LDAPサーバーがGitLabホストからアクセス可能であることを確認してください。
- Rakeチェック出力でエラーメッセージを探し、それがLDAP設定につながり、設定値（特に`host`、`port`、`bind_dn`、および`password`）が正しいことを確認してください。
- 接続失敗をさらにデバッグするには、[ログ](#gitlab-logs)で[エラー](#connection)を探します。

GitLabがLDAPに正常に接続できるがユーザーを返さない場合、[ユーザーが見つからない場合の対処法](#no-users-are-found)を参照してください。

### GitLabログ {#gitlab-logs}

LDAP設定によりユーザーアカウントがブロックまたはブロック解除された場合、メッセージは[`application_json.log`](../../logs/_index.md#application_jsonlog)に記録されます。

LDAPルックアップ中に予期せぬエラー（設定エラー、タイムアウト）が発生した場合、サインインは拒否され、メッセージは[`production.log`](../../logs/_index.md#productionlog)に記録されます。

### ldapsearch {#ldapsearch}

 `ldapsearch`は、LDAPサーバーをクエリできるユーティリティです。これを使用してLDAPの設定をテストし、使用している設定が期待どおりの結果を得られることを確認できます。

`ldapsearch`を使用する場合は、`gitlab.rb`設定ですでに指定したのと同じ設定を使用していることを確認し、それらの正確な設定が使用された場合に何が起こるかを確認できるようにしてください。

GitLabホストでこのコマンドを実行すると、GitLabホストとLDAPの間に障害がないことも確認できます。

例えば、次のGitLab設定を考えてみましょう:

```shell
gitlab_rails['ldap_servers'] = YAML.load <<-'EOS' # remember to close this block with 'EOS' below
   main: # 'main' is the GitLab 'provider ID' of this LDAP server
     label: 'LDAP'
     host: '127.0.0.1'
     port: 389
     uid: 'uid'
     encryption: 'plain'
     bind_dn: 'cn=admin,dc=ldap-testing,dc=example,dc=com'
     password: 'Password1'
     active_directory: true
     allow_username_or_email_login: false
     block_auto_created_users: false
     base: 'dc=ldap-testing,dc=example,dc=com'
     user_filter: ''
     attributes:
       username: ['uid', 'userid', 'sAMAccountName']
       email:    ['mail', 'email', 'userPrincipalName']
       name:       'cn'
       first_name: 'givenName'
       last_name:  'sn'
     group_base: 'ou=groups,dc=ldap-testing,dc=example,dc=com'
     admin_group: 'gitlab_admin'
EOS
```

`bind_dn`ユーザーを見つけるには、次の`ldapsearch`を実行します:

```shell
ldapsearch -D "cn=admin,dc=ldap-testing,dc=example,dc=com" \
  -w Password1 \
  -p 389 \
  -h 127.0.0.1 \
  -b "dc=ldap-testing,dc=example,dc=com"
```

`bind_dn`、`password`、`port`、`host`、および`base`はすべて、`gitlab.rb`で設定されているものと同一です。

#### `start_tls`暗号化でldapsearchを使用する {#use-ldapsearch-with-start_tls-encryption}

前の例では、プレーンテキストでポート389にLDAPテストを実行します。[`start_tls`暗号化](_index.md#basic-configuration-settings)を使用している場合は、`ldapsearch`コマンドに以下を含めます:

- `-Z`フラグ。
- LDAPサーバーのFQDN。

これらを含める必要があります。なぜなら、TLSネゴシエーション中にLDAPサーバーのFQDNがその証明書に対して評価されるためです:

```shell
ldapsearch -D "cn=admin,dc=ldap-testing,dc=example,dc=com" \
  -w Password1 \
  -p 389 \
  -h "testing.ldap.com" \
  -b "dc=ldap-testing,dc=example,dc=com" -Z
```

#### `simple_tls`暗号化でldapsearchを使用する {#use-ldapsearch-with-simple_tls-encryption}

[`simple_tls`暗号化](_index.md#basic-configuration-settings) (通常はポート636) を使用している場合は、`ldapsearch`コマンドに以下を含めます:

- `-H`フラグとポートを含むLDAPサーバーFQDN。
- 完全な構築されたURI。

```shell
ldapsearch -D "cn=admin,dc=ldap-testing,dc=example,dc=com" \
  -w Password1 \
  -H "ldaps://testing.ldap.com:636" \
  -b "dc=ldap-testing,dc=example,dc=com"
```

詳細については、[公式の`ldapsearch`ドキュメント](https://linux.die.net/man/1/ldapsearch)を参照してください。

### **AdFind**の使用 (Windows) {#using-adfind-windows}

[`AdFind`](https://learn.microsoft.com/en-us/archive/technet-wiki/7535.adfind-command-examples)ユーティリティ (Windowsベースのシステム) を使用して、LDAPサーバーにアクセス可能で認証が正しく機能していることをテストできます。AdFindは[Joe Richards](https://www.joeware.net/freetools/tools/adfind/index.htm)によって作成されたフリーウェアユーティリティです。

 **すべてのオブジェクトを返す**

フィルター`objectclass=*`を使用して、すべてのディレクトリオブジェクトを返すことができます。

```shell
adfind -h ad.example.org:636 -ssl -u "CN=GitLabSRV,CN=Users,DC=GitLab,DC=org" -up Password1 -b "OU=GitLab INT,DC=GitLab,DC=org" -f (objectClass=*)
```

 **フィルターを使用して単一のオブジェクトを返す**

オブジェクト名または完全な**DN**を**指定**することで、単一のオブジェクトを取得することもできます。この例では、オブジェクト名のみ`CN=Leroy Fox`を指定します。

```shell
adfind -h ad.example.org:636 -ssl -u "CN=GitLabSRV,CN=Users,DC=GitLab,DC=org" -up Password1 -b "OU=GitLab INT,DC=GitLab,DC=org" -f "(&(objectcategory=person)(CN=Leroy Fox))"
```

### Railsコンソール {#rails-console}

> [!warning]
> Railsコンソールを使用すると、データの作成、読み取り、変更、および削除が非常に簡単です。コマンドはリストされているとおりに正確に実行してください。

Railsコンソールは、LDAPの問題をデバッグするのに役立つ貴重なツールです。コマンドを実行し、GitLabがそれらにどのように応答するかを確認することで、アプリケーションと直接対話できます。

Railsコンソールの使用方法については、この[ガイド](../../operations/rails_console.md#starting-a-rails-console-session)を参照してください。

#### デバッグ出力を有効にする {#enable-debug-output}

これにより、GitLabが何をしているか、そして何を扱っているかを示すデバッグ出力が提供されます。この値は永続化されず、Railsコンソールのこのセッションでのみ有効になります。

Railsコンソールでデバッグ出力を有効にするには、[Railsコンソールを開き](#rails-console)、以下を実行します:

```ruby
Rails.logger.level = Logger::DEBUG
```

#### グループ、サブグループ、メンバー、およびリクエスタに関連するすべてのエラーメッセージを取得する {#get-all-error-messages-associated-with-groups-subgroups-members-and-requesters}

グループ、サブグループ、メンバー、およびリクエスタに関連するエラーメッセージを収集します。これは、Webインターフェースに表示されない可能性のあるエラーメッセージをキャプチャします。これは、[LDAPグループ同期](ldap_synchronization.md#group-sync)の問題や、ユーザーとグループおよびサブグループのメンバーシップに関する予期せぬ動作のトラブルシューティングに特に役立ちます。

```ruby
# Find the group and subgroup
group = Group.find_by_full_path("parent_group")
subgroup = Group.find_by_full_path("parent_group/child_group")

# Group and subgroup errors
group.valid?
group.errors.map(&:full_messages)

subgroup.valid?
subgroup.errors.map(&:full_messages)

# Group and subgroup errors for the members AND requesters
group.requesters.map(&:valid?)
group.requesters.map(&:errors).map(&:full_messages)
group.members.map(&:valid?)
group.members.map(&:errors).map(&:full_messages)
group.members_and_requesters.map(&:errors).map(&:full_messages)

subgroup.requesters.map(&:valid?)
subgroup.requesters.map(&:errors).map(&:full_messages)
subgroup.members.map(&:valid?)
subgroup.members.map(&:errors).map(&:full_messages)
subgroup.members_and_requesters.map(&:errors).map(&:full_messages)
```
