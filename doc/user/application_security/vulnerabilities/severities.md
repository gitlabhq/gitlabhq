---
type: reference
stage: Secure
group: Threat Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
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

|  GitLab analyzer                                                                                       | Outputs severity levels? | Native severity level type | Native severity level example      |
|--------------------------------------------------------------------------------------------------------|--------------------------|----------------------------|------------------------------------|
| [`security-code-scan`](https://gitlab.com/gitlab-org/security-products/analyzers/security-code-scan)     | **{dotted-circle}** No   | N/A                        | N/A                                |
| [`brakeman`](https://gitlab.com/gitlab-org/security-products/analyzers/brakeman)                         | **{dotted-circle}** No   | N/A                        | N/A                                |
| [`sobelow`](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow)                           | **{check-circle}** Yes   | N/A                        | Hardcodes all severity levels to `Unknown` |
| [`nodejs-scan`](https://gitlab.com/gitlab-org/security-products/analyzers/nodejs-scan)                   | **{check-circle}** Yes   | String                     | `INFO`, `WARNING`, `ERROR`         |
| [`flawfinder`](https://gitlab.com/gitlab-org/security-products/analyzers/flawfinder)                     | **{check-circle}** Yes   | Integer                    | `0`, `1`, `2`, `3`, `4`, `5`       |
| [`eslint`](https://gitlab.com/gitlab-org/security-products/analyzers/eslint)                             | **{check-circle}** Yes   | N/A                        | Hardcodes all severity levels to `Unknown` |
| [`SpotBugs`](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs)                         | **{check-circle}** Yes   | Integer                    | `1`, `2`, `3`, `11`, `12`, `18`    |
| [`gosec`](https://gitlab.com/gitlab-org/security-products/analyzers/gosec)                               | **{check-circle}** Yes   | String                     | `HIGH`, `MEDIUM`, `LOW`            |
| [`bandit`](https://gitlab.com/gitlab-org/security-products/analyzers/bandit)                             | **{check-circle}** Yes   | String                     | `HIGH`, `MEDIUM`, `LOW`            |
| [`phpcs-security-audit`](https://gitlab.com/gitlab-org/security-products/analyzers/phpcs-security-audit) | **{check-circle}** Yes   | String                     | `ERROR`, `WARNING`                 |
| [`pmd-apex`](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex)                         | **{check-circle}** Yes   | Integer                    | `1`, `2`, `3`, `4`, `5`            |
| [`kubesec`](https://gitlab.com/gitlab-org/security-products/analyzers/kubesec)                           | **{check-circle}** Yes   | String                     | `CriticalSeverity`, `InfoSeverity` |
| [`secrets`](https://gitlab.com/gitlab-org/security-products/analyzers/secrets)                           | **{check-circle}** Yes   | N/A                        | Hardcodes all severity levels to `Critical` |
| [`semgrep`](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)                           | **{check-circle}** Yes   | String                     | `error`, `warning`, `note`, `none` |

## Dependency Scanning

| GitLab analyzer                                                                          | Outputs severity levels?     | Native severity level type | Native severity level example       |
|------------------------------------------------------------------------------------------|------------------------------|----------------------------|-------------------------------------|
| [`bundler-audit`](https://gitlab.com/gitlab-org/security-products/analyzers/bundler-audit) | **{check-circle}** Yes       | String                     | `low`, `medium`, `high`, `critical` |
| [`retire.js`](https://gitlab.com/gitlab-org/security-products/analyzers/retire.js)         | **{check-circle}** Yes       | String                     | `low`, `medium`, `high`, `critical` |
| [`gemnasium`](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)         | **{check-circle}** Yes       | CVSS v2.0 Rating and CVSS v3.1 Qualitative Severity Rating | `(AV:N/AC:L/Au:S/C:P/I:P/A:N)`, `CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:H` |

## Container Scanning

| GitLab analyzer                                                        | Outputs severity levels? | Native severity level type | Native severity level example                                |
|------------------------------------------------------------------------|--------------------------|----------------------------|--------------------------------------------------------------|
| [`container-scanning`](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning)| **{check-circle}** Yes | String | `Unknown`, `Low`, `Medium`, `High`, `Critical` |

## Fuzz Testing

All fuzz testing results are reported as Unknown. They should be reviewed and triaged manually to find exploitable faults to prioritize for fixing.
