---
stage: Systems
group: Cloud Connector
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab exporter
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

The [GitLab exporter](https://gitlab.com/gitlab-org/ruby/gems/gitlab-exporter) enables you to
measure various GitLab metrics pulled from Redis and the database in Linux package
instances.

For self-compiled installations, you must install and configure it yourself.

To enable the GitLab exporter in a Linux package instance:

1. [Enable Prometheus](_index.md#configuring-prometheus).
1. Edit `/etc/gitlab/gitlab.rb`.
1. Add, or find and uncomment, the following line, making sure it's set to `true`:

   ```ruby
   gitlab_exporter['enable'] = true
   ```

1. Save the file and [reconfigure GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect.

Prometheus automatically begins collecting performance data from
the GitLab exporter exposed at `localhost:9168`.

## Use a different Rack server

By default, the GitLab exporter runs on [WEBrick](https://github.com/ruby/webrick), a single-threaded Ruby web server.
You can choose a different Rack server that better matches your performance needs.
For instance, in multi-node setups that contain a large number of Prometheus scrapers
but only a few monitoring nodes, you may decide to run a multi-threaded server such as Puma instead.

To change the Rack server to Puma:

1. Edit `/etc/gitlab/gitlab.rb`.
1. Add, or find and uncomment, the following line, and set it to `puma`:

   ```ruby
   gitlab_exporter['server_name'] = 'puma'
   ```

1. Save the file and [reconfigure GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation)
   for the changes to take effect.

The supported Rack servers are `webrick` and `puma`.
