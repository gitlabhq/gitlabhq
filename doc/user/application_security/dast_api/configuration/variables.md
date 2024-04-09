---
stage: Secure
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Available CI/CD variables and configuration files

## Available CI/CD variables

| CI/CD variable                                       | Description        |
|------------------------------------------------------|--------------------|
| `SECURE_ANALYZERS_PREFIX`                            | Specify the Docker registry base address from which to download the analyzer. |
| `DAST_API_VERSION`                                   | Specify DAST API container version. Defaults to `3`. |
| `DAST_API_IMAGE_SUFFIX`                              | Specify a container image suffix. Defaults to none. |
| `DAST_API_API_PORT`                                  | Specify the communication port number used by DAST API engine. Defaults to `5500`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/367734) in GitLab 15.5. |
| `DAST_API_TARGET_URL`                                 | Base URL of API testing target. |
|[`DAST_API_CONFIG`](#configuration-files)              | DAST API configuration file. Defaults to `.gitlab-dast-api.yml`. |
|[`DAST_API_PROFILE`](#configuration-files)             | Configuration profile to use during testing. Defaults to `Quick`. |
|[`DAST_API_EXCLUDE_PATHS`](customizing_analyzer_settings.md#exclude-paths)              | Exclude API URL paths from testing. |
|[`DAST_API_EXCLUDE_URLS`](customizing_analyzer_settings.md#exclude-urls)               | Exclude API URL from testing. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/357195) in GitLab 14.10. |
|[`DAST_API_EXCLUDE_PARAMETER_ENV`](customizing_analyzer_settings.md#exclude-parameters)       | JSON string containing excluded parameters. |
|[`DAST_API_EXCLUDE_PARAMETER_FILE`](customizing_analyzer_settings.md#exclude-parameters)      | Path to a JSON file containing excluded parameters. |
|[`DAST_API_REQUEST_HEADERS`](customizing_analyzer_settings.md#request-headers)      | A comma-separated (`,`) list of headers to include on each scan request. Consider using `DAST_API_REQUEST_HEADERS_BASE64`  when storing secret header values in a [masked variable](../../../../ci/variables/index.md#mask-a-cicd-variable), which has character set restrictions. |
|[`DAST_API_REQUEST_HEADERS_BASE64`](customizing_analyzer_settings.md#request-headers)      | A comma-separated (`,`) list of headers to include on each scan request, Base64-encoded. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/378440) in GitLab 15.6. |
|[`DAST_API_OPENAPI`](enabling_the_analyzer.md#openapi-specification)           | OpenAPI specification file or URL. |
|[`DAST_API_OPENAPI_RELAXED_VALIDATION`](enabling_the_analyzer.md#openapi-specification) | Relax document validation. Default is disabled. Introduced in GitLab 14.7. GitLab team members can view more information in this confidential issue: `https://gitlab.com/gitlab-org/gitlab/-/issues/345950`  |
|[`DAST_API_OPENAPI_ALL_MEDIA_TYPES`](enabling_the_analyzer.md#openapi-specification)  | Use all supported media types instead of one when generating requests. Causes test duration to be longer. Default is disabled. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/333304) in GitLab 14.10. |
|[`DAST_API_OPENAPI_MEDIA_TYPES`](enabling_the_analyzer.md#openapi-specification)  | Colon (`:`) separated media types accepted for testing. Default is disabled. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/333304) in GitLab 14.10. |
|[`DAST_API_HAR`](enabling_the_analyzer.md#http-archive-har)                    | HTTP Archive (HAR) file. |
|[`DAST_API_GRAPHQL`](enabling_the_analyzer.md#graphql-schema)                  | Path to GraphQL endpoint, for example `/api/graphql`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352780) in GitLab 15.4. |
|[`DAST_API_GRAPHQL_SCHEMA`](enabling_the_analyzer.md#graphql-schema)           | A URL or filename for a GraphQL schema in JSON format. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352780) in GitLab 15.4. |
|[`DAST_API_POSTMAN_COLLECTION`](enabling_the_analyzer.md#postman-collection)   | Postman Collection file. |
|[`DAST_API_POSTMAN_COLLECTION_VARIABLES`](enabling_the_analyzer.md#postman-variables) | Path to a JSON file to extract Postman variable values. The support for comma-separated (`,`) files was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/356312) in GitLab 15.1. |
|[`DAST_API_OVERRIDES_FILE`](customizing_analyzer_settings.md#overrides)                | Path to a JSON file containing overrides. |
|[`DAST_API_OVERRIDES_ENV`](customizing_analyzer_settings.md#overrides)                 | JSON string containing headers to override. |
|[`DAST_API_OVERRIDES_CMD`](customizing_analyzer_settings.md#overrides)                 | Overrides command. |
|[`DAST_API_OVERRIDES_CMD_VERBOSE`](customizing_analyzer_settings.md#overrides)         | When set to any value. It shows overrides command output as part of the job output. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/334578) in GitLab 14.6. |
|`DAST_API_PRE_SCRIPT`                                  | Run user command or script before scan session starts. |
|`DAST_API_POST_SCRIPT`                                 | Run user command or script after scan session has finished. |
|[`DAST_API_OVERRIDES_INTERVAL`](customizing_analyzer_settings.md#overrides)            | How often to run overrides command in seconds. Defaults to `0` (once). |
|[`DAST_API_HTTP_USERNAME`](customizing_analyzer_settings.md#http-basic-authentication) | Username for HTTP authentication. |
|[`DAST_API_HTTP_PASSWORD`](customizing_analyzer_settings.md#http-basic-authentication) | Password for HTTP authentication. Consider using `DAST_API_HTTP_PASSWORD_BASE64` instead. |
|[`DAST_API_HTTP_PASSWORD_BASE64`](customizing_analyzer_settings.md#http-basic-authentication) | Password for HTTP authentication, base64-encoded. [Introduced](https://gitlab.com/gitlab-org/security-products/analyzers/api-fuzzing-src/-/merge_requests/702) in GitLab 15.4. |
|`DAST_API_SERVICE_START_TIMEOUT`                       | How long to wait for target API to become available in seconds. Default is 300 seconds. |
|`DAST_API_TIMEOUT`                                     | How long to wait for API responses in seconds. Default is 30 seconds. |

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
