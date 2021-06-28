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

- [OpenAPI Specification](#openapi-specification) - version 2.0 or 3.0
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
  **NEVER** run fuzz testing against a production server. Not only can it perform *any* function that
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

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/299234) in GitLab 13.10.

WARNING:
This feature might not be available to you. Check the **version history** note above for details.

The API fuzzing configuration form helps you create or modify your project's API fuzzing
configuration. The form lets you choose values for the most common API fuzzing options and builds
a YAML snippet that you can paste in your GitLab CI/CD configuration.

#### Configure Web API fuzzing with the configuration form

To generate an API Fuzzing configuration snippet:

1. From your project's home page, go to **Security & Compliance > Configuration** in the left
   sidebar.
1. Select **Configure** in the **API Fuzzing** row.
1. Complete the form as needed. Read below for more information on available configuration options.
1. Select **Generate code snippet**.
   A modal opens with the YAML snippet corresponding to the options you've selected in the form.
1. Choose one of the following actions:
   1. Select **Copy code and open `.gitlab-ci.yml` file** to copy the snippet to your clipboard and
      be redirected to your project's `.gitlab-ci.yml` file where you can paste the YAML
      configuration.
   1. Select **Copy code only** to copy the snippet to your clipboard and close the modal.

### OpenAPI Specification

> Support for OpenAPI Specification using YAML format was
> [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/330583) in GitLab 14.0.
> Support for OpenAPI Specification v3.0 was
> [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/228652) in GitLab 13.9.

The [OpenAPI Specification](https://www.openapis.org/) (formerly the Swagger Specification) is an API description format for REST APIs.
This section shows you how to configure API fuzzing using an OpenAPI Specification to provide information about the target API to test.
OpenAPI Specifications are provided as a file system resource or URL. Both JSON and YAML OpenAPI formats are supported.

API fuzzing uses an OpenAPI document to generate the request body. When a request body is required,
the body generation is limited to these body types:

- `application/x-www-form-urlencoded`
- `multipart/form-data`
- `application/json`

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
   or URL. [URL support was introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/285020)
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
   as a file or URL. [URL support was introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/285020)
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

Although Postman can export environment variables into a JSON file, the format is not compatible
with the JSON expected by `FUZZAPI_POSTMAN_COLLECTION_VARIABLES`.

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
   and the test API's application logs.

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
  FUZZAPI_OVERRIDES_FILE: output/api-fuzzing-overrides.json
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
  FUZZAPI_OVERRIDES_FILE: output/api-fuzzing-overrides.json
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
| `FUZZAPI_VERSION`                                           | Specify API Fuzzing container version. Defaults to `latest`. |
| `FUZZAPI_TARGET_URL`                                        | Base URL of API testing target. |
| `FUZZAPI_CONFIG`                                            | [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/276395) in GitLab 13.12, replaced with default `.gitlab/gitlab-api-fuzzing-config.yml`. API Fuzzing configuration file. |
|[`FUZZAPI_PROFILE`](#api-fuzzing-profiles)                   | Configuration profile to use during testing. Defaults to `Quick-10`. |
|[`FUZZAPI_EXCLUDE_PATHS`](#exclude-paths)                    | Exclude API URL paths from testing. |
|[`FUZZAPI_OPENAPI`](#openapi-specification)                  | OpenAPI Specification file or URL. |
|[`FUZZAPI_HAR`](#http-archive-har)                           | HTTP Archive (HAR) file. |
|[`FUZZAPI_POSTMAN_COLLECTION`](#postman-collection)          | Postman Collection file. |
|[`FUZZAPI_POSTMAN_COLLECTION_VARIABLES`](#postman-variables) | Path to a JSON file to extract Postman variable values. |
|[`FUZZAPI_OVERRIDES_FILE`](#overrides)                       | Path to a JSON file containing overrides. |
|[`FUZZAPI_OVERRIDES_ENV`](#overrides)                        | JSON string containing headers to override. |
|[`FUZZAPI_OVERRIDES_CMD`](#overrides)                        | Overrides command. |
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
    "form-param1": "value",
  },
  "body-json":  {
    "json-path1": "value",
    "json-path2": "value",
  },
  "body-xml" :  {
    "xpath1":    "value",
    "xpath2":    "value",
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
  FUZZAPI_OVERRIDES_FILE: output/api-fuzzing-overrides.json
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
container that has Python 3 and Bash installed. If the Python script requires additional packages,
it must detect this and install the packages at runtime. The script creates the overrides JSON file
as defined above.

You must provide three CI/CD variables, each set for correct operation:

- `FUZZAPI_OVERRIDES_FILE`: File generated by the provided command.
- `FUZZAPI_OVERRIDES_CMD`: Command to generate JSON file.
- `FUZZAPI_OVERRIDES_INTERVAL`: Interval in seconds to run command.

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_FILE: output/api-fuzzing-overrides.json
  FUZZAPI_OVERRIDES_CMD: renew_token.py
  FUZZAPI_OVERRIDES_INTERVAL: 300
```

### Exclude Paths

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/211892) in GitLab 14.0.

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

> Introduced in [GitLab Ultimate](https://about.gitlab.com/pricing/) 13.7.

Faults detected by API Fuzzing occur in the live web application, and require manual investigation
to determine if they are vulnerabilities. Fuzzing faults are included as vulnerabilities with a
severity of Unknown. To facilitate investigation of the fuzzing faults, detailed information is
provided about the HTTP messages sent and received along with a description of the modification(s)
made.

Follow these steps to view details of a fuzzing fault:

1. You can view faults in a project, or a merge request:

   - In a project, go to the project's **{shield}** **Security & Compliance > Vulnerability Report**
     page. This page shows all vulnerabilities from the default branch only.
   - In a merge request, go the merge request's **Security** section and click the **Expand**
     button. API Fuzzing faults are available in a section labeled
     **API Fuzzing detected N potential vulnerabilities**. Click the title to display the fault
     details.

1. Click the fault's title to display the fault's details. The table below describes these details.

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

For self-managed GitLab instances in an environment with limited, restricted, or intermittent access
to external resources through the internet, some adjustments are required for the Web API Fuzz testing job to
successfully run. For more information, see [Offline environments](../offline_deployments/index.md).

## Troubleshooting

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
