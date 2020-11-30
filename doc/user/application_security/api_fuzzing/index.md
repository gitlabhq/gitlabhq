---
stage: Secure
group: Fuzz Testing
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
---

# Web API Fuzz Testing **(ULTIMATE)**

You can add web API fuzzing to your [GitLab CI/CD](../../../ci/README.md)
pipelines. This helps you discover bugs and potential security issues that other QA processes may
miss. API fuzzing performs fuzz testing of API operation parameters. Fuzz testing sets operation
parameters to unexpected values in an effort to cause unexpected behavior and errors in the API
backend.

We recommend that you use fuzz testing in addition to [GitLab Secure](../index.md)'s
other security scanners and your own test processes. If you're using [GitLab CI/CD](../../../ci/README.md),
you can run fuzz tests as part your CI/CD workflow.

## Requirements

- One of the following web API types:
  - REST API
  - SOAP
  - GraphQL
  - Form bodies, JSON, or XML
- One of the following assets to provide APIs to test:
  - OpenAPI v2 API definition
  - HTTP Archive (HAR) of API requests to test
  - Postman Collection v2.0 or v2.1

## When fuzzing scans run

When using the `API-Fuzzing.gitlab-ci.yml` template, the `fuzz` job runs last, as shown here. To
ensure API fuzzing scans the latest code, your CI pipeline should deploy changes to a test
environment in one of the jobs preceding the `fuzz` job:

```yaml
stages:
  - build
  - test
  - deploy
  - fuzz
```

Note that if your pipeline is configured to deploy to the same web server on each run, running a
pipeline while another is still running could cause a race condition in which one pipeline
overwrites the code from another. The API to scan should be excluded from changes for the duration
of a fuzzing scan. The only changes to the API should be from the fuzzing scanner. Be aware that
any changes made to the API (for example, by users, scheduled tasks, database changes, code
changes, other pipelines, or other scanners) during a scan could cause inaccurate results.

## Configuration

There are three ways to perform scans. See the configuration section for the one you wish to use:

