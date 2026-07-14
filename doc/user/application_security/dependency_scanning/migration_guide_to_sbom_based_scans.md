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

- The dependency scanning CI/CD jobs are configured by including one of the dependency scanning CI/CD templates.

  ```yaml
    include:
      - template: Jobs/Dependency-Scanning.gitlab-ci.yml
      - template: Jobs/Dependency-Scanning.latest.gitlab-ci.yml
  ```

- The dependency scanning CI/CD jobs are configured by using [Scan Execution Policies](../policies/scan_execution_policies.md).
- The dependency scanning CI/CD jobs are configured by using [Pipeline Execution Policies](../policies/pipeline_execution_policies.md).

## Prepare for migration

Assess your migration effort, identify your path, verify prerequisites, and
determine which projects are affected.

### Estimate migration effort

The [Dependency Scanning migration evaluator](https://dependency-scanning-migration-evaluator-cb84d1.gitlab.io/)
generates a tailored migration checklist based on how dependency scanning is configured in your projects.
It asks about your enablement path, language ecosystems, CI/CD customizations, and (for self-managed instances)
Package Metadata Database sync status. The evaluator produces:

- An effort estimate (minimal, moderate, significant, or complex).
- A checklist of the migration steps that apply to your setup, with direct links to the relevant sections of this guide.
- Flags for situations that need extra attention (like projects that must move from a scan execution policy to a pipeline execution policy).

The evaluator runs entirely in your browser and does not send data anywhere.

### Identify your migration path

Existing configurations are not migrated automatically. To adopt the new feature, you must update your configuration.

Use the following list to find the migration path that applies to you:

- Stable template (`Jobs/Dependency-Scanning.gitlab-ci.yml`): Switch to the `v2` template by following the
  [generic migration steps](#migrate-to-dependency-scanning-using-sbom),
  then apply any
  [language-specific instructions](#language-specific-instructions) for the
  ecosystems used in your projects.
- Latest template (`Jobs/Dependency-Scanning.latest.gitlab-ci.yml`): Same as the stable template. Switch to the `v2`
  template by following the [generic migration steps](#migrate-to-dependency-scanning-using-sbom),
  then apply any [language-specific instructions](#language-specific-instructions).
- CI/CD component: The [main component](https://gitlab.com/components/dependency-scanning/-/tree/main/templates/main)
  already uses the new analyzer but older versions (v0 and v1) lag behind on the analyzer version and on supported inputs.
  Bump the include to the `v2` version and apply any [language-specific instructions](#language-specific-instructions).
  If you use a specialized Android, Rust, Swift, or CocoaPods component, migrate to the main component.
- Scan Execution Policies (SEP) or Pipeline Execution Policies (PEP): Edit the policy to reference the `v2` template,
  then follow the [generic migration steps](#migrate-to-dependency-scanning-using-sbom)
  and any [language-specific instructions](#language-specific-instructions) for projects in scope.
  SEP and PEP are built on top of the CI/CD templates, so the template changes propagate automatically
  to all projects in scope after the SEP is updated. For PEP, update the policy's CI/CD configuration
  directly to reference the `v2` template.

### Verify prerequisites: Package Metadata Database synchronization

The new dependency scanning analyzer requires
[Package Metadata Database (PMDB)](../../../administration/settings/security_and_compliance.md#package-metadata-database-synchronization)
synchronized for the package types used by your projects.
On GitLab.com, the instance already synchronizes data for all supported package types.
On GitLab Self-Managed and GitLab Dedicated, an administrator configures synchronization.

Before you migrate, an administrator should:

- Confirm that PMDB synchronization is enabled and that the package types
  used by your projects are selected. For more information, see
  [choose package registry metadata to sync](../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync).
- For offline or firewalled instances, follow
  [enabling the Package Metadata Database](../../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database).

If PMDB synchronization is not complete for a package type that your
projects use, the new analyzer cannot resolve advisories for the corresponding
components, and security findings may be missing after the migration.

### Identify affected projects

Identify projects that use the legacy dependency scanning feature. The
[security inventory](../security_inventory/_index.md) provides visibility
of scanner coverage across groups and projects. This step is the recommended starting point.

You can also locate legacy usage in your CI/CD configuration:

- Includes of the legacy templates
  `Jobs/Dependency-Scanning.gitlab-ci.yml` or
  `Jobs/Dependency-Scanning.latest.gitlab-ci.yml` in `.gitlab-ci.yml` files.
- References to the same templates in the scan
  execution policies and pipeline execution policies.
- Job names from the legacy analyzer (`gemnasium-dependency_scanning`,
  `gemnasium-maven-dependency_scanning`, `gemnasium-python-dependency_scanning`)
  in `.gitlab-ci.yml` files, policy YAML, or downstream jobs that use them in
  `needs:` or `dependencies:`.

## Understand the changes

The transition from the Gemnasium analyzer to the new dependency scanning
analyzer is a significant technical evolution. Most projects do not need to
change anything beyond the CI/CD configuration switch described in
[migrate to dependency scanning using SBOM](#migrate-to-dependency-scanning-using-sbom).
The changes described in this section help you understand why some
projects (notably Gradle, Maven, and Python without a lockfile) require
additional steps.

Key changes:

- Increased language support and file coverage: The new analyzer is not
  constrained to the Python and Java versions supported by the Gemnasium
  analyzer, and benefits from increased
  [file coverage](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files).
- Increased performance: The new analyzer prefers existing lockfiles or
  dependency graph exports and only runs ecosystem-specific
  [resolution jobs](dependency_scanning_sbom/_index.md#dependency-resolution)
  for projects that lack them.
- Smaller attack surface and more flexible configuration: The analyzer
  image only parses lockfiles and graph exports. Ecosystem-specific settings
  (private registries, custom CA bundles, JVM options) apply only to the
  relevant dependency resolution job. You can override the resolution
  images to match your build environment.

### A new approach to security scanning

When using the legacy dependency scanning feature, all scanning work happens in your CI/CD pipeline. When running a scan, the Gemnasium analyzer handles two critical tasks simultaneously: it identifies your project's dependencies and immediately performs a security analysis of those dependencies using a local copy of the GitLab advisory database and its specific security scanning engine. Then, it outputs results into various reports (CycloneDX SBOM and dependency scanning security report).

On the other hand, the dependency scanning using SBOM feature relies on a decomposed dependency analysis approach that separates dependency detection from other analyses, like static reachability or vulnerability scanning. While these tasks are still executed in the same CI/CD job, they function as decoupled, reusable components. For instance, the vulnerability scanning analysis reuses the unified engine, the GitLab SBOM vulnerability scanner, that also supports GitLab continuous vulnerability scanning features. This also opens up opportunity for future integration points, enabling more flexible vulnerability scanning workflows.

Read more about how dependency scanning using SBOM [scans an application](dependency_scanning_sbom/_index.md#how-it-scans-an-application).

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

In GitLab 19.0 and later, dependency resolution and manifest fallback are enabled by default.

For the most accurate results, commit a lockfile or dependency graph export to your repository, or generate one in a
preceding CI/CD job using your project's actual build environment. The following sections describe the options available
for each language and package manager.

### Accessing scan results

The `v2` template produces the same
[`gl-dependency-scanning-report.json`](../../../ci/yaml/artifacts_reports.md#artifactsreportsdependency_scanning)
job artifact as the legacy template. Downstream jobs that consume this
artifact (with `needs:` or `dependencies:`) continue to work after the
migration, though the producing job name changes from
`gemnasium-dependency_scanning` (and its Maven and Python variants) to
`dependency-scanning`.

## Migrate to dependency scanning using SBOM

How you migrate depends on how dependency scanning is enabled in your projects.
Each subsection covers the customizations to remove, references to update,
and minimal before-and-after example.

To find the subsection that applies to you, see [identify your migration path](#identify-your-migration-path).
For multi-language projects, complete the steps for each language in
[language-specific instructions](#language-specific-instructions).

### Migrate using the stable CI/CD template

To avoid disrupting existing pipelines, the stable template (`Jobs/Dependency-Scanning.gitlab-ci.yml`)
runs the legacy Gemnasium analyzer and is not updated to use the new analyzer.
To adopt the new analyzer, switch the `include` to the `v2` template
(`Jobs/Dependency-Scanning.v2.gitlab-ci.yml`).

Compared to the stable template, the `v2` template:

- Runs the new `dependency-scanning` job instead of the legacy
  `gemnasium-dependency_scanning`, `gemnasium-maven-dependency_scanning`,
  and `gemnasium-python-dependency_scanning` jobs.
- Does not predefine the legacy job names. Customizations that override
  `gemnasium-*` jobs (for example, by extending them in your `.gitlab-ci.yml`)
  no longer apply and must be removed or rewritten.
- Continues to produce the `gl-dependency-scanning-report.json`
  [job artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportsdependency_scanning).
  Downstream jobs that consume this artifact through `needs:` or `dependencies:`
  continue to work after the migration, but must reference the new
  `dependency-scanning` job name instead of the legacy `gemnasium-*` job names.
- Accepts the same CI/CD variables, with some changes documented in
  [Changes to CI/CD variables](#changes-to-cicd-variables).

Prerequisites:

- The Developer, Maintainer, or Owner role for the project.

To migrate using the stable CI/CD template:

1. Remove customizations that override the legacy `gemnasium-*` jobs in your
   `.gitlab-ci.yml` or in any included files. The `v2` template does not define
   these job names, so overrides might cause the pipeline to fail due to invalid
   CI/CD configuration.
1. Update the `include` statement to reference the `v2` template.
1. Update downstream jobs that reference the legacy job names in `needs:` or
   `dependencies:` to use `dependency-scanning` instead.
1. Apply any [language-specific instructions](#language-specific-instructions)
   for the ecosystems in your project.

Before:

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

# Customization that targets the legacy job name.
gemnasium-dependency_scanning:
  variables:
    SECURE_LOG_LEVEL: debug

# Downstream job that consumes the legacy report.
export-security-report:
  stage: deploy
  needs:
    - job: gemnasium-dependency_scanning
      artifacts: true
  script:
    - ./publish.sh gl-dependency-scanning-report.json
```

After:

```yaml
include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
    inputs:
      analyzer_log_level: debug

export-security-report:
  stage: deploy
  needs:
    - job: dependency-scanning
      artifacts: true
  script:
    - ./publish.sh gl-dependency-scanning-report.json
```

If your pipeline needs to run custom jobs before dependency resolution
(for example, to authenticate to a private registry or prepare a build cache),
see [adjust resolution job ordering](#adjust-resolution-job-ordering).

### Migrate using the latest CI/CD template

The latest template (`Jobs/Dependency-Scanning.latest.gitlab-ci.yml`) runs the
legacy Gemnasium analyzer by default. As a transitional step, it supports an
opt-in to the new analyzer through the `DS_ENFORCE_NEW_ANALYZER` CI/CD variable,
but only at version `v1` of the new analyzer and without
[dependency resolution](dependency_scanning_sbom/_index.md#dependency-resolution) jobs.

Prerequisites:

- The Developer, Maintainer, or Owner role for the project.

For Maven, Gradle, and Python projects, you must either:

- Commit a [lockfile or dependency graph export](dependency_scanning_sbom/_index.md#supported-languages-and-files)
  to the repository or generated by a preceding CI/CD job.
- Enable [manifest fallback](dependency_scanning_sbom/_index.md#manifest-fallback).

For full parity with the `v2` template (`v2` analyzer, dependency resolution,
manifest fallback), switch to the `v2` template by following the
[stable template steps](#migrate-using-the-stable-cicd-template). The migration
work is the same: remove customizations targeting the legacy `gemnasium-*` jobs,
update the `include` statement, and update downstream jobs.

If you already opted in to use the new DS analyzer through `DS_ENFORCE_NEW_ANALYZER`,
the transition is simpler. Review the changes the new template introduces before finalizing your migration.

If your pipeline needs to run custom jobs before dependency resolution
(for example, to authenticate to a private registry or prepare a build cache),
see [adjust resolution job ordering](#adjust-resolution-job-ordering).

### Migrate using the CI/CD component

> [!note]
> On GitLab Self-Managed, review the [current limitations](../../../ci/components/_index.md#use-a-gitlabcom-component-on-gitlab-self-managed)
> for using GitLab.com CI/CD components.

The `v2` release of the [main dependency scanning CI/CD component](https://gitlab.com/components/dependency-scanning/-/tree/main/templates/main)
is on par with the `v2` template. It runs the new analyzer in its `v2` version
and supports the same inputs. Older releases (`v0` and `v1`) lag behind on the
analyzer version and on supported features, so projects that include `v0` or `v1`
must bump the include to `v2`.

Prerequisites:

- The Developer, Maintainer, or Owner role for the project.

To migrate using the CI/Cd component:

1. Update the component `include` statement to reference version `2` of
   the main component.
1. Replace any inputs that have been renamed or removed in `v2`. The `v2`
   release of the main component exposes the same input set as the `v2` CI/CD
   template; see the
   [available spec inputs](dependency_scanning_sbom/_index.md#available-spec-inputs)
   reference for the full list.
1. Apply any [language-specific instructions](#language-specific-instructions)
   for the ecosystems in your project.

If you use a specialized component for Android, Rust, Swift, or CocoaPods,
migrate to the main component. The main component now covers all supported
languages and package managers. The specialized components are no longer
needed.

Before:

```yaml
include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@1
```

After:

```yaml
include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@2
```

If your pipeline needs to run custom jobs before dependency resolution
(for example, to authenticate to a private registry or prepare a build cache),
see [adjust resolution job ordering](#adjust-resolution-job-ordering).

### Migrate using scan execution policies

Scan execution policies enforce a CI/CD template across the projects targeted by
the policy. For dependency scanning, the policy's `template` field selects which
template runs. The new analyzer is available through the `v2` template edition.

The policy's behavior on each targeted project mirrors that of a project that
includes the corresponding CI/CD template directly. After the policy is updated
to reference `v2`, the steps for [the stable CI/CD template](#migrate-using-the-stable-cicd-template)
apply to each project in scope: remove customizations that target the legacy
`gemnasium-*` jobs and update any downstream jobs that consume them.

Prerequisites:

- The Owner role for the group, or a custom role with the `manage_security_policy_link` permission.

To migrate using scan execution policies:

1. Edit the scan execution policy and set `template: v2` for the
   `dependency_scanning` action.
1. In each project covered by the policy, remove customizations that override
   the legacy `gemnasium-*` jobs and update downstream jobs that reference them.
1. Apply any [language-specific instructions](#language-specific-instructions)
   for the ecosystems in projects covered by the policy.

Before:

```yaml
scan_execution_policy:
  - name: Enforce dependency scanning
    enabled: true
    rules:
      - type: pipeline
        branch_type: all
    actions:
      - scan: dependency_scanning
```

After:

```yaml
scan_execution_policy:
  - name: Enforce dependency scanning
    enabled: true
    rules:
      - type: pipeline
        branch_type: all
    actions:
      - scan: dependency_scanning
        template: v2
```

#### Projects not covered by dependency resolution or manifest fallback

Scan execution policies use the `build support` capability from the legacy
Gemnasium analyzer to provide a default build environment. The new analyzer
relies on [dependency resolution](dependency_scanning_sbom/_index.md#dependency-resolution)
or [manifest fallback](dependency_scanning_sbom/_index.md#manifest-fallback)
to detect dependencies for projects without a committed lockfile or dependency
graph export.

These mechanisms cover most projects that previously relied on `build support`.
A few situations still benefit from the additional flexibility of a pipeline
execution policy:

- The project's ecosystem is outside the current coverage of dependency
  resolution and manifest fallback (for example, Scala/sbt).
- Dependency resolution needs a setup step that goes beyond the available
  CI/CD variables (for example, authenticating against a private registry
  with non-standard credentials).

For those projects, use a [pipeline execution policy](#migrate-using-pipeline-execution-policies),
where you can customize the CI/CD jobs more freely and
[create a lockfile or dependency graph export manually](dependency_scanning_sbom/_index.md#create-lockfile-or-dependency-graph-export-manually).

### Migrate using pipeline execution policies

Pipeline execution policies enforce a complete CI/CD configuration that
typically includes a dependency scanning template or the CI/CD component, along
with project-specific customizations. The migration steps that apply depend on
what the policy's CI/CD configuration includes.

Prerequisites:

- The Owner role for the group, or a custom role with the `manage_security_policy_link` permission.

To migrate using pipeline execution policies:

1. Determine which template or component your policy uses:
   - If the policy includes the stable CI/CD template, follow
     [migrate using the stable CI/CD template](#migrate-using-the-stable-cicd-template).
   - If the policy includes the latest CI/CD template, follow
     [migrate using the latest CI/CD template](#migrate-using-the-latest-cicd-template).
   - If the policy includes the CI/CD component, follow
     [migrate using the CI/CD component](#migrate-using-the-cicd-component).

1. Apply those steps to the policy's CI/CD configuration/
1. Apply any [language-specific instructions](#language-specific-instructions) for the ecosystems in projects covered by the policy.

CI/CD variables set for projects, groups, or instances (and variables
defined in the policy's own `variables:` block) continue to apply to the new
`dependency-scanning` job and to the resolution jobs that run before it.
For variables whose status has changed in `v2`, see
[changes to CI/CD variables](#changes-to-cicd-variables).

If your pipeline needs to run custom jobs before dependency resolution
(for example, to authenticate to a private registry or prepare a build cache),
see [adjust resolution job ordering](#adjust-resolution-job-ordering).

## Other considerations

The following customizations apply regardless of how dependency scanning is
enabled in your projects.

### Adjust resolution job ordering

By default, dependency resolution jobs run in the `.pre` stage. If your
pipeline has custom jobs that must complete before dependency scanning
runs (for example, a `.pre` job that authenticates to a private registry
or primes a build cache), the resolution jobs run in parallel with those
custom jobs rather than after them. Resolution jobs cannot see artifacts
the custom jobs produce.

To preserve the intended ordering, move the resolution jobs to a later
stage by using the `resolution_jobs_stage` input on the `v2` template or
component:

```yaml
stages:
  - .pre
  - prepare
  - test

include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
    inputs:
      resolution_jobs_stage: prepare

private-registry-cache-build:
  stage: .pre
  script:
    - ./scripts/login-private-registry.sh
    - ./scripts/build-dependency-cache.sh
```

The resolution jobs then run in the `prepare` stage after the custom
`.pre` job completes. Dor the full list of inputs that control resolution job behavior,
see [available CI/CD inputs](dependency_scanning_sbom/_index.md#available-spec-inputs).

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

No additional steps are needed to migrate a Bundler project to use the dependency scanning analyzer.

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
This analyzer does not scan vendored JavaScript files. For more information, see the
[Dependency Scanning for JavaScript vendored libraries deprecation announcement](../../../update/deprecations.md#dependency-scanning-for-javascript-vendored-libraries)
for context and available actions. Support for a replacement feature is proposed in [epic 7186](https://gitlab.com/groups/gitlab-org/-/epics/7186).

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
This analyzer does not scan vendored JavaScript files. For more information, see the
[Dependency Scanning for JavaScript vendored libraries deprecation announcement](../../../update/deprecations.md#dependency-scanning-for-javascript-vendored-libraries)
for context and available actions. Support for a replacement feature is proposed in [epic 7186](https://gitlab.com/groups/gitlab-org/-/epics/7186).

#### Migrate a pnpm project

Migrate a pnpm project to use the new dependency scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.
- The Developer, Maintainer, or Owner role for the project.

No additional steps are required to migrate a pnpm project to use the dependency scanning analyzer.

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
This analyzer does not provide remediation data for Yarn dependencies. For more information, see the
[Resolve a vulnerability for dependency scanning on Yarn projects deprecation announcement](../../../update/deprecations.md#resolve-a-vulnerability-for-dependency-scanning-on-yarn-projects).
Support for a replacement feature is proposed in [epic 759](https://gitlab.com/groups/gitlab-org/-/epics/759).
This analyzer does not scan vendored JavaScript files. For more information, see the
[Dependency Scanning for JavaScript vendored libraries deprecation announcement](../../../update/deprecations.md#dependency-scanning-for-javascript-vendored-libraries)
for context and available actions. Support for a replacement feature is proposed in [epic 7186](https://gitlab.com/groups/gitlab-org/-/epics/7186).

#### Migrate a Yarn project

Migrate a Yarn project to use the new dependency scanning analyzer.

Prerequisites:

- Complete [the generic migration steps](#migrate-to-dependency-scanning-using-sbom) required for all projects.
- The Developer, Maintainer, or Owner role for the project.

There are no additional steps to migrate a Yarn project to use the dependency scanning analyzer. If you previously relied on the Resolve a vulnerability through merge request feature or on vendored JavaScript scanning, see the deprecation announcements linked under **New behavior** above for context and available actions.

## Changes to CI/CD variables

The following table lists the CI/CD variables previously used with the legacy dependency scanning feature
based on the Gemnasium analyzer and their status with the new dependency scanning analyzer:

| Legacy variable                  | Status with the new analyzer                                                                                    |
| -------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `ADDITIONAL_CA_CERT_BUNDLE`      | Kept. Prefer `additional_ca_cert_bundle` spec input.                                                            |
| `AST_ENABLE_MR_PIPELINES`        | Kept.                                                                                                           |
| `DEPENDENCY_SCANNING_DISABLED`   | Kept.                                                                                                           |
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
