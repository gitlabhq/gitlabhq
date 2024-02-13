---
stage: Data Stores
group: Tenant Scale
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# GitLab Cells Development Guidelines

For background of GitLab Cells, refer to the [blueprint](../../architecture/blueprints/cells/index.md).

## Essential and additional workflows

To make the application work within the GitLab Cells architecture, we need to fix various
[workflows](../../architecture/blueprints/cells/index.md#2-workflows).

Here is the suggested approach:

1. Pick a workflow to fix.
1. Firstly, we need to find out the tables that are affected while performing the chosen workflow. As an example, in [this note](https://gitlab.com/gitlab-org/gitlab/-/issues/428600#note_1610331742) we have described how to figure out the list of all tables that are affected when a project is created in a group.
1. For each table affected for the chosen workflow, choose the approriate
   [GitLab schema](../database/multiple_databases.md#gitlab-schema).
1. Identify all cross-joins, cross-transactions, and cross-database foreign keys for
   these tables.
   See the [multiple databases guide](../database/multiple_databases.md)
   on how to identify, and allowlist these items.
1. Fix the cross-joins and cross-database foreign keys necessary for the
   workflow to work with GitLab Cells.
   See the [multiple databases guide](../database/multiple_databases.md)
   on how to fix these items.
1. For the cross-joins, cross-transactions, and cross-database foreign keys that
   were not fixed, open and schedule issues to fix later.
1. Confirm the fixes work by completing the workflow successfully in a local
   GDK running multiple cells.

Refer to following epics for examples:

- [User can create group on Cell 2 while users are shared between Cells](https://gitlab.com/groups/gitlab-org/-/epics/9813)
- [Essential workflows: User can create Project](https://gitlab.com/groups/gitlab-org/-/epics/11683)
