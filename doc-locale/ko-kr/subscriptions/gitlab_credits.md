---
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Credits이 어떻게 작동하는지 이해하고 크레딧 사용량을 확인합니다.
title: GitLab Credits 및 사용 기반 결제
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.7에서 도입되었습니다.
- GitLab Duo AI 에이전트 플랫폼 및 GitLab Credits는 GitLab 18.8 이상에서 지원됩니다.
- GitLab 18.11에서 커뮤니티 구독에 도입되었습니다.

{{< /history >}}

GitLab Credits은 사용 기반 결제를 위한 표준화된 소비 통화입니다. 크레딧은 [GitLab Duo Agent Platform](../user/duo_agent_platform/_index.md)에 사용되며, 각 사용 작업은 일정한 수의 크레딧을 소비합니다.

[GitLab Duo Pro 및 Enterprise](subscription-add-ons.md#gitlab-duo-pro-and-enterprise) 및 관련된 [GitLab Duo 기능](../user/gitlab_duo/feature_summary.md)은 사용 기반으로 청구되지 않으며 GitLab Credits을 소비하지 않습니다.

크레딧은 사용하는 기능과 모델을 기반으로 계산되며, 크레딧 배수 표에 나열되어 있습니다. [일반 공개](../policy/development_stages_support.md#generally-available) 상태인 기능에 대해 청구됩니다.

청구는 프로젝트 수준이 아니라 루트 네임스페이스 또는 최상위 그룹 수준에서 발생합니다. 크레딧 사용량은 사용 중인 프로젝트에 관계없이 작업을 수행하는 주체에게 귀속됩니다. 주체는 인간 사용자 또는 비인간 주체(예: 서비스 계정 또는 자동화된 플로우를 실행하는 봇)입니다.

루트 네임스페이스 또는 최상위 그룹의 모든 사용량은 청구 목적으로 통합됩니다.

GitLab은 크레딧을 얻는 세 가지 방법을 제공합니다:

- 포함된 크레딧
- 월별 약정 풀
- 온디맨드 크레딧

클릭을 통한 데모를 보려면 [GitLab Credits](https://gitlab.navattic.com/credits-dashboard)을 참조합니다.
<!-- Demo published on 2026-01-28 -->

크레딧 가격 정보를 보려면 [GitLab 가격 책정](https://about.gitlab.com/pricing/)을 참조합니다.

## 포함된 크레딧 {#included-credits}

포함된 크레딧은 Premium 또는 Ultimate 계층의 모든 사용자에게 할당됩니다. 이러한 크레딧은 개별적이며 사용자 간에 공유할 수 없습니다. 포함된 크레딧은 매월 초에 재설정됩니다. 미사용 크레딧은 다음 달로 이월되지 않습니다.

[커뮤니티 프로그램 구독](community_programs.md)은 포함된 크레딧을 받지 않습니다.

비인간 주체는 포함된 크레딧을 받지 않습니다. 이들의 소비는 월별 약정 풀 및 온디맨드 크레딧에서 인간 사용자와 동일한 사용 순서로 네임스페이스 수준에서 청구됩니다.

포함된 크레딧에 대한 자세한 내용은 [GitLab 홍보 약관 및 조건](https://about.gitlab.com/pricing/terms/)을 참조합니다.

## 월별 약정 풀 {#monthly-commitment-pool}

월별 약정 풀은 구독 내 모든 사용자가 사용할 수 있는 공유 크레딧 풀입니다. 구독의 모든 사용자는 포함된 크레딧을 모두 소비한 후 이 공유 풀에서 인출할 수 있습니다.

월별 약정 풀을 반복되는 연간 또는 다년 기간으로 구매할 수 있습니다. 연간 구매한 크레딧 수는 12로 나눕니다.

예를 들어 월별 약정 풀 1,000 크레딧을 구매하면 계약 기간 동안 매달 1,000 크레딧을 사용할 수 있습니다.

GitLab 계정 팀을 통해 언제든지 약정을 증가할 수 있습니다. 추가 약정은 계약 기간의 나머지 기간에 적용됩니다. 약정은 갱신 시점에만 감소할 수 있습니다.

내장된 계층화된 할인이 있는 크레딧 약정을 구매할 수 있습니다. 약정은 계약 기간의 시작에 선결제됩니다.

크레딧은 구매 후 즉시 사용 가능하며 매달 1일에 재설정됩니다. 미사용 크레딧은 다음 달로 이월되지 않습니다.

> [!note]
> 월별 약정 풀을 구매할 때 온디맨드 크레딧 사용을 포함한 사용 청구 약관을 수락합니다. 약관을 수락한 후 온디맨드 청구는 구독의 나머지 기간 및 후속 셀프 서비스 갱신에 대해 활성 상태로 유지되며 옵트아웃할 수 없습니다.

## 온디맨드 크레딧 {#on-demand-credits}

온디맨드 크레딧은 포함된 모든 크레딧과 월별 약정 풀의 크레딧을 모두 사용한 후 발생한 사용량을 대금으로 청구합니다. 온디맨드 크레딧은 월별로 청구됩니다.

온디맨드 크레딧은 사용한 크레딧당 $1의 정가로 소비됩니다.

사용 청구 약관을 수락한 후 온디맨드 크레딧을 사용할 수 있습니다. 월별 약정을 구매할 때 이러한 약관을 수락하거나 Customers Portal의 GitLab Credits 대시보드에서 직접 수락할 수 있습니다. 사용 청구 약관을 수락하면 현재 월별 청구 기간에 이미 누적된 모든 온디맨드 요금과 향후 발생할 온디맨드 요금을 지불하는 데 동의합니다.

사용 청구 약관을 수락하지 않으면 GitLab Duo Agent Platform을 사용하고 온디맨드 크레딧을 소비할 수 없습니다. 월별 약정을 구매하거나 사용 청구 약관을 수락하여 GitLab Duo Agent Platform에 다시 액세스할 수 있습니다.

예를 들어 구독에 월별 약정이 매달 50 크레딧입니다. 해당 월에 75 크레딧을 사용한 경우 처음 50 크레딧은 월별 약정 풀의 일부이고 추가 25 크레딧은 온디맨드 사용으로 청구됩니다.

## 사용 순서 {#usage-order}

GitLab Credits은 다음 순서로 소비됩니다:

1. 포함된 크레딧은 먼저 각 사용자가 사용합니다.
1. 포함된 모든 크레딧을 소비한 후 월별 약정 풀 크레딧을 사용합니다.
1. 다른 모든 사용 가능 크레딧(포함된 크레딧 및 월별 약정 풀, 해당하는 경우)을 모두 소비한 후 사용 청구 약관에 서명한 후 온디맨드 크레딧을 사용합니다.

## 임시 평가 크레딧 {#temporary-evaluation-credits}

월별 약정 풀을 구매하지 않았거나 온디맨드 크레딧에 대한 사용 청구 약관을 수락하지 않은 경우 GitLab Duo Agent Platform 기능을 평가하기 위해 무료 임시 크레딧 풀을 요청할 수 있습니다.

크레딧은 평가를 위해 요청한 사용자 수를 기반으로 할당되며 해당 사용자의 공유 풀에 추가됩니다. 크레딧은 30일 동안 유효하며 만료 후에는 사용할 수 없습니다.

크레딧을 요청하려면 [영업팀에 문의합니다](https://about.gitlab.com/sales/).

Free 계층에 있고 크레딧을 시도하려면 [Ultimate 평가판](free_trials.md)을 시작할 수 있습니다.

## Free 계층 {#for-the-free-tier}

{{< details >}}

- 계층:  Free
- 제공:  GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab.com의 GitLab 18.10에서 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/20165)되었습니다.
- GitLab 19.0에서 GitLab Self-Managed에서 활성화되었습니다.

{{< /history >}}

Free 계층의 사용자는 인스턴스 또는 그룹 네임스페이스에 대한 월별 약정 풀 GitLab Credits을 구매할 수 있습니다. 이는 Premium 또는 Ultimate 구독이 필요 없이 [GitLab Duo Agent Platform 기능](../user/duo_agent_platform/_index.md)의 집합에 액세스할 수 있도록 합니다.

Free 네임스페이스에 대한 온디맨드 사용은 각 달력 월당 $25,000으로 제한됩니다. 이 제한에 도달하면 온디맨드 사용이 자동으로 꺼지고 다음 달의 시작 시 재설정됩니다.

## GitLab Credits 구매 {#buy-gitlab-credits}

Customers Portal에서 월별 약정 풀에 대한 GitLab Credits을 구매할 수 있습니다.

{{< tabs >}}

{{< tab title="Customers Portal" >}}

전제 조건:

- 청구 계정 관리자여야 합니다.

1. [Customers Portal](https://customers.gitlab.com/)에 로그인합니다.
1. 관련 구독 카드에서 **GitLab Credits 대시보드**를 선택합니다.
1. **매달 구매 확인** 또는 **Increase monthly commitment**를 선택합니다.
1. 구매하려는 크레딧 수를 입력합니다.
1. **Review order**를 선택합니다. 크레딧 수, 고객 정보 및 결제 수단이 올바른지 확인합니다.
1. **Confirm purchase**을 선택합니다.

{{< /tab >}}

{{< tab title="GitLab.com" >}}

전제 조건:

- 그룹에 대한 소유자 역할이 있어야 합니다.

Premium 및 Ultimate 계층에서:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 최상위 그룹을 찾습니다.
1. **설정** > **GitLab Credits**을 선택합니다.
1. **매달 구매 확인** 또는 **Increase monthly commitment**를 선택합니다.
1. Customers Portal 양식에서 구매하려는 크레딧 수를 입력합니다.
1. **Review order**를 선택합니다. 크레딧 수, 고객 정보 및 결제 수단이 올바른지 확인합니다.
1. **Confirm purchase**을 선택합니다.

Free 계층에서:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 최상위 그룹을 찾습니다.
1. **설정** > **결제**를 선택합니다.
1. 다음의 경우:
   - 평가판에 없습니다:  GitLab Credits 카드에서 **크레딧 구매** 또는 **크레딧 늘리기**를 선택합니다.
   - 활성 평가판에 있습니다:  GitLab Credits 카드에서 **매달 구매 확인** 또는 **크레딧 늘리기**를 선택합니다.
1. Customers Portal 양식에서 구매하려는 크레딧 수를 입력합니다.
1. **Review order**를 선택합니다. 크레딧 수, 고객 정보 및 결제 수단이 올바른지 확인합니다.
1. **Confirm purchase**을 선택합니다.

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

전제 조건:

- 관리자여야 합니다.
- 인스턴스가 GitLab으로 구독 데이터를 동기화할 수 있어야 합니다.

Premium 및 Ultimate 계층에서:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Credits**을 선택합니다.
1. **매달 구매 확인** 또는 **Increase monthly commitment**를 선택합니다.
1. Customers Portal 양식에서 구매하려는 크레딧 수를 입력합니다.
1. **Review order**를 선택합니다. 크레딧 수, 고객 정보 및 결제 수단이 올바른지 확인합니다.
1. **Confirm purchase**을 선택합니다.

Free 계층에서:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **구독**을 선택합니다.
1. GitLab Credits 카드에서 **크레딧 구매**를 선택합니다.
1. Customers Portal 계정이 없으면 먼저 계정을 생성하는 단계를 완료합니다. 그런 다음 자격 증명을 사용하여 로그인합니다.
1. Customers Portal 양식에서 구매하려는 크레딧 수를 입력합니다.
1. **Review order**를 선택합니다. 크레딧 수, 고객 정보 및 결제 수단이 올바른지 확인합니다.
1. **Confirm purchase**을 선택합니다.

{{< /tab >}}

{{< /tabs >}}

GitLab Credits은 Customers Portal의 구독 카드 및 GitLab Credits 대시보드에 표시됩니다.

## 크레딧 배수 {#credit-multipliers}

크레딧 사용량은 사용하는 기능과 모델을 기반으로 계산됩니다. 일부 기능은 여러 모델 옵션이 있고 다른 기능은 하나의 모델만 사용합니다.

요청은 사용자가 시작한 단일(청구 가능) 작업(예: 채팅 메시지 보내기 또는 코드 생성 요청)을 나타냅니다. 이는 사용자의 관점에서 하나의 상호 작용을 나타냅니다.

모델 호출은 사용자 요청을 처리하기 위해 LLM에 대한 기본 API 호출을 나타냅니다. 단일 사용자 요청은 여러 모델 호출을 트리거할 수 있습니다. 예를 들어 컨텍스트를 이해하기 위한 한 호출과 응답을 생성하기 위한 다른 호출입니다.

### 모델 {#models}

다음 표는 다양한 [모델](../user/duo_agent_platform/model_selection.md)에 대해 하나의 GitLab Credits으로 만들 수 있는 LLM 호출 수를 나열합니다. 더 새롭고 복잡한 모델은 더 높은 배수를 가지며 더 많은 크레딧이 필요합니다.

모델 사용에 대한 요금은 다음 청구 방법을 기반으로 합니다:

- GitLab 관리 모델의 변수 가격 책정:  요청은 단일 LLM 호출과 동일합니다. 한 플로우는 하나 또는 많은 호출을 수행합니다. 크레딧 비용은 사용된 모델에 따라 다릅니다.
- 자체 호스팅 모델의 변수 가격 책정:  요청은 단일 LLM 호출과 동일합니다. 한 플로우는 하나 또는 많은 호출을 수행합니다. 지원되거나 호환되는 모든 자체 호스팅 모델에 대해 [지원](../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) 또는 [호환](../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models) 하나의 크레딧으로 8개의 요청을 수행할 수 있습니다.
- GitLab Duo 기능의 정액 가격 책정:  각 성공적인 end-to-end 실행은 실행 중에 수행된 LLM 호출 수(GitLab 관리 및 자체 호스팅 모델)에 관계없이 사전 설정된 크레딧 양을 소비합니다.

완료된 호출 또는 실행만 청구됩니다. 호출 또는 실행이 실패하면 크레딧이 차감되지 않습니다.

기본 통합이 있는 보조 모델의 경우:

| 모델 | 한 크레딧으로 호출 |
|-------|------------------------|
| `claude-3-haiku` | 8.0 |
| `codestral-2501` | 8.0 |
| `gemini-2.5-flash` | 8.0 |
| `gpt-5-mini` | 8.0 |
| `gpt-5-4-nano` | 8.0 |

최적화된 통합이 있는 프리미엄 모델의 경우:

| 모델 | 한 크레딧으로 호출 |
|-------|------------------------|
| `claude-4.5-haiku` | 6.7 |
| `gpt-5-4-mini` | 6.7 |
| `gpt-5-codex` | 3.3|
| `gpt-5` | 3.3 |
| `gpt-5.2` | 2.5 |
| `gpt-5.2-codex` | 2.5 |
| `gpt-5.3-codex` | 2.5 |
| `claude-3.5-sonnet` | 2.0 |
| `claude-3.7-sonnet` | 2.0 |
| `claude-sonnet-4` | 2.0 |
| `claude-sonnet-4.5` | 2.0 |
| `claude-sonnet-4.6` | 2.0 |
| `claude-opus-4.5` | 1.2 |
| `claude-opus-4.6`  | 1.1 |
| `claude-opus-4.7` | 1.1 |

### 기능 {#features}

다음 표는 서로 다른 기능에 대해 하나의 GitLab Credits으로 수행할 수 있는 실행 수를 나열합니다. 이 가격은 기능에 사용할 수 있는 모든 모델(자체 호스팅 모델 포함)에 적용됩니다.

| 기능 | 한 크레딧으로 실행 |
|---------|---------------------------|
| [GitLab Duo 코드 제안](../user/duo_agent_platform/code_suggestions/_index.md) | 50 |
| Code Review 플로우 | 4 |
| SAST False Positive Detection 플로우 | 1 |
| SAST Vulnerability Resolution 플로우 | 0.25 |

GitLab Duo Agentic Chat의 경우 보낸 메시지 하나는 질문에 답하기 위해 하나 이상의 LLM 호출이 수행되므로 하나 이상의 청구 가능 요청으로 계산됩니다. 한 대화 창에는 여러 메시지가 포함될 수 있으므로 여러 청구 가능 요청이 포함됩니다. 가격은 선택한 모델에 따라 다릅니다.

## GitLab Credits 대시보드 {#gitlab-credits-dashboard}

{{< details >}}

- 제공:  GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.7에서 도입되었습니다.
- 정렬 결과 [GitLab 18.10에 도입](https://gitlab.com/groups/gitlab-org/-/work_items/21008)되었습니다.

{{< /history >}}

GitLab Credits 대시보드는 GitLab Credits 사용에 대한 정보를 표시합니다. 대시보드를 사용하여 크레딧 소비를 모니터링하고, 추세를 추적하고, 사용 패턴을 식별합니다.

크레딧 소비 관리를 돕기 위해 GitLab은 다음 정보를 관리자 및 구독 소유자에게 이메일로 보냅니다:

- 월별 크레딧 사용량 요약
- 크레딧 사용량이 50%, 80%, 100%에 도달했을 때 알림

Customers Portal 및 GitLab에서 대시보드에 액세스할 수 있습니다.

> [!note]
> 사용량 데이터는 실시간으로 표시되지 않습니다. 데이터는 주기적으로 대시보드와 동기화되므로 사용량 데이터는 실제 소비 후 몇 시간 내에 나타나야 합니다. 이는 대시보드가 최근 사용량을 표시하지만 지난 몇 시간 내에 수행된 작업을 반영하지 않을 수 있음을 의미합니다.

### Customers Portal {#in-customers-portal}

Customers Portal의 GitLab Credits 대시보드는 사용량 및 비용에 대한 가장 자세한 보기를 제공합니다.

대시보드에서 사용한 크레딧은 사용 가능한 크레딧에서 차감된 것을 나타냅니다. 초과 요금(온디맨드 크레딧)의 경우 사용한 크레딧은 사용 청구 약관에 동의한 경우 나중에 지불할 온디맨드 사용을 나타냅니다.

대시보드는 주요 메트릭의 요약 카드를 표시합니다:

- 현재 월 사용량:  현재 월에 사용된 총 GitLab Credits(월별 약정이 있는 경우)
- 포함된 크레딧:  구독에 포함된 총 크레딧(월별 약정이 있는 경우)
- 약정된 크레딧:  월별 약정 풀의 크레딧(해당하는 경우)
- 월별 면제:  면제의 남은 크레딧(해당하는 경우)
- 온디맨드 사용:  포함된 금액과 약정된 금액을 초과하여 소비된 크레딧입니다. 충분한 면제 크레딧이 있어 모든 온디맨드 크레딧을 상쇄할 수 있으면 GitLab Credits 대시보드는 **On-Demand** 카드를 숨기고 **월별 면제** 카드를 대신 표시합니다.
- 사용 제어 상태:  사용자별 크레딧 상한에 도달하여 Agent Platform 액세스가 차단되었는지 여부입니다.

### GitLab {#in-gitlab}

> [!note]
> 이 대시보드는 청구 불가능한 베타 및 실험 기능을 포함한 모든 GitLab Duo Agent Platform 기능의 사용을 표시합니다. 청구 가능한 사용만 보려면 Customers Portal에서 대시보드를 봅니다.

GitLab의 GitLab Credits 대시보드는 조직의 크레딧 사용에 대한 운영 가시성을 제공합니다. 대시보드를 사용하여 어떤 사용자, 그룹 또는 프로젝트가 사용을 이끌고 있는지 이해하고 리소스 할당에 대한 정보 기반 결정을 내립니다.

대시보드는 다음 정보를 표시합니다:

- **Organization usage**:  GitLab 인스턴스 또는 그룹의 총 크레딧 사용량
- **Total credit consumption**:  모든 제품에 대한 일일 크레딧 소비, 막대 차트로 표시됨
- **사용자별 사용량**:  각 사용자가 사용한 크레딧 수
- **User drill-down view**:  각 사용자의 개별 사용 이벤트, GitLab Duo Agent Platform 세션 세부 정보로의 링크 포함

### GitLab Credits 대시보드 보기 {#view-the-gitlab-credits-dashboard}

{{< history >}}

- 과거 사용 기간 선택 [GitLab 18.11에 도입](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/15910)되었습니다.

{{< /history >}}

{{< tabs >}}

{{< tab title="Customers Portal" >}}

전제 조건:

- 자세한 사용량 정보를 보려면 청구 계정 관리자여야 합니다.

1. [Customers Portal](https://customers.gitlab.com/)에 로그인합니다.
1. 구독 카드에서 **GitLab Credits 대시보드**를 선택합니다.
1. 선택사항. 이전 월을 보려면 **Usage period** 드롭다운 목록에서 보려는 기간을 선택합니다.
1. 선택사항. **사용자** 또는 **사용된 총 크레딧**으로 결과를 정렬하려면 해당 열을 선택합니다.

{{< /tab >}}

{{< tab title="GitLab.com" >}}

전제 조건:

- 그룹에 대한 소유자 역할이 있어야 합니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 최상위 그룹을 찾습니다.
1. **설정** > **GitLab Credits**을 선택합니다.
1. 선택사항. **사용자** 또는 **사용된 총 크레딧**으로 결과를 정렬하려면 해당 열을 선택합니다.

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

전제 조건:

- 관리자여야 합니다.
- 인스턴스가 GitLab으로 구독 데이터를 동기화할 수 있어야 합니다.

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Credits**을 선택합니다.
1. 선택사항. **사용자** 또는 **사용된 총 크레딧**으로 결과를 정렬하려면 해당 열을 선택합니다.

{{< /tab >}}

{{< /tabs >}}

기본적으로 개별 사용자 데이터는 GitLab Credits 대시보드에 표시되지 않습니다. 표시하려면 [그룹](../user/group/manage.md#display-gitlab-credits-user-data) 또는 [인스턴스](../administration/settings/visibility_and_access_controls.md#display-gitlab-credits-user-data)에 대해 이 설정을 활성화해야 합니다.

### 비인간 주체 사용 {#non-human-subject-usage}

{{< history >}}

- GitLab 19.0에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/596238).

{{< /history >}}

크레딧 소비는 인간 사용자 또는 비인간 주체(예: SAST False Positive Detection 플로우와 같은 AI 기능)에 의해 트리거될 수 있습니다.

크레딧이 소비되는 위치를 식별하는 데 도움이 되도록 GitLab Credits 대시보드의 **사용자별 사용량** 탭에는 비인간 주체를 나타내는 행 옆에 **자동화된 플로우** 배지가 표시됩니다. 배지가 없는 행은 인간 사용자를 나타냅니다.

**자동화된 플로우** 배지의 표시는 **GitLab Credits 사용자 데이터 표시** 설정에 의해 제어되며, [그룹](../user/group/manage.md#display-gitlab-credits-user-data) 및 [인스턴스](../administration/settings/visibility_and_access_controls.md#display-gitlab-credits-user-data)에 사용할 수 있습니다.

### 사용 제한 {#usage-caps}

{{< details >}}

- 상태:  베타

{{< /details >}}

{{< history >}}

- GitLab 18.11에서 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/19881) 됨 [기능 플래그](../administration/feature_flags/_index.md)가 있는 `budget_caps_graphql_api`이름. 기본적으로 활성화됨.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그에 의해 제어됩니다. 자세한 내용은 기록을 참조하세요.

월별 GitLab Credits 상한을 구독 및 사용자 수준에서 설정하여 예상치 못한 초과 요금을 방지할 수 있습니다. 크레딧 소비가 구성된 상한에 도달하면 GitLab Credits(예: GitLab Duo Agent Platform)을 소비하는 기능에 대한 액세스가 다음 청구 기간이 시작될 때까지 또는 관리자가 상한을 조정하거나 비활성화할 때까지 자동으로 일시 중단됩니다.

다음 상한 유형을 사용할 수 있습니다:

| 상한 유형 | 적용 대상 | 계산된 크레딧 원본 | 관리 수단 |
|---|---|---|---|
| 구독 상한 | 구독의 모든 사용자 | 온디맨드만 | Customers Portal |
| 정액 사용자 상한 | 개별 사용자(기본 제한) | 모두 | GraphQL API |
| 사용자별 재정의 | 특정 사용자(정액 상한 재정의) | 모두 | GraphQL API |

현재 청구 기간의 온디맨드 사용이 구성된 상한에 도달하거나 초과하면 모든 Agent Platform 기능(Duo Chat, 코드 제안, 플로우 및 에이전트)이 해당 구독 또는 인스턴스의 모든 사용자에 대해 일시 중단됩니다. 사용자 수준 상한의 경우 상한에 도달한 개별 사용자만 일시 중단됩니다.

상한에 도달한 사용자는 상한이 올라가거나 다음 청구 기간이 시작될 때까지 Agent Platform 기능에 액세스할 수 없습니다.

사용 카운터는 각 청구 기간의 시작에 자동으로 재설정됩니다. 상한 값은 변경되지 않는 한 청구 기간 전체에서 유지됩니다.

상한은 사용 가능한 최신 사용량 데이터를 사용하여 적용됩니다. 데이터가 실시간이 아니므로 강제 적용이 적용되기 전에 제한된 추가 GitLab Credits 사용이 발생할 수 있습니다.

구독 온디맨드 사용이 구성된 상한에 도달하면 GitLab은 청구 계정 관리자에게 이메일 알림을 보냅니다.

#### 구독 수준 사용 상한 설정 {#set-a-subscription-level-usage-cap}

전제 조건:

- 청구 계정 관리자여야 합니다.

1. [Customers Portal](https://customers.gitlab.com/)에 로그인합니다.
1. 구독 카드에서 **GitLab Credits 대시보드**를 선택합니다.
1. **On-demand Credit Cap** 패널에서 **Monthly On-demand Credits cap** 토글을 켭니다.
1. 청구 기간당 허용되는 최대 온디맨드 GitLab Credits 수를 입력합니다.
1. **저장**을 선택합니다.

현재 청구 기간에 대해 현재 보고된 총 온디맨드 사용량 아래로 상한을 설정한 경우 다음 강제 적용 확인에서 상한이 즉시 도달한 것으로 간주됩니다.

상한을 비활성화하려면 **Monthly On-demand Credits cap** 토글을 끕니다. 비활성화되면 구독 수준의 온디맨드 GitLab Credits 상한이 적용되지 않으며 동작이 기존 청구 동작으로 되돌아갑니다.

GraphQL API를 사용하여 [사용 상한 보기](../api/graphql/reference/_index.md#gitlabsubscriptionbudgetcaps) 및 [정액 사용자 수준 상한](../api/graphql/reference/_index.md#mutationupsertflatusercap) 또는 [사용자별 재정의 상한](../api/graphql/reference/_index.md#mutationupsertuserbudgetcapoverrides)을 설정할 수 있습니다.

### 사용 제어 상태 {#usage-control-status}

{{< history >}}

- GitLab 18.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/594635)되었습니다.

{{< /history >}}

사용자별 크레딧 상한이 활성화되면 GitLab Credits 대시보드의 **사용자별 사용량** 탭에 **Usage control status** 열이 표시됩니다. 이 열은 각 사용자가 [GitLab Duo Agent Platform](../user/duo_agent_platform/_index.md) 기능에 액세스할 수 있는지 또는 크레딧 상한에 도달하여 차단되었는지 여부를 보여줍니다.

열에는 다음 상태 중 하나가 표시됩니다:

| 상태 | 설명 |
|--------|-------------|
| **일반** | 사용자가 크레딧 상한에 도달하지 않았으며 GitLab Duo Agent Platform 기능을 사용할 수 있습니다. |
| **Blocked - subscription cap reached** | 사용자가 구독 수준에서 설정한 정액 사용자별 상한에 도달했습니다. |
| **Blocked - user cap reached** | 사용자가 특별히 해당 사용자를 위해 설정한 사용자별 재정의 상한에 도달했습니다. |

#### 크레딧 상한에 도달한 사용자 차단 해제 {#unblock-a-user-who-reached-their-credit-cap}

사용자별 재정의 GraphQL API를 사용하여 차단된 사용자에 대한 액세스를 복원할 수 있습니다.

사용자의 차단을 해제하려면 다음 중 하나를 수행합니다:

- 상한 증가:  사용자의 사용량이 새 제한 아래로 떨어지도록 더 높은 사용자별 재정의 상한을 설정합니다.
- 상한 제거:  사용자별 재정의를 삭제하여 사용자가 더 이상 개별 상한의 영향을 받지 않도록 합니다.

상한을 업데이트한 후 사용자의 상태가 **일반**으로 변경되고 GitLab Duo Agent Platform 기능을 다시 사용할 수 있습니다.

### 사용자 크레딧 사용량 세부 정보 보기 {#view-user-credit-usage-details}

{{< history >}}

- GitLab Duo Agent Platform 세션 세부 정보로 연결 [GitLab 18.10에 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/579139)되었습니다.

{{< /history >}}

드릴다운 보기에서 사용자의 개별 사용 이벤트를 보려면:

1. GitLab Credits 대시보드에서 **사용자별 사용량** 탭을 선택합니다.
1. **사용자** 열에서 보려는 사용자를 선택합니다.
1. 세션 세부 정보를 보려면 **조치** 열에서 보려는 작업을 선택합니다.

> [!note]
> 세션 링크는 프로젝트에서 트리거되고 관련 세션 ID가 있는 GitLab Duo Agent Platform 사용 이벤트에만 사용할 수 있습니다. 그룹에서 트리거된 사용 이벤트, 레거시 이벤트 및 Agent Platform 외부의 작업에는 링크가 없습니다.

### 사용량 데이터 내보내기 {#export-usage-data}

{{< history >}}

- GitLab 18.10에서 [도입](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/14504)되었습니다.

{{< /history >}}

Customers Portal에서 구독의 크레딧 사용 데이터를 CSV 파일로 내보낼 수 있습니다. CSV 파일은 현재 월의 각 날짜에 사용된 사용 이벤트 및 크레딧을 나열합니다.

전제 조건:

- 청구 계정 관리자여야 합니다.

1. [Customers Portal](https://customers.gitlab.com/)에 로그인합니다.
1. 구독 카드에서 **GitLab Credits 대시보드**를 선택합니다.
1. **Usage period** 드롭다운 목록에서 데이터를 내보낼 기간을 선택합니다.
1. **Export usage data**를 선택합니다.
