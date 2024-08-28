---
stage: Foundations
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

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Import and export settings**.
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

## User contribution and membership mapping

DETAILS:
**Status:** Experiment

> - [Introduced to migration by using direct transfer](https://gitlab.com/gitlab-org/gitlab/-/issues/443557) in GitLab 17.4 [with flags](../../../administration/feature_flags.md) named `importer_user_mapping` and `bulk_import_importer_user_mapping`. Disabled by default. This feature is an [experiment](../../../policy/experiment-beta-support.md).

FLAG:
The availability of this feature is controlled by feature flags.
For more information, see the history.
This feature is available for internal testing only, it is not ready for production use.

With user contribution and membership mapping, you can assign imported contributions and memberships to users on the
destination instance after import has completed. Unlike the previous method of user contribution and membership mapping,
no preparation is needed before the import.

The process doesn't rely on email addresses, so you can map contributions for users who have different emails on source
and destination instances.

NOTE:
This new method of user contribution and membership method is only supported for
[migrations by using direct transfer](../../group/import/index.md). For information on the other method of user
contribution and membership mapping for direct transfer migrations, see
[User contributions and membership mapping](../../group/import/direct_transfer_migrations.md#user-contributions-and-membership-mapping).

Each user on the destination instance that is assigned a mapping can:

- [Explicitly accept](#accept-contribution-reassignment) the assignment before any imported contributions are
  attributed to them.
- Reject the assignment.

This feature is an [experiment](../../../policy/experiment-beta-support.md). If you find a bug, open an issue in
[epic 12378](https://gitlab.com/groups/gitlab-org/-/epics/12378).

### Requirements

- You must be able to create enough users, subject to [user limits](#placeholder-user-limits).
- If importing to GitLab.com, you must set up your paid namespace before the import.

### Placeholder users

Instead of immediately attempting to assign contributions to users on the destination instance, a
placeholder user is created for:

- Each imported membership.
- Any user whose contributions were imported.

Both contributions and memberships are first assigned to these placeholder users and can be reassigned after import
to existing users on destination instance.

#### Placeholder user attributes

Placeholder users are different to regular users and cannot:

- Sign in.
- Perform any actions. For example, running pipelines.
- Appear in suggestions as assignees or reviewers for issues and merge requests.
- Be members of projects and groups.

To maintain a connection with a user on a source instance, placeholder users have:

- A unique identifier (`source_user_id`) used by the import process to determine if a new placeholder user is required.
- A source hostname or domain (`source_hostname`).
- A source user's name (`source_name`) to help with reassignment of contributions.
- A source user's username (`source_username`) to facilitate group owners during the reassignment of the contribution.
- An import type (`import_type`) to distinguish which importer created the placeholder.

To preserve historical context, the placeholder user name and username are derived from the source user name and username:

- Placeholder user's name is `Placeholder <source user name>`.
- Placeholder user's username is `%{source_username}_placeholder_user_%{incremental_number}`.

#### View placeholder users

Prerequisites:

- You must have the Owner role of the group.

Placeholder users are created in the top-level group on the destination instance where a group or project are imported
to. After the import, to view placeholder users for a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.
1. Select the **Placeholders** tab.

#### Placeholder user limits

Placeholder users are created per [import source](#supported-import-sources) and per top-level group:

- If you import the same project twice to the same top-level group on the destination instance, the second import uses
  the same placeholder users as the first import.
- If you import the same project twice, but to a different top-level group on the destination instance, the second import
  creates new placeholder users under that top-level group.

If importing to GitLab.com, placeholder users are limited per top-level group on the destination instance. The limits
differ depending on your plan and seat count. Placeholder users do not count towards license limits.

| GitLab.com plan          | Number of seats | Placeholder user limit on top-level group |
|:-------------------------|:----------------|:------------------------------------------|
| Free and any trial       | Any amount      | 200                                       |
| Premium                  | < 100           | 500                                       |
| Premium                  | 101-500         | 2000                                      |
| Premium                  | 501 - 1000      | 4000                                      |
| Premium                  | > 1000          | 6000                                      |
| Ultimate and open source | < 100           | 1000                                      |
| Ultimate and open source | 101-500         | 4000                                      |
| Ultimate and open source | 501 - 1000      | 6000                                      |
| Ultimate and open source | > 1000          | 8000                                      |

Customers on legacy Bronze, Silver, or Gold plans have the corresponding Free, Premium, or Ultimate limits.
For Premium customers trying out Ultimate (Ultimate trial paid customer plan), Premium limits apply.

If these limits are not sufficient for your import, [contact GitLab Support](https://about.gitlab.com/support/).

The above limits are for GitLab.com. Self-managed GitLab has no placeholder limits by default. A self-managed instance administrator can [set a placeholder limit](../../../administration/instance_limits.md#import-placeholder-user-limits) for their installation.

### Reassign contributions and memberships

Reassignment of contributions and memberships from placeholder users to existing active (non-bot) users occurs on
the destination instance. On the destination instance, you can:

- Request users to accept reassignment of contributions and membership [in the UI](#request-reassignment-in-ui).
  The reassignment process starts only after the selected user [accepts the reassignment request](#accept-contribution-reassignment),
  which is sent to them by email.
- Choose not to reassign contributions and memberships, and [keep them with placeholder users](#keep-as-placeholder).

All the contributions initially assigned to a single placeholder user can only be reassigned to a single active regular
user on the destination instance. The contributions assigned to a single placeholder user cannot be split among multiple
active regular users.

Bot user contributions and memberships on the source instance cannot be reassigned to bot users on the destination instance.
You might choose to keep source bot user contributions [assigned to a placeholder user](#keep-as-placeholder).

Users that receive a reassignment request can:

- [Accept the request](#accept-contribution-reassignment). All contributions and membership previously attributed to the placeholder user are re-attributed
  to the accepting user. This process can take a few minutes, depending on the number of contributions.
- [Reject the request](#reject-contribution-reassignment) or report it as spam. This option is available in the reassignment
  request email.

In subsequent imports, contributions and memberships that belong to the same source user are automatically mapped to the
user who previously accepted reassignments for that source user.

The reassignment process must be fully completed before you:

- [Move an imported group in the same GitLab instance](../../group/manage.md#transfer-a-group).
- [Move an imported project to a different group](../settings/migrate_projects.md).
- Duplicate an imported issue.
- Promote an imported issue to an epic.

If the process isn't complete, contributions still assigned to placeholder users cannot be reassigned to real users and
they stay associated with placeholder users.

#### Security considerations

Once this contribution and membership reassignment is complete, it cannot be undone so check all everything before
starting.

Reassigning contributions and membership to an incorrect user poses a security threat, because the user becomes a member
of your group. They can, therefore, view information they should not be able to see.

#### Request reassignment in UI

Prerequisites:

- You must have the Owner role of the group.

To request a user accept reassignment of contributions and memberships:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.
1. Select the **Placeholders** tab.
1. Go to **Awaiting reassignment** sub-tab, where placeholders are listed in a table.
1. For each placeholder, review information in table columns **Placeholder user** and **Source**.
1. In the **Reassign placeholder to** column, select the a user from the dropdown list.
1. Select **Reassign**.

Contributions of only one placeholder user can be reassigned to an active non-bot user on destination instance.

Before a user accepts the reassignment, you can [cancel the request](#cancel-reassignment-request).

#### Keep as placeholder

You might not want to reassign contributions and memberships to users on the destination instance. For example, you
might have former employees that contributed on the source instance, but they do not exist as users on the destination
instance.

In these cases, you can keep the contributions assigned to placeholder users. Placeholder users do not keep
membership information because they [cannot be members of projects or groups](#placeholder-user-attributes).

Because names and usernames of placeholder users resemble names and usernames of source users, you keep a lot of
historical context.

Remember that if you keep remaining placeholder users as placeholders, you cannot reassign their contributions to
actual users later. Ensure all required reassignments are completed before keeping the remaining placeholder users as
placeholders.

You can keep contributions assigned to placeholder users either one at a time or in bulk.

To keep placeholder users one at a time:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.
1. Select the **Placeholders** tab.
1. Go to **Awaiting reassignment** sub-tab, where placeholders are listed in a table.
1. Find placeholder user you want to keep by reviewing **Placeholder user** and **Source** columns.
1. In **Reassign placeholder to** column, select **Don't reassign**.
1. Select **Confirm**.

To keep placeholder users in bulk:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.
1. Select the **Placeholders** tab.
1. Select **More options icon** next to **Reassign with CSV**.
1. Choose the **Keep all as placeholder** option.
1. On the confirmation dialog, select **Confirm**.

#### Cancel reassignment request

Before a user accepts a reassignment request, you can cancel the request:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.
1. Select the **Placeholders** tab.
1. Go to **Awaiting reassignment** sub-tab, where placeholders are listed in a table.
1. Select **Cancel** in the correct row.

#### Notify user again about pending reassignment requests

If a user is not acting on a reassignment request, you can prompt them again by sending another email:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.
1. Select the **Placeholders** tab.
1. Go to **Awaiting reassignment** sub-tab, where placeholders are listed in a table.
1. Select **Notify** in the correct row.

#### View and filter and sort by reassignment status

You can review statuses of all placeholder users for which the reassignment process haven't been completed yet:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.
1. Select the **Placeholders** tab.
1. Go to **Awaiting reassignment** sub-tab, where placeholders are listed in a table.
1. See the status of each placeholder user in **Reassignment status** column.

You can filter by reassignment status:

1. In filter dropdown list, select **Status**.
1. Choose one of available statuses.

In the **Awaiting reassignment** tab possible statuses are:

- `Not started` - Reassignment has not started.
- `Pending approval` - Reassignment is waiting on user approval.
- `Reassigning` - Reassignment is in progress.
- `Rejected` - Reassignment was rejected by user.
- `Failed` - Reassignment failed.

In the **Reassigned** tab possible statuses are:

- `Success` - Reassignment succeeded.
- `Kept as placeholder` - Placeholder user was made permanent.

By default, the table is sorted alphabetically by placeholder user name. You can also sort the table by reassignment
status:

1. Select on the sort dropdown list.
1. Select **Reassignment status**.

### Accept contribution reassignment

You might receive an email informing you that an import process took place and asking you to confirm reassignment of
contributions to yourself.

If you were informed about this import process, you must still review reassignment details very carefully. Details
listed in the email are:

- **Imported from** - The platform the imported content originates from. For example, another instance of GitLab,
  GitHub, or Bitbucket.
- **Original user** - The name and username of the user on the source platform. This could be your name and user name on
  that platform.
- **Imported to** - The name of the new platform, which can only be a GitLab instance.
- **Reassigned to** - Your full name and username on the GitLab instance.
- **Reassigned by** - The full name and username of your colleague or manager that performed the import.

#### Reject contribution reassignment

If you receive an email asking you to confirm reassignment of contributions to yourself and you don't recognize or you
notice mistakes in this information:

1. Do not proceed at all or reject the contribution reassignment.
1. Talk to a trusted colleague or your manager.

#### Security considerations

You must review the reassignment details of any reassignment request very carefully. If you were not already informed
about this process by a trusted colleague or your manager, take extra care.

Rather than accept any reassignments that you have any doubts about:

1. Don't act on the emails.
1. Talk to a trusted colleague or your manager.

Accept reassignments only from the users that you know and trust. Reassignment of contributions is permanent and cannot
be undone. Accepting the reassignment might cause contributions to be incorrectly attributed to you.

The contribution reassignment process starts only after you accept the reassignment request by selecting
**Approve reassignment** in GitLab. The process doesn't start by selecting links in the email.

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
or [custom](../index.md#create-a-project-from-a-custom-template)
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

### Exception: `Error Importing repository - No such file or directory @ rb_sysopen - (filename)`

The error occurs if you attempt to import a `tar.gz` file download of a repository's source code.

Imports require a [GitLab export](../settings/import_export.md#export-a-project-and-its-data) file, not just a repository download file.
