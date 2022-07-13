---
stage: Secure
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
---

# Web API Fuzz Testing **(ULTIMATE)**

Web API fuzzing performs fuzz testing of API operation parameters. Fuzz testing sets operation
parameters to unexpected values in an effort to cause unexpected behavior and errors in the API
backend. This helps you discover bugs and potential security issues that other QA processes may
miss.

We recommend that you use fuzz testing in addition to [GitLab Secure](../index.md)'s
other security scanners and your own test processes. If you're using [GitLab CI/CD](../../../ci/index.md),
you can run fuzz tests as part your CI/CD workflow.

## When Web API fuzzing runs

Web API fuzzing runs in the `fuzz` stage of the CI/CD pipeline. To ensure API fuzzing scans the
latest code, your CI/CD pipeline should deploy changes to a test environment in one of the stages
preceding the `fuzz` stage.

Note the following changes have been made to the API fuzzing template:

- In GitLab 14.0 and later, you must define a `fuzz` stage in your `.gitlab-ci.yml` file.
- In GitLab 13.12 and earlier, the API fuzzing template defines `build`, `test`, `deploy`, and
  `fuzz` stages. The `fuzz` stage runs last by default. The predefined stages were deprecated, and removed from the `API-Fuzzing.latest.gitlab-ci.yml` template. They will be removed in a future GitLab
  version.

If your pipeline is configured to deploy to the same web server on each run, running a
pipeline while another is still running could cause a race condition in which one pipeline
overwrites the code from another. The API to scan should be excluded from changes for the duration
of a fuzzing scan. The only changes to the API should be from the fuzzing scanner. Any changes made
to the API (for example, by users, scheduled tasks, database changes, code changes, other pipelines,
or other scanners) during a scan could cause inaccurate results.

You can run a Web API fuzzing scan using the following methods:

