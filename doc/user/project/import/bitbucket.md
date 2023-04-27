---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Import your project from Bitbucket Cloud to GitLab **(FREE)**

NOTE:
The Bitbucket Cloud importer works only with [Bitbucket.org](https://bitbucket.org/), not with Bitbucket
Server (aka Stash). If you are trying to import projects from Bitbucket Server, use
[the Bitbucket Server importer](bitbucket_server.md).

Import your projects from Bitbucket Cloud to GitLab with minimal effort.

The Bitbucket importer can import:

- Repository description
- Git repository data
- Issues
- Issue comments
- Pull requests
- Pull request comments
- Milestones
- Wiki

When importing:

- References to pull requests and issues are preserved.
- Repository public access is retained. If a repository is private in Bitbucket, it's created as
  private in GitLab as well.

## Prerequisites

- [Bitbucket Cloud integration](../../../integration/bitbucket.md) must be enabled. If that integration is not enabled, ask your GitLab administrator
  to enable it. The Bitbucket Cloud integration is enabled by default on GitLab.com.
- [Bitbucket Cloud import source](../../admin_area/settings/visibility_and_access_controls.md#configure-allowed-import-sources) must be enabled. If not enabled, ask your
  GitLab administrator to enable it. The Bitbucket Cloud import source is enabled by default on GitLab.com.
- At least the Maintainer role on the destination group to import to. Using the Developer role for this purpose was
  [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/387891) in GitLab 15.8 and will be removed in GitLab 16.0.

## How it works

When issues/pull requests are being imported, the Bitbucket importer uses the Bitbucket nickname of
the author/assignee and tries to find the same Bitbucket identity in GitLab. If they don't match or
the user is not found in the GitLab database, the project creator (most of the times the current
user that started the import process) is set as the author, but a reference on the issue about the
original Bitbucket author is kept.

The importer creates any new namespaces (groups) if they don't exist or in
the case the namespace is taken, the repository is imported under the user's
namespace that started the import process.

## Requirements for user-mapped contributions

For user contributions to be mapped, each user must complete the following before the project import:

1. Verify that the username in the [Bitbucket account settings](https://bitbucket.org/account/settings/)
   matches the public name in the [Atlassian account settings](https://id.atlassian.com/manage-profile/profile-and-visibility).
   If they don't match, modify the public name in the Atlassian account settings to match the
   username in the Bitbucket account settings.

1. Connect your Bitbucket account in [GitLab profile service sign-in](https://gitlab.com/-/profile/account).

1. [Set your public email](../../profile/index.md#set-your-public-email).

## Import your Bitbucket repositories

> Ability to re-import projects [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/23905) in GitLab 15.9.

1. Sign in to GitLab.
1. On the top bar, select **New** (**{plus}**).
1. Select **New project/repository**.
1. Select **Import project**.
1. Select **Bitbucket Cloud**.
1. Log in to Bitbucket and grant GitLab access to your Bitbucket account.

   ![Grant access](img/bitbucket_import_grant_access.png)

1. Select the projects that you'd like to import or import all projects.
   You can filter projects by name and select the namespace
   each project is imported for.

1. To import a project:
   - For the first time: Select **Import**.
   - Again: Select **Re-import**. Specify a new name and select **Re-import** again. Re-importing creates a new copy of the source project.

## Troubleshooting

### If you have more than one Bitbucket account

Be sure to sign in to the correct account.

If you've accidentally started the import process with the wrong account, follow these steps:

1. Revoke GitLab access to your Bitbucket account, essentially reversing the process in the following procedure: [Import your Bitbucket repositories](#import-your-bitbucket-repositories).

1. Sign out of the Bitbucket account. Follow the procedure linked from the previous step.

### User mapping fails despite matching names

[For user mapping to work](#requirements-for-user-mapped-contributions),
the username in the Bitbucket account settings must match the public name in the Atlassian account
settings. If these names match but user mapping still fails, the user may have modified their
Bitbucket username after connecting their Bitbucket account in the
[GitLab profile service sign-in](https://gitlab.com/-/profile/account).

To fix this, the user must verify that their Bitbucket external UID in the GitLab database matches their
current Bitbucket public name, and reconnect if there's a mismatch:

1. [Use the API to get the currently authenticated user](../../../api/users.md#for-non-administrator-users-1).

1. In the API response, the `identities` attribute contains the Bitbucket account that exists in
   the GitLab database. If the `extern_uid` doesn't match the current Bitbucket public name, the
   user should reconnect their Bitbucket account in the [GitLab profile service sign-in](https://gitlab.com/-/profile/account).

1. Following reconnection, the user should use the API again to verify that their `extern_uid` in
   the GitLab database now matches their current Bitbucket public name.

The importer must then [delete the imported project](../../project/working_with_projects.md#delete-a-project)
and import again.
