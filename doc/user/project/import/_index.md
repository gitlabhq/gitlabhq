---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Import and migrate to GitLab
description: Repository migration, third-party repositories, and user contribution mapping.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- All importers defaulting to disabled for GitLab Self-Managed instances [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118970) in GitLab 16.0.

{{< /history >}}

Bring your existing work into GitLab. You can migrate to GitLab from:

- Other GitLab instances or the same GitLab instance.
- Third-party source code management platforms.

| Migrate from                                                      | GitLab migration tool available? |
|:------------------------------------------------------------------|:---------------------------------|
| [Bitbucket Cloud](bitbucket.md)                                   | {{< yes >}}                      |
| [Bitbucket Server](bitbucket_server.md)                           | {{< yes >}}                      |
| [ClearCase](clearcase.md)                                         | {{< no >}}                       |
| [CVS](cvs.md)                                                     | {{< no >}}                       |
| [FogBugz](fogbugz.md)                                             | {{< yes >}}                      |
| [GitHub](github.md)                                               | {{< yes >}}                      |
| [GitLab (by using direct transfer)](../../group/import/_index.md) | {{< yes >}}                      |
| [GitLab (by using file export)](../settings/import_export.md)     | {{< yes >}}                      |
| [Gitea](gitea.md)                                                 | {{< yes >}}                      |
| Git repository through a [manifest file](manifest.md)             | {{< yes >}}                      |
| Git repository through a [repository URL](repo_by_url.md)         | {{< yes >}}                      |
| [Jira (issues only)](jira.md)                                     | {{< yes >}}                      |
| [Perforce Helix](perforce.md)                                     | {{< no >}}                       |
| [Team Foundation Version Control (TFVC)](tfvc.md)                 | {{< no >}}                       |

After you start a migration, you should not make any changes to imported groups or projects
on the source instance because these changes might not be copied to the destination instance.

## Import repositories from Subversion

GitLab cannot automatically migrate Subversion repositories to Git. Converting Subversion repositories to Git can be
difficult, but several tools exist including:

- [`git svn`](https://git-scm.com/book/en/v2/Git-and-Other-Systems-Migrating-to-Git), for very small and basic repositories.
- [`reposurgeon`](http://www.catb.org/~esr/reposurgeon/repository-editing.html), for larger and more complex repositories.

## View project import history

You can view all project imports created by you. This list includes the following:

- Paths of source projects if projects were imported from external systems, or import method if GitLab projects were migrated.
- Paths of destination projects.
- Start date of each import.
- Status of each import.
- Error details if any errors occurred.

To view project import history:

1. Sign in to GitLab.
1. On the left sidebar, at the top, select **Create new** ({{< icon name="plus" >}}) and **New project/repository**. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Import project**.
1. In the upper-right corner, select the **History** link.
1. If there are any errors for a particular import, select **Details** to see them.

The history also includes projects created from [built-in](../_index.md#create-a-project-from-a-built-in-template)
or [custom](../_index.md#create-a-project-from-a-custom-template)
templates. GitLab uses [import repository by URL](repo_by_url.md)
to create a new project from a template.

## Importing projects with LFS objects

When importing a project that contains LFS objects, if the project has an [`.lfsconfig`](https://github.com/git-lfs/git-lfs/blob/main/docs/man/git-lfs-config.adoc)
file with a URL host (`lfs.url`) different from the repository URL host, LFS files are not downloaded.

## Migrate by engaging Professional Services

If you prefer, you can engage GitLab Professional Services to migrate groups and projects to GitLab instead of doing it
yourself. For more information, see the [Professional Services Full Catalog](https://about.gitlab.com/services/catalog/).
