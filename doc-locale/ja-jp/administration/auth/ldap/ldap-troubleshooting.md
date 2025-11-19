---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: LDAPの問題を解決する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

管理者の方は、以下の情報を利用してLDAPのトラブルシューティングを行ってください。

## 一般的な問題とワークフロー {#common-problems--workflows}

### 接続 {#connection}

#### 接続拒否 {#connection-refused}

LDAPサーバーへの接続を試みるときに`Connection Refused`エラーメッセージが表示される場合は、GitLabで使用されているLDAPの`port`および`encryption`の設定を確認してください。一般的な組み合わせは、`encryption: 'plain'`と`port: 389`、または`encryption: 'simple_tls'`と`port: 636`です。

#### 接続がタイムアウトする {#connection-times-out}

GitLabがLDAPエンドポイントに到達できない場合は、次のようなメッセージが表示されます:

```plaintext
Could not authenticate you from Ldapmain because "Connection timed out - user specified timeout".
```

構成したLDAPプロバイダーやエンドポイントがオフラインの場合、またはGitLabから到達できない場合は、どのLDAPユーザーも認証してサインインできません。GitLabは、LDAPの停止時に認証を提供するために、LDAPユーザーの認証情報をキャッシュまたは保存しません。

このエラーが表示された場合は、LDAPプロバイダーまたは管理者にお問い合わせください。

#### 紹介エラー {#referral-error}

ログに`LDAP search error: Referral`が表示される場合、またはトラブルシューティングLDAPグループ同期時に、このエラーは設定の問題を示している可能性があります。LDAPの設定`/etc/gitlab/gitlab.rb` (Omnibus) または`config/gitlab.yml` (ソース) は、YAML形式で記述されており、インデントの影響を受けやすくなっています。`group_base`および`admin_group`設定キーが、サーバー識別子より2つスペース分インデントされていることを確認してください。デフォルトの識別子は`main`で、コードスニペットの例は次のようになります:

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

