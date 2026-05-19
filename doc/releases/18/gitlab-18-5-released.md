---
stage: Release Notes
group: Monthly Release
date: 2025-10-16
title: "GitLab 18.5 release notes"
description: "GitLab 18.5 released with GitLab Duo Planner, a specialized agent and Product Manager team member (beta)"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On October 16, 2025, GitLab 18.5 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Jose Gabriel Companioni Benitez

In his blog post [“How GitLab Can Boost Your Professional Career”](https://compacompila.com/posts/gitlab-open-source-community/),
Jose shares: “For me, the main advantage that GitLab offers, from a professional development
point of view, is that it is open source.” He adds, “For GitLab, it’s important
that anyone can contribute, and for that reason, they have taken the contributor
onboarding process very seriously.”

Jose’s journey from first-time contributor in September to Notable Contributor
in October demonstrates the power of the GitLab collaborative community. Through
active participation in community office hours, Discord discussions, and pairing
sessions, Jose found a supportive environment that helped him quickly grow to a
level 3 contributor with diverse contributions spanning [documentation](https://gitlab.com/gitlab-org/cli/-/merge_requests/2392),
[code](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/2690), and community support.

The GitLab community offers a welcoming space where contributors
support one another and grow together. Whether you’re just starting your open-source
journey or looking to deepen your skills, our community is here to help you succeed.

To learn more about contributing, see the [GitLab Contributor Platform](https://contributors.gitlab.com/).

Thank you, Jose, for your outstanding work! 🚀

## Primary features

### GitLab Duo Planner, a specialized agent and Product Manager team member (beta)

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com
- Add-ons: Duo Core, Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/duo_agent_platform/agents/foundational_agents/planner.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/576618)

{{< /details >}}

Collaborate with GitLab Duo Planner, a GitLab Duo agent built to support product managers directly within GitLab.
Instead of manually chasing updates, prioritizing work, or summarizing planning data, GitLab Duo Planner helps you analyze backlogs,
apply frameworks like RICE or MoSCoW, and surface what truly needs your attention.
It’s like having a proactive teammate who understands your planning workflow and works with you to make better, faster decisions.
This feature is currently in beta. Please provide feedback in [issue 576622](https://gitlab.com/gitlab-org/gitlab/-/issues/576622).

### GitLab Security Analyst Agent for Duo Agent Catalog (beta)

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com
- Add-ons: Duo Core, Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/duo_agent_platform/agents/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/19659)

{{< /details >}}

Agents in GitLab Duo Agent Platform can be used to perform tasks and answer complex questions
within GitLab. Users can either create custom agents to accomplish specific tasks, like creating merge requests or reviewing code,
or discover GitLab agents using the AI Catalog.

In GitLab 18.5, we are releasing the GitLab Security Analyst Agent as a beta feature, available in the AI Catalog. To use the GitLab Security Analyst Agent in specific projects, select and enable the agent in GitLab Duo Agentic Chat. The agent can perform the following tasks:

- List all vulnerabilities in a given project.
- Get detailed vulnerability information, including CVE data and EPSS scores.
- Confirm and dismiss vulnerabilities.
- Update vulnerability severity levels.
- Revert vulnerability status back to `detected`.
- Create vulnerability issues, or link vulnerabilities to existing issues.

With the GitLab Security Analyst Agent, users can perform tedious security workflows through AI-powered automation and intelligent analysis, enabling engineers to focus on genuine threats while the GitLab Security Analyst Agent handles repetitive assessment and documentation. Please note that the GitLab Security Analyst Agent using GitLab Duo Chat is only available for Ultimate customers with the GitLab Duo add-on.

This feature is in beta, and we welcome your feedback in [issue 576916](https://gitlab.com/gitlab-org/gitlab/-/issues/576916).

### Maven virtual registry now available in beta

<!-- categories: Virtual Registry -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/packages/virtual_registry/maven/_index.md#manage-virtual-registries) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/14137)

{{< /details >}}

GitLab 18.5 introduces a comprehensive web-based interface for Maven virtual registry management. Previously, platform engineers could only configure and manage virtual registries through API calls, which makes routine maintenance tasks cumbersome and requires specialized knowledge.

This web-based approach significantly reduces operational overhead for platform engineering teams. Common tasks, like clearing stale cache entries, reordering upstreams for performance optimization, and testing connectivity are now point-and-click operations. Development teams gain better visibility into their dependency configuration, enabling more informed discussions about build performance and security policies.

The Maven virtual registry remains in beta for GitLab Premium and Ultimate customers. Current beta limitations include a maximum of 20 virtual registries per top-level group and 20 upstreams per virtual registry.

We invite enterprise customers to participate in the Maven virtual registry beta program to help shape the final release. Please consider sharing feedback and suggestions in [issue 543045](https://gitlab.com/gitlab-org/gitlab/-/issues/543045).

### Pick up where you left off on the new personal homepage

<!-- categories: Navigation -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../tutorials/personal_homepage/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16657)

{{< /details >}}

You can now access a new personal homepage that consolidates all your important GitLab activities in one place, making it easier to pick up where you left off. The homepage brings together your to-do items, assigned issues, merge requests, review requests, and recently viewed content, helping you navigate GitLab’s large surface area and stay focused on what matters the most to you.

### GPT-5 now available as a model option for GitLab Duo Agentic Chat

<!-- categories: Model Personalization -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Add-ons: Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/gitlab_duo_chat/agentic_chat.md#select-a-model) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/19124)

{{< /details >}}

OpenAI GPT-5 is now available as a GitLab AI Vendor model when selecting a model for GitLab Duo Agent Platform. When configured by Owners of a top-level group on GitLab.com and instance Administrators on Self-Managed and Dedicated, end-users can select to use GPT-5 with GitLab Duo features. Top-level owners and administrators can continue to set organization-wide model preferences through namespace or instance settings, or allow end-user to choose from all available GitLab AI Vendor models.

To get started using GPT-5, select your preferred model from the model dropdown list in GitLab Duo Chat.

### Instance-wide compliance and security policy management

<!-- categories: Compliance Management, Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../security/compliance_security_policy_management.md)

{{< /details >}}

Enterprise users want to manage their [compliance frameworks](../../user/compliance/compliance_frameworks/centralized_compliance_frameworks.md) and [security policies](../../user/application_security/policies/enforcement/compliance_and_security_policy_groups.md) across multiple top-level groups.
This is often the case when all groups in an instance:

- Share the same compliance frameworks. For example, when all projects in a group must adhere to the ISO 27001 standard.
- Enforce similar security policies. For example, when all groups share the same pipeline execution policy.

With GitLab 18.5, we introduce compliance and security policy groups to centralize the management of security policies and compliance frameworks on an instance for GitLab Self-Managed
and Dedicated instances. With this release, you can now create, configure, and allocate compliance frameworks and
security policies from a single top-level group and enforce them across all of the other top-level groups across your instance.

With a compliance and security policy group, you have a single source of truth
where you can manage and edit your compliance frameworks and security policies.
Security and compliance users within the group can then apply compliance frameworks and security policies to all the projects across the instance.

Compliance and security policy groups make it easier to manage and enforce your compliance and security
needs across your instance. However, groups still retain the ability to create their own compliance
frameworks and security policies to address specific situations or workflows that can arise in those groups.

This feature is for GitLab Self-Managed and Dedicated customers. GitLab.com customers can
manage frameworks and policies centrally within a single top-level group or namespace using security policy projects.

Learn more about compliance and security policy groups for [compliance frameworks](../../user/compliance/compliance_frameworks/centralized_compliance_frameworks.md) and [security policies](../../user/application_security/policies/enforcement/compliance_and_security_policy_groups.md).

### DAST authentication scripts

<!-- categories: DAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/dast/browser/configuration/authentication_scripts.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/17018)

{{< /details >}}

You can now add scripts to your CI/CD configurations to automate DAST authentication workflows. Authentication scripts enable automating complex authentication flows, including support for time-based, one-time passwords (OTP MFA).

This enhancement helps your team maintain critical security controls while conducting thorough, automated security scans. By supporting real-world authentication scenarios, scripts reduce friction and ensure accurate security assessments of production software.

## Agentic Core

### Additional triggers for CLI agents

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../user/duo_agent_platform/triggers/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/567787)

