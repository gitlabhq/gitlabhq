---
stage: Release Notes
group: Monthly Release
title: "GitLab 19.0 release notes - not yet released"
description: "Summary of features included in 19.0"
---

The following features are being delivered for GitLab 19.0.
These features are now available on GitLab.com.

We'd also like to announce this month's [Notable Contributor](https://contributors.gitlab.com/notable-contributors):
Norman Debald!

We are excited to recognize [Norman](https://gitlab.com/Modjo85), a Level 3 contributor
with more than 40 merged improvements across GitLab since joining in May 2022.

<!-- Copy this template, and paste it into the doc section where it belongs:

Primary feature, Agentic Core, Scale and Deployments, or Unified DevOps and Security.

Update all the information as needed.

### Feature explanation here

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../ci/yaml/_index.md), [Related issue](https://gitlab.com/groups/gitlab-org/-/work_items/17754)

{{< /details >}}

Now write 125 words or fewer to explain the value of this improvement.
Use phrases that start with, "In previous versions of GitLab, you couldn't... Now you can..."

Use present tense, and speak about "you" instead of "the user."
-->

## Primary features

### Group-level custom review instructions for GitLab Duo

<!-- categories: Duo Code Review -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Add-ons: Duo Enterprise
- Links: [Documentation](../../user/gitlab_duo/customize_duo/review_instructions.md#configure-custom-review-instructions-for-a-group), [Related issue](https://gitlab.com/groups/gitlab-org/-/work_items/21504)

{{< /details >}}

In previous versions of GitLab, you could only define custom review instructions for
GitLab Duo at the project level. Teams working across many projects in the
same group had to duplicate the same instructions in every project.

Now you can configure shared custom review instructions for an entire group and its subgroups.

Select a project in your group to use as a template. When GitLab Duo performs a code review, it combines the group-level `.gitlab/duo/mr-review-instructions.yaml` file with any instructions defined in the individual project.

Both Code Review Flow and GitLab Duo Code Review support group-level custom instructions.

### Configure work item types

<!-- categories: Team Planning -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/work_items/configurable_work_item_types.md), [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/9365)

{{< /details >}}

Previously, work item types could be either an **Issue** or a **Task**. You can now configure custom work item types in a project to match the way your team plans and tracks work.

You can create or rename types to **User Story**, **Bug**, or **Maintenance**. Each work items displays with it's type name and a unique icon. The new types support custom fields and status lifecycles, and appear in your saved views and issue boards. Type configuration in the top-level group (GitLab.com) or organization (GitLab Self-Managed) cascades down to all projects.

You can also control which types are available for each project. Enable or disable a type across all projects at once, or let individual projects manage their own type visibility. When you disable a type in a project, existing work items are not affected.

### GitLab Secrets Manager now available in open beta

<!-- categories: Secrets Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../ci/secrets/secrets_manager/_index.md), [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/21731)

{{< /details >}}

In previous versions of GitLab, the GitLab Secrets Manager was available only to a closed beta
cohort. Most teams relied on external services such as HashiCorp Vault or AWS Secrets Manager.

The GitLab Secrets Manager is now available in open beta for Premium and Ultimate customers on
GitLab.com and GitLab Self-Managed. When the GitLab Secrets Manager is enabled, project and group Owners
can store, retrieve, and reference CI/CD secrets in GitLab. Secrets are scoped to a project or group
and are accessible to only pipeline jobs that explicitly request them.

During open beta, GitLab Secrets Manager follows the
[beta support policy](../../policy/development_stages_support.md#beta) and might not be ready for production use.

To share feedback, see [issue 598100](https://gitlab.com/gitlab-org/gitlab/-/issues/598100).

### GitLab Duo Developer enhancements for merge request workflows

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/duo_agent_platform/flows/foundational_flows/developer.md), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228817)

{{< /details >}}

GitLab Duo Developer now supports multiple trigger methods: assign it to an issue, select
**Generate MR**, or `@mention` it in any issue or MR discussion thread to turn feedback,
To-do items, and design questions into code changes, follow-up MRs, or research summaries.

With `AGENTS.md` and `agent-config.yml`
configured, GitLab Duo Developer runs your tests and checks before committing. After a top-level
group or instance administrator enables the Developer Flow, GitLab automatically adds mention and assign triggers
to eligible projects.

### Dependency scanning by using SBOM generally available

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md), [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/20456)

