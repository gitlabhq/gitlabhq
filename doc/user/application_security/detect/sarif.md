---
stage: Application Security Testing
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SARIF reports
description: Add findings from third-party SARIF scanners into GitLab vulnerability management.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/452042) in GitLab 18.11
  [with a feature flag](../../../administration/feature_flags/_index.md) named `sarif_ingestion`.
  Disabled by default.
- Enabled by default in GitLab 19.1.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/602748) in GitLab 19.2.
  Feature flag `sarif_ingestion` removed.

{{< /history >}}

Use third-party SARIF reports to add findings from any
[SARIF 2.1.0](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html) scanner
into GitLab vulnerability management. A CI/CD job runs a SARIF-producing scanner and
adds a SARIF artifact. GitLab parses, validates, and adds the artifacts as security
findings.

After you add the report, findings appear alongside findings from native GitLab scanners
in the following pages:

- The pipeline **Security** tab
- The project vulnerability report
- The security dashboard
- The merge request security widget
- Security policies

Third-party SARIF reports complement the built-in scanners that GitLab offers. Use them to integrate
a third-party scanner that GitLab does not provide natively, or to consolidate findings
from a tool you already run.

## Add SARIF reports

To add SARIF findings into GitLab:

Prerequisites:

- The Maintainer or Owner role for the project.
- A CI/CD job that produces a SARIF 2.1.0 file.

1. In your `.gitlab-ci.yml` file, define a job that runs the scanner and saves its
   SARIF output as an `artifacts:reports:sarif` artifact. Example:

   ```yaml
   sarif_scan:
     image: <scanner-image>
     script:
       - <scanner-command> --output sarif.json
     artifacts:
       reports:
         sarif: sarif.json
   ```

1. Commit and push the change. GitLab parses the SARIF file when the job completes.
1. View the added findings in the pipeline **Security** tab.

