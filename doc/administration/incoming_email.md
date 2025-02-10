---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Incoming email
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab has several features based on receiving incoming email messages:

- [Reply by Email](reply_by_email.md): allow GitLab users to comment on issues
  and merge requests by replying to notification email.
- [New issue by email](../user/project/issues/create_issues.md#by-sending-an-email):
  allow GitLab users to create a new issue by sending an email to a
  user-specific email address.
- [New merge request by email](../user/project/merge_requests/creating_merge_requests.md#by-sending-an-email):
  allow GitLab users to create a new merge request by sending an email to a
  user-specific email address.
- [Service Desk](../user/project/service_desk/_index.md): provide email support to
  your customers through GitLab.

## Requirements

We recommend using an email address that receives **only** messages that are intended for
the GitLab instance. Any incoming email messages not intended for GitLab receive a reject notice.

Handling incoming email messages requires an [IMAP](https://en.wikipedia.org/wiki/Internet_Message_Access_Protocol)-enabled
email account. GitLab requires one of the following three strategies:

- Email sub-addressing (recommended)
- Catch-all mailbox
- Dedicated email address (supports Reply by Email only)

Let's walk through each of these options.

### Email sub-addressing

[Sub-addressing](https://en.wikipedia.org/wiki/Email_address#Sub-addressing) is
a mail server feature where any email to `user+arbitrary_tag@example.com` ends up
in the mailbox for `user@example.com` . It is supported by providers such as
Gmail, Google Apps, Yahoo! Mail, Outlook.com, and iCloud, as well as the
[Postfix mail server](reply_by_email_postfix_setup.md), which you can run on-premises.
Microsoft Exchange Server [does not support sub-addressing](#microsoft-exchange-server),
and Microsoft Office 365 [does not support sub-addressing by default](#microsoft-office-365).

NOTE:
If your provider or server supports email sub-addressing, we recommend using it.
A dedicated email address only supports Reply by Email functionality.
A catch-all mailbox supports the same features as sub-addressing,
but sub-addressing is still preferred because only one email address is used,
leaving a catch-all available for other purposes beyond GitLab.

### Catch-all mailbox

A [catch-all mailbox](https://en.wikipedia.org/wiki/Catch-all) for a domain
receives all email messages addressed to the domain that do not match any addresses that
exist on the mail server.

Catch-all mailboxes support the same features as
email sub-addressing, but email sub-addressing remains our recommendation so that you
can reserve your catch-all mailbox for other purposes.

### Dedicated email address

To set up this solution, you must create a dedicated email
address to receive your users' replies to GitLab notifications. However,
this method only supports replies, and not the other features of incoming email.

## Accepted headers

> - Accepting `Cc` headers [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/348572) in GitLab 16.5.
> - Accepting `X-Original-To` headers [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149874) in GitLab 17.0.
> - Accepting `X-Forwarded-To` headers [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/168716) in GitLab 17.6.
> - Accepting `X-Delivered-To` headers [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170221) in GitLab 17.6.

Email is processed correctly when a configured email address is present in one of the following headers
(sorted in the order they are checked):

- `To`
- `Delivered-To`
- `X-Delivered-To`
- `Envelope-To` or `X-Envelope-To`
- `Received`
- `X-Original-To`
- `X-Forwarded-To`
- `Cc`

The `References` header is also accepted, however it is used specifically to relate email responses to existing discussion threads. It is not used for creating issues by email.

In GitLab 14.6 and later, [Service Desk](../user/project/service_desk/_index.md)
also checks accepted headers.

Usually, the `To` field contains the email address of the primary receiver.
However, it might not include the configured GitLab email address if:

- The address is in the `BCC` field.
- The email was forwarded.

The `Received` header can contain multiple email addresses. These are checked in the order that they appear.
The first match is used.

## Rejected headers

To prevent unwanted issue creation from automatic email systems, GitLab ignores all incoming email
containing the following headers:

- `Auto-Submitted` with a value other than `no`
- `X-Autoreply` with a value of `yes`

## Set it up

If you want to use Gmail / Google Apps for incoming email, make sure you have
[IMAP access enabled](https://support.google.com/mail/answer/7126229)
and [allowed less secure apps to access the account](https://support.google.com/accounts/answer/6010255)
or [turn-on 2-step validation](https://support.google.com/accounts/answer/185839)
and use [an application password](https://support.google.com/mail/answer/185833).

If you want to use Office 365, and two-factor authentication is enabled, make sure
you're using an
[app password](https://support.microsoft.com/en-us/account-billing/app-passwords-for-a-work-or-school-account-d6dc8c6d-4bf7-4851-ad95-6d07799387e9)
instead of the regular password for the mailbox.

To set up a basic Postfix mail server with IMAP access on Ubuntu, follow the
[Postfix setup documentation](reply_by_email_postfix_setup.md).

### Security concerns

WARNING:
Be careful when choosing the domain used for receiving incoming email.

For example, suppose your top-level company domain is `hooli.com`.
All employees in your company have an email address at that domain through Google
Workspace, and your company's private Slack instance requires a valid `@hooli.com`
email address to sign up.

If you also host a public-facing GitLab instance at `hooli.com` and set your
incoming email domain to `hooli.com`, an attacker could abuse the Create new
issue by email or
[Create new merge request by email](../user/project/merge_requests/creating_merge_requests.md#by-sending-an-email)
features by using a project's unique address as the email when signing up for
Slack. This would send a confirmation email, which would create a new issue or
merge request on the project owned by the attacker, allowing them to select the
confirmation link and validate their account on your company's private Slack
instance.

We recommend receiving incoming email on a subdomain, such as
`incoming.hooli.com`, and ensuring that you do not employ any services that
authenticate solely based on access to an email domain such as `*.hooli.com.`
Alternatively, use a dedicated domain for GitLab email communications such as
`hooli-gitlab.com`.

See GitLab issue [#30366](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/30366)
for a real-world example of this exploit.

WARNING:
Use a mail server that has been configured to reduce
spam.
A Postfix mail server that is running on a default configuration, for example,
can result in abuse. All messages received on the configured mailbox are processed
and messages that are not intended for the GitLab instance receive a reject notice.
If the sender's address is spoofed, the reject notice is delivered to the spoofed
`FROM` address, which can cause the mail server's IP or domain to appear on a block
list.

WARNING:
Users can use the incoming email features without having to use two-factor authentication (2FA) to authenticate themselves first. This applies even if you have [enforced two-factor authentication](../security/two_factor_authentication.md) for your instance.

### Linux package installations

1. Find the `incoming_email` section in `/etc/gitlab/gitlab.rb`, enable the feature
   and fill in the details for your specific IMAP server and email account (see [examples](#configuration-examples) below).

1. Reconfigure GitLab for the changes to take effect:

   ```shell
   sudo gitlab-ctl reconfigure

   # Needed when enabling or disabling for the first time but not for password changes.
   # See https://gitlab.com/gitlab-org/gitlab-foss/-/issues/23560#note_61966788
   sudo gitlab-ctl restart
   ```

1. Verify that everything is configured correctly:

   ```shell
   sudo gitlab-rake gitlab:incoming_email:check
   ```

Reply by email should now be working.

### Self-compiled installations

1. Go to the GitLab installation directory:

   ```shell
   cd /home/git/gitlab
   ```

1. Install the `gitlab-mail_room` gem manually:

   ```shell
   gem install gitlab-mail_room
   ```

   NOTE: This step is necessary to avoid thread deadlocks and to support the latest MailRoom features. See
   [this explanation](../development/emails.md#mailroom-gem-updates) for more details.

1. Find the `incoming_email` section in `config/gitlab.yml`, enable the feature
   and fill in the details for your specific IMAP server and email account (see [examples](#configuration-examples) below).

If you use systemd units to manage GitLab:

1. Add `gitlab-mailroom.service` as a dependency to `gitlab.target`:

   ```shell
   sudo systemctl edit gitlab.target
   ```

   In the editor that opens, add the following and save the file:

   ```plaintext
   [Unit]
   Wants=gitlab-mailroom.service
   ```

1. If you run Redis and PostgreSQL on the same machine, you should add a
   dependency on Redis. Run:

   ```shell
   sudo systemctl edit gitlab-mailroom.service
   ```

   In the editor that opens, add the following and save the file:

   ```plaintext
   [Unit]
   Wants=redis-server.service
   After=redis-server.service
   ```

1. Start `gitlab-mailroom.service`:

   ```shell
   sudo systemctl start gitlab-mailroom.service
   ```

1. Verify that everything is configured correctly:

   ```shell
   sudo -u git -H bundle exec rake gitlab:incoming_email:check RAILS_ENV=production
   ```

If you use the SysV init script to manage GitLab:

1. Enable `mail_room` in the init script at `/etc/default/gitlab`:

   ```shell
   sudo mkdir -p /etc/default
   echo 'mail_room_enabled=true' | sudo tee -a /etc/default/gitlab
   ```

1. Restart GitLab:

   ```shell
   sudo service gitlab restart
   ```

1. Verify that everything is configured correctly:

   ```shell
   sudo -u git -H bundle exec rake gitlab:incoming_email:check RAILS_ENV=production
   ```

Reply by email should now be working.

### Configuration examples

#### Postfix

Example configuration for Postfix mail server. Assumes mailbox `incoming@gitlab.example.com`.

Example for Linux package installations:

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress+%{key}@gitlab.example.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
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

# If you are using Microsoft Graph instead of IMAP, set this to false to retain
# messages in the inbox because deleted messages are auto-expunged after some time.
gitlab_rails['incoming_email_delete_after_delivery'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
# Only applies to IMAP. Microsoft Graph will auto-expunge any deleted messages.
gitlab_rails['incoming_email_expunge_deleted'] = true
```

Example for self-compiled installations:

```yaml
incoming_email:
    enabled: true

    # The email address including the %{key} placeholder that will be replaced to reference the
    # item being replied to. This %{key} should be included in its entirety within the email
    # address and not replaced by another value.
    # For example: emailaddress+%{key}@gitlab.example.com.
    # The placeholder must appear in the "user" part of the address (before the `@`).
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

    # If you are using Microsoft Graph instead of IMAP, set this to false to retain
    # messages in the inbox because deleted messages are auto-expunged after some time.
    delete_after_delivery: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    # Only applies to IMAP. Microsoft Graph will auto-expunge any deleted messages.
    expunge_deleted: true
```

#### Gmail

Example configuration for Gmail/Google Workspace. Assumes mailbox `gitlab-incoming@gmail.com`.

NOTE:
`incoming_email_email` cannot be a Gmail alias account.

Example for Linux package installations:

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress+%{key}@gmail.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
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

# If you are using Microsoft Graph instead of IMAP, set this to false if you want to retain
# messages in the inbox because deleted messages are auto-expunged after some time.
gitlab_rails['incoming_email_delete_after_delivery'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
# Only applies to IMAP. Microsoft Graph will auto-expunge any deleted messages.
gitlab_rails['incoming_email_expunge_deleted'] = true
```

Example for self-compiled installations:

```yaml
incoming_email:
    enabled: true

    # The email address including the %{key} placeholder that will be replaced to reference the
    # item being replied to. This %{key} should be included in its entirety within the email
    # address and not replaced by another value.
    # For example: emailaddress+%{key}@gmail.com.
    # The placeholder must appear in the "user" part of the address (before the `@`).
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

    # If you are using Microsoft Graph instead of IMAP, set this to falseto retain
    # messages in the inbox because deleted messages are auto-expunged after some time.
    delete_after_delivery: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    # Only applies to IMAP. Microsoft Graph will auto-expunge any deleted messages.
    expunge_deleted: true
```

#### Microsoft Exchange Server

Example configurations for Microsoft Exchange Server with IMAP enabled. Because
Exchange does not support sub-addressing, only two options exist:

- [Catch-all mailbox](#catch-all-mailbox) (recommended for Exchange-only)
- [Dedicated email address](#dedicated-email-address) (supports Reply by Email only)

##### Catch-all mailbox

Assumes the catch-all mailbox `incoming@exchange.example.com`.

Example for Linux package installations:

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress-%{key}@exchange.example.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
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

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
# Only applies to IMAP. Microsoft Graph will auto-expunge any deleted messages.
gitlab_rails['incoming_email_expunge_deleted'] = true
```

Example for self-compiled installations:

```yaml
incoming_email:
    enabled: true

    # The email address including the %{key} placeholder that will be replaced to reference the
    # item being replied to. This %{key} should be included in its entirety within the email
    # address and not replaced by another value.
    # For example: emailaddress-%{key}@exchange.example.com.
    # The placeholder must appear in the "user" part of the address (before the `@`).
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

    # If you are using Microsoft Graph instead of IMAP, set this to false to retain
    # messages in the inbox since deleted messages are auto-expunged after some time.
    delete_after_delivery: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    expunge_deleted: true
```

##### Dedicated email address

NOTE:
Supports [Reply by Email](reply_by_email.md) only.
Cannot support [Service Desk](../user/project/service_desk/_index.md).

Assumes the dedicated email address `incoming@exchange.example.com`.

Example for Linux package installations:

```ruby
gitlab_rails['incoming_email_enabled'] = true

# Exchange does not support sub-addressing, and we're not using a catch-all mailbox so %{key} is not used here
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

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
gitlab_rails['incoming_email_expunge_deleted'] = true
```

Example for self-compiled installations:

```yaml
incoming_email:
    enabled: true

    # Exchange does not support sub-addressing,
    # and we're not using a catch-all mailbox so %{key} is not used here
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

    # If you are using Microsoft Graph instead of IMAP, set this to false to retain
    # messages in the inbox since deleted messages are auto-expunged after some time.
    delete_after_delivery: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    expunge_deleted: true
```

#### Microsoft Office 365

Example configurations for Microsoft Office 365 with IMAP enabled.

##### Sub-addressing mailbox

NOTE:
As of September 2020 sub-addressing support
[has been added to Office 365](https://support.microsoft.com/en-us/office/uservoice-pages-430e1a78-e016-472a-a10f-dc2a3df3450a). This feature is not
enabled by default, and must be enabled through PowerShell.

This series of PowerShell commands enables [sub-addressing](#email-sub-addressing)
at the organization level in Office 365. This allows all mailboxes in the organization
to receive sub-addressed mail.

To enable sub-addressing:

1. Download and install the `ExchangeOnlineManagement` module from the [PowerShell gallery](https://www.powershellgallery.com/packages/ExchangeOnlineManagement/2.0.5).
1. In PowerShell, run the following commands:

   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   Import-Module ExchangeOnlineManagement
   Connect-ExchangeOnline
   Set-OrganizationConfig -AllowPlusAddressInRecipients $true
   Disconnect-ExchangeOnline
   ```

This example for Linux package installations assumes the mailbox `incoming@office365.example.com`:

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress+%{key}@office365.example.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
gitlab_rails['incoming_email_address'] = "incoming+%{key}@office365.example.com"

# Email account username
# Typically this is the userPrincipalName (UPN)
gitlab_rails['incoming_email_email'] = "incoming@office365.example.com"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "outlook.office365.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 993
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
gitlab_rails['incoming_email_expunge_deleted'] = true
```

This example for self-compiled installations assumes the mailbox `incoming@office365.example.com`:

```yaml
incoming_email:
    enabled: true

    # The email address including the %{key} placeholder that will be replaced to reference the
    # item being replied to. This %{key} should be included in its entirety within the email
    # address and not replaced by another value.
    # For example: emailaddress+%{key}@office365.example.com.
    # The placeholder must appear in the "user" part of the address (before the `@`).
    address: "incoming+%{key}@office365.example.comm"

    # Email account username
    # Typically this is the userPrincipalName (UPN)
    user: "incoming@office365.example.comm"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "outlook.office365.com"
    # IMAP server port
    port: 993
    # Whether the IMAP server uses SSL
    ssl: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    expunge_deleted: true
```

##### Catch-all mailbox

This example for Linux package installations assumes the catch-all mailbox `incoming@office365.example.com`:

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress-%{key}@office365.example.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
gitlab_rails['incoming_email_address'] = "incoming-%{key}@office365.example.com"

# Email account username
# Typically this is the userPrincipalName (UPN)
gitlab_rails['incoming_email_email'] = "incoming@office365.example.com"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "outlook.office365.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 993
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
gitlab_rails['incoming_email_expunge_deleted'] = true
```

This example for self-compiled installations assumes the catch-all mailbox `incoming@office365.example.com`:

```yaml
incoming_email:
    enabled: true

    # The email address including the %{key} placeholder that will be replaced to reference the
    # item being replied to. This %{key} should be included in its entirety within the email
    # address and not replaced by another value.
    # For example: emailaddress+%{key}@office365.example.com.
    # The placeholder must appear in the "user" part of the address (before the `@`).
    address: "incoming-%{key}@office365.example.com"

    # Email account username
    # Typically this is the userPrincipalName (UPN)
    user: "incoming@ad-domain.example.com"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "outlook.office365.com"
    # IMAP server port
    port: 993
    # Whether the IMAP server uses SSL
    ssl: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    expunge_deleted: true
```

##### Dedicated email address

NOTE:
Supports [Reply by Email](reply_by_email.md) only.
Cannot support [Service Desk](../user/project/service_desk/_index.md).

This example for Linux package installations assumes the dedicated email address `incoming@office365.example.com`:

```ruby
gitlab_rails['incoming_email_enabled'] = true

gitlab_rails['incoming_email_address'] = "incoming@office365.example.com"

# Email account username
# Typically this is the userPrincipalName (UPN)
gitlab_rails['incoming_email_email'] = "incoming@office365.example.com"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "outlook.office365.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 993
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
gitlab_rails['incoming_email_expunge_deleted'] = true
```

This example for self-compiled installations assumes the dedicated email address `incoming@office365.example.com`:

```yaml
incoming_email:
    enabled: true

    address: "incoming@office365.example.com"

    # Email account username
    # Typically this is the userPrincipalName (UPN)
    user: "incoming@office365.example.com"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "outlook.office365.com"
    # IMAP server port
    port: 993
    # Whether the IMAP server uses SSL
    ssl: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    expunge_deleted: true
```

#### Microsoft Graph

GitLab can read incoming email using the Microsoft Graph API instead of
IMAP. Because [Microsoft is deprecating IMAP usage with Basic Authentication](https://techcommunity.microsoft.com/blog/exchange/announcing-oauth-2-0-support-for-imap-and-smtp-auth-protocols-in-exchange-online/1330432), the Microsoft Graph API is be required for new Microsoft Exchange Online mailboxes.

To configure GitLab for Microsoft Graph, you need to register an
OAuth 2.0 application in your Azure Active Directory that has the
`Mail.ReadWrite` permission for all mailboxes. See the [MailRoom step-by-step guide](https://github.com/tpitale/mail_room/#microsoft-graph-configuration)
and [Microsoft instructions](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app)
for more details.

Record the following when you configure your OAuth 2.0 application:

- Tenant ID for your Azure Active Directory
- Client ID for your OAuth 2.0 application
- Client secret your OAuth 2.0 application

##### Restrict mailbox access

For MailRoom to work as a service account, the application you create
in Azure Active Directory requires that you set the `Mail.ReadWrite` property
to read/write mail in *all* mailboxes.

To mitigate security concerns, we recommend configuring an application access
policy which limits the mailbox access for all accounts, as described in
[Microsoft documentation](https://learn.microsoft.com/en-us/graph/auth-limit-mailbox-access).

This example for Linux package installations assumes you're using the following mailbox: `incoming@example.onmicrosoft.com`:

##### Configure Microsoft Graph

> - Alternative Azure deployments [introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5978) in GitLab 14.9.

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress+%{key}@example.onmicrosoft.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
gitlab_rails['incoming_email_address'] = "incoming+%{key}@example.onmicrosoft.com"

# Email account username
gitlab_rails['incoming_email_email'] = "incoming@example.onmicrosoft.com"
gitlab_rails['incoming_email_delete_after_delivery'] = false

gitlab_rails['incoming_email_inbox_method'] = 'microsoft_graph'
gitlab_rails['incoming_email_inbox_options'] = {
   'tenant_id': '<YOUR-TENANT-ID>',
   'client_id': '<YOUR-CLIENT-ID>',
   'client_secret': '<YOUR-CLIENT-SECRET>',
   'poll_interval': 60  # Optional
}
```

For Microsoft Cloud for US Government or [other Azure deployments](https://learn.microsoft.com/en-us/graph/deployments), configure the `azure_ad_endpoint` and `graph_endpoint` settings.

- Example for Microsoft Cloud for US Government:

```ruby
gitlab_rails['incoming_email_inbox_options'] = {
   'azure_ad_endpoint': 'https://login.microsoftonline.us',
   'graph_endpoint': 'https://graph.microsoft.us',
   'tenant_id': '<YOUR-TENANT-ID>',
   'client_id': '<YOUR-CLIENT-ID>',
   'client_secret': '<YOUR-CLIENT-SECRET>',
   'poll_interval': 60  # Optional
}
```

The Microsoft Graph API is not yet supported in self-compiled installations. See [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/326169) for more details.

### Use encrypted credentials

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108279) in GitLab 15.9.

Instead of having the incoming email credentials stored in plaintext in the configuration files, you can optionally
use an encrypted file for the incoming email credentials.

Prerequisites:

- To use encrypted credentials, you must first enable the
  [encrypted configuration](encrypted_configuration.md).

The supported configuration items for the encrypted file are:

- `user`
- `password`

::Tabs

:::TabTitle Linux package (Omnibus)

1. If initially your incoming email configuration in `/etc/gitlab/gitlab.rb` looked like:

   ```ruby
   gitlab_rails['incoming_email_email'] = "incoming-email@mail.example.com"
   gitlab_rails['incoming_email_password'] = "examplepassword"
   ```

1. Edit the encrypted secret:

   ```shell
   sudo gitlab-rake gitlab:incoming_email:secret:edit EDITOR=vim
   ```

1. Enter the unencrypted contents of the incoming email secret:

   ```yaml
   user: 'incoming-email@mail.example.com'
   password: 'examplepassword'
   ```

1. Edit `/etc/gitlab/gitlab.rb` and remove the `incoming_email` settings for `email` and `password`.
1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

Use a Kubernetes secret to store the incoming email password. For more information,
read about [Helm IMAP secrets](https://docs.gitlab.com/charts/installation/secrets.html#imap-password-for-incoming-emails).

:::TabTitle Docker

1. If initially your incoming email configuration in `docker-compose.yml` looked like:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['incoming_email_email'] = "incoming-email@mail.example.com"
           gitlab_rails['incoming_email_password'] = "examplepassword"
   ```

1. Get inside the container, and edit the encrypted secret:

   ```shell
   sudo docker exec -t <container_name> bash
   gitlab-rake gitlab:incoming_email:secret:edit EDITOR=editor
   ```

1. Enter the unencrypted contents of the incoming email secret:

   ```yaml
   user: 'incoming-email@mail.example.com'
   password: 'examplepassword'
   ```

1. Edit `docker-compose.yml` and remove the `incoming_email` settings for `email` and `password`.
1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. If initially your incoming email configuration in `/home/git/gitlab/config/gitlab.yml` looked like:

   ```yaml
   production:
     incoming_email:
       user: 'incoming-email@mail.example.com'
       password: 'examplepassword'
   ```

1. Edit the encrypted secret:

   ```shell
   bundle exec rake gitlab:incoming_email:secret:edit EDITOR=vim RAILS_ENVIRONMENT=production
   ```

1. Enter the unencrypted contents of the incoming email secret:

   ```yaml
   user: 'incoming-email@mail.example.com'
   password: 'examplepassword'
   ```

1. Edit `/home/git/gitlab/config/gitlab.yml` and remove the `incoming_email:` settings for `user` and `password`.
1. Save the file and restart GitLab and Mailroom

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

## Troubleshooting

### Email ingestion doesn't work in 16.6.0

In GitLab 16.6, a regression prevents `mail_room` (email ingestion) from starting.
Service Desk and other reply-by-email features don't work.
This issue was fixed in 16.6.1. See [issue 432257](https://gitlab.com/gitlab-org/gitlab/-/issues/432257) for details.

The workaround is to run the following commands in your GitLab installation
to patch the affected files:

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
curl --output /tmp/mailroom.patch --url "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137279.diff"
patch -p1 -d /opt/gitlab/embedded/service/gitlab-rails < /tmp/mailroom.patch
gitlab-ctl restart mailroom
```

:::TabTitle Docker

```shell
curl --output /tmp/mailroom.patch --url "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137279.diff"
cd /opt/gitlab/embedded/service/gitlab-rails
patch -p1 < /tmp/mailroom.patch
gitlab-ctl restart mailroom
```

::EndTabs

### Incoming emails are rejected by providers with email address limit

Your GitLab instance might not receive incoming emails, because some email providers impose a
64-character limit on the local part of the email address (before the `@`).
All emails from addresses that exceed this limit are rejected emails.

As a workaround, maintain a shorter path:

- Ensure that the local part configured before `%{key}` in `incoming_email_address` is as short as
  possible, and not longer than 31 characters.
- Place the designated projects at a higher group hierarchy.
- Rename [groups](../user/group/manage.md#change-a-groups-path) and
  [project](../user/project/working_with_projects.md#rename-a-repository) to shorter names.

Track this feature in [issue 460206](https://gitlab.com/gitlab-org/gitlab/-/issues/460206).
