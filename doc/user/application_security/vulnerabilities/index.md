---
type: reference, howto
stage: Secure
group: Threat Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Vulnerability Pages

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/13561) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 13.0.

Each security vulnerability in a project's [Security Dashboard](../security_dashboard/index.md#project-security-dashboard) has an individual page which includes:

- Details for the vulnerability.
- The status of the vulnerability within the project.
- Available actions for the vulnerability.
- Any issues related to the vulnerability.

On the vulnerability page, you can interact with the vulnerability in
several different ways:

- [Change the Vulnerability Status](#changing-vulnerability-status) - You can change the
  status of a vulnerability to **Detected**, **Confirmed**, **Dismissed**, or **Resolved**.
- [Create issue](#creating-an-issue-for-a-vulnerability) - Create a new issue with the
  title and description pre-populated with information from the vulnerability report.
  By default, such issues are [confidential](../../project/issues/confidential_issues.md).
- [Link issues](#link-issues-to-the-vulnerability) - Link existing issues to vulnerability.
- [Automatic remediation](#automatic-remediation-for-vulnerabilities) - For some vulnerabilities,
  a solution is provided for how to fix the vulnerability automatically.

## Changing vulnerability status

You can switch the status of a vulnerability using the **Status** dropdown to one of
the following values:

| Status    | Description                                                                                                      |
|-----------|------------------------------------------------------------------------------------------------------------------|
| Detected  | The default state for a newly discovered vulnerability                                                           |
| Confirmed | A user has seen this vulnerability and confirmed it to be accurate                                               |
| Dismissed | A user has seen this vulnerability and dismissed it because it is not accurate or otherwise not to be resolved |
| Resolved  | The vulnerability has been fixed and is no longer valid                                                          |

A timeline shows you when the vulnerability status has changed
and allows you to comment on a change.

## Creating an issue for a vulnerability

You can create an issue for a vulnerability by selecting the **Create issue** button.

This creates a [confidential issue](../../project/issues/confidential_issues.md) in the
project the vulnerability came from and pre-populates it with useful information from
the vulnerability report. After the issue is created, GitLab redirects you to the
issue page so you can edit, assign, or comment on the issue.

## Link issues to the vulnerability

You can link one or more existing issues to the vulnerability. This allows you to
indicate that this vulnerability affects multiple issues. It also allows you to indicate
that the resolution of one issue would resolve multiple vulnerabilities.

## Automatic remediation for vulnerabilities

You can fix some vulnerabilities by applying the solution that GitLab automatically
generates for you. [Read more about the automatic remediation for vulnerabilities feature](../index.md#automatic-remediation-for-vulnerabilities).
