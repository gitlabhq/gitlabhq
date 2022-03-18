---
stage: none
group: none
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
---

# Removals by milestone

<!-- vale off -->

<!--
DO NOT EDIT THIS PAGE DIRECTLY

This page is automatically generated from the YAML files in `/data/removals` by the rake task
located at `lib/tasks/gitlab/docs/compile_removals.rake`.

For removal authors (usually Product Managers and Engineering Managers):

- To add a removal, use the example.yml file in `/data/removals/templates` as a template.
- For more information about authoring removals, check the the removal item guidance:
  https://about.gitlab.com/handbook/marketing/blog/release-posts/#creating-a-removal-entry

For removal reviewers (Technical Writers only):

- To update the removal doc, run: `bin/rake gitlab:docs:compile_removals`
- To verify the removals doc is up to date, run: `bin/rake gitlab:docs:check_removals`
- For more information about updating the removal doc, see the removal doc update guidance:
  https://about.gitlab.com/handbook/marketing/blog/release-posts/#update-the-removals-doc
-->

## 14.9

### Integrated error tracking disabled by default

WARNING:
This feature was changed or removed in 14.9
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In GitLab 14.4, GitLab released an integrated error tracking backend that replaces Sentry. This feature caused database performance issues. In GitLab 14.9, integrated error tracking is removed from GitLab.com, and turned off by default in GitLab self-managed. While we explore the future development of this feature, please consider switching to the Sentry backend by [changing your error tracking to Sentry in your project settings](https://docs.gitlab.com/ee/operations/error_tracking.html#sentry-error-tracking).

For additional background on this removal, please reference [Disable Integrated Error Tracking by Default](https://gitlab.com/groups/gitlab-org/-/epics/7580). If you have feedback please add a comment to [Feedback: Removal of Integrated Error Tracking](https://gitlab.com/gitlab-org/gitlab/-/issues/355493).

## 14.6

### Limit the number of triggered pipeline to 25K in free tier

A large amount of triggered pipelines in a single project impacts the performance of GitLab.com. In GitLab 14.6, we are limiting the number of triggered pipelines in a single project on GitLab.com at any given moment to 25,000. This change applies to projects in the free tier only, Premium and Ultimate are not affected by this change.

### Release CLI distributed as a generic package

The [release-cli](https://gitlab.com/gitlab-org/release-cli) will be released as a [generic package](https://gitlab.com/gitlab-org/release-cli/-/packages) starting in GitLab 14.2. We will continue to deploy it as a binary to S3 until GitLab 14.5 and stop distributing it in S3 in GitLab 14.6.

## 14.3

### Introduced limit of 50 tags for jobs

GitLab values efficiency and is prioritizing reliability for [GitLab.com in FY22](https://about.gitlab.com/direction/#gitlab-hosted-first). In 14.3, GitLab CI/CD jobs must have less than 50 [tags](https://docs.gitlab.com/ee/ci/yaml/index.html#tags). If a pipeline contains a job with 50 or more tags, you will receive an error and the pipeline will not be created.

### List project pipelines API endpoint removes `name` support in 14.3

In GitLab 14.3, we will remove the ability to filter by `name` in the [list project pipelines API endpoint](https://docs.gitlab.com/ee/api/pipelines.html#list-project-pipelines) to improve performance. If you currently use this parameter with this endpoint, you must switch to `username`.

### Use of legacy storage setting

The support for [`gitlab_pages['use_legacy_storage']` setting](https://docs.gitlab.com/ee/administration/pages/index.html#domain-source-configuration-before-140) in Omnibus installations has been removed.

In 14.0 we removed [`domain_config_source`](https://docs.gitlab.com/ee/administration/pages/index.html#domain-source-configuration-before-140) which had been previously deprecated, and allowed users to specify disk storage. In 14.0 we added `use_legacy_storage` as a **temporary** flag to unblock upgrades, and allow us to debug issues with our users and it was deprecated and communicated for removal in 14.3.

## 14.2

### Max job log file size of 100 MB

GitLab values efficiency for all users in our wider community of contributors, so we're always working hard to make sure the application performs at a high level with a lovable UX.
  In GitLab 14.2, we have introduced a [job log file size limit](https://docs.gitlab.com/ee/administration/instance_limits.html#maximum-file-size-for-job-logs), set to 100 megabytes by default. Administrators of self-managed GitLab instances can customize this to any value. All jobs that exceed this limit are dropped and marked as failed, helping prevent performance impacts or over-use of resources. This ensures that everyone using GitLab has the best possible experience.

## 14.1

### Remove support for `prometheus.listen_address` and `prometheus.enable`

The support for `prometheus.listen_address` and `prometheus.enable` has been removed from `gitlab.yml`. Use `prometheus.enabled` and `prometheus.server_address` to set up Prometheus server that GitLab instance connects to. Refer to [our documentation](https://docs.gitlab.com/ee/install/installation.html#prometheus-server-setup) for details.

This only affects new installations from source where users might use the old configurations.

### Remove support for older browsers

In GitLab 14.1, we are cleaning up and [removing old code](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63994) that was specific for browsers that we no longer support. This has no impact on users when one of our [supported web browsers](https://docs.gitlab.com/ee/install/requirements.html#supported-web-browsers) is used.

Most notably, support for the following browsers has been removed:

- Apple Safari 13 and older.
- Mozilla Firefox 68.
- Pre-Chromium Microsoft Edge.

The minimum supported browser versions are:

- Apple Safari 13.1.
- Mozilla Firefox 78.
- Google Chrome 84.
- Chromium 84.
- Microsoft Edge 84.

## 14.0

### Auto Deploy CI template v1

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In GitLab 14.0, we will update the [Auto Deploy](https://docs.gitlab.com/ee/topics/autodevops/stages.html#auto-deploy) CI template to the latest version. This includes new features, bug fixes, and performance improvements with a dependency on the v2 [auto-deploy-image](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image). Auto Deploy CI template v1 is deprecated going forward.

Since the v1 and v2 versions are not backward-compatible, your project might encounter an unexpected failure if you already have a deployed application. Follow the [upgrade guide](https://docs.gitlab.com/ee/topics/autodevops/upgrading_auto_deploy_dependencies.html#upgrade-guide) to upgrade your environments. You can also start using the latest template today by following the [early adoption guide](https://docs.gitlab.com/ee/topics/autodevops/upgrading_auto_deploy_dependencies.html#early-adopters).

### Breaking changes to Terraform CI template

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

GitLab 14.0 renews the Terraform CI template to the latest version. The new template is set up for the GitLab Managed Terraform state, with a dependency on the GitLab `terraform-images` image, to provide a good user experience around GitLab's Infrastructure-as-Code features.

The current stable and latest templates are not compatible, and the current latest template becomes the stable template beginning with GitLab 14.0, your Terraform pipeline might encounter an unexpected failure if you run a custom `init` job.

### Code Quality RuboCop support changed

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

By default, the Code Quality feature has not provided support for Ruby 2.6+ if you're using the Code Quality template. To better support the latest versions of Ruby, the default RuboCop version is updated to add support for Ruby 2.4 through 3.0. As a result, support for Ruby 2.1, 2.2, and 2.3 is removed. You can re-enable support for older versions by [customizing your configuration](https://docs.gitlab.com/ee/user/project/merge_requests/code_quality.html#rubocop-errors).

Relevant Issue: [Default `codeclimate-rubocop` engine does not support Ruby 2.6+](https://gitlab.com/gitlab-org/ci-cd/codequality/-/issues/28)

### Container Scanning Engine Clair

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

Clair, the default container scanning engine, was deprecated in GitLab 13.9 and is removed from GitLab 14.0 and replaced by Trivy. We advise customers who are customizing variables for their container scanning job to [follow these instructions](https://docs.gitlab.com/ee/user/application_security/container_scanning/#change-scanners) to ensure that their container scanning jobs continue to work.

### DAST default template stages

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In GitLab 14.0, we've removed the stages defined in the current `DAST.gitlab-ci.yml` template to avoid the situation where the template overrides manual changes made by DAST users. We're making this change in response to customer issues where the stages in the template cause problems when used with customized DAST configurations. Because of this removal, `gitlab-ci.yml` configurations that do not specify a `dast` stage must be updated to include this stage.

### DAST environment variable renaming and removal

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

GitLab 13.8 renamed multiple environment variables to support their broader usage in different workflows. In GitLab 14.0, the old variables have been permanently removed and will no longer work. Any configurations using these variables must be updated to the new variable names. Any scans using these variables in GitLab 14.0 and later will fail to be configured correctly. These variables are:

- `DAST_AUTH_EXCLUDE_URLS` becomes `DAST_EXCLUDE_URLS`.
- `AUTH_EXCLUDE_URLS` becomes `DAST_EXCLUDE_URLS`.
- `AUTH_USERNAME` becomes `DAST_USERNAME`.
- `AUTH_PASSWORD` becomes `DAST_PASSWORD`.
- `AUTH_USERNAME_FIELD` becomes `DAST_USERNAME_FIELD`.
- `AUTH_PASSWORD_FIELD` becomes `DAST_PASSWORD_FIELD`.
- `DAST_ZAP_USE_AJAX_SPIDER` will now be `DAST_USE_AJAX_SPIDER`.
- `DAST_FULL_SCAN_DOMAIN_VALIDATION_REQUIRED` will be removed, since the feature is being removed.

### Default Browser Performance testing job renamed in GitLab 14.0

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

Browser Performance Testing has run in a job named `performance` by default. With the introduction of [Load Performance Testing](https://docs.gitlab.com/ee/user/project/merge_requests/load_performance_testing.html) in GitLab 13.2, this naming could be confusing. To make it clear which job is running [Browser Performance Testing](https://docs.gitlab.com/ee/user/project/merge_requests/browser_performance_testing.html), the default job name is changed from `performance` to `browser_performance` in the template in GitLab 14.0.

Relevant Issue: [Rename default Browser Performance Testing job](https://gitlab.com/gitlab-org/gitlab/-/issues/225914)

### Default DAST spider begins crawling at target URL

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In GitLab 14.0, DAST has removed the current method of resetting the scan to the hostname when starting to spider. Prior to GitLab 14.0, the spider would not begin at the specified target path for the URL but would instead reset the URL to begin crawling at the host root. GitLab 14.0 changes the default for the new variable `DAST_SPIDER_START_AT_HOST` to `false` to better support users' intention of beginning spidering and scanning at the specified target URL, rather than the host root URL. This change has an added benefit: scans can take less time, if the specified path does not contain links to the entire site. This enables easier scanning of smaller sections of an application, rather than crawling the entire app during every scan.

### Default branch name for new repositories now `main`

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

Every Git repository has an initial branch, which is named `master` by default. It's the first branch to be created automatically when you create a new repository. Future [Git versions](https://lore.kernel.org/git/pull.656.v4.git.1593009996.gitgitgadget@gmail.com/) will change the default branch name in Git from `master` to `main`. In coordination with the Git project and the broader community, [GitLab has changed the default branch name](https://gitlab.com/gitlab-org/gitlab/-/issues/223789) for new projects on both our SaaS (GitLab.com) and self-managed offerings starting with GitLab 14.0. This will not affect existing projects.

GitLab has already introduced changes that allow you to change the default branch name both at the [instance level](https://docs.gitlab.com/ee/user/project/repository/branches/default.html#instance-level-custom-initial-branch-name) (for self-managed users) and at the [group level](https://docs.gitlab.com/ee/user/group/#use-a-custom-name-for-the-initial-branch) (for both SaaS and self-managed users). We encourage you to make use of these features to set default branch names on new projects.

For more information, check out our [blog post](https://about.gitlab.com/blog/2021/03/10/new-git-default-branch-name/).

### Dependency Scanning

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

As mentioned in [13.9](https://about.gitlab.com/releases/2021/02/22/gitlab-13-9-released/#deprecations-for-dependency-scanning) and [this blog post](https://about.gitlab.com/blog/2021/02/08/composition-analysis-14-deprecations-and-removals/) several removals for Dependency Scanning take effect.

Previously, to exclude a DS analyzer, you needed to remove it from the default list of analyzers, and use that to set the `DS_DEFAULT_ANALYZERS` variable in your project’s CI template. We determined it should be easier to avoid running a particular analyzer without losing the benefit of newly added analyzers. As a result, we ask you to migrate from `DS_DEFAULT_ANALYZERS` to `DS_EXCLUDED_ANALYZERS` when it is available. Read about it in [issue #287691](https://gitlab.com/gitlab-org/gitlab/-/issues/287691).

Previously, to prevent the Gemnasium analyzers to fetch the advisory database at runtime, you needed to set the `GEMNASIUM_DB_UPDATE` variable. However, this is not documented properly, and its naming is inconsistent with the equivalent `BUNDLER_AUDIT_UPDATE_DISABLED` variable. As a result, we ask you to migrate from `GEMNASIUM_DB_UPDATE` to `GEMNASIUM_UPDATE_DISABLED` when it is available. Read about it in [issue #215483](https://gitlab.com/gitlab-org/gitlab/-/issues/215483).

### Deprecated GraphQL fields

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In accordance with our [GraphQL deprecation and removal process](https://docs.gitlab.com/ee/api/graphql/#deprecation-process), the following fields that were deprecated prior to 13.7 are [fully removed in 14.0](https://gitlab.com/gitlab-org/gitlab/-/issues/267966):

- `Mutations::Todos::MarkAllDone`, `Mutations::Todos::RestoreMany` - `:updated_ids`
- `Mutations::DastScannerProfiles::Create`, `Types::DastScannerProfileType` - `:global_id`
- `Types::SnippetType` - `:blob`
- `EE::Types::GroupType`, `EE::Types::QueryType` - `:vulnerabilities_count_by_day_and_severity`
- `DeprecatedMutations (concern**)` - `AddAwardEmoji`, `RemoveAwardEmoji`, `ToggleAwardEmoji`
- `EE::Types::DeprecatedMutations (concern***)` - `Mutations::Pipelines::RunDastScan`, `Mutations::Vulnerabilities::Dismiss`, `Mutations::Vulnerabilities::RevertToDetected`

### DevOps Adoption API Segments

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

The first release of the DevOps Adoption report had a concept of **Segments**. Segments were [quickly removed from the report](https://gitlab.com/groups/gitlab-org/-/epics/5251) because they introduced an additional layer of complexity on top of **Groups** and **Projects**. Subsequent iterations of the DevOps Adoption report focus on comparing adoption across groups rather than segments. GitLab 14.0 removes all references to **Segments** [from the GraphQL API](https://gitlab.com/gitlab-org/gitlab/-/issues/324414) and replaces them with **Enabled groups**.

### Disk source configuration for GitLab Pages

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

GitLab Pages [API-based configuration](https://docs.gitlab.com/ee/administration/pages/#gitlab-api-based-configuration) has been available since GitLab 13.0. It replaces the unsupported `disk` source configuration removed in GitLab 14.0, which can no longer be chosen. You should stop using `disk` source configuration, and move to `gitlab` for an API-based configuration. To migrate away from the 'disk' source configuration, set `gitlab_pages['domain_config_source'] = "gitlab"` in your `/etc/gitlab/gitlab.rb` file. We recommend you migrate before updating to GitLab 14.0, to identify and troubleshoot any potential problems before upgrading.

### Experimental prefix in Sidekiq queue selector options

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

GitLab supports a [queue selector](https://docs.gitlab.com/ee/administration/operations/extra_sidekiq_processes.html#queue-selector) to run only a subset of background jobs for a given process. When it was introduced, this option had an 'experimental' prefix (`experimental_queue_selector` in Omnibus, `experimentalQueueSelector` in Helm charts).

As announced in the [13.6 release post](https://about.gitlab.com/releases/2020/11/22/gitlab-13-6-released/#sidekiq-cluster-queue-selector-configuration-option-has-been-renamed), the 'experimental' prefix is no longer supported. Instead, `queue_selector` for Omnibus and `queueSelector` in Helm charts should be used.

### External Pipeline Validation Service Code Changes

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

For self-managed instances using the experimental [external pipeline validation service](https://docs.gitlab.com/ee/administration/external_pipeline_validation.html), the range of error codes GitLab accepts will be reduced. Currently, pipelines are invalidated when the validation service returns a response code from `400` to `499`. In GitLab 14.0 and later, pipelines will be invalidated for the `406: Not Accepted` response code only.

### Geo Foreign Data Wrapper settings

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

As [announced in GitLab 13.3](https://about.gitlab.com/releases/2020/08/22/gitlab-13-3-released/#geo-foreign-data-wrapper-settings-deprecated), the following configuration settings in `/etc/gitlab/gitlab.rb` have been removed in 14.0:

- `geo_secondary['db_fdw']`
- `geo_postgresql['fdw_external_user']`
- `geo_postgresql['fdw_external_password']`
- `gitlab-_rails['geo_migrated_local_files_clean_up_worker_cron']`

### GitLab OAuth implicit grant

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

GitLab is deprecating the [OAuth 2 implicit grant flow](https://docs.gitlab.com/ee/api/oauth2.html#implicit-grant-flow) as it has been removed for [OAuth 2.1](https://oauth.net/2.1/).

Migrate your existing applications to other supported [OAuth2 flows](https://docs.gitlab.com/ee/api/oauth2.html#supported-oauth2-flows).

### GitLab Runner helper image in GitLab.com Container Registry

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In 14.0, we are now pulling the GitLab Runner [helper image](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#helper-image) from the GitLab Container Registry instead of Docker Hub. Refer to [issue #27218](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27218) for details.

### GitLab Runner installation to ignore the `skel` directory

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In GitLab Runner 14.0, the installation process will ignore the `skel` directory by default when creating the user home directory. Refer to [issue #4845](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4845) for details.

### Gitaly Cluster SQL primary elector

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

Now that Praefect supports a [primary election strategy](https://docs.gitlab.com/ee/administration/gitaly/praefect.html#repository-specific-primary-nodes) for each repository, we have removed the `sql` election strategy.
The `per_repository` election strategy is the new default, which is automatically used if no election strategy was specified.

If you had configured the `sql` election strategy, you must follow the [migration instructions](https://docs.gitlab.com/ee/administration/gitaly/praefect.html#migrate-to-repository-specific-primary-gitaly-nodes) before upgrading to 14.0.

### Global `SAST_ANALYZER_IMAGE_TAG` in SAST CI template

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

With the maturity of GitLab Secure scanning tools, we've needed to add more granularity to our release process. Previously, GitLab shared a major version number for [all analyzers and tools](https://docs.gitlab.com/ee/user/application_security/sast/#supported-languages-and-frameworks). This requires all tools to share a major version, and prevents the use of [semantic version numbering](https://semver.org/). In GitLab 14.0, SAST removes the `SAST_ANALYZER_IMAGE_TAG` global variable in our [managed `SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml) CI template, in favor of the analyzer job variable setting the `major.minor` tag in the SAST vendored template.

Each analyzer job now has a scoped `SAST_ANALYZER_IMAGE_TAG` variable, which will be actively managed by GitLab and set to the `major` tag for the respective analyzer. To pin to a specific version, [change the variable value to the specific version tag](https://docs.gitlab.com/ee/user/application_security/sast/#pinning-to-minor-image-version).
If you override or maintain custom versions of `SAST.gitlab-ci.yml`, update your CI templates to stop referencing the global `SAST_ANALYZER_IMAGE_TAG`, and move it to a scoped analyzer job tag. We strongly encourage [inheriting and overriding our managed CI templates](https://docs.gitlab.com/ee/user/application_security/sast/#overriding-sast-jobs) to future-proof your CI templates. This change allows you to more granularly control future analyzer updates with a pinned `major.minor` version.
This deprecation and removal changes our [previously announced plan](https://about.gitlab.com/releases/2021/02/22/gitlab-13-9-released/#pin-static-analysis-analyzers-and-tools-to-minor-versions) to pin the Static Analysis tools.

### Hardcoded `master` in CI/CD templates

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

Our CI/CD templates have been updated to no longer use hard-coded references to a `master` branch. In 14.0, they all use a variable that points to your project's configured default branch instead. If your CI/CD pipeline relies on our built-in templates, verify that this change works with your current configuration. For example, if you have a `master` branch and a different default branch, the updates to the templates may cause changes to your pipeline behavior. For more information, [read the issue](https://gitlab.com/gitlab-org/gitlab/-/issues/324131).

### Helm v2 support

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

Helm v2 was [officially deprecated](https://helm.sh/blog/helm-v2-deprecation-timeline/) in November of 2020, with the `stable` repository being [de-listed from the Helm Hub](https://about.gitlab.com/blog/2020/11/09/ensure-auto-devops-work-after-helm-stable-repo/) shortly thereafter. With the release of GitLab 14.0, which will include the 5.0 release of the [GitLab Helm chart](https://docs.gitlab.com/charts/), Helm v2 will no longer be supported.

Users of the chart should [upgrade to Helm v3](https://helm.sh/docs/topics/v2_v3_migration/) to deploy GitLab 14.0 and later.

### Legacy DAST domain validation

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

The legacy method of DAST Domain Validation for CI/CD scans was deprecated in GitLab 13.8, and is removed in GitLab 14.0. This method of domain validation only disallows scans if the `DAST_FULL_SCAN_DOMAIN_VALIDATION_REQUIRED` environment variable is set to `true` in the `gitlab-ci.yml` file, and a `Gitlab-DAST-Permission` header on the site is not set to `allow`. This two-step method required users to opt in to using the variable before they could opt out from using the header.

For more information, see the [removal issue](https://gitlab.com/gitlab-org/gitlab/-/issues/293595).

### Legacy feature flags

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

Legacy feature flags became read-only in GitLab 13.4. GitLab 14.0 removes support for legacy feature flags, so you must migrate them to the [new version](https://docs.gitlab.com/ee/operations/feature_flags.html). You can do this by first taking a note (screenshot) of the legacy flag, then deleting the flag through the API or UI (you don't need to alter the code), and finally create a new Feature Flag with the same name as the legacy flag you deleted. Also, make sure the strategies and environments match the deleted flag. We created a [video tutorial](https://www.youtube.com/watch?v=CAJY2IGep7Y) to help with this migration.

### Legacy fields from DAST report

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

As a part of the migration to a common report format for all of the Secure scanners in GitLab, DAST is making changes to the DAST JSON report. Certain legacy fields were deprecated in 13.8 and have been completely removed in 14.0. These fields are `@generated`, `@version`, `site`, and `spider`. This should not affect any normal DAST operation, but does affect users who consume the JSON report in an automated way and use these fields. Anyone affected by these changes, and needs these fields for business reasons, is encouraged to open a new GitLab issue and explain the need.

For more information, see [the removal issue](https://gitlab.com/gitlab-org/gitlab/-/issues/33915).

### Legacy storage

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

As [announced in GitLab 13.0](https://about.gitlab.com/releases/2020/05/22/gitlab-13-0-released/#planned-removal-of-legacy-storage-in-14.0), [legacy storage](https://docs.gitlab.com/ee/administration/repository_storage_types.html#legacy-storage) has been removed in GitLab 14.0.

### License Compliance

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In 13.0, we deprecated the License-Management CI template and renamed it License-Scanning. We have been providing backward compatibility by warning users of the old template to switch. Now in 14.0, we are completely removing the License-Management CI template. Read about it in [issue #216261](https://gitlab.com/gitlab-org/gitlab/-/issues/216261) or [this blog post](https://about.gitlab.com/blog/2021/02/08/composition-analysis-14-deprecations-and-removals/).

### Limit projects returned in `GET /groups/:id/`

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

To improve performance, we are limiting the number of projects returned from the `GET /groups/:id/` API call to 100. A complete list of projects can still be retrieved with the `GET /groups/:id/projects` API call.

### Make `pwsh` the default shell for newly-registered Windows Runners

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In GitLab Runner 13.2, PowerShell Core support was added to the Shell executor. In 14.0, PowerShell Core, `pwsh` is now the default shell for newly-registered Windows runners. Windows `CMD` will still be available as a shell option for Windows runners. Refer to [issue #26419](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/26419) for details.

### Migrate from `SAST_DEFAULT_ANALYZERS` to `SAST_EXCLUDED_ANALYZERS`

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

Until GitLab 13.9, if you wanted to avoid running one particular GitLab SAST analyzer, you needed to remove it from the [long string of analyzers in the `SAST.gitlab-ci.yml` file](https://gitlab.com/gitlab-org/gitlab/-/blob/390afc431e7ce1ac253b35beb39f19e49c746bff/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml#L12) and use that to set the [`SAST_DEFAULT_ANALYZERS`](https://docs.gitlab.com/ee/user/application_security/sast/#docker-images) variable in your project's CI file. If you did this, it would exclude you from future new analyzers because this string hard codes the list of analyzers to execute. We avoid this problem by inverting this variable's logic to exclude, rather than choose default analyzers.
Beginning with 13.9, [we migrated](https://gitlab.com/gitlab-org/gitlab/-/blob/14fed7a33bfdbd4663d8928e46002a5ef3e3282c/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml#L13) to `SAST_EXCLUDED_ANALYZERS` in our `SAST.gitlab-ci.yml` file. We encourage anyone who uses a [customized SAST configuration](https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings) in their project CI file to migrate to this new variable. If you have not overridden `SAST_DEFAULT_ANALYZERS`, no action is needed. The CI/CD variable `SAST_DEFAULT_ANALYZERS` has been removed in GitLab 14.0, which released on June 22, 2021.

### Off peak time mode configuration for Docker Machine autoscaling

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In GitLab Runner 13.0, [issue #5069](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/5069), we introduced new timing options for the GitLab Docker Machine executor. In GitLab Runner 14.0, we have removed the old configuration option, [off peak time mode](https://docs.gitlab.com/runner/configuration/autoscale.html#off-peak-time-mode-configuration-deprecated).

### OpenSUSE Leap 15.1

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

Support for [OpenSUSE Leap 15.1 is being deprecated](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5135). Support for 15.1 will be dropped in 14.0. We are now providing support for openSUSE Leap 15.2 packages.

### PostgreSQL 11 support

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

PostgreSQL 12 will be the minimum required version in GitLab 14.0. It offers [significant improvements](https://www.postgresql.org/about/news/postgresql-12-released-1976/) to indexing, partitioning, and general performance benefits.

Starting in GitLab 13.7, all new installations default to version 12. From GitLab 13.8, single-node instances are automatically upgraded as well. If you aren't ready to upgrade, you can [opt out of automatic upgrades](https://docs.gitlab.com/omnibus/settings/database.html#opt-out-of-automatic-postgresql-upgrades).

### Redundant timestamp field from DORA metrics API payload

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

The [deployment frequency project-level API](https://docs.gitlab.com/ee/api/dora4_project_analytics.html#list-project-deployment-frequencies) endpoint has been deprecated in favor of the [DORA 4 API](https://docs.gitlab.com/ee/api/dora/metrics.html), which consolidates all the metrics under one API with the specific metric as a required field. As a result, the timestamp field, which doesn't allow adding future extensions and causes performance issues, will be removed. With the old API, an example response would be `{ "2021-03-01": 3, "date": "2021-03-01", "value": 3 }`. The first key/value (`"2021-03-01": 3`) will be removed and replaced by the last two (`"date": "2021-03-01", "value": 3`).

### Release description in the Tags API

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

GitLab 14.0 removes support for the release description in the Tags API. You can no longer add a release description when [creating a new tag](https://docs.gitlab.com/ee/api/tags.html#create-a-new-tag). You also can no longer [create](https://docs.gitlab.com/ee/api/tags.html#create-a-new-release) or [update](https://docs.gitlab.com/ee/api/tags.html#update-a-release) a release through the Tags API. Please migrate to use the [Releases API](https://docs.gitlab.com/ee/api/releases/#create-a-release) instead.

### Ruby version changed in `Ruby.gitlab-ci.yml`

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

By default, the `Ruby.gitlab-ci.yml` file has included Ruby 2.5.

To better support the latest versions of Ruby, the template is changed to use `ruby:latest`, which is currently 3.0. To better understand the changes in Ruby 3.0, please reference the [Ruby-lang.org release announcement](https://www.ruby-lang.org/en/news/2020/12/25/ruby-3-0-0-released/).

Relevant Issue: [Updates Ruby version 2.5 to 3.0](https://gitlab.com/gitlab-org/gitlab/-/issues/329160)

### SAST analyzer `SAST_GOSEC_CONFIG` variable

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

With the release of [SAST Custom Rulesets](https://docs.gitlab.com/ee/user/application_security/sast/#customize-rulesets) in GitLab 13.5 we allow greater flexibility in configuration options for our Go analyzer (GoSec). As a result we no longer plan to support our less flexible [`SAST_GOSEC_CONFIG`](https://docs.gitlab.com/ee/user/application_security/sast/#analyzer-settings) analyzer setting. This variable was deprecated in GitLab 13.10.
GitLab 14.0 removes the old `SAST_GOSEC_CONFIG variable`. If you use or override `SAST_GOSEC_CONFIG` in your CI file, update your SAST CI configuration or pin to an older version of the GoSec analyzer. We strongly encourage [inheriting and overriding our managed CI templates](https://docs.gitlab.com/ee/user/application_security/sast/#overriding-sast-jobs) to future-proof your CI templates.

### Service Templates

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

Service Templates are [removed in GitLab 14.0](https://gitlab.com/groups/gitlab-org/-/epics/5672). They were used to apply identical settings to a large number of projects, but they only did so at the time of project creation.

While they solved part of the problem, _updating_ those values later proved to be a major pain point. [Project Integration Management](https://docs.gitlab.com/ee/user/admin_area/settings/project_integration_management.html) solves this problem by enabling you to create settings at the Group or Instance level, and projects within that namespace inheriting those settings.

### Success and failure for finished build metric conversion

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In GitLab Runner 13.5, we introduced `failed` and `success` states for a job. To support Prometheus rules, we chose to convert `success/failure` to `finished` for the metric. In 14.0, the conversion has now been removed. Refer to [issue #26900](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/26900) for details.

### Terraform template version

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

As we continuously [develop GitLab's Terraform integrations](https://gitlab.com/gitlab-org/gitlab/-/issues/325312), to minimize customer disruption, we maintain two GitLab CI/CD templates for Terraform:

- The ["latest version" template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform.latest.gitlab-ci.yml), which is updated frequently between minor releases of GitLab (such as 13.10, 13.11, etc).
- The ["major version" template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform.gitlab-ci.yml), which is updated only at major releases (such as 13.0, 14.0, etc).

At every major release of GitLab, the "latest version" template becomes the "major version" template, inheriting the "latest template" setup.
As we have added many new features to the Terraform integration, the new setup for the "major version" template can be considered a breaking change.

The latest template supports the [Terraform Merge Request widget](https://docs.gitlab.com/ee/user/infrastructure/iac/mr_integration.html) and
doesn't need additional setup to work with the [GitLab managed Terraform state](https://docs.gitlab.com/ee/user/infrastructure/iac/terraform_state.html).

To check the new changes, see the [new "major version" template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform.gitlab-ci.yml).

### Ubuntu 16.04 support

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

Ubuntu 16.04 [reached end-of-life in April 2021](https://ubuntu.com/about/release-cycle), and no longer receives maintenance updates. We strongly recommend users to upgrade to a newer release, such as 20.04.

GitLab 13.12 will be the last release with Ubuntu 16.04 support.

### Ubuntu 19.10 (Eoan Ermine) package

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

Ubuntu 19.10 (Eoan Ermine) reached end of life on Friday, July 17, 2020. In GitLab Runner 14.0, Ubuntu 19.10 (Eoan Ermine) is no longer available from our package distribution. Refer to [issue #26036](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/26036) for details.

### Unicorn in GitLab self-managed

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

[Support for Unicorn](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6078) has been removed in GitLab 14.0 in favor of Puma. [Puma has a multi-threaded architecture](https://docs.gitlab.com/ee/administration/operations/puma.html) which uses less memory than a multi-process application server like Unicorn. On GitLab.com, we saw a 40% reduction in memory consumption by using Puma.

### WIP merge requests renamed 'draft merge requests'

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

The WIP (work in progress) status for merge requests signaled to reviewers that the merge request in question wasn't ready to merge. We've renamed the WIP feature to **Draft**, a more inclusive and self-explanatory term. **Draft** clearly communicates the merge request in question isn't ready for review, and makes no assumptions about the progress being made toward it. **Draft** also reduces the cognitive load for new users, non-English speakers, and anyone unfamiliar with the WIP acronym.

### Web Application Firewall (WAF)

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

The Web Application Firewall (WAF) was deprecated in GitLab 13.6 and is removed from GitLab 14.0. The WAF had limitations inherent in the architectural design that made it difficult to meet the requirements traditionally expected of a WAF. By removing the WAF, GitLab is able to focus on improving other areas in the product where more value can be provided to users. Users who currently rely on the WAF can continue to use the free and open source [ModSecurity](https://github.com/SpiderLabs/ModSecurity) project, which is independent from GitLab. Additional details are available in the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/271276).

### Windows Server 1903 image support

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In 14.0, we have removed Windows Server 1903. Microsoft ended support for this version on 2020-08-12. Refer to [issue #27551](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27551) for details.

### Windows Server 1909 image support

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In 14.0, we have removed Windows Server 1909. Microsoft ended support for this version on 2021-05-11. Refer to [issue #27899](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27899) for details.

### `/usr/lib/gitlab-runner` symlink from package

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In GitLab Runner 13.3, a symlink was added from `/user/lib/gitlab-runner/gitlab-runner` to `/usr/bin/gitlab-runner`. In 14.0, the symlink has been removed and the runner is now installed in `/usr/bin/gitlab-runner`. Refer to [issue #26651](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/26651) for details.

### `?w=1` URL parameter to ignore whitespace changes

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

To create a consistent experience for users based on their preferences, support for toggling whitespace changes via URL parameter has been removed in GitLab 14.0.

### `CI_PROJECT_CONFIG_PATH` variable

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

The `CI_PROJECT_CONFIG_PATH` [predefined project variable](https://docs.gitlab.com/ee/ci/variables/predefined_variables.html)
has been removed in favor of `CI_CONFIG_PATH`, which is functionally the same.

If you are using `CI_PROJECT_CONFIG_PATH` in your pipeline configurations,
please update them to use `CI_CONFIG_PATH` instead.

### `FF_RESET_HELPER_IMAGE_ENTRYPOINT` feature flag

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In 14.0, we have deactivated the `FF_RESET_HELPER_IMAGE_ENTRYPOINT` feature flag. Refer to issue [#26679](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/26679) for details.

### `FF_SHELL_EXECUTOR_USE_LEGACY_PROCESS_KILL` feature flag

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

In [GitLab Runner 13.1](https://docs.gitlab.com/runner/executors/shell.html#gitlab-131-and-later), [issue #3376](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/3376), we introduced `sigterm` and then `sigkill` to a process in the Shell executor. We also introduced a new feature flag, `FF_SHELL_EXECUTOR_USE_LEGACY_PROCESS_KILL`, so you can use the previous process termination sequence. In GitLab Runner 14.0, [issue #6413](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/6413), the feature flag has been removed.

### `FF_USE_GO_CLOUD_WITH_CACHE_ARCHIVER` feature flag

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

GitLab Runner 14.0 removes the `FF_USE_GO_CLOUD_WITH_CACHE_ARCHIVER` feature flag. Refer to [issue #27175](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27175) for details.

### `secret_detection_default_branch` job

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

To ensure Secret Detection was scanning both default branches and feature branches, we introduced two separate secret detection CI jobs (`secret_detection_default_branch` and `secret_detection`) in our managed [`Secret-Detection.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/Secret-Detection.gitlab-ci.yml) template. These two CI jobs created confusion and complexity in the CI rules logic. This deprecation moves the `rule` logic into the `script` section, which then determines how the `secret_detection` job is run (historic, on a branch, commits, etc).
If you override or maintain custom versions of `SAST.gitlab-ci.yml` or `Secret-Detection.gitlab-ci.yml`, you must update your CI templates. We strongly encourage [inheriting and overriding our managed CI templates](https://docs.gitlab.com/ee/user/application_security/secret_detection/#custom-settings-example) to future-proof your CI templates. GitLab 14.0 no longer supports the old `secret_detection_default_branch` job.

### `trace` parameter in `jobs` API

WARNING:
This feature was changed or removed in 14.0
as a [breaking change](https://docs.gitlab.com/ee/development/contributing/#breaking-changes).
Before updating GitLab, review the details carefully to determine if you need to make any
changes to your code, settings, or workflow.

GitLab Runner was updated in GitLab 13.4 to internally stop passing the `trace` parameter to the `/api/jobs/:id` endpoint. GitLab 14.0 deprecates the `trace` parameter entirely for all other requests of this endpoint. Make sure your [GitLab Runner version matches your GitLab version](https://docs.gitlab.com/runner/#gitlab-runner-versions) to ensure consistent behavior.
