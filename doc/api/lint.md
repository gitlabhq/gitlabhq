---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# CI Lint API

## Validate the CI YAML config

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/5953) in GitLab 8.12.

Checks if CI/CD YAML configuration is valid. This endpoint validates basic CI/CD
configuration syntax. It doesn't have any namespace specific context.

```plaintext
POST /ci/lint
```

| Attribute  | Type    | Required | Description |
| ---------- | ------- | -------- | -------- |
| `content`              | string     | yes      | The CI/CD configuration content. |
| `include_merged_yaml`  | boolean    | no       | If the [expanded CI/CD configuration](#yaml-expansion) should be included in the response. |

```shell
curl --header "Content-Type: application/json" "https://gitlab.example.com/api/v4/ci/lint" --data '{"content": "{ \"image\": \"ruby:2.6\", \"services\": [\"postgres\"], \"before_script\": [\"bundle install\", \"bundle exec rake db:create\"], \"variables\": {\"DB_NAME\": \"postgres\"}, \"types\": [\"test\", \"deploy\", \"notify\"], \"rspec\": { \"script\": \"rake spec\", \"tags\": [\"ruby\", \"postgres\"], \"only\": [\"branches\"]}}"}'
```

Be sure to paste the exact contents of your GitLab CI/CD YAML config because YAML
is very sensitive about indentation and spacing.

Example responses:

- Valid content:

  ```json
  {
    "status": "valid",
    "errors": []
  }
  ```

- Invalid content:

  ```json
  {
    "status": "invalid",
    "errors": [
      "variables config should be a hash of key value pairs"
    ]
  }
  ```

- Without the content attribute:

  ```json
  {
    "error": "content is missing"
  }
  ```

### YAML expansion

The expansion only works for CI configurations that don't have local [includes](../ci/yaml/README.md#include).

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
  "merged_config": "---\n:another_test:\n  :stage: test\n  :script: echo 2\n:test:\n  :stage: test\n  :script: echo 1\n"
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

- Valid config:

```json
{
  "valid": true,
  "merged_yaml": "---\n:test_job:\n  :script: echo 1\n",
  "errors": [],
  "warnings": []
}
```

- Invalid config:

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
