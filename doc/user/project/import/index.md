---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Import and migrate groups and projects

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

To bring existing projects to GitLab, or copy GitLab groups and projects to a different location, you can:

- Migrate GitLab groups and projects by using direct transfer.
- Import from supported import sources.
- Import from other import sources.

## Migrate from GitLab to GitLab by using direct transfer

The best way to copy GitLab groups and projects between GitLab instances, or in the same GitLab instance, is
[by using direct transfer](../../group/import/index.md).

Another option is to move GitLab groups using [group transfer](../../group/manage.md#transfer-a-group).

You can also copy GitLab projects by using a GitLab file export, which is a supported import source.

## Supported import sources

> - All importers default to disabled for GitLab self-managed installations. This change was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118970) in GitLab 16.0.

The import sources that are available to you by default depend on which GitLab you use:

- GitLab.com: all available import sources are [enabled by default](../../gitlab_com/index.md#default-import-sources).
- GitLab self-managed: no import sources are enabled by default and must be
  [enabled](../../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources).

GitLab can import projects from these supported import sources.

| Import source                                 | Description |
|:----------------------------------------------|:------------|
| [Bitbucket Cloud](bitbucket.md)               | Using [Bitbucket.org as an OmniAuth provider](../../../integration/bitbucket.md), import Bitbucket repositories. |
| [Bitbucket Server](bitbucket_server.md)       | Import repositories from Bitbucket Server (also known as Stash). |
| [FogBugz](fogbugz.md)                         | Import FogBugz projects. |
| [Gitea](gitea.md)                             | Import Gitea projects. |
| [GitHub](github.md)                           | Import from either GitHub.com or GitHub Enterprise. |
| [GitLab export](../settings/import_export.md) | Migrate projects one by one by using a GitLab export file. |
| [Manifest file](manifest.md)                  | Upload a manifest file. |
| [Repository by URL](repo_by_url.md)           | Provide a Git repository URL to create a new project from. |

### Disable unused import sources

Only import projects from sources you trust. If you import a project from an untrusted source,
an attacker could steal your sensitive data. For example, an imported project
with a malicious `.gitlab-ci.yml` file could allow an attacker to exfiltrate group CI/CD variables.

GitLab self-managed administrators can reduce their attack surface by disabling import sources they don't need:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > General**.
1. Expand **Visibility and access controls**.
1. Scroll to **Import sources**.
1. Clear checkboxes for importers that are not required.

## Other import sources

You can also read information on importing from these other import sources:

- [ClearCase](clearcase.md)
- [Concurrent Versions System (CVS)](cvs.md)
- [Jira (issues only)](jira.md)
- [Perforce Helix](perforce.md)
- [Team Foundation Version Control (TFVC)](tfvc.md)

### Import repositories from Subversion

GitLab can not automatically migrate Subversion repositories to Git. Converting Subversion repositories to Git can be
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
1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Import project**.
1. In the upper-right corner, select the **History** link.
1. If there are any errors for a particular import, select **Details** to see them.

The history also includes projects created from [built-in](../index.md#create-a-project-from-a-built-in-template)
or [custom](../index.md#create-a-project-from-a-built-in-template)
templates. GitLab uses [import repository by URL](repo_by_url.md)
to create a new project from a template.

## Importing projects with LFS objects

When importing a project that contains LFS objects, if the project has an [`.lfsconfig`](https://github.com/git-lfs/git-lfs/blob/main/docs/man/git-lfs-config.adoc)
file with a URL host (`lfs.url`) different from the repository URL host, LFS files are not downloaded.

## Migrate by engaging Professional Services

If you prefer, you can engage GitLab Professional Services to migrate groups and projects to GitLab instead of doing it
yourself. For more information, see the [Professional Services Full Catalog](https://about.gitlab.com/services/catalog/).

## Troubleshooting

### Imported repository is missing branches

If an imported repository does not contain all branches of the source repository:

1. Set the [environment variable](../../../administration/logs/index.md#override-default-log-level) `IMPORT_DEBUG=true`.
1. Retry the import with a [different group, subgroup, or project name](https://about.gitlab.com/releases/2023/02/22/gitlab-15-9-released/#re-import-projects-from-external-providers).
1. If some branches are still missing, inspect [`importer.log`](../../../administration/logs/index.md#importerlog)
   (for example, with [`jq`](../../../administration/logs/log_parsing.md#parsing-gitlab-railsimporterlog)).
