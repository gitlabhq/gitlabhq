---
stage: Monitor
group: Respond
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Reply by email **(FREE SELF)**

GitLab can be set up to allow users to comment on issues and merge requests by
replying to notification emails.

## Prerequisite

Make sure [incoming email](incoming_email.md) is set up.

## How it works

Replying by email happens in three steps:

1. GitLab sends a notification email.
1. You reply to the notification email.
1. GitLab receives your reply to the notification email.

### GitLab sends a notification email

When GitLab sends a notification and Reply by email is enabled, the `Reply-To`
header is set to the address defined in your GitLab configuration, with the
`%{key}` placeholder (if present) replaced by a specific "reply key". In
addition, this "reply key" is also added to the `References` header.

### You reply to the notification email

When you reply to the notification email, your email client:

- Sends the email to the `Reply-To` address it got from the notification email
- Sets the `In-Reply-To` header to the value of the `Message-ID` header from the
  notification email
- Sets the `References` header to the value of the `Message-ID` plus the value of
  the notification email's `References` header.

### GitLab receives your reply to the notification email

When GitLab receives your reply, it looks for the "reply key" in the
following headers, in this order:

1. `To` header
1. `References` header
1. `Delivered-To` header
1. `Envelope-To` header
1. `X-Envelope-To` header
1. `Received` header

If it finds a reply key, it leaves your reply as a comment on
the entity the notification was about (issue, merge request, commit...).

For more details about the `Message-ID`, `In-Reply-To`, and `References headers`,
see [RFC 5322](https://www.rfc-editor.org/rfc/rfc5322#section-3.6.4).
