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
simplest thing to do is to use a tar pipe.

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

In this scenario it is better to use rsync. This utility is either
already installed on your system or easily installable via apt, yum
etc.

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
in GitLab 8.???.

