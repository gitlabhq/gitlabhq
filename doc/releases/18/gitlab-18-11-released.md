---
stage: Release Notes
group: Monthly Release
date: 2026-04-16
title: "GitLab 18.11 release notes"
description: "GitLab 18.11 released with Vulnerability resolution generally available on GitLab Duo Agent Platform"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On April 16, 2026, GitLab 18.11 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Rinku C

We are excited to recognize [Rinku C](https://gitlab.com/therealrinku), a Level 4 contributor with over 80 merged improvements across GitLab since joining in September 2025.

Nominated by [Arianna Haradon](https://gitlab.com/aharadon), Senior Fullstack Engineer on the Developer Relations team, this award celebrates his sustained and meaningful impact over time. Rinku has strengthened security-sensitive flows by [requiring scopes on project and group access token creation forms](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219236), and improved everyday GitLab experience with numerous updates like [next/previous navigation in job logs](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217618), [excluding empty searches from recent](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/223570), and [reducing file tree clutter](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224628) through thoughtful UI refinements that make common workflows clearer and easier to navigate. Rinku tackles the work that often goes unclaimed, keeping the codebase healthy and compounding to meaningful, lasting value. Thank you for your contributions!

## Primary features

### Vulnerability resolution generally available on GitLab Duo Agent Platform

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/vulnerabilities/agentic_vulnerability_resolution.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/585626)

{{< /details >}}

Agentic SAST Vulnerability Resolution is now generally available in GitLab 18.11 on the GitLab Duo Agent Platform. It runs as part of your SAST scan, after SAST false positive detection runs, or when manually triggered for individual SAST vulnerabilities.

Agentic SAST Vulnerability Resolution:

- Autonomously analyzes the finding and reasons through the surrounding code context.
- Automatically creates a ready-to-review merge request with proposed code fixes for critical and high severity SAST vulnerabilities.
- Provides quality assessments so reviewers can quickly gauge confidence in the proposed remediation.
- Allows you to apply resolutions directly from vulnerability details pages.

We welcome your feedback in [issue 585626](https://gitlab.com/gitlab-org/gitlab/-/issues/585626).

### GitLab Data Analyst Foundational Agent now generally available

<!-- categories: Custom Dashboards Foundation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/duo_agent_platform/agents/foundational_agents/data_analyst.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/20337)

{{< /details >}}

The Data Analyst Agent is a specialized AI chat assistant that helps you query, visualize, and surface data across the GitLab platform.

Backed by the [GitLab Query Language (GLQL)](../../user/glql/_index.md), the Data Analyst can retrieve and analyze data about each of the supported [data sources](../../user/glql/data_sources/_index.md), and provide clear, actionable insights about your software development health and engineering efficiency.

These insights can be visualized directly in the agent output and embedded directly into issues and epics for further evaluation.

### CI Expert Agent launches in beta

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/duo_agent_platform/agents/foundational_agents/ci_expert_agent.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/587460)

{{< /details >}}

The AI-powered CI Expert Agent is now available in beta. This agent helps teams get from GitLab code to a first working pipeline without starting from a blank `.gitlab-ci.yml`.

Using GitLab Duo Agent Platform, the agent inspects your repository, asks a few guided questions about your build and test process, and generates a ready-to-run pipeline you can review, edit, and commit.

This turns pipeline creation into a conversational, context-aware experience, while still letting you take full control of the YAML after you’re ready to evolve and optimize your configuration.

### Automated vulnerability severity overrides

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/policies/vulnerability_management_policy.md#severity-override-policies) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/15839)

{{< /details >}}

Default vulnerability severities don’t always reflect your organization’s actual risk. A critical CVE in an internal-only service might not warrant the same urgency as one in a public-facing application, yet teams spend significant time triaging findings that don’t match their risk model.

Vulnerability management policies can now automatically adjust the severity of vulnerabilities based on conditions like CVE ID, CWE ID, file path, and directory. When applied, the policy updates the severity of any vulnerability that matches the criteria on the default branch. Manual overrides still take precedence, and all changes are logged in the vulnerability’s history and audit events.

This reduces triage work and ensures developers focus on the findings that matter most to your business.

### Create Service Account in subgroups and projects

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/profile/service_accounts.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/17754)

{{< /details >}}

