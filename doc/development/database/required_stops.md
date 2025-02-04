---
stage: Data Access
group: Database
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Database required stops
---

This page describes which database changes require GitLab upgrade stops. If you're interested
about a comprehensive list of causes, refer to [causes of required stops](../avoiding_required_stops.md#causes-of-required-stops).

[Required stops](../../update/upgrade_paths.md) will now consistently land on minor versions X.2, X.5, X.8 and X.11. This is to ensure predictable upgrade paths for users. Any changes to the database that require a stop can make use of these releases. The instructions below are used to add required upgrade stops.

## Common database changes that require stops

### Long running migrations being finalized

If a migration takes a long time, it could cause a large number of customers to encounter timeouts
during upgrades. The increased support volume may cause us to introduce a required stop. While any
background migration may cause these issues with particularly large customers, we typically only
introduce stops when the impact is widespread.

- **Cause:** When an upgrade takes more than an hour, omnibus times out.
- **Mitigation:** Schedule finalization for the first minor version after the next required stop.

### Improperly finalized background migrations

You may need to introduce a required stop for mitigation when:

- A background migration is not finalized, and
- A migration is written that depends on that background migration.

- **Cause:** The dependent migration may fail if the background migration is incomplete.
- **Mitigation:** Ensure that all background migrations are finalized before authoring dependent migrations.

### Remove a migration

If a migration is removed, you may need to introduce a required stop to ensure customers
don't miss the required change.

- **Cause:** Dependent migrations may fail, or the application may not function, because a required
  migration was removed.
- **Mitigation:** Ensure migrations are only removed after they've been a part of a planned
  required stop.

### A migration timestamp is very old

If a migration timestamp is very old (> 3 weeks, or after a before the last stop),
these scenarios may cause issues:

- If the migration depends on another migration with a newer timestamp but introduced in a
  previous release _after_ a required stop, then the new migration may run sequentially sooner
  than the prerequisite migration, and thus fail.
- If the migration timestamp ID is before the last, it may be inadvertently squashed when the
  team squashes other migrations from the required stop.

- **Cause:** The migration may fail if it depends on a migration with a later timestamp introduced
  in an earlier version. Or, the migration may be inadvertently squashed after a required stop.
- **Mitigation:** Aim for migration timestamps to fall inside the release dates and be sure that
  they are not dated prior to the last required stop.

### Bugs in migration related tooling

In a few circumstances, bugs in migration related tooling has required us to introduce stops. While we aim
to prevent these in testing, sometimes they happen.

- **Cause:** There have been a few different causes where we recognized these too late.
- **Mitigation:** Typically we try to backport fixes for migrations, but in some cases this is not possible.

## Adding a required stop

If you plan to introduce a change the falls into one of the above scenarios,
please refer to [adding required stops](../avoiding_required_stops.md#adding-required-stops).
