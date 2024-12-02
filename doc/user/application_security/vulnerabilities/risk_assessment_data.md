---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Vulnerability risk assessment data

Use vulnerability risk data to help assess the potential impact to your environment.

Each [vulnerability's details page](index.md) contains risk data, including:

- Severity - [Common Vulnerability Scoring System (CVSS)](severities.md)
- Likelihood of exploitation - [EPSS](#epss)

With multiple data points you can better prioritize remediation and mitigation actions.
For example, a vulnerability with medium severity and a high EPSS score may require mitigation
sooner than a vulnerability with a high severity and a low EPSS score.

## EPSS

> - Introduced in GitLab 17.4 [with flags](../../../administration/feature_flags.md) named `epss_querying` (in issue [470835](https://gitlab.com/gitlab-org/gitlab/-/issues/470835)) and `epss_intgestion` (in issue [467672](https://gitlab.com/gitlab-org/gitlab/-/issues/467672)). Disabled by default.
> - Renamed to `cve_enrichment_querying` and `cve_enrichment_ingestion` respectively and [enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/481431) in GitLab 17.6.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

[Exploit Prediction Scoring System (EPSS)](https://www.first.org/epss) provides an estimate of the likelihood a vulnerability (namely [CVE](https://www.cve.org/)) will be exploited in the next 30 days. EPSS gives each CVE a score between 0 to 1 (equivalent to 0% to 100%).

### Querying EPSS

You can query the EPSS score of vulnerabilities by using the [GraphQL API](../../../api/graphql/index.md). Scores are attached to CVEs and are rounded to the second decimal digit.

The `cveEnrichment` field in the GitLab API model contains the CVE ID and an EPSS score for a given CVE. It is accessible through the `Vulnerability` type.

For example, the following GraphQL query returns all vulnerabilities in a given project and
their EPSS scores. Run the query in the
[GraphQL explorer](../../../api/graphql/index.md#interactive-graphql-explorer) or any other GraphQL client.

```graphql
{
  project(fullPath: "<full/path/to/project>") {
    vulnerabilities {
      nodes {
        identifiers {
          externalId
          externalType
        }
        cveEnrichment {
          epssScore
          cve
        }
      }
    }
  }
}
```

Sample output:

```json
{
  "data": {
    "project": {
      "vulnerabilities": {
        "nodes": [
          {
            "identifiers": [
              {
                "externalId": "CVE-2024-37371",
                "externalType": "cve"
              }
            ],
            "cveEnrichment": {
              "epssScore": 0,
              "cve": "CVE-2024-37371"
            }
          },
          {
            "identifiers": [
              {
                "externalId": "CVE-2024-5171",
                "externalType": "cve"
              }
            ],
            "cveEnrichment": {
              "epssScore": 0.02,
              "cve": "CVE-2024-5171"
            }
          }
        ]
      }
    }
  },
  "correlationId": "..."
}
```
