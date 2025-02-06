---
stage: Tenant Scale
group: Organizations
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Create a project
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You have different options to create a project. You can create a blank project, create a project
from built-in or custom templates, or [create a project with `git push`](../../topics/git/project.md).

## Create a blank project

To create a blank project:

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Create blank project**.
1. Enter the project details:
   1. **Project name**: Enter the name of your project.
   For more information, see [naming rules](../reserved_names.md#rules-for-usernames-project-and-group-names-and-slugs).
   1. **Project slug**: Enter the path to your project. GitLab uses the slug as the URL path.
   1. **Project deployment target (optional)**: If you want to deploy your project to specific environment,
   select the relevant deployment target.
   1. **Visibility Level**: Select the appropriate visibility level.
   See the [viewing and access rights](../public_access.md) for users.
   1. **Initialize repository with a README**: Select this option to initialize the Git repository,
   create a default branch, and enable cloning of this project's repository.
   1. **Enable Static Application Security Testing (SAST)**: Select this option to analyze the
   source code for known security vulnerabilities.
1. Select **Create project**.

## Create a project from a built-in template

Built-in templates populate a new project with files to help you get started.
These templates are sourced from the [`project-templates`](https://gitlab.com/gitlab-org/project-templates)
and [`pages`](https://gitlab.com/pages) groups.
Anyone can [contribute to built-in project templates](../../development/project_templates.md).

To create a project from a built-in template:

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Create from template**.
1. Select the **Built-in** tab.
1. From the list of templates:
   - To preview a template, select **Preview**.
   - To use a template, select **Use template**.
1. Enter the project details:
   - **Project name**: Enter the name of your project.
   - **Project slug**: Enter the path to your project. GitLab uses the slug as the URL path.
   - **Project description (optional)** Enter a description for your project.
   The character limit is 500.
   - **Visibility Level**: Select the appropriate visibility level.
   See the [viewing and access rights](../public_access.md) for users.
1. Select **Create project**.

NOTE:
If a user creates a project from a template, or [imports a project](settings/import_export.md#import-a-project-and-its-data),
they are shown as the author of the imported items, which retain the original timestamp from the template or import.
This can make items appear as if they were created before the user's account existed.

Imported objects are labeled as `By <username> on <timestamp>`.
Before GitLab 17.1, the label was suffixed with `(imported from GitLab)`.

### Create a project from the HIPAA Audit Protocol template

The HIPAA Audit Protocol template contains issues for audit inquiries in the
HIPAA Audit Protocol published by the U.S Department of Health and Human Services.

To create a project from the HIPAA Audit Protocol template:

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Create from template**.
1. Select the **Built-in** tab.
1. Locate the **HIPAA Audit Protocol** template:
   - To preview the template, select **Preview**.
   - To use the template, select **Use template**.
1. Enter the project details:
   - **Project name**: Enter the name of your project.
   - **Project slug**: Enter the path to your project. GitLab uses the slug as the URL path.
   - **Project description (optional)** Enter a description for your project.
   The character limit is 500.
   - **Visibility Level**: Select the appropriate visibility level.
   See the [viewing and access rights](../public_access.md) for users.
1. Select **Create project**.

## Create a project from a custom template

Custom project templates are available for your [instance](../../administration/custom_project_templates.md)
and [group](../group/custom_project_templates.md).

To create a project from a custom template:

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Create from template**.
1. Select the **Instance** or **Group** tab.
1. From the list of templates:
   - To preview the template, select **Preview**.
   - To use a template, select **Use template**.
1. Enter the project details:
   - **Project name**: Enter the name of your project.
   - **Project slug**: Enter the path to your project. GitLab uses the slug as the URL path.
   - **Project description (optional)** Enter a description for your project. The character limit is 500.
   - **Visibility Level**: Select the appropriate visibility level.
   See the [viewing and access rights](../public_access.md) for users.
1. Select **Create project**.

## Create a project that uses SHA-256 hashing

DETAILS:
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/431864) in GitLab 16.7 [with a flag](../../administration/feature_flags.md) named `support_sha256_repositories`. Disabled by default. This feature is an [experiment](../../policy/development_stages_support.md#experiment).

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

You can select SHA-256 hashing for a project only when you create the project.
Git does not support migrating to SHA-256 later, or migrating back to SHA-1.

To create a project that uses SHA-256 hashing:

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Enter the project details:
   - **Project name**: Enter the name of your project.
   - **Project slug**: Enter the path to your project. GitLab uses the slug as the URL path.
   - **Project description (optional)** Enter a description for your project. The character limit is 500.
   - **Visibility Level**: Select the appropriate visibility level.
   See the [viewing and access rights](../public_access.md) for users.
1. In the **Project Configuration** area, expand the **Experimental settings**.
1. Select **Use SHA-256 as the repository hashing algorithm**.
1. Select **Create project**.

### Why SHA-256?

By default, Git uses the SHA-1 [hashing algorithm](https://handbook.gitlab.com/handbook/security/cryptographic-standard/#algorithmic-standards)
to generate a 40-character
ID for objects such as commits, blobs, trees, and tags. The SHA-1 algorithm was proven to be insecure when
[Google was able to produce a hash collision](https://security.googleblog.com/2017/02/announcing-first-sha1-collision.html).
The Git project is not yet impacted by these
kinds of attacks because of the way Git stores objects.

In SHA-256 repositories, the algorithm generates a 64-character ID instead of a 40-character ID.
The Git project determined that the SHA-256 feature is safe to use when they
[removed the experimental label](https://github.com/git/git/blob/master/Documentation/RelNotes/2.42.0.txt#L41-L45).

Federal regulations, such as NIST and CISA [guidelines](https://csrc.nist.gov/projects/hash-functions/nist-policy-on-hash-functions),
which [FedRamp](https://www.fedramp.gov/) enforces, have set a due date in 2030 to stop using SHA-1 and
encourage agencies to move away from SHA-1 earlier, if possible.

## Related topics

- [Create a project with `git push`](../../topics/git/project.md)
- [Reserved project and group names](../reserved_names.md)
- [Rules for project and group names](../reserved_names.md#rules-for-usernames-project-and-group-names-and-slugs)
- [Manage projects](working_with_projects.md)
