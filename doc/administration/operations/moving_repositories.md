# Moving repositories managed by GitLab

Sometimes you need to move all repositories managed by GitLab to
another filesystem or another server. In this document we will look
at some of the ways you can copy all your repositories from
`/var/opt/gitlab/git-data/repositories` to `/mnt/gitlab/repositories`.

We will look at three scenarios: the target directory is empty, the
target directory contains an outdated copy of the repositories, and
how to deal with thousands of repositories.

**Each of the approaches we list can/will overwrite data in the
target directory `/mnt/gitlab/repositories`. Do not mix up the
source and the target.**

## Target directory is empty: use a tar pipe

If the target directory `/mnt/gitlab/repositories` is empty the
simplest thing to do is to use a tar pipe.  This method has low
overhead and tar is almost always already installed on your system.
However, it is not possible to resume an interrupted tar pipe:  if
that happens then all data must be copied again.

```
# As the git user
tar -C /var/opt/gitlab/git-data/repositories -cf - -- . |\
  tar -C /mnt/gitlab/repositories -xf -
```

If you want to see progress, replace `-xf` with `-xvf`.

### Tar pipe to another server

You can also use a tar pipe to copy data to another server. If your
'git' user has SSH access to the newserver as 'git@newserver', you
can pipe the data through SSH.

```
# As the git user
tar -C /var/opt/gitlab/git-data/repositories -cf - -- . |\
  ssh git@newserver tar -C /mnt/gitlab/repositories -xf -
```

If you want to compress the data before it goes over the network
(which will cost you CPU cycles) you can replace `ssh` with `ssh -C`.

## The target directory contains an outdated copy of the repositories: use rsync

If the target directory already contains a partial / outdated copy
of the repositories it may be wasteful to copy all the data again
with tar. In this scenario it is better to use rsync. This utility
is either already installed on your system or easily installable
via apt, yum etc.

```
# As the 'git' user
rsync -a --delete /var/opt/gitlab/git-data/repositories/. \
  /mnt/gitlab/repositories
```

The `/.` in the command above is very important, without it you can
easily get the wrong directory structure in the target directory.
If you want to see progress, replace `-a` with `-av`.

### Single rsync to another server

If the 'git' user on your source system has SSH access to the target
server you can send the repositories over the network with rsync.

```
# As the 'git' user
rsync -a --delete /var/opt/gitlab/git-data/repositories/. \
  git@newserver:/mnt/gitlab/repositories
```

## Thousands of Git repositories: use one rsync per repository

Every time you start an rsync job it has to inspect all files in
the source directory, all files in the target directory, and then
decide what files to copy or not. If the source or target directory
has many contents this startup phase of rsync can become a burden
for your GitLab server. In cases like this you can make rsync's
life easier by dividing its work in smaller pieces, and sync one
repository at a time.

In addition to rsync we will use [GNU
Parallel](http://www.gnu.org/software/parallel/). This utility is
not included in GitLab so you need to install it yourself with apt
or yum.  Also note that the GitLab scripts we used below were added
in GitLab 8.1.

** This process does not clean up repositories at the target location that no
longer exist at the source. ** If you start using your GitLab instance with
`/mnt/gitlab/repositories`, you need to run `gitlab-rake gitlab:cleanup:repos`
after switching to the new repository storage directory.

### Parallel rsync for all repositories known to GitLab

This will sync repositories with 10 rsync processes at a time. We keep
track of progress so that the transfer can be restarted if necessary.

First we create a new directory, owned by 'git', to hold transfer
logs. We assume the directory is empty before we start the transfer
procedure, and that we are the only ones writing files in it.

```
# Omnibus
sudo mkdir /var/opt/gitlab/transfer-logs
sudo chown git:git /var/opt/gitlab/transfer-logs

# Source
sudo -u git -H mkdir /home/git/transfer-logs
```

We seed the process with a list of the directories we want to copy.

```
# Omnibus
sudo -u git sh -c 'gitlab-rake gitlab:list_repos > /var/opt/gitlab/transfer-logs/all-repos-$(date +%s).txt'

# Source
cd /home/git/gitlab
sudo -u git -H sh -c 'bundle exec rake gitlab:list_repos > /home/git/transfer-logs/all-repos-$(date +%s).txt'
```

Now we can start the transfer. The command below is idempotent, and
the number of jobs done by GNU Parallel should converge to zero. If it
does not some repositories listed in all-repos-1234.txt may have been
deleted/renamed before they could be copied.

```
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

### Parallel rsync only for repositories with recent activity

Suppose you have already done one sync that started after 2015-10-1 12:00 UTC.
Then you might only want to sync repositories that were changed via GitLab
_after_ that time. You can use the 'SINCE' variable to tell 'rake
gitlab:list_repos' to only print repositories with recent activity.

```
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
