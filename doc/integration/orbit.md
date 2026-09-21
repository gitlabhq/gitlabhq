---
stage: Analytics
group: Knowledge Graph
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Orbit
description: Configure GitLab Orbit for a GitLab Self-Managed instance.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

## Index top-level group namespaces automatically

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/606375) in GitLab 19.4.

{{< /history >}}

Prerequisites:

- You must have administrator access.
- Your instance must have a license with the Orbit feature.

To index existing and new top-level group namespaces automatically:

1. In the left sidebar, at the bottom, select **Admin**.
1. Select **Orbit**.
1. Expand **Orbit settings**.
1. Select **Index root namespaces automatically**.
1. Select **Save changes**.

When you save the setting, GitLab enqueues a background job.
The job enrolls top-level group namespaces that are not already enrolled or excluded by an
administrator.
Enrollment happens shortly afterward rather than immediately.
An hourly background job also enrolls newly created top-level groups and removes enrollments for
excluded groups.
The hourly job acts as a safety net after direct database changes.
These changes can take up to one hour.
Personal namespaces are not enrolled.

When you clear **Index root namespaces automatically**, existing non-excluded enrollments remain.
The background job does not enroll new top-level groups until you select the setting again.

### Exclude top-level groups from automatic indexing

Administrators can manage exclusions regardless of whether automatic indexing is enabled:

1. In the left sidebar, at the bottom, select **Admin**.
1. Select **Orbit**.
1. In **Excluded groups**, select **Exclude group**.
1. Select a top-level group, then select **Exclude**.

Excluded groups are not automatically enrolled. If an excluded group is already indexed, GitLab
removes its enrollment and index within a few minutes. To allow automatic enrollment again, select
**Remove** next to the group.

> [!note]
> This setting has no effect on GitLab.com.

## View Orbit status

To view the Orbit configuration and indexing status, run:

```shell
sudo gitlab-rake gitlab:orbit:info
```
