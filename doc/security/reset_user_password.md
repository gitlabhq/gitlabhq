---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# How to reset user password

There are a few ways to reset the password of a user.

## Rake Task

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/52347) in GitLab 13.9.

GitLab provides a Rake Task to reset passwords of users using their usernames,
which can be invoked by the following command:

```shell
sudo gitlab-rake "gitlab:password:reset"
```

GitLab asks for a username, a password, and a password confirmation. Upon giving
proper values for them, the password of the specified user is updated.

The Rake task also takes the username as an argument, as shown in the example
below:

```shell
sudo gitlab-rake "gitlab:password:reset[johndoe]"
```

NOTE:
To reset the default admin password, run this Rake task with the username
`root`, which is the default username of that admin account.

## Rails console

The Rake task is capable of finding users via their usernames. However, if only
user ID or email ID of the user is known, Rails console can be used to find user
using user ID and then change password of the user manually.

1. [Start a Rails console](../administration/operations/rails_console.md)

1. Find the user either by username, user ID or email ID:

    ```ruby
    user = User.find_by_username 'exampleuser'

    #or

    user = User.find(123)

    #or

    user = User.find_by(email: 'user@example.com')
    ```

1. Reset the password

    ```ruby
    user.password = 'secret_pass'
    user.password_confirmation = 'secret_pass'
    ```

1. When using this method instead of the [Users API](../api/users.md#user-modification),
   GitLab sends an email to the user stating that the user changed their
   password. If the password was changed by an administrator, execute the
   following command to notify the user by email:

    ```ruby
    user.send_only_admin_changed_your_password_notification!
    ```

1. Save the changes:

    ```ruby
    user.save!
    ```

1. Exit the console, and then try to sign in with your new password.

NOTE:
You can also reset passwords by using the [Users API](../api/users.md#user-modification).

## Password reset does not appear to work

If you can't sign on with the new password, it might be because of the [reconfirmation feature](../user/upgrade_email_bypass.md).

Try fixing this on the rails console. For example, if your new `root` password isn't working:

1. [Start a Rails console](../administration/operations/rails_console.md).

1. Find the user and skip reconfirmation, using any of the methods above:

    ```ruby
    user = User.find(1)
    user.skip_reconfirmation!
    ```

1. Try to sign in again.

## Reset your root password

The previously described steps can also be used to reset the root password.

In normal installations where the username of root account hasn't been changed
manually, the Rake task can be used with username `root` to reset the root
password.

If the username was changed to something else and has been forgotten, one
possible way is to reset the password using Rails console with user ID `1` (in
almost all the cases, the first user is the default admin account).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
