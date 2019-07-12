# Redis exporter

>**Note:**
Available since [Omnibus GitLab 8.17][1118]. For installations from source
you'll have to install and configure it yourself.

The [Redis exporter] allows you to measure various [Redis] metrics. For more
information on what's exported [read the upstream documentation][redis-exp].

To enable the Redis exporter:

1. [Enable Prometheus](index.md#configuring-prometheus)
1. Edit `/etc/gitlab/gitlab.rb`
1. Add or find and uncomment the following line, making sure it's set to `true`:

   ```ruby
   redis_exporter['enable'] = true
   ```

1. Save the file and [reconfigure GitLab][reconfigure] for the changes to
   take effect

Prometheus will now automatically begin collecting performance data from
the Redis exporter exposed under `localhost:9121`.

[← Back to the main Prometheus page](index.md)

[1118]: https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests/1118
[redis]: https://redis.io
[redis exporter]: https://github.com/oliver006/redis_exporter
[redis-exp]: https://github.com/oliver006/redis_exporter/blob/master/README.md#whats-exported
[prometheus]: https://prometheus.io
[reconfigure]: ../../restart_gitlab.md#omnibus-gitlab-reconfigure
