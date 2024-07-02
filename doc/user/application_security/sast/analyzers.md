---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# SAST analyzers

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Moved](https://gitlab.com/groups/gitlab-org/-/epics/2098) from GitLab Ultimate to GitLab Free in 13.3.

Static Application Security Testing (SAST) uses analyzers
to detect vulnerabilities in source code. Each analyzer is a wrapper around a [scanner](../terminology/index.md#scanner), a third-party code analysis tool.

The analyzers are published as Docker images that SAST uses to launch dedicated containers for each
analysis. We recommend a minimum of 4 GB RAM to ensure consistent performance of the analyzers.

SAST default images are maintained by GitLab, but you can also integrate your own custom image.

For each scanner, an analyzer:

- Exposes its detection logic.
- Handles its execution.
- Converts its output to a [standard format](../terminology/index.md#secure-report-format).

## Official analyzers

SAST supports the following official analyzers:

- [`kubesec`](https://gitlab.com/gitlab-org/security-products/analyzers/kubesec) (Kubesec)
- [`pmd-apex`](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex) (PMD (Apex only))
- [`semgrep`](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) (Semgrep)
- [`sobelow`](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow) (Sobelow (Elixir Phoenix))
- [`spotbugs`](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs) (SpotBugs with the Find Sec Bugs plugin (Ant, Gradle and wrapper, Grails, Maven and wrapper, SBT))

The following GitLab analyzers have reached [End of Support](../../../update/terminology.md#end-of-support)
status and do not receive updates. They were replaced by the Semgrep-based analyzer with
GitLab-managed rules.

- [`bandit`](https://gitlab.com/gitlab-org/security-products/analyzers/bandit) (Bandit); [End of Support](https://gitlab.com/gitlab-org/gitlab/-/issues/352554) in GitLab 15.4.
- [`brakeman`](https://gitlab.com/gitlab-org/security-products/analyzers/brakeman) (Brakeman); [End of Support](https://gitlab.com/gitlab-org/gitlab/-/issues/412060) in GitLab 17.0.
- [`eslint`](https://gitlab.com/gitlab-org/security-products/analyzers/eslint) (ESLint (JavaScript and React)); [End of Support](https://gitlab.com/gitlab-org/gitlab/-/issues/352554) in GitLab 15.4.
- [`flawfinder`](https://gitlab.com/gitlab-org/security-products/analyzers/flawfinder) (Flawfinder); [End of Support](https://gitlab.com/gitlab-org/gitlab/-/issues/412060) in GitLab 17.0.
- [`gosec`](https://gitlab.com/gitlab-org/security-products/analyzers/gosec) (Gosec); [End of Support](https://gitlab.com/gitlab-org/gitlab/-/issues/352554) in GitLab 15.4.
- [`mobsf`](https://gitlab.com/gitlab-org/security-products/analyzers/mobsf) (MobSF); [End of Support](https://gitlab.com/gitlab-org/gitlab/-/issues/450925) in GitLab 17.0.
- [`nodejs-scan`](https://gitlab.com/gitlab-org/security-products/analyzers/nodejs-scan) (NodeJsScan);  [End of Support](https://gitlab.com/gitlab-org/gitlab/-/issues/412060) in GitLab 17.0.
- [`phpcs-security-audit`](https://gitlab.com/gitlab-org/security-products/analyzers/phpcs-security-audit) (PHP CS security-audit)
- [`security-code-scan`](https://gitlab.com/gitlab-org/security-products/analyzers/security-code-scan) (Security Code Scan (.NET)); [End of Support](https://gitlab.com/gitlab-org/gitlab/-/issues/390416) in GitLab 16.0.

## GitLab Advanced SAST analyzer

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Status:** Experiment

The GitLab Advanced SAST analyzer offers a broader and more accurate static analysis for Python,
particularly by providing cross-function and cross-file taint analysis.

It is not enabled by default. To enable it, please follow the instructions on the [GitLab Advanced SAST page](gitlab_advanced_sast.md).

## SAST analyzer features

For an analyzer to be considered generally available, it is expected to minimally
support the following features:

- [Customizable configuration](index.md#available-cicd-variables)
- [Customizable rulesets](customize_rulesets.md#customize-rulesets)
- [Scan projects](index.md#supported-languages-and-frameworks)
- Multi-project support
- [Offline support](index.md#running-sast-in-an-offline-environment)
- [Output results in JSON report format](index.md#output)
- [SELinux support](index.md#running-sast-in-selinux)

## Post analyzers

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Post analyzers enrich the report output by an analyzer. A post analyzer doesn't modify report
content directly. Instead, it enhances the results with additional properties, including:

- CWEs.
- Location tracking fields.

## Transition to Semgrep-based scanning

SAST includes a [Semgrep-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) that covers [multiple languages](index.md#supported-languages-and-frameworks).
GitLab maintains the analyzer and writes [detection rules](rules.md) for it.
These rules replace language-specific analyzers that were used in previous releases.

### Vulnerability translation

The Vulnerability Management system automatically moves vulnerabilities from the old analyzer to a new Semgrep-based finding when possible.
When this happens, the system combines the vulnerabilities from each analyzer into a single record.

But, vulnerabilities may not match up if:

- The new Semgrep-based rule detects the vulnerability in a different location, or in a different way, than the old analyzer did.
- You previously [disabled SAST analzyers](#disable-specific-default-analyzers).
This can interfere with automatic translation by preventing necessary identifiers from being recorded for each vulnerability.

If a vulnerability doesn't match:

- The original vulnerability is marked as "no longer detected" in the Vulnerability Report.
- A new vulnerability is then created based on the Semgrep-based finding.

## Customize analyzers

Use [CI/CD variables](index.md#available-cicd-variables)
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
