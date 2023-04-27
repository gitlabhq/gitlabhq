---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Rate limits for imports and exports of project and groups **(FREE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/35728) in GitLab 13.2.

You can configure the rate limits for imports and exports of projects and groups:

To change a rate limit:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Network**, then expand **Import and export rate limits**.
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
