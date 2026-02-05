---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: ClickHouse
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta on GitLab Self-Managed and GitLab Dedicated

{{< /details >}}

[ClickHouse](https://clickhouse.com) is an open-source column-oriented database management system. It can efficiently filter, aggregate, and query across large data sets.

GitLab uses ClickHouse as a secondary data store to enable advanced analytics features such as GitLab Duo, SDLC trends, and CI Analytics. GitLab only stores data that supports these features in ClickHouse.

You should use [ClickHouse Cloud](https://clickhouse.com/cloud) to connect ClickHouse to GitLab.

Alternatively, you can [bring your own ClickHouse](https://clickhouse.com/docs/en/install). For more information, see [ClickHouse recommendations for GitLab Self-Managed](https://clickhouse.com/docs/guides/sizing-and-hardware-recommendations).

## Analytics available with ClickHouse

After you configure ClickHouse, you can use the following analytics features:

| Feature | Description |
|----------------------|---------------------|
| [Runner fleet dashboard](../ci/runners/runner_fleet_dashboard.md#dashboard-metrics)  | Displays runner usage metrics and job wait times. Provides export of CSV files containing job counts and executed runner minutes by runner type and job status for each project.   |
| [Contribution analytics](../user/group/contribution_analytics/_index.md)  | Provides analytics of group member contributions (push events, issues, merge requests) over time. ClickHouse reduces the likelihood of timeout issues for large instances. |
| [GitLab Duo and SDLC trends](../user/analytics/duo_and_sdlc_trends.md)  | Measures the impact of GitLab Duo on software development performance. Tracks development metrics (deployment frequency, lead time, change failure rate, time to restore) alongside AI-specific indicators (GitLab Duo seat adoption, Code Suggestions acceptance rates, and GitLab Duo Chat usage). |
| [GraphQL API for AI Metrics](../api/graphql/duo_and_sdlc_trends.md) | Provides programmatic access to GitLab Duo and SDLC trend data through the `AiMetrics`, `AiUserMetrics`, and `AiUsageData` endpoints. Provides export of pre-aggregated metrics and raw event data for integration with BI tools and custom analytics. |

## Supported ClickHouse versions

The supported ClickHouse version differs depending on your GitLab version:

- GitLab 17.7 and later supports ClickHouse 23.x. To use either ClickHouse 24.x or 25.x, use the [workaround](#database-schema-migrations-on-gitlab-1800-and-earlier).
- GitLab 18.1 and later supports ClickHouse 23.x, 24.x, and 25.x.
- GitLab 18.8 and later supports ClickHouse 23.x, 24.x, 25.x, and the Replicated database engine.
  - Older clusters will require an additional permission (`dictGet`), see the [snippet](#database-dictionary-read-support).

ClickHouse Cloud is always compatible with the latest stable GitLab release.

> [!warning]
> If you're using ClickHouse 25.12, note that it introduced a [backward-incompatible change](https://clickhouse.com/docs/whats-new/changelog#backward-incompatible-change) to `ALTER MODIFY COLUMN`. This breaks the migration process for the GitLab ClickHouse integration in versions prior to 18.8. It requires upgrading GitLab to version 18.8+.

## Set up ClickHouse

Choose your deployment type based on your operational requirements:

- **[ClickHouse Cloud](#set-up-clickhouse-cloud)** (Recommended): Fully managed service with automatic upgrades, backups, and scaling.
- **[ClickHouse for GitLab Self-Managed (BYOC)](#set-up-clickhouse-for-gitlab-self-managed-byoc)**: Complete control over your infrastructure and configuration.

After setting up your ClickHouse instance:

1. [Create the GitLab database and user](#create-database-and-user).
1. [Configure the GitLab connection](#configure-the-gitlab-connection).
1. [Verify the connection](#verify-the-connection).
1. [Run ClickHouse migrations](#run-clickhouse-migrations).
1. [Enable ClickHouse for Analytics](#enable-clickhouse-for-analytics).

### Set up ClickHouse Cloud

Prerequisites:

- Have a ClickHouse Cloud account.
- Enable network connectivity from your GitLab instance to ClickHouse Cloud.
- Be an administrator your GitLab instance.

To set up ClickHouse Cloud:

1. Sign in to [ClickHouse Cloud](https://clickhouse.cloud).
1. Select **New Service**.
1. Choose your service tier:
   - **Development**: For testing and development environments.
   - **Production**: For production workloads with high availability.
1. Select your cloud provider and region. Choose a region close to your GitLab instance for optimal performance.
1. Configure your service name and settings.
1. Select **Create Service**.
1. Once provisioned, note your connection details from the service dashboard:
   - Host
   - Port (usually `9440` for secure connections)
   - Username
   - Password

> [!note]
> ClickHouse Cloud automatically handles version upgrades and security patches. Enterprise Edition (EE) customers can schedule upgrades to control when they occur, and avoid unexpected service interruptions during business hours. For more information, see [upgrade ClickHouse](#upgrade-clickhouse).

After you create your ClickHouse Cloud service, you then [create the GitLab database and user](#create-database-and-user).

### Set up ClickHouse for GitLab Self-Managed (BYOC)

Prerequisites:

- Have a ClickHouse instance installed and running. If ClickHouse is not installed, see:
  - [ClickHouse official installation guide](https://clickhouse.com/docs/en/install).
  - [ClickHouse recommendations for GitLab Self-Managed](https://clickhouse.com/docs/guides/sizing-and-hardware-recommendations).
- Have a [supported ClickHouse version](#supported-clickhouse-versions).
- Enable network connectivity from your GitLab instance to ClickHouse.
- Be an Administrator for both ClickHouse and your GitLab instance.

> [!warning]
> For ClickHouse for GitLab Self-Managed, you are responsible for planning and executing version upgrades, security patches, and backups. For more information, see [Upgrade ClickHouse](#upgrade-clickhouse).

#### Configure High Availability

For a multi-node, high-availability (HA) setup, GitLab supports the Replicated table engine in ClickHouse.

Prerequisites:

- Have a ClickHouse cluster with multiple nodes. A minimum of three nodes is recommended.
- Define a cluster in the `remote_servers` configuration section.
- Configure the following macros in your ClickHouse configuration:
  - `cluster`
  - `shard`
  - `replica`

When configuring the database for HA, you must run the statements with the `ON CLUSTER` clause.

For more information, see [ClickHouse Replicated database engine documentation](https://clickhouse.com/docs/en/engines/database-engines/replicated).

#### Configure Load balancer

The GitLab application communicates with the ClickHouse cluster through the HTTP/HTTPS interface. For HA deployments, use an HTTP proxy or load balancer to distribute requests across ClickHouse cluster nodes.

Recommended load balancer options:

- [chproxy](https://www.chproxy.org/) - ClickHouse-specific HTTP proxy with built-in caching and routing.
- HAProxy - General-purpose TCP/HTTP load balancer.
- NGINX - Web server with load balancing capabilities.
- Cloud provider load balancers (AWS Application Load Balancer, GCP Load Balancer, Azure Load Balancer).

Basic chproxy configuration example:

```yaml
server:
  http:
    listen_addr: ":8080"

clusters:
  - name: "clickhouse_cluster"
    nodes: [
      "http://ch-node1:8123",
      "http://ch-node2:8123",
      "http://ch-node3:8123"
    ]

users:
  - name: "gitlab"
    password: "your_secure_password"
    to_cluster: "clickhouse_cluster"
    to_user: "gitlab"
```

When using a load balancer, configure GitLab to connect to the load balancer URL instead of individual ClickHouse nodes.

For more information, see [chproxy documentation](https://www.chproxy.org/).

After you configure your ClickHouse for GitLab Self-Managed instance, [create the GitLab database and user](#create-database-and-user).

### Verify ClickHouse installation

Before configuring the database, verify ClickHouse is installed and accessible:

1. Check ClickHouse is running:

   ```shell
   clickhouse-client --query "SELECT version()"
   ```

   If ClickHouse is running, you see the version number (for example, `24.3.1.12`).

1. Verify you can connect with credentials:

   ```shell
   clickhouse-client --host your-clickhouse-host --port 9440 --secure --user default --password 'your-password'
   ```

   > [!note]
   > If you have not configured TLS yet, use port `9000` without the `--secure` flag for initial testing.

### Create database and user

To create the necessary user and database objects:

1. Generate a secure password and save it.
1. Sign in to:
   - For ClickHouse Cloud, the ClickHouse SQL console.
   - For ClickHouse for GitLab Self-Managed, the `clickhouse-client`.
1. Run the following commands, replacing `PASSWORD_HERE` with the generated password.

{{< tabs >}}

{{< tab title="Single-node or ClickHouse Cloud" >}}

```sql
CREATE DATABASE gitlab_clickhouse_main_production;
CREATE USER gitlab IDENTIFIED WITH sha256_password BY 'PASSWORD_HERE';
CREATE ROLE gitlab_app;
GRANT SELECT, INSERT, ALTER, CREATE, UPDATE, DROP, TRUNCATE, OPTIMIZE, dictGet ON gitlab_clickhouse_main_production.* TO gitlab_app;
GRANT SELECT ON information_schema.* TO gitlab_app;
GRANT gitlab_app TO gitlab;
```

{{< /tab >}}

{{< tab title="HA ClickHouse for GitLab Self-Managed" >}}

Replace `CLUSTER_NAME_HERE` with your cluster's name:

```sql
CREATE DATABASE gitlab_clickhouse_main_production ON CLUSTER CLUSTER_NAME_HERE ENGINE = Replicated('/clickhouse/databases/{cluster}/gitlab_clickhouse_main_production', '{shard}', '{replica}');
CREATE USER gitlab IDENTIFIED WITH sha256_password BY 'PASSWORD_HERE' ON CLUSTER CLUSTER_NAME_HERE;
CREATE ROLE gitlab_app ON CLUSTER CLUSTER_NAME_HERE;
GRANT SELECT, INSERT, ALTER, CREATE, UPDATE, DROP, TRUNCATE, OPTIMIZE, dictGet ON gitlab_clickhouse_main_production.* TO gitlab_app ON CLUSTER CLUSTER_NAME_HERE;
GRANT SELECT ON information_schema.* TO gitlab_app ON CLUSTER CLUSTER_NAME_HERE;
GRANT gitlab_app TO gitlab ON CLUSTER CLUSTER_NAME_HERE;
```

{{< /tab >}}

{{< /tabs >}}

### Configure the GitLab connection

{{< tabs >}}

{{< tab title="Linux package" >}}

To provide GitLab with ClickHouse credentials:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['clickhouse_databases']['main']['database'] = 'gitlab_clickhouse_main_production'
   gitlab_rails['clickhouse_databases']['main']['url'] = 'https://your-clickhouse-host:port'
   gitlab_rails['clickhouse_databases']['main']['username'] = 'gitlab'
   gitlab_rails['clickhouse_databases']['main']['password'] = 'PASSWORD_HERE' # replace with the actual password
   ```

   Replace the URL with:
   - For ClickHouse Cloud: `https://your-service.clickhouse.cloud:9440`
   - ClickHouse for GitLab Self-Managed: `https://your-clickhouse-host:8443`
   - For ClickHouse for GitLab Self-Managed HA with load balancer: `https://your-load-balancer:8080` (or your load balancer URL)

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
         username: gitlab
         password:
           secret: gitlab-clickhouse-password
           key: main_password
         database: gitlab_clickhouse_main_production
         url: 'https://your-clickhouse-host:port'
   ```

   Replace the URL with:
   - For ClickHouse Cloud: `https://your-service.clickhouse.cloud:9440`
   - For ClickHouse for GitLab Self-Managed single node: `https://your-clickhouse-host:8443`
   - For ClickHouse for GitLab Self-Managed HA with load balancer: `https://your-load-balancer:8080` (or your load balancer URL)

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< /tabs >}}

> [!note]
> For production deployments, configure TLS/SSL on your ClickHouse instance and use `https://` URLs. For GitLab Self-Managed installations, see the [Network Security](#network-security) documentation.

### Verify the connection

To verify that your connection is set up successfully:

1. Sign in to the [Rails console](../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Execute the following command:

   ```ruby
   ClickHouse::Client.select('SELECT 1', :main)
   ```

   If successful, the command returns `[{"1"=>1}]`.

If the connection fails, verify:

- ClickHouse service is running and accessible.
- Network connectivity from GitLab to ClickHouse. Check that firewalls and security groups allow connections.
- Connection URL is correct (host, port, protocol).
- Credentials are correct.
- For HA cluster deployments: Load balancer is properly configured and routing requests.

### Run ClickHouse migrations

{{< tabs >}}

{{< tab title="Linux package" >}}

To create the required database objects, execute:

```shell
sudo gitlab-rake gitlab:clickhouse:migrate
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

Migrations are executed automatically with the [GitLab-Migrations chart](https://docs.gitlab.com/charts/charts/gitlab/migrations/).

Alternatively, you can run migrations by executing the following command in the Toolbox pod:

```shell
gitlab-rake gitlab:clickhouse:migrate
```

{{< /tab >}}

{{< /tabs >}}

### Enable ClickHouse for Analytics

After your GitLab instance is connected to ClickHouse, you can enable features that use ClickHouse:

Prerequisites:

- You must have administrator access to the instance.
- ClickHouse connection is configured and verified.
- Migrations have been successfully completed.

To enable ClickHouse for Analytics:

1. In the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **ClickHouse**.
1. Select **Enable ClickHouse for Analytics**.
1. Select **Save changes**.

### Disable ClickHouse for Analytics

To disable ClickHouse for Analytics:

Prerequisites:

- You must have administrator access to the instance.

To disable:

1. In the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **ClickHouse**.
1. Clear the **Enable ClickHouse for Analytics** checkbox.
1. Select **Save changes**.

> [!note]
> Disabling ClickHouse for Analytics stops GitLab from querying ClickHouse but does not delete any data from your ClickHouse instance. Analytics features that rely on ClickHouse will fall back to alternative data sources or become unavailable.

## Upgrade ClickHouse

### ClickHouse Cloud

ClickHouse Cloud automatically handles version upgrades and security patches. No manual intervention is required.

For information about upgrade scheduling and maintenance windows, see the [ClickHouse Cloud documentation](https://clickhouse.com/docs/cloud/manage/updates).

> [!note]
> ClickHouse Cloud notifies you in advance of upcoming upgrades. Review the [ClickHouse Cloud changelog](https://clickhouse.com/docs/cloud/changes) to stay informed about new features and changes.

### ClickHouse for GitLab Self-Managed (BYOC)

For ClickHouse for GitLab Self-Managed, you are responsible for planning and executing version upgrades.

Prerequisites:

- Have administrator access to the ClickHouse instance.
- Back up your data before upgrading. See [Disaster recovery](#disaster-recovery).

Before upgrading:

1. Review the [ClickHouse release notes](https://clickhouse.com/docs/category/release-notes) for breaking changes.
1. Check [compatibility](#supported-clickhouse-versions) with your GitLab version.
1. Test the upgrade in a non-production environment.
1. Plan for potential downtime, or use a rolling upgrade strategy for HA clusters.

To upgrade ClickHouse:

1. For single-node deployments, follow the [ClickHouse upgrade documentation](https://clickhouse.com/docs/manage/updates).
1. For HA cluster deployments, perform a rolling upgrade to minimize downtime:
   - Upgrade one node at a time.
   - Wait for the node to rejoin the cluster.
   - Verify cluster health before proceeding to the next node.

> [!warning]
> Always ensure the ClickHouse version remains compatible with your GitLab version. Incompatible versions might cause indexing to pause and features to fail. For more information, see [supported ClickHouse versions](#supported-clickhouse-versions)

For detailed upgrade procedures, see the [ClickHouse documentation on updates](https://clickhouse.com/docs/manage/updates).

## Operations

### Check migration status

Prerequisites:

- You must have administrator access to the instance.

To check the status of ClickHouse migrations:

1. In the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **ClickHouse**.
1. Review the **Migration status** section if available.

Alternatively, check for pending migrations using the Rails console:

```ruby
# Sign in to Rails console
# Run this to check migrations
ClickHouse::MigrationSupport::Migrator.new(:main).pending_migrations
```

### Retry failed migrations

If a ClickHouse migration fails:

1. Check the logs for error details. ClickHouse-related errors are logged in the GitLab application logs.
1. Address the underlying issue (for example, insufficient memory, connectivity problems).
1. Retry the migration:

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:clickhouse:migrate

   # For self-compiled installations
   bundle exec rake gitlab:clickhouse:migrate RAILS_ENV=production
   ```

> [!note]
> Migrations are designed to be idempotent and safe to retry. If a migration fails partway through, running it again resumes from where it left off or skip already-completed steps.

## ClickHouse Rake tasks

GitLab provides several Rake tasks for managing your ClickHouse database.

The following Rake tasks are available:

| Task | Description |
|------|-------------|
| [`sudo gitlab-rake gitlab:clickhouse:migrate`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | Runs all pending ClickHouse migrations to create or update database schema. |
| [`sudo gitlab-rake gitlab:clickhouse:drop`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | Drops all ClickHouse databases. Use with extreme caution as this deletes all data. |
| [`sudo gitlab-rake gitlab:clickhouse:create`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | Creates ClickHouse databases if they do not exist. |
| [`sudo gitlab-rake gitlab:clickhouse:setup`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | Creates databases and runs all migrations. Equivalent to running `create` and `migrate` tasks. |
| [`sudo gitlab-rake gitlab:clickhouse:schema:dump`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | Dumps the current database schema to a file for backup or version control. |
| [`sudo gitlab-rake gitlab:clickhouse:schema:load`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/click_house/migration.rake) | Loads the database schema from a dump file. |

> [!note]
> For self-compiled installations, use `bundle exec rake` instead of `sudo gitlab-rake` and add `RAILS_ENV=production` to the end of the command.

### Common task examples

#### Verify ClickHouse connection and schema

To verify your ClickHouse connection is working:

```shell
# For installations that use the Linux package
sudo gitlab-rake gitlab:clickhouse:info

# For self-compiled installations
bundle exec rake gitlab:clickhouse:info RAILS_ENV=production
```

This task outputs debugging information about the ClickHouse connection and configuration.

#### Re-run all migrations

To run all pending migrations:

```shell
# For installations that use the Linux package
sudo gitlab-rake gitlab:clickhouse:migrate

# For self-compiled installations
bundle exec rake gitlab:clickhouse:migrate RAILS_ENV=production
```

#### Reset the database

> [!warning]
> This deletes all data in your ClickHouse database. Use only in development or when troubleshooting.

To drop and recreate the database:

```shell
# For installations that use the Linux package
sudo gitlab-rake gitlab:clickhouse:drop
sudo gitlab-rake gitlab:clickhouse:setup

# For self-compiled installations
bundle exec rake gitlab:clickhouse:drop RAILS_ENV=production
bundle exec rake gitlab:clickhouse:setup RAILS_ENV=production
```

### Environment variables

You can use environment variables to control Rake task behavior:

| Environment variable | Data type | Description |
|---------------------|-----------|-------------|
| `VERBOSE` | Boolean | Set to `true` to see detailed output during migrations. Example: `VERBOSE=true sudo gitlab-rake gitlab:clickhouse:migrate` |

## Performance tuning

> [!note]
> For resource sizing and deployment recommendations based on your user count, see [system requirements](#system-requirements).

For information about ClickHouse architecture and performance tuning, see the [ClickHouse documentation on architecture](https://clickhouse.com/docs/architecture/introduction).

## Disaster recovery

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

- TLS Encryption: Configure ClickHouse servers to [use TLS encryption](#network-security) to validate connections.

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

| Users | Primary recommendation | Comparable AWS ARM instance | Comparable GCP ARM instance | Comparable Azure ARM instance | Deployment type |
|---|---|---|---|---|---|
| 1K | ClickHouse Cloud Basic | - | - | - | Managed |
| 2K | ClickHouse Cloud Basic | `m8g.xlarge` | `c4a-standard-4` |  `Standard_D4ps_v6` | Managed or Single Node |
| 3K | ClickHouse Cloud Scale | `m8g.2xlarge` | `c4a-standard-8` | `Standard_D8ps_v6` | Managed or Single Node |
| 5K | ClickHouse Cloud Scale | `m8g.4xlarge` | `c4a-standard-16` | `Standard_D16ps_v6` | Managed or Single Node |
| 10K | ClickHouse Cloud Scale | `m8g.4xlarge` | `c4a-standard-16` | `Standard_D16ps_v6` | Managed or Single Node/HA |
| 25K | ClickHouse for GitLab Self-Managed or ClickHouse Cloud Scale | `m8g.8xlarge` or 3×`m8g.4xlarge` | `c4a-standard-32` or 3×`c4a-standard-16` | `Standard_D32ps_v6` or 3x`Standard_D16ps_v6` | Managed or Single Node/HA |
| 50K | ClickHouse for GitLab Self-Managed high availability (HA) or ClickHouse Cloud Scale | 3×`m8g.4xlarge` | 3×`c4a-standard-16` | 3x`Standard_D16ps_v6` | Managed or HA Cluster |

### 1K Users

Recommendation: ClickHouse Cloud Basic as it provides good cost efficiency with no operational complexity.

### 2K Users

Recommendation: ClickHouse Cloud Basic as it offers best value with no operational complexity.

Alternative recommendation for ClickHouse for GitLab Self-Managed deployment:

- AWS: m8g.xlarge (4 vCPU, 16 GB)
- GCP: c4a-standard-4 or n4-standard-4 (4 vCPU, 16 GB)
- Azure: Standard_D4ps_v6 (4 vCPU, 16 GB)
- Storage: 20 GB with low-medium performance tier

### 3K Users

Recommendation: ClickHouse Cloud Scale

Alternative recommendation for ClickHouse for GitLab Self-Managed deployment:

- AWS: m8g.2xlarge (8 vCPU, 32 GB)
- GCP: c4a-standard-8 or n4-standard-8 (8 vCPU, 32 GB)
- Azure: Standard_D8ps_v6 (8 vCPU, 32 GB)
- Storage: 100 GB with medium performance tier

Note: HA deployments not cost-effective at this scale.

### 5K Users

Recommendation: ClickHouse Cloud Scale

Alternative recommendation for ClickHouse for GitLab Self-Managed deployment:

- AWS: m8g.4xlarge (16 vCPU, 64 GB)
- GCP: c4a-standard-16 or n4-standard-16 (16 vCPU, 64 GB)
- Azure: Standard_D16ps_v6 (16 vCPU, 64 GB)
- Storage: 100 GB with high performance tier
- Deployment: Single node recommended

### 10K Users

Recommendation: ClickHouse Cloud Scale

Alternative recommendation for ClickHouse for GitLab Self-Managed deployment:

- AWS: m8g.4xlarge (16 vCPU, 64 GB)
- GCP: c4a-standard-16 or n4-standard-16 (16 vCPU, 64 GB)
- Azure: Standard_D16ps_v6 (16 vCPU, 64 GB)
- Storage: 200 GB with high performance tier
- HA Option: 3-node cluster becomes viable for critical workloads

### 25K Users

Recommendation: ClickHouse Cloud Scale or ClickHouse for GitLab Self-Managed. Both options are economically feasible at this scale.

Recommendations for ClickHouse for GitLab Self-Managed deployment:

- Single Node:

  - AWS: m8g.8xlarge (32 vCPU, 128 GB)
  - GCP: c4a-standard-32 or n4-standard-32 (32 vCPU, 128 GB)
  - Azure: Standard_D32ps_v6 (32 vCPU, 128 GB)

- HA Deployment:

  - AWS: 3 × m8g.4xlarge (16 vCPU, 64 GB each)
  - GCP: 3 × c4a-standard-16 or 3 × n4-standard-16 (16 vCPU, 64 GB each)
  - Azure: 3 x Standard_D16ps_v6 (16 vCPU, 64 GB each)

- Storage: 400 GB per node with high performance tier.

### 50K Users

Recommendation: ClickHouse for GitLab Self-Managed HA or ClickHouse Cloud Scale. The self-managed option is slightly more cost-effective at this scale.

Recommendations for ClickHouse for GitLab Self-Managed deployment:

- Single Node:

  - AWS: m8g.8xlarge (32 vCPU, 128 GB)
  - GCP: c4a-standard-32 or n4-standard-32 (32 vCPU, 128 GB)
  - Azure: Standard_D32ps_v6 (32 vCPU, 128 GB)

- HA Deployment (Preferred):

  - AWS: 3 × m8g.4xlarge (16 vCPU, 64 GB each)
  - GCP: 3 × c4a-standard-16 or 3 × n4-standard-16 (16 vCPU, 64 GB each)
  - Azure: 3 x Standard_D16ps_v6 (16 vCPU, 64 GB each)

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
- TTL (Time To Live): Time To Live (TTL) is a ClickHouse feature that automatically moves, deletes, or rolls up columns/rows after a certain time period.
  This allows you to manage storage more efficiently because you can delete, move, or archive the data that you no longer need to access frequently.

## Troubleshooting

### Database schema migrations on GitLab 18.0.0 and earlier

> [!warning]
> On GitLab 18.0.0 and earlier, running database schema migrations for ClickHouse may fail for ClickHouse 24.x and 25.x with the following error message:
>
> ```plaintext
> Code: 344. DB::Exception: Projection is fully supported in ReplacingMergeTree with deduplicate_merge_projection_mode = throw. Use 'drop' or 'rebuild' option of deduplicate_merge_projection_mode
> ```
>
> Without running all migrations, the ClickHouse integration will not work.

To work around this issue and run the migrations:

1. Sign in to the [Rails console](../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Execute the following command:

   ```ruby
   ClickHouse::Client.execute("INSERT INTO schema_migrations (version) VALUES ('20231114142100'), ('20240115162101')", :main)
   ```

1. Migrate the database again:

   ```shell
   sudo gitlab-rake gitlab:clickhouse:migrate
   ```

This time the database migration should successfully finish.

### Database dictionary read support

From GitLab 18.8, GitLab starts using [ClickHouse Dictionaries](https://clickhouse.com/docs/dictionary) for data denormalization. The `GRANT` statements prior 18.8 did not give permission to the `gitlab` user to query dictionaries so a manual modification step is needed:

1. Sign in to:
   - For ClickHouse Cloud, the ClickHouse SQL console.
   - For ClickHouse for GitLab Self-Managed, the `clickhouse-client`.
1. Run the following commands, replacing `PASSWORD_HERE` with the generated password.

{{< tabs >}}

{{< tab title="Single-node or ClickHouse Cloud" >}}

```sql
GRANT dictGet ON gitlab_clickhouse_main_production.* TO gitlab_app;
```

{{< /tab >}}

{{< tab title="HA ClickHouse for GitLab Self-Managed" >}}

Replace `CLUSTER_NAME_HERE` with your cluster's name:

```sql
GRANT dictGet ON gitlab_clickhouse_main_production.* TO gitlab_app ON CLUSTER CLUSTER_NAME_HERE;
```

{{< /tab >}}

{{< /tabs >}}

Without granting the permission, the ClickHouse migration (`CreateNamespaceTraversalPathsDict`) will fail with the following error:

```plaintext
DB::Exception: gitlab: Not enough privileges.
```

After granting the permission, the migration can be safely retried (ideally, wait 1-2 hours until the distributed migration lock clears).

### ClickHouse CI job data materialized view data inconsistencies

In GitLab 18.5 and earlier, duplicate data could be inserted into ClickHouse tables
(such as `ci_finished_pipelines` and `ci_finished_builds`) when Sidekiq workers
retried after network timeouts. This issue caused materialized views to display incorrect
aggregated metrics in analytics dashboards, including the runner fleet dashboard.

This issue was fixed in GitLab 18.9 and backported to 18.6, 18.7, and 18.8.
To resolve this issue, upgrade to GitLab 18.6 or later.

If you have existing duplicate data, a fix to rebuild the affected materialized views is planned
for GitLab 18.10 in [issue 586319](https://gitlab.com/gitlab-org/gitlab/-/issues/586319).
For assistance, contact GitLab Support.
