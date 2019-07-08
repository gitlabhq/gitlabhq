# NFS

You can view information and options set for each of the mounted NFS file
systems by running `nfsstat -m` and `cat /etc/fstab`.

NOTE: **Note:** Filesystem performance has a big impact on overall GitLab
performance, especially for actions that read or write to Git repositories. See
[Filesystem Performance Benchmarking](../operations/filesystem_benchmarking.md)
for steps to test filesystem performance.

## NFS Server features

### Required features

**File locking**: GitLab **requires** advisory file locking, which is only
supported natively in NFS version 4. NFSv3 also supports locking as long as
Linux Kernel 2.6.5+ is used. We recommend using version 4 and do not
specifically test NFSv3.

### Recommended options

When you define your NFS exports, we recommend you also add the following
options:

- `no_root_squash` - NFS normally changes the `root` user to `nobody`. This is
  a good security measure when NFS shares will be accessed by many different
  users. However, in this case only GitLab will use the NFS share so it
  is safe. GitLab recommends the `no_root_squash` setting because we need to
  manage file permissions automatically. Without the setting you may receive
  errors when the Omnibus package tries to alter permissions. Note that GitLab
  and other bundled components do **not** run as `root` but as non-privileged
  users. The recommendation for `no_root_squash` is to allow the Omnibus package
  to set ownership and permissions on files, as needed. In some cases where the
  `no_root_squash` option is not available, the `root` flag can achieve the same
  result.
- `sync` - Force synchronous behavior. Default is asynchronous and under certain
  circumstances it could lead to data loss if a failure occurs before data has
  synced.

