---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Dynamic Application Security Testing (DAST)

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

WARNING:
The DAST proxy-based analyzer was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/430966)
in GitLab 16.9 and [removed](https://gitlab.com/groups/gitlab-org/-/epics/11986) in GitLab 17.3.
This change is a breaking change. For instructions on how to migrate from the DAST proxy-based
analyzer to DAST version 5, see the
[proxy-based migration guide](proxy_based_to_browser_based_migration_guide.md). For instructions on
how to migrate from the DAST version 4 browser-based analyzer to DAST version 5, see the
[browser-based migration guide](browser_based_4_to_5_migration_guide.md).

Dynamic Application Security Testing (DAST) runs automated penetration tests to find vulnerabilities
in your web applications and APIs as they are running. DAST automates a hacker's approach and
simulates real-world attacks for critical threats such as cross-site scripting (XSS), SQL injection
(SQLi), and cross-site request forgery (CSRF) to uncover vulnerabilities and misconfigurations that
other security tools cannot detect.

DAST is completely language-neutral and examines your application from the outside in. DAST scans
can be run in a CI/CD pipeline, on a schedule, or run manually on demand. Using DAST during the
software development lifecycle enables you to uncover vulnerabilities in your application before
deployment in production. DAST is a foundational component of software security and should be used
together with the other GitLab security tools to provide a comprehensive security assessment of your
applications.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Dynamic Application Security Testing (DAST)](https://www.youtube.com/watch?v=nbeDUoLZJTo).

## GitLab DAST

GitLab DAST and API security analyzers are proprietary runtime tools, which provide broad security
coverage for modern-day web applications and APIs.

Use the DAST analyzers according to your needs:

- To scan web-based applications, including single page web applications, for known vulnerabilities,
  use the [DAST](browser/index.md) analyzer.
- To scan APIs for known vulnerabilities, use the [API security](../api_security_testing/index.md)
  analyzer. Technologies such as GraphQL, REST, and SOAP are supported.

Analyzers follow the architectural patterns described in [Secure your application](../index.md).
Each analyzer can be configured in the pipeline by using a CI/CD template and runs the scan in a
Docker container. Scans output a
[DAST report artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportsdast) which GitLab uses
to determine discovered vulnerabilities based on differences between scan results on the source and
target branches.

## View scan results

Detected vulnerabilities appear in [merge requests](../index.md#merge-request), the [pipeline security tab](../index.md#pipeline-security-tab),
and the [vulnerability report](../index.md#vulnerability-report).

1. To see all vulnerabilities detected, either:
   - From your project, select **Security & Compliance**, then **Vulnerability report**.
   - From your pipeline, select the **Security** tab.
   - From the merge request, go to the **Security scanning** widget and select **Full report** tab.

1. Select a DAST vulnerability's description. The following fields are examples of what a DAST analyzer may produce to aid investigation and rectification of the underlying cause. Each analyzer may output different fields.

   | Field            | Description                                                                                                                                                                   |
   |:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:------------------------------------------------------------------ |
   | Description      | Description of the vulnerability.                                                                                                                                             |
   | Evidence         | Evidence of the data found that verified the vulnerability. Often a snippet of the request or response, this can be used to help verify that the finding is a vulnerability.  |
   | Identifiers      | Identifiers of the vulnerability.                                                                                                                                             |
   | Links            | Links to further details of the detected vulnerability.                                                                                                                       |
   | Method           | HTTP method used to detect the vulnerability.                                                                                                                                 |
   | Project          | Namespace and project in which the vulnerability was detected.                                                                                                                |
   | Request Headers  | Headers of the request.                                                                                                                                                       |
   | Response Headers | Headers of the response received from the application.                                                                                                                        |
   | Response Status  | Response status received from the application.                                                                                                                                |
   | Scanner Type     | Type of vulnerability report.                                                                                                                                                 |
   | Severity         | Severity of the vulnerability.                                                                                                                                                |
   | Solution         | Details of a recommended solution to the vulnerability.                                                                                                                       |
   | URL              | URL at which the vulnerability was detected.                                                                                                                                  |

NOTE:
A pipeline may consist of multiple jobs, including SAST and DAST scanning. If any job
fails to finish for any reason, the security dashboard doesn't show DAST scanner output. For
example, if the DAST job finishes but the SAST job fails, the security dashboard doesn't show DAST
results. On failure, the analyzer outputs an
[exit code](../../../development/integrations/secure.md#exit-code).

### List URLs scanned

When DAST completes scanning, the merge request page states the number of URLs scanned.
Select **View details** to view the web console output which includes the list of scanned URLs.
