---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 外部データベースのモニタリングとロギングのセットアップ
---

外部のPostgreSQLデータベースシステムには、パフォーマンスのモニタリングとトラブルシューティングのための様々なロギングオプションがありますが、これらはデフォルトでは有効になっていません。このセクションでは、セルフマネージドのPostgreSQLに関する推奨事項と、PostgreSQLマネージドサービスの主要プロバイダーに関する推奨事項を提供します。

## 推奨されるPostgreSQLロギング設定 {#recommended-postgresql-logging-settings}

次のロギング設定を有効にする必要があります:

- `log_statement=ddl`: データベースデータモデル定義（DDL）の変更をログに記録します。例えば、オブジェクトの`CREATE`、`ALTER`、または`DROP`などです。これは、パフォーマンスの問題を引き起こす可能性のある最近のモデル変更を追跡し、セキュリティ漏洩やヒューマンエラーを特定するのに役立ちます。
- `log_lock_waits=on`: 長時間[locks](https://www.postgresql.org/docs/16/explicit-locking.html)を保持しているプロセスをログに記録します。これは貧弱なクエリパフォーマンスの一般的な原因です。
- `log_temp_files=0`: パフォーマンスの低いクエリを示唆する可能性のある、集中的で異常な一時ファイルの使用状況をログに記録します。
- `log_autovacuum_min_duration=0`: すべてのautovacuum実行をログに記録します。Autovacuumは、PostgreSQLエンジンの全体的なパフォーマンスにとって重要なコンポーネントです。デッドタプルがテーブルから削除されていない場合のトラブルシューティングとチューニングに不可欠です。
- `log_min_duration_statement=1000`: 遅いクエリ（1秒より遅い）をログに記録します。

これらのパラメータ設定の完全な説明は、[PostgreSQLエラー報告とロギングドキュメント](https://www.postgresql.org/docs/16/runtime-config-logging.html#RUNTIME-CONFIG-LOGGING-WHAT)で確認できます。

## Amazon RDS {#amazon-rds}

Amazon Relational Database Service（RDS）は、多数の[モニタリングメトリクス](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Monitoring.html)と[ロギングインターフェース](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Monitor_Logs_Events.html)を提供します。設定すべきいくつかの項目を以下に示します:

- すべての[推奨PostgreSQLロギング設定](#recommended-postgresql-logging-settings)を[RDSパラメータグループ](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithDBInstanceParamGroups.html)を通じて変更します。
  - 推奨ロギングパラメータは[RDSで動的である](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.Parameters.html)ため、これらの設定を変更した後に再起動は不要です。
  - PostgreSQLのログは[RDSコンソール](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/logs-events-streams-console.html)から確認できます。
- [RDSパフォーマンスインサイト](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PerfInsights.html)を有効にすると、多くの重要なPostgreSQLデータベースエンジンのパフォーマンスメトリクスでデータベース負荷を視覚化できます。
- [RDS拡張モニタリング](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Monitoring.OS.html)を有効にして、オペレーティングシステムのメトリクスをモニタリングします。これらのメトリクスは、基盤となるハードウェアとOSのボトルネックを示し、データベースのパフォーマンスに影響を与えている可能性があります。
  - 本番環境では、多くのパフォーマンス問題の原因となりうるリソース使用量の微細なバーストを捕捉するために、モニタリング間隔を10秒以下に設定します。コンソールで`Granularity=10`を設定するか、CLIで`monitoring-interval=10`を設定します。