{{< /details >}}

The GitLab SBOM-based dependency scanner is now generally available. Maven, Gradle, and Python
projects now have complete visibility into vulnerabilities across their full dependency tree,
including vulnerable packages introduced transitively, not just those declared directly.

The analyzer now includes automatic dependency resolution for Maven, Gradle, and Python projects.
When a lockfile or resolved dependency graph is not present, the analyzer automatically invokes tooling
to resolve the full transitive dependency graph before scanning. Dependency resolution is enabled by
default and requires little-to-no additional configuration beyond including the v2 Dependency Scanning template.

For projects where dependency resolution is not possible, the analyzer falls back to
manifest scanning. It parses `pom.xml`, `requirements.txt`, `build.gradle`, and
`build.gradle.kts` to identify direct dependencies. Manifest scanning ensures teams
always get a starting point for vulnerability coverage, even for projects without
lock or build files.

Manifest scanning is enabled by default and returns direct dependencies only.
For full transitive coverage, enable dependency resolution or provide a dependency lockfile or graph export manually.

## Agentic Core

### GitLab Duo Core moves to usage-based billing

<!-- categories: Duo Agent Platform, Duo Chat, Code Suggestions -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../subscriptions/subscription-add-ons.md#gitlab-duo-core), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/600144)

{{< /details >}}

Starting in GitLab 19.0, GitLab Duo Core moves to usage-based billing. Code Suggestions in the Web IDE and desktop IDEs now consume [GitLab Credits](../../subscriptions/gitlab_credits.md).

GitLab Duo Chat is also changing. For GitLab Duo Core users, Chat is now agentic and runs on GitLab Duo Agent Platform. To use GitLab Duo Chat in the GitLab UI or desktop IDEs, enable GitLab Duo Agent Platform for your instance or top-level group.

### Filter exact code search results by repository

<!-- categories: Global Search -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/search/exact_code_search.md#syntax), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/488467)

{{< /details >}}

You can now filter exact code search results by repository. With the `repo:` syntax,
you can directly scope your search query to specific repositories or repository patterns
without having to go to individual projects.

For example, searching for `def authenticate repo:my-group/my-project` returns results
only from that repository. You can also use partial paths or patterns to match multiple repositories.

### Merge request ready event trigger

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/duo_agent_platform/triggers/_index.md), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/592454)

{{< /details >}}

You can now configure flows and external agents to run on the **Merge request ready** event.

When a draft merge request is marked as ready for review, GitLab Duo automatically runs the flow or external agent. 

To configure a trigger, go to **AI** > **Triggers** in your project.

This feature is behind the `merge_request_ready_flow_trigger` feature flag, disabled by default.

### Claude Opus 4.7 now available in GitLab Duo Agent Platform

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/duo_agent_platform/model_selection.md#supported-models), [Related issue](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/work_items/2177)

{{< /details >}}

Claude Opus 4.7 is now available in GitLab Duo Agent Platform. Opus 4.7 delivers meaningful improvements to complex, multistep tasks that require sustained reasoning, precise instruction following, and self-verification before surfacing results. This includes flows supporting CI/CD pipelines, code review, vulnerability resolution, and more.

