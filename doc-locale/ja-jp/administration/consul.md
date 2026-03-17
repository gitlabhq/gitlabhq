---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Consulのセットアップ方法
description: Consulクラスターを設定します。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Consulクラスターは、[サーバーおよびクライアントエージェント](https://developer.hashicorp.com/consul/docs/agent)の両方で構成されます。サーバーは独自のノードで実行され、クライアントはサーバーと通信する他のノードで実行されます。

GitLab Premiumには、`/etc/gitlab/gitlab.rb`を使用して管理できるサービスネットワーキングソリューションである[Consul](https://www.consul.io/)のバンドルされたバージョンが含まれています。

## 前提条件 {#prerequisites}

Consulの設定を行う前に、次のことを確認してください:

1. [リファレンスアーキテクチャ](reference_architectures/_index.md#available-reference-architectures)ドキュメントを確認して、必要なConsulサーバーノードの数を決定してください。
1. 必要に応じて、ファイアウォールで[適切なポートが開いている](package_information/defaults.md#ports)ことを確認してください。

## Consulノードを設定する {#configure-the-consul-nodes}

各Consulサーバーノードで、次の手順を実行します:

1. 希望するプラットフォームを選択してGitLabを[インストール](https://about.gitlab.com/install/)する手順に従いますが、求められても`EXTERNAL_URL`の値は入力しないでください。
1. `/etc/gitlab/gitlab.rb`を編集し、`retry_join`セクションに記載されている値を置き換えて以下を追加します。以下の例では、3つのノードがあり、2つはIPアドレスで、1つはFQDNで示されています。どちらの表記も使用できます:

   ```ruby
   # Disable all components except Consul
   roles ['consul_role']

   # Consul nodes: can be FQDN or IP, separated by a whitespace
   consul['configuration'] = {
     server: true,
     retry_join: %w(10.10.10.1 consul1.gitlab.example.com 10.10.10.2)
   }

   # Disable auto migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. 変更を有効にするには、[GitLabを再設定します](restart_gitlab.md#reconfigure-a-linux-package-installation)。
1. Consulが正しく設定され、すべてのサーバーノードが通信していることを確認するために、次のコマンドを実行します:

   ```shell
   sudo /opt/gitlab/embedded/bin/consul members
   ```

   出力は次のようになります:

   ```plaintext
   Node                 Address               Status  Type    Build  Protocol  DC
   CONSUL_NODE_ONE      XXX.XXX.XXX.YYY:8301  alive   server  0.9.2  2         gitlab_consul
   CONSUL_NODE_TWO      XXX.XXX.XXX.YYY:8301  alive   server  0.9.2  2         gitlab_consul
   CONSUL_NODE_THREE    XXX.XXX.XXX.YYY:8301  alive   server  0.9.2  2         gitlab_consul
   ```

   結果に`alive`以外のステータスのノードが表示されている場合、または3つのノードのいずれかが不足している場合は、[トラブルシューティングセクション](#troubleshooting-consul)を参照してください。

## Consulノードの保護 {#securing-the-consul-nodes}

Consulノード間の通信を保護する方法は、TLSまたはゴシップ暗号化の2通りあります。

### TLS暗号化 {#tls-encryption}

デフォルトでは、Consulクラスターに対してTLSは有効になっていません。デフォルトの設定オプションとそのデフォルトは次のとおりです:

```ruby
consul['use_tls'] = false
consul['tls_ca_file'] = nil
consul['tls_certificate_file'] = nil
consul['tls_key_file'] = nil
consul['tls_verify_client'] = nil
```

これらの設定オプションは、クライアントとサーバーの両方のノードに適用されます。

ConsulノードでTLSを有効にするには、`consul['use_tls'] = true`から始めます。ノードの役割（サーバーまたはクライアント）とTLSの設定に応じて、さらに設定を行う必要があります:

- サーバーノードでは、少なくとも`tls_ca_file`、`tls_certificate_file`、および`tls_key_file`を指定する必要があります。
- クライアントノードでは、クライアントTLS認証がサーバーで無効になっている場合（デフォルトで有効）、少なくとも`tls_ca_file`を指定する必要があります。そうでない場合は、`tls_certificate_file`、`tls_key_file`を使用してクライアントTLS証明書とキーを渡す必要があります。

TLSが有効になっている場合、デフォルトではサーバーは相互TLSを使用し、HTTPSとHTTP（およびTLSと非TLS RPC）の両方でリッスンします。クライアントがTLS認証を使用することを想定しています。`consul['tls_verify_client'] = false`を設定することで、クライアントTLS認証を無効にできます。

一方、クライアントはサーバーノードへの発信接続にのみTLSを使用し、受信リクエストにはHTTP（および非TLS RPC）のみをリッスンします。`consul['https_port']`を負ではない整数に設定することで、クライアントConsulエージェントに受信接続にTLSを使用させることができます（`8501`はConsulのデフォルトHTTPSポートです）。これが機能するには、`tls_certificate_file`と`tls_key_file`も渡す必要があります。サーバーノードがクライアントTLS認証を使用する場合、クライアントTLS証明書とキーはTLS認証と受信HTTPS接続の両方に使用されます。

Consulクライアントノードは、デフォルトではTLSクライアント認証を使用しません（サーバーとは対照的に）。`consul['tls_verify_client'] = true`を設定して明示的に指示する必要があります。

以下はTLS暗号化の例です。

#### 最小限のTLSサポート {#minimal-tls-support}

以下の例では、サーバーは受信接続にTLSを使用します（クライアントTLS認証なし）。

{{< tabs >}}

{{< tab title="Consulサーバーノード" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   consul['enable'] = true
   consul['configuration'] = {
     'server' => true
   }

   consul['use_tls'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   consul['tls_certificate_file'] = '/path/to/server.crt.pem'
   consul['tls_key_file'] = '/path/to/server.key.pem'
   consul['tls_verify_client'] = false
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Consulクライアントノード" >}}

例えば、Patroniノードで以下を設定できます。

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   consul['enable'] = true
   consul['use_tls'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   patroni['consul']['url'] = 'http://localhost:8500'
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

PatroniはローカルのConsulエージェントと通信しますが、これは受信接続にTLSを使用しません。したがって、`patroni['consul']['url']`のHTTP URLが使用されます。

{{< /tab >}}

{{< /tabs >}}

#### デフォルトのTLSサポート {#default-tls-support}

以下の例では、サーバーは相互TLS認証を使用します。

{{< tabs >}}

{{< tab title="Consulサーバーノード" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   consul['enable'] = true
   consul['configuration'] = {
     'server' => true
   }

   consul['use_tls'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   consul['tls_certificate_file'] = '/path/to/server.crt.pem'
   consul['tls_key_file'] = '/path/to/server.key.pem'
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Consulクライアントノード" >}}

例えば、Patroniノードで以下を設定できます。

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   consul['enable'] = true
   consul['use_tls'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   consul['tls_certificate_file'] = '/path/to/client.crt.pem'
   consul['tls_key_file'] = '/path/to/client.key.pem'
   patroni['consul']['url'] = 'http://localhost:8500'
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

PatroniはローカルのConsulエージェントと通信しますが、ConsulサーバーノードへのTLS認証を使用しているにもかかわらず、受信接続にTLSを使用しません。したがって、`patroni['consul']['url']`のHTTP URLが使用されます。

{{< /tab >}}

{{< /tabs >}}

#### フルTLSサポート {#full-tls-support}

以下の例では、クライアントとサーバーの両方が相互TLS認証を使用します。

Consulサーバー、クライアント、およびPatroniクライアント証明書は、相互TLS認証を機能させるために同じ認証局によって発行される必要があります。

{{< tabs >}}

{{< tab title="Consulサーバーノード" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   consul['enable'] = true
   consul['configuration'] = {
     'server' => true
   }

   consul['use_tls'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   consul['tls_certificate_file'] = '/path/to/server.crt.pem'
   consul['tls_key_file'] = '/path/to/server.key.pem'
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Consulクライアントノード" >}}

例えば、Patroniノードで以下を設定できます。

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   consul['enable'] = true
   consul['use_tls'] = true
   consul['tls_verify_client'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   consul['tls_certificate_file'] = '/path/to/client.crt.pem'
   consul['tls_key_file'] = '/path/to/client.key.pem'
   consul['https_port'] = 8501

   patroni['consul']['url'] = 'https://localhost:8501'
   patroni['consul']['cacert'] = '/path/to/ca.crt.pem'
   patroni['consul']['cert'] = '/opt/tls/patroni.crt.pem'
   patroni['consul']['key'] = '/opt/tls/patroni.key.pem'
   patroni['consul']['verify'] = true
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< /tabs >}}

### ゴシップ暗号化 {#gossip-encryption}

ゴシッププロトコルは、Consulエージェント間の通信を保護するために暗号化された場合があります。デフォルトでは暗号化は有効になっていません。暗号化を有効にするには、共有暗号化キーが必要です。便宜上、`gitlab-ctl consul keygen`コマンドを使用してキーを生成できます。キーは32バイト長で、Base 64でエンコードされ、すべてのエージェントで共有される必要があります。

以下のオプションは、クライアントとサーバーの両方のノードで機能します。

ゴシッププロトコルを有効にするには:

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   consul['encryption_key'] = <base-64-key>
   consul['encryption_verify_incoming'] = true
   consul['encryption_verify_outgoing'] = true
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

[既存のデータセンターで暗号化を有効にする](https://developer.hashicorp.com/consul/docs/security/encryption#enable-on-an-existing-consul-datacenter)には、ローリングアップデートのためにこれらのオプションを手動で設定します。

## Consulノードのアップグレード {#upgrade-the-consul-nodes}

Consulノードをアップグレードするには、GitLabパッケージをアップグレードします。

ノードは以下の条件を満たす必要があります:

- Linuxパッケージをアップグレードする前に、正常なクラスターのメンバーであること。
- 一度に1つのノードをアップグレードすること。

各ノードで次のコマンドを実行して、クラスター内の既存のヘルス上の問題を特定します。クラスターが正常であれば、コマンドは空の配列を返します:

```shell
curl "http://127.0.0.1:8500/v1/health/state/critical"
```

Consulバージョンが変更された場合、`gitlab-ctl reconfigure`の最後に、新しいバージョンを使用するためにConsulを再起動する必要があることを示す通知が表示されます。

Consulを一度に1つのノードずつ再起動します:

```shell
sudo gitlab-ctl restart consul
```

Consulノードはraftプロトコルを使用して通信します。現在のリーダーがオフラインになった場合、リーダー選挙が行われる必要があります。クラスター全体の同期を促進するには、リーダーノードが存在する必要があります。同時にあまりにも多くのノードがオフラインになると、クラスターはクォーラムを失い、[合意が破られた](https://developer.hashicorp.com/consul/docs/architecture/consensus)ためにリーダーを選出しません。

アップグレード後にクラスターがリカバリーできない場合は、[トラブルシューティングセクション](#troubleshooting-consul)を参照してください。[停止リカバリー](#outage-recovery)が特に役立つ場合があります。

GitLabは、簡単に再生成できる一時的なデータのみをConsulに保存します。バンドルされたConsulがGitLab自体以外のプロセスで使用されていない場合、[スクラッチからクラスターを再構築](#recreate-from-scratch)できます。

## Consulのトラブルシューティング {#troubleshooting-consul}

以下は、問題をデバッグする場合のいくつかの操作です。次のコマンドを実行して、エラーログを確認できます:

```shell
sudo gitlab-ctl tail consul
```

### クラスターのメンバーシップを確認する {#check-the-cluster-membership}

どのノードがクラスターの一部であるかを判断するには、クラスター内の任意のメンバーで次を実行します:

```shell
sudo /opt/gitlab/embedded/bin/consul members
```

出力は次のようになります:

```plaintext
Node            Address               Status  Type    Build  Protocol  DC
consul-b        XX.XX.X.Y:8301        alive   server  0.9.0  2         gitlab_consul
consul-c        XX.XX.X.Y:8301        alive   server  0.9.0  2         gitlab_consul
consul-c        XX.XX.X.Y:8301        alive   server  0.9.0  2         gitlab_consul
db-a            XX.XX.X.Y:8301        alive   client  0.9.0  2         gitlab_consul
db-b            XX.XX.X.Y:8301        alive   client  0.9.0  2         gitlab_consul
```

理想的には、すべてのノードの`Status`が`alive`であるべきです。

### Consulを再起動する {#restart-consul}

Consulを再起動する必要がある場合は、クォーラムを維持するために制御された方法で行うことが重要です。クォーラムが失われた場合、クラスターをリカバリーするには、Consulの[停止リカバリー](#outage-recovery)プロセスに従います。

安全のため、クラスターが破損しないように、一度に1つのノードでConsulを再起動することをお勧めします。大規模なクラスターの場合、一度に複数のノードを再起動することが可能です。耐えられる失敗の数については、[Consul合意ドキュメント](https://developer.hashicorp.com/consul/docs/architecture/consensus#deployment-table)を参照してください。これは、同時に維持できる再起動の数です。

Consulを再起動するには:

```shell
sudo gitlab-ctl restart consul
```

### Consulノードが通信できない {#consul-nodes-unable-to-communicate}

デフォルトでは、Consulは`0.0.0.0`に[バインド](https://developer.hashicorp.com/consul/docs/agent/config/config-files#bind_addr)しようとしますが、他のConsulノードがそれと通信できるように、ノード上の最初のプライベートIPアドレスをアドバタイズします。他のノードがこのアドレスのノードと通信できない場合、クラスターは失敗したステータスになります。

この問題が発生した場合、`gitlab-ctl tail consul`に次のようなメッセージが出力されます:

```plaintext
2017-09-25_19:53:39.90821     2017/09/25 19:53:39 [WARN] raft: no known peers, aborting election
2017-09-25_19:53:41.74356     2017/09/25 19:53:41 [ERR] agent: failed to sync remote state: No cluster leader
```

これを修正するには、次の手順に従います:

1. すべての他のノードがこのノードに到達できる、各ノード上のアドレスを選択します。
1. `/etc/gitlab/gitlab.rb`を更新します。

   ```ruby
   consul['configuration'] = {
     ...
     bind_addr: 'IP ADDRESS'
   }
   ```

1. GitLabを再設定します。

   ```shell
   gitlab-ctl reconfigure
   ```

それでもエラーが表示される場合は、影響を受けたノードで[Consulデータベースを消去して再初期化](#recreate-from-scratch)する必要がある場合があります。

### Consulが起動しない - 複数のプライベートIP {#consul-does-not-start---multiple-private-ips}

ノードに複数のプライベートIPがある場合、Consulはどのアドレスをアドバタイズすべきか分からず、起動時にすぐに終了します。

`gitlab-ctl tail consul`に次のようなメッセージが出力されます:

```plaintext
2017-11-09_17:41:45.52876 ==> Starting Consul agent...
2017-11-09_17:41:45.53057 ==> Error creating agent: Failed to get advertise address: Multiple private IPs found. Please configure one.
```

これを修正するには、次の手順に従います:

1. すべての他のノードがこのノードに到達できる、ノード上のアドレスを選択します。
1. `/etc/gitlab/gitlab.rb`を更新します。

   ```ruby
   consul['configuration'] = {
     ...
     bind_addr: 'IP ADDRESS'
   }
   ```

1. GitLabを再設定します。

   ```shell
   gitlab-ctl reconfigure
   ```

### 停止リカバリー {#outage-recovery}

クラスターのクォーラムを破るのに十分なConsulノードを失った場合、クラスターは失敗したと見なされ、手動での介入なしには機能できません。その場合、ノードをゼロから再作成するか、リカバリーを試みることができます。

#### スクラッチから再作成する {#recreate-from-scratch}

デフォルトでは、GitLabは再作成できないものをConsulノードに保存しません。Consulデータベースを消去して再初期化するには:

```shell
sudo gitlab-ctl stop consul
sudo rm -rf /var/opt/gitlab/consul/data
sudo gitlab-ctl start consul
```

この後、ノードは再起動し、残りのサーバーエージェントは再参加します。その後すぐに、クライアントエージェントも再参加するはずです。

参加しない場合は、クライアント上のConsulデータも消去する必要があるかもしれません:

```shell
sudo rm -rf /var/opt/gitlab/consul/data
```

#### 失敗したノードをリカバリーする {#recover-a-failed-node}

Consulを利用して他のデータを保存しており、失敗したノードを復元する場合は、Consulの[ガイド](https://developer.hashicorp.com/consul/tutorials/operate-consul/recovery-outage)に従って失敗したクラスターをリカバリーしてください。
