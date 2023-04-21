---
type: reference, howto
stage: Secure
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Container Scanning **(FREE)**

> - Improved support for FIPS [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/263482) in GitLab 13.6 by upgrading `CS_MAJOR_VERSION` from `2` to `3`.
> - Integration with Trivy [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/322656) in GitLab 13.9 by upgrading `CS_MAJOR_VERSION` from `3` to `4`.
> - Integration with Clair [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/321451) in GitLab 13.9.
> - Default container scanning with Trivy [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/61850) in GitLab 14.0.
> - Integration with Grype as an alternative scanner [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/326279) in GitLab 14.0.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86092) the major analyzer version from `4` to `5` in GitLab 15.0.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86783) from GitLab Ultimate to GitLab Free in 15.0.
> - Container Scanning variables that reference Docker [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/357264) in GitLab 15.4.
> - Container Scanning template [moved](https://gitlab.com/gitlab-org/gitlab/-/issues/381665) from `Security/Container-Scanning.gitlab-ci.yml` to `Jobs/Container-Scanning.gitlab-ci.yml` in GitLab 15.6.

Your application's Docker image may itself be based on Docker images that contain known
vulnerabilities. By including an extra Container Scanning job in your pipeline that scans for those
vulnerabilities and displays them in a merge request, you can use GitLab to audit your Docker-based
apps.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Container Scanning](https://www.youtube.com/watch?v=C0jn2eN5MAs).

Container Scanning is often considered part of Software Composition Analysis (SCA). SCA can contain
aspects of inspecting the items your code uses. These items typically include application and system
dependencies that are almost always imported from external sources, rather than sourced from items
you wrote yourself.

GitLab offers both Container Scanning and [Dependency Scanning](../dependency_scanning/index.md)
to ensure coverage for all of these dependency types. To cover as much of your risk area as
possible, we encourage you to use all of our security scanners.

## Overview

GitLab integrates with open-source tools for vulnerability static analysis in containers:

- [Trivy](https://github.com/aquasecurity/trivy)
- [Grype](https://github.com/anchore/grype)

To integrate GitLab with security scanners other than those listed here, see
[Security scanner integration](../../../development/integrations/secure.md).

You can enable container scanning by doing one of the following:

- [Include the CI job](#configuration) in your existing `.gitlab-ci.yml` file.
- Implicitly use [Auto Container Scanning](../../../topics/autodevops/stages.md#auto-container-scanning),
  provided by [Auto DevOps](../../../topics/autodevops/index.md).

GitLab compares the found vulnerabilities between the source and target branches, and shows the
information directly in the merge request.

![Container Scanning Widget](img/container_scanning_v13_2.png)

### Capabilities

| Capability | In Free | In Ultimate |
| --- | ------ | ------ |
| [Configure Scanners](#configuration) | Yes | Yes |
| Customize Settings ([Variables](#available-cicd-variables), [Overriding](#overriding-the-container-scanning-template), [offline environment support](#running-container-scanning-in-an-offline-environment), etc) | Yes | Yes |
| [View JSON Report](#reports-json-format) as a CI job artifact | Yes | Yes |
| Generation of a JSON report of [dependencies](#dependency-list) as a CI job artifact | Yes | Yes |
| Ability to enable container scanning via an MR in the GitLab UI | Yes | Yes |
| [UBI Image Support](#fips-enabled-images) | Yes | Yes |
| Support for Trivy | Yes | Yes |
| Support for Grype | Yes | Yes |
| Inclusion of GitLab Advisory Database | Limited to the time-delayed content from GitLab [advisories-communities](https://gitlab.com/gitlab-org/advisories-community/) project | Yes - all the latest content from [Gemnasium DB](https://gitlab.com/gitlab-org/security-products/gemnasium-db) |
| Presentation of Report data in Merge Request and Security tab of the CI pipeline job | No | Yes |
| [Interaction with Vulnerabilities](#interacting-with-the-vulnerabilities) such as merge request approvals | No | Yes |
| [Solutions for vulnerabilities (auto-remediation)](#solutions-for-vulnerabilities-auto-remediation) | No | Yes |
| Support for the [vulnerability allow list](#vulnerability-allowlisting) | No | Yes |
| [Access to Security Dashboard page](#security-dashboard) | No | Yes |
| [Access to Dependency List page](../dependency_list/index.md) | No | Yes |

## Requirements

To enable container scanning in your pipeline, you need the following:

- GitLab CI/CD pipeline must include the `test` stage, which is available unless overridden with the [`stages`](../../../ci/yaml/index.md#stages) keyword.
- [GitLab Runner](https://docs.gitlab.com/runner/) with the [`docker`](https://docs.gitlab.com/runner/executors/docker.html)
  or [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes.html) executor on Linux/amd64.
- Docker `18.09.03` or higher installed on the same computer as the runner. If you're using the
  shared runners on GitLab.com, then this is already the case.
- An image matching the [supported distributions](#supported-distributions).
- [Build and push](../../packages/container_registry/build_and_push_images.md#use-gitlab-cicd)
  the Docker image to your project's container registry.
- If you're using a third-party container registry, you might need to provide authentication
  credentials through the `CS_REGISTRY_USER` and `CS_REGISTRY_PASSWORD` [configuration variables](#available-cicd-variables).
  For more details on how to use these variables, see [authenticate to a remote registry](#authenticate-to-a-remote-registry).

## Configuration

To enable container scanning, add the
[`Container-Scanning.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/Container-Scanning.gitlab-ci.yml)
to your `.gitlab-ci.yml` file:

```yaml
include:
  - template: Security/Container-Scanning.gitlab-ci.yml
```

The included template:

- Creates a `container_scanning` job in your CI/CD pipeline.
- Pulls the built Docker image from your project's [container registry](../../packages/container_registry/index.md)
  (see [requirements](#requirements)) and scans it for possible vulnerabilities.

GitLab saves the results as a
[Container Scanning report artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportscontainer_scanning)
that you can download and analyze later. When downloading, you always receive the most-recent
artifact. If [dependency scan is enabled](#dependency-list),
a [Dependency Scanning report artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportsdependency_scanning)
is also created.

The following is a sample `.gitlab-ci.yml` that builds your Docker image, pushes it to the container
registry, and scans the image:

```yaml
include:
  - template: Jobs/Build.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_DEFAULT_BRANCH_IMAGE: $CI_REGISTRY_IMAGE/$CI_DEFAULT_BRANCH:$CI_COMMIT_SHA
```

Setting `CS_DEFAULT_BRANCH_IMAGE` avoids duplicate vulnerability findings when an image name differs across branches.
The value of `CS_DEFAULT_BRANCH_IMAGE` indicates the name of the scanned image as it appears on the default branch.
For more details on how this deduplication is achieved, see [Setting the default branch image](#setting-the-default-branch-image).

### Customizing the container scanning settings

There may be cases where you want to customize how GitLab scans your containers. For example, you
may want to enable more verbose output, access a Docker registry that requires
authentication, and more. To change such settings, use the [`variables`](../../../ci/yaml/index.md#variables)
parameter in your `.gitlab-ci.yml` to set [CI/CD variables](#available-cicd-variables).
The variables you set in your `.gitlab-ci.yml` overwrite those in
`Container-Scanning.gitlab-ci.yml`.

This example [includes](../../../ci/yaml/index.md#include) the container scanning template and
enables verbose output for the analyzer:

```yaml
include:
  - template: Security/Container-Scanning.gitlab-ci.yml

variables:
    SECURE_LOG_LEVEL: 'debug'
```

#### Scan an image in a remote registry

To scan images located in a registry other than the project's, use the following `.gitlab-ci.yml`:

```yaml
include:
  - template: Security/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_IMAGE: example.com/user/image:tag
```

##### Authenticate to a remote registry

Scanning an image in a private registry requires authentication. Provide the username in the `CS_REGISTRY_USER`
variable, and the password in the `CS_REGISTRY_PASSWORD` configuration variable.

For example, to scan an image from AWS Elastic Container Registry:

```yaml
container_scanning:
  before_script:
    - ruby -r open-uri -e "IO.copy_stream(URI.open('https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip'), 'awscliv2.zip')"
    - unzip awscliv2.zip
    - sudo ./aws/install
    - aws --version
    - export AWS_ECR_PASSWORD=$(aws ecr get-login-password --region region)

include:
  - template: Security/Container-Scanning.gitlab-ci.yml

variables: 
    CS_IMAGE: <aws_account_id>.dkr.ecr.<region>.amazonaws.com/<image>:<tag>
    CS_REGISTRY_USER: AWS
    CS_REGISTRY_PASSWORD: "$AWS_ECR_PASSWORD"
```

Authenticating to a remote registry is not supported when [FIPS mode](../../../development/fips_compliance.md#enable-fips-mode) is enabled.

#### Dependency list

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/345434) in GitLab 14.6.

The `CS_DISABLE_DEPENDENCY_LIST` CI/CD variable controls whether the scan creates a
[Dependency List](../dependency_list/index.md)
report. This variable is currently only supported when the `trivy` analyzer is used. The variable's default setting of `"false"` causes the scan to create the report. To disable
the report, set the variable to `"true"`:

For example:

```yaml
include:
  - template: Security/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_DISABLE_DEPENDENCY_LIST: "true"
```

#### Report language-specific findings

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/7277) in GitLab 14.6.

The `CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN` CI/CD variable controls whether the scan reports
findings related to programming languages. The languages supported depend on the
[scanner used](#change-scanners):

- [Trivy](https://aquasecurity.github.io/trivy/latest/docs/vulnerability/detection/language/).
- [Grype](https://github.com/anchore/grype#features).

By default, the report only includes packages managed by the Operating System (OS) package manager
(for example, `yum`, `apt`, `apk`, `tdnf`). To report security findings in non-OS packages, set
`CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN` to `"false"`:

```yaml
include:
  - template: Security/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN: "false"
```

When you enable this feature, you may see [duplicate findings](../terminology/index.md#duplicate-finding)
in the [Vulnerability Report](../vulnerability_report/index.md)
if [Dependency Scanning](../dependency_scanning/index.md)
is enabled for your project. This happens because GitLab can't automatically deduplicate findings
across different types of scanning tools. Reference [this comparison](../dependency_scanning/index.md#dependency-scanning-compared-to-container-scanning)
between GitLab Dependency Scanning and Container Scanning for more details on which types of dependencies are likely to be duplicated.

#### Available CI/CD variables

You can [configure](#customizing-the-container-scanning-settings) analyzers by using the following CI/CD variables.

WARNING:
All customization of GitLab security scanning tools should be tested in a merge request before
merging these changes to the default branch. Failure to do so can give unexpected results,
including a large number of false positives.

| CI/CD Variable                 | Default       | Description | Scanner |
| ------------------------------ | ------------- | ----------- | ------------ |
| `ADDITIONAL_CA_CERT_BUNDLE`    | `""`          | Bundle of CA certs that you want to trust. See [Using a custom SSL CA certificate authority](#using-a-custom-ssl-ca-certificate-authority) for more details. | All |
| `CI_APPLICATION_REPOSITORY`    | `$CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG` | Docker repository URL for the image to be scanned. | All |
| `CI_APPLICATION_TAG`           | `$CI_COMMIT_SHA` | Docker repository tag for the image to be scanned. | All |
| `CS_ANALYZER_IMAGE`            | `registry.gitlab.com/security-products/container-scanning:5` | Docker image of the analyzer. | All |
| `CS_DEFAULT_BRANCH_IMAGE`      | `""` | The name of the `CS_IMAGE` on the default branch. See [Setting the default branch image](#setting-the-default-branch-image) for more details. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/338877) in GitLab 14.5. | All |
| `CS_DISABLE_DEPENDENCY_LIST`   | `"false"`      | Disable Dependency Scanning for packages installed in the scanned image. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/345434) in GitLab 14.6. | All |
| `CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN` | `"true"` | Disable scanning for language-specific packages installed in the scanned image. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/345434) in GitLab 14.6. | All |
| `CS_DOCKER_INSECURE`           | `"false"`     | Allow access to secure Docker registries using HTTPS without validating the certificates. | All |
| `CS_IMAGE_SUFFIX`              | `""`          | Suffix added to `CS_ANALYZER_IMAGE`. If set to `-fips`, `FIPS-enabled` image is used for scan. See [FIPS-enabled images](#fips-enabled-images) for more details. [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/7630) in GitLab 14.10. | All |
| `CS_IGNORE_UNFIXED`            | `"false"`     | Ignore vulnerabilities that are not fixed. | All |
| `CS_REGISTRY_INSECURE`         | `"false"`     | Allow access to insecure registries (HTTP only). Should only be set to `true` when testing the image locally. Works with all scanners, but the registry must listen on port `80/tcp` for Trivy to work. | All |
| `CS_SEVERITY_THRESHOLD`        | `UNKNOWN`     | Severity level threshold. The scanner outputs vulnerabilities with severity level higher than or equal to this threshold. Supported levels are `UNKNOWN`, `LOW`, `MEDIUM`, `HIGH`, and `CRITICAL`. | Trivy |
| `CS_IMAGE`                 | `$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG` | The Docker image to be scanned. If set, this variable overrides the `$CI_APPLICATION_REPOSITORY` and `$CI_APPLICATION_TAG` variables. | All |
| `CS_REGISTRY_PASSWORD`              | `$CI_REGISTRY_PASSWORD` | Password for accessing a Docker registry requiring authentication. The default is only set if `$CS_IMAGE` resides at [`$CI_REGISTRY`](../../../ci/variables/predefined_variables.md). Not supported when [FIPS mode](../../../development/fips_compliance.md#enable-fips-mode) is enabled. | All |
| `CS_REGISTRY_USER`                  | `$CI_REGISTRY_USER` | Username for accessing a Docker registry requiring authentication. The default is only set if `$CS_IMAGE` resides at [`$CI_REGISTRY`](../../../ci/variables/predefined_variables.md). Not supported when [FIPS mode](../../../development/fips_compliance.md#enable-fips-mode) is enabled. | All |
| `CS_DOCKERFILE_PATH`              | `Dockerfile`  | The path to the `Dockerfile` to use for generating remediations. By default, the scanner looks for a file named `Dockerfile` in the root directory of the project. You should configure this variable only if your `Dockerfile` is in a non-standard location, such as a subdirectory. See [Solutions for vulnerabilities](#solutions-for-vulnerabilities-auto-remediation) for more details. | All |
| `CS_QUIET`                     | `""`          | If set, this variable disables output of the [vulnerabilities table](#container-scanning-job-log-format) in the job log. [Introduced](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/merge_requests/50) in GitLab 15.1. | All |
| `SECURE_LOG_LEVEL`             | `info`        | Set the minimum logging level. Messages of this logging level or higher are output. From highest to lowest severity, the logging levels are: `fatal`, `error`, `warn`, `info`, `debug`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/10880) in GitLab 13.1. | All |

### Supported distributions

Support depends on which scanner is used:

| Distribution   | Grype | Trivy |
| -------------- | ----- | ----- |
| Alma Linux     |       |  ✅   |
| Alpine Linux   |  ✅   |  ✅   |
| Amazon Linux   |  ✅   |  ✅   |
| BusyBox        |  ✅   |       |
| CentOS         |  ✅   |  ✅   |
| CBL-Mariner    |       |  ✅   |
| Debian         |  ✅   |  ✅   |
| Distroless     |  ✅   |  ✅   |
| Oracle Linux   |  ✅   |  ✅   |
| Photon OS      |       |  ✅   |
| Red Hat (RHEL) |  ✅   |  ✅   |
| Rocky Linux    |       |  ✅   |
| SUSE           |       |  ✅   |
| Ubuntu         |  ✅   |  ✅   |

#### FIPS-enabled images

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5775) in GitLab 14.1.

GitLab also offers [FIPS-enabled Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image)
versions of the container-scanning images. You can therefore replace standard images with FIPS-enabled
images. To configure the images, set the `CS_IMAGE_SUFFIX` to `-fips` or modify the `CS_ANALYZER_IMAGE` variable to the
standard tag plus the `-fips` extension.

| Scanner name    | `CS_ANALYZER_IMAGE` |
| --------------- | ------------------- |
| Default (Trivy) | `registry.gitlab.com/security-products/container-scanning:5-fips` |
| Grype           | `registry.gitlab.com/security-products/container-scanning/grype:5-fips` |
| Trivy           | `registry.gitlab.com/security-products/container-scanning/trivy:5-fips` |

NOTE:
Prior to GitLab 15.0, the `-ubi` image extension is also available. GitLab 15.0 and later only
support `-fips`.

Starting with GitLab 14.10, `-fips` is automatically added to `CS_ANALYZER_IMAGE` when FIPS mode is
enabled in the GitLab instance.

Container scanning of images in authenticated registries is not supported when [FIPS mode](../../../development/fips_compliance.md#enable-fips-mode)
is enabled. When `CI_GITLAB_FIPS_MODE` is `"true"`, and `CS_REGISTRY_USER` or `CS_REGISTRY_PASSWORD` is set,
the analyzer exits with an error and does not perform the scan.

### Enable Container Scanning through an automatic merge request

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/6334) in GitLab 14.9.

To enable Container Scanning in a project, create a merge request from the Security Configuration
page:

1. In the project where you want to enable Container Scanning, go to
   **Security and Compliance > Security configuration**.
1. In the **Container Scanning** row, select **Configure with a merge request**.

This automatically creates a merge request with the changes necessary to enable Container Scanning.
To complete the configuration, review and merge this merge request.

The configuration tool works best with no existing `.gitlab-ci.yml` file, or with a minimal
configuration file. If you have a complex GitLab configuration file, it may not be parsed
successfully and an error may occur.

### Overriding the container scanning template

If you want to override the job definition (for example, to change properties like `variables`), you
must declare and override a job after the template inclusion, and then
specify any additional keys.

This example sets `GIT_STRATEGY` to `fetch`:

```yaml
include:
  - template: Security/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    GIT_STRATEGY: fetch
```

### Change scanners

The container-scanning analyzer can use different scanners, depending on the value of the
`CS_ANALYZER_IMAGE` configuration variable.

The following options are available:

| Scanner name                                             | `CS_ANALYZER_IMAGE`                                                |
|----------------------------------------------------------|--------------------------------------------------------------------|
| Default ([Trivy](https://github.com/aquasecurity/trivy)) | `registry.gitlab.com/security-products/container-scanning:5`       |
| [Grype](https://github.com/anchore/grype)                | `registry.gitlab.com/security-products/container-scanning/grype:5` |
| Trivy                                                    | `registry.gitlab.com/security-products/container-scanning/trivy:5` |

### Setting the default branch image

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/338877) in GitLab 14.5.

By default, container scanning assumes that the image naming convention stores any branch-specific
identifiers in the image tag rather than the image name. When the image name differs between the
default branch and the non-default branch, previously-detected vulnerabilities show up as newly
detected in merge requests.

When the same image has different names on the default branch and a non-default branch, you can use
the `CS_DEFAULT_BRANCH_IMAGE` variable to indicate what that image's name is on the default branch.
GitLab then correctly determines if a vulnerability already exists when running scans on non-default
branches.

As an example, suppose the following:

- Non-default branches publish images with the naming convention
  `$CI_REGISTRY_IMAGE/$CI_COMMIT_BRANCH:$CI_COMMIT_SHA`.
- The default branch publishes images with the naming convention
  `$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA`.

In this example, you can use the following CI/CD configuration to ensure that vulnerabilities aren't
duplicated:

```yaml
include:
  - template: Security/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_DEFAULT_BRANCH_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  before_script:
    - export CS_IMAGE="$CI_REGISTRY_IMAGE/$CI_COMMIT_BRANCH:$CI_COMMIT_SHA"
    - |
      if [ "$CI_COMMIT_BRANCH" == "$CI_DEFAULT_BRANCH" ]; then
        export CS_IMAGE="$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA"
      fi
```

`CS_DEFAULT_BRANCH_IMAGE` should remain the same for a given `CS_IMAGE`. If it changes, then a
duplicate set of vulnerabilities are created, which must be manually dismissed.

When using [Auto DevOps](../../../topics/autodevops/index.md), `CS_DEFAULT_BRANCH_IMAGE` is
automatically set to `$CI_REGISTRY_IMAGE/$CI_DEFAULT_BRANCH:$CI_APPLICATION_TAG`.

### Using a custom SSL CA certificate authority

You can use the `ADDITIONAL_CA_CERT_BUNDLE` CI/CD variable to configure a custom SSL CA certificate authority, which is used to verify the peer when fetching Docker images from a registry which uses HTTPS. The `ADDITIONAL_CA_CERT_BUNDLE` value should contain the [text representation of the X.509 PEM public-key certificate](https://www.rfc-editor.org/rfc/rfc7468#section-5.1). For example, to configure this value in the `.gitlab-ci.yml` file, use the following:

```yaml
container_scanning:
  variables:
    ADDITIONAL_CA_CERT_BUNDLE: |
        -----BEGIN CERTIFICATE-----
        MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
        ...
        jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
        -----END CERTIFICATE-----
```

The `ADDITIONAL_CA_CERT_BUNDLE` value can also be configured as a [custom variable in the UI](../../../ci/variables/index.md#for-a-project), either as a `file`, which requires the path to the certificate, or as a variable, which requires the text representation of the certificate.

### Vulnerability allowlisting **(ULTIMATE)**

To allowlist specific vulnerabilities, follow these steps:

1. Set `GIT_STRATEGY: fetch` in your `.gitlab-ci.yml` file by following the instructions in
   [overriding the container scanning template](#overriding-the-container-scanning-template).
1. Define the allowlisted vulnerabilities in a YAML file named `vulnerability-allowlist.yml`. This must use
   the format described in [`vulnerability-allowlist.yml` data format](#vulnerability-allowlistyml-data-format).
1. Add the `vulnerability-allowlist.yml` file to the root folder of your project's Git repository.

#### `vulnerability-allowlist.yml` data format

The `vulnerability-allowlist.yml` file is a YAML file that specifies a list of CVE IDs of vulnerabilities that are **allowed** to exist, because they're _false positives_, or they're _not applicable_.

If a matching entry is found in the `vulnerability-allowlist.yml` file, the following happens:

- The vulnerability **is not included** when the analyzer generates the `gl-container-scanning-report.json` file.
- The Security tab of the pipeline **does not show** the vulnerability. It is not included in the JSON file, which is the source of truth for the Security tab.

Example `vulnerability-allowlist.yml` file:

```yaml
generalallowlist:
  CVE-2019-8696:
  CVE-2014-8166: cups
  CVE-2017-18248:
images:
  registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256:
    CVE-2018-4180:
  your.private.registry:5000/centos:
    CVE-2015-1419: libxml2
    CVE-2015-1447:
```

This example excludes from `gl-container-scanning-report.json`:

1. All vulnerabilities with CVE IDs: _CVE-2019-8696_, _CVE-2014-8166_, _CVE-2017-18248_.
1. All vulnerabilities found in the `registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256` container image with CVE ID _CVE-2018-4180_.
1. All vulnerabilities found in `your.private.registry:5000/centos` container with CVE IDs _CVE-2015-1419_, _CVE-2015-1447_.

##### File format

- `generalallowlist` block allows you to specify CVE IDs globally. All vulnerabilities with matching CVE IDs are excluded from the scan report.

- `images` block allows you to specify CVE IDs for each container image independently. All vulnerabilities from the given image with matching CVE IDs are excluded from the scan report. The image name is retrieved from one of the environment variables used to specify the Docker image to be scanned, such as `$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG` or `CS_IMAGE`. The image provided in this block **must** match this value and **must not** include the tag value. For example, if you specify the image to be scanned using `CS_IMAGE=alpine:3.7`, then you would use `alpine` in the `images` block, but you cannot use `alpine:3.7`.

  You can specify container image in multiple ways:

  - as image name only (such as `centos`).
  - as full image name with registry hostname (such as `your.private.registry:5000/centos`).
  - as full image name with registry hostname and sha256 label (such as `registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256`).

NOTE:
The string after CVE ID (`cups` and `libxml2` in the previous example) is an optional comment format. It has **no impact** on the handling of vulnerabilities. You can include comments to describe the vulnerability.

##### Container scanning job log format

You can verify the results of your scan and the correctness of your `vulnerability-allowlist.yml` file by looking
at the logs that are produced by the container scanning analyzer in `container_scanning` job details.

The log contains a list of found vulnerabilities as a table, for example:

```plaintext
+------------+-------------------------+------------------------+-----------------------+------------------------------------------------------------------------+
|   STATUS   |      CVE SEVERITY       |      PACKAGE NAME      |    PACKAGE VERSION    |                            CVE DESCRIPTION                             |
+------------+-------------------------+------------------------+-----------------------+------------------------------------------------------------------------+
|  Approved  |   High CVE-2019-3462    |          apt           |         1.4.8         | Incorrect sanitation of the 302 redirect field in HTTP transport metho |
|            |                         |                        |                       | d of apt versions 1.4.8 and earlier can lead to content injection by a |
|            |                         |                        |                       |  MITM attacker, potentially leading to remote code execution on the ta |
|            |                         |                        |                       |                             rget machine.                              |
+------------+-------------------------+------------------------+-----------------------+------------------------------------------------------------------------+
| Unapproved |  Medium CVE-2020-27350  |          apt           |         1.4.8         | APT had several integer overflows and underflows while parsing .deb pa |
|            |                         |                        |                       | ckages, aka GHSL-2020-168 GHSL-2020-169, in files apt-pkg/contrib/extr |
|            |                         |                        |                       | acttar.cc, apt-pkg/deb/debfile.cc, and apt-pkg/contrib/arfile.cc. This |
|            |                         |                        |                       |  issue affects: apt 1.2.32ubuntu0 versions prior to 1.2.32ubuntu0.2; 1 |
|            |                         |                        |                       | .6.12ubuntu0 versions prior to 1.6.12ubuntu0.2; 2.0.2ubuntu0 versions  |
|            |                         |                        |                       | prior to 2.0.2ubuntu0.2; 2.1.10ubuntu0 versions prior to 2.1.10ubuntu0 |
|            |                         |                        |                       |                                  .1;                                   |
+------------+-------------------------+------------------------+-----------------------+------------------------------------------------------------------------+
| Unapproved |  Medium CVE-2020-3810   |          apt           |         1.4.8         | Missing input validation in the ar/tar implementations of APT before v |
|            |                         |                        |                       | ersion 2.1.2 could result in denial of service when processing special |
|            |                         |                        |                       |                         ly crafted deb files.                          |
+------------+-------------------------+------------------------+-----------------------+------------------------------------------------------------------------+
```

Vulnerabilities in the log are marked as `Approved` when the corresponding CVE ID is added to the `vulnerability-allowlist.yml` file.

### Running container scanning in an offline environment

For self-managed GitLab instances in an environment with limited, restricted, or intermittent access
to external resources through the internet, some adjustments are required for the container scanning job to
successfully run. For more information, see [Offline environments](../offline_deployments/index.md).

#### Requirements for offline container Scanning

To use container scanning in an offline environment, you need:

- GitLab Runner with the [`docker` or `kubernetes` executor](#requirements).
- To configure a local Docker container registry with copies of the container scanning images. You
  can find these images in their respective registries:

| GitLab Analyzer | Container Registry |
| --- | --- |
| [Container-Scanning](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning) | [Container-Scanning container registry](https://gitlab.com/security-products/container-scanning/container_registry/) |

GitLab Runner has a [default `pull policy` of `always`](https://docs.gitlab.com/runner/executors/docker.html#using-the-always-pull-policy),
meaning the runner tries to pull Docker images from the GitLab container registry even if a local
copy is available. The GitLab Runner [`pull_policy` can be set to `if-not-present`](https://docs.gitlab.com/runner/executors/docker.html#using-the-if-not-present-pull-policy)
in an offline environment if you prefer using only locally available Docker images. However, we
recommend keeping the pull policy setting to `always` if not in an offline environment, as this
enables the use of updated scanners in your CI/CD pipelines.

##### Support for Custom Certificate Authorities

Support for custom certificate authorities was introduced in the following versions:

| Scanner | Version |
| -------- | ------- |
| `Trivy` | [4.0.0](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/releases/4.0.0) |
| `Grype` | [4.3.0](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/releases/4.3.0) |

#### Make GitLab container scanning analyzer images available inside your Docker registry

For container scanning, import the following images from `registry.gitlab.com` into your
[local Docker container registry](../../packages/container_registry/index.md):

```plaintext
registry.gitlab.com/security-products/container-scanning:5
registry.gitlab.com/security-products/container-scanning/grype:5
registry.gitlab.com/security-products/container-scanning/trivy:5
```

The process for importing Docker images into a local offline Docker registry depends on
**your network security policy**. Consult your IT staff to find an accepted and approved
process by which you can import or temporarily access external resources. These scanners
are [periodically updated](../index.md#vulnerability-scanner-maintenance),
and you may be able to make occasional updates on your own.

For more information, see [the specific steps on how to update an image with a pipeline](#automating-container-scanning-vulnerability-database-updates-with-a-pipeline).

For details on saving and transporting Docker images as a file, see the Docker documentation on
[`docker save`](https://docs.docker.com/engine/reference/commandline/save/), [`docker load`](https://docs.docker.com/engine/reference/commandline/load/),
[`docker export`](https://docs.docker.com/engine/reference/commandline/export/), and [`docker import`](https://docs.docker.com/engine/reference/commandline/import/).

#### Set container scanning CI/CD variables to use local container scanner analyzers

1. [Override the container scanning template](#overriding-the-container-scanning-template) in your `.gitlab-ci.yml` file to refer to the Docker images hosted on your local Docker container registry:

   ```yaml
   include:
     - template: Security/Container-Scanning.gitlab-ci.yml

   container_scanning:
     image: $CI_REGISTRY/namespace/container-scanning
   ```

1. If your local Docker container registry is running securely over `HTTPS`, but you're using a
   self-signed certificate, then you must set `CS_DOCKER_INSECURE: "true"` in the above
   `container_scanning` section of your `.gitlab-ci.yml`.

#### Automating container scanning vulnerability database updates with a pipeline

We recommend that you set up a [scheduled pipeline](../../../ci/pipelines/schedules.md)
to fetch the latest vulnerabilities database on a preset schedule.
Automating this with a pipeline means you do not have to do it manually each time. You can use the
following `.gitlab-ci.yml` example as a template.

```yaml
variables:
  SOURCE_IMAGE: registry.gitlab.com/security-products/container-scanning:5
  TARGET_IMAGE: $CI_REGISTRY/namespace/container-scanning

image: docker:stable

update-scanner-image:
  services:
    - docker:dind
  script:
    - docker pull $SOURCE_IMAGE
    - docker tag $SOURCE_IMAGE $TARGET_IMAGE
    - echo "$CI_REGISTRY_PASSWORD" | docker login $CI_REGISTRY --username $CI_REGISTRY_USER --password-stdin
    - docker push $TARGET_IMAGE
```

The above template works for a GitLab Docker registry running on a local installation. However, if
you're using a non-GitLab Docker registry, you must change the `$CI_REGISTRY` value and the
`docker login` credentials to match your local registry's details.

#### Scan images in external private registries

To scan an image in an external private registry, you must configure access credentials so the
container scanning analyzer can authenticate itself before attempting to access the image to scan.

If you use the GitLab [Container Registry](../../packages/container_registry/index.md),
the `CS_REGISTRY_USER` and `CS_REGISTRY_PASSWORD` [configuration variables](#available-cicd-variables)
are set automatically and you can skip this configuration.

This example shows the configuration needed to scan images in a private [Google Container Registry](https://cloud.google.com/container-registry/):

```yaml
include:
  - template: Security/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_REGISTRY_USER: _json_key
    CS_REGISTRY_PASSWORD: "$GCP_CREDENTIALS"
    CS_IMAGE: "gcr.io/path-to-you-registry/image:tag"
```

Before you commit this configuration, [add a CI/CD variable](../../../ci/variables/index.md#for-a-project)
for `GCP_CREDENTIALS` containing the JSON key, as described in the
[Google Cloud Platform Container Registry documentation](https://cloud.google.com/container-registry/docs/advanced-authentication#json-key).
Also:

- The value of the variable may not fit the masking requirements for the **Mask variable** option,
  so the value could be exposed in the job logs.
- Scans may not run in unprotected feature branches if you select the **Protect variable** option.
- Consider creating credentials with read-only permissions and rotating them regularly if the
  options aren't selected.

Scanning images in external private registries is not supported when [FIPS mode](../../../development/fips_compliance.md#enable-fips-mode) is enabled.

## Running the standalone container scanning tool

It's possible to run the [GitLab container scanning tool](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning)
against a Docker container without needing to run it within the context of a CI job. To scan an
image directly, follow these steps:

1. Run [Docker Desktop](https://www.docker.com/products/docker-desktop/)
   or [Docker Machine](https://github.com/docker/machine).

1. Run the analyzer's Docker image, passing the image and tag you want to analyze in the
   `CI_APPLICATION_REPOSITORY` and `CI_APPLICATION_TAG` variables:

   ```shell
   docker run \
     --interactive --rm \
     --volume "$PWD":/tmp/app \
     -e CI_PROJECT_DIR=/tmp/app \
     -e CI_APPLICATION_REPOSITORY=registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256 \
     -e CI_APPLICATION_TAG=bc09fe2e0721dfaeee79364115aeedf2174cce0947b9ae5fe7c33312ee019a4e \
     registry.gitlab.com/security-products/container-scanning
   ```

The results are stored in `gl-container-scanning-report.json`.

## Reports JSON format

The container scanning tool emits JSON reports which the [GitLab Runner](https://docs.gitlab.com/runner/)
recognizes through the [`artifacts:reports`](../../../ci/yaml/index.md#artifactsreports)
keyword in the CI configuration file.

Once the CI job finishes, the Runner uploads these reports to GitLab, which are then available in
the CI Job artifacts. In GitLab Ultimate, these reports can be viewed in the corresponding [pipeline](../vulnerability_report/pipeline.md)
and become part of the [Vulnerability Report](../vulnerability_report/index.md).

These reports must follow a format defined in the
[security report schemas](https://gitlab.com/gitlab-org/security-products/security-report-schemas/). See:

- [Latest schema for the container scanning report](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/container-scanning-report-format.json).
- [Example container scanning report](https://gitlab.com/gitlab-examples/security/security-reports/-/blob/master/samples/container-scanning.json)

For more information, see [Security scanner integration](../../../development/integrations/secure.md).

### CycloneDX Software Bill of Materials

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/396381) in GitLab 15.11.

In addition to the [JSON report file](#reports-json-format), the [Container Scanning](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning) tool outputs a [CycloneDX](https://cyclonedx.org/) Software Bill of Materials (SBOM) for the scanned image. This CycloneDX SBOM is named `gl-sbom-report.cdx.json` and is saved in the same directory as the `JSON report file`. This feature is only supported when the `Trivy` analyzer is used.

You can download CycloneDX SBOMs [the same way as other job artifacts](../../../ci/jobs/job_artifacts.md#download-job-artifacts).

## Security Dashboard

The [Security Dashboard](../security_dashboard/index.md) shows you an overview of all
the security vulnerabilities in your groups, projects and pipelines.

## Vulnerabilities database

All analyzer images are [updated daily](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/blob/master/README.md#image-updates).

The images use data from upstream advisory databases depending on which scanner is used:

| Data Source                    | Trivy | Grype |
| ------------------------------ | ----- | ----- |
| AlmaLinux Security Advisory    |  ✅   | ✅    |
| Amazon Linux Security Center   |  ✅   | ✅    |
| Arch Linux Security Tracker    |  ✅   |       |
| SUSE CVRF                      |  ✅   | ✅    |
| CWE Advisories                 |  ✅   |       |
| Debian Security Bug Tracker    |  ✅   | ✅    |
| GitHub Security Advisory       |  ✅   | ✅    |
| Go Vulnerability Database      |  ✅   |       |
| CBL-Mariner Vulnerability Data |  ✅   |       |
| NVD                            |  ✅   | ✅    |
| OSV                            |  ✅   |       |
| Red Hat OVAL v2                |  ✅   | ✅    |
| Red Hat Security Data API      |  ✅   | ✅    |
| Photon Security Advisories     |  ✅   |       |
| Rocky Linux UpdateInfo         |  ✅   |       |
| Ubuntu CVE Tracker (only data sources from mid 2021 and later) |  ✅   | ✅    |

In addition to the sources provided by these scanners, GitLab maintains the following vulnerability databases:

- The proprietary
[GitLab Advisory Database](https://gitlab.com/gitlab-org/security-products/gemnasium-db).
- The open source [GitLab Advisory Database (Open Source Edition)](https://gitlab.com/gitlab-org/advisories-community).

In the GitLab Ultimate tier, the data from the [GitLab Advisory Database](https://gitlab.com/gitlab-org/security-products/gemnasium-db) is merged in to augment the data from the external sources. In the GitLab Premium and Free tiers, the data from the [GitLab Advisory Database (Open Source Edition)](https://gitlab.com/gitlab-org/advisories-community) is merged in to augment the data from the external sources. This augmentation currently only applies to the analyzer images for the Trivy scanner.

Database update information for other analyzers is available in the
[maintenance table](../index.md#vulnerability-scanner-maintenance).

## Interacting with the vulnerabilities

After a vulnerability is found, you can [address it](../vulnerabilities/index.md).

## Solutions for vulnerabilities (auto-remediation) **(ULTIMATE)**

Some vulnerabilities can be fixed by applying the solution that GitLab
automatically generates.

To enable remediation support, the scanning tool _must_ have access to the `Dockerfile` specified by
the [`CS_DOCKERFILE_PATH`](#available-cicd-variables) CI/CD variable. To ensure that the scanning tool
has access to this
file, it's necessary to set [`GIT_STRATEGY: fetch`](../../../ci/runners/configure_runners.md#git-strategy) in
your `.gitlab-ci.yml` file by following the instructions described in this document's
[overriding the container scanning template](#overriding-the-container-scanning-template) section.

Read more about the [solutions for vulnerabilities](../vulnerabilities/index.md#resolve-a-vulnerability).

## Troubleshooting

### `docker: Error response from daemon: failed to copy xattrs`

When the runner uses the `docker` executor and NFS is used
(for example, `/var/lib/docker` is on an NFS mount), container scanning might fail with
an error like the following:

```plaintext
docker: Error response from daemon: failed to copy xattrs: failed to set xattr "security.selinux" on /path/to/file: operation not supported.
```

This is a result of a bug in Docker which is now [fixed](https://github.com/containerd/continuity/pull/138 "fs: add WithAllowXAttrErrors CopyOpt").
To prevent the error, ensure the Docker version that the runner is using is
`18.09.03` or higher. For more information, see
[issue #10241](https://gitlab.com/gitlab-org/gitlab/-/issues/10241 "Investigate why Container Scanning is not working with NFS mounts").

### Getting warning message `gl-container-scanning-report.json: no matching files`

For information on this, see the [general Application Security troubleshooting section](../../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload).

## Changes

Changes to the container scanning analyzer can be found in the project's
[changelog](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/blob/master/CHANGELOG.md).
