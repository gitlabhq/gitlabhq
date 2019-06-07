---
type: howto
---
# How to reset your root password

To reset your root password, first log into your server with root privileges.

Start a Ruby on Rails console with this command:

```bash
gitlab-rails console production
```

Wait until the console has loaded.

There are multiple ways to find your user. You can search for email or username.

```bash
user = User.where(id: 1).first
```

or

```bash
user = User.find_by(email: 'admin@local.host')
```

Now you can change your password:

```bash
user.password = 'secret_pass'
user.password_confirmation = 'secret_pass'
```

It's important that you change both password and password_confirmation to make it work.

Don't forget to save the changes.

```bash
user.save!
```

Exit the console and try to login with your new password.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
