# Custom group-level project templates **[PREMIUM ONLY]**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/6861) in [GitLab Premium](https://about.gitlab.com/pricing) 11.6.

When you create a new project, creating it based on custom project templates is
a convenient option to bootstrap from an existing project boilerplate.
The group-level setting to configure a GitLab group that serves as template
source can be found under **Group > Settings > General > Custom project templates**.

Within this section, you can configure the group where all the custom project
templates are sourced. Every project directly under the group namespace will be
available to the user if they have access to them. For example, every public
project in the group will be available to every logged in user. However,
private projects will be available only if the user has view [permissions](../permissions.md)
in the project. That is, users with Owner, Maintainer, Developer, Reporter or Guest roles for projects,
or for groups to which the project belongs.

Projects of nested subgroups of a selected template source cannot be used.

Repository and database information that are copied over to each new project are
identical to the data exported with [GitLab's Project Import/Export](../project/settings/import_export.md).

If you would like to set project templates at an instance level, please see [Custom instance-level project templates](../admin_area/custom_project_templates.md).