---
stage: Release Notes
group: Monthly Release
date: 2025-12-18
title: "GitLab 18.7 release notes"
description: "GitLab 18.7 released with Secret validity checks improved and generally available"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On December 18, 2025, GitLab 18.7 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: David Aniebo

We’re excited to recognize David Aniebo as our 18.7 Notable Contributor for his impactful contributions to GitLab
product planning capabilities and the [contributor platform](https://contributors.gitlab.com).

David’s work on [improving work item list functionality](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207549)
demonstrates his technical expertise and dedication to enhancing the user experience for GitLab planning features.
This contribution helps teams better organize and manage their work items, making project planning more efficient for
thousands of GitLab users.

Beyond code contributions, David has been a consistent supporter of the contributor platform, helping to improve the
experience for community contributors. His collaborative approach and responsiveness have earned praise from multiple
team members across different groups.

“David has done some fantastic work helping out with some Product Planning group efforts, and we are very thankful for
his contributions,” shared Nick Brandt, Engineering Manager for Product Planning.

Thank you, David, for your valuable contributions to GitLab and for being such a collaborative member of our community!
We look forward to your continued involvement.

## Primary features

### Secret validity checks improved and generally available

<!-- categories: Secret Detection -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/vulnerabilities/validity_check.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16890)

{{< /details >}}

When a valid secret is leaked in one of your repositories, you must react quickly.
To help you prioritize urgent threats, validity checks automatically verify whether leaked credentials can still be used.

In GitLab 18.7, we’ve improved:

- Vendor integrations: Integrated with Google Cloud, AWS, and Postman, along with existing support for GitLab tokens.
- Report filtering: Filter the Vulnerability Report by validity status (active, inactive, possibly active) to quickly triage and prioritize secret findings.
- Group-level API: Turn on validity checks across all projects in a group with a single API call and streamline rollout across your organization.

In this release, validity checks are generally available.

### Separate model selection for Agentic Chat and agents

<!-- categories: Model Personalization -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/gitlab_duo/model_selection.md#select-a-model-for-a-feature) | [Related issue](https://gitlab.com/groups/gitlab-org/-/work_items/19998)

{{< /details >}}

Separate models can now be selected for Agentic Chat and for all other agents for top-level groups or instances.
This provides more options for model selection for GitLab Duo Agent Platform.

### Improved GitLab Duo and SDLC trends dashboard

<!-- categories: DevOps Reports -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Add-ons: Duo Core, Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/analytics/duo_and_sdlc_trends.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/19629)

{{< /details >}}

The GitLab Duo and SDLC trends dashboard delivers improved analytics capabilities to measure the impact of GitLab Duo
on software delivery. The dashboard now provides 6-month trend analysis across GitLab Duo feature adoption, pipeline
performance, and common development metrics such as deployment frequency and mean time to merge.

You can now track code generation volumes and IDE or language trends for GitLab Duo Code Suggestions, and observe
as your teams adopt new GitLab Duo Agent Platform flows. Enhanced user-level metrics enable teams to gain deeper
insight into the key Duo features providing continuous value.

A new [endpoint for instance-level AI usage](../../api/graphql/reference/_index.md#aiinstanceusagedata)
is now available for instance administrators to extract all Duo data from either Postgres (3-month retention) or
ClickHouse.

Powered by the [ClickHouse integration](../../integration/clickhouse.md), this dashboard delivers sub-second query performance across millions of
data points. For self-managed instances, see improved recommendations and configuration guidance for
[ClickHouse integration](../../integration/clickhouse.md).

### Additional Planner Agent features available in beta

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Add-ons: Duo Core, Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/duo_agent_platform/agents/foundational_agents/planner.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/576618)

{{< /details >}}

The Planner Agent now includes create and edit features in beta! The Planner Agent is a foundational agent built
to support product managers directly in GitLab. Use the Planner Agent to create, edit, and analyze GitLab work items.

Instead of manually chasing updates, prioritizing work, or summarizing planning data, the Planner Agent helps you
analyze backlogs, apply frameworks like RICE or MoSCoW, and surface what truly needs your attention. It’s like
having a proactive teammate who understands your planning workflow and works with you to make better, more efficient
decisions.

