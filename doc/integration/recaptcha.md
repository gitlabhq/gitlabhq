# reCAPTCHA

GitLab leverages [Google's reCAPTCHA](https://www.google.com/recaptcha/intro/index.html)
to protect against spam and abuse. GitLab displays the CAPTCHA form on the sign-up page
to confirm that a real user, not a bot, is attempting to create an account.

## Configuration

To use reCAPTCHA, first you must create a site and private key.

1. Go to the URL: https://www.google.com/recaptcha/admin

2. Fill out the form necessary to obtain reCAPTCHA keys.

3. Login to your GitLab server, with administrator credentials.

4. Go to Applications Settings on Admin Area (`admin/application_settings`)

5. Fill all recaptcha fields with keys from previous steps

6. Check the `Enable reCAPTCHA` checkbox

7.  Save the configuration.
