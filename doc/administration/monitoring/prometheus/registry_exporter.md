---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Registry exporter **(FREE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/2884) in GitLab 11.9.

The Registry exporter allows you to measure various Registry metrics.
To enable it:

1. [Enable Prometheus](index.md#configuring-prometheus).
1. Edit `/etc/gitlab/gitlab.rb` and enable [debug mode](https://docs.docker.com/registry/#debug) for the Registry:

   ```ruby
   registry['debug_addr'] = "localhost:5001"  # localhost:5001/metrics
   ```

1. Save the file and [reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect.

Prometheus automatically begins collecting performance data from
the registry exporter exposed under `localhost:5001/metrics`.

[← Back to the main Prometheus page](index.md)
