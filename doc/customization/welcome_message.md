# Customize the complete sign-in page (GitLab Enterprise Edition only)

Please see [Branded login page](http://doc.gitlab.com/ee/customization/branded_login_page.html)

# Add a welcome message to the sign-in page (GitLab Community Edition)

It is possible to add a markdown-formatted welcome message to your GitLab
sign-in page. Users of GitLab Enterprise Edition should use the [branded login
page feature](/ee/customization/branded_login_page.html) instead.

## Omnibus-gitlab example

In `/etc/gitlab/gitlab.rb`:

```ruby
gitlab_rails['extra_sign_in_text'] = <<'EOS'
# ACME GitLab
Welcome to the [ACME](http://www.example.com) GitLab server!
EOS
```

Run `sudo gitlab-ctl reconfigure` for changes to take effect.

## Installation from source

In `/home/git/gitlab/config/gitlab.yml`:

```yaml
# snip
production:
  # snip
  extra:
    sign_in_text: |
      # ACME GitLab
      Welcome to the [ACME](http://www.example.com) GitLab server!
```      

Run `sudo service gitlab reload` for the change to take effect.