For the CI/CD artifact reference, see
[`artifacts:reports:sarif`](../../../ci/yaml/artifacts_reports.md#artifactsreportssarif).

## Assigned report types

GitLab assigns a vulnerability report type for each SARIF finding based on the finding's
location and identifiers. The type determines where the finding appears in
the vulnerability report and how it interacts with security policies.

GitLab evaluates the following rules in order and assigns the first type that matches the finding.

| Rule                                                                                         | Assigned report type |
|----------------------------------------------------------------------------------------------|----------------------|
| Any identifier is a CVE.                                                                     | Dependency scanning  |
| Any identifier is a secret-related CWE. <sup>1</sup>                                         | Secret detection     |
| Default (none of the rules matched)                                                          | SAST                 |

**Footnotes:**

1. The following CWEs are secret-related:

   - [CWE-798 (Hard-coded credentials)](https://cwe.mitre.org/data/definitions/798.html).
   - [CWE-259 (Hard-coded password)](https://cwe.mitre.org/data/definitions/259.html).
   - [CWE-321 (Hard-coded cryptographic key)](https://cwe.mitre.org/data/definitions/321.html).
   - [CWE-522 (Insufficiently protected credentials)](https://cwe.mitre.org/data/definitions/522.html).
   - [CWE-312 (Cleartext storage of sensitive information)](https://cwe.mitre.org/data/definitions/312.html).
   - [CWE-319 (Cleartext transmission of sensitive information)](https://cwe.mitre.org/data/definitions/319.html).
   - [CWE-256 (Plaintext storage of a password)](https://cwe.mitre.org/data/definitions/256.html).
   - [CWE-257 (Storing passwords in a recoverable format)](https://cwe.mitre.org/data/definitions/257.html).
   - [CWE-540 (Inclusion of sensitive information in source code)](https://cwe.mitre.org/data/definitions/540.html).

GitLab reads identifiers from three sources in a result and its rule, in this order:

1. `result.ruleId` when the entry matches the format `CVE-YYYY-N` or `CWE-N`.
1. `rule.properties.tags[]` when the entry matches the format `cwe:N`, `cwe-N`,
   `cve:YYYY-N`, or `cve-YYYY-N`.
1. `rule.relationships[]` when the relationship's
   `target.toolComponent.name` is `CWE`.

> [!note]
> Findings without a CVE or supported CWE identifier are assigned as SAST. To change the
> type that GitLab assigns, configure your scanner to emit a matching CVE
> or CWE identifier.

## SARIF field mapping

GitLab assigns SARIF fields to fields that are compatible with GitLab according to the following rules.

| GitLab field          | SARIF source                                                                          | Required    | Notes                                                                                                                                         |
|-----------------------|---------------------------------------------------------------------------------------|-------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| Severity              | See [Severity resolution](#severity-resolution)                                       | {{< no >}}  | Defaults to `medium` when no severity field is set.                                                                                           |
| Primary identifier    | `result.ruleId` is matched to the corresponding value in `run.tool.driver.rules[].id` | {{< yes >}} | Findings without a `ruleId` are not added.                                                                                                    |
| Secondary identifiers | `rule.properties.tags[]` and `rule.relationships[]`                                   | {{< no >}}  | Used to assign the report type.                                                                                                               |
| Location              | `result.locations[0].physicalLocation`                                                | {{< yes >}} | Findings without a physical location are not added.                                                                                           |
| Scanner name          | `run.tool.driver.name`                                                                | {{< yes >}} | Required for a [valid SARIF](https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/sarif-v2.1.0-errata01-os-complete.html#_Toc141790791) |
| Scanner vendor        | `run.tool.driver.organization`, then `run.tool.driver.informationUri`                 | {{< no >}}  | First non-empty value is used                                                                                                                 |
| Scanner version       | `run.tool.driver.version`, then `run.tool.driver.semanticVersion`                     | {{< no >}}  | First non-empty value is used                                                                                                                 |
| Suppression           | `result.suppressions[]`                                                               | {{< no >}}  | Suppressed results are skipped unless every suppression is `underReview` or `rejected`.                                                       |

## Severity resolution

GitLab resolves the severity of a SARIF finding by checking the following fields in
priority order. The first field that has a value is used.

1. `result.rank`. A float from `0.0` to `100.0`.
1. `rule.properties.security-severity`. A float from `0.0` to `10.0`. The value is multiplied by 10 before bucketing.
1. `result.properties.security-severity`. A float from `0.0` to `10.0`. The value is multiplied by 10 before bucketing.
1. `result.level`.
1. `rule.defaultConfiguration.level`.
1. `medium` as the default if no other matches.

Numeric scores from `result.rank` or `security-severity` are assigned as severities
using these ranges:

| Score (0-100) | Severity |
|---------------|----------|
| `0.0`-`9.9`   | Info     |
| `10.0`-`39.9` | Low      |
| `40.0`-`69.9` | Medium   |
| `70.0`-`89.9` | High     |
| `90.0`-`100`  | Critical |

SARIF `level` values are mapped as follows:

| `level`   | Severity |
|-----------|----------|
| `error`   | High     |
| `warning` | Medium   |
| `note`    | Low      |
| `none`    | Info     |

> [!note]
> GitLab assigns `level: error` to high, not critical. To report a critical finding, set
> `result.rank` to `90` or higher, or set `security-severity` to `9.0` or higher.

## Ingestion behavior

When the SARIF file is well-formed but some of the results cannot be added, GitLab uses
the percentage of results that it could not process to decide what to do with the scan as a whole.

| Drop rate     | Behavior                                                | Reported as           |
|---------------|---------------------------------------------------------|------------------------|
| 0%            | All findings are ingested.                              | No message.            |
| 1% to 50%     | The valid findings are ingested.                        | Warning with drop count. |
| More than 50% | The whole scan fails. No findings from the report are ingested. | Error with drop count.   |

GitLab cannot process a result in any of the following cases:

- The `ruleId` is missing.
- The `physicalLocation` is missing.
- Any of the required components used to generate the finding identifier are nil.
- A string field exceeds its [character limit](#limits).

The drop rate is calculated across the entire SARIF artifact, not for each `run` in the file. When
the share of unprocessable results across all runs exceeds the threshold, the
ingestion feedback is applied to every report emitted from the artifact.

Schema validation errors and unsupported SARIF versions cause the whole report
to be rejected, regardless of drop rate.

## Multi-tool reports

A SARIF file can contain multiple tool runs, each with its own `runs[]` entry. For each run,
GitLab groups the findings by inferred report type and creates a separate scan record
for each group. A run that contains findings of more than one inferred type
produces more than one scan record. Each scan uses the run's `tool.driver.name`
as its scanner.

Use multi-run reports to combine the output of several scanners into a single
artifact. For example, a job can run two scanners and emit a single SARIF file that contains two runs.

For the per-file run limit, see [limits](#limits).

## Limits

| Limit                                  | Default                                                       | Configurable |
|----------------------------------------|---------------------------------------------------------------|--------------|
| Maximum SARIF artifact size            | 10 MB (`ci_max_artifact_size_sarif`)                          | {{< yes >}}  |
| Maximum runs per SARIF file            | 20                                                            | {{< no >}}   |
| Maximum results per run                | 5,000                                                         | {{< no >}}   |
| Maximum rules per run                  | 25,000                                                        | {{< no >}}   |
| Maximum tags per rule                  | 10                                                            | {{< no >}}   |
| Maximum `rule.name` length             | 255 characters                                                | {{< no >}}   |
| Maximum `shortDescription.text` length | 1,024 characters                                              | {{< no >}}   |
| Maximum `fullDescription.text` length  | 1,024 characters, truncated to 255 when used as finding title | {{< no >}}   |
| Maximum `message.text` length          | 1,024 characters, truncated to 255 when used as finding title | {{< no >}}   |
| Maximum `helpUri` length               | 2,048 characters                                              | {{< no >}}   |
| Supported SARIF versions               | 2.1.0 only                                                    | {{< no >}}   |

When a per-run count exceeds its limit, GitLab process the first N entries and records a warning.
When a result has a string field that exceeds its character limit,
the whole result is skipped and counted toward the [drop rate](#ingestion-behavior).

For GitLab Self-Managed instances, an administrator can change configurable limits
through the [instance limits](../../../administration/instance_limits.md).

## Known issues

- SARIF findings assigned as SAST, dependency scanning, or secret detection are
  not deduplicated against findings from the equivalent native GitLab scanner.
  For details, see
  [issue 592410](https://gitlab.com/gitlab-org/gitlab/-/issues/592410).
- Although findings can be excluded through SARIF suppressions, GitLab does not create
  vulnerability dismissals based on suppressions. To dismiss a finding, use the vulnerability report.

## Related topics

- [`artifacts:reports:sarif`](../../../ci/yaml/artifacts_reports.md#artifactsreportssarif)
- [Pipeline security report](security_scanning_results.md)
- [Project vulnerability report](../vulnerability_report/_index.md)
- [Security policies](../policies/_index.md)
- [SARIF 2.1.0 specification](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html)
