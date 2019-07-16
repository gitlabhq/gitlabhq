---
type: reference, howto
---

# Custom password length limits

The user password length is set to a minimum of 8 characters by default.
To change that for installations from source:

1. Edit `devise_password_length.rb`:

   ```sh
   cd /home/git/gitlab
   sudo -u git -H cp config/initializers/devise_password_length.rb.example config/initializers/devise_password_length.rb
   sudo -u git -H editor config/initializers/devise_password_length.rb
   ```

1. Change the new password length limits:

   ```ruby
   config.password_length = 12..128
   ```

   In this example, the minimum length is 12 characters, and the maximum length
   is 128 characters.

1. [Restart GitLab](../administration/restart_gitlab.md#installations-from-source)
   for the changes to take effect.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
