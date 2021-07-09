---
type: reference
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Custom group-level project templates **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/6861) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.6.

[Group owners](../permissions.md#group-members-permissions) can set a subgroup to
be the source of project templates that are selectable when a new project is created
in the group. These templates can be selected when you go to **New project > Create from template**
in the group and select the **Group** tab.

Every project in the subgroup, but not nested subgroups, can be selected by members
of the group when a new project is created.

Repository and database information that is copied over to each new project is identical to the
data exported with the [GitLab Project Import/Export](../project/settings/import_export.md).

To set custom project templates at the instance level, see [Custom instance-level project templates](../admin_area/custom_project_templates.md).

## Set up group-level project templates

To set up custom project templates in a group, add the subgroup that contains the
project templates to the group settings:

1. In the group, create a [subgroup](subgroups/index.md).
1. [Add projects to the new subgroup](index.md#add-projects-to-a-group) as your templates.
1. In the left menu for the group, go to **Settings > General**.
1. Expand **Custom project templates** and select the subgroup.

If all enabled [project features](../project/settings/index.md#sharing-and-permissions)
(except for GitLab Pages) are set to **Everyone With Access**, then every project
template in the subgroup is available to every member of the group.

Any projects added to the subgroup later can be selected the next time a group member
creates a new project.

### Example structure

Here's a sample group/project structure for project templates, for a hypothetical _Acme Co_:

```plaintext
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

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