Teams can now create service accounts in subgroups and projects. Instead of broad, top-level group bots, you can attach a dedicated service account to a single subgroup or project and manage its access like any other member of that namespace. Group and subgroup service accounts can be invited to the group where they were created or to any descendant subgroups and projects. Project service accounts are limited to their own project.

### Service Accounts available on GitLab Free

<!-- categories: System Access -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/profile/service_accounts.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/20439)

{{< /details >}}

Service accounts are now available on GitLab.com in all tiers. Previously limited to
Premium and Ultimate, service accounts let you perform automated actions, access data, or run
scheduled processes without tying credentials to individual team members. They’re commonly used in
pipelines and third-party integrations where credentials must stay stable regardless of team
changes. On GitLab Free, you can create up to 100 service accounts per top-level group, including those
created in subgroups or projects.

### Fine-grained permissions for personal access tokens now available (Beta)

<!-- categories: Permissions -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../auth/tokens/fine_grained_access_tokens.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/18555)

{{< /details >}}

Fine-grained personal access tokens (PATs) are now available in beta. Unlike legacy PATs, which grant access to every project and group you belong to, fine-grained PATs let you limit each token to specific resources and actions. This reduces the potential impact of a leaked or compromised token.

Your existing PATs continue to work as before, and you can still create legacy PATs without fine-grained permissions.

This beta release covers approximately 75% of the GitLab REST API. Full REST API coverage, GraphQL enforcement, and administrator policy controls are planned for the GA release.

