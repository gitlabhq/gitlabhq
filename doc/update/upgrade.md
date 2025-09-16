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
1. Perform [pre-upgrade checks](#pre-upgrade-and-post-upgrade-checks).
1. Pause [running CI/CD pipelines and jobs](#cicd-pipelines-and-jobs-during-upgrades).
1. If relevant, follow [upgrade steps for additional features](#upgrade-steps-for-additional-features).
1. Follow the [upgrade steps based on your installation method](#upgrade-based-on-installation-method).
1. If your GitLab instance has any runners associated with it, upgrade them to match the current GitLab version.
   This step ensures [compatibility with GitLab versions](https://docs.gitlab.com/runner/#gitlab-runner-versions).
1. If you encounter problems with the upgrade, [get support](#getting-support).
1. [Disable maintenance mode](../administration/maintenance_mode/_index.md#disable-maintenance-mode) if you had enabled
   it.
1. Unpause [running CI/CD pipelines and jobs](#cicd-pipelines-and-jobs-during-upgrades).
1. Perform [post-upgrade checks](#pre-upgrade-and-post-upgrade-checks).

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

## Pre-upgrade and post-upgrade checks

Immediately before and after the upgrade, perform the pre-upgrade and post-upgrade checks
to ensure the major components of GitLab are working:

1. [Check the general configuration](../administration/raketasks/maintenance.md#check-gitlab-configuration):

   ```shell
   sudo gitlab-rake gitlab:check
   ```

1. [Check the status of all background database migrations](background_migrations.md).

1. Confirm that encrypted database values [can be decrypted](../administration/raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets):

   ```shell
   sudo gitlab-rake gitlab:doctor:secrets
   ```

1. In GitLab UI, check that:
   - Users can sign in.
   - The project list is visible.
   - Project issues and merge requests are accessible.
   - Users can clone repositories from GitLab.
   - Users can push commits to GitLab.

1. For GitLab CI/CD, check that:
   - Runners pick up jobs.
   - Docker images can be pushed and pulled from the registry.

1. If using Geo, run the relevant checks on the primary and each secondary:

   ```shell
   sudo gitlab-rake gitlab:geo:check
   ```

1. If using Elasticsearch, verify that searches are successful.

If something goes wrong, [get support](#getting-support).

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

## Upgrade steps for additional features

Some GitLab features have additional steps.

### External Gitaly

Upgrade Gitaly servers to the newer version before upgrading the application server. This prevents the gRPC client
on the application server from sending RPCs that the old Gitaly version does not support.

### Geo

If you're using Geo:

- Review [Geo upgrade documentation](../administration/geo/replication/upgrading_the_geo_sites.md).
- Review Geo-specific information in the [GitLab upgrade notes](versions/_index.md).
- Review Geo-specific steps when [upgrading the database](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance).
- Create an upgrade and rollback plan for each Geo site (primary and each secondary).

### GitLab agent for Kubernetes

If you have Kubernetes clusters connected with GitLab, [upgrade your GitLab agents for Kubernetes](../user/clusters/agent/install/_index.md#update-the-agent-version) to match your new GitLab version.

### Advanced search (Elasticsearch)

Before updating GitLab, confirm advanced search migrations are complete by
[checking for pending migrations](background_migrations.md#check-for-pending-advanced-search-migrations).

After updating GitLab, you may have to upgrade
[Elasticsearch if the new version breaks compatibility](../integration/advanced_search/elasticsearch.md#version-requirements).
Updating Elasticsearch is **out of scope for GitLab Support**.

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
