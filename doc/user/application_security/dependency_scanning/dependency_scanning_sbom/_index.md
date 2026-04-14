---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dependency scanning by using SBOM
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Limited Availability (GitLab.com and GitLab Self-Managed)

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/8026) in GitLab 17.4 as an [experiment](../../../../policy/development_stages_support.md#experiment) for default branch only [with a feature flag](../../../../administration/feature_flags/_index.md) named `dependency_scanning_using_sbom_reports`. Disabled by default.
- [Enabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/395692) in GitLab 17.5.
- [Changed](https://gitlab.com/groups/gitlab-org/-/work_items/15960) from experiment to beta with support for all branches and [Enabled by default with the latest dependency scanning CI/CD templates](https://gitlab.com/gitlab-org/gitlab/-/issues/519597) for Cargo, Conda, Cocoapods, and Swift in GitLab 17.9.
- Feature flag `dependency_scanning_using_sbom_reports` removed in GitLab 17.10.
- [Changed](https://gitlab.com/groups/gitlab-org/-/work_items/15960) from beta to limited availability for GitLab.com only with a new [V2 CI/CD dependency scanning template](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201175/) in GitLab 18.5 [with a feature flag](../../../../administration/feature_flags/_index.md) named `dependency_scanning_sbom_scan_api`. Disabled by default.
- Feature flag `dependency_scanning_using_sbom_reports` [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/work_items/551861) in GitLab 18.10.

{{< /history >}}

Dependency scanning using CycloneDX Software Bill of Materials (SBOM) analyzes your application's
dependencies for known vulnerabilities. All dependencies are scanned,
[including transitive dependencies](../_index.md).

Dependency scanning is often considered part of Software Composition Analysis (SCA). SCA can contain
aspects of inspecting the items your code uses. These items typically include application and system
dependencies that are almost always imported from external sources, rather than sourced from items
you wrote yourself.

Dependency scanning can run in the development phase of your application's lifecycle. Using the new
dependency scanning analyzer in CI/CD pipelines, project dependencies are detected and reported in CycloneDX
SBOM reports. Security findings are identified and compared between the source
and target branches. Findings and their severity are listed in the merge request, enabling you to
proactively address the risk to your application, before the code change is committed. Security
findings for reported SBOM components are also identified by
[continuous vulnerability scanning](../../continuous_vulnerability_scanning/_index.md)
when new security advisories are published, independently from CI/CD pipelines.

GitLab offers both dependency scanning and [container scanning](../../container_scanning/_index.md) to
ensure coverage for all of these dependency types. To cover as much of your risk area as possible,
we encourage you to use all of our security scanners. For a comparison of these features, see
[Dependency scanning compared to container scanning](../../comparison_dependency_and_container_scanning.md).

Share any feedback on the new dependency scanning analyzer in this [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/523458).

## Turn on dependency scanning

If you are new to dependency scanning, follow these steps to turn it on for your project.

- Prerequisites for all GitLab instances:
  - The Developer, Maintainer, or Owner role for the project.
  - A [supported lockfile or dependency graph export](#supported-languages-and-files),
    either committed to the repository or created in the CI/CD pipeline and passed as an artifact
    to the `dependency-scanning` job. Alternatively, [dependency resolution](#dependency-resolution)
    can generate the required files for supported ecosystems, or a
    [manifest file](#manifest-fallback) can be used as a fallback option.
  - For self-managed runners, GitLab Runner with the
    [`docker`](https://docs.gitlab.com/runner/executors/docker/) or
    [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes/) executor.
  - For hosted runners on GitLab.com, this configuration is enabled by default.
- Additional prerequisites for GitLab Self-Managed only:
  - [Package metadata](../../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync)
    for all PURL types to be scanned must be synchronized in the GitLab instance.

    > [!note]
    > If this data is not available in the GitLab instance, dependency scanning cannot identify
    > vulnerabilities.

To turn on dependency scanning:

1. In the top bar, select **Search or go to** and find your project.
1. Select **Code** > **Repository**.
1. Select the `.gitlab-ci.yml` file.
1. Select **Edit** > **Edit single file**.
1. Add the `v2` dependency scanning CI/CD template:

   ```yaml
   include:
     - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
   ```

1. Select **Commit changes**.

## Understanding the results

Dependency scanning analyzer outputs:

- A CycloneDX SBOM for each supported lockfile or dependency graph export detected.
- A single dependency scanning report for all scanned SBOM documents (GitLab.com and GitLab Self-Managed only).

### CycloneDX Software Bill of Materials

The dependency scanning analyzer outputs a [CycloneDX](https://cyclonedx.org/) Software Bill of Materials (SBOM)
for each directory where a supported lockfile, dependency graph, or manifest file is detected. The CycloneDX SBOMs are created as job artifacts.

The CycloneDX SBOMs are:

- Named `gl-sbom-<package-type>-<package-manager>.cdx.json`.
- Available as job artifacts of the dependency scanning job.
- Uploaded as `cyclonedx` reports.
- Saved in the same directory as the detected lockfile or dependency graph files.

For example, if your project has the following structure:

```plaintext
.
├── ruby-project/
│   └── Gemfile.lock
├── ruby-project-2/
│   └── Gemfile.lock
└── php-project/
    └── composer.lock
```

The following CycloneDX SBOMs are created as job artifacts:

```plaintext
.
├── ruby-project/
│   ├── Gemfile.lock
│   └── gl-sbom-gem-bundler.cdx.json
├── ruby-project-2/
│   ├── Gemfile.lock
│   └── gl-sbom-gem-bundler.cdx.json
└── php-project/
    ├── composer.lock
    └── gl-sbom-packagist-composer.cdx.json
```

### Dependency scanning report

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

The dependency scanning analyzer generates a dependency scanning report that documents all
vulnerabilities identified in dependencies identified in the CycloneDX SBOM files.

The dependency scanning report is:

- Named `gl-dependency-scanning-report.json`.
- Available as a job artifact of the dependency scanning job.
- Uploaded as a `dependency_scanning` report.
- Saved in the root directory of the project.

## Optimization

To optimize dependency scanning with SBOM, use any of the following methods:

- Exclude paths
- Limit scanning to a maximum directory depth

### Exclude paths

Exclude paths to optimize scanning performance and focus on relevant repository content.

List excluded paths in the `.gitlab-ci.yml` file:

- If using the dependency scanning template, use the `DS_EXCLUDED_PATHS` CI/CD variable.
- If using the dependency scanning CI/CD component, use the `excluded_paths` spec input.

#### Exclusion patterns

Exclusion patterns follow these rules:

- Patterns without slashes match file or directory names at any depth in the project (example: `test` matches `./test`, `src/test`).
- Patterns with slashes use parent directory matching - they match paths that start with the pattern (example: `a/b` matches `a/b` and `a/b/c`, but not `c/a/b`).
- Standard glob wildcards are supported (example: `a/**/b` matches `a/b`, `a/x/b`, `a/x/y/b`).
- Leading and trailing slashes are ignored (example: `/build` and `build/` work the same as `build`).

### Limit scanning to a maximum directory depth

Limit scanning to a maximum directory depth to optimize scanning performance and reduce the number
of files analyzed.

The root directory is counted as depth `1`, and each subdirectory increments the depth by 1. The
default depth is `2`. A value of `-1` scans all directories regardless of depth.

To specify the maximum depth in the `.gitlab-ci.yml` file:

- If using the dependency scanning template, use the `DS_MAX_DEPTH` CI/CD variable.
- If using the dependency scanning CI/CD component, use the `max_scan_depth` spec input.

In the following example, with `DS_MAX_DEPTH` set to `3`, subdirectories of the `common` directory
are not scanned.

```plaintext
timer
├── integration
│   ├── doc
│   └── modules
└── source
    ├── common
    │   ├── cplusplus
    │   └── go
    ├── linux
    ├── macos
    └── windows
```

## Roll out

After you are confident in the dependency scanning with SBOM results for a single project, you can
extend its implementation to multiple projects and groups. For details, see
[Enforce scanning on multiple projects](#enforce-scanning-on-multiple-projects).

If you have unique requirements, dependency scanning with SBOM can be run in
[offline environments](#offline-support).

## Supported package types

For the security analysis to be effective, the components listed in your SBOM report must have corresponding
entries in the [GitLab advisory database](../../gitlab_advisory_database/_index.md).

The GitLab SBOM Vulnerability Scanner can report dependency scanning vulnerabilities for components with the
following [PURL types](https://github.com/package-url/purl-spec/blob/346589846130317464b677bc4eab30bf5040183a/PURL-TYPES.rst):

- `cargo`
- `composer`
- `conan`
- `gem`
- `golang`
- `maven`
- `npm`
- `nuget`
- `pypi`
- `swift`

## Supported languages and files

| Language                  | Package manager | File(s)                                         | Description                                                                                                                                                            | Dependency graph export support | Static reachability support |
| ------------------------- | --------------- | ----------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- | --------------------------- |
| C#                        | NuGet           | `packages.lock.json`                            | Lockfiles generated by `nuget`.                                                                                                                                        | {{< yes >}}                     | {{< no >}}                  |
| C/C++                     | Conan           | `conan.lock`                                    | Lockfiles generated by `conan`.                                                                                                                                        | {{< yes >}}                     | {{< no >}}                  |
| C/C++/Fortran/Go/Python/R | Conda           | `conda-lock.yml`                                | Environment files generated by `conda-lock`.                                                                                                                           | {{< no >}}                      | {{< no >}}                  |
| Dart                      | pub             | `pubspec.lock`, `pub.graph.json`                | Lockfiles generated by `pub`. Dependency graph export derived from `dart pub deps --json > pub.graph.json`.                                                            | {{< yes >}}                     | {{< no >}}                  |
| Go                        | go              | `go.mod`, `go.graph`                            | Module files generated by the standard `go` toolchain. Dependency graph export derived from `go mod graph > go.graph`.                                                 | {{< yes >}}                     | {{< no >}}                  |
| Java                      | ivy             | `ivy-report.xml`                                | Dependency graph exports generated by the `report` Apache Ant task.                                                                                                    | {{< no >}}                      | {{< yes >}}                 |
| Java                      | Maven           | `maven.graph.json`                              | Dependency graph exports generated by `mvn dependency:tree -DoutputType=json`.                                                                                         | {{< yes >}}                     | {{< yes >}}                 |
| Java/Kotlin               | Gradle          | `dependencies.lock`, `dependencies.direct.lock` | Lockfiles generated by [gradle-dependency-lock-plugin](https://github.com/nebula-plugins/gradle-dependency-lock-plugin).                                               | {{< yes >}}                     | {{< yes >}}                 |
| Java/Kotlin               | Gradle          | `gradle.lockfile`                               | Lockfiles generated by `gradle dependencies --write-locks`.                                                                                                            | {{< no >}}                      | {{< yes >}}                 |
| Java/Kotlin               | Gradle          | `gradle-html-dependency-report.js`              | Dependency graph exports generated by the [htmlDependencyReport](https://docs.gradle.org/current/dsl/org.gradle.api.tasks.diagnostics.DependencyReportTask.html) task. | {{< yes >}}                     | {{< yes >}}                 |
| JavaScript/TypeScript     | npm             | `package-lock.json`, `npm-shrinkwrap.json`      | Lockfiles generated by `npm` v5 or later (earlier versions, which do not generate a `lockfileVersion` attribute, are not supported).                                   | {{< yes >}}                     | {{< yes >}}                 |
| JavaScript/TypeScript     | pnpm            | `pnpm-lock.yaml`                                | Lockfiles generated by `pnpm`.                                                                                                                                         | {{< yes >}}                     | {{< yes >}}                 |
| JavaScript/TypeScript     | yarn            | `yarn.lock`                                     | Lockfiles generated by `yarn`.                                                                                                                                         | {{< yes >}}                     | {{< yes >}}                 |
| PHP                       | composer        | `composer.lock`                                 | Lockfiles generated by `composer`.                                                                                                                                     | {{< yes >}}                     | {{< no >}}                  |
| Python                    | pip             | `pipdeptree.json`                               | Dependency graph exports generated by `pipdeptree --json`.                                                                                                             | {{< yes >}}                     | {{< yes >}}                 |
| Python                    | pip             | `requirements.txt`                              | Dependency lockfiles generated by `pip-compile`.                                                                                                                       | {{< yes >}}                     | {{< yes >}}                 |
| Python                    | pipenv          | `Pipfile.lock`                                  | Lockfiles generated by `pipenv`.                                                                                                                                       | {{< no >}}                      | {{< no >}}                  |
| Python                    | pipenv          | `pipenv.graph.json`                             | Dependency graph exports generated by `pipenv graph --json-tree >pipenv.graph.json`.                                                                                   | {{< yes >}}                     | {{< yes >}}                 |
| Python                    | poetry          | `poetry.lock`                                   | Lockfiles generated by `poetry`.                                                                                                                                       | {{< yes >}}                     | {{< yes >}}                 |
| Python                    | uv<sup>1</sup>  | `uv.lock`                                       | Lockfiles generated by `uv`.                                                                                                                                           | {{< yes >}}                     | {{< yes >}}                 |
| Ruby                      | bundler         | `Gemfile.lock`, `gems.locked`                   | Lockfiles generated by `bundler`.                                                                                                                                      | {{< yes >}}                     | {{< no >}}                  |
| Rust                      | cargo           | `Cargo.lock`                                    | Lockfiles generated by `cargo`.                                                                                                                                        | {{< yes >}}                     | {{< no >}}                  |
| Scala                     | sbt             | `dependencies-compile.dot`                      | Dependency graph exports generated by `sbt dependencyDot`.                                                                                                             | {{< yes >}}                     | {{< no >}}                  |
| Swift                     | swift           | `Package.resolved`                              | Lockfiles generated by `swift`.                                                                                                                                        | {{< no >}}                      | {{< no >}}                  |

**Footnotes**:

1. If a lockfile contains multiple entries for the same package with different environment markers (for example, numpy==2.2.6 for Python <3.11 and numpy==2.4.1 for Python ≥3.11), only the first entry is parsed and reported.

### Package hash information

Dependency scanning SBOMs include package hash information when available. This information is provided only for NuGet packages.
Package hashes appear in the following locations within the SBOM, allowing you to verify package integrity and authenticity:

- Dedicated hashes field
- PURL qualifiers

For example:

```json
{
  "name": "Iesi.Collections",
  "version": "4.0.4",
  "purl": "pkg:nuget/Iesi.Collections@4.0.4?sha512=8e579b4a3bf66bb6a661f297114b0f0d27f6622f6bd3f164bef4fa0f2ede865ef3f1dbbe7531aa283bbe7d86e713e5ae233fefde9ad89b58e90658ccad8d69f9",
  "hashes": [
    {
      "alg": "SHA-512",
      "content": "8e579b4a3bf66bb6a661f297114b0f0d27f6622f6bd3f164bef4fa0f2ede865ef3f1dbbe7531aa283bbe7d86e713e5ae233fefde9ad89b58e90658ccad8d69f9"
    }
  ],
  "type": "library",
  "bom-ref": "pkg:nuget/Iesi.Collections@4.0.4?sha512=8e579b4a3bf66bb6a661f297114b0f0d27f6622f6bd3f164bef4fa0f2ede865ef3f1dbbe7531aa283bbe7d86e713e5ae233fefde9ad89b58e90658ccad8d69f9"
}
```

## Customizing analyzer behavior

How to customize the analyzer varies depending on the enablement solution.

> [!warning]
> Test all customization of GitLab analyzers in a merge request before merging these changes to the
> default branch. Failure to do so can give unexpected results, including a large number of false
> positives.

### Customizing behavior with the CI/CD template

#### Available spec inputs

The following spec inputs can be used in combination with the `Dependency-Scanning.v2.gitlab-ci.yml` template.

| Spec Input                                  | Type    | Default                                                                                                   | Description                                                                                                                                                                                                                                              |
| ------------------------------------------- | ------- | --------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `job_name`                                  | string  | `"dependency-scanning"`                                                                                   | The name of the dependency scanning job.                                                                                                                                                                                                                 |
| `stage`                                     | string  | `test`                                                                                                    | The stage of the dependency scanning job.                                                                                                                                                                                                                |
| `allow_failure`                             | boolean | `true`                                                                                                    | Whether the dependency scanning job failure should fail the pipeline.                                                                                                                                                                                    |
| `analyzer_image_prefix`                     | string  | `"$CI_TEMPLATE_REGISTRY_HOST/security-products"`                                                          | The registry URL prefix pointing to the repository of the analyzer.                                                                                                                                                                                      |
| `analyzer_image_name`                       | string  | `"dependency-scanning"`                                                                                   | The repository of the analyzer image used by the dependency-scanning job.                                                                                                                                                                                |
| `analyzer_image_version`                    | string  | `"1"`                                                                                                     | The version of the analyzer image used by the dependency-scanning job.                                                                                                                                                                                   |
| `additional_ca_cert_bundle`                 | string  |                                                                                                           | CA certificate bundle to trust. The CA bundle provided here is added to the system's certificates and also used by other tools during the scanning process. For more details, see [Custom TLS certificate authority](#custom-tls-certificate-authority). |
| `pipcompile_requirements_file_name_pattern` | string  |                                                                                                           | Custom requirements file name pattern to use when analyzing. The pattern should match file names only, not directory paths. See [doublestar library](https://www.github.com/bmatcuk/doublestar/tree/v1#patterns) for syntax details.                     |
| `max_scan_depth`                            | number  | `2`                                                                                                       | Defines how many directory levels analyzer should search for supported files. A value of -1 means the analyzer will search all directories regardless of depth.                                                                                          |
| `excluded_paths`                            | string  | `"**/spec,**/test,**/tests,**/tmp"`                                                                       | A comma-separated list of paths (globs supported) to exclude from the scan.                                                                                                                                                                              |
| `include_dev_dependencies`                  | boolean | `true`                                                                                                    | Include development/test dependencies when scanning a supported file.                                                                                                                                                                                    |
| `enable_static_reachability`                | boolean | `false`                                                                                                   | Enable [static reachability](../static_reachability.md).                                                                                                                                                                                                 |
| `analyzer_log_level`                        | string  | `"info"`                                                                                                  | Logging level for dependency scanning. The options are fatal, error, warn, info, debug.                                                                                                                                                                  |
| `enable_vulnerability_scan`                 | boolean | `true`                                                                                                    | Enable the vulnerability analysis of generated SBOMs                                                                                                                                                                                                     |
| `api_timeout`                               | number  | `10`                                                                                                      | Dependency scanning SBOM API request timeout in seconds.                                                                                                                                                                                                 |
| `api_scan_download_delay`                   | number  | `3`                                                                                                       | Dependency scanning SBOM API initial delay in seconds before downloading scan results.                                                                                                                                                                   |
| `resolution_jobs_stage`                     | string  | `.pre`                                                                                                    | The stage for the dependency resolution jobs.                                                                                                                                                                                                            |
| `resolution_jobs_allow_failure`             | boolean | `true`                                                                                                    | When `true`, a failed resolution job does not fail the pipeline. When `false`, a resolution failure blocks the pipeline.                                                                                                                                     |
| `disabled_resolution_jobs`                  | string  | `""`                                                                                                      | Comma-separated list of resolution jobs to disable (for example, `"maven, python"`). By default, all available resolution jobs are enabled. Possible values are: `maven`,`gradle`,`python`.                                                                     |
| `maven_resolution_job_name`                 | string  | `"dependency-scanning:maven-resolution"`                                                                  | The name of the job for Maven dependency resolution.                                                                                                                                                                                                     |
| `maven_resolution_image`                    | string  | `"registry.gitlab.com/security-products/dependency-resolution/ubi9/openjdk-21:1"`                         | The image used by the Maven dependency resolution job.                                                                                                                                                                                                   |
| `python_resolution_job_name`                | string  | `"dependency-scanning:python-resolution"`                                                                 | The name of the job for Python dependency resolution.                                                                                                                                                                                                    |
| `python_resolution_image`                   | string  | `"registry.gitlab.com/security-products/dependency-resolution/ubi9/python-312-minimal-with-piptools-7:9"` | The image used by the Python dependency resolution job.                                                                                                                                                                                                  |
| `gradle_resolution_job_name`                | string  | `"dependency-scanning:gradle-resolution"`                                                                 | The name of the job for Gradle dependency resolution.                                                                                                                                                                                                    |
| `gradle_resolution_image`                   | string  | `"registry.gitlab.com/security-products/dependency-resolution/ubi9/openjdk-17-with-gradle-8:1"`           | The image used by the Gradle dependency resolution job.                                                                                                                                                                                                  |

#### Available CI/CD variables

These variables can replace spec inputs and are also compatible with the beta `latest` template.

| CI/CD variables                                | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `AST_ENABLE_MR_PIPELINES`                      | Control whether dependency scanning job runs in MR or branch pipeline. Default: `"true"`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| `ADDITIONAL_CA_CERT_BUNDLE`                    | CA certificate bundle to trust. The CA bundle provided here is added to the system's certificates and also used by other tools during the scanning process. For more details, see [Custom TLS certificate authority](#custom-tls-certificate-authority).                                                                                                                                                                                                                                                                                                                                         |
| `ANALYZER_ARTIFACT_DIR`                        | Directory where CycloneDX reports (SBOMs) are saved. Default `${CI_PROJECT_DIR}/sca-artifacts`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| `DS_EXCLUDED_ANALYZERS`                        | Specify the analyzers (by name) to exclude from dependency scanning.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| `DS_EXCLUDED_PATHS`                            | Exclude files and directories from the scan based on the paths. A comma-separated list of patterns. Patterns can be globs (see [`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match) for supported patterns), or file or folder paths (for example, `doc,spec`). See [Exclusion patterns](#exclusion-patterns) for matching rules. This is a pre-filter which is applied before the scan is executed. Applies both for dependency detection and static reachability. Default: `"**/spec,**/test,**/tests,**/tmp,**/node_modules,**/.bundle,**/vendor,**/.git"`. |
| `DS_MAX_DEPTH`                                 | Defines how many directory levels deep that the analyzer should search for supported files to scan. A value of `-1` scans all directories regardless of depth. Default: `2`.                                                                                                                                                                                                                                                                                                                                                                                                                     |
| `DS_INCLUDE_DEV_DEPENDENCIES`                  | When set to `"false"`, development dependencies are not reported. Only projects using Composer, Conda, Gradle, Maven, npm, pnpm, Pipenv, Poetry, or uv are supported. Default: `"true"`                                                                                                                                                                                                                                                                                                                                                                                                          |
| `DS_PIPCOMPILE_REQUIREMENTS_FILE_NAME_PATTERN` | Defines which requirement files to process using glob pattern matching (for example, `requirements*.txt` or `*-requirements.txt`). The pattern should match filenames only, not directory paths. See [glob pattern documentation](https://github.com/bmatcuk/doublestar/tree/v1?tab=readme-ov-file#patterns) for syntax details.                                                                                                                                                                                                                                                                 |
| `SECURE_ANALYZERS_PREFIX`                      | Override the name of the Docker registry providing the official default images (proxy).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `DS_FF_LINK_COMPONENTS_TO_GIT_FILES`           | Link components in the dependency list to files committed to the repository rather than lockfiles and graph files generated dynamically in a CI/CD pipeline. This ensures all components are linked to a source file in the repository. Default: `"false"`.                                                                                                                                                                                                                                                                                                                                      |
| `SEARCH_IGNORE_HIDDEN_DIRS`                    | Ignore hidden directories. Works both for dependency scanning and static reachability. Default: `"true"`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| `DS_STATIC_REACHABILITY_ENABLED`               | Enables [static reachability](../static_reachability.md). Default: `"false"`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| `DS_ENABLE_VULNERABILITY_SCAN`                 | Enable vulnerability scanning of generated SBOM files. Generates a [dependency scanning report](#dependency-scanning-report). Default: `"true"`.                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `DS_API_TIMEOUT`                               | Dependency scanning SBOM API request timeout in seconds (minimum: `5`, maximum: `300`) Default: `10`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| `DS_API_SCAN_DOWNLOAD_DELAY`                   | Initial delay in seconds before downloading scan results (minimum: 1, maximum: 120) Default: `3`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `DS_ENABLE_MANIFEST_FALLBACK`                  | Enable manifest fallback when no lockfile or dependency graph export is available. See [Manifest fallback](#manifest-fallback). Default: `"false"`.                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| `SECURE_LOG_LEVEL`                             | Log level. Default: `"info"`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| `DS_DISABLED_RESOLUTION_JOBS`                  | Comma-separated list of resolution jobs to disable (for example, `"maven, python"`). By default, all available resolution jobs are enabled. Possible values are: `maven`,`gradle`,`python`.                                                                                                                                                                                                                                                                                                                                                                                                             |
| `DS_MAVEN_RESOLUTION_IMAGE`                    | The image used by the Maven dependency resolution job.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| `DS_PYTHON_RESOLUTION_IMAGE`                   | The image used by the Python dependency resolution job.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `DS_GRADLE_RESOLUTION_IMAGE`                   | The image used by the Gradle dependency resolution job.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |

### Custom TLS certificate authority

Dependency scanning allows for use of custom TLS certificates for SSL/TLS connections instead of the
default shipped with the analyzer container image.

#### Using a custom TLS certificate authority

To use a custom TLS certificate authority, assign the
[text representation of the X.509 PEM public-key certificate](https://www.rfc-editor.org/rfc/rfc7468#section-5.1)
to the CI/CD variable `ADDITIONAL_CA_CERT_BUNDLE`.

For example, to configure the certificate in the `.gitlab-ci.yml` file:

```yaml
variables:
  ADDITIONAL_CA_CERT_BUNDLE: |
      -----BEGIN CERTIFICATE-----
      MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
      ...
      jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
      -----END CERTIFICATE-----
```

## Dependency resolution

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/20461) for Maven and Python in GitLab 18.11, disabled by default.

{{< /history >}}

When a project does not have a supported lockfile or dependency graph export committed to its
repository, the dependency resolution can automatically generate the required files before the scan runs.

Dependency resolution automatically triggers when supported manifest files are detected in your project.
Resolution jobs run in the `.pre` stage using minimal ecosystem images (for example, `ubi9/openjdk-21`)
to natively generate lockfiles or dependency graph exports. These jobs preserve any existing lockfiles
or graph exports, only creating them when absent. The generated artifacts are then consumed by the
`dependency-scanning` job in the `test` stage. You can substitute the default images with equivalent
alternatives (such as `eclipse-temurin:jdk-21`) or custom images containing the necessary build tools.

The following ecosystems support dependency resolution:

| Language | Package manager | Manifest files detected                                                                                                           | Resolution command    | Output artifact       |
| -------- | --------------- | --------------------------------------------------------------------------------------------------------------------------------- | --------------------- | --------------------- |
| Java     | Maven           | `pom.xml`                                                                                                                         | `mvn dependency:tree` | `maven.graph.json`    |
| Python   | pip, setuptools | `requirements.txt`, `requirements.in`, `requirements.pip`, `requires.txt`, `setup.py`, `setup.cfg`, `pyproject.toml` (non-Poetry) | `pip-compile`         | `pipcompile.lock.txt` |

> [!warning]
> Dependency resolution is disabled by default during the limited availability stage.

To enable dependency resolution, set the `DS_DISABLED_RESOLUTION_JOBS` CI/CD variable to `""`:

```yaml
variables:
  DS_DISABLED_RESOLUTION_JOBS: ""

include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
```

### Customizing dependency resolution

For all available options see [available spec inputs](#available-spec-inputs) and [available CI/CD variables](#available-cicd-variables).

#### Use a custom dependency resolution image

To use your own image, you can set the following inputs:

- `maven_resolution_image`
- `python_resolution_image`

For instance, to use a custom image for maven resolution:

```yaml
include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
    inputs:
      maven_resolution_image: "registry.gitlab.mycorp.com/eclipse-temurin:jdk-21"
```

Alternatively, you can set the following CI/CD variables:

- `DS_MAVEN_RESOLUTION_IMAGE`
- `DS_PYTHON_RESOLUTION_IMAGE`

#### Disable dependency resolution

To disable dependency resolution for a specific ecosystem, use the
`DS_DISABLED_RESOLUTION_JOBS` CI/CD variable or the `disabled_resolution_jobs` input.

For instance, to disable dependency resolution for maven:

```yaml
variables:
  DS_DISABLED_RESOLUTION_JOBS: "maven"

include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
```

### Dependency resolution limitations

Dependency resolution runs ecosystem-native build tools in vanilla or custom images with a single,
fixed runtime version and build tool per ecosystem.

Resolution success depends on the project's compatibility with this environment, its ability to reach
package registries, and the absence of build-time requirements that go beyond dependency collection.

Projects that fail with the default environment can override the relevant resolution job image to provide a compatible one
with all the required dependencies.

Even when compatible, the resolution environment may not match the exact runtime version or other requirements a project was built with.
Therefore, the generated dependency graph may not reflect the exact set of dependencies that would be resolved in the
project's actual build environment. Differences can arise from the fixed runtime version, unresolved environment markers,
platform-specific dependencies, or conditional dependency groups that depend on build-time context unavailable in the resolution job.

For the most accurate results, provide a lockfile or dependency graph export generated in your own build environment,
For projects with highly customized builds that are not adequately covered by dependency resolution workflows,
you should provide a lockfile or dependency graph export generated in your own build environment
as described in [Create lockfile or dependency graph export manually](#create-lockfile-or-dependency-graph-export-manually).

#### Maven

Default environment: Java 21, Maven 3.9

The following limitations apply for Maven projects:

- Maven enforcer plugin: Projects using strict Java version rules in the Maven Enforcer Plugin may fail. The resolution command passes `-Denforcer.skip=true` to mitigate this, but not all enforcer rules are skipped.
- Profile-based activation: Projects using conditional modules activated by JDK version (for example, ZXing, Dubbo) might produce a different dependency graph than when built with the originally targeted Java version.
- Plugins in early lifecycle phases: Plugins bound to the validate or initialize phases that are incompatible with the resolution image's Java version might cause failures.

#### Python

Default environment: Python 3.12, pip-tools 7

The following limitations apply for Python projects:

- Pipfile unsupported: Pipfile projects (without a `Pipfile.lock` file) are not supported. The Python resolution job won't be triggered on the presence of `Pipfile` file in the repository.
- Git/VCS dependencies: Dependencies specified as Git or VCS URLs (`git+https://...`) cannot be resolved. The resolution command will fail for this specific manifest file but continue to process the others, if any.
- Local/editable installs: Entries using `-e .`, `file:`, or local path references are stripped before resolution and a warning is emitted. Those packages do not appear in the output.
- `setup.py` with dynamic `install_requires`: when `install_requires` reads from a file at runtime, a warning is emitted and `pip-compile` will attempt resolution but might fail.
- `pyproject.toml` without a `[project]` table: A `pyproject.toml` that contains only build-system configuration is skipped and a warning is emitted.
- `DS_INCLUDE_DEV_DEPENDENCIES` scope: Development dependency inclusion is implemented only for `pyproject.toml` with `[dependency-groups]`.

### Create lockfile or dependency graph export manually

If your project doesn't have a supported [lockfile](../../terminology/_index.md#lockfile) or
[dependency graph export](../../terminology/_index.md#dependency-graph-export) committed to its
repository and dependency resolution does not support it, you need to provide one.

The examples below show how to create a file that is supported by the GitLab analyzer for popular
languages and package managers. See also the complete list of
[supported languages and files](#supported-languages-and-files).

#### Go

If your project provides only a `go.mod` file, the dependency scanning analyzer can still extract the list of components. However, [dependency path](../../dependency_list/_index.md#dependency-paths) information is not available. Additionally, you might encounter false positives if there are multiple versions of the same module.

To benefit from improved component detection and feature coverage, you should provide a `go.graph` file generated using the [`go mod graph` command](https://go.dev/ref/mod#go-mod-graph) from the Go toolchain.

The following example `.gitlab-ci.yml` demonstrates how to enable the analyzer
with [dependency path](../../dependency_list/_index.md#dependency-paths)
support on a Go project. The dependency graph export is output as a job artifact in the `build`
stage, before dependency scanning runs.

```yaml
stages:
  - build
  - test

include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
go:build:
  stage: build
  image: "golang:latest"
  script:
    - "go mod tidy"
    - "go build ./..."
    - "go mod graph > go.graph"
  artifacts:
    when: on_success
    access: developer
    paths: ["**/go.graph"]

```

#### Gradle

For Gradle projects use either of the following methods to create a dependency graph export.

- Nebula Gradle Dependency Lock Plugin
- Gradle's HtmlDependencyReportTask

##### Dependency lock plugin

This method gives information about dependencies which are direct.

To enable the analyzer on a Gradle project:

1. Edit the `build.gradle` or `build.gradle.kts` to use the
   [gradle-dependency-lock-plugin](https://github.com/nebula-plugins/gradle-dependency-lock-plugin/wiki/Usage#example) or use an init script.
1. Configure the `.gitlab-ci.yml` file to generate the `dependencies.lock` and `dependencies.direct.lock` artifacts, and pass them
   to the `dependency-scanning` job.

The following example demonstrates how to configure the analyzer
for a Gradle project.

```yaml
stages:
  - build
  - test

image: gradle:8.0-jdk11

include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

generate nebula lockfile:
  # Running in the build stage ensures that the dependency-scanning job
  # receives the scannable artifacts.
  stage: build
  script:
    - |
      cat << EOF > nebula.gradle
      initscript {
          repositories {
            mavenCentral()
          }
          dependencies {
              classpath 'com.netflix.nebula:gradle-dependency-lock-plugin:12.7.1'
          }
      }

      allprojects {
          apply plugin: nebula.plugin.dependencylock.DependencyLockPlugin
      }
      EOF
      ./gradlew --init-script nebula.gradle -PdependencyLock.includeTransitives=true -PdependencyLock.lockFile=dependencies.lock generateLock saveLock
      ./gradlew --init-script nebula.gradle -PdependencyLock.includeTransitives=false -PdependencyLock.lockFile=dependencies.direct.lock generateLock saveLock
      # generateLock saves the lockfile in the build/ directory of a project
      # and saveLock copies it into the root of a project. To avoid duplicates
      # and get an accurate location of the dependency, use find to remove the
      # lockfiles in the build/ directory only.
  after_script:
    - find . -path '*/build/dependencies*.lock' -print -delete
  # Collect all generated artifacts and pass them onto jobs in sequential stages.
  artifacts:
    paths:
      - '**/dependencies*.lock'
```

##### HtmlDependencyReportTask

This method gives information about dependencies which are both transitive and direct.

The [HtmlDependencyReportTask](https://docs.gradle.org/current/dsl/org.gradle.api.reporting.dependencies.HtmlDependencyReportTask.html)
is an alternative way to get the list of dependencies for a Gradle project (tested with `gradle`
versions 4 through 8). To enable use of this method with dependency scanning the artifact from running the
`gradle htmlDependencyReport` task needs to be available.

```yaml
stages:
  - build
  - test

# Define the image that contains Java and Gradle
image: gradle:8.0-jdk11

include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

build:
  stage: build
  script:
    - gradle --init-script report.gradle htmlDependencyReport
  # The gradle task writes the dependency report as a javascript file under
  # build/reports/project/dependencies. Because the file has an un-standardized
  # name, the after_script finds and renames the file to
  # `gradle-html-dependency-report.js` copying it to the  same directory as
  # `build.gradle`
  after_script:
    - |
      reports_dir=build/reports/project/dependencies
      while IFS= read -r -d '' src; do
        dest="${src%%/$reports_dir/*}/gradle-html-dependency-report.js"
        cp $src $dest
      done < <(find . -type f -path "*/${reports_dir}/*.js" -not -path "*/${reports_dir}/js/*" -print0)
  # Pass html report artifact to subsequent dependency scanning stage.
  artifacts:
    paths:
      - "**/gradle-html-dependency-report.js"
```

The command above uses the `report.gradle` file and can be supplied through `--init-script` or its contents can be added to `build.gradle` directly:

```kotlin
allprojects {
    apply plugin: 'project-report'
}
```

> [!note]
> The dependency report may indicate that dependencies for some configurations `FAILED` to be
> resolved. In this case dependency scanning logs a warning but does not fail the job. If you prefer
> to have the pipeline fail if resolution failures are reported, add the following extra steps to the
> `build` example above.

```shell
while IFS= read -r -d '' file; do
  grep --quiet -E '"resolvable":\s*"FAILED' $file && echo "Dependency report has dependencies with FAILED resolution status" && exit 1
done < <(find . -type f -path "*/gradle-html-dependency-report.js -print0)
```

#### Maven

The following example `.gitlab-ci.yml` demonstrates how to enable the analyzer
on a Maven project. The dependency graph export is output as a job artifact
in the `build` stage, before dependency scanning runs.

Requirement: use at least version `3.7.0` of the maven-dependency-plugin.

```yaml
stages:
  - build
  - test

image: maven:3.9.9-eclipse-temurin-21

include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

build:
  # Running in the build stage ensures that the dependency-scanning job
  # receives the maven.graph.json artifacts.
  stage: build
  script:
    - mvn install
    - mvn org.apache.maven.plugins:maven-dependency-plugin:3.8.1:tree -DoutputType=json -DoutputFile=maven.graph.json
  # Collect all maven.graph.json artifacts and pass them onto jobs
  # in sequential stages.
  artifacts:
    paths:
      - "**/*.jar"
      - "**/maven.graph.json"
```

#### pip

If your project provides a `requirements.txt` lockfile generated by the [pip-compile command line tool](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/),
the dependency scanning analyzer can extract the list of components and the dependency graph information,
which provides support for the [dependency path](../../dependency_list/_index.md#dependency-paths) feature.

Alternatively, your project can provide a `pipdeptree.json` dependency graph export generated by the [`pipdeptree --json` command line utility](https://pypi.org/project/pipdeptree/).

The following example `.gitlab-ci.yml` demonstrates how to enable the analyzer
with [dependency path](../../dependency_list/_index.md#dependency-paths)
support on a pip project. The `build` stage outputs the dependency graph export as a job artifact
before dependency scanning runs.

```yaml
stages:
  - build
  - test

include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

build:
  stage: build
  image: "python:latest"
  script:
    - "pip install -r requirements.txt"
    - "pip install pipdeptree"
    # Run pipdeptree to get project's dependencies and exclude pipdeptree itself to avoid false positives
    - "pipdeptree -e pipdeptree --json > pipdeptree.json"
  artifacts:
    when: on_success
    access: developer
    paths: ["**/pipdeptree.json"]
```

Because of a [known issue](https://github.com/tox-dev/pipdeptree/issues/107), `pipdeptree` does not mark
[optional dependencies](https://setuptools.pypa.io/en/latest/userguide/dependency_management.html#optional-dependencies)
as dependencies of the parent package. As a result, dependency scanning marks them as direct dependencies of the project,
instead of as transitive dependencies.

#### Pipenv

If your project provides only a `Pipfile.lock` file, the dependency scanning analyzer can still extract the list of components. However, [dependency path](../../dependency_list/_index.md#dependency-paths) information is not available.

To benefit from improved feature coverage, you should provide a `pipenv.graph.json` file generated by the [`pipenv graph` command](https://pipenv.pypa.io/en/latest/cli.html#graph).

The following example `.gitlab-ci.yml` demonstrates how to enable the analyzer
with [dependency path](../../dependency_list/_index.md#dependency-paths)
support on a Pipenv project. The `build` stage outputs the dependency graph export as a job artifact
before dependency scanning runs.

```yaml
stages:
  - build
  - test

include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

build:
  stage: build
  image: "python:3.12"
  script:
    - "pip install pipenv"
    - "pipenv install"
    - "pipenv graph --json-tree > pipenv.graph.json"
  artifacts:
    when: on_success
    access: developer
    paths: ["**/pipenv.graph.json"]
```

#### sbt

To enable the analyzer on an sbt project:

- Edit the `plugins.sbt` to use the
  [sbt-dependency-graph plugin](https://github.com/sbt/sbt-dependency-graph/blob/master/README.md#usage-instructions).

The following example `.gitlab-ci.yml` demonstrates how to enable the analyzer
with [dependency path](../../dependency_list/_index.md#dependency-paths)
support in an sbt project. The `build` stage outputs the dependency graph export as a job artifact
before dependency scanning runs.

```yaml
stages:
  - build
  - test

include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

build:
  stage: build
  image: "sbtscala/scala-sbt:eclipse-temurin-17.0.13_11_1.10.7_3.6.3"
  script:
    - "sbt dependencyDot"
  artifacts:
    when: on_success
    access: developer
    paths: ["**/dependencies-compile.dot"]
```

## Manifest fallback

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/585886) in GitLab 18.9. Only Maven manifest files supported, disabled by default.
- [Updated](https://gitlab.com/gitlab-org/gitlab/-/work_items/586921) in GitLab 18.9. Support for Python requirements file added, disabled by default.
- [Updated](https://gitlab.com/gitlab-org/gitlab/-/work_items/588788) in GitLab 18.10. Support for Gradle manifest files added, disabled by default.

{{< /history >}}

> [!warning]
> Manifest fallback is disabled by default during the limited availability stage.

To enable manifest fallback, set the `DS_ENABLE_MANIFEST_FALLBACK` CI/CD variable to `"true"`.

When a supported lockfile or dependency graph export is not available, the dependency scanning analyzer can extract dependencies from supported manifest files as a fallback.

The following manifest files are supported:

| Language | Package manager | Manifest file                      |
| -------- | --------------- | ---------------------------------- |
| Java     | Maven           | `pom.xml`                          |
| Python   | pip             | `requirements.txt`                 |
| Java     | Gradle          | `build.gradle`, `build.gradle.kts` |

> [!warning]
>
> Manifest fallback has reduced accuracy compared to lockfile scanning:
>
> - No transitive dependencies: Only direct dependencies are detected.
> - Exact resolved versions cannot always be determined.

## How it scans an application

The dependency scanning using SBOM feature relies on a decomposed dependency analysis approach that separates dependency detection from other analyses, like static reachability or vulnerability scanning.

This separation of concerns and the modularity of this architecture allows to better support customers through expansion
of language support, a tighter integration and experience within the GitLab platform, and a shift towards industry standard
report types.

When [dependency resolution](#dependency-resolution) is enabled, resolution jobs run in
the `.pre` stage before the `dependency-scanning` job. These jobs generate lockfiles
or dependency graph exports as artifacts, which the `dependency-scanning` job then consumes.

The overall flow of dependency scanning is illustrated below

```mermaid
flowchart TD
    subgraph CI[CI Pipeline]
        START([CI Job Starts])
        DETECT[Dependency Detection]
        SBOM_GEN[SBOM Reports Generation]
        SR[Static Reachability Analysis]
        UPLOAD[Upload SBOM Files]
        DL[Download Scan Results]
        REPORT[DS Security Report Generation]
        END([CI Job Complete])
    end

    subgraph GitLab[GitLab Instance]
        API[CI SBOM Scan API]
        SCANNER[GitLab SBOM Vulnerability Scanner]
        RESULTS[Scan Results]
    end

    START --> DETECT
    DETECT --> SBOM_GEN
    SBOM_GEN --> SR
    SR --> UPLOAD
    UPLOAD --> API
    API --> SCANNER
    SCANNER --> RESULTS
    RESULTS --> DL
    DL --> REPORT
    REPORT --> END
```

In the dependency detection phase the analyzer parses available lockfiles to build a comprehensive inventory of your project's dependencies and their relationship (dependency graph). This inventory is captured in a CycloneDX SBOM (Software Bill of Materials) document.

In the static reachability phase he analyzer parses source files to identify which SBOM components are actively used and marks them accordingly in the SBOM file.
This allows users to prioritize vulnerabilities based on whether the vulnerable component is reachable.
For more information, see the [static reachability page](../static_reachability.md).

The SBOM documents are temporarily uploaded to the GitLab instance via the dependency scanning SBOM API.
The GitLab SBOM vulnerability scanner engine matches the SBOM components against advisories to generate a list of findings which is returned to the analyzer for inclusion in the dependency scanning report.

The API makes use of the default `CI_JOB_TOKEN` for authentication. Overriding the `CI_JOB_TOKEN` value with a different token might lead to 403 - forbidden responses from the API.

Users can configure the analyzer client that communicates with the dependency scanning SBOM API by using:

- `vulnerability_scan_api_timeout` or `DS_API_TIMEOUT`
- `vulnerability_scan_api_download_delay` or `DS_API_SCAN_DOWNLOAD_DELAY`

For more information see [available spec inputs](#available-spec-inputs) and [available CI/CD variables](#available-cicd-variables).

The generated reports are uploaded to the GitLab instance when the CI job completes and usually processed after pipeline completion.

The SBOM reports are used to support other SBOM based features like the [dependency list](../../dependency_list/_index.md), [license scanning](../../../compliance/license_scanning_of_cyclonedx_files/_index.md) or [continuous vulnerability scanning](../../continuous_vulnerability_scanning/_index.md).

The dependency scanning report follows the generic process for [security scanning results](../../detect/security_scanning_results.md)

- If the dependency scanning report is declared by a CI/CD job on the default branch: vulnerabilities are created,
  and can be seen in the [vulnerability report](../../vulnerability_report/_index.md).
- If the dependency scanning report is declared by a CI/CD job on a non-default branch: security findings are created,
  and can be seen in the [security tab of the pipeline view](../../detect/security_scanning_results.md) and MR security widget.

## Offline support

{{< details >}}

- Tier: Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

For instances in an environment with limited, restricted, or intermittent access
to external resources through the internet, you need to make some adjustments to run dependency scanning jobs successfully.
For more information, see [offline environments](../../offline_deployments/_index.md).

### Requirements

To run dependency scanning in an offline environment you must have:

- A GitLab Runner with the `docker` or `kubernetes` executor.
- Local copies of the dependency scanning analyzer images.
- Access to the [Package Metadata Database](../../../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database). Required to have license and advisory data for your dependencies.

### Local copies of analyzer images

To use the dependency scanning analyzer:

1. Import the following default dependency scanning analyzer images from `registry.gitlab.com` into
   your [local Docker container registry](../../../packages/container_registry/_index.md):

   ```plaintext
   registry.gitlab.com/security-products/dependency-scanning:1
   ```

   The process for importing Docker images into a local offline Docker registry depends on
   **your network security policy**. Consult your IT staff to find an accepted and approved
   process by which external resources can be imported or temporarily accessed.
   These scanners are [periodically updated](../../detect/vulnerability_scanner_maintenance.md)
   with new definitions, and you may want to download them regularly. In case your offline instance
   has access to the GitLab registry you can use the [Security-Binaries template](../../offline_deployments/_index.md#using-the-official-gitlab-template) to download the latest dependency scanning analyzer image.

1. Configure GitLab CI/CD to use the local analyzers.

   Set the value of the CI/CD variable `SECURE_ANALYZERS_PREFIX` or `analyzer_image_prefix` spec input to your local Docker registry - in
   this example, `docker-registry.example.com`.

   ```yaml
   include:
     - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

   variables:
     SECURE_ANALYZERS_PREFIX: "docker-registry.example.com/analyzers"
   ```

## Enforce scanning on multiple projects

Enforce dependency scanning on multiple projects by using a security policy. Dependency scanning
requires a scannable artifact, either a lockfile or dependency graph export. Whether or not the
scannable artifact is committed to the project's repository determines the choice of policy.

- If the scannable artifact is committed to the repository, use a
  [scan execution policy](../../policies/scan_execution_policies.md).

  For projects that have the scannable artifacts committed to their repositories, or supported
  by [dependency resolution](#dependency-resolution), a scan execution
  policy provides the most direct way to enforce dependency scanning.

- If the scannable artifact is not committed to the repository, and not supported
  by [dependency resolution](#dependency-resolution) use a
  [pipeline execution policy](../../policies/pipeline_execution_policies.md).

  For projects that do not have the scannable artifacts committed to their repositories, you must
  use a pipeline execution policy. The policy must define a custom CI/CD job to generate scannable
  artifacts before invoking dependency scanning.

  The pipeline execution policy must:

  - Generate lockfiles or dependency graph exports as part of the CI/CD pipeline.
  - Customize the dependency detection process for your specific project requirements.
  - Implement the language-specific instructions for build tools such as Gradle and Maven.

The following example uses the Gradle `nebula` plugin to generate lock files. For other languages
see [Create lockfile or dependency graph export manually](#create-lockfile-or-dependency-graph-export-manually).

### Example: Pipeline execution policy for a Gradle project

For a Gradle project without a scannable artifact committed to the repository, you must define an
artifact generation step in the pipeline execution policy. The following example uses the `nebula`
plugin.

1. In the dedicated security policy project, create or update the main policy file (for example,
   `policy.yml`):

   ```yaml
   pipeline_execution_policy:
   - name: Enforce Gradle dependency scanning with SBOM
     description: Generate dependency artifact and run dependency scanning.
     enabled: true
     pipeline_config_strategy: inject_policy
     content:
       include:
         - project: $SECURITY_POLICIES_PROJECT
           file: "dependency-scanning.yml"
   ```

1. Add the `dependency-scanning.yml` policy file:

   ```yaml
   stages:
     - build
     - test

   include:
     - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

   generate nebula lockfile:
     image: openjdk:11-jdk
     stage: build
     script:
       - |
         cat << EOF > nebula.gradle
         initscript {
             repositories {
               mavenCentral()
             }
             dependencies {
                 classpath 'com.netflix.nebula:gradle-dependency-lock-plugin:12.7.1'
             }
         }

         allprojects {
             apply plugin: nebula.plugin.dependencylock.DependencyLockPlugin
         }
         EOF
         ./gradlew --init-script nebula.gradle -PdependencyLock.includeTransitives=true -PdependencyLock.lockFile=dependencies.lock generateLock saveLock
         ./gradlew --init-script nebula.gradle -PdependencyLock.includeTransitives=false -PdependencyLock.lockFile=dependencies.direct.lock generateLock saveLock
     after_script:
       - find . -path '*/build/dependencies.lock' -print -delete
     artifacts:
       paths:
         - '**/dependencies.lock'
         - '**/dependencies.direct.lock'
   ```

This approach ensures that:

1. A pipeline run in the Gradle project generates the scannable artifacts.
1. Dependency scanning is enforced and has access to the scannable artifacts.
1. All projects in the policy scope consistently follow the same dependency scanning approach.
1. Configuration changes can be managed centrally and applied across multiple projects.

## Other ways of enabling the new dependency scanning feature

We strongly suggest you enable the dependency scanning feature using the `v2` template.
In case this is not possible you can choose one of the following ways:

### Using the `latest` template

> [!warning]
> The `latest` template is not considered stable and may include breaking changes. See [template editions](../../detect/security_configuration.md#template-editions).

Use the `latest` dependency scanning CI/CD template `Dependency-Scanning.latest.gitlab-ci.yml` to enable a GitLab provided analyzer.

- The (deprecated) Gemnasium analyzer is used by default.
- To enable the new dependency scanning analyzer, set the CI/CD variable `DS_ENFORCE_NEW_ANALYZER` to `true`.
- A [supported lockfile, dependency graph export manually](#create-lockfile-or-dependency-graph-export-manually), or [trigger file](#trigger-files-for-the-latest-template) must exist in the repository to create the `dependency-scanning` job in pipelines.

  ```yaml
  include:
    - template: Jobs/Dependency-Scanning.latest.gitlab-ci.yml

  variables:
    DS_ENFORCE_NEW_ANALYZER: 'true'
  ```

Alternatively you can enable the feature using the [Scan Execution Policies](../../policies/scan_execution_policies.md) with the `latest` template and enforce the new dependency scanning analyzer by setting the CI/CD variable `DS_ENFORCE_NEW_ANALYZER` to `true`.

If you wish to customize the analyzer behavior use the [available CI/CD variables](#available-cicd-variables)

#### Trigger files for the `latest` template

Trigger files create a `dependency-scanning` CI/CD job when using the [latest dependency scanning CI/CD template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.latest.gitlab-ci.yml).
The analyzer does not scan these files.
Your project can be supported if you use a trigger file to [create a lockfile or dependency graph export manually](#create-lockfile-or-dependency-graph-export-manually).

| Language        | Files                                                     |
| --------------- | --------------------------------------------------------- |
| C#/Visual Basic | `*.csproj`, `*.vbproj`                                    |
| Java            | `pom.xml`                                                 |
| Java/Kotlin     | `build.gradle`, `build.gradle.kts`                        |
| Python          | `requirements.pip`, `Pipfile`, `requires.txt`, `setup.py` |
| Scala           | `build.sbt`                                               |

### Using the dependency scanning CI/CD component

{{< history >}}

- Introduced as a [beta](../../../../policy/development_stages_support.md#beta) in GitLab 17.5. [Dependency scanning CI/CD component](https://gitlab.com/explore/catalog/components/dependency-scanning) version [`0.4.0`](https://gitlab.com/components/dependency-scanning/-/tags/0.4.0).
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/578686) in GitLab 18.8. [Dependency scanning CI/CD component](https://gitlab.com/explore/catalog/components/dependency-scanning) version [`1.0.0`](https://gitlab.com/components/dependency-scanning/-/tags/1.0.0).

{{< /history >}}

Use the
[dependency scanning CI/CD component](https://gitlab.com/explore/catalog/components/dependency-scanning)
to enable the new dependency scanning analyzer. Before choosing this approach, review the current
[limitations](../../../../ci/components/_index.md#use-a-gitlabcom-component-on-gitlab-self-managed) for GitLab Self-Managed.

  ```yaml
  include:
    - component: $CI_SERVER_FQDN/components/dependency-scanning/main@1
  ```

You must also [create a lockfile or dependency graph export manually](#create-lockfile-or-dependency-graph-export-manually).

When using the dependency scanning CI/CD component, the analyzer can be customized by configuring the [inputs](https://gitlab.com/explore/catalog/components/dependency-scanning).

### Bringing your own SBOM

> [!warning]
> Third-party SBOM support is technically possible but highly subject to change as we complete official support with this [epic](https://www.gitlab.com/groups/gitlab-org/-/epics/14760).

Use your own CycloneDX SBOM document generated with a 3rd party CycloneDX SBOM generator or a custom tool as [a CI/CD artifact report](../../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx) in a custom CI job.

To activate dependency scanning using SBOM, the provided CycloneDX SBOM document must:

- Comply with [the CycloneDX specification](https://github.com/CycloneDX/specification) version `1.4`, `1.5`, or `1.6`. Online validator available on [CycloneDX Web Tool](https://cyclonedx.github.io/cyclonedx-web-tool/validate).
- Comply with [the GitLab CycloneDX property taxonomy](../../../../development/sec/cyclonedx_property_taxonomy.md).
- Be uploaded as [a CI/CD artifact report](../../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx) from a successful CI job.

## Troubleshooting

When working with dependency scanning, you might encounter the following issues.

### `403 Forbidden` error when you use a custom `CI_JOB_TOKEN`

The dependency scanning SBOM API might return a `403 Forbidden` error during the scan upload or download phase.

This happens because the dependency scanning SBOM API requires the default `CI_JOB_TOKEN` for authentication.
If you override the `CI_JOB_TOKEN` variable with a custom token (such as a project access token or personal access token),
the API cannot authenticate the request properly, even if the custom token has the `api` scope.

To resolve this issue, either:

- Recommended. Remove the `CI_JOB_TOKEN` override. Overriding predefined variables can cause unexpected behavior.
  See [CI/CD variables](../../../../ci/variables/_index.md#use-pipeline-variables) for more information.
- Use a different variable name. If you need to use a custom token for other purposes in your pipeline, store it in a different CI/CD variable, like `CUSTOM_ACCESS_TOKEN`,
  instead of overriding `CI_JOB_TOKEN`.

GitLab does not support [fine-grained job permissions](../../../../ci/jobs/fine_grained_permissions.md) for dependency scanning API endpoints, but [issue 578850](https://gitlab.com/gitlab-org/gitlab/-/issues/578850) proposes to add this feature.

### Warning: `grep: command not found`

The analyzer image contains minimal dependencies to decrease the image's attack surface.
As a result, utilities commonly found in other images, like `grep`, are missing from the image.
This may result in a warning like `/usr/bin/bash: line 3: grep: command not found` to appear in
the job log. This warning does not impact the results of the analyzer and can be ignored.

### Compliance framework compatibility

When using SBOM-based dependency scanning on GitLab Self-Managed instances, there are compatibility considerations with compliance frameworks:

- GitLab.com: The "Dependency scanning running" compliance control works correctly with SBOM-based dependency scanning.
- GitLab Self-Managed from 18.4: The "Dependency scanning running" compliance control may fail when using SBOM-based dependency scanning (`DS_ENFORCE_NEW_ANALYZER: 'true'`) because the traditional `gl-dependency-scanning-report.json` artifact is not generated.

Workaround for Self-Managed instances: If you need to pass compliance framework checks that require the "Dependency scanning running" control, you can use the `v2` template (`Jobs/Dependency-Scanning.v2.gitlab-ci.yml`) which generates both SBOM and dependency scanning reports

For more information about compliance controls, see [GitLab compliance controls](../../../compliance/compliance_frameworks/_index.md#gitlab-compliance-controls).

### Resolution job fails but dependency scanning still runs

Because resolution jobs run automatically they set `allow_failure: true`. If a resolution job fails, the
`dependency-scanning` job still runs. Depending on whether a lockfile is committed to the
repository, the scan either uses the committed file or falls back to
[manifest fallback](#manifest-fallback) if enabled.

Check [known limitations](#dependency-resolution-limitations) to verify if your use case is supported.

To investigate a resolution failure, check the CI/CD job log of the failing resolution job.
The log includes the output of the DS analyzer service container execution and the output
of the build tool commands. If the service log is not visible, you can set `CI_DEBUG_SERVICES` to `"true"`
to [capture service container logs](../../../../ci/services/_index.md#capturing-service-container-logs).

If necessary, you can [disable dependency resolution](#disable-dependency-resolution) and
use a manually generated lockfile instead.

### Error: `failed to verify certificate: x509: certificate signed by unknown authority`

When the dependency scanning analyzer connects to a host the following error might occur. The cause of this
error is that the certificate used by the dependency scanning analyzer is not trusted by the host.

```plaintext
failed to verify certificate: x509: certificate signed by unknown authority
```

To resolve this issue, provide the self-signed certificate in the `ADDITIONAL_CA_CERT_BUNDLE` CI/CD variable.
This certificate will then be used by the dependency scanning analyzer when connecting to the host.

The value of the `ADDITIONAL_CA_CERT_BUNDLE` environment variable must be the certificate itself:

```yaml
include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

dependency-scanning:
  variables:
    ADDITIONAL_CA_CERT_BUNDLE: |
      -----BEGIN CERTIFICATE-----
      <...>
      -----END CERTIFICATE-----
  before_script:
    - echo "$ADDITIONAL_CA_CERT_BUNDLE" > /tmp/cacert.pem
    - export SSL_CERT_FILE="/tmp/cacert.pem"
```
