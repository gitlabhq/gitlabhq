---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# SAST Analyzers **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/3775) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.3.
> - [Moved](https://gitlab.com/groups/gitlab-org/-/epics/2098) to GitLab Free in 13.3.

SAST relies on underlying third party tools that are wrapped into what we call
"Analyzers". An analyzer is a
[dedicated project](https://gitlab.com/gitlab-org/security-products/analyzers)
that wraps a particular tool to:

- Expose its detection logic.
- Handle its execution.
- Convert its output to the common format.

This is achieved by implementing the [common API](https://gitlab.com/gitlab-org/security-products/analyzers/common).

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

The analyzers are published as Docker images that SAST uses to launch
dedicated containers for each analysis.

SAST is pre-configured with a set of **default images** that are maintained by
GitLab, but users can also integrate their own **custom images**.

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

## Official default analyzers

Any custom change to the official analyzers can be achieved by using a
[CI/CD variable in your `.gitlab-ci.yml`](index.md#customizing-the-sast-settings).

### Using a custom Docker mirror

You can switch to a custom Docker registry that provides the official analyzer
images under a different prefix. For instance, the following instructs
SAST to pull `my-docker-registry/gl-images/bandit`
instead of `registry.gitlab.com/gitlab-org/security-products/analyzers/bandit`.
In `.gitlab-ci.yml` define:

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml

variables:
  SECURE_ANALYZERS_PREFIX: my-docker-registry/gl-images
```

This configuration requires that your custom registry provides images for all
the official analyzers.

### Disabling all default analyzers

Setting `SAST_DISABLED` to `true` disables all the official
default analyzers. In `.gitlab-ci.yml` define:

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml

variables:
  SAST_DISABLED: true
```

That's needed when one totally relies on [custom analyzers](#custom-analyzers).

### Disabling specific default analyzers

Set `SAST_EXCLUDED_ANALYZERS` to a comma-delimited string that includes the official
default analyzers that you want to avoid running. In `.gitlab-ci.yml` define the
following to prevent the `eslint` analyzer from running:

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml

variables:
  SAST_EXCLUDED_ANALYZERS: "eslint"
```

## Post Analyzers **(ULTIMATE)**

While analyzers are thin wrappers for executing scanners, post analyzers work to
enrich the data generated within our reports.

GitLab SAST post analyzers never modify report contents directly but work by
augmenting results with additional properties (such as CWEs), location tracking fields,
and a means of identifying false positives or insignificant findings.

The implementation of post analyzers is determined by feature availability tiers, where
simple data enrichment may occur within our free tier and most advanced processing is split
into separate binaries or pipeline jobs.

## Custom Analyzers

You can provide your own analyzers by
defining CI jobs in your CI configuration. For consistency, you should suffix your custom
SAST jobs with `-sast`. Here's how to add a scanning job that's based on the
Docker image `my-docker-registry/analyzers/csharp` and generates a SAST report
`gl-sast-report.json` when `/analyzer run` is executed. Define the following in
`.gitlab-ci.yml`:

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

The [Security Scanner Integration](../../../development/integrations/secure.md) documentation explains how to integrate custom security scanners into GitLab.

## Analyzers Data

| Property / Tool                | Apex | Bandit | Brakeman | ESLint security | SpotBugs | Flawfinder | Gosec | Kubesec Scanner | MobSF | NodeJsScan | PHP CS Security Audit | Security code Scan (.NET) | Semgrep | Sobelow |
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

- ✓ => we have that data
- ⚠ => we have that data but it's partially reliable, or we need to extract it from unstructured content
- ✗ => we don't have that data or it would need to develop specific or inefficient/unreliable logic to obtain it.

The values provided by these tools are heterogeneous so they are sometimes
normalized into common values (for example, `severity`, `confidence`, and so on).