{{< /details >}}

You can now trigger CLI agents using additional events to give you more flexibility and control over where and when your agents take action across your projects. Along with the existing **mention** trigger, you can use:

- **Assign**: Trigger agents when a merge request or issue is assigned.
- **Assign reviewer**: Trigger agents when a reviewer is added to a merge request.

### GitLab Duo Agent Platform for GitLab Duo Self-Hosted now in beta

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/558083)

{{< /details >}}

GitLab Duo Agent Platform is now in beta for GitLab Duo Self-Hosted. This feature is available to all Self-Managed GitLab Duo Enterprise customers. Self-Managed instance administrators using AWS Bedrock or Azure OpenAI can configure Anthropic Claude or OpenAI GPT models for use with GitLab Duo Agent Platform. Self-Hosted administrators can also configure

[compatible models](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models)

to use with GitLab Duo Agent Platform.

### Codestral now supported for GitLab Duo Chat (Classic)

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/550266)

{{< /details >}}

You can now use Mistral Codestral on

GitLab Duo Self-Hosted

for classic Duo Chat. This model is supported for GitLab Duo Self-Hosted customers on GitLab Self-Managed instances.

### GPT OSS Models compatible with GitLab Duo Agent Platform for GitLab Duo Self-Hosted

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/19348)

{{< /details >}}

