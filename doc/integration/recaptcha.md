---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: reCAPTCHA
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

GitLab leverages [reCAPTCHA](https://www.google.com/recaptcha/about/)
to protect against spam and abuse. GitLab displays the CAPTCHA form on the sign-up page
to confirm that a real user, not a bot, is attempting to create an account.

## Configuration

To use reCAPTCHA, first create a site and private key.

1. Go to the [Google reCAPTCHA page](https://www.google.com/recaptcha/admin).
1. To get reCAPTCHA v2 keys, fill in the form and select **Submit**.
1. Sign in to your GitLab server as an administrator.
1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Reporting**.
1. Expand **Spam and Anti-bot Protection**.
1. In the reCAPTCHA fields, enter the keys you obtained in the previous steps.
1. Select the **Enable reCAPTCHA** checkbox.
1. To enable reCAPTCHA for logins via password, select the **Enable reCAPTCHA for login** checkbox.
1. Select **Save changes**.
1. To short-circuit the spam check and trigger the response to return `recaptcha_html`:
   1. Open `app/services/spam/spam_verdict_service.rb`.
   1. Change the first line of the `#execute` method to `return CONDITIONAL_ALLOW`.

NOTE:
Make sure you are viewing an issuable in a project that is public. If you're working with an issue, the issue is public.

## Enable reCAPTCHA for user logins using the HTTP header

You can enable reCAPTCHA for user logins via password [in the user interface](#configuration)
or by setting the `X-GitLab-Show-Login-Captcha` HTTP header.
For example, in NGINX, this can be done via the `proxy_set_header`
configuration variable:

```nginx
proxy_set_header X-GitLab-Show-Login-Captcha 1;
```

In Omnibus GitLab, this can be configured via `/etc/gitlab/gitlab.rb`:

```ruby
nginx['proxy_set_headers'] = { 'X-GitLab-Show-Login-Captcha' => '1' }
```
