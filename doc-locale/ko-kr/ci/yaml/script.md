---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab CI/CD ‘스크립트’ 섹션을 작성하고 특수 구문 또는 구성으로 작업 로그를 개선하는 방법을 알아봅니다.
title: 스크립트 및 작업 로그
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[`script`](_index.md#script) 섹션에서 다음을 수행할 수 있습니다:

- [긴 명령 분할](#split-long-commands)을 여러 줄 명령으로 나눕니다.
- [색상 코드 사용](#add-color-codes-to-script-output)으로 작업 로그를 더 쉽게 검토합니다.
- [사용자 정의 축소 가능한 섹션 만들기](../jobs/job_logs.md#create-custom-collapsible-sections)로 작업 로그 출력을 단순화합니다.

## `script`로 특수 문자 사용 {#use-special-characters-with-script}

경우에 따라 `script` 명령을 단일 또는 이중 따옴표로 묶어야 합니다. 예를 들어 콜론(`:`)을 포함하는 명령은 단일 따옴표(`'`)로 묶어야 합니다. YAML 파서는 텍스트를 "key: value" 쌍이 아닌 문자열로 해석해야 합니다.

예를 들어 이 스크립트는 콜론을 사용합니다:

```yaml
job:
  script:
    - curl --request POST --header 'Content-Type: application/json' "https://gitlab.example.com/api/v4/projects"
```

유효한 YAML로 간주되려면 전체 명령을 단일 따옴표로 묶어야 합니다. 명령이 이미 단일 따옴표를 사용하는 경우 가능하면 이중 따옴표(`"`)로 변경해야 합니다:

```yaml
job:
  script:
    - 'curl --request POST --header "Content-Type: application/json" "https://gitlab.example.com/api/v4/projects"'
```

[CI Lint](lint.md) 도구로 구문이 유효한지 확인할 수 있습니다.

이러한 문자도 사용할 때 주의하세요:

- `{`, `}`, `[`, `]`, `,`, `&`, `*`, `#`, `?`, `|`, `-`, `<`, `>`, `=`, `!`, `%`, `@`, `` ` ``.

## 0이 아닌 종료 코드 무시 {#ignore-non-zero-exit-codes}

스크립트 명령이 0이 아닌 종료 코드를 반환하면 작업이 실패하고 추가 명령은 실행되지 않습니다.

이 동작을 방지하려면 종료 코드를 변수에 저장합니다:

```yaml
job:
  script:
    - exit_code=0
    - false || exit_code=$?
    - if [ $exit_code -ne 0 ]; then echo "Previous command failed"; fi;
```

## 모든 작업에 대해 기본 `before_script` 또는 `after_script` 설정 {#set-a-default-before_script-or-after_script-for-all-jobs}

[`before_script`](_index.md#before_script)과 [`after_script`](_index.md#after_script)를 [`default`](_index.md#default)로 사용할 수 있습니다:

- `before_script`을 `default`와 함께 사용하여 모든 작업의 `script` 명령 이전에 실행되어야 하는 기본 명령 배열을 정의합니다.
- `after_script`을 기본값과 함께 사용하여 모든 작업이 완료되거나 취소된 후에 실행되어야 하는 기본 명령 배열을 정의합니다.

작업에서 다른 기본값을 정의하여 기본값을 덮어쓸 수 있습니다. 기본값을 무시하려면 `before_script: []` 또는 `after_script: []`를 사용합니다:

```yaml
default:
  before_script:
    - echo "Execute this `before_script` in all jobs by default."
  after_script:
    - echo "Execute this `after_script` in all jobs by default."

job1:
  script:
    - echo "These script commands execute after the default `before_script`,"
    - echo "and before the default `after_script`."

job2:
  before_script:
    - echo "Execute this script instead of the default `before_script`."
  script:
    - echo "This script executes after the job's `before_script`,"
    - echo "but the job does not use the default `after_script`."
  after_script: []
```

## 작업이 취소되면 `after_script` 명령 건너뛰기 {#skip-after_script-commands-if-a-job-is-canceled}

{{< history >}}

- GitLab 17.0에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/10158)되었으며 [플래그](../../administration/feature_flags/_index.md) `ci_canceling_status`로 이름이 지정되었습니다. 기본적으로 활성화됩니다. GitLab 러너 버전 16.11.1이 필요합니다.
- GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/460285)합니다. 기능 플래그 `ci_canceling_status`이 제거되었습니다.

{{< /history >}}

[`after_script`](_index.md) 명령은 `before_script` 또는 `script` 섹션이 실행 중인 동안 작업이 취소된 경우 실행됩니다.

작업의 UI 상태는 `canceling`이며 `after_script`이 실행 중이고 `after_script` 명령이 완료되면 `canceled`로 변경됩니다. `$CI_JOB_STATUS` 사전 정의된 변수는 `after_script` 명령이 실행 중인 동안 `canceled` 값을 갖습니다.

`after_script` 명령이 작업 취소 후 실행되는 것을 방지하려면 `after_script` 섹션을 다음과 같이 구성합니다:

1. `after_script` 섹션의 시작 부분에서 `$CI_JOB_STATUS` 사전 정의된 변수를 확인합니다.
1. 값이 `canceled`이면 실행을 조기에 종료합니다.

예를 들어:

```yaml
job1:
  script:
    - my-script.sh
  after_script:
    - if [ "$CI_JOB_STATUS" == "canceled" ]; then exit 0; fi
    - my-after-script.sh
```

## 긴 명령 분할 {#split-long-commands}

`|`(리터럴) 및 `>`(폴드) [YAML 여러 줄 블록 스칼라 표시기](https://yaml-multiline.info/)로 가독성을 개선하기 위해 긴 명령을 여러 줄 명령으로 분할할 수 있습니다.

> [!warning]
> 여러 명령을 하나의 명령 문자열로 결합하면 마지막 명령의 실패 또는 성공만 보고됩니다. [이전 명령의 실패는 버그로 인해 무시됩니다](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/25394). 이를 해결하려면 각 명령을 별도의 `script` 항목으로 실행하거나 각 명령 문자열에 `exit 1` 명령을 추가합니다.

`|`(리터럴) YAML 여러 줄 블록 스칼라 표시기를 사용하여 작업 설명의 `script` 섹션에서 여러 줄에 걸쳐 명령을 작성할 수 있습니다. 각 줄은 별도의 명령으로 취급됩니다. 첫 번째 명령만 작업 로그에 반복되지만 추가 명령은 여전히 실행됩니다:

```yaml
job:
  script:
    - |
      echo "First command line."
      echo "Second command line."
      echo "Third command line."
```

이전 예제는 작업 로그에 다음과 같이 렌더링됩니다:

```shell
$ echo First command line # collapsed multiline command
First command line
Second command line.
Third command line.
```

`>`(폴드) YAML 여러 줄 블록 스칼라 표시기는 섹션 간의 빈 줄을 새 명령의 시작으로 처리합니다:

```yaml
job:
  script:
    - >
      echo "First command line
      is split over two lines."

      echo "Second command line."
```

이는 `>` 또는 `|` 블록 스칼라 표시기 없는 여러 줄 명령과 유사하게 작동합니다:

```yaml
job:
  script:
    - echo "First command line
      is split over two lines."

      echo "Second command line."
```

이전 두 예제는 작업 로그에 다음과 같이 렌더링됩니다:

```shell
$ echo First command line is split over two lines. # collapsed multiline command
First command line is split over two lines.
Second command line.
```

`>` 또는 `|` 블록 스칼라 표시기를 생략하면 GitLab은 비어있지 않은 줄을 연결하여 명령을 형성합니다. 줄을 연결할 때 실행할 수 있는지 확인합니다.

<!-- vale gitlab_base.MeaningfulLinkWords = NO -->

[셀 여기 문서](https://en.wikipedia.org/wiki/Here_document)는 `|` 및 `>` 연산자와도 작동합니다. 다음 예제는 소문자를 대문자로 변환합니다:

<!-- vale gitlab_base.MeaningfulLinkWords = YES -->

```yaml
job:
  script:
    - |
      tr a-z A-Z << END_TEXT
        one two three
        four five six
      END_TEXT
```

결과:

```shell
$ tr a-z A-Z << END_TEXT # collapsed multiline command
  ONE TWO THREE
  FOUR FIVE SIX
```

## 스크립트 출력에 색상 코드 추가 {#add-color-codes-to-script-output}

스크립트 출력은 [ANSI 이스케이프 코드](https://en.wikipedia.org/wiki/ANSI_escape_code#Colors)를 사용하거나 ANSI 이스케이프 코드를 출력하는 명령이나 프로그램을 실행하여 색칠할 수 있습니다.

예를 들어 [색상 코드가 있는 Bash](https://misc.flogisoft.com/bash/tip_colors_and_formatting)를 사용합니다:

```yaml
job:
  script:
    - echo -e "\e[31mThis text is red,\e[0m but this text isn't\e[31m however this text is red again."
```

셀 환경 변수 또는 [CI/CD 변수](../variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file)에서 색상 코드를 정의할 수 있으므로 명령을 더 쉽게 읽고 재사용할 수 있습니다.

예를 들어 이전 예제와 `before_script`에 정의된 환경 변수를 사용합니다:

```yaml
job:
  before_script:
    - TXT_RED="\e[31m" && TXT_CLEAR="\e[0m"
  script:
    - echo -e "${TXT_RED}This text is red,${TXT_CLEAR} but this part isn't${TXT_RED} however this part is again."
    - echo "This text is not colored"
```

또는 [PowerShell 색상 코드](https://superuser.com/a/1259916) 사용:

```yaml
job:
  before_script:
    - $esc="$([char]27)"; $TXT_RED="$esc[31m"; $TXT_CLEAR="$esc[0m"
  script:
    - Write-Host $TXT_RED"This text is red,"$TXT_CLEAR" but this text isn't"$TXT_RED" however this text is red again."
    - Write-Host "This text is not colored"
```
