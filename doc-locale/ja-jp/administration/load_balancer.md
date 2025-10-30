---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 【マルチノード】GitLab用のロードバランサー
description: マルチノードインスタンスでロードバランサーを使用します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

マルチノード構成のGitLabでは、ロードバランサーを使用して、トラフィックをアプリケーションサーバーにルーティングする必要があります。どのロードバランサーを使用するか、またはその正確な設定に関する詳細は、GitLabドキュメントのスコープ外です。GitLabのようなHAシステムを管理している場合は、すでに使用するロードバランサーを選択していることを期待します。HAProxy（オープンソース）、F5 Big-IP LTM、Citrix NetScalerなどの例があります。このドキュメントでは、GitLabで使用するポートとプロトコルについて説明します。

## SSL {#ssl}

マルチノード環境でSSLをどのように処理しますか？次のようないくつかの選択肢があります:

- 各アプリケーションノードがSSLを終端します。
- ロードバランサーはSSLを終端し、ロードバランサーとアプリケーションノード間の通信は安全ではありません
- ロードバランサーはSSLを終端し、ロードバランサーとアプリケーションノード間の通信は安全です

### アプリケーションノードはSSLを終端します {#application-nodes-terminate-ssl}

ロードバランサーがポート443の接続を「HTTP(S)」プロトコルではなく「TCP」として渡すように設定します。これにより、接続はアプリケーションノードのNGINXサービスにそのまま渡されます。NGINXにはSSL証明書があり、ポート443をリッスンします。

