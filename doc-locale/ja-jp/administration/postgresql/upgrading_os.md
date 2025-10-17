---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: PostgreSQL用のオペレーティングシステムをアップグレードする
---

{{< alert type="warning" >}}

[Geo](../geo/_index.md)を使用して、あるオペレーティングシステムから別のオペレーティングシステムにPostgreSQLデータベースを移行することはできません。そのような移行を試みると、セカンダリサイトが100％レプリケートされているように見えても、実際には一部のデータがレプリケートされておらず、データ損失につながる可能性があります。これは、GeoがPostgreSQLストリーミングレプリケーションに依存しており、PostgreSQLストリーミングレプリケーションは、このドキュメントで説明されている制限の影響を受けるためです。[Geoのトラブルシューティング - OSロケールデータの互換性を確認する](../geo/replication/troubleshooting/common.md#check-os-locale-data-compatibility)も参照してください。

{{< /alert >}}

PostgreSQLが動作しているオペレーティングシステムをアップグレードした場合、[ロケールデータの変更により、データベースインデックスが破損する可能性](https://wiki.postgresql.org/wiki/Locale_data_changes)があります。特に、`glibc` 2.28へのアップグレードでは、この問題が発生しやすくなります。この問題を回避するには、次のいずれかの方法で移行してください（おおよその複雑さの低い順に並んでいます）。

- （推奨）[バックアップと復元](#backup-and-restore)。
- （推奨）[すべてのインデックスを再構築する](#rebuild-all-indexes)。
- [影響を受けたインデックスのみを再構築する](#rebuild-only-affected-indexes)。

移行を試みる前に必ずバックアップを取得し、本番環境に近い環境で移行プロセスを検証してください。ダウンタイムの長さが問題になりそうな場合は、本番環境に近い環境で本番データのコピーを使用し、各移行方法の所要時間を検討することをおすすめします。

スケールアウトされたGitLab環境を実行しており、PostgreSQLを実行しているノードで他のサービスを実行していない場合は、PostgreSQLノードのオペレーティングシステムのみをアップグレードすることをおすすめします。複雑さとリスクを軽減するために、特にダウンタイムを必要としない変更（PumaやSidekiqのみを実行しているノードのオペレーティングシステムのアップグレードなど）と同時にこの手順を行うのは避けてください。

GitLabが計画しているこの問題への対処方法の詳細については、[エピック8573](https://gitlab.com/groups/gitlab-org/-/epics/8573)を参照してください。

## バックアップと復元 {#backup-and-restore}

バックアップと復元は、インデックスを含むデータベース全体を再作成します。

1. 計画的なダウンタイムを確保します。すべてのノードで、不要なGitLabサービスを停止します。

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. `pg_dump`またはGitLabのバックアップツールを使用して、PostgreSQLデータベースをバックアップします。このとき、[`db`を除くすべてのデータタイプを除外](../backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup)します（データベースのみをバックアップします）。
1. すべてのPostgreSQLノードで、OSをアップグレードします。
1. すべてのPostgreSQLノードで、[OSのアップグレード後にGitLabのパッケージソースを更新](../../update/package/_index.md#upgrade-the-operating-system-optional)します。
1. すべてのPostgreSQLノードに、同じGitLabバージョンの新しいGitLabパッケージをインストールします。
1. バックアップからPostgreSQLデータベースを復元します。
1. すべてのノードでGitLabを起動します。

利点:

- 簡単に実行できます。
- データベースにおけるインデックスやテーブルの肥大化を解消し、ディスク使用量を削減できます。

欠点:

- データベースのサイズが大きくなるほどダウンタイムが長くなり、いずれ問題になる可能性があります。所要時間は多くの要因に左右されますが、データベースが100 GBを超える場合は、24時間程度かかることがあります。

### Geoセカンダリサイトを含む環境でのバックアップと復元 {#backup-and-restore-with-geo-secondary-sites}

1. 計画的なダウンタイムを確保します。すべてのサイトのすべてのノードで、不要なGitLabサービスを停止します。

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. プライマリサイトで、`pg_dump`またはGitLabのバックアップツールを使用して、PostgreSQLデータベースをバックアップします。このとき、[`db`を除くすべてのデータタイプを除外](../backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup)します（データベースのみをバックアップします）。
1. すべてのサイトのすべてのPostgreSQLノードで、OSをアップグレードします。
1. すべてのサイトのすべてのPostgreSQLノードで、[OSのアップグレード後にGitLabのパッケージソースを更新](../../update/package/_index.md#upgrade-the-operating-system-optional)します。
1. すべてのサイトのすべてのPostgreSQLノードに、同じGitLabバージョンの新しいGitLabパッケージをインストールします。
1. プライマリサイトで、バックアップからPostgreSQLデータベースを復元します。
1. 必要に応じて、セカンダリサイトをウォームスタンバイとして利用できなくなるリスクを踏まえた上で、プライマリサイトの使用を開始します。
1. セカンダリサイトに対してPostgreSQLストリーミングレプリケーションを再度セットアップします。
1. セカンダリサイトがユーザーからのトラフィックを受信する場合は、GitLabを起動する前に、リードレプリカデータベースの同期が完了するのを待機してください。
1. すべてのサイトのすべてのノードで、GitLabを起動します。

## すべてのインデックスを再構築する {#rebuild-all-indexes}

[すべてのインデックスを再構築する](https://www.postgresql.org/docs/16/sql-reindex.html)。

1. 計画的なダウンタイムを確保します。すべてのノードで、不要なGitLabサービスを停止します。

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. すべてのPostgreSQLノードで、OSをアップグレードします。
1. すべてのPostgreSQLノードで、[OSのアップグレード後にGitLabのパッケージソースを更新](../../update/package/_index.md#upgrade-the-operating-system-optional)します。
1. すべてのPostgreSQLノードに、同じGitLabバージョンの新しいGitLabパッケージをインストールします。
1. [データベースコンソール](../troubleshooting/postgresql.md#start-a-database-console)で、すべてのインデックスを再構築します。

   ```sql
   SET statement_timeout = 0;
   REINDEX DATABASE gitlabhq_production;
   ```

1. データベースのインデックスを再構築した後は、影響を受けたすべての照合順序についてバージョンを更新する必要があります。現在の照合順序バージョンを記録するようにシステムカタログを更新するには、次の手順に従います。

   ```sql
   ALTER DATABASE gitlabhq_production REFRESH COLLATION VERSION;
   ```

1. すべてのノードでGitLabを起動します。

利点:

- 簡単に実行できます。
- さまざまな要因次第で、バックアップと復元よりも高速な場合があります。
- データベースにおけるインデックスの肥大化を解消し、ディスク使用量を削減できます。

欠点:

- データベースのサイズが大きくなるほどダウンタイムが長くなり、いずれ問題になる可能性があります。

### Geoセカンダリサイトを含む環境ですべてのインデックスを再構築する {#rebuild-all-indexes-with-geo-secondary-sites}

1. 計画的なダウンタイムを確保します。すべてのサイトのすべてのノードで、不要なGitLabサービスを停止します。

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. すべてのPostgreSQLノードで、OSをアップグレードします。
1. すべてのPostgreSQLノードで、[OSのアップグレード後にGitLabのパッケージソースを更新](../../update/package/_index.md#upgrade-the-operating-system-optional)します。
1. すべてのPostgreSQLノードに、同じGitLabバージョンの新しいGitLabパッケージをインストールします。
1. プライマリサイトの[データベースコンソール](../troubleshooting/postgresql.md#start-a-database-console)で、すべてのインデックスを再構築します。

   ```sql
   SET statement_timeout = 0;
   REINDEX DATABASE gitlabhq_production;
   ```

1. データベースのインデックスを再構築した後は、影響を受けたすべての照合順序についてバージョンを更新する必要があります。現在の照合順序バージョンを記録するようにシステムカタログを更新するには、次の手順に従います。

   ```sql
   ALTER DATABASE <database_name> REFRESH COLLATION VERSION;
   ```

1. セカンダリサイトがユーザーからのトラフィックを受信する場合は、GitLabを起動する前に、リードレプリカデータベースの同期が完了するのを待機してください。
1. すべてのサイトのすべてのノードで、GitLabを起動します。

## 影響を受けたインデックスのみを再構築する {#rebuild-only-affected-indexes}

これは、GitLab.comで採用されているアプローチと似ています。このプロセスの詳細や、さまざまなインデックスがどのように扱われたかについては、[PostgreSQLデータベースクラスターにおいてオペレーティングシステムをアップグレード](https://about.gitlab.com/blog/2022/08/12/upgrading-database-os/)した際のブログ記事を参照してください。

1. 計画的なダウンタイムを確保します。すべてのノードで、不要なGitLabサービスを停止します。

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. すべてのPostgreSQLノードで、OSをアップグレードします。
1. すべてのPostgreSQLノードで、[OSのアップグレード後にGitLabのパッケージソースを更新](../../update/package/_index.md#upgrade-the-operating-system-optional)します。
1. すべてのPostgreSQLノードに、同じGitLabバージョンの新しいGitLabパッケージをインストールします。
1. [影響を受けたインデックスを特定](https://wiki.postgresql.org/wiki/Locale_data_changes#What_indexes_are_affected)します。
1. [データベースコンソール](../troubleshooting/postgresql.md#start-a-database-console)で、影響を受けた各インデックスを再構築します。

   ```sql
   SET statement_timeout = 0;
   REINDEX INDEX <index name> CONCURRENTLY;
   ```

1. 不正なインデックスを再構築した後は、照合順序を更新する必要があります。現在の照合順序バージョンを記録するようにシステムカタログを更新するには、次の手順に従います。

   ```sql
   ALTER DATABASE <database_name> REFRESH COLLATION VERSION;
   ```

1. すべてのノードでGitLabを起動します。

利点:

- 影響を受けていないインデックスの再構築にダウンタイムを費やす必要がありません。

欠点:

- ミスが発生する可能性が高くなります。
- 移行中に発生した予期しない問題に対応するには、PostgreSQLの専門知識が求められます。
- データベースの肥大化がそのまま残ります。

### Geoセカンダリサイトを含む環境で影響を受けたインデックスのみを再構築する {#rebuild-only-affected-indexes-with-geo-secondary-sites}

1. 計画的なダウンタイムを確保します。すべてのサイトのすべてのノードで、不要なGitLabサービスを停止します。

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. すべてのPostgreSQLノードで、OSをアップグレードします。
1. すべてのPostgreSQLノードで、[OSのアップグレード後にGitLabのパッケージソースを更新](../../update/package/_index.md#upgrade-the-operating-system-optional)します。
1. すべてのPostgreSQLノードに、同じGitLabバージョンの新しいGitLabパッケージをインストールします。
1. [影響を受けたインデックスを特定](https://wiki.postgresql.org/wiki/Locale_data_changes#What_indexes_are_affected)します。
1. プライマリサイトの[データベースコンソール](../troubleshooting/postgresql.md#start-a-database-console)で、影響を受けた各インデックスを再構築します。

   ```sql
   SET statement_timeout = 0;
   REINDEX INDEX <index name> CONCURRENTLY;
   ```

1. 不正なインデックスを再構築した後は、照合順序を更新する必要があります。現在の照合順序バージョンを記録するようにシステムカタログを更新するには、次の手順に従います。

   ```sql
   ALTER DATABASE <database_name> REFRESH COLLATION VERSION;
   ```

1. 既存のPostgreSQLストリーミングレプリケーションが、再構築されたインデックスの変更をリードレプリカデータベースにレプリケートするはずです。
1. すべてのサイトのすべてのノードで、GitLabを起動します。

## `glibc`のバージョンを確認する {#checking-glibc-versions}

使用されている`glibc`のバージョンを確認するには、`ldd --version`を実行します。

次の表に、さまざまなオペレーティングシステムに同梱されている`glibc`のバージョンを示します。

| オペレーティングシステム    | `glibc`のバージョン |
|---------------------|-----------------|
| CentOS 7            | 2.17            |
| RedHat Enterprise 8 | 2.28            |
| RedHat Enterprise 9 | 2.34            |
| Ubuntu 18.04        | 2.27            |
| Ubuntu 20.04        | 2.31            |
| Ubuntu 22.04        | 2.35            |
| Ubuntu 24.04        | 2.39            |

たとえば、CentOS 7からRedHat Enterprise 8にアップグレードするとします。この場合、`glibc`が2.17から2.28にアップグレードされるため、アップグレード後のオペレーティングシステムでPostgreSQLを使用するには、前述の2つのアプローチのいずれかを使用する必要があります。照合順序の変更を適切に処理しないと、Runnerがタグ付きのジョブを取得できなくなるなど、GitLabで重大なエラーが発生します。

一方、PostgreSQLがすでに`glibc` 2.28以上の環境で問題なく動作している場合は、特に対応を行わなくてもインデックスは引き続き正常に機能するはずです。たとえば、PostgreSQLをRedHat Enterprise 8（`glibc` 2.28）でしばらく実行しており、RedHat Enterprise 9（`glibc` 2.34）にアップグレードする場合、照合順序に関する問題は発生しないと考えられます。

### `glibc`の照合順序バージョンを確認する {#verifying-glibc-collation-versions}

PostgreSQL 13以降では、次のSQLクエリを使用して、データベースの照合順序バージョンがシステムと一致することを確認できます。

```sql
SELECT collname AS COLLATION_NAME,
       collversion AS VERSION,
       pg_collation_actual_version(oid) AS actual_version
FROM pg_collation
WHERE collprovider = 'c';
```

### 照合順序が一致している例 {#matching-collation-example}

たとえば、Ubuntu 22.04システムでは、適切にインデックスが作成されたシステムの出力は次のようになります。

```sql
gitlabhq_production=# SELECT collname AS COLLATION_NAME,
       collversion AS VERSION,
       pg_collation_actual_version(oid) AS actual_version
FROM pg_collation
WHERE collprovider = 'c';
 collation_name | version | actual_version
----------------+---------+----------------
 C              |         |
 POSIX          |         |
 ucs_basic      |         |
 C.utf8         |         |
 en_US.utf8     | 2.35    | 2.35
 en_US          | 2.35    | 2.35
(6 rows)
```

### 照合順序が一致しない例 {#mismatched-collation-example}

一方、Ubuntu 18.04から22.04にアップグレードした際にインデックスを再構築していない場合、次のように出力されることがあります。

```sql
gitlabhq_production=# SELECT collname AS COLLATION_NAME,
       collversion AS VERSION,
       pg_collation_actual_version(oid) AS actual_version
FROM pg_collation
WHERE collprovider = 'c';
 collation_name | version | actual_version
----------------+---------+----------------
 C              |         |
 POSIX          |         |
 ucs_basic      |         |
 C.utf8         |         |
 en_US.utf8     | 2.27    | 2.35
 en_US          | 2.27    | 2.35
(6 rows)
```

## ストリーミングレプリケーション {#streaming-replication}

破損したインデックスの問題は、PostgreSQLストリーミングレプリケーションに影響を与えます。ロケールデータが異なるレプリカに対する読み取りを許可する前に、[すべてのインデックスを再構築](#rebuild-all-indexes)するか、[影響を受けたインデックスのみを再構築](#rebuild-only-affected-indexes)する必要があります。

## Geoのその他のバリエーション {#additional-geo-variations}

前述のアップグレード手順は固定されたものではありません。Geoでは冗長なインフラストラクチャが存在するため、もっと多くの選択肢がある可能性があります。ユースケースに合わせて手順を変更することもできますが、その場合は必ず、複雑さが増すことも考慮に入れたうえで比較検討を行ってください。次に例を示します。

プライマリサイトおよび他のセカンダリサイトのOSアップグレード中に障害が発生した場合に備えて、セカンダリサイトをウォームスタンバイとして確保するには、次の手順に従います。

1. セカンダリサイトのデータがプライマリサイトの変更によって影響を受けないように、セカンダリサイトを一時停止します。
1. プライマリサイトでOSアップグレードを実行します。
1. OSアップグレードが失敗し、プライマリサイトが回復不能になった場合は、セカンダリサイトをプロモートし、ユーザーをセカンダリサイトにルーティングして、後ほど再試行します。これにより、最新状態のセカンダリサイトがなくなります。

OSアップグレード中にユーザーにGitLabへの読み取り専用アクセスを提供するには（部分的なダウンタイム）、次の手順に従います。

1. プライマリサイトを停止する代わりに、[メンテナンスモード](../maintenance_mode/_index.md)を有効にします。
1. セカンダリサイトをプロモートします。ただし、まだユーザーをルーティングしないでください。
1. プロモートされたサイトでOSアップグレードを実行します。
1. 旧プライマリサイトではなく、プロモートされたサイトにユーザーをルーティングします。
1. 古いプライマリサイトを新たなセカンダリサイトとしてセットアップします。

{{< alert type="warning" >}}

セカンダリサイトにすでにデータベースのリードレプリカがある場合でも、プロモーションの前にそのオペレーティングシステムをアップグレードすることはできません。それを試みると、破損したインデックスが原因で、セカンダリサイトで一部のGitリポジトリやファイルのレプリケーションが失敗する可能性があります。[ストリーミングレプリケーション](#streaming-replication)を参照してください。

{{< /alert >}}
