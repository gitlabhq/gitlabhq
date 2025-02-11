---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Configure your GitLab workspaces to manage your GitLab development environments."
title: Configure workspaces
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112397) in GitLab 15.11 [with a flag](../../administration/feature_flags.md) named `remote_development_feature_flag`. Disabled by default.
> - [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/391543) in GitLab 16.0.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136744) in GitLab 16.7. Feature flag `remote_development_feature_flag` removed.

You can use [workspaces](_index.md) to create and manage isolated development environments for your GitLab projects.
Each workspace includes its own set of dependencies, libraries, and tools,
which you can customize to meet the specific needs of each project.

## Set up workspace infrastructure

Before you [create a workspace](#create-a-workspace), you must set up your infrastructure only once.
To set up infrastructure for workspaces:

1. Set up a Kubernetes cluster that the GitLab agent supports.
   See the [supported Kubernetes versions](../clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features).
1. Ensure autoscaling for the Kubernetes cluster is enabled.
1. In the Kubernetes cluster:
   1. Verify that a [default storage class](https://kubernetes.io/docs/concepts/storage/storage-classes/)
      is defined so that volumes can be dynamically provisioned for each workspace.
   1. Install an Ingress controller of your choice (for example, `ingress-nginx`).
   1. [Install](../clusters/agent/install/_index.md) and [configure](gitlab_agent_configuration.md) the GitLab agent.
   1. Point [`dns_zone`](settings.md#dns_zone) and `*.<dns_zone>`
      to the load balancer exposed by the Ingress controller.
      This load balancer must support WebSockets.
   1. [Set up the GitLab workspaces proxy](set_up_gitlab_agent_and_proxies.md).
1. Optional. [Configure sudo access for a workspace](#configure-sudo-access-for-a-workspace).
1. Optional. [Build and run containers in a workspace](#build-and-run-containers-in-a-workspace).
1. Optional. [Configure support for private container registries](#configure-support-for-private-container-registries).

## Create a workspace

> - Support for private projects [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124273) in GitLab 16.4.
> - **Git reference** and **Devfile location** [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/392382) in GitLab 16.10.
> - **Time before automatic termination** [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/392382) to **Workspace automatically terminates after** in GitLab 16.10.
> - **Variables** [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/463514) in GitLab 17.1.
> - **Workspace automatically terminates after** [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166065) in GitLab 17.6.

Prerequisites:

- You must [set up workspace infrastructure](#set-up-workspace-infrastructure).
- You must have at least the Developer role for the workspace and agent projects.

To create a workspace:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Edit > New workspace**.
1. From the **Cluster agent** dropdown list, select a cluster agent owned by the group the project belongs to.
1. From the **Git reference** dropdown list, select the branch, tag, or commit hash
   GitLab uses to create the workspace.
1. From the **Devfile** dropdown list, select one of the following:

   - [GitLab default devfile](_index.md#gitlab-default-devfile).
   - [Custom devfile](_index.md#custom-devfile).

1. In **Variables**, enter the keys and values of the environment variables you want to inject into the workspace.
   To add a new variable, select **Add variable**.
1. Select **Create workspace**.

The workspace might take a few minutes to start.
To open the workspace, under **Preview**, select the workspace.
You also have access to the terminal and can install any necessary dependencies.

## Configure support for private container registries

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14664) in GitLab 17.6.

To use images from private container registries:

1. Create an [image pull secret in Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/).
1. Add the `name` and `namespace` of this secret to the [GitLab agent configuration](gitlab_agent_configuration.md).

For more information, see [`image_pull_secrets`](settings.md#image_pull_secrets).

## Configure sudo access for a workspace

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13983) in GitLab 17.4.

Prerequisites:

- Ensure the container images used in the devfile support [arbitrary user IDs](_index.md#arbitrary-user-ids).
  Sudo access for a workspace does not mean that the container image used
  in a [devfile](_index.md#devfile) can run with a user ID of `0`.

A development environment often requires sudo permissions to
install, configure, and use dependencies during runtime.
You can configure secure sudo access for a workspace with:

- [Sysbox](#with-sysbox)
- [Kata Containers](#with-kata-containers)
- [User namespaces](#with-user-namespaces)

### With Sysbox

[Sysbox](https://github.com/nestybox/sysbox) is a container runtime that improves container isolation
and enables containers to run the same workloads as virtual machines.

To configure sudo access for a workspace with Sysbox:

1. In the Kubernetes cluster, [install Sysbox](https://github.com/nestybox/sysbox#installation).
1. In the GitLab agent for workspaces:
   - Set [`default_runtime_class`](settings.md#default_runtime_class) to the runtime class
     of Sysbox (for example, `sysbox-runc`).
   - Set [`allow_privilege_escalation`](settings.md#allow_privilege_escalation) to `true`.

### With Kata Containers

[Kata Containers](https://github.com/kata-containers/kata-containers) is a standard implementation of lightweight
virtual machines that perform like containers but provide the workload isolation and security of virtual machines.

To configure sudo access for a workspace with Kata Containers:

1. In the Kubernetes cluster, [install Kata Containers](https://github.com/kata-containers/kata-containers/tree/main/docs/install).
1. In the GitLab agent for workspaces:
   - Set [`default_runtime_class`](settings.md#default_runtime_class) to one of the runtime classes
     of Kata Containers (for example, `kata-qemu`).
   - Set [`allow_privilege_escalation`](settings.md#allow_privilege_escalation) to `true`.

### With user namespaces

[User namespaces](https://kubernetes.io/docs/concepts/workloads/pods/user-namespaces/) isolate the user
running inside the container from the user on the host.

To configure sudo access for a workspace with user namespaces:

1. In the Kubernetes cluster, [configure user namespaces](https://kubernetes.io/blog/2024/04/22/userns-beta/).
1. In the GitLab agent for workspaces, set [`use_kubernetes_user_namespaces`](settings.md#use_kubernetes_user_namespaces)
   and [`allow_privilege_escalation`](settings.md#allow_privilege_escalation) to `true`.

## Build and run containers in a workspace

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13983) in GitLab 17.4.

Development environments often require building and running containers to manage and use dependencies
during runtime.
To build and run containers in a workspace, see [configure sudo access for a workspace with Sysbox](#with-sysbox).

## Connect to a workspace with SSH

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10478) in GitLab 16.3.

Prerequisites:

- You must enable SSH access for the images specified in your [devfile](_index.md#devfile).
  For more information, see [update your workspace container image](#update-your-workspace-container-image).
- You must configure a TCP load balancer that points to the GitLab workspaces proxy.
  For more information, see [update your DNS records](set_up_gitlab_agent_and_proxies.md#update-your-dns-records).

To connect to a workspace with an SSH client:

1. Get the external IP address of your `gitlab-workspaces-proxy-ssh` service:

   ```shell
   kubectl -n gitlab-workspaces get service gitlab-workspaces-proxy-ssh
   ```

1. Get the name of the workspace:

   1. On the left sidebar, select **Search or go to**.
   1. Select **Your work**.
   1. Select **Workspaces**.
   1. Copy the name of the workspace you want to connect to.

1. Run this command:

   ```shell
   ssh <workspace_name>@<ssh_proxy_IP_address>
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

- [Tutorial: Set up GitLab agent and proxies](set_up_gitlab_agent_and_proxies.md)
- [Workspace settings](settings.md)
- [Workspace configuration](configuration.md)
- [Troubleshooting Workspaces](workspaces_troubleshooting.md)
- [Quickstart guide for GitLab remote development workspaces](https://go.gitlab.com/AVKFvy)
- [Set up your infrastructure for on-demand, cloud-based development environments in GitLab](https://go.gitlab.com/dp75xo)
