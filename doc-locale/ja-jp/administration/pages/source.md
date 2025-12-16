---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: セルフコンパイルインストールにおけるGitLab Pagesの管理
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< alert type="note" >}}

GitLab Pagesを有効にする前に、[GitLabをインストール](../../install/self_compiled/_index.md)が正常に完了していることを確認してください。

{{< /alert >}}

このドキュメントでは、セルフコンパイルインストールされたGitLabにおけるGitLab Pagesの設定方法について説明します。

Linuxパッケージインストール（推奨）におけるGitLab Pagesの設定に関する詳細は、[Linuxパッケージのドキュメント](_index.md)を参照してください。

Linuxパッケージインストールを使用する利点は、サポートされている最新バージョンのGitLab Pagesが含まれていることです。

## GitLab Pagesの仕組み {#how-gitlab-pages-works}

GitLab Pagesは、外部IPアドレスをリッスンし、カスタムドメインと証明書をサポートする軽量HTTPサーバーである[GitLab Pagesデーモン](https://gitlab.com/gitlab-org/gitlab-pages)を利用します。`SNI`を介して動的証明書をサポートし、デフォルトでHTTP2を使用してページを公開します。この仕組みを十分に理解するために、[README](https://gitlab.com/gitlab-org/gitlab-pages/blob/master/README.md)を読むことをおすすめします。

[カスタムドメイン](#custom-domains) （[ワイルドカードドメイン](#wildcard-domains)ではない）の場合、Pagesデーモンは`80`または`443`ポートをリッスンする必要があります。そのため、設定方法にはある程度の柔軟性があります:

- GitLabと同じサーバーでPagesデーモンを実行し、セカンダリIPでリッスンします。
- 別のサーバーでPagesデーモンを実行します。この場合、Pagesデーモンをインストールしたサーバーにも[Pagesのパス](#change-storage-path)が存在する必要があるため、ネットワーク経由で共有する必要があります。
- GitLabと同じサーバーでPagesデーモンを実行し、同じIP上の別のポートでリッスンする。その場合、ロードバランサーによるトラフィックのプロキシ処理が必要になります。このルートを選択する場合、HTTPSではTCPロードバランシングを使用する必要があります。TLS終端（HTTPSロードバランシング）を使用する場合、ユーザーが提供する証明書ではページを配信できません。HTTPの場合、HTTPまたはTCPTCP負荷分散を使用できます。

このドキュメントでは、最初のオプションを前提として説明を進めます。カスタムドメインをサポートしていない場合、セカンダリIPは必要ありません。

## 前提要件 {#prerequisites}

Pagesの設定に進む前に、以下を確認してください:

- GitLab Pagesの提供に使用する別のドメインが必要です。このドキュメントでは、それが`example.io`であると想定しています。
- そのドメインの**wildcard DNS record**（ワイルドカードDNSレコード）を設定している必要があります。
- Pagesのアーティファクトを圧縮および解凍するために必要なため、GitLabがインストールされている同じサーバーに`zip`および`unzip`パッケージがインストールされている必要があります。
- オプション。HTTPSでPagesを提供する場合は、そのドメインの**wildcard certificate**（ワイルドカード証明書）（`*.example.io`）を用意します。
- オプション（推奨）: ユーザーが独自のものを持ち込む必要がないように、[インスタンスRunner](../../ci/runners/_index.md)を設定して有効にしている必要があります。

### DNS設定 {#dns-configuration}

GitLab Pagesは、独自の仮想ホストで実行されることを想定しています。DNSサーバー/プロバイダーで、GitLabを実行しているホストを指す[ワイルドカードDNS `A`レコード](https://en.wikipedia.org/wiki/Wildcard_DNS_record)を追加する必要があります。たとえば、次のようなエントリになります:

```plaintext
*.example.io. 1800 IN A 192.0.2.1
```

`example.io`はGitLab Pagesの提供元ドメイン、`192.0.2.1`はGitLabインスタンスのIPアドレスです。

{{< alert type="note" >}}

GitLabドメインを使用してユーザーページを提供すべきではありません。詳細については、[セキュリティセクション](#security)を参照してください。

{{< /alert >}}

## 設定 {#configuration}

ニーズに応じて、4種類の方法でGitLab Pagesを設定できます。次に、もっとも簡単な設定からもっとも高度な設定へと続く順番で、以下のオプションを示します。絶対に必要な最小限の要件は、すべての設定で必要なワイルドカードDNSをセットアップすることです。

### ワイルドカードドメイン {#wildcard-domains}

前提要件: 

- [ワイルドカードDNSの設定](#dns-configuration)

URLスキーム: `http://<namespace>.example.io/<project_slug>`

このセットアップは、Pagesで使用できる最小限のものです。これは、以下に説明するように、他のすべてのセットアップのベースです。NGINXはすべてのリクエストをデーモンにプロキシします。Pagesデーモンは外部からのリクエストをリッスンしません。

1. Pagesデーモンをインストールします:

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. GitLabインストールディレクトリに移動します:

   ```shell
   cd /home/git/gitlab
   ```

1. `gitlab.yml`を編集し、`pages`設定で、`enabled`を`true`に、`host`をGitLab Pagesの提供元となるFQDNに設定します:

   ```yaml
   ## GitLab Pages
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     # path: shared/pages

     host: example.io
     access_control: false
     port: 8090
     https: false
     artifacts_server: false
     external_http: ["127.0.0.1:8090"]
     secret_file: /home/git/gitlab/gitlab-pages-secret
   ```

1. 次の設定ファイルを`/home/git/gitlab-pages/gitlab-pages.conf`に追加し、`example.io`をGitLab Pagesの提供元となるFQDNに、`gitlab.example.com`をGitLabインスタンスのURLに必ず変更してください:

   ```ini
   listen-http=:8090
   pages-root=/home/git/gitlab/shared/pages
   api-secret-key=/home/git/gitlab/gitlab-pages-secret
   pages-domain=example.io
   internal-gitlab-server=https://gitlab.example.com
   ```

   GitLab PagesとGitLabを同じホストで実行する場合は、`http`アドレスを使用できます。`https`を使用し、自己署名証明書を使用する場合は、カスタム認証局をGitLab Pagesで使用できるようにしてください。たとえば、`SSL_CERT_DIR`環境変数を設定することで、これを行うことができます。

1. シークレットAPIキーを追加します:

   ```shell
   sudo -u git -H openssl rand -base64 32 > /home/git/gitlab/gitlab-pages-secret
   ```

1. pagesデーモンを有効にするには:

   - systemdをinitとして使用している場合は、以下を実行します:

     ```shell
     sudo systemctl edit gitlab.target
     ```

     開いたエディタで、以下を追加してファイルを保存します:

     ```plaintext
     [Unit]
     Wants=gitlab-pages.service
     ```

   - システムでSysV initの代わりにを使用している場合は、`/etc/default/gitlab`を編集し、`gitlab_pages_enabled`を`true`に設定します:

     ```ini
     gitlab_pages_enabled=true
     ```

1. `gitlab-pages` NGINX設定ファイルをコピーします:

   ```shell
   sudo cp lib/support/nginx/gitlab-pages /etc/nginx/sites-available/gitlab-pages.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages.conf
   ```

1. NGINXを再起動します。
1. [GitLab](../restart_gitlab.md#self-compiled-installations)を再起動します。

### TLS対応のワイルドカードドメイン {#wildcard-domains-with-tls-support}

前提要件: 

- [ワイルドカードDNSの設定](#dns-configuration)
- ワイルドカードTLS証明書

URLスキーム: `https://<namespace>.example.io/<project_slug>`

NGINXはすべてのリクエストをデーモンにプロキシします。Pagesデーモンは外部からのリクエストをリッスンしません。

1. Pagesデーモンをインストールします:

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. `gitlab.yml`で、ポートを`443`に、httpsを`true`に設定します:

   ```yaml
   ## GitLab Pages
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     # path: shared/pages

     host: example.io
     port: 443
     https: true
   ```

1. `/etc/default/gitlab`を編集し、`gitlab_pages_enabled`を`true`に設定して、pagesデーモンを有効にします。`gitlab_pages_options`では、`-pages-domain`は以前に設定した`host`値と一致する必要があります。`-root-cert`および`-root-key`設定は、`example.io`ドメインのワイルドカードTLS証明書です:

   ```ini
   gitlab_pages_enabled=true
   gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -root-cert /path/to/example.io.crt -root-key /path/to/example.io.key"
   ```

1. `gitlab-pages-ssl` NGINX設定ファイルをコピーします:

   ```shell
   sudo cp lib/support/nginx/gitlab-pages-ssl /etc/nginx/sites-available/gitlab-pages-ssl.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages-ssl.conf
   ```

1. NGINXを再起動します。
1. [GitLab](../restart_gitlab.md#self-compiled-installations)を再起動します。

## 高度な設定 {#advanced-configuration}

ワイルドカードドメインに加えて、GitLab Pagesがカスタムドメインで動作するように設定することもできます。この場合も、カスタムドメインでTLS証明書を使用する、使用しないの2つのオプションがあります。最も簡単なセットアップは、TLS証明書を使用しない方法です。

### カスタムドメイン {#custom-domains}

前提要件: 

- [ワイルドカードDNSの設定](#dns-configuration)
- セカンダリIP

URLスキーム: `http://<namespace>.example.io/<project_slug>`と`http://custom-domain.com`

その場合、pagesデーモンが実行されています。NGINXは引き続きデーモンにリクエストをプロキシしますが、デーモンは外部からのリクエストも受信できます。カスタムドメインはサポートされていますが、TLSはサポートされていません。

1. Pagesデーモンをインストールします:

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. 以下の例のように`gitlab.yml`を編集します。GitLab Pagesの提供元となるFQDNに`host`を変更する必要があります。pagesデーモンが接続をリッスンするセカンダリIPに`external_http`を設定します:

   ```yaml
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     # path: shared/pages

     host: example.io
     port: 80
     https: false

     external_http: 192.0.2.2:80
   ```

1. デーモンを有効にするには、`/etc/default/gitlab`を編集し、`gitlab_pages_enabled`を`true`に設定します。`gitlab_pages_options`では、`-pages-domain`の値は`host`と一致し、`-listen-http`は`external_http`と一致する必要があります:

   ```ini
   gitlab_pages_enabled=true
   gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -listen-http 192.0.2.2:80"
   ```

1. `gitlab-pages-ssl` NGINX設定ファイルをコピーします:

   ```shell
   sudo cp lib/support/nginx/gitlab-pages /etc/nginx/sites-available/gitlab-pages.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages.conf
   ```

1. `/etc/nginx/site-available/`内のすべてのGitLab関連の設定を編集し、`0.0.0.0`を`192.0.2.1`に置き換えます。ここで、`192.0.2.1`はGitLabがリッスンするプライマリIPです。
1. NGINXを再起動します。
1. [GitLab](../restart_gitlab.md#self-compiled-installations)を再起動します。

### TLS対応のカスタムドメイン {#custom-domains-with-tls-support}

前提要件: 

- [ワイルドカードDNSの設定](#dns-configuration)
- ワイルドカードTLS証明書
- セカンダリIP

URLスキーム: `https://<namespace>.example.io/<project_slug>`と`https://custom-domain.com`

その場合、pagesデーモンが実行されています。NGINXは引き続きデーモンにリクエストをプロキシしますが、デーモンは外部からのリクエストも受信できます。カスタムドメインとTLSをサポートしています。

1. Pagesデーモンをインストールします:

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. 以下の例のように`gitlab.yml`を編集します。GitLab Pagesの提供元となるFQDNに`host`を変更する必要があります。pagesデーモンが接続をリッスンするセカンダリIPに`external_http`と`external_https`を設定します:

   ```yaml
   ## GitLab Pages
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     # path: shared/pages

     host: example.io
     port: 443
     https: true

     external_http: 192.0.2.2:80
     external_https: 192.0.2.2:443
   ```

1. `/etc/default/gitlab`を編集し、`gitlab_pages_enabled`を`true`に設定して、pagesデーモンを有効にします。`gitlab_pages_options`では、`-pages-domain`を`host`、`-listen-http`を`external_http`、`-listen-https`を`external_https`設定と一致させる必要があります。`-root-cert`および`-root-key`設定は、`example.io`ドメインのワイルドカードTLS証明書です:

   ```ini
   gitlab_pages_enabled=true
   gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -listen-http 192.0.2.2:80 -listen-https 192.0.2.2:443 -root-cert /path/to/example.io.crt -root-key /path/to/example.io.key"
   ```

1. `gitlab-pages-ssl` NGINX設定ファイルをコピーします:

   ```shell
   sudo cp lib/support/nginx/gitlab-pages-ssl /etc/nginx/sites-available/gitlab-pages-ssl.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages-ssl.conf
   ```

1. `/etc/nginx/site-available/`内のすべてのGitLab関連の設定を編集し、`0.0.0.0`を`192.0.2.1`に置き換えます。ここで、`192.0.2.1`はGitLabがリッスンするプライマリIPです。
1. NGINXを再起動します。
1. [GitLab](../restart_gitlab.md#self-compiled-installations)を再起動します。

## NGINXの注意事項 {#nginx-caveats}

{{< alert type="note" >}}

以下の情報は、セルフコンパイルインストールにのみ適用されます。

{{< /alert >}}

NGINX設定でドメイン名をセットアップする際は、特に注意してください。バックスラッシュを削除しないでください。

GitLab Pagesドメインが`example.io`の場合は、以下のように置き換えます:

```nginx
server_name ~^.*\.YOUR_GITLAB_PAGES\.DOMAIN$;
```

変更後は次のようになります:

```nginx
server_name ~^.*\.example\.io$;
```

サブドメインを使用している場合は、最初のドットを除くすべてのドット（`.`）をバックスラッシュ（）でエスケープしてください。たとえば、`pages.example.io`は次のようになります:

```nginx
server_name ~^.*\.pages\.example\.io$;
```

## アクセス制御 {#access-control}

GitLab Pagesのアクセス制御はプロジェクトごとに設定できます。Pagesサイトへのアクセス制御は、そのプロジェクトに対するユーザーのメンバーシップに基づいて制御できます。

アクセス制御は、PagesデーモンをGitLabのOAuthアプリケーションとして登録することで機能します。認証されていないユーザーがプライベートPagesサイトにアクセスするリクエストを行うたびに、PagesデーモンはユーザーをGitLabにリダイレクトします。認証に成功すると、ユーザーはトークン付きでPagesにリダイレクトされ、そのトークンはCookieに保持されます。Cookieはシークレットキーで署名されているため、改ざんを検出できます。

プライベートサイトのリソースを表示する各リクエストは、そのトークンを使用してPagesによって認証されます。Pagesは受信したリクエストごとにGitLab APIにリクエストを送り、ユーザーにそのサイトを閲覧する権限があるかどうかを確認します。

Pagesのアクセス制御パラメータは設定ファイルで設定され、慣例により`gitlab-pages-config`という名前が付けられます。この設定ファイルは、`-config flag`または`CONFIG`環境変数を使用してページに渡されます。

Pagesへのアクセス制御はデフォルトで無効になっています。有効にするには、次の手順に従います:

1. `config/gitlab.yml`ファイルを変更します:

   ```yaml
   pages:
     access_control: true
   ```

1. [GitLab](../restart_gitlab.md#self-compiled-installations)を再起動します。
1. 新しい[システムOAuthアプリケーション](../../integration/oauth_provider.md#create-a-user-owned-application)を作成します。これは`GitLab Pages`と呼ばれ、`Redirect URL`は`https://projects.example.io/auth`である必要があります。これは「信頼できる」アプリケーションである必要はありませんが、`api`スコープが必要です。
1. 次の引数を使用して設定ファイルを渡して、Pagesデーモンを起動します:

   ```shell
     auth-client-id=<OAuth Application ID generated by GitLab>
     auth-client-secret=<OAuth code generated by GitLab>
     auth-redirect-uri='http://projects.example.io/auth'
     auth-secret=<40 random hex characters>
     auth-server=<URL of the GitLab instance>
   ```

1. これで、ユーザーは[プロジェクトの設定](../../user/project/pages/pages_access_control.md)からアクセス制御を設定できるようになります。

## ストレージパスを変更する {#change-storage-path}

GitLab Pagesのコンテンツを保存するデフォルトのパスを変更するには、次の手順に従います。

1. ページはデフォルトで`/home/git/gitlab/shared/pages`に保存されます。別の場所に保存する場合は、`gitlab.yml`の`pages`セクションで設定する必要があります:

   ```yaml
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     path: /mnt/storage/pages
   ```

1. [GitLab](../restart_gitlab.md#self-compiled-installations)を再起動します。

## Pagesの最大サイズを設定する {#set-maximum-pages-size}

プロジェクトごとの解凍されたアーカイブの最大サイズのデフォルトは100 MBです。

この値を変更するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **設定**を選択します。
1. **Pages**を展開します。
1. **Maximum size of pages (MB)**（Pagesの最大サイズ（MB））の値を更新します。

## バックアップ {#backup}

ページは[通常のバックアップ](../backup_restore/_index.md)の一部であるため、設定するものはありません。

## セキュリティ {#security}

クロスサイトスクリプティング攻撃を防ぐために、GitLab PagesをGitLabとは異なるホスト名で実行することを強くおすすめします。
