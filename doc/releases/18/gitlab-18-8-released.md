---
stage: Release Notes
group: Monthly Release
date: 2026-01-15
title: "GitLab 18.8 release notes"
description: "GitLab 18.8 released with GitLab Duo Agent Platform now generally available"
---

<!-- markdownlint-disable -->
<!-- vale off -->

On January 15, 2026, GitLab 18.8 was released with the following features.

In addition, we want to thank all of our contributors, including this month's notable contributor.

## This month’s Notable Contributor: Wesley Yarde

This month’s Notable Contributor is [Wesley Yarde](https://gitlab.com/WYarde) for building a foundational new feature that allows organizations to disable SSH keys for their enterprise users.

Wesley’s contribution stands out for several reasons:

- **Security and compliance**: This feature enables organizations to enforce SSH key requirements and enhance security across their enterprise.
- **Foundational work**: With no existing implementation to follow, Wesley had to collaborate extensively with the GitLab team to define requirements and architecture from scratch.
- **First contribution**: Remarkably, this was Wesley’s first contribution to GitLab—demonstrating exceptional ability to navigate a complex codebase and tackle a challenging feature.
- **Enables future development**: This work establishes the foundation for similar features like instance-level SSH key disabling and service account controls.

The implementation spanned multiple merge requests ([!205020](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205020), [!210482](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/210482)) with thorough review cycles. Despite the complexity, Wesley demonstrated outstanding collaboration and patience throughout the process.

“It was a pleasure to collaborate with Wesley on this feature request! While both the contributor and reviewers may have felt that the review process was overwhelming, both sides showed understanding and superb collaboration to ensure the implementation is solid and complete.” — [Bogdan Denkovych](https://gitlab.com/bdenkovych), who nominated Wesley for this recognition.

Congratulations Wesley, and thank you for this valuable contribution to GitLab!

## Primary features

### GitLab Duo Agent Platform now generally available

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/duo_agent_platform/_index.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/585273)

{{< /details >}}

GitLab Duo Agent Platform is now generally available, bringing agentic AI orchestration
across your entire software development lifecycle. Unlike AI tools that speed up individual
tasks in isolation, the Agent Platform helps teams coordinate AI agents across
planning, building, securing, and shipping software, closing the gap between faster
individual work and the collaborative, multi-stage reality of software delivery.

The platform provides a central AI Catalog where teams can discover, manage, and share
agents and flows across their organization. Built-in foundational agents like Planner, Security Analyst,
and Data Analyst handle structured work at key decision points, while customizable flows
automate multi-step agents and tasks in development workflows
from issue to merge request, CI/CD migration, pipeline
troubleshooting, and code reviews.

With governance controls, usage visibility, and flexible deployment options including
self-hosted models for offline environments, organizations can adopt AI at scale with
the transparency and control they need.

GitLab Premium and Ultimate users can start using the Agent Platform today on GitLab.com and
GitLab Self-Managed instances with promotional [GitLab Credits](../../subscriptions/gitlab_credits.md).

### GitLab Duo Planner Agent now generally available

<!-- categories: Portfolio Management -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/duo_agent_platform/agents/foundational_agents/planner.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/583008)

{{< /details >}}

The Planner Agent is now generally available! The Planner Agent is a foundational agent built to support product managers directly in GitLab.

Use the Planner Agent to create, edit, and analyze GitLab work items. Instead of manually chasing updates, prioritizing work, or summarizing planning data, the Planner Agent helps you analyze backlogs, apply frameworks like RICE or MoSCoW, and surface what truly needs your attention. It’s like having a proactive teammate who understands your planning workflow and works with you to make better, more efficient decisions.

Please provide your feedback in [issue 583008](https://gitlab.com/gitlab-org/gitlab/-/work_items/583008).

### GitLab Duo Security Analyst Agent now generally available

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/duo_agent_platform/agents/foundational_agents/security_analyst_agent.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/19659)

{{< /details >}}

The GitLab Duo Security Analyst Agent, [introduced as beta in GitLab 18.5](https://about.gitlab.com/releases/2025/10/16/gitlab-18-5-released/#gitlab-security-analyst-agent-for-duo-agent-catalog-beta), is now generally available in GitLab 18.8.

The Security Analyst Agent enables engineers to manage vulnerabilities through natural language commands in GitLab Duo Agentic Chat. Instead of manually clicking through vulnerability dashboards or writing custom scripts for bulk operations, security teams can now triage, assess, and provide guidance for vulnerabilities in Chat conversations.

As a foundational agent, the Security Analyst Agent is available by default in GitLab Duo Agentic Chat, with no manual setup required.

### Auto-dismiss irrelevant vulnerabilities with vulnerability management policies

<!-- categories: Security Policy Management -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/policies/vulnerability_management_policy.md#auto-dismiss-policies) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/10894)

{{< /details >}}

Security teams can now automatically dismiss vulnerabilities that don’t apply to their organization using vulnerability management policies. Dismissing vulnerabilities that are not relevant to your organization reduces noise and helps developers focus on vulnerabilities that pose actual risk.

You can create policies to auto-dismiss vulnerabilities based on:

- File path
- Directory
- Identifier (CVE, CWE, or OWASP)

Auto-dismissed vulnerabilities appear in the merge request’s security widget with an **Auto-dismissed** label and are tracked in the vulnerability report activity with a dismissal reason for audit purposes.

## Agentic Core

### Turn the GitLab Duo Agent Platform on or off

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../user/duo_agent_platform/turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/583980)

