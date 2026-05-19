---
stage: Release Notes
group: Monthly Release
date: 2025-07-17
title: "GitLab 18.2 release notes"
description: "GitLab 18.2 released with Duo Agent Platform in the IDE (Beta)"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On July 17, 2025, GitLab 18.2 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Markus Siebert

[Markus Siebert](https://gitlab.com/m-s-db), a Platform Engineer at DB Systel GmbH, is leading the community effort to bring native AWS Secrets Manager support to GitLab CI/CD, addressing a critical enterprise need for secure secret management in pipelines. With an impressive 172 documented activities in just 6 weeks, Markus has been working tirelessly on implementing both AWS Secrets Manager and AWS Systems Manager Parameter Store support through multiple merge requests including [Add functionality to retrieve secrest from AWS Secrets Manager](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5587), [Add GitLab CI config entry for AWS SSM ParameterStore](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191803), and [Documentation for AWS Secrets Manager](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192378).

“Markus’s work directly enables GitLab users in AWS environments to securely manage their CI/CD secrets without relying on third-party tools or custom scripts. This is especially valuable for enterprise users who have standardized on AWS services,” says [Aditya Tiwari](https://gitlab.com/atiwari71), Senior Backend Engineer, Secure at GitLab, who nominated Markus.

Markus’s dedication to seeing this feature through - from initial implementation to documentation - while actively maintaining and improving merge requests based on feedback, exemplifies the best of community contribution and demonstrates the power of community-driven development in making GitLab better for AWS users.

This contribution was delivered through the [GitLab Co-Create Program](https://about.gitlab.com/community/co-create/).

Thanks to Markus for your valuable contributions to GitLab!

## Primary features

### Duo Agent Platform in the IDE (Beta)

<!-- categories: Editor Extensions -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Core, Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/duo_agent_platform/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/556038)

{{< /details >}}

The Duo Agent Platform brings agentic chat and agent flows directly into VS Code and JetBrains IDEs, enabling natural conversation-based interaction with your codebase and GitLab projects.

Agentic chat is designed for quick, conversational tasks like creating and editing files, searching across your codebase with pattern matching and grep, and getting immediate answers about your code.
Agent flows handle larger implementations and comprehensive planning, taking high-level ideas from concept to architecture while accessing GitLab resources including issues, merge requests, commits, CI/CD pipelines, and security vulnerabilities.
Both provide intelligent search capabilities for documentation, code patterns, and project discovery to help you accomplish everything from quick edits to complex project analysis.

The platform also supports Model Context Protocol (MCP) for connecting to external data sources and tools, allowing AI features to leverage context beyond GitLab.

Learn more in our blog [GitLab Duo Agent Platform Public Beta: Next-gen AI orchestration and more](https://about.gitlab.com/blog/gitlab-duo-agent-platform-public-beta/).

To get started, see the [Duo Agent Platform documentation](../../user/duo_agent_platform/_index.md),
[VS Code setup guide](../../user/gitlab_duo_chat/agentic_chat.md#use-gitlab-duo-chat-in-vs-code),
and [JetBrains setup guide](../../user/gitlab_duo_chat/agentic_chat.md#use-gitlab-duo-chat-in-jetbrains-ides).

### Custom workflow statuses for issues and tasks

<!-- categories: Team Planning -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/work_items/status.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/14794)

{{< /details >}}

Move beyond the basic open/closed system with configurable status that lets you track work items through
your team’s actual workflow stages.

Instead of relying on labels, you can now define custom statuses that accurately
reflect your process. With configurable statuses, you can:

- **Define custom workflows** that match your team’s actual process.
- **Replace workflow labels** with proper statuses that are easier to find, update, and report on.
- **Clarify completion outcomes** beyond closing an issue using “Done” or “Canceled”.
- **Filter and report accurately** on work item status for better project insights.
- **Use status in issue boards** with automatic updates when issues move between columns.
- **Bulk update status** across multiple work items for efficient workflow management.
- **Track dependencies** with status visibility for linked work items.

Custom workflow statuses also support **quick actions in comments** and automatically syncs with GitLab’s
open/closed system.

Help us improve this feature by sharing your thoughts and suggestions in our
[feedback issue](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/35235).

### New merge request homepage

<!-- categories: Code Review Workflow -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/project/merge_requests/homepage.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13448)

{{< /details >}}

Managing code reviews across multiple projects can be overwhelming when you’re juggling dozens of merge requests
as both an author and reviewer.

The new merge request homepage transforms how you navigate your review workload
by intelligently prioritizing what needs your attention right now, with two powerful viewing modes:

- **Workflow view** organizes merge requests by their review state, grouping work by its stage in the code review workflow.
- **Role view** groups your merge requests by whether you’re the author or reviewer, giving you a clear separation of responsibilities.

The **Active** tab shows merge requests requiring attention, **Merged** displays recently completed work,
and **Search** provides comprehensive filtering capabilities.

The new homepage also expands your visibility by combining both authored and assigned merge requests,
ensuring you never miss work that’s been delegated to you.

### Improve security with immutable container tags (Beta)

<!-- categories: Container Registry -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../user/packages/container_registry/immutable_container_tags.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/15139)

{{< /details >}}

Container registries are critical infrastructure for modern DevSecOps teams.
However, even with protected container tags, organizations still face a challenge:
After a tag is created, users with sufficient permissions can alter it.
This creates risks for teams that rely on specific tagged versions of container images for production stability.
Any modification—even by authorized users—can introduce unintended changes or compromise deployment integrity.

With immutable container tags, you can protect container images from unintended changes.
After a tag is created that matches an immutable rule, no one can modify the container image.
You can now:

- Create up to 5 total protection rules per project (combining both protected and immutable rules) using RE2 regex patterns.
- Protect critical tags like latest, semantic versions (for example, v1.0.0), or release candidates from any modification.
- Ensure immutable tags are automatically excluded from cleanup policies.

Immutable container tags require the next-generation container registry, which is enabled by default on GitLab.com.
For GitLab Self-Managed instances, you must enable the [metadata database](../../administration/packages/container_registry_metadata_database.md)
to use immutable container tags.

### Group and project controls for Premium and Ultimate with GitLab Duo

<!-- categories: Code Suggestions, Duo Chat -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/gitlab_duo/turn_on_off.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/551895)

{{< /details >}}

GitLab Premium and Ultimate users can now change the availability of Code Suggestions and GitLab Duo Chat in the IDE for groups and projects. Previously, you could change the availability for the instance or top-level group only.

### New group overview compliance dashboard

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/compliance/compliance_center/compliance_overview_dashboard.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13909)

