---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Continuous container scanning
description: How GitLab detects new vulnerabilities for image dependencies outside of CI/CD pipelines.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Continuous container scanning [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/435435) in GitLab 16.8 [with a flag](../../../../administration/feature_flags/_index.md) named `container_scanning_continuous_vulnerability_scans`. Disabled by default.
- Continuous container scanning [enabled on GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/437162) in GitLab 16.10.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/443712) in GitLab 17.0. Feature flag `container_scanning_continuous_vulnerability_scans` removed.

{{< /history >}}

Continuous vulnerability scanning (CVS) for container scanning looks for security vulnerabilities in your project's image dependencies by comparing their component names and versions against information in the latest [security advisories](#security-advisories) without requiring a new pipeline to run.
CVS relies on a CycloneDX SBOM report stored on the default branch to know which components your project uses. To produce this SBOM, a container scanning job must run at least once on the default branch. From then on, CVS detects newly published advisories against those components automatically, with no further pipeline runs required.
When your image contents change, a new pipeline must run on the default branch to refresh the SBOM so CVS can evaluate the updated set of components. In most projects this happens as part of the regular workflow, because changing dependencies typically involves a code change that already triggers a pipeline.

[New vulnerabilities may arise](#checking-new-vulnerabilities) when continuous vulnerability scanning triggers scans on all projects that contain components with [supported package types](#supported-package-types).

Vulnerabilities created by continuous vulnerability scanning for container scanning use `GitLab SBoM Vulnerability Scanner` as the scanner name and `Container Scanning` as the vulnerability type.

In contrast to CI/CD-based security scans, continuous vulnerability scanning is executed through background jobs (Sidekiq) rather than CI/CD pipelines and no Security report artifacts are generated.

## Prerequisites

- [A CycloneDX SBOM report](#how-to-generate-a-cyclonedx-sbom-report).
- [Security advisories](#security-advisories) synchronized to the GitLab instance.

## Supported package types

Continuous vulnerability scanning supports components with the following [PURL types](https://github.com/package-url/purl-spec/blob/346589846130317464b677bc4eab30bf5040183a/PURL-TYPES.rst):

- `apk`
- `deb`
- `rpm`

Known limitations:

- APK versions containing leading zeros are not supported. Work to support these versions is tracked in [issue 471509](https://gitlab.com/gitlab-org/gitlab/-/issues/471509).
- RPM versions containing `^` are not supported. Work to support these versions is tracked in [issue 459969](https://gitlab.com/gitlab-org/gitlab/-/issues/459969).
- RPM packages in Red Hat distributions are not supported. Work to support this use case is tracked in [epic 12980](https://gitlab.com/groups/gitlab-org/-/epics/12980).

## How to generate a CycloneDX SBOM report

Use a [CycloneDX SBOM report](../../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx) to register your project components with GitLab.

The CycloneDX reports must comply with:

- [the CycloneDX specification](https://github.com/CycloneDX/specification) version `1.4`, `1.5`, or `1.6`.
- [the GitLab CycloneDX property taxonomy for container scanning](../../../../development/sec/cyclonedx_property_taxonomy.md#gitlabcontainer_scanning-namespace-taxonomy).

GitLab offers security analyzers that can generate a report compatible with GitLab:

- [Container scanning](../_index.md#getting-started)
- [Container scanning for registry](../_index.md#container-scanning-for-registry)

## Checking new vulnerabilities

New vulnerabilities detected by continuous vulnerability scanning are visible on the [vulnerability report](../../vulnerability_report/_index.md).
However, they are not listed in the pipeline where the affected SBOM component was detected.

Vulnerabilities are created after a [security advisory](#security-advisories) is added or updated, it may take a few hours for
the corresponding vulnerabilities to be added to your projects, provided the codebase remains unchanged. Only advisories published within the last 14 days
are considered for continuous vulnerability scanning.

## When vulnerabilities are no longer detected

Continuous vulnerability scanning automatically creates vulnerabilities when a new advisory is published
but it is not able to tell when a vulnerability is no longer present in the project. To do so, GitLab
still requires to have a [container scanning](../_index.md) scan executed in a pipeline for the default branch,
and a corresponding security report artifact generated with the up to date information. When these reports
are processed, and when they no longer contain some vulnerabilities, these are flagged as such even if
they were created by continuous vulnerability scanning.

> [!warning]
> Vulnerabilities detected through container scanning for registry cannot be resolved using this
> method and remain visible even after you fix them in your images. This occurs because Container
> Scanning for Registry generates only SBOMs, not the security reports required to mark
> vulnerabilities as resolved.

## Security advisories

Continuous vulnerability scanning uses the Package Metadata Database, a service managed by GitLab which aggregates license and security advisory data, and regularly publishes updates that are used by GitLab.com and GitLab Self-Managed instances.

On GitLab.com, the synchronization is managed by GitLab and is available to all projects.

On GitLab Self-Managed, you can [choose package registry metadata to synchronize](../../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync) in the **Admin** area for the GitLab instance.

### Data sources

Current data sources for security advisories include:

- [Trivy DB](https://github.com/aquasecurity/trivy-db), built from Aqua security's [`vuln-list repository`](https://github.com/aquasecurity/vuln-list)

### Contributing to the vulnerability database

To find a vulnerability, you can search the Aqua security's [`vuln-list repository`](https://github.com/aquasecurity/vuln-list) containing raw data.
You can also [contribute](https://github.com/aquasecurity/vuln-list-update/blob/main/CONTRIBUTING.md) to Trivy-DB.
