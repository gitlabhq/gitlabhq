---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Secret Scanning for Source Code
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- Introduced as an [experiment](../../../../policy/development_stages_support.md) in GitLab 19.0.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240774) from experiment to beta in GitLab 19.3.

{{< /history >}}

GitLab Secret Scanning for Source Code is an alternative analyzer for
[pipeline secret detection](../pipeline/_index.md). It runs in the same `secret_detection` CI/CD job
as the default analyzer, but provides additional capabilities, including detection of generic
secrets and false positive reduction.

## How GitLab Secret Scanning for Source Code differs

The analyzer uses a proprietary scan engine developed by GitLab. Instead of relying on
traditional pattern matching techniques, it uses heuristics to detect unstructured secrets and passwords beyond the
[standard GitLab Secret Detection rules](../detected_secrets.md). It combines multiple heuristic techniques to reduce
false positives.

During beta, the analyzer provides:

- Generic secret detection: Identifies unstructured secrets and passwords, including contextual secrets beyond the standard GitLab Secret Detection rule coverage.
- False positive reduction: Combines multiple heuristic techniques to evaluate both the secret and its surrounding context to reduce noise in scan results.
- Encoded secret detection: Detects secrets that are encoded rather than stored in plain text. Supports base64-encoded strings.

## Turn on the analyzer

Prerequisites:

- You have a Linux-based runner with the [`docker`](https://docs.gitlab.com/runner/executors/docker/) or
  [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes/) executor.
  If you use hosted runners for GitLab.com, this is enabled by default.
  - Windows runners are not supported.
  - Only `arm64` and `amd64` CPU architectures are supported.
- You have a `.gitlab-ci.yml` file that includes the `test` stage.

To turn on the analyzer, use the latest secret detection template and set the
`SECRET_DETECTION_ENABLE_GSS` CI/CD variable to `true`:

```yaml
include:
  - template: Jobs/Secret-Detection.latest.gitlab-ci.yml

secret_detection:
  variables:
    SECRET_DETECTION_ENABLE_GSS: "true"
```

> [!note]
> The analyzer reports only high-confidence findings. Medium- and low-confidence findings
> are intentionally filtered out to minimize noise in the vulnerability report. If an
> expected secret doesn't appear in the results, it was likely flagged at medium or low confidence.
> This behavior remains until the analyzer supports configuring the confidence level for scans
> and the vulnerability report UI supports filtering findings by confidence level. To review the
> suppressed findings in the meantime, see [view findings suppressed by confidence threshold](#view-findings-suppressed-by-confidence-threshold).

### Run the analyzer for the first time

The first time you run GitLab Secret Scanning for Source Code, you should run a historic scan. The
analyzer scans all commits and updates the vulnerability report with the most recent findings,
including taking over existing findings from [pipeline secret detection](../pipeline/_index.md).

To run a historic scan:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Build** > **Pipelines**.
1. Select **New pipeline**.
1. Add a CI/CD variable:
   1. From the dropdown list, select **Variable**.
   1. In the **Input variable key** box, enter `SECRET_DETECTION_HISTORIC_SCAN`.
   1. In the **Input variable value** box, enter `true`.
1. Select **New pipeline**.

If you set `SECRET_DETECTION_HISTORIC_SCAN` to `true` in your `.gitlab-ci.yml` file instead, remove
the variable after the scan completes. Otherwise, every pipeline scans the full repository history.

## Default configuration

When you turn on the analyzer, it runs with the following configuration:

| Setting | Default | How to change |
|---------|---------|---------------|
| Generic secret detection | On | Set `SECRET_DETECTION_GSS_ENABLE_GENERIC_SECRETS` to `false`. See [generic secrets](#generic-secrets). |
| False positive reduction | On | Not configurable. |
| Rules | The default GitLab Secret Detection ruleset | See [customize rules](#customize-rules). |

## Generic secrets

When the analyzer is turned on, generic secret detection is on by default.

To turn off generic secret detection, set the `SECRET_DETECTION_GSS_ENABLE_GENERIC_SECRETS` CI/CD
variable to `false`:

```yaml
include:
  - template: Jobs/Secret-Detection.latest.gitlab-ci.yml

secret_detection:
  variables:
    SECRET_DETECTION_ENABLE_GSS: "true"
    SECRET_DETECTION_GSS_ENABLE_GENERIC_SECRETS: "false"
```

## Customize rules

You can apply scan customizations to GitLab Secret Scanning for Source Code with a
`.gitlab/secret-detection-ruleset.toml` file in your repository. To create this file, see
[create a ruleset configuration file](../pipeline/configure.md#create-a-ruleset-configuration-file).

You can:

- [Disable a rule](../pipeline/configure.md#disable-a-rule) from the default ruleset.
- [Extend the default ruleset](../pipeline/configure.md#extend-the-default-ruleset) with your own rules.
  New rules must follow the [custom rule format](../pipeline/custom_rulesets_schema.md#custom-rule-format).
- Ignore secrets by regular expression or file path with allowlists.

For example, to extend the default ruleset and ignore secrets by regular expression or file path, use
a `file` passthrough that points to an extended configuration file. Add the passthrough to the
`.gitlab/secret-detection-ruleset.toml` file:

```toml
# .gitlab/secret-detection-ruleset.toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gss.toml"
    value  = "extended-gss-config.toml"
```

In the extended configuration file, use `[extend]` to build on the default ruleset, and one or more
`[[allowlists]]` tables to ignore findings. Each allowlist can match secret values with `regexes` and
file paths with `paths`:

```toml
# extended-gss-config.toml
[extend]
# Extends the default packaged ruleset. Do not change the path.
path = "/gitleaks.toml"

[[allowlists]]
  description = "Ignore known test values and fixture paths"
  regexes = [
    '''glpat-[0-9a-zA-Z_\-]{20}''',
  ]
  paths = [
    '''spec/fixtures/.*''',
  ]
```

The `regexes` and `paths` in an allowlist are combined with a logical OR. A finding is ignored if its
secret matches any of the `regexes`, or its file path matches any of the `paths`.

## Migrate from the default analyzer

GitLab Secret Scanning for Source Code replaces the default analyzer in the `secret_detection` job.
When the `SECRET_DETECTION_ENABLE_GSS` CI/CD variable is set to `true`, only GitLab Secret Scanning
for Source Code runs.

To migrate from the default analyzer:

1. [Turn on GitLab Secret Scanning for Source Code](#turn-on-the-analyzer) on a feature branch.
1. Run a pipeline and compare the findings against a scan that uses the default analyzer.
1. Review your ruleset customizations. For the available options, see [customize rules](#customize-rules).
1. When you're satisfied with the results, turn on the analyzer on your default branch.

### Existing findings after migration

When you turn on GitLab Secret Scanning for Source Code on your default branch, secrets that both
analyzers detect are taken over by the analyzer. It matches these findings to the vulnerabilities
previously reported by the default analyzer. Their existing vulnerability records carry over instead
of being reported again as new findings.

Findings that the default analyzer previously reported but GitLab Secret Scanning for Source Code
does not detect remain unchanged.

## FIPS-enabled images

While GitLab Secret Scanning for Source Code is in beta, no FIPS-enabled image is published for it.
If you set the `SECRET_DETECTION_IMAGE_SUFFIX` CI/CD variable to `-fips`, the `secret_detection` job
fails because it cannot pull the image.

To scan with a FIPS-enabled image, use the default analyzer for
[pipeline secret detection](../pipeline/_index.md#fips-enabled-images).

## Troubleshooting

For common issues in pipeline secret detection, see the [troubleshooting](../pipeline/_index.md#troubleshooting) documentation.

### View findings suppressed by confidence threshold

The analyzer suppresses findings that fall below a configurable confidence threshold.
The threshold is fixed at high, so the analyzer suppresses medium- and low-confidence findings.

To review the suppressed findings, set the `SECRET_DETECTION_GSS_DEBUG_REPORT`
CI/CD variable to `true` in the `secret_detection` job. This variable produces
a second job artifact named `gl-secret-detection-report.debug.json`, which you
can download from the job artifacts.
The debug report contains only the findings suppressed because of confidence.
It does not include findings suppressed by exclusions (allowlists).
The vulnerability report is unchanged and still shows only high-confidence findings.
If the variable is not set or is `false`, no debug report is produced. The scanner logs a warning
that does not affect the job status.

## Related topics

- [Customize pipeline secret detection](../pipeline/configure.md)
