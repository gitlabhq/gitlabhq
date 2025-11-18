---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Kubernetes向けGitLabエージェントサーバーをインストールする（KAS）
description: Kubernetes向けGitLabエージェントを管理します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabと共にインストールされるコンポーネントであるエージェントサーバー。[Kubernetes向けGitLabエージェント](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent)の管理に必要です。

KASという略語は、以前の名前である`Kubernetes agent server`を指します。

Kubernetes用エージェントサーバーは、GitLab.comの`wss://kas.gitlab.com`にインストールされ、利用可能です。GitLab Self-Managedを使用している場合、デフォルトではエージェントサーバーがインストールされ、利用可能です。

## インストールオプション {#installation-options}

GitLab管理者として、エージェントサーバーのインストールを制御できます:

- [Linuxパッケージ](#for-linux-package-installations)インストールの場合。
- [GitLab Helmチャート](#for-gitlab-helm-chart)インストールの場合。

### Linuxパッケージインストールの場合 {#for-linux-package-installations}

Linuxパッケージインストール用のエージェントサーバーは、単一ノード、または複数のノードで一度に有効にできます。デフォルトでは、エージェントサーバーは`ws://gitlab.example.com/-/kubernetes-agent/`で有効になり、利用可能です。

#### 単一ノードでの無効化 {#disable-on-a-single-node}

単一ノードのエージェントサーバーを無効にするには:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitlab_kas['enable'] = false
   ```

1. [GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

#### 複数のノードでKASをオンにする {#turn-on-kas-on-multiple-nodes}

KASインスタンスは、既知の場所にあるRedisにプライベートアドレスを登録することで、相互に通信します。他のインスタンスがアクセスできるように、各KASがプライベートアドレスの詳細を提示するように設定する必要があります。

複数のノードでKASをオンにするには:

1. [共通設定](#common-configuration)を追加します。
1. 次のいずれかのオプションから設定を追加します:

   - [オプション1 - 明示的な手動設定](#option-1---explicit-manual-configuration)
   - [オプション2 - 自動CIDRベースの設定](#option-2---automatic-cidr-based-configuration)
   - [オプション3 - リスナー設定に基づく自動設定](#option-3---automatic-configuration-based-on-listener-configuration)

1. [GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。
1. （オプション）個別のGitLab RailsとSidekiqノードでマルチサーバー環境を使用する場合は、SidekiqノードでKASを有効にします。

##### 共通設定 {#common-configuration}

各KASノードについて、`/etc/gitlab/gitlab.rb`のファイルを編集し、次の設定を追加します:

```ruby
gitlab_kas_external_url 'wss://kas.gitlab.example.com/'

gitlab_kas['api_secret_key'] = '<32_bytes_long_base64_encoded_value>'
gitlab_kas['private_api_secret_key'] = '<32_bytes_long_base64_encoded_value>'

# private_api_listen_address examples, pick one:

gitlab_kas['private_api_listen_address'] = 'A.B.C.D:8155' # Listen on a particular IPv4. Each node must use its own unique IP.
# gitlab_kas['private_api_listen_address'] = '[A:B:C::D]:8155' # Listen on a particular IPv6. Each node must use its own unique IP.
# gitlab_kas['private_api_listen_address'] = 'kas-N.gitlab.example.com:8155' # Listen on all IPv4 and IPv6 interfaces that the DNS name resolves to. Each node must use its own unique domain.
# gitlab_kas['private_api_listen_address'] = ':8155' # Listen on all IPv4 and IPv6 interfaces.
# gitlab_kas['private_api_listen_address'] = '0.0.0.0:8155' # Listen on all IPv4 interfaces.
# gitlab_kas['private_api_listen_address'] = '[::]:8155' # Listen on all IPv6 interfaces.

# Uncomment below to enable KAS to KAS TLS communication
# gitlab_kas['private_api_certificate_file'] = '<path_to_kas_server_crt_file>'
# gitlab_kas['private_api_key_file'] = '<path_to_kas_server_certificate_key>'

gitlab_kas['env'] = {
  # 'OWN_PRIVATE_API_HOST' => '<server-name-from-cert>' # Add if you want to use TLS for KAS->KAS communication. This name is used to verify the TLS certificate host name instead of the host in the URL of the destination KAS.
  'SSL_CERT_DIR' => "/opt/gitlab/embedded/ssl/certs/",
}

gitlab_rails['gitlab_kas_external_url'] = 'wss://gitlab.example.com/-/kubernetes-agent/'
gitlab_rails['gitlab_kas_internal_url'] = 'grpc://kas.internal.gitlab.example.com'
gitlab_rails['gitlab_kas_external_k8s_proxy_url'] = 'https://gitlab.example.com/-/kubernetes-agent/k8s-proxy/'
```

**Do not**（設定しないでください）`private_api_listen_address`内部アドレス（以下など）をリッスンするようにします:

- `localhost`
- `127.0.0.1`または`::1`のようなループバックIPアドレス
- UNIXソケット

他のKASノードはこれらのアドレスに到達できません。

単一ノード構成では、`private_api_listen_address`を内部アドレスをリッスンするように設定できます。

##### オプション1 - 明示的な手動設定 {#option-1---explicit-manual-configuration}

各KASノードについて、`/etc/gitlab/gitlab.rb`のファイルを編集し、`OWN_PRIVATE_API_URL`環境変数を明示的に設定します:

```ruby
gitlab_kas['env'] = {
  # OWN_PRIVATE_API_URL examples, pick one. Each node must use its own unique IP or DNS name.
  # Use grpcs:// when using TLS on the private API endpoint.

  'OWN_PRIVATE_API_URL' => 'grpc://A.B.C.D:8155' # IPv4
  # 'OWN_PRIVATE_API_URL' => 'grpcs://A.B.C.D:8155' # IPv4 + TLS
  # 'OWN_PRIVATE_API_URL' => 'grpc://[A:B:C::D]:8155' # IPv6
  # 'OWN_PRIVATE_API_URL' => 'grpc://kas-N-private-api.gitlab.example.com:8155' # DNS name
}
```

##### オプション2 - 自動CIDRベースの設定 {#option-2---automatic-cidr-based-configuration}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/464) GitLab 16.5.0。
- [追加](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/merge_requests/2183)された複数のCIDRサポートをGitLab 17.8.1の`OWN_PRIVATE_API_CIDR`に追加しました。

{{< /history >}}

たとえば、KASホストにIPアドレスとホスト名が動的に割り当てられている場合、`OWN_PRIVATE_API_URL`変数に正確なIPアドレスまたはホスト名を設定できない場合があります。

正確なIPアドレスまたはホスト名を設定できない場合は、1つ以上の[CIDR](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)に基づいて動的に`OWN_PRIVATE_API_URL`を構築するようにKASを設定するために、`OWN_PRIVATE_API_CIDR`を設定できます:

このアプローチにより、各KASノードは、CIDRが変更されない限り機能する静的な設定を使用できます。

各KASノードについて、`/etc/gitlab/gitlab.rb`のファイルを編集して、`OWN_PRIVATE_API_URL` URLを動的に構築します:

1. この変数をオフにするには、共通設定の`OWN_PRIVATE_API_URL`をコメントアウトします。
1. KASノードがリッスンするネットワークを指定するように`OWN_PRIVATE_API_CIDR`を設定します。KASを起動すると、指定されたCIDRに一致するホストアドレスを選択することにより、使用するプライベートIPアドレスが決定されます。
1. 別のポートを使用するように`OWN_PRIVATE_API_PORT`を設定します。デフォルトでは、KASは`private_api_listen_address`パラメータからのポートを使用します。
1. プライベートAPIエンドポイントでTLSを使用する場合は、`OWN_PRIVATE_API_SCHEME=grpcs`を設定します。デフォルトでは、KASは`grpc`スキームを使用します。

```ruby
gitlab_kas['env'] = {
  # 'OWN_PRIVATE_API_CIDR' => '10.0.0.0/8', # IPv4 example
  # 'OWN_PRIVATE_API_CIDR' => '2001:db8:8a2e:370::7334/64', # IPv6 example
  # 'OWN_PRIVATE_API_CIDR' => '10.0.0.0/8,2001:db8:8a2e:370::7334/64', # multiple CIRDs example

  # 'OWN_PRIVATE_API_PORT' => '8155',
  # 'OWN_PRIVATE_API_SCHEME' => 'grpc',
}
```

##### オプション3 - リスナー設定に基づく自動設定 {#option-3---automatic-configuration-based-on-listener-configuration}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/464) GitLab 16.5.0。
- [更新](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/510)されたKASは、すべての非ループバックIPアドレスをリッスンおよび公開し、`private_api_listen_network`の値に基づいてIPv4およびIPv6アドレスをフィルターで除外します。

{{< /history >}}

KASノードは、`private_api_listen_network`および`private_api_listen_address`設定に基づいて、どのIPアドレスが利用可能かを判断できます:

- `private_api_listen_address`が固定IPアドレスとポート番号（たとえば、`ip:port`）に設定されている場合、このIPアドレスを使用します。
- `private_api_listen_address`にIPアドレスがない（たとえば、`:8155`）、または指定されていないIPアドレスがある（たとえば、`[::]:8155`または`0.0.0.0:8155`）場合、KASはすべての非ループバックおよび非リンクローカルIPアドレスをノードに割り当てます。IPv4およびIPv6アドレスは、`private_api_listen_network`の値に基づいてフィルターされます。
- `private_api_listen_address`が`hostname:PORT`（たとえば、`kas-N-private-api.gitlab.example.com:8155`）の場合、KASはドメイン名サービス名を解決し、すべてのIPアドレスをノードに割り当てます。このモードでは、KASは最初のIPアドレスでのみリッスンします（この動作は[Go標準ライブラリ](https://pkg.go.dev/net#Listen)によって定義されています）。IPv4およびIPv6アドレスは、`private_api_listen_network`の値に基づいてフィルターされます。

すべてのIPアドレスでKASのプライベートAPIアドレスを公開する前に、このアクションが組織のセキュリティポリシーと矛盾しないことを確認してください。プライベートAPIエンドポイントには、すべてのリクエストに対して有効な認証トークンが必要です。

各KASノードについて、`/etc/gitlab/gitlab.rb`のファイルを編集します:

例1。すべてのIPv4およびIPv6インターフェースでリッスンします:

```ruby
# gitlab_kas['private_api_listen_network'] = 'tcp' # this is the default value, no need to set it.
gitlab_kas['private_api_listen_address'] = ':8155' # Listen on all IPv4 and IPv6 interfaces
```

例2。すべてのIPv4インターフェースでリッスンします:

```ruby
gitlab_kas['private_api_listen_network'] = 'tcp4'
gitlab_kas['private_api_listen_address'] = ':8155'
```

例3。すべてのIPv6インターフェースでリッスンします:

```ruby
gitlab_kas['private_api_listen_network'] = 'tcp6'
gitlab_kas['private_api_listen_address'] = ':8155'
```

環境変数を使用して、`OWN_PRIVATE_API_URL`を構築するスキームとポートをオーバーライドできます:

```ruby
gitlab_kas['env'] = {
  # 'OWN_PRIVATE_API_PORT' => '8155',
  # 'OWN_PRIVATE_API_SCHEME' => 'grpc',
}
```

##### エージェントサーバーノード設定 {#agent-server-node-settings}

| 設定                                             | 説明 |
|-----------------------------------------------------|-------------|
| `gitlab_kas['private_api_listen_network']`          | KASがリッスンするネットワークファミリ。IPv4とIPv6の両方のネットワークで、`tcp`がデフォルトです。IPv4の場合は`tcp4`、IPv6の場合は`tcp6`に設定します。 |
| `gitlab_kas['private_api_listen_address']`          | KASがリッスンするアドレス。`0.0.0.0:8155`、またはクラスター内の他のノードから到達可能なIPとポートに設定します。 |
| `gitlab_kas['api_secret_key']`                      | KASとGitLab間の認証に使用される共有シークレット。値はBase64エンコードされ、正確に32バイト長である必要があります。 |
| `gitlab_kas['private_api_secret_key']`              | 異なるKASインスタンス間の認証に使用される共有シークレット。値はBase64エンコードされ、正確に32バイト長である必要があります。 |
| `gitlab_kas['private_api_certificate_file']`        | KASサーバー証明書ファイルのフルパス。`OWN_PRIVATE_API_SCHEME`または`OWN_PRIVATE_API_URL`が`grpcs`の場合に必要です。 |
| `gitlab_kas['private_api_key_file']`                | KASサーバー証明書キーファイルのフルパス。`OWN_PRIVATE_API_SCHEME`または`OWN_PRIVATE_API_URL`が`grpcs`の場合に必要です。 |
| `OWN_PRIVATE_API_SCHEME`                            | `OWN_PRIVATE_API_URL`を構築するときに使用するスキームを指定するために使用されるオプション値。`grpc`または`grpcs`を指定できます。 |
| `OWN_PRIVATE_API_URL`                               | サービスディスカバリのためにKASで使用される環境変数。構成しているノードのホスト名またはIPアドレスに設定します。そのノードは、クラスター内の他のノードから到達可能である必要があります。 |
| `OWN_PRIVATE_API_HOST`                              | TLS証明書のホスト名を検証するために使用されるオプション値。<sup>1</sup>クライアントは、この値をサーバーのTLS証明書ファイルのホスト名と比較します。 |
| `OWN_PRIVATE_API_PORT`                              | `OWN_PRIVATE_API_URL`を構築するときに使用するポートを指定するために使用されるオプション値。 |
| `OWN_PRIVATE_API_CIDR`                              | `OWN_PRIVATE_API_URL`を構築するときに使用する、利用可能なネットワークからのIPアドレスを指定するために使用されるオプション値。 |
| `gitlab_kas['client_timeout_seconds']`              | クライアントがKASに接続するためのタイムアウト。 |
| `gitlab_kas_external_url`                           | クラスター内`agentk`のユーザー向けURL。完全修飾ドメイン名サービスまたはサブドメイン名サービス、<sup>2</sup>、またはGitLabの外部URLを指定できます。<sup>3</sup>空白の場合、GitLabの外部URLがデフォルトになります。 |
| `gitlab_rails['gitlab_kas_external_url']`           | クラスター内`agentk`のユーザー向けURL。空白の場合、`gitlab_kas_external_url`がデフォルトになります。 |
| `gitlab_rails['gitlab_kas_external_k8s_proxy_url']` | Kubernetes APIプロキシのユーザー向けURL。空白の場合、`gitlab_kas_external_url`に基づくURLがデフォルトになります。 |
| `gitlab_rails['gitlab_kas_internal_url']`           | GitLabバックエンドがKASとの通信に使用する内部URL。 |

**Footnotes**（脚注）: 

1. `OWN_PRIVATE_API_URL`または`OWN_PRIVATE_API_SCHEME`が`grpcs`で始まる場合、送信接続のTLSが有効になります。
1. たとえば`wss://kas.gitlab.example.com/`などです。
1. たとえば`wss://gitlab.example.com/-/kubernetes-agent/`などです。

### GitLab Helmチャート {#for-gitlab-helm-chart}

[GitLab-KASチャートの使用方法](https://docs.gitlab.com/charts/charts/gitlab/kas/)を参照してください。

## Kubernetes APIプロキシクッキー {#kubernetes-api-proxy-cookie}

{{< history >}}

- GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/104504)。名前付き`kas_user_access`と`kas_user_access_project`の[機能フラグ](../feature_flags/_index.md)を使用します。デフォルトでは無効になっています。
- 機能フラグ`kas_user_access`と`kas_user_access_project`がGitLab 16.1で[有効化](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123479)されました。
- 機能フラグ`kas_user_access`および`kas_user_access_project`はGitLab 16.2で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125835)されました。

{{< /history >}}

KASは、次のいずれかを使用して、Kubernetes APIリクエストをKubernetes向けGitLabエージェントにプロキシします:

- CI/CD [ジョブ](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/kubernetes_ci_access.md)。
- [GitLabユーザー認証情報](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/kubernetes_user_access.md)。

ユーザー認証情報で認証するには、RailsはGitLabフロントエンドのCookieを設定します。このCookieは`_gitlab_kas`と呼ばれ、[`_gitlab_session`Cookie](../../user/profile/_index.md#cookies-used-for-sign-in)のように、暗号化されたセッションIDが含まれています。ユーザーを認証および承認するには、すべてのリクエストで`_gitlab_kas`CookieをKASプロキシエンドポイントに送信する必要があります。

## 受信エージェントを有効にする {#enable-receptive-agents}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/12180)されました。

{{< /history >}}

[受容エージェント](../../user/clusters/agent/_index.md#receptive-agents)を使用すると、GitLabインスタンスへのネットワーク接続を確立できないがGitLabからは接続できるKubernetesクラスターと、GitLabを統合できます。

受信エージェントを有効にするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **GitLab Agent for Kubernetes**を展開。
1. **受信モードを有効にする**トグルをオンにします。

## Kubernetes APIプロキシ応答ヘッダー許可リストを設定する {#configure-kubernetes-api-proxy-response-header-allowlist}

{{< history >}}

- GitLab 18.3で`kas_k8s_api_proxy_response_header_allowlist`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/642)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

KASのKubernetes APIプロキシは、応答ヘッダーの許可リストを使用します。安全でよく知られているKubernetesおよびHTTPヘッダーは、デフォルトで許可されています。

許可されている応答ヘッダーのリストについては、[応答ヘッダー許可リスト](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/internal/module/kubernetes_api/server/proxy_headers.go)を参照してください。

デフォルトの許可リストにない応答ヘッダーが必要な場合は、KAS設定に応答ヘッダーを追加できます。

許可されている追加の応答ヘッダーを追加するには:

```yaml
agent:
  kubernetes_api:
    extra_allowed_response_headers:
      - 'X-My-Custom-Header-To-Allow'
```

応答ヘッダーの追加のサポートは、[イシュー550614](https://gitlab.com/gitlab-org/gitlab/-/issues/550614)で追跡されています。

## トラブルシューティング {#troubleshooting}

Kubernetes用エージェントサーバーの使用中に問題が発生した場合は、次のコマンドを実行してサービスログを表示します:

```shell
kubectl logs -f -l=app=kas -n <YOUR-GITLAB-NAMESPACE>
```

Linuxパッケージインストールでは、`/var/log/gitlab/gitlab-kas/`にログがあります。

[個々のエージェントに関する問題を解決することもできます](../../user/clusters/agent/troubleshooting.md)。

### 設定ファイルが見つかりません {#configuration-file-not-found}

次のエラーメッセージが表示された場合:

```plaintext
time="2020-10-29T04:44:14Z" level=warning msg="Config: failed to fetch" agent_id=2 error="configuration file not found: \".gitlab/agents/test-agent/config.yaml\
```

次のいずれかのパスが正しくありません:

- エージェントが登録されたリポジトリ。
- エージェント設定ファイル。

この問題を解決するには、パスが正しいことを確認してください。

### エラー: `dial tcp <GITLAB_INTERNAL_IP>:443: connect: connection refused`{#error-dial-tcp-gitlab_internal_ip443-connect-connection-refused}

GitLab Self-Managedを実行していて、:

- インスタンスがSSL終端プロキシの背後で実行されていない。
- インスタンス自体にHTTPSが設定されていないGitLabインスタンス。
- インスタンスのホスト名が、ローカルで内部IPアドレスに解決される。

エージェントサーバーがGitLab APIに接続しようとすると、次のエラーが発生する可能性があります:

```json
{"level":"error","time":"2021-08-16T14:56:47.289Z","msg":"GetAgentInfo()","correlation_id":"01FD7QE35RXXXX8R47WZFBAXTN","grpc_service":"gitlab.agent.reverse_tunnel.rpc.ReverseTunnel","grpc_method":"Connect","error":"Get \"https://gitlab.example.com/api/v4/internal/kubernetes/agent_info\": dial tcp 172.17.0.4:443: connect: connection refused"}
```

Linuxパッケージインストールでこの問題を解決するには、`/etc/gitlab/gitlab.rb`に次のパラメータを設定します。`gitlab.example.com`をGitLabインスタンスのホスト名に置き換えます:

```ruby
gitlab_kas['gitlab_address'] = 'http://gitlab.example.com'
```

### エラー: `x509: certificate signed by unknown authority`{#error-x509-certificate-signed-by-unknown-authority}

GitLab URLに到達しようとしたときにこのエラーが発生した場合、それはGitLab証明書を信頼していないことを意味します。

GitLabアプリケーションサーバーのKASログに同様のエラーが表示される場合があります:

```json
{"level":"error","time":"2023-03-07T20:19:48.151Z","msg":"AgentInfo()","grpc_service":"gitlab.agent.agent_configuration.rpc.AgentConfiguration","grpc_method":"GetConfiguration","error":"Get \"https://gitlab.example.com/api/v4/internal/kubernetes/agent_info\": x509: certificate signed by unknown authority"}
```

このエラーを解決するには、内部認証局の公開証明書を`/etc/gitlab/trusted-certs`ディレクトリにインストールします。

または、カスタムディレクトリから証明書を読み取りようにKASを設定することもできます。これを行うには、`/etc/gitlab/gitlab.rb`のファイルに次の設定を追加します:

```ruby
gitlab_kas['env'] = {
   'SSL_CERT_DIR' => "/opt/gitlab/embedded/ssl/certs/"
 }
```

変更を適用するには、再構成します:

1. GitLabを再設定します:

```shell
sudo gitlab-ctl reconfigure
```

1. エージェントサーバーを再起動します:

```shell
gitlab-ctl restart gitlab-kas
```

### エラー: `GRPC::DeadlineExceeded in Clusters::Agents::NotifyGitPushWorker`{#error-grpcdeadlineexceeded-in-clustersagentsnotifygitpushworker}

このエラーは、クライアントがデフォルトのタイムアウト期間（5秒）内に応答を受信しない場合に発生する可能性があります。この問題を解決するには、`/etc/gitlab/gitlab.rb`設定ファイルを修正して、クライアントのタイムアウトを増やすことができます。

#### 解決する手順 {#steps-to-resolve}

1. タイムアウト値を大きくするために、次の設定を追加または更新します:

```ruby
gitlab_kas['client_timeout_seconds'] = "10"
```

1. GitLabを再設定して変更を適用します:

```shell
gitlab-ctl reconfigure
```

#### 注 {#note}

特定のニーズに合わせてタイムアウト値を調整できます。システムパフォーマンスに影響を与えずに問題が解決されることを確認するために、テストをお勧めします。

### エラー: `Blocked Kubernetes API proxy response header`{#error-blocked-kubernetes-api-proxy-response-header}

KubernetesクラスターからKubernetes APIプロキシを介してユーザーに送信されたときにHTTP応答ヘッダーが失われた場合は、KASログまたはSentryインスタンスで次のエラーを確認してください:

```plaintext
Blocked Kubernetes API proxy response header. Please configure extra allowed headers for your instance in the KAS config with `extra_allowed_response_headers` and have a look at the troubleshooting guide at https://docs.gitlab.com/administration/clusters/kas/#troubleshooting.
```

このエラーは、応答ヘッダーが応答ヘッダー許可リストで定義されていないため、Kubernetes APIプロキシが応答ヘッダーをブロックしたことを意味します。

応答ヘッダーの追加の詳細については、[応答ヘッダー許可リストを設定する](#configure-kubernetes-api-proxy-response-header-allowlist)を参照してください。

応答ヘッダーの追加のサポートは、[イシュー550614](https://gitlab.com/gitlab-org/gitlab/-/issues/550614)で追跡されています。
