---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: no
title: GitLabとLDAPのインテグレーション
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、ユーザー認証をサポートするために[LDAP（Lightweight Directory Access Protocol）](https://en.wikipedia.org/wiki/Lightweight_Directory_Access_Protocol)と連携しています。

このインテグレーションは、以下を含む、ほとんどのLDAP準拠のディレクトリサーバーで動作します。

- Microsoft Active Directory。
- Apple Open Directory。
- OpenLDAP。
- 389 Server。

{{< alert type="note" >}}

GitLabは、[Microsoft Active Directoryの信頼関係](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/cc771568(v=ws.10))をサポートしていません。

{{< /alert >}}

LDAPを通じて追加されたユーザー:

- 通常、[ライセンスされたシート](../../../subscriptions/manage_users_and_seats.md#billable-users)を使用します。
- [Gitのパスワード認証が無効](../../settings/sign_in_restrictions.md#password-authentication-enabled)になっている場合でも、GitLabのユーザー名、またはメールアドレスとLDAPパスワードを使用してGitで認証できます。

LDAP識別名（DN）は、次の場合に既存のGitLabユーザーに関連付けられます。

- 既存のユーザーが初めてLDAPを通じてGitLabにサインインした場合。
- LDAPのメールアドレスが、既存のGitLabユーザーのプライマリーメールアドレスである場合。LDAPのメール属性がGitLabユーザーデータベースに見つからない場合は、新しいユーザーが作成されます。

既存のGitLabユーザーがLDAPサインインを有効にする場合は、次の手順に従います。

1. GitLabのメールアドレスがLDAPのメールアドレスと一致することを確認します。
1. LDAP認証情報を使用してGitLabにサインインします。

## セキュリティ {#security}

GitLabは、ユーザーがLDAPでまだアクティブであるかを確認します。

ユーザーは、次の場合にLDAPで非アクティブと見なされます。

- ディレクトリから完全に削除された。
- 設定された`base` DNまたは`user_filter`の検索範囲外に存在する。
- ユーザーアカウント制御属性を通じて、Active Directoryで無効または非アクティブとしてマークされている。これは、属性`userAccountControl:1.2.840.113556.1.4.803`のビット2が設定されていることを意味します。

ユーザーがLDAPでアクティブか非アクティブかを確認するには、次のPowerShellコマンドと[Active Directoryモジュール](https://learn.microsoft.com/en-us/powershell/module/activedirectory/?view=windowsserver2022-ps)を使用して、Active Directoryを確認します。

```powershell
Get-ADUser -Identity <username> -Properties userAccountControl | Select-Object Name, userAccountControl
```

GitLabは、次のタイミングでLDAPユーザーの状態をチェックします。

- 任意の認証プロバイダーを使用してサインインするとき。
- アクティブなWebセッション、あるいはトークンまたはSSHキーを使用したGitリクエストに対して、1時間に1回。
- LDAPのユーザー名とパスワードを使用してGit over HTTPリクエストを実行するとき。
- [ユーザー同期](ldap_synchronization.md#user-sync)の際に1日1回。

ユーザーは、LDAPでアクティブでなくなった場合に次のようになります。

- サインアウトされる。
- `ldap_blocked`状態に設定される。
- LDAPで再アクティブ化されるまで、どの認証プロバイダーを使用してもサインインできなくなる。

### セキュリティリスク {#security-risks}

LDAPインテグレーションは、LDAPユーザーが以下を実行できない場合にのみ使用してください。

- LDAPサーバー上で、自身の`mail`、`email`、または`userPrincipalName`属性を変更すること。ユーザーがこれらの属性を変更できる場合、GitLabサーバー上の任意のアカウントを乗っ取る可能性があります。
- 同じメールアドレスを共有すること。同じメールアドレスを持つLDAPユーザーは、同じGitLabアカウントを共有できます。

## LDAPを設定する {#configure-ldap}

前提要件:

- メールアドレスを使用してサインインするかどうかにかかわらず、LDAPを使用するにはメールアドレスが必要です。

LDAPを設定するには、設定ファイルを編集します。

- 設定ファイルには、次の[基本的な設定](#basic-configuration-settings)を含める必要があります。
  - `label`
  - `host`
  - `port`
  - `uid`
  - `base`
  - `encryption`

- 設定ファイルには、次のオプションの設定を含めることができます。
  - [オプションの基本設定](#basic-configuration-settings)。
  - [SSL設定](#ssl-configuration-settings)。
  - [属性設定](#attribute-configuration-settings)。
  - [LDAP同期の設定](#ldap-sync-configuration-settings)。

- LDAPを設定して、以下を行うこともできます。
  - [複数のサーバーを使用する](#use-multiple-ldap-servers)。
  - [ユーザーをフィルターする](#set-up-ldap-user-filter)。
  - [LDAPユーザー名を自動的に小文字に設定する](#enable-ldap-username-lowercase)。
  - [LDAP Webサインインを無効にする](#disable-ldap-web-sign-in)。
  - [GitLabでスマートカード認証を利用できるようにする](#provide-smart-card-authentication-for-gitlab)。
  - [暗号化された認証情報を使用する](#use-encrypted-credentials)。

編集するファイルは、GitLabのセットアップによって異なります。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_rails['ldap_enabled'] = true
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'label' => 'LDAP',
       'host' =>  'ldap.mydomain.com',
       'port' => 636,
       'uid' => 'sAMAccountName',
       'bind_dn' => 'CN=Gitlab,OU=Users,DC=domain,DC=com',
       'password' => '<bind_user_password>',
       'encryption' => 'simple_tls',
       'verify_certificates' => true,
       'timeout' => 10,
       'active_directory' => false,
       'user_filter' => '(employeeType=developer)',
       'base' => 'dc=example,dc=com',
       'lowercase_usernames' => 'false',
       'retry_empty_result_with_codes' => [80],
       'allow_username_or_email_login' => false,
       'block_auto_created_users' => false
     }
   }
   ```

1. ファイルを保存して、GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. Helmの値をエクスポートします。

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します。

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             label: 'LDAP'
             host: 'ldap.mydomain.com'
             port: 636
             uid: 'sAMAccountName'
             bind_dn: 'CN=Gitlab,OU=Users,DC=domain,DC=com'
             password: '<bind_user_password>'
             encryption: 'simple_tls'
             verify_certificates: true
             timeout: 10
             active_directory: false
             user_filter: '(employeeType=developer)'
             base: 'dc=example,dc=com'
             lowercase_usernames: false
             retry_empty_result_with_codes: [80]
             allow_username_or_email_login: false
             block_auto_created_users: false
   ```

1. ファイルを保存して、新しい値を適用します。

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

詳細については、[Helmチャートを使用してインストールされたGitLabインスタンス向けにLDAPを設定する方法](https://docs.gitlab.com/charts/charts/globals.html#ldap)を参照してください。

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`を編集します。

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_enabled'] = true
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'label' => 'LDAP',
               'host' =>  'ldap.mydomain.com',
               'port' => 636,
               'uid' => 'sAMAccountName',
               'bind_dn' => 'CN=Gitlab,OU=Users,DC=domain,DC=com',
               'password' => '<bind_user_password>',
               'encryption' => 'simple_tls',
               'verify_certificates' => true,
               'timeout' => 10,
               'active_directory' => false,
               'user_filter' => '(employeeType=developer)',
               'base' => 'dc=example,dc=com',
               'lowercase_usernames' => 'false',
               'retry_empty_result_with_codes' => [80],
               'allow_username_or_email_login' => false,
               'block_auto_created_users' => false
             }
           }
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します。

   ```yaml
   production: &base
     ldap:
       enabled: true
       servers:
         main:
           label: 'LDAP'
           host: 'ldap.mydomain.com'
           port: 636
           uid: 'sAMAccountName'
           bind_dn: 'CN=Gitlab,OU=Users,DC=domain,DC=com'
           password: '<bind_user_password>'
           encryption: 'simple_tls'
           verify_certificates: true
           timeout: 10
           active_directory: false
           user_filter: '(employeeType=developer)'
           base: 'dc=example,dc=com'
           lowercase_usernames: false
           retry_empty_result_with_codes: [80]
           allow_username_or_email_login: false
           block_auto_created_users: false
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

さまざまなLDAPオプションの詳細については、[`gitlab.yml.example`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example)の`ldap`の設定を参照してください。

{{< /tab >}}

{{< /tabs >}}

LDAPを設定した後、設定をテストするには、[LDAPチェック用のRakeタスク](../../raketasks/ldap.md#check)を使用します。

### 基本設定 {#basic-configuration-settings}

次の基本設定を使用できます。

<!-- markdownlint-disable MD056 -->

| 設定                         | 必須               | 種類                          | 説明 |
|---------------------------------|------------------------|-------------------------------|-------------|
| `label`                         | {{< icon name="check-circle" >}}はい | 文字列                        | LDAPサーバーに付けるわかりやすい名前。サインインページに表示されます。例: `'Paris'`、`'Acme, Ltd.'` |
| `host`                          | {{< icon name="check-circle" >}}はい | 文字列                        | LDAPサーバーのIPアドレスまたはドメイン名。`hosts`が定義されている場合は無視されます。例: `'ldap.mydomain.com'` |
| `port`                          | {{< icon name="check-circle" >}}はい | 整数                       | LDAPサーバーで接続するポート。`hosts`が定義されている場合は無視されます。例: `389`または`636`（SSLの場合） |
| `uid`                           | {{< icon name="check-circle" >}}はい | 文字列                        | ユーザーがサインインする際に使用するユーザー名にマップするLDAP属性。`uid`にマップされる値ではなく、属性そのものである必要があります。GitLabのユーザー名には影響しません（[属性セクション](#attribute-configuration-settings)を参照）。例: `'sAMAccountName'`、`'uid'`、`'userPrincipalName'` |
| `base`                          | {{< icon name="check-circle" >}}はい | 文字列                        | ユーザーを検索できるベース。例: `'ou=people,dc=gitlab,dc=example'`、`'DC=mydomain,DC=com'` |
| `encryption`                    | {{< icon name="check-circle" >}}はい | 文字列                        | 暗号化方式（`method`キーは非推奨となり、代わりに`encryption`が使用されるようになりました）。指定できる値は、`'start_tls'`、`'simple_tls'`、`'plain'`のいずれかです。`simple_tls`はLDAPライブラリの「Simple TLS」に対応します。`start_tls`はStartTLSに対応しますが、標準のTLSと混同しないよう注意してください。`simple_tls`を指定した場合、通常はポート636を使用し、`start_tls`（StartTLS）はポート389を使用します。`plain`もポート389で動作します。 |
| `hosts`                         | {{< icon name="dotted-circle" >}}いいえ | 文字列と整数の配列 | 接続を確立するためのホストとポートのペアの配列。設定される各サーバーは、同一のデータセットを持つ必要があります。これは、複数の異なるLDAPサーバーを設定するためのものではなく、フェイルオーバーを設定するためのものです。ホストは、設定された順に試行されます。例: `[['ldap1.mydomain.com', 636], ['ldap2.mydomain.com', 636]]` |
| `bind_dn`                       | {{< icon name="dotted-circle" >}}いいえ | 文字列                        | バインドするユーザーの完全なDN。例: `'america\momo'`、`'CN=Gitlab,OU=Users,DC=domain,DC=com'` |
| `password`                      | {{< icon name="dotted-circle" >}}いいえ | 文字列                        | バインドするユーザーのパスワード。 |
| `verify_certificates`           | {{< icon name="dotted-circle" >}}いいえ | ブール値                       | デフォルトは`true`です。暗号化方式が`start_tls`または`simple_tls`の場合、SSL証明書の検証を有効にします。`false`に設定すると、LDAPサーバーのSSL証明書は検証されません。 |
| `timeout`                       | {{< icon name="dotted-circle" >}}いいえ | 整数                       | デフォルトは`10`です。LDAPクエリのタイムアウトを秒単位で設定します。これにより、LDAPサーバーが応答しなくなった場合にリクエストがブロックされるのを防げます。値を`0`に設定すると、タイムアウトは無効になります。 |
| `active_directory`              | {{< icon name="dotted-circle" >}}いいえ | ブール値                       | この設定は、LDAPサーバーがActive Directoryであるかどうかを指定します。AD以外のサーバーの場合、AD固有のクエリはスキップされます。LDAPサーバーがADでない場合は、これをfalseに設定します。 |
| `allow_username_or_email_login` | {{< icon name="dotted-circle" >}}いいえ | ブール値                       | デフォルトは`false`です。有効にすると、GitLabは、サインイン時にユーザーから送信されたLDAPユーザー名の最初の`@`以降をすべて無視します。Active Directoryで`uid: 'userPrincipalName'`を使用している場合は、この設定を無効にする必要があります。その理由は、userPrincipalNameに`@`が含まれているためです。 |
| `block_auto_created_users`      | {{< icon name="dotted-circle" >}}いいえ | ブール値                       | デフォルトは`false`です。GitLabインストール環境で請求対象ユーザー数を厳密に管理するには、この設定を有効にします。有効にすると、新しいユーザーは管理者によって承認されるまでブロックされたままになります。 |
| `user_filter`                   | {{< icon name="dotted-circle" >}}いいえ | 文字列                        | LDAPユーザーをフィルタリングします。[RFC 4515](https://www.rfc-editor.org/rfc/rfc4515.html)の形式に従います。GitLabは`omniauth-ldap`のカスタムフィルター構文をサポートしていません。`user_filter`フィールドの構文の例:<br/><br/>- `'(employeeType=developer)'`<br/>- `'(&(objectclass=user)(\|(samaccountname=momo)(samaccountname=toto)))'` |
| `lowercase_usernames`           | {{< icon name="dotted-circle" >}}いいえ | ブール値                       | 有効にすると、GitLabは名前を小文字に変換します。 |
| `retry_empty_result_with_codes` | {{< icon name="dotted-circle" >}}いいえ | 配列                         | 結果/コンテンツが空であった場合に操作の再試行を試みるLDAPクエリ応答コードの配列。Google Secure LDAPの場合、この値を`[80]`に設定します。 |

<!-- markdownlint-enable MD056 -->

### SSL設定 {#ssl-configuration-settings}

`tls_options`の名前と値のペアで、SSLを設定できます。次の設定はすべてオプションです。

| 設定       | 説明 | 例 |
|---------------|-------------|----------|
| `ca_file`     | たとえば、内部CAが必要な場合などに、PEM形式のCA証明書を含むファイルのパスを指定します。 | `'/etc/ca.pem'` |
| `ssl_version` | OpenSSLのデフォルト設定が適切でない場合に使用する、OpenSSLバージョンを指定します。 | `'TLSv1_1'` |
| `ciphers`     | LDAPサーバーとの通信で使用する特定のSSL暗号。 | `'ALL:!EXPORT:!LOW:!aNULL:!eNULL:!SSLv2'` |
| `cert`        | クライアント証明書。 | `'-----BEGIN CERTIFICATE----- <REDACTED> -----END CERTIFICATE -----'` |
| `key`         | クライアントの秘密キー。 | `'-----BEGIN PRIVATE KEY----- <REDACTED> -----END PRIVATE KEY -----'` |

次の例は、`tls_options`で`ca_file`および`ssl_version`を設定する方法を示しています。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_rails['ldap_enabled'] = true
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'label' => 'LDAP',
       'host' =>  'ldap.mydomain.com',
       'port' => 636,
       'uid' => 'sAMAccountName',
       'encryption' => 'simple_tls',
       'base' => 'dc=example,dc=com'
       'tls_options' => {
         'ca_file' => '/path/to/ca_file.pem',
         'ssl_version' => 'TLSv1_2'
       }
     }
   }
   ```

1. ファイルを保存して、GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. Helmの値をエクスポートします。

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します。

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             label: 'LDAP'
             host: 'ldap.mydomain.com'
             port: 636
             uid: 'sAMAccountName'
             base: 'dc=example,dc=com'
             encryption: 'simple_tls'
             tls_options:
               ca_file: '/path/to/ca_file.pem'
               ssl_version: 'TLSv1_2'
   ```

1. ファイルを保存して、新しい値を適用します。

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

詳細については、[Helmチャートを使用してインストールされたGitLabインスタンス向けにLDAPを設定する方法](https://docs.gitlab.com/charts/charts/globals.html#ldap)を参照してください。

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`を編集します。

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_enabled'] = true
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'label' => 'LDAP',
               'host' =>  'ldap.mydomain.com',
               'port' => 636,
               'uid' => 'sAMAccountName',
               'encryption' => 'simple_tls',
               'base' => 'dc=example,dc=com',
               'tls_options' => {
                 'ca_file' => '/path/to/ca_file.pem',
                 'ssl_version' => 'TLSv1_2'
               }
             }
           }
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します。

   ```yaml
   production: &base
     ldap:
       enabled: true
       servers:
         main:
           label: 'LDAP'
           host: 'ldap.mydomain.com'
           port: 636
           uid: 'sAMAccountName'
           encryption: 'simple_tls'
           base: 'dc=example,dc=com'
           tls_options:
             ca_file: '/path/to/ca_file.pem'
             ssl_version: 'TLSv1_2'
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### 属性の設定 {#attribute-configuration-settings}

GitLabは、これらのLDAP属性を使用して、LDAPユーザーのアカウントを作成します。指定できる属性は、次のいずれかです。

- 属性名を文字列として指定する。例: `'mail'`。
- 順番に試行する属性名の配列。例: `['mail', 'email']`。

ユーザーのLDAPサインインには、[`uid`として指定](#basic-configuration-settings)されたLDAP属性が使用されます。

次のLDAP属性はすべてオプションです。これらの属性を定義する場合は、`attributes`ハッシュで指定する必要があります。

| 設定      | 説明 | 例 |
|--------------|-------------|----------|
| `username`   | GitLabアカウントのプロビジョニングに使用する`@username`。値にメールアドレスが含まれている場合、メールアドレスの`@`より前の部分がGitLabのユーザー名になります。デフォルトでは、[`uid`として指定](#basic-configuration-settings)されたLDAP属性になります。 | `['uid', 'userid', 'sAMAccountName']` |
| `email`      | ユーザーのメールアドレスのLDAP属性。デフォルトは`['mail', 'email', 'userPrincipalName']`です。 | `['mail', 'email', 'userPrincipalName']` |
| `name`       | ユーザー表示名のLDAP属性。`name`が空白の場合、フルネームは`first_name`と`last_name`から取得されます。デフォルトは`'cn'`です。 | `'cn'`や`'displayName'`属性は一般的にフルネームが格納されます。代わりに、`'somethingNonExistent'`などの存在しない属性を指定することで、`first_name`と`last_name`を強制的に使用させることができます。 |
| `first_name` | ユーザーの名のLDAP属性。`name`に設定された属性が存在しない場合に使用されます。デフォルトは`'givenName'`です。 | `'givenName'` |
| `last_name`  | ユーザーの姓のLDAP属性。`name`に設定された属性が存在しない場合に使用されます。デフォルトは`'sn'`です。 | `'sn'` |

### LDAP同期の設定 {#ldap-sync-configuration-settings}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

以下のLDAP同期の設定はオプションです。ただし、`external_groups`が設定されている場合は`group_base`が必須となります。

| 設定           | 説明 | 例 |
|-------------------|-------------|----------|
| `group_base`      | グループの検索に使用されるベース。有効なグループはすべて、このベースをDNの一部として持ちます。 | `'ou=groups,dc=gitlab,dc=example'` |
| `admin_group`     | GitLab管理者を含むグループのCN。`cn=administrators`や完全なDNではありません。 | `'administrators'` |
| `external_groups` | 外部ユーザーとして扱うべきユーザーを含むグループのCNの配列。`cn=interns`や完全なDNではありません。 | `['interns', 'contractors']` |
| `sync_ssh_keys`   | ユーザーの公開SSHキーを含むLDAP属性。 | `'sshPublicKey'`、設定しない場合はfalse |

{{< alert type="note" >}}

Railsサーバーとは異なるサーバーでSidekiqが設定されている場合、LDAP同期を機能させるには、すべてのSidekiqサーバーにもLDAP設定を追加する必要があります。

{{< /alert >}}

### 複数のLDAPサーバーを使用する {#use-multiple-ldap-servers}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

複数のLDAPサーバーにユーザーがいる場合は、それらのサーバーを使用するようにGitLabを設定できます。LDAPサーバーを追加するには、次の手順に従います。

1. [`main` LDAP設定](#configure-ldap)を複製します。
1. 複製された各設定を編集し、追加のサーバーの詳細を入力します。
   - 追加する各サーバーには、`main`、`secondary`、`tertiary`のように、異なるプロバイダーIDを指定します。小文字の英数字を使用します。GitLabはこのプロバイダーIDを使用して、各ユーザーを特定のLDAPサーバーに関連付けます。
   - エントリごとに、一意の`label`値を使用します。これらの値は、サインインページのタブ名として使用されます。

次の例は、最小限の設定で3つのLDAPサーバーを設定する方法を示しています。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_rails['ldap_enabled'] = true
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'label' => 'GitLab AD',
       'host' =>  'ad.mydomain.com',
       'port' => 636,
       'uid' => 'sAMAccountName',
       'encryption' => 'simple_tls',
       'base' => 'dc=example,dc=com',
     },

     'secondary' => {
       'label' => 'GitLab Secondary AD',
       'host' =>  'ad-secondary.mydomain.com',
       'port' => 636,
       'uid' => 'sAMAccountName',
       'encryption' => 'simple_tls',
       'base' => 'dc=example,dc=com',
     },

     'tertiary' => {
       'label' => 'GitLab Tertiary AD',
       'host' =>  'ad-tertiary.mydomain.com',
       'port' => 636,
       'uid' => 'sAMAccountName',
       'encryption' => 'simple_tls',
       'base' => 'dc=example,dc=com',
     }
   }
   ```

1. ファイルを保存して、GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. Helmの値をエクスポートします。

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します。

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             label: 'GitLab AD'
             host: 'ad.mydomain.com'
             port: 636
             uid: 'sAMAccountName'
             base: 'dc=example,dc=com'
             encryption: 'simple_tls'
           secondary:
             label: 'GitLab Secondary AD'
             host: 'ad-secondary.mydomain.com'
             port: 636
             uid: 'sAMAccountName'
             base: 'dc=example,dc=com'
             encryption: 'simple_tls'
           tertiary:
             label: 'GitLab Tertiary AD'
             host: 'ad-tertiary.mydomain.com'
             port: 636
             uid: 'sAMAccountName'
             base: 'dc=example,dc=com'
             encryption: 'simple_tls'
   ```

1. ファイルを保存して、新しい値を適用します。

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`を編集します。

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_enabled'] = true
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'label' => 'GitLab AD',
               'host' =>  'ad.mydomain.com',
               'port' => 636,
               'uid' => 'sAMAccountName',
               'encryption' => 'simple_tls',
               'base' => 'dc=example,dc=com',
             },

             'secondary' => {
               'label' => 'GitLab Secondary AD',
               'host' =>  'ad-secondary.mydomain.com',
               'port' => 636,
               'uid' => 'sAMAccountName',
               'encryption' => 'simple_tls',
               'base' => 'dc=example,dc=com',
             },

             'tertiary' => {
               'label' => 'GitLab Tertiary AD',
               'host' =>  'ad-tertiary.mydomain.com',
               'port' => 636,
               'uid' => 'sAMAccountName',
               'encryption' => 'simple_tls',
               'base' => 'dc=example,dc=com',
             }
           }
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します。

   ```yaml
   production: &base
     ldap:
       enabled: true
       servers:
         main:
           label: 'GitLab AD'
           host: 'ad.mydomain.com'
           port: 636
           uid: 'sAMAccountName'
           base: 'dc=example,dc=com'
           encryption: 'simple_tls'
         secondary:
           label: 'GitLab Secondary AD'
           host: 'ad-secondary.mydomain.com'
           port: 636
           uid: 'sAMAccountName'
           base: 'dc=example,dc=com'
           encryption: 'simple_tls'
         tertiary:
           label: 'GitLab Tertiary AD'
           host: 'ad-tertiary.mydomain.com'
           port: 636
           uid: 'sAMAccountName'
           base: 'dc=example,dc=com'
           encryption: 'simple_tls'
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

さまざまなLDAPオプションの詳細については、[`gitlab.yml.example`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example)の`ldap`の設定を参照してください。

{{< /tab >}}

{{< /tabs >}}

この例では、サインインページに次のタブが表示されます。

- **GitLab AD**
- **GitLab Secondary AD**
- **GitLab Tertiary AD**

### LDAPユーザーフィルターを設定する {#set-up-ldap-user-filter}

GitLabへのすべてのアクセスを、LDAPサーバー上のLDAPユーザーの一部に制限するには、まず設定済みの`base`を絞り込みます。必要に応じて、LDAPユーザーフィルターを設定してユーザーをさらに絞り込むことができます。フィルターは、[RFC 4515](https://www.rfc-editor.org/rfc/rfc4515.html)に準拠する必要があります。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'user_filter' => '(employeeType=developer)'
     }
   }
   ```

1. ファイルを保存して、GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. Helmの値をエクスポートします。

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します。

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             user_filter: '(employeeType=developer)'
   ```

1. ファイルを保存して、新しい値を適用します。

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`を編集します。

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'user_filter' => '(employeeType=developer)'
             }
           }
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します。

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           user_filter: '(employeeType=developer)'
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

Active Directoryグループのネストされたメンバーへのアクセスを制限するには、次の構文を使用します。

```plaintext
(memberOf:1.2.840.113556.1.4.1941:=CN=My Group,DC=Example,DC=com)
```

`LDAP_MATCHING_RULE_IN_CHAIN`フィルターの詳細については、[検索フィルター構文](https://learn.microsoft.com/en-us/windows/win32/adsi/search-filter-syntax)を参照してください。

ユーザーフィルターにおけるネストされたメンバーのサポートを、[グループ同期におけるネストされたグループ](ldap_synchronization.md#supported-ldap-group-typesattributes)のサポートと混同しないように注意してください。

GitLabは、OmniAuth LDAPで使用されるカスタムフィルター構文をサポートしていません。

#### `user_filter`に含まれる特殊文字をエスケープする {#escape-special-characters-in-user_filter}

`user_filter` DNには、特殊文字を含めることができます。次に例を示します。

- カンマ:

  ```plaintext
  OU=GitLab, Inc,DC=gitlab,DC=com
  ```

- 開き括弧と閉じ括弧:

  ```plaintext
  OU=GitLab (Inc),DC=gitlab,DC=com
  ```

これらの文字は、[RFC 4515](https://www.rfc-editor.org/rfc/rfc4515.html#section-4)に記載されているようにエスケープする必要があります。

- カンマは`\2C`でエスケープします。次に例を示します。

  ```plaintext
  OU=GitLab\2C Inc,DC=gitlab,DC=com
  ```

- 開き括弧は`\28`で、閉じ括弧は`\29`でエスケープします。次に例を示します。

  ```plaintext
  OU=GitLab \28Inc\29,DC=gitlab,DC=com
  ```

### LDAPユーザー名の小文字への変換を有効にする {#enable-ldap-username-lowercase}

一部のLDAPサーバーでは、設定に応じて、ユーザー名を大文字で返すことがあります。これにより、大文字の名前でリンクやネームスペースが作成されるなど、いくつかの紛らわしい問題が発生する可能性があります。

GitLabは、設定オプション`lowercase_usernames`を有効にすることで、LDAPサーバーから提供されたユーザー名を自動的に小文字に変換できます。デフォルトでは、この設定オプションは`false`です。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'lowercase_usernames' => true
     }
   }
   ```

1. ファイルを保存して、GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. Helmの値をエクスポートします。

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します。

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
            lowercase_usernames: true
   ```

1. ファイルを保存して、新しい値を適用します。

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`を編集します。

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'lowercase_usernames' => true
             }
           }
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `config/gitlab.yaml`を編集します。

   ```yaml
   production:
     ldap:
       servers:
         main:
           lowercase_usernames: true
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### LDAP Webサインインを無効にする {#disable-ldap-web-sign-in}

SAMLなどの代替手段を優先したい場合、Web UIでのLDAP認証を無効にすると便利です。これにより、グループ同期にはLDAPを利用しつつ、SAMLのIdP側でカスタム2FAなど追加の認証チェックを行うことができます。

LDAP Webサインインを無効にすると、サインインページに**LDAP**タブは表示されなくなります。ただし、GitアクセスにLDAP認証情報を使用することは可能です。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_rails['prevent_ldap_sign_in'] = true
   ```

1. ファイルを保存して、GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. Helmの値をエクスポートします。

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します。

   ```yaml
   global:
     appConfig:
       ldap:
         preventSignin: true
   ```

1. ファイルを保存して、新しい値を適用します。

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`を編集します。

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['prevent_ldap_sign_in'] = true
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `config/gitlab.yaml`を編集します。

   ```yaml
   production:
     ldap:
       prevent_ldap_sign_in: true
   ```

1. ファイルを保存して、GitLabを再起動します。

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### GitLabでスマートカード認証を利用できるようにする {#provide-smart-card-authentication-for-gitlab}

LDAPサーバーおよびGitLabにおけるスマートカードの使用の詳細については、[スマートカード認証](../smartcard.md)を参照してください。

### 暗号化された認証情報を使用する {#use-encrypted-credentials}

LDAPインテグレーションの認証情報を設定ファイルにプレーンテキストで保存する代わりに、オプションで、暗号化されたファイルを使用することもできます。

前提要件:

- 暗号化された認証情報を使用するには、まず[暗号化設定](../../encrypted_configuration.md)を有効にする必要があります。

LDAPの暗号化設定は、暗号化されたYAMLファイルとして存在します。このファイルに含める暗号化されていない内容は、LDAP設定の`servers`ブロックに含まれるシークレット設定の一部である必要があります。

暗号化されたファイルでサポートされている設定項目は次のとおりです。

- `bind_dn`
- `password`

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. 最初に`/etc/gitlab/gitlab.rb`のLDAP設定が次のようになっている場合:

   ```ruby
     gitlab_rails['ldap_servers'] = {
       'main' => {
         'bind_dn' => 'admin',
         'password' => '123'
       }
     }
   ```

1. 暗号化されたシークレットを編集します。

   ```shell
   sudo gitlab-rake gitlab:ldap:secret:edit EDITOR=vim
   ```

1. LDAPシークレットの暗号化されていない内容を入力します。

   ```yaml
   main:
     bind_dn: admin
     password: '123'
   ```

1. `/etc/gitlab/gitlab.rb`を編集し、`bind_dn`と`password`の設定を削除します。
1. ファイルを保存して、GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

Kubernetesシークレットを使用してLDAPパスワードを保存します。詳細については、[HelmにおけるLDAPシークレット](https://docs.gitlab.com/charts/installation/secrets.html#ldap-password)を参照してください。

{{< /tab >}}

{{< tab title="Docker" >}}

1. 最初に`docker-compose.yml`のLDAP設定が次のようになっている場合:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'bind_dn' => 'admin',
               'password' => '123'
             }
           }
   ```

1. コンテナ内に入り、暗号化されたシークレットを編集します。

   ```shell
   sudo docker exec -t <container_name> bash
   gitlab-rake gitlab:ldap:secret:edit EDITOR=vim
   ```

1. LDAPシークレットの暗号化されていない内容を入力します。

   ```yaml
   main:
     bind_dn: admin
     password: '123'
   ```

1. `docker-compose.yml`を編集し、`bind_dn`と`password`の設定を削除します。
1. ファイルを保存して、GitLabを再起動します。

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. 最初に`/home/git/gitlab/config/gitlab.yml`のLDAP設定が次のようになっている場合:

   ```yaml
   production:
     ldap:
       servers:
         main:
           bind_dn: admin
           password: '123'
   ```

1. 暗号化されたシークレットを編集します。

   ```shell
   bundle exec rake gitlab:ldap:secret:edit EDITOR=vim RAILS_ENVIRONMENT=production
   ```

1. LDAPシークレットの暗号化されていない内容を入力します。

   ```yaml
   main:
    bind_dn: admin
    password: '123'
   ```

1. `/home/git/gitlab/config/gitlab.yml`を編集し、`bind_dn`と`password`の設定を削除します。
1. ファイルを保存して、GitLabを再起動します。

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## LDAPのDNとメールアドレスを更新する {#updating-ldap-dn-and-email}

LDAPサーバーがGitLabにユーザーを作成すると、そのユーザーのLDAP DNは識別子としてGitLabアカウントに関連付けられます。

ユーザーがLDAPでサインインしようとすると、GitLabはそのユーザーのアカウントに保存されているDNを使用してユーザーを検索しようとします。

- GitLabがDNでユーザーを特定できた場合、次のように処理します。
  - ユーザーのメールアドレスがGitLabアカウントのメールアドレスと一致している場合、GitLabはそれ以上の処理を行いません。
  - ユーザーのメールアドレスが変更されている場合、GitLabはLDAPに登録されているメールに合わせて、ユーザーのメールのレコードを更新します。
- GitLabがDNでユーザーを特定できない場合、メールアドレスでユーザーを検索しようとします。検索結果に応じて、次のように対応します。
  - メールアドレスでユーザーを特定できた場合、GitLabはユーザーのGitLabアカウントに保存されているDNを更新します。これにより、両方の値がLDAPに保存されている情報と一致するようになります。
  - メールアドレスでユーザーを特定できない場合（DN**と**メールアドレスが変更された場合）、[ユーザーのDNとメールアドレスが変更された](ldap-troubleshooting.md#user-dn-and-email-have-changed)を参照してください。

## 匿名LDAP認証を無効にする {#disable-anonymous-ldap-authentication}

GitLabはTLSクライアント認証をサポートしていません。LDAPサーバーで次の手順を実行します。

1. 匿名認証を無効にします。
1. 次のいずれかの認証タイプを有効にします。
   - 単純認証。
   - SASL（Simple Authenticationand Security Layer）認証。

LDAPサーバーにおいて、TLSクライアント認証の設定を必須にすることはできません。また、クライアントはTLSプロトコルで認証できません。

## LDAPから削除されたユーザー {#users-deleted-from-ldap}

LDAPサーバーから削除されたユーザーは、以下の通りとなります。

- GitLabへのサインインが即座にブロックされます。
- [ライセンスを消費しなくなります](../../moderate_users.md)。

ただし、これらのユーザーは、次回[LDAPチェックキャッシュが実行される](ldap_synchronization.md#adjust-ldap-user-sync-schedule)まで、SSHを使用して引き続きGitを使用できます。

アカウントをすぐに削除する場合は、手動で[ユーザーをブロック](../../moderate_users.md#block-a-user)できます。

## ユーザーのメールアドレスを更新する {#update-user-email-addresses}

LDAPを使用してサインインする場合、LDAPサーバー上のメールアドレスはユーザーの信頼できる情報源と見なされます。

ユーザーのメールアドレスの更新は、そのユーザーを管理しているLDAPサーバーで行う必要があります。GitLab側のメールアドレスは、次のいずれかのタイミングで更新されます。

- ユーザーが次回サインインしたとき。
- 次回の[ユーザー同期](ldap_synchronization.md#user-sync)を実行したとき。

更新されたユーザーの以前のメールアドレスは、そのユーザーのコミット履歴を保持するためにセカンダリメールアドレスになります。

ユーザー更新時に予期される動作の詳細については、[LDAPのトラブルシューティングセクション](ldap-troubleshooting.md#user-dn-and-email-have-changed)を参照してください。

## Google Secure LDAP {#google-secure-ldap}

[Google Cloud Identity](https://cloud.google.com/identity/)は、GitLabでの認証やグループ同期に利用できるSecure LDAPサービスを提供しています。詳細な設定手順については、[Google Secure LDAP](google_secure_ldap.md)を参照してください。

## ユーザーとグループを同期する {#synchronize-users-and-groups}

LDAPとGitLab間でユーザーとグループを同期する方法の詳細については、[LDAP同期](ldap_synchronization.md)を参照してください。

## LDAPからSAMLに移行する {#move-from-ldap-to-saml}

1. 以下のファイルに[SAML設定を追加](../../../integration/saml.md)します。
   - [Linuxパッケージインストールの場合: `gitlab.rb`](../../../integration/saml.md)。
   - [Helmチャートでインストールした場合: `values.yml`](../../../integration/saml.md)

1. （オプション）[サインインページからLDAP認証を無効にします](#disable-ldap-web-sign-in)。

1. （オプション）ユーザーのリンクに関する問題を修正するには、まず、[該当するユーザーのLDAP IDを削除](ldap-troubleshooting.md#remove-the-identity-records-that-relate-to-the-removed-ldap-server)できます。

1. ユーザーがアカウントにサインインできることを確認します。ユーザーがサインインできない場合は、そのユーザーのLDAPがまだ残っていないかを確認し、必要に応じて削除します。この問題が依然として解決しない場合は、ログを調べて問題を特定してください。

1. 設定ファイルで、次のように変更します。
   - `omniauth_auto_link_user`を`saml`のみに変更する。
   - `omniauth_auto_link_ldap_user`をfalseに変更する。
   - `ldap_enabled`を`false`に変更する。LDAPプロバイダーの設定をコメントアウトすることも可能です。

## トラブルシューティング {#troubleshooting}

[LDAPのトラブルシューティングに関する管理者ガイド](ldap-troubleshooting.md)を参照してください。
