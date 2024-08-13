---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Configure your GitLab workspaces to manage your GitLab development environments."
---

# Workspace configuration

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112397) in GitLab 15.11 [with a flag](../../administration/feature_flags.md) named `remote_development_feature_flag`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/391543) in GitLab 16.0.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136744) in GitLab 16.7. Feature flag `remote_development_feature_flag` removed.

You can use [workspaces](index.md) to create and manage isolated development environments for your GitLab projects.
Each workspace includes its own set of dependencies, libraries, and tools,
which you can customize to meet the specific needs of each project.

## Set up workspace infrastructure

Before you [create a workspace](#create-a-workspace), you must set up your infrastructure only once.
To set up infrastructure for workspaces:

1. Set up a Kubernetes cluster that the GitLab agent supports.
   See the [supported Kubernetes versions](../clusters/agent/index.md#supported-kubernetes-versions-for-gitlab-features).
1. Ensure autoscaling for the Kubernetes cluster is enabled.
1. In the Kubernetes cluster:
   1. Verify that a [default storage class](https://kubernetes.io/docs/concepts/storage/storage-classes/)
      is defined so that volumes can be dynamically provisioned for each workspace.
   1. Install an Ingress controller of your choice (for example, `ingress-nginx`).
   1. [Install](../clusters/agent/install/index.md) and [configure](gitlab_agent_configuration.md) the GitLab agent.
   1. Point [`dns_zone`](gitlab_agent_configuration.md#dns_zone) and `*.<dns_zone>`
      to the load balancer exposed by the Ingress controller.
   1. [Set up the GitLab workspaces proxy](set_up_workspaces_proxy.md).

## Create a workspace

> - Support for private projects [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124273) in GitLab 16.4.
> - **Git reference** and **Devfile location** [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/392382) in GitLab 16.10.
> - **Time before automatic termination** [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/392382) to **Workspace automatically terminates after** in GitLab 16.10.
> - **Variables** [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/463514) in GitLab 17.1.

Prerequisites:

- Ensure your [workspace infrastructure](#set-up-workspace-infrastructure) is already set up.
- You must have at least the Developer role in the workspace or agent project.
- In each project where you want to create a workspace, create a [devfile](index.md#devfile):
  1. On the left sidebar, select **Search or go to** and find your project.
  1. In the root directory of your project, create a file named `devfile`.
     You can use one of the [example configurations](index.md#example-configurations).
- Ensure the container images used in the devfile support [arbitrary user IDs](index.md#arbitrary-user-ids).

To create a workspace:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Edit > New workspace**.
1. From the **Cluster agent** dropdown list, select a cluster agent owned by the group the project belongs to.
1. From the **Git reference** dropdown list, select the branch, tag, or commit hash
   GitLab uses to create the workspace.
1. In **Devfile location**, enter the path to the devfile you use to configure the workspace.
   If your devfile is not in the root directory of your project, specify a relative path.
1. In **Workspace automatically terminates after**, enter the number of hours until the workspace automatically terminates.
   This timeout is a safety measure to prevent a workspace from consuming excessive resources or running indefinitely.
1. In **Variables**, enter the keys and values of the environment variables you want to inject into the workspace.
   To add a new variable, select **Add variable**.
1. Select **Create workspace**.

The workspace might take a few minutes to start.
To open the workspace, under **Preview**, select the workspace.
You also have access to the terminal and can install any necessary dependencies.

## Connect to a workspace with SSH

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10478) in GitLab 16.3.

Prerequisites:

- SSH must be enabled for the workspace.
- You must have a TCP load balancer that points to the [GitLab workspaces proxy](set_up_workspaces_proxy.md).

To connect to a workspace with an SSH client:

1. Get the name of the workspace:

   1. On the left sidebar, select **Search or go to**.
   1. Select **Your work**.
   1. Select **Workspaces**.
   1. Copy the name of the workspace you want to connect to.

1. Run this command:

   ```shell
   ssh <workspace_name>@<ssh_proxy>
   ```

1. For the password, enter your personal access token with at least the `read_api` scope.

When you connect to `gitlab-workspaces-proxy` through the TCP load balancer,
`gitlab-workspaces-proxy` examines the username (workspace name) and interacts with GitLab to verify:

- The personal access token
- User access to the workspace

### Update your workspace container image

To update your runtime images for SSH connections:

1. Install [`sshd`](https://man.openbsd.org/sshd.8) in your runtime images.
1. Create a user named `gitlab-workspaces` to allow access to your container without a password.

```Dockerfile
FROM golang:1.20.5-bullseye

# Install `openssh-server` and other dependencies
RUN apt update \
    && apt upgrade -y \
    && apt install  openssh-server sudo curl git wget software-properties-common apt-transport-https --yes \
    && rm -rf /var/lib/apt/lists/*

# Permit empty passwords
RUN sed -i 's/nullok_secure/nullok/' /etc/pam.d/common-auth
RUN echo "PermitEmptyPasswords yes" >> /etc/ssh/sshd_config

# Generate a workspace host key
RUN ssh-keygen -A
RUN chmod 775 /etc/ssh/ssh_host_rsa_key && \
    chmod 775 /etc/ssh/ssh_host_ecdsa_key && \
    chmod 775 /etc/ssh/ssh_host_ed25519_key

# Create a `gitlab-workspaces` user
RUN useradd -l -u 5001 -G sudo -md /home/gitlab-workspaces -s /bin/bash gitlab-workspaces
RUN passwd -d gitlab-workspaces
ENV HOME=/home/gitlab-workspaces
WORKDIR $HOME
RUN mkdir -p /home/gitlab-workspaces && chgrp -R 0 /home && chmod -R g=u /etc/passwd /etc/group /home

# Allow sign-in access to `/etc/shadow`
RUN chmod 775 /etc/shadow

USER gitlab-workspaces
```

## Related topics

- [Quickstart guide for GitLab remote development workspaces](https://go.gitlab.com/AVKFvy)
- [Set up your infrastructure for on-demand, cloud-based development environments in GitLab](https://go.gitlab.com/dp75xo)

## Troubleshooting

When working with workspaces, you might encounter the following issues.

### `Failed to renew lease` when creating a workspace

You might not be able to create a workspace due to a known issue in the GitLab agent for Kubernetes.
The following error message might appear in the agent's log:

```plaintext
{"level":"info","time":"2023-01-01T00:00:00.000Z","msg":"failed to renew lease gitlab-agent-remote-dev-dev/agent-123XX-lock: timed out waiting for the condition\n","agent_id":XXXX}
```

This issue occurs when an agent instance cannot renew its leadership lease, which results
in the shutdown of leader-only modules including the `remote_development` module.
To resolve this issue, restart the agent instance.

### Error: `No agents available to create workspaces`

When you create a workspace in a project, you might get the following error:

```plaintext
No agents available to create workspaces. Please consult Workspaces documentation for troubleshooting.
```

To resolve this issue:

- If you do not have at least the Developer role in the workspace or agent project, contact your administrator.
- If the ancestor groups of the project do not have an allowed agent,
  [allow an agent](gitlab_agent_configuration.md#allow-a-cluster-agent-for-workspaces-in-a-group) for any of these groups.
- If the `remote_development` module is disabled for the GitLab agent,
  set [`enabled`](gitlab_agent_configuration.md#enabled) to `true`.