### Support for self-hosted Gemini models

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models), [Related issue](https://gitlab.com/groups/gitlab-org/-/work_items/21186)

{{< /details >}}

GitLab Duo Agent Platform Self-Hosted is now compatible with Gemini models. Gemini models support multiple flows, including the Code Review Flow, SAST Vulnerability Resolution Flow, Fix CI/CD Pipeline Flow, and more.

### Expanded open source model support in GitLab Duo Agent Platform

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models), [Related issue](https://gitlab.com/groups/gitlab-org/-/work_items/21186)

{{< /details >}}

GitLab Duo Agent Platform now supports additional open source models for self-hosted deployments, including Devstral 2 123B, GLM-5.1-FP8, and others. This helps customers power agentic workflows across a variety of environments, including offline and network-restricted deployments.

### Per-session tool approvals with admin controls

<!-- categories: Duo Agent Platform, Duo Chat -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/gitlab_duo_chat/agentic_chat.md#tool-approvals), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/596366)

{{< /details >}}

Before GitLab Duo Agentic Chat can use a tool on your behalf, it requires your approval. Each tool
invocation requires a separate approval.

Now, you can approve a trusted tool once for an entire session and streamline your workflows.

Administrators control whether tool approval for sessions is available. The following settings
cascade from instance to group to project:

- **On by default**
- **Off by default**
- **Always off**

Groups and subgroups can modify the setting unless an administrator sets it to **Always off**.

The default setting is **Off by default**, ensuring each tool invocation requires explicit approval
unless an administrator changes it.

### Resolve merge conflicts with GitLab Duo (Beta)

<!-- categories: Duo Agent Platform, Code Review Workflow -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/project/merge_requests/conflicts.md#resolve-conflicts-with-gitlab-duo), [Related issue](https://gitlab.com/groups/gitlab-org/-/work_items/20688)

{{< /details >}}

In previous versions of GitLab, you had to resolve merge conflicts manually in
the GitLab UI or from the command line, even for straightforward cases.

Now GitLab Duo can autonomously analyze merge conflicts, edit the conflicting
files, create a commit, and push to the source branch. Trigger conflict
resolution from the **Resolve conflicts** page or directly from the merge
request widget. When complete, GitLab Duo posts a summary comment so reviewers
can see what changed.

GitLab Duo respects branch protection rules and does not force-push to
protected branches.

This feature is in beta and is gated behind the `mr_ai_resolve_conflicts` feature flag,
disabled by default.

### Restrict the AI Catalog to a group hierarchy

<!-- categories: AI Catalog -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/duo_agent_platform/ai_catalog.md#restrict-the-ai-catalog-to-a-group-hierarchy), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/594617)

{{< /details >}}

Top-level group Owners can now restrict the AI Catalog to show only agents and flows owned by projects within their group hierarchy. This blocks agents, external agents, or flows not in this hierarchy from being visible or enabled by any user in that group.

### Purchase credits on the Free tier on GitLab Self-Managed

<!-- categories: Subscription Management -->

{{< details >}}

- Tier: Free
- Offering: GitLab Self-Managed
- Links: [Documentation](../../subscriptions/gitlab_credits.md#buy-gitlab-credits), [Related issue](https://gitlab.com/groups/gitlab-org/-/work_items/20165)

{{< /details >}}

Free tier users on GitLab Self-Managed can now unlock the full power of GitLab Duo Agent Platform, no Premium or Ultimate subscription required. Choose your monthly credit amount, commit to an annual term, and get instant access to AI-powered development tools. Credits refresh automatically each month, so your team always has what it needs to build faster and smarter.

### Admin-defined network access controls for Agent Platform remote flows

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/duo_agent_platform/environment_sandbox.md#configure-a-network-policy), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/593149)

{{< /details >}}

Administrators can now define centralized network policies for GitLab Duo Agent Platform remote flows
directly in Settings. Top-level group administrators on GitLab.com, and instance administrators on
GitLab Self-Managed and Dedicated, can configure organization-wide domain denylists and allowlists
that projects inherit automatically. An additional setting controls whether projects can
extend the approved domain list with custom entries. Policies are enforced at runtime
across all remote flows, giving security and platform teams a consistent governance layer
for agent network egress.

## Scale and Deployments

### PostgreSQL 17 minimum requirement

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/package_information/postgresql_versions.md), [Related issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/9792)

{{< /details >}}

The minimum supported version of PostgreSQL is now version 17. If you use the packaged PostgreSQL 16,
[upgrade the packaged PostgreSQL server](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server)
before installing GitLab 19.0.

### Linux package support for Ubuntu 20.04 discontinued

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../install/package/_index.md#supported-platforms), [Related issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8915)

{{< /details >}}

Ubuntu 20.04 reached end of standard support in May 2025. From GitLab 19.0, Linux packages are no
longer provided for Ubuntu 20.04. GitLab 18.11 is the last release with packages for this
distribution. Before upgrading to GitLab 19.0, migrate to Ubuntu 22.04 or another
[supported operating system](../../install/package/_index.md#supported-platforms).

### Redis 6 support removed

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../install/requirements.md), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/585839)

