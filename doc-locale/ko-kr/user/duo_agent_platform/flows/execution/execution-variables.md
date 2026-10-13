---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "플로우를 실행하는 작업에서 사용할 수 있는 사전 정의된 변수, 환경 변수 및 ID 토큰 변수와 사용할 수 없는 변수를 알아봅니다."
title: 플로우 실행 변수
---

{{< details >}}

- 티어:  [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

모든 변수를 플로우를 실행하는 작업에서 사용할 수 있는 것은 아닙니다.

- 일부 사전 정의된 변수 및 Agent Platform 특정 변수를 사용할 수 있습니다.
- 사전 정의된 필터링된 변수, 사용자 지정 CI/CD 변수 및 사용자 ID 변수는 사용할 수 없습니다.

## 사용할 수 있는 변수 {#available-variables}

다음 변수는 플로우를 실행하는 작업에서 사용할 수 있습니다.

### 사전 정의된 변수 {#predefined-variables}

다음 사전 정의된 CI/CD 변수를 사용할 수 있습니다:

| 변수 | 설명 |
|----------|-------------|
| `CI_PROJECT_ID` | 프로젝트 ID입니다. |
| `CI_PROJECT_NAME` | 프로젝트 이름입니다. |
| `CI_PROJECT_PATH` | 네임스페이스가 포함된 프로젝트 경로입니다. |
| `CI_PROJECT_URL` | 프로젝트 HTTP URL입니다. |
| `CI_PROJECT_NAMESPACE` | 프로젝트 네임스페이스입니다. |
| `CI_PROJECT_VISIBILITY` | 프로젝트 표시 여부(`public`, `internal` 또는 `private`)입니다. |
| `CI_DEFAULT_BRANCH` | 기본 브랜치 이름입니다. |
| `CI_JOB_ID` | 작업 ID입니다. |
| `CI_JOB_URL` | 작업 URL입니다. |
| `CI_JOB_TOKEN` | 작업 인증 토큰입니다. |
| `CI_JOB_IMAGE` | 작업에 사용된 Docker 이미지입니다. |
| `CI_JOB_STATUS` | 작업 상태입니다. |
| `CI_JOB_TIMEOUT` | 초 단위의 작업 시간 초과입니다. |
| `CI_JOB_STARTED_AT` | ISO 8601 형식의 작업 시작 타임스탬프입니다. |
| `CI_PIPELINE_ID` | 파이프라인 ID입니다. |
| `CI_PIPELINE_URL` | 파이프라인 URL입니다. |
| `CI_REGISTRY_USER` | 컨테이너 레지스트리 사용자 이름(`gitlab-ci-token`)입니다. |
| `CI_REGISTRY_PASSWORD` | 컨테이너 레지스트리 암호(작업 토큰)입니다. |
| `CI_DEPENDENCY_PROXY_USER` | 종속성 프록시 사용자 이름입니다. |
| `CI_DEPENDENCY_PROXY_PASSWORD` | 종속성 프록시 암호입니다. |
| `CI_REPOSITORY_URL` | 내장된 자격 증명이 있는 Git 복제 URL입니다. |
| `CI_RUNNER_VERSION` | 러너 버전입니다. |
| `CI_RUNNER_EXECUTABLE_ARCH` | 러너 아키텍처(예: `linux/amd64`)입니다. |
| `CI_SERVER` | CI/CD 환경에서 항상 `yes`입니다. |
| `CI_WORKLOAD_REF` | 플로우 실행을 위한 워크로드 참조(예: `refs/workloads/c727f70ba7f`)입니다. 이들은 내부 Git 참조이며 파이프라인 작업이 완료되거나 실패할 때 자동으로 제거됩니다.|

### 환경 변수 {#environment-variables}

다음 환경 변수는 Agent Platform에 특정됩니다. 이 변수는 `setup_script` 및 기본 에이전트 런타임에서 모두 사용할 수 있습니다.

이 테이블은 주요 변수를 설명합니다. 추가 내부 변수(예: 디버그 플래그 및 원격 분석 식별자)도 실행 컨테이너에 있을 수 있지만 플로우 구성에서 사용하기 위한 것이 아닙니다.

| 변수 | 설명 | 예제 |
|----------|-------------|---------|
| `DUO_WORKFLOW_GIT_HTTP_BASE_URL` | GitLab 인스턴스 기본 URL입니다. 대신 `CI_SERVER_URL`을 사용합니다. | `https://gitlab.com` |
| `DUO_WORKFLOW_PROJECT_ID` | 프로젝트 ID입니다. `CI_PROJECT_ID`과 동일한 값입니다. | `77056053` |
| `DUO_WORKFLOW_NAMESPACE_ID` | 네임스페이스 ID입니다. | `91555435` |
| `DUO_WORKFLOW_GOAL` | 플로우를 트리거한 이슈의 URL입니다. | `https://gitlab.com/group/project/-/issues/10` |
| `DUO_WORKFLOW_DEFINITION` | 플로우 정의 식별자입니다. | `developer/v1` |
| `DUO_WORKFLOW_SERVICE_REALM` | 배포 유형입니다. | `saas` 또는 `self-managed` |
| `DUO_WORKFLOW_GIT_HTTP_USER` | 복제를 위한 Git HTTP 사용자 이름입니다. | `oauth` |
| `DUO_WORKFLOW_GIT_HTTP_PASSWORD` | 복제를 위한 Git HTTP 암호입니다. | *(OAuth 토큰)* |
| `DUO_WORKFLOW_GIT_USER_NAME` | 플로우를 트리거한 사용자의 이름입니다. Git 커밋자로 사용됩니다. | `Jane Developer` |
| `DUO_WORKFLOW_GIT_USER_EMAIL` | 플로우를 트리거한 사용자의 이메일입니다. Git 커밋자 이메일로 사용됩니다. | `jdeveloper@example.com` |
| `DUO_WORKFLOW_GIT_AUTHOR_EMAIL` | 서비스 계정의 이메일입니다. Git 작성자 이메일로 사용됩니다. | `service_account_group_<ID>@noreply.gitlab.com` |
| `DUO_WORKFLOW_GIT_AUTHOR_USER_NAME` | 서비스 계정의 이름입니다. Git 작성자 이름으로 사용됩니다. | `Duo Developer` |
| `GITLAB_BASE_URL` | GitLab 인스턴스 기본 URL입니다. `DUO_WORKFLOW_GIT_HTTP_BASE_URL`과 동일한 값입니다. | `https://gitlab.com` |
| `GITLAB_PROJECT_PATH` | 네임스페이스가 포함된 프로젝트 전체 경로입니다. `CI_PROJECT_PATH`과 동일한 값입니다. | `my-group/my-project` |
| `GITLAB_TOKEN` | GitLab API 액세스를 위한 OAuth 토큰입니다. `DUO_WORKFLOW_GIT_HTTP_PASSWORD`과 동일한 값입니다. | *(OAuth 토큰)* |
| `AGENT_PLATFORM_GITLAB_VERSION` | 플로우를 실행하는 GitLab 버전입니다. | `18.9.0` |

### ID 토큰 변수 {#id-token-variables}

{{< history >}}

- GitLab 19.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224940)되었습니다.

