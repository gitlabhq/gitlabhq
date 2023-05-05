---
stage: none
group: none
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-development-guidelines"
toc: false
---

# Deprecations by version

<!-- vale off -->

<!--
DO NOT EDIT THIS PAGE DIRECTLY

This page is automatically generated from the YAML files in `/data/deprecations` by the rake task
located at `lib/tasks/gitlab/docs/compile_deprecations.rake`.

For deprecation authors (usually Product Managers and Engineering Managers):

- To add a deprecation, use the example.yml file in `/data/deprecations/templates` as a template.
- For more information about authoring deprecations, check the the deprecation item guidance:
  https://about.gitlab.com/handbook/marketing/blog/release-posts/#update-the-deprecations-and-removals-docs

For deprecation reviewers (Technical Writers only):

- To update the deprecation doc, run: `bin/rake gitlab:docs:compile_deprecations`
- To verify the deprecations doc is up to date, run: `bin/rake gitlab:docs:check_deprecations`
- For more information about updating the deprecation doc, see the deprecation doc update guidance:
  https://about.gitlab.com/handbook/marketing/blog/release-posts/#update-the-deprecations-and-removals-docs
-->

{::options parse_block_html="true" /}

These GitLab features are deprecated and no longer recommended for use.
Each deprecated feature will be removed in a future release.
Some features cause breaking changes when they are removed.

On GitLab.com, deprecated features can be removed at any time during the month leading up to the release.

**{rss}** **To be notified of upcoming breaking changes**,
add this URL to your RSS feed reader: `https://about.gitlab.com/breaking-changes.xml`

