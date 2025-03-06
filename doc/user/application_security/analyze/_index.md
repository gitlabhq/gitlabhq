---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Analyze
---

Analysis is the third phase of the vulnerability management lifecycle: detect, triage, analyze,
remediate.

Analysis is the process of evaluating the details of a vulnerability to determine if it can and
should be remediated. Vulnerabilities can be triaged in bulk but analysis must be done individually.
Prioritize analysis of each vulnerability according to its severity and associated risk. As part of
a risk management framework, analysis helps ensure resources are applied where they're most
effective.

Use the data contained in the [security dashboard](../security_dashboard/_index.md) and the
[vulnerability report](../vulnerability_report/_index.md) to help narrow your focus. According the
vulnerability management lifecycle, only confirmed vulnerabilities need to be analyzed. To focus on
only these, use the following filter criteria in the vulnerability report:

- **Status:** Confirmed

Use additional vulnerability report filters to narrow your focus further. For more details, see
[Analysis strategies](#analysis-strategies).

## Risk analysis

You should conduct vulnerability analysis according to a risk assessment framework. If you're not
already using a risk assessment framework, consider the following:

- SANS Institute [Vulnerability Management Framework](https://www.sans.org/blog/the-vulnerability-assessment-framework/)
- OWASP [Threat and Safeguard Matrix (TaSM)](https://owasp.org/www-project-threat-and-safeguard-matrix/)

Calculating the risk score of a vulnerability depends on criteria that are specific to your
organization. A basic risk score formula is:

Risk = Likelihood x Impact

Both the likelihood and impact numbers vary according to the vulnerability and your environment.
Determining these numbers and calculating a risk score may require some information not available in
GitLab. Instead, you must calculate these according to your risk management framework. After
calculating these, record them in the issue you raised for the vulnerability.

Generally, the amount of time and effort spent on a vulnerability should be proportional to its
risk. For example, you might choose to analyze only vulnerabilities of critical and high risk and
dismiss the rest. You should make this decision according to your risk threshold for
vulnerabilities.

## Analysis strategies

Use a risk assessment framework to help guide your vulnerability analysis process. The following
strategies may also help.

### Prioritize vulnerabilities of highest severity

To help identify vulnerabilities of highest severity:

- If you've not already done this in the triage phase, use the
  [Vulnerability Prioritizer CI/CD component](../vulnerabilities/risk_assessment_data.md#vulnerability-prioritizer)
  to help prioritize vulnerabilities for analysis.
- For each group, use the following filter criteria in the vulnerability report to prioritize
  analysis of vulnerabilities by severity:
  - **Status:** Confirmed
  - **Activity:** Still detected
  - **Group by:** Severity
- Prioritize vulnerability triage on your highest-priority projects - for example, applications
  deployed to customers.

### Prioritize vulnerabilities that have a solution available

Some vulnerabilities have a solution available, for example "Upgrade from version 13.2 to 13.8".
This reduces the time taken to analyze and remediate these vulnerabilities. Some solutions are
available only if GitLab Duo is enabled.

Use the following filter criteria in the vulnerability report to identify vulnerabilities that have
a solution available.

- For vulnerabilities detected by SBOM scanning, use the criteria:
  - **Status:** Confirmed
  - **Activity:** Has a solution
- For vulnerabilities detected by SAST, use the criteria:
  - **Status:** Confirmed
  - **Activity:** Vulnerability Resolution available

## Vulnerability details and action

Every vulnerability has a [vulnerability page](../vulnerabilities/_index.md) which contains details
including when it was detected, how it was detected, its severity rating, and a complete log. Use
this information to help analyze a vulnerability.

The following tips may also help you analyze a vulnerability:

- Use [GitLab Duo Vulnerability Explanation](../vulnerabilities/_index.md#explaining-a-vulnerability)
  to help explain the vulnerability and suggest a remediation. Available only for vulnerabilities
  detected by SAST.
- Use [security training](../vulnerabilities/_index.md#view-security-training-for-a-vulnerability)
  provided by third-party training vendors to help understand the nature of a specific
  vulnerability.

After analyzing each confirmed vulnerability you should either:

- Leave its status as **Confirmed** if you decide it should be remediated.
- Change its status to **Dismissed** if you decide it should not be remediated.

If you confirm a vulnerability:

1. [Create an issue](../vulnerabilities/_index.md#create-a-gitlab-issue-for-a-vulnerability) to
   track, document, and manage the remediation work.
1. Continue to the remediation phase of the vulnerability management lifecycle.

If you dismiss a vulnerability you must provide a brief comment that states why you've dismissed
it. Dismissed vulnerabilities are ignored if detected in subsequent scans. Vulnerability records
are permanent but you can change a vulnerability's status at any time.
