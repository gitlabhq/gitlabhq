---
stage: Fulfillment
group: Subscription Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "사용량, 컴퓨팅 분, 저장소 제한, 갱신 정보."
gitlab_dedicated: yes
title: GitLab 구독 문제 해결
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab 구독을 구매하거나 사용할 때 다음과 같은 문제가 발생할 수 있습니다.

## 결제 및 카드 문제 {#payment-and-card-issues}

### 오류: 신용카드 거절 {#error-credit-card-declined}

GitLab 구독을 구매할 때 신용카드가 거절될 수 있는 이유는 다음과 같습니다:

- 신용카드 세부 정보가 잘못되었습니다. 이 문제의 가장 일반적인 원인은 불완전하거나 가짜 주소입니다.
- 신용카드 계정에 자금이 부족합니다.
- 신용카드가 만료되었습니다.
- 거래 금액이 신용한도 또는 카드의 최대 거래 금액을 초과합니다.
- [거래가 허용되지 않습니다](#error-transaction_not_allowed).

금융 기관에 확인하여 이러한 이유 중 해당하는 사항이 있는지 확인하세요. 해당 사항이 없으면 [GitLab 지원팀](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293)에 문의하세요.

#### 오류: `transaction_not_allowed` {#error-transaction_not_allowed}

GitLab 구독을 구매할 때 다음과 같은 오류가 표시될 수 있습니다:

```plaintext
Transaction declined.402 - [card_error/card_declined/transaction_not_allowed]
Your card does not support this type of purchase.
```

이 오류는 귀사가 수행하는 거래 유형이 카드 발급사에 의해 제한됨을 의미합니다. 이는 귀사의 계정을 보호하도록 설계된 보안 조치입니다.

거래가 다음과 같은 하나 이상의 이유로 거절될 수 있습니다:

- 귀사의 카드가 인도에서 발급되었고 거래가 [RBI의 전자 위임장 규칙](https://www.rbi.org.in/Scripts/NotificationUser.aspx?Id=12051&Mode=0)을 준수하지 않습니다.
- 귀사의 카드가 온라인 구매에 대해 활성화되지 않았습니다.
- 귀사의 카드에는 특정 사용 제한이 있습니다. 예를 들어 현지 거래만으로 제한된 직불카드입니다.
- 거래가 귀사의 은행 보안 프로토콜을 트리거합니다.

이 문제를 해결하려면 다음을 시도하세요:

- 인도에서 발급된 카드의 경우: 인증된 현지 리셀러를 통해 거래를 처리하세요. 인도의 다음 GitLab 파트너 중 하나에 문의하세요:
  - [Datamato Technologies Private Limited](https://about.gitlab.com/partners/channel-partners/#/1345598)
  - [FineShift Software Private Limited](https://about.gitlab.com/partners/channel-partners/#/1737250)
- 미국 외부에서 발급된 카드의 경우: 카드가 국제 거래에 사용 가능하도록 설정되어 있는지 확인하고 국가별 제한이 있는지 확인하세요.
- 금융 기관에 문의하세요: 거래가 거절된 이유를 물어보고 이러한 유형의 거래에 대해 카드가 활성화되도록 요청하세요.

#### 오류: `Attempt_Exceed_Limitation` {#error-attempt_exceed_limitation}

GitLab 구독을 구매할 때 `Attempt_Exceed_Limitation - Attempt exceed the limitation, refresh page to try again.` 오류가 나타날 수 있습니다.

이 문제는 신용카드 양식이 1분 내에 3회 또는 1시간 내에 6회 재제출될 때 발생합니다. 이 문제를 해결하려면 몇 분 기다린 후 구매를 다시 시도하세요.

## 인증 및 계정 문제 {#authentication-and-account-issues}

### 오류: `must be authenticated to make a purchase` {#error-must-be-authenticated-to-make-a-purchase}

계정에 로그인하지 않은 상태에서 구매를 시도할 때 이 오류가 표시될 수 있습니다.

이 문제를 해결하려면 구독 구매를 시도하기 전에 GitLab 계정에 로그인하세요.

### 오류: Customers Portal 계정에 나열된 구매가 없습니다 {#error-no-purchases-listed-in-the-customers-portal-account}

Customers Portal의 **Subscriptions & purchases** 페이지에서 구매를 보려면 구독 조직의 연락처로 추가되어야 합니다.

연락처로 추가되려면 [GitLab 지원팀에 티켓을 생성하세요](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293).

## 네임스페이스 및 구독 연결 문제 {#namespace-and-subscription-linking-issues}

### 오류: `GitLab namespace is required` {#error-gitlab-namespace-is-required}

구매 프로세스 중에 GitLab 네임스페이스가 지정되지 않았을 때 이 오류가 표시될 수 있습니다.

이 문제를 해결하려면 구매를 진행하기 전에 유효한 GitLab 네임스페이스를 선택했는지 확인하세요.

### 오류: `Unable to link subscription to namespace` {#error-unable-to-link-subscription-to-namespace}

GitLab.com에서 구독을 네임스페이스에 연결할 수 없으면 권한이 부족할 수 있습니다. 해당 네임스페이스에 대해 소유자 역할을 가지고 있으며 [전송 제한](../manage_subscription.md#transfer-restrictions)을 검토했는지 확인하세요.

### 오류: `Subscription not found` {#error-subscription-not-found}

존재하지 않거나 찾을 수 없는 구독을 수정하려고 할 때 이 오류가 표시될 수 있습니다.

이 이슈를 해결하려면:

- 올바른 구독 ID 또는 이름을 사용하고 있는지 확인하세요.
- 구독이 귀사의 계정에 있는지 확인하세요.
- 수정하려는 구독에 액세스할 수 있는지 확인하세요.

계속 문제가 발생하면 [GitLab 지원팀](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293)에 문의하세요.

## 구매 중 네임스페이스 유효성 검사 오류 {#namespace-validation-errors-during-purchase}

GitLab.com에서 GitLab 구독을 구매할 때 구매를 완료할 수 없도록 하는 네임스페이스 유효성 검사 오류가 발생할 수 있습니다.

### 오류: `GitLab namespace is not valid` {#error-gitlab-namespace-is-not-valid}

네임스페이스가 다음인 경우 이 오류가 표시될 수 있습니다:

- 구매 URL에 지정되지 않았습니다.
- GitLab.com에 존재하지 않습니다.
- 귀사의 사용자 계정이 소유하지 않습니다.
- 최상위 그룹이 아닙니다(하위 그룹 또는 프로젝트입니다).
- 청구 가능한 구성원이 없습니다.

이 이슈를 해결하려면:

- 네임스페이스가 존재하고 [소유자 역할](../../user/permissions.md#roles)을 가지고 있는지 확인하세요. 기존 소유자에게 귀사를 추가해 달라고 요청하세요.
- 네임스페이스가 최상위 그룹인지 확인하세요. 구독을 하위 그룹이나 프로젝트에 적용할 수 없으며, 대신 상위 그룹에 구독을 적용하세요.
- [네임스페이스에 최소 하나의 청구 가능한 사용자가 있는지 확인하세요](../manage_seats.md#billable-users). 필요한 경우 구성원을 추가하세요.
- 구매 URL에 올바른 `gl_namespace_id` 매개변수가 포함되어 있는지 확인하세요(예: `?gl_namespace_id=123`).

위의 단계를 시도한 후에도 계속 문제가 발생하면 [GitLab 지원팀](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293)에 문의하세요.

### 오류: `Subscription does not belong to GitLab namespace` {#error-subscription-does-not-belong-to-gitlab-namespace}

수정하려는 구독이 구매 URL에 지정한 네임스페이스에 속하지 않을 때 이 오류가 표시될 수 있습니다.

이 이슈를 해결하려면:

- 올바른 구독 ID 또는 이름을 사용하고 있는지 확인하세요.
- URL의 네임스페이스가 구독을 소유한 네임스페이스와 일치하는지 확인하세요.
- 구독을 연결할 네임스페이스를 변경해야 하면 [전송 제한](../manage_subscription.md#transfer-restrictions)을 검토하세요.

위의 단계를 시도한 후에도 계속 문제가 발생하면 [GitLab 지원팀](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293)에 문의하세요.

## 제품 및 추가 기능 문제 {#product-and-add-on-issues}

### 오류: `Product is required` {#error-product-is-required}

구매 프로세스 중에 제품이 지정되지 않았을 때 이 오류가 표시될 수 있습니다.

이 문제를 해결하려면 구매를 진행하기 전에 제품을 선택했는지 확인하세요.

### 오류: `cannot purchase more product through the Customers Portal` {#error-cannot-purchase-more-product-through-the-customers-portal}

구독 추가 기능(예: 추가 사용자, 컴퓨팅 분, 저장소 또는 GitLab Duo Pro)을 구매할 때 이 오류가 표시될 수 있습니다.

활성 구독이 있을 때 이 문제가 발생합니다:

- [리셀러를 통해 구매](../billing_account.md#subscription-purchased-through-a-reseller)했습니다.
- 다년간 구독입니다.

이 문제를 해결하려면 귀사의 [GitLab 영업 담당자](https://customers.gitlab.com/contact_us)에게 문의하여 지원을 받으세요.

### 오류: `Product is not available in this purchase flow` {#error-product-is-not-available-in-this-purchase-flow}

구매하려는 제품을 셀프 서비스 구매 흐름을 통해 사용할 수 없을 때 이 오류가 표시될 수 있습니다.

다음과 같은 이유로 발생할 수 있습니다:

- 제품에는 특수한 구성이나 승인이 필요합니다.
- 제품은 직접 영업을 통해서만 사용 가능합니다.
- 귀사의 계정이 이 제품의 요구 사항을 충족하지 않습니다.

이 문제를 해결하려면 귀사의 [GitLab 영업 담당자](https://customers.gitlab.com/contact_us)에게 문의하여 구매 지원을 받으세요.

#### 오류: `Product is not available for sale through the Customers Portal` {#error-product-is-not-available-for-sale-through-the-customers-portal}

다음과 같은 경우 이 오류가 표시될 수 있습니다:

- 제품 가격 책정 계획에는 셀프 서비스 구매 흐름에서 지원하지 않는 여러 청구가 있습니다.
- 제품 가격 책정 계획은 셀프 서비스 구매에 사용할 수 없습니다.

이 문제를 해결하려면 귀사의 [GitLab 영업 담당자](https://customers.gitlab.com/contact_us)에게 문의하여 지원을 받으세요.

## 배포 및 구성 문제 {#deployment-and-configuration-issues}

### 오류: `The deployment type of the purchase does not match your subscription's deployment type` {#error-the-deployment-type-of-the-purchase-does-not-match-your-subscriptions-deployment-type}

지정한 배포 유형이 구매하려는 제품과 일치하지 않을 때 이 오류가 표시될 수 있습니다.

이 이슈를 해결하려면:

- 배포 유형에 적합한 올바른 제품을 구매하고 있는지 확인하세요.
  - GitLab.com 구독은 다중 테넌트 SaaS 배포를 위한 것입니다.
  - GitLab Self-Managed 구독은 온프레미스 또는 프라이빗 클라우드 배포를 위한 것입니다.
- 배포 유형에 적합한 올바른 구매 URL을 사용하고 있는지 확인하세요.
- 다른 배포 유형의 구독이 필요하면 올바른 제품으로 새 구매를 시작하세요.

## 인프라 및 동기화 문제 {#infrastructure-and-synchronization-issues}

### 오류: 구독 데이터 동기화 실패 {#error-subscription-data-fails-to-synchronize}

GitLab Self-Managed 또는 GitLab Dedicated에서 구독 데이터가 동기화되지 않을 수 있습니다. GitLab 인스턴스와 특정 IP 주소 간의 네트워크 트래픽이 허용되지 않을 때 이 문제가 발생할 수 있습니다.

이 문제를 해결하려면 GitLab 인스턴스에서 IP 주소 `172.64.146.11:443` 및 `104.18.41.245:443`(`customers.gitlab.com`)로의 네트워크 트래픽을 허용하세요.

자세한 내용은 [연결 문제 해결](../../administration/license.md#error-cannot-activate-instance-due-to-a-connectivity-issue)을 참조하세요.