{{< /history >}}

선언하는 [ID 토큰](../../../../ci/secrets/id_token_authentication.md)은 플로우 작업에서 환경 변수로 사용할 수 있습니다. 각 변수는 선언하는 토큰의 이름을 사용합니다.

ID 토큰을 다음에서 선언합니다:

- `agent-config.yml` 파일은 CI/CD를 사용하는 플로우용입니다. 자세한 내용은 [ID 토큰 구성](_index.md#configure-id-tokens)을 참조하세요.
- [사용자 지정 외부 에이전트](../../agents/external.md#authenticate-with-id-tokens)의 구성입니다.

예를 들어, `id_tokens` 블록을 `VAULT_ID_TOKEN` 토큰으로 선언하면 플로우가 `$VAULT_ID_TOKEN`을 사용할 수 있습니다.

## 사용할 수 없음 {#not-available}

다음 변수는 플로우를 실행하는 작업에서 사용할 수 없습니다.

### 필터링된 사전 정의된 변수 {#filtered-predefined-variables}

다음 사전 정의된 CI/CD 변수는 사용할 수 없습니다:

| 변수 | 이유 |
|----------|--------|
| `CI_REGISTRY` | 워크로드 변수 게이트에서 필터링됩니다. 대신 하드코딩된 레지스트리 호스트 이름을 사용합니다. |
| `CI_REGISTRY_IMAGE` | 워크로드 변수 게이트에서 필터링됩니다. 대신 하드코딩된 이미지 경로를 사용합니다. |
| `CI_SERVER_URL`, `CI_SERVER_HOST`, `CI_API_V4_URL` | 필터링됩니다. 대신 `GITLAB_BASE_URL` 또는 `DUO_WORKFLOW_GIT_HTTP_BASE_URL`을 사용합니다. |
| `CI_COMMIT_SHA`, `CI_COMMIT_BRANCH`, `CI_COMMIT_REF_NAME` | 작업에는 커밋 컨텍스트가 없습니다. 소스 브랜치는 GitLab Duo 에이전트에 의해 관리됩니다. |
| `GITLAB_USER_LOGIN`, `GITLAB_USER_EMAIL`, `GITLAB_USER_NAME` | 작업은 트리거 사용자가 아닌 서비스 계정으로 실행됩니다. |
| `CI_PIPELINE_SOURCE`, `CI_PIPELINE_IID` | 워크로드 변수 게이트에서 필터링됩니다. |

### 사용자 ID {#user-identity}

플로우 실행 중에 사용되는 CI 작업 토큰은 트리거 사용자와 서비스 계정을 모두 나타내는 [복합 ID](../../composite_identity.md) 토큰입니다.

플로우 실행 중에 생성된 Git 커밋은 플로우를 트리거한 사용자에 의해 커밋되지만 서비스 계정에 의해 작성된 것으로 표시됩니다.

사용자가 아닌 서비스 계정이 플로우를 실행하고 있으므로 `GITLAB_USER_LOGIN` 및 `GITLAB_USER_EMAIL` 변수는 사용할 수 없습니다.

그러나 플로우를 트리거한 사용자의 ID는 `DUO_WORKFLOW_GIT_USER_EMAIL` 및 `DUO_WORKFLOW_GIT_USER_NAME`에서 사용할 수 있으며 서비스 계정 ID는 `DUO_WORKFLOW_GIT_AUTHOR_EMAIL` 및 `DUO_WORKFLOW_GIT_AUTHOR_USER_NAME`에서 사용할 수 있습니다.

### 사용자 지정 CI/CD 변수 {#custom-cicd-variables}

**설정** > **CI/CD** > **변수**에서 정의된 사용자 지정 CI/CD 변수는 프로젝트, 그룹 또는 인스턴스에 사용할 수 없습니다.

사용자 지정 CI/CD 변수에는 보호된 변수, 보호되지 않은 변수, 마스킹된 변수 및 파일 변수가 포함됩니다.

모든 플로우 구성은 `agent-config.yml` 또는 [사용할 수 있는 환경 변수](#environment-variables)를 통해 제공되어야 합니다.

## GitLab 인스턴스 URL 액세스 {#accessing-the-gitlab-instance-url}

표준 `CI_SERVER_URL` 변수는 사용할 수 없습니다. 대신 `GITLAB_BASE_URL` 또는 `DUO_WORKFLOW_GIT_HTTP_BASE_URL`을 사용합니다.

예를 들어, `setup_script`에서 API 호출을 하려면:

```yaml
setup_script:
  - "curl --silent --header 'JOB-TOKEN: ${CI_JOB_TOKEN}' ${GITLAB_BASE_URL}/api/v4/projects/${CI_PROJECT_ID}"
```
