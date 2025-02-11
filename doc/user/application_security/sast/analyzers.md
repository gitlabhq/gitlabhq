---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SAST analyzers
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Moved](https://gitlab.com/groups/gitlab-org/-/epics/2098) from GitLab Ultimate to GitLab Free in 13.3.

Static Application Security Testing (SAST) uses analyzers
to detect vulnerabilities in source code. Each analyzer is a wrapper around a [scanner](../terminology/_index.md#scanner), a third-party code analysis tool.

The analyzers are published as Docker images that SAST uses to launch dedicated containers for each
analysis. We recommend a minimum of 4 GB RAM to ensure consistent performance of the analyzers.

SAST default images are maintained by GitLab, but you can also integrate your own custom image.

For each scanner, an analyzer:

- Exposes its detection logic.
- Handles its execution.
- Converts its output to a [standard format](../terminology/_index.md#secure-report-format).

## Official analyzers

SAST supports the following official analyzers:

- [`gitlab-advanced-sast`](gitlab_advanced_sast.md), providing cross-file and cross-function taint analysis and improved detection accuracy. Ultimate only.
- [`kubesec`](https://gitlab.com/gitlab-org/security-products/analyzers/kubesec), based on Kubesec. Off by default; see [Enabling KubeSec analyzer](_index.md#enabling-kubesec-analyzer).
- [`pmd-apex`](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex), based on PMD with rules for the Apex language.
- [`semgrep`](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep), based on the Semgrep OSS engine [with GitLab-managed rules](rules.md#semgrep-based-analyzer).
- [`sobelow`](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow), based on Sobelow.
- [`spotbugs`](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs), based on SpotBugs with the Find Sec Bugs plugin (Ant, Gradle and wrapper, Grails, Maven and wrapper, SBT).

### Supported versions

Official analyzers are released as container images, separate from the GitLab platform.
Each analyzer version is compatible with a limited set of GitLab versions.

When an analyzer version will no longer be supported in a future GitLab version, this change is announced in advance.
For example, see the [announcement for GitLab 17.0](../../../update/deprecations.md#secure-analyzers-major-version-update).

The supported major version for each official analyzer is reflected in its job definition in the [SAST CI/CD template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml).
To see the analyzer version supported in a previous GitLab version, select a historical version of the SAST template file, such as [v16.11.0-ee](https://gitlab.com/gitlab-org/gitlab/-/blob/v16.11.0-ee/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml?ref_type=tags) for GitLab 16.11.0.

## Analyzers that have reached End of Support

The following GitLab analyzers have reached [End of Support](../../../update/terminology.md#end-of-support)
status and do not receive updates. They were replaced by the Semgrep-based analyzer [with GitLab-managed rules](rules.md#semgrep-based-analyzer).

After you upgrade to GitLab 17.3.1 or later, a one-time data migration [automatically resolves](_index.md#automatic-vulnerability-resolution) findings from the analyzers that reached End of Support.
This includes all of the analyzers listed below except for SpotBugs, because SpotBugs still scans Groovy code.
The migration only resolves vulnerabilities that you haven't confirmed or dismissed, and it doesn't affect vulnerabilities that were [automatically translated to Semgrep-based scanning](#transition-to-semgrep-based-scanning).
For details, see [issue 444926](https://gitlab.com/gitlab-org/gitlab/-/issues/444926).

| Analyzer                                                                                                   | Languages scanned                                                                      | End Of Support GitLab version                                                                 |
|------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| [Bandit](https://gitlab.com/gitlab-org/security-products/analyzers/bandit)                                 | Python                                                                                 | [15.4](../../../update/deprecations.md#sast-analyzer-consolidation-and-cicd-template-changes) |
| [Brakeman](https://gitlab.com/gitlab-org/security-products/analyzers/brakeman)                             | Ruby, including Ruby on Rails                                                          | [17.0](../../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-170)         |
| [ESLint](https://gitlab.com/gitlab-org/security-products/analyzers/eslint) with React and Security plugins | JavaScript and TypeScript, including React                                             | [15.4](../../../update/deprecations.md#sast-analyzer-consolidation-and-cicd-template-changes) |
| [Flawfinder](https://gitlab.com/gitlab-org/security-products/analyzers/flawfinder)                         | C, C++                                                                                 | [17.0](../../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-170)         |
| [gosec](https://gitlab.com/gitlab-org/security-products/analyzers/gosec)                                   | Go                                                                                     | [15.4](../../../update/deprecations.md#sast-analyzer-consolidation-and-cicd-template-changes) |
| [MobSF](https://gitlab.com/gitlab-org/security-products/analyzers/mobsf)                                   | Java and Kotlin, for Android applications only; Objective-C, for iOS applications only | [17.0](../../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-170)         |
| [NodeJsScan](https://gitlab.com/gitlab-org/security-products/analyzers/nodejs-scan)                        | JavaScript (Node.js only)                                                              | [17.0](../../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-170)         |
| [phpcs-security-audit](https://gitlab.com/gitlab-org/security-products/analyzers/phpcs-security-audit)     | PHP                                                                                    | [17.0](../../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-170)         |
| [Security Code Scan](https://gitlab.com/gitlab-org/security-products/analyzers/security-code-scan)         | .NET (including C#, Visual Basic)                                                      | [16.0](../../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-160)         |
| [SpotBugs](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs)                             | Java only<sup>1</sup>                                                                  | [15.4](../../../update/deprecations.md#sast-analyzer-consolidation-and-cicd-template-changes) |
| [SpotBugs](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs)                             | Kotlin and Scala only<sup>1</sup>                                                      | [17.0](../../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-170)         |

Footnotes:

1. SpotBugs remains a [supported analyzer](_index.md#supported-languages-and-frameworks) for Groovy. It only activates when Groovy code is detected.

## SAST analyzer features

For an analyzer to be considered generally available, it is expected to minimally
support the following features:

- [Customizable configuration](_index.md#available-cicd-variables)
- [Customizable rulesets](customize_rulesets.md)
- [Scan projects](_index.md#supported-languages-and-frameworks)
- Multi-project support
- [Offline support](_index.md#running-sast-in-an-offline-environment)
- [Output results in JSON report format](_index.md#download-a-sast-report)
- [SELinux support](_index.md#running-sast-in-selinux)

## Post analyzers

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Post analyzers enrich the report output by an analyzer. A post analyzer doesn't modify report
content directly. Instead, it enhances the results with additional properties, including:

- CWEs.
- Location tracking fields.

## Transition to Semgrep-based scanning

In addition to the [GitLab Advanced SAST analyzer](gitlab_advanced_sast.md), GitLab also provides a [Semgrep-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) that covers [multiple languages](_index.md#supported-languages-and-frameworks).
GitLab maintains the analyzer and writes [detection rules](rules.md) for it.
These rules replace language-specific analyzers that were used in previous releases.

### Vulnerability translation

The Vulnerability Management system automatically moves vulnerabilities from the old analyzer to a new Semgrep-based finding when possible. For translation to the GitLab Advanced SAST analyzer, please refer to the [GitLab Advanced SAST documentation](gitlab_advanced_sast.md).

When this happens, the system combines the vulnerabilities from each analyzer into a single record.

But, vulnerabilities may not match up if:

- The new Semgrep-based rule detects the vulnerability in a different location, or in a different way, than the old analyzer did.
- You previously [disabled SAST analyzers](#disable-specific-default-analyzers).
This can interfere with automatic translation by preventing necessary identifiers from being recorded for each vulnerability.

If a vulnerability doesn't match:

- The original vulnerability is marked as "no longer detected" in the Vulnerability Report.
- A new vulnerability is then created based on the Semgrep-based finding.

## Customize analyzers

Use [CI/CD variables](_index.md#available-cicd-variables)
in your `.gitlab-ci.yml` file to customize the behavior of your analyzers.

### Use a custom Docker mirror

You can use a custom Docker registry, instead of the GitLab registry, to host the analyzers' images.

Prerequisites:

- The custom Docker registry must provide images for all the official analyzers.

NOTE:
This variable affects all Secure analyzers, not just the analyzers for SAST.

To have GitLab download the analyzers' images from a custom Docker registry, define the prefix with
the `SECURE_ANALYZERS_PREFIX` CI/CD variable.

For example, the following instructs SAST to pull `my-docker-registry/gitlab-images/semgrep` instead
of `registry.gitlab.com/security-products/semgrep`:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SECURE_ANALYZERS_PREFIX: my-docker-registry/gitlab-images
```

### Disable all default analyzers

You can disable all default SAST analyzers, leaving only [custom analyzers](#custom-analyzers)
enabled.

To disable all default analyzers, set the CI/CD variable `SAST_DISABLED` to `"true"` in your
`.gitlab-ci.yml` file.

Example:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SAST_DISABLED: "true"
```

### Disable specific default analyzers

Analyzers are run automatically according to the
source code languages detected. However, you can disable select analyzers.

To disable select analyzers, set the CI/CD variable `SAST_EXCLUDED_ANALYZERS` to a comma-delimited
string listing the analyzers that you want to prevent running.

For example, to disable the `spotbugs` analyzer:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SAST_EXCLUDED_ANALYZERS: "spotbugs"
```

### Custom analyzers

You can provide your own analyzers by defining jobs in your CI/CD configuration. For
consistency with the default analyzers, you should add the suffix `-sast` to your custom
SAST jobs.

For more details on integrating a custom security scanner into GitLab, see [Security Scanner Integration](../../../development/integrations/secure.md).

#### Example custom analyzer

This example shows how to add a scanning job that's based on the Docker image
`my-docker-registry/analyzers/csharp`. It runs the script `/analyzer run` and outputs a SAST report
`gl-sast-report.json`.

Define the following in your `.gitlab-ci.yml` file:

```yaml
csharp-sast:
  image:
    name: "my-docker-registry/analyzers/csharp"
  script:
    - /analyzer run
  artifacts:
    reports:
      sast: gl-sast-report.json
```