You can now use GPT OSS models on GitLab Duo Agent Platform with GitLab Duo Self-Hosted.

## Scale and Deployments

### Enhanced **Admin** area groups list

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../administration/admin_area.md#administering-groups) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/17783)

{{< /details >}}

We’ve upgraded the **Admin** area groups list to provide a more consistent experience for GitLab administrators:

- Delayed deletion protection: Group deletions now follow the same safe deletion flow used throughout GitLab, preventing accidental data loss.
- Faster interactions: Filter, sort, and paginate groups without page reloads for a more responsive experience.
- Consistent interface: The groups list now matches the look and behavior of other group lists across GitLab.

This update brings the administrator experience in line with GitLab design standards, and adds important safety features to protect your data. Future enhancements to group management will automatically appear in all group lists throughout the platform.

### Updated navigation experience for groups

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/group/_index.md#view-a-group) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/13790)

{{< /details >}}

We’ve made changes to the group overview list to deliver a more consistent and efficient experience across GitLab.
These improvements make it easier to navigate your groups and projects while providing more valuable information at a glance:

- Richer project information: Projects now display stars, forks, issues, merge requests, and relevant dates, giving you a complete activity overview at a glance.
- Streamlined actions: Edit or delete groups and projects directly from the overview using the actions menu. Archived and pending deletion items appear in the **Inactive** tab.
- Consistent experience: The group overview now matches the look and behavior of other group and project lists throughout GitLab for a more intuitive experience.

These enhancements save time by putting more information and actions at your fingertips. This update also lays the groundwork for future features like bulk editing and advanced filtering options.

### Improved inactive item management for groups and projects

<!-- categories: Groups & Projects -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/project/working_with_projects.md#view-inactive-projects) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/526211)

{{< /details >}}

The **Inactive** tab now consistently displays all inactive items in one unified location across GitLab. This includes archived projects, projects pending deletion, and groups pending deletion.
This tab is available on the group overview page, as well as in group and project lists throughout **Your work**, **Explore**, and the **Admin** area.
All users with the appropriate permissions can view inactive items, while only group owners and project owners and maintainers can take further actions on them.
As part of this update, a new `active` parameter is now available in both the Projects and Groups REST APIs, and GraphQL APIs.

Managing inactive content is a critical part of maintaining a GitLab instance.
This update makes it easier to find and recover content that was archived or is pending deletion, allowing you to maintain better control over your GitLab resources while reducing the risk of accidentally losing valuable work.
The clear separation of active from inactive content also provides a more focused search experience when navigating through groups and projects across all areas of GitLab.