You can also view [REST API](https://docs.gitlab.com/ee/api/rest/deprecations.html)
and [GraphQL](https://docs.gitlab.com/ee/api/graphql/removed_items.html) deprecations/removals.

<div class="js-deprecation-filters"></div>
<div class="milestone-wrapper" data-milestone="17.0">

## GitLab 17.0

<div class="deprecation breaking-change" data-milestone="17.0">

### Accessibility Testing is deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Due to low customer usage, Accessibility Testing is deprecated and will be removed. There is no planned replacement and users should stop using Accessibility Testing before GitLab 17.0.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Atlassian Crowd OmniAuth provider

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.3</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The `omniauth_crowd` gem that provides GitLab with the Atlassian Crowd OmniAuth provider will be removed in our
next major release, GitLab 16.0. This gem sees very little use and its
[lack of compatibility](https://github.com/robdimarco/omniauth_crowd/issues/37) with OmniAuth 2.0 is
[blocking our upgrade](https://gitlab.com/gitlab-org/gitlab/-/issues/30073).

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Auto DevOps support for Herokuish is deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Auto DevOps support for Herokuish is deprecated in favor of [Cloud Native Buildpacks](https://docs.gitlab.com/ee/topics/autodevops/stages.html#auto-build-using-cloud-native-buildpacks). You should [migrate your builds from Herokuish to Cloud Native Buildpacks](https://docs.gitlab.com/ee/topics/autodevops/stages.html#moving-from-herokuish-to-cloud-native-buildpacks). From GitLab 14.0, Auto Build uses Cloud Native Buildpacks by default.

Because Cloud Native Buildpacks do not support automatic testing, the Auto Test feature of Auto DevOps is also deprecated.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Browser Performance Testing is deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Due to limited customer usage, Browser Performance Testing is deprecated and will be removed. There is no planned replacement and users should stop using Browser Performance Testing before GitLab 17.0.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### CiRunner.projects default sort is changing to `id_desc`

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">16.0</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The `CiRunner.projects`'s field default sort order value will change from `id_asc` to `id_desc`.
If you rely on the order of the returned projects to be `id_asc`, change your scripts to make the choice explicit.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### CiRunnerUpgradeStatusType GraphQL type renamed to CiRunnerUpgradeStatus

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">16.0</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The `CiRunnerUpgradeStatusType` GraphQL type has been renamed to `CiRunnerUpgradeStatus`. In GitLab 17.0,
the aliasing for the `CiRunnerUpgradeStatusType` type will be removed.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### DAST ZAP advanced configuration variables deprecation

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.7</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

With the new browser-based DAST analyzer GA in GitLab 15.7, we are working towards making it the default DAST analyzer at some point in the future. In preparation for this, the following legacy DAST variables are being deprecated and scheduled for removal in GitLab 17.0: `DAST_ZAP_CLI_OPTIONS` and `DAST_ZAP_LOG_CONFIGURATION`. These variables allowed for advanced configuration of the legacy DAST analyzer, which was based on OWASP ZAP. The new browser-based analyzer will not include the same functionality, as these were specific to how ZAP worked.

These three variables will be removed in GitLab 17.0.

</div>

<div class="deprecation " data-milestone="17.0">

### Deprecate legacy shell escaping and quoting runner shell executor

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.11</span>
- End of Support: GitLab <span class="milestone">17.9</span>
</div>

The runner's legacy escape sequence mechanism to handle variable expansion implements a sub-optimal implementation of Ansi-C quoting. This method means that the runner would expand arguments included in double quotes. As of 15.11, we are deprecating the legacy escaping and quoting methods in the runner shell executor.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### DingTalk OmniAuth provider

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.10</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The `omniauth-dingtalk` gem that provides GitLab with the DingTalk OmniAuth provider will be removed in our next
major release, GitLab 17.0. This gem sees very little use and is better suited for JiHu edition.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Filepath field in Releases and Release Links APIs

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Support for specifying a `filepath` for a direct asset link in the [Releases API](https://docs.gitlab.com/ee/api/releases)
and [Release Links API](https://docs.gitlab.com/ee/api/releases/links.html) is deprecated in GitLab 15.9 and will be
removed in GitLab 17.0. GitLab introduced a new field called `direct_asset_path` in GitLab 15.9 to replace `filepath`
until it is finally removed.

To avoid any disruptions, you should replace `filepath` with `direct_asset_path` in your calls to the following endpoints:

- Releases API:
  - [Create a release](https://docs.gitlab.com/ee/api/releases/#create-a-release)
  - [Download a release asset](https://docs.gitlab.com/ee/api/releases/#download-a-release-asset)
- Release Links API:
  - [Create a release link](https://docs.gitlab.com/ee/api/releases/links.html#create-a-release-link)
  - [Update a release link](https://docs.gitlab.com/ee/api/releases/links.html#update-a-release-link)

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GitLab Helm chart values `gitlab.kas.privateApi.*` are deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

We introduced the `global.kas.tls.*` Helm values to facilitate TLS communication between KAS and your Helm chart components.
The old values `gitlab.kas.privateApi.tls.enabled` and `gitlab.kas.privateApi.tls.secretName` are deprecated and scheduled for removal in GitLab 17.0.

Because the new values provide a streamlined, comprehensive method to enable TLS for KAS, you should use `global.kas.tls.*` instead of `gitlab.kas.privateApi.tls.*`. The `gitlab.kas.privateApi.tls.*` For more information, see:

- The [merge request](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/2888) that introduces the `global.kas.tls.*` values.
- The [deprecated `gitlab.kas.privateApi.tls.*` documentation](https://docs.gitlab.com/charts/charts/gitlab/kas/index.html#enable-tls-communication-through-the-gitlabkasprivateapi-attributes-deprecated).
- The [new `global.kas.tls.*` documentation](https://docs.gitlab.com/charts/charts/globals.html#tls-settings-1).

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GitLab Runner platforms and setup instructions in GraphQL API

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The `runnerPlatforms` and `runnerSetup` queries to get GitLab Runner platforms and installation instructions
are deprecated and will be removed from the GraphQL API. For installation instructions, you should use the
[GitLab Runner documentation](https://docs.gitlab.com/runner/)

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GitLab Runner registration token in Runner Operator

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.6</span>
- End of Support: GitLab <span class="milestone">17.0</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The [`runner-registration-token`](https://docs.gitlab.com/runner/install/operator.html#install-the-kubernetes-operator) parameter that uses the OpenShift and Kubernetes Vanilla Operator to install a runner on Kubernetes is deprecated. Authentication tokens will be used to register runners instead. Registration tokens, and support for certain configuration arguments,
will be disabled behind a feature flag in GitLab 16.6 and removed in GitLab 17.0. The configuration arguments disabled for authentication tokens are:

- `--locked`
- `--access-level`
- `--run-untagged`
- `--tag-list`

This change is a breaking change. You should use an [authentication token](../ci/runners/register_runner.md) in the `gitlab-runner register` command instead.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GraphQL: The `DISABLED_WITH_OVERRIDE` value of the `SharedRunnersSetting` enum is deprecated. Use `DISABLED_AND_OVERRIDABLE` instead

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

In GitLab 17.0, the `DISABLED_WITH_OVERRIDE` value of the `SharedRunnersSetting` GraphQL enum type will be replaced with the value, `DISABLED_AND_OVERRIDABLE`.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Load Performance Testing is deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Due to low customer usage, Load Performance Testing is deprecated and will be removed. There is no planned replacement and users should stop using Load Performance Testing before GitLab 17.0.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Queue selector for running Sidekiq is deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- End of Support: GitLab <span class="milestone">16.0</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Running Sidekiq with a [queue selector](https://docs.gitlab.com/ee/administration/sidekiq/processing_specific_job_classes.html#queue-selectors) (having multiple processes listening to a set of queues) and [negate settings](https://docs.gitlab.com/ee/administration/sidekiq/processing_specific_job_classes.html#negate-settings) is deprecated and will be fully removed in 17.0.

You can migrate away from queue selectors to [listening to all queues in all processes](https://docs.gitlab.com/ee/administration/sidekiq/extra_sidekiq_processes.html#start-multiple-processes). For example, if Sidekiq is currently running with 4 processes (denoted by 4 elements in `sidekiq['queue_groups']` in `/etc/gitlab/gitlab.rb`) with queue selector (`sidekiq['queue_selector'] = true`), you can change Sidekiq to listen to all queues in all 4 processes,for example `sidekiq['queue_groups'] = ['*'] * 4`. This approach is also recommended in our [Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/5k_users.html#configure-sidekiq). Note that Sidekiq can effectively run as many processes as the number of CPUs in the machine.

While the above approach is recommended for most instances, Sidekiq can also be run using [routing rules](https://docs.gitlab.com/ee/administration/sidekiq/processing_specific_job_classes.html#routing-rules) which is also being used on GitLab.com. You can follow the [migration guide from queue selectors to routing rules](https://docs.gitlab.com/ee/administration/sidekiq/processing_specific_job_classes.html#migrating-from-queue-selectors-to-routing-rules). You need to take care with the migration to avoid losing jobs entirely.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Registration tokens and server-side runner arguments in `POST /api/v4/runners` endpoint

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.6</span>
- End of Support: GitLab <span class="milestone">17.0</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The support for registration tokens and certain runner configuration arguments in the `POST` method operation on the `/api/v4/runners` endpoint is deprecated.
This endpoint [registers](https://docs.gitlab.com/ee/api/runners.html#register-a-new-runner) a runner
with a GitLab instance at the instance, group, or project level through the API. Registration tokens, and support for certain configuration arguments,
will be disabled behind a feature flag in GitLab 16.6 and removed in GitLab 17.0. The configuration arguments disabled for authentication tokens are:

- `--locked`
- `--access-level`
- `--run-untagged`
- `--maximum-timeout`
- `--paused`
- `--tag-list`
- `--maintenance-note`

This change is a breaking change. You should [create a runner in the UI](../ci/runners/register_runner.md) to add configurations, and use the authentication token in the `gitlab-runner register` command instead.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Registration tokens and server-side runner arguments in `gitlab-runner register` command

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.6</span>
- End of Support: GitLab <span class="milestone">17.0</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Registration tokens and certain configuration arguments in the command `gitlab-runner register` that [registers](https://docs.gitlab.com/runner/register/) a runner, are deprecated.
Authentication tokens will be used to register runners instead. Registration tokens, and support for certain configuration arguments,
will be disabled behind a feature flag in GitLab 16.6 and removed in GitLab 17.0. The configuration arguments disabled for authentication tokens are:

- `--locked`
- `--access-level`
- `--run-untagged`
- `--maximum-timeout`
- `--paused`
- `--tag-list`
- `--maintenance-note`

This change is a breaking change. You should [create a runner in the UI](../ci/runners/register_runner.md) to add configurations, and use the authentication token in the `gitlab-runner register` command instead.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Required Pipeline Configuration is deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Required Pipeline Configuration will be removed in the 17.0 release. This impacts self-managed users on the Ultimate license.

We recommend replacing this with an alternative [compliance solution](https://docs.gitlab.com/ee/user/group/compliance_frameworks.html#compliance-pipelines)
that is available now. We recommend this alternative solution because it provides greater flexibility, allowing required pipelines to be assigned to specific compliance framework labels.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Self-managed certificate-based integration with Kubernetes

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.5</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The certificate-based integration with Kubernetes [will be deprecated and removed](https://about.gitlab.com/blog/2021/11/15/deprecating-the-cert-based-kubernetes-integration/).

As a self-managed customer, we are introducing the [feature flag](../administration/feature_flags.md#enable-or-disable-the-feature) `certificate_based_clusters` in GitLab 15.0 so you can keep your certificate-based integration enabled. However, the feature flag will be disabled by default, so this change is a **breaking change**.

In GitLab 17.0 we will remove both the feature and its related code. Until the final removal in 17.0, features built on this integration will continue to work, if you enable the feature flag. Until the feature is removed, GitLab will continue to fix security and critical issues as they arise.

For a more robust, secure, forthcoming, and reliable integration with Kubernetes, we recommend you use the
[agent for Kubernetes](https://docs.gitlab.com/ee/user/clusters/agent/) to connect Kubernetes clusters with GitLab. [How do I migrate?](https://docs.gitlab.com/ee/user/infrastructure/clusters/migrate_to_gitlab_agent.html)

Although an explicit removal date is set, we don't plan to remove this feature until the new solution has feature parity.
For more information about the blockers to removal, see [this issue](https://gitlab.com/gitlab-org/configure/general/-/issues/199).

For updates and details about this deprecation, follow [this epic](https://gitlab.com/groups/gitlab-org/configure/-/epics/8).

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Single database connection is deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Previously, [GitLab's database](https://docs.gitlab.com/omnibus/settings/database.html)
configuration had a single `main:` section. This is being deprecated. The new
configuration has both a `main:` and a `ci:` section.

This deprecation affects users compiling GitLab from source, who will need
to [add the `ci:` section](https://docs.gitlab.com/ee/install/installation.html#configure-gitlab-db-settings).
Omnibus, the Helm chart, and Operator will handle this configuration
automatically from GitLab 16.0 onwards.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Slack notifications integration

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- End of Support: GitLab <span class="milestone">17.0</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

As we're consolidating all Slack capabilities into the
GitLab for Slack app, we're [deprecating the Slack notifications
integration](https://gitlab.com/gitlab-org/gitlab/-/issues/372411).
GitLab.com users can now use the GitLab for Slack app to manage notifications
to their Slack workspace. For self-managed users of the Slack notifications integration,
we'll be introducing support in [this epic](https://gitlab.com/groups/gitlab-org/-/epics/1211).

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Support for REST API endpoints that reset runner registration tokens

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.7</span>
- End of Support: GitLab <span class="milestone">17.0</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The support for runner registration tokens is deprecated. As a consequence, the REST API endpoints to reset a registration token are also deprecated and will
be removed in GitLab 17.0.
The deprecated endpoints are:

- `POST /runners/reset_registration_token`
- `POST /projects/:id/runners/reset_registration_token`
- `POST /groups/:id/runners/reset_registration_token`

We plan to implement a new method to bind runners to a GitLab instance
as part of the new [GitLab Runner token architecture](https://docs.gitlab.com/ee/architecture/blueprints/runner_tokens/).
The work is planned in [this epic](https://gitlab.com/groups/gitlab-org/-/epics/7633).
This new architecture introduces a new method for registering runners and will eliminate the legacy
[runner registration token](https://docs.gitlab.com/ee/security/token_overview.html#runner-registration-tokens).
From GitLab 17.0 and later, the runner registration methods implemented by the new GitLab Runner token architecture will be the only supported methods.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### The GitLab legacy requirement IID is deprecated in favor of work item IID

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

We will be transitioning to a new IID as a result of moving requirements to a [work item type](https://docs.gitlab.com/ee/development/work_items.html#work-items-and-work-item-types). Users should begin using the new IID as support for the legacy IID and existing formatting will end in GitLab 17.0. The legacy requirement IID remains available until its removal in GitLab 17.0.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### The Visual Reviews tool is deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Due to limited customer usage and capabilities, the Visual Reviews feature for Review Apps is deprecated and will be removed. There is no planned replacement and users should stop using Visual Reviews before GitLab 17.0.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### The `gitlab-runner exec` command is deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.7</span>
- End of Support: GitLab <span class="milestone">17.0</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The [`gitlab-runner exec`](https://docs.gitlab.com/runner/commands/#gitlab-runner-exec) command is deprecated and will be fully removed from GitLab Runner in 16.0. The `gitlab-runner exec` feature was initially developed to provide the ability to validate a GitLab CI pipeline on a local system without needing to commit the updates to a GitLab instance. However, with the continued evolution of GitLab CI, replicating all GitLab CI features into `gitlab-runner exec` was no longer viable. Pipeline syntax and validation [simulation](https://docs.gitlab.com/ee/ci/pipeline_editor/#simulate-a-cicd-pipeline) are available in the GitLab pipeline editor.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Trigger jobs can mirror downstream pipeline status exactly

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

In some cases, like when a downstream pipeline had the `passed with warnings` status, trigger jobs that were using [`strategy: depend`](https://docs.gitlab.com/ee/ci/yaml/index.html#strategydepend) did not mirror the status of the downstream pipeline exactly. In GitLab 17.0 trigger jobs will show the exact same status as the the downstream pipeline. If your pipeline relied on this behavior, you should update your pipeline to handle the more accurate status.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### `runnerRegistrationToken` parameter for GitLab Runner Helm Chart

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.6</span>
- End of Support: GitLab <span class="milestone">17.0</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The [`runnerRegistrationToken`](https://docs.gitlab.com/runner/install/kubernetes.html#required-configuration) parameter to use the GitLab Helm Chart to install a runner on Kubernetes is deprecated.

We plan to implement a new method to bind runners to a GitLab instance leveraging `runnerToken`
as part of the new [GitLab Runner token architecture](https://docs.gitlab.com/ee/architecture/blueprints/runner_tokens/).
The work is planned in [this epic](https://gitlab.com/groups/gitlab-org/-/epics/7633).

From GitLab 17.0 and later, the methods to register runners introduced by the new GitLab Runner token architecture will be the only supported methods.

</div>
</div>

<div class="milestone-wrapper" data-milestone="16.6">

## GitLab 16.6

<div class="deprecation breaking-change" data-milestone="16.6">

### Error Tracking UI in GitLab Rails is deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The [Error Tracking UI](https://docs.gitlab.com/ee/operations/error_tracking.html) is deprecated in 15.9 and will be removed in 16.6 (milestone might change) once GitLab Observability UI is made available. In future versions, you should use the [GitLab Observability UI](https://gitlab.com/gitlab-org/opstrace/opstrace-ui/), which will gradually be made available on GitLab.com over the next few releases.

During the transition to the GitLab Observability UI, we will migrate the [GitLab Observability Backend](https://gitlab.com/gitlab-org/opstrace/opstrace) from a per-cluster deployment model to a per-tenant deployment model. Because [Integrated Error Tracking](https://docs.gitlab.com/ee/operations/error_tracking.html#integrated-error-tracking) is in Open Beta, we will not migrate any existing user data. For more details about the migration, see the direction pages for:

- [Observability](https://about.gitlab.com/direction/monitor/observability/data-visualization/).
- The [Observability Backend](https://about.gitlab.com/direction/monitor/observability/data-management/).
- [Data visualization](https://about.gitlab.com/direction/monitor/observability/data-visualization/).

</div>
</div>

<div class="milestone-wrapper" data-milestone="16.5">

## GitLab 16.5

<div class="deprecation breaking-change" data-milestone="16.5">

### Old versions of JSON web tokens are deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Now that we have released [ID tokens](https://docs.gitlab.com/ee/ci/secrets/id_token_authentication.html)
with OIDC support, the old JSON web tokens are deprecated.
Both the `CI_JOB_JWT` and `CI_JOB_JWT_V2` tokens, exposed to jobs as predefined variables, will:

- Not be creatable in GitLab 16.0 and later.
- Be removed in GitLab 16.5.

To prepare for this change:

- Before the release of GitLab 16.5, configure your pipelines to use the fully configurable and more secure
  [`id_token`](https://docs.gitlab.com/ee/ci/yaml/index.html#id_tokens) keyword instead.
- [Enable the **Limit JSON Web Token (JWT) access**](https://docs.gitlab.com/ee/ci/secrets/id_token_authentication.html#enable-automatic-id-token-authentication)
  setting, which prevents the old tokens from being exposed to any jobs.

  In GitLab 16.0 and later, the ability to set this option will be removed and all new projects will have the option
  enabled.

</div>
</div>

<div class="milestone-wrapper" data-milestone="16.1">

## GitLab 16.1

<div class="deprecation " data-milestone="16.1">

### GitLab Runner images based on Alpine 3.12, 3.13, 3.14

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.11</span>
- End of Support: GitLab <span class="milestone">16.1</span>
</div>

We will stop publishing runner images based on the following, end-of-life Alpine versions:

- Alpine 3.12
- Alpine 3.13
- Alpine 3.14 (end-of-life on 2023-05-23)

</div>
</div>

<div class="milestone-wrapper" data-milestone="16.0">

## GitLab 16.0

<div class="deprecation breaking-change" data-milestone="16.0">

### Auto DevOps no longer provisions a PostgreSQL database by default

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Currently, Auto DevOps provisions an in-cluster PostgreSQL database by default.
In GitLab 16.0, databases will be provisioned only for users who opt in. This
change supports production deployments that require more robust database management.

If you want Auto DevOps to provision an in-cluster database,
set the `POSTGRES_ENABLED` CI/CD variable to `true`.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Azure Storage Driver defaults to the correct root prefix

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The Azure Storage Driver writes to `//` as the default root directory. This default root directory appears in some places within the Azure UI as `/<no-name>/`. We have maintained this legacy behavior to support older deployments using this storage driver. However, when moving to Azure from another storage driver, this behavior hides all your data until you configure the storage driver to build root paths without an extra leading slash by setting `trimlegacyrootprefix: true`.

The new default configuration for the storage driver will set `trimlegacyrootprefix: true`, and `/` will be the default root directory. You can add `trimlegacyrootprefix: false` to your current configuration to avoid any disruptions.

This breaking change will happen in GitLab 16.0.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Bundled Grafana Helm Chart is deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.10</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The Grafana Helm chart that is bundled with the GitLab Helm Chart is deprecated and will be removed in the GitLab Helm Chart 7.0 release (releasing along with GitLab 16.0).

The bundled Grafana Helm chart is an optional service that can be turned on to provide the Grafana UI connected to the GitLab Helm Chart's Prometheus metrics.

The version of Grafana that the GitLab Helm Chart is currently providing is no longer a supported Grafana version.
If you're using the bundled Grafana, you should switch to the [newer chart version from Grafana Labs](https://artifacthub.io/packages/helm/grafana/grafana)
or a Grafana Operator from a trusted provider.

In your new Grafana instance, you can [configure the GitLab provided Prometheus as a data source](https://docs.gitlab.com/ee/administration/monitoring/performance/grafana_configuration.html#integration-with-gitlab-ui)
and [connect Grafana to the GitLab UI](https://docs.gitlab.com/ee/administration/monitoring/performance/grafana_configuration.html#integration-with-gitlab-ui).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### CAS OmniAuth provider

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.3</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The `omniauth-cas3` gem that provides GitLab with the CAS OmniAuth provider will be removed in our next major
release, GitLab 16.0. This gem sees very little use and its lack of upstream maintenance is preventing GitLab's
[upgrade to OmniAuth 2.0](https://gitlab.com/gitlab-org/gitlab/-/issues/30073).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### CI/CD jobs will fail when no secret is returned from Hashicorp Vault

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

When using the native HashiCorp Vault integration, CI/CD jobs will fail when no secret is returned from Vault. Make sure your configuration always return a secret, or update your pipeline to handle this change, before GitLab 16.0.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Changing MobSF-based SAST analyzer behavior in multi-module Android projects

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">16.0</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

We'll change how the MobSF-based analyzer in GitLab SAST handles multi-module Android projects.
This analyzer only runs if you [enable Experimental features](https://docs.gitlab.com/ee/user/application_security/sast/#experimental-features) for SAST.

The analyzer currently searches for `AndroidManifest.xml` files and scans only the first one it finds.
This manifest often is not the main manifest for the app, so the scan checks less of the app's source code for vulnerabilities.

Starting in GitLab 16.0, the analyzer will always use `app/src/main/AndroidManifest.xml` as the manifest, and use `app/src/main/` as the project root directory.
The new behavior matches standard Android project layouts and addresses bug reports from customers, so we expect it will improve scan coverage for most apps.

If you relied on the previous behavior, you can [pin the MobSF analyzer](https://docs.gitlab.com/ee/user/application_security/sast/#pinning-to-minor-image-version) to version 4.0.0, which uses the old behavior.
Then, please comment on [the deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/408396) so we can consider new configuration options to accommodate your use case.

This change doesn't affect scans you run in GitLab 15.11 or previous versions, since this change is only included in the [new major version](#secure-analyzers-major-version-update) of the MobSF-based analyzer.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Changing merge request approvals with the `/approvals` API endpoint

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.0</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

To change the approvals required for a merge request, you should no longer use the `/approvals` API endpoint, which was deprecated in GitLab 14.0.

Instead, use the [`/approval_rules` endpoint](https://docs.gitlab.com/ee/api/merge_request_approvals.html#merge-request-level-mr-approvals) to [create](https://docs.gitlab.com/ee/api/merge_request_approvals.html#create-merge-request-level-rule) or [update](https://docs.gitlab.com/ee/api/merge_request_approvals.html#update-merge-request-level-rule) the approval rules for a merge request.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Conan project-level search endpoint returns project-specific results

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

You can use the GitLab Conan repository with [project-level](https://docs.gitlab.com/ee/user/packages/conan_repository/#add-a-remote-for-your-project) or [instance-level](https://docs.gitlab.com/ee/user/packages/conan_repository/#add-a-remote-for-your-instance) endpoints. Each level supports the conan search command. However, the search endpoint for the project level is also returning packages from outside the target project.

This unintended functionality is deprecated in GitLab 15.8 and will be removed in GitLab 16.0. The search endpoint for the project level will only return packages from the target project.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Configuration fields in GitLab Runner Helm Chart

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.6</span>
- End of Support: GitLab <span class="milestone">16.0</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

From GitLab 13.6, users can [specify any runner configuration in the GitLab Runner Helm chart](https://docs.gitlab.com/runner/install/kubernetes.html). When we implemented this feature, we deprecated values in the GitLab Helm Chart configuration that were specific to GitLab Runner. These fields are deprecated and we plan to remove them in v1.0 of the GitLab Runner Helm chart.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Configuring Redis config file paths using environment variables is deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

You can no longer specify Redis configuration file locations
using the environment variables like `GITLAB_REDIS_CACHE_CONFIG_FILE` or
`GITLAB_REDIS_QUEUES_CONFIG_FILE`. Use the default
config file locations instead, for example `config/redis.cache.yml` or
`config/redis.queues.yml`.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Container Registry pull-through cache

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The Container Registry [pull-through cache](https://docs.docker.com/registry/recipes/mirror/) is deprecated in GitLab 15.8 and will be removed in GitLab 16.0. The pull-through cache is part of the upstream [Docker Distribution project](https://github.com/distribution/distribution). However, we are removing the pull-through cache in favor of the GitLab Dependency Proxy, which allows you to proxy and cache container images from Docker Hub. Removing the pull-through cache allows us also to remove the upstream client code without sacrificing functionality.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Container Scanning variables that reference Docker

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.4</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

All Container Scanning variables that are prefixed by `DOCKER_` in variable name are deprecated. This includes the `DOCKER_IMAGE`, `DOCKER_PASSWORD`, `DOCKER_USER`, and `DOCKERFILE_PATH` variables. Support for these variables will be removed in the GitLab 16.0 release. Use the [new variable names](https://docs.gitlab.com/ee/user/application_security/container_scanning/#available-cicd-variables) `CS_IMAGE`, `CS_REGISTRY_PASSWORD`, `CS_REGISTRY_USER`, and `CS_DOCKERFILE_PATH` in place of the deprecated names.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Cookie authorization in the GitLab for Jira Cloud app

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Cookie authentication in the GitLab for Jira Cloud app is now deprecated in favor of OAuth authentication.
On self-managed, you must [set up OAuth authentication](https://docs.gitlab.com/ee/integration/jira/connect-app.html#set-up-oauth-authentication-for-self-managed-instances)
to continue to use the GitLab for Jira Cloud app. Without OAuth, you can't manage linked namespaces.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### DAST API scans using DAST template is deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.7</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

With the move to the new DAST API analyzer and the `DAST-API.gitlab-ci.yml` template for DAST API scans, we will be removing the ability to scan APIs with the DAST analyzer. Use of the `DAST.gitlab-ci.yml` or `DAST-latest.gitlab-ci.yml` templates for API scans is deprecated as of GitLab 15.7 and will no longer work in GitLab 16.0. Please use `DAST-API.gitlab-ci.yml` template and refer to the [DAST API analyzer](https://docs.gitlab.com/ee/user/application_security/dast_api/#configure-dast-api-with-an-openapi-specification) documentation for configuration details.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### DAST API variables

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.7</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

With the switch to the new DAST API analyzer in GitLab 15.6, two legacy DAST API variables are being deprecated. The variables `DAST_API_HOST_OVERRIDE` and `DAST_API_SPECIFICATION` will no longer be used for DAST API scans.

`DAST_API_HOST_OVERRIDE` has been deprecated in favor of using the `DAST_API_TARGET_URL` to automatically override the host in the OpenAPI specification.

`DAST_API_SPECIFICATION` has been deprecated in favor of `DAST_API_OPENAPI`. To continue using an OpenAPI specification to guide the test, users must replace the `DAST_API_SPECIFICATION` variable with the `DAST_API_OPENAPI` variable. The value can remain the same, but the variable name must be replaced.

These two variables will be removed in GitLab 16.0.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### DAST report variables deprecation

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.7</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

With the new browser-based DAST analyzer GA in GitLab 15.7, we are working towards making it the default DAST analyzer at some point in the future. In preparation for this, the following legacy DAST variables are being deprecated and scheduled for removal in GitLab 16.0: `DAST_HTML_REPORT`, `DAST_XML_REPORT`, and `DAST_MARKDOWN_REPORT`. These reports relied on the legacy DAST analyzer and we do not plan to implement them in the new browser-based analyzer. As of GitLab 16.0, these report artifacts will no longer be generated.

These three variables will be removed in GitLab 16.0.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Default CI/CD job token (`CI_JOB_TOKEN`) scope changed

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

In GitLab 14.4 we introduced the ability to [limit your project's CI/CD job token](https://docs.gitlab.com/ee/ci/jobs/ci_job_token.html#limit-your-projects-job-token-access) (`CI_JOB_TOKEN`) access to make it more secure. You can prevent job tokens **from your project's** pipelines from being used to **access other projects**. When enabled with no other configuration, your pipelines cannot access other projects. To use the job token to access other projects from your pipeline, you must list those projects explicitly in the **Limit CI_JOB_TOKEN access** setting's allowlist, and you must be a maintainer in all the projects.

The job token functionality was updated in 15.9 with a better security setting to [allow access to your project with a job token](https://docs.gitlab.com/ee/ci/jobs/ci_job_token.html#allow-access-to-your-project-with-a-job-token). When enabled with no other configuration, job tokens **from other projects** cannot **access your project**. Similar to the older setting, you can optionally allow other projects to access your project with a job token if you list those projects explicitly in the **Allow access to this project with a CI_JOB_TOKEN** setting's allowlist. With this new setting, you must be a maintainer in your own project, but only need to have the Guest role in the other projects.

As a result, the **Limit** setting is deprecated in preference of the better **Allow access** setting. In GitLab 16.0 the **Limit** setting will be disabled by default for all new projects. In projects with this setting currently enabled, it will continue to function as expected, but you will not be able to add any more projects to the allowlist. If the setting is disabled in any project, it will not be possible to re-enable this setting in 16.0 or later.

In 17.0, we plan to remove the **Limit** setting completely, and set the **Allow access** setting to enabled for all projects. This change ensures a higher level of security between projects. If you currently use the **Limit** setting, you should update your projects to use the **Allow access** setting instead. If other projects access your project with a job token, you must add them to the **Allow access** allowlist.

To prepare for this change, users on GitLab.com or self-managed GitLab 15.9 or later can enable the **Allow access** setting now and add the other projects. It will not be possible to disable the setting in 17.0 or later.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Dependency Scanning support for Java 13, 14, 15, and 16

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

GitLab has deprecated Dependency Scanning support for Java versions 13, 14, 15, and 16 and plans to remove that support in the upcoming GitLab 16.0 release. This is consistent with [Oracle's support policy](https://www.oracle.com/java/technologies/java-se-support-roadmap.html) as Oracle Premier and Extended Support for these versions has ended. This also allows GitLab to focus Dependency Scanning Java support on LTS versions moving forward.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Deployment API returns error when `updated_at` and `updated_at` are not used together

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The Deployment API will now return an error when `updated_at` filtering and `updated_at` sorting are not used together. Some users were using filtering by `updated_at` to fetch "latest" deployment without using `updated_at` sorting, which may produce wrong results. You should instead use them together, or migrate to filtering by `finished_at` and sorting by `finished_at` which will give you "latest deployments" in a consistent way.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Deprecate legacy Gitaly configuration methods

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Using environment variables `GIT_CONFIG_SYSTEM` and `GIT_CONFIG_GLOBAL` to configure Gitaly is [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/352609).
These variables are being replaced with standard [`config.toml` Gitaly configuration](https://docs.gitlab.com/ee/administration/gitaly/reference.html).

GitLab instances that use `GIT_CONFIG_SYSTEM` and `GIT_CONFIG_GLOBAL` to configure Gitaly should switch to configuring using
`config.toml`.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Deprecated Consul http metrics

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.10</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The Consul provided in the GitLab Omnibus package will no longer provide older deprecated Consul metrics starting in GitLab 16.0.

In GitLab 14.0, [Consul was updated to 1.9.6](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5344),
which deprecated some telemetry metrics from being at the `consul.http` path. In GitLab 16.0, the `consul.http` path will be removed.

If you have monitoring that consumes Consul metrics, update them to use `consul.api.http` instead of `consul.http`.
For more information, see [the deprecation notes for Consul 1.9.0](https://github.com/hashicorp/consul/releases/tag/v1.9.0).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Deprecation and planned removal for `CI_PRE_CLONE_SCRIPT` variable on GitLab SaaS

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- End of Support: GitLab <span class="milestone">16.0</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The [`CI_PRE_CLONE_SCRIPT` variable](https://docs.gitlab.com/ee/ci/runners/saas/linux_saas_runner.html#pre-clone-script) supported by GitLab SaaS Runners is deprecated as of GitLab 15.9 and will be removed in 16.0. The `CI_PRE_CLONE_SCRIPT` variable enables you to run commands in your CI/CD job prior to the runner executing Git init and get fetch. For more information about how this feature works, see [Pre-clone script](https://docs.gitlab.com/ee/ci/runners/saas/linux_saas_runner.html#pre-clone-script). As an alternative, you can use the [`pre_get_sources_script`](https://docs.gitlab.com/ee/ci/yaml/#hookspre_get_sources_script).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Developer role providing the ability to import projects to a group

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The ability for users with the Developer role for a group to import projects to that group is deprecated in GitLab
15.8 and will be removed in GitLab 16.0. From GitLab 16.0, only users with at least the Maintainer role for a group
will be able to import projects to that group.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Development dependencies reported for PHP and Python

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

In GitLab 16.0 the GitLab Dependency Scanning analyzer will begin reporting development dependencies for both Python/pipenv and PHP/composer projects. Users who do not wish to have these development dependencies reported should set `DS_INCLUDE_DEV_DEPENDENCIES: false` in their CI/CD file.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Embedding Grafana panels in Markdown is deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The ability to add Grafana panels in GitLab Flavored Markdown is deprecated in 15.9 and will be removed in 16.0.
We intend to replace this feature with the ability to [embed charts](https://gitlab.com/groups/gitlab-org/opstrace/-/epics/33) with the [GitLab Observability UI](https://gitlab.com/gitlab-org/opstrace/opstrace-ui).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Enforced validation of CI/CD parameter character lengths

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

While CI/CD [job names](https://docs.gitlab.com/ee/ci/jobs/index.html#job-name-limitations) have a strict 255 character limit, other CI/CD parameters do not yet have validations ensuring they also stay under the limit.

In GitLab 16.0, validation will be added to strictly limit the following to 255 characters as well:

- The `stage` keyword.
- The `ref`, which is the Git branch or tag name for the pipeline.
- The `description` and `target_url` parameter, used by external CI/CD integrations.

Users on self-managed instances should update their pipelines to ensure they do not use parameters that exceed 255 characters. Users on GitLab.com do not need to make any changes, as these are already limited in that database.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Environment search query requires at least three characters

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.10</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

From GitLab 16.0, when you search for environments with the API, you must use at least three characters. This change helps us ensure the scalability of the search operation.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### External field in GraphQL ReleaseAssetLink type

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

In the [GraphQL API](https://docs.gitlab.com/ee/api/graphql/), the `external` field of [`ReleaseAssetLink` type](https://docs.gitlab.com/ee/api/graphql/reference/index.html#releaseassetlink) was used to indicate whether a [release link](https://docs.gitlab.com/ee/user/project/releases/release_fields.html#links) is internal or external to your GitLab instance.
As of GitLab 15.9, we treat all release links as external, and therefore, this field is deprecated in GitLab 15.9, and will be removed in GitLab 16.0.
To avoid any disruptions to your workflow, please stop using the `external` field because it will be removed and will not be replaced.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### External field in Releases and Release Links APIs

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

In [Releases API](https://docs.gitlab.com/ee/api/releases/) and [Release Links API](https://docs.gitlab.com/ee/api/releases/links.html), the `external` field was used to indicate whether a [release link](https://docs.gitlab.com/ee/user/project/releases/release_fields.html#links) is internal or external to your GitLab instance.
As of GitLab 15.9, we treat all release links as external, and therefore, this field is deprecated in GitLab 15.9, and will be removed in GitLab 16.0.
To avoid any disruptions to your workflow, please stop using the `external` field because it will be removed and will not be replaced.

</div>

<div class="deprecation " data-milestone="16.0">

### Geo: Project repository redownload is deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.11</span>
</div>

In secondary Geo sites, the button to "Redownload" a project repository is
deprecated. The redownload logic has inherent data consistency issues which
are difficult to resolve when encountered. The button will be removed in
GitLab 16.0.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### GitLab self-monitoring project

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

GitLab self-monitoring gives administrators of self-hosted GitLab instances the tools to monitor the health of their instances. This feature is deprecated in GitLab 14.9, and is scheduled for removal in 16.0.

</div>

<div class="deprecation " data-milestone="16.0">

### GitLab.com importer

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
</div>

The [GitLab.com importer](https://docs.gitlab.com/ee/user/project/import/gitlab_com.html) is deprecated in GitLab 15.8 and will be removed in GitLab 16.0.

The GitLab.com importer was introduced in 2015 for importing a project from GitLab.com to a self-managed GitLab instance through the UI.
This feature is available on self-managed instances only. [Migrating GitLab groups and projects by direct transfer](https://docs.gitlab.com/ee/user/group/import/#migrate-groups-by-direct-transfer-recommended)
supersedes the GitLab.com importer and provides a more cohesive importing functionality.

See [migrated group items](https://docs.gitlab.com/ee/user/group/import/#migrated-group-items) and [migrated project items](https://docs.gitlab.com/ee/user/group/import/#migrated-project-items) for an overview.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### GraphQL API Runner status will not return `paused`

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.5</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The GitLab Runner GraphQL API endpoints will not return `paused` or `active` as a status in GitLab 16.0.
In a future v5 of the REST API, the endpoints for GitLab Runner will also not return `paused` or `active`.

A runner's status will only relate to runner contact status, such as:
`online`, `offline`, or `not_connected`. Status `paused` or `active` will no longer appear.

When checking if a runner is `paused`, API users are advised to check the boolean attribute
`paused` to be `true` instead. When checking if a runner is `active`, check if `paused` is `false`.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### GraphQL API legacyMode argument for Runner status

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.0</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The `legacyMode` argument to the `status` field in `RunnerType` will be rendered non-functional in the 16.0 release
as part of the deprecations details in the [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/351109).

In GitLab 16.0 and later, the `status` field will act as if `legacyMode` is null. The `legacyMode` argument will
be present during the 16.x cycle to avoid breaking the API signature, and will be removed altogether in the
17.0 release.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### GraphQL field `confidential` changed to `internal` on notes

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.5</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The `confidential` field for a `Note` will be deprecated and renamed to `internal`.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### HashiCorp Vault integration will no longer use CI_JOB_JWT by default

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

As part of our effort to improve the security of your CI workflows using JWT and OIDC, the native HashiCorp integration is also being updated in GitLab 16.0. Any projects that use the [`secrets:vault`](https://docs.gitlab.com/ee/ci/yaml/#secretsvault) keyword to retrieve secrets from Vault will need to be [configured to use ID tokens](https://docs.gitlab.com/ee/ci/secrets/id_token_authentication.html#configure-automatic-id-token-authentication).

To be prepared for this change, you should do the following before GitLab 16.0:

- [Disable the use of JSON web tokens](https://docs.gitlab.com/ee/ci/secrets/id_token_authentication.html#enable-automatic-id-token-authentication) in the pipeline.
- Ensure the bound audience is prefixed with `https://`.
- Use the new [`id_tokens`](https://docs.gitlab.com/ee/ci/yaml/#id_tokens) keyword
  and configure the `aud` claim.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Jira DVCS connector for Jira Cloud

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.1</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The [Jira DVCS connector](https://docs.gitlab.com/ee/integration/jira/dvcs/) for Jira Cloud has been deprecated and will be removed in GitLab 16.0. If you're using the Jira DVCS connector with Jira Cloud, migrate to the [GitLab for Jira Cloud app](https://docs.gitlab.com/ee/integration/jira/connect-app.html).

The Jira DVCS connector is also deprecated for Jira 8.13 and earlier. You can only use the Jira DVCS connector with Jira Server or Jira Data Center in Jira 8.14 and later.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### KAS Metrics Port in GitLab Helm Chart

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.7</span>
- End of Support: GitLab <span class="milestone">16.0</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The `gitlab.kas.metrics.port` has been deprecated in favor of the new `gitlab.kas.observability.port` configuration field for the [GitLab Helm Chart](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/2839).
This port is used for much more than just metrics, which warranted this change to avoid confusion in configuration.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Legacy Gitaly configuration method

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.10</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Gitaly configuration within Omnibus GitLab has been updated such that all Gitaly related configuration keys are in a single
configuration structure that matches the standard Gitaly configuration. As such, the previous configuration structure is deprecated.

The single configuration structure is available from GitLab 15.10, though backwards compatibility is maintained. Once removed, Gitaly must be configured using the single
configuration structure. You should update the configuration of Gitaly at your earliest convenience.

The change improves consistency between Omnibus GitLab and source installs and enables us to provide better documentation and tooling for both.

You should update to the new configuration structure as soon as possible using
[the upgrade instructions](https://docs.gitlab.com/ee/update/#gitaly-omnibus-gitlab-configuration-structure-change).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Legacy Praefect configuration method

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Previously, Praefect configuration keys were scattered throughout the configuration file. Now, these are in a single configuration structure that matches
Praefect configuration so the previous configuration method is deprecated.

The single configuration structure available from GitLab 15.9, though backwards compatibility is maintained. Once removed, Praefect must be configured using the single
configuration structure. You should update your Praefect configuration as soon as possible using
[the upgrade instructions](https://docs.gitlab.com/ee/update/#praefect-omnibus-gitlab-configuration-structure-change).

This change brings Praefect configuration in Omnibus GitLab in line with the configuration structure of Praefect. Previously, the hierarchies and configuration keys
didn't match. The change improves consistency between Omnibus GitLab and source installs and enables us to provide better documentation and tooling for both.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Legacy URLs replaced or removed

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

GitLab 16.0 removes legacy URLs from the GitLab application.

When subgroups were introduced in GitLab 9.0, a `/-/` delimiter was added to URLs to signify the end of a group path. All GitLab URLs now use this delimiter for project, group, and instance level features.

URLs that do not use the `/-/` delimiter are planned for removal in GitLab 16.0. For the full list of these URLs, along with their replacements, see [issue 28848](https://gitlab.com/gitlab-org/gitlab/-/issues/28848#release-notes).

Update any scripts or bookmarks that reference the legacy URLs. GitLab APIs are not affected by this change.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### License Compliance CI Template

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The GitLab [License Compliance](https://docs.gitlab.com/ee/user/compliance/license_compliance/) CI template is now deprecated and is scheduled for removal in the GitLab 16.0 release. Users who wish to continue using GitLab for License Compliance should remove the License Compliance template from their CI pipeline and add the [Dependency Scanning template](https://docs.gitlab.com/ee/user/application_security/dependency_scanning/#configuration). The Dependency Scanning template is now capable of gathering the required license information so it is no longer necessary to run a separate License Compliance job. The License Compliance CI template should not be removed prior to verifying that the `license_scanning_sbom_scanner` and `package_metadata_synchronization` flags are enabled for the instance and that the instance has been upgraded to a version that supports [the new method of license scanning](https://docs.gitlab.com/ee/user/compliance/license_scanning_of_cyclonedx_files/).

| CI Pipeline Includes | GitLab <= 15.8 | 15.9 <= GitLab < 16.0 | GitLab >= 16.0 |
| ------------- | ------------- | ------------- | ------------- |
| Both DS and LS templates | License data from LS job is used | License data from LS job is used | License data from DS job is used |
| DS template is included but LS template is not | No license data | License data from DS job is used | License data from DS job is used |
| LS template is included but DS template is not | License data from LS job is used | License data from LS job is used | No license data |

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### License-Check and the Policies tab on the License Compliance page

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The [License-Check feature](https://docs.gitlab.com/ee/user/compliance/license_check_rules.html) is now deprecated and is scheduled for removal in GitLab 16.0. Additionally, the Policies tab on the License Compliance page and all APIs related to the License-Check feature are deprecated and planned for removal in GitLab 16.0. Users who wish to continue to enforce approvals based on detected licenses are encouraged to create a new [License Approval policy](https://docs.gitlab.com/ee/user/compliance/license_approval_policies.html) instead.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Limit personal access token and deploy token's access with external authorization

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

With external authorization enabled, personal access tokens (PATs) and deploy tokens must no longer be able to access container or package registries. This defense-in-depth security measure will be deployed in 16.0. For users that use PATs and deploy tokens to access these registries, this measure breaks this use of these tokens. Disable external authorization to use tokens with container or package registries.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Maintainer role providing the ability to change Package settings using GraphQL API

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The ability for users with the Maintainer role to change the **Packages and registries** settings for a group using
the GraphQL API is deprecated in GitLab 15.8 and will be removed in GitLab 16.0. These settings include:

- [Allowing or preventing duplicate package uploads](https://docs.gitlab.com/ee/user/packages/maven_repository/#do-not-allow-duplicate-maven-packages).
- [Package request forwarding](https://docs.gitlab.com/ee/user/packages/maven_repository/#request-forwarding-to-maven-central).
- [Enabling lifecycle rules for the Dependency Proxy](https://docs.gitlab.com/ee/user/packages/dependency_proxy/reduce_dependency_proxy_storage.html).

In GitLab 16.0 and later, you must have Owner role for a group to change the **Packages and registries**
settings for the group using either the GitLab UI or GraphQL API.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Major bundled Helm Chart updates for the GitLab Helm Chart

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.10</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

To coincide with GitLab 16.0, the GitLab Helm Chart will release the 7.0 major version. The following major bundled chart updates will be included:

- In GitLab 16.0, [PostgreSQL 12 support is being removed, and PostgreSQL 13 is becoming the new minimum](#postgresql-12-deprecated).
  - Installs using production-ready external databases will need to complete their migration to a newer PostgreSQL version before upgrading.
  - Installs using the [non-production bundled PostgreSQL 12 chart](https://docs.gitlab.com/charts/installation/tools.html#postgresql) will have the chart upgraded to the new version. For more information, [see issue 4118](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/4118)
- Installs using the [non-production bundled Redis chart](https://docs.gitlab.com/charts/installation/tools.html#redis) will have the chart upgraded to a newer version. For more information, [see issue 3375](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3375)
- Installs using the [bundled cert-manager chart](https://docs.gitlab.com/charts/installation/tls.html#option-1-cert-manager-and-lets-encrypt) will have the chart upgraded to a newer version. For more information, [see issue 4313](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/4313)

The full GitLab Helm Chart 7.0 upgrade steps will be available in the [upgrade docs](https://docs.gitlab.com/charts/installation/upgrade.html).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Managed Licenses API

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The [Managed Licenses API](https://docs.gitlab.com/ee/api/managed_licenses.html) is now deprecated and is scheduled for removal in GitLab 16.0.

</div>

<div class="deprecation " data-milestone="16.0">

### Maximum number of active pipelines per project limit (`ci_active_pipelines`)

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.3</span>
</div>

The [**Maximum number of active pipelines per project** limit](https://docs.gitlab.com/ee/user/admin_area/settings/continuous_integration.html#set-cicd-limits) was never enabled by default and will be removed in GitLab 16.0. This limit can also be configured in the Rails console under [`ci_active_pipelines`](https://docs.gitlab.com/ee/administration/instance_limits.html#number-of-pipelines-running-concurrently). Instead, use the other recommended rate limits that offer similar protection:

- [**Pipelines rate limits**](https://docs.gitlab.com/ee/user/admin_area/settings/rate_limit_on_pipelines_creation.html).
- [**Total number of jobs in currently active pipelines**](https://docs.gitlab.com/ee/user/admin_area/settings/continuous_integration.html#set-cicd-limits).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Monitor performance metrics through Prometheus

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.7</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

By displaying data stored in a Prometheus instance, GitLab allows users to view performance metrics. GitLab also displays visualizations of these metrics in dashboards. The user can connect to a previously-configured external Prometheus instance, or set up Prometheus as a GitLab Managed App.
However, since certificate-based integration with Kubernetes clusters is deprecated in GitLab, the metrics functionality in GitLab that relies on Prometheus is also deprecated. This includes the metrics visualizations in dashboards. GitLab is working to develop a single user experience based on [Opstrace](https://about.gitlab.com/press/releases/2021-12-14-gitlab-acquires-opstrace-to-expand-its-devops-platform-with-open-source-observability-solution.html). An [issue exists](https://gitlab.com/groups/gitlab-org/-/epics/6976) for you to follow work on the Opstrace integration.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Non-expiring access tokens

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.4</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Access tokens that have no expiration date are valid indefinitely, which presents a security risk if the access token
is divulged. Because access tokens that have an exipiration date are better, from GitLab 15.3 we
[populate a default expiration date](https://gitlab.com/gitlab-org/gitlab/-/issues/348660).

In GitLab 16.0, any [personal](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html),
[project](https://docs.gitlab.com/ee/user/project/settings/project_access_tokens.html), or
[group](https://docs.gitlab.com/ee/user/group/settings/group_access_tokens.html) access token that does not have an
expiration date will automatically have an expiration date set at one year.

We recommend giving your access tokens an expiration date in line with your company's security policies before the
default is applied:

- On GitLab.com during the 16.0 milestone.
- On GitLab self-managed instances when they are upgraded to 16.0.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Non-standard default Redis ports are deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

If GitLab starts without any Redis configuration file present,
GitLab assumes it can connect to three Redis servers at `localhost:6380`,
`localhost:6381` and `localhost:6382`. We are changing this behavior
so GitLab assumes there is one Redis server at `localhost:6379`.

Administrators who want to keep the three servers must configure
the Redis URLs by editing the `config/redis.cache.yml`,`config/redis.queues.yml`
and `config/redis.shared_state.yml` files.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Option to delete projects immediately is deprecated from deletion protection settings

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The group and project deletion protection setting in the Admin Area had an option to delete groups and projects immediately. Starting with 16.0, this option will no longer be available, and delayed group and project deletion will become the default behavior.

The option will no longer appear as a group setting. Self-managed users will still have the option to define the deletion delay period, and SaaS users have a non-adjustable default retention period of 7 days. Users can still immediately delete the project from the project settings, and the group from the group settings.

The option to delete groups and projects immediately by default was deprecated to prevent users from accidentally taking this action and permanently losing groups and projects.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Package pipelines in API payload is paginated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.5</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

A request to the API for `/api/v4/projects/:id/packages` returns a paginated result of packages. Each package lists all of its pipelines in this response. This is a performance concern, as it's possible for a package to have hundreds or thousands of associated pipelines.

In milestone 16.0, we will remove the `pipelines` attribute from the API response.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### PipelineSecurityReportFinding name GraphQL field

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.1</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Previously, the [PipelineSecurityReportFinding GraphQL type was updated](https://gitlab.com/gitlab-org/gitlab/-/issues/335372) to include a new `title` field. This field is an alias for the current `name` field, making the less specific `name` field redundant. The `name` field will be removed from the PipelineSecurityReportFinding type in GitLab 16.0.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### PipelineSecurityReportFinding projectFingerprint GraphQL field

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.1</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The [`project_fingerprint`](https://gitlab.com/groups/gitlab-org/-/epics/2791) attribute of vulnerability findings is being deprecated in favor of a `uuid` attribute. By using UUIDv5 values to identify findings, we can easily associate any related entity with a finding. The `project_fingerprint` attribute is no longer being used to track findings, and will be removed in GitLab 16.0.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### PostgreSQL 12 deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.0</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Support for PostgreSQL 12 is scheduled for removal in GitLab 16.0.
In GitLab 16.0, PostgreSQL 13 becomes the minimum required PostgreSQL version.

PostgreSQL 12 will be supported for the full GitLab 15 release cycle.
PostgreSQL 13 will also be supported for instances that want to upgrade prior to GitLab 16.0.

Support for PostgreSQL 13 was added to Geo in GitLab 15.2.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Projects API field `operations_access_level` is deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

We are deprecating the `operations_access_level` field in the Projects API. This field has been replaced by fields to control specific features: `releases_access_level`, `environments_access_level`, `feature_flags_access_level`, `infrastructure_access_level`, and `monitor_access_level`.

</div>

<div class="deprecation " data-milestone="16.0">

### Rake task for importing bare repositories

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
</div>

The [Rake task for importing bare repositories](https://docs.gitlab.com/ee/raketasks/import.html) `gitlab:import:repos` is deprecated in GitLab 15.8 and will be removed in GitLab 16.0.

This Rake task imports a directory tree of repositories into a GitLab instance. These repositories must have been
managed by GitLab previously, because the Rake task relies on the specific directory structure or a specific custom Git setting in order to work (`gitlab.fullpath`).

Importing repositories using this Rake task has limitations. The Rake task:

- Only knows about project and project wiki repositories and doesn't support repositories for designs, group wikis, or snippets.
- Permits you to import non-hashed storage projects even though these aren't supported.
- Relies on having Git config `gitlab.fullpath` set. [Epic 8953](https://gitlab.com/groups/gitlab-org/-/epics/8953) proposes removing support for this setting.

Alternatives to using the `gitlab:import:repos` Rake task include:

- Migrating projects using either [an export file](https://docs.gitlab.com/ee/user/project/settings/import_export.html) or
  [direct transfer](https://docs.gitlab.com/ee/user/group/import/#migrate-groups-by-direct-transfer-recommended) migrate repositories as well.
- Importing a [repository by URL](https://docs.gitlab.com/ee/user/project/import/repo_by_url.html).
- Importing a [repositories from a non-GitLab source](https://docs.gitlab.com/ee/user/project/import/).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Redis 5 deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.3</span>
- End of Support: GitLab <span class="milestone">15.6</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

With GitLab 13.9, in the Omnibus GitLab package and GitLab Helm chart 4.9, the Redis version [was updated to Redis 6](https://about.gitlab.com/releases/2021/02/22/gitlab-13-9-released/#omnibus-improvements).
Redis 5 has reached the end of life in April 2022 and will no longer be supported as of GitLab 15.6.
If you are using your own Redis 5.0 instance, you should upgrade it to Redis 6.0 or higher before upgrading to GitLab 16.0 or higher.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Remove `job_age` parameter from `POST /jobs/request` Runner endpoint

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.2</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The `job_age` parameter, returned from the `POST /jobs/request` API endpoint used in communication with GitLab Runner, was never used by any GitLab or Runner feature. This parameter will be removed in GitLab 16.0.

This could be a breaking change for anyone that developed their own runner that relies on this parameter being returned by the endpoint. This is not a breaking change for anyone using an officially released version of GitLab Runner, including public shared runners on GitLab.com.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### SAST analyzer coverage changing in GitLab 16.0

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

GitLab SAST uses various [analyzers](https://docs.gitlab.com/ee/user/application_security/sast/analyzers/) to scan code for vulnerabilities.

We're reducing the number of supported analyzers used by default in GitLab SAST.
This is part of our long-term strategy to deliver a faster, more consistent user experience across different programming languages.

Starting in GitLab 16.0, the GitLab SAST CI/CD template will no longer use the following analyzers, and they will enter End of Support status:

- [Security Code Scan](https://gitlab.com/gitlab-org/security-products/analyzers/security-code-scan) (.NET)
- [PHPCS Security Audit](https://gitlab.com/gitlab-org/security-products/analyzers/phpcs-security-audit) (PHP)

We'll remove these analyzers from the [SAST CI/CD template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml) and replace them with GitLab-supported detection rules and the [Semgrep-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep).
Effective immediately, these analyzers will receive only security updates; other routine improvements or updates are not guaranteed.
After these analyzers reach End of Support, no further updates will be provided.
However, we won't delete container images previously published for these analyzers or remove the ability to run them by using a custom CI/CD pipeline job.

We will also remove Scala from the scope of the [SpotBugs-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs) and replace it with the [Semgrep-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep).
This change will make it simpler to scan Scala code; compilation will no longer be required.
This change will be reflected in the automatic language detection portion of the [GitLab-managed SAST CI/CD template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml).
Note that the SpotBugs-based analyzer will continue to cover Groovy and Kotlin.

If you've already dismissed a vulnerability finding from one of the deprecated analyzers, the replacement attempts to respect your previous dismissal. The system behavior depends on:

- whether you've excluded the Semgrep-based analyzer from running in the past.
- which analyzer first discovered the vulnerabilities shown in the project's Vulnerability Report.

See [Vulnerability translation documentation](https://docs.gitlab.com/ee/user/application_security/sast/analyzers.html#vulnerability-translation) for further details.

If you applied customizations to any of the affected analyzers or if you currently disable the Semgrep analyzer in your pipelines, you must take action as detailed in the [deprecation issue for this change](https://gitlab.com/gitlab-org/gitlab/-/issues/390416#breaking-change).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Secure analyzers major version update

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The Secure stage will be bumping the major versions of its analyzers in tandem with the GitLab 16.0 release. This bump will enable a clear delineation for analyzers, between:

- Those released prior to May 22, 2023
- Those released after May 22, 2023

If you are not using the default included templates, or have pinned your analyzer versions you will need to update your CI/CD job definition to either remove the pinned version or to update the latest major version.
Users of GitLab 13.0-15.10 will continue to experience analyzer updates as normal until the release of GitLab 16.0, following which all newly fixed bugs and released features will be released only in the new major version of the analyzers. We do not backport bugs and features to deprecated versions as per our [maintenance policy](https://docs.gitlab.com/ee/policy/maintenance.html). As required, security patches will be backported within the latest 3 minor releases.
Specifically, the following are being deprecated and will no longer be updated after 16.0 GitLab release:

- API Fuzzing: version 2
- Container Scanning: version 5
- Coverage-guided fuzz testing: version 3
- Dependency Scanning: version 3
- Dynamic Application Security Testing (DAST): version 3
- DAST API: version 2
- IaC Scanning: version 3
- License Scanning: version 4
- Secret Detection: version 4
- Static Application Security Testing (SAST): version 3 of [all analyzers](https://docs.gitlab.com/ee/user/application_security/sast/#supported-languages-and-frameworks)
  - `brakeman`: version 3
  - `flawfinder`: version 3
  - `kubesec`: version 3
  - `mobsf`: version 3
  - `nodejs-scan`: version 3
  - `phpcs-security-audit`: version 3
  - `pmd-apex`: version 3
  - `security-code-scan`: version 3
  - `semgrep`: version 3
  - `sobelow`: version 3
  - `spotbugs`: version 3

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Secure scanning CI/CD templates will use new job `rules`

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

GitLab-managed CI/CD templates for security scanning will be updated in the GitLab 16.0 release.
The updates will include improvements already released in the Latest versions of the CI/CD templates.
We released these changes in the Latest template versions because they have the potential to disrupt customized CI/CD pipeline configurations.

In all updated templates, we're:

- Adding support for running scans in merge request (MR) pipelines.
- Updating the definition of variables like `SAST_DISABLED` and `DEPENDENCY_SCANNING_DISABLED` to disable scanning only if the value is `"true"`. Previously, even if the value were `"false"`, scanning would be disabled.

The following templates will be updated:

- API Fuzzing: [`API-Fuzzing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml)
- Container Scanning: [`Container-Scanning.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Container-Scanning.gitlab-ci.yml)
- Coverage-Guided Fuzzing: [`Coverage-Fuzzing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/Coverage-Fuzzing.gitlab-ci.yml)
- DAST: [`DAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST.gitlab-ci.yml)
- DAST API: [`DAST-API.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST-API.gitlab-ci.yml)
- Dependency Scanning: [`Dependency-Scanning.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.gitlab-ci.yml)
- IaC Scanning: [`SAST-IaC.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST-IaC.gitlab-ci.yml)
- SAST: [`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml)
- Secret Detection: [`Secret-Detection.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Secret-Detction.gitlab-ci.yml)

We recommend that you test your pipelines before the 16.0 release if you use one of the templates listed above and you do any of the following:

  1. You override `rules` for your security scanning jobs.
  1. You use the `_DISABLED` variables but set a value other than `"true"`.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Security report schemas version 14.x.x

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.3</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Version 14.x.x [security report schemas](https://gitlab.com/gitlab-org/security-products/security-report-schemas) are deprecated.

In GitLab 15.8 and later, [security report scanner integrations](https://docs.gitlab.com/ee/development/integrations/secure.html) that use schema version 14.x.x will display a deprecation warning in the pipeline's **Security** tab.

In GitLab 16.0 and later, the feature will be removed. Security reports that use schema version 14.x.x will cause an error in the pipeline's **Security** tab.

For more information, refer to [security report validation](https://docs.gitlab.com/ee/user/application_security/#security-report-validation).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Shimo integration

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.7</span>
- End of Support: GitLab <span class="milestone">16.0</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The [Shimo Workspace integration](https://docs.gitlab.com/ee/user/project/integrations/shimo.html) has been deprecated
and will be moved to the JiHu GitLab codebase.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Starboard directive in the config for the GitLab Agent for Kubernetes

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.4</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

GitLab's operational container scanning capabilities no longer require starboard to be installed. Consequently, use of the `starboard:` directive in the configuration file for the GitLab Agent for Kubernetes is now deprecated and is scheduled for removal in GitLab 16.0. Update your configuration file to use the `container_scanning:` directive.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Support for Praefect custom metrics endpoint configuration

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Support for using the `prometheus_exclude_database_from_default_metrics` configuration value is deprecated in GitLab
15.9 and will be removed in GitLab 16.0. We are removing this configuration value because using it is non-performant.
This change means the following metrics will become unavailable on `/metrics`:

- `gitaly_praefect_unavailable_repositories`.
- `gitaly_praefect_verification_queue_depth`.
- `gitaly_praefect_replication_queue_depth`.

This may require updating your metrics collection targets to also scrape `/db_metrics`.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Support for periods (`.`) in Terraform state names might break existing states

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.7</span>
- End of Support: GitLab <span class="milestone">16.0</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Previously, Terraform state names containing periods were not supported. However, you could still use state names with periods via a workaround.

GitLab 15.7 [adds full support](https://docs.gitlab.com/ee/user/infrastructure/iac/troubleshooting.html#state-not-found-if-the-state-name-contains-a-period) for state names that contain periods. If you used a workaround to handle these state names, your jobs might fail, or it might look like you've run Terraform for the first time.

To resolve the issue:

  1. Change any references to the state file by excluding the period and any characters that follow.
     - For example, if your state name is `state.name`, change all references to `state`.
  1. Run your Terraform commands.

To use the full state name, including the period, [migrate to the full state file](https://docs.gitlab.com/ee/user/infrastructure/iac/terraform_state.html#migrate-to-a-gitlab-managed-terraform-state).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### The API no longer returns revoked tokens for the agent for Kubernetes

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Currently, GET requests to the [Cluster Agents API](https://docs.gitlab.com/ee/api/cluster_agents.html#list-tokens-for-an-agent)
endpoints can return revoked tokens. In GitLab 16.0, GET requests will not return revoked tokens.

You should review your calls to these endpoints and ensure you do not use revoked tokens.

This change affects the following REST and GraphQL API endpoints:

- REST API:
  - [List tokens](https://docs.gitlab.com/ee/api/cluster_agents.html#list-tokens-for-an-agent)
  - [Get a single token](https://docs.gitlab.com/ee/api/cluster_agents.html#get-a-single-agent-token)
- GraphQL:
  - [`ClusterAgent.tokens`](https://docs.gitlab.com/ee/api/graphql/reference/#clusteragenttokens)

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### The Phabricator task importer is deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.7</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The [Phabricator task importer](https://docs.gitlab.com/ee/user/project/import/phabricator.html) is being deprecated. Phabricator itself as a project is no longer actively maintained since June 1, 2021. We haven't observed imports using this tool. There has been no activity on the open related issues on GitLab.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### The latest Terraform templates will overwrite current stable templates

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

With every major GitLab version, we update the stable Terraform templates with the current latest templates.
This change affects the [quickstart](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform.gitlab-ci.yml)
and the [base](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform/Base.gitlab-ci.yml) templates.

Because the new templates ship with default rules, the update might break your Terraform pipelines.
For example, if your Terraform jobs are triggered as a downstream pipeline, the rules won't trigger your jobs
in GitLab 16.0.

To accommodate the changes, you might need to adjust the [`rules`](https://docs.gitlab.com/ee/ci/yaml/#rules) in your
`.gitlab-ci.yml` file.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Toggle behavior of `/draft` quick action in merge requests

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.4</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

In order to make the behavior of toggling the draft status of a merge request more clear via a quick action, we're deprecating and removing the toggle behavior of the `/draft` quick action. Beginning with the 16.0 release of GitLab, `/draft` will only set a merge request to Draft and a new `/ready` quick action will be used to remove the draft status.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Toggle notes confidentiality on APIs

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.10</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Toggling notes confidentiality with REST and GraphQL APIs is being deprecated. Updating notes confidential attribute is no longer supported by any means. We are changing this to simplify the experience and prevent private information from being unintentionally exposed.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Use of `id` field in vulnerabilityFindingDismiss mutation

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.3</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

You can use the vulnerabilityFindingDismiss GraphQL mutation to set the status of a vulnerability finding to `Dismissed`. Previously, this mutation used the `id` field to identify findings uniquely. However, this did not work for dismissing findings from the pipeline security tab. Therefore, using the `id` field as an identifier has been dropped in favor of the `uuid` field. Using the 'uuid' field as an identifier allows you to dismiss the finding from the pipeline security tab.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Use of third party container registries is deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- End of Support: GitLab <span class="milestone">16.0</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Using third-party container registries is deprecated in GitLab 15.8 and the end of support is scheduled for GitLab 16.0. Supporting both GitLab's Container Registry and third-party container registries is challenging for maintenance, code quality, and backward compatibility. This hinders our ability to stay [efficient](https://about.gitlab.com/handbook/values/#efficiency).

Since we released the new [GitLab Container Registry](https://gitlab.com/groups/gitlab-org/-/epics/5523) version for GitLab.com, we've started to implement additional features that are not available in third-party container registries. These new features have allowed us to achieve significant performance improvements, such as [cleanup policies](https://gitlab.com/groups/gitlab-org/-/epics/8379). We are focusing on delivering [new features](https://gitlab.com/groups/gitlab-org/-/epics/5136), most of which will require functionalities only available on the GitLab Container Registry. This deprecation allows us to reduce fragmentation and user frustration in the long term by focusing on delivering a more robust integrated registry experience and feature set.

Moving forward, we'll continue to invest in developing and releasing new features that will only be available in the GitLab Container Registry.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Vulnerability confidence field

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.4</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

In GitLab 15.3, [security report schemas below version 15 were deprecated](https://docs.gitlab.com/ee/update/deprecations.html#security-report-schemas-version-14xx).
The `confidence` attribute on vulnerability findings exists only in schema versions before `15-0-0`, and therefore is effectively deprecated since GitLab 15.4 supports schema version `15-0-0`. To maintain consistency
between the reports and our public APIs, the `confidence` attribute on any vulnerability-related components of our GraphQL API is now deprecated and will be
removed in 16.0.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Work items path with global ID at the end of the path is deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.10</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Usage of global IDs in work item URLs is deprecated. In the future, only internal IDs (IID) will be supported.

Because GitLab supports multiple work item types, a path such as `https://gitlab.com/gitlab-org/gitlab/-/work_items/<global_id>` can display, for example, a [task](https://docs.gitlab.com/ee/user/tasks.html) or an [OKR](https://docs.gitlab.com/ee/user/okrs.html).

In GitLab 15.10 we added support for using internal IDs (IID) in that path by appending a query param at
the end (`iid_path`) in the following format: `https://gitlab.com/gitlab-org/gitlab/-/work_items/<iid>?iid_path=true`.

In GitLab 16.0 we will remove the ability to use a global ID in the work items path. The number at the end of the path will be considered an internal ID (IID) without the need of adding a query param at the end. Only the following format will be supported: `https://gitlab.com/gitlab-org/gitlab/-/work_items/<iid>`.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### ZenTao integration

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.7</span>
- End of Support: GitLab <span class="milestone">16.0</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The [ZenTao product integration](https://docs.gitlab.com/ee/user/project/integrations/zentao.html) has been deprecated
and will be moved to the JiHu GitLab codebase.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### `CI_BUILD_*` predefined variables

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The predefined CI/CD variables that start with `CI_BUILD_*` were deprecated in GitLab 9.0, and will be removed in GitLab 16.0. If you still use these variables, be sure to change to the replacement [predefined variables](https://docs.gitlab.com/ee/ci/variables/predefined_variables.html) which are functionally identical:

| Removed variable      | Replacement variable    |
| --------------------- |------------------------ |
| `CI_BUILD_BEFORE_SHA` | `CI_COMMIT_BEFORE_SHA`  |
| `CI_BUILD_ID`         | `CI_JOB_ID`             |
| `CI_BUILD_MANUAL`     | `CI_JOB_MANUAL`         |
| `CI_BUILD_NAME`       | `CI_JOB_NAME`           |
| `CI_BUILD_REF`        | `CI_COMMIT_SHA`         |
| `CI_BUILD_REF_NAME`   | `CI_COMMIT_REF_NAME`    |
| `CI_BUILD_REF_SLUG`   | `CI_COMMIT_REF_SLUG`    |
| `CI_BUILD_REPO`       | `CI_REPOSITORY_URL`     |
| `CI_BUILD_STAGE`      | `CI_JOB_STAGE`          |
| `CI_BUILD_TAG`        | `CI_COMMIT_TAG`         |
| `CI_BUILD_TOKEN`      | `CI_JOB_TOKEN`          |
| `CI_BUILD_TRIGGERED`  | `CI_PIPELINE_TRIGGERED` |

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### `POST ci/lint` API endpoint deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.7</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The `POST ci/lint` API endpoint is deprecated in 15.7, and will be removed in 16.0. This endpoint does not validate the full range of CI/CD configuration options. Instead, use [`POST /projects/:id/ci/lint`](https://docs.gitlab.com/ee/api/lint.html#validate-a-ci-yaml-configuration-with-a-namespace), which properly validates CI/CD configuration.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### `environment_tier` parameter for DORA API

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

To avoid confusion and duplication, the `environment_tier` parameter is deprecated in favor of the `environment_tiers` parameter. The new `environment_tiers` parameter allows DORA APIs to return aggregated data for multiple tiers at the same time. The `environment_tier` parameter will be removed in GitLab 16.0.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### project.pipeline.securityReportFindings GraphQL query

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.1</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Previous work helped [align the vulnerabilities calls for pipeline security tabs](https://gitlab.com/gitlab-org/gitlab/-/issues/343469) to match the vulnerabilities calls for project-level and group-level vulnerability reports. This helped the frontend have a more consistent interface. The old `project.pipeline.securityReportFindings` query was formatted differently than other vulnerability data calls. Now that it has been replaced with the new `project.pipeline.vulnerabilities` field, the old `project.pipeline.securityReportFindings` is being deprecated and will be removed in GitLab 16.0.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### vulnerabilityFindingDismiss GraphQL mutation

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.5</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The `VulnerabilityFindingDismiss` GraphQL mutation is being deprecated and will be removed in GitLab 16.0. This mutation was not used often as the Vulnerability Finding ID was not available to users (this field was [deprecated in 15.3](https://docs.gitlab.com/ee/update/deprecations.html#use-of-id-field-in-vulnerabilityfindingdismiss-mutation)). Users should instead use `VulnerabilityDismiss` to dismiss vulnerabilities in the Vulnerability Report or `SecurityFindingDismiss` for security findings in the CI Pipeline Security tab.

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.11">

## GitLab 15.11

<div class="deprecation " data-milestone="15.11">

### openSUSE Leap 15.3 packages

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
</div>

Distribution support and security updates for openSUSE Leap 15.3 [ended December 2022](https://en.opensuse.org/Lifetime#Discontinued_distributions).

Starting in GitLab 15.7 we started providing packages for openSUSE Leap 15.4, and will stop providing packages for openSUSE Leap 15.3 in the 15.11 milestone.

- Switch from the openSUSE Leap 15.3 packages to the provided 15.4 packages.

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.10">

## GitLab 15.10

<div class="deprecation breaking-change" data-milestone="15.10">

### Automatic backup upload using Openstack Swift and Rackspace APIs

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- End of Support: GitLab <span class="milestone">15.10</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

We are deprecating support for [uploading backups to remote storage](https://docs.gitlab.com/ee/raketasks/backup_gitlab.html#upload-backups-to-a-remote-cloud-storage) using Openstack Swift and Rackspace APIs. The support for these APIs depends on third-party libraries that are no longer actively maintained and have not been updated for  Ruby 3. GitLab is switching over to Ruby 3 prior to EOL of Ruby 2 in order to stay up to date on security patches.

- If you're using OpenStack, you need to change you configuration to use the S3 API instead of Swift.
- If you're using Rackspace storage, you need to switch to a different provider or manually upload the backup file after the backup task is complete.

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.9">

## GitLab 15.9

<div class="deprecation breaking-change" data-milestone="15.9">

### Live Preview no longer available in the Web IDE

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The Live Preview feature of the Web IDE was intended to provide a client-side preview of static web applications. However, complex configuration steps and a narrow set of supported project types have limited its utility. With the introduction of the Web IDE Beta in GitLab 15.7, you can now connect to a full server-side runtime environment. With upcoming support for installing extensions in the Web IDE, we'll also support more advanced workflows than those available with Live Preview. As of GitLab 15.9, Live Preview is no longer available in the Web IDE.

</div>

<div class="deprecation breaking-change" data-milestone="15.9">

### SaaS certificate-based integration with Kubernetes

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.5</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The certificate-based integration with Kubernetes will be [deprecated and removed](https://about.gitlab.com/blog/2021/11/15/deprecating-the-cert-based-kubernetes-integration/). As a GitLab SaaS customer, on new namespaces, you will no longer be able to integrate GitLab and your cluster using the certificate-based approach as of GitLab 15.0. The integration for current users will be enabled per namespace.

For a more robust, secure, forthcoming, and reliable integration with Kubernetes, we recommend you use the
[agent for Kubernetes](https://docs.gitlab.com/ee/user/clusters/agent/) to connect Kubernetes clusters with GitLab. [How do I migrate?](https://docs.gitlab.com/ee/user/infrastructure/clusters/migrate_to_gitlab_agent.html)

Although an explicit removal date is set, we don't plan to remove this feature until the new solution has feature parity.
For more information about the blockers to removal, see [this issue](https://gitlab.com/gitlab-org/configure/general/-/issues/199).

For updates and details about this deprecation, follow [this epic](https://gitlab.com/groups/gitlab-org/configure/-/epics/8).

GitLab self-managed customers can still use the feature [with a feature flag](https://docs.gitlab.com/ee/update/deprecations.html#self-managed-certificate-based-integration-with-kubernetes).

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.7">

## GitLab 15.7

<div class="deprecation breaking-change" data-milestone="15.7">

### File Type variable expansion in `.gitlab-ci.yml`

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.5</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Previously, variables that referenced or applied alias file variables expanded the value of the `File` type variable. For example, the file contents. This behavior was incorrect because it did not comply with typical shell variable expansion rules. To leak secrets or sensitive information stored in `File` type variables, a user could run an $echo command with the variable as an input parameter.

This breaking change fixes this issue but could disrupt user workflows that work around the behavior. With this change, job variable expansions that reference or apply alias file variables, expand to the file name or path of the `File` type variable, instead of its value, such as the file contents.

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.6">

## GitLab 15.6

<div class="deprecation " data-milestone="15.6">

### NFS for Git repository storage

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.0</span>
</div>

With the general availability of Gitaly Cluster ([introduced in GitLab 13.0](https://about.gitlab.com/releases/2020/05/22/gitlab-13-0-released/)), we have deprecated development (bugfixes, performance improvements, etc) for NFS for Git repository storage in GitLab 14.0. We will continue to provide technical support for NFS for Git repositories throughout 14.x, but we will remove all support for NFS on November 22, 2022. This was originally planned for May 22, 2022, but in an effort to allow continued maturity of Gitaly Cluster, we have chosen to extend our deprecation of support date. Please see our official [Statement of Support](https://about.gitlab.com/support/statement-of-support/#gitaly-and-nfs) for further information.

Gitaly Cluster offers tremendous benefits for our customers such as:

- [Variable replication factors](https://docs.gitlab.com/ee/administration/gitaly/index.html#replication-factor).
- [Strong consistency](https://docs.gitlab.com/ee/administration/gitaly/index.html#strong-consistency).
- [Distributed read capabilities](https://docs.gitlab.com/ee/administration/gitaly/index.html#distributed-reads).

We encourage customers currently using NFS for Git repositories to plan their migration by reviewing our documentation on [migrating to Gitaly Cluster](https://docs.gitlab.com/ee/administration/gitaly/index.html#migrate-to-gitaly-cluster).

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.4">

## GitLab 15.4

<div class="deprecation " data-milestone="15.4">

### Bundled Grafana deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.3</span>
</div>

In GitLab 15.4, we will be swapping the bundled Grafana to a fork of Grafana maintained by GitLab.

There was an [identified CVE for Grafana](https://nvd.nist.gov/vuln/detail/CVE-2022-31107), and to mitigate this security vulnerability, we must swap to our own fork because the older version of Grafana we were bundling is no longer receiving long-term support.

This is not expected to cause any incompatibilities with the previous version of Grafana. Neither when using our bundled version, nor when using an external instance of Grafana.

</div>

<div class="deprecation breaking-change" data-milestone="15.4">

### SAST analyzer consolidation and CI/CD template changes

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

GitLab SAST uses various [analyzers](https://docs.gitlab.com/ee/user/application_security/sast/analyzers/) to scan code for vulnerabilities.

We are reducing the number of analyzers used in GitLab SAST as part of our long-term strategy to deliver a better and more consistent user experience.
Streamlining the set of analyzers will also enable faster [iteration](https://about.gitlab.com/handbook/values/#iteration), better [results](https://about.gitlab.com/handbook/values/#results), and greater [efficiency](https://about.gitlab.com/handbook/values/#efficiency) (including a reduction in CI runner usage in most cases).

In GitLab 15.4, GitLab SAST will no longer use the following analyzers:

- [ESLint](https://gitlab.com/gitlab-org/security-products/analyzers/eslint) (JavaScript, TypeScript, React)
- [Gosec](https://gitlab.com/gitlab-org/security-products/analyzers/gosec) (Go)
- [Bandit](https://gitlab.com/gitlab-org/security-products/analyzers/bandit) (Python)

NOTE:
This change was originally planned for GitLab 15.0 and was postponed to GitLab 15.4.
See [the removal notice](./removals.md#sast-analyzer-consolidation-and-cicd-template-changes) for further details.

These analyzers will be removed from the [GitLab-managed SAST CI/CD template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml) and replaced with the [Semgrep-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep).
Effective immediately, they will receive only security updates; other routine improvements or updates are not guaranteed.
After these analyzers reach End of Support, no further updates will be provided.
We will not delete container images previously published for these analyzers; any such change would be announced as a [deprecation, removal, or breaking change announcement](https://about.gitlab.com/handbook/marketing/blog/release-posts/#deprecations-removals-and-breaking-changes).

We will also remove Java from the scope of the [SpotBugs](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs) analyzer and replace it with the [Semgrep-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep).
This change will make it simpler to scan Java code; compilation will no longer be required.
This change will be reflected in the automatic language detection portion of the [GitLab-managed SAST CI/CD template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml). Note that the SpotBugs-based analyzer will continue to cover Groovy, Kotlin, and Scala.

If you've already dismissed a vulnerability finding from one of the deprecated analyzers, the replacement attempts to respect your previous dismissal. The system behavior depends on:

- whether you’ve excluded the Semgrep-based analyzer from running in the past.
- which analyzer first discovered the vulnerabilities shown in the project’s Vulnerability Report.

See [Vulnerability translation documentation](https://docs.gitlab.com/ee/user/application_security/sast/analyzers.html#vulnerability-translation) for further details.

If you applied customizations to any of the affected analyzers or if you currently disable the Semgrep analyzer in your pipelines, you must take action as detailed in the [deprecation issue for this change](https://gitlab.com/gitlab-org/gitlab/-/issues/352554#breaking-change).

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.3">

## GitLab 15.3

<div class="deprecation " data-milestone="15.3">

### Vulnerability Report sort by State

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.0</span>
</div>

The ability to sort the Vulnerability Report by the `State` column was disabled and put behind a feature flag in GitLab 14.10 due to a refactor
of the underlying data model. The feature flag has remained off by default as further refactoring will be required to ensure sorting
by this value remains performant. Due to very low usage of the `State` column for sorting, the feature flag will instead be removed to simplify the codebase and prevent any unwanted performance degradation.

</div>

<div class="deprecation " data-milestone="15.3">

### Vulnerability Report sort by Tool

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">15.1</span>
</div>

The ability to sort the Vulnerability Report by the `Tool` column (scan type) was disabled and put behind a feature flag in GitLab 14.10 due to a refactor
of the underlying data model. The feature flag has remained off by default as further refactoring will be required to ensure sorting
by this value remains performant. Due to very low usage of the `Tool` column for sorting, the feature flag will instead be removed in
GitLab 15.3 to simplify the codebase and prevent any unwanted performance degradation.

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.1">

## GitLab 15.1

<div class="deprecation " data-milestone="15.1">

### Deprecate support for Debian 9

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.9</span>
</div>

Long term service and support (LTSS) for [Debian 9 Stretch ends in July 2022](https://wiki.debian.org/LTS). Therefore, we will no longer support the Debian 9 distribution for the GitLab package. Users can upgrade to Debian 10 or Debian 11.

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.0">

## GitLab 15.0

<div class="deprecation breaking-change" data-milestone="15.0">

### Audit events for repository push events

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.3</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Audit events for [repository events](https://docs.gitlab.com/ee/administration/audit_events.html#removed-events) are now deprecated and will be removed in GitLab 15.0.

These events have always been disabled by default and had to be manually enabled with a
feature flag. Enabling them can cause too many events to be generated which can
dramatically slow down GitLab instances. For this reason, they are being removed.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Background upload for object storage

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

To reduce the overall complexity and maintenance burden of GitLab's [object storage feature](https://docs.gitlab.com/ee/administration/object_storage.html), support for using `background_upload` to upload files is deprecated and will be fully removed in GitLab 15.0. Review the [15.0 specific changes](https://docs.gitlab.com/omnibus/update/gitlab_15_changes.html) for the [removed background uploads settings for object storage](https://docs.gitlab.com/omnibus/update/gitlab_15_changes.html#removed-background-uploads-settings-for-object-storage).

This impacts a small subset of object storage providers:

- **OpenStack** Customers using OpenStack need to change their configuration to use the S3 API instead of Swift.
- **RackSpace** Customers using RackSpace-based object storage need to migrate data to a different provider.

GitLab will publish additional guidance to assist affected customers in migrating.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### CI/CD job name length limit

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.6</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

In GitLab 15.0 we are going to limit the number of characters in CI/CD job names to 255. Any pipeline with job names that exceed the 255 character limit will stop working after the 15.0 release.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Changing an instance (shared) runner to a project (specific) runner

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.5</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

In GitLab 15.0, you can no longer change an instance (shared) runner to a project (specific) runner.

Users often accidentally change instance runners to project runners, and they're unable to change them back. GitLab does not allow you to change a project runner to a shared runner because of the security implications. A runner meant for one project could be set to run jobs for an entire instance.

Administrators who need to add runners for multiple projects can register a runner for one project, then go to the Admin view and choose additional projects.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Container Network and Host Security

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

All functionality related to GitLab's Container Network Security and Container Host Security categories is deprecated in GitLab 14.8 and scheduled for removal in GitLab 15.0. Users who need a replacement for this functionality are encouraged to evaluate the following open source projects as potential solutions that can be installed and managed outside of GitLab: [AppArmor](https://gitlab.com/apparmor/apparmor), [Cilium](https://github.com/cilium/cilium), [Falco](https://github.com/falcosecurity/falco), [FluentD](https://github.com/fluent/fluentd), [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/). To integrate these technologies into GitLab, add the desired Helm charts into your copy of the [Cluster Management Project Template](https://docs.gitlab.com/ee/user/clusters/management_project_template.html). Deploy these Helm charts in production by calling commands through GitLab [CI/CD](https://docs.gitlab.com/ee/user/clusters/agent/ci_cd_workflow.html).

As part of this change, the following specific capabilities within GitLab are now deprecated, and are scheduled for removal in GitLab 15.0:

- The **Security & Compliance > Threat Monitoring** page.
- The `Network Policy` security policy type, as found on the **Security & Compliance > Policies** page.
- The ability to manage integrations with the following technologies through GitLab: AppArmor, Cilium, Falco, FluentD, and Pod Security Policies.
- All APIs related to the above functionality.

For additional context, or to provide feedback regarding this change, please reference our open [deprecation issue](https://gitlab.com/groups/gitlab-org/-/epics/7476).

</div>

<div class="deprecation " data-milestone="15.0">

### Container scanning schemas below 14.0.0

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.7</span>
</div>

[Container scanning report schemas](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/releases)
versions earlier than 14.0.0 will no longer be supported in GitLab 15.0. Reports that do not pass validation
against the schema version declared in the report will also no longer be supported in GitLab 15.0.

Third-party tools that [integrate with GitLab by outputting a container scanning security report](https://docs.gitlab.com/ee/development/integrations/secure.html#report)
as a pipeline job artifact are affected. You must ensure that all output reports adhere to the correct schema with a minimum version of 14.0.0. Reports with a lower version or that fail to validate against the declared schema version will not be processed, and vulnerability findings will not display in MRs, pipelines, or Vulnerability Reports.

To help with the transition, from GitLab 14.10, non-compliant reports will display a
[warning](https://gitlab.com/gitlab-org/gitlab/-/issues/335789#note_672853791)
in the Vulnerability Report.

</div>

<div class="deprecation " data-milestone="15.0">

### Coverage guided fuzzing schemas below 14.0.0

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.7</span>
</div>

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

</div>

<div class="deprecation " data-milestone="15.0">

### DAST schemas below 14.0.0

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.7</span>
</div>

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

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Dependency Scanning Python 3.9 and 3.6 image deprecation

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

For those using Dependency Scanning for Python projects, we are deprecating the default `gemnasium-python:2` image which uses Python 3.6 as well as the custom `gemnasium-python:2-python-3.9` image which uses Python 3.9. The new default image as of GitLab 15.0 will be for Python 3.9 as it is a [supported version](https://endoflife.date/python) and 3.6 [is no longer supported](https://endoflife.date/python).

For users using Python 3.9 or 3.9-compatible projects, you should not need to take action and dependency scanning should begin to work in GitLab 15.0. If you wish to test the new container now please run a test pipeline in your project with this container (which will be removed in 15.0). Use the Python 3.9 image:

```yaml
gemnasium-python-dependency_scanning:
  image:
    name: registry.gitlab.com/gitlab-org/security-products/analyzers/gemnasium-python:2-python-3.9
```

For users using Python 3.6, as of GitLab 15.0 you will no longer be able to use the default template for dependency scanning. You will need to switch to use the deprecated `gemnasium-python:2` analyzer image. If you are impacted by this please comment in [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/351503) so we can extend the removal if needed.

For users using the 3.9 special exception image, you must instead use the default value and no longer override your container. To verify if you are using the 3.9 special exception image, check your `.gitlab-ci.yml` file for the following reference:

```yaml
gemnasium-python-dependency_scanning:
  image:
    name: registry.gitlab.com/gitlab-org/security-products/analyzers/gemnasium-python:2-python-3.9
```

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Dependency Scanning default Java version changed to 17

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.10</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

In GitLab 15.0, for Dependency Scanning, the default version of Java that the scanner expects will be updated from 11 to 17. Java 17 is [the most up-to-date Long Term Support (LTS) version](https://en.wikipedia.org/wiki/Java_version_history). Dependency scanning continues to support the same [range of versions (8, 11, 13, 14, 15, 16, 17)](https://docs.gitlab.com/ee/user/application_security/dependency_scanning/#supported-languages-and-package-managers), only the default version is changing. If your project uses the previous default of Java 11, be sure to [set the `DS_Java_Version` variable to match](https://docs.gitlab.com/ee/user/application_security/dependency_scanning/#configuring-specific-analyzers-used-by-dependency-scanning).

</div>

<div class="deprecation " data-milestone="15.0">

### Dependency scanning schemas below 14.0.0

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.7</span>
</div>

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

</div>

<div class="deprecation " data-milestone="15.0">

### Deprecate Geo Admin UI Routes

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
</div>

In GitLab 13.0, we introduced new project and design replication details routes in the Geo Admin UI. These routes are `/admin/geo/replication/projects` and `/admin/geo/replication/designs`. We kept the legacy routes and redirected them to the new routes. In GitLab 15.0, we will remove support for the legacy routes `/admin/geo/projects` and `/admin/geo/designs`. Please update any bookmarks or scripts that may use the legacy routes.

</div>

<div class="deprecation " data-milestone="15.0">

### Deprecate custom Geo:db:* Rake tasks

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
</div>

In GitLab 14.8, we are [replacing the `geo:db:*` Rake tasks with built-in tasks](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/77269/diffs) that are now possible after [switching the Geo tracking database to use Rails' 6 support of multiple databases](https://gitlab.com/groups/gitlab-org/-/epics/6458).
The following `geo:db:*` tasks will be replaced with their corresponding `db:*:geo` tasks:

- `geo:db:drop` -> `db:drop:geo`
- `geo:db:create` -> `db:create:geo`
- `geo:db:setup` -> `db:setup:geo`
- `geo:db:migrate` -> `db:migrate:geo`
- `geo:db:rollback` -> `db:rollback:geo`
- `geo:db:version` -> `db:version:geo`
- `geo:db:reset` -> `db:reset:geo`
- `geo:db:seed` -> `db:seed:geo`
- `geo:schema:load:geo` -> `db:schema:load:geo`
- `geo:db:schema:dump` -> `db:schema:dump:geo`
- `geo:db:migrate:up` -> `db:migrate:up:geo`
- `geo:db:migrate:down` -> `db:migrate:down:geo`
- `geo:db:migrate:redo` -> `db:migrate:redo:geo`
- `geo:db:migrate:status` -> `db:migrate:status:geo`
- `geo:db:test:prepare` -> `db:test:prepare:geo`
- `geo:db:test:load` -> `db:test:load:geo`
- `geo:db:test:purge` -> `db:test:purge:geo`

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Deprecate feature flag PUSH_RULES_SUPERSEDE_CODE_OWNERS

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The feature flag `PUSH_RULES_SUPERSEDE_CODE_OWNERS` is being removed in GitLab 15.0. Upon its removal, push rules will supersede Code Owners. Even if Code Owner approval is required, a push rule that explicitly allows a specific user to push code supersedes the Code Owners setting.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Elasticsearch 6.8

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Elasticsearch 6.8 is deprecated in GitLab 14.8 and scheduled for removal in GitLab 15.0.
Customers using Elasticsearch 6.8 need to upgrade their Elasticsearch version to 7.x prior to upgrading to GitLab 15.0.
We recommend using the latest version of Elasticsearch 7 to benefit from all Elasticsearch improvements.

Elasticsearch 6.8 is also incompatible with Amazon OpenSearch, which we [plan to support in GitLab 15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/327560).

</div>

<div class="deprecation " data-milestone="15.0">

### Enforced validation of security report schemas

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.7</span>
</div>

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

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### External status check API breaking changes

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The [external status check API](https://docs.gitlab.com/ee/api/status_checks.html) was originally implemented to
support pass-by-default requests to mark a status check as passing. Pass-by-default requests are now deprecated.
Specifically, the following are deprecated:

- Requests that do not contain the `status` field.
- Requests that have the `status` field set to `approved`.

Beginning in GitLab 15.0, status checks will only be updated to a passing state if the `status` field is both present
and set to `passed`. Requests that:

- Do not contain the `status` field will be rejected with a `422` error. For more information, see [the relevant issue](https://gitlab.com/gitlab-org/gitlab/-/issues/338827).
- Contain any value other than `passed` will cause the status check to fail. For more information, see [the relevant issue](https://gitlab.com/gitlab-org/gitlab/-/issues/339039).

To align with this change, API calls to list external status checks will also return the value of `passed` rather than
`approved` for status checks that have passed.

</div>

<div class="deprecation " data-milestone="15.0">

### GitLab Pages running as daemon

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.9</span>
</div>

In 15.0, support for daemon mode for GitLab Pages will be removed.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### GitLab Serverless

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.3</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

GitLab Serverless is a feature set to support Knative-based serverless development with automatic deployments and monitoring.

We decided to remove the GitLab Serverless features as they never really resonated with our users. Besides, given the continuous development of Kubernetes and Knative, our current implementations do not even work with recent versions.

</div>

<div class="deprecation " data-milestone="15.0">

### Godep support in License Compliance

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.7</span>
</div>

The Godep dependency manager for Golang was deprecated in 2020 by Go and
has been replaced with Go modules.
To reduce our maintenance cost we are deprecating License Compliance for Godep projects as of 14.7
and will remove it in GitLab 15.0

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### GraphQL ID and GlobalID compatibility

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

We are removing a non-standard extension to our GraphQL processor, which we added for backwards compatibility. This extension modifies the validation of GraphQL queries, allowing the use of the `ID` type for arguments where it would normally be rejected.
Some arguments originally had the type `ID`. These were changed to specific
kinds of `ID`. This change may be a breaking change if you:

- Use GraphQL.
- Use the `ID` type for any argument in your query signatures.

Some field arguments still have the `ID` type. These are typically for
IID values, or namespace paths. An example is `Query.project(fullPath: ID!)`.

For a list of affected and unaffected field arguments,
see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/352832).

You can test if this change affects you by validating
your queries locally, using schema data fetched from a GitLab server.
You can do this by using the GraphQL explorer tool for the relevant GitLab
instance. For example: `https://gitlab.com/-/graphql-explorer`.

For example, the following query illustrates the breaking change:

```graphql
# a query using the deprecated type of Query.issue(id:)
# WARNING: This will not work after GitLab 15.0
query($id: ID!) {
  deprecated: issue(id: $id) {
    title, description
  }
}
```

The query above will not work after GitLab 15.0 is released, because the type
of `Query.issue(id:)` is actually `IssueID!`.

Instead, you should use one of the following two forms:

```graphql
# This will continue to work
query($id: IssueID!) {
  a: issue(id: $id) {
    title, description
  }
  b: issue(id: "gid://gitlab/Issue/12345") {
    title, description
  }
}
```

This query works now, and will continue to work after GitLab 15.0.
You should convert any queries in the first form (using `ID` as a named type in the signature)
to one of the other two forms (using the correct appropriate type in the signature, or using
an inline argument expression).

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### GraphQL permissions change for Package settings

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The GitLab Package stage offers a Package Registry, Container Registry, and Dependency Proxy to help you manage all of your dependencies using GitLab. Each of these product categories has a variety of settings that can be adjusted using the API.

The permissions model for GraphQL is being updated. After 15.0, users with the Guest, Reporter, and Developer role can no longer update these settings:

- [Package Registry settings](https://docs.gitlab.com/ee/api/graphql/reference/#packagesettings)
- [Container Registry cleanup policy](https://docs.gitlab.com/ee/api/graphql/reference/#containerexpirationpolicy)
- [Dependency Proxy time-to-live policy](https://docs.gitlab.com/ee/api/graphql/reference/#dependencyproxyimagettlgrouppolicy)
- [Enabling the Dependency Proxy for your group](https://docs.gitlab.com/ee/api/graphql/reference/#dependencyproxysetting)

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Known host required for GitLab Runner SSH executor

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.5</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

In [GitLab 14.3](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3074), we added a configuration setting in the GitLab Runner `config.toml` file. This setting, [`[runners.ssh.disable_strict_host_key_checking]`](https://docs.gitlab.com/runner/executors/ssh.html#security), controls whether or not to use strict host key checking with the SSH executor.

In GitLab 15.0 and later, the default value for this configuration option will change from `true` to `false`. This means that strict host key checking will be enforced when using the GitLab Runner SSH executor.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Legacy approval status names from License Compliance API

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.6</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

We deprecated legacy names for approval status of license policy (blacklisted, approved) in the `managed_licenses` API but they are still used in our API queries and responses. They will be removed in 15.0.

If you are using our License Compliance API you should stop using the `approved` and `blacklisted` query parameters, they are now `allowed` and `denied`. In 15.0 the responses will also stop using `approved` and `blacklisted` so you need to adjust any of your custom tools to use the old and new values so they do not break with the 15.0 release.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Legacy database configuration

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.3</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The syntax of [GitLabs database](https://docs.gitlab.com/omnibus/settings/database.html)
configuration located in `database.yml` is changing and the legacy format is deprecated. The legacy format
supported using a single PostgreSQL adapter, whereas the new format is changing to support multiple databases. The `main:` database needs to be defined as a first configuration item.

This deprecation mainly impacts users compiling GitLab from source because Omnibus will handle this configuration automatically.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Logging in GitLab

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.7</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The logging features in GitLab allow users to install the ELK stack (Elasticsearch, Logstash, and Kibana) to aggregate and manage application logs. Users can search for relevant logs in GitLab. However, since deprecating certificate-based integration with Kubernetes clusters and GitLab Managed Apps, we don't have a recommended solution for logging within GitLab. For more information, you can follow the issue for [integrating Opstrace with GitLab](https://gitlab.com/groups/gitlab-org/-/epics/6976).

</div>

<div class="deprecation " data-milestone="15.0">

### Move `custom_hooks_dir` setting from GitLab Shell to Gitaly

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.9</span>
</div>

The [`custom_hooks_dir`](https://docs.gitlab.com/ee/administration/server_hooks.html#create-a-global-server-hook-for-all-repositories) setting is now configured in Gitaly, and will be removed from GitLab Shell in GitLab 15.0.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### OAuth implicit grant

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.0</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The OAuth implicit grant authorization flow will be removed in our next major release, GitLab 15.0. Any applications that use OAuth implicit grant should switch to alternative [supported OAuth flows](https://docs.gitlab.com/ee/api/oauth2.html).

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### OAuth tokens without expiration

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

By default, all new applications expire access tokens after 2 hours. In GitLab 14.2 and earlier, OAuth access tokens
had no expiration. In GitLab 15.0, an expiry will be automatically generated for any existing token that does not
already have one.

You should [opt in](https://docs.gitlab.com/ee/integration/oauth_provider.html#expiring-access-tokens) to expiring
tokens before GitLab 15.0 is released:

1. Edit the application.
1. Select **Expire access tokens** to enable them. Tokens must be revoked or they don’t expire.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### OmniAuth Kerberos gem

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.3</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The `omniauth-kerberos` gem will be removed in our next major release, GitLab 15.0.

This gem has not been maintained and has very little usage. We therefore plan to remove support for this authentication method and recommend using the Kerberos [SPNEGO](https://en.wikipedia.org/wiki/SPNEGO) integration instead. You can follow the [upgrade instructions](https://docs.gitlab.com/ee/integration/kerberos.html#upgrading-from-password-based-to-ticket-based-kerberos-sign-ins) to upgrade from the `omniauth-kerberos` integration to the supported one.

Note that we are not deprecating the Kerberos SPNEGO integration, only the old password-based Kerberos integration.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Optional enforcement of PAT expiration

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The feature to disable enforcement of PAT expiration is unusual from a security perspective.
We have become concerned that this unusual feature could create unexpected behavior for users.
Unexpected behavior in a security feature is inherently dangerous, so we have decided to remove this feature.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Optional enforcement of SSH expiration

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The feature to disable enforcement of SSH expiration is unusual from a security perspective.
We have become concerned that this unusual feature could create unexpected behavior for users.
Unexpected behavior in a security feature is inherently dangerous, so we have decided to remove this feature.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Out-of-the-box SAST support for Java 8

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The [GitLab SAST SpotBugs analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs) scans [Java, Scala, Groovy, and Kotlin code](https://docs.gitlab.com/ee/user/application_security/sast/#supported-languages-and-frameworks) for security vulnerabilities.
For technical reasons, the analyzer must first compile the code before scanning.
Unless you use the [pre-compilation strategy](https://docs.gitlab.com/ee/user/application_security/sast/#pre-compilation), the analyzer attempts to automatically compile your project's code.

In GitLab versions prior to 15.0, the analyzer image includes Java 8 and Java 11 runtimes to facilitate compilation.

In GitLab 15.0, we will:

- Remove Java 8 from the analyzer image to reduce the size of the image.
- Add Java 17 to the analyzer image to make it easier to compile with Java 17.

If you rely on Java 8 being present in the analyzer environment, you must take action as detailed in the [deprecation issue for this change](https://gitlab.com/gitlab-org/gitlab/-/issues/352549#breaking-change).

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Outdated indices of Advanced Search migrations

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.10</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

As Advanced Search migrations usually require support multiple code paths for a long period of time, it’s important to clean those up when we safely can. We use GitLab major version upgrades as a safe time to remove backward compatibility for indices that have not been fully migrated. See the [upgrade documentation](https://docs.gitlab.com/ee/update/index.html#upgrading-to-a-new-major-version) for details.

</div>

<div class="deprecation " data-milestone="15.0">

### Pseudonymizer

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.7</span>
</div>

The Pseudonymizer feature is generally unused,
can cause production issues with large databases,
and can interfere with object storage development.
It is now considered deprecated, and will be removed in GitLab 15.0.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Querying Usage Trends via the `instanceStatisticsMeasurements` GraphQL node

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The `instanceStatisticsMeasurements` GraphQL node has been renamed to `usageTrendsMeasurements` in 13.10 and the old field name has been marked as deprecated. To fix the existing GraphQL queries, replace `instanceStatisticsMeasurements` with `usageTrendsMeasurements`.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Request profiling

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

[Request profiling](https://docs.gitlab.com/ee/administration/monitoring/performance/index.html) is deprecated in GitLab 14.8 and scheduled for removal in GitLab 15.0.

We're working on [consolidating our profiling tools](https://gitlab.com/groups/gitlab-org/-/epics/7327) and making them more easily accessible.
We [evaluated](https://gitlab.com/gitlab-org/gitlab/-/issues/350152) the use of this feature and we found that it is not widely used.
It also depends on a few third-party gems that are not actively maintained anymore, have not been updated for the latest version of Ruby, or crash frequently when profiling heavy page loads.

For more information, check the [summary section of the deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/352488#deprecation-summary).

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Required pipeline configurations in Premium tier

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The [required pipeline configuration](https://docs.gitlab.com/ee/user/admin_area/settings/continuous_integration.html#required-pipeline-configuration) feature is deprecated in GitLab 14.8 for Premium customers and is scheduled for removal in GitLab 15.0. This feature is not deprecated for GitLab Ultimate customers.

This change to move the feature to GitLab's Ultimate tier is intended to help our features better align with our [pricing philosophy](https://about.gitlab.com/company/pricing/#three-tiers) as we see demand for this feature originating primarily from executives.

This change will also help GitLab remain consistent in its tiering strategy with the other related Ultimate-tier features of:
[Security policies](https://docs.gitlab.com/ee/user/application_security/policies/) and [compliance framework pipelines](https://docs.gitlab.com/ee/user/project/settings/index.html#compliance-pipeline-configuration).

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Retire-JS Dependency Scanning tool

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

As of 14.8 the retire.js job is being deprecated from Dependency Scanning. It will continue to be included in our CI/CD template while deprecated. We are removing retire.js from Dependency Scanning on May 22, 2022 in GitLab 15.0. JavaScript scanning functionality will not be affected as it is still being covered by Gemnasium.

If you have explicitly excluded retire.js using DS_EXCLUDED_ANALYZERS you will need to clean up (remove the reference) in 15.0. If you have customized your pipeline's Dependency Scanning configuration related to the `retire-js-dependency_scanning` job you will want to switch to gemnasium-dependency_scanning before the removal in 15.0, to prevent your pipeline from failing. If you have not used the DS_EXCLUDED_ANALYZERS to reference retire.js, or customized your template specifically for retire.js, you will not need to take action.

</div>

<div class="deprecation " data-milestone="15.0">

### SAST schemas below 14.0.0

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.7</span>
</div>

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

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### SAST support for .NET 2.1

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The GitLab SAST Security Code Scan analyzer scans .NET code for security vulnerabilities.
For technical reasons, the analyzer must first build the code to scan it.

In GitLab versions prior to 15.0, the default analyzer image (version 2) includes support for:

- .NET 2.1
- .NET 3.0 and .NET Core 3.0
- .NET Core 3.1
- .NET 5.0

In GitLab 15.0, we will change the default major version for this analyzer from version 2 to version 3. This change:

- Adds [severity values for vulnerabilities](https://gitlab.com/gitlab-org/gitlab/-/issues/350408) along with [other new features and improvements](https://gitlab.com/gitlab-org/security-products/analyzers/security-code-scan/-/blob/master/CHANGELOG.md).
- Removes .NET 2.1 support.
- Adds support for .NET 6.0, Visual Studio 2019, and Visual Studio 2022.

Version 3 was [announced in GitLab 14.6](https://about.gitlab.com/releases/2021/12/22/gitlab-14-6-released/#sast-support-for-net-6) and made available as an optional upgrade.

If you rely on .NET 2.1 support being present in the analyzer image by default, you must take action as detailed in the [deprecation issue for this change](https://gitlab.com/gitlab-org/gitlab/-/issues/352553#breaking-change).

</div>

<div class="deprecation " data-milestone="15.0">

### Secret Detection configuration variables deprecated

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
</div>

To make it simpler and more reliable to [customize GitLab Secret Detection](https://docs.gitlab.com/ee/user/application_security/secret_detection/#customizing-settings), we're deprecating some of the variables that you could previously set in your CI/CD configuration.

The following variables currently allow you to customize the options for historical scanning, but interact poorly with the [GitLab-managed CI/CD template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/Secret-Detection.gitlab-ci.yml) and are now deprecated:

- `SECRET_DETECTION_COMMIT_FROM`
- `SECRET_DETECTION_COMMIT_TO`
- `SECRET_DETECTION_COMMITS`
- `SECRET_DETECTION_COMMITS_FILE`

The `SECRET_DETECTION_ENTROPY_LEVEL` previously allowed you to configure rules that only considered the entropy level of strings in your codebase, and is now deprecated.
This type of entropy-only rule created an unacceptable number of incorrect results (false positives) and is no longer supported.

In GitLab 15.0, we'll update the Secret Detection [analyzer](https://docs.gitlab.com/ee/user/application_security/terminology/#analyzer) to ignore these deprecated options.
You'll still be able to configure historical scanning of your commit history by setting the [`SECRET_DETECTION_HISTORIC_SCAN` CI/CD variable](https://docs.gitlab.com/ee/user/application_security/secret_detection/#available-cicd-variables).

For further details, see [the deprecation issue for this change](https://gitlab.com/gitlab-org/gitlab/-/issues/352565).

</div>

<div class="deprecation " data-milestone="15.0">

### Secret detection schemas below 14.0.0

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.7</span>
</div>

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

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Secure and Protect analyzer images published in new location

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

GitLab uses various [analyzers](https://docs.gitlab.com/ee/user/application_security/terminology/#analyzer) to [scan for security vulnerabilities](https://docs.gitlab.com/ee/user/application_security/).
Each analyzer is distributed as a container image.

Starting in GitLab 14.8, new versions of GitLab Secure and Protect analyzers are published to a new registry location under `registry.gitlab.com/security-products`.

We will update the default value of [GitLab-managed CI/CD templates](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Security) to reflect this change:

- For all analyzers except Container Scanning, we will update the variable `SECURE_ANALYZERS_PREFIX` to the new image registry location.
- For Container Scanning, the default image address is already updated. There is no `SECURE_ANALYZERS_PREFIX` variable for Container Scanning.

In a future release, we will stop publishing images to `registry.gitlab.com/gitlab-org/security-products/analyzers`.
Once this happens, you must take action if you manually pull images and push them into a separate registry. This is commonly the case for [offline deployments](https://docs.gitlab.com/ee/user/application_security/offline_deployments/index.html).
Otherwise, you won't receive further updates.

See the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/352564) for more details.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Secure and Protect analyzer major version update

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The Secure and Protect stages will be bumping the major versions of their analyzers in tandem with the GitLab 15.0 release. This major bump will enable a clear delineation for analyzers, between:

- Those released prior to May 22, 2022, which generate reports that _are not_ subject to stringent schema validation.
- Those released after May 22, 2022, which generate reports that _are_ subject to stringent schema validation.

If you are not using the default inclusion templates, or have pinned your analyzer versions you will need to update your CI/CD job definition to either remove the pinned version or to update the latest major version.
Users of GitLab 12.0-14.10 will continue to experience analyzer updates as normal until the release of GitLab 15.0, following which all newly fixed bugs and newly released features in the new major versions of the analyzers will not be available in the deprecated versions because we do not backport bugs and new features as per our [maintenance policy](https://docs.gitlab.com/ee/policy/maintenance.html). As required security patches will be backported within the latest 3 minor releases.
Specifically, the following are being deprecated and will no longer be updated after 15.0 GitLab release:

- API Security: version 1
- Container Scanning: version 4
- Coverage-guided fuzz testing: version 2
- Dependency Scanning: version 2
- Dynamic Application Security Testing (DAST): version 2
- Infrastructure as Code (IaC) Scanning: version 1
- License Scanning: version 3
- Secret Detection: version 3
- Static Application Security Testing (SAST): version 2 of [all analyzers](https://docs.gitlab.com/ee/user/application_security/sast/#supported-languages-and-frameworks), except `gosec` which is currently at version 3
  - `bandit`: version 2
  - `brakeman`: version 2
  - `eslint`: version 2
  - `flawfinder`: version 2
  - `gosec`: version 3
  - `kubesec`: version 2
  - `mobsf`: version 2
  - `nodejs-scan`: version 2
  - `phpcs-security-audit`: version 2
  - `pmd-apex`: version 2
  - `security-code-scan`: version 2
  - `semgrep`: version 2
  - `sobelow`: version 2
  - `spotbugs`: version 2

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Sidekiq metrics and health checks configuration

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.7</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Exporting Sidekiq metrics and health checks using a single process and port is deprecated.
Support will be removed in 15.0.

We have updated Sidekiq to export [metrics and health checks from two separate processes](https://gitlab.com/groups/gitlab-org/-/epics/6409)
to improve stability and availability and prevent data loss in edge cases.
As those are two separate servers, a configuration change will be required in 15.0
to explicitly set separate ports for metrics and health-checks.
The newly introduced settings for `sidekiq['health_checks_*']`
should always be set in `gitlab.rb`.
For more information, check the documentation for [configuring Sidekiq](https://docs.gitlab.com/ee/administration/sidekiq/index.html).

These changes also require updates in either Prometheus to scrape the new endpoint or k8s health-checks to target the new
health-check port to work properly, otherwise either metrics or health-checks will disappear.

For the deprecation period those settings are optional
and GitLab will default the Sidekiq health-checks port to the same port as `sidekiq_exporter`
and only run one server (not changing the current behaviour).
Only if they are both set and a different port is provided, a separate metrics server will spin up
to serve the Sidekiq metrics, similar to the way Sidekiq will behave in 15.0.

</div>

<div class="deprecation " data-milestone="15.0">

### Static Site Editor

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.7</span>
</div>

The Static Site Editor will no longer be available starting in GitLab 15.0. Improvements to the Markdown editing experience across GitLab will deliver smiliar benefit but with a wider reach. Incoming requests to the Static Site Editor will be redirected to the [Web IDE](https://docs.gitlab.com/ee/user/project/web_ide/index.html).

Current users of the Static Site Editor can view the [documentation](https://docs.gitlab.com/ee/user/project/web_ide/index.html) for more information, including how to remove the configuration files from existing projects.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Support for SLES 12 SP2

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.5</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Long term service and support (LTSS) for SUSE Linux Enterprise Server (SLES) 12 SP2 [ended on March 31, 2021](https://www.suse.com/lifecycle/). The CA certificates on SP2 include the expired DST root certificate, and it's not getting new CA certificate package updates. We have implemented some [workarounds](https://gitlab.com/gitlab-org/gitlab-omnibus-builder/-/merge_requests/191), but we will not be able to continue to keep the build running properly.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Support for gRPC-aware proxy deployed between Gitaly and rest of GitLab

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Although not recommended or documented, it was possible to deploy a gRPC-aware proxy between Gitaly and
the rest of GitLab. For example, NGINX and Envoy. The ability to deploy a gRPC-aware proxy is
[deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/352517). If you currently use a gRPC-aware proxy for
Gitaly connections, you should change your proxy configuration to use TCP or TLS proxying (OSI layer 4) instead.

Gitaly Cluster became incompatible with gRPC-aware proxies in GitLab 13.12. Now all GitLab installations will be incompatible with
gRPC-aware proxies, even without Gitaly Cluster.

By sending some of our internal RPC traffic through a custom protocol (instead of gRPC) we
increase throughput and reduce Go garbage collection latency. For more information, see
the [relevant epic](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/463).

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Test coverage project CI/CD setting

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

To simplify setting a test coverage pattern, in GitLab 15.0 the
[project setting for test coverage parsing](https://docs.gitlab.com/ee/ci/pipelines/settings.html#add-test-coverage-results-using-project-settings-removed)
is being removed.

Instead, using the project’s `.gitlab-ci.yml`, provide a regular expression with the `coverage` keyword to set
testing coverage results in merge requests.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Tracing in GitLab

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.7</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Tracing in GitLab is an integration with Jaeger, an open-source end-to-end distributed tracing system. GitLab users can navigate to their Jaeger instance to gain insight into the performance of a deployed application, tracking each function or microservice that handles a given request. Tracing in GitLab is deprecated in GitLab 14.7, and scheduled for removal in 15.0. To track work on a possible replacement, see the issue for [Opstrace integration with GitLab](https://gitlab.com/groups/gitlab-org/-/epics/6976).

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Update to the Container Registry group-level API

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.5</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

In milestone 15.0, support for the `tags` and `tags_count` parameters will be removed from the Container Registry API that [gets registry repositories from a group](../api/container_registry.md#within-a-group).

The `GET /groups/:id/registry/repositories` endpoint will remain, but won't return any info about tags. To get the info about tags, you can use the existing `GET /registry/repositories/:id` endpoint, which will continue to support the `tags` and `tag_count` options as it does today. The latter must be called once per image repository.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Value Stream Analytics filtering calculation change

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.5</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

We are changing how the date filter works in Value Stream Analytics. Instead of filtering by the time that the issue or merge request was created, the date filter will filter by the end event time of the given stage. This will result in completely different figures after this change has rolled out.

If you monitor Value Stream Analytics metrics and rely on the date filter, to avoid losing data, you must save the data prior to this change.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Vulnerability Check

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The vulnerability check feature is deprecated in GitLab 14.8 and scheduled for removal in GitLab 15.0. We encourage you to migrate to the new security approvals feature instead. You can do so by navigating to **Security & Compliance > Policies** and creating a new Scan Result Policy.

The new security approvals feature is similar to vulnerability check. For example, both can require approvals for MRs that contain security vulnerabilities. However, security approvals improve the previous experience in several ways:

- Users can choose who is allowed to edit security approval rules. An independent security or compliance team can therefore manage rules in a way that prevents development project maintainers from modifying the rules.
- Multiple rules can be created and chained together to allow for filtering on different severity thresholds for each scanner type.
- A two-step approval process can be enforced for any desired changes to security approval rules.
- A single set of security policies can be applied to multiple development projects to allow for ease in maintaining a single, centralized ruleset.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `Versions` on base `PackageType`

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.5</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

As part of the work to create a [Package Registry GraphQL API](https://gitlab.com/groups/gitlab-org/-/epics/6318), the Package group deprecated the `Version` type for the basic `PackageType` type and moved it to [`PackageDetailsType`](https://docs.gitlab.com/ee/api/graphql/reference/index.html#packagedetailstype).

In milestone 15.0, we will completely remove `Version` from `PackageType`.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `artifacts:reports:cobertura` keyword

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.7</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

Currently, test coverage visualizations in GitLab only support Cobertura reports. Starting 15.0, the
`artifacts:reports:cobertura` keyword will be replaced by
[`artifacts:reports:coverage_report`](https://gitlab.com/gitlab-org/gitlab/-/issues/344533). Cobertura will be the
only supported report file in 15.0, but this is the first step towards GitLab supporting other report types.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `defaultMergeCommitMessageWithDescription` GraphQL API field

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.5</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The GraphQL API field `defaultMergeCommitMessageWithDescription` has been deprecated and will be removed in GitLab 15.0. For projects with a commit message template set, it will ignore the template.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `dependency_proxy_for_private_groups` feature flag

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.5</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

We added a feature flag because [GitLab-#11582](https://gitlab.com/gitlab-org/gitlab/-/issues/11582) changed how public groups use the Dependency Proxy. Prior to this change, you could use the Dependency Proxy without authentication. The change requires authentication to use the Dependency Proxy.

In milestone 15.0, we will remove the feature flag entirely. Moving forward, you must authenticate when using the Dependency Proxy.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `pipelines` field from the `version` field

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.5</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

In GraphQL, there are two `pipelines` fields that you can use in a [`PackageDetailsType`](https://docs.gitlab.com/ee/api/graphql/reference/#packagedetailstype) to get the pipelines for package versions:

- The `versions` field's `pipelines` field. This returns all the pipelines associated with all the package's versions, which can pull an unbounded number of objects in memory and create performance concerns.
- The `pipelines` field of a specific `version`. This returns only the pipelines associated with that single package version.

To mitigate possible performance problems, we will remove the `versions` field's `pipelines` field in milestone 15.0. Although you will no longer be able to get all pipelines for all versions of a package, you can still get the pipelines of a single version through the remaining `pipelines` field for that version.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `projectFingerprint` in `PipelineSecurityReportFinding` GraphQL

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The `projectFingerprint` field in the [PipelineSecurityReportFinding](https://docs.gitlab.com/ee/api/graphql/reference/index.html#pipelinesecurityreportfinding)
GraphQL object is being deprecated. This field contains a "fingerprint" of security findings used to determine uniqueness.
The method for calculating fingerprints has changed, resulting in different values. Going forward, the new values will be
exposed in the UUID field. Data previously available in the projectFingerprint field will eventually be removed entirely.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `promote-db` command from `gitlab-ctl`

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.5</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

In GitLab 14.5, we introduced the command `gitlab-ctl promote` to promote any Geo secondary node to a primary during a failover. This command replaces `gitlab-ctl promote-db` which is used to promote database nodes in multi-node Geo secondary sites. `gitlab-ctl promote-db` will continue to function as-is and be available until GitLab 15.0. We recommend that Geo customers begin testing the new `gitlab-ctl promote` command in their staging environments and incorporating the new command in their failover procedures.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `promote-to-primary-node` command from `gitlab-ctl`

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.5</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

In GitLab 14.5, we introduced the command `gitlab-ctl promote` to promote any Geo secondary node to a primary during a failover. This command replaces `gitlab-ctl promote-to-primary-node` which was only usable for single-node Geo sites. `gitlab-ctl promote-to-primary-node` will continue to function as-is and be available until GitLab 15.0. We recommend that Geo customers begin testing the new `gitlab-ctl promote` command in their staging environments and incorporating the new command in their failover procedures.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `started` iterations API field

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The `started` field in the [iterations API](https://docs.gitlab.com/ee/api/iterations.html#list-project-iterations) is being deprecated and will be removed in GitLab 15.0. This field is being replaced with the `current` field (already available) which aligns with the naming for other time-based entities, such as milestones.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `type` and `types` keyword in CI/CD configuration

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.6</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The `type` and `types` CI/CD keywords will be removed in GitLab 15.0. Pipelines that use these keywords will stop working, so you must switch to `stage` and `stages`, which have the same behavior.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### apiFuzzingCiConfigurationCreate GraphQL mutation

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.6</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The API Fuzzing configuration snippet is now being generated client-side and does not require an
API request anymore. We are therefore deprecating the `apiFuzzingCiConfigurationCreate` mutation
which isn't being used in GitLab anymore.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### bundler-audit Dependency Scanning tool

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.6</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

As of 14.6 bundler-audit is being deprecated from Dependency Scanning. It will continue to be in our CI/CD template while deprecated. We are removing bundler-audit from Dependency Scanning on May 22, 2022 in 15.0. After this removal Ruby scanning functionality will not be affected as it is still being covered by Gemnasium.

If you have explicitly excluded bundler-audit using DS_EXCLUDED_ANALYZERS you will need to clean up (remove the reference) in 15.0. If you have customized your pipeline's Dependency Scanning configuration, for example to edit the `bundler-audit-dependency_scanning` job, you will want to switch to gemnasium-dependency_scanning before removal in 15.0, to prevent your pipeline from failing. If you have not used the DS_EXCLUDED_ANALYZERS to reference bundler-audit, or customized your template specifically for bundler-audit, you will not need to take action.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### htpasswd Authentication for the Container Registry

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The Container Registry supports [authentication](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#auth) with `htpasswd`. It relies on an [Apache `htpasswd` file](https://httpd.apache.org/docs/2.4/programs/htpasswd.html), with passwords hashed using `bcrypt`.

Since it isn't used in the context of GitLab (the product), `htpasswd` authentication will be deprecated in GitLab 14.9 and removed in GitLab 15.0.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### user_email_lookup_limit API field

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The `user_email_lookup_limit` [API field](https://docs.gitlab.com/ee/api/settings.html) is deprecated and will be removed in GitLab 15.0. Until GitLab 15.0, `user_email_lookup_limit` is aliased to `search_rate_limit` and existing workflows will continue to work.

Any API calls attempting to change the rate limits for `user_email_lookup_limit` should use `search_rate_limit` instead.

</div>
</div>

<div class="milestone-wrapper" data-milestone="14.10">

## GitLab 14.10

<div class="deprecation breaking-change" data-milestone="14.10">

### Permissions change for downloading Composer dependencies

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.9</span>
- [Breaking change](https://docs.gitlab.com/ee/development/deprecation_guidelines/)
</div>

The GitLab Composer repository can be used to push, search, fetch metadata about, and download PHP dependencies. All these actions require authentication, except for downloading dependencies.

Downloading Composer dependencies without authentication is deprecated in GitLab 14.9, and will be removed in GitLab 15.0. Starting with GitLab 15.0, you must authenticate to download Composer dependencies.

</div>
</div>

<div class="milestone-wrapper" data-milestone="14.9">

## GitLab 14.9

<div class="deprecation " data-milestone="14.9">

### Configurable Gitaly `per_repository` election strategy

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.8</span>
</div>

Configuring the `per_repository` Gitaly election strategy is [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/352612).
`per_repository` has been the only option since GitLab 14.0.

This change is part of regular maintenance to keep our codebase clean.

</div>
</div>

<div class="milestone-wrapper" data-milestone="14.8">

## GitLab 14.8

<div class="deprecation " data-milestone="14.8">

### openSUSE Leap 15.2 packages

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.5</span>
</div>

Distribution support and security updates for openSUSE Leap 15.2 are [ending December 2021](https://en.opensuse.org/Lifetime#openSUSE_Leap).

Starting in 14.5 we are providing packages for openSUSE Leap 15.3, and will stop providing packages for openSUSE Leap 15.2 in the 14.8 milestone.

</div>
</div>

<div class="milestone-wrapper" data-milestone="14.6">

## GitLab 14.6

<div class="deprecation " data-milestone="14.6">

### Release CLI distributed as a generic package

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.2</span>
</div>

The [release-cli](https://gitlab.com/gitlab-org/release-cli) will be released as a [generic package](https://gitlab.com/gitlab-org/release-cli/-/packages) starting in GitLab 14.2. We will continue to deploy it as a binary to S3 until GitLab 14.5 and stop distributing it in S3 in GitLab 14.6.

</div>
</div>

<div class="milestone-wrapper" data-milestone="14.5">

## GitLab 14.5

<div class="deprecation " data-milestone="14.5">

### Rename Task Runner pod to Toolbox

<div class="deprecation-notes">
- Announced in: GitLab <span class="milestone">14.2</span>
</div>

The Task Runner pod is used to execute periodic housekeeping tasks within the GitLab application and is often confused with the GitLab Runner. Thus, [Task Runner will be renamed to Toolbox](https://gitlab.com/groups/gitlab-org/charts/-/epics/25).

This will result in the rename of the sub-chart: `gitlab/task-runner` to `gitlab/toolbox`. Resulting pods will be named along the lines of `{{ .Release.Name }}-toolbox`, which will often be `gitlab-toolbox`. They will be locatable with the label `app=toolbox`.

</div>
</div>

DISCLAIMER:
This page contains information related to upcoming products, features, and functionality.
It is important to note that the information presented is for informational purposes only.
Please do not rely on this information for purchasing or planning purposes.
As with all projects, the items mentioned on this page are subject to change or delay.
The development, release, and timing of any products, features, or functionality remain at the
sole discretion of GitLab Inc.
