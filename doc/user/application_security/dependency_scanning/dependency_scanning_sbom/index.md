---
stage: Secure
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Dependency scanning by using SBOM

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/395692) in GitLab 17.3 behind the feature flag `dependency_scanning_using_sbom_reports`.
> - Released [lockfile-based Dependency Scanning](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning/-/blob/main/README.md?ref_type=heads#supported-files) analyzer as an [Experiment](../../../../policy/experiment-beta-support.md#experiment-features) in GitLab 17.4.
> - Released [Dependency Scanning CI/CD Component](https://gitlab.com/explore/catalog/components/dependency-scanning) version [`0.4.0`](https://gitlab.com/components/dependency-scanning/-/tags/0.4.0) in GitLab 17.5 with support for the [lockfile-based Dependency Scanning](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning/-/blob/main/README.md?ref_type=heads#supported-files) analyzer.

FLAG:
This feature uses an Experimental analyzer.
For more information, see the history.
This feature is available for testing, but not ready for production use.

Dependency scanning using CycloneDX SBOM analyzes your application's dependencies for known
vulnerabilities. All dependencies are scanned, including transitive dependencies, also known as
nested dependencies.

Dependency scanning is often considered part of Software Composition Analysis (SCA). SCA can contain
aspects of inspecting the items your code uses. These items typically include application and system
dependencies that are almost always imported from external sources, rather than sourced from items
you wrote yourself.

Dependency scanning can run in the development phase of your application's life cycle. Every time a
pipeline produces an SBOM report, security findings are identified and compared between the source
and target branches. Findings and their severity are listed in the merge request, enabling you to
proactively address the risk to your application, before the code change is committed. Security
findings can also be identified outside a pipeline by
[Continuous Vulnerability Scanning](../../continuous_vulnerability_scanning/index.md).

GitLab offers both dependency scanning and [container scanning](../../container_scanning/index.md) to
ensure coverage for all of these dependency types. To cover as much of your risk area as possible,
we encourage you to use all of our security scanners. For a comparison of these features, see
[Dependency Scanning compared to Container Scanning](../../comparison_dependency_and_container_scanning.md).

## Supported package managers

For a list of supported package managers, see the analyzer's
[supported files](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning/#supported-files).

## Dependency detection workflow

The dependency detection workflow is as follows:

1. The application to be scanned provides a CycloneDX SBOM file or creates one.
1. GitLab checks each of the dependencies listed in the SBOM against the GitLab Advisory Database.
1. If the dependency scanning job is run on the default branch: vulnerabilities are created, and can be seen in the vulnerability report.

   If the dependency scanning job is run on a non-default branch: security findings are created, and can be seen in the pipeline security tab and MR security widget.

## Configuration

Enable the dependency scanning analyzer to ensure it scans your application’s dependencies for known vulnerabilities.
You can then adjust its behavior by configuring the CI/CD component's inputs.

## Enabling the analyzer

Prerequisites:

- The component's [stage](https://gitlab.com/explore/catalog/components/dependency-scanning) is required in the `.gitlab-ci.yml` file.
- With self-managed runners you need a GitLab Runner with the
  [`docker`](https://docs.gitlab.com/runner/executors/docker.html) or
  [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executor.
  - If you're using SaaS runners on GitLab.com, this is enabled by default.
- A [supported lock file or dependency graph](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning/#supported-files)
  must be in the repository.
  Alternatively, configure the CI/CD job to output either as a job artifact,
  ensuring the artifacts are generated in a stage before the `dependency-scanning`
  job's stage. See the following example.

To enable the analyzer, use the `main` [dependency scanning CI/CD component](https://gitlab.com/explore/catalog/components/dependency-scanning).

### Enabling the analyzer for a Maven project

The following example `.gitlab-ci.yml` demonstrates how to enable the CI/CD
component on a Maven project. The dependency graph is output as a job artifact
in the `build` stage, before dependency scanning runs.

```yaml
stages:
  - build
  - test

image: maven:3.9.9-eclipse-temurin-21

include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@0

build:
  # Running in the build stage ensures that the dependency-scanning job
  # receives the maven.graph.json artifacts.
  stage: build
  script:
    - mvn install
    - mvn dependency:tree -DoutputType=json -DoutputFile=maven.graph.json
  # Collect all maven.graph.json artifacts and pass them onto jobs
  # in sequential stages.
  artifacts:
    paths:
      - "**/*.jar"
      - "**/maven.graph.json"

```

### Enabling the analyzer for a Gradle project

To enable the CI/CD component on a Gradle project:

1. Edit the `build.gradle` or `build.gradle.kts` to use the [gradle-dependency-lock-plugin](https://github.com/nebula-plugins/gradle-dependency-lock-plugin/wiki/Usage#example).
1. Configure the `.gitlab-ci.yml` file to generate the `dependencies.lock` artifacts, and pass them to the `dependency-scanning` job.

The following example demonstrates how to configure the component
for a Gradle project.

```yaml
stages:
  - build
  - test

# Define the image that contains Java and Gradle
image: gradle:8.0-jdk11

include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@0.4.0

build:
  # Running in the build stage ensures that the dependency-scanning job
  # receives the maven.graph.json artifacts.
  stage: build
  script:
    - gradle generateLock saveLock
    - gradle assemble
  # generateLock saves the lock file in the build/ directory of a project
  # and saveLock copies it into the root of a project. To avoid duplicates
  # and get an accurate location of the dependency, use find to remove the
  # lock files in the build/ directory only.
  after_script:
    - find . -path '*/build/dependencies.lock' -print -delete
  # Collect all dependencies.lock artifacts and pass them onto jobs
  # in sequential stages.
  artifacts:
    paths:
      - "**/dependencies.lock"

```

## Customizing analyzer behavior

The analyzer can be customized by configuring the CI/CD component's
[inputs](https://gitlab.com/explore/catalog/components/dependency-scanning).

## Output

The dependency scanning analyzer produces CycloneDX Software Bill of Materials (SBOM) for each supported
lock file or dependency graph export detected.

### CycloneDX Software Bill of Materials

> - Generally available in GitLab 15.7.

The dependency scanning analyzer outputs a [CycloneDX](https://cyclonedx.org/) Software Bill of Materials (SBOM)
for each supported lock or dependency graph export it detects. The CycloneDX SBOMs are created as job artifacts.

The CycloneDX SBOMs are:

- Named `gl-sbom-<package-type>-<package-manager>.cdx.json`.
- Available as job artifacts of the dependency scanning job.
- Uploaded as `cyclonedx` reports.
- Saved in the same directory as the detected lock or dependency graph exports files.

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

### Merging multiple CycloneDX SBOMs

You can use a CI/CD job to merge the multiple CycloneDX SBOMs into a single SBOM.

NOTE:
GitLab uses [CycloneDX Properties](https://cyclonedx.org/use-cases/#properties--name-value-store)
to store implementation-specific details in the metadata of each CycloneDX SBOM, such as the
location of dependency graph exports and lock files. If multiple CycloneDX SBOMs are merged together,
this information is removed from the resulting merged file.

For example, the following `.gitlab-ci.yml` extract demonstrates how the Cyclone SBOM files can be
merged, and the resulting file validated.

```yaml
stages:
  - test
  - merge-cyclonedx-sboms

include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@0.4.0

merge cyclonedx sboms:
  stage: merge-cyclonedx-sboms
  image:
    name: cyclonedx/cyclonedx-cli:0.27.1
    entrypoint: [""]
  script:
    - find . -name "gl-sbom-*.cdx.json" -exec cyclonedx merge --output-file gl-sbom-all.cdx.json --input-files "{}" +
    # optional: validate the merged sbom
    - cyclonedx validate --input-version v1_6 --input-file gl-sbom-all.cdx.json
  artifacts:
    paths:
      - gl-sbom-all.cdx.json
```
