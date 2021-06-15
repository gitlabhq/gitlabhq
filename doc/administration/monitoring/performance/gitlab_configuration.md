---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Configuration **(FREE SELF)**

GitLab Performance Monitoring is disabled by default. To enable it and change any of its
settings:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Settings > Metrics and profiling**
  (`/admin/application_settings/metrics_and_profiling`).
1. Add the necessary configuration changes.
1. Restart all GitLab for the changes to take effect:

   - For Omnibus GitLab installations: `sudo gitlab-ctl restart`
   - For installations from source: `sudo service gitlab restart`

NOTE:
Removed [in GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/30786). Use the
[Prometheus integration](../prometheus/index.md) instead.

## Pending migrations

When any migrations are pending, the metrics are disabled until the migrations
have been performed.

Read more on:

- [Introduction to GitLab Performance Monitoring](index.md)
- [Grafana Install/Configuration](grafana_configuration.md)
