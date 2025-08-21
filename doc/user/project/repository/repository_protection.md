---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Secure your repository with branch protection, approval rules, and access controls.
title: Protect your repository
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Repository protection prevents unauthorized changes to your codebase while maintaining
development workflows. These controls help you solve common development challenges, including:

- Accidental commits to production or protected branches.
- Exposed sensitive data in commit histories.
- Bypassed code review processes.
- Unauthorized changes to critical files.
- Unverified commit authorship.
- Non-compliant code entering the main branch.

By combining different protection methods, you create validation points that work together to
enforce your organization's standards.

Higher GitLab tiers have access to additional tools to apply comprehensive security scanning,
enforce compliance, and manage vulnerabilities across multiple projects and groups.
In these environments, some of the protection methods may already be enforced by your organization.
For details on these advanced security tools, see [secure your application](../../application_security/secure_your_application.md).

## Protection methods

GitLab provides multiple protection methods that work together to secure your repository.
Each method addresses different security needs and can be combined for comprehensive protection.

| Protection method                                                | Description                                                                                    | When to use                                                                                                       | Instance                                    | Groups                                      | Projects |
|------------------------------------------------------------------|------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|---------------------------------------------|---------------------------------------------|----------|
| [Protected branches](branches/protected.md)                      | Controls permissions on branches to ensure code stability and quality.                         | Control who can push and merge, prevent accidental deletion, enforce reviews, or regulate force push permissions. | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [Merge request approvals](../merge_requests/approvals/_index.md) | Review process that requires approvals before changes merge.                                   | Require code reviews, create approval rules, or configure approval settings.                                      | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [Push rules](push_rules.md)                                      | Pre-receive Git hooks that validate commits, files, and tags before they enter the repository. | Evaluate commit contents, enforce branch name rules, prevent tag removal, or require signed commits.              | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| [Code Owners](../codeowners/_index.md)                           | Defines who has expertise for specific files and directories in your codebase.                 | Require expert approval for changes to specific files or identify responsible parties for code maintenance.       | {{< icon name="dash-circle" >}} No          | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes |
| [Status checks](../merge_requests/status_checks.md)              | API calls to external systems that validate merge request status.                              | Integrate with third-party workflow tools or validate against external quality requirements.                      | {{< icon name="dash-circle" >}} No          | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes |

## Branch rules

To help you manage multiple protection methods, GitLab provides a unified [branch rules](branches/branch_rules.md)
interface for protected branches, approval rules, and status checks.
Use the **Branch rules** page in your project settings to configure all branch protections from one
location, view protection status across branches, and manage complex protection combinations.

{{< alert type="note" >}}

For group protection, configure protected branches and push rules in your group settings.
The **Branch rules** page is available only in projects. Group rules apply to all projects
in the group and work alongside any project-specific rules you create.

{{< /alert >}}

## Configure your protection strategy

Choose protection methods based on your workflow and security requirements. The following are example
strategies.

### Baseline protection

To establish consistent security standards across all repositories:

- Configure default branch protection for the group to automatically protect new projects.
- Set up protected branches to control who can push and merge.
- Require merge request approvals to enforce peer review.

### Comprehensive protection

To secure critical projects with layered protection:

- Set up protected branches and approval rules to control who can push and merge.
- Require Code Owner approvals for files containing sensitive logic.
- Enforce signed commits to verify author identity.
- Add status checks to validate against automated testing.
- Apply push rules to a group to enforce standards across all projects.

### Targeted protection

To address specific security requirements:

- Require Code Owner approval when files need domain expertise review.
- Enforce push rules to maintain commit standards and content restrictions.
- Add status checks when external validation is required.
- Configure approval rules for workflow-specific requirements.

## Get started

Prerequisites:

- You must have at least the Maintainer role for the project or Owner role for the group.
- Identify which branches need protection.
- Determine your compliance and security requirements.

To configure and implement repository protection:

1. Choose your scope:
   - For group rules, go to your group's **Settings** > **Repository**.
   - For project-specific rules, go to your project's **Settings** > **Repository** >
     **Branch rules**.

1. Set baseline protection:
   - Create protected branches for your default branch and other critical branches.
     - In group settings: **Settings** > **Repository** > **Protected branches**.
     - In project settings: **Settings** > **Repository** > **Branch rules**.
   - Configure merge permissions and approval requirements in **Settings** > **Merge requests** >
     **Merge request approvals**.

1. Add review requirements:
   - Define Code Owners in the `CODEOWNERS` file for specific files.
   - Set up approval rules in **Settings** > **Merge requests**.

1. Enable security controls:
   - Configure push rules:
     - For groups: **Settings** > **Repository** > **Push rules**.
     - For projects: **Settings** > **Repository** > **Push rules**.
   - Enable signed commits in **Settings** > **Repository** > **Push rules** >
     **Reject unsigned commits**.

1. Test your configuration:
   - Create a test merge request.
   - Verify protection rules trigger correctly.
   - Adjust settings based on results.

## Related topics

- [Branch rules](branches/branch_rules.md)
- [Push rules](push_rules.md)
- [Merge requests](../merge_requests/_index.md)
- [Code Owners](../codeowners/_index.md)
- [Roles and permissions](../../permissions.md)
