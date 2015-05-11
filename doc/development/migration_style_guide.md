# Migration Style Guide

When writing migrations for GitLab, you have to take into account that
these will be ran by hundreds of thousands of organizations of all sizes, some with
many years of data in their database.

In addition, having to take a server offline for a an upgrade small or big is
a big burden for most organizations. For this reason it is important that your
migrations are written carefully, can be applied online and adhere to the style guide below.

When writing your migrations, also consider that databases might have stale data
or inconsistencies and guard for that. Try to make as little assumptions as possible
about the state of the database.

Please don't depend on GitLab specific code since it can change in future versions.
If needed copy-paste GitLab code into the migration to make make it forward compatible.

## Comments in the migration

Each migration you write needs to have the two following pieces of information
as comments.

### Online, Offline, errors?

First, you need to provide information on whether the migration can be applied:

1. online without errors (works on previous version and new one)
2. online with errors on old instances after migrating
3. online with errors on new instances while migrating
4. offline (needs to happen without app servers to prevent db corruption)

It is always preferable to have a migration run online. If you expect the migration
to take particularly long (for instance, if it loops through all notes),
this is valuable information to add.

### Reversibility

Your migration should be reversible. This is very important, as it should
be possible to downgrade in case of a vulnerability or bugs.

In your migration, add a comment describing how the reversibility of the
migration was tested.