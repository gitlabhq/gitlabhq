---
stage: Verify
group: CI Functions Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Function 만들기
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  실험적 기능

{{< /details >}}

GitLab 함수는 함수의 인터페이스와 구현을 정의하는 `func.yml` 파일이 포함된 디렉터리입니다. 함수는 로컬에서 실행하거나 OCI 레지스트리에 게시하여 작업 및 프로젝트 전체에서 재사용할 수 있습니다.

CI/CD 작업에서 함수를 사용하는 방법에 대한 정보는 [GitLab 함수](_index.md)를 참조하세요. 예제 함수는 [GitLab 함수 예제](examples.md)를 참조하세요.

## 함수 구조 {#function-structure}

함수는 최소한 `func.yml` 파일과 구현에 필요한 모든 보조 파일을 포함하는 디렉터리입니다:

```plaintext
my-function/
├── func.yml
└── my-script.sh
```

`func.yml` 파일에는 `---`로 구분된 두 개의 YAML 문서가 포함됩니다. 함수의 입력 및 출력을 정의하는 사양과 함수가 수행하는 작업을 설명하는 정의입니다.

```yaml
# Document 1: spec
spec:
  inputs:
    message:
      type: string
  outputs:
    result:
      type: string
---
# Document 2: definition
exec:
  command: ["${{ func_dir }}/my-script.sh", "${{ inputs.message }}"]
```

## 사양: 입력 및 출력 선언 {#spec-declare-inputs-and-outputs}

사양은 함수의 인터페이스를 설명합니다.

### 입력 {#inputs}

각 입력에는 `type`이(가) 필요합니다. `default` 값이 있는 입력은 선택 사항입니다. 기본값이 없는 입력은 호출자가 제공해야 합니다.

입력 이름은 영숫자와 밑줄을 사용해야 하며 숫자로 시작할 수 없습니다.

입력은 다음 유형 중 하나여야 합니다:

| 형식      | 예제                 | 설명             |
|:----------|:------------------------|:------------------------|
| `array`   | `["a","b"]`             | 형식화되지 않은 항목의 목록 |
| `boolean` | `true`                  | 참 또는 거짓           |
| `number`  | `56.77`                 | 64비트 부동 소수점            |
| `string`  | `"brown cow"`           | 텍스트                    |
| `struct`  | `{"k1":"v1","k2":"v2"}` | 구조화된 콘텐츠      |

예를 들어:

```yaml
spec:
  inputs:
    # Required string input
    message:
      type: string

    # Optional input with a default
    count:
      type: number
      default: 1

    # Struct input for passing structured data
    config:
      type: struct
      default: {}
```

### 출력 {#outputs}

출력은 함수가 후속 단계로 반환하는 값을 정의합니다. 각 출력에는 `type`이(가) 필요합니다. `default` 값이 있는 출력은 선택 사항입니다. 기본값은 함수가 출력 값을 쓰지 않을 때 사용됩니다.

출력은 입력과 동일한 유형 및 명명 규칙을 사용합니다.

예를 들어:

```yaml
spec:
  outputs:
    # Required string output
    artifact_path:
      type: string

    # Optional output with a default
    compressed:
      type: boolean
      default: false
```

런타임에 함수는 출력 값을 `${{ output_file }}`로 주어진 경로에 씁니다. 각 라인은 `name` 및 `value` 필드가 있는 JSON 객체여야 합니다:

```shell
echo '{"name":"artifact_path","value":"/dist/app.tar.gz"}' >> "${{ output_file }}"
echo '{"name":"compressed","value":true}' >> "${{ output_file }}"
```

### 출력 위임 {#delegate-outputs}

함수에 여러 단계가 있고 함수의 출력이 특정 단계에서 나오기를 원하는 경우, 사양에서 `outputs: delegate`을(를) 사용하고 정의에서 `delegate: <step_name>`을(를) 사용합니다:

```yaml
spec:
  outputs: delegate
---
run:
  - name: build
    func: ./build
  - name: package
    func: ./package
delegate: package  # use the package step outputs as this function outputs
```

## 정의: 함수 구현 {#definition-implement-the-function}

`func.yml`의 두 번째 문서는 구현을 설명합니다. 두 가지 방법으로 함수를 구현할 수 있습니다.

### `exec` {#exec}

`exec`을(를) 사용하여 단일 명령이나 스크립트를 실행합니다. 명령이 셸 없이 OS에 직접 전달되므로 문자열 배열이어야 합니다.

```yaml
spec:
  inputs:
    message:
      type: string
---
exec:
  command: ["./greet", "${{ inputs.message }}"]
```

작업 디렉터리는 `CI_PROJECT_DIR`로 기본 설정됩니다. 이를 재정의하려면 `work_dir`을(를) 사용합니다. `work_dir` 키워드는 `exec` 정의에만 유효하며 `run:` 정의에는 유효하지 않습니다.

