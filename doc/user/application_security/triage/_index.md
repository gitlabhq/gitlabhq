---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Triage
---

Triage is the second phase of the vulnerability management lifecycle: detect, triage, analyze,
remediate.

Triage is an ongoing process of evaluating each vulnerability to decide which need attention now and
which are not as critical. High-risk vulnerabilities are separated from medium or low risk threats.
It may not be possible or feasible to analyze and remediate every vulnerability. As part of a risk
management framework, triage helps ensure resources are applied where they're most effective. It's
best to triage vulnerabilities often, so that the number of vulnerabilities per triage cycle is
small and manageable.

The objective of the triage phase is to either confirm or dismiss each vulnerability. A confirmed
vulnerability continues to the analysis phase but a dismissed vulnerability does not.

Use the data contained in the [security dashboard](../security_dashboard/_index.md) and the
[vulnerability report](../vulnerability_report/_index.md) to help triage vulnerabilities efficiently
and effectively.

## Scope

The scope of the triage phase is all those vulnerabilities that have not been triaged. To list these
vulnerabilities, use the following filter criteria in the vulnerability report:

- **Status:** Needs triage

## Risk analysis

You should conduct vulnerability triage according to a risk assessment framework.
Depending on your industry or geographical location, compliance with a framework might be
required by law. If not, you should use a respected risk assessment framework, for example:

- SANS Institute [Vulnerability Management Framework](https://www.sans.org/blog/the-vulnerability-assessment-framework/)
- OWASP [Threat and Safeguard Matrix (TaSM)](https://owasp.org/www-project-threat-and-safeguard-matrix/)

Generally, the amount of time and effort spent on a vulnerability should be proportional to its
risk. For example, your triage strategy might be that only vulnerabilities of critical and high risk continue
to the analysis phase and the remainder are dismissed. You should make this decision according to your risk
threshold for vulnerabilities.

After you triage a vulnerability you should change its status to either:

- **Confirmed:** You have triaged this vulnerability and decided it requires analysis.
- **Dismissed:** You have triaged this vulnerability and decided against analysis.

When you dismiss a vulnerability you must provide a brief comment that states why it has been
dismissed. Dismissed vulnerabilities are ignored if detected in subsequent scans. Vulnerability
records are permanent but you can change a vulnerability's status at any time.

## Triage strategies

Use a risk assessment framework to help guide your vulnerability triage process. The following
strategies may also help.

### Prioritize vulnerabilities of significant risk

Prioritize vulnerabilities according to their risk.

- Use the [Vulnerability Prioritizer CI/CD component](../vulnerabilities/risk_assessment_data.md#vulnerability-prioritizer)
  to help prioritize vulnerabilities. For example, vulnerabilities in the CISA Known Exploited
  Vulnerabilities (KEV) catalogue should be analyzed and remediated as highest priority because
  these are known to have been exploited.
- For each group, go to the **Security dashboard** and view the **Project security status** panel. This groups
  projects by their highest-severity vulnerability. Use this grouping to prioritize triaging
  vulnerabilities in each project.
- Prioritize vulnerability triage on your highest-priority projects - for example, applications
  deployed to customers.
- For each project, view the vulnerability report. Group the vulnerabilities by severity and change
  the status of all vulnerabilities of critical and high severity to "Confirmed".

### Dismiss vulnerabilities of low risk

To ensure you focus on the right vulnerabilities it can help to triage in bulk those that are of low
risk.

- Vulnerabilities are sometimes detected but no longer detected in subsequent CI/CD pipelines. In
  this instance the vulnerability's activity is labeled as **No longer detected**. You might choose to
  dismiss these vulnerabilities if their severity is **low** or **info**. In the
  vulnerability report, use the filter criteria **Activity: No longer detected** and then bulk dismiss
  them. You can also automate this by using a [vulnerability management policy](../policies/vulnerability_management_policy.md).
- Dismiss vulnerabilities by identifier. If a vulnerability is mitigated by controls outside the
  application layer, you might choose to dismiss them. In the vulnerability report, use the
  **Identifier** filter to select all vulnerabilities matching the specific identifier and then
  bulk dismiss them.
