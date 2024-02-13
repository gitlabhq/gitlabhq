---
stage: Service Management
group: Respond
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Configuration

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

GitLab Performance Monitoring is disabled by default. To enable it and change any of its
settings:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Metrics and profiling**.
1. Add the necessary configuration changes.
1. Restart all GitLab for the changes to take effect:

   - For Linux package installations: `sudo gitlab-ctl restart`
   - For self-compiled installations: `sudo service gitlab restart`

NOTE:
Removed [in GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/30786). Use the
[Prometheus integration](../prometheus/index.md) instead.

## Pending migrations

When any migrations are pending, the metrics are disabled until the migrations
have been performed.

Read more on:

- [Introduction to GitLab Performance Monitoring](index.md)
- [Grafana Install/Configuration](grafana_configuration.md)
