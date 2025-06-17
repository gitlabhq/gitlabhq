---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ClickHouse integration guidelines
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta on GitLab Self-Managed

{{< /details >}}

{{< alert type="note" >}}

For more information on plans for ClickHouse support for GitLab Self-Managed, see [this epic](https://gitlab.com/groups/gitlab-com/gl-infra/data-access/dbo/-/epics/29).

{{< /alert >}}

[ClickHouse](https://clickhouse.com) is an open-source column-oriented database management system. It can efficiently filter, aggregate, and query across large data sets.

ClickHouse is a secondary data store for GitLab. Only specific data is stored in ClickHouse for advanced analytical features such as [AI impact analytics](../user/analytics/ai_impact_analytics.md) and [CI Analytics](../ci/runners/runner_fleet_dashboard.md#enable-more-ci-analytics-features-with-clickhouse).

You can connect ClickHouse to GitLab either:

- Recommended. With [ClickHouse Cloud](https://clickhouse.com/cloud).
- By [bringing your own ClickHouse](https://clickhouse.com/docs/en/install). For more information, see [ClickHouse recommendations for GitLab Self-Managed](https://clickhouse.com/docs/en/install#recommendations-for-self-managed-clickhouse).

## Supported ClickHouse versions

| First GitLab version | ClickHouse versions | Comment |
|-|-|-|
|17.7.0 | 23.x (24.x, 25.x) | For using ClickHouse 24.x and 25.x see the [workaround section](#database-schema-migrations-on-gitlab-1800-and-earlier). |
|18.1.0 | 23.x, 24.x, 25.x | |

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

To create the required database objects execute:

```shell
sudo gitlab-rake gitlab:clickhouse:migrate
```

### Enable ClickHouse for Analytics

Now that your GitLab instance is connected to ClickHouse, you can enable features to use ClickHouse by [enabling ClickHouse for Analytics](../administration/analytics.md).

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
