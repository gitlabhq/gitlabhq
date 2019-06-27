# Configuring Gitaly for Scaled and High Availability

Gitaly does not yet support full high availability. However, Gitaly is quite
stable and is in use on GitLab.com. Scaled and highly available GitLab environments
should consider using Gitaly on a separate node.

See the [Gitaly HA Epic](https://gitlab.com/groups/gitlab-org/-/epics/289) to
track plans and progress toward high availability support.

This document is relevant for [Scaled Architecture](README.md#scalable-architecture-examples)
environments and [High Availability Architecture](README.md#high-availability-architecture-examples).

## Running Gitaly on its own server

See [Running Gitaly on its own server](../gitaly/index.md#running-gitaly-on-its-own-server)
in Gitaly documentation.

Continue configuration of other components by going back to:

- [Scaled Architectures](README.md#scalable-architecture-examples)
- [High Availability Architectures](README.md#high-availability-architecture-examples)

## Enable Monitoring

> [Introduced](https://gitlab.com/gitlab-org/omnibus-gitlab/issues/3786) in GitLab 12.0.

1. Make sure to collect [`CONSUL_SERVER_NODES`](database.md#consul-information), which are the IP addresses or DNS records of the Consul server nodes, for the next step. Note they are presented as `Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z`

1. Create/edit `/etc/gitlab/gitlab.rb` and add the following configuration:

   ```ruby
   # Enable service discovery for Prometheus
   consul['enable'] = true
   consul['monitoring_service_discovery'] =  true

   # Replace placeholders
   # Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z
   # with the addresses of the Consul server nodes
   consul['configuration'] = {
      retry_join: %w(Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z),
   }

   # Set the network addresses that the exporters will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   gitaly['prometheus_listen_addr'] = "0.0.0.0:9236"
   ```

1. Run `sudo gitlab-ctl reconfigure` to compile the configuration.
