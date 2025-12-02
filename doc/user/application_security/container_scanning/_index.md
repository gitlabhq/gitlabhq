---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Container scanning
description: Image vulnerability scanning, configuration, customization, and reporting.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Security vulnerabilities in container images create risk throughout your application lifecycle.
Container scanning detects these risks early, before they reach production environments. When
vulnerabilities appear in your base images or operating system's packages, container scanning
identifies them and provides a remediation path for those that it can.

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
  For an overview, see [Container scanning - Advanced Security Testing](https://www.youtube.com/watch?v=C0jn2eN5MAs).
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> For a video walkthrough, see [How to set up container scanning using GitLab](https://youtu.be/h__mcXpil_4?si=w_BVG68qnkL9x4l1).
- For an introductory tutorial, see [Scan a Docker container for vulnerabilities](../../../tutorials/container_scanning/_index.md).

Container scanning is often considered part of Software Composition Analysis (SCA). SCA can contain
aspects of inspecting the items your code uses. These items typically include application and system
dependencies that are almost always imported from external sources, rather than sourced from items
you wrote yourself.

GitLab offers both container scanning and dependency scanning
to ensure coverage for all these dependency types. To cover as much of your risk area as
possible, use all the security scanners. For a comparison of these features, see
[Dependency scanning compared to container scanning](../comparison_dependency_and_container_scanning.md).

GitLab integrates with the [Trivy](https://github.com/aquasecurity/trivy) security scanner to perform vulnerability static analysis in containers.

{{< alert type="warning" >}}

The Grype analyzer is no longer maintained, except for limited fixes as explained in the GitLab
[statement of support](https://about.gitlab.com/support/statement-of-support/#version-support).
The existing current major version for the Grype analyzer image will continue to be updated with the
latest advisory database, and operating system packages until GitLab 19.0, at which point the analyzer
will stop working.

{{< /alert >}}

## Features

| Features | In Free and Premium | In Ultimate |
|----------|---------------------|-------------|
| Customize Settings ([Variables](#available-cicd-variables), [Overriding](#overriding-the-container-scanning-template), [offline environment support](#offline-environment), etc) | {{< yes >}} | {{< yes >}} |
| [View JSON Report](#reports-json-format) as a CI job artifact | {{< yes >}} | {{< yes >}} |
| Generate a [CycloneDX SBOM JSON report](#cyclonedx-software-bill-of-materials) as a CI job artifact | {{< yes >}} | {{< yes >}} |
| Ability to enable container scanning via an MR in the GitLab UI | {{< yes >}} | {{< yes >}} |
| [UBI Image Support](#fips-enabled-images) | {{< yes >}} | {{< yes >}} |
| Support for Trivy | {{< yes >}} | {{< yes >}} |
| [End-of-life Operating System Detection](#end-of-life-operating-system-detection) | {{< yes >}} | {{< yes >}} |
| Inclusion of GitLab advisory database | Limited to the time-delayed content from GitLab [advisories-communities](https://gitlab.com/gitlab-org/advisories-community/) project | Yes - all the latest content from [Gemnasium DB](https://gitlab.com/gitlab-org/security-products/gemnasium-db) |
| Presentation of Report data in Merge Request and Security tab of the CI pipeline job | {{< no >}} | {{< yes >}} |
| [Solutions for vulnerabilities (auto-remediation)](#solutions-for-vulnerabilities-auto-remediation) | {{< no >}} | {{< yes >}} |
| Support for the [vulnerability allow list](#vulnerability-allowlisting) | {{< no >}} | {{< yes >}} |
| [Access to dependency list page](../dependency_list/_index.md) | {{< no >}} | {{< yes >}} |

## Getting started

Enable the container scanning analyzer in your CI/CD pipeline. When a pipeline runs, the images your
application depends on are scanned for vulnerabilities. You can customize container scanning by
using CI/CD variables.

Prerequisites:

- The test stage is required in the `.gitlab-ci.yml` file.
- With self-managed runners you need a runner with the `docker` or `kubernetes` executor on
  Linux/amd64. If you're using the instance runners on GitLab.com, this is enabled by default.
- An image matching the [supported distributions](#supported-distributions).
- [Build and push](../../packages/container_registry/build_and_push_images.md#use-gitlab-cicd) the
  Docker image to your project's container registry.
- If you're using a third-party container registry, you might need to provide authentication
  credentials by using the CI/CD variables `CS_REGISTRY_USER` and `CS_REGISTRY_PASSWORD`. For more
  details on how to use these variables, see
  [authenticate to a private external registry](#authenticate-to-private-external-registry).

Please see details below for [user and project-specific requirements](#prerequisites).

To enable the analyzer, either:

- Enable Auto DevOps, which includes dependency scanning.
- Use a preconfigured merge request.
- Create a [scan execution policy](../policies/scan_execution_policies.md) that enforces container
  scanning.
- Edit the `.gitlab-ci.yml` file manually.

### Use a preconfigured merge request

This method automatically prepares a merge request that includes the container scanning template
in the `.gitlab-ci.yml` file. You then merge the merge request to enable container scanning.

{{< alert type="note" >}}

This method works best with no existing `.gitlab-ci.yml` file, or with a minimal configuration file.
If you have a complex GitLab configuration file it might not be parsed successfully, and an error
might occur. In that case, use the manual method instead.

{{< /alert >}}

To enable container scanning:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Secure** > **Security configuration**.
1. In the **Container Scanning** row, select **Configure with a merge request**.
1. Select **Create merge request**.
1. Review the merge request, then select **Merge**.

Pipelines now include a container scanning job.

### Edit the `.gitlab-ci.yml` file manually

This method requires you to manually edit the existing `.gitlab-ci.yml` file. Use this method if
you have a complex GitLab configuration file or you need to use non-default options.

To enable container scanning:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Build** > **Pipeline editor**.
1. If no `.gitlab-ci.yml` file exists, select **Configure pipeline**, then delete the example
   content.
1. Copy and paste the following to the bottom of the `.gitlab-ci.yml` file. If an `include` line
   already exists, add only the `template` line below it.

   ```yaml
   include:
     - template: Jobs/Container-Scanning.gitlab-ci.yml
   ```

1. Select the **Validate** tab, then select **Validate pipeline**.

   The message **Simulation completed successfully** confirms the file is valid.
1. Select the **Edit** tab.
1. Complete the fields. Do not use the default branch for the **Branch** field.
1. Select the **Start a new merge request with these changes** checkbox, then select
   **Commit changes**.
1. Complete the fields according to your standard workflow, then select **Create merge request**.
1. Review and edit the merge request according to your standard workflow, wait until the pipeline
   passes, then select **Merge**.

Pipelines now include a container scanning job.

## Understanding the results

You can review vulnerabilities in a pipeline:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. On the left sidebar, select **Build** > **Pipelines**.
1. Select the pipeline.
1. Select the **Security** tab.
1. Select a vulnerability to view its details, including:
   - Description: Explains the cause of the vulnerability, its potential impact, and recommended remediation steps.
   - Status: Indicates whether the vulnerability has been triaged or resolved.
   - Severity: Categorized into six levels based on impact.
     [Learn more about severity levels](../vulnerabilities/severities.md).
   - CVSS score: Provides a numeric value that maps to severity.
   - EPSS: Shows the likelihood of a vulnerability being exploited in the wild.
   - Has Known Exploit (KEV): Indicates that a given vulnerability has been exploited.
   - Project: Highlights the project where the vulnerability was identified.
   - Report type: Explains the output type.
   - Scanner: Identifies which analyzer detected the vulnerability.
   - Image: Provides the image attributed to the vulnerability
   - Namespace: Identifies the workspace attributed to the vulnerability.
   - Links: Evidence of the vulnerability being cataloged in various advisory databases.
   - Identifiers: A list of references used to classify the vulnerability, such as CVE identifiers.

For more details, see [Pipeline security report](../detect/security_scanning_results.md).

Additional ways to see container scanning results:

- [Vulnerability report](../vulnerability_report/_index.md): Shows confirmed vulnerabilities on the default branch.
- [Container scanning report artifact](../../../ci/yaml/artifacts_reports.md#artifactsreportscontainer_scanning)

## Roll out

After you are confident in the container scanning results for a single project, you can extend its implementation to additional projects:

- Use [enforced scan execution](../detect/security_configuration.md#create-a-shared-configuration) to apply container scanning settings across groups.
- If you have unique requirements, container scanning can be run in [offline environments](#offline-environment).

## Supported distributions

The following Linux distributions are supported:

- Alma Linux
- Alpine Linux
- Amazon Linux
- CentOS
- CBL-Mariner
- Debian
- Distroless
- Oracle Linux
- Photon OS
- Red Hat (RHEL)
- Rocky Linux
- SUSE
- Ubuntu

### FIPS-enabled images

GitLab also offers [FIPS-enabled Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image)
versions of the container-scanning images. You can therefore replace standard images with FIPS-enabled
images. To configure the images, set the `CS_IMAGE_SUFFIX` to `-fips` or modify the `CS_ANALYZER_IMAGE` variable to the
standard tag plus the `-fips` extension.

{{< alert type="note" >}}

The `-fips` flag is automatically added to `CS_ANALYZER_IMAGE` when FIPS mode is enabled in the GitLab instance.

{{< /alert >}}

Container scanning of images in authenticated registries is not supported when FIPS mode
is enabled. When `CI_GITLAB_FIPS_MODE` is `"true"`, and `CS_REGISTRY_USER` or `CS_REGISTRY_PASSWORD` is set,
the analyzer exits with an error and does not perform the scan.

## Configuration

### Customizing analyzer behavior

To customize container scanning, use [CI/CD variables](#available-cicd-variables).

#### Enable verbose output

Enable verbose output when you need to see in detail what the dependency scanning job does, for
example when troubleshooting.

In the following example, the container scanning template is included and verbose output is enabled.

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

variables:
    SECURE_LOG_LEVEL: 'debug'
```

#### Report language-specific findings

The `CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN` CI/CD variable controls whether the scan reports
findings related to programming languages. For more information about the supported languages, see [Language-specific Packages](https://aquasecurity.github.io/trivy/latest/docs/coverage/language/#supported-languages) in the Trivy documentation.

By default, the report only includes packages managed by the Operating System (OS) package manager
(for example, `yum`, `apt`, `apk`, `tdnf`). To report security findings in non-OS packages, set
`CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN` to `"false"`:

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN: "false"
```

When you enable this feature, you might see [duplicate findings](../terminology/_index.md#duplicate-finding)
in the vulnerability report if dependency scanning is enabled for your project. This happens because
GitLab can't automatically deduplicate findings across different types of scanning tools. To
understand which types of dependencies are likely to be duplicated, see
[Dependency scanning compared to container scanning](../comparison_dependency_and_container_scanning.md).

#### Running jobs in merge request pipelines

See [Use security scanning tools with merge request pipelines](../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines).

#### Available CI/CD variables

To customize container scanning, use CI/CD variables. The following table lists CI/CD variables
specific to container scanning. You can also use any of the [predefined CI/CD variables](../../../ci/variables/predefined_variables.md).

{{< alert type="warning" >}}

Test customization of GitLab analyzers in a merge request before merging these changes to the
default branch. Failure to do so can give unexpected results, including a large number of false
positives.

{{< /alert >}}

| CI/CD Variable                           | Default                                                                         | Description                                                                                                                                                                                                                                                                                                                                                                                   |
|------------------------------------------|---------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `ADDITIONAL_CA_CERT_BUNDLE`              | `""`                                                                            | Bundle of CA certs that you want to trust. See [Using a custom SSL CA certificate authority](#using-a-custom-ssl-ca-certificate-authority) for more details.                                                                                                                                                                                                                                  |
| `CI_APPLICATION_REPOSITORY`              | `$CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG`                                        | Docker repository URL for the image to be scanned.                                                                                                                                                                                                                                                                                                                                            |
| `CI_APPLICATION_TAG`                     | `$CI_COMMIT_SHA`                                                                | Docker repository tag for the image to be scanned.                                                                                                                                                                                                                                                                                                                                            |
| `CS_ANALYZER_IMAGE`                      | `registry.gitlab.com/security-products/container-scanning:8`                    | Docker image of the analyzer. Do not use the `:latest` tag with analyzer images provided by GitLab.                                                                                                                                                                                                                                                                                           |
| `CS_DEFAULT_BRANCH_IMAGE`                | `""`                                                                            | The name of the `CS_IMAGE` on the default branch. See [Setting the default branch image](#setting-the-default-branch-image) for more details.                                                                                                                                                                                                                                                 |
| `CS_DISABLE_DEPENDENCY_LIST`             | `"false"`                                                                       | {{< icon name="warning" >}} **[Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/439782)** in GitLab 17.0.                                                                                                                                                                                                                                                                               |
| `CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN` | `"true"`                                                                        | Disable scanning for language-specific packages installed in the scanned image.                                                                                                                                                                                                                                                                                                               |
| `CS_DOCKER_INSECURE`                     | `"false"`                                                                       | Allow access to secure Docker registries using HTTPS without validating the certificates.                                                                                                                                                                                                                                                                                                     |
| `CS_DOCKERFILE_PATH`                     | `Dockerfile`                                                                    | The path to the `Dockerfile` to use for generating remediations. By default, the scanner looks for a file named `Dockerfile` in the root directory of the project. You should configure this variable only if your `Dockerfile` is in a non-standard location, such as a subdirectory. See [Solutions for vulnerabilities](#solutions-for-vulnerabilities-auto-remediation) for more details. |
| `CS_INCLUDE_LICENSES`                    | `""`                                                                            | If set, this variable includes licenses for each component. It is only applicable to cyclonedx reports and those licenses are provided by [trivy](https://trivy.dev/v0.60/docs/scanner/license/)                                                                                                                                                                                              |
| `CS_IGNORE_STATUSES`                     | `""`                                                                            | Force the analyzer to ignore findings with specified statuses in a comma-delimited list. The following values are allowed: `unknown,not_affected,affected,fixed,under_investigation,will_not_fix,fix_deferred,end_of_life`. <sup>1</sup>                                                                                                                                                      |
| `CS_IGNORE_UNFIXED`                      | `"false"`                                                                       | Ignore findings that are not fixed. Ignored findings are not included in the report.                                                                                                                                                                                                                                                                                                          |
| `CS_IMAGE`                               | `$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG`                                | The Docker image to be scanned. If set, this variable overrides the `$CI_APPLICATION_REPOSITORY` and `$CI_APPLICATION_TAG` variables.                                                                                                                                                                                                                                                         |
| `CS_IMAGE_SUFFIX`                        | `""`                                                                            | Suffix added to `CS_ANALYZER_IMAGE`. If set to `-fips`, `FIPS-enabled` image is used for scan. See [FIPS-enabled images](#fips-enabled-images) for more details.                                                                                                                                                                                                                              |
| `CS_QUIET`                               | `""`                                                                            | If set, this variable disables output of the [vulnerabilities table](#container-scanning-job-log-format) in the job log.                                                                                                                                    |
| `CS_REGISTRY_INSECURE`                   | `"false"`                                                                       | Allow access to insecure registries (HTTP only). Should only be set to `true` when testing the image locally. Works with all scanners, but the registry must listen on port `80/tcp` for Trivy to work.                                                                                                                                                                                       |
| `CS_REGISTRY_PASSWORD`                   | `$CI_REGISTRY_PASSWORD`                                                         | Password for accessing a Docker registry requiring authentication. The default is only set if `$CS_IMAGE` resides at [`$CI_REGISTRY`](../../../ci/variables/predefined_variables.md). Not supported when FIPS mode is enabled.                                                                                                                                                                |
| `CS_REGISTRY_USER`                       | `$CI_REGISTRY_USER`                                                             | Username for accessing a Docker registry requiring authentication. The default is only set if `$CS_IMAGE` resides at [`$CI_REGISTRY`](../../../ci/variables/predefined_variables.md). Not supported when FIPS mode is enabled.                                                                                                                                                                |
| `CS_REPORT_OS_EOL`                       | `"false"`                                                                       | Enable EOL detection                                                                                                                                                                                                                                                                                                                                                                          |
| `CS_REPORT_OS_EOL_SEVERITY`              | `"Medium"`                                                                      | Severity level assigned to EOL OS findings when `CS_REPORT_OS_EOL` is enabled. EOL findings are always reported regardless of `CS_SEVERITY_THRESHOLD`. Supported levels are `UNKNOWN`, `LOW`, `MEDIUM`, `HIGH`, and `CRITICAL`.                                                                                                                                                               |
| `CS_SEVERITY_THRESHOLD`                  | `UNKNOWN`                                                                       | Severity level threshold. The scanner outputs vulnerabilities with severity level higher than or equal to this threshold. Supported levels are `UNKNOWN`, `LOW`, `MEDIUM`, `HIGH`, and `CRITICAL`.                                                                                                                                                                                            |
| `CS_TRIVY_JAVA_DB`                       | `"registry.gitlab.com/gitlab-org/security-products/dependencies/trivy-java-db"` | Specify an alternate location for the [trivy-java-db](https://github.com/aquasecurity/trivy-java-db) vulnerability database.                                                                                                                                                                                                                                                                  |
| `CS_TRIVY_DETECTION_PRIORITY`            | `"precise"`                                                                     | Scan using the defined Trivy [detection priority](https://trivy.dev/latest/docs/scanner/vulnerability/#detection-priority). The following values are allowed: `precise` or `comprehensive`.                                                                                                                                                                                                   |
| `SECURE_LOG_LEVEL`                       | `info`                                                                          | Set the minimum logging level. Messages of this logging level or higher are output. From highest to lowest severity, the logging levels are: `fatal`, `error`, `warn`, `info`, `debug`.                                                                                                                                                                                                       |
| `TRIVY_TIMEOUT`                          | `5m0s`                                                                          | Set the timeout for the scan.                                                                                                                                                                                                                                                                                                                                                               |
| `TRIVY_PLATFORM`                         | `linux/amd64`                                                                   | Set platform in the format `os/arch` if image is multi-platform capable.                                                                                                                     |

**Footnotes**:

1. Fix status information is highly dependent on accurate fix availability data from the software
   vendor and container image operating system package metadata. It is also subject to
   interpretation by individual container scanners. In cases where a container scanner misreports
   the availability of a fixed package for a vulnerability, using `CS_IGNORE_STATUSES` can lead to
   false positive or false negative filtering of findings when this setting is enabled.

### Overriding the container scanning template

If you want to override the job definition (for example, to change properties like `variables`), you
must declare and override a job after the template inclusion, and then
specify any additional keys.

This example sets `GIT_STRATEGY` to `fetch`:

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    GIT_STRATEGY: fetch
```

### Scan image in external registry

By default, container scanning scans images in the GitLab container registry. You can also scan
images in external registries.

To scan an image in an external registry, configure the `CS_IMAGE` variable with the full path to
the image.

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_IMAGE: <example.com>/<user>/<image>:<tag>
```

#### Authenticate to private external registry

If the external registry requires authentication, provide credentials using the `CS_REGISTRY_USER`
and `CS_REGISTRY_PASSWORD` CI/CD variables.

{{< alert type="note" >}}

Scanning images in an external private registry is not supported when FIPS mode is enabled.

{{< /alert >}}

For example, to scan an image in Google Container Registry:

1. Add a CI/CD variable for `GCP_CREDENTIALS` containing the JSON key, as described in the
   [Google Cloud Platform Container Registry documentation](https://cloud.google.com/container-registry/docs/advanced-authentication#json-key).

   - The value of the variable might not fit the masking requirements for the mask variable option,
     so the value could be exposed in the job logs.
   - Scans might not run in unprotected feature branches if you select the protect variable option.
   - Consider creating credentials with read-only permissions and rotating them regularly if you
     don't select these options.

1. Add the following to the `.gitlab-ci.yml` file.

   ```yaml
   include:
     - template: Jobs/Container-Scanning.gitlab-ci.yml

   container_scanning:
     variables:
       CS_REGISTRY_USER: _json_key
       CS_REGISTRY_PASSWORD: "$GCP_CREDENTIALS"
       CS_IMAGE: "gcr.io/<path-to-your-registry>/<image>:<tag>"
   ```

For example, to scan an image in AWS Elastic Container Registry:

- Add the following to the `.gitlab-ci.yml` file:

  ```yaml
  container_scanning:
    before_script:
      - ruby -r open-uri -e "IO.copy_stream(URI.open('https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip'), 'awscliv2.zip')"
      - unzip awscliv2.zip
      - sudo ./aws/install
      - export AWS_ECR_PASSWORD=$(aws ecr get-login-password --region region)

  include:
    - template: Jobs/Container-Scanning.gitlab-ci.yml

  variables:
      CS_IMAGE: <aws_account_id>.dkr.ecr.<region>.amazonaws.com/<image>:<tag>
      CS_REGISTRY_USER: AWS
      CS_REGISTRY_PASSWORD: "$AWS_ECR_PASSWORD"
      AWS_DEFAULT_REGION: <region>
  ```

### Use a Trivy Java database mirror

When the `trivy` scanner is used and a `jar` file is encountered in a container image being scanned,
`trivy` downloads an additional `trivy-java-db` vulnerability database. By default, the
`trivy-java-db` database is hosted as an [OCI artifact](https://oras.land/docs/quickstart/) at
`ghcr.io/aquasecurity/trivy-java-db:1`. If this registry is
[not accessible](#offline-environment) or responds with
`TOOMANYREQUESTS`, one solution is to mirror the `trivy-java-db` to a more accessible container
registry:

```yaml
mirror trivy java db:
  image:
    name: ghcr.io/oras-project/oras:v1.1.0
    entrypoint: [""]
  script:
    - oras login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - oras pull ghcr.io/aquasecurity/trivy-java-db:1
    - oras push $CI_REGISTRY_IMAGE:1 --config /dev/null:application/vnd.aquasec.trivy.config.v1+json javadb.tar.gz:application/vnd.aquasec.trivy.javadb.layer.v1.tar+gzip
```

The vulnerability database is not a regular Docker image, so you cannot pull it by using
`docker pull`. The image shows an error if you view it in the GitLab UI.

If the container registry is `gitlab.example.com/trivy-java-db-mirror`, then the container scanning
job should be configured in the following way. Do not add the tag `:1` at the end, it is added by
`trivy`:

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_TRIVY_JAVA_DB: gitlab.example.com/trivy-java-db-mirror
```

### Setting the default branch image

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
  - template: Jobs/Container-Scanning.gitlab-ci.yml

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

When using Auto DevOps, `CS_DEFAULT_BRANCH_IMAGE` is
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

The `ADDITIONAL_CA_CERT_BUNDLE` value can also be configured as a custom variable in the UI, either
as a `file`, which requires the path to the certificate, or as a variable, which requires the text
representation of the certificate.

### Scanning a multi-arch image

You can use the `TRIVY_PLATFORM` CI/CD variable to configure the container scan to run against a specific
operating system and architecture. For example, to configure this value in the `.gitlab-ci.yml` file, use
the following:

```yaml
container_scanning:
  # Use an arm64 SaaS runner to scan this natively
  tags: ["saas-linux-small-arm64"]
  variables:
    TRIVY_PLATFORM: "linux/arm64"
```

### Vulnerability allowlisting

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

To allowlist specific vulnerabilities, follow these steps:

1. Set `GIT_STRATEGY: fetch` in your `.gitlab-ci.yml` file by following the instructions in
   [overriding the container scanning template](#overriding-the-container-scanning-template).
1. Define the allowlisted vulnerabilities in a YAML file named `vulnerability-allowlist.yml`. This must use
   the format described in [`vulnerability-allowlist.yml` data format](#vulnerability-allowlistyml-data-format).
1. Add the `vulnerability-allowlist.yml` file to the root folder of your project's Git repository.

#### `vulnerability-allowlist.yml` data format

The `vulnerability-allowlist.yml` file is a YAML file that specifies a list of CVE IDs of vulnerabilities that are **allowed** to exist, because they're false positives, or they're not applicable.

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

1. All vulnerabilities with CVE IDs: `CVE-2019-8696`, `CVE-2014-8166`, `CVE-2017-18248`.
1. All vulnerabilities found in the `registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256` container image with CVE ID `CVE-2018-4180`.
1. All vulnerabilities found in `your.private.registry:5000/centos` container with CVE IDs `CVE-2015-1419`, `CVE-2015-1447`.

##### File format

- `generalallowlist` block allows you to specify CVE IDs globally. All vulnerabilities with matching CVE IDs are excluded from the scan report.

- `images` block allows you to specify CVE IDs for each container image independently. All vulnerabilities from the given image with matching CVE IDs are excluded from the scan report. The image name is retrieved from one of the environment variables used to specify the Docker image to be scanned, such as `$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG` or `CS_IMAGE`. The image provided in this block **must** match this value and **must not** include the tag value. For example, if you specify the image to be scanned using `CS_IMAGE=alpine:3.7`, then you would use `alpine` in the `images` block, but you cannot use `alpine:3.7`.

  You can specify container image in multiple ways:

  - as image name only (such as `centos`).
  - as full image name with registry hostname (such as `your.private.registry:5000/centos`).
  - as full image name with registry hostname and sha256 label (such as `registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256`).

{{< alert type="note" >}}

The string after CVE ID (`cups` and `libxml2` in the previous example) is an optional comment format. It has **no impact** on the handling of vulnerabilities. You can include comments to describe the vulnerability.

{{< /alert >}}

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

### Offline environment

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

To run container scanning in an [offline environment](../offline_deployments/_index.md), you must
do an initial setup and perform ongoing maintenance.

Initial setup:

- Configure runner (ensure the `docker` or `kubernetes` executor is available).
- Set up a local container registry. For details, see
  [GitLab container registry](../../packages/container_registry/_index.md).
- Copy the image to your local container registry.
- Configure CI/CD for each project using container scanning.
- Depending on your requirements, you can optionally configure the following:
  - [Scan an image in an external registry](#scan-image-in-external-registry).
  - [Use a Trivy Java database mirror](#use-a-trivy-java-database-mirror).

Ongoing maintenance:

- Update the local container scanning image as new versions are released.

#### Configure runner

Configure runner (ensure the `docker` or `kubernetes` executor is available). For details,
see [getting started](#getting-started).

By default the runner pulls container images from the GitLab container registry even if a local
copy is available. If you prefer to use only local container images, you can change the
[`pull_policy` can be set to `if-not-present`](https://docs.gitlab.com/runner/executors/docker.html#using-the-if-not-present-pull-policy).
However, you should keep the `pull_policy` setting to the default unless you have good reason to
change it.

#### Copy container image

Import the following image from the GitLab.com container registry into your local container
registry. This image must be accessible from your offline GitLab instance.

```plaintext
registry.gitlab.com/security-products/container-scanning:8
```

The process for importing images into a local container registry depends on your network security
policy. Consult your IT staff to find an accepted and approved process by which you can import or
temporarily access external resources.

#### Configure CI/CD for each project

{{< alert type="note" >}}

These configuration changes do not apply to Container Scanning for Registry because it does not
reference the `.gitlab-ci.yml` file. To configure automatic Container Scanning for Registry in an
offline environment,
[define the `CS_ANALYZER_IMAGE` variable in the GitLab UI](#use-with-offline-or-air-gapped-environments)
instead.

{{< /alert >}}

For each project that uses container scanning, apply the following changes:

1. [Override the container scanning template](#overriding-the-container-scanning-template) in your
   `.gitlab-ci.yml` file to refer to the container images hosted on your local container registry:

   ```yaml
   include:
     - template: Jobs/Container-Scanning.gitlab-ci.yml

   container_scanning:
     image: $CI_REGISTRY/namespace/container-scanning
   ```

1. If you're using a non-GitLab container registry, update the `CI_REGISTRY` value and configure
   authentication by setting `CI_REGISTRY_USER` and `CI_REGISTRY_PASSWORD` variables to match your
   local registry credentials.

1. If your local container registry is running securely over `HTTPS`, but you're using a
   self-signed certificate, then you must set `CS_DOCKER_INSECURE: "true"` in the
   `container_scanning` section of your `.gitlab-ci.yml`.

#### Update local container image

The container scanning image is
[periodically updated](../detect/vulnerability_scanner_maintenance.md) and pushed to the GitLab.com
registry. In an offline environment, you must update the container scanning image in your local
container registry, either automatically (recommended) or manually.

- Manual method: Update the container scanning image manually in your local registry if it cannot
  access the GitLab.com registry over the network. Use the same method you used when you
  [copied the image for the initial setup](#copy-container-image).
- Automatic method: If your offline GitLab instance has read access to GitLab.com, set up a
  scheduled pipeline to automatically update the image on a preset schedule.

##### Automatic image update method

The following `.gitlab-ci.yml` extract demonstrates how to automatically update the container
scanning image in a local registry. This method defines variables for the source image and target
image, then uses the Docker CLI to pull the image from the GitLab.com registry and push it to your
local registry.

If you're using a non-GitLab registry, update the `CI_REGISTRY` value and configure authentication
by setting `CI_REGISTRY_USER` and `CI_REGISTRY_PASSWORD` variables to match your local registry
credentials.

```yaml
variables:
  SOURCE_IMAGE: registry.gitlab.com/security-products/container-scanning:8
  TARGET_IMAGE: $CI_REGISTRY/namespace/container-scanning

image: docker:cli

update-scanner-image:
  services:
    - docker:dind
  script:
    - docker pull $SOURCE_IMAGE
    - docker tag $SOURCE_IMAGE $TARGET_IMAGE
    - echo "$CI_REGISTRY_PASSWORD" | docker login $CI_REGISTRY --username $CI_REGISTRY_USER --password-stdin
    - docker push $TARGET_IMAGE
```

## Scanning archive formats

{{< history >}}

- Scanning tar files [introduced](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/merge_requests/3151) in GitLab 18.0.

{{< /history >}}

Container scanning supports images in archive formats (`.tar`, `.tar.gz`).
Such images may be created, for example, using `docker save` or `docker buildx build`.

To scan an archive file, set the environment variable `CS_IMAGE` to the format `archive://path/to/archive`:

- The `archive://` scheme prefix specifies that the analyzer is to scan an archive.
- `path/to/archive` specifies the path to the archive to scan, whether an absolute path or a relative path.

Container scanning supports tar image files following the [Docker Image Specification](https://github.com/moby/docker-image-spec).
OCI tarballs are not supported.
For more information regarding supported formats, see [Trivy tar file support](https://trivy.dev/v0.48/docs/target/container_image/#tar-files).

### Building supported tar files

Container scanning uses metadata from the tar file for image naming.
When building tar image files, ensure the image is tagged:

```shell
# Pull or build an image with a name and a tag
docker pull image:latest
# OR
docker build . -t image:latest
# Then export to tar using docker save
docker save image:latest -o image-latest.tar

# Or build an image with a tag using buildx build
docker buildx create --name container --driver=docker-container
docker buildx build -t image:latest --builder=container -o type=docker,dest=- . > image-latest.tar

# With podman
podman build -t image:latest .
podman save -o image-latest.tar image:latest
```

### Image name

Container scanning determines the image name by first evaluating the archive's `manifest.json` and using the first item in `RepoTags`.
If this is not found, `index.json` is used to fetch the `io.containerd.image.name` annotation. If this is not found, the archive filename
is used instead.

- `manifest.json` is defined in [Docker Image Specification v1.1.0](https://github.com/moby/docker-image-spec/blob/v1.1.0/v1.1.md#combined-image-json--filesystem-changeset-format)
  and created by using the command `docker save`.
- `index.json` format is defined in the [OCI image specification v1.1.1](https://github.com/opencontainers/image-spec/blob/v1.1.1/spec.md).
  `io.containerd.image.name` is [available in containerd v1.3.0 and later](https://github.com/containerd/containerd/blob/v1.3.0/images/annotations.go)
  when using `ctr image export`.

### Scanning archives built in a previous job

To scan an archive built in a CI/CD job, you must pass the archive artifact from the build job to the container scanning job.
Use the [`artifacts:paths`](../../../ci/yaml/_index.md#artifactspaths) and [`dependencies`](../../../ci/yaml/_index.md#dependencies) keywords to pass artifacts from one job to a following one:

```yaml
build_job:
  script:
    - docker build . -t image:latest
    - docker save image:latest -o image-latest.tar
  artifacts:
    paths:
      - "image-latest.tar"

container_scanning:
  variables:
    CS_IMAGE: "archive://image-latest.tar"
  dependencies:
    - build_job
```

### Scanning archives from the project repository

To scan an archive found in your project repository, ensure that your [Git strategy](../../../ci/runners/configure_runners.md#git-strategy) enables access to your repository.
Set the `GIT_STRATEGY` keyword to either `clone` or `fetch` in the `container_scanning` job because it is set to `none` by default.

```yaml
container_scanning:
  variables:
    GIT_STRATEGY: fetch
```

## Running the standalone container scanning tool

It's possible to run the [GitLab container scanning tool](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning)
against a Docker container without needing to run it within the context of a CI job. To scan an
image directly, follow these steps:

1. Run Docker Desktop or Docker Machine.

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

The container scanning tool emits JSON reports which the GitLab Runner recognizes through the
`artifacts:reports` keyword in the CI/CD configuration file.

After the CI/CD job finishes, the runner uploads these reports to GitLab, which are then available in
the CI/CD job artifacts. In GitLab Ultimate, these reports can be viewed in the corresponding
pipeline and the vulnerability report.

These reports must comply with the
[container scanning report schema](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/container-scanning-report-format.json).

[Example container scanning report](https://gitlab.com/gitlab-examples/security/security-reports/-/blob/master/samples/container-scanning.json).

### CycloneDX Software Bill of Materials

In addition to the JSON report file, the container scanning tool outputs a
[CycloneDX](https://cyclonedx.org/) Software Bill of Materials (SBOM) for the scanned image. This
CycloneDX SBOM is named `gl-sbom-report.cdx.json` and is saved in the same directory as the `JSON report file`. This feature is only supported when the Trivy analyzer is used.

This report can be viewed in the [dependency list](../dependency_list/_index.md).

You can download CycloneDX SBOMs [the same way as other job artifacts](../../../ci/jobs/job_artifacts.md#download-job-artifacts).

#### License Information in CycloneDX Reports

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/472064) in GitLab 18.0.

{{< /history >}}

Container scanning can include license information in CycloneDX reports. This feature is disabled by default to maintain backward compatibility.

To enable license scanning in your container scanning results:

- Set the `CS_INCLUDE_LICENSES` variable in your `.gitlab-ci.yml` file:

```yaml
container_scanning:
  variables:
    CS_INCLUDE_LICENSES: "true"
```

- After enabling this feature, the generated CycloneDX report will include license information for components detected in your container images.

- You can view this license information in the dependency list page or as part of the downloadable CycloneDX job artifact.

It is important to mention that only SPDX licenses are supported. However, licenses that are non-compliant with SPDX will still be ingested without any user-facing error.

## End-of-life operating system detection

Container scanning includes the ability to detect and report when your container images are using operating systems that have reached their end-of-life (EOL). Operating systems that have reached EOL no longer receive security updates, leaving them vulnerable to newly discovered security issues.

The EOL detection feature uses Trivy to identify operating systems that are no longer supported by their respective distributions. When an EOL operating system is detected, it's reported as a vulnerability in your container scanning report alongside other security findings.

To enable EOL detection, set `CS_REPORT_OS_EOL` to `"true"`.

## Container Scanning for Registry

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/2340) in GitLab 17.1 [with a flag](../../../administration/feature_flags/_index.md) named `enable_container_scanning_for_registry`. Disabled by default.
- [Enabled on GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/443827) in GitLab 17.2.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/443827) in GitLab 17.2. Feature flag `enable_container_scanning_for_registry` removed.

{{< /history >}}

When a container image is pushed with the `latest` tag, a container scanning job is automatically triggered by the security policy bot in a new pipeline against the default branch.

Unlike regular container scanning, the scan results do not include a security report. Instead, Container Scanning for Registry relies on [continuous vulnerability scanning](../continuous_vulnerability_scanning/_index.md) to inspect the components detected by the scan.

When security findings are identified, GitLab populates the vulnerability report with these findings. Vulnerabilities can be viewed under the **Container registry vulnerabilities** tab of the vulnerability report page.

{{< alert type="note" >}}

Container Scanning for Registry populates the vulnerability report only when a new advisory is published to the [GitLab advisory database](../gitlab_advisory_database/_index.md). Support for populating the vulnerability report with all present advisory data, instead of only newly-detected data, is proposed in [epic 11219](https://gitlab.com/groups/gitlab-org/-/epics/11219).

{{< /alert >}}

### Prerequisites

- You must have at least the Maintainer role in a project to enable Container Scanning for Registry.
- The project being used must not be empty. If you are utilizing an empty project solely for storing container images, this feature won't function as intended. As a workaround, ensure the project contains an initial commit on the default branch.
- By default there is a limit of `50` scans per project per day.
- You must [configure container registry notifications](../../../administration/packages/container_registry.md#configure-container-registry-notifications).
- You must [configure the Package Metadata Database](../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync). This is configured by default on GitLab.com.

### Enabling Container Scanning for Registry

To enable Container Scanning for the GitLab Container Registry:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Secure** > **Security configuration**.
1. Scroll down to the **Container Scanning For Registry** section and turn on the toggle.

### Use with offline or air-gapped environments

To use container scanning for registry in an offline or air-gapped environment, you must use a local copy of the container scanning analyzer image. Because this feature is managed by the GitLab Security Policy Bot, the analyzer image cannot be configured by editing the `.gitlab-ci.yml` file.

Instead, you must override the default scanner image by setting the `CS_ANALYZER_IMAGE` CI/CD
variable in the GitLab UI. The dynamically-created scanning job inherits variables defined in the
UI. You can use a project, group, or instance CI/CD variable.

To configure a custom scanner image:

1. On the left sidebar, select **Search or go to** and find your project or group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **CI/CD**.
1. Expand the **Variables** section.
1. Select **Add variable** and fill in the details:
   - Key: `CS_ANALYZER_IMAGE`
   - Value: The full URL to your mirrored container scanning image. For example, `my.local.registry:5000/analyzers/container-scanning:7`.
1. Select **Add variable**.

The GitLab Security Policy Bot will use the specified image when it triggers a scan.

## Vulnerabilities database

All analyzer images are [updated daily](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/blob/master/README.md#image-updates).

The images use data from upstream advisory databases:

- AlmaLinux Security Advisory
- Amazon Linux Security Center
- Arch Linux Security Tracker
- SUSE CVRF
- CWE Advisories
- Debian Security Bug Tracker
- GitHub Security Advisory
- Go Vulnerability Database
- CBL-Mariner Vulnerability Data
- NVD
- OSV
- Red Hat OVAL v2
- Red Hat Security Data API
- Photon Security Advisories
- Rocky Linux UpdateInfo
- Ubuntu CVE Tracker (only data sources from mid 2021 and later)

In addition to the sources provided by these scanners, GitLab maintains the following vulnerability databases:

- The proprietary [GitLab advisory database](https://gitlab.com/gitlab-org/security-products/gemnasium-db).
- The open source [GitLab advisory database (Open Source Edition)](https://gitlab.com/gitlab-org/advisories-community).

In the GitLab Ultimate tier, the data from the GitLab advisory database is merged in to augment the
data from the external sources. In the GitLab Premium and Free tiers, the data from the GitLab
Advisory Database (Open Source Edition) is merged in to augment the data from the external sources.
This augmentation only applies to the analyzer images for the Trivy scanner.

Database update information for other analyzers is available in the
[maintenance table](../detect/vulnerability_scanner_maintenance.md).

## Solutions for vulnerabilities (auto-remediation)

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Some vulnerabilities can be fixed by applying the solution that GitLab
automatically generates.

To enable remediation support, the scanning tool must have access to the `Dockerfile` specified by
the CI/CD variable`CS_DOCKERFILE_PATH`. To ensure that the scanning tool
has access to this
file, it's necessary to set [`GIT_STRATEGY: fetch`](../../../ci/runners/configure_runners.md#git-strategy) in
your `.gitlab-ci.yml` file by following the instructions described in this document's
[overriding the container scanning template](#overriding-the-container-scanning-template) section.

Read more about the [solutions for vulnerabilities](../vulnerabilities/_index.md#resolve-a-vulnerability).
