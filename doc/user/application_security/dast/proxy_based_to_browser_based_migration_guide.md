---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrating from the DAST proxy-based analyzer to DAST version 5
---

> - The [DAST proxy-based analyzer](proxy-based.md) was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/430966) in GitLab 16.6 and removed in 17.0.

[DAST version 5](browser/_index.md) replaces the proxy-based analyzer with a browser-based analyzer. This document serves as a guide to
migrate from the proxy-based analyzer to DAST version 5.

Follow this migration guide if all the following conditions apply:

1. You use GitLab DAST to run a DAST scan in a CI/CD pipeline.
1. The DAST CI/CD job is configured by including either of the DAST templates `DAST.gitlab-ci.yml` or `DAST.latest.gitlab-ci.yml`.
1. The CI/CD variable `DAST_VERSION` is not set or is set to `4` or less.
1. The CI/CD variable `DAST_BROWSER_SCAN` is not set or is set to `false`.

Migrate to DAST version 5 by reading the following sections and making the recommended changes.

## DAST analyzer versions

DAST comes in two major versions: 4 and 5.
Effective from GitLab 17.0 the DAST templates `DAST.gitlab-ci.yml` and `DAST.latest.gitlab-ci.yml` use DAST version 5 by default.
You can continue using DAST version 4, but you should do so only as an interim measure while migrating to DAST version 5. For details, see [Continuing to use the proxy-based analyzer](#continuing-to-use-the-proxy-based-analyzer).

Each DAST major version uses different analyzers by default:

- DAST version 4 uses the proxy-based analyzer.
- DAST version 5 uses the browser-based analyzer.

DAST version 5 uses a set of new CI/CD variables. Aliases have been created for the DAST version 4 variables' names.

Changes to make:

- To test your DAST scan using DAST version 5 in GitLab 16.11 and earlier, set the CI/CD variable `DAST_VERSION` to `5`.

## Continuing to use the proxy-based analyzer

You can use the proxy-based DAST analyzer until GitLab 18.0. Bugs and vulnerabilities in this legacy analyzer will not be fixed.

Changes to make:

- To continue using the proxy-based analyzer, set the CI/CD variable `DAST_VERSION` variable to `4`.

## Artifacts

GitLab 17.0 automatically publishes artifacts produced by DAST version 5 to the DAST CI job.

Changes to make:

- Remove `artifacts` from the CI job definition if you have overridden it to expose the file log, crawl graph, or authentication report.
- CI/CD variables `DAST_BROWSER_FILE_LOG_PATH` and `DAST_FILE_LOG_PATH` are no longer required.

## Authentication

The proxy-based analyzer and DAST version 5 both use the browser-based analyzer to authenticate. Upgrading
to DAST version 5 does not change how authentication works.

Changes to make:

- Rename authentication CI/CD variables, see variables with the `DAST_AUTH` prefix.
- If not already done, exclude the logout URL from the scan using `DAST_SCOPE_EXCLUDE_URLS`.

## Crawling

DAST version 5 crawls the target application in a browser to provide better crawl coverage. This may require
more resources to run than an equivalent proxy-based analyzer crawl.

Changes to make:

- Use `DAST_TARGET_URL` instead of `DAST_WEBSITE`.
- Use `DAST_CRAWL_TIMEOUT` instead of `DAST_SPIDER_MINS`.
- CI/CD variables `DAST_USE_AJAX_SPIDER`, `DAST_SPIDER_START_AT_HOST`, `DAST_ZAP_CLI_OPTIONS`
  and `DAST_ZAP_LOG_CONFIGURATION` are no longer supported.
- Configure `DAST_PAGE_MAX_RESPONSE_SIZE_MB` if DAST should process response bodies larger than 10 MB.
- Consider providing more CPU resources to the GitLab Runner executing the DAST job.

## Scope

DAST version 5 provides more control over scope compared to the proxy-based analyzer.

Changes to make:

- Use `DAST_SCOPE_ALLOW_HOSTS` instead of `DAST_ALLOWED_HOSTS`.
- The domain of `DAST_TARGET_URL` is automatically added to `DAST_SCOPE_ALLOW_HOSTS`, consider adding domains for the
  target application API and asset endpoints.
- Remove domains from the scan by adding them to `DAST_SCOPE_EXCLUDE_HOSTS` (except during authentication).

## Vulnerability checks

### Changes required

DAST version 5 uses vulnerability definitions built by GitLab, these do not map directly to proxy-based
analyzer definitions.

Changes to make:

- Use `DAST_CHECKS_TO_RUN` instead of `DAST_ONLY_INCLUDE_RULES`. Change the IDs used to GitLab DAST vulnerability check IDs.
- Use `DAST_CHECKS_TO_EXCLUDE` instead of `DAST_EXCLUDE_RULES`. Change the IDs used to GitLab DAST vulnerability check IDs.
- See [vulnerability check](browser/checks/_index.md) documentation for descriptions and IDs of GitLab DAST vulnerability checks.
- CI/CD variables `DAST_AGGREGATE_VULNERABILITIES` and `DAST_MAX_URLS_PER_VULNERABILITY` are no longer supported.

### Why migrating produces different vulnerabilities

Proxy-based scans and browser-based DAST version 5 scans do not produce the same results because they use a different set of vulnerability checks.

DAST version 5 does not have an equivalent for proxy-based checks that create too many false positives,
are not worth running because modern browsers don't allow the vulnerability to be exploited, or are no longer considered relevant.
DAST version 5 includes checks that proxy-based analyzer does not.

DAST version 5 scans provide better coverage of your application, so they may identify more vulnerabilities because more of your site is scanned.

### Coverage

One proxy-based active check is yet to be implemented in the browser-based DAST analyzer.
Migration of the remaining active check is proposed in
[epic 13411](https://gitlab.com/groups/gitlab-org/-/epics/13411). If you prefer to remain on DAST
version 4 until the last check is migrated, see [Continuing to use the proxy-based analyzer](#continuing-to-use-the-proxy-based-analyzer).

Remaining check:

- CWE-79: Cross-site Scripting (XSS)

## On-demand scans

On-demand scans runs a browser-based scan using [DAST version 5](https://gitlab.com/groups/gitlab-org/-/epics/11429) from GitLab 17.0.

## Troubleshooting

See the DAST version 5 [troubleshooting](browser/troubleshooting.md) documentation.

## Changes to CI/CD variables

The following table outlines migration actions required for each proxy-based analyzer CI/CD variable.
See [configuration](browser/configuration/_index.md) for more information on configuring DAST version 5.

| Proxy-based analyzer CI/CD variable  | Required action          | Notes                                                                                    |
|:-------------------------------------|:-------------------------|:-----------------------------------------------------------------------------------------|
| `DAST_ADVERTISE_SCAN`                | Rename                   | To `DAST_REQUEST_ADVERTISE_SCAN`                                                         |
| `DAST_ALLOWED_HOSTS`                 | Rename                   | To `DAST_SCOPE_ALLOW_HOSTS`                                                              |
| `DAST_API_HOST_OVERRIDE`             | Remove                   | Not supported                                                                            |
| `DAST_API_SPECIFICATION`             | Remove                   | Not supported                                                                            |
| `DAST_AUTH_EXCLUDE_URLS`             | Rename                   | To `DAST_SCOPE_EXCLUDE_URLS`                                                             |
| `DAST_AUTO_UPDATE_ADDONS`            | Remove                   | Not supported                                                                            |
| `DAST_BROWSER_FILE_LOG_PATH`         | Remove                   | No longer required                                                                       |
| `DAST_DEBUG`                         | Remove                   | Not supported                                                                            |
| `DAST_EXCLUDE_RULES`                 | Rename, update check IDs | To `DAST_CHECKS_TO_EXCLUDE`                                                              |
| `DAST_EXCLUDE_URLS`                  | Rename                   | To `DAST_SCOPE_EXCLUDE_URLS`                                                             |
| `DAST_FILE_LOG_PATH`                 | Remove                   | No longer required                                                                       |
| `DAST_FULL_SCAN_ENABLED`             | Rename                   | To `DAST_FULL_SCAN`                                                                      |
| `DAST_HTML_REPORT`                   | Remove                   | Not supported                                                                            |
| `DAST_INCLUDE_ALPHA_VULNERABILITIES` | Remove                   | Not supported                                                                            |
| `DAST_MARKDOWN_REPORT`               | Remove                   | Not supported                                                                            |
| `DAST_MASK_HTTP_HEADERS`             | Remove                   | Not supported                                                                            |
| `DAST_MAX_URLS_PER_VULNERABILITY`    | Remove                   | Not supported                                                                            |
| `DAST_ONLY_INCLUDE_RULES`            | Rename, update check IDs | To `DAST_CHECKS_TO_RUN`                                                                  |
| `DAST_PATHS`                         | None                     | Supported                                                                                |
| `DAST_PATHS_FILE`                    | None                     | Supported                                                                                |
| `DAST_PKCS12_CERTIFICATE_BASE64`     | None                     | Supported                                                                                |
| `DAST_PKCS12_PASSWORD`               | None                     | Supported                                                                                |
| `DAST_SKIP_TARGET_CHECK`             | None                     | Supported                                                                                |
| `DAST_SPIDER_MINS`                   | Change                   | To `DAST_CRAWL_TIMEOUT` using a duration. For example, instead of `5`, use `5m`          |
| `DAST_SPIDER_START_AT_HOST`          | Remove                   | Not supported                                                                            |
| `DAST_TARGET_AVAILABILITY_TIMEOUT`   | Change                   | To `DAST_TARGET_CHECK_TIMEOUT` using a duration. For example, instead of `60`, use `60s` |
| `DAST_USE_AJAX_SPIDER`               | Remove                   | Not supported                                                                            |
| `DAST_XML_REPORT`                    | Remove                   | Not supported                                                                            |
| `DAST_WEBSITE`                              | Rename             | To `DAST_TARGET_URL`<br/>Self-managed: Upgrade your instance to version 17.0 or newer before removing `DAST_WEBSITE`. This variable is required if you use the `DAST.gitlab-ci.yml` file included with pre-17.0 versions of GitLab. |
| `DAST_ZAP_CLI_OPTIONS`               | Remove                   | Not supported                                                                            |
| `DAST_ZAP_LOG_CONFIGURATION`         | Remove                   | Not supported                                                                            |
| `SECURE_ANALYZERS_PREFIX`            | None                     | Supported                                                                                |
