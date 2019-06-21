# Configuring a Monitoring node for Scaling and High Availability

> [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/3786) in GitLab 12.0.

## Standalone Monitoring node using GitLab Omnibus

The GitLab Omnibus package can be used to configure a standalone Monitoring node running Prometheus and Grafana.
The monitoring node is not highly available. See [Scaling and High Availability](README.md)
for an overview of GitLab scaling and high availability options.

The steps below are the minimum necessary to configure a Monitoring node running Prometheus and Grafana with
Omnibus:

1. SSH into the Monitoring node.
1. [Download/install](https://about.gitlab.com/installation) the Omnibus GitLab
   package you want using **steps 1 and 2** from the GitLab downloads page.
   - Do not complete any other steps on the download page.

1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

    ```ruby
    external_url 'http://gitlab.example.com'

    # Enable Prometheus
    prometheus['enable'] = true
    prometheus['listen_address'] = '0.0.0.0:9090'
    prometheus['monitor_kubernetes'] = false

    # Enable Grafana
    grafana['enable'] = true
    grafana['admin_password'] = 'toomanysecrets'

    # Enable service discovery for Prometheus
    consul['enable'] = true
    consul['monitoring_service_discovery'] =  true

    # Replace placeholders
    # Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z
    # with the addresses of the Consul server nodes
    consul['configuration'] = {
       retry_join: %w(Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z),
    }

    # Disable all other services
    gitlab_rails['auto_migrate'] = false
    alertmanager['enable'] = false
    gitaly['enable'] = false
    gitlab_monitor['enable'] = false
    gitlab_workhorse['enable'] = false
    nginx['enable'] = true
    postgres_exporter['enable'] = false
    postgresql['enable'] = false
    redis['enable'] = false
    redis_exporter['enable'] = false
    sidekiq['enable'] = false
    unicorn['enable'] = false
    node_exporter['enable'] = false
    ```

1. Run `sudo gitlab-ctl reconfigure` to compile the configuration.

## Migrating to Service Discovery

Once monitoring using Service Discovery is enabled with `consul['monitoring_service_discovery'] =  true`,
ensure that `prometheus['scrape_configs']` is not set  in `/etc/gitlab/gitlab.rb`. Setting both
`consul['monitoring_service_discovery'] =  true` and `prometheus['scrape_configs']` in `/etc/gitlab/gitlab.rb`
will result in errors.
