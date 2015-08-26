## Migrating to packaged CI

Since version 5.1 GitLab CI is shipping as part of the GitLab omnibus package. This guide describes how to migrate GitLab CI from a source installation to an Omnibus package.

### 1. Update GitLab

Update GitLab CI manually to the version that you will install using the omnibus package (at least 7.11). Follow the update [manual for installation from sourse](update/README.md)

### 2. Backup

```
sudo -u gitlab_ci -H bundle exec rake backup:create RAILS_ENV=production
```

This command will create a backup file in the tmp folder
(`/home/gitlab_ci/gitlab_ci/tmp/backups/*_gitlab_ci_backup.tar.gz`). You can read more in the [GitLab CI backup/restore documentation](https://gitlab.com/gitlab-org/gitlab-ci/blob/master/doc/raketasks/backup_restore.md)

### 2. Install a packaged GitLab CI

This process is described in the [instruction for enabling GitLab CI](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/doc/gitlab-ci/README.md)

### 4. Restore backup

Put backup file to directory `/var/opt/gitlab/backups`.
Run the restore command:

```
sudo gitlab-ci-rake backup:restore
```
