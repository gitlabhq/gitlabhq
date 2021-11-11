---
stage: none
group: none
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
---

# Deprecated feature removal schedule

DISCLAIMER:
This page contains information related to upcoming products, features, and functionality.
It is important to note that the information presented is for informational purposes only.
Please do not rely on this information for purchasing or planning purposes.
As with all projects, the items mentioned on this page are subject to change or delay.
The development, release, and timing of any products, features, or functionality remain at the
sole discretion of GitLab Inc.

<!-- vale off -->

<!--
This page is automatically generated from the YAML files in `/data/deprecations` by the rake task
located at `lib/tasks/gitlab/docs/compile_deprecations.rake`.

Do not edit this page directly.

To add a deprecation, use the example.yml file in `/data/deprecations/templates` as a template.

To update this doc, run `bin/rake gitlab:docs:compile_deprecations`.
To verify this doc is up to date, run `bin/rake gitlab:docs:check_deprecations`
-->

## 14.4

### Rename Task Runner pod to Toolbox

The Task Runner pod is used to execute periodic housekeeping tasks within the GitLab application and is often confused with the GitLab Runner. Thus, [Task Runner will be renamed to Toolbox](https://gitlab.com/groups/gitlab-org/charts/-/epics/25).

This will result in the rename of the sub-chart: `gitlab/task-runner` to `gitlab/toolbox`. Resulting pods will be named along the lines of `{{ .Release.Name }}-toolbox`, which will often be `gitlab-toolbox`. They will be locatable with the label `app=toolbox`.

Announced: 2021-08-22

## 14.6

### Release CLI be distributed as a generic package

The [release-cli](https://gitlab.com/gitlab-org/release-cli) will be released as a [generic package](https://gitlab.com/gitlab-org/release-cli/-/packages) starting in GitLab 14.2. We will continue to deploy it as a binary to S3 until GitLab 14.5 and stop distributing it in S3 in GitLab 14.6.

Announced: 2021-08-22

## 15.0

### Audit events for repository push events

Audit events for [repository events](https://docs.gitlab.com/ee/administration/audit_events.html#repository-push) are now deprecated and will be removed in GitLab 15.0.

These events have always been disabled by default and had to be manually enabled with a
feature flag. Enabling them can cause too many events to be generated which can
dramatically slow down GitLab instances. For this reason, they are being removed.

Announced: 2021-09-22

### Converting an instance (shared) runner to a project (specific) runner is deprecated

In GitLab 15.0, we will remove the feature that enables you to convert an instance (shared) runner to a project (specific) runner. Users who need to add a runner to only a particular project can register a runner to the project directly.

Announced: 2021-11-22

### Deprecate `Versions` on base `PackageType`

As part of the work to create a [Package Registry GraphQL API](https://gitlab.com/groups/gitlab-org/-/epics/6318), the Package group deprecated the `Version` type for the basic `PackageType` type and moved it to [`PackageDetailsType`](https://docs.gitlab.com/ee/api/graphql/reference/index.html#packagedetailstype).

In milestone 15.0, we will completely remove `Version` from `PackageType`.

Announced: 2021-11-22

### GitLab Serverless

[GitLab Serverless](https://docs.gitlab.com/ee/user/project/clusters/serverless/) is a feature set to support Knative-based serverless development with automatic deployments and monitoring.

We decided to remove the GitLab Serverless features as they never really resonated with our users. Besides, given the continuous development of Kubernetes and Knative, our current implementations do not even work with recent versions.

Announced: 2021-09-22

### Known host required for GitLab Runner SSH executor

In [GitLab 14.3](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3074), we added a configuration setting in the GitLab Runner `config.toml` file. This setting, [`[runners.ssh.disable_strict_host_key_checking]`](https://docs.gitlab.com/runner/executors/ssh.html#security), controls whether or not to use strict host key checking with the SSH executor.

In GitLab 15.0 and later, the default value for this configuration option will change from `true` to `false`. This means that strict host key checking will be enforced when using the GitLab Runner SSH executor.

Announced: 2021-11-22

### Legacy database configuration

The syntax of [GitLabs database](https://docs.gitlab.com/omnibus/settings/database.html)
configuration located in `database.yml` is changing and the legacy format is deprecated. The legacy format
supported using a single PostgreSQL adapter, whereas the new format is changing to support multiple databases. The `main:` database needs to be defined as a first configuration item.

This deprecation mainly impacts users compiling GitLab from source because Omnibus will handle this configuration automatically.

Announced: 2021-09-22

### OmniAuth Kerberos gem

The `omniauth-kerberos` gem will be removed in our next major release, GitLab 15.0.

This gem has not been maintained and has very little usage. We therefore plan to remove support for this authentication method and recommend using the Kerberos [SPNEGO](https://en.wikipedia.org/wiki/SPNEGO) integration instead. You can follow the [upgrade instructions](https://docs.gitlab.com/ee/integration/kerberos.html#upgrading-from-password-based-to-ticket-based-kerberos-sign-ins) to upgrade from the `omniauth-kerberos` integration to the supported one.

Note that we are not deprecating the Kerberos SPNEGO integration, only the old password-based Kerberos integration.

Announced: 2021-09-22

### Package pipelines in API payload is paginated

A request to the API for `/api/v4/projects/:id/packages` returns a paginated result of packages. Each package lists all of its pipelines in this response. This is a performance concern, as it's possible for a package to have hundreds or thousands of associated pipelines.

In milestone 15.0, we will remove the `pipelines` attribute from the API response.

Announced: 2021-11-22

### REST API Runner will not contain `paused`

Runner REST API will not return `paused` as a status in GitLab 15.0.

Paused runners' status will only relate to runner contact status, such as:
`online`, `offline`, or `not_connected`. Status `paused` will not appear when the runner is
not active.

When checking if a runner is `paused`, API users are advised to check the boolean attribute
`active` to be `false` instead.

Announced: 2021-11-22

### Remove the `:dependency_proxy_for_private_groups` feature flag

We added a feature flag because [GitLab-#11582](https://gitlab.com/gitlab-org/gitlab/-/issues/11582) changed how public groups use the Dependency Proxy. Prior to this change, you could use the Dependency Proxy without authentication. The change requires authentication to use the Dependency Proxy.

In milestone 15.0, we will remove the feature flag entirely. Moving forward, you must authenticate when using the Dependency Proxy.

Announced: 2021-11-22

### `AuthenticationType` for `[runners.cache.s3]` must be explicitly assigned

In GitLab 15.0 and later, to access the AWS S3 cache, you must specify the `AuthenticationType` for [`[runners.cache.s3]`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnerscaches3-section). The `AuthenticationType` must be `IAM` or `credentials`.

Prior to 14.5, if you did not define the `AuthenticationType`, GitLab Runner chose a type for you. 

Announced: 2021-11-22

## 15.2

### NFS for Git repository storage deprecated

With the general availability of Gitaly Cluster ([introduced in GitLab 13.0](https://about.gitlab.com/releases/2020/05/22/gitlab-13-0-released/)), we have deprecated development (bugfixes, performance improvements, etc) for NFS for Git repository storage in GitLab 14.0. We will continue to provide technical support for NFS for Git repositories throughout 14.x, but we will remove all support for NFS in GitLab 15.0. Please see our official [Statement of Support](https://about.gitlab.com/support/statement-of-support.html#gitaly-and-nfs) for further information.

Gitaly Cluster offers tremendous benefits for our customers such as:

- [Variable replication factors](https://docs.gitlab.com/ee/administration/gitaly/index.html#replication-factor).
- [Strong consistency](https://docs.gitlab.com/ee/administration/gitaly/index.html#strong-consistency).
- [Distributed read capabilities](https://docs.gitlab.com/ee/administration/gitaly/index.html#distributed-reads).

We encourage customers currently using NFS for Git repositories to plan their migration by reviewing our documentation on [migrating to Gitaly Cluster](https://docs.gitlab.com/ee/administration/gitaly/index.html#migrate-to-gitaly-cluster).

Announced: 2021-06-22
