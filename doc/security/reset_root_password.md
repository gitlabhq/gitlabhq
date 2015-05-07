# How to reset your root password:

Log into your server with root privileges. Then start a Ruby on Rails console.

Start the console with this command:

```bash
gitlab-rails console production
```

Wait until the console has loaded.

There are multiple ways to find your user. You can search for email or username.

```bash
irb(main):001:0> u = User.where(id: 1).first
```

or

```bash
user = User.find_by(email: 'admin@local.host')
```

Now you can change your password:

```bash
u.password = 'secret_pass'
u.password_confirmation = 'secret_pass'
```

It's important that you change both password and password_confirmation to make it work.

Don't forget to save the changes.

```bash
u.save!
```

Exit the console and try to login with your new password.