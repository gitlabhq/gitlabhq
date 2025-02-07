---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: PostgreSQL versions shipped with the Linux package
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

NOTE:
This table lists only GitLab versions where a significant change happened in the
package regarding PostgreSQL versions, not all.

Usually, PostgreSQL versions change with major or minor GitLab releases. However, patch versions
of the Linux package sometimes update the patch level of PostgreSQL. We've established a
[yearly cadence for PostgreSQL upgrades](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/data-access/database-framework/postgresql-upgrade-cadence/)
and trigger automatic database upgrades in the release before the new version is required.

For example:

- Linux package 12.7.6 shipped with PostgreSQL 9.6.14 and 10.9.
- Linux package 12.7.7 shipped with PostgreSQL 9.6.17 and 10.12.

Find out [which versions of PostgreSQL (and other components) ship](https://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html)
with each Linux package release.

The lowest supported PostgreSQL versions are listed in the
[installation requirements](../../install/requirements.md#postgresql).

Read more about update policies and warnings in the PostgreSQL
[upgrade docs](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server).

| First GitLab version | PostgreSQL versions | Default version for fresh installs | Default version for upgrades | Notes |
| -------------- | ------------------- | ---------------------------------- | ---------------------------- | ----- |
| 17.5.0 | 14.11, 16.4 | 14.11 | 16.4 | Single node upgrades from PostgreSQL 14 to PostgreSQL 16 are now supported. Starting with GitLab 17.5.0, PostgreSQL 16 is fully supported for both new installations and upgrades in Geo deployments (the restriction from 17.4.0 no longer applies). |
| 17.4.0 | 14.11, 16.4 | 14.11 | 14.11 | PostgreSQL 16 is available for new installations if not using [Geo](../geo/_index.md#requirements-for-running-geo) or [Patroni](../postgresql/_index.md#postgresql-replication-and-failover-for-linux-package-installations). |
| 17.0.0 | 14.11 | 14.11 | 14.11 | Package upgrades are aborted if PostgreSQL is not upgraded to 14 already. |
| 16.10.1, 16.9.3, 16.8.5 | 13.14, 14.11 | 14.11 | 14.11 | |
| 16.6.7, 16.7.5, 16.8.2 | 13.13, 14.10 | 14.10 | 14.10 | |
| 16.7.0 | 13.12, 14.9 | 14.9 | 14.9 | |
| 16.4.3, 16.5.3, 16.6.1 | 13.12, 14.9 | 13.12 | 13.12 | For upgrades, you can manually upgrade to 14.9 following the [upgrade documentation](../../update/versions/gitlab_16_changes.md#linux-package-installations-2). |
| 16.2.0 | 13.11, 14.8 | 13.11 | 13.11 | For upgrades, you can manually upgrade to 14.8 following the [upgrade documentation](../../update/versions/gitlab_16_changes.md#linux-package-installations-2). |
| 16.0.2 | 13.11 | 13.11 | 13.11 | |
| 16.0.0 | 13.8  | 13.8  | 13.8  | |
| 15.11.7 | 13.11 | 13.11 | 12.12 | |
| 15.10.8 | 13.11 | 13.11 | 12.12 | |
| 15.6 | 12.12, 13.8 | 13.8 | 12.12 | For upgrades, you can manually upgrade to 13.8 following the [upgrade documentation](../../update/versions/gitlab_15_changes.md#linux-package-installations-2). |
| 15.0 | 12.10, 13.6 | 13.6 | 12.10 | For upgrades, you can manually upgrade to 13.6 following the [upgrade documentation](../../update/versions/gitlab_15_changes.md#linux-package-installations-2). |
| 14.1 | 12.7, 13.3 | 12.7 | 12.7 | PostgreSQL 13 available for fresh installations if not using [Geo](../geo/_index.md#requirements-for-running-geo) or [Patroni](../postgresql/_index.md#postgresql-replication-and-failover-for-linux-package-installations). |
| 14.0 | 12.7       | 12.7 | 12.7 | HA installations with repmgr are no longer supported and are prevented from upgrading to Linux package 14.0 |
| 13.8 | 11.9, 12.4 | 12.4 | 12.4 | Package upgrades automatically performed PostgreSQL upgrade for nodes that are not part of a Geo or HA cluster. |
| 13.7 | 11.9, 12.4 | 12.4 | 11.9 | For upgrades users can manually upgrade to 12.4 following the [upgrade documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server). |
| 13.4 | 11.9, 12.4 | 11.9 | 11.9 | Package upgrades aborted if users not running PostgreSQL 11 already |
| 13.3 | 11.7, 12.3 | 11.7 | 11.7 | Package upgrades aborted if users not running PostgreSQL 11 already |
| 13.0 | 11.7 | 11.7 | 11.7 | Package upgrades aborted if users not running PostgreSQL 11 already |
| 12.10 | 9.6.17, 10.12, and 11.7 | 11.7 | 11.7 | Package upgrades automatically performed PostgreSQL upgrade for nodes that are not part of a Geo or repmgr cluster. |
| 12.8 | 9.6.17, 10.12, and 11.7 | 10.12 | 10.12 | Users can manually upgrade to 11.7 following the upgrade documentation. |
| 12.0 | 9.6.11 and 10.7 | 10.7 | 10.7 | Package upgrades automatically performed PostgreSQL upgrade. |
| 11.11 | 9.6.11 and 10.7 | 9.6.11 | 9.6.11 | Users can manually upgrade to 10.7 following the upgrade documentation. |
| 10.0 | 9.6.3 | 9.6.3 | 9.6.3 | Package upgrades aborted if users still on 9.2. |
| 9.0 | 9.2.18 and 9.6.1 | 9.6.1 | 9.6.1 | Package upgrades automatically performed PostgreSQL upgrade. |
| 8.14 | 9.2.18 and 9.6.1 | 9.2.18 | 9.2.18 | Users can manually upgrade to 9.6 following the upgrade documentation. |
