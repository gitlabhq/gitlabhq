---
stage: none
group: none
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
---

# Deprecations by milestone

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

## 14.0

### NFS for Git repository storage

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

With the general availability of Gitaly Cluster ([introduced in GitLab 13.0](https://about.gitlab.com/releases/2020/05/22/gitlab-13-0-released/)), we have deprecated development (bugfixes, performance improvements, etc) for NFS for Git repository storage in GitLab 14.0. We will continue to provide technical support for NFS for Git repositories throughout 14.x, but we will remove all support for NFS in GitLab 15.0. Please see our official [Statement of Support](https://about.gitlab.com/support/statement-of-support.html#gitaly-and-nfs) for further information.

Gitaly Cluster offers tremendous benefits for our customers such as:

- [Variable replication factors](https://docs.gitlab.com/ee/administration/gitaly/index.html#replication-factor).
- [Strong consistency](https://docs.gitlab.com/ee/administration/gitaly/index.html#strong-consistency).
- [Distributed read capabilities](https://docs.gitlab.com/ee/administration/gitaly/index.html#distributed-reads).

We encourage customers currently using NFS for Git repositories to plan their migration by reviewing our documentation on [migrating to Gitaly Cluster](https://docs.gitlab.com/ee/administration/gitaly/index.html#migrate-to-gitaly-cluster).

**Planned removal milestone: 15.0 (2022-05-22)**

### OAuth implicit grant

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

The OAuth implicit grant authorization flow will be removed in our next major release, GitLab 15.0. Any applications that use OAuth implicit grant should switch to alternative [supported OAuth flows](https://docs.gitlab.com/ee/api/oauth2.html).

**Planned removal milestone: 15.0 (2022-05-22)**

## 14.2

### Release CLI distributed as a generic package

The [release-cli](https://gitlab.com/gitlab-org/release-cli) will be released as a [generic package](https://gitlab.com/gitlab-org/release-cli/-/packages) starting in GitLab 14.2. We will continue to deploy it as a binary to S3 until GitLab 14.5 and stop distributing it in S3 in GitLab 14.6.

**Planned removal milestone: 14.6 (2021-12-22)**

### Rename Task Runner pod to Toolbox

The Task Runner pod is used to execute periodic housekeeping tasks within the GitLab application and is often confused with the GitLab Runner. Thus, [Task Runner will be renamed to Toolbox](https://gitlab.com/groups/gitlab-org/charts/-/epics/25).

This will result in the rename of the sub-chart: `gitlab/task-runner` to `gitlab/toolbox`. Resulting pods will be named along the lines of `{{ .Release.Name }}-toolbox`, which will often be `gitlab-toolbox`. They will be locatable with the label `app=toolbox`.

**Planned removal milestone: 14.5 (2021-11-22)**

## 14.3

### Audit events for repository push events

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

Audit events for [repository events](https://docs.gitlab.com/ee/administration/audit_events.html#repository-push) are now deprecated and will be removed in GitLab 15.0.

These events have always been disabled by default and had to be manually enabled with a
feature flag. Enabling them can cause too many events to be generated which can
dramatically slow down GitLab instances. For this reason, they are being removed.

**Planned removal milestone: 15.0 (2022-05-22)**

### GitLab Serverless

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

[GitLab Serverless](https://docs.gitlab.com/ee/user/project/clusters/serverless/) is a feature set to support Knative-based serverless development with automatic deployments and monitoring.

We decided to remove the GitLab Serverless features as they never really resonated with our users. Besides, given the continuous development of Kubernetes and Knative, our current implementations do not even work with recent versions.

**Planned removal milestone: 15.0 (2022-05-22)**

### Legacy database configuration

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

The syntax of [GitLabs database](https://docs.gitlab.com/omnibus/settings/database.html)
configuration located in `database.yml` is changing and the legacy format is deprecated. The legacy format
supported using a single PostgreSQL adapter, whereas the new format is changing to support multiple databases. The `main:` database needs to be defined as a first configuration item.

This deprecation mainly impacts users compiling GitLab from source because Omnibus will handle this configuration automatically.

**Planned removal milestone: 15.0 (2022-05-22)**

### OmniAuth Kerberos gem

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

The `omniauth-kerberos` gem will be removed in our next major release, GitLab 15.0.

This gem has not been maintained and has very little usage. We therefore plan to remove support for this authentication method and recommend using the Kerberos [SPNEGO](https://en.wikipedia.org/wiki/SPNEGO) integration instead. You can follow the [upgrade instructions](https://docs.gitlab.com/ee/integration/kerberos.html#upgrading-from-password-based-to-ticket-based-kerberos-sign-ins) to upgrade from the `omniauth-kerberos` integration to the supported one.

Note that we are not deprecating the Kerberos SPNEGO integration, only the old password-based Kerberos integration.

**Planned removal milestone: 15.0 (2022-05-22)**

## 14.5

### Certificate-based integration with Kubernetes

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

[We are deprecating the certificate-based integration with Kubernetes](https://about.gitlab.com/blog/2021/11/15/deprecating-the-cert-based-kubernetes-integration/).
The timeline of removal of the integration from the product is not yet planned and we will communicate
more details as they emerge. The certificate-based integration will continue to receive security and
critical fixes, and features built on the integration will continue to work with supported Kubernetes
versions. We will provide migration plans in a future iteration. See [the list of features affected by this deprecation](https://docs.gitlab.com/ee/user/infrastructure/clusters/#deprecated-features).
For updates and details, follow this [epic](https://gitlab.com/groups/gitlab-org/configure/-/epics/8).

For a more robust, secure, forthcoming, and reliable integration with Kubernetes, we recommend the use of the
[Kubernetes Agent](https://docs.gitlab.com/ee/user/clusters/agent/) to connect Kubernetes clusters with GitLab.

**Planned removal milestone: 15.0 (2022-05-22)**

### Converting an instance (shared) runner to a project (specific) runner

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In GitLab 15.0, we will remove the feature that enables you to convert an instance (shared) runner to a project (specific) runner. Users who need to add a runner to only a particular project can register a runner to the project directly.

**Planned removal milestone: 15.0 (2022-05-22)**

### Known host required for GitLab Runner SSH executor

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In [GitLab 14.3](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3074), we added a configuration setting in the GitLab Runner `config.toml` file. This setting, [`[runners.ssh.disable_strict_host_key_checking]`](https://docs.gitlab.com/runner/executors/ssh.html#security), controls whether or not to use strict host key checking with the SSH executor.

In GitLab 15.0 and later, the default value for this configuration option will change from `true` to `false`. This means that strict host key checking will be enforced when using the GitLab Runner SSH executor.

**Planned removal milestone: 15.0 (2022-05-22)**

### Must explicitly assign `AuthenticationType` for `[runners.cache.s3]`

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In GitLab 15.0 and later, to access the AWS S3 cache, you must specify the `AuthenticationType` for [`[runners.cache.s3]`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnerscaches3-section). The `AuthenticationType` must be `IAM` or `credentials`.

Prior to 14.5, if you did not define the `AuthenticationType`, GitLab Runner chose a type for you.

**Planned removal milestone: 15.0 (2022-05-22)**

### Package pipelines in API payload is paginated

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

A request to the API for `/api/v4/projects/:id/packages` returns a paginated result of packages. Each package lists all of its pipelines in this response. This is a performance concern, as it's possible for a package to have hundreds or thousands of associated pipelines.

In milestone 15.0, we will remove the `pipelines` attribute from the API response.

**Planned removal milestone: 15.0 (2022-05-22)**

### REST API Runner will not contain `paused`

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

The GitLab Runner REST and GraphQL API endpoints will not return `paused` or `active` as a status in GitLab 15.0.

A runner's status will only relate to runner contact status, such as:
`online`, `offline`, or `not_connected`. Status `paused` or `active` will no longer appear.

When checking if a runner is `paused`, API users are advised to check the boolean attribute
`active` to be `false` instead. When checking if a runner is `active`, check if `active` is `true`.

**Planned removal milestone: 15.0 (2022-05-22)**

### Support for SLES 12 SP2

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

Long term service and support (LTSS) for SUSE Linux Enterprise Server (SLES) 12 SP2 [ended on March 31, 2021](https://www.suse.com/lifecycle/). The CA certificates on SP2 include the expired DST root certificate, and it's not getting new CA certificate package updates. We have implemented some [workarounds](https://gitlab.com/gitlab-org/gitlab-omnibus-builder/-/merge_requests/191), but we will not be able to continue to keep the build running properly.

**Planned removal milestone: 15.0 (2022-05-22)**

### Update to the Container Registry group-level API

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In milestone 15.0, support for the `tags` and `tags_count` parameters will be removed from the Container Registry API that [gets registry repositories from a group](../api/container_registry.md#within-a-group).

The `GET /groups/:id/registry/repositories` endpoint will remain, but won't return any info about tags. To get the info about tags, you can use the existing `GET /registry/repositories/:id` endpoint, which will continue to support the `tags` and `tag_count` options as it does today. The latter must be called once per image repository.

**Planned removal milestone: 15.0 (2022-05-22)**

### Value Stream Analytics filtering calculation change

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

We are changing how the date filter works in Value Stream Analytics. Instead of filtering by the time that the issue or merge request was created, the date filter will filter by the end event time of the given stage. This will result in completely different figures after this change has rolled out.

If you monitor Value Stream Analytics metrics and rely on the date filter, to avoid losing data, you must save the data prior to this change.

**Planned removal milestone: 15.0 (2022-05-22)**

### `Versions` on base `PackageType`

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

As part of the work to create a [Package Registry GraphQL API](https://gitlab.com/groups/gitlab-org/-/epics/6318), the Package group deprecated the `Version` type for the basic `PackageType` type and moved it to [`PackageDetailsType`](https://docs.gitlab.com/ee/api/graphql/reference/index.html#packagedetailstype).

In milestone 15.0, we will completely remove `Version` from `PackageType`.

**Planned removal milestone: 15.0 (2022-05-22)**

### `defaultMergeCommitMessageWithDescription` GraphQL API field

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

The GraphQL API field `defaultMergeCommitMessageWithDescription` has been deprecated and will be removed in GitLab 15.0. For projects with a commit message template set, it will ignore the template.

**Planned removal milestone: 15.0 (2022-05-22)**

### `dependency_proxy_for_private_groups` feature flag

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

We added a feature flag because [GitLab-#11582](https://gitlab.com/gitlab-org/gitlab/-/issues/11582) changed how public groups use the Dependency Proxy. Prior to this change, you could use the Dependency Proxy without authentication. The change requires authentication to use the Dependency Proxy.

In milestone 15.0, we will remove the feature flag entirely. Moving forward, you must authenticate when using the Dependency Proxy.

**Planned removal milestone: 15.0 (2022-05-22)**

### `pipelines` field from the `version` field

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In GraphQL, there are two `pipelines` fields that you can use in a [`PackageDetailsType`](https://docs.gitlab.com/ee/api/graphql/reference/#packagedetailstype) to get the pipelines for package versions:

- The `versions` field's `pipelines` field. This returns all the pipelines associated with all the package's versions, which can pull an unbounded number of objects in memory and create performance concerns.
- The `pipelines` field of a specific `version`. This returns only the pipelines associated with that single package version.

To mitigate possible performance problems, we will remove the `versions` field's `pipelines` field in milestone 15.0. Although you will no longer be able to get all pipelines for all versions of a package, you can still get the pipelines of a single version through the remaining `pipelines` field for that version.

**Planned removal milestone: 15.0 (2022-05-22)**

### `promote-db` command from `gitlab-ctl`

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In GitLab 14.5, we introduced the command `gitlab-ctl promote` to promote any Geo secondary node to a primary during a failover. This command replaces `gitlab-ctl promote-db` which is used to promote database nodes in multi-node Geo secondary sites. `gitlab-ctl promote-db` will continue to function as-is and be available until GitLab 15.0. We recommend that Geo customers begin testing the new `gitlab-ctl promote` command in their staging environments and incorporating the new command in their failover procedures.

**Planned removal milestone: 15.0 (2022-05-22)**

### `promote-to-primary-node` command from `gitlab-ctl`

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In GitLab 14.5, we introduced the command `gitlab-ctl promote` to promote any Geo secondary node to a primary during a failover. This command replaces `gitlab-ctl promote-to-primary-node` which was only usable for single-node Geo sites. `gitlab-ctl promote-to-primary-node` will continue to function as-is and be available until GitLab 15.0. We recommend that Geo customers begin testing the new `gitlab-ctl promote` command in their staging environments and incorporating the new command in their failover procedures.

**Planned removal milestone: 15.0 (2022-05-22)**

### openSUSE Leap 15.2 packages

Distribution support and security updates for openSUSE Leap 15.2 are [ending December 2021](https://en.opensuse.org/Lifetime#openSUSE_Leap).

Starting in 14.5 we are providing packages for openSUSE Leap 15.3, and will stop providing packages for openSUSE Leap 15.2 in the 14.8 milestone.

**Planned removal milestone: 14.8 (2022-02-22)**

## 14.6

### API: `stale` status returned instead of `offline` or `not_connected`

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

A breaking change will occur for the Runner [API](https://docs.gitlab.com/ee/api/runners.html#runners-api) endpoints in 15.0.

Instead of the GitLab Runner API endpoints returning `offline` and `not_connected` for runners that have not contacted the GitLab instance in the past three months, the API endpoints will return the `stale` value, which was introduced in 14.6.

**Planned removal milestone: 15.0 (2022-05-22)**

### CI/CD job name length limit

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In GitLab 15.0 we are going to limit the number of characters in CI/CD job names to 255. Any pipeline with job names that exceed the 255 character limit will stop working after the 15.0 release.

**Planned removal milestone: 15.0 (2022-05-22)**

### Legacy approval status names from License Compliance API

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

We deprecated legacy names for approval status of license policy (blacklisted, approved) in the `managed_licenses` API but they are still used in our API queries and responses. They will be removed in 15.0.

If you are using our License Compliance API you should stop using the `approved` and `blacklisted` query parameters, they are now `allowed` and `denied`. In 15.0 the responses will also stop using `approved` and `blacklisted` so you need to adjust any of your custom tools to use the old and new values so they do not break with the 15.0 release.

**Planned removal milestone: 15.0 (2022-05-22)**

### Runner status `not_connected` API value

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

The GitLab Runner REST and GraphQL [API](https://docs.gitlab.com/ee/api/runners.html#runners-api) endpoints
will return `never_contacted` instead of `not_connected` as the status values in 15.0.

Runners that have never contacted the GitLab instance will also return `stale` if created more than 3 months ago.

**Planned removal milestone: 15.0 (2022-05-22)**

### `pipelines` fields in the Package GraphQL types

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

As part of the work to create a [Package Registry GraphQL API](https://gitlab.com/groups/gitlab-org/-/epics/6318), the Package group deprecated the `pipelines` fields in all Package-related GraphQL types. As of GitLab 14.6, the `pipelines` field is deprecated in [`Package`](https://docs.gitlab.com/ee/api/graphql/reference/index.html#package) and [`PackageDetailsType`](https://docs.gitlab.com/ee/api/graphql/reference/index.html#packagedetailstype) due to scalability and performance concerns.

In milestone 15.0, we will completely remove `pipelines` from `Package` and `PackageDetailsType`. You can follow and contribute to work on a replacement in the epic [GitLab-#7214](https://gitlab.com/groups/gitlab-org/-/epics/7214).

**Planned removal milestone: 15.0 (2022-05-22)**

### `type` and `types` keyword in CI/CD configuration

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

The `type` and `types` CI/CD keywords will be removed in GitLab 15.0. Pipelines that use these keywords will stop working, so you must switch to `stage` and `stages`, which have the same behavior.

**Planned removal milestone: 15.0 (2022-05-22)**

### apiFuzzingCiConfigurationCreate GraphQL mutation

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

The API Fuzzing configuration snippet is now being generated client-side and does not require an
API request anymore. We are therefore deprecating the `apiFuzzingCiConfigurationCreate` mutation
which isn't being used in GitLab anymore.

**Planned removal milestone: 15.0 (2022-05-22)**

### bundler-audit Dependency Scanning tool

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

As of 14.6 bundler-audit is being deprecated from Dependency Scanning. It will continue to be in our CI/CD template while deprecated. We are removing bundler-audit from Dependency Scanning on May 22, 2022 in 15.0. After this removal Ruby scanning functionality will not be affected as it is still being covered by Gemnasium.

If you have explicitly excluded bundler-audit using DS_EXCLUDED_ANALYZERS you will need to clean up (remove the reference) in 15.0. If you have customized your pipeline's Dependency Scanning configuration, for example to edit the `bundler-audit-dependency_scanning` job, you will want to switch to gemnasium-dependency_scanning before removal in 15.0, to prevent your pipeline from failing. If you have not used the DS_EXCLUDED_ANALYZERS to reference bundler-audit, or customized your template specifically for bundler-audit, you will not need to take action.

**Planned removal milestone: 15.0 (2022-05-22)**

## 14.7

### Container scanning schemas below 14.0.0

[Container scanning report schemas](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/releases)
versions earlier than 14.0.0 will no longer be supported in GitLab 15.0. Reports that do not pass validation
against the schema version declared in the report will also no longer be supported in GitLab 15.0.

Third-party tools that [integrate with GitLab by outputting a container scanning security report](https://docs.gitlab.com/ee/development/integrations/secure.html#report)
as a pipeline job artifact are affected. You must ensure that all output reports adhere to the correct schema with a minimum version of 14.0.0. Reports with a lower version or that fail to validate against the declared schema version will not be processed, and vulnerability findings will not display in MRs, pipelines, or Vulnerability Reports.

To help with the transition, from GitLab 14.10, non-compliant reports will display a
[warning](https://gitlab.com/gitlab-org/gitlab/-/issues/335789#note_672853791)
in the Vulnerability Report.

**Planned removal milestone: 15.0 (2022-05-22)**

### Coverage guided fuzzing schemas below 14.0.0

[Coverage guided fuzzing report schemas](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/releases)
below version 14.0.0 will no longer be supported in GitLab 15.0. Reports that do not pass validation
against the schema version declared in the report will also no longer be supported in GitLab 15.0.

Third-party tools that [integrate with GitLab by outputting a coverage guided fuzzing security report](https://docs.gitlab.com/ee/development/integrations/secure.html#report)
as a pipeline job artifact are affected. You must ensure that all output reports adhere to the correct
schema with a minimum version of 14.0.0. Any reports with a lower version or that fail to validate
against the declared schema version will not be processed, and vulnerability
findings will not display in MRs, pipelines, or Vulnerability Reports.

To help with the transition, from GitLab 14.10, non-compliant reports will display a
[warning](https://gitlab.com/gitlab-org/gitlab/-/issues/335789#note_672853791)
in the Vulnerability Report.

**Planned removal milestone: 15.0 (2022-05-22)**

### DAST schemas below 14.0.0

[DAST report schemas](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/releases)
versions earlier than 14.0.0 will no longer be supported in GitLab 15.0. Reports that do not pass validation
against the schema version declared in the report will also no longer be supported as of GitLab 15.0.

Third-party tools that [integrate with GitLab by outputting a DAST security report](https://docs.gitlab.com/ee/development/integrations/secure.html#report)
as a pipeline job artifact are affected. You must ensure that all output reports adhere to the correct
schema with a minimum version of 14.0.0. Reports with a lower version or that fail to validate
against the declared schema version will not be processed, and vulnerability
findings will not display in MRs, pipelines, or Vulnerability Reports.

To help with the transition, from GitLab 14.10, non-compliant reports will cause a
[warning to be displayed](https://gitlab.com/gitlab-org/gitlab/-/issues/335789#note_672853791)
in the Vulnerability Report.

**Planned removal milestone: 15.0 (2022-05-22)**

### Dependency scanning schemas below 14.0.0

[Dependency scanning report schemas](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/releases)
versions earlier than 14.0.0 will no longer be supported in GitLab 15.0. Reports that do not pass validation
against the schema version declared in the report will also no longer be supported as of GitLab 15.0.

Third-party tools that [integrate with GitLab by outputting a Dependency scanning security report](https://docs.gitlab.com/ee/development/integrations/secure.html#report)
as a pipeline job artifact are affected. You must ensure that all output reports adhere to the correct
schema with a minimum version of 14.0.0. Reports with a lower version or that fail to validate
against the declared schema version will not be processed, and vulnerability
findings will not display in MRs, pipelines, or Vulnerability Reports.

To help with the transition, from GitLab 14.10, non-compliant reports will cause a
[warning to be displayed](https://gitlab.com/gitlab-org/gitlab/-/issues/335789#note_672853791)
in the Vulnerability Report.

**Planned removal milestone: 15.0 (2022-05-22)**

### Enforced validation of security report schemas

[Security report schemas](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/releases)
versions earlier than 14.0.0 will no longer be supported in GitLab 15.0. Reports that do not pass validation
against the schema version declared in the report will also no longer be supported in GitLab 15.0.

Security tools that [integrate with GitLab by outputting security reports](https://docs.gitlab.com/ee/development/integrations/secure.html#report)
as pipeline job artifacts are affected. You must ensure that all output reports adhere to the correct
schema with a minimum version of 14.0.0. Reports with a lower version or that fail to validate
against the declared schema version will not be processed, and vulnerability
findings will not display in MRs, pipelines, or Vulnerability Reports.

To help with the transition, from GitLab 14.10, non-compliant reports will display a
[warning](https://gitlab.com/gitlab-org/gitlab/-/issues/335789#note_672853791)
in the Vulnerability Report.

**Planned removal milestone: 15.0 (2022-05-22)**

### Godep support in License Compliance

The Godep dependency manager for Golang was deprecated in 2020 by Go and
has been replaced with Go modules.
To reduce our maintenance cost we are deprecating License Compliance for Godep projects as of 14.7
and will remove it in GitLab 15.0

**Planned removal milestone: 15.0 (2022-05-22)**

### Logging in GitLab

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

The logging features in GitLab allow users to install the ELK stack (Elasticsearch, Logstash, and Kibana) to aggregate and manage application logs. Users can search for relevant logs in GitLab. However, since deprecating certificate-based integration with Kubernetes clusters and GitLab Managed Apps, we don't have a recommended solution for logging within GitLab. For more information, you can follow the issue for [integrating Opstrace with GitLab](https://gitlab.com/groups/gitlab-org/-/epics/6976).

**Planned removal milestone: 15.0 (2022-05-22)**

### Monitor performance metrics through Prometheus

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

By displaying data stored in a Prometheus instance, GitLab allows users to view performance metrics. GitLab also displays visualizations of these metrics in dashboards. The user can connect to a previously-configured external Prometheus instance, or set up Prometheus as a GitLab Managed App.
However, since certificate-based integration with Kubernetes clusters is deprecated in GitLab, the metrics functionality in GitLab that relies on Prometheus is also deprecated. This includes the metrics visualizations in dashboards. GitLab is working to develop a single user experience based on [Opstrace](https://about.gitlab.com/press/releases/2021-12-14-gitlab-acquires-opstrace-to-expand-its-devops-platform-with-open-source-observability-solution.html). An [issue exists](https://gitlab.com/groups/gitlab-org/-/epics/6976) for you to follow work on the Opstrace integration.

**Planned removal milestone: 15.0 (2022-05-22)**

### Pseudonymizer

The Pseudonymizer feature is generally unused,
can cause production issues with large databases,
and can interfere with object storage development.
It is now considered deprecated, and will be removed in GitLab 15.0.

**Planned removal milestone: 15.0 (2022-05-22)**

### SAST schemas below 14.0.0

[SAST report schemas](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/releases)
versions earlier than 14.0.0 will no longer be supported in GitLab 15.0. Reports that do not pass validation
against the schema version declared in the report will also no longer be supported as of GitLab 15.0.

Third-party tools that [integrate with GitLab by outputting a SAST security report](https://docs.gitlab.com/ee/development/integrations/secure.html#report)
as a pipeline job artifact are affected. You must ensure that all output reports adhere to the correct
schema with a minimum version of 14.0.0. Reports with a lower version or that fail to validate
against the declared schema version will not be processed, and vulnerability
findings will not display in MRs, pipelines, or Vulnerability Reports.

To help with the transition, from GitLab 14.10, non-compliant reports will display a
[warning](https://gitlab.com/gitlab-org/gitlab/-/issues/335789#note_672853791)
in the Vulnerability Report.

**Planned removal milestone: 15.0 (2022-05-22)**

### Secret detection schemas below 14.0.0

[Secret detection report schemas](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/releases)
versions earlier than 14.0.0 will no longer be supported in GitLab 15.0. Reports that do not pass validation
against the schema version declared in the report will also no longer be supported as of GitLab 15.0.

Third-party tools that [integrate with GitLab by outputting a Secret detection security report](https://docs.gitlab.com/ee/development/integrations/secure.html#report)
as a pipeline job artifact are affected. You must ensure that all output reports adhere to the correct
schema with a minimum version of 14.0.0. Reports with a lower version or that fail to validate
against the declared schema version will not be processed, and vulnerability
findings will not display in MRs, pipelines, or Vulnerability Reports.

To help with the transition, from GitLab 14.10, non-compliant reports will display a
[warning](https://gitlab.com/gitlab-org/gitlab/-/issues/335789#note_672853791)
in the Vulnerability Report.

**Planned removal milestone: 15.0 (2022-05-22)**

### Sidekiq metrics and health checks configuration

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

Exporting Sidekiq metrics and health checks using a single process and port is deprecated.
Support will be removed in 15.0.

We have updated Sidekiq to export [metrics and health checks from two separate processes](https://gitlab.com/groups/gitlab-org/-/epics/6409)
to improve stability and availability and prevent data loss in edge cases.
As those are two separate servers, a configuration change will be required in 15.0
to explicitly set separate ports for metrics and health-checks.
The newly introduced settings for `sidekiq['health_checks_*']`
should always be set in `gitlab.rb`.
For more information, check the documentation for [configuring Sidekiq](https://docs.gitlab.com/ee/administration/sidekiq.html).

These changes also require updates in either Prometheus to scrape the new endpoint or k8s health-checks to target the new
health-check port to work properly, otherwise either metrics or health-checks will disappear.

For the deprecation period those settings are optional
and GitLab will default the Sidekiq health-checks port to the same port as `sidekiq_exporter`
and only run one server (not changing the current behaviour).
Only if they are both set and a different port is provided, a separate metrics server will spin up
to serve the Sidekiq metrics, similar to the way Sidekiq will behave in 15.0.

**Planned removal milestone: 15.0 (2022-05-22)**

### Static Site Editor

The Static Site Editor will no longer be available starting in GitLab 15.0. Improvements to the Markdown editing experience across GitLab will deliver smiliar benefit but with a wider reach. Incoming requests to the Static Site Editor will be redirected to the Web IDE. Current users of the Static Site Editor can view the [documentation](https://docs.gitlab.com/ee/user/project/static_site_editor/) for more information, including how to remove the configuration files from existing projects.

**Planned removal milestone: 15.0 (2022-05-22)**

### Tracing in GitLab

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

Tracing in GitLab is an integration with Jaeger, an open-source end-to-end distributed tracing system. GitLab users can navigate to their Jaeger instance to gain insight into the performance of a deployed application, tracking each function or microservice that handles a given request. Tracing in GitLab is deprecated in GitLab 14.7, and scheduled for removal in 15.0. To track work on a possible replacement, see the issue for [Opstrace integration with GitLab](https://gitlab.com/groups/gitlab-org/-/epics/6976).

**Planned removal milestone: 15.0 (2022-05-22)**

### `artifacts:report:cobertura` keyword

Currently, test coverage visualizations in GitLab only support Cobertura reports. Starting 15.0, the
`artifacts:report:cobertura` keyword will be replaced by
[`artifacts:reports:coverage_report`](https://gitlab.com/gitlab-org/gitlab/-/issues/344533). Cobertura will be the
only supported report file in 15.0, but this is the first step towards GitLab supporting other report types.

**Planned removal milestone: 15.0 (2022-05-22)**

### merged_by API field

The `merged_by` field in the [merge request API](https://docs.gitlab.com/ee/api/merge_requests.html#list-merge-requests) is being deprecated and will be removed in GitLab 15.0. This field is being replaced with the `merge_user` field (already present in GraphQL) which more correctly identifies who merged a merge request when performing actions (merge when pipeline succeeds, add to merge train) other than a simple merge.

**Planned removal milestone: 15.0 (2022-05-22)**

## 14.8

### Vulnerability Check

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

The vulnerability check feature is deprecated in GitLab 14.8 and scheduled for removal in GitLab 15.0. We encourage you to migrate to the new security approvals feature instead. You can do so by navigating to **Security & Compliance > Policies** and creating a new Scan Result Policy.

The new security approvals feature is similar to vulnerability check. For example, both can require approvals for MRs that contain security vulnerabilities. However, security approvals improve the previous experience in several ways:

- Users can choose who is allowed to edit security approval rules. An independent security or compliance team can therefore manage rules in a way that prevents development project maintainers from modifying the rules.
- Multiple rules can be created and chained together to allow for filtering on different severity thresholds for each scanner type.
- A two-step approval process can be enforced for any desired changes to security approval rules.
- A single set of security policies can be applied to multiple development projects to allow for ease in maintaining a single, centralized ruleset.

**Planned removal milestone: 15.0 (2022-05-22)**

### `fixup!` commit messages setting draft status of associated Merge Request

The use of `fixup!` as a commit message to trigger draft status
of the associated Merge Request is generally unused, and can cause
confusion with other uses of the term. "Draft" is the preferred
and supported trigger for triggering draft status from commit
messages, as part of our streamlining of the feature.
Support for `fixup!` is now considered deprecated, and will be
removed in GitLab 15.0.

**Planned removal milestone: 15.0 (2022-06-22)**

### `started` iterations API field

WARNING:
This feature will be changed or removed in 15.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

The `started` field in the [iterations API](https://docs.gitlab.com/ee/api/iterations.html#list-project-iterations) is being deprecated and will be removed in GitLab 15.0. This field is being replaced with the `current` field (already available) which aligns with the naming for other time-based entities, such as milestones.

**Planned removal milestone: 15.0 (2022-05-22)**
