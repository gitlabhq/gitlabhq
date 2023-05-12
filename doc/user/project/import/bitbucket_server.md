---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Import your project from Bitbucket Server **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/20164) in GitLab 11.2.

NOTE:
This process is different than [importing from Bitbucket Cloud](bitbucket.md).

From Bitbucket Server, you can import:

- Repository description
- Git repository data
- Pull requests
- Pull request comments

When importing, repository public access is retained. If a repository is private in Bitbucket, it's
created as private in GitLab as well.

## Import your Bitbucket repositories

> Ability to re-import projects [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/23905) in GitLab 15.9.

You can import Bitbucket repositories to GitLab.

### Prerequisites

> Requirement for Maintainer role instead of Developer role introduced in GitLab 16.0 and backported to GitLab 15.11.1 and GitLab 15.10.5.

- [Bitbucket Server import source](../../admin_area/settings/visibility_and_access_controls.md#configure-allowed-import-sources)
  must be enabled. If not enabled, ask your GitLab administrator to enable it. The Bitbucket Server import source is enabled
  by default on GitLab.com.
- At least the Maintainer role on the destination group to import to.

### Import repositories

To import your Bitbucket repositories:

1. Sign in to GitLab.
1. On the top bar, select **New** (**{plus}**).
1. Select **New project/repository**.
1. Select **Import project**.
1. Select **Bitbucket Server**.
1. Log in to Bitbucket and grant GitLab access to your Bitbucket account.
1. Select the projects to import, or import all projects. You can filter projects by name and select
   the namespace for which to import each project.
1. To import a project:
   - For the first time: Select **Import**.
   - Again: Select **Re-import**. Specify a new name and select **Re-import** again. Re-importing creates a new copy of the source project.

### Items that are not imported

The following items aren't imported:

- Pull request approvals
- Attachments in Markdown
- Task lists
- Emoji reactions

### Items that are imported but changed

The following items are changed when they are imported:

- GitLab doesn't allow comments on arbitrary lines of code. Any out-of-bounds Bitbucket comments are
  inserted as comments in the merge request.
- Multiple threading levels are collapsed into one thread and
  quotes are added as part of the original comment.
- Declined pull requests have unreachable commits. These pull requests show up as empty changes.
- Project filtering doesn't support fuzzy search. Only **starts with** or **full match** strings are
  supported.

## User assignment

Prerequisite:

- Authentication token with administrator access.

When issues and pull requests are importing, the importer tries to find the author's email address
with a confirmed email address in the GitLab user database. If no such user is available, the
project creator is set as the author. The importer appends a note in the comment to mark the
original creator.

The importer creates any new namespaces (groups) if they don't exist. If the namespace is taken, the
repository imports under the namespace of the user who started the import process.

### User assignment by username

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/218609) in GitLab 13.4 [with a flag](../../../administration/feature_flags.md) named `bitbucket_server_user_mapping_by_username`. Disabled by default.
> - Not recommended for production use.

FLAG:
On self-managed GitLab and GitLab.com, by default this feature is not available. To make it
available, ask an administrator to [enable the feature flag](../../../administration/feature_flags.md)
named `bitbucket_server_user_mapping_by_username`. This feature is not ready for production use.

With this feature enabled, the importer tries to find a user in the GitLab user database with the
author's:

- `username`
- `slug`
- `displayName`

If no user matches these properties, the project creator is set as the author.

## Troubleshooting

### General

If the GUI-based import tool does not work, you can try to:

- Use the [GitLab Import API](../../../api/import.md#import-repository-from-bitbucket-server)
  Bitbucket Server endpoint.
- Set up [repository mirroring](../repository/mirror/index.md).
  It provides verbose error output.

See the [troubleshooting section](bitbucket.md#troubleshooting)
for Bitbucket Cloud.

### LFS objects not imported

If the project import completes but LFS objects can't be downloaded or cloned, you may be using a
password or personal access token containing special characters. For more information, see
[this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/337769).

### Pull requests are missing

Importing large projects spawns a process that can consume a lot of memory. Sometimes you can see messages such as `Sidekiq worker RSS out of range` in the
[Sidekiq logs](../../../administration/logs/index.md#sidekiq-logs). This can mean that MemoryKiller is interrupting the `RepositoryImportWorker` because it's using
too much memory.

To resolve this problem, temporarily increase the `SIDEKIQ_MEMORY_KILLER_MAX_RSS` environment variable using
[custom environment variables](https://docs.gitlab.com/omnibus/settings/environment-variables.html) from the default `2000000` value to a larger value like `3000000`.
Consider memory constraints on the system before deciding to increase `SIDEKIQ_MEMORY_KILLER_MAX_RSS`.

## Related topics

- [Automate group and project import](index.md#automate-group-and-project-import)
