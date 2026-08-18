---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Fix CI/CD Pipeline 플로우
---

{{< details >}}

- 티어: [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.4에서 [실험](../../../../policy/development_stages_support.md)으로 도입되었으며 [기능 플래그](../../../../administration/feature_flags/_index.md) `duo_workflow_in_ci` 및 `ai_duo_agent_fix_pipeline_button`로 명명되었습니다. `duo_workflow_in_ci`는 기본적으로 활성화되어 있습니다. `ai_duo_agent_fix_pipeline_button`는 기본적으로 비활성화되어 있습니다. 이 플래그는 인스턴스 또는 프로젝트에 대해 활성화하거나 비활성화할 수 있습니다.
- GitLab 18.5에서 GitLab.com 및 GitLab Self-Managed에서 활성화되었습니다.
- 기능 플래그 `ai_duo_agent_fix_pipeline_button`는 GitLab 18.5에서 [기본적으로 활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205086)되었습니다.
- GitLab 18.8에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)합니다. 기능 플래그 `ai_duo_agent_fix_pipeline_button`이 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/216681)되었습니다. 기능 플래그 `duo_workflow_in_ci`는 GitLab 18.9에서 제거되었습니다.
- GitLab 18.10부터 GitLab.com의 Free 티어에서 GitLab Credits를 사용하여 이용 가능합니다.
- [머지 리퀘스트와 연결된 파이프라인에 대한 수정이 변경](https://gitlab.com/groups/gitlab-org/-/work_items/21837)되어 GitLab 19.1에서 코드 제안으로 적용되며 [기능 플래그](../../../../administration/feature_flags/_index.md) `fix_pipeline_next`로 명명됩니다. GitLab.com에서 사용자의 일부에 대해 활성화되었습니다.
- GitLab 19.2에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/241608)합니다. `fix_pipeline_next` 기능 플래그가 제거되었습니다.

{{< /history >}}

Fix CI/CD Pipeline Flow는 GitLab CI/CD 파이프라인의 문제를 진단하고 수정을 제안합니다. 실패를 진단하기 위해 플로우는 다음을 검사합니다:

- 오류 메시지, 실패한 작업 출력 및 종료 코드를 포함한 파이프라인 로그입니다.
- 실패를 야기했을 수 있는 머지 리퀘스트 변경 사항입니다.
- 구문, 린팅 또는 가져오기 오류를 식별하기 위한 리포지토리 내용입니다.
- 명령 실패, 누락된 실행 파일 또는 권한 문제를 포함한 스크립트 오류입니다.

플로우가 수정을 적용하는 방법은 파이프라인 컨텍스트에 따라 달라집니다:

- 파이프라인이 머지 리퀘스트와 연결되어 있으면 플로우는 소스 브랜치에 인라인 코드 제안을 적용합니다. 머지 리퀘스트에서 직접 제안을 검토하고 적용할 수 있습니다.
  - 수정이 현재 머지 리퀘스트 diff 외부의 파일 변경을 필요로 하면 플로우는 대신 새 머지 리퀘스트를 생성합니다.
- 파이프라인이 머지 리퀘스트와 연결되어 있지 않으면 플로우는 수정을 포함하는 새 머지 리퀘스트를 생성합니다.

경우에 따라 플로우는 수정을 시도하는 대신 실패와 가능한 다음 단계를 설명하는 댓글을 게시합니다. 이는 파이프라인이 머지 리퀘스트와 연결되어 있을 때 발생합니다. 예를 들어:

- 신뢰할 수 있는 수정을 결정하기 위한 충분한 컨텍스트가 없습니다.
- 실패는 보안에 민감하며 사람이 검토해야 합니다.
- 실패 범주는 플로우에서 실행 가능하지 않습니다.

세션이 시작되고 완료되면 플로우는 세션에 대한 링크가 포함된 시스템 메모를 머지 리퀘스트에 게시합니다. 이 플로우는 GitLab UI에서만 사용할 수 있습니다.

GitLab Duo Agent Platform을 사용하고 실패한 파이프라인을 자동으로 수정하려면 이 플로우가 권장되는 경로입니다. 이는 [Root Cause Analysis](../../../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)와는 별개의 경험이며, 단일 작업 실패를 트러블슈팅하는 GitLab Duo Chat 기능입니다.

## 전제 조건 {#prerequisites}

