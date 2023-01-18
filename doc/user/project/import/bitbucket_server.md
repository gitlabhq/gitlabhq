---
type: reference, howto
stage: Manage
group: Import
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

Prerequisites:

- An administrator must enable **Bitbucket Server** in  **Admin > Settings > General > Visibility and access controls > Import sources**.
- At least the Maintainer role on the destination group to import to. Using the Developer role for this purpose was
  [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/387891) in GitLab 15.8 and will be removed in GitLab 16.0.

To import your Bitbucket repositories:

1. Sign in to GitLab.
1. On the top bar, select **New** (**{plus}**).
1. Select **New project/repository**.
1. Select **Import project**.
1. Select **Bitbucket Server**.
1. Log in to Bitbucket and grant GitLab access to your Bitbucket account.
1. Select the projects to import, or import all projects. You can filter projects by name and select
   the namespace for which to import each project.

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

## Related topics

For information on automating user, group, and project import API calls, see
[Automate group and project import](index.md#automate-group-and-project-import).
