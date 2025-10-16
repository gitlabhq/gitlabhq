---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Upgrade a GitLab instance
description: Upgrade steps for all installation methods.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Upgrade a GitLab instance to take advantage of new features and bug fixes.

Before you upgrade, consult [information you need before you upgrade](plan_your_upgrade.md).

## Upgrade GitLab

To upgrade GitLab:

1. If available in your starting version, consider [turning on maintenance mode](../administration/maintenance_mode/_index.md)
   during the upgrade.
1. Pause [running CI/CD pipelines and jobs](#cicd-pipelines-and-jobs-during-upgrades).
1. Follow the [upgrade steps based on your installation method](#upgrade-based-on-installation-method).
1. If your GitLab instance has any runners associated with it, upgrade them to match the current GitLab version.
   This step ensures [compatibility with GitLab versions](https://docs.gitlab.com/runner/#gitlab-runner-versions).
1. [Disable maintenance mode](../administration/maintenance_mode/_index.md#disable-maintenance-mode) if you had enabled
   it.
1. Unpause [running CI/CD pipelines and jobs](#cicd-pipelines-and-jobs-during-upgrades).
1. Run [upgrade health checks](plan_your_upgrade.md#run-upgrade-health-checks).

## Upgrade based on installation method

Depending on the installation method and your GitLab version, there are multiple
official ways to upgrade GitLab:

{{< tabs >}}

{{< tab title="Linux packages (Omnibus)" >}}

As part of a GitLab upgrade, the [Linux package upgrade guide](package/_index.md) contains the specific steps to follow
to upgrade a Linux package instance.

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

GitLab can be deployed into a Kubernetes cluster using Helm. For production deployments,
the setup follows the [Cloud Native Hybrid](../administration/reference_architectures/_index.md#cloud-native-hybrid)
guidance where stateless components of cloud-native GitLab run in Kubernetes with
the GitLab Helm chart, and stateful components are deployed in compute VMs with the
Linux package.

Use the [version mapping](https://docs.gitlab.com/charts/installation/version_mappings.html)
from the chart version to GitLab version to determine the [upgrade path](upgrade_paths.md).

Follow [Multi-node upgrades with downtime](with_downtime.md) to perform the upgrade in a Cloud Native Hybrid setup.

A full cloud-native deployment is [not supported](../administration/reference_architectures/_index.md#stateful-components-in-kubernetes)
for production. However, instructions on how to upgrade such an environment are in
[a separate document](https://docs.gitlab.com/charts/installation/upgrade.html).

{{< /tab >}}

{{< tab title="Docker" >}}

GitLab provides official Docker images for both Community and Enterprise
editions, and they are based on the Linux package. See how to
[install GitLab using Docker](../install/docker/_index.md).

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

- [Upgrading Community Edition and Enterprise Edition from source](upgrading_from_source.md):
  The guidelines for upgrading Community Edition and Enterprise Edition from source.
- [Patch versions](patch_versions.md) guide includes the steps needed for a
  patch version, such as 15.2.0 to 15.2.1, and apply to both Community and Enterprise
  Editions.

In the past we used separate documents for the upgrading instructions, but we
have switched to using a single document. The old upgrading guidelines
can still be found in the Git repository:

- [Old upgrading guidelines for Community Edition](https://gitlab.com/gitlab-org/gitlab-foss/tree/11-8-stable/doc/update)
- [Old upgrading guidelines for Enterprise Edition](https://gitlab.com/gitlab-org/gitlab/-/tree/11-8-stable-ee/doc/update)

{{< /tab >}}

{{< /tabs >}}

## CI/CD pipelines and jobs during upgrades

If you upgrade your GitLab instance while the GitLab Runner is processing jobs, the trace updates fail. When GitLab is back online, the trace updates should self-heal. However, depending on the error, the GitLab Runner either retries, or eventually terminates, job handling.

As for the artifacts, the GitLab Runner attempts to upload them three times, after which the job eventually fails.

To address the two previous scenarios, it is advised to do the following prior to upgrading:

1. Plan your maintenance.
1. Pause your runners, or block new jobs from starting by adding the following to your `/etc/gitlab/gitlab.rb`:

   ```ruby
   nginx['custom_gitlab_server_config'] = "location = /api/v4/jobs/request {\n deny all;\n return 503;\n}\n"
   ```

   And reconfigure GitLab with:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Wait until all jobs are finished.
1. Upgrade GitLab.
1. [Upgrade GitLab Runner](https://docs.gitlab.com/runner/install/) to the same version
   as your GitLab version. Both versions [should be the same](https://docs.gitlab.com/runner/#gitlab-runner-versions).
1. Unpause your runners and unblock new jobs from starting by reverting the previous `/etc/gitlab/gitlab.rb` change.

## Upgrading between editions

GitLab comes in two flavors: [Community Edition](https://about.gitlab.com/features/#community) which is MIT licensed,
and [Enterprise Edition](https://about.gitlab.com/features/#enterprise) which builds on top of the Community Edition and
includes extra features mainly aimed at organizations with more than 100 users.

In the following section you can find some guides to help you change GitLab editions.

## Getting support

If something goes wrong:

- Copy any errors and gather any logs to later analyze, and then [roll back to the last working version](plan_your_upgrade.md#rollback-plan).
  You can use the following tools to help you gather data:
  - [`gitlabsos`](https://gitlab.com/gitlab-com/support/toolbox/gitlabsos) if
    you installed GitLab using the Linux package or Docker.
  - [`kubesos`](https://gitlab.com/gitlab-com/support/toolbox/kubesos/) if
    you installed GitLab using the Helm Charts.

For support:

- [Contact GitLab Support](https://support.gitlab.com/hc/en-us) and, if you have one, your Customer Success Manager.
- If [the situation qualifies](https://about.gitlab.com/support/#definitions-of-support-impact) and
  [your plan includes emergency support](https://about.gitlab.com/support/#priority-support),
  create an emergency ticket.

## Related topics

- [Managing PostgreSQL extensions](../install/postgresql_extensions.md)
