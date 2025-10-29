---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Upgrade a multi-node instance with downtime
description: Upgrade a multi-node Linux package-based or cloud-native instance with downtime.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

To upgrade a multi-node GitLab instance with downtime:

1. Shut down the GitLab application.
1. Upgrade Consul servers.
1. Upgrade Gitaly, Rails, PostgreSQL, Redis, and PgBouncer in any order. If you use PostgreSQL or Redis from your cloud
   platform and upgrades are required, substitute these instructions for your cloud provider's instructions.
1. Upgrade the GitLab application (Sidekiq, Puma) and start the application.

Before you begin an upgrade with downtime, [consider your downtime options](downtime_options.md).

## Shut down the GitLab application

Before upgrading, you must stop writes to the database by shutting down the GitLab application. The process is different
depending on your [installation method](../administration/reference_architectures/_index.md).

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Shut down Puma and Sidekiq on all servers running these processes:

```shell
sudo gitlab-ctl stop sidekiq
sudo gitlab-ctl stop puma
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

For [Helm chart](../administration/reference_architectures/_index.md#cloud-native-hybrid) instances:

1. Note the current number of replicas for database clients for subsequent restart:

```shell
kubectl get deploy -n <namespace> -l release=<helm release name> -l 'app in (prometheus,webservice,sidekiq)' -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.replicas}{"\n"}{end}'
```

1. Stop the clients of the database:

```shell
kubectl scale deploy -n <namespace> -l release=<helm release name> -l 'app in (prometheus,webservice,sidekiq)' --replicas=0
```

{{< /tab >}}

{{< /tabs >}}

## Upgrade the Consul nodes

Follow instructions for [upgrading the Consul nodes](../administration/consul.md#upgrade-the-consul-nodes). In summary:

1. Check the Consul nodes are all healthy.
1. Upgrade all Consul servers by [upgrading with the Linux package](package/_index.md#upgrade-with-the-linux-package).
1. Restart all GitLab services **one node at a time**:

   ```shell
   sudo gitlab-ctl restart
   ```

Your Consul cluster processes might not be on their own servers and are shared with another service such as Redis HA or
Patroni. In this case, when upgrading those servers:

- Restart services on only one server at a time.
- Check the Consul cluster is healthy before upgrading or restarting services.

## Upgrade Gitaly and Gitaly Cluster (Praefect)

For Gitaly servers that are not part of Gitaly Cluster (Praefect), upgrade the server
by [upgrading with the Linux package](package/_index.md#upgrade-with-the-linux-package).
If you have multiple Gitaly shards, you can upgrade the Gitaly servers in any order.

If you're running Gitaly Cluster (Praefect), follow the
[zero-downtime upgrade process for Gitaly Cluster (Praefect)](zero_downtime.md#upgrade-gitaly-cluster-praefect-nodes).

### When using Amazon Machine Images

If you are using Amazon Machine Images (AMIs) on AWS, you can upgrade the Gitaly nodes using an AMI redeployment process.
To use this process, you must use [Elastic network interfaces (ENIs)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html).
Gitaly Cluster (Praefect) tracks replicas of Git repositories by the server hostname. ENIs can ensure the private DNS
name stays the same when the instance is redeployed. If the nodes are redeployed with new hostnames, even if the storage is
the same, Gitaly Cluster (Praefect) cannot work.

If you are not using ENIs, you must upgrade the Gitaly nodes by using the Linux package.

To upgrade Gitaly Cluster (Praefect) nodes by using an AMI redeployment process:

1. The AMI redeployment process must include `gitlab-ctl reconfigure`. Set `praefect['auto_migrate'] = false` on the AMI
   so all nodes get this. This setting prevents `reconfigure` from automatically running database migrations.
1. The first node to be redeployed with the upgraded image should be your deploy node.
1. After it's deployed, set `praefect['auto_migrate'] = true` in `gitlab.rb` and apply with `gitlab-ctl reconfigure`.
1. This command runs the database migrations.
1. Redeploy your other Gitaly Cluster (Praefect) nodes.

## Upgrade the PostgreSQL nodes

For non-clustered PostgreSQL servers:

1. Upgrade the server by [upgrading with the Linux package](package/_index.md#upgrade-with-the-linux-package).
1. Because the upgrade process does not restart PostgreSQL when the binaries are upgraded, restart to load the new version:

   ```shell
   sudo gitlab-ctl restart
   ```

### Upgrade Patroni nodes

Patroni is used to achieve high availability with PostgreSQL.

If a PostgreSQL major version upgrade is required,
[follow the major version process](../administration/postgresql/replication_and_failover.md#upgrading-postgresql-major-version-in-a-patroni-cluster).

The upgrade process for all other versions is performed on all replicas first. After the replicas are upgraded, a
cluster failover occurs from the leader to one of the upgraded replicas. This process ensures that only one failover is
needed and, once complete, the new leader is upgraded.

To upgrade Patroni nodes:

1. Identify the leader and replica nodes, and
   [verify that the cluster is healthy](../administration/postgresql/replication_and_failover.md#check-replication-status).
   On a database node, run:

   ```shell
   sudo gitlab-ctl patroni members
   ```

1. Upgrade one of the replica nodes by [upgrading with the Linux package](package/_index.md#upgrade-with-the-linux-package).
1. Restart to load the new version:

   ```shell
   sudo gitlab-ctl restart
   ```

1. [Verify that the cluster is healthy](../administration/postgresql/replication_and_failover.md#check-replication-status).
1. Repeat the upgrade, restart, and health check steps for the other replicas.
1. Upgrade the leader node following the same Linux package upgrade as the replicas.
1. Restart all services on the leader node to load the new version and also trigger a cluster failover:

   ```shell
   sudo gitlab-ctl restart
   ```

1. [Check the cluster is healthy](../administration/postgresql/replication_and_failover.md#check-replication-status)

## Upgrade the PgBouncer nodes

If you run PgBouncer on your GitLab application (Rails) nodes, then PgBouncer is upgraded as part of the
application server upgrade. Otherwise, upgrade the PgBouncer nodes by
[upgrading with the Linux package](package/_index.md#upgrade-with-the-linux-package).

## Upgrade the Redis node

To upgrade a standalone Redis server, [upgrade with the Linux package](package/_index.md#upgrade-with-the-linux-package).

### Upgrade Redis HA (using Sentinel)

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

If you use Redis HA, follow [the zero-downtime instructions](zero_downtime.md) for upgrading your Redis HA cluster.

## Upgrade the GitLab application components

The process for upgrading the GitLab application depends on your installation method.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

All the Puma and Sidekiq processes were previously shut down. On each GitLab application node:

1. Ensure `/etc/gitlab/skip-auto-reconfigure` does not exist.
1. Check that Puma and Sidekiq are shut down:

   ```shell
   ps -ef | egrep 'puma: | puma | sidekiq '
   ```

Select one node that runs Puma as your deploy node that is responsible for running all database migrations. On the
deploy node:

1. Ensure the server is configured to permit regular migrations. Check that
   `/etc/gitlab/gitlab.rb` does not contain `gitlab_rails['auto_migrate'] = false`.
   Either set it specifically `gitlab_rails['auto_migrate'] = true` or omit it
   for the default behavior (`true`).

1. If you're using PgBouncer, you must bypass PgBouncer and connect directly to PostgreSQL before running migrations.

   Rails uses an advisory lock when attempting to run a migration to prevent
   concurrent migrations from running on the same database. These locks are
   not shared across transactions, resulting in `ActiveRecord::ConcurrentMigrationError` errors
   and other issues when running database migrations using PgBouncer in transaction
   pooling mode.

   1. If you're running Patroni, find the leader node. Run on a database node:

      ```shell
      sudo gitlab-ctl patroni members
      ```

   1. Update `gitlab.rb` on the deploy node. Change `gitlab_rails['db_host']`
      and `gitlab_rails['db_port']` to either:

      - The host and port for your database server (non-clustered PostgreSQL).
      - The host and port for your cluster leader if you're running Patroni.

   1. Apply the changes:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

1. Upgrade GitLab by [upgrading with the Linux package](package/_index.md#upgrade-with-the-linux-package).
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

1. Upgrade GitLab by [upgrading with the Linux package](package/_index.md#upgrade-with-the-linux-package).
1. Ensure all services are restarted:

   ```shell
   sudo gitlab-ctl restart
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

After all stateful components are upgraded, follow
[GitLab chart upgrade steps](https://docs.gitlab.com/charts/installation/upgrade.html)
to upgrade the stateless components (Webservice, Sidekiq, other supporting services).

After you perform the GitLab chart upgrade, resume the database clients:

```shell
kubectl scale deploy -lapp=sidekiq,release=<helm release name> -n <namespace> --replicas=<value>
kubectl scale deploy -lapp=webservice,release=<helm release name> -n <namespace> --replicas=<value>
kubectl scale deploy -lapp=prometheus,release=<helm release name> -n <namespace> --replicas=<value>
```

{{< /tab >}}

{{< /tabs >}}

## Upgrade the monitor node

You might have configured Prometheus to act as a standalone monitoring node. For example, as part of
[configuring a 60 RPS or 3,000 users reference architecture](../administration/reference_architectures/3k_users.md#configure-prometheus).

To upgrade the monitor node, [upgrade with the Linux package](package/_index.md#upgrade-with-the-linux-package).
