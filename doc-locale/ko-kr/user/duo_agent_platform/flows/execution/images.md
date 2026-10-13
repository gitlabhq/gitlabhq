---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 기본 Docker 이미지를 사용자 지정하거나 강화된 오프라인 이미지로 대체하여 CI/CD에서 GitLab Duo Agent Platform 플로우를 실행합니다.
title: 플로우 실행을 위한 이미지 구성
---

{{< details >}}

- 티어:  [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

CI/CD로 실행되는 플로우는 Docker 이미지 내에서 실행됩니다. 기본적으로 GitLab은 플로우에 필요한 도구와 네트워크 보호를 포함하는 이미지를 제공합니다. 기본 이미지를 사용자 지정하거나 강화된 이미지로 대체하여 프로젝트 종속성을 추가하거나 규정 준수 요구 사항을 충족하거나 오프라인 환경에서 플로우를 실행할 수 있습니다.

## 기본 Docker 이미지 변경 {#change-the-default-docker-image}

CI/CD로 실행되는 모든 플로우는 GitLab에서 제공하는 Docker 이미지를 사용합니다. 이 Docker 이미지는 [Anthropic Sandbox Runtime(`srt`)](https://github.com/anthropic-experimental/sandbox-runtime)을 사용하여 네트워크 보호를 자동으로 포함합니다.

특정 종속성이나 도구가 있는 복잡한 프로젝트가 있는 경우 Docker 이미지를 변경할 수 있습니다.

기본 Docker 이미지를 변경하려면 `agent-config.yml` 파일에 다음 구성을 추가합니다.

```yaml
image: YOUR_DOCKER_IMAGE
```

예를 들어:

{{< tabs >}}

{{< tab title="Python 프로젝트" >}}

```yaml
image: python:3.11-slim
```

{{< /tab >}}

{{< tab title="Node.js 프로젝트" >}}

```yaml
image: node:20-alpine
```

{{< /tab >}}

{{< /tabs >}}

### 네트워크 보호 추가 {#add-network-protection}

이미지에서 네트워크 보호를 사용하려면 `srt`을 Docker 이미지에 추가합니다(선호하는 버전 포함).

```Docker
# Install srt sandboxing with cache clearing and verification
ARG SANDBOX_RUNTIME_VERSION=0.0.63
RUN npm cache clean --force && \
    npm install -g @anthropic-ai/sandbox-runtime@${SANDBOX_RUNTIME_VERSION} && \
    test -s "$(npm root -g)/@anthropic-ai/sandbox-runtime/package.json" && \
    srt --version
```

SRT 및 사용자 지정 이미지에 설치하는 방법에 대한 자세한 내용은 [원격 실행 환경 샌드박스](../../environment_sandbox.md)를 참조하세요.

## 사용자 지정 이미지 사용 {#use-a-custom-image}

사용자 지정 Docker 이미지를 사용하는 경우 다음 명령이 에이전트가 올바르게 작동하도록 사용 가능한지 확인합니다.

- `git`
- `curl` - 플로우 시작 시 GitLab Duo CLI 바이너리를 다운로드합니다.

대부분의 기본 이미지는 기본적으로 이러한 명령을 포함합니다. 그러나 최소 이미지(`alpine` 변형 등)는 명시적으로 설치해야 할 수 있습니다. 필요한 경우 [설정 스크립트 구성](_index.md#configure-setup-scripts)에서 누락된 명령을 설치할 수 있습니다.

> [!note]
> GitLab 18.9 이하에서는 [알려진 문제(587996)](https://gitlab.com/gitlab-org/gitlab/-/work_items/587996)가 있어 사용자 지정 이미지에서 `git`의 최신 버전에서 플로우가 실패할 수 있습니다. 이 문제는 `@gitlab/duo-cli` 버전 8.71.0에서 해결됩니다.
>
> `@gitlab/duo-cli` 버전 8.71.0 이하에 있으면 새로운 Git 버전으로 플로우가 실패하지 않도록 하기 위해 다음 중 하나를 수행할 수 있습니다.
>
> - 사용자 지정 이미지에서 Git 버전 `2.43.7` 이상을 사용합니다
> - `@gitlab/duo-cli` 버전 8.71.0을 사용합니다.

또한 플로우 실행 중에 에이전트가 수행하는 도구 호출에 따라 다른 일반적인 유틸리티가 필요할 수 있습니다.

예를 들어 Alpine 기반 이미지를 사용하는 경우:

```yaml
image: python:3.11-alpine
setup_script:
  - apk add --update git curl
```

### 보안 및 성능 {#security-and-performance}

사용자 지정 Docker 이미지를 사용할 때 Anthropic Sandbox Runtime(SRT)이 사용자 지정 이미지에 포함되어 있을 때만 [환경 샌드박스](../../environment_sandbox.md)가 적용됩니다. SRT가 포함되지 않으면 플로우가 러너에서 도달 가능한 모든 도메인과 전체 파일 시스템에 액세스할 수 있습니다.

사용자 지정 이미지로 네트워크 격리가 필요하면 [이미지에 SRT를 설치](../../environment_sandbox.md#install-anthropic-sandbox-runtime-srt-on-a-custom-image)하고 [네트워크 정책을 구성](../../environment_sandbox.md#configure-a-network-policy)하거나 러너에서 네트워크 수준 컨트롤(예: 방화벽 규칙 또는 네트워크 정책)을 구성합니다.

작업 시작 시간을 약 15-20초 단축하려면 GitLab Duo CLI 바이너리와 `glab` CLI를 사용자 지정 이미지에 포함시킵니다. 강화된 이미지는 두 도구를 모두 사전 설치합니다.

## 오프라인 환경에서 사용자 지정 이미지 사용 {#use-a-custom-image-in-an-offline-environment}

러너가 외부 레지스트리에 도달할 수 없는 오프라인 환경에서는 GitLab Duo CLI를 포함하는 사용자 지정 실행기 이미지를 미리 빌드할 수 있습니다. GitLab Duo CLI가 이미 이미지에 있으면 플로우 시작 시 다운로드 단계를 건너뜁니다.

사전 요구 사항:

- 관리자 액세스 권한.
- GitLab 18.9 이상.
- 이미지를 빌드하고 아티팩트를 다운로드할 온라인 머신에 대한 액세스.

오프라인 환경에 대해 플로우를 구성하려면:

1. 온라인 머신에서 [GitLab 패키지 레지스트리](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/packages)에서 GitLab Duo CLI 바이너리를 다운로드합니다:

   ```shell
   curl --location "https://gitlab.com/api/v4/projects/46519181/packages/generic/duo-cli/9.8.0/duo-linux-x64" \
     --output duo-linux-x64
   ```

1. 바이너리를 포함하는 사용자 지정 이미지를 빌드합니다:

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:v0.0.6
   COPY duo-linux-x64 /usr/bin/duo
   RUN chmod +x /usr/bin/duo
   ```

1. 이미지를 오프라인 환경으로 전송합니다. 예를 들어 Docker를 사용하여 다음 명령을 실행합니다.

   ```shell
   # On an online machine
   docker save my-duo-executor:latest -o duo-executor.tar

   # Transfer `duo-executor.tar` to the offline environment

   # On an offline machine
   docker load -i duo-executor.tar
   ```

1. 이미지를 내부 컨테이너 레지스트리로 푸시합니다.
1. 사용자 지정 이미지 레지스트리 설정:
   1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
   1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
   1. **구성 변경**을 선택합니다.
   1. **이미지 레지스트리** 텍스트 상자에 내부 레지스트리 URL을 입력합니다(예: `registry.internal.example.com`).
1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 사용자 지정 이미지를 사용하려면 `agent-config.yml` 파일을 업데이트합니다.

   ```yaml
   image: registry.internal.example.com/duo-executor:latest
   ```

## Red Hat Universal Base Image 9 Minimal 사용 {#use-a-red-hat-universal-base-image-9-minimal}

{{< history >}}

- GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/-/merge_requests/12)되었습니다.

{{< /history >}}

GitLab은 Red Hat Universal Base Image(UBI) 9 Minimal을 기반으로 하는 강화되고 최소화된 이미지 변형을 제공합니다.

환경에서 다음을 필요로 할 때 강화된 이미지를 사용합니다.

- Red Hat UBI 기본 이미지입니다. 예를 들어 FedRAMP 또는 엔터프라이즈 규정 준수의 경우입니다.
- 기본적으로 root가 아닌 컨테이너 실행입니다.
- Agent Platform 자체에 필요한 것 이외에 언어 런타임이 없는 최소 공격 표면입니다.
- 플로우 실행 시 아웃바운드 인터넷 접근 없음(모든 Agent Platform 종속성이 사전 설치됨)

강화된 이미지는 `registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened`에서 게시됩니다

`linux/amd64` 및 `linux/arm64` 모두에 대해 빌드되며 다음 태그 스키마를 사용합니다:

- 각 빌드에 대해 `:<short-sha>`
- 각 릴리스에 대해 `:<git-tag>`

사전 요구 사항:

- GitLab 18.10 이상

강화된 이미지를 사용하려면 `agent-config.yml`에서 설정합니다.

```yaml
image: registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened:<tag>
```

### 이미지 내용 {#image-contents}

모든 구성 요소 및 고정된 버전의 권위있는 최신 목록은 `default-docker-image` [README](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/-/blob/main/README.md#runtime-inventory)의 런타임 인벤토리를 참조하세요.

다음 표에는 현재 고정된 버전이 나열되어 있습니다:

| 구성 요소                             | 버전 또는 출처                                        |
|---------------------------------------|----------------------------------------------------------|
| 기본 이미지                            | Red Hat UBI 9 Minimal(`ubi9-minimal:9.7-1776833838`)    |
| `git`                                 | 2.47.x(UBI 9 기본 제공)                                     |
| `git-lfs`                             | UBI 9 표준                                              |
| Node.js                               | 20(UBI 9 모듈 스트림 `nodejs:20`)                     |
| `npm`                                 | Node.js 20과 함께 번들로 제공                                  |
| `@gitlab/duo-cli`                     | 9.21.0                                                   |
| `glab`(GitLab CLI)                   | 1.107.0                                                  |
| `@anthropic-ai/sandbox-runtime`(SRT) | 0.0.63(npm을 통해)                                         |
| `bwrap`(bubblewrap)                  | AlmaLinux 9 EPEL(일반 바이너리, userns 기반 샌드박싱) |
| `socat`                               | AlmaLinux 9 EPEL                                         |
| `rg`(ripgrep)                        | AlmaLinux 9 EPEL                                         |
| `unshare`                             | UBI 9(`util-linux-core`)                                |
| 런타임 사용자                          | root가 아닌 사용자, UID 1001(`duo-runner`)                        |

이미지는 GitLab Duo CLI 및 `glab`을 포함합니다. `registry.npmjs.org` 또는 `registry.gitlab.com`에 대한 아웃바운드 접근은 플로우 실행 시 필요하지 않습니다.

Node.js 및 `npm`은 Anthropic Sandbox Runtime(SRT)을 설치하기 위해서만 이미지에 유지됩니다. GitLab Duo CLI 자체는 미리 컴파일된 바이너리이며 이들이 필요하지 않습니다. SRT도 미리 컴파일된 바이너리로 배포될 때 이후 버전의 강화된 이미지는 Node.js 및 `npm`을 완전히 제거합니다.

### 추가 패키지 추가 {#add-additional-packages}

강화된 이미지는 UID 1001(`duo-runner`)로 실행됩니다. `setup_script`의 `agent-config.yml`도 이 root가 아닌 사용자로 실행되므로 `microdnf`로 시스템 패키지를 설치할 수 없습니다.

언어 런타임 또는 시스템 패키지를 추가하려면:

1. 자신의 `FROM` 계층으로 이미지를 확장합니다.

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened:<tag>

   USER root
   RUN microdnf install -y python3.12 python3.12-pip && microdnf clean all
   USER 1001
   ```

1. `setup_script`을 사용하여 root 액세스가 필요하지 않은 프로젝트 종속성을 추가합니다. 예를 들어 `pip install --user` 또는 `npm install`입니다.
