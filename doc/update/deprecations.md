---
stage: none
group: none
info: "See the Technical Writers assigned to Development Guidelines: https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-development-guidelines"
toc: false
---

# Deprecations and removals by version

The following GitLab features are deprecated and no longer recommended for use.

- Each deprecated feature will be removed in a future release.
- Some features cause breaking changes when they are removed.
- On GitLab.com, deprecated features can be removed at any time during the month leading up to the release.
- To view documentation for a removed feature, see the [GitLab Docs archive](https://docs.gitlab.com/archives/).
- For GraphQL API deprecations, you should [verify your API calls work without the deprecated items](https://docs.gitlab.com/ee/api/graphql/#verify-against-the-future-breaking-change-schema).

For advanced searching and filtering of this deprecation information, try
[a tool built by our Customer Success team](https://gitlab-com.gitlab.io/cs-tools/gitlab-cs-tools/what-is-new-since/?tab=deprecations).

[REST API deprecations](https://docs.gitlab.com/ee/api/rest/deprecations.html) are documented separately.

**{rss}** **To be notified of upcoming breaking changes**,
add this URL to your RSS feed reader: `https://about.gitlab.com/breaking-changes.xml`

<!-- vale off -->

<!--
DO NOT EDIT THIS PAGE DIRECTLY

This page is automatically generated from the template located at
`data/deprecations/templates/_deprecation_template.md.erb`, using
the YAML files in `/data/deprecations` by the rake task
located at `lib/tasks/gitlab/docs/compile_deprecations.rake`,

For deprecation authors (usually Product Managers and Engineering Managers):

- To add a deprecation, use the example.yml file in `/data/deprecations/templates` as a template.
- For more information about authoring deprecations, check the the deprecation item guidance:
  https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#update-the-deprecations-doc

For deprecation reviewers (Technical Writers only):

- To update the deprecation doc, run: `bin/rake gitlab:docs:compile_deprecations`
- To verify the deprecations doc is up to date, run: `bin/rake gitlab:docs:check_deprecations`
- For more information about updating the deprecation doc, see the deprecation doc update guidance:
  https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#update-the-deprecations-doc
-->

{::options parse_block_html="true" /}

<div class="js-deprecation-filters"></div>
<div class="milestone-wrapper" data-milestone="20.0">

## GitLab 20.0

<div class="deprecation breaking-change" data-milestone="20.0">

### GitLab Runner Docker Machine executor is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.5</span>
- Removal in GitLab <span class="milestone">20.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/498268).

</div>

The [GitLab Runner Docker Machine executor](https://docs.gitlab.com/runner/executors/docker_machine.html) is deprecated and will be fully removed from the product as a supported feature in GitLab 20.0 (May 2027). The replacement for Docker Machine, [GitLab Runner Autoscaler](https://docs.gitlab.com/runner/runner_autoscale/) with GitLab developed plugins for Amazon Web Services (AWS) EC2, Google Compute Engine (GCE) and Microsoft Azure virtual machines (VMs) is generally available. With this announcement, the GitLab Runner team will no longer accept community contributions for the GitLab maintained Docker Machine fork, or resolve newly identified bugs.

</div>
</div>

<div class="milestone-wrapper" data-milestone="19.0">

## GitLab 19.0

<div class="deprecation breaking-change" data-milestone="19.0">

### Behavior change for protected variables and multi-project pipelines

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.10</span>
- Removal in GitLab <span class="milestone">19.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/432328).

</div>

In some cases, users with sufficient permissions in a project could forward protected variables to an unsecure project, so this change is a security enhancement that minimizes the risk of protected variable values being exposed.

While [forwarding CI/CD variables](https://docs.gitlab.com/ee/ci/pipelines/downstream_pipelines.html#pass-cicd-variables-to-a-downstream-pipeline) through downstream pipelines is useful for some workflows, [protected variables](https://docs.gitlab.com/ee/ci/variables/#protect-a-cicd-variable) require additional care. They are intended for use only with specific protected branches or tags.

In GitLab 19.0, variable forwarding will be updated to ensure protected variables are only passed in specific situations:

- Project-level protected variables can only be forwarded to downstream pipelines in the same project (child pipelines).
- Group-level protected variables can only be forwarded to downstream pipelines of projects that belong to the same group as the source project.

If your pipeline relies on forwarding protected variables, update your configuration to either conform to the two options above, or avoid forwarding protected variables.

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### Compliance pipelines

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.3</span>
- Removal in GitLab <span class="milestone">19.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/groups/gitlab-org/-/epics/11275).

</div>

Currently, there are two ways to ensure compliance- or security-related jobs are run in a project pipeline:

- [Compliance pipelines](https://docs.gitlab.com/ee/user/group/compliance_pipelines.html).
- [Security policies](https://docs.gitlab.com/ee/user/application_security/policies/).

To provide a single place for ensuring required jobs are run in all pipelines for a project, we have deprecated
compliance pipelines in GitLab 17.3 and will remove the feature in GitLab 19.0.

Customers should migrate from compliance pipelines to the new
[pipeline execution policy type](https://docs.gitlab.com/ee/user/application_security/policies/pipeline_execution_policies.html)
as soon as possible.
For details, see the [migration guide](https://docs.gitlab.com/ee/user/group/compliance_pipelines.html#pipeline-execution-policies-migration) and [blog post](https://about.gitlab.com/blog/2024/10/01/why-gitlab-is-deprecating-compliance-pipelines-in-favor-of-security-policies/).

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### GitLab Self-Managed certificate-based integration with Kubernetes

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.5</span>
- Removal in GitLab <span class="milestone">19.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/groups/gitlab-org/configure/-/epics/8).

</div>

The certificate-based integration with Kubernetes [will be deprecated and removed](https://about.gitlab.com/blog/2021/11/15/deprecating-the-cert-based-kubernetes-integration/).

For GitLab Self-Managed, we are introducing the [feature flag](https://docs.gitlab.com/ee/administration/feature_flags.html#enable-or-disable-the-feature) `certificate_based_clusters` in GitLab 15.0 so you can keep your certificate-based integration enabled. However, the feature flag will be disabled by default, so this change is a **breaking change**.

In GitLab 19.0 we will remove both the feature and its related code. Until the final removal in 19.0, features built on this integration will continue to work, if you enable the feature flag. Until the feature is removed, GitLab will continue to fix security and critical issues as they arise.

For a more robust, secure, forthcoming, and reliable integration with Kubernetes, we recommend you use the
[agent for Kubernetes](https://docs.gitlab.com/ee/user/clusters/agent/) to connect Kubernetes clusters with GitLab. [How do I migrate?](https://docs.gitlab.com/ee/user/infrastructure/clusters/migrate_to_gitlab_agent.html)

Although an explicit removal date is set, we don't plan to remove this feature until the new solution has feature parity.
For more information about the blockers to removal, see [this issue](https://gitlab.com/gitlab-org/configure/general/-/issues/199).

For updates and details about this deprecation, follow [this epic](https://gitlab.com/groups/gitlab-org/configure/-/epics/8).

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### Pipeline subscriptions

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.6</span>
- End of Support in GitLab <span class="milestone">18.0</span>
- Removal in GitLab <span class="milestone">19.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/501460).

</div>

The [pipeline subscriptions](https://docs.gitlab.com/ee/ci/pipelines/#trigger-a-pipeline-when-an-upstream-project-is-rebuilt-deprecated) feature is deprecated and will no longer be supported as of GitLab 18.0, with complete removal scheduled for GitLab 19.0. Pipeline subscriptions are used to run downstream pipelines based on tag pipelines in upstream projects.

Instead, use [CI/CD jobs with pipeline trigger tokens](https://docs.gitlab.com/ee/ci/triggers/#use-a-cicd-job) to trigger pipelines when another pipeline runs. This method is more reliable and flexible than pipeline subscriptions.

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### Running a single database is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.1</span>
- Removal in GitLab <span class="milestone">19.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/411239).

</div>

From GitLab 19.0, we will require a [separate database for CI features](https://gitlab.com/groups/gitlab-org/-/epics/7509).
We recommend running both databases on the same Postgres instance(s) due to ease of management for most deployments.

This change provides additional scalability for the largest of GitLab instances, like GitLab.com.
This change applies to all installation methods: Omnibus GitLab, GitLab Helm chart, GitLab Operator, GitLab Docker images, and installation from source.
Before upgrading to GitLab 19.0, please ensure you have [migrated](https://docs.gitlab.com/ee/administration/postgresql/multiple_databases.html) to two databases.

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### Single database connection is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">19.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/387898).

</div>

Previously, the [GitLab database](https://docs.gitlab.com/omnibus/settings/database.html)
configuration had a single `main:` section. This is being deprecated. The new
configuration has both a `main:` and a `ci:` section.

This deprecation affects users compiling GitLab from source, who will need
to [add the `ci:` section](https://docs.gitlab.com/ee/install/installation.html#configure-gitlab-db-settings).
Omnibus, the Helm chart, and Operator will handle this configuration
automatically from GitLab 16.0 onwards.

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### Slack notifications integration

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">19.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/435909).

</div>

As we're consolidating all Slack capabilities into the
GitLab for Slack app, we've deprecated the Slack notifications
integration.
Use the GitLab for Slack app to manage notifications
to your Slack workspace.

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### The `Project.services` GraphQL field is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">19.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/388424).

</div>

The `Project.services` GraphQL field is deprecated. A `Project.integrations` field is proposed instead in [issue 389904](https://gitlab.com/gitlab-org/gitlab/-/issues/389904).

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### `scanResultPolicies` GraphQL field is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.8</span>
- Removal in GitLab <span class="milestone">19.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/439199).

</div>

In 16.10, scan result policies were renamed to merge request approval policies to more accurately reflect the change in scope and capability for the policy type.

As a result, we updated the GraphQL endpoints. Use `approvalPolicies` instead of `scanResultPolicies`.

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### `sidekiq` delivery method for `incoming_email` and `service_desk_email` is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.0</span>
- Removal in GitLab <span class="milestone">19.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/398132).

</div>

The `sidekiq` delivery method for `incoming_email` and `service_desk_email` is deprecated and is
scheduled for removal in GitLab 19.0.

GitLab uses a separate process called `mail_room` to ingest emails. Currently, GitLab administrators
can configure their GitLab instances to use `sidekiq` or `webhook` delivery methods to deliver ingested
emails from `mail_room` to GitLab.

Using the deprecated `sidekiq` delivery method, `mail_room` writes the job data directly to the GitLab
Redis queue. This means that there is a hard coupling between the delivery method and the Redis
configuration. Another disadvantage is that framework optimizations such as job payload compression are missed.

Using the `webhook` delivery method, `mail_room` pushes the ingested email body to the GitLab
API. That way `mail_room` does not need to know your Redis configuration and the GitLab application
adds the processing job. `mail_room` authenticates with a shared secret key.

Reconfiguring an Omnibus installation generates this secret key file automatically,
so no secret file configuration setting is needed.

You can configure a custom secret key file (32 characters base 64 encoded) by running a command
like below and referencing the secret file in `incoming_email_secret_file` and
`service_desk_email_secret_file` (always specify the absolute path):

```shell
echo $( ruby -rsecurerandom -e "puts SecureRandom.base64(32)" ) > ~/.gitlab-mailroom-secret
```

If you run GitLab on more than one machine, you need to provide the secret key file for each machine.

We encourage GitLab administrators to switch to the webhook delivery method for
`incoming_email_delivery_method` and `service_desk_email_delivery_method` instead of `sidekiq`.

[Issue 393157](https://gitlab.com/gitlab-org/gitlab/-/issues/393157) tracks improving email ingestion in general.
We hope this will simplify infrastructure setup and add several improvements to how you manage GitLab in the near future.

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### `workflow:rules` templates

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.0</span>
- Removal in GitLab <span class="milestone">19.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/456394).

</div>

The [`workflow:rules`](https://docs.gitlab.com/ee/ci/yaml/workflow.html#workflowrules-templates) templates are deprecated and no longer recommended for use. Using these templates greatly limits the flexibility of your pipelines and makes it hard to use new `workflow` features.

This is one small step towards moving away from CI/CD templates in preference of [CI/CD components](https://docs.gitlab.com/ee/ci/components/). You can search the [CI/CD Catalog](https://docs.gitlab.com/ee/ci/components/#cicd-catalog) for a replacement, or [add `workflow:rules`](https://docs.gitlab.com/ee/ci/yaml/workflow.html) to your pipeline explicitly.

</div>
</div>

<div class="milestone-wrapper" data-milestone="18.0">

## GitLab 18.0

<div class="deprecation breaking-change" data-milestone="18.0">

### Amazon S3 Signature Version 2

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.8</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/container-registry/-/issues/1449).

</div>

Using Signature Version 2 to authenticate requests to Amazon S3 buckets in the container registry is deprecated.

To ensure continued compatibility and security, migrate to Signature Version 4. This change requires updating your S3 bucket configuration settings and ensuring that your GitLab container registry settings are compatible with Signature Version 4.

To migrate:

1. Check your S3 storage backend configuration in the GitLab container registry settings.
1. Remove the `v4auth: false` option if it's set.
1. Verify your existing credentials work with v4 authentication.

If you encounter any issues after making these changes, try regenerating your AWS credentials.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Application Security Testing analyzers major version update

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.9</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/513417).

</div>

The Application Security Testing stage will be bumping the major versions of its analyzers in
tandem with the GitLab 18.0 release.

If you are not using the default included templates, or have pinned your analyzer versions, you
must update your CI/CD job definition to either remove the pinned version or update
the latest major version.

Users of GitLab 17.0 to GitLab 15.11 will continue to experience analyzer updates until the
release of GitLab 18.0, after which all newly fixed bugs and released features will be
released only in the new major version of the analyzers.

We do not backport bugs and features to deprecated versions as per our maintenance policy. As
required, security patches will be backported within the latest 3 minor releases.

Specifically, the following analyzers are being deprecated and will no longer be updated after
the GitLab 18.0 release:

- GitLab Advanced SAST: version 1
- Container Scanning: version 7
- Dependency Scanning: version 0
- Gemnasium: [all versions](https://gitlab.com/gitlab-org/gitlab/-/issues/501308)
- DAST: version 5
- DAST API: version 4
- Fuzz API: version 4
- IaC Scanning: version 5
- Pipeline Secret Detection: version 6
- Static Application Security Testing (SAST): version 5 of [all analyzers](https://docs.gitlab.com/ee/user/application_security/sast/analyzers/)
  - `kics`
  - `kubesec`
  - `pmd-apex`
  - `semgrep`
  - `sobelow`
  - `spotbugs`

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Behavior change for Upcoming and Started milestone filters

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.7</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/501294).

</div>

The behavior of "Upcoming" and "Started" special filters is planned to change in upcoming GitLab major release 18.0.
The new behavior of both the filters is outlined in
[issue 429728](https://gitlab.com/gitlab-org/gitlab/-/issues/429728#proposed-issue-filter-logic-for-upcoming-and-started-milestones).

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### CI/CD job token - **Authorized groups and projects** allowlist enforcement

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.5</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/383084).

</div>

With the [**Authorized groups and projects** setting](https://docs.gitlab.com/ee/ci/jobs/ci_job_token.html#add-a-group-or-project-to-the-job-token-allowlist)
introduced in GitLab 15.9 (renamed from **Limit access _to_ this project** in GitLab 16.3), you can control CI/CD job token access to your project.
When set to **Only this project and any groups and projects in the allowlist**,
only groups or projects added to the allowlist can use job tokens to access your project.

For projects created before GitLab 15.9, the allowlist was disabled by default
([**All groups and projects**](https://docs.gitlab.com/ee/ci/jobs/ci_job_token.html#allow-any-project-to-access-your-project)
access setting selected), allowing job token access from any project.
The allowlist is now enabled by default in all new projects. In older
projects, it might still be disabled or you might have manually selected
the **All groups and projects** option to make access unrestricted.

Starting in GitLab 17.6, administrators for GitLab Self-Managed and GitLab Dedicated instances can optionally
[enforce this more secure setting for all projects](https://docs.gitlab.com/ee/administration/settings/continuous_integration.html#job-token-permissions).
This setting prevents project maintainers from selecting **All groups and projects**.
This change ensures a higher level of security between projects.
In GitLab 18.0, this setting will be enabled by default on GitLab.com, GitLab Self-Managed, and GitLab Dedicated.

To prepare for this change, project maintainers using job tokens for cross-project authentication
should populate their project's **Authorized groups and projects** allowlists. They should then change
the setting to **Only this project and any groups and projects in the allowlist**.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### CI/CD job token - **Limit access from your project** setting removal

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/395708).

</div>

In GitLab 14.4, we introduced a setting to [limit access _from_ your project's CI/CD job tokens (`CI_JOB_TOKEN`)](https://docs.gitlab.com/ee/ci/jobs/ci_job_token.html#limit-your-projects-job-token-access) to make it more secure.
This setting was called **Limit CI_JOB_TOKEN access**. In GitLab 16.3, we renamed this setting to **Limit access _from_ this project** for clarity.

In GitLab 15.9, we introduced an alternative setting called
[**Authorized groups and projects**](https://docs.gitlab.com/ee/ci/jobs/ci_job_token.html#add-a-group-or-project-to-the-job-token-allowlist).
This setting controls job token access _to_ your project by using an allowlist.
This new setting is a large improvement over the original. The first iteration is deprecated
in GitLab 16.0 and scheduled for removal in GitLab 18.0.

The **Limit access _from_ this project** setting is disabled by default for all new projects.
In GitLab 16.0 and later, you cannot re-enable this setting after it is disabled in any project.
Instead, use the **Authorized groups and projects** setting to control job token access to your projects.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### CodeClimate-based Code Quality scanning will be removed

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.3</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/471677).

</div>

In GitLab 18.0, we will remove CodeClimate-based Code Quality scanning.
In its place, you should use quality tools directly in your CI/CD pipeline and [provide the tool's report as an artifact](https://docs.gitlab.com/ee/ci/testing/code_quality.html#import-code-quality-results-from-a-cicd-job).
Many tools already support the required report format, and you can integrate them by following the [documented steps](https://docs.gitlab.com/ee/ci/testing/code_quality.html#integrate-common-tools-with-code-quality).

We expect to implement this change by:

1. Changing the [`Code-Quality.gitlab-ci.yml` CI/CD template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Code-Quality.gitlab-ci.yml) to no longer execute scans. Today, this template runs CodeClimate-based scans. (We plan to change the template rather than delete it to reduce the impact on any pipelines that still `include` the template after 18.0.)
1. No longer running CodeClimate-based scanning as part of Auto DevOps.

Effective immediately, CodeClimate-based scanning will receive only [limited updates](https://docs.gitlab.com/ee/update/terminology.html#deprecation).
After End of Support in GitLab 18.0, we won't provide further updates.
However, we won't delete previously published container images or remove the ability to run them by using custom CI/CD pipeline job definitions.

For more details, see [Scan code for quality violations](https://docs.gitlab.com/ee/ci/testing/code_quality.html#scan-code-for-quality-violations).

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Container Scanning default severity threshold set to `medium`

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.9</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/515358).

</div>

The Container Scanning security feature generates a lot of security findings and this volume is often difficult for engineering teams to manage.
By changing the severity threshold to `medium`, we provide a more reasonable default to our users, where any findings with a severity below `medium` are not reported.
Starting with GitLab 18.0, the default value for the `CS_SEVERITY_THRESHOLD` environment variable is set to `medium` instead of `unknown`. As a result, the security findings with the `low` and `unknown`
severity levels will no longer be reported by default. Consequently, any vulnerablity with these severities that were previously reported on the default branch will be marked as no longer detected
upon the next execution of Container Scanning.
To continue showing these findings, you must configure the `CS_SEVERITY_THRESHOLD` variable to the desired level.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Dependency Proxy token scope enforcement

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.9</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/426887).

</div>

The Dependency Proxy for containers accepts `docker login` and `docker pull` requests using personal access tokens or group access tokens without validating their scopes.

In GitLab 18.0, the Dependency Proxy will require both `read_registry` and `write_registry` scopes for authentication. After this change, authentication attempts using tokens without these scopes will be rejected.

This is a breaking change. Before you upgrade, create new access tokens with the [required scopes](https://docs.gitlab.com/ee/user/packages/dependency_proxy/#authenticate-with-the-dependency-proxy-for-container-images), and update your workflow variables and scripts with these new tokens.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Deprecate CI job implementation of Repository X-Ray

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.6</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/500146).

</div>

GitLab 18.0 removes the Repository X-Ray CI job:

- The initial implementation of [Repository X-Ray](https://docs.gitlab.com/ee/user/project/repository/code_suggestions/repository_xray.html), using a CI job, is deprecated in GitLab 17.6.
- This CI job is being replaced by an automated [background job](https://docs.gitlab.com/ee/user/project/repository/code_suggestions/repository_xray.html#how-repository-x-ray-works), triggered when a new commit is pushed to your project's default branch.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Deprecate License Scanning CI/CD artifact report type

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/439301).

</div>

The CI/CD [artifact report](https://docs.gitlab.com/ee/ci/yaml/artifacts_reports.html) type is deprecated in GitLab 16.9, and will be removed in GitLab 18.0. CI/CD configurations using this keyword will stop working in GitLab 18.0.

The artifact report type is no longer used because of the removal of the legacy License Scanning CI/CD job in GitLab 16.3.
Instead, you should use [License scanning of CycloneDX files](https://docs.gitlab.com/ee/user/compliance/license_scanning_of_cyclonedx_files/).

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Deprecate Terraform CI/CD templates

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/438010).

</div>

The Terraform CI/CD templates are deprecated and will be removed in GitLab 18.0.
This affects the following templates:

- `Terraform.gitlab-ci.yml`
- `Terraform.latest.gitlab-ci.yml`
- `Terraform/Base.gitlab-ci.yml`
- `Terraform/Base.latest.gitlab-ci.yml`

In GitLab 16.9, a new job is added to the templates to inform users of the deprecation.

GitLab won't be able to update the `terraform` binary in the job images to any version that
is licensed under BSL.

To continue using Terraform, clone the templates and [Terraform image](https://gitlab.com/gitlab-org/terraform-images),
and maintain them as needed.

As an alternative we recommend using the new OpenTofu CI/CD component on GitLab.com
or the new OpenTofu CI/CD template on GitLab Self-Managed.
CI/CD components are not yet available on GitLab Self-Managed,
but [Issue #415638](https://gitlab.com/gitlab-org/gitlab/-/issues/415638)
proposes to add this feature. If CI/CD components become available on GitLab Self-Managed,
the OpenTofu CI/CD template will be removed.

You can read more about the new OpenTofu CI/CD component [here](https://gitlab.com/components/opentofu).

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Deprecate license metadata format V1

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/438477).

</div>

The license metadata format V1 dataset has been deprecated and will be removed
in GitLab 18.0.

Users who have the `package_metadata_synchronization` feature flag enabled are advised to
upgrade to GitLab 16.3 or above, and remove the feature flag configuration.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Deprecation of `STORAGE` enum in `NamespaceProjectSortEnum` GraphQL API

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.7</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/396284).

</div>

The `STORAGE` enum in `NamespaceProjectSortEnum` of the GitLab GraphQL API will be removed in GitLab 18.0.

To prepare for this change, we recommend reviewing and updating your GraphQL queries that interact with the `NamespaceProjectSortEnum`. Replace any references to the `STORAGE` field with `EXCESS_REPO_STORAGE_SIZE_DESC`.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Deprecation of `name` field in `ProjectMonthlyUsageType` GraphQL API

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.7</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/381894).

</div>

The `name` field in the `ProjectMonthlyUsageType` of the GitLab GraphQL API will be removed in GitLab 18.0.

To prepare for this change, we recommend reviewing and updating your GraphQL queries that interact with the `ProjectMonthlyUsageType`. Replace any references to the `name` field with `project.name`.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Enforce keyset pagination on audit event API

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.8</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/382338).

</div>

The Audit Event APIs for instances, groups, and projects currently support optional keyset pagination. In GitLab 18.0
we will enforce keyset pagination on these APIs.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Fix typo in user profile visibility updated audit event type

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.8</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/474386).

</div>

To fix a typo in an audit event type, in GitLab 18.0 we'll rename the `user_profile_visiblity_updated` event type to
`user_profile_visibility_updated`.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### GitLab Advanced SAST will be enabled by default

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.9</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/513685).

</div>

In GitLab 18.0, we will update the [SAST CI/CD templates](https://docs.gitlab.com/ee/user/application_security/sast#stable-vs-latest-sast-templates) to enable [GitLab Advanced SAST](https://docs.gitlab.com/ee/user/application_security/sast/gitlab_advanced_sast) by default in projects with GitLab Ultimate.
Before this change, the GitLab Advanced SAST analyzer was enabled only if you set the CI/CD variable `GITLAB_ADVANCED_SAST_ENABLED` to `true`.

Advanced SAST delivers more accurate results by using cross-file, cross-function scanning and a new ruleset.
Advanced SAST takes over coverage for [supported languages](https://docs.gitlab.com/ee/user/application_security/sast/gitlab_advanced_sast#supported-languages) and disables scanning for that language in the previous scanner.
An automated process migrates results from previous scanners after the first scan on each project's default branch, if they're still detected.

Because it scans your project in more detail, Advanced SAST may take more time to scan your project.
If needed, you can [disable GitLab Advanced SAST](https://docs.gitlab.com/ee/user/application_security/sast/gitlab_advanced_sast#disable-gitlab-advanced-sast-scanning) by setting the CI/CD variable `GITLAB_ADVANCED_SAST_ENABLED` to `false`.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### GitLab Runner platforms and setup instructions in GraphQL API

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/387937).

</div>

The `runnerPlatforms` and `runnerSetup` queries to get GitLab Runner platforms and installation instructions
are deprecated and will be removed from the GraphQL API. For installation instructions, you should use the
[GitLab Runner documentation](https://docs.gitlab.com/runner/)

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### GitLab Runner registration token in Runner Operator

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.6</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/382077).

</div>

The [`runner-registration-token`](https://docs.gitlab.com/runner/install/operator.html#install-the-kubernetes-operator) parameter that uses the OpenShift and Kubernetes Vanilla Operator to install a runner on Kubernetes is deprecated. Authentication tokens will be used to register runners instead. Registration tokens, and support for certain configuration arguments,
will be removed in GitLab 18.0. For more information, see [Migrating to the new runner registration workflow](https://docs.gitlab.com/ee/ci/runners/new_creation_workflow.html).
The configuration arguments disabled for authentication tokens are:

- `--locked`
- `--access-level`
- `--run-untagged`
- `--tag-list`

This change is a breaking change. You must use an [authentication token](https://docs.gitlab.com/ee/ci/runners/runners_scope.html) in the `gitlab-runner register` command instead.

See also how to [prevent your runner registration workflow from breaking](https://docs.gitlab.com/ee/ci/runners/new_creation_workflow.html#prevent-your-runner-registration-workflow-from-breaking) in GitLab 17.0 and later.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### GitLab Runner support for Alpine versions

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.7</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38369).

</div>

GitLab Runner versions 17.7 and later support only a single Alpine version (`latest`) instead of specific versions.
Alpine versions 3.18 and 3.19 will be supported to the stated EOL date. In contrast, Ubuntu 20.04, as an LTS release,
will be supported to its EOL date, at which point we will move to the most recent LTS release.

When you upgrade an Alpine container, make sure your container image uses
[a supported named version](https://docs.gitlab.com/runner/install/support-policy.html),
`latest` (for GitLab Runner images), or `alpine-latest` (for GitLab Runner helper images).

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### GitLab chart use of NGINX controller image v1.3.1

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.6</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5794).

</div>

In GitLab 17.6, the GitLab chart updated the default NGINX controller image to v1.11.2. This new version requires new RBAC rules that were added to our Ingress
NGINX-bundled subchart.

This change is being backported to 17.5.1, 17.4.3, and 17.3.6.

Some users prefer to manage RBAC rules themselves by setting the Helm key `nginx-ingress.rbac.create` to `false`. To give time for users who manage their own RBAC rules to
add the new required rules before they adopt the new v1.11.2 version, we've implemented a fallback mechanism to detect `nginx-ingress.rbac.create: false` and force the chart
to keep using NGINX image v1.3.1, which does not need the new RBAC rules.

If you manage your own NGINX RBAC rules, but you also want to take advantage of the new NGINX controller image v1.11.2 immediately:

1. Add the new RBAC rules to your cluster [like we did](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3901/diffs?commit_id=93a3cbdb5ad83db95e12fa6c2145df0800493d8b).
1. Set `nginx-ingress.controller.image.disableFallback` to true.

We plan to remove this fallback support and support for NGINX controller image v1.3.1 in GitLab 18.0.

You can read more about it in the [charts release page](https://docs.gitlab.com/charts/releases/8_0.html#upgrade-to-86x-851-843-836).

</div>

<div class="deprecation " data-milestone="18.0">

### Gitaly rate limiting

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.7</span>
- Removal in GitLab <span class="milestone">18.0</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitaly/-/issues/5011).

</div>

Because of the highly variable nature of Git operations and repository latencies, Gitaly
[RPC-based rate limiting](https://docs.gitlab.com/ee/administration/gitaly/monitoring.html#monitor-gitaly-rate-limiting)
is ineffective. Configuring proper rate limits is challenging and often becomes obsolete quickly because harmful
actions rarely generate enough requests per second to stand out.

Gitaly already supports [concurrency limiting](https://docs.gitlab.com/ee/administration/gitaly/concurrency_limiting.html) and an
[adaptive limiting add-on](https://docs.gitlab.com/ee/administration/gitaly/concurrency_limiting.html#adaptive-concurrency-limiting),
which have proven to work well in production.

Because Gitaly is not directly exposed to external networks and external protection layers, such as load balancers,
provide better safeguards, rate limiting is less effective.

Therefore, we're depecating rate limiting in favor of the more reliable concurrency limiting. Gitaly RPC-based
rate limiting will be removed in GitLab 18.0.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### GraphQL `target` field for to-do items replaced with `targetEntity`

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.4</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/484987).

</div>

Under certain circumstances, the `target` field on a to-do item can be null. The GraphQL schema currently declares this field as non-nullable. The new `targetEntity` field is nullable and replaces the non-nullable `target` field.
Update any GraphQL queries that use the `currentUser.todos.target` field to use the new `currentUser.todos.targetEntity` field instead.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### GraphQL deprecation of `dependencyProxyTotalSizeInBytes` field

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.1</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/414236).

</div>

You can use GraphQL to query the amount of storage used by the GitLab Dependency Proxy. However, the `dependencyProxyTotalSizeInBytes` field is limited to about 2 gigabytes, which is not always large enough for the Dependency Proxy. As a result, `dependencyProxyTotalSizeInBytes` is deprecated and will be removed in GitLab 17.0.

Use `dependencyProxyTotalSizeBytes` instead, introduced in GitLab 16.1.

</div>

<div class="deprecation " data-milestone="18.0">

### Group vulnerability report by OWASP top 10 2017 is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.0</span>
- Removal in GitLab <span class="milestone">18.0</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/458835).

</div>

Grouping the vulnerability report by OWASP top 10 2017 is deprecated, replaced by grouping by OWASP top 10 2021.
In the future we will support the most recent version of OWASP top 10 for grouping on the vulnerability report.
Along with this change we are also deprecating and removing the 2017 GraphQL API enums which the feature uses. Additional details are included in [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/488433).

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Guest users can pull packages from private projects on GitLab.com

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.6</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/336622).

</div>

Starting in 18.0, Guest users on GitLab.com will be able to pull packages from private projects. This is the same ability that Guest users already have on GitLab Self-Managed.

This change streamlines package sharing capabilities within organizations and simplifies access management for package consumers by providing consistent behavior across all GitLab deployments.

Project Owners and Maintainers should review their private projects' lists of members. Users with the Guest role who should not have package pulling capabilities should be removed. If more restrictive package access is required, consider using project access tokens instead of guest role.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Increased default security for use of pipeline variables

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.7</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/502382).

</div>

GitLab believes in secure-by-default practices. To honor this, we are making some changes to support least privilege principles relating to the use of CI/CD variables.
Today, users with the Developer role or higher are able to use [pipeline variables](https://docs.gitlab.com/ee/ci/variables/#use-pipeline-variables) by default, without any verification or opt-in.
In 18.0, GitLab is updating the [pipeline variable restrictions](https://docs.gitlab.com/ee/ci/variables/#restrict-pipeline-variables) to default enabled.
As a result of this change, the ability to use pipeline CI/CD variables will be restricted for all users by default.
If necessary, you can manually update this setting with a minimum role that is allowed to use pipeline variables, though it's recommended to keep this as restricted as possible.

You can already start using a more secure-by-default experience for pipeline variables by enabling the current setting with the Project settings API, to increase the allowed role to Maintainers and above.
You can also raise the minimum role to the recommended [Owner only, or no one](https://docs.gitlab.com/ee/ci/variables/#set-a-minimum-role-for-pipeline-variables).
Starting in 17.7, this will be the default for all new projects in new namespaces on GitLab.com.
We also plan to make this easier to manage by adding an option to control this from the project settings UI.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Legacy Geo Prometheus repository checks metrics

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.9</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/426659).

</div>

Following the migration of projects to the [Geo self-service framework](https://docs.gitlab.com/ee/development/geo/framework.html) we have removed the support for [repository checks](https://docs.gitlab.com/ee/administration/repository_checks.html) using `git fsck` on Geo secondary sites.
The following Geo-related [Prometheus](https://docs.gitlab.com/ee/administration/monitoring/prometheus/) metrics are deprecated and will be removed in GitLab 18.0.
The table below lists the deprecated metrics and their respective replacements. The replacements are available in GitLab 16.3.0 and later.

| Deprecated metric                 |  Replacement metric        |
| --------------------------------- | -------------------------- |
| `geo_repositories`                | `geo_project_repositories` |
| `geo_repositories_checked`        |  None available            |
| `geo_repositories_checked_failed` |  None available            |

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Legacy Web IDE is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.9</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/513938).

</div>

The legacy Vue-based GitLab Web IDE implementation will be removed from GitLab.
This change follows our successful transition to the GitLab VSCode Fork-based Web IDE,
which has been the default Web IDE experience since GitLab 15.11.

This removal affects users who are still accessing the legacy Web IDE implementation.

To prepare for this removal, enable the `vscode_web_ide` feature flag on your GitLab instance
if it was previously disabled in the GitLab instance.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Limit number of scan execution policy actions allowed per policy

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.5</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/510897).

</div>

New limits have been added for maximum scan execution policy actions allowed per policy. This change was introduced in 17.4 behind feature flags `scan_execution_policy_action_limit` and `scan_execution_policy_action_limit_group`. When enabled, only the first 10 actions of a scan execution policy are processed.

By adding limits, we can ensure performance and scalability for security policies.

If additional actions are needed, limit existing polices to no more than 10 actions. Then, create new scan execution policies with additional actions, within the limit of 5 scan execution policies per security policy project.

For GitLab Self-Managed administrators, you can configure a custom limit with the `scan_execution_policies_action_limit` application setting.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### OpenTofu CI/CD template

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.1</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/components/opentofu/-/issues/43#note_1913822299).

</div>

We introduced the OpenTofu CI/CD template in 16.8 as CI/CD components were not available for GitLab Self-Managed yet.
With the introduction of [GitLab CI/CD components for GitLab Self-Managed](https://docs.gitlab.com/ee/ci/components/#use-a-gitlabcom-component-in-a-self-managed-instance)
we are removing the redundant OpenTofu CI/CD templates in favor of the CI/CD components.

For information about migrating from the CI/CD template to the component, see the [OpenTofu component documentation](https://gitlab.com/components/opentofu#usage-on-self-managed).

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Pipeline job limits extended to the Commits API

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.7</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/436361).

</div>

Starting in GitLab 18.0, the maximum [number of jobs in active pipelines](https://docs.gitlab.com/ee/administration/instance_limits.html#number-of-jobs-in-active-pipelines) will also apply when creating jobs using the [Commits API](https://docs.gitlab.com/ee/api/commits.html#set-the-pipeline-status-of-a-commit). Review your integration to ensure it stays within the configured job limits.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Pipelines API cancel endpoint returns error for non-cancelable pipelines

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.6</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/414963).

</div>

The Pipelines API cancel endpoint [`POST /projects/:id/pipelines/:pipeline_id/cancel`](https://docs.gitlab.com/ee/api/pipelines.html#cancel-a-pipelines-jobs)
returns a `200` success response regardless of whether a pipeline can be canceled.
Starting in GitLab 18.0, the endpoint will return a `422 Unprocessable Entity` error when a pipeline cannot be canceled.
Update your API integration to handle the `422` status code when making pipeline cancellation requests.

</div>

<div class="deprecation " data-milestone="18.0">

### Project page in group settings is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.0</span>
- End of Support in GitLab <span class="milestone">17.9</span>
- Removal in GitLab <span class="milestone">18.0</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/443347).

</div>

Group owners can access a project page in the group settings that lists the projects the group contains, with options to create, edit, or delete a project, as well as a link to the Members page for each project.
All of this functionality is available on the group overview page and the respective Member pages of the projects.
Due to low usage of the project page in the group settings and its limited accessibility, this page will be deprecated.
This change affects only the user interface. The underlying API will remain available, so project creation, edits, and deletions can still be performed using the [Projects API](https://docs.gitlab.com/ee/api/projects.html).
In 17.9, we will implement a redirect to the group overview page from this page.
The project page will be removed entirely from the group settings in 18.0.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Public use of Secure container registries is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.4</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/470641).

</div>

Container registries under `registry.gitlab.com/gitlab-org/security-products/`
are no longer accessible in GitLab 18.0. [Since GitLab 14.8](https://docs.gitlab.com/ee/update/deprecations.html#secure-and-protect-analyzer-images-published-in-new-location)
the correct location is under `registry.gitlab.com/security-products` (note the absence of
`gitlab-org` in the address).

This change improves the security of the release process for GitLab [vulnerability scanners](https://docs.gitlab.com/ee/user/application_security/#vulnerability-scanner-maintenance).

Users are advised to use the equivalent registry under `registry.gitlab.com/security-products/`,
which is the canonical location for GitLab security scanner images. The relevant GitLab CI
templates already use this location, so no changes should be necessary for users that use the
unmodified templates.

Offline deployments should review the [specific scanner instructions](https://docs.gitlab.com/ee/user/application_security/offline_deployments/#specific-scanner-instructions)
to ensure the correct locations are being used to mirror the required scanner images.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### REST API endpoint `pre_receive_secret_detection_enabled` is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.9</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/514413).

</div>

The REST API endpoint `pre_receive_secret_detection_enabled` is deprecated in favor of `secret_push_protection_enabled`. We are renaming some API fields to reflect the name change of the feature `pre_receive_secret_detection` to `secret_push_protection`.
To avoid breaking workflows that use the old name, you should stop using the `pre_receive_secret_detection_enabled` endpoint before GitLab 18.0. Instead, use the new `secret_push_protection_enabled` endpoint.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Rate limits for common User, Project, and Group API endpoints

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.4</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/480914).

</div>

Rate limits will be enabled by default for commonly used [User](https://docs.gitlab.com/ee/administration/settings/user_and_ip_rate_limits.html),
[Project](https://docs.gitlab.com/ee/administration/settings/rate_limit_on_projects_api.html), and [Group](https://docs.gitlab.com/ee/administration/settings/rate_limit_on_groups_api.html) endpoints.
Enabling these rate limits by default can help improve overall system stability,
by reducing the potential for heavy API usage to negatively impact the broader user experience. Requests made above the rate
limit will return an [HTTP 429](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/429) error code and [additional rate limit headers](https://docs.gitlab.com/ee/administration/settings/user_and_ip_rate_limits.html#response-headers).

The default rate limits have been intentionally set fairly high to not disrupt most usage, based on the request rates we see on GitLab.com.
Instance administrators can set higher or lower limits as needed in the Admin area, similarly to other rate limits already in place.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Registration tokens and server-side runner arguments in `POST /api/v4/runners` endpoint

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.6</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/379743).

</div>

The support for registration tokens and certain runner configuration arguments in the `POST` method operation on the `/api/v4/runners` endpoint is deprecated.
This endpoint [registers](https://docs.gitlab.com/ee/api/runners.html#create-a-runner) a runner
with a GitLab instance at the instance, group, or project level through the API. In GitLab 18.0, registration tokens, and support for certain configuration arguments,
will start returning the HTTP `410 Gone` status code. For more information, see [Migrating to the new runner registration workflow](https://docs.gitlab.com/ee/ci/runners/new_creation_workflow.html#prevent-your-runner-registration-workflow-from-breaking).

The configuration arguments disabled for runner authentication tokens are:

- `--locked`
- `--access-level`
- `--run-untagged`
- `--maximum-timeout`
- `--paused`
- `--tag-list`
- `--maintenance-note`

This change is a breaking change. You should [create a runner in the UI](https://docs.gitlab.com/ee/ci/runners/runners_scope.html) to add configurations, and use the runner authentication token in the `gitlab-runner register` command instead.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Registration tokens and server-side runner arguments in `gitlab-runner register` command

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.6</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/380872).

</div>

Registration tokens and certain configuration arguments in the command `gitlab-runner register` that [registers](https://docs.gitlab.com/runner/register/) a runner, are deprecated.
Authentication tokens will be used to register runners instead. Registration tokens, and support for certain configuration arguments,
will be removed in GitLab 18.0. For more information, see [Migrating to the new runner registration workflow](https://docs.gitlab.com/ee/ci/runners/new_creation_workflow.html).
The configuration arguments disabled for authentication tokens are:

- `--locked`
- `--access-level`
- `--run-untagged`
- `--maximum-timeout`
- `--paused`
- `--tag-list`
- `--maintenance-note`

This change is a breaking change. You should [create a runner in the UI](https://docs.gitlab.com/ee/ci/runners/runners_scope.html) to add configurations, and use the authentication token in the `gitlab-runner register` command instead.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Removal of `migrationState` field in `ContainerRepository` GraphQL API

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.6</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/459869).

</div>

The `migrationState` field in the `ContainerRepositoryType` of the GitLab GraphQL API will be removed in GitLab 18.0. This deprecation is part of our efforts to streamline and improve our API.

To prepare for this change, we recommend reviewing and updating your GraphQL queries that interact with the `ContainerRepositoryType`. Remove any references to the `migrationState` field and adjust your application logic accordingly.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Remove `previousStageJobsOrNeeds` from GraphQL

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.0</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/424417).

</div>

The `previousStageJobsOrNeeds` field in GraphQL will be removed as it has been replaced by the `previousStageJobs` and `needs` fields.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Remove duoProAssignedUsersCount GraphQL field

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.9</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/498671).

</div>

In 18.0 we are removing the `duoProAssignedUsersCount` GraphQL field. Users may experience issues if they are using this field with the [`aiMetrics` API](https://docs.gitlab.com/ee/api/graphql/reference/#aimetrics), and instead they can use the `duoAssignedUsersCount`. This removal is part of the [fix to count both GitLab Duo Pro and Duo seats assigned users](https://gitlab.com/gitlab-org/gitlab/-/issues/485510).

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Rename `setPreReceiveSecretDetection` GraphQL mutation to `setSecretPushProtection`

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.7</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/514414).

</div>

The `setPreReceiveSecretDetection` GraphQL mutation has been renamed to `setSecretPushProtection`. We are also renaming some fields in the mutation's response to reflect the name change of the feature `pre_receive_secret_detection` to `secret_push_protection`.
To avoid breaking workflows that use the old name, before GitLab 18.0 you should:

- Stop using the old mutation name `setPreReceiveSecretDetection`. Instead, use the name `setSecretPushProtection`.
- Change any references to the field `pre_receive_secret_detection_enabled` to `secret_push_protection_enabled`.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Rename options to skip GitGuardian secret detection

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.3</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/470119).

</div>

The options to skip GitGuardian secret detection, `[skip secret detection]` and `secret_detection.skip_all`, are deprecated and will be removed in GitLab 18.0. You should use `[skip secret push protection]` and `secret_push_protection.skip_all` instead.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Replace GraphQL field `take_ownership_pipeline_schedule` with `admin_pipeline_schedule` in PipelineSchedulePermissions

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/391941).

</div>

The GraphQL field `take_ownership_pipeline_schedule` will be deprecated. To
determine if a user can take ownership of a pipeline schedule, use the
`admin_pipeline_schedule` field instead.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Replace `add_on_purchase` GraphQL field with `add_on_purchases`

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.4</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/476858).

</div>

The GraphQL field `add_on_purchase` will be deprecated in GitLab 17.4 and removed in GitLab 18.0. Use the `add_on_purchases` field instead.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Replace `threshold` with `maxretries` for container registry notifications

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.1</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/container-registry/-/issues/1243).

</div>

You can configure the container registry to send [webhook notifications](https://docs.gitlab.com/ee/administration/packages/container_registry.html#configure-container-registry-notifications) in response to events happening in the registry. The configuration uses the `threshold` and `backoff` parameters to specify how many failures are allowed before backing off for a period of time before retrying.

The problem is that the event will be held in memory forever until it is successful or the registry is shut down. This is not ideal as it can cause high memory and CPU usage on the registry side if the events are not sent properly. It will also delay any new events added to the queue of events.

A new `maxretries` parameter has been added to control how many times an event will be retried before dropping the event. As such, we have deprecated the `threshold` parameter in favor of `maxretries` so that events are not held in memory forever.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Replace namespace `add_on_purchase` GraphQL field with `add_on_purchases`

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.5</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/489850).

</div>

The namespace GraphQL field `add_on_purchase` will be deprecated in GitLab 17.5 and removed in GitLab 18.0. Use the root `add_on_purchases` field instead.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Runner `active` GraphQL fields replaced by `paused`

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/351109).

</div>

Occurrences of the `active` identifier in the GitLab GraphQL API endpoints will be renamed to `paused` in GitLab 18.0:

- The `CiRunner` property.
- The `RunnerUpdateInput` input type for the `runnerUpdate` mutation.
- The `runners`, `Group.runners`, and `Project.runners` queries.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### RunnersRegistrationTokenReset GraphQL mutation is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.7</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/505703).

</div>

The support for runner registration tokens is deprecated. Consequently, the support for resetting a registration token has also been deprecated
and will be removed in GitLab 18.0.

A new method to bind runners to a GitLab instance has been implemented
as part of the new [GitLab Runner token architecture](https://docs.gitlab.com/ee/ci/runners/new_creation_workflow.html).
For details, see [epic 7633](https://gitlab.com/groups/gitlab-org/-/epics/7633).
This new architecture introduces a new method for registering runners and eliminates the legacy
[runner registration token](https://docs.gitlab.com/ee/security/tokens/#runner-registration-tokens-deprecated).
In GitLab 18.0, only the runner registration methods implemented in the new GitLab Runner token architecture will be supported.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### SAST jobs no longer use global cache settings

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.9</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/512564).

</div>

In GitLab 18.0, we will update SAST and IaC Scanning to explicitly [disable the use of the CI/CD job cache](https://docs.gitlab.com/ee/ci/caching/#disable-cache-for-specific-jobs) by default.

This change affects the CI/CD templates for:

- SAST: `SAST.gitlab-ci.yml`.
- IaC Scanning: `SAST-IaC.gitlab-ci.yml`.

We already updated the `latest` templates `SAST.latest.gitlab-ci.yml` and `SAST-IaC.latest.gitlab-ci.yml`. See [stable and latest templates](https://docs.gitlab.com/ee/user/application_security/sast/#stable-vs-latest-sast-templates) for more details on these template versions.

The cache directories are not in scope for scanning in most projects, so fetching the cache can cause timeouts or false-positive results.

If you need to use the cache when scanning a project, you can restore the previous behavior by [overriding](https://docs.gitlab.com/ee/user/application_security/sast/#overriding-sast-jobs) the
[`cache`](https://docs.gitlab.com/ee/ci/yaml/#cache) property in the project's CI configuration.

</div>

<div class="deprecation " data-milestone="18.0">

### Secret detection analyzer doesn't run as root user by default

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.9</span>
- Removal in GitLab <span class="milestone">18.0</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/476160).

</div>

From GitLab 18.0, the secret detection analyzer will no longer use the root user by default. You shouldn't experience any impact as a result of this change. However, you might experience issues if you use `before_script` or `after_script` to make changes to the image. GitLab doesn't support this use of `before_script` and `after_script`.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Subscription related API endpoints in the public API are deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.9</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/515371#note_2319368251).

</div>

The following endpoints in the public REST API will be removed:

- `POST /api/v4/namespaces/:namespace_id/minutes`
- `GET /api/v4/namespaces/:namespace_id/subscription_add_on_purchase/:id`
- `POST /api/v4/namespaces/:id/gitlab_subscription`
- `PUT /api/v4/namespaces/:id/gitlab_subscription`
- `PUT /api/v4/user/:id/credit_card_validation`
- `PUT /api/v4/namespaces/:namespace_id/subscription_add_on_purchase/:id`
- `POST /api/v4/namespaces/:namespace_id/subscription_add_on_purchase/:id`
- `PATCH /api/v4/namespaces/:previous_namespace_id/minutes/move/:target_namespace_id`
- `DELETE /api/v4/internal/upcoming_reconciliations`
- `PUT /api/v4/internal/upcoming_reconciliations`
- `PUT /api/v4/namespaces/:id`

These endpoints were being used by the Subscription Portal to manage subscription information on GitLab.com. Their
usage has been replaced by internal endpoints with JWT authentication to support the upcoming Cells architecture.
The endpoints in the public API are being removed so that they are not accidentally used again, and to reduce
the maintenance burden as they start to drift in functionality.

You shouldn't experience any impact as a result of this change, as these are endpoints that were used internally.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Support for REST API endpoints that reset runner registration tokens

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.7</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/383341).

</div>

The support for runner registration tokens is deprecated. As a consequence, the REST API endpoints to reset a registration token are also deprecated and will
return the HTTP `410 Gone` status code in GitLab 18.0.
The deprecated endpoints are:

- `POST /runners/reset_registration_token`
- `POST /projects/:id/runners/reset_registration_token`
- `POST /groups/:id/runners/reset_registration_token`

We plan to implement a new method to bind runners to a GitLab instance
as part of the new [GitLab Runner token architecture](https://docs.gitlab.com/ee/ci/runners/new_creation_workflow.html).
The work is planned in [this epic](https://gitlab.com/groups/gitlab-org/-/epics/7633).
This new architecture introduces a new method for registering runners and will eliminate the legacy
[runner registration token](https://docs.gitlab.com/ee/security/tokens/#runner-registration-tokens-deprecated).
From GitLab 18.0 and later, the runner registration methods implemented by the new GitLab Runner token architecture will be the only supported methods.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Support for SUSE Linux Enterprise Server 15 SP2

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.9</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8888).

</div>

Long term service and support (LTSS) for SUSE Linux Enterprise Server (SLES) 15 SP2 ended in December 2024.

Therefore, we will no longer support the SLES SP2 distribution for Linux package installs. You should upgrade to
SLES 15 SP6 for continued support.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### The GitLab legacy requirement IID is deprecated in favor of work item IID

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390263).

</div>

We will be transitioning to a new IID as a result of moving requirements to a [work item type](https://docs.gitlab.com/ee/development/work_items.html#work-items-and-work-item-types). Users should begin using the new IID as support for the legacy IID and existing formatting will end in GitLab 18.0. The legacy requirement IID remains available until its removal in GitLab 18.0.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### The `ci_job_token_scope_enabled` projects API attribute is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.4</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/423091).

</div>

GitLab 16.1 introduced [API endpoints for the job token scope](https://gitlab.com/gitlab-org/gitlab/-/issues/351740). In the [projects API](https://docs.gitlab.com/ee/api/projects.html), the `ci_job_token_scope_enabled` attribute is deprecated, and will be removed in 17.0. You should use the [job token scope APIs](https://docs.gitlab.com/ee/api/project_job_token_scopes.html) instead.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### The `direction` GraphQL argument for `ciJobTokenScopeRemoveProject` is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/383084).

</div>

The `direction` GraphQL argument for the `ciJobTokenScopeRemoveProject` mutation is deprecated. Following the [default CI/CD job token scope change](https://docs.gitlab.com/ee/update/deprecations.html#default-cicd-job-token-ci_job_token-scope-changed) announced in GitLab 15.9, the `direction` argument will default to `INBOUND` and `OUTBOUND` will no longer be valid in GitLab 17.0. We will remove the `direction` argument in GitLab 18.0.

If you are using `OUTBOUND` with the `direction` argument to control the direction of your project's token access, your pipeline that use job tokens risk failing authentication. To ensure pipelines continue to run as expected, you will need to explicitly [add the other projects to your project's allowlist](https://docs.gitlab.com/ee/ci/jobs/ci_job_token.html#add-a-group-or-project-to-the-job-token-allowlist).

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### The `heroku/builder:22` image is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.4</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/cluster-integration/auto-build-image/-/issues/79).

</div>

The cloud native buildpack (CNB) builder image was updated to `heroku/builder:24` in the Auto DevOps Build project. While we don't expect the changes to be disruptive for the most part, this might be a breaking change for some users of Auto DevOps, and especially users of Auto Build. To better understand the impact of you workloads, review the following:

- [Heroku-24 stack release notes](https://devcenter.heroku.com/articles/heroku-24-stack#what-s-new)
- [Heroku-24 stack upgrade notes](https://devcenter.heroku.com/articles/heroku-24-stack#upgrade-notes)
- [Heroku stack packages](https://devcenter.heroku.com/articles/stack-packages)

These changes affect you if your pipelines use the [`auto-build-image`](https://gitlab.com/gitlab-org/cluster-integration/auto-build-image) provided by [the Auto Build stage of Auto DevOps](https://docs.gitlab.com/ee/topics/autodevops/stages.html#auto-build).

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Toggle notes confidentiality on APIs

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.10</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/350670).

</div>

Toggling notes confidentiality with REST and GraphQL APIs is being deprecated. Updating notes confidential attribute is no longer supported by any means. We are changing this to simplify the experience and prevent private information from being unintentionally exposed.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Updated tooling to release CI/CD components to the Catalog

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.7</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/groups/gitlab-org/-/epics/12788).

</div>

Starting in GitLab 18.0, the internal process that releases CI/CD components to the Catalog will be changed.
If you use the [recommended CI/CD component release process](https://docs.gitlab.com/ee/ci/components/#publish-a-new-release), which makes use of the `release` keyword and the `registry.gitlab.com/gitlab-org/release-cli:latest` container image, you do not need to make any changes.
The `latest` version of this container image (`v0.20.0`) contains [GLab](https://gitlab.com/gitlab-org/cli/) `v1.50.0`, which will be used for all releases to the CI/CD Catalog in GitLab 18.0 and later.
In other cases:

- If you need to pin the container image to a specific version, use `v0.20.0` or later (`registry.gitlab.com/gitlab-org/release-cli:v0.20.0`),
  to ensure GLab is available for the release process.
- If you've manually installed the Release CLI tool on your runners, you must install GLab `v1.50.0` or later on those runners.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Workspaces `editor` GraphQL field is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.8</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/508155).

</div>

The `editor` field is not used internally. It will be deprecated in the following GraphQL elements:

- `Workspace` type.
- Input to `workspaceCreate` mutation.

To prepare for this change:

- Review and update your GraphQL queries that interact with the `Workspace` type.
- Remove any references to the `editor` field.
- Adjust your application logic accordingly.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### ZenTao integration

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.7</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/377825).

</div>

The [ZenTao product integration](https://docs.gitlab.com/ee/user/project/integrations/zentao.html) has been deprecated
and will be moved to the JiHu GitLab codebase.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `GITLAB_SHARED_RUNNERS_REGISTRATION_TOKEN` is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.11</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/453949).

</div>

The [`GITLAB_SHARED_RUNNERS_REGISTRATION_TOKEN`](https://docs.gitlab.com/ee/administration/environment_variables.html#supported-environment-variables) environment variable is deprecated. GitLab introduced a new [GitLab Runner token architecture](https://docs.gitlab.com/ee/architecture/blueprints/runner_tokens/) in GitLab 15.8, which introduces a new method for registering runners and eliminates the legacy runner registration token. Please refer to the [documentation](https://docs.gitlab.com/ee/ci/runners/new_creation_workflow.html) for guidance on migrating to the new workflow.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `RemoteDevelopmentAgentConfig` GraphQL type is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.9</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/509787).

</div>

The `RemoteDevelopmentAgentConfig` type is no longer used internally. It is deprecated in the `ClusterAgent` type.

To prepare for this change:

- Review and update your GraphQL queries that interact with the `RemoteDevelopmentAgentConfig` type.
- Switch over to the experimental type `workspacesAgentConfig`.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `ciJobTokenScopeAddProject` GraphQL mutation is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.5</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/474175).

</div>

With the [upcoming default behavior change to the CI/CD job token](https://docs.gitlab.com/ee/update/deprecations.html#default-cicd-job-token-ci_job_token-scope-changed) in GitLab 18.0, we are also deprecating the associated `ciJobTokenScopeAddProject` GraphQL mutation as the associated feature will be no longer be available.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `ciMinutesUsed` GraphQL field renamed to `ciDuration`

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.5</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/497364).

</div>

The `ciDuration` field of the `CiRunnerUsage` and `CiRunnerUsageByProject` types replaces the former `ciMinutesUsed` field.
Update all references to `ciMinutesUsed` from these types to `ciDuration`.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `defaultMaxHoursBeforeTermination` and `maxHoursBeforeTerminationLimit` fields are deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.9</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/509787).

</div>

The `defaultMaxHoursBeforeTermination` and `maxHoursBeforeTerminationLimit` fields are no longer used internally.
They are deprecated in the `WorkspacesAgentConfig` type.

This removal extends to the [agent configuration](https://docs.gitlab.com/ee/user/workspace/gitlab_agent_configuration.html#workspace-settings)
file associated with your workspaces setup.

To prepare for this change:

- Review and update your GraphQL queries that interact with the `WorkspacesAgentConfig` type.
- Remove any references to the `defaultMaxHoursBeforeTermination` and `maxHoursBeforeTerminationLimit` fields.
- Remove the fields `default_max_hours_before_termination` and `max_hours_before_termination_limit` from your agent configuration file.
- Adjust your application logic accordingly.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `git_data_dirs` for configuring Gitaly storages

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.0</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8786).

</div>

Support for using `git_data_dirs` to configure Gitaly storages for Linux package instances has been deprecated
[since 16.0](https://docs.gitlab.com/ee/update/versions/gitlab_16_changes.html#gitaly-configuration-structure-change) and will be removed in 18.0.

For migration instructions, see
[Migrating from `git_data_dirs`](https://docs.gitlab.com/omnibus/settings/configuration.html#migrating-from-git_data_dirs).

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `maxHoursBeforeTermination` GraphQL field is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.9</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/509787).

</div>

The `maxHoursBeforeTermination` GraphQL field is no longer used internally. It is deprecated in the following GraphQL elements:

- `Workspace` type.
- Input to `workspaceCreate` mutation.

To prepare for this change:

- Review and update your GraphQL queries that interact with the `Workspace` type.
- Remove any references to the `maxHoursBeforeTermination` field.
- Adjust your application logic accordingly.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `mergeTrainIndex` and `mergeTrainsCount` GraphQL fields deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.5</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/473759).

</div>

The GraphQL field `mergeTrainIndex` and `mergeTrainsCount` in `MergeRequest` are deprecated. To
determine the position of the merge request on the merge train use the
`index` field in `MergeTrainCar` instead. To get the count of MRs in a merge train,
use `count` from `cars` in `MergeTrains::TrainType` instead.

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `runnerRegistrationToken` parameter for GitLab Runner Helm Chart

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.6</span>
- Removal in GitLab <span class="milestone">18.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/381111).

</div>

The [`runnerRegistrationToken`](https://docs.gitlab.com/runner/install/kubernetes.html) parameter to use the GitLab Helm Chart to install a runner on Kubernetes is deprecated.

We plan to implement a new method to bind runners to a GitLab instance leveraging `runnerToken`
as part of the new [GitLab Runner token architecture](https://docs.gitlab.com/ee/ci/runners/new_creation_workflow.html).
The work is planned in [this epic](https://gitlab.com/groups/gitlab-org/-/epics/7633).

From GitLab 18.0 and later, the methods to register runners introduced by the new GitLab Runner token architecture will be the only supported methods.

</div>
</div>

<div class="milestone-wrapper" data-milestone="17.9">

## GitLab 17.9

<div class="deprecation " data-milestone="17.9">

### Support for openSUSE Leap 15.5

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.6</span>
- Removal in GitLab <span class="milestone">17.9</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8778).

</div>

Long term service and support (LTSS) for [openSUSE Leap ends in December 2024](https://en.opensuse.org/Lifetime#openSUSE_Leap).

Therefore, we will no longer support the openSUSE Leap 15.5 distribution for Linux package installs. Users should upgrade to
openSUSE Leap 15.6 for continued support.

</div>
</div>

<div class="milestone-wrapper" data-milestone="17.8">

## GitLab 17.8

<div class="deprecation " data-milestone="17.8">

### Support for CentOS 7

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.6</span>
- Removal in GitLab <span class="milestone">17.8</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8714).

</div>

Long term service and support (LTSS) for [CentOS 7 ended in June 2024](https://www.redhat.com/en/topics/linux/centos-linux-eol).

Therefore, we will no longer support the CentOS 7 distribution for Linux package installs. Users should upgrade to
another operating system for continued support.

</div>

<div class="deprecation " data-milestone="17.8">

### Support for Oracle Linux 7

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.6</span>
- Removal in GitLab <span class="milestone">17.8</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8746).

</div>

Long term service and support (LTSS) for [Oracle Linux 7 ends in December 2024](https://wiki.debian.org/LTS).

Therefore, we will no longer support the Oracle Linux 7 distribution for Linux package installs. Users should upgrade to
Oracle Linux 8 for continued support.

</div>

<div class="deprecation " data-milestone="17.8">

### Support for Raspberry Pi OS Buster

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.6</span>
- Removal in GitLab <span class="milestone">17.8</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8734).

</div>

Long term service and support (LTSS) for Raspberry Pi OS Buster (formerly known as Raspbian Buster) ended in June 2024.

Therefore, we will no longer support the PiOS Buster distribution for Linux package installs. Users should upgrade to
PiOS Bullseye for continued support.

</div>

<div class="deprecation " data-milestone="17.8">

### Support for Red Hat Enterprise Linux 7

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.6</span>
- Removal in GitLab <span class="milestone">17.8</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8714).

</div>

Red Hat Enterprise Linux (RHEL) 7 reached [end of maintenance support in June 2024](https://www.redhat.com/en/technologies/linux-platforms/enterprise-linux/rhel-7-end-of-maintenance).

Therefore, we will no longer publish Linux packages for RHEL 7 and RHEL 7 compatible operating systems.
Users should upgrade to RHEL 8 for continued support.

</div>

<div class="deprecation " data-milestone="17.8">

### Support for Scientific Linux 7

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.6</span>
- Removal in GitLab <span class="milestone">17.8</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8745).

</div>

Long term service and support (LTSS) for [Scientific Linux 7 ended in June 2024](https://scientificlinux.org/downloads/sl-versions/sl7/).

Therefore, we will no longer support the Scientific Linux distribution for Linux package installs. Users should upgrade to
another RHEL-compatible operating system.

</div>
</div>

<div class="milestone-wrapper" data-milestone="17.7">

## GitLab 17.7

<div class="deprecation " data-milestone="17.7">

### TLS 1.0 and 1.1 no longer supported

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.4</span>
- Removal in GitLab <span class="milestone">17.7</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164512).

</div>

Long term support (LTS) for [OpenSSL version 1.1.1 ended in September 2023](https://endoflife.date/openssl). Therefore, OpenSSL 3 will be the default in GitLab 17.7. GitLab bundles OpenSSL 3, so you are not required to make any changes to your operating system.

With the upgrade to OpenSSL 3:

- GitLab requires TLS 1.2 or higher for all outgoing and incoming TLS connections.
- TLS/SSL certificates must have at least 112 bits of security. RSA, DSA, and DH keys shorter than 2048 bits, and ECC keys shorter than 224 bits are prohibited.

See the [GitLab 17.5 changes](https://docs.gitlab.com/ee/update/versions/gitlab_17_changes.html#1750) for more details.

</div>
</div>

<div class="milestone-wrapper" data-milestone="17.6">

## GitLab 17.6

<div class="deprecation " data-milestone="17.6">

### Support for Debian 10

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.3</span>
- Removal in GitLab <span class="milestone">17.6</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8607).

</div>

Long term service and support (LTSS) for [Debian 10 ended in June 2024](https://wiki.debian.org/LTS).

Therefore, we will no longer support the Debian 10 distribution for Linux package installs. Users should upgrade to
Debian 11 or Debian 12 for continued support.

</div>
</div>

<div class="milestone-wrapper" data-milestone="17.4">

## GitLab 17.4

<div class="deprecation " data-milestone="17.4">

### Removed Needs tab from the pipeline view

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.1</span>
- Removal in GitLab <span class="milestone">17.4</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/336560).

</div>

We are removing the Needs tab from the pipeline view, as it duplicates the information displayed in the regular pipeline view with the **Job dependencies** grouping option. We will continue improving the views in the main pipeline graph in the future.

</div>
</div>

<div class="milestone-wrapper" data-milestone="17.3">

## GitLab 17.3

<div class="deprecation " data-milestone="17.3">

### FIPS-compliant Secure analyzers will change from UBI Minimal to UBI Micro

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.2</span>
- Removal in GitLab <span class="milestone">17.3</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/471869).

</div>

We're updating the base image of some of the analyzers used to scan your code for security vulnerabilities.
We're only changing the analyzer images that are already based on Red Hat Universal Base Image (UBI), so this change only affects you if you've specifically enabled [FIPS mode](https://docs.gitlab.com/ee/development/fips_compliance.html) for security scanning.
The default images that GitLab security scans use are not affected because they aren't based on UBI.

In GitLab 17.3, we will change the base image of the UBI-based analyzers from UBI Minimal to [UBI Micro](https://www.redhat.com/en/blog/introduction-ubi-micro), which includes fewer unnecessary packages and omits a package manager.
The updated images will be smaller and will be affected by fewer vulnerabilities in packages provided by the operating system.

The GitLab Support Team's [Statement of Support](https://about.gitlab.com/support/statement-of-support/#ci-cd-templates) excludes undocumented customizations, including those that rely on specific contents of the analyzer image.
For example, installing additional packages in a `before_script` is not a supported modification.
Nevertheless, if you rely on this type of customization, see the [deprecation issue for this change](https://gitlab.com/gitlab-org/gitlab/-/issues/471869#action-required) to learn how to respond to this change or to provide feedback about your current customizations.

</div>
</div>

<div class="milestone-wrapper" data-milestone="17.0">

## GitLab 17.0

<div class="deprecation breaking-change" data-milestone="17.0">

### Agent for Kubernetes option `ca-cert-file` renamed

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/437728).

</div>

In the GitLab agent for Kubernetes (agentk), the `--ca-cert-file` command line option
and the corresponding `config.caCert` Helm chart value have been renamed
to `--kas-ca-cert-file` and `config.kasCaCert`, respectively.

The old `--ca-cert-file` and `config.caCert` options are deprecated, and will
be removed in GitLab 17.0.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Auto DevOps support for Herokuish is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/211643).

</div>

Auto DevOps support for Herokuish is deprecated in favor of [Cloud Native Buildpacks](https://docs.gitlab.com/ee/topics/autodevops/stages.html#auto-build-using-cloud-native-buildpacks). You should [migrate your builds from Herokuish to Cloud Native Buildpacks](https://docs.gitlab.com/ee/topics/autodevops/stages.html#moving-from-herokuish-to-cloud-native-buildpacks). From GitLab 14.0, Auto Build uses Cloud Native Buildpacks by default.

Because Cloud Native Buildpacks do not support automatic testing, the Auto Test feature of Auto DevOps is also deprecated.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Autogenerated Markdown anchor links with dash (`-`) characters

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/440733).

</div>

GitLab automatically creates anchor links for all headings, so you can link to
a specific place in a Markdown document or wiki page. But in some edge cases,
the autogenerated anchor is created with fewer dash (`-`) characters than many users expect.
For example, with a heading with `## Step - 1`, most other Markdown tools and linters would expect `#step---1`.
But GitLab generates an anchor of `#step-1`, with consecutive dashes compressed down to one.

In GitLab 17.0, we will align our autogenerated anchors to the industry standard by no longer stripping consecutive dashes.
If you have Markdown documents and link to headings that could have multiple dashes in 17.0,
you should update the heading to avoid this edge case. With the example above, you
can change `## Step - 1` to `## Step 1` to ensure in-page links continue to work.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### CiRunner.projects default sort is changing to `id_desc`

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.0</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/372117).

</div>

The `CiRunner.projects`'s field default sort order value will change from `id_asc` to `id_desc`.
If you rely on the order of the returned projects to be `id_asc`, change your scripts to make the choice explicit.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Compliance framework in general settings

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/422783).

</div>

We moved compliance framework management to the framework and projects reports in the
[Compliance Center](https://docs.gitlab.com/ee/user/compliance/compliance_center/).

Therefore, in GitLab 17.0, we are removing the management of compliance frameworks from the **General** settings page of groups and projects.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Container registry support for the Swift and OSS storage drivers

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.6</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/container-registry/-/issues/1141).

</div>

The container registry uses storage drivers to work with various object storage platforms. While each driver's code is relatively self-contained, there is a high maintenance burden for these drivers. Each driver implementation is unique and making changes to a driver requires a high level of domain expertise with that specific driver.

As we look to reduce maintenance costs, we are deprecating support for OSS (Object Storage Service) and OpenStack Swift. Both have already been removed from the upstream Docker Distribution. This helps align the container registry with the broader GitLab product offering with regards to [object storage support](https://docs.gitlab.com/ee/administration/object_storage.html#supported-object-storage-providers).

OSS has an [S3 compatibility mode](https://www.alibabacloud.com/help/en/oss/developer-reference/compatibility-with-amazon-s3), so consider using that if you can't migrate to a supported driver. Swift is [compatible with S3 API operations](https://docs.openstack.org/swift/latest/s3_compat.html), required by the S3 storage driver as well.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### DAST ZAP advanced configuration variables deprecation

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.7</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/383467).

</div>

With the new browser-based DAST analyzer GA in GitLab 15.7, we are working towards making it the default DAST analyzer at some point in the future. In preparation for this, the following legacy DAST variables are being deprecated and scheduled for removal in GitLab 17.0: `DAST_ZAP_CLI_OPTIONS` and `DAST_ZAP_LOG_CONFIGURATION`. These variables allowed for advanced configuration of the legacy DAST analyzer, which was based on OWASP ZAP. The new browser-based analyzer will not include the same functionality, as these were specific to how ZAP worked.

These three variables will be removed in GitLab 17.0.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Dependency Scanning incorrect SBOM metadata properties

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/438779).

</div>

GitLab 17.0 removes support for the following metadata properties in CycloneDX SBOM reports:

- `gitlab:dependency_scanning:input_file`
- `gitlab:dependency_scanning:package_manager`

These properties were added in GitLab 15.7 to the SBOM produced by Dependency Scanning. However, these properties were incorrect and didn't align with the [GitLab CycloneDX property taxonomy](https://docs.gitlab.com/ee/development/sec/cyclonedx_property_taxonomy.html).
The following correct properties were added in GitLab 15.11 to address this:

- `gitlab:dependency_scanning:input_file:path`
- `gitlab:dependency_scanning:package_manager:name`

The incorrect properties were kept for backward compatibility. They are now deprecated and will be removed in 17.0.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Dependency Scanning support for sbt 1.0.X

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.8</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/415835).

</div>

Supporting very old versions of sbt is preventing us from improving our support for additional use cases with this package manager without increasing our maintenance cost.

Version 1.1.0 of sbt was released 6 years ago, and users are advised to upgrade from 1.0.x as Dependency Scanning will no longer work.

</div>

<div class="deprecation " data-milestone="17.0">

### Deprecate GraphQL fields related to the temporary storage increase

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.7</span>
- Removal in GitLab <span class="milestone">17.0</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/385720).

</div>

The GraphQL fields, `isTemporaryStorageIncreaseEnabled` and `temporaryStorageIncreaseEndsOn`, have been deprecated. These GraphQL fields are related to the temporary storage increase project. The project has been canceled and the fields were not used.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Deprecate Grype scanner for Container Scanning

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/439164).

</div>

Support for the Grype scanner in the GitLab Container Scanning analyzer is deprecated in
GitLab 16.9.

From GitLab 17.0, the Grype analyzer will no longer be maintained, except for limited fixes as
explained in our [statement of support](https://about.gitlab.com/support/statement-of-support/#version-support).

Users are advised to use the default setting for `CS_ANALYZER_IMAGE`, which uses the Trivy
scanner.

The existing current major version for the Grype analyzer image will continue to be updated
with the latest advisory database, and operating system packages until GitLab 19.0, at which
point the analyzer will stop working.

To continue to use Grype past 19.0, see the [Security scanner integration documentation](https://docs.gitlab.com/ee/development/integrations/secure.html)
to learn how to create your own integration with GitLab.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Deprecate License Scanning CI templates

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/439157).

</div>

GitLab 17.0 removes the License Scanning CI templates:

- [`Jobs/License-Scanning.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/6d9956863d3cd066edc50a29767c2cd4a939c6fd/lib/gitlab/ci/templates/Jobs/License-Scanning.gitlab-ci.yml)
- [`Jobs/License-Scanning.latest.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/6d9956863d3cd066edc50a29767c2cd4a939c6fd/lib/gitlab/ci/templates/Jobs/License-Scanning.latest.gitlab-ci.yml)
- [`Security/License-Scanning.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/6d9956863d3cd066edc50a29767c2cd4a939c6fd/lib/gitlab/ci/templates/Security/License-Scanning.gitlab-ci.yml)

CI configurations including any of the templates above will stop working in GitLab 17.0.

Users are advised to use [License scanning of CycloneDX files](https://docs.gitlab.com/ee/user/compliance/license_scanning_of_cyclonedx_files/) instead.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Deprecate Python 3.9 in Dependency Scanning and License Scanning

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/441201).

</div>

From GitLab 16.9, Dependency Scanning and License Scanning support for Python 3.9 is deprecated. In GitLab 17.0, Python 3.10 is the default version for the Dependency Scanning CI/CD job.

From GitLab 17.0, Dependency Scanning and License Scanning features won't support projects that require Python 3.9 without a
[compatible lockfile](https://docs.gitlab.com/ee/user/application_security/dependency_scanning/#obtaining-dependency-information-by-parsing-lockfiles).

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Deprecate Windows CMD in GitLab Runner

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.1</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/414864).

</div>

In GitLab 11.11 the Windows Batch executor, the CMD shell was deprecated in GitLab Runner in favor of PowerShell. Since then, the CMD shell has continued to be supported in GitLab Runner. However this has resulted in additional complexity for both the engineering team and customers using the Runner on Windows. We plan to fully remove support for Windows CMD from GitLab Runner in 17.0. Customers should plan to use PowerShell when using the runner on Windows with the shell executor. Customers can provide feedback or ask questions in the removal issue, [issue 29479](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29479).

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Deprecate `CiRunner` GraphQL fields duplicated in `CiRunnerManager`

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.2</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/415185).

</div>

These fields (`architectureName`, `ipAddress`, `platformName`, `revision`, `version`) are now deprecated from the [GraphQL `CiRunner`](https://docs.gitlab.com/ee/api/graphql/reference/#cirunner) type as they are duplicated with the introduction of runner managers grouped within a runner configuration.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Deprecate `fmt` job in Terraform Module CI/CD template

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/440249).

</div>

The `fmt` job in the Terraform Module CI/CD templates is deprecated and will be removed in GitLab 17.0.
This affects the following templates:

- `Terraform-Module.gitlab-ci.yml`
- `Terraform/Module-Base.gitlab-ci.yml`

You can manually add back a Terraform `fmt` job to your pipeline using:

```yaml
fmt:
  image: hashicorp/terraform
  script: terraform fmt -chdir "$TF_ROOT" -check -diff -recursive
```

You can also use the `fmt` template from the [OpenTofu CI/CD component](https://gitlab.com/components/opentofu).

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Deprecate `message` field from Vulnerability Management features

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.1</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/411573).

</div>

This MR deprecates the `message` field on the `VulnerabilityCreate` GraphQL mutation, and in the `AdditionalInfo` column of the vulnerability export.
The message field was removed from security reports schema in GitLab 16.0 and is no longer being used elsewhere.

</div>

<div class="deprecation " data-milestone="17.0">

### Deprecate `terminationGracePeriodSeconds` in the GitLab Runner Kubernetes executor

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.3</span>
- End of Support in GitLab <span class="milestone">17.0</span>
- Removal in GitLab <span class="milestone">17.0</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28165).

</div>

The GitLab Runner Kubernetes executor setting, `terminationGracePeriodSeconds`, is deprecated and will be removed in GitLab 17.0. To manage the cleanup and termination of GitLab Runner worker pods on Kubernetes, customers should instead configure `cleanupGracePeriodSeconds` and `podTerminationGracePeriodSeconds`. For information about how to use the `cleanupGracePeriodSeconds` and `podTerminationGracePeriodSeconds`, see the [GitLab Runner Executor documentation](https://docs.gitlab.com/runner/executors/kubernetes/#other-configtoml-settings).

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Deprecate `version` field in feature flag API

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/437986).

</div>

The `version` field in the [feature flag REST API](https://docs.gitlab.com/ee/api/feature_flags.html)
is deprecated and will be removed in GitLab 17.0.

After the `version` field is removed, there won't be a way to create legacy feature flags.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Deprecate change vulnerability status from the Developer role

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.4</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/424133).

</div>

The ability for Developers to change the status of vulnerabilities is now deprecated. We plan to make a breaking change in the upcoming GitLab 17.0 release to remove this ability from the Developer role. Users who wish to continue to grant this permission to developers can [create a custom role](https://docs.gitlab.com/ee/user/permissions.html#custom-roles) for their developers and add in the `admin_vulnerability` permission to give them this access.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Deprecate custom role creation for group owners on GitLab Self-Managed

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/439284).

</div>

In GitLab Self-Managed 17.0, custom role creation will be removed for group Owners. This functionality will move to the instance level for administrators only.
Group Owners will be able to assign custom roles at the group level.

Group owners on GitLab.com can continue to manage custom roles and assign at the group level.

If using the API to manage custom roles on GitLab Self-Managed, a new instance endpoint has been added and is required to continue API operations.

- List all member roles on the instance - `GET /api/v4/member_roles`
- Add member role to the instance - `POST /api/v4/member_roles`
- Remove member role from the instance - `DELETE /api/v4/member_roles/:id`

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Deprecate field `hasSolutions` from GraphQL VulnerabilityType

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.3</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/414895).

</div>

The GraphQL field `Vulnerability.hasSolutions` is deprecated and will be removed in GitLab 17.0.
Use `Vulnerability.hasRemediations` instead.

</div>

<div class="deprecation " data-milestone="17.0">

### Deprecate legacy shell escaping and quoting runner shell executor

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.11</span>
- Removal in GitLab <span class="milestone">17.0</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/406679).

</div>

The runner's legacy escape sequence mechanism to handle variable expansion implements a sub-optimal implementation of Ansi-C quoting. This method means that the runner would expand arguments included in double quotes. As of 15.11, we are deprecating the legacy escaping and quoting methods in the runner shell executor.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Deprecated parameters related to custom text in the sign-in page

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.2</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124461).

</div>

The parameters, `sign_in_text` and `help_text`, are deprecated in the [Settings API](https://docs.gitlab.com/ee/api/settings.html). To add a custom text to the sign-in and sign-up pages, use the `description` field in the [Appearance API](https://docs.gitlab.com/ee/api/appearance.html).

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Deprecating Windows Server 2019 in favor of 2022

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/438554).

</div>

We have recently announced the release of Windows Server 2022 for our GitLab.com runners on Windows (Beta). With it, we are deprecating Windows 2019 in GitLab 17.0.

For more information about how to migrate to using Windows 2022, see [Windows 2022 support for GitLab.com runners now available](https://about.gitlab.com/blog/2024/01/22/windows-2022-support-for-gitlab-saas-runners/).

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### DingTalk OmniAuth provider

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.10</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390855).

</div>

The `omniauth-dingtalk` gem that provides GitLab with the DingTalk OmniAuth provider will be removed in our next
major release, GitLab 17.0. This gem sees very little use and is better suited for JiHu edition.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Duplicate storages in Gitaly configuration

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.10</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitaly/-/issues/5598).

</div>

Support for configuring multiple Gitaly storages that point to the same storage path is deprecated and will be removed in GitLab 17.0
In GitLab 17.0 and later, this type of configuration will cause an error.

We're removing support for this type of configuration because it can cause problems with background repository
maintenance and will not be compatible with future Gitaly storage implementations.

Instance administrators must update the `storage` entries of the `gitaly['configuration']`
section in `gitlab.rb` configuration file to ensure each storage is configured with a unique path.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### File type variable expansion fixed in downstream pipelines

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.6</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/419445).

</div>

Previously, if you tried to reference a [file type CI/CD variable](https://docs.gitlab.com/ee/ci/variables/#use-file-type-cicd-variables) in another CI/CD variable, the CI/CD variable would expand to contain the contents of the file. This behavior was incorrect because it did not comply with typical shell variable expansion rules. The CI/CD variable reference should expand to only contain the path to the file, not the contents of the file itself. This was [fixed for most use cases in GitLab 15.7](https://gitlab.com/gitlab-org/gitlab/-/issues/29407). Unfortunately, passing CI/CD variables to downstream pipelines was an edge case not yet fixed, but which will now be fixed in GitLab 17.0.

With this change, a variable configured in the `.gitlab-ci.yml` file can reference a file variable and be passed to a downstream pipeline, and the file variable will be passed to the downstream pipeline as well. The downstream pipeline will expand the variable reference to the file path, not the file contents.

This breaking change could disrupt user workflows that depend on expanding a file variable in a downstream pipeline.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Geo: Legacy replication details routes for designs and projects deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.4</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/424002).

</div>

As part of the migration of legacy data types to the [Geo self-service framework](https://docs.gitlab.com/ee/development/geo/framework.html), the following replication details routes are deprecated:

- Designs `/admin/geo/replication/designs` replaced by `/admin/geo/sites/<Geo Node/Site ID>/replication/design_management_repositories`
- Projects `/admin/geo/replication/projects` replaced by `/admin/geo/sites/<Geo Node/Site ID>/replication/projects`

From GitLab 16.4 to 17.0, lookups for the legacy routes will automatically be redirected to the new routes. We will remove the redirections in 17.0. Please update any bookmarks or scripts that may use the legacy routes.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GitLab Helm chart values `gitlab.kas.privateApi.tls.*` are deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/4097).

</div>

We introduced the `global.kas.tls.*` Helm values to facilitate TLS communication between KAS and your Helm chart components.
The old values `gitlab.kas.privateApi.tls.enabled` and `gitlab.kas.privateApi.tls.secretName` are deprecated and scheduled for removal in GitLab 17.0.

Because the new values provide a streamlined, comprehensive method to enable TLS for KAS, you should use `global.kas.tls.*` instead of `gitlab.kas.privateApi.tls.*`. The `gitlab.kas.privateApi.tls.*` For more information, see:

- The [merge request](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/2888) that introduces the `global.kas.tls.*` values.
- The [deprecated `gitlab.kas.privateApi.tls.*` documentation](https://docs.gitlab.com/charts/charts/gitlab/kas/#enable-tls-communication-through-the-gitlabkasprivateapi-attributes-deprecated).
- The [new `global.kas.tls.*` documentation](https://docs.gitlab.com/charts/charts/globals.html#tls-settings-1).

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GitLab Runner provenance metadata SLSA v0.2 statement

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.8</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36869).

</div>

Runners generate provenance metadata and currently defaults to generating statements that adhere to SLSA v0.2. Because SLSA v1.0 has been released and is now supported by GitLab, the v0.2 statement is now deprecated and removal is planned in GitLab 17.0. The SLSA v1.0 statement is planned to become the new default statement format in GitLab 17.0.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GraphQL API access through unsupported methods

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">17.0</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/442520).

</div>

From GitLab 17.0, we limiting access to GraphQL to only through the
[already documented supported token types](https://docs.gitlab.com/ee/api/graphql/#token-authentication).

For customers already using documented and supported token types, there are no breaking changes.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GraphQL `networkPolicies` resource deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/421440).

</div>

The `networkPolicies` [GraphQL resource](https://docs.gitlab.com/ee/api/graphql/reference/#projectnetworkpolicies) has been deprecated and will be removed in GitLab 17.0. Since GitLab 15.0 this field has returned no data.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GraphQL field `confidential` changed to `internal` on notes

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.5</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/371485).

</div>

The `confidential` field for a `Note` will be deprecated and renamed to `internal`.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GraphQL field `registrySizeEstimated` has been deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.2</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/416509).

</div>

For clarity, the GraphQL field `registrySizeEstimated` was renamed to `containerRegistrySizeIsEstimated`, to match its counterpart.
`registrySizeEstimated` was deprecated in GitLab 16.2 and will be removed in GitLab 17.0.
Use `containerRegistrySizeIsEstimated` introduced in GitLab 16.2 instead.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GraphQL field `totalWeight` is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.3</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/416219).

</div>

You can use GraphQL to query the total weight of issues in an issue board. However, the `totalWeight` field is limited to the maximum size 2147483647. As a result, `totalWeight` is deprecated and will be removed in GitLab 17.0.

Use `totalIssueWeight` instead, introduced in GitLab 16.2.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GraphQL type, `RunnerMembershipFilter` renamed to `CiRunnerMembershipFilter`

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.0</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/409333).

</div>

The GraphQL type, `RunnerMembershipFilter`, has been renamed to `CiRunnerMembershipFilter`. In GitLab 17.0,
the aliasing for the `RunnerMembershipFilter` type will be removed.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GraphQL: The `DISABLED_WITH_OVERRIDE` value for the `SharedRunnersSetting` enum is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/385636).

</div>

In GitLab 17.0, the `DISABLED_WITH_OVERRIDE` value of the `SharedRunnersSetting` GraphQL enum type will be removed.
Use `DISABLED_AND_OVERRIDABLE` instead.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GraphQL: deprecate support for `canDestroy` and `canDelete`

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.6</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390754).

</div>

The Package Registry user interface relies on the GitLab GraphQL API. To make it easy for everyone to contribute, it's important that the frontend is coded consistently across all GitLab product areas. Before GitLab 16.6, however, the Package Registry UI handled permissions differently from other areas of the product.

In 16.6, we added a new `UserPermissions` field under the `Types::PermissionTypes::Package` type to align the Package Registry with the rest of GitLab. This new field replaces the `canDestroy` field under the `Package`, `PackageBase`, and `PackageDetailsType` types. It also replaces the field `canDelete` for `ContainerRepository`, `ContainerRepositoryDetails`, and `ContainerRepositoryTag`. In GitLab 17.0, the `canDestroy` and `canDelete` fields will be removed.

This is a breaking change that will be completed in 17.0.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### HashiCorp Vault integration will no longer use the `CI_JOB_JWT` CI/CD job token by default

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/366798).

</div>

As part of our effort to improve the security of your CI workflows using JWT and OIDC, the native HashiCorp integration is also being updated in GitLab 16.0. Any projects that use the [`secrets:vault`](https://docs.gitlab.com/ee/ci/yaml/#secretsvault) keyword to retrieve secrets from Vault will need to be [configured to use the ID tokens](https://docs.gitlab.com/ee/ci/secrets/id_token_authentication.html#configure-automatic-id-token-authentication). ID tokens were introduced in 15.7.

To prepare for this change, use the new [`id_tokens`](https://docs.gitlab.com/ee/ci/yaml/#id_tokens)
keyword and configure the `aud` claim. Ensure the bound audience is prefixed with `https://`.

In GitLab 15.9 to 15.11, you can [enable the **Limit JSON Web Token (JWT) access**](https://docs.gitlab.com/ee/ci/secrets/id_token_authentication.html#enable-automatic-id-token-authentication)
setting, which prevents the old tokens from being exposed to any jobs and enables
[ID token authentication for the `secrets:vault` keyword](https://docs.gitlab.com/ee/ci/secrets/id_token_authentication.html#configure-automatic-id-token-authentication).

In GitLab 16.0 and later:

- This setting will be removed.
- CI/CD jobs that use the `id_tokens` keyword can use ID tokens with `secrets:vault`,
  and will not have any `CI_JOB_JWT*` tokens available.
- Jobs that do not use the `id_tokens` keyword will continue to have the `CI_JOB_JWT*`
  tokens available until GitLab 17.0.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Heroku image upgrade in Auto DevOps build

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/437937).

</div>

In GitLab 17.0, the `auto-build-image` project will upgrade from the `heroku/builder:20` image to `heroku/builder:22`.

To test the behavior of the new image, set the CI/CD variable `AUTO_DEVOPS_BUILD_IMAGE_CNB_BUILDER` to
`heroku/builder:22`.

To continue to use `heroku/builder:20` after GitLab 17.0,
set `AUTO_DEVOPS_BUILD_IMAGE_CNB_BUILDER` to `heroku/builder:20`.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Internal container registry API tag deletion endpoint

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.4</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/container-registry/-/issues/1094).

</div>

The Docker Registry HTTP API V2 Spec, later replaced by the [OCI Distribution Spec](https://github.com/opencontainers/distribution-spec/blob/main/spec.md) did not include a tag delete operation, and an unsafe and slow workaround (involving deleting manifests, not tags) had to be used to achieve the same end.

Tag deletion is an important function, so we added a tag deletion operation to the GitLab container registry, extending the V2 API beyond the scope of the Docker and OCI distribution spec.

Since then, the OCI Distribution Spec has had some updates and it now has a tag delete operation, using the [`DELETE /v2/<name>/manifests/<tag>` endpoint](https://github.com/opencontainers/distribution-spec/blob/main/spec.md#deleting-tags).

This leaves the container registry with two endpoints that provide the exact same functionality. `DELETE /v2/<name>/tags/reference/<tag>` is the custom GitLab tag delete endpoint and `DELETE /v2/<name>/manifests/<tag>`, the OCI compliant tag delete endpoint introduced in GitLab 16.4.

Support for the custom GitLab tag delete endpoint is deprecated in GitLab 16.4, and it will be removed in GitLab 17.0.

This endpoint is used by the **internal** container registry application API, not the public [GitLab container registry API](https://docs.gitlab.com/ee/api/container_registry.html). No action should be required by the majority of container registry users. All the GitLab UI and API functionality related to tag deletions will remain intact as we transition to the new OCI-compliant endpoint.

If you do access the internal container registry API and use the original tag deletion endpoint, you must update to the new endpoint.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### JWT `/-/jwks` instance endpoint is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.7</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/221031).

</div>

With the [deprecation of old JSON web token versions](https://docs.gitlab.com/ee/update/deprecations.html?removal_milestone=17.0#old-versions-of-json-web-tokens-are-deprecated) in GitLab 17.0, the associated `/-/jwks` endpoint, which is an alias for `/oauth/discovery/keys`, is no longer necessary and will be removed.
If you've been specifying `jwks_url` in your auth configuration, update your configuration to `oauth/discovery/keys` instead and remove all uses of `/-/jwks` in your endpoints.
If you've already been using `oauth_discovery_keys` in your auth configuration and the `/-/jwks` alias in your endpoints, remove `/-/jwks` from your endpoints. For example, change `https://gitlab.example.com/-/jwks` to `https://gitlab.example.com`.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Legacy Geo Prometheus metrics

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.6</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/430192).

</div>

Following the migration of projects to the [Geo self-service framework](https://docs.gitlab.com/ee/development/geo/framework.html) we have deprecated a number of [Prometheus](https://docs.gitlab.com/ee/administration/monitoring/prometheus/) metrics.
The following Geo-related Prometheus metrics are deprecated and will be removed in 17.0.
The table below lists the deprecated metrics and their respective replacements. The replacements are available in GitLab 16.3.0 and later.

| Deprecated metric                        |  Replacement metric                            |
| ---------------------------------------- | ---------------------------------------------- |
| `geo_repositories_synced`                | `geo_project_repositories_synced`              |
| `geo_repositories_failed`                | `geo_project_repositories_failed`              |
| `geo_repositories_checksummed`           | `geo_project_repositories_checksummed`         |
| `geo_repositories_checksum_failed`       | `geo_project_repositories_checksum_failed`     |
| `geo_repositories_verified`              | `geo_project_repositories_verified`            |
| `geo_repositories_verification_failed`   | `geo_project_repositories_verification_failed` |
| `geo_repositories_checksum_mismatch`     |  None available                                |
| `geo_repositories_retrying_verification` |  None available                                |

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### License List is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.8</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/436100).

</div>

Today in GitLab you can see a list of all of the licenses your project and the components that
use that license on the License List. As of 16.8, the License List
is deprecated and scheduled to be removed in 17.0 as a breaking change.
With the release of the [Group Dependency List](https://docs.gitlab.com/ee/user/application_security/dependency_list/)
and the ability to filter by license on the project and group Dependency List, you can now
access all of the licenses your project or group is using on the Dependency List.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### License Scanning support for sbt 1.0.X

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.8</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/437591).

</div>

GitLab 17.0 removes License Scanning support for sbt 1.0.x.

Users are advised to upgrade from sbt 1.0.x.

</div>

<div class="deprecation " data-milestone="17.0">

### Linux packages for Ubuntu 18.04

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.8</span>
- Removal in GitLab <span class="milestone">17.0</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8082).

</div>

Standard support for Ubuntu 18.04 [ended on June 2023](https://wiki.ubuntu.com/Releases).

From GitLab 17.0, we will not provide Linux packages for Ubuntu 18.04.

To prepare for GitLab 17.0 and later:

1. Move servers running GitLab instances from Ubuntu 18.04 to either Ubuntu 20.04 or Ubuntu 22.04.
1. Upgrade your GitLab instances using Linux package for the version of Ubuntu you're now using.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### List repository directories Rake task

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.7</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/384361).

</div>

The `gitlab-rake gitlab:list_repos` Rake task does not work and will be removed in GitLab 17.0.
If you're migrating GitLab, use
[backup and restore](https://docs.gitlab.com/ee/administration/operations/moving_repositories.html#recommended-approach-in-all-cases)
instead.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Maintainer role providing the ability to change Package settings using GraphQL API

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/370471).

</div>

The ability for users with the Maintainer role to change the **Packages and registries** settings for a group using
the GraphQL API is deprecated in GitLab 15.8 and will be removed in GitLab 17.0. These settings include:

- [Allowing or preventing duplicate package uploads](https://docs.gitlab.com/ee/user/packages/maven_repository/#do-not-allow-duplicate-maven-packages).
- [Package request forwarding](https://docs.gitlab.com/ee/user/packages/maven_repository/#request-forwarding-to-maven-central).
- [Enabling lifecycle rules for the Dependency Proxy](https://docs.gitlab.com/ee/user/packages/dependency_proxy/reduce_dependency_proxy_storage.html).

In GitLab 17.0 and later, you must have the Owner role for a group to change the **Packages and registries**
settings for the group using either the GitLab UI or GraphQL API.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Maven versions below 3.8.8 support in Dependency Scanning and License Scanning

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/438772).

</div>

GitLab 17.0 drops Dependency Scanning and License Scanning support for Maven versions below 3.8.8.

Users are advised to upgrade to 3.8.8 or greater.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Min concurrency and max concurrency in Sidekiq options

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/439687).

</div>

- For Linux package (Omnibus) installations, the [`sidekiq['min_concurrency']` and `sidekiq['max_concurrency']`](https://docs.gitlab.com/ee/administration/sidekiq/extra_sidekiq_processes.html#manage-thread-counts-explicitly) settings are deprecated in GitLab 16.9 and will be removed in GitLab 17.0.

  You can use `sidekiq['concurrency']` in GitLab 16.9 and later to set thread counts explicitly in each process.

  The above change only applies to Linux package (Omnibus) installations.

- For GitLab Helm chart installations, passing `SIDEKIQ_CONCURRENCY_MIN` and/or `SIDEKIQ_CONCURRENCY_MAX` as `extraEnv` to the `sidekiq` sub-chart is deprecated in GitLab 16.10 and will be removed in GitLab 17.0.

  You can use the `concurrency` option to set thread counts explicitly in each process.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Offset pagination for `/users` REST API endpoint is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.5</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/426547).

</div>

Offset pagination for the `/users` REST API is deprecated in GitLab 16.5, and will be removed in GitLab 17.0. Use [keyset pagination](https://docs.gitlab.com/ee/api/rest/#keyset-based-pagination) instead.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Old versions of JSON web tokens are deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/366798).

</div>

[ID tokens](https://docs.gitlab.com/ee/ci/secrets/id_token_authentication.html) with OIDC support
were introduced in GitLab 15.7. These tokens are more configurable than the old JSON web tokens (JWTs), are OIDC compliant,
and only available in CI/CD jobs that explicitly have ID tokens configured.
ID tokens are more secure than the old `CI_JOB_JWT*` JSON web tokens which are exposed in every job,
and as a result these old JSON web tokens are deprecated:

- `CI_JOB_JWT`
- `CI_JOB_JWT_V1`
- `CI_JOB_JWT_V2`

To prepare for this change, configure your pipelines to use [ID tokens](https://docs.gitlab.com/ee/ci/yaml/#id_tokens)
instead of the deprecated tokens. For OIDC compliance, the `iss` claim now uses
the fully qualified domain name, for example `https://example.com`, previously
introduced with the `CI_JOB_JWT_V2` token.

In GitLab 15.9 to 15.11, you can [enable the **Limit JSON Web Token (JWT) access**](https://docs.gitlab.com/ee/ci/secrets/id_token_authentication.html#enable-automatic-id-token-authentication)
setting, which prevents the old tokens from being exposed to any jobs and enables
[ID token authentication for the `secrets:vault` keyword](https://docs.gitlab.com/ee/ci/secrets/id_token_authentication.html#configure-automatic-id-token-authentication).

In GitLab 16.0 and later:

- This setting will be removed.
- CI/CD jobs that use the `id_tokens` keyword can use ID tokens with `secrets:vault`,
  and will not have any `CI_JOB_JWT*` tokens available.
- Jobs that do not use the `id_tokens` keyword will continue to have the `CI_JOB_JWT*`
  tokens available until GitLab 17.0.

In GitLab 17.0, the deprecated tokens will be completely removed and will no longer
be available in CI/CD jobs.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### OmniAuth Facebook is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.2</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/416000).

</div>

OmniAuth Facebook support will be removed in GitLab 17.0. The last gem release was in 2021 and it is currently unmaintained. The current usage is less than 0.1%. If you use OmniAuth Facebook, switch to a [supported provider](https://docs.gitlab.com/ee/integration/omniauth.html#supported-providers) in advance of support removal.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Package pipelines in API payload is paginated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.5</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/289956).

</div>

A request to the API for `/api/v4/projects/:id/packages` returns a paginated result of packages. Each package lists all of its pipelines in this response. This is a performance concern, as it's possible for a package to have hundreds or thousands of associated pipelines.

In milestone 17.0, we will remove the `pipelines` attribute from the API response.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### PostgreSQL 13 no longer supported

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.0</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/groups/gitlab-org/-/epics/9065).

</div>

GitLab follows an [annual upgrade cadence for PostgreSQL](https://handbook.gitlab.com/handbook/engineering/infrastructure/core-platform/data_stores/database/postgresql-upgrade-cadence/).

Support for PostgreSQL 13 is scheduled for removal in GitLab 17.0.
In GitLab 17.0, PostgreSQL 14 becomes the minimum required PostgreSQL version.

PostgreSQL 13 will be supported for the full GitLab 16 release cycle.
PostgreSQL 14 will also be supported for instances that want to upgrade prior to GitLab 17.0.
If you are running a single PostgreSQL instance you installed by using an Omnibus Linux package, an automatic upgrade may be attempted with 16.11.
Make sure you have enough disk space to accommodate the upgrade. For more information, see the [Omnibus database documentation](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server).

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Proxy-based DAST deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.6</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/430966).

</div>

As of GitLab 17.0, Proxy-based DAST will not be supported. Please migrate to Browser-based DAST to continue analyzing your projects for security findings via dynamic analysis. **Breach and Attack Simulation**, an incubating feature which is built on top of Proxy-based DAST, is also included in this deprecation and will not be supported after 17.0.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Queue selector for running Sidekiq is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- End of Support in GitLab <span class="milestone">16.0</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390787).

</div>

Running Sidekiq with a [queue selector](https://docs.gitlab.com/ee/administration/sidekiq/processing_specific_job_classes.html#queue-selectors) (having multiple processes listening to a set of queues) and [negate settings](https://docs.gitlab.com/ee/administration/sidekiq/processing_specific_job_classes.html#negate-settings) is deprecated and will be fully removed in 17.0.

You can migrate away from queue selectors to [listening to all queues in all processes](https://docs.gitlab.com/ee/administration/sidekiq/extra_sidekiq_processes.html#start-multiple-processes). For example, if Sidekiq is currently running with 4 processes (denoted by 4 elements in `sidekiq['queue_groups']` in `/etc/gitlab/gitlab.rb`) with queue selector (`sidekiq['queue_selector'] = true`), you can change Sidekiq to listen to all queues in all 4 processes,for example `sidekiq['queue_groups'] = ['*'] * 4`. This approach is also recommended in our [Reference Architecture](https://docs.gitlab.com/ee/administration/reference_architectures/5k_users.html#configure-sidekiq). Note that Sidekiq can effectively run as many processes as the number of CPUs in the machine.

While the above approach is recommended for most instances, Sidekiq can also be run using [routing rules](https://docs.gitlab.com/ee/administration/sidekiq/processing_specific_job_classes.html#routing-rules) which is also being used on GitLab.com. You can follow the [migration guide from queue selectors to routing rules](https://docs.gitlab.com/ee/administration/sidekiq/processing_specific_job_classes.html#migrating-from-queue-selectors-to-routing-rules). You need to take care with the migration to avoid losing jobs entirely.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Removal of tags from small GitLab.com runners on Linux

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30829).

</div>

Due to historical reasons, small Linux GitLab.com Runners had a lot of tags attached because they were used as labels. We want to streamline the tag to just use `saas-linux-small-amd64` and be consistent across all GitLab.com runners.

We are deprecating the tags: `docker`, `east-c`, `gce`, `git-annex`, `linux`, `mongo`, `mysql`, `postgres`, `ruby`, `shared`.

For more information, see [Removing tags from our small SaaS runner on Linux](https://about.gitlab.com/blog/2023/08/15/removing-tags-from-small-saas-runner-on-linux/).

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Required Pipeline Configuration is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/389467).

</div>

Required pipeline configuration will be removed in GitLab 17.0. This impacts users on GitLab Self-Managed on the Ultimate tier.

You should replace required pipeline configuration with either:

- [Security policies scoped to compliance frameworks](https://docs.gitlab.com/ee/user/application_security/policies/scan_execution_policies.html#security-policy-scopes), which are experimental.
- [Compliance pipelines](https://docs.gitlab.com/ee/user/group/compliance_pipelines.html), which are available now.

We recommend these alternative solutions because they provides greater flexibility, allowing required pipelines to be assigned to specific
compliance framework labels.

Compliance pipelines will be deprecated in the future and migrated to security policies. For more information, see the
[migration and deprecation epic](https://gitlab.com/groups/gitlab-org/-/epics/11275).

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### SAST analyzer coverage changing in GitLab 17.0

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/412060).

</div>

We're reducing the number of supported [analyzers](https://docs.gitlab.com/ee/user/application_security/sast/analyzers/) used by default in GitLab SAST.
This is part of our long-term strategy to deliver a faster, more consistent user experience across different programming languages.

In GitLab 17.0, we will:

1. Remove a set of language-specific analyzers from the [SAST CI/CD template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml) and replace their coverage with [GitLab-supported detection rules](https://docs.gitlab.com/ee/user/application_security/sast/rules.html) in the [Semgrep-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep). The following analyzers are now deprecated and will reach End of Support in GitLab 17.0:
   1. [Brakeman](https://gitlab.com/gitlab-org/security-products/analyzers/brakeman) (Ruby, Ruby on Rails)
   1. [Flawfinder](https://gitlab.com/gitlab-org/security-products/analyzers/flawfinder) (C, C++)
   1. [MobSF](https://gitlab.com/gitlab-org/security-products/analyzers/mobsf) (Android, iOS)
   1. [NodeJS Scan](https://gitlab.com/gitlab-org/security-products/analyzers/nodejs-scan) (Node.js)
   1. [PHPCS Security Audit](https://gitlab.com/gitlab-org/security-products/analyzers/phpcs-security-audit) (PHP)
1. Change the [SAST CI/CD template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml) to stop running the [SpotBugs-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs) for Kotlin and Scala code. These languages will instead be scanned using [GitLab-supported detection rules](https://docs.gitlab.com/ee/user/application_security/sast/rules.html) in the [Semgrep-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep).

Effective immediately, the deprecated analyzers will receive only security updates; other routine improvements or updates are not guaranteed.
After the analyzers reach End of Support in GitLab 17.0, no further updates will be provided.
However, we won't delete container images previously published for these analyzers or remove the ability to run them by using custom CI/CD pipeline job definitions.

The vulnerability management system will update most existing findings so that they're matched with the new detection rules.
Findings that aren't migrated to the new analyzer will be [automatically resolved](https://docs.gitlab.com/ee/user/application_security/sast/#automatic-vulnerability-resolution).
See [Vulnerability translation documentation](https://docs.gitlab.com/ee/user/application_security/sast/analyzers.html#vulnerability-translation) for further details.

If you applied customizations to the removed analyzers, or if you currently disable the Semgrep-based analyzer in your pipelines, you must take action as detailed in the [deprecation issue for this change](https://gitlab.com/gitlab-org/gitlab/-/issues/412060#action-required).

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Scan execution policies using `_EXCLUDED_ANALYZERS` variable override project variables

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/424513).

</div>

After delivering and verifying [Enforce SEP variables with the highest precedence](https://gitlab.com/gitlab-org/gitlab/-/issues/424028), we have discovered unintended behavior, allowing users to set `_EXCLUDED_PATHS` in pipeline configuration and preventing them from setting `_EXCLUDED_ANALYZERS` in both policy and pipeline configuration.

To ensure proper enforcement of scan execution variables, when an `_EXCLUDED_ANALYZERS` or `_EXCLUDED_PATHS` variables are specified for a scan execution policy using the GitLab scan action, the variable will now override any project variables defined for excluded analyzers.

Users may enable the feature flag to enforce this behavior before 17.0. In 17.0, projects leveraging the `_EXCLUDED_ANALYZERS`/`_EXCLUDED_PATHS` variable where a scan execution policy with the variable is defined will be overridden by default.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Secure analyzers major version update

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/438123).

</div>

The Secure stage will be bumping the major versions of its analyzers in tandem with the GitLab
17.0 release.

If you are not using the default included templates, or have pinned your analyzer versions you
must update your CI/CD job definition to either remove the pinned version or to update
the latest major version.

Users of GitLab 16.0-16.11 will continue to experience analyzer updates as normal until the
release of GitLab 17.0, following which all newly fixed bugs and released features will be
released only in the new major version of the analyzers.

We do not backport bugs and features to deprecated versions as per our maintenance policy. As
required, security patches will be backported within the latest 3 minor releases.

Specifically, the following analyzers are being deprecated and will no longer be updated after
the GitLab 17.0 release:

- Container Scanning: version 6
- Dependency Scanning: version 4
- DAST: version 4
- DAST API: version 3
- Fuzz API: version 3
- IaC Scanning: version 4
- Secret Detection: version 5
- Static Application Security Testing (SAST): version 4 of [all analyzers](https://docs.gitlab.com/ee/user/application_security/sast/analyzers/)
  - `brakeman`
  - `flawfinder`
  - `kubesec`
  - `mobsf`
  - `nodejs-scan`
  - `phpcs-security-audit`
  - `pmd-apex`
  - `semgrep`
  - `sobelow`
  - `spotbugs`

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Security policy field `match_on_inclusion` is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/424513).

</div>

In [Support additional filters for scan result policies](https://gitlab.com/groups/gitlab-org/-/epics/6826#note_1341377224), we broke the `newly_detected` field into two options: `new_needs_triage` and `new_dismissed`. By including both options in the security policy YAML, you will achieve the same result as the original `newly_detected` field. However, you may now narrow your filter to ignore findings that have been dismissed by only using `new_needs_triage`.
Based on discussion in [epic 10203](https://gitlab.com/groups/gitlab-org/-/epics/10203#note_1545826313), we have changed the name of the `match_on_inclusion` field to `match_on_inclusion_license` for more clarity in the YAML definition.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Security policy field `newly_detected` is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.5</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/422414).

</div>

In [Support additional filters for scan result policies](https://gitlab.com/groups/gitlab-org/-/epics/6826#note_1341377224), we broke the `newly_detected` field into two options: `new_needs_triage` and `new_dismissed`. By including both options in the security policy YAML, you will achieve the same result as the original `newly_detected` field. However, you may now narrow your filter to ignore findings that have been dismissed by only using `new_needs_triage`.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Support for self-hosted Sentry versions 21.4.1 and earlier

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/435791).

</div>

Support for self-hosted Sentry versions 21.4.1 and earlier is deprecated and will be removed in GitLab 17.0.

If your self-hosted Sentry version is 21.4.1 or earlier, you may not be able to collect errors from your GitLab instance after upgrading to GitLab 17.0 or later.
To continue sending errors from your GitLab instance to your Sentry instance, upgrade Sentry to version 21.5.0 or later. For more information,
see [Sentry documentation](https://develop.sentry.dev/self-hosted/releases/).

NOTE:
The deprecated support is for
[GitLab instance error tracking features](https://docs.gitlab.com/omnibus/settings/configuration.html#error-reporting-and-logging-with-sentry)
for administrators. The deprecated support does not relate to
[GitLab error tracking](https://docs.gitlab.com/ee/operations/error_tracking.html#sentry-error-tracking) for
developers' own deployed applications.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Support for setting custom schema for backup is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.8</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/435210).

</div>

You could configure GitLab to use a custom schema for backup, by setting
`gitlab_rails['backup_pg_schema'] = '<schema_name>'` in `/etc/gitlab/gitlab.rb` for Linux package installations,
or by editing `config/gitlab.yml` for self-compiled installations.

While the configuration setting was available, it had no effect and did not serve the purpose it was intended.
This configuration setting will be removed in GitLab 17.0.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### The GitHub importer Rake task

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.6</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/428225).

</div>

In GitLab 16.6, the GitHub importer Rake task was deprecated. The Rake task lacks several features that are supported by the API and is not actively maintained.

In GitLab 17.0, the Rake task will be removed.

Instead, GitHub repositories can be imported by using the [API](https://docs.gitlab.com/ee/api/import.html#import-repository-from-github) or the [UI](https://docs.gitlab.com/ee/user/project/import/github.html).

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### The Visual Reviews tool is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/387751).

</div>

Due to limited customer usage and capabilities, the Visual Reviews feature for Review Apps is deprecated and will be removed. There is no planned replacement and users should stop using Visual Reviews before GitLab 17.0.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### The `gitlab-runner exec` command is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.7</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/385235).

</div>

The `gitlab-runner exec` command is deprecated and will be fully removed from GitLab Runner in 16.0. The `gitlab-runner exec` feature was initially developed to provide the ability to validate a GitLab CI pipeline on a local system without needing to commit the updates to a GitLab instance. However, with the continued evolution of GitLab CI, replicating all GitLab CI features into `gitlab-runner exec` was no longer viable. Pipeline syntax and validation [simulation](https://docs.gitlab.com/ee/ci/pipeline_editor/#simulate-a-cicd-pipeline) are available in the GitLab pipeline editor.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### The pull-based deployment features of the GitLab agent for Kubernetes is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.2</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/406545).

</div>

We are deprecating the built-in pull-based deployment features of the GitLab agent for Kubernetes in favor of Flux and related integrations.

The GitLab agent for Kubernetes **is not deprecated**. This change affects only the pull-based functionality of the agent. All other functionality will remain intact, and GitLab will continue to support the agent for Kubernetes.

If you use the agent for pull-based deployments, you should [migrate to Flux](https://docs.gitlab.com/ee/user/clusters/agent/gitops/agent.html#migrate-to-flux). Because Flux is a mature CNCF project for GitOps, we decided to [integrate Flux with GitLab in February 2023](https://about.gitlab.com/blog/2023/02/08/why-did-we-choose-to-integrate-fluxcd-with-gitlab/).

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Twitter OmniAuth login option is deprecated from GitLab Self-Managed

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.3</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-com/Product/-/issues/11417).

</div>

Twitter OAuth 1.0a OmniAuth is deprecated and will be removed for GitLab Self-Managed in GitLab 17.0 due to low use and lack of gem support. Use [another supported OmniAuth provider](https://docs.gitlab.com/ee/integration/omniauth.html#supported-providers) instead.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Unified approval rules are deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.1</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/groups/gitlab-org/-/epics/9662).

</div>

Unified approval rules are deprecated in favor of multiple approval rules, which provide more flexibility.
You might not be able to migrate your Unified approval rules to multiple approval rules without breaking changes.
To help you migrate manually, we introduced migration documentation.

If you don't migrate manually before unified approval
rules are removed, GitLab will automatically migrate your settings.
As multiple approval rules allow a more fine-grained setup for approval rules, if you leave the migration to GitLab,
the automatic migrations might end up with more restrictive rules than you might prefer.
Check your migration rules if you have an issue where you need more approvals than you expect.

In GitLab 15.11, UI support for unified approval rules was removed.
You can still access unified approval rules with the API.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Upgrading the operating system version of GitLab.com runners on Linux

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/ci-cd/shared-runners/infrastructure/-/issues/60).

</div>

GitLab is upgrading the container-optimized operating system (COS) of the ephemeral VMs used to execute jobs for GitLab.com runners on Linux.
That COS upgrade includes a Docker Engine upgrade from Version 19.03.15 to Version 23.0.5, which introduces a known compatibility issue.

Docker-in-Docker prior to version 20.10 or Kaniko images older than v1.9.0, will be unable to detect the container runtime and fail.

For more information, see [Upgrading the operating system version of our SaaS runners on Linux](https://about.gitlab.com/blog/2023/10/04/updating-the-os-version-of-saas-runners-on-linux/).

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Vulnerability confidence field

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.4</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/372332).

</div>

In GitLab 15.3, [security report schemas below version 15 were deprecated](https://docs.gitlab.com/ee/update/deprecations.html#security-report-schemas-version-14xx).
The `confidence` attribute on vulnerability findings exists only in schema versions before `15-0-0`, and therefore is effectively deprecated because GitLab 15.4 supports schema version `15-0-0`. To maintain consistency
between the reports and our public APIs, the `confidence` attribute on any vulnerability-related components of our GraphQL API is now deprecated and will be
removed in 17.0.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### `after_script` keyword will run for canceled jobs

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.8</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/437789).

</div>

The [`after_script`](https://docs.gitlab.com/ee/ci/yaml/#after_script) CI/CD keyword is used to run additional commands after the main `script` section of a job. This is often used for cleaning up environments or other resources that were used by the job. For many users, the fact that the `after_script` commands do not run if a job is canceled was unexpected and undesired. In 17.0, the keyword will be updated to also run commands after job cancellation. Make sure that your CI/CD configuration that uses the `after_script` keyword is able to handle running for canceled jobs as well.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### `dependency_files` is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/396376).

</div>

Today in GitLab, a project's dependency list is generated using content from `dependency_files` in the Dependency Scanning report. However, to maintain consistency with the group dependency list, starting with GitLab 17.0, the project's dependency list will use CycloneDX SBOM report artifacts, stored in the PostgreSQL database. As such, the `dependency_files` property of the Dependency Scanning report schema is deprecated, and will be removed in 17.0.

As a part of this deprecation, the [`dependency_path`](https://docs.gitlab.com/ee/user/application_security/dependency_list/#dependency-paths) will also be deprecated and removed in 17.0. GitLab will move forward with the implementation of the [dependency graph using the CycloneDX specification](https://gitlab.com/gitlab-org/gitlab/-/issues/441118) to provide similar information.

Additionally, the Container Scanning CI job [will no longer produce a Dependency Scanning report](https://gitlab.com/gitlab-org/gitlab/-/issues/439782) to provide the list of Operating System components as this is replaced with the CycloneDX SBOM report. The `CS_DISABLE_DEPENDENCY_LIST` environment variable for Container Scanning is no longer in use and will also be removed in 17.0.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### `metric` filter and `value` field for DORA API

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.8</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/393172).

</div>

Multiple DORA metrics can now be queried simultaneously using a new metrics field. The `metric` filter and `value` field for GraphQL DORA API will be removed in GitLab 17.0.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### `omniauth-azure-oauth2` gem is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/408989).

</div>

GitLab users can use the `omniauth-azure-oauth2` gem to authenticate with GitLab. In 17.0, this gem will be replaced with the `omniauth_openid_connect` gem. The new gem contains all of the same features as the old gem, but also has upstream maintenance and is better for security and centralized maintenance.

This change requires that users re-connect to the OAuth 2.0 provider at time of migration. To avoid disruption, [add `omniauth_openid_connect` as a new provider](https://docs.gitlab.com/ee/administration/auth/oidc.html#configure-multiple-openid-connect-providers) any time before 17.0. Users will see a new login button and have to manually reconnect their credentials. If you do not implement the `omniauth_openid_connect` gem before 17.0, users will no longer be able to sign in using the Azure login button, and will have to sign in using their username and password, until the correct gem is implemented by the administrator.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### `omnibus_gitconfig` configuration item is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.10</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitaly/-/issues/5132).

</div>

The `omnibus_gitconfig['system']` configuration item has been deprecated. If you use
`omnibus_gitconfig['system']` to set custom Git configuration for Gitaly, you must configure Git
directly through Gitaly configuration under `gitaly[:configuration][:git][:config]` before upgrading to GitLab 17.0.

For example:

```ruby
  gitaly[:configuration][:git][:config] = [
    {
      key: 'fetch.fsckObjects',
      value: 'true',
    },
    # ...
  ]
```

The format of the configuration keys must match what is passed to `git` through the CLI flag `git -c <configuration>`.

If you have trouble converting the existing keys to the expected format, see the existing keys in the correct format in
the Linux package-generated configuration file of Gitaly. By default, the configuration file is located at
`/var/opt/gitlab/gitaly/config.toml`.

The following configuration options that are managed by Gitaly should be removed. These keys do not need to be migrated
to Gitaly:

- `pack.threads=1`
- `receive.advertisePushOptions=true`
- `receive.fsckObjects=true`
- `repack.writeBitmaps=true`
- `transfer.hideRefs=^refs/tmp/`
- `transfer.hideRefs=^refs/keep-around/`
- `transfer.hideRefs=^refs/remotes/`
- `core.alternateRefsCommand="exit 0 #"`
- `core.fsyncObjectFiles=true`
- `fetch.writeCommitGraph=true`

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### `postgres_exporter['per_table_stats']` configuration setting

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.4</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8164).

</div>

The Linux package provides custom queries for the bundled PostgreSQL exporter, which included a `per_table_stats` query controlled by `postgres_exporter['per_table_stats']`
configuration setting.

The PostgreSQL exporter now provides a `stat_user_tables` collector that provides the same metrics. If you had `postgres_exporter['per_table_stats']` enabled,
enable `postgres_exporter['flags']['collector.stat_user_tables']` instead.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### `projectFingerprint` GraphQL field

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.1</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/343475).

</div>

The [`project_fingerprint`](https://gitlab.com/groups/gitlab-org/-/epics/2791) attribute of vulnerability findings is being deprecated in favor of a `uuid` attribute. By using UUIDv5 values to identify findings, we can easily associate any related entity with a finding. The `project_fingerprint` attribute is no longer being used to track findings, and will be removed in GitLab 17.0. Starting in 16.1, the output of `project_fingerprint` returns the same value as the `uuid` field.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### `repository_download_operation` audit event type for public projects

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/383218).

</div>

The audit event type `repository_download_operation` is currently saved to the database for all project downloads, both public projects and private projects. For
public projects, this audit event is not the most useful for auditing purposes because it can be triggered by non-authenticated users.

From GitLab 17.0, the `repository_download_operation` audit event type will only be triggered for private or internal projects. We will add a new audit event type
called `public_repository_download_operation` for public project downloads. This new audit event type will be streaming only.

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### npm package uploads now occur asynchronously

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.9</span>
- Removal in GitLab <span class="milestone">17.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/433009).

</div>

The GitLab package registry supports npm and Yarn. When you upload an npm or Yarn package, the upload is synchronous. However, there are known issues with synchronous uploads. For example, GitLab doesn't support features like [overrides](https://gitlab.com/gitlab-org/gitlab/-/issues/432876).

From 17.0, npm and Yarn packages will be uploaded asynchronously. This is a breaking change because you might have pipelines that expect the package to be available as soon as it's published.

As a workaround, you should use the [packages API](https://docs.gitlab.com/ee/api/packages.html) to check for packages.

</div>
</div>

<div class="milestone-wrapper" data-milestone="16.9">

## GitLab 16.9

<div class="deprecation " data-milestone="16.9">

### Deprecation of `lfs_check` feature flag

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.6</span>
- Removal in GitLab <span class="milestone">16.9</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/233550).

</div>

In GitLab 16.9, we will remove the `lfs_check` feature flag. This feature flag was [introduced 4 years ago](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/60588) and controls whether the LFS integrity check is enabled. The feature flag is enabled by default, but some customers experienced performance issues with the LFS integrity check and explicitly disabled it.

After [dramatically improving the performance](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/61355) of the LFS integrity check, we are ready to remove the feature flag. After the flag is removed, the feature will automatically be turned on for any environment in which it is currently disabled.

If this feature flag is disabled for your environment, and you are concerned about performance issues, please enable it and monitor the performance before it is removed in 16.9. If you see any performance issues after enabling it, please let us know in [this feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/233550).

</div>
</div>

<div class="milestone-wrapper" data-milestone="16.8">

## GitLab 16.8

<div class="deprecation " data-milestone="16.8">

### openSUSE Leap 15.4 packages

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.5</span>
- Removal in GitLab <span class="milestone">16.8</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8212).

</div>

Support and security updates for openSUSE Leap 15.4 is [ending November 2023](https://en.opensuse.org/Lifetime#openSUSE_Leap).

GitLab 15.4 provided packages for openSUSE Leap 15.5. GitLab 15.8 and later will not provide packages for openSUSE Leap 15.4.

To prepare for GitLab 15.8 and later, you should:

1. Move instances from openSUSE Leap 15.4 to openSUSE Leap 15.5.
1. Switch from the openSUSE Leap 15.4 GitLab-provided packages to the openSUSE Leap 15.5 GitLab-provided packages.

</div>
</div>

<div class="milestone-wrapper" data-milestone="16.7">

## GitLab 16.7

<div class="deprecation breaking-change" data-milestone="16.7">

### Shimo integration

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.7</span>
- Removal in GitLab <span class="milestone">16.7</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/377824).

</div>

The **Shimo Workspace integration** has been deprecated
and will be moved to the JiHu GitLab codebase.

</div>

<div class="deprecation breaking-change" data-milestone="16.7">

### `user_email_lookup_limit` API field

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.9</span>
- Removal in GitLab <span class="milestone">16.7</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))

</div>

The `user_email_lookup_limit` [API field](https://docs.gitlab.com/ee/api/settings.html) is deprecated in GitLab 14.9 and removed in GitLab 16.7. Until the feature is removed, `user_email_lookup_limit` is aliased to `search_rate_limit` and existing workflows still work.

Any API calls to change the rate limits for `user_email_lookup_limit` must use `search_rate_limit` instead.

</div>
</div>

<div class="milestone-wrapper" data-milestone="16.6">

## GitLab 16.6

<div class="deprecation breaking-change" data-milestone="16.6">

### Job token allowlist covers public and internal projects

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.3</span>
- Removal in GitLab <span class="milestone">16.6</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/420678).

</div>

Starting in 16.6, projects that are **public** or **internal** will no longer authorize job token requests from projects that are **not** on the project's allowlist when [**Limit access to this project**](https://docs.gitlab.com/ee/ci/jobs/ci_job_token.html#add-a-group-or-project-to-the-job-token-allowlist) is enabled.

If you have [public or internal](https://docs.gitlab.com/ee/user/public_access.html#change-project-visibility) projects with the **Limit access to this project** setting enabled, you must add any projects which make job token requests to your project's allowlist for continued authorization.

</div>
</div>

<div class="milestone-wrapper" data-milestone="16.5">

## GitLab 16.5

<div class="deprecation " data-milestone="16.5">

### Adding non-LDAP synced members to a locked LDAP group is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.0</span>
- Removal in GitLab <span class="milestone">16.5</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/213311).

</div>

Enabling the `ldap_settings_unlock_groups_by_owners` feature flag allowed non-LDAP synced users to be added to a locked LDAP group. This [feature](https://gitlab.com/gitlab-org/gitlab/-/issues/1793) has always been disabled by default and behind a feature flag. We are removing this feature to keep continuity with our SAML integration, and because allowing non-synced group members defeats the "single source of truth" principle of using a directory service. Once this feature is removed, any LDAP group members that are not synced with LDAP will lose access to that group.

</div>

<div class="deprecation breaking-change" data-milestone="16.5">

### Geo: Housekeeping Rake tasks

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.3</span>
- Removal in GitLab <span class="milestone">16.5</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/416384).

</div>

As part of the migration of the replication and verification to the
[Geo self-service framework (SSF)](https://docs.gitlab.com/ee/development/geo/framework.html),
the legacy replication for project repositories has been
[removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130565).
As a result, the following Rake tasks that relied on legacy code have also been removed. The work invoked by these Rake tasks are now triggered automatically either periodically or based on trigger events.

| Rake task | Replacement |
| --------- | ----------- |
| `geo:git:housekeeping:full_repack` | [Moved to UI](https://docs.gitlab.com/ee/administration/housekeeping.html#heuristical-housekeeping). No equivalent Rake task in the SSF. |
| `geo:git:housekeeping:gc` | Always executed for new repositories, and then when it's needed. No equivalent Rake task in the SSF. |
| `geo:git:housekeeping:incremental_repack` | Executed when needed. No equivalent Rake task in the SSF. |
| `geo:run_orphaned_project_registry_cleaner` | Executed regularly by a registry [consistency worker](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/geo/secondary/registry_consistency_worker.rb) which removes orphaned registries. No equivalent Rake task in the SSF. |
| `geo:verification:repository:reset` | Moved to UI. No equivalent Rake task in the SSF. |
| `geo:verification:wiki:reset` | Moved to UI. No equivalent Rake task in the SSF. |

</div>
</div>

<div class="milestone-wrapper" data-milestone="16.3">

## GitLab 16.3

<div class="deprecation breaking-change" data-milestone="16.3">

### Bundled Grafana deprecated and disabled

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.0</span>
- Removal in GitLab <span class="milestone">16.3</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7772).

</div>

The version of Grafana bundled with Omnibus GitLab is
[deprecated and disabled](https://docs.gitlab.com/ee/administration/monitoring/performance/grafana_configuration.html#deprecation-of-bundled-grafana)
in 16.0 and will be removed in 16.3. If you are using the bundled Grafana, you must migrate to either:

- Another implementation of Grafana. For more information, see
  [Switch to new Grafana instance](https://docs.gitlab.com/ee/administration/monitoring/performance/grafana_configuration.html#switch-to-new-grafana-instance).
- Another observability platform of your choice.

The version of Grafana that is currently provided is no longer a supported version.

In GitLab versions 16.0 to 16.2, you can still [re-enable the bundled Grafana](https://docs.gitlab.com/ee/administration/monitoring/performance/grafana_configuration.html#temporary-workaround).
However, enabling the bundled Grafana will no longer work from GitLab 16.3.

</div>

<div class="deprecation breaking-change" data-milestone="16.3">

### License Compliance CI Template

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">16.3</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/387561).

</div>

**Update:** We previously announced we would remove the existing License Compliance CI template in GitLab 16.0. However, due to performance issues with the [license scanning of CycloneDX files](https://docs.gitlab.com/ee/user/compliance/license_scanning_of_cyclonedx_files/) we will do this in 16.3 instead.

The GitLab [**License Compliance**](https://docs.gitlab.com/ee/user/compliance/license_approval_policies.html) CI/CD template is now deprecated and is scheduled for removal in the GitLab 16.3 release.

To continue using GitLab for license compliance, remove the **License Compliance** template from your CI/CD pipeline and add the **Dependency Scanning** template. The **Dependency Scanning** template is now capable of gathering the required license information, so it is no longer necessary to run a separate license compliance job.

Before you remove the **License Compliance** CI/CD template, verify that the instance has been upgraded to a version that supports the new method of license scanning.

To begin using the Dependency Scanner quickly at scale, you may set up a scan execution policy at the group level to enforce the SBOM-based license scan for all projects in the group. Then, you may remove the inclusion of the `Jobs/License-Scanning.gitlab-ci.yml` template from your CI/CD configuration.

If you wish to continue using the legacy license compliance feature, you can do so by setting the `LICENSE_MANAGEMENT_VERSION CI` variable to `4`. This variable can be set at the project, group, or instance level. This configuration change will allow you to continue using an existing version of license compliance without having to adopt the new approach.

Bugs and vulnerabilities in this legacy analyzer will no longer be fixed.

| CI Pipeline Includes | GitLab <= 15.8 | 15.9 <= GitLab < 16.3 | GitLab >= 16.3 |
| ------------- | ------------- | ------------- | ------------- |
| Both DS and LS templates | License data from LS job is used | License data from LS job is used | License data from DS job is used |
| DS template is included but LS template is not | No license data | License data from DS job is used | License data from DS job is used |
| LS template is included but DS template is not | License data from LS job is used | License data from LS job is used | No license data |

</div>

<div class="deprecation breaking-change" data-milestone="16.3">

### RSA key size limits

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.3</span>
- Removal in GitLab <span class="milestone">16.3</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/groups/gitlab-org/-/epics/11186).

</div>

Go versions 1.20.7 and later add a `maxRSAKeySize` constant that limits RSA keys to a maximum of 8192 bits. As a result, RSA keys larger than 8192 bits will no longer work with GitLab. Any RSA keys larger than 8192 bits must be regenerated at a smaller size.

You might notice this issue because your logs include an error like `tls: server sent certificate containing RSA key larger than 8192 bits`. To test the length of your key, use this command: `openssl rsa -in <your-key-file> -text -noout | grep "Key:"`.

</div>

<div class="deprecation breaking-change" data-milestone="16.3">

### Twitter OmniAuth login option is removed from GitLab.com

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.3</span>
- Removal in GitLab <span class="milestone">16.3</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-com/Product/-/issues/11417).

</div>

Twitter OAuth 1.0a OmniAuth is being deprecated and removed on GitLab.com in GitLab 16.3 due to low use, lack of gem support, and the lack of a functional sign-in option for this feature. If you sign in to GitLab.com with Twitter, you can sign in with a password or another [supported OmniAuth provider](https://gitlab.com/users/sign_in).

</div>
</div>

<div class="milestone-wrapper" data-milestone="16.1">

## GitLab 16.1

<div class="deprecation " data-milestone="16.1">

### GitLab Runner images based on Alpine 3.12, 3.13, 3.14

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.11</span>
- End of Support in GitLab <span class="milestone">16.1</span>
- Removal in GitLab <span class="milestone">16.1</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29639).

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

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/343988).

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

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/container-registry/-/issues/854).

</div>

The container registry's Azure Storage Driver writes to `//` as the default root directory. This default root directory appears in some places within the Azure UI as `/<no-name>/`. We have maintained this legacy behavior to support older deployments using this storage driver. However, when moving to Azure from another storage driver, this behavior hides all your data until you configure the storage driver to build root paths without an extra leading slash by setting `trimlegacyrootprefix: true`.

The new default configuration for the storage driver will set `trimlegacyrootprefix: true`, and `/` will be the default root directory. You can add `trimlegacyrootprefix: false` to your current configuration to avoid any disruptions.

This breaking change will happen in GitLab 16.0.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Bundled Grafana Helm Chart is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.10</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/4353).

</div>

The Grafana Helm chart that is bundled with the GitLab Helm Chart is deprecated and will be removed in the GitLab Helm Chart 7.0 release (releasing along with GitLab 16.0).

The bundled Grafana Helm chart is an optional service that can be turned on to provide the Grafana UI connected to the GitLab Helm Chart's Prometheus metrics.

The version of Grafana that the GitLab Helm Chart is currently providing is no longer a supported Grafana version.
If you're using the bundled Grafana, you should switch to the [newer chart version from Grafana Labs](https://artifacthub.io/packages/helm/grafana/grafana)
or a Grafana Operator from a trusted provider.

In your new Grafana instance, you can [configure the GitLab provided Prometheus as a data source](https://docs.gitlab.com/ee/administration/monitoring/performance/grafana_configuration.html#configure-grafana)
and [connect Grafana to the GitLab UI](https://docs.gitlab.com/ee/administration/monitoring/performance/grafana_configuration.html#integrate-with-gitlab-ui).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### CAS OmniAuth provider

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.3</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/369127).

</div>

The `omniauth-cas3` gem that provides GitLab with the CAS OmniAuth provider will be removed in our next major
release, GitLab 16.0. This gem sees very little use and its lack of upstream maintenance is preventing GitLab from
[upgrading to OmniAuth 2.0](https://gitlab.com/gitlab-org/gitlab/-/issues/30073).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### CI/CD jobs will fail when no secret is returned from HashiCorp Vault

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/353080).

</div>

When using the native HashiCorp Vault integration, CI/CD jobs will fail when no secret is returned from Vault. Make sure your configuration always return a secret, or update your pipeline to handle this change, before GitLab 16.0.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Changing MobSF-based SAST analyzer behavior in multi-module Android projects

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.0</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/408396).

</div>

**Update:** We previously announced a change to how the MobSF-based GitLab SAST analyzer would scan multi-module Android projects.
We've canceled that change, and no action is required.

Instead of changing which single module would be scanned, we [improved multi-module support](https://gitlab.com/gitlab-org/security-products/analyzers/mobsf/-/merge_requests/73).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Changing merge request approvals with the `/approvals` API endpoint

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.0</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/353097).

</div>

To change the approvals required for a merge request, you should no longer use the `/approvals` API endpoint, which was deprecated in GitLab 14.0.

Instead, use the [`/approval_rules` endpoint](https://docs.gitlab.com/ee/api/merge_request_approvals.html#merge-request-level-mr-approvals) to [create](https://docs.gitlab.com/ee/api/merge_request_approvals.html#create-merge-request-level-rule) or [update](https://docs.gitlab.com/ee/api/merge_request_approvals.html#update-merge-request-level-rule) the approval rules for a merge request.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Conan project-level search endpoint returns project-specific results

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/384455).

</div>

You can use the GitLab Conan repository with [project-level](https://docs.gitlab.com/ee/user/packages/conan_repository/#add-a-remote-for-your-project) or [instance-level](https://docs.gitlab.com/ee/user/packages/conan_repository/#add-a-remote-for-your-instance) endpoints. Each level supports the Conan search command. However, the search endpoint for the project level is also returning packages from outside the target project.

This unintended functionality is deprecated in GitLab 15.8 and will be removed in GitLab 16.0. The search endpoint for the project level will only return packages from the target project.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Configuration fields in GitLab Runner Helm Chart

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.6</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/379064).

</div>

From GitLab 13.6, users can [specify any runner configuration in the GitLab Runner Helm chart](https://docs.gitlab.com/runner/install/kubernetes.html). When we implemented this feature, we deprecated values in the GitLab Helm Chart configuration that were specific to GitLab Runner. The deprecated values will be removed in GitLab 16.0.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Configuring Redis config file paths using environment variables is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/388255).

</div>

You can no longer specify Redis configuration file locations
using the environment variables like `GITLAB_REDIS_CACHE_CONFIG_FILE` or
`GITLAB_REDIS_QUEUES_CONFIG_FILE`. Use the default
config file locations instead, for example `config/redis.cache.yml` or
`config/redis.queues.yml`.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Container Scanning variables that reference Docker

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.4</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/371840).

</div>

All Container Scanning variables that are prefixed by `DOCKER_` in variable name are deprecated. This includes the `DOCKER_IMAGE`, `DOCKER_PASSWORD`, `DOCKER_USER`, and `DOCKERFILE_PATH` variables. Support for these variables will be removed in the GitLab 16.0 release. Use the [new variable names](https://docs.gitlab.com/ee/user/application_security/container_scanning/#available-cicd-variables) `CS_IMAGE`, `CS_REGISTRY_PASSWORD`, `CS_REGISTRY_USER`, and `CS_DOCKERFILE_PATH` in place of the deprecated names.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Container registry pull-through cache

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/container-registry/-/issues/842).

</div>

The container registry [pull-through cache](https://docs.docker.com/docker-hub/mirror/) is deprecated in GitLab 15.8 and will be removed in GitLab 16.0. The pull-through cache is part of the upstream [Docker Distribution project](https://github.com/distribution/distribution). However, we are removing the pull-through cache in favor of the GitLab Dependency Proxy, which allows you to proxy and cache container images from Docker Hub. Removing the pull-through cache allows us also to remove the upstream client code without sacrificing functionality.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Cookie authorization in the GitLab for Jira Cloud app

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/387299).

</div>

Cookie authentication in the GitLab for Jira Cloud app is now deprecated in favor of OAuth authentication.
On GitLab Self-Managed, you must [set up OAuth authentication](https://docs.gitlab.com/ee/integration/jira/connect-app.html#set-up-oauth-authentication-for-self-managed-instances)
to continue to use the GitLab for Jira Cloud app. Without OAuth, you can't manage linked namespaces.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### DAST API scans using DAST template is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.7</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/384198).

</div>

With the move to the new DAST API analyzer and the `DAST-API.gitlab-ci.yml` template for DAST API scans, we will be removing the ability to scan APIs with the DAST analyzer. Use of the `DAST.gitlab-ci.yml` or `DAST-latest.gitlab-ci.yml` templates for API scans is deprecated as of GitLab 15.7 and will no longer work in GitLab 16.0. Please use `DAST-API.gitlab-ci.yml` template and refer to the [DAST API analyzer](https://docs.gitlab.com/ee/user/application_security/dast_api/#configure-dast-api-with-an-openapi-specification) documentation for configuration details.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### DAST API variables

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.7</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/383467).

</div>

With the switch to the new DAST API analyzer in GitLab 15.6, two legacy DAST API variables are being deprecated. The variables `DAST_API_HOST_OVERRIDE` and `DAST_API_SPECIFICATION` will no longer be used for DAST API scans.

`DAST_API_HOST_OVERRIDE` has been deprecated in favor of using the `DAST_API_TARGET_URL` to automatically override the host in the OpenAPI specification.

`DAST_API_SPECIFICATION` has been deprecated in favor of `DAST_API_OPENAPI`. To continue using an OpenAPI specification to guide the test, users must replace the `DAST_API_SPECIFICATION` variable with the `DAST_API_OPENAPI` variable. The value can remain the same, but the variable name must be replaced.

These two variables will be removed in GitLab 16.0.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### DAST report variables deprecation

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.7</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/384340).

</div>

With the new browser-based DAST analyzer GA in GitLab 15.7, we are working towards making it the default DAST analyzer at some point in the future. In preparation for this, the following legacy DAST variables are being deprecated and scheduled for removal in GitLab 16.0: `DAST_HTML_REPORT`, `DAST_XML_REPORT`, and `DAST_MARKDOWN_REPORT`. These reports relied on the legacy DAST analyzer and we do not plan to implement them in the new browser-based analyzer. As of GitLab 16.0, these report artifacts will no longer be generated.

These three variables will be removed in GitLab 16.0.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Dependency Scanning support for Java 13, 14, 15, and 16

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/387560).

</div>

GitLab has deprecated Dependency Scanning support for Java versions 13, 14, 15, and 16 and plans to remove that support in the upcoming GitLab 16.0 release. This is consistent with [Oracle support policy](https://www.oracle.com/java/technologies/java-se-support-roadmap.html) as Oracle Premier and Extended Support for these versions has ended. This also allows GitLab to focus Dependency Scanning Java support on LTS versions moving forward.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Deployment API returns error when `updated_at` and `updated_at` are not used together

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/328500).

</div>

The Deployment API will now return an error when `updated_at` filtering and `updated_at` sorting are not used together. Some users were using filtering by `updated_at` to fetch "latest" deployment without using `updated_at` sorting, which may produce wrong results. You should instead use them together, or migrate to filtering by `finished_at` and sorting by `finished_at` which will give you "latest deployments" in a consistent way.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Deprecate legacy Gitaly configuration methods

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/352609).

</div>

Using environment variables `GIT_CONFIG_SYSTEM` and `GIT_CONFIG_GLOBAL` to configure Gitaly is [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/352609).
These variables are being replaced with standard [`config.toml` Gitaly configuration](https://docs.gitlab.com/ee/administration/gitaly/reference.html).

GitLab instances that use `GIT_CONFIG_SYSTEM` and `GIT_CONFIG_GLOBAL` to configure Gitaly should switch to configuring using
`config.toml`.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Deprecated Consul http metrics

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.10</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7278).

</div>

The Consul provided in the Linux package will no longer provide older deprecated Consul metrics starting in GitLab 16.0.

In GitLab 14.0, [Consul was updated to 1.9.6](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5344),
which deprecated some telemetry metrics from being at the `consul.http` path. In GitLab 16.0, the `consul.http` path will be removed.

If you have monitoring that consumes Consul metrics, update them to use `consul.api.http` instead of `consul.http`.
For more information, see [the deprecation notes for Consul 1.9.0](https://github.com/hashicorp/consul/releases/tag/v1.9.0).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Deprecation and planned removal for `CI_PRE_CLONE_SCRIPT` variable on GitLab.com

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/391896).

</div>

The [`CI_PRE_CLONE_SCRIPT` variable](https://docs.gitlab.com/ee/ci/runners/saas/linux_saas_runner.html#pre-clone-script) supported by GitLab.com Runners is deprecated as of GitLab 15.9 and will be removed in 16.0. The `CI_PRE_CLONE_SCRIPT` variable enables you to run commands in your CI/CD job prior to the runner executing Git init and get fetch. For more information about how this feature works, see [Pre-clone script](https://docs.gitlab.com/ee/ci/runners/saas/linux_saas_runner.html#pre-clone-script). As an alternative, you can use the [`pre_get_sources_script`](https://docs.gitlab.com/ee/ci/yaml/#hookspre_get_sources_script).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Developer role providing the ability to import projects to a group

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/387891).

</div>

The ability for users with the Developer role for a group to import projects to that group is deprecated in GitLab
15.8 and will be removed in GitLab 16.0. From GitLab 16.0, only users with at least the Maintainer role for a group
will be able to import projects to that group.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Development dependencies reported for PHP and Python

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/375505).

</div>

In GitLab 16.0 the GitLab Dependency Scanning analyzer will begin reporting development dependencies for both Python/pipenv and PHP/composer projects. Users who do not wish to have these development dependencies reported should set `DS_INCLUDE_DEV_DEPENDENCIES: false` in their CI/CD file.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Embedding Grafana panels in Markdown is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/389477).

</div>

The ability to add Grafana panels in GitLab Flavored Markdown is deprecated in 15.9 and will be removed in 16.0.
We intend to replace this feature with the ability to [embed charts](https://gitlab.com/groups/gitlab-org/opstrace/-/epics/33) with the [GitLab Observability UI](https://gitlab.com/gitlab-org/opstrace/opstrace-ui).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Enforced validation of CI/CD parameter character lengths

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/372770).

</div>

While CI/CD [job names](https://docs.gitlab.com/ee/ci/jobs/#job-name) have a strict 255 character limit, other CI/CD parameters do not yet have validations ensuring they also stay under the limit.

In GitLab 16.0, validation will be added to strictly limit the following to 255 characters as well:

- The `stage` keyword.
- The `ref`, which is the Git branch or tag name for the pipeline.
- The `description` and `target_url` parameter, used by external CI/CD integrations.

Users on GitLab Self-Managed should update their pipelines to ensure they do not use parameters that exceed 255 characters. Users on GitLab.com do not need to make any changes, as these are already limited in that database.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Environment search query requires at least three characters

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.10</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/382532).

</div>

From GitLab 16.0, when you search for environments with the API, you must use at least three characters. This change helps us ensure the scalability of the search operation.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### External field in GraphQL ReleaseAssetLink type

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))

</div>

In the [GraphQL API](https://docs.gitlab.com/ee/api/graphql/), the `external` field of [`ReleaseAssetLink` type](https://docs.gitlab.com/ee/api/graphql/reference/#releaseassetlink) was used to indicate whether a [release link](https://docs.gitlab.com/ee/user/project/releases/release_fields.html#links) is internal or external to your GitLab instance.
As of GitLab 15.9, we treat all release links as external, and therefore, this field is deprecated in GitLab 15.9, and will be removed in GitLab 16.0.
To avoid any disruptions to your workflow, please stop using the `external` field because it will be removed and will not be replaced.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### External field in Releases and Release Links APIs

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))

</div>

In [Releases API](https://docs.gitlab.com/ee/api/releases/) and [Release Links API](https://docs.gitlab.com/ee/api/releases/links.html), the `external` field was used to indicate whether a [release link](https://docs.gitlab.com/ee/user/project/releases/release_fields.html#links) is internal or external to your GitLab instance.
As of GitLab 15.9, we treat all release links as external, and therefore, this field is deprecated in GitLab 15.9, and will be removed in GitLab 16.0.
To avoid any disruptions to your workflow, please stop using the `external` field because it will be removed and will not be replaced.

</div>

<div class="deprecation " data-milestone="16.0">

### Geo: Project repository redownload is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.11</span>
- Removal in GitLab <span class="milestone">16.0</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/388868).

</div>

In secondary Geo sites, the button to "Redownload" a project repository is
deprecated. The redownload logic has inherent data consistency issues which
are difficult to resolve when encountered. The button will be removed in
GitLab 16.0.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### GitLab administrators must have permission to modify protected branches or tags

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.0</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/12776).

</div>

GitLab administrators can no longer perform actions on protected branches or tags unless they have been explicitly granted that permission. These actions include pushing and merging into a [protected branch](https://docs.gitlab.com/ee/user/project/repository/branches/protected.html), unprotecting a branch, and creating [protected tags](https://docs.gitlab.com/ee/user/project/protected_tags.html).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### GitLab self-monitoring project

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.9</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/348909).

</div>

GitLab self-monitoring gives instance administrators the tools to monitor the health of their instances. This feature is deprecated in GitLab 14.9, and is scheduled for removal in 16.0.

</div>

<div class="deprecation " data-milestone="16.0">

### GitLab.com importer

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">16.0</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-com/Product/-/issues/4895).

</div>

The GitLab.com importer was deprecated in GitLab 15.8 and will be removed in GitLab 16.0.

The GitLab.com importer was introduced in 2015 for importing a project from GitLab.com to a GitLab Self-Managed instance through the UI.
This feature is available on GitLab Self-Managed only. [Migrating GitLab groups and projects by direct transfer](https://docs.gitlab.com/ee/user/group/import/#migrate-groups-by-direct-transfer-recommended)
supersedes the GitLab.com importer and provides a more cohesive importing functionality.

See [migrated group items](https://docs.gitlab.com/ee/user/group/import/#migrated-group-items) and [migrated project items](https://docs.gitlab.com/ee/user/group/import/#migrated-project-items) for an overview.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### GraphQL API Runner status will not return `paused`

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.5</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/344648).

</div>

The GitLab Runner GraphQL API endpoints will not return `paused` or `active` as a status in GitLab 16.0.
In a future v5 of the REST API, the endpoints for GitLab Runner will also not return `paused` or `active`.

A runner's status will only relate to runner contact status, such as:
`online`, `offline`, or `not_connected`. Status `paused` or `active` will no longer appear.

When checking if a runner is `paused`, API users are advised to check the boolean attribute
`paused` to be `true` instead. When checking if a runner is `active`, check if `paused` is `false`.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Jira DVCS connector for Jira Cloud

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.1</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/groups/gitlab-org/-/epics/7508).

</div>

The [Jira DVCS connector](https://docs.gitlab.com/ee/integration/jira/dvcs/) for Jira Cloud has been deprecated and will be removed in GitLab 16.0. If you're using the Jira DVCS connector with Jira Cloud, migrate to the [GitLab for Jira Cloud app](https://docs.gitlab.com/ee/integration/jira/connect-app.html).

The Jira DVCS connector is also deprecated for Jira 8.13 and earlier. You can only use the Jira DVCS connector with Jira Server or Jira Data Center in Jira 8.14 and later.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### KAS Metrics Port in GitLab Helm Chart

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.7</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/383039).

</div>

The `gitlab.kas.metrics.port` has been deprecated in favor of the new `gitlab.kas.observability.port` configuration field for the [GitLab Helm Chart](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/2839).
This port is used for much more than just metrics, which warranted this change to avoid confusion in configuration.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Legacy Gitaly configuration method

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.10</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/393574).

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

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390291).

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

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/214217).

</div>

GitLab 16.0 removes legacy URLs from the GitLab application.

When subgroups were introduced in GitLab 9.0, a `/-/` delimiter was added to URLs to signify the end of a group path. All GitLab URLs now use this delimiter for project, group, and instance level features.

URLs that do not use the `/-/` delimiter are planned for removal in GitLab 16.0. For the full list of these URLs, along with their replacements, see [issue 28848](https://gitlab.com/gitlab-org/gitlab/-/issues/28848#release-notes).

Update any scripts or bookmarks that reference the legacy URLs. GitLab APIs are not affected by this change.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### License-Check and the Policies tab on the License Compliance page

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390417).

</div>

The **License-Check feature** is now deprecated and is scheduled for removal in GitLab 16.0. Additionally, the Policies tab on the License Compliance page and all APIs related to the License-Check feature are deprecated and planned for removal in GitLab 16.0. Users who wish to continue to enforce approvals based on detected licenses are encouraged to create a new [License Approval policy](https://docs.gitlab.com/ee/user/compliance/license_approval_policies.html) instead.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Limit personal access token and deploy token's access with external authorization

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/387721).

</div>

With external authorization enabled, personal access tokens (PATs) and deploy tokens must no longer be able to access container or package registries. This defense-in-depth security measure will be deployed in 16.0. For users that use PATs and deploy tokens to access these registries, this measure breaks this use of these tokens. Disable external authorization to use tokens with container or package registries.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Major bundled Helm Chart updates for the GitLab Helm Chart

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.10</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3442).

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

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390417).

</div>

The Managed Licenses API is now deprecated and is scheduled for removal in GitLab 16.0.

</div>

<div class="deprecation " data-milestone="16.0">

### Maximum number of active pipelines per project limit (`ci_active_pipelines`)

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.3</span>
- Removal in GitLab <span class="milestone">16.0</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/368195).

</div>

The [**Maximum number of active pipelines per project** limit](https://docs.gitlab.com/ee/administration/settings/continuous_integration.html#set-cicd-limits) was never enabled by default and will be removed in GitLab 16.0. This limit can also be configured in the Rails console under [`ci_active_pipelines`](https://docs.gitlab.com/ee/administration/instance_limits.html#number-of-pipelines-running-concurrently). Instead, use the other recommended rate limits that offer similar protection:

- [**Pipelines rate limits**](https://docs.gitlab.com/ee/administration/settings/rate_limit_on_pipelines_creation.html).
- [**Total number of jobs in currently active pipelines**](https://docs.gitlab.com/ee/administration/settings/continuous_integration.html#set-cicd-limits).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Monitor performance metrics through Prometheus

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.7</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/346541).

</div>

By displaying data stored in a Prometheus instance, GitLab allows users to view performance metrics. GitLab also displays visualizations of these metrics in dashboards. The user can connect to a previously-configured external Prometheus instance, or set up Prometheus as a GitLab Managed App.
However, since certificate-based integration with Kubernetes clusters is deprecated in GitLab, the metrics functionality in GitLab that relies on Prometheus is also deprecated. This includes the metrics visualizations in dashboards. GitLab is working to develop a single user experience based on [Opstrace](https://about.gitlab.com/press/releases/2021-12-14-gitlab-acquires-opstrace-to-expand-its-devops-platform-with-open-source-observability-solution/). An [issue exists](https://gitlab.com/groups/gitlab-org/-/epics/6976) for you to follow work on the Opstrace integration.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Non-expiring access tokens

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.4</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/369122).

</div>

Whether your existing project access tokens have expiry dates automatically applied depends on what GitLab offering you have, and when you upgraded to GitLab 16.0 or later:

- On GitLab.com, during the 16.0 milestone, existing project access tokens without an expiry date were automatically given an expiry date of 365 days later than the current date.
- On GitLab Self-Managed, if you upgraded from GitLab 15.11 or earlier to GitLab 16.0 or later:
  - On or before July 23, 2024, existing project access tokens without an expiry date were automatically given an expiry date of 365 days later than the current date.
    This change is a breaking change.
  - On or after July 24, 2024, existing project access tokens without an expiry date did not have an expiry date set.

On GitLab Self-Managed, if you do a new install of one of the following GitLab versions, your existing project access tokens do not have expiry dates automatically applied:

- 16.0.9
- 16.1.7
- 16.2.10
- 16.3.8
- 16.4.6
- 16.5.9
- 16.6.9
- 16.7.9
- 16.8.9
- 16.9.10
- 16.10.9
- 16.11.7
- 17.0.5
- 17.1.3
- 17.2.1

Access tokens that have no expiration date are valid indefinitely, which presents a security risk if the access token
is divulged. Because access tokens that have an expiration date are better, from GitLab 15.3 we
[populate a default expiration date](https://gitlab.com/gitlab-org/gitlab/-/issues/348660).

In GitLab 16.0, any [personal](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html),
[project](https://docs.gitlab.com/ee/user/project/settings/project_access_tokens.html), or
[group](https://docs.gitlab.com/ee/user/group/settings/group_access_tokens.html) access token that does not have an
expiration date will automatically have an expiration date set at one year.

We recommend giving your access tokens an expiration date in line with your company's security policies before the
default is applied:

- On GitLab.com during the 16.0 milestone.
- On GitLab Self-Managed when they are upgraded to 16.0.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Non-standard default Redis ports are deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/388269).

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

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/389557).

</div>

The group and project deletion protection setting in the **Admin** area had an option to delete groups and projects immediately. Starting with 16.0, this option will no longer be available, and delayed group and project deletion will become the default behavior.

The option will no longer appear as a group setting. Users on GitLab Self-Managed will still have the option to define the deletion delay period, and GitLab.com users have a non-adjustable default retention period of 7 days. Users can still immediately delete the project from the project settings, and the group from the group settings.

The option to delete groups and projects immediately by default was deprecated to prevent users from accidentally taking this action and permanently losing groups and projects.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### PostgreSQL 12 deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.0</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/349185).

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

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/385798).

</div>

We are deprecating the `operations_access_level` field in the Projects API. This field has been replaced by fields to control specific features: `releases_access_level`, `environments_access_level`, `feature_flags_access_level`, `infrastructure_access_level`, and `monitor_access_level`.

</div>

<div class="deprecation " data-milestone="16.0">

### Rake task for importing bare repositories

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">16.0</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-com/Product/-/issues/5255).

</div>

The Rake task for importing bare repositories (`gitlab:import:repos`) is deprecated in GitLab 15.8 and will be removed in GitLab 16.0.

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
- Importing [repositories from a non-GitLab source](https://docs.gitlab.com/ee/user/project/import/).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Redis 5 deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.3</span>
- End of Support in GitLab <span class="milestone">15.6</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/331468).

</div>

With GitLab 13.9, in the Omnibus GitLab package and GitLab Helm chart 4.9, the Redis version [was updated to Redis 6](https://about.gitlab.com/releases/2021/02/22/gitlab-13-9-released/#omnibus-improvements).
Redis 5 has reached the end of life in April 2022 and will no longer be supported as of GitLab 15.6.
If you are using your own Redis 5.0 instance, you should upgrade it to Redis 6.0 or higher before upgrading to GitLab 16.0 or higher.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Remove `job_age` parameter from `POST /jobs/request` Runner endpoint

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.2</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/334253).

</div>

The `job_age` parameter, returned from the `POST /jobs/request` API endpoint used in communication with GitLab Runner, was never used by any GitLab or Runner feature. This parameter will be removed in GitLab 16.0.

This could be a breaking change for anyone that developed their own runner that relies on this parameter being returned by the endpoint. This is not a breaking change for anyone using an officially released version of GitLab Runner, including public shared runners on GitLab.com.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### SAST analyzer coverage changing in GitLab 16.0

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390416).

</div>

GitLab SAST uses various [analyzers](https://docs.gitlab.com/ee/user/application_security/sast/analyzers/) to scan code for vulnerabilities.

We're reducing the number of supported analyzers used by default in GitLab SAST.
This is part of our long-term strategy to deliver a faster, more consistent user experience across different programming languages.

Starting in GitLab 16.0, the GitLab SAST CI/CD template will no longer use the [Security Code Scan](https://gitlab.com/gitlab-org/security-products/analyzers/security-code-scan)-based analyzer for .NET, and it will enter End of Support status.
We'll remove this analyzer from the [SAST CI/CD template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml) and replace it with GitLab-supported detection rules for C# in the [Semgrep-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep).

Effective immediately, this analyzer will receive only security updates; other routine improvements or updates are not guaranteed.
After this analyzer reaches End of Support in GitLab 16.0, no further updates will be provided.
However, we won't delete container images previously published for this analyzer or remove the ability to run it by using a custom CI/CD pipeline job.

If you've already dismissed a vulnerability finding from the deprecated analyzer, the replacement attempts to respect your previous dismissal. The system behavior depends on:

- whether you've excluded the Semgrep-based analyzer from running in the past.
- which analyzer first discovered the vulnerabilities shown in the project's Vulnerability Report.

See [Vulnerability translation documentation](https://docs.gitlab.com/ee/user/application_security/sast/analyzers.html#vulnerability-translation) for further details.

If you applied customizations to the affected analyzer, or if you currently disable the Semgrep-based analyzer in your pipelines, you must take action as detailed in the [deprecation issue for this change](https://gitlab.com/gitlab-org/gitlab/-/issues/390416#breaking-change).

**Update:** We've reduced the scope of this change. We will no longer make the following changes in GitLab 16.0:

1. Remove support for the analyzer based on [PHPCS Security Audit](https://gitlab.com/gitlab-org/security-products/analyzers/phpcs-security-audit) and replace it with GitLab-managed detection rules in the [Semgrep-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep).
1. Remove Scala from the scope of the [SpotBugs-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs) and replace it with GitLab-managed detection rules in the [Semgrep-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep).

Work to replace the PHPCS Security Audit-based analyzer is tracked in [issue 364060](https://gitlab.com/gitlab-org/gitlab/-/issues/364060) and work to migrate Scala scanning to the Semgrep-based analyzer is tracked in [issue 362958](https://gitlab.com/gitlab-org/gitlab/-/issues/362958).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Secure analyzers major version update

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390912).

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

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/391822).

</div>

GitLab-managed CI/CD templates for security scanning will be updated in the GitLab 16.0 release.
The updates will include improvements already released in the Latest versions of the CI/CD templates.
We released these changes in the Latest template versions because they have the potential to disrupt customized CI/CD pipeline configurations.

In all updated templates, we're updating the definition of variables like `SAST_DISABLED` and `DEPENDENCY_SCANNING_DISABLED` to disable scanning only if the value is `"true"`. Previously, even if the value were `"false"`, scanning would be disabled.

The following templates will be updated:

- API Fuzzing: [`API-Fuzzing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml)
- Container Scanning: [`Container-Scanning.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Container-Scanning.gitlab-ci.yml)
- Coverage-Guided Fuzzing: [`Coverage-Fuzzing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/Coverage-Fuzzing.gitlab-ci.yml)
- DAST: [`DAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST.gitlab-ci.yml)
- DAST API: [`DAST-API.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST-API.gitlab-ci.yml)
- Dependency Scanning: [`Dependency-Scanning.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.gitlab-ci.yml)
- IaC Scanning: [`SAST-IaC.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST-IaC.gitlab-ci.yml)
- SAST: [`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml)
- Secret Detection: [`Secret-Detection.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Secret-Detection.gitlab-ci.yml)

We recommend that you test your pipelines before the 16.0 release if you use one of the templates listed above and you use the `_DISABLED` variables but set a value other than `"true"`.

**Update:** We previously announced that we would update the `rules` on the affected templates to run in [merge request pipelines](https://docs.gitlab.com/ee/ci/pipelines/merge_request_pipelines.html) by default.
However, due to compatibility issues [discussed in the deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/388988#note_1372629948), we will no longer make this change in GitLab 16.0. We will still release the changes to the `_DISABLED` variables as described above.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Security report schemas version 14.x.x

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.3</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/366477).

</div>

Version 14.x.x [security report schemas](https://gitlab.com/gitlab-org/security-products/security-report-schemas) are deprecated.

In GitLab 15.8 and later, [security report scanner integrations](https://docs.gitlab.com/ee/development/integrations/secure.html) that use schema version 14.x.x will display a deprecation warning in the pipeline's **Security** tab.

In GitLab 16.0 and later, the feature will be removed. Security reports that use schema version 14.x.x will cause an error in the pipeline's **Security** tab.

For more information, refer to [security report validation](https://docs.gitlab.com/ee/user/application_security/#security-report-validation).

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Starboard directive in the configuration of the GitLab agent for Kubernetes

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.4</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/368828).

</div>

GitLab container scanning capabilities no longer require starboard to be installed. Consequently, use of the `starboard:` directive in the configuration file for the GitLab agent for Kubernetes is now deprecated and is scheduled for removal in GitLab 16.0. Update your configuration file to use the `container_scanning:` directive.

</div>

<div class="deprecation " data-milestone="16.0">

### Stop publishing GitLab Runner images based on Windows Server 2004 and 20H2

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">16.0</span>
- Removal in GitLab <span class="milestone">16.0</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/31001).

</div>

As of GitLab 16.0, GitLab Runner images based on Windows Server 2004 and 20H2 will not be provided as these operating systems are end-of-life.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Support for Praefect custom metrics endpoint configuration

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/390266).

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

- Announced in GitLab <span class="milestone">15.7</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/385564).

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

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/382129).

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

- Announced in GitLab <span class="milestone">15.7</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-com/Product/-/issues/4894).

</div>

The Phabricator task importer is being deprecated. Phabricator itself as a project is no longer actively maintained since June 1, 2021. We haven't observed imports using this tool. There has been no activity on the open related issues on GitLab.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### The latest Terraform templates will overwrite current stable templates

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/386001).

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

- Announced in GitLab <span class="milestone">15.4</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/365365).

</div>

In order to make the behavior of toggling the draft status of a merge request more clear via a quick action, we're deprecating and removing the toggle behavior of the `/draft` quick action. Beginning with the 16.0 release of GitLab, `/draft` will only set a merge request to Draft and a new `/ready` quick action will be used to remove the draft status.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Use of `id` field in `vulnerabilityFindingDismiss` mutation

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.3</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/367166).

</div>

You can use the `vulnerabilityFindingDismiss` GraphQL mutation to set the status of a vulnerability finding to `Dismissed`. Previously, this mutation used the `id` field to identify findings uniquely. However, this did not work for dismissing findings from the pipeline security tab. Therefore, using the `id` field as an identifier has been dropped in favor of the `uuid` field. Using the 'uuid' field as an identifier allows you to dismiss the finding from the pipeline security tab.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Use of third party container registries is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/376216).

</div>

Using third-party container registries with GitLab as an auth endpoint is deprecated in GitLab 15.8 and the [end of support](https://docs.gitlab.com/ee/development/deprecation_guidelines/#terminology) is scheduled for GitLab 16.0. This impacts users on GitLab Self-Managed that have connected their external registry to the GitLab user interface to find, view, and delete container images.

Supporting both the GitLab container registry as well as third-party container registries is challenging for maintenance, code quality, and backward compatibility. This hinders our ability to stay [efficient](https://handbook.gitlab.com/handbook/values/#efficiency). As a result we will not support this functionality moving forward.

This change will not impact your ability to pull and push container images to external registries using pipelines.

Since we released the new [GitLab container registry](https://gitlab.com/groups/gitlab-org/-/epics/5523) version for GitLab.com, we've started to implement additional features that are not available in third-party container registries. These new features have allowed us to achieve significant performance improvements, such as [cleanup policies](https://gitlab.com/groups/gitlab-org/-/epics/8379). We are focusing on delivering [new features](https://gitlab.com/groups/gitlab-org/-/epics/5136), most of which will require functionalities only available on the GitLab container registry. This deprecation allows us to reduce fragmentation and user frustration in the long term by focusing on delivering a more robust integrated registry experience and feature set.

Moving forward, we'll continue to invest in developing and releasing new features that will only be available in the GitLab container registry.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Work items path with global ID at the end of the path is deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.10</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/393836).

</div>

Usage of global IDs in work item URLs is deprecated. In the future, only internal IDs (IID) will be supported.

Because GitLab supports multiple work item types, a path such as `https://gitlab.com/gitlab-org/gitlab/-/work_items/<global_id>` can display, for example, a [task](https://docs.gitlab.com/ee/user/tasks.html) or an [OKR](https://docs.gitlab.com/ee/user/okrs.html).

In GitLab 15.10 we added support for using internal IDs (IID) in that path by appending a query parameter at
the end (`iid_path`) in the following format: `https://gitlab.com/gitlab-org/gitlab/-/work_items/<iid>?iid_path=true`.

In GitLab 16.0 we will remove the ability to use a global ID in the work items path. The number at the end of the path will be considered an internal ID (IID) without the need of adding a query parameter at the end. Only the following format will be supported: `https://gitlab.com/gitlab-org/gitlab/-/work_items/<iid>`.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### `CI_BUILD_*` predefined variables

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/352957).

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

- Announced in GitLab <span class="milestone">15.7</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/381669).

</div>

The `POST ci/lint` API endpoint is deprecated in 15.7, and will be removed in 16.0. This endpoint does not validate the full range of CI/CD configuration options. Instead, use [`POST /projects/:id/ci/lint`](https://docs.gitlab.com/ee/api/lint.html#validate-a-ci-yaml-configuration-with-a-namespace), which properly validates CI/CD configuration.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### `environment_tier` parameter for DORA API

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/365939).

</div>

To avoid confusion and duplication, the `environment_tier` parameter is deprecated in favor of the `environment_tiers` parameter. The new `environment_tiers` parameter allows DORA APIs to return aggregated data for multiple tiers at the same time. The `environment_tier` parameter will be removed in GitLab 16.0.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### `name` field for `PipelineSecurityReportFinding` GraphQL type

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.1</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/346335).

</div>

Previously, the [`PipelineSecurityReportFinding` GraphQL type was updated](https://gitlab.com/gitlab-org/gitlab/-/issues/335372) to include a new `title` field. This field is an alias for the current `name` field, making the less specific `name` field redundant. The `name` field will be removed from the `PipelineSecurityReportFinding` type in GitLab 16.0.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### `started` iteration state

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/334018).

</div>

The `started` iteration state in the [iterations GraphQL API](https://docs.gitlab.com/ee/api/graphql/reference/#iterationstate)
and [iterations REST API](https://docs.gitlab.com/ee/api/iterations.html#list-project-iterations) is deprecated.

The GraphQL API version will be removed in GitLab 16.0. This state is being replaced with the `current` state (already available)
which aligns with the naming for other time-based entities, such as milestones.

We plan to continue to support the `started` state in REST API version until the next v5 REST API version.

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### `vulnerabilityFindingDismiss` GraphQL mutation

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.5</span>
- Removal in GitLab <span class="milestone">16.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/375645).

</div>

The `VulnerabilityFindingDismiss` GraphQL mutation is being deprecated and will be removed in GitLab 16.0. This mutation was not used often as the Vulnerability Finding ID was not available to users (this field was [deprecated in 15.3](https://docs.gitlab.com/ee/update/deprecations.html#use-of-id-field-in-vulnerabilityfindingdismiss-mutation)). Users should instead use `VulnerabilityDismiss` to dismiss vulnerabilities in the Vulnerability Report or `SecurityFindingDismiss` for security findings in the CI Pipeline Security tab.

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.11">

## GitLab 15.11

<div class="deprecation " data-milestone="15.11">

### openSUSE Leap 15.3 packages

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">15.11</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7371).

</div>

Distribution support and security updates for openSUSE Leap 15.3 [ended December 2022](https://en.opensuse.org/Lifetime#Discontinued_distributions).

Starting in GitLab 15.7 we started providing packages for openSUSE Leap 15.4, and will stop providing packages for openSUSE Leap 15.3 in the 15.11 milestone.

- Switch from the openSUSE Leap 15.3 packages to the provided 15.4 packages.

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.10">

## GitLab 15.10

<div class="deprecation breaking-change" data-milestone="15.10">

### Automatic backup upload using OpenStack Swift and Rackspace APIs

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">15.10</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/387976).

</div>

We are deprecating support for **uploading backups to remote storage** using OpenStack Swift and Rackspace APIs. The support for these APIs depends on third-party libraries that are no longer actively maintained and have not been updated for Ruby 3. GitLab is switching over to Ruby 3 prior to EOL of Ruby 2 in order to stay up to date on security patches.

- If you're using OpenStack, you need to change you configuration to use the S3 API instead of Swift.
- If you're using Rackspace storage, you need to switch to a different provider or manually upload the backup file after the backup task is complete.

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.9">

## GitLab 15.9

<div class="deprecation breaking-change" data-milestone="15.9">

### GitLab.com certificate-based integration with Kubernetes

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.5</span>
- Removal in GitLab <span class="milestone">15.9</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/groups/gitlab-org/configure/-/epics/8).

</div>

The certificate-based integration with Kubernetes will be [deprecated and removed](https://about.gitlab.com/blog/2021/11/15/deprecating-the-cert-based-kubernetes-integration/). As a GitLab.com user, on new namespaces, you will no longer be able to integrate GitLab and your cluster using the certificate-based approach as of GitLab 15.0. The integration for current users will be enabled per namespace.

For a more robust, secure, forthcoming, and reliable integration with Kubernetes, we recommend you use the
[agent for Kubernetes](https://docs.gitlab.com/ee/user/clusters/agent/) to connect Kubernetes clusters with GitLab. [How do I migrate?](https://docs.gitlab.com/ee/user/infrastructure/clusters/migrate_to_gitlab_agent.html)

Although an explicit removal date is set, we don't plan to remove this feature until the new solution has feature parity.
For more information about the blockers to removal, see [this issue](https://gitlab.com/gitlab-org/configure/general/-/issues/199).

For updates and details about this deprecation, follow [this epic](https://gitlab.com/groups/gitlab-org/configure/-/epics/8).

GitLab Self-Managed customers can still use the feature [with a feature flag](https://docs.gitlab.com/ee/update/deprecations.html#self-managed-certificate-based-integration-with-kubernetes).

</div>

<div class="deprecation breaking-change" data-milestone="15.9">

### Live Preview no longer available in the Web IDE

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.8</span>
- Removal in GitLab <span class="milestone">15.9</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/383889).

</div>

The Live Preview feature of the Web IDE was intended to provide a client-side preview of static web applications. However, complex configuration steps and a narrow set of supported project types have limited its utility. With the introduction of the Web IDE Beta in GitLab 15.7, you can now connect to a full server-side runtime environment. With upcoming support for installing extensions in the Web IDE, we'll also support more advanced workflows than those available with Live Preview. As of GitLab 15.9, Live Preview is no longer available in the Web IDE.

</div>

<div class="deprecation breaking-change" data-milestone="15.9">

### `omniauth-authentiq` gem no longer available

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.9</span>
- Removal in GitLab <span class="milestone">15.9</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/389452).

</div>

`omniauth-authentiq` is an OmniAuth strategy gem that was part of GitLab. The company providing authentication services, Authentiq, has shut down. Therefore the gem is being removed.

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.7">

## GitLab 15.7

<div class="deprecation breaking-change" data-milestone="15.7">

### File Type variable expansion in `.gitlab-ci.yml`

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.5</span>
- Removal in GitLab <span class="milestone">15.7</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/29407).

</div>

Previously, variables that referenced or applied alias file variables expanded the value of the `File` type variable. For example, the file contents. This behavior was incorrect because it did not comply with typical shell variable expansion rules. To leak secrets or sensitive information stored in `File` type variables, a user could run an $echo command with the variable as an input parameter.

This breaking change fixes this issue but could disrupt user workflows that work around the behavior. With this change, job variable expansions that reference or apply alias file variables, expand to the filename or path of the `File` type variable, instead of its value, such as the file contents.

</div>

<div class="deprecation " data-milestone="15.7">

### Flowdock integration

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.7</span>
- Removal in GitLab <span class="milestone">15.7</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/379197).

</div>

As of December 22, 2022, we are removing the Flowdock integration because the service was shut down on August 15, 2022.

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.6">

## GitLab 15.6

<div class="deprecation " data-milestone="15.6">

### NFS for Git repository storage

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.0</span>
- Removal in GitLab <span class="milestone">15.6</span>

</div>

With the general availability of Gitaly Cluster ([introduced in GitLab 13.0](https://about.gitlab.com/releases/2020/05/22/gitlab-13-0-released/)), we have deprecated development (bugfixes, performance improvements, etc) for NFS for Git repository storage in GitLab 14.0. We will continue to provide technical support for NFS for Git repositories throughout 14.x, but we will remove all support for NFS on November 22, 2022. This was originally planned for May 22, 2022, but in an effort to allow continued maturity of Gitaly Cluster, we have chosen to extend our deprecation of support date. Please see our official [Statement of Support](https://about.gitlab.com/support/statement-of-support/#gitaly-and-nfs) for further information.

Gitaly Cluster offers tremendous benefits for our customers such as:

- [Variable replication factors](https://docs.gitlab.com/ee/administration/gitaly/#replication-factor).
- [Strong consistency](https://docs.gitlab.com/ee/administration/gitaly/#strong-consistency).
- [Distributed read capabilities](https://docs.gitlab.com/ee/administration/gitaly/#distributed-reads).

We encourage customers currently using NFS for Git repositories to plan their migration by reviewing our documentation on [migrating to Gitaly Cluster](https://docs.gitlab.com/ee/administration/gitaly/#migrate-to-gitaly-cluster).

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.4">

## GitLab 15.4

<div class="deprecation " data-milestone="15.4">

### Bundled Grafana deprecated

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.3</span>
- Removal in GitLab <span class="milestone">15.4</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6972).

</div>

In GitLab 15.4, we will be swapping the bundled Grafana to a fork of Grafana maintained by GitLab.

There was an [identified CVE for Grafana](https://nvd.nist.gov/vuln/detail/CVE-2022-31107), and to mitigate this security vulnerability, we must swap to our own fork because the older version of Grafana we were bundling is no longer receiving long-term support.

This is not expected to cause any incompatibilities with the previous version of Grafana. Neither when using our bundled version, nor when using an external instance of Grafana.

</div>

<div class="deprecation breaking-change" data-milestone="15.4">

### SAST analyzer consolidation and CI/CD template changes

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.4</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/352554).

</div>

GitLab SAST uses various [analyzers](https://docs.gitlab.com/ee/user/application_security/sast/analyzers/) to scan code for vulnerabilities.

We are reducing the number of analyzers used in GitLab SAST as part of our long-term strategy to deliver a better and more consistent user experience.
Streamlining the set of analyzers will also enable faster [iteration](https://handbook.gitlab.com/handbook/values/#iteration), better [results](https://handbook.gitlab.com/handbook/values/#results), and greater [efficiency](https://handbook.gitlab.com/handbook/values/#efficiency) (including a reduction in CI runner usage in most cases).

In GitLab 15.4, GitLab SAST will no longer use the following analyzers:

- [ESLint](https://gitlab.com/gitlab-org/security-products/analyzers/eslint) (JavaScript, TypeScript, React)
- [Gosec](https://gitlab.com/gitlab-org/security-products/analyzers/gosec) (Go)
- [Bandit](https://gitlab.com/gitlab-org/security-products/analyzers/bandit) (Python)

NOTE:
This change was originally planned for GitLab 15.0 and was postponed to GitLab 15.4.

These analyzers will be removed from the [GitLab-managed SAST CI/CD template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml) and replaced with the [Semgrep-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep).
Effective immediately, they will receive only security updates; other routine improvements or updates are not guaranteed.
After these analyzers reach End of Support, no further updates will be provided.
We will not delete container images previously published for these analyzers; any such change would be announced as a [deprecation, removal, or breaking change announcement](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#deprecations-removals-and-breaking-changes).

We will also remove Java from the scope of the [SpotBugs](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs) analyzer and replace it with the [Semgrep-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep).
This change will make it simpler to scan Java code; compilation will no longer be required.
This change will be reflected in the automatic language detection portion of the [GitLab-managed SAST CI/CD template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml). Note that the SpotBugs-based analyzer will continue to cover Groovy, Kotlin, and Scala.

If you've already dismissed a vulnerability finding from one of the deprecated analyzers, the replacement attempts to respect your previous dismissal. The system behavior depends on:

- whether you've excluded the Semgrep-based analyzer from running in the past.
- which analyzer first discovered the vulnerabilities shown in the project's Vulnerability Report.

See [Vulnerability translation documentation](https://docs.gitlab.com/ee/user/application_security/sast/analyzers.html#vulnerability-translation) for further details.

If you applied customizations to any of the affected analyzers or if you currently disable the Semgrep analyzer in your pipelines, you must take action as detailed in the [deprecation issue for this change](https://gitlab.com/gitlab-org/gitlab/-/issues/352554#breaking-change).

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.3">

## GitLab 15.3

<div class="deprecation " data-milestone="15.3">

### Vulnerability Report sort by State

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.0</span>
- Removal in GitLab <span class="milestone">15.3</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/360516).

</div>

The ability to sort the Vulnerability Report by the `State` column was disabled and put behind a feature flag in GitLab 14.10 due to a refactor
of the underlying data model. The feature flag has remained off by default as further refactoring will be required to ensure sorting
by this value remains performant. Due to very low usage of the `State` column for sorting, the feature flag will instead be removed to simplify the codebase and prevent any unwanted performance degradation.

</div>

<div class="deprecation " data-milestone="15.3">

### Vulnerability Report sort by Tool

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">15.1</span>
- Removal in GitLab <span class="milestone">15.3</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/362962).

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

- Announced in GitLab <span class="milestone">14.9</span>
- Removal in GitLab <span class="milestone">15.1</span>

</div>

Long term service and support (LTSS) for [Debian 9 Stretch ends in July 2022](https://wiki.debian.org/LTS). Therefore, we will no longer support the Debian 9 distribution for the GitLab package. Users can upgrade to Debian 10 or Debian 11.

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.0">

## GitLab 15.0

<div class="deprecation breaking-change" data-milestone="15.0">

### Audit events for repository push events

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.3</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/337993).

</div>

Audit events for **repository events** are now deprecated and will be removed in GitLab 15.0.

These events have always been disabled by default and had to be manually enabled with a
feature flag. Enabling them can cause too many events to be generated which can
dramatically slow down GitLab instances. For this reason, they are being removed.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Background upload for object storage

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.9</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/26600).

</div>

To reduce the overall complexity and maintenance burden of the [object storage feature](https://docs.gitlab.com/ee/administration/object_storage.html), support for using `background_upload` to upload files is deprecated and will be fully removed in GitLab 15.0. Review the [15.0 specific changes](https://docs.gitlab.com/omnibus/update/gitlab_15_changes.html) for the [removed background uploads settings for object storage](https://docs.gitlab.com/omnibus/update/gitlab_15_changes.html#removed-background-uploads-settings-for-object-storage).

This impacts a small subset of object storage providers:

- **OpenStack** Customers using OpenStack need to change their configuration to use the S3 API instead of Swift.
- **RackSpace** Customers using RackSpace-based object storage need to migrate data to a different provider.

GitLab will publish additional guidance to assist affected customers in migrating.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### CI/CD job name length limit

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.6</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/342800).

</div>

In GitLab 15.0 we are going to limit the number of characters in CI/CD job names to 255. Any pipeline with job names that exceed the 255 character limit will stop working after the 15.0 release.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Changing an instance (shared) runner to a project (specific) runner

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.5</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/345347).

</div>

In GitLab 15.0, you can no longer change an instance (shared) runner to a project (specific) runner.

Users often accidentally change instance runners to project runners, and they're unable to change them back. GitLab does not allow you to change a project runner to a shared runner because of the security implications. A runner meant for one project could be set to run jobs for an entire instance.

Administrators who need to add runners for multiple projects can register a runner for one project, then go to the Admin view and choose additional projects.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Container Network and Host Security

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))

</div>

All functionality related to GitLab Container Network Security and
Container Host Security categories is deprecated in GitLab 14.8 and
scheduled for removal in GitLab 15.0. Users who need a replacement for this
functionality are encouraged to evaluate the following open source projects
as potential solutions that can be installed and managed outside of GitLab:
[AppArmor](https://gitlab.com/apparmor/apparmor),
[Cilium](https://github.com/cilium/cilium),
[Falco](https://github.com/falcosecurity/falco),
[FluentD](https://github.com/fluent/fluentd),
[Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/).

To integrate these technologies into GitLab, add the desired Helm charts
into your copy of the
[Cluster Management Project Template](https://docs.gitlab.com/ee/user/clusters/management_project_template.html).
Deploy these Helm charts in production by calling commands through GitLab
[CI/CD](https://docs.gitlab.com/ee/user/clusters/agent/ci_cd_workflow.html).

As part of this change, the following specific capabilities within GitLab
are now deprecated, and are scheduled for removal in GitLab 15.0:

- The **Security & Compliance > Threat Monitoring** page.
- The `Network Policy` security policy type, as found on the **Security & Compliance > Policies** page.
- The ability to manage integrations with the following technologies through GitLab: AppArmor, Cilium, Falco, FluentD, and Pod Security Policies.
- All APIs related to the above functionality.

For additional context, or to provide feedback regarding this change,
please reference our open
[deprecation issue](https://gitlab.com/groups/gitlab-org/-/epics/7476).

</div>

<div class="deprecation " data-milestone="15.0">

### Container scanning schemas below 14.0.0

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.7</span>
- Removal in GitLab <span class="milestone">15.0</span>

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

- Announced in GitLab <span class="milestone">14.7</span>
- Removal in GitLab <span class="milestone">15.0</span>

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

- Announced in GitLab <span class="milestone">14.7</span>
- Removal in GitLab <span class="milestone">15.0</span>

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

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/334060).

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

- Announced in GitLab <span class="milestone">14.10</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))

</div>

In GitLab 15.0, for Dependency Scanning, the default version of Java that the scanner expects will be updated from 11 to 17. Java 17 is [the most up-to-date Long Term Support (LTS) version](https://en.wikipedia.org/wiki/Java_version_history). Dependency scanning continues to support the same [range of versions (8, 11, 13, 14, 15, 16, 17)](https://docs.gitlab.com/ee/user/application_security/dependency_scanning/#supported-languages-and-package-managers), only the default version is changing. If your project uses the previous default of Java 11, be sure to [set the `DS_Java_Version` variable to match](https://docs.gitlab.com/ee/user/application_security/dependency_scanning/#configuring-specific-analyzers-used-by-dependency-scanning).

</div>

<div class="deprecation " data-milestone="15.0">

### Dependency scanning schemas below 14.0.0

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.7</span>
- Removal in GitLab <span class="milestone">15.0</span>

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

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/351345).

</div>

In GitLab 13.0, we introduced new project and design replication details routes in the Geo Admin UI. These routes are `/admin/geo/replication/projects` and `/admin/geo/replication/designs`. We kept the legacy routes and redirected them to the new routes. In GitLab 15.0, we will remove support for the legacy routes `/admin/geo/projects` and `/admin/geo/designs`. Please update any bookmarks or scripts that may use the legacy routes.

</div>

<div class="deprecation " data-milestone="15.0">

### Deprecate custom Geo:db:* Rake tasks

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/351945).

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

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/262019).

</div>

The feature flag `PUSH_RULES_SUPERSEDE_CODE_OWNERS` is being removed in GitLab 15.0. Upon its removal, push rules will supersede Code Owners. Even if Code Owner approval is required, a push rule that explicitly allows a specific user to push code supersedes the Code Owners setting.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Elasticsearch 6.8

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/350275).

</div>

Elasticsearch 6.8 is deprecated in GitLab 14.8 and scheduled for removal in GitLab 15.0.
Customers using Elasticsearch 6.8 need to upgrade their Elasticsearch version to 7.x prior to upgrading to GitLab 15.0.
We recommend using the latest version of Elasticsearch 7 to benefit from all Elasticsearch improvements.

Elasticsearch 6.8 is also incompatible with Amazon OpenSearch, which we [plan to support in GitLab 15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/327560).

</div>

<div class="deprecation " data-milestone="15.0">

### Enforced validation of security report schemas

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.7</span>
- Removal in GitLab <span class="milestone">15.0</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/groups/gitlab-org/-/epics/6968).

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

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))

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

- Announced in GitLab <span class="milestone">14.9</span>
- Removal in GitLab <span class="milestone">15.0</span>

</div>

In 15.0, support for daemon mode for GitLab Pages will be removed.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### GitLab Serverless

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.3</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/groups/gitlab-org/configure/-/epics/6).

</div>

GitLab Serverless is a feature set to support Knative-based serverless development with automatic deployments and monitoring.

We decided to remove the GitLab Serverless features as they never really resonated with our users. Besides, given the continuous development of Kubernetes and Knative, our current implementations do not even work with recent versions.

</div>

<div class="deprecation " data-milestone="15.0">

### Godep support in License Compliance

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.7</span>
- Removal in GitLab <span class="milestone">15.0</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/327057).

</div>

The Godep dependency manager for Go was deprecated in 2020 by Go and
has been replaced with Go modules.
To reduce our maintenance cost we are deprecating License Compliance for Godep projects as of 14.7
and will remove it in GitLab 15.0

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### GraphQL ID and GlobalID compatibility

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/257883).

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

- Announced in GitLab <span class="milestone">14.9</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))

</div>

The GitLab Package stage offers a Package Registry, container registry, and Dependency Proxy to help you manage all of your dependencies using GitLab. Each of these product categories has a variety of settings that can be adjusted using the API.

The permissions model for GraphQL is being updated. After 15.0, users with the Guest, Reporter, and Developer role can no longer update these settings:

- [Package Registry settings](https://docs.gitlab.com/ee/api/graphql/reference/#packagesettings)
- [Container registry cleanup policy](https://docs.gitlab.com/ee/api/graphql/reference/#containerexpirationpolicy)
- [Dependency Proxy time-to-live policy](https://docs.gitlab.com/ee/api/graphql/reference/#dependencyproxyimagettlgrouppolicy)
- [Enabling the Dependency Proxy for your group](https://docs.gitlab.com/ee/api/graphql/reference/#dependencyproxysetting)

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Known host required for GitLab Runner SSH executor

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.5</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28192).

</div>

In [GitLab 14.3](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3074), we added a configuration setting in the GitLab Runner `config.toml` file. This setting, [`[runners.ssh.disable_strict_host_key_checking]`](https://docs.gitlab.com/runner/executors/ssh.html#security), controls whether or not to use strict host key checking with the SSH executor.

In GitLab 15.0 and later, the default value for this configuration option will change from `true` to `false`. This means that strict host key checking will be enforced when using the GitLab Runner SSH executor.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Legacy approval status names from License Compliance API

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.6</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/335707).

</div>

We deprecated legacy names for approval status of license policy (`blacklisted`, `approved`) in the `managed_licenses` API but they are still used in our API queries and responses. They will be removed in 15.0.

If you are using our License Compliance API you should stop using the `approved` and `blacklisted` query parameters, they are now `allowed` and `denied`. In 15.0 the responses will also stop using `approved` and `blacklisted` so you need to adjust any of your custom tools to use the old and new values so they do not break with the 15.0 release.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Legacy database configuration

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.3</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/338182).

</div>

The syntax of [GitLabs database](https://docs.gitlab.com/omnibus/settings/database.html)
configuration located in `database.yml` is changing and the legacy format is deprecated. The legacy format
supported using a single PostgreSQL adapter, whereas the new format is changing to support multiple databases. The `main:` database needs to be defined as a first configuration item.

This deprecation mainly impacts users compiling GitLab from source because Omnibus will handle this configuration automatically.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Logging in GitLab

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.7</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/346485).

</div>

The logging features in GitLab allow users to install the ELK stack (Elasticsearch, Logstash, and Kibana) to aggregate and manage application logs. Users can search for relevant logs in GitLab. However, since deprecating certificate-based integration with Kubernetes clusters and GitLab Managed Apps, we don't have a recommended solution for logging within GitLab. For more information, you can follow the issue for [integrating Opstrace with GitLab](https://gitlab.com/groups/gitlab-org/-/epics/6976).

</div>

<div class="deprecation " data-milestone="15.0">

### Move `custom_hooks_dir` setting from GitLab Shell to Gitaly

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.9</span>
- Removal in GitLab <span class="milestone">15.0</span>

</div>

The [`custom_hooks_dir`](https://docs.gitlab.com/ee/administration/server_hooks.html#create-a-global-server-hook-for-all-repositories) setting is now configured in Gitaly, and will be removed from GitLab Shell in GitLab 15.0.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### OAuth implicit grant

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.0</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))

</div>

The OAuth implicit grant authorization flow will be removed in our next major release, GitLab 15.0. Any applications that use OAuth implicit grant should switch to alternative [supported OAuth flows](https://docs.gitlab.com/ee/api/oauth2.html).

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### OAuth tokens without expiration

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))

</div>

By default, all new applications expire access tokens after 2 hours. In GitLab 14.2 and earlier, OAuth access tokens
had no expiration. In GitLab 15.0, an expiry will be automatically generated for any existing token that does not
already have one.

You should [opt in](https://docs.gitlab.com/ee/integration/oauth_provider.html#access-token-expiration) to expiring
tokens before GitLab 15.0 is released:

1. Edit the application.
1. Select **Expire access tokens** to enable them. Tokens must be revoked or they don't expire.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### OmniAuth Kerberos gem

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.3</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/337384).

</div>

The `omniauth-kerberos` gem will be removed in our next major release, GitLab 15.0.

This gem has not been maintained and has very little usage. We therefore plan to remove support for this authentication method and recommend using the Kerberos [SPNEGO](https://en.wikipedia.org/wiki/SPNEGO) integration instead. You can follow the [upgrade instructions](https://docs.gitlab.com/ee/integration/kerberos.html#upgrading-from-password-based-to-ticket-based-kerberos-sign-ins) to upgrade from the `omniauth-kerberos` integration to the supported one.

Note that we are not deprecating the Kerberos SPNEGO integration, only the old password-based Kerberos integration.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Optional enforcement of PAT expiration

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/351962).

</div>

The feature to disable enforcement of PAT expiration is unusual from a security perspective.
We have become concerned that this unusual feature could create unexpected behavior for users.
Unexpected behavior in a security feature is inherently dangerous, so we have decided to remove this feature.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Optional enforcement of SSH expiration

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/351963).

</div>

The feature to disable enforcement of SSH expiration is unusual from a security perspective.
We have become concerned that this unusual feature could create unexpected behavior for users.
Unexpected behavior in a security feature is inherently dangerous, so we have decided to remove this feature.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Out-of-the-box SAST support for Java 8

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/352549).

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

- Announced in GitLab <span class="milestone">14.10</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/359133).

</div>

As Advanced Search migrations usually require support multiple code paths for a long period of time,
it's important to clean those up when we safely can. We use GitLab major version upgrades as a safe
time to remove backward compatibility for indices that have not been fully migrated. See the
[upgrade documentation](https://docs.gitlab.com/ee/update/#upgrading-to-a-new-major-version) for details.

</div>

<div class="deprecation " data-milestone="15.0">

### Pseudonymizer

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.7</span>
- Removal in GitLab <span class="milestone">15.0</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/219952).

</div>

The Pseudonymizer feature is generally unused,
can cause production issues with large databases,
and can interfere with object storage development.
It is now considered deprecated, and will be removed in GitLab 15.0.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Querying usage trends via the `instanceStatisticsMeasurements` GraphQL node

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/332323).

</div>

The `instanceStatisticsMeasurements` GraphQL node has been renamed to `usageTrendsMeasurements` in 13.10 and the old field name has been marked as deprecated. To fix the existing GraphQL queries, replace `instanceStatisticsMeasurements` with `usageTrendsMeasurements`.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Request profiling

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/352488).

</div>

[Request profiling](https://docs.gitlab.com/ee/administration/monitoring/performance/) is deprecated in GitLab 14.8 and scheduled for removal in GitLab 15.0.

We're working on [consolidating our profiling tools](https://gitlab.com/groups/gitlab-org/-/epics/7327) and making them more easily accessible.
We [evaluated](https://gitlab.com/gitlab-org/gitlab/-/issues/350152) the use of this feature and we found that it is not widely used.
It also depends on a few third-party gems that are not actively maintained anymore, have not been updated for the latest version of Ruby, or crash frequently when profiling heavy page loads.

For more information, check the [summary section of the deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/352488#deprecation-summary).

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Required pipeline configurations in Premium tier

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))

</div>

The [required pipeline configuration](https://docs.gitlab.com/ee/administration/settings/continuous_integration.html#required-pipeline-configuration) feature is deprecated in GitLab 14.8 for Premium customers and is scheduled for removal in GitLab 15.0. This feature is not deprecated for GitLab Ultimate customers.

This change to move the feature to GitLab Ultimate tier is intended to help our features better align with our [pricing philosophy](https://handbook.gitlab.com/handbook/company/pricing/#three-tiers) as we see demand for this feature originating primarily from executives.

This change will also help GitLab remain consistent in its tiering strategy with the other related Ultimate-tier features of:
[Security policies](https://docs.gitlab.com/ee/user/application_security/policies/) and [compliance framework pipelines](https://docs.gitlab.com/ee/user/project/settings/#compliance-pipeline-configuration).

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Retire-JS Dependency Scanning tool

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/350510).

</div>

As of 14.8 the retire.js job is being deprecated from Dependency Scanning. It will continue to be included in our CI/CD template while deprecated. We are removing retire.js from Dependency Scanning on May 22, 2022 in GitLab 15.0. JavaScript scanning functionality will not be affected as it is still being covered by Gemnasium.

If you have explicitly excluded retire.js using DS_EXCLUDED_ANALYZERS you will need to clean up (remove the reference) in 15.0. If you have customized your pipeline's Dependency Scanning configuration related to the `retire-js-dependency_scanning` job you will want to switch to gemnasium-dependency_scanning before the removal in 15.0, to prevent your pipeline from failing. If you have not used the DS_EXCLUDED_ANALYZERS to reference retire.js, or customized your template specifically for retire.js, you will not need to take action.

</div>

<div class="deprecation " data-milestone="15.0">

### SAST schemas below 14.0.0

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.7</span>
- Removal in GitLab <span class="milestone">15.0</span>

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

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/352553).

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

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/352565).

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

- Announced in GitLab <span class="milestone">14.7</span>
- Removal in GitLab <span class="milestone">15.0</span>

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

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/352564).

</div>

GitLab uses various [analyzers](https://docs.gitlab.com/ee/user/application_security/terminology/#analyzer) to [scan for security vulnerabilities](https://docs.gitlab.com/ee/user/application_security/).
Each analyzer is distributed as a container image.

Starting in GitLab 14.8, new versions of GitLab Secure and Protect analyzers are published to a new registry location under `registry.gitlab.com/security-products`.

We will update the default value of [GitLab-managed CI/CD templates](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Security) to reflect this change:

- For all analyzers except Container Scanning, we will update the variable `SECURE_ANALYZERS_PREFIX` to the new image registry location.
- For Container Scanning, the default image address is already updated. There is no `SECURE_ANALYZERS_PREFIX` variable for Container Scanning.

In a future release, we will stop publishing images to `registry.gitlab.com/gitlab-org/security-products/analyzers`.
Once this happens, you must take action if you manually pull images and push them into a separate registry. This is commonly the case for [offline deployments](https://docs.gitlab.com/ee/user/application_security/offline_deployments/).
Otherwise, you won't receive further updates.

See the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/352564) for more details.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Secure and Protect analyzer major version update

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/350936).

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

- Announced in GitLab <span class="milestone">14.7</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/347509).

</div>

Exporting Sidekiq metrics and health checks using a single process and port is deprecated.
Support will be removed in 15.0.

We have updated Sidekiq to export [metrics and health checks from two separate processes](https://gitlab.com/groups/gitlab-org/-/epics/6409)
to improve stability and availability and prevent data loss in edge cases.
As those are two separate servers, a configuration change will be required in 15.0
to explicitly set separate ports for metrics and health-checks.
The newly introduced settings for `sidekiq['health_checks_*']`
should always be set in `gitlab.rb`.
For more information, check the documentation for [configuring Sidekiq](https://docs.gitlab.com/ee/administration/sidekiq/).

These changes also require updates in either Prometheus to scrape the new endpoint or k8s health-checks to target the new
health-check port to work properly, otherwise either metrics or health-checks will disappear.

For the deprecation period those settings are optional
and GitLab will default the Sidekiq health-checks port to the same port as `sidekiq_exporter`
and only run one server (not changing the current behavior).
Only if they are both set and a different port is provided, a separate metrics server will spin up
to serve the Sidekiq metrics, similar to the way Sidekiq will behave in 15.0.

</div>

<div class="deprecation " data-milestone="15.0">

### Static Site Editor

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.7</span>
- Removal in GitLab <span class="milestone">15.0</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/347137).

</div>

The Static Site Editor will no longer be available starting in GitLab 15.0. Improvements to the Markdown editing experience across GitLab will deliver similiar benefit but with a wider reach. Incoming requests to the Static Site Editor will be redirected to the [Web IDE](https://docs.gitlab.com/ee/user/project/web_ide/).

Current users of the Static Site Editor can view the [documentation](https://docs.gitlab.com/ee/user/project/web_ide/) for more information, including how to remove the configuration files from existing projects.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Support for SLES 12 SP2

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.5</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))

</div>

Long term service and support (LTSS) for SUSE Linux Enterprise Server (SLES) 12 SP2 [ended on March 31, 2021](https://www.suse.com/lifecycle/). The CA certificates on SP2 include the expired DST root certificate, and it's not getting new CA certificate package updates. We have implemented some [workarounds](https://gitlab.com/gitlab-org/gitlab-omnibus-builder/-/merge_requests/191), but we will not be able to continue to keep the build running properly.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Support for gRPC-aware proxy deployed between Gitaly and rest of GitLab

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))

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

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))

</div>

To simplify setting a test coverage pattern, in GitLab 15.0 the
[project setting for test coverage parsing](https://docs.gitlab.com/ee/ci/pipelines/settings.html#add-test-coverage-results-using-project-settings-removed)
is being removed.

Instead, using the project's `.gitlab-ci.yml`, provide a regular expression with the `coverage` keyword to set
testing coverage results in merge requests.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Tracing in GitLab

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.7</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/346540).

</div>

Tracing in GitLab is an integration with Jaeger, an open-source end-to-end distributed tracing system. GitLab users can go to their Jaeger instance to gain insight into the performance of a deployed application, tracking each function or microservice that handles a given request. Tracing in GitLab is deprecated in GitLab 14.7, and scheduled for removal in 15.0. To track work on a possible replacement, see the issue for [Opstrace integration with GitLab](https://gitlab.com/groups/gitlab-org/-/epics/6976).

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Update to the container registry group-level API

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.5</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/336912).

</div>

In milestone 15.0, support for the `tags` and `tags_count` parameters will be removed from the container registry API that [gets registry repositories from a group](https://docs.gitlab.com/ee/api/container_registry.html#within-a-group).

The `GET /groups/:id/registry/repositories` endpoint will remain, but won't return any info about tags. To get the info about tags, you can use the existing `GET /registry/repositories/:id` endpoint, which will continue to support the `tags` and `tag_count` options as it does today. The latter must be called once per image repository.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Value Stream Analytics filtering calculation change

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.5</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/343210).

</div>

We are changing how the date filter works in Value Stream Analytics. Instead of filtering by the time that the issue or merge request was created, the date filter will filter by the end event time of the given stage. This will result in completely different figures after this change has rolled out.

If you monitor Value Stream Analytics metrics and rely on the date filter, to avoid losing data, you must save the data prior to this change.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Vulnerability Check

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))

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

- Announced in GitLab <span class="milestone">14.5</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/327453).

</div>

As part of the work to create a [Package Registry GraphQL API](https://gitlab.com/groups/gitlab-org/-/epics/6318), the Package group deprecated the `Version` type for the basic `PackageType` type and moved it to [`PackageDetailsType`](https://docs.gitlab.com/ee/api/graphql/reference/#packagedetailstype).

In milestone 15.0, we will completely remove `Version` from `PackageType`.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `apiFuzzingCiConfigurationCreate` GraphQL mutation

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.6</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/333233).

</div>

The API Fuzzing configuration snippet is now being generated client-side and does not require an
API request anymore. We are therefore deprecating the `apiFuzzingCiConfigurationCreate` mutation
which isn't being used in GitLab anymore.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `artifacts:reports:cobertura` keyword

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.7</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/348980).

</div>

Currently, test coverage visualizations in GitLab only support Cobertura reports. Starting 15.0, the
`artifacts:reports:cobertura` keyword will be replaced by
[`artifacts:reports:coverage_report`](https://gitlab.com/gitlab-org/gitlab/-/issues/344533). Cobertura will be the
only supported report file in 15.0, but this is the first step towards GitLab supporting other report types.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `defaultMergeCommitMessageWithDescription` GraphQL API field

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.5</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/345451).

</div>

The GraphQL API field `defaultMergeCommitMessageWithDescription` has been deprecated and will be removed in GitLab 15.0. For projects with a commit message template set, it will ignore the template.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `dependency_proxy_for_private_groups` feature flag

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.5</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/276777).

</div>

We added a feature flag because [GitLab-#11582](https://gitlab.com/gitlab-org/gitlab/-/issues/11582) changed how public groups use the Dependency Proxy. Prior to this change, you could use the Dependency Proxy without authentication. The change requires authentication to use the Dependency Proxy.

In milestone 15.0, we will remove the feature flag entirely. Moving forward, you must authenticate when using the Dependency Proxy.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `htpasswd` Authentication for the container registry

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.9</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))

</div>

The container registry supports [authentication](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#auth) with `htpasswd`. It relies on an [Apache `htpasswd` file](https://httpd.apache.org/docs/2.4/programs/htpasswd.html), with passwords hashed using `bcrypt`.

Since it isn't used in the context of GitLab (the product), `htpasswd` authentication will be deprecated in GitLab 14.9 and removed in GitLab 15.0.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `pipelines` field from the `version` field

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.5</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/342882).

</div>

In GraphQL, there are two `pipelines` fields that you can use in a [`PackageDetailsType`](https://docs.gitlab.com/ee/api/graphql/reference/#packagedetailstype) to get the pipelines for package versions:

- The `versions` field's `pipelines` field. This returns all the pipelines associated with all the package's versions, which can pull an unbounded number of objects in memory and create performance concerns.
- The `pipelines` field of a specific `version`. This returns only the pipelines associated with that single package version.

To mitigate possible performance problems, we will remove the `versions` field's `pipelines` field in milestone 15.0. Although you will no longer be able to get all pipelines for all versions of a package, you can still get the pipelines of a single version through the remaining `pipelines` field for that version.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `projectFingerprint` in `PipelineSecurityReportFinding` GraphQL

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))

</div>

The `projectFingerprint` field in the [`PipelineSecurityReportFinding`](https://docs.gitlab.com/ee/api/graphql/reference/#pipelinesecurityreportfinding)
GraphQL object is being deprecated. This field contains a "fingerprint" of security findings used to determine uniqueness.
The method for calculating fingerprints has changed, resulting in different values. Going forward, the new values will be
exposed in the UUID field. Data previously available in the `projectFingerprint` field will eventually be removed entirely.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `promote-db` command from `gitlab-ctl`

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.5</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/345207).

</div>

In GitLab 14.5, we introduced the command `gitlab-ctl promote` to promote any Geo secondary node to a primary during a failover. This command replaces `gitlab-ctl promote-db` which is used to promote database nodes in multi-node Geo secondary sites. `gitlab-ctl promote-db` will continue to function as-is and be available until GitLab 15.0. We recommend that Geo customers begin testing the new `gitlab-ctl promote` command in their staging environments and incorporating the new command in their failover procedures.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `promote-to-primary-node` command from `gitlab-ctl`

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.5</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/345207).

</div>

In GitLab 14.5, we introduced the command `gitlab-ctl promote` to promote any Geo secondary node to a primary during a failover. This command replaces `gitlab-ctl promote-to-primary-node` which was only usable for single-node Geo sites. `gitlab-ctl promote-to-primary-node` will continue to function as-is and be available until GitLab 15.0. We recommend that Geo customers begin testing the new `gitlab-ctl promote` command in their staging environments and incorporating the new command in their failover procedures.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `type` and `types` keyword in CI/CD configuration

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.6</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))

</div>

The `type` and `types` CI/CD keywords will be removed in GitLab 15.0. Pipelines that use these keywords will stop working, so you must switch to `stage` and `stages`, which have the same behavior.

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### bundler-audit Dependency Scanning tool

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.6</span>
- Removal in GitLab <span class="milestone">15.0</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/289832).

</div>

As of 14.6 bundler-audit is being deprecated from Dependency Scanning. It will continue to be in our CI/CD template while deprecated. We are removing bundler-audit from Dependency Scanning on May 22, 2022 in 15.0. After this removal Ruby scanning functionality will not be affected as it is still being covered by Gemnasium.

If you have explicitly excluded bundler-audit using DS_EXCLUDED_ANALYZERS you will need to clean up (remove the reference) in 15.0. If you have customized your pipeline's Dependency Scanning configuration, for example to edit the `bundler-audit-dependency_scanning` job, you will want to switch to gemnasium-dependency_scanning before removal in 15.0, to prevent your pipeline from failing. If you have not used the DS_EXCLUDED_ANALYZERS to reference bundler-audit, or customized your template specifically for bundler-audit, you will not need to take action.

</div>
</div>

<div class="milestone-wrapper" data-milestone="14.10">

## GitLab 14.10

<div class="deprecation breaking-change" data-milestone="14.10">

### Permissions change for downloading Composer dependencies

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.9</span>
- Removal in GitLab <span class="milestone">14.10</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))

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

- Announced in GitLab <span class="milestone">14.8</span>
- Removal in GitLab <span class="milestone">14.9</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/352612).

</div>

Configuring the `per_repository` Gitaly election strategy is [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/352612).
`per_repository` has been the only option since GitLab 14.0.

This change is part of regular maintenance to keep our codebase clean.

</div>

<div class="deprecation breaking-change" data-milestone="14.9">

### Integrated error tracking disabled by default

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.9</span>
- Removal in GitLab <span class="milestone">14.9</span> ([breaking change](https://docs.gitlab.com/ee/update/terminology.html#breaking-change))
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/issues/353639).

</div>

In GitLab 14.4, GitLab released an integrated error tracking backend that replaces Sentry. This feature caused database performance issues. In GitLab 14.9, integrated error tracking is removed from GitLab.com, and turned off by default in GitLab Self-Managed. While we explore the future development of this feature, please consider switching to the Sentry backend by [changing your error tracking to Sentry in your project settings](https://docs.gitlab.com/ee/operations/error_tracking.html#sentry-error-tracking).

For additional background on this removal, please reference [Disable Integrated Error Tracking by Default](https://gitlab.com/groups/gitlab-org/-/epics/7580). If you have feedback please add a comment to [Feedback: Removal of Integrated Error Tracking](https://gitlab.com/gitlab-org/gitlab/-/issues/355493).

</div>
</div>

<div class="milestone-wrapper" data-milestone="14.8">

## GitLab 14.8

<div class="deprecation " data-milestone="14.8">

### openSUSE Leap 15.2 packages

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.5</span>
- Removal in GitLab <span class="milestone">14.8</span>
- To discuss this change or learn more, see the [deprecation issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6427).

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

- Announced in GitLab <span class="milestone">14.2</span>
- Removal in GitLab <span class="milestone">14.6</span>

</div>

The [release-cli](https://gitlab.com/gitlab-org/release-cli) will be released as a [generic package](https://gitlab.com/gitlab-org/release-cli/-/packages) starting in GitLab 14.2. We will continue to deploy it as a binary to S3 until GitLab 14.5 and stop distributing it in S3 in GitLab 14.6.

</div>
</div>

<div class="milestone-wrapper" data-milestone="14.5">

## GitLab 14.5

<div class="deprecation " data-milestone="14.5">

### Rename Task Runner pod to Toolbox

<div class="deprecation-notes">

- Announced in GitLab <span class="milestone">14.2</span>
- Removal in GitLab <span class="milestone">14.5</span>

</div>

The Task Runner pod is used to execute periodic housekeeping tasks within the GitLab application and is often confused with the GitLab Runner. Thus, [Task Runner will be renamed to Toolbox](https://gitlab.com/groups/gitlab-org/charts/-/epics/25).

This will result in the rename of the sub-chart: `gitlab/task-runner` to `gitlab/toolbox`. Resulting pods will be named along the lines of `{{ .Release.Name }}-toolbox`, which will often be `gitlab-toolbox`. They will be locatable with the label `app=toolbox`.

</div>
</div>

DISCLAIMER:
This page contains information related to upcoming products, features, and functionality.
It is important to note that the information presented is for informational purposes only.
Please do not rely on this information for purchasing or planning purposes.
The development, release, and timing of any products, features, or functionality may be subject to change or delay and remain at the
sole discretion of GitLab Inc.
