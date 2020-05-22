---
type: reference
---

# Custom group-level project templates **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/6861) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.6.

When you create a new [project](../project/index.md), creating it based on custom project templates is
a convenient option.

Users can configure a GitLab group that serves as template
source under a group's **Settings > General > Custom project templates**.

NOTE: **Note:**
GitLab administrators can
[set project templates for an entire GitLab instance](../admin_area/custom_project_templates.md).

Within this section, you can configure the group where all the custom project
templates are sourced. Every project directly under the group namespace will be
available to the user if they have access to them. For example, every public
project in the group will be available to every logged in user.

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
