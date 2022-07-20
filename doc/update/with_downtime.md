---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Multi-node upgrades with downtime **(FREE SELF)**

NOTE:
This process is a work in progress. You're welcome to provide feedback by either raising a ticket to support,
or [commenting on this issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6244).

While you can upgrade a multi-node GitLab deployment [with zero downtime](zero_downtime.md),
there are a number of constraints. In particular, you can upgrade to only one minor release
at a time, for example, from 14.6 to 14.7, then to 14.8, etc.

If you want to upgrade to more than one minor release at a time (for example, from 14.6 to 14.9),
you must take your GitLab instance offline, which implies downtime.
Before starting this process, verify the
[version specific upgrading instructions](index.md#version-specific-upgrading-instructions)
relevant to your [upgrade path](index.md#upgrade-paths).

For a single node installation, you must only [upgrade the GitLab package](package/index.md).

The process for upgrading a number of components of a multi-node GitLab
installation is the same as for zero downtime upgrades.
The differences relate to the servers running Rails (Puma/Sidekiq) and
the order of events.

At a high level, the process is:

1. Shut down the GitLab application.
1. Upgrade your Consul servers.
1. Upgrade the other back-end components:
   - Gitaly, Rails PostgreSQL, Redis, PgBouncer: these can be upgraded in any order.
   - If you use PostgreSQL or Redis from your cloud platform and upgrades are required,
     substitute the instructions for Omnibus GitLab with your cloud provider's instructions.
1. Upgrade the GitLab application (Sidekiq, Puma) and start the application up.

If you are a Community Edition user, replace `gitlab-ee` with
`gitlab-ce` in the following commands.

## Stop writes to the database

Shut down Puma and Sidekiq on all servers running these processes:

```shell
sudo gitlab-ctl stop sidekiq
sudo gitlab-ctl stop puma
```

## Upgrade the Consul nodes

[Consult the Consul documentation for the complete instructions](../administration/consul.md#upgrade-the-consul-nodes).

In summary:

1. Check the Consul nodes are all healthy.
1. Upgrade the GitLab package on all your Consul servers:

   ```shell
   # Debian/Ubuntu
   sudo apt-get update && sudo apt-get install gitlab-ee

   # Centos/RHEL
   sudo yum install gitlab-ee
   ```

1. Restart all GitLab services **one node at a time**:

   ```shell
   sudo gitlab-ctl restart
   ```

If your Consul cluster processes are not on their own servers, and are shared
with another service such as Redis HA or Patroni, ensure that you follow the
following principles when upgrading those servers:

- Do not restart services more than one server at a time.
- Check the Consul cluster is healthy before upgrading or restarting services.

## Upgrade the Gitaly nodes (Praefect / Gitaly Cluster)

If you're running Gitaly cluster, follow the [zero downtime process](zero_downtime.md#gitaly-or-gitaly-cluster)
for Gitaly cluster.

If you are using Amazon Machine Images (AMIs) on AWS, the Gitaly nodes
**should not be upgraded via the AMI process**. Gitaly nodes should **only**
be upgraded using the package upgrade because:

- Praefect tracks replicas of Git repositories by server hostname.
- Redeployment using AMIs issues the nodes with new hostnames.
- Even though the storage is the same, Gitaly cluster does not work after this.

The Praefect nodes, however, can be upgraded via an AMI redeployment process:

  1. The AMI redeployment process must include `gitlab-ctl reconfigure`.
     Set `praefect['auto_migrate'] = false` on the AMI so all nodes get this. This
     prevents `reconfigure` from automatically running database migrations.
  1. The first node to be redeployed with the upgraded image should be your
     deploy node.
  1. After it's deployed, set `praefect['auto_migrate'] = true` in `gitlab.rb`
     and apply with `gitlab-ctl reconfigure`. This runs the database
     migrations.
  1. Redeploy your other Praefect nodes.

## Upgrade the Gitaly nodes not part of Gitaly cluster

For Gitaly servers which are not part of Gitaly cluster, update the GitLab package:

```shell
# Debian/Ubuntu
sudo apt-get update && sudo apt-get install gitlab-ee

# Centos/RHEL
sudo yum install gitlab-ee
```

If you have multiple Gitaly shards or have multiple load-balanced Gitaly nodes
using NFS, it doesn't matter in which order you upgrade the Gitaly servers.

## Upgrade the PostgreSQL nodes

For unclustered PostgreSQL servers:

1. Upgrade the GitLab package:

   ```shell
   # Debian/Ubuntu
   sudo apt-get update && sudo apt-get install gitlab-ee

   # Centos/RHEL
   sudo yum install gitlab-ee
   ```

1. The upgrade process does not restart PostgreSQL when the binaries are upgraded.
   Restart to load the new version:

   ```shell
   sudo gitlab-ctl restart
   ```

## Upgrade the Patroni node

Patroni is used to achieve high availability with PostgreSQL.

If a PostgreSQL major version upgrade is required,
[follow the major version process](../administration/postgresql/replication_and_failover.md#upgrading-postgresql-major-version-in-a-patroni-cluster).

The upgrade process for all other versions is performed on all replicas first.
After they're upgraded, a cluster failover occurs from the leader to one of the upgraded
replicas. This ensures that only one failover is needed, and once complete the new
leader is upgraded.

Follow the following process:

1. Identify the leader and replica nodes, and [verify that the cluster is healthy](../administration/postgresql/replication_and_failover.md#check-replication-status).
   Run on a database node:

   ```shell
   sudo gitlab-ctl patroni members
   ```

1. Upgrade the GitLab package on one of the replica nodes:

   ```shell
   # Debian/Ubuntu
   sudo apt-get update && sudo apt-get install gitlab-ee

   # Centos/RHEL
   sudo yum install gitlab-ee
   ```

1. Restart to load the new version:

   ```shell
   sudo gitlab-ctl restart
   ```

1. [Verify that the cluster is healthy](../administration/postgresql/replication_and_failover.md#check-replication-status).
1. Repeat these steps for the other replica: upgrade, restart, health check.
1. Upgrade the leader node following the same package upgrade as the replicas.
1. Restart all services on the leader node to load the new version, and also
   trigger a cluster failover:

   ```shell
   sudo gitlab-ctl restart
   ```

1. [Check the cluster is healthy](../administration/postgresql/replication_and_failover.md#check-replication-status)

## Upgrade the PgBouncer nodes

If you run PgBouncer on your Rails (application) nodes, then
PgBouncer are upgraded as part of the application server upgrade.

Upgrade the PgBouncer nodes:

```shell
# Debian/Ubuntu
sudo apt-get update && sudo apt-get install gitlab-ee

# Centos/RHEL
sudo yum install gitlab-ee
```

## Upgrade the Redis node

Upgrade a standalone Redis server by updating the GitLab package:

```shell
# Debian/Ubuntu
sudo apt-get update && sudo apt-get install gitlab-ee

# Centos/RHEL
sudo yum install gitlab-ee
```

## Upgrade Redis HA (using Sentinel) **(PREMIUM SELF)**

Follow [the zero downtime instructions](zero_downtime.md#redis-ha-using-sentinel)
for upgrading your Redis HA cluster.

## Upgrade the Rails nodes (Puma / Sidekiq)

All the Puma and Sidekiq processes were previously shut down. On each node:

1. Ensure `/etc/gitlab/skip-auto-reconfigure` does not exist.
1. Check that Puma and Sidekiq are shut down:

   ```shell
   ps -ef | egrep 'puma: | puma | sidekiq '
   ```

Select one node that runs Puma. This is your deploy node, and is responsible for
running all database migrations. On the deploy node:

1. Ensure the server is configured to permit regular migrations. Check that
   `/etc/gitlab/gitlab.rb` does not contain `gitlab_rails['auto_migrate'] = false`.
   Either set it specifically `gitlab_rails['auto_migrate'] = true` or omit it
   for the default behavior (`true`).

1. If you're using PgBouncer:

   You must bypass PgBouncer and connect directly to PostgreSQL
   before running migrations.

   Rails uses an advisory lock when attempting to run a migration to prevent
   concurrent migrations from running on the same database. These locks are
   not shared across transactions, resulting in `ActiveRecord::ConcurrentMigrationError`
   and other issues when running database migrations using PgBouncer in transaction
   pooling mode.

   1. If you're running Patroni, find the leader node. Run on a database node:

      ```shell
      sudo gitlab-ctl patroni members
      ```

   1. Update `gitlab.rb` on the deploy node. Change `gitlab_rails['db_host']`
      and `gitlab_rails['db_port']` to either:

      - The host and port for your database server (unclustered PostgreSQL).
      - The host and port for your cluster leader if you're running Patroni.

   1. Apply the changes:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

1. Upgrade the GitLab package:

   ```shell
   # Debian/Ubuntu
   sudo apt-get update && sudo apt-get install gitlab-ee

   # Centos/RHEL
   sudo yum install gitlab-ee
   ```

1. If you modified `gitlab.rb` on the deploy node to bypass PgBouncer:
   1. Update `gitlab.rb` on the deploy node. Change `gitlab_rails['db_host']`
      and `gitlab_rails['db_port']` back to your PgBouncer settings.
   1. Apply the changes:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

1. To ensure all services are running the upgraded version, and (if applicable) accessing
   the database using PgBouncer, restart all services on the deploy node:

   ```shell
   sudo gitlab-ctl restart
   ```

Next, upgrade all the other Puma and Sidekiq nodes. The setting `gitlab_rails['auto_migrate']` can be
set to anything in `gitlab.rb` on these nodes.

They can be upgraded in parallel:

1. Upgrade the GitLab package:

   ```shell
   # Debian/Ubuntu
   sudo apt-get update && sudo apt-get install gitlab-ee

   # Centos/RHEL
   sudo yum install gitlab-ee
   ```

1. Ensure all services are restarted:

   ```shell
   sudo gitlab-ctl restart
   ```

## Upgrade the Monitor node

Upgrade the GitLab package:

```shell
# Debian/Ubuntu
sudo apt-get update && sudo apt-get install gitlab-ee

# Centos/RHEL
sudo yum install gitlab-ee
```
