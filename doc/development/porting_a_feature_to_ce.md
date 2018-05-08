# Porting a feature from Enterprise Edition (EE) to Community Edition (CE)

Porting a feature from one version to the other can sometimes be a complicated process
with many pitfalls, this document lays out some lessons learned and common pitfalls to avoid.

## The EE counterpart should always be the superset of all changes

There should be no change in the CE version that is not in EE.

If a table being ported has extra columns in EE than in CE make sure you add those columns 
in a separate EE-only migration.

## Scope

You should always try to reduce the scope as much as possible, to keep the changes intuitive
and easy to review. 

A good example would be if there are a few methods in a model that need to be ported over 
to another model. In that case, a good possibility would be to begin by delegating every method
to that model, and then, make a separate merge request that finishes the port of those methods.

## Migrations

Migrations can become quite a complex matter at GitLab's scale so they should always be handled with
extreme care.

Make sure you read the [What requires downtime guidelines][downtime] and the
[Background migrations guidelines][background].

If a table needs to be migrated, you should always base yourself on the actual state of the schema 
rather than looking at each migration related with the table in question.

If we are dealing with a large volume of data that needs to be ported, batching should be considered.
For more information refer to the [iterating tables in batches guidelines][batches].

Always make sure the database changes are MySQL compatible. 

## Pipelines

The EE specific pipelines, such as `ee_compat_check`, `ee-specific-lines-check` and `ee-files-location-check`
become especially useful when porting a feature over to CE since they will be able to help you prevent
possible conflicts when a CE-to-EE merge takes place.

[downtime]: https://docs.gitlab.com/ee/development/what_requires_downtime.html
[background]: https://docs.gitlab.com/ee/development/background_migrations.html
[batches]: https://docs.gitlab.com/ce/development/iterating_tables_in_batches.html