- [OpenAPI v2 specification](#openapi-specification)
- [HTTP Archive (HAR)](#http-archive-har)
- [Postman Collection v2.0 or v2.1](#postman-collection)

Examples of both configurations can be found here:

- [Example OpenAPI v2 specification project](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing-example/-/tree/openapi)
- [Example HTTP Archive (HAR) project](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing-example/-/tree/har)
- [Example Postman Collection project](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/postman-api-fuzzing-example)

### OpenAPI Specification

The [OpenAPI Specification](https://www.openapis.org/) (formerly the Swagger Specification) is an
API description format for REST APIs. This section shows you how to configure API fuzzing by using
an OpenAPI specification to provide information about the target API to test. OpenAPI specifications
are provided as a filesystem resource or URL.

Follow these steps to configure API fuzzing in GitLab with an OpenAPI specification:

1. To use API fuzzing, you must [include](../../../ci/yaml/README.md#includetemplate)
   the [`API-Fuzzing.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml)
   that's provided as part of your GitLab installation. To do so, add the following to your
   `.gitlab-ci.yml` file:

   ```yaml
   include:
     - template: API-Fuzzing.gitlab-ci.yml
   ```

1. Add the configuration file [`gitlab-api-fuzzing-config.yml`](https://gitlab.com/gitlab-org/security-products/analyzers/api-fuzzing/-/blob/master/gitlab-api-fuzzing-config.yml) to your repository's root as `.gitlab-api-fuzzing.yml`.

1. The [configuration file](#configuration-files) has several testing profiles defined with varying
   amounts of fuzzing. We recommend that you start with the `Quick-10` profile. Testing with this
   profile completes quickly, allowing for easier configuration validation.

   Provide the profile by adding the `FUZZAPI_PROFILE` variable to your `.gitlab-ci.yml` file,
   substituting `Quick-10` for the profile you choose:

   ```yaml
   include:
     - template: API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
   ```

1. Provide the location of the OpenAPI v2 specification. You can provide the specification as a file
   or URL. Specify the location by adding the `FUZZAPI_OPENAPI` variable:

   ```yaml
   include:
     - template: API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
     FUZZAPI_OPENAPI: test-api-specification.json
   ```

1. The target API instance's base URL is also required. Provide it by using the `FUZZAPI_TARGET_URL`
   variable or an `environment_url.txt` file.

   Adding the URL in an `environment_url.txt` file at your project's root is great for testing in
   dynamic environments. To run API fuzzing against an app dynamically created during a GitLab CI/CD
   pipeline, have the app persist its domain in an `environment_url.txt` file. API fuzzing
   automatically parses that file to find its scan target. You can see an
   [example of this in our Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml).

   Here's an example of using `FUZZAPI_TARGET_URL`:

   ```yaml
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

DANGER: **Warning:**
**NEVER** run fuzz testing against a production server. Not only can it perform *any* function that
the API can, it may also trigger bugs in the API. This includes actions like modifying and deleting
data. Only run fuzzing against a test server.

### HTTP Archive (HAR)

The [HTTP Archive format (HAR)](http://www.softwareishard.com/blog/har-12-spec/)
is an archive file format for logging HTTP transactions. When used with GitLab's API fuzzer, HAR
must contain records of calling the web API to test. The API fuzzer extracts all the requests and
uses them to perform testing.

You can use various tools to generate HAR files:

- [Fiddler](https://www.telerik.com/fiddler): Web debugging proxy
- [Insomnia Core](https://insomnia.rest/): API client
- [Chrome](https://www.google.com/chrome): Browser
- [Firefox](https://www.mozilla.org/en-US/firefox/): Browser

DANGER: **Warning:**
HAR files may contain sensitive information such as authentication tokens, API keys, and session
cookies. We recommend that you review the HAR file contents before adding them to a repository.

Follow these steps to configure API fuzzing to use a HAR file that provides information about the
target API to test:

1. To use API fuzzing, you must [include](../../../ci/yaml/README.md#includetemplate)
   the [`API-Fuzzing.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml)
   that's provided as part of your GitLab installation. To do so, add the following to your
   `.gitlab-ci.yml` file:

   ```yaml
   include:
     - template: API-Fuzzing.gitlab-ci.yml
   ```

1. Add the configuration file [`gitlab-api-fuzzing-config.yml`](https://gitlab.com/gitlab-org/security-products/analyzers/api-fuzzing/-/blob/master/gitlab-api-fuzzing-config.yml) to your repository's root as `.gitlab-api-fuzzing.yml`.

1. The [configuration file](#configuration-files) has several testing profiles defined with varying
   amounts of fuzzing. We recommend that you start with the `Quick-10` profile. Testing with this
   profile completes quickly, allowing for easier configuration validation.

   Provide the profile by adding the `FUZZAPI_PROFILE` variable to your `.gitlab-ci.yml` file,
   substituting `Quick-10` for the profile you choose:

   ```yaml
   include:
     - template: API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
   ```

1. Add the `FUZZAPI_HAR` variable and set it to the HAR file's location:

   ```yaml
   include:
     - template: API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
     FUZZAPI_HAR: test-api-recording.har
   ```

1. The target API instance's base URL is also required. Provide it by using the `FUZZAPI_TARGET_URL`
   variable or an `environment_url.txt` file.

   Adding the URL in an `environment_url.txt` file at your project's root is great for testing in
   dynamic environments. To run API fuzzing against an app dynamically created during a GitLab CI/CD
   pipeline, have the app persist its domain in an `environment_url.txt` file. API fuzzing
   automatically parses that file to find its scan target. You can see an
   [example of this in our Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml).

   Here's an example of using `FUZZAPI_TARGET_URL`:

   ```yaml
   include:
     - template: API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
     FUZZAPI_HAR: test-api-recording.har
     FUZZAPI_TARGET_URL: http://test-deployment/
   ```

This is a minimal configuration for API Fuzzing. From here you can:

- [Run your first scan](#running-your-first-scan).
- [Add authentication](#authentication).
- Learn how to [handle false positives](#handling-false-positives).

DANGER: **Warning:**
**NEVER** run fuzz testing against a production server. Not only can it perform *any* function that
the API can, it may also trigger bugs in the API. This includes actions like modifying and deleting
data. Only run fuzzing against a test server.

### Postman Collection

The [Postman API Client](https://www.postman.com/product/api-client/) is a popular tool that
developers and testers use to call various types of APIs. The API definitions
[can be exported as a Postman Collection file](https://learning.postman.com/docs/getting-started/importing-and-exporting-data/#exporting-postman-data)
for use with API Fuzzing. When exporting, make sure to select a supported version of Postman
Collection: v2.0 or v2.1.

When used with GitLab's API fuzzer, Postman Collections must contain definitions of the web API to
test with valid data. The API fuzzer extracts all the API definitions and uses them to perform
testing.

DANGER: **Warning:**
Postman Collection files may contain sensitive information such as authentication tokens, API keys,
and session cookies. We recommend that you review the Postman Collection file contents before adding
them to a repository.

Follow these steps to configure API fuzzing to use a Postman Collection file that provides
information about the target API to test:

1. To use API fuzzing, you must [include](../../../ci/yaml/README.md#includetemplate)
   the [`API-Fuzzing.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml)
   that's provided as part of your GitLab installation. To do so, add the following to your
   `.gitlab-ci.yml` file:

   ```yaml
   include:
     - template: API-Fuzzing.gitlab-ci.yml
   ```

1. Add the configuration file [`gitlab-api-fuzzing-config.yml`](https://gitlab.com/gitlab-org/security-products/analyzers/api-fuzzing/-/blob/master/gitlab-api-fuzzing-config.yml)
   to your repository's root as `.gitlab-api-fuzzing.yml`.

1. The [configuration file](#configuration-files) has several testing profiles defined with varying
   amounts of fuzzing. We recommend that you start with the `Quick-10` profile. Testing with this
   profile completes quickly, allowing for easier configuration validation.

   Provide the profile by adding the `FUZZAPI_PROFILE` variable to your `.gitlab-ci.yml` file,
   substituting `Quick-10` for the profile you choose:

   ```yaml
   include:
     - template: API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
   ```

1. Add the `FUZZAPI_POSTMAN_COLLECTION` variable and set it to the Postman Collection's location:

   ```yaml
   include:
     - template: API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
     FUZZAPI_POSTMAN_COLLECTION: postman-collection_serviceA.json
   ```

1. The target API instance's base URL is also required. Provide it by using the `FUZZAPI_TARGET_URL`
   variable or an `environment_url.txt` file.

   Adding the URL in an `environment_url.txt` file at your project's root is great for testing in
   dynamic environments. To run API fuzzing against an app dynamically created during a GitLab CI/CD
   pipeline, have the app persist its domain in an `environment_url.txt` file. API fuzzing
   automatically parses that file to find its scan target. You can see an
   [example of this in our Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml).

   Here's an example of using `FUZZAPI_TARGET_URL`:

   ```yaml
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

DANGER: **Warning:**
**NEVER** run fuzz testing against a production server. Not only can it perform *any* function that
the API can, it may also trigger bugs in the API. This includes actions like modifying and deleting
data. Only run fuzzing against a test server.

### Authentication

Authentication is handled by providing the authentication token as a header or cookie. You can
provide a script that performs an authentication flow or calculates the token.

#### HTTP Basic Authentication

[HTTP basic authentication](https://en.wikipedia.org/wiki/Basic_access_authentication)
is an authentication method built into the HTTP protocol and used in-conjunction with
[transport layer security (TLS)](https://en.wikipedia.org/wiki/Transport_Layer_Security).
To use HTTP basic authentication, two variables are added to your `.gitlab-ci.yml` file:

- `FUZZAPI_HTTP_USERNAME`: The username for authentication.
- `FUZZAPI_HTTP_PASSWORD`: The password for authentication.

For the password, we recommended that you [create a CI/CD variable](../../../ci/variables/README.md#create-a-custom-variable-in-the-ui)
(for example, `TEST_API_PASSWORD`) set to the password. You can create CI/CD variables from the
GitLab projects page at **Settings > CI/CD**, in the **Variables** section.

```yaml
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

If the bearer token doesn't expire, you can provide it using the `FUZZAPI_OVERRIDES_ENV` variable.
The `FUZZAPI_OVERRIDES_ENV` content is a JSON snippet that provides headers and cookies that should
be added to outgoing HTTP requests made by API fuzzing.

Create a CI/CD variable, for example `TEST_API_BEARERAUTH`, with the value
`{"headers":{"Authorization":"Bearer dXNlcm5hbWU6cGFzc3dvcmQ="}}` (substitute your token). You can
create CI/CD variables from the GitLab projects page at **Settings > CI/CD** in the **Variables**
section.

Set `FUZZAPI_OVERRIDES_ENV` in your `.gitlab-ci.yml` file:

```yaml
include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick-10
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_ENV: $TEST_API_BEARERAUTH
```

To validate that authentication is working, run an API fuzzing test and review the fuzzing logs and
the test API's application logs.

##### Token generated at test-runtime

If the bearer token must be generated, and the resulting token doesn't expire during testing, you
can provide to API fuzzing a file containing the token. This file can be generated by a prior stage
and job, or as part of the API fuzzing job.

API fuzzing expects to receive a JSON file with the following structure:

```json
{
  "headers" : {
    "Authorization" : "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  }
}
```

This file can be generated by a prior stage and provided to API fuzzing through the
`FUZZAPI_OVERRIDES_FILE` variable.

Set `FUZZAPI_OVERRIDES_FILE` in your `.gitlab-ci.yml` file:

```yaml
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

You must provide three variables, each set for correct operation:

- `FUZZAPI_OVERRIDES_FILE`: File generated by the provided command.
- `FUZZAPI_OVERRIDES_CMD`: Command to generate JSON file.
- `FUZZAPI_OVERRIDES_INTERVAL`: Interval in seconds to run command.

```yaml
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

### Configuration files

To get started quickly, GitLab provides you with the configuration file
[`gitlab-api-fuzzing-config.yml`](https://gitlab.com/gitlab-org/security-products/analyzers/api-fuzzing/-/blob/master/gitlab-api-fuzzing-config.yml).
This file has several testing profiles that perform various amounts of testing. The run time of each
increases as the numbers go up. To use a configuration file, add it to your repository's root as
`.gitlab-api-fuzzing.yml`.

| Profile  | Scan Type  |
|:---------|:-----------|
|Quick-10  |Fuzzing 10 times per parameter  |
|Medium-20 |Fuzzing 20 times per parameter  |
|Medium-50 |Fuzzing 50 times per parameter  |
|Long-100  |Fuzzing 100 times per parameter |

### Available variables

| Environment variable        | Description        |
|-----------------------------|--------------------|
| `FUZZAPI_VERSION`           |Specify API Fuzzing container version. Defaults to `latest`. |
| `FUZZAPI_TARGET_URL`        |Base URL of API testing target. |
|[`FUZZAPI_CONFIG`](#configuration-files)|API Fuzzing configuration file. Defaults to `.gitlab-apifuzzer.yml`. |
|[`FUZZAPI_PROFILE`](#configuration-files)|Configuration profile to use during testing. Defaults to `Quick`. |
| `FUZZAPI_REPORT`            |Scan report filename. Defaults to `gl-api_fuzzing-report.xml`. |
|[`FUZZAPI_OPENAPI`](#openapi-specification)|OpenAPI specification file or URL. |
|[`FUZZAPI_HAR`](#http-archive-har)|HTTP Archive (HAR) file. |
|[`FUZZAPI_POSTMAN_COLLECTION`](#postman-collection)|Postman Collection file. |
|[`FUZZAPI_OVERRIDES_FILE`](#overrides)     |Path to a JSON file containing overrides. |
|[`FUZZAPI_OVERRIDES_ENV`](#overrides)      |JSON string containing headers to override. |
|[`FUZZAPI_OVERRIDES_CMD`](#overrides)      |Overrides command. |
|[`FUZZAPI_OVERRIDES_INTERVAL`](#overrides) |How often to run overrides command in seconds. Defaults to `0` (once). |
|[`FUZZAPI_HTTP_USERNAME`](#http-basic-authentication) |Username for HTTP authentication. |
|[`FUZZAPI_HTTP_PASSWORD`](#http-basic-authentication) |Password for HTTP authentication. |

<!--|[`FUZZAPI_D_TARGET_IMAGE`](#target-container) |API target docker image |
|[`FUZZAPI_D_TARGET_ENV`](#target-container)   |Docker environment options |
|[`FUZZAPI_D_TARGET_VOLUME`](#target-container)|Docker volume options |
|[`FUZZAPI_D_TARGET_PORTS`](#target-container) |Docker port options |
| `FUZZAPI_D_WORKER_IMAGE`    |Custom worker docker image |
| `FUZZAPI_D_WORKER_ENV`      |Custom worker docker environment options |
| `FUZZAPI_D_WORKER_VOLUME`   |Custom worker docker volume options |
| `FUZZAPI_D_WORKER_PORTS`    |Custom worker docker port options |
| `FUZZAPI_D_NETWORK`         |Name of docker network, defaults to "testing-net"|
| `FUZZAPI_D_PRE_SCRIPT`      |Pre script runs after docker login and docker network create, but before starting the scanning image container.|
| `FUZZAPI_D_POST_SCRIPT`     |Post script runs after scanning image container is started. This is the place to start your target(s) and kick off scanning when using an advanced configuration.| -->

### Overrides

API Fuzzing provides a method to add or override headers and cookies for all outbound HTTP requests
made. You can use this to inject semver headers, authentication, and so on. The
[authentication section](#authentication) includes examples of using overrides for that purpose.

Overrides uses a JSON document to define the headers and cookies:

```json
{
  "headers": {
    "header1": "value",
    "header2": "value"
  },
  "cookies": {
    "cookie1": "value",
    "cookie2": "value"
  }
}
```

Example usage for setting a single header:

```json
{
  "headers": {
    "Authorization": "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  }
}
```

Example usage for setting both a header and cookie:

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

You can provide this JSON document as a file or environment variable. You may also provide a command
to generate the JSON document. The command can run at intervals to support values that expire.

#### Using a file

To provide the overrides JSON as a file, the `FUZZAPI_OVERRIDES_FILE` environment variable is set. The path is relative to the job current working directory.

Example `.gitlab-ci.yml`:

```yaml
include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_FILE: output/api-fuzzing-overrides.json
```

#### Using an environment variable

To provide the overrides JSON as an environment variable, use the `FUZZAPI_OVERRIDES_ENV` variable.
This allows you to place the JSON as CI/CD variables that can be masked and protected.

In this example `.gitlab-ci.yml`, the JSON is provided directly:

```yaml
include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_ENV: '{"headers":{"X-API-Version":"2"}}'
```

In this example `.gitlab-ci.yml`, the CI/CD variable `SECRET_OVERRIDES` provides the JSON. This is a
[group or instance level environment variable defined in the UI](../../../ci/variables/README.md#instance-level-cicd-environment-variables):

```yaml
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

You must provide three variables, each set for correct operation:

- `FUZZAPI_OVERRIDES_FILE`: File generated by the provided command.
- `FUZZAPI_OVERRIDES_CMD`: Command to generate JSON file.
- `FUZZAPI_OVERRIDES_INTERVAL`: Interval in seconds to run command.

```yaml
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

`Headers` is a list of headers to fuzz. Only headers listed are fuzzed. For example, to fuzz a
custom header `X-Custom` used by your APIs, add an entry for it using the syntax
`- Name: HeaderName`, substituting `HeaderName` with the header to fuzz:

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

When configured correctly, a CI/CD pipeline contains a `Fuzz` stage and a `apifuzzer_fuzz` job. The
job only fails when an invalid configuration is provided. During normal operation, the job always
succeeds even if faults are identified during fuzz testing.

Faults are displayed on the **Tests** pipeline tab with the suite name **API-Fuzzing**. The **Name**
field on the **Tests** page includes the fuzz-tested operation and parameter. The **Trace** field
contains a writeup of the identified fault. This writeup contains information on what the fuzzer
tested and how it detected something wrong.

To prevent an excessive number of reported faults, the API fuzzing scanner limits the number of
faults it reports to one per parameter.

### Fault Writeup

The faults that API fuzzing finds aren't associated with a specific vulnerability type. They require
investigation to determine what type of issue they are and if they should be fixed. See
[handling false positives](#handling-false-positives) for information about configuration changes
you can make to limit the number of false positives reported.

This table contains a description of fields in an API fuzzing fault writeup.

| Writeup Item | Description |
|:-------------|:------------|
| Operation | The operation tested. |
| Parameter | The field modified. This can be a path segment, header, query string, or body element. |
| Endpoint  | The endpoint being tested. |
| Check     | Check module producing the test. Checks can be turned on and off. |
| Assert    | Assert module that detected a failure. Assertions can be configured and turned on and off. |
| CWE       | Fuzzing faults always have the same CWE. |
| OWASP     | Fuzzing faults always have the same OWASP ID. |
| Exploitability | Fuzzing faults always have an `unknown` exploitability. |
| Impact         | Fuzzing faults always have an `unknown` risk impact. |
| Description    | Verbose description of what the check did. Includes the original parameter value and the modified (mutated) value. |
| Detection      | Why a failure was detected and reported. This is related to the Assert that was used. |
| Original Request  | The original, unmodified HTTP request. Useful when reviewing the actual request to see what changes were made. |
| Actual Request    | The request that produced the failure. This request has been modified in some way by the Check logic. |
| Actual Response   | The response to the actual request. |
| Recorded Request  | An unmodified request. |
| Recorded Response | The response to the unmodified request. You can compare this with the actual request when triaging this fault. |

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
profiles. The provided [configuration files](#configuration-files) define several profiles that you
can use. The profile definition in the configuration file lists all the checks that are active
during a scan. To turn off a specific check, simply remove it from the profile definition in the
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
