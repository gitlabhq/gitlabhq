---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Manage Switchboard users and configure notification preferences, including SMTP email service settings.
title: GitLab Dedicated users and notifications
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

Manage users who can access Switchboard and configure email notifications for your GitLab Dedicated instance.

## Switchboard user management

Switchboard is the administrative interface for managing your GitLab Dedicated instance.
Switchboard users are administrators who can configure and monitor the instance.

{{< alert type="note" >}}

Switchboard users are separate from the users on your GitLab Dedicated instance.
For information about configuring authentication for both Switchboard and your GitLab Dedicated instance,
see [authentication for GitLab Dedicated](authentication/_index.md).

{{< /alert >}}

### Add Switchboard users

Administrators can add two types of Switchboard users to manage and view their GitLab Dedicated instance:

- **Read only**: Users can only view instance data.
- **Admin**: Users can edit the instance configuration and manage users.

To add a new user to Switchboard for your GitLab Dedicated instance:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. From the top of the page, select **Users**.
1. Select **New user**.
1. Enter the **Email** and select a **Role** for the user.
1. Select **Create**.

An invitation to use Switchboard is sent to the user.

### Reset your password

To reset your Switchboard password:

1. On the Switchboard sign-in page, enter your email address then select **Continue**.
1. Select **Forgot your password?**.
1. Select **Send verification code**.
1. Check your email for the verification code.
1. Enter the verification code then select **Continue**.
1. Enter and confirm your new password.
1. Select **Save password**.

After your password is reset, you're automatically signed in to Switchboard.
If multi-factor authentication (MFA) is set up for your account, you're prompted to enter your MFA verification code.

### Reset multi-factor authentication

To reset your MFA for Switchboard, [submit a support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).
The support team will help you regain access to your account.

## Email notifications

GitLab sends email notifications about instance incidents, maintenance, performance issues, 
and security updates.

Notifications are sent to:

- Switchboard users: Receive notifications based on their notification settings.
- Operational contacts: Receive notifications for important instance events and service updates,
  regardless of their notification settings.

Operational contacts receive customer notifications, even if recipients:

- Are not Switchboard users.
- Have not signed in to Switchboard.
- Turn off email notifications.

### Manage email addresses for operational contacts

Add multiple email addresses or a distribution list as operational contacts.

To manage operational contact addresses:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Expand **Contact information**.
1. Under **Operational email addresses**:
   - To add a new address:
     1. Select **Add email address**.
     1. Enter the email address.
     1. Select **Save**.
   - To edit an existing address:
     1. Select the pencil ({{< icon name="pencil" >}}) next to the address.
     1. Edit the email address.
     1. Select **Save**.
   - To delete an address:
     1. Select the trash can ({{< icon name="remove" >}}) next to the address.
     1. On the confirmation dialog, select **Delete**.

### Manage notification preferences

To receive email notifications, you must first:

- Receive an email invitation and sign in to Switchboard.
- Set up a password and two-factor authentication (2FA).

To turn your personal notifications on or off:

1. Select the dropdown list next to your user name.
1. Select **Toggle email notifications off** or **Toggle email notifications on**.

An alert confirms that your notification preferences have been updated.

## SMTP email service

You can configure an [SMTP](../../../subscriptions/gitlab_dedicated/_index.md#email-service) email service for your GitLab Dedicated instance.

To configure an SMTP email service, [submit a support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)
with the credentials and settings for your SMTP server.
