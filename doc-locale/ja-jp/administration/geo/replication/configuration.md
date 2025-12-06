---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: シークレット、SSHキーをレプリケートし、データ同期を開始するために新しいサイトをプライマリに追加して、セカンダリサイトのGeoの設定を完了させます。
title: 新しいセカンダリサイトの設定
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< alert type="note" >}}

これは、**セカンダリ** Geoサイトをセットアップする際の最終ステップです。設定プロセスのステージは、ドキュメントに記載されている順序で完了する必要があります。そうでない場合は、続行する前に[complete all prior stages](../setup/_index.md#using-linux-package-installations)。

{{< /alert >}}

**セカンダリ**サイトを設定する基本的な手順は次のとおりです:

1. **プライマリ**サイトと**セカンダリ**サイト間で必要な設定をレプリケートします。
1. 各**セカンダリ**サイトでトラッキングデータベースを設定します。
1. 各**セカンダリ**サイトでGitLabを起動します。

このドキュメントでは、最初の項目に焦点を当てます。テスト/本番環境で実行する前に、すべての手順を読んで理解しておくことをお勧めします。

**both primary and secondary sites**の前提条件:

- [Set up the database replication](../setup/database.md)
- [承認されたSSHキーの高速検索](../../operations/fast_ssh_key_lookup.md)

{{< alert type="note" >}}

**セカンダリ**サイトでは、カスタム認証を設定**しないでください**。これは**プライマリ**サイトによって処理されます。**管理者エリア**へのアクセスを必要とする変更は、**プライマリ**サイトで行う必要があります。これは、**セカンダリ**サイトが読み取り専用レプリカであるためです。

{{< /alert >}}

## ステップ1: 秘密のGitLabの値を手動でレプリケートします {#step-1-manually-replicate-secret-gitlab-values}

GitLabは、`/etc/gitlab/gitlab-secrets.json`ファイルに多数の秘密値を格納します。これは、サイトのすべてのノードで同じである必要があります。サイト間でこれらを自動的にレプリケートする手段がない限り（[イシュー3789](https://gitlab.com/gitlab-org/gitlab/-/issues/3789)を参照）、これらは**セカンダリサイトのすべてのノード**に手動でレプリケートする必要があります。

1. **プライマリサイトのRailsノード**にSSH接続し、次のコマンドを実行します:

   ```shell
   sudo cat /etc/gitlab/gitlab-secrets.json
   ```

   これにより、レプリケートする必要があるシークレットがJSON形式で表示されます。

1. **into each node on your secondary Geo site**にSSH接続し、`root`ユーザーとしてログインします:

   ```shell
   sudo -i
   ```

1. 既存のシークレットのバックアップを作成します:

   ```shell
   mv /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.`date +%F`
   ```

1. `/etc/gitlab/gitlab-secrets.json`を**プライマリサイトのRailsノード**サイトから**セカンダリサイトの各ノード**にコピーするか、ノード間でファイルの内容をコピーアンドペーストします:

   ```shell
   sudo editor /etc/gitlab/gitlab-secrets.json

   # paste the output of the `cat` command you ran on the primary
   # save and exit
   ```

1. ファイル権限が正しいことを確認してください:

   ```shell
   chown root:root /etc/gitlab/gitlab-secrets.json
   chmod 0600 /etc/gitlab/gitlab-secrets.json
   ```

1. 変更を有効にするには、**セカンダリサイトの各Rails、Sidekiq、Gitalyノード**を再設定します:

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart
   ```

## ステップ2: **プライマリ**サイトのSSHホストキーを手動でレプリケートします {#step-2-manually-replicate-the-primary-sites-ssh-host-keys}

GitLabはシステムにインストールされたSSHデーモンと統合し、すべてのアクセス要求が処理されるユーザー（通常は`git`という名前）を指定します。

[ディザスターリカバリー](../disaster_recovery/_index.md)の状況では、GitLabシステム管理者が**セカンダリ**サイトを**プライマリ**サイトにプロモートします。**プライマリ**ドメインのDNSレコードも、新しい**プライマリ**サイト（以前は**セカンダリ**サイト）を指すように更新する必要があります。これにより、GitリモートおよびAPI URLを更新する必要がなくなります。

これにより、新たにプロモートされた**プライマリ**サイトへのすべてのSSHリクエストは、SSHホストキーの不一致により失敗します。これを防ぐために、プライマリのSSHホストキーを手動で**セカンダリ**サイトにレプリケートする必要があります。

SSHホストキーのパスは、使用するソフトウェアによって異なります:

- OpenSSHを使用している場合、パスは`/etc/ssh`です。
- [`gitlab-sshd`](../../operations/gitlab_sshd.md)を使用している場合、パスは`/var/opt/gitlab/gitlab-sshd`です。

次の手順では、使用している`<ssh_host_key_path>`に置き換えます:

1. **セカンダリサイトの各Railsノード**にSSH接続し、`root`ユーザーとしてサインインします:

   ```shell
   sudo -i
   ```

1. 既存のSSHホストキーのバックアップを作成します:

   ```shell
   find <ssh_host_key_path> -iname 'ssh_host_*' -exec cp {} {}.backup.`date +%F` \;
   ```

1. **プライマリ**サイトからSSHホストキーをコピーします:

   SSHトラフィックを処理する**nodes on your primary**（primary）サイトのノード（通常は、メインのGitLab Railsアプリケーションノード）の1つに、**root**ユーザーを使用してアクセスできる場合:

   ```shell
   # Run this from the secondary site, change `<primary_site_fqdn>` for the IP or FQDN of the server
   scp root@<primary_node_fqdn>:<ssh_host_key_path>/ssh_host_*_key* <ssh_host_key_path>
   ```

   `sudo`権限を持つユーザーを介してのみアクセスできる場合:

   ```shell
   # Run this from the node on your primary site:
   sudo tar --transform 's/.*\///g' -zcvf ~/geo-host-key.tar.gz <ssh_host_key_path>/ssh_host_*_key*

   # Run this on each node on your secondary site:
   scp <user_with_sudo>@<primary_site_fqdn>:geo-host-key.tar.gz .
   tar zxvf ~/geo-host-key.tar.gz -C <ssh_host_key_path>
   ```

1. **セカンダリサイトの各Railsノード**で、ファイルの権限が正しいことを確認します:

   ```shell
   chown root:root <ssh_host_key_path>/ssh_host_*_key*
   chmod 0600 <ssh_host_key_path>/ssh_host_*_key
   ```

1. キーのフィンガープリントの一致を検証するには、各サイトのプライマリとセカンダリのノードの両方で次のコマンドを実行します:

   ```shell
   for file in <ssh_host_key_path>/ssh_host_*_key; do ssh-keygen -lf $file; done
   ```

   これと同様の出力が表示され、両方のノードで同一である必要があります:

   ```shell
   1024 SHA256:FEZX2jQa2bcsd/fn/uxBzxhKdx4Imc4raXrHwsbtP0M root@serverhostname (DSA)
   256 SHA256:uw98R35Uf+fYEQ/UnJD9Br4NXUFPv7JAUln5uHlgSeY root@serverhostname (ECDSA)
   256 SHA256:sqOUWcraZQKd89y/QQv/iynPTOGQxcOTIXU/LsoPmnM root@serverhostname (ED25519)
   2048 SHA256:qwa+rgir2Oy86QI+PZi/QVR+MSmrdrpsuH7YyKknC+s root@serverhostname (RSA)
   ```

1. 既存の秘密キーに正しい公開キーがあることを確認します:

   ```shell
   # This will print the fingerprint for private keys:
   for file in <ssh_host_key_path>/ssh_host_*_key; do ssh-keygen -lf $file; done

   # This will print the fingerprint for public keys:
   for file in <ssh_host_key_path>/ssh_host_*_key.pub; do ssh-keygen -lf $file; done
   ```

   {{< alert type="note" >}}

   秘密キーと公開キーコマンドの出力は、同じフィンガープリントを生成する必要があります。

   {{< /alert >}}

1. **セカンダリサイトの各Railsノード**で、OpenSSHの場合は`sshd`、または`gitlab-sshd`サービスを再起動します:

   - OpenSSHの場合:

     ```shell
     # Debian or Ubuntu installations
     sudo service ssh reload

     # CentOS installations
     sudo service sshd reload
     ```

   - `gitlab-sshd`の場合:

     ```shell
     sudo gitlab-ctl restart gitlab-sshd
     ```

1. SSHがまだ機能していることを確認します。

   新しいターミナルでGitLab **セカンダリ**サーバーにSSH接続します。接続できない場合は、前の手順に従って権限が正しいことを確認してください。

## ステップ3: **セカンダリ**サイトを追加 {#step-3-add-the-secondary-site}

1. **セカンダリサイトの各RailsおよびSidekiqノード**にSSH接続し、rootとしてログインします:

   ```shell
   sudo -i
   ```

1. `/etc/gitlab/gitlab.rb`を編集し、サイトに**unique**な名前を追加します。これは、次の手順で必要になります:

   ```ruby
   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/ee/administration/geo_sites.html#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'
   ```

1. 変更を有効にするには、**セカンダリサイトの各RailsおよびSidekiqノード**を再設定します:

   ```shell
   gitlab-ctl reconfigure
   ```

1. プライマリノードのGitLabインスタンスに移動します:
   1. 左側のサイドバーの下部で、**管理者**を選択します。
   1. 左側のサイドバーの下部にある**Geo** > **サイト**を選択します。
   1. **サイトを追加**を選択します。![Geo設定インターフェースでのセカンダリサイトの追加](img/adding_a_secondary_v15_8.png)
   1. **名前**に、`/etc/gitlab/gitlab.rb`の`gitlab_rails['geo_node_name']`の値を入力します。これらの値は常に、文字どおり**exactly**一致する必要があります。
   1. **外部URL**に、`/etc/gitlab/gitlab.rb`の`external_url`の値を入力します。これらの値は常に一致する必要がありますが、一方が`/`で終わり、もう一方が終わらない場合は問題ありません。
   1. オプション。**内部URL (オプション)**に、セカンダリサイトの内部URLを入力します。
   1. オプション。**セカンダリ**サイトによってレプリケートされるグループまたはストレージシャードを選択します。すべてをレプリケートするには、空白のままにします。詳細については、[selective synchronization](selective_synchronization.md)を参照してください。
   1. **変更を保存**を選択して、**セカンダリ**サイトを追加します。
1. **セカンダリサイトの各RailsおよびSidekiqノード**にSSH接続し、サービスを再起動します:

   ```shell
   gitlab-ctl restart
   ```

   実行して、Geoの設定に関する一般的なイシューがあるかどうかを確認します:

   ```shell
   gitlab-rake gitlab:geo:check
   ```

   チェックのいずれかが失敗した場合は、[troubleshooting documentation](troubleshooting/_index.md)を確認してください。

1. **Rails or Sidekiq server on your primary**サイトにSSH接続し、rootとしてログインして、**セカンダリ**サイトが到達可能であるか、Geoの設定に共通のイシューがないかを確認します:

   ```shell
   gitlab-rake gitlab:geo:check
   ```

   チェックのいずれかが失敗した場合は、[troubleshooting documentation](troubleshooting/_index.md)を確認してください。

**セカンダリ**サイトがGeoの管理者ページに追加され、再起動されると、サイトは自動的に**プライマリ**サイトから不足データのレプリケートを**backfill**というプロセスで開始します。一方、**プライマリ**サイトは各**セカンダリ**サイトに変更を通知し始め、**セカンダリ**サイトはこれらの通知にすぐに対応できます。

セカンダリサイトが実行中でアクセス可能であることを確認してください。プライマリサイトで使用したものと同じ認証情報を使用してセカンダリサイトにサインインできます。

## ステップ4: （オプション）カスタム証明書の使用 {#step-4-optional-using-custom-certificates}

次の場合は、この手順を安全にスキップできます:

- **プライマリ**サイトが、公開CA発行のHTTPS証明書を使用している。
- **プライマリ**サイトは、CA発行（自己署名ではない）のHTTPS証明書を使用して、外部サービスにのみ接続する。

### インバウンド接続用のカスタムまたは自己署名証明書 {#custom-or-self-signed-certificate-for-inbound-connections}

GitLab Geoの**プライマリ**サイトが、カスタムまたは[self-signed certificate to secure inbound HTTPS connections](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates)を使用している場合、これはシングルドメイン証明書またはマルチドメイン証明書のいずれかになります。

証明書のタイプに基づいて、正しい証明書をインストールします:

- **Multi-domain certificate**: プライマリサイトとセカンダリサイトドメインの両方を含む: `/etc/gitlab/ssl`の証明書を**Rails, Sidekiq, and Gitaly**（Rails、Sidekiq、およびGitaly） ノード (**セカンダリ**サイト内) すべてにインストールします。
- **Single-domain certificate**: 証明書が各Geoサイトドメインに固有である: **セカンダリ**サイトのドメインの有効な証明書を生成し、`/etc/gitlab/ssl`ですべての**Rails, Sidekiq, and Gitaly**（Rails、Sidekiq、およびGitaly）ノード (**セカンダリ**サイト内) に[these instructions](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates)に従ってインストールします。

### カスタム証明書を使用する外部サービスへの接続 {#connecting-to-external-services-that-use-custom-certificates}

外部サービス用の自己署名証明書のコピーは、サービスへのアクセスを必要とするすべての**プライマリ**サイトのノード上の信頼ストアに追加する必要があります。

**セカンダリ**サイトが同じ外部サービスにアクセスできるようにするには、これらの証明書を**セカンダリ**サイトのトラストストアに追加する必要があります。

**プライマリ**サイトが[custom or self-signed certificate for inbound HTTPS connections](#custom-or-self-signed-certificate-for-inbound-connections)を使用している場合、**プライマリ**サイトの証明書を**セカンダリ**サイトのトラストストアに追加する必要があります:

1. **セカンダリサイトのRails、Sidekiq、Gitalyノード**にSSH接続し、rootとしてログインします:

   ```shell
   sudo -i
   ```

1. **プライマリ**サイトから信頼できる証明書をコピーします:

   rootユーザーを使用してSSHトラフィックを処理する**プライマリ**サイトのノードの1つにアクセスできる場合:

   ```shell
   scp root@<primary_site_node_fqdn>:/etc/gitlab/trusted-certs/* /etc/gitlab/trusted-certs
   ```

   sudo権限を持つユーザーを介してのみアクセスできる場合:

   ```shell
   # Run this from the node on your primary site:
   sudo tar --transform 's/.*\///g' -zcvf ~/geo-trusted-certs.tar.gz /etc/gitlab/trusted-certs/*

   # Run this on each node on your secondary site:
   scp <user_with_sudo>@<primary_site_node_fqdn>:geo-trusted-certs.tar.gz .
   tar zxvf ~/geo-trusted-certs.tar.gz -C /etc/gitlab/trusted-certs
   ```

1. 更新された各**Rails, Sidekiq, and Gitaly node in your secondary**（Rails、Sidekiq、およびGitalyノード（セカンダリ））サイトを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## ステップ5: HTTP/HTTPSおよびSSHを介したGitアクセスを有効にする {#step-5-enable-git-access-over-httphttps-and-ssh}

GeoはHTTP/HTTPSを介してリポジトリを同期するため、このクローン方式を有効にする必要があります。これはデフォルトで有効になっていますが、既存のサイトをGeoに変換する場合は、確認する必要があります:

**プライマリ**サイトで:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **表示レベルとアクセス制御**を展開します。
1. SSH経由でGitを使用している場合は、次のようにします:
   1. 「有効なGitアクセスプロトコル」が「SSHとHTTP(S)の両方」に設定されていることを確認します。
   1. **all primary and secondary**サイトで[fast lookup of authorized SSH keys in the database](../../operations/fast_ssh_key_lookup.md)を設定する手順に従ってください。
1. SSH経由でGitを使用していない場合は、「有効なGitアクセスプロトコル」を「HTTP(S)のみ」に設定します。

## ステップ6: **セカンダリ**サイトの適切な機能を検証します {#step-6-verify-proper-functioning-of-the-secondary-site}

**セカンダリ**サイトには、**プライマリ**サイトで使用したものと同じ認証情報でサインインできます。サインインした後:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **Geo** > **サイト**を選択します。
1. それが**セカンダリ** Geoサイトとして正しく識別され、Geoが有効になっていることを確認します。

最初のレプリケーションには時間がかかる場合があります。サイトのステータスまたは「バックフィル」は、まだ進行中である可能性があります。ブラウザで、**プライマリ**サイトの**Geoサイト**ダッシュボードから、各Geoサイトの同期プロセスをモニタリングできます。

![Geo dashboard of secondary site](img/geo_dashboard_v14_0.png)

インストールが正しく機能しない場合は、[troubleshooting document](troubleshooting/_index.md)を確認してください。

ダッシュボードで明らかになる可能性のある2つの最も明白なイシューは次のとおりです:

1. データベースのレプリケーションがうまく機能していません。
1. インスタンスからインスタンスへの通知が機能していません。その場合、次のいずれかになります:
   - カスタム証明書またはカスタムCAを使用しています（[troubleshooting document](troubleshooting/_index.md)を参照）。
   - インスタンスがファイアウォールで保護されています（ファイアウォールルールを確認してください）。

**セカンダリ**サイトを無効にすると、同期プロセスが停止します。

リポジトリストレージが複数のリポジトリシャードの**プライマリ**サイトでカスタマイズされている場合は、同じ設定を各**セカンダリ**サイトで複製する必要があります。

[Using a Geo Site guide](usage.md)にユーザーを誘導します。

現在、同期されているのは次のとおりです:

- Gitリポジトリ
- Wiki。
- LFSオブジェクト。
- イシュー、マージリクエスト、スニペット、コメントの添付ファイル。
- ユーザー、グループ、プロジェクトアバター。

## トラブルシューティング {#troubleshooting}

[troubleshooting document](troubleshooting/_index.md)を参照してください。
