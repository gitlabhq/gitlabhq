---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: スマートカード認証
description: 証明書ベースのログインのために、ハードウェアデバイスを使用して認証します。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、スマートカードを使用した認証をサポートしています。

## 既存のパスワード認証 {#existing-password-authentication}

デフォルトでは、スマートカード認証が有効になっている場合、既存のユーザー名とパスワードを使用してサインインし続けることができます。

既存のユーザー名とパスワードによる認証のみを強制的に使用させるには、[ユーザー名とパスワード認証を無効](../settings/sign_in_restrictions.md#password-authentication-enabled)にしてください。

## 認証方法 {#authentication-methods}

GitLabは、2つの認証方法をサポートしています:

- ローカルデータベースを使用したX.509証明書。
- LDAPサーバー。

### X.509証明書を使用したローカルデータベースに対する認証 {#authentication-against-a-local-database-with-x509-certificates}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

X.509証明書付きのスマートカードを使用してGitLabで認証できます。

X.509証明書付きのスマートカードを使用してGitLabのローカルデータベースに対して認証するには、証明書に`CN`と`emailAddress`が定義されている必要があります。次に例を示します: 

```plaintext
Certificate:
    Data:
        Version: 1 (0x0)
        Serial Number: 12856475246677808609 (0xb26b601ecdd555e1)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: O=Random Corp Ltd, CN=Random Corp
        Validity
            Not Before: Oct 30 12:00:00 2018 GMT
            Not After : Oct 30 12:00:00 2019 GMT
        Subject: CN=Gitlab User, emailAddress=gitlab-user@example.com
```

### X.509証明書とSAN拡張機能を使用したローカルデータベースに対する認証 {#authentication-against-a-local-database-with-x509-certificates-and-san-extension}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

SAN拡張機能を使用するX.509証明書付きのスマートカードを使用してGitLabで認証できます。

X.509証明書付きのスマートカードを使用してGitLabのローカルデータベースに対して認証するには:

- 少なくとも1つの`subjectAltName`（SAN）拡張機能は、GitLabインスタンス（`URI`）内でユーザーID（`email`）を定義する必要があります。
- `URI`は`Gitlab.config.host.gitlab`と一致する必要があります。
- 証明書に**1つ**のSANメールエントリのみが含まれている場合、`email`を`URI`と一致させるために追加または変更する必要はありません。

次に例を示します: 

```plaintext
Certificate:
    Data:
        Version: 1 (0x0)
        Serial Number: 12856475246677808609 (0xb26b601ecdd555e1)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: O=Random Corp Ltd, CN=Random Corp
        Validity
            Not Before: Oct 30 12:00:00 2018 GMT
            Not After : Oct 30 12:00:00 2019 GMT
        ...
        X509v3 extensions:
            X509v3 Key Usage:
                Key Encipherment, Data Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication
            X509v3 Subject Alternative Name:
                email:gitlab-user@example.com, URI:http://gitlab.example.com/
```

### LDAPサーバーに対する認証 {#authentication-against-an-ldap-server}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

GitLabは、[RFC4523](https://www.rfc-editor.org/rfc/rfc4523)に従って、証明書照合の標準的な方法を実装しています。これは、`certificateExactMatch`証明書照合ルールを`userCertificate`属性に対して使用します。前提条件として、次のLDAPサーバーを使用する必要があります:

- `certificateExactMatch`照合ルールをサポートします。
- `userCertificate`属性に保存されている証明書があります。

### Active Directory LDAPサーバーに対する認証 {#authentication-against-an-active-directory-ldap-server}

{{< history >}}

- GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/328074)されました。
- [追加](https://gitlab.com/gitlab-org/gitlab/-/issues/514025)された`reverse_issuer_and_subject`および`reverse_issuer_and_serial_number`形式（GitLab 17.11）。

{{< /history >}}

Active Directoryは、`certificateExactMatch`ルールまたは`userCertificate`属性をサポートしていません。スマートカードなどの証明書ベースの認証用のほとんどのツールは、`altSecurityIdentities`属性を使用します。これには、ユーザーごとに複数の証明書を含めることができます。フィールド内のデータは、[Microsoftが推奨する形式のいずれか](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-certificate-based-authentication-certificateuserids#supported-patterns-for-certificate-user-ids)と一致する必要があります。

次の属性を使用して、GitLabがチェックするフィールドと証明書データの形式をカスタマイズします:

- `smartcard_ad_cert_field` - 検索するフィールドの名前を指定します。これは、ユーザーオブジェクトの任意の属性にすることができます。
- `smartcard_ad_cert_format` - 証明書から収集された情報の形式を指定します。この形式は、次のいずれかの値である必要があります。最も一般的なのは、Active Directory以外のLDAPサーバーの動作と一致させるための`issuer_and_serial_number`です。

| `smartcard_ad_cert_format` | データの例                                                 |
| -------------------------- | ------------------------------------------------------------ |
| `principal_name`           | `X509:<PN>alice@example.com`                                 |
| `rfc822_name`              | `X509:<RFC822>bob@example.com`                               |
| `subject`                  | `X509:<S>DC=com,DC=example,OU=UserAccounts,CN=dennis`        |
| `issuer_and_serial_number` | `X509:<I>DC=com,DC=example,CN=CONTOSO-DC-CA<SR>1181914561`   |
| `issuer_and_subject`       | `X509:<I>DC=com,DC=example,CN=EXAMPLE-DC-CA<S>DC=com,DC=example,OU=UserAccounts,CN=cynthia` |
| `reverse_issuer_and_serial_number` | `X509:<I>CN=CONTOSO-DC-CA,DC=example,DC=com<SR>1181914561`   |
| `reverse_issuer_and_subject`   | `X509:<I>CN=EXAMPLE-DC-CA,DC=example,DC=com<S>DC=com,DC=example,OU=UserAccounts,CN=cynthia` |

`issuer_and_serial_number`の場合、`<SR>`の部分はリバースバイトオーダーで、最下位バイトが最初になります。詳細については、[altSecurityIdentities属性を使用して、ユーザーを証明書にマップする方法](https://learn.microsoft.com/en-us/archive/blogs/spatdsg/howto-map-a-user-to-a-certificate-via-all-the-methods-available-in-the-altsecurityidentities-attribute)を参照してください。

リバース発行者形式は、発行者文字列を最小単位から最大単位にソートします。一部のActive Directoryサーバーは、この形式で証明書を保存します。

{{< alert type="note" >}}

`smartcard_ad_cert_format`が指定されていないが、LDAPサーバーが`active_directory: true`で構成され、スマートカードが有効になっている場合、GitLabは16.8以前の動作にデフォルト設定され、`certificateExactMatch`を`userCertificate`属性で使用します。

{{< /alert >}}

### Azure IDドメインサービスに対する認証 {#authentication-against-entra-id-domain-services}

{{< history >}}

- GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/328074)されました。

{{< /history >}}

[Microsoft Azure ID](https://learn.microsoft.com/en-us/entra/fundamentals/whatis)（旧称Azure Active Directory）は、企業および組織向けのクラウドベースのディレクトリを提供します。[Azureドメインサービス](https://learn.microsoft.com/en-us/entra/identity/domain-services/overview)は、ディレクトリへの安全な読み取り専用LDAPインターフェースを提供しますが、Azure IDが持つフィールドの限られたサブセットのみを公開します。

Azure IDは、ユーザーのクライアント証明書を管理するために`CertificateUserIds`フィールドを使用しますが、このフィールドはLDAP / Azure IDドメインサービスでは公開されません。クラウドのみのセットアップでは、GitLabがLDAPを使用してユーザーのスマートカードを認証することはできません。

ハイブリッドオンプレミスおよびクラウド環境では、エンティティはオンプレミスのActive DirectoryコントローラーとクラウドAzure IDの間で[Azure Connect](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/whatis-azure-ad-connect-v2)を使用して同期されます。Entra ID Connectを使用して[Azure IDの`certificateUserIds`属性に`altSecurityIdentities`属性を同期する](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-certificate-based-authentication-certificateuserids#update-certificateuserids-using-microsoft-entra-connect)場合は、このデータをLDAP / Azure IDドメインサービスで公開して、GitLabで認証できるようにすることができます:

1. Azure ID Connectにルールを追加して、Azure IDの追加の属性に`altSecurityIdentities`属性を同期します。
1. その追加の属性を[Azure IDドメインサービスの拡張属性](https://learn.microsoft.com/en-us/entra/identity/domain-services/concepts-custom-attributes)として有効にします。
1. この拡張属性を使用するように、GitLabの`smartcard_ad_cert_field`フィールドを構成します。

## スマートカード認証用のGitLabを構成する {#configure-gitlab-for-smart-card-authentication}

Linuxパッケージインストールの場合:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   # Allow smart card authentication
   gitlab_rails['smartcard_enabled'] = true

   # Path to a file containing a CA certificate
   gitlab_rails['smartcard_ca_file'] = "/etc/ssl/certs/CA.pem"

   # Host and port where the client side certificate is requested by the
   # webserver (NGINX/Apache)
   gitlab_rails['smartcard_client_certificate_required_host'] = "smartcard.example.com"
   gitlab_rails['smartcard_client_certificate_required_port'] = 3444
   ```

   {{< alert type="note" >}}

   次の変数の少なくとも1つ（`gitlab_rails['smartcard_client_certificate_required_host']`または`gitlab_rails['smartcard_client_certificate_required_port']`）に値を割り当てます。

   {{< /alert >}}

1. ファイルを保存して、変更を有効にするためにGitLabを[再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)してください。

自己コンパイルによるインストールの場合: 

1. クライアント側の証明書をリクエストするようにNGINXを構成します

   NGINX構成では、同じ構成で、**追加**のサーバーコンテキストを定義する必要があります:

   - 追加のNGINXサーバーコンテキストは、異なるポートで実行するように構成する必要があります:

     ```plaintext
     listen *:3444 ssl;
     ```

   - 異なるホスト名で実行するように構成することもできます:

     ```plaintext
     listen smartcard.example.com:443 ssl;
     ```

   - 追加のNGINXサーバーコンテキストは、クライアント側の証明書を要求するように構成する必要があります:

     ```plaintext
     ssl_verify_depth 2;
     ssl_client_certificate /etc/ssl/certs/CA.pem;
     ssl_verify_client on;
     ```

   - 追加のNGINXサーバーコンテキストは、クライアント側の証明書を転送するように構成する必要があります:

     ```plaintext
     proxy_set_header    X-SSL-Client-Certificate    $ssl_client_escaped_cert;
     ```

   たとえば、以下は、NGINX構成ファイル（`/etc/nginx/sites-available/gitlab-ssl`など）のサーバーコンテキストの例です:

   ```plaintext
   server {
       listen smartcard.example.com:3443 ssl;

       # certificate for configuring SSL
       ssl_certificate /path/to/example.com.crt;
       ssl_certificate_key /path/to/example.com.key;

       ssl_verify_depth 2;
       # CA certificate for client side certificate verification
       ssl_client_certificate /etc/ssl/certs/CA.pem;
       ssl_verify_client on;

       location / {
           proxy_set_header    Host                        $http_host;
           proxy_set_header    X-Real-IP                   $remote_addr;
           proxy_set_header    X-Forwarded-For             $proxy_add_x_forwarded_for;
           proxy_set_header    X-Forwarded-Proto           $scheme;
           proxy_set_header    Upgrade                     $http_upgrade;
           proxy_set_header    Connection                  $connection_upgrade;

           proxy_set_header    X-SSL-Client-Certificate    $ssl_client_escaped_cert;

           proxy_read_timeout 300;

           proxy_pass http://gitlab-workhorse;
       }
   }
   ```

1. `config/gitlab.yml`を編集します:

   ```yaml
   ## Smart card authentication settings
   smartcard:
     # Allow smart card authentication
     enabled: true

     # Path to a file containing a CA certificate
     ca_file: '/etc/ssl/certs/CA.pem'

     # Host and port where the client side certificate is requested by the
     # webserver (NGINX/Apache)
     client_certificate_required_host: smartcard.example.com
     client_certificate_required_port: 3443
   ```

   {{< alert type="note" >}}

   次の変数の少なくとも1つ（`client_certificate_required_host`または`client_certificate_required_port`）に値を割り当てます。

   {{< /alert >}}

1. ファイルを保存して、変更を有効にするためにGitLabを[再起動](../restart_gitlab.md#self-compiled-installations)してください。

### SAN拡張機能を使用する場合の追加手順 {#additional-steps-when-using-san-extensions}

Linuxパッケージインストールの場合:

1. `/etc/gitlab/gitlab.rb`に追加:

   ```ruby
   gitlab_rails['smartcard_san_extensions'] = true
   ```

1. ファイルを保存して、変更を有効にするためにGitLabを[再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)してください。

自己コンパイルによるインストールの場合: 

1. スマートカードセクション内の`config/gitlab.yml`に`san_extensions`行を追加します:

   ```yaml
   smartcard:
      enabled: true
      ca_file: '/etc/ssl/certs/CA.pem'
      client_certificate_required_port: 3444

      # Enable the use of SAN extensions to match users with certificates
      san_extensions: true
   ```

1. ファイルを保存して、変更を有効にするためにGitLabを[再起動](../restart_gitlab.md#self-compiled-installations)してください。

### LDAPサーバーに対して認証する場合の追加手順 {#additional-steps-when-authenticating-against-an-ldap-server}

Linuxパッケージインストールの場合:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['ldap_servers'] = YAML.load <<-EOS
   main:
     # snip...
     # Enable smart card authentication against the LDAP server. Valid values
     # are "false", "optional", and "required".
     smartcard_auth: optional

     # If your LDAP server is Active Directory, you can configure these two fields.
     # Specify which field contains certificate information, 'altSecurityIdentities' by default
     smartcard_ad_cert_field: altSecurityIdentities

     # Specify format of certificate information. Valid values are:
     # principal_name, rfc822_name, issuer_and_subject, subject, issuer_and_serial_number
     smartcard_ad_cert_format: issuer_and_serial_number
   EOS
   ```

1. ファイルを保存して、変更を有効にするためにGitLabを[再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)してください。

自己コンパイルによるインストールの場合: 

1. `config/gitlab.yml`を編集します:

   ```yaml
   production:
     ldap:
       servers:
         main:
           # snip...
           # Enable smart card authentication against the LDAP server. Valid values
           # are "false", "optional", and "required".
           smartcard_auth: optional

           # If your LDAP server is Active Directory, you can configure these two fields.
           # Specify which field contains certificate information, 'altSecurityIdentities' by default
           smartcard_ad_cert_field: altSecurityIdentities

           # Specify format of certificate information. Valid values are:
           # principal_name, rfc822_name, issuer_and_subject, subject, issuer_and_serial_number
           smartcard_ad_cert_format: issuer_and_serial_number
   ```

1. ファイルを保存して、変更を有効にするためにGitLabを[再起動](../restart_gitlab.md#self-compiled-installations)してください。

### Gitアクセスにスマートカードサインインによるブラウザセッションを必須にする {#require-browser-session-with-smart-card-sign-in-for-git-access}

Linuxパッケージインストールの場合:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['smartcard_required_for_git_access'] = true
   ```

1. ファイルを保存して、変更を有効にするためにGitLabを[再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)してください。

自己コンパイルによるインストールの場合: 

1. `config/gitlab.yml`を編集します:

   ```yaml
   ## Smart card authentication settings
   smartcard:
     # snip...
     # Browser session with smart card sign-in is required for Git access
     required_for_git_access: true
   ```

1. ファイルを保存して、変更を有効にするためにGitLabを[再起動](../restart_gitlab.md#self-compiled-installations)してください。

## スマートカード認証を介して作成されたユーザーのパスワード {#passwords-for-users-created-via-smart-card-authentication}

[統合認証で作成されたユーザーのパスワードの生成](../../security/passwords_for_integrated_authentication_methods.md)ガイドでは、スマートカード認証で作成されたユーザーに対してGitLabがパスワードを生成および設定する方法の概要を説明しています。
