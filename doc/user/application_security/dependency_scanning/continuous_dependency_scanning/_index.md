---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Continuous dependency scanning
description: How GitLab detects new vulnerabilities for application dependencies outside of CI/CD pipelines.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Continuous vulnerability scanning for dependency scanning [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/371063) with [feature flags](../../../../administration/feature_flags/_index.md) `dependency_scanning_on_advisory_ingestion` and `package_metadata_advisory_scans` enabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/425753) in GitLab 16.10. Feature flags `dependency_scanning_on_advisory_ingestion` and `package_metadata_advisory_scans` removed.

{{< /history >}}

Continuous vulnerability scanning (CVS) for dependency scanning looks for security vulnerabilities in your project's dependencies by comparing their component names and versions against information in the latest [security advisories](#security-advisories) without requiring a new pipeline to run.
A pipeline must run at least once on the default branch to register your project's components through a CycloneDX SBOM. After that, CVS runs as advisories are published, without further pipeline executions, until your dependencies change.

[New vulnerabilities may arise](#checking-new-vulnerabilities) when continuous vulnerability scanning triggers scans on all projects that contain components with [supported package types](#supported-package-types).

Vulnerabilities created by continuous vulnerability scanning for dependency scanning use `GitLab SBoM Vulnerability Scanner` as the scanner name and `Dependency Scanning` as the vulnerability type.

In contrast to CI/CD-based security scans, continuous vulnerability scanning is executed through background jobs (Sidekiq) rather than CI/CD pipelines and no Security report artifacts are generated.

## Prerequisites

- [A CycloneDX SBOM report](#how-to-generate-a-cyclonedx-sbom-report).
- [Security advisories](#security-advisories) synchronized to the GitLab instance.

## Supported package types

Continuous vulnerability scanning supports components with the following [PURL types](https://github.com/package-url/purl-spec/blob/346589846130317464b677bc4eab30bf5040183a/PURL-TYPES.rst) for dependency scanning:

- `cargo`
- `conan`
- `go`
- `maven`
- `npm`
- `nuget`
- `packagist`
- `pub`
- `pypi`
- `rubygem`
- `swift`

Go pseudo versions are not supported. A project dependency that references a Go pseudo version is
never considered as affected because this might result in false negatives.

## How to generate a CycloneDX SBOM report

Use a [CycloneDX SBOM report](../../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx) to register your project components with GitLab.

The CycloneDX reports must comply with:

- [the CycloneDX specification](https://github.com/CycloneDX/specification) version `1.4`, `1.5`, or `1.6`.
- [the GitLab CycloneDX property taxonomy for dependency scanning](../../../../development/sec/cyclonedx_property_taxonomy.md#gitlabdependency_scanning-namespace-taxonomy).

GitLab offers security analyzers that can generate a report compatible with GitLab:

- [Dependency scanning analyzer](../dependency_scanning_sbom/_index.md#turn-on-dependency-scanning)
- [Gemnasium analyzer (deprecated)](../legacy_dependency_scanning/_index.md)

## Checking new vulnerabilities

New vulnerabilities detected by continuous vulnerability scanning are visible on the [vulnerability report](../../vulnerability_report/_index.md).
However, they are not listed in the pipeline where the affected SBOM component was detected.

Vulnerabilities are created after a [security advisory](#security-advisories) is added or updated, it may take a few hours for
the corresponding vulnerabilities to be added to your projects, provided the codebase remains unchanged. Only advisories published within the last 14 days
are considered for continuous vulnerability scanning.

## When vulnerabilities are no longer detected

Continuous vulnerability scanning automatically creates vulnerabilities when a new advisory is published
but it is not able to tell when a vulnerability is no longer present in the project. To do so, GitLab
still requires to have a [dependency scanning](../_index.md) scan executed in a pipeline for the default branch,
and a corresponding security report artifact generated with the up to date information. When these reports
are processed, and when they no longer contain some vulnerabilities, these are flagged as such even if
they were created by continuous vulnerability scanning.

## Security advisories

Continuous vulnerability scanning uses the Package Metadata Database, a service managed by GitLab which aggregates license and security advisory data, and regularly publishes updates that are used by GitLab.com and GitLab Self-Managed instances.

On GitLab.com, the synchronization is managed by GitLab and is available to all projects.

On GitLab Self-Managed, you can [choose package registry metadata to synchronize](../../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync) in the **Admin** area for the GitLab instance.

### Data sources

Current data sources for security advisories include:

- [GitLab advisory database](https://advisories.gitlab.com/) (hosted in the [`gemnasium-db`](https://gitlab.com/gitlab-org/security-products/gemnasium-db) repository, a legacy name)

### Contributing to the vulnerability database

To find a vulnerability, you can search the [`GitLab advisory database`](https://advisories.gitlab.com/).
You can also [submit new vulnerabilities](https://gitlab.com/gitlab-org/security-products/gemnasium-db/blob/master/CONTRIBUTING.md).
