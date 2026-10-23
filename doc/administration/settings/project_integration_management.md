---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Integration administration
description: "Configure and manage default settings for project and group integrations in an organization or GitLab instance."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> For user documentation, see [project integrations](../../user/project/integrations/_index.md).

Project and group administrators can configure and enable integrations.
As an organization administrator, you can [set default configuration parameters](#in-the-organization-admin-area) for integrations in your organization.
As an instance administrator, you can:

- Set default configuration parameters for an integration.
- Configure an allowlist to control which integrations can be enabled on a GitLab instance.

## Configure default settings for an integration

Default settings for an integration belong to an organization.
Groups and projects in that organization inherit them.
You can configure them from the **Admin** area as an instance administrator, or from the **Organization Admin** area as an organization administrator.

> [!warning]
> This might affect all or most of the groups and projects in the organization.
> Review the following details.

If this is the first time you are setting up default settings for an integration:

- The integration is enabled for all groups and projects that don't already have this integration configured, if you have the **Enable integration** toggle turned on in the default settings.
- Groups and projects that already have the integration configured are not affected, but can choose to use the inherited settings at any time.

When you make further changes to the defaults:

- They are immediately applied to all groups and projects that have the integration set to use default settings.
- They are immediately applied to newer groups and projects, created after you last saved defaults for the integration. If your default setting has the **Enable integration** toggle turned on, the integration is automatically enabled for all such groups and projects.
- Groups and projects with custom settings selected for the integration are not immediately affected and may choose to use the latest defaults at any time.

Default settings are inherited in this order: organization, then group, then project.
If [group-level settings](../../user/project/integrations/_index.md#manage-group-default-settings-for-a-project-integration) have also
been configured for the same integration, projects in that group inherit the group-level settings instead of the organization-level settings.
Groups and projects do not inherit defaults from other organizations.

Only the entire settings for an integration can be inherited. Per-field inheritance
is proposed in [epic 2137](https://gitlab.com/groups/gitlab-org/-/work_items/2137).

### In the Admin area

{{< details >}}

- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Defaults you set in the **Admin** area belong to the [default organization](../../user/organization/_index.md#the-default-organization), which holds all groups and projects on an instance with a single organization.

Prerequisites:

- You must have administrator access to the instance.

To configure default settings for an integration:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Integrations**.
1. Select an integration.
1. Complete the fields.
1. Select **Save changes**.

### In the Organization Admin area

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

Prerequisites:

- You must be an [organization administrator](../../user/organization/_index.md#user-types-and-permissions).

To configure default settings for an integration in your organization:

1. In the left sidebar, select **Organizations**.
1. From the dropdown list, select the organization you want to go to.
1. In the left sidebar, select **Manage organization**. The **Organization Admin** area opens.
1. Select **Settings** > **Integrations**.
1. Select an integration.
1. Complete the fields.
1. Select **Save changes**.

The Beyond Identity and Amazon Q integrations are not available in the **Organization Admin** area.
Only instance administrators can configure them, in the **Admin** area.

From the same page, you can also:

- Select **Reset** to remove default settings for an integration.
- Select the **Projects using custom settings** tab to view projects that use custom settings.
  The list shows only projects in that organization.

### Remove default settings for an integration

{{< details >}}

- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prerequisites:

- You must have administrator access to the instance.

To remove default settings for an integration:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Integrations**.
1. Select an integration.
1. Select **Reset** and confirm.

Resetting a default setting removes the integration from all projects that have the integration set to use default settings.

### View projects that use custom settings

{{< details >}}

- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prerequisites:

- You must have administrator access to the instance.

To view projects in your instance that [use custom settings](../../user/project/integrations/_index.md#use-custom-settings-for-a-project-or-group-integration):

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Integrations**.
1. Select an integration.
1. Select the **Projects using custom settings** tab.

## Integration allowlist

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/500610) in GitLab 17.7.

{{< /history >}}

By default, project and group administrators can enable integrations.
However, instance administrators can configure an allowlist to control
which integrations can be enabled on a GitLab instance.

Enabled integrations that are later blocked by the allowlist settings are disabled.
If these integrations are allowed again, they are re-enabled with their existing configuration.

If you configure an empty allowlist, no integrations are allowed on the instance.
After you configure an allowlist, new GitLab integrations are not on the allowlist by default.

### Allow some integrations

Prerequisites:

- You must have administrator access to the instance.

To allow only integrations on the allowlist:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand the **Integration settings** section.
1. Select **Allow only integrations on this allowlist**.
1. Select the checkbox for each integration you want to allow on the instance.
1. Select **Save changes**.

### Allow all integrations

Prerequisites:

- You must have administrator access to the instance.

To allow all integrations on a GitLab instance:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand the **Integration settings** section.
1. Select **Allow all integrations**.
1. Select **Save changes**.
