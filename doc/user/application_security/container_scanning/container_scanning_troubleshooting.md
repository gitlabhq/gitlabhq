---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting container scanning
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

When working with container scanning, you might encounter the following issues.

## Enable verbose logging

Enable verbose output when you need to see in detail what the container scanning job does. For details, see
[debug-level logging](../troubleshooting_application_security.md#debug-level-logging).

## `docker: Error response from daemon: failed to copy xattrs`

When the runner uses the `docker` executor and NFS is used
(for example, `/var/lib/docker` is on an NFS mount), container scanning might fail with
an error like the following:

```plaintext
docker: Error response from daemon: failed to copy xattrs: failed to set xattr "security.selinux" on /path/to/file: operation not supported.
```

This error is a result of a bug in Docker which is now [fixed](https://github.com/containerd/continuity/pull/138 "fs: add WithAllowXAttrErrors CopyOpt").
To prevent the error, ensure the Docker version that the runner is using is
`18.09.03` or higher. For more information, see
[issue #10241](https://gitlab.com/gitlab-org/gitlab/-/issues/10241 "Investigate why container scanning is not working with NFS mounts").

## Error: `gl-container-scanning-report.json: no matching files`

For information on this, see the [general Application Security troubleshooting section](../../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload).

## Error: `unexpected status code 401 Unauthorized: Not Authorized`

This error might occur when you scan an image from AWS ECR and the AWS region is not configured.
The scanner cannot retrieve an authorization token.
When you set `SECURE_LOG_LEVEL` to `debug` you will see a log message like the following:

```shell
[35mDEBUG[0m failed to get authorization token: MissingRegion: could not find region configuration
```

To resolve this, add the `AWS_DEFAULT_REGION` to your CI/CD variables:

```yaml
variables:
  AWS_DEFAULT_REGION: <AWS_REGION_FOR_ECR>
```

## Error: `unable to open a file: open /home/gitlab/.cache/trivy/ee/db/metadata.json`

The compressed Trivy database is stored in the `/tmp` folder of the container and it is extracted to `/home/gitlab/.cache/trivy/{ee|ce}/db` at runtime. This error can happen if you have a volume mount for `/tmp` directory in your runner configuration.

To resolve this issue, instead of binding the `/tmp` folder, bind specific files or folders in `/tmp` (for example `/tmp/myfile.txt`).

## Error: `context deadline exceeded`

This error means a timeout occurred. To resolve it, add the `TRIVY_TIMEOUT` environment variable to the `container_scanning` job with a sufficiently long duration.

## No vulnerabilities detected on images based on an old image

Trivy does not scan operating system images that are no longer receiving any updates.

Making this visible in the UI is proposed in [issue 433325](https://gitlab.com/gitlab-org/gitlab/-/issues/433325).

## Expected vulnerabilities not detected

Trivy does not report [language-specific findings](_index.md#report-language-specific-findings)
by default which may result in an empty report when the image does not have any
vulnerable operating system dependencies. To enable language-specific findings,
follow the steps in the linked documentation and re-run the scan.

## Container scanning v6.x: outdated vulnerability database error

Using container scanning with `registry.gitlab.com/security-products/container-scanning/grype:6` and `registry.gitlab.com/security-products/container-scanning/grype:6-fips` analyzer images may fail with an outdated vulnerability database error, for example:

`1 error occurred: * the vulnerability database was built 6 days ago (max allowed age is 5 days)`

This happens when one of the container scanning images above is copied to a user's own repository and not updated to the image (images are rebuilt daily).