- [OpenAPI Specification](#openapi-specification) - version 2, and 3.
- [HTTP Archive](#http-archive-har) (HAR)
- [Postman Collection](#postman-collection) - version 2.0 or 2.1

Example projects using these methods are available:

- [Example OpenAPI v2 Specification project](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing-example/-/tree/openapi)
- [Example HTTP Archive (HAR) project](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing-example/-/tree/har)
- [Example Postman Collection project](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/postman-api-fuzzing-example)
- [Example GraphQL project](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/graphql-api-fuzzing-example)
- [Example SOAP project](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/soap-api-fuzzing-example)

## Enable Web API fuzzing

Requirements:

- One of the following web API types:
  - REST API
  - SOAP
  - GraphQL
  - Form bodies, JSON, or XML
- One of the following assets to provide APIs to test:
  - OpenAPI v2 or v3 API definition
  - HTTP Archive (HAR) of API requests to test
  - Postman Collection v2.0 or v2.1

  WARNING:
  **Never** run fuzz testing against a production server. Not only can it perform *any* function that
  the API can, it may also trigger bugs in the API. This includes actions like modifying and deleting
  data. Only run fuzzing against a test server.

To enable Web API fuzzing:

- Include the API fuzzing template in your `.gitlab-ci.yml` file.
- From GitLab 13.10 and later, use the Web API fuzzing configuration form.

- For manual configuration instructions, see the respective section, depending on the API type:
  - [OpenAPI Specification](#openapi-specification)
  - [HTTP Archive (HAR)](#http-archive-har)
  - [Postman Collection](#postman-collection)
- Otherwise, see [Web API fuzzing configuration form](#web-api-fuzzing-configuration-form).

In GitLab 14.0 and later, API fuzzing configuration files must be in your repository's
`.gitlab` directory instead of your repository's root.

### Web API fuzzing configuration form

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/299234) in GitLab 13.10.

The API fuzzing configuration form helps you create or modify your project's API fuzzing
configuration. The form lets you choose values for the most common API fuzzing options and builds
a YAML snippet that you can paste in your GitLab CI/CD configuration.

#### Configure Web API fuzzing in the UI

To generate an API Fuzzing configuration snippet:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Security & Compliance > Configuration**.
1. In the **API Fuzzing** row, select **Enable API Fuzzing**.
1. Complete the fields. For details see [Available CI/CD variables](#available-cicd-variables).
1. Select **Generate code snippet**.
   A modal opens with the YAML snippet corresponding to the options you've selected in the form.
1. Do one of the following:
   1. To copy the snippet to your clipboard, select **Copy code only**.
   1. To add the snippet to your project's `.gitlab-ci.yml` file, select
      **Copy code and open `.gitlab-ci.yml` file**. The Pipeline Editor opens.
      1. Paste the snippet into the `.gitlab-ci.yml` file.
      1. Select the **Lint** tab to confirm the edited `.gitlab-ci.yml` file is valid.
      1. Select the **Edit** tab, then select **Commit changes**.

When the snippet is committed to the `.gitlab-ci.yml` file, pipelines include an API Fuzzing job.

### OpenAPI Specification

> - Support for OpenAPI Specification v3.0 was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/228652) in GitLab 13.9.
> - Support for OpenAPI Specification using YAML format was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/330583) in GitLab 14.0.
> - Support for OpenAPI Specification v3.1 was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/327268) in GitLab 14.2.
> - Support to generate media type `application/xml` was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/327268) in GitLab 14.8.
> - Support to select media types was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/333304) in GitLab 14.10.

The [OpenAPI Specification](https://www.openapis.org/) (formerly the Swagger Specification) is an API description format for REST APIs.
This section shows you how to configure API fuzzing using an OpenAPI Specification to provide information about the target API to test.
OpenAPI Specifications are provided as a file system resource or URL. Both JSON and YAML OpenAPI formats are supported.

API fuzzing uses an OpenAPI document to generate the request body. When a request body is required,
the body generation is limited to these body types:

- `application/x-www-form-urlencoded`
- `multipart/form-data`
- `application/json`
- `application/xml`

### OpenAPI and media types

A media type (formerly known as MIME type) is an identifier for file formats and format contents transmitted. A OpenAPI document lets you specify that a given operation can accept different media types, hence a given request can send data using different file content. As for example, a `PUT /user` operation to update user data could accept data in either XML (media type `application/xml`) or JSON (media type `application/json`) format.
OpenAPI 2.x lets you specify the accepted media types globally or per operation, and OpenAPI 3.x lets you specify the accepted media types per operation. API Fuzzing checks the listed media types and tries to produce sample data for each supported media type.

- In [GitLab 14.10 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/333304), the default behavior is to select one of the supported media types to use. The first supported media type is chosen from the list. This behavior is configurable.
- In GitLab 14.9 and earlier, the default behavior is to perform testing using all supported media types. This means if two media types are listed (for example, `application/json` and `application/xml`), tests are performed using JSON, and then the same tests using XML.

Testing the same operation (for example, `POST /user`) using different media types (for example, `application/json` and `application/xml`) is not always desirable.
For example, if the target application executes the same code regardless of the request content type, it will take longer to finish the test session, and it may report duplicate vulnerabilities related to the request body depending on the target app.

The environment variable `FUZZAPI_OPENAPI_ALL_MEDIA_TYPES` lets you specify whether or not to use all supported media types instead of one when generating requests for a given operation. When the environmental variable `FUZZAPI_OPENAPI_ALL_MEDIA_TYPES` is set to any value, API Fuzzing will try to generate requests for all supported media types instead of one in a given operation. This will cause testing to take longer as testing is repeated for each provided media type.

Alternatively, the variable `FUZZAPI_OPENAPI_MEDIA_TYPES` is used to provide a list of media types that will each be tested. Providing more than one media type causes testing to take longer, as testing is performed for each media type selected. When the environment variable `FUZZAPI_OPENAPI_MEDIA_TYPES` is set to a list of media types, only the listed media types are included when creating requests.

Multiple media types in `FUZZAPI_OPENAPI_MEDIA_TYPES` must separated by a colon (`:`). For example, to limit request generation to the media types `application/x-www-form-urlencoded` and  `multipart/form-data`, set the environment variable `FUZZAPI_OPENAPI_MEDIA_TYPES` to `application/x-www-form-urlencoded:multipart/form-data`. Only supported media types in this list are included when creating requests, though unsupported media types are always skipped. A media type text may contain different sections. For example, `application/vnd.api+json; charset=UTF-8` is a compound of `type "/" [tree "."] subtype ["+" suffix]* [";" parameter]`. Parameters are not taken into account when filtering media types on request generation.

The environment variables `FUZZAPI_OPENAPI_ALL_MEDIA_TYPES` and `FUZZAPI_OPENAPI_MEDIA_TYPES` allow you to decide how to handle media types. These settings are mutually exclusive. If both are enabled, API Fuzzing reports an error.

#### Configure Web API fuzzing with an OpenAPI Specification

To configure API fuzzing in GitLab with an OpenAPI Specification:

1. Add the `fuzz` stage to your `.gitlab-ci.yml` file.

1. [Include](../../../ci/yaml/index.md#includetemplate)
   the [`API-Fuzzing.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml)
   in your `.gitlab-ci.yml` file.

1. Provide the profile by adding the `FUZZAPI_PROFILE` CI/CD variable to your `.gitlab-ci.yml` file.
   The profile specifies how many tests are run. Substitute `Quick-10` for the profile you choose. For more details, see [API fuzzing profiles](#api-fuzzing-profiles).

   ```yaml
   variables:
     FUZZAPI_PROFILE: Quick-10
   ```

1. Provide the location of the OpenAPI Specification. You can provide the specification as a file
   or URL. Specify the location by adding the `FUZZAPI_OPENAPI` variable.

1. Provide the target API instance's base URL. Use either the `FUZZAPI_TARGET_URL` variable or an
   `environment_url.txt` file.

   Adding the URL in an `environment_url.txt` file at your project's root is great for testing in
   dynamic environments. To run API fuzzing against an application dynamically created during a
   GitLab CI/CD pipeline, have the application persist its URL in an `environment_url.txt` file.
   API fuzzing automatically parses that file to find its scan target. You can see an
   example of this in the [Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml).

Example `.gitlab-ci.yml` file using an OpenAPI Specification:

   ```yaml
   stages:
     - fuzz

   include:
     - template: API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
     FUZZAPI_OPENAPI: test-api-specification.json
     FUZZAPI_TARGET_URL: http://test-deployment/
   ```

This is a minimal configuration for API Fuzzing. From here you can:

- [Run your first scan](#running-your-first-scan).
- [Add authentication](#authentication).
- Learn how to [handle false positives](#handling-false-positives).

For details of API fuzzing configuration options, see [Available CI/CD variables](#available-cicd-variables).

### HTTP Archive (HAR)

The [HTTP Archive format (HAR)](http://www.softwareishard.com/blog/har-12-spec/)
is an archive file format for logging HTTP transactions. When used with the GitLab API fuzzer, HAR
must contain records of calling the web API to test. The API fuzzer extracts all the requests and
uses them to perform testing.

For more details, including how to create a HAR file, see [HTTP Archive format](create_har_files.md).

WARNING:
HAR files may contain sensitive information such as authentication tokens, API keys, and session
cookies. We recommend that you review the HAR file contents before adding them to a repository.

#### Configure Web API fuzzing with a HAR file

To configure API fuzzing to use a HAR file:

1. Add the `fuzz` stage to your `.gitlab-ci.yml` file.

1. [Include](../../../ci/yaml/index.md#includetemplate)
   the [`API-Fuzzing.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml)
   in your `.gitlab-ci.yml` file.

1. Provide the profile by adding the `FUZZAPI_PROFILE` CI/CD variable to your `.gitlab-ci.yml` file.
   The profile specifies how many tests are run. Substitute `Quick-10` for the profile you choose. For more details, see [API fuzzing profiles](#api-fuzzing-profiles).

   ```yaml
   variables:
     FUZZAPI_PROFILE: Quick-10
   ```

1. Provide the location of the HAR specification. You can provide the specification as a file
   or URL. URL support was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/285020)
   in GitLab 13.10 and later. Specify the location by adding the `FUZZAPI_HAR` variable.

1. The target API instance's base URL is also required. Provide it by using the `FUZZAPI_TARGET_URL`
   variable or an `environment_url.txt` file.

   Adding the URL in an `environment_url.txt` file at your project's root is great for testing in
   dynamic environments. To run API fuzzing against an app dynamically created during a GitLab CI/CD
   pipeline, have the app persist its domain in an `environment_url.txt` file. API fuzzing
   automatically parses that file to find its scan target. You can see an
   [example of this in our Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml).

Example `.gitlab-ci.yml` file using a HAR file:

   ```yaml
   stages:
     - fuzz

   include:
     - template: API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
     FUZZAPI_HAR: test-api-recording.har
     FUZZAPI_TARGET_URL: http://test-deployment/
   ```

This is a minimal configuration for API fuzzing. From here you can:

- [Run your first scan](#running-your-first-scan).
- [Add authentication](#authentication).
- Learn how to [handle false positives](#handling-false-positives).

For details of API fuzzing configuration options, see [Available CI/CD variables](#available-cicd-variables).

### Postman Collection

The [Postman API Client](https://www.postman.com/product/api-client/) is a popular tool that
developers and testers use to call various types of APIs. The API definitions
[can be exported as a Postman Collection file](https://learning.postman.com/docs/getting-started/importing-and-exporting-data/#exporting-postman-data)
for use with API Fuzzing. When exporting, make sure to select a supported version of Postman
Collection: v2.0 or v2.1.

When used with the GitLab API fuzzer, Postman Collections must contain definitions of the web API to
test with valid data. The API fuzzer extracts all the API definitions and uses them to perform
testing.

WARNING:
Postman Collection files may contain sensitive information such as authentication tokens, API keys,
and session cookies. We recommend that you review the Postman Collection file contents before adding
them to a repository.

#### Configure Web API fuzzing with a Postman Collection file

To configure API fuzzing to use a Postman Collection file:

1. Add the `fuzz` stage to your `.gitlab-ci.yml` file.

1. [Include](../../../ci/yaml/index.md#includetemplate)
   the [`API-Fuzzing.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml)
   in your `.gitlab-ci.yml` file.

1. Provide the profile by adding the `FUZZAPI_PROFILE` CI/CD variable to your `.gitlab-ci.yml` file.
   The profile specifies how many tests are run. Substitute `Quick-10` for the profile you choose. For more details, see [API fuzzing profiles](#api-fuzzing-profiles).

   ```yaml
   variables:
     FUZZAPI_PROFILE: Quick-10
   ```

1. Provide the location of the Postman Collection specification. You can provide the specification
   as a file or URL. URL support was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/285020)
   in GitLab 13.10 and later. Specify the location by adding the `FUZZAPI_POSTMAN_COLLECTION`
   variable.

1. Provide the target API instance's base URL. Use either the `FUZZAPI_TARGET_URL` variable or an
   `environment_url.txt` file.

   Adding the URL in an `environment_url.txt` file at your project's root is great for testing in
   dynamic environments. To run API fuzzing against an app dynamically created during a GitLab CI/CD
   pipeline, have the app persist its domain in an `environment_url.txt` file. API fuzzing
   automatically parses that file to find its scan target. You can see an
   [example of this in our Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml).

Example `.gitlab-ci.yml` file using a Postman Collection file:

   ```yaml
   stages:
     - fuzz

   include:
     - template: API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
     FUZZAPI_POSTMAN_COLLECTION: postman-collection_serviceA.json
     FUZZAPI_TARGET_URL: http://test-deployment/
   ```

This is a minimal configuration for API Fuzzing. From here you can:

- [Run your first scan](#running-your-first-scan).
- [Add authentication](#authentication).
- Learn how to [handle false positives](#handling-false-positives).

For details of API fuzzing configuration options, see [Available CI/CD variables](#available-cicd-variables).

#### Postman variables

Postman allows the developer to define placeholders that can be used in different parts of the
requests. These placeholders are called variables, as explained in the Postman documentation,
[Using variables](https://learning.postman.com/docs/sending-requests/variables/).
You can use variables to store and reuse values in your requests and scripts. For example, you can
edit the collection to add variables to the document:

![Edit collection variable tab View](img/api_fuzzing_postman_collection_edit_variable.png)

You can then use the variables in sections such as URL, headers, and others:

![Edit request using variables View](img/api_fuzzing_postman_request_edit.png)

Variables can be defined at different [scopes](https://learning.postman.com/docs/sending-requests/variables/#variable-scopes)
(for example, Global, Collection, Environment, Local, and Data). In this example, they're defined at
the Environment scope:

![Edit environment variables View](img/api_fuzzing_postman_environment_edit_variable.png)

When you export a Postman collection, only Postman collection variables are exported into the
Postman file. For example, Postman does not export environment-scoped variables into the Postman
file.

By default, the API fuzzer uses the Postman file to resolve Postman variable values. If a JSON file
is set in a GitLab CI/CD variable `FUZZAPI_POSTMAN_COLLECTION_VARIABLES`, then the JSON
file takes precedence to get Postman variable values.

WARNING:
Although Postman can export environment variables into a JSON file, the format is not compatible with the JSON expected by `FUZZAPI_POSTMAN_COLLECTION_VARIABLES`.

Here is an example of using `FUZZAPI_POSTMAN_COLLECTION_VARIABLES`:

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick-10
  FUZZAPI_POSTMAN_COLLECTION: postman-collection_serviceA.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_POSTMAN_COLLECTION_VARIABLES: variable-collection-dictionary.json
```

The file `variable-collection-dictionary.json` is a JSON document. This JSON is an object with
key-value pairs for properties. The keys are the variables' names, and the values are the variables'
values. For example:

   ```json
   {
      "base_url": "http://127.0.0.1/",
      "token": "Token 84816165151"
   }
   ```

## API fuzzing configuration

The API fuzzing behavior can be changed through CI/CD variables.

From GitLab 13.12 and later, the default API fuzzing configuration file is `.gitlab/gitlab-api-fuzzing-config.yml`. In GitLab 14.0 and later, API fuzzing configuration files must be in your repository's
`.gitlab` directory instead of your repository's root.

WARNING:
All customization of GitLab security scanning tools should be tested in a merge request before
merging these changes to the default branch. Failure to do so can give unexpected results,
including a large number of false positives.

### Authentication

Authentication is handled by providing the authentication token as a header or cookie. You can
provide a script that performs an authentication flow or calculates the token.

#### HTTP Basic Authentication

[HTTP basic authentication](https://en.wikipedia.org/wiki/Basic_access_authentication)
is an authentication method built in to the HTTP protocol and used in conjunction with
[transport layer security (TLS)](https://en.wikipedia.org/wiki/Transport_Layer_Security).
To use HTTP basic authentication, two CI/CD variables are added to your `.gitlab-ci.yml` file:

- `FUZZAPI_HTTP_USERNAME`: The username for authentication.
- `FUZZAPI_HTTP_PASSWORD`: The password for authentication.

For the password, we recommended that you [create a CI/CD variable](../../../ci/variables/index.md#custom-cicd-variables)
(for example, `TEST_API_PASSWORD`) set to the password. You can create CI/CD variables from the
GitLab projects page at **Settings > CI/CD**, in the **Variables** section. Use that variable
as the value for `FUZZAPI_HTTP_PASSWORD`:

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick-10
  FUZZAPI_HAR: test-api-recording.har
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_HTTP_USERNAME: testuser
  FUZZAPI_HTTP_PASSWORD: $TEST_API_PASSWORD
```

#### Bearer Tokens

Bearer tokens are used by several different authentication mechanisms, including OAuth2 and JSON Web
Tokens (JWT). Bearer tokens are transmitted using the `Authorization` HTTP header. To use bearer
tokens with API fuzzing, you need one of the following:

- A token that doesn't expire
- A way to generate a token that lasts the length of testing
- A Python script that API fuzzing can call to generate the token

##### Token doesn't expire

If the bearer token doesn't expire, use the `FUZZAPI_OVERRIDES_ENV` variable to provide it. This
variable's content is a JSON snippet that provides headers and cookies to add to API fuzzing's
outgoing HTTP requests.

Follow these steps to provide the bearer token with `FUZZAPI_OVERRIDES_ENV`:

1. [Create a CI/CD variable](../../../ci/variables/index.md#custom-cicd-variables),
   for example `TEST_API_BEARERAUTH`, with the value
   `{"headers":{"Authorization":"Bearer dXNlcm5hbWU6cGFzc3dvcmQ="}}` (substitute your token). You
   can create CI/CD variables from the GitLab projects page at **Settings > CI/CD**, in the
   **Variables** section.

1. In your `.gitlab-ci.yml` file, set `FUZZAPI_OVERRIDES_ENV` to the variable you just created:

   ```yaml
   stages:
     - fuzz

   include:
     - template: API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
     FUZZAPI_OPENAPI: test-api-specification.json
     FUZZAPI_TARGET_URL: http://test-deployment/
     FUZZAPI_OVERRIDES_ENV: $TEST_API_BEARERAUTH
   ```

1. To validate that authentication is working, run an API fuzzing test and review the fuzzing logs
   and the test API's application logs. See the [overrides section](#overrides) for more information about override commands.

##### Token generated at test runtime

If the bearer token must be generated and doesn't expire during testing, you can provide to API
fuzzing a file containing the token. A prior stage and job, or part of the API fuzzing job, can
generate this file.

API fuzzing expects to receive a JSON file with the following structure:

```json
{
  "headers" : {
    "Authorization" : "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  }
}
```

This file can be generated by a prior stage and provided to API fuzzing through the
`FUZZAPI_OVERRIDES_FILE` CI/CD variable.

Set `FUZZAPI_OVERRIDES_FILE` in your `.gitlab-ci.yml` file:

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_FILE: api-fuzzing-overrides.json
```

To validate that authentication is working, run an API fuzzing test and review the fuzzing logs and
the test API's application logs.

##### Token has short expiration

If the bearer token must be generated and expires prior to the scan's completion, you can provide a
program or script for the API fuzzer to execute on a provided interval. The provided script runs in
an Alpine Linux container that has Python 3 and Bash installed. If the Python script requires
additional packages, it must detect this and install the packages at runtime.

The script must create a JSON file containing the bearer token in a specific format:

```json
{
  "headers" : {
    "Authorization" : "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  }
}
```

You must provide three CI/CD variables, each set for correct operation:

- `FUZZAPI_OVERRIDES_FILE`: JSON file the provided command generates.
- `FUZZAPI_OVERRIDES_CMD`: Command that generates the JSON file.
- `FUZZAPI_OVERRIDES_INTERVAL`: Interval (in seconds) to run command.

For example:

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick-10
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_FILE: api-fuzzing-overrides.json
  FUZZAPI_OVERRIDES_CMD: renew_token.py
  FUZZAPI_OVERRIDES_INTERVAL: 300
```

To validate that authentication is working, run an API fuzzing test and review the fuzzing logs and
the test API's application logs.

### API fuzzing profiles

GitLab provides the configuration file
[`gitlab-api-fuzzing-config.yml`](https://gitlab.com/gitlab-org/security-products/analyzers/api-fuzzing/-/blob/master/gitlab-api-fuzzing-config.yml).
It contains several testing profiles that perform a specific numbers of tests. The runtime of each
profile increases as the number of tests increases.

| Profile   | Fuzz Tests (per parameter) |
|:----------|:---------------------------|
| Quick-10  | 10 |
| Medium-20 | 20 |
| Medium-50 | 50 |
| Long-100  | 100 |

### Available CI/CD variables

| CI/CD variable                                              | Description |
|-------------------------------------------------------------|-------------|
| `SECURE_ANALYZERS_PREFIX`                                   | Specify the Docker registry base address from which to download the analyzer. |
| `FUZZAPI_VERSION`                                           | Specify API Fuzzing container version. Defaults to `2`. |
| `FUZZAPI_IMAGE_SUFFIX`                                      | Specify a container image suffix. Defaults to none. |
| `FUZZAPI_TARGET_URL`                                        | Base URL of API testing target. |
| `FUZZAPI_CONFIG`                                            | [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/276395) in GitLab 13.12, replaced with default `.gitlab/gitlab-api-fuzzing-config.yml`. API Fuzzing configuration file. |
|[`FUZZAPI_PROFILE`](#api-fuzzing-profiles)                   | Configuration profile to use during testing. Defaults to `Quick-10`. |
|[`FUZZAPI_EXCLUDE_PATHS`](#exclude-paths)                    | Exclude API URL paths from testing. |
|[`FUZZAPI_EXCLUDE_URLS`](#exclude-urls)                      | Exclude API URL from testing. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/357195) in GitLab 14.10. |
|[`FUZZAPI_EXCLUDE_PARAMETER_ENV`](#exclude-parameters)       | JSON string containing excluded parameters. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/292196) in GitLab 14.10. |
|[`FUZZAPI_EXCLUDE_PARAMETER_FILE`](#exclude-parameters)      | Path to a JSON file containing excluded parameters. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/292196) in GitLab 14.10. |
|[`FUZZAPI_OPENAPI`](#openapi-specification)                  | OpenAPI Specification file or URL. |
|[`FUZZAPI_OPENAPI_RELAXED_VALIDATION`](#openapi-specification) | Relax document validation. Default is disabled. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/345950) in GitLab 14.7. |
|[`FUZZAPI_OPENAPI_ALL_MEDIA_TYPES`](#openapi-specification)  | Use all supported media types instead of one when generating requests. Causes test duration to be longer. Default is disabled. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/333304) in GitLab 14.10. |
|[`FUZZAPI_OPENAPI_MEDIA_TYPES`](#openapi-specification)  | Colon (`:`) separated media types accepted for testing. Default is disabled. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/333304) in GitLab 14.10. |
|[`FUZZAPI_HAR`](#http-archive-har)                           | HTTP Archive (HAR) file. |
|[`FUZZAPI_POSTMAN_COLLECTION`](#postman-collection)          | Postman Collection file. |
|[`FUZZAPI_POSTMAN_COLLECTION_VARIABLES`](#postman-variables) | Path to a JSON file to extract Postman variable values. |
|[`FUZZAPI_OVERRIDES_FILE`](#overrides)                       | Path to a JSON file containing overrides. |
|[`FUZZAPI_OVERRIDES_ENV`](#overrides)                        | JSON string containing headers to override. |
|[`FUZZAPI_OVERRIDES_CMD`](#overrides)                        | Overrides command. |
|[`FUZZAPI_OVERRIDES_CMD_VERBOSE`](#overrides)                | When set to any value. It shows overrides command output as part of the job output. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/334578) in GitLab 14.8. |
|`FUZZAPI_PRE_SCRIPT`                                         | Run user command or script before scan session starts. |
|`FUZZAPI_POST_SCRIPT`                                        | Run user command or script after scan session has finished. |
|[`FUZZAPI_OVERRIDES_INTERVAL`](#overrides)                   | How often to run overrides command in seconds. Defaults to `0` (once). |
|[`FUZZAPI_HTTP_USERNAME`](#http-basic-authentication)        | Username for HTTP authentication. |
|[`FUZZAPI_HTTP_PASSWORD`](#http-basic-authentication)        | Password for HTTP authentication. |

### Overrides

API Fuzzing provides a method to add or override specific items in your request, for example:

- Headers
- Cookies
- Query string
- Form data
- JSON nodes
- XML nodes

You can use this to inject semantic version headers, authentication, and so on. The
[authentication section](#authentication) includes examples of using overrides for that purpose.

Overrides use a JSON document, where each type of override is represented by a JSON object:

```json
{
  "headers": {
    "header1": "value",
    "header2": "value"
  },
  "cookies": {
    "cookie1": "value",
    "cookie2": "value"
  },
  "query":      {
    "query-string1": "value",
    "query-string2": "value"
  },
  "body-form":  {
    "form-param1": "value",
    "form-param2": "value"
  },
  "body-json":  {
    "json-path1": "value",
    "json-path2": "value"
  },
  "body-xml" :  {
    "xpath1":    "value",
    "xpath2":    "value"
  }
}
```

Example of setting a single header:

```json
{
  "headers": {
    "Authorization": "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  }
}
```

Example of setting both a header and cookie:

```json
{
  "headers": {
    "Authorization": "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  },
  "cookies": {
    "flags": "677"
  }
}
```

Example usage for setting a `body-form` override:

```json
{
  "body-form":  {
    "username": "john.doe"
  }
}
```

The override engine uses `body-form` when the request body has only form-data content.

Example usage for setting a `body-json` override:

```json
{
  "body-json":  {
    "$.credentials.access-token": "iddqd!42.$"
  }
}
```

Note that each JSON property name in the object `body-json` is set to a [JSON Path](https://goessner.net/articles/JsonPath/)
expression. The JSON Path expression `$.credentials.access-token` identifies the node to be
overridden with the value `iddqd!42.$`. The override engine uses `body-json` when the request body
has only [JSON](https://www.json.org/json-en.html) content.

For example, if the body is set to the following JSON:

```json
{
    "credentials" : {
        "username" :"john.doe",
        "access-token" : "non-valid-password"
    }
}
```

It is changed to:

```json
{
    "credentials" : {
        "username" :"john.doe",
        "access-token" : "iddqd!42.$"
    }
}
```

Here's an example for setting a `body-xml` override. The first entry overrides an XML attribute and
the second entry overrides an XML element:

```json
{
  "body-xml" :  {
    "/credentials/@isEnabled": "true",
    "/credentials/access-token/text()" : "iddqd!42.$"
  }
}
```

Note that each JSON property name in the object `body-xml` is set to an
[XPath v2](https://www.w3.org/TR/xpath20/)
expression. The XPath expression `/credentials/@isEnabled` identifies the attribute node to override
with the value `true`. The XPath expression `/credentials/access-token/text()` identifies the
element node to override with the value `iddqd!42.$`. The override engine uses `body-xml` when the
request body has only [XML](https://www.w3.org/XML/)
content.

For example, if the body is set to the following XML:

```xml
<credentials isEnabled="false">
  <username>john.doe</username>
  <access-token>non-valid-password</access-token>
</credentials>
```

It is changed to:

```xml
<credentials isEnabled="true">
  <username>john.doe</username>
  <access-token>iddqd!42.$</access-token>
</credentials>
```

You can provide this JSON document as a file or environment variable. You may also provide a command
to generate the JSON document. The command can run at intervals to support values that expire.

#### Using a file

To provide the overrides JSON as a file, the `FUZZAPI_OVERRIDES_FILE` CI/CD variable is set. The path is relative to the job current working directory.

Here's an example `.gitlab-ci.yml`:

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_FILE: api-fuzzing-overrides.json
```

#### Using a CI/CD variable

To provide the overrides JSON as a CI/CD variable, use the `FUZZAPI_OVERRIDES_ENV` variable.
This allows you to place the JSON as variables that can be masked and protected.

In this example `.gitlab-ci.yml`, the `FUZZAPI_OVERRIDES_ENV` variable is set directly to the JSON:

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_ENV: '{"headers":{"X-API-Version":"2"}}'
```

In this example `.gitlab-ci.yml`, the `SECRET_OVERRIDES` variable provides the JSON. This is a
[group or instance level CI/CD variable defined in the UI](../../../ci/variables/index.md#add-a-cicd-variable-to-an-instance):

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_ENV: $SECRET_OVERRIDES
```

#### Using a command

If the value must be generated or regenerated on expiration, you can provide a program or script for
the API fuzzer to execute on a specified interval. The provided script runs in an Alpine Linux
container that has Python 3 and Bash installed.

You have to set the environment variable `FUZZAPI_OVERRIDES_CMD` to the program or script you would like
to execute. The provided command creates the overrides JSON file as defined previously.

You might want to install other scripting runtimes like NodeJS or Ruby, or maybe you need to install a dependency for
your overrides command. In this case, we recommend setting the `FUZZAPI_PRE_SCRIPT` to the file path of a script which
provides those prerequisites. The script provided by `FUZZAPI_PRE_SCRIPT` is executed once, before the analyzer starts.

See the [Alpine Linux package management](https://wiki.alpinelinux.org/wiki/Alpine_Linux_package_management)
page for information about installing Alpine Linux packages.

You must provide three CI/CD variables, each set for correct operation:

- `FUZZAPI_OVERRIDES_FILE`: File generated by the provided command.
- `FUZZAPI_OVERRIDES_CMD`: Overrides command in charge of generating the overrides JSON file periodically.
- `FUZZAPI_OVERRIDES_INTERVAL`: Interval in seconds to run command.

Optionally:

- `FUZZAPI_PRE_SCRIPT`: Script to install runtimes or dependencies before the analyzer starts.

WARNING:
To execute scripts in Alpine Linux you must first use the command [`chmod`](https://www.gnu.org/software/coreutils/manual/html_node/chmod-invocation.html) to set the [execution permission](https://www.gnu.org/software/coreutils/manual/html_node/Setting-Permissions.html). For example, to set the execution permission of `script.py` for everyone, use the command: `chmod a+x script.py`. If needed, you can version your `script.py` with the execution permission already set.

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_FILE: api-fuzzing-overrides.json
  FUZZAPI_OVERRIDES_CMD: renew_token.py
  FUZZAPI_OVERRIDES_INTERVAL: 300
```

#### Debugging overrides

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/334578) in GitLab 14.8.

By default the output of the overrides command is hidden. If the overrides command returns a non zero exit code, the command is displayed as part of your job output. Optionally, you can set the variable `FUZZAPI_OVERRIDES_CMD_VERBOSE` to any value in order to display overrides command output as it is generated. This is useful when testing your overrides script, but should be disabled afterwards as it slows down testing.

It is also possible to write messages from your script to a log file that is collected when the job completes or fails. The log file must be created in a specific location and follow a naming convention.

Adding some basic logging to your overrides script is useful in case the script fails unexpectedly during normal running of the job. The log file is automatically included as an artifact of the job, allowing you to download it after the job has finished.

Following our example, we provided `renew_token.py` in the environmental variable `FUZZAPI_OVERRIDES_CMD`. Please notice two things in the script:

- Log file is saved in the location indicated by the environment variable `CI_PROJECT_DIR`.
- Log filename should match `gl-*.log`.

```python
#!/usr/bin/env python

# Example of an overrides command

# Override commands can update the overrides json file
# with new values to be used.  This is a great way to
# update an authentication token that will expire
# during testing.

import logging
import json
import os
import requests
import backoff

# [1] Store log file in directory indicated by env var CI_PROJECT_DIR
working_directory = os.environ.get( 'CI_PROJECT_DIR')
overrides_file_name = os.environ.get('FUZZAPI_OVERRIDES_FILE', 'api-fuzzing-overrides.json')
overrides_file_path = os.path.join(working_directory, overrides_file_name)

# [2] File name should match the pattern: gl-*.log
log_file_path = os.path.join(working_directory, 'gl-user-overrides.log')

# Set up logger
logging.basicConfig(filename=log_file_path, level=logging.DEBUG)

# Use `backoff` decorator to retry in case of transient errors.
@backoff.on_exception(backoff.expo,
                      (requests.exceptions.Timeout,
                       requests.exceptions.ConnectionError),
                       max_time=30)
def get_auth_response():
    authorization_url = 'https://authorization.service/api/get_api_token'
    return requests.get(
        f'{authorization_url}',
        auth=(os.environ.get('AUTH_USER'), os.environ.get('AUTH_PWD'))
    )

# In our example, access token is retrieved from a given endpoint
try:

    # Performs a http request, response sample:
    # { "Token" : "b5638ae7-6e77-4585-b035-7d9de2e3f6b3" }
    response = get_auth_response()

    # Check that the request is successful. may raise `requests.exceptions.HTTPError`
    response.raise_for_status()

    # Gets JSON data
    response_body = response.json()

# If needed specific exceptions can be caught
# requests.ConnectionError                  : A network connection error problem occurred
# requests.HTTPError                        : HTTP request returned an unsuccessful status code. [Response.raise_for_status()]
# requests.ConnectTimeout                   : The request timed out while trying to connect to the remote server
# requests.ReadTimeout                      : The server did not send any data in the allotted amount of time.
# requests.TooManyRedirects                 : The request exceeds the configured number of maximum redirections
# requests.exceptions.RequestException      : All exceptions that related to Requests
except json.JSONDecodeError as json_decode_error:
    # logs errors related decoding JSON response
    logging.error(f'Error, failed while decoding JSON response. Error message: {json_decode_error}')
    raise
except requests.exceptions.RequestException as requests_error:
    # logs  exceptions  related to `Requests`
    logging.error(f'Error, failed while performing HTTP request. Error message: {requests_error}')
    raise
except Exception as e:
    # logs any other error
    logging.error(f'Error, unknown error while retrieving access token. Error message: {e}')
    raise

# computes object that holds overrides file content.
# It uses data fetched from request
overrides_data = {
    "headers": {
        "Authorization": f"Token {response_body['Token']}"
    }
}

# log entry informing about the file override computation
logging.info("Creating overrides file: %s" % overrides_file_path)

# attempts to overwrite the file
try:
    if os.path.exists(overrides_file_path):
        os.unlink(overrides_file_path)

    # overwrites the file with our updated dictionary
    with open(overrides_file_path, "wb+") as fd:
        fd.write(json.dumps(overrides_data).encode('utf-8'))
except Exception as e:
    # logs any other error
    logging.error(f'Error, unknown error when overwriting file {overrides_file_path}. Error message: {e}')
    raise

# logs informing override has finished successfully
logging.info("Override file has been updated")

# end
```

In the overrides command example, the Python script depends on the `backoff` library. To make sure the library is installed before executing the Python script, the `FUZZAPI_PRE_SCRIPT` is set to a script that will install the dependencies of your overrides command.
As for example, the following script `user-pre-scan-set-up.sh`:

```shell
#!/bin/bash

# user-pre-scan-set-up.sh
# Ensures python dependencies are installed

echo "**** install python dependencies ****"

python3 -m ensurepip
pip3 install --no-cache --upgrade \
    pip \
    requests \
    backoff

echo "**** python dependencies installed ****"

# end
```

You have to update your configuration to set the `FUZZAPI_PRE_SCRIPT` to our new `user-pre-scan-set-up.sh` script. For example:

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_PRE_SCRIPT: user-pre-scan-set-up.sh
  FUZZAPI_OVERRIDES_FILE: api-fuzzing-overrides.json
  FUZZAPI_OVERRIDES_CMD: renew_token.py
  FUZZAPI_OVERRIDES_INTERVAL: 300
```

In the previous sample, you could use the script `user-pre-scan-set-up.sh` to also install new runtimes or applications that later on you could use in your overrides command.

### Exclude Paths

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/211892) in GitLab 14.0.

When testing an API it can be useful to exclude certain paths. For example, you might exclude testing of an authentication service or an older version of the API. To exclude paths, use the `FUZZAPI_EXCLUDE_PATHS` CI/CD variable . This variable is specified in your `.gitlab-ci.yml` file. To exclude multiple paths, separate entries using the `;` character. In the provided paths you can use a single character wildcard `?` and `*` for a multiple character wildcard.

To verify the paths are excluded, review the `Tested Operations` and `Excluded Operations` portion of the job output. You should not see any excluded paths listed under `Tested Operations`.

```plaintext
2021-05-27 21:51:08 [INF] API Security: --[ Tested Operations ]-------------------------
2021-05-27 21:51:08 [INF] API Security: 201 POST http://target:7777/api/users CREATED
2021-05-27 21:51:08 [INF] API Security: ------------------------------------------------
2021-05-27 21:51:08 [INF] API Security: --[ Excluded Operations ]-----------------------
2021-05-27 21:51:08 [INF] API Security: GET http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API Security: POST http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API Security: ------------------------------------------------
```

#### Examples of excluding paths

This example excludes the `/auth` resource. This does not exclude child resources (`/auth/child`).

```yaml
variables:
  FUZZAPI_EXCLUDE_PATHS=/auth
```

To exclude `/auth`, and child resources (`/auth/child`), we use a wildcard.

```yaml
variables:
  FUZZAPI_EXCLUDE_PATHS=/auth*
```

To exclude multiple paths we can use the `;` character. In this example we exclude `/auth*` and `/v1/*`.

```yaml
variables:
  FUZZAPI_EXCLUDE_PATHS=/auth*;/v1/*
```

### Exclude parameters

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/292196) in GitLab 14.10.

While testing an API you may might want to exclude a parameter (query string, header, or body element) from testing. This may be needed because a parameter always causes a failure, slows down testing, or for other reasons. To exclude parameters you can use one of the following variables: `FUZZAPI_EXCLUDE_PARAMETER_ENV` or `FUZZAPI_EXCLUDE_PARAMETER_FILE`.

The `FUZZAPI_EXCLUDE_PARAMETER_ENV` allows providing a JSON string containing excluded parameters. This is a good option if the JSON is short and will not often change. Another option is the variable `FUZZAPI_EXCLUDE_PARAMETER_FILE`. This variable is set to a file path that can be checked into the repository, created by another job as an artifact, or generated at runtime from a pre script using `FUZZAPI_PRE_SCRIPT`.

#### Exclude parameters using a JSON document

The JSON document contains a JSON object which uses specific properties to identify which parameter should be excluded.
You can provide the following properties to exclude specific parameters during the scanning process:

- `headers`: Use this property to exclude specific headers. The property's value is an array of header names to be excluded. Names are case-insensitive.
- `cookies`: Use this property's value to exclude specific cookies. The property's value is an array of cookie names to be excluded. Names are case-sensitive.
- `query`: Use this property to exclude specific fields from the query string. The property's value is an array of field names from the query string to be excluded. Names are case-sensitive.
- `body-form`: Use this property to exclude specific fields from a request that uses the media type `application/x-www-form-urlencoded`. The property's value is an array of the field names from the body to be excluded. Names are case-sensitive.
- `body-json`: Use this property to exclude specific JSON nodes from a request that uses the media type `application/json`. The property's value is an array, each entry of the array is a [JSON Path](https://goessner.net/articles/JsonPath/) expression.
- `body-xml`: Use this property to exclude specific XML nodes from a request that uses media type `application/xml`. The property's value is an array, each entry of the array is a [XPath v2](https://www.w3.org/TR/xpath20/) expression.

The following JSON document is an example of the expected structure to exclude parameters.

```json
{
  "headers": [
    "header1",
    "header2"
  ],
  "cookies": [
    "cookie1",
    "cookie2"
  ],
  "query": [
    "query-string1",
    "query-string2"
  ],
  "body-form": [
    "form-param1",
    "form-param2"
  ],
  "body-json": [
    "json-path-expression-1",
    "json-path-expression-2"
  ],
  "body-xml" : [
    "xpath-expression-1",
    "xpath-expression-2"
  ]
}
```

#### Examples

##### Excluding a single header

To exclude the header `Upgrade-Insecure-Requests`, set the `header` property's value to an array with the header name: `[ "Upgrade-Insecure-Requests" ]`. For instance, the JSON document looks like this:

```json
{
  "headers": [ "Upgrade-Insecure-Requests" ]
}
```

Header names are case-insensitive, thus the header name `UPGRADE-INSECURE-REQUESTS` is equivalent to `Upgrade-Insecure-Requests`.

##### Excluding both a header and two cookies

To exclude the header `Authorization` and the cookies `PHPSESSID` and `csrftoken`, set the `headers` property's value to an array with header name `[ "Authorization" ]` and the `cookies` property's value to an array with the cookies' names `[ "PHPSESSID", "csrftoken" ]`. For instance, the JSON document looks like this:

```json
{
  "headers": [ "Authorization" ],
  "cookies": [ "PHPSESSID", "csrftoken" ]
}
```

##### Excluding a `body-form` parameter

To exclude the `password` field in a request that uses `application/x-www-form-urlencoded`, set the `body-form` property's value to an array with the field name `[ "password" ]`. For instance, the JSON document looks like this:

```json
{
  "body-form":  [ "password" ]
}
```

The exclude parameters uses `body-form` when the request uses a content type `application/x-www-form-urlencoded`.

##### Excluding a specific JSON nodes using JSON Path

To exclude the `schema` property in the root object, set the `body-json` property's value to an array with the JSON Path expression `[ "$.schema" ]`.

The JSON Path expression uses special syntax to identify JSON nodes: `$` refers to the root of the JSON document, `.` refers to the current object (in our case the root object), and the text `schema` refers to a property name. Thus, the JSON path expression `$.schema` refers to a property `schema` in the root object.
For instance, the JSON document looks like this:

```json
{
  "body-json": [ "$.schema" ]
}
```

The exclude parameters uses `body-json` when the request uses a content type `application/json`. Each entry in `body-json` is expected to be a [JSON Path expression](https://goessner.net/articles/JsonPath/). In JSON Path, characters like `$`, `*`, `.` among others have special meaning.

##### Excluding multiple JSON nodes using JSON Path

To exclude the property `password` on each entry of an array of `users` at the root level, set the `body-json` property's value to an array with the JSON Path expression `[ "$.users[*].paswword" ]`.

The JSON Path expression starts with `$` to refer to the root node and uses `.` to refer to the current node. Then, it uses `users` to refer to a property and the characters `[` and `]` to enclose the index in the array you want to use, instead of providing a number as an index you use `*` to specify any index. After the index reference, we find `.` which now refers to any given selected index in the array, preceded by a property name `password`.

For instance, the JSON document looks like this:

```json
{
  "body-json": [ "$.users[*].paswword" ]
}
```

The exclude parameters uses `body-json` when the request uses a content type `application/json`. Each entry in `body-json` is expected to be a [JSON Path expression](https://goessner.net/articles/JsonPath/). In JSON Path characters like `$`, `*`, `.` among others have special meaning.

##### Excluding an XML attribute

To exclude an attribute named `isEnabled` located in the root element `credentials`, set the `body-xml` property's value to an array with the XPath expression `[ "/credentials/@isEnabled" ]`.

The XPath expression `/credentials/@isEnabled`, starts with `/` to indicate the root of the XML document, then it is followed by the word `credentials` which indicates the name of the element to match. It uses a `/` to refer to a node of the previous XML element, and the character `@` to indicate that the name `isEnable` is an attribute.

For instance, the JSON document looks like this:

```json
{
  "body-xml": [
    "/credentials/@isEnabled"
  ]
}
```

The exclude parameters uses `body-xml` when the request uses a content type `application/xml`. Each entry in `body-xml` is expected to be an [XPath v2 expression](https://www.w3.org/TR/xpath20/). In XPath expressions, characters like `@`, `/`, `:`, `[`, `]` among others have special meanings.

##### Excluding an XML element's text

To exclude the text of the `username` element contained in root node `credentials`, set the `body-xml` property's value to an array with the XPath expression `[/credentials/username/text()" ]`.

In the XPath expression `/credentials/username/text()`, the first character `/` refers to the root XML node, and then after it indicates an XML element's name `credentials`. Similarly, the character `/` refers to the current element, followed by a new XML element's name `username`. Last part has a `/` that refers to the current element, and uses a XPath function called `text()` which identifies the text of the current element.

For instance, the JSON document looks like this:

```json
{
  "body-xml": [
    "/credentials/username/text()"
  ]
}
```

The exclude parameters uses `body-xml` when the request uses a content type `application/xml`. Each entry in `body-xml` is expected to be a [XPath v2 expression](https://www.w3.org/TR/xpath20/). In XPath expressions characters like `@`, `/`, `:`, `[`, `]` among others have special meanings.

##### Excluding an XML element

To exclude the element `username` contained in root node `credentials`, set the `body-xml` property's value to an array with the XPath expression `[/credentials/username" ]`.

In the XPath expression `/credentials/username`, the first character `/` refers to the root XML node, and then after it indicates an XML element's name `credentials`. Similarly, the character `/` refers to the current element, followed by a new XML element's name `username`.

For instance, the JSON document looks like this:

```json
{
  "body-xml": [
    "/credentials/username"
  ]
}
```

The exclude parameters uses `body-xml` when the request uses a content type `application/xml`. Each entry in `body-xml` is expected to be a [XPath v2 expression](https://www.w3.org/TR/xpath20/). In XPath expressions characters like `@`, `/`, `:`, `[`, `]` among others have special meanings.

##### Excluding an XML node with namespaces

To exclude a XML element `login` which is defined in namespace `s`, and contained in `credentials` root node, set the `body-xml` property's value to an array with the XPath expression `[ "/credentials/s:login" ]`.

In the XPath expression `/credentials/s:login`, the first character `/` refers to the root XML node, and then after it indicates an XML element's name `credentials`. Similarly, the character `/` refers to the current element, followed by a new XML element's name `s:login`. Notice that name contains the character `:`, this character separates the namespace from the node name.

The namespace name should have been defined in the XML document which is part of the body request. You may check the namespace in the specification document HAR, OpenAPI, or Postman Collection file.

```json
{
  "body-xml": [
    "/credentials/s:login"
  ]
}
```

The exclude parameters uses `body-xml` when the request uses a content type `application/xml`. Each entry in `body-xml` is expected to be a [XPath v2 expression](https://www.w3.org/TR/xpath20/). In XPath expressions characters like `@`, `/`, `:`, `[`, `]` among others have special meanings.

#### Using a JSON string

To provide the exclusion JSON document set the variable `FUZZAPI_EXCLUDE_PARAMETER_ENV` with the JSON string. In the following example, the `.gitlab-ci.yml`, the `FUZZAPI_EXCLUDE_PARAMETER_ENV` variable is set to a JSON string:

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_EXCLUDE_PARAMETER_ENV: '{ "headers": [ "Upgrade-Insecure-Requests" ] }'
```

#### Using a file

To provide the exclusion JSON document, set the variable `FUZZAPI_EXCLUDE_PARAMETER_FILE` with the JSON file path. The file path is relative to the job current working directory. In the following example `.gitlab-ci.yml` file, the `FUZZAPI_EXCLUDE_PARAMETER_FILE` variable is set to a JSON file path:

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_EXCLUDE_PARAMETER_FILE: api-fuzzing-exclude-parameters.json
```

The `api-fuzzing-exclude-parameters.json` is a JSON document that follows the structure of [exclude parameters document](#exclude-parameters-using-a-json-document).

### Exclude URLs

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/357195) in GitLab 14.10.

As an alternative to excluding by paths, you can filter by any other component in the URL by using the `FUZZAPI_EXCLUDE_URLS` CI/CD variable. This variable can be set in your `.gitlab-ci.yml` file. The variable can store multiple values, separated by commas (`,`). Each value is a regular expression. Because each entry is a regular expression, an entry such as `.*` excludes all URLs because it is a regular expression that matches everything.

In your job output you can check if any URLs matched any provided regular expression from `FUZZAPI_EXCLUDE_URLS`. Matching operations are listed in the **Excluded Operations** section. Operations listed in the **Excluded Operations** should not be listed in the **Tested Operations** section. For example the following portion of a job output:

```plaintext
2021-05-27 21:51:08 [INF] API Security: --[ Tested Operations ]-------------------------
2021-05-27 21:51:08 [INF] API Security: 201 POST http://target:7777/api/users CREATED
2021-05-27 21:51:08 [INF] API Security: ------------------------------------------------
2021-05-27 21:51:08 [INF] API Security: --[ Excluded Operations ]-----------------------
2021-05-27 21:51:08 [INF] API Security: GET http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API Security: POST http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API Security: ------------------------------------------------
```

NOTE:
Each value in `FUZZAPI_EXCLUDE_URLS` is a regular expression. Characters such as `.` , `*` and `$` among many others have special meanings in [regular expressions](https://en.wikipedia.org/wiki/Regular_expression#Standards).

#### Examples

##### Excluding a URL and child resources

The following example excludes the URL `http://target/api/auth` and its child resources.

```yaml
variables:
  FUZZAPI_EXCLUDE_URLS: http://target/api/auth
```

##### Excluding two URLs and allow their child resources

To exclude the URLs `http://target/api/buy` and `http://target/api/sell` but allowing to scan their child resources, for instance: `http://target/api/buy/toy` or `http://target/api/sell/chair`. You could use the value `http://target/api/buy/$,http://target/api/sell/$`. This value is using two regular expressions, each of them separated by a `,` character. Hence, it contains `http://target/api/buy$` and `http://target/api/sell$`. In each regular expression, the trailing `$` character points out where the matching URL should end.

```yaml
variables:
  FUZZAPI_EXCLUDE_URLS: http://target/api/buy/$,http://target/api/sell/$
```

##### Excluding two URLs and their child resources

In order to exclude the URLs: `http://target/api/buy` and `http://target/api/sell`, and their child resources. To provide multiple URLs we use the `,` character as follows:

```yaml
variables:
  FUZZAPI_EXCLUDE_URLS: http://target/api/buy,http://target/api/sell
```

##### Excluding URL using regular expressions

In order to exclude exactly `https://target/api/v1/user/create` and `https://target/api/v2/user/create` or any other version (`v3`,`v4`, and more). We could use `https://target/api/v.*/user/create$`, in the previous regular expression `.` indicates any character and `*` indicates zero or more times, additionally `$` indicates that the URL should end there.

```yaml
variables:
  FUZZAPI_EXCLUDE_URLS: https://target/api/v.*/user/create$
```

### Header Fuzzing

Header fuzzing is disabled by default due to the high number of false positives that occur with many
technology stacks. When header fuzzing is enabled, you must specify a list of headers to include in
fuzzing.

Each profile in the default configuration file has an entry for `GeneralFuzzingCheck`. This check
performs header fuzzing. Under the `Configuration` section, you must change the `HeaderFuzzing` and
`Headers` settings to enable header fuzzing.

This snippet shows the `Quick-10` profile's default configuration with header fuzzing disabled:

```yaml
- Name: Quick-10
  DefaultProfile: Empty
  Routes:
  - Route: *Route0
    Checks:
    - Name: FormBodyFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
    - Name: GeneralFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
        HeaderFuzzing: false
        Headers:
    - Name: JsonFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
    - Name: XmlFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
```

`HeaderFuzzing` is a boolean that turns header fuzzing on and off. The default setting is `false`
for off. To turn header fuzzing on, change this setting to `true`:

```yaml
    - Name: GeneralFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
        HeaderFuzzing: true
        Headers:
```

`Headers` is a list of headers to fuzz. Only headers listed are fuzzed. To fuzz a header used by
your APIs, add an entry for it using the syntax `- Name: HeaderName`. For example, to fuzz a
custom header `X-Custom`, add `- Name: X-Custom`:

```yaml
    - Name: GeneralFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
        HeaderFuzzing: true
        Headers:
          - Name: X-Custom
```

You now have a configuration to fuzz the header `X-Custom`. Use the same notation to list additional
headers:

```yaml
    - Name: GeneralFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
        HeaderFuzzing: true
        Headers:
          - Name: X-Custom
          - Name: X-AnotherHeader
```

Repeat this configuration for each profile as needed.

## Running your first scan

When configured correctly, a CI/CD pipeline contains a `fuzz` stage and an `apifuzzer_fuzz` or
`apifuzzer_fuzz_dnd` job. The job only fails when an invalid configuration is provided. During
normal operation, the job always succeeds even if faults are identified during fuzz testing.

Faults are displayed on the **Security** pipeline tab with the suite name. When testing against the
repositories default branch, the fuzzing faults are also shown on the Security & Compliance's
Vulnerability Report page.

To prevent an excessive number of reported faults, the API fuzzing scanner limits the number of
faults it reports.

## Viewing fuzzing faults

The API Fuzzing analyzer produces a JSON report that is collected and used
[to populate the faults into GitLab vulnerability screens](#view-details-of-an-api-fuzzing-vulnerability).
Fuzzing faults show up as vulnerabilities with a severity of Unknown.

The faults that API fuzzing finds require manual investigation and aren't associated with a specific
vulnerability type. They require investigation to determine if they are a security issue, and if
they should be fixed. See [handling false positives](#handling-false-positives)
for information about configuration changes you can make to limit the number of false positives
reported.

### View details of an API Fuzzing vulnerability

> Introduced in GitLab 13.7.

Faults detected by API Fuzzing occur in the live web application, and require manual investigation
to determine if they are vulnerabilities. Fuzzing faults are included as vulnerabilities with a
severity of Unknown. To facilitate investigation of the fuzzing faults, detailed information is
provided about the HTTP messages sent and received along with a description of the modifications
made.

Follow these steps to view details of a fuzzing fault:

1. You can view faults in a project, or a merge request:

   - In a project, go to the project's **{shield}** **Security & Compliance > Vulnerability Report**
     page. This page shows all vulnerabilities from the default branch only.
   - In a merge request, go the merge request's **Security** section and select the **Expand**
     button. API Fuzzing faults are available in a section labeled
     **API Fuzzing detected N potential vulnerabilities**. Select the title to display the fault
     details.

1. Select the fault's title to display the fault's details. The table below describes these details.

   | Field               | Description                                                                             |
   |:--------------------|:----------------------------------------------------------------------------------------|
   | Description         | Description of the fault including what was modified.                                   |
   | Project             | Namespace and project in which the vulnerability was detected.                          |
   | Method              | HTTP method used to detect the vulnerability.                                           |
   | URL                 | URL at which the vulnerability was detected.                                            |
   | Request             | The HTTP request that caused the fault.                                                 |
   | Unmodified Response | Response from an unmodified request. This is what a normal working response looks like. |
   | Actual Response     | Response received from fuzzed request.                                                  |
   | Evidence            | How we determined a fault occurred.                                                     |
   | Identifiers         | The fuzzing check used to find this fault.                                              |
   | Severity            | Severity of the finding is always Unknown.                                              |
   | Scanner Type        | Scanner used to perform testing.                                                        |

### Security Dashboard

Fuzzing faults show up as vulnerabilities with a severity of Unknown. The Security Dashboard is a
good place to get an overview of all the security vulnerabilities in your groups, projects and
pipelines. For more information, see the [Security Dashboard documentation](../security_dashboard/index.md).

### Interacting with the vulnerabilities

Fuzzing faults show up as vulnerabilities with a severity of Unknown.
Once a fault is found, you can interact with it. Read more on how to
[address the vulnerabilities](../vulnerabilities/index.md).

## Handling False Positives

False positives can be handled in two ways:

- Turn off the Check producing the false positive. This prevents the check from generating any
  faults. Example checks are the JSON Fuzzing Check, and Form Body Fuzzing Check.
- Fuzzing checks have several methods of detecting when a fault is identified, called _Asserts_.
  Asserts can also be turned off and configured. For example, the API fuzzer by default uses HTTP
  status codes to help identify when something is a real issue. If an API returns a 500 error during
  testing, this creates a fault. This isn't always desired, as some frameworks return 500 errors
  often.

### Turn off a Check

Checks perform testing of a specific type and can be turned on and off for specific configuration
profiles. The default configuration file defines several profiles that you
can use. The profile definition in the configuration file lists all the checks that are active
during a scan. To turn off a specific check, remove it from the profile definition in the
configuration file. The profiles are defined in the `Profiles` section of the configuration file.

Example profile definition:

```yaml
Profiles:
  - Name: Quick-10
    DefaultProfile: Quick
    Routes:
      - Route: *Route0
        Checks:
          - Name: FormBodyFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
          - Name: GeneralFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
          - Name: JsonFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
          - Name: XmlFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
```

To turn off the General Fuzzing Check you can remove these lines:

```yaml
- Name: GeneralFuzzingCheck
  Configuration:
    FuzzingCount: 10
    UnicodeFuzzing: true
```

This results in the following YAML:

```yaml
- Name: Quick-10
  DefaultProfile: Quick
  Routes:
    - Route: *Route0
      Checks:
        - Name: FormBodyFuzzingCheck
          Configuration:
            FuzzingCount: 10
            UnicodeFuzzing: true
        - Name: JsonFuzzingCheck
          Configuration:
            FuzzingCount: 10
            UnicodeFuzzing: true
        - Name: XmlFuzzingCheck
          Configuration:
            FuzzingCount: 10
            UnicodeFuzzing: true
```

### Turn off an Assertion for a Check

Assertions detect faults in tests produced by checks. Many checks support multiple Assertions such
as Log Analysis, Response Analysis, and Status Code. When a fault is found, the Assertion used is
provided. To identify which Assertions are on by default, see the Checks default configuration in
the configuration file. The section is called `Checks`.

This example shows the FormBody Fuzzing Check:

```yaml
Checks:
  - Name: FormBodyFuzzingCheck
    Configuration:
      FuzzingCount: 30
      UnicodeFuzzing: true
    Assertions:
      - Name: LogAnalysisAssertion
      - Name: ResponseAnalysisAssertion
      - Name: StatusCodeAssertion
```

Here you can see three Assertions are on by default. A common source of false positives is
`StatusCodeAssertion`. To turn it off, modify its configuration in the `Profiles` section. This
example provides only the other two Assertions (`LogAnalysisAssertion`,
`ResponseAnalysisAssertion`). This prevents `FormBodyFuzzingCheck` from using `StatusCodeAssertion`:

```yaml
Profiles:
  - Name: Quick-10
    DefaultProfile: Quick
    Routes:
      - Route: *Route0
        Checks:
          - Name: FormBodyFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
            Assertions:
              - Name: LogAnalysisAssertion
              - Name: ResponseAnalysisAssertion
          - Name: GeneralFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
          - Name: JsonFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
          - Name: XmlInjectionCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
```

## Running API fuzzing in an offline environment

For self-managed GitLab instances in an environment with limited, restricted, or intermittent access to external resources through the internet, some adjustments are required for the Web API Fuzz testing job to successfully run.

Steps:

1. Host the Docker image in a local container registry.
1. Set the `SECURE_ANALYZERS_PREFIX` to the local container registry.

The Docker image for API Fuzzing must be pulled (downloaded) from the public registry and then pushed (imported) into a local registry. The GitLab container registry can be used to locally host the Docker image. This process can be performed using a special template. See [loading Docker images onto your offline host](../offline_deployments/index.md#loading-docker-images-onto-your-offline-host) for instructions.

Once the Docker image is hosted locally, the `SECURE_ANALYZERS_PREFIX` variable is set with the location of the local registry. The variable must be set such that concatenating `/api-security:2` results in a valid image location.

For example, the below line sets a registry for the image `registry.gitlab.com/security-products/api-security:2`:

`SECURE_ANALYZERS_PREFIX: "registry.gitlab.com/security-products"`

NOTE:
Setting `SECURE_ANALYZERS_PREFIX` changes the Docker image registry location for all GitLab Secure templates.

For more information, see [Offline environments](../offline_deployments/index.md).

## Troubleshooting

### Error waiting for API Security 'http://127.0.0.1:5000' to become available

A bug exists in versions of the API Fuzzing analyzer prior to v1.6.196 that can cause a background process to fail under certain conditions. The solution is to update to a newer version of the DAST API analyzer.

The version information can be found in the job details for the `apifuzzer_fuzz` job.

If the issue is occurring with versions v1.6.196 or greater, please contact Support and provide the following information:

1. Reference this troubleshooting section and ask for the issue to be escalated to the Dynamic Analysis Team.
1. The full console output of the job.
1. The `gl-api-security-scanner.log` file available as a job artifact. In the right-hand panel of the job details page, select the **Browse** button.
1. The `apifuzzer_fuzz` job definition from your `.gitlab-ci.yml` file.

### Error, the OpenAPI document is not valid. Errors were found during validation of the document using the published OpenAPI schema

At the start of an API Fuzzing job the OpenAPI Specification is validated against the [published schema](https://github.com/OAI/OpenAPI-Specification/tree/master/schemas). This error is shown when the provided OpenAPI Specification has validation errors. Errors can be introduced when creating an OpenAPI Specification manually, and also when the schema is generated.

For OpenAPI Specifications that are generated automatically validation errors are often the result of missing code annotations.

**Error message**

- In [GitLab 13.11 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/323939), `Error, the OpenAPI document is not valid. Errors were found during validation of the document using the published OpenAPI schema`
  - `OpenAPI 2.0 schema validation error ...`
  - `OpenAPI 3.0.x schema validation error ...`

**Solution**

**For generated OpenAPI Specifications**

1. Identify the validation errors.
    1. Use the [Swagger Editor](https://editor.swagger.io/) to identify validation problems in your specification. The visual nature of the Swagger Editor makes it easier to understand what needs to change.
    1. Alternatively, you can check the log output and look for schema validation warnings. They are prefixed with messages such as `OpenAPI 2.0 schema validation error` or `OpenAPI 3.0.x schema validation error`. Each failed validation provides extra information about `location` and `description`. Note that JSON Schema validation messages might not be easy to understand. This is why we recommend the use of editors to validate schema documents.
1. Review the documentation for the OpenAPI generation your framework/tech stack is using. Identify the changes needed to produce a correct OpenAPI document.
1. Once the validation issues are resolved, re-run your pipeline.

**For manually created OpenAPI Specifications**

1. Identify the validation errors.
   1. The simplest solution is to use a visual tool to edit and validate the OpenAPI document. For example the [Swagger Editor](https://editor.swagger.io/) highlights schema errors and possible solutions.
   1. Alternatively, you can check the log output and look for schema validation warnings. They are prefixed with messages such as `OpenAPI 2.0 schema validation error` or `OpenAPI 3.0.x schema validation error`. Each failed validation provides extra information about `location` and `description`. Correct each of the validation failures and then resubmit the OpenAPI doc. Note that JSON Schema validation message might not be easy to understand. This is why we recommend the use of editors to validate document.
1. Once the validation issues are resolved, re-run your pipeline.

### Failed to start scanner session (version header not found)

The API Fuzzing engine outputs an error message when it cannot establish a connection with the scanner application component. The error message is shown in the job output window of the `apifuzzer_fuzz` job. A common cause of this issue is changing the `FUZZAPI_API` variable from its default.

**Error message**

- In [GitLab 13.11 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/323939), `Failed to start scanner session (version header not found).`
- In GitLab 13.10 and earlier, `API Security version header not found.  Are you sure that you are connecting to the API Security server?`.

**Solution**

- Remove the `FUZZAPI_API` variable from the `.gitlab-ci.yml` file. The value will be inherited from the API Fuzzing CI/CD template. We recommend this method instead of manually setting a value.
- If removing the variable is not possible, check to see if this value has changed in the latest version of the [API Fuzzing CI/CD template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml). If so, update the value in the `.gitlab-ci.yml` file.

### Application cannot determine the base URL for the target API

The API Fuzzing analyzer outputs an error message when it cannot determine the target API after inspecting the OpenAPI document. This error message is shown when the target API has not been set in the `.gitlab-ci.yml`file, it is not available in the `environment_url.txt` file, and it could not be computed using the OpenAPI document.

There is an order of precedence in which the API Fuzzing analyzer tries to get the target API when checking the different sources. First, it will try to use the `FUZZAPI_TARGET_URL`. If the environment variable has not been set, then the API Fuzzing analyzer will attempt to use the `environment_url.txt` file. If there is no file `environment_url.txt`, the API Fuzzing analyzer will then use the OpenAPI document contents and the URL provided in `FUZZAPI_OPENAPI` (if a URL is provided) to try to compute the target API.

The best-suited solution will depend on whether or not your target API changes for each deployment. In static environments, the target API is the same for each deployment, in this case please refer to the [static environment solution](#static-environment-solution). If the target API changes for each deployment a [dynamic environment solution](#dynamic-environment-solutions) should be applied.

#### Static environment solution

This solution is for pipelines in which the target API URL doesn't change (is static).

**Add environmental variable**

For environments where the target API remains the same, we recommend you specify the target URL by using the `FUZZAPI_TARGET_URL` environment variable. In your `.gitlab-ci.yml` file, add a variable `FUZZAPI_TARGET_URL`. The variable must be set to the base URL of API testing target. For example:

```yaml
include:
    - template: API-Fuzzing.gitlab-ci.yml

  variables:
    FUZZAPI_TARGET_URL: http://test-deployment/
    FUZZAPI_OPENAPI: test-api-specification.json
```

#### Dynamic environment solutions

In a dynamic environment your target API changes for each different deployment. In this case, there is more than one possible solution, we recommend to use the `environment_url.txt` file when dealing with dynamic environments.

**Use environment_url.txt**

To support dynamic environments in which the target API URL changes during each pipeline, API Fuzzing supports the use of an `environment_url.txt` file that contains the URL to use. This file is not checked into the repository, instead it's created during the pipeline by the job that deploys the test target and collected as an artifact that can be used by later jobs in the pipeline. The job that creates the `environment_url.txt` file must run before the API Fuzzing job.

1. Modify the test target deployment job adding the base URL in an `environment_url.txt` file at the root of your project.
1. Modify the test target deployment job collecting the `environment_url.txt` as an artifact.

Example:

```yaml
deploy-test-target:
  script:
    # Perform deployment steps
    # Create environment_url.txt (example)
    - echo http://${CI_PROJECT_ID}-${CI_ENVIRONMENT_SLUG}.example.org > environment_url.txt

  artifacts:
    paths:
      - environment_url.txt
```

<!--
### Target Container

The API Fuzzing template supports launching a docker container containing an API target using docker-in-docker.

TODO
-->

### Use OpenAPI with an invalid schema

There are cases where the document is autogenerated with an invalid schema or cannot be edited manually in a timely manner. In those scenarios, the API Security is able to perform a relaxed validation by setting the variable `FUZZAPI_OPENAPI_RELAXED_VALIDATION`. We recommend providing a fully compliant OpenAPI document to prevent unexpected behaviors.

#### Edit a non-compliant OpenAPI file

To detect and correct elements that don't comply with the OpenAPI specifications, we recommend using an editor. An editor commonly provides document validation, and suggestions to create a schema-compliant OpenAPI document. Suggested editors include:

| Editor | OpenAPI 2.0 | OpenAPI 3.0.x | OpenAPI 3.1.x |
| -- | -- | -- | -- |
| [Swagger Editor](https://editor.swagger.io/) | **{check-circle}** YAML, JSON | **{check-circle}** YAML, JSON | **{dotted-circle}** YAML, JSON |
| [Stoplight Studio](https://stoplight.io/studio/) | **{check-circle}** YAML, JSON | **{check-circle}** YAML, JSON | **{check-circle}** YAML, JSON |

If your OpenAPI document is generated manually, load your document in the editor and fix anything that is non-compliant. If your document is generated automatically, load it in your editor to identify the issues in the schema, then go to the application and perform the corrections based on the framework you are using.

#### Enable OpenAPI relaxed validation

Relaxed validation is meant for cases when the OpenAPI document cannot meet OpenAPI specifications, but it still has enough content to be consumed by different tools. A validation is performed but less strictly in regards to document schema.

API Security can still try to consume an OpenAPI document that does not fully comply with OpenAPI specifications. To instruct API Security to perform a relaxed validation, set the variable `FUZZAPI_OPENAPI_RELAXED_VALIDATION` to any value, for example:

```yaml
   stages:
     - fuzz

   include:
     - template: API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
     FUZZAPI_TARGET_URL: http://test-deployment/
     FUZZAPI_OPENAPI: test-api-specification.json
     FUZZAPI_OPENAPI_RELAXED_VALIDATION: On
```

### No operation in the OpenAPI document is consuming any supported media type

API Security uses the specified media types in the OpenAPI document to generate requests. If no request can be created due to the lack of supported media types, then an error will be thrown.

**Error message**

- In [GitLab 14.10 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/333304), `Error, no operation in the OpenApi document is consuming any supported media type. Check 'OpenAPI Specification' to check the supported media types.`

**Solution**

1. Review the supported media types in the [OpenAPI Specification](#openapi-specification) section.
1. Edit your OpenAPI document, allowing at least a given operation to accept any of the supported media types. Alternatively, a supported media type could be set in the OpenAPI document level and get applied to all operations. This step may require changes in your application to ensure the supported media type is accepted by the application.

## Get support or request an improvement

To get support for your particular problem please use the [getting help channels](https://about.gitlab.com/get-help/).

The [GitLab issue tracker on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues) is the right place for bugs and feature proposals about API Security and API Fuzzing.
Please use `~"Category:API Security"` [label](../../../development/contributing/issue_workflow.md#labels) when opening a new issue regarding API fuzzing to ensure it is quickly reviewed by the right people. Please refer to our [review response SLO](../../../development/code_review.md#review-response-slo) to understand when you should receive a response.

[Search the issue tracker](https://gitlab.com/gitlab-org/gitlab/-/issues) for similar entries before submitting your own, there's a good chance somebody else had the same issue or feature proposal. Show your support with an award emoji and or join the discussion.

When experiencing a behavior not working as expected, consider providing contextual information:

- GitLab version if using a self-managed instance.
- `.gitlab-ci.yml` job definition.
- Full job console output.
- Scanner log file available as a job artifact named `gl-api-security-scanner.log`.

WARNING:
**Sanitize data attached to a support issue**. Please remove sensitive information, including: credentials, passwords, tokens, keys, and secrets.

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
