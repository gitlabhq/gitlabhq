# GitLab exporter

>**Note:**
Available since [Omnibus GitLab 8.17][1132]. For installations from source
you'll have to install and configure it yourself.

The [GitLab exporter] allows you to measure various GitLab metrics, pulled from Redis and the database.

To enable the GitLab exporter:

1. [Enable Prometheus](index.md#configuring-prometheus)
1. Edit `/etc/gitlab/gitlab.rb`
1. Add or find and uncomment the following line, making sure it's set to `true`:

   ```ruby
   gitlab_exporter['enable'] = true
   ```

1. Save the file and [reconfigure GitLab][reconfigure] for the changes to
   take effect

Prometheus will now automatically begin collecting performance data from
the GitLab exporter exposed under `localhost:9168`.

[← Back to the main Prometheus page](index.md)

[1132]: https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests/1132
[GitLab exporter]: https://gitlab.com/gitlab-org/gitlab-exporter
[prometheus]: https://prometheus.io
[reconfigure]: ../../restart_gitlab.md#omnibus-gitlab-reconfigure
