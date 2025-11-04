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

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/479571) in GitLab 17.11 [with a flag](../../administration/feature_flags/_index.md) named `custom_fields_feature`.
  Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/479571) in GitLab 18.0. Feature flag `custom_fields_feature` removed.

{{< /history >}}

Custom fields add specialized information to work items, such as issues and epics, that match your specific planning needs.
Configure custom fields for a group to track data points like business value, risk assessment, priority ranking, or team attributes.
These fields appear in all work items across the group, its subgroups, and projects.

Custom fields help teams standardize how they record and report information across the entire workflow.
This standardization creates consistency across projects and supports more powerful filtering and reporting capabilities.
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

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
   This group must be at the top level.
1. Select **Settings** > **Issues**.
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
     - To add multiple options at once, select the input and paste a list of items, one per line.
1. Select **Save**.

### Edit a custom field

Edit existing custom fields to reflect changing needs in your organization.
You can modify a field's name, the work item types it applies to, and the available options without
losing existing data.

Prerequisites:

- You must have at least the Maintainer role for the group.

To edit a custom field:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
   This group must be at the top level.
1. Select **Settings** > **Issues**.
1. Next to the field you want to edit, select **Edit `<field name>`** ({{< icon name="pencil" >}}).
1. Make changes to any of the fields.
1. Select **Update**.

### Archive a custom field

Archive custom fields that are no longer needed while preserving their historical data.
Archiving removes the field from any work items that had them.

Prerequisites:

- You must have at least the Maintainer role for the group.

To archive a custom field:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
   This group must be at the top level.
1. Select **Settings** > **Issues**.
1. Next to the field you want to archive, select **Archive `<field name>`** ({{< icon name="archive" >}}).

### Unarchive a custom field

Restore a previously archived custom field when you need to use it again.
Work items that had values set for this field retain the same values they had before the field was archived.

Prerequisites:

- You must have at least the Maintainer role for the group.

To unarchive a custom field:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
   This group must be at the top level.
1. Select **Settings** > **Issues**.
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

## Field type selection guide

When creating custom fields, choose a field type that matches the kind of data you want to track.
The right field type improves data quality and makes reporting more effective.

### Single-select fields

Use single-select fields when:

- Users should choose exactly one option from a predefined list.
- The options are mutually exclusive.
- You want to enforce consistency and prevent free-form input.

Single-select fields work well for:

- Priority indicators (like `High`, `Medium`, `Low`)
- Category assignments
- Team assignments
- Approval states
- Priority levels

### Multi-select fields

Use multi-select fields when:

- Multiple values might apply simultaneously.
- You need to track overlapping attributes.
- Items might belong to multiple categories.

Multi-select fields work well for:

- Tags or labels
- Skills required
- Affected components
- Stakeholder groups
- Feature capabilities

### Number fields

Use number fields when:

- You need to collect quantitative data.
- You want to perform calculations or aggregations.
- The information needs to be sortable numerically.

Number fields work well for:

- Cost estimates
- Time estimates
- Business value scores
- Ranking or prioritization scores
- Percentage complete

### Text fields

Use text fields when:

- You need to capture unique information that doesn't fit predefined categories.
- The data is highly variable.
- You need to provide context or details.

Text fields work well for:

- Additional context
- External reference IDs
- Contact information
- Brief notes or comments
- URLs or links

## Naming conventions for custom fields

Consistent naming conventions for custom fields make them easier to understand and use.
Good field names improve adoption and data quality.

### General guidelines

- Keep names concise but descriptive.
- Use clear, specific language that your organization understands.
- Be consistent with capitalization (title case is recommended).
- Avoid abbreviations unless they're widely understood.
- Include the unit of measure when applicable.

### Naming single-select and multi-select fields

Start with the category name, followed by a descriptor. For example:

- `Risk Level` instead of `Risk`
- `Customer Segment` instead of `Segment`
- `Development Phase` instead of `Phase`
- `Approval Status` instead of `Status`

### Naming number fields

Include the unit of measurement in the field name. For example:

- `Effort Points` instead of `Points`
- `Budget Estimate ($)` instead of `Budget`
- `Implementation Time (days)` instead of `Time`
- `Business Value Score` instead of `Value`

### Naming text fields

Clearly indicate what information should be entered. For example:

- `External Reference ID` instead of `Reference`
- `Implementation Notes` instead of `Notes`
- `Requirements Source` instead of `Source`

### Team-specific prefixes

If multiple teams use the same GitLab instance, consider adding team prefixes to avoid confusion:

- `DEV: Sprint Priority`
- `QA: Test Environment`
- `UX: Design Status`
- `PM: Market Segment`

This approach helps teams quickly identify which fields are relevant to their work.
