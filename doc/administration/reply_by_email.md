# Reply by email

GitLab can be set up to allow users to comment on issues and merge requests by
replying to notification emails.

## Requirement

Make sure [incoming email](incoming_email.md) is setup.

## How it works?

### 1. GitLab sends a notification email

When GitLab sends a notification and Reply by email is enabled, the `Reply-To`
header is set to the address defined in your GitLab configuration, with the
`%{key}` placeholder (if present) replaced by a specific "reply key". In
addition, this "reply key" is also added to the `References` header.

### 2. You reply to the notification email

When you reply to the notification email, your email client will:

- send the email to the `Reply-To` address it got from the notification email
- set the `In-Reply-To` header to the value of the `Message-ID` header from the
  notification email
- set the `References` header to the value of the `Message-ID` plus the value of
  the notification email's `References` header.

### 3. GitLab receives your reply to the notification email

When GitLab receives your reply, it will look for the "reply key" in the
following headers, in this order:

1. the `To` header
1. the `References` header

If it finds a reply key, it will be able to leave your reply as a comment on
the entity the notification was about (issue, merge request, commit...).

For more details about the `Message-ID`, `In-Reply-To`, and `References headers`,
please consult [RFC 5322](https://tools.ietf.org/html/rfc5322#section-3.6.4).
