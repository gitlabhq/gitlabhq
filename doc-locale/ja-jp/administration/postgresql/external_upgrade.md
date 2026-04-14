---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 外部のPostgreSQLデータベースをアップグレードする
---

PostgreSQLデータベースエンジンをアップグレードする際は、PostgreSQLコミュニティおよびクラウドプロバイダーが推奨するすべてのステップに従うことが重要です。PostgreSQLデータベースには2種類のアップグレードがあります:

- マイナーバージョンアップグレード: これらには、バグやセキュリティ修正のみが含まれます。これらは常に、既存のアプリケーションデータモデルと下位互換性があります。

  マイナーバージョンアップグレードプロセスは、PostgreSQLのバイナリを置き換えてデータベースサービスを再起動することで構成されます。データディレクトリは変更されません。

- メジャーバージョンアップグレード: これらは内部ストレージ形式とデータベースカタログを変更します。その結果、クエリオプティマイザーが使用するオブジェクト統計は[新しいバージョンに転送されない](https://www.postgresql.org/docs/16/pgupgrade.html)ため、`ANALYZE`を使用して再構築する必要があります。

  文書化されたメジャーバージョンアップグレードプロセスに従わないと、多くの場合、データベースパフォーマンスの低下やデータベースサーバーでの高いCPU使用率につながります。

すべての主要なクラウドプロバイダーは、`pg_upgrade`ユーティリティを使用して、データベースインスタンスのインプレースメジャーバージョンアップグレードをサポートしています。ただし、パフォーマンスの低下やデータベースの中断のリスクを減らすために、アップグレード前後の手順に従う必要があります。

外部データベースプラットフォームのメジャーバージョンアップグレード手順を注意深くお読みください:

- [Amazon RDS for PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.html#USER_UpgradeDBInstance.PostgreSQL.MajorVersion.Process)
- [Azure Database for PostgreSQL Flexible Server](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-major-version-upgrade)
- [Google Cloud SQL for PostgreSQL](https://cloud.google.com/sql/docs/postgres/upgrade-major-db-version-inplace)
- [PostgreSQL community `pg_upgrade`](https://www.postgresql.org/docs/16/pgupgrade.html)

## メジャーバージョンアップグレード後には、必ずデータベースを`ANALYZE`してください {#always-analyze-your-database-after-a-major-version-upgrade}

オプティマイザー統計は[`pg_upgrade`によって転送されない](https://www.postgresql.org/docs/16/pgupgrade.html)ため、メジャーバージョンアップグレード後に`pg_statistic`テーブルを更新するには、[`ANALYZE`操作](https://www.postgresql.org/docs/16/sql-analyze.html)を実行することが必須です。これは、アップグレードされたPostgreSQLサービス/インスタンス/クラスター上のすべてのデータベースに対して行う必要があります。

メンテナンス期間を計画する際には、この操作がGitLabのパフォーマンスを著しく低下させる可能性があるため、`ANALYZE`の時間を考慮に入れる必要があります。

`ANALYZE`操作を高速化するには、`njobs`個のコマンドを同時に実行することで、`ANALYZE`コマンドを並行して実行する`--analyze-only --jobs=njobs`オプションを付けて、[`vacuumdb`ユーティリティ](https://www.postgresql.org/docs/16/app-vacuumdb.html)を使用します。
