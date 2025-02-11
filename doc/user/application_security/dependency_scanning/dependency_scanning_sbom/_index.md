---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Dependency scanning by using SBOM
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/395692) in GitLab 17.1 and officially released in GitLab 17.3 with a flag named `dependency_scanning_using_sbom_reports`.
> - [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/395692) in GitLab 17.5.
> - Released [lockfile-based Dependency Scanning](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning/-/blob/main/README.md?ref_type=heads#supported-files) analyzer as an [Experiment](../../../../policy/development_stages_support.md#experiment-features) in GitLab 17.4.
> - Released [Dependency Scanning CI/CD Component](https://gitlab.com/explore/catalog/components/dependency-scanning) version [`0.4.0`](https://gitlab.com/components/dependency-scanning/-/tags/0.4.0) in GitLab 17.5 with support for the [lockfile-based Dependency Scanning](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning/-/blob/main/README.md?ref_type=heads#supported-files) analyzer.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature uses an experimental scanner.
This feature is available for testing, but not ready for production use.

Dependency scanning using CycloneDX SBOM analyzes your application's dependencies for known
vulnerabilities. All dependencies are scanned, [including transitive dependencies](../_index.md).

Dependency scanning is often considered part of Software Composition Analysis (SCA). SCA can contain
aspects of inspecting the items your code uses. These items typically include application and system
dependencies that are almost always imported from external sources, rather than sourced from items
you wrote yourself.

Dependency scanning can run in the development phase of your application's lifecycle. Every time a
pipeline produces an SBOM report, security findings are identified and compared between the source
and target branches. Findings and their severity are listed in the merge request, enabling you to
proactively address the risk to your application, before the code change is committed. Security
findings can also be identified outside a pipeline by
[Continuous Vulnerability Scanning](../../continuous_vulnerability_scanning/_index.md).

GitLab offers both dependency scanning and [container scanning](../../container_scanning/_index.md) to
ensure coverage for all of these dependency types. To cover as much of your risk area as possible,
we encourage you to use all of our security scanners. For a comparison of these features, see
[Dependency Scanning compared to Container Scanning](../../comparison_dependency_and_container_scanning.md).

## Supported package types

The vulnerability scanning of SBOM files is performed in GitLab by the same scanner used by
[Continuous Vulnerability Scanning](../../continuous_vulnerability_scanning/_index.md).
In order for security scanning to work for your package manager, advisory information must be
available for the components present in the SBOM report.

See [Supported package types](../../continuous_vulnerability_scanning/_index.md#supported-package-types).

## Dependency detection workflow

The dependency detection workflow is as follows:

1. The application to be scanned provides a
   [CycloneDX SBOM report](../../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx)
   or creates one by [enabling the GitLab Dependency Scanning analyzer](#enabling-the-analyzer).
1. GitLab checks each of the dependencies listed in the SBOM against the GitLab Advisory Database.
1. If the SBOM report is declared by a CI/CD job on the default branch: vulnerabilities are created,
   and can be seen in the vulnerability report.

   If the SBOM report is declared by a CI/CD job on a non-default branch: no vulnerability
   scanning takes place. Improvement to the feature is being tracked in
   [Epic 14636](https://gitlab.com/groups/gitlab-org/-/epics/14636) so that security findings are
   created, and can be seen in the pipeline security tab and MR security widget.

## Configuration

- Enable the dependency scanning analyzer to generate a CycloneDX SBOM containing your
  application's dependencies. Once this report is uploaded to GitLab, the dependencies are scanned
  for known vulnerabilities.
- You can adjust the analyzer behavior by configuring the CI/CD component's inputs.

For a list of languages and package managers supported by the analyzer, see
[supported files](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning/#supported-files).

After a
[CycloneDX SBOM report](../../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx)
is uploaded, GitLab automatically scans all
[supported package types](../../continuous_vulnerability_scanning/_index.md#supported-package-types)
present in the report.

## Enabling the analyzer

The Dependency Scanning analyzer produces a CycloneDX SBOM report compatible with GitLab. If your
application can't generate such a report, you can use the GitLab analyzer to produce one.

Prerequisites:

- A [supported lock file or dependency graph](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning/#supported-files)
  must exist in the repository or must be passed as an artifact to the `dependency-scanning` job.
- The component's [stage](https://gitlab.com/explore/catalog/components/dependency-scanning) is required in the `.gitlab-ci.yml` file.
- With self-managed runners you need a GitLab Runner with the
  [`docker`](https://docs.gitlab.com/runner/executors/docker.html) or
  [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executor.
  - If you're using SaaS runners on GitLab.com, this is enabled by default.

To enable the analyzer, use the `main` [dependency scanning CI/CD component](https://gitlab.com/explore/catalog/components/dependency-scanning):

```yaml
include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@0
```

### Language-specific instructions

If your project doesn't have a supported lock file dependency graph committed to its
repository, you need to provide one.

The examples below show how to create a file that is supported by the GitLab analyzer for popular
languages and package managers.

#### Go

If your project provides only a `go.mod` file, the Dependency Scanning analyzer can still extract the list of components. However, [dependency path](../../dependency_list/_index.md#dependency-paths) information is not available. Additionally, you might encounter false positives if there are multiple versions of the same module.

To benefit from improved component detection and feature coverage, you should provide a `go.graph` file generated using the [`go mod graph` command](https://go.dev/ref/mod#go-mod-graph) from the Go toolchain.

The following example `.gitlab-ci.yml` demonstrates how to enable the CI/CD
component with [dependency path](../../dependency_list/_index.md#dependency-paths)
support on a Go project. The dependency graph is output as a job artifact in the `build`
stage, before dependency scanning runs.

```yaml
stages:
  - build
  - test

include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@0

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

To enable the CI/CD component on a Gradle project:

1. Edit the `build.gradle` or `build.gradle.kts` to use the
   [gradle-dependency-lock-plugin](https://github.com/nebula-plugins/gradle-dependency-lock-plugin/wiki/Usage#example).
1. Configure the `.gitlab-ci.yml` file to generate the `dependencies.lock` artifacts, and pass them
   to the `dependency-scanning` job.

The following example demonstrates how to configure the component
for a Gradle project.

```yaml
stages:
  - build
  - test

# Define the image that contains Java and Gradle
image: gradle:8.0-jdk11

include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@0

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

#### Maven

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

#### pip

If your project provides a `requirements.txt` lock file generated by the [pip-compile command line tool](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/), the Dependency Scanning analyzer can extract the list of components and the dependency graph information, which provides support for the [dependency path](../../dependency_list/_index.md#dependency-paths) feature.

Alternatively, your project can provide a `pipdeptree.json` dependency graph export generated by the [`pipdeptree --json` command line utility](https://pypi.org/project/pipdeptree/).

The following example `.gitlab-ci.yml` demonstrates how to enable the CI/CD
component with [dependency path](../../dependency_list/_index.md#dependency-paths)
support on a pip project. The `build` stage outputs the dependency graph as a job artifact
before dependency scanning runs.

```yaml
stages:
  - build
  - test

include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@0

build:
  stage: build
  image: "python:latest"
  script:
    - "pip install pipdeptree"
    - "pipdeptree --json > pipdeptree.json"
  artifacts:
    when: on_success
    access: developer
    paths: ["**/pipdeptree.json"]

```

#### Pipenv

If your project provides only a `Pipfile.lock` file, the Dependency Scanning analyzer can still extract the list of components. However, [dependency path](../../dependency_list/_index.md#dependency-paths) information is not available.

To benefit from improved feature coverage, you should provide a `pipenv.graph.json` file generated by the [`pipenv graph` command](https://pipenv.pypa.io/en/latest/cli.html#graph).

The following example `.gitlab-ci.yml` demonstrates how to enable the CI/CD
component with [dependency path](../../dependency_list/_index.md#dependency-paths)
support on a Pipenv project. The `build` stage outputs the dependency graph as a job artifact
before dependency scanning runs.

```yaml
stages:
  - build
  - test

include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@0

build:
  stage: build
  image: "python:latest"
  script:
    - "pipenv graph --json-tree > pipenv.graph.json"
  artifacts:
    when: on_success
    access: developer
    paths: ["**/pipenv.graph.json"]

```

#### sbt

To enable the CI/CD component on an sbt project:

- Edit the `plugins.sbt` to use the
  [sbt-dependency-graph plugin](https://github.com/sbt/sbt-dependency-graph/blob/master/README.md#usage-instructions).

The following example `.gitlab-ci.yml` demonstrates how to enable the CI/CD
component with [dependency path](../../dependency_list/_index.md#dependency-paths)
support in an sbt project. The `build` stage outputs the dependency graph as a job artifact
before dependency scanning runs.

```yaml
stages:
  - build
  - test

include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@0

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
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@0

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

## Troubleshooting

When working with dependency scanning, you might encounter the following issues.

### Warning: `grep: command not found`

The analyzer image contains minimal dependencies to decrease the image's attack surface.
As a result, utilities commonly found in other images, like `grep`, are missing from the image.
This may result in a warning like `/usr/bin/bash: line 3: grep: command not found` to appear in
the job log. This warning does not impact the results of the analyzer and can be ignored.
