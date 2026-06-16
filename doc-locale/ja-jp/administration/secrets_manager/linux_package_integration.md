---
stage: Sec
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: LinuxパッケージデプロイのGitLab向けOpenBaoをインストールする
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 19.0でベータ機能として[導入](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/9669)されました。

{{< /history >}}

LinuxパッケージでインストールされたGitLabインスタンスと連携してOpenBaoをKubernetesクラスターで使用します。OpenBaoはクラスターで動作し、PostgreSQLデータベースに接続します。GitLab RailsとSidekiqはHTTPS経由でOpenBaoに接続します。

OpenBaoを次の2つの方法のいずれかで実行します:

- **Colocated cluster**: ローカルのKubernetesディストリビューション（k3sなど）は、Linuxパッケージインスタンスと同じホストで実行されます。LinuxパッケージにバンドルされたNGINXは、OpenBaoの外部URLのTLS終端リバースプロキシとして機能します。GitLabアプリケーションは、Kubernetesが共有ネットワーク上で公開するエンドポイントを介してOpenBaoに接続します。
- **External Kubernetes cluster**: OpenBaoは別のKubernetesクラスターで実行されます。クラスターのIngressとTLS終端を設計します。GitLab RailsとSidekiqは、公開するOpenBao URLに接続します。マルチノードのLinuxパッケージデプロイを使用している場合や、クラウドプロバイダーのマネージドKubernetesサービスの使用を希望する場合は、このアプローチを検討してください。

> [!note]
> Linuxパッケージ管理の[PostgreSQLクラスター](../postgresql/replication_and_failover.md)は、OpenBaoデータベースのバックエンドとしてサポートされていません。GitLabにそのようなクラスターを使用する場合は、OpenBao用に個別のPostgreSQLインスタンスをプロビジョニングしてください。これはセルフマネージドまたはマネージドクラウドデータベースサービスとして提供されます。詳細については、[イシュー7292](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/7292)を参照してください。

## 前提条件 {#prerequisites}

{{< tabs >}}

{{< tab title="コロケートクラスター" >}}

- LinuxパッケージでインストールされたGitLab 19.0以降、および管理者アクセス。
- 同じホストにインストールされたローカルのKubernetesディストリビューション。
- ホストで`helm`と`kubectl`が利用可能です。
- OpenBaoドメインをホストのパブリックIPアドレスにポイントするDNSレコード。

{{< /tab >}}

{{< tab title="外部クラスター" >}}

- LinuxパッケージでインストールされたGitLabインスタンス、および管理者アクセス。
- Linuxパッケージインスタンスノードからアクセス可能な外部Kubernetesクラスター。
- `helm`と`kubectl`がクラスターにアクセスするように設定されています。
- OpenBaoドメインをクラスターIngress IPアドレスにポイントするDNSレコード。

{{< /tab >}}

{{< /tabs >}}

## 要件 {#requirements}

{{< tabs >}}

{{< tab title="コロケートクラスター" >}}

OpenBaoをインストールする前に、お使いのKubernetesディストリビューションが以下の要件を満たしていることを確認してください:

