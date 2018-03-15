# Alertmanager

>**Note:**
Available since [Omnibus GitLab 10.6][2205]. For installations from source
you'll have to install and configure it yourself.

The Prometheus [Alertmanager][alertmanager] allows you to route Prometheus alerts to users.

To enable the Alertmanager:

1. [Enable Prometheus](index.md#configuring-prometheus)
1. Edit `/etc/gitlab/gitlab.rb`
1. Add or find and uncomment the following lines:

    ```ruby
    alertmanager['enable'] = true
    alertmanager['admin_email'] = 'admin@example.com'
    ```
1. Configure [SMTP][smtp] for sending email.
1. Save the file and [reconfigure GitLab][reconfigure] for the changes to
   take effect


[← Back to the main Prometheus page](index.md)

[2205]: https://gitlab.com/gitlab-org/omnibus-gitlab/merge_requests/2205
[alertmanager]: https://github.com/prometheus/alertmanager
[reconfigure]: ../../restart_gitlab.md#omnibus-gitlab-reconfigure
[smtp]: https://docs.gitlab.com/omnibus/settings/smtp.html
