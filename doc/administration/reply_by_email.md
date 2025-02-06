---
stage: Monitor
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Reply by email
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

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

When GitLab sends a notification email:

- The `Reply-To` header is set to your configured email address.
- If the address contains a `%{key}` placeholder, it's replaced with a specific reply key.
- The reply key is added to the `References` header.

### You reply to the notification email

When you reply to the notification email, your email client:

- Sends the email to the `Reply-To` address it got from the notification email.
- Sets the `In-Reply-To` header to the value of the `Message-ID` header from the
  notification email.
- Sets the `References` header to the value of the `Message-ID` plus the value of
  the notification email's `References` header.

### GitLab receives your reply to the notification email

When GitLab receives your reply, it looks for the reply key in the
[list of accepted headers](incoming_email.md#accepted-headers).

If a reply key is found, your response appears as a comment on the relevant issue,
merge request, commit, or other item that triggered the notification.

For more information about the `Message-ID`, `In-Reply-To`, and `References` headers,
see [RFC 5322](https://www.rfc-editor.org/rfc/rfc5322#section-3.6.4).
