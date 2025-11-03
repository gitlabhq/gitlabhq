---
stage: None - Facilitated functionality, see https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality
group: Unassigned - Facilitated functionality, see https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Federated Learning of Cohorts (FLoC)
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Federated Learning of Cohorts (FLoC) was a proposed feature
for Google Chrome that categorized users into different cohorts for interest-based
advertising. FLoC has been replaced by the [Topics API](https://patcg-individual-drafts.github.io/topics/),
which provides similar functionality to help advertisers target and track users.

By default, GitLab opts out of user tracking for interest-based advertising
by sending the following header:

```plaintext
Permissions-Policy: interest-cohort=()
```

This header prevents users from being tracked and categorized in any GitLab instance.
The header is compatible with the Topics API and the deprecated FLoC system.

To enable user tracking for interest-based advertising:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **General**.
1. Expand **Federated Learning of Cohorts (FLoC)**.
1. Select the **Participate in FLoC** checkbox.
1. Select **Save changes**.