## Unified DevOps and Security

### New vulnerability management features in GitLab Duo Agentic Chat

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Add-ons: Duo Core, Duo Pro, Duo Enterprise
- Links: [Documentation](../../user/gitlab_duo_chat/agentic_chat.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/19639)

{{< /details >}}

GitLab Duo Agentic Chat is an enhanced version of GitLab Duo Chat. It searches,
retrieves, and combines information from multiple sources across your GitLab projects to
provide more thorough and relevant answers. A few of its use cases include
the ability to search through projects, read and list files, and autonomously create and change
files based on the prompt provided to GitLab Duo Chat.

In GitLab 18.5, the Agentic Chat use case expands to include managing
vulnerabilities from your security scanners. By adding vulnerability management tools to
Agentic Chat, this transforms tedious security workflows through AI-powered automation and intelligent analysis,
enabling security professionals to efficiently triage, manage, and remediate vulnerabilities through natural language commands.
This eliminates hours of manual clicking through vulnerability dashboards and streamlining complex bulk operations that previously required custom scripts or tedious manual work.

With the new vulnerability management tools added to GitLab Duo Chat, Ultimate users with GitLab Duo can perform
the following:

- List all vulnerabilities in a given project.
- Get detailed vulnerability information, including CVE data and EPSS scores.
- Confirm and dismiss vulnerabilities.
- Update vulnerability severity levels.
- Revert vulnerability status back to `detected`.
- Create vulnerability issues, or link vulnerabilities to existing issues.

These tools transform security workflows from reactive manual triage into intelligent remediation,
letting engineers focus on genuine threats while AI handles repetitive assessment and documentation. Vulnerability management using GitLab Duo Chat is only available for Ultimate customers with the GitLab Duo add-on.

### C/C++ support for Advanced SAST

<!-- categories: SAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/sast/advanced_sast_cpp.md)

{{< /details >}}

We have added beta support for C/C++ to GitLab Advanced SAST.

To use this new cross-file, cross-function scanning support, [enable C/C++ support](../../user/application_security/sast/advanced_sast_cpp.md).

We welcome feedback on this feature. If you have any questions, comments, or would like to engage with our team, please see this [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/575671).

### Secret validity checks is in beta

<!-- categories: Secret Detection -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/vulnerabilities/validity_check.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16927)

{{< /details >}}

Pipeline secret detection alerts you to exposed credentials, like passwords or API keys, in your projects. However, until GitLab 18.5, you had to manually check whether each detection represented an active token. This could make effectively triaging detections difficult and time consuming.

Now that validity checks is in beta, enable it to display the status of detected GitLab secrets. Active secrets can be used to impersonate legitimate activity, so you should rotate them as soon as possible. To watch validity checks in action, see the [validity checks playlist](https://www.youtube.com/playlist?list=PL05JrBw4t0Ko8uOgubcYqmTTMGs0zWQRt).

### Increased rule coverage for secret push protection and pipeline secret detection

<!-- categories: Secret Detection -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/secret_detection/detected_secrets.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/573973)

{{< /details >}}

New rules have been added to the GitLab pipeline secret detection. Some existing rules have also been updated
to improve quality and reduce false positives. These changes are released in [version 7.15.0](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v7.15.0) of the secrets analyzer.

### Customizable detection logic for Advanced SAST

<!-- categories: SAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/sast/customize_rulesets.md)

{{< /details >}}

You can now create custom security detection rules tailored to your organization’s specific security requirements and coding patterns with GitLab Advanced SAST. This feature enables your security teams to define custom vulnerability patterns beyond the predefined ruleset, allowing them to detect application-specific security issues.

For more information, see [Customize rulesets](../../user/application_security/sast/customize_rulesets.md).

### Advanced SAST diff-based scanning in merge requests

