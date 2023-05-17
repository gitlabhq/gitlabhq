---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Custom instance-level project templates **(PREMIUM SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/6860) in GitLab 11.2.

GitLab administrators can set a group to be the source of project templates that are
selectable when a new project is created on the instance. These templates can be selected
when you go to **New project > Create from template** and select the **Instance** tab.

Every project in the group, but not its subgroups, can be selected when a new project
is created, based on the user's access permissions:

- Public projects can be selected by any authenticated user as a template for a new project,
  if all enabled [project features](../project/settings/index.md#configure-project-visibility-features-and-permissions)
  except for **GitLab Pages** and **Security and Compliance** are set to **Everyone With Access**.
  The same applies to internal projects.
- Private projects can be selected only by users who are members of the projects.

The **Metrics Dashboard** is set to **Only Project Members** when you create a new project. Make
sure you change it to **Everyone With Access** before making it a project template.

Repository and database information that are copied over to each new project are
identical to the data exported with the [GitLab Project Import/Export](../project/settings/import_export.md).

To set project templates at the group level, see [Custom group-level project templates](../group/custom_project_templates.md).

## Select instance-level project template group

To select the group to use as the source for the project templates:

1. On the top bar, navigate to **Main menu > Admin > Settings > Templates**.
1. Expand **Custom project templates**.
1. Select a group to use.
1. Select **Save changes**.

Projects in subgroups of the template group are **not** included in the template list.

## What is copied from the templates

The entire custom instance-level project templates repository is copied, including:

- Branches
- Commits
- Tags

If the user:

- Has the Owner role on the custom instance-level project templates project or is a GitLab administrator, all project settings are copied over to the new
  project.
- Doesn't have the Owner role or is not a GitLab administrator, project [deploy keys](../project/deploy_keys/index.md#view-deploy-keys) and project
  [webhooks](../project/integrations/webhooks.md) aren't copied over because they contain sensitive data.

To learn more about what is migrated, see
[Items that are exported](../project/settings/import_export.md#items-that-are-exported).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
