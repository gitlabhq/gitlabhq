---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Pagesの管理
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLab Pagesは、GitLabプロジェクトおよびグループの静的サイトホスティングを提供します。ユーザーがこの機能にアクセスできるようにするには、サーバー管理者がPagesを設定しておく必要があります。GitLab Pagesを使用すると、管理者は次のことが可能になります。

- カスタムドメインとSSL/TLS証明書を使用して、静的ウェブサイトを安全にホストする。
- GitLabの権限を通じてPagesサイトへのアクセスを制御するための認証を有効にする。
- マルチノード環境でオブジェクトストレージまたはネットワークストレージを使用して、デプロイをスケールする。
- レート制限とカスタムヘッダーを使用して、トラフィックを監視および管理する。
- すべてのPagesサイトでIPv4およびIPv6アドレスをサポートする。

GitLab Pagesデーモンは個別のプロセスとして実行され、GitLabと同じサーバー上または独自の専用インフラストラクチャ上で設定できます。ユーザー向けドキュメントについては、[GitLab Pages](../../user/project/pages/_index.md)を参照してください。

{{< alert type="note" >}}

このガイドは、Linuxパッケージインストール環境を対象としています。自己コンパイルでGitLabをインストールしている場合は、[自己コンパイルでインストールしたGitLab Pagesの管理](source.md)を参照してください。

{{< /alert >}}

## GitLab Pagesデーモン

