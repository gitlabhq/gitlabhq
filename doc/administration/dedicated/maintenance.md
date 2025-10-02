---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Scheduled maintenance windows, emergency procedures, and contact management for GitLab Dedicated instances.
title: GitLab Dedicated maintenance operations
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

GitLab Dedicated provides regular maintenance for your instance to ensure security,
reliability, and optimal performance during scheduled weekly windows.

## Maintenance windows

Maintenance is performed during scheduled weekly windows outside standard working hours.
You choose your maintenance window during onboarding, and it cannot be changed after
your instance is created.

### Maintenance window schedule

| Region                          | Day           | Time (UTC) |
| ------------------------------- | ------------- | ---------- |
| Asia Pacific                    | Wednesday     | 1:00 PM-5:00 PM |
| Europe, Middle East, and Africa | Tuesday       | 1:00 AM-5:00 AM |
| Americas (Option 1)             | Tuesday       | 7:00 AM-11:00 AM |
| Americas (Option 2)             | Sunday-Monday | 9:00 PM-1:00 AM |

To view your assigned maintenance window, go to [Switchboard](tenant_overview.md).

During scheduled maintenance windows, the following tasks might be performed:

- Application and operating system software patches and upgrades
- Operating system restarts
- Infrastructure upgrades
- Security and availability enhancements
- Feature enhancements

### Access during maintenance

Downtime is not expected for the entire duration of your maintenance window. A brief
service interruption (less than one minute) may occur when compute resources restart
after upgrades, typically during the first half of the maintenance window.

Long-running connections may be interrupted during this period. To minimize disruption,
you can implement strategies like automatic recovery and retry.

Longer service interruptions are rare. If extended downtime is expected, you receive advance notice.

{{< alert type="note" >}}

Performance degradation or downtime during the scheduled maintenance window does not
count against the system service level availability (SLA).

{{< /alert >}}

### Scheduling exceptions

A production change lock (PCL) is a complete pause on all production changes during periods of reduced team
availability, such as major holidays. A PCL ensures system stability when support resources are limited.

During a PCL, the following is paused:

- Configuration changes using Switchboard
- Code deployments or infrastructure changes
- Automated maintenance
- New customer onboarding

If a PCL is active during your scheduled upgrade, the upgrade is deferred
to the first maintenance window after the PCL ends.

When a PCL is active, you see a notification banner in Switchboard.

## Zero-downtime upgrades

GitLab Dedicated provides zero-downtime upgrades to ensure backward compatibility for your instance.
When no infrastructure changes or maintenance tasks require downtime,
you can continue using your instance safely during upgrades.

To ensure asset availability during version upgrades:

1. Each static asset has a unique name that changes when its content changes.
1. Browsers cache each static asset.
1. Each request from the same browser routes to the same server temporarily.

Upgrades are usually unnoticeable. In rare cases, you might experience temporary
interface inconsistencies during an upgrade. If this occurs, refresh the page
to resolve any visual inconsistencies.

{{< alert type="note" >}}

Implementing a caching proxy in your network further reduces the risk of
interface inconsistencies during upgrades.

{{< /alert >}}

## Emergency maintenance

Emergency maintenance is initiated when your instance requires urgent actions.
This maintenance can happen outside your scheduled maintenance windows and cannot be postponed.

For example, when a critical (S1) security vulnerability requires urgent patching,
your instance receives emergency maintenance to upgrade it to a secure version.

During emergency maintenance, stability and security are prioritized while minimizing
impact to your service. All changes follow internal processes and undergo appropriate
internal review and approval before they are applied to your instance.

You receive advance notice when possible and complete details after the issue
is resolved. The Support team:

- Creates a support ticket for tracking.
- Sends email notifications to your operational contacts.
- Copies your Customer Success Manager (CSM) on all communications.

To ensure you receive these notifications,
[review your contact information](configure_instance/users_notifications.md#manage-email-addresses-for-operational-contacts)
in Switchboard.

## Related topics

- [GitLab Dedicated releases and versioning](releases.md)
- [Tenant overview](tenant_overview.md)
- [GitLab release and maintenance policy](../../policy/maintenance.md)
- [Zero-downtime upgrades](../../update/zero_downtime.md)
