---
type: reference
---

# Configuring a Monitoring node for Scaling and High Availability

> [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3786) in GitLab 12.0.

You can configure a Prometheus node to monitor GitLab.

## Standalone Monitoring node using Omnibus GitLab

The Omnibus GitLab package can be used to configure a standalone Monitoring node running [Prometheus](../monitoring/prometheus/index.md) and [Grafana](../monitoring/performance/grafana_configuration.md).
The monitoring node is not highly available. See [Scaling and High Availability](../reference_architectures/index.md)
for an overview of GitLab scaling and high availability options.

The steps below are the minimum necessary to configure a Monitoring node running Prometheus and Grafana with
Omnibus:

1. SSH into the Monitoring node.
1. [Download/install](https://about.gitlab.com/install/) the Omnibus GitLab
   package you want using **steps 1 and 2** from the GitLab downloads page.
   - Do not complete any other steps on the download page.

1. Make sure to collect [`CONSUL_SERVER_NODES`](database.md#consul-information), which are the IP addresses or DNS records of the Consul server nodes, for the next step. Note they are presented as `Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z`

1. Edit `/etc/gitlab/gitlab.rb` and add the contents:

   ```ruby
   external_url 'http://gitlab.example.com'

   # Enable Prometheus
   prometheus['enable'] = true
   prometheus['listen_address'] = '0.0.0.0:9090'
   prometheus['monitor_kubernetes'] = false

   # Enable Login form
   grafana['disable_login_form'] = false

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
   gitlab_exporter['enable'] = false
   gitlab_workhorse['enable'] = false
   nginx['enable'] = true
   postgres_exporter['enable'] = false
   postgresql['enable'] = false
   redis['enable'] = false
   redis_exporter['enable'] = false
   sidekiq['enable'] = false
   puma['enable'] = false
   node_exporter['enable'] = false
   gitlab_exporter['enable'] = false
   ```

1. Run `sudo gitlab-ctl reconfigure` to compile the configuration.

## Migrating to Service Discovery

Once monitoring using Service Discovery is enabled with `consul['monitoring_service_discovery'] =  true`,
ensure that `prometheus['scrape_configs']` is not set in `/etc/gitlab/gitlab.rb`. Setting both
`consul['monitoring_service_discovery'] = true` and `prometheus['scrape_configs']` in `/etc/gitlab/gitlab.rb`
will result in errors.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
