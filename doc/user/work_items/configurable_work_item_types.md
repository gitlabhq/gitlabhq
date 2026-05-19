---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Create, control, and configure work item types with names and icons to match your organization's planning processes.
title: Configurable work item types
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/7897) in GitLab 19.0 [with a flag](../../administration/feature_flags/_index.md) named `work_item_configurable_types`. Enabled by default.

{{< /history >}}

Customize work item types to match your planning
workflows. Create new types with names and icons, and
control which types are available in your projects.
A work item type configuration cascades to all
projects.

New types are available at the project level only.
Their widgets and hierarchy restrictions match those
of issues. You can associate new types with
[custom fields](custom_fields.md) and
[status lifecycles](status.md). You can also filter
by work item type in
[saved views](saved_views.md) and issue boards.

## Limits and naming rules

You can have a maximum of 40 work item types in a top-level group or organization,
including types provided by GitLab.
Type names must be unique in a namespace or organization and no more than 48 characters.
A type cannot share a name with another type, including archived and disabled types.
Vulnerability, merge request, commit, pipeline, alert, review, diff, report,
and sha are reserved names that cannot be used.

When you rename a type (for example, rename `Feature` to `Enhancement`), the original name is
available for a new type. You can rename a type back to its original name if that name has not been taken.

## Work item type states

Each work item type has one of the following states:

| State | Description |
|-------|-------------|
| Enabled | The default state. The type is available to create work items and appears in filters. |
| Disabled | The type cannot be used to create new work items and does not appear in filters. You can still rename and change the icon of a disabled type. Existing work items of that type are not affected. |
| Archived | The type is removed from all lists, filters, and creation flows. You can only view and unarchive archived types at the top-level group or organization level. You cannot rename or change the icon of an archived type. |
| Locked | The type is tied to a specific GitLab feature and cannot be renamed, disabled, or archived. For example, Ticket, Incident, Epic, and Task types are locked. |

> [!note]
> Epics appear as a work item type at the project level
> but are disabled for projects because epics are
> available only at the group level.

## Create a work item type

Create a work item type with a name and icon to
represent a specific category of work.

Prerequisites:

- On GitLab.com: You must have at least the Maintainer
  role for the top-level group.
- On GitLab Self-Managed: You must be an instance
  administrator or organization owner.

To create a work item type:

1. Go to the work items settings:
   - On GitLab.com: In the top bar, select
     **Search or go to** and find your top-level group.
     In the left sidebar, select
     **Settings** > **Work items**.
   - On GitLab Self-Managed: In the upper-right corner, select **Admin**.
     In the left sidebar, select
     **Settings** > **Work items**.
1. In the **Work item types** section, select
   **New type**.
1. Enter a name for the type.
1. Select an icon.
1. Select **Save**.

## Edit a work item type

Update the name or icon of an existing work item type.

Prerequisites:

- On GitLab.com: You must have at least the Maintainer
  role for the top-level group.
- On GitLab Self-Managed: You must be an instance
  administrator or organization owner.
- The type must not be locked or archived.

To edit a work item type:

1. Go to the work items settings:
   - On GitLab.com: In the top bar, select
     **Search or go to** and find your top-level group.
     In the left sidebar, select
     **Settings** > **Work items**.
   - On GitLab Self-Managed: In the upper-right corner, select **Admin**.
     In the left sidebar, select
     **Settings** > **Work items**.
1. In the **Work item types** section, find the type
   you want to edit.
1. Select **Edit name and icon**.
1. Update the name, icon, or both.
1. Select **Save**.

> [!note]
> Types that are tied to certain GitLab features cannot
> be edited. For example, Ticket, Incident, Epic, and
> Task types are locked and cannot be renamed or have
> their icon changed.

## Archive a work item type

Archive a work item type to remove it from all lists,
filters, and creation flows. Archived types remain in
the system, and existing work items of that type are
not affected.

Prerequisites:

- On GitLab.com: You must have at least the Maintainer
  role for the top-level group.
