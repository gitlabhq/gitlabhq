---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Gitalyを設定する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Gitalyを設定する方法は2つあります:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集して、Gitalyの設定を追加または変更します。[Gitaly設定ファイル](https://gitlab.com/gitlab-org/gitaly/-/blob/master/config.toml.example)の例を参照してください。サンプルファイルの設定は、Rubyに変換する必要があります。
1. ファイルを保存して[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. [Gitalyチャート](https://docs.gitlab.com/charts/charts/gitlab/gitaly/)を設定します。
1. [Helmリリースをアップグレード](https://docs.gitlab.com/charts/installation/deployment.html)します。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitaly/config.toml`を編集して、Gitalyの設定を追加または変更します。[Gitaly設定ファイル](https://gitlab.com/gitlab-org/gitaly/-/blob/master/config.toml.example)の例を参照してください。
1. ファイルを保存して、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}

次の設定オプションも使用できます:

- [TLSサポート](tls_support.md)の有効化。
- [RPC並行処理](concurrency_limiting.md#limit-rpc-concurrency)の制限。
- [pack-objects並行処理](concurrency_limiting.md#limit-pack-objects-concurrency)の制限。

## Gitalyトークンについて {#about-the-gitaly-token}

Gitalyドキュメント全体で参照されているトークンは、管理者が選択した任意のパスワードにすぎません。これは、GitLab APIまたは他の同様のAPI用に作成されたトークンとは関係ありません。

## Gitalyを独自のサーバーで実行する {#run-gitaly-on-its-own-server}

デフォルトでは、GitalyはGitalyクライアントと同じサーバー上で実行され、前述のように構成されます。シングルサーバーインストールは、以下で使用されるこのデフォルト構成で最適に提供されます:

- [Linuxパッケージインストール](https://docs.gitlab.com/omnibus/)。
- [セルフコンパイルインストール](../../install/self_compiled/_index.md)。

ただし、Gitalyは独自のサーバーにデプロイでき、複数のマシンにまたがるGitLabインストールに役立ちます。

{{< alert type="note" >}}

独自のサーバー上で実行するように構成されている場合、Gitalyサーバーは、クラスター内のGitalyクライアントより前に[アップグレード](../../update/package/_index.md)する必要があります。

{{< /alert >}}

{{< alert type="note" >}}

[ディスク要件](_index.md#disk-requirements)は、Gitalyノードに適用されます。{{< /alert >}}

独自のサーバーにGitalyをセットアップする手順は次のとおりです:

1. [Gitalyをインストール](#install-gitaly)します。
1. [認証](#configure-authentication)を構成します。
1. [Gitalyサーバー](#configure-gitaly-servers)を構成します。
1. [Gitalyクライアント](#configure-gitaly-clients)を設定します。
1. [不要なGitalyを無効にする](#disable-gitaly-where-not-required-optional) (オプション)。

### ネットワークアーキテクチャ {#network-architecture}

次のリストは、Gitalyのネットワークアーキテクチャを示しています:

- GitLab Railsは、[リポジトリストレージ](../repository_storage_paths.md)にシャードを分割します。
- `/config/gitlab.yml`には、ストレージ名から`(Gitaly address, Gitaly token)`のペアへのマップが含まれています。
- `/config/gitlab.yml`の`storage name` -> `(Gitaly address, Gitaly token)`マップは、Gitalyネットワークトポロジの信頼できる唯一の情報源です。
- `(Gitaly address, Gitaly token)`は、Gitalyサーバーに対応します。
- Gitalyサーバーは、1つ以上のストレージをホストします。
- Gitalyクライアントは、1つ以上のGitalyサーバーを使用できます。
- Gitalyアドレスは、すべてのGitalyクライアントに対して正しく解決されるように指定する必要があります。
- Gitalyクライアントは次のとおりです:
  - Puma。
  - Sidekiq。
  - GitLab Workhorse。
  - GitLab Shell。
  - Elasticsearch Indexer。
  - Gitaly自体。
- Gitalyサーバーは、`/config/gitlab.yml`で指定されているように、独自の`(Gitaly address, Gitaly token)`ペアを使用して、自身に対してRPC呼び出しを実行できる必要があります。
- 認証は、GitalyノードとGitLab Railsノード間で共有されるスタティックトークンを介して行われます。

次の図は、HTTPおよびHTTPs通信のデフォルトポートを示すGitalyサーバーとGitLab Rails間の通信を示しています。

![情報を交換する2つのGitalyサーバーとGitLab Rails。](img/gitaly_network_v13_9.png)

{{< alert type="warning" >}}

Gitalyのネットワークトラフィックはデフォルトで暗号化されていないため、Gitalyサーバーをパブリックインターネットに公開しないでください。Gitalyサーバーへのアクセスを制限するために、ファイアウォールの使用を強くお勧めします。別のオプションは、[TLSを使用する](tls_support.md)ことです。

{{< /alert >}}

次のセクションでは、シークレットトークン`abc123secret`を使用して2つのGitalyサーバーを構成する方法について説明します:

- `gitaly1.internal`。
- `gitaly2.internal`。

お客様のGitLab環境には、3つのリポジトリストレージがあることを前提としています:

- `default`。
- `storage1`。
- `storage2`。

必要に応じて、1つのリポジトリストレージを備えたサーバーを少数使用できます。

### Gitalyをインストールする {#install-gitaly}

次のいずれかを使用して、各GitalyサーバーにGitalyをインストールします:

- Linuxパッケージインストールの必要なLinuxパッケージを[ダウンロードしてインストール](https://about.gitlab.com/install/)しますが、`EXTERNAL_URL=`値は指定しないでください。
- セルフコンパイルインストール。[Gitalyをインストール](../../install/self_compiled/_index.md#install-gitaly)する手順に従います。

### Gitalyサーバーを構成する {#configure-gitaly-servers}

Gitalyサーバーを構成するには、次の操作を行う必要があります:

- 認証を構成します。
- リポジトリストレージのパスを構成します。
- ネットワークリスナーを有効にします。

`git`ユーザーは、構成されたストレージパスに対する読み取り、書き込み、および権限の設定を実行できる必要があります。

Gitalyトークンのローテーション中にダウンタイムが発生しないように、`gitaly['auth_transitioning']`設定を使用して、一時的に認証を無効にすることができます。詳細については、[認証移行モードの有効化](#enable-auth-transitioning-mode)を参照してください。

#### 認証を構成する {#configure-authentication}

GitalyとGitLabは、認証に2つの共有シークレットを使用します:

- _Gitalyトークン_: GitalyへのgRPCリクエストを認証するために使用されます。
- _GitLab Shellトークン_: GitLab ShellからGitLab内部APIへの認証コールバックに使用されます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. _Gitalyトークン_を構成するには、`/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitaly['configuration'] = {
      # ...
      auth: {
        # ...
        token: 'abc123secret',
      },
   }
   ```

1. _GitLab Shellトークン_を構成するには、次の2つの方法があります:

   - 方法1（推奨: ）: GitalyクライアントからGitalyサーバーおよびその他のGitalyクライアント上の同じパスに`/etc/gitlab/gitlab-secrets.json`をコピーします。

   - 方法2:

     1. GitLab Railsを実行しているすべてのノードで、`/etc/gitlab/gitlab.rb`を編集します。
     1. `GITLAB_SHELL_SECRET_TOKEN`を実際のシークレットに置き換えます:

        - GitLab 17.5以降:

          ```ruby
          gitaly['gitlab_secret'] = 'GITLAB_SHELL_SECRET_TOKEN'
          ```

        - GitLab 17.4以前:

          ```ruby
          gitlab_shell['secret_token'] = 'GITLAB_SHELL_SECRET_TOKEN'
          ```

     1. Gitalyを実行しているすべてのノードで、`/etc/gitlab/gitlab.rb`を編集します。
     1. `GITLAB_SHELL_SECRET_TOKEN`を実際のシークレットに置き換えます:

        - GitLab 17.5以降:

          ```ruby
          gitaly['gitlab_secret'] = 'GITLAB_SHELL_SECRET_TOKEN'
          ```

        - GitLab 17.4以前:

          ```ruby
          gitlab_shell['secret_token'] = 'GITLAB_SHELL_SECRET_TOKEN'
          ```

     1. これらの変更後、GitLabを再構成します:

     ```shell
     sudo gitlab-ctl reconfigure
     ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. GitalyクライアントからGitalyサーバー（およびその他のGitalyクライアント）上の同じパスに`/home/git/gitlab/.gitlab_shell_secret`をコピーします。
1. Gitalyクライアントで、`/home/git/gitlab/config/gitlab.yml`を編集します:

   ```yaml
   gitlab:
     gitaly:
       token: 'abc123secret'
   ```

1. ファイルを保存して、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。
1. Gitalyサーバーで、`/home/git/gitaly/config.toml`を編集します:

   ```toml
   [auth]
   token = 'abc123secret'
   ```

1. ファイルを保存して、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}

#### Gitalyサーバーを構成する {#configure-gitaly-server}

<!--
Updates to example must be made at:

- https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-omnibus-gitlab
- https://gitlab.com/gitlab-org/gitlab/blob/master/doc/administration/gitaly/index.md#gitaly-server-configuration
- All reference architecture pages
-->

Gitalyサーバーを構成します。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   # Avoid running unnecessary services on the Gitaly server
   postgresql['enable'] = false
   redis['enable'] = false
   nginx['enable'] = false
   puma['enable'] = false
   sidekiq['enable'] = false
   gitlab_workhorse['enable'] = false
   gitlab_exporter['enable'] = false
   gitlab_kas['enable'] = false

   # If you run a separate monitoring node you can disable these services
   prometheus['enable'] = false
   alertmanager['enable'] = false

   # If you don't run a separate monitoring node you can
   # enable Prometheus access & disable these extra services.
   # This makes Prometheus listen on all interfaces. You must use firewalls to restrict access to this address/port.
   # prometheus['listen_address'] = '0.0.0.0:9090'
   # prometheus['monitor_kubernetes'] = false

   # If you don't want to run monitoring services uncomment the following (not recommended)
   # node_exporter['enable'] = false

   # Prevent database connections during 'gitlab-ctl reconfigure'
   gitlab_rails['auto_migrate'] = false

   # Configure the gitlab-shell API callback URL. Without this, `git push` will
   # fail. This can be your 'front door' GitLab URL or an internal load
   # balancer.
   # Don't forget to copy `/etc/gitlab/gitlab-secrets.json` from Gitaly client to Gitaly server.
   gitlab_rails['internal_api_url'] = 'https://gitlab.example.com'

   gitaly['configuration'] = {
      # ...
      #
      # Make Gitaly accept connections on all network interfaces. You must use
      # firewalls to restrict access to this address/port.
      # Comment out following line if you only want to support TLS connections
      listen_addr: '0.0.0.0:8075',
      auth: {
        # ...
        #
        # Authentication token to ensure only authorized servers can communicate with
        # Gitaly server
        token: 'AUTH_TOKEN',
      },
   }
   ```

1. それぞれのGitalyサーバーについて、次の内容を`/etc/gitlab/gitlab.rb`に追加します:

   <!-- Updates to following example must also be made at https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-omnibus-gitlab -->

   `gitaly1.internal`の場合:

   ```ruby
   gitaly['configuration'] = {
      # ...
      storage: [
         {
            name: 'default',
            path: '/var/opt/gitlab/git-data/repositories',
         },
         {
            name: 'storage1',
            path: '/mnt/gitlab/git-data/repositories',
         },
      ],
   }
   ```

   `gitaly2.internal`の場合:

   ```ruby
   gitaly['configuration'] = {
      # ...
      storage: [
         {
            name: 'storage2',
            path: '/srv/gitlab/git-data/repositories',
         },
      ],
   }
   ```

1. ファイルを保存して[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
1. GitalyがGitLab内部APIにコールバックを実行できることを確認します:

   ```shell
   sudo -u git -- /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitaly/config.toml`を編集します: 

   ```toml
   listen_addr = '0.0.0.0:8075'

   runtime_dir = '/var/opt/gitlab/gitaly'

   [logging]
   format = 'json'
   level = 'info'
   dir = '/var/log/gitaly'
   ```

1. それぞれのGitalyサーバーについて、次の内容を`/home/git/gitaly/config.toml`に追加します:

   `gitaly1.internal`の場合:

   ```toml
   [[storage]]
   name = 'default'
   path = '/var/opt/gitlab/git-data/repositories'

   [[storage]]
   name = 'storage1'
   path = '/mnt/gitlab/git-data/repositories'
   ```

   `gitaly2.internal`の場合:

   ```toml
   [[storage]]
   name = 'storage2'
   path = '/srv/gitlab/git-data/repositories'
   ```

1. `/home/git/gitlab-shell/config.yml`を編集します: 

   ```yaml
   gitlab_url: https://gitlab.example.com
   ```

1. ファイルを保存して、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。
1. GitalyがGitLab内部APIにコールバックを実行できることを確認します:

   ```shell
   sudo -u git -- /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

{{< /tab >}}

{{< /tabs >}}

{{< alert type="warning" >}}

GitLabサーバーからGitalyにリポジトリデータを直接コピーする場合は、メタデータファイル（デフォルトパス`/var/opt/gitlab/git-data/repositories/.gitaly-metadata`）が転送に含まれていないことを確認してください。このファイルをコピーすると、GitLabがGitalyサーバーでホストされているリポジトリへの直接ディスクアクセスを使用するようになり、`Error creating pipeline`および`Commit not found`エラー、または古いデータが発生します。

{{< /alert >}}

### Gitalyクライアントを設定します {#configure-gitaly-clients}

最後の手順として、Gitalyクライアントを更新して、ローカルのGitalyサービスの使用から、構成したばかりのGitalyサーバーを使用するように切り替える必要があります。

{{< alert type="note" >}}

GitLabでは、`default`リポジトリストレージを構成する必要があります。[この制限の詳細](#gitlab-requires-a-default-repository-storage)をご覧ください。

{{< /alert >}}

GitalyクライアントがGitalyサーバーにアクセスできなくなるようなことがあれば、すべてのGitalyリクエストが失敗するため、これは危険な場合があります。たとえば、ネットワーク、ファイアウォール、または名前解決の問題などです。

Gitalyは次のことを前提としています:

- `gitaly1.internal` Gitalyサーバーには、Gitalyクライアントから`gitaly1.internal:8075`でアクセスでき、そのGitalyサーバーは`/var/opt/gitlab/git-data`と`/mnt/gitlab/git-data`の読み取り、書き込み、および権限の設定を実行できます。
- `gitaly2.internal` Gitalyサーバーには、Gitalyクライアントから`gitaly2.internal:8075`でアクセスでき、そのGitalyサーバーは`/srv/gitlab/git-data`の読み取り、書き込み、および権限の設定を実行できます。
- `gitaly1.internal`および`gitaly2.internal` Gitalyサーバーは、相互にアクセスできます。

[混合構成](#mixed-configuration)を使用しない限り、一部をローカルGitalyサーバー（`gitaly_address`なし）として、一部をリモートサーバー（`gitaly_address`あり）としてGitalyサーバーを定義することはできません。

次の2つの方法のいずれかでGitalyクライアントを構成します。これらの手順は暗号化されていない接続用ですが、[TLSサポート](tls_support.md)を有効にすることもできます:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   # Use the same token value configured on all Gitaly servers
   gitlab_rails['gitaly_token'] = '<AUTH_TOKEN>'

   gitlab_rails['repositories_storages'] = {
     'default'  => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
     'storage1' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
     'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075' },
   }
   ```

   または、各Gitalyサーバーが異なる認証トークンを使用するように構成されている場合:

   ```ruby
   gitlab_rails['repositories_storages'] = {
     'default'  => { 'gitaly_address' => 'tcp://gitaly1.internal:8075', 'gitaly_token' => '<AUTH_TOKEN_1>' },
     'storage1' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075', 'gitaly_token' => '<AUTH_TOKEN_1>' },
     'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075', 'gitaly_token' => '<AUTH_TOKEN_2>' },
   }
   ```

1. ファイルを保存して[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
1. Gitalyクライアント（たとえば、Railsアプリケーション）で`sudo gitlab-rake gitlab:gitaly:check`を実行して、Gitalyサーバーに接続できることを確認します。
1. ログを追跡してリクエストを確認します:

   ```shell
   sudo gitlab-ctl tail gitaly
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します: 

   ```yaml
   gitlab:
     repositories:
       storages:
         default:
           gitaly_address: tcp://gitaly1.internal:8075
           gitaly_token: AUTH_TOKEN_1
         storage1:
           gitaly_address: tcp://gitaly1.internal:8075
           gitaly_token: AUTH_TOKEN_1
         storage2:
           gitaly_address: tcp://gitaly2.internal:8075
           gitaly_token: AUTH_TOKEN_2
   ```

1. ファイルを保存して、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。
1. `sudo -u git -H bundle exec rake gitlab:gitaly:check RAILS_ENV=production`を実行して、GitalyクライアントがGitalyサーバーに接続できることを確認します。
1. ログを追跡してリクエストを確認します:

   ```shell
   tail -f /home/git/gitlab/log/gitaly.log
   ```

{{< /tab >}}

{{< /tabs >}}

GitalyサーバーのGitalyログをプルすると、リクエストが届いていることがわかります。Gitalyリクエストをトリガーする確実な方法の1つは、HTTPまたはHTTPS経由でGitLabからリポジトリをクローンすることです。

{{< alert type="warning" >}}

[サーバーフック](../server_hooks.md)を構成している場合、リポジトリごとまたはグローバルに、これらをGitalyサーバーに移動する必要があります。複数のGitalyサーバーがある場合は、サーバーフックをすべてのGitalyサーバーにコピーします。

{{< /alert >}}

#### 混合構成 {#mixed-configuration}

GitLabは、多くのGitalyサーバーの1つと同じサーバー上に存在できますが、ローカル構成とリモート構成を混在させる構成はサポートされていません。次の設定は正しくありません。理由:

- すべてのアドレスは、他のGitalyサーバーから到達できる必要があります。
- `storage1`には、一部のGitalyサーバーに対して無効な`gitaly_address`のUnixソケットが割り当てられています。

```ruby
gitlab_rails['repositories_storages'] = {
  'default' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
  'storage1' => { 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' },
  'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075' },
}
```

ローカルGitalyサーバーとリモートGitalyサーバーを組み合わせるには、ローカルGitalyサーバーに外部アドレスを使用します。例: 

```ruby
gitlab_rails['repositories_storages'] = {
  'default' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
  # Address of the GitLab server that also has Gitaly running on it
  'storage1' => { 'gitaly_address' => 'tcp://gitlab.internal:8075' },
  'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075' },
}

gitaly['configuration'] = {
  # ...
  #
  # Make Gitaly accept connections on all network interfaces
  listen_addr: '0.0.0.0:8075',
  # Or for TLS
  tls_listen_addr: '0.0.0.0:9999',
  tls: {
    certificate_path:  '/etc/gitlab/ssl/cert.pem',
    key_path: '/etc/gitlab/ssl/key.pem',
  },
  storage: [
    {
      name: 'storage1',
      path: '/mnt/gitlab/git-data/repositories',
    },
  ],
}
```

`path`は、ローカルGitalyサーバー上のストレージシャードに対してのみ含めることができます。除外した場合、そのストレージシャードにはデフォルトのGitストレージディレクトリが使用されます。

### GitLabにはデフォルトのリポジトリストレージが必要です {#gitlab-requires-a-default-repository-storage}

Gitalyサーバーを環境に追加する場合、元の`default` Gitalyサービスを置き換えることができます。ただし、GitLabでは`default`というストレージが必要なため、`default`ストレージを削除するようにGitLabアプリケーションサーバーを再構成することはできません。[この制限事項](https://gitlab.com/gitlab-org/gitlab/-/issues/36175)の詳細についてをご覧ください。

制限を回避するには:

1. 新しいGitalyサービス上に追加のストレージ場所を定義し、その追加のストレージが`default`になるように構成します。ストレージの場所には、動作中のストレージを想定するデータベース移行の問題を回避するために、Gitalyサービスが実行されていて、利用可能である必要があります。
1. [**管理者**エリア](../repository_storage_paths.md#configure-where-new-repositories-are-stored)で、`default`をゼロのウェイトに設定して、リポジトリがそこに格納されないようにします。

### 不要なGitalyを無効にする（オプション） {#disable-gitaly-where-not-required-optional}

Gitalyを[リモートサービスとして](#run-gitaly-on-its-own-server)実行する場合は、デフォルトでGitLabサーバー上で実行されるローカルGitalyサービスを無効にすることを検討し、必要な場合にのみ実行します。

GitalyをGitLabインスタンス上で無効にすることは、GitalyがGitLabインスタンスとは別のマシン上で実行されるカスタムクラスター構成でGitLabを実行する場合にのみ意味があります。クラスター内のすべてのマシンでGitalyを無効にすることは、有効な構成ではありません（一部のマシンはGitalyサーバーとして動作する必要があります）。

次の2つの方法のいずれかで、GitLabサーバー上のGitalyを無効にします:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitaly['enable'] = false
   ```

1. ファイルを保存して[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/etc/default/gitlab`を編集します: 

   ```shell
   gitaly_enabled=false
   ```

1. ファイルを保存して、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}

## Gitalyリスナーインターフェースを変更する {#change-the-gitaly-listening-interface}

Gitalyがリッスンするインターフェースを変更できます。Gitalyと通信する必要のある外部サービスがある場合は、リスナーインターフェースを変更することがあります。たとえば、完全一致コードの検索が有効になっているが、実際のサービスが別のサーバーで実行されている場合にZoektを使用する[完全一致コードの検索](../../integration/exact_code_search/zoekt.md)などです。

`gitaly_token`は、`gitaly_token`がGitalyサービスとの認証に使用されるため、シークレット文字列である必要があります。このシークレットは、ランダムな32文字の文字列を生成するために`openssl rand -base64 24`で生成できます。

たとえば、Gitalyリスナーインターフェースを`0.0.0.0:8075`に変更するには:

```ruby
# /etc/gitlab/gitlab.rb
# Add a shared token for Gitaly authentication
gitlab_shell['secret_token'] = 'your_secure_token_here'
gitlab_rails['gitaly_token'] = 'your_secure_token_here'

# Gitaly configuration
gitaly['gitlab_secret'] = 'your_secure_token_here'
gitaly['configuration'] = {
  listen_addr: '0.0.0.0:8075',
  auth: {
    token: 'your_secure_token_here',
  },
  storage: [
    {
      name: 'default',
      path: '/var/opt/gitlab/git-data/repositories',
    },
  ]
}

# Tell Rails where to find Gitaly
gitlab_rails['repositories_storages'] = {
  'default' => { 'gitaly_address' => 'tcp://ip_address_here:8075' },
}

# Internal API URL (important for multi-server setups)
gitlab_rails['internal_api_url'] = 'http://ip_address_here'
```

## コントロールグループ {#control-groups}

コントロールグループの詳細については、[Cgroups](cgroups.md)を参照してください。

## バックグラウンドリポジトリの最適化 {#background-repository-optimization}

Gitリポジトリのオブジェクトデータベースにデータが格納される方法は、時間の経過とともに非効率になる可能性があり、Git操作が遅くなります。これらのアイテムをクリーンアップしてパフォーマンスを向上させるために、最大期間で毎日のバックグラウンドタスクを実行するようにGitalyをスケジュールできます。

{{< alert type="warning" >}}

バックグラウンドリポジトリの最適化は、実行中にホストに大きな負荷をかける可能性があります。ピーク時以外の時間にスケジュールし、期間を短く（たとえば、30〜60分）してください。

{{< /alert >}}

次の2つの方法のいずれかで、バックグラウンドリポジトリの最適化を構成します:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

`/etc/gitlab/gitlab.rb`を編集して、以下を追加します:

```ruby
gitaly['configuration'] = {
  # ...
  daily_maintenance: {
    # ...
    start_hour: 4,
    start_minute: 30,
    duration: '30m',
    storages: ['default'],
  },
}
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

`/home/git/gitaly/config.toml`を編集して、以下を追加します:

```toml
[daily_maintenance]
start_hour = 4
start_minute = 30
duration = '30m'
storages = ["default"]
```

{{< /tab >}}

{{< /tabs >}}

## Gitaly認証トークンをローテーションする {#rotate-gitaly-authentication-token}

本番環境で認証情報をローテーションすると、ダウンタイムが必要になったり、停止が発生したりすることがよくあります。

ただし、サービスを中断することなく、Gitaly認証情報をローテーションできます。Gitaly認証トークンのローテーションには、次のものがあります:

- [認証モニタリング](#verify-authentication-monitoring)の検証。
- [認証移行モードの有効化](#enable-auth-transitioning-mode)。
- [Gitaly認証トークンの更新](#update-gitaly-authentication-token)。
- [認証の失敗がないことを確認する](#ensure-there-are-no-authentication-failures)。
- [認証移行モードの無効化](#disable-auth-transitioning-mode)。
- [認証が強制されていることの確認](#verify-authentication-is-enforced)。

この手順は、単一サーバー上でGitLabを実行している場合にも機能します。その場合、GitalyサーバーとGitalyクライアントは同じマシンを参照します。

### 認証モニタリングを検証する {#verify-authentication-monitoring}

Gitaly認証トークンをローテーションする前に、Prometheusを使用してGitLabインストールの[認証動作をモニタリングできる](monitoring.md#queries)ことを確認してください。

その後、手順の残りを続行できます。

### 認証移行モードを有効にする {#enable-auth-transitioning-mode}

次の手順に従って、Gitalyサーバーを認証移行モードにすることで、GitalyサーバーでのGitaly認証を一時的に無効にします:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
  # ...
  auth: {
    # ...
    transitioning: true,
  },
}
```

この変更を加えた後、[Prometheusクエリ](#verify-authentication-monitoring)は次のようなものを返すはずです:

```promql
{enforced="false",status="would be ok"}  4424.985419441742
```

`enforced="false"`のため、新しいトークンのロールアウトを開始しても安全です。

### Gitaly認証トークンを更新する {#update-gitaly-authentication-token}

新しいGitaly認証トークンに更新するには、各GitalyクライアントおよびGitalyサーバーで次の手順を実行します:

1. 設定を更新します:

   ```ruby
   # in /etc/gitlab/gitlab.rb
   gitaly['configuration'] = {
      # ...
      auth: {
         # ...
         token: '<new secret token>',
      },
   }
   ```

1. Gitalyを再起動します:

   ```shell
   gitlab-ctl restart gitaly
   ```

この変更のロールアウト中に[Prometheusクエリ](#verify-authentication-monitoring)を実行すると、`enforced="false",status="denied"`カウンターにゼロ以外の値が表示されます。

### 認証の失敗がないことを確認する {#ensure-there-are-no-authentication-failures}

新しいトークンが設定され、関係するすべてのサービスが再起動された後、次のものが[一時的に表示されます](#verify-authentication-monitoring):

- `status="would be ok"`。
- `status="denied"`。

新しいトークンがすべてのGitalyクライアントとGitalyサーバーによってプルされた後、ゼロ以外のレートは`enforced="false",status="would be ok"`のみになります。

### 認証移行モードを無効にする {#disable-auth-transitioning-mode}

Gitaly認証を再度有効にするには、認証移行モードを無効にします。次の手順に従って、Gitalyサーバーで構成を更新します:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
  # ...
  auth: {
    # ...
    transitioning: false,
  },
}
```

{{< alert type="warning" >}}

この手順を完了しないと、Gitaly認証は行われません。

{{< /alert >}}

### 認証が適用されていることを確認する {#verify-authentication-is-enforced}

[Prometheusクエリ](#verify-authentication-monitoring)を更新します。これで、開始時と同じような結果が表示されるはずです。例: 

```promql
{enforced="true",status="ok"}  4424.985419441742
```

`enforced="true"`は、認証が適用されていることを意味します。

## Pack-objectsキャッシュ {#pack-objects-cache}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

[Gitaly](_index.md)（Gitリポジトリのストレージを提供するサービス）は、Gitフェッチ応答の短いローリングウィンドウをキャッシュするように構成できます。これにより、サーバーが大量のCIフェッチトラフィックを受信した場合に、サーバーの負荷を軽減できます。

パックオブジェクトのキャッシュは、Gitの内部的な部分である`git pack-objects`をラップし、PostUploadPackおよびSSHUploadPack Gitaly RPCを使用して間接的に呼び出されます。ユーザーがHTTPを使用してGitフェッチを実行すると、GitalyはPostUploadPackを実行し、ユーザーがSSHを使用してGitフェッチを実行すると、SSHUploadPackを実行します。キャッシュが有効になっている場合、PostUploadPackまたはSSHUploadPackを使用するものはすべて、そのメリットをプルできます。以下とは無関係で、影響を受けません:

- トランスポート（HTTPまたはSSH）。
- Gitプロトコルバージョン（v0またはv2）。
- フルクローン、増分フェッチ、シャロークローン、または部分クローンなどのフェッチのタイプ。

このキャッシュの強みは、同時実行される同一のフェッチを重複排除できることです。それは:

- ユーザーが多数の同時ジョブでCI/CDパイプラインを実行するGitLabインスタンスに役立ちます。サーバーのCPU使用率が大幅に低下するはずです。
- まったく独自のフェッチにはメリットがありません。たとえば、リポジトリをローカルコンピューターにクローンしてスポットチェックを実行する場合、フェッチはおそらく一意であるため、このキャッシュからメリットが得られる可能性は低いです。

パックオブジェクトのキャッシュはローカルキャッシュです。それは:

- 有効になっているGitalyプロセスのメモリにメタデータを格納します。
- ローカルストレージ上のファイルにキャッシュしている実際のGitデータを格納します。

ローカルファイルを使用すると、オペレーティングシステムがパックオブジェクトのキャッシュファイルの一部をRAMに自動的に保持し、高速化できるというメリットがあります。

パックオブジェクトのキャッシュにより、ディスク書き込みIOが大幅に増加する可能性があるため、デフォルトではオフになっています。

### 設定を構成 {#configure-the-cache}

これらの構成設定は、パックオブジェクトのキャッシュで使用できます。各設定については、以下で詳しく説明します。

| 設定   | デフォルト                                            | 説明                                                                                        |
|:----------|:---------------------------------------------------|:---------------------------------------------------------------------------------------------------|
| `enabled` | `false`                                            | キャッシュをオンにします。オフの場合、Gitalyはリクエストごとに専用の`git pack-objects`プロセスを実行します。 |
| `dir`     | `<PATH TO FIRST STORAGE>/+gitaly/PackObjectsCache` | キャッシュファイルを格納するローカルディレクトリ。                                                      |
| `max_age` | `5m`（5分）                                   | これより古いエントリは削除され、ディスクから削除されます。                                   |
| `min_occurrences` | 1 | キャッシュエントリが作成される前に、キーが発生する必要がある最小回数。 |

`/etc/gitlab/gitlab.rb`で、次のように設定します:

```ruby
gitaly['configuration'] = {
  # ...
  pack_objects_cache: {
    enabled: true,
    # The default settings for "dir", "max_age" and "min_occurences" should be fine.
    # If you want to customize these, see details below.
  },
}
```

#### `enabled`のデフォルトは`false` {#enabled-defaults-to-false}

キャッシュは、[極端な増加](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/4010#note_534564684)を招く場合があるため、デフォルトで無効になっています。GitLab.comでは、リポジトリストレージディスクがこの追加のワークロードを処理できることを確認していますが、どこでもこれが当てはまるとは限りません。

#### キャッシュストレージディレクトリ`dir` {#cache-storage-directory-dir}

キャッシュには、ファイルを格納するためのディレクトリが必要です。このディレクトリは次のようになります:

- 十分なスペースのあるファイルシステム内。キャッシュファイルシステムのスペースがなくなると、すべてのフェッチが失敗し始めます。
- 十分なIO帯域幅を持つディスク上。キャッシュディスクのIO帯域幅がなくなると、すべてのフェッチ、おそらくサーバー全体が遅くなります。

{{< alert type="warning" >}}

指定されたディレクトリ内の既存のデータはすべて削除されます。既存のデータを含むディレクトリは使用しないように注意してください。

{{< /alert >}}

デフォルトでは、キャッシュストレージディレクトリは、設定ファイルで定義されている最初のGitalyストレージのサブディレクトリに設定されます。

複数のGitalyプロセスで、キャッシュストレージに同じディレクトリを使用できます。各Gitalyプロセスは、作成するキャッシュファイル名の一部として、一意のランダム文字列を使用します。これは、次の意味をもちます:

- 衝突しません。
- 別のプロセスのファイルを再利用しません。

デフォルトのディレクトリは、リポジトリデータと同じファイルシステムにキャッシュファイルをパックしますが、これは要件ではありません。インフラストラクチャに適している場合は、キャッシュファイルを別のファイルシステムにパックできます。

ディスクから必要なIO帯域幅の量は、次によって異なります:

- Gitalyサーバー上のリポジトリのサイズと形状。
- ユーザーが生成するタイプのトラフィック。

キャッシュヒット率が0％であると仮定して、`gitaly_pack_objects_generated_bytes_total`メトリクスを悲観的な見積もりとして使用できます。

必要なスペースの量は、次によって異なります:

- ユーザーがキャッシュからプルする1秒あたりのバイト数。
- `max_age`キャッシュ削除ウィンドウのサイズ。

ユーザーが100 MB/秒をプルし、5分のウィンドウを使用すると、平均して`5*60*100 MB = 30 GB`のデータがキャッシュディレクトリにパックされます。この平均は、保証ではなく、予想される平均です。ピークサイズがこの平均を超える場合があります。

#### キャッシュ削除ウィンドウ`max_age` {#cache-eviction-window-max_age}

`max_age`構成設定を使用すると、キャッシュヒットの可能性と、キャッシュファイルで使用されるストレージの平均量を制御できます。`max_age`より古いエントリはディスクから削除されます。

削除は、進行中のリクエストを妨げません。Unixファイルシステムは、削除されたファイルを読み取っているすべてのプロセスがファイルを閉じるまで、ファイルを実際に削除しないため、低速接続でフェッチを実行するのにかかる時間よりも`max_age`が短くても問題ありません。

#### キーの発生回数`min_occurrences` {#minimum-key-occurrences-min_occurrences}

`min_occurrences`設定は、新しいキャッシュエントリを作成する前に、同一のリクエストが発生する必要がある頻度を制御します。デフォルト値は`1`で、一意のリクエストはキャッシュに書き込まれません。

次の場合:

- この数値を増やすと、キャッシュヒット率が低下し、キャッシュの使用ディスクスペースが少なくなります。
- この数値を減らすと、キャッシュヒット率が上がり、キャッシュの使用ディスクスペースが増えます。

`min_occurrences`を`1`に設定する必要があります。GitLab.comでは、0から1にすると、キャッシュヒット率にほとんど影響を与えずに、キャッシュディスクスペースが50％節約されました。

### キャッシュを監視する {#observe-the-cache}

{{< history >}}

- パックオブジェクトのキャッシュのログは、[変更](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/5719)されましたGitLab 16.0。

{{< /history >}}

[メトリクスを使用](monitoring.md#pack-objects-cache)して、および次のログに記録された情報でキャッシュを監視できます。これらのログはgRPCログの一部であり、呼び出しが実行されると検出できます。

| フィールド | 説明 |
|:---|:---|
| `pack_objects_cache.hit` | 現在のパックオブジェクトのキャッシュがヒットしたかどうかを示します（`true`または`false`）。 |
| `pack_objects_cache.key` | パックオブジェクトのキャッシュに使用されるキーです |
| `pack_objects_cache.generated_bytes` | 書き込まれている新しいキャッシュのサイズ（バイト単位） |
| `pack_objects_cache.served_bytes` | 処理されているキャッシュのサイズ（バイト単位） |
| `pack_objects.compression_statistics` | パックオブジェクトの生成に関する統計 |
| `pack_objects.enumerate_objects_ms` | クライアントから送信されたオブジェクトの列挙に費やされた合計時間（ミリ秒単位） |
| `pack_objects.prepare_pack_ms` | クライアントに送り返す前に、パックファイルの準備に費やされた合計時間（ミリ秒単位） |
| `pack_objects.write_pack_file_ms` | クライアントにパックファイルを送り返すのに費やされた合計時間（ミリ秒単位）。クライアントのインターネット接続に大きく依存します |
| `pack_objects.written_object_count` | Gitalyがクライアントに送り返すオブジェクトの合計数 |

次の場合:

- キャッシュミス、Gitalyは`pack_objects_cache.generated_bytes`メッセージと`pack_objects_cache.served_bytes`メッセージの両方をログに記録します。Gitalyは、パックオブジェクトの生成に関するより詳細な統計もログに記録します。
- キャッシュヒット、Gitalyは`pack_objects_cache.served_bytes`メッセージのみをログに記録します。

例: 

```json
{
  "bytes":26186490,
  "correlation_id":"01F1MY8JXC3FZN14JBG1H42G9F",
  "grpc.meta.deadline_type":"none",
  "grpc.method":"PackObjectsHook",
  "grpc.request.fullMethod":"/gitaly.HookService/PackObjectsHook",
  "grpc.request.glProjectPath":"root/gitlab-workhorse",
  "grpc.request.glRepository":"project-2",
  "grpc.request.repoPath":"@hashed/d4/73/d4735e3a265e16eee03f59718b9b5d03019c07d8b6c51f90da3a666eec13ab35.git",
  "grpc.request.repoStorage":"default",
  "grpc.request.topLevelGroup":"@hashed",
  "grpc.service":"gitaly.HookService",
  "grpc.start_time":"2021-03-25T14:57:52.747Z",
  "level":"info",
  "msg":"finished unary call with code OK",
  "peer.address":"@",
  "pid":20961,
  "span.kind":"server",
  "system":"grpc",
  "time":"2021-03-25T14:57:53.543Z",
  "pack_objects.compression_statistics": "Total 145991 (delta 68), reused 6 (delta 2), pack-reused 145911",
  "pack_objects.enumerate_objects_ms": 170,
  "pack_objects.prepare_pack_ms": 7,
  "pack_objects.write_pack_file_ms": 786,
  "pack_objects.written_object_count": 145991,
  "pack_objects_cache.generated_bytes": 49533030,
  "pack_objects_cache.hit": "false",
  "pack_objects_cache.key": "123456789",
  "pack_objects_cache.served_bytes": 49533030,
  "peer.address": "127.0.0.1",
  "pid": 8813,
}
```

## `cat-file`キャッシュ {#cat-file-cache}

多くのGitaly RPCは、リポジトリからGitオブジェクトを検索する必要があります。ほとんどの場合、`git cat-file --batch`プロセスを使用します。パフォーマンスを向上させるために、Gitalyはこれらの`git cat-file`プロセスをRPC呼び出し全体で再利用できます。以前に使用されたプロセスは、[`git cat-file`キャッシュ](https://about.gitlab.com/blog/2019/07/08/git-performance-on-nfs/#enter-cat-file-cache)に保持されます。システムリソースの消費量を制御するために、キャッシュにパックできるcat-fileプロセスの最大数があります。

デフォルトの制限は100 `cat-file`であり、`git cat-file --batch`および`git cat-file --batch-check`プロセスのペアを構成します。"too many open files"に関するエラー、または新しいプロセスを作成できないというエラーが表示される場合は、この制限を下げたい場合があります。

理想的には、この数は標準的なトラフィックを処理するのに十分な大きさである必要があります。制限を引き上げる場合は、前後にキャッシュヒット率を測定する必要があります。ヒット率が向上しない場合、制限を高くしても意味のある違いは生じない可能性があります。ヒット率を確認するためのPrometheusクエリの例を次に示します:

```plaintext
sum(rate(gitaly_catfile_cache_total{type="hit"}[5m])) / sum(rate(gitaly_catfile_cache_total{type=~"(hit)|(miss)"}[5m]))
```

Gitaly構成ファイルで`cat-file`キャッシュを設定します。

## GitLab UIコミットのコミット署名を構成する {#configure-commit-signing-for-gitlab-ui-commits}

{{< history >}}

- 署名されたGitLab UIコミットの**検証済み**バッジの表示`gitaly_gpg_signing`という名前の[フラグ付き](../feature_flags/_index.md)のGitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124218)されました。デフォルトでは無効になっています。
- `rotated_signing_keys`オプションで指定された複数のキーを使用して署名を検証するGitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6163)。
- GitLab 17.0のGitLab DedicatedとSelf-Managedで[デフォルトで有効](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6876)。

{{< /history >}}

{{< alert type="flag" >}}

GitLab Self-Managedでは、デフォルトでこの機能を利用できます。この機能を非表示にするために、管理者は`gitaly_gpg_signing`という名前の[機能フラグを無効](../feature_flags/_index.md)にできます。GitLab.comでは、この機能は利用できません。GitLab Dedicatedでは、この機能は利用できません。

{{< /alert >}}

デフォルトでは、GitalyはGitLab UIを使用して作成されたコミットに署名しません。たとえば、次を使用して作成されたコミット:

- Webエディタ。
- Web IDE。
- マージリクエスト。

Gitalyでコミット署名を有効にすると:

- GitLabは、UIを介して作成されたすべてのコミットに署名します。
- 署名は、作成者のIDではなく、コミッターのIDを検証します。
- `committer_email`と`committer_name`を設定することで、コミットがインスタンスによってコミットされたことを反映するようにGitalyを構成できます。たとえば、GitLab.comでは、これらの構成オプションは`noreply@gitlab.com`と`GitLab`に設定されています。

`rotated_signing_keys`は、検証にのみ使用するキーのリストです。Gitalyは、設定された`signing_key`を使用してWebコミットを検証しようとし、成功するまでローテーションされたキーを1つずつ使用します。いずれかの場合、`rotated_signing_keys`オプションを設定します:

- 署名キーがローテーションされます。
- 他のインスタンスからプロジェクトを移行するための複数のキーを指定し、Webコミットを**検証済み**として表示する場合。

GitLab UIで作成されたコミットに署名するようにGitalyを構成するには、次の2つの方法があります:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. [GPGキーを作成](../../user/project/repository/signed_commits/gpg.md#create-a-gpg-key)してエクスポートするか、[SSHキーを作成](../../user/ssh.md#generate-an-ssh-key-pair)します。最適なパフォーマンスを得るには、EdDSAキーを使用します。

   エクスポートGPGキー:

   ```shell
   gpg --export-secret-keys <ID> > signing_key.gpg
   ```

   または、（パスフレーズなしで）SSHキーを作成します:

   ```shell
   ssh-keygen -t ed25519 -f signing_key.ssh
   ```

1. Gitalyノードで、キーを`/etc/gitlab/gitaly/`にコピーし、`git`ユーザーにファイルを読み取る権限があることを確認します。
1. `/etc/gitlab/gitlab.rb`を編集し、`gitaly['git']['signing_key']`を構成します:

   ```ruby
   gitaly['configuration'] = {
      # ...
      git: {
        # ...
        committer_name: 'Your Instance',
        committer_email: 'noreply@yourinstance.com',
        signing_key: '/etc/gitlab/gitaly/signing_key.gpg',
        rotated_signing_keys: ['/etc/gitlab/gitaly/previous_signing_key.gpg'],
        # ...
      },
   }
   ```

1. ファイルを保存して[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. [GPGキーを作成](../../user/project/repository/signed_commits/gpg.md#create-a-gpg-key)してエクスポートするか、[SSHキーを作成](../../user/ssh.md#generate-an-ssh-key-pair)します。最適なパフォーマンスを得るには、EdDSAキーを使用します。

   エクスポートGPGキー:

   ```shell
   gpg --export-secret-keys <ID> > signing_key.gpg
   ```

   または、（パスフレーズなしで）SSHキーを作成します:

   ```shell
   ssh-keygen -t ed25519 -f signing_key.ssh
   ```

1. Gitalyノードで、キーを`/etc/gitlab`にコピーします。
1. `/home/git/gitaly/config.toml`を編集し、`signing_key`を構成します:

   ```toml
   [git]
   committer_name = "Your Instance"
   committer_email = "noreply@yourinstance.com"
   signing_key = "/etc/gitlab/gitaly/signing_key.gpg"
   rotated_signing_keys = ["/etc/gitlab/gitaly/previous_signing_key.gpg"]
   ```

1. ファイルを保存して、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}

## 外部コマンドを使用して設定を生成する {#generate-configuration-using-an-external-command}

外部コマンドを使用して、Gitaly構成の一部を生成できます。これは、次の場合に行うことができます:

- 各ノードに完全な構成を配布しなくても、ノードを設定するため。
- ノードの設定の自動検出を使用して構成するため。たとえば、DNSエントリを使用します。
- ノードの起動時にシークレットを設定し、プレーンテキストで表示する必要がないようにするため。

外部コマンドを使用して設定を生成するには、Gitalyノードの目的の設定をJSON形式で標準出力にダンプするスクリプトを提供する必要があります。

たとえば、次のコマンドは、AWSシークレットを使用してGitLab内部APIへの接続に使用されるHTTPパスワードを設定します:

```ruby
#!/usr/bin/env ruby
require 'json'
JSON.generate({"gitlab": {"http_settings": {"password": `aws get-secret-value --secret-id ...`}}})
```

次に、スクリプトのパスをGitalyに次の2つの方法のいずれかで認識させる必要があります:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

`/etc/gitlab/gitlab.rb`を編集し、`config_command`を構成します:

```ruby
gitaly['configuration'] = {
    config_command: '/path/to/config_command',
}
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

`/home/git/gitaly/config.toml`を編集し、`config_command`を構成します:

```toml
config_command = "/path/to/config_command"
```

{{< /tab >}}

{{< /tabs >}}

設定後、Gitalyは起動時にコマンドを実行し、標準出力をJSONとして解析中します。結果として得られる設定は、他のGitaly構成にマージされます。

Gitalyは、次のいずれかの場合に起動に失敗します:

- 構成コマンドが失敗します。
- コマンドによって生成された出力を有効なJSONとして解析できません。

## サーバー側のバックアップを構成する {#configure-server-side-backups}

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitaly/-/issues/4941)されました。
- 最新のバックアップではなく、指定されたバックアップを復元するためのサーバーサイドサポートが、GitLab 16.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132188)されました。
- GitLab 16.6で増分バックアップを作成するためのサーバー側のサポートが[導入](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6475)されました。
- GitLab 17.0でHelmチャートインストールに追加されたサーバー側のサポート。

{{< /history >}}

リポジトリバックアップは、各リポジトリをホストするGitalyノードがバックアップの作成とオブジェクトストレージへのストリーミングを担当するように構成できます。これにより、バックアップの作成と復元に必要なネットワークリソースを削減できます。

各Gitalyノードは、バックアップのためにオブジェクトストレージに接続するように構成する必要があります。

サーバー側のバックアップを構成した後、[サーバー側のリポジトリバックアップを作成](../backup_restore/backup_gitlab.md#create-server-side-repository-backups)できます。

### Azure Blob Storageを設定するには、次の手順に従います。 {#configure-azure-blob-storage}

バックアップのためにAzure BLOBストレージを構成する方法は、お使いのインストールの種類によって異なります。セルフコンパイルインストールでは、`AZURE_STORAGE_ACCOUNT`と`AZURE_STORAGE_KEY`の環境変数をGitLabの外部に設定する必要があります。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

`/etc/gitlab/gitlab.rb`を編集し、`go_cloud_url`を構成します:

```ruby
gitaly['env'] = {
    'AZURE_STORAGE_ACCOUNT' => 'azure_storage_account',
    'AZURE_STORAGE_KEY' => 'azure_storage_key' # or 'AZURE_STORAGE_SAS_TOKEN'
}
gitaly['configuration'] = {
    backup: {
        go_cloud_url: 'azblob://<bucket>'
    }
}
```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

Helmベースのデプロイについては、[Gitalyチャートのサーバー側のバックアップドキュメント](https://docs.gitlab.com/charts/charts/gitlab/gitaly/#server-side-backups)を参照してください。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

`/home/git/gitaly/config.toml`を編集し、`go_cloud_url`を構成します:

```toml
[backup]
go_cloud_url = "azblob://<bucket>"
```

{{< /tab >}}

{{< /tabs >}}

### Google Cloud Storageを構成する {#configure-google-cloud-storage}

Google Cloud Storage（GCP）は、アプリケーションデフォルトの認証情報を使用して認証します。各Gitalyサーバーで、次のいずれかの方法でアプリケーションデフォルトの認証情報を設定します:

- [`gcloud auth application-default login`](https://cloud.google.com/sdk/gcloud/reference/auth/application-default/login)コマンド。
- `GOOGLE_APPLICATION_CREDENTIALS`環境変数。セルフコンパイルインストールの場合、環境変数をGitLabの外部に設定します。

詳細については、[アプリケーションデフォルトの認証情報](https://cloud.google.com/docs/authentication/provide-credentials-adc)を参照してください。

宛先バケットは、`go_cloud_url`オプションを使用して構成されます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

`/etc/gitlab/gitlab.rb`を編集し、`go_cloud_url`を構成します:

```ruby
gitaly['env'] = {
    'GOOGLE_APPLICATION_CREDENTIALS' => '/path/to/service.json'
}
gitaly['configuration'] = {
    backup: {
        go_cloud_url: 'gs://<bucket>'
    }
}
```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

Helmベースのデプロイについては、[Gitalyチャートのサーバー側のバックアップドキュメント](https://docs.gitlab.com/charts/charts/gitlab/gitaly/#server-side-backups)を参照してください。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

`/home/git/gitaly/config.toml`を編集し、`go_cloud_url`を構成します:

```toml
[backup]
go_cloud_url = "gs://<bucket>"
```

{{< /tab >}}

{{< /tabs >}}

### S3ストレージを構成する {#configure-s3-storage}

S3ストレージの認証を構成するには、以下を実行します:

- AWS CLIで認証する場合は、デフォルトのAWSセッションを使用できます。
- それ以外の場合は、`AWS_ACCESS_KEY_ID`と`AWS_SECRET_ACCESS_KEY`の環境変数を使用できます。セルフコンパイルインストールでは、環境変数をGitLabの外部に設定します。

詳細については、[AWSセッションのドキュメント](https://docs.aws.amazon.com/sdk-for-go/api/aws/session/)を参照してください。

宛先バケットとAWSリージョンは、`go_cloud_url`オプションを使用して構成されます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

`/etc/gitlab/gitlab.rb`を編集し、`go_cloud_url`を構成します:

```ruby
gitaly['env'] = {
    'AWS_ACCESS_KEY_ID' => 'aws_access_key_id',
    'AWS_SECRET_ACCESS_KEY' => 'aws_secret_access_key'
}
gitaly['configuration'] = {
    backup: {
        go_cloud_url: 's3://<bucket>?region=us-west-1'
    }
}
```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

Helmベースのデプロイについては、[Gitalyチャートのサーバー側のバックアップドキュメント](https://docs.gitlab.com/charts/charts/gitlab/gitaly/#server-side-backups)を参照してください。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

`/home/git/gitaly/config.toml`を編集し、`go_cloud_url`を構成します:

```toml
[backup]
go_cloud_url = "s3://<bucket>?region=us-west-1"
```

{{< /tab >}}

{{< /tabs >}}

#### S3互換サーバーを構成する {#configure-s3-compatible-servers}

MinIOなどのS3互換サーバーは、`endpoint`パラメータを追加して、S3と同様に構成されます。

次のパラメータがサポートされています:

- `region`: AWSリージョン。
- `endpoint`: は、エンドポイントのURLです。
- `disabledSSL`: `true`の値は、SSLを無効にします。
- `s3ForcePathStyle`: `true`の値は、パススタイルのアドレス指定を強制します。

{{< tabs >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

Helmベースのデプロイについては、[Gitalyチャートのサーバー側のバックアップドキュメント](https://docs.gitlab.com/charts/charts/gitlab/gitaly/#server-side-backups)を参照してください。

{{< /tab >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

`/etc/gitlab/gitlab.rb`を編集し、`go_cloud_url`を構成します:

```ruby
gitaly['env'] = {
    'AWS_ACCESS_KEY_ID' => 'minio_access_key_id',
    'AWS_SECRET_ACCESS_KEY' => 'minio_secret_access_key'
}
gitaly['configuration'] = {
    backup: {
        go_cloud_url: 's3://<bucket>?region=minio&endpoint=my.minio.local:8080&disableSSL=true&s3ForcePathStyle=true'
    }
}
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

`/home/git/gitaly/config.toml`を編集し、`go_cloud_url`を構成します:

```toml
[backup]
go_cloud_url = "s3://<bucket>?region=minio&endpoint=my.minio.local:8080&disableSSL=true&s3ForcePathStyle=true"
```

{{< /tab >}}

{{< /tabs >}}
