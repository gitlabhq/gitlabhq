---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Advanced SAST Swift and Objective-C configuration
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/16318) as a [beta](../../../policy/development_stages_support.md#beta) in GitLab 19.3.
- Incremental scanning [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249721) in GitLab 19.4.

{{< /history >}}

GitLab Advanced SAST analyzes Swift and Objective-C code by using cross-file, cross-function taint
analysis, which extends [GitLab Advanced SAST](gitlab_advanced_sast.md) coverage to iOS
applications.

Swift and Objective-C analysis runs as a separate CI/CD job, `gitlab-advanced-sast-ext`, that ships
as its own container image. No additional configuration is required. When GitLab Advanced SAST is
turned on, the job runs if the repository contains Swift (`.swift`), Objective-C (`.m`), or
Objective-C++ (`.mm`) files.

## Turn on GitLab Advanced SAST Swift and Objective-C analysis

Prerequisites:

- [Turn on GitLab Advanced SAST](gitlab_advanced_sast.md#turn-on-gitlab-advanced-sast).

Swift and Objective-C analysis uses the same enablement variable as the other supported languages:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  GITLAB_ADVANCED_SAST_ENABLED: "true"
```

When this variable is set and the repository contains Swift or Objective-C files, GitLab adds the
`gitlab-advanced-sast-ext` job to the `test` stage of the pipeline.

## Turn off GitLab Advanced SAST Swift and Objective-C analysis

To turn off Swift and Objective-C analysis while keeping GitLab Advanced SAST turned on for other
languages, add `gitlab-advanced-sast-ext` to the `SAST_EXCLUDED_ANALYZERS` variable:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  GITLAB_ADVANCED_SAST_ENABLED: "true"
  SAST_EXCLUDED_ANALYZERS: "gitlab-advanced-sast-ext"
```

To turn off GitLab Advanced SAST entirely, including Swift and Objective-C analysis, set
`GITLAB_ADVANCED_SAST_ENABLED` to `"false"`.

If `GITLAB_ADVANCED_SAST_ENABLED` is set as a group CI/CD variable, a value in the project's
`.gitlab-ci.yml` file does not override it. To override a group variable, define a project CI/CD
variable with the same name. For more information, see
[CI/CD variable precedence](../../../ci/variables/_index.md#cicd-variable-precedence).

## Incremental scanning

Incremental scanning is turned on by default. The analyzer caches its taint analysis store between
pipeline runs, then re-analyzes only the files whose code changed or dependencies changed,
and reuses cached results for unchanged code.
This reduces scan times on large codebases where most code doesn't change
between commits.

For the other GitLab Advanced SAST languages, the equivalent feature is
[incremental scanning](gitlab_advanced_sast.md#incremental-scanning), which is turned off by default
and configured with different CI/CD variables.

The `gitlab-advanced-sast-ext` job carries the store across pipelines by using the job's `cache:`,
keyed by the branch with a fallback to the default branch.

Cache reuse requires the runner to have access to the previous cache.
If your instance uses multiple runners without [distributed caching](https://docs.gitlab.com/runner/configuration/autoscale/#distributed-runners-caching),
the store might not be available and the analyzer performs a full scan.

### Turn off incremental scanning

To turn off incremental scanning and scan all code on every run, set the `GITLAB_ADVANCED_SAST_EXT_INCREMENTAL_ENABLED` variable
to `"false"`:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  GITLAB_ADVANCED_SAST_ENABLED: "true"
  GITLAB_ADVANCED_SAST_EXT_INCREMENTAL_ENABLED: "false"
```

### Disable the cache

Turning off incremental scanning keeps the `cache:` active, so every pipeline still uploads and
downloads the store.
The store stays primed, so you can re-enable incremental scanning and reuse it immediately.

To also remove the cache cost from every pipeline, override the job with an empty `cache:`:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  GITLAB_ADVANCED_SAST_ENABLED: "true"

gitlab-advanced-sast-ext:
  cache: []
```

With the cache disabled, every pipeline runs a full scan and pays no cache cost.
Re-enabling incremental scanning then requires one full scan to prime the store again.

## Vulnerability coverage

The analyzer traces untrusted input from sources to vulnerable sinks across files and functions.
In addition to general weakness types such as SQL injection and cleartext transmission of
sensitive information, it models iOS-specific APIs and data flows, including:

- Deep links and custom URL schemes as untrusted input sources.
- Keychain item accessibility classes.
- Storage of sensitive data in `UserDefaults`, the pasteboard, and local files.
- WebKit and UIWebView content loading.

For the complete list of weakness types the analyzer detects, see
[Swift and Objective-C CWE coverage](advanced_sast_coverage.md#swift-and-objective-c-cwe-coverage).

## FIPS pipelines

A FIPS-enabled image is not available for Swift and Objective-C analysis during the beta. As with
the other analyzers, a FIPS-compliant image is available only for GitLab Advanced SAST and the
Semgrep-based analyzer.

In pipelines that use [FIPS-enabled images](_index.md#fips-enabled-images), the
`gitlab-advanced-sast-ext` job still runs, and fails because it cannot pull a FIPS-enabled image.
To use SAST in a FIPS-compliant manner,
[turn off Swift and Objective-C analysis](#turn-off-gitlab-advanced-sast-swift-and-objective-c-analysis).

## Known issues

During the beta, Swift and Objective-C analysis has the following known issues:

- [Offline environments](../offline_deployments/_index.md) are not supported.
- Findings are not deduplicated against findings from the Semgrep-based SAST analyzer. When both
  analyzers detect the same vulnerability in a Swift or Objective-C file, both findings are
  reported.
- [Custom rulesets](customize_rulesets.md) are not supported.
- [Diff-based scanning](gitlab_advanced_sast.md#diff-based-scanning) is not supported.
