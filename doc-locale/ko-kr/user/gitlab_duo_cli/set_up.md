---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo CLI를 설치하고 인증합니다.
title: GitLab Duo CLI 설정
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[GitLab CLI](https://docs.gitlab.com/cli/)(`glab`)를 통해 GitLab Duo CLI를 사용할 수 있습니다. GitLab CLI를 사용하면 다른 GitLab 기능에 액세스할 수 있으며 OAuth 또는 개인 액세스 토큰을 사용하여 한 번만 인증하면 됩니다.

또는 GitLab Duo CLI(`duo`)를 독립 실행형 AI 도구로 설치 및 사용하고 개인 액세스 토큰으로 별도로 인증할 수 있습니다.

두 설정 모두 대화형 및 헤드리스 모드와 함께 모든 GitLab Duo CLI 옵션, 명령 및 기능을 지원합니다.

## 전제 조건 {#prerequisites}

- GitLab 19.2 이상.
- [GitLab Duo Agent Platform의 필수 조건](../duo_agent_platform/_index.md#prerequisites).
- GitLab Self-Managed와 GitLab Dedicated의 경우 GitLab Duo CLI 액세스가 [활성화](_index.md#manage-gitlab-duo-cli-access)되어 있는지 확인하세요.

> [!note]
> GitLab 18.11부터 19.1 사이를 사용 중인 경우, [베타 및 실험 기능](../duo_agent_platform/turn_on_off.md#turn-on-beta-and-experimental-features)을 활성화하여 최신 버전의 GitLab Duo CLI를 사용할 수 있습니다.

## GitLab CLI 사용 {#with-the-gitlab-cli}

전제 조건:

- [GitLab CLI](https://docs.gitlab.com/cli/) 1.107.0 이상.
- GitLab CLI가 [인증됨](https://docs.gitlab.com/cli/#authenticate-with-gitlab).

GitLab CLI를 통해 GitLab Duo CLI를 설정하려면:

1. GitLab Duo CLI에 대해 `glab` 명령을 실행합니다.

   ```shell
   glab duo cli
   ```

1. 프롬프트를 따라 GitLab Duo CLI 바이너리를 설치합니다.

GitLab CLI가 자동으로 인증을 처리하므로 즉시 GitLab Duo CLI를 사용을 시작할 수 있습니다.

## GitLab CLI 없이 {#without-the-gitlab-cli}

GitLab Duo CLI를 독립 실행형 도구로 사용하려면 설치한 다음 인증합니다.

### 설치 {#install}

GitLab Duo CLI를 컴파일된 바이너리로 설치하려면 설치 스크립트를 다운로드하고 실행합니다.

macOS 및 Linux:

```shell
bash <(curl --fail --silent --show-error --location "https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/raw/main/packages/cli/scripts/install_duo_cli.sh")
```

Windows:

```shell
irm "https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/raw/main/packages/cli/scripts/install_duo_cli.ps1" | iex
```

### 인증 {#authenticate}

> [!note]
> `glab`이 시스템에 이미 설치되고 인증된 경우 처음으로 `duo`을 실행할 때 `duo`는 자동으로 `glab`을 자격 증명 도우미로 사용합니다. 따로 인증할 필요가 없습니다. 이를 위해서는 `glab` 1.85.2 이상 및 `duo` 8.68.0 이상이 필요합니다.
>
> 이 기능을 사용할 수 있기 전에 `duo`을 인증했고 대신 `glab`을 자격 증명 도우미로 사용하려면 `~/.gitlab/storage.json`에서 인증 설정을 삭제합니다.

전제 조건:

- `api` 권한이 있는 [개인 액세스 토큰](../profile/personal_access_tokens.md).

인증하려면:

1. 터미널에서 `duo`을 실행합니다. 처음으로 GitLab Duo CLI를 실행할 때 구성 화면이 나타납니다.
1. **GitLab Instance URL**을 입력한 후 <kbd>Enter</kbd>를 누릅니다.
   - GitLab.com의 경우 `https://gitlab.com`을 입력합니다.
   - GitLab Self-Managed 또는 GitLab Dedicated의 경우 인스턴스 URL을 입력합니다.
1. **GitLab Token**에 개인 액세스 토큰을 입력합니다.
1. CLI를 저장하고 종료하려면 <kbd>Enter</kbd>를 누릅니다.
1. CLI를 다시 시작하려면 터미널에서 `duo`을 실행합니다.

초기 설정 후 구성을 수정하려면 `duo config edit`을 사용합니다.

### 환경 변수를 사용하여 인증 {#authenticate-with-environment-variables}

전제 조건:

- `api` 권한이 있는 [개인 액세스 토큰](../profile/personal_access_tokens.md).

GitLab Duo CLI는 표준 프록시 환경 변수를 준수합니다.

- `HTTP_PROXY` 또는 `http_proxy`: HTTP 요청에 대한 프록시 URL입니다.
- `HTTPS_PROXY` 또는 `https_proxy`: HTTPS 요청에 대한 프록시 URL입니다.
- `NO_PROXY` 또는 `no_proxy`: 프록시에서 제외할 호스트의 쉼표로 구분된 목록입니다.

환경 변수로 인증하려면:

1. `GITLAB_TOKEN` 또는 `GITLAB_OAUTH_TOKEN`을 개인 액세스 토큰으로 설정합니다.

   ```shell
   export GITLAB_TOKEN="<your-personal-access-token>"
   ```

1. 선택 사항. `GITLAB_BASE_URL` 또는 `GITLAB_URL`을 사용자 정의 GitLab 인스턴스 URL로 설정합니다(예: `https://gitlab.example.com`). 기본값은 `https://gitlab.com`입니다.

   ```shell
   export GITLAB_BASE_URL="<your-instance-url>"
   ```

이 방법은 헤드리스 모드, CI/CD 파이프라인 및 대화형 인증이 불가능한 스크립트된 워크플로우에 유용합니다.

## 관련 항목 {#related-topics}

- [GitLab Duo CLI 완전 참조](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md)
- [편집기 확장 프로그램의 보안 고려 사항](../../editor_extensions/security_considerations.md)
- [GitLab CLI](https://docs.gitlab.com/cli/)