- On GitLab Self-Managed: You must be an instance
  administrator or organization owner.

To archive a work item type:

1. Go to the work items settings:
   - On GitLab.com: In the top bar, select
     **Search or go to** and find your top-level group.
     In the left sidebar, select
     **Settings** > **Work items**.
   - On GitLab Self-Managed: In the upper-right corner, select **Admin**.
     In the left sidebar, select
     **Settings** > **Work items**.
1. In the **Work item types** section, find the type
   you want to archive.
1. Select **Archive**.
1. In the confirmation dialog, select **Archive**.

Archived types are visible only at the top-level group
or organization level in the **Archived** tab. They are
not visible at the subgroup or project level.

## Unarchive a work item type

Restore an archived work item type to make it
available again.

Prerequisites:

- On GitLab.com: You must have at least the Maintainer
  role for the top-level group.
- On GitLab Self-Managed: You must be an instance
  administrator or organization owner.
- The total number of active types must be below the
  maximum of 40.

To unarchive a work item type:

1. Go to the work items settings:
   - On GitLab.com: In the top bar, select
     **Search or go to** and find your top-level group.
     In the left sidebar, select
     **Settings** > **Work items**.
   - On GitLab Self-Managed: In the upper-right corner, select **Admin**.
     In the left sidebar, select
     **Settings** > **Work items**.
1. In the **Work item types** section, select the
   **Archived** tab.
1. Find the type you want to restore.
1. Select **Unarchive**.
1. In the confirmation dialog, select **Unarchive**.

## Type availability controls

Control which work item types are available in your
projects. Type availability has three layers:

- **Type customization in projects**: A switch
  at the top-level group or organization that
  allows or prevents projects from customizing type
  availability. Disabled by default.
- **Per-type availability for all projects**: Enable
  or disable a specific type across all descendant
  projects.
- **Per-project availability**: Individual projects
  can enable or disable types for their own scope.

### Allow type customization in projects

Control the ability for projects to
customize which types are available.

Prerequisites:

- On GitLab.com: You must have at least the Maintainer
  role for the top-level group.
- On GitLab Self-Managed: You must be an instance
  administrator or organization owner.

To toggle type customization:

1. Go to the work items settings:
   - On GitLab.com: In the top bar, select
     **Search or go to** and find your top-level group.
     In the left sidebar, select
     **Settings** > **Work items**.
   - On GitLab Self-Managed: In the upper-right corner, select **Admin**.
     In the left sidebar, select
     **Settings** > **Work items**.
1. In the **Type customization in projects** section,
   select **Enable** or **Disable**.

When you disable type customization, all types are
treated as enabled in all projects regardless of
previous visibility settings. Per-project overrides
are preserved but ignored. Re-enabling type
customization restores the previous configuration.

### Enable or disable a type for all projects

Control the availability of a specific type across all
descendant projects at once. This removes any
per-project overrides for that type.

Prerequisites:

- On GitLab.com: You must have at least the Maintainer
  role for the top-level group.
- On GitLab Self-Managed: You must be an instance
  administrator or organization owner.

To enable or disable a type for all projects:

1. Go to the work items settings:
   - On GitLab.com: In the top bar, select
     **Search or go to** and find your top-level group.
     In the left sidebar, select
     **Settings** > **Work items**.
   - On GitLab Self-Managed: In the upper-right corner, select **Admin**.
     In the left sidebar, select
     **Settings** > **Work items**.
1. In the **Work item types** section, find the type.
1. From the type actions menu, select
   **Enable for all projects** or
   **Disable for all projects**.

### Enable or disable a type in a project

Control which types are available in a specific
project.

Prerequisites:

- You must have at least the Maintainer role for
  the project.

To enable or disable a type in a project:

1. In the top bar, select **Search or go to** and
   find your project.
1. In the left sidebar, select
   **Settings** > **Work items**.
1. In the **Enabled work item types** section, find
   the type.
1. Toggle the type on or off.

When you disable a type in a project, the type
cannot be used to create new work items in that
project. Existing work items of that type are not
affected.
