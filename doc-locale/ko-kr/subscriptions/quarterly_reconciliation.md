---
stage: Fulfillment
group: Subscription Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab 구독에 대한 사용자 초과 시 청구 프로세스를 이해합니다.
title: 사용자 초과 시 청구
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab 구독에 구매한 사용자 수보다 청구 가능한 사용자가 더 많으면 추가 사용자에 대한 요금이 청구됩니다.

[GitLab 구독 계약](https://about.gitlab.com/terms/)에 따라 GitLab은 사용자 사용 현황을 검토하고 분기별(분기 조정 프로세스) 또는 연간(연간 확정 프로세스)으로 초과분에 대한 청구서를 보냅니다.

- **Quarterly reconciliation**: 구독 기간의 남은 기간에 대해 분기별로 비례하여 청구됩니다. 분기 중 사용한 최대 사용자 수에 대해 비용을 지불합니다. 연간 비용이 적게 들어 상당한 절감액을 얻을 수 있습니다.
- **Annual true-up**: 연중 언제든지 추가된 사용자에 대해 전체 연간 구독료를 지불합니다.

다음에 대해 자세히 알아보세요:

- [사용자 사용 현황이 결정되는 방식](manage_seats.md#gitlabcom-billing-and-usage)을 GitLab.com에서 확인하세요.
- [GitLab이 사용자에 대해 청구하는 방식](manage_seats.md#self-managed-billing-and-usage)을 GitLab Self-Managed에서 확인하세요.

초과를 방지하려면 [그룹](../user/group/manage.md#turn-on-restricted-access) 또는 [인스턴스](../administration/settings/sign_up_restrictions.md#turn-on-restricted-access)에 대해 제한된 액세스를 켤 수 있습니다. 이 설정은 구독에 남은 사용자가 없을 때 그룹이 새로운 청구 가능한 사용자를 추가하는 것을 제한합니다.

## 예 {#example}

예를 들어, 1월에 100명의 사용자를 위한 연간 라이선스를 구매했으며, 각 추가 사용자는 $100입니다. 연중 사용자 수는 95명에서 120명 사이에서 변동했습니다. 이는 연중에 라이선스를 20명의 사용자만큼 초과했음을 의미합니다.

다음 차트는 연중 월별 및 분기별 사용자 수를 보여줍니다.

![월별 및 분기별 사용자 수를 보여주는 막대 차트](img/quarterly_reconciliation_v14_7.png)

분기별로 청구하는 경우:

- Q1에 110명의 사용자가 있었습니다. 구독 초과 10명 x 사용자당 $25 x 3분기 = $750. 이제 110명의 사용자를 위한 라이선스 비용을 지불합니다.
- Q2에 105명의 사용자가 있었습니다. 110명의 사용자를 초과하지 않았으므로 요금이 청구되지 않습니다.
- Q3에 120명의 사용자가 있었습니다. 구독 초과 10명 x 사용자당 $25 x 1개의 남은 분기 = $250. 이제 120명의 사용자를 위한 라이선스 비용을 지불합니다.
- Q4에 120명의 사용자가 있었습니다. Q3의 사용자 수를 초과하지 않았으므로 요금이 청구되지 않습니다. 그러나 수를 초과했더라도 Q4에는 수를 초과하는 데 대한 요금이 없으므로 요금이 청구되지 않습니다.
- 연간 총 비용은 $1000입니다.

연간으로 청구하는 경우:

- 추가 사용자의 경우 $100 x 20명의 사용자를 지불합니다.
- 연간 총 비용은 $2000입니다.

## 분기 조정 {#quarterly-reconciliation}

### 적격성 {#eligibility}

다음의 경우 분기 조정에 자동으로 등록됩니다:

- 구독을 구매하는 데 사용한 신용카드가 여전히 GitLab 계정에 연결되어 있습니다.
- 청구서를 통해 구독을 구매했습니다.

다음의 경우 분기 조정에서 제외됩니다:

- 리셀러 또는 다른 채널 파트너로부터 구독을 구매했습니다.
- 12개월이 아닌 기간의 구독을 구매했습니다(다중 연도 및 비표준 길이 구독 포함).
- 구매 발주를 통해 구독을 구매했습니다.
- [엔터프라이즈 애자일 계획](manage_seats.md#enterprise-agile-planning) 상품을 구매했습니다.
- 공공 부문 고객입니다.
- 오프라인 환경을 보유하고 있으며 라이선스 파일을 사용하여 구독을 활성화했습니다.
- GitLab for Education, GitLab for Open Source Program 또는 GitLab for Startups와 같은 Free 티어를 제공하는 프로그램에 등록되어 있습니다.

분기 조정에서 제외되었고 Free 티어가 아닌 경우, 확정은 연간으로 조정됩니다. 또는 [추가 사용자 구매](manage_seats.md#buy-more-seats)를 통해 초과분을 조정할 수 있습니다.

### 청구 및 결제 {#invoicing-and-payment}

각 구독 분기가 끝나면 GitLab에서 초과분을 알려줍니다. 초과분에 대해 알림을 받은 날짜는 청구되는 날짜와 다릅니다.

1. [초과 사용자 수량](manage_seats.md#users-over-subscription-limit)을 전달하고 예상 청구서 금액을 알리는 이메일을 보냅니다:

   - GitLab.com:  조정 날짜에 그룹 소유자 및 청구 계정 관리자에게 보냅니다.
   - GitLab Self-Managed:  조정 날짜로부터 6일 후 청구 계정 관리자에게 보냅니다.

1. 이메일 알림으로부터 7일 후 구독은 추가 사용자를 포함하도록 업데이트되고 비례 금액에 대한 청구서가 생성됩니다. 신용카드가 저장되어 있으면 결제가 자동으로 적용됩니다. 그렇지 않으면 청구서를 받게 되며, 이는 결제 조건이 적용됩니다.

## 연간 확정 {#annual-true-up}

다음의 경우 구독 청구는 연간 확정 프로세스로 기본 설정됩니다:

- 계약 수정을 사용하여 분기 조정을 명시적으로 거부합니다.
- 분기 조정에 적격이 아닙니다.

## 문제 해결 {#troubleshooting}

### 결제 실패 {#failed-payment}

분기 조정 프로세스 중에 신용카드가 거부된 경우 `Action required: Your GitLab subscription failed to reconcile`라는 제목의 이메일을 받습니다. 이 이슈를 해결하려면:

1. [결제 정보 업데이트](billing_account.md#change-your-payment-method)
1. [선택한 결제 방법을 기본값으로 설정](billing_account.md#set-a-default-payment-method)

결제 방법이 업데이트되면 조정이 자동으로 다시 시도됩니다.
