---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Maintenance Rake tasks
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab provides Rake tasks for general maintenance.

## Gather GitLab and system information

This command gathers information about your GitLab installation and the system it runs on.
These may be useful when asking for help or reporting issues. In a multi-node environment, run this command on nodes running GitLab Rails to avoid PostgreSQL socket errors.

- Linux package installations:

  ```shell
  sudo gitlab-rake gitlab:env:info
  ```

- Self-compiled installations:

  ```shell
  bundle exec rake gitlab:env:info RAILS_ENV=production
  ```

Example output:

```plaintext
System information
System:         Ubuntu 20.04
Proxy:          no
Current User:   git
Using RVM:      no
Ruby Version:   2.7.6p219
Gem Version:    3.1.6
Bundler Version:2.3.15
Rake Version:   13.0.6
Redis Version:  6.2.7
Sidekiq Version:6.4.2
Go Version:     unknown

GitLab information
Version:        15.5.5-ee
Revision:       5f5109f142d
Directory:      /opt/gitlab/embedded/service/gitlab-rails
DB Adapter:     PostgreSQL
DB Version:     13.8
URL:            https://app.gitaly.gcp.gitlabsandbox.net
HTTP Clone URL: https://app.gitaly.gcp.gitlabsandbox.net/some-group/some-project.git
SSH Clone URL:  git@app.gitaly.gcp.gitlabsandbox.net:some-group/some-project.git
Elasticsearch:  no
Geo:            no
Using LDAP:     no
Using Omniauth: yes
Omniauth Providers:

GitLab Shell
Version:        14.12.0
Repository storage paths:
- default:      /var/opt/gitlab/git-data/repositories
- gitaly:       /var/opt/gitlab/git-data/repositories
GitLab Shell path:              /opt/gitlab/embedded/service/gitlab-shell


Gitaly
- default Address:      unix:/var/opt/gitlab/gitaly/gitaly.socket
- default Version:      15.5.5
- default Git Version:  2.37.1.gl1
- gitaly Address:       tcp://10.128.20.6:2305
- gitaly Version:       15.5.5
- gitaly Git Version:   2.37.1.gl1
```

## Show GitLab license information

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

This command shows information about your [GitLab license](../license.md) and
how many seats are used. It is only available on GitLab Enterprise
installations: a license cannot be installed into GitLab Community Edition.

These may be useful when raising tickets with Support, or for programmatically
checking your license parameters.

- Linux package installations:

  ```shell
  sudo gitlab-rake gitlab:license:info
  ```

- Self-compiled installations:

  ```shell
  bundle exec rake gitlab:license:info RAILS_ENV=production
  ```

Example output:

```plaintext
Today's Date: 2020-02-29
Current User Count: 30
Max Historical Count: 30
Max Users in License: 40
License valid from: 2019-11-29 to 2020-11-28
Email associated with license: user@example.com
```

## Check GitLab configuration

The `gitlab:check` Rake task runs the following Rake tasks:

