---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Use hosted runners to run your CI/CD jobs on GitLab Dedicated.
title: Hosted runners for GitLab Dedicated
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

> [!note]
> To use this feature, contact your customer success manager or account representative.

Hosted runners for GitLab Dedicated are [GitLab-hosted runners](../../ci/runners/_index.md) that are managed by GitLab and fully integrated with your GitLab Dedicated instance.
Hosted runners are autoscaling [instance runners](../../ci/runners/runners_scope.md#instance-runners),
running on AWS EC2 in the same region as your instance.

Key benefits include:

- Provisioning, patching, scaling, and monitoring managed by GitLab
- Single-tenant runners with the same data residency as your GitLab Dedicated instance
- Ephemeral runners destroyed after each job, with a secure network connection through outbound PrivateLink
- Automatic scaling for consistent performance during peak periods
- 99.9% uptime SLA backed by a highly available runner architecture
- GitLab Credits consumption tracked on the GitLab Credits dashboard
- Pay only for what you use through GitLab Credits

<i class="fa-vimeo" aria-hidden="true"></i>
For an overview, see [demo: hosted runners for GitLab Dedicated](https://player.vimeo.com/video/1219640416).
<!-- Video published on 2026-08-24 -->

When you use hosted runners:

- Each job runs in a newly provisioned virtual machine (VM), which is dedicated to the specific job.
- The VM where your job runs has `sudo` access with no password.
- The storage is shared by the operating system, the image with pre-installed software, and a copy of your cloned repository. This means that the available free disk space for your jobs is reduced.
- By default, untagged jobs run on the small Linux x86-64 runner. GitLab administrators can [change the run untagged jobs option in GitLab](#configure-hosted-runners-in-gitlab).

## Hosted runners on Linux

Hosted runners on Linux for GitLab Dedicated use the [Docker Autoscaler](https://docs.gitlab.com/runner/executors/docker_autoscaler/) executor. Each job gets a Docker environment in a fully isolated, ephemeral virtual machine (VM), and runs on the latest version of Docker Engine.

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

> [!note]
> The machine type and underlying processor type might change. Jobs optimized for a specific processor design might behave inconsistently.

Default runner tags are assigned upon creation. Administrators can subsequently [modify the tag settings](#configure-hosted-runners-in-gitlab) for their instance runners.

### Container images

As runners on Linux are using the [Docker Autoscaler](https://docs.gitlab.com/runner/executors/docker_autoscaler/) executor, you can choose any container image by defining the image in your `.gitlab-ci.yml` file. Make sure that the selected Docker image is compatible with the underlying processor architecture. See the [example `.gitlab-ci.yml` file](../../ci/runners/hosted_runners/linux.md#example-gitlab-ciyml-file).

If no image is set, the default is `ruby:3.1`.

If you use images from the Docker Hub container registry, you might run into [rate limits](../settings/user_and_ip_rate_limits.md). This is because GitLab Dedicated uses a single Network Address Translation (NAT) IP address.

To avoid rate limits, instead use:

- Images stored in the [GitLab container registry](../../user/packages/container_registry/_index.md).
- Images stored in other public registries with no rate limits.
- The [dependency proxy](../../user/packages/dependency_proxy/_index.md), acting as a pull-through cache.

### Docker in Docker support

The runners are configured to run in `privileged` mode to support [Docker in Docker](../../ci/docker/using_docker_build.md#use-docker-in-docker) to build Docker images natively or run multiple containers within your isolated job.

## Plan runner stack concurrency

Each production runner stack supports up to 1,000 concurrently running jobs. The limit applies
to running jobs, not submitted jobs. When a stack reaches the limit, any additional jobs stay
queued until capacity becomes available.

To send jobs to a specific stack, use that stack's runner tag. If you expect more than 1,000 jobs
to run at the same time, use runner tags to distribute jobs across multiple stacks.

For service level agreement (SLA) calculations, a job that takes more than 5 minutes to start is
not counted as a slow job if the stack was already running 1,000 jobs when the job entered the
pending state.

## Manage hosted runners

You can create and view hosted runners in Switchboard, and view and configure them in GitLab. You can also disable hosted runners for specific projects or groups.

### Manage hosted runners in Switchboard

You can create and view hosted runners for your GitLab Dedicated instance using Switchboard.

Prerequisites:

- Your customer success manager or account representative has enabled hosted runners for your instance.

#### Create hosted runners in Switchboard

For each instance, you can create one runner of each type and size combination. Switchboard displays the available runner options.

To create hosted runners:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com).
1. In the left sidebar, select **Hosted runners**.
1. Select **New hosted runner**.
1. Choose a size for the runner, then select **Create hosted runner**.

You will receive an email notification when your hosted runner is ready to use.

[Outbound PrivateLink connections](#outbound-privatelink-connections) configured for existing runners don't apply to new runners. A separate request is required for each new runner.

#### View hosted runners in Switchboard

To view hosted runners:

1. Sign in to [Switchboard](https://console.gitlab-dedicated.com).
1. In the left sidebar, select **Hosted runners**.
1. Optional. From the list of hosted runners, copy the **Runner ID** of the runner you want to access in GitLab.

### View and configure hosted runners in GitLab

GitLab administrators can manage hosted runners for their GitLab Dedicated instance from the [**Admin** area](../admin_area.md#administering-runners).

#### View hosted runners in GitLab

You can view hosted runners for your GitLab Dedicated instance in the Runners page and in the [Fleet dashboard](../../ci/runners/runner_fleet_dashboard.md).

Prerequisites:

- You must be an administrator.

> [!note]
> Compute usage visualizations are not available, but an [epic](https://gitlab.com/groups/gitlab-com/gl-infra/gitlab-dedicated/-/work_items/524) exists to add them for general availability.

To view hosted runners in GitLab:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **CI/CD** > **Runners**.
1. Optional. Select **Fleet dashboard**.

#### Configure hosted runners in GitLab

Prerequisites:

- You must be an administrator.

You can configure hosted runners for your GitLab Dedicated instance, including changing the default values for the runner tags.

Available configuration options include:

- [Change the maximum job timeout](../../ci/runners/configure_runners.md#for-an-instance-runner).
- [Set the runner to run tagged or untagged jobs](../../ci/runners/configure_runners.md#for-an-instance-runner-2).

> [!note]
> Any changes to the runner description and the runner tags are not controlled by GitLab.

### Disable hosted runners for groups or projects in GitLab

By default, hosted runners are available for all projects and groups in your GitLab Dedicated instance.
GitLab maintainers can disable hosted runners for a [project](../../ci/runners/runners_scope.md#disable-instance-runners-for-a-project) or a [group](../../ci/runners/runners_scope.md#disable-instance-runners-for-a-group).

## Security and Network

Hosted runners for GitLab Dedicated have built-in layers that harden the security of the GitLab Runner build environment:

- Firewall rules allow only outbound communication from the ephemeral VM to the public internet.
- Firewall rules do not allow inbound communication from the public internet to the ephemeral VM.
- Firewall rules do not allow communication between VMs.
- Only the runner manager can communicate with the ephemeral VMs.
- Ephemeral runner VMs only serve a single job and are deleted after the job execution.
- Runners are single-tenant and are not shared with other GitLab Dedicated instances.

You can also [enable PrivateLink connections](#outbound-privatelink-connections) from hosted runners to your AWS account.

For more information, see the architecture diagram for [hosted runners for GitLab Dedicated](architecture.md#hosted-runners-for-gitlab-dedicated).

### Outbound PrivateLink connections

Outbound PrivateLink connections create a secure connection between hosted runners for GitLab Dedicated and services in your AWS VPC.
This connection doesn't expose any traffic to the public internet and allows hosted runners to:

- Access private services, such as custom secrets managers.
- Retrieve artifacts or job images stored in your infrastructure.
- Deploy to your infrastructure.

Two outbound PrivateLink connections exist by default for all runners in the GitLab-managed runner account:

- A connection to your GitLab instance
- A connection to a GitLab-controlled Prometheus instance

These connections are pre-configured and cannot be modified. The tenant's Prometheus instance is managed by GitLab and is not accessible to users.

To use an outbound PrivateLink connection with other VPC services for hosted runners,
[manual configuration is required with a support request](configure_instance/network_security.md#configure-outbound-privatelink-connections-with-a-support-request).

### Inbound and outbound connections

Inbound connections to hosted runners for GitLab Dedicated from the public internet or other untrusted sources are blocked.
The runner manager is the only exception, and can communicate with the ephemeral VMs.

Outbound connections are open by default. To block specific IP addresses or ranges, submit a [support ticket](https://support.gitlab.com/)
with the details of the range you want blocked. GitLab maintains this deny list on a best-effort basis. For more
information, reach out to your customer success manager or account representative.

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

## Service level agreement

Hosted runners for GitLab Dedicated are backed by a 99.9% uptime SLA, supported by a
highly available (HA) runner architecture. GitLab calculates the hosted runners SLA separately from the GitLab
Dedicated instance SLA, so downtime for hosted runners does not count as downtime for the GitLab Dedicated instance.
For the full definition, including the availability measure, valid job population, excluded minutes, and Service
Credits, see the [hosted runners for GitLab Dedicated SLA definition](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/service-level-agreement/#hosted-runners-for-gitlab-dedicated-service-level-agreement---availability-definition).

## Usage and monitoring

> [!note]
> Hosted runners for GitLab Dedicated keep running jobs after you deplete your Monthly Commitment Pool of GitLab
> Credits, so your CI/CD pipelines are not interrupted, provided you have accepted the usage billing terms.

If you're at risk of overage, monitor your usage on the GitLab Credits dashboard and do one of the following:

- Purchase a larger monthly credit commitment.
- Accept the overage and continue running jobs on on-demand credits.
- Point your CI/CD jobs to different self-hosted runners.

To track GitLab Credits consumption for hosted runners, see the
[GitLab Credits dashboard](../../subscriptions/gitlab_credits.md).
For compute usage, see [compute usage for GitLab-hosted runners on GitLab Dedicated](../../ci/pipelines/dedicated_hosted_runner_compute_minutes.md).

### Usage cap exemptions

Hosted runners for GitLab Dedicated are exempt from usage caps because interrupting them would break a critical part of your workflow.
A subscription or per-user cap does not stop CI/CD jobs from running. Jobs continue after the Monthly Commitment Pool is depleted, drawing On-Demand credits in the usual order.
Because caps do not apply, you can't use cap-based controls to limit this spend. Monitor consumption in the GitLab Credits dashboard instead.

## Pricing

For pricing details, reach out to your account representative.
