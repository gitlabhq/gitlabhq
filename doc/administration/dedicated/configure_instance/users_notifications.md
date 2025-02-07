---
stage: GitLab Dedicated
group: Switchboard
description: Manage Switchboard users and configure notification preferences, including SMTP email service settings.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Dedicated users and notifications
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Dedicated

## Add Switchboard users

Administrators can add Switchboard users to their GitLab Dedicated instance. There are two types of users:

- **Read only**: Users can only view instance data.
- **Admin**: Users can edit the instance configuration and manage users.

To add a new user to your GitLab Dedicated instance:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. From the top of the page, select **Users**.
1. Select **New user**.
1. Enter the **Email** and select a **Role** for the user.
1. Select **Create**.

An invitation to use Switchboard is sent to the user.

### Manage notification preferences

You can specify whether you want to receive email notifications from Switchboard. You will only receive notifications after you:

- Receive an email invitation and first sign in to Switchboard.
- Set up a password and two-factor authentication (2FA) for your user account.

To manage your own email notification preferences:

1. From any page, open the dropdown next to your user name.
1. To stop receiving email notifications, select **Toggle email notifications off**.
1. To resume receiving email notifications, select **Toggle email notifications on**.

You will see an alert confirming that your notification preferences have been updated.

## SMTP email service

You can configure an [SMTP](../../../subscriptions/gitlab_dedicated/_index.md#email-service) email service for your GitLab Dedicated instance.

To configure an SMTP email service, submit a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) with the credentials and settings for your SMTP server.
