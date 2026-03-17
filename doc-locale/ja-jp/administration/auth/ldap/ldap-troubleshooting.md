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

管理者の場合、以下の情報を使用してLDAPのトラブルシューティングを行ってください。

## 一般的な問題とワークフロー {#common-problems--workflows}

### 接続 {#connection}

#### 接続拒否 {#connection-refused}

LDAPサーバーへの接続を試行した際に`Connection Refused`エラーメッセージが表示される場合は、GitLabで使用されているLDAPの`port`と`encryption`の設定を確認してください。一般的な組み合わせは、`encryption: 'plain'`と`port: 389`、または`encryption: 'simple_tls'`と`port: 636`です。

#### 接続タイムアウト {#connection-times-out}

GitLabがLDAPのエンドポイントに到達できない場合、次のようなメッセージが表示されます:

```plaintext
Could not authenticate you from Ldapmain because "Connection timed out - user specified timeout".
```

設定されたLDAPプロバイダーやエンドポイントがオフラインであるか、またはGitLabから到達できない場合、どのLDAPユーザーも認証してサインインすることはできません。GitLabは、LDAPユーザーの認証情報をキャッシュまたは保存して、LDAPの停止中の認証を提供することはありません。

このエラーが表示される場合は、LDAPプロバイダーまたは管理者に連絡してください。

#### 参照エラー {#referral-error}

ログに`LDAP search error: Referral`が表示される場合、またはLDAPグループ同期のトラブルシューティング時に、このエラーは設定の問題を示している可能性があります。LDAPの設定ファイル`/etc/gitlab/gitlab.rb`（Omnibus）または`config/gitlab.yml`（ソース）はYAML形式であり、インデントに注意が必要です。`group_base`と`admin_group`の設定キーが、サーバー識別子より2スペースインデントされた位置にあることを確認してください。デフォルトの識別子は`main`であり、スニペットの例は次のようになります:

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