Please provide your feedback in [issue 576622](https://gitlab.com/gitlab-org/gitlab/-/issues/576622).

### Dynamic input options in CI/CD pipelines

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../ci/inputs/_index.md#define-conditional-input-options-with-specinputsrules) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/18546)

{{< /details >}}

You can set up your CI/CD pipelines to make use of dynamic input selection when creating new pipelines through the
intuitive web interface.

Now, with dynamic input options, you can configure your pipelines so that input selection options update dynamically
based on previous selections. For example, when you select an input in one dropdown list, it automatically populates
a list of related input options in a second dropdown list.

With CI/CD inputs, you can:

- Trigger pipelines with pre-configured inputs, reducing errors and streamlining deployments.
- Enable your users to select different inputs than the defaults from dropdown menus.
- Now have cascading dropdown lists where options dynamically update based on previous selections.

This dynamic capability enables you to create more intelligent, context-aware input configurations that guide you
through the pipeline creation process, reducing errors and ensuring only valid combinations of inputs are selected.

### SAST False Positive Detection with AI (Beta)

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Add-ons: Duo Core, Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/application_security/vulnerabilities/false_positive_detection.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/18977)

{{< /details >}}

Security teams often spend significant time investigating SAST findings that turn out to be false positives,
diverting attention from genuine security risks.

In GitLab 18.7, we’re introducing AI-powered SAST False Positive Detection to help teams focus on the
vulnerabilities that matter. When a security scan runs, GitLab Duo automatically analyzes each Critical and High
severity SAST vulnerability to determine the likelihood that it’s a false positive.

The AI assessment appears directly in the vulnerability report, giving security engineers immediate context to
make faster, more confident triage decisions.

Key capabilities include:

- Automatic analysis: False positive detection runs automatically after each security scan with no manual triggering required.
- Manual trigger option: Users can manually trigger false positive detection for individual vulnerabilities on the vulnerability details page for on-demand analysis.
- Focused on high-impact findings: Scoped to Critical and High severity vulnerabilities to maximize signal-to-noise improvement.
- Contextual AI reasoning: Each assessment includes an explanation of why the finding may or may not be a true positive, based on code context and vulnerability characteristics.
- Seamless workflow integration: Results surface directly in the vulnerability report alongside existing severity, status, and remediation information.

This feature is available as a free beta for Ultimate customers and must be enabled in your group or project settings.
We welcome your feedback in [issue 583697](https://gitlab.com/gitlab-org/gitlab/-/issues/583697).

### New security dashboards enabled by default

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/security_dashboard/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/20213)

{{< /details >}}

The new security dashboards have been updated and modernized. The dashboards were previously available on GitLab.com,
and are now enabled by default on GitLab Dedicated and GitLab Self-Managed.

The new features include:

- A vulnerabilities over time chart that supports:
  - Filtering based on project or report type.
  - Grouping by report type and severity.
  - Direct links to vulnerabilities in the vulnerability report.
- A risk score module that calculates the estimated risk for a group or project based on a GitLab algorithm.

Please note that using the new dashboard requires Elasticsearch.

### Instance setting to control publishing of components to the CI/CD Catalog

<!-- categories: Pipeline Composition, Component Catalog -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../administration/settings/continuous_integration.md#restrict-cicd-catalog-publishing) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/582044)

{{< /details >}}

Administrators of GitLab Self-Managed and GitLab Dedicated can now restrict which projects are allowed to publish
components to the CI/CD Catalog. This new setting enables organizations to maintain a curated, trusted CI/CD Catalog
by controlling what components can be published.

Administrators can now specify an allowlist of projects authorized to publish components. When the allowlist is
populated with projects, only those projects can publish components. This prevents unauthorized or unapproved
components from cluttering the list of published components and ensures all components meet organizational standards
and security requirements.

This addresses a key governance challenge for enterprise customers who want to maintain control over their CI/CD
component ecosystem while enabling their teams to discover and reuse approved components.

## Agentic Core

### Advanced search available for both merge request descriptions and comments

<!-- categories: Global Search -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/search/advanced_search.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/572590)

{{< /details >}}

Advanced search now returns matching results from both merge request descriptions and comments. Previously, users
had to search merge request descriptions and comments separately.

This improvement provides a more streamlined and comprehensive search workflow for GitLab merge requests.

### Support for `AGENTS.md` with GitLab Duo Chat (Agentic) in IDEs

<!-- categories: Editor Extensions -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Add-ons: Duo Core, Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/duo_agent_platform/customize/agents_md.md)

{{< /details >}}

