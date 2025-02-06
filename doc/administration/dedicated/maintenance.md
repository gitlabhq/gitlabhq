---
stage: GitLab Dedicated
group: Environment Automation
description: Maintenance windows, release schedules, and emergency maintenance processes for GitLab Dedicated instances.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Dedicated maintenance and release schedule
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Dedicated

GitLab performs regular maintenance to your GitLab Dedicated instance. This page outlines the maintenance windows and release upgrade schedule.

## Maintenance windows

Maintenance is performed outside standard working hours:

| Region | Day | Time (UTC) |
|--------|-----|------------|
| Asia Pacific | Wednesday | 13:00 - 17:00 |
| Europe, Middle East, and Africa | Tuesday | 01:00 - 05:00 |
| Americas (Option 1) | Tuesday | 07:00 - 11:00 |
| Americas (Option 2) | Sunday-Monday | 21:00 - 01:00 |

View your maintenance window in [Switchboard](tenant_overview.md#maintenance-windows), including upcoming and recent maintenance. You can postpone scheduled maintenance to another window in the same week by contacting your Customer Success Manager at least one week in advance.

NOTE:
The scheduled weekly maintenance window is separate from [emergency maintenance](#emergency-maintenance), which cannot be postponed.

### Access during maintenance

Downtime is not expected for the entire duration of your maintenance window. A brief service interruption (less than one minute) may occur when compute resources restart after upgrades, typically during the first half of the maintenance window.

Long-running connections may be interrupted during this period. To minimize disruption, you can implement strategies like automatic recovery and retry.

Longer service interruptions are rare. If extended downtime is expected, GitLab provides advance notice.

NOTE:
Performance degradation or downtime during the scheduled maintenance window does not count against [the system Service Level Availability](https://handbook.gitlab.com/handbook/engineering/infrastructure/team/gitlab-dedicated/slas/).

## Release rollout schedule

GitLab Dedicated is [upgraded](../../subscriptions/gitlab_dedicated/maintenance.md#upgrades-and-patches) to the previous minor version (`N-1`) after each GitLab release. For example, when GitLab 16.9 is released, GitLab Dedicated instances are upgraded to 16.8.

Upgrades occur in your selected [maintenance window](#maintenance-windows) according to the following schedule, where `T` is the date of a [minor GitLab release](../../policy/maintenance.md):

| Calendar days after release | Maintenance window region |
|-------------------|---------------------------|
| `T`+5 | Europe, Middle East, and Africa,<br/> Americas (Option 1) |
| `T`+6 | Asia Pacific |
| `T`+10 | Americas (Option 2) |

For example, GitLab 16.9 released on 2024-02-15. Instances in the EMEA and Americas (Option 1) regions were then upgraded to 16.8 on 2024-02-20, 5 days after the 16.9 release.

NOTE:
If a production change lock (PCL) is active during a scheduled upgrade, GitLab defers the upgrade to the first maintenance window after the PCL ends. For more information, including upcoming and current PCL periods, see [Production Change Lock](https://handbook.gitlab.com/handbook/engineering/infrastructure/team/gitlab-dedicated/#production-change-lock-pcl).

## Emergency maintenance

In an event of a platform outage, degradation, or a security event requiring urgent action,
GitLab performs emergency maintenance per
[the emergency change processes](https://handbook.gitlab.com/handbook/engineering/infrastructure/emergency-change-processes/).

Emergency maintenance is initiated when urgent actions need to be executed by GitLab on a
GitLab Dedicated tenant instance. For example, when a critical (S1) security vulnerability requires urgent patching, GitLab performs emergency maintenance to upgrade your tenant instance to a secure version. This maintenance can occur outside scheduled maintenance windows.

GitLab provides advance emergency maintenance notice when possible and sends complete details after the issue is resolved. The GitLab Support team creates a support ticket and notifies all [Switchboard users](../dedicated/create_instance.md#step-1-get-access-to-switchboard) by email.

You cannot postpone emergency maintenance, because the same process must be applied to all GitLab Dedicated instances to ensure their security and availability.
