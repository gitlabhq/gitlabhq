---
type: reference, howto
---

# Custom password length limits

By default, GitLab supports passwords with:

- A minimum length of 8.
- A maximum length of 128.

GitLab administrators can modify password lengths:

- Using configuration file.
- [From](https://gitlab.com/gitlab-org/gitlab/merge_requests/20661) GitLab 12.6, using the GitLab UI.

## Modify maximum password length using configuration file

The user password length is set to a maximum of 128 characters by default.
To change that for installations from source:

1. Edit `devise_password_length.rb`:

   ```sh
   cd /home/git/gitlab
   sudo -u git -H cp config/initializers/devise_password_length.rb.example config/initializers/devise_password_length.rb
   sudo -u git -H editor config/initializers/devise_password_length.rb
   ```

1. Change the new password length limits:

   ```ruby
   config.password_length = 12..135
   ```

   In this example, the minimum length is 12 characters, and the maximum length
   is 135 characters.

1. [Restart GitLab](../administration/restart_gitlab.md#installations-from-source)
   for the changes to take effect.

NOTE: **Note:**
From GitLab 12.6, the minimum password length set in this configuration file will be ignored. Minimum password lengths will now have to be modified via the [GitLab UI](#modify-minimum-password-length-using-gitlab-ui) instead.

## Modify minimum password length using GitLab UI

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/20661) in GitLab 12.6

The user password length is set to a minimum of 8 characters by default.
To change that using GitLab UI:

In **Admin Area > Settings** (`/admin/application_settings`), go to the section **Sign-up restrictions**.

[Minimum password length settings](../user/admin_area/img/minimum_password_length_settings_v12_6.png)

Set the **Minimum password length** to a value greater than or equal to 8 and hit **Save changes** to save the changes.

CAUTION: **Caution:**
Changing minimum or maximum limit does not affect existing user passwords in any manner. Existing users will not be asked to reset their password to adhere to the new limits.
The new limit restriction will only apply during new user sign-ups and when an existing user performs a password reset.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
