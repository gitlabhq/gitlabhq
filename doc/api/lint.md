---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI Lint API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to [validate your GitLab CI/CD configuration](../ci/yaml/lint.md).

These endpoints use JSON-encoded YAML content. In some cases, it can be helpful to use third-party tools like [`jq`](https://jqlang.org/) to properly format your YAML content before making a request. This can be helpful if you want to maintain the format of your CI/CD configuration.

For example, the following command uses JQ to properly escape a given YAML file, encode it as JSON, and make a request to the API.

```shell
jq --null-input --arg yaml "$(<example-gitlab-ci.yml)" '.content=$yaml' \
| curl --url "https://gitlab.com/api/v4/projects/:id/ci/lint?include_merged_yaml=true" \
--header 'Content-Type: application/json' \
--data @-
```

1. Create a YAML file named `example-gitlab-ci.yml`:

   ```yaml
   .api_test:
     rules:
       - if: $CI_PIPELINE_SOURCE=="merge_request_event"
         changes:
           - src/api/*
   deploy:
     extends:
       - .api_test
     rules:
       - when: manual
         allow_failure: true
     script:
       - echo "hello world"
   ```

1. To escape and encode an input YAML file (`example-gitlab-ci.yml`), then `POST` it to the
   GitLab API, create a one-line command that combines `curl` and `jq`:

   ```shell
   jq --null-input --arg yaml "$(<example-gitlab-ci.yml)" '.content=$yaml' \
   | curl --url "https://gitlab.com/api/v4/projects/:id/ci/lint?include_merged_yaml=true" \
       --header 'Content-Type: application/json' \
       --data @-
   ```

## Parse responses from this API

To reformat responses from the CI Lint API, either:

- Pipe the CI Lint response directly to `jq`.
- Store the API response as a text file, and provide it to `jq` as an argument, like this:

  ```shell
  jq --raw-output '.merged_yaml | fromjson' <your_input_here>
  ```

For example, this JSON array:

```json
{"valid":"true","errors":[],"merged_yaml":"---\n.api_test:\n  rules:\n  - if: $CI_PIPELINE_SOURCE==\"merge_request_event\"\n    changes:\n    - src/api/*\ndeploy:\n  rules:\n  - when: manual\n    allow_failure: true\n  extends:\n  - \".api_test\"\n  script:\n  - echo \"hello world\"\n"}
```

When parsed and reformatted, the resulting YAML file contains:

```yaml
.api_test:
  rules:
  - if: $CI_PIPELINE_SOURCE=="merge_request_event"
    changes:
    - src/api/*
deploy:
  rules:
  - when: manual
    allow_failure: true
  extends:
  - ".api_test"
  script:
  - echo "hello world"
```

## Validate a new CI/CD configuration

Validates a new `.gitlab-ci.yml` configuration for a specified project.
This endpoint validates the CI/CD configuration in the context of the
project, including:

- Using the project's CI/CD variables.
- Searching the project's files for `include:local` entries.

```plaintext
POST /projects/:id/ci/lint
```

| Attribute      | Type    | Required | Description |
|----------------|---------|----------|-------------|
| `content`      | string  | Yes      | The CI/CD configuration content. |
| `dry_run`      | boolean | No       | Run [pipeline creation simulation](../ci/yaml/lint.md#simulate-a-pipeline), or only do static check. Default: `false`. |
| `include_jobs` | boolean | No       | If the list of jobs that would exist in a static check or pipeline simulation should be included in the response. Default: `false`. |
| `ref`          | string  | No       | When `dry_run` is `true`, sets the branch or tag context to use to validate the CI/CD YAML configuration. Defaults to the project's default branch when not set. |

Example request:

```shell
curl --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/:id/ci/lint" \
  --data @- <<'EOF'
{
  "content": "{
    \"image\": \"ruby:2.6\",
    \"services\": [\"postgres\"],
    \"before_script\": [
      \"bundle install\",
      \"bundle exec rake db:create\"
    ],
    \"variables\": {
      \"DB_NAME\": \"postgres\"
    },
    \"stages\": [\"test\", \"deploy\", \"notify\"],
    \"rspec\": {
      \"script\": \"rake spec\",
      \"tags\": [\"ruby\", \"postgres\"],
      \"only\": [\"branches\"]
    }
  }"
}
EOF
```

Example responses:

- Valid configuration:

  ```json
  {
    "valid": true,
    "merged_yaml": "---\ntest_job:\n  script: echo 1\n",
    "errors": [],
    "warnings": [],
    "includes": []
  }
  ```

- Invalid configuration:

  ```json
  {
    "valid": false,
    "errors": [
      "jobs config should contain at least one visible job"
    ],
    "warnings": [],
    "merged_yaml": "---\n\".job\":\n  script:\n  - echo \"A hidden job\"\n",
    "includes": []
  }
  ```

## Validate an existing CI/CD configuration

{{< history >}}

- `sha` attribute [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/369212) in GitLab 16.5.
- `sha` and `ref` [renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143098) to `content_ref` and `dry_run_ref` in GitLab 16.10.

{{< /history >}}

Validates an existing `.gitlab-ci.yml` configuration for a specified project.
This endpoint validates the CI/CD configuration in the context of the
project, including:

- Using the project's CI/CD variables.
- Searching the project's files for `include:local` entries.

```plaintext
GET /projects/:id/ci/lint
```

| Attribute      | Type    | Required | Description |
|----------------|---------|----------|-------------|
| `content_ref`  | string  | No       | The CI/CD configuration content is taken from this commit SHA, branch or tag. Defaults to the SHA of the head of the project's default branch when not set. |
| `dry_run`      | boolean | No       | Run pipeline creation simulation, or only do static check. |
| `dry_run_ref`  | string  | No       | Of `dry_run` is `true`, sets the branch or tag context to use to validate the CI/CD YAML configuration. Defaults to the project's default branch when not set. |
| `include_jobs` | boolean | No       | If the list of jobs that would exist in a static check or pipeline simulation should be included in the response. Default: `false`. |
| `ref`          | string  | No       | (Deprecated) When `dry_run` is `true`, sets the branch or tag context to use to validate the CI/CD YAML configuration. Defaults to the project's default branch when not set. Use `dry_run_ref` instead. |
| `sha`          | string  | No       | (Deprecated) The CI/CD configuration content is taken from this commit SHA, branch or tag. Defaults to the SHA of the head of the project's default branch when not set. Use `content_ref` instead. |

Example request:

```shell
curl --url "https://gitlab.example.com/api/v4/projects/:id/ci/lint"
```

Example responses:

- Valid configuration, with `include.yml` as an [included file](../ci/yaml/_index.md#include)
  and `include_jobs` set to `true`:

  ```json
  {
    "valid": true,
    "errors": [],
    "warnings": [],
    "merged_yaml": "---\ninclude-job:\n  script:\n  - echo \"An included job\"\njob:\n  rules:\n  - if: \"$CI_COMMIT_BRANCH\"\n  script:\n  - echo \"A test job\"\n",
    "includes": [
      {
        "type": "local",
        "location": "include.yml",
        "blob": "https://gitlab.example.com/test-group/test-project/-/blob/ef5014c045873c5c4ffeb7a2f5be021a1d3ed703/include.yml",
        "raw": "https://gitlab.example.com/test-group/test-project/-/raw/ef5014c045873c5c4ffeb7a2f5be021a1d3ed703/include.yml",
        "extra": {},
        "context_project": "test-group/test-project",
        "context_sha": "ef5014c045873c5c4ffeb7a2f5be021a1d3ed703"
      }
    ],
    "jobs": [
      {
        "name": "include-job",
        "stage": "test",
        "before_script": [],
        "script": [
          "echo \"An included job\""
        ],
        "after_script": [],
        "tag_list": [],
        "only": {
          "refs": [
            "branches",
            "tags"
          ]
        },
        "except": null,
        "environment": null,
        "when": "on_success",
        "allow_failure": false,
        "needs": null
      },
      {
        "name": "job",
        "stage": "test",
        "before_script": [],
        "script": [
          "echo \"A test job\""
        ],
        "after_script": [],
        "tag_list": [],
        "only": null,
        "except": null,
        "environment": null,
        "when": "on_success",
        "allow_failure": false,
        "needs": null
      }
    ]
  }
  ```

- Invalid configuration:

  ```json
  {
    "valid": false,
    "errors": [
      "jobs config should contain at least one visible job"
    ],
    "warnings": [],
    "merged_yaml": "---\n\".job\":\n  script:\n  - echo \"A hidden job\"\n",
    "includes": []
  }
  ```
