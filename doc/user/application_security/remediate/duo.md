---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Resolve vulnerabilities with AI
---

{{< details >}}

- Tier: Ultimate
- Add-on: GitLab Duo Enterprise, GitLab Duo with Amazon Q
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Model information" >}}

- [Default LLM](../../gitlab_duo/model_selection.md#default-models)
- LLM for Amazon Q: Amazon Q Developer
- Available on [GitLab Duo with self-hosted models](../../../administration/gitlab_duo_self_hosted/_index.md): Yes

{{< /collapsible >}}

GitLab Duo Vulnerability Resolution helps you automatically resolve security vulnerabilities.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch an overview](https://www.youtube.com/watch?v=VJmsw_C125E&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW)

## Use AI assistance responsibly

As with all AI-based systems, we can't guarantee that the large language model produces correct results every time.
You should always review the proposed change before merging it. When reviewing, check that:

- Your application's existing functionality is preserved.
- The vulnerability is resolved in accordance with your organization's standards.

## Prerequisites

- You must be a member of the project.
- The vulnerability must be a SAST finding from a supported analyzer:
  - Any [GitLab-supported analyzer](../sast/analyzers.md).
  - A properly integrated third-party SAST scanner that reports the vulnerability location and a CWE Identifier for each vulnerability.
- The vulnerability must be of a [supported type](#supported-vulnerabilities-for-vulnerability-resolution).

Learn more about [how to enable all GitLab Duo features](../../gitlab_duo/turn_on_off.md).

## Supported vulnerabilities for Vulnerability Resolution

To ensure that suggested resolutions are high-quality, Vulnerability Resolution is available for a specific set of vulnerabilities.
The system decides whether to offer Vulnerability Resolution based on the vulnerability's Common Weakness Enumeration (CWE) identifier.

We selected the current set of vulnerabilities based on testing by automated systems and security experts.
We are actively working to expand coverage to more types of vulnerabilities.

<details><summary style="color:#5943b6; margin-top: 1em;"><a>View the complete list of supported CWEs for Vulnerability Resolution</a></summary>

<ul>
  <li>CWE-23: Relative Path Traversal</li>
  <li>CWE-73: External Control of File Name or Path</li>
  <li>CWE-78: Improper Neutralization of Special Elements used in an OS Command ('OS Command Injection')</li>
  <li>CWE-80: Improper Neutralization of Script-Related HTML Tags in a Web Page (Basic XSS)</li>
  <li>CWE-89: Improper Neutralization of Special Elements used in an SQL Command ('SQL Injection')</li>
  <li>CWE-116: Improper Encoding or Escaping of Output</li>
  <li>CWE-118: Incorrect Access of Indexable Resource ('Range Error')</li>
  <li>CWE-119: Improper Restriction of Operations within the Bounds of a Memory Buffer</li>
  <li>CWE-120: Buffer Copy without Checking Size of Input ('Classic Buffer Overflow')</li>
  <li>CWE-126: Buffer Over-read</li>
  <li>CWE-190: Integer Overflow or Wraparound</li>
  <li>CWE-200: Exposure of Sensitive Information to an Unauthorized Actor</li>
  <li>CWE-208: Observable Timing Discrepancy</li>
  <li>CWE-209: Generation of Error Message Containing Sensitive Information</li>
  <li>CWE-272: Least Privilege Violation</li>
  <li>CWE-287: Improper Authentication</li>
  <li>CWE-295: Improper Certificate Validation</li>
  <li>CWE-297: Improper Validation of Certificate with Host Mismatch</li>
  <li>CWE-305: Authentication Bypass by Primary Weakness</li>
  <li>CWE-310: Cryptographic Issues</li>
  <li>CWE-311: Missing Encryption of Sensitive Data</li>
  <li>CWE-323: Reusing a Nonce, Key Pair in Encryption</li>
  <li>CWE-327: Use of a Broken or Risky Cryptographic Algorithm</li>
  <li>CWE-328: Use of Weak Hash</li>
  <li>CWE-330: Use of Insufficiently Random Values</li>
  <li>CWE-338: Use of Cryptographically Weak Pseudo-Random Number Generator (PRNG)</li>
  <li>CWE-345: Insufficient Verification of Data Authenticity</li>
  <li>CWE-346: Origin Validation Error</li>
  <li>CWE-352: Cross-Site Request Forgery</li>
  <li>CWE-362: Concurrent Execution using Shared Resource with Improper Synchronization ('Race Condition')</li>
  <li>CWE-369: Divide By Zero</li>
  <li>CWE-377: Insecure Temporary File</li>
  <li>CWE-378: Creation of Temporary File With Insecure Permissions</li>
  <li>CWE-400: Uncontrolled Resource Consumption</li>
  <li>CWE-489: Active Debug Code</li>
  <li>CWE-521: Weak Password Requirements</li>
  <li>CWE-539: Use of Persistent Cookies Containing Sensitive Information</li>
  <li>CWE-599: Missing Validation of OpenSSL Certificate</li>
  <li>CWE-611: Improper Restriction of XML External Entity Reference</li>
  <li>CWE-676: Use of potentially dangerous function</li>
  <li>CWE-704: Incorrect Type Conversion or Cast</li>
  <li>CWE-754: Improper Check for Unusual or Exceptional Conditions</li>
  <li>CWE-770: Allocation of Resources Without Limits or Throttling</li>
  <li>CWE-1004: Sensitive Cookie Without 'HttpOnly' Flag</li>
  <li>CWE-1275: Sensitive Cookie with Improper SameSite Attribute</li>
</ul>
</details>

## Data shared with third-party AI APIs for Vulnerability Resolution

The following data is shared with third-party AI APIs:

- Vulnerability name
- Vulnerability description
- Identifiers (CWE, OWASP)
- Entire file that contains the vulnerable lines of code
- Vulnerable lines of code (line numbers)

## Workflows

Vulnerablilty Resolution is available in different workflows. You can:

- Resolve existing vulnerabilities from the Vulnerability Report.
- Resolve vulnerabilities in the context of a merge request.

### Resolve an existing vulnerability from the Vulnerability Report

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10779) in GitLab 16.7 as an [experiment](../../../policy/development_stages_support.md#experiment) on GitLab.com.
- Changed to beta in GitLab 17.3.
- Changed to require GitLab Duo add-on in GitLab 17.6 and later.

{{< /history >}}

#### Find vulnerabilities that support Vulnerability Resolution

{{< history >}}

- Vulnerability Resolution activity icon:
  - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/15036) in GitLab 17.5 with a flag named [`vulnerability_report_vr_badge`](https://gitlab.com/gitlab-org/gitlab/-/issues/486549). Disabled by default.
  - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171718) in GitLab 17.6.
  - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/503568) in GitLab 18.0. Feature flag `vulnerability_report_vr_badge` removed.