{{< /details >}}

The compliance center is the central location for compliance teams to manage their compliance status
reporting, violations reporting, and compliance frameworks for their group.

The new group overview compliance dashboard gives compliance managers an aggregated view on compliance
information across all of the projects in a group. This first iteration displays the following information:

- % of projects covered by a certain compliance framework.
- % of failed requirements for all projects in a group.
- % of failed controls for all projects in a group.
- The specific frameworks that require ‘attention’.

With this new group overview, compliance managers now have a single unified view that
provides them with a clear high-level picture, of their compliance posture.

### Map workspace Kubernetes agents for the instance

<!-- categories: Workspaces -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../user/workspace/gitlab_agent_configuration.md#allow-a-cluster-agent-for-workspaces-on-the-instance) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16485)

{{< /details >}}

GitLab administrators can now map enabled workspace Kubernetes agents for the instance. Users can then create workspaces from any group or project in that instance.

This significantly increases workspace scalability by allowing organizations to provision workspace Kubernetes agents once, and make those agents accessible to all current and future projects across the entire instance.

### Download a PDF export of security reports

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/security_dashboard/_index.md#export-as-pdf) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16989)

{{< /details >}}

To communicate the state and progress of your vulnerability management efforts to other stakeholders,
you can now export the security dashboard for each project or group as a PDF document.

### Centralized Security Policy Management (Beta)

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/enforcement/compliance_and_security_policy_groups.md#set-up-centralized-security-policy-management) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/17392)

{{< /details >}}

In large organizations where compliance is critical, teams often struggle with fragmented policies
scattered across multiple projects and groups. Without centralized visibility, ensuring consistent
enforcement becomes a time-consuming challenge while increasing compliance risk.

Centralized security policy management introduces a unified approach to creating, managing,
and enforcing security policies across your entire GitLab organization through a single designated
compliance and security policy (CSP) group. This allows security teams to:

- **Define policies once and apply everywhere**: Create instance-wide security policies once through the CSP and automatically enforce the policies across all groups and projects.
- **Configure business unit policies**: Top-level groups can configure their own distinct set of policies while inheriting organization policies from the CSP group.
- **Ensure adherence to principle of least privilege**: Establish a central policy management layer enforced for the instance.

