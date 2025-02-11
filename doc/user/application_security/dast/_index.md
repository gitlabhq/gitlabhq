---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Dynamic Application Security Testing (DAST)
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

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
  use the [DAST](browser/_index.md) analyzer.
- To scan APIs for known vulnerabilities, use the [API security](../api_security_testing/_index.md)
  analyzer. Technologies such as GraphQL, REST, and SOAP are supported.

Analyzers follow the architectural patterns described in [Secure your application](../_index.md).
Each analyzer can be configured in the pipeline by using a CI/CD template and runs the scan in a
Docker container. Scans output a
[DAST report artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportsdast) which GitLab uses
to determine discovered vulnerabilities based on differences between scan results on the source and
target branches.

## View scan results

Detected vulnerabilities appear in [merge requests](../detect/security_scan_results.md#merge-request), the [pipeline security tab](../vulnerability_report/pipeline.md),
and the [vulnerability report](../vulnerability_report/_index.md).

NOTE:
A pipeline may consist of multiple jobs, including SAST and DAST scanning. If any job
fails to finish for any reason, the security dashboard doesn't show DAST scanner output. For
example, if the DAST job finishes but the SAST job fails, the security dashboard doesn't show DAST
results. On failure, the analyzer outputs an
[exit code](../../../development/integrations/secure.md#exit-code).

### List URLs scanned

When DAST completes scanning, the merge request page states the number of URLs scanned.
Select **View details** to view the web console output which includes the list of scanned URLs.
