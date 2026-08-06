---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ディザスターリカバリー（Geo）
description: Geoインスタンスを使用して、災害からリカバリーします。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Geoは、データベース、Gitリポジトリ、その他のアセットをレプリケートします。いくつかの[既知のイシュー](../_index.md#known-issues)があります。

> [!warning]
>
> - 複数セカンダリの設定では、プロモートされていないすべてのセカンダリの完全な再同期と再設定が必要であり、ダウンタイムが発生します。
> - セカンダリGeoサイトがプロモートされた後、プライマリGeoサイトは完全に切り離されます。プライマリGeoサイトを復元する場合は、新しいセカンダリGeoサイトとして追加する必要があります。

## 選択的同期が有効なセカンダリGeoサイト {#secondary-sites-with-selective-synchronization-enabled}

選択的同期が有効なセカンダリGeoサイトをプロモートすると、そのセカンダリGeoサイトにレプリケートされなかったすべてのデータが**permanent data loss**。詳細については、[選択的同期が有効なセカンダリGeoサイトのプロモート](../replication/selective_synchronization.md#promoting-a-secondary-site-with-selective-synchronization-enabled)を参照してください。

## `gitlab-cluster.json`ファイル {#the-gitlab-clusterjson-file}

`gitlab-ctl geo promote`を使用してセカンダリGeoサイトをプライマリGeoサイトにプロモートすると、コマンドは実行する各ノードに`/etc/gitlab/gitlab-cluster.json`ファイルが自動的に作成されます。ほとんどの場合、このファイルを手動で編集する必要はありません。

`gitlab-cluster.json`ファイルを使用すると、`/etc/gitlab/gitlab.rb`を直接変更することなく、プロモートコマンドで設定の変更を自動化できます。`gitlab.rb`をプログラムで編集するとエラーが発生しやすいため、`gitlab-cluster.json`は機械で管理される上書きレイヤーとして機能します。

両方のファイルが存在する場合、`gitlab-ctl reconfigure`が実行されると、`gitlab-cluster.json`の値が`gitlab.rb`の対応する値より優先されます。このコマンドを実行すると、次のような警告が表示されます:

```plaintext
The 'geo_primary_role' is defined in /etc/gitlab/gitlab-cluster.json as 'true' and overrides the setting in the /etc/gitlab/gitlab.rb
The 'geo_secondary_role' is defined in /etc/gitlab/gitlab-cluster.json as 'false' and overrides the setting in the /etc/gitlab/gitlab.rb
```

この警告は、プロモート後に予期されるものです。

### ファイル構造 {#file-structure}

典型的な`gitlab-cluster.json`ファイルは次のようになります:

```json
{
  "primary": true,
  "secondary": false,
  "geo_secondary": {
    "enable": false
  }
}
```

| キー | 説明 |
|---|---|
| `primary` | `true`の場合、`geo_primary_role`が有効になり、ノードがGeoプライマリとして設定されます。 |
| `secondary` | `true`の場合、`geo_secondary_role`が有効になり、ノードがGeoセカンダリとして設定されます。 |
| `geo_secondary` | Geoセカンダリ設定に関連する設定（追跡データベースなど）を含みます。`"enable": false`はセカンダリ固有のサービスを無効にします。 |

`primary`と`secondary`キーは、それぞれ`geo_primary_role`と`geo_secondary_role`に対応します。これらのロールは単一ノードの設定に便利なものであり、個々のサービスロールが`gitlab.rb`で明示的に設定されているマルチノードの設定では使用しないでください。

### ファイルを削除 {#remove-the-file}

プロモートが成功した後も、`gitlab-cluster.json`を残しておくことができます。ただし、次のような場合は削除する必要があります:

- [降格されたプライマリを新しいセカンダリGeoサイトとして戻す](bring_primary_back.md#configure-the-former-primary-site-to-be-a-secondary-site)場合は、すべてのSidekiq、PostgreSQL、Gitaly、およびRailsノードから`gitlab-cluster.json`を削除する必要があります。
- `gitlab.rb`を更新してGeoロール（`roles(['geo_primary_role'])`など）を設定し、`gitlab.rb`を唯一の設定ソースにしたい場合。
- 部分的なフェイルオーバーからリカバリーした後。

  ファイルがリカバリー中に手動で作成される時期の詳細については、[部分的なフェイルオーバーからのリカバリー](failover_troubleshooting.md#recovering-from-a-partial-failover)を参照してください。

ファイルを削除するには:

- 次のコマンドを実行します:

  ```shell
  sudo rm /etc/gitlab/gitlab-cluster.json
  sudo gitlab-ctl reconfigure
  ```

  マルチノードの設定では、サイトのすべてのノードでこれらのコマンドを繰り返します。

`gitlab-cluster.json`が再設定プロセスとどのように連携するかの技術的な詳細については、[Omnibus再設定ドキュメント](https://docs.gitlab.com/omnibus/development/reconfigure_in_detail/#gitlab-clusterjson-file)を参照してください。

## 単一ノードの設定におけるセカンダリGeoサイトのプロモート {#promoting-a-secondary-geo-site-in-single-secondary-configurations}

Geoレプリカを自動的にプロモートしてフェイルオーバーを行うことはできませんが、マシンへの`root`アクセスがある場合は手動でプロモートできます。

このプロセスは、セカンダリGeoサイトをプライマリGeoサイトにプロモートします。地理的な冗長性をできるだけ早く回復するために、これらの手順に従った直後に新しいセカンダリGeoサイトを追加する必要があります。

### 可能であればレプリケーションの完了を許可する {#allow-replication-to-finish-if-possible}

セカンダリGeoサイトがまだプライマリGeoサイトからデータをレプリケートしている場合は、不要なデータ損失を避けるために[計画されたフェイルオーバードキュメント](planned_failover.md)に可能な限り厳密に従ってください。

### ステップ1.プライマリGeoサイトを永続的に無効にする {#step-1-permanently-disable-the-primary-site}

> [!warning]
> プライマリGeoサイトがオフラインになった場合、プライマリGeoサイトに保存されているデータがセカンダリGeoサイトにレプリケートされていない可能性があります。続行すると、このデータは失われたものとして扱われます。

プライマリGeoサイトで停止が発生した場合、2つの異なるGitLabインスタンスで書き込みが発生するスプリットブレイン状態を回避するために可能な限りのことを行う必要があります。これはリカバリー作業を複雑にします。したがって、フェイルオーバーの準備として、プライマリGeoサイトを無効にする必要があります。

- SSHアクセスがある場合:

  1. プライマリGeoサイトにSSHで接続し、GitLabを停止および無効にします:

     ```shell
     sudo gitlab-ctl stop
     ```

  1. サーバーが予期せず再起動した場合にGitLabが再度起動するのを防ぎます:

     ```shell
     sudo systemctl disable gitlab-runsvdir
     ```

- プライマリGeoサイトへのSSHアクセスがない場合は、利用可能なあらゆる手段でマシンをオフラインにし、再起動しないようにします。次のような作業が必要になる場合があります:

  - ロードバランサーを再設定します。
  - DNSレコードを変更します（例: プライマリDNSレコードをセカンダリGeoサイトにポイントして、プライマリGeoサイトの使用を停止します）。
  - 仮想サーバーを停止します。
  - ファイアウォールを介してトラフィックをブロックします。
  - プライマリGeoサイトからオブジェクトストレージの権限を失効します。
  - マシンを物理的に切断します。

  [プライマリドメインDNSレコードを更新](#optional-updating-the-primary-domain-dns-record)する場合は、DNS変更の高速な伝播を確実にするために、低いTTLを維持することをお勧めします。

  > [!note]
  > プライマリGeoサイトの`/etc/gitlab/gitlab.rb`ファイルは、このプロセス中にセカンダリGeoサイトに自動的にコピーされません。プライマリの`/etc/gitlab/gitlab.rb`ファイルをバックアップして、後でセカンダリGeoサイトで必要な値を復元できるようにしてください。

### ステップ2.セカンダリGeoサイトのプロモート {#step-2-promoting-a-secondary-site}

セカンダリをプロモートする際に、次の点に注意してください:

- セカンダリGeoサイトが[一時停止されている](../replication/pause_resume_replication.md)場合、プロモートは最後に既知の状態へのポイントインタイムリカバリーを実行します。セカンダリが一時停止中にプライマリで作成されたデータは失われます。
- セカンダリGeoサイトが[一時停止されている](../replication/pause_resume_replication.md)状態で、このプロセス中に`ActiveRecord::StatementInvalid: PG::ReadOnlySqlTransaction: ERROR:  cannot execute DELETE in a read-only transaction`エラーメッセージが発生した場合は、このナレッジベースドキュメントを参照してください: [予期しないプライマリ停止後のGeoプロモートの失敗（読み取り専用トランザクションエラーまたはタイムアウト）](https://support.gitlab.com/hc/en-us/articles/21019042667804-Geo-promotion-fails-with-read-only-transaction-error-or-timeout-after-unexpected-primary-shutdown)。
- 現時点では、新しいセカンダリを追加しないでください。新しいセカンダリを追加したい場合は、セカンダリをプライマリにプロモートするプロセス全体を完了した後に行います。
- このプロセス中に`ActiveRecord::RecordInvalid: Validation failed: Name has already been taken`エラーメッセージが発生した場合は、詳細についてこの[トラブルシューティングアドバイス](failover_troubleshooting.md#fixing-errors-during-a-failover-or-when-promoting-a-secondary-to-a-primary-site)を参照してください。
- 個別のURLを使用している場合は、[プライマリドメインDNSを新しくプロモートされたサイトにポイント](#optional-updating-the-primary-domain-dns-record)する必要があります。そうしないと、Runnerを新しくプロモートされたサイトに再登録する必要があり、すべてのGitリモート、ブックマーク、および外部インテグレーションを更新する必要があります。
- [ロケーション認識DNS](../secondary_proxy/_index.md#configure-location-aware-dns)を使用している場合、古いプライマリがDNSエントリから削除されると、Runnerは自動的に新しいプライマリに接続します。
- プライマリGeoサイトがダウンした後、セカンダリで`gitlab-ctl promotion-preflight-checks`を実行してGeo同期ステータスを確認し、最終検証チェックを実行します。
- 以前のプライマリに接続されていたRunnerが戻ってこないと予想される場合は、それらを削除する必要があります:
  - UIを使用する場合は、以下のとおりです:
    1. 右上隅で、**管理者**を選択します。
    1. **CI/CD** > **Runners**を選択して削除します。
  - [Runner API](../../../api/runners.md)を使用します。

#### 単一ノードで実行されているセカンダリGeoサイトのプロモート {#promoting-a-secondary-site-running-on-a-single-node}

1. セカンダリGeoサイトにSSHで接続し、実行します:

   - セカンダリGeoサイトをプライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - セカンダリGeoサイトをプライマリに**without any further confirmation**プロモートするには:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. 以前セカンダリGeoサイトに使用されていたURLを使用して、新しくプロモートされたプライマリGeoサイトに接続できることを確認します。
1. 成功した場合、セカンダリGeoサイトはプライマリGeoサイトにプロモートされました。

`gitlab-ctl geo promote`を実行すると、[`gitlab-cluster.json`](#the-gitlab-clusterjson-file)ファイルがノードに作成されます。このファイルは、再設定時に`gitlab.rb`内のGeoロール設定を上書きします。

### ステップ3.以前のセカンダリの追跡データベースを削除する {#step-3-removing-the-former-secondarys-tracking-database}

`/etc/gitlab/gitlab.rb`ファイルで`geo_secondary[]`設定オプションが有効になっている場合は、それらをコメントアウトまたは削除し、変更を有効にするために[GitLabを再設定](../../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

この時点で、プロモートされたサイトが新しいプライマリGitLabGeoサイトです。オプションで、新しいセカンダリGeoサイトとしてGeoを再度設定したい場合は、[古いサイトをセカンダリとして戻す](bring_primary_back.md#configure-the-former-primary-site-to-be-a-secondary-site)ことができます。

### マルチノードと単一ノードセカンダリGeoサイトを持つセカンダリGeoサイトのプロモート {#promoting-a-secondary-site-with-multiple-nodes-and-a-single-secondary-site}

1. セカンダリGeoサイトのすべてのSidekiq、PostgreSQL、およびGitalyノードにSSHで接続し、次のいずれかのコマンドを実行します:

   - セカンダリGeoサイトのノードをプライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - セカンダリGeoサイトをプライマリに**without any further confirmation**プロモートするには:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. セカンダリGeoサイトの各RailsノードにSSHで接続し、次のいずれかのコマンドを実行します:

   - セカンダリGeoサイトをプライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - セカンダリGeoサイトをプライマリに**without any further confirmation**プロモートするには:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. 以前セカンダリGeoサイトに使用されていたURLを使用して、新しくプロモートされたプライマリGeoサイトに接続できることを確認します。
1. 成功した場合、セカンダリGeoサイトはプライマリGeoサイトにプロモートされました。

`gitlab-ctl geo promote`を実行すると、[`gitlab-cluster.json`](#the-gitlab-clusterjson-file)ファイルがノードに作成されます。このファイルは、再設定時に`gitlab.rb`内のGeoロール設定を上書きします。

#### Patroniスタンバイクラスターを持つセカンダリGeoサイトのプロモート {#promoting-a-secondary-site-with-a-patroni-standby-cluster}

1. セカンダリGeoサイトのすべてのSidekiq、PostgreSQL、およびGitalyノードにSSHで接続し、次のいずれかのコマンドを実行します:

   - セカンダリGeoサイトをプライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - セカンダリGeoサイトをプライマリに**without any further confirmation**プロモートするには:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. セカンダリGeoサイトの各RailsノードにSSHで接続し、次のいずれかのコマンドを実行します:

   - セカンダリGeoサイトをプライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - セカンダリGeoサイトをプライマリに**without any further confirmation**プロモートするには:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. 以前セカンダリGeoサイトに使用されていたURLを使用して、新しくプロモートされたプライマリGeoサイトに接続できることを確認します。
1. 成功した場合、セカンダリGeoサイトはプライマリGeoサイトにプロモートされました。

#### 外部PostgreSQLデータベースを持つセカンダリGeoサイトのプロモート {#promoting-a-secondary-site-with-an-external-postgresql-database}

`gitlab-ctl geo promote`コマンドは、外部PostgreSQLデータベースと組み合わせて使用できます。この場合、まずセカンダリGeoサイトに関連付けられたレプリカデータベースを手動でプロモートする必要があります:

1. セカンダリGeoサイトに関連付けられたレプリカデータベースをプロモートします。これにより、データベースが読み書き可能に設定されます。手順は、データベースがホストされている場所によって異なります:
   - [Amazon RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html#USER_ReadRepl.Promote)
   - [Azure PostgreSQL](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-read-replicas-portal#stop-replication)
   - [Google Cloud SQL](https://cloud.google.com/sql/docs/mysql/replication/manage-replicas#promote-replica)
   - 他の外部PostgreSQLデータベースの場合は、セカンダリGeoサイトに次のスクリプトを保存します（例: `/tmp/geo_promote.sh`）。そして、環境に合わせて接続パラメータを修正します。次に、それを実行してレプリカをプロモートします:

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

1. セカンダリGeoサイトのすべてのSidekiq、PostgreSQL、およびGitalyノードにSSHで接続し、次のいずれかのコマンドを実行します:

   - セカンダリGeoサイトをプライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - セカンダリGeoサイトをプライマリに**without any further confirmation**プロモートするには:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. セカンダリGeoサイトの各RailsノードにSSHで接続し、次のいずれかのコマンドを実行します:

   - セカンダリGeoサイトをプライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - セカンダリGeoサイトをプライマリに**without any further confirmation**プロモートするには:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. 以前セカンダリGeoサイトに使用されていたURLを使用して、新しくプロモートされたプライマリGeoサイトに接続できることを確認します。
1. 成功した場合、セカンダリGeoサイトはプライマリGeoサイトにプロモートされました。

### （オプション）プライマリドメインDNSレコードの更新 {#optional-updating-the-primary-domain-dns-record}

プライマリドメインのDNSレコードを更新して、セカンダリGeoサイトをポイントするようにします。これにより、GitリモートやAPI URLの変更など、プライマリドメインへのすべての参照を更新する必要がなくなります。

1. セカンダリGeoサイトにSSHで接続し、rootでログインします:

   ```shell
   sudo -i
   ```

1. プライマリドメインのDNSレコードを更新します。プライマリドメインのDNSレコードを更新してセカンダリGeoサイトをポイントするようにした後、セカンダリGeoサイトの`/etc/gitlab/gitlab.rb`を編集して新しいURLを反映させます:

   ```ruby
   # Change the existing external_url configuration
   external_url 'https://<new_external_url>'
   ```

   > [!note]
   > `external_url`を変更しても、セカンダリDNSレコードがそのまま残っている限り、古いセカンダリURLからのアクセスは妨げられません。

1. セカンダリのSSL証明書を更新します:

   - [Let's Encryptインテグレーション](https://docs.gitlab.com/omnibus/settings/ssl/#enable-the-lets-encrypt-integration)を使用している場合、証明書は自動的に更新されます。
   - [手動で設定](https://docs.gitlab.com/omnibus/settings/ssl/#configure-https-manually)した場合は、セカンダリの証明書をプライマリからセカンダリにコピーします。プライマリにアクセスできない場合は、新しい証明書を発行し、主体の別名にプライマリとセカンダリの両方のURLが含まれていることを確認してください。次で確認できます:

     ```shell
     /opt/gitlab/embedded/bin/openssl x509 -noout -dates -subject -issuer \
         -nameopt multiline -ext subjectAltName -in /etc/gitlab/ssl/new-gitlab.new-example.com.crt
     ```

1. セカンダリGeoサイトを再設定して、変更を有効にします:

   ```shell
   gitlab-ctl reconfigure
   ```

1. 新しくプロモートされたプライマリGeoサイトURLを更新するために、以下のコマンドを実行します:

   ```shell
   gitlab-rake gitlab:geo:update_primary_node_url
   ```

   このコマンドは、`/etc/gitlab/gitlab.rb`で定義されている`external_url`の変更された設定を使用します。

1. 新しくプロモートされたプライマリに、そのURLを使用して接続できることを確認します。プライマリドメインのDNSレコードを更新した場合、以前のDNSレコードのTTLによっては、これらの変更がまだ伝播されていない可能性があります。

### （オプション）プロモートされたプライマリGeoサイトにセカンダリGeoサイトを追加する {#optional-add-secondary-geo-site-to-a-promoted-primary-site}

新しいセカンダリGeoサイトをオンラインにするには、[Geo設定手順](../setup/_index.md)に従ってください。

## マルチノード設定におけるセカンダリGeoレプリカのプロモート {#promoting-secondary-geo-replica-in-multi-secondary-configurations}

セカンダリGeoサイトが複数あり、そのうちの1つをプロモートする必要がある場合は、[単一ノード設定におけるセカンダリGeoサイトのプロモート](#promoting-a-secondary-geo-site-in-single-secondary-configurations)に従うことをお勧めします。その後、さらに2つのステップが必要です。

### ステップ1.1つ以上のセカンダリGeoサイトにサービスを提供するように新しいプライマリGeoサイトを準備する {#step-1-prepare-the-new-primary-site-to-serve-one-or-more-secondary-sites}

1. 新しいプライマリGeoサイトにSSHで接続し、rootでログインします:

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

1. ファイルを保存し、データベースのリッスン変更とレプリケーションスロットの変更を適用するためにGitLabを再構成します:

   ```shell
   gitlab-ctl reconfigure
   ```

   変更を有効にするため、PostgreSQLを再起動します:

   ```shell
   gitlab-ctl restart postgresql
   ```

1. PostgreSQLが再起動され、プライベートアドレスでリッスンしているため、移行を再度有効にします。

   `/etc/gitlab/gitlab.rb`を編集し、構成を`true`に**変更**します:

   ```ruby
   gitlab_rails['auto_migrate'] = true
   ```

   ファイルを保存し、GitLabを再設定します:

   ```shell
   gitlab-ctl reconfigure
   ```

### ステップ2.レプリケーションプロセスを開始する {#step-2-initiate-the-replication-process}

次に、各セカンダリGeoサイトに新しいプライマリGeoサイトの変更をリッスンさせる必要があります。そのためには、[レプリケーションプロセス](../setup/database.md#step-3-initiate-the-replication-process)を再度開始する必要がありますが、今回は別のプライマリGeoサイトに対してです。古いレプリケーション設定はすべて上書きされます。

既存のセカンダリGeoサイトにはすべて入力されたデータベースがあるため、次のようなメッセージが表示される場合があります:

```shell
Found data inside the gitlabhq_production database! If you are sure you are in the secondary server, override with --force
```

適切なセカンダリGeoサイトであることを確認したら、`--force`でレプリケーションを開始します。

> [!warning]
> `--force`を使用すると、**all existing data in the database on that secondary server to be deleted**。

## GitLab HelmチャートにおけるセカンダリGeoクラスターのプロモート {#promoting-a-secondary-geo-cluster-in-the-gitlab-helm-chart}

クラウドネイティブGeoデプロイを更新する場合、セカンダリKubernetesクラスターの外部にあるノードを更新するプロセスは、非クラウドネイティブのアプローチと変わりありません。そのため、詳細についてはいつでも[単一ノード設定におけるセカンダリGeoサイトのプロモート](#promoting-a-secondary-geo-site-in-single-secondary-configurations)を参照してください。

以下のセクションでは、`gitlab`ネームスペースを使用していることを前提としています。クラスターの設定時に別のネームスペースを使用した場合は、`--namespace gitlab`を独自のネームスペースに置き換える必要があります。

### ステップ1.プライマリクラスターを永続的に無効にする {#step-1-permanently-disable-the-primary-cluster}

> [!warning]
> プライマリGeoサイトがオフラインになった場合、プライマリGeoサイトに保存されているデータがセカンダリGeoサイトにレプリケートされていない可能性があります。続行すると、このデータは失われたものとして扱われます。

プライマリGeoサイトで停止が発生した場合、2つの異なるGitLabインスタンスで書き込みが発生するスプリットブレイン状態を回避するために可能な限りのことを行う必要があります。これはリカバリー作業を複雑にします。したがって、フェイルオーバーの準備として、プライマリGeoサイトを無効にする必要があります:

- プライマリKubernetesクラスターにアクセスできる場合は、それに接続し、GitLab `webservice`および`Sidekiq`ポッドを無効にします:

  ```shell
  kubectl --namespace gitlab scale deploy gitlab-geo-webservice-default --replicas=0
  kubectl --namespace gitlab scale deploy gitlab-geo-sidekiq-all-in-1-v1 --replicas=0
  ```

- プライマリKubernetesクラスターにアクセスできない場合は、クラスターをオフラインにし、利用可能なあらゆる手段で再起動しないようにします。次のような作業が必要になる場合があります:

  - ロードバランサーを再設定します。
  - DNSレコードを変更します（例: プライマリDNSレコードをセカンダリGeoサイトにポイントして、プライマリGeoサイトの使用を停止します）。
  - 仮想サーバーを停止します。
  - ファイアウォールを介してトラフィックをブロックします。
  - プライマリGeoサイトからオブジェクトストレージの権限を失効します。
  - マシンを物理的に切断します。

### ステップ2.クラスターの外部にあるすべてのセカンダリGeoサイトノードをプロモート {#step-2-promote-all-secondary-site-nodes-external-to-the-cluster}

> [!warning]
> セカンダリGeoサイトが[一時停止されている](../_index.md#pausing-and-resuming-replication)場合、これは最後に既知の状態へのポイントインタイムリカバリーを実行します。セカンダリが一時停止中にプライマリで作成されたデータは失われます。

1. Linuxパッケージを使用しているセカンダリKubernetesクラスターの外部にある各ノード（PostgreSQLまたはGitalyなど）にSSHで接続し、次のいずれかのコマンドを実行します:

   - セカンダリKubernetesクラスターの外部にあるセカンダリGeoサイトノードをプライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - セカンダリKubernetesクラスターの外部にあるセカンダリGeoサイトノードをプライマリに**without any further confirmation**プロモートするには:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. `toolbox`ポッドを見つけます:

   ```shell
   kubectl --namespace gitlab get pods -lapp=toolbox
   ```

1. セカンダリをプロモートします:

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- gitlab-rake gitlab:geo:set_secondary_as_primary
   ```

   タスクの動作を変更するために環境変数を指定できます。利用可能な変数は次のとおりです:

   | 名前 | デフォルト値 | 説明 |
   | ---- | ------------- | ------- |
   | `ENABLE_SILENT_MODE` | `false`  | `true`の場合、プロモート前に[サイレントモード](../../silent_mode/_index.md)を有効にします |

### ステップ3.セカンダリクラスターをプロモート {#step-3-promote-the-secondary-cluster}

1. 既存のクラスター設定を更新します。

   Helmで既存の設定を取得できます:

   ```shell
   helm --namespace gitlab get values gitlab-geo > gitlab.yaml
   ```

   既存の設定には、次のようなGeoセクションが含まれています:

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

   セカンダリクラスターをプライマリクラスターにプロモートするには、`role: secondary`を`role: primary`に更新します。

   クラスターがプライマリGeoサイトとして残る場合、`geo`の下の`psql`セクション全体を削除する必要があります。これは追跡データベースを参照します。そのままにしておくと、アプリケーションは起動時にノードをセカンダリとして識別し、統合URLで新しいセカンダリが追加されたときに認証を妨げるルート登録の問題を引き起こします。

   新しい設定でクラスターを更新します:

   ```shell
   helm upgrade --install --version <current Chart version> gitlab-geo gitlab/gitlab --namespace gitlab -f gitlab.yaml
   ```

1. 以前セカンダリに使用されていたURLを使用して、新しくプロモートされたプライマリに接続できることを確認します。
1. 成功しました！セカンダリがプライマリにプロモートされました。

### ステップ4.（オプション）OpenBao HAクラスターをプロモート {#step-4-optional-promote-the-openbao-ha-cluster}

GitLab Secrets Managerが有効になっている場合、Kubernetesクラスターをプロモートした後、OpenBao高可用性（HA）クラスターをプロモートするには、以下の手順を実行します。

#### OpenBaoポッドを再起動する {#restart-openbao-pods}

PostgreSQLレプリカがプライマリにプロモートされた後、OpenBaoポッドを再起動して、書き込み可能になったデータベースに再接続させます:

```shell
kubectl --namespace gitlab rollout restart deployment -l app=openbao
```

#### JWT認証を設定する {#configure-jwt-authentication}

プライマリドメインがプロモートされたセカンダリGeoサイトをポイントするようにDNSレコードを更新します。OpenBaoは、異なるドメインを使用するセカンダリGeoサイトへのフェイルオーバーをサポートしていません。詳細については、[Geoデプロイ](../../secrets_manager/_index.md#geo-deployment)を参照してください。

#### 必要に応じて開封シークレットを復元する {#restore-the-unseal-secret-if-needed}

セカンダリクラスターの開封キーは、プライマリキーと同じである必要があります。そうでない場合、OpenBaoはセカンダリのVaultを開封できません。

不一致がある場合は、`gitlab-openbao-unseal`シークレットをセカンダリクラスターに[バックアップ](https://docs.gitlab.com/charts/backup-restore/backup/#back-up-the-secrets)から復元し、OpenBaoポッドを再起動します:

```shell
kubectl --namespace gitlab rollout restart deployment -l app=openbao
```

#### OpenBaoが機能することを確認する {#verify-openbao-is-functional}

1. すべてのOpenBaoポッドが実行されていることを確認します:

   ```shell
   kubectl --namespace gitlab get pods -l app=openbao
   ```

1. [シークレットマネージャー変数](../../../ci/secrets/secrets_manager/_index.md)を使用するCIパイプラインを実行して、OpenBaoインテグレーションをテストします。

## トラブルシューティング {#troubleshooting}

このセクションは[別の場所](failover_troubleshooting.md#fixing-errors-during-a-failover-or-when-promoting-a-secondary-to-a-primary-site)に移動されました。
