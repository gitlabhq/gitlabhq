---
stage: Verify
group: Pipeline Authoring
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Contribute to the CI/CD Schema
---

The [pipeline editor](../../ci/pipeline_editor/_index.md) uses a CI/CD schema to enhance
the authoring experience of our CI/CD configuration files. With the CI/CD schema, the editor can:

- Validate the content of the CI/CD configuration file as it is being written in the editor.
- Provide autocomplete functionality and suggest available keywords.
- Provide definitions of keywords through annotations.

As the rules and keywords for configuring our CI/CD configuration files change, so too
should our CI/CD schema.

## JSON Schemas

The CI/CD schema follows the [JSON Schema Draft-07](https://json-schema.org/draft-07/json-schema-release-notes)
specification. Although the CI/CD configuration file is written in YAML, it is converted
into JSON by using `monaco-yaml` before it is validated by the CI/CD schema.

If you're new to JSON schemas, consider checking out
[this guide](https://json-schema.org/learn/getting-started-step-by-step) for
a step-by-step introduction on how to work with JSON schemas.

## Update Keywords

The CI/CD schema is at [`app/assets/javascripts/editor/schema/ci.json`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/editor/schema/ci.json).
It contains all the keywords available for authoring CI/CD configuration files.
Check the [CI/CD YAML syntax reference](../../ci/yaml/_index.md) for a comprehensive list of
all available keywords.

All keywords are defined under `definitions`. We use these definitions as
[references](https://json-schema.org/learn/getting-started-step-by-step#references)
to share common data structures across the schema.

For example, this defines the `retry` keyword:

```json
{
  "definitions": {
    "retry": {
      "description": "Retry a job if it fails. Can be a simple integer or object definition.",
      "oneOf": [
        {
          "$ref": "#/definitions/retry_max"
        },
        {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "max": {
              "$ref": "#/definitions/retry_max"
            },
            "when": {
              "description": "Either a single or array of error types to trigger job retry.",
              "oneOf": [
                {
                  "$ref": "#/definitions/retry_errors"
                },
                {
                  "type": "array",
                  "items": {
                    "$ref": "#/definitions/retry_errors"
                  }
                }
              ]
            }
          }
        }
      ]
    }
  }
}
```

With this definition, the `retry` keyword is both a property of
the `job_template` definition and the `default` global keyword. Global keywords
that configure pipeline behavior (such as `workflow` and `stages`) are defined
under the topmost **properties** key.

```json
{
  "properties": {
    "default": {
      "type": "object",
      "properties": {
        "retry": {
          "$ref": "#/definitions/retry"
        },
      }
    }
  },
  "definitions": {
    "job_template": {
      "properties": {
        "retry": {
          "$ref": "#/definitions/retry"
        }
      },
    }
  }
}
```

## Guidelines for updating the schema

- Keep definitions atomic when possible, to be flexible with
  referencing keywords. For example, `workflow:rules` uses only a subset of
  properties in the `rules` definition. The `rules` properties have their
  own definitions, so we can reference them individually.
- When adding new keywords, consider adding a `description` with a link to the
  keyword definition in the documentation. This information shows up in the annotations
  when the user hovers over the keyword.
- For each property, consider if a `minimum`, `maximum`, or
  `default` values are required. Some values might be required, and in others we can set
  blank. In the blank case, we can add the following to the definition:

```json
{
  "keyword": {
    "oneOf": [
      {
        "type": "null"
      },
      ...
    ]
  }
}
```

## Test the schema

### Verify changes

1. Go to **CI/CD** > **Editor**.
1. Write your CI/CD configuration in the editor and verify that the schema validates
   it correctly.

### Write specs

All of the CI/CD schema specs are in [`spec/frontend/editor/schema/ci`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/spec/frontend/editor/schema/ci).
Legacy tests are in JSON, but we recommend writing all new tests in YAML.
You can write them as if you're adding a new `.gitlab-ci.yml` configuration file.

Tests are separated into **positive** tests and **negative** tests. Positive tests
are snippets of CI/CD configuration code that use the schema keywords as intended.
Conversely, negative tests give examples of the schema keywords being used incorrectly.
These tests ensure that the schema validates different examples of input as expected.

`ci_schema_spec.js` is responsible for running all of the tests against the schema.

A detailed explanation of how the tests are set up can be found in this
[merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/83047).

#### Update schema specs

If a YAML test does not exist for the specified keyword, create new files in
`yaml_tests/positive_tests` and `yaml_tests/negative_tests`. Otherwise, you can update
the existing tests:

1. Write both positive and negative tests to validate different kinds of input.
1. If you created new files, import them in `ci_schema_spec.js` and add each file to their
   corresponding object entries. For example:

   ```javascript
   import CacheYaml from './yaml_tests/positive_tests/cache.yml';
   import CacheNegativeYaml from './yaml_tests/negative_tests/cache.yml';

   // import your new test files
   import NewKeywordTestYaml from './yaml_tests/positive_tests/cache.yml';
   import NewKeywordTestNegativeYaml from './yaml_tests/negative_tests/cache.yml';

   describe('positive tests', () => {
     it.each(
       Object.entries({
         CacheYaml,
         NewKeywordTestYaml, // add positive test here
       }),
     )('schema validates %s', (_, input) => {
       expect(input).toValidateJsonSchema(schema);
     });
   });

   describe('negative tests', () => {
     it.each(
       Object.entries({
         CacheNegativeYaml,
         NewKeywordTestYaml, // add negative test here
       }),
     )('schema validates %s', (_, input) => {
       expect(input).not.toValidateJsonSchema(schema);
     });
   });
   ```

1. Run the command `yarn jest spec/frontend/editor/schema/ci/ci_schema_spec.js`
   and verify that all the tests successfully pass.

If the spec covers a change to an existing keyword and it affects the legacy JSON
tests, update them as well.
