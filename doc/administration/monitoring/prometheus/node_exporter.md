---
stage: Monitor
group: APM
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Node exporter

The [node exporter](https://github.com/prometheus/node_exporter) enables you to measure
various machine resources such as memory, disk and CPU utilization.

NOTE: **Note:**
For installations from source you'll have to install and configure it yourself.

To enable the node exporter:

1. [Enable Prometheus](index.md#configuring-prometheus).
1. Edit `/etc/gitlab/gitlab.rb`.
1. Add (or find and uncomment) the following line, making sure it's set to `true`:

   ```ruby
   node_exporter['enable'] = true
   ```

1. Save the file, and [reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect.

Prometheus will now begin collecting performance data from the node exporter
exposed at `localhost:9100`.