To share feedback, see [epic 18555](https://gitlab.com/groups/gitlab-org/-/epics/18555).

### Top CWE chart in security dashboards

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/security_dashboard/_index.md#top-10-cwes) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/17422)

{{< /details >}}

The top CWE chart is now available on the new security dashboards. Identify the most common CWEs across your project or instance to identify opportunities for training, improvement, or program optimization. Users can group the dashboard data by severity and filter the dashboard by severity, project, and report type.

### Deploy Gitaly on Kubernetes

<!-- categories: Gitaly -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../administration/gitaly/kubernetes.md) | [Related issue](https://gitlab.com/groups/gitlab-org/-/work_items/6127)

{{< /details >}}

You can now deploy Gitaly on Kubernetes as a fully supported deployment method. This gives you greater flexibility in managing your GitLab infrastructure by using Kubernetes orchestration capabilities for scaling, high availability, and resource management. Previously, Kubernetes deployments required custom configurations and weren’t officially supported, making it difficult to maintain reliable Gitaly deployments in containerized environments.

### Reconfigure inputs when manually running MR pipelines

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../ci/pipelines/merge_request_pipelines.md#run-a-merge-request-pipeline-with-custom-inputs) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/547861)

{{< /details >}}

A powerful aspect of CI/CD inputs is that you can manually run new pipelines with new values for runtime customization.
This was not available in merge request (MR) pipelines before, but in this release you can now customize inputs in MR pipelines too.

After you configure inputs for MR pipelines, you can optionally modify those inputs and change the pipeline behavior any time you run a new pipeline for a merge request.

## Agentic Core

### Default model for GitLab Duo Agentic Chat updated from Haiku 4.5 to Sonnet 4.6

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/duo_agent_platform/model_selection.md#default-models) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/595042)

{{< /details >}}

We’ve made an update to improve your Agentic Chat experience in GitLab. The default model for Agentic Chat was upgraded from Claude Haiku 4.5 to Claude Sonnet 4.6, hosted on Vertex AI. Claude Sonnet 4.6 offers improved reasoning and response quality but uses a higher GitLab Credit multiplier than Haiku 4.5.

You can select an alternative model, including Haiku, using the [model selection](../../user/duo_agent_platform/model_selection.md#select-a-model-for-a-feature) setting. If you’ve already selected a specific model, your choice is preserved. This update only affects the default and will not override any existing selections. For information about credit multipliers by model, see the [GitLab Credits documentation](../../subscriptions/gitlab_credits.md).

### Configure tools in custom flow definitions

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/duo_agent_platform/flows/custom.md#create-a-flow) | [Related issue](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/work_items/2147)

{{< /details >}}

You can now configure tool options and parameter values directly in your custom flow definitions to supersede the LLM default values. This gives you more precise, consistent control over how tools behave within a custom flow, making it easier to enforce guardrails and specific parameter values across that flow.

### Mistral AI now supported as a self-hosted model in GitLab Duo Agent Platform

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/supported_llm_serving_platforms.md#cloud-hosted-model-deployments) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/587872)

{{< /details >}}

GitLab Duo Agent Platform now supports Mistral AI as an LLM platform for self-hosted model deployments. GitLab Self-Managed customers can configure Mistral AI alongside existing supported platforms, including AWS Bedrock, Google Vertex AI, Azure OpenAI, Anthropic, and OpenAI. This gives teams more choice in how they run AI-powered features.

## Scale and Deployments

### View historical months in GitLab Credits dashboard

<!-- categories: Consumables Cost Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../subscriptions/gitlab_credits.md#view-the-gitlab-credits-dashboard) | [Related issue](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/15910)

{{< /details >}}

The GitLab Credits dashboard in Customers Portal now supports historical month navigation. Billing managers can browse past billing months to review daily usage trends, compare consumption patterns across periods, and reconcile usage with invoices. Previously, the dashboard only displayed the current billing month. With this improvement, administrators can make more informed decisions about credit allocation and forecast future needs based on historical data.

### Set subscription-level usage cap for GitLab Credits

<!-- categories: Consumables Cost Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../subscriptions/gitlab_credits.md#usage-control-status)

{{< /details >}}

Administrators can now set a monthly usage cap for On-Demand Credits at the subscription level. When total on-demand credit consumption reaches the configured cap, GitLab Duo Agent Platform access is automatically suspended for all users on that subscription until the next billing period begins or the admin adjusts the cap. This setting gives organizations a hard guardrail against unexpected overage bills, removing a key barrier to broader Agent Platform rollout. Caps reset automatically each billing period, and administrators receive an email notification when the cap is reached.

### Set per-user GitLab Credits cap

<!-- categories: Consumables Cost Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../subscriptions/gitlab_credits.md#usage-control-status)

{{< /details >}}

Administrators can now set an optional per-user usage cap for GitLab Credits per billing period. When an individual user’s total credit consumption reaches the configured limit, GitLab Duo Agent Platform access is suspended only for that user, while other users continue unaffected. This prevents any single user from consuming a disproportionate share of the organization’s credit pool, and gives administrators fine-grained control over usage distribution. Per-user usage caps work alongside subscription-level usage caps, by applying the cap that is reached first.

### Linux package improvements

<!-- categories: Omnibus Package -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](https://docs.gitlab.com/omnibus/settings/database/#upgrade-packaged-postgresql-server) | [Related issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/9734)

{{< /details >}}

In GitLab 19.0, the minimum-supported version of PostgreSQL will be version 17. To prepare for this change, on instances that don’t use [PostgreSQL Cluster](../../administration/postgresql/replication_and_failover.md), upgrades to GitLab 18.11 will attempt to automatically upgrade PostgreSQL to version 17.

If you use [PostgreSQL Cluster](../../administration/postgresql/replication_and_failover.md) or [opt out of this automated upgrade](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades), you must [manually upgrade to PostgreSQL 17](https://docs.gitlab.com/omnibus/settings/database/#upgrade-packaged-postgresql-server) to be able to upgrade to GitLab 19.0.

### Backup and Restore Support for Container Registry Metadata Database

<!-- categories: Backup/Restore of GitLab instances -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/backup_restore/_index.md) | [Related issue](https://gitlab.com/groups/gitlab-com/gl-infra/data-access/durability/-/work_items/45)

{{< /details >}}

The GitLab `backup` Rake task for Linux package installations and the `[backup-utility](https://docs.gitlab.com/charts/backup-restore/)`
for Cloud Native (Helm) installations now support the [container registry metadata database](../../administration/packages/container_registry_metadata_database.md).
You can now back up references to blobs, manifests, tags, and other data stored in the metadata database,
enabling recovery in the event of malicious or accidental data corruption.

### New navigation experience for groups in Explore

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/group/_index.md#explore-groups) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/13791)

{{< /details >}}

We’re excited to announce improvements to the groups list in **Explore**, making it easier to discover groups across your GitLab instance.
The redesigned interface introduces a tabbed layout with two views:

- **Active** tab: Browse all accessible groups, helping you discover relevant communities and projects.
- **Inactive** tab: View archived groups and groups pending deletion for visibility into group lifecycle status.

These changes streamline group discovery and provide clearer visibility into which groups are available to join.

### Asynchronous transfer of projects

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/group/manage.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/20521)

{{< /details >}}

In previous versions of GitLab, transfers of large groups and projects could timeout. As we move groups and projects to use a unified state model for operations such as transfer, archive, and deletion, you get more consistent behavior, better visibility into state history and audit details, and fewer timeouts, specifically, for long running transfer operations through asynchronous processing.

## Unified DevOps and Security

### ClickHouse is generally available for Self-Managed deployments

<!-- categories: DevOps Reports -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../integration/clickhouse.md#set-up-clickhouse) | [Related issue](https://gitlab.com/groups/gitlab-org/architecture/gitlab-data-analytics/-/work_items/51)

{{< /details >}}

For GitLab Self-Managed instances, we now have improved recommendations and configuration guidance for the GitLab [ClickHouse integration](../../integration/clickhouse.md). Customers have options to bring their own cluster, or use the ClickHouse Cloud (recommended) setup option. This integration powers multiple dashboards and unlocks access to various API endpoints within the analytics space.

This scalable, high-performance database is part of the larger architectural improvements planned for the GitLab analytics infrastructure.

### Enhanced GitLab Duo Agent Platform analytics on Duo and SDLC trends dashboard

<!-- categories: DevOps Reports -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/analytics/duo_and_sdlc_trends.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/20540)

{{< /details >}}

The GitLab Duo and SDLC trends dashboard delivers improved analytics capabilities to measure the impact of GitLab Duo
on software delivery. The dashboard now includes new single stat panels for monthly Agent Platform unique users and Agentic Chat sessions.
Additionally, metrics previously displayed as a % usage compared to seat assignments have been updated to strictly report usage counts.
This change resolves the [issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/590326) where counts were missing Agent Platform usage controlled under the new usage billing model.

### GLQL now has access to projects, pipelines, and jobs data sources

<!-- categories: Custom Dashboards Foundation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/glql/data_sources/_index.md)

