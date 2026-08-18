---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page,
  see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 특정 작업에 dotenv 변수 전달
description: dotenv 보고서를 사용하여 파이프라인의 작업 간에 환경 변수를 전달합니다.
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

다른 작업에 환경 변수를 전달하려면 dotenv 파일을 사용합니다. dotenv 파일은 `.env` 확장자를 가진 파일로, 환경 변수 키와 값의 목록을 저장합니다. 예를 들어, `sample.env` 파일에서:

```plaintext
REVIEW_URL=review.example.com/123456
BUILD_VERSION=v1.0.0
```

dotenv 파일을 [dotenv 보고서 아티팩트](../yaml/artifacts_reports.md#artifactsreportsdotenv)로 저장합니다. 이는 동일한 파이프라인의 다른 작업, 다운스트림 파이프라인, 또는 동적 환경 URL 설정을 위해 전달할 수 있습니다.

다음과 같은 방식으로 dotenv 변수를 사용할 수 있습니다:

- 한 작업에서 값을 생성하고 이후 작업에서 사용합니다.
- 스테이지 간에 계산된 값을 전달합니다.
- 배포 출력을 기반으로 동적 환경 URL을 설정합니다.
- 다중 프로젝트 파이프라인 전체에서 변수를 공유합니다.

작업 `script` 섹션 또는 [러너에서 변수 확장](where_variables_can_be_used.md#gitlab-ciyml-file)을 지원하는 키워드와 함께 dotenv 변수를 사용할 수 있습니다. `rules` 섹션에서 dotenv 변수를 사용할 수 없습니다.

Dotenv 변수는 [우선순위](_index.md#cicd-variable-precedence)가 작업 변수 및 `.gitlab-ci.yml`에 정의된 기본 변수보다 높습니다. 다만 프로젝트, 그룹, 인스턴스 또는 파이프라인 변수보다는 낮습니다.

동일한 변수 이름이 `dotenv` 보고서에 여러 번 나타나면 마지막 값이 사용됩니다.

## 이후 작업에 변수 전달 {#pass-variables-to-later-jobs}

기본적으로 dotenv 변수는 이후 스테이지의 모든 작업에서 사용 가능합니다. 작업 간에 변수를 전달하려면:

1. 작업에서 파일(`build.env` 등)을 만들고 `VARIABLE_NAME=value` 형식으로 변수를 작성합니다. 한 줄에 하나의 변수를 작성합니다.
1. 파일을 `dotenv` 보고서 아티팩트로 출력합니다.
1. 이후 작업에서 스크립트의 변수를 사용합니다.

예를 들어, `build-job`은 `build.env`을 `BUILD_VERSION=v1.0.0`으로 만들고, `test-job`는 이를 환경 변수로 자동으로 받습니다:

```yaml
build-job:
  stage: build
  script:
    - echo "BUILD_VERSION=v1.0.0" >> build.env
  artifacts:
    reports:
      dotenv: build.env

test-job:
  stage: test
  script:
    - echo "Testing version $BUILD_VERSION"  # Output: 'Testing version v1.0.0'
```

> [!warning]
> dotenv 파일에 자격 증명, API 키 또는 토큰과 같은 민감한 데이터를 포함하지 마세요. 파이프라인 사용자는 dotenv 파일 내용에 액세스할 수 있습니다. 액세스를 제한하려면 [`artifacts:access`](../yaml/_index.md#artifactsaccess)를 사용합니다.

## dotenv 변수를 수신하는 작업 제어 {#control-which-jobs-receive-dotenv-variables}

dotenv 변수를 수신하는 작업을 제어하려면 [`dependencies`](../yaml/_index.md#dependencies) 또는 [`needs`](../yaml/_index.md#needs) 키워드를 사용합니다.

### 특정 작업에서 상속 {#inherit-from-specific-jobs}

`dependencies`을 사용하여 상속을 특정 작업으로만 제한합니다:

```yaml
build-job1:
  stage: build
  script:
    - echo "BUILD_VERSION=v1.0.0" >> build.env
  artifacts:
    reports:
      dotenv: build.env

build-job2:
  stage: build
  script:
    - echo "This job has no dotenv artifacts"

test-job:
  stage: test
  script:
    - echo "$BUILD_VERSION"  # Output: 'v1.0.0'
  dependencies:
    - build-job1
    # build-job2 is not listed, so its artifacts are not inherited
```

### Dotenv 변수 제외 {#exclude-dotenv-variables}

지정된 작업에서 dotenv 변수를 수신하는 것을 방지하려면 `needs`을 `artifacts: false`와 함께 사용합니다. 이는 dotenv 변수뿐만 아니라 해당 작업의 모든 아티팩트 다운로드를 차단합니다:

```yaml
test-job:
  stage: test
  script:
    - echo "$BUILD_VERSION"  # Output: '' (empty)
  needs:
    - job: build-job1
      artifacts: false
```

이 예의 [`needs`](../yaml/_index.md#needs)는 또한 `build-job1`이 완료되는 즉시 작업이 시작되도록 합니다.

또는 빈 [`dependencies`](../yaml/_index.md) 배열을 사용하여 모든 업스트림 작업의 아티팩트 다운로드를 차단합니다:

```yaml
test-job:
  stage: test
  script:
    - echo "$BUILD_VERSION"  # Output: '' (empty)
  dependencies: []
```

## 다운스트림 파이프라인에 변수 전달 {#pass-variables-to-downstream-pipelines}

dotenv 변수 상속으로 다운스트림 파이프라인에 dotenv 변수를 전달할 수 있습니다. [다중 프로젝트 파이프라인](../pipelines/downstream_pipelines.md#multi-project-pipelines)에서 업스트림 작업에 dotenv 아티팩트를 만들고 작업 다운스트림에서 `needs`을 사용하여 상속합니다:

1. `.env` 파일에 변수를 저장합니다.
1. `.env` 파일을 `dotenv` 보고서 아티팩트로 저장합니다.
1. 다운스트림 파이프라인을 트리거합니다.

```yaml
build_vars:
  stage: build
  script:
    - echo "BUILD_VERSION=hello" >> build.env
  artifacts:
    reports:
      dotenv: build.env

deploy:
  stage: deploy
  trigger: my/downstream_project
```

다운스트림 파이프라인에서 업스트림 작업의 아티팩트를 상속하도록 작업을 설정합니다. `needs` 사용합니다. 작업은 dotenv 변수를 받고 스크립트에서 `BUILD_VERSION`에 액세스할 수 있습니다:

```yaml
test:
  stage: test
  script:
    - echo $BUILD_VERSION
  needs:
    - project: my/upstream_project
      job: build_vars
      ref: master
      artifacts: true
```

## 동적 환경 URL 설정 {#set-a-dynamic-environment-url}

배포 작업이 완료된 후 dotenv 변수를 사용하여 동적 환경 URL을 설정할 수 있습니다. 외부 호스팅 플랫폼이 각 배포에 대해 URL을 동적으로 생성할 때 유용합니다.

자세한 내용은 [동적 환경 URL 설정](../environments/_index.md#set-a-dynamic-environment-url)을 참조하세요.

## 복잡한 값 저장 {#store-complex-values}

Dotenv 파일에는 multiline 값의 제한 및 이스케이핑이 필요한 특수 문자와 같은 특정 형식 제한 사항이 있습니다. 값에 JSON이 포함되어 있거나 여러 줄에 걸쳐 있거나 이스케이핑이 필요한 문자가 포함된 경우 dotenv 변수를 사용하지 마세요. 대신 별도의 파일 아티팩트를 사용합니다. 값 제약의 전체 목록은 [형식 요구 사항](#format-requirements)을 참조하세요.

대신:

```yaml
# Not supported
- echo 'CONFIG={"key": "value"}' >> build.env
```

별도의 아티팩트를 사용합니다:

```yaml
build-job:
  stage: build
  script:
    - echo '{"key": "value"}' > config.json
  artifacts:
    paths:
      - config.json
```

## Dotenv 파일 요구 사항 {#dotenv-file-requirements}

Dotenv 파일은 다음 형식, 크기 및 변수 요구 사항을 충족해야 합니다.

GitLab은 [dotenv gem](https://github.com/bkeepers/dotenv)을 사용하여 dotenv 파일을 처리하지만, [원본 dotenv 규칙](https://github.com/motdotla/dotenv?tab=readme-ov-file#what-rules-does-the-parsing-engine-follow) 이상으로 추가 제한 사항을 적용하고 gem 구현도 함께 적용합니다.

### 형식 요구 사항 {#format-requirements}

- [UTF-8 인코딩](../jobs/job_artifacts_troubleshooting.md#error-message-fatal-invalid-argument-when-uploading-a-dotenv-artifact-on-a-windows-runner)만 지원됩니다.
- 파일에는 빈 줄 또는 주석(줄은 `#`로 시작)을 포함할 수 없습니다.
- 변수 이름에는 ASCII 문자(`A-Za-z`), 숫자(`0-9`), 밑줄(`_`)만 포함될 수 있습니다.
- dotenv 파일은 인용을 지원하지 않습니다. 따옴표는 있는 그대로 보존되며 이스케이핑에 사용할 수 없습니다.
- 값에는 줄 바꿈 또는 이스케이핑이 필요한 다른 특수 문자를 포함할 수 없습니다.
- Multiline 값은 지원되지 않습니다. GitLab은 업로드 시 파일을 거부합니다.
- 선행 및 후행 공백 또는 줄 바꿈 문자(`\n`)는 제거됩니다.

### 크기 및 변수 제한 {#size-and-variable-limits}

| 한도                                                      | 값 |
| ---------------------------------------------------------- | ----- |
| 최대 파일 크기                                          | 5 KB  |
| GitLab Self-Managed의 기본 최대 상속 변수 | 20    |

GitLab.com 티어 제한의 경우 [GitLab.com CI/CD 설정](../../user/gitlab_com/_index.md#cicd)을 참조하세요.

GitLab Self-Managed에서 이러한 제한을 변경하려면 [CI/CD 제한](../../administration/cicd/limits.md#limit-dotenv-file-size)을 참조하세요.
