---
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Credits의 작동 방식을 이해하고 크레딧 사용량을 확인하세요.
title: GitLab Credits 및 사용 기반 청구
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.7에서 도입되었습니다.
- GitLab Duo Agent Platform 및 GitLab Credits는 GitLab 18.8 이상에서 지원됩니다.
- GitLab 18.11에서 커뮤니티 구독을 위해 도입되었습니다.
- GitLab 19.4에서 Credit 사용 순서가 변경되었습니다.

{{< /history >}}

GitLab Credits는 사용량 기반 청구를 위한 표준화된 소비 통화입니다. Credit는 [GitLab Duo Agent Platform](../user/duo_agent_platform/_index.md)과 일부 비에이전트 [기능](#features)에 사용되며, 각 사용 작업마다 일정한 수의 Credit를 소비합니다.

[GitLab Duo Pro 및 Enterprise](subscription-add-ons.md#gitlab-duo-pro-and-enterprise)와 이에 연결된 [GitLab Duo 기능](../user/gitlab_duo/feature_summary.md)은 사용량 기반으로 청구되지 않으며 GitLab Credits를 소비하지 않습니다.

크레딧은 크레딧 배수 표에 나열된 대로 사용자가 사용하는 기능과 모델을 기반으로 계산됩니다. [정식 출시(GA)](../policy/development_stages_support.md#generally-available) 기능에 대해 요금이 청구됩니다. 일부 릴리스 전 기능도 사용료가 발생합니다. 요금이 적용되면 해당 기능의 설명서 페이지에서 이것을 명시합니다.

청구는 프로젝트 수준이 아닌 루트 네임스페이스 또는 최상위 그룹 수준에서 발생합니다. 크레딧 사용량은 기능을 사용하는 프로젝트에 관계없이 작업을 수행하는 주체에게 귀속됩니다. 주체는 실제 사용자이거나 사람이 아닌 주체(예: 서비스 계정 또는 자동화된 플로우를 실행하는 봇)일 수 있습니다.

루트 네임스페이스 또는 최상위 그룹의 모든 사용량은 청구 목적으로 통합됩니다.

GitLab은 크레딧을 얻는 세 가지 방법을 제공합니다.

- 포함된 크레딧
- 월간 약정 풀
- 온디맨드 크레딧

클릭 방식 데모를 보려면 [GitLab Credits](https://gitlab.navattic.com/credits-dashboard)를 참조하세요.
<!-- Demo published on 2026-01-28 -->

크레딧 가격에 대한 자세한 내용은 [GitLab 요금제](https://about.gitlab.com/pricing/)를 참조하세요.

## Free 티어 {#for-the-free-tier}

{{< details >}}

- 티어:  Free
- 제공 서비스: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab.com에 대해 GitLab 18.10에서 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/20165)되었습니다.
- GitLab 19.0에서 GitLab Self-Managed에 사용으로 설정되었습니다.

{{< /history >}}

Free 티어 사용자는 해당 인스턴스 또는 그룹 네임스페이스에 대한 GitLab Credits의 월간 약정 풀을 구매할 수 있습니다. 이를 통해 Premium 또는 Ultimate 구독 없이도 다양한 [GitLab Duo Agent Platform 기능](../user/duo_agent_platform/_index.md)에 액세스할 수 있습니다.

Free 네임스페이스의 온디맨드 사용량은 매달(역월 기준) 25,000달러($25,000)로 제한됩니다. 이 한도에 도달하면 온디맨드 사용이 자동으로 차단되며, 다음 달 초에 초기화됩니다.

## 포함된 크레딧 {#included-credits}

포함된 크레딧은 Premium 또는 Ultimate 티어의 모든 사용자에게 할당됩니다. 이러한 크레딧은 개인에게 부여되며 사용자 간에 공유할 수 없습니다. 포함된 크레딧은 매월 초에 초기화됩니다. 사용하지 않은 크레딧은 다음 달로 이월되지 않습니다.

[커뮤니티 프로그램 구독](community_programs.md)에는 포함된 크레딧이 제공되지 않습니다.

사람이 아닌 주체에게는 포함된 크레딧이 제공되지 않습니다. 이들의 크레딧 소비는 월간 약정 풀 및 온디맨드 크레딧을 통해 네임스페이스 수준에서 청구되며, 크레딧 사용 순서는 실제 사용자와 동일하게 적용됩니다.

포함된 크레딧에 대한 자세한 내용은 [GitLab 프로모션 이용 약관](https://about.gitlab.com/pricing/terms/)을 참조하세요.

## 임시 평가 크레딧 {#temporary-evaluation-credits}

Monthly Commitment Pool를 구매하지 않았거나 On-Demand Credit의 사용 청구 약관을 수락하지 않았다면, Credit 기반 기능을 평가하기 위해 무료 임시 Credit 풀을 요청할 수 있습니다.

평가를 위해 요청한 사용자 수에 따라 크레딧이 할당되며, 해당 사용자들을 위한 공유 풀에 추가됩니다. 크레딧은 30일 동안 유효하며, 만료된 후에는 사용할 수 없습니다.

크레딧을 요청하려면 [영업팀에 문의하세요](https://about.gitlab.com/sales/).

Free 티어를 사용 중이고 크레딧을 사용해 보려면 [Ultimate 평가판](free_trials.md)을 시작할 수 있습니다.

## 월간 약정 풀 {#monthly-commitment-pool}

월간 약정 풀은 구독 내 모든 사용자가 사용할 수 있는 공유 크레딧 풀입니다. 구독 내 모든 사용자는 포함된 크레딧을 모두 소진한 후 이 공유 풀에서 크레딧을 가져올 수 있습니다.

사용자의 하위 집합에 대해 풀을 예약하거나 특정 사용자, 그룹 또는 프로젝트로 사용량을 격리할 수 없습니다. 개별 사용자의 소비량을 제한하려면 [사용 한도](gitlab_credits_dashboard.md#usage-caps)를 사용하세요.

Monthly Commitment Pool을 구매할 때 사용 청구 약관을 수락합니다.

월간 약정 풀은 연 단위 또는 여러 해 단위 갱신 조건으로 구매할 수 있습니다. 해당 연도에 대해 구매한 크레딧 수를 12로 나눕니다.

예를 들어 월간 약정 풀로 1,000 크레딧을 구매하면, 계약 기간 동안 매월 1,000 크레딧을 사용할 수 있습니다.

사용자는 GitLab 고객 담당 팀을 통해 언제든지 약정을 늘릴 수 있습니다. 추가된 약정은 남은 계약 기간 동안 적용됩니다. 약정은 갱신 시점에만 줄일 수 있습니다.

티어별 할인이 적용된 크레딧 약정을 구매할 수 있습니다. 약정 요금은 계약 기간이 시작될 때 선불로 청구됩니다.

크레딧은 구매 즉시 사용할 수 있으며, 매월 1일에 초기화됩니다. 사용하지 않은 크레딧은 다음 달로 이월되지 않습니다.

## 온디맨드 크레딧 {#on-demand-credits}

온디맨드 크레딧은 포함된 모든 크레딧과 월간 약정 풀의 크레딧을 모두 소진한 이후에 발생한 사용량에 적용됩니다. On-Demand Credit는 월별로 사용한 Credit당 $1의 정가로 청구됩니다.

On-Demand Credit를 사용하려면 사용 청구 약관을 수락해야 합니다.

예를 들어, 구독에 매월 50 크레딧의 월간 약정이 포함되어 있습니다. 해당 월에 75 크레딧이 사용된 경우, 처음 50 크레딧은 월간 약정 풀에서 차감되고 추가된 25 크레딧은 온디맨드 사용량으로 청구됩니다.

## 사용 순서 {#usage-order}

GitLab Credits는 다음 순서로 차감됩니다.

1. 먼저 각 사용자가 포함된 크레딧을 사용합니다.
1. 임시 평가 Credit는 사용자의 포함된 Credit가 소비된 후에 사용됩니다.
1. 크레딧의 월간 약정 풀은 포함된 모든 크레딧이 소비된 후에 사용됩니다.
1. 온디맨드 크레딧은 사용 가능한 다른 모든 크레딧(포함된 크레딧 및 월간 약정 풀(해당하는 경우))이 모두 소진되고 사용량 기반 청구 약관에 서명한 이후에 사용됩니다.

일회성 요금 Credit와 같은 다른 Credit 유형이 구독에 적용될 수 있습니다. 자세한 내용은 계정 담당팀에 문의하세요.

## 사용 청구 약관 {#usage-billing-terms}

Monthly Commitment Pool을 구매할 때 On-Demand Credit 사용을 포함한 사용 청구 약관을 수락합니다. 사용량 기반 청구 약관에 동의하면, 현재 월간 청구 기간에 이미 누적된 모든 온디맨드 요금과 향후 발생하는 모든 온디맨드 요금을 지불하는 데 동의하는 것입니다.

Monthly Commitment Pool을 구매할 때 또는 Customers Portal의 GitLab Credits 대시보드에서 직접 사용 청구 약관을 수락할 수 있습니다.

약관에 동의한 이후 온디맨드 청구는 남은 구독 기간 및 이후의 셀프 서비스 갱신 시에도 활성 상태로 유지되며, 해지할 수 없습니다.

사용 청구 약관을 수락하지 않으면 포함된 Credit과 모든 임시 평가 Credit를 소비할 때까지 Credit 기반 기능을 계속 사용할 수 있습니다.

## GitLab Credits 구매 {#buy-gitlab-credits}

고객 포털에서 월간 약정 풀에 사용할 GitLab Credits를 구매할 수 있습니다.

{{< tabs >}}

{{< tab title="고객 포털" >}}

사전 요구 사항:

- 청구 계정 관리자여야 합니다.

1. [고객 포털](https://customers.gitlab.com/)에 로그인합니다.
1. 관련 구독 카드에서 **GitLab Credits 대시보드**를 선택합니다.
1. **월간 약정 구매** 또는 **월간 약정 늘리기**를 선택합니다.
1. 구매할 크레딧 수를 입력합니다.
1. **주문 검토**를 선택합니다. 크레딧 수량, 고객 정보 및 결제 수단이 정확한지 확인합니다.
1. **주문 확인**을 선택합니다.

{{< /tab >}}

{{< tab title="GitLab.com" >}}

사전 요구 사항:

- 그룹의 소유자 역할이 있어야 합니다.

Premium 및 Ultimate 티어의 경우:

1. 상단 바에서 **검색 또는 이동**을 선택하고 최상위 그룹을 찾습니다.
1. **설정** > **GitLab Credits**를 선택합니다.
1. **월간 약정 구매** 또는 **월간 약정 늘리기**를 선택합니다.
1. 고객 포털 양식에서 구매하려는 크레딧 수를 입력합니다.
1. **주문 검토**를 선택합니다. 크레딧 수량, 고객 정보 및 결제 수단이 정확한지 확인합니다.
1. **주문 확인**을 선택합니다.

Free 티어의 경우:

1. 상단 바에서 **검색 또는 이동**을 선택하고 최상위 그룹을 찾습니다.
1. **설정** > **청구**를 선택합니다.
1. 다음 조건에 해당하는 경우:
   - 평가판을 사용 중이 아닌 경우: GitLab Credits 카드에서 **크레딧 구매** 또는 **크레딧 늘리기**를 선택합니다.
   - 활성 평가판을 사용 중인 경우: GitLab Credits 카드에서 **월간 약정 구매** 또는 **크레딧 늘리기**를 선택합니다.
1. 고객 포털 양식에서 구매하려는 크레딧 수를 입력합니다.
1. **주문 검토**를 선택합니다. 크레딧 수량, 고객 정보 및 결제 수단이 정확한지 확인합니다.
1. **주문 확인**을 선택합니다.

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

사전 요구 사항:

- 관리자 권한이 있어야 합니다.
- 인스턴스가 GitLab과 구독 데이터를 동기화할 수 있어야 합니다.

Premium 및 Ultimate 티어의 경우:

1. 오른쪽 위 모서리에서 **관리자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Credits**를 선택합니다.
1. **월간 약정 구매** 또는 **월간 약정 늘리기**를 선택합니다.
1. 고객 포털 양식에서 구매하려는 크레딧 수를 입력합니다.
1. **주문 검토**를 선택합니다. 크레딧 수량, 고객 정보 및 결제 수단이 정확한지 확인합니다.
1. **주문 확인**을 선택합니다.

Free 티어의 경우:

1. 오른쪽 위 모서리에서 **관리자**를 선택합니다.
1. 왼쪽 사이드바에서 **구독**을 선택합니다.
1. GitLab Credits 카드에서 **크레딧 구매**를 선택합니다.
1. 고객 포털 계정이 없는 경우, 먼저 계정 만들기 단계를 완료합니다. 그런 다음 자격 증명을 사용하여 로그인합니다.
1. 고객 포털 양식에서 구매하려는 크레딧 수를 입력합니다.
1. **주문 검토**를 선택합니다. 크레딧 수량, 고객 정보 및 결제 수단이 정확한지 확인합니다.
1. **주문 확인**을 선택합니다.

{{< /tab >}}

{{< /tabs >}}

보유한 GitLab Credits는 고객 포털의 구독 카드와 GitLab Credits 대시보드에 표시됩니다.

## 크레딧 배수 {#credit-multipliers}

크레딧 사용량은 사용자가 이용하는 기능과 모델을 기준으로 계산됩니다. 일부 기능은 선택할 수 있는 다중 모델 옵션이 제공되는 반면, 다른 기능은 단일 모델만 사용합니다.

요청은 사용자가 시작한 단일 청구 가능 작업(예: 채팅 메시지 전송 또는 코드 생성 요청)을 의미합니다. 사용자의 관점에서 하나의 상호 작용을 나타냅니다.

모델 호출은 사용자 요청을 처리하기 위해 LLM으로 수행되는 백엔드 API 호출을 나타냅니다. 단일 사용자 요청이 여러 번의 모델 호출을 트리거할 수 있습니다. 예를 들어, 컨텍스트를 이해하기 위한 호출 한 번과 응답을 생성하기 위한 또 다른 호출이 발생할 수 있습니다.

### 모델 {#models}

다음 표는 다양한 [모델](../user/duo_agent_platform/model_selection.md)에 대해 1 GitLab Credit으로 수행할 수 있는 LLM 호출 횟수를 보여줍니다. 더 새롭고 복잡한 모델일수록 배수가 높으며 더 많은 크레딧을 요구합니다.

모델 사용 요금은 다음 청구 방식에 따라 부과됩니다.

- GitLab 관리형 모델의 가변 가격 책정: 하나의 요청은 단일 LLM 호출과 같습니다. 하나의 플로우는 한 번 또는 여러 번의 호출을 수행합니다. 크레딧 비용은 사용된 모델에 따라 달라집니다.
- 자체 호스팅 모델의 가변 가격 책정: 하나의 요청은 단일 LLM 호출과 같습니다. 하나의 플로우는 한 번 또는 여러 번의 호출을 수행합니다. [지원되거나](../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) [호환되는](../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models) 모든 자체 호스팅 모델의 경우 1개 크레딧으로 8개의 요청을 수행할 수 있습니다.
- GitLab Duo 기능의 정액 가격 책정:  엔드투엔드 실행이 소비될 때마다 실행 중에 수행된 LLM 호출 수(GitLab 관리형 및 자체 호스팅 모델 포함)에 관계없이 미리 설정된 크레딧 양이 차감됩니다. 자체 호스팅 모델에서 실행되는 기능은 실행을 위해 소비된 크레딧에 대해 20% 할인을 받습니다.
- 실패한 실행에 대한 크레딧 차감은 제공 서비스에 따라 다릅니다.
  - GitLab.com에 GitLab 관리 모델에서는 완료되기 전에 실패한 플로우는 일부 LLM 호출이 이미 수행되었더라도 크레딧이 차감되지 않습니다.
  - GitLab Self-Managed에 자체 호스팅 모델에서 정액 요금을 사용하지 않는 기능의 경우 청구는 플로우 완료가 아닌 개별 LLM 호출을 기반으로 합니다. 각 호출은 시작할 때 계산되므로 플로우가 실패하기 전에 수행한 호출은 여전히 청구됩니다. 즉, 중간에 실패한 플로우는 이미 시작된 호출에 대한 크레딧을 계속 소비할 수 있습니다. 정액 가격 책정 기능의 경우 실제로 수행된 LLM 호출의 수와 관계없이 플로우가 실패하더라도 전체 정액 요금이 청구됩니다.

기본 통합이 제공되는 보조 모델의 경우:

| 모델 | 1개 크레딧으로 호출 수 |
|-------|------------------------|
| `claude-3-haiku` | 8.0 |
| `codestral-2501` | 8.0 |
| `gemini-2.5-flash` | 8.0 |
| `gpt-5-mini` | 8.0 |
| `gpt-5-4-nano` | 8.0 |

최적화된 통합이 있는 프리미엄 모델의 경우:

| 모델 | 1개 크레딧으로 호출 수 |
|-------|------------------------|
| `gpt-5.6-luna` | 8.0 |
| `minimax-m3` | 8.0 |
| `claude-4.5-haiku` | 6.7 |
| `gemini-3.6-flash` <sup>1</sup> | 6.7 |
| `gemini-3.7-flash` <sup>1</sup> | 6.7 |
| `gemini-3.8-flash` <sup>1</sup> | 6.7 |
| `gpt-5-4-mini` | 6.7 |
| `glm-5.3` | 5.0 |
| `gemini-3.5-flash` | 3.3 |
| `gpt-5` | 3.3 |
| `gpt-5-codex` | 3.3 |
| `claude-sonnet-5` | 3.2 |
| `gpt-5.2` | 2.5 |
| `gpt-5.2-codex` | 2.5 |
| `gpt-5.3-codex` | 2.5 |
| `gpt-5.6-terra` <sup>3</sup> | 2.5 |
| `claude-3.5-sonnet` | 2.0 |
| `claude-3.7-sonnet` | 2.0 |
| `claude-sonnet-4.5` | 2.0 |
| `claude-sonnet-4.6` | 2.0 |
| `gpt-5.4` <sup>3</sup> | 2.0 |
| `kimi-k3` | 1.82 |
| `gpt-5.6-terra` <sup>4</sup> | 1.43 |
| `gpt-5.6-sol` <sup>2</sup> <sup>3</sup> | 1.33 |
| `claude-opus-4.5` | 1.2 |
| `gpt-5.4` <sup>4</sup> | 1.11 |
| `claude-opus-4.6` | 1.1 |
| `claude-opus-4.7` | 1.1 |
| `claude-opus-4.8` | 1.1 |
| `claude-opus-5` | 1.1 |
| `gpt-5.5` <sup>3</sup> | 1.0 |
| `gpt-5.6-sol` <sup>4</sup> | 0.76 |
| `claude-fable-5` | 0.6 |
| `claude-fable-5.1` | 0.6 |
| `gpt-5.5` <sup>4</sup> | 0.57 |
| `gpt-6-astra` <sup>3</sup> | 0.54 |
| `gpt-6-astra` <sup>4</sup> | 0.31 |

**각주**:

1. 2026년 12월 31일까지 프로모션 요금이 적용됩니다. 이후에 요금은 대략 크레딧당 3.3개 호출로 변경됩니다.
1. 2026년 11월 21일까지 GPT-5.6 Sol의 프로모션 가격입니다. 그 이후로는 단축 컨텍스트 윈도우의 경우 대략 Credit당 1.0 호출, 긴 컨텍스트 윈도우의 경우 0.57로 변경됩니다.
1. 최대 272,000개 토큰의 짧은 컨텍스트 기간입니다.
1. 272,000개 이상의 토큰의 긴 컨텍스트 기간입니다.

### 기능 {#features}

{{< history >}}

- GitLab 19.1에서 `self_hosted_flat_pricing_discount`라는 [기능 플래그](../administration/feature_flags/_index.md)로 자체 호스팅 모델 할인이 도입되었습니다.

{{< /history >}}

> [!flag]
> 자체 호스팅 모델 할인의 사용 가능성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

다음 표는 각 기능별로 1개 GitLab Credit으로 수행할 수 있는 실행 수를 보여줍니다. 이 가격 책정은 해당 기능에 사용할 수 있는 모든 모델(자체 호스팅 모델 포함)에 적용됩니다.

[자체 호스팅 모델](../administration/gitlab_duo_self_hosted/_index.md)에서 실행되는 기능은 20% 할인을 받습니다.

| 기능 | 한 크레딧으로 실행(GitLab 관리 모델) | 한 크레딧으로 실행(자체 호스팅 모델) |
|---------|----------------------------|------------------------------------------------|
| GitLab Duo Code Suggestions | 50 | 62.5 |
| Code Review 플로우 | 4 | 5 |
| SAST False Positive Detection 플로우 | 1 | 1.25 |
| SAST Vulnerability Resolution 플로우 | 0.25 | 0.3125 |

GitLab Duo Agentic Chat의 경우, 질문에 답하기 위해 하나 이상의 LLM 호출이 발생하므로 보낸 메시지 하나가 하나 이상의 청구 가능 요청으로 계산됩니다. 하나의 대화창에 여러 메시지가 포함될 수 있으며, 이에 따라 여러 번의 청구 가능 요청이 발생할 수 있습니다. 가격은 선택한 모델에 따라 달라집니다.

다음 기능도 Credit를 소비하지만 다른 소비 모델로 작동합니다:

- [GitLab Secrets Manager](../ci/secrets/secrets_manager/credit_usage.md)
- [GitLab Dedicated의 호스팅된 러너](../administration/dedicated/hosted_runners.md#usage-cap-exemptions)
