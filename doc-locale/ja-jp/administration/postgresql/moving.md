---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabデータベースを別のPostgreSQLインスタンスに移行する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

データベースをPostgreSQLの別のインスタンスに移行する必要がある場合があります。たとえば、AWS Auroraを使用しており、データベースロードバランシングを有効にする準備をしている場合は、PostgreSQL用のRDSにデータベースを移行する必要があります。

データベースをあるインスタンスから別のインスタンスに移行するには、次の手順に従います:

1. ソースと宛先のPostgreSQLエンドポイント情報を収集します:

   ```shell
   SRC_PGHOST=<source postgresql host>
   SRC_PGUSER=<source postgresql user>

   DST_PGHOST=<destination postgresql host>
   DST_PGUSER=<destination postgresql user>
   ```

1. GitLabを停止します:

   ```shell
   sudo gitlab-ctl stop
   ```

1. ソースからデータベースをダンプします:

   ```shell
   /opt/gitlab/embedded/bin/pg_dump -h $SRC_PGHOST -U $SRC_PGUSER -c -C -f gitlabhq_production.sql gitlabhq_production
   /opt/gitlab/embedded/bin/pg_dump -h $SRC_PGHOST -U $SRC_PGUSER -c -C -f praefect_production.sql praefect_production
   ```

   {{< alert type="note" >}}

   まれに、`pg_dump`を実行して復元するした後、データベースのパフォーマンスの問題が発生することがあります。これは、`pg_dump`に[クエリ計画の決定を行うためにオプティマイザで使用される](https://www.postgresql.org/docs/16/app-pgdump.html)統計が含まれていないために発生する可能性があります。復元する後にパフォーマンスが低下する場合は、問題のあるクエリを見つけ、そのクエリで使用されているテーブルでANALYZEを実行して問題を修正してください。

   {{< /alert >}}

1. 宛先にデータベースを復元する （これにより、同じ名前の既存のデータベースが上書きされます）:

   ```shell
   /opt/gitlab/embedded/bin/psql -h $DST_PGHOST -U $DST_PGUSER -f praefect_production.sql postgres
   /opt/gitlab/embedded/bin/psql -h $DST_PGHOST -U $DST_PGUSER -f gitlabhq_production.sql postgres
   ```

1. オプション。PgBouncerを使用しないデータベースから使用するデータベースに移行する場合は、アプリケーションデータベース（通常は`gitlabhq_production`）に[`pg_shadow_lookup`関数](../gitaly/praefect/configure.md#manual-database-setup)を手動で追加する必要があります。
1. `/etc/gitlab/gitlab.rb`ファイル内の宛先PostgreSQLインスタンスの適切な接続の詳細でGitLabアプリケーションサーバーを構成します:

   ```ruby
   gitlab_rails['db_host'] = '<destination postgresql host>'
   ```

   GitLabマルチノード設定の詳細については、[参照アーキテクチャ](../reference_architectures/_index.md)を参照してください。

1. 変更を有効にするには、再構成を実行してください:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. GitLabを再起動します:

   ```shell
   sudo gitlab-ctl start
   ```
