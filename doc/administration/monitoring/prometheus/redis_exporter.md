---
stage: Shared responsibility based on functional area
group: Shared responsibility based on functional area
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Redis exporter
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

The [Redis exporter](https://github.com/oliver006/redis_exporter) enables you to measure
various [Redis](https://redis.io) metrics. For more information on what is exported,
[read the upstream documentation](https://github.com/oliver006/redis_exporter/blob/master/README.md#whats-exported).

For self-compiled installations, you must install and configure it yourself.

To enable the Redis exporter:

1. [Enable Prometheus](_index.md#configuring-prometheus).
1. Edit `/etc/gitlab/gitlab.rb`.
1. Add (or find and uncomment) the following line, making sure it's set to `true`:

   ```ruby
   redis_exporter['enable'] = true
   ```

1. Save the file and [reconfigure GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect.

Prometheus begins collecting performance data from
the Redis exporter exposed at `localhost:9121`.
