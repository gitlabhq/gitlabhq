---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ClickHouse integration guidelines
---

DETAILS:
**Status:** Experiment

This feature is an [experiment](../policy/development_stages_support.md).

Instructions about how to set up integration between GitLab and ClickHouse database.

## Setup

To set up ClickHouse as the GitLab data storage:

1. [Run ClickHouse Cluster and configure database](#run-and-configure-clickhouse).
1. [Configure GitLab connection to ClickHouse](#configure-the-gitlab-connection-to-clickhouse).
1. [Run ClickHouse migrations](#run-clickhouse-migrations).

### Run and configure ClickHouse

The most straightforward way to run ClickHouse is with [ClickHouse Cloud](https://console.clickhouse.cloud/).
You can also [run ClickHouse on your own server](https://clickhouse.com/docs/en/install). Refer to the ClickHouse
documentation regarding [recommendations for GitLab Self-Managed](https://clickhouse.com/docs/en/install#recommendations-for-self-managed-clickhouse).

When you run ClickHouse on a hosted server, various data points might impact the resource consumption, like the number
of builds that run on your instance each month, the selected hardware, the data center choice to host ClickHouse, and more.
Regardless, the cost should not be significant.

NOTE:
ClickHouse is a secondary data store for GitLab. Only specific data is stored in ClickHouse for analytics purposes.

To create necessary user and database objects:

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

::Tabs

:::TabTitle Linux package

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

:::TabTitle Helm chart (Kubernetes)

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

::EndTabs

To verify that your connection is set up successfully:

1. Sign in to [Rails console](../administration/operations/rails_console.md#starting-a-rails-console-session)
1. Execute the following:

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
