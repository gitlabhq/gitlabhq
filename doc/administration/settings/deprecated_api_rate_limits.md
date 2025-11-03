---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Define limits for deprecated APIs on GitLab.
gitlab_dedicated: yes
title: Deprecated API rate limits
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Deprecated API endpoints have been replaced with alternative features, but they can't be removed
without breaking backward compatibility. To encourage users to switch to the alternative, set a
restrictive rate limit on deprecated endpoints.

## Deprecated API endpoints

This rate limit does not include all deprecated API endpoints, just the ones that are likely to
affect performance:

- [`GET /groups/:id`](../../api/groups.md#get-a-single-group) without the `with_projects=0` query parameter.

## Define deprecated API rate limits

Rate limits for deprecated API endpoints are disabled by default. When enabled, they supersede
the general user and IP rate limits for requests to deprecated endpoints. You can keep any general user
and IP rate limits already in place, and increase or decrease the rate limits
for deprecated API endpoints. No other new features are provided by this override.

Prerequisites:

- You must have administrator access to the instance.

To override the general user and IP rate limits for requests to deprecated API endpoints:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **Network**.
1. Expand **Deprecated API Rate Limits**.
1. Select the checkboxes for the types of rate limits you want to enable:
   - **Unauthenticated API request rate limit**
   - **Authenticated API request rate limit**
1. If you selected **unauthenticated**:
   1. Select the **Maximum unauthenticated API requests per period per IP**.
   1. Select the **Unauthenticated API rate limit period in seconds**.
1. If you selected **authenticated**:
   1. Select the **Maximum authenticated API requests per period per user**.
   1. Select the **Authenticated API rate limit period in seconds**.

## Related topics

- [Rate limits](../../security/rate_limits.md)
- [User and IP rate limits](user_and_ip_rate_limits.md)