명령이 `func.yml`과(와) 같은 디렉터리에 있는 파일을 참조해야 할 때 `work_dir`을(를) `${{ func_dir }}`로 설정합니다:

```yaml
exec:
  command: ["./build.sh"]
  work_dir: "${{ func_dir }}"
```

명령이 0이 아닌 종료 코드로 종료되면 함수가 실패합니다.

### `run` {#run}

`run`을(를) 사용하여 다른 함수를 순서대로 호출하는 함수를 만듭니다.

시퀀스의 모든 단계가 실패하면 함수가 실패합니다. 실패 후 시퀀스의 후속 단계는 실행되지 않습니다.

```yaml
spec:
  inputs:
    environment:
      type: string
  outputs:
    url:
      type: string
---
run:
  - name: build
    func: ./build
  - name: push
    func: registry.example.com/my-org/push:1.0.0
    inputs:
      artifact: ${{ steps.build.outputs.artifact_path }}
  - name: deploy
    func: ./deploy
    inputs:
      env: ${{ inputs.environment }}
      image: ${{ steps.push.outputs.image_ref }}
outputs:
  url: ${{ steps.deploy.outputs.url }}
```

### 환경 변수 설정 {#set-environment-variables}

정의에서 `env`을(를) 사용하여 `exec` 명령의 환경 변수를 설정하거나 `run:` 시퀀스의 모든 단계를 설정합니다. 값은 표현식을 사용할 수 있습니다:

```yaml
spec:
---
run:
  - name: test
    func: ./run-tests
env:
  GOFLAGS: "-race"
  TARGET_ENV: "${{ inputs.environment }}"
```

## 환경 변수 내보내기 {#export-environment-variables}

환경 변수를 함수 실행 후 작업이 남은 동안 실행되는 모든 단계에서 사용할 수 있도록 하려면 `${{ export_file }}`에 쓰세요. 각 라인은 `name` 및 `value` 필드가 있는 JSON 객체여야 합니다:

```shell
echo '{"name":"INSTALL_PATH","value":"/opt/myapp"}' >> "${{ export_file }}"
```

`string`, `number`, `boolean` 값만 환경 변수로 내보낼 수 있습니다.

