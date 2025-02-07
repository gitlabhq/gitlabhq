---
stage: GitLab Dedicated
group: Switchboard
description: Configure your GitLab Dedicated instance with Switchboard.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configure GitLab Dedicated
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Dedicated

The instructions on this page guide you through configuring your GitLab Dedicated instance, including enabling and updating the settings for [available functionality](../../../subscriptions/gitlab_dedicated/_index.md#available-features).

Administrators can configure additional settings in their GitLab application by using the [**Admin** area](../../admin_area.md).

As a GitLab-managed solution, you cannot change any GitLab functionality controlled by SaaS environment settings. Examples of such SaaS environment settings include `gitlab.rb` configurations and access to shell, Rails console, and PostgreSQL console.

GitLab Dedicated engineers do not have direct access to your environment, except for [break glass situations](../../../subscriptions/gitlab_dedicated/_index.md#access-controls).

NOTE:
An instance refers to a GitLab Dedicated deployment, whereas a tenant refers to a customer.

## Configure your instance using Switchboard

You can use Switchboard to make limited configuration changes to your GitLab Dedicated instance.

The following configuration settings are available in Switchboard:

- [IP allowlist](../configure_instance/network_security.md#ip-allowlist)
- [SAML settings](../configure_instance/saml.md)
- [Custom certificates](../configure_instance/network_security.md#custom-certificates)
- [Outbound private links](../configure_instance/network_security.md#outbound-private-link)
- [Private hosted zones](../configure_instance/network_security.md#private-hosted-zones)

Prerequisites:

- You must have the [Admin](../configure_instance/users_notifications.md#add-switchboard-users) role.

To make a configuration change:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. At the top of the page, select **Configuration**.
1. Follow the instructions in the relevant sections below.

For all other instance configurations, submit a support ticket according to the
[configuration change request policy](_index.md#request-configuration-changes-with-a-support-ticket).

### Apply configuration changes in Switchboard

You can apply configuration changes made in Switchboard immediately or defer them until your next scheduled weekly [maintenance window](../../dedicated/maintenance.md#maintenance-windows).

When you apply changes immediately:

- Deployment can take up to 90 minutes.
- Changes are applied in the order they're saved.
- You can save multiple changes and apply them in one batch.

After the deployment job is complete, you receive an email notification. Check your spam folder if you do not see a notification in your main inbox.
All users with access to view or edit your tenant in Switchboard receive a notification for each change. For more information, see [Manage Switchboard notification preferences](../configure_instance/users_notifications.md#manage-notification-preferences).

NOTE:
You only receive email notifications for changes made by a Switchboard tenant administrator. Changes made by a GitLab Operator (for example, a GitLab version update completed during a maintenance window) do not trigger email notifications.

## Configuration change log

The **Configuration change log** page in Switchboard tracks changes made to your GitLab Dedicated instance.

Each change log entry includes the following details:

| Field                | Description                                                                                                                                   |
|----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| Configuration change | Name of the configuration setting that changed.                                                                                               |
| User                 | Email address of the user that made the configuration change. For changes made by a GitLab Operator, this value appears as `GitLab Operator`. |
| IP                   | IP address of the user that made the configuration change. For changes made by a GitLab Operator, this value appears as `Unavailable`.        |
| Status               | Whether the configuration change is initiated, in progress, completed, or deferred.                                                           |
| Start time           | Start date and time when the configuration change is initiated, in UTC.                                                                       |
| End time             | End date and time when the configuration change is deployed, in UTC.                                                                          |

Each configuration change has a status:

| Status | Description |
|---|---|
| Initiated | Configuration change is made in Switchboard, but not yet deployed to the instance. |
| In progress | Configuration change is actively being deployed to the instance. |
| Complete | Configuration change has been deployed to the instance. |
| Delayed | Initial job to deploy a change has failed and the change has not yet been assigned to a new job. |

### View the configuration change log

To view the configuration change log:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. Select your tenant.
1. At the top of the page, select **Configuration change log**.

Each configuration change appears as an entry in the table. Select **View details** to see more information about each change.

## Request configuration changes with a support ticket

Certain configuration changes require that you submit a support ticket to request the changes. For more information on how to create a support ticket, see [creating a ticket](https://about.gitlab.com/support/portal/#creating-a-ticket).

Configuration changes requested with a [support ticket](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) adhere to the following policies:

- Are applied during your environment's weekly four-hour maintenance window.
- Can be requested for options specified during onboarding or for optional features listed on this page.
- May be postponed to the following week if GitLab needs to perform high-priority maintenance tasks.
- Can't be applied outside the weekly maintenance window unless they qualify for [emergency support](https://about.gitlab.com/support/#how-to-engage-emergency-support).

NOTE:
Even if a change request meets the minimum lead time, it might not be applied during the upcoming maintenance window.
