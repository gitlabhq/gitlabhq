---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migrating to dependency scanning using SBOM
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- The dependency scanning feature based on the Gemnasium analyzer is deprecated in GitLab 17.9 and is proposed for removal in GitLab 20.0. However, the removal timeline is not finalized, and you can continue using Gemnasium as needed.

{{< /history >}}

The dependency scanning feature is upgrading to the GitLab SBOM Vulnerability Scanner.
As part of this change, the [dependency scanning using SBOM](dependency_scanning_sbom/_index.md) feature and the [new dependency scanning analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning)
replace the legacy dependency scanning feature based on the [Gemnasium analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium).
However, existing projects are not migrated automatically because of the significant changes introduced in this transition.

Follow this migration guide if you use GitLab dependency scanning and any of the following conditions apply:

- The dependency scanning CI/CD jobs are configured by including a dependency scanning CI/CD templates.

  ```yaml
    include:
      - template: Jobs/Dependency-Scanning.gitlab-ci.yml
      - template: Jobs/Dependency-Scanning.latest.gitlab-ci.yml
  ```

- The dependency scanning CI/CD jobs are configured by using [Scan Execution Policies](../policies/scan_execution_policies.md).
- The dependency scanning CI/CD jobs are configured by using [Pipeline Execution Policies](../policies/pipeline_execution_policies.md).

## Understand the changes