{{< /details >}}

Support for Redis 6 is removed in GitLab 19.0. If you use an external Redis 6 deployment, migrate
to Redis 7.2 or Valkey 7.2 before upgrading. The bundled Redis included with the Linux package has
used Redis 7 since GitLab 16.2 and is not affected.

### Mattermost removed from the Linux package

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.mattermost.com/administration-guide/onboard/migrate-gitlab-omnibus.html), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/590798)

{{< /details >}}

Bundled Mattermost is removed from the Linux package in GitLab 19.0. If you currently use the
bundled Mattermost, refer to
[Migrating from the Linux package to Mattermost Standalone](https://docs.mattermost.com/administration-guide/onboard/migrate-gitlab-omnibus.html)
for migration instructions. Customers not using the bundled Mattermost are not impacted.

### Linux package support for SUSE distributions discontinued

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../install/docker/installation.md), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/590801)

{{< /details >}}

Linux package support for SUSE distributions ends in GitLab 19.0, which affects openSUSE Leap 15.6,
SUSE Linux Enterprise Server 12.5, and SUSE Linux Enterprise Server 15.6. GitLab 18.11 is the last
version with Linux packages for these distributions. To continue to use SUSE distributions, migrate
to a [Docker deployment of GitLab](../../install/docker/installation.md).

### Spamcheck removed from Linux package and GitLab Helm chart

<!-- categories: Omnibus Package, Cloud Native Installation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/reporting/spamcheck.md), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/590796)

{{< /details >}}

[Spamcheck](../../administration/reporting/spamcheck.md) is removed from the Linux package and
GitLab Helm chart in GitLab 19.0. Customers not currently using Spamcheck are not impacted. If you
use the bundled Spamcheck, you can deploy it separately using
[Docker](https://gitlab.com/gitlab-org/gl-security/security-engineering/security-automation/spam/spamcheck).
No data migration is required.

### NGINX Ingress replaced by Gateway API with Envoy Gateway

<!-- categories: Cloud Native Installation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/charts/), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/590800)

{{< /details >}}

Gateway API with Envoy Gateway becomes the default networking configuration in the GitLab Helm chart
in GitLab 19.0, replacing NGINX Ingress which reached end-of-life in March 2026. If migration to
Envoy Gateway is not immediately feasible, you can explicitly re-enable the bundled NGINX Ingress,
which remains available until its planned removal in GitLab 20.0. This change does not impact the
NGINX used in the Linux package, or Helm chart instances using an externally managed Ingress or
Gateway API controller.

### Bundled PostgreSQL, Redis, and MinIO removed from GitLab Helm chart

<!-- categories: Cloud Native Installation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/590797)

{{< /details >}}

The bundled Bitnami PostgreSQL, Bitnami Redis, and MinIO charts are removed from the GitLab Helm
chart and GitLab Operator in GitLab 19.0 with no replacement. These components were intended only
for proof-of-concept and test environments and are not recommended for production use. If you run an
instance with any of these bundled services, follow the
[migration guide](https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/)
to configure external services before upgrading to GitLab 19.0.

