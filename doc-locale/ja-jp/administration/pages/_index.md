---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Pagesの管理
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLab Pagesは、GitLabプロジェクトおよびグループの静的サイトホスティングを提供します。ユーザーがこの機能にアクセスできるようにするには、サーバー管理者がPagesを設定しておく必要があります。GitLab Pagesを使用すると、管理者は次のことができます:

- [カスタムドメイン](#custom-domains)とSSL/TLS証明書を使用して、静的Webサイトを安全にホストします。
- GitLabの権限を通じてPagesサイトへのアクセスを制御するための認証を有効にする。
- マルチノード環境でオブジェクトストレージまたはネットワークストレージを使用して、デプロイをスケールする。
- レート制限とカスタムヘッダーを使用して、トラフィックをモニタリングおよび管理する。
- すべてのPagesサイトでIPv4およびIPv6アドレスをサポートする。

GitLab Pagesデーモンは個別のプロセスとして実行され、GitLabと同じサーバー上または独自の専用インフラストラクチャ上で設定できます。ユーザー向けドキュメントについては、[GitLab Pages](../../user/project/pages/_index.md)を参照してください。

> [!note]このガイドはLinuxパッケージインストール用です。セルフコンパイルインストールの場合は、[GitLab Pagesのセルフコンパイルインストール管理](source.md)を参照してください。

## GitLab Pagesデーモン {#gitlab-pages-daemon}

GitLab Pagesは、[GitLab Pagesデーモン](https://gitlab.com/gitlab-org/gitlab-pages)を使用します。Goで記述された基本的なHTTPサーバーで、外部IPアドレスをリスナーし、[カスタムドメイン](#custom-domains)とカスタム証明書をサポートします。Server Name Indication（SNI）を使用した動的証明書をサポートし、デフォルトでHTTP2を使用してページを公開します。

詳細については、[Readme](https://gitlab.com/gitlab-org/gitlab-pages/blob/master/README.md)を参照してください。

[カスタムドメイン](#custom-domains)で使用する場合、Pagesデーモンはポート`80`または`443`をリスナーする必要があります。これは[ワイルドカードドメイン](#wildcard-domains)には必要ありません。

Pagesデーモンは、以下のように実行できます:

- GitLabと同じサーバーで、セカンダリIPでリスナーします。
- [別のサーバー](#running-gitlab-pages-on-a-separate-server)で。Pages [パス](#change-storage-path)は、Pagesデーモンがインストールされているサーバーにも存在する必要があるため、ネットワーク経由で共有する必要があります。
- GitLabと同じサーバーで、同じIPで異なるポートをリスナーします。この場合、ロードバランサーによるトラフィックのプロキシ処理が必要になります。HTTPSの場合は、TCP負荷分散を使用します。TLS終端（HTTPSロードバランシング）を使用する場合、ページはユーザー提供の証明書で提供できません。HTTPの場合は、HTTPまたはTCP負荷分散のいずれも許容されます。

以下のセクションでは、最初のオプションを前提としています。カスタムドメインをサポートしていない場合、セカンダリIPは必要ありません。

## 前提条件 {#prerequisites}

このセクションでは、GitLab Pagesを設定するための前提条件について説明します。

> [!note] GitLabインスタンスとPagesデーモンがプライベートネットワークまたはファイアウォールの背後にデプロイされている場合、GitLab Pages Webサイトはプライベートネットワークにアクセスできるデバイスとユーザーのみがアクセスできます。

### ワイルドカードドメイン {#wildcard-domains}

各サイトは独自のサブドメインを取得します（例: `<namespace>.example.io/<project_slug>`）。このサブドメインにはDNSワイルドカード（`*.example.io`）が必要であり、ほとんどのインスタンスで推奨される設定です。

ワイルドカードドメインのPagesを設定する前に、次の準備が必要です。

1. GitLabインスタンスドメインのサブドメインではない、Pagesのドメインを用意します。

   | GitLabドメイン        | Pagesドメイン        | 動作可能？ |
   | -------------------- | ------------------- | ------------- |
   | `example.com`        | `example.io`        | {{< icon name="check-circle" >}}はい |
   | `example.com`        | `pages.example.com` | {{< icon name="dotted-circle" >}}いいえ<sup>1</sup> |
   | `gitlab.example.com` | `pages.example.com` | {{< icon name="check-circle" >}}はい |

   **脚注**: 

   1. PagesドメインがGitLabインスタンスドメインのサブドメインである場合、デプロイされたすべてのPagesサイトはGitLabセッションクッキーにアクセスできます。

1. **ワイルドカードDNSレコード**を設定します。
1. （オプション）HTTPSでPagesを提供する場合は、そのドメインの**ワイルドカード証明書**を用意します。
1. オプション（推奨）: ユーザーが独自のインスタンスRunnerを用意する必要がないように、[インスタンスRunner](../../ci/runners/_index.md)を有効にします。
1. カスタムドメインの場合は、**セカンダリIP**を用意します。

### シングルドメインサイト {#single-domain-sites}

すべてのサイトは1つのドメインを共有し、ネームスペースとプロジェクトのslugがパスセグメントになります（例: `example.io/<namespace>/<project_slug>`）。このドメインには、単一のDNS `A`レコードのみが必要です。

シングルドメインサイトのPagesを設定する前に、次の準備が必要です。

1. GitLabインスタンスドメインのサブドメインではない、Pagesのドメインを用意します。

   | GitLabドメイン        | Pagesドメイン        | サポート対象 |
   | -------------------- | ------------------- | ------------- |
   | `example.com`        | `example.io`        | {{< icon name="check-circle" >}}はい |
   | `example.com`        | `pages.example.com` | {{< icon name="dotted-circle" >}}いいえ<sup>1</sup> |
   | `gitlab.example.com` | `pages.example.com` | {{< icon name="check-circle" >}}はい |

   **脚注**: 

   1. PagesドメインがGitLabインスタンスドメインのサブドメインである場合、デプロイされたすべてのPagesサイトはGitLabセッションクッキーにアクセスできます。

1. **DNSレコード**を設定します。
1. （オプション）HTTPSでPagesを提供する場合は、そのドメインの**TLS証明書**を用意します。
1. オプション（推奨）: ユーザーが独自のインスタンスRunnerを用意する必要がないように、[インスタンスRunner](../../ci/runners/_index.md)を有効にします。
1. カスタムドメインの場合は、**セカンダリIP**を用意します。

### Public Suffix Listにドメインを追加する {#add-the-domain-to-the-public-suffix-list}

[Public Suffix List](https://publicsuffix.org)は、サブドメインの処理方法を決定するためにブラウザによって使用されます。GitLabインスタンスが一般ユーザーによるGitLab Pagesサイトの作成を許可している場合、これらのユーザーはページドメイン（`example.io`）上にサブドメインを作成することも許可されます。ドメインをPublic Suffix Listに追加すると、ブラウザが[スーパーCookie](https://en.wikipedia.org/wiki/HTTP_cookie#Supercookie)を受け入れるのを防ぐことができます。

GitLab Pagesのサブドメインを送信するには、[Public Suffix Listへの修正を送信](https://publicsuffix.org/submit/)を参照してください。たとえば、ドメインが`example.io`の場合、`example.io`をPublic Suffix Listに追加するよう申請する必要があります。GitLab.comは、[2016年](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/230)に`gitlab.io`を追加しました。

### DNS設定 {#dns-configuration}

GitLab Pagesは独自の仮想ホストで動作します。DNSサーバーまたはプロバイダーで、GitLabが実行されているホストを指す[DNSワイルドカード`A`レコード](https://en.wikipedia.org/wiki/Wildcard_DNS_record)を追加します。例: 

```plaintext
*.example.io. 1800 IN A    192.0.2.1
*.example.io. 1800 IN AAAA 2001:db8::1
```

ここで、`example.io`はGitLab Pagesを提供するドメイン、`192.0.2.1`はGitLabインスタンスのIPv4アドレス、`2001:db8::1`はIPv6アドレスです。IPv6がない場合は、`AAAA`レコードを省略できます。

#### シングルドメインサイトのDNS設定 {#dns-configuration-for-single-domain-sites}

{{< history >}}

- GitLab 16.7で[実験的機能](../../policy/development_stages_support.md)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/17584)されました。
- GitLab 16.11で[ベータ](../../policy/development_stages_support.md)に[移行](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148621)しました。
- GitLab 17.2で実装がNGINXからGitLab Pagesコードベースに[変更](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/1111)されました。
- GitLab 17.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/483365)になりました。

{{< /history >}}

ワイルドカードDNSを使用せずに、シングルドメインサイトのGitLab Pages DNSを設定するには、次の手順に従います。

1. `/etc/gitlab/gitlab.rb`に`gitlab_pages['namespace_in_path'] = true`を追加して、この機能のGitLab Pagesフラグを有効にします。
1. DNSプロバイダーで、`example.io`のエントリを追加します。`example.io`をドメイン名に、`192.0.0.0`をインスタンスのIPv4アドレスに置き換えます:

   ```plaintext
   example.io          1800 IN A    192.0.0.0
   ```

1. （オプション）GitLabインスタンスにIPv6アドレスがある場合は、そのエントリを追加します。`example.io`をドメイン名に、`2001:db8::1`をインスタンスのIPv6アドレスに置き換えます:

   ```plaintext
   example.io          1800 IN AAAA 2001:db8::1
   ```

   `example.io`は、GitLab Pagesが提供されるドメインです。

#### カスタムドメインのDNS設定 {#dns-configuration-for-custom-domains}

カスタムドメインサポートが必要な場合、Pagesルートドメインのすべてのサブドメインは、Pagesデーモン専用のセカンダリIPを指す必要があります。この設定がないと、ユーザーは`CNAME`レコードを使用して独自の[カスタムドメイン](#custom-domains)をGitLab Pagesにポイントできません。

例: 

```plaintext
example.com   1800 IN A    192.0.2.1
*.example.io. 1800 IN A    192.0.2.2
```

この例には以下が含まれます:

- `example.com`: GitLabドメイン。
- `example.io`: GitLab Pagesを提供するドメイン。
- `192.0.2.1`: GitLabインスタンスのプライマリIP。
- `192.0.2.2`: GitLab Pages専用のセカンダリIP。プライマリIPとは異なる必要があります。

> [!note]ユーザーページを提供するためにGitLabドメインを使用しないでください。詳細については、[セキュリティセクション](#security)を参照してください。

## 設定 {#configuration}

GitLab Pagesはいくつかの方法で設定できます。以下の例は、最もシンプルな設定から最も高度なものまでリストされています。

### ワイルドカードドメイン {#wildcard-domains-1}

この設定は、GitLab Pagesを使用するための最小限の設定であり、他のすべての設定の基盤となります。この設定では、次のようになります。

- NGINXがすべてのリクエストをGitLab Pagesデーモンにプロキシします。
- GitLab Pagesデーモンは、パブリックインターネットに直接リスナーしません。

前提条件: 

- [DNSワイルドカード](#dns-configuration)を設定しました。

ワイルドカードドメインを使用するようにGitLab Pagesを設定するには、次の手順に従います。

1. `/etc/gitlab/gitlab.rb`でGitLab Pagesの外部URLを設定します。

   ```ruby
   external_url "http://example.com" # external_url here is only for reference
   pages_external_url 'http://example.io' # Important: not a subdomain of external_url, so cannot be http://pages.example.com
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

この設定でアクセス可能になるURLスキームは、`http://<namespace>.example.io/<project_slug>`です。

<i class="fa-youtube-play" aria-hidden="true"></i>概要については、[GitLab CEおよびEE向けGitLab Pagesを有効にする](https://youtu.be/dD8c7WNcc6s)ビデオを参照してください。
<!-- Video published on 2017-02-22 -->

### シングルドメインサイト {#single-domain-sites-1}

{{< history >}}

- GitLab 16.7で[実験的機能](../../policy/development_stages_support.md)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/17584)されました。
- GitLab 16.11で[ベータ](../../policy/development_stages_support.md)に[移行](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148621)しました。
- GitLab 17.2で実装がNGINXからGitLab Pagesコードベースに[変更](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/1111)されました。
- GitLab 17.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/483365)になりました。

{{< /history >}}

この設定は、シングルドメインサイトを使用するための最小限の設定であり、他のすべてのシングルドメイン設定の基盤となります。この設定では、次のようになります。

- NGINXがすべてのリクエストをGitLab Pagesデーモンにプロキシします。
- GitLab Pagesデーモンは、パブリックインターネットに直接リスナーしません。

前提条件: 

- [シングルドメインサイト](#dns-configuration-for-single-domain-sites)のDNS設定が完了している。

シングルドメインサイトを使用するようにGitLab Pagesを設定するには、次の手順に従います。

1. `/etc/gitlab/gitlab.rb`で、GitLab Pagesの外部URLを設定し、機能を有効にします。

   ```ruby
   external_url "http://example.com" # Swap out this URL for your own
   pages_external_url 'http://example.io' # Important: not a subdomain of external_url, so cannot be http://pages.example.com

   # Set this flag to enable this feature
   gitlab_pages['namespace_in_path'] = true
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

この設定でアクセス可能になるURLスキームは、`http://example.io/<namespace>/<project_slug>`です。

> [!warning] GitLab Pagesは、ワイルドカードドメインまたはシングルドメインサイトのいずれか、一度に1つのURLスキームのみをサポートします。`namespace_in_path`を有効にすると、既存のGitLab Pagesウェブサイトはシングルドメインサイトとしてのみアクセスできます。

### TLS対応のワイルドカードドメイン {#wildcard-domains-with-tls-support}

NGINXはすべてのリクエストをデーモンにプロキシします。Pagesデーモンは、パブリックインターネットをリスナーしません。

1つのインスタンスにワイルドカードは1つしか割り当てられません。

前提条件: 

- [DNSワイルドカード](#dns-configuration)を設定しました。
- TLS証明書を所有している。ワイルドカード証明書、または[要件](../../user/project/pages/custom_domains_ssl_tls_certification/_index.md#manually-add-ssltls-certificates)を満たすその他の種類の証明書を使用できます。

TLSをサポートするワイルドカードドメインを設定するには:

1. `*.example.io`のワイルドカードTLS証明書とキーを`/etc/gitlab/ssl`内に配置します。
1. `/etc/gitlab/gitlab.rb`で、以下の設定を指定します:

   ```ruby
   external_url "https://example.com" # external_url here is only for reference
   pages_external_url 'https://example.io' # Important: not a subdomain of external_url, so cannot be https://pages.example.com

   pages_nginx['redirect_http_to_https'] = true
   ```

1. 証明書とキーが`example.io.crt`および`example.io.key`という名前でない場合は、完全なパスを追加します:

   ```ruby
   pages_nginx['ssl_certificate'] = "/etc/gitlab/ssl/pages-nginx.crt"
   pages_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/pages-nginx.key"
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
1. [アクセス制御](#access-control)を使用している場合は、GitLab Pages [システムOAuthアプリケーション](../../integration/oauth_provider.md#create-an-instance-wide-application)のURIを更新してHTTPSプロトコルを使用します。

この設定でアクセス可能になるURLスキームは、`https://<namespace>.example.io/<project_slug>`です。

> [!warning]リダイレクトURIが変更されても、GitLab PagesはOAuthアプリケーションを更新しません。再設定する前に、`/etc/gitlab/gitlab-secrets.json`から`gitlab_pages`セクションを削除し、`gitlab-ctl reconfigure`を実行してください。詳細については、[GitLab PagesがOAuthを再生成しない](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3947)を参照してください。

### TLS対応のシングルドメインサイト {#single-domain-sites-with-tls-support}

{{< history >}}

- GitLab 16.7で[実験的機能](../../policy/development_stages_support.md)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/17584)されました。
- GitLab 16.11で[ベータ](../../policy/development_stages_support.md)に[移行](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148621)しました。
- GitLab 17.2で実装がNGINXからGitLab Pagesコードベースに[変更](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/1111)されました。
- GitLab 17.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/483365)になりました。

{{< /history >}}

この設定では、NGINXはすべてのリクエストをデーモンにプロキシします。GitLab Pagesデーモンは、パブリックインターネットに直接リスナーしません。

前提条件: 

- [シングルドメインサイト](#dns-configuration-for-single-domain-sites)のDNS設定が完了している。
- ドメイン（例: `example.io`）をカバーするTLS証明書を所有している。

TLSをサポートするシングルドメインサイトを設定するには:

1. TLS証明書とキーを`/etc/gitlab/ssl`に追加します。
1. `/etc/gitlab/gitlab.rb`で、GitLab Pagesの外部URLを設定し、機能を有効にします:

   ```ruby
   external_url "https://example.com" # Swap out this URL for your own
   pages_external_url 'https://example.io' # Important: not a subdomain of external_url, so cannot be https://pages.example.com

   pages_nginx['redirect_http_to_https'] = true

   # Set this flag to enable this feature
   gitlab_pages['namespace_in_path'] = true
   ```

1. TLS証明書またはキーファイルの名前が`example.io.crt`および`example.io.key`と異なる場合は、完全なパスを追加します:

   ```ruby
   pages_nginx['ssl_certificate'] = "/etc/gitlab/ssl/pages-nginx.crt"
   pages_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/pages-nginx.key"
   ```

1. [アクセス制御](#access-control)を使用している場合は、GitLab Pages [システムOAuthアプリケーション](../../integration/oauth_provider.md#create-an-instance-wide-application)のURIを更新してHTTPSプロトコルを使用します。

   > [!note] GitLab PagesはOAuthアプリケーションを更新せず、デフォルトの`auth_redirect_uri`は`https://example.io/projects/auth`に更新されます。再設定する前に、`/etc/gitlab/gitlab-secrets.json`から`gitlab_pages`セクションを削除し、`gitlab-ctl reconfigure`を実行してください。詳細については、[GitLab PagesがOAuthを再生成しない](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3947)を参照してください。

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

この設定でアクセス可能になるURLスキームは、`https://example.io/<namespace>/<project_slug>`です。

> [!warning] GitLab Pagesは、ワイルドカードドメインまたはシングルドメインサイトのいずれか、一度に1つのURLスキームのみをサポートします。`namespace_in_path`を有効にすると、既存のGitLab Pagesウェブサイトはシングルドメインサイトとしてのみアクセスできます。

### TLS終端ロードバランサーを備えたワイルドカードドメイン {#wildcard-domains-with-tls-terminating-load-balancer}

[Amazon Web ServicesにGitLab POCをインストールする際にこの設定を使用します。](../../install/aws/_index.md)この設定には、TLSを終端する[クラシックロードバランサー](../../install/aws/_index.md#load-balancer)が含まれており、このロードバランサーがHTTPS接続をリッスンして、TLS証明書を管理し、HTTPトラフィックをインスタンスに転送します。

前提条件: 

- [DNSワイルドカード](#dns-configuration)が設定済み。
- TLS終端ロードバランサー。

TLS終端ロードバランサーを使用してワイルドカードドメインを設定するには:

1. `/etc/gitlab/gitlab.rb`で、以下の設定を指定します:

   ```ruby
   external_url "https://example.com" # external_url here is only for reference
   pages_external_url 'https://example.io' # Important: not a subdomain of external_url, so cannot be https://pages.example.com

   pages_nginx['enable'] = true
   pages_nginx['listen_port'] = 80
   pages_nginx['listen_https'] = false
   pages_nginx['redirect_http_to_https'] = true
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

この設定でアクセス可能になるURLスキームは、`https://<namespace>.example.io/<project_slug>`です。

### グローバル設定 {#global-settings}

以下の表では、LinuxパッケージインストールでPagesが認識するすべての設定項目について説明しています。これらのオプションは`/etc/gitlab/gitlab.rb`で調整でき、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)すると有効になります。

これらの設定のほとんどは、Pagesデーモンが環境で読み込み、コンテンツを提供する方法をより詳細に制御する必要がない限り、手動で設定する必要はありません。

| 設定                                 | デフォルト                                               | 説明 |
|-----------------------------------------|-------------------------------------------------------|-------------|
| `pages_external_url` <sup>1</sup>       | 該当なし                                        | GitLab PagesにアクセスできるURL（プロトコル（HTTP/HTTPS）を含む）。`https://`を使用する場合は、追加の設定が必要です。詳細については、[TLSサポート付きワイルドカードドメイン](#wildcard-domains-with-tls-support)および[TLSサポート付きカスタムドメイン](#custom-domains-with-tls-support)を参照してください。 |
| **`gitlab_pages[]`**                    | 該当なし                                        |             |
| `access_control`                        | 該当なし                                        | [アクセス制御](_index.md#access-control)を有効にするかどうか。 |
| `api_secret_key`                        | 自動生成                                        | GitLab APIとの認証に使用するシークレットキーのファイルのフルパス。 |
| `artifacts_server`                      | 該当なし                                        | GitLab Pagesで[ジョブアーティファクト](../cicd/job_artifacts.md)の表示を有効にします。 |
| `artifacts_server_timeout`              | 該当なし                                        | アーティファクトサーバーへのプロキシリクエストのタイムアウト（秒単位）。 |
| `artifacts_server_url`                  | GitLab `external URL` + `/api/v4`                     | アーティファクトのリクエストのプロキシ先となるAPI URL（例: `https://gitlab.com/api/v4`）。個別のPagesサーバーを運用している場合、このURLはメインのGitLabサーバーのAPIを指す必要があります。 |
| `auth_redirect_uri`                     | プロジェクトの`pages_external_url`のサブドメイン+ `/auth` | GitLabとの認証に使用するコールバックURL。URLは`pages_external_url`のサブドメインに`/auth`を付けた形式である必要があります（例: `https://projects.example.io/auth`）。`namespace_in_path`が有効な場合、デフォルトは`pages_external_url`に`/projects/auth`を付けた形式です（例: `https://example.io/projects/auth`）。 |
| `auth_secret`                           | GitLabから自動的にプル                               | 認証リクエストに署名するためのシークレットキー。OAuth登録時にGitLabから自動的にプルするには、空白のままにします。 |
| `client_cert`                           | 該当なし                                        | GitLab APIとの[相互TLS](#support-mutual-tls-when-calling-the-gitlab-api)に使用するクライアント証明書。 |
| `client_key`                            | 該当なし                                        | GitLab APIとの[相互TLS](#support-mutual-tls-when-calling-the-gitlab-api)に使用するクライアントキー。 |
| `client_ca_certs`                       | 該当なし                                        | GitLab APIとの[相互TLS](#support-mutual-tls-when-calling-the-gitlab-api)に使用するクライアント証明書の署名に使用するルートCA証明書。 |
| `dir`                                   | 該当なし                                        | 設定ファイルおよびシークレットファイルの作業ディレクトリ。 |
| `enable`                                | 該当なし                                        | 現在のシステムでGitLab Pagesを有効または無効にします。 |
| `external_http`                         | 該当なし                                        | HTTPリクエストを処理するため、1つ以上のセカンダリIPアドレスにバインドするようにPagesを設定します。複数のアドレスは配列として指定でき、ポートを明示的に含めることもできます（例: `['1.2.3.4', '1.2.3.5:8063']`）。`listen_http`の値を設定します。TLS終端を行うリバースプロキシの背後でGitLab Pagesを実行している場合は、`external_http`の代わりに`listen_proxy`を指定します。 |
| `external_https`                        | 該当なし                                        | HTTPSリクエストを処理するため、1つ以上のセカンダリIPアドレスにバインドするようにPagesを設定します。複数のアドレスは配列として指定でき、ポートを明示的に含めることもできます（例: `['1.2.3.4', '1.2.3.5:8063']`）。`listen_https`の値を設定します。 |
| `custom_domain_mode`                    | 該当なし                                        | カスタムドメインを有効にするようにPagesを設定します（`http`または`https`）。個別のPagesサーバーを運用している場合は、GitLabサーバーでもこのように設定してください。GitLab 18.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/285089)されました。 |
| `server_shutdown_timeout`               | `30s`                                                 | GitLab Pagesサーバーのシャットダウンタイムアウト（秒単位）。 |
| `gitlab_client_http_timeout`            | `60s`                                                 | GitLab API HTTPクライアント接続タイムアウト（秒単位）。 |
| `gitlab_client_jwt_expiry`              | `30s`                                                 | JWTトークンの有効期限（秒単位）。 |
| `gitlab_cache_expiry`                   | `600s`                                                | ドメインの設定が[キャッシュ](#gitlab-api-cache-configuration)に保存される最大時間。 |
| `gitlab_cache_refresh`                  | `60s`                                                 | ドメインの設定が更新対象とされる間隔。 |
| `gitlab_cache_cleanup`                  | `60s`                                                 | 期限切れのアイテムを[キャッシュ](#gitlab-api-cache-configuration)から削除する間隔。 |
| `gitlab_retrieval_timeout`              | `30s`                                                 | 1リクエストあたりで、GitLab APIからの応答を待機する最大時間。 |
| `gitlab_retrieval_interval`             | `1s`                                                  | GitLab APIを使用してドメインの設定を解決する際、再試行までに待機する間隔。 |
| `gitlab_retrieval_retries`              | `3`                                                   | GitLab APIを使用してドメインの設定を解決する際、再試行する最大回数。 |
| `gitlab_id`                             | 自動入力                                           | OAuthアプリケーションの公開ID。空白のままにすると、PagesがGitLabで認証する際に自動的に入力されます。 |
| `gitlab_secret`                         | 自動入力                                           | OAuthアプリケーションのシークレット。空白のままにすると、PagesがGitLabで認証する際に自動的に入力されます。 |
| `auth_scope`                            | `api`                                                 | 認証に使用するOAuthアプリケーションのスコープ。GitLab PagesのOAuthアプリケーション設定と一致している必要があります。空白のままにすると、デフォルトで`api`スコープが使用されます。 |
| `auth_timeout`                          | `5s`                                                  | 認証のためのGitLabアプリケーションクライアントのタイムアウト（秒単位）。`0`を指定すると、タイムアウトは無効になります。 |
| `auth_cookie_session_timeout`           | `10m`                                                 | 認証用Cookieのセッションタイムアウト（秒単位。）。`0`を指定すると、ブラウザセッションの終了後にCookieが削除されます。 |
| `gitlab_server`                         | GitLab `external_url`                                 | アクセス制御が有効な場合に認証に使用するサーバー。 |
| `headers`                               | 該当なし                                        | 各応答とともにクライアントに送信する必要がある追加のHTTPヘッダーを指定します。複数のヘッダーを配列として指定でき、ヘッダーと値は1つの文字列として記述します。例: `['my-header: myvalue', 'my-other-header: my-other-value']`。 |
| `enable_disk`                           | 該当なし                                        | GitLab Pagesデーモンがディスクからコンテンツを配信できるようにします。共有ディスクストレージが利用できない場合は無効にします。 |
| `insecure_ciphers`                      | 該当なし                                        | 3DESやRC4のような脆弱な暗号スイートを含む可能性がある、デフォルトの暗号スイートリストを使用します。 |
| `internal_gitlab_server`                | GitLab `external_url`                                 | APIリクエスト専用に使用する内部GitLabサーバーアドレス。そのトラフィックを内部ロードバランサー経由で送信したい場合に使用します。 |
| `listen_proxy`                          | 該当なし                                        | リバースプロキシリクエストをリッスンするアドレス。Pagesはこれらのアドレスのネットワークソケットにバインドし、そこから受信リクエストを受け取ります。`$nginx-dir/conf/gitlab-pages.conf`の`proxy_pass`の値を設定します。 |
| `log_directory`                         | 該当なし                                        | ログディレクトリへの絶対パス。 |
| `log_format`                            | 該当なし                                        | ログ出力形式: `text`または`json`。 |
| `log_verbose`                           | 該当なし                                        | 冗長なログの生成。true/false。 |
| `namespace_in_path`                     | `false`                                               | シングルドメインサイトのDNS設定をサポートするため、URLパスでのネームスペースを有効または無効にします。 |
| `propagate_correlation_id`              | `false`                                               | 受信リクエストヘッダー`X-Request-ID`に既存の相関IDが存在する場合、それを再利用するには、trueに設定します。リバースプロキシがこのヘッダーを設定している場合、その値はリクエストチェーン全体に伝播されます。 |
| `max_connections`                       | 該当なし                                        | HTTP、HTTPS、プロキシリスナーへの同時接続数の制限。 |
| `max_uri_length`                        | `2048`                                                | GitLab Pagesで受け付けるURIの最大長。無制限にするには、0に設定します。 |
| `metrics_address`                       | 該当なし                                        | メトリクスのリクエストをリッスンするアドレス。 |
| `redirect_http`                         | 該当なし                                        | HTTPからHTTPSにページをリダイレクトします。true/false。 |
| `redirects_max_config_size`             | `65536`                                               | `_redirects`ファイルの最大サイズ（バイト単）。 |
| `redirects_max_path_segments`           | `25`                                                  | `_redirects`ルールのURLで許可されるパスセグメントの最大数。 |
| `redirects_max_rule_count`              | `1000`                                                | `_redirects`で設定可能なルールの最大数。 |
| `sentry_dsn`                            | 該当なし                                        | Sentryクラッシュレポートの送信先アドレス。 |
| `sentry_enabled`                        | 該当なし                                        | Sentryによるレポートとログの生成を有効にします。true/false。 |
| `sentry_environment`                    | 該当なし                                        | Sentryクラッシュレポートの環境。 |
| `status_uri`                            | 該当なし                                        | ステータスページのURLパス（例: `/@status`）。GitLab Pagesでヘルスチェックエンドポイントを有効にするには、この項目を設定します。 |
| `tls_max_version`                       | 該当なし                                        | 最大のTLSバージョン（「tls1.2」または「tls1.3」）を指定します。 |
| `tls_min_version`                       | 該当なし                                        | 最小のTLSバージョン（「tls1.2」または「tls1.3」）を指定します。 |
| `use_http2`                             | 該当なし                                        | HTTP2のサポートを有効にします。 |
| **`gitlab_pages['env'][]`**             | 該当なし                                        |             |
| `http_proxy`                            | 該当なし                                        | GitLab PagesとGitLab間のトラフィックを仲介するためにHTTPプロキシを使用するようにGitLab Pagesを設定します。Pagesデーモンの起動時に環境変数`http_proxy`を設定します。 |
| **`gitlab_rails[]`**                    | 該当なし                                        |             |
| `pages_domain_verification_cron_worker` | 該当なし                                        | カスタムGitLab Pagesドメインを検証するためのスケジュール。 |
| `pages_domain_ssl_renewal_cron_worker`  | 該当なし                                        | GitLab Pagesドメインに対してLet's Encryptを介してSSL証明書を取得および更新するためのスケジュール。 |
| `pages_domain_removal_cron_worker`      | 該当なし                                        | 未検証のカスタムGitLab Pagesドメインを削除するスケジュール。 |
| `pages_path`                            | `GITLAB-RAILS/shared/pages`                           | ページの保存先となるディスク上のディレクトリ。 |
| **`pages_nginx[]`**                     | 該当なし                                        |             |
| `enable`                                | 該当なし                                        | NGINX内にPagesの仮想ホスト`server{}`ブロックを含めます。NGINXがトラフィックをPagesデーモンにプロキシするために必要です。たとえば[カスタムドメイン](_index.md#custom-domains)を使用して、Pagesデーモンがすべてのリクエストを直接受け取る場合は`false`に設定します。 |
| `FF_CONFIGURABLE_ROOT_DIR`              | 該当なし                                        | [デフォルトフォルダーをカスタマイズ](../../user/project/pages/introduction.md#customize-the-default-folder)するための機能フラグ（デフォルトで有効）。 |
| `FF_ENABLE_PLACEHOLDERS`                | 該当なし                                        | 書き換え用の機能フラグ（デフォルトで有効）。詳細については、[リライト](../../user/project/pages/redirects.md#rewrites)を参照してください。 |
| `rate_limit_source_ip`                  | 該当なし                                        | 送信元IPごとのレート制限（1秒あたりのリクエスト数）。この機能を無効にするには、`0`に設定します。 |
| `rate_limit_source_ip_burst`            | 該当なし                                        | 送信元IPごとのレート制限（秒あたりに許容される最大バースト）。 |
| `rate_limit_domain`                     | 該当なし                                        | ドメインごとのレート制限（1秒あたりのリクエスト数）。この機能を無効にするには、`0`に設定します。 |
| `rate_limit_domain_burst`               | 該当なし                                        | ドメインごとのレート制限（秒あたりに許容される最大バースト）。 |
| `rate_limit_tls_source_ip`              | 該当なし                                        | 送信元IPごとのレート制限（秒あたりのTLS接続数）。この機能を無効にするには、`0`に設定します。 |
| `rate_limit_tls_source_ip_burst`        | 該当なし                                        | 送信元IPごとのレート制限（TLS接続に対して1秒あたりに許容される最大バースト）。 |
| `rate_limit_tls_domain`                 | 該当なし                                        | ドメインごとのレート制限（1秒あたりのTLS接続数）。この機能を無効にするには、`0`に設定します。 |
| `rate_limit_tls_domain_burst`           | 該当なし                                        | ドメインごとのレート制限（TLS接続に対して1秒あたりに許容される最大バースト）。 |
| `rate_limit_subnets_allow_list`         | 該当なし                                        | すべてのレート制限を回避する必要があるIP範囲（サブネット）の許可リスト。例: `['1.2.3.4/24', '2001:db8::1/32']`。GitLab 17.3で[導入](https://gitlab.com/groups/gitlab-org/-/epics/14653)されました。 |
| `server_read_timeout`                   | `5s`                                                  | リクエストヘッダーと本文の読み取りに許可される最大時間。タイムアウトなしにするには、`0`または負の値に設定します。 |
| `server_read_header_timeout`            | `1s`                                                  | リクエストヘッダーの読み取りに許可される最大時間。タイムアウトなしにするには、`0`または負の値に設定します。 |
| `server_write_timeout`                  | `0`                                                   | 応答に含まれるすべてのファイルを書き込むために許可される最大時間。ファイルが大きいほど、より長い時間が必要です。タイムアウトなしにするには、`0`または負の値に設定します。 |
| `server_keep_alive`                     | `15s`                                                 | このリスナーが受け付けたネットワーク接続の`Keep-Alive`の持続時間。`0`に設定すると、プロトコルとオペレーティングシステムがサポートしている場合に限り`Keep-Alive`が有効になります。負の値に設定すると、`Keep-Alive`は無効になります。 |

**脚注**: 

1. 外部Sidekiqノードを使用する場合、`pages_external_url`を設定に追加する必要があります。この設定がないと、外部Sidekiqノードはデプロイジョブを処理できません。

## 高度な設定 {#advanced-configuration}

ワイルドカードドメインに加えて、TLS証明書の有無にかかわらず、カスタムドメインで機能するようにGitLab Pagesを設定できます。いずれの場合も、**セカンダリIP**が必要になります。IPv6アドレスとIPv4アドレスの両方がある場合、両方を使用できます。

### カスタムドメイン {#custom-domains}

デフォルトでは、GitLab PagesサイトはPagesルートドメインのサブドメインで提供されます（例: `namespace.example.io/project`）。Pagesサイトのカスタムドメインを設定するには、独自のドメイン（例: `example-custom-site-here.com`）をGitLab PagesにポイントするCNAME DNSレコードを追加します。

デフォルトの`*.example.io`サブドメインURLのみが必要な場合、カスタムドメインサポートを設定する必要はありません。

この設定では、Pagesデーモンが実行されており、NGINXがリクエストをプロキシしますが、デーモンはパブリックインターネットからもリクエストを受け取ることができます。カスタムドメインはTLSなしでサポートされます。

前提条件: 

- [DNSワイルドカード](#dns-configuration)が設定済み。
- セカンダリIP。

カスタムドメインを設定するには:

1. `/etc/gitlab/gitlab.rb`で、以下の設定を指定します:

   ```ruby
   external_url "http://example.com" # external_url here is only for reference
   pages_external_url 'http://example.io' # Important: not a subdomain of external_url, so cannot be http://pages.example.com
   nginx['listen_addresses'] = ['192.0.2.1'] # The primary IP of the GitLab instance
   pages_nginx['enable'] = false
   gitlab_pages['external_http'] = ['192.0.2.2:80', '[2001:db8::2]:80'] # The secondary IPs for the GitLab Pages daemon
   gitlab_pages['custom_domain_mode'] = 'http' # Enable custom domain
   ```

   IPv6がない場合は、IPv6アドレスを省略します。

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

この設定でアクセス可能になるURLスキームは、`http://<namespace>.example.io/<project_slug>`および`http://custom-domain.com`です。

### TLS対応のカスタムドメイン {#custom-domains-with-tls-support}

この設定では、Pagesデーモンが実行されており、NGINXがリクエストをプロキシしますが、デーモンはパブリックインターネットからもリクエストを受け取ることができます。カスタムドメインとTLSをサポートしています。

前提条件: 

- [DNSワイルドカード](#dns-configuration)が設定済み。
- TLS証明書。ワイルドカード証明書、または[要件](../../user/project/pages/custom_domains_ssl_tls_certification/_index.md#manually-add-ssltls-certificates)を満たすその他の種類の証明書を使用できます。
- セカンダリIP。

TLSをサポートするカスタムドメインを設定するには:

1. `*.example.io`のワイルドカードTLS証明書とキーを`/etc/gitlab/ssl`内に配置します。
1. `/etc/gitlab/gitlab.rb`で、以下の設定を指定します:

   ```ruby
   external_url "https://example.com" # external_url here is only for reference
   pages_external_url 'https://example.io' # Important: not a subdomain of external_url, so cannot be https://pages.example.com
   nginx['listen_addresses'] = ['192.0.2.1'] # The primary IP of the GitLab instance
   pages_nginx['enable'] = false
   gitlab_pages['external_http'] = ['192.0.2.2:80', '[2001:db8::2]:80'] # The secondary IPs for the GitLab Pages daemon
   gitlab_pages['external_https'] = ['192.0.2.2:443', '[2001:db8::2]:443'] # The secondary IPs for the GitLab Pages daemon
   gitlab_pages['custom_domain_mode'] = 'https' # Enable custom domain
   # Redirect pages from HTTP to HTTPS
   gitlab_pages['redirect_http'] = true
   ```

   IPv6がない場合は、IPv6アドレスを省略します。

1. 証明書とキーが`example.io.crt`および`example.io.key`という名前でない場合は、完全なパスを追加します:

   ```ruby
   gitlab_pages['cert'] = "/etc/gitlab/ssl/example.io.crt"
   gitlab_pages['cert_key'] = "/etc/gitlab/ssl/example.io.key"
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
1. アクセス制御を使用している場合は、GitLab Pages [システムOAuthアプリケーション](../../integration/oauth_provider.md#create-an-instance-wide-application)のURIを編集してHTTPSプロトコルを使用します。

### カスタムドメインの検証 {#custom-domain-verification}

悪意のあるユーザーが所有していないドメインをハイジャックするのを防ぐために、GitLabは[カスタムドメイン認証](../../user/project/pages/custom_domains_ssl_tls_certification/_index.md)をサポートしています。カスタムドメインを追加する際、ユーザーはそのドメインのDNSレコードにGitLabが制御する認証codeコードを追加することで、その所有権を証明する必要があります。

> [!warning]ドメイン認証を無効にすることは脆弱なことであり、様々な脆弱性につながる可能性があります。無効にする場合、Pagesルートドメイン自体がセカンダリIPを指していないこと、またはルートドメインをプロジェクトのカスタムドメインとして追加することを確認してください。そうしないと、任意のユーザーがこのドメインを自身のプロジェクトのカスタムドメインとして追加できます。

ユーザーベースがプライベートであるか、または信頼できる場合は、検証要件を無効にできます。

1. 右上隅で、**管理者**を選択します。
1. **設定** > **設定**を選択します。
1. **Pages**を展開します。
1. **ユーザーにカスタムドメインの所有権を証明することを要求する**チェックボックスをオフにします。この設定はデフォルトで有効になっています。

### Let's Encryptのインテグレーション {#lets-encrypt-integration}

[GitLab PagesのLet's Encryptのインテグレーション](../../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md)を使用すると、カスタムドメインで提供されるGitLab PagesサイトにLet's Encrypt SSL証明書を追加できます。

有効にするには、次の手順に従います。

1. ドメインの有効期限切れに関する通知を受け取るメールアドレスを選択します。
1. 右上隅で、**管理者**を選択します。
1. **設定** > **設定**を選択します。
1. **Pages**を展開します。
1. 通知を受信するメールアドレスを入力し、Let's Encryptの利用規約に同意します。
1. **変更を保存**を選択します。

### アクセス制御 {#access-control}

GitLab Pagesへのアクセス制御はプロジェクトごとに設定でき、そのプロジェクトに対するユーザーのメンバーシップに基づいてPagesサイトへのアクセスを制御できます。

アクセス制御は、PagesデーモンをGitLabのOAuthアプリケーションとして登録することで機能します。未認証済みユーザーがプライベートPagesサイトへのアクセスをリクエストするたびに、PagesデーモンはユーザーをGitLabにリダイレクトします。認証に成功すると、ユーザーはトークン付きでPagesにリダイレクトされ、そのトークンはCookieに保持されます。Cookieはシークレットキーで署名されているため、改ざんを検出できます。

プライベートサイトのリソースを表示する各リクエストは、そのトークンを使用してPagesによって認証されます。受信した各リクエストに対して、PagesはGitLab APIにリクエストを行い、ユーザーがそのサイトを読み取りする権限があるかどうかを確認します。

Pagesへのアクセス制御はデフォルトで無効になっています。有効にするには、次の手順に従います。

1. `/etc/gitlab/gitlab.rb`に、以下を追加します:

   ```ruby
   gitlab_pages['access_control'] = true
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
1. これで、ユーザーは[プロジェクトの設定](../../user/project/pages/pages_access_control.md)からアクセス制御を設定できるようになります。

> [!note]この設定がマルチノード設定で有効になるためには、すべてのAppノードとSidekiqノードに適用します。

#### 認証スコープを制限してPagesを使用する {#using-pages-with-reduced-authentication-scope}

Pagesデーモンが認証するために使用するスコープを設定できます。デフォルトでは、Pagesデーモンは`api`スコープを使用します。

たとえば、`/etc/gitlab/gitlab.rb`でスコープを`read_api`に制限するには、次のように設定します。

```ruby
gitlab_pages['auth_scope'] = 'read_api'
```

認証に使用するスコープは、GitLab PagesのOAuthアプリケーション設定と一致している必要があります。既存のアプリケーションのユーザーは、GitLab PagesのOAuthアプリケーションを変更する必要があります。

前提条件: 

- [アクセス制御](#access-control)を有効にしました。

Pagesが使用するスコープを変更するには、次の手順に従います。

1. 右上隅で、**管理者**を選択します。
1. **アプリケーション**を選択します。
1. **GitLab Pages**を展開します。
1. `api`スコープのチェックボックスをオフにして、必要なスコープのチェックボックス（`read_api`など）をオンにします。
1. **変更を保存**を選択します。

#### すべてのPagesサイトへの公開アクセスを無効にする {#disable-public-access-to-all-pages-sites}

独自のGitLabインスタンスでホストされているすべてのGitLab Pages Webサイトに対してアクセス制御を強制できます。この設定を有効にすると、認証済みユーザーのみがPages Webサイトにアクセスできます。すべてのプロジェクトは**全員**の表示レベルオプションを失い、プロジェクトの表示レベル設定に応じて、プロジェクトメンバーまたはアクセス権を持つ全員に制限されます。

この設定を使用して、Pagesで公開される情報をインスタンスのユーザーのみに制限します。

前提条件: 

- インスタンスへの管理者アクセス権。
- 設定が管理者エリアに表示されるようにアクセス制御が有効になっています。

すべてのPagesサイトへの公開アクセスを無効にするには、次の手順に従います。

1. 右上隅で、**管理者**を選択します。
1. **設定** > **設定**を選択します。
1. **Pages**を展開します。
1. **Pagesサイトへの公開アクセスを無効にする**チェックボックスをオンにします。
1. **変更を保存**を選択します。

#### デフォルトで一意のドメインを無効にする {#disable-unique-domains-by-default}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/555559)されました。

{{< /history >}}

デフォルトでは、新しく作成されたすべてのGitLab Pagesサイトは、一意のドメインURL（例: `my-project-1a2b3c.example.com`）を使用します。これにより、同じネームスペース内の異なるサイト間でCookieが共有されなくなります。

このデフォルトの動作を無効にすると、新しいPagesサイトがパスベースのURL（例: `my-namespace.example.com/my-project`）を使用するようになります。ただし、このアプローチには、同じネームスペース内の異なるサイト間でCookieが共有されるリスクがあります。

この設定が制御するのは、新しいサイトのデフォルト動作だけです。ユーザーは、個々のプロジェクトでこの設定をオーバーライドできます。

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

デフォルトで一意のドメインを無効にするには、次の手順に従います。

1. 右上隅で、**管理者**を選択します。
1. **設定** > **設定**を選択します。
1. **Pages**を展開します。
1. **デフォルトで一意のドメインを有効にする**チェックボックスをオフにします。
1. **変更を保存**を選択します。

この設定は、新しいPagesサイトにのみ影響します。既存のサイトは、現在の一意のドメイン設定を保持します。

### プロキシの背後で実行する {#running-behind-a-proxy}

外部インターネット接続がプロキシによってゲートされている環境でGitLab Pagesを使用できます。

GitLab Pagesにプロキシを使用するには、次の手順に従います。

1. `/etc/gitlab/gitlab.rb`に、以下を追加します:

   ```ruby
   gitlab_pages['env']['http_proxy'] = 'http://example:8080'
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

### カスタム認証局（CA）を使用する {#using-a-custom-certificate-authority-ca}

カスタムCAによって発行された証明書を使用する場合、そのカスタムCAが認識されないと、アクセス制御や[HTMLジョブアーティファクトのオンライン表示](../../ci/jobs/job_artifacts.md#download-job-artifacts)が機能しません。

その場合は通常、次のようなエラーが表示されます。

```plaintext
Post /oauth/token: x509: certificate signed by unknown authority
```

これを解決するには、次の手順に従います:

- Linuxパッケージインストールの場合、[カスタムCAをインストール](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates)します。
- セルフコンパイルインストールの場合、システム証明書ストアにカスタムCAをインストールします。

### GitLab APIの呼び出し時に相互TLSをサポートする {#support-mutual-tls-when-calling-the-gitlab-api}

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/548)されました。

{{< /history >}}

GitLabの[設定で相互TLSを必須にしている](https://docs.gitlab.com/omnibus/settings/ssl/#enable-2-way-ssl-client-authentication)場合は、GitLab Pagesの設定にクライアント証明書を追加する必要があります。

証明書には次の要件があります。

- 証明書には、ホスト名またはIPアドレスがSubject Alternative Name（サブジェクトの別名）として指定されている必要があります。
- エンドユーザー証明書、中間証明書、ルート証明書をこの順序で含む完全な証明書チェーンが必要です。

証明書の共通名フィールドは無視されます。

前提条件: 

- あなたのインスタンスはLinuxパッケージインストール方法を使用します。

GitLab Pagesサーバーで証明書を設定するには、次の手順に従います。

1. GitLab Pagesノードで、`/etc/gitlab/ssl`ディレクトリを作成し、キーと完全な証明書チェーンをそこにコピーします。

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp key.pem cert.pem /etc/gitlab/ssl/
   sudo chmod 644 key.pem cert.pem
   ```

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_pages['client_cert'] = ['/etc/gitlab/ssl/cert.pem']
   gitlab_pages['client_key'] = ['/etc/gitlab/ssl/key.pem']
   ```

1. カスタムCAを使用した場合、ルートCA証明書を`/etc/gitlab/ssl`にコピーし、`/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_pages['client_ca_certs'] = ['/etc/gitlab/ssl/ca.pem']
   ```

   複数のカスタム認証局のファイルパスはコンマで区切られます。

1. マルチノードのGitLab Pagesインストールがある場合、これらのステップをすべてのノードで繰り返します。
1. 完全な証明書チェーンファイルをすべてのGitLabノードの`/etc/gitlab/trusted-certs`ディレクトリに保存します。

### ZIP配信とキャッシュ設定 {#zip-serving-and-cache-configuration}

> [!warning]推奨されるデフォルト値は、GitLab Pages内で設定されています。これらの設定は、絶対に必要な場合にのみ変更してください。

GitLab Pagesは、オブジェクトストレージを通じてZIPアーカイブのコンテンツを配信できます。ZIPアーカイブからコンテンツを配信する際のパフォーマンスを向上させるため、インメモリキャッシュを使用しています。次の設定フラグを変更することで、このキャッシュの動作を変更できます。

| 設定 | 説明 |
| ------- | ----------- |
| `zip_cache_expiration` | ZIPアーカイブのキャッシュ有効期限の間隔。古いコンテンツの配信を避けるため、ゼロより大きい値を指定する必要があります。デフォルトは`60s`です。 |
| `zip_cache_cleanup` | アーカイブが有効期限切れになった後、メモリからクリーンアップされる間隔。デフォルトは`30s`です。 |
| `zip_cache_refresh` | `zip_cache_expiration`の期限内にアクセスがあった場合、メモリ内でそのアーカイブを延長する時間間隔。`zip_cache_expiration`と連携して、アーカイブがメモリ内で拡張されるかどうかを決定します。詳細については、[ZIPキャッシュ更新の例](#zip-cache-refresh-example)を参照してください。デフォルトは`30s`です。 |
| `zip_open_timeout` | ZIPアーカイブを開くことができる最大時間。大規模なアーカイブまたは低速なネットワーク接続の場合、この値を増やしてください。デフォルトは`30s`です。 |
| `zip_http_client_timeout` | ZIP HTTPクライアントの最大タイムアウト時間。デフォルトは`30m`です。 |

#### ZIPキャッシュの更新例 {#zip-cache-refresh-example}

アーカイブは、`zip_cache_expiration`の有効期限内にアクセスされ、有効期限が切れるまでの残り時間が`zip_cache_refresh`以下の場合、キャッシュ内で更新（メモリ内での保持時間が延長）されます。たとえば、`0s`の時点で`archive.zip`にアクセスされた場合、有効期限は`60s`（`zip_cache_expiration`のデフォルト）になります。アーカイブが`15s`後に再度開かれた場合、有効期限までの残り時間（`45s`）が`zip_cache_refresh`（デフォルト`30s`）よりも長いため、更新されません。ただし、アーカイブが`45s`後に再度アクセスされた場合（最初に開かれた時点から）、更新されます。これにより、メモリ内でのアーカイブの保持時間が`45s + zip_cache_expiration
(60s)`に延長され、合計で`105s`になります。

アーカイブが`zip_cache_expiration`に達すると、期限切れとマークされ、次回の`zip_cache_cleanup`の間隔が経過するとメモリから削除されます。

![ZIPキャッシュの更新によってZIPキャッシュの有効期限が延長されることを示すタイムライン。](img/zip_cache_configuration_v13_7.png)

### HTTP Strict Transport Security（HSTS）のサポート {#http-strict-transport-security-hsts-support}

HTTP Strict Transport Security（HSTS）は、`gitlab_pages['headers']`設定オプションを使用して有効にできます。HSTSは、Webサイトが常にHTTPS経由でアクセスされるべきであることをブラウザに通知し、攻撃者が暗号化されていない接続を強制するのを防ぎます。また、ブラウザがHTTPSにリダイレクトされる前に暗号化されていないHTTP接続を試みるのを防ぐことで、ページ読み込み速度を向上させることもできます。

```ruby
gitlab_pages['headers'] = ['Strict-Transport-Security: max-age=63072000']
```

### Pagesプロジェクトのリダイレクト制限 {#pages-project-redirect-limits}

GitLab Pagesには、パフォーマンスへの影響を最小限に抑えるための[`_redirects`ファイル](../../user/project/pages/redirects.md)のデフォルト制限があります。

制限を調整するには:

```ruby
gitlab_pages['redirects_max_config_size'] = 131072
gitlab_pages['redirects_max_path_segments'] = 50
gitlab_pages['redirects_max_rule_count'] = 2000
```

## 環境変数を使用する {#use-environment-variables}

Pagesデーモンに環境変数を渡して、機能フラグを有効または無効にすることができます。

設定可能なディレクトリ機能を無効にするには、次の手順に従います。

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_pages['env'] = {
     'FF_CONFIGURABLE_ROOT_DIR' => "false"
   }
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

## デーモンの冗長なログの生成を有効にする {#activate-verbose-logging-for-daemon}

GitLab Pagesデーモンの詳細なロギングを設定するには:

1. デフォルトでは、デーモンは`INFO`レベルでのみログを生成します。イベントを`DEBUG`レベルでログに記録するには、`/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_pages['log_verbose'] = true
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

## 相関IDを伝播させる {#propagating-the-correlation-id}

`propagate_correlation_id`を`true`に設定すると、リバースプロキシの背後にあるインストールで、GitLab Pagesに送信されるリクエストに相関IDを生成して設定できます。リバースプロキシが`X-Request-ID`ヘッダーの値を設定すると、その値はリクエストチェーン内で伝播されます。ユーザーは[ログで相関IDを見つける](../logs/tracing_correlation_id.md#identify-the-correlation-id-for-a-request)ことができます。

相関IDの伝播を有効にするには、次の手順に従います。

1. `/etc/gitlab/gitlab.rb`に、以下を追加します:

   ```ruby
   gitlab_pages['propagate_correlation_id'] = true
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

## ストレージパスを変更する {#change-storage-path}

GitLab Pagesコンテンツが保存されるデフォルトのパスを変更するには:

1. ページはデフォルトで`/var/opt/gitlab/gitlab-rails/shared/pages`に保存されます。別の場所を使用するには、`/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['pages_path'] = "/mnt/storage/pages"
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

## リバースプロキシリクエストのリスナーを設定する {#configure-listener-for-reverse-proxy-requests}

GitLab Pagesのプロキシリスナーを設定するには:

1. デフォルトでは、リスナーは`localhost:8090`でリクエストをリッスンするように設定されています。

   それを無効にするには、`/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_pages['listen_proxy'] = nil
   ```

   ポートを変更するには、`/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_pages['listen_proxy'] = "localhost:10080"
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

## 各GitLab Pagesサイトのグローバルな最大サイズを設定する {#set-global-maximum-size-of-each-gitlab-pages-site}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

プロジェクトのグローバルな最大ページサイズを設定するには、次の手順に従います。

1. 右上隅で、**管理者**を選択します。
1. **設定** > **設定**を選択します。
1. **Pages**を展開します。
1. **ページの最大サイズ**に値を入力します。デフォルトは`100`です。
1. **変更を保存**を選択します。

## グループ内の各GitLab Pagesサイトの最大サイズを設定する {#set-maximum-size-of-each-gitlab-pages-site-in-a-group}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

グループ内の各GitLab Pagesサイトの最大サイズを設定し、継承された設定をオーバーライドするには、次の手順に従います。

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般**を選択します。
1. **Pages**を展開します。
1. **最大サイズ**に値をMB単位で入力します。
1. **変更を保存**を選択します。

## プロジェクト内のGitLab Pagesサイトの最大サイズを設定する {#set-maximum-size-of-gitlab-pages-site-in-a-project}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

プロジェクト内のGitLab Pagesサイトの最大サイズを設定し、継承された設定を上書きするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Pages**を選択します。
1. **ページの最大サイズ**に、サイズをMB単位で入力します。
1. **変更を保存**を選択します。

## プロジェクトのGitLab Pagesカスタムドメインの最大数を設定する {#set-maximum-number-of-gitlab-pages-custom-domains-for-a-project}

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

プロジェクトのGitLab Pagesカスタムドメインの最大数を設定するには、次の手順に従います。

1. 右上隅で、**管理者**を選択します。
1. **設定** > **設定**を選択します。
1. **Pages**を展開します。
1. **プロジェクトごとのカスタムドメインの最大数**に値を入力します。カスタムドメイン数を無制限にする場合は、`0`を入力します。
1. **変更を保存**を選択します。

## 並列デプロイのデフォルトの有効期限を設定する {#configure-the-default-expiry-for-parallel-deployments}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/456477)されました。

{{< /history >}}

前提条件: 

- インスタンスへの管理者アクセス権。

[並列デプロイ](../../user/project/pages/_index.md#parallel-deployments)が削除された後のデフォルト期間を設定するには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **設定**を選択します。
1. **Pages**を展開します。
1. **並列デプロイのデフォルトの有効期限（秒）**に値を入力します。並列デプロイをデフォルトで期限切れにしない場合は、`0`を入力します。
1. **変更を保存**を選択します。

## GitLab Pagesウェブサイトごとのファイルの最大数を設定する {#set-maximum-number-of-files-per-gitlab-pages-website}

ファイルエントリ（ディレクトリとシンボリックリンクを含む）の合計数は、各GitLab Pages Webサイトで`200,000`に制限されています。

この制限は、GitLab Self-Managedインスタンスで[GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)を使用して更新できます。

詳細については、[GitLabアプリケーションの制限](../instance_limits.md#number-of-files-per-gitlab-pages-website)を参照してください。

## 別のサーバーでGitLab Pagesを実行する {#running-gitlab-pages-on-a-separate-server}

GitLab Pagesデーモンを別のサーバーで実行することで、メインアプリケーションサーバーの負荷を軽減できます。

> [!warning]以下の手順には、`gitlab-secrets.json`ファイルのバックアップと編集の手順が含まれています。このファイルには、データベースの暗号化を制御するシークレットが含まれているため、慎重に作業を進めてください。

別のサーバーでGitLab Pagesを設定するには、次の手順に従います。

1. （オプション）アクセス制御を有効にするには、`/etc/gitlab/gitlab.rb`に次の内容を追加し、[**GitLabサーバー**を再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

   > [!warning] GitLab Pagesをアクセス制御と共に使用する予定がある場合は、`gitlab-secrets.json`をコピーする前にGitLabサーバーでそれを有効にしてください。アクセス制御を有効にすると、新しいOAuthアプリケーションが生成され、その情報が`gitlab-secrets.json`に伝播されます。これが正しい順序で行われない場合、アクセス制御に関するイシューに直面する可能性があります。

   ```ruby
   gitlab_pages['access_control'] = true
   ```

1. **GitLabサーバー**でシークレットファイルのバックアップを作成します。

   ```shell
   cp /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.bak
   ```

1. **GitLabサーバー**でPagesを有効にするには、`/etc/gitlab/gitlab.rb`に次の内容を追加します。

   ```ruby
   pages_external_url "http://<pages_server_URL>"
   ```

1. 次のいずれかの方法でオブジェクトストレージを設定します。
   - [オブジェクトストレージを設定し、GitLab Pagesのデータを移行する](#object-storage-settings)。
   - [ネットワークストレージを設定する](#enable-pages-network-storage-in-multi-node-environments)。
1. 変更を反映するために[**GitLabサーバー**を再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。これで、`gitlab-secrets.json`ファイルが新しい設定で更新されました。
1. 新しいサーバーを設定します。これが**Pagesサーバー**になります。
1. **Pagesサーバー**で、Linuxパッケージを使用してGitLabをインストールし、`/etc/gitlab/gitlab.rb`を次のように変更します。

   ```ruby
   roles ['pages_role']

   pages_external_url "http://<pages_server_URL>"

   gitlab_pages['gitlab_server'] = 'http://<gitlab_server_IP_or_URL>'

   ## If access control was enabled
   gitlab_pages['access_control'] = true
   ```

1. **GitLab server**にカスタムUID/GID設定がある場合は、それらを**Pages server**の`/etc/gitlab/gitlab.rb`にも追加してください。そうしないと、**GitLab server**で`gitlab-ctl reconfigure`を実行すると、ファイル所有権が変更され、Pagesのリクエストが失敗する可能性があります。

1. **Pagesサーバー**でシークレットファイルのバックアップを作成します。

   ```shell
   cp /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.bak
   ```

1. 個々のGitLab Pagesサイトでカスタムドメインを有効にするには、次のいずれかを使用して**Pagesサーバー**を設定します。

   - [カスタムドメイン](#custom-domains)
   - [TLS対応のカスタムドメイン](#custom-domains-with-tls-support)

1. **GitLab server**から**Pages server**へ`/etc/gitlab/gitlab-secrets.json`ファイルをコピーします:

   ```shell
   # On the GitLab server
   cp /etc/gitlab/gitlab-secrets.json /mnt/pages/gitlab-secrets.json

   # On the Pages server
   mv /var/opt/gitlab/gitlab-rails/shared/pages/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json
   ```

1. 変更を反映するために[**Pagesサーバー**を再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
1. **GitLabサーバー**で、`/etc/gitlab/gitlab.rb`を次のように変更します。

   ```ruby
   pages_external_url "http://<pages_server_URL>"
   gitlab_pages['enable'] = false
   pages_nginx['enable'] = false
   ```

1. 個々のGitLab Pagesサイトでカスタムドメインを有効にするには、**GitLabサーバー**で`/etc/gitlab/gitlab.rb`に次の変更を加えます。

   - カスタムドメイン:

     ```ruby
        gitlab_pages['custom_domain_mode'] = 'http'
     ```

   - TLSサポート付きカスタムドメイン:

     ```ruby
        gitlab_pages['custom_domain_mode'] = 'https'
     ```

1. 変更を反映するために[**GitLabサーバー**を再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

負荷を分散するために、複数のGitLab Pagesを、DNSサーバーを設定して複数のIPを返すようにしたり、IPレベルのロードバランサーを使用したりするなど、標準的なロードバランシング手法を用いて複数のサーバーで実行できます。複数のサーバーにGitLab Pagesを設定するには、各Pagesサーバーで前の手順を繰り返します。

## ドメインソース設定 {#domain-source-configuration}

GitLab Pagesデーモンがリクエストを処理する際、まずどのプロジェクトがリクエストされたURLを処理すべきか、そしてそのコンテンツがどのように保存されているかを識別します。

デフォルトでは、GitLab Pagesは新しいドメインがリクエストされるたびに、内部のGitLab APIを使用します。PagesはAPIに接続できない場合、起動に失敗します。ドメイン情報は、後続のリクエストを高速化するためにPagesデーモンによってもキャッシュされます。

一般的なイシューについては、[トラブルシューティング](troubleshooting.md#failed-to-connect-to-the-internal-gitlab-api)セクションを参照してください。

### GitLab APIキャッシュ設定 {#gitlab-api-cache-configuration}

APIベースの設定は、パフォーマンスと信頼性を向上させるためにキャッシュメカニズムを使用します。キャッシュの動作は、以下の設定を変更することで修正できますが、推奨されるデフォルトは必要な場合にのみ変更すべきです。誤った設定は、断続的または永続的なエラー、あるいはPagesデーモンが古いコンテンツを提供することにつながる可能性があります。

> [!note]有効期限、間隔、およびタイムアウトフラグは[Go期間フォーマット](https://pkg.go.dev/time#ParseDuration)を使用します。期間文字列は、オプションの小数と単位サフィックスを持つ10進数の符号付きシーケンスであり、たとえば`300ms`、`1.5h`、または`2h45m`のようになります。有効な時間単位は、`ns`、`us`（または`µs`）、`ms`、`s`、`m`、`h`です。

例: 

- `gitlab_cache_expiry`を増やすと、キャッシュ内のアイテムがより長く保持されます。GitLab PagesとGitLab Rails間の通信が安定していない場合に、この設定を使用します。
- `gitlab_cache_refresh`を増やすと、GitLab PagesがGitLab Railsに対してドメインの設定情報をリクエストする頻度が減ります。GitLab PagesがGitLab APIへのリクエストを過剰に生成し、コンテンツが頻繁に変更されない場合に、この設定を使用します。
- `gitlab_cache_cleanup`を減らすと、期限切れの項目がキャッシュからより頻繁に削除され、Pagesノードでのメモリ使用量が削減されます。
- `gitlab_retrieval_timeout`を減らすと、GitLab Railsへのリクエストがより迅速に停止されます。それを増やすと、APIから応答を受信する時間が増えます。低速なネットワーク環境でこの設定を使用します。
- `gitlab_retrieval_interval`を減らすと、接続タイムアウトなど、APIからのエラー応答がある場合にのみ、APIへのリクエストがより頻繁に行われます。
- `gitlab_retrieval_retries`を減らすと、エラーを報告する前にドメインの設定が再試行される回数が減ります。

## オブジェクトストレージ設定 {#object-storage-settings}

以下の[オブジェクトストレージ](../object_storage.md)設定では、次のようになります。

- 自己コンパイルによるインストールでは、設定は`pages:`の下の`object_store:`にネストされます。
- Linuxパッケージインストールでは、プレフィックスとして`pages_object_store_`が付きます。

| 設定 | 説明 | デフォルト |
|---------|-------------|---------|
| `enabled` | オブジェクトストレージが有効かどうかを指定します。 | `false` |
| `remote_directory` | Pagesサイトのコンテンツを保存するバケットの名前。 | |
| `connection` | さまざまな接続オプション（以降のセクションで説明します）。 | |

> [!note] NFSサーバーの使用を停止し、切断する場合は、[ローカルストレージを明示的に無効にする](#disable-pages-local-storage)必要があります。

### S3互換接続設定 {#s3-compatible-connection-settings}

[統合されたオブジェクトストレージ設定](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)を使用する必要があります。

[プロバイダーごとの使用可能な接続設定](../object_storage.md#configure-the-connection-settings)を参照してください。

### Pagesデプロイをオブジェクトストレージに移行する {#migrate-pages-deployments-to-object-storage}

既存のPagesデプロイオブジェクト（ZIPアーカイブ）は、ローカルストレージまたはオブジェクトストレージのいずれかに保存できます。

既存のPagesデプロイをローカルストレージからオブジェクトストレージに移行するには:

```shell
sudo gitlab-rake gitlab:pages:deployments:migrate_to_object_storage
```

[PostgreSQLコンソール](https://docs.gitlab.com/omnibus/settings/database/#connecting-to-the-postgresql-database)を使用して、進行状況を追跡し、すべてのPagesデプロイを正常に移行したことを確認できます。

- Linuxパッケージインストールの場合: `sudo gitlab-rails dbconsole --database main`。
- 自己コンパイルによるインストールの場合: `sudo -u git -H psql -d gitlabhq_production`。

`objectstg`（`store=2`）にすべてのPagesデプロイのカウントがあることを確認します:

```shell
gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM pages_deployments;

total | filesystem | objectstg
------+------------+-----------
   10 |          0 |        10
```

すべてが正しく動作していることを確認したら、[Pagesのローカルストレージを無効にします](#disable-pages-local-storage)。

### Pagesデプロイをローカルストレージにロールバックする {#rolling-pages-deployments-back-to-local-storage}

オブジェクトストレージに移行した後、Pagesデプロイをローカルストレージに戻すことができます:

```shell
sudo gitlab-rake gitlab:pages:deployments:migrate_to_local
```

### Pagesローカルストレージを無効にする {#disable-pages-local-storage}

オブジェクトストレージを使用する場合は、不要なディスクの使用や書き込みを防ぐため、ローカルストレージを無効にできます。

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_rails['pages_local_store_enabled'] = false
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

## マルチノード環境でPagesのネットワークストレージを有効にする {#enable-pages-network-storage-in-multi-node-environments}

オブジェクトストレージは、ほとんどの環境において推奨される設定です。ただし、要件によってネットワークストレージが必要であり、[別のサーバー](#running-gitlab-pages-on-a-separate-server)でPagesを実行する必要がある場合は、次の手順に従います。

1. 共有ストレージボリュームがプライマリサーバーと意図するPagesサーバーの両方で既にマウントされ、利用可能であることを確認してください。
1. 各ノードの`/etc/gitlab/gitlab.rb`を更新して以下を含めます:

   ```ruby
   gitlab_pages['enable_disk'] = true
   gitlab_rails['pages_path'] = "/var/opt/gitlab/gitlab-rails/shared/pages" # Path to your network storage
   ```

1. Pagesを別のサーバーに切り替えます。

別のサーバーでPagesの設定が正常に完了した後、共有ストレージボリュームへのアクセスが必要なのはそのサーバーのみとなります。単一ノード環境に移行する必要がある場合に備えて、共有ストレージボリュームをプライマリサーバーにマウントしたままにすることを検討してください。

## ZIPストレージ {#zip-storage}

GitLab Pagesの基盤となるストレージ形式は、プロジェクトごとに1つのZIPアーカイブです。これらのアーカイブは、ローカルまたは[オブジェクトストレージのいずれかに保存できます。](#object-storage-settings)Pagesサイトが更新されるたびに、新しいアーカイブが保存されます。

## バックアップ {#backup}

GitLab Pagesは[定期バックアップ](../backup_restore/_index.md)に含まれているため、個別のバックアップ設定はありません。

## セキュリティ {#security}

クロスサイトスクリプティング攻撃を防ぐために、GitLab PagesをGitLabとは異なるホスト名で実行することを強くおすすめします。

### レート制限 {#rate-limits}

{{< history >}}

- GitLab 17.3で[変更](https://gitlab.com/groups/gitlab-org/-/epics/14653)され、サブネットをPagesのレート制限から除外できるようになりました。

{{< /history >}}

サービス拒否（DoS）攻撃のリスクを最小限に抑えるために、レート制限を適用できます。GitLab Pagesは、トークンバケットアルゴリズムを使用してレート制限を実施しています。デフォルトでは、指定された制限を超えたリクエストまたはTLS接続は報告され、拒否されます。

GitLab Pagesでは、次の種類のレート制限をサポートしています。

- 各`source_ip`に対して: 単一のクライアントIPアドレスからのリクエストまたはTLS接続を制限します。
- 各`domain`に対して: GitLab PagesでホストされているドメインごとのリクエストまたはTLS接続を制限します。これは`example.com`のようなカスタムドメイン、または`group.gitlab.io`のようなグループドメインにすることができます。

HTTPリクエストベースのレート制限は、以下の設定を使用して適用されます:

- `rate_limit_source_ip`: クライアントIPあたりの最大リクエスト数/秒。無効にするには`0`に設定します。
- `rate_limit_source_ip_burst`: クライアントIPあたりの最初のバーストで許可される最大リクエスト数（例: ページが複数のリソースを同時に読み込みする場合）。
- `rate_limit_domain`: ホストされているPagesドメインあたりの最大リクエスト数/秒。無効にするには`0`に設定します。
- `rate_limit_domain_burst`: ホストされているPagesドメインあたりの最初のバーストで許可される最大リクエスト数。

TLS接続ベースのレート制限は、以下の設定を使用して適用されます:

- `rate_limit_tls_source_ip`: クライアントIPあたりの最大TLS接続数/秒。無効にするには`0`に設定します。
- `rate_limit_tls_source_ip_burst`: クライアントIPあたりの最初のバーストで許可される最大TLS接続数。
- `rate_limit_tls_domain`: ホストされているPagesドメインあたりの最大TLS接続数/秒。無効にするには`0`に設定します。
- `rate_limit_tls_domain_burst`: ホストされているPagesドメインあたりの最初のバーストで許可される最大TLS接続数。

特定のIP範囲（サブネット）がすべてのレート制限をバイパスすることを許可するには、`rate_limit_subnets_allow_list`を使用します。例: `['1.2.3.4/24', '2001:db8::1/32']`。[GitLab Pagesチャートの例](https://docs.gitlab.com/charts/charts/gitlab/gitlab-pages/#configure-rate-limits-subnets-allow-list)が利用可能です。

クライアントのIPアドレスがIPv6の場合、制限はアドレス全体ではなく、長さ64のIPv6プレフィックスに適用されます。

#### ソースIPごとのHTTPリクエストレート制限を有効にする {#enable-http-requests-rate-limits-by-source-ip}

`/etc/gitlab/gitlab.rb`でレート制限を設定するには:

1. 以下を追加します:

   ```ruby
   gitlab_pages['rate_limit_source_ip'] = 20.0
   gitlab_pages['rate_limit_source_ip_burst'] = 600
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

#### ドメインごとのHTTPリクエストレート制限を有効にする {#enable-http-requests-rate-limits-by-domain}

`/etc/gitlab/gitlab.rb`でレート制限を設定するには:

1. 追加:

   ```ruby
   gitlab_pages['rate_limit_domain'] = 1000
   gitlab_pages['rate_limit_domain_burst'] = 5000
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

#### ソースIPごとのTLS接続レート制限を有効にする {#enable-tls-connections-rate-limits-by-source-ip}

`/etc/gitlab/gitlab.rb`でレート制限を設定するには:

1. 追加:

   ```ruby
   gitlab_pages['rate_limit_tls_source_ip'] = 20.0
   gitlab_pages['rate_limit_tls_source_ip_burst'] = 600
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

#### ドメインごとのTLS接続レート制限を有効にする {#enable-tls-connections-rate-limits-by-domain}

`/etc/gitlab/gitlab.rb`でレート制限を設定するには:

1. 追加:

   ```ruby
   gitlab_pages['rate_limit_tls_domain'] = 1000
   gitlab_pages['rate_limit_tls_domain_burst'] = 5000
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

## 関連トピック {#related-topics}

- [GitLab Pagesの管理のトラブルシューティング](troubleshooting.md)
- [GitLab Pagesのユーザードキュメント](../../user/project/pages/_index.md)
- [カスタムドメインとSSL/TLS証明書](../../user/project/pages/custom_domains_ssl_tls_certification/_index.md)
- [GitLab Pagesへのアクセス制御](../../user/project/pages/pages_access_control.md)
- [ジョブアーティファクト](../cicd/job_artifacts.md)
- [OAuthプロバイダーインテグレーション](../../integration/oauth_provider.md)
- [GitLabアプリケーションの制限](../instance_limits.md#number-of-files-per-gitlab-pages-website)
- [オブジェクトストレージ](../object_storage.md)
- [並列デプロイ](../../user/project/pages/_index.md#parallel-deployments)
- [デフォルトフォルダーをカスタマイズする](../../user/project/pages/introduction.md#customize-the-default-folder)
- [Pagesでのリダイレクト](../../user/project/pages/redirects.md)
