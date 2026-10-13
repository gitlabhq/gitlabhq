---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "CI/CD의 플로우를 위한 보안 모델, 에이전트 구성 파일의 위험성, 그리고 권장되는 보호 조치를 이해합니다."
title: 플로우 실행을 위한 보안 고려 사항
---

{{< details >}}

- 티어:  [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

플로우가 GitLab CI/CD에서 실행될 때:

- 이들은 [복합 ID](../../composite_identity.md)를 사용하여 액세스를 제한합니다.
- 플로우가 완료되면 제거되는 임시 [워크로드 파이프라인](../../../../ci/pipelines/pipeline_types.md#workload-pipeline)을 생성합니다.
- 사용 가능한 도구는 플로우의 목적에 따라 지정됩니다. 이러한 도구는 머지 리퀘스트 생성 또는 실행 환경에서 로컬 셸 명령 실행을 포함할 수 있습니다.

기본적으로 플로우는 GitLab 인스턴스에 대한 네트워크 액세스만 가능합니다. 네트워크 액세스 규칙에 대한 자세한 내용은 [네트워크 정책을 구성하는 방법](../../environment_sandbox.md#configure-a-network-policy)을 참조하세요. 이 별도의 환경은 셸 명령 실행의 의도하지 않은 결과로부터 보호합니다.

GitLab UI에서 플로우가 자동으로 실행되지 않도록 하려면 [플로우 실행을 끌 수 있습니다](../foundational_flows/_index.md#turn-foundational-flows-on-or-off).

## `agent-config.yml`의 보안 영향 {#security-implications-of-agent-configyml}

`.gitlab/duo/agent-config.yml` 파일은 플로우가 CI/CD에서 실행되는 방식을 제어하며, `setup_script`에서 실행되는 명령을 포함합니다. 플로우 실행 방식으로 인해 이 파일의 변경 사항은 커밋한 사용자보다 더 많은 영향을 미칩니다.

### 교차 사용자 실행 {#cross-user-execution}

플로우는 [복합 ID](../../composite_identity.md)를 통해 플로우를 트리거하는 사용자의 ID로 실행됩니다. `setup_script`의 명령은 트리거하는 사용자의 복합 ID 자격증명으로 실행되며, 구성을 커밋한 사용자의 자격증명이 아닙니다.

`.gitlab/duo/agent-config.yml`에 대한 쓰기 액세스 권한이 있는 사용자는 다른 사용자의 러너 환경에서 실행되는 작업에 영향을 줄 수 있습니다. 이 파일에 대한 수정 사항은 나중에 프로젝트에서 플로우를 트리거하는 모든 사용자의 실행 컨텍스트에 영향을 미칩니다.

### 노출된 환경 변수 {#exposed-environment-variables}

`setup_script` 실행 중(Anthropic Sandbox Runtime(SRT) 외부에서 실행됨) 다음의 민감한 변수가 환경에 있습니다.

- `GITLAB_OAUTH_TOKEN` 및 `GITLAB_TOKEN`: 복합 ID를 통한 트리거하는 사용자의 OAuth 토큰입니다.
- `DUO_WORKFLOW_GIT_HTTP_PASSWORD`: Git HTTP 암호입니다.
- `DUO_WORKFLOW_SERVICE_TOKEN`: 서비스 토큰입니다.
- `DUO_WORKFLOW_GIT_USER_EMAIL` 및 `DUO_WORKFLOW_GIT_USER_NAME`: 트리거하는 사용자의 이메일 및 이름입니다.

노출된 변수의 전체 목록은 [플로우 실행 변수](execution-variables.md)를 참조하세요.

### 권장되는 보호 {#recommended-protections}

`.gitlab/duo/agent-config.yml` 파일에 대한 무단 변경 위험을 줄이려면:

- [기본 브랜치 보호](../../../project/repository/branches/protected.md)를 통해 직접 푸시를 방지합니다.
- [코드 소유자](../../../project/codeowners/_index.md)를 사용하여 `.gitlab/duo/agent-config.yml`에 대한 변경 사항을 병합하기 전에 특정 소유자의 승인을 요구합니다. 예를 들어 `CODEOWNERS` 파일에 다음을 추가합니다.

  ```plaintext
  .gitlab/duo/agent-config.yml @your-group/security-reviewers
  ```

- [승인 규칙](../../../project/merge_requests/approvals/rules.md)을 구성하여 이 파일을 수정하는 머지 리퀘스트에 대해 신뢰할 수 있는 관리자의 리뷰를 요구합니다.
