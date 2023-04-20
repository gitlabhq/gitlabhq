---
type: reference
stage: Govern
group: Threat Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Vulnerability severity levels **(ULTIMATE)**

GitLab vulnerability analyzers attempt to return vulnerability severity level values whenever
possible. The following is a list of available GitLab vulnerability severity levels, ranked from
most to least severe:

- `Critical`
- `High`
- `Medium`
- `Low`
- `Info`
- `Unknown`

Most GitLab vulnerability analyzers are wrappers around popular open source scanning tools. Each
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

## SAST

|  GitLab analyzer                                                                                         | Outputs severity levels? | Native severity level type | Native severity level example      |
|----------------------------------------------------------------------------------------------------------|--------------------------|----------------------------|------------------------------------|
| [`security-code-scan`](https://gitlab.com/gitlab-org/security-products/analyzers/security-code-scan)     | **{check-circle}** Yes   | String                     | `CRITICAL`, `HIGH`, `MEDIUM` in [analyzer version 3.2.0 and later](https://gitlab.com/gitlab-org/security-products/analyzers/security-code-scan/-/blob/master/CHANGELOG.md#v320). In earlier versions, hardcoded to `Unknown`. |
| [`brakeman`](https://gitlab.com/gitlab-org/security-products/analyzers/brakeman)                         | **{check-circle}** Yes   | String                     | `HIGH`, `MEDIUM`, `LOW`            |
| [`sobelow`](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow)                           | **{check-circle}** Yes   | Not applicable             | Hardcodes all severity levels to `Unknown` |
| [`nodejs-scan`](https://gitlab.com/gitlab-org/security-products/analyzers/nodejs-scan)                   | **{check-circle}** Yes   | String                     | `INFO`, `WARNING`, `ERROR`         |
| [`flawfinder`](https://gitlab.com/gitlab-org/security-products/analyzers/flawfinder)                     | **{check-circle}** Yes   | Integer                    | `0`, `1`, `2`, `3`, `4`, `5`       |
| [`SpotBugs`](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs)                         | **{check-circle}** Yes   | Integer                    | `1`, `2`, `3`, `11`, `12`, `18`    |
| [`phpcs-security-audit`](https://gitlab.com/gitlab-org/security-products/analyzers/phpcs-security-audit) | **{check-circle}** Yes   | String                     | `ERROR`, `WARNING`                 |
| [`pmd-apex`](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex)                         | **{check-circle}** Yes   | Integer                    | `1`, `2`, `3`, `4`, `5`            |
| [`kubesec`](https://gitlab.com/gitlab-org/security-products/analyzers/kubesec)                           | **{check-circle}** Yes   | String                     | `CriticalSeverity`, `InfoSeverity` |
| [`secrets`](https://gitlab.com/gitlab-org/security-products/analyzers/secrets)                           | **{check-circle}** Yes   | Not applicable             | Hardcodes all severity levels to `Critical` |
| [`semgrep`](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)                           | **{check-circle}** Yes   | String                     | `error`, `warning`, `note`, `none` |
| [`kics`](https://gitlab.com/gitlab-org/security-products/analyzers/kics)                                 | **{check-circle}** Yes   | String                     | `error`, `warning`, `note`, `none` (gets mapped to `info` in [analyzer version 3.7.0 and later](https://gitlab.com/gitlab-org/security-products/analyzers/kics/-/releases/v3.7.0)) |

## Dependency Scanning

| GitLab analyzer                                                                          | Outputs severity levels?     | Native severity level type | Native severity level example       |
|------------------------------------------------------------------------------------------|------------------------------|----------------------------|-------------------------------------|
| [`gemnasium`](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)         | **{check-circle}** Yes       | CVSS v2.0 Rating and CVSS v3.1 Qualitative Severity Rating <sup>1</sup> | `(AV:N/AC:L/Au:S/C:P/I:P/A:N)`, `CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:H` |

The CVSS v3.1 rating is used to calculate the severity level. If it's not available, the CVSS v2.0 rating is used instead.

## Container Scanning

| GitLab analyzer                                                        | Outputs severity levels? | Native severity level type | Native severity level example                                |
|------------------------------------------------------------------------|--------------------------|----------------------------|--------------------------------------------------------------|
| [`container-scanning`](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning)| **{check-circle}** Yes | String | `Unknown`, `Low`, `Medium`, `High`, `Critical` |

When available, the vendor severity level takes precedence and is used by the analyzer. If that is not available then it falls back on the CVSS v3.1 rating. If that is also not available, then the CVSS v2.0 rating is used instead. Details on this implementation are available on the respective issues for [trivy](https://github.com/aquasecurity/trivy/issues/310) and [grype](https://github.com/anchore/grype/issues/287).

## Fuzz Testing

All fuzz testing results are reported as Unknown. They should be reviewed and triaged manually to find exploitable faults to prioritize for fixing.
