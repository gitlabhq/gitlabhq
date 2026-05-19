---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dependency scanning
description: Vulnerabilities, remediation, configuration, analyzers, and reports.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Dependency scanning identifies known security vulnerabilities in your project's
dependencies, including runtime, development, and transitive (nested) packages.
GitLab offers several dependency scanning methods, each suited to a different
workflow. Use the summary below to choose the method that fits your project.

## Available scanning methods

### Dependency Scanning using SBOM

Scans the CycloneDX SBOM artifacts produced in your pipeline by the Dependency
Scanning analyzer against the GitLab Advisory Database.
This is the recommended method for new projects and the long-term direction for
dependency scanning in GitLab.

For details, see [Dependency Scanning using SBOM](dependency_scanning_sbom/_index.md).

### Continuous Dependency Scanning

Continuously rescans the SBOM components from your default branch's latest
successful pipeline whenever the GitLab Advisory Database is updated, so newly
disclosed vulnerabilities surface without re-running a pipeline.

For details, see [Continuous Dependency Scanning](continuous_dependency_scanning/_index.md).

### Dependency Scanning with Gemnasium

The original pipeline-based analyzer that detects dependencies and matches them
against the GitLab Advisory Database in a CI/CD job.

> [!warning]
> Dependency scanning based on the Gemnasium analyzer is deprecated in GitLab 17.9
> and proposed for removal in GitLab 20.0. For migration guidance, see the
> [migration guide](migration_guide_to_sbom_based_scans.md). For more information,
> see [epic 15961](https://gitlab.com/groups/gitlab-org/-/epics/20456).

For details, see the [legacy dependency scanning page](legacy_dependency_scanning/_index.md).

### Analyze dependencies for behaviors (Libbehave)

An experiment that analyzes the runtime behavior of your dependencies to surface
suspicious or malicious activity beyond known CVEs.

For details, see [Analyze dependencies for behaviors](experiment_libbehave_dependency.md).

## Comparison of scanning methods

| Method                             | Status               | Trigger            | Best for                                                   |
| ---------------------------------- | -------------------- | ------------------ | ---------------------------------------------------------- |
| Dependency Scanning using SBOM     | General Availability | Pipeline           | New projects, SBOM-first workflows                         |
| Continuous Dependency Scanning     | General Availability | Advisory DB update | Catching newly disclosed CVEs without re-running pipelines |
| Dependency Scanning with Gemnasium | Deprecated (17.9)    | Pipeline           | Existing projects pending migration                        |
| Analyze dependencies for behaviors | Experiment           | Pipeline           | Detecting malicious package behavior                       |

## Contributing to the vulnerability database

To find a vulnerability, you can search the [`GitLab advisory database`](https://advisories.gitlab.com/).
You can also [submit new vulnerabilities](https://gitlab.com/gitlab-org/security-products/gemnasium-db/blob/master/CONTRIBUTING.md).
