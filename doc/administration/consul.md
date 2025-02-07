---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: How to set up Consul
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

A Consul cluster consists of both
[server and client agents](https://developer.hashicorp.com/consul/docs/agent).
The servers run on their own nodes and the clients run on other nodes that in
turn communicate with the servers.

GitLab Premium includes a bundled version of [Consul](https://www.consul.io/)
a service networking solution that you can manage by using `/etc/gitlab/gitlab.rb`.

## Prerequisites

Before configuring Consul:

1. Review the [reference architecture](reference_architectures/_index.md#available-reference-architectures)
   documentation to determine the number of Consul server nodes you should have.
1. If necessary, ensure the [appropriate ports are open](package_information/defaults.md#ports) in your firewall.

## Configure the Consul nodes

On _each_ Consul server node:

1. Follow the instructions to [install](https://about.gitlab.com/install/)
   GitLab by choosing your preferred platform, but do not supply the
   `EXTERNAL_URL` value when asked.
1. Edit `/etc/gitlab/gitlab.rb`, and add the following by replacing the values
   noted in the `retry_join` section. In the example below, there are three
   nodes, two denoted with their IP, and one with its FQDN, you can use either
   notation:

   ```ruby
   # Disable all components except Consul
   roles ['consul_role']

   # Consul nodes: can be FQDN or IP, separated by a whitespace
   consul['configuration'] = {
     server: true,
     retry_join: %w(10.10.10.1 consul1.gitlab.example.com 10.10.10.2)
   }

   # Disable auto migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. [Reconfigure GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes
   to take effect.
1. Run the following command to ensure Consul is both configured correctly and
   to verify that all server nodes are communicating:

   ```shell
   sudo /opt/gitlab/embedded/bin/consul members
   ```

   The output should be similar to:

   ```plaintext
   Node                 Address               Status  Type    Build  Protocol  DC
   CONSUL_NODE_ONE      XXX.XXX.XXX.YYY:8301  alive   server  0.9.2  2         gitlab_consul
   CONSUL_NODE_TWO      XXX.XXX.XXX.YYY:8301  alive   server  0.9.2  2         gitlab_consul
   CONSUL_NODE_THREE    XXX.XXX.XXX.YYY:8301  alive   server  0.9.2  2         gitlab_consul
   ```

   If the results display any nodes with a status that isn't `alive`, or if any
   of the three nodes are missing, see the [Troubleshooting section](#troubleshooting-consul).

## Securing the Consul nodes

There are two ways you can secure the communication between the Consul nodes, using either TLS or gossip encryption.

### TLS encryption

By default TLS is not enabled for the Consul cluster, the default configuration
options and their defaults are:

```ruby
consul['use_tls'] = false
consul['tls_ca_file'] = nil
consul['tls_certificate_file'] = nil
consul['tls_key_file'] = nil
consul['tls_verify_client'] = nil
```

These configuration options apply to both client and server nodes.

To enable TLS on a Consul node start with `consul['use_tls'] = true`. Depending
on the role of the node (server or client) and your TLS preferences you need to
provide further configuration:

- On a server node you must at least specify `tls_ca_file`,
  `tls_certificate_file`, and `tls_key_file`.
- On a client node, when client TLS authentication is disabled on the server
  (enabled by default) you must at least specify `tls_ca_file`, otherwise you have
  to pass the client TLS certificate and key using `tls_certificate_file`,
  `tls_key_file`.

When TLS is enabled, by default the server uses mTLS and listens on both HTTPS
and HTTP (and TLS and non-TLS RPC). It expects clients to use TLS
authentication. You can disable client TLS authentication by setting
`consul['tls_verify_client'] = false`.

On the other hand, clients only use TLS for outgoing connection to server nodes
and only listen on HTTP (and non-TLS RPC) for incoming requests. You can enforce
client Consul agents to use TLS for incoming connections by setting
`consul['https_port']` to a non-negative integer (`8501` is the Consul's default
HTTPS port). You must also pass `tls_certificate_file` and `tls_key_file` for
this to work. When server nodes use client TLS authentication, the client TLS
certificate and key is used for both TLS authentication and incoming HTTPS
connections.

Consul client nodes do not use TLS client authentication by default (as opposed
to servers) and you need to explicitly instruct them to do it by setting
`consul['tls_verify_client'] = true`.

Below are some examples of TLS encryption.

#### Minimal TLS support

In the following example, the server uses TLS for incoming connections (without client TLS authentication).

::Tabs

:::TabTitle Consul server node

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   consul['enable'] = true
   consul['configuration'] = {
     'server' => true
   }

   consul['use_tls'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   consul['tls_certificate_file'] = '/path/to/server.crt.pem'
   consul['tls_key_file'] = '/path/to/server.key.pem'
   consul['tls_verify_client'] = false
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Consul client node

The following can be configured on a Patroni node for example.

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   consul['enable'] = true
   consul['use_tls'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   patroni['consul']['url'] = 'http://localhost:8500'
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Patroni talks to the local Consul agent which does not use TLS for incoming
connections. Hence the HTTP URL for `patroni['consul']['url']`.

::EndTabs

#### Default TLS support

In the following example, the server uses mutual TLS authentication.

::Tabs

:::TabTitle Consul server node

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   consul['enable'] = true
   consul['configuration'] = {
     'server' => true
   }

   consul['use_tls'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   consul['tls_certificate_file'] = '/path/to/server.crt.pem'
   consul['tls_key_file'] = '/path/to/server.key.pem'
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Consul client node

The following can be configured on a Patroni node for example.

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   consul['enable'] = true
   consul['use_tls'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   consul['tls_certificate_file'] = '/path/to/client.crt.pem'
   consul['tls_key_file'] = '/path/to/client.key.pem'
   patroni['consul']['url'] = 'http://localhost:8500'
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Patroni talks to the local Consul agent which does not use TLS for incoming
connections, even though it uses TLS authentication to Consul server nodes.
Hence the HTTP URL for `patroni['consul']['url']`.

::EndTabs

#### Full TLS support

In the following example, both client and server use mutual TLS authentication.

The Consul server, client, and Patroni client certificates must be issued by the
same CA for mutual TLS authentication to work.

::Tabs

:::TabTitle Consul server node

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   consul['enable'] = true
   consul['configuration'] = {
     'server' => true
   }

   consul['use_tls'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   consul['tls_certificate_file'] = '/path/to/server.crt.pem'
   consul['tls_key_file'] = '/path/to/server.key.pem'
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Consul client node

The following can be configured on a Patroni node for example.

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   consul['enable'] = true
   consul['use_tls'] = true
   consul['tls_verify_client'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   consul['tls_certificate_file'] = '/path/to/client.crt.pem'
   consul['tls_key_file'] = '/path/to/client.key.pem'
   consul['https_port'] = 8501

   patroni['consul']['url'] = 'https://localhost:8501'
   patroni['consul']['cacert'] = '/path/to/ca.crt.pem'
   patroni['consul']['cert'] = '/opt/tls/patroni.crt.pem'
   patroni['consul']['key'] = '/opt/tls/patroni.key.pem'
   patroni['consul']['verify'] = true
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

::EndTabs

### Gossip encryption

The Gossip protocol can be encrypted to secure communication between Consul
agents. By default encryption is not enabled, to enable encryption a shared
encryption key is required. For convenience, the key can be generated by using
the `gitlab-ctl consul keygen` command. The key must be 32 bytes long, Base 64
encoded and shared on all agents.

The following options work on both client and server nodes.

To enable the gossip protocol:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   consul['encryption_key'] = <base-64-key>
   consul['encryption_verify_incoming'] = true
   consul['encryption_verify_outgoing'] = true
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

To [enable encryption in an existing datacenter](https://developer.hashicorp.com/consul/docs/security/encryption#enable-on-an-existing-consul-datacenter),
manually set these options for a rolling update.

## Upgrade the Consul nodes

To upgrade your Consul nodes, upgrade the GitLab package.

Nodes should be:

- Members of a healthy cluster prior to upgrading the Linux package.
- Upgraded one node at a time.

Identify any existing health issues in the cluster by running the following command
in each node. The command returns an empty array if the cluster is healthy:

```shell
curl "http://127.0.0.1:8500/v1/health/state/critical"
```

If the Consul version has changed, you see a notice at the end of `gitlab-ctl reconfigure`
informing you that Consul must be restarted for the new version to be used.

Restart Consul one node at a time:

```shell
sudo gitlab-ctl restart consul
```

Consul nodes communicate using the raft protocol. If the current leader goes
offline, there must be a leader election. A leader node must exist to facilitate
synchronization across the cluster. If too many nodes go offline at the same time,
the cluster loses quorum and doesn't elect a leader due to
[broken consensus](https://developer.hashicorp.com/consul/docs/architecture/consensus).

Consult the [troubleshooting section](#troubleshooting-consul) if the cluster is not
able to recover after the upgrade. The [outage recovery](#outage-recovery) may
be of particular interest.

GitLab uses Consul to store only easily regenerated, transient data. If the
bundled Consul wasn't used by any process other than GitLab itself, you can
[rebuild the cluster from scratch](#recreate-from-scratch).

## Troubleshooting Consul

Below are some operations should you debug any issues.
You can see any error logs by running:

```shell
sudo gitlab-ctl tail consul
```

### Check the cluster membership

To determine which nodes are part of the cluster, run the following on any member in the cluster:

```shell
sudo /opt/gitlab/embedded/bin/consul members
```

The output should be similar to:

```plaintext
Node            Address               Status  Type    Build  Protocol  DC
consul-b        XX.XX.X.Y:8301        alive   server  0.9.0  2         gitlab_consul
consul-c        XX.XX.X.Y:8301        alive   server  0.9.0  2         gitlab_consul
consul-c        XX.XX.X.Y:8301        alive   server  0.9.0  2         gitlab_consul
db-a            XX.XX.X.Y:8301        alive   client  0.9.0  2         gitlab_consul
db-b            XX.XX.X.Y:8301        alive   client  0.9.0  2         gitlab_consul
```

Ideally all nodes have a `Status` of `alive`.

### Restart Consul

If it is necessary to restart Consul, it is important to do this in
a controlled manner to maintain quorum. If quorum is lost, to recover the cluster,
you follow the Consul [outage recovery](#outage-recovery) process.

To be safe, it's recommended that you only restart Consul in one node at a time to
ensure the cluster remains intact. For larger clusters, it is possible to restart
multiple nodes at a time. See the
[Consul consensus document](https://developer.hashicorp.com/consul/docs/architecture/consensus#deployment-table)
for the number of failures it can tolerate. This is the number of simultaneous
restarts it can sustain.

To restart Consul:

```shell
sudo gitlab-ctl restart consul
```

### Consul nodes unable to communicate

By default, Consul attempts to
[bind](https://developer.hashicorp.com/consul/docs/agent/config/config-files#bind_addr) to `0.0.0.0`, but
it advertises the first private IP address on the node for other Consul nodes
to communicate with it. If the other nodes cannot communicate with a node on
this address, then the cluster has a failed status.

If you run into this issue, then messages like the following are output in `gitlab-ctl tail consul`:

```plaintext
2017-09-25_19:53:39.90821     2017/09/25 19:53:39 [WARN] raft: no known peers, aborting election
2017-09-25_19:53:41.74356     2017/09/25 19:53:41 [ERR] agent: failed to sync remote state: No cluster leader
```

To fix this:

1. Pick an address on each node that all of the other nodes can reach this node through.
1. Update your `/etc/gitlab/gitlab.rb`

   ```ruby
   consul['configuration'] = {
     ...
     bind_addr: 'IP ADDRESS'
   }
   ```

1. Reconfigure GitLab;

   ```shell
   gitlab-ctl reconfigure
   ```

If you still see the errors, you may have to
[erase the Consul database and reinitialize](#recreate-from-scratch) on the affected node.

### Consul does not start - multiple private IPs

If a node has multiple private IPs, Consul doesn't know about
which of the private addresses to advertise, and then it immediately exits on start.

Messages like the following are output in `gitlab-ctl tail consul`:

```plaintext
2017-11-09_17:41:45.52876 ==> Starting Consul agent...
2017-11-09_17:41:45.53057 ==> Error creating agent: Failed to get advertise address: Multiple private IPs found. Please configure one.
```

To fix this:

1. Pick an address on the node that all of the other nodes can reach this node through.
1. Update your `/etc/gitlab/gitlab.rb`

   ```ruby
   consul['configuration'] = {
     ...
     bind_addr: 'IP ADDRESS'
   }
   ```

1. Reconfigure GitLab;

   ```shell
   gitlab-ctl reconfigure
   ```

### Outage recovery

If you have lost enough Consul nodes in the cluster to break quorum, then the cluster
is considered to have failed and cannot function without manual intervention.
In that case, you can either recreate the nodes from scratch or attempt a
recover.

#### Recreate from scratch

By default, GitLab does not store anything in the Consul node that cannot be
recreated. To erase the Consul database and reinitialize:

```shell
sudo gitlab-ctl stop consul
sudo rm -rf /var/opt/gitlab/consul/data
sudo gitlab-ctl start consul
```

After this, the node should start back up, and the rest of the server agents rejoin.
Shortly after that, the client agents should rejoin as well.

If they do not join, you might also need to erase the Consul data on the client:

```shell
sudo rm -rf /var/opt/gitlab/consul/data
```

#### Recover a failed node

If you have taken advantage of Consul to store other data and want to restore
the failed node, follow the
[Consul guide](https://developer.hashicorp.com/consul/tutorials/operate-consul/recovery-outage)
to recover a failed cluster.
