---
stage: None - Facilitated functionality, see https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality
group: Unassigned - Facilitated functionality, see https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: Email from GitLab
description: Administrators can send plain-text emails to all users of an instance or members of a group or project.
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

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

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Overview** > **Users**.
1. In the upper-right corner, select **Send email to users** ({{< icon name="mail" >}}).
1. Complete the fields. The email body supports only plain text and does not support HTML, Markdown, or other rich text formats.
1. From the **Select group or project** dropdown list, select the recipient.
1. Select **Send message**.

## Unsubscribing from emails

Users can choose to unsubscribe from receiving emails from GitLab by following
the unsubscribe link in the email. Unsubscribing is unauthenticated in order
to keep this feature simple.

On unsubscribe, users receive an email notification that unsubscribe happened.
The endpoint that provides the unsubscribe option is rate-limited.
