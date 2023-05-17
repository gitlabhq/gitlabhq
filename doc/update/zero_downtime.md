---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Zero downtime upgrades **(FREE SELF)**

It's possible to upgrade to a newer major, minor, or patch version of GitLab
without having to take your GitLab instance offline. However, for this to work
there are the following requirements:

- You can only upgrade one minor release at a time. So from 13.1 to 13.2, not to
   13.3. If you skip releases, database modifications may be run in the wrong
   sequence [and leave the database schema in a broken state](https://gitlab.com/gitlab-org/gitlab/-/issues/321542).
- You have to use [post-deployment migrations](../development/database/post_deployment_migrations.md).
- You are using PostgreSQL. Starting from GitLab 12.1, MySQL is not supported.
- You have set up a multi-node GitLab instance. Single-node instances do not support zero-downtime upgrades.

If you want to upgrade multiple releases or do not meet the other requirements:

- [Upgrade a single node with downtime](package/index.md).
- [Upgrade a multi-node instance with downtime](with_downtime.md).

If you meet all the requirements above, follow these instructions in order. There are three sets of steps, depending on your deployment type:

| Deployment type                                                 | Description                                       |
| --------------------------------------------------------------- | ------------------------------------------------  |
| [Gitaly or Gitaly Cluster](#gitaly-or-gitaly-cluster)           | GitLab CE/EE using HA architecture for Gitaly or Gitaly Cluster |
| [Multi-node / PostgreSQL HA](#postgresql)                | GitLab CE/EE using HA architecture for PostgreSQL |
| [Multi-node / Redis HA](#redis-ha-using-sentinel)           | GitLab CE/EE using HA architecture for Redis |
| [Geo](#geo-deployment)                                          | GitLab EE with Geo enabled                        |
| [Multi-node / HA with Geo](#multi-node--ha-deployment-with-geo) | GitLab CE/EE on multiple nodes                    |

Each type of deployment requires that you hot reload the `puma` and `sidekiq` processes on all nodes running these
services after you've upgraded. The reason for this is that those processes each load the GitLab Rails application which reads and loads
the database schema into memory when starting up. Each of these processes must be reloaded (or restarted in the case of `sidekiq`)
to re-read any database changes that have been made by post-deployment migrations.

Most of the time you can safely upgrade from a patch release to the next minor
release if the patch release is not the latest. For example, upgrading from
14.1.1 to 14.2.0 should be safe even if 14.1.2 has been released. We do recommend
you check the release posts of any releases between your current and target
version just in case they include any migrations that may require you to upgrade
one release at a time.

We also recommend you verify the [version specific upgrading instructions](index.md#version-specific-upgrading-instructions) relevant to your [upgrade path](index.md#upgrade-paths).

Some releases may also include so called "background migrations". These
migrations are performed in the background by Sidekiq and are often used for
migrating data. Background migrations are only added in the monthly releases.

Certain major/minor releases may require a set of background migrations to be
finished. To guarantee this, such a release processes any remaining jobs
before continuing the upgrading procedure. While this doesn't require downtime
(if the above conditions are met) we require that you
[wait for background migrations to complete](background_migrations.md)
between each major/minor release upgrade.
The time necessary to complete these migrations can be reduced by
increasing the number of Sidekiq workers that can process jobs in the
`background_migration` queue. To see the size of this queue,
[Check for background migrations before upgrading](background_migrations.md).

As a guideline, any database smaller than 10 GB doesn't take too much time to
upgrade; perhaps an hour at most per minor release. Larger databases however may
require more time, but this is highly dependent on the size of the database and
the migrations that are being performed.

To help explain this, let's look at some examples:

**Example 1:** You are running a large GitLab installation using version 13.4.2,
which is the latest patch release of 13.4. When GitLab 13.5.0 is released this
installation can be safely upgraded to 13.5.0 without requiring downtime if the
requirements mentioned above are met. You can also skip 13.5.0 and upgrade to
13.5.1 after it's released, but you **can not** upgrade straight to 13.6.0; you
_have_ to first upgrade to a 13.5.Z release.

**Example 2:** You are running a large GitLab installation using version 13.4.2,
which is the latest patch release of 13.4. GitLab 13.5 includes some background
migrations, and 14.0 requires these to be completed (processing any
remaining jobs for you). Skipping 13.5 is not possible without downtime, and due
to the background migrations would require potentially hours of downtime
depending on how long it takes for the background migrations to complete. To
work around this you have to upgrade to 13.5.Z first, then wait at least a
week before upgrading to 14.0.

**Example 3:** You use MySQL as the database for GitLab. Any upgrade to a new
major/minor release requires downtime. If a release includes any background
migrations this could potentially lead to hours of downtime, depending on the
size of your database. To work around this you must use PostgreSQL and
meet the other online upgrade requirements mentioned above.

## Multi-node / HA deployment

WARNING:
You can only upgrade one minor release at a time. So from 15.6 to 15.7, not to 15.8.
If you attempt more than one minor release, the upgrade may fail. 

### Use a load balancer in front of web (Puma) nodes

With Puma, single node zero-downtime updates are no longer possible. To achieve
HA with zero-downtime updates, at least two nodes are required to be used with a
load balancer which distributes the connections properly across both nodes.

The load balancer in front of the application nodes must be configured to check
proper health check endpoints to check if the service is accepting traffic or
not. For Puma, the `/-/readiness` endpoint should be used, while
`/readiness` endpoint can be used for Sidekiq and other services.

Upgrades on web (Puma) nodes must be done in a rolling manner, one after
another, ensuring at least one node is always up to serve traffic. This is
required to ensure zero-downtime.

Puma enters a blackout period as part of the upgrade, during which nodes
continue to accept connections but mark their respective health check
endpoints to be unhealthy. On seeing this, the load balancer should disconnect
them gracefully.

Puma restarts only after completing all the currently-processing requests.
This ensures data and service integrity. Once they have restarted, the health
check end points are marked healthy.

The nodes must be updated in the following order to update an HA instance using
load balancer to latest GitLab version.

1. Select one application node as a deploy node and complete the following steps
   on it:

    1. Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. This prevents upgrades from running `gitlab-ctl reconfigure`, which by default automatically stops GitLab, runs all database migrations, and restarts GitLab:

        ```shell
        sudo touch /etc/gitlab/skip-auto-reconfigure
        ```

    1. [Upgrade the GitLab package](package/index.md#upgrade-to-a-specific-version-using-the-official-repositories).

    1. Get the regular migrations and latest code in place. Before running this step,
       the deploy node's `/etc/gitlab/gitlab.rb` configuration file must have
       `gitlab_rails['auto_migrate'] = true` to permit regular migrations.

       ```shell
       sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-ctl reconfigure
       ```

    1. Ensure services use the latest code:

       ```shell
       sudo gitlab-ctl hup puma
       sudo gitlab-ctl restart sidekiq
       ```

1. Complete the following steps on the other Puma/Sidekiq nodes, one
   after another. Always ensure at least one of such nodes is up and running,
   and connected to the load balancer before proceeding to the next node.

    1. Update the GitLab package and ensure a `reconfigure` is run as part of
       it. If not (due to `/etc/gitlab/skip-auto-reconfigure` file being
       present), run `sudo gitlab-ctl reconfigure` manually.

    1. Ensure services use latest code:

       ```shell
       sudo gitlab-ctl hup puma
       sudo gitlab-ctl restart sidekiq
       ```

1. On the deploy node, run the post-deployment migrations:

      ```shell
      sudo gitlab-rake db:migrate
      ```

### Gitaly or Gitaly Cluster

Gitaly nodes can be located on their own server, either as part of a sharded setup, or as part of
[Gitaly Cluster](../administration/gitaly/praefect.md).

Before you update the main GitLab application you must (in order):

1. Upgrade the Gitaly nodes that reside on separate servers.
1. Upgrade Praefect if using Gitaly Cluster.

Because of a [known issue](https://gitlab.com/groups/gitlab-org/-/epics/10328), Gitaly and Gitaly Cluster upgrades
cause some downtime.

#### Upgrade Gitaly nodes

[Upgrade the GitLab package](package/index.md#upgrade-to-a-specific-version-using-the-official-repositories) on the Gitaly nodes one at a time to ensure access to Git repositories is maintained.

#### Upgrade Praefect

From the Praefect nodes, select one to be your Praefect deploy node. You install the new Omnibus package on the deploy
node first and run database migrations.

1. On the **Praefect deploy node**:

   1. Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. This prevents upgrades from running `gitlab-ctl reconfigure`,
      which by default automatically stops GitLab, runs all database migrations, and restarts GitLab:

      ```shell
      sudo touch /etc/gitlab/skip-auto-reconfigure
      ```

   1. Ensure that `praefect['auto_migrate'] = true` is set in `/etc/gitlab/gitlab.rb`.

1. On all **remaining Praefect nodes**, ensure that `praefect['auto_migrate'] = false` is
   set in `/etc/gitlab/gitlab.rb` to prevent `reconfigure` from automatically running database migrations.

1. On the **Praefect deploy node**:

   1. [Upgrade the GitLab package](package/index.md#upgrade-to-a-specific-version-using-the-official-repositories).

   1. To apply the Praefect database migrations and restart Praefect, run:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

1. On all **remaining Praefect nodes**:

   1. [Upgrade the GitLab package](package/index.md#upgrade-to-a-specific-version-using-the-official-repositories).

   1. Ensure nodes are running the latest code:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

### PostgreSQL

Pick a node to be the `Deploy Node`. It can be any application node, but it must be the same
node throughout the process.

**Deploy node**

- Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. This prevents upgrades from running `gitlab-ctl reconfigure`, which by default automatically stops GitLab, runs all database migrations, and restarts GitLab.

  ```shell
  sudo touch /etc/gitlab/skip-auto-reconfigure
  ```

**All nodes _including_ the Deploy node**

- To prevent `reconfigure` from automatically running database migrations, ensure that `gitlab_rails['auto_migrate'] = false` is set in `/etc/gitlab/gitlab.rb`.

**PostgreSQL only nodes**

- [Upgrade the GitLab package](package/index.md#upgrade-to-a-specific-version-using-the-official-repositories).

- Ensure nodes are running the latest code

  ```shell
  sudo gitlab-ctl reconfigure
  ```

**Deploy node**

- [Upgrade the GitLab package](package/index.md#upgrade-to-a-specific-version-using-the-official-repositories).

- If you're using PgBouncer:

  You must [bypass PgBouncer](../administration/postgresql/pgbouncer.md#procedure-for-bypassing-pgbouncer) and connect directly to the database leader
  before running migrations.

  Rails uses an advisory lock when attempting to run a migration to prevent
  concurrent migrations from running on the same database. These locks are
  not shared across transactions, resulting in `ActiveRecord::ConcurrentMigrationError`
  and other issues when running database migrations using PgBouncer in transaction
  pooling mode.

  To find the leader node, run the following on a database node:

  ```shell
  sudo gitlab-ctl patroni members
  ```

  Then, in your `gitlab.rb` file on the deploy node, update
  `gitlab_rails['db_host']` and `gitlab_rails['db_port']` with the database
  leader's host and port.

- To get the regular database migrations and latest code in place, run

  ```shell
  sudo gitlab-ctl reconfigure
  sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-rake db:migrate
  ```

**All nodes _excluding_ the Deploy node**

- [Upgrade the GitLab package](package/index.md#upgrade-to-a-specific-version-using-the-official-repositories).

- Ensure nodes are running the latest code

  ```shell
  sudo gitlab-ctl reconfigure
  ```

**Deploy node**

- Run post-deployment database migrations on deploy node to complete the migrations with

  ```shell
  sudo gitlab-rake db:migrate
  ```

**For nodes that run Puma or Sidekiq**

- Hot reload `puma` and `sidekiq` services

  ```shell
  sudo gitlab-ctl hup puma
  sudo gitlab-ctl restart sidekiq
  ```

- If you're using PgBouncer:

  Change your `gitlab.rb` to point back to PgBouncer and run:

  ```shell
  sudo gitlab-ctl reconfigure
  ```

If you do not want to run zero downtime upgrades in the future, make
sure you remove `/etc/gitlab/skip-auto-reconfigure` and revert
setting `gitlab_rails['auto_migrate'] = false` in
`/etc/gitlab/gitlab.rb` after you've completed these steps.

### Redis HA (using Sentinel) **(PREMIUM SELF)**

Package upgrades may involve version updates to the bundled Redis service. On
instances using [Redis for scaling](../administration/redis/index.md),
upgrades must follow a proper order to ensure minimum downtime, as specified
below. This doc assumes the official guides are being followed to setup Redis
HA.

#### In the application node

According to [official Redis documentation](https://redis.io/docs/management/admin/#upgrading-or-restarting-a-redis-instance-without-downtime),
the easiest way to update an HA instance using Sentinel is to upgrade the
secondaries one after the other, perform a manual failover from current
primary (running old version) to a recently upgraded secondary (running a new
version), and then upgrade the original primary. For this, we must know
the address of the current Redis primary.

- If your application node is running GitLab 12.7.0 or later, you can use the
following command to get address of current Redis primary

  ```shell
  sudo gitlab-ctl get-redis-master
  ```

- If your application node is running a version older than GitLab 12.7.0, you
  have to run the underlying `redis-cli` command (which `get-redis-master`
  command uses) to fetch information about the primary.

  1. Get the address of one of the sentinel nodes specified as
     `gitlab_rails['redis_sentinels']` in `/etc/gitlab/gitlab.rb`

  1. Get the Redis main name specified as `redis['master_name']` in
     `/etc/gitlab/gitlab.rb`

  1. Run the following command

     ```shell
     sudo /opt/gitlab/embedded/bin/redis-cli -h <sentinel host> -p <sentinel port> SENTINEL get-master-addr-by-name <redis master name>
     ```

#### In the Redis secondary nodes

1. Set `gitlab_rails['rake_cache_clear'] = false` in `gitlab.rb` if you haven't already. If not, you might receive the error `Redis::CommandError: READONLY You can't write against a read only replica.` during the reconfigure post installation of new package.

1. Install package for new version.

1. Run `sudo gitlab-ctl reconfigure`, if a reconfigure is not run as part of
   installation (due to `/etc/gitlab/skip-auto-reconfigure` file being present).

1. If reconfigure warns about a pending Redis/Sentinel restart, restart the
   corresponding service

   ```shell
   sudo gitlab-ctl restart redis
   sudo gitlab-ctl restart sentinel
   ```

#### In the Redis primary node

Before upgrading the Redis primary node, we must perform a failover so that
one of the recently upgraded secondary nodes becomes the new primary. After the
failover is complete, we can go ahead and upgrade the original primary node.

1. Stop Redis service in Redis primary node so that it fails over to a secondary
   node

   ```shell
   sudo gitlab-ctl stop redis
   ```

1. Wait for failover to be complete. You can verify it by periodically checking
   details of the current Redis primary node (as mentioned above). If it starts
   reporting a new IP, failover is complete.

1. Start Redis again in that node, so that it starts following the current
   primary node.

   ```shell
   sudo gitlab-ctl start redis
   ```

1. Install package corresponding to new version.

1. Run `sudo gitlab-ctl reconfigure`, if a reconfigure is not run as part of
   installation (due to `/etc/gitlab/skip-auto-reconfigure` file being present).

1. If reconfigure warns about a pending Redis/Sentinel restart, restart the
   corresponding service

   ```shell
   sudo gitlab-ctl restart redis
   sudo gitlab-ctl restart sentinel
   ```

#### Update the application node

Install the package for new version and follow regular package upgrade
procedure.

## Geo deployment **(PREMIUM SELF)**

WARNING:
You can only upgrade one minor release at a time.

The order of steps is important. While following these steps, make
sure you follow them in the right order, on the correct node.

### Update the Geo primary site

Log in to your **primary** node, executing the following:

1. Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. This prevents upgrades from running `gitlab-ctl reconfigure`, which by default automatically stops GitLab, runs all database migrations, and restarts GitLab:

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

1. Edit `/etc/gitlab/gitlab.rb` and ensure the following is present:

   ```ruby
   gitlab_rails['auto_migrate'] = false
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. [Upgrade the GitLab package](package/index.md#upgrade-to-a-specific-version-using-the-official-repositories).

1. To get the database migrations and latest code in place, run:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. After the node is updated and reconfigure finished successfully, complete the migrations:

   ```shell
   sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-rake db:migrate
   ```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from the primary site to the secondary site if they're different.
   The file must be the same on all of a site's nodes.

### Update the Geo secondary site

On each **secondary** node, executing the following:

1. Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. This prevents upgrades from running `gitlab-ctl reconfigure`, which by default automatically stops GitLab, runs all database migrations, and restarts GitLab.

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

1. Edit `/etc/gitlab/gitlab.rb` and ensure the following is present:

   ```ruby
   gitlab_rails['auto_migrate'] = false
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. [Upgrade the GitLab package](package/index.md#upgrade-to-a-specific-version-using-the-official-repositories).

1. To get the database migrations and latest code in place, run:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Run post-deployment database migrations, specific to the Geo database:

   ```shell
   sudo gitlab-rake db:migrate:geo
   ```

### Finalize the update

After all **secondary** nodes are updated, finalize
the update on the **primary** node:

- Run post-deployment database migrations

   ```shell
   sudo gitlab-rake db:migrate
   ```

- After the update is finalized on the primary node, hot reload `puma` and
restart `sidekiq` and `geo-logcursor` services on **all primary and secondary**
nodes:

   ```shell
   sudo gitlab-ctl hup puma
   sudo gitlab-ctl restart sidekiq
   sudo gitlab-ctl restart geo-logcursor
   ```

After updating all nodes (both **primary** and all **secondaries**), check their status:

- Verify Geo configuration and dependencies

   ```shell
   sudo gitlab-rake gitlab:geo:check
   ```

If you do not want to run zero downtime upgrades in the future, make
sure you remove `/etc/gitlab/skip-auto-reconfigure` and revert
setting `gitlab_rails['auto_migrate'] = false` in
`/etc/gitlab/gitlab.rb` after you've completed these steps.

## Multi-node / HA deployment with Geo **(PREMIUM SELF)**

WARNING:
You can only upgrade one minor release at a time. You also must first start with the Gitaly cluster, updating Gitaly one node one at a time. This will ensure access to the Git repositories for the remainder of the upgrade process.

This section describes the steps required to upgrade a multi-node / HA
deployment with Geo. Some steps must be performed on a particular node. This
node is known as the "deploy node" and is noted through the following
instructions.

Updates must be performed in the following order:

1. Update Geo **primary** multi-node deployment.
1. Update Geo **secondary** multi-node deployments.
1. Post-deployment migrations and checks.

### Step 1: Choose a "deploy node" for each deployment

You now must choose:

- One instance for use as the **primary** "deploy node" on the Geo **primary** multi-node deployment.
- One instance for use as the **secondary** "deploy node" on each Geo **secondary** multi-node deployment.

Deploy nodes must be configured to be running Puma or Sidekiq or the `geo-logcursor` daemon. In order
to avoid any downtime, they must not be in use during the update:

- If running Puma remove the deploy node from the load balancer.
- If running Sidekiq, ensure the deploy node is not processing jobs:

  ```shell
  sudo gitlab-ctl stop sidekiq
  ```

- If running `geo-logcursor` daemon, ensure the deploy node is not processing events:

  ```shell
  sudo gitlab-ctl stop geo-logcursor
  ```

For zero-downtime, Puma, Sidekiq, and `geo-logcursor` must be running on other nodes during the update.

### Step 2: Update the Geo primary multi-node deployment

**On all primary nodes _including_ the primary "deploy node"**

1. Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. This prevents upgrades from running `gitlab-ctl reconfigure`, which by default automatically stops GitLab, runs all database migrations, and restarts GitLab.

```shell
sudo touch /etc/gitlab/skip-auto-reconfigure
```

1. To prevent `reconfigure` from automatically running database migrations, ensure that `gitlab_rails['auto_migrate'] = false` is set in `/etc/gitlab/gitlab.rb`.

1. Ensure nodes are running the latest code

   ```shell
   sudo gitlab-ctl reconfigure
   ```

**On primary Gitaly only nodes**

1. [Upgrade the GitLab package](package/index.md#upgrade-to-a-specific-version-using-the-official-repositories).

1. Ensure nodes are running the latest code

   ```shell
   sudo gitlab-ctl reconfigure
   ```

**On the primary "deploy node"**

1. [Upgrade the GitLab package](package/index.md#upgrade-to-a-specific-version-using-the-official-repositories).

1. If you're using PgBouncer:

   You must [bypass PgBouncer](../administration/postgresql/pgbouncer.md#procedure-for-bypassing-pgbouncer) and connect directly to the database leader
   before running migrations.

   Rails uses an advisory lock when attempting to run a migration to prevent
   concurrent migrations from running on the same database. These locks are
   not shared across transactions, resulting in `ActiveRecord::ConcurrentMigrationError`
   and other issues when running database migrations using PgBouncer in transaction
   pooling mode.

   To find the leader node, run the following on a database node:

   ```shell
   sudo gitlab-ctl patroni members
   ```

   Then, in your `gitlab.rb` file on the deploy node, update
   `gitlab_rails['db_host']` and `gitlab_rails['db_port']` with the database
   leader's host and port.

1. To get the regular database migrations and latest code in place, run

   ```shell
   sudo gitlab-ctl reconfigure
   sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-rake db:migrate
   ```

1. If this deploy node is used to serve requests or process jobs,
   then you may return it to service at this point.

   - To serve requests, add the deploy node to the load balancer.
   - To process Sidekiq jobs again, start Sidekiq:

     ```shell
     sudo gitlab-ctl start sidekiq
     ```

**On all primary nodes _excluding_ the primary "deploy node"**

1. [Upgrade the GitLab package](package/index.md#upgrade-to-a-specific-version-using-the-official-repositories).

1. Ensure nodes are running the latest code

   ```shell
   sudo gitlab-ctl reconfigure
   ```

**For all primary nodes that run Puma or Sidekiq _including_ the primary "deploy node"**

Hot reload `puma` and `sidekiq` services:

```shell
sudo gitlab-ctl hup puma
sudo gitlab-ctl restart sidekiq
```

1. Copy the `/etc/gitlab/gitlab-secrets.json` file from the primary site to the secondary site if they're different. The
   file must be the same on all of a site's nodes.

### Step 3: Update each Geo secondary multi-node deployment

Only proceed if you have successfully completed all steps on the Geo **primary** multi-node deployment.

**On all secondary nodes _including_ the secondary "deploy node"**

1. Create an empty file at `/etc/gitlab/skip-auto-reconfigure`. This prevents upgrades from running `gitlab-ctl reconfigure`, which by default automatically stops GitLab, runs all database migrations, and restarts GitLab.

```shell
sudo touch /etc/gitlab/skip-auto-reconfigure
```

1. To prevent `reconfigure` from automatically running database migrations, ensure that `geo_secondary['auto_migrate'] = false` is set in `/etc/gitlab/gitlab.rb`.

1. Ensure nodes are running the latest code

   ```shell
   sudo gitlab-ctl reconfigure
   ```

**On secondary Gitaly only nodes**

1. [Upgrade the GitLab package](package/index.md#upgrade-to-a-specific-version-using-the-official-repositories).

1. Ensure nodes are running the latest code

   ```shell
   sudo gitlab-ctl reconfigure
   ```

**On the secondary "deploy node"**

1. [Upgrade the GitLab package](package/index.md#upgrade-to-a-specific-version-using-the-official-repositories).

1. To get the regular database migrations and latest code in place, run

   ```shell
   sudo gitlab-ctl reconfigure
   sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-rake db:migrate:geo
   ```

1. If this deploy node is used to serve requests or perform
   background processing, then you may return it to service at this point.

   - To serve requests, add the deploy node to the load balancer.
   - To process Sidekiq jobs again, start Sidekiq:

     ```shell
     sudo gitlab-ctl start sidekiq
     ```

   - To process Geo events again, start the `geo-logcursor` daemon:

     ```shell
     sudo gitlab-ctl start geo-logcursor
     ```

**On all secondary nodes _excluding_ the secondary "deploy node"**

1. [Upgrade the GitLab package](package/index.md#upgrade-to-a-specific-version-using-the-official-repositories).

1. Ensure nodes are running the latest code

   ```shell
   sudo gitlab-ctl reconfigure
   ```

**For all secondary nodes that run Puma, Sidekiq, or the `geo-logcursor` daemon _including_ the secondary "deploy node"**

Hot reload `puma`, `sidekiq` and ``geo-logcursor`` services:

```shell
sudo gitlab-ctl hup puma
sudo gitlab-ctl restart sidekiq
sudo gitlab-ctl restart geo-logcursor
```

### Step 4: Run post-deployment migrations and checks

**On the primary "deploy node"**

1. Run post-deployment database migrations:

   ```shell
   sudo gitlab-rake db:migrate
   ```

1. Verify Geo configuration and dependencies

   ```shell
   sudo gitlab-rake gitlab:geo:check
   ```

1. If you're using PgBouncer:

   Change your `gitlab.rb` to point back to PgBouncer and run:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

**On all secondary "deploy nodes"**

1. Run post-deployment database migrations, specific to the Geo database:

   ```shell
   sudo gitlab-rake db:migrate:geo
   ```

1. Verify Geo configuration and dependencies

   ```shell
   sudo gitlab-rake gitlab:geo:check
   ```

1. Verify Geo status

   ```shell
   sudo gitlab-rake geo:status
   ```
