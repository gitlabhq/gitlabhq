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
