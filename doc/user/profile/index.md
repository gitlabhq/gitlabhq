---
type: index, howto
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# User account **(FREE)**

Each GitLab account has a user profile, which contains information about you and your GitLab activity.

Your profile also includes settings, which you use to customize your GitLab experience.

## Access your user profile

To access your profile:

1. On the top bar, in the top-right corner, select your avatar.
1. Select your name or username.

## Access your user settings

To access your user settings:

1. On the top bar, in the top-right corner, select your avatar.
1. Select **Edit profile**.

## Change your username

Your username has a unique [namespace](../namespace/index.md),
which is updated when you change your username. Before you change your username, read about
[how redirects behave](../project/repository/index.md#what-happens-when-a-repository-path-changes).
If you do not want to update the namespace, you can create a new user or group and transfer projects to it instead.

Prerequisites:

- Your namespace cannot contain a project with [Container Registry](../packages/container_registry/index.md) tags.
- Your namespace cannot have a project that hosts [GitLab Pages](../project/pages/index.md). For more information,
  see [this procedure in the GitLab Team Handbook](https://about.gitlab.com/handbook/tools-and-tips/#change-your-username-at-gitlabcom).

To change your username:

1. On the top bar, in the top-right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Account**.
1. In the **Change username** section, enter a new username as the path.
1. Select **Update username**.

## Add emails to your user profile

To add new email to your account:

1. On the top bar, in the top-right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Emails**.
1. In the **Email** text box, enter the new email.
1. Select **Add email address**.
1. Verify your email address with the verification email received.

## Make your user profile page private

You can make your user profile visible to only you and GitLab administrators.

To make your profile private:

1. On the top bar, in the top-right corner, select your avatar.
1. Select **Edit profile**.
1. Select the **Private profile** checkbox.
1. Select **Update profile settings**.

The following is hidden from your user profile page (`https://gitlab.example.com/username`):

- Atom feed
- Date when account was created
- Tabs for activity, groups, contributed projects, personal projects, starred projects, snippets

NOTE:
Making your user profile page private does not hide all your public resources from
the REST or GraphQL APIs. For example, the email address associated with your commit
signature is accessible unless you [use an automatically-generated private commit email](#use-an-automatically-generated-private-commit-email).

### User visibility

The public page of a user, located at `/username`, is always visible whether you are signed-in or
not.

When visiting the public page of a user, you can only see the projects which you have privileges to.

If the [public level is restricted](../admin_area/settings/visibility_and_access_controls.md#restrict-visibility-levels),
user profiles are only visible to signed-in users.

## Add details to your profile with a README

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/232157) in GitLab 14.5.

You can add more information to your profile page with a README file. When you populate
the README file with information, it's included on your profile page.

### From a new project

To create a new project and add its README to your profile:

1. On the top bar, select **Main menu > Projects > View all projects**.
1. On the right of the page, select **New project**.
1. Select **Create blank project**.
1. Enter the project details:
   - In the **Project name** field, enter the name for your new project.
   - In the **Project URL** field, select your GitLab username.
   - In the **Project slug** field, enter your GitLab username.
1. For **Visibility Level**, select **Public**.
   ![Proper project path for an individual on the hosted product](img/personal_readme_setup_v14_5.png)
1. For **Project Configuration**, ensure **Initialize repository with a README** is selected.
1. Select **Create project**.
1. Create a README file inside this project. The file can be any valid [README or index file](../project/repository/index.md#readme-and-index-files).
1. Populate the README file with [Markdown](../markdown.md), or another [supported markup language](../project/repository/index.md#supported-markup-languages).

GitLab displays the contents of your README below your contribution graph.

### From an existing project

To add the README from an existing project to your profile,
[update the path](../project/settings/index.md#rename-a-repository) of the project
to match your username.

## Add external accounts to your user profile page

You can add links to certain other external accounts you might have, like Skype and Twitter.
They can help other users connect with you on other platforms.

To add links to other accounts:

1. On the top bar, in the top-right corner, select your avatar.
1. Select **Edit profile**.
1. In the **Main settings** section, add your information from:
   - Skype
   - LinkedIn
   - Twitter
1. Select **Update profile settings**.

## Show private contributions on your user profile page

In the user contribution calendar graph and recent activity list, you can see your [contribution actions](contributions_calendar.md#user-contribution-events) to private projects.

To show private contributions:

1. On the top bar, in the top-right corner, select your avatar.
1. Select **Edit profile**.
1. In the **Main settings** section, select the **Include private contributions on my profile** checkbox.
1. Select **Update profile settings**.

## Add your gender pronouns

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332405) in GitLab 14.0.

You can add your gender pronouns to your GitLab account to be displayed next to
your name in your profile.

To specify your pronouns:

1. On the top bar, in the top-right corner, select your avatar.
1. Select **Edit profile**.
1. In the **Pronouns** text box, enter your pronouns.
1. Select **Update profile settings**.

## Add your name pronunciation

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/25742) in GitLab 14.2.

You can add your name pronunciation to your GitLab account. This is displayed in your profile, below
your name.

To add your name pronunciation:

1. On the top bar, in the top-right corner, select your avatar.
1. Select **Edit profile**.
1. In the **Pronunciation** text box, enter how your name is pronounced.
1. Select **Update profile settings**.

## Set your current status

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/56649) in GitLab 13.10, users can schedule the clearing of their status.

You can provide a custom status message for your user profile along with an emoji that describes it.
This may be helpful when you are out of office or otherwise not available.

Your status is publicly visible even if your [profile is private](#make-your-user-profile-page-private).

To set your current status:

1. On the top bar, in the top-right corner, select your avatar.
1. Select **Set status** or, if you have already set a status, **Edit status**.
1. Set the desired emoji and status message. Status messages must be plain text and 100 characters or less.
   They can also contain emoji codes like, `I'm on vacation :palm_tree:`.
1. Select a value from the **Clear status after** dropdown list.
1. Select **Set status**. Alternatively, you can select **Remove status** to remove your user status entirely.

You can also set your current status from [your user settings](#access-your-user-settings) or by [using the API](../../api/users.md#user-status).

If you select the **Busy** checkbox, remember to clear it when you become available again.

## Set a busy status indicator

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/259649) in GitLab 13.6.
> - It was [deployed behind a feature flag](../feature_flags.md), disabled by default.
> - [Became enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/281073) in GitLab 13.8.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/329163) in GitLab 13.12.

To indicate to others that you are busy, you can set an indicator.

To set the busy status indicator, either:

- Set it directly:
  1. On the top bar, in the top-right corner, select your avatar.
  1. Select **Set status** or, if you have already set a status, **Edit status**.
  1. Select the **Set yourself as busy** checkbox.

- Set it on your profile:
  1. On the top bar, in the top-right corner, select your avatar.
  1. Select **Edit profile**.
  1. In the **Current status** section, select the **Set yourself as busy** checkbox.

  The busy status is displayed in the user interface.

  Username:

  | Profile page | Settings menu | User popovers |
  | --- | --- | --- |
  | ![Busy status - profile page](img/busy_indicator_profile_page_v13_6.png) | ![Busy status - settings menu](img/busy_indicator_settings_menu_v13_6.png) | ![Busy status - user popovers](img/busy_indicator_user_popovers_v13_6.png) |

  Issue and merge request sidebar:

  | Sidebar| Collapsed sidebar |
  | --- | --- |
  | ![Busy status - sidebar](img/busy_indicator_sidebar_v13_9.png) | ![Busy status - sidebar collapsed](img/busy_indicator_sidebar_collapsed_v13_9.png) |

  Notes:

  | Notes | Note headers |
  | --- | --- |
  | ![Busy status - notes](img/busy_indicator_notes_v13_9.png) | ![Busy status - note header](img/busy_indicator_note_header_v13_9.png) |

## Set your time zone

You can set your local time zone to:

- Display your local time on your profile, and in places where hovering over your name shows information about you.
- Align your contribution calendar with your local time to better reflect when your contributions were made
  ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/335343) in GitLab 14.5).

To set your time zone:

1. On the top bar, in the top-right corner, select your avatar.
1. Select **Edit profile**.
1. In the **Time settings** section, select your time zone from the dropdown list.

## Change the email displayed on your commits

A commit email is an email address displayed in every Git-related action carried out through the GitLab interface.

Any of your own verified email addresses can be used as the commit email.
Your primary email is used by default.

To change your commit email:

1. In the top-right corner, select your avatar.
1. Select **Edit profile**.
1. In the **Commit email** dropdown list, select an email address.
1. Select **Update profile settings**.

## Change your primary email

Your primary email:

- Is the default email address for your login, commit email, and notification email.
- Must be already [linked to your user profile](#add-emails-to-your-user-profile).

To change your primary email:

1. In the top-right corner, select your avatar.
1. Select **Edit profile**.
1. In the **Email** field, enter your new email address.
1. Select **Update profile settings**.

## Set your public email

You can select one of your [configured email addresses](#add-emails-to-your-user-profile) to be displayed on your public profile:

1. In the top-right corner, select your avatar.
1. Select **Edit profile**.
1. In the **Public email** field, select one of the available email addresses.
1. Select **Update profile settings**.

### Use an automatically-generated private commit email

GitLab provides an automatically-generated private commit email address,
so you can keep your email information private.

To use a private commit email:

1. On the top bar, in the top-right corner, select your avatar.
1. Select **Edit profile**.
1. In the **Commit email** dropdown list, select **Use a private email**.
1. Select **Update profile settings**.

Every Git-related action uses the private commit email.

To stay fully anonymous, you can also copy the private commit email
and configure it on your local machine by using the following command:

```shell
git config --global user.email <your email address>
```

## User activity

GitLab tracks [user contribution activity](contributions_calendar.md). You can follow or unfollow other users from either:

- Their [user profiles](#access-your-user-profile).
- The small popover that appears when you hover over a user's name ([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/76050)
  in GitLab 15.0).

In [GitLab 15.5 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/360755),
the maximum number of users you can follow is 300.

To view a user's activity in a top-level Activity view:

1. From a user's profile, select **Follow**.
1. In the GitLab menu, select **Activity**.
1. Select the **Followed users** tab.

## Troubleshooting

### Why do you keep getting signed out?

When you sign in to the main GitLab application, a `_gitlab_session` cookie is
set. When you close your browser, the cookie is cleared client-side
and it expires after a set duration. GitLab administrators can determine the duration:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > General**.
1. Expand **Account and limit**. The set duration is in **Session duration (minutes)**.

The default is `10080`, which equals 7 days.

When you sign in to the main GitLab application, you can also check the
**Remember me** option. This sets the `remember_user_token`
cookie via [`devise`](https://github.com/heartcombo/devise).
The `remember_user_token` cookie expires after
`config/initializers/devise.rb` -> `config.remember_for`. The default is 2 weeks.

When the `_gitlab_session` expires or isn't available, GitLab uses the `remember_user_token`
to get you a new `_gitlab_session` and keep you signed in through browser restarts.

After your `remember_user_token` expires and your `_gitlab_session` is cleared/expired,
you are asked to sign in again to verify your identity for security reasons.

NOTE:
When any session is signed out, or when a session is revoked
via [Active Sessions](active_sessions.md), all **Remember me** tokens are revoked.
While other sessions remain active, the **Remember me** feature doesn't restore
a session if the browser is closed or the existing session expires.

### Increased sign-in time

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/20340) in GitLab 13.1.

The `remember_user_token` lifetime of a cookie can now extend beyond the deadline set by `config.remember_for`, as the `config.extend_remember_period` flag is now set to true.

GitLab uses both session and persistent cookies:

- Session cookie: Session cookies are normally removed at the end of the browser session when
  the browser is closed. The `_gitlab_session` cookie has no fixed expiration date. However,
  it expires based on its [`session_expire_delay`](#why-do-you-keep-getting-signed-out).
- Persistent cookie: The `remember_user_token` is a cookie with an expiration date of two weeks.
  GitLab activates this cookie if you select **Remember Me** when you sign in.

By default, the server sets a time-to-live (TTL) of 1-week on any session that is used.

When you close a browser, the session cookie may still remain. For example, Chrome has the "Continue where you left off" option that restores session cookies.
In other words, as long as you access GitLab at least once every 2 weeks, you could remain signed in with GitLab, as long as your browser tab is open.
The server continues to reset the TTL for that session, independent of whether 2FA is installed,
If you close your browser and open it up again, the `remember_user_token` cookie allows your user to reauthenticate itself.

Without the `config.extend_remember_period` flag, you would be forced to sign in again after two weeks.

## Related topics

- [Create users](account/create_accounts.md)
- [Sign in to your GitLab account](../../topics/authentication/index.md)
- [Change your password](user_passwords.md)
- Receive emails for:
  - [Sign-ins from unknown IP addresses or devices](notifications.md#notifications-for-unknown-sign-ins)
  - [Attempted sign-ins using wrong two-factor authentication codes](notifications.md#notifications-for-attempted-sign-in-using-wrong-two-factor-authentication-codes)
- Manage applications that can [use GitLab as an OAuth provider](../../integration/oauth_provider.md)
- Manage [personal access tokens](personal_access_tokens.md) to access your account via API and authorized applications
- Manage [SSH keys](../ssh.md) to access your account via SSH
- Change your [syntax highlighting theme](preferences.md#syntax-highlighting-theme)
- [View your active sessions](active_sessions.md) and revoke any of them if necessary
