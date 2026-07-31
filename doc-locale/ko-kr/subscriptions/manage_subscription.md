---
stage: Fulfillment
group: Subscription Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab 구독을 구매, 확인 및 갱신합니다."
title: 구독 관리
---

## 구독 구매 {#buy-a-subscription}

GitLab에 [가입](https://gitlab.com/users/sign_up)한 후 GitLab.com 또는 GitLab Self-Managed용 구독을 구매할 수 있습니다. 구독은 개인 프로젝트에 사용할 수 있는 기능을 결정합니다.

GitLab을 구독한 후 구독의 세부정보를 관리할 수 있습니다. 문제가 발생하면 [GitLab 구독 문제 해결](gitlab_com/gitlab_subscription_troubleshooting.md)을 참조합니다.

공개 오픈 소스 프로젝트가 있는 조직은 [GitLab for Open Source 프로그램](community_programs.md#gitlab-for-open-source)에 신청할 수 있습니다.

### GitLab.com {#for-gitlabcom}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

GitLab.com은 GitLab 멀티테넌트 SaaS(Software-as-a-Service) 제공 서비스입니다. GitLab.com을 사용하기 위해 아무것도 설치할 필요가 없으며, [가입](https://gitlab.com/users/sign_up)하기만 하면 됩니다. 가입할 때 다음을 선택합니다:

- [구독](https://about.gitlab.com/pricing/). [GitLab.com 기능 비교](https://about.gitlab.com/pricing/feature-comparison/)를 확인하고 원하는 티어를 선택합니다.
- 원하는 사용자 수.
- GitLab Credits 옵션.

GitLab.com 구독은 최상위 그룹에 적용됩니다. 그룹의 모든 하위 그룹 및 프로젝트의 구성원:

- 구독의 기능을 사용할 수 있습니다.
- 구독에서 사용자 수를 소비합니다.

사용자가 다른 최상위 그룹(예를 들어 자신이 생성한 그룹)을 확인하거나 선택하고 해당 그룹에 유료 구독이 없으면 사용자는 유료 기능을 볼 수 없습니다.

사용자는 서로 다른 구독이 있는 두 개의 다른 최상위 그룹에 속할 수 있습니다. 이 경우 사용자는 해당 구독에서 사용할 수 있는 기능만 봅니다.

GitLab.com을 구독하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **결제**를 선택합니다.
1. **구독 업그레이드**를 선택합니다.
1. 티어와 GitLab Credits 옵션을 선택합니다.
1. **결제로 이동**을 선택합니다. Customers Portal로 리디렉션됩니다.
1. **사용자** 필드에 원하는 사용자 수를 입력합니다.
1. 구독 세부정보 및 결제 정보를 검토합니다.
1. **I accept the Privacy Statement and Terms of Service** 체크박스를 선택합니다.
1. **구독 구매**를 선택합니다.

### GitLab Self-Managed {#for-gitlab-self-managed}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab Self-Managed 인스턴스를 위해 GitLab을 구독하려면:

- [가격 책정 페이지](https://about.gitlab.com/pricing/)로 이동하여 셀프 관리 요금제를 선택합니다. 구매를 완료하기 위해 [Customers Portal](https://customers.gitlab.com/)로 리디렉션됩니다.

> [!note]
> 기존 **Free** GitLab Self-Managed 인스턴스의 구독을 구매하는 경우 [사용자를 충분히 포함](../administration/admin_area.md#administering-users)할 수 있도록 충분한 사용자를 구매해야 합니다.

## 구독 활성화 {#activate-subscription}

구독을 구매한 후:

- GitLab.com에서 구독은 최상위 그룹에 자동으로 적용됩니다. 활성화 코드가 필요하지 않습니다. 계정 담당자 또는 GitLab 파트너를 통해 구독을 구매한 경우 먼저 구독을 최상위 그룹에 연결해야 합니다.
- GitLab Self-Managed에서 Customers Portal 계정의 이메일 주소로 활성화 코드를 받습니다.

구독을 사용하여 시작하려면:

1. GitLab Self-Managed의 경우 활성화 코드를 사용하여 [라이센스를 활성화](../administration/license.md)합니다.
1. 구독을 확인하여 티어, 사용자 수, 시작 및 종료 날짜를 확인합니다.
1. GitLab.com의 경우 구독이 올바른 최상위 그룹에 적용되지 않으면 구독을 그룹에 연결합니다.
1. 결제 방법, 결제 및 구독 연락처를 확인하기 위해 계정을 검토합니다.
1. 적절한 사람이 구독 알림을 받도록 구독 연락처를 추가하거나 변경합니다.
1. 팀의 사용자를 추가하고, 사용자를 관리하고, 추가 기능을 할당합니다.

## 구독 확인 {#view-subscription}

### GitLab.com {#for-gitlabcom-1}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

전제 조건:

- 그룹의 Owner 역할이 있어야 합니다.

GitLab.com 구독의 상태를 확인하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **결제**를 선택합니다.

다음 정보가 표시됩니다:

| 필드                       | 설명 |
|:----------------------------|:------------|
| **구독 사용자**   | 유료 요금제인 경우 이 그룹을 위해 구매한 사용자 수를 나타냅니다(Enterprise Agile Planning 사용자 포함). |
| **현재 사용 중인 사용자**  | 사용 중인 사용자 수입니다. **사용 보기**를 선택하여 이 사용자를 사용 중인 사용자의 목록을 확인합니다. |
| **Maximum seats used**      | 사용한 가장 많은 사용자 수입니다. |
| **청구될 사용자**              | **사용된 최대 사용자** - **구독 사용자**. |
| **구독 시작 날짜** | 구독이 시작된 날짜입니다. |
| **구독 종료 날짜**   | 현재 구독이 종료되는 날짜입니다. |

### GitLab Self-Managed {#for-gitlab-self-managed-1}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

전제 조건:

- 관리자여야 합니다.

구독의 상태를 확인할 수 있습니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **Subscription**을 선택합니다.

**구독** 페이지에 다음 정보가 포함됩니다:

- 라이센시
- 요금제
- 업로드, 시작 및 만료 시기
- 구독의 사용자 수(Enterprise Agile Planning 사용자 포함)
- 청구 가능한 사용자 수
- 최대 사용자 수
- 구독을 초과하는 사용자 수

## 계정 검토 {#review-your-account}

결제 계정 설정 및 구매 정보를 정기적으로 검토해야 합니다.

결제 계정 설정을 검토하려면:

1. [Customers Portal](https://customers.gitlab.com/customers/sign_in)에 로그인합니다.
1. **Billing account settings**을 선택합니다.
1. 다음을 확인하거나 업데이트합니다:
   - **Payment methods**에서 파일에 있는 신용카드를 확인합니다.
   - **Company information**에서 구독 및 결제 연락처 세부정보를 확인합니다.
1. 모든 변경사항을 저장합니다.

올바른 수의 활성 청구 가능 사용자만을 갱신하고 있는지 확인하기 위해 정기적으로 사용자 계정을 검토해야 합니다. 비활성 사용자 계정:

- 청구 가능한 사용자로 계산될 수 있습니다. 비활성 사용자 계정을 갱신하면 예상보다 더 많이 지불할 수 있습니다.
- 보안 위험이 될 수 있습니다. 정기적인 검토는 이 위험을 줄이는 데 도움이 됩니다.

자세한 정보는 다음 설명서를 참조합니다:

- [사용자 통계](../administration/admin_area.md#users-statistics).
- [라이센스 사용](../administration/license_usage.md).
- [사용자 관리 및 구독 사용자](manage_seats.md).

## 구독 티어 업그레이드 {#upgrade-subscription-tier}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed

{{< /details >}}

전제 조건:

- 청구 계정 관리자여야 합니다.

[GitLab 티어](https://about.gitlab.com/pricing/)를 업그레이드하려면:

1. [Customers Portal](https://customers.gitlab.com/customers/sign_in)에 로그인합니다.
1. 관련 구독 카드에서 **요금제 업그레이드**를 선택합니다.
1. 업그레이드할 요금제를 선택합니다.
1. **결제로 이동**을 선택합니다.
1. 업그레이드 세부정보 및 결제 정보를 검토합니다.
1. **I accept the Privacy Statement and Terms of Service** 체크박스를 선택합니다.
1. **구독 업그레이드**를 선택합니다.

다음이 이메일로 발송됩니다:

- 결제 영수증입니다. Customers Portal의 [**Invoices**](https://customers.gitlab.com/invoices)에서도 이 정보에 액세스할 수 있습니다.
- GitLab Self-Managed에서 라이센스의 새 활성화 코드입니다.

GitLab Self-Managed에서 새 티어는 다음 구독 동기화 시 적용됩니다. [구독을 수동으로 동기화](#subscription-data-synchronization)하여 즉시 업그레이드할 수도 있습니다.

GitLab.com에서 구독을 구매할 때 GitLab Credits 옵션을 선택할 수도 있습니다.

## 구독 갱신 {#renew-subscription}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed

{{< /details >}}

구독 갱신 날짜 전에 현재 사용자 사용 현황 및 청구 가능한 사용자를 확인하기 위해 계정을 검토해야 합니다.

구독을 자동으로 또는 수동으로 갱신할 수 있습니다. 다음 중 하나를 수행하려면 구독을 수동으로 갱신해야 합니다:

- 더 적은 사용자로 갱신합니다.
- 갱신되는 제품의 수량을 증가하거나 감소합니다.
- 갱신된 구독 기간에 더 이상 필요하지 않은 추가 기능을 제거합니다.
- 구독 티어를 업그레이드합니다.

갱신 기간 시작 날짜는 그룹 결제 페이지의 **다음 구독 기간 시작일** 아래에 표시됩니다.

다음에 문의합니다:

- Customers Portal에 액세스하거나 구독을 관리하는 연락처를 변경할 때 도움이 필요하면 [지원 팀](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293)에 문의합니다.
- 구독 갱신에 도움이 필요하면 [영업 팀](https://customers.gitlab.com/contact_us)에 문의합니다.

### 구독 만료 시기 확인 {#check-when-subscription-expires}

구독 만료 15일 전에 GitLab 사용자 인터페이스에서 관리자를 위해 구독 만료 날짜가 있는 배너가 표시됩니다.

구독이 만료되기 15일 이전에는 구독을 수동으로 갱신할 수 없습니다. 갱신할 수 있는 시기를 확인하려면:

1. [Customers Portal](https://customers.gitlab.com/customers/sign_in)에 로그인합니다.
1. **Subscription actions**({{< icon name="ellipsis_v" >}})을 선택한 다음 갱신할 수 있는 날짜를 보려면 **구독 갱신**을 선택합니다.

### 자동으로 갱신 {#renew-automatically}

전제 조건:

- GitLab Self-Managed의 경우 변경 사항이 동기화되도록 갱신 2일 전에 [구독 데이터를 동기화](#subscription-data-synchronization)하고 계정을 검토해야 합니다.

구독이 자동 갱신으로 설정되면 만료 날짜의 자정 UTC에 서비스 사용 가능성 간격 없이 자동으로 갱신됩니다. 구독이 자동으로 갱신되기 전에 [이메일 알림](#renewal-notifications)을 받습니다.

사용자 수는 갱신 시 자동으로 감소하지 않습니다. 갱신 시 청구 가능한 사용자가 현재 구독 수량보다 많으면 사용자 수가 자동으로 증가하여 [그룹](manage_seats.md#view-seat-usage) 또는 [인스턴스](../administration/moderate_users.md#view-users)의 현재 사용자 수와 일치합니다. 구독을 예기치 않게 더 많은 사용자로 갱신하는 것을 피하려면 [더 적은 사용자으로 갱신](#renew-for-fewer-seats)하는 방법을 알아봅니다.

Customers Portal을 통해 구매한 구독은 기본적으로 자동 갱신으로 설정되지만 [자동 구독 갱신을 끌 수](#turn-on-or-turn-off-automatic-subscription-renewal) 있습니다.

#### 자동 구독 갱신 켜기 또는 끄기 {#turn-on-or-turn-off-automatic-subscription-renewal}

Customers Portal을 사용하여 자동 구독 갱신을 켜거나 끌 수 있습니다:

1. [Customers Portal](https://customers.gitlab.com/customers/sign_in)에 로그인합니다. **Subscriptions & purchases** 페이지로 이동합니다.
1. 구독 카드를 확인합니다:
   - 카드에 **Expires on DATE**가 표시되면 구독이 자동으로 갱신되도록 설정되지 않습니다. 자동 갱신을 활성화하려면 **Subscription actions**({{< icon name="ellipsis_v" >}})에서 **Turn on auto-renew**를 선택합니다.
   - 카드에 **Auto-renews on DATE**이 표시되면 구독이 자동으로 갱신되도록 설정됩니다. 자동 갱신을 비활성화하려면:
     1. **Subscription actions**({{< icon name="ellipsis_v" >}})에서 **Cancel subscription**를 선택합니다.
     1. 취소 이유를 선택합니다.
     1. 선택 사항. **Would you like to add anything?**에 관련 정보를 입력합니다.
     1. **Cancel subscription**를 선택합니다.

### 수동으로 갱신 {#renew-manually}

구독을 수동으로 갱신하려면:

1. 다음 구독 기간에 필요한 사용자 수를 결정합니다.
1. [Customers Portal](https://customers.gitlab.com/customers/sign_in)에 로그인합니다.
1. 기존 구독에서 **Start renewal**을 선택합니다. 이 버튼은 구독이 만료되기 15일 전까지 표시되지 않습니다.
1. Premium 또는 Ultimate 제품을 갱신하는 경우 **사용자** 텍스트 상자에 향후 1년 동안 필요한 총 사용자 수를 입력합니다.

   > [!note]
   > 이 수를 갱신 시 시스템의 [청구 가능한 사용자](manage_seats.md#billable-users) 수보다 크거나 같은지 확인합니다.

1. 선택 사항. GitLab Self-Managed의 경우 인스턴스의 최대 사용자 수가 이전 구독 기간에 라이센스를 받은 수를 초과한 경우 갱신할 때 [초과분](quarterly_reconciliation.md)이 지급됩니다.

   **Users over license** 텍스트 상자에 발생한 사용자 초과분에 대한 [구독을 초과하는 사용자](manage_seats.md#users-over-subscription-limit) 수를 입력합니다.
1. 선택 사항. 추가 기능을 갱신하는 경우 원하는 수량을 검토하고 업데이트합니다. 제품을 제거할 수도 있습니다.
1. 선택 사항. 구독 티어를 업그레이드하는 경우 원하는 옵션을 선택합니다.
1. 갱신 세부정보를 검토하고 **구독 갱신**을 선택하여 결제 프로세스를 완료합니다.
1. GitLab Self-Managed의 경우 관련 구독 카드의 [구독 및 구매](https://customers.gitlab.com/subscriptions) 페이지에서 **Copy activation code**를 선택하여 갱신 기간 활성화 코드의 복사본을 가져오고 [활성화 코드를 추가](../administration/license.md)하여 인스턴스에 적용합니다.

구독에 제품을 추가하려면 [영업 팀에 문의](https://customers.gitlab.com/contact_us)합니다.

### 더 적은 사용자로 갱신 {#renew-for-fewer-seats}

더 적은 사용자로 구독을 갱신하려면 현재 청구 가능한 사용자 수 이상이어야 합니다.

구독을 갱신하기 전에:

- GitLab.com의 경우 갱신하려는 사용자 수를 초과하면 [청구 가능한 사용자 수를 줄입니다](manage_seats.md#remove-users-from-subscription).
- GitLab Self-Managed의 경우 [비활성 또는 원하지 않는 사용자를 차단](../administration/moderate_users.md#block-a-user)합니다.

더 적은 사용자로 구독을 수동으로 갱신하려면 다음 중 하나를 수행할 수 있습니다:

- [수동으로 갱신](#renew-manually)은 구독 갱신 날짜 후 15일 이내입니다. 갱신할 때 사용자 수량을 지정해야 합니다.
- [구독의 자동 갱신을 끄고](#turn-on-or-turn-off-automatic-subscription-renewal) [영업 팀](https://customers.gitlab.com/contact_us)에 문의하여 원하는 사용자 수로 갱신합니다.

### 갱신 알림 {#renewal-notifications}

구독이 자동으로 갱신되기 15일 전에 갱신에 대한 정보가 포함된 이메일이 발송됩니다.

- 신용카드가 만료된 경우 이메일은 업데이트하는 방법을 알려줍니다.
- 미결제 초과분이 있거나 구독을 자동으로 갱신할 수 없는 다른 이유가 있으면 이메일은 영업 팀에 문의하거나 Customers Portal에서 수동으로 갱신하도록 지시합니다.
- 문제가 없으면 이메일은 다음을 지정합니다:
  - 갱신 중인 제품의 이름 및 수량입니다.
  - 지불해야 할 총 금액입니다. 갱신 전에 사용 현황이 증가하면 이 금액은 변경됩니다.

### 갱신 청구서 관리 {#manage-renewal-invoice}

갱신을 위한 청구서가 생성됩니다. 이 갱신 청구서를 확인하거나 다운로드하려면 [Customers Portal 청구서 페이지](https://customers.gitlab.com/invoices)로 이동합니다.

계정에 [저장된 신용카드](billing_account.md#change-your-payment-method)가 있으면 카드가 청구서 금액으로 청구됩니다.

결제를 처리할 수 없거나 자동 갱신이 다른 이유로 실패하면 14일 이내에 구독을 갱신할 수 있으며, 그 이후 GitLab 티어는 다운그레이드됩니다.

## 만료된 구독 {#expired-subscription}

구독은 만료 날짜(00:00 서버 시간)의 시작 시점에 만료됩니다.

예를 들어 구독이 2024년 1월 1일부터 2025년 1월 1일까지 유효한 경우:

- 2024년 12월 31일 오후 11:59:59 UTC에 만료됩니다.
- 2025년 1월 1일 오전 12:00:00 UTC부터 만료된 것으로 간주됩니다.

구독이 만료된 경우 만료 날짜 후 15일 이내에 수동으로 갱신할 수 있습니다. 15일이 지나면 수동 갱신 옵션을 더 이상 사용할 수 없으며 유료 기능에 대한 액세스를 복원하려면 새 구독을 구매해야 합니다.

### GitLab.com {#for-gitlabcom-2}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

구독이 만료되면 유료 기능을 더 이상 사용할 수 없습니다. 그러나 무료 기능은 계속 사용할 수 있습니다. 유료 기능 기능을 재개하려면 구독을 갱신합니다.

### GitLab Self-Managed {#for-gitlab-self-managed-2}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

라이센스가 만료되면:

- 인스턴스가 읽기 전용이 됩니다.
- GitLab은 Git 푸시 및 이슈 생성과 같은 기능을 잠급니다.
- 만료 메시지가 모든 인스턴스 관리자에게 표시됩니다.

라이센스가 만료된 후:

- 기능을 재개하려면 [새 구독을 활성화](../administration/license_file.md#activate-subscription-during-installation)합니다.
- Free 티어 기능만 계속 사용하려면 [만료된 라이센스를 제거](../administration/license_file.md#remove-a-license)합니다.

## 구독 데이터 동기화 {#subscription-data-synchronization}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

전제 조건:

- GitLab Enterprise Edition(EE).
- 인터넷에 연결되어 있으며 오프라인 환경이 아니어야 합니다.
- 활성화 코드로 [인스턴스를 활성화](../administration/license.md)했습니다.

[구독 데이터](#subscription-data)는 GitLab Self-Managed 인스턴스와 GitLab 간에 하루에 한 번씩 자동으로 동기화됩니다.

대략 오전 3:00(UTC)에 이 일일 동기화 작업은 [구독 데이터](#subscription-data)를 Customers Portal로 전송합니다. 이 때문에 업데이트 및 갱신이 즉시 적용되지 않을 수 있습니다.

데이터는 `customers.gitlab.com` 포트 `443`로의 암호화된 HTTPS 연결을 통해 안전하게 전송됩니다. 작업이 실패하면 약 17시간 동안 최대 12번까지 재시도됩니다.

자동 데이터 동기화를 설정한 후 다음 프로세스도 자동으로 수행됩니다.

- [분기별 구독 조정](quarterly_reconciliation.md).
- 구독 갱신.
- 더 많은 사용자 추가 또는 GitLab 티어 업그레이드와 같은 구독 업데이트.

### 구독 데이터 수동 동기화 {#manually-synchronize-subscription-data}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

언제든지 구독 데이터를 수동으로 동기화할 수 있습니다.

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **Subscription**을 선택합니다.
1. **구독 세부정보** 섹션에서 **Sync**({{< icon name="retry" >}})을 선택합니다.

동기화 작업이 대기열에 추가됩니다. 작업이 완료되면 구독 세부정보가 업데이트됩니다.

### 구독 데이터 {#subscription-data}

{{< history >}}

- 고유 인스턴스 ID는 GitLab 18.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189399)되었습니다.

{{< /history >}}

일일 동기화 작업은 Customers Portal로 다음 정보를 전송합니다:

- 날짜
- 타임스탬프
- 라이센스 키(키 내에 다음이 암호화됨):
  - 회사 이름
  - 라이센시 이름
  - 라이센시 이메일
- 기록 [최대 사용자 수](manage_seats.md#self-managed-billing-and-usage)
- [청구 가능한 사용자 수](manage_seats.md#billable-users)
- GitLab 버전
- 호스트명
- 인스턴스 ID
- 고유 인스턴스 ID

또한 다음과 같은 추가 기능 메트릭을 얻습니다:

- 추가 기능 유형
- 구매한 사용자
- 할당된 사용자

라이센스 동기화 요청의 예:

```json
{
  "gitlab_version": "14.1.0-pre",
  "timestamp": "2021-06-14T12:00:09Z",
  "date": "2021-06-14",
  "license_key": "XXX",
  "max_historical_user_count": 75,
  "billable_users_count": 75,
  "hostname": "gitlab.example.com",
  "instance_id": "9367590b-82ad-48cb-9da7-938134c29088",
  "unique_instance_id": "a98bab6e-73e3-5689-a487-1e7b89a56901",
  "add_on_metrics": [
    {
      "add_on_type": "duo_enterprise",
      "purchased_seats": 100,
      "assigned_seats": 50
    }
  ]
}
```

## 구독을 그룹에 연결 {#link-subscription-to-a-group}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

전제 조건:

- 그룹 네임스페이스.

하나의 그룹 네임스페이스만 구독에 연결될 수 있습니다.

Premium 또는 Ultimate 구독이 개인 네임스페이스에 있는 경우 구독을 연결하기 전에 다음 중 하나를 수행해야 합니다:

- [프로젝트를 그룹으로 전송](../user/project/working_with_projects.md#transfer-a-project)합니다.
- [개인 네임스페이스를 그룹으로 변환](../tutorials/convert_personal_namespace_to_group/_index.md)하여 기존 URL을 유지합니다.

구독을 그룹에 연결하거나 GitLab.com 구독에 연결된 그룹을 변경하려면:

1. [Customers Portal](https://customers.gitlab.com/customers/sign_in)에 [연결된](billing_account.md#link-a-gitlabcom-account) GitLab.com 계정으로 로그인합니다.
1. 다음 중 하나를 수행합니다:
   - 구독이 그룹에 연결되지 않으면 **Link subscription to a group**을 선택합니다.
   - 구독이 이미 그룹에 연결되어 있으면 **Subscription actions**({{< icon name="ellipsis_v" >}}) > **Change linked group**을 선택합니다.
1. **New Namespace** 드롭다운 목록에서 원하는 그룹을 선택합니다. 그룹이 여기에 나타나려면 해당 그룹에 대한 Owner 역할이 있어야 합니다.
1. 그룹의 [총 사용자 수](manage_seats.md#view-seat-usage)가 구독의 사용자 수를 초과하면 추가 사용자에 대해 비용을 지불하라는 메시지가 표시됩니다. 구독 요금은 하위 그룹 및 중첩된 프로젝트를 포함하는 그룹의 총 사용자 수를 기준으로 계산됩니다.

   인증된 리셀러를 통해 구독을 구매한 경우 추가 사용자에 대해 비용을 지불할 수 없습니다. 다음 중 하나를 수행할 수 있습니다:

   - 초과분이 감지되지 않도록 추가 사용자를 제거합니다.
   - 파트너에게 문의하여 지금 또는 구독 기간 종료 시 추가 사용자를 구매합니다.

1. **Confirm changes**을 선택합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 데모는 [GitLab 구독을 네임스페이스에 연결](https://youtu.be/8iOsN8ajBUw)을 참조합니다.

## 구독 연락처 추가 또는 변경 {#add-or-change-subscription-contacts}

연락처는 구독을 갱신하거나, 구독을 취소하거나, 구독을 다른 네임스페이스로 전송할 수 있습니다.

[프로필 소유자 정보 변경](billing_account.md#change-profile-owner-information)하거나 [다른 결제 계정 관리자 추가](billing_account.md#add-a-billing-account-manager)할 수 있습니다.

### 전송 제한 {#transfer-restrictions}

연결된 네임스페이스를 변경할 수 있지만 모든 구독 유형에 대해 지원되지 않습니다.

다음을 전송할 수 없습니다:

- 만료되었거나 평가판 구독.
- 이미 네임스페이스에 연결되어 있는 컴퓨팅 분을 포함하는 구독.
- 이미 Premium 또는 Ultimate 요금제가 있는 네임스페이스로 Premium 또는 Ultimate 요금제가 있는 구독.
- 이미 GitLab Duo 추가 기능이 있는 구독이 있는 네임스페이스로 GitLab Duo 추가 기능이 있는 구독.
- 개인 네임스페이스로 Premium 또는 Ultimate 요금제가 있는 구독.
- 할인 코드를 사용하여 구매한 구독.
