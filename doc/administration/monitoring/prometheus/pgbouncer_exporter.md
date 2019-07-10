# PgBouncer exporter

>**Note:**
Available since [Omnibus GitLab 11.0][2493]. For installations from source
you'll have to install and configure it yourself.

The [PgBouncer exporter] allows you to measure various PgBouncer metrics.

To enable the PgBouncer exporter:

1. [Enable Prometheus](index.md#configuring-prometheus)
1. Edit `/etc/gitlab/gitlab.rb`
1. Add or find and uncomment the following line, making sure it's set to `true`:

   ```ruby
   pgbouncer_exporter['enable'] = true
   ```

1. Save the file and [reconfigure GitLab][reconfigure] for the changes to
   take effect.

Prometheus will now automatically begin collecting performance data from
the PgBouncer exporter exposed under `localhost:9188`.

The PgBouncer exporter will also be enabled by default if the [pgbouncer_role][postgres roles]
is enabled.

[← Back to the main Prometheus page](index.md)

[2493]: https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests/2493
[PgBouncer exporter]: https://github.com/stanhu/pgbouncer_exporter
[postgres roles]: https://docs.gitlab.com/omnibus/roles/#postgres-roles
[prometheus]: https://prometheus.io
[reconfigure]: ../../restart_gitlab.md#omnibus-gitlab-reconfigure