내보낸 변수가 `env:`과(와) 더 넓은 환경과 상호 작용하는 방법에 대한 자세한 내용은 [환경 변수](_index.md#environment-variables)를 참조하세요.

## 표현식 {#expressions}

표현식은 `${{ }}` 구문을 사용하며 함수 실행 직전에 평가됩니다. `inputs` 값, `env` 값, `exec` 명령 인수, `work_dir`에 나타날 수 있습니다.

다음 컨텍스트 변수는 함수 정의 내에서 사용할 수 있으며, [표현식](_index.md#expressions)에 설명된 변수 외에도 사용할 수 있습니다:

| 변수                                  | 설명                                                                                 |
|:------------------------------------------|:--------------------------------------------------------------------------------------------|
| `inputs.<name>`                           | 이 함수에 전달된 명명된 입력의 값입니다.                                       |
| `func_dir`                                | 이 `func.yml`을(를) 포함하는 디렉터리의 절대 경로입니다. 번들로 제공된 파일을 참조하는 데 사용합니다.  |
| `output_file`                             | 출력을 쓰기 위한 파일의 경로입니다.                                                       |
| `export_file`                             | 환경 변수를 내보내기 위한 파일의 경로입니다.                                       |
| `steps.<step_name>.outputs.<output_name>` | 명명된 단계의 출력(`run:` 정의에서만 사용 가능)입니다.                            |

## 완전한 예제 {#complete-example}

다음 함수는 파일 경로를 수락하여 `gzip`으로 압축하고 압축된 파일의 경로를 반환합니다.

### 함수 만들기 {#create-the-function}

디렉터리 레이아웃:

```plaintext
compress/
├── func.yml
└── compress.sh
```

`func.yml`:

```yaml
spec:
  inputs:
    input_path:
      type: string
  outputs:
    output_path:
      type: string
---
exec:
  command: ["${{ func_dir }}/compress.sh", "${{ inputs.input_path }}", "${{ output_file }}"]
```

`compress.sh` (실행 가능해야 함):

```shell
#!/usr/bin/env sh
set -e

INPUT_PATH="$1"
OUTPUT_FILE="$2"

gzip --keep "$INPUT_PATH"

echo "{\"name\":\"output_path\",\"value\":\"${INPUT_PATH}.gz\"}" >> "$OUTPUT_FILE"
```

### 작업에서 함수 사용 {#use-the-function-from-a-job}

이 함수는 작업 환경에서 `gzip`을(를) 필요로 합니다. 이 예제는 `gzip`이(가) 작업이 실행되는 인스턴스에서 이미 사용 가능하다고 가정합니다. 그렇지 않은 경우 `script:` 단계로 먼저 설치하거나 설치를 처리한 후 `compress`를 호출하는 함수를 호출할 수 있습니다.

```yaml
my-job:
  run:
    - name: compress_artifact
      func: ./compress
      inputs:
        input_path: "dist/app.tar"
    - name: list_compressed
      script: ls -lh ${{ steps.compress_artifact.outputs.output_path }}
```

더 많은 예제 함수는 [GitLab 함수 예제](examples.md)를 참조하세요.

## 함수 빌드 및 릴리스 {#build-and-release-functions}

함수는 OCI 이미지로 배포됩니다. 단계 러너는 함수 이미지를 빌드하고 게시하기 위한 두 가지 기본 제공 함수를 제공합니다.

### 빌드 {#build}

`builtin://function/oci/build` 함수는 프로젝트 디렉터리의 파일에서 다중 아키텍처 함수 OCI 이미지를 빌드하고 `CI_PROJECT_DIR`에서 `function-image.tar`로 보관합니다.

`common.files`은(는) 모든 플랫폼 전체에서 공유되는 파일을 복사합니다. `platforms.<os/arch>.files`은(는) 해당 플랫폼과 관련된 파일을 복사합니다. 두 경우 모두 맵 키는 이미지의 대상 경로이고 값은 `CI_PROJECT_DIR`에 상대적인 원본 경로입니다.

다음 예제에서 `function-image.tar`은(는) `linux/amd64`과(와) `linux/arm64`의 두 플랫폼을 지원하는 함수 OCI 이미지입니다. 각 플랫폼 이미지에는 `func.yml`, `my-script.sh`, `bin/my-binary` 세 파일이 있습니다. 플랫폼 바이너리에 동일한 파일 이름을 사용하면 `func.yml`이(가) 플랫폼 독립적으로 유지됩니다.

<!-- vale gitlab_base.Substitutions = NO -->
```yaml
build_function:
  artifacts:
    paths:
      - function-image.tar
  run:
    - name: build
      func: builtin://function/oci/build
      inputs:
        version: "1.2.3"
        common:
          files:
            func.yml: func.yml
            my-script.sh: my-script.sh
        platforms:
          linux/amd64:
            files:
              bin/my-binary: bin/linux-amd64/my-binary
          linux/arm64:
            files:
              bin/my-binary: bin/linux-arm64/my-binary
```
<!-- vale gitlab_base.Substitutions = YES -->

### 릴리스 {#release}

`builtin://function/oci/publish` 함수는 `function/oci/build`의 보관함을 OCI 레지스트리에 게시합니다.

게시 함수는 함수 이미지 태그에 시멘틱 버전 관리를 사용합니다: `1.0.0`, `1.1.0`, `2.0.0`. 함수는 `function-image.tar` 파일에서 버전을 추출합니다. 게시는 `major`, `major.minor`, `major.minor.patch` 및 `latest` 태그를 필요에 따라 업데이트합니다.

릴리스 후보는 `1.2.0-rc1`과(와) 같은 사전 릴리스 접미사를 사용합니다. 릴리스 후보를 게시하면 정확한 `major.minor.patch-prerelease` 태그만 만들어집니다. `major`, `major.minor`, `latest` 태그는 업데이트하지 않습니다.

```yaml
publish_function:
  needs: [build_function]
  run:
    - name: publish
      func: builtin://function/oci/publish
      inputs:
        archive: function-image.tar  # version is baked into the tar file
        to_repository: registry.example.com/my-org/my-function
```

### 레지스트리에 인증 {#authenticate-to-a-registry}

비공개 레지스트리에 게시하려면 `function/oci/publish`을(를) 실행하기 전에 인증합니다. [Docker Auth](https://gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/docker-auth) 함수를 사용하여 게시하기 전에 단계로 `DOCKER_AUTH_CONFIG`을(를) 생성하고 내보냅니다:

```yaml
publish_function:
  needs: [build_function]
  run:
    - name: auth
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/docker-auth:1
      inputs:
        registry: ${{ vars.CI_REGISTRY }}
        username: ${{ vars.CI_REGISTRY_USER }}
        password: ${{ vars.CI_REGISTRY_PASSWORD }}
    - name: publish
      func: builtin://function/oci/publish
      inputs:
        archive: function-image.tar
        to_repository: ${{ vars.CI_REGISTRY_IMAGE }}
```

`docker-auth`은(는) `DOCKER_AUTH_CONFIG`을(를) 모든 후속 단계로 내보내므로 `function/oci/publish`은(는) 자동으로 선택합니다.

게시되면 호출자는 레지스트리 URL과 태그를 사용하여 함수를 참조합니다:

```yaml
run:
  - name: run_my_function
    func: registry.example.com/my-org/my-function:1.2.3
```
