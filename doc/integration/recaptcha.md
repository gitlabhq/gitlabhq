# reCAPTCHA

GitLab leverages [Google's reCAPTCHA](https://www.google.com/recaptcha/intro/index.html)
to protect against spam and abuse. GitLab displays the CAPTCHA form on the sign-up page
to confirm that a real user, not a bot, is attempting to create an account.

## Configuration

To use reCAPTCHA, first you must create a site and private key.

1. Go to the URL: <https://www.google.com/recaptcha/admin>.
1. Fill out the form necessary to obtain reCAPTCHA v2 keys.
1. Log in to your GitLab server, with administrator credentials.
1. Go to Reporting Applications Settings in the Admin Area (`admin/application_settings/reporting`).
1. Fill all reCAPTCHA fields with keys from previous steps.
1. Check the `Enable reCAPTCHA` checkbox.
1. Save the configuration.

## Enabling reCAPTCHA for user logins via passwords

By default, reCAPTCHA is only enabled for user registrations. To enable it for
user logins via passwords, the `X-GitLab-Show-Login-Captcha` HTTP header must
be set. For example, in NGINX, this can be done via the `proxy_set_header`
configuration variable:

```nginx
proxy_set_header X-GitLab-Show-Login-Captcha 1;
```

In Omnibus GitLab, this can be configured via `/etc/gitlab/gitlab.rb`:

```ruby
nginx['proxy_set_headers'] = { 'X-GitLab-Show-Login-Captcha' => 1 }
```
