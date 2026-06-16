---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "중앙 카탈로그에서 에이전트와 플로우를 발견하고, 활성화하고, 관리합니다."
title: AI 카탈로그
---

{{< details >}}

- 계층:  [무료](../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="모델 정보" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /collapsible >}}

{{< history >}}

- GitLab 18.5에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/549914) [플래그 포함](../../administration/feature_flags/_index.md) `global_ai_catalog` GitLab.com에서 [실험](../../policy/development_stages_support.md)으로 활성화됨
- 외부 에이전트 지원이 GitLab 18.6에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207610) `ai_catalog_third_party_flows` 플래그 포함 GitLab.com에서 [실험](../../policy/development_stages_support.md)으로 활성화됨
- GitLab 18.7에서 베타로 [변경됨](https://gitlab.com/gitlab-org/gitlab/-/issues/568176)
- GitLab 18.8에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)합니다.
- 기능 플래그 `global_ai_catalog` 18.10에서 [제거됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/223135)
- GitLab 18.10에서 GitLab.com의 무료 티어에서 GitLab Credits를 사용하여 사용 가능합니다.

{{< /history >}}

AI 카탈로그는 에이전트와 플로우의 중앙 목록입니다. 이러한 에이전트와 플로우를 프로젝트에 추가하여 에이전트 AI 작업을 오케스트레이션하기 시작합니다.

AI 카탈로그를 사용하여:

- GitLab 팀 및 커뮤니티 멤버가 만든 에이전트와 플로우를 발견합니다.
- 사용자 지정 에이전트와 플로우를 만들고 다른 사용자와 공유합니다.
- 프로젝트에서 에이전트와 플로우를 활성화하여 GitLab Duo Agent Platform 전체에서 사용합니다.

## AI 카탈로그 보기 {#view-the-ai-catalog}

{{< history >}}

- GitLab Duo 사이드바를 사용하여 AI 카탈로그를 보는 기능이 GitLab 18.11에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/592493)

{{< /history >}}

전제 조건:

