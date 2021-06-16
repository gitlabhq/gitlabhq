---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# How to unlock a locked user from the command line **(FREE SELF)**

After ten failed login attempts a user gets in a locked state.

To unlock a locked user:

1. SSH into your GitLab server.
1. Start a Ruby on Rails console:

   ```shell
   ## For Omnibus GitLab
   sudo gitlab-rails console -e production

   ## For installations from source
   sudo -u git -H bundle exec rails console -e production
   ```

1. Find the user to unlock. You can search by email or ID.

   ```ruby
   user = User.find_by(email: 'admin@local.host')
   ```

   or

   ```ruby
   user = User.where(id: 1).first
   ```

1. Unlock the user:

   ```ruby
   user.unlock_access!
   ```

1. Exit the console with <kbd>Control</kbd>+<kbd>d</kbd>

The user should now be able to log in.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
