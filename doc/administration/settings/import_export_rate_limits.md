---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Rate limits for imports and exports of project and groups
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

You can configure the rate limits for imports and exports of projects and groups:

To change a rate limit:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Network**.
1. Expand **Import and export rate limits**.
1. Change the value of any rate limit. The rate limits are per minute per user, not per IP address.
   Set to `0` to disable a rate limit.

| Limit                   | Default |
|-------------------------|---------|
| Project Import          | 6       |
| Project Export          | 6       |
| Project Export Download | 1       |
| Group Import            | 6       |
| Group Export            | 6       |
| Group Export Download   | 1       |

When a user exceeds a rate limit, it is logged in `auth.log`.
