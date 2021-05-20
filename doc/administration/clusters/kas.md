---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Install the Kubernetes Agent Server (KAS) **(PREMIUM SELF)**

The Kubernetes Agent Server (KAS) is a GitLab backend service dedicated to
managing [Kubernetes Agents](../../user/clusters/agent/index.md).

The KAS is already installed and available in GitLab.com under `wss://kas.gitlab.com`.
See [how to use GitLab.com's KAS](../../user/clusters/agent/index.md#set-up-the-kubernetes-agent-server).
This document describes how to install a KAS for GitLab self-managed instances.

## Installation options

As a GitLab administrator of self-managed instances, you can install KAS according to your GitLab
installation method:

- For [Omnibus installations](#install-kas-with-omnibus).
- For [GitLab Helm Chart installations](#install-kas-with-the-gitlab-helm-chart).

You can also opt to use an [external KAS](#use-an-external-kas-installation).

### Install KAS with Omnibus

For [Omnibus](https://docs.gitlab.com/omnibus/) package installations:

1. Edit `/etc/gitlab/gitlab.rb` to enable the Kubernetes Agent Server:

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

If you face any issues with KAS, you can read the service logs
with the following command:

```shell
kubectl logs -f -l=app=kas -n <YOUR-GITLAB-NAMESPACE>
```

In Omnibus GitLab, find the logs in `/var/log/gitlab/gitlab-kas/`.

See also the [user documentation](../../user/clusters/agent/index.md#troubleshooting)
for troubleshooting problems with individual agents.

### KAS logs - GitOps: failed to get project info

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
