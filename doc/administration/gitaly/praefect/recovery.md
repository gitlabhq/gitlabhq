---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Gitaly Cluster (Praefect) recovery options and tools
---

Gitaly Cluster (Praefect) can recover from primary-node failure and unavailable repositories. Gitaly Cluster (Praefect)
can perform data recovery and has Praefect tracking database tools.

## Manage Gitaly nodes on a Gitaly Cluster (Praefect)

You can add and replace Gitaly nodes on a Gitaly Cluster (Praefect).

### Add new Gitaly nodes

To add a new Gitaly node:

1. Install the new Gitaly node by following the [documentation](configure.md#gitaly).
1. Add the new node to your [Praefect configuration](configure.md#praefect) under `praefect['virtual_storages']`.
1. Reconfigure and restart Praefect by running following commands:

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart praefect
   ```

The replication behavior depends on your replication factor setting.

#### Custom replication factor

If a custom replication factor is set, Praefect doesn't automatically replicate existing repositories to the new Gitaly node. You must set the
[replication factor](configure.md#configure-replication-factor) for each repository using the `set-replication-factor` Praefect command. New repositories are replicated based on
the [replication factor](configure.md#configure-replication-factor).

#### Default replication factor

If the default replication factor is used, Praefect automatically replicates all data to any new Gitaly node added to the configuration to maintain the replication factor.

### Replace an existing Gitaly node

You can replace an existing Gitaly node with a new node that has either the same name or a different name.

#### Replacing primary nodes

Gitaly Cluster (Praefect) elects a primary separately for each repository. When you remove a node that is the
primary for some repositories, the outcome depends on whether an up-to-date replica remains.

If an up-to-date replica exists on a remaining healthy node, the repository stays available.
Reads are served from the up-to-date replica, and Praefect elects a new primary from a valid candidate on
the next request that requires one. Users are not affected.

If no up-to-date replica remains (the removed node held the last current copy), the repository becomes
unavailable. Praefect returns `404` for reads rather than serve a stale copy. The repository stays unavailable
until one of the following restores an up-to-date copy:

- The node is brought back (same name) and re-replicated.
- A replacement node that contains the repository's data becomes available (different name).

Because an unavailable repository has no valid primary candidate to elect, a read cannot recover it: there is
nowhere to route the request. The next write re-establishes a primary by promoting the best available replica (the
one with the fewest unreplicated changes), which can incur data loss for writes that existed only on the removed
node. To avoid this case entirely, ensure every repository on the node has an up-to-date copy on a remaining healthy node before removal.

Gitaly Cluster (Praefect) does not provide a command to manually trigger re-election of a primary. The closest option
is the [`accept-dataloss`](#accept-data-loss) subcommand, which sets a specified storage as the primary for a
relative path and begins replicating from that storage instead of the old primary.

#### Prepare to remove a node

Before you remove the old node, so that every repository it holds has an up-to-date copy on another healthy node:

1. Confirm the replication factor allows redundancy:
   - If a replication factor is set, it must be greater than `1`. With a replication factor of `1`, removing a node causes data loss.
   - If no replication factor is set, repositories are replicated to every node in the virtual storage, so a copy already exists elsewhere.
1. Ensure pool repositories are replicated to the same nodes as their upstream repository and forks. Pool repositories
   are treated the same as other repositories for replication, but older clusters might have pool repositories that are
   not co-located with the repositories that depend on them.
1. Use the [`dataloss`](#check-for-data-loss) subcommand to confirm each affected repository has an up-to-date, assigned replica on a node you are keeping.
1. Place the GitLab instance in [maintenance mode](../../maintenance_mode/_index.md) so that new writes are not
   processed by the cluster while you remove the node.

#### Use the same name

To use the same name for the replacement node, use [repository verifier](configure.md#enable-deletions) to scan the storage and remove dangling metadata records.
[Manually prioritize verification](configure.md#prioritize-verification-manually) of the replaced storage to speed up the process.

#### Use a different name

When using a different name for the replacement node, how you get repositories onto the new node depends on your
[replication factor](configure.md#configure-replication-factor) configuration.

If a custom replication factor is set, existing repositories are not automatically replicated to a newly added node.
Get the new node populated using one of the following approaches:

- **Increase the replication factor** with [`praefect set-replication-factor`](configure.md#configure-replication-factor).
  This assigns one additional storage chosen at random from the unassigned configured storages. It does not
  preferentially pick the newly added node. In a cluster with more than one unassigned storage, the new replica can
  land on any of them, including a node you intend to retire. Use this approach when adding redundancy, not when
  capacity on the old nodes is constrained.

  For example, if two nodes in the virtual storage have a replication factor of 2 and a new node (`gitaly-3`) is added, you can increase the replication
  factor to 3:

  ```shell
  $ sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml set-replication-factor -virtual-storage default -relative-path @hashed/3f/db/3fdba35f04dc8c462986c992bcf875546257113072a909c162f7e470e581e278.git -replication-factor 3

  current assignments: gitaly-1, gitaly-2, gitaly-3
  ```

  This ensures that the repository is replicated to a new node and the `repository_assignments` table is updated with the name of the new Gitaly node.

- **Reassign at the same replication factor** by updating the `repository_assignments` table. This swaps the old
  storage for the new one without adding a copy, and is the recommended approach when you are draining a node or
  source capacity is limited. See the reassignment steps later in this section.

If the [default replication factor](configure.md#configure-replication-factor) is set, Praefect automatically
replicates all repositories to any newly added node to maintain the factor. No per-repository action is required.

After you [verify](#check-for-data-loss) that repository is successfully replicated to the new node:

1. Remove the `gitaly-1` node from the [Praefect configuration](configure.md#praefect) under `praefect['virtual_storages']`.
1. Reconfigure and restart Praefect:

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart praefect
   ```

Database state referring to the old Gitaly node can be ignored.

An alternative is to reassign all repositories from the old storage to the new one, after configuring the new Gitaly node:

1. Connect to Praefect database:

   ```shell
   /opt/gitlab/embedded/bin/psql -h <psql host> -U <user> -d <database name>
   ```

1. Update the `repository_assignments` table to replace the old Gitaly node name (for example, `old-gitaly`) with the new Gitaly node name
   (for example, `new-gitaly`):

   ```sql
   UPDATE repository_assignments SET storage='new-gitaly' WHERE storage='old-gitaly';
   ```

This triggers the appropriate replication jobs to bring the system back into the desired state. Before you remove the
old node, use the [`dataloss`](#check-for-data-loss) subcommand to confirm each affected repository has an up-to-date,
assigned replica on the new node.

## Primary node failure

Gitaly Cluster (Praefect) recovers from a failing primary Gitaly node by promoting a healthy secondary as the new primary.
Gitaly Cluster (Praefect):

- Elects a healthy secondary with a fully up to date copy of the repository as the new primary.
- If no fully up to date secondary is available, elects the secondary with the least unreplicated writes from the primary as the new primary.
- Repository becomes unavailable if there are no fully up to date copies of it on healthy secondaries. Use the [Praefect `dataloss` subcommand](#check-for-data-loss) to detect it.

### Unavailable repositories

A repository is unavailable if all of its up to date replicas are unavailable. Unavailable repositories are
not accessible through Praefect to prevent serving stale data that may break automated tooling.

### Check for data loss

The Praefect `dataloss` subcommand identifies unavailable repositories. This helps identify potential data loss
and repositories that are no longer accessible because all of their up-to-date replicas copies are unavailable.

The following parameters are available:

- `-virtual-storage` that specifies which virtual storage to check. Because they might require
  an administrator to intervene, the default behavior is to display unavailable repositories.
- [`-partially-unavailable`](#unavailable-replicas-of-available-repositories)
  that specifies whether to include in the output repositories that are available but have
  some assigned copies that are not available.

> [!note]
> `dataloss` is still in [beta](../../../policy/development_stages_support.md#beta) and the output format is subject to change.

To check for repositories with outdated primaries or for unavailable repositories, run:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss [-virtual-storage <virtual-storage>]
```

Every configured virtual storage is checked if none is specified:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss
```

Repositories are listed in the output that have no healthy and fully up-to-date copies available. The following
information is printed for each repository:

- A repository's relative path to the storage directory identifies each repository and groups the related
  information.
- `(unavailable)` is printed next to the disk path if the repository is unavailable.
- The primary field lists the repository's current primary. If the repository has no primary, the field shows
  `No Primary`.
- The In-Sync Storages lists replicas which have replicated the latest successful write and all writes
  preceding it.
- The Outdated Storages lists replicas which contain an outdated copy of the repository. Replicas which have no copy
  of the repository but should contain it are also listed here. The maximum number of changes the replica is missing
  is listed next to replica. It's important to notice that the outdated replicas may be fully up to date or contain
  later changes but Praefect can't guarantee it.

Additional information includes:

- Whether a node is assigned to host the repository is listed with each node's status.
  `assigned host` is printed next to nodes that are assigned to store the repository. The
  text is omitted if the node contains a copy of the repository but is not assigned to store
  the repository. Such copies aren't kept in sync by Praefect, but may act as replication
  sources to bring assigned copies up to date.
- `unhealthy` is printed next to the copies that are located on unhealthy Gitaly nodes.

Example output:

```shell
Virtual storage: default
  Outdated repositories:
    @hashed/3f/db/3fdba35f04dc8c462986c992bcf875546257113072a909c162f7e470e581e278.git (unavailable):
      Primary: gitaly-1
      In-Sync Storages:
        gitaly-2, assigned host, unhealthy
      Outdated Storages:
        gitaly-1 is behind by 3 changes or less, assigned host
        gitaly-3 is behind by 3 changes or less
```

A confirmation is printed out when every repository is available. For example:

```shell
Virtual storage: default
  All repositories are available!
```

#### Unavailable replicas of available repositories

To also list information of repositories which are available but are unavailable from some of the assigned nodes,
use the `-partially-unavailable` flag.

A repository is available if there is a healthy, up to date replica available. Some of the assigned secondary
replicas may be temporarily unavailable for access while they are waiting to replicate the latest changes.

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss [-virtual-storage <virtual-storage>] [-partially-unavailable]
```

Example output:

```shell
Virtual storage: default
  Outdated repositories:
    @hashed/3f/db/3fdba35f04dc8c462986c992bcf875546257113072a909c162f7e470e581e278.git:
      Primary: gitaly-1
      In-Sync Storages:
        gitaly-1, assigned host
      Outdated Storages:
        gitaly-2 is behind by 3 changes or less, assigned host
        gitaly-3 is behind by 3 changes or less
```

With the `-partially-unavailable` flag set, a confirmation is printed out if every assigned replica is fully up to
date and healthy.

For example:

```shell
Virtual storage: default
  All repositories are fully available on all assigned storages!
```

### Check repository checksums

To check a project's repository checksums across on all Gitaly nodes, run the
[replicas Rake task](../../raketasks/praefect.md#replica-checksums) on the main GitLab node.

### Accept data loss

> [!warning]
> `accept-dataloss` causes permanent data loss by overwriting other versions of the repository. Data
> [recovery efforts](#data-recovery) must be performed before using it.

If it is not possible to bring one of the up to date replicas back online, you may have to accept data
loss. When accepting data loss, Praefect marks the chosen replica of the repository as the latest version
and replicates it to the other assigned Gitaly nodes. This process overwrites any other version of the
repository so care must be taken.

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml accept-dataloss
-virtual-storage <virtual-storage> -relative-path <relative-path> -authoritative-storage <storage-name>
```

### Enable writes or accept data loss

> [!warning]
> `accept-dataloss` causes permanent data loss by overwriting other versions of the repository.
> Data [recovery efforts](#data-recovery) must be performed before using it.

Praefect provides the following subcommands to re-enable writes or accept data loss. If it is not possible to bring one
of the up-to-date nodes back online, you might have to accept data loss:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml accept-dataloss -virtual-storage <virtual-storage> -relative-path <relative-path> -authoritative-storage <storage-name>
```

When accepting data loss, Praefect:

1. Marks the chosen copy of the repository as the latest version.
1. Replicates the copy to the other assigned Gitaly nodes.

   This process overwrites any other copy of the repository so care must be taken.

## Data recovery

If a Gitaly node fails replication jobs for any reason, it ends up hosting outdated versions of the
affected repositories. Praefect provides tools for automatic reconciliation. These tools reconcile the outdated
repositories to bring them fully up to date again.

Praefect automatically reconciles repositories that are not up to date. By default, this is done every
five minutes. For each outdated repository on a healthy Gitaly node, Praefect picks a
random, fully up-to-date replica of the repository on another healthy Gitaly node to replicate from. A
replication job is scheduled only if there are no other replication jobs pending for the target
repository.

The reconciliation frequency can be changed through the configuration. The value can be any valid
[Go duration value](https://pkg.go.dev/time#ParseDuration). Values below 0 disable the feature.

Examples:

```ruby
praefect['configuration'] = {
   # ...
   reconciliation: {
      # ...
      scheduling_interval: '5m', # the default value
   },
}
```

```ruby
praefect['configuration'] = {
   # ...
   reconciliation: {
      # ...
      scheduling_interval: '30s', # reconcile every 30 seconds
   },
}
```

```ruby
praefect['configuration'] = {
   # ...
   reconciliation: {
      # ...
      scheduling_interval: '0', # disable the feature
   },
}
```

### Manually remove repositories

The `remove-repository` Praefect sub-command removes a repository from a Gitaly Cluster (Praefect), and all state associated with a given repository including:

- On-disk repositories on all relevant Gitaly nodes.
- Any database state tracked by Praefect.

By default, the command operates in dry-run mode. For example:

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml remove-repository -virtual-storage <virtual-storage> -relative-path <repository>
```

- Replace `<virtual-storage>` with the name of the virtual storage containing the repository.
- Replace `<repository>` with the relative path of the repository to remove.
- Add `-db-only` to remove the Praefect tracking database entry without removing the on-disk repository. Use this option to remove orphaned database entries and to
  protect on-disk repository data from deletion when a valid repository is accidentally specified. If the database entry is accidentally deleted, re-track the repository with the
  [`track-repository` command](#manually-add-a-single-repository-to-the-tracking-database).
- Add `-apply` to run the command outside of dry-run mode and remove the repository. For example:

  ```shell
  sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml remove-repository -virtual-storage <virtual-storage> -relative-path <repository> -apply
  ```

- `-virtual-storage` is the virtual storage the repository is located in. Virtual storages are configured in `/etc/gitlab/gitlab.rb` under `praefect['configuration']['virtual_storage]` and looks like the following:

  ```ruby
  praefect['configuration'] = {
    # ...
    virtual_storage: [
      {
        # ...
        name: 'default',
      },
      {
        # ...
        name: 'storage-1',
      },
    ],
  }
  ```

  In this example, the virtual storage to specify is `default` or `storage-1`.

- `-repository` is the repository's relative path in the storage [beginning with `@hashed`](../../repository_storage_paths.md#hashed-storage).
  For example:

  ```plaintext
  @hashed/f5/ca/f5ca38f748a1d6eaf726b8a42fb575c3c71f1864a8143301782de13da2d9202b.git
  ```

Parts of the repository can continue to exist after running `remove-repository`. This can be because of:

- A deletion error.
- An in-flight RPC call targeting the repository.

If this occurs, run `remove-repository` again.

## Praefect tracking database maintenance

Common maintenance tasks on the Praefect tracking database are documented in this section.

### List untracked repositories

The `list-untracked-repositories` Praefect sub-command lists repositories of the Gitaly Cluster (Praefect) that both:

- Exist for at least one Gitaly storage.
- Aren't tracked in the Praefect tracking database.

Add the `-older-than` option to avoid showing repositories that:

- Are in the process of being created.
- For which a record doesn't yet exist in the Praefect tracking database.

Replace `<duration>` with a time duration (for example, `5s`, `10m`, or `1h`). Defaults to `6h`.

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml list-untracked-repositories -older-than <duration>
```

Only repositories with a creation time before the specified duration are considered.

The command outputs:

- Result to `STDOUT` and the command's logs.
- Errors to `STDERR`.

Each entry is a complete JSON string with a newline at the end (configurable using the
`-delimiter` flag). For example:

```plaintext
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml list-untracked-repositories
{"virtual_storage":"default","storage":"gitaly-1","relative_path":"@hashed/ab/cd/abcd123456789012345678901234567890123456789012345678901234567890.git"}
{"virtual_storage":"default","storage":"gitaly-1","relative_path":"@hashed/ab/cd/abcd123456789012345678901234567890123456789012345678901234567891.git"}
```

### Manually add a single repository to the tracking database

> [!warning]
> Because of a [known issue](https://gitlab.com/gitlab-org/gitaly/-/issues/5402), in GitLab 16.0 and earlier, you can't
> add repositories to the Praefect tracking database with Praefect-generated replica paths (`@cluster`). These
> repositories are not associated with the repository path used by GitLab and are inaccessible.

The `track-repository` Praefect sub-command adds repositories on disk to the Praefect tracking database to be tracked.

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml track-repository -virtual-storage <virtual-storage> -authoritative-storage <storage-name> -relative-path <repository> -replica-path <disk_path> -replicate-immediately
```

- `-virtual-storage` is the virtual storage the repository is located in. Virtual storages are configured in `/etc/gitlab/gitlab.rb` under `praefect['configuration'][:virtual_storage]` and looks like the following:

  ```ruby
  praefect['configuration'] = {
    # ...
    virtual_storage: [
      {
        # ...
        name: 'default',
      },
      {
        # ...
        name: 'storage-1',
      },
    ],
  }
  ```

  In this example, the virtual storage to specify is `default` or `storage-1`.

- `-relative-path` is the relative path in the virtual storage. Usually [beginning with `@hashed`](../../repository_storage_paths.md#hashed-storage).
  For example:

  ```plaintext
  @hashed/f5/ca/f5ca38f748a1d6eaf726b8a42fb575c3c71f1864a8143301782de13da2d9202b.git
  ```

- `-replica-path` is the relative path on physical storage. Can start with [`@cluster` or match `relative_path`](../../repository_storage_paths.md#gitaly-cluster-praefect-storage).
- `-authoritative-storage` is the storage we want Praefect to treat as the primary. Required if
  [per-repository replication](configure.md#configure-replication-factor) is set as the replication strategy.
- `-replicate-immediately` causes the command to replicate the repository to its secondaries immediately.
  Otherwise, replication jobs are scheduled for execution in the database and are picked up by a Praefect background process.

The command outputs:

- Results to `STDOUT` and the command's logs.
- Errors to `STDERR`.

This command fails if:

- The repository is already being tracked by the Praefect tracking database.
- The repository does not exist on disk.

### Manually add many repositories to the tracking database

> [!warning]
> Because of a [known issue](https://gitlab.com/gitlab-org/gitaly/-/issues/5402), in GitLab 16.0 and earlier, you can't
> add repositories to the Praefect tracking database with Praefect-generated replica paths (`@cluster`). These
> repositories are not associated with the repository path used by GitLab and are inaccessible.

Migrations using the API automatically add repositories to the Praefect tracking database.

If you are instead manually copying repositories over from existing infrastructure, you can use the `track-repositories`
Praefect subcommand. This subcommand adds large batches of on-disk repositories to the Praefect tracking database.

```shell
# Omnibus GitLab install
sudo gitlab-ctl praefect track-repositories --input-path /path/to/input.json

# Source install
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml track-repositories -input-path /path/to/input.json
```

The command validates that all entries:

- Are formatted correctly and contain required fields.
- Correspond to a valid Git repository on disk.
- Are not tracked in the Praefect tracking database.

If any entry fails these checks, the command aborts prior to attempting to track a repository.

- `input-path` is the path to a file containing a list of repositories formatted as newline-delimited JSON objects. Objects must contain the following keys:
  - `relative_path`: corresponds with `repository` in [`track-repository`](#manually-add-a-single-repository-to-the-tracking-database).
  - `authoritative-storage`: the storage Praefect is to treat as the primary.
  - `virtual-storage`: the virtual storage the repository is located in.

    For example:

    ```json
    {"relative_path":"@hashed/f5/ca/f5ca38f748a1d6eaf726b8a42fb575c3c71f1864a8143301782de13da2d9202b.git","replica_path":"@cluster/fe/d3/1","authoritative_storage":"gitaly-1","virtual_storage":"default"}
    {"relative_path":"@hashed/f8/9f/f89f8d0e735a91c5269ab08d72fa27670d000e7561698d6e664e7b603f5c4e40.git","replica_path":"@cluster/7b/28/2","authoritative_storage":"gitaly-2","virtual_storage":"default"}
    ```

- `-replicate-immediately`, causes the command to replicate the repository to its secondaries immediately.
  Otherwise, replication jobs are scheduled for execution in the database and are picked up by a Praefect background process.

### List virtual storage details

The `list-storages` Praefect sub-command lists virtual storages and their associated storage nodes. If a virtual storage is:

- Specified using `-virtual-storage`, it lists only storage nodes for the specified virtual storage.
- Not specified, all virtual storages and their associated storage nodes are listed in tabular format.

```shell
sudo -u git -- /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml list-storages -virtual-storage <virtual_storage_name>
```

The command outputs:

- Result to `STDOUT` and the command's logs.
- Errors to `STDERR`.
