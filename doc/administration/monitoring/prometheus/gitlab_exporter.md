---
stage: Monitor
group: APM
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# GitLab exporter

>- Available since [Omnibus GitLab 8.17](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/1132).
>- Renamed from `GitLab monitor exporter` to `GitLab exporter` in [GitLab 12.3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/16511).

The [GitLab exporter](https://gitlab.com/gitlab-org/gitlab-exporter) allows you to
measure various GitLab metrics, pulled from Redis and the database, in Omnibus GitLab
instances.

NOTE: **Note:**
For installations from source you'll have to install and configure it yourself.

To enable the GitLab exporter in an Omnibus GitLab instance:

1. [Enable Prometheus](index.md#configuring-prometheus)
1. Edit `/etc/gitlab/gitlab.rb`
1. Add or find and uncomment the following line, making sure it's set to `true`:

   ```ruby
   gitlab_exporter['enable'] = true
   ```

1. Save the file and [reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect

Prometheus will now automatically begin collecting performance data from
the GitLab exporter exposed under `localhost:9168`.

[← Back to the main Prometheus page](index.md)
