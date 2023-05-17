---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Custom group-level project templates **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/6861) in GitLab 11.6.

When you create a project, you can [choose from a list of templates](../project/index.md#create-a-project).
These templates, for things like GitLab Pages or Ruby, populate the new project with a copy of the files contained in the
template. This information is identical to the information used by [GitLab project import/export](../project/settings/import_export.md)
and can help you start a new project more quickly.

You can [customize the list](../project/index.md#create-a-project) of available templates, so
that all projects in your group have the same list. To do this, you populate a subgroup with the projects you want to
use as templates.

You can also configure [custom templates for the instance](../admin_area/custom_project_templates.md).

## Set up group-level project templates

Prerequisite:

- You must have the Owner role for the group.

To set up custom project templates in a group, add the subgroup that contains the
project templates to the group settings:

1. In the group, create a [subgroup](subgroups/index.md).
1. [Add projects to the new subgroup](manage.md#add-projects-to-a-group) as your templates.
1. In the left menu for the group, select **Settings > General**.
1. Expand **Custom project templates** and select the subgroup.

The next time a group member creates a project, they can select any of the projects in the subgroup.

Projects in nested subgroups are not included in the template list.

## Which projects are available as templates

- Public and internal projects can be selected by any authenticated user as a template for a new project,
  if all [project features](../project/settings/index.md#configure-project-visibility-features-and-permissions)
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

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
