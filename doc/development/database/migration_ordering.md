---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Migration ordering
---

Starting with GitLab 17.1, migrations are executed using
a custom ordering scheme that conforms to the GitLab release cadence. This change
simplifies the upgrade process, and eases both maintenance and support.

## Pre 17.1 logic

Migrations are executed in an order based upon the 14-digit timestamp
given in the file name of the migration itself. This behavior is the default for a Rails application.

GitLab also features logic to extend standard migration behavior in these important ways:

1. You can load migrations from additional folders. For example, migrations are
   loaded from both the `db/post_migrate` folder and the `db/migrate` folder, which
   you need when using [Post-Deployment migrations](post_deployment_migrations.md).
1. If you set the environment variable `SKIP_POST_DEPLOYMENT_MIGRATIONS`, migrations
   are not loaded from any `post_migrate` folder.
1. You must provide a GitLab minor version, or "milestone", on all new migrations.

## 17.1+ logic

Migrations are executed in the following order:

1. Migrations without `milestone` defined are executed first, ordered by their timestamp.
1. Migrations with `milestone` defined are executed in milestone order:
   1. Regular migrations are executed before post-deployment migrations.
   1. Migrations of the same type and milestone are executed in order specified by their timestamp.

Example:

1. Any migrations without `milestone` defined.
1. `17.1` regular migrations.
1. `17.1` post-deployment migrations.
1. `17.2` regular migrations.
1. `17.2` post-deployment migrations.
1. Repeat for each milestone in the upgrade.

### New behavior for post-deployment migrations

This change causes post-deployment migrations to always be sorted at the end
of a given milestone. Previously, post-deployment migrations were
interleaved with regular ones, provided `SKIP_POST_DEPLOYMENT_MIGRATIONS` was not set.
When `SKIP_POST_DEPLOYMENT_MIGRATIONS` is set, post-deployment migrations are not executed.
