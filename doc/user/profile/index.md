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

1. On the top bar, in the upper-right corner, select your avatar.
1. Select your name or username.

## Access your user settings

To access your user settings:

1. On the top bar, in the upper-right corner, select your avatar.
1. Select **Edit profile**.

## Change your username

Your username has a unique [namespace](../namespace/index.md),
which is updated when you change your username. Before you change your username, read about
[how redirects behave](../project/repository/index.md#what-happens-when-a-repository-path-changes).
If you do not want to update the namespace, you can create a new user or group and transfer projects to it instead.

Prerequisites:

- Your namespace must not:
  - Contain a project with [Container Registry](../packages/container_registry/index.md) tags.
  - Have a project that hosts [GitLab Pages](../project/pages/index.md). For more information,
  see [changing your username in the GitLab Team Handbook](https://about.gitlab.com/handbook/tools-and-tips/#change-your-username-at-gitlabcom).
- Your username must be between 2 and 255 characters in length, and must not:
  - Contain special characters or emojis.
  - End with `.<reserved file extension>`, for example `jon.png`. However, `jonpng` is valid.

To change your username:

1. On the top bar, in the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Account**.
1. In the **Change username** section, enter a new username as the path.
1. Select **Update username**.

## Add emails to your user profile

To add new email to your account:

1. On the top bar, in the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Emails**.
1. In the **Email** text box, enter the new email.
1. Select **Add email address**.
1. Verify your email address with the verification email received.

## Make your user profile page private

You can make your user profile visible to only you and GitLab administrators.

To make your profile private:

1. On the top bar, in the upper-right corner, select your avatar.
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
user profiles are only visible to authenticated users.

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

1. On the top bar, in the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. In the **Main settings** section, add your:
   - Discord [user ID](https://support.discord.com/hc/en-us/articles/206346498-Where-can-I-find-my-User-Server-Message-ID-).
   - LinkedIn profile name.
   - Skype username.
   - Twitter @username.

   Your user ID or username must be 500 characters or less.
1. Select **Update profile settings**.

## Show private contributions on your user profile page

In the user contribution calendar graph and recent activity list, you can see your [contribution actions](contributions_calendar.md#user-contribution-events) to private projects.

To show private contributions:

1. On the top bar, in the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. In the **Main settings** section, select the **Include private contributions on my profile** checkbox.
1. Select **Update profile settings**.

## Add your gender pronouns

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332405) in GitLab 14.0.

You can add your gender pronouns to your GitLab account to be displayed next to
your name in your profile.

To specify your pronouns:

1. On the top bar, in the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. In the **Pronouns** text box, enter your pronouns. The text must be 50 characters or less.
1. Select **Update profile settings**.

## Add your name pronunciation

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/25742) in GitLab 14.2.

You can add your name pronunciation to your GitLab account. This is displayed in your profile, below
your name.

To add your name pronunciation:

1. On the top bar, in the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. In the **Pronunciation** text box, enter how your name is pronounced. The pronunciation must be plain text and 255 characters or less.
1. Select **Update profile settings**.

## Set your current status

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/56649) in GitLab 13.10, users can schedule the clearing of their status.

You can provide a custom status message for your user profile along with an emoji that describes it.
This may be helpful when you are out of office or otherwise not available.

Your status is publicly visible even if your [profile is private](#make-your-user-profile-page-private).

To set your current status:

1. On the top bar, in the upper-right corner, select your avatar.
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
  1. On the top bar, in the upper-right corner, select your avatar.
  1. Select **Set status** or, if you have already set a status, **Edit status**.
  1. Select the **Set yourself as busy** checkbox.

- Set it on your profile:
  1. On the top bar, in the upper-right corner, select your avatar.
  1. Select **Edit profile**.
  1. In the **Current status** section, select the **Set yourself as busy** checkbox.

  The busy status is displayed next to your name, every time your name is shown in the user interface.

## Set your time zone

You can set your local time zone to:

- Display your local time on your profile, and in places where hovering over your name shows information about you.
- Align your contribution calendar with your local time to better reflect when your contributions were made
  ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/335343) in GitLab 14.5).

To set your time zone:

1. On the top bar, in the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. In the **Time settings** section, select your time zone from the dropdown list.

## Change the email displayed on your commits

A commit email is an email address displayed in every Git-related action carried out through the GitLab interface.

Any of your own verified email addresses can be used as the commit email.
Your primary email is used by default.

