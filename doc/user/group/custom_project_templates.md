---
type: reference
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Custom group-level project templates **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/6861) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.6.

Custom project templates are useful for organizations that need to create many similar types of [projects](../project/index.md) and want to start from the same jumping-off point.

## Setting up Group-level Project Templates

To use a custom project template for a new project you need to:

1. [Create a 'templates' subgroup](subgroups/index.md).
1. [Add repositories (projects) to the that new subgroup](index.md#add-projects-to-a-group), as your templates.
1. Edit your group's settings to look to your 'templates' subgroup for templates:
   1. In the left-hand menu, click **{settings}** **Settings > General**.

      NOTE: **Note:**
      If you don't have access to the group's settings, you may not have sufficient privileges (for example, you may need developer or higher permissions).

   1. Scroll to **Custom project templates** and click **Expand**. If no **Custom project templates** section displays, make sure you've created a subgroup, and added a project (repository) to it.
   1. Select the 'templates' subgroup.

### Example structure

Here is a sample group/project structure for a hypothetical "Acme Co" for project templates:

```txt
# GitLab instance and group
gitlab.com/acmeco/
    # Subgroups
    internal
    tools
    # Subgroup for handling project templates
    websites
        templates
            # Project templates
            client-site-django
            client-site-gatsby
            client-site-hTML

        # Other projects
        client-site-a
        client-site-b
        client-site-c
        ...
```

### Adjust Settings

Users can configure a GitLab group that serves as template
source under a group's **Settings > General > Custom project templates**.

NOTE: **Note:**
GitLab administrators can
[set project templates for an entire GitLab instance](../admin_area/custom_project_templates.md).

Within this section, you can configure the group where all the custom project
templates are sourced. Every project _template_ directly under the group namespace is
available to every signed-in user, if all enabled [project features](../project/settings/index.md#sharing-and-permissions) are set to **Everyone With Access**.

However, private projects will be available only if the user is a member of the project.

NOTE: **Note:**
Only direct subgroups can be set as the template source. Projects of nested subgroups of a selected template source cannot be used.

Repository and database information that are copied over to each new project are
identical to the data exported with [GitLab's Project Import/Export](../project/settings/import_export.md).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
