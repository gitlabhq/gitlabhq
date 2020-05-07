---
stage: Monitor
group: APM
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# PgBouncer exporter

>**Note:**
Available since [Omnibus GitLab 11.0](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/2493).
For installations from source you'll have to install and configure it yourself.

The [PgBouncer exporter](https://github.com/stanhu/pgbouncer_exporter) allows you to measure various PgBouncer metrics.

To enable the PgBouncer exporter:

1. [Enable Prometheus](index.md#configuring-prometheus)
1. Edit `/etc/gitlab/gitlab.rb`
1. Add or find and uncomment the following line, making sure it's set to `true`:

   ```ruby
   pgbouncer_exporter['enable'] = true
   ```

1. Save the file and [reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to
   take effect.

Prometheus will now automatically begin collecting performance data from
the PgBouncer exporter exposed under `localhost:9188`.

The PgBouncer exporter will also be enabled by default if the [`pgbouncer_role`](https://docs.gitlab.com/omnibus/roles/#postgres-roles)
role is enabled.

[← Back to the main Prometheus page](index.md)