GitLab Pagesは、[GitLab Pagesデーモン](https://gitlab.com/gitlab-org/gitlab-pages)を使用しています。これは、Goで記述された基本的なHTTPサーバーであり、外部IPアドレスをリッスンし、カスタムドメインとカスタム証明書をサポートしています。Server Name Indication（SNI）を使用した動的証明書をサポートし、デフォルトでHTTP2を使用してページを公開します。この仕組みを十分に理解するために、[README](https://gitlab.com/gitlab-org/gitlab-pages/blob/master/README.md)を読むことをおすすめします。

[カスタムドメイン](#custom-domains)（[ワイルドカードドメイン](#wildcard-domains)ではない）の場合、Pagesデーモンは`80`または`443`ポートをリッスンする必要があります。そのため、設定方法にはある程度の柔軟性があります。

- GitLabと同じサーバーでPagesデーモンを実行し、**セカンダリIP**でリッスンする。
- [別のサーバー](#running-gitlab-pages-on-a-separate-server)でPagesデーモンを実行する。この場合、Pagesデーモンをインストールしたサーバーにも[Pagesのパス](#change-storage-path)が存在する必要があるため、ネットワーク経由で共有する必要があります。
- GitLabと同じサーバーでPagesデーモンを実行し、同じIP上の別のポートでリッスンする。その場合、ロードバランサーによるトラフィックのプロキシ処理が必要になります。このルートを選択する場合、HTTPSではTCPロードバランシングを使用する必要があります。TLS終端（HTTPSロードバランシング）を使用する場合、ユーザーが提供する証明書ではページを配信できません。HTTPの場合は、HTTPまたはTCPロードバランシングを使用できます。

このドキュメントでは、最初のオプションを前提として説明を進めます。カスタムドメインをサポートしていない場合は、セカンダリIPは必要ありません。

## 前提要件

このセクションでは、GitLab Pagesを設定するための前提要件について説明します。

### ワイルドカードドメイン

ワイルドカードドメインのPagesを設定する前に、次の準備が必要です。

1. GitLabインスタンスドメインのサブドメインではない、Pagesのドメインを用意します。

   | GitLabドメイン        | Pagesドメイン        | 動作可能？ |
   | -------------------- | ------------------- | ------------- |
   | `example.com`        | `example.io`        | {{< icon name="check-circle" >}} はい |
   | `example.com`        | `pages.example.com` | {{< icon name="dotted-circle" >}} いいえ |
   | `gitlab.example.com` | `pages.example.com` | {{< icon name="check-circle" >}} はい |

1. **ワイルドカードDNSレコード**を設定します。
1. （オプション）HTTPSでPagesを提供する場合は、そのドメインの**ワイルドカード証明書**を用意します。
1. （推奨されるオプション）ユーザーが独自にRunnerを用意しなくてもいいように、[インスタンスRunner](../../ci/runners/_index.md)を有効にします。
1. カスタムドメインの場合は、**セカンダリIP**を用意します。

### シングルドメインサイト

シングルドメインサイトのPagesを設定する前に、次の準備が必要です。

1. GitLabインスタンスドメインのサブドメインではない、Pagesのドメインを用意します。

   | GitLabドメイン        | Pagesドメイン        | サポート対象 |
   | -------------------- | ------------------- | ------------- |
   | `example.com`        | `example.io`        | {{< icon name="check-circle" >}} はい |
   | `example.com`        | `pages.example.com` | {{< icon name="dotted-circle" >}} いいえ |
   | `gitlab.example.com` | `pages.example.com` | {{< icon name="check-circle" >}} はい |

1. **DNSレコード**を設定します。
1. （オプション）HTTPSでPagesを提供する場合は、そのドメインの**TLS証明書**を用意します。
1. （推奨されるオプション）ユーザーが独自にRunnerを用意しなくてもいいように、[インスタンスRunner](../../ci/runners/_index.md)を有効にします。
1. カスタムドメインの場合は、**セカンダリIP**を用意します。

{{< alert type="note" >}}

GitLabインスタンスとPagesデーモンがプライベートネットワークにデプロイされている場合、またはファイアウォールの内側にある場合、プライベートネットワークにアクセスできるデバイス/ユーザーのみがGitLab Pagesウェブサイトにアクセスできます。

{{< /alert >}}

### Public Suffix Listにドメインを追加する

[Public Suffix List](https://publicsuffix.org)は、サブドメインの処理方法を決定するためにブラウザによって使用されます。GitLabインスタンスが一般ユーザーによるGitLab Pagesサイトの作成を許可している場合、これらのユーザーはページドメイン（`example.io`）上にサブドメインを作成することも許可されます。ドメインをPublic Suffix Listに追加すると、特にブラウザが[スーパーCookie](https://en.wikipedia.org/wiki/HTTP_cookie#Supercookie)を受け入れるのを防ぐことができます。

GitLab Pagesのサブドメインを登録するには、[Submit amendments to the Public Suffix List](https://publicsuffix.org/submit/)（Public Suffix Listへの修正申請）に記載された手順に従います。たとえば、ドメインが`example.io`の場合、`example.io`をPublic Suffix Listに追加するよう申請する必要があります。GitLab.comは、`gitlab.io`を[2016年に追加](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/230)しました。

### DNSの設定

GitLab Pagesは、独自の仮想ホストで実行されることを想定しています。DNSサーバー/プロバイダーで、GitLabを実行しているホストを指す[ワイルドカードDNS `A`レコード](https://en.wikipedia.org/wiki/Wildcard_DNS_record)を追加します。たとえば、次のようなエントリになります。

```plaintext
*.example.io. 1800 IN A    192.0.2.1
*.example.io. 1800 IN AAAA 2001:db8::1
```

ここで、`example.io`はGitLab Pagesを提供するドメイン、`192.0.2.1`はGitLabインスタンスのIPv4アドレス、`2001:db8::1`はIPv6アドレスです。IPv6を使用していない場合は、`AAAA`レコードは省略できます。

#### シングルドメインサイトのDNS設定

{{< history >}}

- GitLab 16.7で[実験](../../policy/development_stages_support.md)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/17584)されました。
- GitLab 16.11で[ベータ](../../policy/development_stages_support.md)に[移行](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148621)しました。
- GitLab 17.2でNGINXからGitLab Pagesコードベースに実装が[変更](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/1111)されました。
- GitLab 17.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/483365)になりました。

{{< /history >}}

ワイルドカードDNSを使用せずに、シングルドメインサイトのGitLab Pages DNSを設定するには、次の手順に従います。

1. `/etc/gitlab/gitlab.rb`に`gitlab_pages["namespace_in_path"] = true`を追加して、この機能のGitLab Pagesフラグを有効にします。
1. DNSプロバイダーで、`example.io`のエントリを追加します。`example.io`をドメイン名に、`192.0.0.0`をIPアドレスのIPv4バージョンに置き換えます。次のようなエントリになります。

   ```plaintext
   example.io          1800 IN A    192.0.0.0
   ```

1. （オプション）GitLabインスタンスにIPv6アドレスがある場合は、そのエントリを追加します。`example.io`をドメイン名に、`2001:db8::1`をIPアドレスのIPv6バージョンに置き換えます。次のようなエントリになります。

   ```plaintext
   example.io          1800 IN AAAA 2001:db8::1
   ```

この例には、次の項目が含まれています。

- `example.io`: GitLab Pagesを提供するドメイン。

#### カスタムドメインのDNS設定

カスタムドメインのサポートが必要な場合は、Pagesのルートドメインに属するすべてのサブドメインがセカンダリIP（Pagesデーモン専用）を指す必要があります。この設定がないと、ユーザーは`CNAME`レコードを使用して、カスタムドメインがGitLab Pagesを指すように指定することができません。

たとえば、次のようなエントリになります。

```plaintext
example.com   1800 IN A    192.0.2.1
*.example.io. 1800 IN A    192.0.2.2
```

この例には、次の項目が含まれています。

- `example.com`: GitLabドメイン。
- `example.io`: GitLab Pagesを提供するドメイン。
- `192.0.2.1`: GitLabインスタンスのプライマリIP。
- `192.0.2.2`: GitLab Pages専用のセカンダリIP。プライマリIPとは異なるものを指定する必要があります。

{{< alert type="note" >}}

GitLabドメインを使用してユーザーページを提供すべきではありません。詳細については、[セキュリティセクション](#security)を参照してください。

{{< /alert >}}

## 設定

ニーズに応じて、4種類の方法でGitLab Pagesを設定できます。

次に、最も簡単な設定から最も高度な設定の順番で、各設定例を紹介します。

### ワイルドカードドメイン

次の設定は、GitLab Pagesを使用するための最小限のセットアップです。これは、このセクションで説明する他のすべての設定の基礎となります。この設定では次のように動作します。

- NGINXがすべてのリクエストをGitLab Pagesデーモンにプロキシします。
- GitLab Pagesデーモンは、パブリックインターネットを直接リッスンしません。

前提要件:

- [ワイルドカードDNSの設定](#dns-configuration)

ワイルドカードドメインを使用するようにGitLab Pagesを設定するには、次の手順に従います。

1. `/etc/gitlab/gitlab.rb`でGitLab Pagesの外部URLを設定します。

   ```ruby
   external_url "http://example.com" # external_url here is only for reference
   pages_external_url 'http://example.io' # Important: not a subdomain of external_url, so cannot be http://pages.example.com
   ```

1. [GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

この設定でアクセス可能になるURLスキームは、`http://<namespace>.example.io/<project_slug>`です。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> 概要については、[How to Enable GitLab Pages for GitLab CE and EE](https://youtu.be/dD8c7WNcc6s)（GitLab CEおよびEEでGitLab Pagesを有効にする方法）を参照してください。
<!-- Video published on 2017-02-22 -->

### シングルドメインサイト

{{< history >}}

- GitLab 16.7で[実験](../../policy/development_stages_support.md)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/17584)されました。
- GitLab 16.11で[ベータ](../../policy/development_stages_support.md)に[移行](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148621)しました。
- GitLab 17.2でNGINXからGitLab Pagesコードベースに実装が[変更](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/1111)されました。
- GitLab 17.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/483365)になりました。

{{< /history >}}

次の設定は、GitLab Pagesを使用するための最小限のセットアップです。これは、このセクションで説明する他のすべての設定の基礎となります。この設定では次のように動作します。

- NGINXがすべてのリクエストをGitLab Pagesデーモンにプロキシします。
- GitLab Pagesデーモンは、パブリックインターネットを直接リッスンしません。

前提要件:

- [シングルドメインサイト](#dns-configuration-for-single-domain-sites)のDNSの設定が完了している。

シングルドメインサイトを使用するようにGitLab Pagesを設定するには、次の手順に従います。

1. `/etc/gitlab/gitlab.rb`で、GitLab Pagesの外部URLを設定し、機能を有効にします。

   ```ruby
   external_url "http://example.com" # Swap out this URL for your own
   pages_external_url 'http://example.io' # Important: not a subdomain of external_url, so cannot be http://pages.example.com

   # Set this flag to enable this feature
   gitlab_pages["namespace_in_path"] = true
   ```

1. [GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

この設定でアクセス可能になるURLスキームは、`http://example.io/<namespace>/<project_slug>`です。

{{< alert type="warning" >}}

GitLab Pagesでは、一度にサポートできるURLスキームは1つのみで、ワイルドカードドメインサイトまたはシングルドメインサイトのいずれかを使用できます。`namespace_in_path`を有効にすると、既存のGitLab Pagesウェブサイトはシングルドメインでのみアクセスできます。

{{< /alert >}}

### TLS対応のワイルドカードドメイン

前提要件:

- [ワイルドカードDNSの設定](#dns-configuration)
- TLS証明書。ワイルドカード証明書、または[要件](../../user/project/pages/custom_domains_ssl_tls_certification/_index.md#manual-addition-of-ssltls-certificates)を満たすその他の種類の証明書。

NGINXはすべてのリクエストをデーモンにプロキシします。Pagesデーモンはパブリックインターネットをリッスンしません。

1. `*.example.io`のワイルドカードTLS証明書とキーを`/etc/gitlab/ssl`内に配置します。
1. `/etc/gitlab/gitlab.rb`で、次のように設定します。

   ```ruby
   external_url "https://example.com" # external_url here is only for reference
   pages_external_url 'https://example.io' # Important: not a subdomain of external_url, so cannot be https://pages.example.com

   pages_nginx['redirect_http_to_https'] = true
   ```

1. 証明書に`example.io.crt`、キーに`example.io.key`という名前を付けていない場合は、次のようにフルパスも指定する必要があります。

   ```ruby
   pages_nginx['ssl_certificate'] = "/etc/gitlab/ssl/pages-nginx.crt"
   pages_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/pages-nginx.key"
   ```

1. [GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。
1. [Pagesへのアクセス制御](#access-control)を使用している場合は、GitLab Pagesの[システムOAuthアプリケーション](../../integration/oauth_provider.md#create-an-instance-wide-application)のリダイレクトURIを更新して、HTTPSプロトコルを使用します。

この設定でアクセス可能になるURLスキームは、`https://<namespace>.example.io/<project_slug>`です。

{{< alert type="warning" >}}

1つのインスタンスに対する複数のワイルドカードはサポートされていません。インスタンスごとに1つのワイルドカードのみを割り当てることができます。

{{< /alert >}}

{{< alert type="warning" >}}

リダイレクトURIに変更が加えられても、GitLab PagesはOAuthアプリケーションを更新しません。再設定する前に、`/etc/gitlab/gitlab-secrets.json`から`gitlab_pages`セクションを削除し、その後`gitlab-ctl reconfigure`を実行してください。詳細については、[GitLab PagesがOAuthを再生成しない](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3947)を参照してください。{{< /alert >}}

### TLS対応のシングルドメインサイト

{{< history >}}

- GitLab 16.7で[実験](../../policy/development_stages_support.md)として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/17584)されました。
- GitLab 16.11で[ベータ](../../policy/development_stages_support.md)に[移行](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148621)しました。
- GitLab 17.2でNGINXからGitLab Pagesコードベースに実装が[変更](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/1111)されました。
- GitLab 17.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/483365)になりました。

{{< /history >}}

前提要件:

- [シングルドメインサイト](#dns-configuration-for-single-domain-sites)のDNSの設定が完了している。
- ドメイン（例: `example.io`）をカバーするTLS証明書を所有している。

この設定では、NGINXはすべてのリクエストをデーモンにプロキシします。GitLab Pagesデーモンはパブリックインターネットをリッスンしません。

1. 前提要件にあるTLS証明書とキーを`/etc/gitlab/ssl`に配置します。
1. `/etc/gitlab/gitlab.rb`で、GitLab Pagesの外部URLを設定し、機能を有効にします。

   ```ruby
   external_url "https://example.com" # Swap out this URL for your own
   pages_external_url 'https://example.io' # Important: not a subdomain of external_url, so cannot be https://pages.example.com

   pages_nginx['redirect_http_to_https'] = true

   # Set this flag to enable this feature
   gitlab_pages["namespace_in_path"] = true
   ```

1. TLS証明書およびキーのファイル名がドメイン名（例: `example.io.crt`や`example.io.key`）と一致しない場合は、証明書とキーのファイルのフルパスを`/etc/gitlab/gitlab.rb`に追加します。

   ```ruby
   pages_nginx['ssl_certificate'] = "/etc/gitlab/ssl/pages-nginx.crt"
   pages_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/pages-nginx.key"
   ```

1. [Pagesへのアクセス制御](#access-control)を使用している場合は、GitLab Pagesの[システムOAuthアプリケーション](../../integration/oauth_provider.md#create-an-instance-wide-application)のリダイレクトURIを更新して、HTTPSプロトコルを使用します。

   {{< alert type="warning" >}}

   GitLab PagesはOAuthアプリケーションを更新せず、デフォルトの`auth_redirect_uri`が`https://example.io/projects/auth`に更新されます。再設定する前に、`/etc/gitlab/gitlab-secrets.json`から`gitlab_pages`セクションを削除し、その後`gitlab-ctl reconfigure`を実行してください。詳細については、[GitLab PagesがOAuthを再生成しない](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3947)を参照してください。

   {{< /alert >}}

1. [GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

この設定でアクセス可能になるURLスキームは、`https://example.io/<namespace>/<project_slug>`です。

{{< alert type="warning" >}}

GitLab Pagesでは、一度にサポートできるURLスキームは1つのみで、ワイルドカードドメインサイトまたはシングルドメインサイトのいずれかを使用できます。`namespace_in_path`を有効にすると、既存のGitLab Pagesウェブサイトはシングルドメインサイトとしてのみアクセスできます。

{{< /alert >}}

### TLS終端ロードバランサーを使用するワイルドカードドメイン

前提要件:

- [ワイルドカードDNSの設定](#dns-configuration)
- [TLS終端ロードバランサー](../../install/aws/_index.md#load-balancer)

この設定は主に、[Amazon Web ServicesにGitLab PoCをインストールする](../../install/aws/_index.md)際に使用することを目的としています。これには、TLSを終端する[クラシックロードバランサー](../../install/aws/_index.md#load-balancer)が含まれており、このロードバランサーがHTTPS接続をリッスンし、TLS証明書を管理し、HTTPトラフィックをインスタンスに転送します。

1. `/etc/gitlab/gitlab.rb`で、次のように設定します。

   ```ruby
   external_url "https://example.com" # external_url here is only for reference
   pages_external_url 'https://example.io' # Important: not a subdomain of external_url, so cannot be https://pages.example.com

   pages_nginx['enable'] = true
   pages_nginx['listen_port'] = 80
   pages_nginx['listen_https'] = false
   pages_nginx['redirect_http_to_https'] = true
   ```

1. [GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

この設定でアクセス可能になるURLスキームは、`https://<namespace>.example.io/<project_slug>`です。

### グローバル設定

以下の表は、LinuxパッケージインストールでPagesが認識するすべての設定項目と、その機能を示しています。これらのオプションは`/etc/gitlab/gitlab.rb`で調整でき、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)すると有効になります。環境内でPagesデーモンの動作やコンテンツの提供方法をより細かく制御する必要がない限り、ほとんどの設定は手動で指定する必要はありません。

| 設定                                 | 説明                                                                                                                                                                                                                                                                                                |
|-----------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `pages_external_url`                    | GitLab PagesにアクセスできるURL（プロトコル（HTTP/HTTPS）を含む）。`https://`を使用する場合は、追加の設定が必要です。詳細については、[TLS対応のワイルドカードドメイン](#wildcard-domains-with-tls-support)および[TLS対応のカスタムドメイン](#custom-domains-with-tls-support)を参照してください。 |
| **`gitlab_pages[]`**                    |                                                                                                                                                                                                                                                                                                            |
| `access_control`                        | [アクセス制御](_index.md#access-control)を有効にするかどうか。                                                                                                                                                                                                                                               |
| `api_secret_key`                        | GitLab APIとの認証に使用するシークレットキーのファイルのフルパス。未設定のままにすると自動生成されます。                                                                                                                                                                                                |
| `artifacts_server`                      | GitLab Pagesで[アーティファクト](../cicd/job_artifacts.md)の表示を有効にします。                                                                                                                                                                                                                                           |
| `artifacts_server_timeout`              | アーティファクトサーバーへのプロキシリクエストのタイムアウト（秒単位）。                                                                                                                                                                                                                                        |
| `artifacts_server_url`                  | アーティファクトリクエストのプロキシ先となるAPI URL。デフォルトはGitLab `external URL` + `/api/v4`です（例: `https://gitlab.com/api/v4`）。[個別のPagesサーバー](#running-gitlab-pages-on-a-separate-server)を運用している場合、このURLはメインのGitLabサーバーのAPIを指す必要があります。                                    |
| `auth_redirect_uri`                     | GitLabとの認証に使用するコールバックURL。URLは`pages_external_url`のサブドメインに`/auth`を付けた形式である必要があります。デフォルトでは、`pages_external_url`のプロジェクト用サブドメインに`/auth`を付けたものになります（例: `https://projects.example.io/auth`）。`namespace_in_path`が有効な場合、デフォルトは`pages_external_url`に`/projects/auth`を付けた形式です（例: `https://example.io/projects/auth`）。  |
| `auth_secret`                           | 認証リクエストに署名するためのシークレットキー。OAuth登録時にGitLabから自動的にプルするには、空白のままにします。                                                                                                                                                                                   |
| `client_cert`                           | GitLab APIとの相互TLSに使用するクライアント証明書。詳細については、[GitLab APIの呼び出し時に相互TLSをサポートする](#support-mutual-tls-when-calling-the-gitlab-api)を参照してください。                                                                                                                             |
| `client_key`                            | GitLab APIとの相互TLSに使用するクライアントキー。詳細については、[GitLab APIの呼び出し時に相互TLSをサポートする](#support-mutual-tls-when-calling-the-gitlab-api)を参照してください。                                                                                                                                     |
| `client_ca_certs`                       | GitLab APIとの相互TLSに使用するクライアント証明書の署名に使用するルートCA証明書。詳細については、[GitLab APIの呼び出し時に相互TLSをサポートする](#support-mutual-tls-when-calling-the-gitlab-api)を参照してください。                                                                                           |
| `dir`                                   | 設定ファイルおよびシークレットファイルの作業ディレクトリ。                                                                                                                                                                                                                                                     |
| `enable`                                | 現在のシステムでGitLab Pagesを有効または無効にします。                                                                                                                                                                                                                                                      |
| `external_http`                         | HTTPリクエストを処理するため、1つ以上のセカンダリIPアドレスにバインドするようにPagesを設定します。複数のアドレスは配列として指定でき、ポートを明示的に含めることもできます（例: `['1.2.3.4', '1.2.3.5:8063']`）。`listen_http`の値を設定します。TLS終端を行うリバースプロキシの背後でGitLab Pagesを実行している場合は、`external_http`の代わりに`listen_proxy`を指定します。 |
| `external_https`                        | HTTPSリクエストを処理するため、1つ以上のセカンダリIPアドレスにバインドするようにPagesを設定します。複数のアドレスは配列として指定でき、ポートを明示的に含めることもできます（例: `['1.2.3.4', '1.2.3.5:8063']`）。`listen_https`の値を設定します。                                                                      |
| `server_shutdown_timeout`               | GitLab Pagesサーバーのシャットダウンタイムアウト（秒単位。デフォルト: `30s`）。                                                                                                                                                                                                                                          |
| `gitlab_client_http_timeout`            | GitLab API HTTPクライアント接続タイムアウト（秒単位。デフォルト: `10s`）。                                                                                                                                                                                                                                     |
| `gitlab_client_jwt_expiry`              | JWTトークンの有効期限（秒単位。デフォルト: `30s`）。                                                                                                                                                                                                                                                         |
| `gitlab_cache_expiry`                   | ドメインの設定がキャッシュに保存される最大時間（デフォルト: `600s`）。詳細については、[GitLab APIキャッシュ設定](#gitlab-api-cache-configuration)を参照してください。 |
| `gitlab_cache_refresh`                  | ドメインの設定が更新対象とされる間隔（デフォルト: `60s`）。詳細については、[GitLab APIキャッシュ設定](#gitlab-api-cache-configuration)を参照してください。 |
| `gitlab_cache_cleanup`                  | 期限切れのアイテムをキャッシュから削除する間隔（デフォルト: `60s`）。詳細については、[GitLab APIキャッシュ設定](#gitlab-api-cache-configuration)を参照してください。 |
| `gitlab_retrieval_timeout`              | 1リクエストあたりで、GitLab APIからの応答を待機する最大時間（デフォルト: `30s`）。詳細については、[GitLab APIキャッシュ設定](#gitlab-api-cache-configuration)を参照してください。 |
| `gitlab_retrieval_interval`             | GitLab API経由でドメインの設定を解決する際、再試行までに待機する間隔（デフォルト: `1s`）。詳細については、[GitLab APIキャッシュ設定](#gitlab-api-cache-configuration)を参照してください。 |
| `gitlab_retrieval_retries`              | API経由でドメインの設定を解決する際、再試行する最大回数（デフォルト: 3）。詳細については、[GitLab APIキャッシュ設定](#gitlab-api-cache-configuration)を参照してください。 |
| `domain_config_source`                  | このパラメータは14.0で削除されました。以前のバージョンでは、API経由のドメイン設定ソースを有効化およびテストするために使用できます。                                                                                                                                                                                  |
| `gitlab_id`                             | OAuthアプリケーションの公開ID。空白のままにすると、PagesがGitLabで認証する際に自動的に入力されます。                                                                                                                                                                                                   |
| `gitlab_secret`                         | OAuthアプリケーションのシークレット。空白のままにすると、PagesがGitLabで認証する際に自動的に入力されます。                                                                                                                                                                                                      |
| `auth_scope`                            | 認証に使用するOAuthアプリケーションのスコープ。GitLab PagesのOAuthアプリケーション設定と一致している必要があります。空白のままにすると、デフォルトで`api`スコープが使用されます。                                                                                                                                                      |
| `auth_timeout`                          | 認証のためのGitLabアプリケーションクライアントのタイムアウト（秒単位。デフォルト: `5s`）。`0`を指定すると、タイムアウトは無効になります。                                                                                                                                                                                          |
| `auth_cookie_session_timeout`           | 認証用Cookieのセッションタイムアウト（秒単位。デフォルト: `10m`）。`0`を指定すると、ブラウザセッションの終了後にCookieが削除されます。                                                                                                                                                              |
| `gitlab_server`                         | アクセス制御が有効な場合に認証に使用するサーバー。デフォルトはGitLabの`external_url`です。                                                                                                                                                                                                        |
| `headers`                               | 各応答とともにクライアントに送信する必要がある追加のHTTPヘッダーを指定します。複数のヘッダーを配列として指定でき、ヘッダーと値は1つの文字列として記述します（例: `['my-header: myvalue', 'my-other-header: my-other-value']`）。                                                               |
| `enable_disk`                           | GitLab Pagesデーモンがディスクからコンテンツを配信できるようにします。共有ディスクストレージが利用できない場合は無効にする必要があります。                                                                                                                                                                                       |
| `insecure_ciphers`                      | デフォルトの暗号スイートリストを使用します。3DESやRC4などの脆弱なものが含まれている可能性があります。                                                                                                                                                                                                                            |
| `internal_gitlab_server`                | APIリクエスト専用に使用する内部GitLabサーバーアドレス。トラフィックを内部ロードバランサー経由で送信する必要がある場合に役立ちます。デフォルトはGitLabの`external_url`です。                                                                                                                               |
| `listen_proxy`                          | リバースプロキシリクエストをリッスンするアドレス。Pagesはこれらのアドレスのネットワークソケットにバインドし、そこから受信リクエストを受け取ります。`$nginx-dir/conf/gitlab-pages.conf`の`proxy_pass`の値を設定します。                                                                                    |
| `log_directory`                         | ログディレクトリの絶対パス。                                                                                                                                                                                                                                                                          |
| `log_format`                            | ログ出力形式: `text`または`json`。                                                                                                                                                                                                                                                                   |
| `log_verbose`                           | 冗長なログの生成。true/false。                                                                                                                                                                                                                                                                               |
| `namespace_in_path`                     | [シングルドメインサイトのDNS設定](#dns-configuration-for-single-domain-sites)をサポートするため、URLパスでのネームスペースを有効または無効にします。デフォルト: `false`。                                                                                                                                             |
| `propagate_correlation_id`              | 受信リクエストヘッダー`X-Request-ID`に既存の相関IDが存在する場合、それを再利用するには、trueに設定します（デフォルトはfalse）。リバースプロキシがこのヘッダーを設定している場合、その値はリクエストチェーン全体に伝播されます。                                                                                            |
| `max_connections`                       | HTTP、HTTPS、プロキシリスナーへの同時接続数の制限。                                                                                                                                                                                                                       |
| `max_uri_length`                        | GitLab Pagesで受け付けるURIの最大長。無制限にするには、0に設定します。                                                                                                                                                                                                                        |
| `metrics_address`                       | メトリクスのリクエストをリッスンするアドレス。                                                                                                                                                                                                                                                             |
| `redirect_http`                         | HTTPからHTTPSにページをリダイレクトします。true/false。                                                                                                                                                                                                                                                             |
| `redirects_max_config_size`             | `_redirects`ファイルの最大サイズ（バイト単位。デフォルト: 65536）。                                                                                                                                                                                                                                      |
| `redirects_max_path_segments`           | `_redirects`ルールのURLで許可されるパスセグメントの最大数（デフォルト: 25）。                                                                                                                                                                                                                      |
| `redirects_max_rule_count`              | `_redirects`で設定可能なルールの最大数（デフォルト: 1,000）。                                                                                                                                                                                                                                       |
| `sentry_dsn`                            | Sentryクラッシュレポートの送信先アドレス。                                                                                                                                                                                                                                                         |
| `sentry_enabled`                        | Sentryによるレポートとログの生成を有効にします。true/false。                                                                                                                                                                                                                                                      |
| `sentry_environment`                    | Sentryクラッシュレポートの環境。                                                                                                                                                                                                                                                                |
| `status_uri`                            | ステータスページのURLパス（例: `/@status`）。GitLab Pagesでヘルスチェックエンドポイントを有効にするには、この項目を設定します。                                                                                                                                                                                                                                                   |
| `tls_max_version`                       | 最大のTLSバージョン（「tls1.2」または「tls1.3」）を指定します。                                                                                                                                                                                                                                                  |
| `tls_min_version`                       | 最小のTLSバージョン（「tls1.2」または「tls1.3」）を指定します。                                                                                                                                                                                                                                                  |
| `use_http2`                             | HTTP2のサポートを有効にします。                                                                                                                                                                                                                                                                                      |
| **`gitlab_pages['env'][]`**             |                                                                                                                                                                                                                                                                                                            |
| `http_proxy`                            | PagesとGitLab間のトラフィックをHTTPプロキシが仲介するようにGitLab Pagesを設定します。Pagesデーモンの起動時に環境変数`http_proxy`を設定します。                                                                                                                                             |
| **`gitlab_rails[]`**                    |                                                                                                                                                                                                                                                                                                            |
| `pages_domain_verification_cron_worker` | カスタムGitLab Pagesドメインを検証するためのスケジュール。                                                                                                                                                                                                                                                        |
| `pages_domain_ssl_renewal_cron_worker`  | GitLab Pagesドメインに対してLet's Encryptを介してSSL証明書を取得および更新するためのスケジュール。                                                                                                                                                                                                       |
| `pages_domain_removal_cron_worker`      | 未検証のカスタムGitLab Pagesドメインを削除するためのスケジュール。                                                                                                                                                                                                                                              |
| `pages_path`                            | ページの保存先となるディスク上のディレクトリ。デフォルトは`GITLAB-RAILS/shared/pages`です。                                                                                                                                                                                                                     |
| **`pages_nginx[]`**                     |                                                                                                                                                                                                                                                                                                            |
| `enable`                                | NGINX内にPagesの仮想ホスト`server{}`ブロックを含めます。NGINXがトラフィックをPagesデーモンにプロキシするために必要です。たとえば[カスタムドメイン](_index.md#custom-domains)を使用して、Pagesデーモンがすべてのリクエストを直接受け取る場合は`false`に設定します。                                    |
| `FF_CONFIGURABLE_ROOT_DIR`              | [デフォルトフォルダーをカスタマイズ](../../user/project/pages/introduction.md#customize-the-default-folder)するための機能フラグ（デフォルトで有効）。                                                                                                                                                                |
| `FF_ENABLE_PLACEHOLDERS`                | 書き換え用の機能フラグ（デフォルトで有効）。詳細については、[書き換え](../../user/project/pages/redirects.md#rewrites)を参照してください。                                                                                                                                                                       |
| `rate_limit_source_ip`                  | 送信元IPごとのレート制限（秒あたりのリクエスト数）。この機能を無効にするには、`0`に設定します。                                                                                                                                                                                                             |
| `rate_limit_source_ip_burst`            | 送信元IPごとのレート制限（秒あたりに許容される最大バースト）。                                                                                                                                                                                                                                                 |
| `rate_limit_domain`                     | ドメインごとのレート制限（秒あたりのリクエスト数）。この機能を無効にするには、`0`に設定します。                                                                                                                                                                                                                |
| `rate_limit_domain_burst`               | ドメインごとのレート制限（秒あたりに許容される最大バースト）。                                                                                                                                                                                                                                                    |
| `rate_limit_tls_source_ip`              | 送信元IPごとのレート制限（秒あたりのTLS接続数）。この機能を無効にするには、`0`に設定します。                                                                                                                                                                                                      |
| `rate_limit_tls_source_ip_burst`        | 送信元IPごとのレート制限（TLS接続に対して秒あたりに許容される最大バースト）。                                                                                                                                                                                                                                 |
| `rate_limit_tls_domain`                 | ドメインごとのレート制限（秒あたりのTLS接続数）。この機能を無効にするには、`0`に設定します。                                                                                                                                                                                                         |
| `rate_limit_tls_domain_burst`           | ドメインごとのレート制限（TLS接続に対して秒あたりに許容される最大バースト）。                                                                                                                                                                                                                                    |
| `rate_limit_subnets_allow_list`         | すべてのレート制限を回避する必要があるIP範囲（サブネット）の許可リスト。例: `['1.2.3.4/24', '2001:db8::1/32']`。GitLab 17.3で[導入](https://gitlab.com/groups/gitlab-org/-/epics/14653)されました。 |
| `server_read_timeout`                   | リクエストヘッダーと本文の読み取りに許可される最大時間。タイムアウトなしにするには、`0`または負の値に設定します。デフォルト:`5s`                                                                                                                                                                                       |
| `server_read_header_timeout`            | リクエストヘッダーの読み取りに許可される最大時間。タイムアウトなしにするには、`0`または負の値に設定します。デフォルト:`1s`                                                                                                                                                                                                |
| `server_write_timeout`                  | 応答に含まれるすべてのファイルを書き込むために許可される最大時間。ファイルが大きいほど、より長い時間が必要です。タイムアウトなしにするには、`0`または負の値に設定します。デフォルト:`0`                                                                                                                                                          |
| `server_keep_alive`                     | このリスナーが受け付けたネットワーク接続の`Keep-Alive`の持続時間。`0`に設定すると、プロトコルとオペレーティングシステムがサポートしている場合に限り`Keep-Alive`が有効になります。負の値に設定すると、`Keep-Alive`は無効になります。デフォルト: `15s`                                                                                        |

## 高度な設定

ワイルドカードドメインに加えて、GitLab Pagesがカスタムドメインで動作するように設定することもできます。この場合も、カスタムドメインでTLS証明書を使用する、使用しないの2つのオプションがあります。最も簡単なセットアップは、TLS証明書を使用しない方法です。いずれの場合も、**セカンダリIP**が必要になります。IPv4アドレスだけでなくIPv6アドレスもある場合は、両方を使用できます。

### カスタムドメイン

前提要件:

- [ワイルドカードDNSの設定](#dns-configuration)
- セカンダリIP

この設定では、Pagesデーモンを実行しており、NGINXが引き続きデーモンにリクエストをプロキシしますが、デーモンは外部からのリクエストを受け取ることもできます。カスタムドメインは使用できますが、TLSはサポートしていません。

1. `/etc/gitlab/gitlab.rb`で、次のように設定します。

   ```ruby
   external_url "http://example.com" # external_url here is only for reference
   pages_external_url 'http://example.io' # Important: not a subdomain of external_url, so cannot be http://pages.example.com
   nginx['listen_addresses'] = ['192.0.2.1'] # The primary IP of the GitLab instance
   pages_nginx['enable'] = false
   gitlab_pages['external_http'] = ['192.0.2.2:80', '[2001:db8::2]:80'] # The secondary IPs for the GitLab Pages daemon
   ```

   IPv6を使用していない場合は、IPv6アドレスは省略できます。

1. [GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

この設定でアクセス可能になるURLスキームは、`http://<namespace>.example.io/<project_slug>`および`http://custom-domain.com`です。

### TLS対応のカスタムドメイン

前提要件:

- [ワイルドカードDNSの設定](#dns-configuration)
- TLS証明書。ワイルドカード証明書、または[要件](../../user/project/pages/custom_domains_ssl_tls_certification/_index.md#manual-addition-of-ssltls-certificates)を満たすその他の種類の証明書。
- セカンダリIP

この設定では、Pagesデーモンを実行しており、NGINXが引き続きデーモンにリクエストをプロキシしますが、デーモンは外部からのリクエストを受け取ることもできます。カスタムドメインとTLSをサポートしています。

1. `*.example.io`のワイルドカードTLS証明書とキーを`/etc/gitlab/ssl`内に配置します。
1. `/etc/gitlab/gitlab.rb`で、次のように設定します。

   ```ruby
   external_url "https://example.com" # external_url here is only for reference
   pages_external_url 'https://example.io' # Important: not a subdomain of external_url, so cannot be https://pages.example.com
   nginx['listen_addresses'] = ['192.0.2.1'] # The primary IP of the GitLab instance
   pages_nginx['enable'] = false
   gitlab_pages['external_http'] = ['192.0.2.2:80', '[2001:db8::2]:80'] # The secondary IPs for the GitLab Pages daemon
   gitlab_pages['external_https'] = ['192.0.2.2:443', '[2001:db8::2]:443'] # The secondary IPs for the GitLab Pages daemon
   # Redirect pages from HTTP to HTTPS
   gitlab_pages['redirect_http'] = true
   ```

   IPv6を使用していない場合は、IPv6アドレスは省略できます。

1. 証明書に`example.io.crt`、キーに`example.io.key`という名前を付けていない場合は、次のようにフルパスも指定する必要があります。

   ```ruby
   gitlab_pages['cert'] = "/etc/gitlab/ssl/example.io.crt"
   gitlab_pages['cert_key'] = "/etc/gitlab/ssl/example.io.key"
   ```

1. [GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。
1. [Pagesへのアクセス制御](#access-control)を使用している場合は、GitLab Pagesの[システムOAuthアプリケーション](../../integration/oauth_provider.md#create-an-instance-wide-application)のリダイレクトURIを更新して、HTTPSプロトコルを使用します。

この設定でアクセス可能になるURLスキームは、`https://<namespace>.example.io/<project_slug>`および`https://custom-domain.com`です。

### カスタムドメインの検証

悪意のあるユーザーが他人のドメインを乗っ取るのを防ぐために、GitLabは[カスタムドメインの検証](../../user/project/pages/custom_domains_ssl_tls_certification/_index.md#steps)をサポートしています。カスタムドメインを追加する際に、ユーザーはそのドメインのDNSレコードにGitLabが管理する検証コードを追加することで、そのドメインを所有していることを証明する必要があります。

{{< alert type="warning" >}}

ドメインの検証を無効にすることは安全ではなく、さまざまな脆弱性につながる可能性があります。*あえて*無効にする場合は、Pagesルートドメイン自体がセカンダリIPを指さないようにするか、ルートドメインをカスタムドメインとしてプロジェクトに追加してください。そうしないと、どのユーザーでもこのドメインをカスタムドメインとして自分のプロジェクトに追加できるようになります。

{{< /alert >}}

ユーザーベースがプライベートであるか信頼できる場合は、検証要件を無効にできます。

1. 左側のサイドバーの下部にある**管理者**を選択します。
1. **設定 > 設定**を選択します。
1. **Pages**を展開します。
1. **ユーザーにカスタムドメインの所有権を証明することを要求する**チェックボックスをオフにします。この設定はデフォルトで有効になっています。

### Let's Encryptのインテグレーション

[GitLab PagesのLet's Encryptのインテグレーション](../../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md)を使用すると、カスタムドメインで提供されるGitLab PagesサイトにLet's Encrypt SSL証明書を追加できます。

有効にするには、次の手順に従います。

1. 有効期限が近づいているドメインに関する通知を受信するメールアドレスを選択します。
1. 左側のサイドバーの下部にある**管理者**を選択します。
1. **設定 > 設定**を選択します。
1. **Pages**を展開します。
1. 通知を受信するメールアドレスを入力し、Let's Encryptの利用規約に同意します。
1. **変更を保存**を選択します。

### アクセス制御

GitLab Pagesへのアクセス制御はプロジェクトごとに設定でき、そのプロジェクトに対するユーザーのメンバーシップに基づいてPagesサイトへのアクセスを制御できます。

アクセス制御は、PagesデーモンをGitLabのOAuthアプリケーションとして登録することで機能します。認証されていないユーザーがプライベートPagesサイトにアクセスするリクエストを行うたびに、PagesデーモンはユーザーをGitLabにリダイレクトします。認証に成功すると、ユーザーはトークン付きでPagesにリダイレクトされ、そのトークンはCookieに保持されます。Cookieはシークレットキーで署名されているため、改ざんを検出できます。

プライベートサイトのリソースを表示する各リクエストは、そのトークンを使用してPagesによって認証されます。Pagesは受信したリクエストごとにGitLab APIにリクエストを送り、ユーザーにそのサイトを閲覧する権限があるかどうかを確認します。

Pagesへのアクセス制御はデフォルトで無効になっています。有効にするには、次の手順に従います。

1. `/etc/gitlab/gitlab.rb`で、この設定を有効にします。

   ```ruby
   gitlab_pages['access_control'] = true
   ```

1. [GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。
1. これで、ユーザーは[プロジェクトの設定](../../user/project/pages/pages_access_control.md)からアクセス制御を設定できるようになります。

{{< alert type="note" >}}

この設定をマルチノード環境で有効にするには、すべてのアプリノードとSidekiqノードに適用する必要があります。

{{< /alert >}}

#### 認証スコープを制限してPagesを使用する

デフォルトでは、Pagesデーモンは`api`スコープを使用して認証を行います。このスコープは設定可能です。たとえば、`/etc/gitlab/gitlab.rb`でスコープを`read_api`に制限するには、次のように設定します。

```ruby
gitlab_pages['auth_scope'] = 'read_api'
```

認証に使用するスコープは、GitLab PagesのOAuthアプリケーション設定と一致している必要があります。既存のアプリケーションのユーザーは、GitLab PagesのOAuthアプリケーションを変更する必要があります。これを行うには、次の手順に従います。

1. [アクセス制御](#access-control)を有効にします。
1. 左側のサイドバーの下部にある**管理者**を選択します。
1. **アプリケーション**を選択します。
1. **GitLab Pages**を展開します。
1. `api`スコープのチェックボックスをオフにして、必要なスコープのチェックボックス（`read_api`など）をオンにします。
1. **変更を保存**を選択します。

#### すべてのPagesサイトへの公開アクセスを無効にする

GitLabインスタンスでホストしているすべてのGitLab Pagesウェブサイトに対して、[アクセス制御](#access-control)を適用できます。これにより、認証済みユーザーのみがアクセスできるようになります。この設定は、個々のプロジェクトでユーザーが設定したアクセス制御をオーバーライドします。

これは、Pagesウェブサイトで公開される情報へのアクセスを、インスタンスのユーザーのみに制限するのに役立ちます。これを行うには、次の手順に従います。

1. 左側のサイドバーの下部にある**管理者**を選択します。
1. **設定 > 設定**を選択します。
1. **Pages**を展開します。
1. **Pagesサイトへの公開アクセスを無効にする**チェックボックスをオンにします。
1. **変更を保存**を選択します。

{{< alert type="note" >}}

この設定を**管理者**エリアに表示するには、まず[アクセス制御](#access-control)を有効にする必要があります。

{{< /alert >}}

### プロキシの背後で実行する

GitLabの他の機能と同様に、Pagesも外部インターネット接続がプロキシで制限されている環境で使用できます。GitLab Pagesにプロキシを使用するには、次の手順に従います。

1. `/etc/gitlab/gitlab.rb`で次のように設定します。

   ```ruby
   gitlab_pages['env']['http_proxy'] = 'http://example:8080'
   ```

1. 変更を有効にするには、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

### カスタム公開認証局（CA）を使用する

カスタムCAによって発行された証明書を使用する場合、そのカスタムCAが認識されないと、[アクセス制御](../../user/project/pages/pages_access_control.md)や[HTMLジョブアーティファクトのオンライン表示](../../ci/jobs/job_artifacts.md#download-job-artifacts)が機能しません。

その場合は通常、次のようなエラーが表示されます。`Post /oauth/token: x509: certificate signed by unknown authority`

Linuxパッケージインストールの場合、[カスタムCAをインストール](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates)することでこの問題を解決できます。

自己コンパイルによるインストールの場合、カスタム公開認証局（CA）をシステム証明書ストアにインストールすることでこの問題を解決できます。

### GitLab APIの呼び出し時に相互TLSをサポートする

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/548)されました。

{{< /history >}}

前提要件:

- Linuxパッケージを使用してインスタンスをインストールしている必要があります。

GitLabの[設定で相互TLSを必須にしている](https://docs.gitlab.com/omnibus/settings/ssl/#enable-2-way-ssl-client-authentication)場合は、GitLab Pagesの設定にクライアント証明書を追加する必要があります。

証明書には次の要件があります。

- 証明書には、ホスト名またはIPアドレスがSubject Alternative Name（サブジェクトの別名）として指定されている必要があります。
- エンドユーザー証明書、中間証明書、ルート証明書をこの順序で含む完全な証明書チェーンが必要です。

証明書の共通名フィールドは無視されます。

GitLab Pagesサーバーで証明書を設定するには、次の手順に従います。

1. GitLab Pagesノードで、`/etc/gitlab/ssl`ディレクトリを作成し、キーと完全な証明書チェーンをそこにコピーします。

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp key.pem cert.pem /etc/gitlab/ssl/
   sudo chmod 644 key.pem cert.pem
   ```

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_pages['client_cert'] = ['/etc/gitlab/ssl/cert.pem']
   gitlab_pages['client_key'] = ['/etc/gitlab/ssl/key.pem']
   ```

1. カスタム公開認証局（CA）を使用している場合は、ルートCA証明書を`/etc/gitlab/ssl`にコピーし、`/etc/gitlab/gitlab.rb`を編集する必要があります。

   ```ruby
   gitlab_pages['client_ca_certs'] = ['/etc/gitlab/ssl/ca.pem']
   ```

   複数のカスタム公開認証局（CA）のファイルパスは、カンマで区切って指定します。

1. マルチノードのGitLab Pagesインストール環境を使用している場合は、すべてのノードでこれらの手順を繰り返します。
1. すべてのGitLabノードの`/etc/gitlab/trusted-certs`ディレクトリに、完全な証明書チェーンファイルのコピーを保存します。

### ZIP配信とキャッシュ設定

{{< alert type="warning" >}}

以下の手順では、GitLabインスタンスにおけるいくつかの高度な設定を扱います。推奨されるデフォルト値は、GitLab Pages内に設定されています。これらの設定は、どうしても必要な場合にのみ変更してください。また、細心の注意を払って操作してください。

{{< /alert >}}

GitLab Pagesは、オブジェクトストレージを通じてZIPアーカイブのコンテンツを配信できます（ディスクストレージのサポートに関する[イシュー](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/485)もあります）。ZIPアーカイブからコンテンツを配信する際のパフォーマンスを向上させるため、インメモリキャッシュを使用しています。次の設定フラグを変更することで、このキャッシュの動作を変更できます。

| 設定 | 説明 |
| ------- | ----------- |
| `zip_cache_expiration` | ZIPアーカイブのキャッシュ有効期限の間隔。古いコンテンツの配信を避けるため、ゼロより大きい値を指定する必要があります。デフォルトは`60s`です。 |
| `zip_cache_cleanup` | 有効期限が切れたアーカイブをメモリから削除する間隔。デフォルトは`30s`です。 |
| `zip_cache_refresh` | `zip_cache_expiration`の期限内にアクセスがあった場合、メモリ内でそのアーカイブを延長する時間間隔。この設定と`zip_cache_expiration`を組み合わせて、アーカイブをメモリ内で延長するかどうかを判断します。重要な詳細については、[以下の例](#zip-cache-refresh-example)を参照してください。デフォルトは`30s`です。 |
| `zip_open_timeout` | ZIPアーカイブを開くことができる最大時間。アーカイブが大きい場合やネットワーク接続が遅い場合は、この時間を延ばしてください。Pagesの配信のレイテンシーに影響を与える可能性があります。デフォルトは30sです。 |
| `zip_http_client_timeout` | ZIP HTTPクライアントの最大タイムアウト時間。デフォルトは`30m`です。 |

#### ZIPキャッシュの更新例

アーカイブは、`zip_cache_expiration`の有効期限内にアクセスされ、有効期限が切れるまでの残り時間が`zip_cache_refresh`以下の場合、キャッシュ内で更新（メモリ内での保持時間が延長）されます。たとえば、`0s`の時点で`archive.zip`にアクセスされた場合、有効期限は`60s`（`zip_cache_expiration`のデフォルト）になります。以下の例では、`15s`後にアーカイブが再度開かれても、有効期限までの残り時間（`45s`）が`zip_cache_refresh`（デフォルトは`30s`）よりも長いため、更新**されません**。ただし、アーカイブが（最初に開いたときから）`45s`後に再度アクセスされた場合は、キャッシュが更新されます。これにより、メモリ内でのアーカイブの保持時間が`45s + zip_cache_expiration (60s)`に延長され、合計で`105s`になります。

アーカイブが`zip_cache_expiration`に達すると、期限切れとマークされ、次回の`zip_cache_cleanup`の間隔が経過するとメモリから削除されます。

![ZIPキャッシュの更新によってZIPキャッシュの有効期限が延長されることを示すタイムライン。](img/zip_cache_configuration_v13_7.png)

### HTTP Strict Transport Security（HSTS）のサポート

HTTP Strict Transport Security（HSTS）は、`gitlab_pages['headers']`設定オプションを使用して有効にできます。HSTSは、攻撃者が後続の接続で暗号化なしの状態を強制できないように、アクセスしているウェブサイトが常にHTTPS経由でコンテンツを提供する必要があることをブラウザに通知します。これにより、ブラウザがHTTPSにリダイレクトされる前に、暗号化されていないHTTPチャンネル経由で接続を試みるのを防ぐことができるため、ページの読み込み速度の向上にもつながります。

```ruby
gitlab_pages['headers'] = ['Strict-Transport-Security: max-age=63072000']
```

### Pagesプロジェクトのリダイレクト制限

{{< history >}}

- GitLab 15.2で[導入](https://gitlab.com/gitlab-org/gitlab-pages/-/merge_requests/778)されました。

{{< /history >}}

GitLab Pagesでは、パフォーマンスへの影響を最小限に抑えるため、[`_redirects`ファイル](../../user/project/pages/redirects.md)に一連のデフォルト制限が適用されています。制限を増減する必要がある場合は、これらの制限を変更できます。

```ruby
gitlab_pages['redirects_max_config_size'] = 131072
gitlab_pages['redirects_max_path_segments'] = 50
gitlab_pages['redirects_max_rule_count'] = 2000
```

## 環境変数を使用する

環境変数をPagesデーモンに渡すことができます（たとえば、機能フラグを有効または無効にするため）。

設定可能なディレクトリ機能を無効にするには、次の手順に従います。

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_pages['env'] = {
     'FF_CONFIGURABLE_ROOT_DIR' => "false"
   }
   ```

1. ファイルを保存して、GitLabを再設定します。

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## デーモンの冗長なログの生成を有効にする

GitLab Pagesデーモンの冗長なログの生成を設定するには、次の手順に従います。

1. デフォルトでは、デーモンは`INFO`レベルでのみログを生成します。`DEBUG`レベルでイベントをログに記録する場合は、`/etc/gitlab/gitlab.rb`で次のように設定する必要があります。

   ```ruby
   gitlab_pages['log_verbose'] = true
   ```

1. [GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

## 相関IDを伝播させる

`propagate_correlation_id`をtrueに設定すると、リバースプロキシの背後にあるインストール環境で、GitLab Pagesに送信されるリクエストに対して相関IDを生成し、設定できるようになります。リバースプロキシが`X-Request-ID`ヘッダーの値を設定すると、その値はリクエストチェーン内で伝播されます。ユーザーは[この相関IDをログで確認できます](../logs/tracing_correlation_id.md#identify-the-correlation-id-for-a-request)。

相関IDの伝播を有効にするには、次の手順に従います。

1. `/etc/gitlab/gitlab.rb`で、パラメータをtrueに設定します。

   ```ruby
   gitlab_pages['propagate_correlation_id'] = true
   ```

1. [GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

## ストレージパスを変更する

GitLab Pagesのコンテンツを保存するデフォルトのパスを変更するには、次の手順に従います。

1. ページはデフォルトで`/var/opt/gitlab/gitlab-rails/shared/pages`に保存されます。別の場所に保存する場合は、`/etc/gitlab/gitlab.rb`で設定する必要があります。

   ```ruby
   gitlab_rails['pages_path'] = "/mnt/storage/pages"
   ```

1. [GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

## リバースプロキシリクエストのリスナーを設定する

GitLab Pagesのプロキシリスナーを設定するには、次の手順に従います。

1. デフォルトでは、リスナーは`localhost:8090`でリクエストをリッスンするように設定されています。

   無効にする場合は、`/etc/gitlab/gitlab.rb`で次のように設定します。

   ```ruby
   gitlab_pages['listen_proxy'] = nil
   ```

   別のポートでリッスンする場合も、`/etc/gitlab/gitlab.rb`で次のように設定する必要があります。

   ```ruby
   gitlab_pages['listen_proxy'] = "localhost:10080"
   ```

1. [GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

## 各GitLab Pagesサイトのグローバルな最大サイズを設定する

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

プロジェクトのグローバルな最大ページサイズを設定するには、次の手順に従います。

1. 左側のサイドバーの下部にある**管理者**を選択します。
1. **設定 > 設定**を選択します。
1. **Pages**を展開します。
1. **ページの最大サイズ**に値を入力します。デフォルトは`100`です。
1. **変更を保存**を選択します。

## グループ内の各GitLab Pagesサイトの最大サイズを設定する

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

グループ内の各GitLab Pagesサイトの最大サイズを設定し、継承された設定をオーバーライドするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動**を選択し、グループを検索します。
1. **設定 > 一般**を選択します。
1. **Pages**を展開します。
1. **最大サイズ**に値をMB単位で入力します。
1. **変更を保存**を選択します。

## プロジェクト内のGitLab Pagesサイトの最大サイズを設定する

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

プロジェクト内のGitLab Pagesサイトの最大サイズを設定し、継承された設定をオーバーライドするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを検索します。
1. **デプロイ > Pages**を選択します。
1. **ページの最大サイズ**に、サイズをMB単位で入力します。
1. **変更を保存**を選択します。

## プロジェクトのGitLab Pagesカスタムドメインの最大数を設定する

前提要件:

- インスタンスへの管理者アクセス権が必要です。

プロジェクトのGitLab Pagesカスタムドメインの最大数を設定するには、次の手順に従います。

1. 左側のサイドバーの下部にある**管理者**を選択します。
1. **設定 > 設定**を選択します。
1. **Pages**を展開します。
1. **プロジェクトごとのカスタムドメインの最大数**に値を入力します。カスタムドメイン数を無制限にする場合は、`0`を入力します。
1. **変更を保存**を選択します。

## 並列デプロイのデフォルトの有効期限を設定する

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/456477)されました。

{{< /history >}}

前提要件:

- インスタンスへの管理者アクセス権が必要です。

[並列デプロイ](../../user/project/pages/_index.md#parallel-deployments)が削除されるまで、インスタンスのデフォルト期間を設定するには、次の手順に従います。

1. 左側のサイドバーの下部にある**管理者**を選択します。
1. **設定 > 設定**を選択します。
1. **Pages**を展開します。
1. **並列デプロイのデフォルトの有効期限（秒）**に値を入力します。並列デプロイをデフォルトで期限切れにしない場合は、`0`を入力します。
1. **変更を保存**を選択します。

## GitLab Pagesウェブサイトごとのファイル数の最大値を設定する

GitLab Pagesウェブサイトごとに、ファイルエントリ（ディレクトリやシンボリックリンクを含む）の総数は`200,000`に制限されています。

この制限は、GitLab Self-Managedインスタンスで[GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)を使用して更新できます。

詳細については、[GitLabのアプリケーションの制限](../instance_limits.md#number-of-files-per-gitlab-pages-website)を参照してください。

## 別のサーバーでGitLab Pagesを実行する

GitLab Pagesデーモンを別のサーバーで実行することで、メインアプリケーションサーバーの負荷を軽減できます。この設定は、相互TLS（mTLS）をサポートしていません。詳細については、[該当する機能提案](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/548)を参照してください。

別のサーバーでGitLab Pagesを設定するには、次の手順に従います。

{{< alert type="warning" >}}

次の手順には、`gitlab-secrets.json`ファイルのバックアップと編集が含まれています。このファイルには、データベースの暗号化を制御するシークレットが含まれているため、慎重に作業を進めてください。

{{< /alert >}}

1. 必要に応じて、[アクセス制御](#access-control)を有効にするには、`/etc/gitlab/gitlab.rb`に次の内容を追加し、[GitLabサーバーを**再設定**](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

   ```ruby
   gitlab_pages['access_control'] = true
   ```

   {{< alert type="warning" >}}

   アクセス制御を有効にした状態でGitLab Pagesを使用する予定がある場合は、最初のGitLabサーバーで有効にしてから、`gitlab-secrets.json`をコピーする必要があります。アクセス制御を有効にすると、新しいOAuthアプリケーションが生成され、その情報が`gitlab-secrets.json`に伝播されます。正しい順序で作業を行わないと、アクセス制御で問題が発生する可能性があります。

   {{< /alert >}}

1. **GitLabサーバー**でシークレットファイルのバックアップを作成します。

   ```shell
   cp /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.bak
   ```

1. **GitLabサーバー**でPagesを有効にするには、`/etc/gitlab/gitlab.rb`に次の内容を追加します。

   ```ruby
   pages_external_url "http://<pages_server_URL>"
   ```

1. 次のいずれかの方法でオブジェクトストレージを設定します。
   - [オブジェクトストレージを設定し、GitLab Pagesのデータを移行する。](#object-storage-settings)
   - [ネットワークストレージを設定する。](#enable-pages-network-storage-in-multi-node-environments)

1. 変更を有効にするには、[**GitLabサーバー**を再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。これで、`gitlab-secrets.json`ファイルが新しい設定で更新されました。

1. 新しいサーバーを設定します。これが**Pagesサーバー**になります。

1. **Pagesサーバー**で、Linuxパッケージを使用してGitLabをインストールし、`/etc/gitlab/gitlab.rb`を次のように変更します。

   ```ruby
   roles ['pages_role']

   pages_external_url "http://<pages_server_URL>"

   gitlab_pages['gitlab_server'] = 'http://<gitlab_server_IP_or_URL>'

   ## If access control was enabled on step 3
   gitlab_pages['access_control'] = true
   ```

1. **GitLabサーバー**でカスタムUID/GIDを設定している場合は、**Pagesサーバー**の`/etc/gitlab/gitlab.rb`にも同じ設定を追加してください。そうしないと、**GitLabサーバー**で`gitlab-ctl reconfigure`を実行した際に、ファイルの所有権が変更され、Pagesリクエストが失敗する原因になります。

1. **Pagesサーバー**でシークレットファイルのバックアップを作成します。

   ```shell
   cp /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.bak
   ```

1. `/etc/gitlab/gitlab-secrets.json`ファイルを**GitLabサーバー**から**Pagesサーバー**にコピーします。

   ```shell
   # On the GitLab server
   cp /etc/gitlab/gitlab-secrets.json /mnt/pages/gitlab-secrets.json

   # On the Pages server
   mv /var/opt/gitlab/gitlab-rails/shared/pages/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json
   ```

1. 変更を有効にするには、[**Pagesサーバー**を再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

1. **GitLabサーバー**で、`/etc/gitlab/gitlab.rb`を次のように変更します。

   ```ruby
   pages_external_url "http://<pages_server_URL>"
   gitlab_pages['enable'] = false
   pages_nginx['enable'] = false
   ```

1. 変更を有効にするには、[**GitLabサーバー**を再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

負荷を分散させたい場合は、複数のサーバーでGitLab Pagesを実行できます。これを実現するには、DNSサーバーを設定してPagesサーバーの複数のIPを返すようにするか、IPレベルで動作するようにロードバランサーを設定するなど、標準的なロードバランシング手法を使用します。複数のサーバーでGitLab Pagesをセットアップする場合は、各Pagesサーバーに対して上記の手順を実行してください。

## ドメインソース設定

GitLab Pagesデーモンがページリクエストを処理する際、まず、そのリクエストのURLに対応するプロジェクトと、そのコンテンツがどのように保存されているかを特定する必要があります。

デフォルトでは、GitLab Pagesは新しいドメインがリクエストされるたびに、内部のGitLab APIを使用します。APIに接続できない場合、Pagesは起動に失敗します。また、後続のリクエストを高速化するために、Pagesデーモンはドメイン情報をキャッシュします。

一般的な問題については、[トラブルシューティング](troubleshooting.md#failed-to-connect-to-the-internal-gitlab-api)を参照してください。

詳細については、こちらの[ブログ投稿](https://about.gitlab.com/blog/2020/08/03/how-gitlab-pages-uses-the-gitlab-api-to-serve-content/)を参照してください。

### GitLab APIキャッシュ設定

APIベースの設定では、Pagesの配信のパフォーマンスと信頼性を高めるために、キャッシュメカニズムを使用します。キャッシュの動作はキャッシュ設定を変更することで調整できます。ただし、推奨値があらかじめ設定されているため、必要な場合にのみ変更することが推奨されます。これらの値を誤って設定すると、断続的または永続的なエラーが発生したり、Pagesデーモンが古いコンテンツを配信したりする可能性があります。

{{< alert type="note" >}}

有効期限、間隔、タイムアウトの各フラグは、[Goのduration形式](https://pkg.go.dev/time#ParseDuration)で指定します。duration文字列は、符号付き10進数に、それぞれオプションの小数および単位サフィックスが付きます。例: `300ms`、`1.5h`、`2h45m`など。有効な時間単位は、`ns`、`us`（または`µs`）、`ms`、`s`、`m`、`h`です。

{{< /alert >}}

例:

- `gitlab_cache_expiry`を増やすと、キャッシュ内のアイテムがより長く保持されます。この設定は、GitLab PagesとGitLab Rails間の通信が安定していない場合に役立つことがあります。
- `gitlab_cache_refresh`を増やすと、GitLab PagesがGitLab Railsに対してドメインの設定情報をリクエストする頻度が減ります。この設定は、GitLab PagesがGitLab APIに対するリクエストを過剰に生成する場合や、コンテンツが頻繁には変更されない場合に有用です。
- `gitlab_cache_cleanup`を減らすと、期限切れのアイテムがより頻繁にキャッシュから削除され、Pagesノードのメモリ使用量が削減されます。
- `gitlab_retrieval_timeout`を減らすと、GitLab Railsへのリクエストをより迅速に停止できます。増やすと、APIからの応答を受信するまでの待機時間が長くなり、低速なネットワーク環境で役立ちます。
- `gitlab_retrieval_interval`を減らすと、APIからエラー（接続タイムアウトなど）が返された場合にのみ、APIへのリクエストがより頻繁に行われます。
- `gitlab_retrieval_retries`を減らすと、エラーを報告する前にドメインの設定を自動的に解決しようとする試行回数が少なくなります。

## オブジェクトストレージ設定

以下の[オブジェクトストレージ](../object_storage.md)設定では、次のようになります。

- 自己コンパイルによるインストールでは、設定は`pages:`の下の`object_store:`にネストされます。
- Linuxパッケージのインストールでは、プレフィックスとして`pages_object_store_`が付きます。

| 設定 | 説明 | デフォルト |
|---------|-------------|---------|
| `enabled` | オブジェクトストレージが有効かどうかを指定します。 | `false` |
| `remote_directory` | Pagesサイトのコンテンツを保存するバケットの名前。 | |
| `connection` | 以下に説明するさまざまな接続オプション。 | |

{{< alert type="note" >}}

NFSサーバーの使用を停止して切断する場合は、[ローカルストレージを明示的に無効にする](#disable-pages-local-storage)必要があります。

{{< /alert >}}

### S3互換接続設定

[統合されたオブジェクトストレージ設定](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)を使用する必要があります。

[プロバイダーごとの使用可能な接続設定](../object_storage.md#configure-the-connection-settings)を参照してください。

### Pagesデプロイをオブジェクトストレージに移行する

既存のPagesデプロイオブジェクト（zipアーカイブ）は、次のいずれかに保存できます。

- ローカルストレージ
- [オブジェクトストレージ](../object_storage.md)

既存のPagesデプロイをローカルストレージからオブジェクトストレージに移行するには、次のコマンドを実行します。

```shell
sudo gitlab-rake gitlab:pages:deployments:migrate_to_object_storage
```

[PostgreSQLコンソール](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-bundled-postgresql-database)を使用して、進行状況を追跡し、すべてのPagesデプロイを正常に移行したことを確認できます。

- Linuxパッケージインストールの場合: `sudo gitlab-rails dbconsole --database main`
- 自己コンパイルによるインストールの場合: `sudo -u git -H psql -d gitlabhq_production`

以下の`objectstg`（`store=2`）が、すべてのPagesデプロイの数と一致することを確認します。

```shell
gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM pages_deployments;

total | filesystem | objectstg
------+------------+-----------
   10 |          0 |        10
```

すべてが正しく動作していることを確認したら、[Pagesのローカルストレージを無効にします](#disable-pages-local-storage)。

### Pagesデプロイをローカルストレージにロールバックする

オブジェクトストレージへの移行を実行した後、Pagesデプロイをローカルストレージに戻すことができます。

```shell
sudo gitlab-rake gitlab:pages:deployments:migrate_to_local
```

### Pagesローカルストレージを無効にする

[オブジェクトストレージ](#object-storage-settings)を使用する場合は、不要なディスクの使用や書き込みを防ぐため、ローカルストレージを無効にできます。

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_rails['pages_local_store_enabled'] = false
   ```

1. 変更を有効にするには、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

## マルチノード環境でPagesのネットワークストレージを有効にする

オブジェクトストレージは、ほとんどの環境において推奨される設定です。ただし、要件によってネットワークストレージが必要であり、[別のサーバー](#running-gitlab-pages-on-a-separate-server)でPagesを実行する必要がある場合は、次の手順に従います。

1. 使用する予定の共有ストレージボリュームが、プライマリサーバーと目的のPagesサーバーの両方にすでにマウントされ、使用可能であることを確認します。
1. 各ノードの`/etc/gitlab/gitlab.rb`に、次の設定を追加します。

   ```ruby
   gitlab_pages['enable_disk'] = true
   gitlab_rails['pages_path'] = "/var/opt/gitlab/gitlab-rails/shared/pages" # Path to your network storage
   ```

1. Pagesを別のサーバーに切り替えます。

別のサーバーでPagesの設定が正常に完了した後、共有ストレージボリュームへのアクセスが必要なのはそのサーバーのみとなります。将来的に単一ノード環境へ移行する可能性を考慮し、共有ストレージボリュームはプライマリサーバーに引き続きマウントしておくことを検討してください。

## ZIPストレージ

GitLab Pagesの基盤となるストレージ形式は、プロジェクトごとに1つのZIPアーカイブです。

これらのZIPアーカイブは、ローカルのディスクストレージ、または[オブジェクトストレージ](#object-storage-settings)（設定している場合）に保存できます。

Pagesサイトが更新されるたびに、ZIPアーカイブが保存されます。

## バックアップ

GitLab Pagesは[標準のバックアップ](../backup_restore/_index.md)に含まれているため、個別のバックアップ設定はありません。

## セキュリティ

XSS攻撃を防ぐために、GitLab PagesをGitLabとは異なるホスト名で実行することを強くおすすめします。

### レート制限

{{< history >}}

- GitLab 17.3で[変更](https://gitlab.com/groups/gitlab-org/-/epics/14653)され、サブネットをPagesのレート制限から除外できるようになりました。

{{< /history >}}

サービス拒否（DoS）攻撃のリスクを最小限に抑えるために、レート制限を適用できます。GitLab Pagesは、[トークンバケットアルゴリズム](https://en.wikipedia.org/wiki/Token_bucket)を使用してレート制限を実施しています。デフォルトでは、指定された制限を超えたリクエストまたはTLS接続は報告され、拒否されます。

GitLab Pagesでは、次の種類のレート制限をサポートしています。

- `source_ip`ごと: 1つのクライアントIPアドレスごとに、許可されるリクエストまたはTLS接続の数を制限します。
- `domain`ごと: GitLab Pagesでホストしているドメインごとに、許可されるリクエストまたはTLS接続の数を制限します。`example.com`のようなカスタムドメインや、`group.gitlab.io`のようなグループドメインが対象となります。

HTTPリクエストベースのレート制限は、以下の設定を使用して適用されます。

- `rate_limit_source_ip`: クライアントIPごとに、1秒あたりのリクエスト数の最大しきい値を設定します。この機能を無効にするには、0に設定します。
- `rate_limit_source_ip_burst`: クライアントIPごとに、リクエストが一度に多数発生する初期のタイミングで許可されるリクエスト数の最大しきい値を設定します。たとえば、複数のリソースを同時に読み込むウェブページを読み込む場合などです。
- `rate_limit_domain`: ホストしているPagesドメインごとに、1秒あたりのリクエスト数の最大しきい値を設定します。この機能を無効にするには、0に設定します。
- `rate_limit_domain_burst`: ホストしているPagesドメインごとに、リクエストが一度に多数発生する初期のタイミングで許可されるリクエスト数の最大しきい値を設定します。

TLS接続ベースのレート制限は、以下の設定を使用して適用されます。

- `rate_limit_tls_source_ip`: クライアントIPごとに、1秒あたりのTLS接続数の最大しきい値を設定します。この機能を無効にするには、0に設定します。
- `rate_limit_tls_source_ip_burst`: クライアントIPごとに、TLS接続が一度に多数発生する初期のタイミングで許可されるTLS接続数の最大しきい値を設定します。たとえば、異なるウェブブラウザから同時にウェブページを読み込む場合などです。
- `rate_limit_tls_domain`: ホストしているPagesドメインごとに、1秒あたりのTLS接続数の最大しきい値を設定します。この機能を無効にするには、0に設定します。
- `rate_limit_tls_domain_burst`: ホストしているPagesドメインごとに、TLS接続が一度に多数発生する初期のタイミングで許可されるTLS接続数の最大しきい値を設定します。

特定のIP範囲（サブネット）がすべてのレート制限を回避できるようにするには、次の手順に従います。

- `rate_limit_subnets_allow_list`: すべてのレート制限を回避させるIP範囲（サブネット）を指定する許可リストを設定します。例: `['1.2.3.4/24', '2001:db8::1/32']`。[チャートの例はこちら](https://docs.gitlab.com/charts/charts/gitlab/gitlab-pages/#configure-rate-limits-subnets-allow-list)をご覧ください。

IPv6アドレスには、128ビットのアドレス空間の中で大きなプレフィックスが割り当てられます。通常、プレフィックス長は少なくとも/64です。使用可能なアドレス数が多いため、クライアントのIPアドレスがIPv6の場合、IPv6アドレス全体ではなく、長さ64のIPv6プレフィックスに対して制限が適用されます。

#### 送信元IPごとのHTTPリクエストのレート制限を有効にする

1. `/etc/gitlab/gitlab.rb`に、次のようにレート制限を設定します。

   ```ruby
   gitlab_pages['rate_limit_source_ip'] = 20.0
   gitlab_pages['rate_limit_source_ip_burst'] = 600
   ```

1. [GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

#### ドメインごとのHTTPリクエストのレート制限を有効にする

1. `/etc/gitlab/gitlab.rb`に、次のようにレート制限を設定します。

   ```ruby
   gitlab_pages['rate_limit_domain'] = 1000
   gitlab_pages['rate_limit_domain_burst'] = 5000
   ```

1. [GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

#### 送信元IPごとのTLS接続のレート制限を有効にする

1. `/etc/gitlab/gitlab.rb`に、次のようにレート制限を設定します。

   ```ruby
   gitlab_pages['rate_limit_tls_source_ip'] = 20.0
   gitlab_pages['rate_limit_tls_source_ip_burst'] = 600
   ```

1. [GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

#### ドメインごとのTLS接続のレート制限を有効にする

1. `/etc/gitlab/gitlab.rb`に、次のようにレート制限を設定します。

   ```ruby
   gitlab_pages['rate_limit_tls_domain'] = 1000
   gitlab_pages['rate_limit_tls_domain_burst'] = 5000
   ```

1. [GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

## 関連トピック

- [GitLab Pagesの管理のトラブルシューティング](troubleshooting.md)
