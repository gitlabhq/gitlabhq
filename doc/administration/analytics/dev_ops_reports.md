---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: DevOps adoption by instance
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

DevOps Reports give you an overview of your entire instance's adoption of
development, security, and operations features, along with a DevOps score.

For more information about this feature, see also [DevOps adoption by group](../../user/group/devops_adoption/_index.md).

## DevOps score

NOTE:
To view the DevOps score, you must activate your GitLab instance's [Service Ping](../settings/usage_statistics.md#service-ping).
DevOps Score is a comparative tool, so your score data must be centrally processed by GitLab Inc. first.
If Service Ping is not activated, the DevOps score value is 0.

You can use the DevOps score to compare your DevOps status to other organizations.

The **DevOps Score** displays usage of major GitLab features on your instance over
the last 30 days, averaged over the number of billable users in that time period.

- **Your score** represents the average of your feature scores.
- **Your usage** represents the average usage of a feature per billable user in the last 30 days.
- The **Leader usage** is calculated from top-performing instances based on
[Service Ping data](../settings/usage_statistics.md#service-ping) collected by GitLab.

Service Ping data is aggregated on GitLab servers for analysis.
Your usage information is **not sent** to any other GitLab instances.
If you have just started using GitLab, it might take a few weeks for data to be collected
before this feature becomes available.

## View DevOps Reports

To view DevOps Reports for your instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Analytics > DevOps Reports**.

## Add a group to DevOps Reports

Prerequisites:

- You must have at least the Reporter role for the group.

To add a group to the DevOps Reports:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Analytics > DevOps Reports**.
1. From the **Add or remove groups** dropdown list, select the group you want to add.

## Remove a group from DevOps Reports

Prerequisites:

- You must have at least the Reporter role for the group.

To remove a group from the DevOps Reports:

1. On the left sidebar, at the bottom, select **Admin area**.
1. Select **Analytics > DevOps Reports**.
1. Either:

- From the **Add or remove groups** dropdown list, clear the group you want to remove.
- From the **Adoption by group** table, in the row of the group you want to remove, select
**Remove Group from the table** (**{remove}**).
