---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Importing a database dump into a staging environment
---

Sometimes it is useful to import the database from a production environment
into a staging environment for testing. The procedure below assumes you have
SSH and `sudo` access to both the production environment and the staging VM.

**Destroy your staging VM** when you are done with it. It is important to avoid
data leaks.

On the staging VM, add the following line to `/etc/gitlab/gitlab.rb` to speed up
large database imports.

```shell
# On STAGING
echo "postgresql['checkpoint_segments'] = 64" | sudo tee -a /etc/gitlab/gitlab.rb
sudo touch /etc/gitlab/skip-auto-reconfigure
sudo gitlab-ctl reconfigure
sudo gitlab-ctl stop puma
sudo gitlab-ctl stop sidekiq
```

Next, we let the production environment stream a compressed SQL dump to our
local machine via SSH, and redirect this stream to a `psql` client on the staging
VM.

```shell
# On LOCAL MACHINE
ssh -C gitlab.example.com sudo -u gitlab-psql /opt/gitlab/embedded/bin/pg_dump -Cc gitlabhq_production |\
  ssh -C staging-vm sudo -u gitlab-psql /opt/gitlab/embedded/bin/psql -d template1
```

## Recreating directory structure

If you need to re-create some directory structure on the staging server you can
use this procedure.

First, on the production server, create a list of directories you want to
re-create.

```shell
# On PRODUCTION
(umask 077; sudo find /var/opt/gitlab/git-data/repositories -maxdepth 1 -type d -print0 > directories.txt)
```

Copy `directories.txt` to the staging server and create the directories there.

```shell
# On STAGING
sudo -u git xargs -0 mkdir -p < directories.txt
```
