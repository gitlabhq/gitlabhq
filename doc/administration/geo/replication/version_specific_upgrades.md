---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Version-specific upgrade instructions **(PREMIUM SELF)**

NOTE:
We're in the process of merging all the version-specific upgrade information
into a single page. For more information,
see [epic 9581](https://gitlab.com/groups/gitlab-org/-/epics/9581).
For the latest Geo version-specific upgrade instructions,
see the [general upgrade page](../../../update/index.md).

Review this page for upgrade instructions for your version. These steps
accompany the [general steps](upgrading_the_geo_sites.md#general-upgrade-steps)
for upgrading Geo sites.

## Upgrading to 15.1

[Geo proxying](../secondary_proxy/index.md) was [enabled by default for different URLs](https://gitlab.com/gitlab-org/gitlab/-/issues/346112) in 15.1. This may be a breaking change. If needed, you may [disable Geo proxying](../secondary_proxy/index.md#disable-geo-proxying).

If you are using SAML with different URLs, you must modify your SAML configuration and your Identity Provider configuration. For more information, see the [Geo with Single Sign-On (SSO) documentation](single_sign_on.md).

## Upgrading to 14.9

**Do not** upgrade to GitLab 14.9.0. Instead, use 14.9.1 or later.

We've discovered an issue with Geo's CI verification feature that may [cause job traces to be lost](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/6664). This issue was fixed in [the GitLab 14.9.1 patch release](https://about.gitlab.com/releases/2022/03/23/gitlab-14-9-1-released/).

If you have already upgraded to GitLab 14.9.0, you can disable the feature causing the issue by [disabling the `geo_job_artifact_replication` feature flag](../../feature_flags.md#how-to-enable-and-disable-features-behind-flags).

## Upgrading to 14.2 through 14.7

There is [an issue in GitLab 14.2 through 14.7](https://gitlab.com/gitlab-org/gitlab/-/issues/299819#note_822629467)
that affects Geo when the GitLab-managed object storage replication is used, causing blob object types to fail synchronization.

Since GitLab 14.2, verification failures result in synchronization failures and cause
a resynchronization of these objects.

As verification is not yet implemented for files stored in object storage (see
[issue 13845](https://gitlab.com/gitlab-org/gitlab/-/issues/13845) for more details), this
results in a loop that consistently fails for all objects stored in object storage.

For information on how to fix this, see
[Troubleshooting - Failed syncs with GitLab-managed object storage replication](troubleshooting.md#failed-syncs-with-gitlab-managed-object-storage-replication).

## Upgrading to 14.4

There is [an issue in GitLab 14.4.0 through 14.4.2](../../../update/index.md#1440) that can affect Geo and other features that rely on cronjobs. We recommend upgrading to GitLab 14.4.3 or later.

## Upgrading to 14.1, 14.2, 14.3

### Multi-arch images

We found an [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/336013) where the Container Registry replication wasn't fully working if you used multi-arch images. In case of a multi-arch image, only the primary architecture (for example `amd64`) would be replicated to the secondary site. This has been [fixed in GitLab 14.3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/67624) and was backported to 14.2 and 14.1, but manual steps are required to force a re-sync.

You can check if you are affected by running:

```shell
docker manifest inspect <SECONDARY_IMAGE_LOCATION> | jq '.mediaType'
```

Where `<SECONDARY_IMAGE_LOCATION>` is a container image on your secondary site.
If the output matches `application/vnd.docker.distribution.manifest.list.v2+json`
(there can be a `mediaType` entry at several levels, we only care about the top level entry),
then you don't need to do anything.

Otherwise, for each **secondary** site, on a Rails application node, open a [Rails console](../../operations/rails_console.md), and run the following:

 ```ruby
 list_type = 'application/vnd.docker.distribution.manifest.list.v2+json'

 Geo::ContainerRepositoryRegistry.synced.each do |gcr|
   cr = gcr.container_repository
   primary = Geo::ContainerRepositorySync.new(cr)
   cr.tags.each do |tag|
     primary_manifest = JSON.parse(primary.send(:client).repository_raw_manifest(cr.path, tag.name))
     next unless primary_manifest['mediaType'].eql?(list_type)

     cr.delete_tag_by_name(tag.name)
   end
   primary.execute
 end
 ```

If you are running a version prior to 14.1 and are using Geo and multi-arch containers in your Container Registry, we recommend [upgrading](upgrading_the_geo_sites.md) to at least GitLab 14.1.

### Geo Admin Area shows 'Unhealthy' after enabling Maintenance Mode

GitLab 13.9 through GitLab 14.3 are affected by a bug in which enabling [GitLab Maintenance Mode](../../maintenance_mode/index.md) causes Geo secondary site statuses to appear to stop upgrading and become unhealthy. For more information, see [Troubleshooting - Geo Admin Area shows 'Unhealthy' after enabling Maintenance Mode](troubleshooting.md#geo-admin-area-shows-unhealthy-after-enabling-maintenance-mode).

## Upgrading to GitLab 14.0/14.1

### Primary sites cannot be removed from the UI

We found an issue where [Primary sites cannot be removed from the UI](https://gitlab.com/gitlab-org/gitlab/-/issues/338231).

This bug only exists in the UI and does not block the removal of Primary sites using any other method.

If you are running an affected version and need to remove your Primary site, you can manually remove the Primary site by using the [Geo Sites API](../../../api/geo_nodes.md#delete-a-geo-node).

### Geo Admin Area shows 'Unhealthy' after enabling Maintenance Mode

GitLab 13.9 through GitLab 14.3 are affected by a bug in which enabling [GitLab Maintenance Mode](../../maintenance_mode/index.md) causes Geo secondary site statuses to appear to stop upgrading and become unhealthy. For more information, see [Troubleshooting - Geo Admin Area shows 'Unhealthy' after enabling Maintenance Mode](troubleshooting.md#geo-admin-area-shows-unhealthy-after-enabling-maintenance-mode).

## Upgrading to GitLab 13.12

### Secondary sites re-download all LFS files upon upgrade

We found an issue where [secondary sites re-download all LFS files](https://gitlab.com/gitlab-org/gitlab/-/issues/334550) upon upgrade. This bug:

- Only applies to Geo secondary sites that have replicated LFS objects.
- Is _not_ a data loss risk.
- Causes churn and wasted bandwidth re-downloading all LFS objects.
- May impact performance for GitLab installations with a large number of LFS files.

If you don't have many LFS objects or can stand a bit of churn, then it is safe to let the secondary sites re-download LFS objects.
If you do have many LFS objects, or many Geo secondary sites, or limited bandwidth, or a combination of them all, then we recommend you skip GitLab 13.12.0 through 13.12.6 and upgrade to GitLab 13.12.7 or newer.

#### If you have already upgraded to an affected version, and the re-sync is ongoing

You can manually migrate the legacy sync state to the new state column by running the following command in a [Rails console](../../operations/rails_console.md). It should take under a minute:

```ruby
Geo::LfsObjectRegistry.where(state: 0, success: true).update_all(state: 2)
```

### Geo Admin Area shows 'Unhealthy' after enabling Maintenance Mode

GitLab 13.9 through GitLab 14.3 are affected by a bug in which enabling [GitLab Maintenance Mode](../../maintenance_mode/index.md) causes Geo secondary site statuses to appear to stop upgrading and become unhealthy. For more information, see [Troubleshooting - Geo Admin Area shows 'Unhealthy' after enabling Maintenance Mode](troubleshooting.md#geo-admin-area-shows-unhealthy-after-enabling-maintenance-mode).

## Upgrading to GitLab 13.11

We found an [issue with Git clone/pull through HTTP(s)](https://gitlab.com/gitlab-org/gitlab/-/issues/330787) on Geo secondaries and on any GitLab instance if maintenance mode is enabled. This was caused by a regression in GitLab Workhorse. This is fixed in the [GitLab 13.11.4 patch release](https://about.gitlab.com/releases/2021/05/14/gitlab-13-11-4-released/). To avoid this issue, upgrade to GitLab 13.11.4 or later.

### Geo Admin Area shows 'Unhealthy' after enabling Maintenance Mode

GitLab 13.9 through GitLab 14.3 are affected by a bug in which enabling [GitLab Maintenance Mode](../../maintenance_mode/index.md) causes Geo secondary site statuses to appear to stop upgrading and become unhealthy. For more information, see [Troubleshooting - Geo Admin Area shows 'Unhealthy' after enabling Maintenance Mode](troubleshooting.md#geo-admin-area-shows-unhealthy-after-enabling-maintenance-mode).

## Upgrading to GitLab 13.10

### Geo Admin Area shows 'Unhealthy' after enabling Maintenance Mode

GitLab 13.9 through GitLab 14.3 are affected by a bug in which enabling [GitLab Maintenance Mode](../../maintenance_mode/index.md) causes Geo secondary site statuses to appear to stop upgrading and become unhealthy. For more information, see [Troubleshooting - Geo Admin Area shows 'Unhealthy' after enabling Maintenance Mode](troubleshooting.md#geo-admin-area-shows-unhealthy-after-enabling-maintenance-mode).

## Upgrading to GitLab 13.9

### Error during zero-downtime upgrade: `cannot drop column asset_proxy_whitelist`

We've detected an issue [with a column rename](https://gitlab.com/gitlab-org/gitlab/-/issues/324160)
that prevents upgrades to GitLab 13.9.0, 13.9.1, 13.9.2 and 13.9.3 when following the zero-downtime steps. It is necessary
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

1. Hot reload `puma` and `sidekiq` services:

   ```shell
   sudo gitlab-ctl hup puma
   sudo gitlab-ctl restart sidekiq
   ```

If you have already run the final `sudo gitlab-rake db:migrate` command on the deploy node and have
encountered the [column rename issue](https://gitlab.com/gitlab-org/gitlab/-/issues/324160), you might
see the following error:

```shell
-- remove_column(:application_settings, :asset_proxy_whitelist)
rake aborted!
StandardError: An error has occurred, all later migrations canceled:
PG::DependentObjectsStillExist: ERROR: cannot drop column asset_proxy_whitelist of table application_settings because other objects depend on it
DETAIL: trigger trigger_0d588df444c8 on table application_settings depends on column asset_proxy_whitelist of table application_settings
```

To work around this bug, follow the previous steps to complete the upgrade.
More details are available [in this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/324160).

### Geo Admin Area shows 'Unhealthy' after enabling Maintenance Mode

GitLab 13.9 through GitLab 14.3 are affected by a bug in which enabling [GitLab Maintenance Mode](../../maintenance_mode/index.md) causes Geo secondary site statuses to appear to stop upgrading and become unhealthy. For more information, see [Troubleshooting - Geo Admin Area shows 'Unhealthy' after enabling Maintenance Mode](troubleshooting.md#geo-admin-area-shows-unhealthy-after-enabling-maintenance-mode).

## Upgrading to GitLab 13.7

- We've detected an issue with the `FetchRemove` call used by Geo secondaries.
  This causes performance issues as we execute reference transaction hooks for
  each upgraded reference. Delay any upgrade attempts until this is in the
  [13.7.5 patch release.](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/3002).
  More details are available [in this issue](https://gitlab.com/gitlab-org/git/-/issues/79).
- A new secret is generated in `/etc/gitlab/gitlab-secrets.json`.
  In an HA GitLab or GitLab Geo environment, secrets need to be the same on all nodes.
  Ensure this new secret is also accounted for if you are manually syncing the file across
  nodes, or manually specifying secrets in `/etc/gitlab/gitlab.rb`.

## Upgrading to GitLab 13.5

GitLab 13.5 has a [regression that prevents viewing a list of container repositories and registries](https://gitlab.com/gitlab-org/gitlab/-/issues/285475)
on Geo secondaries. This issue is fixed in GitLab 13.6.1 and later.

## Upgrading to GitLab 13.3

In GitLab 13.3, Geo removed the PostgreSQL [Foreign Data Wrapper](https://www.postgresql.org/docs/11/postgres-fdw.html)
dependency for the tracking database.

The FDW server, user, and the extension is removed during the upgrade
process on each secondary site. The GitLab settings related to the FDW in the
`/etc/gitlab/gitlab.rb`  have been deprecated and can be safely removed.

There are some scenarios like using an external PostgreSQL instance for the
tracking database where the FDW settings must be removed manually. Enter the
PostgreSQL console of that instance and remove them:

```shell
DROP SERVER gitlab_secondary CASCADE;
DROP EXTENSION IF EXISTS postgres_fdw;
```

WARNING:
In GitLab 13.3, promoting a secondary site to a primary while the secondary is
paused fails. Do not pause replication before promoting a secondary. If the
site is paused, be sure to resume before promoting. To avoid this issue,
upgrade to GitLab 13.4 or later.

WARNING:
Promoting the database during a failover can fail on XFS and filesystems ordering files lexically,
when using `--force` or `--skip-preflight-checks`, due to [an issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6076) fixed in 13.5.
The [troubleshooting steps](troubleshooting.md#errors-when-using---skip-preflight-checks-or---force)
contain a workaround if you run into errors during the failover.

## Upgrading to GitLab 13.2

In GitLab 13.2, promoting a secondary site to a primary while the secondary is
paused fails. Do not pause replication before promoting a secondary. If the
site is paused, be sure to resume before promoting. To avoid this issue,
upgrade to GitLab 13.4 or later.

## Upgrading to GitLab 13.0

Upgrading to GitLab 13.0 requires GitLab 12.10 to already be using PostgreSQL
version 11. For the recommended procedure, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

## Upgrading to GitLab 12.10

GitLab 12.10 doesn't attempt to upgrade the embedded PostgreSQL server when
using Geo, because the PostgreSQL upgrade requires downtime for secondaries
while reinitializing streaming replication. It must be upgraded manually. For
the recommended procedure, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

## Upgrading to GitLab 12.9

WARNING:
GitLab 12.9.0 through GitLab 12.9.3 are affected by
[a bug that stops repository verification](https://gitlab.com/gitlab-org/gitlab/-/issues/213523).
The issue is fixed in GitLab 12.9.4. Upgrade to GitLab 12.9.4 or later.

By default, GitLab 12.9 attempts to upgrade the embedded PostgreSQL server
version from 9.6 to 10.12, which requires downtime on secondaries while
reinitializing streaming replication. For the recommended procedure, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

You can temporarily disable this behavior by running the following before
upgrading:

```shell
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

## Upgrading to GitLab 12.8

By default, GitLab 12.8 attempts to upgrade the embedded PostgreSQL server
version from 9.6 to 10.12, which requires downtime on secondaries while
reinitializing streaming replication. For the recommended procedure, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

You can temporarily disable this behavior by running the following before
upgrading:

```shell
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

## Upgrading to GitLab 12.7

WARNING:
Only upgrade to GitLab 12.7.5 or later. Do not upgrade to versions 12.7.0
through 12.7.4 because there is [an initialization order bug](https://gitlab.com/gitlab-org/gitlab/-/issues/199672) that causes Geo secondaries to set the incorrect database connection pool size.
[The fix](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/24021) was
shipped in 12.7.5.

By default, GitLab 12.7 attempts to upgrade the embedded PostgreSQL server
version from 9.6 to 10.9, which requires downtime on secondaries while
reinitializing streaming replication. For the recommended procedure, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

You can temporarily disable this behavior by running the following before
upgrading:

```shell
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

## Upgrading to GitLab 12.6

By default, GitLab 12.6 attempts to upgrade the embedded PostgreSQL server
version from 9.6 to 10.9, which requires downtime on secondaries while
reinitializing streaming replication. For the recommended procedure, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

You can temporarily disable this behavior by running the following before
upgrading:

```shell
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

## Upgrading to GitLab 12.5

By default, GitLab 12.5 attempts to upgrade the embedded PostgreSQL server
version from 9.6 to 10.9, which requires downtime on secondaries while
reinitializing streaming replication. For the recommended procedure, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

You can temporarily disable this behavior by running the following before
upgrading:

```shell
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

## Upgrading to GitLab 12.4

By default, GitLab 12.4 attempts to upgrade the embedded PostgreSQL server
version from 9.6 to 10.9, which requires downtime on secondaries while
reinitializing streaming replication. For the recommended procedure, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

You can temporarily disable this behavior by running the following before
upgrading:

```shell
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

## Upgrading to GitLab 12.3

WARNING:
If the existing PostgreSQL server version is 9.6.x, we recommend upgrading to
GitLab 12.4 or later. By default, GitLab 12.3 attempts to upgrade the embedded
PostgreSQL server version from 9.6 to 10.9. In certain circumstances, it can
fail. For more information, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

Additionally, if the PostgreSQL upgrade doesn't fail, a successful upgrade
requires downtime for secondaries while reinitializing streaming replication.
For the recommended procedure, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

## Upgrading to GitLab 12.2

WARNING:
If the existing PostgreSQL server version is 9.6.x, we recommend upgrading to
GitLab 12.4 or later. By default, GitLab 12.2 attempts to upgrade the embedded
PostgreSQL server version from 9.6 to 10.9. In certain circumstances, it can
fail. For more information, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

Additionally, if the PostgreSQL upgrade doesn't fail, a successful upgrade
requires downtime for secondaries while reinitializing streaming replication.
For the recommended procedure, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

GitLab 12.2 includes the following minor PostgreSQL upgrades:

- To version `9.6.14`, if you run PostgreSQL 9.6.
- To version `10.9`, if you run PostgreSQL 10.

This upgrade occurs even if major PostgreSQL upgrades are disabled.

Before [refreshing Foreign Data Wrapper during a Geo upgrade](../../../update/zero_downtime.md#step-4-run-post-deployment-migrations-and-checks),
restart the Geo tracking database:

```shell
sudo gitlab-ctl restart geo-postgresql
```

The restart avoids a version mismatch when PostgreSQL tries to load the FDW
extension.

## Upgrading to GitLab 12.1

WARNING:
If the existing PostgreSQL server version is 9.6.x, we recommend upgrading to
GitLab 12.4 or later. By default, GitLab 12.1 attempts to upgrade the embedded
PostgreSQL server version from 9.6 to 10.9. In certain circumstances, it can
fail. For more information, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

Additionally, if the PostgreSQL upgrade doesn't fail, a successful upgrade
requires downtime for secondaries while reinitializing streaming replication.
For the recommended procedure, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

## Upgrading to GitLab 12.0

WARNING:
This version is affected by a
[bug that results in new LFS objects not being replicated to Geo secondary sites](https://gitlab.com/gitlab-org/gitlab/-/issues/32696).
The issue is fixed in GitLab 12.1. Be sure to upgrade to GitLab 12.1 or later.
