---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: API security testing analyzer
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - API security testing analyzer [became the default analyzer for on-demand API security testing scans](https://gitlab.com/groups/gitlab-org/-/epics/4254) in GitLab 15.6.
> - [Renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/457449) from **DAST API analyzer** to **API security testing analyzer** in GitLab 17.0.

Perform Dynamic Application Security Testing (DAST) of web APIs to help discover bugs and potential
security issues that other QA processes may miss. Use API security testing in addition to
other [GitLab Secure](../_index.md) security scanners and your own test processes. You can run DAST
API tests either as part your CI/CD workflow, [on-demand](../dast/on-demand_scan.md), or both.

WARNING:
Do not run API security testing against a production server. Not only can it perform _any_ function that
the API can, it may also trigger bugs in the API. This includes actions like modifying and deleting
data. Only run API security testing against a test server.

API security testing can test the following web API types:

- REST API
- SOAP
- GraphQL
- Form bodies, JSON, or XML

NOTE:
DAST API has been re-branded to API Security Testing. As part of this re-branding the template
name and variable prefixes have also been updated. The old template and variable names continue to work until the next major release, 18.0 in May 2025.

## When API security testing scans run

When run in your CI/CD pipeline, API security testing scanning runs in the `dast` stage by default. To ensure
API security testing scanning examines the latest code, ensure your CI/CD pipeline deploys changes to a test
environment in a stage before the `dast` stage.

If your pipeline is configured to deploy to the same web server on each run, running a pipeline
while another is still running could cause a race condition in which one pipeline overwrites the
code from another. The API to be scanned should be excluded from changes for the duration of a
API security testing scan. The only changes to the API should be from the API security testing scanner. Changes made to the
API (for example, by users, scheduled tasks, database changes, code changes, other pipelines, or
other scanners) during a scan could cause inaccurate results.

## Example API security testing scanning configurations

The following projects demonstrate API security testing scanning:

- [Example OpenAPI v3 Specification project](https://gitlab.com/gitlab-org/security-products/demos/api-dast/openapi-v3-example)
- [Example OpenAPI v2 Specification project](https://gitlab.com/gitlab-org/security-products/demos/api-dast/openapi-example)
- [Example HTTP Archive (HAR) project](https://gitlab.com/gitlab-org/security-products/demos/api-dast/har-example)
- [Example Postman Collection project](https://gitlab.com/gitlab-org/security-products/demos/api-dast/postman-example)
- [Example GraphQL project](https://gitlab.com/gitlab-org/security-products/demos/api-dast/graphql-example)
- [Example SOAP project](https://gitlab.com/gitlab-org/security-products/demos/api-dast/soap-example)
- [Authentication Token using Selenium](https://gitlab.com/gitlab-org/security-products/demos/api-dast/auth-token-selenium)

## Get support or request an improvement

To get support for your particular problem, use the [getting help channels](https://about.gitlab.com/get-help/).

The [GitLab issue tracker on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues) is the right place for bugs and feature proposals about API Security and API security testing.
Use `~"Category:API Security"` [label](../../../development/labels/_index.md) when opening a new issue regarding API security testing to ensure it is quickly reviewed by the right people. Refer to our [review response SLO](https://handbook.gitlab.com/handbook/engineering/workflow/code-review/#review-response-slo) to understand when you should receive a response.

[Search the issue tracker](https://gitlab.com/gitlab-org/gitlab/-/issues) for similar entries before submitting your own, there's a good chance somebody else had the same issue or feature proposal. Show your support with an emoji reaction or join the discussion.

When experiencing a behavior not working as expected, consider providing contextual information:

- GitLab version if using a self-managed instance.
- `.gitlab-ci.yml` job definition.
- Full job console output.
- Scanner log file available as a job artifact named `gl-api-security-scanner.log`.

WARNING:
**Sanitize data attached to a support issue**. Remove sensitive information, including: credentials, passwords, tokens, keys, and secrets.

## Glossary

- Assert: Assertions are detection modules used by checks to trigger a vulnerability. Many assertions have
  configurations. A check can use multiple Assertions. For example, Log Analysis, Response Analysis,
  and Status Code are common Assertions used together by checks. Checks with multiple Assertions
  allow them to be turned on and off.
- Check: Performs a specific type of test, or performed a check for a type of vulnerability. For
  example, the SQL Injection Check performs DAST testing for SQL Injection vulnerabilities. The API security testing scanner is comprised of several checks. Checks can be turned on and off in a profile.
- Profile: A configuration file has one or more testing profiles, or sub-configurations. You may
  have a profile for feature branches and another with extra testing for a main branch.
