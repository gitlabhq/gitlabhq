---
stage: Create
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Moving repositories managed by GitLab **(FREE SELF)**

Sometimes you need to move all repositories managed by GitLab to
another file system or another server.

## Moving data within a GitLab instance

The GitLab API is the recommended way to move Git repositories:

- Between servers.
- Between different storage.
- From single-node Gitaly to Gitaly Cluster.

For more information, see:

- [Configuring additional storage for Gitaly](../gitaly/configure_gitaly.md#network-architecture). This
  example configures additional storage called `storage1` and `storage2`.
- [The API documentation](../../api/project_repository_storage_moves.md) details the endpoints for
  querying and scheduling project repository moves.
- [The API documentation](../../api/snippet_repository_storage_moves.md) details the endpoints for
  querying and scheduling snippet repository moves.
- [The API documentation](../../api/group_repository_storage_moves.md) details the endpoints for
  querying and scheduling group repository moves **(PREMIUM SELF)**.
- [Migrate to Gitaly Cluster](../gitaly/praefect.md#migrate-to-gitaly-cluster).

## Migrating to another GitLab instance

[Using the API](#moving-data-within-a-gitlab-instance) isn't an option if you are migrating to a new
GitLab environment, for example:

- From a single-node GitLab to a scaled-out architecture.
- From a GitLab instance in your private data center to a cloud provider.

The rest of the document looks
at some of the ways you can copy all your repositories from
`/var/opt/gitlab/git-data/repositories` to `/mnt/gitlab/repositories`.

We look at three scenarios:

- The target directory is empty.
- The target directory contains an outdated copy of the repositories.
- How to deal with thousands of repositories.

WARNING:
Each of the approaches we list can or does overwrite data in the target directory
`/mnt/gitlab/repositories`. Do not mix up the source and the target.

### Recommended approach in all cases

The GitLab [backup and restore capability](../../raketasks/backup_restore.md) should be used. Git
repositories are accessed, managed, and stored on GitLab servers by Gitaly as a database. Data loss
can result from directly accessing and copying Gitaly's files using tools like `rsync`.

- From GitLab 13.3, backup performance can be improved by
  [processing multiple repositories concurrently](../../raketasks/backup_restore.md#back-up-git-repositories-concurrently).
- Backups can be created of just the repositories using the
  [skip feature](../../raketasks/backup_restore.md#excluding-specific-directories-from-the-backup).

### Target directory is empty: use a `tar` pipe

If the target directory `/mnt/gitlab/repositories` is empty the
simplest thing to do is to use a `tar` pipe. This method has low
overhead and `tar` is almost always already installed on your system.
However, it is not possible to resume an interrupted `tar` pipe: if
that happens then all data must be copied again.

```shell
sudo -u git sh -c 'tar -C /var/opt/gitlab/git-data/repositories -cf - -- . |\
  tar -C /mnt/gitlab/repositories -xf -'
```

If you want to see progress, replace `-xf` with `-xvf`.

#### `tar` pipe to another server

You can also use a `tar` pipe to copy data to another server. If your
`git` user has SSH access to the new server as `git@newserver`, you
can pipe the data through SSH.

```shell
sudo -u git sh -c 'tar -C /var/opt/gitlab/git-data/repositories -cf - -- . |\
  ssh git@newserver tar -C /mnt/gitlab/repositories -xf -'
```

If you want to compress the data before it goes over the network
(which costs you CPU cycles) you can replace `ssh` with `ssh -C`.

### The target directory contains an outdated copy of the repositories: use `rsync`

WARNING:
Using `rsync` to migrate Git data can cause data loss and repository corruption.
[These instructions are being reviewed](https://gitlab.com/gitlab-org/gitlab/-/issues/270422).

If the target directory already contains a partial / outdated copy
of the repositories it may be wasteful to copy all the data again
with `tar`. In this scenario it is better to use `rsync`. This utility
is either already installed on your system, or installable
by using `apt` or `yum`.

```shell
sudo -u git  sh -c 'rsync -a --delete /var/opt/gitlab/git-data/repositories/. \
  /mnt/gitlab/repositories'
```

The `/.` in the command above is very important, without it you can
get the wrong directory structure in the target directory.
If you want to see progress, replace `-a` with `-av`.

#### Single `rsync` to another server

WARNING:
Using `rsync` to migrate Git data can cause data loss and repository corruption.
[These instructions are being reviewed](https://gitlab.com/gitlab-org/gitlab/-/issues/270422).

If the `git` user on your source system has SSH access to the target
server you can send the repositories over the network with `rsync`.

```shell
sudo -u git sh -c 'rsync -a --delete /var/opt/gitlab/git-data/repositories/. \
  git@newserver:/mnt/gitlab/repositories'
```

### Thousands of Git repositories: use one `rsync` per repository

WARNING:
Using `rsync` to migrate Git data can cause data loss and repository corruption.
[These instructions are being reviewed](https://gitlab.com/gitlab-org/gitlab/-/issues/270422).

Every time you start an `rsync` job it must:

- Inspect all files in the source directory.
- Inspect all files in the target directory.
- Decide whether or not to copy files.

If the source or target directory
has many contents, this startup phase of `rsync` can become a burden
for your GitLab server. You can reduce the workload of `rsync` by dividing its
work in smaller pieces, and sync one repository at a time.

In addition to `rsync` we use [GNU Parallel](http://www.gnu.org/software/parallel/).
This utility is not included in GitLab, so you must install it yourself with `apt`
or `yum`.

This process does not clean up repositories at the target location that no
longer exist at the source.

#### Parallel `rsync` for all repositories known to GitLab

WARNING:
Using `rsync` to migrate Git data can cause data loss and repository corruption.
[These instructions are being reviewed](https://gitlab.com/gitlab-org/gitlab/-/issues/270422).

This syncs repositories with 10 `rsync` processes at a time. We keep
track of progress so that the transfer can be restarted if necessary.

First we create a new directory, owned by `git`, to hold transfer
logs. We assume the directory is empty before we start the transfer
procedure, and that we are the only ones writing files in it.

```shell
# Omnibus
sudo mkdir /var/opt/gitlab/transfer-logs
sudo chown git:git /var/opt/gitlab/transfer-logs

# Source
sudo -u git -H mkdir /home/git/transfer-logs
```

We seed the process with a list of the directories we want to copy.

```shell
# Omnibus
sudo -u git sh -c 'gitlab-rake gitlab:list_repos > /var/opt/gitlab/transfer-logs/all-repos-$(date +%s).txt'

# Source
cd /home/git/gitlab
sudo -u git -H sh -c 'bundle exec rake gitlab:list_repos > /home/git/transfer-logs/all-repos-$(date +%s).txt'
```

Now we can start the transfer. The command below is idempotent, and
the number of jobs done by GNU Parallel should converge to zero. If it
does not, some repositories listed in `all-repos-1234.txt` may have been
deleted/renamed before they could be copied.

```shell
# Omnibus
sudo -u git sh -c '
cat /var/opt/gitlab/transfer-logs/* | sort | uniq -u |\
  /usr/bin/env JOBS=10 \
  /opt/gitlab/embedded/service/gitlab-rails/bin/parallel-rsync-repos \
    /var/opt/gitlab/transfer-logs/success-$(date +%s).log \
    /var/opt/gitlab/git-data/repositories \
    /mnt/gitlab/repositories
'

# Source
cd /home/git/gitlab
sudo -u git -H sh -c '
cat /home/git/transfer-logs/* | sort | uniq -u |\
  /usr/bin/env JOBS=10 \
  bin/parallel-rsync-repos \
    /home/git/transfer-logs/success-$(date +%s).log \
    /home/git/repositories \
    /mnt/gitlab/repositories
`
```

#### Parallel `rsync` only for repositories with recent activity

WARNING:
Using `rsync` to migrate Git data can cause data loss and repository corruption.
[These instructions are being reviewed](https://gitlab.com/gitlab-org/gitlab/-/issues/270422).

Suppose you have already done one sync that started after 2015-10-1 12:00 UTC.
Then you might only want to sync repositories that were changed by using GitLab
after that time. You can use the `SINCE` variable to tell `rake
gitlab:list_repos` to only print repositories with recent activity.

```shell
# Omnibus
sudo gitlab-rake gitlab:list_repos SINCE='2015-10-1 12:00 UTC' |\
  sudo -u git \
  /usr/bin/env JOBS=10 \
  /opt/gitlab/embedded/service/gitlab-rails/bin/parallel-rsync-repos \
    success-$(date +%s).log \
    /var/opt/gitlab/git-data/repositories \
    /mnt/gitlab/repositories

# Source
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:list_repos SINCE='2015-10-1 12:00 UTC' |\
  sudo -u git -H \
  /usr/bin/env JOBS=10 \
  bin/parallel-rsync-repos \
    success-$(date +%s).log \
    /home/git/repositories \
    /mnt/gitlab/repositories
```
