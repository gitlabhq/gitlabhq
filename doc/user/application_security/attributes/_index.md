---
stage: Security Governance
group: Security Controls
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Security attributes
description: Security attributes allows security teams to apply custom metadata labels to projects and groups, enabling them to filter and prioritize security risks based on business context.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/18010) in GitLab 18.5 with flags named `security_context_labels` and `security_categories_and_attributes`. Disabled by default. This feature was introduced in [beta](../../../policy/development_stages_support.md).
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/551226) in GitLab 18.6.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/588619) in GitLab 18.9. Feature flag `security_inventory_dashboard` removed.

{{< /history >}}

Security teams can now apply metadata specific to their own organization and business needs to projects using security attributes.

Security attributes are organized by categories based on:

- Business impact
- Application
- Business unit
- Internet exposure
- Location

By applying these attributes across your projects, you can much more quickly identify which projects require action based on your own organization's risk posture and business needs. With security attributes, you can:

- Identify projects that are mission critical and require stronger scan coverage.
- Review scan coverage for each application or business unit.
- Locate projects that contribute to publicly accessible and exposed applications.

Track the development of the security inventory in [epic 16939](https://gitlab.com/groups/gitlab-org/-/work_items/16939). Share [your feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/553062) as development continues on this feature.

## Manage security attributes for groups

You manage security attributes in the top-level group. The categories and attributes are
available to all subgroups and projects in the group.

Some default categories have restrictions:

- **Category locked**: You cannot edit or delete the category or its attributes.
- **Limited edits allowed**: You cannot delete the category, but you can edit its attributes.

### View categories for a group

View the categories and attributes that are available to projects in the group.

Prerequisites:

- The Security Manager, Maintainer, or Owner role for the top-level group.

To view categories for a group:

1. In the top bar, select **Search or go to** and find your top-level group.
1. In the left sidebar, select **Secure** > **Security configuration**.
1. Select the **Security attributes** tab.
1. Under **Categories**, select a category to view its attributes and the number of projects that use each one.

### Create a category

Create a category to group security attributes that are specific to your organization.

Prerequisites:

- The Security Manager, Maintainer, or Owner role for the top-level group.

To create a category:

1. In the top bar, select **Search or go to** and find your top-level group.
1. In the left sidebar, select **Secure** > **Security configuration**.
1. Select the **Security attributes** tab.
1. Next to **Categories**, select **Create category** ({{< icon name="plus" >}}).
1. In **Name**, enter a name.
1. Optional. In **Description**, enter a description.
1. Under **Selection type**, select one of the following options:
   - **Single selection**: Each project can have only one attribute from this category.
   - **Multiple selection**: Each project can have more than one attribute from this category.

   You cannot change the selection type after you create the category.
1. Add an attribute.
   1. In the **Attributes** section, select **Create attribute**.
   1. In the **Add security attribute** drawer, enter a **Name** and **Description**, and select a **Color**.
   1. Select **Add attribute**.
   1. Optional. Repeat this process to add additional attributes.
1. Select **Save changes**.

### Edit a category

Edit a category to rename it or change its attributes.

Prerequisites:

- The Security Manager, Maintainer, or Owner role for the top-level group.

To edit a category:

1. In the top bar, select **Search or go to** and find your top-level group.
1. In the left sidebar, select **Secure** > **Security configuration**.
1. Select the **Security attributes** tab.
1. Under **Categories**, select the category.
1. Edit the category:
   - To change the category, edit the **Name** or **Description**, then select **Save changes**.
     You cannot change the selection type.
   - To add an attribute, select **Create attribute**.
   - To edit an attribute, next to the attribute, select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Edit**.
   - To delete an attribute, next to the attribute, select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Delete**.
     This also removes the attribute from any projects that use it.

### Delete a category

Delete a category when you no longer need it.

> [!warning]
> When you delete a category, you also delete its attributes. Projects that use attributes from the
> category lose those attributes. You cannot undo this action.

Prerequisites:

- The Security Manager, Maintainer, or Owner role for the top-level group.

To delete a category:

1. In the top bar, select **Search or go to** and find your top-level group.
1. In the left sidebar, select **Secure** > **Security configuration**.
1. Select the **Security attributes** tab.
1. Under **Categories**, select the category.
1. Select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Delete**.
1. Select **Delete category**.

## Manage security attributes for projects

You apply security attributes to projects from the categories in the top-level group. You can
apply attributes to one project at a time, or to multiple projects from the security inventory.

For a category with **Single selection**, a project can have only one attribute from that category.

### View security attributes for a project

Prerequisites:

- The Security Manager, Developer, Maintainer, or Owner role for the project.

To view security attributes for a project:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Secure** > **Security configuration**.
1. Select the **Security attributes** tab.

The table shows the category and description of each attribute applied to the project.

### Edit security attributes for a project

Prerequisites:

- The Security Manager, Maintainer, or Owner role for the project.

To edit security attributes for a project:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Secure** > **Security configuration**.
1. Select the **Security attributes** tab.
1. Select **Edit project attributes**. If the project has no attributes, select **Add attributes**.
1. For each category, select the attributes to apply.
1. Select **Save changes**.

### Remove a security attribute from a project

Prerequisites:

- The Security Manager, Maintainer, or Owner role for the project.

To remove a security attribute from a project:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Secure** > **Security configuration**.
1. Select the **Security attributes** tab.
1. Next to the attribute, select **Remove attribute**.

### Edit security attributes for multiple projects

Prerequisites:

- The Security Manager, Maintainer, or Owner role for the top-level group.

To edit security attributes for multiple projects:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Secure** > **Security inventory**.
1. Select the checkbox next to each project.
1. Select **Select bulk action** > **Manage security attributes**.
1. Under **Update method**, select one of the following options:
   - **Add attributes**: Apply the selected attributes and keep existing attributes.
   - **Remove attributes**: Remove the selected attributes.
   - **Replace all attributes**: Remove all existing attributes and apply only the selected attributes.
1. Under **Attributes**, select the attributes.
1. Select **Save changes**.

## Related topics

- [Security inventory](../security_inventory/_index.md)
- [Security dashboard](../security_dashboard/_index.md)
- [Vulnerability reports](../vulnerability_report/_index.md)
