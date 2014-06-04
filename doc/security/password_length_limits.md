# Custom password length limits

If you want to enforce longer user passwords you can create an extra Devise initializer with the steps below.

If you do not use the `devise_password_length.rb` initializer the password length is set to a minimum of 8 characters in `config/initializers/devise.rb`.

```bash
cd /home/git/gitlab
sudo -u git -H cp config/initializers/devise_password_length.rb.example config/initializers/devise_password_length.rb
sudo -u git -H editor config/initializers/devise_password_length.rb   # inspect and edit the new password length limits
```
