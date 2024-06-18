---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# CI Lint API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

## Validate the CI/CD configuration for a namespace

Checks if CI/CD YAML configuration is valid. This endpoint has namespace
specific context.

```plaintext
POST /projects/:id/ci/lint
```

| Attribute      | Type    | Required | Description |
|----------------|---------|----------|-------------|
| `content`      | string  | Yes      | The CI/CD configuration content. |
| `dry_run`      | boolean | No       | Run [pipeline creation simulation](../ci/lint.md#simulate-a-pipeline), or only do static check. Default: `false`. |
| `include_jobs` | boolean | No       | If the list of jobs that would exist in a static check or pipeline simulation should be included in the response. Default: `false`. |
| `ref`          | string  | No       | When `dry_run` is `true`, sets the branch or tag context to use to validate the CI/CD YAML configuration. Defaults to the project's default branch when not set. |

Example request:

```shell
curl --header "Content-Type: application/json" "https://gitlab.example.com/api/v4/projects/:id/ci/lint" --data '{"content": "{ \"image\": \"ruby:2.6\", \"services\": [\"postgres\"], \"before_script\": [\"bundle install\", \"bundle exec rake db:create\"], \"variables\": {\"DB_NAME\": \"postgres\"}, \"types\": [\"test\", \"deploy\", \"notify\"], \"rspec\": { \"script\": \"rake spec\", \"tags\": [\"ruby\", \"postgres\"], \"only\": [\"branches\"]}}"}'
```

Example responses:

- Valid configuration:

  ```json
  {
    "valid": true,
    "merged_yaml": "---\ntest_job:\n  script: echo 1\n",
    "errors": [],
    "warnings": []
  }
  ```

- Invalid configuration:

  ```json
  {
    "valid": false,
    "merged_yaml": "---\ntest_job:\n  script: echo 1\n",
    "errors": [
      "jobs config should contain at least one visible job"
    ],
    "warnings": []
  }
  ```

## Validate a project's CI configuration

> - `sha` attribute [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/369212) in GitLab 16.5.
> - `sha` and `ref` [renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143098) to `content_ref` and `dry_run_ref` in GitLab 16.10.

Checks if a project's `.gitlab-ci.yml` configuration in a given ref (the
`content_ref` parameter, by default `HEAD` of the project's default branch) is valid.
This endpoint uses all namespace specific data available, including variables
and local includes.

```plaintext
GET /projects/:id/ci/lint
```

| Attribute      | Type    | Required | Description |
|----------------|---------|----------|-------------|
| `content_ref`  | string  | No       | The CI/CD configuration content is taken from this commit SHA, branch or tag. Defaults to the SHA of the head of the project's default branch when not set. |
| `dry_run_ref`  | string  | No       | When `dry_run` is `true`, sets the branch or tag context to use to validate the CI/CD YAML configuration. Defaults to the project's default branch when not set. |
| `dry_run`      | boolean | No       | Run pipeline creation simulation, or only do static check. |
| `include_jobs` | boolean | No       | If the list of jobs that would exist in a static check or pipeline simulation should be included in the response. Default: `false`. |
| `ref`          | string  | No       | (Deprecated) When `dry_run` is `true`, sets the branch or tag context to use to validate the CI/CD YAML configuration. Defaults to the project's default branch when not set. Use `dry_run_ref` instead. |
| `sha`          | string  | No       | (Deprecated) The CI/CD configuration content is taken from this commit SHA, branch or tag. Defaults to the SHA of the head of the project's default branch when not set. Use `content_ref` instead. |

Example request:

```shell
curl "https://gitlab.example.com/api/v4/projects/:id/ci/lint"
```

Example responses:

- Valid configuration:

```json
{
  "valid": true,
  "merged_yaml": "---\ntest_job:\n  script: echo 1\n",
  "errors": [],
  "warnings": []
}
```

- Invalid configuration:

```json
{
  "valid": false,
  "merged_yaml": "---\ntest_job:\n  script: echo 1\n",
  "errors": [
    "jobs config should contain at least one visible job"
  ],
  "warnings": []
}
```

## Use jq to create and process YAML & JSON payloads

To `POST` a YAML configuration to the CI Lint endpoint, it must be properly escaped and JSON encoded.
You can use `jq` and `curl` to escape and upload YAML to the GitLab API.

### Escape YAML for JSON encoding

To escape quotes and encode your YAML in a format suitable for embedding within
a JSON payload, you can use `jq`. For example, create a file named `example-gitlab-ci.yml`:

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

Next, use `jq` to escape and encode the YAML file into JSON:

```shell
jq --raw-input --slurp < example-gitlab-ci.yml
```

To escape and encode an input YAML file (`example-gitlab-ci.yml`), and `POST` it to the
GitLab API using `curl` and `jq` in a one-line command:

```shell
jq --null-input --arg yaml "$(<example-gitlab-ci.yml)" '.content=$yaml' \
| curl "https://gitlab.com/api/v4/projects/:id/ci/lint?include_merged_yaml=true" \
--header 'Content-Type: application/json' \
--data @-
```

### Parse a CI Lint response

To reformat the CI Lint response, you can use `jq`. You can pipe the CI Lint response to `jq`,
or store the API response as a text file and provide it as an argument:

```shell
jq --raw-output '.merged_yaml | fromjson' <your_input_here>
```

Example input:

```json
{"status":"valid","errors":[],"merged_yaml":"---\n.api_test:\n  rules:\n  - if: $CI_PIPELINE_SOURCE==\"merge_request_event\"\n    changes:\n    - src/api/*\ndeploy:\n  rules:\n  - when: manual\n    allow_failure: true\n  extends:\n  - \".api_test\"\n  script:\n  - echo \"hello world\"\n"}
```

Becomes:

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

With a one-line command, you can:

1. Escape the YAML
1. Encode it in JSON
1. POST it to the API with curl
1. Format the response

```shell
jq --null-input --arg yaml "$(<example-gitlab-ci.yml)" '.content=$yaml' \
| curl "https://gitlab.com/api/v4/projects/:id/ci/lint?include_merged_yaml=true" \
--header 'Content-Type: application/json' --data @- \
| jq --raw-output '.merged_yaml | fromjson'
```
