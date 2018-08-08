## Custom project templates **[PREMIUM ONLY]**

> **Notes:**
> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/6860) in [GitLab Premium](https://about.gitlab.com/pricing) 11.2

When you create a new project, creating it based on custom project templates is
a convenient option to bootstrap from an existing project boilerplate.
The administration setting to configure a GitLab group that serves as template
source can be found under **Admin > Settings > Custom project templates**.

Within this section, you can configure the group where all the custom project
templates are sourced. Every project directly under the group namespace will be
available to the user if they have access to them. For example: Every public
project in the group will be available to every logged user. However,
private projects will be available only if the user has view [permissions](../permissions.md)
in the project:

- Project Owner, Maintainer, Developer, Reporter or Guest
- Is a member of the Group: Owner, Maintainer, Developer, Reporter or Guest

Projects below subgroups of the template group are **not** supported.

Repository and database information that are copied over to each new project are
 identical to the data exported with [GitLab's Project Import/Export](../project/settings/import_export.md).