<!-- categories: SAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Links: [Documentation](../../user/application_security/sast/gitlab_advanced_sast.md#diff-based-scanning)

{{< /details >}}

You can now perform diff-based scans that analyze only the code changes in a merge request with GitLab Advanced SAST, significantly reducing scan times compared to full repository scans. By scanning just the Git diff rather than the entire codebase, your teams can integrate security testing more seamlessly into their development workflow without sacrificing speed or adding friction to the merge request process.

We are working to enable this performance improvement by default; this is tracked in [issue 546359](https://gitlab.com/gitlab-org/gitlab/-/issues/546359).

### Control requests for external control statuses

<!-- categories: Compliance Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/compliance/compliance_frameworks/_index.md#ping-enabled-setting) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/521757)

{{< /details >}}

External controls can be attached to requirements when creating compliance frameworks in GitLab.

By default, GitLab automatically requests the status of external controls from external systems every 12 hours
during compliance scans, setting the control status to ‘pending’. External systems then respond by using the
external controls API to update the status to ‘pass’ or ‘fail’.

In GitLab 18.5, you can now disable this automatic 12-hour ping by turning off the **Ping enabled** setting when
configuring external controls. When the 12-hour ping is disabled:

- GitLab will not automatically request status updates from external systems.
- The external control displays a **Disabled** badge in the compliance framework UI.
- You have complete control over when external control statuses are updated using the external controls API.

This prevents the system from resetting the external control statuses to ‘pending’ and gives you full control over
status update timing.

### Dependency scanning in limited availability

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/15961)

{{< /details >}}

In GitLab 18.5, we released a new dependency scanning template that works with the dependency scanning analyzer.
The analyzer now generates a dependency scanning report containing all component vulnerabilities.
Scan Execution Policy (SEP) and Pipeline Execution Policy (PEP) support the new template.

To use the new template, import `Jobs/Dependency-Scanning.v2.gitlab-ci.yml`.

This feature is available on GitLab.com and self-managed instances, though it’s marked as limited availability because official support for self-managed is not yet available.
GitLab.com users can use it immediately.

We welcome feedback on this feature. If you have questions, comments, or would like to engage with our team, please see this [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/523458).

### Variable expansion in environment `deployment_tier`

<!-- categories: Environment Management -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../ci/yaml/_index.md#environmentdeployment_tier) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/365402)

{{< /details >}}

You can now use CI/CD variables in the `environment:deployment_tier` field, making it easier to
dynamically configure deployment tiers based on pipeline conditions.

### Configure status lifecycles for issues and tasks

<!-- categories: Team Planning -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/work_items/status.md#lifecycles) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/555528)

{{< /details >}}

Previously, issues and tasks were required to share the same set of configured statuses. In this release, we’ve added support for configuring status lifecycles, enabling you to define distinct workflows for issues and tasks in your projects. With status mapping built into the workflow, you can seamlessly transition an issue or task to a new set of statuses with no bulk editing required when changing work item types.

Share your feedback and help us improve the feature by [contributing to our feedback issue](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/35235) with your use cases and suggestions.

### Format Markdown tables in the plain text editor

<!-- categories: Markdown -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/markdown.md#tables)

{{< /details >}}

Misaligned Markdown tables are difficult to read and edit, even though they render correctly.

The new **Reformat table** feature in the plain text editor’s toolbar realigns table
columns with a single click, preserving alignment settings and indentation. To use it:

- Select any Markdown table in wiki pages, issues, or merge requests.
- From the **More options** menu, select **Reformat table**.

This makes documentation maintenance faster and collaboration easier when working with
complex tables.

### View child task completion in issues

<!-- categories: Team Planning -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/tasks.md#view-tasks) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/520886)

{{< /details >}}

You can now track the progress of issues directly from the child items widget, giving you a status overview at a glance. This enhancement provides real-time visibility into potential bottlenecks when work is already in progress, helping you quickly identify at-risk items and make timely adjustments before sprint deadlines are threatened.

### Expose original severity from the vulnerabilities API

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../api/graphql/reference/_index.md#pipelinesecurityreportfinding) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/557940)

{{< /details >}}

The vulnerabilities GraphQL API now exposes the original severity of vulnerabilities.
This allows you to determine what the severity of the vulnerability was before severity overrides were applied.

### Time windows for merge request approval policies

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md#security_report_time_window) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/525509)

{{< /details >}}

To provide further flexibility in security vulnerability comparisons, we have introduced time windows in merge request approval policies. If the security reports for the most recent baseline are not yet available, this new policy configuration allows you to use previously completed security reports, as long as the reports are not older than the age that you specify as the time window.

Development teams can now avoid unnecessary delays when baseline security scans are stuck or taking too long, such as in very busy projects. By configuring a time window, merge requests that don’t introduce new vulnerabilities can proceed without waiting for the latest pipeline to complete, improving workflow efficiency.

To use this feature, create or edit a merge request approval policy and specify the `security_report_time_window` parameter (in minutes) in your approval policy configuration

The system will compare your merge request’s security results against the latest pipeline using the security reports created within the specified time window, allowing for faster approvals when no new vulnerabilities are introduced.

### Refreshed security finding statuses in the pipeline **Security** tab

<!-- categories: Vulnerability Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/detect/security_scanning_results.md#change-status) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/554078)

{{< /details >}}

Previously, in the **Security** tab for a pipeline, if you dismissed an vulnerability, the vulnerability was not immediately removed from the list.

Status updates in the security tab of a pipeline page are now updated after they are changed.

### Exceptions to bypass merge request approval policies

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/policies/merge_request_approval_policies.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/18114)

