---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Available CI/CD variables and configuration files
---

> - [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/450445) Changed template name from `DAST-API.gitlab-ci.yml` to `API-Security.gitlab-ci.yml` and variable prefixed from `DAST_API_` to `APISEC_` in GitLab 17.1.

## Available CI/CD variables

| CI/CD variable                                                                              | Description |
|---------------------------------------------------------------------------------------------|-------------|
| `SECURE_ANALYZERS_PREFIX`                                                                   | Specify the Docker registry base address from which to download the analyzer. |
| `APISEC_DISABLED`                                                                           | Set to 'true' or '1' to disable API security testing scanning. |
| `APISEC_DISABLED_FOR_DEFAULT_BRANCH`                                                        | Set to 'true' or '1' to disable API security testing scanning for only the default (production) branch. |
| `APISEC_VERSION`                                                                            | Specify API security testing container version. Defaults to `3`. |
| `APISEC_IMAGE_SUFFIX`                                                                       | Specify a container image suffix. Defaults to none. |
| `APISEC_API_PORT`                                                                           | Specify the communication port number used by API security testing engine. Defaults to `5500`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/367734) in GitLab 15.5. |
| `APISEC_TARGET_URL`                                                                         | Base URL of API testing target. |
| `APISEC_TARGET_CHECK_SKIP`                                                                  | Disable waiting for target to become available. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/442699) in GitLab 17.1. |
| `APISEC_TARGET_CHECK_STATUS_CODE`                                                           | Provide the expected status code for target availability check. If not provided, any non-500 status code is acceptable. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/442699) in GitLab 17.1. |
| [`APISEC_CONFIG`](#configuration-files)                                                     | API security testing configuration file. Defaults to `.gitlab-dast-api.yml`. |
| [`APISEC_PROFILE`](#configuration-files)                                                    | Configuration profile to use during testing. Defaults to `Quick`. |
| [`APISEC_EXCLUDE_PATHS`](customizing_analyzer_settings.md#exclude-paths)                    | Exclude API URL paths from testing. |
| [`APISEC_EXCLUDE_URLS`](customizing_analyzer_settings.md#exclude-urls)                      | Exclude API URL from testing. |
| [`APISEC_EXCLUDE_PARAMETER_ENV`](customizing_analyzer_settings.md#exclude-parameters)       | JSON string containing excluded parameters. |
| [`APISEC_EXCLUDE_PARAMETER_FILE`](customizing_analyzer_settings.md#exclude-parameters)      | Path to a JSON file containing excluded parameters. |
| [`APISEC_REQUEST_HEADERS`](customizing_analyzer_settings.md#request-headers)                | A comma-separated (`,`) list of headers to include on each scan request. Consider using `APISEC_REQUEST_HEADERS_BASE64` when storing secret header values in a [masked variable](../../../../ci/variables/_index.md#mask-a-cicd-variable), which has character set restrictions. |
| [`APISEC_REQUEST_HEADERS_BASE64`](customizing_analyzer_settings.md#request-headers)         | A comma-separated (`,`) list of headers to include on each scan request, Base64-encoded. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/378440) in GitLab 15.6. |
| [`APISEC_OPENAPI`](enabling_the_analyzer.md#openapi-specification)                          | OpenAPI specification file or URL. |
| [`APISEC_OPENAPI_RELAXED_VALIDATION`](enabling_the_analyzer.md#openapi-specification)       | Relax document validation. Default is disabled. |
| [`APISEC_OPENAPI_ALL_MEDIA_TYPES`](enabling_the_analyzer.md#openapi-specification)          | Use all supported media types instead of one when generating requests. Causes test duration to be longer. Default is disabled. |
| [`APISEC_OPENAPI_MEDIA_TYPES`](enabling_the_analyzer.md#openapi-specification)              | Colon (`:`) separated media types accepted for testing. Default is disabled. |
| [`APISEC_HAR`](enabling_the_analyzer.md#http-archive-har)                                   | HTTP Archive (HAR) file. |
| [`APISEC_GRAPHQL`](enabling_the_analyzer.md#graphql-schema)                                 | Path to GraphQL endpoint, for example `/api/graphql`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352780) in GitLab 15.4. |
| [`APISEC_GRAPHQL_SCHEMA`](enabling_the_analyzer.md#graphql-schema)                          | A URL or filename for a GraphQL schema in JSON format. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352780) in GitLab 15.4. |
| [`APISEC_POSTMAN_COLLECTION`](enabling_the_analyzer.md#postman-collection)                  | Postman Collection file. |
| [`APISEC_POSTMAN_COLLECTION_VARIABLES`](enabling_the_analyzer.md#postman-variables)         | Path to a JSON file to extract Postman variable values. The support for comma-separated (`,`) files was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/356312) in GitLab 15.1. |
| [`APISEC_OVERRIDES_FILE`](customizing_analyzer_settings.md#overrides)                       | Path to a JSON file containing overrides. |
| [`APISEC_OVERRIDES_ENV`](customizing_analyzer_settings.md#overrides)                        | JSON string containing headers to override. |
| [`APISEC_OVERRIDES_CMD`](customizing_analyzer_settings.md#overrides)                        | Overrides command. |
| [`APISEC_OVERRIDES_CMD_VERBOSE`](customizing_analyzer_settings.md#overrides)                | When set to any value. It logs overrides command output to the `gl-api-security-scanner.log` job artifact file. |
| `APISEC_PER_REQUEST_SCRIPT`                                                                 | Full path and filename for a per-request script. [See demo project for examples.](https://gitlab.com/gitlab-org/security-products/demos/api-dast/auth-with-request-example) [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13691) in GitLab 17.2. |
| `APISEC_PRE_SCRIPT`                                                                         | Run user command or script before scan session starts. `sudo` must be used for privileged operations like installing packages. |
| `APISEC_POST_SCRIPT`                                                                        | Run user command or script after scan session has finished. `sudo` must be used for privileged operations like installing packages. |
| [`APISEC_OVERRIDES_INTERVAL`](customizing_analyzer_settings.md#overrides)                   | How often to run overrides command in seconds. Defaults to `0` (once). |
| [`APISEC_HTTP_USERNAME`](customizing_analyzer_settings.md#http-basic-authentication)        | Username for HTTP authentication. |
| [`APISEC_HTTP_PASSWORD`](customizing_analyzer_settings.md#http-basic-authentication)        | Password for HTTP authentication. Consider using `APISEC_HTTP_PASSWORD_BASE64` instead. |
| [`APISEC_HTTP_PASSWORD_BASE64`](customizing_analyzer_settings.md#http-basic-authentication) | Password for HTTP authentication, base64-encoded. [Introduced](https://gitlab.com/gitlab-org/security-products/analyzers/api-fuzzing-src/-/merge_requests/702) in GitLab 15.4. |
| `APISEC_SERVICE_START_TIMEOUT`                                                              | How long to wait for target API to become available in seconds. Default is 300 seconds. |
| `APISEC_TIMEOUT`                                                                            | How long to wait for API responses in seconds. Default is 30 seconds. |
| `APISEC_SUCCESS_STATUS_CODES`                                                               | Specify a comma-separated (`,`) list of HTTP success status codes that determine whether an API security testing scanning job has passed. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/442219) in GitLab 17.1. Example: `'200, 201, 204'` |

## Configuration files

To get you started quickly, GitLab provides the configuration file
[`gitlab-dast-api-config.yml`](https://gitlab.com/gitlab-org/security-products/analyzers/dast/-/blob/master/config/gitlab-dast-api-config.yml).
This file has several testing profiles that perform various numbers of tests. The run time of each
profile increases as the test numbers go up. To use a configuration file, add it to your
repository's root as `.gitlab/gitlab-dast-api-config.yml`.

### Profiles

The following profiles are pre-defined in the default configuration file. Profiles
can be added, removed, and modified by creating a custom configuration.

#### Passive

- Application Information Check
- Cleartext Authentication Check
- JSON Hijacking Check
- Sensitive Information Check
- Session Cookie Check

#### Quick

- Application Information Check
- Cleartext Authentication Check
- FrameworkDebugModeCheck
- HTML Injection Check
- Insecure Http Methods Check
- JSON Hijacking Check
- JSON Injection Check
- Sensitive Information Check
- Session Cookie Check
- SQL Injection Check
- Token Check
- XML Injection Check

#### Full

- Application Information Check
- Cleartext AuthenticationCheck
- CORS Check
- DNS Rebinding Check
- Framework Debug Mode Check
- HTML Injection Check
- Insecure Http Methods Check
- JSON Hijacking Check
- JSON Injection Check
- Open Redirect Check
- Sensitive File Check
- Sensitive Information Check
- Session Cookie Check
- SQL Injection Check
- TLS Configuration Check
- Token Check
- XML Injection Check
