---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 스크릿 거짓 양성 탐지
---

{{< details >}}

- 티어:  Ultimate
- 추가 기능: GitLab Duo Core, Pro 또는 Enterprise
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.10에서 `duo_secret_detection_false_positive` [기능 플래그](../../../../administration/feature_flags/_index.md)의 [베타](../../../../policy/development_stages_support.md#beta) 기능으로 [에픽 17885](https://gitlab.com/groups/gitlab-org/-/work_items/20152)가 도입되었습니다. [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227074).
- GitLab 19.1에서 [일반적으로 사용 가능](../../../../policy/development_stages_support.md#generally-available)합니다.

{{< /history >}}

스크릿 오탐 탐지는 시크릿 검색 결과를 자동으로 분석하여 거짓 양성을 식별합니다. 실제 보안 위험이 아닐 가능성이 높은 시크릿을 무시하면 취약성 보고서의 노이즈를 줄입니다.

시크릿 검색 스캔이 실행되면 GitLab Duo는 각 결과를 자동으로 분석하여 거짓 양성일 가능성을 판단합니다. 탐지는 [GitLab 시크릿 검색](../../../application_security/secret_detection/_index.md)에서 탐지한 모든 시크릿 유형에 사용 가능합니다.

GitLab Duo 평가에는 각 거짓 양성 검출 결과에 대한 정보가 포함됩니다:

- 신뢰도 점수: 결과가 거짓 양성일 가능성을 나타내는 수치 점수입니다.
- 설명: 결과가 실제 양성일 수도 있고 아닐 수도 있는 이유입니다.
- 시각적 표시기: 평가 결과를 보여주는 취약성 보고서의 배지입니다.

결과는 AI 분석을 기반으로 하며 보안 전문가가 검토해야 합니다. 이 기능을 사용하려면 활성 구독이 있는 GitLab Duo가 필요합니다.

> [!note]
> 서비스 계정을 언급하거나 할당하거나 검토 요청을 통해 이 플로우를 트리거할 수 없습니다. 플로우는 보안 스캔이 완료된 후 자동으로 실행됩니다. 수동으로 실행하려면 취약성 페이지에서 **AI 작업**을 선택한 후 **거짓 양성 점검**을 선택하세요.

## 사전 요구 사항 {#prerequisites}

- [GitLab Duo Agent Platform 사전 요구 사항](../../_index.md#prerequisites)을 충족합니다.
- **파운데이셔널 플로우 허용** 및 **비밀 탐지 거짓 양성 검출**을 [최상위 그룹에 대해](_index.md#turn-foundational-flows-on-or-off) 켭니다.
- [서비스 계정을 허용하도록 푸시 규칙을 해야 합니다](../../troubleshooting.md#configure-push-rules-to-allow-a-service-account).
- 프로젝트를 위해 [자체 러너를 구성](../execution/_index.md#configure-runners-to-execute-flows)하거나 [GitLab 호스팅 러너](../../../../ci/runners/hosted_runners/_index.md)를 활성화해야 합니다.

## 스크릿 오탐 탐지 실행 {#running-secret-false-positive-detection}

플로우는 다음 시나리오에서 자동으로 실행됩니다:

- 시크릿 검색 스캔이 기본 브랜치에서 성공적으로 완료됩니다.
- 스캔이 시크릿을 탐지합니다.
- 프로젝트 또는 그룹에서 GitLab Duo 기능이 활성화되어 있습니다.

기존 취약성에 대해 분석을 수동으로 트리거할 수도 있습니다:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **취약점 보고서**를 선택합니다.
1. 분석할 취약성을 선택합니다.
1. 우측 상단 모서리에서 **AI 작업**을 선택한 후 **거짓 양성 점검**을 선택하세요.

## 관련 링크 {#related-links}

- [스크릿 오탐 탐지](../../../application_security/vulnerabilities/secret_false_positive_detection.md).
- [취약성 보고서](../../../application_security/vulnerability_report/_index.md).
- [시크릿 검색](../../../application_security/secret_detection/_index.md).
