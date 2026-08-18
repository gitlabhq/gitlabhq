---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 스크립트 및 작업 로그 문제 해결
---

## `Syntax is incorrect` 사용 중 `:` 포함된 스크립트 {#syntax-is-incorrect-in-scripts-that-use-}

스크립트에 콜론(`:`)을 사용하면 GitLab이 다음을 출력할 수 있습니다:

- `Syntax is incorrect`
- `script config should be a string or a nested array of strings up to 10 levels deep`

예를 들어 cURL 명령의 일부로 `"PRIVATE-TOKEN: ${PRIVATE_TOKEN}"`을(를) 사용하는 경우:

```yaml
pages-job:
  stage: deploy
  script:
    - curl --header 'PRIVATE-TOKEN: ${PRIVATE_TOKEN}' "https://gitlab.example.com/api/v4/projects"
  environment: production
```

YAML 파서는 `:`이 YAML 키워드를 정의한다고 생각하고 `Syntax is incorrect` 오류를 출력합니다.

콜론이 포함된 명령을 사용하려면 전체 명령을 작은따옴표로 감싸야 합니다. 기존 작은따옴표(`'`)를 큰따옴표(`"`)로 변경해야 할 수도 있습니다:

```yaml
pages-job:
  stage: deploy
  script:
    - 'curl --header "PRIVATE-TOKEN: ${PRIVATE_TOKEN}" "https://gitlab.example.com/api/v4/projects"'
  environment: production
```

## 작업이 스크립트에서 `&&`을(를) 사용할 때 실패하지 않음 {#job-does-not-fail-when-using--in-a-script}

`&&`을(를) 사용하여 두 명령을 단일 스크립트 라인에서 결합하면 명령 중 하나가 실패했더라도 작업이 성공으로 반환될 수 있습니다. 예를 들어:

```yaml
job-does-not-fail:
  script:
    - invalid-command xyz && invalid-command abc
    - echo $?
    - echo "The job should have failed already, but this is executed unexpectedly."
```

`&&` 연산자는 두 명령이 실패했음에도 불구하고 종료 코드 `0`을(를) 반환하며, 작업이 계속 실행됩니다. 명령이 실패할 때 스크립트를 강제로 종료하려면 전체 라인을 괄호로 감싸십시오:

```yaml
job-fails:
  script:
    - (invalid-command xyz && invalid-command abc)
    - echo "The job failed already, and this is not executed."
```

## 접힌 YAML 다중 라인 블록 스칼라로 보존되지 않는 다중 라인 명령 {#multiline-commands-not-preserved-by-folded-yaml-multiline-block-scalar}

`- >` 접힌 YAML 다중 라인 블록 스칼라를 사용하여 긴 명령을 분할하면, 추가 들여쓰기로 인해 라인이 개별 명령으로 처리됩니다.

예를 들어:

```yaml
script:
  - >
    RESULT=$(curl --silent
      --header
        "Authorization: Bearer $CI_JOB_TOKEN"
      "${CI_API_V4_URL}/job"
    )
```

들여쓰기로 인해 줄 바꿈이 보존되므로 이 작업이 실패합니다:

```plaintext
$ RESULT=$(curl --silent # collapsed multi-line command
curl: no URL specified!
curl: try 'curl --help' or 'curl --manual' for more information
/bin/bash: line 149: --header: command not found
/bin/bash: line 150: https://gitlab.example.com/api/v4/job: No such file or directory
```

다음 중 하나로 해결하십시오:

- 추가 들여쓰기 제거:

  ```yaml
  script:
    - >
      RESULT=$(curl --silent
      --header
      "Authorization: Bearer $CI_JOB_TOKEN"
      "${CI_API_V4_URL}/job"
      )
  ```

- 스크립트를 수정하여 추가 줄 바꿈을 처리합니다. 예를 들어 셸 라인 연속을 사용합니다:

  ```yaml
  script:
    - >
      RESULT=$(curl --silent \
        --header \
          "Authorization: Bearer $CI_JOB_TOKEN" \
        "${CI_API_V4_URL}/job")
  ```

## 작업 로그 출력이 예상대로 포맷되지 않거나 예상치 못한 문자 포함 {#job-log-output-is-not-formatted-as-expected-or-contains-unexpected-characters}

작업 로그의 포맷이 색상 지정 또는 포맷 지정을 위해 `TERM` 환경 변수에 의존하는 도구와 함께 올바르지 않게 표시되는 경우가 있습니다. 예를 들어 `mypy` 명령의 경우:

![예제 출력](img/incorrect_log_rendering_v16_5.png)

러너는 컨테이너의 셸을 비대화형 모드로 실행하므로 셸의 `TERM` 환경 변수가 `dumb`로 설정됩니다. 이러한 도구의 포맷을 수정하려면 다음을 수행할 수 있습니다:

- 명령을 실행하기 전에 셸의 환경에서 `TERM=ansi`을(를) 설정하는 추가 스크립트 라인을 추가합니다.
- `TERM` [CI/CD 변수](../variables/_index.md)를 `ansi` 값으로 추가합니다.

## `after_script` 섹션 실행이 조기에 중지되고 `$CI_JOB_STATUS` 상태가 잘못됨 {#after_script-section-execution-stops-early-and-incorrect-ci_job_status-values}

GitLab Runner 16.9.0 ~ 16.11.0에서:

- `after_script` 섹션 실행이 때때로 너무 일찍 중지됩니다.
- `$CI_JOB_STATUS` 사전 정의된 변수의 상태는 [`failed`로 잘못 설정되는 동안 작업이 취소 중입니다](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37485).
