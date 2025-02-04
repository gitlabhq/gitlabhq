---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Delete existing migrations
---

When removing existing migrations from the GitLab project, you have to take into account
the possibility of the migration already been included in past releases or in the current release, and thus already executed on GitLab.com and/or in self-managed instances.

Because of it, it's not possible to delete existing migrations, as that could lead to:

- Schema inconsistency, as changes introduced into the database were not rolled back properly.
- Leaving a record on the `schema_versions` table, that points out to migration that no longer exists on the codebase.

Instead of deleting we can opt for disabling the migration.

## Pre-requisites to disable a migration

Migrations can be disabled if:

- They caused a timeout or general issue on GitLab.com.
- They are obsoleted, for example, changes are not necessary due to a feature change.
- Migration is a data migration only, that is, the migration does not change the database schema.

## How to disable a data migration?

In order to disable a migration, the following steps apply to all types of migrations:

1. Turn the migration into a no-op by removing the code inside `#up`, `#down`
   or `#perform` methods, and adding `# no-op` comment instead.
1. Add a comment explaining why the code is gone.

Disabling migrations requires explicit approval of Database Maintainer.

## Examples

- [Disable scheduling of productivity analytics](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17253)
