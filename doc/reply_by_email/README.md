# Reply by email

GitLab can be set up to allow users to comment on issues and merge requests by replying to notification emails.

In order to do this, you need access to an IMAP-enabled email account, with a provider or server that supports [email sub-addressing](https://en.wikipedia.org/wiki/Email_address#Sub-addressing). Sub-addressing is a feature where any email to `user+some_arbitrary_tag@example.com` will end up in the mailbox for `user@example.com`, and is supported by providers such as Gmail, Yahoo! Mail, Outlook.com and iCloud, as well as the [Postfix](http://www.postfix.org/) mail server which you can run on-premises.

## Set it up

In this example, we'll use the Gmail address `gitlab-replies@gmail.com`. If you're actually using Gmail with Reply by email, make sure you have [IMAP access enabled](https://support.google.com/mail/troubleshooter/1668960?hl=en#ts=1665018) and [allow less secure apps to access the account](https://support.google.com/accounts/answer/6010255).

### Installations from source

1. Go to the GitLab installation directory:

    ```sh
    cd /home/git/gitlab
    ```

1. Find the `reply_by_email` section in `config/gitlab.yml`, enable the feature and enter the email address including a placeholder for the `reply_key`:

    ```sh
    sudo editor config/gitlab.yml
    ```
    
    ```yaml
    reply_by_email:
      enabled: true
      address: "gitlab-replies+%{reply_key}@gmail.com"
    ```

    As mentioned, the part after `+` is ignored, and this will end up in the mailbox for `gitlab-replies@gmail.com`.

2. Find `config/mail_room.yml.example` and copy it to `config/mail_room.yml`:
    
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
        :email: "gitlab-replies@gmail.com"
        # Email account password
        :password: "[REDACTED]"
        # The name of the mailbox where incoming mail will end up. Usually "inbox".
        :name: "inbox"
        # Always "sidekiq".
        :delivery_method: sidekiq
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


4.  Find `lib/support/init.d/gitlab.default.example` and copy it to `/etc/default/gitlab`:
    
    ```sh
    sudo cp lib/support/init.d/gitlab.default.example /etc/default/gitlab
    ```

5. Edit `/etc/default/gitlab` to enable `mail_room`:

    ```sh
    sudo editor /etc/default/gitlab
    ```
    
    ```sh
    mail_room_enabled=true
    ```

6. Restart GitLab:
    
    ```sh
    sudo service gitlab restart
    ```

7. Check if everything is configured correctly:

    ```sh
    sudo bundle exec rake gitlab:reply_by_email:check RAILS_ENV=production
    ```

8. Reply by email should now be working.

### Omnibus package installations

TODO

### Development

1. Go to the GitLab installation directory.

1. Find the `reply_by_email` section in `config/gitlab.yml`, enable the feature and enter the email address including a placeholder for the `reply_key`:
    
    ```yaml
    reply_by_email:
      enabled: true
      address: "gitlab-replies+%{reply_key}@gmail.com"
    ```

    As mentioned, the part after `+` is ignored, and this will end up in the mailbox for `gitlab-replies@gmail.com`.

2. Find `config/mail_room.yml.example` and copy it to `config/mail_room.yml`:
    
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
        :email: "gitlab-replies@gmail.com"
        # Email account password
        :password: "[REDACTED]"
        # The name of the mailbox where incoming mail will end up. Usually "inbox".
        :name: "inbox"
        # Always "sidekiq".
        :delivery_method: sidekiq
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

7. Check if everything is configured correctly:

    ```sh
    bundle exec rake gitlab:reply_by_email:check RAILS_ENV=development
    ```

8. Reply by email should now be working.