- [OpenBaoサイジング推奨事項](_index.md#sizing-recommendations)は、Linuxパッケージインスタンスの要件とKubernetesクラスターの要件に加えて満たされる必要があります。
- コロケートされたKubernetesのいかなるものも、GitLabによってすでに使用されているポートにアタッチしようとしないでください。多くの小規模なKubernetesディストリビューションは、デフォルトでポート80と443にバインドするロードバランサーをインストールします。Linuxパッケージ管理のNGINXはすでにそれらのポートでリッスンしているため、そのようなコンポーネントを無効にします。
- コロケートされたKubernetesは、Linuxパッケージインスタンスとネットワークを共有する必要があります。これにより、Linuxパッケージ管理のNGINXが外部OpenBaoトラフィックをOpenBaoサービスにルーティングし、そこからのリクエストをリッスンできるようになります。Linuxパッケージインスタンスは、サービスがKubernetes `LoadBalancer`または`NodePort`を介して公開されているかどうかを気にしません。両方が共有ネットワーク内で到達可能である限り問題ありません。

{{< /tab >}}

{{< tab title="外部クラスター" >}}

OpenBaoをインストールする前に、セットアップが以下の要件を満たしていることを確認してください:

- [OpenBaoサイジング推奨事項](_index.md#sizing-recommendations)は、お使いのKubernetesクラスターによって満たされる必要があります。
- クラスター内のOpenBaoポッドとLinuxパッケージインスタンスノードとの間にネットワーク接続が存在する必要があります。この接続を確立する方法は、インフラストラクチャによって異なります。例えば、VPCピアリング、共有VPC、またはファイアウォールルールを使用する場合があります。GitLab RailsとSidekiqは、クラスターから公開するOpenBao URLに到達できる必要があります。
- Linuxパッケージ管理のPostgreSQLをOpenBaoデータベースとして使用する場合、PostgreSQLノードはクラスターポッドCIDRからのTCP接続を受け入れる必要があります。このトラフィックをデータベースポートで許可するようにファイアウォールまたはセキュリティグループルールを設定します。

{{< /tab >}}

{{< /tabs >}}

## はじめる前 {#before-you-begin}

{{< tabs >}}

{{< tab title="コロケートクラスター" >}}

はじめる前:

1. Kubernetes CNI（ポッドネットワーク）のCIDRを収集します。PostgreSQLの認証を設定するために後で必要になります。
1. LinuxパッケージインスタンスとKubernetes間で共有されるネットワークインターフェースのIPアドレス（`<SHARED_NETWORK_IP>`）を収集します。いくつかの設定値のために後で必要になります。
1. OpenBaoのインストールを試みる前に、お使いのKubernetesディストリビューションが完全に稼働していることを確認してください。
1. `kubectl`コンテキストがこのクラスターに設定されていること（`KUBECONFIG`が正しく設定されていること）を確認します。

{{< /tab >}}

{{< tab title="外部クラスター" >}}

はじめる前:

1. KubernetesポッドネットワークのCIDRを収集します。PostgreSQLの認証を設定するために後で必要になります。
1. OpenBaoが使用するPostgreSQLインスタンスのアドレス（`<POSTGRES_ADDRESS>`）を収集します。これは、LinuxパッケージPostgreSQLノードのIPアドレス、または外部またはマネージドPostgreSQLインスタンスのエンドポイントのいずれかです。
1. OpenBaoのインストールを試みる前に、お使いのKubernetesクラスターが完全に稼働していることを確認してください。
1. `kubectl`コンテキストがこのクラスターに設定されていること（`KUBECONFIG`が正しく設定されていること）を確認します。

{{< /tab >}}

{{< /tabs >}}

## OpenBao PostgreSQLデータベースをプロビジョニングする {#provision-the-openbao-postgresql-database}

> [!note]
> `gitlab-psql`は、Linuxパッケージ管理のPostgreSQLを使用している場合にのみ利用可能です。代わりに外部またはマネージドPostgreSQLインスタンスを使用する場合は、そのインスタンスで同等のSQLコマンドを実行します。ユーザーとデータベースの作成ロジックは同じです。

`gitlab-psql`はUnixソケット経由で接続し、TCPリスナーを必要としないため、`gitlab-ctl reconfigure`を実行する前にこれらのコマンドを実行できます。

OpenBao PostgreSQLデータベースをプロビジョニングするには:

1. OpenBaoデータベースユーザーに強力なパスワードを選択してください。このセクションの最後のステップで、Kubernetesシークレットにこの同じパスワードを使用します。

1. OpenBaoデータベースユーザーを作成します:

   ```shell
   sudo gitlab-psql \
     -c "CREATE USER openbao WITH PASSWORD '<strong-password>';"
   ```

1. OpenBaoデータベースを作成します:

   ```shell
   sudo gitlab-psql \
     -c "CREATE DATABASE openbao OWNER openbao;"
   ```

1. Kubernetesネームスペースと、データベースパスワードをHelmチャートに渡すシークレットを作成します:

   ```shell
   kubectl create namespace openbao

   kubectl create secret generic openbao-db-secret \
     --namespace openbao \
     --from-literal=password='<strong-password>'
   ```

## Helmを使用してOpenBaoをインストールする {#install-openbao-by-using-helm}

{{< tabs >}}

{{< tab title="コロケートクラスター" >}}

Helmを使用してOpenBaoをインストールするには:

1. GitLab Helmリポジトリを追加します。

   ```shell
   helm repo add gitlab https://charts.gitlab.io
   helm repo update
   ```

1. プレースホルダーの値を実際のドメインとIPアドレスに置き換えて、以下の内容で`openbao-values.yaml`ファイルを作成します:

   ```yaml
   config:
     ui: false
     storage:
       postgresql:
         haEnabled: true
         connection:
           host: "<SHARED_NETWORK_IP>"
           port: 5432
           database: openbao
           username: openbao
           sslMode: "disable"
           password:
             secret: openbao-db-secret
             key: password
     initialize:
       enabled: true
       oidcDiscoveryUrl: "https://<GITLAB_DOMAIN>"
       boundIssuer: "https://<GITLAB_DOMAIN>"
       boundAudiences: '"https://<OPENBAO_DOMAIN>"'

   gatewayRoute:
     enabled: false
   ```

1. OpenBaoをインストールします:

   ```shell
   helm upgrade --install openbao gitlab/openbao \
     --namespace openbao \
     --values openbao-values.yaml
   ```

   ポッドがPostgreSQLに接続できないため、`--wait`を使用しないでください。PostgreSQLは、`gitlab-ctl reconfigure`の後にポッドネットワークからのTCP接続のみを受け入れます。現時点では、ポッドは`CrashLoopBackOff`状態です。

   利用可能なすべてのチャートオプションについては、[OpenBao Helmチャートドキュメント](https://docs.gitlab.com/charts/charts/openbao/)を参照してください。

1. OpenBaoサービスに使用する内部URLを定義します。複数のオプションがあります:

   - ロードバランサー。コロケートされたKubernetesクラスターで内部ロードバランサーを使用している場合、`gitlab.rb`ファイルの`oak['components']['openbao']['internal_url']`設定をロードバランサーの内部URLに設定して、リクエストをOpenBao Kubernetesサービスにルーティングできます。この場合、内部URLが内部ロードバランサーIPに解決されるようにDNSを設定する必要があります。
   - クラスター`nodePort`。OpenBaoチャートサービスをKubernetesサービスタイプ`nodePort`で実行するようにカスタマイズした場合、内部URLもそれに設定できます。
   - サービス`clusterIP`。このオプションは最もシンプルである可能性が高いです。コロケートされたクラスターのロードバランサーを完全にスキップするには、OpenBao内部URLがOpenBaoサービス`clusterIP`に直接通信するように指示することもできます。Linuxパッケージ管理のNGINXがすでに存在するため、このオプションを使用すると、マシンに追加のロードバランサーをインストールする必要がなくなります。

   OpenBaoサービスの`clusterIP`は、以下を実行することで見つけることができます:

   ```shell
   kubectl -n openbao get svc openbao-active \
     -o jsonpath='{.spec.clusterIP}'
   ```

   内部URLのIPは、Kubernetesクラスター外部のホストマシンからアクセス可能である必要があることを覚えておいてください。選択した`<SHARED_NETWORK_IP>`からIPを割り当てるようにクラスターを設定します。

{{< /tab >}}

{{< tab title="外部クラスター" >}}

Helmを使用してOpenBaoをインストールするには:

1. GitLab Helmリポジトリを追加します。

   ```shell
   helm repo add gitlab https://charts.gitlab.io
   helm repo update
   ```

1. プレースホルダーの値を実際のドメインとPostgreSQLアドレスに置き換えて、以下の内容で`openbao-values.yaml`ファイルを作成します:

   ```yaml
   config:
     ui: false
     storage:
       postgresql:
         haEnabled: true
         connection:
           host: "<POSTGRES_ADDRESS>"
           port: 5432
           database: openbao
           username: openbao
           password:
             secret: openbao-db-secret
             key: password
     initialize:
       enabled: true
       oidcDiscoveryUrl: "https://<GITLAB_DOMAIN>"
       boundIssuer: "https://<GITLAB_DOMAIN>"
       boundAudiences: '"https://<OPENBAO_DOMAIN>"'

   # The chart deploys a Kubernetes Ingress resource by default, which you need to provide the hostname to be reachable for GitLab Rails and Sidekiq
   # Alternatively, you could configure it to deploy an HTTPRoute resource, if you prefer to deploy a Gateway API controller.
   #
   # For available network ingress and TLS configuration options, see:
   # https://docs.gitlab.com/charts/charts/openbao/#ingress-and-tls-configuration-options
   ingress:
     enabled: true
     hostname: "<OPENBAO_DOMAIN>"
   ```

1. OpenBaoをインストールします:

   ```shell
   helm upgrade --install openbao gitlab/openbao \
     --namespace openbao \
     --values openbao-values.yaml
   ```

利用可能なすべてのチャートオプションについては、[OpenBao Helmチャートドキュメント](https://docs.gitlab.com/charts/charts/openbao/)を参照してください。

{{< /tab >}}

{{< /tabs >}}

## GitLabを設定する {#configure-gitlab}

{{< tabs >}}

{{< tab title="コロケートクラスター" >}}

GitLabホストの`/etc/gitlab/gitlab.rb`に以下を追加し、プレースホルダーの値を実際のIPアドレスとドメインに置き換えます:

```ruby
# PostgreSQL: accept TCP connections from Kubernetes pods.
# Use the shared network IP to restrict exposure to the shared network.
# Using '0.0.0.0' makes PostgreSQL listen on all interfaces, including public ones.
postgresql['listen_address'] = '<SHARED_NETWORK_IP>'

# Local connections (GitLab Rails and other services) continue without a password.
postgresql['trust_auth_cidr_addresses'] = %w[127.0.0.1/32 ::1/128]

# Kubernetes pods authenticate with a password.
# Replace 10.42.0.0/16 with the CIDR of your Kubernetes CNI (pod network).
postgresql['md5_auth_cidr_addresses'] = %w[10.42.0.0/16]

# OAK: OpenBao reverse proxy via GitLab NGINX.
oak['enable'] = true
oak['network_address'] = '<SHARED_NETWORK_IP>'

oak['components']['openbao']['enable'] = true

# Replace 'https://openbao.example.com' with the URL of the DNS record
# you configured for OpenBao, which resolves to your host's public IP address.
oak['components']['openbao']['external_url'] = 'https://openbao.example.com'

# Example of service clusterIP. Replace <CLUSTER_IP> with the IP taken
# from the previous step.
#
# A nodePort would look similar: specify the cluster node IP with the port
# you chose when you deployed OpenBao.
#
# If behind a load balancer: 'http://openbao-internal.example.com'
oak['components']['openbao']['internal_url'] = 'http://<CLUSTER_IP>:8200'

# The URL that the GitLab application uses to connect to OpenBao.
gitlab_rails['openbao'] = {
  'url' => 'https://openbao.example.com'
}
```

この設定では、次のようになります。

- `postgresql['listen_address']`は共有ネットワークIPです。`trust_auth_cidr_addresses`または`md5_auth_cidr_addresses`にリストされていないCIDRからの接続はPostgreSQLによって拒否されます。
- `postgresql['trust_auth_cidr_addresses']`はCIDRブロックのリスト（localhostのみ）です。これらのブロックからの接続にはパスワードは必要ありません。これらのアドレスはGitLabサービスによって使用されます。
- `postgresql['md5_auth_cidr_addresses']`はポッドCIDRからのCIDRブロックのリストです。これらのブロックからの接続にはパスワードが必要です。これらのアドレスはOpenBaoポッドによって使用されます。パスワード認証。OpenBaoポッドによって使用されます。
- `oak['network_address']`は共有ネットワークIPです。NGINXのリッスンディレクティブによって使用されます。
- `oak['components']['openbao']['internal_url']`は、GitLabアプリケーションがOpenBaoと通信するために使用するURLです。
- `gitlab_rails['openbao']['url']`は、GitLabアプリケーションが使用するOpenBao URLです。

GitLabの`external_url`設定が`https://`を使用している場合、Let's Encryptはすでに有効になっています。OpenBaoの`external_url`スキームを`https://`に設定するだけで十分です。GitLabは、既存のLet's Encrypt証明書にOpenBaoドメインをSubject Alternative Name (SAN) として自動的に追加します。

代わりにカスタム証明書を使用するには、以下を追加します:

```ruby
oak['components']['openbao']['ssl_certificate']     = '/etc/gitlab/ssl/openbao.example.com.crt'
oak['components']['openbao']['ssl_certificate_key'] = '/etc/gitlab/ssl/openbao.example.com.key'
```

{{< /tab >}}

{{< tab title="外部クラスター" >}}

各GitLabアプリケーションノードの`/etc/gitlab/gitlab.rb`に以下を追加し、プレースホルダーの値を実際のIPアドレスとドメインに置き換えます:

```ruby
# The URL GitLab Rails uses to connect to OpenBao.
gitlab_rails['openbao'] = {
  'url' => 'https://openbao.example.com'
}
```

別のSidekiqノードがある場合は、各Sidekiqノードの`/etc/gitlab/gitlab.rb`に同じ`gitlab_rails['openbao']`設定を追加します。プロビジョニングするシークレットを持つSidekiqワーカーもOpenBaoへのアクセスが必要です。

Linuxパッケージ管理のPostgreSQLをOpenBaoデータベースとして使用する場合は、PostgreSQLノードの`/etc/gitlab/gitlab.rb`にも以下を追加します:

```ruby
# PostgreSQL: accept TCP connections from Kubernetes pods.
postgresql['listen_address'] = '<POSTGRES_ADDRESS>'

# Local connections (GitLab Rails and other services) continue without a password.
postgresql['trust_auth_cidr_addresses'] = %w[127.0.0.1/32 ::1/128]

# Kubernetes pods authenticate with a password.
# Replace 10.0.0.0/14 with the CIDR of your Kubernetes pod network.
postgresql['md5_auth_cidr_addresses'] = %w[10.0.0.0/14]
```

{{< /tab >}}

{{< /tabs >}}

## 設定の変更を適用する {#apply-configuration-changes}

{{< tabs >}}

{{< tab title="コロケートクラスター" >}}

設定の変更を適用します:

```shell
sudo gitlab-ctl reconfigure
```

このコマンドは、すべての設定を一度に適用します:

- PostgreSQLはKubernetesポッドからのTCP接続を受け入れ始めます。
- NGINXは、TLS終端とHTTPからHTTPSへのリダイレクトを含むOpenBao仮想ホストで設定されます。
- 該当する場合、Let's Encrypt証明書が発行または更新されます。

{{< /tab >}}

{{< tab title="外部クラスター" >}}

`gitlab.rb`を更新した各ノードで設定の変更を適用します:

```shell
sudo gitlab-ctl reconfigure
```

PostgreSQLノードでは、これによりPostgreSQLがクラスターポッドネットワークからのTCP接続を受け入れるようになります。RailsおよびSidekiqノードでは、これはOpenBao URLの設定を適用します。

{{< /tab >}}

{{< /tabs >}}

## OpenBaoが準備完了になるまで待機する {#wait-for-openbao-to-become-ready}

ロールアウトが完了するまで待機します:

```shell
kubectl -n openbao rollout status deployment openbao
```

コロケートされたクラスターの場合、以前`CrashLoopBackOff`状態にあったポッドは、`gitlab-ctl reconfigure`の完了後に正常になります。

## インストールを検証する {#verify-the-installation}

インストールを検証するには:

1. OpenBaoに到達可能であることを確認します:

   ```shell
   curl "https://openbao.example.com/v1/sys/health"
   ```

   成功した応答は次のようになります:

   ```json
   {
     "initialized": true,
     "sealed": false,
     "standby": false,
     "version": "2.0.0"
   }
   ```

1. [GitLab Secrets Manager](../../ci/secrets/secrets_manager/_index.md#enable-gitlab-secrets-manager)を有効にします。
