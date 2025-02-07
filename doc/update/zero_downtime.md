---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Zero-downtime upgrades
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

With zero-downtime upgrades, it's possible to upgrade a live GitLab environment without having to
take it offline. This guide will take you through the core process of performing
such an upgrade.

At a high level, this process is done by sequentially upgrading GitLab nodes in a certain order, utilizing a combination of
Load Balancing, HA systems and graceful reloads to minimize the disruption.

For the purposes of this guide it will only pertain to the core GitLab components where applicable. For upgrades
or management of third party services, such as AWS RDS, please refer to the respective documentation.

## Before you start

Achieving _true_ zero downtime as part of an upgrade is notably difficult for any distributed application. The process detailed in
this guide has been tested as given against our HA [Reference Architectures](../administration/reference_architectures/_index.md)
and was found to result in effectively no observable downtime, but please be aware your mileage may vary dependent on the specific system makeup.

For additional confidence, some customers have found success with further techniques such as the
manually draining nodes by using specific load balancer or infrastructure capabilities. These techniques depend greatly
on the underlying infrastructure capabilities and as a result are not covered in this guide.
For any additional information please reach out to your GitLab representative
or the [Support team](https://about.gitlab.com/support/).

## Requirements and considerations

The zero-downtime upgrade process has the following requirements:

- Zero-downtime upgrades are only supported on multi-node GitLab environments built with the Linux package that have Load Balancing and HA mechanisms configured as follows:
  - External Load Balancer configured for Rails nodes with health checks enabled against the [Readiness](../administration/monitoring/health_check.md#readiness) (`/-/readiness`) endpoint.
  - Internal Load Balancer configured for any PgBouncer and Praefect components with TCP health checks enabled.
  - HA mechanisms configured for the Consul, Postgres and Redis components if present.
    - Any of these components that are not deployed in a HA fashion will need to be upgraded separately with downtime.
- **You can only upgrade one minor release at a time**. So from `16.1` to `16.2`, not to `16.3`. If you skip releases, database modifications may be run in the wrong sequence [and leave the database schema in a broken state](https://gitlab.com/gitlab-org/gitlab/-/issues/321542).
- You have to use [post-deployment migrations](../development/database/post_deployment_migrations.md).
- [Zero-downtime upgrades are not available with the GitLab Charts](https://docs.gitlab.com/charts/installation/upgrade.html) but are with [GitLab Operator](https://docs.gitlab.com/operator/gitlab_upgrades.html).

In addition to the above, please be aware of the following considerations:

- Most of the time, you can safely upgrade from a patch release to the next minor release if the patch release is not the latest.
  For example, upgrading from `16.3.2` to `16.4.1` should be safe even if `16.3.3` has been released. You should verify the
  version-specific upgrading instructions relevant to your [upgrade path](upgrade_paths.md) and be aware of any required upgrade stops:
  - [GitLab 17 changes](versions/gitlab_17_changes.md)
  - [GitLab 16 changes](versions/gitlab_16_changes.md)
  - [GitLab 15 changes](versions/gitlab_15_changes.md)
- Some releases may include [background migrations](background_migrations.md). These migrations are performed in the background by Sidekiq and are often used for migrating data. Background migrations are only added in the monthly releases.
  - Certain major or minor releases may require a set of background migrations to be finished. While this doesn't require downtime (if the above conditions are met), it's required that you [wait for background migrations to complete](background_migrations.md) between each major or minor release upgrade.
  - The time necessary to complete these migrations can be reduced by increasing the number of Sidekiq workers that can process jobs in the
    `background_migration` queue. To see the size of this queue, [check for background migrations before upgrading](background_migrations.md).
- [PostgreSQL major version upgrades](../administration/postgresql/replication_and_failover.md#near-zero-downtime-upgrade-of-postgresql-in-a-patroni-cluster) are a separate process and not covered by zero-downtime upgrades (smaller upgrades are covered).
- Zero-downtime upgrades are supported for any GitLab components you've deployed with the GitLab Linux package. If you've deployed select components through a supported third party service, such as PostgreSQL in AWS RDS or Redis in GCP Memorystore, upgrades for those services will need to be performed separately as per their standard processes.
- As a general guideline, the larger amount of data you have, the more time it will take for the upgrade to complete. In testing, any database smaller than 10 GB shouldn't generally take longer than an hour, but your mileage may vary.

NOTE:
If you want to upgrade multiple releases or do not meet these requirements [upgrades with downtime](with_downtime.md) should be explored instead.

## Upgrade order

We recommend a "back to front" approach for the order of what components to upgrade with zero downtime.
Generally this would be stateful backends first, their dependents next and then the frontends accordingly.
While the order of deployment can be changed, it is best to deploy the components running GitLab application code (Rails, Sidekiq) together. If possible, upgrade the supporting infrastructure (PostgreSQL, PgBouncer, Consul, Gitaly, Praefect, Redis) separately since these components do not have dependencies on changes made in version updates within a major release.
As such, we generally recommend the following order:

1. Consul
1. PostgreSQL
1. PgBouncer
1. Redis
1. Gitaly
1. Praefect
1. Rails
1. Sidekiq

## Multi-node / HA deployment

In this section we'll go through the core process of upgrading a multi-node GitLab environment by
sequentially going through each as per the [upgrade order](#upgrade-order) and load balancers / HA mechanisms handle each node going down accordingly.

For the purposes of this guide we'll upgrade a [200 RPS or 10,000 Reference Architecture](../administration/reference_architectures/10k_users.md) built with the Linux package.

### Consul, PostgreSQL, PgBouncer and Redis

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
   sudo gitlab-ctl restart
   ```

### Gitaly

[Gitaly](../administration/gitaly/_index.md) follows the same core process when it comes to upgrading but with a key difference
that the Gitaly process itself is not restarted as it has a built-in process to gracefully reload
at the earliest opportunity. Note that any other component will still need to be restarted.

NOTE:
The upgrade process attempts to do a graceful handover to a new Gitaly process.
Existing long-running Git requests that were started before the upgrade may eventually be dropped as this handover occurs.
In the future this functionality may be changed, [refer to this Epic](https://gitlab.com/groups/gitlab-org/-/epics/10328) for more information.

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

### Praefect

For Gitaly Cluster setups, you must deploy and upgrade Praefect in a similar way by using a graceful reload.

NOTE:
The upgrade process attempts to do a graceful handover to a new Praefect process.
Existing long-running Git requests that were started before the upgrade may eventually be dropped as this handover occurs.
In the future this functionality may be changed, [refer to this Epic](https://gitlab.com/groups/gitlab-org/-/epics/10328) for more information.

One additional step though for Praefect is that it will also need to run through its database migrations to upgrade its data.
Migrations need to be run on only one Praefect node to avoid clashes. This is best done by selecting one of the
nodes to be a deploy node. This target node will be configured to run migrations while the rest are not. We'll refer to this as the **Praefect deploy node** below:

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

Rails as a webserver consists primarily of [Puma](../administration/operations/puma.md), [Workhorse](../development/workhorse/_index.md), and [NGINX](../development/architecture.md#nginx).

Each of these components have different behaviours when it comes to doing a live upgrade. While Puma can allow
for a graceful reload, Workhorse doesn't. The best approach is to drain the node gracefully through other means,
such as by using your load balancer. You can also do this by using NGINX on the node through its graceful shutdown
functionality. This section explains the NGINX approach.

In addition to the above, Rails is where the main database migrations need to be executed. Like Praefect, the best approach is by using the deploy node. If PgBouncer is currently being used, it also needs to be bypassed as Rails uses an advisory lock when attempting to run a migration to prevent concurrent migrations from running on the same database. These locks are not shared across transactions, resulting in `ActiveRecord::ConcurrentMigrationError` and other issues when running database migrations using PgBouncer in transaction pooling mode.

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

   1. Configure regular migrations to by setting `gitlab_rails['auto_migrate'] = true` in the
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

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

This section describes the steps required to upgrade live GitLab environment
deployment with Geo.

Overall, the approach is largely the same as the
[normal process](#multi-node--ha-deployment) with some additional steps required
for each secondary site. The required order is upgrading the primary first, then
the secondaries. You must also run any post-deployment migrations on the primary _after_
all secondaries have been updated.

NOTE:
The same [requirements and consideration](#requirements-and-considerations) apply for upgrading a live GitLab environment with Geo.

### Primary site

The upgrade process for the Primary site is the same as the [normal process](#multi-node--ha-deployment) with one exception being
not to run the post-deployment migrations until after all the secondaries have been updated.

Run through the same steps for the Primary site as described but stopping at the Rails node step of running the post-deployment migrations.

### Secondary site(s)

The upgrade process for any Secondary sites follow the same steps as the normal process except for the Rails nodes
where several additional steps are required as detailed below.

To upgrade the site proceed through the normal process steps as normal until the Rails node and instead follow the steps
below:

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
