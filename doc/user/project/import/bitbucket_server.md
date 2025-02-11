---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Import your project from Bitbucket Server
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Ability to re-import projects [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/23905) in GitLab 15.9.
> - Ability to import reviewers [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416611) in GitLab 16.3.
> - Support for pull request approval imports [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135256) in GitLab 16.7.
> - An **Imported** badge on some imported items [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/461211) in GitLab 17.2.

Import your projects from Bitbucket Server to GitLab.

## Prerequisites

> - Requirement for Maintainer role instead of Developer role introduced in GitLab 16.0 and backported to GitLab 15.11.1 and GitLab 15.10.5.

- [Bitbucket Server import source](../../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)
  must be enabled. If not enabled, ask your GitLab administrator to enable it. The Bitbucket Server import source is enabled
  by default on GitLab.com.
- At least the Maintainer role on the destination group to import to.
- Bitbucket Server authentication token with administrator access. Without administrator access, some data is
  [not imported](https://gitlab.com/gitlab-org/gitlab/-/issues/446218).

## Import repositories

To import your Bitbucket repositories:

1. Sign in to GitLab.
1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Import project**.
1. Select **Bitbucket Server**.
1. Sign in to Bitbucket and grant GitLab access to your Bitbucket account.
1. Select the projects to import, or import all projects. You can filter projects by name and select
   the namespace for which to import each project.
1. To import a project:
   - For the first time: Select **Import**.
   - Again: Select **Re-import**. Specify a new name and select **Re-import** again. Re-importing creates a new copy of the source project.

## Items that are imported

- Repository description
- Git repository data
- Pull requests, including comments, user mentions, reviewers, and merge events
- LFS objects

When importing:

- Repository public access is retained. If a repository is private in Bitbucket, it's created as private in GitLab as
  well.
- Imported merge requests and comments have an **Imported** badge in GitLab.

When closed or merged pull requests are imported, commit SHAs that do not exist in the repository are fetched from the Bitbucket server
to make sure pull requests have commits tied to them:

- Source commit SHAs are saved with references in the format `refs/merge-requests/<iid>/head`.
- Target commit SHAs are saved with references in the format `refs/keep-around/<SHA>`.

If the source commit does not exist in the repository, a commit containing the SHA in the commit message is used instead.

## Items that are not imported

The following items aren't imported:

- Attachments in Markdown
- Task lists
- Emoji reactions
- Pull request approvals
- Approval rules for pull requests

## Items that are imported but changed

The following items are changed when they are imported:

- GitLab doesn't allow comments on arbitrary lines of code. Any out-of-bounds Bitbucket comments are
  inserted as comments in the merge request.
- Multiple threading levels are collapsed into one thread and
  quotes are added as part of the original comment.
- Project filtering doesn't support fuzzy search. Only **starts with** or **full match** strings are
  supported.

## User contribution and membership mapping

> - User mapping by email address or username [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/36885) in GitLab 13.4 [with a flag](../../../administration/feature_flags.md) named `bitbucket_server_user_mapping_by_username`. Disabled by default.
> - Mapping user mentions to GitLab users [added](https://gitlab.com/gitlab-org/gitlab/-/issues/433008) in GitLab 16.8.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153041) to map users only by email address in GitLab 17.1.
> - [Changed on GitLab.com](https://gitlab.com/groups/gitlab-org/-/epics/14667) to [user contribution and membership mapping](../import/_index.md#user-contribution-and-membership-mapping) in GitLab 17.8.
> - [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176675) in GitLab 17.8.

The Bitbucket Server importer uses an [improved method](../import/_index.md#user-contribution-and-membership-mapping)
of mapping user contributions for GitLab.com and GitLab Self-Managed.

### Old method of user contribution mapping

You can use the old user contribution mapping method for imports to GitLab Self-Managed and GitLab Dedicated instances.
To use this method, `importer_user_mapping` and `bulk_import_importer_user_mapping` must be disabled.
For imports to GitLab.com, you must
use the [improved method](../import/_index.md#user-contribution-and-membership-mapping) instead.

Using the old method, the importer tries to match a Bitbucket Server user's email address with a confirmed email address in the GitLab user database. If no
such user is found:

- The project creator is used instead. The importer appends a note in the comment to mark the original creator.
- For pull request reviewers, no reviewer is assigned.
- For pull request approvers, no approval is added.

`@mentions` on pull request descriptions and notes are matched to user profiles on a Bitbucket Server by using the user's email address.
If a user with the same email address is not found on GitLab, the `@mention` is made static.
For a user to be matched, they must have a GitLab role that provides at least read access to the project.

If the project is public, GitLab only matches users who are invited to the project.

The importer creates any new namespaces (groups) if they don't exist. If the namespace is taken, the
repository imports under the namespace of the user who started the import process.

## Troubleshooting

### General

If the GUI-based import tool does not work, you can try to:

- Use the [GitLab Import API](../../../api/import.md#import-repository-from-bitbucket-server)
  Bitbucket Server endpoint.
- Set up [repository mirroring](../repository/mirror/_index.md).
  It provides verbose error output.

See the [troubleshooting section](bitbucket.md#troubleshooting)
for Bitbucket Cloud.

### LFS objects not imported

If the project import completes but LFS objects can't be downloaded or cloned, you may be using a
password or personal access token containing special characters. For more information, see
[this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/337769).

### Import fails due to invalid/unresolved host address, or the import URL is blocked

If a project import fails with an error message such as `Importing the project failed: Import url is blocked`, even though the initial connection to the Bitbucket
server succeeded, the Bitbucket server or a reverse proxy might not be configured correctly.

To troubleshoot this problem, use the [Projects API](../../../api/projects.md) to check for the newly-created project and locate the `import_url` value of the project.

This value indicates the URL provided by the Bitbucket server to use for the import. If this URL isn't publicly resolvable, you can get unresolvable address errors.

To fix this problem, ensure that the Bitbucket server is aware of any proxy servers because proxy servers can impact how Bitbucket constructs and uses URLs.
For more information, see [Proxy and secure Bitbucket](https://confluence.atlassian.com/bitbucketserver/proxy-and-secure-bitbucket-776640099.html).
