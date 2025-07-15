---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Maintenance Rake tasks
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

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

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

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
- [Linux package installations](https://docs.gitlab.com/omnibus/#troubleshooting).

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

- Kubernetes installations:

  ```shell
  kubectl exec -it <toolbox-pod-name> -- sudo gitlab-rake gitlab:check
  ```

  {{< alert type="note" >}}
  Due to the specific architecture of Helm-based GitLab installations, the output may contain
  false negatives for connectivity verification to `gitlab-shell`, Sidekiq, and `systemd`-related files.
  These reported failures are expected and do not indicate actual issues, disregard them when reviewing diagnostic results.
  {{< /alert >}}
  
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

{{< alert type="warning" >}}

Don't run it while GitLab or Sidekiq is running

{{< /alert >}}

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
order that conforms to the GitLab release cadence.

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
order that conforms to the GitLab release cadence.

## Rebuild database indexes

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/42705) in GitLab 13.5 [with a flag](../../administration/feature_flags/_index.md) named `database_reindexing`. Disabled by default.
- [Enabled on GitLab.com](https://gitlab.com/groups/gitlab-org/-/epics/3989) in GitLab 13.9.
- [Enabled on GitLab Self-Managed and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188548) in GitLab 18.0.

{{< /history >}}

{{< alert type="warning" >}}

Use with caution when running in a production environment, and run during off-peak times.

{{< /alert >}}

Database indexes can be rebuilt regularly to reclaim space and maintain healthy
levels of index bloat over time. Reindexing can also be run as a
[regular cron job](https://docs.gitlab.com/omnibus/settings/database.html#automatic-database-reindexing).
A "healthy" level of bloat is highly dependent on the specific index, but generally
should be below 30%.

Prerequisites:

- This feature requires PostgreSQL 12 or later.
- These index types are **not supported**: expression indexes and indexes used for constraint exclusion.

### Run reindexing

The following task rebuilds only the two indexes in each database with the highest bloat. To rebuild more than two indexes, run the task again until all desired indexes have been rebuilt.

1. Run the reindexing task:

   ```shell
   sudo gitlab-rake gitlab:db:reindex
   ```

1. Check [application_json.log](../../administration/logs/_index.md#application_jsonlog) to verify execution or to troubleshoot.

### Customize reindexing settings

For smaller instances or to adjust reindexing behavior, you can modify these settings using the Rails console:

```shell
sudo gitlab-rails console
```

Then customize the configuration:

```ruby
# Lower minimum index size to 100 MB (default is 1 GB)
Gitlab::Database::Reindexing.minimum_index_size!(100.megabytes)

# Change minimum bloat threshold to 30% (default is 20%, there is no benefit from setting it lower)
Gitlab::Database::Reindexing.minimum_relative_bloat_size!(0.3)
```

### Automated reindexing

For larger instances with significant database size, automate database reindexing by scheduling it to run during periods of low activity.

#### Schedule with crontab

For packaged GitLab installations, use crontab:

1. Edit the crontab:

   ```shell
   sudo crontab -e
   ```

1. Add an entry based on your preferred schedule:

   1. Option 1: Run daily during quiet periods

   ```shell
   # Run database reindexing every day at 21:12
   # The log will be rotated by the packaged logrotate daemon
   12 21 * * * /opt/gitlab/bin/gitlab-rake gitlab:db:reindex >> /var/log/gitlab/gitlab-rails/cron_reindex.log 2>&1
   ```

   1. Option 2: Run on weekends only

   ```shell
   # Run database reindexing at 01:00 AM on weekends
   0 1 * * 0,6 /opt/gitlab/bin/gitlab-rake gitlab:db:reindex >> /var/log/gitlab/gitlab-rails/cron_reindex.log 2>&1
   ```

   1. Option 3: Run frequently during low-traffic hours

   ```shell
   # Run database reindexing every 3 hours during night hours (22:00-07:00)
   0 22,1,4,7 * * * /opt/gitlab/bin/gitlab-rake gitlab:db:reindex >> /var/log/gitlab/gitlab-rails/cron_reindex.log 2>&1
   ```

For Kubernetes deployments, you can create a similar schedule using the CronJob resource to run the reindexing task.

### Notes

- Rebuilding database indexes is a disk-intensive task, so you should perform the
  task during off-peak hours. Running the task during peak hours can lead to
  increased bloat, and can also cause certain queries to perform slowly.
- The task requires free disk space for the index being restored. The created
  indexes are appended with `_ccnew`. If the reindexing task fails, re-running the
  task cleans up the temporary indexes.
- The time it takes for database index rebuilding to complete depends on the size
  of the target database. It can take between several hours and several days.
- The task uses Redis locks, it's safe to schedule it to run frequently.
  It's a no-op if another reindexing task is already running.

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

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/390719) in GitLab 15.11.

{{< /history >}}

This Rake task checks the database schema for any inconsistencies and prints them in the terminal.
This task is a diagnostic tool to be used under the guidance of GitLab Support.
You should not use the task for routine checks as database inconsistencies might be expected.

```shell
gitlab-rake gitlab:db:schema_checker:run
```

## Collect information and statistics about the database

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-com/-/epics/2456) in GitLab 17.11.

{{< /history >}}

The `gitlab:db:sos` command gathers configuration, performance, and diagnostic data about your GitLab
database to help you troubleshoot issues. Where you run this command depends on your configuration. Make sure
to run this command relative to where GitLab is installed `(/gitlab)`.

- **Scaled GitLab**: on your Puma or Sidekiq server.
- **Cloud native install**: on the toolbox pod.
- **All other configurations**: on your GitLab server.

Modify the command as needed:

- **Default path** - To run the command with the default file path (`/var/opt/gitlab/gitlab-rails/tmp/sos.zip`), run `gitlab-rake gitlab:db:sos`.
- **Custom path** - To change the file path, run `gitlab-rake gitlab:db:sos["/absolute/custom/path/to/file.zip"]`.
- **Zsh users** - If you have not modified your Zsh configuration, you must add quotation marks
  around the entire command, like this: `gitlab-rake "gitlab:db:sos[/absolute/custom/path/to/file.zip]"`

The Rake task runs for five minutes. It creates a compressed folder in the path you specify.
The compressed folder contains a large number of files.

### Enable optional query statistics data

The `gitlab:db:sos` Rake task can also gather data for troubleshooting slow queries using the
[`pg_stat_statements` extension](https://www.postgresql.org/docs/16/pgstatstatements.html).

Enabling this extension is optional, and requires restarting PostgreSQL and GitLab. This data is
likely required for troubleshooting GitLab performance issues caused by slow database queries.

Prerequisites:

- You must be a PostgreSQL user with superuser privileges to enable or disable an extension.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modify `/etc/gitlab/gitlab.rb` to add the following line:

   ```ruby
   postgresql['shared_preload_libraries'] = 'pg_stat_statements'
   ```

1. Run reconfigure:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. PostgreSQL needs to restart to load this extension, requiring a GitLab restart as well:

   ```shell
   sudo gitlab-ctl restart postgresql
   sudo gitlab-ctl restart sidekiq
   sudo gitlab-ctl restart puma
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Modify `/etc/gitlab/gitlab.rb` to add the following line:

   ```ruby
   postgresql['shared_preload_libraries'] = 'pg_stat_statements'
   ```

1. Run reconfigure:

   ```shell
   docker exec -it <container-id> gitlab-ctl reconfigure
   ```

1. PostgreSQL needs to restart to load this extension, requiring a GitLab restart as well:

   ```shell
   docker exec -it <container-id> gitlab-ctl restart postgresql
   docker exec -it <container-id> gitlab-ctl restart sidekiq
   docker exec -it <container-id> gitlab-ctl restart puma
   ```

{{< /tab >}}

{{< tab title="External PostgreSQL service" >}}

1. Add or uncomment the following parameters in your `postgresql.conf` file

   ```shell
   shared_preload_libraries = 'pg_stat_statements'
   pg_stat_statements.track = all
   ```

1. Restart PostgreSQL for the changes to take effect.

1. Restart GitLab: the web (Puma) and Sidekiq services should be restarted.

{{< /tab >}}

{{< /tabs >}}

1. On the [database console](../troubleshooting/postgresql.md) run:

   ```SQL
   CREATE EXTENSION pg_stat_statements;
   ```

1. Check the extension is working:

   ```SQL
   SELECT extname FROM pg_extension WHERE extname = 'pg_stat_statements';
   SELECT * FROM pg_stat_statements LIMIT 10;
   ```

## Check the database for duplicate CI/CD tags

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/518698) in GitLab 17.10.

{{< /history >}}

This Rake task checks the `ci` database for duplicate tags in the `tags` table.
This issue might affect instances that have undergone multiple major upgrades over an extended period.
Run the following command to search duplicate tags, then rewrite any tag assignments that
reference duplicate tags to use the original tag instead.

```shell
sudo gitlab-rake gitlab:db:deduplicate_tags
```

To run this command in dry-run mode, set the environment variable `DRY_RUN=true`.

## Detect PostgreSQL collation version mismatches

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/195450) in GitLab 18.2.

{{< /history >}}

The PostgreSQL collation checker detects collation version mismatches between the database and
operating system that can cause index corruption. PostgreSQL uses the operating
system's `glibc` library for string collation (sorting and comparison rules).
Run this task after operating system upgrades that change the underlying `glibc` library.

Prerequisites:

- PostgreSQL 13 or later.

To check for PostgreSQL collation mismatches in all databases:

```shell
sudo gitlab-rake gitlab:db:collation_checker
```

To check a specific database:

```shell
# Check main database
sudo gitlab-rake gitlab:db:collation_checker:main

# Check CI database
sudo gitlab-rake gitlab:db:collation_checker:ci
```

### Example output

When no issues are found:

```plaintext
Checking for PostgreSQL collation mismatches on main database...
No collation mismatches detected on main.
```

If mismatches are detected, the task provides remediation steps to fix the affected indexes.

Example output with mismatches:

```plaintext
Checking for PostgreSQL collation mismatches on main database...
⚠️ COLLATION MISMATCHES DETECTED on main database!
2 collation(s) have version mismatches:
  - en_US.utf8: stored=428.1, actual=513.1
  - es_ES.utf8: stored=428.1, actual=513.1

Affected indexes that need to be rebuilt:
  - index_projects_on_name (btree) on table projects
    • Affected columns: name
    • Type: UNIQUE

REMEDIATION STEPS:
1. Put GitLab into maintenance mode
2. Run the following SQL commands:

# Step 1: Check for duplicate entries in unique indexes
SELECT name, COUNT(*), ARRAY_AGG(id) FROM projects GROUP BY name HAVING COUNT(*) > 1 LIMIT 1;

# If duplicates exist, you may need to use gitlab:db:deduplicate_tags or similar tasks
# to fix duplicate entries before rebuilding unique indexes.

# Step 2: Rebuild affected indexes
# Option A: Rebuild individual indexes with minimal downtime:
REINDEX INDEX CONCURRENTLY index_projects_on_name;

# Option B: Alternatively, rebuild all indexes at once (requires downtime):
REINDEX DATABASE main;

# Step 3: Refresh collation versions
ALTER COLLATION "en_US.utf8" REFRESH VERSION;
ALTER COLLATION "es_ES.utf8" REFRESH VERSION;

3. Take GitLab out of maintenance mode
```

For more information about PostgreSQL collation issues and how they affect database indexes, see the [PostgreSQL upgrading OS documentation](../postgresql/upgrading_os.md).

## Troubleshooting

### Advisory lock connection information

After running the `db:migrate` Rake task, you may see output like the following:

```shell
main: == [advisory_lock_connection] object_id: 173580, pg_backend_pid: 5532
main: == [advisory_lock_connection] object_id: 173580, pg_backend_pid: 5532
```

The messages returned are informational and can be ignored.

### PostgreSQL socket errors when executing the `gitlab:env:info` Rake task

After running `sudo gitlab-rake gitlab:env:info` on Gitaly or other non-Rails nodes, you might see the following error:

```plaintext
PG::ConnectionBad: could not connect to server: No such file or directory
Is the server running locally and accepting
connections on Unix domain socket "/var/opt/gitlab/postgresql/.s.PGSQL.5432"?
```

This is because, in a multi-node environment, the `gitlab:env:info` Rake task should only be executed on the nodes running **GitLab Rails**.
