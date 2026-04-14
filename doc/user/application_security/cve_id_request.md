---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CVE ID request
description: Vulnerability tracking and security disclosure.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

A [Common Vulnerabilities and Exposures ID](https://cve.mitre.org/index.html) (CVE ID) is a unique
identifier assigned to publicly-disclosed software vulnerabilities. GitLab is a
[CVE Numbering Authority](<https://cve.mitre.org/cve/cna.html>) (CNA), which means we can assign CVE
identifiers to vulnerabilities in projects hosted on GitLab.com.

For public projects, you can request a CVE identifier to keep users informed about security issues.
For example, GitLab [dependency scanning tools](dependency_scanning/_index.md) can detect when your
project uses vulnerable versions of a dependency.

A common vulnerability workflow is:

1. Request a CVE for a vulnerability.
1. Reference the assigned CVE identifier in release notes.
1. Publish the vulnerability's details after the fix is released.

## Submit a CVE ID request

Prerequisites:

- The Maintainer or Owner role for the project.
- The project is hosted on GitLab.com.
- The project is public.
- The vulnerability's issue is [confidential](../project/issues/confidential_issues.md).

To submit a CVE ID request:

1. Go to the vulnerability's issue and select **Create CVE ID Request**. The new issue page of
   the [GitLab CVE project](https://gitlab.com/gitlab-org/cves) opens.
1. In the **Title** box, enter a brief description of the vulnerability.
1. In the **Description** box, enter the following details:

   - A detailed description of the vulnerability
   - The project's vendor and name
   - Impacted versions
   - Fixed versions
   - The vulnerability class (a [CWE](https://cwe.mitre.org/data/index.html) identifier)
   - A [CVSS v3 vector](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator)

GitLab updates your CVE ID request issue when:

- Your submission is assigned a CVE.
- Your CVE is published.
- MITRE is notified that your CVE is published.
- MITRE has added your CVE in the NVD feed.

## CVE assignment

After a CVE identifier is assigned, you can reference it as required. Details of the vulnerability
submitted in the CVE ID request are published according to your schedule.
