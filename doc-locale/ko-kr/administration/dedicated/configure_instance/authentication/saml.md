---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Dedicated용 SAML 단일 로그인(SSO) 인증을 구성합니다.
title: GitLab Dedicated용 SAML SSO
---

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab Dedicated

{{< /details >}}

GitLab Dedicated 인스턴스에 최대 10개의 ID 제공자(IdP)를 위해 SAML 단일 로그인(SSO)을 구성할 수 있습니다.

다음 SAML SSO 옵션을 사용할 수 있습니다:

- [요청 서명](#request-signing)
- [그룹용 SAML SSO](#saml-groups)
- [그룹 동기화](#group-sync)

> [!note]
> 이는 GitLab Dedicated 인스턴스의 최종 사용자를 위해 SAML SSO를 구성합니다. Switchboard 관리자용 SSO를 구성하려면 [Switchboard SSO 구성](_index.md#configure-switchboard-sso)을 참고하세요.

## 필수 요구 사항 {#prerequisites}

- GitLab Dedicated용 SAML을 구성하기 전에 [ID 제공자 설정](../../../../integration/saml.md#set-up-identity-providers)을 완료해야 합니다.
- GitLab이 SAML 인증 요청에 서명하도록 구성하려면 GitLab Dedicated 인스턴스에 대한 개인 키와 공개 인증서 쌍을 만들어야 합니다.

## Switchboard를 사용하여 SAML 제공자 추가 {#add-a-saml-provider-with-switchboard}

GitLab Dedicated 인스턴스에 SAML 제공자를 추가하려면 다음을 수행합니다:

1. [Switchboard](https://console.gitlab-dedicated.com/)에 로그인합니다.
1. 페이지 맨 위에서 **구성**을 선택합니다.
1. **SAML providers**를 확장합니다.
1. **Add SAML provider**를 선택합니다.
1. **SAML label** 텍스트 상자에 Switchboard에서 이 제공자를 식별할 이름을 입력합니다.
1. 선택사항. SAML 그룹 멤버십 또는 그룹 동기화를 기반으로 사용자를 구성하려면 다음 필드를 완료합니다:
   - **SAML group attribute**
   - **Admin groups**
   - **Auditor groups**
   - **External groups**
   - **Required groups**
1. **IdP cert fingerprint** 텍스트 상자에 IdP 인증서 지문을 입력합니다. 이 값은 IdP의 `X.509` 인증서 지문의 SHA1 체크섬입니다.
1. **IdP SSO target URL** 텍스트 상자에 GitLab Dedicated이 사용자를 이 제공자로 인증하도록 리디렉션하는 IdP의 URL 엔드포인트를 입력합니다.
1. **Name identifier format** 드롭다운 목록에서 이 제공자가 GitLab에 보내는 NameID 형식을 선택합니다.
1. 선택사항. 요청 서명을 구성하려면 다음 필드를 완료합니다:
   - **발급자**
   - **Attribute statements**
   - **보안**
1. 이 제공자를 사용하기 시작하려면 **Enable this provider** 확인란을 선택합니다.
1. **저장**을 선택합니다.
1. 다른 SAML 제공자를 추가하려면 **Add SAML provider**를 다시 선택하고 이전 단계를 따릅니다. 최대 10개의 제공자를 추가할 수 있습니다.
1. 페이지 상단까지 위로 스크롤합니다. **Initiated changes** 배너는 SAML 구성 변경 사항이 다음 유지보수 기간 동안 적용됨을 설명합니다. 변경 사항을 즉시 적용하려면 **Apply changes now**을 선택합니다.

변경 사항이 적용된 후 이 SAML 제공자를 사용하여 GitLab Dedicated 인스턴스에 로그인할 수 있습니다. 그룹 동기화를 사용하려면 [SAML 그룹 링크 구성](../../../../user/group/saml_sso/group_sync.md#configure-saml-group-links)을 수행합니다.

## SAML 구성 확인 {#verify-your-saml-configuration}

SAML 구성이 성공적인지 확인하려면 다음을 수행합니다:

1. 로그아웃하고 GitLab Dedicated 인스턴스의 로그인 페이지로 이동합니다.
1. SAML 제공자의 SSO 버튼이 로그인 페이지에 표시되는지 확인합니다.
1. 인스턴스의 메타데이터 URL로 이동합니다(`https://INSTANCE-URL/users/auth/saml/metadata`). 메타데이터 URL은 ID 제공자 구성을 간단하게 하고 SAML 설정을 확인하는 데 도움이 되는 정보를 표시합니다.
1. SAML 제공자를 통해 로그인을 시도하여 인증 플로우가 올바르게 작동하는지 확인합니다.

문제 해결 정보를 확인하려면 [SAML 문제 해결](../../../../user/group/saml_sso/troubleshooting.md)을 참고하세요.

## 지원 요청을 통해 SAML 제공자 추가 {#add-a-saml-provider-with-a-support-request}

Switchboard를 사용하여 GitLab Dedicated 인스턴스에 대해 SAML을 추가하거나 업데이트할 수 없는 경우 [지원 티켓](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)을 열 수 있습니다:

1. 필요한 변경을 수행하려면 지원 티켓에 GitLab 애플리케이션에 대해 원하는 [SAML 구성 블록](../../../../integration/saml.md#configure-saml-support-in-gitlab)을 포함합니다. 최소한 GitLab은 인스턴스에 SAML을 활성화하기 위해 다음 정보가 필요합니다:
   - IDP SSO 대상 URL
   - 인증서 지문 또는 인증서
   - NameID 형식
   - SSO 로그인 버튼 설명

   ```json
   "saml": {
     "attribute_statements": {
         //optional
     },
     "enabled": true,
     "groups_attribute": "",
     "admin_groups": [
       // optional
     ],
     "idp_cert_fingerprint": "43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8",
     "idp_sso_target_url": "https://login.example.com/idp",
     "label": "IDP Name",
     "name_identifier_format": "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
     "security": {
       // optional
     },
     "auditor_groups": [
       // optional
     ],
     "external_groups": [
       // optional
     ],
     "required_groups": [
       // optional
     ],
   }
   ```

1. GitLab이 SAML 구성을 인스턴스에 배포한 후 지원 티켓에서 알림을 받습니다.
1. SAML 구성이 성공적인지 확인하려면 다음을 수행합니다:
   - SSO 로그인 버튼 설명이 인스턴스의 로그인 페이지에 표시되는지 확인합니다.
   - 인스턴스의 메타데이터 URL로 이동합니다. 이 URL은 GitLab이 지원 티켓에서 제공합니다. 이 페이지는 ID 제공자 구성의 대부분을 간단하게 하고 설정을 수동으로 확인하는 데 사용할 수 있습니다.

## 요청 서명 {#request-signing}

[SAML 요청 서명](../../../../integration/saml.md#sign-saml-authentication-requests-optional)이 원하는 경우 인증서를 획득해야 합니다. 이 인증서는 자체 서명될 수 있으며, 이는 임의의 일반 이름(CN)에 대한 소유권을 공개 인증서 기관(CA)에 증명할 필요가 없다는 장점이 있습니다.

> [!note]
> SAML 요청 서명은 인증서 서명이 필요하므로 이 기능이 활성화된 SAML을 사용하려면 이 단계를 완료해야 합니다.

SAML 요청 서명을 활성화하려면 다음을 수행합니다:

1. [지원 티켓](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)을 열고 요청 서명을 활성화하려고 함을 나타냅니다.
1. GitLab은 서명할 인증서 서명 요청(CSR)을 보내는 것에 대해 사용자와 함께 작업합니다. 또는 CSR을 공개 CA로 서명할 수 있습니다.
1. 인증서가 서명된 후 인증서와 관련 개인 키를 사용하여 Switchboard의 [SAML 구성](#add-a-saml-provider-with-switchboard)의 `security` 섹션을 완료할 수 있습니다.

GitLab에서 ID 제공자로의 인증 요청은 이제 서명될 수 있습니다.

## SAML 그룹 {#saml-groups}

SAML 그룹을 사용하면 SAML 그룹 멤버십을 기반으로 GitLab 사용자를 구성할 수 있습니다.

SAML 그룹을 활성화하려면 [필수 요소](../../../../integration/saml.md#configure-users-based-on-saml-group-membership) 를 [Switchboard](#add-a-saml-provider-with-switchboard) 의 SAML 구성에 추가하거나 [지원 티켓](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)에서 제공하는 SAML 블록에 추가합니다.

## 그룹 동기화 {#group-sync}

[그룹 동기화](../../../../user/group/saml_sso/group_sync.md)를 사용하면 ID 제공자 그룹의 사용자를 GitLab의 매핑된 그룹과 동기화할 수 있습니다.

그룹 동기화를 활성화하려면 다음을 수행합니다:

1. [필수 요소](../../../../user/group/saml_sso/group_sync.md#configure-saml-group-sync) 를 [Switchboard](#add-a-saml-provider-with-switchboard) 의 SAML 구성에 추가하거나 [지원 티켓](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)에서 제공하는 SAML 구성 블록에 추가합니다.
1. [그룹 링크](../../../../user/group/saml_sso/group_sync.md#configure-saml-group-links)를 구성합니다.
