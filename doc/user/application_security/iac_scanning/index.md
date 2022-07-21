---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Infrastructure as Code (IaC) Scanning

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/6655) in GitLab 14.5.

Infrastructure as Code (IaC) Scanning scans your IaC configuration files for known vulnerabilities.

Currently, IaC scanning supports configuration files for Terraform, Ansible, AWS CloudFormation, and Kubernetes.

## Requirements

IaC Scanning runs in the `test` stage, which is available by default. If you redefine the stages in the `.gitlab-ci.yml` file, the `test` stage is required.

To run IaC scanning jobs, by default, you need GitLab Runner with the
[`docker`](https://docs.gitlab.com/runner/executors/docker.html) or
[`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executor.
If you're using the shared runners on GitLab.com, this is enabled by default.

WARNING:
Our IaC scanning jobs require a Linux/amd64 container type. Windows containers are not yet supported.

WARNING:
If you use your own runners, make sure the Docker version installed
is **not** `19.03.0`. See [troubleshooting information](../sast/index.md#error-response-from-daemon-error-processing-tar-file-docker-tar-relocation-error) for details.

## Supported languages and frameworks

GitLab IaC scanning supports a variety of IaC configuration files. Our IaC security scanners also feature automatic language detection which works even for mixed-language projects. If any supported configuration files are detected in project source code we automatically run the appropriate IaC analyzers.

| Configuration File Type                  | Scan tool                        | Introduced in GitLab Version  |
|------------------------------------------|----------------------------------|-------------------------------|
| Ansible                                  | [KICS](https://kics.io/)         | 14.5                          |
| AWS CloudFormation                       | [KICS](https://kics.io/)         | 14.5                          |
| Azure Resource Manager <sup>1</sup>      | [KICS](https://kics.io/)         | 14.5                          |
| Dockerfile                               | [KICS](https://kics.io/)         | 14.5                          |
| Google Deployment Manager                | [KICS](https://kics.io/)         | 14.5                          |
| Kubernetes                               | [KICS](https://kics.io/)         | 14.5                          |
| OpenAPI                                  | [KICS](https://kics.io/)         | 14.5                          |
| Terraform <sup>2</sup>                   | [KICS](https://kics.io/)         | 14.5                          |

1. IaC scanning can analyze Azure Resource Manager templates in JSON format. If you write templates in the [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview) language, you must use [the bicep CLI](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-cli) to convert your Bicep files into JSON before GitLab IaC scanning can analyze them.
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
  - template: Security/SAST-IaC.latest.gitlab-ci.yml
```

### Making IaC analyzers available to all GitLab tiers

All open source (OSS) analyzers are available with the GitLab Free tier. Future proprietary analyzers may be restricted to higher tiers.

#### Summary of features per tier

Different features are available in different [GitLab tiers](https://about.gitlab.com/pricing/),
as shown in the following table:

| Capability                                                      | In Free & Premium   | In Ultimate        |
|:----------------------------------------------------------------|:--------------------|:-------------------|
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
[`SAST-IaC.latest.gitlab-ci.yml template`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST-IaC.latest.gitlab-ci.yml) provided as part of your GitLab installation. Here is an example of how to include it:

```yaml
include:
  - template: Security/SAST-IaC.latest.gitlab-ci.yml
```

The included template creates IaC scanning jobs in your CI/CD pipeline and scans
your project's configuration files for possible vulnerabilities.

The results are saved as a
[SAST report artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportssast)
that you can download and analyze.

### Enable IaC Scanning via an automatic merge request

To enable IaC Scanning in a project, you can create a merge request:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Security & Compliance > Configuration**.
1. In the **Infrastructure as Code (IaC) Scanning** row, select **Configure with a merge request**.
1. Review and merge the merge request to enable IaC Scanning.

Pipelines now include an IaC job.

## Reports JSON format

The IaC tool emits a JSON report file in the existing SAST report format. For more information, see the
[schema for this report](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/sast-report-format.json).

The JSON report file can be downloaded from the CI pipelines page, or the
pipelines tab on merge requests by [setting `artifacts: paths`](../../../ci/yaml/index.md#artifactspaths) to `gl-sast-report.json`. For more information see [Downloading artifacts](../../../ci/pipelines/job_artifacts.md).

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
