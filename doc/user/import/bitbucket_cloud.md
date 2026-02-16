---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrate from Bitbucket Cloud
description: "Migrate from Bitbucket Cloud to GitLab."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Requirement for Maintainer role instead of Developer role introduced in GitLab 16.0 and backported to GitLab 15.11.1 and GitLab 15.10.5.
- Parallel imports from Bitbucket Cloud [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/412614) in GitLab 16.6 [with a flag](../../administration/feature_flags/_index.md) named `bitbucket_parallel_importer`. Disabled by default.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/423530) in GitLab 16.6.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/423530) in GitLab 16.7. Feature flag `bitbucket_parallel_importer` removed.
- An **Imported** badge on some imported items [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/461210) in GitLab 17.2.

{{< /history >}}

Import your projects from Bitbucket Cloud to GitLab.

The Bitbucket Cloud importer imports a subset of items from Bitbucket Cloud.

| Bitbucket Cloud item              | Imported |
|:----------------------------------|:---------|
| Repository description            | {{< yes >}} |
| Git repository data               | {{< yes >}} |
| Issues, including comments        | {{< yes >}} |
| Pull requests, including comments | {{< yes >}} |
| Milestones                        | {{< yes >}} |
| Wiki                              | {{< yes >}} |
| Labels                            | {{< yes >}} |
| Milestones                        | {{< yes >}} |
| LFS objects                       | {{< yes >}} |
| Pull request approvals            | {{< no >}} |
| Approval rules                    | {{< no >}} |

## Importer workflow

When Bitbucket Cloud items are imported:

- References to pull requests and issues are preserved.
- Repository public access is retained. If a repository is private in Bitbucket Cloud, it's created as private in GitLab.
- Imported issues, merge requests, and comments have an **Imported** badge in GitLab.

When importing issues, pull requests, and comments, the Bitbucket Cloud importer:

- Uses the Bitbucket nickname of the author/assignee and tries to find the same Bitbucket identity in GitLab.
- If they don't match or the user is not found in the GitLab database, sets the project creator (usually the current
  user that started the import process) as the author and keeps a reference on the issue about the original Bitbucket
  author.

For pull requests, the importer:

- Uses the source SHA, and if it does not exist in the repository, attempts to set the source commit to the merge commit SHA.
- Sets the merge request assignee to the author and sets reviewers with usernames matching Bitbucket identities in GitLab.
- Sets merge requests in GitLab to be either `opened`, `closed`, or `merged`.

For issues, the importer:

- Adds a label corresponding to the type of issue on Bitbucket. Either `bug`, `enhancement`, `proposal` or `task`.
- If the issue on Bitbucket was one of `resolved`, `invalid`, `duplicate`, `wontfix`, or `closed`, closes the issue on
  GitLab.

The Bitbucket Cloud importer creates any new namespaces (groups) if they don't exist. If the namespace is taken, the
repository is imported under the namespace of the user who started the import process.

## Prerequisites

- You must enable the [Bitbucket Cloud integration](../../integration/bitbucket.md) or
  ask your GitLab administrator to enable it. Enabled by default on GitLab.com.
- You must enable the [Bitbucket Cloud import source](../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)
  or ask your GitLab administrator to enable it. Enabled by default on GitLab.com.
- You must have the Maintainer or Owner role on the destination group to import to.
- Pull requests in Bitbucket must have the same source and destination project and not be from a fork of a project.
  Otherwise, the pull requests are imported as empty merge requests.

For user contributions to be mapped, each user must complete the following before the project import:

1. Verify that the username in the [Bitbucket account settings](https://bitbucket.org/account/settings/)
   matches the public name in the [Atlassian account settings](https://id.atlassian.com/manage-profile/profile-and-visibility).
   If they don't match, modify the public name in the Atlassian account settings to match the
   username in the Bitbucket account settings.
1. Connect your Bitbucket account in [GitLab profile service sign-in](https://gitlab.com/-/profile/account).

### Generate a Bitbucket Cloud app password

> [!warning]
> Support for app passwords was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/work_items/588961) in GitLab 18.9
> and is planned for removal in 19.0. Use [user API tokens](https://support.atlassian.com/organization-administration/docs/understand-user-api-tokens/)
> instead.

If you want to use the import API to import a Bitbucket Cloud repository, you must create a Bitbucket Cloud app password.

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

## Import your Bitbucket Cloud repositories

1. In the upper-right corner, select **Create new** ({{< icon name="plus" >}}) and **New project/repository**.
1. Select **Import project**.
1. Select **Bitbucket Cloud**.
1. Sign in to Bitbucket, then select **Grant access** to give GitLab access to your Bitbucket account.
1. Select the projects you want to import, or import all projects. You can filter projects by name and select the
   namespace each project is imported for.
1. To import a project:
   - For the first time, select **Import**.
   - Subsequent times, select **Re-import**. Specify a new name and select **Re-import** again. Re-importing creates a
     new copy of the source project.

## Troubleshooting

These sections contain possible solutions to issues you might encounter when importing from Bitbucket Cloud.

### Import process used wrong account

Be sure to sign in to the correct account. If you've accidentally started the import process with the wrong account,
follow these steps:

1. Revoke GitLab access to your Bitbucket account, essentially reversing the process when you
   [imported your Bitbucket Cloud repositories](#import-your-bitbucket-cloud-repositories).
1. Sign out of the Bitbucket account and [import your Bitbucket Cloud repositories](#import-your-bitbucket-cloud-repositories) again.

### User mapping fails despite matching names

[For user mapping to work](mapping.md), the username in the Bitbucket account settings must match the public name
in the Atlassian account settings.

If these names match but user mapping still fails, the user might have modified their Bitbucket username after connecting
their Bitbucket account in the [GitLab profile service sign-in](https://gitlab.com/-/profile/account).

To fix this issue, the user must verify that their Bitbucket external UID in the GitLab database matches their
current Bitbucket public name, and reconnect if there's a mismatch:

1. [Use the API to get the authenticated user](../../api/users.md#retrieve-the-current-user).
1. In the API response, the `identities` attribute contains the Bitbucket account that exists in the GitLab database.
   If the `extern_uid` doesn't match the current Bitbucket public name, the user should reconnect their Bitbucket account
   in the [GitLab profile service sign-in](https://gitlab.com/-/profile/account).
1. Following reconnection, the user should use the API again to verify that their `extern_uid` in
   the GitLab database now matches their current Bitbucket public name.

The user who imported the project must then [delete the imported project](../project/working_with_projects.md#delete-a-project)
and import again.

## Related topics

- [Migrate from Bitbucket Server](bitbucket_server.md)
- [Import API](../../api/import.md)
- [Import and export settings](../../administration/settings/import_and_export_settings.md).
- [Sidekiq configuration for imports](../../administration/sidekiq/configuration_for_imports.md).
- [Running multiple Sidekiq processes](../../administration/sidekiq/extra_sidekiq_processes.md).
- [Processing specific job classes](../../administration/sidekiq/processing_specific_job_classes.md).
