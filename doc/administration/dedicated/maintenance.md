---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Maintenance windows, release schedules, and emergency maintenance processes for GitLab Dedicated instances.
title: GitLab Dedicated maintenance and release schedule
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

Regular maintenance is performed on GitLab Dedicated instances according to scheduled maintenance windows and release upgrade timelines.

During scheduled maintenance windows, the following tasks might be performed:

- Application and operating system software patches and upgrades.
- Operating system restarts.
- Infrastructure upgrades.
- Activities needed to operate and enhance the availability or security of your tenant.
- Feature enhancements.

## Maintenance windows

Maintenance is performed outside standard working hours:

| Region                          | Day           | Time (UTC) |
|---------------------------------|---------------|------------|
| Asia Pacific                    | Wednesday     | 1:00 PM-5:00 PM |
| Europe, Middle East, and Africa | Tuesday       | 1:00 AM-5:00 AM |
| Americas (Option 1)             | Tuesday       | 7:00 AM-11:00 AM |
| Americas (Option 2)             | Sunday-Monday | 9:00 PM-1:00 AM |

You choose your maintenance window during [onboarding](create_instance/_index.md#step-2-create-your-gitlab-dedicated-instance).
This window cannot be changed after your instance is created.
To view your maintenance window, go to [Switchboard](tenant_overview.md#maintenance-windows).

{{< alert type="note" >}}

The scheduled weekly maintenance window is separate from [emergency maintenance](#emergency-maintenance), which can happen at any time.

{{< /alert >}}

### Access during maintenance

Downtime is not expected for the entire duration of your maintenance window. A brief service interruption (less than one minute) may occur when compute resources restart after upgrades, typically during the first half of the maintenance window.

Long-running connections may be interrupted during this period. To minimize disruption, you can implement strategies like automatic recovery and retry.

Longer service interruptions are rare. If extended downtime is expected, GitLab provides advance notice.

{{< alert type="note" >}}

Performance degradation or downtime during the scheduled maintenance window does not count against the system service level availability (SLA).

{{< /alert >}}

## Release rollout schedule

GitLab Dedicated is [upgraded](../../subscriptions/gitlab_dedicated/maintenance.md#upgrades-and-patches) to the previous minor version (`N-1`) after each GitLab release. For example, when GitLab 16.9 is released, GitLab Dedicated instances are upgraded to 16.8.

Upgrades occur in your selected [maintenance window](#maintenance-windows) according to the following schedule, where `T` is the date of a [minor GitLab release](../../policy/maintenance.md):

| Calendar days after release | Maintenance window region |
|-------------------|---------------------------|
| `T`+5 | Europe, Middle East, and Africa,<br/> Americas (Option 1) |
| `T`+6 | Asia Pacific |
| `T`+10 | Americas (Option 2) |

For example, GitLab 16.9 released on 2024-02-15. Instances in the EMEA and Americas (Option 1) regions were then upgraded to 16.8 on 2024-02-20, 5 days after the 16.9 release.

{{< alert type="note" >}}

If a production change lock (PCL) is active during a scheduled upgrade, GitLab defers the upgrade to the first maintenance window after the PCL ends.

A PCL for GitLab Dedicated is a complete pause on all production changes during periods of reduced team availability such as major holidays. During a PCL, the following is paused:

- Configuration changes using Switchboard.
- Code deployments or infrastructure changes.
- Automated maintenance.
- New customer onboarding.

When a PCL is in effect, Switchboard displays a notification banner to alert users.
PCLs help ensure system stability when support resources may be limited.

{{< /alert >}}

## Emergency maintenance

Emergency maintenance is initiated when urgent actions are required on a GitLab Dedicated tenant instance. For example, when a critical (S1) security vulnerability requires urgent patching, GitLab performs emergency maintenance to upgrade your tenant instance to a secure version. This maintenance can occur outside scheduled maintenance windows.

GitLab prioritizes stability and security while minimizing customer impact during emergency maintenance. The specific maintenance procedures follow established internal processes, and all changes undergo appropriate internal review and approval before they are applied.

GitLab provides advance notice when possible and sends complete details
after the issue is resolved. The GitLab Support team:

- Creates a support ticket for tracking.
- Sends email notifications only to addresses listed as **Operational email addresses** in the
  **Customer communication** section of Switchboard.
- Copies your Customer Success Manager (CSM) on all communications.

You cannot postpone emergency maintenance because it is critical to stability and security.

### Verify your operational contacts

To ensure you receive maintenance notifications:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com/).
1. Select your tenant.
1. In the **Customer communication** section, review the email addresses listed under **Operational email addresses**.

To update these contacts, submit a support ticket.
