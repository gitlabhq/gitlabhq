---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab Duo CLI용 옵션, 명령, 환경 변수"
title: GitLab Duo CLI 참조
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab Duo CLI를 시작하거나 실행할 때 이러한 옵션, 명령 및 환경 변수를 사용합니다.

완전한 목록이 아닙니다. 전체 참고 자료는 [GitLab Duo CLI 완전 참고 자료](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md)를 참조하세요.

## 옵션 {#options}

GitLab Duo CLI는 다음 옵션을 지원합니다.

- `-C, --cwd <path>`: 작업 디렉터리를 변경합니다.
- `-h, --help`: GitLab Duo CLI 또는 특정 명령에 대한 도움말을 표시합니다. 예를 들어 `duo --help` 또는 `duo run --help`입니다.
- `-v`, `--version`: 버전 정보를 표시합니다.
- `--model <model>`: 세션에 사용할 AI 모델을 선택합니다.

옵션의 완전한 목록은 GitLab Duo CLI 완전 참고 자료를 참조하세요.

## 명령 {#commands}

다음 명령은 각 설정에 대해 사용할 수 있습니다.

{{< tabs >}}

{{< tab title="glab" >}}

- `glab duo cli`: 대화형 모드를 시작합니다.
- `glab duo cli log`: 로그를 보고 관리합니다.
- `glab duo cli run`: 헤드리스 모드를 시작합니다.

{{< /tab >}}

{{< tab title="duo" >}}

- `duo`: 대화형 모드를 시작합니다.
- `duo config`: 구성 및 인증 설정을 관리합니다.
- `duo log`: 로그를 보고 관리합니다.
- `duo run`: 헤드리스 모드를 시작합니다.

{{< /tab >}}

{{< /tabs >}}

명령의 완전한 목록은 GitLab Duo CLI 완전 참고 자료를 참조하세요.

## 환경 변수 {#environment-variables}

{{< history >}}

- GitLab 19.0 릴리스 중 `AI_AGENT` 환경 변수가 GitLab Duo CLI 8.95.0에 [도입](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.95.0)되었습니다.

{{< /history >}}

환경 변수를 사용하여 GitLab Duo CLI를 구성할 수 있습니다.

- `DUO_WORKFLOW_GIT_HTTP_PASSWORD`: Git HTTP 인증 암호입니다.
- `DUO_WORKFLOW_GIT_HTTP_USER`: Git HTTP 인증 사용자 이름입니다.
- `GITLAB_BASE_URL` 또는 `GITLAB_URL`: GitLab 인스턴스 URL입니다.
- `GITLAB_DUO_MODEL`: 세션에 사용할 AI 모델입니다.
- `GITLAB_OAUTH_TOKEN` 또는 `GITLAB_TOKEN`: 인증 토큰입니다.

GitLab Duo CLI가 귀하를 대신하여 명령을 실행할 때 해당 프로세스에 `AI_AGENT` 환경 변수를 설정합니다. 스크립트 및 도구는 `AI_AGENT`을 읽어 AI 기반 실행 중임을 감지할 수 있습니다.

환경 변수의 완전한 목록은 GitLab Duo CLI 완전 참고 자료를 참조하세요.