SSL証明書の管理とNGINXの設定の詳細については、[HTTPSのドキュメント](https://docs.gitlab.com/omnibus/settings/ssl/)を参照してください。

### ロードバランサーはバックエンドSSLなしでSSLを終端します {#load-balancers-terminate-ssl-without-backend-ssl}

`TCP`ではなく、`HTTP(S)`プロトコルを使用するようにロードバランサーを設定します。ロードバランサーは、SSL証明書の管理とSSLの終端処理を担当します。

ロードバランサーとGitLab間の通信が安全ではなくなるため、追加の設定が必要となります。詳細については、[プロキシSSLのドキュメント](https://docs.gitlab.com/omnibus/settings/ssl/#configure-a-reverse-proxy-or-load-balancer-ssl-termination)を参照してください。

### ロードバランサーはバックエンドSSLありでSSLを終端します {#load-balancers-terminate-ssl-with-backend-ssl}

`TCP`ではなく、`HTTP(S)`プロトコルを使用するようにロードバランサーを設定します。ロードバランサーは、エンドユーザーに表示されるSSL証明書の管理を担当します。

このシナリオでは、ロードバランサーとNGINX間のトラフィックも安全になります。接続は常に安全であるため、プロキシーSSLの設定を追加する必要はありません。ただし、SSL証明書を設定するには、GitLabに設定を追加する必要があります。SSL証明書の管理とNGINXの設定の詳細については、[HTTPSのドキュメント](https://docs.gitlab.com/omnibus/settings/ssl/)を参照してください。

## ポート {#ports}

### 基本ポート {#basic-ports}

| LBポート | バックエンドポート | プロトコル                 |
| ------- | ------------ | ------------------------ |
| 80      | 80           | HTTP（*1*）               |
| 443     | 443          | TCPまたはHTTPS（*1*）（*2*） |
| 22      | 22           | TCP                      |

- （*1*）: [Web端末](../ci/environments/_index.md#web-terminals-deprecated)のサポートでは、ロードバランサーがWebSocket接続を正しく処理する必要があります。HTTPまたはHTTPSプロキシを使用する場合、これは、`Connection`および`Upgrade`のホップバイホップヘッダーを通過するようにロードバランサーを設定する必要があることを意味します。詳細については、[Web端末](integration/terminal.md)インテグレーションガイドを参照してください。
- （*2*）: ポート443にHTTPSプロトコルを使用する場合は、ロードバランサーにSSL証明書を追加する必要があります。代わりにGitLabアプリケーションサーバーでSSLを終了する場合は、TCPプロトコルを使用します。

### GitLab Pagesのポート {#gitlab-pages-ports}

カスタムドメインサポートでGitLab Pagesを使用している場合は、いくつかの追加ポート設定が必要になります。GitLabページには、個別の仮想IPアドレスが必要です。新しい仮想IPアドレスで、`/etc/gitlab/gitlab.rb`から`pages_external_url`を指すようにDNSを設定します。詳細については、[GitLab Pagesのドキュメント](pages/_index.md)を参照してください。

| LBポート | バックエンドポート  | プロトコル  |
| ------- | ------------- | --------- |
| 80      | 変動（*1*）  | HTTP      |
| 443     | 変動（*1*）  | TCP（*2*） |

- （*1*）: GitLab Pagesのバックエンドポートは、`gitlab_pages['external_http']`および`gitlab_pages['external_https']`の設定によって異なります。詳細については、[GitLab Pagesのドキュメント](pages/_index.md)を参照してください。
- （*2*）: GitLab Pagesのポート443では、常にTCPプロトコルを使用する必要があります。ユーザーはカスタムSSLでカスタムドメインを設定できますが、SSLがロードバランサーで終了した場合、この設定は不可能です。

### 代替SSHポート {#alternate-ssh-port}

一部の組織には、SSHポート22を開くことについてポリシーがあります。この場合、ユーザーがポート443でSSHを使用できるようにする代替SSHホスト名を設定すると役立つ場合があります。前述の他のGitLab HTTP設定と比較した場合、代替SSHホスト名には、新しい仮想IPアドレスが必要になります。

`altssh.gitlab.example.com`などの代替SSHホスト名のDNSを設定します。

| LBポート | バックエンドポート | プロトコル |
| ------- | ------------ | -------- |
| 443     | 22           | TCP      |

## 準備完了チェック {#readiness-check}

マルチノードデプロイでは、ロードバランサーが[ヘルスチェック](monitoring/health_check.md#readiness)を使用して、トラフィックをルーティングする前に、ノードがトラフィックを受け入れる準備ができていることを確認することを強くお勧めします。これは、Pumaを使用している場合に特に重要です。Pumaは再起動中にリクエストを受け入れない期間があるためです。

{{< alert type="warning" >}}

GitLabバージョン15.4～15.8のreadiness checkで`all=1`パラメータを使用すると、[Praefectメモリ使用量が増加](https://gitlab.com/gitlab-org/gitaly/-/issues/4751)し、メモリエラーが発生する可能性があります。

{{< /alert >}}

## トラブルシューティング {#troubleshooting}

### ヘルスチェックがロードバランサー経由で`408` HTTP code>コードを返しています {#the-health-check-is-returning-a-408-http-code-via-the-load-balancer}

GitLab 15.0以降に[AWS Classic Load Balancer](https://docs.aws.amazon.com/en_en/elasticloadbalancing/latest/classic/elb-ssl-security-policy.html#ssl-ciphers)を使用している場合は、NGINXで`AES256-GCM-SHA384`暗号化を有効にする必要があります。詳細については、[NGINXでAES256-GCM-SHA384 SSL暗号がデフォルトで許可されなくなった](../update/versions/gitlab_15_changes.md#1500)を参照してください。

GitLabバージョンのデフォルトの暗号は、[`files/gitlab-cookbooks/gitlab/attributes/default.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/gitlab/attributes/default.rb)ファイルで確認でき、ターゲットGitLabバージョン（例：`15.0.5+ee.0`）に対応するGitタグ付けを選択します。ロードバランサーで必要な場合は、NGINXの[カスタムSSL暗号](https://docs.gitlab.com/omnibus/settings/ssl/#use-custom-ssl-ciphers)を定義できます。

### 一部のページとリンクがブラウザでレンダリングされずにダウンロードされる {#some-pages-and-links-are-downloaded-instead-of-rendered-in-the-browser}

一部のGitLab機能では、WebSocketsの使用が必要です。ロードバランサーでWebSocketsサポートが有効になっていないシナリオでは、一部のリンクまたはページがブラウザでレンダリングされずにダウンロードされることがあります。ダウンロードされたファイルには、次のようなコンテンツが含まれている場合があります:

```plaintext
One or more reserved bits are on: reserved1 = 1, reserved2 = 0, reserved3 = 0
```

ロードバランサーは、HTTP WebSocketリクエストをサポートできる必要があります。リンクがこのようにダウンロードされる場合は、ロードバランサーの設定をチェックインし、HTTP WebSocketリクエストが有効になっていることを確認してください。
