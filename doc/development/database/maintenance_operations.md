---
stage: Data Access
group: Database Frameworks
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Maintenance operations
---

This page details various database related operations that may relate to development.

## Disabling an index is not safe

WARNING:
Previously, this section described a procedure to mark the index as invalid before removing it.
It's no longer recommended, as [it is not safe](https://gitlab.com/groups/gitlab-org/-/epics/11543#note_1570734906).

There are certain situations in which you might want to disable an index before removing it:

- The index is on a large table and rebuilding it in the case of a revert would take a long time.
- It is uncertain whether or not the index is being used in ways that are not fully visible.

In such situations, the index was disabled in a coordinated manner with
the infrastructure team and the database team
by opening a [production infrastructure issue](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/new)
with the "Production Change" template and
then running the following commands:

```sql
-- Disable the index then run an EXPLAIN command known to use the index:
UPDATE pg_index SET indisvalid = false WHERE indexrelid = 'index_issues_on_foo'::regclass;
-- Verify the index is invalid on replicas:
SELECT indisvalid FROM pg_index WHERE indexrelid = 'index_issues_on_foo'::regclass;

-- Rollback the invalidation:
UPDATE pg_index SET indisvalid = true WHERE indexrelid = 'index_issues_on_foo'::regclass;
```

See this [example infrastructure issue](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/2795) for reference.