- [GitLab Duo Agent Platform 전제 조건](../../_index.md#prerequisites)을 충족해야 합니다.
- **파운데이셔널 플로우 허용** 및 **CI/CD 파이프라인 헤결**를 [최상위 그룹](_index.md#turn-foundational-flows-on-or-off)에 대해 활성화합니다.
- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.
- 기존의 실패한 파이프라인이 있습니다.
- [서비스 계정을 허용하도록 푸시 규칙을 해야 합니다](../../troubleshooting.md#configure-push-rules-to-allow-a-service-account).
- 프로젝트를 위해 [자체 러너를 구성](../execution.md#configure-runners-to-execute-flows)하거나 [GitLab 호스팅 러너](../../../../ci/runners/hosted_runners/_index.md)를 활성화해야 합니다.

## 머지 리퀘스트에서 파이프라인 수정 {#fix-the-pipeline-in-a-merge-request}

{{< history >}}

- GitLab Duo Agentic Chat 대화에서 플로우 사용 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/20484)됨은 GitLab 19.2에서 [기능 플래그](../../../../administration/feature_flags/_index.md) `agentic_foundational_flow_tool`로 명명되었습니다. 기본적으로 활성화되었습니다.

{{< /history >}}

> [!flag]
> 이 기능의 사용 가능 여부는 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요.

머지 리퀨스트에서 CI/CD 파이프라인을 수정하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 엽니다.
1. 파이프라인을 수정하려면 다음 방법 중 하나를 사용합니다:
   - **개요** 탭을 선택하고 실패한 파이프라인 아래에서 **Duo로 파이프라인 고침**을 선택합니다.
   - **파이프라인** 탭을 선택하고 맨 오른쪽 열에서 **Duo로 파이프라인 고침**({{< icon name="tanuki-ai" >}})을 선택합니다.
   - GitLab Duo 사이드바에서 새로운 또는 기존 Agentic Chat 대화를 엽니다. Agentic Chat에 파이프라인을 수정하도록 요청합니다.
1. 진행 상황을 모니터링하려면 왼쪽 사이드바에서 **AI** > **세션**을 선택하세요.

   Agentic Chat에 있는 경우 다음을 수행할 수도 있습니다:
   - Chat 대화에서 진행 상황을 확인하세요.
   - 대화에서 **View Agent Session**를 선택하세요.

세션이 완료되면 플로우는 코드 제안을 머지 리퀘스트에 추가하거나 댓글이 가능한 다음 단계를 설명합니다.

## 다른 CI/CD 파이프라인 수정 {#fix-other-cicd-pipelines}

머지 리퀘스트와 연결되지 않은 CI/CD 파이프라인을 수정하려면:

1. **빌드** > **파이프라인**을 선택합니다.
1. 실패한 파이프라인을 선택합니다.
1. 오른쪽 위 모서리에서 **Duo로 파이프라인 고침**을 선택합니다.
1. 진행 상황을 모니터링하려면 **AI** > **세션**을 선택합니다.

## `AGENTS.md`을 사용하여 플로우 사용자 정의 {#use-agentsmd-to-customize-the-flow}

플로우는 리포지토리의 [`AGENTS.md`](../../customize/agents_md.md) 파일에서 리포지토리 특정 지침을 읽습니다. `AGENTS.md`을 사용하여 다음과 같은 동작을 사용자 정의할 수 있습니다:

- 플로우가 커밋하는 변경 사항에 대한 커밋 메시지 형식입니다.
- 플로우가 생성하는 머지 리퀘스트에 대한 레이블 및 설명과 같은 머지 리퀘스트 메타데이터입니다.
- 특정 유형의 실패를 분류하고 처리하는 방법입니다.

예를 들어:

```markdown
## Fix pipeline merge requests

When opening a merge request as part of the Fix Pipeline flow (the title contains [FixPipeline]),
apply labels based on the following failed pipeline scenarios:

- Pipeline failed on merge_request: apply "pipeline::tier-1". This runs the cheaper tier-1
  pipeline instead of the full default pipeline.
- Pipeline failed on the default_branch (main): apply both "pipeline::expedited" and
  "main:broken". Do not apply pipeline::tier-1 in this case.
- Pipeline failed on other branches: apply "pipeline::tier-1". Same treatment as the
  merge_request case.
```

## 알려진 이슈 {#known-issues}

- AI 게이트웨이는 작업 로그의 마지막 150KiB만 처리합니다. 작업이 광범위한 출력을 생성하면 플로우는 로그의 앞부분에 나타나는 관련 실패 정보를 캡처하지 못할 수 있습니다. 해결 방법은 다음 섹션을 참조하세요.
- 플로우는 샌드박스 런타임 환경에서 패키지 설치를 항상 확인할 수 없습니다. 종속 항목이 누락된 경우 기본 플로우 이미지를 사용자 정의할 수 있습니다. [기본 Docker 이미지 변경](../execution.md#change-the-default-docker-image)을 참조하세요.
- `AGENTS.md`의 리포지토리 지침은 플로우의 동작에 영향을 주지만 모든 경우에 따르도록 보장되지는 않습니다.

## 문제 해결 {#troubleshooting}

Fix CI/CD Pipeline 플로우로 작업할 때 다음 문제가 발생할 수 있습니다.

### 플로우가 실패의 근본 원인을 식별할 수 없음 {#flow-cannot-identify-the-root-cause-of-a-failure}

플로우는 파이프라인 실패의 근본 원인을 식별하지 못할 수 있습니다.

이 문제는 작업 로그가 150KiB를 초과할 때 발생합니다. AI 게이트웨이는 마지막 150KiB만 처리하므로 로그의 앞부분에 나타나는 관련 실패 정보를 캡처하지 못할 수 있습니다.

이 문제를 해결하려면 다음을 시도하세요:

- 디버그 로깅 및 진행 표시기를 제거하여 자세한 출력을 줄입니다.
- 셸 리디렉션(`> /dev/null`)을 사용하여 중요하지 않은 출력을 리디렉션합니다.
- 주요 오류 메시지를 반향하는 스크립트 끝에 요약 단계를 추가합니다.
- `after_script`을 사용하여 기본 스크립트가 완료된 후 진단 정보를 출력합니다.
- 자세한 작업을 더 간결한 로그를 가진 더 작고 집중된 작업으로 분할합니다.

## 피드백 제공 {#give-feedback}

팀은 Fix CI/CD Pipeline 플로우를 적극적으로 개선하고 있습니다. 문제를 보고하거나 개선을 제안하려면 [피드백 이슈 601991](https://gitlab.com/gitlab-org/gitlab/-/work_items/601991)에 피드백을 남겨주세요.
