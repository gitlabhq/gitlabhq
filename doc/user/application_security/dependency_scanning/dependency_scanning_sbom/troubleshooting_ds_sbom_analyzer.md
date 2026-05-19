---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Troubleshooting dependency scanning SBOM analyzer
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

When working with the dependency scanning SBOM analyzer, you might encounter the following issues.

## `403 Forbidden` error when you use a custom `CI_JOB_TOKEN`

The dependency scanning SBOM API might return a `403 Forbidden` error during the scan upload or download phase.

This happens because the dependency scanning SBOM API requires the default `CI_JOB_TOKEN` for authentication.
If you override the `CI_JOB_TOKEN` variable with a custom token (such as a project access token or personal access token),
the API cannot authenticate the request properly, even if the custom token has the `api` scope.

To resolve this issue, either:

- Recommended. Remove the `CI_JOB_TOKEN` override. Overriding predefined variables can cause unexpected behavior.
  See [CI/CD variables](../../../../ci/variables/_index.md#use-pipeline-variables) for more information.
- Use a different variable name. If you need to use a custom token for other purposes in your pipeline, store it in a different CI/CD variable, like `CUSTOM_ACCESS_TOKEN`,
  instead of overriding `CI_JOB_TOKEN`.

GitLab does not support [fine-grained job permissions](../../../../ci/jobs/fine_grained_permissions.md) for dependency scanning API endpoints, but [issue 578850](https://gitlab.com/gitlab-org/gitlab/-/issues/578850) proposes to add this feature.

## Warning: `grep: command not found`

The analyzer image contains minimal dependencies to decrease the image's attack surface.
As a result, utilities commonly found in other images, like `grep`, are missing from the image.
This may result in a warning like `/usr/bin/bash: line 3: grep: command not found` to appear in
the job log. This warning does not impact the results of the analyzer and can be ignored.

## Compliance framework compatibility

When using SBOM-based dependency scanning on GitLab Self-Managed instances, there are compatibility considerations with compliance frameworks:

- GitLab.com: The "Dependency scanning running" compliance control works correctly with SBOM-based dependency scanning.
- GitLab Self-Managed from 18.4: The "Dependency scanning running" compliance control may fail when using SBOM-based dependency scanning (`DS_ENFORCE_NEW_ANALYZER: 'true'`) because the traditional `gl-dependency-scanning-report.json` artifact is not generated.

Workaround for Self-Managed instances: If you need to pass compliance framework checks that require the "Dependency scanning running" control, you can use the `v2` template (`Jobs/Dependency-Scanning.v2.gitlab-ci.yml`) which generates both SBOM and dependency scanning reports

For more information about compliance controls, see [GitLab compliance controls](../../../compliance/compliance_frameworks/_index.md#gitlab-compliance-controls).

## Resolution job fails but dependency scanning still runs

Because resolution jobs run automatically they set `allow_failure: true`. If a resolution job fails, the
`dependency-scanning` job still runs. Depending on whether a lockfile is committed to the
repository, the scan either uses the committed file or falls back to
[manifest fallback](_index.md#manifest-fallback) if enabled.

Check [known limitations](_index.md#dependency-resolution-limitations) to verify if your use case is supported.

To investigate a resolution failure, check the CI/CD job log of the failing resolution job.
The log includes the output of the DS analyzer service container execution and the output
of the build tool commands. If the service log is not visible, you can set `CI_DEBUG_SERVICES` to `"true"`
to [capture service container logs](../../../../ci/services/_index.md#capturing-service-container-logs).

If necessary, you can [disable dependency resolution](_index.md#disable-dependency-resolution) and
use a manually generated lockfile instead.

## Dependency scanning job succeeds but produces no reports

If the dependency scanning job completes successfully but does not produce any SBOM or dependency
scanning report artifacts, the project likely does not contain any
[supported file](_index.md#supported-languages-and-files).

Check the CI/CD job log for a warning message similar to:

```plaintext
No compatible file found in <directory>.
```

To resolve this issue, add a supported lockfile or dependency graph export to your project. For instructions, see
[Create lockfile or dependency graph export manually](_index.md#create-lockfile-or-dependency-graph-export-manually).

## Dependency scanning job does not run when `DS_SKIP_IF_NO_SUPPORTED_FILES` is set

If `DS_SKIP_IF_NO_SUPPORTED_FILES` is set to `"true"` and the `dependency-scanning` job does not
appear in the pipeline, a [supported file](_index.md#supported-languages-and-files) was not detected in the project.

Some files that trigger a [dependency resolution](_index.md#dependency-resolution) job might not
trigger the dependency scanning job because they are not supported. For example, `settings.gradle`,
`setup.cfg`, `pyproject.toml`, or `requirements.in` are not supported directly.

To resolve this issue, do one of the following:

- Set `DS_SKIP_IF_NO_SUPPORTED_FILES` to `"false"` or leave it unset so the dependency scanning
  job runs unconditionally.
- Commit a [supported file](_index.md#supported-languages-and-files) to the repository, for example
  a generated lockfile or dependency graph export.

## Error: `failed to verify certificate: x509: certificate signed by unknown authority`

When the dependency scanning analyzer connects to a host the following error might occur. The cause of this
error is that the certificate used by the dependency scanning analyzer is not trusted by the host.

```plaintext
failed to verify certificate: x509: certificate signed by unknown authority
```

To resolve this issue, provide the self-signed certificate in the `ADDITIONAL_CA_CERT_BUNDLE` CI/CD variable.
This certificate will then be used by the dependency scanning analyzer when connecting to the host.

The value of the `ADDITIONAL_CA_CERT_BUNDLE` environment variable must be the certificate itself:

```yaml
include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

dependency-scanning:
  variables:
    ADDITIONAL_CA_CERT_BUNDLE: |
      -----BEGIN CERTIFICATE-----
      <...>
      -----END CERTIFICATE-----
  before_script:
    - echo "$ADDITIONAL_CA_CERT_BUNDLE" > /tmp/cacert.pem
    - export SSL_CERT_FILE="/tmp/cacert.pem"
```

## Only dependency scanning runs in merge request pipelines, other jobs appear skipped

By default, the `Dependency-Scanning.v2.gitlab-ci.yml` template runs the dependency scanning job in
merge request pipelines. If your project does not use merge request pipelines for other jobs, this
causes only the dependency scanning job to appear in the merge request pipeline, while all other
jobs run in a separate branch pipeline. To disable this behavior, see
[Disable MR pipelines for dependency scanning](_index.md#disable-merge-request-pipelines-for-dependency-scanning).
