---
type: reference, howto
---
# Custom password length limits

If you want to enforce longer user passwords you can create an extra Devise
initializer with the steps below.

If you do not use the `devise_password_length.rb` initializer the password
length is set to a minimum of 8 characters in `config/initializers/devise.rb`.

```bash
cd /home/git/gitlab
sudo -u git -H cp config/initializers/devise_password_length.rb.example config/initializers/devise_password_length.rb
sudo -u git -H editor config/initializers/devise_password_length.rb   # inspect and edit the new password length limits
```

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
