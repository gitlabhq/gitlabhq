---
stage: Shared responsibility based on functional area
group: Shared responsibility based on functional area
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Node exporter
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

The [node exporter](https://github.com/prometheus/node_exporter) enables you to measure
various machine resources such as memory, disk and CPU utilization.

For self-compiled installations, you must install and configure it yourself.

To enable the node exporter:

1. [Enable Prometheus](_index.md#configuring-prometheus).
1. Edit `/etc/gitlab/gitlab.rb`.
1. Add (or find and uncomment) the following line, making sure it's set to `true`:

   ```ruby
   node_exporter['enable'] = true
   ```

1. Save the file, and [reconfigure GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect.

Prometheus begins collecting performance data from the node exporter
exposed at `localhost:9100`.