GitLab Duo Chat now supports the `AGENTS.md` specification, an emerging standard for providing context and
instructions to AI coding assistants.

Unlike custom rules that are only available to GitLab Duo, `AGENTS.md` files are also available for other AI
coding tools to use. This makes your build commands, testing instructions, code style guidelines, and
project-specific context available to any AI tool that supports the specification.

GitLab Duo Chat in your IDE automatically applies available instructions from `AGENTS.md` files in your repository,
set at the user or workspace level. For monorepos, you can place `AGENTS.md` files in subdirectories to provide
tailored instructions for different components.

### AI agent and flow versioning

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/duo_agent_platform/ai_catalog.md#agent-and-flow-versions) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/20022)

{{< /details >}}

When you enable an agent or flow from the AI Catalog in your project, GitLab now pins it to a specific version.

This means your AI-powered workflows stay stable and predictable even as catalog items evolve, so you can test and
validate new versions before you upgrade.

### AI gateway timeout setting

<!-- categories: Model Personalization -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated
- Add-ons: Duo Enterprise
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-timeout-for-the-ai-gateway) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/579183)

{{< /details >}}

For GitLab Duo Self-Hosted, you can now configure a timeout value for requests to self-hosted models.

This value can range from 60 to 600 seconds.

### Report agents and flows to administrators

<!-- categories: AI Catalog -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/report_abuse.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/578591)

{{< /details >}}

You can now report agents and flows to instance administrators when you encounter problematic content. Submit an
abuse report that includes your feedback, and an administrator can choose to hide or delete the harmful item.

Use this feature to keep your agents and flows safe across your entire organization.

### Configure foundational agent availability

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/duo_agent_platform/agents/foundational_agents/_index.md#turn-foundational-agents-on-or-off) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/583815)

{{< /details >}}

You can now control which foundational agents are available in your top-level group or instance.

Turn all foundational agents on or off by default, or toggle individual agents to align with your organization’s
security and governance policies.

## Scale and Deployments

### Enhanced active trial experience for Self-Managed

<!-- categories: Acquisition -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../subscriptions/free_trials.md#view-remaining-trial-period-days)

{{< /details >}}

GitLab Self-Managed users on an Ultimate trial can now access their active trial status, remaining days, accessible
features, and expiration notifications from the left sidebar.

These enhancements help eliminate confusion about trial duration and make it easier to evaluate paid features before purchase.

## Unified DevOps and Security

### Advanced vulnerability management available in Self-Managed and Dedicated environments

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/vulnerability_report/_index.md#advanced-vulnerability-management) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/532703)

{{< /details >}}

Advanced vulnerability management is available to all Ultimate customers and includes the following features:

- Grouping data by OWASP 2021 categories in the vulnerability report for a project or group.
- Filtering based on a vulnerability identifier in the vulnerability report for a project or group.
- Filtering based on the reachability value in the vulnerability report for a project or group.
- Filtering by policy violation bypass reason.

### Data Analyst foundational agent powered by GLQL (Beta)

<!-- categories: Custom Dashboards Foundation -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Add-ons: Duo Core, Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/duo_agent_platform/agents/foundational_agents/data_analyst.md)

{{< /details >}}

The Data Analyst Agent is a specialized AI assistant that helps you query, visualize, and surface data across the
GitLab platform. It uses GitLab Query Language (GLQL) to retrieve and analyze data, then provides clear, actionable
insights about your projects.

You can find example prompts and use cases in the documentation.

This agent is currently in beta status, so please share your thoughts in the
[feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/574028) to help us improve and provide insight into
where you’d like to see this go next.

### Filter and comment on compliance violations

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/compliance/compliance_center/compliance_violations_report.md)

{{< /details >}}

The compliance violations report provides a centralized view of all compliance violations across your
organization’s projects. The report displays comprehensive details about control violations, related audit events,
and enables teams to track violation statuses effectively.

In GitLab 18.7, we’ve introduced powerful filtering capabilities to help you quickly find the violations that
matter most. You can now filter by:

- Status
- Project
- Control

Teams can now also collaborate directly on resolving violations through comments. Within the violation record
itself, teams can:

- Tag team members for investigation
- Discuss remediation approaches
- Document findings—all within the violation record itself.

Together, these features evolve the compliance violations report into a dynamic collaboration platform,
enabling organizations to efficiently discover, analyze, and resolve compliance violations in their groups and
projects.

