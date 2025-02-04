---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

To help with troubleshooting, run the following commands.

```shell
sudo gitlab-ctl status
sudo gitlab-rake gitlab:check SANITIZE=true
```

For more information on:

- Using `gitlab-ctl` for maintenance, see [Maintenance commands](https://docs.gitlab.com/omnibus/maintenance/index.html).
- Using `gitlab-rake` for configuration checking, see
  [Check GitLab configuration](../../administration/raketasks/maintenance.md#check-gitlab-configuration).

## RPM 'package is already installed' error

If you are using RPM and you are upgrading from GitLab Community Edition to GitLab Enterprise Edition you might get an
error similar to:

```shell
package gitlab-7.5.2_omnibus.5.2.1.ci-1.el7.x86_64 (which is newer than gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el7.x86_64) is already installed
```

You can override this version check with the `--oldpackage` option:

```shell
sudo rpm -Uvh --oldpackage gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el7.x86_64.rpm
```

## Package obsoleted by installed package

Community Edition (CE) and Enterprise Edition (EE) packages are marked as obsoleting each other so that both aren't
installed at the same time.

If you are using local RPM files to switch from CE to EE or vice versa, use `rpm` for installing the package rather than
`yum`. If you try to use yum, then you may get an error like this:

```plaintext
Cannot install package gitlab-ee-11.8.3-ee.0.el6.x86_64. It is obsoleted by installed package gitlab-ce-11.8.3-ce.0.el6.x86_64
```

To avoid this issue, either:

- Use the same instructions provided in the
  [Upgrade using a manually-downloaded package](_index.md#by-using-a-downloaded-package) section.
- Temporarily disable this checking in yum by adding `--setopt=obsoletes=0` to the options given to the command.

## 500 error when accessing project repository settings

This error occurs when GitLab is converted from Community Edition (CE) to Enterprise Edition (EE), and then to
CE and then back to EE.

When viewing a project's repository settings, you can see this error in the logs:

```shell
Processing by Projects::Settings::RepositoryController#show as HTML
  Parameters: {"namespace_id"=>"<namespace_id>", "project_id"=>"<project_id>"}
Completed 500 Internal Server Error in 62ms (ActiveRecord: 4.7ms | Elasticsearch: 0.0ms | Allocations: 14583)

NoMethodError (undefined method `commit_message_negative_regex' for #<PushRule:0x00007fbddf4229b8>
Did you mean?  commit_message_regex_change):
```

This error is caused by an EE feature being added to a CE instance on the initial move to EE.
After the instance is moved back to CE and then is upgraded to EE again, the
`push_rules` table already exists in the database. Therefore, a migration is
unable to add the `commit_message_regex_change` column.

This results in the [backport migration of EE tables](https://gitlab.com/gitlab-org/gitlab/-/blob/cf00e431024018ddd82158f8a9210f113d0f4dbc/db/migrate/20190402150158_backport_enterprise_schema.rb#L1619)
not working correctly. The backport migration assumes that certain tables in the database do not exist when running CE.

To fix this issue:

1. Start a database console:

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

1. Manually add the missing `commit_message_negative_regex` column:

   ```sql
   ALTER TABLE push_rules ADD COLUMN commit_message_negative_regex VARCHAR;

   # Exit psql
   \q
   ```

1. Restart GitLab:

   ```shell
   sudo gitlab-ctl restart
   ```

## 500 errors with `PG::UndefinedColumn: ERROR:..` message in logs

After upgrading, if you start getting `500` errors in the logs that show messages similar to `PG::UndefinedColumn: ERROR:...`,
these errors could be cause by either:

- [Database migrations](../background_migrations.md) not being complete. Wait until migrations are completed.
- Database migrations being complete, but GitLab needing to load the new schema. To load the new schema,
  [restart GitLab](../../administration/restart_gitlab.md).

## Error: Failed to connect to the internal GitLab API

If you receive the error `Failed to connect to the internal GitLab API` on a separate GitLab Pages server,
see the [GitLab Pages administration troubleshooting](../../administration/pages/troubleshooting.md#failed-to-connect-to-the-internal-gitlab-api)

## An error occurred during the signature verification

If you receive this error when running `apt-get update`:

```plaintext
An error occurred during the signature verification
```

Update the GPG key of the GitLab packages server with this command:

```shell
curl --silent "https://packages.gitlab.com/gpg.key" | apt-key add -
apt-get update
```

## `Mixlib::ShellOut::CommandTimeout: rails_migration[gitlab-rails] [..] Command timed out after 3600s`

If database schema and data changes (database migrations) must take more than one hour to run,
upgrades fail with a `timed out` error:

```plaintext
FATAL: Mixlib::ShellOut::CommandTimeout: rails_migration[gitlab-rails] (gitlab::database_migrations line 51)
had an error: Mixlib::ShellOut::CommandTimeout: bash[migrate gitlab-rails database]
(/opt/gitlab/embedded/cookbooks/cache/cookbooks/gitlab/resources/rails_migration.rb line 16)
had an error: Mixlib::ShellOut::CommandTimeout: Command timed out after 3600s:
```

To fix this error:

1. Run the remaining database migrations:

   ```shell
   sudo gitlab-rake db:migrate
   ```

   This command may take a very long time to complete. Use `screen` or some other mechanism to ensure
   the program is not interrupted if your SSH session drops.

1. Complete the upgrade:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Hot reload `puma` and `sidekiq` services:

   ```shell
   sudo gitlab-ctl hup puma
   sudo gitlab-ctl restart sidekiq
   ```

## Missing asset files

Following an upgrade, GitLab might not correctly serve up assets such as:

- Images
- JavaScript
- Style sheets

GitLab might generate 500 errors, or the web UI might fail to render properly.

In a scaled out GitLab environment, if one web server behind the load balancer is demonstrating
this issue, the problem occurs intermittently.

The [Rake task to recompile](../../administration/raketasks/maintenance.md#precompile-the-assets) the
assets doesn't apply to a Linux package installation which serves
pre-compiled assets from `/opt/gitlab/embedded/service/gitlab-rails/public/assets`.

The following sections outline possible causes and solutions.

### Old processes

The most likely cause of old processes is that an old Puma process is running. And old Puma process can instruct clients
to request asset files from a previous release of GitLab. Because the files no longer exist, HTTP 404 errors are returned.

A reboot is the best way to ensure these old Puma processes are no longer running. Alternatively, you can:

1. Stop Puma:

   ```shell
   gitlab-ctl stop puma
   ```

1. Check for any remaining Puma processes, and kill them:

   ```shell
   ps -ef | egrep 'puma[: ]'
   kill <processid>
   ```

1. Verify with `ps` that the Puma processes have stopped running.
1. Start Puma

   ```shell
   gitlab-ctl start puma
   ```

### Duplicate sprockets files

The compiled asset files have unique filenames in each release. The sprockets files
provide a mapping from the filenames in the application code to the unique filenames.

```plaintext
/opt/gitlab/embedded/service/gitlab-rails/public/assets/.sprockets-manifest*.json
```

Make sure there's only one sprockets file. [Rails uses the first one](https://github.com/rails/sprockets-rails/blob/118ce60b1ffeb7a85640661b014cd2ee3c4e3e56/lib/sprockets/railtie.rb#L201).

A check for duplicate sprockets files runs during Linux package upgrades:

```plaintext
GitLab discovered stale file(s) from the previous install that need to be cleaned up.
The following files need to be removed:

/opt/gitlab/embedded/service/gitlab-rails/public/assets/.sprockets-manifest-e16fdb7dd73cfdd64ed9c2cc0e35718a.json
```

Options for resolving this include:

- If you have the output from the package upgrade, remove the specified files. Then restart Puma:

  ```shell
  gitlab-ctl restart puma
  ```

- If you don't have the message, perform a reinstall to generate it again. For more information, see
  [Incomplete installation](#incomplete-installation).
- Remove all the sprockets files and then follow the instructions for an [incomplete installation](#incomplete-installation).

### Incomplete installation

An incomplete installation could be the cause of missing asset file problems.

Verify the package to determine if this is the problem:

- For Debian distributions:

  ```shell
  apt-get install debsums
  debsums -c gitlab-ee
  ```

- For Red Hat/SUSE (RPM) distributions:

  ```shell
  rpm -V gitlab-ee
  ```

To reinstall the package to fix an incomplete installation:

1. Check the installed version:

   - For Debian distributions:

     ```shell
     apt --installed list gitlab-ee
     ```

   - For Red Hat/SUSE (RPM) distributions:

     ```shell
     rpm -qa gitlab-ee
     ```

1. Reinstall the package, specifying the installed version. For example 14.4.0 Enterprise Edition:

   - For Debian distributions:

     ```shell
     apt-get install --reinstall gitlab-ee=14.4.0-ee.0
     ```

   - For Red Hat/SUSE (RPM) distributions:

     ```shell
     yum reinstall gitlab-ee-14.4.0
     ```

### NGINX Gzip support disabled

Check whether `nginx['gzip_enabled']` has been disabled:

```shell
grep gzip /etc/gitlab/gitlab.rb
```

This might prevent some assets from being served.
[Read more](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6087#note_558194395) in one of the related issues.

## ActiveRecord::LockWaitTimeout error, retrying after sleep

In rare cases, Sidekiq is busy and locks the table that migrations are trying to alter. To resolve this issue:

1. Put GitLab in read-only mode.
1. Stop Sidekiq:

   ```shell
   gitlab-ctl stop sidekiq
   ```
