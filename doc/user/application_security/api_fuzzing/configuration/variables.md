---
stage: Secure
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Available CI/CD variables

| CI/CD variable                                              | Description |
|-------------------------------------------------------------|-------------|
| `SECURE_ANALYZERS_PREFIX`                                   | Specify the Docker registry base address from which to download the analyzer. |
| `FUZZAPI_VERSION`                                           | Specify API Fuzzing container version. Defaults to `3`. |
| `FUZZAPI_IMAGE_SUFFIX`                                      | Specify a container image suffix. Defaults to none. |
| `FUZZAPI_API_PORT`                                          | Specify the communication port number used by API Fuzzing engine. Defaults to `5500`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/367734) in GitLab 15.5. |
| `FUZZAPI_TARGET_URL`                                        | Base URL of API testing target. |
| `FUZZAPI_CONFIG`                                            | [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/276395) in GitLab 13.12, replaced with default `.gitlab/gitlab-api-fuzzing-config.yml`. API Fuzzing configuration file. |
|[`FUZZAPI_PROFILE`](customizing_analyzer_settings.md#api-fuzzing-profiles)                   | Configuration profile to use during testing. Defaults to `Quick-10`. |
|[`FUZZAPI_EXCLUDE_PATHS`](customizing_analyzer_settings.md#exclude-paths)                    | Exclude API URL paths from testing. |
|[`FUZZAPI_EXCLUDE_URLS`](customizing_analyzer_settings.md#exclude-urls)                      | Exclude API URL from testing. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/357195) in GitLab 14.10. |
|[`FUZZAPI_EXCLUDE_PARAMETER_ENV`](customizing_analyzer_settings.md#exclude-parameters)       | JSON string containing excluded parameters. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/292196) in GitLab 14.10. |
|[`FUZZAPI_EXCLUDE_PARAMETER_FILE`](customizing_analyzer_settings.md#exclude-parameters)      | Path to a JSON file containing excluded parameters. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/292196) in GitLab 14.10. |
|[`FUZZAPI_OPENAPI`](enabling_the_analyzer.md#openapi-specification)                  | OpenAPI Specification file or URL. |
|[`FUZZAPI_OPENAPI_RELAXED_VALIDATION`](enabling_the_analyzer.md#openapi-specification) | Relax document validation. Default is disabled. Introduced in GitLab 14.7. GitLab team members can view more information in this confidential issue: `https://gitlab.com/gitlab-org/gitlab/-/issues/345950`. |
|[`FUZZAPI_OPENAPI_ALL_MEDIA_TYPES`](enabling_the_analyzer.md#openapi-specification)  | Use all supported media types instead of one when generating requests. Causes test duration to be longer. Default is disabled. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/333304) in GitLab 14.10. |
|[`FUZZAPI_OPENAPI_MEDIA_TYPES`](enabling_the_analyzer.md#openapi-specification)  | Colon (`:`) separated media types accepted for testing. Default is disabled. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/333304) in GitLab 14.10. |
|[`FUZZAPI_HAR`](enabling_the_analyzer.md#http-archive-har)                           | HTTP Archive (HAR) file. |
|[`FUZZAPI_GRAPHQL`](enabling_the_analyzer.md#graphql-schema)                         | Path to GraphQL endpoint, for example `/api/graphql`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352780) in GitLab 15.4. |
|[`FUZZAPI_GRAPHQL_SCHEMA`](enabling_the_analyzer.md#graphql-schema)                  | A URL or filename for a GraphQL schema in JSON format. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352780) in GitLab 15.4. |
|[`FUZZAPI_POSTMAN_COLLECTION`](enabling_the_analyzer.md#postman-collection)          | Postman Collection file. |
|[`FUZZAPI_POSTMAN_COLLECTION_VARIABLES`](enabling_the_analyzer.md#postman-variables) | Path to a JSON file to extract Postman variable values. The support for comma-separated (`,`) files was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/356312) in GitLab 15.1. |
|[`FUZZAPI_OVERRIDES_FILE`](customizing_analyzer_settings.md#overrides)                       | Path to a JSON file containing overrides. |
|[`FUZZAPI_OVERRIDES_ENV`](customizing_analyzer_settings.md#overrides)                        | JSON string containing headers to override. |
|[`FUZZAPI_OVERRIDES_CMD`](customizing_analyzer_settings.md#overrides)                        | Overrides command. |
|[`FUZZAPI_OVERRIDES_CMD_VERBOSE`](customizing_analyzer_settings.md#overrides)                | When set to any value. It shows overrides command output as part of the job output. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/334578) in GitLab 14.8. |
|`FUZZAPI_PRE_SCRIPT`                                         | Run user command or script before scan session starts. |
|`FUZZAPI_POST_SCRIPT`                                        | Run user command or script after scan session has finished. |
|[`FUZZAPI_OVERRIDES_INTERVAL`](customizing_analyzer_settings.md#overrides)                   | How often to run overrides command in seconds. Defaults to `0` (once). |
|[`FUZZAPI_HTTP_USERNAME`](customizing_analyzer_settings.md#http-basic-authentication)        | Username for HTTP authentication. |
|[`FUZZAPI_HTTP_PASSWORD`](customizing_analyzer_settings.md#http-basic-authentication)        | Password for HTTP authentication. |
|[`FUZZAPI_HTTP_PASSWORD_BASE64`](customizing_analyzer_settings.md#http-basic-authentication) | Password for HTTP authentication, Base64-encoded. [Introduced](https://gitlab.com/gitlab-org/security-products/analyzers/api-fuzzing-src/-/merge_requests/702) in GitLab 15.4. |
