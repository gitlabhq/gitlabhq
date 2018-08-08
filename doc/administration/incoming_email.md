# Incoming email

GitLab has several features based on receiving incoming emails:

- [Reply by Email](reply_by_email.md): allow GitLab users to comment on issues
  and merge requests by replying to notification emails.
- [New issue by email](../user/project/issues/create_new_issue.md#new-issue-via-email):
  allow GitLab users to create a new issue by sending an email to a
  user-specific email address.
- [New merge request by email](../user/project/merge_requests/index.md#create-new-merge-requests-by-email):
  allow GitLab users to create a new merge request by sending an email to a
  user-specific email address.
- [Service Desk](../user/project/service_desk.md): provide e-mail support to
  your customers through GitLab.

## Requirements

Handling incoming emails requires an [IMAP]-enabled email account. GitLab
requires one of the following three strategies:

- Email sub-addressing
- Dedicated email address
- Catch-all mailbox

Let's walk through each of these options.

**If your provider or server supports email sub-addressing, we recommend using it.
Most features (other than reply by email) only work with sub-addressing.**

[IMAP]: https://en.wikipedia.org/wiki/Internet_Message_Access_Protocol

### Email sub-addressing

[Sub-addressing](https://en.wikipedia.org/wiki/Email_address#Sub-addressing) is
a feature where any email to `user+some_arbitrary_tag@example.com` will end up
in the mailbox for `user@example.com`, and is supported by providers such as
Gmail, Google Apps, Yahoo! Mail, Outlook.com and iCloud, as well as the
[Postfix mail server] which you can run on-premises.

[Postfix mail server]: reply_by_email_postfix_setup.md

### Dedicated email address

This solution is really simple to set up: you just have to create an email
address dedicated to receive your users' replies to GitLab notifications.

### Catch-all mailbox

A [catch-all mailbox](https://en.wikipedia.org/wiki/Catch-all) for a domain will
"catch all" the emails addressed to the domain that do not exist in the mail
server.

GitLab can be set up to allow users to comment on issues and merge requests by
replying to notification emails.

## Set it up

If you want to use Gmail / Google Apps for incoming emails, make sure you have
[IMAP access enabled](https://support.google.com/mail/troubleshooter/1668960?hl=en#ts=1665018)
and [allowed less secure apps to access the account](https://support.google.com/accounts/answer/6010255)
or [turn-on 2-step validation](https://support.google.com/accounts/answer/185839)
and use [an application password](https://support.google.com/mail/answer/185833).

To set up a basic Postfix mail server with IMAP access on Ubuntu, follow the
[Postfix setup documentation](reply_by_email_postfix_setup.md).

### Security Concerns

**WARNING:** Be careful when choosing the domain used for receiving incoming
email.

For the sake of example, suppose your top-level company domain is `hooli.com`.
All employees in your company have an email address at that domain via Google
Apps, and your company's private Slack instance requires a valid `@hooli.com`
email address in order to sign up.

If you also host a public-facing GitLab instance at `hooli.com` and set your
incoming email domain to `hooli.com`, an attacker could abuse the "Create new
issue by email" or
"[Create new merge request by email](../user/project/merge_requests/index.md#create-new-merge-requests-by-email)"
features by using a project's unique address as the email when signing up for
Slack, which would send a confirmation email, which would create a new issue or
merge request on the project owned by the attacker, allowing them to click the
confirmation link and validate their account on your company's private Slack
instance.

We recommend receiving incoming email on a subdomain, such as
`incoming.hooli.com`, and ensuring that you do not employ any services that
authenticate solely based on access to an email domain such as `*.hooli.com.`
Alternatively, use a dedicated domain for GitLab email communications such as
`hooli-gitlab.com`.

See GitLab issue [#30366](https://gitlab.com/gitlab-org/gitlab-ce/issues/30366)
for a real-world example of this exploit.

### Omnibus package installations

1. Find the `incoming_email` section in `/etc/gitlab/gitlab.rb`, enable the
  feature and fill in the details for your specific IMAP server and email account:

    Configuration for Postfix mail server, assumes mailbox
    incoming@gitlab.example.com

    ```ruby
    gitlab_rails['incoming_email_enabled'] = true

    # The email address including the `%{key}` placeholder that will be replaced to reference the item being replied to.
    # The placeholder can be omitted but if present, it must appear in the "user" part of the address (before the `@`).
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
    # The IDLE command timeout.
    gitlab_rails['incoming_email_idle_timeout'] = 60
    ```

    Configuration for Gmail / Google Apps, assumes mailbox
    gitlab-incoming@gmail.com

    ```ruby
    gitlab_rails['incoming_email_enabled'] = true

    # The email address including the `%{key}` placeholder that will be replaced to reference the item being replied to.
    # The placeholder can be omitted but if present, it must appear in the "user" part of the address (before the `@`).
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
    # The IDLE command timeout.
    gitlab_rails['incoming_email_idle_timeout'] = 60
    ```

    Configuration for Microsoft Exchange mail server w/ IMAP enabled, assumes
    mailbox incoming@exchange.example.com

    ```ruby
    gitlab_rails['incoming_email_enabled'] = true

    # The email address replies are sent to - Exchange does not support sub-addressing so %{key} is not used here
    gitlab_rails['incoming_email_address'] = "incoming@exchange.example.com"

    # Email account username
    # Typically this is the userPrincipalName (UPN)
    gitlab_rails['incoming_email_email'] = "incoming@ad-domain.example.com"
    # Email account password
    gitlab_rails['incoming_email_password'] = "[REDACTED]"

    # IMAP server host
    gitlab_rails['incoming_email_host'] = "exchange.example.com"
    # IMAP server port
    gitlab_rails['incoming_email_port'] = 993
    # Whether the IMAP server uses SSL
    gitlab_rails['incoming_email_ssl'] = true
    ```

1. Reconfigure GitLab for the changes to take effect:

    ```sh
    sudo gitlab-ctl reconfigure
    sudo gitlab-ctl restart
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

1. Find the `incoming_email` section in `config/gitlab.yml`, enable the feature
  and fill in the details for your specific IMAP server and email account:

    ```sh
    sudo editor config/gitlab.yml
    ```

    Configuration for Postfix mail server, assumes mailbox
    incoming@gitlab.example.com

    ```yaml
    incoming_email:
      enabled: true

      # The email address including the `%{key}` placeholder that will be replaced to reference the item being replied to.
      # The placeholder can be omitted but if present, it must appear in the "user" part of the address (before the `@`).
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
      # The IDLE command timeout.
      idle_timeout: 60
    ```

    Configuration for Gmail / Google Apps, assumes mailbox
    gitlab-incoming@gmail.com

    ```yaml
    incoming_email:
      enabled: true

      # The email address including the `%{key}` placeholder that will be replaced to reference the item being replied to.
      # The placeholder can be omitted but if present, it must appear in the "user" part of the address (before the `@`).
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
      # The IDLE command timeout.
      idle_timeout: 60
    ```

    Configuration for Microsoft Exchange mail server w/ IMAP enabled, assumes
    mailbox incoming@exchange.example.com

    ```yaml
    incoming_email:
      enabled: true

      # The email address replies are sent to - Exchange does not support sub-addressing so %{key} is not used here
      address: "incoming@exchange.example.com"

      # Email account username
      # Typically this is the userPrincipalName (UPN)
      user: "incoming@ad-domain.example.com"
      # Email account password
      password: "[REDACTED]"

      # IMAP server host
      host: "exchange.example.com"
      # IMAP server port
      port: 993
      # Whether the IMAP server uses SSL
      ssl: true
      # Whether the IMAP server uses StartTLS
      start_tls: false

      # The mailbox where incoming mail will end up. Usually "inbox".
      mailbox: "inbox"
      # The IDLE command timeout.
      idle_timeout: 60
    ```

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
