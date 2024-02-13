---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Rate limits on raw endpoints

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/30635) in GitLab 12.2.

This setting defaults to `300` requests per minute, and allows you to rate limit the requests to raw endpoints:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Network**.
1. Expand **Performance optimization**.

For example, requests over `300` per minute to `https://gitlab.com/gitlab-org/gitlab-foss/raw/master/app/controllers/application_controller.rb` are blocked. Access to the raw file is released after 1 minute.

![Rate limits on raw endpoints](img/rate_limits_on_raw_endpoints.png)

This limit is:

- Applied independently per project, per file path.
- Not applied per IP address.
- Active by default. To disable, set the option to `0`.

Requests over the rate limit are logged into `auth.log`.
