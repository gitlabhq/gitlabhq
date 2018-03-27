# NFS

You can view information and options set for each of the mounted NFS file
systems by running `sudo nfsstat -m`.

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
  to set ownership and permissions on files, as needed.
- `sync` - Force synchronous behavior. Default is asynchronous and under certain
  circumstances it could lead to data loss if a failure occurs before data has
  synced.

## AWS Elastic File System

GitLab strongly recommends against using AWS Elastic File System (EFS).
Our support team will not be able to assist on performance issues related to
file system access.

Customers and users have reported that AWS EFS does not perform well for GitLab's
use-case. There are several issues that can cause problems. For these reasons
GitLab does not recommend using EFS with GitLab.

- EFS bases allowed IOPS on volume size. The larger the volume, the more IOPS
  are allocated. For smaller volumes, users may experience decent performance
  for a period of time due to 'Burst Credits'. Over a period of weeks to months
  credits may run out and performance will bottom out.
- To keep "Burst Credits" available, it may be necessary to provision more space
  with 'dummy data'.  However, this may get expensive.
- Another option to maintain "Burst Credits" is to use FS Cache on the server so
  that AWS doesn't always have to go into EFS to access files.
- For larger volumes, allocated IOPS may not be the problem. Workloads where
  many small files are written in a serialized manner are not well-suited for EFS.
  EBS with an NFS server on top will perform much better.

In addition, avoid storing GitLab log files (e.g. those in `/var/log/gitlab`)
because this will also affect performance. We recommend that the log files be
stored on a local volume.

For more details on another person's experience with EFS, see
[Amazon's Elastic File System: Burst Credits](https://www.rawkode.io/2017/04/amazons-elastic-file-system-burst-credits/)

## NFS Client mount options

Below is an example of an NFS mount point defined in `/etc/fstab` we use on
GitLab.com:

```
10.1.1.1:/var/opt/gitlab/git-data /var/opt/gitlab/git-data nfs4 defaults,soft,rsize=1048576,wsize=1048576,noatime,nobootwait,lookupcache=positive 0 2
```

Notice several options that you should consider using:

| Setting | Description |
| ------- | ----------- |
| `nobootwait` | Don't halt boot process waiting for this mount to become available
| `lookupcache=positive` | Tells the NFS client to honor `positive` cache results but invalidates any `negative` cache results. Negative cache results cause problems with Git. Specifically, a `git push` can fail to register uniformly across all NFS clients. The negative cache causes the clients to 'remember' that the files did not exist previously.

## Mount locations

When using default Omnibus configuration you will need to share 5 data locations
between all GitLab cluster nodes. No other locations should be shared. The
following are the 5 locations you need to mount:

| Location | Description | Default configuration |
| -------- | ----------- | --------------------- |
| `/var/opt/gitlab/git-data` | Git repository data. This will account for a large portion of your data | `git_data_dirs({"default" => "/var/opt/gitlab/git-data"})`
| `/var/opt/gitlab/.ssh` | SSH `authorized_keys` file and keys used to import repositories from some other Git services | `user['home'] = '/var/opt/gitlab/'`
| `/var/opt/gitlab/gitlab-rails/uploads` | User uploaded attachments | `gitlab_rails['uploads_directory'] = '/var/opt/gitlab/gitlab-rails/uploads'`
| `/var/opt/gitlab/gitlab-rails/shared` | Build artifacts, GitLab Pages, LFS objects, temp files, etc. If you're using LFS this may also account for a large portion of your data | `gitlab_rails['shared_path'] = '/var/opt/gitlab/gitlab-rails/shared'`
| `/var/opt/gitlab/gitlab-ci/builds` | GitLab CI build traces | `gitlab_ci['builds_directory'] = '/var/opt/gitlab/gitlab-ci/builds'`

Other GitLab directories should not be shared between nodes. They contain
node-specific files and GitLab code that does not need to be shared. To ship
logs to a central location consider using remote syslog. GitLab Omnibus packages
provide configuration for [UDP log shipping][udp-log-shipping].

### Consolidating mount points

If you don't want to configure 5-6 different NFS mount points, you have a few
alternative options.

#### Change default file locations

Omnibus allows you to configure the file locations. With custom configuration
you can specify just one main mountpoint and have all of these locations
as subdirectories. Mount `/gitlab-data` then use the following Omnibus
configuration to move each data location to a subdirectory:

```ruby
git_data_dirs({"default" => "/gitlab-data/git-data"})
user['home'] = '/gitlab-data/home'
gitlab_rails['uploads_directory'] = '/gitlab-data/uploads'
gitlab_rails['shared_path'] = '/gitlab-data/shared'
gitlab_ci['builds_directory'] = '/gitlab-data/builds'
```

To move the `git` home directory, all GitLab services must be stopped. Run
`gitlab-ctl stop && initctl stop gitlab-runsvdir`. Then continue with the
reconfigure.

Run `sudo gitlab-ctl reconfigure` to start using the central location. Please
be aware that if you had existing data you will need to manually copy/rsync it
to these new locations and then restart GitLab.

#### Bind mounts

Bind mounts provide a way to specify just one NFS mount and then
bind the default GitLab data locations to the NFS mount. Start by defining your
single NFS mount point as you normally would in `/etc/fstab`. Let's assume your
NFS mount point is `/gitlab-data`. Then, add the following bind mounts in
`/etc/fstab`:

```bash
/gitlab-data/git-data /var/opt/gitlab/git-data none bind 0 0
/gitlab-data/.ssh /var/opt/gitlab/.ssh none bind 0 0
/gitlab-data/uploads /var/opt/gitlab/gitlab-rails/uploads none bind 0 0
/gitlab-data/shared /var/opt/gitlab/gitlab-rails/shared none bind 0 0
/gitlab-data/builds /var/opt/gitlab/gitlab-ci/builds none bind 0 0
```

---

Read more on high-availability configuration:

1. [Configure the database](database.md)
1. [Configure Redis](redis.md)
1. [Configure the GitLab application servers](gitlab.md)
1. [Configure the load balancers](load_balancer.md)

[udp-log-shipping]: http://docs.gitlab.com/omnibus/settings/logs.html#udp-log-shipping-gitlab-enterprise-edition-only "UDP log shipping"
