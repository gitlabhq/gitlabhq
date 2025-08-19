---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Upgrade a multi-node instance with zero downtime
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

In this section we'll go through the core process of upgrading a multi-node GitLab environment by
sequentially going through each as per the [upgrade order](downtime_options.md#upgrade-order) and load balancers / HA mechanisms handle each node going down accordingly.

For the purposes of this guide we'll upgrade a [200 RPS or 10,000 Reference Architecture](../administration/reference_architectures/10k_users.md) built with the Linux package.

### Consul, PostgreSQL, PgBouncer, and Redis

The [Consul](../administration/consul.md), [PostgreSQL](../administration/postgresql/replication_and_failover.md),
[PgBouncer](../administration/postgresql/pgbouncer.md), and [Redis](../administration/redis/replication_and_failover.md) components all follow the same underlying process to upgrading without downtime.

Run through the following steps sequentially on each component's node to perform the upgrade:

1. Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. This prevents upgrades from running `gitlab-ctl reconfigure`, which by default automatically stops GitLab, runs all database migrations, and restarts GitLab:

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

1. [Upgrade the GitLab package](package/_index.md#upgrade-to-a-specific-version).

1. Reconfigure and restart to get the latest code in place:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   {{< tabs >}}

   {{< tab title="For PostgreSQL nodes only" >}}

   Restart the Consul client first, then restart all other services to ensure PostgreSQL failover occurs gracefully:

   ```shell
   sudo gitlab-ctl restart consul
   sudo gitlab-ctl restart-except consul
   ```

   {{< /tab >}}

   {{< tab title="For all other component nodes" >}}

   ```shell
   sudo gitlab-ctl restart
   ```

   {{< /tab >}}

   {{< /tabs >}}

### Gitaly

[Gitaly](../administration/gitaly/_index.md) follows the same core process when it comes to upgrading but with a key difference
that the Gitaly process itself is not restarted as it has a built-in process to gracefully reload
at the earliest opportunity. Other components will still need to be restarted.

{{< alert type="note" >}}

The upgrade process attempts to do a graceful handover to a new Gitaly process.
Existing long-running Git requests that were started before the upgrade may eventually be dropped as this handover occurs.
In the future this functionality may be changed, [refer to this Epic](https://gitlab.com/groups/gitlab-org/-/epics/10328) for more information.

{{< /alert >}}

This process applies to both Gitaly Sharded and Cluster setups. Run through the following steps sequentially on each Gitaly node to perform the upgrade:

1. Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. This prevents upgrades from running `gitlab-ctl reconfigure`, which by default automatically stops GitLab, runs all database migrations, and restarts GitLab:

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

1. [Upgrade the GitLab package](package/_index.md#upgrade-to-a-specific-version).
1. Run the `reconfigure` command to get the latest code in place and to instruct Gitaly to gracefully reload at the next opportunity:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Finally, while Gitaly will gracefully reload any other components that have been deployed, we will still need a restart:

   ```shell
   # Get a list of what other components have been deployed beside Gitaly
   sudo gitlab-ctl status

   # Restart each component except Gitaly. Example given for Consul, Node Exporter and Logrotate
   sudo gitlab-ctl restart consul node-exporter logrotate
   ```

#### Gitaly Cluster (Praefect)

For Gitaly Cluster (Praefect) setups, you must deploy and upgrade Praefect in a similar way by using a graceful reload.

{{< alert type="note" >}}

The upgrade process attempts to do a graceful handover to a new Praefect process.
Existing long-running Git requests that were started before the upgrade may eventually be dropped as this handover occurs.
In the future this functionality may be changed, [refer to this Epic](https://gitlab.com/groups/gitlab-org/-/epics/10328) for more information.

{{< /alert >}}

{{< alert type="note" >}}

This section focuses exclusively on the Praefect component, not its [required PostgreSQL database](../administration/gitaly/praefect/configure.md#postgresql). The [GitLab Linux package does not offer HA](https://gitlab.com/groups/gitlab-org/-/epics/7814) and subsequently Zero Downtime support for the Praefect database. A third party database solution is required to avoid downtime.

{{< /alert >}}

Praefect must also perform database migrations to upgrade any existing data. To avoid clashes,
migrations should run on only one Praefect node. To do this, designate a specific node as a
deploy node that runs the migrations. This is referred to as
the **Praefect deploy node** in the following steps:

1. On the **Praefect deploy node**:

   1. Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. This prevents upgrades from running `gitlab-ctl reconfigure`,
      which by default automatically stops GitLab, runs all database migrations, and restarts GitLab:

      ```shell
      sudo touch /etc/gitlab/skip-auto-reconfigure
      ```

   1. [Upgrade the GitLab package](package/_index.md#upgrade-to-a-specific-version).

   1. Ensure that `praefect['auto_migrate'] = true` is set in `/etc/gitlab/gitlab.rb` so that database migrations run.

   1. Run the `reconfigure` command to get the latest code in place, apply the Praefect database migrations and restart gracefully:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

1. On all **remaining Praefect nodes**:

   1. Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. This prevents upgrades from running `gitlab-ctl reconfigure`,
      which by default automatically stops GitLab, runs all database migrations, and restarts GitLab:

      ```shell
      sudo touch /etc/gitlab/skip-auto-reconfigure
      ```

   1. [Upgrade the GitLab package](package/_index.md#upgrade-to-a-specific-version).

   1. Ensure that `praefect['auto_migrate'] = false` is set in `/etc/gitlab/gitlab.rb` to prevent
      `reconfigure` from automatically running database migrations.

   1. Run the `reconfigure` command to get the latest code in place as well as restart gracefully:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

1. Finally, while Praefect will gracefully reload, any other components that have been deployed will still need a restart.
   On all **Praefect nodes**:

   ```shell
   # Get a list of what other components have been deployed beside Praefect
   sudo gitlab-ctl status

   # Restart each component except Praefect. Example given for Consul, Node Exporter and Logrotate
   sudo gitlab-ctl restart consul node-exporter logrotate
   ```

### Rails

Rails as a webserver consists primarily of [Puma](../administration/operations/puma.md), Workhorse, and NGINX.

Each of these components have different behaviours when it comes to doing a live upgrade. While Puma can allow
for a graceful reload, Workhorse doesn't. The best approach is to drain the node gracefully through other means,
such as by using your load balancer. You can also do this by using NGINX on the node through its graceful shutdown
functionality. This section explains the NGINX approach.

In addition to the previous, Rails is where the main database migrations need to be executed. Like Praefect, the best approach is by using the deploy node. If PgBouncer is currently being used, it also needs to be bypassed as Rails uses an advisory lock when attempting to run a migration to prevent concurrent migrations from running on the same database. These locks are not shared across transactions, resulting in `ActiveRecord::ConcurrentMigrationError` and other issues when running database migrations using PgBouncer in transaction pooling mode.

1. On the **Rails deploy node**:

   1. Drain the node of traffic gracefully. You can do this in various ways, but one
   approach is to use NGINX by sending it a `QUIT` signal and then stopping the service.
   As an example, you can do this by using the following shell script:

      ```shell
      # Send QUIT to NGINX master process to drain and exit
      NGINX_PID=$(cat /var/opt/gitlab/nginx/nginx.pid)
      kill -QUIT $NGINX_PID

      # Wait for drain to complete
      while kill -0 $NGINX_PID 2>/dev/null; do sleep 1; done

      # Stop NGINX service to prevent automatic restarts
      gitlab-ctl stop nginx
      ```

   1. Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. This prevents upgrades from running `gitlab-ctl reconfigure`, which by default automatically stops GitLab, runs all database migrations, and restarts GitLab:

      ```shell
      sudo touch /etc/gitlab/skip-auto-reconfigure
      ```

   1. [Upgrade the GitLab package](package/_index.md#upgrade-to-a-specific-version).

   1. Configure regular migrations to run by setting `gitlab_rails['auto_migrate'] = true` in the
      `/etc/gitlab/gitlab.rb` configuration file.
      - If the deploy node is currently going through PgBouncer to reach the database then
        you must [bypass it](../administration/postgresql/pgbouncer.md#procedure-for-bypassing-pgbouncer)
        and connect directly to the database leader before running migrations.
      - To find the database leader you can run the following command on any database node - `sudo gitlab-ctl patroni members`.

   1. Run the regular migrations and get the latest code in place:

      ```shell
      sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-ctl reconfigure
      ```

   1. Leave this node as-is for now as you'll come back to run post-deployment migrations
      later.

1. On every **other Rails node** sequentially:

   1. Drain the node of traffic gracefully. You can do this in various ways, but one
   approach is to use NGINX by sending it a `QUIT` signal and then stopping the service.
   As an example, you can do this by using the following shell script:

      ```shell
      # Send QUIT to NGINX master process to drain and exit
      NGINX_PID=$(cat /var/opt/gitlab/nginx/nginx.pid)
      kill -QUIT $NGINX_PID

      # Wait for drain to complete
      while kill -0 $NGINX_PID 2>/dev/null; do sleep 1; done

      # Stop NGINX service to prevent automatic restarts
      gitlab-ctl stop nginx
      ```

   1. Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. This prevents upgrades from running `gitlab-ctl reconfigure`, which by default automatically stops GitLab, runs all database migrations, and restarts GitLab:

      ```shell
      sudo touch /etc/gitlab/skip-auto-reconfigure
      ```

   1. [Upgrade the GitLab package](package/_index.md#upgrade-to-a-specific-version).

   1. Ensure that `gitlab_rails['auto_migrate'] = false` is set in `/etc/gitlab/gitlab.rb` to prevent
      `reconfigure` from automatically running database migrations.

   1. Run the `reconfigure` command to get the latest code in place as well as restart:

      ```shell
      sudo gitlab-ctl reconfigure
      sudo gitlab-ctl restart
      ```

1. On the **Rails deploy node** run the post-deployment migrations:

   1. Ensure the deploy node is still pointing at the database leader directly. If the node
      is currently going through PgBouncer to reach the database then you must
      [bypass it](../administration/postgresql/pgbouncer.md#procedure-for-bypassing-pgbouncer)
      and connect directly to the database leader before running migrations.
      - To find the database leader you can run the following command on any database node - `sudo gitlab-ctl patroni members`.

   1. Run the post-deployment migrations:

      ```shell
      sudo gitlab-rake db:migrate
      ```

   1. Return the config back to normal by setting `gitlab_rails['auto_migrate'] = false` in the
      `/etc/gitlab/gitlab.rb` configuration file.
      - If PgBouncer is being used make sure to set the database config to once again point towards it

   1. Run through reconfigure once again to reapply the normal config as well as restart:

      ```shell
      sudo gitlab-ctl reconfigure
      sudo gitlab-ctl restart
      ```

### Sidekiq

[Sidekiq](../administration/sidekiq/_index.md) follows the same underlying process as others to upgrading without downtime.

Run through the following steps sequentially on each component node to perform the upgrade:

1. Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. This prevents upgrades from running `gitlab-ctl reconfigure`, which by default automatically stops GitLab, runs all database migrations, and restarts GitLab:

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

1. [Upgrade the GitLab package](package/_index.md#upgrade-to-a-specific-version).

1. Run the `reconfigure` command to get the latest code in place as well as restart:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart
   ```

## Multi-node / HA deployment with Geo

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

This section describes the steps required to upgrade live GitLab environment
deployment with Geo.

Overall, the approach is largely the same as the
normal process with some additional steps required
for each secondary site. The required order is upgrading the primary first, then
the secondaries. You must also run any post-deployment migrations on the primary after
all secondaries have been updated.

{{< alert type="note" >}}

The same [requirements and consideration](downtime_options.md#requirements-and-considerations) apply for upgrading a live GitLab environment with Geo.

{{< /alert >}}

### Primary site

The upgrade process for the Primary site is the same as the normal process with one exception being
not to run the post-deployment migrations until after all the secondaries have been updated.

Run through the same steps for the Primary site as described but stopping at the Rails node step of running the post-deployment migrations.

### Secondary sites

The upgrade process for any Secondary sites follow the same steps as the normal process except for the Rails nodes
The upgrade process is the same for both primary and secondary sites. However, you must perform the following additional steps for Rails nodes on secondary sites.

#### Rails

1. On the **Rails deploy node**:

   1. Drain the node of traffic gracefully. You can do this in various ways, but one
   approach is to use NGINX by sending it a `QUIT` signal and then stopping the service.
   As an example, you can do this by using the following shell script:

      ```shell
      # Send QUIT to NGINX master process to drain and exit
      NGINX_PID=$(cat /var/opt/gitlab/nginx/nginx.pid)
      kill -QUIT $NGINX_PID

      # Wait for drain to complete
      while kill -0 $NGINX_PID 2>/dev/null; do sleep 1; done

      # Stop NGINX service to prevent automatic restarts
      gitlab-ctl stop nginx
      ```

   1. Stop the Geo Log Cursor process to ensure it fails over to another node:

      ```shell
      gitlab-ctl stop geo-logcursor
      ```

   1. Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. This prevents upgrades from running `gitlab-ctl reconfigure`, which by default automatically stops GitLab, runs all database migrations, and restarts GitLab:

      ```shell
      sudo touch /etc/gitlab/skip-auto-reconfigure
      ```

   1. [Upgrade the GitLab package](package/_index.md#upgrade-to-a-specific-version).

   1. Copy the `/etc/gitlab/gitlab-secrets.json` file from the primary site Rails node to the secondary site Rails node if they're different. The file must be the same on all of a site's nodes.

   1. Ensure no migrations are configured to be run automatically by setting `gitlab_rails['auto_migrate'] = false` and `geo_secondary['auto_migrate'] = false` in the
      `/etc/gitlab/gitlab.rb` configuration file.

   1. Run the `reconfigure` command to get the latest code in place as well as restart:

      ```shell
      sudo gitlab-ctl reconfigure
      sudo gitlab-ctl restart
      ```

   1. Run the regular Geo Tracking migrations and get the latest code in place:

      ```shell
      sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-rake db:migrate:geo
      ```

1. On every **other Rails node** sequentially:

   1. Drain the node of traffic gracefully. You can do this in various ways, but one
   approach is to use NGINX by sending it a `QUIT` signal and then stopping the service.
   As an example, you can do this by using the following shell script:

      ```shell
      # Send QUIT to NGINX master process to drain and exit
      NGINX_PID=$(cat /var/opt/gitlab/nginx/nginx.pid)
      kill -QUIT $NGINX_PID

      # Wait for drain to complete
      while kill -0 $NGINX_PID 2>/dev/null; do sleep 1; done

      # Stop NGINX service to prevent automatic restarts
      gitlab-ctl stop nginx
      ```

   1. Stop the Geo Log Cursor process to ensure it fails over to another node:

      ```shell
      gitlab-ctl stop geo-logcursor
      ```

   1. Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. This prevents upgrades from running `gitlab-ctl reconfigure`, which by default automatically stops GitLab, runs all database migrations, and restarts GitLab:

      ```shell
      sudo touch /etc/gitlab/skip-auto-reconfigure
      ```

   1. [Upgrade the GitLab package](package/_index.md#upgrade-to-a-specific-version).

   1. Ensure no migrations are configured to be run automatically by setting `gitlab_rails['auto_migrate'] = false` and `geo_secondary['auto_migrate'] = false` in the
      `/etc/gitlab/gitlab.rb` configuration file.

   1. Run the `reconfigure` command to get the latest code in place as well as restart:

      ```shell
      sudo gitlab-ctl reconfigure
      sudo gitlab-ctl restart
      ```

#### Sidekiq

Following the main process all that's left to be done now is to upgrade Sidekiq.

Upgrade Sidekiq in the [same manner as described in the main section](#sidekiq).

### Post-deployment migrations

Finally, head back to the primary site and finish the upgrade by running the post-deployment migrations:

1. On the Primary site's **Rails deploy node** run the post-deployment migrations:

   1. Ensure the deploy node is still pointing at the database leader directly. If the node
      is currently going through PgBouncer to reach the database then you must
      [bypass it](../administration/postgresql/pgbouncer.md#procedure-for-bypassing-pgbouncer)
      and connect directly to the database leader before running migrations.
      - To find the database leader you can run the following command on any database node - `sudo gitlab-ctl patroni members`.

   1. Run the post-deployment migrations:

      ```shell
      sudo gitlab-rake db:migrate
      ```

   1. Verify Geo configuration and dependencies

      ```shell
      sudo gitlab-rake gitlab:geo:check
      ```

   1. Return the config back to normal by setting `gitlab_rails['auto_migrate'] = false` in the
      `/etc/gitlab/gitlab.rb` configuration file.
      - If PgBouncer is being used make sure to set the database config to once again point towards it

   1. Run through reconfigure once again to reapply the normal config as well as restart:

      ```shell
      sudo gitlab-ctl reconfigure
      sudo gitlab-ctl restart
      ```

1. On the Secondary site's **Rails deploy node** run the post-deployment Geo Tracking migrations:

   1. Run the post-deployment Geo Tracking migrations:

      ```shell
      sudo gitlab-rake db:migrate:geo
      ```

   1. Verify Geo status:

       ```shell
       sudo gitlab-rake geo:status
       ```
