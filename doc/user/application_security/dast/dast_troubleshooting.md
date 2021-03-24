---
stage: Secure
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
---

# Dynamic Application Security Testing (DAST) Troubleshooting **(ULTIMATE)**

The following troubleshooting scenarios have been collected from customer support cases. If you
experience a problem not addressed here, or the information here does not fix your problem, create a
support ticket. For more details, see the [GitLab Support](https://about.gitlab.com/support/) page.

## Running out of memory

By default, ZAProxy, which DAST relies on, is allocated memory that sums to 25%
of the total memory on the host.
Since it keeps most of its information in memory during a scan,
it's possible for DAST to run out of memory while scanning large applications.
This results in the following error:

```plaintext
[zap.out] java.lang.OutOfMemoryError: Java heap space
```

Fortunately, it's straightforward to increase the amount of memory available
for DAST by using the `DAST_ZAP_CLI_OPTIONS` CI/CD variable:

```yaml
include:
  - template: DAST.gitlab-ci.yml

variables:
  DAST_ZAP_CLI_OPTIONS: "-Xmx3072m"
```

This example allocates 3072 MB to DAST.
Change the number after `-Xmx` to the required memory amount.

## DAST job exceeding the job timeout

If your DAST job exceeds the job timeout and you need to reduce the scan duration, we shared some
tips for optimizing DAST scans in a [blog post](https://about.gitlab.com/blog/2020/08/31/how-to-configure-dast-full-scans-for-complex-web-applications/).

## Getting warning message `gl-dast-report.json: no matching files`

For information on this, see the [general Application Security troubleshooting section](../../../ci/pipelines/job_artifacts.md#error-message-no-files-to-upload).

## Getting error `dast job: chosen stage does not exist` when including DAST CI template

To avoid overwriting stages from other CI files, newer versions of the DAST CI template do not
define stages. If you recently started using `DAST.latest.gitlab-ci.yml` or upgraded to a new major
release of GitLab and began receiving this error, you must define a `dast` stage with your other
stages. Note that you must have a running application for DAST to scan. If your application is set
up in your pipeline, it must be deployed in a stage _before_ the `dast` stage:

```yaml
stages:
  - deploy  # DAST needs a running application to scan
  - dast

include:
  - template: DAST.latest.gitlab-ci.yml
```
