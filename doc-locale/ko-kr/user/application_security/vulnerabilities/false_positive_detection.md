---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 거짓 양성을 자동으로 감지
description: SAST 검색 결과의 거짓 양성 자동 감지 및 필터링.
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.7에서 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/18977)되었으며, [베타](../../../policy/development_stages_support.md#beta) [기능 플래그](../../../administration/feature_flags/_index.md) `enable_vulnerability_fp_detection` 및 `ai_experiment_sast_fp_detection`으로 명명되어 있습니다. 기본적으로 사용으로 설정됩니다.
- GitLab 18.10에서 [일반 공급](https://gitlab.com/groups/gitlab-org/-/work_items/19789).
- 기능 플래그 [`ai_experiment_sast_fp_detection`](https://gitlab.com/gitlab-org/gitlab/-/work_items/584344) 및 [`enable_vulnerability_fp_detection`](https://gitlab.com/gitlab-org/gitlab/-/work_items/584343)는 GitLab 19.1에서 제거되었습니다.
- 분류 및 수정 프로필의 지원이 GitLab 19.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/254011)되었으며, [기능 플래그](../../../administration/feature_flags/_index.md) `triage_and_remediation_profile`으로 명명되어 있습니다. 기본적으로 사용으로 설정됩니다.

{{< /history >}}

정적 애플리케이션 보안 테스트(SAST) 스캔이 실행될 때, SAST 거짓 양성 감지 플로우는 각 중요도가 높은 SAST 취약성을 자동으로 분석하여 거짓 양성일 가능성을 결정합니다. 감지는 [GitLab 지원 SAST 분석기](../sast/analyzers.md)의 취약성에 사용할 수 있습니다.

플로우 평가는 다음을 포함합니다:

- 신뢰도 점수: 검색 결과가 거짓 양성일 가능성을 나타내는 수치 점수.
- 설명: 코드 컨텍스트 및 취약성 특성을 기반으로 검색 결과가 참 양성일 수도 있고 아닐 수도 있는 이유에 대한 컨텍스트 설명.
- 시각적 표시기: 거짓 양성 평가를 보여주는 취약점 보고서의 배지.

감지는 각 보안 스캔 후에 자동으로 실행되며 수동 트리거가 필요하지 않습니다.

결과는 AI 분석을 기반으로 하며 보안 전문가가 검토해야 합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 개요를 보려면 [GitLab AI 기반 SAST 거짓 양성 감지 및 수정](https://www.youtube.com/watch?v=kVMM5OFva_U)을 참조하세요.
<!-- Video published on 2026-03-20 -->

클릭 쓰루 데모를 보려면 [SAST 거짓 양성 감지 플로우](https://gitlab.navattic.com/sast-fp-detection-flow)를 참조하세요.
<!-- Demo published on 2026-02-17 -->

보안 구성 프로필도 이 플로우를 지원합니다. 여러 프로젝트 및 그룹에서 플로우를 한 번에 켜고 구성하려면 [자동화된 분류 및 수정 프로필](../configuration/security_configuration_profiles.md#automated-triage-and-remediation-profile)을 사용하세요.

## 사전 요구 사항 {#prerequisites}

- [GitLab Duo Agent Platform 사전 요구 사항](../../duo_agent_platform/_index.md#prerequisites)을 충족합니다.
- **파운데이셔널 플로우 허용** 및 **SAST 거짓 양성 검출**을 [최상위 그룹](../../duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off)에 대해 켜세요.
- [서비스 계정을 허용하도록 푸시 규칙을 해야 합니다](../../duo_agent_platform/troubleshooting.md#configure-push-rules-to-allow-a-service-account).
- 프로젝트를 위해 [자체 러너를 구성](../../duo_agent_platform/flows/execution/_index.md#configure-runners-to-execute-flows)하거나 [GitLab 호스팅 러너](../../../ci/runners/hosted_runners/_index.md)를 활성화해야 합니다.
- 사용자 설정에서 [기본 GitLab Duo 네임스페이스 설정](../../profile/preferences.md#set-a-default-gitlab-duo-namespace)을 합니다.

## 그룹에 대한 기본 플로우 허용 {#allow-foundational-flow-for-a-group}

그룹의 모든 프로젝트가 기본 플로우를 사용할 수 있도록 허용할 수 있습니다. 개별 프로젝트는 여전히 프로젝트 설정에서 기능을 활성화해야 합니다. 그룹의 모든 프로젝트에 대해 거짓 양성 탐지를 허용하려면:

1. 왼쪽 사이드바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. **설정** > **GitLab Duo**를 선택합니다.
1. **파운데이셔널 플로우 허용** 아래에서 **SAST 거짓 양성 검출** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 프로젝트에 대해 켜기 {#turn-on-for-a-project}

사전 요구 사항:

- 프로젝트에 대한 Security Manager, Maintainer 또는 Owner 역할.

특정 프로젝트에 대해 거짓 양성 탐지를 켜려면:

1. 왼쪽 사이드바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. **설정** > **일반**을 선택합니다.
1. **GitLab Duo**를 확장합니다.
1. **SAST 거짓 양성 탐지 켜기** 토글을 켭니다.
1. **변경 사항 저장**을 선택합니다.

그룹에 대해 거짓 양성 감지를 허용하고 프로젝트에 대해 켜면, 기능이 기존 SAST 스캐너와 자동으로 작동합니다.

## 자동 탐지 {#automatic-detection}

거짓 양성 감지 플로우는 다음 경우에 자동으로 실행됩니다:

- SAST 보안 스캔이 기본 브랜치에서 성공적으로 완료됩니다.
- 스캔이 중요도가 높은 취약성을 감지합니다.
- 프로젝트에 대해 GitLab Duo 기능이 활성화됩니다.

분석은 백그라운드에서 발생하며 처리가 완료되면 결과가 취약성 보고서에 표시됩니다.

## SAST 거짓 양성 감지 플로우 실행 {#run-the-sast-false-positive-detection-flow}

기존 취약성에 대한 분석을 수동으로 트리거할 수 있습니다:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **취약점 보고서**를 선택합니다.
1. 분석할 취약성을 선택합니다.
1. 오른쪽 상단 모서리에서 **AI 작업**을 선택한 후 **거짓 양성 점검**을 선택합니다.

GitLab Duo 분석이 실행되고 결과가 취약성 상세 정보 페이지에 표시됩니다.

## 여러 취약성 분석 {#analyze-multiple-vulnerabilities}

{{< details >}}

- 제공 서비스: GitLab.com, GitLab Self-Managed
- 상태:  베타

{{< /details >}}

{{< history >}}

- GitLab 19.3에서 `bulk_vulnerabilities_duo_workflow_api`라는 이름의 [기능 플래그](../../../administration/feature_flags/_index.md)로 [베타](../../../policy/development_stages_support.md#beta) 기능으로 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/21890)되었습니다. 기본적으로 사용 중지됩니다.
- GitLab 19.4에서 [GitLab.com 및 GitLab Self-Managed에서 기본적으로 활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/253325)됨.

{{< /history >}}

> [!flag]
> 이 기능의 사용 가능성은 기능 플래그로 제어합니다. 자세한 내용은 기록을 참조하세요.

플로우를 트리거하여 거짓 양성에 대한 여러 취약성을 분석할 수 있습니다.

다음 심각도 수준이 분석됩니다:

- 긴급
- 높음
- 중간
- 낮음
- 알 수 없음
- 정보

사전 요구 사항:

- 여러 취약성을 분석하려면 다음 중 하나가 필요합니다:
  - 프로젝트에 대한 보안 관리자, 유지 관리자 또는 소유자 역할
  - `admin_vulnerability` 권한이 있는 사용자 지정 역할
- 플로우의 진행률을 보려면 개발자 역할이 있어야 합니다.

1. 왼쪽 사이드바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. **안전함** > **취약점 보고서**를 선택합니다.
1. 분석하려는 각 취약성 옆의 확인란을 선택합니다. 페이지의 모든 취약점을 선택하려면 테이블 헤더의 확인란을 선택합니다.
1. **동작 선택** 드롭다운 목록에서 **SAST 거짓 양성 검출 실행**을 선택합니다.
1. **SAST 거짓 양성 검출 실행**을 선택합니다.

### 알려진 제한 사항 {#known-limitations}

- 진행률 보고서는 해결할 수 있는 취약성의 수만 표시합니다. 10개의 취약성을 선택하고 3개가 적격이면, 진행률 보고서는 3개만 보고합니다.
- 각 플로우의 한 번의 실행만 한 번에 프로젝트에서 활성화될 수 있습니다. 실행은 프로젝트에 속하므로 다른 사용자가 시작한 실행도 새 실행을 차단합니다. 같은 플로우의 다른 실행을 시작하기 전에 활성 실행이 완료될 때까지 기다리세요.
- 최대 1,000개의 취약성에 대해서만 대량 플로우 실행을 수행할 수 있습니다. 이 제한은 취약점 보고서에서 선택한 취약성에 적용됩니다. 1,000개 이상의 취약성을 해결하려면 GraphQL을 사용하세요.

## 신뢰도 점수 {#confidence-scores}

신뢰도 점수는 GitLab Duo 평가가 올바를 가능성을 추정합니다.

- **거짓 양성 가능성 높음(80-100%)**: GitLab Duo는 결과가 거짓 양성일 가능성이 매우 높다고 판단합니다.
- **거짓 양성 가능성 있음(60-79%)**: GitLab Duo는 결과가 거짓 양성일 수 있다고 합리적으로 판단하지만 수동 검토를 권장합니다.
- **거짓 양성 가능성 없음(<60%)**: GitLab Duo는 결과가 거짓 양성일 가능성이 낮다고 판단합니다. 취약성을 해지하기 전에 수동 검토를 강력히 권장합니다.

## 거짓 양성 해지 {#dismissing-false-positives}

GitLab Duo 분석이 취약성을 거짓 양성으로 식별하면 다음 옵션이 있습니다.

- 취약성 해지
- 거짓 양성 플래그 제거

### 취약성 해지 {#dismiss-the-vulnerability}

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **취약점 보고서**를 선택합니다.
1. 해지할 취약성을 선택합니다.
1. 오른쪽 사이드바에 **상태** 섹션에서 **편집**을 선택합니다.
1. **상태** 드롭다운 목록에서 **다음으로 해제...** 아래에서 **거짓 양성**을 선택합니다.
1. **댓글** 텍스트 상자에 거짓 양성으로 해제하는 이유에 대한 컨텍스트를 제공합니다. 댓글은 필수입니다.
1. **상태 변경**을 선택합니다.

취약성이 해지됨으로 표시되고 재도입되지 않는 한 향후 스캔에서 나타나지 않습니다.

### 거짓 양성 플래그 제거 {#remove-the-false-positive-flag}

거짓 양성 평가를 제거하고 취약성을 유지하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **취약점 보고서**를 선택합니다.
1. 거짓 양성 플래그가 있는 취약성을 찾습니다.
1. 취약성의 거짓 양성 배지 위에 마우스를 올립니다.
1. **거짓 양성 플래그 제거**를 선택합니다.

거짓 양성 플래그가 제거되고 FP 신뢰도 점수가 0으로 되돌아갑니다. 취약성은 보고서에 남아 있으며 향후 스캔에서 재평가될 수 있습니다.

## 피드백 제공 {#providing-feedback}

[이슈 583697](https://gitlab.com/gitlab-org/gitlab/-/issues/583697)에서 피드백을 공유하세요.

## 관련 항목 {#related-topics}

- [취약성 세부 정보](_index.md)
- [취약점 보고서](../vulnerability_report/_index.md)
- [SAST](../sast/_index.md)
- [GitLab Duo](../../gitlab_duo/_index.md)
