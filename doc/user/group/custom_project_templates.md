---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Custom group-level project templates

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/6861) in GitLab 11.6.

When you create a project, you can [choose from a list of templates](../project/index.md).
These templates, for things like GitLab Pages or Ruby, populate the new project with a copy of the files contained in the
template. This information is identical to the information used by [GitLab project import/export](../project/settings/import_export.md)
and can help you start a new project more quickly.

You can [customize the list](../project/index.md) of available templates, so
that all projects in your group have the same list. To do this, you populate a subgroup with the projects you want to
use as templates.

You can also configure [custom templates for the instance](../../administration/custom_project_templates.md).

## Set up group-level project templates

Prerequisites:

- You must have the Owner role for the group.

To set up custom project templates in a group, add the subgroup that contains the
project templates to the group settings:

1. In the group, create a [subgroup](subgroups/index.md).
1. [Add projects to the new subgroup](index.md#add-projects-to-a-group) as your templates.
1. In the left menu for the group, select **Settings > General**.
1. Expand **Custom project templates** and select the subgroup.

The next time a group member creates a project, they can select any of the projects in the subgroup.

Projects in nested subgroups are not included in the template list.

## Which projects are available as templates

- Public and internal projects can be selected by any authenticated user as a template for a new project,
  if all [project features](../project/settings/index.md#configure-project-features-and-permissions)
  except for **GitLab Pages** and **Security and Compliance** are set to **Everyone With Access**.
- Private projects can be selected only by users who are members of the projects.

## Example structure

Here's a sample group and project structure for project templates, for `myorganization`:

```plaintext
# GitLab instance and group
gitlab.com/myorganization/
    # Subgroups
    internal
    tools
    # Subgroup for handling project templates
    websites
        templates
            # Project templates
            client-site-django
            client-site-gatsby
            client-site-html

        # Other projects
        client-site-a
        client-site-b
        client-site-c
        ...
```

## What is copied from the templates

The entire custom instance-level project templates repository is copied, including:

- Branches
- Commits
- Tags

If the user:

- Has the Owner role on the custom instance-level project templates project or is a GitLab administrator,
  all project settings, including project members, are copied over to the new project.
- Doesn't have the Owner role or is not a GitLab administrator,
  project deploy keys and project webhooks aren't copied over because they contain sensitive data.

To learn more about what is migrated, see
[Items that are exported](../project/settings/import_export.md#project-items-that-are-exported).

## User assignments in templates

When you use a template created by another user, any items that were assigned
to a user in the template are reassigned to you. It's important to understand
this reassignment when you configure security features like protected branches
and tags. For example, if the template contains a protected branch:

- In the template, the branch allows the _template owner_ to merge into the default branch.
- In the project created from the template, the branch allows _you_ to merge into
  the default branch.

## Troubleshooting

### Administrator cannot see custom group-level project templates when creating a project

Custom group-level project templates are only available to group members.
If the administrator account you are using is not a member of a group,
you can't access the templates.
