---
comments: false
type: index, dev
stage: none
group: Development
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
description: "Development Guidelines: learn about workspace when developing GitLab."
---

# Workspace

The [Workspace initiative](../../user/workspace/index.md) focuses on reaching feature parity between
SaaS and self-managed installations.

## Consolidate groups and projects

- [Architecture blueprint](../../architecture/blueprints/consolidating_groups_and_projects/index.md)

One facet of the workspace initiative is to consolidate groups and projects,
addressing the feature disparity between them. Some features, such as epics, are
only available at the group level. Some features, such as issues, are only available
at the project level. Other features, such as milestones, are available to both groups
and projects.

We receive many requests to add features either to the group or project level.
Moving features around to different levels is problematic on multiple levels:

- It requires engineering time to move the features.
- It requires UX overhead to maintain mental models of feature availability.
- It creates redundant code.

When features are copied from one level (project, group, or instance) to another,
the copies often have small, nuanced differences between them. These nuances cause
extra engineering time when fixes are needed, because the fix must be copied to
several locations. These nuances also create different user experiences when the
feature is used in different places.

A solution for this problem is to consolidate groups and projects into a single
entity, `namespace`. The work on this solution is split into several phases and
is tracked in [epic 6473](https://gitlab.com/groups/gitlab-org/-/epics/6473).

### Phase 1

- [Phase 1 epic](https://gitlab.com/groups/gitlab-org/-/epics/6697).
- **Goals**:
  1. Ensure every project receives a corresponding record in the `namespaces`
     table with `type='Project'`.
  1. For user namespaces, the type changes from `NULL` to `User`.

We should make sure that projects, and the project namespace, are equivalent:

- **Create project:** use Rails callbacks to ensure a new project namespace is
  created for each project. Project namespace records should contain `created_at` and
  `updated_at` attributes equal to the project's `created_at`/`updated_at` attributes.
- **Update project:** use the `after_save` callback in Rails to ensure some
  attributes are kept in sync between project and project namespaces.
  Read [`project#after_save`](https://gitlab.com/gitlab-org/gitlab/blob/6d26634e864d7b748dda0e283eb2477362263bc3/app/models/project.rb#L101-L101)
  for more information.
- **Delete project:** use FKs cascade delete or Rails callbacks to ensure when a `Project`
  or its `ProjectNamespace` is removed, its corresponding `ProjectNamespace` or `Project`
  is also removed.
- **Transfer project to a different group:** make sure that when a project is transferred,
  its corresponding project namespace is transferred to the same group.
- **Transfer group:** make sure when transferring a group that all of its sub-projects,
  either direct or through descendant groups, have their corresponding project
  namespaces transferred correctly as well.
- **Export or import project**
  - **Export project** continues to export only the project, and not its project namespace,
    in this phase. The project namespace does not contain any specific information
    to export at this point. Eventually we want the project namespace to be exported as well.
  - **Import project** creates a new project, so the project namespace is created through
    Rails `after_save` callback on the project model.
- **Export or import group:** when importing or exporting a `Group`, projects are not
  included in the operation. If that feature is changed to include `Project` when its group is
  imported or exported, the logic must include their corresponding project namespaces
  in the import or export.

After ensuring these points, run a database migration to create a `ProjectNamespace`
record for every `Project`. Project namespace records created during the migration
should have `created_at` and `updated_at` attributes set to the migration runtime.
The project namespaces' `created_at` and `updated_at` attributes would not match
their corresponding project's `created_at` and `updated_at` attributes. We want
the different dates to help audit any of the created project namespaces, in case we need it.
After this work completes, we must migrate data as described in
[Backfill `ProjectNamespace` for every Project](https://gitlab.com/gitlab-org/gitlab/-/issues/337100).

### Phase 2

- [Phase 2 epic](https://gitlab.com/groups/gitlab-org/-/epics/6768).
- **Goal**: Make `ProjectNamespace` the front entity to interact with instead of `Project`.

In this phase:

- Communicate the changes company-wide at the engineering level. We want to make
  engineers aware of the upcoming changes, even though teams are not expected to
  collaborate actively until phase 3.
- Raise awareness to avoid regressions, and conflicting or duplicate work that
  can be dealt with before phase 3.

Problems to solve as part of this phase:

- Routes handling through `ProjectNamespace` rather than `Project`.
- Memberships handling.
- Policies handling.
- Import and export.
- Other interactions between project namespace and project models.

### Phase 3

- [Phase 3 epic](https://gitlab.com/groups/gitlab-org/-/epics/6585).
- **Goal**: Feature parity between the namespace types.

Phase 3 is when the active migration of features from `Project` to `ProjectNamespace`,
or directly to `Namespace`, happens.

## Related topics

- [Consolidating groups and projects](../../architecture/blueprints/consolidating_groups_and_projects/index.md)
  architecture documentation
- [Workspace user documentation](../../user/workspace/index.md)
