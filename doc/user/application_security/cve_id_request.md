---
stage: Govern
group: Threat Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# CVE ID request

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/41203) in GitLab 13.4, only for public projects on GitLab.com.

A [CVE](https://cve.mitre.org/index.html) identifier is assigned to a publicly-disclosed software
vulnerability. GitLab is a [CVE Numbering Authority](https://about.gitlab.com/security/cve/)
([CNA](https://cve.mitre.org/cve/cna.html)). For any public project you can request
a CVE identifier (ID).

Assigning a CVE ID to a vulnerability in your project helps your users stay secure and informed. For
example, [dependency scanning tools](../application_security/dependency_scanning/index.md) can
detect when vulnerable versions of your project are used as a dependency.

A common vulnerability workflow is:

1. Request a CVE for a vulnerability.
1. Reference the assigned CVE identifier in release notes.
1. Publish the vulnerability's details after the fix is released.

## Prerequisites

To [submit a CVE ID Request](#submit-a-cve-id-request) the following prerequisites must be met:

- The project is hosted on GitLab.com.
- The project is public.
- You are a maintainer of the project.
- The vulnerability's issue is [confidential](../project/issues/confidential_issues.md).

## Submit a CVE ID request

To submit a CVE ID request:

1. Go to the vulnerability's issue and select **Create CVE ID Request**. The new issue page of
   the [GitLab CVE project](https://gitlab.com/gitlab-org/cves) opens.

   ![CVE ID request button](img/cve_id_request_button.png)

1. In the **Title** box, enter a brief description of the vulnerability.

1. In the **Description** box, enter the following details:

   - A detailed description of the vulnerability
   - The project's vendor and name
   - Impacted versions
   - Fixed versions
   - The vulnerability class (a [CWE](https://cwe.mitre.org/data/index.html) identifier)
   - A [CVSS v3 vector](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator)

   ![New CVE ID request issue](img/new_cve_request_issue.png)

GitLab updates your CVE ID request issue when:

- Your submission is assigned a CVE.
- Your CVE is published.
- MITRE is notified that your CVE is published.
- MITRE has added your CVE in the NVD feed.

## CVE assignment

After a CVE identifier is assigned, you can reference it as required. Details of the vulnerability
submitted in the CVE ID request are published according to your schedule.
