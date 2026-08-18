---
stage: Verify
group: CI Functions Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Functions
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  실험적 기능

{{< /details >}}

GitLab Functions는 GitLab CI/CD 작업에서 `script`을(를) 대체하는 재사용 가능한 CI/CD 작업 로직 단위를 제공합니다.

> [!note]
> GitLab Functions는 개발 중인 실험 기능이며 주요 변경 사항의 대상이 될 수 있습니다. 자세한 내용은 [변경 로그](https://gitlab.com/gitlab-org/step-runner/-/blob/main/CHANGELOG.md)를 검토하세요.

## 함수를 사용하는 이유 {#why-functions}

작업이 증가함에 따라 `script` 블록을 유지하기가 어려워집니다. 논리가 여러 작업에서 중복되고, 스크립트가 런타임에 외부 소스에서 가져와지며, 작은 변경 사항을 여러 곳에서 업데이트해야 합니다. GitLab Functions는 이러한 문제를 해결하도록 설계되었습니다.

함수의 장점은 다음과 같습니다:

- 함수는 자체 포함되고 버전이 관리됩니다. 함수는 논리, 지원 스크립트 또는 이진 파일, 그리고 입력 및 출력을 설명하는 사양을 패키징하는 OCI 이미지입니다. 단계가 실행되면 GitLab은 함수를 자동으로 가져옵니다. 단계 시작에서 스크립트를 가져오거나 외부 종속성을 수동으로 관리할 필요가 없습니다. 특정 버전 태그에서 함수를 참조하면 매번 정확히 그 버전을 얻을 수 있습니다.

- 함수는 작업 및 프로젝트 전체에서 재사용할 수 있습니다. 함수를 OCI 레지스트리에 게시한 후 모든 작업이 단일 `func` 참조로 사용할 수 있으며, 각 리포지토리에서 스크립트 파일을 복사하고 유지할 필요가 없습니다.

- 함수는 데이터 흐름을 명시적으로 만듭니다. `script` 블록에서 값은 셸 변수를 통해 명령 간에 전달되며, 임의의 순서로 설정, 덮어쓰거나 읽을 수 있습니다. `run` 목록에서 각 단계는 자신의 입력 및 출력을 선언하고, 단계는 이미 실행된 단계의 출력만 액세스할 수 있습니다.

- 함수는 독립적으로 테스트할 수 있습니다. 함수가 입력 및 출력을 정의하므로 전체 파이프라인을(를) 실행하지 않고 격리된 상태에서 실행하고 테스트할 수 있습니다.

- 함수 실행은 플랫폼 전체에서 안정적입니다. 전용 에이전트가 네트워크를 통해 전송되는 스크립트를 해석하지 않고 빌드 호스트에서 함수 실행을 관리합니다. 이는 함수에 적절한 프로세스 제어, 크로스 플랫폼 일관성, 재개 가능한 작업의 기초를 제공합니다. 이러한 기능은 셸 스크립트만으로는 달성하기 어렵거나 불가능합니다.

기존 셸 스크립트를 재사용하려면 `script` 단계를 사용하여 증분 마이그레이션 중에 `run` 목록에서 직접 실행합니다. 모든 것을 한 번에 변환하지 않고 함수를 사용할 수 있습니다.

## 함수 이해하기 {#understand-functions}

기존 CI/CD 작업에서 `script` 키워드에는 셸 명령 목록이 포함됩니다. 작업이 모든 단계를 소유하고 논리는 YAML에 직접 있으며, 이는 결과를 달성하는 방법을 정확히 설명합니다. 파이프라인이 증가함에 따라 이 접근 방식은 프로젝트 전체에서 재사용, 테스트 또는 공유하기가 어려워집니다.

GitLab Functions를 사용하면 `run` 키워드를 사용하여 단계 목록을 선언합니다. 각 단계는 구현을 포함하는 함수를 참조하고, 작업은 방법이 아닌 무엇이 일어나야 하는지를 설명합니다. 논리는 함수에 존재하며 YAML에는 없습니다.

다음은 JavaScript 프로젝트에 대한 예제 기존 `.gitlab-ci.yml`입니다:

```yaml
build_and_release:
  script:
    - npm run lint
    - npm test
    - npm run bundle
    - BUNDLE_PATH=$(find dist -name '*.js' | head -1)
    - npm run minify -- --input $BUNDLE_PATH
    - npm run deploy -- --artifact $MINIFIED_PATH --env production
```

GitLab Functions로 작성한 동일한 파이프라인:

```yaml
build_and_release:
  run:
    - name: validate
      func: registry.gitlab.com/js/validate:1.0.0
    - name: release
      func: registry.gitlab.com/js/release:1.0.0
      inputs:
        environment: production
```

각 작업은 단계를 통해 무엇이 일어나야 하는지를 선언합니다. 함수 자체에는 구현이 포함됩니다.

## GitLab Functions 용어 {#gitlab-functions-glossary}

이 용어집은 GitLab Functions와 관련된 용어의 정의를 제공합니다.

함수: 재사용 가능하고 자체 포함된 CI/CD 논리 패키지입니다. 함수에는 플랫폼별 컴파일된 코드, 입력 및 출력을 정의하는 사양, 그리고 함수의 기능을 설명하는 정의가 포함됩니다. 함수는 명령을 실행하거나 다른 함수를 구성할 수 있습니다.

단계: `run` 목록에서 함수의 단일 호출입니다. 단계에는 이름, 함수 참조, 제공된 입력 및 해당 호출에 대해 설정된 환경 변수가 포함됩니다.

입력: 단계로 호출할 때 함수에 전달하는 명명된 값입니다. 입력은 함수 사양에서 유형 및 선택적 기본값으로 선언됩니다.

출력: 함수가 실행 후 반환하는 명명된 값입니다. 출력은 함수 사양에서 선언되고 실행 중에 출력 파일에 작성됩니다.

환경 변수: 런타임에 함수에서 사용할 수 있는 변수입니다. 환경 변수는 운영 체제 프로세스 환경, 러너, 함수 정의, 단계 호출 또는 이를 내보낸 이전에 실행한 함수에서 올 수 있습니다.

## CI/CD Steps에서 이름 변경 {#rename-from-cicd-steps}

GitLab Functions는 이전에 CI/CD Steps라고 불렸습니다. 이 기능과 구문이 이름 변경되었습니다.

| 이전                                       | 새로운                           |
|:------------------------------------------|:------------------------------|
| CI/CD Steps                               | GitLab Functions              |
| `step:` (더 이상 사용되지 않음)                      | `func:`                       |
| `step.yml` (더 이상 사용되지 않음)                   | `func.yml`                    |
| `${{ step_dir }}` (더 이상 사용되지 않음)            | `${{ func_dir }}`             |
| `${{ job.<variable_name> }}` (더 이상 사용되지 않음) | `${{ vars.<variable_name> }}` |

## 구성 요소 및 함수 {#components-and-functions}

구성 요소와 함수는 파이프라인의 다양한 수준에서 작동하며 다양한 문제를 해결합니다.

[CI/CD 구성 요소](../components/_index.md)는 파이프라인 수준에서 재사용할 수 있습니다. GitLab은 작업이 실행되기 전에 구성 요소를 포함하고 작업, 스테이지 및 구성을 파이프라인에 제공합니다. 구성 요소는 파이프라인에 어떤 작업이 있는지를 설명합니다.

GitLab Functions는 작업 수준에서 재사용할 수 있습니다. 이들은 작업 내에서 실행되고 `script`을(를) 대체합니다.

구성 요소와 함수는 다양한 수준에서 작동하며 서로 잘 보완됩니다. 구성 요소는 작업을 정의하고 함수를 내부적으로 사용하여 이를 구현할 수 있습니다. 구성 요소를 포함하면 작동 방식을 알 필요 없이 완전히 구성된 작업을 얻습니다. 구성 요소 작성자는 함수를 사용하여 작업의 복잡성을 처리합니다.

### 표현식 구문 {#expression-syntax}

구성 요소와 함수는 다양한 시간에 평가되기 때문에 다양한 표현식 구문을 사용합니다:

- `$[[ ]]` 표현식은 파이프라인 생성 중에 평가되며, 작업이 실행되기 전입니다. [CI/CD 입력](../inputs/_index.md) 및 구성 요소 입력에 이 구문을 사용합니다.
- `${{ }}` 표현식은 작업 실행 중에 평가되며, 각 단계가 실행되기 직전입니다. 함수 입력, 환경 변수 및 런타임 상태에 따라 달라지는 값에 이 구문을 사용합니다.

두 구문 모두 CI/CD 구성 요소 YAML 구성 파일에 나타날 수 있습니다:

```yaml
spec:
  inputs:
    go_version:
      default: "1.22"
---

my-format-job:
  run:
    - name: install_go
      func: ./languages/go/install
      inputs:
        version: $[[ inputs.go_version ]]                      # resolved at pipeline creation
    - name: format
      func: ./languages/go/go-fmt
      inputs:
        go_binary: ${{ steps.install_go.outputs.go_binary }}   # resolved during job execution
```

## 함수 실행 모델 {#function-execution-model}

함수는 입력을 수용하고, 출력을 반환하고, 환경 변수를 내보낼 수 있는 자체 포함된 패키지입니다. 함수는 CI 작업의 환경에서 실행되며, 인스턴스가 호스트 머신인지 컨테이너인지에 상관없습니다. 함수를 파일 시스템, OCI 레지스트리 또는 Git 리포지토리에 로컬로 호스팅할 수 있습니다.

`run` 목록의 각 단계는 순서대로 실행됩니다. 단계는 공유 셸 상태가 아닌 입력, 출력 및 내보낸 환경 변수를 통해 서로 통신합니다.

한 단계의 출력은 `${{ steps.<step-name>.outputs.<output-name> }}` 표현식을 통해 후속 단계에서 사용할 수 있습니다. 한 단계에서 내보낸 환경 변수는 모든 후속 단계에서 사용할 수 있습니다. 출력과 환경 변수는 모두 단계가 완료된 후에만 사용할 수 있게 됩니다.

러너가 `run` 목록이 있는 작업을 선택하면, 단계 러너를 호출하여 실행을 관리합니다. 목록의 각 단계에 대해 단계 러너는:

1. 함수 참조를 해결하고 파일 시스템, OCI 리포지토리 또는 Git 리포지토리에서 함수 패키지를 가져옵니다.
1. 단계의 입력 및 환경 변수의 표현식을 평가합니다.
1. 함수를 실행하고 해결된 입력 및 환경을 전달합니다.
1. 함수가 출력 파일에 작성한 출력을 읽고 후속 단계에서 사용할 수 있도록 합니다.
1. 함수가 내보낸 환경 변수를 읽고 전역 환경에 추가합니다.
1. 다음 단계로 이동하거나, 단계가 실패하면 중지합니다.

## 함수 요구 사항 {#function-requirements}

함수를 사용하려면 사용하는 러너 실행기에 단계 러너를 설치해야 할 수도 있습니다. 자세한 내용은 [단계 러너 수동 설치](https://docs.gitlab.com/runner/install/step-runner)를 참조하세요.

## 함수 사용 {#use-functions}

`run` 키워드를 사용하여 GitLab CI/CD 작업을 함수를 사용하도록 구성합니다. 함수를 실행할 때 작업에서 `before_script`, `after_script` 또는 `script`을(를) 사용할 수 없습니다.

### 단계를 통해 함수 실행 {#run-a-function-with-a-step}

`run` 키워드는 실행할 단계 목록을 수용합니다. 단계는 목록에 정의된 순서대로 한 번에 하나씩 실행됩니다. 각 단계에는 `name`, `func` 또는 `script`, 그리고 선택적으로 `inputs` 및 `env`이 있습니다.

이름은 영숫자 문자와 밑줄만 포함해야 하며 숫자로 시작할 수 없습니다.

#### 함수 호출 {#invoke-a-function}

단계는 `func` 키워드를 사용하여 [함수 참조](#function-reference)를 제공하여 함수를 호출할 수 있습니다. `inputs` 키워드를 사용하여 함수에 입력을 전달하고 `env` 키워드를 사용하여 환경 값을 재정의합니다. [표현식](#expressions)을(를) `func` 값과 `inputs` 및 `env`의 키와 값에 사용합니다.

함수는 호출된 함수가 작업 디렉토리를 재정의하지 않는 한 `CI_PROJECT_DIR` 디렉토리에서 실행됩니다.

예를 들어, 아래의 echo 함수를 실행하면 작업 로그에 `Hi Sally!` 메시지를 인쇄합니다.

```yaml
my-job:
  variables:
    FRIEND: "Sally"
  run:
    - name: say_hi
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo:1
      inputs:
        message: "Hi ${{ vars.FRIEND }}!"
```

#### 스크립트 실행 {#run-a-script}

단계는 `script` 키워드를 사용하여 스크립트를 호출할 수 있습니다. `env`를 사용하여 스크립트에 전달되는 환경 변수는 셸에 설정됩니다. 스크립트 단계는 `bash` 셸을 사용하며, bash를 찾을 수 없으면 `sh`로 대체됩니다. [표현식](#expressions)은(는) `script` 값과 `env`의 키 및 값에 사용할 수 있습니다. 스크립트 단계는 `CI_PROJECT_DIR` 디렉토리에서 실행됩니다.

함수와 함께 간단한 사용자 지정 항목이 필요할 때 스크립트 단계를 사용합니다. 내부적으로 함수는 스크립트를 함수 호출로 변환하고 스크립트를 입력으로 전달합니다.

예를 들어, 다음 스크립트 단계는 작업 로그에 `Hi Sally!` 메시지를 인쇄합니다:

```yaml
my-job:
  variables:
    FRIEND: "Sally"
  run:
    - name: say_hi
      script: echo 'Hi ${{ vars.FRIEND }}!'
```

### 함수 참조 {#function-reference}

함수는 파일 시스템 또는 OCI 리포지토리에서 로드됩니다. Git 리포지토리에서 로드하는 것은 지원되지만 더 이상 사용되지 않습니다.

#### OCI 리포지토리에서 로드 {#load-from-an-oci-repository}

{{< history >}}

- GitLab 러너 18.9에서 [도입](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/6351)되었습니다.

{{< /history >}}

OCI 리포지토리에서 함수를 로드하려면 레지스트리, 리포지토리 및 버전(태그)을 제공합니다. 이 방법은 함수를 배포하고 소비하는 권장 방법입니다.

함수 OCI 이미지는 여러 플랫폼을 지원합니다. 단계 러너는 실행 중인 플랫폼과 일치하는 이미지를 다운로드합니다. 일치 항목이 없으면 단계가 실패합니다.

```yaml
# prints 'Hi from GitLab Functions'
my-job:
  run:
    - name: echo
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo:1
      inputs:
        message: "Hi from GitLab Functions"
```

함수가 루트에 없으면 이미지의 하위 디렉토리와 파일 이름을 지정할 수도 있습니다:

```yaml
# prints 'snoitcnuF baLtiG morf iH'
my-job:
  run:
    - name: echo
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo:1 reverse/func.yml
      inputs:
        message: "Hi from GitLab Functions"
```

비공개 OCI 리포지토리에 인증하려면 `DOCKER_AUTH_CONFIG` 환경 변수를 Docker 구성 파일 형식의 값으로 설정합니다. 함수로 인증의 작동 예를 보려면 [Docker Auth](https://gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/docker-auth) 함수를 참조하세요.

#### 파일 시스템에서 로드 {#load-from-the-file-system}

상대 경로를 사용하여 파일 시스템에서 함수를 로드하려면 함수 참조를 `.`로 시작합니다. 경로는 호출 함수의 디렉토리에 상대적입니다. 작업에서 직접 함수를 호출하면 경로는 `CI_PROJECT_DIR`에 상대적입니다.

절대 경로를 사용하여 파일 시스템에서 함수를 로드하려면 함수 참조를 `/`로 시작합니다.

단계가 실행되면 경로가 함수 디렉토리가 됩니다. 함수 정의 YAML이 이 디렉토리에 있어야 합니다. 선택적으로 함수 정의 YAML 파일 이름이 표준이 아닌 경우 이를 제공합니다.

경로 구분 기호는 운영 체제에 관계없이 슬래시 `/`을(를) 사용해야 합니다.

예를 들어:

- 상대 디렉토리에서 로드:

  ```yaml
  - name: my_step
    func: ./path/to/my-function
  ```

- 절대 디렉토리에서 로드:

  ```yaml
  - name: my_step
    func: /opt/gitlab-functions/my-function
  ```

- 사용자 지정 함수 정의 파일을 사용하여 로드:

  ```yaml
  - name: my_step
    func: ./funcs/release/dry-run.yml
  ```

#### Git 브랜치에서 로드 (더 이상 사용되지 않음) {#load-from-a-git-repository-deprecated}

> [!warning]
> GitLab은 향후 릴리스에서 Git 브랜치에서 함수 로드 지원을 제거할 계획입니다. 대신 OCI 리포지토리에서 함수를 로드합니다.

Git 리포지토리에서 함수를 로드하려면 리포지토리의 URL 및 리비전(커밋, 브랜치 또는 태그)을 제공합니다. 리포지토리에 인증하려면 URL에 사용자 이름과 암호를 추가합니다.

Git 함수 참조를 `func`의 텍스트로 제공할 때 함수는 `steps` 하위 디렉토리에 있어야 합니다. 긴 형식의 Git 함수 참조 `git`를 사용할 때 함수는 `dir` 디렉토리에 있어야 합니다.

Git 리포지토리에는 소스가 포함되며 컴파일된 코드는 포함되지 않습니다. 가능하면 OCI 리포지토리에서 함수를 로드합니다.

예를 들어:

- 태그가 있는 함수를 지정합니다:

  ```yaml
  - name: my_step
    func: gitlab.com/funcs/my-git-repo@v1.0.0
  ```

- 분기가 있는 함수를 지정합니다:

  ```yaml
  - name: my_step
    func: gitlab.com/funcs/my-git-repo@main
  ```

- 디렉토리, 파일 이름 및 Git 커밋이 있는 함수를 지정합니다:

  ```yaml
  - name: my_step
    func: gitlab.com/funcs/my-git-repo/-/reverse/my-func.yml@3c63f399ace12061db4b8b9a29f522f41a3d7f25
  ```

- 가져올 때 Git에 인증합니다:

  ```yaml
  - name: my_step
    func: gitlab-ci-token:${{ vars.CI_JOB_TOKEN }}@gitlab.com/funcs/my-git-repo@v2.0.0
  ```

`steps` 폴더 외부의 디렉토리 또는 파일을 지정하려면 확장된 `func` 구문을 사용합니다:

```yaml
my-job:
  run:
    - name: my_step
      func:
        git:
          url: gitlab.com/funcs/my-git-repo
          rev: main
          dir: my-functions/sub-directory  # optional, defaults to the repository root
          file: my-func.yml                # optional, defaults to `func.yml`
```

### 표현식 {#expressions}

작업이 실행될 때까지 알 수 없는 값(예: 이전 단계의 출력, 작업 변수 또는 계산된 값)이 필요할 때 표현식을 사용합니다.

표현식은 `${{ }}` 구문을 사용하며 각 함수가 실행되기 전에 평가됩니다. 전체 표현식 언어 참조(연산자, 데이터 구조 및 기본 제공 함수 포함)는 [Moa 표현식 언어](moa.md)를 참조하세요.

표현식은 다음에서 사용할 수 있습니다:

- 입력 값 (`inputs`)
- 환경 변수 값 (`env`)
- 함수 참조 (`func`)
- 스크립트 콘텐츠 (`script`)

#### 사용 가능한 컨텍스트 {#available-context}

GitLab Functions를 사용할 때 다음 컨텍스트 변수를 사용합니다. 전체 컨텍스트 참조는 [Moa 표현식 언어](moa.md#context-reference)를 참조하세요.

| 변수                                  | 형식   | 설명                                                                                                                                                                                                   |
|:------------------------------------------|:-------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `env.<name>`                              | 문자열 | 함수가 실행될 때의 환경입니다. OS, 러너 및 이전에 실행한 단계에서 내보낸 환경 변수로 설정된 환경 변수를 포함합니다. `env`은(는) CI/CD 작업 변수를 포함하지 않습니다. |
| `vars.<name>`                             | 문자열 | 러너에서 전달되는 CI/CD 작업 변수입니다. `env`과(와) 달리 이 변수는 단계 내보내기의 영향을 받지 않습니다.                                                                                                      |
| `inputs.<name>`                           | 어떤    | 현재 함수에 전달되는 입력 값입니다.                                                                                                                                                              |
| `steps.<step_name>.outputs.<output_name>` | 어떤    | 현재 `run` 목록에서 이전에 완료된 단계의 출력 값입니다.                                                                                                                                     |
| `func_dir`                                | 문자열 | 함수의 정의 파일을 포함하는 디렉토리의 경로입니다. 함수와 함께 번들로 제공되는 파일을 참조하는 데 사용합니다.                                                                                            |
| `work_dir`                                | 문자열 | 현재 실행의 작업 디렉토리 경로입니다.                                                                                                                                                      |

#### 예제 {#examples}

- 이전 단계의 출력 참조:

  ```yaml
  my-job:
    run:
      - name: generate_rand
        func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/random:1
      - name: echo
        func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo:1
        inputs:
          message: "The random value is: ${{ steps.generate_rand.outputs.random_value }}"
  ```

- 폴백 기본값이 있는 작업 변수 사용:

  ```yaml
  run:
    - name: deploy
      func: ./deploy
      inputs:
        environment: ${{ vars.CI_COMMIT_REF_NAME == "main" && "production" || "staging" }}
  ```

### 환경 변수 {#environment-variables}

환경 변수는 두 가지 방식으로 단계 간에 이동합니다. `env`로 설정하거나 함수를 통해 내보냅니다. 그들은 서로 다른 범위를 가지고 있기 때문에 차이가 중요합니다.

CI/CD 작업 변수는 환경 변수로 사용할 수 없습니다. 대신 `${{ vars.<name> }}`을(를) 사용하여 작업 변수에 액세스합니다.

#### 단계에 대한 환경 변수 설정 {#set-environment-variables-for-a-step}

단계에서 `env` 키워드를 사용하여 해당 단계 및 이 호출하는 모든 함수의 환경 변수를 설정합니다. `env`로 설정된 변수는 환경에 이미 있는 모든 변수 외에 해당 단계에서 사용할 수 있습니다. 변수가 이미 있으면 `env`에서 설정한 값이 우선합니다. 이런 방식으로 설정된 변수는 동일한 `run` 목록의 후속 단계에서 사용할 수 없습니다.

```yaml
run:
  - name: build
    func: ./build
    env:
      BUILD_TARGET: release   # available to build and its child steps only
  - name: test
    func: ./test              # BUILD_TARGET is not available here
```

[표현식](#expressions)을(를) `env`의 키 및 값에 사용합니다.

#### 내보낸 환경 변수 {#exported-environment-variables}

함수가 `${{ export_file }}`에 쓸 때, 작성한 변수는 `run` 목록의 모든 후속 단계로 내보내집니다. 함수는 이 방법을 사용하여 나중 단계와 상태를 공유합니다.

내보낸 변수는 표현식의 `env`을(를) 통해 사용할 수 있습니다:

```yaml
run:
  - name: setup
    func: ./setup             # exports INSTALL_PATH during execution
  - name: build
    func: ./build
    inputs:
      path: ${{ env.INSTALL_PATH }}   # available because setup exported it
```

#### 우선 순위 {#precedence}

동일한 변수가 여러 위치에 설정된 경우 다음 순서가 적용되며, 높음에서 낮음 순입니다:

1. 함수 정의 (`func.yml`)에서 설정된 `env`
1. `run` 목록의 단계에서 설정된 `env`
1. 이전에 실행한 단계에서 내보냄
1. 러너에서 설정함
1. OS 프로세스 환경에서 설정함

## 자신만의 함수 만들기 {#create-your-own-function}

함수를 생성하려면 [GitLab Function 만들기](create.md)를 참조하세요.

예제 함수는 [GitLab Functions 예제](examples.md)를 참조하세요.

## 문제 해결 {#troubleshooting}

### HTTPS URL에서 함수 가져오기 {#fetch-functions-from-an-https-url}

`tls: failed to verify certificate: x509: certificate signed by unknown authority`과(와) 같은 오류 메시지는 운영 체제가 함수를 호스팅하는 서버를 인식하거나 신뢰하지 않음을 나타냅니다.

일반적인 원인은 신뢰할 수 있는 루트 인증서가 설치되지 않은 Docker 이미지입니다. 작업 `image`에 컨테이너에 인증서를 설치하거나 이를 구워서 문제를 해결합니다.

함수를 가져오기 전에 종속성을 설치하려면 `script` 단계를 사용할 수 있습니다:

```yaml
ubuntu_job:
  image: ubuntu:24.04
  run:
    - name: install_certs
      script: apt update && apt install --assume-yes --no-install-recommends ca-certificates
    - name: echo_step
      func: registry.gitlab.com/user/my_functions/hello_world:1.0.0
```
