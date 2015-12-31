# Reply by email

GitLab can be set up to allow users to comment on issues and merge requests by replying to notification emails.

**Warning**: Do not enable Reply by email if you have **multiple GitLab application servers**. 
Due to an issue with the way incoming emails are read from the mail server, every incoming reply-by-email email will result in as many comments being created as you have application servers.
[A fix is being worked on.](https://github.com/tpitale/mail_room/issues/46)

## Get a mailbox

Reply by email requires an IMAP-enabled email account, with a provider or server that supports [email sub-addressing](https://en.wikipedia.org/wiki/Email_address#Sub-addressing). Sub-addressing is a feature where any email to `user+some_arbitrary_tag@example.com` will end up in the mailbox for `user@example.com`, and is supported by providers such as Gmail, Google Apps, Yahoo! Mail, Outlook.com and iCloud, as well as the Postfix mail server which you can run on-premises.

If you want to use Gmail / Google Apps with Reply by email, make sure you have [IMAP access enabled](https://support.google.com/mail/troubleshooter/1668960?hl=en#ts=1665018) and [allow less secure apps to access the account](https://support.google.com/accounts/answer/6010255).

To set up a basic Postfix mail server with IMAP access on Ubuntu, follow [these instructions](./postfix.md).

## Set it up

### Omnibus package installations

1. Find the `incoming_email` section in `/etc/gitlab/gitlab.rb`, enable the feature and fill in the details for your specific IMAP server and email account:

    ```ruby
<<<<<<< HEAD
<<<<<<< HEAD
    # Configuration for Postfix mail server, assumes mailbox incoming@gitlab.example.com
    gitlab_rails['incoming_email_enabled'] = true
    
    # The email address including a placeholder for the key that references the item being replied to.
    # The `%{key}` placeholder is added after the user part, before the `@`.
    gitlab_rails['incoming_email_address'] = "incoming+%{key}@gitlab.example.com"
    
    # Email account username
    # With third party providers, this is usually the full email address.
    # With self-hosted email servers, this is usually the user part of the email address.
    gitlab_rails['incoming_email_email'] = "incoming"
    # Email account password
    gitlab_rails['incoming_email_password'] = "[REDACTED]"
    
    # IMAP server host
    gitlab_rails['incoming_email_host'] = "gitlab.example.com"
    # IMAP server port
    gitlab_rails['incoming_email_port'] = 143
    # Whether the IMAP server uses SSL
    gitlab_rails['incoming_email_ssl'] = false
    # Whether the IMAP server uses StartTLS
    gitlab_rails['incoming_email_start_tls'] = false

    # The mailbox where incoming mail will end up. Usually "inbox".
    gitlab_rails['incoming_email_mailbox_name'] = "inbox"
    ```

    ```ruby
    # Configuration for Gmail / Google Apps, assumes mailbox gitlab-incoming@gmail.com
    gitlab_rails['incoming_email_enabled'] = true
    
    # The email address including the `%{key}` placeholder that will be replaced to reference the item being replied to.
    # The `%{key}` placeholder is added after the user part, after a `+` character, before the `@`.
    gitlab_rails['incoming_email_address'] = "gitlab-incoming+%{key}@gmail.com"
    
    # Email account username
    # With third party providers, this is usually the full email address.
    # With self-hosted email servers, this is usually the user part of the email address.
    gitlab_rails['incoming_email_email'] = "gitlab-incoming@gmail.com"
    # Email account password
    gitlab_rails['incoming_email_password'] = "[REDACTED]"
    
    # IMAP server host
    gitlab_rails['incoming_email_host'] = "imap.gmail.com"
    # IMAP server port
    gitlab_rails['incoming_email_port'] = 993
    # Whether the IMAP server uses SSL
    gitlab_rails['incoming_email_ssl'] = true
    # Whether the IMAP server uses StartTLS
    gitlab_rails['incoming_email_start_tls'] = false

    # The mailbox where incoming mail will end up. Usually "inbox".
    gitlab_rails['incoming_email_mailbox_name'] = "inbox"
    ```

=======
=======
>>>>>>> gitlabhq/revert-9758-fix/api-helpers-bad-autoload-name
    # Postfix mail server, assumes mailbox incoming@gitlab.example.com
    gitlab_rails['incoming_email_enabled'] = true
    gitlab_rails['incoming_email_address'] = "incoming+%{key}@gitlab.example.com"
    gitlab_rails['incoming_email_host'] = "gitlab.example.com" # IMAP server host
    gitlab_rails['incoming_email_port'] = 143 # IMAP server port
    gitlab_rails['incoming_email_ssl'] = false # Whether the IMAP server uses SSL
    gitlab_rails['incoming_email_email'] = "incoming"  # Email account username. Usually the full email address.
    gitlab_rails['incoming_email_password'] = "[REDACTED]" # Email account password
    gitlab_rails['incoming_email_mailbox_name'] = "inbox" # The name of the mailbox where incoming mail will end up. Usually "inbox".
    ```

    ```ruby
    # Gmail / Google Apps, assumes mailbox gitlab-incoming@gmail.com
    gitlab_rails['incoming_email_enabled'] = true
    gitlab_rails['incoming_email_address'] = "gitlab-incoming+%{key}@gmail.com"
    gitlab_rails['incoming_email_host'] = "imap.gmail.com" # IMAP server host
    gitlab_rails['incoming_email_port'] = 993 # IMAP server port
    gitlab_rails['incoming_email_ssl'] = true # Whether the IMAP server uses SSL
    gitlab_rails['incoming_email_email'] = "gitlab-incoming@gmail.com"  # Email account username. Usually the full email address.
    gitlab_rails['incoming_email_password'] = "[REDACTED]" # Email account password
    gitlab_rails['incoming_email_mailbox_name'] = "inbox" # The name of the mailbox where incoming mail will end up. Usually "inbox".
    ```

<<<<<<< HEAD
>>>>>>> origin/8-0-stable
=======
>>>>>>> gitlabhq/revert-9758-fix/api-helpers-bad-autoload-name
    As mentioned, the part after `+` in the address is ignored, and any email sent here will end up in the mailbox for `incoming@gitlab.example.com`/`gitlab-incoming@gmail.com`.

1. Reconfigure GitLab for the changes to take effect:

    ```sh
    sudo gitlab-ctl reconfigure
    ```

1. Verify that everything is configured correctly:

    ```sh
    sudo gitlab-rake gitlab:incoming_email:check
    ```

1. Reply by email should now be working.

### Installations from source

1. Go to the GitLab installation directory:

    ```sh
    cd /home/git/gitlab
    ```

1. Find the `incoming_email` section in `config/gitlab.yml`, enable the feature and fill in the details for your specific IMAP server and email account:

    ```sh
    sudo editor config/gitlab.yml
    ```

    ```yaml
<<<<<<< HEAD
<<<<<<< HEAD
    # Configuration for Postfix mail server, assumes mailbox incoming@gitlab.example.com
=======
    # Postfix mail server, assumes mailbox incoming@gitlab.example.com
    incoming_email:
      enabled: true
      address: "incoming+%{key}@gitlab.example.com"
    ```

    ```yaml
    # Gmail / Google Apps, assumes mailbox gitlab-incoming@gmail.com
>>>>>>> gitlabhq/revert-9758-fix/api-helpers-bad-autoload-name
    incoming_email:
      enabled: true
=======
    # Postfix mail server, assumes mailbox incoming@gitlab.example.com
    incoming_email:
      enabled: true
      address: "incoming+%{key}@gitlab.example.com"
    ```

<<<<<<< HEAD
    ```yaml
    # Gmail / Google Apps, assumes mailbox gitlab-incoming@gmail.com
    incoming_email:
      enabled: true
      address: "gitlab-incoming+%{key}@gmail.com"
    ```
=======
    As mentioned, the part after `+` in the address is ignored, and any email sent here will end up in the mailbox for `incoming@gitlab.example.com`/`gitlab-incoming@gmail.com`.

2. Copy `config/mail_room.yml.example` to `config/mail_room.yml`:
>>>>>>> gitlabhq/revert-9758-fix/api-helpers-bad-autoload-name

    As mentioned, the part after `+` in the address is ignored, and any email sent here will end up in the mailbox for `incoming@gitlab.example.com`/`gitlab-incoming@gmail.com`.
>>>>>>> origin/8-0-stable

      # The email address including the `%{key}` placeholder that will be replaced to reference the item being replied to.
      # The `%{key}` placeholder is added after the user part, after a `+` character, before the `@`.
      address: "incoming+%{key}@gitlab.example.com"

      # Email account username
      # With third party providers, this is usually the full email address.
      # With self-hosted email servers, this is usually the user part of the email address.
      user: "incoming"
      # Email account password
      password: "[REDACTED]"

      # IMAP server host
      host: "gitlab.example.com"
      # IMAP server port
      port: 143
      # Whether the IMAP server uses SSL
      ssl: false
      # Whether the IMAP server uses StartTLS
      start_tls: false

      # The mailbox where incoming mail will end up. Usually "inbox".
      mailbox: "inbox"
    ```

    ```yaml
<<<<<<< HEAD
    # Configuration for Gmail / Google Apps, assumes mailbox gitlab-incoming@gmail.com
    incoming_email:
      enabled: true

      # The email address including the `%{key}` placeholder that will be replaced to reference the item being replied to.
      # The `%{key}` placeholder is added after the user part, after a `+` character, before the `@`.
      address: "gitlab-incoming+%{key}@gmail.com"

      # Email account username
      # With third party providers, this is usually the full email address.
      # With self-hosted email servers, this is usually the user part of the email address.
      user: "gitlab-incoming@gmail.com"
      # Email account password
      password: "[REDACTED]"

      # IMAP server host
      host: "imap.gmail.com"
      # IMAP server port
      port: 993
      # Whether the IMAP server uses SSL
      ssl: true
      # Whether the IMAP server uses StartTLS
      start_tls: false

      # The mailbox where incoming mail will end up. Usually "inbox".
      mailbox: "inbox"
=======
    # Postfix mail server
    :mailboxes:
      -
        # IMAP server host
        :host: "gitlab.example.com"
        # IMAP server port
        :port: 143
        # Whether the IMAP server uses SSL
        :ssl: false
        # Whether the IMAP server uses StartTLS
        :start_tls: false
        # Email account username. Usually the full email address.
        :email: "incoming"
        # Email account password
        :password: "[REDACTED]"
        # The name of the mailbox where incoming mail will end up. Usually "inbox".
        :name: "inbox"
        # Always "sidekiq".
        :delivery_method: sidekiq
        # Always true.
        :delete_after_delivery: true
        :delivery_options:
          # The URL to the Redis server used by Sidekiq. Should match the URL in config/resque.yml.
          :redis_url: redis://localhost:6379
          # Always "resque:gitlab".
          :namespace: resque:gitlab
          # Always "incoming_email".
          :queue: incoming_email
          # Always "EmailReceiverWorker"
          :worker: EmailReceiverWorker
    ```

    ```yaml
<<<<<<< HEAD
=======
    # Postfix mail server
    :mailboxes:
      -
        # IMAP server host
        :host: "gitlab.example.com"
        # IMAP server port
        :port: 143
        # Whether the IMAP server uses SSL
        :ssl: false
        # Whether the IMAP server uses StartTLS
        :start_tls: false
        # Email account username. Usually the full email address.
        :email: "incoming"
        # Email account password
        :password: "[REDACTED]"
        # The name of the mailbox where incoming mail will end up. Usually "inbox".
        :name: "inbox"
        # Always "sidekiq".
        :delivery_method: sidekiq
        # Always true.
        :delete_after_delivery: true
        :delivery_options:
          # The URL to the Redis server used by Sidekiq. Should match the URL in config/resque.yml.
          :redis_url: redis://localhost:6379
          # Always "resque:gitlab".
          :namespace: resque:gitlab
          # Always "incoming_email".
          :queue: incoming_email
          # Always "EmailReceiverWorker"
          :worker: EmailReceiverWorker
    ```

    ```yaml
>>>>>>> gitlabhq/revert-9758-fix/api-helpers-bad-autoload-name
    # Gmail / Google Apps
    :mailboxes:
      -
        # IMAP server host
        :host: "imap.gmail.com"
        # IMAP server port
        :port: 993
        # Whether the IMAP server uses SSL
        :ssl: true
        # Whether the IMAP server uses StartTLS
        :start_tls: false
        # Email account username. Usually the full email address.
        :email: "gitlab-incoming@gmail.com"
        # Email account password
        :password: "[REDACTED]"
        # The name of the mailbox where incoming mail will end up. Usually "inbox".
        :name: "inbox"
        # Always "sidekiq".
        :delivery_method: sidekiq
        # Always true.
        :delete_after_delivery: true
        :delivery_options:
          # The URL to the Redis server used by Sidekiq. Should match the URL in config/resque.yml.
          :redis_url: redis://localhost:6379
          # Always "resque:gitlab".
          :namespace: resque:gitlab
          # Always "incoming_email".
          :queue: incoming_email
          # Always "EmailReceiverWorker"
          :worker: EmailReceiverWorker
>>>>>>> origin/8-0-stable
    ```

    As mentioned, the part after `+` in the address is ignored, and any email sent here will end up in the mailbox for `incoming@gitlab.example.com`/`gitlab-incoming@gmail.com`.

1. Enable `mail_room` in the init script at `/etc/default/gitlab`:

    ```sh
    sudo mkdir -p /etc/default
    echo 'mail_room_enabled=true' | sudo tee -a /etc/default/gitlab
    ```

1. Restart GitLab:

    ```sh
    sudo service gitlab restart
    ```

1. Verify that everything is configured correctly:

    ```sh
    sudo -u git -H bundle exec rake gitlab:incoming_email:check RAILS_ENV=production
    ```

1. Reply by email should now be working.

### Development

1. Go to the GitLab installation directory.

1. Find the `incoming_email` section in `config/gitlab.yml`, enable the feature and fill in the details for your specific IMAP server and email account:

    ```yaml
<<<<<<< HEAD
<<<<<<< HEAD
    # Configuration for Gmail / Google Apps, assumes mailbox gitlab-incoming@gmail.com
=======
    # Gmail / Google Apps, assumes mailbox gitlab-incoming@gmail.com
>>>>>>> origin/8-0-stable
=======
    # Gmail / Google Apps, assumes mailbox gitlab-incoming@gmail.com
>>>>>>> gitlabhq/revert-9758-fix/api-helpers-bad-autoload-name
    incoming_email:
      enabled: true

      # The email address including a placeholder for the key that references the item being replied to.
      # The `%{key}` placeholder is added after the user part, before the `@`.
      address: "gitlab-incoming+%{key}@gmail.com"

      # Email account username
      # With third party providers, this is usually the full email address.
      # With self-hosted email servers, this is usually the user part of the email address.
      user: "gitlab-incoming@gmail.com"
      # Email account password
      password: "[REDACTED]"

      # IMAP server host
      host: "imap.gmail.com"
      # IMAP server port
      port: 993
      # Whether the IMAP server uses SSL
      ssl: true
      # Whether the IMAP server uses StartTLS
      start_tls: false

      # The mailbox where incoming mail will end up. Usually "inbox".
      mailbox: "inbox"
    ```

<<<<<<< HEAD
    As mentioned, the part after `+` is ignored, and this will end up in the mailbox for `gitlab-incoming@gmail.com`.
=======
3. Uncomment the configuration options in `config/mail_room.yml` and fill in the details for your specific IMAP server and email account:

    ```yaml
    # Gmail / Google Apps, assumes mailbox gitlab-incoming@gmail.com
    :mailboxes:
      -
        # IMAP server host
        :host: "imap.gmail.com"
        # IMAP server port
        :port: 993
        # Whether the IMAP server uses SSL
        :ssl: true
        # Whether the IMAP server uses StartTLS
        :start_tls: false
        # Email account username. Usually the full email address.
        :email: "gitlab-incoming@gmail.com"
        # Email account password
        :password: "[REDACTED]"
        # The name of the mailbox where incoming mail will end up. Usually "inbox".
        :name: "inbox"
        # Always "sidekiq".
        :delivery_method: sidekiq
        # Always true.
        :delete_after_delivery: true
        :delivery_options:
          # The URL to the Redis server used by Sidekiq. Should match the URL in config/resque.yml.
          :redis_url: redis://localhost:6379
          # Always "resque:gitlab".
          :namespace: resque:gitlab
          # Always "incoming_email".
          :queue: incoming_email
          # Always "EmailReceiverWorker"
          :worker: EmailReceiverWorker
    ```
>>>>>>> origin/8-0-stable

1. Uncomment the `mail_room` line in your `Procfile`:

    ```yaml
    mail_room: bundle exec mail_room -q -c config/mail_room.yml
    ```

1. Restart GitLab:

    ```sh
    bundle exec foreman start
    ```

1. Verify that everything is configured correctly:

    ```sh
    bundle exec rake gitlab:incoming_email:check RAILS_ENV=development
    ```

1. Reply by email should now be working.
