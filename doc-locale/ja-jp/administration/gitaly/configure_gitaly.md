---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Gitalyを設定する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Gitalyは2つの方法のいずれかで設定できます:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集して、Gitalyの設定を追加または変更します。[Gitalyの設定ファイル](https://gitlab.com/gitlab-org/gitaly/-/blob/master/config.toml.example)の例を参照してください。例ファイル内の設定は、Rubyに変換する必要があります。
1. ファイルを保存して[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. [Gitalyのチャート](https://docs.gitlab.com/charts/charts/gitlab/gitaly/)を設定します。
1. [Helmリリースをアップグレード](https://docs.gitlab.com/charts/installation/deployment/)します。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitaly/config.toml`を編集して、Gitalyの設定を追加または変更します。[Gitalyの設定ファイル](https://gitlab.com/gitlab-org/gitaly/-/blob/master/config.toml.example)の例を参照してください。
1. ファイルを保存し、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}

次の設定オプションも利用可能です:

- [TLSサポート](tls_support.md)を有効にします。
- [RPC並行処理](concurrency_limiting.md#limit-rpc-concurrency)を制限します。
- [pack-objects並行処理](concurrency_limiting.md#limit-pack-objects-concurrency)を制限します。

## Gitalyトークンについて {#about-the-gitaly-token}

Gitalyのドキュメント全体で参照されているトークンは、管理者によって選択された任意のパスワードです。これは、GitLab API用またはその他の類似のWeb APIトークン用に作成されたトークンとは無関係です。

## Gitalyを専用サーバーで実行する {#run-gitaly-on-its-own-server}

デフォルトでは、GitalyはGitalyクライアントと同じサーバーで実行され、前述のとおり設定されます。シングルサーバーインストールは、デフォルトで次の設定を使用するのが最適です:

- [Linuxパッケージのインストール](https://docs.gitlab.com/omnibus/)。
- [セルフコンパイルインストール](../../install/self_compiled/_index.md)。

ただし、Gitalyは専用サーバーにデプロイでき、これにより複数のマシンにまたがるGitLabインストールにメリットがあります。

> [!note]
> 専用サーバーで実行するように設定されている場合、Gitalyサーバーはクラスター内のGitalyクライアントより先に[アップグレード](../../update/package/_index.md)する必要があります。

Gitalyを専用サーバーに設定するプロセスは次のとおりです:

1. [Gitalyをインストール](#install-gitaly)します。
1. [認証を設定](#configure-authentication)します。
1. [Gitalyサーバーを設定](#configure-gitaly-servers)します。
1. [Gitalyクライアントを設定](#configure-gitaly-clients)します。
1. [Gitalyが不要な場所で無効化](#disable-gitaly-where-not-required-optional)します（オプション）。

> [!note]
> [ディスク要件](_index.md#disk-requirements)はGitalyノードに適用されます。

### ネットワークアーキテクチャ {#network-architecture}

次のリストはGitalyのネットワークアーキテクチャを示しています:

- GitLab Railsはリポジトリを[リポジトリストレージ](../repository_storage_paths.md)にシャードします。
- `/config/gitlab.yml`には、ストレージ名から`(Gitaly address, Gitaly token)`ペアへのマップが含まれています。
- `/config/gitlab.yml`内の`storage name` -> `(Gitaly address, Gitaly token)`マップは、Gitalyネットワークトポロジの信頼できる唯一の情報源です。
- `(Gitaly address, Gitaly token)`はGitalyサーバーに対応します。
- Gitalyサーバーは1つまたは複数のストレージをホストします。
- Gitalyクライアントは1つまたは複数のGitalyサーバーを使用できます。
- Gitalyアドレスは、すべてのGitalyクライアントに対して正しく解決されるように指定する必要があります。
- Gitalyクライアントは次のとおりです:
  - Puma。
  - Sidekiq。
  - GitLab Workhorse。
  - GitLab Shell。
  - Elasticsearchインデクサー。
  - Gitaly自体。
- Gitalyサーバーは、`/config/gitlab.yml`で指定されている独自の`(Gitaly address, Gitaly token)`ペアを使用して、それ自体にRPCsコールを行うことができる必要があります。
- 認証は、GitalyノードとGitLab Railsノード間で共有される静的トークンを介して行われます。

次の図は、GitalyサーバーとGitLab Rails間の通信を、HTTPおよびHTTPs通信のデフォルトポートと共に示しています。

![2つのGitalyサーバーとGitLab Railsが情報交換を行っています。](img/gitaly_network_v13_9.png)

> [!warning]
> Gitalyサーバーは、Gitalyのネットワークトラフィックがデフォルトで暗号化されていないため、パブリックインターネットに公開してはなりません。Gitalyサーバーへのアクセスを制限するために、ファイアウォールの使用を強くお勧めします。別のオプションは、[TLSを使用する](tls_support.md)ことです。

次のセクションでは、シークレットトークン`abc123secret`を使用して2つのGitalyサーバーを設定する方法について説明します:

- `gitaly1.internal`。
- `gitaly2.internal`。

GitLabインストールには3つのリポジトリストレージがあるものとします:

- `default`。
- `storage1`。
- `storage2`。

必要に応じて、1つのサーバーで1つのリポジトリストレージを使用することも可能です。

### Gitalyをインストールする {#install-gitaly}

各Gitalyサーバーに次のいずれかの方法でGitalyをインストールします:

- Linuxパッケージのインストール。目的のLinuxパッケージを[ダウンロードしてインストール](https://about.gitlab.com/install/)しますが、`EXTERNAL_URL=`の値を指定しないでください。
- セルフコンパイルインストール。[Gitalyのインストール](../../install/self_compiled/_index.md#install-gitaly)の手順に従ってください。

### Gitalyサーバーの設定 {#configure-gitaly-servers}

Gitalyサーバーを設定するには、次の手順を実行する必要があります:

- 認証を設定します。
- ストレージパスを設定します。
- ネットワークリスナーを有効にします。

The `git` user must be able to読み取り, 書き込み、および設定されたストレージパス上の権限を設定できる必要があります。

Gitalyトークンをローテーションしている間の停止を回避するために、`gitaly['auth_transitioning']`設定を使用して認証を一時的に無効にすることができます。詳細については、[認証遷移モードを有効にする](#enable-auth-transitioning-mode)を参照してください。

#### 認証の設定 {#configure-authentication}

GitalyとGitLabは、認証に2つの共有シークレットを使用します:

- _Gitalyトークン_: GitalyへのgRPCリクエストを認証するために使用されます。
- _GitLab Shellトークン_: GitLab ShellからGitLab内部APIへの認証コールバックに使用されます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. _Gitalyトークン_を設定するには、`/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   gitaly['configuration'] = {
      # ...
      auth: {
        # ...
        token: 'abc123secret',
      },
   }
   ```

1. _GitLab Shellトークン_を次の2つの方法のいずれかで設定します:

   - 方法1（推奨）: `/etc/gitlab/gitlab-secrets.json`をGitalyクライアントからGitalyサーバーおよびその他のGitalyクライアントの同じパスにコピーします。

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

     1. これらの変更後、GitLabを再設定します:

     ```shell
     sudo gitlab-ctl reconfigure
     ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/.gitlab_shell_secret`をGitalyクライアントからGitalyサーバー（およびその他のGitalyクライアント）の同じパスにコピーします。
1. Gitalyクライアントで、`/home/git/gitlab/config/gitlab.yml`を編集します:

   ```yaml
   gitlab:
     gitaly:
       token: 'abc123secret'
   ```

1. ファイルを保存し、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。
1. Gitalyサーバーで、`/home/git/gitaly/config.toml`を編集します:

   ```toml
   [auth]
   token = 'abc123secret'
   ```

1. ファイルを保存し、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}

#### Gitalyサーバーを設定する {#configure-gitaly-server}

<!--
Updates to example must be made at:

- <https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-linux-package-installation>
- <https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/administration/gitaly/praefect/configure.md#praefect>
- All reference architecture pages
-->

Gitalyサーバーを設定します。

Gitalyには、クライアント（RailsやSidekiqなど）によって提供されるアドレスを使用して、それ自体にRPCsコールを行うネットワーク呼び出しがいくつかあります。

ネットワーク設定が原因でGitalyがこの方法でそれ自体に到達できない場合（たとえば、Gitalyがヘアピン接続をサポートしないロードバランサーの背後にある場合）:

1. Gitalyサーバーの`/etc/hosts`ファイルを編集します。
1. クライアントが使用するGitalyアドレスをGitalyサーバー自身のIPアドレスにリダイレクトするためのエントリを追加します。例: `127.0.0.1 gitaly.example.com`、`<local-ip> gitaly.example.com`。

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

1. 各Gitalyサーバーに`/etc/gitlab/gitlab.rb`に次の内容を追加します:

   <!-- Updates to following example must also be made at https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-omnibus-gitlab -->

   `gitaly1.internal`で:

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

   `gitaly2.internal`で:

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
1. GitalyがGitLab内部APIへのコールバックを実行できることを確認します:

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

1. 各Gitalyサーバーに`/home/git/gitaly/config.toml`に次の内容を追加します:

   `gitaly1.internal`で:

   ```toml
   [[storage]]
   name = 'default'
   path = '/var/opt/gitlab/git-data/repositories'

   [[storage]]
   name = 'storage1'
   path = '/mnt/gitlab/git-data/repositories'
   ```

   `gitaly2.internal`で:

   ```toml
   [[storage]]
   name = 'storage2'
   path = '/srv/gitlab/git-data/repositories'
   ```

1. `/home/git/gitlab-shell/config.yml`を編集します:

   ```yaml
   gitlab_url: https://gitlab.example.com
   ```

1. ファイルを保存し、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。
1. GitalyがGitLab内部APIへのコールバックを実行できることを確認します:

   ```shell
   sudo -u git -- /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

{{< /tab >}}

{{< /tabs >}}

> [!warning]
> GitLabサーバーからGitalyにリポジトリデータを直接コピーする場合は、メタデータファイル（デフォルトパス`/var/opt/gitlab/git-data/repositories/.gitaly-metadata`）が転送に含まれていないことを確認してください。このファイルをコピーすると、GitLabがGitalyサーバーでホストされているリポジトリへの直接ディスクアクセスを使用するようになり、`Error creating pipeline`や`Commit not found`エラー、または古いデータが発生します。

### Gitalyクライアントの設定 {#configure-gitaly-clients}

最後のステップとして、Gitalyクライアントを更新して、ローカルGitalyサービスの使用から、設定したGitalyサーバーを使用するように切り替える必要があります。

> [!note]
> GitLabは`default`リポジトリストレージが設定されている必要があります。[この制限の詳細](#gitlab-requires-a-default-repository-storage)をご覧ください。

GitalyクライアントがGitalyサーバーに到達できないようにするものはすべて、すべてのGitalyリクエストを失敗させるため、これは危険を伴う可能性があります。例えば、あらゆる種類のネットワーク、ファイアウォール、または名前解決の問題など。

Gitalyは次の仮定に基づいています:

- あなたの`gitaly1.internal` Gitalyサーバーは、Gitalyクライアントから`gitaly1.internal:8075`で到達可能であり、そのGitalyサーバーは`/var/opt/gitlab/git-data`および`/mnt/gitlab/git-data`に対する読み取り、書き込み、および権限の設定を行うことができます。
- あなたの`gitaly2.internal` Gitalyサーバーは、Gitalyクライアントから`gitaly2.internal:8075`で到達可能であり、そのGitalyサーバーは`/srv/gitlab/git-data`に対する読み取り、書き込み、および権限の設定を行うことができます。
- あなたの`gitaly1.internal`と`gitaly2.internal` Gitalyサーバーは互いに到達可能です。

[混合設定](#mixed-configuration)を使用しない限り、一部をローカルGitalyサーバー（`gitaly_address`なし）として、一部をリモートサーバー（`gitaly_address`あり）としてGitalyサーバーを定義することはできません。

Gitalyクライアントを次の2つの方法のいずれかで設定します。これらの手順は暗号化されていない接続用ですが、[TLSサポート](tls_support.md)を有効にすることもできます:

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

   あるいは、各Gitalyサーバーが異なる認証トークンを使用するように設定されている場合:

   ```ruby
   gitlab_rails['repositories_storages'] = {
     'default'  => { 'gitaly_address' => 'tcp://gitaly1.internal:8075', 'gitaly_token' => '<AUTH_TOKEN_1>' },
     'storage1' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075', 'gitaly_token' => '<AUTH_TOKEN_1>' },
     'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075', 'gitaly_token' => '<AUTH_TOKEN_2>' },
   }
   ```

1. ファイルを保存して[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
1. Gitalyクライアント（例えばRailsアプリケーション）で`sudo gitlab-rake gitlab:gitaly:check`を実行して、Gitalyサーバーに接続できることを確認します。
1. ログを追跡してリクエストを確認します。

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

1. ファイルを保存し、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。
1. GitalyクライアントがGitalyサーバーに接続できることを確認するために`sudo -u git -H bundle exec rake gitlab:gitaly:check RAILS_ENV=production`を実行します。
1. ログを追跡してリクエストを確認します。

   ```shell
   tail -f /home/git/gitlab/log/gitaly.log
   ```

{{< /tab >}}

{{< /tabs >}}

Gitalyサーバー上のGitalyログをテールすると、リクエストが受信されていることがわかるはずです。Gitalyリクエストをトリガーする確実な方法の1つは、HTTPまたはHTTPSを介してGitLabからリポジトリをクローンすることです。

> [!warning]
> [サーバーフック](../server_hooks.md)が設定されている場合（各リポジトリごと、またはグローバルに）、これらをGitalyサーバーに移動する必要があります。複数のGitalyサーバーがある場合は、サーバーフックをすべてのGitalyサーバーにコピーしてください。

#### 混合設定 {#mixed-configuration}

GitLabは多くのGitalyサーバーの1つと同じサーバーに存在できますが、ローカル設定とリモート設定を混在させる設定はサポートしていません。次のセットアップは、次の理由により正しくありません:

- すべてのアドレスは、その他のGitalyサーバーから到達可能である必要があります。
- `storage1`には、一部のGitalyサーバーでは無効な`gitaly_address`用のUnixソケットが割り当てられています。

```ruby
gitlab_rails['repositories_storages'] = {
  'default' => { 'gitaly_address' => 'tcp://gitaly1.internal:8075' },
  'storage1' => { 'gitaly_address' => 'unix:/var/opt/gitlab/gitaly/gitaly.socket' },
  'storage2' => { 'gitaly_address' => 'tcp://gitaly2.internal:8075' },
}
```

ローカルとリモートのGitalyサーバーを組み合わせるには、ローカルGitalyサーバーに外部アドレスを使用します。例: 

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

`path`は、ローカルGitalyサーバー上のストレージシャードにのみ含めることができます。除外された場合、そのストレージシャードにはデフォルトのGitストレージディレクトリが使用されます。

### GitLabにはデフォルトリポジトリストレージが必要です {#gitlab-requires-a-default-repository-storage}

環境にGitalyサーバーを追加する際、元の`default` Gitalyサービスを置き換えたい場合があります。ただし、GitLabは`default`というストレージを必要とするため、GitLabアプリケーションサーバーを再設定して`default`ストレージを削除することはできません。この制限については、[詳細](https://gitlab.com/gitlab-org/gitlab/-/issues/36175)をご覧ください。

この制限を回避するには:

1. 新しいGitalyサービスで追加のストレージの場所を定義し、その追加ストレージを`default`に設定します。ストレージの場所には、動作するストレージを期待するデータベース移行の問題を回避するために、Gitalyサービスが実行され、利用可能である必要があります。
1. [**管理者**エリア](../repository_storage_paths.md#configure-where-new-repositories-are-stored)で、`default`のウェイトをゼロに設定して、リポジトリがそこに保存されないようにします。

### Gitalyが不要な場所で無効化する（オプション） {#disable-gitaly-where-not-required-optional}

Gitalyを[リモートサービス](#run-gitaly-on-its-own-server)として実行している場合、デフォルトでGitLabサーバー上で実行されるローカルGitalyサービスを無効にし、必要な場所でのみ実行することを検討してください。

GitLabインスタンスでGitalyを無効にすることは、GitalyがGitLabインスタンスとは別のマシンで実行されるカスタムクラスター設定でGitLabを実行している場合にのみ意味があります。クラスター内のすべてのマシンでGitalyを無効にすることは、有効な設定ではありません（一部のマシンはGitalyサーバーとして機能する必要があります）。

GitLabサーバーでGitalyを次の2つの方法のいずれかで無効にします:

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

1. ファイルを保存し、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}

## Gitalyリスナーインターフェースを変更する {#change-the-gitaly-listening-interface}

Gitalyがリッスンするインターフェースを変更できます。Gitalyと通信する必要がある外部サービスがある場合、リスナーインターフェースを変更する場合があります。例えば、[完全一致コードの検索](../../integration/zoekt/_index.md)が有効な場合にZoektを使用する完全一致コードの検索がありますが、実際のサービスが別のサーバーで実行されている場合です。

`gitaly_token`は、`gitaly_token`がGitalyサービスでの認証に使用されるため、シークレット文字列である必要があります。このシークレットは、ランダムな32文字の文字列を生成するために`openssl rand -base64 24`で生成できます。

例えば、Gitalyリスナーインターフェースを`0.0.0.0:8075`に変更するには:

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

コントロールグループに関する情報は、[Cgroups](cgroups.md)を参照してください。

## バックグラウンドリポジトリ最適化 {#background-repository-optimization}

Gitリポジトリのオブジェクトデータベースにデータが保存される方法は、時間の経過とともに非効率になり、Git操作が遅くなる可能性があります。Gitalyをスケジュールして、これらの項目をクリーンアップし、パフォーマンスを向上させるために、最大実行時間を持つ日次バックグラウンドタスクを実行できます。

> [!warning]
> バックグラウンドリポジトリ最適化は、実行中にホストにかなりの負荷をかける可能性があります。ピーク時間外にこれをスケジュールし、実行時間を短く（例えば、30〜60分）してください。

バックグラウンドリポジトリ最適化を次の2つの方法のいずれかで設定します:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

`/etc/gitlab/gitlab.rb`を編集して、以下を追加します。

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

`/home/git/gitaly/config.toml`を編集して、以下を追加します。

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

認証情報をローテーションすることは、本番環境では多くの場合、停止時間、障害、またはその両方を引き起こします。

ただし、Gitalyの認証情報はサービスを中断することなくローテーションできます。Gitaly認証トークンのローテーションには次の内容が含まれます:

- [認証モニタリングを確認](#verify-authentication-monitoring)します。
- [認証遷移モードを有効にする](#enable-auth-transitioning-mode)。
- [Gitaly認証トークンを更新](#update-gitaly-authentication-token)します。
- [認証失敗がないことを確認](#ensure-there-are-no-authentication-failures)します。
- [認証遷移モードを無効にする](#disable-auth-transitioning-mode)。
- [認証が強制されていることを確認](#verify-authentication-is-enforced)します。

この手順は、単一のサーバーでGitLabを実行している場合にも機能します。その場合、GitalyサーバーとGitalyクライアントは同じマシンを指します。

### 認証モニタリングを確認する {#verify-authentication-monitoring}

Gitaly認証トークンをローテーションする前に、Prometheusを使用してGitLabインストールの[認証動作をモニタリング](monitoring.md#queries)できることを確認してください。

その後、残りの手順を続行できます。

### 認証遷移モードを有効にする {#enable-auth-transitioning-mode}

GitalyサーバーでGitaly認証を一時的に無効にするには、次のように認証遷移モードに設定します:

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

この変更を行った後、あなたの[Prometheusクエリ](#verify-authentication-monitoring)は次のような結果を返すはずです:

```promql
{enforced="false",status="would be ok"}  4424.985419441742
```

`enforced="false"`であるため、新しいトークンの展開を開始しても安全です。

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

この変更が展開されている間に[Prometheusクエリ](#verify-authentication-monitoring)を実行すると、`enforced="false",status="denied"`カウンターにゼロ以外の値が表示されます。

### 認証失敗がないことを確認する {#ensure-there-are-no-authentication-failures}

新しいトークンが設定され、関連するすべてのサービスが再起動されると、一時的に[次の](#verify-authentication-monitoring)組み合わせが表示されます:

- `status="would be ok"`。
- `status="denied"`。

新しいトークンがすべてのGitalyクライアントとGitalyサーバーによって認識されると、ゼロ以外の唯一のレートは`enforced="false",status="would be ok"`になるはずです。

### 認証遷移モードを無効にする {#disable-auth-transitioning-mode}

Gitaly認証を再有効化するには、認証遷移モードを無効にします。Gitalyサーバー上の設定を次のように更新します:

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

> [!warning]
> このステップを完了しないと、Gitaly認証は利用できません。

### 認証が強制されていることを確認する {#verify-authentication-is-enforced}

[Prometheusクエリ](#verify-authentication-monitoring)を更新します。開始時と同様の結果が表示されるはずです。例: 

```promql
{enforced="true",status="ok"}  4424.985419441742
```

`enforced="true"`は、認証が強制されていることを意味します。

## Pack-objectsキャッシュ {#pack-objects-cache}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

[Gitaly](_index.md)（Gitリポジトリのストレージを提供するサービス）は、Gitフェッチ応答の短いローリングウィンドウをキャッシュするように設定できます。これにより、サーバーが多数のCIフェッチトラフィックを受信したときのサーバーの負荷を軽減できます。

Pack-objectsキャッシュは、PostUploadPackおよびSSHUploadPack Gitaly RPCsを使用することで間接的に実行されるGitの内部部分である`git pack-objects`をラップします。Gitalyは、ユーザーがHTTPを使用してGitフェッチを実行するときにPostUploadPackを、ユーザーがSSHを使用してGitフェッチを実行するときにSSHUploadPackを実行します。キャッシュが有効になっている場合、PostUploadPackまたはSSHUploadPackを使用するものはすべて、その恩恵を受けることができます。それは独立しており、次の影響を受けません:

- トランスポート（HTTPまたはSSH）。
- Gitプロトコルバージョン（v0またはv2）。
- フルクローン、インクリメンタルフェッチ、シャロークローン、または部分クローンなどのフェッチの種類。

このキャッシュの強みは、同時に行われる同一のフェッチを重複排除する機能です。これは次のとおりです:

- 多くの並行ジョブを持つCI/CDパイプラインを実行するGitLabインスタンスにメリットがあります。サーバーのCPU使用率が著しく低下するはずです。
- ユニークなフェッチにはまったくメリットがありません。例えば、リポジトリをローカルコンピューターにクローンしてスポットチェックを実行しても、あなたのフェッチはユニークである可能性が高いため、このキャッシュによるメリットは期待できません。

Pack-objectsキャッシュはローカルキャッシュです。これは次のとおりです:

- 有効になっているGitalyプロセスのメモリにメタデータを保存します。
- キャッシュしている実際のGitデータをローカルストレージ上のファイルに保存します。

ローカルファイルを使用すると、オペレーティングシステムがpack-objectsキャッシュファイルの一部を自動的にRAMに保持できるため、処理が高速になるというメリットがあります。

Pack-objectsキャッシュはディスク書き込みIOを大幅に増加させる可能性があるため、デフォルトで無効になっています。

### キャッシュを設定する {#configure-the-cache}

これらの設定設定は、pack-objectsキャッシュで利用できます。各設定については、以下で詳しく説明します。

| 設定   | デフォルト                                            | 説明                                                                                        |
|:----------|:---------------------------------------------------|:---------------------------------------------------------------------------------------------------|
| `enabled` | `false`                                            | キャッシュをオンにします。オフの場合、Gitalyは各リクエストに対して専用の`git pack-objects`プロセスを実行します。 |
| `dir`     | `<PATH TO FIRST STORAGE>/+gitaly/PackObjectsCache` | キャッシュファイルが保存されるローカルディレクトリ。                                                      |
| `max_age` | `5m`（5分）                                   | これより古いキャッシュエントリは削除され、ディスクから除去されます。                                   |
| `min_occurrences` | 1 | キャッシュエントリが作成される前に、キーが出現する必要がある最小回数。 |

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

#### `enabled`は`false`にデフォルトで設定されます {#enabled-defaults-to-false}

キャッシュは、場合によってはディスクに書き込まれるバイト数を[大幅に増加](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/4010#note_534564684)させる可能性があるため、デフォルトで無効になっています。GitLab.comでは、リポジトリストレージディスクがこの追加ワークロードを処理できることを確認しましたが、これがどこでも当てはまるわけではないと感じました。

#### キャッシュストレージディレクトリ`dir` {#cache-storage-directory-dir}

キャッシュは、ファイルを保存するディレクトリを必要とします。このディレクトリは次のとおりである必要があります:

- 十分な空き容量のあるファイルシステム内。キャッシュファイルシステムの空き容量がなくなると、すべてのフェッチが失敗し始めます。
- 十分なIO帯域幅を持つディスク上。キャッシュディスクのIO帯域幅がなくなると、すべてのフェッチ、そしておそらく全体のサーバーが遅くなります。

> [!warning]
> 指定されたディレクトリ内の既存のデータはすべて削除されます。既存のデータがあるディレクトリを使用しないように注意してください。

デフォルトでは、キャッシュストレージディレクトリは、設定ファイルで定義された最初のGitalyストレージのサブディレクトリに設定されます。

複数のGitalyプロセスは、キャッシュストレージに同じディレクトリを使用できます。各Gitalyプロセスは、作成するキャッシュファイル名の一部として一意のランダム文字列を使用します。これは、次の意味をもちます。

- それらは衝突しません。
- 別のプロセスのファイルを再利用しません。

デフォルトディレクトリはキャッシュファイルをリポジトリデータと同じファイルシステムに配置しますが、これは必須ではありません。キャッシュファイルは、インフラストラクチャにとってより適切であれば、別のファイルシステムに配置できます。

ディスクから必要とされるIO帯域幅の量は、次のものに依存します:

- Gitalyサーバー上のリポジトリのサイズと形状。
- ユーザーが生成するトラフィックの種類。

`gitaly_pack_objects_generated_bytes_total`メトリクスを、キャッシュヒット率が0％であると仮定した悲観的な推定値として使用できます。

必要なスペースの量は、次のものに依存します:

- ユーザーがキャッシュからプルする1秒あたりのバイト数。
- `max_age`キャッシュ削除ウィンドウのサイズ。

ユーザーが100 MB/秒でプルし、5分のウィンドウを使用する場合、平均してキャッシュディレクトリに`5*60*100 MB = 30 GB`のデータがあります。この平均は期待される平均であり、保証ではありません。ピークサイズはこの平均を超える場合があります。

#### キャッシュ削除ウィンドウ`max_age` {#cache-eviction-window-max_age}

`max_age`設定設定により、キャッシュヒットの可能性と、キャッシュファイルによって使用される平均ストレージ容量を制御できます。`max_age`より古いエントリーはディスクから削除されます。

削除は進行中のリクエストを妨げません。Unixファイルシステムでは、削除されたファイルを読み取っているすべてのプロセスがファイルを閉じるまで、実際にファイルが削除されないため、`max_age`が低速接続でのフェッチにかかる時間よりも短くても問題ありません。

#### 最小キー発生回数`min_occurrences` {#minimum-key-occurrences-min_occurrences}

`min_occurrences`設定は、新しいキャッシュエントリを作成する前に、同一のリクエストがどれくらいの頻度で発生する必要があるかを制御します。デフォルト値は`1`であり、ユニークなリクエストはキャッシュに書き込まれないことを意味します。

次の場合:

- この数を増やすと、キャッシュヒット率が低下し、キャッシュが使用するディスク容量が少なくなります。
- この数を減らすと、キャッシュヒット率が上がり、キャッシュが使用するディスク容量が多くなります。

`min_occurrences`を`1`に設定する必要があります。GitLab.comでは、0から1にすることで、キャッシュヒット率にほとんど影響を与えることなく、キャッシュディスク容量を50%削減できました。

### キャッシュを監視する {#observe-the-cache}

{{< history >}}

- Pack-objectsキャッシュのログは、GitLab 16.0で[変更](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/5719)されました。

{{< /history >}}

Prometheusメトリクスとログフィールドを使用してキャッシュを監視できます。

#### Prometheusメトリクス {#prometheus-metrics}

Gitalyは、pack-objectsキャッシュをモニタリングするための次のPrometheusメトリクスをエクスポートします:

| メトリック | 種類 | 説明 |
|:-------|:-----|:------------|
| `gitaly_pack_objects_served_bytes_total` | カウンター | `git-pack-objects`データからクライアントに提供されたバイトの合計数。 |
| `gitaly_pack_objects_cache_lookups_total` | カウンター | キャッシュルックアップの数。`result`ラベルは`hit`または`miss`を示します。 |
| `gitaly_pack_objects_generated_bytes_total` | カウンター | `git-pack-objects`を実行することによって生成されたバイトの合計数。 |

**Example Prometheus queries:**

キャッシュヒット率:

```promql
sum(rate(gitaly_pack_objects_cache_lookups_total{result="hit"}[5m])) /
sum(rate(gitaly_pack_objects_cache_lookups_total[5m]))
```

キャッシュから提供された1秒あたりのバイト数:

```promql
rate(gitaly_pack_objects_served_bytes_total[5m])
```

生成されたバイト（キャッシュミス）1秒あたり:

```promql
rate(gitaly_pack_objects_generated_bytes_total[5m])
```

キャッシュ効率性（提供されたバイト数と生成されたバイト数）:

```promql
rate(gitaly_pack_objects_served_bytes_total[5m]) /
rate(gitaly_pack_objects_generated_bytes_total[5m])
```

#### ログフィールド {#log-fields}

これらのログはgRPCログの一部であり、呼び出しが実行されたときに検出できます。

| フィールド | 説明 |
|:---|:---|
| `pack_objects_cache.hit` | 現在のpack-objectsキャッシュがヒットしたかどうかを示します（`true`または`false`） |
| `pack_objects_cache.key` | pack-objectsキャッシュに使用されるキャッシュキー |
| `pack_objects_cache.generated_bytes` | 書き込まれている新しいキャッシュのサイズ（バイト単位） |
| `pack_objects_cache.served_bytes` | 提供されているキャッシュのサイズ（バイト単位） |
| `pack_objects.compression_statistics` | pack-objects生成に関する統計。 |
| `pack_objects.enumerate_objects_ms` | クライアントによって送信されたオブジェクトの列挙に費やされた合計時間（ミリ秒単位） |
| `pack_objects.prepare_pack_ms` | クライアントにパックファイルを送信する前にパックファイルの準備に費やされた合計時間（ミリ秒単位） |
| `pack_objects.write_pack_file_ms` | クライアントにパックファイルを送信し返すのに費やされた合計時間（ミリ秒単位）。クライアントのインターネット接続に大きく依存します。 |
| `pack_objects.written_object_count` | Gitalyがクライアントに送り返すオブジェクトの総数。 |

次の場合:

- キャッシュミスの場合、Gitalyは`pack_objects_cache.generated_bytes`と`pack_objects_cache.served_bytes`の両方のメッセージをログに記録します。Gitalyは、pack-object生成に関するより詳細な統計もログに記録します。
- キャッシュヒットの場合、Gitalyは`pack_objects_cache.served_bytes`メッセージのみをログに記録します。

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

多くのGitaly RPCsは、リポジトリからGitオブジェクトをルックアップする必要があります。ほとんどの場合、これには`git cat-file --batch`プロセスを使用します。パフォーマンスを向上させるために、Gitalyはこれらの`git cat-file`プロセスをRPCs呼び出し間で再利用できます。以前に使用されたプロセスは、[`git cat-file`キャッシュ](https://about.gitlab.com/blog/git-performance-on-nfs/#enter-cat-file-cache)に保持されます。これが使用するシステムリソースの量を制御するために、キャッシュに入れることができるcat-ファイルプロセスの最大数があります。

デフォルトの制限は100 `cat-file`であり、これは`git cat-file --batch`と`git cat-file --batch-check`プロセスのペアを構成します。「開いているファイルが多すぎます」というエラーや、新しいプロセスを作成できないというエラーが表示される場合は、この制限を下げたいと考えるかもしれません。

理想的には、この数は標準的なトラフィックを処理するのに十分な大きさであるべきです。制限を上げた場合、前後でキャッシュヒット率を測定する必要があります。ヒット率が改善しない場合、より高い制限は意味のある違いを生み出していない可能性が高いです。ヒット率を確認するためのPrometheusクエリの例を次に示します:

```plaintext
sum(rate(gitaly_catfile_cache_total{type="hit"}[5m])) / sum(rate(gitaly_catfile_cache_total{type=~"(hit)|(miss)"}[5m]))
```

Gitaly設定ファイルで`cat-file`キャッシュを設定します。

## GitLab UIコミットの署名を設定する {#configure-commit-signing-for-gitlab-ui-commits}

{{< history >}}

- 署名されたGitLab UIコミットに対する**検証済み**バッジの表示は、GitLab 16.3で`gitaly_gpg_signing`という名前の[フラグ](../feature_flags/_index.md)と共に[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124218)されました。デフォルトでは無効になっています。
- GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6163)された`rotated_signing_keys`オプションで指定された複数のキーを使用して署名を検証します。
- GitLab 17.0でGitLab Self-ManagedおよびGitLab Dedicatedで[デフォルト](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6876)で有効化されました。

{{< /history >}}

> [!flag]
> GitLab Self-Managedでは、デフォルトでこの機能が利用可能です。この機能を非表示にするために、管理者は`gitaly_gpg_signing`という名前の[機能フラグを無効](../feature_flags/_index.md)にできます。GitLab.comでは、この機能は利用できません。GitLab Dedicatedでは、この機能は利用可能です。

デフォルトでは、GitalyはGitLab UIを使用して作成されたコミットに署名しません。例えば、次のものを使用して作成されたコミット:

- Webエディタ。
- Web IDE。
- マージリクエスト。

Gitalyでコミット署名を有効にすると:

- GitLabはUIを介して行われたすべてのコミットに署名します。
- 署名はコミッターのIDを検証し、作成者のIDは検証しません。
- `committer_email`および`committer_name`を設定することで、コミットがあなたのインスタンスによってコミットされたことを反映するようにGitalyを設定できます。例えば、GitLab.comでは、これらの設定オプションは`noreply@gitlab.com`と`GitLab`に設定されています。

`rotated_signing_keys`は、検証のみに使用するキーのリストです。Gitalyは、設定された`signing_key`を使用してWebコミットを検証しようとし、成功するまでローテーションされたキーを1つずつ使用します。`rotated_signing_keys`オプションは次のいずれかの場合に設定します:

- 署名キーがローテーションされた場合。
- 他のインスタンスからプロジェクトを移行するために複数のキーを指定し、それらのWebコミットを**検証済み**として表示したい場合。

GitLab UIで作成されたコミットにGitalyが署名するように次の2つの方法のいずれかで設定します:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. [GPGキーを作成](../../user/project/repository/signed_commits/gpg.md#create-a-gpg-key)してエクスポートするか、[SSHキーを作成](../../user/ssh.md#generate-an-ssh-key-pair)します。最適なパフォーマンスを得るには、EdDSAキーを使用してください。

   GPGキーをエクスポート:

   ```shell
   gpg --export-secret-keys <ID> > signing_key.gpg
   ```

   またはSSHキーを（パスフレーズなしで）作成します:

   ```shell
   ssh-keygen -t ed25519 -f signing_key.ssh
   ```

1. Gitalyノードで、キーを`/etc/gitlab/gitaly/`にコピーし、`git`ユーザーがそのファイルを読み取り権限を持っていることを確認します。
1. `/etc/gitlab/gitlab.rb`を編集し、`gitaly['git']['signing_key']`を設定します:

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

1. [GPGキーを作成](../../user/project/repository/signed_commits/gpg.md#create-a-gpg-key)してエクスポートするか、[SSHキーを作成](../../user/ssh.md#generate-an-ssh-key-pair)します。最適なパフォーマンスを得るには、EdDSAキーを使用してください。

   GPGキーをエクスポート:

   ```shell
   gpg --export-secret-keys <ID> > signing_key.gpg
   ```

   またはSSHキーを（パスフレーズなしで）作成します:

   ```shell
   ssh-keygen -t ed25519 -f signing_key.ssh
   ```

1. Gitalyノードで、キーを`/etc/gitlab`にコピーします。
1. `/home/git/gitaly/config.toml`を編集し、`signing_key`を設定します:

   ```toml
   [git]
   committer_name = "Your Instance"
   committer_email = "noreply@yourinstance.com"
   signing_key = "/etc/gitlab/gitaly/signing_key.gpg"
   rotated_signing_keys = ["/etc/gitlab/gitaly/previous_signing_key.gpg"]
   ```

1. ファイルを保存し、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}

## カスタムGit設定を設定する {#configure-custom-git-configuration}

GitalyはシステムまたはユーザーレベルのGit設定ファイルを読み取りません。GitalyサーバーでカスタムGit設定を提供するには、`git.config`設定を使用します。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

`/etc/gitlab/gitlab.rb`を編集します:

```ruby
gitaly['configuration'] = {
  # ...
  git: {
    # ...
    config: [
      { key: "fsck.badDate", value: "ignore" },
      ...
    ],
  },
}
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

`/home/git/gitaly/config.toml`を編集します:

```toml
[[git.config]]
key = "fsck.badDate"
value = "ignore"
```

{{< /tab >}}

{{< /tabs >}}

### Gitalyによって設定されるGit設定 {#git-configuration-set-by-gitaly}

Gitalyは次のGit設定値を設定します。これらは`git.config`設定を使用してオーバーライドすることはできません:

- `advice.fetchShowForcedUpdates`
- `attr.tree`
- `bundle.heuristic`
- `bundle.mode`
- `bundle.version`
- `core.alternateRefsCommand`
- `core.autocrlf`
- `core.bigFileThreshold`
- `core.filesRefLockTimeout`
- `core.fsync`
- `core.fsyncMethod`
- `core.hooksPath`
- `core.packedRefsTimeout`
- `core.useReplaceRefs`
- `diff.noprefix`
- `fetch.fsck.badTimezone`
- `fetch.fsck.missingSpaceBeforeDate`
- `fetch.fsck.zeroPaddedFilemode`
- `fetch.fsckObjects`
- `fetch.negotiationAlgorithm`
- `fetch.recurseSubmodules`
- `fetch.writeCommitGraph`
- `fsck.badTimezone`
- `fsck.missingSpaceBeforeDate`
- `fsck.zeroPaddedFilemode`
- `gc.auto`
- `grep.threads`
- `http.<url>.extraHeader`
- `http.curloptResolve`
- `http.extraHeader`
- `http.followRedirects`
- `init.defaultBranch`
- `init.templateDir`
- `maintenance.auto`
- `pack.allowPackReuse`
- `pack.island`
- `pack.islandCore`
- `pack.threads`
- `pack.windowMemory`
- `pack.writeBitmapLookupTable`
- `pack.writeReverseIndex`
- `receive.advertisePushOptions`
- `receive.autogc`
- `receive.fsck.badTimezone`
- `receive.fsck.missingSpaceBeforeDate`
- `receive.fsck.zeroPaddedFilemode`
- `receive.hideRefs`
- `receive.procReceiveRefs`
- `remote.inmemory.fetch`
- `remote.inmemory.url`
- `remote.origin.fetch`
- `remote.origin.url`
- `repack.updateServerInfo`
- `repack.writeBitmaps`
- `transfer.bundleURI`
- `transfer.fsckObjects`
- `uploadpack.advertiseBundleURIs`
- `uploadpack.allowAnySHA1InWant`
- `uploadpack.allowFilter`
- `uploadpack.hideRefs`

## 外部コマンドを使用して設定を生成する {#generate-configuration-using-an-external-command}

外部コマンドを使用してGitalyの設定の一部を生成できます。これは次の目的で実行する場合があります:

- 各ノードに完全な設定を配布することなく、ノードを設定するため。
- ノードの設定の自動検出を使用して設定するため。例えば、DNSエントリを使用します。
- ノードの起動時にシークレットを設定し、プレーンテキストで表示する必要がないようにするため。

外部コマンドを使用して設定を生成するには、Gitalyノードの目的の設定をJSON形式で標準出力にダンプするスクリプトを提供する必要があります。

例えば、次のコマンドは、AWSシークレットを使用してGitLab内部APIに接続するために使用されるHTTPパスワードを設定します:

```ruby
#!/usr/bin/env ruby
require 'json'
JSON.generate({"gitlab": {"http_settings": {"password": `aws get-secret-value --secret-id ...`}}})
```

その後、スクリプトパスを次の2つの方法のいずれかでGitalyに認識させる必要があります:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

`/etc/gitlab/gitlab.rb`を編集し、`config_command`を設定します:

```ruby
gitaly['configuration'] = {
    config_command: '/path/to/config_command',
}
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

`/home/git/gitaly/config.toml`を編集し、`config_command`を設定します:

```toml
config_command = "/path/to/config_command"
```

{{< /tab >}}

{{< /tabs >}}

設定後、Gitalyは起動時にコマンドを実行し、その標準出力をJSONとして解析します。結果の設定は、その他のGitaly設定にマージされます。

Gitalyは次のいずれかの場合に起動に失敗します:

- 設定コマンドが失敗した場合。
- コマンドによって生成された出力が有効なJSONとして解析できない場合。

## サーバーサイドバックアップの設定 {#configure-server-side-backups}

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitaly/-/issues/4941)されました。
- 最新のバックアップではなく、指定されたバックアップをリストアするためのサーバーサイドサポートがGitLab 16.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132188)されました。
- GitLab 16.6で増分バックアップを作成するためのサーバー側のサポートが[導入](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6475)されました。
- GitLab 17.0で、Helmチャートインストールにサーバーサイドサポートが追加されました。

{{< /history >}}

リポジトリバックアップは、各リポジトリをホストするGitalyノードがバックアップの作成とオブジェクトストレージへのストリーミングを担当するように設定できます。これにより、バックアップの作成と復元に必要なネットワークリソースを削減できます。

各Gitalyノードは、バックアップのためにオブジェクトストレージに接続するように設定する必要があります。

サーバーサイドバックアップを設定した後、[サーバーサイドリポジトリバックアップを作成](../backup_restore/backup_gitlab.md#create-server-side-repository-backups)できます。

### Azure Blobストレージの設定 {#configure-azure-blob-storage}

Azure Blobストレージをバックアップ用に設定する方法は、お使いのインストールの種類によって異なります。セルフコンパイルインストールの場合は、`AZURE_STORAGE_ACCOUNT`と`AZURE_STORAGE_KEY`環境変数をGitLabの外部で設定する必要があります。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

`/etc/gitlab/gitlab.rb`を編集し、`go_cloud_url`を設定します:

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

Helmベースのデプロイについては、[Gitalyチャート用のサーバーサイドバックアップドキュメント](https://docs.gitlab.com/charts/charts/gitlab/gitaly/#server-side-backups)を参照してください。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

`/home/git/gitaly/config.toml`を編集し、`go_cloud_url`を設定します:

```toml
[backup]
go_cloud_url = "azblob://<bucket>"
```

{{< /tab >}}

{{< /tabs >}}

### Google Cloud Storageの設定 {#configure-google-cloud-storage}

Google Cloud Storage（GCP）は、アプリケーションデフォルト認証情報を使用して認証します。各Gitalyサーバーでアプリケーションデフォルト認証情報を次のいずれかの方法で設定します:

- [`gcloud auth application-default login`](https://cloud.google.com/sdk/gcloud/reference/auth/application-default/login)コマンド。
- `GOOGLE_APPLICATION_CREDENTIALS`環境変数。セルフコンパイルインストールの場合は、環境変数をGitLabの外部で設定します。

詳細については、[アプリケーションデフォルト認証情報](https://cloud.google.com/docs/authentication/provide-credentials-adc)を参照してください。

宛先バケットは`go_cloud_url`オプションを使用して設定されます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

`/etc/gitlab/gitlab.rb`を編集し、`go_cloud_url`を設定します:

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

Helmベースのデプロイについては、[Gitalyチャート用のサーバーサイドバックアップドキュメント](https://docs.gitlab.com/charts/charts/gitlab/gitaly/#server-side-backups)を参照してください。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

`/home/git/gitaly/config.toml`を編集し、`go_cloud_url`を設定します:

```toml
[backup]
go_cloud_url = "gs://<bucket>"
```

{{< /tab >}}

{{< /tabs >}}

### S3ストレージの設定 {#configure-s3-storage}

S3ストレージ認証を設定するには:

- AWS CLIで認証する場合、デフォルトのAWSセッションを使用できます。
- そうでない場合は、`AWS_ACCESS_KEY_ID`および`AWS_SECRET_ACCESS_KEY`環境変数を使用できます。セルフコンパイルインストールの場合は、環境変数をGitLabの外部で設定します。

詳細については、[AWSセッションドキュメント](https://docs.aws.amazon.com/sdk-for-go/api/aws/session/)を参照してください。

宛先バケットとリージョンは、`go_cloud_url`オプションを使用して設定されます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

`/etc/gitlab/gitlab.rb`を編集し、`go_cloud_url`を設定します:

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

Helmベースのデプロイについては、[Gitalyチャート用のサーバーサイドバックアップドキュメント](https://docs.gitlab.com/charts/charts/gitlab/gitaly/#server-side-backups)を参照してください。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

`/home/git/gitaly/config.toml`を編集し、`go_cloud_url`を設定します:

```toml
[backup]
go_cloud_url = "s3://<bucket>?region=us-west-1"
```

{{< /tab >}}

{{< /tabs >}}

#### S3互換サーバーの設定 {#configure-s3-compatible-servers}

S3互換サーバーは、`endpoint`パラメータの追加を除いてS3と同様に設定されます。

次のパラメータがサポートされています。

- `region`: AWSリージョン。
- `endpoint`: エンドポイントURL。
- `disabledSSL`: `true`の値はSSLを無効にします。
- `s3ForcePathStyle`: `true`の値はパススタイルのアドレス指定を強制します。

{{< tabs >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

Helmベースのデプロイについては、[Gitalyチャート用のサーバーサイドバックアップドキュメント](https://docs.gitlab.com/charts/charts/gitlab/gitaly/#server-side-backups)を参照してください。

{{< /tab >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

`/etc/gitlab/gitlab.rb`を編集し、`go_cloud_url`を設定します:

```ruby
gitaly['env'] = {
    'AWS_ACCESS_KEY_ID' => '<your_access_key_id>',
    'AWS_SECRET_ACCESS_KEY' => '<your_secret_access_key>'
}
gitaly['configuration'] = {
    backup: {
        go_cloud_url: 's3://<bucket>?region=us-east-1&endpoint=s3.example.com:9000&disableSSL=true&s3ForcePathStyle=true'
    }
}
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

`/home/git/gitaly/config.toml`を編集し、`go_cloud_url`を設定します:

```toml
[backup]
go_cloud_url = "s3://<bucket>?region=us-east-1&endpoint=s3.example.com:9000&disableSSL=true&s3ForcePathStyle=true"
```

{{< /tab >}}

{{< /tabs >}}
