---
comments: false
type: index, dev
stage: none
group: Development
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
description: "Development Guidelines: learn about workspaces when developing GitLab."
---

# Workspaces

[Read more](../../user/workspace/index.md) about the workspaces initiative.

## Consolidate Groups and Projects

- [Architecture blueprint](../../architecture/blueprints/consolidating_groups_and_projects/index.md)

Consolidate Groups and Projects is one facet of the workspaces initiative, addressing the feature disparity between
groups and projects.

There is feature disparity between groups and projects. Some features only available at group level (for example epics).
Some features only available at project level (for example issues). And some features available at both levels
(for example labels, milestones).

We get more and more requests to get one feature or another added to either group or project level. This takes
engineering time, to just move features around to different levels. This also adds a UX overhead of keeping a mental
model of which features are available at which level.

This also creates lots of redundant code. Features get copied from project, to group to instance level with small
nuances between them. This also causes extra maintenance, when something needs to be fixed. The fix is copied to
several locations. This also creates different user experience for the same feature but in the different locations.

To solve this we are moving towards consolidating groups and projects into a single entity, namespace. The work on this
solution is split into several phases and is tracked in [epic 6473](https://gitlab.com/groups/gitlab-org/-/epics/6473).

### Phase 1

Epic tracking [Phase 1](https://gitlab.com/groups/gitlab-org/-/epics/6697)

Goal of Phase 1 is to ensure that every project gets a corresponding record in `namespaces` table with `type='Project'`.
For user namespaces, type changes from `NULL` to `User`.

Places where we should make sure project and project namespace go hand in hand:

- Create project.
  - Use Rails callbacks to ensure a new project namespace is created for each project.
    - In this case project namespace records should have `created_at`/`updated_at` attributes equal to project's `created_at`/`updated_at` attributes.
- Update Project.
  - Use Rails `after_save` callback to ensure some attributes are kept in sync between project and project namespaces,
  see [project#after_save](https://gitlab.com/gitlab-org/gitlab/blob/6d26634e864d7b748dda0e283eb2477362263bc3/app/models/project.rb#L101-L101).
- Delete project.
  - Use FKs cascade delete or Rails callbacks to ensure when either a `Project` or its `ProjectNamespace` is removed its
  corresponding `ProjectNamespace` or `Project` respectively is removed as well.
- Transfer project to a different group.
  - Make sure that when a project is transferred, its corresponding project namespace is transferred to the same group.
- Transfer group.
  - Make sure when transferring a group that all of its sub projects, either direct or through descendant groups, have their
  corresponding project namespaces transferred correctly as well.
- Export/import project.
  - Export project would continue to only export the project and not its project namespace in this phase. Project
  namespace does not contain any specific information that has to be exported at this point. Eventually we want the
  project namespace to be exported as well.
  - Import creates a new project, so project namespace is created through Rails `after_save` callback on the project model.
- Export/import group.
  - As of this writing, when importing or exporting a `Group`, `Project`s are not included in the operation. If that functionality is changed to include `Project` when its Group is imported/exported, the logic must be sure to include their corresponding project namespaces in the import/export.

After ensuring the above points, we plan to run a DB migration to create a `ProjectNamespace` record for every `Project`.
Project namespace records created during migration should have `created_at`/`updated_at` attributes set to migration
runtime. That means that project namespaces `created_at`/`updated_at` attributes don't match their corresponding
project's `created_at`/`updated_at` attributes. We want the different dates to help audit any of the created project
namespaces, in case we need it. We plan to run the back-filling migration in 14.5 milestone.

### Phase 2

Epic tracking [Phase 2](https://gitlab.com/groups/gitlab-org/-/epics/6768)

The focus of this phase is to make `ProjectNamespace` the front entity to interact with instead of `Project` .
Problems to solve as part of this phase:

- Routes handling through project namespace rather than project.
- Memberships handling.
- Policies handling.
- Import/export.
- Other interactions between project namespace and project models.

Communicate the changes company wide at the engineers level. We want engineers to be aware of the upcoming changes even
though active collaboration of teams is expected only in phase 3. Raise awareness to avoid regressions, conflicting or duplicate work
that can be taken care of even before phase 3.

### Phase 3

Epic tracking [Phase 3](https://gitlab.com/groups/gitlab-org/-/epics/6585)

The focus of this phase is to get feature parity between the namespace types. Phase 3 is when active migration
of features from `Project` to `ProjectNamespace` or directly to `Namespace` happens.
