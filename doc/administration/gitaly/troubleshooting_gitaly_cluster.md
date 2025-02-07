---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting Gitaly Cluster
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Refer to the information below when troubleshooting Gitaly Cluster (Praefect). For information on troubleshooting Gitaly,
see [Troubleshooting Gitaly](troubleshooting.md).

## Check cluster health

The `check` Praefect sub-command runs a series of checks to determine the health of the Gitaly Cluster.

```shell
gitlab-ctl praefect check
```

If Praefect is deployed by using the Praefect chart, run the binary directly.

```shell
/usr/local/bin/praefect check
```

The following sections describe the checks that are run.

### Praefect migrations

Because Database migrations must be up to date for Praefect to work correctly, checks if Praefect migrations are up to date.

If this check fails:

1. See the `schema_migrations` table in the database to see which migrations have run.
1. Run `praefect sql-migrate` to bring the migrations up to date.

### Node connectivity and disk access

Checks if Praefect can reach all of its Gitaly nodes, and if each Gitaly node has read and write access to all of its storages.

If this check fails:

1. Confirm the network addresses and tokens are set up correctly:
   - In the Praefect configuration.
   - In each Gitaly node's configuration.
1. On the Gitaly nodes, check that the `gitaly` process being run as `git`. There might be a permissions issue that is preventing Gitaly from
   accessing its storage directories.
1. Confirm that there are no issues with the network that connects Praefect to Gitaly nodes.

### Database read and write access

Checks if Praefect can read from and write to the database.

If this check fails:

1. See if the Praefect database is in recovery mode. In recovery mode, tables may be read only. To check, run:

   ```sql
   select pg_is_in_recovery()
   ```

1. Confirm that the user that Praefect uses to connect to PostgreSQL has read and write access to the database.
1. See if the database has been placed into read-only mode. To check, run:

   ```sql
   show default_transaction_read_only
   ```

### Inaccessible repositories

Checks how many repositories are inaccessible because they are missing a primary assignment, or their primary is unavailable.

If this check fails:

1. See if any Gitaly nodes are down. Run `praefect ping-nodes` to check.
1. Check if there is a high load on the Praefect database. If the Praefect database is slow to respond, it can lead health checks failing to persist
   to the database, leading Praefect to think nodes are unhealthy.

## Praefect errors in logs

If you receive an error, check `/var/log/gitlab/gitlab-rails/production.log`.

Here are common errors and potential causes:

- 500 response code
  - `ActionView::Template::Error (7:permission denied)`
    - `praefect['configuration'][:auth][:token]` and `gitlab_rails['gitaly_token']` do not match on the GitLab server.
    - `gitlab_rails['repositories_storages']` storage configuration is missing on the Sidekiq server.
  - `Unable to save project. Error: 7:permission denied`
    - Secret token in `praefect['configuration'][:virtual_storage]` on GitLab server does not match the
      value in `gitaly['auth_token']` on one or more Gitaly servers.
- 503 response code
  - `GRPC::Unavailable (14:failed to connect to all addresses)`
    - GitLab was unable to reach Praefect.
  - `GRPC::Unavailable (14:all SubCons are in TransientFailure...)`
    - Praefect cannot reach one or more of its child Gitaly nodes. Try running
      the Praefect connection checker to diagnose.

## Praefect database experiencing high CPU load

Some common reasons for the Praefect database to experience elevated CPU usage include:

