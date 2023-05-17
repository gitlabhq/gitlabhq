---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Upgrade GitLab by using the GitLab package **(FREE SELF)**

You can upgrade GitLab to a new version by using the
GitLab package.

## Prerequisites

- Decide when to upgrade by viewing the [supported upgrade paths](../index.md#upgrade-paths).
  You can't directly skip major versions (for example, go from 10.3 to 12.7 in one step).
- If you are upgrading from a non-package installation to a GitLab package installation, see
  [Upgrading from a non-package installation to a GitLab package installation](https://docs.gitlab.com/omnibus/update/convert_to_omnibus.html).
- Ensure that any
  [background migrations](../background_migrations.md)
  are fully completed. Upgrading
  before background migrations have finished can lead to data corruption.
  We recommend performing upgrades between major and minor releases no more than once per
  week, to allow time for background migrations to finish.
- Gitaly servers must be upgraded to the newer version prior to upgrading the application server.
  This prevents the gRPC client on the application server from sending RPCs that the old Gitaly version
  does not support.

## Downtime

- For single node installations, GitLab is not available to users while an
  upgrade is in progress. The user's web browser shows a `Deploy in progress` message or a `502` error.
- For multi-node installations, see how to perform
  [zero downtime upgrades](../zero_downtime.md).
- Upgrades to multi-node installations can also be performed
  [with downtime](../with_downtime.md).

## Version-specific changes

Upgrading versions might need some manual intervention. For more information,
check the version your are upgrading to:

- [GitLab 15](https://docs.gitlab.com/omnibus/update/gitlab_15_changes.html)
- [GitLab 14](https://docs.gitlab.com/omnibus/update/gitlab_14_changes.html)
- [GitLab 13](https://docs.gitlab.com/omnibus/update/gitlab_13_changes.html)
- [GitLab 12](https://docs.gitlab.com/omnibus/update/gitlab_12_changes.html)
- [GitLab 11](https://docs.gitlab.com/omnibus/update/gitlab_11_changes.html)

## Back up before upgrading

The GitLab database is backed up before installing a newer GitLab version. You
may skip this automatic database backup by creating an empty file
at `/etc/gitlab/skip-auto-backup`:

```shell
sudo touch /etc/gitlab/skip-auto-backup
```

Nevertheless, it is highly recommended to maintain a full up-to-date
[backup](../../raketasks/backup_restore.md) on your own.

## Upgrade using the official repositories

All GitLab packages are posted to the GitLab [package server](https://packages.gitlab.com/gitlab/).
Five repositories are maintained:

- [`gitlab/gitlab-ee`](https://packages.gitlab.com/gitlab/gitlab-ee): The full
  GitLab package that contains all the Community Edition features plus the
  [Enterprise Edition](https://about.gitlab.com/pricing/) ones.
- [`gitlab/gitlab-ce`](https://packages.gitlab.com/gitlab/gitlab-ce): A stripped
  down package that contains only the Community Edition features.
- [`gitlab/unstable`](https://packages.gitlab.com/gitlab/unstable): Release candidates and other unstable versions.
- [`gitlab/nightly-builds`](https://packages.gitlab.com/gitlab/nightly-builds): Nightly builds.
- [`gitlab/raspberry-pi2`](https://packages.gitlab.com/gitlab/raspberry-pi2): Official Community Edition releases built for [Raspberry Pi](https://www.raspberrypi.org) packages.

If you have installed GitLab [Community Edition](https://about.gitlab.com/install/?version=ce)
or [Enterprise Edition](https://about.gitlab.com/install/), then the
official GitLab repository should have already been set up for you.

### Upgrade to the latest version using the official repositories

If you upgrade GitLab regularly, for example once a month, you can upgrade to
the latest version by using your package manager.

To upgrade to the latest GitLab version:

```shell
# Ubuntu/Debian
sudo apt update && sudo apt install gitlab-ee

# RHEL/CentOS 6 and 7
sudo yum install gitlab-ee

# RHEL/CentOS 8
sudo dnf install gitlab-ee

# SUSE
sudo zypper install gitlab-ee
```

NOTE:
For the GitLab Community Edition, replace `gitlab-ee` with
`gitlab-ce`.

### Upgrade to a specific version using the official repositories

Linux package managers default to installing the latest available version of a
package for installation and upgrades. Upgrading directly to the latest major
version can be problematic for older GitLab versions that require a multi-stage
[upgrade path](../index.md#upgrade-paths). An upgrade path can span multiple
versions, so you must specify the specific GitLab package with each upgrade.

To specify the intended GitLab version number in your package manager's install
or upgrade command:

1. Identify the version number of the installed package:

   ```shell
   # Ubuntu/Debian
   sudo apt-cache madison gitlab-ee

   # RHEL/CentOS 6 and 7
   yum --showduplicates list gitlab-ee

   # RHEL/CentOS 8
   dnf --showduplicates list gitlab-ee

   # SUSE
   zypper search -s gitlab-ee
   ```

1. Install the specific `gitlab-ee` package by using one of the following commands
   and replacing `<version>` with the next supported version you would like to install
   (make sure to review the [upgrade path](../index.md#upgrade-paths) to confirm the
   version you're installing is part of a supported path):

   ```shell
   # Ubuntu/Debian
   sudo apt install gitlab-ee=<version>

   # RHEL/CentOS 6 and 7
   yum install gitlab-ee-<version>

   # RHEL/CentOS 8
   dnf install gitlab-ee-<version>

   # SUSE
   zypper install gitlab-ee=<version>
   ```

NOTE:
For the GitLab Community Edition, replace `gitlab-ee` with
`gitlab-ce`.

## Upgrade using a manually-downloaded package

NOTE:
The [package repository](#upgrade-using-the-official-repositories) is recommended over
a manual installation.

If for some reason you don't use the official repositories, you can
download the package and install it manually. This method can be used to either
install GitLab for the first time or upgrade it.

To download and install GitLab:

1. Visit the [official repository](#upgrade-using-the-official-repositories) of your package.
1. Filter the list by searching for the version you want to install (for example 14.1.8).
   Multiple packages may exist for a single version, one for each supported distribution
   and architecture. Next to the filename is a label indicating the distribution,
   as the filenames may be the same.
1. Find the package version you wish to install, and select the filename from the list.
1. In the upper-right corner, select **Download**.
1. After the package is downloaded, install it by using one of the
   following commands and replacing `<package_name>` with the package name
   you downloaded:

   ```shell
   # Debian/Ubuntu
   dpkg -i <package_name>

   # RHEL/CentOS 6 and 7 
   rpm -Uvh <package_name>

   # RHEL/CentOS 8
   dnf install <package_name>

   # SUSE
   zypper install <package_name>
   ```

NOTE:
For the GitLab Community Edition, replace `gitlab-ee` with
`gitlab-ce`.

## Upgrade the product documentation

This is an optional step. If you [installed the product documentation](../../administration/docs_self_host.md),
see how to [upgrade to a later version](../../administration/docs_self_host.md#upgrade-using-docker).

## Troubleshooting

### Get the status of a GitLab installation

```shell
sudo gitlab-ctl status
sudo gitlab-rake gitlab:check SANITIZE=true
```

- Information on using `gitlab-ctl` to perform [maintenance tasks](https://docs.gitlab.com/omnibus/maintenance/index.html).
- Information on using `gitlab-rake` to [check the configuration](../../administration/raketasks/maintenance.md#check-gitlab-configuration).

### RPM 'package is already installed' error

If you are using RPM and you are upgrading from GitLab Community Edition to GitLab Enterprise Edition you may get an error like this:

```shell
package gitlab-7.5.2_omnibus.5.2.1.ci-1.el7.x86_64 (which is newer than gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el7.x86_64) is already installed
```

You can override this version check with the `--oldpackage` option:

```shell
sudo rpm -Uvh --oldpackage gitlab-7.5.2_ee.omnibus.5.2.1.ci-1.el7.x86_64.rpm
```

### Package obsoleted by installed package

CE and EE packages are marked as obsoleting and replacing each other so that both aren't installed and running at the same time.

If you are using local RPM files to switch from CE to EE or vice versa, use `rpm` for installing the package rather than `yum`. If you try to use yum, then you may get an error like this:

```plaintext
Cannot install package gitlab-ee-11.8.3-ee.0.el6.x86_64. It is obsoleted by installed package gitlab-ce-11.8.3-ce.0.el6.x86_64
```

To avoid this issue, either:

- Use the same instructions provided in the
  [Upgrade using a manually-downloaded package](#upgrade-using-a-manually-downloaded-package) section.
- Temporarily disable this checking in yum by adding `--setopt=obsoletes=0` to the options given to the command.

### 500 error when accessing Project > Settings > Repository

This error occurs when GitLab is converted from CE > EE > CE, and then back to EE.
When viewing a project's repository settings, you can view this error in the logs:

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

This results in the [backport migration of EE tables](https://gitlab.com/gitlab-org/gitlab/-/blob/cf00e431024018ddd82158f8a9210f113d0f4dbc/db/migrate/20190402150158_backport_enterprise_schema.rb#L1619) not working correctly.
The backport migration assumes that certain tables in the database do not exist when running CE.

To fix this issue:

1. Start a database console:

   In GitLab 14.2 and later:

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   In GitLab 14.1 and earlier:

   ```shell
   sudo gitlab-rails dbconsole
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

### Error `Failed to connect to the internal GitLab API` on a separate GitLab Pages server

See [GitLab Pages administration troubleshooting](../../administration/pages/troubleshooting.md#failed-to-connect-to-the-internal-gitlab-api).

### Error `An error occurred during the signature verification` when running `apt-get update`

To update the GPG key of the GitLab packages server run:

```shell
curl --silent "https://packages.gitlab.com/gpg.key" | apt-key add -
apt-get update
```

### `Mixlib::ShellOut::CommandTimeout: rails_migration[gitlab-rails] [..] Command timed out after 3600s`

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

### Missing asset files

Following an upgrade, GitLab might not be correctly serving up assets such as images, JavaScript, and style sheets.
It might be generating 500 errors, or the web UI may be failing to render properly.

In a scaled out GitLab environment, if one web server behind the load balancer is demonstrating
this issue, the problem occurs intermittently.

The [Rake task to recompile](../../administration/raketasks/maintenance.md#precompile-the-assets) the
assets doesn't apply to an Omnibus installation which serves
pre-compiled assets from `/opt/gitlab/embedded/service/gitlab-rails/public/assets`.

Potential causes and fixes:

- [Ensure no old processes are running](#old-processes).
- [Remove duplicate sprockets files](#duplicate-sprockets-files)
- [The installation is incomplete](#incomplete-installation)
- [NGINX Gzip support is disabled](#nginx-gzip-support)

#### Old processes

The most likely cause is that an old Puma process is running, instructing clients
to request asset files from a previous release of GitLab. As the files no longer exist,
HTTP 404 errors are returned.

A reboot is the best way to ensure these old Puma processes are no longer running.

Alternatively:

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

#### Duplicate sprockets files

The compiled asset files have unique file names in each release. The sprockets files
provide a mapping from the filenames in the application code to the unique filenames.

```plaintext
/opt/gitlab/embedded/service/gitlab-rails/public/assets/.sprockets-manifest*.json
```

Make sure there's only one sprockets file. [Rails uses the first one](https://github.com/rails/sprockets-rails/blob/118ce60b1ffeb7a85640661b014cd2ee3c4e3e56/lib/sprockets/railtie.rb#L201).

A check for duplicate sprockets files runs during Omnibus GitLab upgrades:

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

- If you don't have the message, perform a reinstall
  (see [incomplete installation](#incomplete-installation) below for more details)
  to generate it again.

- Remove all the sprockets files and then follow the instructions for an [incomplete installation](#incomplete-installation).

#### Incomplete installation

An incomplete installation could be the cause of this issue.

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

1. Check the installed version

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

#### NGINX Gzip support

Check whether `nginx['gzip_enabled']` has been disabled:

```shell
grep gzip /etc/gitlab/gitlab.rb
```

This might prevent some assets from being served.
[Read more](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6087#note_558194395) in one of the related issues.
