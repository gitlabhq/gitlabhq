---
stage: Secure
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Enabling the analyzer

You can specify the API you want to scan by using:

- [OpenAPI v2 or v3 Specification](#openapi-specification)
- [GraphQL Schema](#graphql-schema)
- [HTTP Archive (HAR)](#http-archive-har)
- [Postman Collection v2.0 or v2.1](#postman-collection)

## OpenAPI Specification

> - Support for OpenAPI Specification using YAML format was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/330583) in GitLab 14.0.
> - Support to generate media type `application/xml` was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/327268) in GitLab 14.8.
> - Support to media types was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/333304) in GitLab 14.10.

The [OpenAPI Specification](https://www.openapis.org/) (formerly the Swagger Specification) is an API description format for REST APIs.
This section shows you how to configure DAST API scanning using an OpenAPI Specification to provide information about the target API to test.
OpenAPI Specifications are provided as a file system resource or URL. Both JSON and YAML OpenAPI formats are supported.

DAST API uses an OpenAPI document to generate the request body. When a request body is required,
the body generation is limited to these body types:

- `application/x-www-form-urlencoded`
- `multipart/form-data`
- `application/json`
- `application/xml`

## OpenAPI and media types

A media type (formerly known as MIME type) is an identifier for file formats and format contents transmitted. A OpenAPI document lets you specify that a given operation can accept different media types, hence a given request can send data using different file content. As for example, a `PUT /user` operation to update user data could accept data in either XML (media type `application/xml`) or JSON (media type `application/json`) format.
OpenAPI 2.x lets you specify the accepted media types globally or per operation, and OpenAPI 3.x lets you specify the accepted media types per operation. DAST API will check the listed media types, and try to produce sample data for each supported media type.

- In [GitLab 14.10 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/333304), the default behavior is to select one of the supported media types to use. The first supported media type is chosen from the list. This behavior is configurable.
- In GitLab 14.9 and earlier, the default behavior is to perform testing using all supported media types. This means if two media types are listed (for example, `application/json` and `application/xml`), testing are performed using JSON, and then the same tests using XML.

Testing the same operation (for example, `POST /user`) using different media types (for example, `application/json` and `application/xml`) is not always desirable.
For example, if the target application executes the same code regardless of the request content type, it will take longer to finish the test session, and it may report duplicated vulnerabilities related to the request body depending on the target app.

The environment variable `DAST_API_OPENAPI_ALL_MEDIA_TYPES` lets you specify whether or not to use all supported media types instead of one when generating requests for a given operation. When the environment variable `DAST_API_OPENAPI_ALL_MEDIA_TYPES` is set to any value, DAST API tries to generate requests for all supported media types instead of one in a given operation. This will cause testing to take longer as testing is repeated for each provided media type.

Alternatively, the variable `DAST_API_OPENAPI_MEDIA_TYPES` is used to provide a list of media types that will each be tested. Providing more than one media type causes testing to take longer, as testing is performed for each media type selected. When the environment variable `DAST_API_OPENAPI_MEDIA_TYPES` is set to a list of media types, only the listed media types are included when creating requests.

Multiple media types in `DAST_API_OPENAPI_MEDIA_TYPES` are separated by a colon (`:`). For example, to limit request generation to the media types `application/x-www-form-urlencoded` and `multipart/form-data`, set the environment variable `DAST_API_OPENAPI_MEDIA_TYPES` to `application/x-www-form-urlencoded:multipart/form-data`. Only supported media types in this list are included when creating requests, though non-supported media types are always skipped. A media type text may contain different sections. For example, `application/vnd.api+json; charset=UTF-8`, is a compound of `type "/" [tree "."] subtype ["+" suffix]* [";" parameter]`. Parameters are not taken into account when performing the filtering media types on request generation.

The environment variables `DAST_API_OPENAPI_ALL_MEDIA_TYPES` and `DAST_API_OPENAPI_MEDIA_TYPES` allow you to decide how to handle media types. These settings are mutually exclusive. If both are enabled, DAST API reports an error.

### Configure DAST API with an OpenAPI Specification

To configure DAST API scanning with an OpenAPI Specification:

1. [Include](../../../../ci/yaml/index.md#includetemplate)
   the [`DAST-API.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST-API.gitlab-ci.yml) in your `.gitlab-ci.yml` file.

1. The [configuration file](variables.md#configuration-files) has several testing profiles defined with different checks enabled. We recommend that you start with the `Quick` profile.
   Testing with this profile completes faster, allowing for easier configuration validation.
   Provide the profile by adding the `DAST_API_PROFILE` CI/CD variable to your `.gitlab-ci.yml` file.

1. Provide the location of the OpenAPI Specification as either a file or URL.
   Specify the location by adding the `DAST_API_OPENAPI` variable.

1. The target API instance's base URL is also required. Provide it by using the `DAST_API_TARGET_URL`
   variable or an `environment_url.txt` file.

   Adding the URL in an `environment_url.txt` file at your project's root is great for testing in
   dynamic environments. To run DAST API against an app dynamically created during a GitLab CI/CD
   pipeline, have the app persist its URL in an `environment_url.txt` file. DAST API
   automatically parses that file to find its scan target. You can see an
   [example of this in our Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml).

Complete example configuration of using an OpenAPI Specification:

```yaml
stages:
  - dast

include:
  - template: DAST-API.gitlab-ci.yml

variables:
  DAST_API_PROFILE: Quick
  DAST_API_OPENAPI: test-api-specification.json
  DAST_API_TARGET_URL: http://test-deployment/
```

This is a minimal configuration for DAST API. From here you can:

- [Run your first scan](#running-your-first-scan).
- [Add authentication](customizing_analyzer_settings.md#authentication).
- Learn how to [handle false positives](#handling-false-positives).

## HTTP Archive (HAR)

The [HTTP Archive format (HAR)](../../api_fuzzing/create_har_files.md) is an archive file format for
logging HTTP transactions. When used with the GitLab DAST API scanner, the HAR file must contain
records of calling the web API to test. The DAST API scanner extracts all of the requests and uses them
to perform testing.

You can use various tools to generate HAR files:

- [Insomnia Core](https://insomnia.rest/): API client
- [Chrome](https://www.google.com/chrome/): Browser
- [Firefox](https://www.mozilla.org/en-US/firefox/): Browser
- [Fiddler](https://www.telerik.com/fiddler): Web debugging proxy
- [GitLab HAR Recorder](https://gitlab.com/gitlab-org/security-products/har-recorder): Command line

WARNING:
HAR files may contain sensitive information such as authentication tokens, API keys, and session
cookies. We recommend that you review the HAR file contents before adding them to a repository.

### DAST API scanning with a HAR file

To configure DAST API to use a HAR file that provides information about the target API to test:

1. [Include](../../../../ci/yaml/index.md#includetemplate)
   the [`DAST-API.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST-API.gitlab-ci.yml) in your `.gitlab-ci.yml` file.

1. The [configuration file](variables.md#configuration-files) has several testing profiles defined with different checks enabled. We recommend that you start with the `Quick` profile.
   Testing with this profile completes faster, allowing for easier configuration validation.

   Provide the profile by adding the `DAST_API_PROFILE` CI/CD variable to your `.gitlab-ci.yml` file.

1. Provide the location of the HAR file. You can provide the location as a file path
   or URL. [URL support was introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/285020) in GitLab 13.10 and later. Specify the location by adding the `DAST_API_HAR` variable.

1. The target API instance's base URL is also required. Provide it by using the `DAST_API_TARGET_URL`
   variable or an `environment_url.txt` file.

   Adding the URL in an `environment_url.txt` file at your project's root is great for testing in
   dynamic environments. To run DAST API against an app dynamically created during a GitLab CI/CD
   pipeline, have the app persist its URL in an `environment_url.txt` file. DAST API
   automatically parses that file to find its scan target. You can see an
   [example of this in our Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml).

Complete example configuration of using an HAR file:

```yaml
stages:
  - dast

include:
  - template: DAST-API.gitlab-ci.yml

variables:
  DAST_API_PROFILE: Quick
  DAST_API_HAR: test-api-recording.har
  DAST_API_TARGET_URL: http://test-deployment/
```

This example is a minimal configuration for DAST API. From here you can:

- [Run your first scan](#running-your-first-scan).
- [Add authentication](customizing_analyzer_settings.md#authentication).
- Learn how to [handle false positives](#handling-false-positives).

## GraphQL Schema

> - Support for GraphQL Schema was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352780) in GitLab 15.4.

GraphQL is a query language for your API and an alternative to REST APIs.
DAST API supports testing GraphQL endpoints multiple ways:

- Test using the GraphQL Schema. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352780) in GitLab 15.4.
- Test using a recording (HAR) of GraphQL queries.
- Test using a Postman Collection containing GraphQL queries.

This section documents how to test using a GraphQL schema. The GraphQL schema support in
DAST API is able to query the schema from endpoints that support [introspection](https://graphql.org/learn/introspection/).
Introspection is enabled by default to allow tools like GraphiQL to work.
For details on how to enable introspection, see your GraphQL framework documentation.

### DAST API scanning with a GraphQL endpoint URL

The GraphQL support in DAST API is able to query a GraphQL endpoint for the schema.

NOTE:
The GraphQL endpoint must support introspection queries for this method to work correctly.

To configure DAST API to use a GraphQL endpoint URL that provides information about the target API to test:

1. [Include](../../../../ci/yaml/index.md#includetemplate)
   the [`DAST-API.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST-API.gitlab-ci.yml) in your `.gitlab-ci.yml` file.

1. Provide the path to the GraphQL endpoint, for example `/api/graphql`. Specify the location by adding the `DAST_API_GRAPHQL` variable.

1. The target API instance's base URL is also required. Provide it by using the `DAST_API_TARGET_URL`
   variable or an `environment_url.txt` file.

   Adding the URL in an `environment_url.txt` file at your project's root is great for testing in
   dynamic environments. See the [dynamic environment solutions](../troubleshooting.md#dynamic-environment-solutions) section of our documentation for more information.

Complete example configuration of using a GraphQL endpoint path:

```yaml
stages:
  - dast

include:
  - template: DAST-API.gitlab-ci.yml

dast_api:
  variables:
    DAST_API_GRAPHQL: /api/graphql
    DAST_API_TARGET_URL: http://test-deployment/
```

This example is a minimal configuration for DAST API. From here you can:

- [Run your first scan](#running-your-first-scan).
- [Add authentication](customizing_analyzer_settings.md#authentication).
- Learn how to [handle false positives](#handling-false-positives).

### DAST API scanning with a GraphQL Schema file

DAST API can use a GraphQL schema file to understand and test a GraphQL endpoint that has introspection disabled. To use a GraphQL schema file, it must be in the introspection JSON format. A GraphQL schema can be converted to a the introspection JSON format using an online 3rd party tool: [https://transform.tools/graphql-to-introspection-json](https://transform.tools/graphql-to-introspection-json).

To configure DAST API to use a GraphQL schema file that provides information about the target API to test:

1. [Include](../../../../ci/yaml/index.md#includetemplate)
   the [`DAST-API.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST-API.gitlab-ci.yml) in your `.gitlab-ci.yml` file.

1. Provide the GraphQL endpoint path, for example `/api/graphql`. Specify the path by adding the `DAST_API_GRAPHQL` variable.

1. Provide the location of the GraphQL schema file. You can provide the location as a file path
   or URL. Specify the location by adding the `DAST_API_GRAPHQL_SCHEMA` variable.

1. The target API instance's base URL is also required. Provide it by using the `DAST_API_TARGET_URL`
   variable or an `environment_url.txt` file.

   Adding the URL in an `environment_url.txt` file at your project's root is great for testing in
   dynamic environments. See the [dynamic environment solutions](../troubleshooting.md#dynamic-environment-solutions) section of our documentation for more information.

Complete example configuration of using an GraphQL schema file:

```yaml
stages:
  - dast

include:
  - template: DAST-API.gitlab-ci.yml

dast_api:
  variables:
    DAST_API_GRAPHQL: /api/graphql
    DAST_API_GRAPHQL_SCHEMA: test-api-graphql.schema
    DAST_API_TARGET_URL: http://test-deployment/
```

Complete example configuration of using an GraphQL schema file URL:

```yaml
stages:
  - dast

include:
  - template: DAST-API.gitlab-ci.yml

dast_api:
  variables:
    DAST_API_GRAPHQL: /api/graphql
    DAST_API_GRAPHQL_SCHEMA: http://file-store/files/test-api-graphql.schema
    DAST_API_TARGET_URL: http://test-deployment/
```

This example is a minimal configuration for DAST API. From here you can:

- [Run your first scan](#running-your-first-scan).
- [Add authentication](customizing_analyzer_settings.md#authentication).
- Learn how to [handle false positives](#handling-false-positives).

## Postman Collection

The [Postman API Client](https://www.postman.com/product/api-client/) is a popular tool that
developers and testers use to call various types of APIs. The API definitions
[can be exported as a Postman Collection file](https://learning.postman.com/docs/getting-started/importing-and-exporting-data/#exporting-postman-data)
for use with DAST API. When exporting, make sure to select a supported version of Postman
Collection: v2.0 or v2.1.

When used with the GitLab DAST API scanner, Postman Collections must contain definitions of the web API to
test with valid data. The DAST API scanner extracts all the API definitions and uses them to perform
testing.

WARNING:
Postman Collection files may contain sensitive information such as authentication tokens, API keys,
and session cookies. We recommend that you review the Postman Collection file contents before adding
them to a repository.

### DAST API scanning with a Postman Collection file

To configure DAST API to use a Postman Collection file that provides information about the target
API to test:

1. [Include](../../../../ci/yaml/index.md#includetemplate)
   the [`DAST-API.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST-API.gitlab-ci.yml).

1. The [configuration file](variables.md#configuration-files) has several testing profiles defined with different checks enabled. We recommend that you start with the `Quick` profile.
   Testing with this profile completes faster, allowing for easier configuration validation.

   Provide the profile by adding the `DAST_API_PROFILE` CI/CD variable to your `.gitlab-ci.yml` file.

1. Provide the location of the Postman Collection file as either a file or URL. Specify the location by adding the `DAST_API_POSTMAN_COLLECTION` variable.

1. The target API instance's base URL is also required. Provide it by using the `DAST_API_TARGET_URL`
   variable or an `environment_url.txt` file.

   Adding the URL in an `environment_url.txt` file at your project's root is great for testing in
   dynamic environments. To run DAST API against an app dynamically created during a GitLab CI/CD
   pipeline, have the app persist its URL in an `environment_url.txt` file. DAST API
   automatically parses that file to find its scan target. You can see an
   [example of this in our Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml).

Complete example configuration of using a Postman collection:

```yaml
stages:
  - dast

include:
  - template: DAST-API.gitlab-ci.yml

variables:
  DAST_API_PROFILE: Quick
  DAST_API_POSTMAN_COLLECTION: postman-collection_serviceA.json
  DAST_API_TARGET_URL: http://test-deployment/
```

This is a minimal configuration for DAST API. From here you can:

- [Run your first scan](#running-your-first-scan).
- [Add authentication](customizing_analyzer_settings.md#authentication).
- Learn how to [handle false positives](#handling-false-positives).

### Postman variables

> - Support for Postman Environment file format was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/356312) in GitLab 15.1.
> - Support for multiple variable files was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/356312) in GitLab 15.1.
> - Support for Postman variable scopes: Global and Environment was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/356312) in GitLab 15.1.

#### Variables in Postman Client

Postman allows the developer to define placeholders that can be used in different parts of the
requests. These placeholders are called variables, as explained in [using variables](https://learning.postman.com/docs/sending-requests/variables/).
You can use variables to store and reuse values in your requests and scripts. For example, you can
edit the collection to add variables to the document:

![Edit collection variable tab View](../img/dast_api_postman_collection_edit_variable.png)

Or alternatively, you can add variables in an environment:

![Edit environment variables View](../img/dast_api_postman_environment_edit_variable.png)

You can then use the variables in sections such as URL, headers, and others:

![Edit request using variables View](../img/dast_api_postman_request_edit.png)

Postman has grown from a basic client tool with a nice UX experience to a more complex ecosystem that allows testing APIs with scripts, creating complex collections that trigger secondary requests, and setting variables along the way. Not every feature in the Postman ecosystem is supported. For example, scripts are not supported. The main focus of the Postman support is to ingest Postman Collection definitions that are used by the Postman Client and their related variables defined in the workspace, environments, and the collections themselves.

Postman allows creating variables in different scopes. Each scope has a different level of visibility in the Postman tools. For example, you can create a variable in a _global environment_ scope that is seen by every operation definition and workspace. You can also create a variable in a specific _environment_ scope that is only visible and used when that specific environment is selected for use. Some scopes are not always available, for example in the Postman ecosystem you can create requests in the Postman Client, these requests do not have a _local_ scope, but test scripts do.

Variable scopes in Postman can be a daunting topic and not everyone is familiar with it. We strongly recommend that you read [Variable Scopes](https://learning.postman.com/docs/sending-requests/variables/#variable-scopes) from Postman documentation before moving forward.

As mentioned above, there are different variable scopes, and each of them has a purpose and can be used to provide more flexibility to your Postman document. There is an important note on how values for variables are computed, as per Postman documentation:

> If a variable with the same name is declared in two different scopes, the value stored in the variable with narrowest scope is used. For example, if there is a global variable named `username` and a local variable named `username`, the local value is used when the request runs.

The following is a summary of the variable scopes supported by the Postman Client and DAST API:

- **Global Environment (Global) scope** is a special pre-defined environment that is available throughout a workspace. We can also refer to the _global environment_ scope as the _global_ scope. The Postman Client allows exporting the global environment into a JSON file, which can be used with DAST API.
- **Environment scope** is a named group of variables created by a user in the Postman Client.
  The Postman Client supports a single active environment along with the global environment. The variables defined in an active user-created environment take precedence over variables defined in the global environment. The Postman Client allows exporting your environment into a JSON file, which can be used with DAST API.
- **Collection scope** is a group of variables declared in a given collection. The collection variables are available to the collection where they have been declared and the nested requests or collections. Variables defined in the collection scope take precedence over the _global environment_ scope and also the _environment_ scope.
  The Postman Client can export one or more collections into a JSON file, this JSON file contains selected collections, requests, and collection variables.
- **DAST API Scope** is a new scope added by DAST API to allow users to provide extra variables, or override variables defined in other supported scopes. This scope is not supported by Postman. The _DAST API Scope_ variables are provided using a [custom JSON file format](#dast-api-scope-custom-json-file-format).
  - Override values defined in the environment or collection
  - Defining variables from scripts
  - Define a single row of data from the unsupported _data scope_
- **Data scope** is a group of variables in which their name and values come from JSON or CSV files. A Postman collection runner like [Newman](https://learning.postman.com/docs/running-collections/using-newman-cli/command-line-integration-with-newman/) or [Postman Collection Runner](https://learning.postman.com/docs/running-collections/intro-to-collection-runs/) executes the requests in a collection as many times as entries have the JSON or CSV file. A good use case for these variables is to automate tests using scripts in Postman.
  DAST API does **not** support reading data from a CSV or JSON file.
- **Local scope** are variables that are defined in Postman scripts. DAST API does **not** support Postman scripts and by extension, variables defined in scripts. You can still provide values for the script-defined variables by defining them in one of the supported scopes, or our custom JSON format.

Not all scopes are supported by DAST API and variables defined in scripts are not supported. The following table is sorted by broadest scope to narrowest scope.

| Scope              |Postman    | DAST API     | Comment  |
| ------------------ |:---------:|:------------:| :--------|
| Global Environment | Yes       | Yes          | Special pre-defined environment |
| Environment        | Yes       | Yes          | Named environments |
| Collection         | Yes       | Yes          | Defined in your postman collection |
| DAST API Scope     | No        | Yes          | Custom scope added by DAST API |
| Data               | Yes       | No           | External files in CSV or JSON format |
| Local              | Yes       | No           | Variables defined in scripts |

For more details on how to define variables and export variables in different scopes, see:

- [Defining collection variables](https://learning.postman.com/docs/sending-requests/variables/#defining-collection-variables)
- [Defining environment variables](https://learning.postman.com/docs/sending-requests/variables/#defining-environment-variables)
- [Defining global variables](https://learning.postman.com/docs/sending-requests/variables/#defining-global-variables)

##### Exporting from Postman Client

The Postman Client lets you export different file formats, for instance, you can export a Postman collection or a Postman environment.
The exported environment can be the global environment (which is always available) or can be any custom environment you previously have created. When you export a Postman Collection, it may contain only declarations for _collection_ and _local_ scoped variables; _environment_ scoped variables are not included.

To get the declaration for _environment_ scoped variables, you have to export a given environment at the time. Each exported file only includes variables from the selected environment.

For more details on exporting variables in different supported scopes, see:

- [Exporting collections](https://learning.postman.com/docs/getting-started/importing-and-exporting-data/#exporting-collections)
- [Exporting environments](https://learning.postman.com/docs/getting-started/importing-and-exporting-data/#exporting-environments)
- [Downloading global environments](https://learning.postman.com/docs/sending-requests/variables/#downloading-global-environments)

#### DAST API Scope, custom JSON file format

Our custom JSON file format is a JSON object where each object property represents a variable name and the property value represents the variable value. This file can be created using your favorite text editor, or it can be produced by an earlier job in your pipeline.

This example defines two variables `base_url` and `token` in the DAST API scope:

```json
{
  "base_url": "http://127.0.0.1/",
  "token": "Token 84816165151"
}
```

#### Using scopes with DAST API

The scopes: _global_, _environment_, _collection_, and _GitLab DAST API_ are supported in [GitLab 15.1 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/356312). GitLab 15.0 and earlier, supports only the _collection_, and _GitLab DAST API_ scopes.

The following table provides a quick reference for mapping scope files/URLs to DAST API configuration variables:

| Scope              |  How to Provide |
| ------------------ | --------------- |
| Global Environment | DAST_API_POSTMAN_COLLECTION_VARIABLES |
| Environment        | DAST_API_POSTMAN_COLLECTION_VARIABLES |
| Collection         | DAST_API_POSTMAN_COLLECTION           |
| DAST API Scope     | DAST_API_POSTMAN_COLLECTION_VARIABLES |
| Data               | Not supported   |
| Local              | Not supported   |

The Postman Collection document automatically includes any _collection_ scoped variables. The Postman Collection is provided with the configuration variable `DAST_API_POSTMAN_COLLECTION`. This variable can be set to a single [exported Postman collection](https://learning.postman.com/docs/getting-started/importing-and-exporting-data/#exporting-collections).

Variables from other scopes are provided through the `DAST_API_POSTMAN_COLLECTION_VARIABLES` configuration variable. The configuration variable supports a comma (`,`) delimited file list in [GitLab 15.1 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/356312). GitLab 15.0 and earlier, supports only one single file. The order of the files provided is not important as the files provide the needed scope information.

The configuration variable `DAST_API_POSTMAN_COLLECTION_VARIABLES` can be set to:

- [Exported Global environment](https://learning.postman.com/docs/sending-requests/variables/#downloading-global-environments)
- [Exported environments](https://learning.postman.com/docs/getting-started/importing-and-exporting-data/#exporting-environments)
- [DAST API Custom JSON format](#dast-api-scope-custom-json-file-format)

#### Undefined Postman variables

There is a chance that DAST API engine does not find all variables references that your Postman collection file is using. Some cases can be:

- You are using _data_ or _local_ scoped variables, and as stated previously these scopes are not supported by DAST API. Thus, assuming the values for these variables have not been provided through [the DAST API scope](#dast-api-scope-custom-json-file-format), then the values of the _data_ and _local_ scoped variables are undefined.
- A variable name was typed incorrectly, and the name does not match the defined variable.
- Postman Client supports a new dynamic variable that is not supported by DAST API.

When possible, DAST API follows the same behavior as the Postman Client does when dealing with undefined variables. The text of the variable reference remains the same, and there is no text substitution. The same behavior also applies to any unsupported dynamic variables.

For example, if a request definition in the Postman Collection references the variable `{{full_url}}` and the variable is not found it is left unchanged with the value `{{full_url}}`.

#### Dynamic Postman variables

In addition to variables that a user can define at various scope levels, Postman has a set of pre-defined variables called _dynamic_ variables. The [_dynamic_ variables](https://learning.postman.com/docs/writing-scripts/script-references/variables-list/) are already defined and their name is prefixed with a dollar sign (`$`), for instance, `$guid`. _Dynamic_ variables can be used like any other variable, and in the Postman Client, they produce random values during the request/collection run.

An important difference between DAST API and Postman is that DAST API returns the same value for each usage of the same dynamic variables. This differs from the Postman Client behavior which returns a random value on each use of the same dynamic variable. In other words, DAST API uses static values for dynamic variables while Postman uses random values.

The supported dynamic variables during the scanning process are:

| Variable    | Value       |
| ----------- | ----------- |
| `$guid` | `611c2e81-2ccb-42d8-9ddc-2d0bfa65c1b4` |
| `$isoTimestamp` | `2020-06-09T21:10:36.177Z` |
| `$randomAbbreviation` | `PCI` |
| `$randomAbstractImage` | `http://no-a-valid-host/640/480/abstract` |
| `$randomAdjective` | `auxiliary` |
| `$randomAlphaNumeric` | `a` |
| `$randomAnimalsImage` | `http://no-a-valid-host/640/480/animals` |
| `$randomAvatarImage` | `https://no-a-valid-host/path/to/some/image.jpg` |
| `$randomBankAccount` | `09454073` |
| `$randomBankAccountBic` | `EZIAUGJ1` |
| `$randomBankAccountIban` | `MU20ZPUN3039684000618086155TKZ` |
| `$randomBankAccountName` | `Home Loan Account` |
| `$randomBitcoin` | `3VB8JGT7Y4Z63U68KGGKDXMLLH5` |
| `$randomBoolean` | `true` |
| `$randomBs` | `killer leverage schemas` |
| `$randomBsAdjective` | `viral` |
| `$randomBsBuzz` | `repurpose` |
| `$randomBsNoun` | `markets` |
| `$randomBusinessImage` | `http://no-a-valid-host/640/480/business` |
| `$randomCatchPhrase` | `Future-proofed heuristic open architecture` |
| `$randomCatchPhraseAdjective` | `Business-focused` |
| `$randomCatchPhraseDescriptor` | `bandwidth-monitored` |
| `$randomCatchPhraseNoun` | `superstructure` |
| `$randomCatsImage` | `http://no-a-valid-host/640/480/cats` |
| `$randomCity` | `Spinkahaven` |
| `$randomCityImage` | `http://no-a-valid-host/640/480/city` |
| `$randomColor` | `fuchsia` |
| `$randomCommonFileExt` | `wav` |
| `$randomCommonFileName` | `well_modulated.mpg4` |
| `$randomCommonFileType` | `audio` |
| `$randomCompanyName` | `Grady LLC` |
| `$randomCompanySuffix` | `Inc` |
| `$randomCountry` | `Kazakhstan` |
| `$randomCountryCode` | `MD` |
| `$randomCreditCardMask` | `3622` |
| `$randomCurrencyCode` | `ZMK` |
| `$randomCurrencyName` | `Pound Sterling` |
| `$randomCurrencySymbol` | `£` |
| `$randomDatabaseCollation` | `utf8_general_ci` |
| `$randomDatabaseColumn` | `updatedAt` |
| `$randomDatabaseEngine` | `Memory` |
| `$randomDatabaseType` | `text` |
| `$randomDateFuture` | `Tue Mar 17 2020 13:11:50 GMT+0530 (India Standard Time)` |
| `$randomDatePast` | `Sat Mar 02 2019 09:09:26 GMT+0530 (India Standard Time)` |
| `$randomDateRecent` | `Tue Jul 09 2019 23:12:37 GMT+0530 (India Standard Time)` |
| `$randomDepartment` | `Electronics` |
| `$randomDirectoryPath` | `/usr/local/bin` |
| `$randomDomainName` | `trevor.info` |
| `$randomDomainSuffix` | `org` |
| `$randomDomainWord` | `jaden` |
| `$randomEmail` | `Iva.Kovacek61@no-a-valid-host.com` |
| `$randomExampleEmail` | `non-a-valid-user@example.net` |
| `$randomFashionImage` | `http://no-a-valid-host/640/480/fashion` |
| `$randomFileExt` | `war` |
| `$randomFileName` | `neural_sri_lanka_rupee_gloves.gdoc` |
| `$randomFilePath` | `/home/programming_chicken.cpio` |
| `$randomFileType` | `application` |
| `$randomFirstName` | `Chandler` |
| `$randomFoodImage` | `http://no-a-valid-host/640/480/food` |
| `$randomFullName` | `Connie Runolfsdottir` |
| `$randomHexColor` | `#47594a` |
| `$randomImageDataUri` | `data:image/svg+xml;charset=UTF-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20version%3D%221.1%22%20baseProfile%3D%22full%22%20width%3D%22undefined%22%20height%3D%22undefined%22%3E%20%3Crect%20width%3D%22100%25%22%20height%3D%22100%25%22%20fill%3D%22grey%22%2F%3E%20%20%3Ctext%20x%3D%220%22%20y%3D%2220%22%20font-size%3D%2220%22%20text-anchor%3D%22start%22%20fill%3D%22white%22%3Eundefinedxundefined%3C%2Ftext%3E%20%3C%2Fsvg%3E` |
| `$randomImageUrl` | `http://no-a-valid-host/640/480` |
| `$randomIngverb` | `navigating` |
| `$randomInt` | `494` |
| `$randomIP` | `241.102.234.100` |
| `$randomIPV6` | `dbe2:7ae6:119b:c161:1560:6dda:3a9b:90a9` |
| `$randomJobArea` | `Mobility` |
| `$randomJobDescriptor` | `Senior` |
| `$randomJobTitle` | `International Creative Liaison` |
| `$randomJobType` | `Supervisor` |
| `$randomLastName` | `Schneider` |
| `$randomLatitude` | `55.2099` |
| `$randomLocale` | `ny` |
| `$randomLongitude` | `40.6609` |
| `$randomLoremLines` | `Ducimus in ut mollitia.\nA itaque non.\nHarum temporibus nihil voluptas.\nIste in sed et nesciunt in quaerat sed.` |
| `$randomLoremParagraph` | `Ab aliquid odio iste quo voluptas voluptatem dignissimos velit. Recusandae facilis qui commodi ea magnam enim nostrum quia quis. Nihil est suscipit assumenda ut voluptatem sed. Esse ab voluptas odit qui molestiae. Rem est nesciunt est quis ipsam expedita consequuntur.` |
| `$randomLoremParagraphs` | `Voluptatem rem magnam aliquam ab id aut quaerat. Placeat provident possimus voluptatibus dicta velit non aut quasi. Mollitia et aliquam expedita sunt dolores nam consequuntur. Nam dolorum delectus ipsam repudiandae et ipsam ut voluptatum totam. Nobis labore labore recusandae ipsam quo.` |
| `$randomLoremSentence` | `Molestias consequuntur nisi non quod.` |
| `$randomLoremSentences` | `Et sint voluptas similique iure amet perspiciatis vero sequi atque. Ut porro sit et hic. Neque aspernatur vitae fugiat ut dolore et veritatis. Ab iusto ex delectus animi. Voluptates nisi iusto. Impedit quod quae voluptate qui.` |
| `$randomLoremSlug` | `eos-aperiam-accusamus, beatae-id-molestiae, qui-est-repellat` |
| `$randomLoremText` | `Quisquam asperiores exercitationem ut ipsum. Aut eius nesciunt. Et reiciendis aut alias eaque. Nihil amet laboriosam pariatur eligendi. Sunt ullam ut sint natus ducimus. Voluptas harum aspernatur soluta rem nam.` |
| `$randomLoremWord` | `est` |
| `$randomLoremWords` | `vel repellat nobis` |
| `$randomMACAddress` | `33:d4:68:5f:b4:c7` |
| `$randomMimeType` | `audio/vnd.vmx.cvsd` |
| `$randomMonth` | `February` |
| `$randomNamePrefix` | `Dr.` |
| `$randomNameSuffix` | `MD` |
| `$randomNatureImage` | `http://no-a-valid-host/640/480/nature` |
| `$randomNightlifeImage` | `http://no-a-valid-host/640/480/nightlife` |
| `$randomNoun` | `bus` |
| `$randomPassword` | `t9iXe7COoDKv8k3` |
| `$randomPeopleImage` | `http://no-a-valid-host/640/480/people` |
| `$randomPhoneNumber` | `700-008-5275` |
| `$randomPhoneNumberExt` | `27-199-983-3864` |
| `$randomPhrase` | `You can't program the monitor without navigating the mobile XML program!` |
| `$randomPrice` | `531.55` |
| `$randomProduct` | `Pizza` |
| `$randomProductAdjective` | `Unbranded` |
| `$randomProductMaterial` | `Steel` |
| `$randomProductName` | `Handmade Concrete Tuna` |
| `$randomProtocol` | `https` |
| `$randomSemver` | `7.0.5` |
| `$randomSportsImage` | `http://no-a-valid-host/640/480/sports` |
| `$randomStreetAddress` | `5742 Harvey Streets` |
| `$randomStreetName` | `Kuhic Island` |
| `$randomTransactionType` | `payment` |
| `$randomTransportImage` | `http://no-a-valid-host/640/480/transport` |
| `$randomUrl` | `https://no-a-valid-host.net` |
| `$randomUserAgent` | `Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.9.8; rv:15.6) Gecko/20100101 Firefox/15.6.6` |
| `$randomUserName` | `Jarrell.Gutkowski` |
| `$randomUUID` | `6929bb52-3ab2-448a-9796-d6480ecad36b` |
| `$randomVerb` | `navigate` |
| `$randomWeekday` | `Thursday` |
| `$randomWord` | `withdrawal` |
| `$randomWords` | `Samoa Synergistic sticky copying Grocery` |
| `$timestamp` | `1562757107` |

#### Example: Global Scope

In this example, [the _global_ scope is exported](https://learning.postman.com/docs/sending-requests/variables/#downloading-global-environments) from the Postman Client as `global-scope.json` and provided to DAST API through the `DAST_API_POSTMAN_COLLECTION_VARIABLES` configuration variable.

Here is an example of using `DAST_API_POSTMAN_COLLECTION_VARIABLES`:

```yaml
stages:
  - dast

include:
  - template: DAST-API.gitlab-ci.yml

variables:
  DAST_API_PROFILE: Quick
  DAST_API_POSTMAN_COLLECTION: postman-collection.json
  DAST_API_POSTMAN_COLLECTION_VARIABLES: global-scope.json
  DAST_API_TARGET_URL: http://test-deployment/
```

#### Example: Environment Scope

In this example, [the _environment_ scope is exported](https://learning.postman.com/docs/getting-started/importing-and-exporting-data/#exporting-environments) from the Postman Client as `environment-scope.json` and provided to DAST API through the `DAST_API_POSTMAN_COLLECTION_VARIABLES` configuration variable.

Here is an example of using `DAST_API_POSTMAN_COLLECTION_VARIABLES`:

```yaml
stages:
  - dast

include:
  - template: DAST-API.gitlab-ci.yml

variables:
  DAST_API_PROFILE: Quick
  DAST_API_POSTMAN_COLLECTION: postman-collection.json
  DAST_API_POSTMAN_COLLECTION_VARIABLES: environment-scope.json
  DAST_API_TARGET_URL: http://test-deployment/
```

#### Example: Collection Scope

The _collection_ scope variables are included in the exported Postman Collection file and provided through the `DAST_API_POSTMAN_COLLECTION` configuration variable.

Here is an example of using `DAST_API_POSTMAN_COLLECTION`:

```yaml
stages:
  - dast

include:
  - template: DAST-API.gitlab-ci.yml

variables:
  DAST_API_PROFILE: Quick
  DAST_API_POSTMAN_COLLECTION: postman-collection.json
  DAST_API_TARGET_URL: http://test-deployment/
```

#### Example: DAST API Scope

The DAST API Scope is used for two main purposes, defining _data_ and _local_ scope variables that are not supported by DAST API, and changing the value of an existing variable defined in another scope. The DAST API Scope is provided through the `DAST_API_POSTMAN_COLLECTION_VARIABLES` configuration variable.

Here is an example of using `DAST_API_POSTMAN_COLLECTION_VARIABLES`:

```yaml
stages:
  - dast

include:
  - template: DAST-API.gitlab-ci.yml

variables:
  DAST_API_PROFILE: Quick
  DAST_API_POSTMAN_COLLECTION: postman-collection.json
  DAST_API_POSTMAN_COLLECTION_VARIABLES: dast-api-scope.json
  DAST_API_TARGET_URL: http://test-deployment/
```

The file `dast-api-scope.json` uses our [custom JSON file format](#dast-api-scope-custom-json-file-format). This JSON is an object with key-value pairs for properties. The keys are the variables' names, and the values are the variables'
values. For example:

```json
{
  "base_url": "http://127.0.0.1/",
  "token": "Token 84816165151"
}
```

#### Example: Multiple Scopes

In this example, a _global_ scope, _environment_ scope, and _collection_ scope are configured. The first step is to export our various scopes.

- [Export the _global_ scope](https://learning.postman.com/docs/sending-requests/variables/#downloading-global-environments) as `global-scope.json`
- [Export the _environment_ scope](https://learning.postman.com/docs/getting-started/importing-and-exporting-data/#exporting-environments) as `environment-scope.json`
- Export the Postman Collection which includes the _collection_ scope as `postman-collection.json`

The Postman Collection is provided using the `DAST_API_POSTMAN_COLLECTION` variable, while the other scopes are provided using the `DAST_API_POSTMAN_COLLECTION_VARIABLES`. DAST API can identify which scope the provided files match using data provided in each file.

```yaml
stages:
  - dast

include:
  - template: DAST-API.gitlab-ci.yml

variables:
  DAST_API_PROFILE: Quick
  DAST_API_POSTMAN_COLLECTION: postman-collection.json
  DAST_API_POSTMAN_COLLECTION_VARIABLES: global-scope.json,environment-scope.json
  DAST_API_TARGET_URL: http://test-deployment/
```

#### Example: Changing a Variables Value

When using exported scopes, it's often the case that the value of a variable must be changed for use with DAST API. For example, a _collection_ scoped variable might contain a variable named `api_version` with a value of `v2`, while your test needs a value of `v1`. Instead of modifying the exported collection to change the value, the DAST API scope can be used to change its value. This works because the _DAST API_ scope takes precedence over all other scopes.

The _collection_ scope variables are included in the exported Postman Collection file and provided through the `DAST_API_POSTMAN_COLLECTION` configuration variable.

The DAST API Scope is provided through the `DAST_API_POSTMAN_COLLECTION_VARIABLES` configuration variable, but first, we must create the file.
The file `dast-api-scope.json` uses our [custom JSON file format](#dast-api-scope-custom-json-file-format). This JSON is an object with key-value pairs for properties. The keys are the variables' names, and the values are the variables'
values. For example:

```json
{
  "api_version": "v1"
}
```

Our CI definition:

```yaml
stages:
  - dast

include:
  - template: DAST-API.gitlab-ci.yml

variables:
  DAST_API_PROFILE: Quick
  DAST_API_POSTMAN_COLLECTION: postman-collection.json
  DAST_API_POSTMAN_COLLECTION_VARIABLES: dast-api-scope.json
  DAST_API_TARGET_URL: http://test-deployment/
```

#### Example: Changing a Variables Value with Multiple Scopes

When using exported scopes, it's often the case that the value of a variable must be changed for use with DAST API. For example, an _environment_ scope might contain a variable named `api_version` with a value of `v2`, while your test needs a value of `v1`. Instead of modifying the exported file to change the value, the DAST API scope can be used. This works because the _DAST API_ scope takes precedence over all other scopes.

In this example, a _global_ scope, _environment_ scope, _collection_ scope, and _DAST API_ scope are configured. The first step is to export and create our various scopes.

- [Export the _global_ scope](https://learning.postman.com/docs/sending-requests/variables/#downloading-global-environments) as `global-scope.json`
- [Export the _environment_ scope](https://learning.postman.com/docs/getting-started/importing-and-exporting-data/#exporting-environments) as `environment-scope.json`
- Export the Postman Collection which includes the _collection_ scope as `postman-collection.json`

The DAST API scope is used by creating a file `dast-api-scope.json` using our [custom JSON file format](#dast-api-scope-custom-json-file-format). This JSON is an object with key-value pairs for properties. The keys are the variables' names, and the values are the variables'
values. For example:

```json
{
  "api_version": "v1"
}
```

The Postman Collection is provided using the `DAST_API_POSTMAN_COLLECTION` variable, while the other scopes are provided using the `DAST_API_POSTMAN_COLLECTION_VARIABLES`. DAST API can identify which scope the provided files match using data provided in each file.

```yaml
stages:
  - dast

include:
  - template: DAST-API.gitlab-ci.yml

variables:
  DAST_API_PROFILE: Quick
  DAST_API_POSTMAN_COLLECTION: postman-collection.json
  DAST_API_POSTMAN_COLLECTION_VARIABLES: global-scope.json,environment-scope.json,dast-api-scope.json
  DAST_API_TARGET_URL: http://test-deployment/
```

## Running your first scan

When configured correctly, a CI/CD pipeline contains a `dast` stage and an `dast_api` job. The job only fails when an invalid configuration is provided. During typical operation, the job always succeeds even if vulnerabilities are identified during testing.

Vulnerabilities are displayed on the **Security** pipeline tab with the suite name. When testing against the repositories default branch, the DAST API vulnerabilities are also shown on the Security and Compliance's Vulnerability Report page.

To prevent an excessive number of reported vulnerabilities, the DAST API scanner limits the number of vulnerabilities it reports per operation.

## Viewing DAST API vulnerabilities

The DAST API analyzer produces a JSON report that is collected and used
[to populate the vulnerabilities into GitLab vulnerability screens](#view-details-of-a-dast-api-vulnerability).

See [handling false positives](#handling-false-positives) for information about configuration changes you can make to limit the number of false positives reported.

### View details of a DAST API vulnerability

Follow these steps to view details of a vulnerability:

1. You can view vulnerabilities in a project, or a merge request:

   - In a project, go to the project's **Secure > Vulnerability report**
     page. This page shows all vulnerabilities from the default branch only.
   - In a merge request, go the merge request's **Security** section and select the **Expand**
     button. DAST API vulnerabilities are available in a section labeled
     **DAST detected N potential vulnerabilities**. Select the title to display the vulnerability
     details.

1. Select the vulnerabilities title to display the details. The table below describes these details.

   | Field               | Description                                                                             |
   |:--------------------|:----------------------------------------------------------------------------------------|
   | Description         | Description of the vulnerability including what was modified.                           |
   | Project             | Namespace and project in which the vulnerability was detected.                          |
   | Method              | HTTP method used to detect the vulnerability.                                           |
   | URL                 | URL at which the vulnerability was detected.                                            |
   | Request             | The HTTP request that caused the vulnerability.                                         |
   | Unmodified Response | Response from an unmodified request. This is what a typical working response looks like.|
   | Actual Response     | Response received from test request.                                                    |
   | Evidence            | How we determined a vulnerability occurred.                                             |
   | Identifiers         | The DAST API check used to find this vulnerability.                                     |
   | Severity            | Severity of the vulnerability.                                                          |
   | Scanner Type        | Scanner used to perform testing.                                                        |

### Security Dashboard

The Security Dashboard is a good place to get an overview of all the security vulnerabilities in your groups, projects and
pipelines. For more information, see the [Security Dashboard documentation](../../security_dashboard/index.md).

### Interacting with the vulnerabilities

Once a vulnerability is found, you can interact with it. Read more on how to
[address the vulnerabilities](../../vulnerabilities/index.md).

### Handling False Positives

False positives can be handled in several ways:

- Dismiss the vulnerability.
- Some checks have several methods of detecting when a vulnerability is identified, called _Assertions_.
  Assertions can also be turned off and configured. For example, the DAST API scanner by default uses HTTP
  status codes to help identify when something is a real issue. If an API returns a 500 error during
  testing, this creates a vulnerability. This isn't always desired, as some frameworks return 500 errors often.
- Turn off the Check producing the false positive. This prevents the check from generating any
  vulnerabilities. Example checks are the SQL Injection Check, and JSON Hijacking Check.

#### Turn off a Check

Checks perform testing of a specific type and can be turned on and off for specific configuration
profiles. The provided [configuration files](variables.md#configuration-files) define several profiles that you
can use. The profile definition in the configuration file lists all the checks that are active
during a scan. To turn off a specific check, remove it from the profile definition in the
configuration file. The profiles are defined in the `Profiles` section of the configuration file.

Example profile definition:

```yaml
Profiles:
  - Name: Quick
    DefaultProfile: Empty
    Routes:
      - Route: *Route0
        Checks:
          - Name: ApplicationInformationCheck
          - Name: CleartextAuthenticationCheck
          - Name: FrameworkDebugModeCheck
          - Name: HtmlInjectionCheck
          - Name: InsecureHttpMethodsCheck
          - Name: JsonHijackingCheck
          - Name: JsonInjectionCheck
          - Name: SensitiveInformationCheck
          - Name: SessionCookieCheck
          - Name: SqlInjectionCheck
          - Name: TokenCheck
          - Name: XmlInjectionCheck
```

To turn off the JSON Hijacking Check you can remove these lines:

```yaml
          - Name: JsonHijackingCheck
```

This results in the following YAML:

```yaml
- Name: Quick
  DefaultProfile: Empty
  Routes:
    - Route: *Route0
      Checks:
        - Name: ApplicationInformationCheck
        - Name: CleartextAuthenticationCheck
        - Name: FrameworkDebugModeCheck
        - Name: HtmlInjectionCheck
        - Name: InsecureHttpMethodsCheck
        - Name: JsonInjectionCheck
        - Name: SensitiveInformationCheck
        - Name: SessionCookieCheck
        - Name: SqlInjectionCheck
        - Name: TokenCheck
        - Name: XmlInjectionCheck
```

#### Turn off an Assertion for a Check

Assertions detect vulnerabilities in tests produced by checks. Many checks support multiple Assertions such as Log Analysis, Response Analysis, and Status Code. When a vulnerability is found, the Assertion used is provided. To identify which Assertions are on by default, see the Checks default configuration in the configuration file. The section is called `Checks`.

This example shows the SQL Injection Check:

```yaml
- Name: SqlInjectionCheck
  Configuration:
    UserInjections: []
  Assertions:
    - Name: LogAnalysisAssertion
    - Name: ResponseAnalysisAssertion
    - Name: StatusCodeAssertion
```

Here you can see three Assertions are on by default. A common source of false positives is
`StatusCodeAssertion`. To turn it off, modify its configuration in the `Profiles` section. This
example provides only the other two Assertions (`LogAnalysisAssertion`,
`ResponseAnalysisAssertion`). This prevents `SqlInjectionCheck` from using `StatusCodeAssertion`:

```yaml
Profiles:
  - Name: Quick
    DefaultProfile: Empty
    Routes:
      - Route: *Route0
        Checks:
          - Name: ApplicationInformationCheck
          - Name: CleartextAuthenticationCheck
          - Name: FrameworkDebugModeCheck
          - Name: HtmlInjectionCheck
          - Name: InsecureHttpMethodsCheck
          - Name: JsonHijackingCheck
          - Name: JsonInjectionCheck
          - Name: SensitiveInformationCheck
          - Name: SessionCookieCheck
          - Name: SqlInjectionCheck
            Assertions:
              - Name: LogAnalysisAssertion
              - Name: ResponseAnalysisAssertion
          - Name: TokenCheck
          - Name: XmlInjectionCheck
```
