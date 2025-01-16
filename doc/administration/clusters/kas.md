---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Install the GitLab agent server for Kubernetes (KAS)

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

##### Configure KAS to listen on a UNIX socket

If you use GitLab behind a proxy, KAS might not work correctly. You can resolve this issue on a single-node installation, you can configure KAS to listen on a UNIX socket.

To configure KAS to listen on a UNIX socket:

1. Create a directory for the KAS sockets:

   ```shell
   sudo mkdir -p /var/opt/gitlab/gitlab-kas/sockets/
   ```

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_kas['internal_api_listen_network'] = 'unix'
   gitlab_kas['internal_api_listen_address'] = '/var/opt/gitlab/gitlab-kas/sockets/internal-api.socket'
   gitlab_kas['private_api_listen_network'] = 'unix'
   gitlab_kas['private_api_listen_address'] = '/var/opt/gitlab/gitlab-kas/sockets/private-api.socket'
   gitlab_kas['client_timeout_seconds'] = '5'
   gitlab_kas['env'] = {
     'SSL_CERT_DIR' => "/opt/gitlab/embedded/ssl/certs/",
     'OWN_PRIVATE_API_URL' => 'unix:///var/opt/gitlab/gitlab-kas/sockets/private-api.socket'
   }
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

For additional configuration options, see the **GitLab Kubernetes agent server** section of
[`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template).

#### Enable on multiple nodes

To enable the agent server on multiple nodes:

1. For each agent server node, edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_kas_external_url 'wss://kas.gitlab.example.com/'

   gitlab_kas['api_secret_key'] = '<32_bytes_long_base64_encoded_value>'
   gitlab_kas['private_api_secret_key'] = '<32_bytes_long_base64_encoded_value>'
   gitlab_kas['private_api_listen_address'] = '0.0.0.0:8155'
   gitlab_kas['client_timeout_seconds'] = '5'
   gitlab_kas['env'] = {
     'SSL_CERT_DIR' => "/opt/gitlab/embedded/ssl/certs/",
     'OWN_PRIVATE_API_URL' => 'grpc://<ip_or_hostname_of_this_host>:8155' # use grpcs:// when using TLS on the private API endpoint

     # 'OWN_PRIVATE_API_HOST' => '<server-name-from-cert>' # Add if you want to use TLS for KAS->KAS communication. This is used to verify the TLS certificate host name.

     # 'OWN_PRIVATE_API_CIDR' => '10.0.0.0/8', # IPv4 example
     # 'OWN_PRIVATE_API_CIDR' => '2001:db8:8a2e:370::7334/64', # IPv6 example
     # 'OWN_PRIVATE_API_PORT' => '8155',
     # 'OWN_PRIVATE_API_SCHEME' => 'grpc',
   }

   gitlab_rails['gitlab_kas_external_url'] = 'wss://gitlab.example.com/-/kubernetes-agent/'
   gitlab_rails['gitlab_kas_internal_url'] = 'grpc://kas.internal.gitlab.example.com'
   gitlab_rails['gitlab_kas_external_k8s_proxy_url'] = 'https://gitlab.example.com/-/kubernetes-agent/k8s-proxy/'
   ```

   You might not be able to specify an exact IP address or host name in the `OWN_PRIVATE_API_URL` variable.
   For example, if the kas host is assigned an IP dynamically.

   In this situation, you can configure `OWN_PRIVATE_API_CIDR` instead to set up kas to dynamically construct `OWN_PRIVATE_API_URL`:

   - Comment out `OWN_PRIVATE_API_URL` to disable this variable.
   - Configure `OWN_PRIVATE_API_CIDR` to specify what network kas listens on. When you start kas, kas looks at
     the IP addresses the host is assigned, and uses the address that matches the specified CIDR as its own private IP address.
   - By default, kas uses the port from the `private_api_listen_address` parameter. Configure `OWN_PRIVATE_API_PORT` to use a different port.
   - Optional. By default, kas uses the `grpc` scheme. If you use TLS on the private API endpoint, configure `OWN_PRIVATE_API_SCHEME=grpcs`.
   - Optional. By default, the `client_timeout_seconds` parameter is configured to wait for the kas response for 5 seconds.

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. Optional. If you use a multi-server environment with separate GitLab Rails and Sidekiq nodes, enable the agent server on the Sidekiq nodes.

##### Agent server node settings

| Setting | Description |
|---------|-------------|
| `gitlab_kas['private_api_listen_address']` | The address the agent server listens on. Set to `0.0.0.0` or to an IP address reachable by other nodes in the cluster. |
| `gitlab_kas['api_secret_key']` | The shared secret used for authentication between KAS and GitLab. The value must be Base64-encoded and exactly 32 bytes long. |
| `gitlab_kas['private_api_secret_key']` | The shared secret used for authentication between different KAS instances. The value must be Base64-encoded and exactly 32 bytes long. |
| `OWN_PRIVATE_API_URL` | The environment variable used by KAS for service discovery. Set to the hostname or IP address of the node you're configuring. The node must be reachable by other nodes in the cluster. |
| `OWN_PRIVATE_API_HOST` | Optional value used to verify the TLS certificate host name. <sup>1</sup> A client compares this value to the host name in the server's TLS certificate file.|
| `gitlab_kas['client_timeout_seconds']` | The timeout for the client to connect to the agent server. |
| `gitlab_kas_external_url` | The user-facing URL for the in-cluster `agentk`. Can be a fully qualified domain or subdomain, <sup>2</sup> or a GitLab external URL. <sup>3</sup> If blank, defaults to a GitLab external URL. |
| `gitlab_rails['gitlab_kas_external_url']` | The user-facing URL for the in-cluster `agentk`. If blank, defaults to the `gitlab_kas_external_url`. |
| `gitlab_rails['gitlab_kas_external_k8s_proxy_url']` | The user-facing URL for Kubernetes API proxying. If blank, defaults to a URL based on `gitlab_kas_external_url`. |
| `gitlab_rails['gitlab_kas_internal_url']` | The internal URL the GitLab backend uses to communicate with KAS. |

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
session ID, like the [`_gitlab_session` cookie](../../user/profile/index.md#cookies-used-for-sign-in).
The `_gitlab_kas` cookie must be sent to the KAS proxy endpoint with every request
to authenticate and authorize the user.

## Enable receptive agents

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12180) in GitLab 17.4.

[Receptive agents](../../user/clusters/agent/index.md#receptive-agents) allow GitLab to integrate with Kubernetes clusters
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

You might see a similar error in the Kubernetes Agent Server (KAS) logs of your GitLab application server:

```json
{"level":"error","time":"2023-03-07T20:19:48.151Z","msg":"AgentInfo()","grpc_service":"gitlab.agent.agent_configuration.rpc.AgentConfiguration","grpc_method":"GetConfiguration","error":"Get \"https://gitlab.example.com/api/v4/internal/kubernetes/agent_info\": x509: certificate signed by unknown authority"}
```

To fix this error, install the public certificate of your internal CA in the `/etc/gitlab/trusted-certs` directory.

Alternatively, you can configure your KAS to read the certificate from a custom directory. To do this, add to `/etc/gitlab/gitlab.rb` the following configuration:

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

1. Restart GitLab KAS:

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
