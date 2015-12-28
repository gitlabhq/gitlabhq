# reCAPTCHA

GitLab leverages [Google's reCAPTCHA](https://www.google.com/recaptcha/intro/index.html)
to protect against spam and abuse. GitLab displays the CAPTCHA form on the sign-up page
to confirm that a real user, not a bot, is attempting to create an account.

## Configuration

To use reCAPTCHA, first you must create a public and private key.

1. Go to the URL: https://www.google.com/recaptcha/admin

1. Fill out the form necessary to obtain reCAPTCHA keys.

1. On your GitLab server, open the configuration file.

    For omnibus package:

    ```sh
      sudo editor /etc/gitlab/gitlab.rb
    ```

    For installations from source:

    ```sh
      cd /home/git/gitlab

      sudo -u git -H editor config/gitlab.yml
    ```

1.  Enable reCAPTCHA and add the settings:

    For omnibus package:

    ```ruby
      gitlab_rails['recaptcha_enabled'] = true
      gitlab_rails['recaptcha_public_key'] = 'YOUR_PUBLIC_KEY'
      gitlab_rails['recaptcha_private_key'] = 'YOUR_PUBLIC_KEY'
    ```

    For installation from source:

    ```
      recaptcha:
        enabled: true
        public_key: 'YOUR_PUBLIC_KEY'
        private_key: 'YOUR_PRIVATE_KEY'
    ```

1.  Change 'YOUR_PUBLIC_KEY' to the public key from step 2.

1.  Change 'YOUR_PRIVATE_KEY' to the private key from step 2.

1.  Save the configuration file.

1.  Restart GitLab.
