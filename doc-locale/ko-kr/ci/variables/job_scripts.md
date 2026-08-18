---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CD 변수를 작업 스크립트에서 사용
description: "구성, 사용 및 보안입니다."
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

모든 CI/CD 변수는 작업의 환경에서 환경 변수로 설정됩니다. 작업 스크립트에서 각 환경의 셸에 맞는 표준 형식으로 변수를 사용할 수 있습니다.

환경 변수에 액세스하려면 [러너 실행기의 셸](https://docs.gitlab.com/runner/executors/) 구문을 사용하세요.

## Bash 및 `sh` {#with-bash-and-sh}

Bash, `sh`, 및 유사한 셸에서 환경 변수에 액세스하려면 CI/CD 변수를 `$`로 시작하세요:

```yaml
job_name:
  script:
    - echo "$CI_JOB_ID"
```

## PowerShell {#with-powershell}

Windows PowerShell 환경에서 변수에 액세스하려면(시스템에서 설정된 환경 변수 포함) 변수 이름을 `$env:` 또는 `$`로 시작하세요:

```yaml
job_name:
  script:
    - echo $env:CI_JOB_ID
    - echo $CI_JOB_ID
    - echo $env:PATH
```

## Windows Batch {#with-windows-batch}

Windows Batch에서 CI/CD 변수에 액세스하려면 변수를 `%`로 감싸세요:

```yaml
job_name:
  script:
    - echo %CI_JOB_ID%
```

변수를 `!`로 감싸서 [지연 확장](https://ss64.com/nt/delayedexpansion.html)을 사용할 수도 있습니다. 공백이나 줄 바꿈이 포함된 변수의 경우 지연 확장이 필요할 수 있습니다:

```yaml
job_name:
  script:
    - echo !ERROR_MESSAGE!
```

## 서비스 컨테이너에서 {#in-service-containers}

[서비스 컨테이너](../docker/using_docker_images.md)는 CI/CD 변수를 사용할 수 있지만 기본적으로 [`.gitlab-ci.yml` 파일에 저장된 변수](_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file)에만 액세스할 수 있습니다. [GitLab UI에서 추가된](_index.md#define-a-cicd-variable-in-the-ui) 변수는 서비스 컨테이너에서 사용할 수 없습니다. 서비스 컨테이너는 기본적으로 신뢰할 수 없기 때문입니다.

UI에서 정의된 변수를 서비스 컨테이너에서 사용 가능하게 하려면 `.gitlab-ci.yml`의 다른 변수에 재할당할 수 있습니다:

```yaml
variables:
  SA_PASSWORD_YAML_FILE: $SA_PASSWORD_UI
```

재할당된 변수는 원래 변수와 같은 이름을 가질 수 없습니다. 그렇지 않으면 확장되지 않습니다.

## 구문 분석 오류 방지 {#prevent-parsing-errors}

스크립트 명령 및 변수 값을 인용하여 YAML 및 셸 구문 분석 오류를 방지하세요:

- 전체 명령을 인용할 때 콜론(`:`)을 포함하여 YAML이 키-값 쌍으로 해석하지 않도록 합니다:

  ```yaml
  job_name:
    script:
      - 'echo "Status: Complete"'  # Single quotes prevent YAML colon parsing
  ```

- 변수 값에 공백이나 특수 문자가 포함될 수 있을 때 변수를 인용하세요:

  ```yaml
  job_name:
    script:
      - echo "$FILE_PATH"          # Quote if FILE_PATH might have spaces
  ```

- 변수를 별도의 셸 인수로 확장하려는 경우 인용을 피하세요:

  ```yaml
  job_name:
    variables:
      COMPILE_FLAGS: "-Wall -Werror -O2"
    script:
      - gcc $COMPILE_FLAGS main.c  # Expands to: gcc -Wall -Werror -O2 main.c
  ```

## `script` 섹션에서 `artifacts` 또는 `cache`로 환경 변수 전달 {#pass-an-environment-variable-from-the-script-section-to-artifacts-or-cache}

{{< history >}}

- GitLab 16.4에서 [도입됨](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29391).

{{< /history >}}

`$GITLAB_ENV`을 사용하여 `script` 섹션에서 정의된 환경 변수를 `artifacts` 또는 `cache` 키워드에서 사용하세요. 예를 들어:

```yaml
build-job:
  stage: build
  script:
    - echo "ARCH=$(arch)" >> $GITLAB_ENV
    - touch some-file-$(arch)
  artifacts:
    paths:
      - some-file-$ARCH
```

## 하나의 변수에 여러 값 저장 {#store-multiple-values-in-one-variable}

값 배열인 CI/CD 변수를 만들 수 없지만 유사한 동작을 위해 셸 스크립팅 기법을 사용할 수 있습니다.

예를 들어 공백으로 구분된 여러 값을 변수에 저장한 다음 스크립트를 사용하여 값을 반복할 수 있습니다:

```yaml
job1:
  variables:
    FOLDERS: src test docs
  script:
    - |
      for FOLDER in $FOLDERS
        do
          echo "The path is root/${FOLDER}"
        done
```

## 다른 변수에서 CI/CD 변수 사용 {#use-cicd-variables-in-other-variables}

다른 변수 내에서 변수를 사용할 수 있습니다:

```yaml
job:
  variables:
    FLAGS: '-al'
    LS_CMD: 'ls "$FLAGS"'
  script:
    - 'eval "$LS_CMD"'  # Executes 'ls -al'
```

### 문자열의 일부로 {#as-part-of-a-string}

변수를 문자열의 일부로 사용할 수 있습니다. 변수를 중괄호(`{}`)로 감싸서 변수 이름을 주변 텍스트와 구별하는 데 도움이 될 수 있습니다. 중괄호가 없으면 인접한 텍스트가 변수 이름의 일부로 해석됩니다. 예를 들어:

```yaml
job:
  variables:
    FLAGS: '-al'
    DIR: 'path/to/directory'
    LS_CMD: 'ls "$FLAGS"'
    CD_CMD: 'cd "${DIR}_files"'
  script:
    - 'eval "$LS_CMD"'  # Executes 'ls -al'
    - 'eval "$CD_CMD"'  # Executes 'cd path/to/directory_files'
```

### CI/CD 변수에서 `$` 문자 사용 {#use-the--character-in-cicd-variables}

`$` 문자가 다른 변수의 시작으로 해석되지 않도록 하려면 `$$`을 대신 사용하세요:

```yaml
job:
  variables:
    FLAGS: '-al'
    LS_CMD: 'ls "$FLAGS" $$TMP_DIR'
  script:
    - 'eval "$LS_CMD"'  # Executes 'ls -al $TMP_DIR'
```

이는 [다운스트림 파이프라인으로 CI/CD 변수 전달](../pipelines/downstream_pipelines_troubleshooting.md#variable-with--character-does-not-get-passed-to-a-downstream-pipeline-properly)할 때 작동하지 않습니다.

## 관련 항목 {#related-topics}

- [dotenv를 사용하여 나중 작업에 환경 변수 전달](dotenv_variables.md#pass-variables-to-later-jobs)
