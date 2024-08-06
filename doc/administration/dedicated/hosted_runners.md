---
stage: SaaS Platforms
group: GitLab Dedicated
description: Use hosted runners to run your CI/CD jobs on GitLab Dedicated.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Hosted runners for GitLab Dedicated

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Dedicated
**Status:** Beta

> - [Introduced](https://about.gitlab.com/blog/2024/01/31/hosted-runners-for-gitlab-dedicated-available-in-beta/) as [beta](../../policy/experiment-beta-support.md#beta) on GitLab Dedicated in GitLab on January 31, 2024.

NOTE:
To use this feature, you must [purchase a subscription](../../subscriptions/subscription-add-ons.md) for Hosted Runners for GitLab Dedicated. To participate in the closed beta of Hosted Runners for Dedicated, reach out to your Customer Success Manager or Account representative.

You can run your CI/CD jobs on GitLab-hosted [runners](../../ci/runners/index.md). These runners are managed by GitLab and fully integrated with your GitLab Dedicated instance.
GitLab-hosted runners for Dedicated are autoscaling [instance runners](../../ci/runners/runners_scope.md#instance-runners),
running on AWS EC2 in the same region as the GitLab Dedicated instance.

When you use hosted runners:

- Each job runs in a newly provisioned virtual machine (VM), which is dedicated to the specific job.
- The VM where your job runs has `sudo` access with no password.
- The storage is shared by the operating system, the image with pre-installed software, and a copy of your cloned repository. This means that the available free disk space for your jobs is reduced.
- By default, untagged jobs run on the small Linux x86-64 runner. GitLab administrators can [change the run untagged jobs option in GitLab](#configure-hosted-runners-in-gitlab).

## Security

This section provides an overview of the additional built-in layers that harden the security of the GitLab Runner build environment.

Hosted runners for GitLab Dedicated are configured as such:

- Firewall rules only allow outbound communication from the ephemeral VM to the public internet.
- Inbound communication from the public internet to the ephemeral VM is not allowed.
- Firewall rules do not permit communication between VMs.
- The only internal communication allowed to the ephemeral VMs is from the runner manager.
- Ephemeral runner VMs will only serve a single job and will be deleted right after the job execution.

In addition, you can also [configure a private connection](#configure-outbound-private-link) from the hosted runners to your AWS account that bypasses the public internet.

For more information, see the architecture diagram for [Hosted runners for GitLab Dedicated](index.md#hosted-runners-for-gitlab-dedicated).

## Pricing

During Beta, hosted runners for GitLab Dedicated are free of charge. The detailed pricing model will be announced with the general availability.

## Hosted runners on Linux

Hosted runners on Linux for GitLab Dedicated use the [Docker Autoscaler](https://docs.gitlab.com/runner/executors/docker_autoscaler.html) executor. Each job gets a Docker environment in a fully isolated, ephemeral virtual machine (VM), and runs on the latest version of Docker Engine.

### Machine types for Linux (x86-64)

The following machine types are available for hosted runners on Linux x86-64.

| Size    | Runner Tag                    | vCPUs | Memory | Storage |
|---------|-------------------------------|-------|--------|---------|
| Small   | `linux-small-amd64` (default) | 2     | 8 GB   | 30 GB   |
| Medium  | `linux-medium-amd64`          | 4     | 16 GB  | 50 GB   |
| Large   | `linux-large-amd64`           | 8     | 32 GB  | 100 GB  |
| X-Large  | `linux-xlarge-amd64`          | 16    | 64 GB  | 200 GB  |
| 2X-Large | `linux-2xlarge-amd64`         | 32    | 128 GB | 200 GB  |

NOTE:
The machine type and underlying processor type might change. Jobs optimized for a specific processor design might behave inconsistently.

Default runner tags are assigned upon creation. Administrators can subsequently [modify the tag settings](#configure-hosted-runners-in-gitlab) for their instance runners.

### Container images

As runners on Linux are using the [Docker Autoscaler](https://docs.gitlab.com/runner/executors/docker_autoscaler.html) executor, you can choose any container image by defining the image in your `.gitlab-ci.yml` file. Make sure that the selected Docker image is compatible with the underlying processor architecture. See the [example `.gitlab-ci.yml` file](../../ci/runners/hosted_runners/linux.md#example-gitlab-ciyml-file).

If no image is set, the default is `ruby:3.1`.

If you use images from the Docker Hub container registry, you might run into [rate limits](../../administration/settings/user_and_ip_rate_limits.md). This is because GitLab Dedicated uses a single Network Address Translation (NAT) IP address.

To avoid rate limits, instead use:

- Images stored in the [GitLab container registry](../../user/packages/container_registry/index.md).
- Images stored in other public registries with no rate limits.
- The [dependency proxy](../../user/packages/dependency_proxy/index.md), acting as a pull-through cache.

### Docker in Docker support

The runners are configured to run in `privileged` mode to support [Docker in Docker](../../ci/docker/using_docker_build.md#use-docker-in-docker) to build Docker images natively or run multiple containers within your isolated job.

## Manage hosted runners in Switchboard

You can create and view hosted runners for your GitLab Dedicated instance using Switchboard.

Prerequisites:

- You must [purchase a subscription](../../subscriptions/subscription-add-ons.md) for Hosted Runners for GitLab Dedicated.

### Create hosted runners in Switchboard

To create hosted runners:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com).
1. At the top of the page, select **Hosted runners**.
1. Select **New hosted runner**.
1. Choose a size for the runner, then select **Create hosted runner**.

You will receive an email notification when your hosted runner is ready to use.

### View hosted runners in Switchboard

To view hosted runners:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com).
1. At the top of the page, select **Hosted runners**.
1. Optional. From the list of hosted runners, copy the **Runner ID** of the runner you want to access in GitLab.

## View and configure hosted runners in GitLab

GitLab administrators can manage hosted runners for their GitLab Dedicated instance from the [**Admin** area](../../administration/admin_area.md#administering-runners).

### View hosted runners in GitLab

You can view hosted runners for your GitLab Dedicated instance in the Runners page and in the [Fleet dashboard](../../ci/runners/runner_fleet_dashboard.md).

Prerequisites:

- You must be an administrator.

To view hosted runners in GitLab:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **CI/CD > Runners**.
1. Optional. Select **Fleet dashboard**.

### Configure hosted runners in GitLab

Prerequisites:

- You must be an administrator.

You can configure hosted runners for your GitLab Dedicated instance, including changing the default values for the runner tags.

Available configuration options include:

- [Change the maximum job timeout](../../ci/runners/configure_runners.md#for-an-instance-runner).
- [Set the runner to run tagged or untagged jobs](../../ci/runners/configure_runners.md#for-an-instance-runner-2).
 
NOTE:
Any changes to the runner description and the runner tags are not controlled by GitLab.

### Disable hosted runners for groups or projects in GitLab

By default, hosted runners are available for all projects and groups in your GitLab Dedicated instance.
GitLab maintainers can disable hosted runners for a [project](../../ci/runners/runners_scope.md#disable-instance-runners-for-a-project) or a [group](../../ci/runners/runners_scope.md#disable-instance-runners-for-a-group).

## Configure outbound private link

Outbound private link allows hosted runners for GitLab Dedicated to securely communicate with services running in your VPC on AWS without exposing any traffic to the public internet.

This type of connection allows GitLab-hosted runners connection to:

- access private services, such as custom secrets managers
- artifacts or job images stored in your infrastructure
- deployments into your infrastructure

For more information on how to configure Outbound Private Link for hosted runners for GitLab Dedicated, read [Outbound Private Link](../../administration/dedicated/configure_instance.md#outbound-private-link).

## IP ranges

IP ranges for hosted runners for GitLab Dedicated are available upon request. IP ranges are maintained on a best-effort basis and may change at any time due to changes in the infrastructure. For more information, reach out to your Customer Success Manager or Account representative.

## Migrate jobs to hosted runners

To migrate your jobs to use hosted runners:

1. Use the small Linux x86-64 runner for untagged jobs.
1. Add the appropriate tags to your job configurations in the `.gitlab-ci.yml` file:

    ```yaml
    job_name:
      tags:
        - linux-medium-amd64  # Use the medium-sized Linux runner
    ```

1. [Modify the tags](#configure-hosted-runners-in-gitlab) to match your existing job configurations.

GitLab administrators can [configure instance runners in GitLab](#configure-hosted-runners-in-gitlab) to not run untagged jobs.
