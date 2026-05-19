---
stage: Facilitated functionality
group: Facilitated functionality
info: For more information, see <https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality>
description: Send email notifications to all users or specific groups and projects.
gitlab_dedicated: yes
title: Email from GitLab
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

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Overview** > **Users**.
1. In the upper-right corner, next to the **New user** button, select **Send email to users** ({{< icon name="mail" >}}).
1. Complete the fields. The email body supports only plain text and does not support HTML, Markdown, or other rich text formats.
1. From the **Select group or project** dropdown list, select the recipient.
1. Select **Send message**.

## Unsubscribing from emails

Users can choose to unsubscribe from receiving emails from GitLab by following
the unsubscribe link in the email. Unsubscribing is unauthenticated in order
to keep this feature simple.

On unsubscribe, users receive an email notification that unsubscribe happened.
The endpoint that provides the unsubscribe option is rate-limited.
