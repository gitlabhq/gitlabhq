---
stage: Enablement
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Version-specific update instructions **(PREMIUM SELF)**

Review this page for update instructions for your version. These steps
accompany the [general steps](updating_the_geo_nodes.md#general-update-steps)
for updating Geo nodes.

## Updating to GitLab 13.11

We found an [issue with Git clone/pull through HTTP(s)](https://gitlab.com/gitlab-org/gitlab/-/issues/330787) on Geo secondaries and on any GitLab instance if maintenance mode is enabled. This was caused by a regression in GitLab Workhorse. This is fixed in the [GitLab 13.11.4 patch release](https://about.gitlab.com/releases/2021/05/14/gitlab-13-11-4-released/). To avoid this issue, upgrade to GitLab 13.11.4 or later.

## Updating to GitLab 13.9

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

## Updating to GitLab 13.7

We've detected an issue with the `FetchRemove` call used by Geo secondaries.
This causes performance issues as we execute reference transaction hooks for
each updated reference. Delay any upgrade attempts until this is in the
[13.7.5 patch release.](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/3002).
More details are available [in this issue](https://gitlab.com/gitlab-org/git/-/issues/79).

## Updating to GitLab 13.5

GitLab 13.5 has a [regression that prevents viewing a list of container repositories and registries](https://gitlab.com/gitlab-org/gitlab/-/issues/285475)
on Geo secondaries. This issue is fixed in GitLab 13.6.1 and later.

## Updating to GitLab 13.3

In GitLab 13.3, Geo removed the PostgreSQL [Foreign Data Wrapper](https://www.postgresql.org/docs/11/postgres-fdw.html)
dependency for the tracking database.

The FDW server, user, and the extension will be removed during the upgrade
process on each secondary node. The GitLab settings related to the FDW in the
`/etc/gitlab/gitlab.rb`  have been deprecated and can be safely removed.

There are some scenarios like using an external PostgreSQL instance for the
tracking database where the FDW settings must be removed manually. Enter the
PostgreSQL console of that instance and remove them:

```shell
DROP SERVER gitlab_secondary CASCADE;
DROP EXTENSION IF EXISTS postgres_fdw;
```

WARNING:
In GitLab 13.3, promoting a secondary node to a primary while the secondary is
paused fails. Do not pause replication before promoting a secondary. If the
node is paused, be sure to resume before promoting. To avoid this issue,
upgrade to GitLab 13.4 or later.

WARNING:
Promoting the database during a failover can fail on XFS and filesystems ordering files lexically,
when using `--force` or `--skip-preflight-checks`, due to [an issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6076) fixed in 13.5.
The [troubleshooting steps](troubleshooting.md#errors-when-using---skip-preflight-checks-or---force)
contain a workaround if you run into errors during the failover.

## Updating to GitLab 13.2

In GitLab 13.2, promoting a secondary node to a primary while the secondary is
paused fails. Do not pause replication before promoting a secondary. If the
node is paused, be sure to resume before promoting. To avoid this issue,
upgrade to GitLab 13.4 or later.

## Updating to GitLab 13.0

Upgrading to GitLab 13.0 requires GitLab 12.10 to already be using PostgreSQL
version 11. For the recommended procedure, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

## Updating to GitLab 12.10

GitLab 12.10 doesn't attempt to update the embedded PostgreSQL server when
using Geo, because the PostgreSQL upgrade requires downtime for secondaries
while reinitializing streaming replication. It must be upgraded manually. For
the recommended procedure, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

## Updating to GitLab 12.9

WARNING:
GitLab 12.9.0 through GitLab 12.9.3 are affected by [a bug that stops
repository verification](https://gitlab.com/gitlab-org/gitlab/-/issues/213523).
The issue is fixed in GitLab 12.9.4. Upgrade to GitLab 12.9.4 or later.

By default, GitLab 12.9 attempts to update the embedded PostgreSQL server
version from 9.6 to 10.12, which requires downtime on secondaries while
reinitializing streaming replication. For the recommended procedure, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

You can temporarily disable this behavior by running the following before
updating:

```shell
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

## Updating to GitLab 12.8

By default, GitLab 12.8 attempts to update the embedded PostgreSQL server
version from 9.6 to 10.12, which requires downtime on secondaries while
reinitializing streaming replication. For the recommended procedure, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

You can temporarily disable this behavior by running the following before
updating:

```shell
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

## Updating to GitLab 12.7

WARNING:
Only upgrade to GitLab 12.7.5 or later. Do not upgrade to versions 12.7.0
through 12.7.4 because there is [an initialization order bug](https://gitlab.com/gitlab-org/gitlab/-/issues/199672) that causes Geo secondaries to set the incorrect database connection pool size.
[The fix](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/24021) was
shipped in 12.7.5.

By default, GitLab 12.7 attempts to update the embedded PostgreSQL server
version from 9.6 to 10.9, which requires downtime on secondaries while
reinitializing streaming replication. For the recommended procedure, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

You can temporarily disable this behavior by running the following before
updating:

```shell
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

## Updating to GitLab 12.6

By default, GitLab 12.6 attempts to update the embedded PostgreSQL server
version from 9.6 to 10.9, which requires downtime on secondaries while
reinitializing streaming replication. For the recommended procedure, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

You can temporarily disable this behavior by running the following before
updating:

```shell
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

## Updating to GitLab 12.5

By default, GitLab 12.5 attempts to update the embedded PostgreSQL server
version from 9.6 to 10.9, which requires downtime on secondaries while
reinitializing streaming replication. For the recommended procedure, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

You can temporarily disable this behavior by running the following before
updating:

```shell
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

## Updating to GitLab 12.4

By default, GitLab 12.4 attempts to update the embedded PostgreSQL server
version from 9.6 to 10.9, which requires downtime on secondaries while
reinitializing streaming replication. For the recommended procedure, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

You can temporarily disable this behavior by running the following before
updating:

```shell
sudo touch /etc/gitlab/disable-postgresql-upgrade
```

## Updating to GitLab 12.3

WARNING:
If the existing PostgreSQL server version is 9.6.x, we recommend upgrading to
GitLab 12.4 or later. By default, GitLab 12.3 attempts to update the embedded
PostgreSQL server version from 9.6 to 10.9. In certain circumstances, it can
fail. For more information, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

Additionally, if the PostgreSQL upgrade doesn't fail, a successful upgrade
requires downtime for secondaries while reinitializing streaming replication.
For the recommended procedure, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

## Updating to GitLab 12.2

WARNING:
If the existing PostgreSQL server version is 9.6.x, we recommend upgrading to
GitLab 12.4 or later. By default, GitLab 12.2 attempts to update the embedded
PostgreSQL server version from 9.6 to 10.9. In certain circumstances, it can
fail. For more information, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

Additionally, if the PostgreSQL upgrade doesn't fail, a successful upgrade
requires downtime for secondaries while reinitializing streaming replication.
For the recommended procedure, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

GitLab 12.2 includes the following minor PostgreSQL updates:

- To version `9.6.14`, if you run PostgreSQL 9.6.
- To version `10.9`, if you run PostgreSQL 10.

This update occurs even if major PostgreSQL updates are disabled.

Before [refreshing Foreign Data Wrapper during a Geo upgrade](https://docs.gitlab.com/omnibus/update/README.html#run-post-deployment-migrations-and-checks),
restart the Geo tracking database:

```shell
sudo gitlab-ctl restart geo-postgresql
```

The restart avoids a version mismatch when PostgreSQL tries to load the FDW
extension.

## Updating to GitLab 12.1

WARNING:
If the existing PostgreSQL server version is 9.6.x, we recommend upgrading to
GitLab 12.4 or later. By default, GitLab 12.1 attempts to update the embedded
PostgreSQL server version from 9.6 to 10.9. In certain circumstances, it can
fail. For more information, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

Additionally, if the PostgreSQL upgrade doesn't fail, a successful upgrade
requires downtime for secondaries while reinitializing streaming replication.
For the recommended procedure, see the
[Omnibus GitLab documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).

## Updating to GitLab 12.0

WARNING:
This version is affected by a [bug that results in new LFS objects not being
replicated to Geo secondary nodes](https://gitlab.com/gitlab-org/gitlab/-/issues/32696).
The issue is fixed in GitLab 12.1. Be sure to upgrade to GitLab 12.1 or later.

## Updating to GitLab 11.11

WARNING:
This version is affected by a [bug that results in new LFS objects not being
replicated to Geo secondary nodes](https://gitlab.com/gitlab-org/gitlab/-/issues/32696).
The issue is fixed in GitLab 12.1. Be sure to upgrade to GitLab 12.1 or later.
