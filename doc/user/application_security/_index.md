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

GitLab application security testing provides continuous detection of vulnerabilities, during
development and after changes are deployed.

Application security testing scans your project's source code, dependencies, libraries, and
container images. Runtime vulnerabilities are detected through simulated attacks and fuzz testing
against your deployed application in a test environment.

During development, scans run automatically as part of CI/CD pipelines when code is committed or
merge requests are created. Security findings appear directly in merge requests and IDEs, notifying
developers before code is merged. This proactive approach reduces the cost and effort of fixing
issues later in development.

Outside the development cycle, you can run security scans on demand, or schedule them to run at
regular intervals. As vulnerability databases are updated with newly discovered threats and zero-day
exploits, new risks to your project's software libraries and container images are identified.
Together, these methods identify risks that weren't previously known during the original development
cycle.

For a click-through demo, see [Integrating security to the pipeline](https://gitlab.navattic.com/gitlab-scans).
<!-- Demo published on 2024-01-15 -->

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
