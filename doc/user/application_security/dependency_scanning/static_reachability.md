---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Static reachability analysis
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14177) as an [experiment](../../../policy/development_stages_support.md) in GitLab 17.5.
- [Changed](https://gitlab.com/groups/gitlab-org/-/epics/15781) from experiment to beta in GitLab 17.11.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/502334) support for JavaScript and TypeScript in GitLab 18.2 and dependency scanning analyzer v0.32.0.
- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/17607) support for Java in GitLab 18.5 and dependency scanning analyzer v0.39.0.
- [Changed](https://gitlab.com/groups/gitlab-org/-/epics/15780) from beta to Limited Availability (LA) in GitLab 18.5.
- [Changed](https://gitlab.com/groups/gitlab-org/-/epics/19692) Java support from experiment to beta in GitLab 18.8.
- [Generally available](https://gitlab.com/groups/gitlab-org/-/work_items/20456) in GitLab 19.0.

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

Share feedback in [issue 535498](https://gitlab.com/gitlab-org/gitlab/-/issues/535498).

## Turn on static reachability analysis

Prerequisites:

- The Developer, Maintainer, or Owner role for the project.
- The project uses
  [supported languages and package managers](#supported-languages-and-package-managers).
- [Dependency scanning analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning)
  version 0.39.0 or later (earlier versions may support specific languages - see `History` above).
- [Dependency scanning by using SBOM](dependency_scanning_sbom/_index.md#turn-on-dependency-scanning) turned on for the project.
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
    - Repository must contain lockfiles
      [supported](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files)
      by the dependency scanning analyzer.
  - Java:
    - Dependency graph files must be provided as a job artifact in the `build` stage. See the
      instructions for [Maven](dependency_scanning_sbom/_index.md#maven) or
      [Gradle](dependency_scanning_sbom/_index.md#gradle).

> [!warning]
> Static reachability analysis increases job duration.

To turn on static reachability analysis in your project:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Repository**.
1. Select the `.gitlab-ci.yml` file.
1. Select **Edit** > **Edit single file**.
1. Add the following configuration:

   ```yaml
   include:
   - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

   variables:
     DS_STATIC_REACHABILITY_ENABLED: true
   ```

1. Select **Commit changes**.

When dependency scanning runs and outputs an SBOM, the results are supplemented by static reachability analysis.

## Reachability values

A dependency can have one of the following reachability values. Prioritize triage and remediation of
dependencies marked as **Yes**, because these are confirmed to be used in your code.

Yes
: The package linked to this vulnerability is confirmed reachable in code. When a direct dependency
  is marked as reachable, its transitive dependencies are also marked as reachable.

Not Found
: Static reachability analysis ran successfully but did not detect usage of the vulnerable package.

Not Available
: Static reachability analysis was not executed, so no reachability data exists.

To find the reachability value for a vulnerable dependency:

- In the vulnerability report, hover over the **Severity** value.
- In a vulnerability's details page, check the **Reachable** value.
- Use a GraphQL query to list vulnerabilities that are reachable.

### "Not Found" results

A **Not Found** reachability value doesn't guarantee the dependency is unused, because static
reachability analysis cannot always definitively determine package usage.

Dependencies are marked as not found when:

- They appear in lockfiles but are not imported in the code.
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
this occurs when the lockfile is outside the excluded directory but the code that imports the
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
1. Java's dynamic nature causes the following issues which can result in higher false negative
   rates for projects using modern frameworks:
   - Static reachability analysis detects explicit usage through direct imports, Java reflection
     patterns, and Java Database Connectivity connection strings in source code. It cannot identify
     dependencies loaded dynamically at runtime, such as those using dependency injection frameworks
     like Spring Boot.
   - Coverage is limited to packages in the GitLab advisory database and the most
     widely-depended-upon packages in Maven Central.
1. Use `maven.graph.json` files as described in the
   [Maven](dependency_scanning_sbom/_index.md#maven) instructions.
1. Use dependency lockfiles as described in the [Gradle](dependency_scanning_sbom/_index.md#gradle)
   instructions.

## Offline environment

To run static reachability analysis in an [offline environment](../offline_deployments/_index.md),
you must do an initial setup and perform ongoing maintenance.

Initial setup:

- Complete the offline environment requirements for
  [dependency scanning (SBOM)](dependency_scanning_sbom/_index.md#offline-environment).

Ongoing maintenance:

- Update the local dependency scanning (SBOM) image whenever new versions are released.

For Python and Java packages, static reachability analysis uses metadata to map package names from
SBOMs to their corresponding code import paths. This metadata is contained in the dependency
scanning analyzer's image. Outdated metadata may result in incomplete or inaccurate reachability
analysis.