{{< /details >}}

You can now turn on or off the GitLab Duo Agent Platform, including GitLab Duo Chat (Agentic), agents,
and flows for a top-level group or the entire instance. When this setting is turned off, these features are not available.

### Group access control for GitLab Duo features

<!-- categories: Duo Agent Platform -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../administration/gitlab_duo/configure/access_control.md) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/585355)

{{< /details >}}

You can now define group access rules to control who can use GitLab Duo features, enabling flexible adoption strategies from immediate organization-wide access to phased rollouts.

This feature provides granular governance control so you can scale adoption at your pace while maintaining security and compliance.

### GitLab Duo Agent Platform for GitLab Duo Self-Hosted (offline licensing) now generally available

<!-- categories: Self-Hosted Models -->

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Add-ons: Duo Enterprise
- Links: [Documentation](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/19125)

{{< /details >}}

GitLab Duo Agent Platform is now generally available for Duo Self-Hosted. This feature is available to GitLab Self-Managed customers with an offline license, and uses seat-based pricing.

Self-Managed administrators can configure [compatible models](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models) for use with GitLab Duo Agent Platform. Administrators using AWS Bedrock or Azure OpenAI can also configure Anthropic Claude or OpenAI GPT models.

## Unified DevOps and Security

### C/C++ support in Advanced SAST now generally available

<!-- categories: SAST -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/sast/advanced_sast_cpp.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/18369)

{{< /details >}}

Cross-file, cross-function scanning support for C/C++ is now generally available in GitLab Advanced SAST.

### Multiple Container Scanning

<!-- categories: Container Scanning -->

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](../../user/application_security/container_scanning/multi_container_scanning.md) | [Related epic](https://gitlab.com/groups/gitlab-org/-/work_items/3139)

{{< /details >}}

In GitLab 18.8, we released multi-container scanning in Beta.

Users are now able to pass in an array of images to be scanned as part of many Container Scanning jobs.

### Centralized credential management API for group owners

<!-- categories: System Access -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../api/groups.md#credentials-inventory-management) | [Related epic](https://gitlab.com/groups/gitlab-org/-/epics/16343)

{{< /details >}}

The Credentials Inventory API is now available for Enterprise users on GitLab.com. This adds credential management capabilities previously only available on self-hosted instances, and enables organizations to better manage and secure their authentication tokens and keys.

The Credentials Inventory API provides programmatic access to view credentials across your organization, including:

- Personal Access Tokens (PATs)
- Group Access Tokens (GrATs)
- Project Access Tokens (PrATs)
- SSH Keys
- GPG Keys

This API complements the existing Credentials Inventory UI, allowing enterprise administrators to automate credential management tasks that previously required manual intervention. With the Credentials Inventory API, you can:

- Automate security workflows: Build automated processes to monitor, audit, and revoke credentials.
- Enforce credential policies: Identify and revoke unused or expired tokens.
- Improve security posture: Reduce the risk of credential misuse through regular auditing.
- Streamline operations: Integrate credential management into your existing security tools and workflows.

### Group Owners can disable SSH keys for enterprise users

<!-- categories: System Access -->

{{< details >}}

- Tier: Silver, Gold
- Offering: GitLab.com
- Links: [Documentation](../../user/ssh_advanced.md#disable-ssh-keys-for-enterprise-users) | [Related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/30343)

{{< /details >}}

Group Owners can now disable SSH keys for all enterprise users in their group. When disabled, users cannot add new SSH keys and their existing keys are deactivated. This applies to all enterprise users in the group, including those with the Owner role.

Thank you to [Wesley Yarde](https://gitlab.com/WYarde) for helping build this feature!

### GitLab Runner 18.8

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated, GitLab Dedicated for Government
- Links: [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

We’re also releasing GitLab Runner 18.8 today! GitLab Runner is the highly-scalable build agent that runs your CI/CD jobs and sends the results back to a GitLab instance. GitLab Runner works in conjunction with GitLab CI/CD, the open-source continuous integration service included with GitLab.

#### What’s New

- [Improved error messages for job inputs interpolation errors](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39163)

#### Bug Fixes

- [`WaitForServicesTimeout` no longer supports `-1` to disable timeout](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39172)
- [Custom URL breaks submodule authentication with `insteadOf` rules](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39170)
- [Custom runner short-token on Windows 2025 uses 9 characters instead 8](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39122)
- [PowerShell default helper image missing for Docker executor in GitLab Runner 17.8.3](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/38669)
- [GitLab Runner with Docker Autoscaler does not reuse available cache volumes](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/37906)
- [VirtualBox leaves dangling VM when job is cancelled](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/37344)

The list of all changes is in the GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-8-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-8-stable/CHANGELOG.md).md).

## Related topics

- [Bug fixes](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.8)
- [Performance improvements](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.8)
- [UI improvements](https://papercuts.gitlab.com/?milestone=18.8)
- [Deprecations and removals](../../update/deprecations.md)
- [Upgrade notes](../../update/versions/_index.md)
