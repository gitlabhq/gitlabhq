---
stage: Fulfillment
group: Subscription Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Customers Portal에서 청구 계정 데이터 및 결제 방법을 변경하고, 송장을 결제하며, GitLab 계정을 연결합니다."
title: 청구 계정 관리
---

Customers Portal은 [GitLab 구독 관리](manage_subscription.md) 및 청구를 위한 포괄적인 셀프 서비스 허브입니다. GitLab 상품을 구매하고, 전체 구독 수명 주기 동안 구독을 관리하며, 송장을 보고 결제하고, 청구 세부 정보 및 연락처 정보에 액세스할 수 있습니다.

공인된 리셀러를 통해 구매했다면, 구독을 변경하기 위해 리셀러에 직접 연락해야 합니다. 자세한 내용은 [리셀러를 통해 구매한 고객](#subscription-purchased-through-a-reseller)을 참조하세요.

## Customers Portal에 로그인 {#sign-in-to-customers-portal}

GitLab.com 계정 또는 이메일로 전송된 일회용 로그인 링크로 Customers Portal에 로그인할 수 있습니다(아직 [Customers Portal 계정을 GitLab.com 계정과 연결](#link-a-gitlabcom-account)하지 않은 경우).

> [!note]
> GitLab.com 계정으로 Customers Portal에 등록했다면, 이 계정으로 로그인하세요.

GitLab.com 계정을 사용하여 Customers Portal에 로그인하려면:

1. [Customers Portal](https://customers.gitlab.com/customers/sign_in)로 이동합니다.
1. **Continue with GitLab.com account**를 선택합니다.

이메일로 Customers Portal에 로그인하고 일회용 로그인 링크를 받으려면:

1. [Customers Portal](https://customers.gitlab.com/customers/sign_in)로 이동합니다.
1. **Sign in with your email**을 선택합니다.
1. Customers Portal 프로필에 **이메일**을 입력합니다. 일회용 로그인 링크가 포함된 이메일을 받습니다.
1. 받은 이메일에서 **로그인**을 선택합니다.

> [!note]
> 일회용 로그인 링크는 24시간 후에 만료되며 한 번만 사용할 수 있습니다.

## Customers Portal 이메일 주소 확인 {#confirm-customers-portal-email-address}

일회용 로그인 링크로 Customers Portal에 처음 로그인할 때는 Customers Portal에 대한 액세스를 유지하기 위해 이메일 주소를 확인해야 합니다. GitLab.com을 통해 Customers Portal에 로그인하면 이메일 주소를 확인할 필요가 없습니다.

프로필 이메일 주소에 대한 모든 업데이트를 확인해야 합니다. 확인 방법에 대한 지침이 포함된 자동 이메일을 받으며, 필요한 경우 [다시 보낼](https://customers.gitlab.com/customers/confirmation/new) 수 있습니다.

## 프로필 소유자 정보 변경 {#change-profile-owner-information}

프로필 소유자의 이메일 주소는 [Customers Portal 레거시 로그인](#sign-in-to-customers-portal)에 사용됩니다. 프로필 소유자도 [청구 계정 관리자](#subscription-and-billing-contacts)인 경우, 이들의 개인 정보는 송장 및 라이선스 및 구독 관련 이메일에 사용됩니다.

이름 및 이메일 주소를 포함한 프로필 세부 정보를 변경하려면:

1. [Customers Portal](https://customers.gitlab.com/customers/sign_in)에 로그인합니다.
1. **My profile** > **Profile settings**을 선택합니다.
1. **Your personal details**를 편집합니다.
1. **변경 사항 저장**을 선택합니다.

## 회사 세부 정보 변경 {#change-your-company-details}

회사명 및 세금 ID를 포함한 회사 세부 정보를 변경하려면:

1. [Customers Portal](https://customers.gitlab.com/customers/sign_in)에 로그인합니다.
1. **Billing account settings**을 선택합니다.
1. **Company information** 섹션까지 아래로 스크롤합니다.
1. 회사 세부 정보를 편집합니다.
1. **변경 사항 저장**을 선택합니다.

## 구독 및 청구 담당자 {#subscription-and-billing-contacts}

구독 관리에 관여하는 사용자는 구독에 대한 권한 및 가시성 수준이 다른 세 가지 역할을 가질 수 있습니다:

- 청구 계정 관리자: 구독, 결제 방법 및 청구 계정 설정을 보고 편집할 수 있습니다. 송장을 지불하고 다운로드하며, 구독 담당자를 나열된 청구 계정 관리자로 업데이트할 수 있습니다.
- 구독 담당자(또는 "판매처" 담당자): 구독 소유자이며 청구 계정의 주요 담당자입니다. 구독 이벤트 및 구독 적용에 관한 정보에 대한 알림을 받습니다. 이 역할은 기본적으로 청구 계정 관리자이기도 합니다.
- 청구 담당자(또는 "청구처" 담당자): 모든 송장 및 구독 이벤트에 관한 알림을 받습니다. 이 역할도 청구 계정 관리자가 아닌 한 구독에 액세스할 수 있는 Customers Portal 계정이 없습니다.

한 사용자가 세 가지 역할을 모두 가질 수 있습니다.

### 구독 담당자 변경 {#change-your-subscription-contact}

구독 담당자를 변경하려면:

1. [Customers Portal](https://customers.gitlab.com/customers/sign_in)에 로그인합니다.
1. 왼쪽 사이드바에서 **Billing account settings**을 선택합니다.
1. **Company information** 섹션까지 스크롤한 후 **Subscription contact**까지 스크롤합니다.
1. 다른 구독 담당자를 선택하려면 **Billing account manager** 드롭다운 목록에서 선택합니다.
1. 담당자 정보를 편집합니다.
1. **변경 사항 저장**을 선택합니다.

### 청구 계정 관리자 추가 {#add-a-billing-account-manager}

계정에 다른 청구 계정 관리자를 추가하려면:

1. 추가할 사용자를 위해 [Customers Portal](https://customers.gitlab.com/customers/sign_in)에 계정이 존재하는지 확인합니다.
1. [Customers Portal](https://customers.gitlab.com/customers/sign_in)에 로그인합니다.
1. 왼쪽 사이드바에서 **Billing account settings**을 선택합니다.
1. **Billing account managers** 섹션까지 스크롤합니다.
1. **Invite billing account manager**를 선택합니다.
1. 추가할 사용자의 이메일 주소를 입력합니다.
1. **초대**를 선택합니다.

초대된 사용자는 Customers Portal로의 초대가 포함된 이메일을 받습니다. 초대는 7일 동안 유효합니다. 사용자가 만료되기 전에 초대를 수락하지 않으면 새 초대를 보낼 수 있습니다. 한 번에 최대 15개의 대기 중인 초대를 보유할 수 있습니다.

### 청구 계정 관리자 제거 {#remove-a-billing-account-manager}

언제든지 계정에서 청구 계정 관리자를 제거할 수 있습니다. 청구 계정 관리자를 제거한 후 더 이상 청구 계정 정보를 보거나 편집할 수 없습니다.

청구 계정 관리자를 제거하려면:

1. [Customers Portal](https://customers.gitlab.com/customers/sign_in)에 로그인합니다.
1. 왼쪽 사이드바에서 **Billing account settings**을 선택합니다.
1. **Billing account managers** 섹션까지 스크롤합니다.
1. 목록에서 제거할 청구 계정 관리자 옆에 **삭제**를 선택합니다.
1. 확인 대화상자에서 **삭제**를 선택하여 작업을 확인합니다.

### 청구 계정 관리자 초대 취소 {#revoke-a-billing-account-manager-invitation}

아직 수락되지 않은 초대를 취소할 수 있습니다. 초대되었지만 아직 초대를 수락하지 않은 사용자는 **Awaiting user registration** 이름으로 표시됩니다.

초대를 취소하려면:

1. [Customers Portal](https://customers.gitlab.com/customers/sign_in)에 로그인합니다.
1. 왼쪽 사이드바에서 **Billing account settings**을 선택합니다.
1. **Billing account managers** 섹션까지 스크롤합니다.
1. 목록에서 **Awaiting user registration** 이름의 초대된 사용자 옆에 **삭제**를 선택합니다.
1. 확인 대화상자에서 **삭제**를 선택하여 초대를 취소합니다.

### 청구 담당자 변경 {#change-your-billing-contact}

청구 담당자는 모든 송장 및 구독 이벤트 알림을 받습니다.

청구 담당자를 변경하려면:

1. [Customers Portal](https://customers.gitlab.com/customers/sign_in)에 로그인합니다.
1. 왼쪽 사이드바에서 **Billing account settings**을 선택합니다.
1. **Company information** 섹션까지 스크롤한 후 **Billing contact**까지 스크롤합니다.

   - 청구 담당자를 구독 담당자로 변경하려면:

     1. **Billing contact is the same as subscription contact**을 선택합니다.
     1. **변경 사항 저장**을 선택합니다.

   - 청구 담당자를 다른 청구 계정 관리자로 변경하려면:

     1. **Billing contact is the same as subscription contact** 확인란을 선택 취소합니다.
     1. **사용자** 드롭다운 목록에서 다른 청구 계정 관리자를 선택합니다.
     1. 담당자 정보를 편집합니다.
     1. **변경 사항 저장**을 선택합니다.

   - 청구 담당자를 사용자 지정 담당자로 변경하려면:

     1. **Billing contact is the same as subscription contact** 확인란을 선택 취소합니다.
     1. **Enter a custom contact**을 **사용자** 드롭다운 목록에서 선택합니다.
     1. 담당자 정보를 입력합니다.
     1. **변경 사항 저장**을 선택합니다.

## 결제 방법 변경 {#change-your-payment-method}

Customers Portal에서의 구매에는 결제 방법으로 기록된 신용카드가 필요합니다. 계정에 여러 신용카드를 추가할 수 있으므로 다양한 상품의 구매가 올바른 카드로 청구됩니다.

다른 결제 방법을 사용하려면 [영업팀에 문의하세요](https://customers.gitlab.com/contact_us).

결제 방법을 변경하려면:

1. [Customers Portal](https://customers.gitlab.com/customers/sign_in)에 로그인합니다.
1. 왼쪽 사이드바에서 **Billing account settings**을 선택합니다.
1. 기존 결제 방법의 정보를 **편집**하거나 **Add new payment method**합니다.
1. **변경 사항 저장**을 선택합니다.

### 기본 결제 방법 설정 {#set-a-default-payment-method}

구독의 자동 갱신은 기본 결제 방법으로 청구됩니다. 결제 방법을 기본값으로 표시하려면:

1. [Customers Portal](https://customers.gitlab.com/customers/sign_in)에 로그인합니다.
1. 왼쪽 사이드바에서 **Billing account settings**을 선택합니다.
1. 선택한 결제 방법을 **편집**하고 **Make default payment method** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

### 기본 결제 방법 삭제 {#delete-a-default-payment-method}

Customers Portal을 통해 기본 결제 방법을 직접 삭제할 수 없습니다. 기본 결제 방법을 삭제하려면 [청구팀에 문의하세요](https://customers.gitlab.com/contact_us).

## 송장 결제 {#pay-for-an-invoice}

Customers Portal에서 신용카드로 송장을 결제할 수 있습니다.

송장을 결제하려면:

1. [Customers Portal](https://customers.gitlab.com/customers/sign_in)에 로그인합니다.
1. 왼쪽 사이드바에서 **Invoices**을 선택합니다.
1. 결제할 송장에서 **Pay for invoice**를 선택합니다.
1. 결제 양식을 작성합니다.

다른 결제 방법을 사용하려면 [청구팀에 문의하세요](https://customers.gitlab.com/contact_us#contact-billing-team).

## GitLab.com 계정 연결 {#link-a-gitlabcom-account}

로그인할 레거시 Customers Portal 프로필이 있는 경우 이 지침을 따릅니다.

GitLab.com 계정을 Customers Portal 프로필과 연결하려면:

1. [Customers Portal](https://customers.gitlab.com/customers/sign_in?legacy=true) 계정에서 이메일로 일회용 로그인 링크를 트리거합니다.
1. 이메일을 찾아 일회용 로그인 링크를 선택하여 Customers Portal 계정에 로그인합니다.
1. **My profile** > **Profile settings**을 선택합니다.
1. **Your GitLab.com account** 아래에서 **Link account**을 선택합니다.
1. Customers Portal 프로필과 연결할 [GitLab.com](https://gitlab.com/users/sign_in) 계정에 로그인합니다.

## 연결된 계정 변경 {#change-the-linked-account}

Customers Portal 계정을 다른 GitLab.com 계정과 연결하려면 GitLab.com 계정을 사용하여 새 Customers Portal 프로필에 등록해야 합니다.

구독 담당자를 변경하려면 다음 중 하나를 대신 수행할 수 있습니다:

- [청구 담당자 변경](#change-your-billing-contact).
- [구독 담당자 변경](#change-your-subscription-contact).

GitLab.com 계정에 연결되지 않은 레거시 Customers Portal 프로필이 있는 경우, 이메일로 전송된 일회용 로그인 링크를 사용하여 [로그인](https://customers.gitlab.com/customers/sign_in?legacy=true)할 수 있습니다. 그러나 Customers Portal에 계속 액세스하기 위해 [계정을 생성](https://gitlab.com/users/sign_up)하고 [GitLab.com 계정을 연결](#change-the-linked-account)해야 합니다.

Customers Portal 프로필과 연결된 GitLab.com 계정을 변경하려면:

1. [Customers Portal](https://customers.gitlab.com/customers/sign_in)에 로그인합니다.
1. 별도의 브라우저 탭에서 [GitLab.com](https://gitlab.com/users/sign_in)으로 이동하고 로그인하지 않았는지 확인합니다.
1. Customers Portal 페이지에서 **My profile** > **Profile settings**을 선택합니다.
1. **Your GitLab.com account** 아래에서 **Change linked account**을 선택합니다.
1. Customers Portal 프로필과 연결할 [GitLab.com](https://gitlab.com/users/sign_in) 계정에 로그인합니다.

## 구독 소유권 이전 {#transfer-subscription-ownership}

Customers Portal에서 담당자로부터 또는 담당자에게 구독 소유권을 이전할 수 있습니다.

### 새로운 청구 계정 관리자에게 {#to-a-new-billing-account-manager}

청구 계정 관리자로 나열되지 않은 담당자에게 구독 소유권을 이전하려면:

1. 담당자를 청구 계정 관리자로 초대합니다.
1. 담당자가 초대를 수락한 후 구독 담당자를 새 청구 계정 관리자로 변경합니다.

### 새로운 구독 담당자에게 {#to-a-new-subscription-contact}

현재 구독 담당자이고 Customers Portal 계정이 없는 다른 사람에게 소유권을 이전하려면:

1. 프로필 소유자 정보를 새 담당자의 세부 정보로 변경합니다.
1. 새 담당자가 일회용 로그인 링크를 사용하여 이메일 주소로 Customers Portal에 로그인하도록 합니다.
1. 새 담당자가 연결된 GitLab.com 계정을 자신의 GitLab.com 계정으로 변경하도록 합니다.

### 조직을 떠난 담당자로부터 {#from-a-contact-who-has-left-the-organization}

구독 담당자의 이메일 사서함에 액세스할 수 있는 경우:

1. 구독 담당자의 이메일 주소를 사용하여 일회용 로그인 링크로 Customers Portal에 로그인합니다.
1. 구독 담당자 정보를 자신의 세부 정보로 변경합니다.
1. 연결된 계정을 자신의 GitLab.com 계정으로 변경합니다.

구독 담당자의 이메일 사서함에 액세스할 수 없는 경우 [지원팀에 문의](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293)하여 구독 소유권 이전을 요청합니다. 지원팀이 요청을 처리하려면 소유권 증명을 제공해야 합니다.

지원팀 요청에 다음 템플릿을 사용할 수 있습니다:

```plaintext
Hi Support,

Please update subscription ownership for my subscription/billing account. I confirm that I am not able to make this change in the Customers Portal. Here are the relevant details:

- Old subscription contact's email address:
- New subscription contact's email address:
- (Optional) Subscription or Billing account name:
- Proof of ownership:
```

## 미국 이외의 고객을 위한 세금 ID {#tax-id-for-non-us-customers}

세금 ID는 부가가치세(VAT), 상품 및 서비스 세(GST) 또는 유사한 간접세에 등록된 사업체에 세무 당국에서 부여하는 고유한 번호입니다.

유효한 세금 ID를 제공하면 송장에 대한 VAT/GST 청구 대신 역지정 메커니즘을 적용하도록 허용하여 세금 부담을 줄일 수 있습니다. 유효한 세금 ID가 없으면 적용 가능한 VAT/GST 세율은 위치를 기반으로 합니다.

사업체가 간접세에 등록되지 않은 경우(규모 기준이나 다른 이유로 인해), GitLab은 현지 규정에 따라 표준 VAT/GST 세율을 적용합니다.

국가별 세금 ID 형식 및 추가 정보에 대해 [전체 세금 ID 참고 가이드](https://handbook.gitlab.com/handbook/finance/tax/#frequently-asked-questions---tax-id-for-non-us-customers)를 참조하세요.

## 문제 해결 {#troubleshooting}

GitLab 구독에 대해 문제가 발생했거나 질문이 있는 경우 [문의하기](https://customers.gitlab.com/contact_us) 페이지를 방문합니다. 영업, 청구 및 지원팀의 리소스, 서비스 및 연락 옵션에 액세스하여 필요한 도움을 빠르게 받을 수 있습니다.

### 리셀러를 통해 구매한 구독 {#subscription-purchased-through-a-reseller}

공인된 리셀러(GCP 및 AWS 마켓플레이스 포함)를 통해 구독을 구매했다면, Customers Portal에 액세스하여 다음을 수행할 수 있습니다:

- 구독을 확인합니다.
- 구독을 관련 그룹(GitLab.com)과 연결하거나 라이선스(GitLab Self-Managed)를 다운로드합니다.
- 담당자 정보를 관리합니다.

기타 변경 및 요청은 리셀러를 통해 수행해야 하며, 다음을 포함합니다:

- 구독에 대한 변경.
- 추가 사용자, 스토리지 또는 컴퓨팅 구매.
- 리셀러에서 발급하고 GitLab에서가 아닌 송장 요청.

리셀러는 Customers Portal 또는 고객 계정에 액세스할 수 없습니다.

구독 주문이 처리된 후 여러 이메일을 받습니다:

- 로그인 방법에 대한 지침을 포함한 "Customers Portal에 오신 것을 환영합니다" 이메일.
- 액세스를 프로비저닝하는 방법에 대한 지침이 포함된 구매 확인 이메일.

### 청구 및 구독 담당자 이름이 일치하지 않음 {#billing-and-subscription-contacts-names-dont-match}

청구 계정 관리자의 이메일이 다른 이름이나 성을 가진 담당자에게 연결되어 있으면 이름을 업데이트하라는 메시지가 표시됩니다.

청구 계정 관리자인 경우 지침에 따라 [개인 프로필을 업데이트](#change-profile-owner-information)합니다.

청구 계정 관리자가 아닌 경우 개인 프로필을 업데이트하도록 알립니다.

### 구독 담당자가 더 이상 계정 관리자가 아님 {#subscription-contact-is-no-longer-account-manager}

구독 담당자가 더 이상 청구 계정 관리자가 아니면 새 담당자를 선택하라는 메시지가 표시됩니다. 지침에 따라 [구독 담당자를 변경](#change-your-subscription-contact)합니다.

### 오류: `Email has already been taken` {#error-email-has-already-been-taken}

등록하려는 이메일 주소가 이미 Customers Portal에서 사용 중인 경우 다음 중 하나를 수행할 수 있습니다:

- 대체 이메일 주소를 제공합니다.
- 구독 소유권을 이전합니다.
