---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabコンポーネントにマネージドクラウドサービスを使用するためのガイダンス。
title: GitLabコンポーネントにクラウドサービスを使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

PostgreSQL、Redis/Valkey、およびオブジェクトストレージを自身で管理する代わりに、マネージドクラウドプロバイダーサービスを使用できます。

> [!note]
> GitLab Helmチャートを使用するクラウドネイティブデプロイの場合、外部のPostgreSQLおよびRedis/Valkeyサービスが必要です。これらのコンポーネントはバンドルされていません。

## マネージドクラウドPostgreSQLを使用する {#use-managed-cloud-postgresql}

[サポートされているバージョン](requirements.md#postgresql)を実行している外部PostgreSQLサービスを使用します。セットアップ手順については、[外部PostgreSQLデータベースの使用](../administration/postgresql/external.md)を参照してください。

完全なPostgreSQLデプロイのみがサポートされています。PostgreSQLワイヤプロトコルを実装しているが完全なPostgreSQLデプロイではないサービス（[Amazon Aurora](https://aws.amazon.com/rds/aurora/)や[Google AlloyDB](https://cloud.google.com/alloydb)など）は、GitLabと互換性がありません。

動作が確認されているサービスには以下が含まれます:

- [Google Cloud SQL](https://cloud.google.com/sql/docs/postgres/high-availability#normal)
- [Amazon RDS](https://aws.amazon.com/rds/)
- [Azure Database for PostgreSQL Flexible Server](https://azure.microsoft.com/en-gb/products/postgresql/)

### パフォーマンスと高可用性 {#performance-and-high-availability}

大規模な環境では、[データベースロードバランシング](../administration/postgresql/database_load_balancing.md)をリードレプリカと共に有効にします。レプリカの数を、同等のLinuxパッケージデプロイで使用されているものと一致させます。リードレプリカを使用する場合、すべてのレプリカノードに`hot_standby_feedback = on`が設定されていることを確認し、レプリケーションラグの蓄積を防ぎます。

大規模な環境のGCP Cloud SQLでは、最適なパフォーマンスを得るために[Enterprise Plusエディション](https://cloud.google.com/sql/docs/editions-intro)を使用してください。

> [!note]
> GCP Cloud SQLは、データベースフラグとしての`statement_timeout`をサポートしていません。代わりにデータベースまたはユーザーごとに設定してください: `ALTER DATABASE gitlab SET statement_timeout = '60s';`

### GitLab Geo {#gitlab-geo}

[GitLab Geo](../administration/geo/_index.md)には、プライマリサイトとセカンダリサイト間でのクロスリージョンPostgreSQLレプリケーションが必要です。すべてのマネージドデータベースサービスがこれをサポートしているわけではありません。

既知の制限事項:

- Amazon RDS Multi-AZ DBクラスター: クロスリージョンレプリケーションはサポートされていません。代わりに、クロスリージョンリードレプリカを備えた標準の[RDS Multi-AZ DBインスタンス](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZSingleStandby.html)を使用してください。
- GCP Cloud SQL: Geoのリードレプリカは、同じVPCおよび同じGCPプロジェクト内でのみ作成できます。異なるプロジェクトのセカンダリサイトの場合、Cloud SQLは直接レプリカを作成できません。[PostgreSQL論理レプリケーションを手動で設定](https://cloud.google.com/sql/docs/postgres/replication/configure-external-replica)し、その後に[GitLab Geo外部PostgreSQLセットアップ](../administration/geo/setup/external_database.md)に従ってください。

### コネクションプーリング {#connection-pooling}

ワークロードがPostgreSQLで直接処理される以上の追加のコネクションプーリングを必要とする場合は、独自のPgBouncerインスタンスをデプロイしてください。

> [!note]
> GitLabにバンドルされたPgBouncerは、バンドルされたPostgreSQLでのみ動作し、外部データベースサービスでは使用できません。

次のプロバイダーマネージドプーリングソリューションは推奨されません:

- AWS RDS Proxy: GitLabでの使用は検証されていません。
- Azure Database for PostgreSQL PgBouncer: シングルスレッドで限られた可観測性です。負荷がかかった状態ではボトルネックを引き起こす可能性があります。

## マネージドクラウドRedisおよびValkeyを使用する {#use-managed-cloud-redis-and-valkey}

[サポートされているバージョン](requirements.md#redis-or-valkey)を実行している外部RedisまたはValkeyサービスを使用します。セットアップ手順については、[マネージドサービスとしてのRedis](../administration/redis/replication_and_failover_external.md#redis-as-a-managed-service-in-a-cloud-provider)を参照してください。

サービスは以下をサポートしている必要があります:

- スタンドアロン（プライマリとレプリカ）モードであり、Redisクラスターモードではありません。
- レプリケーションによる高可用性
- 設定可能な[エビクションポリシー](../administration/redis/replication_and_failover_external.md#setting-the-eviction-policy)

> [!note]
> Serverless RedisおよびValkeyのバリアントはサポートされていません。

動作が確認されているサービスには以下が含まれます:

- [Google Memorystore](https://cloud.google.com/memorystore)
- [Amazon ElastiCache for Valkey](https://aws.amazon.com/elasticache/valkey/)

> [!note]
> AWSでは、Valkey 7.2用のElastiCacheを使用してください。Redis 7.2用のElastiCacheはAWSでは利用できません。Redis 7.1用のElastiCacheはRedis 7.0 OSS上に構築されており、新規デプロイには推奨されません。現在、[Azure Cache for Redis](https://azure.microsoft.com/en-gb/products/cache)と[Azure Managed Redis](https://azure.microsoft.com/en-gb/products/managed-redis)のいずれも、Redis 7.2またはサポート対象のValkeyバージョンを提供していません。Azureデプロイの場合、RedisまたはValkeyを仮想マシン上で自己管理してください。

大規模な環境では、キャッシュ用と永続データ用に別々のRedisインスタンスを実行します。Redisはシングルスレッドであり、単一の共有インスタンスではスケール時にボトルネックとなります。

## マネージドクラウドオブジェクトストレージを使用する {#use-managed-cloud-object-storage}

S3互換のオブジェクトストレージサービスを使用します。テスト済みのプロバイダーと設定の詳細の全リストについては、[オブジェクトストレージ](../administration/object_storage.md)を参照してください。
