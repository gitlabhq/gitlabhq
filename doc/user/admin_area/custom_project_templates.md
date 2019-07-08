# Custom instance-level project templates **(PREMIUM ONLY)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/6860) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.2.

When you create a new [project](../project/index.md), creating it based on custom project templates is
a convenient bootstrap option.

GitLab administrators can configure a GitLab group that serves as template
source for an entire GitLab instance under **Admin area > Settings > Custom project templates**.

NOTE: **Note:**
To set project templates at a group level,
see [Custom group-level project templates](../group/custom_project_templates.md).

Within this section, you can configure the group where all the custom project
templates are sourced. Every project directly under the group namespace will be
available to the user if they have access to them. For example, every public
project in the group will be available to every logged in user.

However, private projects will be available only if the user is a member of the project.

NOTE: **Note:**
Projects below subgroups of the template group are **not** supported.

Repository and database information that are copied over to each new project are
identical to the data exported with [GitLab's Project Import/Export](../project/settings/import_export.md).
