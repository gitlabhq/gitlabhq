---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 2つの単一ノードサイト用のGeoをセットアップする（外部PostgreSQLサービスを使用）
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

次のガイドでは、2つのLinuxパッケージインスタンスと、RDS、Azure Database、Google Cloud SQLなどの外部PostgreSQLデータベースを使用して、2つのシングルノードサイト構成のGitLab Geoをデプロイする方法について、簡潔に説明します。

前提要件: 

- 少なくとも2つの独立して動作するGitLabサイトが必要です。サイトの作成については、[GitLabリファレンスアーキテクチャに関するドキュメント](../../reference_architectures/_index.md)を参照してください。
  - 1つのGitLabサイトが**Geo primary site**（Geoプライマリサイト）として機能します。各Geoサイトに対して異なるリファレンスアーキテクチャのサイズを使用できます。GitLabインスタンスがすでに動作している場合は、プライマリサイトとして使用できます。
  - 2番目のGitLabサイトは、**Geo secondary site**（Geoセカンダリサイト）として機能します。Geoでは、複数のセカンダリサイトがサポートされています。
- Geoプライマリサイトには、少なくとも[GitLab Premium](https://about.gitlab.com/pricing/)のライセンスが必要です。すべてのサイトに必要なライセンスは1つだけです。
- すべてのサイトが[Geoを実行するための要件](../_index.md#requirements-for-running-geo)を満たしていることを確認します。

## Linuxパッケージ版Geoのセットアップ {#set-up-geo-for-linux-package-omnibus}

前提要件: 

- [`pg_basebackup`ツール](https://www.postgresql.org/docs/16/app-pgbasebackup.html)を含むPostgreSQL 12以降を使用します。

### プライマリサイトの設定 {#configure-the-primary-site}

1. SSHを使用してGitLabプライマリサイトにログインし、rootとしてサインインします:

   ```shell
   sudo -i
   ```

1. 一意のGeoサイト名を`/etc/gitlab/gitlab.rb`に追加します:

   ```ruby
   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/ee/administration/geo_sites.html#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'
   ```

1. 変更を適用するには、プライマリサイトを再設定します:

   ```shell
   gitlab-ctl reconfigure
   ```

1. サイトをプライマリGeoサイトとして定義します:

   ```shell
   gitlab-ctl set-geo-primary-node
   ```

   このコマンドは、`/etc/gitlab/gitlab.rb`で定義された`external_url`を使用します。

設定例については、[外部PostgreSQLを使用したプライマリサイトの完了](#complete-primary-site-with-external-postgresql)を参照してください。

### レプリケートする外部データベースの設定 {#configure-the-external-database-to-be-replicated}

外部データベースを設定するには、次のいずれかを実行します:

- [ストリーミングレプリケーション](https://www.postgresql.org/docs/16/warm-standby.html#STREAMING-REPLICATION-SLOTS)を自分で設定します（たとえば、Amazon RDS、またはLinuxパッケージで管理されていないベアメタル）。
- 次のように、Linuxパッケージインストールの設定を手動で実行します。

#### クラウドプロバイダーのツールを利用して、プライマリデータベースをレプリケートする {#leverage-your-cloud-providers-tools-to-replicate-the-primary-database}

RDSを使用するAWS EC2にプライマリサイトが設定されているとします。これで、別のリージョンに読み取り専用のレプリカを作成するだけで、レプリケーションプロセスはAWSによって管理されます。セカンダリRailsノードがデータベースにアクセスできるように、必要に応じてネットワークACL（アクセス制御リスト）、サブネット、およびセキュリティグループを設定していることを確認してください。

次の手順では、一般的なクラウドプロバイダーの読み取り専用のレプリカを作成する方法について詳しく説明します:

- Amazon RDS - [リードレプリカの作成](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html#USER_ReadRepl.Create)
- Azure Database for PostgreSQL - [Azure Database for PostgreSQLで読み取り専用レプリカを作成および管理する](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-read-replicas-portal)
- Google Cloud SQL - [リードレプリカの作成](https://cloud.google.com/sql/docs/postgres/replication/create-replica)

読み取り専用のレプリカが設定されたら、[セカンダリサイトの設定](#configure-the-secondary-site-to-use-the-external-read-replica)に進んでください。

### 外部リードレプリカを使用するようにセカンダリサイトを設定する {#configure-the-secondary-site-to-use-the-external-read-replica}

Linuxパッケージインストールでは、[`geo_secondary_role`](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles)には3つの主な機能があります:

1. レプリカデータベースを設定します。
1. トラッキングデータベースを設定します。
1. [Geoログカーソル](../_index.md#geo-log-cursor)を有効にします。

外部リードレプリカデータベースへの接続を設定するには:

1. **Rails, Sidekiq and Geo Log Cursor**（Rails、Sidekiq、およびGeoログカーソル）の各ノードにSSHで接続し、**セカンダリ**サイトでrootとしてログインします:

   ```shell
   sudo -i
   ```

1. `/etc/gitlab/gitlab.rb`を編集して、以下を追加します。

   ```ruby
   ##
   ## Geo Secondary role
   ## - configure dependent flags automatically to enable Geo
   ##
   roles ['geo_secondary_role']

   # note this is shared between both databases,
   # make sure you define the same password in both
   gitlab_rails['db_password'] = '<your_db_password_here>'

   gitlab_rails['db_username'] = 'gitlab'
   gitlab_rails['db_host'] = '<database_read_replica_host>'

   # Disable the bundled Omnibus PostgreSQL because we are
   # using an external PostgreSQL
   postgresql['enable'] = false
   ```

1. [外部PostgreSQLを使用したセカンダリサイトの完了](#complete-secondary-site-with-external-postgresql)から設定例をコピーします。変更を適用するには、ファイルを保存してGitLabを再設定します:

   ```shell
   gitlab-ctl reconfigure
   ```

レプリカデータベースへの接続に問題がある場合は、次のコマンドを使用してサーバーから[TCP接続を確認](../../raketasks/maintenance.md)します:

```shell
gitlab-rake gitlab:tcp_check[<replica FQDN>,5432]
```

このステップが失敗する場合は、間違ったIPアドレスを使用しているか、ファイアウォールがサイトへのアクセスを妨げている可能性があります。パブリックアドレスとプライベートアドレスの違いに注意して、IPアドレスを確認してください。ファイアウォールが存在する場合は、セカンダリサイトがポート5432でプライマリサイトに接続できることを確認してください。

#### GitLabのシークレット値を手動でレプリケートする {#manually-replicate-secret-gitlab-values}

GitLabは、`/etc/gitlab/gitlab-secrets.json`に多数のシークレット値を保存します。このJSONファイルは、各サイトノードで同じである必要があります。[イシュー3789](https://gitlab.com/gitlab-org/gitlab/-/issues/3789)でこの動作を変更することが提案されていますが、シークレットファイルをすべてのセカンダリサイトに手動でレプリケートする必要があります。

1. SSHを使用してプライマリサイトのRailsノードに接続し、次のコマンドを実行します:

   ```shell
   sudo cat /etc/gitlab/gitlab-secrets.json
   ```

   これにより、JSON形式でレプリケートする必要のあるシークレットが表示されます。

1. SSHを使用してGeoセカンダリサイトの各ノードに接続し、rootとしてサインインします:

   ```shell
   sudo -i
   ```

1. 既存のシークレットのバックアップを作成します:

   ```shell
   mv /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.`date +%F`
   ```

1. プライマリサイトのRailsノードから各セカンダリサイトノードに`/etc/gitlab/gitlab-secrets.json`をコピーします。ノード間でファイルの内容をコピーアンドペーストすることもできます:

   ```shell
   sudo editor /etc/gitlab/gitlab-secrets.json

   # paste the output of the `cat` command you ran on the primary
   # save and exit
   ```

1. ファイルの権限が正しいことを確認してください:

   ```shell
   chown root:root /etc/gitlab/gitlab-secrets.json
   chmod 0600 /etc/gitlab/gitlab-secrets.json
   ```

1. 変更を適用するには、すべてのRails、Sidekiq、およびGitalyセカンダリサイトノードを再設定します:

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart
   ```

#### プライマリサイトのSSHホストキーを手動でレプリケートする {#manually-replicate-the-primary-site-ssh-host-keys}

1. SSHを使用してセカンダリサイトの各ノードに接続し、rootとしてサインインします:

   ```shell
   sudo -i
   ```

1. 既存のSSHホストキーをバックアップします:

   ```shell
   find /etc/ssh -iname 'ssh_host_*' -exec cp {} {}.backup.`date +%F` \;
   ```

1. プライマリサイトからOpenSSHホストキーをコピーします。

   - SSHトラフィックを処理するプライマリサイトノード（通常はGitLab Railsアプリケーションのmainノード）の1つにrootとしてアクセスできる場合:

     ```shell
     # Run this from the secondary site, change `<primary_site_fqdn>` for the IP or FQDN of the server
     scp root@<primary_node_fqdn>:/etc/ssh/ssh_host_*_key* /etc/ssh
     ```

   - `sudo`権限を持つユーザーを通じてのみアクセスできる場合:

     ```shell
     # Run this from the node on your primary site:
     sudo tar --transform 's/.*\///g' -zcvf ~/geo-host-key.tar.gz /etc/ssh/ssh_host_*_key*

     # Run this on each node on your secondary site:
     scp <user_with_sudo>@<primary_site_fqdn>:geo-host-key.tar.gz .
     tar zxvf ~/geo-host-key.tar.gz -C /etc/ssh
     ```

1. セカンダリサイトノードごとに、ファイルの権限が正しいことを確認します:

   ```shell
   chown root:root /etc/ssh/ssh_host_*_key*
   chmod 0600 /etc/ssh/ssh_host_*_key
   ```

1. キーのフィンガープリントが一致することを確認するには、各サイトのプライマリノードとセカンダリノードの両方で次のコマンドを実行します:

   ```shell
   for file in /etc/ssh/ssh_host_*_key; do ssh-keygen -lf $file; done
   ```

   次のような出力が得られるはずです:

   ```shell
   1024 SHA256:FEZX2jQa2bcsd/fn/uxBzxhKdx4Imc4raXrHwsbtP0M root@serverhostname (DSA)
   256 SHA256:uw98R35Uf+fYEQ/UnJD9Br4NXUFPv7JAUln5uHlgSeY root@serverhostname (ECDSA)
   256 SHA256:sqOUWcraZQKd89y/QQv/iynPTOGQxcOTIXU/LsoPmnM root@serverhostname (ED25519)
   2048 SHA256:qwa+rgir2Oy86QI+PZi/QVR+MSmrdrpsuH7YyKknC+s root@serverhostname (RSA)
   ```

   出力は両方のノードで同じである必要があります。

1. 既存のプライベートキーの正しいパブリックキーがあることを確認します:

   ```shell
   # This will print the fingerprint for private keys:
   for file in /etc/ssh/ssh_host_*_key; do ssh-keygen -lf $file; done

   # This will print the fingerprint for public keys:
   for file in /etc/ssh/ssh_host_*_key.pub; do ssh-keygen -lf $file; done
   ```

   パブリックキーコマンドとプライベートキーコマンドの出力は、同じフィンガープリントを生成する必要があります。

1. セカンダリサイトノードごとに、`sshd`を再起動します:

   ```shell
   # Debian or Ubuntu installations
   sudo service ssh reload

   # CentOS installations
   sudo service sshd reload
   ```

1. SSHがまだ機能していることを確認するには、新しいターミナルからSSHを使用してGitLabセカンダリサーバーに接続します。接続できない場合は、正しい権限があることを確認してください。

#### 承認されたSSHキーの高速検索 {#fast-lookup-of-authorized-ssh-keys}

最初のレプリケーションプロセスが完了したら、[許可されたSSHキーの高速ルックアップを設定する](../../operations/fast_ssh_key_lookup.md)手順に従います。

高速ルックアップは[Geoに必須](../../operations/fast_ssh_key_lookup.md#fast-lookup-is-required-for-geo)です。

{{< alert type="note" >}}

認証はプライマリサイトによって処理されます。セカンダリサイトのカスタム認証を設定しないでください。**管理者**エリアへのアクセスが必要な変更は、プライマリサイトで行う必要があります。これは、セカンダリサイトが読み取り専用のコピーであるためです。

{{< /alert >}}

#### セカンダリサイトを追加します {#add-the-secondary-site}

1. SSHを使用してセカンダリサイトの各RailsおよびSidekiqノードに接続し、rootとしてサインインします:

   ```shell
   sudo -i
   ```

1. `/etc/gitlab/gitlab.rb`を編集して、サイトの一意の名前を追加します。

   ```ruby
   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/ee/administration/geo_sites.html#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<secondary_site_name_here>'
   ```

   次の手順のために、一意の名前を保存します。

1. 変更を適用するには、セカンダリサイトの各RailsおよびSidekiqノードを再設定します。

   ```shell
   gitlab-ctl reconfigure
   ```

1. プライマリノードGitLabインスタンスに移動します:
   1. 左側のサイドバーの下部にある**管理者**を選択します。
   1. **Geo** > **サイト**を選択します。
   1. **サイトを追加**を選択します。

      ![新しいGeoセカンダリサイトを追加するフォーム](img/adding_a_secondary_v15_8.png)

   1. **名前**に、`/etc/gitlab/gitlab.rb`の`gitlab_rails['geo_node_name']`の値を入力します。値は完全に一致する必要があります。
   1. **外部URL**に、`/etc/gitlab/gitlab.rb`の`external_url`の値を入力します。一方の値が`/`で終わり、もう一方の値が終わらない場合は問題ありません。それ以外の場合、値は完全に一致する必要があります。
   1. オプション。**内部URL（オプション）**に、プライマリサイトの内部URLを入力します。
   1. オプション。セカンダリサイトがレプリケートするグループまたはストレージシャードを選択します。すべてレプリケートするには、フィールドを空白のままにします。[選択的同期](../replication/selective_synchronization.md)を参照してください。
   1. **変更を保存**を選択します。
1. SSHを使用してセカンダリサイトの各RailsおよびSidekiqノードに接続し、サービスを再起動します:

   ```shell
   sudo gitlab-ctl restart
   ```

1. 実行して、Geo設定に関する一般的な問題があるかどうかを確認します:

   ```shell
   sudo gitlab-rake gitlab:geo:check
   ```

   チェックのいずれかが失敗した場合は、[トラブルシューティングドキュメント](../replication/troubleshooting/_index.md)を参照してください。

1. セカンダリサイトに到達できることを確認するには、SSHを使用してプライマリサイトのRailsまたはSidekiqサーバーに接続し、次を実行します:

   ```shell
   sudo gitlab-rake gitlab:geo:check
   ```

   チェックのいずれかが失敗した場合は、[トラブルシューティングドキュメント](../replication/troubleshooting/_index.md)を確認してください。

セカンダリサイトがGeo管理ページに追加され、再起動されると、サイトはバックフィルと呼ばれるプロセスで、プライマリサイトからの不足しているデータのレプリケートするを自動的に開始します。

一方、プライマリサイトは各セカンダリサイトに変更を通知し始め、セカンダリサイトがすぐに通知に対応できるようにします。

セカンダリサイトが実行中でアクセス可能であることを確認してください。プライマリサイトで使用したのと同じ認証情報を使用して、セカンダリサイトにサインインできます。

#### HTTP/HTTPSおよびSSH経由でのGitアクセスを有効にする {#enable-git-access-over-httphttps-and-ssh}

GeoはHTTP/HTTPS経由でリポジトリを同期するため（新しいインストールではデフォルトで有効）、このクローンメソッドを有効にする必要があります。既存のサイトをGeoに変換する場合は、クローンメソッドが有効になっていることを確認する必要があります。

プライマリサイトで次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **表示レベルとアクセス制御**を展開します。
1. SSH経由でGitを使用する場合:
   1. **有効なGitアクセスプロトコル**が**SSHとHTTP(S)の両方**に設定されていることを確認します。
   1. プライマリサイトとセカンダリサイトの両方で、[データベース内の許可されたSSHキーの高速ルックアップ](../../operations/fast_ssh_key_lookup.md)を有効にします。
1. SSH経由でGitを使用しない場合は、**有効なGitアクセスプロトコル**を**HTTP(S)のみ**に設定します。

#### セカンダリサイトが適切に機能していることを確認する {#verify-proper-functioning-of-the-secondary-site}

プライマリサイトで使用したのと同じ認証情報を使用して、セカンダリサイトにサインインできます。

サインイン後:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **Geo** > **サイト**を選択します。
1. サイトがGeoのセカンダリサイトとして正しく識別され、Geoが有効になっていることを確認します。

最初のレプリケーションには時間がかかる場合があります。ブラウザで、プライマリサイトの**Geoサイト**サイトのダッシュボードから、各Geoサイトの同期プロセスを監視できます。

![セカンダリサイトの同期ステータスを示すGeo管理者ダッシュボード。](img/geo_dashboard_v14_0.png)

## トラッキングデータベースの設定 {#configure-the-tracking-database}

{{< alert type="note" >}}

このステップは、別のサーバーで外部にトラッキングデータベースを設定する場合にもオプションです。

{{< /alert >}}

**セカンダリ**サイトは、レプリケーションステータスを追跡するため、および潜在的なレプリケーションの問題から自動的に回復するために、トラッキングデータベースとして個別のPostgreSQLインストールを使用します。Linuxパッケージは、`roles ['geo_secondary_role']`が設定されている場合、トラッキングデータベースを自動的に設定します。このデータベースをLinuxパッケージインストール外部で実行する場合は、次の手順を使用します。

### クラウド管理データベースサービス {#cloud-managed-database-services}

トラッキングデータベースにクラウド管理サービスを使用している場合は、トラッキングデータベースユーザーに追加のロールを付与する必要がある場合があります（デフォルトでは、`gitlab_geo`です）:

- Amazon RDSには、[`rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.html#Appendix.PostgreSQL.CommonDBATasks.Roles)ロールが必要です。
- Azure Database for PostgreSQLには、[`azure_pg_admin`](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-create-users#how-to-create-additional-admin-users-in-azure-database-for-postgresql)ロールが必要です。
- Google Cloud SQLには、[`cloudsqlsuperuser`](https://cloud.google.com/sql/docs/postgres/users#default-users)ロールが必要です。

インストールおよびアップグレード中に、拡張機能のインストールには追加のロールが必要です。別の方法として、[拡張機能が手動でインストールされていることを確認し、将来のGitLabアップグレード中に発生する可能性のある問題についてお読みください](../../../install/postgresql_extensions.md)。

{{< alert type="note" >}}

Amazon RDSをトラッキングデータベースとして使用する場合は、セカンダリデータベースにアクセスできることを確認してください。残念ながら、送信ルールはRDS PostgreSQLデータベースに適用されないため、同じセキュリティグループを割り当てるだけでは十分ではありません。したがって、ポート5432のトラッキングデータベースからのすべてのTCPトラフィックを許可する、リードレプリカのセキュリティグループに受信ルールを明示的に追加する必要があります。

{{< /alert >}}

### トラッキングデータベースを作成する {#create-the-tracking-database}

PostgreSQLインスタンスにトラッキングデータベースを作成して設定します:

1. [データベース要件に関するドキュメント](../../../install/requirements.md#postgresql)に従ってPostgreSQLをセットアップします。
1. 選択したパスワードを使用して`gitlab_geo`ユーザーを設定し、`gitlabhq_geo_production`データベースを作成し、ユーザーをデータベースのオーナーにします。この設定の例は、[セルフコンパイルインストールのドキュメント](../../../install/self_compiled/_index.md#7-database)にあります。
1. クラウド管理PostgreSQLデータベースを使用**していない**場合は、セカンダリサイトがトラッキングデータベースに関連付けられている`pg_hba.conf`を手動で変更して、トラッキングデータベースと通信できることを確認してください。変更を有効にするには、その後、PostgreSQLを再起動することを忘れないでください:

   ```plaintext
   ##
   ## Geo Tracking Database Role
   ## - pg_hba.conf
   ##
   host    all         all               <trusted tracking IP>/32      md5
   host    all         all               <trusted secondary IP>/32     md5
   ```

### GitLabを設定する {#configure-gitlab}

このデータベースを使用するようにGitLabを設定します。これらの手順は、LinuxパッケージおよびDockerデプロイメント用です。

1. GitLab **セカンダリ**サーバーにSSHで接続し、rootとしてログインします:

   ```shell
   sudo -i
   ```

1. PostgreSQLインスタンスを持つマシンの接続パラメータと認証情報を使用して`/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   geo_secondary['db_username'] = 'gitlab_geo'
   geo_secondary['db_password'] = '<your_tracking_db_password_here>'

   geo_secondary['db_host'] = '<tracking_database_host>'
   geo_secondary['db_port'] = <tracking_database_port>      # change to the correct port
   geo_postgresql['enable'] = false     # don't use internal managed instance
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   gitlab-ctl reconfigure
   ```

#### データベーススキーマを手動でセットアップする（オプション） {#manually-set-up-the-database-schema-optional}

[前述の手順](#configure-gitlab)のreconfigureコマンドは、これらの手順を自動的に処理します。これらの手順は、何らかの問題が発生した場合に備えて提供されています。

1. このタスクは、データベーススキーマを作成します。データベースユーザーはスーパーユーザーである必要があります。

   ```shell
   sudo gitlab-rake db:create:geo
   ```

1. Railsデータベースの移行（スキーマとデータの更新）の適用も、reconfigureによって実行されます。`geo_secondary['auto_migrate'] = false`が設定されている場合、またはスキーマが手動で作成された場合、この手順が必要です:

   ```shell
   sudo gitlab-rake db:migrate:geo
   ```

## 設定例 {#example-configurations}

### 外部PostgreSQLを使用した完全なプライマリサイト {#complete-primary-site-with-external-postgresql}

<!-- If you update this configuration example, also update the example in two_single_node_sites.md -->

この完全な`gitlab.rb`設定例は、外部PostgreSQLを使用するGeoプライマリサイト用です:

```ruby
# Primary site with external PostgreSQL configuration example

## Geo Primary role
roles(['geo_primary_role'])

## The unique identifier for the Geo site
gitlab_rails['geo_node_name'] = 'headquarters'

## External URL
external_url 'https://gitlab.example.com'

## External PostgreSQL configuration
postgresql['enable'] = false
gitlab_rails['db_adapter'] = 'postgresql'
gitlab_rails['db_encoding'] = 'unicode'
gitlab_rails['db_host'] = 'primary-postgres.example.com'
gitlab_rails['db_port'] = 5432
gitlab_rails['db_database'] = 'gitlabhq_production'
gitlab_rails['db_username'] = 'gitlab'
gitlab_rails['db_password'] = 'your_database_password_here'

## SSL/TLS configuration
nginx['listen_port'] = 80
nginx['listen_https'] = false
letsencrypt['enable'] = false

## Object Storage configuration (recommended for external services)
gitlab_rails['object_store']['enabled'] = true
gitlab_rails['object_store']['connection'] = {
  'provider' => 'AWS',
  'region' => 'us-east-1',
  'aws_access_key_id' => 'your_access_key',
  'aws_secret_access_key' => 'your_secret_key'
}

## Monitoring configuration
node_exporter['listen_address'] = '0.0.0.0:9100'
gitlab_workhorse['prometheus_listen_addr'] = '0.0.0.0:9229'
```

### 外部PostgreSQLを使用した完全なセカンダリサイト {#complete-secondary-site-with-external-postgresql}

<!-- If you update this configuration example, also update the example in two_single_node_sites.md -->

この完全な`gitlab.rb`設定例は、外部PostgreSQLを使用するGeoセカンダリサイト用です:

```ruby
# Secondary site with external PostgreSQL configuration example

## Geo Secondary role
roles(['geo_secondary_role'])

## The unique identifier for the Geo site
gitlab_rails['geo_node_name'] = 'location-2'

## External URL
external_url 'https://gitlab.example.com'

## External PostgreSQL configuration (read-only replica)
postgresql['enable'] = false
gitlab_rails['db_adapter'] = 'postgresql'
gitlab_rails['db_encoding'] = 'unicode'
gitlab_rails['db_host'] = 'secondary-postgres.example.com'
gitlab_rails['db_port'] = 5432
gitlab_rails['db_database'] = 'gitlabhq_production'
gitlab_rails['db_username'] = 'gitlab'
gitlab_rails['db_password'] = 'your_database_password_here'

## Geo tracking database configuration
geo_secondary['db_username'] = 'gitlab_geo'
geo_secondary['db_password'] = 'your_tracking_db_password_here'
geo_secondary['db_host'] = 'secondary-tracking-db.example.com'
geo_secondary['db_port'] = 5432
geo_postgresql['enable'] = false

## SSL/TLS configuration
nginx['listen_port'] = 80
nginx['listen_https'] = false
letsencrypt['enable'] = false

## Object Storage configuration (must match primary)
gitlab_rails['object_store']['enabled'] = true
gitlab_rails['object_store']['connection'] = {
  'provider' => 'AWS',
  'region' => 'us-east-1',
  'aws_access_key_id' => 'your_access_key',
  'aws_secret_access_key' => 'your_secret_key'
}

## Monitoring configuration
node_exporter['listen_address'] = '0.0.0.0:9100'
gitlab_workhorse['prometheus_listen_addr'] = '0.0.0.0:9229'
```

## トラブルシューティング {#troubleshooting}

[トラブルシューティングGeo](../replication/troubleshooting/_index.md)を参照してください。
