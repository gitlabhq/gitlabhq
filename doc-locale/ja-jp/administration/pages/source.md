---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Pagesのセルフコンパイルインストール管理
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

> [!note] GitLab Pagesを有効にする前に、[GitLabを正常にインストールした](../../install/self_compiled/_index.md)ことを確認してください。

このドキュメントでは、セルフコンパイルインストールのGitLab Pagesを設定する方法を説明します。

Linuxパッケージインストール (推奨) のGitLab Pages設定に関する詳細については、[Linuxパッケージのドキュメント](_index.md)を参照してください。Linuxパッケージインストールには、サポートされている最新のGitLab Pagesのバージョンが含まれています。

## GitLab Pagesの仕組み {#how-gitlab-pages-works}

GitLab Pagesは、外部IPアドレスをリッスンし、カスタムドメインと証明書をサポートする軽量HTTPサーバーであるGitLab Pagesデーモンを使用します。`SNI`を介した動的証明書をサポートし、デフォルトでHTTP2を使用してページを公開します。詳細については、[Readme](https://gitlab.com/gitlab-org/gitlab-pages/blob/master/README.md)を参照してください。

[カスタムドメイン](#custom-domains)の場合、Pagesデーモンは`80`または`443`ポートをリッスンする必要があります。これは[ワイルドカードドメイン](#wildcard-domains)には適用されません。次のいずれかの方法で設定できます:

- GitLabと同じサーバー上のセカンダリIPでリッスンします。
- 別のサーバー上。[Pagesパス](#change-storage-path)もそのサーバーに存在する必要があるため、ネットワーク経由で共有する必要があります。
- GitLabと同じサーバーで、同じIPでも異なるポートでリッスンします。この場合、ロードバランサーによるトラフィックのプロキシ処理が必要になります。HTTPSの場合は、TCP負荷分散を使用します。TLS終端 (HTTPSロードバランシング) を使用する場合、ユーザーが提供する証明書でページを提供することはできません。HTTPの場合、HTTPまたはTCP負荷分散のいずれも許容されます。

以下のセクションでは、最初のオプションを前提としています。カスタムドメインをサポートしていない場合、セカンダリIPは必要ありません。

## 前提条件 {#prerequisites}

Pagesの設定に進む前に、以下を確認してください:

- GitLab Pagesを提供する別のドメインを持っていること。このドキュメントでは、このドメインは`example.io`です。
- そのドメイン用に**wildcard DNS record**を設定していること。
- GitLabがインストールされているのと同じサーバーに`zip`と`unzip`パッケージをインストールしていること。パッケージは、Pagesアーティファクトを圧縮および解凍するために必要です。
- オプション。HTTPSでPagesを提供する場合、Pagesドメイン (`*.example.io`) 用の**wildcard certificate**があること。(オプション)
- オプション（推奨）: オプションですが推奨。[インスタンスRunner](../../ci/runners/_index.md)を設定して有効にしているため、ユーザーは自分で用意する必要がありません。

### DNS設定 {#dns-configuration}

GitLab Pagesは、独自の仮想ホストで実行する必要があります。DNSサーバーまたはプロバイダーで、GitLabが実行されているホストを指す[ワイルドカードDNS `A`レコード](https://en.wikipedia.org/wiki/Wildcard_DNS_record)を追加してください。例: 

```plaintext
*.example.io. 1800 IN A 192.0.2.1
```

ここで、`example.io`はGitLab Pagesが提供されるドメインであり、`192.0.2.1`はGitLabインスタンスのIPアドレスです。

> [!note]ユーザーページを提供するためにGitLabドメインを使用しないでください。詳細については、[セキュリティセクション](#security)を参照してください。

## 設定 {#configuration}

GitLab Pagesはいくつかの方法で設定できます。以下のオプションは、最もシンプルな設定から最も高度な設定まで順に示されています。すべての設定における最小要件は、ワイルドカードDNSレコードです。

### ワイルドカードドメイン {#wildcard-domains}

各サイトは独自のサブドメインを取得します (例: `<namespace>.example.io/<project_slug>`)。このサブドメインにはワイルドカードDNSレコード (`*.example.io`) が必要であり、ほとんどのインスタンスに推奨される設定です。

前提条件: 

- [ワイルドカードDNSの設定](#dns-configuration)

この設定は、Pagesで使用できる最小限の設定です。これは、以下に説明する他のすべての設定の基本となります。NGINXはすべてのリクエストをデーモンにプロキシします。Pagesデーモンは外部をリッスンしません。

1. Pagesデーモンをインストールします:

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. GitLabのインストールディレクトリに移動します:

   ```shell
   cd /home/git/gitlab
   ```

1. `gitlab.yml`を編集し、`pages`設定の下で、`enabled`を`true`に、`host`をGitLab Pagesを提供するFQDNに設定します:

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

1. 以下の設定ファイルを`/home/git/gitlab-pages/gitlab-pages.conf`に追加します。`example.io`をGitLab Pagesを提供するFQDNに、`gitlab.example.com`をGitLabインスタンスのURLに置き換えます:

   ```ini
   listen-http=:8090
   pages-root=/home/git/gitlab/shared/pages
   api-secret-key=/home/git/gitlab/gitlab-pages-secret
   pages-domain=example.io
   internal-gitlab-server=https://gitlab.example.com

   You can use an `http` address when running GitLab Pages and GitLab on the same host. If you use
   `https` with a self-signed certificate, make your custom CA available to GitLab Pages, for
   example by setting the `SSL_CERT_DIR` environment variable.

1. シークレットAPIキーを追加します:

   ```shell
   sudo -u git -H openssl rand -base64 32 > /home/git/gitlab/gitlab-pages-secret
   ```

1. Pagesデーモンを有効にするには:

   - システムがsystemd initを使用している場合は、以下を実行します:

     ```shell
     sudo systemctl edit gitlab.target
     ```

     エディタで以下を追加し、ファイルを保存します:

     ```plaintext
     [Unit]
     Wants=gitlab-pages.service
     ```

   - システムがSysV initを使用している場合は、`/etc/default/gitlab`を編集し、`gitlab_pages_enabled`を`true`に設定します:

     ```ini
     gitlab_pages_enabled=true
     ```

1. `gitlab-pages` NGINX設定ファイルをコピーします:

   ```shell
   sudo cp lib/support/nginx/gitlab-pages /etc/nginx/sites-available/gitlab-pages.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages.conf
   ```

1. NGINXを再起動します。
1. [GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

### TLS対応のワイルドカードドメイン {#wildcard-domains-with-tls-support}

前提条件: 

- [ワイルドカードDNSの設定](#dns-configuration)
- ワイルドカードTLS証明書

URLスキーム: `https://<namespace>.example.io/<project_slug>`

NGINXはすべてのリクエストをデーモンにプロキシします。Pagesデーモンはパブリックインターネットをリッスンしません。

TLSサポート付きワイルドカードドメインを設定するには:

1. Pagesデーモンをインストールします:

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. `gitlab.yml`で、`port`を`443`に、`https`を`true`に設定します:

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

1. `/etc/default/gitlab`を編集し、`gitlab_pages_enabled`を`true`に設定します。`gitlab_pages_options`では、`-pages-domain`は`host`の値と一致する必要があります。`-root-cert`および`-root-key`設定は、`example.io`ドメイン用のワイルドカードTLS証明書です:

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
1. [GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

## 高度な設定 {#advanced-configuration}

ワイルドカードドメインに加えて、GitLab PagesをTLS証明書の有無にかかわらずカスタムドメインで動作するように設定できます。

### カスタムドメイン {#custom-domains}

前提条件: 

- [ワイルドカードDNSの設定](#dns-configuration)
- セカンダリIP

URLスキーム: `http://<namespace>.example.io/<project_slug>`および`http://custom-domain.com`

この設定では、Pagesデーモンが実行され、NGINXがこれにリクエストをプロキシしますが、デーモンはパブリックインターネットからのリクエストも受信できます。カスタムドメインはTLSなしでサポートされます。

カスタムドメインを設定するには:

1. Pagesデーモンをインストールします:

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. `gitlab.yml`を編集します。`host`をGitLab Pagesを提供するFQDNに、`external_http`をPagesデーモンがリッスンするセカンダリIPに設定します:

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

1. `/etc/default/gitlab`を編集し、`gitlab_pages_enabled`を`true`に設定します。`gitlab_pages_options`で次を行います:

   - `-pages-domain`は`host`と一致する必要があります。
   - `-listen-http`は`external_http`と一致する必要があります。
   - `-listen-https`は`external_https`と一致する必要があります。

   ```ini
   gitlab_pages_enabled=true
   gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -listen-http 192.0.2.2:80"
   ```

1. `gitlab-pages` NGINX設定ファイルをコピーします:

   ```shell
   sudo cp lib/support/nginx/gitlab-pages /etc/nginx/sites-available/gitlab-pages.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages.conf
   ```

1. `/etc/nginx/site-available/`内のすべてのGitLab関連の設定を編集し、`0.0.0.0`を`192.0.2.1`に置き換えます。ここで`192.0.2.1`はGitLabがリッスンするプライマリIPです。
1. NGINXを再起動します。
1. [GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

### TLS対応のカスタムドメイン {#custom-domains-with-tls-support}

前提条件: 

- [ワイルドカードDNSの設定](#dns-configuration)
- ワイルドカードTLS証明書
- セカンダリIP

URLスキーム: `https://<namespace>.example.io/<project_slug>`および`https://custom-domain.com`

この設定では、Pagesデーモンが実行され、NGINXがこれにリクエストをプロキシしますが、デーモンはパブリックインターネットからのリクエストも受信できます。カスタムドメインとTLSをサポートしています。

TLSサポート付きカスタムドメインを設定するには:

1. Pagesデーモンをインストールします:

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. `gitlab.yml`を編集します。`host`をGitLab Pagesを提供するFQDNに、`external_http`と`external_https`をPagesデーモンがリッスンするセカンダリIPに設定します:

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

1. `/etc/default/gitlab`を編集し、`gitlab_pages_enabled`を`true`に設定します。`gitlab_pages_options`で次を行います:

   - `-pages-domain`は`host`と一致する必要があります。
   - `-listen-http`は`external_http`と一致する必要があります。
   - `-listen-https`は`external_https`と一致する必要があります。

   `-root-cert`および`-root-key`設定は、`example.io`ドメイン用のワイルドカードTLS証明書です:

   ```ini
   gitlab_pages_enabled=true
   gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -listen-http 192.0.2.2:80 -listen-https 192.0.2.2:443 -root-cert /path/to/example.io.crt -root-key /path/to/example.io.key"
   ```

1. `gitlab-pages-ssl` NGINX設定ファイルをコピーします:

   ```shell
   sudo cp lib/support/nginx/gitlab-pages-ssl /etc/nginx/sites-available/gitlab-pages-ssl.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages-ssl.conf
   ```

1. `/etc/nginx/site-available/`内のすべてのGitLab関連の設定を編集し、`0.0.0.0`を`192.0.2.1`に置き換えます。ここで`192.0.2.1`はGitLabがリッスンするプライマリIPです。
1. NGINXを再起動します。
1. [GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

## NGINXの注意点 {#nginx-caveats}

> [!note]以下の情報はセルフコンパイルインストールにのみ適用されます。

NGINXの設定でドメイン名を設定する際は注意してください。バックスラッシュを削除してはいけません。

GitLab Pagesドメインが`example.io`の場合、以下を置き換えます:

```nginx
server_name ~^.*\.YOUR_GITLAB_PAGES\.DOMAIN$;
```

変更後は次のようになります。

```nginx
server_name ~^.*\.example\.io$;
```

サブドメインを使用している場合、最初のドット (`.`) 以外はすべてバックスラッシュ (`\`) でエスケープしてください。例えば、`pages.example.io`は次のようになります:

```nginx
server_name ~^.*\.pages\.example\.io$;
```

## アクセス制御 {#access-control}

GitLab Pagesのアクセス制御は、プロジェクトごとに設定できます。Pagesサイトへのアクセスは、そのプロジェクトへのユーザーのメンバーシップに基づいて制御できます。

アクセス制御は、PagesデーモンをGitLabのOAuthアプリケーションとして登録することで機能します。認証されていないユーザーがプライベートPagesサイトへのリクエストを行うと、PagesデーモンはそのユーザーをGitLabにリダイレクトします。認証に成功すると、ユーザーはトークン付きでPagesにリダイレクトされ、そのトークンはCookieに保持されます。Cookieはシークレットキーで署名されているため、改ざんを検出できます。

プライベートサイトのリソースを表示する各リクエストは、そのトークンを使用してPagesによって認証されます。Pagesは、受信する各リクエストに対して、GitLab APIにリクエストを行い、ユーザーがそのサイトを読み取りする権限があることを確認します。

Pagesのアクセス制御パラメータは次のとおりです:

- `gitlab-pages-config`という名前の規約によって設定ファイルに設定されます。
- `-config`フラグまたは`CONFIG`環境変数を使用してPagesに渡されます。

Pagesへのアクセス制御はデフォルトで無効になっています。有効にするには、次の手順に従います。

1. `config/gitlab.yml`を修正します:

   ```yaml
   pages:
     access_control: true
   ```

1. [GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。
1. 新しい[システムOAuthアプリケーション](../../integration/oauth_provider.md#create-a-user-owned-application)を作成します。名前を`GitLab Pages`とし、**Redirect URL**を`https://projects.example.io/auth`に設定します。信頼されたアプリケーションである必要はありませんが、`api`スコープが必要です。
1. 以下の引数とともに設定ファイルを渡してPagesデーモンを起動します:

   ```shell
     auth-client-id=<OAuth Application ID generated by GitLab>
     auth-client-secret=<OAuth code generated by GitLab>
     auth-redirect-uri='http://projects.example.io/auth'
     auth-secret=<40 random hex characters>
     auth-server=<URL of the GitLab instance>
   ```

1. ユーザーは、[プロジェクト設定](../../user/project/pages/pages_access_control.md)でこれを設定できるようになりました。

## ストレージパスを変更する {#change-storage-path}

GitLab Pagesのコンテンツが保存されるデフォルトパスを変更するには:

1. ページはデフォルトで`/home/git/gitlab/shared/pages`に保存されます。別の場所を使用するには、`pages`セクションの下にある`gitlab.yml`を編集します:

   ```yaml
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     path: /mnt/storage/pages
   ```

1. [GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

## 最大Pagesサイズを設定 {#set-maximum-pages-size}

プロジェクトごとの解凍されたアーカイブのデフォルトの最大サイズは100 MBです。

前提条件: 

- 管理者アクセス権が必要です。

この値を変更するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **設定**を選択します。
1. **Pages**を展開します。
1. **Maximum size of pages (MB)**の値を更新します。

## バックアップ {#backup}

Pagesは[通常のバックアップ](../backup_restore/_index.md)の一部であるため、設定することはありません。

## セキュリティ {#security}

クロスサイトスクリプティング攻撃を防ぐために、GitLab PagesをGitLabとは異なるホスト名で実行することを強くおすすめします。
