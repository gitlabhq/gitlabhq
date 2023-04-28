---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
type: reference
---

# Account and limit settings **(FREE SELF)**

## Default projects limit

You can configure the default maximum number of projects new users can create in their
personal namespace. This limit affects only new user accounts created after you change
the setting. This setting is not retroactive for existing users, but you can separately edit
the [project limits for existing users](#projects-limit-for-a-user).

To configure the maximum number of projects in personal namespaces for new users:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > General**, then expand **Account and limit**.
1. Increase or decrease that **Default projects limit** value.

If you set **Default projects limit** to 0, users are not allowed to create projects
in their users personal namespace. However, projects can still be created in a group.

### Projects limit for a user

You can edit a specific user, and change the maximum number of projects this user
can create in their personal namespace:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Overview** > **Users**.
1. From the list of users, select a user.
1. Select **Edit**.
1. Increase or decrease the **Projects limit** value.

## Max attachment size

> [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/20061) from 10 MB to 100 MB in GitLab 15.7.

The maximum file size for attachments in GitLab comments and replies is 100 MB.
To change the maximum attachment size:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > General**, then expand **Account and limit**.
1. Increase or decrease by changing the value in **Maximum attachment size (MB)**.

If you choose a size larger than the configured value for the web server,
you may receive errors. Read the [troubleshooting section](#troubleshooting) for more
details.

For GitLab.com repository size limits, read [accounts and limit settings](../../gitlab_com/index.md#account-and-limit-settings).

## Max push size

You can change the maximum push size for your instance:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > General**, then expand **Account and limit**.
1. Increase or decrease by changing the value in **Maximum push size (MB)**.

For GitLab.com push size limits, read [accounts and limit settings](../../gitlab_com/index.md#account-and-limit-settings).

NOTE:
When you [add files to a repository](../../project/repository/web_editor.md#create-a-file)
through the web UI, the maximum **attachment** size is the limiting factor,
because the [web server](../../../development/architecture.md#components)
must receive the file before GitLab can generate the commit.
Use [Git LFS](../../../topics/git/lfs/index.md) to add large files to a repository.

## Max export size

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86124) in GitLab 15.0.

To modify the maximum file size for exports in GitLab:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > General**, then expand **Account and limit**.
1. Increase or decrease by changing the value in **Maximum export size (MB)**.

## Max import size

> [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/251106) from 50 MB to unlimited in GitLab 13.8.

To modify the maximum file size for imports in GitLab:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > General**, then expand **Account and limit**.
1. Increase or decrease by changing the value in **Maximum import size (MB)**.

This setting applies only to repositories
[imported from a GitLab export file](../../project/settings/import_export.md#import-a-project-and-its-data).

If you choose a size larger than the configured value for the web server,
you may receive errors. See the [troubleshooting section](#troubleshooting) for more
details.

For GitLab.com repository size limits, read [accounts and limit settings](../../gitlab_com/index.md#account-and-limit-settings).

## Personal access token prefix

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20968) in GitLab 13.7.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/342327) in GitLab 14.5, a default prefix.

You can specify a prefix for personal access tokens. You might use a prefix
to find tokens more quickly, or for use with automation tools.

The default prefix is `glpat-` but administrators can change it.

[Project access tokens](../../project/settings/project_access_tokens.md) and
[group access tokens](../../group/settings/group_access_tokens.md) also inherit this prefix.

### Set a prefix

To change the default global prefix:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Account and limit** section.
1. Fill in the **Personal Access Token prefix** field.
1. Select **Save changes**.

You can also configure the prefix by using the
[settings API](../../../api/settings.md).

## Repository size limit **(PREMIUM SELF)**

Repositories in your GitLab instance can grow quickly, especially if you are
using LFS. Their size can grow exponentially, rapidly consuming available storage.
To prevent this from happening, you can set a hard limit for your repositories' size.
This limit can be set globally, per group, or per project, with per project limits
taking the highest priority.

There are numerous use cases where you might set up a limit for repository size.
For instance, consider the following workflow:

1. Your team develops apps which require large files to be stored in
   the application repository.
1. Although you have enabled [Git LFS](../../../topics/git/lfs/index.md#git-large-file-storage-lfs)
   to your project, your storage has grown significantly.
1. Before you exceed available storage, you set up a limit of 10 GB
   per repository.

NOTE:
For GitLab.com repository size limits, read [accounts and limit settings](../../gitlab_com/index.md#account-and-limit-settings).

### How it works

Only a GitLab administrator can set those limits. Setting the limit to `0` means
there are no restrictions.

These settings can be found in:

- Each project's settings:
  1. From the Project's homepage, navigate to **Settings > General**.
  1. Fill in the **Repository size limit (MB)** field in the **Naming, topics, avatar** section.
  1. Select **Save changes**.
- Each group's settings:
  1. From the Group's homepage, navigate to **Settings > General**.
  1. Fill in the **Repository size limit (MB)** field in the **Naming, visibility** section.
  1. Select **Save changes**.
- GitLab global settings:
  1. On the top bar, select **Main menu > Admin**.
  1. On the left sidebar, select **Settings > General**.
  1. Expand the **Account and limit** section.
  1. Fill in the **Size limit per repository (MB)** field.
  1. Select **Save changes**.

The first push of a new project, including LFS objects, is checked for size.
If the sum of their sizes exceeds the maximum allowed repository size, the push
is rejected.

NOTE:
The repository size limit includes repository files and LFS, but does not include artifacts, uploads,
wiki, packages, or snippets. The repository size limit applies to both private and public projects.

For details on manually purging files, see [reducing the repository size using Git](../../project/repository/reducing_the_repo_size_using_git.md).

## Customize the default session duration

You can change how long users can remain signed in.

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > General**.
1. Expand **Account and limit**. The set duration is in **Session duration (minutes)**.

For details, see [cookies used for sign-in](../../profile/index.md#cookies-used-for-sign-in).

## Customize session duration for Git Operations when 2FA is enabled **(PREMIUM SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/296669) in GitLab 13.9.
> - It's deployed behind a feature flag, disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to [enable the feature flag](../../../administration/feature_flags.md) named `two_factor_for_cli`. On GitLab.com, this feature is not available. This feature is not ready for production use. This feature flag also affects [2FA for Git over SSH operations](../../../security/two_factor_authentication.md#2fa-for-git-over-ssh-operations).

GitLab administrators can choose to customize the session duration (in minutes) for Git operations when 2FA is enabled. The default is 15 and this can be set to a value between 1 and 10080.

To set a limit on how long these sessions are valid:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Account and limit** section.
1. Fill in the **Session duration for Git operations when 2FA is enabled (minutes)** field.
1. Select **Save changes**.

## Limit the lifetime of SSH keys **(ULTIMATE SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/1007) in GitLab 14.6 [with a flag](../../../administration/feature_flags.md) named `ff_limit_ssh_key_lifetime`. Disabled by default.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/346753) in GitLab 14.6.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/1007) in GitLab 14.7. [Feature flag `ff_limit_ssh_key_lifetime`](https://gitlab.com/gitlab-org/gitlab/-/issues/347408) removed.

Users can optionally specify a lifetime for
[SSH keys](../../ssh.md).
This lifetime is not a requirement, and can be set to any arbitrary number of days.

SSH keys are user credentials to access GitLab.
However, organizations with security requirements may want to enforce more protection by
requiring the regular rotation of these keys.

### Set a lifetime

Only a GitLab administrator can set a lifetime. Leaving it empty means
there are no restrictions.

To set a lifetime on how long SSH keys are valid:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Account and limit** section.
1. Fill in the **Maximum allowable lifetime for SSH keys (days)** field.
1. Select **Save changes**.

Once a lifetime for SSH keys is set, GitLab:

- Requires users to set an expiration date that is no later than the allowed lifetime on new
  SSH keys.
- Applies the lifetime restriction to existing SSH keys. Keys with no expiry or a lifetime
  greater than the maximum immediately become invalid.

NOTE:
When a user's SSH key becomes invalid they can delete and re-add the same key again.

## Limit the lifetime of access tokens **(ULTIMATE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/3649) in GitLab 12.6.

Users can optionally specify a lifetime for
access tokens, this includes [personal](../../profile/personal_access_tokens.md),
[group](../../group/settings/group_access_tokens.md), and [project](../../project/settings/project_access_tokens.md) access tokens.
This lifetime is not a requirement, and can be set to any arbitrary number of days.

Access tokens are the only tokens needed for programmatic access to GitLab.
However, organizations with security requirements may want to enforce more protection by
requiring the regular rotation of these tokens.

### Set a lifetime

Only a GitLab administrator can set a lifetime. Leaving it empty means
there are no restrictions.

To set a lifetime on how long access tokens are valid:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Account and limit** section.
1. Fill in the **Maximum allowable lifetime for access tokens (days)** field.
1. Select **Save changes**.

Once a lifetime for access tokens is set, GitLab:

- Applies the lifetime for new personal access tokens, and require users to set an expiration date
  and a date no later than the allowed lifetime.
- After three hours, revoke old tokens with no expiration date or with a lifetime longer than the
  allowed lifetime. Three hours is given to allow administrators to change the allowed lifetime,
  or remove it, before revocation takes place.

## Disable user profile name changes **(PREMIUM SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/24605) in GitLab 12.7.

To maintain integrity of user details in [Audit Events](../../../administration/audit_events.md), GitLab administrators can choose to disable a user's ability to change their profile name.

To do this:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > General**, then expand **Account and limit**.
1. Select the **Prevent users from changing their profile name** checkbox.

NOTE:
When this ability is disabled, GitLab administrators can still use the
[Admin Area](../index.md#administering-users) or the
[API](../../../api/users.md#user-modification) to update usernames.

## Prevent new users from creating top-level groups

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/367754) in GitLab 15.5.

By default, new users can create top-level groups. GitLab administrators can prevent new users from creating top-level groups:

- In GitLab 15.5 and later, using either:
  - The GitLab UI using the steps in this section.
  - The [application setting API](../../../api/settings.md#change-application-settings).
- In GitLab 15.4 and earlier, a [configuration file](../../../administration/user_settings.md#use-configuration-files-to-prevent-new-users-from-creating-top-level-groups).

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > General**, then expand **Account and limit**.
1. Clear the **Allow new users to create top-level groups** checkbox.

## Set profiles of new users to private by default

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/231301) in GitLab 15.8.

By default, newly created users have a public profile. GitLab administrators can set new users to have a private profile by default:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > General**, then expand **Account and limit**.
1. Select the **Make new users' profiles private by default** checkbox.

## Troubleshooting

### 413 Request Entity Too Large

When attaching a file to a comment or reply in GitLab displays a `413 Request Entity Too Large`
error, the [max attachment size](#max-attachment-size)
is probably larger than the web server's allowed value.

To increase the max attachment size to 200 MB in a
[Omnibus GitLab](https://docs.gitlab.com/omnibus/) install, you may need to
add the line below to `/etc/gitlab/gitlab.rb` before increasing the max attachment size:

```ruby
nginx['client_max_body_size'] = "200m"
```

### This repository has exceeded its size limit

If you receive intermittent push errors in your [Rails exceptions log](../../../administration/logs/index.md#exceptions_jsonlog), like this:

```plaintext
Your push has been rejected, because this repository has exceeded its size limit.
```

[Housekeeping](../../../administration/housekeeping.md) tasks may be causing your repository size to grow.
To resolve this problem, either of these options helps in the short- to middle-term:

- Increase the [repository size limit](#repository-size-limit).
- [Reduce the repository size](../../project/repository/reducing_the_repo_size_using_git.md).
