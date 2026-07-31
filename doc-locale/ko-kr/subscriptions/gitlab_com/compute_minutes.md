---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab.com의 그룹 및 개인 네임스페이스를 위한 추가 컴퓨팅 시간 구매, 월별 이월 및 문제 해결 포함"
title: 추가 컴퓨팅 시간 구매
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

[컴퓨팅 시간](../../ci/pipelines/compute_minutes.md)은 GitLab.com 인스턴스 러너에서 [CI/CD 파이프라인](../../ci/_index.md)을 실행할 때 소비되는 리소스입니다. [GitLab 가격 책정 페이지](https://about.gitlab.com/pricing/#compute-minutes)에서 추가 컴퓨팅 시간의 가격을 확인할 수 있습니다.

추가 컴퓨팅 시간:

- 구독에 포함된 월간 할당량이 소진된 후에만 사용됩니다.
- 월말에 남은 부분이 있으면 [다음 달로 이월](#monthly-rollover-of-purchased-compute-minutes)됩니다.
- 구매 날짜로부터 12개월 동안 유효하며, 이전에 소비되지 않은 경우입니다.
- 컴퓨팅 시간의 만료가 아직 적용되지 않으므로 만료 날짜 이후에도 사용할 수 있습니다. 그러나 GitLab은 만료 날짜 이후에도 컴퓨팅 시간이 유효하게 유지될 것을 보장하지 않습니다.
- 평가판 구독에서 구매한 컴퓨팅 시간은 평가판이 끝나거나 유료 요금제로 업그레이드한 후에 사용할 수 있습니다.
- 구독 티어를 변경할 때 사용 가능한 상태로 유지되며, 유료 티어 간 변경 또는 Free 티어로의 변경을 포함합니다.

## 그룹용 컴퓨팅 시간 구매 {#purchase-compute-minutes-for-a-group}

그룹에 추가 컴퓨팅 시간을 구매할 수 있습니다. 구매한 컴퓨팅 시간을 한 그룹에서 다른 그룹으로 이전할 수 없으므로 올바른 그룹을 선택했는지 확인하세요.

전제 조건:

- 그룹에 대한 소유자 역할이 있거나 결제 계정 관리자여야 합니다.
- 결제 계정이 그룹의 네임스페이스 구독에 연결되어 있어야 합니다.

그룹용 컴퓨팅 시간을 구매하려면:

{{< tabs >}}

{{< tab title="그룹 소유자" >}}

1. GitLab.com에 로그인합니다.
1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **사용 할당량**을 선택합니다.
1. **파이프라인**을 선택합니다.
1. **추가 컴퓨팅 시간 구매**를 선택합니다. Customers Portal로 이동합니다.
1. **구독 세부정보** 섹션의 **Quantity** 필드에 원하는 컴퓨팅 시간 팩 수량을 입력합니다.
1. **Customer information** 섹션에서 주소를 확인합니다.
1. **Billing information** 섹션에서 드롭다운 목록에서 결제 방법을 선택합니다.
1. **개인정보 보호정책** 및 **Terms of Service** 확인란을 선택합니다.
1. **컴퓨팅 시간 구매**를 선택합니다.

{{< /tab >}}

{{< tab title="결제 계정 관리자" >}}

1. [Customers Portal](https://customers.gitlab.com/customers/sign_in)로 이동합니다.
1. 구독 카드에서 세로 줄임표({{< icon name="ellipsis_v" >}})를 선택한 다음 **추가 컴퓨팅 시간 구매**를 선택합니다.
1. **구독 세부정보** 섹션의 **Quantity** 필드에 원하는 컴퓨팅 시간 팩 수량을 입력합니다.
1. **Customer information** 섹션에서 주소를 확인합니다.
1. **Billing information** 섹션에서 드롭다운 목록에서 결제 방법을 선택합니다.
1. **개인정보 보호정책** 및 **Terms of Service** 확인란을 선택합니다.
1. **컴퓨팅 시간 구매**를 선택합니다.

{{< /tab >}}

{{< /tabs >}}

결제가 처리된 후 추가 컴퓨팅 시간이 그룹 네임스페이스에 추가됩니다. 추가 컴퓨팅 시간은 [**사용 할당량** 페이지](../../ci/pipelines/instance_runner_compute_minutes.md#view-usage-for-a-group)에 **추가 컴퓨팅 시간**으로 표시됩니다.

## 개인 네임스페이스용 컴퓨팅 시간 구매 {#purchase-compute-minutes-for-a-personal-namespace}

개인 네임스페이스에 추가 컴퓨팅 시간을 구매하려면:

1. GitLab.com에 로그인합니다.
1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택합니다.
1. 왼쪽 사이드바에서 **사용 할당량**을 선택합니다.
1. **추가 컴퓨팅 시간 구매**를 선택합니다. Customers Portal로 이동합니다.
1. **구독 세부정보** 섹션에서 드롭다운 목록에서 사용자 이름을 선택합니다.
1. 원하는 컴퓨팅 시간 팩 수량을 입력합니다.
1. **Customer information** 섹션에서 주소를 확인합니다.
1. **Billing information** 섹션에서 드롭다운 목록에서 결제 방법을 선택합니다.
1. **개인정보 보호정책** 및 **Terms of Service** 확인란을 선택합니다.
1. **컴퓨팅 시간 구매**를 선택합니다.

결제가 처리된 후 추가 컴퓨팅 시간이 개인 네임스페이스에 추가됩니다. 추가 컴퓨팅 시간은 [**사용 할당량** 페이지](../../ci/pipelines/instance_runner_compute_minutes.md#view-usage-for-a-personal-namespace)에 **추가 컴퓨팅 시간**으로 표시됩니다.

## 구매한 컴퓨팅 시간의 월별 이월 {#monthly-rollover-of-purchased-compute-minutes}

추가 컴퓨팅 시간을 구매하고 전체 금액을 사용하지 않으면 남은 금액이 다음 달로 이월됩니다. 추가 컴퓨팅 시간은 일회성 구매이며 매월 갱신되거나 새로 고쳐지지 않습니다.

예를 들어 월간 할당량이 10,000 컴퓨팅 시간인 경우:

- 4월 1일에 5,000 추가 컴퓨팅 시간을 구매하면 4월에 15,000분을 사용할 수 있습니다.
- 4월 동안 13,000분을 사용하면 5,000 추가 컴퓨팅 시간 중 3,000을 사용하게 됩니다.
- 5월 1일에 [월간 할당량이 재설정](../../ci/pipelines/instance_runner_compute_minutes.md#monthly-reset)되고 사용하지 않은 컴퓨팅 시간이 이월됩니다. 따라서 2,000 추가 컴퓨팅 시간이 남아 있고 5월에 총 12,000분을 사용할 수 있습니다.

## 문제 해결 {#troubleshooting}

### 오류: `Last name can't be blank` {#error-last-name-cant-be-blank}

컴퓨팅 시간을 구매할 때 "성이 비어 있을 수 없습니다" 오류가 나타날 수 있습니다. 이 문제는 프로필의 **이름** 필드에서 성이 누락되었을 때 발생합니다.

이 문제를 해결하려면:

- 사용자 프로필에 성이 입력되어 있는지 확인합니다:

  1. 오른쪽 위 모서리에서 아바타를 선택합니다.
  1. **프로필 편집**을 선택합니다.
  1. **이름** 필드를 이름과 성 모두를 포함하도록 업데이트한 후 변경 사항을 저장합니다.

- 브라우저 캐시와 쿠키를 지우고 구매 프로세스를 다시 시도합니다.
- 오류가 계속되면 다른 웹 브라우저 또는 시크릿/비공개 검색 창을 사용해 봅니다.

### 오류: `Attempt_Exceed_Limitation - Attempt exceed the limitation, refresh page to try again` {#error-attempt_exceed_limitation---attempt-exceed-the-limitation-refresh-page-to-try-again}

컴퓨팅 시간을 구매할 때 `Attempt_Exceed_Limitation - Attempt exceed the limitation, refresh page to try again.` 오류가 나타날 수 있습니다.

이 문제는 신용카드 양식이 너무 빠르게 다시 제출될 때(1분 안에 3번 또는 1시간 안에 6번 제출) 발생합니다.

이 문제를 해결하려면 몇 분 기다린 후 구매 프로세스를 다시 시도합니다.