以下を使用すると、Railsコンソールを使用してLDAP内で検索を実行できます。何をしようとしているかに応じて、[ユーザー](#query-a-user-in-ldap)または[グループ](#query-a-group-in-ldap)を直接クエリする、あるいは[`ldapsearch`](#ldapsearch)を使用する方が理にかなっている場合があります。

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

これがどのように実行されるかの例については、[`Adapter`モジュールを確認してください](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ee/gitlab/auth/ldap/adapter.rb)。

### ユーザーサインイン {#user-sign-ins}

#### ユーザーが見つかりません {#no-users-are-found}

LDAPへの接続が確立できることを[確認した](#ldap-check)にもかかわらず、GitLabの出力にLDAPユーザーが表示されない場合、次のいずれかの可能性が高いです:

- `bind_dn`ユーザーには、ユーザーツリーを走査するのに十分な権限がありません。
- ユーザーは[設定された`base`](_index.md#configure-ldap)に含まれていません。
- 設定された[`user_filter`](_index.md#set-up-ldap-user-filter)がユーザーへのアクセスをブロックしています。

この場合、[ldapsearch](#ldapsearch)と`/etc/gitlab/gitlab.rb`内の既存のLDAP設定を使用して、上記でどれが該当するかを確認できます。

#### ユーザーがサインインできません {#users-cannot-sign-in}

ユーザーがサインインできない理由はいくつかあります。まず、以下の質問を自問してみてください:

- ユーザーはLDAPの[設定された`base`](_index.md#configure-ldap)に含まれていますか？ユーザーがサインインするには、この`base`に含まれている必要があります。
- ユーザーは[設定された`user_filter`](_index.md#set-up-ldap-user-filter)を通過しますか？設定されたていない場合、この質問は無視できます。設定されたいる場合は、ユーザーがサインインを許可されるために、このフィルターも通過する必要があります。
  - [`user_filter`](#debug-ldap-user-filter)のデバッグに関するドキュメントを参照してください。

上記の質問がどちらも問題ない場合、次に問題を調査する場所は、問題を再現しながらログ自体を確認することです。

- ユーザーにサインインを促し、失敗させてください。
- サインインに関するエラーやその他のメッセージがないか、[出力を確認してください](#gitlab-logs)。このページに記載されている他のエラーメッセージが表示される場合があります。その場合は、そのセクションが問題の解決に役立ちます。

ログが問題の根本原因を示さない場合、[Railsコンソール](#rails-console)を使用して[このユーザーをクエリ](#query-a-user-in-ldap)し、GitLabがLDAPサーバー上のこのユーザーを読み取りできるかどうかを確認します。

さらに調査するために、ユーザー同期の[デバッグ](#sync-all-users)も役立ちます。

#### ユーザーに`Invalid login or password.`エラーが表示される {#users-see-an-error-invalid-login-or-password}

{{< history >}}

- GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/438144)されました。

{{< /history >}}

ユーザーがこのエラーを確認した場合、**標準**サインインフォームではなく、**LDAP**サインインフォームを使用してサインインしようとしている可能性があります。

解決するには、ユーザーに**LDAP**サインインフォームにLDAPのユーザー名とパスワードを入力するよう依頼してください。

#### サインイン時の無効な認証情報 {#invalid-credentials-on-sign-in}

LDAPで使われているサインイン認証情報が正確である場合、対象のユーザーについて以下のことが当てはまることを確認してください:

- バインドしているユーザーが、ユーザーのツリーを読み取り、走査するのに十分な権限を持っていることを確認してください。
- `user_filter`が正当なユーザーをブロックしていないことを確認してください。
- [LDAPチェックコマンド](#ldap-check)を実行して、LDAPの設定が正しいこと、および[GitLabがユーザーを認識できる](#no-users-are-found)ことを確認してください。

#### あなたのLDAPアカウントのアクセスが拒否されました {#access-denied-for-your-ldap-account}

[監査担当者アクセスレベル](../../auditor_users.md)のユーザーに影響を与える可能性のある[バグ](https://gitlab.com/gitlab-org/gitlab/-/issues/235930)があります。Premium/Ultimateからダウングレードする際、監査担当者ユーザーがサインインしようとすると、`Access denied for your LDAP account`というメッセージが表示される場合があります。

回避策は、影響を受けるユーザーのアクセスレベルを変更することです。

前提条件: 

- 管理者アクセス権が必要です。

1. 右上隅で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 影響を受けるユーザーの名前を選択します。
1. 右上隅で、**編集**を選択します。
1. ユーザーのアクセスレベルを`Regular`から`Administrator`に変更します（またはその逆）。
1. ページの下部で、**変更を保存**を選択します。
1. 右上隅で、もう一度**編集**を選択します。
1. ユーザーの元のアクセスレベル（`Regular`または`Administrator`）を復元し、もう一度**変更を保存**を選択します。

ユーザーはサインインできるようになります。

#### メールはすでに使用されています {#email-has-already-been-taken}

ユーザーが正しいLDAP認証情報でサインインしようとすると、アクセスが拒否され、[production.log](../../logs/_index.md#productionlog)に次のようなエラーが表示されます:

```plaintext
(LDAP) Error saving user <USER DN> (email@example.com): ["Email has already been taken"]
```

このエラーは、LDAP内のメールアドレス`email@example.com`を参照しています。メールアドレスはGitLab内で一意である必要があり、LDAPはユーザーのプライマリメール（多数のセカンダリメールのいずれかではなく）にリンクされます。別のユーザー（または同じユーザー）がメール`email@example.com`をセカンダリメールとして設定しており、このエラーが発生しています。

[Railsコンソール](#rails-console)を使用して、この競合するメールアドレスがどこから来ているかを確認できます。コンソールで、以下を実行します:

```ruby
# This searches for an email among the primary AND secondary emails
user = User.find_by_any_email('email@example.com')
user.username
```

これにより、どのユーザーがこのメールアドレスを持っているかが表示されます。ここでは、2つのステップのいずれかを実行する必要があります:

- LDAPでサインインする際に、このユーザーのために新しいGitLabユーザー/ユーザー名を作成するには、競合を削除するためにセカンダリメールを削除します。
- LDAPで使用するために、このユーザーに既存のGitLabユーザー/ユーザー名を使用するには、このメールをセカンダリメールから削除し、プライマリメールにすることで、GitLabがこのプロファイルをLDAP識別子に関連付けます。

ユーザーは[自分のプロファイルで](../../../user/profile/_index.md#access-your-user-profile)これらのステップのいずれかを実行できます。または管理者が実行することもできます。

#### プロジェクト制限エラー {#projects-limit-errors}

以下のエラーは、制限または制約がアクティブ化されているものの、関連するデータフィールドにデータが含まれていないことを示しています:

- `Projects limit can't be blank`。
- `Projects limit is not a number`。

これを解決するには、次の手順に従います:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. 以下の両方を展開します:
   - **アカウントと制限**。
   - **新規登録の制限**。
1. 例えば、**デフォルトのプロジェクトの制限**または**サインアップに許可されたドメイン**のフィールドを確認し、関連する値が設定されたていることを確認してください。

#### LDAPユーザーフィルターのデバッグ {#debug-ldap-user-filter}

[`ldapsearch`](#ldapsearch)を使用すると、設定された済みの[ユーザーフィルター](_index.md#set-up-ldap-user-filter)をテストし、期待どおりのユーザーが返されることを確認できます。

```shell
ldapsearch -H ldaps://$host:$port -D "$bind_dn" -y bind_dn_password.txt  -b "$base" "$user_filter" sAMAccountName
```

- `$`で始まる変数は、LDAPセクションの設定ファイルからの変数を参照します。
- プレーン認証方法を使用している場合は、`ldaps://`を`ldap://`に置き換えてください。ポート`389`は`ldap://`のデフォルトポートであり、`636`は`ldaps://`のデフォルトポートです。
- `bind_dn`ユーザーのパスワードは`bind_dn_password.txt`にあると仮定しています。

#### すべてのユーザーを同期 {#sync-all-users}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

手動の[ユーザー同期](ldap_synchronization.md#user-sync)からの出力は、GitLabがユーザーをLDAPに対して同期しようとするときに何が起こるかを示します。[Railsコンソール](#rails-console)に入力し、以下を実行します:

```ruby
Rails.logger.level = Logger::DEBUG

LdapSyncWorker.new.perform
```

次に、[出力の読み方を学びます](#example-console-output-after-a-user-sync)。

##### ユーザー同期後のコンソール出力例 {#example-console-output-after-a-user-sync}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

[手動ユーザー同期](#sync-all-users)からの出力は非常に詳細であり、単一ユーザーの正常な同期は次のようになります:

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

まず、GitLabは以前にLDAPでサインインしたすべてのユーザーを検索し、それらにイテレーションを行います。各ユーザーの同期は、現在GitLabに存在するユーザーのユーザー名とメールを含む以下の行から始まります:

```shell
Syncing user John, email@example.com
```

特定のユーザーのGitLabメールが出力に見つからない場合、そのユーザーはまだLDAPでサインインしていません。

次に、GitLabは`identities`テーブルで、このユーザーと設定されたLDAPプロバイダー間の既存のリンクを検索します:

```sql
  Identity Load (0.9ms)  SELECT  "identities".* FROM "identities" WHERE "identities"."user_id" = 20 AND (provider LIKE 'ldap%') LIMIT 1
```

この識別子オブジェクトには、GitLabがLDAPでユーザーを検索するために使用するDNが含まれています。DNが見つからない場合は、代わりにメールが使用されます。このユーザーがLDAPで見つかったことがわかります:

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

LDAPでユーザーが見つかった後、残りの出力によってGitLabデータベースが変更で更新されます。

#### LDAPでユーザーをクエリする {#query-a-user-in-ldap}

これは、GitLabがLDAPに到達して特定のユーザーを読み取りできることをテストします。これは、GitLabUIでサイレントに失敗しているように見える可能性のある、LDAPへの接続やLDAPのクエリに関する潜在的なエラーを明らかにすることができます。

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

#### メンバーシップが付与されていません {#memberships-not-granted}

特定のユーザーがLDAPグループ同期を通じてGitLabグループに追加されるべきだと考えるかもしれませんが、何らかの理由でそれが起こらないことがあります。状況をデバッグするためにいくつか確認できることがあります。

- LDAP設定に`group_base`が指定されていることを確認してください。[この設定](ldap_synchronization.md#group-sync)は、グループ同期が適切に機能するために必要です。
- 正しい[LDAPグループリンクがGitLabグループに追加されている](ldap_synchronization.md#add-group-links)ことを確認してください。
- ユーザーにLDAP識別子があることを確認してください:
  1. GitLabに管理者ユーザーとしてサインインします。
  1. 右上隅で、**管理者**を選択します。
  1. 左側のサイドバーで、**概要** > **ユーザー**を選択します。
  1. ユーザーを検索します。
  1. ユーザーの名前を選択して開きます。**編集**を選択しないでください。
  1. **識別子**タブを選択します。`Identifier`としてLDAP DNを持つLDAP識別子が存在するはずです。存在しない場合、このユーザーはまだLDAPでサインインしていないため、まずサインインする必要があります。
- グループが同期されるまで1時間、または[設定された間隔](ldap_synchronization.md#adjust-ldap-sync-schedule)を待ちました。プロセスを高速化するには、GitLabグループの**管理** > **メンバー**に移動して**Sync now**を押すか、[グループ同期Rakeタスクを実行](../../raketasks/ldap.md#run-a-group-sync)（すべてのグループを同期）します。

すべてのチェックが良好に見える場合は、Railsコンソールでより高度なデバッグに進みます。

1. [Railsコンソール](#rails-console)に入力します。
1. テストするGitLabグループを選択します。このグループには、すでにLDAPグループリンクが設定されたてある必要があります。
1. デバッグログを有効にし、選択したGitLabグループを見つけて、[LDAPと同期します](#sync-one-group)。
1. 同期の出力を確認してください。出力の読み方については、[ログ出力例](#example-console-output-after-a-group-sync)を参照してください。
1. ユーザーが追加されない理由がまだわからない場合は、[LDAPグループを直接クエリ](#query-a-group-in-ldap)して、メンバーがどのようにリストされているかを確認してください。
1. ユーザーのDNまたはUIDは、クエリされたグループのリストのいずれかにありますか？ここにあるDNまたはUIDのいずれかは、以前にチェックしたLDAP識別子からの'Identifier'と一致する必要があります。一致しない場合、ユーザーはLDAPグループに存在しないようです。

#### LDAP同期が有効になっている場合、サービスアカウントユーザーをグループに追加できません {#cannot-add-service-account-user-to-group-when-ldap-sync-is-enabled}

グループに対してLDAP同期が有効になっている場合、「招待」ダイアログを使用して新しいグループメンバーを招待することはできません。

GitLab 16.8以降でこの問題を解決するには、[グループメンバーAPIエンドポイント](../../../api/group_members.md#add-a-group-member)を使用して、サービスアカウントをグループに招待したり、グループから削除したりすることができます。

#### 管理者権限が付与されていません {#administrator-privileges-not-granted}

[管理者同期](ldap_synchronization.md#administrator-sync)が設定されたにもかかわらず、設定されたユーザーに正しい管理者権限が付与されていない場合、以下の条件が真であることを確認してください:

- また、[`group_base`が設定されたている](ldap_synchronization.md#group-sync)こと。
- `gitlab.rb`内の設定された`admin_group`が、DNや配列ではなくCNであること。
- このCNが、設定された`group_base`のスコープ内にあること。
- `admin_group`のメンバーが、すでにLDAP認証情報でGitLabにサインインしていること。GitLabは、アカウントがすでにLDAPに接続されているユーザーにのみ管理者アクセスを許可します。

上記の条件がすべて真であり、ユーザーがまだアクセスを取得できない場合、Railsコンソールで[手動グループ同期を実行](#sync-all-groups)し、GitLabが`admin_group`を同期するときに何が起こるかを確認するために[出力を確認](#example-console-output-after-a-group-sync)してください。

#### UIで今すぐ同期ボタンがスタックする {#sync-now-button-stuck-in-the-ui}

グループの**グループ** > **メンバー**ページにある**Sync now**ボタンがスタックすることがあります。ボタンが押されてページがリロードされると、ボタンがスタックします。その後、ボタンを再度選択できなくなります。

**Sync now**ボタンがスタックする理由はたくさんあり、特定のケースではデバッグが必要です。以下は、問題の2つの考えられる原因と、考えられる解決策です。

##### 無効なメンバーシップ {#invalid-memberships}

グループのメンバーまたはリクエスタの一部が無効である場合、**Sync now**ボタンがスタックします。この問題の表示レベルを改善するための進捗状況は、[関連するイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/348226)で追跡できます。[Railsコンソール](#rails-console)を使用して、この問題が**Sync now**ボタンのスタックを引き起こしているかどうかを確認できます:

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

表示されたエラーは、問題を特定し、解決策を示すことができます。例えば、サポートチームは以下のエラーを確認しています:

```ruby
irb(main):018:0> group.members.map(&:errors).map(&:full_messages)
=> [["The member's email address is not allowed for this group. Go to the group's 'Settings > General' page, and check 'Restrict membership by email domain'."]]
```

このエラーは、管理者が[メールドメインによるグループメンバーシップを制限](../../../user/group/access_and_permissions.md#restrict-group-access-by-domain)することを選択したが、ドメインにタイプミスがあったことを示しています。ドメイン設定が修正された後、**Sync now**ボタンは再び機能しました。

##### Sidekiqノード上の不足しているLDAP設定 {#missing-ldap-configuration-on-sidekiq-nodes}

GitLabが複数のノードにスケールされ、Sidekiqを実行しているノード上の[`/etc/gitlab/gitlab.rb`からLDAP設定が不足している](../../sidekiq/_index.md#configure-ldap-and-user-or-group-synchronization)場合、**Sync now**ボタンがスタックします。この場合、Sidekiqジョブが消えてしまうようです。

SidekiqノードにはLDAPが必要です。LDAPには、ローカルLDAP設定を必要とする、非同期で実行される複数のジョブがあるためです:

- [ユーザー同期](ldap_synchronization.md#user-sync)。
- [グループ同期](ldap_synchronization.md#group-sync)。

[LDAPをチェックするRakeタスクを実行](#ldap-check)することで、LDAP設定の欠落が問題であるかどうかを、Sidekiqを実行している各ノードでテストできます。このノードでLDAPが正しく設定されたている場合、LDAPサーバーに接続し、ユーザーを返します。

この問題を解決するには、Sidekiqノードで[LDAPを設定](../../sidekiq/_index.md#configure-ldap-and-user-or-group-synchronization)します。設定されたら、[LDAPをチェックするRakeタスクを実行](#ldap-check)して、GitLabノードがLDAPに接続できることを確認します。

#### すべてのグループを同期 {#sync-all-groups}

> [!note]
> デバッグが不要な場合にすべてのグループを手動で同期するには、代わりに[Rakeタスクを使用してください](../../raketasks/ldap.md#run-a-group-sync)。

手動の[グループ同期](ldap_synchronization.md#group-sync)からの出力は、GitLabがLDAPグループグループメンバーシップをLDAPに対して同期するときに何が起こるかを示します。[Railsコンソール](#rails-console)に入力し、以下を実行します:

```ruby
Rails.logger.level = Logger::DEBUG

LdapAllGroupsSyncWorker.new.perform
```

次に、[出力の読み方を学びます](#example-console-output-after-a-group-sync)。

##### グループ同期後のコンソール出力例 {#example-console-output-after-a-group-sync}

ユーザー同期からの出力と同様に、[手動グループ同期](#sync-all-groups)からの出力も非常に詳細です。ただし、多くの役立つ情報が含まれています。

同期が実際に始まる地点を示します:

```shell
Started syncing 'ldapmain' provider for 'my_group' group
```

以下のエントリは、GitLabがLDAPサーバーで確認するすべてのユーザーDNの配列を示しています。これらのDNは、単一のLDAPグループのユーザーであり、GitLabグループではありません。このGitLabグループに複数のLDAPグループがリンクされている場合、LDAPグループごとに1つずつ、このような複数のログエントリが表示されます。このログエントリにLDAPユーザーDNが表示されない場合、検索時にLDAPがユーザーを返していません。ユーザーが実際にLDAPグループにいることを確認してください。

```shell
Members in 'ldap_group_1' LDAP group: ["uid=john0,ou=people,dc=example,dc=com",
"uid=mary0,ou=people,dc=example,dc=com", "uid=john1,ou=people,dc=example,dc=com",
"uid=mary1,ou=people,dc=example,dc=com", "uid=john2,ou=people,dc=example,dc=com",
"uid=mary2,ou=people,dc=example,dc=com", "uid=john3,ou=people,dc=example,dc=com",
"uid=mary3,ou=people,dc=example,dc=com", "uid=john4,ou=people,dc=example,dc=com",
"uid=mary4,ou=people,dc=example,dc=com"]
```

各エントリの直後に、解決されたメンバーアクセスレベルのハッシュが表示されます。このハッシュは、GitLabがこのグループへのアクセスを持つべきだと考えるすべてのユーザーDNと、そのアクセスレベル（ロール）を表します。このハッシュは加算式であり、追加のLDAPグループルックアップに基づいて、より多くのDNが追加されたり、既存のエントリが変更されたりする可能性があります。このエントリの最後の出現は、GitLabがグループに追加されるべきだと考えるユーザーを正確に示すはずです。

> [!note]
> 10は`Guest`、20は`Reporter`、30は`Developer`、40は`Maintainer`、50は`Owner`です。

```shell
Resolved 'my_group' group member access: {"uid=john0,ou=people,dc=example,dc=com"=>30,
"uid=mary0,ou=people,dc=example,dc=com"=>30, "uid=john1,ou=people,dc=example,dc=com"=>30,
"uid=mary1,ou=people,dc=example,dc=com"=>30, "uid=john2,ou=people,dc=example,dc=com"=>30,
"uid=mary2,ou=people,dc=example,dc=com"=>30, "uid=john3,ou=people,dc=example,dc=com"=>30,
"uid=mary3,ou=people,dc=example,dc=com"=>30, "uid=john4,ou=people,dc=example,dc=com"=>30,
"uid=mary4,ou=people,dc=example,dc=com"=>30}
```

以下のような警告が表示されることは珍しくありません。これらは、GitLabがユーザーをグループに追加したであろうが、そのユーザーがGitLabに見つからなかったことを示しています。通常、これは懸念の原因ではありません。

特定のユーザーがすでにGitLabに存在すると考えるのに、このエントリが表示される場合、それはGitLabに保存されているDNの不一致が原因である可能性があります。ユーザーのLDAP識別子を更新するには、[ユーザーDNとメールが変更されました](#user-dn-and-email-have-changed)を参照してください。

```shell
User with DN `uid=john0,ou=people,dc=example,dc=com` should have access
to 'my_group' group but there is no user in GitLab with that
identity. Membership will be updated when the user signs in for
the first time.
```

最後に、以下のエントリは、このグループの同期が完了したことを示しています:

```shell
Finished syncing all providers for 'my_group' group
```

すべての設定されたグループリンクが同期されると、GitLabは管理者または外部ユーザーを検索して同期します:

```shell
Syncing admin users for 'ldapmain' provider
```

出力は単一グループの場合と同様に見え、その後、この行が同期の完了を示します:

```shell
Finished syncing admin users for 'ldapmain' provider
```

[管理者同期](ldap_synchronization.md#administrator-sync)が設定されたていない場合、その旨を示すメッセージが表示されます:

```shell
No `admin_group` configured for 'ldapmain' provider. Skipping
```

#### 1つのグループを同期 {#sync-one-group}

[すべてのグループを同期する](#sync-all-groups)と、出力に多くのノイズが発生する可能性があり、単一のGitLabグループのメンバーシップのトラブルシューティングにのみ関心がある場合は、気が散ることがあります。その場合、このグループのみを同期してそのデバッグ出力を表示する方法は次のとおりです:

```ruby
Rails.logger.level = Logger::DEBUG

# Find the GitLab group.
# If the output is `nil`, the group could not be found.
# If a bunch of group attributes are in the output, your group was found successfully.
group = Group.find_by(name: 'my_gitlab_group')

# Sync this group against LDAP
EE::Gitlab::Auth::Ldap::Sync::Group.execute_all_providers(group)
```

出力は、[すべてのグループを同期することで得られるもの](#example-console-output-after-a-group-sync)と似ています。

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
1. LDAPグループ同期の実行が完了するまで待ちます。
1. ユーザーをLDAPグループから削除します。

### ユーザーDNとメールが変更されました {#user-dn-and-email-have-changed}

プライマリメール**と**DNの両方がLDAPで変更された場合、GitLabはユーザーの正しいLDAPレコードを識別子できません。結果として、GitLabはそのユーザーをブロックします。GitLabがLDAPレコードを見つけられるように、ユーザーの既存のGitLabプロファイルを少なくとも以下のいずれかで更新します:

- 新しいプライマリメール。
- DN値。

以下のスクリプトは、提供されたすべてのユーザーのメールを更新し、それらがブロックされたりアカウントにアクセスできなくなったりしないようにします。

> [!note]
> 以下のスクリプトは、新しいメールアドレスを持つ新しいアカウントが最初に削除されることを要求します。メールアドレスはGitLab内で一意である必要があります。

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

その後、[ユーザー同期を実行](#sync-all-users)して、これらの各ユーザーの最新のDNを同期できます。

## AzureActivedirectoryV2から認証できませんでした。`Invalid grant` {#could-not-authenticate-from-azureactivedirectoryv2-because-invalid-grant}

LDAPからSAMLに変換するときに、Azureで次のようなエラーが表示されることがあります:

```plaintext
Authentication failure! invalid_credentials: OAuth2::Error, invalid_grant.
```

このイシューは、以下の両方が真の場合に発生します:

- SAMLがこれらのユーザーに対して設定された後も、LDAP識別子がユーザーのために存在し続ける。
- これらのユーザーに対してLDAPを無効にする。

ログにLDAPとAzureの両方のメタデータが受信され、Azureでエラーが生成されます。

単一ユーザーの回避策は、**管理者** > **識別子**でユーザーからLDAP識別子を削除することです。

複数のLDAP識別子を削除するには、以下の`Could not authenticate you from Ldapmain because "Unknown provider"`エラーに対するいずれかの回避策を使用してください。

## エラー: `Could not authenticate you from Ldapmain because "Unknown provider"` {#error-could-not-authenticate-you-from-ldapmain-because-unknown-provider}

LDAPサーバーで認証する際に、以下のエラーを受け取る可能性があります:

```plaintext
Could not authenticate you from Ldapmain because "Unknown provider (ldapsecondary). available providers: ["ldapmain"]".
```

このエラーは、以前にLDAPサーバーで認証されたアカウントが、GitLabの設定から名前が変更されたか削除された場合に発生します。例: 

- 当初、GitLab設定の`ldap_servers`に`main`と`secondary`が設定されています。
- `secondary`の設定が削除されるか、`main`に名前が変更されます。
- サインインしようとするユーザーは`secondary`の`identify`レコードを持っていますが、それはもはや設定されたていません。

[Railsコンソール](../../operations/rails_console.md)を使用して、影響を受けるユーザーをリストし、彼らがどのLDAPサーバーの識別子を持っているかを確認します:

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

この解決策は、LDAPサーバーが互いのレプリカであり、影響を受けるユーザーが設定されたLDAPサーバーを使用してサインインできるべき場合に適しています。例えば、ロードバランサーがLDAPの高可用性を管理するために使用されており、個別のセカンダリサインインオプションがもはや不要な場合などです。

> [!note] 
> LDAPサーバーが互いのレプリカでない場合、この解決策は影響を受けるユーザーがサインインできないようにします。

もはや設定されたていないLDAPサーバーへの[参照の名前を変更](../../raketasks/ldap.md#other-options)するには、以下を実行します:

```shell
sudo gitlab-rake gitlab:ldap:rename_provider[ldapsecondary,ldapmain]
```

### 削除されたLDAPサーバーに関連する`identity`レコードを削除する {#remove-the-identity-records-that-relate-to-the-removed-ldap-server}

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

## ライセンスの有効期限切れが複数のLDAPサーバーでエラーを引き起こす {#expired-license-causes-errors-with-multiple-ldap-servers}

[複数のLDAPサーバー](_index.md#use-multiple-ldap-servers)を使用するには、有効なライセンスが必要です。有効期限切れのライセンスは、以下の原因となります:

- ウェブインターフェースでの`502`エラー。
- ログ内の以下のエラー（実際の戦略名は`/etc/gitlab/gitlab.rb`で設定された名によって異なります）:

  ```plaintext
  Could not find a strategy with name `Ldapsecondary'. Please ensure it is required or explicitly set it using the :strategy_class option. (Devise::OmniAuth::StrategyNotFound)
  ```

このエラーを解決するには、ウェブインターフェースを使用せずに、新しいライセンスをGitLabインスタンスに適用する必要があります:

1. すべての非プライマリLDAPサーバーのGitLab設定行を削除またはコメントアウトします。
1. 一時的に1つのLDAPサーバーのみを使用するように[GitLabを再設定](../../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
1. [Railsコンソールに入力し、ライセンスキーを追加](../../license_file.md#add-a-license-through-the-console)します。
1. GitLab設定で追加のLDAPサーバーを再有効化し、GitLabを再度再設定します。

## ユーザーがグループから削除され、再度追加される {#users-are-being-removed-from-group-and-re-added-again}

グループ同期中にユーザーがグループに追加され、次の同期で削除され、これが繰り返し発生している場合、ユーザーが複数のまたは冗長なLDAP識別子を持っていないことを確認してください。

それらの識別子の1つが、もはや使用されていない古いLDAPプロバイダーのために追加された場合、[削除されたLDAPサーバーに関連する`identity`レコードを削除](#remove-the-identity-records-that-relate-to-the-removed-ldap-server)します。

## デバッグツール {#debugging-tools}

### LDAPチェック {#ldap-check}

[LDAPをチェックするRakeタスク](../../raketasks/ldap.md#check)は、GitLabがLDAPへの接続を正常に確立し、ユーザーを読み取りできるかどうかを判断するのに役立つ貴重なツールです。

接続を確立できない場合、それは設定の問題か、ファイアウォールが接続をブロックしているかのどちらかの可能性が高いです。

- ファイアウォールが接続をブロックしていないこと、およびLDAPサーバーがGitLabホストからアクセス可能であることを確認してください。
- Rakeチェック出力にエラーメッセージがないか確認してください。これにより、LDAP設定に導かれ、設定値（特に`host`、`port`、`bind_dn`、および`password`）が正しいことを確認できます。
- 接続失敗をさらにデバッグするために、[ログ](#connection)内で[エラー](#gitlab-logs)を探してください。

GitLabがLDAPに正常に接続できるものの、ユーザーを返さない場合、[ユーザーが見つからない場合の対処法](#no-users-are-found)を参照してください。

### GitLabログ {#gitlab-logs}

LDAP設定のためにユーザーアカウントがブロックまたはブロック解除された場合、メッセージは[`application_json.log`にログとして記録されます](../../logs/_index.md#application_jsonlog)。

LDAPルックアップ中に予期せぬエラー（設定エラー、タイムアウト）が発生した場合、サインインは拒否され、メッセージは[`production.log`にログとして記録されます](../../logs/_index.md#productionlog)。

### ldapsearch {#ldapsearch}

`ldapsearch`は、LDAPサーバーをクエリできるユーティリティです。これを使用して、LDAPの設定をテストし、使用している設定が期待する結果をもたらすことを確認できます。

`ldapsearch`を使用する際は、`gitlab.rb`の設定ですでに指定したのと同じ設定を使用してください。そうすることで、それらの正確な設定が使用された場合に何が起こるかを確認できます。

GitLabホストでこのコマンドを実行することは、GitLabホストとLDAPの間に障害がないことを確認するのにも役立ちます。

例えば、以下のGitLab設定を検討してください:

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

`bind_dn`ユーザーを見つけるために、以下の`ldapsearch`を実行します:

```shell
ldapsearch -D "cn=admin,dc=ldap-testing,dc=example,dc=com" \
  -w Password1 \
  -p 389 \
  -h 127.0.0.1 \
  -b "dc=ldap-testing,dc=example,dc=com"
```

`bind_dn`、`password`、`port`、`host`、および`base`はすべて、`gitlab.rb`で設定されたものと同一です。

#### ldapsearchを`start_tls`の暗号化で使用する {#use-ldapsearch-with-start_tls-encryption}

前の例では、LDAPテストをプレーンテキストでポート389に実行しています。[`start_tls`の暗号化](_index.md#basic-configuration-settings)を使用している場合、`ldapsearch`コマンドに以下を含めます:

- `-Z`フラグ。
- LDAPサーバーのFQDN。

これらは、TLSネゴシエーション中にLDAPサーバーのFQDNがその証明書に対して評価されるため、含める必要があります:

```shell
ldapsearch -D "cn=admin,dc=ldap-testing,dc=example,dc=com" \
  -w Password1 \
  -p 389 \
  -h "testing.ldap.com" \
  -b "dc=ldap-testing,dc=example,dc=com" -Z
```

#### ldapsearchを`simple_tls`の暗号化で使用する {#use-ldapsearch-with-simple_tls-encryption}

[`simple_tls`の暗号化](_index.md#basic-configuration-settings)（通常はポート636）を使用している場合、`ldapsearch`コマンドに以下を含めます:

- `-H`フラグとポートを指定したLDAPサーバーのFQDN。
- 完全に構築されたURI。

```shell
ldapsearch -D "cn=admin,dc=ldap-testing,dc=example,dc=com" \
  -w Password1 \
  -H "ldaps://testing.ldap.com:636" \
  -b "dc=ldap-testing,dc=example,dc=com"
```

詳細については、[公式の`ldapsearch`ドキュメント](https://linux.die.net/man/1/ldapsearch)を参照してください。

### **AdFind**（Windows）を使用する {#using-adfind-windows}

[`AdFind`](https://learn.microsoft.com/en-us/archive/technet-wiki/7535.adfind-command-examples)ユーティリティ（Windowsベースのシステム上）を使用して、LDAPサーバーがアクセス可能で認証が正しく機能していることをテストできます。AdFindは[Joe Richards](https://www.joeware.net/freetools/tools/adfind/index.htm)によって開発されたフリーウェアユーティリティです。

**Return all objects**

フィルター`objectclass=*`を使用して、すべてのディレクトリオブジェクトを返すことができます。

```shell
adfind -h ad.example.org:636 -ssl -u "CN=GitLabSRV,CN=Users,DC=GitLab,DC=org" -up Password1 -b "OU=GitLab INT,DC=GitLab,DC=org" -f (objectClass=*)
```

**Return single object using filter**

オブジェクト名または完全な**DN**を**specifying**して単一のオブジェクトを取得することもできます。この例では、オブジェクト名のみ`CN=Leroy Fox`を指定します。

```shell
adfind -h ad.example.org:636 -ssl -u "CN=GitLabSRV,CN=Users,DC=GitLab,DC=org" -up Password1 -b "OU=GitLab INT,DC=GitLab,DC=org" -f "(&(objectcategory=person)(CN=Leroy Fox))"
```

### Railsコンソール {#rails-console}

> [!warning] 
> Railsコンソールを使用すると、データの作成、読み取り、変更、および削除が非常に簡単です。コマンドはリストされているとおりに正確に実行してください。

Railsコンソールは、LDAPの問題をデバッグするのに役立つ貴重なツールです。コマンドを実行し、GitLabがそれらにどのように応答するかを確認することで、アプリケーションと直接対話できます。

Railsコンソールの使用方法については、この[ガイド](../../operations/rails_console.md#starting-a-rails-console-session)を参照してください。

#### デバッグ出力を有効にする {#enable-debug-output}

これは、GitLabが何をしていて、何を使用しているかを示すデバッグ出力を提供します。この値は永続化されず、Railsコンソールのこのセッションでのみ有効です。

Railsコンソールでデバッグ出力を有効にするには、[Railsコンソールに入力](#rails-console)し、以下を実行します:

```ruby
Rails.logger.level = Logger::DEBUG
```

#### グループ、サブグループ、メンバー、およびリクエスタに関連付けられたすべてのエラーメッセージを取得する {#get-all-error-messages-associated-with-groups-subgroups-members-and-requesters}

グループ、サブグループ、メンバー、およびリクエスタに関連付けられたエラーメッセージを収集します。これは、Webインターフェースに表示されない可能性のあるエラーメッセージを捕捉します。これは、[LDAPグループ同期](ldap_synchronization.md#group-sync)の問題や、ユーザーとグループおよびサブグループにおけるメンバーシップの予期せぬ動作のトラブルシューティングに特に役立ちます。

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
