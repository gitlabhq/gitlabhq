---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# SAST analyzers **(FREE)**

> [Moved](https://gitlab.com/groups/gitlab-org/-/epics/2098) from GitLab Ultimate to GitLab Free in 13.3.

Static Application Security Testing (SAST) uses analyzers
to detect vulnerabilities in source code. Each analyzer is a wrapper around a [scanner](../terminology/#scanner), a third-party code analysis tool.

The analyzers are published as Docker images that SAST uses to launch dedicated containers for each
analysis.

SAST default images are maintained by GitLab, but you can also integrate your own custom image.

For each scanner, an analyzer:

- Exposes its detection logic.
- Handles its execution.
- Converts its output to a [standard format](../terminology/#secure-report-format).

## SAST analyzers

SAST supports the following official analyzers:

- [`bandit`](https://gitlab.com/gitlab-org/security-products/analyzers/bandit) (Bandit)
- [`brakeman`](https://gitlab.com/gitlab-org/security-products/analyzers/brakeman) (Brakeman)
- [`eslint`](https://gitlab.com/gitlab-org/security-products/analyzers/eslint) (ESLint (JavaScript and React))
- [`flawfinder`](https://gitlab.com/gitlab-org/security-products/analyzers/flawfinder) (Flawfinder)
- [`gosec`](https://gitlab.com/gitlab-org/security-products/analyzers/gosec) (Gosec)
- [`kubesec`](https://gitlab.com/gitlab-org/security-products/analyzers/kubesec) (Kubesec)
- [`mobsf`](https://gitlab.com/gitlab-org/security-products/analyzers/mobsf) (MobSF (beta))
- [`nodejs-scan`](https://gitlab.com/gitlab-org/security-products/analyzers/nodejs-scan) (NodeJsScan)
- [`phpcs-security-audit`](https://gitlab.com/gitlab-org/security-products/analyzers/phpcs-security-audit) (PHP CS security-audit)
- [`pmd-apex`](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex) (PMD (Apex only))
- [`security-code-scan`](https://gitlab.com/gitlab-org/security-products/analyzers/security-code-scan) (Security Code Scan (.NET))
- [`semgrep`](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) (Semgrep)
- [`sobelow`](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow) (Sobelow (Elixir Phoenix))
- [`spotbugs`](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs) (SpotBugs with the Find Sec Bugs plugin (Ant, Gradle and wrapper, Grails, Maven and wrapper, SBT))

## SAST analyzer features

For an analyzer to be considered Generally Available, it is expected to minimally
support the following features:

- [Customizable configuration](index.md#available-cicd-variables)
- [Customizable rulesets](index.md#customize-rulesets)
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

## Data provided by analyzers

Each analyzer provides data about the vulnerabilities it detects. The following table details the
data available from each analyzer. The values provided by these tools are heterogeneous so they are sometimes
normalized into common values, for example, `severity` and `confidence`.

| Property / tool                | Apex | Bandit | Brakeman | ESLint security | SpotBugs | Flawfinder | Gosec | Kubesec Scanner | MobSF | NodeJsScan | PHP CS Security Audit | Security code Scan (.NET) | Semgrep | Sobelow |
|--------------------------------|------|--------|----------|-----------------|----------|------------|-------|-----------------|-------|------------|-----------------------|---------------------------|---------|---------|
| Affected item (for example, class or package) | ✓ | ✗ | ✓ | ✗               | ✓        | ✓          | ✗     | ✓               | ✗     | ✗          | ✗                     | ✗                         | ✗       | ✗       |
| Confidence                     | ✗    | ✓      | ✓        | ✗               | ✓        | x          | ✓     | ✓               | ✗     | ✗          | ✗                     | ✗                         | ⚠       | ✓       |
| Description                    | ✓    | ✗      | ✗        | ✓               | ✓        | ✗          | ✗     | ✓               | ✓     | ✓          | ✗                     | ✗                         | ✓       | ✓       |
| End column                     | ✓    | ✗      | ✗        | ✓               | ✓        | ✗          | ✗     | ✗               | ✗     | ✗          | ✗                     | ✗                         | ✗       | ✗       |
| End line                       | ✓    | ✓      | ✗        | ✓               | ✓        | ✗          | ✗     | ✗               | ✗     | ✗          | ✗                     | ✗                         | ✗       | ✗       |
| External ID (for example, CVE) | ✗    | ✗      | ⚠        | ✗               | ⚠        | ✓          | ✗     | ✗               | ✗     | ✗          | ✗                     | ✗                         | ⚠       | ✗       |
| File                           | ✓    | ✓      | ✓        | ✓               | ✓        | ✓          | ✓     | ✓               | ✓     | ✓          | ✓                     | ✓                         | ✓       | ✓       |
| Internal doc/explanation       | ✓    | ⚠      | ✓        | ✗               | ✓        | ✗          | ✗     | ✗               | ✗     | ✗          | ✗                     | ✗                         | ✗       | ✓       |
| Internal ID                    | ✓    | ✓      | ✓        | ✓               | ✓        | ✓          | ✓     | ✗               | ✗     | ✗          | ✓                     | ✓                         | ✓       | ✓       |
| Severity                       | ✓    | ✓      | ✓        | ✓               | ✓        | ✓          | ✓     | ✓               | ✓     | ✓          | ✓                     | ✗                         | ⚠       | ✗       |
| Solution                       | ✓    | ✗      | ✗        | ✗               | ⚠        | ✓          | ✗     | ✗               | ✗     | ✗          | ✗                     | ✗                         | ⚠       | ✗       |
| Source code extract            | ✗    | ✓      | ✓        | ✓               | ✗        | ✓          | ✓     | ✗               | ✗     | ✗          | ✗                     | ✗                         | ✗       | ✗       |
| Start column                   | ✓    | ✗      | ✗        | ✓               | ✓        | ✓          | ✓     | ✗               | ✗     | ✗          | ✓                     | ✓                         | ✓       | ✗       |
| Start line                     | ✓    | ✓      | ✓        | ✓               | ✓        | ✓          | ✓     | ✗               | ✓     | ✓          | ✓                     | ✓                         | ✓       | ✓       |
| Title                          | ✓    | ✓      | ✓        | ✓               | ✓        | ✓          | ✓     | ✓               | ✓     | ✓          | ✓                     | ✓                         | ✓       | ✓       |
| URLs                           | ✓    | ✗      | ✓        | ✗               | ⚠        | ✗          | ⚠     | ✗               | ✗     | ✗          | ✗                     | ✗                         | ✗       | ✗       |

- ✓ => Data is available.
- ⚠ => Data is available, but it's partially reliable, or it has to be extracted from unstructured content.
- ✗ => Data is not available or it would require specific, inefficient or unreliable, logic to obtain it.

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

For example, the following instructs SAST to pull `my-docker-registry/gitlab-images/bandit` instead
of `registry.gitlab.com/security-products/bandit`:

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml

variables:
  SECURE_ANALYZERS_PREFIX: my-docker-registry/gitlab-images
```

### Disable all default analyzers

You can disable all default SAST analyzers, leaving only [custom analyzers](#custom-analyzers)
enabled.

To disable all default analyzers, set the CI/CD variable `SAST_DISABLED` to `true` in your
`.gitlab-ci.yml` file.

Example:

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml

variables:
  SAST_DISABLED: true
```

### Disable specific default analyzers

Analyzers are run automatically according to the
source code languages detected. However, you can disable select analyzers.

To disable select analyzers, set the CI/CD variable `SAST_EXCLUDED_ANALYZERS` to a comma-delimited
string listing the analyzers that you want to prevent running.

For example, to disable the `eslint` analyzer:

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml

variables:
  SAST_EXCLUDED_ANALYZERS: "eslint"
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