This beta release establishes the foundational framework for centralized policy management,
with support for all existing security policy types, configurable for groups, projects, or instance.

## Agentic Core

### Mistral Small now available for GitLab Duo Self-Hosted

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/18202)

{{< /details >}}

You can now use Mistral Small on GitLab Duo Self-Hosted. This model is available on GitLab Self-Managed instances,
and is the first fully compatible open source model for GitLab Duo Chat and Code Suggestions on GitLab Duo Self-Hosted.

## Scale and Deployments

### Administrators can reassign contributions without user confirmation

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/523259)

{{< /details >}}

Administrators can now reassign contributions from placeholder users to active users without user confirmation.
This feature addresses a key challenge for larger organizations where the process stalled when users did not check their emails to approve reassignments.

On GitLab instances where user impersonation is enabled, administrators can maintain data integrity while streamlining user management workflows.
Users still receive notification emails after the reassignment is complete, ensuring transparency throughout the process.

### Reassign from placeholder users to inactive users

<!-- categories: Importers -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/523260)

{{< /details >}}

Previously, administrators could reassign contributions and memberships from placeholder users to active users only.

On GitLab Self-Managed, administrators can now also reassign contributions and memberships from placeholder users to inactive users.
This feature permits you to preserve the contribution history and membership information of blocked, banned, or deactivated users on your GitLab instance.

Administrators must first enable this setting and, when enabled, this setting streamlines user management by
skipping user confirmation during reassignment while maintaining secure access control.

## Unified DevOps and Security

### Container Scanning support for multi-architecture container images

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/container_scanning/_index.md#available-cicd-variables) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/543144)

{{< /details >}}

Container Scanning now ships with Linux Arm64 container image variants. When running
on a Linux Arm64 runner, the analyzer will no longer require emulation, resulting in a faster
analysis. In addition, you can now scan multi-architecture images by
setting the `TRIVY_PLATFORM` environment variable to the platform you want to scan.

### Improved archive file support for Container Scanning

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/container_scanning/_index.md#scanning-archive-formats) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/501077)

{{< /details >}}

GitLab 18.2 brings improved archive file scanning support to Container Scanning.
If a vulnerability in a particular package is found in multiple images, you now see a vulnerability attributed to each scanned image.

### Static reachability support for JavaScript

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/dependency_scanning/static_reachability.md#supported-languages-and-package-managers) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/502334)

{{< /details >}}

Composition Analysis now supports Static Reachability for JavaScript libraries.
You can use the data produced by static reachability as part of your triage and remediation
decision making. Static reachability data can also be used with EPSS, KEV, and CVSS scores
to provide a more focused view of your vulnerabilities.

### Improved support for verifying successful DAST login

<!-- categories: DAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/dast/browser/configuration/variables.md#authentication) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/435942)

{{< /details >}}

Previously, the `DAST_AUTH_SUCCESS_IF_AT_URL` variable required an exact URL match to verify successful authentication. This worked well for applications with static landing pages, but posed difficulties for applications where post-login URLs contain dynamic elements for each login.

Now, you can use wildcard patterns in the `DAST_AUTH_SUCCESS_IF_AT_URL` variable to match dynamic URL patterns. This enhancement provides the flexibility needed to verify authentication success even when the exact URL changes between sessions.

### DAST support for time-based one-time password MFA

<!-- categories: DAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/dast/browser/configuration/authentication.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13633)

{{< /details >}}

Dynamic Analysis now supports time-based one-time password (TOTP) multi-factor authentication.

You can run DAST scans on projects with TOTP MFA enabled to ensure comprehensive security testing.
This enhancement delivers more accurate scan results by testing applications in configurations that mirror
production environments where MFA is deployed.

### Deactivate streaming to an audit streaming destination

<!-- categories: Audit Events -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../administration/compliance/audit_event_streaming.md#activate-or-deactivate-streaming-destinations) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/537096)

{{< /details >}}

Previously, there was no way to temporarily deactivate streaming to an audit streaming destination. You might
want to do this for a number of reasons, including to troubleshoot stream connectivity or to make changes to
configuration without deleting the configuration and starting again.

With GitLab 18.2, we’ve added the ability to toggle an audit stream as active or inactive. When the audit stream
is inactive, audit events are no longer streamed to the chosen destination. When reactivated, audit events are
again streamed to the chosen destination.

### Filter functionality for all audit streaming destinations

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/compliance/audit_event_streaming.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/524939)