Due to the complexities of running Omnibus with LDAP and the complexities of
maintaining ID mapping without LDAP, in most cases you should enable numeric UIDs
and GIDs (which is off by default in some cases) for simplified permission
management between systems:

  - [NetApp instructions](https://library.netapp.com/ecmdocs/ECMP1401220/html/GUID-24367A9F-E17B-4725-ADC1-02D86F56F78E.html)
  - For non-NetApp devices, disable NFSv4 `idmapping` by performing opposite of [enable NFSv4 idmapper](https://wiki.archlinux.org/index.php/NFS#Enabling_NFSv4_idmapping)

### Improving NFS performance with GitLab

NOTE: **Note:** From GitLab 12.1, it will automatically be detected if Rugged can and should be used per storage.

If you previously enabled Rugged using the feature flag, you will need to unset the feature flag by using:

```sh
sudo gitlab-rake gitlab:features:unset_rugged
```

If the Rugged feature flag is explicitly set to either true or false, GitLab will use the value explicitly set.

### Known issues

On some customer systems, we have seen NFS clients slow precipitously due to
[excessive network traffic from numerous `TEST_STATEID` NFS
messages](https://gitlab.com/gitlab-org/gitlab-ce/issues/52017). This is
likely due to a [Linux kernel
bug](https://bugzilla.redhat.com/show_bug.cgi?id=1552203) that may be fixed in
[more recent kernels with this
commit](https://github.com/torvalds/linux/commit/95da1b3a5aded124dd1bda1e3cdb876184813140).

GitLab recommends all NFS users disable the NFS server
delegation feature. To disable NFS server delegations
on an Linux NFS server, do the following:

1. On the NFS server, run:

    ```sh
    echo 0 > /proc/sys/fs/leases-enable
    sysctl -w fs.leases-enable=0
    ```

1. Restart the NFS server process. For example, on CentOS run `service nfs restart`.

## Avoid using AWS's Elastic File System (EFS)

GitLab strongly recommends against using AWS Elastic File System (EFS).
Our support team will not be able to assist on performance issues related to
file system access.

Customers and users have reported that AWS EFS does not perform well for GitLab's
use-case. Workloads where many small files are written in a serialized manner, like `git`,
are not well-suited for EFS. EBS with an NFS server on top will perform much better.

If you do choose to use EFS, avoid storing GitLab log files (e.g. those in `/var/log/gitlab`)
there because this will also affect performance. We recommend that the log files be
stored on a local volume.

For more details on another person's experience with EFS, see
[Amazon's Elastic File System: Burst Credits](https://rawkode.com/2017/04/16/amazons-elastic-file-system-burst-credits/)

## Avoid using CephFS and GlusterFS

GitLab strongly recommends against using CephFS and GlusterFS.
These distributed file systems are not well-suited for GitLab's input/output access patterns because git uses many small files and access times and file locking times to propagate will make git activity very slow.

## Avoid using PostgreSQL with NFS

GitLab strongly recommends against running your PostgreSQL database
across NFS. The GitLab support team will not be able to assist on performance issues related to
this configuration.

Additionally, this configuration is specifically warned against in the
[Postgres Documentation](https://www.postgresql.org/docs/current/static/creating-cluster.html#CREATING-CLUSTER-NFS):

>PostgreSQL does nothing special for NFS file systems, meaning it assumes NFS behaves exactly like
>locally-connected drives. If the client or server NFS implementation does not provide standard file
>system semantics, this can cause reliability problems. Specifically, delayed (asynchronous) writes
>to the NFS server can cause data corruption problems.

For supported database architecture, please see our documentation on
[Configuring a Database for GitLab HA](database.md).

## NFS Client mount options

Below is an example of an NFS mount point defined in `/etc/fstab` we use on
GitLab.com:

```
10.1.1.1:/var/opt/gitlab/git-data /var/opt/gitlab/git-data nfs4 defaults,soft,rsize=1048576,wsize=1048576,noatime,nofail,lookupcache=positive 0 2
```

Note there are several options that you should consider using:

| Setting | Description |
| ------- | ----------- |
| `vers=4.1` |NFS v4.1 should be used instead of v4.0 because there is a Linux [NFS client bug in v4.0](https://gitlab.com/gitlab-org/gitaly/issues/1339) that can cause significant problems due to stale data.
| `nofail` | Don't halt boot process waiting for this mount to become available
| `lookupcache=positive` | Tells the NFS client to honor `positive` cache results but invalidates any `negative` cache results. Negative cache results cause problems with Git. Specifically, a `git push` can fail to register uniformly across all NFS clients. The negative cache causes the clients to 'remember' that the files did not exist previously.

## A single NFS mount

It's recommended to nest all gitlab data dirs within a mount, that allows automatic
restore of backups without manually moving existing data.

```
mountpoint
└── gitlab-data
    ├── builds
    ├── git-data
    ├── shared
    └── uploads
```

To do so, we'll need to configure Omnibus with the paths to each directory nested
in the mount point as follows:

Mount `/gitlab-nfs` then use the following Omnibus
configuration to move each data location to a subdirectory:

```ruby
git_data_dirs({"default" => { "path" => "/gitlab-nfs/gitlab-data/git-data"} })
gitlab_rails['uploads_directory'] = '/gitlab-nfs/gitlab-data/uploads'
gitlab_rails['shared_path'] = '/gitlab-nfs/gitlab-data/shared'
gitlab_ci['builds_directory'] = '/gitlab-nfs/gitlab-data/builds'
```

Run `sudo gitlab-ctl reconfigure` to start using the central location. Please
be aware that if you had existing data you will need to manually copy/rsync it
to these new locations and then restart GitLab.

## Bind mounts

Alternatively to changing the configuration in Omnibus, bind mounts can be used
to store the data on an NFS mount.

Bind mounts provide a way to specify just one NFS mount and then
bind the default GitLab data locations to the NFS mount. Start by defining your
single NFS mount point as you normally would in `/etc/fstab`. Let's assume your
NFS mount point is `/gitlab-nfs`. Then, add the following bind mounts in
`/etc/fstab`:

```bash
/gitlab-nfs/gitlab-data/git-data /var/opt/gitlab/git-data none bind 0 0
/gitlab-nfs/gitlab-data/.ssh /var/opt/gitlab/.ssh none bind 0 0
/gitlab-nfs/gitlab-data/uploads /var/opt/gitlab/gitlab-rails/uploads none bind 0 0
/gitlab-nfs/gitlab-data/shared /var/opt/gitlab/gitlab-rails/shared none bind 0 0
/gitlab-nfs/gitlab-data/builds /var/opt/gitlab/gitlab-ci/builds none bind 0 0
```

Using bind mounts will require manually making sure the data directories
are empty before attempting a restore. Read more about the
[restore prerequisites](../../raketasks/backup_restore.md).

## Multiple NFS mounts

When using default Omnibus configuration you will need to share 4 data locations
between all GitLab cluster nodes. No other locations should be shared. The
following are the 4 locations need to be shared:

| Location | Description | Default configuration |
| -------- | ----------- | --------------------- |
| `/var/opt/gitlab/git-data` | Git repository data. This will account for a large portion of your data | `git_data_dirs({"default" => { "path" => "/var/opt/gitlab/git-data"} })`
| `/var/opt/gitlab/gitlab-rails/uploads` | User uploaded attachments | `gitlab_rails['uploads_directory'] = '/var/opt/gitlab/gitlab-rails/uploads'`
| `/var/opt/gitlab/gitlab-rails/shared` | Build artifacts, GitLab Pages, LFS objects, temp files, etc. If you're using LFS this may also account for a large portion of your data | `gitlab_rails['shared_path'] = '/var/opt/gitlab/gitlab-rails/shared'`
| `/var/opt/gitlab/gitlab-ci/builds` | GitLab CI build traces | `gitlab_ci['builds_directory'] = '/var/opt/gitlab/gitlab-ci/builds'`

Other GitLab directories should not be shared between nodes. They contain
node-specific files and GitLab code that does not need to be shared. To ship
logs to a central location consider using remote syslog. GitLab Omnibus packages
provide configuration for [UDP log shipping][udp-log-shipping].

Having multiple NFS mounts will require manually making sure the data directories
are empty before attempting a restore. Read more about the
[restore prerequisites](../../raketasks/backup_restore.md).

---

Read more on high-availability configuration:

1. [Configure the database](database.md)
1. [Configure Redis](redis.md)
1. [Configure the GitLab application servers](gitlab.md)
1. [Configure the load balancers](load_balancer.md)

[udp-log-shipping]: https://docs.gitlab.com/omnibus/settings/logs.html#udp-log-shipping-gitlab-enterprise-edition-only "UDP log shipping"
