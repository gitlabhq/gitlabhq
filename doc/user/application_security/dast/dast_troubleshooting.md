---
stage: Secure
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting DAST proxy-based analyzer

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

The following troubleshooting scenarios have been collected from customer support cases. If you
experience a problem not addressed here, or the information here does not fix your problem, see the
[GitLab Support](https://about.gitlab.com/support/) page for ways to get help.

## Debugging DAST jobs

A DAST job has two executing processes:

- The ZAP server.
- A series of scripts that start, control and stop the ZAP server.

Enable the `DAST_DEBUG` CI/CD variable to debug scripts. This can help when troubleshooting the job,
and outputs statements indicating what percentage of the scan is complete.
For details on using variables, see [Overriding the DAST template](proxy-based.md#customize-dast-settings).

Debug mode of the ZAP server can be enabled using the `DAST_ZAP_LOG_CONFIGURATION` variable.
The following table outlines examples of values that can be set and the effect that they have on the output that is logged.
Multiple values can be specified, separated by semicolons.

For example, `log4j.logger.org.parosproxy.paros.network.HttpSender=DEBUG;log4j.logger.com.crawljax=DEBUG`.

| Log configuration value                                      | Effect                                                            |
|--------------------------------------------------            | ----------------------------------------------------------------- |
| `log4j.rootLogger=DEBUG`                                     | Enable all debug logging statements.                              |
| `log4j.logger.org.apache.commons.httpclient=DEBUG`           | Log every HTTP request and response made by the ZAP server.       |
| `log4j.logger.org.zaproxy.zap.spider.SpiderController=DEBUG` | Log URLs found during the spider scan of the target.              |
| `log4j.logger.com.crawljax=DEBUG`                            | Enable Ajax Crawler debug logging statements.                     |
| `log4j.logger.org.parosproxy.paros=DEBUG`                    | Enable ZAP server proxy debug logging statements.                 |
| `log4j.logger.org.zaproxy.zap=DEBUG`                         | Enable debug logging statements of the general ZAP server code.   |

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

For information on this, see the [general Application Security troubleshooting section](../../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload).

## Getting error `dast job: chosen stage does not exist` when including DAST CI template

To avoid overwriting stages from other CI files, newer versions of the DAST CI template do not
define stages. If you recently started using `DAST.latest.gitlab-ci.yml` or upgraded to a new major
release of GitLab and began receiving this error, you must define a `dast` stage with your other
stages. You must have a running application for DAST to scan. If your application is set
up in your pipeline, it must be deployed in a stage _before_ the `dast` stage:

```yaml
stages:
  - deploy  # DAST needs a running application to scan
  - dast

include:
  - template: DAST.latest.gitlab-ci.yml
```

## Getting error `shell not found` when using DAST CI/CD template

When including the DAST CI/CD template as described in the documentation, the job may fail, with an error like the following recorded in the job logs:

```shell
shell not found
```

To avoid this error, make sure you are using the latest stable version of Docker. More information is available in [issue 358847](https://gitlab.com/gitlab-org/gitlab/-/issues/358847).

## Lack of IPv6 support

Due to the underlying [ZAProxy engine not supporting IPv6](https://github.com/zaproxy/zaproxy/issues/3705), DAST is unable to scan or crawl IPv6-based applications.

## Additional insight into DAST scan activity

For additional insight into what a DAST scan is doing at a given time, you may find it helpful to review
the web server access logs for a DAST target endpoint during or following a scan.
