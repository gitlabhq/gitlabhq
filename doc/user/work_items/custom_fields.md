---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Create and use custom fields for work items to track specific information unique to your workflow. Configure field types to enhance planning and reporting capabilities."
title: Custom fields
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/479571) in GitLab 17.11 [with a flag](../../administration/feature_flags.md) named `custom_fields_feature`.
  Disabled by default.
  Enabled on GitLab.com for a subset of users.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

Custom fields add specialized information to work items, such as issues and epics, that match your specific planning needs.
Configure custom fields for a group to track data points like business value, risk assessment, priority ranking, or team attributes.
These fields appear in all work items across the group, its subgroups, and projects.

Custom fields help teams standardize how they record and report information across the entire workflow.
This standardization creates consistency across projects.
<!-- Use the sentence below when custom fields show on filters: -->
<!-- This standardization creates consistency across projects and supports more powerful filtering and reporting capabilities. -->
Choose from various field types to accommodate different data requirements and planning scenarios:

- Single-select
- Multi-select
- Number
- Text

## Configure custom fields for a group

Configure custom fields for top-level groups to make them available for work items in that group,
its subgroups, and projects.

### Create a custom field

Create custom fields to capture the specific information your team needs to track.
You can configure each field for one or more work item types, tailoring your workflow to
your organization's requirements.

Keep these limits in mind:

- A top-level group can have at most 50 active custom fields.
- A work item type can have at most 10 custom fields assigned to it.

Prerequisites:

- You must have at least the Maintainer role for the group.

To create a custom field:

1. On the left sidebar, select **Search or go to** and find your group.
   This group must be at the top level.
1. Select **Settings > Issues**.
1. Select **Create field**.
1. Complete the fields:
   - In **Type**, select what type the field should be:
     - Single-select
     - Multi-select
     - Number
     - Text field

     The field type cannot be changed after you create the field.
   - In **Use on**, select the work item types where you want this field to be available.
   - In **Options** (on single-select and multi-select fields), enter the possible select options.
     A single-select or multi-select field can have at most 50 select options.
     - Reorder options by dragging the grip icon ({{< icon name="grip" >}}) to the left of each option.
1. Select **Save**.

### Edit a custom field

Edit existing custom fields to reflect changing needs in your organization.
You can modify a field's name, the work item types it applies to, and the available options without
losing existing data.

Prerequisites:

- You must have at least the Maintainer role for the group.

To edit a custom field:

1. On the left sidebar, select **Search or go to** and find your group.
   This group must be at the top level.
1. Select **Settings > Issues**.
1. Next to the field you want to edit, select **Edit `<field name>`** ({{< icon name="pencil" >}}).
1. Make changes to any of the fields.
1. Select **Update**.

### Archive a custom field

Archive custom fields that are no longer needed while preserving their historical data.
Archiving removes the field from any work items that had them.

Prerequisites:

- You must have at least the Maintainer role for the group.

To archive a custom field:

1. On the left sidebar, select **Search or go to** and find your group.
   This group must be at the top level.
1. Select **Settings > Issues**.
1. Next to the field you want to archive, select **Archive `<field name>`** ({{< icon name="archive" >}}).

### Unarchive a custom field

Restore a previously archived custom field when you need to use it again.
Work items that had values set for this field retain the same values they had before the field was archived.

Prerequisites:

- You must have at least the Maintainer role for the group.

To unarchive a custom field:

1. On the left sidebar, select **Search or go to** and find your group.
   This group must be at the top level.
1. Select **Settings > Issues**.
1. Select the **Archived** tab to list archived fields.
1. Next to the field you want to unarchive, select **Unarchive `<field name>`** ({{< icon name="redo" >}}).

## Set custom field values for a work item

Add relevant information to work items by using the custom fields configured for your group.

Prerequisites:

- You must have at least the Planner role for the work item's project or group.
- If you have the Guest role, you can set custom fields only when creating a work item.

1. Go to a work item.
1. On the right sidebar, find the section for the custom field you want to edit, and then select **Edit**.
1. Enter or select the desired value.
   - A text field value can have at most 1024 characters.
1. Select any area outside the field.
