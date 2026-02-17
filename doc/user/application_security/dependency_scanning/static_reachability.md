---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Static reachability analysis
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Limited Availability

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14177) as an [experiment](../../../policy/development_stages_support.md) in GitLab 17.5.
- [Changed](https://gitlab.com/groups/gitlab-org/-/epics/15781) from experiment to beta in GitLab 17.11.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/502334) support for JavaScript and TypeScript in GitLab 18.2 and dependency scanning analyzer v0.32.0.
- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/17607) support for Java in GitLab 18.5 and dependency scanning analyzer v0.39.0.
- [Changed](https://gitlab.com/groups/gitlab-org/-/epics/15780) from beta to Limited Availability (LA) in GitLab 18.5.
- [Changed](https://gitlab.com/groups/gitlab-org/-/epics/19692) Java support from experiment to beta in GitLab 18.8.

{{< /history >}}

Dependency scanning identifies all vulnerable dependencies in your project. However, not all
vulnerabilities pose equal risk. Static reachability analysis helps you prioritize remediation by
determining which vulnerable packages are reachable, meaning they are imported by your application.
By focusing on reachable vulnerabilities, static reachability analysis enables you to prioritize
remediation based on actual threat exposure rather than theoretical risk.

Static reachability analysis works by analyzing your project's source code to determine which
dependencies from your SBOM are reachable. Dependency scanning generates an SBOM report that
identifies all components and their transitive dependencies. Static reachability analysis then
checks each dependency in the SBOM and adds a reachability value, enriching the report with actual
usage data. This enriched SBOM is then ingested by GitLab to supplement vulnerability findings.

An SBOM is enriched only when both the SBOM file and source code files belong to the same project
directory tree. When multiple nested projects exist, the system selects the closest (deepest)
project path to determine enrichment. static reachability analysis relies on
[metadata](https://gitlab.com/gitlab-org/security-products/static-reachability-metadata/-/tree/v1?ref_type=heads)
that maps package names from SBOMs to their corresponding code import paths for Python and Java
packages. This metadata is maintained with weekly updates.

> [!warning]
> Static reachability analysis is production-ready. However, it has limited availability
> because it depends on [dependency scanning by SBOM](dependency_scanning_sbom/_index.md),
> which has the same status.

Share feedback in [issue 535498](https://gitlab.com/gitlab-org/gitlab/-/issues/535498).

## Enable static reachability analysis

Prerequisites:

- Ensure the project uses
  [supported languages and package managers](#supported-languages-and-package-managers).
- [Dependency scanning analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning)
  version 0.39.0 or later (earlier versions may support specific languages - see `History` above)
- Enable [Dependency scanning by using SBOM](dependency_scanning_sbom/_index.md#getting-started).
  [Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium) analyzers are not
  supported.
- Language-specific prerequisites:
  - Python:
    - Dependency graph files must be provided as a job artifact in the `build` stage. See the
      instructions for [pip](dependency_scanning_sbom/_index.md#pip) or
      [pipenv](dependency_scanning_sbom/_index.md#pipenv). For other supported Python package
      managers, see the
      [dependency scanning analyzer documentation](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files).
  - JavaScript and TypeScript:
    - Repository must contain lock files
      [supported](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files)
      by the dependency scanning analyzer.
  - Java:
    - Dependency graph files must be provided as a job artifact in the `build` stage. See the
      instructions for [Maven](dependency_scanning_sbom/_index.md#maven) or
      [Gradle](dependency_scanning_sbom/_index.md#gradle).

> [!warning]
> Static reachability analysis increases job duration.

To enable static reachability analysis in your project:

- On the top bar, select **Search or go to** and find your project.
- Edit the `.gitlab-ci.yml` file, and add the following.

```yaml
include:
- template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
  variables:
  DS_STATIC_REACHABILITY_ENABLED: true
```

At this point, static reachability analysis is enabled in your pipeline. When dependency scanning
runs and outputs an SBOM, the results are supplemented by static reachability analysis.

## Reachability values

A dependency can have one of the following reachability values. Prioritize triage and remediation of
dependencies marked as **Yes**, because these are confirmed to be used in your code.

**Yes**
: The package linked to this vulnerability is confirmed reachable in code. When a direct
dependency is marked as reachable, its transitive dependencies are also marked as reachable.

**Not Found**
: Static reachability analysis ran successfully but did not detect usage of the vulnerable package.

**Not Available**
: Static reachability analysis was not executed, so no reachability data exists.

To find the reachability value for a vulnerable dependency:

- In the vulnerability report, hover over the **Severity** value.
- In a vulnerability's details page, check the **Reachable** value.
- Use a GraphQL query to list vulnerabilities that are reachable.

### "Not Found" results

A **Not Found** reachability value doesn't guarantee the dependency is unused, because static
reachability analysis cannot always definitively determine package usage.

Dependencies are marked as not found when:

- They appear in lock files but are not imported in the code.
- They are in excluded directories (for example, configured with `DS_EXCLUDED_PATHS`).
- They are tools included for local usage only, such as coverage testing or linting packages.

Consider the following example of an excluded directory. You have defined the CI/CD variable
`DS_EXCLUDED_PATHS="test"`. The project's repository structure is as follows.

```plaintext
.
├── pipdeptree.json  // contains "requests" dependency
└── test/
    └── app.py       // imports "requests" dependency
```

In this example, the graph file `pipdeptree.json` is outside the excluded directory and is analyzed
to identify the dependencies listed in the file. However, the source code that imports the
`requests` dependency is in an excluded directory, so static reachability analysis doesn't check its
reachability. As a result, the `requests` dependency is labeled as **Not found**. In other words,
this occurs when the lock file is outside the excluded directory but the code that imports the
dependency is inside it.

## Supported languages and package managers

Support varies by language maturity and includes specific package managers and file types for each
language.

| Language                          | Maturity | Supported package managers                  | Supported file types |
|-----------------------------------|----------|---------------------------------------------|----------------------|
| Python<sup>1</sup>                | Beta     | `pip`, `pipenv`<sup>2</sup>, `poetry`, `uv` | `.py`                |
| JavaScript/TypeScript<sup>3</sup> | Beta     | `npm`, `pnpm`, `yarn`                       | `.js`, `.ts`         |
| Java<sup>4</sup>                  | Beta     | `maven`<sup>5</sup>, `gradle`<sup>6</sup>   | `.java`              |

**Footnotes**:

1. When using dependency scanning with `pipdeptree`,
   [optional dependencies](https://setuptools.pypa.io/en/latest/userguide/dependency_management.html#optional-dependencies)
   are marked as direct dependencies instead of as transitive dependencies. Static reachability
   analysis might not identify those packages as in use. For example, requiring `passlib[bcrypt]`
   may result in `passlib` being marked as `in_use` and `bcrypt` is marked as `not_found`. For more
   details, see [pip](dependency_scanning_sbom/_index.md#pip).
1. For Python `pipenv`, static reachability analysis doesn't support `Pipfile.lock` files. Support
   is available only for `pipenv.graph.json` because it supports a dependency graph.
1. No support for frontend frameworks.
1. Java's dynamic nature causes [known issues](#known-issues-for-java) with higher false negatives.
1. Use `maven.graph.json` files as described in the
   [Maven](dependency_scanning_sbom/_index.md#maven) instructions.
1. Use dependency lock files as described in the
   [Gradle](dependency_scanning_sbom/_index.md#gradle) instructions.

### Known issues for Java

Static reachability analysis for Java has the following known issues:

- It detects explicit usage through direct imports, Java reflection patterns, and JDBC connection
  strings in source code. It cannot identify dependencies loaded dynamically at runtime, such as
  those using dependency injection frameworks like Spring Boot.
- Coverage is limited to packages in the GitLab advisory database and the most widely-depended-upon
  packages in Maven Central.

These issues might result in higher false negative rates for projects using modern frameworks.

## Offline environment

To run static reachability analysis in an [offline environment](../offline_deployments/_index.md),
you must do an initial setup and perform ongoing maintenance.

Initial setup:

- Complete the offline environment requirements for
  [dependency scanning (SBOM)](dependency_scanning_sbom/_index.md#offline-support).

Ongoing maintenance:

- Update the local dependency scanning (SBOM) image whenever new versions are released.

For Python and Java packages, static reachability analysis uses metadata to map package names from
SBOMs to their corresponding code import paths. This metadata is contained in the dependency
scanning analyzer's image. Outdated metadata may result in incomplete or inaccurate reachability
analysis.
