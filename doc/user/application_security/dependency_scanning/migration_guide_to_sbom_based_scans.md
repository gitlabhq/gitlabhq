---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrating to Dependency Scanning using SBOM
---

{{< history >}}

- The legacy [Dependency Scanning feature based on the Gemnasium analyzer](_index.md) was [deprecated](../../../update/deprecations.md#dependency-scanning-upgrades-to-the-gitlab-sbom-vulnerability-scanner) in GitLab 17.9 and planned for removal in 18.0.

{{< /history >}}

The Dependency Scanning feature is upgrading to the GitLab SBOM Vulnerability Scanner.
As part of this change, the [Dependency Scanning using SBOM](dependency_scanning_sbom/_index.md) feature and the [new Dependency Scanning analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning)
replace the legacy Dependency Scanning feature based on the Gemnasium analyzer. However, due to the significant changes this transition introduces, it is not implemented automatically and this document serves as a migration guide.

Follow this migration guide if you use GitLab Dependency Scanning and any of the following conditions apply:

- The Dependency Scanning CI/CD jobs are configured by including a Dependency Scanning CI/CD templates.

  ```yaml
    include:
      - template: Jobs/Dependency-Scanning.gitlab-ci.yml
      - template: Jobs/Dependency-Scanning.latest.gitlab-ci.yml
  ```

- The Dependency Scanning CI/CD jobs are configured by using [Scan Execution Policies](../policies/scan_execution_policies.md).
- The Dependency Scanning CI/CD jobs are configured by using [Pipeline Execution Policies](../policies/pipeline_execution_policies.md).

## Understand the changes

Before you migrate your project to Dependency Scanning using SBOM, you should
understand the fundamental changes being introduced. The transition represents a
technical evolution, a new approach to how Dependency Scanning works in GitLab,
and various improvements to the user experience, some of which include, but are
not limited to, the following:

- Increased language support.
  The deprecated Gemnasium analyzers are constrained to a small subset of Python
  and Java versions. The new analyzer gives organizations the necessary
  flexibility to use older versions of these toolchains with older projects,
  and the option to try newer versions without waiting on a major update to the
  analyzer's image. Additionally, the new analyzer benefits from increased
  [file coverage](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files).
- Increased performance.
  Depending on the application, builds invoked by the
  Gemnasium analyzers can last for almost an hour, and be a duplicate effort. The
  new analyzer no longer invokes build systems directly. Instead, it re-uses previously
  defined build jobs to improve overall scan performance.
- Smaller attack surface.
  To support its build capabilities, the Gemnasium analyzers are preloaded with
  a variety of dependencies. The new analyzer removes a large amount of these
  dependencies which results in a smaller attack surface.
- Simpler configuration.
  The deprecated Gemnasium analyzers frequently require the configuration of
  proxies, Certificate Authority (CA) certificate bundles, and various other utilities
  to function correctly. The new solution removes many of these requirements, resulting
  in a robust tool that is simpler to configure.

### A new approach to security scanning

When using the legacy Dependency Scanning feature, all scanning work happens within your CI/CD pipeline. When running a scan, the Gemnasium analyzer handles two critical tasks simultaneously: it identifies your project's dependencies and immediately performs a security analysis of those dependencies, all within the same CI/CD job.

The Dependency Scanning using SBOM approach separates these tasks into two distinct phases:

- First, when you run the new Dependency Scanning analyzer in the CI/CD pipeline, it focuses solely on creating a comprehensive inventory of your project's dependencies. This inventory is captured in a CycloneDX SBOM (Software Bill of Materials) report.
- Second, the detected components are sent to the GitLab platform to perform a thorough security analysis using the built-in GitLab SBOM Vulnerability Scanner. You're already benefiting from this scanner with the [Continuous Vulnerability Scanning](../continuous_vulnerability_scanning/_index.md) feature.

This separation of concerns brings several advantages for future enhancements, but it also means some changes are necessary since the security analysis happens outside the CI/CD pipeline.
This impacts the availability of some functionalities that depend on the security analysis to run in the CI/CD pipeline. Please review [the deprecation announcement](../../../update/deprecations.md#dependency-scanning-upgrades-to-the-gitlab-sbom-vulnerability-scanner) for a complete description.

### CI/CD configuration

To prevent disruption to your CI/CD pipelines, the new approach is not yet applied to the stable Dependency Scanning CI/CD template (`Dependency-Scanning.gitlab-ci.yml`) and as of GitLab 17.9, you must use the `latest` template (`Dependency-Scanning.latest.gitlab-ci.yml`) to enable it.
Other migration paths might be considered as the feature gains maturity.

The latest Dependency Scanning CI/CD template (`Dependency-Scanning.latest.gitlab-ci.yml`) still maintains backward compatibility by default. It continues to run existing Gemnasium analyzer jobs, while the new Dependency Scanning analyzer only activates for newly supported languages and package managers. You can opt-in to use the new Dependency Scanning analyzer for all projects by configuring the `DS_ENFORCE_NEW_ANALYZER` CI/CD variable to `true`.

If you're using [Scan Execution Policies](../policies/scan_execution_policies.md), these changes apply in the same way because they build upon the CI/CD templates.

If you're using the [main Dependency Scanning CI/CD component](https://gitlab.com/components/dependency-scanning/-/tree/main/templates/main) you won't see any changes as it already employs the new analyzer.
However, if you're using the specialized components for Android, Rust, Swift, or Cocoapods, you'll need to migrate to the main component that now covers all supported languages and package managers.

### Build support for Java and Python

One significant change affects how dependencies are discovered, particularly for Java and Python projects. The new analyzer takes a different approach: instead of attempting to build your application to determine dependencies, it requires explicit dependency information through lockfiles or dependency graph files.
This change means you'll need to ensure these files are available, either by committing them to your repository or generating them dynamically during the CI/CD pipeline. While this requires some initial setup, it provides more reliable and consistent results across different environments.
The following sections will guide you through the specific steps needed to adapt your projects to this new approach if that's necessary.

### Accessing scan results (during Beta only)

{{< alert type="warning" >}}

ADDENDUM: Based on customer feedback, we have decided to reinstate the generation of the Dependency Scanning report artifact for the Generally Available release.
However, it will not be available in the Beta release.
See [this epic](https://gitlab.com/groups/gitlab-org/-/epics/17150) for more details.

{{< /alert >}}

<details>
  <summary>See Beta behavior</summary>

  When you migrate to Dependency Scanning using SBOM, you'll notice a fundamental change in how security scan results are handled. The new approach moves the security analysis out of the CI/CD pipeline and into the GitLab platform, which changes how you access and work with the results.
  With the legacy Dependency Scanning feature, CI/CD jobs using the Gemnasium analyzer generate a [Dependency Scanning report artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportsdependency_scanning) containing the scan results, and upload it to the platform. You can access these results by all possible ways offered to job artifacts. This means you can process or modify the results within your CI/CD pipeline before they reach the GitLab platform.
  The Dependency Scanning using SBOM approach works differently. Since the security analysis now happens within the GitLab platform using the built-in GitLab SBOM Vulnerability Scanner, you won't find the scan results in your job artifacts anymore. Instead, GitLab analyzes the [CycloneDX SBOM report artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx) that your CI/CD pipeline generates, creating security findings directly in the GitLab platform.
  To help you transition smoothly, GitLab maintains some backward compatibility. While using the Gemnasium analyzer, you'll still get a standard artifact (using `artifacts:paths`) that contains the scan results. This means if you have succeeding CI/CD jobs that need these results, they can still access them. However, keep in mind that as the GitLab SBOM Vulnerability Scanner evolves and improves, these artifact-based results won't reflect the latest enhancements.
  When you're ready to fully migrate to the new Dependency Scanning analyzer, you'll need to adjust how you programmatically access scan results. Instead of reading job artifacts, you'll use GitLab GraphQL API, specifically the ([`Pipeline.securityReportFindings` resource](../../../api/graphql/reference/_index.md#pipelinesecurityreportfindings)).
</details>

## Identify affected projects

Understanding which of your projects need attention for this migration is an important first step. The most significant impact will be on your Java and Python projects, since the way these handle dependencies is changing fundamentally.
To help you identify affected projects, GitLab provides the [Dependency Scanning Build Support Detection Helper](https://gitlab.com/security-products/tooling/build-support-detection-helper) tool. This tool examines your GitLab group or self-managed instance and identifies projects that currently use the Dependency Scanning feature with either the `gemnasium-maven-dependency_scanning` or `gemnasium-python-dependency_scanning` CI/CD jobs.
When you run this tool, it creates a comprehensive report of projects that will need your attention during the migration. Having this information early helps you plan your migration strategy effectively, especially if you manage multiple projects across your organization.

## Migrate to Dependency Scanning using SBOM

To migrate to the Dependency Scanning using SBOM method, perform the following steps for each project:

1. Remove existing customization for Dependency Scanning based on the Gemnasium analyzer.
   - If you have manually overridden the `gemnasium-dependency_scanning`, `gemnasium-maven-dependency_scanning`, or `gemnasium-python-dependency_scanning` CI/CD jobs to customize them in a project's `.gitlab-ci.yml` or in the CI/CD configuration for a Pipeline Execution Policy, remove them.
   - If you have configured any of [the impacted CI/CD variables](#changes-to-cicd-variables), adjust your configuration accordingly.
1. Enable the Dependency Scanning using SBOM feature with one of the following options:
   - Use the `latest` Dependency Scanning CI/CD template `Dependency-Scanning.latest.gitlab-ci.yml` to run the new Dependency Scanning analyzer:
     1. Ensure your `.gitlab-ci.yml` CI/CD configuration includes the latest Dependency Scanning CI/CD template.
     1. Add the CI/CD variable `DS_ENFORCE_NEW_ANALYZER` and set it to `true`. This variable can be set in many different places, while observing the [CI/CD variable precedence](../../../ci/variables/_index.md#cicd-variable-precedence).
     1. Adjust your project and your CI/CD configuration if needed by following the language-specific instructions below.
   - Use the [Scan Execution Policies](../policies/scan_execution_policies.md) to run the new Dependency Scanning analyzer:
     1. Edit the configured scan execution policy for Dependency Scanning and ensure it uses the `latest` template.
     1. Add the CI/CD variable `DS_ENFORCE_NEW_ANALYZER` and set it to `true`. This variable can be set in many different places, while observing the [CI/CD variable precedence](../../../ci/variables/_index.md#cicd-variable-precedence).
     1. Adjust your project and your CI/CD configuration if needed by following the language-specific instructions below.
   - Use the [Dependency Scanning CI/CD component](https://gitlab.com/explore/catalog/components/dependency-scanning) to run the new Dependency Scanning analyzer:
     1. Replace the Dependency Scanning CI/CD template's `include` statement with the Dependency Scanning CI/CD component in your `.gitlab-ci.yml` CI/CD configuration.
     1. Adjust your project and your CI/CD configuration if needed by following the language-specific instructions below.
   - Use your own CycloneDX SBOM document:
     1. Remove the Dependency Scanning CI/CD template's `include` statement from your `.gitlab-ci.yml` CI/CD configuration.
     1. Ensure a compatible SBOM document is generated by a CI/CD job and uploaded as a [CycloneDX SBOM report artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx).
1. Adjust any workflow depending on the [dependency_scanning report artifacts](../../../ci/yaml/artifacts_reports.md#artifactsreportsdependency_scanning) which are no longer uploaded.

For multi-language projects, complete all relevant language-specific migration steps.

{{< alert type="note" >}}

If you decide to migrate from the CI/CD template to the CI/CD component, please review the [current limitations](../../../ci/components/_index.md#use-a-gitlabcom-component-on-gitlab-self-managed) for GitLab Self-Managed.

{{< /alert >}}

## Language-specific instructions

As you migrate to the new Dependency Scanning analyzer, you'll need to make specific adjustments based on your project's programming languages and package managers. These instructions apply whenever you use the new Dependency Scanning analyzer,
regardless of how you've configured it to run - whether through CI/CD templates, Scan Execution Policies, or the Dependency Scanning CI/CD component.
In the following sections, you'll find detailed instructions for each supported language and package manager. For each one, we'll explain:

- How dependency detection is changing
- What specific files you need to provide
- How to generate these files if they're not already part of your workflow

Please share any feedback on the new Dependency Scanning analyzer in this [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/523458).

### Bundler

**Previous behavior:** Dependency Scanning based on the Gemnasium analyzer supports Bundler projects using the `gemnasium-dependency_scanning` CI/CD job and its ability to extract the project dependencies by parsing the `Gemfile.lock` file (`gems.locked` alternate filename is also supported). The combination of supported versions of Bundler and the `Gemfile.lock` file are detailed in the [Dependency Scanning (Gemnasium-based) documentation](_index.md#obtaining-dependency-information-by-parsing-lockfiles).

**New behavior:** The new Dependency Scanning analyzer also extracts the project dependencies by parsing the `Gemfile.lock` file (`gems.locked` alternate filename is also supported) and generates a CycloneDX SBOM report artifact with the `dependency-scanning` CI/CD job.

#### Migrate a Bundler project

Migrate a Bundler project to use the new Dependency Scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.

There are no additional steps needed to migrate a Bundler project to use the Dependency Scanning analyzer.

### CocoaPods

**Previous behavior:** Dependency Scanning based on the Gemnasium analyzer does not support CocoaPods projects when using the CI/CD templates or the Scan Execution Policies. Support for CocoaPods is only available on the experimental Cocoapods CI/CD component.

**New behavior:** The new Dependency Scanning analyzer extracts the project dependencies by parsing the `Podfile.lock` file and generates a CycloneDX SBOM report artifact with the `dependency-scanning` CI/CD job.

#### Migrate a CocoaPods project

Migrate a CocoaPods project to use the new Dependency Scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.

There are no additional steps to migrate a CocoaPods project to use the Dependency Scanning analyzer.

### Composer

**Previous behavior:** Dependency Scanning based on the Gemnasium analyzer supports Composer projects using the `gemnasium-dependency_scanning` CI/CD job and its ability to extract the project dependencies by parsing the `composer.lock` file. The combination of supported versions of Composer and the `composer.lock` file are detailed in the [Dependency Scanning (Gemnasium-based) documentation](_index.md#obtaining-dependency-information-by-parsing-lockfiles).

**New behavior:** The new Dependency Scanning analyzer also extracts the project dependencies by parsing the `composer.lock` file and generates a CycloneDX SBOM report artifact with the `dependency-scanning` CI/CD job.

#### Migrate a Composer project

Migrate a Composer project to use the new Dependency Scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.

There are no additional steps to migrate a Composer project to use the Dependency Scanning analyzer.

### Conan

**Previous behavior:** Dependency Scanning based on the Gemnasium analyzer supports Conan projects using the `gemnasium-dependency_scanning` CI/CD job and its ability to extract the project dependencies by parsing the `conan.lock` file. The combination of supported versions of Conan and the `conan.lock` file are detailed in the [Dependency Scanning (Gemnasium-based) documentation](_index.md#obtaining-dependency-information-by-parsing-lockfiles).

**New behavior:** The new Dependency Scanning analyzer also extracts the project dependencies by parsing the `conan.lock` file and generates a CycloneDX SBOM report artifact with the `dependency-scanning` CI/CD job.

#### Migrate a Conan project

Migrate a Conan project to use the new Dependency Scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.

There are no additional steps to migrate a Conan project to use the Dependency Scanning analyzer.

### Go

**Previous behavior:** Dependency Scanning based on the Gemnasium analyzer supports Go projects using the `gemnasium-dependency_scanning` CI/CD job and its ability to extract the project dependencies by using the `go.mod` and `go.sum` file. This analyzer attempts to execute the `go list` command to increase the accuracy of the detected dependencies, which requires a functional Go environment. In case of failure, it falls back to parsing the `go.sum` file. The combination of supported versions of Go, the `go.mod`, and the `go.sum` files are detailed in the [Dependency Scanning (Gemnasium-based) documentation](_index.md#obtaining-dependency-information-by-parsing-lockfiles).

**New behavior:** The new Dependency Scanning analyzer does not attempt to execute the `go list` command in the project to extract the dependencies and it no longer falls back to parsing the `go.sum` file. Instead, the project must provide at least a `go.mod` file and ideally a `go.graph` file generated with the [`go mod graph` command](https://go.dev/ref/mod#go-mod-graph) from the Go Toolchains. The `go.graph` file is required to increase the accuracy of the detected components and to generate the dependency graph to enable features like the [dependency path](../dependency_list/_index.md#dependency-paths). These files are processed by the `dependency-scanning` CI/CD job to generate a CycloneDX SBOM report artifact. This approach does not require GitLab to support specific versions of Go.

#### Migrate a Go project

Migrate a Go project to use the new Dependency Scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.

To migrate a Go project:

- Ensure that your project provides a `go.mod` and a `go.graph` files. Configure the [`go mod graph` command](https://go.dev/ref/mod#go-mod-graph) from the Go Toolchains in a preceding CI/CD job (for example, `build`) to dynamically generate the `dependencies.lock` file and export it as an [artifact](../../../ci/jobs/job_artifacts.md) prior to running the Dependency Scanning job.

See the [enablement instructions for Go](dependency_scanning_sbom/_index.md#go) for more details and examples.

### Gradle

**Previous behavior:** Dependency Scanning based on the Gemnasium analyzer supports Gradle projects using the `gemnasium-maven-dependency_scanning` CI/CD job to extract the project dependencies by building the application from the `build.gradle` and `build.gradle.kts` files. The combinations of supported versions for Java, Kotlin, and Gradle are complex, as detailed in the [Dependency Scanning (Gemnasium-based) documentation](_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file).

**New behavior:** The new Dependency Scanning analyzer does not build the project to extract the dependencies. Instead, the project must provide a `dependencies.lock` file generated with the [Gradle Dependency Lock Plugin](https://github.com/nebula-plugins/gradle-dependency-lock-plugin). This file is processed by the `dependency-scanning` CI/CD job to generate a CycloneDX SBOM report artifact. This approach does not require GitLab to support specific versions of Java, Kotlin, and Gradle.

#### Migrate a Gradle project

Migrate a Gradle project to use the new Dependency Scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.

To migrate a Gradle project:

- Ensure that your project provides a `dependencies.lock` file. Configure the [Gradle Dependency Lock Plugin](https://github.com/nebula-plugins/gradle-dependency-lock-plugin) in your project and either:
  - Permanently integrate the plugin into your development workflow. This means committing the `dependencies.lock` file into your repository and updating it as you're making changes to your project dependencies.
  - Use the command in a preceding CI/CD job (for example, `build`) to dynamically generate the `dependencies.lock` file and export it as an [artifact](../../../ci/jobs/job_artifacts.md) prior to running the Dependency Scanning job.

See the [enablement instructions for Gradle](dependency_scanning_sbom/_index.md#gradle) for more details and examples.

### Maven

**Previous behavior:** Dependency Scanning based on the Gemnasium analyzer supports Maven projects using the `gemnasium-maven-dependency_scanning` CI/CD job to extract the project dependencies by building the application from the `pom.xml` file. The combinations of supported versions for Java, Kotlin, and Maven are complex, as detailed in the [Dependency Scanning (Gemnasium-based) documentation](_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file).

**New behavior:** The new Dependency Scanning analyzer does not build the project to extract the dependencies. Instead, the project must provide a `maven.graph.json` file generated with the [maven dependency plugin](https://maven.apache.org/plugins/maven-dependency-plugin/index.html). This file is processed by the `dependency-scanning` CI/CD job to generate a CycloneDX SBOM report artifact. This approach does not require GitLab to support specific versions of Java, Kotlin, and Maven.

#### Migrate a Maven project

Migrate a Maven project to use the new Dependency Scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.

To migrate a Maven project:

- Ensure that your project provides a `maven.graph.json` file. Configure the [maven dependency plugin](https://maven.apache.org/plugins/maven-dependency-plugin/index.html) in a preceding CI/CD job (e.g. `build`) to dynamically generate the `maven.graph.json` file and export it as an [artifact](../../../ci/jobs/job_artifacts.md) prior to running the Dependency Scanning job.

See the [enablement instructions for Maven](dependency_scanning_sbom/_index.md#maven) for more details and examples.

### npm

**Previous behavior:** Dependency Scanning based on the Gemnasium analyzer supports npm projects using the `gemnasium-dependency_scanning` CI/CD job and its ability to extract the project dependencies by parsing the `package-lock.json` or `npm-shrinkwrap.json.lock` files. The combination of supported versions of npm and the `package-lock.json` or `npm-shrinkwrap.json.lock` files are detailed in the [Dependency Scanning (Gemnasium-based) documentation](_index.md#obtaining-dependency-information-by-parsing-lockfiles).
This analyzer may scan JavaScript files vendored in a npm project using the `Retire.JS` scanner.

**New behavior:** The new Dependency Scanning analyzer also extracts the project dependencies by parsing the `package-lock.json` or `npm-shrinkwrap.json.lock` files and generates a CycloneDX SBOM report artifact with the `dependency-scanning` CI/CD job.
This analyzer does not scan vendored JavaScript files. Support for a replacement feature is proposed in [epic 7186](https://gitlab.com/groups/gitlab-org/-/epics/7186).

#### Migrate an npm project

Migrate an npm project to use the new Dependency Scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.

There are no additional steps to migrate an npm project to use the Dependency Scanning analyzer.

### NuGet

**Previous behavior:** Dependency Scanning based on the Gemnasium analyzer supports NuGet projects using the `gemnasium-dependency_scanning` CI/CD job and its ability to extract the project dependencies by parsing the `packages.lock.json` file. The combination of supported versions of NuGet and the `packages.lock.json` file are detailed in the [Dependency Scanning (Gemnasium-based) documentation](_index.md#obtaining-dependency-information-by-parsing-lockfiles).

**New behavior:** The new Dependency Scanning analyzer also extracts the project dependencies by parsing the `packages.lock.json` file and generates a CycloneDX SBOM report artifact with the `dependency-scanning` CI/CD job.

#### Migrate a NuGet project

Migrate a NuGet project to use the new Dependency Scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.

There are no additional steps to migrate a NuGet project to use the Dependency Scanning analyzer.

### pip

**Previous behavior:** Dependency Scanning based on the Gemnasium analyzer supports pip projects using the `gemnasium-python-dependency_scanning` CI/CD job to extract the project dependencies by building the application from the `requirements.txt` file (`requirements.pip` and `requires.txt` alternate filenames are also supported). The `PIP_REQUIREMENTS_FILE` environment variable can also be used to specify a custom filename. The combinations of supported versions for Python and pip are detailed in the [Dependency Scanning (Gemnasium-based) documentation](_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file).

**New behavior:** The new Dependency Scanning analyzer does not build the project to extract the dependencies. Instead, the project must provide a `requirements.txt` lockfile generated by the [pip-compile command line tool](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/). This file is processed by the `dependency-scanning` CI/CD job to generate a CycloneDX SBOM report artifact. This approach does not require GitLab to support specific versions of Python and pip. The `DS_PIPCOMPILE_REQUIREMENTS_FILE_NAME_PATTERN` environment variable can also be used to specify custom filnames for pip-compile lockfiles.

Alternatively, the project can provide a `pipdeptree.json` file generated with the [pipdeptree command line utility](https://pypi.org/project/pipdeptree/).

#### Migrate a pip project

Migrate a pip project to use the new Dependency Scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.

To migrate a pip project:

- Ensure that your project provides a `requirements.txt` lockfile. Configure the [pip-compile command line tool](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/) in your project and either:
  - Permanently integrate the command line tool into your development workflow. This means committing the `requirements.txt` file into your repository and updating it as you're making changes to your project dependencies.
  - Use the command line tool in a preceding CI/CD job (e.g. `build`) to dynamically generate the `requirements.txt` file and export it as an [artifact](../../../ci/jobs/job_artifacts.md) prior to running the Dependency Scanning job.

OR

- Ensure that your project provides a `pipdeptree.json` lockfile. Configure the [pipdeptree command line utility](https://pypi.org/project/pipdeptree/) in a preceding CI/CD job (e.g. `build`) to dynamically generate the `pipdeptree.json` file and export it as an [artifact](../../../ci/jobs/job_artifacts.md) prior to running the Dependency Scanning job.

See the [enablement instructions for pip](dependency_scanning_sbom/_index.md#pip) for more details and examples.

### Pipenv

**Previous behavior:** Dependency Scanning based on the Gemnasium analyzer supports Pipenv projects using the `gemnasium-python-dependency_scanning` CI/CD job to extract the project dependencies by building the application from the `Pipfile` file or from a `Pipfile.lock` file if present. The combinations of supported versions for Python and Pipenv are detailed in the [Dependency Scanning (Gemnasium-based) documentation](_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file).

**New behavior:** The new Dependency Scanning analyzer does not build the Pipenv project to extract the dependencies. Instead, the project must provide at least a `Pipfile.lock` file and ideally a `pipenv.graph.json` file generated by the [`pipenv graph` command](https://pipenv.pypa.io/en/latest/cli.html#graph). The `pipenv.graph.json` file is required to generate the dependency graph and enable features like the [dependency path](../dependency_list/_index.md#dependency-paths). These files are processed by the `dependency-scanning` CI/CD job to generate a CycloneDX SBOM report artifact. This approach does not require GitLab to support specific versions of Python and Pipenv.

#### Migrate a Pipenv project

Migrate a Pipenv project to use the new Dependency Scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.

To migrate a Pipenv project:

- Ensure that your project provides a `Pipfile.lock` file. Configure the [`pipenv lock` command](https://pipenv.pypa.io/en/latest/cli.html#graph) in your project and either:
  - Permanently integrate the command into your development workflow. This means committing the `Pipfile.lock` file into your repository and updating it as you're making changes to your project dependencies.
  - Use the command in a preceding CI/CD job (for example, `build`) to dynamically generate the `Pipfile.lock` file and export it as an [artifact](../../../ci/jobs/job_artifacts.md) prior to running the Dependency Scanning job.

OR

- Ensure that your project provides a `pipenv.graph.json` file. Configure the [`pipenv graph` command](https://pipenv.pypa.io/en/latest/cli.html#graph) in a preceding CI/CD job (for example, `build`) to dynamically generate the `pipenv.graph.json` file and export it as an [artifact](../../../ci/jobs/job_artifacts.md) prior to running the Dependency Scanning job.

See the [enablement instructions for Pipenv](dependency_scanning_sbom/_index.md#pipenv) for more details and examples.

### Poetry

**Previous behavior:** Dependency Scanning based on the Gemnasium analyzer supports Poetry projects using the `gemnasium-python-dependency_scanning` CI/CD job and its ability to extract the project dependencies by parsing the `poetry.lock` file. The combination of supported versions of Poetry and the `poetry.lock` file are detailed in the [Dependency Scanning (Gemnasium-based) documentation](_index.md#obtaining-dependency-information-by-parsing-lockfiles).

**New behavior:** The new Dependency Scanning analyzer also extracts the project dependencies by parsing the `poetry.lock` file and generates a CycloneDX SBOM report artifact with the `dependency-scanning` CI/CD job.

#### Migrate a Poetry project

Migrate a Poetry project to use the new Dependency Scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.

There are no additional steps to migrate a Poetry project to use the Dependency Scanning analyzer.

### pnpm

**Previous behavior:** Dependency Scanning based on the Gemnasium analyzer supports pnpm projects using the `gemnasium-dependency_scanning` CI/CD job and its ability to extract the project dependencies by parsing the `pnpm-lock.yaml` file. The combination of supported versions of pnpm and the `pnpm-lock.yaml` file are detailed in the [Dependency Scanning (Gemnasium-based) documentation](_index.md#obtaining-dependency-information-by-parsing-lockfiles).
This analyzer may scan JavaScript files vendored in a npm project using the `Retire.JS` scanner.

**New behavior:** The new Dependency Scanning analyzer also extracts the project dependencies by parsing the `pnpm-lock.yaml` file and generates a CycloneDX SBOM report artifact with the `dependency-scanning` CI/CD job.
This analyzer does not scan vendored JavaScript files. Support for a replacement feature is proposed in [epic 7186](https://gitlab.com/groups/gitlab-org/-/epics/7186).

#### Migrate a pnpm project

Migrate a pnpm project to use the new Dependency Scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.

There is no additional steps to migrate a pnpm project to use the Dependency Scanning analyzer.

### sbt

**Previous behavior:** Dependency Scanning based on the Gemnasium analyzer supports sbt projects using the `gemnasium-maven-dependency_scanning` CI/CD job to extract the project dependencies by building the application from the `build.sbt` file. The combinations of supported versions for Java, Scala, and sbt are complex, as detailed in the [Dependency Scanning (Gemnasium-based) documentation](_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file).

**New behavior:** The new Dependency Scanning analyzer does not build the project to extract the dependencies. Instead, the project must provide a `dependencies-compile.dot` file generated with the [sbt-dependency-graph plugin](https://github.com/sbt/sbt-dependency-graph) ([included in sbt >= 1.4.0](https://www.scala-sbt.org/1.x/docs/sbt-1.4-Release-Notes.html#sbt-dependency-graph+is+in-sourced)). This file is processed by the `dependency-scanning` CI/CD job to generate a CycloneDX SBOM report artifact. This approach does not require GitLab to support specific versions of Java, Scala, and sbt.

#### Migrate an sbt project

Migrate an sbt project to use the new Dependency Scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.

To migrate an sbt project:

- Ensure that your project provides a `dependencies-compile.dot` file. Configure the [sbt-dependency-graph plugin](https://github.com/sbt/sbt-dependency-graph) in a preceding CI/CD job (e.g. `build`) to dynamically generate the `dependencies-compile.dot` file and export it as an [artifact](../../../ci/jobs/job_artifacts.md) prior to running the Dependency Scanning job.

See the [enablement instructions for sbt](dependency_scanning_sbom/_index.md#sbt) for more details and examples.

### setuptools

**Previous behavior:** Dependency Scanning based on the Gemnasium analyzer supports setuptools projects using the `gemnasium-python-dependency_scanning` CI/CD job to extract the project dependencies by building the application from the `setup.py` file. The combinations of supported versions for Python and setuptools are detailed in the [Dependency Scanning (Gemnasium-based) documentation](_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file).

**New behavior:** The new Dependency Scanning analyzer does not support building a setuptool project to extract the dependencies. We recommend to configure the [pip-compile command line tool](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/) to generate a compatible `requirements.txt` lockfile. Alternatively you can provide your own CycloneDX SBOM document.

#### Migrate a setuptools project

Migrate a setuptools project to use the new Dependency Scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.

To migrate a setuptools project:

- Ensure that your project provides a `requirements.txt` lockfile. Configure the [pip-compile command line tool](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/) in your project and either:
  - Permanently integrate the command line tool into your development workflow. This means committing the `requirements.txt` file into your repository and updating it as you're making changes to your project dependencies.
  - Use the command line tool in a `build` CI/CD job to dynamically generate the `requirements.txt` file and export it as an [artifact](../../../ci/jobs/job_artifacts.md) prior to running the Dependency Scanning job.

See the [enablement instructions for pip](dependency_scanning_sbom/_index.md#pip) for more details and examples.

### Swift

**Previous behavior:** Dependency Scanning based on the Gemnasium analyzer does not support Swift projects when using the CI/CD templates or the Scan Execution Policies. Support for Swift is only available on the experimental Swift CI/CD component.

**New behavior:** The new Dependency Scanning analyzer also extracts the project dependencies by parsing the `Package.resolved` file and generates a CycloneDX SBOM report artifact with the `dependency-scanning` CI/CD job.

#### Migrate a Swift project

Migrate a Swift project to use the new Dependency Scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.

There are no additional steps to migrate a Swift project to use the Dependency Scanning analyzer.

### uv

**Previous behavior:** Dependency Scanning based on the Gemnasium analyzer supports uv projects using the `gemnasium-dependency_scanning` CI/CD job and its ability to extract the project dependencies by parsing the `uv.lock` file. The combination of supported versions of uv and the `uv.lock` file are detailed in the [Dependency Scanning (Gemnasium-based) documentation](_index.md#obtaining-dependency-information-by-parsing-lockfiles).

**New behavior:** The new Dependency Scanning analyzer also extracts the project dependencies by parsing the `uv.lock` file and generates a CycloneDX SBOM report artifact with the `dependency-scanning` CI/CD job.

#### Migrate a uv project

Migrate a uv project to use the new Dependency Scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.

There are no additional steps to migrate a uv project to use the Dependency Scanning analyzer.

### Yarn

**Previous behavior:** Dependency Scanning based on the Gemnasium analyzer supports Yarn projects using the `gemnasium-dependency_scanning` CI/CD job and its ability to extract the project dependencies by parsing the `yarn.lock` file. The combination of supported versions of Yarn and the `yarn.lock` files are detailed in the [Dependency Scanning (Gemnasium-based) documentation](_index.md#obtaining-dependency-information-by-parsing-lockfiles).
This analyzer may provide remediation data to [resolve a vulnerability via merge request](../vulnerabilities/_index.md#resolve-a-vulnerability) for Yarn dependencies.
This analyzer may scan JavaScript files vendored in a Yarn project using the `Retire.JS` scanner.

**New behavior:** The new Dependency Scanning analyzer also extracts the project dependencies by parsing the `yarn.lock` file and generates a CycloneDX SBOM report artifact with the `dependency-scanning` CI/CD job.
This analyzer does not provide remediations data for Yarn dependencies. Support for a replacement feature is proposed in [epic 759](https://gitlab.com/groups/gitlab-org/-/epics/759).
This analyzer does not scan vendored JavaScript files. Support for a replacement feature is proposed in [epic 7186](https://gitlab.com/groups/gitlab-org/-/epics/7186).

#### Migrate a Yarn project

Migrate a Yarn project to use the new Dependency Scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.

There are no additional steps to migrate a Yarn project to use the Dependency Scanning analyzer. If you use the Resolve a vulnerability via merge request feature please check [the deprecation announcement](../../../update/deprecations.md#resolve-a-vulnerability-for-dependency-scanning-on-yarn-projects) for available actions. If you use the JavaScript vendored files scan feature, please check the [deprecation announcement](../../../update/deprecations.md#dependency-scanning-for-javascript-vendored-libraries) for available actions.

## Changes to CI/CD variables

Most of the existing CI/CD variables are no longer relevant with the new Dependency Scanning analyzer so their values will be ignored.
Unless these are also used to configure other security analyzers (for example, `ADDITIONAL_CA_CERT_BUNDLE`), you should remove them from your CI/CD configuration.

Remove the following CI/CD variables from your CI/CD configuration:

- `ADDITIONAL_CA_CERT_BUNDLE`
- `DS_GRADLE_RESOLUTION_POLICY`
- `DS_IMAGE_SUFFIX`
- `DS_JAVA_VERSION`
- `DS_PIP_DEPENDENCY_PATH`
- `DS_PIP_VERSION`
- `DS_REMEDIATE_TIMEOUT`
- `DS_REMEDIATE`
- `GEMNASIUM_DB_LOCAL_PATH`
- `GEMNASIUM_DB_REF_NAME`
- `GEMNASIUM_DB_REMOTE_URL`
- `GEMNASIUM_DB_UPDATE_DISABLED`
- `GEMNASIUM_LIBRARY_SCAN_ENABLED`
- `GOARCH`
- `GOFLAGS`
- `GOOS`
- `GOPRIVATE`
- `GRADLE_CLI_OPTS`
- `GRADLE_PLUGIN_INIT_PATH`
- `MAVEN_CLI_OPTS`
- `PIP_EXTRA_INDEX_URL`
- `PIP_INDEX_URL`
- `PIP_REQUIREMENTS_FILE`
- `PIPENV_PYPI_MIRROR`
- `SBT_CLI_OPTS`

Keep the following CI/CD variables as they are applicable to the new Dependency Scanning analyzer:

- `DS_EXCLUDED_ANALYZERS`*
- `DS_EXCLUDED_PATHS`
- `DS_INCLUDE_DEV_DEPENDENCIES`
- `DS_MAX_DEPTH`
- `SECURE_ANALYZERS_PREFIX`

{{< alert type="note" >}}

The `PIP_REQUIREMENTS_FILE` is replaced with `DS_PIPCOMPILE_REQUIREMENTS_FILE_NAME_PATTERN` in the new Dependency Scanning analyzer.

The `DS_EXCLUDED_ANALYZERS` can now contain a new value `dependency-scanning` to prevent the new Dependency Scanning analyzer job from running.

{{< /alert >}}

## Continue with the Gemnasium analyzer

You can continue using the deprecated Gemnasium analyzer with your existing CI/CD configuration, including all your current CI/CD variables.
GitLab will continue to support it until the [Dependency Scanning using SBOM](dependency_scanning_sbom/_index.md) feature and the [new Dependency Scanning analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning)
are Generally Available. This work is tracked in [this epic](https://gitlab.com/groups/gitlab-org/-/epics/15961)
