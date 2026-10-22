---
stage: Application Security Testing
group: Threat Research
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Malicious sources scanning
description: Detect references to known-malicious domains in your source code.
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced on GitLab.com](https://gitlab.com/groups/gitlab-org/-/work_items/22809) as an [experiment](../../../policy/development_stages_support.md#experiment) in GitLab 19.3.

{{< /history >}}

Malicious sources scanning finds references to known-malicious external domains in your repository,
such as the CDNs involved in the polyfill.io supply chain attack.
Each reference is reported as a SAST vulnerability.

To help decide the future of this experiment, share your feedback in [issue 634760](https://gitlab.com/gitlab-org/gitlab/-/work_items/634760).

## Turn on malicious sources scanning

To turn on malicious sources scanning, add the
[malicious sources CI/CD component](https://gitlab.com/explore/catalog/security-products/experiments/malicious-sources)
to your `.gitlab-ci.yml` file:

```yaml
include:
  - component: gitlab.com/security-products/experiments/malicious-sources/malicious-sources@0.2.0
```

The component adds a `malicious-sources-scan` job to the `test` stage.
Findings appear in the [vulnerability report](../vulnerability_report/_index.md) and in merge requests.

## Detected domains

Malicious sources scanning detects references to these domains, with `Critical` severity:

- `bootcdn.net`
- `bootcss.com` and `cdn.bootcss.com`
- `polyfill.com`
- `polyfill.io` and `cdn.polyfill.io`
- `staticfile.net` and `cdn.staticfile.net`
- `staticfile.org` and `cdn.staticfile.org`
- `unionadjs.com`

The analyzer matches `https://`, `http://`, and protocol-relative (`//`) references case-insensitively.

## Exclude paths

To skip files and directories, set `SAST_EXCLUDED_PATHS` to a comma-separated list of
gitignore-style patterns. The `.git` directory is always excluded.

```yaml
variables:
  SAST_EXCLUDED_PATHS: "node_modules, vendor, **/*.min.js"
```

## Add custom rules

To detect other domains, set `MALICIOUS_SOURCES_CUSTOM_RULES` to a YAML list of rules.
Custom rules are added to the built-in rules.

```yaml
variables:
  MALICIOUS_SOURCES_CUSTOM_RULES: |
    - rule_id: malicious.example.test
      substring: //malicious.example.test
      severity: High
      title: "Malicious CDN: malicious.example.test"
      description: "Known malicious CDN observed in supply chain attacks."
```

| Field              | Required | Description |
|--------------------|----------|-------------|
| `rule_id`          | Yes      | Unique ID. To override a built-in rule, use the rule's domain as the ID. |
| `substring`        | Yes      | Literal text to match on each line. Regular expressions are not supported. |
| `severity`         | Yes      | One of `Info`, `Low`, `Medium`, `High`, or `Critical`. |
| `title`            | Yes      | Name shown in the finding. |
| `description`      | Yes      | Explanation shown in the vulnerability report. |
| `case_insensitive` | No       | When `true`, matching ignores case. Default is `false`. |
| `disabled`         | No       | When `true`, the rule is removed. Default is `false`. |

To turn off a built-in rule, set `disabled: true` on its domain:

```yaml
variables:
  MALICIOUS_SOURCES_CUSTOM_RULES: |
    - rule_id: cdn.polyfill.io
      disabled: true
```

If the YAML is not valid, the scan fails with an error.