To change your commit email:

1. In the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. In the **Commit email** dropdown list, select an email address.
1. Select **Update profile settings**.

## Change your primary email

Your primary email is the default email address for your login, commit email, and notification email.

To change your primary email:

1. In the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. In the **Email** field, enter your new email address.
1. Select **Update profile settings**.
1. Optional. Select the confirmation email if you have not previously added this email to your GitLab.com account.

## Set your public email

You can select one of your [configured email addresses](#add-emails-to-your-user-profile) to be displayed on your public profile:

1. In the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. In the **Public email** field, select one of the available email addresses.
1. Select **Update profile settings**.

### Use an automatically-generated private commit email

GitLab provides an automatically-generated private commit email address,
so you can keep your email information private.

To use a private commit email:

1. On the top bar, in the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. In the **Commit email** dropdown list, select **Use a private email**.
1. Select **Update profile settings**.

Every Git-related action uses the private commit email.

To stay fully anonymous, you can also copy the private commit email
and configure it on your local machine by using the following command:

```shell
git config --global user.email <your email address>
```

## Follow users

You can follow or unfollow users from either:

- Their [user profiles](#access-your-user-profile).
- The small popover that appears when you hover over a user's name ([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/76050)
  in GitLab 15.0).

In [GitLab 15.5 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/360755),
the maximum number of users you can follow is 300.

## View your activity

GitLab tracks [user contribution activity](contributions_calendar.md).
To view a summary of your activity, or the activity of other users:

1. From a user's profile, select **Follow**.
1. In the GitLab menu, select **Activity**.
1. Select the **Followed users** tab.

## Stay signed in for two weeks

By default, you are signed out of GitLab every seven days, or 10080 minutes.
GitLab administrators can
[change this default](../admin_area/settings/account_and_limit_settings.md#customize-the-default-session-duration).

To extend the duration to two weeks:

- On the GitLab sign-in page, select the **Remember me** checkbox.

## Stay signed in indefinitely

To remain signed in indefinitely:

1. On the GitLab sign-in page, select the **Remember me** checkbox.
1. Access GitLab at least once every two weeks, and leave your browser open.

You remain signed in because, although the server sets a time-to-live (TTL) of one week on your browser session,
the server continues to reset the TTL, regardless of whether 2FA is installed.

### Cookies used for sign-in

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/20340) in GitLab 13.1.

When you sign in, three cookies are set:

- A session cookie called `_gitlab_session`.
  This cookie has no set expiration date. However, it expires based on its `session_expire_delay`.
- A session cookied called `about_gitlab_active_user`.
  This cookie is used by the [marketing site](https://about.gitlab.com/) to determine if a user has an active GitLab session. No user information is passed to the cookie and it expires with the session.
- A persistent cookie called `remember_user_token`, which is set only if you selected **Remember me** on the sign-in page.

When you close your browser, the `_gitlab_session` and `about_gitlab_active_user` cookies are usually cleared client-side.
When it expires or isn't available, GitLab:

- Uses the `remember_user_token`cookie to get you a new `_gitlab_session` cookie and keep you signed in, even if you close your browser.
- Sets the `about_gitlab_active_user` to `true`.

When both the `remember_user_token` and `_gitlab_session` cookies are gone or expired, you must sign in again.

NOTE:
When any session is signed out, or when a session is revoked
from the [active sessions list](active_sessions.md), all **Remember me** tokens are revoked.
While other sessions remain active, the **Remember me** feature doesn't restore
a session if the browser is closed or the existing session expires.

## Related topics

- [Create users](account/create_accounts.md)
- [Sign in to your GitLab account](../../topics/authentication/index.md)
- [Change your password](user_passwords.md)
- Receive emails for:
  - [Sign-ins from unknown IP addresses or devices](notifications.md#notifications-for-unknown-sign-ins)
  - [Attempted sign-ins using incorrect verification codes](notifications.md#notifications-for-attempted-sign-ins-using-incorrect-verification-codes)
- Manage applications that can [use GitLab as an OAuth provider](../../integration/oauth_provider.md)
- Manage [personal access tokens](personal_access_tokens.md) to access your account via API and authorized applications
- Manage [SSH keys](../ssh.md) to access your account via SSH
- Change your [syntax highlighting theme](preferences.md#syntax-highlighting-theme)
- [View your active sessions](active_sessions.md) and revoke any of them if necessary
