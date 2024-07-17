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

Upgrading GitLab is a relatively straightforward process, but the complexity
can increase based on the installation method you have used, how old your
GitLab version is, if you're upgrading to a major version, and so on.

Make sure to read the whole page as it contains information related to every upgrade method.

The [maintenance policy documentation](../policy/maintenance.md)
has additional information about upgrading, including:

- How to interpret GitLab product versioning.
- Recommendations on what release to run.
- How we use patch and security patch releases.
- When we backport code changes.

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
from the chart version to GitLab version to determine the [upgrade path](#upgrade-paths).

Follow [Multi-node upgrades with downtime](with_downtime.md) to perform the upgrade in a Cloud Native Hybrid setup.

A full cloud-native deployment is [not supported](../administration/reference_architectures/index.md#stateful-components-in-kubernetes)
for production. However, instructions on how to upgrade such an environment are in
[a separate document](https://docs.gitlab.com/charts/installation/upgrade.html).

:::TabTitle Docker

GitLab provides official Docker images for both Community and Enterprise
editions, and they are based on the Omnibus package. See how to
[install GitLab using Docker](../install/docker.md).

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

## Plan your upgrade

See the guide to [plan your GitLab upgrade](plan_your_upgrade.md).

## Check for background migrations before upgrading

Certain releases may require different migrations to be
finished before you upgrade to the newer version.

For more information, see [background migrations](background_migrations.md).

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

## Checking for pending advanced search migrations

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

This section is only applicable if you have enabled the [Elasticsearch integration](../integration/advanced_search/elasticsearch.md).
Major releases require all [advanced search migrations](../integration/advanced_search/elasticsearch.md#advanced-search-migrations)
to be finished from the most recent minor release in your current version
before the major version upgrade. You can find pending migrations by
running the following command.

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
sudo gitlab-rake gitlab:elastic:list_pending_migrations
```

:::TabTitle Self-compiled (source)

```shell
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:elastic:list_pending_migrations
```

::EndTabs

### What do you do if your advanced search migrations are stuck?

In GitLab 15.0, an advanced search migration named `DeleteOrphanedCommit` can be permanently stuck
in a pending state across upgrades. This issue
[is corrected in GitLab 15.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89539).

If you are a self-managed customer who uses GitLab 15.0 with advanced search, you will experience performance degradation.
To clean up the migration, upgrade to 15.1 or later.

For other advanced search migrations stuck in pending, see [how to retry a halted migration](../integration/advanced_search/elasticsearch.md#retry-a-halted-migration).

If you upgrade GitLab before all pending advanced search migrations are completed, any pending migrations
that have been removed in the new version cannot be executed or retried.
In this case, you must
[re-create your index from scratch](../integration/advanced_search/elasticsearch_troubleshooting.md#last-resort-to-recreate-an-index).

### What do you do for the error `Elasticsearch version not compatible`

Confirm that your version of Elasticsearch or OpenSearch is [compatible with your version of GitLab](../integration/advanced_search/elasticsearch.md#version-requirements).

## Upgrading without downtime

Read how to [upgrade without downtime](zero_downtime.md).

## Upgrading to a new major version

Upgrading the *major* version requires more attention.
Backward-incompatible changes are reserved for major versions.
Follow the directions carefully as we
cannot guarantee that upgrading between major versions is seamless.

A *major* upgrade requires the following steps:

1. Identify a [supported upgrade path](#upgrade-paths). The last minor release of the previous major version is always a required stop due to the background migrations being introduced in the last minor version.
1. Ensure that any [background migrations have been fully completed](background_migrations.md)
   before upgrading to a new major version.
1. If you have enabled the [Elasticsearch integration](../integration/advanced_search/elasticsearch.md), then
   before proceeding with the major version upgrade, [ensure that all advanced search migrations are completed](#checking-for-pending-advanced-search-migrations).
1. If your GitLab instance has any runners associated with it, it is very
   important to upgrade them to match the current GitLab version. This ensures
   [compatibility with GitLab versions](https://docs.gitlab.com/runner/#gitlab-runner-versions).

## Upgrade paths

Upgrading across multiple GitLab versions in one go is *only possible by accepting downtime*.
If you don't want any downtime, read how to [upgrade with zero downtime](zero_downtime.md).

Upgrade paths include required upgrade stops, which are versions of GitLab that you must upgrade to before upgrading to
later versions. When moving through an upgrade path:

1. Upgrade to the required upgrade stop after your current version.
1. Allow the background migrations for the upgrade to finish.
1. Upgrade to the next required upgrade stop.

From GitLab 17.5, required upgrade stops consistently land on minor versions X.2, X.5, X.8, and X.11. This schedule provides a predictable upgrade schedule for instance administrators.

To determine your upgrade path:

1. Note where in the upgrade path your current version sits, including required upgrade stops:

   - GitLab 15 includes the following required upgrade stops:
     - [`15.0.5`](versions/gitlab_15_changes.md#1500).
     - [`15.1.6`](versions/gitlab_15_changes.md#1510). GitLab instances with multiple web nodes.
     - [`15.4.6`](versions/gitlab_15_changes.md#1540).
     - [`15.11.13`](versions/gitlab_15_changes.md#15110). The latest GitLab 15.11 release.
   - GitLab 16 includes the following required upgrade stops:
     - [`16.0.8`](versions/gitlab_16_changes.md#1600). Instances with
       [lots of users](versions/gitlab_16_changes.md#long-running-user-type-data-change) or
       [large pipeline variables history](versions/gitlab_16_changes.md#1610).
     - [`16.1.6`](versions/gitlab_16_changes.md#1610). Instances with NPM packages in their package registry.
     - [`16.2.9`](versions/gitlab_16_changes.md#1620). Instances with [large pipeline variables history](versions/gitlab_16_changes.md#1630).
     - [`16.3.7`](versions/gitlab_16_changes.md#1630).
     - [`16.7.z`](versions/gitlab_16_changes.md#1670). The latest GitLab 16.7 release.
     - [`16.11.z`](https://gitlab.com/gitlab-org/gitlab/-/releases). The latest GitLab 16.11 release.
   - GitLab 17: [`17.y.z`](versions/gitlab_17_changes.md). The latest GitLab 17 release.

1. Consult the [version-specific upgrade instructions](#version-specific-upgrading-instructions).

Even when not explicitly specified, upgrade GitLab to the latest available patch release of the `major`.`minor` release
rather than the first patch release. For example, `16.8.7` instead of `16.8.0`.

This includes `major`.`minor` versions you must stop at on the upgrade path because there may
be fixes for issues relating to the upgrade process.

Specifically around a [major version](#upgrading-to-a-new-major-version),
crucial database schema and migration patches may be included in the latest patch releases.

### Upgrade Path tool

To quickly calculate which upgrade stops are required based on your current and desired target GitLab version, see the
[Upgrade Path tool](https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/). This tool is
maintained by the [GitLab Support team](https://handbook.gitlab.com/handbook/support/#about-the-support-team).

To share feedback and help improve the tool, create an issue or merge request in the [upgrade-path project](https://gitlab.com/gitlab-com/support/toolbox/upgrade-path).

### Earlier GitLab versions

For information on upgrading to earlier GitLab versions, see the [documentation archives](https://archives.docs.gitlab.com).
The versions of the documentation in the archives contain version-specific information for even earlier versions of GitLab.

For example, the [documentation for GitLab 15.11](https://archives.docs.gitlab.com/15.11/ee/update/#upgrade-paths)
contains information on versions back to GitLab 12.

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
- [Docker CE to EE](../install/docker.md#convert-community-edition-to-enterprise-edition) -
  Follow this guide to upgrade your GitLab Community Edition container to an Enterprise Edition container.
- [Helm chart (Kubernetes) CE to EE](https://docs.gitlab.com/charts/installation/deployment.html#convert-community-edition-to-enterprise-edition) -
  Follow this guide to upgrade your GitLab Community Edition Helm deployment to Enterprise Edition.

### Enterprise to Community Edition

To downgrade your Enterprise Edition installation back to Community
Edition, you can follow [this guide](../downgrade_ee_to_ce/index.md) to make the process as smooth as
possible.

## Version-specific upgrading instructions

Each month, major or minor as well as possibly patch releases of GitLab are published along with a
[release post](https://about.gitlab.com/releases/categories/releases/).
You should read the release posts for all versions you're passing over.
At the end of major and minor release posts, there are three sections to look for specifically:

- Deprecations
- Removals
- Important notes on upgrading

These include:

- Steps you must perform as part of an upgrade.
  For example [8.12](https://about.gitlab.com/releases/2016/09/22/gitlab-8-12-released/#upgrade-barometer)
  required the Elasticsearch index to be recreated. Any older version of GitLab upgrading to 8.12 or later would require this.
- Changes to the versions of software we support such as
  [ceasing support for IE11 in GitLab 13](https://about.gitlab.com/releases/2020/03/22/gitlab-12-9-released/#ending-support-for-internet-explorer-11).

Apart from the instructions in this section, you should also check the
installation-specific upgrade instructions, based on how you installed GitLab:

- [Linux packages (Omnibus GitLab)](../update/package/index.md#version-specific-changes)
- [Helm charts](https://docs.gitlab.com/charts/installation/upgrade.html)

NOTE:
Specific information that follow related to Ruby and Git versions do not apply to [Omnibus installations](https://docs.gitlab.com/omnibus/)
and [Helm Chart deployments](https://docs.gitlab.com/charts/). They come with appropriate Ruby and Git versions and are not using system binaries for Ruby and Git. There is no need to install Ruby or Git when utilizing these two approaches.

### GitLab 17

Before upgrading to GitLab 17, see [GitLab 17 changes](versions/gitlab_17_changes.md).

### GitLab 16

Before upgrading to GitLab 16, see [GitLab 16 changes](versions/gitlab_16_changes.md).

### GitLab 15

Before upgrading to GitLab 15, see [GitLab 15 changes](versions/gitlab_15_changes.md).

## Miscellaneous

- [Managing PostgreSQL extensions](../install/postgresql_extensions.md)
