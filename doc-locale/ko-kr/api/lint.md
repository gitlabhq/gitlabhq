---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI Lint API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 [GitLab CI/CD 구성을 검증](../ci/yaml/lint.md)하세요.

이러한 엔드포인트는 JSON으로 인코딩된 YAML 콘텐츠를 사용합니다. 경우에 따라 [`jq`](https://jqlang.org/)와 같은 타사 도구를 사용하여 요청을 하기 전에 YAML 콘텐츠를 올바르게 포맷하는 것이 도움이 될 수 있습니다. CI/CD 구성의 형식을 유지하려면 이것이 도움이 될 수 있습니다.

예를 들어 다음 명령은 JQ를 사용하여 주어진 YAML 파일을 올바르게 이스케이프하고, JSON으로 인코딩한 후 API에 요청합니다.

```shell
jq --null-input --arg yaml "$(<example-gitlab-ci.yml)" '.content=$yaml' \
| curl --url "https://gitlab.com/api/v4/projects/:id/ci/lint?include_merged_yaml=true" \
--header 'Content-Type: application/json' \
--data @-
```

1. `example-gitlab-ci.yml` 이름의 YAML 파일을 만드세요:

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

1. 입력 YAML 파일(`example-gitlab-ci.yml`)을 이스케이프하고 인코딩한 후 GitLab API에 `POST` 방식으로 보내려면 `curl`과 `jq`를 결합하는 한 줄 명령을 만드세요:

   ```shell
   jq --null-input --arg yaml "$(<example-gitlab-ci.yml)" '.content=$yaml' \
   | curl --url "https://gitlab.com/api/v4/projects/:id/ci/lint?include_merged_yaml=true" \
       --header 'Content-Type: application/json' \
       --data @-
   ```

## 이 API에서 응답 구문 분석 {#parse-responses-from-this-api}

CI Lint API에서 응답을 다시 포맷하려면 다음 중 하나를 수행하세요:

- CI Lint 응답을 `jq`로 직접 전달합니다.
- API 응답을 텍스트 파일로 저장한 후 `jq`에 인수로 제공하세요. 예를 들면 다음과 같습니다:

  ```shell
  jq --raw-output '.merged_yaml | fromjson' <your_input_here>
  ```

예를 들어 이 JSON 배열입니다:

```json
{"valid":"true","errors":[],"merged_yaml":"---\n.api_test:\n  rules:\n  - if: $CI_PIPELINE_SOURCE==\"merge_request_event\"\n    changes:\n    - src/api/*\ndeploy:\n  rules:\n  - when: manual\n    allow_failure: true\n  extends:\n  - \".api_test\"\n  script:\n  - echo \"hello world\"\n"}
```

구문 분석하고 다시 포맷할 때 결과 YAML 파일에는 다음이 포함됩니다:

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

## CI/CD 구성 검증 {#validate-cicd-configuration}

지정된 프로젝트에 대해 `.gitlab-ci.yml` 구성을 검증합니다. 이 엔드포인트는 프로젝트 컨텍스트에서 CI/CD 구성을 검증하며, 다음을 포함합니다:

- 프로젝트의 CI/CD 변수를 사용합니다.
- 프로젝트의 파일에서 `include:local` 항목을 검색합니다.

```plaintext
POST /projects/:id/ci/lint
```

| 속성      | 유형    | 필수 | 설명 |
|----------------|---------|----------|-------------|
| `content`      | 문자열  | 예      | CI/CD 구성 콘텐츠입니다. |
| `dry_run`      | 부울 | 아니요       | [파이프라인 생성 시뮬레이션](../ci/yaml/lint.md#simulate-a-pipeline)을 실행하거나 정적 검사만 수행합니다. 기본값: `false`. |
| `include_jobs` | 부울 | 아니요       | 정적 검사 또는 파이프라인 시뮬레이션에서 존재할 작업의 목록을 응답에 포함해야 하는지 여부입니다. 기본값: `false`. |
| `ref`          | 문자열  | 아니요       | `dry_run`이 `true`일 때 CI/CD YAML 구성을 검증하는 데 사용할 브랜치 또는 태그 컨텍스트를 설정합니다. 설정되지 않으면 프로젝트의 기본 브랜치로 기본 설정됩니다. |

요청 예시:

```shell
curl --request POST \
  --header "Content-Type: application/json" \
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

응답 예시:

- 유효한 구성:

  ```json
  {
    "valid": true,
    "merged_yaml": "---\ntest_job:\n  script: echo 1\n",
    "errors": [],
    "warnings": [],
    "includes": []
  }
  ```

- 잘못된 구성:

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

## 기존 CI/CD 구성 검증 {#validate-existing-cicd-configuration}

{{< history >}}

- `sha` 특성은 GitLab 16.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/369212)되었습니다.
- `sha`과 `ref`는 GitLab 16.10에서 `content_ref`과 `dry_run_ref`로 [이름이 변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143098)되었습니다.

{{< /history >}}

지정된 프로젝트에 대해 기존 `.gitlab-ci.yml` 구성을 검증합니다. 이 엔드포인트는 프로젝트 컨텍스트에서 CI/CD 구성을 검증하며, 다음을 포함합니다:

- 프로젝트의 CI/CD 변수를 사용합니다.
- 프로젝트의 파일에서 `include:local` 항목을 검색합니다.

```plaintext
GET /projects/:id/ci/lint
```

| 속성      | 유형    | 필수 | 설명 |
|----------------|---------|----------|-------------|
| `content_ref`  | 문자열  | 아니요       | CI/CD 구성 콘텐츠는 이 커밋 SHA, 브랜치 또는 태그에서 가져옵니다. 설정되지 않으면 프로젝트의 기본 브랜치 헤드의 SHA로 기본 설정됩니다. |
| `dry_run`      | 부울 | 아니요       | 파이프라인 생성 시뮬레이션을 실행하거나 정적 검사만 수행합니다. |
| `dry_run_ref`  | 문자열  | 아니요       | `dry_run`이 `true`인 경우 CI/CD YAML 구성을 검증하는 데 사용할 브랜치 또는 태그 컨텍스트를 설정합니다. 설정되지 않으면 프로젝트의 기본 브랜치로 기본 설정됩니다. |
| `include_jobs` | 부울 | 아니요       | 정적 검사 또는 파이프라인 시뮬레이션에서 존재할 작업의 목록을 응답에 포함해야 하는지 여부입니다. 기본값: `false`. |
| `ref`          | 문자열  | 아니요       | (더 이상 사용되지 않음) `dry_run`이 `true`일 때 CI/CD YAML 구성을 검증하는 데 사용할 브랜치 또는 태그 컨텍스트를 설정합니다. 설정되지 않으면 프로젝트의 기본 브랜치로 기본 설정됩니다. `dry_run_ref` 대신 사용합니다. |
| `sha`          | 문자열  | 아니요       | (더 이상 사용되지 않음) CI/CD 구성 콘텐츠는 이 커밋 SHA, 브랜치 또는 태그에서 가져옵니다. 설정되지 않으면 프로젝트의 기본 브랜치 헤드의 SHA로 기본 설정됩니다. `content_ref` 대신 사용합니다. |

요청 예시:

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/projects/:id/ci/lint"
```

응답 예시:

- `include.yml`을 [포함된 파일](../ci/yaml/_index.md#include)로 하고 `include_jobs`을 `true`로 설정한 유효한 구성:

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

- 잘못된 구성:

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
