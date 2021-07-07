---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Upgrading GitLab **(FREE SELF)**

Upgrading GitLab is a relatively straightforward process, but the complexity
can increase based on the installation method you have used, how old your
GitLab version is, if you're upgrading to a major version, and so on.

Make sure to read the whole page as it contains information related to every upgrade method.

The [maintenance policy documentation](../policy/maintenance.md)
has additional information about upgrading, including:

- How to interpret GitLab product versioning.
- Recommendations on the what release to run.
- How we use patch and security patch releases.
- When we backport code changes.

## Upgrade based on installation method

Depending on the installation method and your GitLab version, there are multiple
official ways to update GitLab:

- [Linux packages (Omnibus GitLab)](#linux-packages-omnibus-gitlab)
- [Source installations](#installation-from-source)
- [Docker installations](#installation-using-docker)
- [Kubernetes (Helm) installations](#installation-using-helm)

### Linux packages (Omnibus GitLab)

The [Omnibus update guide](https://docs.gitlab.com/omnibus/update/)
contains the steps needed to update a package installed by official GitLab
repositories.

There are also instructions when you want to
[update to a specific version](https://docs.gitlab.com/omnibus/update/#multi-step-upgrade-using-the-official-repositories).

### Installation from source

- [Upgrading Community Edition and Enterprise Edition from
  source](upgrading_from_source.md) - The guidelines for upgrading Community
  Edition and Enterprise Edition from source.
- [Patch versions](patch_versions.md) guide includes the steps needed for a
  patch version, such as 13.2.0 to 13.2.1, and apply to both Community and Enterprise
  Editions.

In the past we used separate documents for the upgrading instructions, but we
have since switched to using a single document. The old upgrading guidelines
can still be found in the Git repository:

- [Old upgrading guidelines for Community Edition](https://gitlab.com/gitlab-org/gitlab-foss/tree/11-8-stable/doc/update)
- [Old upgrading guidelines for Enterprise Edition](https://gitlab.com/gitlab-org/gitlab/-/tree/11-8-stable-ee/doc/update)

### Installation using Docker

GitLab provides official Docker images for both Community and Enterprise
editions. They are based on the Omnibus package and instructions on how to
update them are in [a separate document](https://docs.gitlab.com/omnibus/docker/README.html).

### Installation using Helm

GitLab can be deployed into a Kubernetes cluster using Helm.
Instructions on how to update a cloud-native deployment are in
[a separate document](https://docs.gitlab.com/charts/installation/upgrade.html).

Use the [version mapping](https://docs.gitlab.com/charts/installation/version_mappings.html)
from the chart version to GitLab version to determine the [upgrade path](#upgrade-paths).

## Checking for background migrations before upgrading

Certain major/minor releases may require a set of background migrations to be
finished. The number of remaining migrations jobs can be found by running the
following command:

**For Omnibus installations**

If using GitLab 12.9 and newer, run:

```shell
sudo gitlab-rails runner -e production 'puts Gitlab::BackgroundMigration.remaining'
```

If using GitLab 12.8 and older, run the following using a [Rails console](../administration/operations/rails_console.md#starting-a-rails-console-session):

```ruby
puts Sidekiq::Queue.new("background_migration").size
Sidekiq::ScheduledSet.new.select { |r| r.klass == 'BackgroundMigrationWorker' }.size
```

**For installations from source**

If using GitLab 12.9 and newer, run:

```shell
cd /home/git/gitlab
sudo -u git -H bundle exec rails runner -e production 'puts Gitlab::BackgroundMigration.remaining'
```

If using GitLab 12.8 and older, run the following using a [Rails console](../administration/operations/rails_console.md#starting-a-rails-console-session):

```ruby
Sidekiq::Queue.new("background_migration").size
Sidekiq::ScheduledSet.new.select { |r| r.klass == 'BackgroundMigrationWorker' }.size
```

### Batched background migrations

See the documentation on [batched background migrations](../user/admin_area/monitoring/background_migrations.md).

### What do I do if my background migrations are stuck?

WARNING:
The following operations can disrupt your GitLab performance.

It is safe to re-execute these commands, especially if you have 1000+ pending jobs which would likely overflow your runtime memory.

**For Omnibus installations**

```shell
# Start the rails console
sudo gitlab-rails c

# Execute the following in the rails console
scheduled_queue = Sidekiq::ScheduledSet.new
pending_job_classes = scheduled_queue.select { |job| job["class"] == "BackgroundMigrationWorker" }.map { |job| job["args"].first }.uniq
pending_job_classes.each { |job_class| Gitlab::BackgroundMigration.steal(job_class) }
```

**For installations from source**

```shell
# Start the rails console
sudo -u git -H bundle exec rails RAILS_ENV=production

# Execute the following in the rails console
scheduled_queue = Sidekiq::ScheduledSet.new
pending_job_classes = scheduled_queue.select { |job| job["class"] == "BackgroundMigrationWorker" }.map { |job| job["args"].first }.uniq
pending_job_classes.each { |job_class| Gitlab::BackgroundMigration.steal(job_class) }
```

## Dealing with running CI/CD pipelines and jobs

If you upgrade your GitLab instance while the GitLab Runner is processing jobs, the trace updates will fail. Once GitLab is back online, then the trace updates should self-heal. However, depending on the error, the GitLab Runner will either retry or eventually terminate job handling.

As for the artifacts, the GitLab Runner will attempt to upload them three times, after which the job will eventually fail.

To address the above two scenario's, it is advised to do the following prior to upgrading:

1. Plan your maintenance.
1. Pause your runners.
1. Wait until all jobs are finished.
1. Upgrade GitLab.

## Checking for pending Advanced Search migrations

This section is only applicable if you have enabled the [Elasticsearch
integration](../integration/elasticsearch.md).

Major releases require all [Advanced Search
migrations](../integration/elasticsearch.md#advanced-search-migrations) to
be finished from the most recent minor release in your current version
before the major version upgrade. You can find pending migrations by
running the following command:

**For Omnibus installations**

```shell
sudo gitlab-rake gitlab:elastic:list_pending_migrations
```

**For installations from source**

```shell
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:elastic:list_pending_migrations
```

### What do I do if my Advanced Search migrations are stuck?

See [how to retry a halted
migration](../integration/elasticsearch.md#retry-a-halted-migration).

## Upgrade paths

Upgrading across multiple GitLab versions in one go is *only possible with downtime*.
The following examples assume a downtime upgrade.
See the section below for [zero downtime upgrades](#upgrading-without-downtime).

Find where your version sits in the upgrade path below, and upgrade GitLab
accordingly, while also consulting the
[version-specific upgrade instructions](#version-specific-upgrading-instructions):

`8.11.Z` -> [`8.12.0`](#upgrades-from-versions-earlier-than-812) -> `8.17.7` -> `9.5.10` -> `10.8.7` -> [`11.11.8`](#1200) -> `12.0.12` -> [`12.1.17`](#1210) -> `12.10.14` -> `13.0.14` -> [`13.1.11`](#1310) -> [latest `13.12.Z`](https://about.gitlab.com/releases/categories/releases/) -> [latest `14.0.Z`](https://about.gitlab.com/releases/categories/releases/) -> [latest `14.Y.Z`](https://about.gitlab.com/releases/categories/releases/)

The following table, while not exhaustive, shows some examples of the supported
upgrade paths.

| Target version | Your version | Supported upgrade path | Note |
| --------------------- | ------------ | ------------------------ | ---- |
| `14.1.0`                | `13.9.2`      | `13.9.2` -> `13.12.6` -> `14.0.3` -> `14.1.0` | Two intermediate versions are required: `13.12` and `14.0`, then `14.1.0`. |
| `13.5.4`                | `12.9.2`      | `12.9.2` -> `12.10.14` -> `13.0.14`  -> `13.1.11` -> `13.5.4` | Three intermediate versions are required: `12.10`, `13.0` and `13.1`, then `13.5.4`. |
| `13.2.10`                | `11.5.0`      | `11.5.0` -> `11.11.8` -> `12.0.12` -> `12.1.17` -> `12.10.14` -> `13.0.14` -> `13.1.11` -> `13.2.10` | Six intermediate versions are required: `11.11`, `12.0`, `12.1`, `12.10`, `13.0` and `13.1`, then `13.2.10`. |
| `12.10.14`             | `11.3.4`       | `11.3.4` -> `11.11.8` -> `12.0.12` -> `12.1.17` -> `12.10.14`             |  Three intermediate versions are required: `11.11`, `12.0` and `12.1`, then `12.10.14`. |
| `12.9.5`             | `10.4.5`       | `10.4.5` -> `10.8.7` -> `11.11.8` -> `12.0.12` -> `12.1.17` -> `12.9.5`   | Four intermediate versions are required: `10.8`, `11.11`, `12.0` and `12.1`, then `12.9.5`. |
| `12.2.5`              | `9.2.6`        | `9.2.6` -> `9.5.10` -> `10.8.7` -> `11.11.8` -> `12.0.12` -> `12.1.17` -> `12.2.5` | Five intermediate versions are required: `9.5`, `10.8`, `11.11`, `12.0`, `12.1`, then `12.2.5`. |
| `11.3.4`              | `8.13.4`       | `8.13.4` -> `8.17.7` -> `9.5.10` -> `10.8.7` -> `11.3.4` | `8.17.7` is the last version in version 8, `9.5.10` is the last version in version 9, `10.8.7` is the last version in version 10. |

## Upgrading to a new major version

Upgrading the *major* version requires more attention.
Backward-incompatible changes and migrations are reserved for major versions.
Follow the directions carefully as we
cannot guarantee that upgrading between major versions will be seamless.

It is required to follow the following upgrade steps to ensure a successful *major* version upgrade:

1. Upgrade to the latest minor version of the preceeding major version.
1. Upgrade to the first minor version (`X.0.Z`) of the target major version.
1. Proceed with upgrading to a newer release.

Identify a [supported upgrade path](#upgrade-paths).

It's also important to ensure that any background migrations have been fully completed
before upgrading to a new major version. To see the current size of the `background_migration` queue,
[Check for background migrations before upgrading](#checking-for-background-migrations-before-upgrading).

If you have enabled the [Elasticsearch
integration](../integration/elasticsearch.md), then ensure
all Advanced Search migrations are completed in the last minor version within
your current version. Be sure to [check for pending Advanced Search
migrations](#checking-for-pending-advanced-search-migrations) before proceeding
with the major version upgrade.

If your GitLab instance has any runners associated with it, it is very
important to upgrade GitLab Runner to match the GitLab minor version that was
upgraded to. This is to ensure [compatibility with GitLab versions](https://docs.gitlab.com/runner/#compatibility-with-gitlab-versions).

## Upgrading without downtime

Starting with GitLab 9.1.0 it's possible to upgrade to a newer major, minor, or
patch version of GitLab without having to take your GitLab instance offline.
However, for this to work there are the following requirements:

- You can only upgrade 1 minor release at a time. So from 9.1 to 9.2, not to
   9.3. If you skip releases, database modifications may be run in the wrong
   sequence [and leave the database schema in a broken state](https://gitlab.com/gitlab-org/gitlab/-/issues/321542).
- You have to use [post-deployment
   migrations](../development/post_deployment_migrations.md) (included in
   [zero downtime update steps below](#steps)).
- You are using PostgreSQL. Starting from GitLab 12.1, MySQL is not supported.
- Multi-node GitLab instance. Single-node instances may experience brief interruptions
  [as services restart (Puma in particular)](https://docs.gitlab.com/omnibus/update/README.html#single-node-deployment).

Most of the time you can safely upgrade from a patch release to the next minor
release if the patch release is not the latest. For example, upgrading from
9.1.1 to 9.2.0 should be safe even if 9.1.2 has been released. We do recommend
you check the release posts of any releases between your current and target
version just in case they include any migrations that may require you to upgrade
1 release at a time.

Some releases may also include so called "background migrations". These
migrations are performed in the background by Sidekiq and are often used for
migrating data. Background migrations are only added in the monthly releases.

Certain major/minor releases may require a set of background migrations to be
finished. To guarantee this, such a release processes any remaining jobs
before continuing the upgrading procedure. While this doesn't require downtime
(if the above conditions are met) we recommend users to keep at least 1 week
between upgrading major/minor releases, allowing the background migrations to
finish. The time necessary to complete these migrations can be reduced by
increasing the number of Sidekiq workers that can process jobs in the
`background_migration` queue. To see the size of this queue,
[Check for background migrations before upgrading](#checking-for-background-migrations-before-upgrading).

As a rule of thumb, any database smaller than 10 GB doesn't take too much time to
upgrade; perhaps an hour at most per minor release. Larger databases however may
require more time, but this is highly dependent on the size of the database and
the migrations that are being performed.

### Examples

To help explain this, let's look at some examples.

**Example 1:** You are running a large GitLab installation using version 9.4.2,
which is the latest patch release of 9.4. When GitLab 9.5.0 is released this
installation can be safely upgraded to 9.5.0 without requiring downtime if the
requirements mentioned above are met. You can also skip 9.5.0 and upgrade to
9.5.1 after it's released, but you **can not** upgrade straight to 9.6.0; you
_have_ to first upgrade to a 9.5.Z release.

**Example 2:** You are running a large GitLab installation using version 9.4.2,
which is the latest patch release of 9.4. GitLab 9.5 includes some background
migrations, and 10.0 requires these to be completed (processing any
remaining jobs for you). Skipping 9.5 is not possible without downtime, and due
to the background migrations would require potentially hours of downtime
depending on how long it takes for the background migrations to complete. To
work around this you have to upgrade to 9.5.Z first, then wait at least a
week before upgrading to 10.0.

**Example 3:** You use MySQL as the database for GitLab. Any upgrade to a new
major/minor release requires downtime. If a release includes any background
migrations this could potentially lead to hours of downtime, depending on the
size of your database. To work around this you must use PostgreSQL and
meet the other online upgrade requirements mentioned above.

### Steps

Steps to [upgrade without downtime](https://docs.gitlab.com/omnibus/update/README.html#zero-downtime-updates).

## Upgrading between editions

GitLab comes in two flavors: [Community Edition](https://about.gitlab.com/features/#community) which is MIT licensed,
and [Enterprise Edition](https://about.gitlab.com/features/#enterprise) which builds on top of the Community Edition and
includes extra features mainly aimed at organizations with more than 100 users.

Below you can find some guides to help you change GitLab editions.

### Community to Enterprise Edition

NOTE:
The following guides are for subscribers of the Enterprise Edition only.

If you wish to upgrade your GitLab installation from Community to Enterprise
Edition, follow the guides below based on the installation method:

- [Source CE to EE update guides](upgrading_from_ce_to_ee.md) - The steps are very similar
  to a version upgrade: stop the server, get the code, update configuration files for
  the new functionality, install libraries and do migrations, update the init
  script, start the application and check its status.
- [Omnibus CE to EE](https://docs.gitlab.com/omnibus/update/README.html#update-community-edition-to-enterprise-edition) - Follow this guide to update your Omnibus
  GitLab Community Edition to the Enterprise Edition.

### Enterprise to Community Edition

If you need to downgrade your Enterprise Edition installation back to Community
Edition, you can follow [this guide](../downgrade_ee_to_ce/index.md) to make the process as smooth as
possible.

## Version-specific upgrading instructions

Each month, major, minor or patch releases of GitLab are published along with a
[release post](https://about.gitlab.com/releases/categories/releases/).
You should read the release posts for all versions you're passing over.
At the end of major and minor release posts, there are three sections to look for specifically:

- Deprecations
- Removals
- Important notes on upgrading

These include:

- Steps you need to perform as part of an upgrade.
  For example [8.12](https://about.gitlab.com/releases/2016/09/22/gitlab-8-12-released/#upgrade-barometer)
  required the Elasticsearch index to be recreated. Any older version of GitLab upgrading to 8.12 or higher would require this.
- Changes to the versions of software we support such as
  [ceasing support for IE11 in GitLab 13](https://about.gitlab.com/releases/2020/03/22/gitlab-12-9-released/#ending-support-for-internet-explorer-11).

Apart from the instructions in this section, you should also check the
installation-specific upgrade instructions, based on how you installed GitLab:

- [Linux packages (Omnibus GitLab)](https://docs.gitlab.com/omnibus/update/README.html#version-specific-changes)
- [Helm charts](https://docs.gitlab.com/charts/installation/upgrade.html)

NOTE:
Specific information that follow related to Ruby and Git versions do not apply to [Omnibus installations](https://docs.gitlab.com/omnibus/)
and [Helm Chart deployments](https://docs.gitlab.com/charts/). They come with appropriate Ruby and Git versions and are not using system binaries for Ruby and Git. There is no need to install Ruby or Git when utilizing these two approaches.

### 14.0.0

- In GitLab 13.3 some [pipeline processing methods were deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/218536)
  and this code was completely removed in GitLab 14.0. If you plan to upgrade from
  **GitLab 13.2 or older** directly to 14.0 ([unsupported](#upgrading-to-a-new-major-version)), you should not have any pipelines running
  when you upgrade or the pipelines might report the wrong status when the upgrade completes.
  You should instead follow a [supported upgrade path](#upgrade-paths).
- The support of PostgreSQL 11 [has been dropped](../install/requirements.md#database). Make sure to [update your database](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server) to version 12 before updating to GitLab 14.0.

### 13.11.0

Git 2.31.x and later is required. We recommend you use the
[Git version provided by Gitaly](../install/installation.md#git).

### 13.9.0

We've detected an issue [with a column rename](https://gitlab.com/gitlab-org/gitlab/-/issues/324160)
that will prevent upgrades to GitLab 13.9.0, 13.9.1, 13.9.2 and 13.9.3 when following the zero-downtime steps. It is necessary
to perform the following additional steps for the zero-downtime upgrade:

1. Before running the final `sudo gitlab-rake db:migrate` command on the deploy node,
   execute the following queries using the PostgreSQL console (or `sudo gitlab-psql`)
   to drop the problematic triggers:

   ```sql
   drop trigger trigger_e40a6f1858e6 on application_settings;
   drop trigger trigger_0d588df444c8 on application_settings;
   drop trigger trigger_1572cbc9a15f on application_settings;
   drop trigger trigger_22a39c5c25f3 on application_settings;
   ```

1. Run the final migrations:

   ```shell
   sudo gitlab-rake db:migrate
   ```

If you have already run the final `sudo gitlab-rake db:migrate` command on the deploy node and have
encountered the [column rename issue](https://gitlab.com/gitlab-org/gitlab/-/issues/324160), you will
see the following error:

```shell
-- remove_column(:application_settings, :asset_proxy_whitelist)
rake aborted!
StandardError: An error has occurred, all later migrations canceled:
PG::DependentObjectsStillExist: ERROR: cannot drop column asset_proxy_whitelist of table application_settings because other objects depend on it
DETAIL: trigger trigger_0d588df444c8 on table application_settings depends on column asset_proxy_whitelist of table application_settings
```

To work around this bug, follow the previous steps to complete the update.
More details are available [in this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/324160).

### 13.6.0

Ruby 2.7.2 is required. GitLab does not start with Ruby 2.6.6 or older versions.

The required Git version is Git v2.29 or higher.

### 13.4.0

GitLab 13.4.0 includes a background migration to [move all remaining repositories in legacy storage to hashed storage](../administration/raketasks/storage.md#migrate-to-hashed-storage). There are [known issues with this migration](https://gitlab.com/gitlab-org/gitlab/-/issues/259605) which are fixed in GitLab 13.5.4 and later. If possible, skip 13.4.0 and upgrade to 13.5.4 or higher instead. Note that the migration can take quite a while to run, depending on how many repositories must be moved. Be sure to check that all background migrations have completed before upgrading further.

### 13.3.0

The recommended Git version is Git v2.28. The minimum required version of Git
v2.24 remains the same.

### 13.2.0

GitLab installations that have multiple web nodes must be
[upgraded to 13.1](#1310) before upgrading to 13.2 (and later) due to a
breaking change in Rails that can result in authorization issues.

GitLab 13.2.0 [remediates](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/35492) an [email verification bypass](https://about.gitlab.com/releases/2020/05/27/security-release-13-0-1-released/).
After upgrading, if some of your users are unexpectedly encountering 404 or 422 errors when signing in,
or "blocked" messages when using the command line,
their accounts may have been un-confirmed.
In that case, please ask them to check their email for a re-confirmation link.
For more information, see our discussion of [Email confirmation issues](../user/upgrade_email_bypass.md).

GitLab 13.2.0 relies on the `btree_gist` extension for PostgreSQL. For installations with an externally managed PostgreSQL setup, please make sure to
[install the extension manually](https://www.postgresql.org/docs/11/sql-createextension.html) before upgrading GitLab if the database user for GitLab
is not a superuser. This is not necessary for installations using a GitLab managed PostgreSQL database.

### 13.1.0

In 13.1.0, you must upgrade to either:

- At least Git v2.24 (previously, the minimum required version was Git v2.22).
- The recommended Git v2.26.

Failure to do so results in internal errors in the Gitaly service in some RPCs due
to the use of the new `--end-of-options` Git flag.

Additionally, in GitLab 13.1.0, the version of [Rails was upgraded from 6.0.3 to
6.0.3.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/33454).
The Rails upgrade included a change to CSRF token generation which is
not backwards-compatible - GitLab servers with the new Rails version
generate CSRF tokens that are not recognizable by GitLab servers
with the older Rails version - which could cause non-GET requests to
fail for [multi-node GitLab installations](https://docs.gitlab.com/omnibus/update/#multi-node--ha-deployment).

So, if you are using multiple Rails servers and specifically upgrading from 13.0,
all servers must first be upgraded to 13.1.Z before upgrading to 13.2.0 or later:

1. Ensure all GitLab web nodes are running GitLab 13.1.Z.
1. Enable the `global_csrf_token` feature flag to enable new
   method of CSRF token generation:

   ```ruby
   Feature.enable(:global_csrf_token)
   ```

1. Only then, continue to upgrade to later versions of GitLab.

### 12.2.0

In 12.2.0, we enabled Rails' authenticated cookie encryption. Old sessions are
automatically upgraded.

However, session cookie downgrades are not supported. So after upgrading to 12.2.0,
any downgrades would result to all sessions being invalidated and users are logged out.

### 12.1.0

If you are planning to upgrade from `12.0.Z` to `12.10.Z`, it is necessary to
perform an intermediary upgrade to `12.1.Z` before upgrading to `12.10.Z` to
avoid issues like [#215141](https://gitlab.com/gitlab-org/gitlab/-/issues/215141).

### 12.0.0

In 12.0.0 we made various database related changes. These changes require that
users first upgrade to the latest 11.11 patch release. After upgraded to 11.11.Z,
users can upgrade to 12.0.Z. Failure to do so may result in database migrations
not being applied, which could lead to application errors.

It is also required that you upgrade to 12.0.Z before moving to a later version
of 12.Y.

Example 1: you are currently using GitLab 11.11.8, which is the latest patch
release for 11.11.Z. You can upgrade as usual to 12.0.Z.

Example 2: you are currently using a version of GitLab 10.Y. To upgrade, first
upgrade to the last 10.Y release (10.8.7) then the last 11.Y release (11.11.8).
After upgraded to 11.11.8 you can safely upgrade to 12.0.Z.

See our [documentation on upgrade paths](../policy/maintenance.md#upgrade-recommendations)
for more information.

### Upgrades from versions earlier than 8.12

- `8.11.Z` and earlier: you might have to upgrade to `8.12.0` specifically before you can upgrade to `8.17.7`. This was [reported in an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/207259).
- [CI changes prior to version 8.0](https://docs.gitlab.com/omnibus/update/README.html#updating-gitlab-ci-from-prior-540-to-version-714-via-omnibus-gitlab)
  when it was merged into GitLab.

## Miscellaneous

- [MySQL to PostgreSQL](mysql_to_postgresql.md) guides you through migrating
  your database from MySQL to PostgreSQL.
- [Restoring from backup after a failed upgrade](restore_after_failure.md)
- [Upgrading PostgreSQL Using Slony](upgrading_postgresql_using_slony.md), for
  upgrading a PostgreSQL database with minimal downtime.
- [Managing PostgreSQL extensions](../install/postgresql_extensions.md)
