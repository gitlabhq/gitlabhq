---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Consulをセットアップする方法
description: Consulクラスタを設定します。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Consulクラスタは、[サーバーエージェントとクライアントエージェント](https://developer.hashicorp.com/consul/docs/agent)の両方で構成されています。サーバーは独自のノード上で実行され、クライアントはサーバーと通信する他のノード上で実行されます。

GitLab Premiumには、[Consul](https://www.consul.io/)のバンドル版が含まれており、`/etc/gitlab/gitlab.rb`を使用して管理できます。

## 前提要件 {#prerequisites}

Consulを構成する前に:

1. 必要なConsulサーバーノードの数を決定するために、[リファレンスアーキテクチャ](reference_architectures/_index.md#available-reference-architectures)のドキュメントをレビューしてください。
1. 必要に応じて、ファイアウォールで[適切なポートが開いている](package_information/defaults.md#ports)ことを確認してください。

## Consulノードを構成する {#configure-the-consul-nodes}

各Consulサーバーノードで:

1. お好みのプラットフォームを選択してGitLabを[インストール](https://about.gitlab.com/install/)する手順に従いますが、要求されたら`EXTERNAL_URL`値を指定しないでください。
1. `/etc/gitlab/gitlab.rb`を編集し、`retry_join`セクションに記載されている値を置き換えることで、以下を追加します。以下の例では、3つのノードがあり、2つはIPで示され、1つはFQDNで示されています。どちらの表記法も使用できます:

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
1. 次のコマンドを実行して、Consulが正しく構成されていることと、すべてのサーバーノードが通信していることを確認します:

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

   結果に`alive`ではないステータスのノードが表示された場合、または3つのノードのいずれかが欠落している場合は、[トラブルシューティング](#troubleshooting-consul)セクションを参照してください。

## Consulノードの保護 {#securing-the-consul-nodes}

TLSまたはゴシップ暗号化のいずれかを使用して、Consulノード間の通信を保護する方法は2つあります。

### TLS暗号化 {#tls-encryption}

デフォルトでは、TLSはConsulクラスタに対して有効になっていません。デフォルトの設定オプションとそのデフォルトは次のとおりです:

```ruby
consul['use_tls'] = false
consul['tls_ca_file'] = nil
consul['tls_certificate_file'] = nil
consul['tls_key_file'] = nil
consul['tls_verify_client'] = nil
```

これらの設定オプションは、クライアントノードとサーバーノードの両方に適用されます。

ConsulノードでTLSを有効にするには、`consul['use_tls'] = true`から開始します。ノードのロール(サーバーまたはクライアント)とTLSの好みに応じて、さらに設定を提供する必要があります:

- サーバーノードでは、少なくとも`tls_ca_file`、`tls_certificate_file`、および`tls_key_file`を指定する必要があります。
- クライアントノードでは、サーバーでクライアントTLS認証が無効になっている場合(デフォルトで有効)、少なくとも`tls_ca_file`を指定する必要があります。それ以外の場合は、`tls_certificate_file`、`tls_key_file`を使用してクライアントTLS証明書とキーを渡す必要があります。

TLSが有効になっている場合、デフォルトでは、サーバーはmTLSを使用し、HTTPSとHTTP(およびTLSおよび非TLS RPC)の両方をリッスンします。クライアントはTLS認証を使用することを想定しています。`consul['tls_verify_client'] = false`を設定して、クライアントTLS認証を無効にできます。

一方、クライアントはサーバーノードへの送信接続にのみTLSを使用し、受信リクエストに対してHTTP(および非TLS RPC)のみをリッスンします。`consul['https_port']`を負でない整数(`8501`はConsulのデフォルトのHTTPSポートです)に設定することで、クライアントConsulエージェントが受信接続にTLSを使用するように強制できます。これが機能するには、`tls_certificate_file`と`tls_key_file`も渡す必要があります。サーバーノードがクライアントTLS認証を使用する場合、クライアントTLS証明書とキーは、TLS認証と受信HTTPS接続の両方で使用されます。

Consulクライアントノードは、(参照元のサーバーとは対照的に)デフォルトではTLSクライアント認証を使用しないため、`consul['tls_verify_client'] = true`を設定して、それらを実行するように明示的に指示する必要があります。

以下に、TLS暗号化の例をいくつか示します。

#### 最小限のTLSサポート {#minimal-tls-support}

次の例では、サーバーは受信接続にTLSを使用します(クライアントTLS認証なし)。

{{< tabs >}}

{{< tab title="Consulサーバーノード" >}}

1. `/etc/gitlab/gitlab.rb`を編集します:

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

以下は、たとえばPatroniノードで構成できます。

1. `/etc/gitlab/gitlab.rb`を編集します:

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

PatroniはローカルConsulエージェントと通信しますが、これは受信接続にTLSを使用しません。したがって、`patroni['consul']['url']`のHTTP URL。

{{< /tab >}}

{{< /tabs >}}

#### デフォルトのTLSサポート {#default-tls-support}

次の例では、サーバーは相互TLS認証を使用します。

{{< tabs >}}

{{< tab title="Consulサーバーノード" >}}

1. `/etc/gitlab/gitlab.rb`を編集します:

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

以下は、たとえばPatroniノードで構成できます。

1. `/etc/gitlab/gitlab.rb`を編集します:

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

PatroniはローカルConsulエージェントと通信しますが、ConsulサーバーノードへのTLS認証を使用している場合でも、受信接続にTLSを使用しません。したがって、`patroni['consul']['url']`のHTTP URL。

{{< /tab >}}

{{< /tabs >}}

#### 完全なTLSサポート {#full-tls-support}

次の例では、クライアントとサーバーの両方が相互TLS認証を使用します。

相互TLS認証が機能するには、Consulサーバー、クライアント、およびPatroniクライアント証明書が同じCAによって発行されている必要があります。

{{< tabs >}}

{{< tab title="Consulサーバーノード" >}}

1. `/etc/gitlab/gitlab.rb`を編集します:

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

以下は、たとえばPatroniノードで構成できます。

1. `/etc/gitlab/gitlab.rb`を編集します:

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

ゴシッププロトコルを暗号化されたして、Consulエージェント間の通信を保護できます。デフォルトでは、暗号化は有効になっていません。有効にするには、共有暗号化キーが必要です。便宜上、`gitlab-ctl consul keygen`コマンドを使用してキーを生成できます。キーは32バイト長、Base 64エンコードで、すべてのエージェントで共有する必要があります。

次のオプションは、クライアントノードとサーバーノードの両方で機能します。

ゴシッププロトコルを有効にするには:

1. `/etc/gitlab/gitlab.rb`を編集します:

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

ノードは次のようになります:

- Linuxパッケージをアップグレードする前に、正常なクラスタのメンバー。
- 一度に1つのノードをアップグレードします。

各ノードで次のコマンドを実行して、クラスタ内の既存のヘルスイシューを特定します。クラスタが正常な場合、コマンドは空の配列を返します:

```shell
curl "http://127.0.0.1:8500/v1/health/state/critical"
```

Consulバージョンが変更された場合は、`gitlab-ctl reconfigure`の最後に通知が表示され、新しいバージョンを使用するにはConsulを再起動する必要があることが通知されます。

Consulを一度に1つのノードずつ再起動します:

```shell
sudo gitlab-ctl restart consul
```

Consulノードは、raftプロトコルを使用して通信します。現在のリーダーがオフラインになった場合は、リーダー選出が必要です。クラスタ全体での同期を容易にするには、リーダノードが存在する必要があります。同時にオフラインになるノードが多すぎると、クラスタはクォーラムを失い、[コンセンサスが崩れた](https://developer.hashicorp.com/consul/docs/architecture/consensus)ためにリーダーを選出できなくなります。

アップグレード後にクラスタをリカバリーできない場合は、[トラブルシューティング](#troubleshooting-consul)セクションを参照してください。[停止リカバリー](#outage-recovery)が特に関心を集める可能性があります。

GitLabは、簡単に再生成できる一時的なデータのみをConsulに保存します。GitLab自体以外のプロセスでバンドルされたConsulが使用されていない場合は、[クラスタを最初から再構築](#recreate-from-scratch)できます。

## Consulのトラブルシューティング {#troubleshooting-consul}

以下に、デバッグの問題をいくつか示します。次のコマンドを実行すると、エラーログが表示されます:

```shell
sudo gitlab-ctl tail consul
```

### クラスタメンバーシップの確認 {#check-the-cluster-membership}

どのノードがクラスタの一部であるかを判断するには、クラスタ内の任意のメンバーで以下を実行します:

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

理想的には、すべてのノードの`Status`が`alive`です。

### Consulの再起動 {#restart-consul}

Consulを再起動する必要がある場合は、クォーラムを維持するために、制御された方法でこれを行うことが重要です。クォーラムが失われた場合、クラスタをリカバリーするには、Consulの[停止リカバリー](#outage-recovery)プロセスに従います。

安全のため、クラスタが確実に無傷のままであるように、一度に1つのノードでのみConsulを再起動することをお勧めします。大規模なクラスタの場合、一度に複数のノードを再起動することができます。許容できる失敗の数については、[Consulコンセンサスドキュメント](https://developer.hashicorp.com/consul/docs/architecture/consensus#deployment-table)を参照してください。これは、持続できる同時再起動の数です。

Consulを再起動するには:

```shell
sudo gitlab-ctl restart consul
```

### Consulノードが通信できません {#consul-nodes-unable-to-communicate}

デフォルトでは、Consulは[バインド](https://developer.hashicorp.com/consul/docs/agent/config/config-files#bind_addr)を`0.0.0.0`に試みますが、他のConsulノードが通信するために、ノード上の最初のプライベートIPアドレスをアドバタイズします。他のノードがこのアドレスのノードと通信できない場合、クラスタは失敗したステータスになります。

このイシューが発生した場合、次のようなメッセージが`gitlab-ctl tail consul`に出力されます:

```plaintext
2017-09-25_19:53:39.90821     2017/09/25 19:53:39 [WARN] raft: no known peers, aborting election
2017-09-25_19:53:41.74356     2017/09/25 19:53:41 [ERR] agent: failed to sync remote state: No cluster leader
```

これを修正するには、次の手順に従います:

1. 他のすべてのノードがこのノードを介して到達できる各ノードのアドレスを選択します。
1. `/etc/gitlab/gitlab.rb`を更新します

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

エラーが引き続き表示される場合は、影響を受けるノードで[Consulデータベースを消去して再初期化](#recreate-from-scratch)する必要があるかもしれません。

### Consulが起動しない - 複数のプライベートIP {#consul-does-not-start---multiple-private-ips}

ノードに複数のプライベートIPがある場合、Consulはどのアドレスをアドバタイズするかを認識せず、起動時にすぐに終了します。

次のようなメッセージが`gitlab-ctl tail consul`に出力されます:

```plaintext
2017-11-09_17:41:45.52876 ==> Starting Consul agent...
2017-11-09_17:41:45.53057 ==> Error creating agent: Failed to get advertise address: Multiple private IPs found. Please configure one.
```

これを修正するには、次の手順に従います:

1. 他のすべてのノードがこのノードを介して到達できるノードのアドレスを選択します。
1. `/etc/gitlab/gitlab.rb`を更新します

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

クォーラムを壊すのに十分なConsulノードをクラスタで失った場合、クラスタは失敗したと見なされ、手動で介入しないと機能しません。その場合は、ノードを最初から再作成するか、リカバリーを試みることができます。

#### 最初から再作成 {#recreate-from-scratch}

デフォルトでは、GitLabは再作成できないものをConsulノードに保存しません。Consulデータベースを消去して再初期化するには:

```shell
sudo gitlab-ctl stop consul
sudo rm -rf /var/opt/gitlab/consul/data
sudo gitlab-ctl start consul
```

この後、ノードが再起動し、残りのサーバーエージェントが再結合します。その後まもなく、クライアントエージェントも再結合します。

参加しない場合は、クライアントでConsulデータを消去する必要があるかもしれません:

```shell
sudo rm -rf /var/opt/gitlab/consul/data
```

#### 失敗したノードをリカバリーする {#recover-a-failed-node}

Consulを利用して他のデータを保存し、失敗したノードを復元する場合は、[Consulガイド](https://developer.hashicorp.com/consul/tutorials/operate-consul/recovery-outage)に従って、失敗したクラスタをリカバリーします。
