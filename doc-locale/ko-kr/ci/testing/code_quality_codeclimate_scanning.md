---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CodeClimate 기반 코드 품질 스캔 구성(더 이상 사용하지 않음)
---

<!--- start_remove The following content will be removed on remove_date: '2026-08-15' -->

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> 이 기능은 GitLab 17.3에서 [사용 중단됨](../../update/deprecations.md#codeclimate-based-code-quality-scanning-will-be-removed)되었으며 19.0에서 제거할 예정입니다. [지원되는 도구의 결과를 직접 통합](code_quality.md#import-code-quality-results-from-a-cicd-job)하세요. 이 변경은 주요 변경사항입니다.

코드 품질에는 빌트인 CI/CD 템플릿인 `Code-Quality.gitlab-ci.yaml`이(가) 포함됩니다. 이 템플릿은 오픈 소스 CodeClimate 스캔 엔진을 기반으로 한 스캔을 실행합니다.

CodeClimate 엔진이 실행됩니다:

- [지원되는 언어 집합](https://docs.codeclimate.com/docs/supported-languages-for-maintainability)에 대한 기본 유지 보수성 검사를 수행합니다.
- 오픈 소스 스캐너를 래핑하는 구성 가능한 [플러그인](https://docs.codeclimate.com/docs/list-of-engines) 세트로 소스 코드를 분석합니다.

## CodeClimate 기반 스캔 활성화 {#enable-codeclimate-based-scanning}

전제 조건:

- GitLab CI/CD 구성(`.gitlab-ci.yml`)에는 `test` 스테이지가 포함되어야 합니다.
- 인스턴스 러너를 사용하는 경우 코드 품질 작업을 [Docker-in-Docker 워크플로우](../docker/using_docker_build.md#use-docker-in-docker)에 맞게 구성해야 합니다. 이 워크플로우를 사용할 때 `/builds` 볼륨을 매핑하여 보고서를 저장할 수 있어야 합니다.
- 프라이빗 러너를 사용하는 경우 코드 품질 분석을 더 효율적으로 실행하기 위해 권장되는 [대체 구성](#use-private-runners)을 사용해야 합니다.
- 러너는 생성된 코드 품질 파일을 저장할 충분한 디스크 공간이 있어야 합니다. 예를 들어 [GitLab 프로젝트](https://gitlab.com/gitlab-org/gitlab)의 경우 파일이 약 7GB입니다.

코드 품질을 활성화하려면 다음 중 하나를 수행하세요:

- [Auto DevOps](../../topics/autodevops/_index.md)를 활성화하면 [Auto 코드 품질](../../topics/autodevops/stages.md#auto-code-quality)이 포함됩니다.

- [코드 품질 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Code-Quality.gitlab-ci.yml)을 `.gitlab-ci.yml` 파일에 포함하세요.

  예:

  ```yaml
     include:
     - template: Jobs/Code-Quality.gitlab-ci.yml
  ```

  코드 품질은 이제 파이프라인에서 실행됩니다.

> [!warning]
> GitLab Self-Managed에서 악의적인 사용자가 코드 품질 작업 정의를 손상시키면 러너 호스트에서 권한 있는 Docker 명령을 실행할 수 있습니다. 적절한 액세스 제어 정책이 있으면 신뢰할 수 있는 사용자만 액세스하도록 허용하여 이 공격 벡터를 완화할 수 있습니다.

## CodeClimate 기반 스캔 비활성화 {#disable-codeclimate-based-scanning}

`code_quality` 작업은 `$CODE_QUALITY_DISABLED` CI/CD 변수가 있으면 실행되지 않습니다. 변수를 정의하는 방법에 대한 자세한 내용은 [GitLab CI/CD 변수](../variables/_index.md)를 참조하세요.

코드 품질을 비활성화하려면 다음 중 하나에 대해 `CODE_QUALITY_DISABLED`이라는 사용자 지정 CI/CD 변수를 만드세요:

- [전체 프로젝트](../variables/_index.md#for-a-project).
- [단일 파이프라인](../pipelines/_index.md#run-a-pipeline-manually).

## CodeClimate 분석 플러그인 구성 {#configure-codeclimate-analysis-plugins}

기본적으로 `code_quality` 작업은 CodeClimate를 다음과 같이 구성합니다:

- [특정 플러그인 집합](https://gitlab.com/gitlab-org/ci-cd/codequality/-/blob/master/codeclimate_defaults/.codeclimate.yml.template?ref_type=heads)을 사용합니다.
- 해당 플러그인에 대한 [기본 구성](https://gitlab.com/gitlab-org/ci-cd/codequality/-/tree/master/codeclimate_defaults?ref_type=heads)을 사용합니다.

더 많은 언어를 스캔하려면 더 많은 [플러그인](https://docs.codeclimate.com/docs/list-of-engines)을 활성화할 수 있습니다. `code_quality` 작업이 기본적으로 활성화하는 플러그인을 비활성화할 수도 있습니다.

예를 들어 [SonarJava 분석기](https://docs.codeclimate.com/docs/sonar-java)를 사용하려면:

1. `.codeclimate.yml`이라는 파일을 리포지토리의 루트에 추가하세요.
1. 플러그인에 대한 [활성화 코드](https://docs.codeclimate.com/docs/sonar-java#enable-the-plugin)를 리포지토리 루트에서 `.codeclimate.yml` 파일에 추가하세요:

   ```yaml
   version: "2"
   plugins:
     sonar-java:
       enabled: true
   ```

이렇게 하면 SonarJava가 `plugins:` 섹션의 [기본 `.codeclimate.yml`](https://gitlab.com/gitlab-org/ci-cd/codequality/-/blob/master/codeclimate_defaults/.codeclimate.yml.template)에 추가되어 프로젝트에 포함됩니다.

`plugins:` 섹션의 변경 사항은 기본 `.codeclimate.yml`의 `exclude_patterns` 섹션에 영향을 주지 않습니다. 자세한 내용은 코드 클라이밋 설명서의 [파일 및 폴더 제외](https://docs.codeclimate.com/docs/excluding-files-and-folders)를 참조하세요.

## 스캔 작업 설정 사용자 정의 {#customize-scan-job-settings}

GitLab CI/CD YAML에서 [CI/CD 변수](#available-cicd-variables)를 설정하여 `code_quality` 스캔 작업의 동작을 변경할 수 있습니다.

코드 품질 작업을 구성하려면:

1. 템플릿 포함 후 코드 품질 작업과 동일한 이름으로 작업을 선언하세요.
1. 작업의 스탠자에 추가 키를 지정하세요.

예제는 [HTML 형식으로만 출력 다운로드](#output-in-only-html-format)를 참조하세요.

### 사용 가능한 CI/CD 변수 {#available-cicd-variables}

코드 품질은 사용 가능한 CI/CD 변수를 정의하여 사용자 정의할 수 있습니다:

| CI/CD 변수                  | 설명 |
|---------------------------------|-------------|
| `CODECLIMATE_DEBUG`             | [코드 클라이밋 디버그 모드](https://github.com/codeclimate/codeclimate#environment-variables)를 활성화하도록 설정합니다. |
| `CODECLIMATE_DEV`               | `--dev` 모드를 활성화하도록 설정하면 CLI에 알려지지 않은 엔진을 실행할 수 있습니다. |
| `CODECLIMATE_PREFIX`            | CodeClimate 엔진에서 모든 `docker pull` 명령과 함께 사용할 접두사를 설정합니다. [오프라인 스캔](https://github.com/codeclimate/codeclimate/pull/948)에 유용합니다. 자세한 내용은 [프라이빗 컨테이너 레지스트리 사용](#use-a-private-container-image-registry)을 참조하세요. |
| `CODECLIMATE_REGISTRY_USERNAME` | `CODECLIMATE_PREFIX`에서 구문 분석한 레지스트리 도메인의 사용자 이름을 지정하도록 설정합니다. |
| `CODECLIMATE_REGISTRY_PASSWORD` | `CODECLIMATE_PREFIX`에서 구문 분석한 레지스트리 도메인의 암호를 지정하도록 설정합니다. |
| `CODE_QUALITY_DISABLED`         | 코드 품질 작업이 실행되지 않도록 합니다. |
| `CODE_QUALITY_IMAGE`            | 완전히 접두사가 붙은 이미지 이름으로 설정합니다. 이미지는 작업 환경에서 액세스할 수 있어야 합니다. |
| `ENGINE_MEMORY_LIMIT_BYTES`     | 엔진의 메모리 제한을 설정합니다. 기본값: 1,024,000,000바이트. |
| `REPORT_STDOUT`                 | 보고서를 `STDOUT`로 인쇄하도록 설정하며, 일반 보고서 파일을 생성하지 않습니다. |
| `REPORT_FORMAT`                 | 생성된 보고서 파일의 형식을 제어하도록 설정합니다. `json` 또는 `html`. |
| `SOURCE_CODE`                   | 스캔할 소스 코드의 경로입니다. 복제된 소스가 저장된 디렉터리의 절대 경로여야 합니다. |
| `TIMEOUT_SECONDS`               | `codeclimate analyze` 명령의 엔진 컨테이너당 사용자 정의 시간 제한입니다. 기본값: 900초(15분) |

### 출력 {#output}

코드 품질은 발견된 이슈의 세부 정보를 포함하는 보고서를 출력합니다. 이 보고서의 내용은 내부적으로 처리되고 결과가 UI에 표시됩니다. 보고서는 또한 `code_quality` 작업의 작업 아티팩트로 `gl-code-quality-report.json`라는 이름으로 출력됩니다. 선택적으로 HTML 형식으로 보고서를 출력할 수 있습니다. 예를 들어 HTML 형식 파일을 GitLab Pages에 게시하여 더 쉽게 검토할 수 있습니다.

#### JSON 및 HTML 형식으로 출력 {#output-in-json-and-html-format}

코드 품질 보고서를 JSON 및 HTML 형식으로 출력하려면 추가 작업을 만듭니다. 이를 위해서는 코드 품질을 파일 형식당 한 번씩 두 번 실행해야 합니다.

코드 품질 보고서를 HTML 형식으로 출력하려면 `extends: code_quality`을(를) 사용하여 템플릿에 다른 작업을 추가하세요:

```yaml
include:
  - template: Jobs/Code-Quality.gitlab-ci.yml

code_quality_html:
  extends: code_quality
  variables:
    REPORT_FORMAT: html
  artifacts:
    paths: [gl-code-quality-report.html]
```

JSON 및 HTML 파일은 모두 작업 아티팩트로 출력됩니다. HTML 파일은 `artifacts.zip` 작업 아티팩트에 포함됩니다.

#### HTML 형식으로만 출력 {#output-in-only-html-format}

`REPORT_FORMAT`을(를) `html`로 설정하여 코드 품질 보고서를 HTML 형식으로만 다운로드하면 `code_quality` 작업의 기본 정의를 재정의합니다.

> [!note]
> 이렇게 하면 JSON 형식 파일이 생성되지 않으므로 코드 품질 결과가 머지 리퀘스트 위젯, 파이프라인 보고서 또는 변경사항 보기에 표시되지 않습니다.

```yaml
include:
  - template: Jobs/Code-Quality.gitlab-ci.yml

code_quality:
  variables:
    REPORT_FORMAT: html
  artifacts:
    paths: [gl-code-quality-report.html]
```

HTML 파일은 작업 아티팩트로 출력됩니다.

## 머지 리퀘스트 파이프라인과 함께 코드 품질 사용 {#use-code-quality-with-merge-request-pipelines}

기본 코드 품질 구성은 `code_quality` 작업이 [머지 리퀘스트 파이프라인](../pipelines/merge_request_pipelines.md)에서 실행되는 것을 허용하지 않습니다.

머지 리퀘스트 파이프라인에서 코드 품질을 실행하도록 활성화하려면 코드 품질 `rules` 또는 [`workflow: rules`](../yaml/_index.md#workflow)을(를) 덮어써서 현재 `rules`과(와) 일치하도록 하세요.

예를 들어:

```yaml
include:
  - template: Jobs/Code-Quality.gitlab-ci.yml

code_quality:
  rules:
    - if: $CODE_QUALITY_DISABLED
      when: never
    - if: $CI_PIPELINE_SOURCE == "merge_request_event" # Run code quality job in merge request pipelines
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH      # Run code quality job in pipelines on the default branch (but not in other branch pipelines)
    - if: $CI_COMMIT_TAG                               # Run code quality job in pipelines for tags
```

## CodeClimate 이미지를 다운로드하는 방식 변경 {#change-how-codeclimate-images-are-downloaded}

CodeClimate 엔진은 각 플러그인을 실행하기 위해 컨테이너 이미지를 다운로드합니다. 기본적으로 이미지는 Docker Hub에서 다운로드됩니다. 이미지 소스를 변경하여 성능을 개선하거나, Docker Hub 속도 제한을 해결하거나, 프라이빗 레지스트리를 사용할 수 있습니다.

### 종속성 프록시를 사용하여 이미지 다운로드 {#use-the-dependency-proxy-to-download-images}

종속성 프록시를 사용하여 종속성 다운로드에 소요되는 시간을 줄일 수 있습니다.

전제 조건:

- 프로젝트의 그룹에서 [종속성 프록시](../../user/packages/dependency_proxy/_index.md)를 활성화했습니다.

종속성 프록시를 참조하려면 `.gitlab-ci.yml` 파일에서 다음 변수를 구성하세요:

- `CODE_QUALITY_IMAGE`
- `CODECLIMATE_PREFIX`
- `CODECLIMATE_REGISTRY_USERNAME`
- `CODECLIMATE_REGISTRY_PASSWORD`

예를 들어:

```yaml
include:
  - template: Jobs/Code-Quality.gitlab-ci.yml

code_quality:
  variables:
    ## You must add a trailing slash to `$CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX`.
    CODECLIMATE_PREFIX: $CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX/
    CODECLIMATE_REGISTRY_USERNAME: $CI_DEPENDENCY_PROXY_USER
    CODECLIMATE_REGISTRY_PASSWORD: $CI_DEPENDENCY_PROXY_PASSWORD
```

### 인증과 함께 Docker Hub 사용 {#use-docker-hub-with-authentication}

Docker Hub를 코드 품질 이미지의 대체 소스로 사용할 수 있습니다.

전제 조건:

- 사용자 이름과 암호를 프로젝트의 [보호된 CI/CD 변수](../variables/_index.md#for-a-project)로 추가하세요.

DockerHub를 사용하려면 `.gitlab-ci.yml` 파일에서 다음 변수를 구성하세요:

- `CODECLIMATE_PREFIX`
- `CODECLIMATE_REGISTRY_USERNAME`
- `CODECLIMATE_REGISTRY_PASSWORD`

예:

```yaml
include:
  - template: Jobs/Code-Quality.gitlab-ci.yml

code_quality:
  variables:
    CODECLIMATE_PREFIX: "registry-1.docker.io/"
    CODECLIMATE_REGISTRY_USERNAME: $DOCKERHUB_USERNAME
    CODECLIMATE_REGISTRY_PASSWORD: $DOCKERHUB_PASSWORD
```

### 프라이빗 컨테이너 이미지 레지스트리 사용 {#use-a-private-container-image-registry}

프라이빗 컨테이너 이미지 레지스트리를 사용하면 이미지 다운로드에 소요되는 시간을 줄이고 외부 종속성도 줄일 수 있습니다. 컨테이너 실행의 중첩 방식 때문에 CodeClimate의 후속 `docker pull` 명령을 개별 엔진에 전달할 레지스트리 접두사를 구성해야 합니다.

다음 변수는 필요한 모든 이미지 가져오기를 처리할 수 있습니다:

- `CODE_QUALITY_IMAGE`: 작업 환경에서 액세스할 수 있는 모든 위치에 있을 수 있는 완전히 접두사가 붙은 이미지 이름입니다. GitLab 컨테이너 레지스트리를 여기에 사용하여 자신의 복사본을 호스팅할 수 있습니다.
- `CODECLIMATE_PREFIX`: 의도한 컨테이너 이미지 레지스트리의 도메인입니다. 이는 [CodeClimate CLI](https://github.com/codeclimate/codeclimate/pull/948)에서 지원하는 구성 옵션입니다. 다음을 수행해야 합니다:
  - 후행 슬래시(`/`)를 포함합니다.
  - `https://`과(와) 같은 프로토콜 접두사를 포함하지 마세요.
- `CODECLIMATE_REGISTRY_USERNAME`: `CODECLIMATE_PREFIX`에서 구문 분석한 레지스트리 도메인의 사용자 이름을 지정하기 위한 선택적 변수입니다.
- `CODECLIMATE_REGISTRY_PASSWORD`: `CODECLIMATE_PREFIX`에서 구문 분석한 레지스트리 도메인의 암호를 지정하기 위한 선택적 변수입니다.

```yaml
include:
  - template: Jobs/Code-Quality.gitlab-ci.yml

code_quality:
  variables:
    CODE_QUALITY_IMAGE: "my-private-registry.local:12345/codequality:0.85.24"
    CODECLIMATE_PREFIX: "my-private-registry.local:12345/"
```

이 예제는 GitLab 코드 품질에만 적용됩니다. DinD를 레지스트리 미러로 구성하는 방법에 대한 자세한 지침은 [Docker-in-Docker 서비스에 대한 레지스트리 미러 활성화](../docker/using_docker_build.md#enable-registry-mirror-for-dockerdind-service)를 참조하세요.

#### 필수 이미지 {#required-images}

다음 이미지는 [기본 `.codeclimate.yml`](https://gitlab.com/gitlab-org/ci-cd/codequality/-/blob/master/codeclimate_defaults/.codeclimate.yml.template)에 필요합니다:

- `codeclimate/codeclimate-structure:latest`
- `codeclimate/codeclimate-csslint:latest`
- `codeclimate/codeclimate-coffeelint:latest`
- `codeclimate/codeclimate-duplication:latest`
- `codeclimate/codeclimate-eslint:latest`
- `codeclimate/codeclimate-fixme:latest`
- `codeclimate/codeclimate-rubocop:rubocop-0-92`

사용자 지정 `.codeclimate.yml` 구성 파일을 사용하는 경우 프라이빗 컨테이너 레지스트리에 지정된 플러그인을 추가해야 합니다.

## 러너 구성 변경 {#change-runner-configuration}

CodeClimate은 각 분석 단계에 대해 별도의 컨테이너를 실행합니다. CodeClimate 기반 스캔을 실행할 수 있도록 또는 더 빠르게 실행하도록 러너 구성을 조정해야 할 수 있습니다.

### 프라이빗 러너 사용 {#use-private-runners}

프라이빗 러너가 있으면 다음 이유로 코드 품질의 성능 향상을 위해 이 구성을 사용해야 합니다:

- 권한 있는 모드가 사용되지 않습니다.
- Docker-in-Docker가 사용되지 않습니다.
- Docker 이미지(모든 CodeClimate 이미지 포함)가 캐시되며 후속 작업을 위해 다시 가져오지 않습니다.

이 대체 구성은 소켓 바인딩을 사용하여 러너의 Docker 데몬을 작업 환경과 공유합니다. 이 구성을 구현하기 전에 [제한 사항](../docker/using_docker_build.md#use-docker-socket-binding)을 고려하세요.

프라이빗 러너를 사용하려면:

1. 새 러너를 등록하세요:

   ```shell
   $ gitlab-runner register --executor "docker" \
     --docker-image="docker:cli" \
     --url "https://gitlab.com/" \
     --description "cq-sans-dind" \
     --docker-volumes "/cache"\
     --docker-volumes "/builds:/builds"\
     --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
     --registration-token="<project_token>" \
     --non-interactive
   ```

1. **Optional, but recommended**: 빌드 디렉터리를 `/tmp/builds`로 설정하여 작업 아티팩트가 러너 호스트에서 주기적으로 삭제됩니다. 이 단계를 건너뛰면 기본 빌드 디렉터리(`/builds`)를 직접 정리해야 합니다. 이전 단계에서 `gitlab-runner register`에 다음 두 플래그를 추가하여 이를 수행할 수 있습니다.

   ```shell
   --builds-dir "/tmp/builds"
   --docker-volumes "/tmp/builds:/tmp/builds" # Use this instead of --docker-volumes "/builds:/builds"
   ```

   결과 구성:

   ```toml
   [[runners]]
     name = "cq-sans-dind"
     url = "https://gitlab.com/"
     token = "<project_token>"
     executor = "docker"
     builds_dir = "/tmp/builds"
     [runners.docker]
       tls_verify = false
       image = "docker:cli"
       privileged = false
       disable_entrypoint_overwrite = false
       oom_kill_disable = false
       disable_cache = false
       volumes = ["/cache", "/var/run/docker.sock:/var/run/docker.sock", "/tmp/builds:/tmp/builds"]
       shm_size = 0
     [runners.cache]
       [runners.cache.s3]
       [runners.cache.gcs]
   ```

1. 템플릿에서 만든 `code_quality` 작업에 두 가지 재정의를 적용하세요:

   ```yaml
   include:
     - template: Jobs/Code-Quality.gitlab-ci.yml

   code_quality:
     services:            # Shut off Docker-in-Docker
     tags:
       - cq-sans-dind     # Set this job to only run on our new specialized runner
   ```

코드 품질은 이제 표준 Docker 모드에서 실행됩니다.

### 프라이빗 러너로 CodeClimate 루트리스 실행 {#run-codeclimate-rootless-with-private-runners}

프라이빗 러너를 사용하고 있고 코드 품질 스캔을 [루트리스 Docker 모드](https://docs.docker.com/engine/security/rootless/)에서 실행하려면 코드 품질이 제대로 실행되도록 일부 특수한 변경 사항이 필요합니다. 소켓 바인딩의 변경 사항이 다른 작업에서 문제를 일으킬 수 있으므로 코드 품질 작업만 실행하는 전용 러너가 필요할 수 있습니다.

루트리스 프라이빗 러너를 사용하려면:

1. 새 러너를 등록하세요:

   `/run/user/<gitlab-runner-user>/docker.sock`을(를) `gitlab-runner` 사용자의 로컬 `docker.sock`의 경로로 바꾸세요.

   ```shell
   $ gitlab-runner register --executor "docker" \
     --docker-image="docker:cli" \
     --url "https://gitlab.com/" \
     --description "cq-rootless" \
     --tag-list "cq-rootless" \
     --locked="false" \
     --access-level="not_protected" \
     --docker-volumes "/cache" \
     --docker-volumes "/tmp/builds:/tmp/builds" \
     --docker-volumes "/run/user/<gitlab-runner-user>/docker.sock:/run/user/<gitlab-runner-user>/docker.sock" \
     --token "<project_token>" \
     --non-interactive \
     --builds-dir "/tmp/builds" \
     --env "DOCKER_HOST=unix:///run/user/<gitlab-runner-user>/docker.sock" \
     --docker-host "unix:///run/user/<gitlab-runner-user>/docker.sock"
   ```

   결과 구성:

   ```toml
   [[runners]]
     name = "cq-rootless"
     url = "https://gitlab.com/"
     token = "<project_token>"
     executor = "docker"
     builds_dir = "/tmp/builds"
     environment = ["DOCKER_HOST=unix:///run/user/<gitlab-runner-user>/docker.sock"]
     [runners.docker]
       tls_verify = false
       image = "docker:cli"
       privileged = false
       disable_entrypoint_overwrite = false
       oom_kill_disable = false
       disable_cache = false
       volumes = ["/cache", "/run/user/<gitlab-runner-user>/docker.sock:/run/user/<gitlab-runner-user>/docker.sock", "/tmp/builds:/tmp/builds"]
       shm_size = 0
       host = "unix:///run/user/<gitlab-runner-user>/docker.sock"
     [runners.cache]
       [runners.cache.s3]
       [runners.cache.gcs]
   ```

1. 템플릿에서 만든 `code_quality` 작업에 다음 재정의를 적용하세요:

   ```yaml
   code_quality:
     services:
     variables:
       DOCKER_SOCKET_PATH: /run/user/997/docker.sock
     tags:
       - cq-rootless
   ```

코드 품질은 이제 표준 Docker 모드와 루트리스에서 실행됩니다.

코드 품질로 [루트리스 Podman을 사용하여 Docker를 실행](https://docs.gitlab.com/runner/executors/docker/#use-podman-to-run-docker-commands)하려는 경우 동일한 구성이 필요합니다. `/run/user/<gitlab-runner-user>/docker.sock`를 시스템의 올바른 `podman.sock` 경로(예: `/run/user/<gitlab-runner-user>/podman/podman.sock`)로 바꾸세요.

### Kubernetes 또는 OpenShift 러너 구성 {#configure-kubernetes-or-openshift-runners}

코드 품질을 사용하려면 Docker 컨테이너에서 Docker를 설정해야 합니다(Docker-in-Docker). Kubernetes 실행기는 [Docker-in-Docker를 지원합니다](https://docs.gitlab.com/runner/executors/kubernetes/#using-dockerdind).

코드 품질 작업이 Kubernetes 실행기에서 실행될 수 있도록 하려면:

- TLS를 사용하여 Docker 데몬과 통신하는 경우 실행기는 [권한 있는 모드에서 실행](https://docs.gitlab.com/runner/executors/kubernetes/#other-configtoml-settings)되어야 합니다. 또한 인증서 디렉터리를 [볼륨 마운트로 지정](../docker/using_docker_build.md#docker-in-docker-with-tls-enabled-in-kubernetes)해야 합니다.
- DinD 서비스가 코드 품질 작업이 시작되기 전에 완전히 시작되지 않을 수 있습니다. 이는 [Kubernetes 실행기 문제 해결](https://docs.gitlab.com/runner/executors/kubernetes/troubleshooting/#docker-cannot-connect-to-the-docker-daemon-at-tcpdocker2375-is-the-docker-daemon-running)에 설명된 제한 사항입니다. 이슈를 해결하려면 `before_script`을(를) 사용하여 Docker 데몬이 완전히 부팅될 때까지 기다리세요. 예제는 다음 섹션에서 설명하는 `.gitlab-ci.yml` 파일의 구성을 참조하세요.

#### Kubernetes {#kubernetes}

Kubernetes에서 코드 품질을 실행하려면:

- Docker in Docker 서비스를 `config.toml` 파일의 서비스 컨테이너로 추가해야 합니다.
- 서비스 컨테이너의 Docker 데몬은 TCP 및 UNIX 소켓을 수신해야 하며, 두 소켓 모두 코드 품질에 필요합니다.
- Docker 소켓은 볼륨과 공유되어야 합니다.

[Docker 요구사항](https://docs.docker.com/reference/cli/docker/container/run/#privileged) 때문에 서비스 컨테이너에 대해 권한 있는 플래그를 활성화해야 합니다.

```toml
[runners.kubernetes]

[runners.kubernetes.service_container_security_context]
privileged = true
allow_privilege_escalation = true

[runners.kubernetes.volumes]

[[runners.kubernetes.volumes.empty_dir]]
mount_path = "/var/run/"
name = "docker-sock"

[[runners.kubernetes.services]]
alias = "dind"
command = [
    "--host=tcp://0.0.0.0:2375",
    "--host=unix://var/run/docker.sock",
    "--storage-driver=overlay2"
]
entrypoint = ["dockerd"]
name = "docker:29.1.4-dind"
```

> [!note]
> [GitLab Runner Helm Chart](https://docs.gitlab.com/runner/install/kubernetes/)를 사용하면 `values.yaml` 파일의 [`config` 필드](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration/)에서 이전 Kubernetes 구성을 사용할 수 있습니다.

`overlay2` [스토리지 드라이버](https://docs.docker.com/storage/storagedriver/select-storage-driver/)를 사용하는지 확인하세요. 이는 최고의 전체 성능을 제공합니다:

- Docker CLI가 통신하는 `DOCKER_HOST`을(를) 지정하세요.
- `DOCKER_DRIVER` 변수를 비워 두도록 설정하세요.

`before_script` 섹션을 사용하여 Docker 데몬이 완전히 부팅될 때까지 기다리세요. GitLab Runner v16.9 이후로는 [`HEALTHCHECK_TCP_PORT` 변수를 설정하기만](https://docs.gitlab.com/runner/executors/kubernetes/#define-a-list-of-services) 해도 됩니다.

```yaml
include:
  - template: Code-Quality.gitlab-ci.yml

code_quality:
  services: []
  variables:
    DOCKER_HOST: tcp://dind:2375
    DOCKER_DRIVER: ""
  before_script:
    - while ! docker info > /dev/null 2>&1; do sleep 1; done
```

#### OpenShift {#openshift}

OpenShift의 경우 [GitLab Runner Operator](https://docs.gitlab.com/runner/install/operator/)를 사용해야 합니다. 서비스 컨테이너의 Docker 데몬이 스토리지를 초기화할 권한을 얻도록 하려면 `/var/lib` 디렉터리를 볼륨 마운트로 마운트해야 합니다.

> [!note]
> `/var/lib` 디렉터리를 볼륨 마운트로 마운트할 수 없으면 `--storage-driver`을(를) `vfs`로 설정할 수 있습니다. `vfs` 값을 선택하면 [성능](https://docs.docker.com/storage/storagedriver/select-storage-driver/)에 부정적인 영향을 미칠 수 있습니다.

Docker 데몬의 권한을 구성하려면:

1. 이 구성 템플릿을 사용하여 `config.toml` 파일을 만들어 러너의 구성을 사용자 정의하세요:

```toml
[[runners]]

[runners.kubernetes]

[runners.kubernetes.service_container_security_context]
privileged = true
allow_privilege_escalation = true

[runners.kubernetes.volumes]

[[runners.kubernetes.volumes.empty_dir]]
mount_path = "/var/run/"
name = "docker-sock"

[[runners.kubernetes.volumes.empty_dir]]
mount_path = "/var/lib/"
name = "docker-data"

[[runners.kubernetes.services]]
alias = "dind"
command = [
    "--host=tcp://0.0.0.0:2375",
    "--host=unix://var/run/docker.sock",
    "--storage-driver=overlay2"
]
entrypoint = ["dockerd"]
name = "docker:29.1.4-dind"
```

1. [러너에 사용자 정의 구성을 설정하세요](https://docs.gitlab.com/runner/configuration/configuring_runner_operator/#customize-configtoml-with-a-configuration-template).
1. 선택 사항. 빌드 Pod에 [`privileged` 서비스 계정](https://docs.openshift.com/container-platform/3.11/admin_guide/manage_scc.html)을 연결하세요. 이는 OpenShift 클러스터 설정에 따라 달라집니다:

   ```shell
   oc create sa dind-sa
   oc adm policy add-scc-to-user anyuid -z dind-sa
   oc adm policy add-scc-to-user -z dind-sa privileged
   ```

1. [`[runners.kubernetes]` 섹션](https://docs.gitlab.com/runner/executors/kubernetes/#other-configtoml-settings)에서 권한을 설정하세요.
1. 작업 정의는 Kubernetes 경우와 동일하게 유지됩니다:

   ```yaml
   include:
   - template: Code-Quality.gitlab-ci.yml

   code_quality:
   services: []
   variables:
     DOCKER_HOST: tcp://dind:2375
     DOCKER_DRIVER: ""
   before_script:
     - while ! docker info > /dev/null 2>&1; do sleep 1; done
   ```

#### 볼륨 및 Docker 스토리지 {#volumes-and-docker-storage}

Docker는 모든 데이터를 `/var/lib` 볼륨에 저장하므로 큰 볼륨이 될 수 있습니다. Docker-in-Docker 스토리지를 클러스터 전체에서 다시 사용하려면 [영구 볼륨](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)을 대신 사용할 수 있습니다.
<!--- end_remove -->
