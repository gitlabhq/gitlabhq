---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# PostgreSQL versions shipped with Omnibus GitLab **(FREE SELF)**

NOTE:
This table lists only GitLab versions where a significant change happened in the
package regarding PostgreSQL versions, not all.

Usually, PostgreSQL versions change with major or minor GitLab releases. However, patch versions
of Omnibus GitLab sometimes update the patch level of PostgreSQL.

For example:

- Omnibus 12.7.6 shipped with PostgreSQL 9.6.14 and 10.9.
- Omnibus 12.7.7 shipped with PostgreSQL 9.6.17 and 10.12.

[Find out which versions of PostgreSQL (and other components) ship with
each Omnibus GitLab release](https://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html).

Read more about update policies and warnings in the PostgreSQL
[upgrade docs](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server).

| GitLab version | PostgreSQL versions | Default version for fresh installs | Default version for upgrades | Notes |
| -------------- | --------------------- | ---------------------------------- | ---------------------------- | ----- |
| 15.0 | 12.10, 13.6 | 13.6 | 12.10 | For upgrades, users can manually upgrade to 13.6 following the [upgrade docs](https://docs.gitlab.com/omnibus/settings/database.html#gitlab-150-and-later). |
| 14.1 | 12.7, 13.3 | 12.7 | 12.7 | PostgreSQL 13 available for fresh installations if not using [Geo](../geo/index.md#requirements-for-running-geo) or [Patroni](../postgresql/index.md#postgresql-replication-and-failover-with-omnibus-gitlab).
| 14.0 | 12.7       | 12.7 | 12.7 | HA installations with repmgr are no longer supported and will be prevented from upgrading to Omnibus GitLab 14.0 |
| 13.8 | 11.9, 12.4 | 12.4 | 12.4 | Package upgrades automatically performed PostgreSQL upgrade for nodes that are not part of a Geo or HA cluster.). |
| 13.7 | 11.9, 12.4 | 12.4 | 11.9 | For upgrades users can manually upgrade to 12.4 following the [upgrade docs](https://docs.gitlab.com/omnibus/settings/database.html#gitlab-133-and-later). |
| 13.4 | 11.9, 12.4 | 11.9 | 11.9 | Package upgrades aborted if users not running PostgreSQL 11 already |
| 13.3 | 11.7, 12.3 | 11.7 | 11.7 | Package upgrades aborted if users not running PostgreSQL 11 already |
| 13.0 | 11.7 | 11.7 | 11.7 | Package upgrades aborted if users not running PostgreSQL 11 already |
| 12.10 | 9.6.17, 10.12, and 11.7 | 11.7 | 11.7 | Package upgrades automatically performed PostgreSQL upgrade for nodes that are not part of a Geo or repmgr cluster. |
| 12.8 | 9.6.17, 10.12, and 11.7 | 10.12 | 10.12 | Users can manually upgrade to 11.7 following the upgrade docs. |
| 12.0 | 9.6.11 and 10.7 | 10.7 | 10.7 | Package upgrades automatically performed PostgreSQL upgrade. |
| 11.11 | 9.6.11 and 10.7 | 9.6.11 | 9.6.11 | Users can manually upgrade to 10.7 following the upgrade docs. |
| 10.0 | 9.6.3 | 9.6.3 | 9.6.3 | Package upgrades aborted if users still on 9.2. |
| 9.0 | 9.2.18 and 9.6.1 | 9.6.1 | 9.6.1 | Package upgrades automatically performed PostgreSQL upgrade. |
| 8.14 | 9.2.18 and 9.6.1 | 9.2.18 | 9.2.18 | Users can manually upgrade to 9.6 following the upgrade docs. |
