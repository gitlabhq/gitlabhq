---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Infrastructure as Code scanning

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/6655) in GitLab 14.5.

Infrastructure as Code (IaC) scanning runs in your CI/CD pipeline, checking your infrastructure
definition files for known vulnerabilities. Identify vulnerabilities before they're committed to
the default branch to proactively address the risk to your application.

The IaC scanning analyzer outputs JSON-formatted reports as
[job artifacts](../../../ci/yaml/artifacts_reports.md#artifactsreportssast).

With GitLab Ultimate, IaC scanning results are also processed so you can:

- See them in merge requests.
- Use them in approval workflows.
- Review them in the vulnerability report.

## Enable the scanner

Prerequisites:

- IaC scanning requires the AMD64 architecture. Microsoft Windows is not supported.
- Minimum of 4 GB RAM to ensure consistent performance.
- The `test` stage is required in the `.gitlab-ci.yml` file.
- On GitLab self-managed you need GitLab Runner with the
  [`docker`](https://docs.gitlab.com/runner/executors/docker.html) or
  [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executor.
- If you're using SaaS runners on GitLab.com, this is enabled by default.

To enable IaC scanning of a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Build > Pipeline editor**.
1. Copy and paste the following to the bottom of the `.gitlab-ci.yml` file. If an `include` line
   already exists, add only the `template` line below it.

   ```yaml
   include:
     - template: Jobs/SAST-IaC.gitlab-ci.yml
   ```

1. Select the **Validate** tab, then select **Validate pipeline**.
   The message **Simulation completed successfully** indicates the file is valid.
1. Select the **Edit** tab.
1. Select **Commit changes**.

Pipelines now include an IaC scanning job.

## Supported languages and frameworks

IaC scanning supports a variety of IaC configuration files. When any supported configuration files
are detected in a project, they are scanned by using [KICS](https://kics.io/). Projects with a mix
of IaC configuration files are supported.

Supported configuration formats:

- Ansible
- AWS CloudFormation
- Azure Resource Manager

  NOTE:
  IaC scanning can analyze Azure Resource Manager templates in JSON format.
  If you write templates in [Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview),
  you must use the [Bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-cli) to
  convert your Bicep files into JSON before IaC scanning can analyze them.

- Dockerfile
- Google Deployment Manager
- Kubernetes
- OpenAPI
- Terraform

  NOTE:
  Terraform modules in a custom registry are not scanned for vulnerabilities.
  For more information about the proposed feature, see [issue 357004](https://gitlab.com/gitlab-org/gitlab/-/issues/357004).

## Customize rules

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> Support for overriding rules [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/235359) in GitLab 14.8.

You can customize the default IaC scanning rules provided with GitLab.

The following customization options can be used separately, or together:

- [Disable predefined rules](#disable-rules).
- [Override predefined rules](#override-rules).

### Ruleset definition

Every IaC scanning rule is contained in a `ruleset` section, which contains:

- A `type` field for the rule. For IaC Scanning, the identifier type is `kics_id`.
- A `value` field for the rule identifier. KICS rule identifiers are alphanumeric strings.
  To find the rule identifier:
  - Find it in the [JSON report artifact](#reports-json-format).
  - Search for the rule name in the [list of KICS queries](https://docs.kics.io/latest/queries/all-queries/)
    and copy the alphanumeric identifier that's shown. The rule name is shown on the
    [Vulnerability Page](../vulnerabilities/index.md) when a rule violation is detected.

### Disable rules

You can disable specific IaC Scanning rules.

To disable analyzer rules:

1. Create a `.gitlab` directory at the root of your project, if one doesn't already exist.
1. Create a custom ruleset file named `sast-ruleset.toml` in the `.gitlab` directory, if
   one doesn't already exist.
1. Set the `disabled` flag to `true` in the context of a `ruleset` section.
1. In one or more `ruleset` subsections, list the rules to disable.

After you merge the `sast-ruleset.toml` file to the default branch, existing findings for disabled rules are [automatically resolved](#automatic-vulnerability-resolution).

In the following example `sast-ruleset.toml` file, the disabled rules are assigned to
the `kics` analyzer by matching the `type` and `value` of identifiers:

```toml
[kics]
  [[kics.ruleset]]
    disable = true
    [kics.ruleset.identifier]
      type = "kics_id"
      value = "8212e2d7-e683-49bc-bf78-d6799075c5a7"

  [[kics.ruleset]]
    disable = true
    [kics.ruleset.identifier]
      type = "kics_id"
      value = "b03a748a-542d-44f4-bb86-9199ab4fd2d5"
```

### Override rules

You can override specific IaC scanning rules to customize them. For example, assign a rule a lower
severity, or link to your own documentation about how to fix a finding.

To override rules:

1. Create a `.gitlab` directory at the root of your project, if one doesn't already exist.
1. Create a custom ruleset file named `sast-ruleset.toml` in the `.gitlab` directory, if
   one doesn't already exist.
1. In one or more `ruleset.identifier` subsections, list the rules to override.
1. In the `ruleset.override` context of a `ruleset` section, provide the keys to override. Any
   combination of keys can be overridden. Valid keys are:
   - description
   - message
   - name
   - severity (valid options are: Critical, High, Medium, Low, Unknown, Info)

In the following example `sast-ruleset.toml` file, rules are matched by the `type` and
`value` of identifiers and then overridden:

```toml
[kics]
  [[kics.ruleset]]
    [kics.ruleset.identifier]
      type = "kics_id"
      value = "8212e2d7-e683-49bc-bf78-d6799075c5a7"
    [kics.ruleset.override]
      description = "OVERRIDDEN description"
      message = "OVERRIDDEN message"
      name = "OVERRIDDEN name"
      severity = "Info"
```

## Use a specific analyzer version

The GitLab-managed CI/CD template specifies a major version and automatically pulls the latest
analyzer release in that major version. In some cases, you may need to use a specific version.
For example, you might need to avoid a regression in a later release.

To use a specific analyzer version:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Build > Pipeline editor**.
1. Add the `SAST_ANALYZER_IMAGE_TAG` CI/CD variable, after the line that includes the
   `SAST-IaC.gitlab-ci.yml` template.

   NOTE:
   Only set this variable in a specific job. If you set it at the top level, the version you set is
   used for other SAST analyzers.

   Set the tag to:

   - A major version, like `3`. Your pipelines use any minor or patch updates that are released in this major version.
   - A minor version, like `3.7`. Your pipelines use any patch updates that are released in this minor version.
   - A patch version, like `3.7.0`. Your pipelines don't receive any updates.

This example uses a specific minor version of the IaC analyzer:

```yaml
include:
  - template: Jobs/SAST-IaC.gitlab-ci.yml

kics-iac-sast:
  variables:
    SAST_ANALYZER_IMAGE_TAG: "3.1"
```

## Supported distributions

GitLab scanners are provided with a base Alpine image for size and maintainability.

### Use FIPS-enabled images

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/6479) in GitLab 14.10.

GitLab provides [FIPS-enabled Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image)
versions of the scanners' images, in addition to the standard images.

To use the FIPS-enabled images in a pipeline, set the `SAST_IMAGE_SUFFIX` to `-fips` or modify the
standard tag plus the `-fips` extension.

The following example uses the `SAST_IMAGE_SUFFIX` CI/CD variable.

```yaml
variables:
  SAST_IMAGE_SUFFIX: '-fips'

include:
  - template: Jobs/SAST-IaC.gitlab-ci.yml
```

## Automatic vulnerability resolution

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/368284) in GitLab 15.9 [with a project-level flag](../../../administration/feature_flags.md) named `sec_mark_dropped_findings_as_resolved`.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/375128) in GitLab 16.2. Feature flag `sec_mark_dropped_findings_as_resolved` removed.

To help you focus on the vulnerabilities that are still relevant, IaC scanning automatically
[resolves](../vulnerabilities/index.md#vulnerability-status-values) vulnerabilities when:

- You [disable a predefined rule](#disable-rules).
- We remove a rule from the default ruleset.

If you re-enable the rule later, the findings are reopened for triage.

The vulnerability management system adds a note when it automatically resolves a vulnerability.

## Reports JSON format

The IaC scanner outputs a JSON report file in the existing SAST report format. For more information, see the
[schema for this report](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/sast-report-format.json).

The JSON report file can be downloaded from:

- The CI pipelines page.
- The pipelines tab on merge requests by
  [setting `artifacts: paths`](../../../ci/yaml/index.md#artifactspaths) to `gl-sast-report.json`.

For more information see [Downloading artifacts](../../../ci/jobs/job_artifacts.md).

## Troubleshooting

When working with IaC scanning, you might encounter the following issues.

### IaC scanning findings show as `No longer detected` unexpectedly

If a previously detected finding unexpectedly shows as `No longer detected`, it might
be due to an update to the scanner. An update can disable rules that are found to
be ineffective or false positives, and the findings are marked as `No longer detected`.

In GitLab 15.3, [secret detection in the IaC scanner was disabled](https://gitlab.com/gitlab-org/gitlab/-/issues/346181),
so IaC findings in the "Passwords and Secrets" family show as `No longer detected`.

### Message `exec /bin/sh: exec format error` in job log

You might get an error in the job log that states `exec /bin/sh: exec format error`. This issue
occurs when attempting to run the IaC scanning analyzer on an architecture other than AMD64
architecture. For details of IaC scanning prerequisites, see [Enable the scanner](#enable-the-scanner).
