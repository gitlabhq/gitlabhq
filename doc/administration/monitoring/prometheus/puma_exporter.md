---
stage: Monitor
group: Respond
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Puma exporter **(FREE SELF)**

You can use the [Puma exporter](https://github.com/sapcc/puma-exporter)
to measure various Puma metrics.

To enable the Puma exporter:

1. [Enable Prometheus](index.md#configuring-prometheus).
1. Edit `/etc/gitlab/gitlab.rb` to add (or find and uncomment) the following lines. Make sure
   `puma['exporter_enabled']` is set to `true`:

   ```ruby
   puma['exporter_enabled'] = true
   puma['exporter_address'] = "127.0.0.1"
   puma['exporter_port'] = 8083
   ```

1. Save the file and [reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect.

Prometheus begins collecting performance data from the Puma exporter exposed at `localhost:8083`.

For more information on using Puma with GitLab, see [Puma](../../operations/puma.md).
