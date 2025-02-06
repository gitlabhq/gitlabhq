---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Email from GitLab
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

Administrators can email all users, or users of a chosen group or project.
Users receive the email at their primary email address.

You might use this functionality to notify your users:

- About a new project, a new feature, or a new product launch.
- About a new deployment, or that downtime is expected.

For information about email notifications originating from GitLab, read
[GitLab notification emails](../user/profile/notifications.md).

## Sending emails to users from GitLab

You can send email notifications to all users, or only to users in a specific group or project.
You can send email notifications once every 10 minutes.

To send an email:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
1. In the upper-right corner, select **Send email to users** (**{mail}**).
1. Complete the fields. The email body supports only plain text and does not support HTML, Markdown, or other rich text formats.
1. From the **Select group or project** dropdown list, select the recipient.
1. Select **Send message**.

## Unsubscribing from emails

Users can choose to unsubscribe from receiving emails from GitLab by following
the unsubscribe link in the email. Unsubscribing is unauthenticated in order
to keep this feature simple.

On unsubscribe, users receive an email notification that unsubscribe happened.
The endpoint that provides the unsubscribe option is rate-limited.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
