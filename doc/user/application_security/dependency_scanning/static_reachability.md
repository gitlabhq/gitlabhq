---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Static reachability analysis
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14177) as an [experiment](../../../policy/development_stages_support.md) in GitLab 17.5.
- [Changed](https://gitlab.com/groups/gitlab-org/-/epics/15781) from experiment to beta in GitLab 17.11.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/502334) support for JavaScript and TypeScript in GitLab 18.2 and Dependency Scanning Analyzer v0.32.0.

{{< /history >}}

Static reachability analysis (SRA) helps you prioritize remediation of vulnerabilities in
dependencies. SRA identifies which dependencies your application actually uses. While dependency
scanning finds all vulnerable dependencies, SRA focuses on those that are reachable and pose higher
security risks, helping you prioritize remediation based on actual threat exposure.

## Getting started

If you are new to static reachability analysis, the following steps show how to enable it for your
project.

Prerequisites:

- Only Python, JavaScript, and TypeScript projects are supported.
- [Dependency Scanning analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning)
  version 0.32.0 and later.
- Enable [Dependency Scanning by using SBOM](dependency_scanning_sbom/_index.md#getting-started).
  [Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium) analyzers are not
  supported.

  For Python, follow the [pip](dependency_scanning_sbom/_index.md#pip) or
  [pipenv](dependency_scanning_sbom/_index.md#pipenv)
  related instructions for dependency scanning using SBOM. You can also use any other Python package
  manager that is
  [supported](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files)
  by the DS analyzer.

  For JavaScript and TypeScript, ensure your repository has the [supported](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files)
  lock files by the DS analyzer.

Exclusions:

- SRA cannot be used together with either a scan execution policy or pipeline execution policy.

To enable SRA:

- On the left sidebar, select **Search or go to** and find your project.
- Edit the `.gitlab-ci.yml` file, and add one of the following.

  If you're using the CI/CD template, add the following (ensure there is only one `variables:`
  line):

  ```yaml
  variables:
    DS_STATIC_REACHABILITY_ENABLED: true
  ```

  If you're using the [Dependency Scanning component](https://gitlab.com/components/dependency-scanning),
  add the following (ensuring there is only one `include:` line.):

  ```yaml
  include:
    - component: ${CI_SERVER_FQDN}/components/dependency-scanning/main@0
      inputs:
        enable_static_reachability: true
      rules:
        - if: $CI_SERVER_HOST == "gitlab.com"
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

Not Found
: SRA ran successfully but did not detect usage of the vulnerable package. If a vulnerable
dependency's reachability value is shown as **Not Found** exercise caution rather than completely
dismissing it, because the beta version of SRA may produce false negatives.

Not Available
: SRA was not executed, so no reachability data exists.

When a direct dependency is marked as **in use**, all its transitive dependencies are also marked as
**in use**.

## Supported languages and package managers

Static reachability analysis is available for Python, JavaScript, and TypeScript projects. SRA uses the new dependency
scanning analyzer to generate SBOMs and supports the same package managers as the analyzer.

| Language | Supported package managers | Supported file suffix |
|----------|----------------------------|-----------------------|
| Python   | `pip`, `pipenv`, `poetry`, `uv` | `.py` |
| JavaScript/TypeScript | `npm`, `pnpm`, `yarn` |  `.js`, `.ts` |

For Python `pipenv`, static reachability doesn't support `Pipfile.lock` files. Support is available only for `pipenv.graph.json` because it has support for a dependency graph.

If a package manager without dependency graph support is used, all indirect dependencies are marked as not in use.

Because of a [known issue](dependency_scanning_sbom/_index.md#pip) in Dependency Scanning with `pipdeptree`,
[optional dependencies](https://setuptools.pypa.io/en/latest/userguide/dependency_management.html#optional-dependencies)
are marked as direct dependencies instead of as transitive dependencies. Static Reachability might not
identify those packages as in use.

For example, requiring `passlib[bcrypt]` may result in `passlib` being marked as `in_use` whilst `bcrypt` is marked as `not_found`.

## Running SRA in an offline environment

To use the dependency scanning component in an offline environment, you must first
[mirror the component project](../../../ci/components/_index.md#use-a-gitlabcom-component-on-gitlab-self-managed).

## How static reachability analysis works

Dependency scanning generates an SBOM report that identifies all components and their transitive
dependencies. Static reachability analysis checks each dependency in the SBOM report and adds a
reachability value to the SBOM report. The enriched SBOM is then ingested by the GitLab instance.

The following are marked as not found:

- Dependencies that are found in the project's lock files but are not imported in the code.
- Tools that are included in the project's lock files for local usage but are not imported in the
  code. For example, tools such as coverage testing or linting packages are marked as not found even
  if used locally.
