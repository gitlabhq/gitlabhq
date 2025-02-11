---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Web API Fuzz Testing
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Web API fuzzing performs fuzz testing of API operation parameters. Fuzz testing sets operation
parameters to unexpected values in an effort to cause unexpected behavior and errors in the API
backend. This helps you discover bugs and potential security issues that other QA processes may
miss.

You should use fuzz testing in addition to the other security scanners in [GitLab Secure](../_index.md)
and your own test processes. If you're using [GitLab CI/CD](../../../ci/_index.md),
you can run fuzz tests as part your CI/CD workflow.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Web API Fuzzing](https://www.youtube.com/watch?v=oUHsfvLGhDk).

## When Web API fuzzing runs

Web API fuzzing runs in the `fuzz` stage of the CI/CD pipeline. To ensure API fuzzing scans the
latest code, your CI/CD pipeline should deploy changes to a test environment in one of the stages
preceding the `fuzz` stage.

If your pipeline is configured to deploy to the same web server on each run, running a
pipeline while another is still running could cause a race condition in which one pipeline
overwrites the code from another. The API to scan should be excluded from changes for the duration
of a fuzzing scan. The only changes to the API should be from the fuzzing scanner. Any changes made
to the API (for example, by users, scheduled tasks, database changes, code changes, other pipelines,
or other scanners) during a scan could cause inaccurate results.

You can run a Web API fuzzing scan using the following methods:

- [OpenAPI Specification](configuration/enabling_the_analyzer.md#openapi-specification) - version 2, and 3.
- [GraphQL Schema](configuration/enabling_the_analyzer.md#graphql-schema)
- [HTTP Archive](configuration/enabling_the_analyzer.md#http-archive-har) (HAR)
- [Postman Collection](configuration/enabling_the_analyzer.md#postman-collection) - version 2.0 or 2.1

Example projects using these methods are available:

- [Example OpenAPI v2 Specification project](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing-example/-/tree/openapi)
- [Example HTTP Archive (HAR) project](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing-example/-/tree/har)
- [Example Postman Collection project](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/postman-api-fuzzing-example)
- [Example GraphQL project](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/graphql-api-fuzzing-example)
- [Example SOAP project](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/soap-api-fuzzing-example)
- [Authentication Token using Selenium](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/auth-token-selenium)

## Get support or request an improvement

To get support for your particular problem use the [getting help channels](https://about.gitlab.com/get-help/).

The [GitLab issue tracker on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues) is the right place for bugs and feature proposals about API Security and API Fuzzing.
Use `~"Category:API Security"` [label](../../../development/labels/_index.md) when opening a new issue regarding API fuzzing to ensure it is quickly reviewed by the right people. Refer to our [review response SLO](https://handbook.gitlab.com/handbook/engineering/workflow/code-review/#review-response-slo) to understand when you should receive a response.

[Search the issue tracker](https://gitlab.com/gitlab-org/gitlab/-/issues) for similar entries before submitting your own, there's a good chance somebody else had the same issue or feature proposal. Show your support with an emoji reaction or join the discussion.

When experiencing a behavior not working as expected, consider providing contextual information:

- GitLab version if using a self-managed instance.
- `.gitlab-ci.yml` job definition.
- Full job console output.
- Scanner log file available as a job artifact named `gl-api-security-scanner.log`.

WARNING:
**Sanitize data attached to a support issue**. Remove sensitive information, including: credentials, passwords, tokens, keys, and secrets.

## Glossary

- Assert: Assertions are detection modules used by checks to trigger a fault. Many assertions have
  configurations. A check can use multiple Assertions. For example, Log Analysis, Response Analysis,
  and Status Code are common Assertions used together by checks. Checks with multiple Assertions
  allow them to be turned on and off.
- Check: Performs a specific type of test, or performed a check for a type of vulnerability. For
  example, the JSON Fuzzing Check performs fuzz testing of JSON payloads. The API fuzzer is
  comprised of several checks. Checks can be turned on and off in a profile.
- Fault: During fuzzing, a failure identified by an Assert is called a fault. Faults are
  investigated to determine if they are a security vulnerability, a non-security issue, or a false
  positive. Faults don't have a known vulnerability type until they are investigated. Example
  vulnerability types are SQL Injection and Denial of Service.
- Profile: A configuration file has one or more testing profiles, or sub-configurations. You may
  have a profile for feature branches and another with extra testing for a main branch.
