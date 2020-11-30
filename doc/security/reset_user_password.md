---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# How to reset user password

To reset the password of a user, first log into your server with root privileges.

Start a Ruby on Rails console with this command:

```shell
gitlab-rails console -e production
```

Wait until the console has loaded.

## Find the user

There are multiple ways to find your user. You can search by email or user ID number.

```shell
user = User.where(id: 7).first
```

or

```shell
user = User.find_by(email: 'user@example.com')
```

## Reset the password

Now you can change your password:

```shell
user.password = 'secret_pass'
user.password_confirmation = 'secret_pass'
```

It's important that you change both password and password_confirmation to make it work.

When using this method instead of the [Users API](../api/users.md#user-modification), GitLab sends an email to the user stating that the user changed their password.

If the password was changed by an administrator, execute the following command to notify the user by email:

```shell
user.send_only_admin_changed_your_password_notification!
```

Don't forget to save the changes.

```shell
user.save!
```

Exit the console, and then try to sign in with your new password.

NOTE: **Note:**
You can also reset passwords by using the [Users API](../api/users.md#user-modification).

### Reset your root password

The previously described steps can also be used to reset the root password. First,
identify the root user, with an `id` of `1`. To do so, run the following command:

```shell
user = User.where(id: 1).first
```

After finding the user, follow the steps mentioned in the [Reset the password](#reset-the-password) section to reset the password of the root user.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
