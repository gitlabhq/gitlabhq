---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Vulnerability severity levels
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

GitLab vulnerability analyzers attempt to return vulnerability severity level values whenever
possible. The following is a list of available GitLab vulnerability severity levels, ranked from
most to least severe:

- `Critical`
- `High`
- `Medium`
- `Low`
- `Info`
- `Unknown`

GitLab analyzers make an effort to fit the severity descriptions below, but they may not always be correct. Analyzers and scanners provided by third-party vendors may not follow the same classification.

## Critical severity

Vulnerabilities identified at the Critical Severity level should be investigated immediately. Vulnerabilities at this level assume exploitation of the flaw could lead to full system or data compromise. Examples of critical severity flaws are Command/Code Injection and SQL Injection. Typically these flaws are rated with CVSS 3.1 between 9.0-10.0.

## High severity

High severity vulnerabilities can be characterized as flaws that may lead to an attacker accessing application resources or unintended exposure of data. Examples of high severity flaws are External XML Entity Injection (XXE), Server Side Request Forgery (SSRF), Local File Include/Path Traversal and certain forms of Cross-Site Scripting (XSS). Typically these flaws are rated with CVSS 3.1 between 7.0-8.9.

## Medium severity

Medium severity vulnerabilities usually arise from misconfiguration of systems or lack of security controls. Exploitation of these vulnerabilities may lead to accessing a restricted amount of data or could be used in conjunction with other flaws to gain unintended access to systems or resources. Examples of medium severity flaws are reflected XSS, incorrect HTTP session handling, and missing security controls. Typically these flaws are rated with CVSS 3.1 between 4.0-6.9.

## Low severity

Low severity vulnerabilities contain flaws that may not be directly exploitable but introduce unnecessary weakness to an application or system. These flaws are usually due to missing security controls, or unnecessary disclose information about the application environment. Examples of low severity vulnerabilities are missing cookie security directives, verbose error or exception messages. Typically these flaws are rated with CVSS 3.1 between 0.1-3.9.

## Info severity

Info level severity vulnerabilities contain information that may have value, but are not necessarily associated to a particular flaw or weakness. Typically these issues do not have a CVSS rating.

## Unknown severity

Issues identified at this level do not have enough context to clearly demonstrate severity.  

GitLab vulnerability analyzers include popular open source scanning tools. Each
open source scanning tool provides their own native vulnerability severity level value. These values
can be one of the following:

