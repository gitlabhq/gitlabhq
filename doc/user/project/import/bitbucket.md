---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Import your project from Bitbucket Cloud
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Parallel imports from Bitbucket Cloud [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/412614) in GitLab 16.6 [with a flag](../../../administration/feature_flags.md) named `bitbucket_parallel_importer`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/423530) in GitLab 16.6.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/423530) in GitLab 16.7. Feature flag `bitbucket_parallel_importer` removed.
> - An **Imported** badge on some imported items [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/461210) in GitLab 17.2.

Import your projects from Bitbucket Cloud to GitLab.

The Bitbucket importer can import:

- Repository description
- Git repository data
- Issues, including comments
- Pull requests, including comments
- Milestones
- Wiki
- Labels
- Milestones
- LFS objects

The Bitbucket importer cannot import:

- Pull request approvals
- Approval rules

When importing:

- References to pull requests and issues are preserved.
- Repository public access is retained. If a repository is private in Bitbucket, it's created as
  private in GitLab as well.
- Imported issues, merge requests, and comments have an **Imported** badge in GitLab.

NOTE:
The Bitbucket Cloud importer works only with [Bitbucket.org](https://bitbucket.org/), not with Bitbucket
Server (aka Stash). If you are trying to import projects from Bitbucket Server, use
[the Bitbucket Server importer](bitbucket_server.md).

When issues, pull requests, and comments are imported, the Bitbucket importer uses the Bitbucket nickname of
the author/assignee and tries to find the same Bitbucket identity in GitLab. If they don't match or
the user is not found in the GitLab database, the project creator (most of the times the current
user that started the import process) is set as the author, but a reference on the issue about the
original Bitbucket author is kept.

For pull requests:

- If the source SHA does not exist in the repository, the importer attempts to set the source commit to the merge commit SHA.
- The merge request assignee is set to the author. Reviewers are set with usernames matching Bitbucket identities in GitLab.
- Merge requests in GitLab can be either can be either `opened`, `closed` or `merged`.

For issues:

- A label is added corresponding to the type of issue on Bitbucket. Either `bug`, `enhancement`, `proposal` or `task`.
- If the issue on Bitbucket was one of `resolved`, `invalid`, `duplicate`, `wontfix`, or `closed`, the issue is closed on GitLab.

The importer creates any new namespaces (groups) if they don't exist or in
the case the namespace is taken, the repository is imported under the user's
namespace that started the import process.

## Prerequisites

> - Requirement for Maintainer role instead of Developer role introduced in GitLab 16.0 and backported to GitLab 15.11.1 and GitLab 15.10.5.

- [Bitbucket Cloud integration](../../../integration/bitbucket.md) must be enabled. If that integration is not enabled, ask your GitLab administrator
  to enable it. The Bitbucket Cloud integration is enabled by default on GitLab.com.
- [Bitbucket Cloud import source](../../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources) must be enabled. If not enabled, ask your
  GitLab administrator to enable it. The Bitbucket Cloud import source is enabled by default on GitLab.com.
- At least the Maintainer role on the destination group to import to.
- Pull requests in Bitbucket must have the same source and destination project and not be from a fork of a project.
  Otherwise, the pull requests are imported as empty merge requests.

### Requirements for user-mapped contributions

For user contributions to be mapped, each user must complete the following before the project import:

1. Verify that the username in the [Bitbucket account settings](https://bitbucket.org/account/settings/)
   matches the public name in the [Atlassian account settings](https://id.atlassian.com/manage-profile/profile-and-visibility).
   If they don't match, modify the public name in the Atlassian account settings to match the
   username in the Bitbucket account settings.

1. Connect your Bitbucket account in [GitLab profile service sign-in](https://gitlab.com/-/profile/account).

## Import your Bitbucket repositories

> - Ability to re-import projects [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/23905) in GitLab 15.9.

1. Sign in to GitLab.
1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Import project**.
1. Select **Bitbucket Cloud**.
1. Sign in to Bitbucket and grant GitLab access to your Bitbucket account.

   ![Grant access](img/bitbucket_import_grant_access_v8.png)

1. Select the projects that you'd like to import or import all projects.
   You can filter projects by name and select the namespace
   each project is imported for.

1. To import a project:
   - For the first time: Select **Import**.
   - Again: Select **Re-import**. Specify a new name and select **Re-import** again. Re-importing creates a new copy of the source project.

### Generate a Bitbucket Cloud app password

If you want to use the [GitLab REST API](../../../api/import.md#import-repository-from-bitbucket-cloud) to import a
Bitbucket Cloud repository, you must create a Bitbucket Cloud app password.

To generate a Bitbucket Cloud app password:

1. Go to <https://bitbucket.org/account/settings/>.
1. In the **Access Management** section, select **App passwords**.
1. Select **Create app password**.
1. Enter password name.
1. Select at least the following permissions:

   ```plaintext
   Account: Email, Read
   Projects: Read
   Repositories: Read
   Pull Requests: Read
   Issues: Read
   Wiki: Read and Write
   ```

1. Select **Create**.

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

1. [Use the API to get the currently authenticated user](../../../api/users.md#as-a-regular-user-2).

1. In the API response, the `identities` attribute contains the Bitbucket account that exists in
   the GitLab database. If the `extern_uid` doesn't match the current Bitbucket public name, the
   user should reconnect their Bitbucket account in the [GitLab profile service sign-in](https://gitlab.com/-/profile/account).

1. Following reconnection, the user should use the API again to verify that their `extern_uid` in
   the GitLab database now matches their current Bitbucket public name.

The importer must then [delete the imported project](../working_with_projects.md#delete-a-project)
and import again.
