---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Configure the maximum number of projects users can create on GitLab Self-Managed. Configure size limits for attachments, pushes, and repository size."
title: Account and limit settings
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

## Default projects limit

You can configure the default maximum number of projects new users can create in their
personal namespace. This limit affects only new user accounts created after you change
the setting. This setting is not retroactive for existing users, but you can separately edit
the [project limits for existing users](#projects-limit-for-a-user).

To configure the maximum number of projects in personal namespaces for new users:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Account and limit**.
1. Increase or decrease that **Default projects limit** value.

If you set **Default projects limit** to 0, users are not allowed to create projects
in their user's personal namespace. However, projects can still be created in a group.

### Projects limit for a user

You can edit a specific user, and change the maximum number of projects this user
can create in their personal namespace:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview** > **Users**.
1. From the list of users, select a user.
1. Select **Edit**.
1. Increase or decrease the **Projects limit** value.

## Max attachment size

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/20061) from 10 MB to 100 MB in GitLab 15.7.

The maximum file size for attachments in GitLab comments and replies is 100 MB.
To change the maximum attachment size:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Account and limit**.
1. Increase or decrease by changing the value in **Maximum attachment size (MiB)**.

If you choose a size larger than the configured value for the web server,
you may receive errors. For more information, see the [troubleshooting section](#troubleshooting).

For GitLab.com repository size limits, see [accounts and limit settings](../../user/gitlab_com/_index.md#account-and-limit-settings).

## Max push size

You can change the maximum push size for your instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Account and limit**.
1. Increase or decrease by changing the value in **Maximum push size (MiB)**.

For GitLab.com push size limits, see [accounts and limit settings](../../user/gitlab_com/_index.md#account-and-limit-settings).

NOTE:
When you [add files to a repository](../../user/project/repository/web_editor.md#create-a-file)
through the web UI, the maximum **attachment** size is the limiting factor. This happens
because the [web server](../../development/architecture.md#components)
must receive the file before GitLab can generate the commit.
Use [Git LFS](../../topics/git/lfs/_index.md) to add large files to a repository.
This setting does not apply when pushing Git LFS objects.

## Personal access token prefix

You can specify a prefix for personal access tokens. You might use a prefix
to find tokens more quickly, or for use with automation tools.

The default prefix is `glpat-` but administrators can change it.

[Project access tokens](../../user/project/settings/project_access_tokens.md) and
[group access tokens](../../user/group/settings/group_access_tokens.md) also inherit this prefix.

### Set a prefix

To change the default global prefix:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand the **Account and limit** section.
1. Fill in the **Personal access token prefix** field.
1. Select **Save changes**.

You can also configure the prefix by using the
[settings API](../../api/settings.md).

## Repository size limit

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

Repositories in your GitLab instance can grow quickly, especially if you are
using LFS. Their size can grow exponentially, rapidly consuming available storage.
To prevent this from happening, you can set a hard limit for your repositories' size.
This limit can be set globally, per group, or per project, with per project limits
taking the highest priority.

The repository size limit applies to both private and public projects. It includes repository files and LFS,
but does not include:

- Artifacts
- Containers
- Packages
- Snippets
- Uploads
- Wikis

Numerous use cases exist where you might set up a limit for repository size.
For instance, consider the following workflow:

1. Your team develops apps which require large files to be stored in
   the application repository.
1. Although you have enabled [Git LFS](../../topics/git/lfs/_index.md)
   to your project, your storage has grown significantly.
1. Before you exceed available storage, you set up a limit of 10 GB
   per repository.

On GitLab Self-Managed, only a GitLab administrator can set those limits. Setting the limit to `0` means
there are no restrictions. For GitLab.com repository size limits, see
[accounts and limit settings](../../user/gitlab_com/_index.md#account-and-limit-settings).

These settings can be found in:

- Each project's settings:
  1. From the Project's homepage, go to **Settings > General**.
  1. Fill in the **Repository size limit (MiB)** field in the **Naming, topics, avatar** section.
  1. Select **Save changes**.
- Each group's settings:
  1. From the Group's homepage, go to **Settings > General**.
  1. Fill in the **Repository size limit (MiB)** field in the **Naming, visibility** section.
  1. Select **Save changes**.
- GitLab global settings:
  1. On the left sidebar, at the bottom, select **Admin**.
  1. Select **Settings > General**.
  1. Expand the **Account and limit** section.
  1. Fill in the **Size limit per repository (MiB)** field.
  1. Select **Save changes**.

The first push of a new project, including LFS objects, is checked for size.
If the sum of their sizes exceeds the maximum allowed repository size, the push
is rejected.

For details on manually purging files, see [reducing the repository size using Git](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size).

## Session duration

### Customize the default session duration

You can change how long users can remain signed in without activity.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Account and limit**.
1. Fill in the **Session duration (minutes)** field.
1. Select **Save changes**.
1. Restart GitLab to apply the changes.

   WARNING:
   Setting **Session duration (minutes)** to `0` breaks your GitLab instance.
   For more information, see [issue 19469](https://gitlab.com/gitlab-org/gitlab/-/issues/19469).

If [Remember me](#turn-remember-me-on-or-off) is enabled, users' sessions can remain active for an indefinite period of time.

For details, see [cookies used for sign-in](../../user/profile/_index.md#cookies-used-for-sign-in).

### Turn **Remember me** on or off

> - Enabling and disabling the **Remember me** setting [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/369133) in GitLab 16.0.

Users can select the **Remember me** checkbox on sign-in. Their session remains active for an indefinite
period of time when accessed from that specific browser. Turn off this setting to expire sessions for
security or compliance purposes. Turning off this setting ensures users' sessions expire after the
number of minutes of inactivity set when you [customize your session duration](#customize-the-default-session-duration).

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Account and limit**.
1. Select or clear the **Remember me** checkbox to turn this setting on or off.

### Customize session duration for Git Operations when 2FA is enabled

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/296669) in GitLab 13.9 with a [flag](../feature_flags.md) named `two_factor_for_cli`. Disabled by default. This feature flag also affects [2FA for Git over SSH operations](../../security/two_factor_authentication.md#2fa-for-git-over-ssh-operations).

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history. This feature is not ready for production use.

GitLab administrators can choose to customize the session duration (in minutes) for Git operations
when 2FA is enabled. The default is 15 and this can be set to a value between 1 and 10080.

To set a limit on how long these sessions are valid:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand the **Account and limit** section.
1. Fill in the **Session duration for Git operations when 2FA is enabled (minutes)** field.
1. Select **Save changes**.

## Require expiration dates for new access tokens

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/470192) in GitLab 17.3.

Prerequisites:

- You must be an administrator.

You can require all new access tokens to have an expiration date.
This setting is turned on by default and applies to:

- Project access tokens.
- Group access tokens.
- Personal access tokens for non-service account users.

For personal access tokens for service accounts, use the `service_access_tokens_expiration_enforced`
setting in the [Application Settings API](../../api/settings.md).

To require expiration dates for new access tokens:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Account and limit**.
1. Select the **Personal / Project / Group access token expiration** checkbox.
1. Select **Save changes**.

When you require expiration dates for new access tokens:

- Users must set an expiration date that does not exceed the allowed lifetime for new access tokens.
- To control the maximum access token lifetime, use the [**Limit the lifetime of access tokens** setting](#limit-the-lifetime-of-access-tokens).

## Allow top-level group Owners to create service accounts

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163726) in GitLab 17.5 [with a feature flag](../feature_flags.md) named `allow_top_level_group_owners_to_create_service_accounts` for GitLab Self-Managed. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172502) in GitLab 17.6. Feature flag `allow_top_level_group_owners_to_create_service_accounts` removed.

By default, in GitLab Self-Managed, top-level group Owners can not create service accounts. GitLab
administrators can allow top-level group Owners to create service accounts.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Account and limit**.
1. Under **Service account creation**, select the **Allow top-level group owners to create Service accounts** checkbox.
1. Select **Save changes**.

## Limit the lifetime of SSH keys

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Self-Managed

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/461901) the maximum allowable lifetime limit to an increased value of 400 days in GitLab 17.6 [with a flag](../feature_flags.md) named `buffered_token_expiration_limit`. Disabled by default.

FLAG:
The availability of the extended maximum allowable lifetime limit is controlled by a feature flag.
For more information, see the history.

Users can optionally specify a lifetime for
[SSH keys](../../user/ssh.md).
This lifetime is not a requirement, and can be set to any arbitrary number of days.

SSH keys are user credentials to access GitLab.
However, organizations with security requirements may want to enforce more protection by
requiring the regular rotation of these keys.

### Set a lifetime

Only a GitLab administrator can set a lifetime. Leaving it empty means
there are no restrictions.

To set a lifetime on how long SSH keys are valid:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand the **Account and limit** section.
1. Fill in the **Maximum allowable lifetime for SSH keys (days)** field.
1. Select **Save changes**.

After a lifetime for SSH keys is set, GitLab:

- Requires users to set an expiration date that is no later than the allowed lifetime on new SSH keys. The maximum allowed lifetime is:
  - 365 days by default.
  - 400 days, if you enable the `buffered_token_expiration_limit` feature flag.
- Applies the lifetime restriction to existing SSH keys. Keys with no expiry or a lifetime
  greater than the maximum immediately become invalid.

NOTE:
When a user's SSH key becomes invalid they can delete and re-add the same key again.

## Limit the lifetime of access tokens

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Self-Managed

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/461901) the maximum allowable lifetime limit to an increased value of 400 days in GitLab 17.6 [with a flag](../feature_flags.md) named `buffered_token_expiration_limit`. Disabled by default.

FLAG:
The availability of the extended maximum allowable lifetime limit is controlled by a feature flag.
For more information, see the history.

Users can optionally specify a maximum lifetime in days for
access tokens, this includes [personal](../../user/profile/personal_access_tokens.md),
[group](../../user/group/settings/group_access_tokens.md), and [project](../../user/project/settings/project_access_tokens.md) access tokens.
This lifetime is not a requirement, and can be set to any value greater than 0 and less than or equal to:

- 365 days by default.
- 400 days, if you enable the `buffered_token_expiration_limit` feature flag.

If this setting is left blank, the default allowable lifetime of access tokens is:

- 365 days by default.
- 400 days, if you enable the `buffered_token_expiration_limit` feature flag.

Access tokens are the only tokens needed for programmatic access to GitLab.
However, organizations with security requirements may want to enforce more protection by
requiring the regular rotation of these tokens.

### Set a lifetime

Only a GitLab administrator can set a lifetime. Leaving it empty means
there are no restrictions.

To set a lifetime on how long access tokens are valid:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand the **Account and limit** section.
1. Fill in the **Maximum allowable lifetime for access tokens (days)** field.
1. Select **Save changes**.

After a lifetime for access tokens is set, GitLab:

- Applies the lifetime for new personal access tokens, and require users to set an expiration date
  and a date no later than the allowed lifetime.
- After three hours, revoke old tokens with no expiration date or with a lifetime longer than the
  allowed lifetime. Three hours is given to allow administrators to change the allowed lifetime,
  or remove it, before revocation takes place.

## User OAuth applications setting

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Prerequisites:

- You must be an administrator.

The **User OAuth applications** setting controls whether users can register applications to use GitLab
as an OAuth provider. This setting affects OAuth applications owned by users, but does not affect OAuth
applications owned by groups.

To turn the **User OAuth applications** setting on or off:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand the **Account and limit** section.
1. Select or clear the **User OAuth applications** checkbox.
1. Select **Save changes**.

## OAuth authorizations

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/323615) in GitLab 17.8.

Prerequisites:

- You must be an administrator.

The **OAuth authorizations** setting controls whether users can use the OAuth resource owner password
credentials flow to authorize themselves without client credentials.

To turn this setting on or off:

1. On the left sidebar, under **Settings**, select **Admin area**.
1. Select **OAuth**.
1. Select **OAuth authorizations**.
1. Select or clear the **Allow user to use resource owner password credentials flow without OAuth client credentials** checkbox.
1. Select **Save changes**.

## Disable user profile name changes

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

To maintain integrity of user details in [audit events](../audit_event_reports.md),
GitLab administrators can prevent users from changing their profile name.

To do this:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Account and limit**.
1. Select **Prevent users from changing their profile name**.

When selected, GitLab administrators can still update usernames in the
[**Admin** area](../admin_area.md#administering-users) or the
[API](../../api/users.md#modify-a-user).

## Prevent users from creating organizations

DETAILS:
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423302) in GitLab 16.7 [with a flag](../feature_flags.md) named `ui_for_organizations`. Disabled by default.

FLAG:
On GitLab Self-Managed, by default this feature is not available. To make it available, an administrator
can [enable the feature flag](../feature_flags.md) named `ui_for_organizations`. On GitLab.com and GitLab Dedicated,
this feature is not available. This feature is not ready for production use.

By default, users can create organizations. GitLab administrators can prevent users from creating organizations.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Account and limit**.
1. Clear the **Allow users to create organizations** checkbox.

## Prevent new users from creating top-level groups

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/367754) in GitLab 15.5.

By default, new users can create top-level groups. GitLab administrators can prevent new users from creating top-level groups:

- In GitLab 15.5 and later, use either:
  - The GitLab UI with the steps in this section.
  - The [Application settings API](../../api/settings.md#update-application-settings).
- In GitLab 15.4 and earlier, modify a [configuration file](../user_settings.md#prevent-users-from-creating-top-level-groups).

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Account and limit**.
1. Clear the **Allow new users to create top-level groups** checkbox.

## Prevent non-members from creating projects and groups

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/426279) in GitLab 16.8

By default, users with the Guest role can create projects and groups.
GitLab administrators can prevent this behavior:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Account and limit**.
1. Clear the **Allow users with up to Guest role to create groups and personal projects** checkbox.
1. Select **Save changes**.

## Prevent users from making their profiles private

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/421310) in GitLab 17.1 [with a flag](../feature_flags.md) named `disallow_private_profiles`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/427400) in GitLab 17.9. Feature flag `disallow_private_profiles` removed.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

By default, users can make their profiles private.
GitLab administrators can disable this setting to require all user profiles to be public.
This setting does not affect [internal users](../internal_users.md) (sometimes referred to as "bots").

To prevent users from making their profiles private:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Account and limit**.
1. Clear the **Allow users to make their profiles private** checkbox.
1. Select **Save changes**.

When you turn off this setting:

- All private user profiles become public.
- The option to [set profiles of new users to private by default](#set-profiles-of-new-users-to-private-by-default)
  is also turned off.

When you re-enable this setting, the user's
[previously set profile visibility](../../user/profile/_index.md#make-your-user-profile-page-private) is selected.

## Set profiles of new users to private by default

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/231301) in GitLab 15.8.

By default, newly created users have a public profile. GitLab administrators can set new users to have a private profile by default:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Account and limit**.
1. Select the **Make new users' profiles private by default** checkbox.
1. Select **Save changes**.

NOTE:
If [**Allow users to make their profiles private**](#prevent-users-from-making-their-profiles-private) is disabled, this setting is also disabled.

## Prevent users from deleting their accounts

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/26053) in GitLab 16.1 [with a flag](../feature_flags.md) named `deleting_account_disabled_for_users`. Enabled by default.

By default, users can delete their own accounts. GitLab administrators can prevent
users from deleting their own accounts:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Account and limit**.
1. Clear the **Allows users to delete their own accounts** checkbox.

## Troubleshooting

### 413 Request Entity Too Large

When attaching a file to a comment or reply in GitLab, the [max attachment size](#max-attachment-size)
is probably larger than the web server's allowed value.

To increase the max attachment size to 200 MB in a
[Linux package](https://docs.gitlab.com/omnibus/) install:

1. Add this line to `/etc/gitlab/gitlab.rb`:

   ```ruby
   nginx['client_max_body_size'] = "200m"
   ```

1. Increase the max attachment size.

### This repository has exceeded its size limit

If you receive intermittent push errors in your [Rails exceptions log](../logs/_index.md#exceptions_jsonlog), like this:

```plaintext
Your push has been rejected, because this repository has exceeded its size limit.
```

[Housekeeping](../housekeeping.md) tasks may be causing your repository size to grow.
To resolve this problem, either of these options helps in the short- to middle-term:

- Increase the [repository size limit](#repository-size-limit).
- [Reduce the repository size](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size).
