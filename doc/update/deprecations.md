---
stage: none
group: none
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
---

# Deprecated features

DISCLAIMER:
This page contains information related to upcoming products, features, and functionality.
It is important to note that the information presented is for informational purposes only.
Please do not rely on this information for purchasing or planning purposes.
As with all projects, the items mentioned on this page are subject to change or delay.
The development, release, and timing of any products, features, or functionality remain at the
sole discretion of GitLab Inc.

<!-- vale off -->

<!--
DO NOT EDIT THIS PAGE DIRECTLY

This page is automatically generated from the YAML files in `/data/deprecations` by the rake task
located at `lib/tasks/gitlab/docs/compile_deprecations.rake`.

For deprecation authors (usually Product Managers and Engineering Managers):

- To add a deprecation, use the example.yml file in `/data/deprecations/templates` as a template.
- For more information about authoring deprecations, check the the deprecation item guidance:
  https://about.gitlab.com/handbook/marketing/blog/release-posts/#creating-a-deprecation-entry

For deprecation reviewers (Technical Writers only):

- To update the deprecation doc, run: `bin/rake gitlab:docs:compile_deprecations`
- To verify the deprecations doc is up to date, run: `bin/rake gitlab:docs:check_deprecations`
- For more information about updating the deprecation doc, see the deprecation doc update guidance:
  https://about.gitlab.com/handbook/marketing/blog/release-posts/#update-the-deprecations-doc
-->

## 14.5

### Rename Task Runner pod to Toolbox

