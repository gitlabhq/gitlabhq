---
stage: Data Access
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Gitaly TLSのサポート
---

GitalyはTLS暗号化をサポートしています。セキュアな接続をリッスンするGitalyインスタンスと通信するには、GitLabの設定で、対応するストレージエントリの`gitaly_address`で`tls://` URLスキームを使用する必要があります。

Gitalyは、GitLabへのTLS接続において、クライアント証明書と同じサーバー証明書を提供します。これは、クライアント証明書を検証してGitLabへのアクセスを許可するリバースプロキシ（NGINXなど）と組み合わせることで、相互TLS認証戦略の一部として使用できます。

これは自動的には提供されないため、独自の証明書を用意する必要があります。各Gitalyサーバーに対応する証明書は、そのGitalyサーバーにインストールする必要があります。

さらに、証明書（またはその認証局）は、以下すべてにインストールする必要があります:

- Gitalyサーバー。
- それと通信するGitalyクライアント。

ロードバランサーを使用する場合は、ALPN TLS拡張を使用してHTTP/2をネゴシエートできる必要があります。

## 証明書の要件 {#certificate-requirements}

- 証明書は、Gitalyサーバーへのアクセスに使用するアドレスを指定する必要があります。ホスト名またはIPアドレスをサブジェクトの別名（SAN）として証明書に追加する必要があります。
- Gitalyサーバーは、暗号化されていないリスニングアドレス`listen_addr`と暗号化されたリスニングアドレス`tls_listen_addr`の両方で同時に設定できます。これにより、必要に応じて、暗号化されていないトラフィックから暗号化されたトラフィックへの段階的な移行を行うことができます。
- 証明書の共通名フィールドは無視されます。

## TLSを使用してGitalyを設定する {#configure-gitaly-with-tls}

{{< history >}}

- 最小TLSバージョン設定オプションがGitLab 17.11で[導入されました](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/7755)。

{{< /history >}}

TLSサポートを設定する前に、[Gitalyを設定する](configure_gitaly.md)。

TLSサポートを設定するプロセスは、インストールの種類によって異なります。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. Gitalyサーバーの証明書を作成します。
1. Gitalyクライアントで、証明書（またはその認証局）を`/etc/gitlab/trusted-certs`にコピーします:

   ```shell
   sudo cp cert.pem /etc/gitlab/trusted-certs/
   ```

1. Gitalyクライアントで、`/etc/gitlab/gitlab.rb`の`gitlab_rails['repositories_storages']`を次のように編集します:

   ```ruby
   gitlab_rails['repositories_storages'] = {
     'default' => { 'gitaly_address' => 'tls://gitaly1.internal:9999' },
     'storage1' => { 'gitaly_address' => 'tls://gitaly1.internal:9999' },
     'storage2' => { 'gitaly_address' => 'tls://gitaly2.internal:9999' },
   }
   ```

