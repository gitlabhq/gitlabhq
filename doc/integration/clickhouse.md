---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: ClickHouse integration guidelines
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta on GitLab Self-Managed and GitLab Dedicated

{{< /details >}}

{{< alert type="note" >}}

For more information on plans for ClickHouse support for GitLab Self-Managed, see [epic 51](https://gitlab.com/groups/gitlab-org/architecture/gitlab-data-analytics/-/epics/51).

{{< /alert >}}

{{< alert type="note" >}}

For more information about ClickHouse support for GitLab Dedicated, see [ClickHouse for GitLab Dedicated](../subscriptions/gitlab_dedicated/_index.md#clickhouse-cloud).

{{< /alert >}}

[ClickHouse](https://clickhouse.com) is an open-source column-oriented database management system. It can efficiently filter, aggregate, and query across large data sets.

ClickHouse is a secondary data store for GitLab. Only specific data is stored in ClickHouse for advanced analytical features such as [GitLab Duo and SDLC trends](../user/analytics/duo_and_sdlc_trends.md) and [CI Analytics](../ci/runners/runner_fleet_dashboard.md#enable-more-ci-analytics-features-with-clickhouse).

You should use [ClickHouse Cloud](https://clickhouse.com/cloud) to connect ClickHouse to GitLab.

Alternatively, you can [bring your own ClickHouse](https://clickhouse.com/docs/en/install). For more information, see [ClickHouse recommendations for GitLab Self-Managed](https://clickhouse.com/docs/guides/sizing-and-hardware-recommendations).

## Supported ClickHouse versions

| First GitLab version | ClickHouse versions | Comment |
|----------------------|---------------------|---------|
| 17.7.0               | 23.x (24.x, 25.x)   | For using ClickHouse 24.x and 25.x see the [workaround section](#database-schema-migrations-on-gitlab-1800-and-earlier). |
| 18.1.0               | 23.x, 24.x, 25.x    |         |
| 18.5.0               | 23.x, 24.x, 25.x    | Experimental support for `Replicated` database engine. |

{{< alert type="note" >}}

[ClickHouse Cloud](https://clickhouse.com/cloud) is supported. Compatibility is generally ensured with the latest major GitLab release and newer versions.

{{< /alert >}}

## Set up ClickHouse

To set up ClickHouse with GitLab:

1. [Run ClickHouse Cluster and configure database](#run-and-configure-clickhouse).
1. [Configure GitLab connection to ClickHouse](#configure-the-gitlab-connection-to-clickhouse).
1. [Run ClickHouse migrations](#run-clickhouse-migrations).

### Run and configure ClickHouse

When you run ClickHouse on a hosted server, various data points might impact the resource consumption, like the number
of builds that run on your instance each month, the selected hardware, the data center choice to host ClickHouse, and more.
Regardless, the cost should not be significant.

To create the necessary user and database objects:

1. Generate a secure password and save it.
1. Sign in to the ClickHouse SQL console.
1. Execute the following command. Replace `PASSWORD_HERE` with the generated password.

   ```sql
   CREATE DATABASE gitlab_clickhouse_main_production;
   CREATE USER gitlab IDENTIFIED WITH sha256_password BY 'PASSWORD_HERE';
   CREATE ROLE gitlab_app;
   GRANT SELECT, INSERT, ALTER, CREATE, UPDATE, DROP, TRUNCATE, OPTIMIZE ON gitlab_clickhouse_main_production.* TO gitlab_app;
   GRANT SELECT ON information_schema.* TO gitlab_app;
   GRANT gitlab_app TO gitlab;
   ```

### Configure the GitLab connection to ClickHouse

{{< tabs >}}

{{< tab title="Linux package" >}}

To provide GitLab with ClickHouse credentials:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['clickhouse_databases']['main']['database'] = 'gitlab_clickhouse_main_production'
   gitlab_rails['clickhouse_databases']['main']['url'] = 'https://example.com/path'
   gitlab_rails['clickhouse_databases']['main']['username'] = 'gitlab'
   gitlab_rails['clickhouse_databases']['main']['password'] = 'PASSWORD_HERE' # replace with the actual password
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Save the ClickHouse password as a Kubernetes Secret:

   ```shell
   kubectl create secret generic gitlab-clickhouse-password --from-literal="main_password=PASSWORD_HERE"
   ```

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     clickhouse:
       enabled: true
       main:
         username: default
         password:
           secret: gitlab-clickhouse-password
           key: main_password
         database: gitlab_clickhouse_main_production
         url: 'http://example.com'
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< /tabs >}}

To verify that your connection is set up successfully:

1. Sign in to [Rails console](../administration/operations/rails_console.md#starting-a-rails-console-session)
1. Execute the following command:

   ```ruby
   ClickHouse::Client.select('SELECT 1', :main)
   ```

   If successful, the command returns `[{"1"=>1}]`

### Run ClickHouse migrations

{{< tabs >}}

{{< tab title="Linux package" >}}

To create the required database objects execute:

```shell
sudo gitlab-rake gitlab:clickhouse:migrate
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Migrations are executed automatically using the [GitLab-Migrations chart](https://docs.gitlab.com/charts/charts/gitlab/migrations/#clickhouse-optional).

Alternatively, you can run migrations by executing the following command in the [Toolbox pod](https://docs.gitlab.com/charts/charts/gitlab/toolbox/):

```shell
gitlab-rake gitlab:clickhouse:migrate
```

{{< /tab >}}

{{< /tabs >}}

### Enable ClickHouse for Analytics

Now that your GitLab instance is connected to ClickHouse, you can enable features to use ClickHouse by [enabling ClickHouse for Analytics](../administration/analytics.md).

## `Replicated` database engine

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/560927) as an experiment in GitLab 18.5.

{{< /history >}}

For a multi-node, high-availability setup, GitLab supports the `Replicated` table engine in ClickHouse.

Prerequisites:

- A cluster must be defined in the `remote_servers` [configuration section](https://clickhouse.com/docs/architecture/cluster-deployment#configure-clickhouse-servers).
- The following [macros](https://clickhouse.com/docs/architecture/cluster-deployment#macros-config-explanation) must be configured:
  - `cluster`
  - `shard`
  - `replica`

When configuring the database, you must run the statements with the `ON CLUSTER` clause.
In the following example, replace `CLUSTER_NAME_HERE` with your cluster's name:

 ```sql
 CREATE DATABASE gitlab_clickhouse_main_production ON CLUSTER CLUSTER_NAME_HERE ENGINE = Replicated('/clickhouse/databases/{cluster}/gitlab_clickhouse_main_production', '{shard}', '{replica}')
 CREATE USER gitlab IDENTIFIED WITH sha256_password BY 'PASSWORD_HERE' ON CLUSTER CLUSTER_NAME_HERE;
 CREATE ROLE gitlab_app ON CLUSTER CLUSTER_NAME_HERE;
 GRANT SELECT, INSERT, ALTER, CREATE, UPDATE, DROP, TRUNCATE, OPTIMIZE ON gitlab_clickhouse_main_production.* TO gitlab_app ON CLUSTER CLUSTER_NAME_HERE;
 GRANT SELECT ON information_schema.* TO gitlab_app ON CLUSTER CLUSTER_NAME_HERE;
 GRANT gitlab_app TO gitlab ON CLUSTER CLUSTER_NAME_HERE;
 ```

### Load balancer considerations

The GitLab application communicates with the ClickHouse cluster through the HTTP/HTTPS interface. Consider using an HTTP proxy for load balancing requests to the ClickHouse cluster, such as [`chproxy`](https://www.chproxy.org/).

### Backup and Restore

You should perform a full backup before upgrading the GitLab application.
ClickHouse data is not included in GitLab backup tooling.

Backup and restore strategy depends on the choice of deployment.

#### ClickHouse Cloud

ClickHouse Cloud automatically:

- Manages the backups and restores.
- Create and retains daily backups.

You do not have to do any additional configuration.

For more information, see [ClickHouse Cloud backups](https://clickhouse.com/docs/cloud/manage/backups).

#### ClickHouse for GitLab Self-Managed

If you manage your own ClickHouse instance, you should take regular backups to ensure data safety:

- Take initial full backups of tables (excluding system tables like `metrics` or `logs`) to a [object storage bucket, for example AWS S3](https://clickhouse.com/docs/en/operations/backup#configuring-backuprestore-to-use-an-s3-endpoint).
- Take [incremental backups](https://clickhouse.com/docs/en/operations/backup#take-an-incremental-backup) after this initial full backup.

This duplicates data for every full backup, but is the [easiest approach to restore data](https://clickhouse.com/docs/en/operations/backup#restore-from-the-incremental-backup).

Alternatively, use [`clickhouse-backup`](https://github.com/Altinity/clickhouse-backup). This is a third-party tool that provides similar functionality with additional features like scheduling and remote storage management.

## Monitoring

To ensure the stability of the GitLab integration, you should monitor the health and performance of your ClickHouse cluster.

### ClickHouse Cloud

ClickHouse Cloud provides a native [Prometheus integration](https://clickhouse.com/docs/integrations/prometheus) that exposes metrics through a secure API endpoint.

After generating the API credentials, you can configure collectors to scrape metrics from ClickHouse Cloud. For example, a [Prometheus deployment](https://clickhouse.com/docs/integrations/prometheus#configuring-prometheus).

### ClickHouse for GitLab Self-Managed

ClickHouse can expose [metrics in Prometheus format](https://clickhouse.com/docs/operations/server-configuration-parameters/settings#prometheus).
To enable this:

1. Configure the `prometheus` section in your `config.xml` to expose metrics on a dedicated port (default is `9363`).

   ```xml
    <prometheus>
        <endpoint>/metrics</endpoint>
        <port>9363</port>
        <metrics>true</metrics>
        <events>true</events>
        <asynchronous_metrics>true</asynchronous_metrics>
    </prometheus>
   ```

1. Configure Prometheus or a similar compatible server to scrape `http://<clickhouse-host>:9363/metrics`.

### Metrics to monitor

You should set up alerts for the following metrics to detect issues that may impact GitLab features:

| Metric Name | Description | Alert Threshold (Recommendation) |
| :--- | :--- | :--- |
| `ClickHouse_Metrics_Query` | Number of queries currently executing. A sudden spike might indicate a performance bottleneck. | Baseline deviation (for example `> 100`) |
| `ClickHouseProfileEvents_FailedSelectQuery` | Number of failed select queries | Baseline deviation (for example `> 50`) |
| `ClickHouseProfileEvents_FailedInsertQuery` | Number of failed insert queries | Baseline deviation (for example `> 10`) |
| `ClickHouse_AsyncMetrics_ReadonlyReplica` | Indicates if a replica has gone into read-only mode (often due to ZooKeeper connection loss). | `> 0` (take immediate action) |
| `ClickHouse_ProfileEvents_NetworkErrors` | Network errors (connection resets/timeouts). Frequent errors might cause GitLab background jobs to fail. | Rate `> 0` |

### Liveness check

If ClickHouse is available behind a load balancer, you can use the HTTP `/ping` endpoint to check for liveness.
The expected response is `Ok` with HTTP Code 200.

## Security and auditing

To ensure the security of your data and ensure audit ability, use the following security practices.

### Network security

- TLS Encryption: Configure ClickHouse servers to [use TLS encryption](https://clickhouse.com/docs/guides/sre/configuring-ssl) to validate connections.

  When configuring the connection URL in GitLab, you should use the `https://` protocol (for example, `https://clickhouse.example.com:8443`) to specify this.

- IP Allow lists: Restrict access to the ClickHouse port (default `8443` or `9440`) to only the GitLab application nodes and other authorized networks.

### Audit logging

GitLab application does not maintain a separate audit log for individual ClickHouse queries.
In order to satisfy specific requirements regarding data access (who queried what and when), you can enable logging on the ClickHouse side.

#### ClickHouse Cloud

In ClickHouse Cloud, query logging is enabled by default.
You can access these logs by querying the `system.query_log` table.

#### ClickHouse for GitLab Self-Managed

For self-managed instances, ensure the `query_log` configuration parameter is enabled in your server configuration:

1. Verify that the `query_log` section exists in your `config.xml` or `users.xml`:

   ```xml
    <query_log>
        <database>system</database>
        <table>query_log</table>
        <partition_by>toYYYYMM(event_date)</partition_by>
        <flush_interval_milliseconds>7500</flush_interval_milliseconds>
        <ttl>event_date + INTERVAL 30 DAY</ttl>  <!-- Keep only 30 days -->
    </query_log>
   ```

1. Once enabled, all executed queries are recorded in the `system.query_log` table, allowing for audit trail.

## System requirements

The recommended system requirements change depending on the number of users.

### Deployment decision matrix quick reference

| Users | Primary Recommendation | Comparable AWS ARM Instance | Comparable GCP ARM Instance | Deployment Type |
|---|---|---|---|---|
| 1K | ClickHouse Cloud Basic | - | - | Managed |
| 2K | ClickHouse Cloud Basic | `m8g.xlarge` | `c4a-standard-4` |  Managed or Single Node |
| 3K | ClickHouse Cloud Scale | `m8g.2xlarge` | `c4a-standard-8` | Managed or Single Node |
| 5K | ClickHouse Cloud Scale | `m8g.4xlarge` | `c4a-standard-16` | Managed or Single Node |
| 10K | ClickHouse Cloud Scale | `m8g.4xlarge` | `c4a-standard-16` |  Managed or Single Node/HA |
| 25K | ClickHouse for GitLab Self-Managed or ClickHouse Cloud Scale | `m8g.8xlarge` or 3×`m8g.4xlarge` | `c4a-standard-32` or 3×`c4a-standard-16` | Managed or Single Node/HA |
| 50K | ClickHouse for GitLab Self-Managed high availability (HA) or ClickHouse Cloud Scale | 3×`m8g.4xlarge` | 3×`c4a-standard-16` | Managed or HA Cluster |

### 1K Users

Recommendation: ClickHouse Cloud Basic as it provides good cost efficiency with no operational complexity.

### 2K Users

Recommendation: ClickHouse Cloud Basic as it offers best value with no operational complexity.

Alternative recommendation for ClickHouse for GitLab Self-Managed deployment:

- AWS: m8g.xlarge (4 vCPU, 16 GB)
- GCP: c4a-standard-4 or n4-standard-4 (4 vCPU, 16 GB)
- Storage: 20 GB with low-medium performance tier

### 3K Users

Recommendation: ClickHouse Cloud Scale

Alternative recommendation for ClickHouse for GitLab Self-Managed deployment:

- AWS: m8g.2xlarge (8 vCPU, 32 GB)
- GCP: c4a-standard-8 or n4-standard-8 (8 vCPU, 32 GB)
- Storage: 100 GB with medium performance tier

Note: HA deployments not cost-effective at this scale.

### 5K Users

Recommendation: ClickHouse Cloud Scale

Alternative recommendation for ClickHouse for GitLab Self-Managed deployment:

- AWS: m8g.4xlarge (16 vCPU, 64 GB)
- GCP: c4a-standard-16 or n4-standard-16 (16 vCPU, 64 GB)
- Storage: 100 GB with high performance tier
- Deployment: Single node recommended

### 10K Users

Recommendation: ClickHouse Cloud Scale

Alternative recommendation for ClickHouse for GitLab Self-Managed deployment:

- AWS: m8g.4xlarge (16 vCPU, 64 GB)
- GCP: c4a-standard-16 or n4-standard-16 (16 vCPU, 64 GB)
- Storage: 200 GB with high performance tier
- HA Option: 3-node cluster becomes viable for critical workloads

### 25K Users

Recommendation: ClickHouse Cloud Scale or ClickHouse for GitLab Self-Managed. Both options are economically feasible at this scale.

Recommendations for ClickHouse for GitLab Self-Managed deployment:

- Single Node:

  - AWS: m8g.8xlarge (32 vCPU, 128 GB)
  - GCP: c4a-standard-32 or n4-standard-32 (32 vCPU, 128 GB)

- HA Deployment:

  - AWS: 3 × m8g.4xlarge (16 vCPU, 64 GB each)
  - GCP: 3 × c4a-standard-16 or 3 × n4-standard-16 (16 vCPU, 64 GB each)

- Storage: 400 GB per node with high performance tier.

### 50K Users

Recommendation: ClickHouse for GitLab Self-Managed HA or ClickHouse Cloud Scale. The self-managed option is slightly more cost-effective at this scale.

Recommendations for ClickHouse for GitLab Self-Managed deployment:

- Single Node:

  - AWS: m8g.8xlarge (32 vCPU, 128 GB)
  - GCP: c4a-standard-32 or n4-standard-32 (32 vCPU, 128 GB)

- HA Deployment (Preferred):

  - AWS: 3 × m8g.4xlarge (16 vCPU, 64 GB each)
  - GCP: 3 × c4a-standard-16 or 3 × n4-standard-16 (16 vCPU, 64 GB each)

- Storage: 1000 GB per node with high performance tier.

#### HA considerations for ClickHouse for GitLab Self-Managed deployment

HA setup becomes cost effective only at 10k users or above.

- Minimum: Three ClickHouse nodes for quorum.
- [ClickHouse Keeper](https://clickhouse.com/clickhouse/keeper): Three nodes for coordination (can be co-located or separate).
- LoadBalancer: Recommended for distributing queries.
- Network: Low-latency connectivity between nodes is critical.

## Glossary

- Cluster: A collection of nodes (servers) that work together to store and process data.
- MergeTree: [`MergeTree`](https://clickhouse.com/docs/engines/table-engines/mergetree-family/mergetree) is a table engine in ClickHouse designed for high data ingest rates and large data volumes.
  It is the core storage engine in ClickHouse, providing features such as columnar storage, custom partitioning, sparse primary indexes, and support for background data merges.
- Parts: A physical file on a disk that stores a portion of the table's data.
  A part is different from a partition, which is a logical division of a table's data that is created using a partition key.
- Replica: A copy of the data stored in a ClickHouse database.
  You can have any number of replicas of the same data for redundancy and reliability.
  Replicas are used in conjunction with the ReplicatedMergeTree table engine, which enables ClickHouse to keep multiple copies of data in sync across different servers.
- Shard: A subset of data.
  ClickHouse always has at least one shard for your data.
  If you do not split the data across multiple servers, your data is stored in one shard.
  Sharding data across multiple servers can be used to divide the load if you exceed the capacity of a single server.
- TTL: Time To Live (TTL) is a ClickHouse feature that automatically moves, deletes, or rolls up columns/rows after a certain time period.
  This allows you to manage storage more efficiently because you can delete, move, or archive the data that you no longer need to access frequently.

## Troubleshooting

### Database schema migrations on GitLab 18.0.0 and earlier

On GitLab 18.0.0 and earlier, running database schema migrations for ClickHouse may fail for ClickHouse 24.x and 25.x with the following error message:

```plaintext
Code: 344. DB::Exception: Projection is fully supported in ReplacingMergeTree with deduplicate_merge_projection_mode = throw. Use 'drop' or 'rebuild' option of deduplicate_merge_projection_mode
```

Without running all migrations, the ClickHouse integration will not work.

To work around this issue and run the migrations:

1. Sign in to [Rails console](../administration/operations/rails_console.md#starting-a-rails-console-session)
1. Execute the following command:

   ```ruby
   ClickHouse::Client.execute("INSERT INTO schema_migrations (version) VALUES ('20231114142100'), ('20240115162101')", :main)
   ```

1. Migrate the database again:

   ```shell
   sudo gitlab-rake gitlab:clickhouse:migrate
   ```

This time the database migration should successfully finish.
