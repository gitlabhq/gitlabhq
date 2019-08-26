# Dealing with email in development

## Sent emails

To view rendered emails "sent" in your development instance, visit
[`/rails/letter_opener`](http://localhost:3000/rails/letter_opener).

Please note that [S/MIME signed](../administration/smime_signing_email.md) emails
[cannot be currently previewed](https://github.com/fgrehm/letter_opener_web/issues/96) with
`letter_opener`.

## Mailer previews

Rails provides a way to preview our mailer templates in HTML and plaintext using
dummy data.

The previews live in [`app/mailers/previews`][previews] and can be viewed at
[`/rails/mailers`](http://localhost:3000/rails/mailers).

See the [Rails guides] for more info.

[previews]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/app/mailers/previews
[Rails guides]: http://guides.rubyonrails.org/action_mailer_basics.html#previewing-emails

## Incoming email

1. Go to the GitLab installation directory.

1. Find the `incoming_email` section in `config/gitlab.yml`, enable the
   feature and fill in the details for your specific IMAP server and email
   account:

   Configuration for Gmail / Google Apps, assumes mailbox `gitlab-incoming@gmail.com`:

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

   As mentioned, the part after `+` is ignored, and this will end up in the mailbox for `gitlab-incoming@gmail.com`.

1. Run this command in the GitLab root directory to launch `mail_room`:

   ```sh
   bundle exec mail_room -q -c config/mail_room.yml
   ```

1. Verify that everything is configured correctly:

   ```sh
   bundle exec rake gitlab:incoming_email:check RAILS_ENV=development
   ```

1. Reply by email should now be working.

## Email namespace

As of GitLab 11.7, we support a new format for email handler addresses.  This was done to
support catch-all mailboxes.

If you need to implement a feature which requires a new email handler, follow these rules
for the format of the email key:

- Actions are always at the end, separated by `-`.  For example `-issue` or `-merge-request`
- If your feature is related to a project, the key begins with the project identifiers (project path slug
  and project id), separated by `-`.  For example, `gitlab-org-gitlab-ce-20`
- Additional information, such as an author's token, can be added between the project identifiers and
  the action, separated by `-`.  For example, `gitlab-org-gitlab-ce-20-Author_Token12345678-issue`
- You register your handlers in `lib/gitlab/email/handler.rb`

Examples of valid email keys:

- `gitlab-org-gitlab-ce-20-Author_Token12345678-issue` (create a new issue)
- `gitlab-org-gitlab-ce-20-Author_Token12345678-merge-request` (create a new merge request)
- `1234567890abcdef1234567890abcdef-unsubscribe` (unsubscribe from a conversation)
- `1234567890abcdef1234567890abcdef` (reply to a conversation)

Please note that the action `-issue-` is used in GitLab Premium as the handler for the Service Desk feature.

### Legacy format

Although we continue to support the older legacy format, no new features should use a legacy format.
These are the only valid legacy formats for an email handler:

- `path/to/project+namespace`
- `path/to/project+namespace+action`
- `namespace`
- `namespace+action`

Please note that `path/to/project` is used in GitLab Premium as handler for the Service Desk feature.

---

[Return to Development documentation](README.md)
