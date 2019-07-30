---
type: howto
---

# Creating projects

Most work in GitLab is done within a [Project](../user/project/index.md). Files and
code are saved in projects, and most features are used within the scope of projects.

## Create a project in GitLab

To create a project in GitLab:

1. In your dashboard, click the green **New project** button or use the plus
   icon in the navigation bar. This opens the **New project** page.
1. On the **New project** page, choose if you want to:
   - Create a [blank project](#blank-projects).
   - Create a project using with one of the available [project templates](#project-templates).
   - [Import a project](../user/project/import/index.md) from a different repository,
     if enabled on your GitLab instance. Contact your GitLab admin if this is unavailable.
   - Run [CI/CD pipelines for external repositories](../ci/ci_cd_for_external_repos/index.md). **(PREMIUM)**

NOTE: **Note:**
For a list of words that cannot be used as project names see
[Reserved project and group names](../user/reserved_names.md).

### Blank projects

To create a new blank project on the **New project** page:

1. On the **Blank project** tab, provide the following information:
   - The name of your project in the **Project name** field. You can't use
     special characters, but you can use spaces, hyphens, underscores or even
     emoji.
   - The **Project description (optional)** field enables you to enter a
     description for your project's dashboard, which will help others
     understand what your project is about. Though it's not required, it's a good
     idea to fill this in.
   - Changing the **Visibility Level** modifies the project's
     [viewing and access rights](../public_access/public_access.md) for users.
   - Selecting the **Initialize repository with a README** option creates a
     README file so that the Git repository is initialized, has a default branch, and
     can be cloned.
1. Click **Create project**.

### Project templates

Project templates can pre-populate a new project with the necessary files to get you
started quickly.

There are two types of project templates:

- [Built-in templates](#built-in-templates), sourced from the following groups:
  - [`project-templates`](https://gitlab.com/gitlab-org/project-templates)
  - [`pages`](https://gitlab.com/pages)
- [Custom project templates](#custom-project-templates-premium-only), for custom templates
  configured by GitLab administrators and users.

#### Built-in templates

Built-in templates are project templates that are:

- Developed and maintained in the [`project-templates`](https://gitlab.com/gitlab-org/project-templates)
  and [`pages`](https://gitlab.com/pages) groups.
- Released with GitLab.

To use a built-in template on the **New project** page:

1. On the **Create from template** tab, select the **Built-in** tab.
1. From the list of available built-in templates, click the:
   - **Preview** button to look at the template source itself.
   - **Use template** button to start creating the project.
1. Finish creating the project by filling out the project's details. The process is
   the same as creating a [blank project](#blank-projects).

TIP: **Tip:**
You can improve the existing built-in templates or contribute new ones in the
[`project-templates`](https://gitlab.com/gitlab-org/project-templates) and
[`pages`](https://gitlab.com/pages) groups.

#### Custom project templates **(PREMIUM ONLY)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/6860) in
[GitLab Premium](https://about.gitlab.com/pricing) 11.2.

Creating new projects based on custom project templates is a convenient option to
bootstrap a project.

Custom projects are available at the [instance-level](../user/admin_area/custom_project_templates.md)
from the **Instance** tab, or at the [group-level](../user/group/custom_project_templates.md)
from the **Group** tab, under the **Create from template** tab.

To use a custom project template on the **New project** page:

1. On the **Create from template** tab, select the **Instance** tab or the **Group** tab.
1. From the list of available custom templates, click the:
   - **Preview** button to look at the template source itself.
   - **Use template** button to start creating the project.
1. Finish creating the project by filling out the project's details. The process is
   the same as creating a [blank project](#blank-projects).

## Push to create a new project

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/26388) in GitLab 10.5.

When you create a new repository locally, instead of going to GitLab to manually
create a new project and then [clone the repo](start-using-git.md#clone-a-repository)
locally, you can directly push it to GitLab to create the new project, all without leaving
your terminal. If you have access rights to the associated namespace, GitLab will
automatically create a new project under that GitLab namespace with its visibility
set to Private by default (you can later change it in the [project's settings](../public_access/public_access.md#how-to-change-project-visibility)).

This can be done by using either SSH or HTTPS:

```sh
## Git push using SSH
git push --set-upstream git@gitlab.example.com:namespace/nonexistent-project.git master

## Git push using HTTPS
git push --set-upstream https://gitlab.example.com/namespace/nonexistent-project.git master
```

Once the push finishes successfully, a remote message will indicate
the command to set the remote and the URL to the new project:

```text
remote:
remote: The private project namespace/nonexistent-project was created.
remote:
remote: To configure the remote, run:
remote:   git remote add origin https://gitlab.example.com/namespace/nonexistent-project.git
remote:
remote: To view the project, visit:
remote:   https://gitlab.example.com/namespace/nonexistent-project
remote:
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
