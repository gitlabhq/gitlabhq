---
owning-stage: "~devops::data stores"
description: 'Cells ADR 007: Cells 1.0 for internal customers only'
---

<!-- vale gitlab.FutureTense = NO -->

# Cells ADR 007: Cells 1.0 for internal customers only

## Context

[Initially](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139519) Cells 1.0 was created for new customers only.
Finding new customers willing to onboard on untested infrastructure turned out to be a challenge, especially with [missing features](../iterations/cells-1.0.md).
Not having a customer in mind makes it impossible for us to define scope of which features to deliver.

## Decision

Cells 1.0 will only be for internal customers of GitLab where a subset of team members will have their groups migrated to another Cell and work on that Cell.
This will allow us to dogfood important workflows before rolling them out to customers.
Groups and projects of the internal customer will have to be private, because the Organization will stay private.
Internal customers might not need things like the CI Catalog or Advanced Search.

The first internal customer to migrate is yet to be identified.
The migration will loosely follow this plan:

1. Create `GitLab Inc.` Organization on another Cell
1. Use [Direct Transfer](../../../../user/group/import/index.md) to move a group from the existing GitLab.com infrastructure to the other Cell.
1. Use [Org Mover](https://gitlab.com/groups/gitlab-org/-/epics/12857) when it's ready to migrate the rest of the top-level groups and the feature set is enough for that top-level group. For example, `gitlab-org` will be moved in Cells 2.0.

## Consequences

Users of Cells 1.0 can only be associated with one Organization, so certain GitLab team members will have to manage two accounts: one to access the default Organization on GitLab.com, and one to access `GitLab Inc.` on another Cell.
This might temporarily complicate their workflow, in case they want to collaborate with the rest of the GitLab team members.

## Alternatives

The only alternative is finding new customers who are willing to partner with us.
This search is ongoing, and the above proposal will allow us to move forward regardless.
