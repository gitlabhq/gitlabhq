---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Using NFS with GitLab
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

NFS can be used as an alternative for object storage but this isn't typically
recommended for performance reasons.

For data objects such as LFS, Uploads, and Artifacts, an [Object Storage service](object_storage.md)
is recommended over NFS where possible, due to better performance.
When eliminating the usage of NFS, there are [additional steps you need to take](object_storage.md#alternatives-to-file-system-storage)
in addition to moving to Object Storage.

NFS cannot be used for repository storage.

For steps you can use to test file system performance, see
[File System Performance Benchmarking](operations/filesystem_benchmarking.md).

## Fast lookup of authorized SSH keys

The [fast SSH key lookup](operations/fast_ssh_key_lookup.md) feature can improve
performance of GitLab instances even if they're using block storage.

[Fast SSH key lookup](operations/fast_ssh_key_lookup.md) is a replacement for
`authorized_keys` (in `/var/opt/gitlab/.ssh`) using the GitLab database.

NFS increases latency, so fast lookup is recommended if `/var/opt/gitlab`
is moved to NFS.

We are investigating the use of
[fast lookup as the default](https://gitlab.com/groups/gitlab-org/-/epics/3104).

## NFS server

Installing the `nfs-kernel-server` package allows you to share directories with
the clients running the GitLab application:

```shell
sudo apt-get update
sudo apt-get install nfs-kernel-server
```

### Required features

**File locking**: GitLab **requires** advisory file locking, which is only
supported natively in NFS version 4. NFSv3 also supports locking as long as
Linux Kernel 2.6.5+ is used. We recommend using version 4 and do not
specifically test NFSv3.

### Recommended options

When you define your NFS exports, we recommend you also add the following
options:

- `no_root_squash` - NFS usually changes the `root` user to `nobody`. This is
  a good security measure when NFS shares are accessed by many different
  users. However, in this case only GitLab uses the NFS share so it
  is safe. GitLab recommends the `no_root_squash` setting because we need to
  manage file permissions automatically. Without the setting, you may receive
  errors when the Linux package tries to alter permissions. GitLab
  and other bundled components do **not** run as `root` but as non-privileged
  users. The recommendation for `no_root_squash` is to allow the Linux package
  to set ownership and permissions on files, as needed. In some cases where the
  `no_root_squash` option is not available, the `root` flag can achieve the same
  result.
- `sync` - Force synchronous behavior. Default is asynchronous and under certain
  circumstances it could lead to data loss if a failure occurs before data has
  synced.

Due to the complexities of running the Linux package with LDAP and the complexities of
maintaining ID mapping without LDAP, in most cases you should enable numeric UIDs
and GIDs (which is off by default in some cases) for simplified permission
management between systems:

- [NetApp instructions](https://docs.netapp.com/a/ontap/7-mode/8.2.4/File-Access-And-Protocols-Management-Guide-For-7-Mode.pdf)
- For non-NetApp devices, disable NFSv4 `idmapping` by performing opposite of [enable NFSv4 idmapper](https://wiki.archlinux.org/title/NFS#Enabling_NFSv4_idmapping)

### Disable NFS server delegation

We recommend that all NFS users disable the NFS server delegation feature. This
is to avoid a [Linux kernel bug](https://bugzilla.redhat.com/show_bug.cgi?id=1552203)
which causes NFS clients to slow precipitously due to
[excessive network traffic from numerous `TEST_STATEID` NFS messages](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/52017).

To disable NFS server delegation, do the following:

1. On the NFS server, run:

   ```shell
   echo 0 > /proc/sys/fs/leases-enable
   sysctl -w fs.leases-enable=0
   ```

1. Restart the NFS server process. For example, on CentOS run `service nfs restart`.

NOTE:
The kernel bug may be fixed in
[more recent kernels with this commit](https://github.com/torvalds/linux/commit/95da1b3a5aded124dd1bda1e3cdb876184813140).
Red Hat Enterprise 7 [shipped a kernel update](https://access.redhat.com/errata/RHSA-2019:2029)
on August 6, 2019 that may also have resolved this problem.
You may not need to disable NFS server delegation if you know you are using a version of
the Linux kernel that has been fixed. That said, GitLab still encourages instance
administrators to keep NFS server delegation disabled.

## NFS client

The `nfs-common` provides NFS functionality without installing server components which
we don't need running on the application nodes.

```shell
apt-get update
apt-get install nfs-common
```

### Mount options

Here is an example snippet to add to `/etc/fstab`:

```plaintext
10.1.0.1:/var/opt/gitlab/.ssh /var/opt/gitlab/.ssh nfs4 defaults,vers=4.1,hard,rsize=1048576,wsize=1048576,noatime,nofail,_netdev,lookupcache=positive 0 2
10.1.0.1:/var/opt/gitlab/gitlab-rails/uploads /var/opt/gitlab/gitlab-rails/uploads nfs4 defaults,vers=4.1,hard,rsize=1048576,wsize=1048576,noatime,nofail,_netdev,lookupcache=positive 0 2
10.1.0.1:/var/opt/gitlab/gitlab-rails/shared /var/opt/gitlab/gitlab-rails/shared nfs4 defaults,vers=4.1,hard,rsize=1048576,wsize=1048576,noatime,nofail,_netdev,lookupcache=positive 0 2
10.1.0.1:/var/opt/gitlab/gitlab-ci/builds /var/opt/gitlab/gitlab-ci/builds nfs4 defaults,vers=4.1,hard,rsize=1048576,wsize=1048576,noatime,nofail,_netdev,lookupcache=positive 0 2
```

You can view information and options set for each of the mounted NFS file
systems by running `nfsstat -m` and `cat /etc/fstab`.

Note there are several options that you should consider using:

| Setting | Description |
| ------- | ----------- |
| `vers=4.1` |NFS v4.1 should be used instead of v4.0 because there is a Linux [NFS client bug in v4.0](https://gitlab.com/gitlab-org/gitaly/-/issues/1339) that can cause significant problems due to stale data. |
| `nofail` | Don't halt boot process waiting for this mount to become available. |
| `lookupcache=positive` | Tells the NFS client to honor `positive` cache results but invalidates any `negative` cache results. Negative cache results cause problems with Git. Specifically, a `git push` can fail to register uniformly across all NFS clients. The negative cache causes the clients to 'remember' that the files did not exist previously. |
| `hard` | Instead of `soft`. [Further details](#soft-mount-option). |
| `cto` | `cto` is the default option, which you should use. Do not use `nocto`. [Further details](#nocto-mount-option). |
| `_netdev` | Wait to mount file system until network is online. See also the [`high_availability['mountpoint']`](https://docs.gitlab.com/omnibus/settings/configuration.html#only-start-omnibus-gitlab-services-after-a-given-file-system-is-mounted) option. |

#### `soft` mount option

It's recommended that you use `hard` in your mount options, unless you have a specific
reason to use `soft`.

When GitLab.com used NFS, we used `soft` because there were times when we had NFS servers
reboot and `soft` improved availability, but everyone's infrastructure is different.
If your NFS is provided by on-premise storage arrays with redundant controllers,
for example, you shouldn't need to worry about NFS server availability.

The NFS man page states:

> "soft" timeout can cause silent data corruption in certain cases

Read the [Linux man page](https://linux.die.net/man/5/nfs) to understand the difference,
and if you do use `soft`, ensure that you've taken steps to mitigate the risks.

If you experience behavior that might have been caused by
writes to disk on the NFS server not occurring, such as commits going missing,
use the `hard` option, because (from the man page):

> use the soft option only when client responsiveness is more important than data integrity

Other vendors make similar recommendations, including
[Recommended mount options for read-write directories](https://help.sap.com/docs/SUPPORT_CONTENT/basis/3354611703.html) and NetApp's
[knowledge base](https://kb.netapp.com/on-prem/ontap/da/NAS/NAS-KBs/What_are_the_differences_between_hard_mount_and_soft_mount),
they highlight that if the NFS client driver caches data, `soft` means there is no certainty if
writes by GitLab are actually on disk.

Mount points set with the option `hard` may not perform as well, and if the
NFS server goes down, `hard` causes processes to hang when interacting with
the mount point. Use `SIGKILL` (`kill -9`) to deal with hung processes.
The `intr` option
[stopped working in the 2.6 kernel](https://access.redhat.com/solutions/157873).

#### `nocto` mount option

Do not use `nocto`. Instead, use `cto`, which is the default.

When using `nocto`, the dentry cache is always used, up to `acdirmax` seconds (attribute cache time) from the time it's created.

This results in stale dentry cache issues with multiple clients, where each client can see a different (cached)
version of a directory.

From the [Linux man page](https://linux.die.net/man/5/nfs), the important parts:

> If the `nocto` option is specified, the client uses a non-standard heuristic to determine when files on the server have changed.
>
> Using the `nocto` option may improve performance for read-only mounts, but should be used only if the data on the server changes only occasionally.

We have noticed this behavior in an issue about [refs not found after a push](https://gitlab.com/gitlab-org/gitlab/-/issues/326066),
where newly added loose refs can be seen as missing on a different client with a local dentry cache, as
[described in this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/326066#note_539436931).

### A single NFS mount

It's recommended to nest all GitLab data directories within a mount, that allows automatic
restore of backups without manually moving existing data.

```plaintext
mountpoint
└── gitlab-data
    ├── builds
    ├── shared
    └── uploads
```

To do so, configure the Linux package with the paths to each directory nested
in the mount point as follows:

Mount `/gitlab-nfs` then use the following Linux package
configuration to move each data location to a subdirectory:

```ruby
gitlab_rails['uploads_directory'] = '/gitlab-nfs/gitlab-data/uploads'
gitlab_rails['shared_path'] = '/gitlab-nfs/gitlab-data/shared'
gitlab_ci['builds_directory'] = '/gitlab-nfs/gitlab-data/builds'
```

Run `sudo gitlab-ctl reconfigure` to start using the central location. Be aware
that if you had existing data, you need to manually copy or rsync it to
these new locations, and then restart GitLab.

### Bind mounts

Instead of changing the configuration in the Linux package, bind mounts can be used
to store the data on an NFS mount.

Bind mounts provide a way to specify just one NFS mount and then
bind the default GitLab data locations to the NFS mount. Start by defining your
single NFS mount point as you typically would in `/etc/fstab`. Let's assume your
NFS mount point is `/gitlab-nfs`. Then, add the following bind mounts in
`/etc/fstab`:

```shell
/gitlab-nfs/gitlab-data/.ssh /var/opt/gitlab/.ssh none bind 0 0
/gitlab-nfs/gitlab-data/uploads /var/opt/gitlab/gitlab-rails/uploads none bind 0 0
/gitlab-nfs/gitlab-data/shared /var/opt/gitlab/gitlab-rails/shared none bind 0 0
/gitlab-nfs/gitlab-data/builds /var/opt/gitlab/gitlab-ci/builds none bind 0 0
```

Using bind mounts requires you to manually make sure the data directories
are empty before attempting a restore. Read more about the
[restore prerequisites](backup_restore/_index.md).

### Multiple NFS mounts

When using default Linux package configuration, you need to share 3 data locations
between all GitLab cluster nodes. No other locations should be shared. The
following are the 3 locations need to be shared:

| Location | Description | Default configuration |
| -------- | ----------- | --------------------- |
| `/var/opt/gitlab/gitlab-rails/uploads` | User uploaded attachments | `gitlab_rails['uploads_directory'] = '/var/opt/gitlab/gitlab-rails/uploads'` |
| `/var/opt/gitlab/gitlab-rails/shared` | Objects such as build artifacts, GitLab Pages, LFS objects, and temp files. If you're using LFS this may also account for a large portion of your data | `gitlab_rails['shared_path'] = '/var/opt/gitlab/gitlab-rails/shared'` |
| `/var/opt/gitlab/gitlab-ci/builds` | GitLab CI/CD build traces | `gitlab_ci['builds_directory'] = '/var/opt/gitlab/gitlab-ci/builds'` |

Other GitLab directories should not be shared between nodes. They contain
node-specific files and GitLab code that does not need to be shared. To ship
logs to a central location consider using remote syslog. The Linux package
provides configuration for [UDP log shipping](https://docs.gitlab.com/omnibus/settings/logs.html#udp-log-shipping-gitlab-enterprise-edition-only).

Having multiple NFS mounts requires you to manually make sure the data directories
are empty before attempting a restore. Read more about the
[restore prerequisites](backup_restore/_index.md).

## Testing NFS

When you've set up the NFS server and client, you can verify NFS is configured correctly
by testing the following commands:

```shell
sudo mkdir /gitlab-nfs/test-dir
sudo chown git /gitlab-nfs/test-dir
sudo chgrp root /gitlab-nfs/test-dir
sudo chmod 0700 /gitlab-nfs/test-dir
sudo chgrp gitlab-www /gitlab-nfs/test-dir
sudo chmod 0751 /gitlab-nfs/test-dir
sudo chgrp git /gitlab-nfs/test-dir
sudo chmod 2770 /gitlab-nfs/test-dir
sudo chmod 2755 /gitlab-nfs/test-dir
sudo -u git mkdir /gitlab-nfs/test-dir/test2
sudo -u git chmod 2755 /gitlab-nfs/test-dir/test2
sudo ls -lah /gitlab-nfs/test-dir/test2
sudo -u git rm -r /gitlab-nfs/test-dir
```

Any `Operation not permitted` errors means you should investigate your NFS server export options.

## NFS in a Firewalled Environment

If the traffic between your NFS server and NFS clients is subject to port filtering
by a firewall, then you need to reconfigure that firewall to allow NFS communication.

[This guide from The Linux Documentation Project (TDLP)](https://tldp.org/HOWTO/NFS-HOWTO/security.html#FIREWALLS)
covers the basics of using NFS in a firewalled environment. Additionally, we encourage you to
search for and review the specific documentation for your operating system or distribution and your firewall software.

Example for Ubuntu:

Check that NFS traffic from the client is allowed by the firewall on the host by running
the command: `sudo ufw status`. If it's being blocked, then you can allow traffic from a specific
client with the command below.

```shell
sudo ufw allow from <client_ip_address> to any port nfs
```

## Known issues

### Avoid using cloud-based file systems

GitLab strongly recommends against using cloud-based file systems such as:

- AWS Elastic File System (EFS).
- Google Cloud Filestore.
- Azure Files.

Our support team cannot assist with performance issues related to cloud-based file system access.

Customers and users have reported that these file systems don't perform well for
the file system access GitLab requires. Workloads where many small files are written in
a serialized manner, like `git`, are not well suited to cloud-based file systems.

If you do choose to use these, avoid storing GitLab log files (for example, those in `/var/log/gitlab`)
there because this also affects performance. We recommend that the log files be
stored on a local volume.

For more details on the experience of using a cloud-based file systems with GitLab,
see this [Commit Brooklyn 2019 video](https://youtu.be/K6OS8WodRBQ?t=313).

### Avoid using CephFS and GlusterFS

GitLab strongly recommends against using CephFS and GlusterFS.
These distributed file systems are not well-suited for the GitLab input/output access patterns because Git uses many small files and access times and file locking times to propagate makes Git activity very slow.

### Avoid using PostgreSQL with NFS

GitLab strongly recommends against running your PostgreSQL database
across NFS. The GitLab support team is not able to assist on performance issues related to
this configuration.

Additionally, this configuration is specifically warned against in the
[PostgreSQL Documentation](https://www.postgresql.org/docs/current/creating-cluster.html#CREATING-CLUSTER-NFS):

>PostgreSQL does nothing special for NFS file systems, meaning it assumes NFS behaves exactly like
>locally-connected drives. If the client or server NFS implementation does not provide standard file
>system semantics, this can cause reliability problems. Specifically, delayed (asynchronous) writes
>to the NFS server can cause data corruption problems.

For supported database architecture, see our documentation about
[configuring a database for replication and failover](postgresql/replication_and_failover.md).

## Troubleshooting

### Finding the requests that are being made to NFS

In case of NFS-related problems, it can be helpful to trace
the file system requests that are being made by using `perf`:

```shell
sudo perf trace -e 'nfs4:*' -p $(pgrep -fd ',' puma)
```

On Ubuntu 16.04, use:

```shell
sudo perf trace --no-syscalls --event 'nfs4:*' -p $(pgrep -fd ',' puma)
```
