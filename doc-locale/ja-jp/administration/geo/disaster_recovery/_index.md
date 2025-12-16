---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ディザスターリカバリー（Geo）
description: Geoインスタンスを使用して、障害からリカバリーします。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Geoは、データベース、Gitリポジトリ、その他の資産をレプリケートします。[既知の問題](../_index.md#known-issues)が存在します。

{{< alert type="warning" >}}

マルチセカンダリ構成では、プロモートされないすべてのセカンダリの完全な再同期と再設定が必要となり、停止が発生します。

{{< /alert >}}

## シングルセカンダリ構成での**セカンダリ** Geoサイトのプロモート {#promoting-a-secondary-geo-site-in-single-secondary-configurations}

Geoレプリカを自動的にプロモートしてフェイルオーバーを実行することはできませんが、マシンへの`root`アクセス権があれば、手動でプロモートできます。

このプロセスでは、**セカンダリ** Geoサイトを**プライマリ**サイトにプロモートします。地理的な冗長性をできるだけ早く回復するには、これらの手順に従った直後に、新しい**セカンダリ**サイトを追加する必要があります。

### ステップ1.可能であれば、レプリケーションが完了するのを待ちます {#step-1-allow-replication-to-finish-if-possible}

**セカンダリ**サイトが**プライマリ**サイトからデータをレプリケートしている場合は、不必要なデータ損失を避けるために、[計画されたフェイルオーバードキュメント](planned_failover.md)にできる限り厳密に従ってください。

### ステップ2.**プライマリ**サイトを完全に無効にします {#step-2-permanently-disable-the-primary-site}

{{< alert type="warning" >}}

**プライマリ**サイトが停止した場合、**プライマリ**サイトに保存されているデータが**セカンダリ**サイトにレプリケートされていない可能性があります。続行する場合は、このデータを失われたものとして扱う必要があります。

{{< /alert >}}

**プライマリ**サイトで停止が発生した場合、書き込みが2つの異なるGitLabインスタンスで発生する可能性のあるスプリットブレイン状態を回避するために、あらゆる可能な限りのことを行う必要があります。これにより、リカバリー作業が複雑になります。そのため、フェイルオーバーに備えるには、**プライマリ**サイトを無効にする必要があります。

- SSHアクセスがある場合:

  1. **プライマリ**サイトにSSHで接続し、GitLabをブロックして無効にします:

     ```shell
     sudo gitlab-ctl stop
     ```

  1. サーバーが予期せず再起動した場合に、GitLabが再度起動しないようにします:

     ```shell
     sudo systemctl disable gitlab-runsvdir
     ```

- **プライマリ**サイトへのSSHアクセスがない場合は、マシンをオフラインにし、利用できるあらゆる手段で再起動しないようにします。次のことを行う必要があるかもしれません:

  - ロードバランサーを再設定します。
  - DNSレコードを変更します（たとえば、**セカンダリ**サイトを指すプライマリDNSレコードを指定して、**プライマリ**サイトの使用を停止します）。
  - 仮想サーバーを停止します。
  - ファイアウォールを通過するトラフィックをブロックします。
  - **プライマリ**サイトからオブジェクトストレージの権限を失効します。
  - マシンを物理的に切断します。

  [プライマリ](#step-4-optional-updating-the-primary-domain-dns-record)ドメインDNSレコードを更新することを計画している場合は、DNSの変更を迅速に伝達するために、低いTTLを維持することをお勧めします。

  {{< alert type="note" >}}

このプロセス中に、プライマリサイトの`/etc/gitlab/gitlab.rb`ファイルは、セカンダリサイトに自動的にコピーされません。プライマリの`/etc/gitlab/gitlab.rb`ファイルをバックアップして、後でセカンダリサイトに必要な値を復元できるようにしてください。

  {{< /alert >}}

### ステップ3.**セカンダリ**サイトのプロモート {#step-3-promoting-a-secondary-site}

セカンダリをプロモートするときは、以下に注意してください:

- セカンダリサイトが[一時停止された場合](../replication/pause_resume_replication.md)、プロモートにより、最後に認識された状態へのポイントインタイムリカバリーが実行されます。セカンダリが一時停止している間にプライマリで作成されたデータは失われます。
- この時点では、新しい**セカンダリ**を追加しないでください。新しい**セカンダリ**を追加する場合は、**セカンダリ**を**プライマリ**にプロモートするプロセス全体を完了した後に行ってください。
- このプロセス中に`ActiveRecord::RecordInvalid: Validation failed: Name has already been taken`エラーメッセージが表示された場合は、この[トラブルシューティング](failover_troubleshooting.md#fixing-errors-during-a-failover-or-when-promoting-a-secondary-to-a-primary-site)のアドバイスを参照してください。
- 個別のURLを使用している場合は、[新しくプロモートされたサイトでプライマリドメインDNSをポイントする必要があります](#step-4-optional-updating-the-primary-domain-dns-record)。それ以外の場合は、新しくプロモートされたサイトにRunnerを再度登録し、すべてのGitリモート、ブックマーク、および外部インテグレーションを更新する必要があります。
- [ロケーション対応DNS](../secondary_proxy/_index.md#configure-location-aware-dns)を使用している場合、古いプライマリがDNSエントリから削除されると、Runnerは自動的に新しいプライマリに接続します。
- 以前のプライマリに接続されていたRunnerが戻ってこないと予想される場合は、削除する必要があります:
  - UIを使用する場合は、以下のとおりです:
    1. 左側のサイドバーの下部で、**管理者**を選択します。
    1. 左側のサイドバーの下部にある**CI/CD** > **Runners**を選択して、それらを削除します。
  - [Runners API](../../../api/runners.md)を使用します。

#### **セカンダリ**サイトを単一ノードで実行するプロモート {#promoting-a-secondary-site-running-on-a-single-node}

1. **セカンダリ**サイトにSSHでログインして実行します:

   - セカンダリサイトをプライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - セカンダリサイトを**さらに確認せずに**プライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. 以前に**セカンダリ**サイトに使用したURLを使用して、新しくプロモートされた**プライマリ**サイトに接続できることを確認します。
1. 成功した場合、**セカンダリ**サイトは**プライマリ**サイトにプロモートされました。

#### 複数のノードを持つ**セカンダリ**サイトをプロモート {#promoting-a-secondary-site-with-multiple-nodes}

1. **セカンダリ**サイトのすべてのSidekiq、PostgreSQL、およびGitalyノードにSSHで接続し、次のいずれかのコマンドを実行します:

   - セカンダリサイトのノードをプライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - セカンダリサイトを**さらに確認せずに**プライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. **セカンダリ**サイトの各RailsノードにSSHで接続し、次のいずれかのコマンドを実行します:

   - セカンダリサイトをプライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - セカンダリサイトを**さらに確認せずに**プライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. 以前に**セカンダリ**サイトに使用したURLを使用して、新しくプロモートされた**プライマリ**サイトに接続できることを確認します。
1. 成功した場合、**セカンダリ**サイトは**プライマリ**サイトにプロモートされました。

#### Patroniスタンバイクラスタリングを持つ**セカンダリ**サイトをプロモート {#promoting-a-secondary-site-with-a-patroni-standby-cluster}

1. **セカンダリ**サイトのすべてのSidekiq、PostgreSQL、およびGitalyノードにSSHで接続し、次のいずれかのコマンドを実行します:

   - セカンダリサイトをプライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - セカンダリサイトを**さらに確認せずに**プライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. **セカンダリ**サイトの各RailsノードにSSHで接続し、次のいずれかのコマンドを実行します:

   - セカンダリサイトをプライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - セカンダリサイトを**さらに確認せずに**プライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. 以前に**セカンダリ**サイトに使用したURLを使用して、新しくプロモートされた**プライマリ**サイトに接続できることを確認します。
1. 成功した場合、**セカンダリ**サイトは**プライマリ**サイトにプロモートされました。

#### 外部PostgreSQLデータベースを持つ**セカンダリ**サイトをプロモート {#promoting-a-secondary-site-with-an-external-postgresql-database}

`gitlab-ctl geo promote`コマンドは、外部PostgreSQLデータベースと組み合わせて使用​​できます。この場合、最初に**セカンダリ**サイトに関連付けられているレプリカデータベースを手動でプロモートする必要があります:

1. **セカンダリ**サイトに関連付けられているレプリカデータベースをプロモートします。これにより、データベースが読み取り/書き込みに設定されます。手順は、データベースのホスト場所によって異なります:
   - [Amazon RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html#USER_ReadRepl.Promote)
   - [Azure PostgreSQL](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-read-replicas-portal#stop-replication)
   - [Google Cloud SQL](https://cloud.google.com/sql/docs/mysql/replication/manage-replicas#promote-replica)
   - 他の外部PostgreSQLデータベースの場合は、セカンダリサイト（たとえば、`/tmp/geo_promote.sh`）に次のスクリプトを保存し、環境変数に合わせて接続パラメータを変更します。次に、それを実行してレプリカをプロモートします:

     ```shell
     #!/bin/bash

     PG_SUPERUSER=postgres

     # The path to your pg_ctl binary. You may need to adjust this path to match
     # your PostgreSQL installation
     PG_CTL_BINARY=/usr/lib/postgresql/16/bin/pg_ctl

     # The path to your PostgreSQL data directory. You may need to adjust this
     # path to match your PostgreSQL installation. You can also run
     # `SHOW data_directory;` from PostgreSQL to find your data directory
     PG_DATA_DIRECTORY=/etc/postgresql/16/main

     # Promote the PostgreSQL database and allow read/write operations
     sudo -u $PG_SUPERUSER $PG_CTL_BINARY -D $PG_DATA_DIRECTORY promote
     ```

1. **セカンダリ**サイトのすべてのSidekiq、PostgreSQL、およびGitalyノードにSSHで接続し、次のいずれかのコマンドを実行します:

   - セカンダリサイトをプライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - セカンダリサイトを**さらに確認せずに**プライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. **セカンダリ**サイトの各RailsノードにSSHで接続し、次のいずれかのコマンドを実行します:

   - セカンダリサイトをプライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - セカンダリサイトを**さらに確認せずに**プライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. 以前に**セカンダリ**サイトに使用したURLを使用して、新しくプロモートされた**プライマリ**サイトに接続できることを確認します。
1. 成功した場合、**セカンダリ**サイトは**プライマリ**サイトにプロモートされました。

### ステップ4.（オプション）プライマリドメインDNSレコードの更新 {#step-4-optional-updating-the-primary-domain-dns-record}

プライマリドメインのDNSレコードを更新して、**セカンダリ**サイトを指すようにします。これにより、GitリモートやAPI URLを変更するなど、プライマリドメインへのすべての参照を更新する必要がなくなります。

1. **セカンダリ**サイトにSSHで接続し、ルートとしてログインします:

   ```shell
   sudo -i
   ```

1. プライマリドメインのDNSレコードを更新します。プライマリドメインのDNSレコードを更新して**セカンダリ**サイトをポイントした後、**セカンダリ**サイトの`/etc/gitlab/gitlab.rb`を編集して、新しいURLを反映させます:

   ```ruby
   # Change the existing external_url configuration
   external_url 'https://<new_external_url>'
   ```

   {{< alert type="note" >}}

   `external_url`変更しても、セカンダリDNSレコードがまだそのまま残っていれば、古いセカンダリURLを介したアクセスを防ぐことはできません。

   {{< /alert >}}

1. **セカンダリ**のSSL証明書を更新します:

   - [Let's Encryptインテグレーション](https://docs.gitlab.com/omnibus/settings/ssl/#enable-the-lets-encrypt-integration)を使用している場合、証明書は自動的に更新されます。
   - [手動でセットアップした場合](https://docs.gitlab.com/omnibus/settings/ssl/#configure-https-manually)、**セカンダリ**の証明書は、**プライマリ**から**セカンダリ**に証明書をコピーします。**プライマリ**にアクセスできない場合は、新しい証明書を発行し、サブジェクトの別名に**プライマリ**と**セカンダリ**の両方のURLが含まれていることを確認してください。以下で確認できます:

     ```shell
     /opt/gitlab/embedded/bin/openssl x509 -noout -dates -subject -issuer \
         -nameopt multiline -ext subjectAltName -in /etc/gitlab/ssl/new-gitlab.new-example.com.crt
     ```

1. 変更を有効にするには、**セカンダリ**サイトを再設定します:

   ```shell
   gitlab-ctl reconfigure
   ```

1. 新しくプロモートされた**プライマリ**サイトURLを更新するには、以下のコマンドを実行します:

   ```shell
   gitlab-rake geo:update_primary_node_url
   ```

   このコマンドは、`/etc/gitlab/gitlab.rb`で定義された変更された`external_url`設定を使用します。

1. URLを使用して、新しくプロモートされた**プライマリ**に接続できることを確認します。プライマリドメインのDNSレコードを更新した場合、これらの変更は、以前のDNSレコードのTTLによってはまだ伝播されていない可能性があります。

### ステップ5.（オプション）プロモートされた**プライマリ**サイトへの**セカンダリ** Geoサイトの追加 {#step-5-optional-add-secondary-geo-site-to-a-promoted-primary-site}

以前のプロセスを使用して**セカンダリ**サイトを**プライマリ**サイトにプロモートしても、新しい**プライマリ**サイトでGeoは有効になりません。

新しい**セカンダリ**サイトをオンラインにするには、[Geoセットアップ手順](../setup/_index.md)に従います。

### ステップ6.以前のセカンダリのトラッキングデータベースの削除 {#step-6-removing-the-former-secondarys-tracking-database}

すべての**セカンダリ**には、**プライマリ**からのすべてのアイテムの同期ステータスを保存するために使用される特別なトラッキングデータベースがあります。**セカンダリ**はすでにプロモートされているため、トラッキングデータベース内のそのデータは不要になりました。

次のコマンドを使用してデータを削除できます:

```shell
sudo rm -rf /var/opt/gitlab/geo-postgresql
```

`gitlab.rb`ファイルで`geo_secondary[]`設定オプションが有効になっている場合は、それらをコメントアウトするか削除して、[GitLabを再設定します](../../restart_gitlab.md#reconfigure-a-linux-package-installation)して、変更を有効にします。

この時点で、プロモートされたサイトは、Geoが設定されていない通常のGitLabサイトです。オプションで、[古いサイトをセカンダリとして戻す](bring_primary_back.md#configure-the-former-primary-site-to-be-a-secondary-site)ことができます。

## マルチセカンダリ構成でのセカンダリGeoレプリカのプロモート {#promoting-secondary-geo-replica-in-multi-secondary-configurations}

複数の**セカンダリ**サイトがあり、そのうちの1つをプロモートする必要がある場合は、[**セカンダリ** Geoサイトをシングルセカンダリ構成でプロモートする](#promoting-a-secondary-geo-site-in-single-secondary-configurations)ことをお勧めします。その後、さらに2つの手順が必要になります。

### ステップ1.1つ以上の**セカンダリ**サイトを提供する新しい**プライマリ**サイトを準備します {#step-1-prepare-the-new-primary-site-to-serve-one-or-more-secondary-sites}

1. 新しい**プライマリ**サイトにSSHで接続し、ルートとしてログインします:

   ```shell
   sudo -i
   ```

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   ## Enable a Geo Primary role (if you haven't yet)
   roles ['geo_primary_role']

   ##
   # Allow PostgreSQL client authentication from the primary and secondary IPs. These IPs may be
   # public or VPC addresses in CIDR format, for example ['198.51.100.1/32', '198.51.100.2/32']
   ##
   postgresql['md5_auth_cidr_addresses'] = ['<primary_site_ip>/32', '<secondary_site_ip>/32']

   # Every secondary site needs to have its own slot so specify the number of secondary sites you're going to have
   # postgresql['max_replication_slots'] = 1 # Set this to be the number of Geo secondary nodes if you have more than one

   ##
   ## Disable automatic database migrations temporarily
   ## (until PostgreSQL is restarted and listening on the private address).
   ##
   gitlab_rails['auto_migrate'] = false
   ```

   （これらの設定の詳細については、[プライマリサーバーの設定](../setup/database.md#step-1-configure-the-primary-site)を参照してください）

1. ファイルを保存し、データベースのリスンの変更と適用されるレプリケーションスロットの変更のために、GitLabを再設定します:

   ```shell
   gitlab-ctl reconfigure
   ```

   変更を有効にするには、PostgreSQLを再起動します:

   ```shell
   gitlab-ctl restart postgresql
   ```

1. PostgreSQLが再起動され、プライベートアドレスをリッスンするようになったので、移行を再度有効にします。

   `/etc/gitlab/gitlab.rb`を編集し、設定を**変更**して`true`にします:

   ```ruby
   gitlab_rails['auto_migrate'] = true
   ```

   ファイルを保存して、GitLabを再設定します:

   ```shell
   gitlab-ctl reconfigure
   ```

### ステップ2.レプリケーションプロセスの開始 {#step-2-initiate-the-replication-process}

ここで、各**セカンダリ**サイトに、新しい**プライマリ**サイトでの変更をリッスンさせる必要があります。そのためには、[レプリケーションプロセスを開始する](../setup/database.md#step-3-initiate-the-replication-process)必要がありますが、今回は別の**プライマリ**サイトに対して行います。古いレプリケーション設定はすべて上書きされます。

既存のセカンダリサイトにはすべて入力されたデータベースがあるため、次のようなメッセージが表示される場合があります:

```shell
Found data inside the gitlabhq_production database! If you are sure you are in the secondary server, override with --force
```

適切なセカンダリサイトにいることを確認したら、`--force`を使用してレプリケーションを開始します。

{{< alert type="warning" >}}

`--force`を使用すると、**そのセカンダリサーバー上のデータベース内の既存のデータがすべて削除されます**。

{{< /alert >}}

## GitLab HelmチャートでのセカンダリGeoクラスタリングのプロモート {#promoting-a-secondary-geo-cluster-in-the-gitlab-helm-chart}

クラウドネイティブGeoデプロイを更新する場合、セカンダリKubernetesクラスタの外部にあるノードを更新するプロセスは、クラウドネイティブではないアプローチとは異なります。そのため、詳細については、[シングルセカンダリ構成でのセカンダリGeoサイトのプロモート](#promoting-a-secondary-geo-site-in-single-secondary-configurations)を参照してください。

以下のセクションでは、`gitlab`ネームスペースを使用していることを前提としています。クラスターのセットアップ時に別のネームスペースを使用した場合は、`--namespace gitlab`を自分のネームスペースに置き換える必要もあります。

### ステップ1.**プライマリ**クラスターを完全に無効にする {#step-1-permanently-disable-the-primary-cluster}

{{< alert type="warning" >}}

**プライマリ**サイトがオフラインになると、**プライマリ**サイトに保存されているデータのうち、**セカンダリ**サイトにレプリケートされていないデータがある可能性があります。続行する場合は、このデータを失われたものとして扱う必要があります。

{{< /alert >}}

**プライマリ**サイトで停止が発生した場合、書き込みが2つの異なるGitLabインスタンスで発生する可能性のあるスプリットブレイン状態を回避するために、あらゆる可能な限りのことを行う必要があります。これにより、リカバリー作業が複雑になります。そのため、フェイルオーバーに備えるには、**プライマリ**サイトを無効にする必要があります:

- **プライマリ** Kubernetesクラスターへのアクセス権がある場合は、それに接続して、GitLab `webservice`および`Sidekiq`ポッドを無効にします:

  ```shell
  kubectl --namespace gitlab scale deploy gitlab-geo-webservice-default --replicas=0
  kubectl --namespace gitlab scale deploy gitlab-geo-sidekiq-all-in-1-v1 --replicas=0
  ```

- **プライマリ** Kubernetesクラスターへのアクセス権がない場合は、クラスターをオフラインにし、あらゆる手段を講じてオンラインに戻らないようにします。次のことを行う必要があるかもしれません:

  - ロードバランサーを再設定します。
  - DNSレコードを変更します（たとえば、**セカンダリ**サイトを指すプライマリDNSレコードを指定して、**プライマリ**サイトの使用を停止します）。
  - 仮想サーバーを停止します。
  - ファイアウォールを通過するトラフィックをブロックします。
  - **プライマリ**サイトからオブジェクトストレージの権限を失効します。
  - マシンを物理的に切断します。

### ステップ2.クラスター**セカンダリ**サイトのすべてのノードをプロモートします {#step-2-promote-all-secondary-site-nodes-external-to-the-cluster}

{{< alert type="warning" >}}

セカンダリサイトが[一時停止された場合](../_index.md#pausing-and-resuming-replication)、これは、最後に認識された状態への特定時点へのリカバリーを実行します。セカンダリが一時停止している間にプライマリで作成されたデータは失われます。

{{< /alert >}}

1. **セカンダリ** Kubernetesクラスターの外部にあるPostgreSQLやGitalyなどの各ノードについて、Linuxパッケージを使用して、ノードにSSHでログインし、次のいずれかのコマンドを実行します:

   - Kubernetesクラスターの外部にある**セカンダリ**サイトノードをプライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - Kubernetesクラスターの外部にある**セカンダリ**サイトノードを、**without any further confirmation**（それ以上の確認なしに） プライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. `toolbox`ポッドを見つけます:

   ```shell
   kubectl --namespace gitlab get pods -lapp=toolbox
   ```

1. セカンダリをプロモートします:

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- gitlab-rake geo:set_secondary_as_primary
   ```

   タスクの動作を変更するために、環境変数を指定できます。使用可能な変数は次のとおりです:

   | 名前 | デフォルト値 | 説明 |
   | ---- | ------------- | ------- |
   | `ENABLE_SILENT_MODE` | `false`  | `true`の場合、プロモートの前に[サイレントモード](../../silent_mode/_index.md)を有効にします（GitLab 16.4以降） |

### ステップ3.**セカンダリ**クラスターをプロモートします {#step-3-promote-the-secondary-cluster}

1. 既存のクラスター設定を更新します。

   Helmを使用して既存の設定を取得できます:

   ```shell
   helm --namespace gitlab get values gitlab-geo > gitlab.yaml
   ```

   既存の設定には、次のようなGeoのセクションが含まれています:

   ```yaml
   geo:
      enabled: true
      role: secondary
      nodeName: secondary.example.com
      psql:
         host: geo-2.db.example.com
         port: 5431
         password:
            secret: geo
            key: geo-postgresql-password
   ```

   **セカンダリ**クラスターを**プライマリ**クラスターにプロモートするには、`role: secondary`を`role: primary`に更新します。

   クラスターがプライマリサイトとして残っている場合は、`psql`セクション全体を削除できます。プライマリサイトとして機能している間は、トラッキングデータベースを参照し、無視されます。

   新しい設定でクラスターを更新します:

   ```shell
   helm upgrade --install --version <current Chart version> gitlab-geo gitlab/gitlab --namespace gitlab -f gitlab.yaml
   ```

1. セカンダリに使用されていたURLを使用して、新しくプロモートされたプライマリに接続できることを確認します。

1. 成功!これで、セカンダリがプライマリにプロモートされました。

## トラブルシューティング {#troubleshooting}

このセクションは[別の場所](failover_troubleshooting.md#fixing-errors-during-a-failover-or-when-promoting-a-secondary-to-a-primary-site)に移されました。
