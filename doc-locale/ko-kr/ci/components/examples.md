---
stage: Verify
group: Pipeline Authoring
info: This page is maintained by Developer Relations, author @dnsmichi, see <https://handbook.gitlab.com/handbook/marketing/developer-relations/developer-advocacy/content/#maintained-documentation>
title: CI/CD 구성 요소 예제
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## 구성 요소 테스트 {#test-a-component}

구성 요소의 기능에 따라 [구성 요소 테스트](_index.md#test-the-component)에 리포지토리의 추가 파일이 필요할 수 있습니다. 예를 들어, 특정 프로그래밍 언어로 소프트웨어를 린트, 빌드 및 테스트하는 구성 요소에는 실제 소스 코드 샘플이 필요합니다. 소스 코드 예제, 구성 파일 등을 동일한 리포지토리에 포함할 수 있습니다.

예를 들어, Code Quality CI/CD 구성 요소는 테스트용 여러 [코드 샘플](https://gitlab.com/components/code-quality/-/tree/main/src)을 포함합니다.

### 예: Rust 언어 CI/CD 구성 요소 테스트 {#example-test-a-rust-language-cicd-component}

구성 요소의 기능에 따라 [구성 요소 테스트](_index.md#test-the-component)에 리포지토리의 추가 파일이 필요할 수 있습니다.

Rust 프로그래밍 언어의 다음 "hello world" 예제는 간단하게 하기 위해 `cargo` 도구 체인을 사용합니다:

1. CI/CD 구성 요소 루트 디렉토리로 이동합니다.
1. `cargo init` 명령을 사용하여 새 Rust 프로젝트를 초기화합니다.

   ```shell
   cargo init
   ```

   명령은 `src/main.rs` "hello world" 예제를 포함하여 필요한 모든 프로젝트 파일을 만듭니다. 이 단계는 `cargo build`을 사용하여 구성 요소 작업에서 Rust 소스 코드를 빌드하기에 충분합니다.

   ```plaintext
   tree
   .
   ├── Cargo.toml
   ├── LICENSE.md
   ├── README.md
   ├── src
   │   └── main.rs
   └── templates
       └── build.yml
   ```

1. 구성 요소가 Rust 소스 코드를 빌드하는 작업을 가지고 있는지 확인하세요. 예를 들어, `templates/build.yml`에서:

   ```yaml
   spec:
     inputs:
       stage:
         default: build
         description: 'Defines the build stage'
       rust_version:
         default: latest
         description: 'Specify the Rust version, use values from https://hub.docker.com/_/rust/tags Defaults to latest'
   ---

   "build-$[[ inputs.rust_version ]]":
     stage: $[[ inputs.stage ]]
     image: rust:$[[ inputs.rust_version ]]
     script:
       - cargo build --verbose
   ```

   이 예에서:

   - `stage` 및 `rust_version` 입력값을 기본값에서 수정할 수 있습니다. CI/CD 작업은 `build-` 접두사로 시작하며 `rust_version` 입력값에 따라 동적으로 이름을 만듭니다. `cargo build --verbose` 명령은 Rust 소스 코드를 컴파일합니다.

1. 프로젝트의 `.gitlab-ci.yml` 구성 파일에서 구성 요소의 `build` 템플릿을 테스트합니다:

   ```yaml
   include:
     # include the component located in the current project from the current SHA
     - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/build@$CI_COMMIT_SHA
       inputs:
         stage: build

   stages: [build, test, release]
   ```

1. 테스트 실행 등을 위해 Rust 코드에 추가 함수와 테스트를 추가하고 `cargo test`을 실행하는 구성 요소 템플릿과 작업을 `templates/test.yml`에 추가합니다.

   ```yaml
   spec:
     inputs:
       stage:
         default: test
         description: 'Defines the test stage'
       rust_version:
         default: latest
         description: 'Specify the Rust version, use values from https://hub.docker.com/_/rust/tags Defaults to latest'
   ---

   "test-$[[ inputs.rust_version ]]":
     stage: $[[ inputs.stage ]]
     image: rust:$[[ inputs.rust_version ]]
     script:
       - cargo test --verbose
   ```

1. `test` 구성 요소 템플릿을 포함하여 파이프라인에서 추가 작업을 테스트합니다:

   ```yaml
   include:
     # include the component located in the current project from the current SHA
     - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/build@$CI_COMMIT_SHA
       inputs:
         stage: build
     - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/test@$CI_COMMIT_SHA
       inputs:
         stage: test

   stages: [build, test, release]
   ```

## CI/CD 구성 요소 패턴 {#cicd-component-patterns}

이 섹션에서는 CI/CD 구성 요소에서 일반적인 패턴을 구현하는 실용적인 예제를 제공합니다.

### 부울 입력값을 사용하여 작업을 조건부로 구성 {#use-boolean-inputs-to-conditionally-configure-jobs}

`boolean` 유형 입력값과 [`extends`](../yaml/_index.md#extends) 기능을 결합하여 두 개의 조건부를 사용하는 작업을 작성할 수 있습니다.

예를 들어, `boolean` 입력값으로 복잡한 캐싱 동작을 구성하려면:

```yaml
spec:
  inputs:
    enable_special_caching:
      description: 'If set to `true` configures a complex caching behavior'
      type: boolean
---

.my-component:enable_special_caching:false:
  extends: null

.my-component:enable_special_caching:true:
  cache:
    policy: pull-push
    key: $CI_COMMIT_SHA
    paths: [...]

my-job:
  extends: '.my-component:enable_special_caching:$[[ inputs.enable_special_caching ]]'
  script: ... # run some fancy tooling
```

이 패턴은 `enable_special_caching` 입력값을 작업의 `extends` 키워드로 전달하여 작동합니다. `enable_special_caching`이 `true` 또는 `false`인지 여부에 따라 미리 정의된 숨겨진 작업(`.my-component:enable_special_caching:true` 또는 `.my-component:enable_special_caching:false`)에서 적절한 구성이 선택됩니다.

### `options`을 사용하여 작업을 조건부로 구성 {#use-options-to-conditionally-configure-jobs}

`if` 및 `elseif` 조건부와 유사한 동작으로 여러 옵션을 사용하여 작업을 작성할 수 있습니다. 모든 조건에 대해 `string` 유형과 여러 `options`을 사용하여 [`extends`](../yaml/_index.md#extends)을 사용합니다.

예를 들어, 3개의 다른 옵션으로 복잡한 캐싱 동작을 구성하려면:

```yaml
spec:
  inputs:
    cache_mode:
      description: Defines the caching mode to use for this component
      type: string
      options:
        - default
        - aggressive
        - relaxed
---

.my-component:cache_mode:default:
  extends: null

.my-component:cache_mode:aggressive:
  cache:
    policy: push
    key: $CI_COMMIT_SHA
    paths: ['*/**']

.my-component:cache_mode:relaxed:
  cache:
    policy: pull-push
    key: $CI_COMMIT_BRANCH
    paths: ['bin/*']

my-job:
  extends: '.my-component:cache_mode:$[[ inputs.cache_mode ]]'
  script: ... # run some fancy tooling
```

이 예제에서 `cache_mode` 입력값은 `default`, `aggressive`, 및 `relaxed` 옵션을 제공하며, 각각은 다른 숨겨진 작업에 해당합니다. `extends: '.my-component:cache_mode:$[[ inputs.cache_mode ]]'`을 사용하여 구성 요소 작업을 확장하면 선택된 옵션에 따라 작업이 동적으로 올바른 캐싱 구성을 상속합니다.

### 버전이 지정된 리소스를 참조하기 위해 구성 요소 컨텍스트 사용 {#use-component-context-to-reference-versioned-resources}

{{< history >}}

- GitLab 18.6에서 [베타](../../policy/development_stages_support.md#beta)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/438275)되었으며 [플래그](../../administration/feature_flags/_index.md) 이름은 `ci_component_context_interpolation`입니다. 기본적으로 활성화됩니다.
- GitLab 18.7에서 [일반 공급 개시](https://gitlab.com/gitlab-org/gitlab/-/issues/571986)됨. 기능 플래그 `ci_component_context_interpolation`이 제거되었습니다.

{{< /history >}}

구성 요소 메타데이터(버전 및 커밋 SHA 등)를 참조하려면 구성 요소 컨텍스트 [CI/CD 표현식](../yaml/expressions.md)을 사용합니다. 한 가지 사용 사례는 구성 요소로 버전이 지정된 리소스(예: Docker 이미지)를 빌드 및 게시하고 구성 요소가 일치하는 버전을 사용하도록 하는 것입니다.

예를 들어, 다음을 수행할 수 있습니다:

- 구성 요소의 릴리스 파이프라인에서 구성 요소 버전과 일치하는 태그를 사용하여 Docker 이미지를 빌드합니다.
- 구성 요소가 동일한 이미지 버전을 참조하도록 합니다.

구성 요소 작업의 릴리스 파이프라인(`.gitlab-ci.yml`)에서:

```yaml
build-image:
  stage: build
  image: docker:latest
  script:
    - docker build -t $CI_REGISTRY_IMAGE/my-tool:$CI_COMMIT_TAG .
    - docker push $CI_REGISTRY_IMAGE/my-tool:$CI_COMMIT_TAG

create-release:
  stage: release
  image: registry.gitlab.com/gitlab-org/cli:latest
  script: echo "Creating release $CI_COMMIT_TAG"
  rules:
    - if: $CI_COMMIT_TAG
  release:
    tag_name: $CI_COMMIT_TAG
    description: "Release $CI_COMMIT_TAG"
```

구성 요소 템플릿(`templates/my-component/template.yml`)에서:

```yaml
spec:
  component: [version, reference]
  inputs:
    stage:
      default: test
---

run-tool:
  stage: $[[ inputs.stage ]]
  image: $CI_REGISTRY_IMAGE/my-tool:$[[ component.version ]]
  script:
    - echo "Running tool version $[[ component.version ]]"
    - echo "Component was included using reference: $[[ component.reference ]]"
    - my-tool --version
```

이 예에서:

- `@1.0.0`을 사용하여 구성 요소를 포함하면 작업은 `my-tool:1.0.0` 이미지를 사용합니다.
- `@1.0`을 사용하여 포함하면 최신 `1.0.x` 버전(예: `1.0.3`)으로 해석되므로 `my-tool:1.0.3`를 사용합니다.
- `@~latest`을 사용하여 포함하면 최신 릴리스 버전을 사용합니다.
- `component.reference` 필드는 `1.0`, `~latest` 또는 SHA와 같이 지정한 정확한 참조를 표시합니다. 이 참조는 로깅 또는 디버깅에 유용할 수 있습니다.

## CI/CD 구성 요소 마이그레이션 예제 {#cicd-component-migration-examples}

이 섹션에서는 CI/CD 템플릿 및 파이프라인 구성을 재사용 가능한 CI/CD 구성 요소로 마이그레이션하는 실용적인 예제를 보여줍니다.

### CI/CD 구성 요소 마이그레이션 예제: Go {#cicd-component-migration-example-go}

소프트웨어 개발 수명 주기를 위한 완전한 파이프라인을 여러 작업과 스테이지로 작성할 수 있습니다. 프로그래밍 언어용 CI/CD 템플릿은 단일 템플릿 파일에 여러 작업을 제공할 수 있습니다. 관례상 다음 Go CI/CD 템플릿을 마이그레이션해야 합니다.

```yaml
default:
  image: golang:latest

stages:
  - test
  - build
  - deploy

format:
  stage: test
  script:
    - go fmt $(go list ./... | grep -v /vendor/)
    - go vet $(go list ./... | grep -v /vendor/)
    - go test -race $(go list ./... | grep -v /vendor/)

compile:
  stage: build
  script:
    - mkdir -p mybinaries
    - go build -o mybinaries ./...
  artifacts:
    paths:
      - mybinaries
```

> [!note]
> 더 점진적인 접근 방식을 위해 한 번에 하나의 작업을 마이그레이션하세요. `build` 작업으로 시작한 다음 `format` 및 `test` 작업에 대해 단계를 반복하세요.

CI/CD 템플릿 마이그레이션에는 다음 단계가 포함됩니다:

1. CI/CD 작업과 종속성을 분석하고 마이그레이션 작업을 정의합니다:
   - `image` 구성은 전역이며, [작업 정의로 이동해야 합니다](_index.md#avoid-using-global-keywords).
   - `format` 작업은 하나의 작업에서 여러 `go` 명령을 실행합니다. `go test` 명령은 파이프라인 효율성을 높이기 위해 별도의 작업으로 이동해야 합니다.
   - `compile` 작업은 `go build`를 실행하며 `build`로 이름을 바꿔야 합니다.
1. 더 나은 파이프라인 효율성을 위해 최적화 전략을 정의합니다.
   - `stage` 작업 속성을 구성 가능하게 하여 다양한 CI/CD 파이프라인 소비자를 허용해야 합니다.
   - `image` 키는 `latest` 이미지 태그를 하드코딩합니다. [`golang_version`를 입력값으로](../inputs/_index.md) 추가하고 `latest`를 기본값으로 사용하여 더 유연하고 재사용 가능한 파이프라인을 만듭니다. 입력값은 Docker Hub 이미지 태그 값과 일치해야 합니다.
   - `compile` 작업은 바이너리를 하드코딩된 대상 디렉토리 `mybinaries`에 빌드하며, 동적 [입력값](../inputs/_index.md) 및 기본값 `mybinaries`로 향상될 수 있습니다.
1. 각 작업에 대해 하나의 템플릿을 기반으로 새 구성 요소에 대한 템플릿 [디렉토리 구조](_index.md#directory-structure)를 만듭니다.

   - 템플릿의 이름은 `go` 명령을 따르고 예를 들어 `format.yml`, `build.yml`, 및 `test.yml`입니다.
   - 새 작업을 만들고 Git 리포지토리를 초기화하고 모든 변경 사항을 추가/커밋하고 원격 원본을 설정한 후 푸시합니다. CI/CD 구성 요소 작업 경로에 대한 URL을 수정합니다.
   - [구성 요소 작성](_index.md#write-a-component) 지침에 개략적으로 설명된 대로 추가 파일을 만듭니다: `README.md`, `LICENSE.md`, `.gitlab-ci.yml`, `.gitignore`. 다음 셸 명령은 Go 구성 요소 구조를 초기화합니다:

   ```shell
   git init

   mkdir templates
   touch templates/{format,build,test}.yml

   touch README.md LICENSE.md .gitlab-ci.yml .gitignore

   git add -A
   git commit -avm "Initial component structure"

   git remote add origin https://gitlab.example.com/components/golang.git

   git push
   ```

1. 템플릿으로 CI/CD 작업을 만듭니다. `build` 작업으로 시작하세요.
   - `spec` 섹션에서 다음 입력값을 정의합니다: `stage`, `golang_version` 및 `binary_directory`.
   - 동적 작업 이름 정의를 추가하고 `inputs.golang_version`에 액세스합니다.
   - 동적 Go 이미지 버전에 대해 유사한 패턴을 사용하고 `inputs.golang_version`에 액세스합니다.
   - `inputs.stage` 값에 스테이지를 할당합니다.
   - `inputs.binary_directory`에서 바이너리 디렉토리를 만들고 `go build`의 매개변수로 추가합니다.
   - 아티팩트 경로를 `inputs.binary_directory`로 정의합니다.

     ```yaml
     spec:
       inputs:
         stage:
           default: 'build'
           description: 'Defines the build stage'
         golang_version:
           default: 'latest'
           description: 'Go image version tag'
         binary_directory:
           default: 'mybinaries'
           description: 'Output directory for created binary artifacts'
     ---

     "build-$[[ inputs.golang_version ]]":
       image: golang:$[[ inputs.golang_version ]]
       stage: $[[ inputs.stage ]]
       script:
         - mkdir -p $[[ inputs.binary_directory ]]
         - go build -o $[[ inputs.binary_directory ]] ./...
       artifacts:
         paths:
           - $[[ inputs.binary_directory ]]
     ```

   - `format` 작업 템플릿은 동일한 패턴을 따르지만 `stage` 및 `golang_version` 입력값만 필요합니다.

     ```yaml
     spec:
       inputs:
         stage:
           default: 'format'
           description: 'Defines the format stage'
         golang_version:
           default: 'latest'
           description: 'Golang image version tag'
     ---

     "format-$[[ inputs.golang_version ]]":
       image: golang:$[[ inputs.golang_version ]]
       stage: $[[ inputs.stage ]]
       script:
         - go fmt $(go list ./... | grep -v /vendor/)
         - go vet $(go list ./... | grep -v /vendor/)
     ```

   - `test` 작업 템플릿은 동일한 패턴을 따르지만 `stage` 및 `golang_version` 입력값만 필요합니다.

     ```yaml
     spec:
       inputs:
         stage:
           default: 'test'
           description: 'Defines the format stage'
         golang_version:
           default: 'latest'
           description: 'Golang image version tag'
     ---

     "test-$[[ inputs.golang_version ]]":
       image: golang:$[[ inputs.golang_version ]]
       stage: $[[ inputs.stage ]]
       script:
         - go test -race $(go list ./... | grep -v /vendor/)
     ```

1. 구성 요소를 테스트하기 위해 `.gitlab-ci.yml` 구성 파일을 수정하고 [테스트](_index.md#test-the-component)를 추가합니다.

   - `golang_version` 작업의 입력값으로 `build`에 대한 다른 값을 지정합니다.
   - CI/CD 구성 요소 경로에 대한 URL을 수정합니다.

     ```yaml
     stages: [format, build, test]

     include:
       - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/format@$CI_COMMIT_SHA
       - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/build@$CI_COMMIT_SHA
       - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/build@$CI_COMMIT_SHA
         inputs:
           golang_version: "1.21"
       - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/test@$CI_COMMIT_SHA
         inputs:
           golang_version: latest
     ```

1. CI/CD 구성 요소를 테스트할 Go 소스 코드를 추가합니다. `go` 명령은 루트 디렉토리에 `go.mod` 및 `main.go`이 있는 Go 작업을 예상합니다.

   - Go 모듈을 초기화합니다. CI/CD 구성 요소 경로에 대한 URL을 수정합니다.

     ```shell
     go mod init example.gitlab.com/components/golang
     ```

   - `main.go` 파일을 작업 함수로 만들고 예를 들어 `Hello, CI/CD component`을 인쇄합니다. 코드 주석을 사용하여 GitLab Duo 코드 제안을 사용하여 Go 코드를 생성할 수 있습니다.

     ```go
     // Specify the package, import required packages
     // Create a main function
     // Inside the main function, print "Hello, CI/CD Component"

     package main

     import "fmt"

     func main() {
       fmt.Println("Hello, CI/CD Component")
     }
     ```

   - 디렉토리 트리는 다음과 같아야 합니다:

     ```plaintext
     tree
     .
     ├── LICENSE.md
     ├── README.md
     ├── go.mod
     ├── main.go
     └── templates
         ├── build.yml
         ├── format.yml
         └── test.yml
     ```

마이그레이션을 완료하려면 [CI/CD 템플릿을 구성 요소로 변환](_index.md#convert-a-cicd-template-to-a-component) 섹션의 나머지 단계를 따릅니다:

1. 커밋하고 변경 사항을 푸시한 후 CI/CD 파이프라인 결과를 확인합니다.
1. [구성 요소 작성](_index.md#write-a-component)에 대한 지침을 따라 `README.md` 및 `LICENSE.md` 파일을 업데이트합니다.
1. [구성 요소 릴리스](_index.md#publish-a-new-release)하고 CI/CD 카탈로그에서 확인합니다.
1. CI/CD 구성 요소를 스테이징/프로덕션 환경에 추가합니다.

[GitLab이 유지보수하는 Go 구성 요소](https://gitlab.com/components/go)는 입력값 및 구성 요소 모범 사례로 향상된 Go CI/CD 템플릿에서 성공적인 마이그레이션의 예제를 제공합니다. Git 기록을 검사하여 자세히 알아볼 수 있습니다.
