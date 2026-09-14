---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 에이전트 기반 주요 변경사항 해결
description: 종속성을 업데이트하는 머지 리퀘스트의 문제에 대한 AI 기반 해결방안입니다.
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.2에서 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/17884)되었으며, [베타](../../../policy/development_stages_support.md#beta) 기능으로 [기능 플래그](../../../administration/feature_flags/_index.md) `enable_dependency_bump_breaking_changes`와 `dependency_bump_web_search`를 사용합니다.

{{< /history >}}

에이전트 기반 주요 변경사항 해결은 옵트인 기본 플로우로 다음 기능을 수행합니다:

- 종속성을 업데이트하는 머지 리퀘스트의 실패한 파이프라인을 분석합니다.
- 종속성 업데이트로 인한 주요 변경사항을 해결하는 수정 사항을 생성합니다.

> [!warning]
> 이 기능이 활성화되면, 영향을 받은 머지 리퀘스트의 파이프라인 로그 및 코드 컨텍스트가 분석을 위해 대규모 언어 모델(LLM)에 전송됩니다. 이 기능을 활성화하기 전에 조직의 데이터 정책을 검토하세요.

이 기본 플로우에서 GitLab Duo는 다음을 수행합니다:

- 파이프라인 오류 로그를 분석하여 실패의 근본 원인을 파악합니다.
- 종속성 변경 로그 및 릴리스 정보를 분석하여 주요 변경사항을 식별합니다.
- 업데이트된 종속성의 코드 사용 패턴을 검토합니다.
- 코드 수정 사항을 생성하고 종속성 범핑 MR 브랜치에 직접 커밋합니다.
- 수정 사항을 적용한 후 파이프라인을 다시 실행합니다.

결과는 AI 분석을 기반으로 하며, 병합 전에 개발자가 검토해야 합니다.

## 전제 조건 {#prerequisites}

- 프로젝트 또는 그룹에서 [GitLab Duo 활성화](../../gitlab_duo/turn_on_off.md).
- 사용자 기본 설정에서 [기본 GitLab Duo 네임스페이스 설정](../../profile/preferences.md#set-a-default-gitlab-duo-namespace).
- [종속성 검사 자동 수정](../remediate/auto_remediation.md)이 프로젝트에서 활성화되어 있습니다. 에이전트 기반 주요 변경사항 해결은 자동 수정이 생성하는 종속성 범핑 머지 리퀘스트에 적용됩니다.

## 에이전트 기반 주요 변경사항 해결 활성화 {#enable-agentic-breaking-change-resolution}

이 기능은 기본적으로 비활성화되어 있으며, 그룹 및 프로젝트 수준 모두에서 명시적으로 활성화해야 합니다.

### 최상위 그룹에서 이 기본 플로우 활성화 {#turn-on-this-foundational-flow-in-a-top-level-group}

그룹의 모든 프로젝트가 기본 플로우를 사용하도록 허용하려면 다음을 수행하세요:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. **설정** > **GitLab Duo**를 선택합니다.
1. **파운데이셔널 플로우 허용** 아래에서 **버전 변경에 따른 종속성 범핑 문제를 해결** 체크박스를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

### 특정 프로젝트에서 이 기본 플로우 활성화 {#turn-on-this-foundational-flow-for-a-project}

전제 조건:

- 프로젝트에 대한 Maintainer 또는 Owner 역할.
- 최상위 그룹에서 활성화된 기본 플로우입니다.

특정 프로젝트에서 에이전트 기반 주요 변경사항 해결을 활성화하려면 다음을 수행하세요:

1. 왼쪽 사이드바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. **설정** > **일반**을 선택합니다.
1. **GitLab Duo**를 확장합니다.
1. **Turn on AI-powered resolution of dependency bump breaking changes** 토글을 켭니다.
1. **변경 사항 저장**을 선택합니다.

## 플로우 트리거 {#trigger-the-flow}

플로우를 자동으로 또는 수동으로 트리거할 수 있습니다.

### 자동 트리거 {#automatic-trigger}

플로우는 다음 경우에 자동으로 실행됩니다:

- 자동 수정 에이전트가 생성한 종속성 범핑 머지 리퀘스트에서 파이프라인이 실패합니다.
- 기능이 프로젝트에서 활성화되어 있습니다.
- GitLab Duo 기능이 프로젝트 또는 그룹에서 활성화되어 있습니다.

분석은 백그라운드에서 실행됩니다. 완료되면, 생성된 모든 수정 사항이 머지 리퀘스트 브랜치에 커밋되고 파이프라인이 다시 실행됩니다.

### 수동 트리거 {#manual-trigger}

실패한 파이프라인이 있는 머지 리퀘스트(종속성을 범핑하는)에서 에이전트 기반 주요 변경사항 해결을 수동으로 트리거하려면 다음을 수행하세요:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택합니다.
1. 실패한 파이프라인이 있는 종속성 범핑 머지 리퀘스트를 선택합니다.
1. 파이프라인 위젯에서 **Duo로 주요 변경사항 해결**을 선택합니다.

플로우는 백그라운드에서 실행됩니다. 완료되면, MR 브랜치에 생성된 모든 수정 사항을 커밋하고 파이프라인을 다시 실행합니다.

## 피드백 제공 {#provide-feedback}

[피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/work_items/605189)에서 피드백을 공유하세요.

## 관련 항목 {#related-topics}

- [에이전트 기반 주요 변경사항 해결 기본 플로우](../../duo_agent_platform/flows/foundational_flows/agentic-breaking-change-resolution.md)
- [종속성 검사 자동 수정](../remediate/auto_remediation.md)
- [종속성 검사](_index.md)
- [GitLab Duo Agent Platform](../../duo_agent_platform/_index.md)
- [GitLab Duo](../../gitlab_duo/_index.md)
