---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Roll out application security testing'
---

Plan your application security testing implementation in phases to ensure a smooth transition to a
more secure development practice.

This guide helps you implement GitLab application security testing across your organization in
phases. By starting with a pilot group and gradually expanding coverage, you can minimize disruption
while maximizing security benefits. The phased approach allows your team to become familiar with
application security testing tools and workflows before scaling to all projects.

Prerequisites:

- GitLab Ultimate.
- Familiarity with GitLab CI/CD pipelines. The following GitLab self-paced courses provide a good
  introduction:
  - [Introduction to CI/CD](https://university.gitlab.com/courses/introduction-to-cicd-s2)
  - [Hands-on Labs: CI Fundamentals](https://university.gitlab.com/courses/hands-on-labs-ci-fundamentals)
- Understanding of your organization's security requirements and risk tolerance.

## Scope

This guide covers how to plan and execute a phased implementation of GitLab application security
testing features, including configuration, vulnerability management, and prevention
strategies. It assumes you want to gradually introduce application security testing to minimize
disruption to existing workflows while securing your codebase.

## Phases

The implementation consists of two main phases:

1. **Pilot phase**: Implement application security testing for a limited set of projects to validate
   configurations and train teams.
1. **Rollout phase**: Expand application security testing to all target projects using the knowledge
   gained during the pilot.

## Pilot phase

The pilot phase allows you to apply application security testing with minimal risk before a wider
rollout.

Consider the following guidance before starting on the pilot phase:

- Identify key stakeholders including security team members, developers, and project managers.
- Select pilot projects that are representative of your codebase but not critical to daily
  operations.
- Schedule training sessions for developers and security team members.
- Document current security practices to measure improvements.

### Pilot goals

The pilot phase helps you achieve several key objectives:

- Implement application security testing without slowing development

  During the pilot, application security testing results are available to developers in the UI,
  without blocking merge requests. This approach minimizes risk to projects outside the pilot's
  scope while collecting valuable data on your current security posture. In the rollout phase you
  should use a [merge request approval policy](#merge-request-approval-policy) to add an additional
  approval gate when vulnerabilities are detected in merge requests.

- Establish scalable detection methods

  Implement application security testing on pilot projects in a way that can be expanded to include
  all projects in the wider rollout scope. Focus on configurations that scale well and can be
  standardized across projects.

- Test scan times

  Test scan times on representative codebases and applications.

- Simulate the vulnerability remediation workflow

  Simulate detecting, triaging, analyzing, and remediating vulnerabilities in the developer
  workflows. Verify that engineers can act on findings.

- Compare maintenance costs

  Compare the maintenance of a single solution versus integrating multiple endpoint solutions. How
  well does this integrate into the IDE, merge request, and pipeline?

#### Benefits for developers

Developers in the pilot group will gain:

- Familiarity with application security testing methods and how to interpret results.
- Experience preventing vulnerabilities from being merged into the default branch.
- Understanding of the vulnerability management workflow that begins when a vulnerability is
  detected in the default branch.

#### Benefits for security management

Security team members participating in the pilot will gain:

- Experience with vulnerability tracking and management in GitLab.
- Data to establish security baselines and set realistic remediation goals.
- Insights to refine the security policy before wider rollout.

### Pilot plan

Proper planning ensures an effective pilot phase.

#### Roles and responsibilities

Define who is responsible for:

- Configuring application security testing
- Reviewing scan results
- Triaging vulnerabilities
- Managing remediation
- Training team members
- Measuring the pilot's success

### Pilot scope

Carefully select which projects to include in the pilot phase.

Consider these factors when selecting pilot projects:

- Include projects with different technology stacks to test application security testing
  effectiveness.
- Choose projects with active development to see real-time results.
- Select projects with teams open to learning new security practices.
- Avoid starting with mission-critical applications.

### Security application security testing order

Introduce security application security testing in the following order. This balances value and ease
of deployment.

- Dependency scanning
- SAST
- Advanced SAST
- Pipeline secret detection
- Secret push protection
- Container scanning
- DAST
- API security testing
- IaC scanning
- Operational container scanning

## Test pilot projects

With planning complete, begin implementing application security testing of your pilot projects.

### Set up testing of pilot projects

Prerequisites:

- You must have the Maintainer role for the projects in which application security testing is to be
  enabled.

For each project in scope:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Secure** > **Security configuration**.
1. Expand **Security configuration**.
1. Enable the appropriate application security testing based on your project's stack.

For more details, see [Security configuration](security_configuration.md).

### For developers

Introduce developers to the tools that provide visibility into security findings.

#### Pipeline results

Developers can view security findings directly in pipeline results:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Build** > **Pipelines**.
1. Select the pipeline to review.
1. In the pipeline details, select the **Security** tab to view detected vulnerabilities.

For more details, see
[View security scan results in pipelines](security_scanning_results.md).

#### Merge request security widget

The security widget provides visibility into vulnerabilities detected in merge request pipelines:

1. Open a merge request.
1. Review the security widget to see detected vulnerabilities.
1. Select **Expand** to see detailed findings.

For more details, see [View security scan results in merge requests](security_scanning_results.md).

#### VS Code integration with GitLab Workflow extension

Developers can view security findings directly in their IDE:

1. Install the GitLab Workflow extension for VS Code.
1. Connect the extension to your GitLab instance.
1. Use the extension to view security findings without leaving your development environment.

For more details, see
[GitLab Workflow extension for VS Code](../../../editor_extensions/visual_studio_code/_index.md).

## Vulnerability management workflow

Establish a structured workflow for handling detected vulnerabilities.

The vulnerability management workflow consists of four key stages:

1. **Detect**: Find vulnerabilities through automated application security testing in pipelines.
1. **Triage**: Assess the severity and impact of detected vulnerabilities.
1. **Analyze**: Investigate the root cause and determine the best approach for remediation.
1. **Remediate**: Implement fixes to resolve the vulnerabilities.

### Efficient triage

GitLab provides several features to streamline vulnerability triage:

- Vulnerability filters to focus on high-impact issues first.
- Severity and confidence ratings to prioritize efforts.
- Vulnerability tracking to maintain visibility of outstanding issues.
- Risk assessment data.

For more details, see [Triage](../triage/_index.md).

Triage should include regular reviews of the vulnerability report with security stakeholders.

### Efficient remediation

Streamline the remediation process with these GitLab features:

- Automated remediation suggestions for certain vulnerability types.
- Merge request creation directly from vulnerability details.
- Vulnerability history tracking to monitor progress.
- Automatically resolve vulnerabilities that are no longer detected.

For more details, see [Remediate](../remediate/_index.md).

#### Integrate with ticketing systems

You can use a GitLab issue to track the remediation work required for a vulnerability.
Alternatively, you can use a Jira issue if that is your primary ticketing system.

For more details, see
[Linking a vulnerability to GitLab and Jira issues](../vulnerabilities/_index.md#linking-a-vulnerability-to-gitlab-and-jira-issues).

## Vulnerability prevention

Implement features to prevent vulnerabilities from being introduced in the first place.

### Merge request approval policy

Use a merge request approval policy to add an extra approval requirement if the number and
severity of vulnerabilities in a merge request exceeds a specific threshold. This allows an extra
review from a member of the application security team, providing an extra level of scrutiny.

Configure approval policies to require security reviews:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Secure** > **Policies**.
1. Select **New policy**
1. In the **Merge request approval policy** pane, select **Select policy**.
1. Add a merge request approval policy requiring approval from security team members.

For more details, see
[Security approvals in merge requests](../policies/merge_request_approval_policies.md).

## Rollout phase

After a successful pilot, expand application security testing to all target projects.

Before starting on the rollout phase consider the following:

- Evaluate the results of the pilot phase.
- Document lessons learned and best practices.
- Prepare training materials based on pilot experiences.
- Update implementation plans based on pilot feedback.

### Define access to team members

Application security testing tasks require specific roles or permissions. For each person taking
part in the rollout phases, define their access according to the tasks they'll be
performing.

- Users with the Developer role can view vulnerabilities on their projects and merge requests.
- Users with the Maintainer role can configure security configurations for projects.
- Users assigned a Custom Role with `admin_vulnerability` permission can manage and triage
  vulnerabilities.
- Users assigned a Custom Role with `manage_security_policy_link` permission can enforce policies
  on groups and projects.

For more details, see
[Roles and permissions](../../permissions.md#application-security-group-permissions).

### Rollout goals

The rollout phase aims to implement application security testing across all projects in scope,
using the knowledge and experience gained during the pilot.

### Rollout plan

Review and update roles and responsibilities established during the pilot. The same team
structure should work for the rollout, but you may need to add more team members as the
scope expands.

## Implement application security testing at scale

Use policy features to efficiently scale your security implementation.

### Use policy inheritance

Use policy inheritance to maximize effectiveness while also minimizing the number of policies to be
managed.

Consider the scenario in which you have a top-level group named Finance which contains subgroups A,
B, and C. You want to run dependency scanning and secret detection on all projects in the Finance
group. For each subgroup you want to run different sets of application security testing tools.

To achieve this goal, you could define 3 policies for the Finance group:

- Policy 1:
  - Includes dependency scanning and secret detection.
  - Applies to the Finance group, all its subgroups, and their projects.
- Policy 2:
  - Includes DAST and API security testing.
  - Scoped to only subgroups A and B.
- Policy 3:
  - Includes SAST.
  - Scoped to only subgroup C.

Only a single set of policies needs to be maintained but still provides the flexibility to suit
the needs of different projects.

For more details, see [Enforcement](../policies/enforcement/_index.md#enforcement).

### Configure scan execution policies

Implement consistent application security testing across multiple projects by using scan execution
policies.

Prerequisites:

- You must have the Owner role, or a custom role with `manage_security_policy_link` permission, for
  the groups in which application security testing is to be enabled.

1. On the left sidebar, select **Search or go to** and find your project or group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Secure** > **Policies**.
1. Create scan execution policies based on the application security testing configuration used
   during the pilot phase.

For more details, see [Security policies](../policies/_index.md).

### Scale gradually

Scale the rollout gradually, first to the pilot projects and incrementally to all target projects.
When applying policies to all groups and projects, create awareness to all project stakeholders as
this can impact changes in pipelines and merge request workflows. For example, notify stakeholders

Implement your security policies in phases:

1. Start by applying policies to the projects from the pilot phase.
1. Monitor for any issues or disruptions.
1. Gradually expand the policies' scope to include more projects.
1. Continue until all target projects are covered.

For more details, see the [policy design guidelines](../policies/enforcement/_index.md#policy-design-guidelines).
