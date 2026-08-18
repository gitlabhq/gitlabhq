---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 시크릿 오탐 탐지
description: 비밀 탐지 결과에서 거짓 양성의 자동 탐지 및 필터링입니다.
---

{{< details >}}

- 계층: Ultimate
- 추가 기능: GitLab Duo Core, Pro, 또는 Enterprise
- 제공 서비스:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [에픽 17885](https://gitlab.com/groups/gitlab-org/-/work_items/20152)에서 GitLab 18.10의 [베타](../../../policy/development_stages_support.md#beta) 기능으로 [기능 플래그](../../../administration/feature_flags/_index.md)가 `duo_secret_detection_false_positive`명으로 도입되었습니다. [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227074).
- GitLab 19.1에서 [일반적으로 사용 가능](https://gitlab.com/groups/gitlab-org/-/work_items/21233)합니다.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

시크릿 오탐 탐지는 선택적 기능입니다.

> [!important]
이 기능을 활성화하면 탐지된 시크릿 주변의 코드 컨텍스트를 포함한 취약성 정보가 분석을 위해 대규모 언어 모델(LLM)로 전송됩니다. [시크릿 검색 및 수정](../../gitlab_duo/data_usage.md#secret-detection-and-redaction) 설명서에 설명된 동작은 이 기능에 적용되지 않습니다. 이 기능을 활성화하기 전에 조직의 데이터 정책을 검토하세요.

GitLab Duo 평가에는 각 거짓 양성 결과에 대한 정보가 포함됩니다:

- 신뢰도 점수: 결과가 거짓 양성일 가능성을 나타내는 수치 점수입니다.
- 설명: 코드 컨텍스트 및 시크릿 특성에 따라 결과가 참 양성일 수도 있고 아닐 수도 있는 이유입니다.
- 시각적 표시기: 거짓 양성 평가를 보여주는 취약점 보고서의 배지입니다.

활성화되면 거짓 양성 탐지가 수동 개입 없이 각 보안 스캔 후 자동으로 실행됩니다.

결과는 AI 분석을 기반으로 하며 보안 전문가가 검토해야 합니다. 이 기능에는 활성 구독이 포함된 GitLab Duo가 필요합니다.

## 자동 탐지 {#automatic-detection}

거짓 양성 탐지는 다음 시나리오에서 자동으로 실행됩니다:

- 시크릿 검색 스캔이 기본 브랜치에서 성공적으로 완료됩니다.
- 스캔이 시크릿을 탐지합니다.
- 프로젝트에 대해 GitLab Duo 기능이 활성화됩니다.

분석이 백그라운드에서 실행되고 처리가 완료된 후 결과가 취약점 보고서에 표시됩니다.

## 수동 트리거 {#manual-trigger}

기존 취약성에 대해 거짓 양성 탐지를 수동으로 실행할 수 있습니다:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **취약점 보고서**를 선택합니다.
1. 분석할 취약성을 선택합니다.
1. 오른쪽 위 모서리에서 **거짓 양성 점검**을 선택하여 거짓 양성 탐지를 트리거합니다.

GitLab Duo 분석이 실행되고 결과가 취약성 세부 정보 페이지에 표시됩니다.

## 구성 {#configuration}

거짓 양성 탐지를 사용하려면 다음 요구 사항을 충족해야 합니다:

- GitLab Duo 추가 기능 구독(GitLab Duo Core, Pro 또는 Enterprise)입니다.
- 프로젝트 또는 그룹에서 [GitLab Duo 활성화](../../gitlab_duo/turn_on_off.md).
- 사용자 기본 설정에서 [기본 GitLab Duo 네임스페이스 설정](../../profile/preferences.md#set-a-default-gitlab-duo-namespace).
- GitLab 18.10 이상입니다.

### 거짓 양성 탐지 활성화 {#enable-false-positive-detection}

거짓 양성 탐지는 기본적으로 꺼져 있으며 명시적으로 활성화해야 합니다. 활성화되면 취약성에 대한 정보(주변 코드 컨텍스트 포함)가 분석을 위해 LLM으로 전송됩니다. 이 기능을 사용하려면 그룹에 대한 기본 플로우를 활성화하고 프로젝트에 대한 기능을 켜야 합니다.

#### 그룹에 대한 기본 플로우 허용 {#allow-foundational-flow-for-a-group}

그룹의 모든 프로젝트가 기본 플로우를 사용할 수 있도록 허용할 수 있습니다. 개별 프로젝트는 여전히 프로젝트 설정에서 기능을 활성화해야 합니다. 그룹의 모든 프로젝트에 대해 거짓 양성 탐지를 허용하려면:

1. 왼쪽 사이드바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. **Settings** > **GitLab Duo**를 선택합니다.
1. **파운데이셔널 플로우 허용** 아래에서 **비밀 탐지 거짓 양성 검출** 확인란을 선택합니다.
1. **변경사항 저장**을 선택합니다.

#### 프로젝트에 대해 켜기 {#turn-on-for-a-project}

특정 프로젝트에 대해 거짓 양성 탐지를 켜려면:

1. 왼쪽 사이드바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. **Settings** > **General**을 선택합니다.
1. **GitLab Duo**를 확장합니다.
1. **Turn on secret detection false positive detection** 토글을 켭니다.
1. **변경사항 저장**을 선택합니다.

그룹에 대해 거짓 양성 탐지를 허용하고 프로젝트에 대해 켜면 기능이 기존 시크릿 검색 스캐너와 자동으로 작동합니다.

## 신뢰도 점수 {#confidence-scores}

신뢰도 점수는 GitLab Duo 평가가 올바를 가능성을 추정합니다:

- 거짓 양성일 가능성(80-100%): GitLab Duo는 결과가 거짓 양성일 가능성이 매우 높다고 판단합니다.
- 거짓 양성일 수 있음(60-79%): GitLab Duo는 결과가 거짓 양성일 수 있다고 합리적으로 판단하지만 수동 검토를 권장합니다.
- 거짓 양성이 아닐 가능성(<60%): GitLab Duo는 결과가 거짓 양성일 가능성이 낮다고 판단합니다. 취약성을 해지하기 전에 수동 검토를 강력히 권장합니다.

## 거짓 양성 해지 {#dismissing-false-positives}

GitLab Duo 분석이 취약성을 거짓 양성으로 식별하면 다음 옵션이 있습니다:

- 취약성 해지
- 거짓 양성 플래그 제거

### 취약성 해지 {#dismiss-the-vulnerability}

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **취약점 보고서**를 선택합니다.
1. 해지할 취약성을 선택합니다.
1. **상태 변경**을 선택합니다.
1. **상태** 드롭다운 목록에서 **해지됨**을 선택합니다.
1. **Set dismissal reason** 드롭다운 목록에서 **거짓 양성**을 선택합니다.
1. **댓글 추가** 입력 필드에 거짓 양성으로 해지하는 이유에 대한 컨텍스트를 제공합니다.
1. **상태 변경**을 선택합니다.

취약성이 해지됨으로 표시되고 재도입되지 않는 한 향후 스캔에서 나타나지 않습니다.

### 거짓 양성 플래그 제거 {#remove-the-false-positive-flag}

거짓 양성 평가를 제거하고 취약성을 유지하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **취약점 보고서**를 선택합니다.
1. 거짓 양성 플래그가 있는 취약성을 찾습니다.
1. 취약성의 거짓 양성 배지 위에 마우스를 올립니다.
1. **Remove False Positive Flag**를 선택합니다.

거짓 양성 플래그가 제거되고 FP 신뢰도 점수가 0으로 되돌아갑니다. 취약성은 보고서에 남아 있으며 향후 스캔에서 재평가될 수 있습니다.

## 피드백 제공 {#providing-feedback}

[이슈 592861](https://gitlab.com/gitlab-org/gitlab/-/work_items/592861)에서 피드백을 공유합니다.

## 관련 항목 {#related-topics}

- [취약성 세부 정보](_index.md)
- [취약점 보고서](../vulnerability_report/_index.md)
- [시크릿 검색](../secret_detection/_index.md)
- [GitLab Duo](../../gitlab_duo/_index.md)