1. ファイルを保存して[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
1. Gitalyサーバーで、`/etc/gitlab/ssl`ディレクトリを作成し、キーと証明書をそこにコピーします:

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp key.pem cert.pem /etc/gitlab/ssl/
   sudo chmod 644 /etc/gitlab/ssl/cert.pem
   sudo chmod 600 /etc/gitlab/ssl/key.pem
   # For Linux package installations, 'git' is the default username. Modify the following command if it was changed from the default
   sudo chown -R git /etc/gitlab/ssl
   ```

1. すべてのGitalyサーバーとクライアントで、すべてのGitalyサーバー証明書（またはその認証局）を`/etc/gitlab/trusted-certs`にコピーして、Gitalyサーバーとクライアントが、自身または他のGitalyサーバーに呼び出すときに証明書を信頼するようにします:

   ```shell
   sudo cp cert1.pem cert2.pem /etc/gitlab/trusted-certs/
   ```

1. `/etc/gitlab/gitlab.rb`を編集して、以下を追加します:

   <!-- Updates to following example must also be made at https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-omnibus-gitlab -->

   ```ruby
   gitaly['configuration'] = {
      # ...
      tls_listen_addr: '0.0.0.0:9999',
      tls: {
        certificate_path: '/etc/gitlab/ssl/cert.pem',
        key_path: '/etc/gitlab/ssl/key.pem',
        ## Optionally configure the minimum TLS version Gitaly offers to clients.
        ##
        ## Default: "TLS 1.2"
        ## Options: ["TLS 1.2", "TLS 1.3"].
        #
        # min_version: "TLS 1.2"
      },
   }
   ```

1. ファイルを保存して[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
1. Gitalyクライアント（たとえば、Railsアプリケーション）で`sudo gitlab-rake gitlab:gitaly:check`を実行して、Gitalyサーバーに接続できることを確認します。
1. [Gitaly接続のタイプを監視する](#observe-type-of-gitaly-connections)ことで、GitalyのトラフィックがTLS経由で読み込まれていることを確認します。
1. オプション。セキュリティを強化するには、次の手順を実行します:
   1. `/etc/gitlab/gitlab.rb`の`gitaly['configuration'][:listen_addr]`をコメントアウトするか削除して、TLS以外の接続を無効にします。
   1. ファイルを保存します。
   1. [GitLabを再設定する](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. Gitalyサーバーの証明書を作成します。
1. Gitalyクライアントで、証明書をシステムの信頼できる証明書にコピーします:

   ```shell
   sudo cp cert.pem /usr/local/share/ca-certificates/gitaly.crt
   sudo update-ca-certificates
   ```

1. Gitalyクライアントで、`/home/git/gitlab/config/gitlab.yml`の`storages`を編集して、TLSアドレスを使用するように`gitaly_address`を変更します。例: 

   ```yaml
   gitlab:
     repositories:
       storages:
         default:
           gitaly_address: tls://gitaly1.internal:9999
           gitaly_token: AUTH_TOKEN_1
         storage1:
           gitaly_address: tls://gitaly1.internal:9999
           gitaly_token: AUTH_TOKEN_1
         storage2:
           gitaly_address: tls://gitaly2.internal:9999
           gitaly_token: AUTH_TOKEN_2
   ```

1. ファイルを保存して、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。
1. Gitalyサーバーで、`/etc/default/gitlab`を作成または編集し、以下を追加します:

   ```shell
   export SSL_CERT_DIR=/etc/gitlab/ssl
   ```

1. Gitalyサーバーで、`/etc/gitlab/ssl`ディレクトリを作成し、キーと証明書をそこにコピーします:

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp key.pem cert.pem /etc/gitlab/ssl/
   sudo chmod 644 /etc/gitlab/ssl/cert.pem
   sudo chmod 600 /etc/gitlab/ssl/key.pem
   # Set ownership to the same user that runs Gitaly
   sudo chown -R git /etc/gitlab/ssl
   ```

1. すべてのGitalyサーバー証明書（またはその認証局）をシステムの信頼できる証明書フォルダーにコピーして、Gitalyサーバーが自身または他のGitalyサーバーに呼び出すときに証明書を信頼するようにします。

   ```shell
   sudo cp cert.pem /usr/local/share/ca-certificates/gitaly.crt
   sudo update-ca-certificates
   ```

1. `/home/git/gitaly/config.toml`を編集して、以下を追加します:

   ```toml
   tls_listen_addr = '0.0.0.0:9999'

   [tls]
   certificate_path = '/etc/gitlab/ssl/cert.pem'
   key_path = '/etc/gitlab/ssl/key.pem'
   ```

1. ファイルを保存して、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。
1. [Gitaly接続のタイプを監視する](#observe-type-of-gitaly-connections)ことで、GitalyのトラフィックがTLS経由で読み込まれていることを確認します。
1. オプション。セキュリティを強化するには、次の手順を実行します:
   1. `/home/git/gitaly/config.toml`の`listen_addr`をコメントアウトするか削除して、TLS以外の接続を無効にします。
   1. ファイルを保存します。
   1. [GitLabを再起動](../restart_gitlab.md#self-compiled-installations)。

{{< /tab >}}

{{< /tabs >}}

### 証明書を更新する {#update-the-certificates}

初期設定後にGitalyを更新するには:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

`/etc/gitlab/ssl`ディレクトリにあるSSL証明書の内容が更新されていても、`/etc/gitlab/gitlab.rb`に設定の変更が加えられていない場合、GitLabを再設定してもGitalyには影響しません。代わりに、Gitalyプロセスで証明書が読み込まれるように、Gitalyを手動で再起動する必要があります:

```shell
sudo gitlab-ctl restart gitaly
```

`/etc/gitlab/gitlab.rb`ファイルを変更せずに、`/etc/gitlab/trusted-certs`の証明書を変更または更新する場合は、以下を実行する必要があります:

1. 信頼できる証明書のシンボリックリンクが更新されるように、[GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。
1. Gitalyプロセスで証明書が読み込まれるように、Gitalyを手動で再起動します:

   ```shell
   sudo gitlab-ctl restart gitaly
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

`/etc/gitlab/ssl`ディレクトリにあるSSL証明書の内容が更新された場合は、Gitalyプロセスで証明書が読み込まれるように、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)する必要があります。

`/usr/local/share/ca-certificates`の証明書を変更または更新する場合は、以下を実行する必要があります:

1. `sudo update-ca-certificates`を実行して、システムの信頼できるストアを更新します。
1. Gitalyプロセスで証明書が読み込まれるように、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}

## Gitaly接続のタイプを読み込む {#observe-type-of-gitaly-connections}

Gitaly読み込む方法については、[関連ドキュメント](monitoring.md#queries)を参照してください。
