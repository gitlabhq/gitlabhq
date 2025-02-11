---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Install the GitLab agent server for Kubernetes (KAS)
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

The agent server is a component installed together with GitLab. It is required to
manage the [GitLab agent for Kubernetes](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent).

The KAS acronym refers to the former name, `Kubernetes agent server`.

The agent server for Kubernetes is installed and available on GitLab.com at `wss://kas.gitlab.com`.
If you use GitLab Self-Managed, by default the agent server is installed and available.

## Installation options

As a GitLab administrator, you can control the agent server installation:

- For [Linux package installations](#for-linux-package-installations).
- For [GitLab Helm chart installations](#for-gitlab-helm-chart).

### For Linux package installations

The agent server for Linux package installations can be enabled on a single node, or on multiple nodes at once.
By default, the agent server is enabled and available at `ws://gitlab.example.com/-/kubernetes-agent/`.

#### Disable on a single node

To disable the agent server on a single node:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_kas['enable'] = false
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

#### Turn on KAS on multiple nodes

KAS instances communicate with each other by registering their private addresses in Redis at a well-known location. Each KAS must be configured with its specific location details so that other instances can reach it.

To turn on KAS on multiple nodes:

1. Add the [common configuration](#common-configuration).
1. Add the configuration from one of the following options:

   - [Option 1 - explicit manual configuration](#option-1---explicit-manual-configuration)
   - [Option 2 - automatic CIDR-based configuration](#option-2---automatic-cidr-based-configuration)
   - [Option 3 - automatic configuration based on listener configuration](#option-3---automatic-configuration-based-on-listener-configuration)

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. (Optional) If you use a multi-server environment with separate GitLab Rails and Sidekiq nodes, enable KAS on the Sidekiq nodes.

##### Common configuration

For each KAS node, edit the file at `/etc/gitlab/gitlab.rb` and add the following configuration:

```ruby
gitlab_kas_external_url 'wss://kas.gitlab.example.com/'

gitlab_kas['api_secret_key'] = '<32_bytes_long_base64_encoded_value>'
gitlab_kas['private_api_secret_key'] = '<32_bytes_long_base64_encoded_value>'

# private_api_listen_address examples, pick one:

gitlab_kas['private_api_listen_address'] = 'A.B.C.D:8155' # Listen on a particular IPv4. Each node must use its own unique IP.
# gitlab_kas['private_api_listen_address'] = '[A:B:C::D]:8155' # Listen on a particular IPv6. Each node must use its own unique IP.
# gitlab_kas['private_api_listen_address'] = 'kas-N.gitlab.example.com:8155' # Listen on all IPv4 and IPv6 interfaces that the DNS name resolves to. Each node must use its own unique domain.
# gitlab_kas['private_api_listen_address'] = ':8155' # Listen on all IPv4 and IPv6 interfaces.
# gitlab_kas['private_api_listen_address'] = '0.0.0.0:8155' # Listen on all IPv4 interfaces.
# gitlab_kas['private_api_listen_address'] = '[::]:8155' # Listen on all IPv6 interfaces.

gitlab_kas['env'] = {
  # 'OWN_PRIVATE_API_HOST' => '<server-name-from-cert>' # Add if you want to use TLS for KAS->KAS communication. This name is used to verify the TLS certificate host name instead of the host in the URL of the destination KAS.
  'SSL_CERT_DIR' => "/opt/gitlab/embedded/ssl/certs/",
}

gitlab_rails['gitlab_kas_external_url'] = 'wss://gitlab.example.com/-/kubernetes-agent/'
gitlab_rails['gitlab_kas_internal_url'] = 'grpc://kas.internal.gitlab.example.com'
gitlab_rails['gitlab_kas_external_k8s_proxy_url'] = 'https://gitlab.example.com/-/kubernetes-agent/k8s-proxy/'
```

**Do not** set `private_api_listen_address` to listen on an internal address, such as:

- `localhost`
- Loopback IP addresses, like `127.0.0.1` or `::1`
- A UNIX socket

Other KAS nodes cannot reach these addresses.

For single-node configurations, you can set `private_api_listen_address` to listen on an internal address.

##### Option 1 - explicit manual configuration

For each KAS node, edit the file at `/etc/gitlab/gitlab.rb` and set the `OWN_PRIVATE_API_URL` environment variable explicitly:

```ruby
gitlab_kas['env'] = {
  # OWN_PRIVATE_API_URL examples, pick one. Each node must use its own unique IP or DNS name.
  # Use grpcs:// when using TLS on the private API endpoint.

  'OWN_PRIVATE_API_URL' => 'grpc://A.B.C.D:8155' # IPv4
  # 'OWN_PRIVATE_API_URL' => 'grpcs://A.B.C.D:8155' # IPv4 + TLS
  # 'OWN_PRIVATE_API_URL' => 'grpc://[A:B:C::D]:8155' # IPv6
  # 'OWN_PRIVATE_API_URL' => 'grpc://kas-N-private-api.gitlab.example.com:8155' # DNS name
}
```

##### Option 2 - automatic CIDR-based configuration

> - [Introduced](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/464) in GitLab 16.5.0.
> - [Added](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/merge_requests/2183) multiple CIDR support to `OWN_PRIVATE_API_CIDR` in GitLab 17.8.1.

You might not be able to set an exact IP address or hostname in the `OWN_PRIVATE_API_URL` variable if, for example,
the KAS host is assigned an IP address and a hostname dynamically.

If you cannot set an exact IP address or hostname, you can configure `OWN_PRIVATE_API_CIDR` to set up KAS to dynamically construct
`OWN_PRIVATE_API_URL` based on one or more [CIDRs](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing):

This approach allows each KAS node to use a static configuration that works as long as
the CIDR doesn't change.

For each KAS node, edit the file at `/etc/gitlab/gitlab.rb` to dynamically construct the
`OWN_PRIVATE_API_URL` URL:

1. Comment out `OWN_PRIVATE_API_URL` in your common configuration to turn off this variable.
1. Configure `OWN_PRIVATE_API_CIDR` to specify what networks the KAS nodes listen on.
   When you start KAS, it determines which private IP address to use by selecting the host address that matches the specified CIDR.
1. Configure `OWN_PRIVATE_API_PORT` to use a different port. By default, KAS uses the port from the `private_api_listen_address` parameter.
1. If you use TLS on the private API endpoint, configure `OWN_PRIVATE_API_SCHEME=grpcs`. By default, KAS uses the `grpc` scheme.

```ruby
gitlab_kas['env'] = {
  # 'OWN_PRIVATE_API_CIDR' => '10.0.0.0/8', # IPv4 example
  # 'OWN_PRIVATE_API_CIDR' => '2001:db8:8a2e:370::7334/64', # IPv6 example
  # 'OWN_PRIVATE_API_CIDR' => '10.0.0.0/8,2001:db8:8a2e:370::7334/64', # multiple CIRDs example

  # 'OWN_PRIVATE_API_PORT' => '8155',
  # 'OWN_PRIVATE_API_SCHEME' => 'grpc',
}
```

##### Option 3 - automatic configuration based on listener configuration

> - [Introduced](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/464) in GitLab 16.5.0.
> - [Updated](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/510) KAS to listen on and publish all non-loopback IP addresses and filter out IPv4 and IPv6 addresses based on the value of `private_api_listen_network`.

A KAS node can determine what IP addresses are available based on the `private_api_listen_network` and
`private_api_listen_address` settings:

- If `private_api_listen_address` is set to a fixed IP address and port number (for example, `ip:port`), it uses this IP address.
- If `private_api_listen_address` has no IP address (for example, `:8155`), or has an unspecified IP address
  (for example, `[::]:8155` or `0.0.0.0:8155`), KAS assigns all non-loopback and non-link-local IP addresses to the node.
  IPv4 and IPv6 addresses are filtered based on the value of `private_api_listen_network`.
- If `private_api_listen_address` is a `hostname:PORT` (for example, `kas-N-private-api.gitlab.example.com:8155`), KAS
  resolves the DNS name and assigns all IP addresses to the node.
  In this mode, KAS listens only on the first IP address (This behavior is defined by the [Go standard library](https://pkg.go.dev/net#Listen)).
  IPv4 and IPv6 addresses are filtered based on the value of `private_api_listen_network`.

Before exposing the private API address of a KAS on all IP addresses, make sure this action does not conflict with your organization's security policy.
The private API endpoint requires a valid authentication token for all requests.

For each KAS node, edit the file at `/etc/gitlab/gitlab.rb`:

Example 1. Listen on all IPv4 and IPv6 interfaces:

```ruby
# gitlab_kas['private_api_listen_network'] = 'tcp' # this is the default value, no need to set it.
gitlab_kas['private_api_listen_address'] = ':8155' # Listen on all IPv4 and IPv6 interfaces
```

Example 2. Listen on all IPv4 interfaces:

```ruby
gitlab_kas['private_api_listen_network'] = 'tcp4'
gitlab_kas['private_api_listen_address'] = ':8155'
```

Example 3. Listen on all IPv6 interfaces:

```ruby
gitlab_kas['private_api_listen_network'] = 'tcp6'
gitlab_kas['private_api_listen_address'] = ':8155'
```

You can use environment variables to override the scheme and port that
construct the `OWN_PRIVATE_API_URL`:

```ruby
gitlab_kas['env'] = {
  # 'OWN_PRIVATE_API_PORT' => '8155',
  # 'OWN_PRIVATE_API_SCHEME' => 'grpc',
}
```

##### Agent server node settings

| Setting | Description                                                                                                                                                                                      |
|---------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `gitlab_kas['private_api_listen_network']` | The network family KAS listens on. Defaults to `tcp` for both IPv4 and IPv6 networks. Set to `tcp4` for IPv4 or `tcp6` for IPv6.                                                   |
| `gitlab_kas['private_api_listen_address']` | The address the KAS listens on. Set to `0.0.0.0:8155` or to an IP:PORT reachable by other nodes in the cluster.                                                                         |
| `gitlab_kas['api_secret_key']` | The shared secret used for authentication between KAS and GitLab. The value must be Base64-encoded and exactly 32 bytes long.                                                           |
| `gitlab_kas['private_api_secret_key']` | The shared secret used for authentication between different KAS instances. The value must be Base64-encoded and exactly 32 bytes long.                                                  |
| `OWN_PRIVATE_API_SCHEME` | Optional value used to specify what scheme to use when constructing `OWN_PRIVATE_API_URL`. Can be `grpc` or `grpcs`.                                                                             |
| `OWN_PRIVATE_API_URL` | The environment variable used by KAS for service discovery. Set to the hostname or IP address of the node you're configuring. The node must be reachable by other nodes in the cluster. |
| `OWN_PRIVATE_API_HOST` | Optional value used to verify the TLS certificate hostname. <sup>1</sup> A client compares this value to the hostname in the server's TLS certificate file.                                    |
| `OWN_PRIVATE_API_PORT` | Optional value used to specify what port to use when constructing `OWN_PRIVATE_API_URL`.                                                                                                         |
| `OWN_PRIVATE_API_CIDR` | Optional value used to specify which IP addresses from the available networks to use when constructing `OWN_PRIVATE_API_URL`.                                                                                       |
| `gitlab_kas['client_timeout_seconds']` | The timeout for the client to connect to the KAS.                                                                                                                                       |
| `gitlab_kas_external_url` | The user-facing URL for the in-cluster `agentk`. Can be a fully qualified domain or subdomain, <sup>2</sup> or a GitLab external URL. <sup>3</sup> If blank, defaults to a GitLab external URL.  |
| `gitlab_rails['gitlab_kas_external_url']` | The user-facing URL for the in-cluster `agentk`. If blank, defaults to the `gitlab_kas_external_url`.                                                                                            |
| `gitlab_rails['gitlab_kas_external_k8s_proxy_url']` | The user-facing URL for Kubernetes API proxying. If blank, defaults to a URL based on `gitlab_kas_external_url`.                                                                                 |
| `gitlab_rails['gitlab_kas_internal_url']` | The internal URL the GitLab backend uses to communicate with KAS.                                                                                                                       |

**Footnotes:**

1. TLS for outbound connections is enabled when `OWN_PRIVATE_API_URL` or `OWN_PRIVATE_API_SCHEME` starts with `grpcs`.
1. For example, `wss://kas.gitlab.example.com/`.
1. For example, `wss://gitlab.example.com/-/kubernetes-agent/`.

### For GitLab Helm Chart

See [how to use the GitLab-KAS chart](https://docs.gitlab.com/charts/charts/gitlab/kas/).

## Kubernetes API proxy cookie

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/104504) in GitLab 15.10 [with feature flags](../feature_flags.md) named `kas_user_access` and `kas_user_access_project`. Disabled by default.
> - Feature flags `kas_user_access` and `kas_user_access_project` [enabled](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123479) in GitLab 16.1.
> - Feature flags `kas_user_access` and `kas_user_access_project` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125835) in GitLab 16.2.

KAS proxies Kubernetes API requests to the GitLab agent with either:

- A [CI/CD job](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/kubernetes_ci_access.md).
- [GitLab user credentials](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/kubernetes_user_access.md).

To authenticate with user credentials, Rails sets a cookie for the GitLab frontend.
This cookie is called `_gitlab_kas` and it contains an encrypted
session ID, like the [`_gitlab_session` cookie](../../user/profile/_index.md#cookies-used-for-sign-in).
The `_gitlab_kas` cookie must be sent to the KAS proxy endpoint with every request
to authenticate and authorize the user.

## Enable receptive agents

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12180) in GitLab 17.4.

[Receptive agents](../../user/clusters/agent/_index.md#receptive-agents) allow GitLab to integrate with Kubernetes clusters
that cannot establish a network connection to the GitLab instance, but can be connected to by GitLab.

To enable receptive agents:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **GitLab Agent for Kubernetes**.
1. Turn on the **Enable receptive mode** toggle.

## Troubleshooting

If you have issues while using the agent server for Kubernetes, view the
service logs by running the following command:

```shell
kubectl logs -f -l=app=kas -n <YOUR-GITLAB-NAMESPACE>
```

In Linux package installations, find the logs in `/var/log/gitlab/gitlab-kas/`.

You can also [troubleshoot issues with individual agents](../../user/clusters/agent/troubleshooting.md).

### Configuration file not found

If you get the following error message:

```plaintext
time="2020-10-29T04:44:14Z" level=warning msg="Config: failed to fetch" agent_id=2 error="configuration file not found: \".gitlab/agents/test-agent/config.yaml\
```

The path is incorrect for either:

- The repository where the agent was registered.
- The agent configuration file.

To fix this issue, ensure that the paths are correct.

### `dial tcp <GITLAB_INTERNAL_IP>:443: connect: connection refused`

If you are running GitLab Self-Managed and:

- The instance isn't running behind an SSL-terminating proxy.
- The instance doesn't have HTTPS configured on the GitLab instance itself.
- The instance's hostname resolves locally to its internal IP address.

When the agent server tries to connect to the GitLab API, the following error might occur:

```json
{"level":"error","time":"2021-08-16T14:56:47.289Z","msg":"GetAgentInfo()","correlation_id":"01FD7QE35RXXXX8R47WZFBAXTN","grpc_service":"gitlab.agent.reverse_tunnel.rpc.ReverseTunnel","grpc_method":"Connect","error":"Get \"https://gitlab.example.com/api/v4/internal/kubernetes/agent_info\": dial tcp 172.17.0.4:443: connect: connection refused"}
```

To fix this issue for Linux package installations,
set the following parameter in `/etc/gitlab/gitlab.rb`. Replace `gitlab.example.com` with your GitLab instance's hostname:

```ruby
gitlab_kas['gitlab_address'] = 'http://gitlab.example.com'
```

### Error: `x509: certificate signed by unknown authority`

If you encounter this error when trying to reach the GitLab URL, it means it doesn't trust the GitLab certificate.

You might see a similar error in the KAS logs of your GitLab application server:

```json
{"level":"error","time":"2023-03-07T20:19:48.151Z","msg":"AgentInfo()","grpc_service":"gitlab.agent.agent_configuration.rpc.AgentConfiguration","grpc_method":"GetConfiguration","error":"Get \"https://gitlab.example.com/api/v4/internal/kubernetes/agent_info\": x509: certificate signed by unknown authority"}
```

To fix this error, install the public certificate of your internal CA in the `/etc/gitlab/trusted-certs` directory.

Alternatively, you can configure KAS to read the certificate from a custom directory. To do this, add the following configuration to the file at `/etc/gitlab/gitlab.rb`:

```ruby
gitlab_kas['env'] = {
   'SSL_CERT_DIR' => "/opt/gitlab/embedded/ssl/certs/"
 }
```

To apply the changes:

1. Reconfigure GitLab:

```shell
sudo gitlab-ctl reconfigure
```

1. Restart agent server:

```shell
gitlab-ctl restart gitlab-kas
```

### GRPC::DeadlineExceeded in Clusters::Agents::NotifyGitPushWorker

This error likely occurs when the client does not receive a response within the default timeout period (5 seconds). To resolve the issue, you can increase the client timeout by modifying the `/etc/gitlab/gitlab.rb` configuration file.

#### Steps to Resolve

1. Add or update the following configuration to increase the timeout value:

```ruby
gitlab_kas['client_timeout_seconds'] = "10"
```

1. Apply the changes by reconfiguring GitLab:

```shell
gitlab-ctl reconfigure
```

#### Note

You can adjust the timeout value to suit your specific needs. Testing is recommended to ensure the issue is resolved without impacting system performance.