- Prometheus metrics scrapes [running an expensive query](https://gitlab.com/gitlab-org/gitaly/-/issues/3796). Set
  `praefect['configuration'][:prometheus_exclude_database_from_default_metrics] = true` in `gitlab.rb`.
- [Read distribution caching](praefect.md#reads-distribution-caching) is disabled, increasing the number of queries made to the
  database when user traffic is high. Ensure read distribution caching is enabled.

## Determine primary Gitaly node

To determine the primary node of a repository, use the [`praefect metadata`](#view-repository-metadata) subcommand.

## View repository metadata

Gitaly Cluster maintains a [metadata database](_index.md#components) about the repositories stored on the cluster. Use the `praefect metadata` subcommand
to inspect the metadata for troubleshooting.

You can retrieve a repository's metadata by its Praefect-assigned repository ID:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml metadata -repository-id <repository-id>
```

When the physical path on the physical storage starts with `@cluster`, you can
[find the repository ID in the physical path](_index.md#praefect-generated-replica-paths).

You can also retrieve a repository's metadata by its virtual storage and relative path:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml metadata -virtual-storage <virtual-storage> -relative-path <relative-path>
```

### Examples

To retrieve the metadata for a repository with a Praefect-assigned repository ID of 1:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml metadata -repository-id 1
```

To retrieve the metadata for a repository with virtual storage `default` and relative path `@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git`:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml metadata -virtual-storage default -relative-path @hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git
```

Either of these examples retrieve the following metadata for an example repository:

```plaintext
Repository ID: 54771
Virtual Storage: "default"
Relative Path: "@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git"
Replica Path: "@hashed/b1/7e/b17ef6d19c7a5b1ee83b907c595526dcb1eb06db8227d650d5dda0a9f4ce8cd9.git"
Primary: "gitaly-1"
Generation: 1
Replicas:
- Storage: "gitaly-1"
  Assigned: true
  Generation: 1, fully up to date
  Healthy: true
  Valid Primary: true
  Verified At: 2021-04-01 10:04:20 +0000 UTC
- Storage: "gitaly-2"
  Assigned: true
  Generation: 0, behind by 1 changes
  Healthy: true
  Valid Primary: false
  Verified At: unverified
- Storage: "gitaly-3"
  Assigned: true
  Generation: replica not yet created
  Healthy: false
  Valid Primary: false
  Verified At: unverified
```

### Available metadata

The metadata retrieved by `praefect metadata` includes the fields in the following tables.

| Field             | Description                                                                                                        |
|:------------------|:-------------------------------------------------------------------------------------------------------------------|
| `Repository ID`   | Permanent unique ID assigned to the repository by Praefect. Different to the ID GitLab uses for repositories.      |
| `Virtual Storage` | Name of the virtual storage the repository is stored in.                                                           |
| `Relative Path`   | Repository's path in the virtual storage.                                                                          |
| `Replica Path`    | Where on the Gitaly node's disk the repository's replicas are stored.                                                |
| `Primary`         | Current primary of the repository.                                                                                 |
| `Generation`      | Used by Praefect to track repository changes. Each write in the repository increments the repository's generation. |
| `Replicas`        | A list of replicas that exist or are expected to exist.                                                            |

For each replica, the following metadata is available:

| `Replicas` Field | Description                                                                                                                                                                                                                                                                                                                                                                                                                                            |
|:-----------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `Storage`        | Name of the Gitaly storage that contains the replica.                                                                                                                                                                                                                                                                                                                                                                                                  |
| `Assigned`       | Indicates whether the replica is expected to exist in the storage. Can be `false` if a Gitaly node is removed from the cluster or if the storage contains an extra copy after the repository's replication factor was decreased.                                                                                                                                                                                                                       |
| `Generation`     | Latest confirmed generation of the replica. It indicates:<br><br>- The replica is fully up to date if the generation matches the repository's generation.<br>- The replica is outdated if the replica's generation is less than the repository's generation.<br>- `replica not yet created` if the replica does not yet exist at all on the storage.                                                                                                          |
| `Healthy`        | Indicates whether the Gitaly node that is hosting this replica is considered healthy by the consensus of Praefect nodes.                                                                                                                                                                                                                                                                                                                               |
| `Valid Primary`  | Indicates whether the replica is fit to serve as the primary node. If the repository's primary is not a valid primary, a failover occurs on the next write to the repository if there is another replica that is a valid primary. A replica is a valid primary if:<br><br>- It is stored on a healthy Gitaly node.<br>- It is fully up to date.<br>- It is not targeted by a pending deletion job from decreasing replication factor.<br>- It is assigned. |
| `Verified At` | Indicates last successful verification of the replica by the [verification worker](praefect.md#repository-verification). If the replica has not yet been verified, `unverified` is displayed in place of the last successful verification time. Introduced in GitLab 15.0. |

### Command fails with 'repository not found'

If the supplied value for `-virtual-storage` is incorrect, the command returns the following error:

```plaintext
get metadata: rpc error: code = NotFound desc = repository not found
```

The documented examples specify `-virtual-storage default`. Check the Praefect server setting `praefect['configuration'][:virtual_storage]` in `/etc/gitlab/gitlab.rb`.

## Check that repositories are in sync

Is [some cases](_index.md#known-issues) the Praefect database can get out of sync with the underlying Gitaly nodes. To check that
a given repository is fully synced on all nodes, run the [`gitlab:praefect:replicas` Rake task](../raketasks/praefect.md#replica-checksums) on your Rails node.
This Rake task checksums the repository on all Gitaly nodes.

The [Praefect `dataloss`](recovery.md#check-for-data-loss) command only checks the state of the repository in the Praefect database, and cannot
be relied to detect sync problems in this scenario.

### `dataloss` command shows `@failed-geo-sync` repositories as out of sync

`@failed-geo-sync` is a legacy path that was used on GitLab 16.1 and earlier by Geo when project synchronization failed and has been
[deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/375640).

On GitLab 16.2 and later, you can safely delete this path. The `@failed-geo-sync` directories are located under [the repository path](../repository_storage_paths.md) on the Gitaly nodes.

## Relation does not exist errors

By default Praefect database tables are created automatically by `gitlab-ctl reconfigure` task.

However, the Praefect database tables are not created on initial reconfigure and can throw
errors that relations do not exist if either:

- The `gitlab-ctl reconfigure` command isn't executed.
- Errors occur during the execution.

For example:

- `ERROR:  relation "node_status" does not exist at character 13`
- `ERROR:  relation "replication_queue_lock" does not exist at character 40`
- This error:

  ```json
  {"level":"error","msg":"Error updating node: pq: relation \"node_status\" does not exist","pid":210882,"praefectName":"gitlab1x4m:0.0.0.0:2305","time":"2021-04-01T19:26:19.473Z","virtual_storage":"praefect-cluster-1"}
  ```

To solve this, the database schema migration can be done using `sql-migrate` sub-command of
the `praefect` command:

```shell
$ sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml sql-migrate
praefect sql-migrate: OK (applied 21 migrations)
```

## Requests fail with 'repository scoped: invalid Repository' errors

This indicates that the virtual storage name used in the
[Praefect configuration](praefect.md#praefect) does not match the storage name used in
[`gitaly['configuration'][:storage][<index>][:name]` setting](praefect.md#gitaly) for GitLab.

Resolve this by matching the virtual storage names used in Praefect and GitLab configuration.

## Gitaly Cluster performance issues on cloud platforms

Praefect does not require a lot of CPU or memory, and can run on small virtual machines.
Cloud services may place other limits on the resources that small VMs can use, such as
disk IO and network traffic.

Praefect nodes generate a lot of network traffic. The following symptoms can be observed if their network bandwidth has
been throttled by the cloud service:

- Poor performance of Git operations.
- High network latency.
- High memory use by Praefect.

Possible solutions:

- Provision larger VMs to gain access to larger network traffic allowances.
- Use your cloud service's monitoring and logging to check that the Praefect nodes are not exhausting their traffic allowances.

## `gitlab-ctl reconfigure` fails with a Praefect configuration error

If `gitlab-ctl reconfigure` fails, you might see this error:

```plaintext
STDOUT: praefect: configuration error: error reading config file: toml: cannot store TOML string into a Go int
```

This error occurs when `praefect['database_port']` or `praefect['database_direct_port']` are configured as a string instead of an integer.

## Common replication errors

The following are some common replication errors with possible solutions.

### Lock file exists

Lock files are used to prevent multiple updates to the same ref. Sometimes lock files become stale, and replication fails with the error `error: cannot lock ref`.

To clear stale `*.lock` files, you can trigger `OptimizeRepositoryRequest` on the [Rails console](../operations/rails_console.md):

```ruby
p = Project.find <Project ID>
client = Gitlab::GitalyClient::RepositoryService.new(p.repository)
client.optimize_repository
```

If triggering `OptimizeRepositoryRequest` does not work, inspect the files manually to confirm the creation date and decide if the `*.lock` file can be manually removed.
Any lock files created over 24 hours ago are safe to remove.

### Git `fsck` errors

Gitaly repositories with invalid objects can lead to replication failures with errors in Gitaly logs such as:

- `exit status 128, stderr: "fatal: git upload-pack: not our ref"`.
- `"fatal: bad object 58....e0f... ssh://gitaly/internal.git did not send all necessary objects`.

As long one of the Gitaly nodes still has a healthy copy of the repository, these issues can be fixed by:

1. [Removing the repository from the Praefect database](recovery.md#manually-remove-repositories).
1. Using the [Praefect `track-repository` subcommand](recovery.md#manually-add-a-single-repository-to-the-tracking-database) to re-track it.

This will use the copy of the repository from the authoritative Gitaly node to overwrite the copies on all other Gitaly nodes.
Be sure a recent backup of the repository has been made before running these commands.

1. Move the bad repository out of place:

   ```shell
   run `mv <REPOSITORY_PATH> <REPOSITORY_PATH>.backup`
   ```

   For example:

   ```shell
   mv /var/opt/gitlab/git-data/repositories/@cluster/repositories/de/74/2335 /var/opt/gitlab/git-data/repositories/@cluster/repositories/de/74/2335.backup
   ```

1. Run the Praefect commands to trigger replication:

   ```shell
   # Validate you have the correct repository.
   sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml remove-repository -virtual-storage gitaly -relative-path '<relative_path>' -db-only

   # Run again with '--apply' flag to remove repository from the Praefect tracking database
   sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml remove-repository -virtual-storage gitaly -relative-path '<relative_path>' -db-only --apply

   # Re-track the repository, overwriting the secondary nodes
   sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml track-repository -virtual-storage gitaly -authoritative-storage '<healthy_gitaly>' -relative-path '<relative_path>' -replica-path '<replica_path>'-replicate-immediately
   ```

### Replication fails silently

If the [Praefect `dataloss`](recovery.md#check-for-data-loss) shows [repositories partially unavailable](recovery.md#unavailable-replicas-of-available-repositories), and [`accept-dataloss` command](recovery.md#accept-data-loss) fails to synchronize the repository with no error present on the logs, this could be due to a mismatch in Praefect database in the `repository_id` field of the `storage_repositories` table. To check for a mismatch:

1. Connect to the Praefect database.
1. Run the following query:

   ```sql
   select * from storage_repositories where relative_path = '<relative-path>';
   ```

   Replace `<relative-path>` with the repository path [beginning with `@hashed`](../repository_storage_paths.md#hashed-storage).

### Alternate directory does not exists

GitLab uses the [Git alternates mechanism for deduplication](../../development/git_object_deduplication.md). `alternates` is a text file that points to the `objects` directory on
a `@pool` repository to fetch objects. If this file points to an invalid path, replication can fail with one of the following the errors:

- `"error":"no alternates directory exists", "warning","msg":"alternates file does not point to valid git repository"`
- `"error":"unexpected alternates content:`
- `remote: error: unable to normalize alternate object path`

To investigate the cause of this error:

1. Check if the project is part of a pool by using the [Rails console](../operations/rails_console.md):

   ```ruby
   project = Project.find_by_id(<project id>)
   project.pool_repository
   ```

1. Check if the pool repository path exists on disk and that it matches [the `alternates` file](../../development/git_object_deduplication.md) content.
1. Check if the path in the [`alternates` file](../../development/git_object_deduplication.md) is reachable from the `objects` directory in the project.

After performing these checks, reach out to GitLab Support with the information collected.
