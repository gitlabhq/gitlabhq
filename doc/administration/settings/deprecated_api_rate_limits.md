---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Define limits for deprecated APIs on GitLab Self-Managed."
title: Deprecated API rate limits
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Deprecated API endpoints are those which have been replaced with alternative
functionality, but cannot be removed without breaking backward compatibility.
Setting a restrictive rate limit on these endpoints can encourage users to
switch to the alternatives.

## Deprecated API endpoints

Not all deprecated API endpoints are included in this rate limit - just those
that might have a performance impact:

- [`GET /groups/:id`](../../api/groups.md#get-a-single-group) **without** the `with_projects=0` query parameter.

## Define Deprecated API rate limits

Rate limits for deprecated API endpoints are disabled by default. When enabled, they supersede
the general user and IP rate limits for requests to deprecated endpoints. You can keep any general user
and IP rate limits already in place, and increase or decrease the rate limits
for deprecated API endpoints. No other new features are provided by this override.

Prerequisites:

- You must have administrator access to the instance.

To override the general user and IP rate limits for requests to deprecated API endpoints:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Network**.
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
- [User and IP rate limits](../settings/user_and_ip_rate_limits.md)
