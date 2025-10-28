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
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/502334) support for JavaScript and TypeScript in GitLab 18.2 and Dependency Scanning Analyzer v0.32.0.
- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/17607) support for Java in GitLab 18.5 and Dependency Scanning Analyzer v0.39.0.
- [Changed](https://gitlab.com/groups/gitlab-org/-/epics/15780) from beta to Limited Availability (LA) in GitLab 18.5.

{{< /history >}}

Static reachability analysis (SRA) helps you prioritize remediation of vulnerabilities in
dependencies. SRA identifies which dependencies your application actually uses. While dependency
scanning finds all vulnerable dependencies, SRA focuses on those that are reachable and pose higher
security risks, helping you prioritize remediation based on actual threat exposure.

Static reachability analysis is production-ready but marked as Limited Availability because it is bundled with [Dependency Scanning](dependency_scanning_sbom/_index.md), which is in Limited Availability maturity level.

## Getting started

If you are new to static reachability analysis, the following steps show how to enable it for your
project.

Share any feedback on the new static reachability analysis in this [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/535498).

Prerequisites:

- Ensure the project uses [supported languages and package managers](#supported-languages-and-package-managers).
- [Dependency scanning analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning)
  version 0.39.0 or later (earlier versions may support specific languages - see `History` above)
- Enable [Dependency scanning by using SBOM](dependency_scanning_sbom/_index.md#getting-started).
  [Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium) analyzers are not
  supported.
- Language-specific prerequisites:
  - For Python, follow the [pip](dependency_scanning_sbom/_index.md#pip) or
    [pipenv](dependency_scanning_sbom/_index.md#pipenv)
    related instructions for dependency scanning using SBOM. You can also use any other Python package
    manager that is
    [supported](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files)
    by the dependency scanning analyzer.
  - For JavaScript and TypeScript, ensure your repository has lock files
    [supported](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files)
    by the dependency scanning analyzer.
  - For Java, follow the [Maven](dependency_scanning_sbom/_index.md#maven) or
    [Gradle](dependency_scanning_sbom/_index.md#gradle) related instructions for dependency scanning using SBOM
    to generate the required dependency graph files.

Performance impact:

- When you enable static reachability analysis, keep in mind that it increases dependency scanning job duration.

To enable SRA:

- On the left sidebar, select **Search or go to** and find your project.
- Edit the `.gitlab-ci.yml` file, and add the following.

```yaml
include:
- template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
  variables:
  DS_STATIC_REACHABILITY_ENABLED: true
```

At this point, SRA is enabled in your pipeline. When dependency scanning runs and outputs an SBOM,
the results are supplemented by static reachability analysis.

## Understanding the results

To identify vulnerable dependencies that are reachable, either:

- In the vulnerability report, hover over the **Severity** value of a vulnerability.
- In a vulnerability's details page, check the **Reachable** value.
- Use a GraphQL query to list those vulnerabilities that are reachable.

A dependency can have one of the following reachability values:

Yes
: The package linked to this vulnerability is confirmed reachable in code.

  When a direct dependency is marked as reachable its transitive dependencies are also
  marked as reachable.

Not Found
: SRA ran successfully but did not detect usage of the vulnerable package.

Not Available
: SRA was not executed, so no reachability data exists.

### Not Found reachability value

If a vulnerable dependency's reachability value is shown as **Not Found**, exercise caution rather than completely
dismissing it, as SRA cannot always definitively determine package usage.

Dependencies in excluded directories might appear in the SBOM but be marked as **Not Found**. This occurs when lock files
are in scope of dependency scanning but the source code that uses those dependencies is excluded. For example, you configure the
CI/CD variable `DS_EXCLUDED_PATHS` to exclude the directory `tests/` from dependency scanning. All dependencies identified from
the lock file are listed in the SBOM, but SRA does not scan source code in excluded paths.

## Supported languages and package managers

Static reachability analysis is available for Python, JavaScript, TypeScript, and Java projects.
Frontend frameworks are not supported.

### Language maturity levels

While the end-to-end static reachability feature is at Limited Availability level, individual language support has different maturity levels:

| Maturity | Languages | Additional Information |
|----------|-----------|-------------|
| Beta | Python | Not applicable |
| Beta | JavaScript, TypeScript | No support for frontend frameworks. |
| Experimental | Java | Java support is in early stages with [known limitations](#java-static-reachability-limitations) and may have higher false negative rates. |

SRA supplements the SBOMs generated by the new dependency scanner analyzer and so supports the same
package managers. If a package manager without dependency graph support is used, all indirect
dependencies are marked as [not found](#understanding-the-results).

| Language              | Supported package managers                  | Supported file suffix |
|-----------------------|---------------------------------------------|-----------------------|
| Python<sup>1</sup>    | `pip`, `pipenv`<sup>2</sup>, `poetry`, `uv` | `.py`                 |
| JavaScript/TypeScript | `npm`, `pnpm`, `yarn`                       | `.js`, `.ts`          |
| Java<sup>3</sup>      | `maven`, `gradle`                           | `.java`               |

**Footnotes**:

1. When using dependency scanning with `pipdeptree`,
  [optional dependencies](https://setuptools.pypa.io/en/latest/userguide/dependency_management.html#optional-dependencies)
   are marked as direct dependencies instead of as transitive dependencies. Static reachability
   analysis might not identify those packages as in use. For example, requiring `passlib[bcrypt]`
   may result in `passlib` being marked as `in_use` and `bcrypt` is marked as `not_found`. For
   more details, see [pip](dependency_scanning_sbom/_index.md#pip).
1. For Python `pipenv`, static reachability analysis doesn't support `Pipfile.lock` files. Support
   is available only for `pipenv.graph.json` because it supports a dependency graph.
1. For Java, static reachability analysis requires dependency graph files. For Maven projects,
   use `maven.graph.json` files as described in the [Maven](dependency_scanning_sbom/_index.md#maven)
   instructions. For Gradle projects, use dependency lock files as described in the
   [Gradle](dependency_scanning_sbom/_index.md#gradle) instructions.

### Java static reachability limitations

Static reachability analysis for Java has two key limitations:

- **Detection scope**: Detects only explicit static usage through direct imports. Cannot identify dependencies loaded dynamically at runtime, such as those using dependency injection frameworks like Spring Boot.
- **Package coverage**: Limited to vulnerable and popular packages available in Maven Central.

These limitations may result in higher false negative rates for projects using modern frameworks. We plan to improve Java static reachability analysis in future releases.

## Running SRA in an offline environment

To use the dependency scanning component in an offline environment, you must first
[mirror the component project](../../../ci/components/_index.md#use-a-gitlabcom-component-on-gitlab-self-managed).

## How static reachability analysis works

Dependency scanning generates an SBOM report that identifies all components and their transitive
dependencies. Static reachability analysis checks each dependency in the SBOM report and adds a
reachability value to the SBOM report. The enriched SBOM is then ingested by the GitLab instance.

Static reachability analysis relies on [metadata](https://gitlab.com/gitlab-org/security-products/static-reachability-metadata/-/tree/v1?ref_type=heads) that maps package names from SBOMs to their corresponding code import paths for Python and Java packages. This metadata is maintained with weekly updates.

The following are marked as not found:

- Dependencies that are found in the project's lock files but are not imported in the code.
- Tools that are included in the project's lock files for local usage but are not imported in the
  code. For example, tools such as coverage testing or linting packages are marked as not found even
  if used locally.
