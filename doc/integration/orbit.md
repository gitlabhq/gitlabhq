---
stage: Analytics
group: Knowledge Graph
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Orbit
description: Configure GitLab Orbit for GitLab Self-Managed and GitLab Dedicated.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Start a free trial

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/260183) in GitLab 19.5 behind a feature flag named `orbit_trial`, disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.
> This feature is available for testing, but not ready for production use.

If your top-level group is not yet licensed for Orbit, you can start a free trial.
The trial gives the group free GitLab credits for Orbit.
Groups that do not meet the trial criteria see a **Contact sales** option instead.

Prerequisites:

- You must have the Owner role for the top-level group.
- The group must meet the trial criteria.

To start a free trial:

1. In the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Orbit**.
1. Turn on the **Turn on GitLab Orbit** toggle.
1. On the confirmation dialog, select **Turn on GitLab Orbit**.

After you start the trial, Orbit turns on for the group and indexes the group, its subgroups,
and its projects.
Indexing can take up to a few hours.

The trial applies to that one group only.
Only Orbit can use the trial credits.
When the trial ends or the credits run out, Orbit pauses.
To keep using Orbit, contact sales.

## Start a free trial for the instance

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/261678) in GitLab 19.6 behind feature flags named `orbit_trial` and `orbit_promo_access_gate`, disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by feature flags.
> For more information, see the history.
> This feature is available for testing, but not ready for production use.

When your instance is not in the Orbit beta and has not purchased Orbit, an administrator
can start a free trial for the instance.
The trial gives the instance free GitLab credits for Orbit, and all top-level groups share them.

Prerequisites:

- You must have administrator access.
- Your instance must have an online cloud license.
- The instance must meet the trial criteria.

To start a free trial for the instance:

1. In the left sidebar, at the bottom, select **Admin**.
1. Select **GitLab Orbit**.
1. Select **Start trial**.
1. On the confirmation dialog, select **Start trial**.

You can also start the trial from the **Overview** tab of the Orbit dashboard: select
**Go to GitLab Orbit settings** on the card over the map, then follow the steps on the **Admin** Orbit page.

You and the Owners of top-level groups can turn on Orbit for groups before and during the trial.
The trial credits pay for Orbit queries.

When the trial ends or the credits run out, Orbit keeps indexing your groups, but Orbit queries stop.
To run Orbit queries again, contact sales.

## Turn Orbit on or off for your groups

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/orbit/knowledge-graph/-/work_items/1364) in GitLab 19.6.

{{< /history >}}

The **Status** tab lists your top-level groups with their Orbit state and index status.
For a group that Orbit is indexing, select the information icon ({{< icon name="information-o" >}})
to see the index status of each area.

Prerequisites:

- To turn Orbit on or off, you must have the Owner role for the top-level group.

To turn Orbit on or off for your groups:

1. In the left sidebar, select **Your work**.
1. Select **GitLab Orbit**.
1. Select the **Status** tab.
1. Select the groups.
1. Select **Actions** > **Turn on GitLab Orbit** or **Actions** > **Turn off GitLab Orbit**.
1. On the confirmation dialog, select **Turn on GitLab Orbit** or **Turn off GitLab Orbit**.

On GitLab.com, turning on Orbit for an eligible group starts the free trial of that group.
The confirmation dialog shows the trial that each group gets.
On GitLab Self-Managed and GitLab Dedicated, during a free trial for the instance, the confirmation
dialog shows the end date of the trial.

On GitLab Self-Managed and GitLab Dedicated, you can turn on Orbit for a group without a free trial
or a purchase. Orbit indexes the group, and the **Status** tab shows the index status.
When the `orbit_promo_access_gate` feature flag is enabled, the instance needs a free trial or
a purchase to run Orbit queries. Until then, the **Overview** tab shows the item counts of your groups,
and a card over the map says how the instance gets Orbit queries. An administrator of an instance
that can start its free trial sees **Go to GitLab Orbit settings** on the card. The **Query editor** tab
says how to get Orbit queries. After the free trial of the instance ends, you can still turn on Orbit
for more groups.

## Orbit in GitLab Duo default

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/orbit/knowledge-graph/-/work_items/1319) in GitLab 19.5.

{{< /history >}}

Orbit in GitLab Duo is on by default. In their preferences, users choose which
Orbit-powered features to use.

On GitLab.com, Orbit in GitLab Duo is on for members of a top-level group with Orbit on.
On GitLab Self-Managed and GitLab Dedicated, an administrator sets the instance-wide
switch and the instance must have a license with the Orbit feature.

Orbit availability, licensing, and namespace enrollment requirements still apply.

### Turn off Orbit in GitLab Duo for the instance

Prerequisites:

- You must have administrator access.
- Your instance must have a license with the Orbit feature.

To turn off Orbit in GitLab Duo for all users on the instance:

1. In the left sidebar, at the bottom, select **Admin**.
1. Select **GitLab Orbit**.
1. Turn off the **Turn on GitLab Orbit in GitLab Duo** toggle.

The setting is saved when you change the toggle.

## Index top-level group namespaces automatically

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/606375) in GitLab 19.4.

{{< /history >}}

Prerequisites:

- You must have administrator access.
- Your instance must have a license with the Orbit feature.

To index existing and new top-level group namespaces automatically:

1. In the left sidebar, at the bottom, select **Admin**.
1. Select **GitLab Orbit**.
1. Turn on the **Turn on GitLab Orbit for all top-level groups automatically** toggle.
1. Select **Turn on for all top-level groups**.

When you turn on the setting, GitLab enqueues a background job.
The job enrolls top-level group namespaces that are not already enrolled or excluded by an
administrator.
Enrollment happens shortly afterward rather than immediately.
An hourly background job also enrolls newly created top-level groups and removes enrollments for
excluded groups.
The hourly job acts as a safety net after direct database changes.
These changes can take up to one hour.
Personal namespaces are not enrolled.

The job enrolls groups without a free trial or a purchase.
When the `orbit_promo_access_gate` feature flag is enabled and the free trial of the instance
has ended, the job enrolls groups only when the instance has purchased Orbit.

When you turn off **Turn on GitLab Orbit for all top-level groups automatically**, existing non-excluded
enrollments remain.
The background job does not enroll new top-level groups until you turn on the setting again.

### Exclude top-level groups from automatic indexing

Administrators can manage exclusions regardless of whether automatic indexing is enabled:

1. In the left sidebar, at the bottom, select **Admin**.
1. Select **GitLab Orbit**.
1. In **Top-level groups**, select the groups to exclude.
1. Select **Actions** > **Exclude from automatic indexing**.
1. If Orbit is on for a selected group, select **Exclude** to confirm.

Excluded groups are not automatically enrolled.
If an excluded group is already indexed, the hourly background job removes its enrollment and index.
To allow automatic enrollment again, select the group, then select **Actions** > **Remove exclusion**.
To turn on Orbit for an excluded group, remove the exclusion first.

> [!note]
> This setting has no effect on GitLab.com.

## View Orbit status

To view the Orbit configuration and indexing status, run:

```shell
sudo gitlab-rake gitlab:orbit:info
```
