# Reply by email

GitLab can be set up to allow users to comment on issues and merge requests by replying to notification emails.

## Get a mailbox

Reply by email requires an IMAP-enabled email account, with a provider or server that supports [email sub-addressing](https://en.wikipedia.org/wiki/Email_address#Sub-addressing). Sub-addressing is a feature where any email to `user+some_arbitrary_tag@example.com` will end up in the mailbox for `user@example.com`, and is supported by providers such as Gmail, Yahoo! Mail, Outlook.com and iCloud, as well as the Postfix mail server which you can run on-premises.

If you want to use Gmail with Reply by email, make sure you have [IMAP access enabled](https://support.google.com/mail/troubleshooter/1668960?hl=en#ts=1665018) and [allow less secure apps to access the account](https://support.google.com/accounts/answer/6010255).

To set up a basic Postfix mail server with IMAP access on Ubuntu, follow [these instructions](./postfix.md).

## Set it up

In this example, we'll use the Gmail address `gitlab-incoming@gmail.com`.

### Omnibus package installations

1. Find the `incoming_email` section in `/etc/gitlab/gitlab.rb`, enable the feature, enter the email address including a placeholder for the `key` that references the item being replied to and fill in the details for your specific IMAP server and email account:

    ```ruby
    gitlab_rails['incoming_email_enabled'] = true
    gitlab_rails['incoming_email_address'] = "gitlab-incoming+%{key}@gmail.com"
    gitlab_rails['incoming_email_host'] = "imap.gmail.com" # IMAP server host
    gitlab_rails['incoming_email_port'] = 993 # IMAP server port
    gitlab_rails['incoming_email_ssl'] = true # Whether the IMAP server uses SSL
    gitlab_rails['incoming_email_email'] = "gitlab-incoming@gmail.com"  # Email account username. Usually the full email address.
    gitlab_rails['incoming_email_password'] = "password" # Email account password
    gitlab_rails['incoming_email_mailbox_name'] = "inbox" # The name of the mailbox where incoming mail will end up. Usually "inbox".
    ```

    As mentioned, the part after `+` in the address is ignored, and any email sent here will end up in the mailbox for `gitlab-incoming@gmail.com`.

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

1. Find the `incoming_email` section in `config/gitlab.yml`, enable the feature and enter the email address including a placeholder for the `key` that references the item being replied to:

    ```sh
    sudo editor config/gitlab.yml
    ```

    ```yaml
    incoming_email:
      enabled: true
      address: "gitlab-incoming+%{key}@gmail.com"
    ```

    As mentioned, the part after `+` in the address is ignored, and any email sent here will end up in the mailbox for `gitlab-incoming@gmail.com`.

2. Copy `config/mail_room.yml.example` to `config/mail_room.yml`:

    ```sh
    sudo cp config/mail_room.yml.example config/mail_room.yml
    ```

3. Uncomment the configuration options in `config/mail_room.yml` and fill in the details for your specific IMAP server and email account:

    ```sh
    sudo editor config/mail_room.yml
    ```

    ```yaml
    :mailboxes:
      -
        # IMAP server host
        :host: "imap.gmail.com"
        # IMAP server port
        :port: 993
        # Whether the IMAP server uses SSL
        :ssl: true
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

5. Edit the init script configuration at `/etc/default/gitlab` to enable `mail_room`:

    ```sh
    sudo mkdir -p /etc/default
    echo 'mail_room_enabled=true' | sudo tee -a /etc/default/gitlab
    ```

6. Restart GitLab:

    ```sh
    sudo service gitlab restart
    ```

7. Verify that everything is configured correctly:

    ```sh
    sudo -u git -H bundle exec rake gitlab:incoming_email:check RAILS_ENV=production
    ```

8. Reply by email should now be working.

### Development

1. Go to the GitLab installation directory.

1. Find the `incoming_email` section in `config/gitlab.yml`, enable the feature and enter the email address including a placeholder for the `key` that references the item being replied to:

    ```yaml
    incoming_email:
      enabled: true
      address: "gitlab-incoming+%{key}@gmail.com"
    ```

    As mentioned, the part after `+` is ignored, and this will end up in the mailbox for `gitlab-incoming@gmail.com`.

2. Copy `config/mail_room.yml.example` to `config/mail_room.yml`:

    ```sh
    sudo cp config/mail_room.yml.example config/mail_room.yml
    ```

3. Uncomment the configuration options in `config/mail_room.yml` and fill in the details for your specific IMAP server and email account:

    ```yaml
    :mailboxes:
      -
        # IMAP server host
        :host: "imap.gmail.com"
        # IMAP server port
        :port: 993
        # Whether the IMAP server uses SSL
        :ssl: true
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

4. Uncomment the `mail_room` line in your `Procfile`:

    ```yaml
    mail_room: bundle exec mail_room -q -c config/mail_room.yml
    ```

6. Restart GitLab:

    ```sh
    bundle exec foreman start
    ```

7. Verify that everything is configured correctly:

    ```sh
    bundle exec rake gitlab:incoming_email:check RAILS_ENV=development
    ```

8. Reply by email should now be working.
