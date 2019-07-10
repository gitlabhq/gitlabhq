# Postgres exporter

>**Note:**
Available since [Omnibus GitLab 8.17][1131]. For installations from source
you'll have to install and configure it yourself.

The [postgres exporter] allows you to measure various PostgreSQL metrics.

To enable the postgres exporter:

1. [Enable Prometheus](index.md#configuring-prometheus)
1. Edit `/etc/gitlab/gitlab.rb`
1. Add or find and uncomment the following line, making sure it's set to `true`:

   ```ruby
   postgres_exporter['enable'] = true
   ```

1. Save the file and [reconfigure GitLab][reconfigure] for the changes to
   take effect

Prometheus will now automatically begin collecting performance data from
the postgres exporter exposed under `localhost:9187`.

[← Back to the main Prometheus page](index.md)

[1131]: https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests/1131
[postgres exporter]: https://github.com/wrouesnel/postgres_exporter
[prometheus]: https://prometheus.io
[reconfigure]: ../../restart_gitlab.md#omnibus-gitlab-reconfigure
