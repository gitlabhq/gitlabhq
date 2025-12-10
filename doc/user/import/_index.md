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

Bring your existing work into GitLab.

A migration tool is available for some third-party platforms. Some support
[user contribution and membership mapping](mapping.md).

| Migrate from                                                                | Groups                  | Projects    | Migration tool | Automatic mapping |
|:----------------------------------------------------------------------------|:------------------------|:------------|:---------------|:------------------|
| [GitLab (by using direct transfer)](../group/import/_index.md)              | {{< yes >}}             | {{< yes >}} | {{< yes >}}    | {{< yes >}}       |
| [GitLab (by using file export)](../project/settings/import_export.md)       | {{< yes >}}<sup>1</sup> | {{< yes >}} | {{< yes >}}    | {{< no >}}        |
| [Bitbucket Server](../project/import/bitbucket_server.md)                   | {{< no >}}              | {{< yes >}} | {{< yes >}}    | {{< yes >}}       |
| [GitHub](../project/import/github.md)                                       | {{< no >}}              | {{< yes >}} | {{< yes >}}    | {{< yes >}}       |
| [Gitea](../project/import/gitea.md)                                         | {{< no >}}              | {{< yes >}} | {{< yes >}}    | {{< yes >}}       |
| [Bitbucket Cloud](bitbucket_cloud.md)                                       | {{< no >}}              | {{< yes >}} | {{< yes >}}    | {{< no >}}        |
| [FogBugz](../project/import/fogbugz.md)                                     | {{< no >}}              | {{< yes >}} | {{< yes >}}    | {{< no >}}        |
| Git repository through a [manifest file](../project/import/manifest.md)     | {{< no >}}              | {{< yes >}} | {{< yes >}}    | {{< no >}}        |
| Git repository through a [repository URL](../project/import/repo_by_url.md) | {{< no >}}              | {{< yes >}} | {{< yes >}}    | {{< no >}}        |
| [ClearCase](../project/import/clearcase.md)                                 | {{< no >}}              | {{< yes >}} | {{< no >}}     | {{< no >}}        |
| [CVS](../project/import/cvs.md)                                             | {{< no >}}              | {{< yes >}} | {{< no >}}     | {{< no >}}        |
| [Perforce Helix](../project/import/perforce.md)                             | {{< no >}}              | {{< yes >}} | {{< no >}}     | {{< no >}}        |
| [Subversion](#migrate-from-subversion)                                      | {{< no >}}              | {{< yes >}} | {{< no >}}     | {{< no >}}        |
| [Team Foundation Version Control (TFVC)](../project/import/tfvc.md)         | {{< no >}}              | {{< yes >}} | {{< no >}}     | {{< no >}}        |
| [Jira (issues only)](../project/import/jira.md)                             | {{< no >}}              | {{< no >}}  | {{< yes >}}    | {{< no >}}        |

**Footnotes**:

1. Using file exports for group migration is deprecated.

## Migrate from Subversion

GitLab cannot automatically migrate Subversion repositories to Git. To convert Subversion repositories to Git,
you can use external tools, for example:

- [`git svn`](https://git-scm.com/book/en/v2/Git-and-Other-Systems-Migrating-to-Git), for very small and basic repositories.
- [`reposurgeon`](http://www.catb.org/~esr/reposurgeon/repository-editing.html), for larger and more complex repositories.

## Migrate by engaging Professional Services

If you prefer, you can engage GitLab Professional Services to migrate groups and projects to GitLab instead of doing it
yourself. For more information, see the [Professional Services Full Catalog](https://about.gitlab.com/services/catalog/).

## View project import history

You can view all project imports you created. This list includes:

- Paths of source projects if projects were imported from external systems, or import method if GitLab projects were
  migrated.
- Paths of destination projects.
- Start date of each import.
- Status of each import.
- Error details if any errors occurred.

The history also includes projects created from either:

- [Built-in](../project/_index.md#create-a-project-from-a-built-in-template) templates.
- [Custom](../project/_index.md#create-a-project-from-a-custom-template) templates.

GitLab uses [import repository by URL](../project/import/repo_by_url.md) to create a new project from a template.

To view project import history:

1. In the upper-right corner, select **Create new** ({{< icon name="plus" >}}) and **New project/repository**.
1. Select **Import project**.
1. In the upper-right corner, select the **History** link.
1. If there are any errors for a particular import, select **Details** to see them.

## Importing projects with LFS objects

When importing a project that contains LFS objects, if the project has an [`.lfsconfig`](https://github.com/git-lfs/git-lfs/blob/main/docs/man/git-lfs-config.adoc)
file with a URL host (`lfs.url`) different from the repository URL host, LFS files are not downloaded.

## Related topics

- [Moving repositories managed by GitLab](../../administration/operations/moving_repositories.md).