### Compliance framework controls show accurate scan status

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/compliance/compliance_frameworks/_index.md#gitlab-compliance-controls)

{{< /details >}}

GitLab compliance controls can be used in compliance frameworks. Controls are checks against the configuration or
behavior of projects that are assigned to a compliance framework.

Previously, controls related to scanners (for example, checking if SAST is enabled) required your projects to have
a passing pipeline in the default branch before the compliance centre displayed the success or failure status of your
controls.

In GitLab 18.7, we have changed this behavior to show whether your controls have succeeded or failed based solely on
scan completion, regardless of the overall pipeline status. This helps ease confusion because the compliance status
of your controls reflects whether security scans ran and completed, not whether the entire pipeline passed.

### Accessibility improvements for heading anchor links

<!-- categories: Markdown -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/markdown.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/463385)

{{< /details >}}

Heading anchor links now announce with the same text as their corresponding heading, improving the experience for
screen reader users. The links also appear after the heading text, providing a cleaner visual presentation.

These changes make it easier for all users to understand and navigate to specific sections of documentation,
issues, and other content.

### Warn mode in merge request approval policies

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#warn-mode) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/19595)

{{< /details >}}

Security teams can now use warn mode to test and validate the impact of security policies before applying
enforcement or to roll out soft gates for accelerating your security program. Warn mode helps to reduce developer
friction during security policy rollouts, while continuing to ensure detected vulnerabilities are addressed.

When you create or edit a
[merge request approval policy](../../user/application_security/policies/merge_request_approval_policies.md),
you can now choose between `warn` or `enforce` enforcement options.

Policies in warn mode generate informative bot comments without blocking merge requests. Optional approvers can
be designated as points of contact for policy questions. This approach enables security teams to assess policy
impact and build developer trust through transparent, gradual policy adoption.

Clear indicators in merge requests tell users when policies are in `warn` or `enforce` mode, and audit events
track policy violations and dismissals for compliance reporting. Developers can bypass scan finding and license
policy violations by providing a reasoning for the policy dismissal, creating a collaborative feedback loop between
developers and security teams for more effective policy enablement.

When policy violations are detected on a project’s default branch, policies identify vulnerabilities that violate
the policy in the vulnerability reports for projects and groups. The dependency list for projects also displays
badges that indicate license compliance policy violations.

Additionally, you can use the API to query a filtered list of policy violations on the default branch in a project.

### Service accounts available during trials on GitLab.com

<!-- categories: System Access -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/profile/service_accounts.md)

{{< /details >}}

Service accounts are now available during trial periods, allowing you to test automation and integration workflows
before purchasing.

### GitLab Runner 18.7

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 18.7 today!

GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab
instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service
included with GitLab.

#### What’s New

- [Configurable taskscaler reservation throttling](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39161)
- [Enable `FF_TIMESTAMPS` by default](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38378)

#### Bug Fixes

- [Shell executor fails on existing Git repository if a relative `builds_dir` is specified](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39150)
- [Authentication failure in GitLab Runner 18.6.0 on subsequent pipeline runs (SSH executor)](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39140)
- [Authentication failure in GitLab Runner 18.6.0 on subsequent pipeline runs (shell executor)](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39123)
- [Docker 29 API compatibility issues](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39129)
- [Variables that reference file variables no longer work in GitLab Runner 18.6.0 with the shell executor](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39124)
- [GitLab Runner now supports Windows 11 2025 (25H2)](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39050)
- [ECR credential helper is not working with the Docker Autoscaler executor](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38365)
- [Job timeouts now properly enforced in GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27040)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-7-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-7-stable/CHANGELOG.md).md).

### View child pipeline reports in merge requests

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../ci/pipelines/downstream_pipelines.md#view-child-pipeline-reports-in-merge-requests) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/18311)

{{< /details >}}

Teams using parent-child CI/CD pipelines previously had to navigate through multiple pipeline pages to check test
results, code quality reports, and infrastructure changes, disrupting their merge request review workflow.

You can now view and download all reports in a unified view, including unit tests, code quality checks, Terraform
plans, and custom metrics, without leaving the merge request.

This eliminates context switching and accelerates merge request velocity, giving teams the ability to deliver
features faster without compromising quality.

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.7)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.7)
- [UI improvements](https://papercuts.gitlab.com/?milestone=18.7)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
