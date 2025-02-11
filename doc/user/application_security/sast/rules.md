---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SAST rules
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

GitLab SAST uses a set of [analyzers](analyzers.md) to scan code for potential vulnerabilities.
It automatically chooses which analyzers to run based on which programming languages are found in the repository.

Each analyzer processes the code, then uses rules to find possible weaknesses in source code.
The analyzer's rules determine what types of weaknesses it reports.

## Scope of rules

GitLab SAST focuses on security weaknesses and vulnerabilities. It does not aim to find general bugs or assess overall code quality or maintainability.

GitLab manages the detection ruleset with a focus on identifying actionable security weaknesses and vulnerabilities.
The ruleset is designed to provide broad coverage against the most impactful vulnerabilities while minimizing false positives (reported vulnerabilities where no vulnerability exists).

GitLab SAST is designed to be used in its default configuration, but you can [configure detection rules](#configure-rules-in-your-projects) if needed.

## Source of rules

### GitLab Advanced SAST

DETAILS:
**Tier:** Ultimate

GitLab creates, maintains, and supports the rules for [GitLab Advanced SAST](gitlab_advanced_sast.md).
Its rules are custom-built to leverage the GitLab Advanced SAST scanning engine's cross-file, cross-function analysis capabilities.
The GitLab Advanced SAST ruleset is not open source, and is not the same ruleset as any other analyzer.

For details of which types of vulnerabilities GitLab Advanced SAST detects, see [When vulnerabilities are reported](gitlab_advanced_sast.md#when-vulnerabilities-are-reported).

### Semgrep-based analyzer

GitLab creates, maintains, and supports the rules that are used in the Semgrep-based GitLab SAST analyzer.
This analyzer scans [many languages](_index.md#supported-languages-and-frameworks) in a single CI/CD pipeline job.
It combines:

- the Semgrep open-source engine.
- a GitLab-managed detection ruleset, which is managed in [the GitLab-managed open source `sast-rules` project](https://gitlab.com/gitlab-org/security-products/sast-rules).
- GitLab proprietary technology for [vulnerability tracking](_index.md#advanced-vulnerability-tracking).

### Other analyzers

GitLab SAST uses other analyzers to scan the remaining [supported languages](_index.md#supported-languages-and-frameworks).
The rules for these scans are defined in the upstream projects for each scanner.

## How rule updates are released

GitLab updates rules regularly based on customer feedback and internal research.
Rules are released as part of the container image for each analyzer.
You automatically receive updated analyzers and rules unless you [manually pin analyzers to a specific version](_index.md#pinning-to-minor-image-version).

Analyzers and their rules are updated [at least monthly](../_index.md#vulnerability-scanner-maintenance) if relevant updates are available.

### Rule update policies

Updates to SAST rules are not [breaking changes](../../../update/terminology.md#breaking-change).
This means that rules may be added, removed, or updated without prior notice.

However, to make rule changes more convenient and understandable, GitLab:

- Documents [rule changes](#important-rule-changes) that are planned or completed.
- [Automatically resolves](_index.md#automatic-vulnerability-resolution) findings from rules after they are removed for Semgrep-based analyzers.
- Enables you to [change the status on vulnerabilities where activity = "no longer detected" in bulk](../vulnerability_report/_index.md#change-status-of-vulnerabilities).
- Evaluates proposed rule changes for the impact they will have on existing vulnerability records.

## Configure rules in your projects

You should use the default SAST rules unless you have a specific reason to make a change.
The default ruleset is designed to be relevant to most projects.

However, you can [customize which rules are used](#apply-local-rule-preferences) or [control how rule changes are rolled out](#coordinate-rule-rollouts) if needed.

### Apply local rule preferences

You may want to customize the rules used in SAST scans because:

- Your organization has assigned priorities to specific vulnerability classes, such as choosing to address Cross-Site Scripting (XSS) or SQL Injection before other classes of vulnerabilities.
- You believe that a specific rule is a false positive result or isn't relevant in the context of your codebase.

To change which rules are used to scan your projects, adjust their severity, or apply other preferences, see [Customize rulesets](customize_rulesets.md).
If your customization would benefit other users, consider [reporting a problem to GitLab](#report-a-problem-with-a-gitlab-sast-rule).

### Coordinate rule rollouts

To control the rollout of rule changes, you can [pin SAST analyzers to a specific version](_index.md#pinning-to-minor-image-version).

If you want to make these changes at the same time across multiple projects, consider setting the variables in:

- [Group-level CI/CD variables](../../../ci/variables/_index.md#for-a-group).
- Custom CI/CD variables in a [Scan Execution Policy](../policies/scan_execution_policies.md).

## Report a problem with a GitLab SAST rule
<!-- This title is intended to match common search queries users might make. -->

GitLab welcomes contributions to the rulesets used in SAST.
Contributions might address:

- False positive results, where the potential vulnerability is incorrect.
- False negative results, where SAST did not report a potential vulnerability that truly exists.
- The name, severity rating, description, guidance, or other explanatory content for a rule.

If you believe a detection rule could be improved for all users, consider:

- Submitting a merge request to [the `sast-rules` repository](https://gitlab.com/gitlab-org/security-products/sast-rules). See the [contribution instructions](https://gitlab.com/gitlab-org/security-products/sast-rules#contributing) for details.
- Filing an issue in [the `gitlab-org/gitlab` issue tracker](https://gitlab.com/gitlab-org/gitlab/-/issues/).
  - Post a comment that says `@gitlab-bot label ~"group::static analysis" ~"Category:SAST"` so your issue lands in the correct triage workflow.

## Important rule changes

GitLab updates SAST rules [regularly](#how-rule-updates-are-released).
This section highlights the most important changes.
More details are available in release announcements and in the CHANGELOG links provided.

### Rule changes in the Semgrep-based analyzer

Key changes to the GitLab-managed ruleset for Semgrep-based scanning include:

- Beginning in GitLab 16.3, the GitLab Static Analysis and Vulnerability Research teams are working to remove rules that tend to produce too many false positive results or not enough actionable true positive results. Existing findings from these removed rules are [automatically resolved](_index.md#automatic-vulnerability-resolution); they no longer appear in the [Security Dashboard](../security_dashboard/_index.md#project-security-dashboard) or in the default view of the [Vulnerability Report](../vulnerability_report/_index.md). This work is tracked in [epic 10907](https://gitlab.com/groups/gitlab-org/-/epics/10907).
- In GitLab 16.0 through 16.2, the GitLab Vulnerability Research team updated the guidance that's included in each result.
- In GitLab 15.10, the `detect-object-injection` rule was [removed by default](https://gitlab.com/gitlab-org/gitlab/-/issues/373920) and its findings were [automatically resolved](_index.md#automatic-vulnerability-resolution).

For more details, see the [CHANGELOG for `sast-rules`](https://gitlab.com/gitlab-org/security-products/sast-rules/-/blob/main/CHANGELOG.md).

### Rule changes in other analyzers

See the CHANGELOG file for each [analyzer](analyzers.md) for details of the changes, including new or updated rules, included in each version.
