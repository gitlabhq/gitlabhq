---
stage: Systems
group: Distribution
description: Latest version instructions.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Upgrade GitLab

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

Upgrading GitLab is a relatively straightforward process, but the complexity can increase based on:

- The installation method you have used.
- How old your GitLab version is.
- If you're upgrading to a major version.

Make sure to read the whole page as it contains information related to every upgrade method.

To upgrade GitLab:

1. Familiarize yourself with the [maintenance policy documentation](../policy/maintenance.md).
1. Read the [release posts](https://about.gitlab.com/releases/categories/releases/) for versions you're passing over.
   In particular, deprecations, removals, and important notes on upgrading.
1. Check for [background migrations](background_migrations.md).
1. [Plan your upgrade](plan_your_upgrade.md).
1. Consult changes for different versions of GitLab to ensure compatibility before upgrading:
   - [GitLab 17 changes](versions/gitlab_17_changes.md)
   - [GitLab 16 changes](versions/gitlab_16_changes.md)
   - [GitLab 15 changes](versions/gitlab_15_changes.md)
1. Follow the [upgrade steps based on your installation method](#upgrade-based-on-installation-method).

## Upgrade based on installation method

Depending on the installation method and your GitLab version, there are multiple
official ways to upgrade GitLab:

::Tabs

:::TabTitle Linux packages (Omnibus)

The [package upgrade guide](package/index.md)
contains the steps needed to upgrade a package installed by official GitLab
repositories.

There are also instructions when you want to
[upgrade to a specific version](package/index.md#upgrade-to-a-specific-version-using-the-official-repositories).

:::TabTitle Helm chart (Kubernetes)

GitLab can be deployed into a Kubernetes cluster using Helm. For production deployments,
the setup follows the [Cloud Native Hybrid](../administration/reference_architectures/index.md#cloud-native-hybrid)
guidance where stateless components of cloud-native GitLab run in Kubernetes with
the GitLab Helm chart, and stateful components are deployed in compute VMs with the
Linux package.

Use the [version mapping](https://docs.gitlab.com/charts/installation/version_mappings.html)
from the chart version to GitLab version to determine the [upgrade path](upgrade_paths.md).

Follow [Multi-node upgrades with downtime](with_downtime.md) to perform the upgrade in a Cloud Native Hybrid setup.

A full cloud-native deployment is [not supported](../administration/reference_architectures/index.md#stateful-components-in-kubernetes)
for production. However, instructions on how to upgrade such an environment are in
[a separate document](https://docs.gitlab.com/charts/installation/upgrade.html).

:::TabTitle Docker

GitLab provides official Docker images for both Community and Enterprise
editions, and they are based on the Omnibus package. See how to
[install GitLab using Docker](../install/docker/index.md).

:::TabTitle Self-compiled (source)

- [Upgrading Community Edition and Enterprise Edition from source](upgrading_from_source.md) -
  The guidelines for upgrading Community Edition and Enterprise Edition from source.
- [Patch versions](patch_versions.md) guide includes the steps needed for a
  patch version, such as 15.2.0 to 15.2.1, and apply to both Community and Enterprise
  Editions.

In the past we used separate documents for the upgrading instructions, but we
have switched to using a single document. The old upgrading guidelines
can still be found in the Git repository:

- [Old upgrading guidelines for Community Edition](https://gitlab.com/gitlab-org/gitlab-foss/tree/11-8-stable/doc/update)
- [Old upgrading guidelines for Enterprise Edition](https://gitlab.com/gitlab-org/gitlab/-/tree/11-8-stable-ee/doc/update)

::EndTabs

## Dealing with running CI/CD pipelines and jobs

If you upgrade your GitLab instance while the GitLab Runner is processing jobs, the trace updates fail. When GitLab is back online, the trace updates should self-heal. However, depending on the error, the GitLab Runner either retries, or eventually terminates, job handling.

As for the artifacts, the GitLab Runner attempts to upload them three times, after which the job eventually fails.

To address the above two scenarios, it is advised to do the following prior to upgrading:

1. Plan your maintenance.
1. Pause your runners, or block new jobs from starting by adding the following to your `/etc/gitlab/gitlab.rb`:

   ```ruby
   nginx['custom_gitlab_server_config'] = "location ^~ /api/v4/jobs/request {\n deny all;\n return 503;\n}\n"
   ```

   And reconfigure GitLab with:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Wait until all jobs are finished.
1. Upgrade GitLab.
1. [Upgrade GitLab Runner](https://docs.gitlab.com/runner/install/index.html) to the same version
   as your GitLab version. Both versions [should be the same](https://docs.gitlab.com/runner/#gitlab-runner-versions).
1. Unpause your runners and unblock new jobs from starting by reverting the previous `/etc/gitlab/gitlab.rb` change.

## Upgrading between editions

GitLab comes in two flavors: [Community Edition](https://about.gitlab.com/features/#community) which is MIT licensed,
and [Enterprise Edition](https://about.gitlab.com/features/#enterprise) which builds on top of the Community Edition and
includes extra features mainly aimed at organizations with more than 100 users.

Below you can find some guides to help you change GitLab editions.

### Community to Enterprise Edition

NOTE:
The following guides are for subscribers of the Enterprise Edition only.

If you wish to upgrade your GitLab installation from Community to Enterprise
Edition, follow the guides below based on the installation method:

- [Source CE to EE upgrade guides](upgrading_from_ce_to_ee.md) - The steps are very similar
  to a version upgrade: stop the server, get the code, update configuration files for
  the new functionality, install libraries and do migrations, update the init
  script, start the application and check its status.
- [Omnibus CE to EE](package/convert_to_ee.md) - Follow this guide to upgrade your Omnibus
  GitLab Community Edition to the Enterprise Edition.
- [Docker CE to EE](../install/docker/upgrade.md#convert-community-edition-to-enterprise-edition) -
  Follow this guide to upgrade your GitLab Community Edition container to an Enterprise Edition container.
- [Helm chart (Kubernetes) CE to EE](https://docs.gitlab.com/charts/installation/deployment.html#convert-community-edition-to-enterprise-edition) -
  Follow this guide to upgrade your GitLab Community Edition Helm deployment to Enterprise Edition.

### Enterprise to Community Edition

To downgrade your Enterprise Edition installation back to Community
Edition, you can follow [this guide](../downgrade_ee_to_ce/index.md) to make the process as smooth as
possible.

## Related topics

- [Managing PostgreSQL extensions](../install/postgresql_extensions.md)
