---
stage: Verify
group: Hosted Runners
description: Use hosted runners to run your CI/CD jobs on GitLab Dedicated.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Hosted runners for GitLab Dedicated
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Dedicated
**Status:** Limited availability

NOTE:
To use this feature, you must purchase a subscription for Hosted Runners for GitLab Dedicated. To participate in the limited availability of Hosted Runners for Dedicated, reach out to your Customer Success Manager or Account representative.

You can run your CI/CD jobs on GitLab-hosted [runners](../../ci/runners/_index.md). These runners are managed by GitLab and fully integrated with your GitLab Dedicated instance.
GitLab-hosted runners for Dedicated are autoscaling [instance runners](../../ci/runners/runners_scope.md#instance-runners),
running on AWS EC2 in the same region as the GitLab Dedicated instance.

When you use hosted runners:

- Each job runs in a newly provisioned virtual machine (VM), which is dedicated to the specific job.
- The VM where your job runs has `sudo` access with no password.
- The storage is shared by the operating system, the image with pre-installed software, and a copy of your cloned repository. This means that the available free disk space for your jobs is reduced.
- By default, untagged jobs run on the small Linux x86-64 runner. GitLab administrators can [change the run untagged jobs option in GitLab](#configure-hosted-runners-in-gitlab).

## Hosted runners on Linux

Hosted runners on Linux for GitLab Dedicated use the [Docker Autoscaler](https://docs.gitlab.com/runner/executors/docker_autoscaler.html) executor. Each job gets a Docker environment in a fully isolated, ephemeral virtual machine (VM), and runs on the latest version of Docker Engine.

### Machine types for Linux - x86-64

The following machine types are available for hosted runners on Linux x86-64.

| Size     | Runner Tag                    | vCPUs | Memory | Storage |
|----------|-------------------------------|-------|--------|---------|
| Small    | `linux-small-amd64` (default) | 2     | 8 GB   | 30 GB   |
| Medium   | `linux-medium-amd64`          | 4     | 16 GB  | 50 GB   |
| Large    | `linux-large-amd64`           | 8     | 32 GB  | 100 GB  |
| X-Large  | `linux-xlarge-amd64`          | 16    | 64 GB  | 200 GB  |
| 2X-Large | `linux-2xlarge-amd64`         | 32    | 128 GB | 200 GB  |

### Machine types for Linux - Arm64

The following machine types are available for hosted runners on Linux Arm64.

| Size     | Runner Tag            | vCPUs | Memory | Storage |
|----------|-----------------------|-------|--------|---------|
| Small    | `linux-small-arm64`   | 2     | 8 GB   | 30 GB   |
| Medium   | `linux-medium-arm64`  | 4     | 16 GB  | 50 GB   |
| Large    | `linux-large-arm64`   | 8     | 32 GB  | 100 GB  |
| X-Large  | `linux-xlarge-arm64`  | 16    | 64 GB  | 200 GB  |
| 2X-Large | `linux-2xlarge-arm64` | 32    | 128 GB | 200 GB  |

NOTE:
The machine type and underlying processor type might change. Jobs optimized for a specific processor design might behave inconsistently.

Default runner tags are assigned upon creation. Administrators can subsequently [modify the tag settings](#configure-hosted-runners-in-gitlab) for their instance runners.

### Container images

As runners on Linux are using the [Docker Autoscaler](https://docs.gitlab.com/runner/executors/docker_autoscaler.html) executor, you can choose any container image by defining the image in your `.gitlab-ci.yml` file. Make sure that the selected Docker image is compatible with the underlying processor architecture. See the [example `.gitlab-ci.yml` file](../../ci/runners/hosted_runners/linux.md#example-gitlab-ciyml-file).

If no image is set, the default is `ruby:3.1`.

If you use images from the Docker Hub container registry, you might run into [rate limits](../settings/user_and_ip_rate_limits.md). This is because GitLab Dedicated uses a single Network Address Translation (NAT) IP address.

To avoid rate limits, instead use:

- Images stored in the [GitLab container registry](../../user/packages/container_registry/_index.md).
- Images stored in other public registries with no rate limits.
- The [dependency proxy](../../user/packages/dependency_proxy/_index.md), acting as a pull-through cache.

### Docker in Docker support

The runners are configured to run in `privileged` mode to support [Docker in Docker](../../ci/docker/using_docker_build.md#use-docker-in-docker) to build Docker images natively or run multiple containers within your isolated job.

## Manage hosted runners

### Manage hosted runners in Switchboard

You can create and view hosted runners for your GitLab Dedicated instance using Switchboard.

Prerequisites:

- You must purchase a subscription for Hosted Runners for GitLab Dedicated.

#### Create hosted runners in Switchboard

For each instance, you can create one runner of each type and size combination. Switchboard displays the available runner options.

To create hosted runners:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com).
1. At the top of the page, select **Hosted runners**.
1. Select **New hosted runner**.
1. Choose a size for the runner, then select **Create hosted runner**.

You will receive an email notification when your hosted runner is ready to use.

#### View hosted runners in Switchboard

To view hosted runners:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com).
1. At the top of the page, select **Hosted runners**.
1. Optional. From the list of hosted runners, copy the **Runner ID** of the runner you want to access in GitLab.

### View and configure hosted runners in GitLab

GitLab administrators can manage hosted runners for their GitLab Dedicated instance from the [**Admin** area](../admin_area.md#administering-runners).

#### View hosted runners in GitLab

You can view hosted runners for your GitLab Dedicated instance in the Runners page and in the [Fleet dashboard](../../ci/runners/runner_fleet_dashboard.md).

Prerequisites:

- You must be an administrator.

NOTE:
Compute usage visualizations are not available, but an [epic](https://gitlab.com/groups/gitlab-com/gl-infra/gitlab-dedicated/-/epics/524) exists to add them for general availability.

To view hosted runners in GitLab:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **CI/CD > Runners**.
1. Optional. Select **Fleet dashboard**.

#### Configure hosted runners in GitLab

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

## Security and Network

Hosted runners for GitLab Dedicated have built-in layers that harden the security of the GitLab Runner build environment.

Hosted runners for GitLab Dedicated have the following configurations:

- Firewall rules allow only outbound communication from the ephemeral VM to the public internet.
- Firewall rules do not allow inbound communication from the public internet to the ephemeral VM.
- Firewall rules do not allow communication between VMs.
- Only the runner manager can communicate with the ephemeral VMs.
- Ephemeral runner VMs only serve a single job and are deleted after the job execution.

You can also [enable private connections](#outbound-private-link) from hosted runners to your AWS account.

For more information, see the architecture diagram for [hosted runners for GitLab Dedicated](architecture.md#hosted-runners-for-gitlab-dedicated).

### Outbound private link

Outbound private link creates a secure connection between hosted runners for GitLab Dedicated and services in your AWS VPC.
This connection doesn't expose any traffic to the public internet and allows hosted runners to:

- Access private services, such as custom secrets managers.
- Retrieve artifacts or job images stored in your infrastructure.
- Deploy to your infrastructure.

Two outbound private links exist by default for all runners in the GitLab-managed runner account:

- A link to your GitLab instance
- A link to a GitLab-controlled Prometheus instance

These links are pre-configured and cannot be modified. The tenant's Prometheus instance is managed by GitLab and is not accessible to users.

To use an outbound private link with other VPC services, manual configuration is required. For more information, see [Outbound private link](configure_instance/network_security.md#outbound-private-link).

### IP ranges

IP ranges for hosted runners for GitLab Dedicated are available upon request. IP ranges are maintained on a best-effort basis and may change at any time due to changes in the infrastructure. For more information, reach out to your Customer Success Manager or Account representative.

## Use hosted runners

After you [create hosted runners in Switchboard](#create-hosted-runners-in-switchboard) and the runners are ready, you can use them.

To use runners, adjust the [tags](../../ci/yaml/_index.md#tags) in your job configuration in the `.gitlab-ci.yml` file to match the hosted
runner you want to use.

For the Linux medium x86-64 runner, configure your job like this:

   ```yaml
   job_name:
     tags:
       - linux-medium-amd64  # Use the medium-sized Linux runner
   ```

By default, untagged jobs are picked up by the small Linux x86-64 runner.
GitLab administrators can [configure instance runners in GitLab](#configure-hosted-runners-in-gitlab) to not run untagged jobs.

To migrate jobs without changing job configurations, [modify the hosted runner tags](#configure-hosted-runners-in-gitlab)
to match the tags used in your existing job configurations.

If you see your job is stuck with the error message `no runners that match all of the job's tags`:

1. Verify if you've selected the correct tag
1. Confirm if [instance runners are enabled for your project or group](../../ci/runners/runners_scope.md#enable-instance-runners-for-a-project).

## Upgrades

Runner version upgrades require a short downtime.
Runners are upgraded during the scheduled maintenance windows of a GitLab Dedicated tenant.
An [issue](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/issues/4505) exists to implement zero downtime upgrades.

## Pricing

For pricing details, reach out to your account representative.

We offer a 30-day free trial for GitLab Dedicated customers. The trial includes:

- Small, Medium, and Large Linux x86-64 runners
- Small and Medium Linux Arm runners
- Limited autoscaling configuration that supports up to 100 concurrent jobs