{{< /details >}}

Previously, certain audit streaming destinations did not have all of the available filtering capability.

We now support filter functionality for all destinations via the UI, including the ability to filter:

- By audit event type.
- By groups or projects.

This change also means that audit event destinations such as AWS and GCP can now filter through audit events.

### Configure epic display preferences

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/group/epics/manage_epics.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/393559)

{{< /details >}}

You now have full control over which metadata appears when you view your list of
work items, making it easier to focus on the information that matters most to you.

Previously, all metadata fields were always visible, which could make scanning through work
items overwhelming. Now you can customize your view by turning on or off specific fields
like assignees, labels, dates, and milestones.

### Open epics in a drawer or the full page on the Epics page

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/group/epics/manage_epics.md#open-epics-in-a-drawer) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/536620)

{{< /details >}}

You can now choose how epics open from the list page with a new toggle that switches between drawer view and
full-page navigation.

Use the drawer to quickly review epic details while maintaining context of your epic list,
or open the full page when you need more screen space for detailed editing and comprehensive navigation.

### Assign [milestones](../../user/project/milestones/_index.md) to epics for enhanced long-term planning

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/project/milestones/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/329)

{{< /details >}}

You can now assign [milestones](../../user/project/milestones/_index.md) directly to epics, creating a natural planning cascade from strategic initiatives down to execution. This enhancement helps you align longer-term planning cadences, like quarterly planning or SAFe program increments, with epics. At the same time, you can keep iterations focused on development sprints.

With this clear hierarchy in place, you can reduce administrative overhead and gain better visibility into how your strategic initiatives progress against organizational timeframes.

### Assign epics to team members

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/group/epics/manage_epics.md#assignees) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/4231)

{{< /details >}}

You can now assign epics to individuals, making it clear who is responsible for overseeing strategic initiatives. Epic assignees help you identify ownership at the portfolio level, enabling faster decision-making and clearer accountability for long-term objectives. Teams can quickly see who to contact about epic progress, dependencies, or scope changes.

### Sorting and pagination for GLQL views

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/glql/_index.md#presentation-syntax) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/502701)

{{< /details >}}

This release introduces enhanced sorting and pagination for GLQL views, making it easier to work with large datasets.

You can now sort by key fields including due dates, health status, and popularity to quickly find the most relevant items. The new “Load more” pagination system provides better control over data loading, replacing overwhelming full-page results with manageable chunks that load on demand.

These improvements help teams efficiently navigate complex project data and focus on what matters most at any given moment.

### Work item references and editor improvements for GitLab Flavored Markdown

<!-- categories: Markdown -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/markdown.md#gitlab-specific-references) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/7654)

{{< /details >}}

You can now reference issues, epics, and work items using a unified `[work_item:123]` syntax in GitLab Flavored Markdown. This new syntax works alongside existing reference formats like `#123` for issues and `&123` for epics, and supports cross-project references with `[work_item:namespace/project/123]`.

The plain text editor also includes a new [preference to maintain cursor indentation](../../user/profile/preferences.md#maintain-cursor-indentation) when you press Enter, making it easier to write structured content like nested lists and code blocks.

### Vulnerability ID added to vulnerability report CSV export

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/vulnerability_report/_index.md#exporting) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/18033)

{{< /details >}}

Previously, the CSV export of the vulnerability report did not include vulnerability IDs.
You can now find the ID of each vulnerability listed in the CSV export.

### Reachability filter in the vulnerability report

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/vulnerability_report/_index.md#filtering-vulnerabilities) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/543346)

{{< /details >}}

Users can now filter data in the vulnerability report to include only reachable vulnerabilities.
Reachable vulnerabilities represent vulnerabilities that are both:

- On the Common Vulnerabilities and Exposures (CVE) list.
- Part of a library that is explicitly imported.

### Vulnerability GraphQL API returns additional information

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../api/graphql/reference/_index.md#vulnerability) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/468913)

{{< /details >}}

You can now use the GraphQL API to determine the pipeline when the vulnerability was
introduced and when it was last detected. The Vulnerability GraphQL API now includes:

- `initialDetectedPipeline`: Use to retrieve additional commit information about when the vulnerability was introduced, such as the author’s user name.
- `latestDetectedPipeline`: Use to retrieve additional commit information about when the vulnerability was removed, such as the commit SHA.

### Source branch pattern exceptions for approval policies

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#source-branch-exceptions) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/18113)

{{< /details >}}

Previously, teams using GitFlow often faced approval deadlocks when merging `release/*` branches to `main`,
as most contributors had already participated in release development and then couldn’t serve as approvers.

Branch pattern exceptions in merge request approval policies solve this by automatically bypassing approval
requirements for specific source-target branch combinations.
Configure strict approvals for feature-to-main merges while allowing streamlined release-to-main workflows.

**Key capabilities:**

- **Pattern-based configuration:** Define source branch patterns like `release/*` or `hotfix/*` that bypass approval requirements
- **Seamless integration:** Branch exceptions integrate directly into existing merge request approval policies and are configurable through the UI or `policy.yml` file.

This eliminates the need for complex workarounds while preserving the security benefits of merge request
approval policies for standard development workflows.

### Display dependency paths

<!-- categories: Dependency Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/dependency_list/_index.md#dependency-paths) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16815)

{{< /details >}}

Previously, it was difficult to determine whether a dependency was a direct dependency, or a transient dependency imported by a descendant of the dependency.

You can now determine whether a library is primarily or transitively imported using the new dependency paths feature. You can find dependency paths on the project and group dependency list as well as in the vulnerability details. This capability allows developers to determine the most efficient path to a fix depending on how the library is imported.

### Credentials inventory now includes service account tokens

<!-- categories: System Access -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../administration/credentials_inventory.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/421954)