### Reliable SCIM user deprovisioning for large groups

<!-- categories: User Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com
- Links: [Documentation](../../development/internal_api/_index.md#group-scim-api), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/521324)

{{< /details >}}

For organizations managing large numbers of users through SCIM, deprovisioning group members
could time out and return `500` errors. SCIM `DELETE` and `PATCH` requests now return a
success response immediately. Membership removal is handled asynchronously, so identity
providers and SCIM clients receive consistent success responses.

## Unified DevOps and Security

### Dependency scanning in security configuration profiles

<!-- categories: Security Testing Configuration -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/configuration/security_configuration_profiles.md), [Related issue](https://gitlab.com/groups/gitlab-org/-/work_items/19952)

{{< /details >}}

GitLab 18.11 introduced security configuration profiles for SAST and secret detection.
Now, dependency scanning is also available with the **Dependency Scanning - Default** profile.
This profile gives you a unified control surface to apply standardized SCA coverage across all
of your projects without editing a single CI/CD configuration file.

The profile activates two scan triggers:

- **Merge Request Pipelines**: Automatically runs a dependency scanning scan each time new commits are pushed to a branch with an open merge request. Results include only new vulnerabilities introduced by the merge request.
- **Branch Pipelines (default only)**: Runs automatically when changes are merged or pushed to the default branch, providing a complete view of your default branch's dependency posture.

### Improved array support for CI/CD inputs

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../ci/inputs/_index.md#access-individual-array-elements), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/587657)

{{< /details >}}

CI/CD inputs now have improved support for working with arrays.
Use the array index operator `[]` to access specific elements within array inputs.
This enhancement provides more flexible and powerful input interpolation capabilities in your pipeline configurations,
enabling you to reference individual array items directly without additional processing steps.

### Select multiple values for pipeline inputs

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../ci/inputs/_index.md#array-inputs-with-options), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/566155)

{{< /details >}}

Previously, you could only select a single value when selecting input options in the UI,
limiting flexibility for pipelines with more complex options.

Now when you run a pipeline with inputs from the UI, you can select multiple values from a dropdown list
and the selected values are combined into an array, for example `["option1","option2"]`.
This makes it easy to restart services on multiple instances, build multiple Docker images,
run tests with multiple tag combinations, or perform any operation across multiple targets
in a single pipeline run.

### Detailed CI/CD Catalog component usage analytics

<!-- categories: Component Catalog -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../ci/components/_index.md#view-component-usage-details), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/579460)

{{< /details >}}

When you manage a CI/CD component in the GitLab Catalog, usage details are critical for
managing upgrades, enforcing compliance, and communicating breaking changes.
You need to know which projects use your components, and which versions they are using.
Previously, this information was not available, making it difficult to notify
the right maintainers, plan deprecations safely, or ensure projects stay
current with the latest security patches.

The component usage details view in the catalog resource page now shows
exactly which projects use each component, the version they are running,
and whether they are on the latest version or an outdated one. Projects
using older versions are surfaced at the top, so you can prioritize
outreach, drive adoption of security fixes, and ensure a smooth upgrade
path across your organization.

### Configure parallel pipeline limits for merge trains

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../administration/instance_limits.md#merge-train-parallel-pipeline-limit),
 [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/374188)

{{< /details >}}

In previous versions of GitLab, you couldn't change the maximum of 20 parallel pipelines in a merge train,
which forced you to either overwhelm your runners or skip merge trains entirely.
Now you can configure the parallel pipeline limit per merge train to balance runner load and merge throughput.
You can set the limit per project or instance-wide.
Setting the limit to 1 means each merge request runs one at a time, against a clean target branch.

Thanks to [Norman Debald (@Modjo85)](https://gitlab.com/Modjo85) for this community contribution.

### Customize default merge request titles

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/merge_requests/title_templates.md), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/16080)

