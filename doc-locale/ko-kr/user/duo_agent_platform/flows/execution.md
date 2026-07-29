---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 플로우 실행 구성
---

{{< history >}}

- [GitLab 18.3에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/477166).

{{< /history >}}

플로우는 에이전트를 사용하여 작업을 실행합니다.

- GitLab UI에서 실행된 플로우는 CI/CD를 사용합니다.
- IDE에서 실행된 플로우는 로컬로 실행됩니다.

플로우가 CI/CD를 사용하여 실행되는 환경을 구성할 수 있습니다. [자신의 러너를 사용](#configure-runners-to-execute-flows)하거나 [작업에서 변수를 지정](execution_variables.md)하도록 선택할 수 있습니다.

## 플로우 보안 {#flow-security}

플로우가 GitLab CI/CD에서 실행될 때:

- 이들은 [복합 ID](../composite_identity.md)를 사용하여 액세스를 제한합니다.
- 임시 [워크로드 파이프라인](../../../ci/pipelines/pipeline_types.md#workload-pipeline)을 생성하며, 플로우가 완료되면 제거됩니다.
- 사용 가능한 도구는 플로우의 목적에 따라 지정됩니다. 이러한 도구는 머지 리퀘스트 생성 또는 실행 환경에서 로컬 셸 명령 실행을 포함할 수 있습니다.

기본적으로 플로우는 GitLab 인스턴스에 대한 네트워크 액세스만 가능합니다. 네트워크 액세스 규칙에 대한 자세한 내용은 [네트워크 정책을 구성하는 방법](../environment_sandbox.md#configure-a-network-policy)을 참조하세요. 이 별도의 환경은 셸 명령 실행의 의도하지 않은 결과로부터 보호합니다.

GitLab UI에서 플로우가 자동으로 실행되지 않도록 하려면 [플로우 실행을 끌 수 있습니다](foundational_flows/_index.md#turn-foundational-flows-on-or-off).

### `agent-config.yml`의 보안 영향 {#security-implications-of-agent-configyml}

`.gitlab/duo/agent-config.yml` 파일은 플로우가 CI/CD에서 실행되는 방식을 제어하며, `setup_script`에서 실행되는 명령을 포함합니다. 플로우 실행 방식으로 인해 이 파일의 변경 사항은 커밋한 사용자보다 더 많은 영향을 미칩니다.

#### 교차 사용자 실행 {#cross-user-execution}

플로우는 [복합 ID](../composite_identity.md)를 통해 플로우를 트리거하는 사용자의 ID로 실행됩니다. `setup_script`의 명령은 트리거하는 사용자의 복합 ID 자격증명으로 실행되며, 구성을 커밋한 사용자의 자격증명이 아닙니다.

`.gitlab/duo/agent-config.yml`에 대한 쓰기 액세스 권한이 있는 사용자는 다른 사용자의 러너 환경에서 실행되는 작업에 영향을 줄 수 있습니다. 이 파일에 대한 수정 사항은 나중에 프로젝트에서 플로우를 트리거하는 모든 사용자의 실행 컨텍스트에 영향을 미칩니다.

#### 노출된 환경 변수 {#exposed-environment-variables}

`setup_script` 실행 중(Anthropic Sandbox Runtime(SRT) 외부에서 실행됨) 다음의 민감한 변수가 환경에 있습니다:

- `GITLAB_OAUTH_TOKEN` 및 `GITLAB_TOKEN`: 복합 ID를 통한 트리거하는 사용자의 OAuth 토큰입니다.
- `DUO_WORKFLOW_GIT_HTTP_PASSWORD`: Git HTTP 암호입니다.
- `DUO_WORKFLOW_SERVICE_TOKEN`: 서비스 토큰입니다.
- `DUO_WORKFLOW_GIT_USER_EMAIL` 및 `DUO_WORKFLOW_GIT_USER_NAME`: 트리거하는 사용자의 이메일 및 이름입니다.

노출된 변수의 전체 목록은 [플로우 실행 변수](execution_variables.md)를 참조하세요.

#### 권장되는 보호 {#recommended-protections}

`.gitlab/duo/agent-config.yml` 파일에 대한 무단 변경 위험을 줄이려면:

- [기본 브랜치 보호](../../../user/project/repository/branches/protected.md)를 통해 직접 푸시를 방지합니다.
- [코드 소유자](../../../user/project/codeowners/_index.md)를 사용하여 `.gitlab/duo/agent-config.yml`에 대한 변경 사항을 병합하기 전에 특정 소유자의 승인을 요구합니다. 예를 들어 `CODEOWNERS` 파일에 다음을 추가합니다:

  ```plaintext
  .gitlab/duo/agent-config.yml @your-group/security-reviewers
  ```

- [승인 규칙](../../../user/project/merge_requests/approvals/rules.md)을 구성하여 이 파일을 수정하는 머지 리퀘스트에 대해 신뢰할 수 있는 관리자의 리뷰를 요구합니다.

## 실행기 아키텍처 {#executor-architecture}

플로우가 CI/CD에서 실행될 때 러너는:

1. npm 레지스트리에서 `@gitlab/duo-cli` 패키지를 다운로드합니다.
1. GitLab Duo CLI를 실행하며, WebSocket을 사용하여 GitLab Duo 워크플로우 서비스에 연결합니다.
1. AI 모델의 지시에 따라 도구(파일 작업, Git 명령)를 실행합니다.

실행기 버전은 GitLab에서 관리하며 정기적인 릴리스의 일부로 업데이트됩니다.

## CI/CD 실행 구성 {#configure-cicd-execution}

플로우가 CI/CD에서 실행되는 방식을 사용자 지정하려면 프로젝트에서 에이전트 구성 파일을 생성합니다.

지원되는 키 및 해당 유형의 목록을 보려면 [`agent-config.yml` 참조](agent_config_yml.md)를 참조하세요.

> [!note]
> 이 시나리오에서 사전 정의된 CI/CD 변수를 사용할 수 없습니다. [사용 가능한 변수의 목록](execution_variables.md#available-variables)을 참조하세요.

## 구성 파일 생성 {#create-the-configuration-file}

1. 프로젝트의 리포지토리에서 `.gitlab/duo/` 폴더를 생성합니다(없는 경우).
1. 폴더에서 `agent-config.yml`이라는 구성 파일을 생성합니다.
1. 필요한 구성 옵션을 추가합니다(아래 섹션 참조).
1. 파일을 기본 브랜치에 커밋하고 푸시합니다.

플로우가 프로젝트에 대해 CI/CD에서 실행될 때 구성이 적용됩니다.

> [!note]
> 구성 파일은 프로젝트의 기본 브랜치에서만 읽습니다. 다른 브랜치에 커밋된 파일은 무시되며, 해당 브랜치에서 플로우가 실행되는 경우에도 마찬가지입니다.

### 기본 Docker 이미지 변경 {#change-the-default-docker-image}

기본적으로 CI/CD를 사용하여 실행된 모든 플로우는 GitLab에서 제공하는 표준 Docker 이미지를 사용합니다. 이 Docker 이미지는 [Anthropic Sandbox Runtime(`srt`)](https://github.com/anthropic-experimental/sandbox-runtime)을 사용하여 네트워크 보호를 자동으로 포함합니다.

Docker 이미지를 변경하고 대신 자신의 이미지를 지정할 수 있습니다. 자신의 이미지는 특정 종속성 또는 도구를 필요로 하는 복잡한 프로젝트에 유용할 수 있습니다. 이미지에서 네트워크 보호를 사용하려면 `srt`을 Docker 이미지에 추가합니다(선호하는 버전 포함):

```Docker
# Install srt sandboxing with cache clearing and verification
ARG SANDBOX_RUNTIME_VERSION=0.0.20
RUN npm cache clean --force && \
    npm install -g @anthropic-ai/sandbox-runtime@${SANDBOX_RUNTIME_VERSION} && \
    test -s "$(npm root -g)/@anthropic-ai/sandbox-runtime/package.json" && \
    srt --version
```

SRT 및 사용자 지정 이미지에 설치하는 방법에 대한 자세한 내용은 [원격 실행 환경 샌드박스](../environment_sandbox.md)를 참조하세요.

기본 Docker 이미지를 변경하려면 `agent-config.yml` 파일에 다음 구성을 추가합니다:

```yaml
image: YOUR_DOCKER_IMAGE
```

예를 들어:

```yaml
image: python:3.11-slim
```

또는 Node.js 프로젝트의 경우:

```yaml
image: node:20-alpine
```

#### 강화된 UBI 9 최소 이미지 {#hardened-ubi-9-minimal-image}

{{< history >}}

- GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/-/merge_requests/12)되었습니다.

{{< /history >}}

GitLab은 Red Hat Universal Base Image(UBI) 9 최소를 기반으로 하는 강화된 최소 이미지 변형도 제공합니다. 이 이미지는 네트워크 제한, FedRAMP 스타일 또는 더 작은 공격 표면, root가 아닌 실행 및 Red Hat UBI 기반이 필요한 보안에 민감한 환경을 위해 설계되었습니다.

강화된 이미지는 다음에 발행됩니다: `registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened`

`linux/amd64` 및 `linux/arm64` 모두를 위해 빌드되며, 기본 이미지와 동일한 태그 체계를 사용합니다:

- 빌드당 `:<short-sha>`
- 릴리스당 `:<git-tag>`

##### 강화된 이미지 사용 {#use-the-hardened-image}

전제 조건:

- GitLab 18.10 이상

강화된 이미지를 사용하려면 `agent-config.yml`에서 설정합니다:

```yaml
image: registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened:<tag>
```

##### 이미지 내용 {#image-contents}

| 구성 요소           | 버전                           |
|---------------------|-----------------------------------|
| 기본 이미지          | Red Hat UBI 9 최소             |
| `git`               | UBI 9 표준                       |
| `git-lfs`           | UBI 9 표준                       |
| Node.js             | 20(UBI 9 모듈 스트림)          |
| `npm`               | Node.js 20과 함께 번들로 제공           |
| `@gitlab/duo-cli`   | 사전 설치됨                     |
| `glab`(GitLab CLI) | 사전 설치됨                     |
| 런타임 사용자        | root가 아닌 사용자, UID 1001(`duo-runner`) |

이미지는 `@gitlab/duo-cli` 및 `glab`을 포함하므로 `registry.npmjs.org` 또는 `registry.gitlab.com`에 대한 아웃바운드 액세스가 플로우 실행 시간에 필요하지 않습니다.

##### 추가 패키지로 이미지 확장 {#extend-the-image-with-additional-packages}

강화된 이미지는 UID 1001(`duo-runner`)로 실행됩니다. `setup_script`의 `agent-config.yml`도 이 root가 아닌 사용자로 실행되므로 `microdnf`로 시스템 패키지를 설치할 수 없습니다.

언어 런타임 또는 시스템 패키지를 추가하려면:

1. 자신의 `FROM` 계층으로 이미지를 확장합니다:

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened:<tag>

   USER root
   RUN microdnf install -y python3.12 python3.12-pip && microdnf clean all
   USER 1001
   ```

1. `setup_script`을 사용하여 root 액세스가 필요하지 않은 프로젝트 종속성을 추가합니다. 예를 들어 `pip install --user` 또는 `npm install`입니다.

##### 강화된 이미지를 언제 사용할 것인가 {#when-to-use-the-hardened-image}

환경에서 다음을 필요로 할 때 강화된 이미지를 사용합니다:

- Red Hat UBI 기본 이미지입니다. 예를 들어 FedRAMP 또는 엔터프라이즈 규정 준수의 경우입니다.
- 기본적으로 root가 아닌 컨테이너 실행입니다.
- Agent Platform 자체에 필요한 것 이외에 언어 런타임이 없는 최소 공격 표면입니다.
- 플로우 실행 시간에 아웃바운드 인터넷 액세스가 없습니다(모든 Agent Platform 종속성이 사전 설치되어 있음).

연결된 환경에서 여러 언어 런타임을 바로 사용할 수 있는 범용 플로우에는 [기본 이미지](#change-the-default-docker-image)를 사용합니다.

#### 사용자 지정 이미지 요구 사항 {#custom-image-requirements}

사용자 지정 Docker 이미지를 사용하는 경우 다음 명령이 에이전트가 올바르게 작동하도록 사용 가능한지 확인합니다:

- `git`
- `npm`과 `@gitlab/duo-cli`호환되는 Node.js 버전입니다. 자세한 내용은 [GitLab Duo CLI 필수 조건](../../gitlab_duo_cli/_index.md#install)을 참조하세요.

대부분의 기본 이미지는 기본적으로 이러한 명령을 포함합니다. 그러나 최소 이미지(`alpine` 변형 등)는 명시적으로 설치해야 할 수 있습니다. 필요한 경우 [설정 스크립트 구성](#configure-setup-scripts)에서 누락된 명령을 설치할 수 있습니다.

> [!note]
> GitLab 18.9 이하에서는 [알려진 문제(587996)](https://gitlab.com/gitlab-org/gitlab/-/work_items/587996)가 있어 사용자 지정 이미지에서 `git`의 최신 버전에서 플로우가 실패할 수 있습니다. 이 문제는 `@gitlab/duo-cli` 버전 8.71.0에서 해결됩니다.
>
> `@gitlab/duo-cli` 버전 8.71.0 이하에 있으면 새로운 Git 버전으로 플로우가 실패하지 않도록 하기 위해 다음 중 하나를 수행할 수 있습니다:
>
> - 사용자 지정 이미지에서 Git 버전 `2.43.7` 이상을 사용합니다
> - `@gitlab/duo-cli` 버전 8.71.0을 사용합니다.

또한 플로우 실행 중에 에이전트가 수행하는 도구 호출에 따라 다른 일반적인 유틸리티가 필요할 수 있습니다.

예를 들어 Alpine 기반 이미지를 사용하는 경우:

```yaml
image: python:3.11-alpine
setup_script:
  - apk add --update git nodejs npm
```

#### 보안 및 성능 {#security-and-performance}

사용자 지정 Docker 이미지를 사용할 때 Anthropic Sandbox Runtime(SRT)이 사용자 지정 이미지에 포함되어 있을 때만 [환경 샌드박스](../environment_sandbox.md)가 적용됩니다. SRT가 포함되지 않으면 플로우는 러너에서 도달 가능한 모든 도메인 및 전체 파일 시스템에 액세스할 수 있습니다.

사용자 지정 이미지로 네트워크 격리가 필요하면 [이미지에 SRT를 설치](../environment_sandbox.md#install-anthropic-sandbox-runtime-srt-on-a-custom-image)하고 [네트워크 정책을 구성](../environment_sandbox.md#configure-a-network-policy)하거나 러너에서 네트워크 수준 컨트롤(예: 방화벽 규칙 또는 네트워크 정책)을 구성합니다.

작업 시작 시간을 약 15-20초 줄이려면 `@gitlab/duo-cli` npm 패키지 및 `glab` CLI를 사용자 지정 이미지에 포함합니다. 강화된 이미지는 두 도구를 모두 사전 설치합니다.

### 설정 스크립트 구성 {#configure-setup-scripts}

플로우 실행 전에 실행할 설정 스크립트를 정의할 수 있습니다. 이는 종속성 설치, 환경 구성 또는 필요한 초기화를 수행하는 데 유용합니다.

설정 스크립트를 추가하려면 `agent-config.yml` 파일에 다음 명령을 추가합니다:

```yaml
setup_script:
  - apt-get update && apt-get install -y curl
  - pip install -r requirements.txt
  - echo "Setup complete"
```

이 명령은 다음 작업을 완료합니다:

- 주 워크플로우 명령 전에 실행합니다.
- 지정된 순서대로 실행합니다.
- 단일 명령 또는 명령 배열일 수 있습니다.

`setup_script`의 사용자 컨텍스트는 Docker 이미지에 따라 다릅니다. 기본 GitLab 이미지는 `root`로 실행됩니다. 사용자 지정 이미지는 이미지의 `USER` 지시문에서 정의한 사용자로 실행됩니다. `setup_script`에 root 액세스가 필요한 경우(예: 시스템 패키지를 설치하려면) 사용자 지정 이미지가 그에 따라 구성되어 있는지 확인합니다.

> [!warning]
> `setup_script` 명령은 SRT가 적용되기 전에 실행되며 그 외부에서 실행됩니다. 이 명령은 플로우의 모든 환경 변수에 액세스할 수 있으며, 트리거하는 사용자의 OAuth 토큰, 서비스 토큰 및 ID 세부 정보를 포함합니다. 보안 모델 및 권장 보호에 대해서는 [`agent-config.yml`의 보안 영향](#security-implications-of-agent-configyml)을 참조하세요.

### 오프라인 환경에서 사용자 지정 이미지 사용 {#use-a-custom-image-in-an-offline-environment}

러너가 외부 레지스트리에 도달할 수 없는 오프라인 환경에서 `@gitlab/duo-cli`을 포함하는 사용자 지정 실행기 이미지를 사전 구축할 수 있습니다. GitLab Duo CLI가 이미 이미지에 있으면 플로우 시작은 npm 다운로드 단계를 건너뜁니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.
- GitLab 18.9 이상입니다.
- 이미지를 빌드하고 아티팩트를 다운로드할 온라인 머신에 대한 액세스입니다.

오프라인 환경에 대해 플로우를 구성하려면:

1. 온라인 머신에서 GitLab Duo CLI를 사용하여 사용자 지정 이미지를 빌드합니다:

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:v0.0.6
   RUN npm install -g @gitlab/duo-cli@8.86.0
   ```

   또는 npm을 완전히 피하려면 [GitLab 패키지 레지스트리](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/packages)에서 독립형 이진 파일을 다운로드합니다:

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:v0.0.6
   COPY duo-linux-x64 /usr/bin/duo
   RUN chmod +x /usr/bin/duo
   ```

   독립형 이진 파일을 다운로드하려면 다음 명령을 실행합니다:

   ```shell
   curl --location "https://gitlab.com/api/v4/projects/46519181/packages/generic/duo-cli/8.86.0/duo-linux-x64" \
     --output duo-linux-x64
   ```

1. 이미지를 오프라인 환경으로 전송합니다. 예를 들어 Docker를 사용하여 다음 명령을 실행합니다:

   ```shell
   # On an online machine
   docker save my-duo-executor:latest -o duo-executor.tar

   # Transfer `duo-executor.tar` to the offline environment

   # On an offline machine
   docker load -i duo-executor.tar
   ```

1. 이미지를 내부 컨테이너 레지스트리로 푸시합니다.
1. 사용자 지정 이미지 레지스트리 설정:
   1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
   1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
   1. **구성 변경**을 선택합니다.
   1. **이미지 레지스트리** 텍스트 상자에 내부 레지스트리 URL을 입력합니다(예: `registry.internal.example.com`).
1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 사용자 지정 이미지를 사용하려면 `agent-config.yml` 파일을 업데이트합니다:

   ```yaml
   image: registry.internal.example.com/duo-executor:latest
   ```

### 캐싱 구성 {#configure-caching}

캐싱을 구성하여 후속 플로우 실행을 빠르게 하려면 `agent-config.yml` 파일을 구성하여 실행 간에 파일 및 디렉터리를 유지합니다. 캐싱은 `node_modules` 또는 Python 가상 환경과 같은 종속성 폴더에 유용할 수 있습니다.

#### 기본 캐시 구성 {#basic-cache-configuration}

특정 경로를 캐시하려면 `agent-config.yml` 파일에 다음을 추가합니다:

```yaml
cache:
  paths:
    - node_modules/
    - .npm/
```

#### 키를 포함한 캐시 {#cache-with-keys}

캐시 키를 사용하여 다양한 시나리오에 대해 다양한 캐시를 생성할 수 있습니다. 캐시 키는 캐시가 프로젝트의 상태를 기반으로 하도록 합니다.

##### 문자열 키 사용 {#use-a-string-key}

```yaml
cache:
  key: my-project-cache
  paths:
    - vendor/
    - .bundle/
```

##### 파일 기반 캐시 키 사용 {#use-file-based-cache-keys}

파일 내용(잠금 파일 등)을 기반으로 동적 캐시 키를 생성합니다. 이 파일이 변경되면 새 캐시가 생성됩니다. 이는 지정된 파일의 SHA 체크섬을 생성합니다:

```yaml
cache:
  key:
    files:
      - package-lock.json
      - yarn.lock
  paths:
    - node_modules/
```

##### 파일 기반 키로 접두사 사용 {#use-a-prefix-with-file-based-keys}

캐시 키 파일에 대해 계산된 SHA와 접두사를 결합합니다:

```yaml
cache:
  key:
    files:
      - package-lock.json
    prefix: $CI_JOB_NAME
  paths:
    - node_modules/
    - .npm/
```

이 예제에서 작업 이름이 `test`이고 SHA 체크섬이 `abc123`이면 캐시 키가 `test-abc123`이 됩니다.

#### 캐시 제한 {#cache-limitations}

- 캐시 키 생성을 위해 최대 두 개의 파일을 지정할 수 있습니다. 더 많은 파일을 지정하면 처음 두 개만 사용됩니다.
- 캐시 `paths` 필드는 필수입니다. 경로 없는 캐시 구성은 효과가 없습니다.
- 캐시 키는 `prefix` 필드의 CI/CD 변수를 지원합니다.

### ID 토큰 구성 {#configure-id-tokens}

{{< history >}}

- [GitLab 19.2에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224940).

{{< /history >}}

플로우에서 타사 서비스를 인증하려면 [ID 토큰](../../../ci/secrets/id_token_authentication.md)을 구성합니다.

ID 토큰은 GitLab CI/CD가 생성하고 장기 자격증명을 저장하지 않고 키 없는 OpenID Connect(OIDC) 인증을 위해 플로우를 실행하는 작업에 주입하는 JSON 웹 토큰(JWT)입니다. 예를 들어 ID 토큰을 사용하여 시크릿 관리자에서 시크릿을 검색하거나 바이너리 및 Git 커밋에 서명할 수 있습니다.

ID 토큰을 구성하려면 `agent-config.yml` 파일에 `id_tokens` 블록을 추가합니다. 각 토큰은 `aud`(대상) 클레임이 필요합니다:

```yaml
id_tokens:
  VAULT_ID_TOKEN:
    aud: https://vault.example.com

network_policy:
  allowed_domains:
    - vault.example.com
```

`aud` 클레임은 단일 문자열 또는 문자열 목록이 될 수 있습니다:

```yaml
id_tokens:
  MY_ID_TOKEN:
    aud:
      - https://first.service.example.com
      - https://second.service.example.com

network_policy:
  allowed_domains:
    - first.service.example.com
    - second.service.example.com
```

각 토큰은 토큰의 이름을 사용하는 환경 변수로 플로우 작업에서 사용 가능합니다. 이전 예제의 경우 플로우에서 `$VAULT_ID_TOKEN` 및 `$MY_ID_TOKEN`를 사용할 수 있습니다.

토큰 이름이 구성의 다른 곳에서 선언된 변수 이름과 일치하면 ID 토큰이 우선합니다.

> [!warning]
> ID 토큰은 `aud` 클레임을 신뢰하는 모든 서비스에 액세스 권한을 부여하는 자격증명입니다. 손상된 토큰이 가능한 한 적은 서비스로 인증할 수 있도록 각 토큰에 대해 가능한 가장 좁은 `aud` 값을 설정합니다. 구성 파일이 기본 브랜치에서 읽히므로 [권장 보호](#recommended-protections)를 적용하여 플로우가 요청할 수 있는 토큰을 변경할 수 있는 사용자를 제어합니다.

토큰 페이로드 및 타사 서비스와의 신뢰를 구성하는 방법에 대한 자세한 내용은 [OpenID Connect(OIDC) 인증 사용(ID 토큰)](../../../ci/secrets/id_token_authentication.md)을 참조하세요.

### 완전한 구성 예제 {#complete-configuration-example}

사용 가능한 모든 옵션을 사용하는 예제 `agent-config.yml` 파일은 다음과 같습니다:

```yaml
# Custom Docker image
image: python:3.11

# Setup script to run before the flow
setup_script:
  - apt-get update && apt-get install -y build-essential
  - pip install --upgrade pip
  - pip install -r requirements.txt

# Cache configuration
cache:
  key:
    files:
      - requirements.txt
      - Pipfile.lock
    prefix: python-deps
  paths:
    - .cache/pip
    - venv/

# Network configuration
network_policy:
  include_recommended_allowed: true
  allow_all_unix_sockets: true
  allowed_domains:
    - vault.example.com
  denied_domains:
    - malicious.com

# ID tokens for OIDC authentication
id_tokens:
  VAULT_ID_TOKEN:
    aud: https://vault.example.com
```

이 구성:

- Python 3.11을 기본 이미지로 사용합니다.
- 플로우를 실행하기 전에 빌드 도구 및 Python 종속성을 설치합니다.
- pip 및 가상 환경 디렉터리를 캐시합니다.
- `requirements.txt` 또는 `Pipfile.lock`가 변경될 때 `python-deps`의 접두사로 새 캐시를 생성합니다.
- HashiCorp Vault로 OIDC 인증을 위한 `VAULT_ID_TOKEN` ID 토큰을 제공합니다.

## 플로우를 실행하도록 러너 구성 {#configure-runners-to-execute-flows}

CI/CD를 사용하는 플로우는 러너에서 실행됩니다.

GitLab.com에서 플로우는 GitLab이 제공하는 [호스팅된 러너](../../../ci/runners/hosted_runners/_index.md)를 사용할 수 있습니다. 이들은 기본적으로 활성화됩니다. 

플로우에 대해 자신의 러너를 구성하는 옵션도 있습니다.

> [!note]
> 최상위 그룹에 [IP 주소 제한](../../group/access_and_permissions.md#restrict-group-access-by-ip-address)이 활성화되어 있으면 호스팅된 러너를 플로우에 사용할 수 없습니다. 호스팅된 러너는 그룹의 IP 허용 목록에 추가할 수 없는 클라우드 공급자 풀의 동적 IP 주소를 사용합니다. 대신 최상위 그룹에서 자신의 그룹 러너를 구성합니다.

플로우에 대해 자신의 러너를 구성하려면:

1. [인스턴스 러너](../../../ci/runners/runners_scope.md)를 생성하거나 최상위 그룹에 할당된 그룹 러너를 생성합니다. 플로우가 프로젝트 러너 또는 하위 그룹에 할당된 그룹 러너를 사용하려면 `duo_runner_restrictions` 기능 플래그를 끕니다(GitLab Self-Managed만 해당).
1. `gitlab--duo` 태그를 러너에 추가하여 플로우에 대한 작업을 선택하도록 합니다. 러너에 이 태그가 없으면 플로우가 있는 작업은 무한정 대기 상태로 유지됩니다. 다음 방법 중 하나를 사용합니다:
   - 러너를 생성할 때 **태그** 필드에 `gitlab--duo`를 입력합니다.
   - 기존 러너의 경우 [러너가 실행할 수 있는 작업 편집](../../../ci/runners/configure_runners.md#control-jobs-that-a-runner-can-run)을 수행하고 **태그** 필드에 `gitlab--duo`를 입력합니다.
   - `config.toml` 파일로 러너를 구성하면 `[[runners]]` 섹션에 태그를 추가합니다:

     <!-- markdownlint-disable MD044 -->
     ```toml
     [[runners]]
       executor = "docker"
       tags = ["gitlab--duo"]
     ```
     <!-- markdownlint-enable MD044 -->

1. 러너를 구성하여 Docker 이미지를 지원하는 [실행기](https://docs.gitlab.com/runner/executors/)(예: `docker`, `docker-autoscaler` 또는 `kubernetes`)를 사용합니다. `shell` 실행기는 지원되지 않습니다.
1. 최상위 그룹이 [IP 주소 제한](../../group/access_and_permissions.md#restrict-group-access-by-ip-address)을 켰으면 러너의 IP 주소를 그룹의 IP 허용 목록에 추가하여 러너가 그룹에 액세스할 수 있도록 합니다.
1. GitLab Self-Managed만 해당입니다. 러너가 플로우에 필요한 서비스에 도달할 수 있는지 확인합니다:
   - [GitLab 인스턴스에서 아웃바운드 연결 허용](../../../administration/gitlab_duo/configure/_index.md#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo)을 Agent Platform으로 수행합니다.
   - [러너에서 아웃바운드 연결 허용](../../../administration/gitlab_duo/configure/_index.md#allow-connections-from-the-runner)을 Agent Platform으로 수행합니다.
   - 인증서 체인의 자체 서명 인증서가 있는 인스턴스의 경우 [추가 GitLab Duo CLI 구성](../../gitlab_duo_cli/_index.md#custom-ssl-certificates)을 완료합니다.

### 실행 환경 샌드박스를 사용하여 플로우 보안 {#use-the-execution-environment-sandbox-to-secure-flows}

네트워크 및 파일 시스템 격리를 위해 [실행 환경 샌드박스](../environment_sandbox.md)를 사용하여 러너에서 실행된 플로우를 보안합니다.

샌드박스를 사용하려면 다음 이미지 중 하나를 사용해야 합니다:

- Agent Platform용 기본 Docker 기본 이미지
- A [SRT가 설치된 사용자 지정 이미지](../environment_sandbox.md#install-anthropic-sandbox-runtime-srt-on-a-custom-image)

샌드박스를 사용하도록 러너를 구성하려면 `privileged = true`을 [러너 구성](https://docs.gitlab.com/runner/configuration/advanced-configuration/)에서 설정합니다.

예를 들어:

<!-- markdownlint-disable MD044 -->
```toml
[[runners]]
  executor = "docker"
  tags = ["gitlab--duo"]
  [runners.docker]
    privileged = true
```
<!-- markdownlint-enable MD044 -->

다음 이미지로는 샌드박스를 사용할 수 없습니다:

- SRT가 설치되지 않은 사용자 지정 이미지
- 강화된 UBI 9 최소 이미지
