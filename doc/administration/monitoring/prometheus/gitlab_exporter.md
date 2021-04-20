---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab exporter **(FREE SELF)**

>- Available since [Omnibus GitLab 8.17](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/1132).
>- Renamed from `GitLab monitor exporter` to `GitLab exporter` in [GitLab 12.3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/16511).

The [GitLab exporter](https://gitlab.com/gitlab-org/gitlab-exporter) enables you to
measure various GitLab metrics pulled from Redis and the database in Omnibus GitLab
instances.

For installations from source you must install and configure it yourself.

To enable the GitLab exporter in an Omnibus GitLab instance:

1. [Enable Prometheus](index.md#configuring-prometheus).
1. Edit `/etc/gitlab/gitlab.rb`.
1. Add, or find and uncomment, the following line, making sure it's set to `true`:

   ```ruby
   gitlab_exporter['enable'] = true
   ```

1. Save the file and [reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect.

Prometheus automatically begins collecting performance data from
the GitLab exporter exposed at `localhost:9168`.

## Use a different Rack server

>- Introduced in [Omnibus GitLab 13.8](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/4896).
>- WEBrick is now the default Rack server instead of Puma.

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

1. Save the file and [reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect.

The supported Rack servers are `webrick` and `puma`.