{{< /details >}}

The [GitLab Query Language (GLQL)](../../user/glql/_index.md) now has access to three new data sources: projects, pipelines, and jobs.
These new data sources are also available as embedded views, letting teams surface pipeline results, job statuses,
and project overviews directly in wikis, issue and merge request descriptions, and repository Markdown files.
GLQL also powers the [Data Analyst Agent](../../user/duo_agent_platform/agents/foundational_agents/data_analyst.md).

With these new types, the agent can inspect CI/CD job results, debug failures, and provide detailed overviews of pipeline execution,
as well as provide an accurate overview of projects in a namespace.

### Dependency resolution for Maven and Python SBOM scanning

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#dependency-resolution) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/20461)

{{< /details >}}

GitLab dependency scanning using SBOM now supports generating a dependency graph automatically for Maven and Python projects.
Previously, dependency scanning required users to provide a lock file or a graph file to get an accurate dependency analysis.
Now, when a lock file or graph file is not available, the analyzer automatically attempts to generate one.
This improvement makes it easier for Maven and Python projects to enable dependency scanning without requiring a lock file.

### Incremental scanning for Advanced SAST

<!-- categories: SAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/sast/gitlab_advanced_sast.md#incremental-scanning) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/20508)

{{< /details >}}

You can now perform incremental scans that analyze only changed parts of the codebase with GitLab Advanced SAST, significantly reducing scan times compared to full repository scans. This feature is a further iteration of diff-based scanning, because it produces full results for codebases.

By scanning just the code that has changed rather than the entire codebase, your teams can integrate security testing more seamlessly into their development workflow without sacrificing speed or adding friction.

### Unverified vulnerabilities (Beta)

<!-- categories: SAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/sast/gitlab_advanced_sast.md#report-unverified-vulnerabilities) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/15649)

{{< /details >}}

Advanced SAST can now surface unverified vulnerabilities (findings that cannot be fully traced from source to sink) directly in the vulnerability report. Enable this feature if you have a higher tolerance for false positives over false negatives.

This feature is in beta status. Provide feedback in [issue 596512](https://gitlab.com/gitlab-org/gitlab/-/work_items/596512).

### Kubernetes 1.35 support

<!-- categories: Deployment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/584225)

{{< /details >}}

GitLab now fully supports Kubernetes version 1.35. If you want to deploy your applications to Kubernetes
and access all features, upgrade your connected clusters to the most recent version.
For more information, see [supported Kubernetes versions for GitLab features](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features).

