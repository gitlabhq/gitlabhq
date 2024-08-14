---
stage: Data Stores
group: Tenant Scale
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Create a project

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

You can create a project in many ways in GitLab.

## Create a blank project

To create a blank project:

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Create blank project**.
1. Enter the project details:
   - In the **Project name** field, enter the name of your project. See the [limitations on project names](../../user/reserved_names.md).
   - In the **Project slug** field, enter the path to your project. The GitLab instance uses the
     slug as the URL path to the project. To change the slug, first enter the project name,
     then change the slug.
   - In the **Project deployment target (optional)** field, select your project's deployment target.
     This information helps GitLab better understand its users and their deployment requirements.
   - To modify the project's [viewing and access rights](../public_access.md) for
     users, change the **Visibility Level**.
   - To create README file so that the Git repository is initialized, has a default branch, and
     can be cloned, select **Initialize repository with a README**.
   - To analyze the source code in the project for known security vulnerabilities,
     select **Enable Static Application Security Testing (SAST)**.
1. Select **Create project**.

## Create a project from a built-in template

A built-in project template populates a new project with files to get you started.
Built-in templates are sourced from the following groups:

- [`project-templates`](https://gitlab.com/gitlab-org/project-templates)
- [`pages`](https://gitlab.com/pages)

Anyone can [contribute a built-in template](../../development/project_templates.md).

To create a project from a built-in template:

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Create from template**.
1. Select the **Built-in** tab.
1. From the list of templates:
   - To view a preview of the template, select **Preview**.
   - To use a template for the project, select **Use template**.
1. Enter the project details:
   - In the **Project name** field, enter the name of your project. The name must start with a lowercase or uppercase letter (`a-zA-Z`), digit (`0-9`), emoji, or underscore (`_`). It can also contain dots (`.`), pluses (`+`), dashes (`-`), or spaces.
   - In the **Project slug** field, enter the path to your project. The GitLab instance uses the
     slug as the URL path to the project. To change the slug, first enter the project name,
     then change the slug.
   - In the **Project description (optional)** field, enter the description of your project's dashboard. The description is limited to 500 characters.
   - To modify the project's [viewing and access rights](../public_access.md) for users,
     change the **Visibility Level**.
1. Select **Create project**.

Users who create projects [from a template](#create-a-project-from-a-built-in-template) or [by importing them](settings/import_export.md#import-a-project-and-its-data) are
displayed as the author of the imported items, which keep the original timestamp from the template or import. For this reason, the creation date of imported items can be
older than the creation date of the user's account. This can make items appear to have been created by a user before they even had an account.

Imported objects are labeled as `By <username> on <timestamp>`. Before GitLab 17.1, the label was suffixed with `(imported from GitLab)`.

## Create a project from a custom template

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Custom project templates are available at:

- The [instance-level](../../administration/custom_project_templates.md)
- The [group-level](../../user/group/custom_project_templates.md)

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Create from template**.
1. Select the **Instance** or **Group** tab.
1. From the list of templates:
   - To view a preview of the template, select **Preview**.
   - To use a template for the project, select **Use template**.
1. Enter the project details:
   - In the **Project name** field, enter the name of your project. The name must start with a lowercase or uppercase letter (`a-zA-Z`), digit (`0-9`), emoji, or underscore (`_`). It can also contain dots (`.`), pluses (`+`), dashes (`-`), or spaces.
   - In the **Project slug** field, enter the path to your project. The GitLab instance uses the
     slug as the URL path to the project. To change the slug, first enter the project name,
     then change the slug.
   - The description of your project's dashboard in the **Project description (optional)** field. The description is limited to 500 characters.
   - To modify the project's [viewing and access rights](../public_access.md) for users,
     change the **Visibility Level**.
1. Select **Create project**.

## Create a project from the HIPAA Audit Protocol template

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

The HIPAA Audit Protocol template contains issues for audit inquiries in the
HIPAA Audit Protocol published by the U.S Department of Health and Human Services.

To create a project from the HIPAA Audit Protocol template:

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Create from template**.
1. Select the **Built-in** tab.
1. Locate the **HIPAA Audit Protocol** template:
   - To view a preview of the template, select **Preview**.
   - To use the template for the project, select **Use template**.
1. Enter the project details:
   - In the **Project name** field, enter the name of your project. The name must start with a lowercase or uppercase letter (`a-zA-Z`), digit (`0-9`), emoji, or underscore (`_`). It can also contain dots (`.`), pluses (`+`), dashes (`-`), or spaces.
   - In the **Project slug** field, enter the path to your project. The GitLab instance uses the
     slug as the URL path to the project. To change the slug, first enter the project name,
     then change the slug.
   - In the **Project description (optional)** field, enter the description of your project's dashboard. The description is limited to 500 characters.
   - To modify the project's [viewing and access rights](../public_access.md) for users,
     change the **Visibility Level**.
1. Select **Create project**.

## Create a new project with Git push

Use `git push` to push a local project repository to GitLab. After you push a repository,
GitLab creates your project in your chosen namespace.

You cannot use `git push` to create projects with project paths that:

- Have previously been used.
- Have been [renamed](working_with_projects.md#rename-a-repository).

Previously used project paths have a redirect. The redirect causes push attempts to redirect requests
to the renamed project location, instead of creating a new project. To create a new project for a previously
used or renamed project, use the UI or the [Projects API](../../api/projects.md#create-project).

Prerequisites:

- To push with SSH, you must have [an SSH key](../ssh.md) that is
  [added to your GitLab account](../ssh.md#add-an-ssh-key-to-your-gitlab-account).
- You must have permission to add new projects to a namespace. To check if you have permission:

  1. On the left sidebar, select **Search or go to** and find your group.
  1. In the upper-right corner, confirm that **New project** is visible.
     Contact your GitLab administrator if you require permission.

To push your repository and create a project:

1. Push with SSH or HTTPS:
   - To push with SSH:

     ```shell
     # Use this version if your project uses the standard port 22
     $ git push --set-upstream git@gitlab.example.com:namespace/myproject.git main

     # Use this version if your project requires a non-standard port number
     $ git push --set-upstream ssh://git@gitlab.example.com:00/namespace/myproject.git main
     ```

   - To push with HTTPS:

     ```shell
     git push --set-upstream https://gitlab.example.com/namespace/myproject.git master
     ```

   - For `gitlab.example.com`, use the domain name of the machine that hosts your Git repository.
   - For `namespace`, use the name of your [namespace](../namespace/index.md).
   - For `myproject`, use the name of your project.
   - If specifying a port, change `00` to your project's required port number.
   - Optional. To export existing repository tags, append the `--tags` flag to your `git push` command.
1. Optional. To configure the remote:

   ```shell
   git remote add origin https://gitlab.example.com/namespace/myproject.git
   ```

When the push completes, GitLab displays the message:

```shell
remote: The private project namespace/myproject was created.
```

To view your new project, go to `https://gitlab.example.com/namespace/myproject`.
Your project's visibility is set to **Private** by default. To change project visibility, adjust your
[project's settings](../public_access.md#change-project-visibility).

## Create a project that uses SHA-256 hashing

DETAILS:
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/794) in GitLab 16.9. This feature is an [experiment](../../policy/experiment-beta-support.md#experiment).

FLAG:
On self-managed GitLab, by default this feature is not available.
To make it available, an administrator can enable the [feature flag](../../administration/feature_flags.md) named `support_sha256_repositories`.

You can select SHA-256 hashing for a project only when you create the project.

To create a project that uses SHA-256 hashing:

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Create blank project** and fill out the project's details as usual. For more information on project details, see [Create a blank project](#create-a-blank-project).
1. In the **Project Configuration** area, click on **Experimental settings** to
   expand the accordion.
1. Select **Use SHA-256 as the repository hashing algorithm**.
1. Select **Create project**.

WARNING:
Git does not support migrating to SHA-256 later, or migrating back to SHA-1.

### Why SHA-256?

By default, Git uses the SHA-1 [hashing algorithm](https://handbook.gitlab.com/handbook/security/cryptographic-standard/#algorithmic-standards) to generate a 40-character
ID for objects such as commits, blobs, trees, and tags. The SHA-1 algorithm was proven to be insecure when
[Google was able to produce a hash collision](https://security.googleblog.com/2017/02/announcing-first-sha1-collision.html). The Git project is not yet impacted by these
kinds of attacks because of the way Git stores objects. However, it is only a matter of time until new attacks on SHA-1 are found that impact Git.

In SHA-256 repositories, the algorithm generates a 64-character ID instead of a 40-character ID. The Git project determined that the SHA-256 feature is safe to use when they [removed the experimental label](https://github.com/git/git/blob/master/Documentation/RelNotes/2.42.0.txt#L41-L45).

Federal regulations, such as NIST and CISA [guidelines](https://csrc.nist.gov/projects/hash-functions/nist-policy-on-hash-functions) (which
[FedRamp](https://www.fedramp.gov/) enforces), have set a due date in 2030 to stop using SHA-1 and encourage agencies using SHA-1 to move away from it sooner, if possible.

## Related topics

- [Reserved project and group names](../../user/reserved_names.md)
- [Limitations on project and group names](../../user/reserved_names.md#limitations-on-usernames-project-and-group-names-and-slugs)
- [Manage projects](working_with_projects.md)