- `gitlab:gitlab_shell:check`
- `gitlab:gitaly:check`
- `gitlab:sidekiq:check`
- `gitlab:incoming_email:check`
- `gitlab:ldap:check`
- `gitlab:app:check`
- `gitlab:geo:check` (only if you're running [Geo](../geo/replication/troubleshooting/common.md#health-check-rake-task))

It checks that each component was set up according to the installation guide and suggest fixes
for issues found. This command must be run from your application server and doesn't work correctly on
component servers like [Gitaly](../gitaly/configure_gitaly.md#run-gitaly-on-its-own-server).

You may also have a look at our troubleshooting guides for:

- [GitLab](../troubleshooting/_index.md).
- [Linux package installations](https://docs.gitlab.com/omnibus/index.html#troubleshooting).

Additionally you should also [verify database values can be decrypted using the current secrets](check.md#verify-database-values-can-be-decrypted-using-the-current-secrets).

To run `gitlab:check`, run:

- Linux package installations:

  ```shell
  sudo gitlab-rake gitlab:check
  ```

- Self-compiled installations:

  ```shell
  bundle exec rake gitlab:check RAILS_ENV=production
  ```

Use `SANITIZE=true` for `gitlab:check` if you want to omit project names from the output.

Example output:

```plaintext
Checking Environment ...

Git configured for git user? ... yes
Has python2? ... yes
python2 is supported version? ... yes

Checking Environment ... Finished

Checking GitLab Shell ...

GitLab Shell version? ... OK (1.2.0)
Repo base directory exists? ... yes
Repo base directory is a symlink? ... no
Repo base owned by git:git? ... yes
Repo base access is drwxrws---? ... yes
post-receive hook up-to-date? ... yes
post-receive hooks in repos are links: ... yes

Checking GitLab Shell ... Finished

Checking Sidekiq ...

Running? ... yes

Checking Sidekiq ... Finished

Checking GitLab App...

Database config exists? ... yes
Database is SQLite ... no
All migrations up? ... yes
GitLab config exists? ... yes
GitLab config up to date? ... no
Cable config exists? ... yes
Resque config exists? ... yes
Log directory writable? ... yes
Tmp directory writable? ... yes
Init script exists? ... yes
Init script up-to-date? ... yes
Redis version >= 2.0.0? ... yes

Checking GitLab ... Finished
```

## Rebuild `authorized_keys` file

In some cases it is necessary to rebuild the `authorized_keys` file,
for example, if after an upgrade you receive `Permission denied (publickey)` when pushing [via SSH](../../user/ssh.md)
and find `404 Key Not Found` errors in [the `gitlab-shell.log` file](../logs/_index.md#gitlab-shelllog).
To rebuild `authorized_keys`, run:

- Linux package installations:

  ```shell
  sudo gitlab-rake gitlab:shell:setup
  ```

- Self-compiled installations:

  ```shell
  cd /home/git/gitlab
  sudo -u git -H bundle exec rake gitlab:shell:setup RAILS_ENV=production
  ```

Example output:

```plaintext
This will rebuild an authorized_keys file.
You will lose any data stored in authorized_keys file.
Do you want to continue (yes/no)? yes
```

## Clear Redis cache

If for some reason the dashboard displays the wrong information, you might want to
clear Redis' cache. To do this, run:

- Linux package installations:

  ```shell
  sudo gitlab-rake cache:clear
  ```

- Self-compiled installations:

  ```shell
  cd /home/git/gitlab
  sudo -u git -H bundle exec rake cache:clear RAILS_ENV=production
  ```

## Precompile the assets

Sometimes during version upgrades you might end up with some wrong CSS or
missing some icons. In that case, try to precompile the assets again.

This Rake task only applies to self-compiled installations. [Read more](../../update/package/package_troubleshooting.md#missing-asset-files)
about troubleshooting this problem when running the Linux package.
The guidance for Linux package might be applicable for Kubernetes and Docker
deployments of GitLab, though in general, container-based installations
don't have issues with missing assets.

- Self-compiled installations:

  ```shell
  cd /home/git/gitlab
  sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production
  ```

For Linux package installations, the unoptimized assets (JavaScript, CSS) are frozen at
the release of upstream GitLab. The Linux package installation includes optimized versions
of those assets. Unless you are modifying the JavaScript / CSS code on your
production machine after installing the package, there should be no reason to redo
`rake gitlab:assets:compile` on the production machine. If you suspect that assets
have been corrupted, you should reinstall the Linux package.

## Check TCP connectivity to a remote site

Sometimes you need to know if your GitLab installation can connect to a TCP
service on another machine (for example a PostgreSQL or web server)
to troubleshoot proxy issues.
A Rake task is included to help you with this.

- Linux package installations:

  ```shell
  sudo gitlab-rake gitlab:tcp_check[example.com,80]
  ```

- Self-compiled installations:

  ```shell
  cd /home/git/gitlab
  sudo -u git -H bundle exec rake gitlab:tcp_check[example.com,80] RAILS_ENV=production
  ```

## Clear exclusive lease (DANGER)

GitLab uses a shared lock mechanism: `ExclusiveLease` to prevent simultaneous operations
in a shared resource. An example is running periodic garbage collection on repositories.

In very specific situations, an operation locked by an Exclusive Lease can fail without
releasing the lock. If you can't wait for it to expire, you can run this task to manually
clear it.

To clear all exclusive leases:

WARNING:
Don't run it while GitLab or Sidekiq is running

```shell
sudo gitlab-rake gitlab:exclusive_lease:clear
```

To specify a lease `type` or lease `type + id`, specify a scope:

```shell
# to clear all leases for repository garbage collection:
sudo gitlab-rake gitlab:exclusive_lease:clear[project_housekeeping:*]

# to clear a lease for repository garbage collection in a specific project: (id=4)
sudo gitlab-rake gitlab:exclusive_lease:clear[project_housekeeping:4]
```

## Display status of database migrations

See the [background migrations documentation](../../update/background_migrations.md)
for how to check that migrations are complete when upgrading GitLab.

To check the status of specific migrations, you can use the following Rake task:

```shell
sudo gitlab-rake db:migrate:status
```

To check the [tracking database on a Geo secondary site](../geo/setup/external_database.md#configure-the-tracking-database), you can use the following Rake task:

```shell
sudo gitlab-rake db:migrate:status:geo
```

This outputs a table with a `Status` of `up` or `down` for
each migration. Example:

```shell
database: gitlabhq_production

 Status   Migration ID    Type     Milestone    Name
--------------------------------------------------
   up     20240701074848  regular  17.2         AddGroupIdToPackagesDebianGroupComponents
   up     20240701153843  regular  17.2         AddWorkItemsDatesSourcesSyncToIssuesTrigger
   up     20240702072515  regular  17.2         AddGroupIdToPackagesDebianGroupArchitectures
   up     20240702133021  regular  17.2         AddWorkspaceTerminationTimeoutsToRemoteDevelopmentAgentConfigs
   up     20240604064938  post     17.2         FinalizeBackfillPartitionIdCiPipelineMessage
   up     20240604111157  post     17.2         AddApprovalPolicyRulesFkOnApprovalGroupRules
```

Starting with GitLab 17.1, migrations are executed in an
[order](../../development/database/migration_ordering.md#171-logic) that conforms to the GitLab release cadence.

## Run incomplete database migrations

Database migrations can be stuck in an incomplete state, with a `down`
status in the output of the `sudo gitlab-rake db:migrate:status` command.

1. To complete these migrations, use the following Rake task:

   ```shell
   sudo gitlab-rake db:migrate
   ```

1. After the command completes, run `sudo gitlab-rake db:migrate:status` to check if all migrations are completed (have an `up` status).

1. Hot reload `puma` and `sidekiq` services:

   ```shell
   sudo gitlab-ctl hup puma
   sudo gitlab-ctl restart sidekiq
   ```

Starting with GitLab 17.1, migrations are executed in an
[order](../../development/database/migration_ordering.md#171-logic) that conforms to the GitLab release cadence.

## Rebuild database indexes

DETAILS:
**Status:** Experiment

WARNING:
This feature is experimental, and isn't enabled by default. Use caution when
running in a production environment, and run during off-peak times.

Database indexes can be rebuilt regularly to reclaim space and maintain healthy
levels of index bloat over time. Reindexing can also be run as a
[regular cron job](https://docs.gitlab.com/omnibus/settings/database.html#automatic-database-reindexing).
A "healthy" level of bloat is highly dependent on the specific index, but generally
should be below 30%.

Prerequisites:

- This feature requires PostgreSQL 12 or later.
- These index types are not supported: expression indexes, partitioned indexes,
  and indexes used for constraint exclusion.

To manually rebuild a database index:

1. Optional. To send annotations to a Grafana (4.6 or later) endpoint, enable annotations
   with these custom environment variables (see [setting custom environment variables](https://docs.gitlab.com/omnibus/settings/environment-variables.html)):

   1. `GRAFANA_API_URL`: The base URL for Grafana, such as `http://some-host:3000`.
   1. `GRAFANA_API_KEY`: A Grafana API key with at least `Editor role`.

1. Run the Rake task to rebuild the two indexes with the highest estimated bloat:

   ```shell
   sudo gitlab-rake gitlab:db:reindex
   ```

1. The reindexing task (`gitlab:db:reindex`) rebuilds only the two indexes in each database
   with the highest bloat. To rebuild more than two indexes, run the task again
   until all desired indexes have been rebuilt.

### Notes

- Rebuilding database indexes is a disk-intensive task, so you should perform the
  task during off-peak hours. Running the task during peak hours can lead to
  _increased_ bloat, and can also cause certain queries to perform slowly.
- The task requires free disk space for the index being restored. The created
  indexes are appended with `_ccnew`. If the reindexing task fails, re-running the
  task cleans up the temporary indexes.
- The time it takes for database index rebuilding to complete depends on the size
  of the target database. It can take between several hours and several days.

## Dump the database schema

In rare circumstances, the database schema can differ from what the application code expects
even if all database migrations are complete. If this does occur, it can lead to odd errors
in GitLab.

To dump the database schema:

```shell
SCHEMA=/tmp/structure.sql gitlab-rake db:schema:dump
```

The Rake task creates a `/tmp/structure.sql` file that contains the database schema dump.

To determine if there are any differences:

1. Go to the [`db/structure.sql`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/db/structure.sql) file in the [`gitlab`](https://gitlab.com/gitlab-org/gitlab) project.
   Select the branch that matches your GitLab version. For example, the file for GitLab 16.2: <https://gitlab.com/gitlab-org/gitlab/-/blob/16-2-stable-ee/db/structure.sql>.
1. Compare `/tmp/structure.sql` with the `db/structure.sql` file for your version.

## Check the database for schema inconsistencies

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/390719) in GitLab 15.11.

This Rake task checks the database schema for any inconsistencies and prints them in the terminal.
This task is a diagnostic tool to be used under the guidance of GitLab Support.
You should not use the task for routine checks as database inconsistencies might be expected.

```shell
gitlab-rake gitlab:db:schema_checker:run
```

## Troubleshooting

### Advisory lock connection information

After running the `db:migrate` Rake task, you may see output like the following:

```shell
main: == [advisory_lock_connection] object_id: 173580, pg_backend_pid: 5532
main: == [advisory_lock_connection] object_id: 173580, pg_backend_pid: 5532
```

The messages returned are informational and can be ignored.

### PostgreSQL socket errors when executing the `gitlab:env:info` Rake task

After running `sudo gitlab-rake gitlab:env:info` on Gitaly or other non-Rails nodes , you might see the following error:

```plaintext
PG::ConnectionBad: could not connect to server: No such file or directory
Is the server running locally and accepting
connections on Unix domain socket "/var/opt/gitlab/postgresql/.s.PGSQL.5432"?
```

This is because, in a multi-node environment, the `gitlab:env:info` Rake task should only be executed on the nodes running **GitLab Rails**.
