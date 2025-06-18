---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Application security testing'
description: Scanning, vulnerabilities, compliance, customization, and reporting.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Build security into your development process with GitLab application security testing capabilities.
These features help you identify and address vulnerabilities early in your development lifecycle,
before they reach production environments.

GitLab application security testing provides comprehensive coverage of both repository content and
deployed applications, enabling you to detect potential security issues throughout your software
development lifecycle.

GitLab also helps reduce the risk of vulnerabilities being introduced through several protective
mechanisms:

Secret push protection
: Blocks secrets such as keys and API tokens from being pushed to GitLab.

Merge request approval policies
: Enforce an additional approval on merge requests that would introduce vulnerabilities.

For a click-through demo, see [Integrating security to the pipeline](https://gitlab.navattic.com/gitlab-scans).
<!-- Demo published on 2024-01-15 -->

## How application security testing works

GitLab detects security vulnerabilities throughout your code, dependencies, containers, and
deployed applications. Your project's repository and your application's behavior are scanned for
vulnerabilities.

Security findings appear directly in merge requests, providing actionable information before code is
merged. This proactive approach reduces the cost and effort of fixing issues later in development.

Application security testing can run in several contexts:

During development
: Automated scans run as part of CI/CD pipelines when code is committed or merge requests are
  created.

Outside development
: Security testing can be run manually on demand or scheduled to run at regular intervals.

## Vulnerability management lifecycle

GitLab assists in the complete vulnerability management lifecycle through key phases:

[Detect](detect/_index.md)
: Identify vulnerabilities through automated scanning and security testing.

[Triage](triage/_index.md)
: Evaluate and prioritize vulnerabilities to determine which need immediate attention and which
  can be addressed later.

[Analyze](analyze/_index.md)
: Conduct detailed analysis of confirmed vulnerabilities to understand their impact and determine
  appropriate remediation strategies.

[Remediate](remediate/_index.md)
: Fix the root cause of vulnerabilities or implement appropriate risk mitigation measures.

Vulnerabilities are centralized in the vulnerability report and security dashboard, making
prioritization and remediation tracking more straightforward for security teams.

## Get started

To get started, see [Get started securing your application](get-started-security.md).
