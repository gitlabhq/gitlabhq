---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: index, howto
---

# Contribute to the CI Schema **(FREE)**

The [pipeline editor](../../ci/pipeline_editor/index.md) uses a CI schema to enhance
the authoring experience of our CI configuration files. With the CI schema, the editor can:

- Validate the content of the CI configuration file as it is being written in the editor.
- Provide autocomplete functionality and suggest available keywords.
- Provide definitions of keywords through annotations.

As the rules and keywords for configuring our CI configuration files change, so too
should our CI schema.

This feature is behind the [`schema_linting`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/feature_flags/development/schema_linting.yml)
feature flag for self-managed instances, and is enabled for GitLab.com.

## JSON Schemas

The CI schema follows the [JSON Schema Draft-07](https://json-schema.org/draft-07/json-schema-release-notes.html)
specification. Although the CI configuration file is written in YAML, it is converted
into JSON by using `monaco-yaml` before it is validated by the CI schema.

If you're new to JSON schemas, consider checking out
[this guide](https://json-schema.org/learn/getting-started-step-by-step) for
a step-by-step introduction on how to work with JSON schemas.

## Update Keywords

The CI schema is at [`app/assets/javascripts/editor/schema/ci.json`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/editor/schema/ci.json).
It contains all the keywords available for authoring CI configuration files.
Check the [keyword reference](../../ci/yaml/index.md) for a comprehensive list of
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

For now, the CI schema can only be tested manually. To verify the behavior is correct:

1. Enable the `schema_linting` feature flag.
1. Go to **CI/CD** > **Editor**.
1. Write your CI/CD configuration in the editor and verify that the schema validates
   it correctly.
