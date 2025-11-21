---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Database upgrade DDL lock
---

During major PostgreSQL upgrades on GitLab.com, DDL (Data Definition Language) changes are temporarily blocked to prevent conflicts with the upgrade process.
GitLab.com uses logical replication for PostgreSQL upgrades, replicating data between different major versions to achieve zero-downtime upgrades.
During the upgrade window, new DDL changes can break the replication.

Instead of using a hard Production Change Lock (PCL) that blocks all deployments, a targeted lock prevents
only database schema changes from being merged.

This approach allows GitLab to continue releasing other changes while protecting the
database upgrade process from breaking schema modifications.

## How it works

The DDL lock is configured in `config/database_upgrade_ddl_lock.yml` and enforced by a
Danger check that runs in CI/CD pipelines. The configuration includes:

- Merge requests that modify `db/structure.sql` are automatically blocked by Danger.
- A warning appears on affected merge requests several days before the lock begins.
- The lock only affects DDL changes. Other changes can still be merged and deployed.
- The Danger check fails during the lock period, preventing the merge request from being merged.

## When a DDL lock is active

When a lock is configured and active:

- The Danger check fails, preventing the merge request from being merged.
- A clear error message explains the lock period and provides next steps.

## What to do if your merge request is affected

If your merge request contains DDL changes and is affected by an upgrade lock:

### During the warning period

You can still merge your changes. The Danger check displays a warning message indicating:

- How many days until the lock begins
- When the lock starts and ends
- Details about the upgrade
- A link to the upgrade tracking issue

Consider merging your changes before the lock begins, or plan to wait until after the lock expires.

### During the lock period

You must wait until the lock expires. The Danger check fails with an error message.

After the lock ends:

- Retry the CI/CD pipeline.
- The Danger check passes automatically.
- Proceed with the normal merge request process.
