---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# SAST analyzers **(FREE)**

> [Moved](https://gitlab.com/groups/gitlab-org/-/epics/2098) from GitLab Ultimate to GitLab Free in 13.3.

Static Application Security Testing (SAST) uses analyzers
to detect vulnerabilities in source code. Each analyzer is a wrapper around a [scanner](../terminology/index.md#scanner), a third-party code analysis tool.

The analyzers are published as Docker images that SAST uses to launch dedicated containers for each
analysis. We recommend a minimum of 4 GB RAM to ensure consistent performance of the analyzers.

SAST default images are maintained by GitLab, but you can also integrate your own custom image.

For each scanner, an analyzer:

- Exposes its detection logic.
- Handles its execution.
- Converts its output to a [standard format](../terminology/index.md#secure-report-format).

## SAST analyzers

SAST supports the following official analyzers:

- [`brakeman`](https://gitlab.com/gitlab-org/security-products/analyzers/brakeman) (Brakeman)
- [`flawfinder`](https://gitlab.com/gitlab-org/security-products/analyzers/flawfinder) (Flawfinder)
- [`kubesec`](https://gitlab.com/gitlab-org/security-products/analyzers/kubesec) (Kubesec)
- [`mobsf`](https://gitlab.com/gitlab-org/security-products/analyzers/mobsf) (MobSF (beta))
- [`nodejs-scan`](https://gitlab.com/gitlab-org/security-products/analyzers/nodejs-scan) (NodeJsScan)
- [`phpcs-security-audit`](https://gitlab.com/gitlab-org/security-products/analyzers/phpcs-security-audit) (PHP CS security-audit)
- [`pmd-apex`](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex) (PMD (Apex only))
- [`semgrep`](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) (Semgrep)
- [`sobelow`](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow) (Sobelow (Elixir Phoenix))
- [`spotbugs`](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs) (SpotBugs with the Find Sec Bugs plugin (Ant, Gradle and wrapper, Grails, Maven and wrapper, SBT))

SAST has used other analyzers in previous versions. These analyzers reached End of Support status and do not receive updates:

- [`bandit`](https://gitlab.com/gitlab-org/security-products/analyzers/bandit) (Bandit); [End of Support](https://gitlab.com/gitlab-org/gitlab/-/issues/352554) in GitLab 15.4. Replaced by the `semgrep` analyzer with GitLab-managed rules.
- [`eslint`](https://gitlab.com/gitlab-org/security-products/analyzers/eslint) (ESLint (JavaScript and React)); [End of Support](https://gitlab.com/gitlab-org/gitlab/-/issues/352554) in GitLab 15.4. Replaced by the `semgrep` analyzer with GitLab-managed rules.
- [`gosec`](https://gitlab.com/gitlab-org/security-products/analyzers/gosec) (Gosec); [End of Support](https://gitlab.com/gitlab-org/gitlab/-/issues/352554) in GitLab 15.4. Replaced by the `semgrep` analyzer with GitLab-managed rules.
- [`security-code-scan`](https://gitlab.com/gitlab-org/security-products/analyzers/security-code-scan) (Security Code Scan (.NET)); [End of Support](https://gitlab.com/gitlab-org/gitlab/-/issues/390416) in GitLab 16.0. Replaced by the `semgrep` analyzer with GitLab-managed rules.

## SAST analyzer features

For an analyzer to be considered Generally Available, it is expected to minimally
support the following features:

- [Customizable configuration](index.md#available-cicd-variables)
- [Customizable rulesets](customize_rulesets.md#customize-rulesets)
- [Scan projects](index.md#supported-languages-and-frameworks)
- [Multi-project support](index.md#multi-project-support)
- [Offline support](index.md#running-sast-in-an-offline-environment)
- [Emits JSON report format](index.md#reports-json-format)
- [SELinux support](index.md#running-sast-in-selinux)

## Post analyzers

Post analyzers enrich the report output by an analyzer. A post analyzer doesn't modify report
content directly. Instead, it enhances the results with additional properties, including:

- CWEs.
- Location tracking fields.
- A means of identifying false positives or insignificant findings. **(ULTIMATE)**

## Transition to Semgrep-based scanning

SAST includes a [Semgrep-based analyzer](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) that covers [multiple languages](index.md#supported-languages-and-frameworks).
GitLab maintains the analyzer and writes detection rules for it.

If you use the [GitLab-managed CI/CD template](index.md#configuration), the Semgrep-based analyzer operates alongside other language-specific analyzers.
It runs with GitLab-managed detection rules that mimic the other analyzers' detection rules.
Work to remove language-specific analyzers and replace them with the Semgrep-based analyzer is tracked in [epic 5245](https://gitlab.com/groups/gitlab-org/-/epics/5245). In case of duplicate findings, the [analyzer order](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/reports/security/scanner.rb#L15) determines which analyzer's findings are preferred.

You can choose to disable the other analyzers early and use Semgrep-based scanning for supported languages before the default behavior changes. If you do so:

- You enjoy significantly faster scanning, reduced CI minutes usage, and more customizable scanning rules.
- However, vulnerabilities previously reported by language-specific analyzers are reported again under certain conditions, including if you've dismissed the vulnerabilities before. The system behavior depends on:
  - whether you've excluded the Semgrep-based analyzer from running in the past.
  - which analyzer first discovered the vulnerabilities shown in the project's [Vulnerability Report](../vulnerability_report/index.md).

### Vulnerability translation

When you switch analyzers for a language, vulnerabilities may not match up.

The Vulnerability Management system automatically moves vulnerabilities from the old analyzer to Semgrep for certain languages:

- For C, a vulnerability is moved if it has only ever been detected by Flawfinder in pipelines where Semgrep also detected it. Semgrep coverage for C was introduced by default into the CI/CD template in GitLab 14.4 (October 2021).
- For Go, a vulnerability is moved if it has only ever been detected by Gosec in pipelines where Semgrep also detected it. Semgrep coverage for Go was introduced by default into the CI/CD template in GitLab 14.2 (August 2021).
- For JavaScript and TypeScript, a vulnerability is moved if it has only ever been detected by ESLint in pipelines where Semgrep also detected it. Semgrep coverage for these languages was introduced into the CI/CD template in GitLab 13.12 (May 2021).

However, old vulnerabilities re-created based on Semgrep results are visible if:

- A vulnerability was created by Bandit or SpotBugs and you disable those analyzers. We only recommend disabling Bandit and SpotBugs now if the analyzers aren't working. Work to automatically translate Bandit and SpotBugs vulnerabilities to Semgrep is tracked in [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/328062).
- A vulnerability was created by ESLint, Gosec, or Flawfinder in a default-branch pipeline where Semgrep scanning did not run successfully (before Semgrep coverage was introduced for the language, because you disabled Semgrep explicitly, or because the Semgrep scan failed in that pipeline). We do not currently plan to combine these vulnerabilities if they already exist.

When a vulnerability is re-created, the original vulnerability is marked as "no longer detected" in the Vulnerability Report.
A new vulnerability is then created based on the Semgrep finding.

### Activating Semgrep-based scanning early

You can choose to use Semgrep-based scanning instead of language-specific analyzers before the default behavior changes.

We recommend taking this approach if any of these cases applies:

- You haven't used SAST before on a project, so you don't already have SAST vulnerabilities in your [Vulnerability Report](../vulnerability_report/index.md).
- You're having trouble configuring one of the analyzers whose coverage overlaps with Semgrep-based coverage. For example, you might have trouble setting up the SpotBugs-based analyzer to compile your code.
- You've already seen and dismissed vulnerabilities created by ESLint, Gosec, or Flawfinder scanning, and you've kept the re-created vulnerabilities created by Semgrep.

You can make a separate choice for each of the language-specific analyzers, or you can disable them all.

#### Activate Semgrep-based scanning

To switch to Semgrep-based scanning early, you can:

1. Create a merge request (MR) to set the [`SAST_EXCLUDED_ANALYZERS` CI/CD variable](#disable-specific-default-analyzers) to `"bandit,gosec,eslint"`.
    - If you also want to disable SpotBugs scanning, add `spotbugs` to the list. We only recommend this for Java projects. SpotBugs is the only current analyzer that can scan Groovy, Kotlin, and Scala.
    - If you also want to disable Flawfinder scanning, add `flawfinder` to the list. We only recommend this for C projects. Flawfinder is the only current analyzer that can scan C++.
1. Verify that scanning jobs succeed in the MR. Findings from the removed analyzers are available in _Fixed_ and findings from Semgrep in _New_. (Some findings may show different names, descriptions, and severities, since GitLab manages and edits the Semgrep rulesets.)
1. Merge the MR and wait for the default-branch pipeline to run.
1. Use the Vulnerability Report to dismiss the findings that are no longer detected by the language-specific analyzers.

#### Preview Semgrep-based scanning

You can see how Semgrep-based scanning works in your projects before the GitLab-managed Stable CI/CD template for SAST is updated.
We recommend that you test this change in a merge request but continue using the Stable template in your default branch pipeline configuration.

In GitLab 15.3, we [activated a feature flag](https://gitlab.com/gitlab-org/gitlab/-/issues/362179) to migrate security findings on the default branch from other analyzers to Semgrep.
In GitLab 15.4, we [removed the deprecated analyzers](https://gitlab.com/gitlab-org/gitlab/-/issues/352554) from the Stable CI/CD template.

To preview the upcoming changes to the CI/CD configuration in GitLab 15.3 or earlier:

1. Open an MR to switch from the Stable CI/CD template, `SAST.gitlab-ci.yaml`, to [the Latest template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.latest.gitlab-ci.yml), `SAST.latest.gitlab-ci.yaml`.
    - On GitLab.com, use the latest template directly:

      ```yaml
      include:
        template: 'Jobs/SAST.latest.gitlab-ci.yaml'
      ```

    - On a Self-Managed instance, download the template from GitLab.com:

      ```yaml
      include:
        remote: 'https://gitlab.com/gitlab-org/gitlab/-/raw/2851f4d5/lib/gitlab/ci/templates/Jobs/SAST.latest.gitlab-ci.yml'
      ```

1. Verify that scanning jobs succeed in the MR. You notice findings from the removed analyzers in _Fixed_ and findings from Semgrep in _New_. (Some findings may show different names, descriptions, and severities, since GitLab manages and edits the Semgrep rulesets.)
1. Close the MR.

For more information about Stable and Latest templates, see [CI/CD template versioning](../../../development/cicd/templates.md#versioning).

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
  - template: Security/SAST.gitlab-ci.yml

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
  - template: Security/SAST.gitlab-ci.yml

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
  - template: Security/SAST.gitlab-ci.yml

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

## Data provided by analyzers

Each analyzer provides data about the vulnerabilities it detects. The following table details the
data available from each analyzer. The values provided by these tools are heterogeneous so they are sometimes
normalized into common values, for example, `severity` and `confidence`.

| Property / tool                | Apex | Bandit<sup>1</sup> | Brakeman | ESLint security<sup>1</sup> | SpotBugs | Flawfinder | Gosec<sup>1</sup> | Kubesec Scanner | MobSF | NodeJsScan | PHP CS Security Audit | Security code Scan (.NET)<sup>1</sup> | Semgrep | Sobelow |
|--------------------------------|------|--------|----------|-----------------|----------|------------|-------|-----------------|-------|------------|-----------------------|---------------------------|---------|---------|
| Affected item (for example, class or package) | ✓ | ✗ | ✓ | ✗               | ✓        | ✓          | ✗     | ✓               | ✗     | ✗          | ✗                     | ✗                         | ✗       | ✗       |
| Confidence                     | ✗    | ✓                  | ✓        | ✗                           | ✓        | x          | ✓                 | ✓               | ✗     | ✗          | ✗                     | ✗                         | ⚠       | ✓       |
| Description                    | ✓    | ✗                  | ✗        | ✓                           | ✓        | ✗          | ✗                 | ✓               | ✓     | ✓          | ✗                     | ✗                         | ✓       | ✓       |
| End column                     | ✓    | ✗                  | ✗        | ✓                           | ✓        | ✗          | ✗                 | ✗               | ✗     | ✗          | ✗                     | ✗                         | ✗       | ✗       |
| End line                       | ✓    | ✓                  | ✗        | ✓                           | ✓        | ✗          | ✗                 | ✗               | ✗     | ✗          | ✗                     | ✗                         | ✗       | ✗       |
| External ID (for example, CVE) | ✗    | ✗                  | ⚠        | ✗                           | ⚠        | ✓          | ✗                 | ✗               | ✗     | ✗          | ✗                     | ✗                         | ⚠       | ✗       |
| File                           | ✓    | ✓                  | ✓        | ✓                           | ✓        | ✓          | ✓                 | ✓               | ✓     | ✓          | ✓                     | ✓                         | ✓       | ✓       |
| Internal doc/explanation       | ✓    | ⚠                  | ✓        | ✗                           | ✓        | ✗          | ✗                 | ✗               | ✗     | ✗          | ✗                     | ✗                         | ✗       | ✓       |
| Internal ID                    | ✓    | ✓                  | ✓        | ✓                           | ✓        | ✓          | ✓                 | ✗               | ✗     | ✗          | ✓                     | ✓                         | ✓       | ✓       |
| Severity                       | ✓    | ✓                  | ✓        | ✓                           | ✓        | ✓          | ✓                 | ✓               | ✓     | ✓          | ✓                     | ✗                         | ⚠       | ✗       |
| Solution                       | ✓    | ✗                  | ✗        | ✗                           | ⚠        | ✓          | ✗                 | ✗               | ✗     | ✗          | ✗                     | ✗                         | ⚠       | ✗       |
| Source code extract            | ✗    | ✓                  | ✓        | ✓                           | ✗        | ✓          | ✓                 | ✗               | ✗     | ✗          | ✗                     | ✗                         | ✗       | ✗       |
| Start column                   | ✓    | ✗                  | ✗        | ✓                           | ✓        | ✓          | ✓                 | ✗               | ✗     | ✗          | ✓                     | ✓                         | ✓       | ✗       |
| Start line                     | ✓    | ✓                  | ✓        | ✓                           | ✓        | ✓          | ✓                 | ✗               | ✓     | ✓          | ✓                     | ✓                         | ✓       | ✓       |
| Title                          | ✓    | ✓                  | ✓        | ✓                           | ✓        | ✓          | ✓                 | ✓               | ✓     | ✓          | ✓                     | ✓                         | ✓       | ✓       |
| URLs                           | ✓    | ✗                  | ✓        | ✗                           | ⚠        | ✗          | ⚠                 | ✗               | ✗     | ✗          | ✗                     | ✗                         | ✗       | ✗       |

- ✓ => Data is available.
- ⚠ => Data is available, but it's partially reliable, or it has to be extracted from unstructured content.
- ✗ => Data is not available or it would require specific, inefficient or unreliable, logic to obtain it.

1. This analyzer has reached [End of Support](https://about.gitlab.com/handbook/product/gitlab-the-product/#end-of-support). For more information, see the [SAST analyzers](#sast-analyzers) section.
