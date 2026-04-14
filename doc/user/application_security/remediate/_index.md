---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Remediate
description: Fix or eliminate the root cause of a vulnerability.
---

Remediation is the fourth phase of the vulnerability management lifecycle: detect, triage, analyze,
remediate.

Remediation is the process of fixing or eliminating the root cause of a vulnerability. Use
information contained in each vulnerability's [details page](../vulnerabilities/_index.md) to help
you understand the nature of the vulnerability and remediate it.

<i class="fa-youtube-play"></i>
For a walkthrough of how GitLab Duo can help you analyze and remediate a vulnerability, see
[Use GitLab Duo to remediate an SQL injection](https://youtu.be/EJXAIzXNAWQ?si=IDKtApBH1j5JwdUY).

## Scope

The scope of the remediation phase is all those vulnerabilities that have been through the analysis
phase and confirmed as needing further action. To list these vulnerabilities, use the following
filter criteria in the vulnerability report:

- **Status**: Confirmed
- **Activity**: Has issue

## Document the vulnerability

If you've not already,
[create an issue](../vulnerabilities/_index.md#create-a-gitlab-issue-for-a-vulnerability) to
document your investigation and remediation work. Use these steps if this vulnerability recurs
or you find similar vulnerabilities.

## Choose an outcome

After analyzing a vulnerability, you must decide whether to remediate it or dismiss it. Use your
organization's risk management framework to guide your decision. The guidance here is generic. Adapt
it to your organization's risk profile.

If available, use the
[Security Analyst Agent](../../duo_agent_platform/agents/foundational_agents/security_analyst_agent.md)
to accelerate vulnerability remediation. The agent triages, assesses, and
remediates security findings by providing insights, risk assessments, and remediation guidance.

Remediate a vulnerability when:

- The vulnerability poses a genuine security risk in your environment.
- The root cause can be fixed or mitigated.
- The effort required is justified by the risk level.

Dismiss a vulnerability when:

- The estimated cost of remediation effort is too high.
- The vulnerability poses little to no risk.
- The vulnerability's risk has already been mitigated.
- The vulnerability is not valid in your environment.

## Remediate a vulnerability

Use the information gathered in the analysis phase to help guide you to remediate the vulnerability.
It's important to understand the root cause of the vulnerability so that remediation is
effective.

Change the status of a vulnerability to **Resolved** when you have remediated it. This status change
creates a record of when and how the vulnerability was addressed, which is important for compliance
and security reviews. If the same vulnerability is detected again in future scans, GitLab
automatically reinstates the record and sets its status back to **Needs triage**, alerting you to a
regression.

Prerequisites:

- The Security Manager, Maintainer or Owner role for the project.

To change a vulnerability's status to resolved:

1. In the top bar, select **Search or go to** and find your project.
1. Select **Secure** > **Vulnerability report**.
1. Find the vulnerability in the vulnerability report.
1. Select the vulnerability's description.
1. Select **Edit vulnerability** > **Change status**.
1. From the **Status** dropdown list, select **Resolved**.
1. Optional. In the **Comment** input box, explain why you've marked the vulnerability as resolved.
1. Select **Change status**.
1. If you created an issue for the vulnerability, document how it was remediated, then close the
   issue.

## Dismiss a vulnerability

Change the status of a vulnerability to **Dismissed** when you've decided that remediation is not
justified. This status change creates a record of when and how the vulnerability was addressed,
which is important for compliance and security reviews. A dismissed vulnerability is ignored if it's
detected in subsequent scans.

Prerequisites:

- The Security Manager, Maintainer or Owner role for the project.

To dismiss a vulnerability:

1. In the top bar, select **Search or go to** and find your project.
1. Select **Secure** > **Vulnerability report**.
1. Find the vulnerability in the vulnerability report.
1. Select the vulnerability's description.
1. Select **Edit vulnerability** > **Change status**.
1. From the **Status** dropdown list, select a dismissal reason.
1. In the **Comment** input box, explain why you've dismissed the vulnerability.
1. Select **Change status**.
1. If you created an issue for the vulnerability, document why you've dismissed it, then close the
   issue.