{{< /details >}}

In previous versions of GitLab, the default title for a new merge request came from the
source branch or first commit, and you couldn't enforce a consistent naming convention
across your project.

Now you can configure a default merge request title template per project. Templates
support variables for the source branch, target branch, first commit subject, linked
issue ID, issue title, and a human-readable version of the source branch name. For example, the template
`Resolve %{issue_id} "%{issue_title}"` produces titles like `Resolve 123 "Fix login bug"`.
You can still edit the title before creating the merge request.

### Secure webhooks with HMAC signing tokens

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/project/integrations/webhooks.md#signing-tokens), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/19367)

{{< /details >}}

The existing `X-Gitlab-Token` header sends a static secret in plain text,
making webhooks susceptible to interception and replay attacks.

You can now add a signing token to any webhook. GitLab uses
the signing token to compute an HMAC-SHA256 signature over:

- The unique webhook ID.
- The request timestamp.
- The webhook payload.

GitLab then sends the result in the `webhook-signature` header alongside
`webhook-id` and `webhook-timestamp` headers, following the
[Standard Webhooks](https://www.standardwebhooks.com/) specification.

You can recompute the signature to confirm requests genuinely came from GitLab
and that the payload has not been modified. By also validating the timestamp, you can reject replayed requests.

Thanks to [Van Anderson](https://gitlab.com/van.m.anderson) and
[Norman Debald](https://gitlab.com/Modjo85) for their community contributions!

### Cross-project pushes using CI/CD job tokens

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../ci/jobs/ci_job_token.md#allow-cross-project-git-push-requests-from-allowlisted-projects), [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/479907)

{{< /details >}}

In previous versions of GitLab, you could only use a CI/CD job token (`CI_JOB_TOKEN`) to push
to the same repository where the pipeline runs. Cross-project pushes required a personal access
token or deploy token.

You can now use a job token to push to another project when:

1. The target project opts in.
1. The user who starts the pipeline has at least the Developer role in the target project.

This feature is behind the `allow_push_to_allowlisted_projects` feature flag, disabled by default
in GitLab 19.0. Ask your administrator to enable it.

### Rapid Diffs for merge request reviews (Beta)

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/project/merge_requests/changes.md#rapid-diffs), [Related issue](https://gitlab.com/groups/gitlab-org/-/work_items/18457)

{{< /details >}}

In previous versions of GitLab, you would have to wait for the **Changes** tab to load all files before you could begin reviewing, which slowed down large reviews.

Now you can use Rapid Diffs to review merge requests with faster initial load, smoother
scrolling, and more responsive interactions across files. Rapid Diffs uses the same
technology that already powers the commits page.

Rapid Diffs is in beta. Some features from the classic diff experience aren't yet available. You can switch back at any time.

[Watch the overview video](https://www.youtube.com/watch?v=S-IzJnhoH6U) and share your
experience in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/596236).

### GitLab Runner 19.0

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 19.0 today! GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What's New

- [Runner instrumentation: Feature negotiation, OTLP export client, and first `job_execution` span](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39231)
- [Add configurable prepare stage timeout to runner configuration](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/26583)

#### Bug Fixes

- [Comprehensive fixes for `FF_SCRIPTS_TO_STEPS` feature flag implementation](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39403)
- [`SignatureDoesNotMatch` error when downloading S3 cache](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39402)
- [Runtime error when GitLab Runner runs in AWS with S3 cache](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39386)
- [Broken RPM S3 download links for `amd64`, `arm64`, `arm`, and `armhf` in GitLab Runner 18.9.0 and later](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39362)
- [Negative exit codes are reported incorrectly on Windows](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39292)
- [Incorrect Kubernetes executor service container naming documentation](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39235)
        
The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/19-0-stable/CHANGELOG.md).
