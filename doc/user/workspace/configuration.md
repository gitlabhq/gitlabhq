---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Configure your GitLab workspaces to manage your GitLab development environments.
title: Configure workspaces
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Feature flag `remote_development_feature_flag` [enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/391543) in GitLab 16.0.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136744) in GitLab 16.7. Feature flag `remote_development_feature_flag` removed.

{{< /history >}}

You can use [workspaces](_index.md) to create and manage isolated development environments for your GitLab projects.
Each workspace includes its own set of dependencies, libraries, and tools,
which you can customize to meet the specific needs of each project.

## Set up workspace infrastructure

Before you [create a workspace](#create-a-workspace), you must set up your infrastructure only once.
To set up infrastructure for workspaces, regardless of cloud provider, you must:

1. Set up a Kubernetes cluster that the [GitLab agent for Kubernetes](../clusters/agent/_index.md) supports.
   See the [supported Kubernetes versions](../clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features).
1. Ensure autoscaling for the Kubernetes cluster is enabled.
1. In the Kubernetes cluster:
   1. Verify that a [default storage class](https://kubernetes.io/docs/concepts/storage/storage-classes/)
      is defined so that volumes can be dynamically provisioned for each workspace.
1. Complete all steps in the [Tutorial: Set up the GitLab agent for Kubernetes](set_up_gitlab_agent_and_proxies.md).
1. Optional. [Build and run containers in a workspace](#build-and-run-containers-in-a-workspace).
1. Optional. [Configure support for private container registries](#configure-support-for-private-container-registries).
1. Optional. [Configure sudo access for a workspace](#configure-sudo-access-for-a-workspace).

If you use AWS, you can use our OpenTofu tutorial. For more information, see
[Tutorial: Set up workspaces infrastructure on AWS](set_up_infrastructure.md).

## Create a workspace

{{< history >}}

- **Time before automatic termination** [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120168) in GitLab 16.0
- Support for private projects [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124273) in GitLab 16.4.
- **Git reference** and **Devfile location** [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/392382) in GitLab 16.10.
- **Time before automatic termination** [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/392382) to **Workspace automatically terminates after** in GitLab 16.10.
- **Variables** [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/463514) in GitLab 17.1.
- **Workspace automatically terminates after** [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166065) in GitLab 17.6.
- **Workspace can be created from Merge Request page** [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/187320) in GitLab 18.0.

{{< /history >}}

{{< alert type="warning" >}}

Create a workspace only from trusted projects.

{{< /alert >}}

Prerequisites:

- You must [set up workspace infrastructure](#set-up-workspace-infrastructure).
- You must have at least the Developer role for the workspace and agent projects.

{{< tabs >}}

{{< tab title="From a project" >}}

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Edit** > **New workspace**.
1. From the **Cluster agent** dropdown list, select a cluster agent owned by the group the project belongs to.
1. From the **Git reference** dropdown list, select the branch, tag, or commit hash
   GitLab uses to create the workspace. By default, this is the branch you're viewing.
1. From the **Devfile** dropdown list, select one of the following:
   - [GitLab default devfile](_index.md#gitlab-default-devfile).
   - [Custom devfile](_index.md#custom-devfile).
1. In **Variables**, enter the keys and values of the environment variables you want to inject into the workspace.
   To add a new variable, select **Add variable**.
1. Select **Create workspace**.

{{< /tab >}}

{{< tab title="From a merge request" >}}

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. On the left sidebar, select **Code** > **Merge requests**.
1. Select the merge request you want to create a workspace for.
1. Select **Code** > **Open in Workspace**.
1. From the **Cluster agent** dropdown list, select a cluster agent owned by the group the project belongs to.
1. From the **Git reference** dropdown list, select the branch, tag, or commit hash
   GitLab uses to create the workspace. By default, this is the source branch of the merge request.
1. From the **Devfile** dropdown list, select one of the following:
   - [GitLab default devfile](_index.md#gitlab-default-devfile).
   - [Custom devfile](_index.md#custom-devfile).
1. In **Variables**, enter the keys and values of the environment variables you want to inject into the workspace.
   To add a new variable, select **Add variable**.
1. Select **Create workspace**.

{{< /tab >}}

{{< /tabs >}}

The workspace might take a few minutes to start.
To open the workspace, under **Preview**, select the workspace.
You also have access to the terminal and can install any necessary dependencies.

### Monitor workspace startup progress

When you start a workspace, you can monitor the progress of initialization tasks and `postStart`
events by checking the workspace logs. For more information, see [Workspace logs directory](_index.md#workspace-logs-directory).

## Platform compatibility

The platform requirements for workspaces depend on your development needs.

For basic workspace functionality, workspaces run on any `linux/amd64` Kubernetes cluster that supports
the GitLab agent for Kubernetes, regardless of the underlying operating system.

To choose a method that fits your platform requirements, see [Configure sudo access for a workspace](#configure-sudo-access-for-a-workspace).

## Build and run containers in a workspace

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13983) in GitLab 17.4.

{{< /history >}}

Development environments often require building and running containers to manage and use dependencies
during runtime.
To build and run containers in a workspace, see [configure sudo access for a workspace with Sysbox](#with-sysbox).

## Configure support for private container registries

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14664) in GitLab 17.6.

{{< /history >}}

To use images from private container registries:

1. Create an [image pull secret in Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/).
1. Add the `name` and `namespace` of this secret to the [GitLab agent for Kubernetes configuration](gitlab_agent_configuration.md).

For more information, see [`image_pull_secrets`](settings.md#image_pull_secrets).

## Configure sudo access for a workspace

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13983) in GitLab 17.4.

{{< /history >}}

Development environments often require sudo permissions to install, configure, and use dependencies
during runtime. Choose the method that fits your platform requirements:

| Method                                   | Platform requirements                                                                                                                                                                                                                                                                     | Usage |
|------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------|
| [Sysbox](#with-sysbox)                   | For up-to-date information, see the [Sysbox distribution compatibility matrix](https://github.com/nestybox/sysbox/blob/master/docs/distro-compat.md).                                                                                                                                     | Improves container isolation and enables containers to run the same workloads as virtual machines. |
| [Kata Containers](#with-kata-containers) | For up-to-date information, see the [Kata Containers installation guides](https://github.com/kata-containers/kata-containers/tree/main/docs/install).                                                                                                                                     | Lightweight VMs perform like containers but provide enhanced workload isolation and security. |
| [User namespaces](#with-user-namespaces) | Kubernetes version 1.33 or later have the user namespaces enabled behind a Kubernetes feature gate which is enabled by default. For up-to-date information, see the [Kubernetes Feature Gates](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/). | No additional runtime installation required. Isolates container users from host users for improved security. |

Prerequisites:

- Your container images must support [arbitrary user IDs](_index.md#arbitrary-user-ids).
  Even with sudo access configured, container images used in a [devfile](_index.md#devfile)
  cannot run with a user ID of `0`.

### With Sysbox

[Sysbox](https://github.com/nestybox/sysbox) is a container runtime that improves container isolation
and enables containers to run the same workloads as virtual machines.

To configure sudo access with Sysbox:

1. In your Kubernetes cluster, [install Sysbox](https://github.com/nestybox/sysbox#installation).
1. Configure the GitLab agent for Kubernetes:

   - Set the default runtime class. In [`default_runtime_class`](settings.md#default_runtime_class),
     enter the runtime class for Sysbox. For example, `sysbox-runc`.
   - Enable privilege escalation.
     Set [`allow_privilege_escalation`](settings.md#allow_privilege_escalation) to `true`.
   - Configure the annotations required by Sysbox. Set [`annotations`](settings.md#annotations) to
     `{"io.kubernetes.cri-o.userns-mode": "auto:size=65536"}`.

### With Kata Containers

[Kata Containers](https://github.com/kata-containers/kata-containers) is a standard implementation
of lightweight virtual machines that perform like containers but provide the workload isolation and
security of virtual machines.

To configure sudo access with Kata Containers:

1. In your Kubernetes cluster, [install Kata Containers](https://github.com/kata-containers/kata-containers/tree/main/docs/install).
1. Configure the GitLab agent for Kubernetes:

   - Set the default runtime class. In [`default_runtime_class`](settings.md#default_runtime_class),
     enter the runtime class for Kata Containers. For example, `kata-qemu`.
   - Enable privilege escalation.
     Set [`allow_privilege_escalation`](settings.md#allow_privilege_escalation) to `true`.

### With user namespaces

[User namespaces](https://kubernetes.io/docs/concepts/workloads/pods/user-namespaces/) isolate
container users from host users.

To configure sudo access with user namespaces:

1. In your Kubernetes cluster, [configure user namespaces](https://kubernetes.io/blog/2024/04/22/userns-beta/).
1. Configure the GitLab agent for Kubernetes:

   - Set [`use_kubernetes_user_namespaces`](settings.md#use_kubernetes_user_namespaces) to `true`.
   - Set [`allow_privilege_escalation`](settings.md#allow_privilege_escalation) to `true`.

## Connect to a workspace with SSH

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10478) in GitLab 16.3.

{{< /history >}}

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

   1. On the left sidebar, select **Search or go to**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
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

You can update your custom workspace images in two ways.

If your workspace image is based on the [workspace base image](_index.md#workspace-base-image),
SSH support is already configured and ready to use. This approach ensures your image has all
necessary workspace configurations.
For detailed instructions, see [Create a custom workspace image](create_image.md).

If you prefer not to use the workspace base image, you can build from your own base image. If you do
this, configure SSH support manually in your runtime images:

1. Install [`sshd`](https://man.openbsd.org/sshd.8) in your runtime images.
1. Create a user named `gitlab-workspaces` to allow access to your container without a password.

The following is an SSH configuration example:

```dockerfile
FROM golang:1.20.5-bullseye

# Install `openssh-server` and other dependencies
RUN apt update \
    && apt upgrade -y \
    && apt install openssh-server sudo curl git wget software-properties-common apt-transport-https --yes \
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

- [Tutorial: Set up the GitLab agent for Kubernetes](set_up_gitlab_agent_and_proxies.md)
- [Workspace settings](settings.md)
- [Workspace configuration](configuration.md)
- [Troubleshooting Workspaces](workspaces_troubleshooting.md)
- [Quickstart guide for GitLab remote development workspaces](https://go.gitlab.com/AVKFvy)
- [Set up your infrastructure for on-demand, cloud-based development environments in GitLab](https://go.gitlab.com/dp75xo)
