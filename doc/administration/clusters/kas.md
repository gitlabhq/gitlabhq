---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Install the GitLab Agent Server for Kubernetes (KAS) **(FREE SELF)**

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3834) in GitLab 13.10, the GitLab Agent Server (KAS) became available on GitLab.com under `wss://kas.gitlab.com`.
> - [Moved](https://gitlab.com/groups/gitlab-org/-/epics/6290) from GitLab Premium to GitLab Free in 14.5.

The GitLab Agent Server for Kubernetes is a GitLab backend service dedicated to
managing the [GitLab Agent for Kubernetes](../../user/clusters/agent/index.md).

The KAS acronym refers to the former name, Kubernetes Agent Server.

The KAS is already installed and available in GitLab.com under `wss://kas.gitlab.com`.
This document describes how to install a KAS for GitLab self-managed instances.

## Installation options

As a GitLab administrator of self-managed instances, you can install KAS according to your GitLab
installation method:

- For [Omnibus installations](#install-kas-with-omnibus).
- For [GitLab Helm Chart installations](#install-kas-with-the-gitlab-helm-chart).

You can also opt to use an [external KAS](#use-an-external-kas-installation).

### Install KAS with Omnibus

For [Omnibus](https://docs.gitlab.com/omnibus/) package installations:

1. Edit `/etc/gitlab/gitlab.rb` to enable the Agent Server:

   ```ruby
   gitlab_kas['enable'] = true
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

To configure any additional options related to your KAS,
refer to the **Enable GitLab KAS** section of the
[`gitlab.rb.template`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-config-template/gitlab.rb.template).

### Install KAS with the GitLab Helm Chart

For GitLab [Helm Chart](https://docs.gitlab.com/charts/)
installations, you must set `global.kas.enabled` to `true`.
For example, in a shell with `helm` and `kubectl`
installed, run:

```shell
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
  --timeout 600s \
  --set global.hosts.domain=<YOUR_DOMAIN> \
  --set global.hosts.externalIP=<YOUR_IP> \
  --set certmanager-issuer.email=<YOUR_EMAIL> \
  --set global.kas.enabled=true # <-- without this, KAS will not be installed
```

To configure KAS, use a `gitlab.kas` sub-section in your `values.yaml` file:

```yaml
gitlab:
  kas:
    # put your KAS custom options here
```

For details, see [how to use the GitLab-KAS chart](https://docs.gitlab.com/charts/charts/gitlab/kas/).

### Use an external KAS installation

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/299850) in GitLab 13.10.

Besides installing KAS with GitLab, you can opt to configure GitLab to use an external KAS.

For GitLab instances installed through the GitLab Helm Chart, see [how to configure your external KAS](https://docs.gitlab.com/charts/charts/globals.html#external-kas).

For GitLab instances installed through Omnibus packages:

1. Edit `/etc/gitlab/gitlab.rb` adding the paths to your external KAS:

   ```ruby
   gitlab_kas['enable'] = false
   gitlab_kas['api_secret_key'] = 'Your shared secret between GitLab and KAS'

   gitlab_rails['gitlab_kas_enabled'] = true
   gitlab_rails['gitlab_kas_external_url'] = 'wss://kas.gitlab.example.com' # User-facing URL for the in-cluster agentk
   gitlab_rails['gitlab_kas_internal_url'] = 'grpc://kas.internal.gitlab.example.com' # Internal URL for the GitLab backend
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

## Troubleshooting

If you have issues while using the GitLab Agent Server for Kubernetes, view the
service logs by running the following command:

```shell
kubectl logs -f -l=app=kas -n <YOUR-GITLAB-NAMESPACE>
```

In Omnibus GitLab, find the logs in `/var/log/gitlab/gitlab-kas/`.

You can also [troubleshoot issues with individual Agents](../../user/clusters/agent/troubleshooting.md).

### KAS logs - GitOps: failed to get project information

If you get the following error message:

```json
{"level":"warn","time":"2020-10-30T08:37:26.123Z","msg":"GitOps: failed to get project info","agent_id":4,"project_id":"root/kas-manifest001","error":"error kind: 0; status: 404"}
```

It means that the specified manifest project `root/kas-manifest001`
doesn't exist or the manifest project is private. To fix it, make sure the project path is correct
and its visibility is [set to public](../../public_access/public_access.md).

### KAS logs - Configuration file not found

If you get the following error message:

```plaintext
time="2020-10-29T04:44:14Z" level=warning msg="Config: failed to fetch" agent_id=2 error="configuration file not found: \".gitlab/agents/test-agent/config.yaml\
```

It means that the path to the configuration project is incorrect,
or the path to `config.yaml` inside the project is not valid.

To fix this, ensure that the paths to the configuration repository and to the `config.yaml` file
are correct.

### KAS logs - `dial tcp <GITLAB_INTERNAL_IP>:443: connect: connection refused`

If you are running a self-managed GitLab instance and:

- The instance isn't running behind an SSL-terminating proxy.
- The instance doesn't have HTTPS configured on the GitLab instance itself.
- The instance's hostname resolves locally to its internal IP address.

You may see the following error when the KAS tries to connect to the GitLab API:

```json
{"level":"error","time":"2021-08-16T14:56:47.289Z","msg":"GetAgentInfo()","correlation_id":"01FD7QE35RXXXX8R47WZFBAXTN","grpc_service":"gitlab.agent.reverse_tunnel.rpc.ReverseTunnel","grpc_method":"Connect","error":"Get \"https://gitlab.example.com/api/v4/internal/kubernetes/agent_info\": dial tcp 172.17.0.4:443: connect: connection refused"}
```

To fix this for [Omnibus](https://docs.gitlab.com/omnibus/) package installations,
set the following parameter in `/etc/gitlab/gitlab.rb`
(replacing `gitlab.example.com` with your GitLab instance's hostname):

```ruby
gitlab_kas['gitlab_address'] = 'http://gitlab.example.com'
```