- [GitLab Duo Agent Platform 필수 조건](_index.md#prerequisites)을 충족하세요.
- GitLab Self-Managed에서 [인스턴스에 대해 GitLab Duo를 활성화](turn_on_off.md#for-an-instance)합니다.
- AI 카탈로그에서 에이전트와 플로우를 활성화하려면:
  - 그룹에서는 Maintainer 또는 Owner 역할이 있어야 합니다.
  - 프로젝트에서는 Maintainer 또는 Owner 역할이 있어야 합니다.

AI 카탈로그를 보려면 다음 중 하나를 수행할 수 있습니다:

- 상단 표시줄 사용:
  1. 상단 표시줄에서 **검색 또는 이동** > **탐색**을 선택합니다.
  1. **AI 카탈로그**를 선택합니다.

- GitLab Duo 사이드바 사용:
  1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
  1. GitLab Duo 사이드바에서 **GitLab Duo AI 카탈로그** ({{< icon name="tanuki-ai" >}})를 선택합니다.

에이전트 목록이 표시됩니다.

GitLab Self-Managed에서는 다음 에이전트가 AI 카탈로그에 표시되지 않습니다:

- GitLab.com에서 만든 사용자 지정 에이전트
- [인스턴스에 추가](agents/external.md#add-gitlab-managed-agents-to-other-instances)되지 않은 GitLab 관리형 외부 에이전트

사용 가능한 플로우를 보려면 **플로우** 탭을 선택합니다.

## 에이전트 및 플로우 버전 {#agent-and-flow-versions}

{{< history >}}

- GitLab 18.7에서 [도입됨](https://gitlab.com/groups/gitlab-org/-/epics/20022)

{{< /history >}}

AI 카탈로그의 각 사용자 지정 에이전트 및 플로우는 버전 기록을 유지합니다. 항목의 구성을 변경하면 GitLab이 자동으로 새 버전을 만듭니다. 기본 에이전트 및 플로우는 버전 관리를 사용하지 않습니다.

GitLab은 시멘틱 버전 관리를 사용하여 변경의 범위를 나타냅니다. 예를 들어, 에이전트는 `1.0.0` 또는 `1.1.0` 같은 버전 번호를 가질 수 있습니다. GitLab은 시멘틱 버전 관리를 자동으로 관리합니다. 에이전트 또는 플로우에 대한 업데이트는 항상 부 버전을 증가시킵니다.

버전 관리는 프로젝트 및 그룹이 안정적이고 테스트된 에이전트 또는 플로우 구성을 계속 사용하도록 합니다. 이는 예기치 않은 변경이 워크플로우에 영향을 미치는 것을 방지합니다.

### 버전 생성 {#creating-versions}

GitLab은 다음을 수행할 때 버전을 만듭니다:

- 사용자 지정 에이전트의 시스템 프롬프트를 업데이트합니다.
- 외부 에이전트 또는 플로우의 구성을 수정합니다.

일관된 동작을 보장하기 위해 버전은 변경 불가능합니다.

### 버전 고정 {#version-pinning}

{{< history >}}

- 에이전트 또는 플로우를 관리하는 프로젝트가 항상 해당 항목의 최신 버전을 사용합니다. GitLab 18.10에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/583024)

{{< /history >}}

AI 카탈로그 항목을 활성화할 때:

- 그룹에서 GitLab은 최신 버전을 고정합니다.
- 해당 항목을 관리하지 않는 프로젝트에서 GitLab은 프로젝트의 최상위 그룹과 같은 버전을 고정합니다.

버전 고정은 다음을 의미합니다:

- 프로젝트 또는 그룹이 항목의 고정된 버전을 사용합니다.
- AI 카탈로그의 에이전트 또는 플로우 업데이트는 구성에 영향을 주지 않습니다.
- 새 버전을 채택할 시기를 제어합니다.

이 접근 방식은 AI 기반 워크플로우의 안정성과 예측 가능성을 제공합니다.

AI 카탈로그 항목을 관리하는 프로젝트에서 활성화하면 GitLab은 버전을 고정하지 않습니다. 대신 관리자 프로젝트는 항상 항목의 최신 버전을 사용합니다.

GitLab 18.10 이전에 관리자 프로젝트에서 에이전트 또는 플로우를 활성화한 경우 구성은 고정된 버전에 남아 있습니다.

처음으로 최신 버전으로 업데이트한 후 GitLab은 그 이후로 자동으로 최신 버전을 사용합니다.

### 현재 버전 보기 {#view-the-current-version}

전제 조건:

- Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

에이전트 또는 플로우의 현재 버전을 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 다음 중 하나를 선택합니다:
   - **AI** > **에이전트**
   - **AI** > **플로우**
1. 에이전트 또는 플로우를 선택하여 세부 정보를 봅니다.

세부 정보 페이지에 다음이 표시됩니다:

- 프로젝트 또는 그룹이 사용 중인 고정된 버전
- 버전 식별자 예를 들어, `1.2.0`.
- 해당 특정 버전의 구성에 대한 세부 정보

### 최신 버전으로 업데이트 {#update-to-the-latest-version}

전제 조건:

- Maintainer 또는 Owner 역할이 있어야 합니다.

그룹 또는 프로젝트가 에이전트 또는 플로우의 최신 버전을 사용하도록 하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 다음 중 하나를 선택합니다:
   - **AI** > **에이전트**
   - **AI** > **플로우**
1. 업데이트할 에이전트 또는 플로우를 선택합니다.
1. 최신 버전을 주의 깊게 검토합니다. 업데이트하려면 **가장 최신 버전 보기** > **업데이트 `<x.y.z>`**를 선택합니다.

## AI 카탈로그를 그룹 계층 구조로 제한 {#restrict-the-ai-catalog-to-a-group-hierarchy}

{{< details >}}

- 제공:  GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 19.0에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/594617).

{{< /history >}}

최상위 그룹에서 AI 카탈로그를 제한할 수 있으므로 해당 그룹 계층 구조의 프로젝트에 대해 사용자는 다음만 보고, 활성화하고, 실행할 수 있습니다:

- GitLab에서 유지하는 기본 에이전트 및 플로우
- 동일한 최상위 그룹 계층 구조의 프로젝트가 소유한 공개 에이전트 및 플로우
- 프로젝트 자체가 소유한 비공개 에이전트 및 플로우

계층 구조 외부의 프로젝트가 소유한 에이전트 및 플로우는:

- AI 카탈로그에서 숨겨집니다.
- 활성화하지 못하도록 차단됩니다.
- 프로젝트가 이전에 활성화했더라도 실행하지 못하도록 차단됩니다.

최상위 그룹에서만 이 설정을 구성할 수 있습니다. 해당 계층 구조의 모든 프로젝트에 적용됩니다. 이 설정에 대한 변경 사항은 감사 로그에 기록됩니다.

전제 조건:

- 최상위 그룹에 대한 소유자 역할이 있어야 합니다.

AI 카탈로그를 그룹 계층 구조로 제한하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 최상위 그룹을 찾습니다.
1. **설정** > **GitLab Duo**를 선택합니다.
1. **구성 변경**을(를) 선택합니다.
1. **데이터와 개인정보 보호** 섹션에서 **AI 카탈로그** 아래 **Restrict the AI Catalog to this group** 확인란을 선택합니다.
1. **변경사항 저장**을 선택합니다.

## 관련 항목 {#related-topics}

- [에이전트](agents/_index.md)
- [외부 에이전트](agents/external.md)