以下を使用すると、Railsコンソールを使用してLDAPで検索を実行できます。実行しようとしていることに応じて、[ユーザー](#query-a-user-in-ldap)または[グループ](#query-a-group-in-ldap)に直接クエリを実行するか、代わりに[`ldapsearch`を使用](#ldapsearch)すると、より意味をなす場合があります。

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

フィルターでOIDを使用する場合は、`Net::LDAP::Filter.eq`を`Net::LDAP::Filter.construct`に置き換えます:

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

これの実行方法の例については、[`Adapter`モジュールをレビューしてください](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ee/gitlab/auth/ldap/adapter.rb)。

### ユーザーサインイン {#user-sign-ins}

#### ユーザーが見つかりません {#no-users-are-found}

[確認済み](#ldap-check)のLDAPへの接続を確立できるものの、GitLabが出力にLDAPユーザーを表示しない場合は、次のいずれかが当てはまる可能性が非常に高くなります:

- `bind_dn`ユーザーには、ユーザーツリーを走査するのに十分な権限がありません。
- ユーザーが[設定された`base`](_index.md#configure-ldap)に該当しません。
- [設定された`user_filter`](_index.md#set-up-ldap-user-filter)により、ユーザーへのアクセスがブロックされます。

この場合、`/etc/gitlab/gitlab.rb`にある既存のLDAPの設定で[ldapsearch](#ldapsearch)を使用して、以前のどれが当てはまるかを確認できます。

#### ユーザーがサインインできない {#users-cannot-sign-in}

ユーザーは、さまざまな理由でサインインできないことがあります。まず、自問すべき質問をいくつか示します:

- ユーザーはLDAPの[設定された`base`](_index.md#configure-ldap)に該当しますか？ユーザーがサインインするには、この`base`に該当する必要があります。
- ユーザーは[設定された`user_filter`](_index.md#set-up-ldap-user-filter)を通過しますか？構成されていない場合は、この質問を無視できます。構成されている場合は、サインインを許可されるには、ユーザーもこのフィルターを通過する必要があります。
  - [`user_filter`のデバッグ](#debug-ldap-user-filter)に関するドキュメントを参照してください。

上記の両方の質問に問題がない場合、問題の根本を探す次の場所は、問題を再現しながらログ自体を確認することです。

- ユーザーにサインインさせて、失敗させます。
- サインインに関するエラーやその他のメッセージについて、[出力を確認して](#gitlab-logs)ください。このページの他のエラーメッセージのいずれかが表示される場合があります。その場合、そのセクションが問題の解決に役立ちます。

ログが問題の根本原因につながらない場合は、[Railsコンソール](#rails-console)を使用して[このユーザーをクエリする](#query-a-user-in-ldap)ことで、GitLabがLDAPサーバー上でこのユーザーを読み取りできるかどうかを確認してください。

[ユーザー同期をデバッグする](#sync-all-users)と、さらに調査に役立つ場合があります。

#### ユーザーに「ログインまたはパスワードが無効です」というエラーが表示される {#users-see-an-error-invalid-login-or-password}

{{< history >}}

- GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/438144)されました。

{{< /history >}}

このエラーがユーザーに表示される場合、**標準**サインインフォームではなく、**LDAP**サインインフォームを使用してサインインしようとしていることが原因である可能性があります。

解決するには、ユーザーにLDAPのユーザー名とパスワードを**LDAP**サインインフォームに入力するように依頼してください。

#### サインイン時の認証情報が無効 {#invalid-credentials-on-sign-in}

使用されているサインイン認証情報がLDAPで正確である場合、問題のユーザーについて以下が当てはまることを確認してください:

- バインドしているユーザーに、ユーザーのツリーを読み取り、走査するのに十分な権限があることを確認してください。
- `user_filter`が、それ以外の場合は有効なユーザーをブロックしていないことを確認してください。
- LDAPの設定が正しいことを確認するために[LDAPチェックコマンドを実行](#ldap-check)し、[GitLabがユーザーを認識できる](#no-users-are-found)ことを確認します。

#### LDAPアカウントへのアクセスが拒否されました {#access-denied-for-your-ldap-account}

[バグ](https://gitlab.com/gitlab-org/gitlab/-/issues/235930)があり、[監査担当者レベルのアクセス](../../auditor_users.md)を持つユーザーに影響を与える可能性があります。Premium/Ultimateプランからダウングレードすると、サインインしようとする監査担当者ユーザーに次のメッセージが表示される場合があります。`Access denied for your LDAP account`。

影響を受けるユーザーのアクセスレベル切り替えることに基づいて、回避策があります:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 影響を受けるユーザーの名前を選択します。
1. 右上隅で、**編集**を選択します。
1. ユーザーのアクセスレベルを`Regular`から`Administrator`に変更します (またはその逆)。
1. ページの下部にある**変更を保存**を選択します。
1. 右上隅で、もう一度**編集**を選択します。
1. ユーザーの元のアクセスレベル (`Regular`または`Administrator`) を復元し、もう一度**変更を保存**を選択します。

これで、ユーザーはサインインできるようになります。

#### メールアドレスがすでに取得されています {#email-has-already-been-taken}

ユーザーが正しいLDAPの認証情報でサインインしようとすると、アクセスが拒否され、[production.log](../../logs/_index.md#productionlog)に次のようなエラーが表示されます:

```plaintext
(LDAP) Error saving user <USER DN> (email@example.com): ["Email has already been taken"]
```

このエラーは、LDAPのメールアドレスである`email@example.com`を参照しています。メールアドレスはGitLabで一意である必要があり、LDAPはユーザーのプライマリメール (可能性のある多数のセカンダリメールとは対照的) にリンクします。別のユーザー (または同じユーザー) が、`email@example.com`メールをセカンダリメールとして設定しているため、このエラーが発生しています。

この競合するメールアドレスの出所を、[Railsコンソール](#rails-console)を使用して確認できます。コンソールで、以下を実行します:

```ruby
# This searches for an email among the primary AND secondary emails
user = User.find_by_any_email('email@example.com')
user.username
```

これにより、どのユーザーがこのメールアドレスを持っているかがわかります。ここで、次の2つのステップのいずれかを実行する必要があります:

- LDAPでサインインするときにこのユーザーの新しいGitLabユーザー/ユーザー名を作成するには、セカンダリメールを削除して競合を解消します。
- このユーザーがLDAPで使用するために既存のGitLabユーザー/ユーザー名を使用するには、このメールをセカンダリメールとして削除し、プライマリメールにして、GitLabがこのプロファイルをLDAPの識別子に関連付けるようにします。

ユーザーは、[自分のプロファイル](../../../user/profile/_index.md#access-your-user-profile)でこれらの手順のいずれかを実行するか、管理者が実行できます。

#### プロジェクトの制限エラー {#projects-limit-errors}

次のエラーは、制限が有効になっているものの、関連するデータフィールドにデータが含まれていないことを示しています:

- `Projects limit can't be blank`。
- `Projects limit is not a number`。

これを解決するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. 次の両方を展開します:
   - **アカウントと制限**。
   - **新規登録の制限**。
1. たとえば、**デフォルトのプロジェクトの制限**フィールドまたは**サインアップに許可されたドメイン**フィールドを確認し、関連する値が構成されていることを確認します。

#### LDAPユーザーフィルターをデバッグする {#debug-ldap-user-filter}

[`ldapsearch`](#ldapsearch)を使用すると、構成済みの[ユーザーフィルター](_index.md#set-up-ldap-user-filter)をテストして、予期したユーザーが返されることを確認できます。

```shell
ldapsearch -H ldaps://$host:$port -D "$bind_dn" -y bind_dn_password.txt  -b "$base" "$user_filter" sAMAccountName
```

- `$`で始まる変数は、設定ファイルのLDAPセクションからの変数を参照します。
- プレーン認証方式を使用している場合は、`ldaps://`を`ldap://`に置き換えます。ポート`389`はデフォルトの`ldap://`ポートで、`636`はデフォルトの`ldaps://`ポートです。
- `bind_dn`ユーザーのパスワードが`bind_dn_password.txt`にあることを前提としています。

#### すべてのユーザーを同期する {#sync-all-users}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

手動による[ユーザー同期](ldap_synchronization.md#user-sync)からの出力は、GitLabがそのユーザーをLDAPと照合して同期しようとするときに何が起こるかを示します。[Railsコンソール](#rails-console)を入力し、以下を実行します:

```ruby
Rails.logger.level = Logger::DEBUG

LdapSyncWorker.new.perform
```

次に、[出力の読み取り方](#example-console-output-after-a-user-sync)を学びます。

##### ユーザー同期後のコンソールの出力例 {#example-console-output-after-a-user-sync}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

[手動によるユーザー同期](#sync-all-users)からの出力は非常に詳細であり、1人のユーザーの同期が成功すると、次のようになります:

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

ここには多くの情報があるので、デバッグするときに役立つ可能性のあることについて説明しましょう。

まず、GitLabは、以前にLDAPでサインインしたすべてのユーザーを探し、それらをイテレーションを行うします。各ユーザーの同期は、GitLabに存在するユーザーのユーザー名とメールを含む次の行から始まります:

```shell
Syncing user John, email@example.com
```

特定のユーザーのGitLabメールが出力に表示されない場合、そのユーザーはまだLDAPでサインインしていません。

次に、GitLabは、このユーザーと構成済みのLDAPプロバイダー間の既存のリンクについて、その`identities`テーブルを検索します:

```sql
  Identity Load (0.9ms)  SELECT  "identities".* FROM "identities" WHERE "identities"."user_id" = 20 AND (provider LIKE 'ldap%') LIMIT 1
```

識別子オブジェクトには、GitLabがLDAPでユーザーを検索するために使用するDNがあります。DNが見つからない場合は、代わりにメールアドレスが使用されます。このユーザーがLDAPで見つかったことがわかります:

```shell
Instantiating Gitlab::Auth::Ldap::Person with LDIF:
dn: cn=John Smith,ou=people,dc=example,dc=com
cn: John Smith
mail: email@example.com
memberof: cn=admin_staff,ou=people,dc=example,dc=com
uid: John
```

DNまたはメールのいずれかでユーザーがLDAPで見つからなかった場合は、代わりに次のメッセージが表示されることがあります:

```shell
LDAP search error: No Such Object
```

この場合、ユーザーはブロックされます:

```shell
  User Update (0.4ms)  UPDATE "users" SET "state" = $1, "updated_at" = $2 WHERE "users"."id" = $3  [["state", "ldap_blocked"], ["updated_at", "2019-10-18 15:46:22.902177"], ["id", 20]]
```

ユーザーがLDAPで見つかった後、出力の残りの部分は、変更内容でGitLabデータベースを更新します。

#### LDAPでユーザーをクエリする {#query-a-user-in-ldap}

これは、GitLabがLDAPにアクセスして特定のユーザーを読み取りできるかどうかをテストします。GitLabのUIで静かに失敗するように見える、LDAPへの接続およびクエリに関する潜在的なエラーを公開できます。

```ruby
Rails.logger.level = Logger::DEBUG

adapter = Gitlab::Auth::Ldap::Adapter.new('ldapmain') # If `main` is the LDAP provider
Gitlab::Auth::Ldap::Person.find_by_uid('<uid>', adapter)
```

### グループメンバーシップ {#group-memberships}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

#### 許可されていないグループメンバーシップ {#memberships-not-granted}

特定のユーザーがLDAPグループ同期を介してGitLabグループに追加されるべきであると考えているのに、何らかの理由でそうならない場合があります。状況をデバッグするために、いくつかのことを確認できます。

- LDAPの設定に`group_base`が指定されていることを確認してください。[この設定](ldap_synchronization.md#group-sync)は、グループ同期が適切に機能するために必要です。
- 正しい[LDAPグループリンクがGitLabグループに追加されていることを確認](ldap_synchronization.md#add-group-links)します。
- ユーザーがLDAPの識別子を持っていることを確認してください:
  1. 管理者ユーザーとしてGitLabにサインインします。
  1. 左側のサイドバーの下部で、**管理者**を選択します。
  1. 左側のサイドバーで、**概要** > **ユーザー**を選択します。
  1. ユーザーを検索します。
  1. 名前を選択してユーザーを開きます。**編集**を選択しないでください。
  1. **識別子**タブを選択します。`Identifier`としてLDAP DNを持つLDAP識別子があるはずです。そうでない場合、このユーザーはまだLDAPでサインインしていないため、最初にサインインする必要があります。
- 1時間、または[設定された間隔](ldap_synchronization.md#adjust-ldap-group-sync-schedule)だけグループが同期されるのを待ちました。プロセスを高速化するには、GitLabグループの**管理** > **メンバー**に移動して**Sync now** (1つのグループを同期する) を押すか、[グループ同期Rakeタスクを実行](../../raketasks/ldap.md#run-a-group-sync) (すべてのグループを同期する) します。

すべてのチェックが問題ないように見える場合は、Railsコンソールでより高度なデバッグに飛び込みます。

1. [Railsコンソール](#rails-console)を使用します。
1. テストするGitLabグループを選択します。このグループには、すでに設定されているLDAPグループリンクが必要です。
1. デバッグログを有効にし、選択したGitLabグループを見つけて、[LDAPと同期します](#sync-one-group)。
1. 同期の出力を調べます。出力の読み取り方法については、[ログ出力例](#example-console-output-after-a-group-sync)を参照してください。
1. ユーザーが追加されない理由がまだわからない場合は、[LDAPグループに直接クエリを実行](#query-a-group-in-ldap)して、リストされているメンバーを確認します。
1. ユーザーのDNまたはUIDは、クエリされたグループからのリストの1つにありますか？ここにあるDNまたはUIDの1つは、以前にチェックしたLDAP識別子からの「識別子」と一致する必要があります。そうでない場合、ユーザーはLDAPグループに存在しないようです。

#### LDAP同期が有効になっている場合、サービスアカウントユーザーをグループに追加できません {#cannot-add-service-account-user-to-group-when-ldap-sync-is-enabled}

LDAP同期がグループに対して有効になっている場合、「招待」ダイアログを使用して新しいグループメンバーを招待することはできません。

GitLab 16.8以降でこの問題を解決するには、[グループメンバーAPIエンドポイント](../../../api/members.md#add-a-member-to-a-group-or-project)を使用して、サービスアカウントをグループに招待したり、削除することができます。

#### 管理者の特権が付与されていません {#administrator-privileges-not-granted}

[管理者同期](ldap_synchronization.md#administrator-sync)が設定されているのに、構成されたユーザーに正しい管理者権限が付与されない場合は、次の条件が満たされていることを確認してください:

- [`group_base`も設定されています](ldap_synchronization.md#group-sync)。
- `admin_group`の設定された`gitlab.rb`は、DNまたは配列ではなく、CNです。
- このCNは、設定された`group_base`のスコープに該当します。
- `admin_group`のメンバーは、すでにLDAPの認証情報でGitLabにサインインしています。GitLabは、アカウントがすでにLDAPに接続されているユーザーにのみ管理者アクセス権を付与します。

上記のすべての条件が満たされていても、ユーザーがアクセス権を取得できない場合は、Railsコンソールで[手動グループ同期を実行](#sync-all-groups)し、[出力を調べて](#example-console-output-after-a-group-sync)、GitLabが`admin_group`を同期するときに何が起こるかを確認します。

#### UIで今すぐ同期ボタンが停止している {#sync-now-button-stuck-in-the-ui}

グループの**グループ** > **メンバー**ページにある**Sync now**ボタンが停止することがあります。ボタンを押してページがリロードされると、ボタンが停止します。ボタンは再び選択できなくなります。

**Sync now**ボタンがさまざまな理由で停止することがあり、特定のケースではデバッグが必要です。以下は、2つの考えられる原因と問題の考えられる解決策です。

##### 無効なグループメンバーシップ {#invalid-memberships}

**Sync now**ボタンは、グループのメンバーまたはリクエスターの一部が無効な場合、停止します。この問題の表示レベルを改善する進捗状況は、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/348226)で追跡するできます。[Railsコンソール](#rails-console)を使用して、この問題が**Sync now**ボタンが停止する原因になっているかどうかを確認できます:

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

表示されたエラーは、問題を特定し、解決策を示すことができます。たとえば、サポートチームは次のエラーを確認しました:

```ruby
irb(main):018:0> group.members.map(&:errors).map(&:full_messages)
=> [["The member's email address is not allowed for this group. Go to the group's &#39;Settings &gt; General&#39; page, and check &#39;Restrict membership by email domain&#39;."]]
```

このエラーは、管理者が[メールメールドメインでグループメンバーシップを制限する](../../../user/group/access_and_permissions.md#restrict-group-access-by-domain)ことを選択したが、ドメインにタイプミスがあったことを示していました。ドメイン設定を修正した後、**Sync now**ボタンが再度機能しました。

##### SidekiqノードでのLDAP設定の欠落 {#missing-ldap-configuration-on-sidekiq-nodes}

**Sync now**ボタンは、GitLabが複数のノードにスケールされ、Sidekiqを実行しているノードの[`/etc/gitlab/gitlab.rb`にLDAP設定がない場合、停止します。](../../sidekiq/_index.md#configure-ldap-and-user-or-group-synchronization)この場合、Sidekiqジョブが消えているように見えます。

LDAPにはローカルLDAP設定を必要とする非同期的に実行される複数のジョブがあるため、SidekiqノードでLDAPが必要です:

- [ユーザー同期](ldap_synchronization.md#user-sync)。
- [グループ同期](ldap_synchronization.md#group-sync)。

不足しているLDAP設定が問題であるかどうかをテストするには、Sidekiqを実行している各ノードで[LDAPをチェックするRakeタスク](#ldap-check)を実行します。このノードでLDAPが正しくセットアップされている場合、LDAPサーバーに接続してユーザーを返します。

この問題を解決するには、Sidekiqノードで[LDAPを設定します](../../sidekiq/_index.md#configure-ldap-and-user-or-group-synchronization)。設定したら、GitLabノードがLDAPに接続できることを確認するために、[LDAPをチェックするRakeタスク](#ldap-check)を実行します。

#### すべてのグループを同期 {#sync-all-groups}

{{< alert type="note" >}}

デバッグが不要な場合にすべてのグループを手動で同期するには、代わりに[Rakeタスクを使用](../../raketasks/ldap.md#run-a-group-sync)します。

{{< /alert >}}

手動[グループ同期](ldap_synchronization.md#group-sync)からの出力は、GitLabがLDAPグループのグループメンバーシップをLDAPと同期するときに何が起こるかを示すことができます。[Railsコンソール](#rails-console)を入力し、以下を実行します:

```ruby
Rails.logger.level = Logger::DEBUG

LdapAllGroupsSyncWorker.new.perform
```

次に、[出力の読み取り方](#example-console-output-after-a-group-sync)を学びます。

##### グループ同期後のコンソールの出力例 {#example-console-output-after-a-group-sync}

ユーザー同期からの出力と同様に、[手動グループ同期](#sync-all-groups)からの出力も非常に冗長です。ただし、役立つ情報がたくさん含まれています。

同期が実際に開始されるポイントを示します:

```shell
Started syncing 'ldapmain' provider for 'my_group' group
```

次のエントリは、GitLabがLDAPサーバーで認識するすべてのユーザーDNの配列を示しています。これらのDNは、GitLabグループではなく、単一のLDAPグループのユーザーです。このGitLabグループにリンクされているLDAPグループが複数ある場合は、LDAPグループごとに1つずつ、このようなログエントリが複数表示されます。このログエントリにLDAPユーザーDNが表示されない場合、LDAPは検索時にユーザーを返していません。ユーザーが実際にLDAPグループにいることを確認します。

```shell
Members in 'ldap_group_1' LDAP group: ["uid=john0,ou=people,dc=example,dc=com",
"uid=mary0,ou=people,dc=example,dc=com", "uid=john1,ou=people,dc=example,dc=com",
"uid=mary1,ou=people,dc=example,dc=com", "uid=john2,ou=people,dc=example,dc=com",
"uid=mary2,ou=people,dc=example,dc=com", "uid=john3,ou=people,dc=example,dc=com",
"uid=mary3,ou=people,dc=example,dc=com", "uid=john4,ou=people,dc=example,dc=com",
"uid=mary4,ou=people,dc=example,dc=com"]
```

各エントリの直後には、解決されたメンバーアクセスレベルのハッシュが表示されます。このハッシュは、GitLabがこのグループへのアクセスレベル（ロール）を持つ必要があると考えるすべてのユーザーDNを表しています。このハッシュは加算的であり、追加のLDAPグループの検索に基づいて、より多くのDNが追加されたり、既存のエントリが変更されたりする可能性があります。このエントリの最後のオカレンスは、GitLabがグループに追加する必要があると考えるユーザーを正確に示すはずです。

{{< alert type="note" >}}

10は`Guest`、20は`Reporter`、30は`Developer`、40は`Maintainer`、50は`Owner`です。

{{< /alert >}}

```shell
Resolved 'my_group' group member access: {"uid=john0,ou=people,dc=example,dc=com"=>30,
"uid=mary0,ou=people,dc=example,dc=com"=>30, "uid=john1,ou=people,dc=example,dc=com"=>30,
"uid=mary1,ou=people,dc=example,dc=com"=>30, "uid=john2,ou=people,dc=example,dc=com"=>30,
"uid=mary2,ou=people,dc=example,dc=com"=>30, "uid=john3,ou=people,dc=example,dc=com"=>30,
"uid=mary3,ou=people,dc=example,dc=com"=>30, "uid=john4,ou=people,dc=example,dc=com"=>30,
"uid=mary4,ou=people,dc=example,dc=com"=>30}
```

次のような警告が表示されるのは珍しいことではありません。これらは、GitLabがユーザーをグループに追加したはずですが、GitLabでユーザーが見つからなかったことを示しています。通常、これは心配の原因ではありません。

特定のユーザーがすでにGitLabに存在しているはずだが、このエントリが表示されている場合は、GitLabに保存されているDNが一致しないことが原因である可能性があります。ユーザーのLDAPアイデンティティを更新するには、[ユーザーDNとメールアドレスが変更された](#user-dn-and-email-have-changed)を参照してください。

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

すべての設定済みグループリンクが同期されると、GitLabは管理者または外部ユーザーを検索して同期します:

```shell
Syncing admin users for 'ldapmain' provider
```

出力は、単一のグループで発生することと同様に見え、次の行は同期が完了したことを示しています:

```shell
Finished syncing admin users for 'ldapmain' provider
```

[管理者同期](ldap_synchronization.md#administrator-sync)が設定されていない場合は、そのようなメッセージが表示されます:

```shell
No `admin_group` configured for 'ldapmain' provider. Skipping
```

#### 1つのグループを同期 {#sync-one-group}

[すべてのグループを同期する](#sync-all-groups)と、出力に多くのノイズが発生する可能性があり、単一のGitLabグループのグループメンバーシップのトラブルシューティングにのみ関心がある場合は、気が散ることがあります。その場合は、このグループを同期して、デバッグ出力を表示する方法を次に示します:

```ruby
Rails.logger.level = Logger::DEBUG

# Find the GitLab group.
# If the output is `nil`, the group could not be found.
# If a bunch of group attributes are in the output, your group was found successfully.
group = Group.find_by(name: 'my_gitlab_group')

# Sync this group against LDAP
EE::Gitlab::Auth::Ldap::Sync::Group.execute_all_providers(group)
```

出力は、[すべてのグループを同期することから得られるもの](#example-console-output-after-a-group-sync)と似ています。

#### LDAPでグループをクエリする {#query-a-group-in-ldap}

GitLabがLDAPグループを読み取り、そのすべてのメンバーを表示できることを確認する場合は、次を実行できます:

```ruby
# Find the adapter and the group itself
adapter = Gitlab::Auth::Ldap::Adapter.new('ldapmain') # If `main` is the LDAP provider
ldap_group = EE::Gitlab::Auth::Ldap::Group.find_by_cn('group_cn_here', adapter)

# Find the members of the LDAP group
ldap_group.member_dns
ldap_group.member_uids
```

#### LDAPの同期はグループからグループ作成者を削除しません {#ldap-synchronization-does-not-remove-group-creator-from-group}

[LDAP同期](ldap_synchronization.md)は、そのユーザーがグループに存在しない場合、そのグループからLDAPグループの作成者を削除する必要があります。LDAPの同期を実行してもこれが実行されない場合:

1. LDAPグループにユーザーを追加します。
1. LDAPグループの同期が完了するまで待ちます。
1. LDAPグループからユーザーを削除します。

### ユーザーDNとメールアドレスが変更されました {#user-dn-and-email-have-changed}

LDAPでプライマリメール**と**DNの両方が変更された場合、GitLabはユーザーの正しいLDAPレコードを識別できません。その結果、GitLabはそのユーザーをブロックします。GitLabがLDAPレコードを見つけられるようにするには、少なくとも次のいずれかで、ユーザーの既存のGitLabプロファイルを更新します:

- 新しいプライマリメール。
- DN値。

次のスクリプトは、提供されたすべてのユーザーのメールを更新して、ブロックされたり、アカウントにアクセスできなくなったりしないようにします。

{{< alert type="note" >}}

次のスクリプトでは、新しいメールアドレスを持つ新しいアカウントを最初に削除する必要があります。メールアドレスは、GitLabで一意である必要があります。

{{< /alert >}}

[Railsコンソール](#rails-console)に移動して、次を実行します:

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

次に、[ユーザー同期](#sync-all-users)を実行して、これらの各ユーザーの最新のDNを同期できます。

## 「無効な許可」が原因でAzureActivedirectoryV2から認証できませんでした {#could-not-authenticate-from-azureactivedirectoryv2-because-invalid-grant}

LDAPからSAMLに変換するときに、Azureで次のエラーが発生する可能性があります:

```plaintext
Authentication failure! invalid_credentials: OAuth2::Error, invalid_grant.
```

この問題は、次の両方が当てはまる場合に発生します:

- SAMLがこれらのユーザーに設定された後も、LDAPIDがユーザーに存在します。
- これらのユーザーのLDAPを無効にします。

ログにLDAPとAzureの両方のメタデータが表示され、Azureでエラーが生成されます。

単一ユーザーの回避策は、**管理者** > **識別子**でユーザーからLDAPアイデンティティを削除することです。

複数のLDAPアイデンティティを削除するには、[`Could not authenticate you from Ldapmain because "Unknown provider"`エラー](#could-not-authenticate-you-from-ldapmain-because-unknown-provider)のいずれかの回避策を使用します。

## `Could not authenticate you from Ldapmain because "Unknown provider"` {#could-not-authenticate-you-from-ldapmain-because-unknown-provider}

LDAPサーバーで認証するときに、次のエラーが発生する可能性があります:

```plaintext
Could not authenticate you from Ldapmain because "Unknown provider (ldapsecondary). available providers: ["ldapmain"]".
```

このエラーは、GitLab設定から名前が変更または削除されたLDAPサーバーで以前に認証されたアカウントを使用すると発生します。次に例を示します: 

- 最初は、`main`と`secondary`がGitLab設定の`ldap_servers`に設定されます。
- `secondary`設定が削除されるか、`main`に名前が変更されます。
- サインインしようとしているユーザーは、`identify`の`secondary`レコードを持っていますが、これは設定されていません。

[Railsコンソール](../../operations/rails_console.md)を使用して、影響を受けるユーザーをリストし、IDを持つLDAPサーバーを確認します:

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

### LDAPサーバーへの参照の名前を変更します {#rename-references-to-the-ldap-server}

このソリューションは、LDAPサーバーが互いのレプリカであり、影響を受けるユーザーが設定済みのLDAPサーバーを使用してサインインできる必要がある場合に適しています。たとえば、ロードバランサーがHAを管理するために使用されるようになり、個別のセカンダリサインインオプションが不要になった場合などです。

{{< alert type="note" >}}

LDAPサーバーが互いのレプリカでない場合、このソリューションは、影響を受けるユーザーがサインインできなくなるのを防ぎます。

{{< /alert >}}

不再設定されている[LDAPサーバーへの参照の名前を変更する](../../raketasks/ldap.md#other-options)には、次を実行します:

```shell
sudo gitlab-rake gitlab:ldap:rename_provider[ldapsecondary,ldapmain]
```

### 削除されたLDAPサーバーに関連する`identity`レコードを削除します {#remove-the-identity-records-that-relate-to-the-removed-ldap-server}

前提要件: 

- `auto_link_ldap_user`が有効になっていることを確認します。

このソリューションでは、IDが削除された後、影響を受けるユーザーは設定されたLDAPサーバーでサインインでき、新しい`identity`レコードがGitLabによって作成されます。

削除されたLDAPサーバーが`ldapsecondary`であったため、[Railsコンソール](../../operations/rails_console.md)ですべての`ldapsecondary`アイデンティティを削除します:

```ruby
ldap_identities = Identity.where(provider: "ldapsecondary")
ldap_identities.each do |identity|
  puts "Destroying identity: #{identity.id} #{identity.provider}: #{identity.extern_uid}"
  identity.destroy!
rescue => e
  puts 'Error generated when destroying identity:\n ' + e.to_s
end; nil
```

## 有効期限が切れたライセンスが複数のLDAPサーバーでエラーを引き起こす {#expired-license-causes-errors-with-multiple-ldap-servers}

[複数のLDAPサーバー](_index.md#use-multiple-ldap-servers)を使用するには、有効なライセンスが必要です。期限切れのライセンスにより、次の問題が発生する可能性があります:

- Webインターフェースでの`502`エラー。
- ログの次のエラー（実際のストラテジ名は、`/etc/gitlab/gitlab.rb`で設定された名前に依存します）:

  ```plaintext
  Could not find a strategy with name `Ldapsecondary'. Please ensure it is required or explicitly set it using the :strategy_class option. (Devise::OmniAuth::StrategyNotFound)
  ```

このエラーを解決するには、Webインターフェースなしで、新しいライセンスをGitLabインスタンスに適用する必要があります:

1. プライマリ以外のすべてのLDAPサーバーのGitLab設定行を削除するか、コメントアウトします。
1. [GitLabを再設定する](../../restart_gitlab.md#reconfigure-a-linux-package-installation)して、一時的に1つのLDAPサーバーのみを使用するようにします。
1. [Railsコンソール](../../license_file.md#add-a-license-through-the-console)に入り、ライセンスキーを追加します。
1. GitLab設定で追加のLDAPサーバーを再度有効にし、GitLabを再度再設定します。

## ユーザーがグループから削除され、再度追加されています {#users-are-being-removed-from-group-and-re-added-again}

ユーザーがグループ同期中にグループに追加され、次回の同期で削除され、これが繰り返し発生している場合は、ユーザーに複数のLDAPIDまたは冗長なLDAPIDがないことを確認してください。

それらのIDの1つが、使用されなくなった古いLDAPプロバイダーに追加されたものである場合は、[削除されたLDAPサーバーに関連する`identity`レコードを削除](#remove-the-identity-records-that-relate-to-the-removed-ldap-server)します。

## デバッグツール {#debugging-tools}

### LDAPチェック {#ldap-check}

[LDAPをチェックするためのRakeタスク](../../raketasks/ldap.md#check)は、GitLabがLDAPへの接続を正常に確立し、ユーザーを読み取ることができるかどうかを判断するのに役立つ貴重なツールです。

接続を確立できない場合は、設定の問題または接続をブロックするファイアウォールが原因である可能性があります。

- ファイアウォールが接続をブロックしておらず、LDAPサーバーがGitLabホストにアクセスできることを確認してください。
- Rakeタスクチェック出力のエラーメッセージを探します。これにより、LDAP設定（具体的には`host`、`port`、`bind_dn`、および`password`）が正しいことを確認できます。
- [ログ](#gitlab-logs)で[エラー](#connection)を探して、接続障害をさらにデバッグします。

GitLabがLDAPに正常に接続できるが、ユーザーが返されない場合は、[ユーザーが見つからない場合の対処方法](#no-users-are-found)を参照してください。

### GitLabログ {#gitlab-logs}

LDAP設定が原因でユーザーアカウントがブロックまたはブロック解除された場合、メッセージは[`application_json.log`に記録されます](../../logs/_index.md#application_jsonlog)。

LDAPの検索中に予期しないエラー（設定エラー、タイムアウト）が発生した場合、サインインは拒否され、メッセージは[`production.log`に記録されます](../../logs/_index.md#productionlog)。

### ldapsearch {#ldapsearch}

`ldapsearch`は、LDAPサーバーをクエリできるユーティリティです。これを使用して、LDAP設定をテストし、使用している設定で期待される結果が得られることを確認できます。

`ldapsearch`を使用する場合は、`gitlab.rb`設定で既に指定されているものと同じ設定を使用してください。これにより、これらの正確な設定が使用された場合に何が起こるかを確認できます。

このコマンドをGitLabホストで実行すると、GitLabホストとLDAPの間に障害がないことを確認するのにも役立ちます。

たとえば、次のGitLab設定を考えてみましょう:

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

次の`ldapsearch`を実行して、`bind_dn`ユーザーを見つけます:

```shell
ldapsearch -D "cn=admin,dc=ldap-testing,dc=example,dc=com" \
  -w Password1 \
  -p 389 \
  -h 127.0.0.1 \
  -b "dc=ldap-testing,dc=example,dc=com"
```

`bind_dn`、`password`、`port`、`host`、および`base`はすべて、`gitlab.rb`で設定されているものと同一です。

#### `start_tls`暗号化でldapsearchを使用する {#use-ldapsearch-with-start_tls-encryption}

前の例では、平文でポート389へのLDAPテストを実行します。[`start_tls`暗号化](_index.md#basic-configuration-settings)を使用している場合は、`ldapsearch`コマンドに以下を含めます:

- `-Z`フラグ。
- LDAPサーバーのFQDN。

TLSネゴシエーション中に、LDAPサーバーのFQDNが証明書に対して評価されるため、これらを含める必要があります:

```shell
ldapsearch -D "cn=admin,dc=ldap-testing,dc=example,dc=com" \
  -w Password1 \
  -p 389 \
  -h "testing.ldap.com" \
  -b "dc=ldap-testing,dc=example,dc=com" -Z
```

#### `simple_tls`暗号化でldapsearchを使用する {#use-ldapsearch-with-simple_tls-encryption}

[`simple_tls`暗号化](_index.md#basic-configuration-settings)を使用している場合（通常ポート636）は、`ldapsearch`コマンドに以下を含めます:

- `-H`フラグとポートを使用したLDAPサーバーのFQDN。
- 完全に構築されたURI。

```shell
ldapsearch -D "cn=admin,dc=ldap-testing,dc=example,dc=com" \
  -w Password1 \
  -H "ldaps://testing.ldap.com:636" \
  -b "dc=ldap-testing,dc=example,dc=com"
```

詳しくは、[公式`ldapsearch`ドキュメント](https://linux.die.net/man/1/ldapsearch)をご覧ください。

### **AdFind**（AdFind）（Windows）を使用する {#using-adfind-windows}

Windowsベースのシステムで[`AdFind`](https://learn.microsoft.com/en-us/archive/technet-wiki/7535.adfind-command-examples)ユーティリティを使用して、LDAPサーバーにアクセス可能であり、認証が正しく機能していることをテストできます。AdFindは、[Joe Richards](https://www.joeware.net/freetools/tools/adfind/index.htm)によって構築されたフリーウェアユーティリティです。

**Return all objects**（すべてのオブジェクトを返す）

フィルター`objectclass=*`を使用して、すべてのディレクトリオブジェクトを返すことができます。

```shell
adfind -h ad.example.org:636 -ssl -u "CN=GitLabSRV,CN=Users,DC=GitLab,DC=org" -up Password1 -b "OU=GitLab INT,DC=GitLab,DC=org" -f (objectClass=*)
```

**Return single object using filter**（フィルターを使用した単一オブジェクトの返却）

オブジェクト名または完全な**DN**（DN）を**specifying**（指定）して、単一のオブジェクトを取得することもできます。この例では、オブジェクト名`CN=Leroy Fox`のみを指定します。

```shell
adfind -h ad.example.org:636 -ssl -u "CN=GitLabSRV,CN=Users,DC=GitLab,DC=org" -up Password1 -b "OU=GitLab INT,DC=GitLab,DC=org" -f "(&(objectcategory=person)(CN=Leroy Fox))"
```

### Railsコンソール {#rails-console}

{{< alert type="warning" >}}

Railsコンソールを使用すると、データの作成、読み取り、変更、および削除が非常に簡単に行えます。リストされているとおりにコマンドを実行してください。

{{< /alert >}}

Railsコンソールは、LDAPの問題をデバッグするのに役立つ貴重なツールです。コマンドを実行し、GitLabがどのように応答するかを確認することで、アプリケーションを直接操作できます。

Railsコンソールの使用方法については、この[ガイド](../../operations/rails_console.md#starting-a-rails-console-session)を参照してください。

#### デバッグ出力を有効にする {#enable-debug-output}

これにより、GitLabが何をしているのか、何を使用しているのかを示すデバッグ出力が提供されます。この値は永続化されず、Railsコンソールのこのセッションでのみ有効になります。

Railsコンソールでデバッグ出力を有効にするには、[Railsコンソールに入り](#rails-console)、次を実行します:

```ruby
Rails.logger.level = Logger::DEBUG
```

#### グループ、サブグループ、メンバー、およびリクエスタに関連付けられたすべてのエラーメッセージを取得する {#get-all-error-messages-associated-with-groups-subgroups-members-and-requesters}

グループ、サブグループ、メンバー、およびリクエスタに関連付けられたエラーメッセージを収集します。これにより、Webインターフェースに表示されない可能性のあるエラーメッセージがキャプチャされます。これは、[LDAPグループ同期](ldap_synchronization.md#group-sync)、およびグループとサブグループ内のユーザーとそのメンバーシップに関する予期しない動作のトラブルシューティングに特に役立ちます。

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
