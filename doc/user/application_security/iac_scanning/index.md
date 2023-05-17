---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Infrastructure as Code (IaC) Scanning **(FREE)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/6655) in GitLab 14.5.

Infrastructure as Code (IaC) Scanning scans your IaC configuration files for known vulnerabilities.

IaC Scanning supports configuration files for Terraform, Ansible, AWS CloudFormation, and Kubernetes.

## Requirements

IaC Scanning runs in the `test` stage, which is available by default. If you redefine the stages in the `.gitlab-ci.yml` file, the `test` stage is required.

We recommend a minimum of 4 GB RAM to ensure consistent performance.

To run IaC Scanning jobs, by default, you need GitLab Runner with the
[`docker`](https://docs.gitlab.com/runner/executors/docker.html) or
[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executor.
If you're using the shared runners on GitLab.com, this is enabled by default.

WARNING:
GitLab IaC Scanning analyzers don't support running on Windows or on any CPU architectures other than amd64.

WARNING:
If you use your own runners, make sure the Docker version installed
is **not** `19.03.0`. See [troubleshooting information](../sast/index.md#error-response-from-daemon-error-processing-tar-file-docker-tar-relocation-error) for details.

## Supported languages and frameworks

GitLab IaC Scanning supports a variety of IaC configuration files. Our IaC security scanners also feature automatic language detection which works even for mixed-language projects. If any supported configuration files are detected in project source code we automatically run the appropriate IaC analyzers.

| Configuration file type             | Scan tool                | Introduced in GitLab version |
| ----------------------------------- | ------------------------ | ---------------------------- |
| Ansible                             | [KICS](https://kics.io/) | 14.5                         |
| AWS CloudFormation                  | [KICS](https://kics.io/) | 14.5                         |
| Azure Resource Manager <sup>1</sup> | [KICS](https://kics.io/) | 14.5                         |
| Dockerfile                          | [KICS](https://kics.io/) | 14.5                         |
| Google Deployment Manager           | [KICS](https://kics.io/) | 14.5                         |
| Kubernetes                          | [KICS](https://kics.io/) | 14.5                         |
| OpenAPI                             | [KICS](https://kics.io/) | 14.5                         |
| Terraform <sup>2</sup>              | [KICS](https://kics.io/) | 14.5                         |

1. IaC Scanning can analyze Azure Resource Manager templates in JSON format. If you write templates in the [Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview) language, you must use [the bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-cli) to convert your Bicep files into JSON before GitLab IaC Scanning can analyze them.
1. Terraform modules in a custom registry are not scanned for vulnerabilities. You can follow [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/357004) for the proposed feature.

### Supported distributions

GitLab scanners are provided with a base alpine image for size and maintainability.

#### FIPS-enabled images

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/6479) in GitLab 14.10.

GitLab also offers [FIPS-enabled Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image)
versions of the images. You can therefore replace standard images with FIPS-enabled
images. To configure the images, set the `SAST_IMAGE_SUFFIX` to `-fips` or modify the
standard tag plus the `-fips` extension.

```yaml
variables:
  SAST_IMAGE_SUFFIX: '-fips'

include:
  - template: Jobs/SAST-IaC.gitlab-ci.yml
```

### Making IaC analyzers available to all GitLab tiers

All open source (OSS) analyzers are available with the GitLab Free tier. Future proprietary analyzers may be restricted to higher tiers.

#### Summary of features per tier

Different features are available in different [GitLab tiers](https://about.gitlab.com/pricing/),
as shown in the following table:

| Capability                                                      | In Free & Premium   | In Ultimate        |
| :-------------------------------------------------------------- | :------------------ | :----------------- |
| [Configure IaC scanner](#configuration)                         | **{check-circle}**  | **{check-circle}** |
| Download [JSON Report](#reports-json-format)                    | **{check-circle}**  | **{check-circle}** |
| See new findings in merge request widget                        | **{dotted-circle}** | **{check-circle}** |
| [Manage vulnerabilities](../vulnerabilities/index.md)           | **{dotted-circle}** | **{check-circle}** |
| [Access the Security Dashboard](../security_dashboard/index.md) | **{dotted-circle}** | **{check-circle}** |

## Contribute your scanner

The [Security Scanner Integration](../../../development/integrations/secure.md) documentation explains how to integrate other security scanners into GitLab.

## Configuration

To configure IaC Scanning for a project you can:

- [Configure IaC Scanning manually](#configure-iac-scanning-manually)
- [Enable IaC Scanning via an automatic merge request](#enable-iac-scanning-via-an-automatic-merge-request)

### Configure IaC Scanning manually

To enable IaC Scanning you must [include](../../../ci/yaml/index.md#includetemplate) the
[`SAST-IaC.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST-IaC.gitlab-ci.yml) provided as part of your GitLab installation. Here is an example of how to include it:

```yaml
include:
  - template: Jobs/SAST-IaC.gitlab-ci.yml
```

The included template creates IaC Scanning jobs in your CI/CD pipeline and scans
your project's configuration files for possible vulnerabilities.

The results are saved as a
[SAST report artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportssast)
that you can download and analyze.

### Enable IaC Scanning via an automatic merge request

To enable IaC Scanning in a project, you can create a merge request:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Security and Compliance > Security configuration**.
1. In the **Infrastructure as Code (IaC) Scanning** row, select **Configure with a merge request**.
1. Review and merge the merge request to enable IaC Scanning.

Pipelines now include an IaC Scanning job.

## Customize rulesets **(ULTIMATE)**

> [Added](https://gitlab.com/gitlab-org/gitlab/-/issues/235359) support for overriding rules in GitLab 14.8.

You can customize the default IaC Scanning rules provided with GitLab.

The following customization options can be used separately, or together:

- [Disable predefined rules](#disable-predefined-analyzer-rules).
- [Override predefined rules](#override-predefined-analyzer-rules).

### Disable predefined analyzer rules

If there are specific IaC Scanning rules that you don't want active, you can disable them.

To disable analyzer rules:

1. Create a `.gitlab` directory at the root of your project, if one doesn't already exist.
1. Create a custom ruleset file named `sast-ruleset.toml` in the `.gitlab` directory, if
   one doesn't already exist.
1. Set the `disabled` flag to `true` in the context of a `ruleset` section.
1. In one or more `ruleset` subsections, list the rules to disable. Every
   `ruleset.identifier` section has:
   - A `type` field for the rule. For IaC Scanning, the identifier type is `kics_id`.
   - A `value` field for the rule identifier. KICS rule identifiers are alphanumeric strings. To find the rule identifier, you can:
     - Find it in the [JSON report artifact](#reports-json-format).
     - Search for the rule name in the [list of KICS queries](https://docs.kics.io/latest/queries/all-queries/) and copy the alphanumeric identifier that's shown. The rule name is shown on the [Vulnerability Page](../vulnerabilities/index.md) when a rule violation is detected.

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

### Override predefined analyzer rules

If there are specific IaC Scanning rules you want to customize, you can override them. For
example, you might lower the severity of a rule or link to your own documentation about how to fix a finding.

To override rules:

1. Create a `.gitlab` directory at the root of your project, if one doesn't already exist.
1. Create a custom ruleset file named `sast-ruleset.toml` in the `.gitlab` directory, if
   one doesn't already exist.
1. In one or more `ruleset.identifier` subsections, list the rules to override. Every
   `ruleset.identifier` section has:
   - A `type` field for the rule. For IaC Scanning, the identifier type is `kics_id`.
   - A `value` field for the rule identifier. KICS rule identifiers are alphanumeric strings. To find the rule identifier, you can:
     - Find it in the [JSON report artifact](#reports-json-format).
     - Search for the rule name in the [list of KICS queries](https://docs.kics.io/latest/queries/all-queries/) and copy the alphanumeric identifier that's shown. The rule name is shown on the [Vulnerability Page](../vulnerabilities/index.md) when a rule violation is detected.
1. In the `ruleset.override` context of a `ruleset` section,
   provide the keys to override. Any combination of keys can be
   overridden. Valid keys are:
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

## Pinning to specific analyzer version

The GitLab-managed CI/CD template specifies a major version and automatically pulls the latest analyzer release within that major version.

In some cases, you may need to use a specific version.
For example, you might need to avoid a regression in a later release.

To override the automatic update behavior, set the `SAST_ANALYZER_IMAGE_TAG` CI/CD variable
in your CI/CD configuration file after you include the [`SAST-IaC.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST-IaC.gitlab-ci.yml).

Only set this variable in a specific job.
If you set it [at the top level](../../../ci/variables/index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file), the version you set is used for other SAST analyzers.

You can set the tag to:

- A major version, like `3`. Your pipelines use any minor or patch updates that are released within this major version.
- A minor version, like `3.7`. Your pipelines use any patch updates that are released within this minor version.
- A patch version, like `3.7.0`. Your pipelines don't receive any updates.

This example uses a specific minor version of the `KICS` analyzer:

```yaml
include:
  - template: Security/SAST-IaC.gitlab-ci.yml

kics-iac-sast:
  variables:
    SAST_ANALYZER_IMAGE_TAG: "3.1"
```

## Automatic vulnerability resolution

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/368284) in GitLab 15.9 [with a project-level flag](../../../administration/feature_flags.md) named `sec_mark_dropped_findings_as_resolved`.
> - Enabled by default in 15.10. On GitLab.com, [contact Support](https://about.gitlab.com/support/) if you need to disable the flag for your project.

To help you focus on the vulnerabilities that are still relevant, GitLab IaC Scanning automatically [resolves](../vulnerabilities/index.md#vulnerability-status-values) vulnerabilities when:

- You [disable a predefined rule](#disable-predefined-analyzer-rules).
- We remove a rule from the default ruleset.

The Vulnerability Management system leaves a comment on automatically-resolved vulnerabilities so you still have a historical record of the vulnerability.

If you re-enable the rule later, the findings are reopened for triage.

## Reports JSON format

The IaC tool emits a JSON report file in the existing SAST report format. For more information, see the
[schema for this report](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/sast-report-format.json).

The JSON report file can be downloaded from the CI pipelines page, or the
pipelines tab on merge requests by [setting `artifacts: paths`](../../../ci/yaml/index.md#artifactspaths) to `gl-sast-report.json`. For more information see [Downloading artifacts](../../../ci/jobs/job_artifacts.md).

## Troubleshooting

### IaC debug logging

To help troubleshoot IaC jobs, you can increase the [Secure scanner log verbosity](../sast/index.md#logging-level)
by using a global CI/CD variable set to `debug`:

```yaml
variables:
  SECURE_LOG_LEVEL: "debug"
```

### IaC Scanning findings show as `No longer detected` unexpectedly

If a previously detected finding unexpectedly shows as `No longer detected`, it might
be due to an update to the scanner. An update can disable rules that are found to
be ineffective or false positives, and the findings are marked as `No longer detected`:

- In GitLab 15.3, [secret detection in the KICS SAST IaC scanner was disabled](https://gitlab.com/gitlab-org/gitlab/-/issues/346181),
  so IaC findings in the "Passwords and Secrets" family show as `No longer detected`.

### `exec /bin/sh: exec format error` message in job log

The GitLab IaC Scanning analyzer [only supports](#requirements) running on the `amd64` CPU architecture.
This message indicates that the job is being run on a different architecture, such as `arm`.
