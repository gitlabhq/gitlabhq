---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 파운데이셔널 플로우
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="모델 정보" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /collapsible >}}

기본 플로우는 GitLab에서 구축하고 유지 관리하며 GitLab 유지 관리 배지를 표시합니다({{< icon name="tanuki-verified" >}}).

각 플로우는 특정 문제를 해결하거나 개발 작업을 지원하도록 설계되었습니다.

다음과 같은 기본 플로우를 사용할 수 있습니다:

| 플로우 | 설명 |
|------|-------------|
| [에이전트 호환성 문제 해결](../../../application_security/dependency_scanning/agentic-breaking-change-resolution.md) | 종속성 버전 업그레이드 머지 리퀘스트의 호환성 문제를 자동으로 해결합니다. |
| [코드 검토](code_review/_index.md) | AI 기반 분석 및 피드백으로 코드 검토를 자동화합니다. |
| [GitLab CI/CD로 변환](../../../../ci/migration/convert_to_gitlab_ci.md) | Jenkins 파이프라인을 CI/CD로 마이그레이션합니다. |
| [Developer](developer.md) | 이슈에서 실행 가능한 머지 리퀘스트를 생성하거나 GitLab Duo Agentic Chat에서 다양한 작업을 완료합니다. |
| [CI/CD 파이프라인 수정](fix_pipeline.md) | 실패한 작업을 진단하고 복구합니다. |
| [검토자 추천](../../../project/merge_requests/reviews/automatic_reviewer_assignment.md#assign-reviewers-with-the-recommend-reviewers-flow) | 머지 리퀘스트를 검토하기에 가장 적합한 검토자를 추천하고 할당합니다. |
| [SAST 거짓 양성 탐지](../../../application_security/vulnerabilities/false_positive_detection.md) | SAST 결과의 거짓 긍정을 자동으로 식별하고 필터링합니다. |
| [SAST 취약성 해결](../../../application_security/vulnerabilities/agentic_vulnerability_resolution.md) | SAST 취약성을 해결하는 머지 리퀘스트를 자동으로 생성합니다. |
| [시크릿 거짓 긍정 검색](secret_false_positive_detection.md) | 시크릿 검색 결과의 거짓 긍정을 자동으로 식별하고 필터링합니다. |
| [보안 검토](security_review.md) | 머지 리퀘스트 변경 사항에서 비즈니스 로직 보안 취약성을 감지합니다. |
| [소프트웨어 개발](software_development.md) | 소프트웨어 개발 수명 주기 전반에서 AI 생성 솔루션을 만듭니다. |

## 개발자 {#for-developers}

GitLab에 새 기본 플로우를 생성하고 추가하는 방법을 알아보려면 [기본 플로우 개발 가이드](../../../../development/ai_features/foundational_flows.md)를 참조하세요.

## 플로우 실행 CI/CD 세부 정보 구성 {#configure-flow-execution-cicd-details}

플로우가 CI/CD를 사용하여 실행되는 환경을 구성할 수 있습니다.

예를 들어 GitLab Self-Managed에서 관리자는 기본 플로우 이미지에 대해 사용자 지정 컨테이너 레지스트리를 구성할 수 있습니다.

자세한 내용은 [플로우 실행 구성](../execution/_index.md)을 참조하세요.

## 기본 플로우의 보안 {#security-for-foundational-flows}

GitLab UI에서 기본 플로우는 다음 GitLab API에 액세스할 수 있습니다:

- [프로젝트 API](../../../../api/projects.md)
- [이슈 API](../../../../api/issues.md)
- [머지 리퀘스트 API](../../../../api/merge_requests.md)
- [리포지토리 파일 API](../../../../api/repository_files.md)
- [브랜치 API](../../../../api/branches.md)
- [커밋 API](../../../../api/commits.md)
- [CI 파이프라인 API](../../../../api/pipelines.md)
- [레이블 API](../../../../api/labels.md)
- [에픽 API](../../../../api/epics.md)
- [메모 API](../../../../api/notes.md)
- [검색 API](../../../../api/search.md)

### 서비스 계정 {#service-accounts}

기본 플로우는 서비스 계정을 사용하여 작업을 완료합니다. 자세한 내용은 [복합 신원 워크플로우](../../composite_identity.md#composite-identity-workflow)를 참조하세요.

기본 플로우가 머지 리퀘스트를 생성할 때, 머지 리퀘스트는 서비스 계정 대신 플로우를 트리거한 사용자에게 할당됩니다. 이는 업무 분리를 요구하는 규정 준수 프레임워크를 준수하기 위해 수행됩니다. [규정 준수 고려 사항](../../composite_identity.md#compliance-considerations-for-merge-requests)을 참조하세요.

## 기본 플로우 켜기 또는 끄기 {#turn-foundational-flows-on-or-off}

기본 플로우를 켜거나 끌 수 있습니다:

- GitLab.com:  최상위 그룹 및 프로젝트의 경우입니다.
- GitLab Self-Managed:  인스턴스, 그룹 및 프로젝트의 경우입니다.

또한 플로우 실행을 켜거나 꺼서 컴퓨팅 시간을 소비하는 기능이 GitLab UI에서 실행될 수 있는지 여부를 제어할 수 있습니다. 이러한 기능에는 외부 에이전트, 기본 플로우 및 사용자 지정 플로우가 포함됩니다.

이 설정은 GitLab에서 실행되는 플로우를 제어합니다. 예를 들어 이슈 또는 머지 리퀘스트에서 시작하는 플로우입니다.

이 설정은 IDE 또는 [GitLab Duo CLI](../../../gitlab_duo_cli/_index.md) 세션에서 직접 실행하는 플로우를 제어하지 않습니다. 이러한 세션에서는 다음 조건에서 기본 플로우를 실행할 수 있습니다:

- [GitLab Duo Agent Platform을 사용할 수 있으면](../../turn_on_off.md) 프로젝트 또는 그룹에 적용됩니다.
- 플로우는 구독 티어에서 사용 가능합니다. 베타 플로우는 또한 [실험 및 베타 기능](../../turn_on_off.md#turn-on-beta-and-experimental-features)이 켜져야 합니다.

예를 들어 기본 플로우를 끄면 GitLab에서 해당 플로우를 더 이상 실행할 수 없지만 사용자는 IDE 또는 GitLab Duo CLI 세션에서 계속 실행할 수 있습니다.

### GitLab.com {#on-gitlabcom}

{{< tabs >}}

{{< tab title="최상위 그룹" >}}

사전 요구 사항:

- 최상위 그룹의 소유자 역할이 있습니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 최상위 그룹을 찾습니다.
1. **설정** > **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **플로우 실행** 아래에서 **플로우 실행 허용** 및 **파운데이셔널 플로우 허용** 체크박스를 선택합니다.
1. 켜려는 각 기본 플로우에 대해 체크박스를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

최상위 그룹에 대한 기본 플로우를 끄면 해당 그룹을 기본 GitLab Duo 네임스페이스로 사용하는 사용자는 어떤 네임스페이스에서도 기본 플로우에 액세스할 수 없습니다.

{{< /tab >}}

{{< tab title="프로젝트" >}}

사전 요구 사항:

- 프로젝트에 대한 유지 관리자 또는 소유자 역할입니다.
- 최상위 그룹에 대해 플로우 실행 및 기본 플로우가 켜져 있습니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정 > 일반**을 선택합니다.
1. **GitLab Duo**를 확장합니다.
1. **GitLab Duo**, **플로우 실행 허용** 및 **파운데이셔널 플로우 허용** 토글을 켭니다.
1. **변경 사항 저장**을 선택합니다.

{{< /tab >}}

{{< /tabs >}}

### GitLab Self-Managed {#on-gitlab-self-managed}

{{< history >}}

- 이미지 레지스트리의 전체 이미지 참조가 GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/594208)되었습니다.

{{< /history >}}

{{< tabs >}}

{{< tab title="인스턴스" >}}

사전 요구 사항:

- 관리자 액세스 권한이 있어야 합니다.

1. 오른쪽 위 모서리에서 **관리자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **플로우 실행** 아래에서 **플로우 실행 허용** 및 **파운데이셔널 플로우 허용** 체크박스를 선택합니다.
1. 선택 사항입니다. **이미지 레지스트리** 텍스트 상자에 다음 중 하나를 입력합니다:

   - 해당 레지스트리에서 기본 이미지를 사용할 레지스트리 호스트명입니다.
   - 이미지 전체를 재정의할 전체 이미지 참조입니다(예: `registry.example.com/group/project/image:tag`).

   기본값 `registry.gitlab.com`을(를) 사용하려면 비워 둡니다.
1. **변경 사항 저장**을 선택합니다.

{{< /tab >}}

{{< tab title="그룹" >}}

사전 요구 사항:

- 그룹에 대한 유지 관리자 또는 소유자 역할이 있습니다.
- 인스턴스에 대해 플로우 실행 및 기본 플로우가 켜져 있습니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **GitLab Duo 기능**을 확장합니다.
1. **플로우 실행** 아래에서 **플로우 실행 허용** 및 **파운데이셔널 플로우 허용** 체크박스를 선택합니다.
1. 최상위 그룹만 해당하며, 켜려는 각 기본 플로우에 대해 체크박스를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

그룹에 대해 켜지면 모든 하위 그룹 및 프로젝트에서 기본 플로우를 사용할 수 있습니다.

{{< /tab >}}

{{< tab title="프로젝트" >}}

사전 요구 사항:

- 프로젝트에 대한 유지 관리자 또는 소유자 역할입니다.
- 인스턴스 및 그룹에 대해 플로우 실행 및 기본 플로우가 켜져 있습니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정 > 일반**을 선택합니다.
1. **GitLab Duo**를 확장합니다.
1. **GitLab Duo**, **플로우 실행 허용** 및 **파운데이셔널 플로우 허용** 토글을 켭니다.
1. **변경 사항 저장**을 선택합니다.

{{< /tab >}}

{{< /tabs >}}
