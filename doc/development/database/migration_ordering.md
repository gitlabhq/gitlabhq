---
stage: Data Stores
group: Database
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Migration ordering

Starting with GitLab 17.1, the migration Rake tasks apply migrations using
a custom ordering scheme that conforms to the GitLab release cadence. This change
simplifies the upgrade process, and eases both maintenance and support.

## Pre 17.1 logic

Relevant Rake tasks apply migrations in an order based upon the 14-digit timestamp
given in the file name of the migration itself. This behavior is the default for a Rails application.

GitLab also features logic to extend standard migration behavior in these important ways:

1. You can load migrations from additional folders. For example, migrations are
   loaded from both the `db/post_migrate` folder and the `db/migrate` folder, which
   you need when using [Post-Deployment migrations](post_deployment_migrations.md).
1. If you set the environment variable `SKIP_POST_DEPLOYMENT_MIGRATIONS`, migrations
   are not loaded from any `post_migrate` folder.
1. You must provide a GitLab minor version, or "milestone", on all new migrations.

## 17.1+ logic

The new logic orders migrations according to four criteria, in this order:

1. If a GitLab milestone is present in the migration definition.
   Migrations without a milestone defined are sorted lower.
1. The milestone defined on the migration. "Milestone" values are converted to
   [GitLab semantic versions](https://gitlab.com/gitlab-org/gitlab/-/blob/master/gems/gitlab-utils/lib/gitlab/version_info.rb)
   and these semantic versions are used as this sort criteria, in ascending order.
1. The 'migration type', which you can think of as an enumerable with two values:
   `regular` and `post`, with `regular` sorting lower.
   [Relevant source](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/database/migrations/version.rb).
1. The timestamp value itself.

### New behavior for post-deployment migrations

This change causes post-deployment migrations to always be sorted at the end
of a given milestone. Previously, post-deployment migrations were
interleaved with regular ones, provided `SKIP_POST_DEPLOYMENT_MIGRATIONS` was not set.
