---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabをKerberosと連携する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、[Kerberos](https://web.mit.edu/kerberos/)を認証メカニズムとして統合できます。

- ユーザーがKerberosの認証情報でサインインできるように、GitLabを設定できます。
- Kerberosを使用すると、送信されたパスワードをだれかが傍受または盗聴するのを[防ぐ](https://web.mit.edu/sipb/doc/working/guide/guide/node20.html)ことができます。

Kerberosは、GitLab EEを使用するインスタンスでのみ使用できます。GitLab CEを実行している場合は、[GitLab CEからGitLab EEに変換する](../update/convert_to_ee/package.md)ことができます。

{{< alert type="warning" >}}

インテグレーションが[専用ポートを使用するように設定](#http-git-access-with-kerberos-token-passwordless-authentication)されていない限り、Kerberos対応のGitLabインスタンスでは、GitLab CI/CDは機能しません。

{{< /alert >}}

## 設定 {#configuration}

GitLabがKerberosトークンベースの認証を提供するには、次の前提条件を実行します。レルムを指定するなど、Kerberosを使用するためにシステムを設定する必要があります。GitLabは、システムのKerberos設定を使用します。

### GitLabキータブ {#gitlab-keytab}

1. GitLabサーバー上のHTTPサービス用のKerberosサービスプリンシパルを作成します。GitLabサーバーが`gitlab.example.com`で、Kerberosレルムが`EXAMPLE.COM`の場合、Kerberosデータベースに`HTTP/gitlab.example.com@EXAMPLE.COM`サービスプリンシパルを作成します。
1. サービスプリンシパルのキータブをGitLabサーバー上に作成します。たとえば`/etc/http.keytab`などです。

キータブは機密ファイルであり、GitLabユーザーが読み取り可能である必要があります。所有権を設定し、ファイルを適切に保護します:

```shell
sudo chown git /etc/http.keytab
sudo chmod 0600 /etc/http.keytab
```

### GitLabを設定する {#configure-gitlab}

#### 自己コンパイルによるインストール {#self-compiled-installations}

{{< alert type="note" >}}

セルフコンパイルインストールの場合は、`kerberos` gemグループが[インストールされている](../install/self_compiled/_index.md#install-gems)ことを確認してください。

{{< /alert >}}

1. Kerberosトークンベースの認証を有効にするには、[`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example)の`kerberos`セクションを編集します。ほとんどの場合、Kerberosを有効にし、キータブの場所を指定するだけで済みます:

   ```yaml
   omniauth:
     enabled: true
     allow_single_sign_on: ['kerberos']

   kerberos:
     # Allow the HTTP Negotiate authentication method for Git clients
     enabled: true

     # Kerberos 5 keytab file. The keytab file must be readable by the GitLab user,
     # and should be different from other keytabs in the system.
     # (default: use default keytab from Krb5 config)
     keytab: /etc/http.keytab
   ```

1. 変更を反映させるため、[GitLabを再起動](../administration/restart_gitlab.md#self-compiled-installations)します。

#### Linuxパッケージインストール {#linux-package-installations}

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['omniauth_allow_single_sign_on'] = ['kerberos']

   gitlab_rails['kerberos_enabled'] = true
   gitlab_rails['kerberos_keytab'] = "/etc/http.keytab"
   ```

   GitLabがKerberosを介して最初にサインインしたときにユーザーを自動的に作成しないようにするには、`gitlab_rails['omniauth_allow_single_sign_on']`に`kerberos`を設定しないでください。

1. 変更を有効にするには、[GitLabを再設定します](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)。

GitLabは、サインインおよびHTTP Gitアクセス用の`negotiate`認証メソッドを提供するようになり、この認証プロトコルをサポートするGitクライアントがKerberosトークンで認証できるようになりました。

#### シングルサインオンを有効にする {#enable-single-sign-on}

[共通設定](omniauth.md#configure-common-settings)で、`kerberos`をシングルサインオンプロバイダーとして追加します。これにより、既存のGitLabアカウントを持たないユーザーに対して、Just-In-Timeアカウントプロビジョニングが有効になります。

## Kerberosアカウントを作成してリンクする {#create-and-link-kerberos-accounts}

Kerberosアカウントを既存のGitLabアカウントにリンクするか、Kerberosユーザーがサインインしようとしたときに新しいアカウントを作成するようにGitLabを設定できます。

### Kerberosアカウントを既存のGitLabアカウントにリンクする {#link-a-kerberos-account-to-an-existing-gitlab-account}

{{< history >}}

- Kerberos SPNEGOは、GitLabバージョン15.4でKerberosに[名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96335)。

{{< /history >}}

管理者の場合は、Kerberosアカウントを既存のGitLabアカウントにリンクできます。これを行うには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. ユーザーを選択して、**識別子**タブを選択します。
1. **プロバイダー**ドロップダウンリストから、**Kerberos**を選択します。
1. **識別子**がKerberosユーザー名に対応していることを確認してください。
1. **変更を保存**を選択します。

管理者でない場合:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで、**アカウント**を選択します。
1. **サインインに利用するサービス**セクションで、**Connect Kerberos**（Kerberosに接続）を選択します。**サインインに利用するサービス**Kerberosオプションが表示されない場合は、[シングルサインオンを有効にする](#enable-single-sign-on)の要件に従ってください。

どちらの場合も、Kerberos認証情報を使用してGitLabアカウントにサインインできるようになります。

### 最初のサインイン時にアカウントを作成する {#create-accounts-on-first-sign-in}

ユーザーが最初にKerberosアカウントでGitLabにサインインすると、GitLabは一致するアカウントを作成します。続行する前に、Linuxパッケージとセルフコンパイルインストールインスタンスの[一般的な設定](omniauth.md#configure-common-settings)オプションを確認してください。また、`kerberos`を含める必要があります。

その情報があれば:

1. `allow_single_sign_on`設定で`'kerberos'`を含めます。
1. 今のところ、`block_auto_created_users`オプションデフォルトのtrueを受け入れます。
1. ユーザーがKerberos認証情報を使用してサインインしようとすると、GitLabは新しいアカウントを作成します。
   1. `block_auto_created_users`がtrueの場合、Kerberosユーザーには次のようなメッセージが表示されることがあります:

      ```shell
      Your account has been blocked. Please contact your GitLab
      administrator if you think this is an error.
      ```

      1. 管理者として、新しいブロックされたアカウントを確認できます:
         1. 左側のサイドバーの下部で、**管理者**を選択します。
         1. 左側のサイドバーで、**概要** > **ユーザー**を選択し、**ブロック済み**タブを確認します。
      1. ユーザーを有効にできます。
   1. `block_auto_created_users`がfalseの場合、Kerberosユーザーは認証され、GitLabにサインインします。

{{< alert type="warning" >}}

`block_auto_created_users`のデフォルトを保持することをお勧めします。管理者の知識なしにGitLabでアカウントを作成するKerberosユーザーは、セキュリティリスクになる可能性があります。

{{< /alert >}}

## KerberosアカウントとLDAPアカウントを一緒にリンクする {#link-kerberos-and-ldap-accounts-together}

ユーザーがKerberosでサインインしているが、[LDAPインテグレーション](../administration/auth/ldap/_index.md)も有効になっている場合、ユーザーは最初のサインイン時に自分のLDAPアカウントにリンクされます。これが機能するためには、いくつかの前提条件を満たす必要があります:

Kerberosユーザー名は、LDAPユーザーのUIDと一致する必要があります。管理者は、どのLDAP属性をGitLabの[LDAP設定](../administration/auth/ldap/_index.md#configure-ldap)でUIDとして使用するかを選択できますが、Active Directoryの場合、これは`sAMAccountName`にする必要があります。

Kerberosレルムは、LDAPユーザーの識別名のドメイン部分と一致する必要があります。たとえば、Kerberosレルムが`AD.EXAMPLE.COM`の場合、LDAPユーザーの識別名は`dc=ad,dc=example,dc=com`で終わる必要があります。

これらのルールをまとめると、リンクが機能するのは、ユーザーのKerberosユーザー名が`foo@AD.EXAMPLE.COM`の形式で、LDAP識別名が`sAMAccountName=foo,dc=ad,dc=example,dc=com`のように見える場合のみです。

### カスタム許可レルム {#custom-allowed-realms}

ユーザーのKerberosレルムがユーザーのLDAP DNのドメインと一致しない場合は、カスタム許可レルムを設定できます。設定値は、ユーザーが持つことが予想されるすべてのドメインを指定する必要があります。他のドメインはすべて無視され、LDAP識別子はリンクされません。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['kerberos_simple_ldap_linking_allowed_realms'] = ['example.com','kerberos.example.com']
   ```

1. ファイルを保存して、[再設定](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `config/gitlab.yml`を編集します:

   ```yaml
   kerberos:
     simple_ldap_linking_allowed_realms: ['example.com','kerberos.example.com']
   ```

1. ファイルを保存して、[再起動](../administration/restart_gitlab.md#self-compiled-installations)し、変更を有効にします。

{{< /tab >}}

{{< /tabs >}}

## HTTP Gitアクセス {#http-git-access}

リンクされたKerberosアカウントを使用すると、標準のGitLab認証情報だけでなく、Kerberosアカウントを使用して`git pull`および`git push`を行うことができます。

リンクされたKerberosアカウントを持つGitLabユーザーは、Kerberosトークンを使用して`git pull`および`git push`を行うこともできます。つまり、操作ごとにパスワードを送信する必要はありません。

{{< alert type="warning" >}}

[既知のイシュー](https://github.com/curl/curl/issues/1261)がバージョン7.64.1より前の`libcurl`にあり、ネゴシエート時に接続を再利用しません。これにより、プッシュが`http.postBuffer`設定よりも大きい場合に認可のイシューが発生します。これを回避するには、Gitが少なくとも`libcurl` 7.64.1を使用していることを確認してください。インストールされている`libcurl`バージョンを知るには、`curl-config --version`を実行します。

{{< /alert >}}

### Kerberosトークンを使用したHTTP Gitアクセス（パスワードレス認証） {#http-git-access-with-kerberos-token-passwordless-authentication}

[現在のGitバージョンに存在するバグ](https://lore.kernel.org/git/YKNVop80H8xSTCjz@coredump.intra.peff.net/T/#mab47fd7dcb61fee651f7cc8710b8edc6f62983d5)が原因で、`git`コマンドラインインターフェースコマンドは、HTTPサーバーが`negotiate`認証方法を提供している場合、この方法のみを使用します。たとえ認証が失敗した場合（たとえばクライアントがKerberosトークンを持っていない場合など）でも同様です。したがって、Kerberos認証が失敗した場合、埋め込みのユーザー名とパスワード（`basic`とも呼ばれます）の認証にフォールバックすることはできません。

GitLabユーザーが現在のGitバージョンで`basic`または`negotiate`認証を使用できるようにするには、標準ポートでは`basic`認証のみを提供し、別のポート（たとえば、`8443`）でKerberosチケットベースの認証を提供することができます。

{{< alert type="note" >}}

[Git 2.4以降](https://github.com/git/git/blob/master/Documentation/RelNotes/2.4.0.adoc?plain=1#L225-L228)では、ユーザー名とパスワードがインタラクティブに渡されるか、認証情報マネージャーを介して渡される場合、`basic`認証へのフォールバックがサポートされています。ユーザー名とパスワードがURLの一部として渡される場合は、フォールバックに失敗します。たとえば、[CI/CDジョブトークンで認証する](../ci/jobs/ci_job_token.md)GitLab CI/CDジョブでこの問題が発生することがあります。

{{< /alert >}}

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['kerberos_use_dedicated_port'] = true
   gitlab_rails['kerberos_port'] = 8443
   gitlab_rails['kerberos_https'] = true
   ```

1. 変更を有効にするには、[GitLabを再設定します](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)。

{{< /tab >}}

{{< tab title="HTTPSを使用したセルフコンパイルインストール（ソース）" >}}

1. GitLabのNGINX設定ファイル（たとえば、`/etc/nginx/sites-available/gitlab-ssl`）を編集し、標準のHTTPSポートに加えて、ポート`8443`をリッスンするようにNGINXを設定します:

   ```conf
   server {
     listen 0.0.0.0:443 ssl;
     listen [::]:443 ipv6only=on ssl default_server;
     listen 0.0.0.0:8443 ssl;
     listen [::]:8443 ipv6only=on ssl;
   ```

1. [`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example)の`kerberos`セクションを更新します:

   ```yaml
   kerberos:
     # Dedicated port: Git before 2.4 does not fall back to Basic authentication if Negotiate fails.
     # To support both Basic and Negotiate methods with older versions of Git, configure
     # nginx to proxy GitLab on an extra port (for example: 8443) and uncomment the following lines
     # to dedicate this port to Kerberos authentication. (default: false)
     use_dedicated_port: true
     port: 8443
     https: true
   ```

1. 変更を有効にするには、[GitLabを再起動](../administration/restart_gitlab.md#self-compiled-installations)し、NGINXを再起動します。

{{< /tab >}}

{{< /tabs >}}

この変更後、Kerberosトークンベースの認証を使用するには、GitリモートURLを`https://gitlab.example.com:8443/mygroup/myproject.git`に更新する必要があります。

## パスワードベースからトークンベースのKerberosサインインへのアップグレード {#upgrading-from-password-based-to-ticket-based-kerberos-sign-ins}

以前のバージョンのGitLabでは、ユーザーはサインイン時に自分のKerberosユーザー名とパスワードをGitLabに送信する必要がありました。

GitLab 15.0でパスワードベースのKerberosサインインを[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/2908)しました。

## Active Directory Kerberos環境のサポート {#support-for-active-directory-kerberos-environments}

Active DirectoryドメインでKerberosチケットベースの認証を使用する場合、Kerberosプロトコルの拡張によりHTTP認証ヘッダーがデフォルトサイズの8 kBを超える可能性があるため、NGINXで許可される最大ヘッダーサイズを増やす必要がある場合があります。[NGINX設定](https://nginx.org/en/docs/http/ngx_http_core_module.html#large_client_header_buffers)で`large_client_header_buffers`をより大きな値に設定します。

### Windows ADでAESのみの暗号化を使用して作成されたキータブを使用する {#use-keytabs-created-using-aes-only-encryption-with-windows-ad}

高度暗号化標準（AES）のみの暗号化でキータブを作成する場合は、ADサーバーでそのアカウントの**This account supports Kerberos AES <128/256> bit encryption**チェックボックスをオンにする必要があります。チェックボックスが128ビットか256ビットかは、キータブを作成したときに使用した暗号化強度によって異なります。これを確認するには、Active Directoryサーバーで:

1. **Users and Groups**（ユーザーとグループ）ツールを開きます。
1. キータブの作成に使用したアカウントを見つけます。
1. アカウントを右クリックして、**Properties**（プロパティ）を選択します。
1. **アカウント**タブの**Account Options**（アカウントオプション）で、適切なAES暗号化サポートチェックボックスを選択します。
1. 保存して閉じます。