{{< /details >}}

GitLab now supports service account tokens in the credentials inventory, giving you better visibility and control over the various authentication methods used across your software supply chain. The credentials inventory provides a complete picture of credentials used across your organization.

### Security Inventory for comprehensive asset visibility now in beta

<!-- categories: Security Asset Inventories -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/security_inventory/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16484)

{{< /details >}}

AppSec teams need comprehensive visibility into their organization’s security posture across all assets. Previously, GitLab’s security workflows focused primarily on project-level scanner configuration and project-level vulnerabilities, making it difficult to understand coverage gaps and make efficient, risk-based prioritization decisions.

Security Inventory provides a centralized view of the security posture across your GitLab instance, enabling AppSec teams to:

- Get complete visibility into security coverage across projects and groups
- Identify assets that lack security scanning or have configuration gaps
- Make informed, risk-based decisions about where to focus security efforts
- Track security posture improvements over time

This feature helps bridge the gap between individual project security and organization-wide security strategy, giving you the asset inventory foundation needed for effective security program management.

### Custom admin role in beta

<!-- categories: Permissions -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed
- Links: [Documentation](../../user/custom_roles/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/15069)

{{< /details >}}

The custom admin role brings granular permissions to the Admin Area for GitLab Self-Managed and GitLab Dedicated instances. Instead of granting full access, administrators can now create specialized roles that access only the specific functions needed by users. This feature helps organizations implement the principle of least privilege for administrative functions, reduce security risks from overprivileged access, and improve operational efficiency.

We’re actively seeking community feedback on this feature. If you have questions, want to share your implementation experience, or would like to engage directly with our team about potential improvements, please visit our [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/509376).

### Trigger jobs can mirror the downstream pipeline status

<!-- categories: Pipeline Composition -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](../../ci/yaml/_index.md#triggerstrategy) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/431882)

{{< /details >}}

Previously, trigger jobs using `strategy:depend` had limitations when dealing with complex pipeline states such as manual jobs,
blocked pipelines, or retried pipelines with changing statuses during execution.
This could make it seem like the downstream pipeline was actively running, when it was actually blocked on a manual job.

The new `strategy:mirror` keyword provides more nuanced status reporting by mirroring
the exact real-time status of the downstream pipeline. Statuses include intermediate states like
`running`, `manual`, `blocked`, and `canceled` . This gives teams complete visibility into
the current state of their downstream pipeline without breaking the existing workflow.

### GitLab Runner 18.2

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Dedicated
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 18.2 today! GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### Bug Fixes

- [Runners fail in FIPS mode after you upgrade to GitLab Runner 18.1.0](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38890)
- [Unable to start job pods with `FF_USE_DUMB_INIT_WITH_KUBERNETES_EXECUTOR`](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/241)
- [The `ubi-fips` image is not the default helper image flavor for GitLab Runner FIPS](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38273)
- [Runners remain offline for an extended period after you disable GitLab maintenance mode](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29181)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-2-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-2-stable/CHANGELOG.md).md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.2)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.2)
- [UI improvements](https://papercuts.gitlab.com/?milestone=18.2)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
