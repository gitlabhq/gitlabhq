---
type: howto
---
# How to unlock a locked user

To unlock a locked user, first log into your server with root privileges.

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

Unlock the user:

```bash
user.unlock_access!
```

Exit the console, the user should now be able to log in again.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
