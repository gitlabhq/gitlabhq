---
type: reference
---

# Configuring Gitaly for Scaled and High Availability

Gitaly does not yet support full high availability. However, Gitaly is quite
stable and is in use on GitLab.com. Scaled and highly available GitLab environments
should consider using Gitaly on a separate node.

See the [Gitaly HA Epic](https://gitlab.com/groups/gitlab-org/-/epics/289) to
track plans and progress toward high availability support.

This document is relevant for [Scalable and Highly Available Setups](../scaling/index.md).

## Running Gitaly on its own server

See [Running Gitaly on its own server](../gitaly/index.md#running-gitaly-on-its-own-server)
in Gitaly documentation.

Continue configuration of other components by going back to the
[Scaling](../scaling/index.md#components-provided-by-omnibus-gitlab) page.

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

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