| Native vulnerability severity level type                                                                                          | Examples                                       |
|-----------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------|
| String                                                                                                                            | `WARNING`, `ERROR`, `Critical`, `Negligible`   |
| Integer                                                                                                                           | `1`, `2`, `5`                                  |
| [CVSS v2.0 Rating](https://nvd.nist.gov/vuln-metrics/cvss)                                                                        | `(AV:N/AC:L/Au:S/C:P/I:P/A:N)`                 |
| [CVSS v3.1 Qualitative Severity Rating](https://www.first.org/cvss/v3.1/specification-document#Qualitative-Severity-Rating-Scale) | `CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:H` |

To provide consistent vulnerability severity level values, the GitLab vulnerability analyzers
convert from the above values to a standardized GitLab vulnerability severity level, as outlined in
the following tables:

## Container Scanning

| GitLab analyzer                                                        | Outputs severity levels? | Native severity level type | Native severity level example                                |
|------------------------------------------------------------------------|--------------------------|----------------------------|--------------------------------------------------------------|
| [`container-scanning`](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning)| **{check-circle}** Yes | String | `Unknown`, `Low`, `Medium`, `High`, `Critical` |

When available, the vendor severity level takes precedence and is used by the analyzer. If that is not available then it falls back on the CVSS v3.1 rating. If that is also not available, then the CVSS v2.0 rating is used instead. Details on this implementation are available on the issue for [trivy](https://github.com/aquasecurity/trivy/issues/310).

## DAST

| GitLab analyzer                                                                          | Outputs severity levels?     | Native severity level type | Native severity level example       |
|------------------------------------------------------------------------------------------|------------------------------|----------------------------|-------------------------------------|
| [`Browser-based DAST`](../dast/browser/_index.md)         | **{check-circle}** Yes       | String | `HIGH`, `MEDIUM`, `LOW`, `INFO` |

## API security testing

| GitLab analyzer                                                                          | Outputs severity levels?     | Native severity level type | Native severity level example       |
|------------------------------------------------------------------------------------------|------------------------------|----------------------------|-------------------------------------|
| [`API security testing`](../api_security_testing/_index.md)         | **{check-circle}** Yes       | String | `HIGH`, `MEDIUM`, `LOW` |

## Dependency Scanning

| GitLab analyzer                                                                          | Outputs severity levels?     | Native severity level type | Native severity level example       |
|------------------------------------------------------------------------------------------|------------------------------|----------------------------|-------------------------------------|
| [`gemnasium`](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)         | **{check-circle}** Yes       | CVSS v2.0 Rating and CVSS v3.1 Qualitative Severity Rating <sup>1</sup> | `(AV:N/AC:L/Au:S/C:P/I:P/A:N)`, `CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:H` |

The CVSS v3.1 rating is used to calculate the severity level. If it's not available, the CVSS v2.0 rating is used instead.

## Fuzz Testing

All fuzz testing results are reported as Unknown. They should be reviewed and triaged manually to find exploitable faults to prioritize for fixing.

## SAST

|  GitLab analyzer                                                                 | Outputs severity levels? | Native severity level type | Native severity level example      |
|----------------------------------------------------------------------------------|--------------------------|----------------------------|------------------------------------|
| [`kubesec`](https://gitlab.com/gitlab-org/security-products/analyzers/kubesec)   | **{check-circle}** Yes   | String                     | `CriticalSeverity`, `InfoSeverity` |
| [`pmd-apex`](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex) | **{check-circle}** Yes   | Integer                    | `1`, `2`, `3`, `4`, `5`            |
| [`semgrep`](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)   | **{check-circle}** Yes   | String                     | `error`, `warning`, `note`, `none` |
| [`sobelow`](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow)   | **{check-circle}** Yes   | Not applicable             | Hardcodes all severity levels to `Unknown` |
| [`SpotBugs`](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs) | **{check-circle}** Yes   | Integer                    | `1`, `2`, `3`, `11`, `12`, `18`    |

## IaC Scanning

|  GitLab analyzer                                                                                         | Outputs severity levels? | Native severity level type | Native severity level example      |
|----------------------------------------------------------------------------------------------------------|--------------------------|----------------------------|------------------------------------|
| [`kics`](https://gitlab.com/gitlab-org/security-products/analyzers/kics)                                 | **{check-circle}** Yes   | String                     | `error`, `warning`, `note`, `none` (gets mapped to `info` in [analyzer version 3.7.0 and later](https://gitlab.com/gitlab-org/security-products/analyzers/kics/-/releases/v3.7.0)) |

### KICS severity mapping

The KICS analyzer maps its output to SARIF severities which, in turn, are mapped to GitLab
severities. Use the table below to see the corresponding severity in the GitLab Vulnerability
Report.

| KICS severity | KICS SARIF severity | GitLab severity |
|---------------|---------------------|-----------------|
| CRITICAL      | error               | Critical        |
| HIGH          | error               | Critical        |
| MEDIUM        | warning             | Medium          |
| LOW           | note                | Info            |
| INFO          | none                | Info            |
| invalid       | none                | Info            |

Note that while both KICS and GitLab define `High` severity, SARIF doesn't, which means `HIGH`
vulnerabilities in KICS are mapped to `Critical` in GitLab. This is expected.

[Source code for GitLab mapping](https://gitlab.com/gitlab-org/security-products/analyzers/report/-/blob/902c7dcb5f3a0e551223167931ebf39588a0193a/sarif/sarif.go#L279-315).

## Secret Detection

The GitLab [`secrets`](https://gitlab.com/gitlab-org/security-products/analyzers/secrets) analyzer hardcodes all severity levels to `Critical`.
[Epic 10320](https://gitlab.com/groups/gitlab-org/-/epics/10320) proposes to adopt more granular severity ratings.