{{< /history >}}

To resolve a vulnerability:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Secure** > **Vulnerability report**.
1. Optional. To remove the default filters, select **Clear** ({{< icon name="clear" >}}).
1. Above the list of vulnerabilities, select the filter bar.
1. In the dropdown list that appears, select **Activity**, then select **Vulnerability Resolution available** in the **GitLab Duo (AI)** category.
1. Select outside the filter field. The vulnerability severity totals and list of matching vulnerabilities are updated.
1. Select the SAST vulnerability you want resolved.
   - A blue icon is shown next to vulnerabilities that support Vulnerability Resolution.

#### Resolve the selected vulnerability

After you've selected a vulnerability that supports resolution:

1. In the upper-right corner, select **Resolve with AI**. If this project is a public project be aware that creating an MR will publicly expose the vulnerability and offered resolution. To create the MR privately, [create a private fork](../../project/merge_requests/confidential.md), and repeat this process.
1. Add an additional commit to the MR. This forces a new pipeline to run.
1. After the pipeline is complete, on the [pipeline security tab](../detect/security_scanning_results.md), confirm that the vulnerability no longer appears.
1. On the vulnerability report, [manually update the vulnerability](../vulnerability_report/_index.md#change-status-of-vulnerabilities).

A merge request containing the AI remediation suggestions is opened. Review the suggested changes,
then process the merge request according to your standard workflow.

Provide feedback on this feature in [issue 476553](https://gitlab.com/gitlab-org/gitlab/-/issues/476553).

### Resolve a vulnerability in a merge request

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14862) in GitLab 17.6.
- [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175150) in GitLab 17.7.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/185452) in GitLab 17.11. Feature flag `resolve_vulnerability_in_mr` removed.

{{< /history >}}

You can use GitLab Duo Vulnerability Resolution in a merge request to fix vulnerabilities before they're merged.
Vulnerability Resolution automatically creates a merge request suggestion comment that resolves the vulnerability finding.

To resolve a vulnerability finding:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Merge requests**.
1. Select a merge request.
   - Vulnerability findings supported by Vulnerability Resolution are indicated by the tanuki AI icon ({{< icon name="tanuki-ai" >}}).
1. Select the supported findings to open the security finding dialog.
1. In the lower-right corner, select **Resolve with AI**.

A comment containing the AI remediation suggestions is opened in the merge request. Review the suggested changes, then apply the merge request suggestion according to your standard workflow.

Provide feedback on this feature in [issue 476553](https://gitlab.com/gitlab-org/gitlab/-/issues/476553).

## Troubleshooting

Vulnerability Resolution sometimes cannot generate a suggested fix. Common causes include:

- False positive detected:
  - Before proposing a fix, the AI model assesses whether the vulnerability is valid. It may judge that the vulnerability is not a true vulnerability, or isn't worth fixing.
  - This can happen if the vulnerability occurs in test code. Your organization might still choose to fix vulnerabilities even if they happen in test code, but models sometimes assess these to be false positives.
  - If you agree that the vulnerability is a false-positive or is not worth fixing, you should [dismiss the vulnerability](../vulnerabilities/_index.md#vulnerability-status-values) and [select a matching reason](../vulnerabilities/_index.md#vulnerability-dismissal-reasons).
    - To customize your SAST configuration or report a problem with a GitLab SAST rule, see [SAST rules](../sast/rules.md).
- Temporary or unexpected error:
  - The error message may state that `an unexpected error has occurred`, `the upstream AI provider request timed out`, `something went wrong`, or a similar cause.
  - These errors may be caused by temporary problems with the AI provider or with GitLab Duo.
  - A new request may succeed, so you can try to resolve the vulnerability again.
  - If you continue to see these errors, contact GitLab for assistance.
- `Resolution target could not be found in the merge request, unable to create suggestion` error:
  - This error may occur when the target branch has not run a full security scan pipeline. See the [merge request documentation](../detect/security_scanning_results.md).
