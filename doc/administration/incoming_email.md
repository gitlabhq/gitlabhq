---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Incoming email **(FREE SELF)**

GitLab has several features based on receiving incoming email messages:

- [Reply by Email](reply_by_email.md): allow GitLab users to comment on issues
  and merge requests by replying to notification email.
- [New issue by email](../user/project/issues/managing_issues.md#new-issue-via-email):
  allow GitLab users to create a new issue by sending an email to a
  user-specific email address.
- [New merge request by email](../user/project/merge_requests/creating_merge_requests.md#new-merge-request-by-email):
  allow GitLab users to create a new merge request by sending an email to a
  user-specific email address.
- [Service Desk](../user/project/service_desk.md): provide email support to
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
and Microsoft Office 365 [does not support sub-addressing by default](#microsoft-office-365)

NOTE:
If your provider or server supports email sub-addressing, we recommend using it.
A dedicated email address only supports Reply by Email functionality.
A catch-all mailbox supports the same features as sub-addressing as of GitLab 11.7,
but sub-addressing is still preferred because only one email address is used,
leaving a catch-all available for other purposes beyond GitLab.

### Catch-all mailbox

A [catch-all mailbox](https://en.wikipedia.org/wiki/Catch-all) for a domain
receives all email messages addressed to the domain that do not match any addresses that
exist on the mail server.

As of GitLab 11.7, catch-all mailboxes support the same features as
email sub-addressing, but email sub-addressing remains our recommendation so that you
can reserve your catch-all mailbox for other purposes.

### Dedicated email address

This solution is relatively simple to set up: you just need to create an email
address dedicated to receive your users' replies to GitLab notifications. However,
this method only supports replies, and not the other features of [incoming email](#incoming-email).

## Set it up

If you want to use Gmail / Google Apps for incoming email, make sure you have
[IMAP access enabled](https://support.google.com/mail/answer/7126229)
and [allowed less secure apps to access the account](https://support.google.com/accounts/answer/6010255)
or [turn-on 2-step validation](https://support.google.com/accounts/answer/185839)
and use [an application password](https://support.google.com/mail/answer/185833).

If you want to use Office 365, and two-factor authentication is enabled, make sure
you're using an
[app password](https://docs.microsoft.com/en-us/azure/active-directory/user-help/multi-factor-authentication-end-user-app-passwords)
instead of the regular password for the mailbox.

To set up a basic Postfix mail server with IMAP access on Ubuntu, follow the
[Postfix setup documentation](reply_by_email_postfix_setup.md).

### Security concerns

WARNING:
Be careful when choosing the domain used for receiving incoming email.

For example, suppose your top-level company domain is `hooli.com`.
All employees in your company have an email address at that domain via Google
Apps, and your company's private Slack instance requires a valid `@hooli.com`
email address to sign up.

If you also host a public-facing GitLab instance at `hooli.com` and set your
incoming email domain to `hooli.com`, an attacker could abuse the "Create new
issue by email" or
"[Create new merge request by email](../user/project/merge_requests/creating_merge_requests.md#new-merge-request-by-email)"
features by using a project's unique address as the email when signing up for
Slack. This would send a confirmation email, which would create a new issue or
merge request on the project owned by the attacker, allowing them to click the
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

### Omnibus package installations

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

### Installations from source

1. Go to the GitLab installation directory:

   ```shell
   cd /home/git/gitlab
   ```

1. Find the `incoming_email` section in `config/gitlab.yml`, enable the feature
  and fill in the details for your specific IMAP server and email account (see [examples](#configuration-examples) below).

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

Example for Omnibus installs:

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

# Whether to expunge (permanently remove) messages from the mailbox when they are deleted after delivery
gitlab_rails['incoming_email_expunge_deleted'] = true
```

Example for source installs:

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

    # Whether to expunge (permanently remove) messages from the mailbox when they are deleted after delivery
    expunge_deleted: true
```

#### Gmail

Example configuration for Gmail/Google Workspace. Assumes mailbox `gitlab-incoming@gmail.com`.

NOTE:
`incoming_email_email` cannot be a Gmail alias account.

Example for Omnibus installs:

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

# Whether to expunge (permanently remove) messages from the mailbox when they are deleted after delivery
gitlab_rails['incoming_email_expunge_deleted'] = true
```

Example for source installs:

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

    # Whether to expunge (permanently remove) messages from the mailbox when they are deleted after delivery
    expunge_deleted: true
```

#### Microsoft Exchange Server

Example configurations for Microsoft Exchange Server with IMAP enabled. Because
Exchange does not support sub-addressing, only two options exist:

- [Catch-all mailbox](#catch-all-mailbox) (recommended for Exchange-only)
- [Dedicated email address](#dedicated-email-address) (supports Reply by Email only)

##### Catch-all mailbox

Assumes the catch-all mailbox `incoming@exchange.example.com`.

Example for Omnibus installs:

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
```

Example for source installs:

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
```

##### Dedicated email address

Assumes the dedicated email address `incoming@exchange.example.com`.

Example for Omnibus installs:

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
```

Example for source installs:

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
```

#### Microsoft Office 365

Example configurations for Microsoft Office 365 with IMAP enabled.

##### Sub-addressing mailbox

NOTE:
As of September 2020 sub-addressing support
[has been added to Office 365](https://office365.uservoice.com/forums/273493-office-365-admin/suggestions/18612754-support-for-dynamic-email-aliases-in-office-36). This feature is not
enabled by default, and must be enabled through PowerShell.

This series of PowerShell commands enables [sub-addressing](#email-sub-addressing)
at the organization level in Office 365. This allows all mailboxes in the organization
to receive sub-addressed mail:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$UserCredential = Get-Credential

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection

Import-PSSession $Session -DisableNameChecking

Set-OrganizationConfig -AllowPlusAddressInRecipients $true
```

This example for Omnibus GitLab assumes the mailbox `incoming@office365.example.com`:

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
```

This example for source installs assumes the mailbox `incoming@office365.example.com`:

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
```

##### Catch-all mailbox

This example for Omnibus installs assumes the catch-all mailbox `incoming@office365.example.com`:

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
```

This example for source installs assumes the catch-all mailbox `incoming@office365.example.com`:

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
```

##### Dedicated email address

This example for Omnibus installs assumes the dedicated email address `incoming@office365.example.com`:

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
```

This example for source installs assumes the dedicated email address `incoming@office365.example.com`:

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
```

#### Microsoft Graph

> Introduced in [GitLab 13.11](https://gitlab.com/gitlab-org/gitlab/-/issues/214900).

GitLab can read incoming email using the Microsoft Graph API instead of
IMAP. Because [Microsoft is deprecating IMAP usage with Basic Authentication](https://techcommunity.microsoft.com/t5/exchange-team-blog/announcing-oauth-2-0-support-for-imap-and-smtp-auth-protocols-in/ba-p/1330432), the Microsoft Graph API will soon be required for new Microsoft Exchange Online
mailboxes.

To configure GitLab for Microsoft Graph, you will need to register an
OAuth2 application in your Azure Active Directory that has the
`Mail.ReadWrite` permission for all mailboxes. See the [MailRoom step-by-step guide](https://github.com/tpitale/mail_room/#microsoft-graph-configuration)
and [Microsoft instructions](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
for more details.

Record the following when you configure your OAuth2 application:

- Tenant ID for your Azure Active Directory
- Client ID for your OAuth2 application
- Client secret your OAuth2 application

##### Restrict mailbox access

For MailRoom to work as a service account, the application you create
in Azure Active Directory requires that you set the `Mail.ReadWrite` property
to read/write mail in *all* mailboxes.

To mitigate security concerns, we recommend configuring an application access
policy which limits the mailbox access for all accounts, as described in
[Microsoft documentation](https://docs.microsoft.com/en-us/graph/auth-limit-mailbox-access).

This example for Omnibus GitLab assumes you're using the following mailbox: `incoming@example.onmicrosoft.com`:

##### Configure Microsoft Graph

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

gitlab_rails['incoming_email_inbox_method'] = 'microsoft_graph'
gitlab_rails['incoming_email_inbox_options'] = {
   'tenant_id': '<YOUR-TENANT-ID>',
   'client_id': '<YOUR-CLIENT-ID>',
   'client_secret': '<YOUR-CLIENT-SECRET>',
   'poll_interval': 60  # Optional
}
```

The Microsoft Graph API is not yet supported in source installations. See [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/326169) for more details.
