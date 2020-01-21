# Incoming email

GitLab has several features based on receiving incoming emails:

- [Reply by Email](reply_by_email.md): allow GitLab users to comment on issues
  and merge requests by replying to notification emails.
- [New issue by email](../user/project/issues/managing_issues.md#new-issue-via-email):
  allow GitLab users to create a new issue by sending an email to a
  user-specific email address.
- [New merge request by email](../user/project/merge_requests/creating_merge_requests.md#new-merge-request-by-email-core-only):
  allow GitLab users to create a new merge request by sending an email to a
  user-specific email address.
- [Service Desk](../user/project/service_desk.md): provide e-mail support to
  your customers through GitLab. **(PREMIUM)**

## Requirements

Handling incoming emails requires an [IMAP](https://en.wikipedia.org/wiki/Internet_Message_Access_Protocol)-enabled
email account. GitLab requires one of the following three strategies:

- Email sub-addressing (recommended)
- Catch-all mailbox
- Dedicated email address (supports Reply by Email only)

Let's walk through each of these options.

### Email sub-addressing

[Sub-addressing](https://en.wikipedia.org/wiki/Email_address#Sub-addressing) is
a mail server feature where any email to `user+arbitrary_tag@example.com` will end up
in the mailbox for `user@example.com` . It is supported by providers such as
Gmail, Google Apps, Yahoo! Mail, Outlook.com, and iCloud, as well as the
[Postfix mail server](reply_by_email_postfix_setup.md), which you can run on-premises.

TIP: **Tip:**
If your provider or server supports email sub-addressing, we recommend using it.
A dedicated email address only supports Reply by Email functionality.
A catch-all mailbox supports the same features as sub-addressing as of GitLab 11.7,
but sub-addressing is still preferred because only one email address is used,
leaving a catch-all available for other purposes beyond GitLab.

### Catch-all mailbox

A [catch-all mailbox](https://en.wikipedia.org/wiki/Catch-all) for a domain
receives all emails addressed to the domain that do not match any addresses that
exist on the mail server.

As of GitLab 11.7, catch-all mailboxes support the same features as
email sub-addressing, but email sub-addressing remains our recommendation so that you
can reserve your catch-all mailbox for other purposes.

### Dedicated email address

This solution is relatively simple to set up: you just need to create an email
address dedicated to receive your users' replies to GitLab notifications. However,
this method only supports replies, and not the other features of [incoming email](#incoming-email).

## Set it up

If you want to use Gmail / Google Apps for incoming emails, make sure you have
[IMAP access enabled](https://support.google.com/mail/answer/7126229)
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
"[Create new merge request by email](../user/project/merge_requests/creating_merge_requests.md#new-merge-request-by-email-core-only)"
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

See GitLab issue [#30366](https://gitlab.com/gitlab-org/gitlab-foss/issues/30366)
for a real-world example of this exploit.

### Omnibus package installations

1. Find the `incoming_email` section in `/etc/gitlab/gitlab.rb`, enable the feature
    and fill in the details for your specific IMAP server and email account (see [examples](#config-examples) below).

1. Reconfigure GitLab for the changes to take effect:

   ```sh
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart
   ```

1. Verify that everything is configured correctly:

   ```sh
   sudo gitlab-rake gitlab:incoming_email:check
   ```

Reply by email should now be working.

### Installations from source

1. Go to the GitLab installation directory:

   ```sh
   cd /home/git/gitlab
   ```

1. Find the `incoming_email` section in `config/gitlab.yml`, enable the feature
  and fill in the details for your specific IMAP server and email account (see [examples](#config-examples) below).

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

Reply by email should now be working.

### Config examples

#### Postfix

Example configuration for Postfix mail server. Assumes mailbox `incoming@gitlab.example.com`.

Example for Omnibus installs:

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

Example for source installs:

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

#### Gmail

Example configuration for Gmail/G Suite. Assumes mailbox `gitlab-incoming@gmail.com`.

Example for Omnibus installs:

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

Example for source installs:

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

#### MS Exchange

Example configuration for Microsoft Exchange mail server with IMAP enabled. Assumes the
catch-all mailbox incoming@exchange.example.com.

Example for Omnibus installs:

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the `%{key}` placeholder that will be replaced to reference the item being replied to.
# The placeholder can be omitted but if present, it must appear in the "user" part of the address (before the `@`).
# Exchange does not support sub-addressing, so a catch-all mailbox must be used.
gitlab_rails['incoming_email_address'] = "incoming-%{key}@exchange.example.com"

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

Example for source installs:

```yaml
incoming_email:
    enabled: true

    # The email address including the `%{key}` placeholder that will be replaced to reference the item being replied to.
    # The placeholder can be omitted but if present, it must appear in the "user" part of the address (before the `@`).
    # Exchange does not support sub-addressing, so a catch-all mailbox must be used.
    address: "incoming-%{key}@exchange.example.com"

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
