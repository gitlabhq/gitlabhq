---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Introducing a new database migration version
---

At GitLab we've added many helpers for the database migrations to help developers manipulate
the schema and data of tables on a large scale like on GitLab.com. To avoid the repetitive task
of including the helpers into each database migration, we use a subclass of the Rails `ActiveRecord::Migration`
class that we use for all of our database migrations. This subclass is `Gitlab::Database::Migration`, and it already
includes all the helpers that developers can use. You can see many use cases of helpers built
in-house in [Avoiding downtime in migrations](avoiding_downtime_in_migrations.md).

Sometimes, we need to add or modify existing an helper's functionality without having a reverse effect on all the
previous database migrations. That's why we introduced versioning to `Gitlab::Database::Migration`. Now,
each database migration can inherit the latest version of this class at the time of the writing the database migration.
After we add a new feature, those old database migrations are no longer affected. We usually
refer to the version using `Gitlab::Database::Migration[2.1]`, where `2.1` is the current version.

Because we are chasing a moving target, adding a new migration and deprecating older versions
can be challenging. Database migrations are introduced every day, and this can break the pipeline.
In this document, we explain a two-step method to add a new database migration version.

1. [Introduce a new version, and keep the older version allowed](#introduce-a-new-version-and-keep-the-older-version-allowed)
1. [Prevent the usage of the older database migration version](#prevent-the-usage-of-the-older-database-migration-version)

## Introduce a new version, and keep the older version allowed

1. The new version can be added to the
   [`migration.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/database/migration.rb)
   class, along with any new helpers that should be included in the new version.
   Make sure that `current_version` refers to this new version. For example:

   ```ruby
         class V2_2 < V2_1 # rubocop:disable Naming/ClassAndModuleCamelCase
           include Gitlab::Database::MigrationHelpers::ANY_NEW_HELPER
         end

         def self.current_version
           2.2
         end
   ```

1. Update all the examples in the documentation to refer to the new database
   migration version `Gitlab::Database::Migration[2.2]`.
1. Make sure that [`migration_spec.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/db/migration_spec.rb)
   doesn't fail for the new database migrations by adding an open date rate for
   the **new database version**.

## Prevent the usage of the older database migration version

After some time passes, and ensuring all developers are using the
new database migration version in their merge requests, prevent the older
version from being used:

1. Close the date range in [`migration_spec.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/db/migration_spec.rb)
   for the older database version.
1. Modify the
   [`RuboCop::Cop::Migration::VersionedMigrationClass`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/rubocop/cop/migration/versioned_migration_class.rb)
   and [its owned tests](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/rubocop/cop/migration/versioned_migration_class_spec.rb).
1. Communicate this change on our Slack `#backend` and `#database` channels and
   [Engineering Week-in-Review document](https://handbook.gitlab.com/handbook/engineering/engineering-comms/#keeping-yourself-informed).