{{< /details >}}

Organizations can now designate specific users, groups, roles, or custom roles that can bypass merge request approval policies in case critical situations occur. This capability provides flexibility for emergency responses, while maintaining comprehensive audit trails and governance controls.

**Emergency bypass with accountability**: Designated users can bypass approval requirements during critical incidents, security hotfixes, or urgent production issues. When emergencies strike, authorized personnel can merge or push changes immediately while the system captures detailed justification and audit information for compliance review.

Key capabilities include:

- **Documented bypass process**: When authorized users invoke a policy bypass, they must provide detailed reasoning using an intuitive modal interface, ensuring every exception is properly documented with context.
- **Comprehensive audit integration**: Every bypass generates detailed audit events including user identity, policy context, reasoning, and timestamps for complete visibility into exception usage patterns.
- **Flexible configuration**: Define exception permissions for policies using YAML or UI configuration, supporting individual users, GitLab groups, standard roles, and custom roles.
- **Git-based push exceptions**: Users with pre-approved policy exceptions may push directly when invoking the push bypass option `security_policy.bypass_reason`.

This feature eliminates the need to entirely disable security policies during emergencies, providing a controlled path for urgent changes while preserving organizational governance and audit requirements.

### Show only active vulnerabilities in the dependency list

<!-- categories: Dependency Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/dependency_list/_index.md#vulnerabilities) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/353487)

{{< /details >}}

Previously, the dependency list included some dismissed vulnerabilities.

To provide you with a more useful representation of the vulnerabilities in the dependency list, the project dependency list now includes only active vulnerabilities in the `detected` and `confirmed` states.

### Static reachability in limited availability and experimental Java support

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/application_security/dependency_scanning/static_reachability.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/15780)

{{< /details >}}

In GitLab 18.5, we released limited availability support for static reachability.
This release focuses on improving JS/TS coverage support, fixing bugs, and providing experimental support for Java.
Static reachability enriches Software Composition Analysis (SCA) results by scanning project source code to identify open source dependencies that are in use.
Data produced by static reachability can be used as part of users’ triage and remediation decision making. Static reachability data can also be used with CVSS and EPSS scores, as well as KEV indicators to provide a more focused view of identified vulnerabilities.

We welcome feedback on this feature. If you have questions, comments, or would like to engage with our team, please see this [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/535498).

### GitLab Runner 18.5

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](https://docs.gitlab.com/runner) | [Related issue](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38976)

{{< /details >}}

We’re also releasing GitLab Runner 18.5 today! GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

Bug fixes:

- [Runner update fails on vanilla Kubernetes after updating runner operator from 1.39 to 1.41](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/259)
- [Some container labels have duplicate prefixes](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38674)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-5-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-5-stable/CHANGELOG.md).md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.5)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.5)
- [UI improvements](https://papercuts.gitlab.com/?milestone=18.5)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