### Prefer mode for the container registry metadata database

<!-- categories: Container Registry -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../administration/packages/container_registry_metadata_database.md#prefer-mode) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/595480)

{{< /details >}}

You can now set the container registry metadata database to `prefer` mode, a new configuration option alongside the existing `true` and `false` values. In prefer mode, the registry automatically detects whether it should use the metadata database or fall back to legacy storage based on the current state of your installation.

If your registry has existing filesystem metadata that has not been imported to the database, the registry continues to use legacy storage until you complete a metadata import. If the database is already in use, or on a fresh installation, the registry uses the database directly.

In a later release, `prefer` mode will become the default for new Linux package installations. Existing installations will not be affected. For more information, see [issue 595480](https://gitlab.com/gitlab-org/gitlab/-/work_items/595480).

### Package protection rules now support Terraform modules

<!-- categories: Package Registry -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/packages/package_registry/package_protection_rules.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/592761)

{{< /details >}}

Teams publishing Terraform modules through the built-in GitLab Terraform module registry had
no way to restrict who could push new module versions. Package protection rules supported
several package formats but did not include `terraform_module`, leaving infrastructure
teams without a project-level push control.

You can now create package protection rules scoped to `terraform_module`, restricting push
access based on minimum role. Support is available in the UI package type dropdown, the
REST API, the GraphQL API, and the GitLab Terraform provider resource.

### Release evidence now includes packages

<!-- categories: Package Registry, Release Evidence -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/project/releases/release_evidence.md#include-packages-as-release-evidence) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/283995)

{{< /details >}}

When creating a GitLab Release, packages published to the package registry were not
automatically associated with it. Teams had to manually construct package URLs and attach
them as release links through the API or pipeline scripts, adding friction and risk of
incomplete release records.

GitLab now automatically includes packages in release evidence when the package version
matches the release tag. This creates a verifiable, auditable link between your release and
its associated packages without any manual steps, keeping source code, artifacts, and
packages together in one complete release snapshot.

### Wiki sidebar toggle repositioned for easier access

<!-- categories: Wiki -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/project/wiki/_index.md#sidebar) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/580569)

{{< /details >}}

The wiki sidebar toggle is now positioned on the left side, directly next to the sidebar
it controls.

When the sidebar is collapsed, the toggle remains visible as a floating
control so you can reopen it without scrolling back to the top of the page.

### Sticky action bar on wiki pages

<!-- categories: Wiki -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/project/wiki/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/590255)

{{< /details >}}

The action bar on wiki pages is now sticky, so it remains visible as you scroll
through a page. Previously, you had to scroll back to the top to access actions
like editing, viewing page history, or managing templates. Now the page title
and key actions, including Edit, New page, Templates, Page history, and more,
stay within reach no matter how far down the page you are.

### Epic weights

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/work_items/weight.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/12273)

{{< /details >}}

Epics now support weights, making it easier to estimate and prioritize large-scale
initiatives during planning.

Before breaking down an epic into child issues, you can assign a preliminary weight
to represent your initial estimate.
As you decompose the epic, the weight automatically updates to reflect the rolled-up total
from all child issues.
This is consistent with how weight rollup works for issues and tasks.

On the epic detail page, you can see both the preliminary weight and the rolled-up weight
from child issues, giving you the insight needed to refine estimates over time.

### Block merge requests with high exploitability risk

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#vulnerability_attributes-object) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16311)

{{< /details >}}

Previously, merge request (MR) approval policies could block MRs based on vulnerability severity, but not all vulnerabilities carry the same risk. CVSS severity alone doesn’t tell you whether a CVE is being exploited or how likely exploitation is. This leads to noisy approval policies and wasted time for developers and security teams.

You can now configure MR approval policies using Known Exploited Vulnerability (KEV) and Exploit Prediction Scoring System (EPSS) data. Block or require approval when a finding is in the KEV catalog (actively exploited in the wild), or when its EPSS score is above a threshold. Policy violations in the MR include KEV and EPSS context so developers understand why the security gate was triggered.

This gives security teams precise control over which findings block or warn, reduces alert fatigue, and keeps enforcement aligned with the current threat landscape.

### Assign CVSS 4.0 scores to vulnerabilities

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/vulnerabilities/severities.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/18697)

{{< /details >}}

