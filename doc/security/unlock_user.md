# How to unlock a locked user

Log into your server with root privileges. Then start a Ruby on Rails console.

Start the console with this command:

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
