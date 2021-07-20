---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# CI Lint API **(FREE)**

## Validate the CI YAML configuration

Checks if CI/CD YAML configuration is valid. This endpoint validates basic CI/CD
configuration syntax. It doesn't have any namespace specific context.

Access to this endpoint does not require authentication when the instance
[allows new sign ups](../user/admin_area/settings/sign_up_restrictions.md#disable-new-sign-ups)
and:

- Does not have an [allowlist or denylist](../user/admin_area/settings/sign_up_restrictions.md#allow-or-deny-sign-ups-using-specific-email-domains).
- Does not [require administrator approval for new sign ups](../user/admin_area/settings/sign_up_restrictions.md#require-administrator-approval-for-new-sign-ups).
- Does not have additional [sign up
  restrictions](../user/admin_area/settings/sign_up_restrictions.html#sign-up-restrictions).

Otherwise, authentication is required.

```plaintext
POST /ci/lint
```

| Attribute  | Type    | Required | Description |
| ---------- | ------- | -------- | -------- |
| `content`              | string     | yes      | The CI/CD configuration content. |
| `include_merged_yaml`  | boolean    | no       | If the [expanded CI/CD configuration](#yaml-expansion) should be included in the response. |

```shell
curl --header "Content-Type: application/json" --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/ci/lint" --data '{"content": "{ \"image\": \"ruby:2.6\", \"services\": [\"postgres\"], \"before_script\": [\"bundle install\", \"bundle exec rake db:create\"], \"variables\": {\"DB_NAME\": \"postgres\"}, \"types\": [\"test\", \"deploy\", \"notify\"], \"rspec\": { \"script\": \"rake spec\", \"tags\": [\"ruby\", \"postgres\"], \"only\": [\"branches\"]}}"}'
```

Be sure to paste the exact contents of your GitLab CI/CD YAML configuration because YAML
is very sensitive about indentation and spacing.

Example responses:

- Valid content:

  ```json
  {
    "status": "valid",
    "errors": [],
    "warnings": []
  }
  ```

- Valid content with warnings:

  ```json
  {
    "status": "valid",
    "errors": [],
    "warnings": ["jobs:job may allow multiple pipelines to run for a single action due to
    `rules:when` clause with no `workflow:rules` - read more:
    https://docs.gitlab.com/ee/ci/troubleshooting.html#pipeline-warnings"]
  }
  ```

- Invalid content:

  ```json
  {
    "status": "invalid",
    "errors": [
      "variables config should be a hash of key value pairs"
    ],
    "warnings": []
  }
  ```

- Without the content attribute:

  ```json
  {
    "error": "content is missing"
  }
  ```

### YAML expansion

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/29568) in GitLab 13.5.

The CI lint returns an expanded version of the configuration. The expansion does not
work for CI configuration added with [`include: local`](../ci/yaml/index.md#includelocal),
or with [`extends:`](../ci/yaml/index.md#extends).

Example contents of a `.gitlab-ci.yml` passed to the CI Lint API with
`include_merged_yaml` set as true:

```yaml
include:
  remote: 'https://example.com/remote.yaml'

test:
  stage: test
  script:
    - echo 1
```

Example contents of `https://example.com/remote.yaml`:

```yaml
another_test:
  stage: test
  script:
    - echo 2
```

Example response:

```json
{
  "status": "valid",
  "errors": [],
  "merged_yaml": "---\n:another_test:\n  :stage: test\n  :script: echo 2\n:test:\n  :stage: test\n  :script: echo 1\n"
}
```

## Validate a CI YAML configuration with a namespace

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/231352) in GitLab 13.6.

Checks if CI/CD YAML configuration is valid. This endpoint has namespace
specific context.

```plaintext
POST /projects/:id/ci/lint
```

| Attribute  | Type    | Required | Description |
| ---------- | ------- | -------- | -------- |
| `content`  | string  | yes      | The CI/CD configuration content. |
| `dry_run`  | boolean | no       | Run [pipeline creation simulation](../ci/lint.md#pipeline-simulation), or only do static check. This is false by default. |

Example request:

```shell
curl --header "Content-Type: application/json" "https://gitlab.example.com/api/v4/projects/:id/ci/lint" --data '{"content": "{ \"image\": \"ruby:2.6\", \"services\": [\"postgres\"], \"before_script\": [\"bundle install\", \"bundle exec rake db:create\"], \"variables\": {\"DB_NAME\": \"postgres\"}, \"types\": [\"test\", \"deploy\", \"notify\"], \"rspec\": { \"script\": \"rake spec\", \"tags\": [\"ruby\", \"postgres\"], \"only\": [\"branches\"]}}"}'
```

Example responses:

- Valid configuration:

  ```json
  {
    "valid": true,
    "merged_yaml": "---\n:test_job:\n  :script: echo 1\n",
    "errors": [],
    "warnings": []
  }
  ```

- Invalid configuration:

  ```json
  {
    "valid": false,
    "merged_yaml": "---\n:test_job:\n  :script: echo 1\n",
    "errors": [
      "jobs config should contain at least one visible job"
    ],
    "warnings": []
  }
  ```

## Validate a project's CI configuration

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/231352) in GitLab 13.5.

Checks if a project's latest (`HEAD` of the project's default branch)
`.gitlab-ci.yml` configuration is valid. This endpoint uses all namespace
specific data available, including variables, local includes, and so on.

```plaintext
GET /projects/:id/ci/lint
```

| Attribute  | Type    | Required | Description |
| ---------- | ------- | -------- | -------- |
| `dry_run`  | boolean | no       | Run pipeline creation simulation, or only do static check. |

Example request:

```shell
curl "https://gitlab.example.com/api/v4/projects/:id/ci/lint"
```

Example responses:

- Valid configuration:

```json
{
  "valid": true,
  "merged_yaml": "---\n:test_job:\n  :script: echo 1\n",
  "errors": [],
  "warnings": []
}
```

- Invalid configuration:

```json
{
  "valid": false,
  "merged_yaml": "---\n:test_job:\n  :script: echo 1\n",
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
    - if: '$CI_PIPELINE_SOURCE=="merge_request_event"'
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
| curl "https://gitlab.com/api/v4/ci/lint?include_merged_yaml=true" \
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
{"status":"valid","errors":[],"merged_yaml":"---\n:.api_test:\n  :rules:\n  - :if: $CI_PIPELINE_SOURCE==\"merge_request_event\"\n    :changes:\n    - src/api/*\n:deploy:\n  :rules:\n  - :when: manual\n    :allow_failure: true\n  :extends:\n  - \".api_test\"\n  :script:\n  - echo \"hello world\"\n"}
```

Becomes:

```yaml
:.api_test:
  :rules:
  - :if: $CI_PIPELINE_SOURCE=="merge_request_event"
    :changes:
    - src/api/*
:deploy:
  :rules:
  - :when: manual
    :allow_failure: true
  :extends:
  - ".api_test"
  :script:
  - echo "hello world"
```

With a one-line command, you can:

1. Escape the YAML
1. Encode it in JSON
1. POST it to the API with curl
1. Format the response

```shell
jq --null-input --arg yaml "$(<example-gitlab-ci.yml)" '.content=$yaml' \
| curl "https://gitlab.com/api/v4/ci/lint?include_merged_yaml=true" \
--header 'Content-Type: application/json' --data @- \
| jq --raw-output '.merged_yaml | fromjson'
```