Before you migrate your project to dependency scanning using SBOM, you should
understand the fundamental changes being introduced. The transition represents a
technical evolution, a new approach to how dependency scanning works in GitLab,
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
  Builds invoked by the Gemnasium analyzers can last for almost an hour and often duplicate work
  already done by the project's own build jobs. The new analyzer prefers existing lockfiles or
  dependency graph exports, and runs only for ecosystems that lack lockfiles. These [jobs](dependency_scanning_sbom/_index.md#dependency-resolution)
  use minimal ecosystem images and run native package manager commands to produce a project's
  dependency graph. The generated dependency graphs are stored as file artifacts and
  are passed to the `dependency-scanning` job for security scanning and SBOM creation.
- Smaller attack surface.
  To support their build capabilities, the Gemnasium analyzers ship with a wide range of
  preloaded toolchains and dependencies. The new analyzer separates dependency detection from
  dependency resolution. The analyzer image carries only what it needs to parse lockfiles and
  graph exports. Dependency resolution runs in dedicated, minimal ecosystem images. Each
  image carries only the build tool needed for its ecosystem.
- More flexible configuration.
  The deprecated Gemnasium analyzers frequently require configuration of proxies, Certificate
  Authority (CA) certificate bundles, and other utilities inside a single image that bundles
  every supported ecosystem. The new analyzer separates concerns. The analyzer itself needs
  little configuration. Ecosystem-specific settings (private registries, custom CA bundles,
  JVM options) apply only to the relevant dependency resolution job. You can also override the
  resolution images to match your build environment.

### A new approach to security scanning

When using the legacy dependency scanning feature, all scanning work happens in your CI/CD pipeline. When running a scan, the Gemnasium analyzer handles two critical tasks simultaneously: it identifies your project's dependencies and immediately performs a security analysis of those dependencies using a local copy of the GitLab advisory database and its specific security scanning engine. Then, it outputs results into various reports (CycloneDX SBOM and dependency scanning security report).

On the other hand, the dependency scanning using SBOM feature relies on a decomposed dependency analysis approach that separates dependency detection from other analyses, like static reachability or vulnerability scanning. While these tasks are still executed in the same CI/CD job, they function as decoupled, reusable components. For instance, the vulnerability scanning analysis reuses the unified engine, the GitLab SBOM vulnerability scanner, that also supports GitLab continuous vulnerability scanning features. This also opens up opportunity for future integration points, enabling more flexible vulnerability scanning workflows.

Read more about how dependency scanning using SBOM [scans an application](dependency_scanning_sbom/_index.md#how-it-scans-an-application).

### CI/CD configuration

To prevent disruption to your CI/CD pipelines, the new approach does not apply to the stable dependency scanning CI/CD template (`Dependency-Scanning.gitlab-ci.yml`) and as of GitLab 18.5, you must use the `v2` template (`Dependency-Scanning.v2.gitlab-ci.yml`) to enable it.
Other migration paths might be considered as the feature gains maturity.

If you're using [Scan Execution Policies](../policies/scan_execution_policies.md), these changes apply in the same way because they build upon the CI/CD templates.

If you're using the [main dependency scanning CI/CD component](https://gitlab.com/components/dependency-scanning/-/tree/main/templates/main) you won't see any changes as it already employs the new analyzer.
However, if you're using the specialized components for Android, Rust, Swift, or CocoaPods, you'll need to migrate to the main component that now covers all supported languages and package managers.

### Dependency detection for Gradle, Maven, and Python

The new analyzer changes how dependencies are discovered for Gradle, Maven, and Python projects. Instead of building your application
to determine dependencies, the analyzer uses a multi-tiered detection model that follows the "accuracy is a dial" principle:

1. Lockfile or dependency graph export: When a supported file is committed to the repository or passed as a job
   artifact (like `maven.graph.json`, `dependencies.lock`, `requirements.txt`, `Pipfile.lock`), the analyzer
   uses it directly. This is the most accurate option.
1. [Dependency resolution](dependency_scanning_sbom/_index.md#dependency-resolution): When no supported file exists
   for Maven, Gradle, or Python projects, the analyzer attempts to generate one automatically. Resolution jobs run in the `.pre`
   stage with minimal ecosystem images and native commands (like `mvn dependency:tree`, `pip-compile`,
   `gradle dependencies`). The `dependency-scanning` job uses the generated artifacts.
1. [Manifest fallback](dependency_scanning_sbom/_index.md#manifest-fallback): When no lockfile or dependency
   graph file exist, the analyzer parses supported manifest files (like `pom.xml`, `requirements.txt`,
   `build.gradle`, `build.gradle.kts`) to extract direct dependencies only. Transitive dependencies are not detected and
   exact resolved versions cannot be determined.

Dependency resolution and manifest fallback are turned off by default during the limited availability. To turn them
on, see the [dependency resolution](dependency_scanning_sbom/_index.md#dependency-resolution) and
[manifest fallback](dependency_scanning_sbom/_index.md#manifest-fallback) documentation.

For the most accurate results, commit a lockfile or dependency graph export to your repository, or generate one in a
preceding CI/CD job using your project's actual build environment. The following sections describe the options available
for each language and package manager.

### Accessing scan results

Users can view dependency scanning results as a job artifact (`gl-dependency-scanning-report.json`) when using `Dependency-Scanning.v2.gitlab-ci.yml`.

#### Beta behavior

The dependency scanning report artifact is included in the Generally Available release.
The Beta behavior is documented below for historical reference, but is no longer
officially supported and might be removed from the product.

<details>
  <summary>Expand this section for details of changes to how you access vulnerability scanning results.</summary>

  When you migrate to dependency scanning using SBOM, you'll notice a fundamental change in how security scan results are handled. The new approach moves the security analysis out of the CI/CD pipeline and into the GitLab platform, which changes how you access and work with the results.
  With the legacy dependency scanning feature, CI/CD jobs using the Gemnasium analyzer generate a [dependency scanning report artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportsdependency_scanning) containing the scan results, and upload it to the platform. You can access these results by all possible ways offered to job artifacts. This means you can process or modify the results within your CI/CD pipeline before they reach the GitLab platform.
  The dependency scanning using SBOM approach works differently. The security analysis now happens within the GitLab platform using the built-in GitLab SBOM Vulnerability Scanner, so you won't find the scan results in your job artifacts anymore. Instead, GitLab analyzes the [CycloneDX SBOM report artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx) that your CI/CD pipeline generates, creating security findings directly in the GitLab platform.
  To help you transition smoothly, GitLab maintains some backward compatibility. While using the Gemnasium analyzer, you'll still get a standard artifact (using `artifacts:paths`) that contains the scan results. This means if you have succeeding CI/CD jobs that need these results, they can still access them. However, keep in mind that as the GitLab SBOM Vulnerability Scanner evolves and improves, these artifact-based results won't reflect the latest enhancements.
  When you're ready to fully migrate to the new dependency scanning analyzer, you'll need to adjust how you programmatically access scan results. Instead of reading job artifacts, you'll use GitLab GraphQL API, specifically the ([`Pipeline.securityReportFindings` resource](../../../api/graphql/reference/_index.md#pipelinesecurityreportfindings)).
</details>

### Compliance framework considerations

When migrating to SBOM-based dependency scanning, be aware of potential impacts on compliance frameworks:

- The "Dependency scanning running" compliance control may fail on GitLab Self-Managed instances (from 18.4) when using SBOM-based scanning because it expects the traditional `gl-dependency-scanning-report.json` artifact.
- This issue does not affect GitLab.com instances.
- If your organization uses compliance frameworks with dependency scanning controls, test the migration in a non-production environment first.

For more information, see [compliance framework compatibility](dependency_scanning_sbom/troubleshooting_ds_sbom_analyzer.md#compliance-framework-compatibility).

## Identify affected projects

Identifying which projects need attention helps you plan your migration. Gradle, Maven, and Python projects are most affected
because dependency detection works differently in the new analyzer. With [dependency resolution](dependency_scanning_sbom/_index.md#dependency-resolution)
and [manifest fallback](dependency_scanning_sbom/_index.md#manifest-fallback) turned on, many of these projects can scan
out of the box at a baseline accuracy. Projects that need the highest accuracy still benefit from a committed lockfile
or dependency graph export.
This tool examines your GitLab group or GitLab Self-Managed instance and identifies projects that currently use the
`gemnasium-maven-dependency_scanning` or `gemnasium-python-dependency_scanning` CI/CD jobs. The tool's report helps you
prioritize projects when you plan to migrate across your organization.

## Migrate to dependency scanning using SBOM

Prerequisites:

- To edit the `.gitlab-ci.yml` file or use the CI/CD component: The Developer, Maintainer, or Owner role for the project.
- To edit scan execution or pipeline execution policies: The Owner role for the group, or a custom role with `manage_security_policy_link` permission.

To migrate to the dependency scanning using SBOM method, perform the following steps for each project:

1. Remove existing customization for dependency scanning based on the Gemnasium analyzer.
   - If you have manually overridden the `gemnasium-dependency_scanning`, `gemnasium-maven-dependency_scanning`, or `gemnasium-python-dependency_scanning` CI/CD jobs to customize them in a project's `.gitlab-ci.yml` or in the CI/CD configuration for a Pipeline Execution Policy, remove them.
   - If you have configured any of [the impacted CI/CD variables](#changes-to-cicd-variables), adjust your configuration accordingly.
1. Enable the dependency scanning using SBOM feature with one of the following options:
   - **Recommended**: Use the `v2` dependency scanning CI/CD template `Dependency-Scanning.v2.gitlab-ci.yml` to run the new dependency scanning analyzer:
     1. Ensure your `.gitlab-ci.yml` CI/CD configuration includes the `v2` dependency scanning CI/CD template.
     1. Adjust your project and your CI/CD configuration if needed by following the language-specific instructions below.
   - Use a [scan execution policy](dependency_scanning_sbom/_index.md#enforce-scanning-on-multiple-projects) to run the new dependency scanning analyzer:
     1. Edit the configured scan execution policy for dependency scanning and ensure it uses the `v2` template.
     1. Adjust your project and your CI/CD configuration if needed by following the language-specific instructions below.
   - Use a [pipeline execution policy](dependency_scanning_sbom/_index.md#enforce-scanning-on-multiple-projects) to run the new dependency scanning analyzer:
     1. Edit the configured pipeline execution policy and ensure it uses the `v2` template.
     1. Adjust your project and your CI/CD configuration if needed by following the language-specific instructions below.
   - Use the [dependency scanning CI/CD component](https://gitlab.com/explore/catalog/components/dependency-scanning) to run the new dependency scanning analyzer:
     1. Replace the dependency scanning CI/CD template's `include` statement with the dependency scanning CI/CD component in your `.gitlab-ci.yml` CI/CD configuration.
     1. Adjust your project and your CI/CD configuration if needed by following the language-specific instructions below.

For multi-language projects, complete all relevant language-specific migration steps.

> [!note]
> If you decide to migrate from the CI/CD template to the CI/CD component, review the [current limitations](../../../ci/components/_index.md#use-a-gitlabcom-component-on-gitlab-self-managed) for GitLab Self-Managed.

## Language-specific instructions

As you migrate to the new dependency scanning analyzer, you'll need to make specific adjustments based on your project's programming languages and package managers. These instructions apply whenever you use the new dependency scanning analyzer,
regardless of how you've configured it to run - whether through CI/CD templates, Scan Execution Policies, or the dependency scanning CI/CD component.
In the following sections, you'll find detailed instructions for each supported language and package manager. Each instruction has explanations for:

- How dependency detection is changing
- What specific files you need to provide
- How to generate these files if they're not already part of your workflow

Share any feedback on the new dependency scanning analyzer in this [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/523458).

### Bundler

**Previous behavior**: Dependency scanning based on the Gemnasium analyzer supports Bundler projects using the `gemnasium-dependency_scanning` CI/CD job and its ability to extract the project dependencies by parsing the `Gemfile.lock` file (`gems.locked` alternate filename is also supported). The combination of supported versions of Bundler and the `Gemfile.lock` file are detailed in the [dependency scanning (Gemnasium-based) documentation](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles).

**New behavior**: The new dependency scanning analyzer also extracts the project dependencies by parsing the `Gemfile.lock` file (`gems.locked` alternate filename is also supported) and generates a CycloneDX SBOM report artifact with the `dependency-scanning` CI/CD job.

#### Migrate a Bundler project

Migrate a Bundler project to use the new dependency scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.
- The Developer, Maintainer, or Owner role for the project.

There are no additional steps needed to migrate a Bundler project to use the dependency scanning analyzer.

### CocoaPods

**Previous behavior**: Dependency scanning based on the Gemnasium analyzer does not support CocoaPods projects when using the CI/CD templates or the Scan Execution Policies. Support for CocoaPods is only available on the experimental CocoaPods CI/CD component.

**New behavior**: The new dependency scanning analyzer extracts the project dependencies by parsing the `Podfile.lock` file and generates a CycloneDX SBOM report artifact with the `dependency-scanning` CI/CD job.

#### Migrate a CocoaPods project

Migrate a CocoaPods project to use the new dependency scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.
- The Developer, Maintainer, or Owner role for the project.

There are no additional steps to migrate a CocoaPods project to use the dependency scanning analyzer.

### Composer

**Previous behavior**: Dependency scanning based on the Gemnasium analyzer supports Composer projects using the `gemnasium-dependency_scanning` CI/CD job and its ability to extract the project dependencies by parsing the `composer.lock` file. The combination of supported versions of Composer and the `composer.lock` file are detailed in the [dependency scanning (Gemnasium-based) documentation](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles).

**New behavior**: The new dependency scanning analyzer also extracts the project dependencies by parsing the `composer.lock` file and generates a CycloneDX SBOM report artifact with the `dependency-scanning` CI/CD job.

#### Migrate a Composer project

Migrate a Composer project to use the new dependency scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.
- The Developer, Maintainer, or Owner role for the project.

There are no additional steps to migrate a Composer project to use the dependency scanning analyzer.

### Conan

**Previous behavior**: Dependency scanning based on the Gemnasium analyzer supports Conan projects using the `gemnasium-dependency_scanning` CI/CD job and its ability to extract the project dependencies by parsing the `conan.lock` file. The combination of supported versions of Conan and the `conan.lock` file are detailed in the [dependency scanning (Gemnasium-based) documentation](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles).

**New behavior**: The new dependency scanning analyzer also extracts the project dependencies by parsing the `conan.lock` file and generates a CycloneDX SBOM report artifact with the `dependency-scanning` CI/CD job.

#### Migrate a Conan project

Migrate a Conan project to use the new dependency scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.
- The Developer, Maintainer, or Owner role for the project.

There are no additional steps to migrate a Conan project to use the dependency scanning analyzer.

### Go

**Previous behavior**: Dependency scanning based on the Gemnasium analyzer supports Go projects using the `gemnasium-dependency_scanning` CI/CD job and its ability to extract the project dependencies by using the `go.mod` and `go.sum` file. This analyzer attempts to execute the `go list` command to increase the accuracy of the detected dependencies, which requires a functional Go environment. In case of failure, it falls back to parsing the `go.sum` file. The combination of supported versions of Go, the `go.mod`, and the `go.sum` files are detailed in the [dependency scanning (Gemnasium-based) documentation](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles).

**New behavior**: The new dependency scanning analyzer does not attempt to execute the `go list` command in the project to extract the dependencies and it no longer falls back to parsing the `go.sum` file. Instead, the project must provide at least a `go.mod` file and ideally a `go.graph` file generated with the [`go mod graph` command](https://go.dev/ref/mod#go-mod-graph) from the Go Toolchains. The `go.graph` file is required to increase the accuracy of the detected components and to generate the dependency graph to enable features like the [dependency path](../dependency_list/_index.md#dependency-paths). These files are processed by the `dependency-scanning` CI/CD job to generate a CycloneDX SBOM report artifact. This approach does not require GitLab to support specific versions of Go.
[Dependency resolution](dependency_scanning_sbom/_index.md#dependency-resolution) is not supported for Go projects.

#### Migrate a Go project

Migrate a Go project to use the new dependency scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.
- The Developer, Maintainer, or Owner role for the project.

To migrate a Go project:

- Ensure that your project provides a `go.mod` and a `go.graph` files. Configure the [`go mod graph` command](https://go.dev/ref/mod#go-mod-graph) from the Go Toolchains in a preceding CI/CD job (for example: `build`) to dynamically generate the `go.graph` file and export it as an [artifact](../../../ci/jobs/job_artifacts.md) prior to running the dependency scanning job.

See the [enablement instructions for Go](dependency_scanning_sbom/_index.md#go) for more details and examples.

### Gradle

**Previous behavior**: Dependency scanning based on the Gemnasium analyzer supports Gradle projects using the `gemnasium-maven-dependency_scanning` CI/CD job to extract the project dependencies by building the application from the `build.gradle` and `build.gradle.kts` files. The combinations of supported versions for Java, Kotlin, and Gradle are complex, as detailed in the [dependency scanning (Gemnasium-based) documentation](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file).

**New behavior**: The new dependency scanning analyzer does not build the project to extract the dependencies. Instead, it uses a multi-tiered detection model:

- If a [supported lockfile or graph export](dependency_scanning_sbom/_index.md#supported-languages-and-files)
  exists in the repository or a job artifact (like, `gradle.lockfile`), the analyzer uses it directly.
- If no supported lockfile or graph export is detected but a supported build file exists
  (like, `build.gradle`), a [dependency resolution](dependency_scanning_sbom/_index.md#dependency-resolution)
  job runs in the `.pre` stage. It automatically executes `gradle dependencies` to generate a
  dependency graph export for the `dependency-scanning` job.
- If dependency resolution is not available or fails, [manifest fallback](dependency_scanning_sbom/_index.md#manifest-fallback)
  parses `build.gradle` and `build.gradle.kts` directly to extract direct dependencies only.
  Manifest fallback accuracy is reduced for projects that declare dependencies through `gradle.properties` or
  `gradle/libs.versions.toml`, because version variables are not always resolved.

#### Migrate a Gradle project

Migrate a Gradle project to use the new dependency scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.
- The Developer, Maintainer, or Owner role for the project.

To migrate a Gradle project, choose one of the following options:

- For the most accurate results, ensure that your project provides a dependency graph export file.
  Configure the [Gradle dependencies task](https://docs.gradle.org/current/userguide/viewing_debugging_dependencies.html) in a preceding CI/CD job (for example: `build`)
  to dynamically generate the `gradle.graph.txt` file and export it as an [artifact](../../../ci/jobs/job_artifacts.md) prior to running the dependency scanning job.
  Alternatively, you can select another [supported lockfile or graph export](dependency_scanning_sbom/_index.md#supported-languages-and-files).
  When you generate a lockfile or graph export dynamically, disable automatic dependency resolution by adding `gradle` to
  the `DS_DISABLED_RESOLUTION_JOBS` CI/CD variable value.
- Rely on [dependency resolution](dependency_scanning_sbom/_index.md#dependency-resolution) to automatically generate the `gradle.graph.txt` file.
  Verify that the resolution image can successfully generate the graph export.
- Defer to [manifest fallback](dependency_scanning_sbom/_index.md#manifest-fallback) for baseline coverage of direct dependencies declared in `build.gradle` or `build.gradle.kts`.

See the [enablement instructions for Gradle](dependency_scanning_sbom/_index.md#gradle) for more details and examples.

### Maven

**Previous behavior**: Dependency scanning based on the Gemnasium analyzer supports Maven projects using the `gemnasium-maven-dependency_scanning` CI/CD job to extract the project dependencies by building the application from the `pom.xml` file. The combinations of supported versions for Java, Kotlin, and Maven are complex, as detailed in the [dependency scanning (Gemnasium-based) documentation](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file).

**New behavior**: The new dependency scanning analyzer does not build the project to extract the dependencies. Instead, it uses a multi-tiered detection model:

- If a `maven.graph.json` graph export file generated with the [Maven dependency plugin](https://maven.apache.org/plugins/maven-dependency-plugin/index.html)
  exists in the repository or a job artifact, the analyzer uses it directly.
- If no graph export is detected but a supported `pom.xml` file exists, a [dependency resolution](dependency_scanning_sbom/_index.md#dependency-resolution)
  job runs in the `.pre` stage. It automatically executes  `mvn dependency:tree` to generate a
  dependency graph export for the `dependency-scanning` job.
- If dependency resolution is not available or fails, [manifest fallback](dependency_scanning_sbom/_index.md#manifest-fallback)
  parses the `pom.xml` directly to extract direct dependencies only.

#### Migrate a Maven project

Migrate a Maven project to use the new dependency scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.
- The Developer, Maintainer, or Owner role for the project.

To migrate a Maven project, choose one of the following options:

- For the most accurate results, ensure that your project provides a `maven.graph.json` file.
  Configure the [Maven dependency plugin](https://maven.apache.org/plugins/maven-dependency-plugin/index.html) in a preceding CI/CD job (for example: `build`)
  to dynamically generate the `maven.graph.json` file and export it as an [artifact](../../../ci/jobs/job_artifacts.md) prior to running the dependency scanning job.
  When you generate a graph export dynamically, disable automatic dependency resolution by adding `maven` to
  the `DS_DISABLED_RESOLUTION_JOBS` CI/CD variable value.
- Rely on [dependency resolution](dependency_scanning_sbom/_index.md#dependency-resolution) to automatically generate the `maven.graph.json` file.
  Verify that the resolution image can successfully generate the graph export.
- Defer to [manifest fallback](dependency_scanning_sbom/_index.md#manifest-fallback) for baseline coverage of direct dependencies declared in `pom.xml`.

See the [enablement instructions for Maven](dependency_scanning_sbom/_index.md#maven) for more details and examples.

### npm

**Previous behavior**: Dependency scanning based on the Gemnasium analyzer supports npm projects using the `gemnasium-dependency_scanning` CI/CD job and its ability to extract the project dependencies by parsing the `package-lock.json` or `npm-shrinkwrap.json.lock` files. The combination of supported versions of npm and the `package-lock.json` or `npm-shrinkwrap.json.lock` files are detailed in the [dependency scanning (Gemnasium-based) documentation](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles).
This analyzer may scan JavaScript files vendored in a npm project using the `Retire.JS` scanner.

**New behavior**: The new dependency scanning analyzer also extracts the project dependencies by parsing the `package-lock.json` or `npm-shrinkwrap.json.lock` files and generates a CycloneDX SBOM report artifact with the `dependency-scanning` CI/CD job.
This analyzer does not scan vendored JavaScript files. Support for a replacement feature is proposed in [epic 7186](https://gitlab.com/groups/gitlab-org/-/epics/7186).

#### Migrate an npm project

Migrate an npm project to use the new dependency scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.
- The Developer, Maintainer, or Owner role for the project.

There are no additional steps to migrate an npm project to use the dependency scanning analyzer.

### NuGet

**Previous behavior**: Dependency scanning based on the Gemnasium analyzer supports NuGet projects using the `gemnasium-dependency_scanning` CI/CD job and its ability to extract the project dependencies by parsing the `packages.lock.json` file. The combination of supported versions of NuGet and the `packages.lock.json` file are detailed in the [dependency scanning (Gemnasium-based) documentation](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles).

**New behavior**: The new dependency scanning analyzer also extracts the project dependencies by parsing the `packages.lock.json` file and generates a CycloneDX SBOM report artifact with the `dependency-scanning` CI/CD job.

#### Migrate a NuGet project

Migrate a NuGet project to use the new dependency scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.
- The Developer, Maintainer, or Owner role for the project.

There are no additional steps to migrate a NuGet project to use the dependency scanning analyzer.

### pip

**Previous behavior**: Dependency scanning based on the Gemnasium analyzer supports pip projects using the `gemnasium-python-dependency_scanning` CI/CD job to extract the project dependencies by building the application from the `requirements.txt` file (`requirements.pip` and `requires.txt` alternate filenames are also supported). The `PIP_REQUIREMENTS_FILE` environment variable can also be used to specify a custom filename. The combinations of supported versions for Python and pip are detailed in the [dependency scanning (Gemnasium-based) documentation](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file).

**New behavior**: The new dependency scanning analyzer does not build the project to extract the dependencies. Instead, it uses a multi-tiered detection model:

- If a [supported lockfile or graph export](dependency_scanning_sbom/_index.md#supported-languages-and-files)
  exists in the repository or a job artifact (for example, `requirements.txt` generated with pip-compile), the analyzer uses it directly.
- If no supported lockfile or graph export is detected but a supported build file exists
  (for example, `requirements.in`), a [dependency resolution](dependency_scanning_sbom/_index.md#dependency-resolution)
  job runs in the `.pre` stage. It automatically executes `pip-compile` to generate a
  lockfile for the `dependency-scanning` job.
- If dependency resolution is not available or fails, [manifest fallback](dependency_scanning_sbom/_index.md#manifest-fallback)
  parses the `requirements.txt` file directly to extract direct dependencies only.

#### Migrate a pip project

Migrate a pip project to use the new dependency scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.
- The Developer, Maintainer, or Owner role for the project.

To migrate a pip project, choose one of the following options:

- For the most accurate results, ensure that your project provides a lockfile.
  Configure the [pip-compile command line tool](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/) in your project and either
  commit the `requirements.txt` lockfile into your repository or use it in a preceding CI/CD job (for example: `build`) to dynamically
  generate the `requirements.txt` file and export it as an [artifact](../../../ci/jobs/job_artifacts.md) prior to running the dependency scanning job.
  Alternatively, you can select another [supported lockfile or graph export](dependency_scanning_sbom/_index.md#supported-languages-and-files).
  When you generate a lockfile or graph export dynamically, disable automatic dependency resolution by adding `python` to
  the `DS_DISABLED_RESOLUTION_JOBS` CI/CD variable value.
- Rely on [dependency resolution](dependency_scanning_sbom/_index.md#dependency-resolution) to automatically generate the `pipcompile.lock.txt` file.
  Verify that the resolution image can successfully generate the lockfile.
- Defer to [manifest fallback](dependency_scanning_sbom/_index.md#manifest-fallback) for baseline coverage of direct dependencies declared in `requirements.txt`.

See the [enablement instructions for pip](dependency_scanning_sbom/_index.md#pip) for more details and examples.

### Pipenv

**Previous behavior**: Dependency scanning based on the Gemnasium analyzer supports Pipenv projects using the `gemnasium-python-dependency_scanning` CI/CD job to extract the project dependencies by building the application from the `Pipfile` file or from a `Pipfile.lock` file if present. The combinations of supported versions for Python and Pipenv are detailed in the [dependency scanning (Gemnasium-based) documentation](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file).

**New behavior**: The new dependency scanning analyzer does not build the Pipenv project to extract the dependencies. Instead, the project must provide at least a `Pipfile.lock` file and ideally a `pipenv.graph.json` file generated by the [`pipenv graph` command](https://pipenv.pypa.io/en/latest/cli.html#graph). The `pipenv.graph.json` file is required to generate the dependency graph and enable features like the [dependency path](../dependency_list/_index.md#dependency-paths). These files are processed by the `dependency-scanning` CI/CD job to generate a CycloneDX SBOM report artifact. This approach does not require GitLab to support specific versions of Python and Pipenv.
[Dependency resolution](dependency_scanning_sbom/_index.md#dependency-resolution) is not supported for projects using a `Pipfile` without a `Pipfile.lock` file.

#### Migrate a Pipenv project

Migrate a Pipenv project to use the new dependency scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.
- The Developer, Maintainer, or Owner role for the project.

To migrate a Pipenv project:

- Ensure that your project provides a `Pipfile.lock` file.
  Configure the [`pipenv lock` command](https://pipenv.pypa.io/en/latest/cli.html#graph) in your project and either
  commit the `Pipfile.lock` file into your repository or use it in a preceding CI/CD job (for example: `build`) to dynamically
  generate the `Pipfile.lock` file and export it as an [artifact](../../../ci/jobs/job_artifacts.md) prior to running the dependency scanning job.
  Alternatively, you can select another [supported lockfile or graph export](dependency_scanning_sbom/_index.md#supported-languages-and-files).

### Poetry

**Previous behavior**: Dependency scanning based on the Gemnasium analyzer supports Poetry projects using the `gemnasium-python-dependency_scanning` CI/CD job and its ability to extract the project dependencies by parsing the `poetry.lock` file. The combination of supported versions of Poetry and the `poetry.lock` file are detailed in the [dependency scanning (Gemnasium-based) documentation](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles).

**New behavior**: The new dependency scanning analyzer also extracts the project dependencies by parsing the `poetry.lock` file and generates a CycloneDX SBOM report artifact with the `dependency-scanning` CI/CD job.

#### Migrate a Poetry project

Migrate a Poetry project to use the new dependency scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.
- The Developer, Maintainer, or Owner role for the project.

There are no additional steps to migrate a Poetry project to use the dependency scanning analyzer.

### pnpm

**Previous behavior**: Dependency scanning based on the Gemnasium analyzer supports pnpm projects using the `gemnasium-dependency_scanning` CI/CD job and its ability to extract the project dependencies by parsing the `pnpm-lock.yaml` file. The combination of supported versions of pnpm and the `pnpm-lock.yaml` file are detailed in the [dependency scanning (Gemnasium-based) documentation](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles).
This analyzer may scan JavaScript files vendored in a npm project using the `Retire.JS` scanner.

**New behavior**: The new dependency scanning analyzer also extracts the project dependencies by parsing the `pnpm-lock.yaml` file and generates a CycloneDX SBOM report artifact with the `dependency-scanning` CI/CD job.
This analyzer does not scan vendored JavaScript files. Support for a replacement feature is proposed in [epic 7186](https://gitlab.com/groups/gitlab-org/-/epics/7186).

#### Migrate a pnpm project

Migrate a pnpm project to use the new dependency scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.
- The Developer, Maintainer, or Owner role for the project.

There are no additional steps to migrate a `pnpm` project to use the dependency scanning analyzer.

### sbt

**Previous behavior**: Dependency scanning based on the Gemnasium analyzer supports sbt projects using the `gemnasium-maven-dependency_scanning` CI/CD job to extract the project dependencies by building the application from the `build.sbt` file. The combinations of supported versions for Java, Scala, and sbt are complex, as detailed in the [dependency scanning (Gemnasium-based) documentation](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file).

**New behavior**: The new dependency scanning analyzer does not build the project to extract the dependencies. Instead, the project must provide a `dependencies-compile.dot` file generated with the [sbt-dependency-graph plugin](https://github.com/sbt/sbt-dependency-graph) ([included in sbt >= 1.4.0](https://www.scala-sbt.org/1.x/docs/sbt-1.4-Release-Notes.html#sbt-dependency-graph+is+in-sourced)). This file is processed by the `dependency-scanning` CI/CD job to generate a CycloneDX SBOM report artifact. This approach does not require GitLab to support specific versions of Java, Scala, and sbt.
[Dependency resolution](dependency_scanning_sbom/_index.md#dependency-resolution) is not supported for sbt projects.

#### Migrate an sbt project

Migrate an sbt project to use the new dependency scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.
- The Developer, Maintainer, or Owner role for the project.

To migrate an sbt project:

- Ensure that your project provides a `dependencies-compile.dot` file. Configure the [sbt-dependency-graph plugin](https://github.com/sbt/sbt-dependency-graph) in a preceding CI/CD job (for example: `build`) to dynamically generate the `dependencies-compile.dot` file and export it as an [artifact](../../../ci/jobs/job_artifacts.md) prior to running the dependency scanning job.

See the [enablement instructions for sbt](dependency_scanning_sbom/_index.md#sbt) for more details and examples.

### setuptools

**Previous behavior**: Dependency scanning based on the Gemnasium analyzer supports setuptools projects using the `gemnasium-python-dependency_scanning` CI/CD job to extract the project dependencies by building the application from the `setup.py` file. The combinations of supported versions for Python and setuptools are detailed in the [dependency scanning (Gemnasium-based) documentation](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file).

**New behavior**: The new dependency scanning analyzer does not build a setuptools project to extract the dependencies. Instead, it uses a multi-tiered detection model:

- If a [supported lockfile or graph export](dependency_scanning_sbom/_index.md#supported-languages-and-files)
  exists in the repository or a job artifact (for example, `requirements.txt` generated with pip-compile), the analyzer uses it directly.
- If no supported lockfile or graph export is detected but a supported build file exists
  (for example, `setup.py`), a [dependency resolution](dependency_scanning_sbom/_index.md#dependency-resolution)
  job runs in the `.pre` stage. It automatically executes `pip-compile` to generate a
  lockfile for the `dependency-scanning` job.

#### Migrate a setuptools project

Migrate a setuptools project to use the new dependency scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.
- The Developer, Maintainer, or Owner role for the project.

To migrate a setuptools project, choose one of the following options:

- For the most accurate results, ensure that your project provides a `requirements.txt` lockfile. Configure the [pip-compile command line tool](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/) in your project and either:
  - Permanently integrate the command line tool into your development workflow. This means committing the `requirements.txt` file into your repository and updating it as you're making changes to your project dependencies.
  - Use the command line tool in a `build` CI/CD job to dynamically generate the `requirements.txt` file and export it as an [artifact](../../../ci/jobs/job_artifacts.md) prior to running the dependency scanning job.
- Enable [dependency resolution](dependency_scanning_sbom/_index.md#dependency-resolution) to automatically generate a `requirements.txt` lockfile from your manifest files.

See the [enablement instructions for pip](dependency_scanning_sbom/_index.md#pip) for more details and examples.

### Swift

**Previous behavior**: Dependency scanning based on the Gemnasium analyzer does not support Swift projects when using the CI/CD templates or the Scan Execution Policies. Support for Swift is only available on the experimental Swift CI/CD component.

**New behavior**: The new dependency scanning analyzer also extracts the project dependencies by parsing the `Package.resolved` file and generates a CycloneDX SBOM report artifact with the `dependency-scanning` CI/CD job.

#### Migrate a Swift project

Migrate a Swift project to use the new dependency scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.
- The Developer, Maintainer, or Owner role for the project.

There are no additional steps to migrate a Swift project to use the dependency scanning analyzer.

### uv

**Previous behavior**: Dependency scanning based on the Gemnasium analyzer supports uv projects using the `gemnasium-dependency_scanning` CI/CD job and its ability to extract the project dependencies by parsing the `uv.lock` file. The combination of supported versions of uv and the `uv.lock` file are detailed in the [dependency scanning (Gemnasium-based) documentation](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles).

**New behavior**: The new dependency scanning analyzer also extracts the project dependencies by parsing the `uv.lock` file and generates a CycloneDX SBOM report artifact with the `dependency-scanning` CI/CD job.

#### Migrate a uv project

Migrate a uv project to use the new dependency scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.
- The Developer, Maintainer, or Owner role for the project.

There are no additional steps to migrate a uv project to use the dependency scanning analyzer.

### Yarn

**Previous behavior**: Dependency scanning based on the Gemnasium analyzer supports Yarn projects using the `gemnasium-dependency_scanning` CI/CD job and its ability to extract the project dependencies by parsing the `yarn.lock` file. The combination of supported versions of Yarn and the `yarn.lock` files are detailed in the [dependency scanning (Gemnasium-based) documentation](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles).
This analyzer may provide remediation data to [resolve a vulnerability via merge request](../vulnerabilities/_index.md#resolve-a-vulnerability) for Yarn dependencies.
This analyzer may scan JavaScript files vendored in a Yarn project using the `Retire.JS` scanner.

**New behavior**: The new dependency scanning analyzer also extracts the project dependencies by parsing the `yarn.lock` file and generates a CycloneDX SBOM report artifact with the `dependency-scanning` CI/CD job.
This analyzer does not provide remediations data for Yarn dependencies. Support for a replacement feature is proposed in [epic 759](https://gitlab.com/groups/gitlab-org/-/epics/759).
This analyzer does not scan vendored JavaScript files. Support for a replacement feature is proposed in [epic 7186](https://gitlab.com/groups/gitlab-org/-/epics/7186).

#### Migrate a Yarn project

Migrate a Yarn project to use the new dependency scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.
- The Developer, Maintainer, or Owner role for the project.

There are no additional steps to migrate a Yarn project to use the dependency scanning analyzer. If you use the Resolve a vulnerability via merge request feature check [the deprecation announcement](../../../update/deprecations.md#resolve-a-vulnerability-for-dependency-scanning-on-yarn-projects) for available actions. If you use the JavaScript vendored files scan feature, check the [deprecation announcement](../../../update/deprecations.md#dependency-scanning-for-javascript-vendored-libraries) for available actions.

## Changes to CI/CD variables

The following table lists the CI/CD variables previously used with the legacy dependency scanning feature
based on the Gemnasium analyzer and their status with the new dependency scanning analyzer:

| Legacy variable                  | Status with the new analyzer                                                                                    |
| -------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `ADDITIONAL_CA_CERT_BUNDLE`      | Kept. Prefer `additional_ca_cert_bundle` spec input.                                                            |
| `AST_ENABLE_MR_PIPELINES`        | Kept.                                                                                                           |
| `DS_ANALYZER_IMAGE`              | Kept.                                                                                                           |
| `DS_EXCLUDED_ANALYZERS`          | Removed.                                                                                                        |
| `DS_EXCLUDED_PATHS`              | Kept. Prefer `excluded_paths` spec input.                                                                       |
| `DS_GRADLE_RESOLUTION_POLICY`    | Removed.                                                                                                        |
| `DS_IMAGE_SUFFIX`                | Removed.                                                                                                        |
| `DS_INCLUDE_DEV_DEPENDENCIES`    | Kept. Prefer `include_dev_dependencies` spec input.                                                             |
| `DS_JAVA_VERSION`                | Removed.                                                                                                        |
| `DS_MAX_DEPTH`                   | Kept. Prefer `max_scan_depth` spec input.                                                                       |
| `DS_PIP_DEPENDENCY_PATH`         | Kept. Applies only to [Python dependency resolution](dependency_scanning_sbom/_index.md#dependency-resolution). |
| `DS_PIP_VERSION`                 | Removed.                                                                                                        |
| `DS_REMEDIATE`                   | Removed.                                                                                                        |
| `DS_REMEDIATE_TIMEOUT`           | Removed.                                                                                                        |
| `GEMNASIUM_DB_LOCAL_PATH`        | Removed.                                                                                                        |
| `GEMNASIUM_DB_REF_NAME`          | Removed.                                                                                                        |
| `GEMNASIUM_DB_REMOTE_URL`        | Removed.                                                                                                        |
| `GEMNASIUM_DB_UPDATE_DISABLED`   | Removed.                                                                                                        |
| `GEMNASIUM_IGNORED_SCOPES`       | Removed.                                                                                                        |
| `GEMNASIUM_LIBRARY_SCAN_ENABLED` | Removed.                                                                                                        |
| `GOARCH`                         | Removed.                                                                                                        |
| `GOFLAGS`                        | Removed.                                                                                                        |
| `GOOS`                           | Removed.                                                                                                        |
| `GOPRIVATE`                      | Removed.                                                                                                        |
| `GRADLE_CLI_OPTS`                | Kept. Applies only to [Gradle dependency resolution](dependency_scanning_sbom/_index.md#dependency-resolution). |
| `GRADLE_PLUGIN_INIT_PATH`        | Removed.                                                                                                        |
| `MAVEN_CLI_OPTS`                 | Replaced by `MAVEN_ARGS`.                                                                                       |
| `PIP_EXTRA_INDEX_URL`            | Kept. Applies only to [Python dependency resolution](dependency_scanning_sbom/_index.md#dependency-resolution). |
| `PIP_INDEX_URL`                  | Kept. Applies only to [Python dependency resolution](dependency_scanning_sbom/_index.md#dependency-resolution). |
| `PIP_REQUIREMENTS_FILE`          | Replaced by `DS_PIP_MANIFEST_FILE_NAME_PATTERN`.                                                                |
| `PIPENV_PYPI_MIRROR`             | Removed.                                                                                                        |
| `SBT_CLI_OPTS`                   | Removed.                                                                                                        |
| `SEARCH_IGNORE_HIDDEN_DIRS`      | Kept.                                                                                                           |
| `SECURE_ANALYZERS_PREFIX`        | Kept. Prefer `analyzer_image_prefix` spec input.                                                                |
| `SECURE_LOG_LEVEL`               | Kept. Prefer `analyzer_log_level` spec input.                                                                   |

Variables marked **Removed** are ignored by the new analyzer. Remove them from your CI/CD configuration unless they
are also used by other jobs.

Variables marked **Replaced by `<new-name>`** still work but are deprecated. They are planned for removal in the next
major version of GitLab. Update your CI/CD configuration to use the new variable name.

Variables marked **Kept** are accepted by the new analyzer and behave as documented in the
[available CI/CD variables reference](dependency_scanning_sbom/_index.md#available-cicd-variables).
Some kept variables now apply only to dependency resolution jobs and are noted as such in the table.

To smooth the transition for existing user configurations (like scan execution policies),
the `v2` template is backwards compatible with these CI/CD variables. When set, they take precedence over their
corresponding `spec:inputs` introduced in this new template.

When you use the `v2` CI/CD template directly in `.gitlab-ci.yml`, prefer
[spec inputs](dependency_scanning_sbom/_index.md#available-spec-inputs) over CI/CD variables
to configure the analyzer. Spec inputs are validated at pipeline creation time, provide
clearer error messages, and are scoped to the template include. Use CI/CD variables when
you configure dependency scanning through scan execution policies or security configuration profiles,
where spec inputs are not available yet.

### New CI/CD variables introduced with the v2 template

The `v2` template adds the following variables. For details, see the
[available spec inputs](dependency_scanning_sbom/_index.md#available-spec-inputs) and
[available CI/CD variables](dependency_scanning_sbom/_index.md#available-cicd-variables) references.

| Variable                                   | Spec input equivalent                   | Purpose                                                                                                                                                  |
| ------------------------------------------ | --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ANALYZER_ARTIFACT_DIR`                    | _(none)_                                | Directory where CycloneDX SBOM reports are saved.                                                                                                        |
| `DS_API_SCAN_DOWNLOAD_DELAY`               | `api_scan_download_delay`               | Initial delay before downloading vulnerability scan results.                                                                                             |
| `DS_API_TIMEOUT`                           | `api_timeout`                           | Timeout for the dependency scanning SBOM scan API.                                                                                                       |
| `DS_DISABLED_RESOLUTION_JOBS`              | `disabled_resolution_jobs`              | Comma-separated list of [dependency resolution](dependency_scanning_sbom/_index.md#dependency-resolution) jobs to disable (`maven`, `gradle`, `python`). |
| `DS_ENABLE_MANIFEST_FALLBACK`              | `enable_manifest_fallback`              | Enable [manifest fallback](dependency_scanning_sbom/_index.md#manifest-fallback) when no lockfile or dependency graph export is available.               |
| `DS_ENABLE_VULNERABILITY_SCAN`             | `enable_vulnerability_scan`             | Toggle vulnerability scanning of generated SBOMs.                                                                                                        |
| `DS_FF_LINK_COMPONENTS_TO_GIT_FILES`       | _(none)_                                | (Beta) Link components in the dependency list to files committed to the repository instead of dynamically generated files.                               |
| `DS_GRADLE_RESOLUTION_IMAGE`               | `gradle_resolution_image`               | Image used by the Gradle dependency resolution job.                                                                                                      |
| `DS_MAVEN_RESOLUTION_IMAGE`                | `maven_resolution_image`                | Image used by the Maven dependency resolution job.                                                                                                       |
| `DS_MAVEN_DEPENDENCY_PLUGIN_VERSION`       | `maven_dependency_plugin_version`       | The version of `maven-dependency-plugin` used during Maven dependency resolution.                                                                        |
| `DS_PIP_MANIFEST_FILE_NAME_PATTERN`        | `pip_manifest_file_name_pattern`        | Glob pattern for pip manifest files.                                                                                                                     |
| `DS_PIPCOMPILE_LOCKFILE_FILE_NAME_PATTERN` | `pipcompile_lockfile_file_name_pattern` | Glob pattern for `pip-compile` lockfiles.                                                                                                                |
| `DS_PYTHON_RESOLUTION_IMAGE`               | `python_resolution_image`               | Image used by the Python dependency resolution job.                                                                                                      |
| `DS_STATIC_REACHABILITY_ENABLED`           | `enable_static_reachability`            | Enable [static reachability](static_reachability.md).                                                                                                    |
