---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Remediate
description: Root cause determination and analysis.
---

Remediation is the fourth phase of the vulnerability management lifecycle: detect, triage, analyze,
remediate.

Remediation is the process of finding the root cause of a vulnerability and fixing the root cause,
reducing the risks, or both. Use information contained in each vulnerability's
[details page](../vulnerabilities/_index.md) to help you understand the nature of the vulnerability
and remediate it.

The objective of the remediation phase is to either resolve or dismiss a vulnerability. A
vulnerability is resolved when either you've remediated the root cause or it's no longer present. A
vulnerability is dismissed when you've decided that no further effort is justified.

<i class="fa-youtube-play" aria-hidden="true"></i>
For a walkthrough of how GitLab Duo can help you analyze and remediate a vulnerability, see
[Use GitLab Duo to remediate an SQL injection](https://youtu.be/EJXAIzXNAWQ?si=IDKtApBH1j5JwdUY).
<!-- Video published on 2023-07-08 -->

## Scope

The scope of the remediation phase is all those vulnerabilities that have been through the analysis
phase and confirmed as needing further action. To list these vulnerabilities, use the following
filter criteria in the vulnerability report:

- **Status**: Confirmed
- **Activity**: Has issue

## Document the vulnerability

If you've not already,
[create an issue](../vulnerabilities/_index.md#create-a-gitlab-issue-for-a-vulnerability)
to document your investigation and remediation work. This documentation provides a reference point
if you discover a similar vulnerability, or if the same vulnerability is detected again.

## Remediate the vulnerability

Use the information gathered in the analysis phase to help guide you to remediate the vulnerability.
It's important to understand the root cause of the vulnerability so that remediation is
effective.

For some vulnerabilities detected by SAST, GitLab can:

- [Explain the vulnerability](../vulnerabilities/_index.md#explaining-a-vulnerability), using GitLab
  Duo Chat.
- [Resolve the vulnerability](../vulnerabilities/_index.md#vulnerability-resolution), using GitLab
  Duo Chat.
- Provide the complete data path from input to the vulnerable line of code, if you're using
  GitLab Advanced SAST.

When the root cause of a vulnerability is remediated, resolve the vulnerability.

To do this:

1. Change the vulnerability's status to **Resolved**.
1. Document in the issue created for the vulnerability how it was remediated, then close the issue.

   If a resolved vulnerability is reintroduced and detected again, its record is reinstated and its
   status set to **Needs triage**.

## Dismiss the vulnerability

At any point during the remediation phase you might decide to dismiss the vulnerability, possibly
because you have decided:

- The estimated cost of remediation effort is too high.
- The vulnerability poses little to no risk.
- The vulnerability's risk has already been mitigated.
- The vulnerability is not valid in your environment.

When you dismiss the vulnerability:

1. Provide a brief comment that states why you've dismissed it.
1. Change the vulnerability's status to **Dismissed**.
1. If you created an issue for the vulnerability, add a comment noting that you dismissed the
   vulnerability, then close the issue.

   A dismissed vulnerability is ignored if it's detected in subsequent scans.