The Task Runner pod is used to execute periodic housekeeping tasks within the GitLab application and is often confused with the GitLab Runner. Thus, [Task Runner will be renamed to Toolbox](https://gitlab.com/groups/gitlab-org/charts/-/epics/25).

This will result in the rename of the sub-chart: `gitlab/task-runner` to `gitlab/toolbox`. Resulting pods will be named along the lines of `{{ .Release.Name }}-toolbox`, which will often be `gitlab-toolbox`. They will be locatable with the label `app=toolbox`.

Announced: 2021-08-22
Planned removal: 2021-11-22

## 14.6

### Release CLI distributed as a generic package

The [release-cli](https://gitlab.com/gitlab-org/release-cli) will be released as a [generic package](https://gitlab.com/gitlab-org/release-cli/-/packages) starting in GitLab 14.2. We will continue to deploy it as a binary to S3 until GitLab 14.5 and stop distributing it in S3 in GitLab 14.6.

Announced: 2021-08-22
Planned removal: 2021-12-22

## 14.8

### openSUSE Leap 15.2 packages

Distribution support and security updates for openSUSE Leap 15.2 are [ending December 2021](https://en.opensuse.org/Lifetime#openSUSE_Leap).

Starting in 14.5 we are providing packages for openSUSE Leap 15.3, and will stop providing packages for openSUSE Leap 15.2 in the 14.8 milestone.

Announced: 2021-11-22
Planned removal: 2022-02-22

## 15.0

### API: `stale` status returned instead of `offline` or `not_connected`

A breaking change will occur for the Runner [API](https://docs.gitlab.com/ee/api/runners.html#runners-api) endpoints in 15.0.

Instead of the GitLab Runner API endpoints returning `offline` and `not_connected` for runners that have not contacted the GitLab instance in the past three months, the API endpoints will return the `stale` value, which was introduced in 14.6.

Announced: 2021-12-22
Planned removal: 2022-05-22

### Audit events for repository push events

Audit events for [repository events](https://docs.gitlab.com/ee/administration/audit_events.html#repository-push) are now deprecated and will be removed in GitLab 15.0.

These events have always been disabled by default and had to be manually enabled with a
feature flag. Enabling them can cause too many events to be generated which can
dramatically slow down GitLab instances. For this reason, they are being removed.

Announced: 2021-09-22
Planned removal: 2022-05-22

### CI/CD job name length limit

In GitLab 15.0 we are going to limit the number of characters in CI/CD job names to 255. Any pipeline with job names that exceed the 255 character limit will stop working after the 15.0 release.

Announced: 2021-12-22
Planned removal: 2022-05-22

### Certificate-based integration with Kubernetes

[We are deprecating the certificate-based integration with Kubernetes](https://about.gitlab.com/blog/2021/11/15/deprecating-the-cert-based-kubernetes-integration/).
The timeline of removal of the integration from the product is not yet planned and we will communicate
more details as they emerge. The certificate-based integration will continue to receive security and
critical fixes, and features built on the integration will continue to work with supported Kubernetes
versions. We will provide migration plans in a future iteration. See [the list of features affected by this deprecation](https://docs.gitlab.com/ee/user/infrastructure/clusters/#deprecated-features).
For updates and details, follow this [epic](https://gitlab.com/groups/gitlab-org/configure/-/epics/8).

For a more robust, secure, forthcoming, and reliable integration with Kubernetes, we recommend the use of the
[Kubernetes Agent](https://docs.gitlab.com/ee/user/clusters/agent/) to connect Kubernetes clusters with GitLab.

Announced: 2021-11-15
Planned removal: 2022-05-22

### Converting an instance (shared) runner to a project (specific) runner is deprecated

In GitLab 15.0, we will remove the feature that enables you to convert an instance (shared) runner to a project (specific) runner. Users who need to add a runner to only a particular project can register a runner to the project directly.

Announced: 2021-11-22
Planned removal: 2022-05-22

### Deprecate `Versions` on base `PackageType`

As part of the work to create a [Package Registry GraphQL API](https://gitlab.com/groups/gitlab-org/-/epics/6318), the Package group deprecated the `Version` type for the basic `PackageType` type and moved it to [`PackageDetailsType`](https://docs.gitlab.com/ee/api/graphql/reference/index.html#packagedetailstype).

In milestone 15.0, we will completely remove `Version` from `PackageType`.

Announced: 2021-11-22
Planned removal: 2022-05-22

### Deprecate `pipelines` fields in the Package GraphQL types

As part of the work to create a [Package Registry GraphQL API](https://gitlab.com/groups/gitlab-org/-/epics/6318), the Package group deprecated the `pipelines` fields in all Package-related GraphQL types. As of GitLab 14.6, the `pipelines` field is deprecated in [`Package`](https://docs.gitlab.com/ee/api/graphql/reference/index.html#package) and [`PackageDetailsType`](https://docs.gitlab.com/ee/api/graphql/reference/index.html#packagedetailstype) due to scalability and performance concerns.

In milestone 15.0, we will completely remove `pipelines` from `Package` and `PackageDetailsType`. You can follow and contribute to work on a replacement in the epic [GitLab-#7214](https://gitlab.com/groups/gitlab-org/-/epics/7214).

Announced: 2021-12-22
Planned removal: 2022-05-22

### Deprecate legacy approval status names from License Compliance API

We deprecated legacy names for approval status of license policy (blacklisted, approved) in the `managed_licenses` API but they are still used in our API queries and responses. They will be removed in 15.0.

If you are using our License Compliance API you should stop using the `approved` and `blacklisted` query parameters, they are now `allowed` and `denied`. In 15.0 the responses will also stop using `approved` and `blacklisted` so you need to adjust any of your custom tools to use the old and new values so they do not break with the 15.0 release.

Announced: 2021-12-22
Planned removal: 2022-05-22

### Deprecate support for SLES 12 SP2

Long term service and support (LTSS) for SUSE Linux Enterprise Server (SLES) 12 SP2 [ended on March 31, 2021](https://www.suse.com/lifecycle/). The CA certificates on SP2 include the expired DST root certificate, and it's not getting new CA certificate package updates. We have implemented some [workarounds](https://gitlab.com/gitlab-org/gitlab-omnibus-builder/-/merge_requests/191), but we will not be able to continue to keep the build running properly.

Announced: 2021-11-22
Planned removal: 2022-05-22

### Deprecation of Runner status `not_connected` API value

The GitLab Runner REST and GraphQL [API](https://docs.gitlab.com/ee/api/runners.html#runners-api) endpoints
will return `never_contacted` instead of `not_connected` as the status values in 15.0.

Runners that have never contacted the GitLab instance will also return `stale` if created more than 3 months ago.

Announced: 2021-12-22
Planned removal: 2022-05-22

### Deprecation of bundler-audit Dependency Scanning tool

As of 14.6 bundler-audit is being deprecated from Dependency Scanning. It will continue to be in our CI/CD template while deprecated. We are removing bundler-audit from Dependency Scanning on May 22, 2022 in 15.0. After this removal Ruby scanning functionality will not be affected as it is still being covered by Gemnasium.

If you have explicitly excluded bundler-audit using DS_EXCLUDED_ANALYZERS you will need to clean up (remove the reference) in 15.0. If you have customized your pipeline's Dependency Scanning configuration, for example to edit the `bundler-audit-dependency_scanning` job, you will want to switch to gemnasium-dependency_scanning before removal in 15.0, to prevent your pipeline from failing. If you have not used the DS_EXCLUDED_ANALYZERS to reference bundler-audit, or customized your template specifically for bundler-audit, you will not need to take action.

Announced: 2021-12-22
Planned removal: 2022-05-22

### GitLab Serverless

[GitLab Serverless](https://docs.gitlab.com/ee/user/project/clusters/serverless/) is a feature set to support Knative-based serverless development with automatic deployments and monitoring.

We decided to remove the GitLab Serverless features as they never really resonated with our users. Besides, given the continuous development of Kubernetes and Knative, our current implementations do not even work with recent versions.

Announced: 2021-09-22
Planned removal: 2022-05-22

### Known host required for GitLab Runner SSH executor

In [GitLab 14.3](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3074), we added a configuration setting in the GitLab Runner `config.toml` file. This setting, [`[runners.ssh.disable_strict_host_key_checking]`](https://docs.gitlab.com/runner/executors/ssh.html#security), controls whether or not to use strict host key checking with the SSH executor.

In GitLab 15.0 and later, the default value for this configuration option will change from `true` to `false`. This means that strict host key checking will be enforced when using the GitLab Runner SSH executor.

Announced: 2021-11-22
Planned removal: 2022-05-22

### Legacy database configuration

The syntax of [GitLabs database](https://docs.gitlab.com/omnibus/settings/database.html)
configuration located in `database.yml` is changing and the legacy format is deprecated. The legacy format
supported using a single PostgreSQL adapter, whereas the new format is changing to support multiple databases. The `main:` database needs to be defined as a first configuration item.

This deprecation mainly impacts users compiling GitLab from source because Omnibus will handle this configuration automatically.

Announced: 2021-09-22
Planned removal: 2022-05-22

### Must explicitly assign `AuthenticationType` for `[runners.cache.s3]`

In GitLab 15.0 and later, to access the AWS S3 cache, you must specify the `AuthenticationType` for [`[runners.cache.s3]`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnerscaches3-section). The `AuthenticationType` must be `IAM` or `credentials`.

Prior to 14.5, if you did not define the `AuthenticationType`, GitLab Runner chose a type for you.

Announced: 2021-11-22
Planned removal: 2022-05-22

### NFS for Git repository storage deprecated

With the general availability of Gitaly Cluster ([introduced in GitLab 13.0](https://about.gitlab.com/releases/2020/05/22/gitlab-13-0-released/)), we have deprecated development (bugfixes, performance improvements, etc) for NFS for Git repository storage in GitLab 14.0. We will continue to provide technical support for NFS for Git repositories throughout 14.x, but we will remove all support for NFS in GitLab 15.0. Please see our official [Statement of Support](https://about.gitlab.com/support/statement-of-support.html#gitaly-and-nfs) for further information.

Gitaly Cluster offers tremendous benefits for our customers such as:

- [Variable replication factors](https://docs.gitlab.com/ee/administration/gitaly/index.html#replication-factor).
- [Strong consistency](https://docs.gitlab.com/ee/administration/gitaly/index.html#strong-consistency).
- [Distributed read capabilities](https://docs.gitlab.com/ee/administration/gitaly/index.html#distributed-reads).

We encourage customers currently using NFS for Git repositories to plan their migration by reviewing our documentation on [migrating to Gitaly Cluster](https://docs.gitlab.com/ee/administration/gitaly/index.html#migrate-to-gitaly-cluster).

Announced: 2021-06-22
Planned removal: 2022-05-22

### OmniAuth Kerberos gem

The `omniauth-kerberos` gem will be removed in our next major release, GitLab 15.0.

This gem has not been maintained and has very little usage. We therefore plan to remove support for this authentication method and recommend using the Kerberos [SPNEGO](https://en.wikipedia.org/wiki/SPNEGO) integration instead. You can follow the [upgrade instructions](https://docs.gitlab.com/ee/integration/kerberos.html#upgrading-from-password-based-to-ticket-based-kerberos-sign-ins) to upgrade from the `omniauth-kerberos` integration to the supported one.

Note that we are not deprecating the Kerberos SPNEGO integration, only the old password-based Kerberos integration.

Announced: 2021-09-22
Planned removal: 2022-05-22

### Package pipelines in API payload is paginated

A request to the API for `/api/v4/projects/:id/packages` returns a paginated result of packages. Each package lists all of its pipelines in this response. This is a performance concern, as it's possible for a package to have hundreds or thousands of associated pipelines.

In milestone 15.0, we will remove the `pipelines` attribute from the API response.

Announced: 2021-11-22
Planned removal: 2022-05-22

### Pseudonymizer

The Pseudonymizer feature is generally unused,
can cause production issues with large databases,
and can interfere with object storage development.
It is now considered deprecated, and will be removed in GitLab 15.0.

Announced: 2021-01-22
Planned removal: 2021-06-22

### REST API Runner will not contain `paused`

The GitLab Runner REST and GraphQL API endpoints will not return `paused` or `active` as a status in GitLab 15.0.

A runner's status will only relate to runner contact status, such as:
`online`, `offline`, or `not_connected`. Status `paused` or `active` will no longer appear.

When checking if a runner is `paused`, API users are advised to check the boolean attribute
`active` to be `false` instead. When checking if a runner is `active`, check if `active` is `true`.

Announced: 2021-11-22
Planned removal: 2022-05-22

### Removal of `defaultMergeCommitMessageWithDescription` GraphQL API field

The GraphQL API field `defaultMergeCommitMessageWithDescription` has been deprecated and will be removed in GitLab 15.0. For projects with a commit message template set, it will ignore the template.

Announced: 2021-11-22
Planned removal: 2022-05-22

### Removal of `promote-db` command from `gitlab-ctl`

In GitLab 14.5, we introduced the command `gitlab-ctl promote` to promote any Geo secondary node to a primary during a failover. This command replaces `gitlab-ctl promote-db` which is used to promote database nodes in multi-node Geo secondary sites. `gitlab-ctl promote-db` will continue to function as-is and be available until GitLab 15.0. We recommend that Geo customers begin testing the new `gitlab-ctl promote` command in their staging environments and incorporating the new command in their failover procedures.

Announced: 2021-11-22
Planned removal: 2022-05-22

### Removal of `promote-to-primary-node` command from `gitlab-ctl`

In GitLab 14.5, we introduced the command `gitlab-ctl promote` to promote any Geo secondary node to a primary during a failover. This command replaces `gitlab-ctl promote-to-primary-node` which was only usable for single-node Geo sites. `gitlab-ctl promote-to-primary-node` will continue to function as-is and be available until GitLab 15.0. We recommend that Geo customers begin testing the new `gitlab-ctl promote` command in their staging environments and incorporating the new command in their failover procedures.

Announced: 2021-11-22
Planned removal: 2022-05-22

### Remove `type` and `types` keyword in CI/CD configuration

The `type` and `types` CI/CD keywords will be removed in GitLab 15.0. Pipelines that use these keywords will stop working, so you must switch to `stage` and `stages`, which have the same behavior.

Announced: 2021-12-22
Planned removal: 2022-05-22

### Remove the `:dependency_proxy_for_private_groups` feature flag

We added a feature flag because [GitLab-#11582](https://gitlab.com/gitlab-org/gitlab/-/issues/11582) changed how public groups use the Dependency Proxy. Prior to this change, you could use the Dependency Proxy without authentication. The change requires authentication to use the Dependency Proxy.

In milestone 15.0, we will remove the feature flag entirely. Moving forward, you must authenticate when using the Dependency Proxy.

Announced: 2021-11-22
Planned removal: 2022-05-22

### Remove the `pipelines` field from the `version` field

In GraphQL, there are two `pipelines` fields that you can use in a [`PackageDetailsType`](https://docs.gitlab.com/ee/api/graphql/reference/#packagedetailstype) to get the pipelines for package versions:

- The `versions` field's `pipelines` field. This returns all the pipelines associated with all the package's versions, which can pull an unbounded number of objects in memory and create performance concerns.
- The `pipelines` field of a specific `version`. This returns only the pipelines associated with that single package version.

To mitigate possible performance problems, we will remove the `versions` field's `pipelines` field in milestone 15.0. Although you will no longer be able to get all pipelines for all versions of a package, you can still get the pipelines of a single version through the remaining `pipelines` field for that version.

Announced: 2021-11-22
Planned removal: 2022-05-22

### Update to the Container Registry group-level API

In milestone 15.0, support for the `tags` and `tags_count` parameters will be removed from the Container Registry API that [gets registry repositories from a group](../api/container_registry.md#within-a-group).

The `GET /groups/:id/registry/repositories` endpoint will remain, but won't return any info about tags. To get the info about tags, you can use the existing `GET /registry/repositories/:id` endpoint, which will continue to support the `tags` and `tag_count` options as it does today. The latter must be called once per image repository.

Announced: 2021-11-22
Planned removal: 2022-05-22

### Value Stream Analytics filtering calculation change

We are changing how the date filter works in Value Stream Analytics. Instead of filtering by the time that the issue or merge request was created, the date filter will filter by the end event time of the given stage. This will result in completely different figures after this change has rolled out.

If you monitor Value Stream Analytics metrics and rely on the date filter, to avoid losing data, you must save the data prior to this change.

Announced: 2021-11-22
Planned removal: 2022-05-22

### apiFuzzingCiConfigurationCreate GraphQL mutation

The API Fuzzing configuration snippet is now being generated client-side and does not require an
API request anymore. We are therefore deprecating the `apiFuzzingCiConfigurationCreate` mutation
which isn't being used in GitLab anymore.

Announced: 2021-12-22
Planned removal: 2022-05-22
