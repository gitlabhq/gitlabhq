---
stage: Application Security Testing
group: Threat Research
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab advisory database
description: Security advisories, vulnerabilities, dependencies, database, and updates.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab maintains two advisory feeds for software dependencies and synchronizes them to your GitLab instance:

- [Vulnerability advisories](#gitlab-advisories-for-vulnerabilities), for packages with known vulnerabilities.
- [Malware advisories](#gitlab-advisories-for-malware), for packages that are malicious.

## GitLab advisories for vulnerabilities

The GitLab advisory database (GLAD) aggregates security advisories for software dependencies from public data feeds,
such as the [National Vulnerability Database](https://nvd.nist.gov/) (NVD) and [GitHub Security Advisories](https://github.com/advisories) (GHSA),
and from proprietary advisories.

Advisories identify vulnerabilities by their [CVE](../terminology/_index.md#cve) identifier.
When a vulnerability has no CVE identifier, advisories use another identifier, such as a GHSA ID.
Advisories also classify weaknesses with [CWE](../terminology/_index.md#cwe) and rate impact with [CVSS](../terminology/_index.md#cvss) scores.

> [!note]
> GitLab synchronizes GLAD to your instance automatically.
> In [offline environments](../offline_deployments/_index.md), [download the advisory data on a machine with internet access](../../../topics/offline/package-metadata-database.md#download-v2-package-metadata-with-gsutil) and copy it to the instance instead.

These features use GLAD advisories:

- [Dependency scanning using SBOM](../dependency_scanning/dependency_scanning_sbom/_index.md) creates a vulnerability when a pipeline detects a vulnerable package.
- [Continuous vulnerability scanning](../continuous_vulnerability_scanning/_index.md) creates a vulnerability when a new advisory affects a package, without a pipeline.

[Dependency scanning with Gemnasium](../dependency_scanning/_index.md#dependency-scanning-with-gemnasium) uses the [legacy GitLab advisory database](#legacy-gitlab-advisory-database) instead.

### Supported package types for vulnerability advisories

GLAD covers components with these package types:
`cargo`, `conan`, `go`, `maven`, `npm`, `nuget`, `packagist`, `pub`, `pypi`, `rubygem`, and `swift`.

## GitLab advisories for malware

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/20876) in GitLab 19.3 [with flags](../../../administration/feature_flags/_index.md) named `sync_malware_advisories` and `ingest_malware_advisories`. Disabled by default.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249740) in GitLab 19.3.
- [Generally available](https://gitlab.com/groups/gitlab-org/-/epics/20876) in GitLab 19.5. Feature flags `sync_malware_advisories` and `ingest_malware_advisories` removed.

{{< /history >}}

GitLab advisories for malware (GLAM) is a separate feed of advisories for malicious packages published to package registries.
GitLab builds GLAM from the [OpenSSF malicious-packages project](https://github.com/ossf/malicious-packages),
upstream feeds from package registries, and its own analysis of newly published packages.
Intentionally malicious packages do not qualify for CVE identifiers, so GLAM tracks them with its own IDs
in the format `GLAM-<year>-<month>-<sequence>`, for example `GLAM-2026-09-00138`.

> [!note]
> GitLab synchronizes GLAM to your instance automatically.
> In offline environments, [download the malware advisories on a machine with internet access](../../../topics/offline/package-metadata-database.md#download-gitlab-v3-malware-advisories) and copy them to the instance instead.

These features use GLAM advisories:

- [Dependency scanning using SBOM](../dependency_scanning/_index.md#dependency-scanning-using-sbom) creates a vulnerability when a pipeline detects a malicious package.
- [Continuous vulnerability scanning](../continuous_vulnerability_scanning/_index.md#malicious-packages) creates a vulnerability without a pipeline.
- [Merge request approval policies](../policies/merge_request_approval_policies.md#block-malicious-packages-with-the-malware-rule) block merge requests that introduce a malicious package.

### Supported package types for malware advisories

GLAM covers components with these package types:
`cargo`, `go`, `maven`, `npm`, `nuget`, `pypi`, and `rubygem`.
Components with other package types, such as `conan` or container scanning types like `deb`, are never flagged as malicious.

## Legacy GitLab advisory database

Dependency scanning with Gemnasium uses the legacy GitLab advisory database, a subset of GLAD
without the proprietary advisories added from September 29, 2026.
To browse it, go to [`advisories.gitlab.com`](https://advisories.gitlab.com).

## Look up advisories with the GraphQL API

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/503307) in GitLab 18.11 [with a feature flag](../../../administration/feature_flags/_index.md) named `pm_advisory_graphql`. Disabled by default. This feature is an [experiment](../../../policy/development_stages_support.md).

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.
> This feature is available for testing, but not ready for production use.

To check which advisories your GitLab instance has, look them up by identifier:

- [`Query.packageMetadataAdvisory` to look up a single advisory](../../../api/graphql/reference/queries.md#packagemetadataadvisory)
- [`Query.packageMetadataAdvisories` to look up multiple advisories](../../../api/graphql/reference/queries.md#packagemetadataadvisories)

Results include proprietary and container scanning advisories, but not malware advisories.
When several advisories share an identifier, only `Query.packageMetadataAdvisories` returns all of them.

### Single advisory

To look up a single advisory by identifier:

```graphql
{
  packageMetadataAdvisory(identifier: "CVE-2026-34598") {
    id
    title
    description
    publishedDate
    identifiers {
      name
      url
    }
  }
}
```

Example response:

```json
{
  "data": {
    "packageMetadataAdvisory": {
      "id": "gid://gitlab/PackageMetadata::Advisory/8295281",
      "title": "YesWiki has Persistent Blind XSS at \"/?BazaR&vue=consulter\"",
      "description": "A stored and blind XSS vulnerability exists in the form title field. A malicious attacker can inject JavaScript without any authentication via a form title that is saved in the backend database. When any user visits that injected page, the JavaScript payload gets executed.\n\nType: Stored and Blind Cross-Site Scripting (XSS)\nAffected Component: form title input field\nAuthentication Required: No (Unauthenticated attack possible)\nImpact: Arbitrary JavaScript execution in victim's browser",
      "publishedDate": "2026-04-01",
      "identifiers": [
        {
          "name": "CVE-2026-34598",
          "url": "https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2026-34598"
        },
        {
          "name": "GHSA-37fq-47qj-6j5j",
          "url": "https://github.com/advisories/GHSA-37fq-47qj-6j5j"
        }
      ]
    }
  },
  "correlationId": "9f10f45bdb871a6e-MEL"
}
```

### Multiple advisories

To look up multiple advisories by identifiers:

```graphql
{
  packageMetadataAdvisories(identifiers: ["CVE-2026-34598", "CVE-2026-34601"]) {
    nodes {
      id
      title
      description
      publishedDate
      identifiers {
        name
        url
      }
    }
  }
}
```

The response has the same fields as the single advisory response, with one entry in `nodes` for each matching advisory.

### Null responses

Both endpoints return `null` instead of an error when any of these conditions is true:

- The request is not authenticated.
- The `pm_advisory_graphql` feature flag is not enabled for your user.
- Your GitLab instance does not have an Ultimate license.

For example:

```json
{
  "data": {
    "packageMetadataAdvisory": null
  }
}
```

`Query.packageMetadataAdvisory` also returns `null` when no advisory matches the identifier.
To confirm that the API is available, look up an identifier that you know exists, such as `CVE-2026-34598`.
