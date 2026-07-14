---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: Configure custom and built-in project templates for projects on your GitLab instance.
title: Project templates for your instance
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Project templates populate new projects with files and configuration. On your instance, you can
configure custom project templates from a group you manage, and control whether built-in project
templates are available to users.

## Custom project templates

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

### Select a group to manage template projects

Prerequisites:

- Administrator access.

To select the group to manage the project templates for your instance:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **Templates**.
1. Expand **Custom project templates**.
1. Select a group to use.
1. Select **Save changes**.

After you configure the group as a source for project templates, new projects added to this group
become available as templates.

### Configure a project for use as a template

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
identical to the data exported with GitLab project import and export.
This includes the full Git commit history from the template project.
For more information, see [migrate GitLab data by using file exports](../user/project/settings/import_export.md).

To create a template without commit history, initialize your template project with a single commit
that contains all the files you want to include.

## Built-in project templates

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230641) in GitLab 19.0 [with a feature flag](feature_flags/_index.md) named `use_built_in_project_templates_enabled`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/593623) in GitLab 19.2. Feature flag `use_built_in_project_templates_enabled` removed.

{{< /history >}}

[Built-in project templates](../user/project/_index.md#create-a-project-from-a-built-in-template)
populate new projects with starter files.
By default, these templates are available to all users.
As an administrator, you can turn off this setting for the instance, and optionally enforce it so
group Owners cannot override it.
Group Owners can also
[control this setting for their groups](../user/group/manage.md#control-built-in-project-templates).

The setting uses cascading inheritance:

- By default, root groups inherit the instance value.
- Subgroups inherit the value from their closest ancestor group.
- A group-specific value overrides the inherited value.
- When you enforce the setting for the instance, all groups inherit it.
- When you enforce the setting for a group, all subgroups inherit it.
- When you change the instance setting, the new value cascades to all groups.
- When you change a group setting, the new value cascades to all subgroups.

### Configure built-in project templates

Prerequisites:

- You must be an administrator.

To control built-in project templates for the instance:

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **Templates**.
1. Expand **Built-in project templates**.
1. Select or clear the **Enable built-in project templates** checkbox.
1. Optional. To prevent groups from changing this setting, select the **Enforce for all groups**
   checkbox.
1. Select **Save changes**.

## Related topics

- [Custom project templates for groups](../user/group/custom_project_templates.md).
