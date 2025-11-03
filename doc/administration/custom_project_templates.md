---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
description: Configure project templates and make them available to all projects on your GitLab instance.
title: Custom project templates for your instance
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

To speed up the creation of projects on your instance, configure a group that contains template
projects. Users can then create
[new projects based on your templates](../user/project/_index.md#create-a-project-from-a-custom-template) that include the common tooling and configuration you specify.

To learn more about what data is copied from template projects, see
[what is copied from the templates](../user/group/custom_project_templates.md#what-is-copied-from-the-templates).

Before you make template projects available to your instance, select a group
to manage the templates. To prevent any unexpected changes to templates, create a new
group for this purpose, rather than reusing an existing group. If you reuse an
existing group created for a different purpose, users with the Maintainer role
might edit the template projects without understanding the side effects.

## Select a group to manage template projects

To select the group to manage the project templates for your instance:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **Templates**.
1. Expand **Custom project templates**.
1. Select a group to use.
1. Select **Save changes**.

After you configure the group as a source for project templates, new projects added to this group
become available as templates.

## Configure a project for use as a template

After you create a group to manage the template projects, configure the
visibility and feature availability of each template project.

Prerequisites:

- You must be either the administrator of the instance, or a user with a role
  that allows you to configure the project.

1. Ensure the project belongs to the group directly, and not through a subgroup.
   Projects from subgroups of the chosen group can't be used as templates.
1. To configure which users can select the project template, set the
   [project's visibility](../user/public_access.md#change-project-visibility):
   - **Public** and **Internal** projects can be selected by any authenticated user.
   - **Private** projects can be selected only by members of that project.
1. Review the project's
   [feature settings](../user/project/settings/_index.md#configure-project-features-and-permissions).
   All enabled project features should be set to **Everyone With Access**, except
   **GitLab Pages** and **Security and compliance**.

Repository and database information that are copied over to each new project are
identical to the data exported with the [GitLab Project Import/Export](../user/project/settings/import_export.md).

## Related topics

- [Custom project templates for groups](../user/group/custom_project_templates.md).
