---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Vulnerability risk assessment data
---

Use vulnerability risk data to help assess the potential impact to your environment.

- Severity: Each vulnerability is assigned a standardized GitLab severity value.

- For vulnerabilities in the [Common Vulnerabilities and Exposures (CVE)](https://www.cve.org/) catalog, the following data can be retrieved by using a GraphQL query:
  - Likelihood of exploitation: [Exploit Prediction Scoring System (EPSS)](https://www.first.org/epss) score.
  - Existence of known exploits: [Known Exploited Vulnerabilities (KEV)](https://www.cisa.gov/known-exploited-vulnerabilities-catalog) status.

Use this data to help prioritize remediation and mitigation actions. For example, a vulnerability
with medium severity and a high EPSS score may require mitigation sooner than a vulnerability with a
high severity and a low EPSS score.

## EPSS

> - Introduced in GitLab 17.4 [with flags](../../../administration/feature_flags.md) named `epss_querying` (in issue [470835](https://gitlab.com/gitlab-org/gitlab/-/issues/470835)) and `epss_ingestion` (in issue [467672](https://gitlab.com/gitlab-org/gitlab/-/issues/467672)). Disabled by default.
> - Renamed to `cve_enrichment_querying` and `cve_enrichment_ingestion` respectively and [enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/481431) in GitLab 17.6.
> - [Generally available](https://gitlab.com/groups/gitlab-org/-/epics/11544) in GitLab 17.7. Feature flags `cve_enrichment_querying` and `cve_enrichment_ingestion` removed.

The EPSS score provides an estimate of the likelihood a vulnerability in the CVE catalog will be
exploited in the next 30 days. EPSS assigns each CVE a score between 0 to 1 (equivalent to 0% to
100%).

## KEV

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/499407) in GitLab 17.7.

The KEV catalog lists vulnerabilities that are known to have been exploited. You should prioritize
the remediation of vulnerabilities in the KEV catalog above other vulnerabilities. Attacks using
these vulnerabilities have occurred and the exploitation method is likely known to attackers.

## Query risk assessment data

Use the GraphQL API to query the severity, EPSS, and KEV values of vulnerabilities in a project.

The `Vulnerability` type in the GraphQL API has a `cveEnrichment` field, which is populated when the
`identifiers` field contains a CVE identifier. The `cveEnrichment` field contains the CVE ID, EPSS
score, and KEV status for the vulnerability. EPSS scores are rounded to the second decimal digit.

For example, the following GraphQL API query returns all vulnerabilities in a given project and
their CVE ID, EPSS score, and KEV status (`isKnownExploit`). Run the query in the
[GraphQL explorer](../../../api/graphql/_index.md#interactive-graphql-explorer) or any other GraphQL
client.

```graphql
{
  project(fullPath: "<full/path/to/project>") {
    vulnerabilities {
      nodes {
        severity
        identifiers {
          externalId
          externalType
        }
        cveEnrichment {
          epssScore
          isKnownExploit
          cve
        }
      }
    }
  }
}
```

Example output:

```json
{
  "data": {
    "project": {
      "vulnerabilities": {
        "nodes": [
          {
            "severity": "CRITICAL",
            "identifiers": [
              {
                "externalId": "CVE-2019-3859",
                "externalType": "cve"
              }
            ],
            "cveEnrichment": {
              "epssScore": 0.2,
              "isKnownExploit": false,
              "cve": "CVE-2019-3859"
            }
          },
          {
            "severity": "CRITICAL",
            "identifiers": [
              {
                "externalId": "CVE-2016-8735",
                "externalType": "cve"
              }
            ],
            "cveEnrichment": {
              "epssScore": 0.94,
              "isKnownExploit": true,
              "cve": "CVE-2016-8735"
            }
          },
        ]
      }
    }
  },
  "correlationId": "..."
}
```

## Vulnerability Prioritizer

DETAILS:
**Status:** Experiment

Use the [Vulnerability Prioritizer CI/CD component](https://gitlab.com/explore/catalog/components/vulnerability-prioritizer) to help prioritize a project's vulnerabilities (namely CVEs). The component outputs a prioritization report in the `vulnerability-prioritizer` job's output.

Vulnerabilities are listed in the following order:

1. Vulnerabilities with known exploitation (KEV) are top priority.
1. Higher EPSS scores (closer to 1) are prioritized.
1. Severities are ordered from `Critical` to `Low`.

Only vulnerabilities detected by [dependency scanning](../dependency_scanning/_index.md) and [container scanning](../container_scanning/_index.md) are included because the Vulnerability Prioritizer CI/CD component requires data only available in Common Vulnerabilities and Exposures (CVE) records. Moreover, only [detected (**Needs triage**) and confirmed](../vulnerabilities/_index.md#vulnerability-status-values) vulnerabilities are shown.

To add the Vulnerability Prioritizer CI/CD component to your project's CI/CD pipeline, see the [Vulnerability Prioritizer documentation](https://gitlab.com/components/vulnerability-prioritizer).
