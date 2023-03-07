---
stage: Data Stores
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Adding required stops

Required stops should only be added when it is deemed absolutely necessary, due to their
disruptive effect on customers. Before adding a required stop, consider if any
alternative approaches exist to avoid a required stop. Sometimes a required
stop is unavoidable. In those cases, follow the instructions below.

## Common scenarios that require stops

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

### Bugs in migration related tooling

In a few circumstances, bugs in migration related tooling has required us to introduce stops. While we aim
to prevent these in testing, sometimes they happen.

- **Cause:** There have been a few different causes where we recognized these too late.
- **Mitigation:** Typically we try to backport fixes for migrations, but in some cases this is not possible.

## Before the required stop is released

Before releasing a known required stop, complete these steps. If the required stop
is identified after release, the following steps must still be completed:

1. Update [upgrade paths](../../update/index.md#upgrade-paths) to include the new
   required stop.
1. Communicate the changes with the customer Support and Release management teams.
1. File an issue with the Database group to squash migrations to that version in the
   next release. Use this template for your issue:

   ```markdown
   Title: `Squash migrations to <Required stop version>`
   As a result of the required stop added for <required stop version> we should squash
   migrations up to that version, and update the minimum schema version.

   Deliverables:
   - [ ] Migrations are squashed up to <required stop version>
   - [ ] `Gitlab::Database::MIN_SCHEMA_VERSION` matches init_schema version

   /label ~"group::database" ~"section::enablement" ~"devops::data_stores" ~"Category:Database" ~"type::maintenance"
   /cc @gitlab-org/database-team/triage
   ```

## In the release following the required stop

1. Update `Gitlab::Database::MIN_SCHEMA_GITLAB_VERSION` in `lib/gitlab/database.rb` to the
   new required stop versions. Do not change `Gitlab::Database::MIN_SCHEMA_VERSION`.