CVSS 4.0 is the latest version of the industry standard used to assess and rate the severity of a vulnerability. You can now view and access CVSS 4.0 score in the UI, including the vulnerability details page and the vulnerability report. You can also query the score using the API.

### Improved row interaction in the vulnerability report

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/vulnerability_report/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/561414)

{{< /details >}}

Previously, you had to select the row description to navigate to a vulnerability details page from the vulnerability report.

You can now select anywhere in the row to go directly to its details. Link styling for the vulnerability description and file location only appears when you hover over each link, and keyboard navigation has been improved.

These changes make the vulnerability report more intuitive and accessible.

### Export a security dashboard as a PDF

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/security_dashboard/_index.md#export-as-pdf) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/18203)

{{< /details >}}

You can export the security dashboard as a PDF for use in reports and presentations. The export captures the current state of all of the charts and panels in the dashboard, including any active filters.

### SAST scanning in security configuration profiles

<!-- categories: Security Testing Configuration -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/configuration/security_configuration_profiles.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/19951)

{{< /details >}}

In GitLab 18.9, we introduced security configuration profiles with the **Secret Detection - Default** profile. In GitLab 18.11, profiles now extend to SAST with the **Static Application Security Testing (SAST) - Default** profile, giving you a unified control surface to apply standardized static analysis coverage across all your projects without touching a single CI/CD configuration file.

The profile activates two scan triggers:

- **Merge Request Pipelines**: Automatically runs a SAST scan each time new commits are pushed to a branch with an open merge request. Results only include new vulnerabilities introduced by the merge request.
- **Branch Pipelines (default only)**: Runs automatically when changes are merged or pushed to the default branch, providing a complete view of your default branch’s SAST posture.

### Security attribute filters in group security dashboards

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/security_dashboard/_index.md#filter-the-entire-dashboard) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/18201)

{{< /details >}}

You can now filter the results in a group security dashboard based on the security attributes that you have applied to the projects in that group.

The available security attributes include the following:

- Business impact
- Application
- Business unit
- Internet exposure
- Location

### Security Manager role (Beta)

<!-- categories: Permissions -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/permissions.md)

{{< /details >}}

The Security Manager role is now available as a beta feature, providing a new default set of permissions designed specifically for security professionals. Security teams no longer need Developer or Maintainer roles to access security features, eliminating over-privileging concerns while maintaining separation of duties.

Users with the Security Manager role have the following access:

- **Vulnerability management**: View, triage, and manage vulnerabilities across groups and projects, including vulnerability reports and security dashboards.
- **Security inventory**: View a group’s security inventory to understand scanner coverage across all projects.
- **Security configuration profiles**: View security configuration profiles for a group.
- **Compliance tools**: View audit events, compliance center, compliance frameworks, and dependency lists for a group or project.
- **Secret push protection**: Enable secret push protection for a group.
- **On-demand DAST**: Create and run on-demand DAST scans for a group.

To get started, go to a group and select **Manage** > **Members** to invite and assign members to the Security Manager role.

### Identifier list popover in the vulnerability report

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/vulnerability_report/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/564939)

{{< /details >}}

The vulnerability report now shows the primary CVE identifier as a clickable link in each row. When multiple identifiers exist,
a `"+N more"` popover lists all of the identifiers. Each identifier in the list links to its external reference
(for example, in the CVE, CWE, or WASC databases) so you can quickly access more details without leaving the report.

### GitLab Runner 18.11

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 18.11 today! GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s New

- [Create `concrete` helper image with bundled dependencies](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39286)
- [Read the job router feature flag from the runner configuration instead of an environment variable](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39280)

#### Bug Fixes

- [Incorrect runner binary path after refactoring](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39329)
- [Pipeline hangs on cache operations](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39279)
- [The `docker-machine` binary in GitLab Runner 18.9.0 references CVE-2025-68121](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39276)
- [Runner silently falls back to job payload credentials when credential helper binary is missing from `DOCKER_AUTH_CONFIG`](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39201)
- [`CONCURRENT_PROJECT_ID `not unique in different jobs, which causes a conflict in the builds directory](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/38307)
- [Artifact upload fails with timeout awaiting response headers](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/37220)
- [User-defined `after_script` executes after failed `pre_build_script` and bypasses `post_build_script`](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/3116)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-11-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-11-stable/CHANGELOG.md).md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.11)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.11)
- [UI improvements](https://papercuts.gitlab.com/?milestone=18.11)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
