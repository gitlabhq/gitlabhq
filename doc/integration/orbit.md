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

A background job runs every five minutes and enrolls top-level group namespaces that are not already
enrolled.
Personal namespaces are not enrolled.

When you clear **Index root namespaces automatically**, existing enrollments remain.
The background job does not enroll new top-level groups until you select the setting again.

> [!note]
> This setting has no effect on GitLab.com.

## View Orbit status

To view the Orbit configuration and indexing status, run:

```shell
sudo gitlab-rake gitlab:orbit:info
```
