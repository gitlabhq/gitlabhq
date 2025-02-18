---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Working with email in development
---

## Ensuring compatibility with mailer Sidekiq jobs

A Sidekiq job is enqueued whenever `deliver_later` is called on an `ActionMailer`.
If a mailer argument needs to be added or removed, it is important to ensure
both backward and forward compatibility. Adhere to the Sidekiq steps for
[changing the arguments for a worker](sidekiq/compatibility_across_updates.md#changing-the-arguments-for-a-worker).

The same applies to a new mailer method, or a new mailer. If you introduce either,
follow the steps for [adding new workers](sidekiq/compatibility_across_updates.md#adding-new-workers).
This includes wrapping the new method with a [feature flag](feature_flags/_index.md)
so the new mailer can be disabled if a problem arises after deployment.

In the following example from [`NotificationService`](https://gitlab.com/gitlab-org/gitlab/-/blob/33ccb22e4fc271dbaac94b003a7a1a2915a13441/app/services/notification_service.rb#L74)
adding or removing an argument in this mailer's definition may cause problems
during deployment before all Rails and Sidekiq nodes have the updated code.

```ruby
mailer.unknown_sign_in_email(user, ip, time).deliver_later
```

## Sent emails

To view rendered emails "sent" in your development instance, visit
[`/rails/letter_opener`](http://localhost:3000/rails/letter_opener).

[S/MIME signed](../administration/smime_signing_email.md) emails
[cannot be currently previewed](https://github.com/fgrehm/letter_opener_web/issues/96) with
`letter_opener`.

## Mailer previews

Rails provides a way to preview our mailer templates in HTML and plaintext using
sample data.

The previews live in [`app/mailers/previews`](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/app/mailers/previews) and can be viewed at
[`/rails/mailers`](http://localhost:3000/rails/mailers).

See the [Rails guides](https://guides.rubyonrails.org/action_mailer_basics.html#previewing-emails) for more information.

## Incoming email

1. Go to the GitLab installation directory.

1. Find the `incoming_email` section in `config/gitlab.yml`, enable the
   feature and fill in the details for your specific IMAP server and email
   account:

   Configuration for Gmail / Google Apps, assumes mailbox `gitlab-incoming@gmail.com`:

   ```yaml
   incoming_email:
     enabled: true

     # The email address including the %{key} placeholder that will be replaced to reference the
     # item being replied to. This %{key} should be included in its entirety within the email
     # address and not replaced by another value.
     # For example: emailaddress+%{key}@gmail.com.
     # The placeholder must appear in the "user" part of the address (before the `@`). It can be omitted but some features,
     # including Service Desk, may not work properly.
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

     # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
     expunge_deleted: false
   ```

   As mentioned, the part after `+` is ignored, and this message is sent to the mailbox for `gitlab-incoming@gmail.com`.

1. Read the [MailRoom Gem updates](#mailroom-gem-updates) section for more details before you proceed to make sure you have the right version of MailRoom installed. In summary, you need to update the `gitlab-mail_room` version in the `Gemfile` to the latest `gitlab-mail_room` temporarily and run `bundle install`. **Do not commit** this change as it's a temporary workaround.

1. Run this command in the GitLab root directory to launch `mail_room`:

   ```shell
   bundle exec mail_room -q -c config/mail_room.yml
   ```

1. Verify that everything is configured correctly:

   ```shell
   bundle exec rake gitlab:incoming_email:check RAILS_ENV=development
   ```

1. Reply by email should now be working.

## Email namespace

GitLab supports the new format for email handler addresses. This was done to
support catch-all mailboxes.

If you need to implement a feature which requires a new email handler, follow these rules
for the format of the email key:

- Actions are always at the end, separated by `-`. For example `-issue` or `-merge-request`
- If your feature is related to a project, the key begins with the project identifiers (project path slug
  and project ID), separated by `-`. For example, `gitlab-org-gitlab-foss-20`
- Additional information, such as an author's token, can be added between the project identifiers and
  the action, separated by `-`. For example, `gitlab-org-gitlab-foss-20-Author_Token12345678-issue`
- You register your handlers in `lib/gitlab/email/handler.rb`

Examples of valid email keys:

- `gitlab-org-gitlab-foss-20-Author_Token12345678-issue` (create a new issue)
- `gitlab-org-gitlab-foss-20-Author_Token12345678-merge-request` (create a new merge request)
- `1234567890abcdef1234567890abcdef-unsubscribe` (unsubscribe from a conversation)
- `1234567890abcdef1234567890abcdef` (reply to a conversation)

The action `-issue-` is used in GitLab as the handler for the Service Desk feature.

### Legacy format

Although we continue to support the older legacy format, no new features should use a legacy format.
These are the only valid legacy formats for an email handler:

- `path/to/project+namespace`
- `path/to/project+namespace+action`
- `namespace`
- `namespace+action`

In GitLab, the handler for the Service Desk feature is `path/to/project`.

### MailRoom Gem updates

We use [`gitlab-mail_room`](https://gitlab.com/gitlab-org/ruby/gems/gitlab-mail_room), a
fork of [`MailRoom`](https://github.com/tpitale/mail_room/), to ensure
that we can make updates quickly to the gem if necessary. We try to upstream
changes as soon as possible and keep the two projects in sync.

To update MailRoom:

1. Update `Gemfile` in GitLab Rails (see [example merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116494)).
1. Update the Helm Chart configuration (see [example merge request](https://gitlab.com/gitlab-org/build/CNG/-/merge_requests/854)).

---

[Return to Development documentation](_index.md)
