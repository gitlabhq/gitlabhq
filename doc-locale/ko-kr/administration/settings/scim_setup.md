---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Self-Managed 또는 GitLab Dedicated를 위한 SCIM 구성
description: 자동 계정 프로비저닝으로 사용자 수명 주기를 관리합니다.
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

개방형 표준인 System for Cross-domain Identity Management(SCIM)을 사용하여 다음을 자동으로 수행할 수 있습니다:

- 사용자를 생성합니다.
- 사용자를 차단합니다.
- 사용자를 다시 추가합니다(SCIM 식별을 다시 활성화합니다).

[내부 GitLab SCIM API](../../development/internal_api/_index.md#instance-scim-api) 는 [RFC7644 프로토콜](https://www.rfc-editor.org/rfc/rfc7644)의 일부를 구현합니다.

GitLab.com 사용자인 경우 [GitLab.com 그룹용 SCIM 구성](../../user/group/saml_sso/scim_setup.md)을 참조하세요.

## GitLab 구성 {#configure-gitlab}

전제 조건:

- [SAML Single Sign-On](../../integration/saml.md)이 구성되어 있어야 합니다.
- 관리자 액세스 권한이 있어야 합니다.

GitLab SCIM을 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **SCIM 토큰** 섹션을 확장하고 **SCIM 토큰 생성**을 선택합니다.
1. ID 공급자 구성을 위해 다음을 저장합니다:
   - **내 SCIM 토큰** 필드의 토큰입니다.
   - **SCIM API 엔드포인트 URL** 필드의 URL입니다.

## ID 공급자 구성 {#configure-an-identity-provider}

GitLab은 여러 ID 공급자에서 SCIM을 지원합니다. 다른 ID 공급자도 GitLab에서 작동할 수 있지만 테스트되지 않았으며 지원되지 않습니다. 지원되지 않는 공급자에 대한 도움이 필요하면 공급자에 직접 문의하세요. GitLab Support은 관련 로그 항목을 검토하는 데 도움을 드릴 수 있습니다.

### Okta 구성 {#configure-okta}

[Single Sign-On](../../integration/saml.md) 설정 중에 생성된 SAML 애플리케이션을 Okta용으로 SCIM에 맞게 설정해야 합니다.

전제 조건:

- [Okta Lifecycle Management](https://www.okta.com/products/lifecycle-management/) 제품을 사용해야 합니다. 이 제품 계층은 Okta에서 SCIM을 사용하는 데 필요합니다.
- [GitLab이 SCIM을 위해 구성되어](#configure-gitlab) 있습니다.
- [Okta](https://developer.okta.com/docs/guides/build-sso-integration/saml2/main/) SAML 애플리케이션을 [Okta 설정 메모](../../integration/saml.md#set-up-okta)에서 설명한 대로 설정합니다.
- Okta SAML 설정이 [구성 단계](_index.md)와 일치해야 하며, 특히 NameID 구성이 일치해야 합니다.

Okta를 SCIM용으로 구성하려면:

1. Okta에 로그인합니다.
1. 오른쪽 위 모서리에서 **Admin**을 선택합니다. 버튼은 **운영자** 영역에서 표시되지 않습니다.
1. **Application** 탭에서 **Browse App Catalog**를 선택합니다.
1. **GitLab** 애플리케이션을 찾아 선택합니다.
1. GitLab 애플리케이션 개요 페이지에서 **Add Integration**을 선택합니다.
1. **Application Visibility** 아래에서 두 체크박스를 모두 선택합니다. GitLab 애플리케이션은 SAML 인증을 지원하지 않으므로 아이콘이 사용자에게 표시되지 않아야 합니다.
1. **완료**를 선택하여 애플리케이션 추가를 마칩니다.
1. **Provisioning** 탭에서 **Configure API integration**을 선택합니다.
1. **Enable API integration**을 선택합니다.
   - **Base URL**의 경우 GitLab SCIM 구성 페이지에서 **SCIM API 엔드포인트 URL**에서 복사한 URL을 붙여넣습니다.
   - **API Token**의 경우 GitLab SCIM 구성 페이지에서 **내 SCIM 토큰**에서 복사한 SCIM 토큰을 붙여넣습니다.
1. 구성을 확인하려면 **Test API Credentials**를 선택합니다.
1. **Save**를 선택합니다.
1. API 통합 세부 정보를 저장한 후 왼쪽에 새로운 설정 탭이 나타납니다. **To App**을 선택합니다.
1. **편집**을 선택합니다.
1. **사용** 체크박스를 선택하여 **Create Users** 및 **Deactivate Users** 모두를 활성화합니다.
1. **Save**를 선택합니다.
1. **할당** 탭에서 사용자를 할당합니다. 할당된 사용자는 GitLab 그룹에서 생성되고 관리됩니다.

### Microsoft Entra ID 구성 {#configure-microsoft-entra-id}

{{< history >}}

- GitLab 16.10에서 Microsoft Entra ID 용어로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143146)되었습니다.

{{< /history >}}

전제 조건:

- [GitLab이 SCIM을 위해 구성되어](#configure-gitlab) 있습니다.
- [Microsoft Entra ID용 SAML 애플리케이션이 설정되어](../../integration/saml.md#set-up-microsoft-entra-id) 있습니다.

[Single Sign-On](../../integration/saml.md) 설정 중에 생성된 SAML 애플리케이션을 [Azure Active Directory](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/view-applications-portal)용으로 SCIM에 맞게 설정해야 합니다. 예를 들어 [예제 구성](../../user/group/saml_sso/example_saml_config.md#scim-mapping)을 참조하세요.

> [!note]
> SCIM 프로비저닝을 다음 지침에서 설명한 대로 정확하게 구성해야 합니다. 잘못 구성하면 사용자 프로비저닝 및 로그인 이슈가 발생하며 이를 해결하려면 많은 노력이 필요합니다. 문제가 있거나 어느 단계에서든 질문이 있으면 GitLab Support에 문의하세요.

Microsoft Entra ID를 구성하려면 다음을 구성합니다:

- SCIM용 Microsoft Entra ID입니다.
- 설정입니다.
- 속성 매핑을 포함한 매핑입니다.

#### SCIM용 Microsoft Entra ID 구성 {#configure-microsoft-entra-id-for-scim}

1. 앱에서 **Provisioning** 탭으로 이동하고 **시작하기**를 선택합니다.
1. **Provisioning Mode**를 **Automatic**으로 설정합니다.
1. 다음 값을 사용하여 **Admin Credentials**을 완성합니다:
   - GitLab의 **SCIM API 엔드포인트 URL**을 **Tenant URL** 필드에 입력합니다.
   - GitLab의 **내 SCIM 토큰**을 **Secret Token** 필드에 입력합니다.
1. **Test Connection**을 선택합니다.

   테스트가 성공하면 구성을 저장합니다.

   테스트가 실패하면 [문제 해결](../../user/group/saml_sso/troubleshooting.md)을 참조하여 이를 해결하세요.
1. **Save**를 선택합니다.

저장한 후 **Mappings** 및 **설정** 섹션이 나타납니다.

#### 매핑 구성 {#configure-mappings}

**Mappings** 섹션 아래에서 먼저 그룹을 프로비저닝합니다:

1. **Provision Microsoft Entra ID Groups**를 선택합니다.
1. 속성 매핑 페이지에서 **활성화** 토글을 끕니다.

   SCIM 그룹 프로비저닝은 GitLab에서 지원되지 않습니다. 그룹 프로비저닝을 활성화된 상태로 두면 SCIM 사용자 프로비저닝이 중단되지는 않지만 Entra ID SCIM 프로비저닝 로그에서 혼동을 주고 오도할 수 있는 오류가 발생합니다.

   > [!note]
   > **Provision Microsoft Entra ID Groups**가 비활성화되었을 때도 매핑 섹션에 **활성화: 예**가 표시될 수 있습니다. 이것은 표시 버그이며 안전하게 무시할 수 있습니다.

1. **Save**를 선택합니다.

다음으로 사용자를 프로비저닝합니다:

1. **Provision Microsoft Entra ID Users**를 선택합니다.
1. **활성화** 토글이 **예**로 설정되어 있는지 확인합니다.
1. 모든 **Target Object Actions**이 활성화되어 있는지 확인합니다.
1. **Attribute Mappings** 아래에서 [구성된 속성 매핑](#configure-attribute-mappings)과 일치하도록 매핑을 구성합니다:
   1. 선택사항. **customappsso Attribute** 열에서 `externalId`을 찾아 삭제합니다.
   1. 첫 번째 속성을 다음과 같이 편집합니다:
      - `objectId`의 **source attribute**입니다.
      - `externalId`의 **target attribute**입니다.
      - `1`의 **matching precedence**입니다.
   1. 기존 **customappsso** 속성을 [구성된 속성 매핑](#configure-attribute-mappings)과 일치하도록 업데이트합니다.
   1. [속성 매핑 테이블](#configure-attribute-mappings)에 없는 추가 속성을 삭제합니다. 삭제하지 않아도 문제가 발생하지는 않지만 GitLab이 속성을 사용하지 않습니다.
1. 매핑 목록 아래에서 **Show advanced options** 체크박스를 선택합니다.
1. **Edit attribute list for customappsso** 링크를 선택합니다.
1. `id`이 기본 필수 필드인지 확인하고 `externalId`도 필수인지 확인합니다.
1. **저장**을 선택하면 속성 매핑 구성 페이지로 돌아갑니다.
1. **Attribute Mapping** 구성 페이지를 닫으려면 오른쪽 위 모서리에서 `X`을 선택합니다.

##### 속성 매핑 구성 {#configure-attribute-mappings}

> [!note]
> Microsoft가 Azure Active Directory에서 Entra ID 명명 방식으로 전환하는 동안 사용자 인터페이스에서 불일치가 나타날 수 있습니다. 문제가 있으면 이 문서의 이전 버전을 보거나 GitLab Support에 문의할 수 있습니다.

Entra ID를 SCIM용으로 구성하는 동안 속성 매핑을 구성합니다. 예를 들어 [예제 구성](../../user/group/saml_sso/example_saml_config.md#scim-mapping)을 참조하세요.

다음 테이블은 GitLab에 필요한 속성 매핑을 제공합니다.

| 소스 속성                                                           | 대상 속성               | 일치 우선순위 |
|:---------------------------------------------------------------------------|:-------------------------------|:--------------------|
| `objectId`                                                                 | `externalId`                   | 1                   |
| `userPrincipalName` 또는 `mail` <sup>1</sup>                                 | `emails[type eq "work"].value` |                     |
| `mailNickname`                                                    | `userName`                     |                     |
| `displayName` 또는 `Join(" ", [givenName], [surname])` <sup>2</sup>          | `name.formatted`               |                     |
| `Switch([IsSoftDeleted], , "False", "True", "True", "False")` <sup>3</sup> | `active`                       |                     |

**각주**:

1. `mail`을 `userPrincipalName`이 이메일 주소가 아니거나 전달할 수 없을 때 소스 속성으로 사용합니다.
1. `displayName`이 `Firstname Lastname` 형식과 일치하지 않으면 `Join` 표현을 사용합니다.
1. 이것은 직접 매핑이 아닌 표현 매핑 유형입니다. **Mapping type** 드롭다운 목록에서 **Expression**을 선택합니다.

각 속성 매핑은:

- **target attribute**과 일치하는 **customappsso Attribute**입니다.
- **source attribute**과 일치하는 **Microsoft Entra ID Attribute**입니다.
- 일치 우선순위입니다.

각 속성의 경우:

1. 기존 속성을 편집하거나 새 속성을 추가합니다.
1. 드롭다운 목록에서 필요한 소스 및 대상 속성 매핑을 선택합니다.
1. **확인**을 선택합니다.
1. **Save**를 선택합니다.

SAML 구성이 [권장 SAML 설정](../../integration/saml.md)과 다르면 매핑 속성을 선택하고 적절히 수정합니다. `externalId` 대상 속성으로 매핑하는 소스 속성은 SAML `NameID`에 사용되는 속성과 일치해야 합니다.

테이블에 나열되지 않은 매핑은 Microsoft Entra ID 기본값을 사용합니다. 필수 속성 목록은 [내부 인스턴스 SCIM API](../../development/internal_api/_index.md#instance-scim-api) 문서를 참조하세요.

#### 설정 구성 {#configure-settings}

**설정** 섹션 아래:

1. 선택사항. 원하면 **Send an email notification when a failure occurs** 체크박스를 선택합니다.
1. 선택사항. 원하면 **Prevent accidental deletion** 체크박스를 선택합니다.
1. 필요한 경우 **저장**을 선택하여 모든 변경 사항이 저장되었는지 확인합니다.

매핑 및 설정을 구성한 후 앱 개요 페이지로 돌아가 **Start provisioning**을 선택하여 GitLab에서 자동 SCIM 사용자 프로비저닝을 시작합니다.

> [!warning]
> 동기화되면 `id`과 `externalId`에 매핑된 필드를 변경하면 오류가 발생할 수 있습니다. 여기에는 프로비저닝 오류, 중복 사용자가 포함되며 기존 사용자가 GitLab 그룹에 액세스하지 못할 수 있습니다.

## 액세스 제거 {#remove-access}

ID 공급자에서 사용자를 제거하거나 비활성화하면 GitLab 인스턴스에서 사용자가 차단되며 SCIM 식별은 GitLab 사용자에 연결된 상태로 유지됩니다.

사용자 SCIM 식별을 업데이트하려면 [내부 GitLab SCIM API](../../development/internal_api/_index.md#update-a-single-scim-provisioned-user-1)를 사용합니다.

## 액세스 다시 활성화 {#reactivate-access}

{{< history >}}

- GitLab 16.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/379149) 되었으며 [플래그](../feature_flags/_index.md)라고 하는 `skip_saml_identity_destroy_during_scim_deprovision`입니다. 기본적으로 비활성화됨.
- GitLab 16.4에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121226)합니다. 기능 플래그 `skip_saml_identity_destroy_during_scim_deprovision` 제거됨.

{{< /history >}}

사용자가 SCIM을 통해 제거되거나 비활성화된 후 SCIM ID 공급자에 추가하여 해당 사용자를 다시 활성화할 수 있습니다.

ID 공급자가 구성된 일정에 따라 동기화를 수행하면 사용자의 SCIM 식별이 다시 활성화되고 GitLab 인스턴스 액세스가 복원됩니다.

## SCIM을 사용한 그룹 동기화 {#group-synchronization-with-scim}

{{< history >}}

- GitLab 18.0에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/15990) 되었으며 [플래그](../feature_flags/_index.md)라고 하는 `self_managed_scim_group_sync`입니다. 기본적으로 비활성화됨.
- GitLab 18.2에서 [GitLab Self-Managed에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/553662)됨(기본값).
- GitLab 18.6에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/554271)합니다. 기능 플래그 `self_managed_scim_group_sync` 제거됨.

{{< /history >}}

사용자 프로비저닝 외에도 SCIM을 사용하여 ID 공급자와 GitLab 간에 그룹 구성원을 동기화할 수 있습니다. 이 방법을 사용하면 ID 공급자의 그룹 구성원을 기반으로 GitLab 그룹에서 자동으로 사용자를 추가 및 제거할 수 있습니다.

전제 조건:

- [SAML 그룹 링크](../../user/group/saml_sso/group_sync.md#configure-saml-group-links)를 먼저 구성해야 합니다.
- ID 공급자의 SAML 그룹 이름은 GitLab에 구성된 SAML 그룹 이름과 일치해야 합니다.

SCIM 그룹 동기화는 SAML 그룹 링크와 함께 작동하여 그룹 구성원을 관리합니다. ID 공급자가 SCIM API를 통해 그룹 구성원 변경을 보낼 때 GitLab은 해당 SCIM 그룹과 연결된 SAML 그룹 링크가 있는 모든 GitLab 그룹의 사용자 구성원을 업데이트합니다.

SCIM은 일방향 프로토콜입니다. 변경 사항은 ID 공급자에서 GitLab으로 흐릅니다. GitLab에서 SAML 그룹 링크를 변경하면(추가 또는 제거하는 등) ID 공급자는 SCIM을 통해 이러한 변경 사항을 감지할 수 없습니다.

### 새 그룹 링크의 알려진 제한 {#known-limitation-of-new-group-links}

ID 공급자가 처음으로 SCIM 그룹을 프로비저닝할 때(`POST /Groups` 통해) GitLab은 SCIM 그룹 ID를 일치하는 그룹 이름을 가진 모든 기존 SAML 그룹 링크와 연결합니다. 그러나 초기 프로비저닝 후에 동일한 그룹 이름으로 새 SAML 그룹 링크를 추가하면 새 그룹 링크가 SCIM 그룹 ID와 자동으로 연결되지 않습니다. 이는 ID 공급자로부터의 SCIM 구성원 업데이트가 새로 추가된 그룹 링크의 사용자에게 영향을 주지 않음을 의미합니다.

개선 지원이 [이슈 582729](https://gitlab.com/gitlab-org/gitlab/-/issues/582729)에서 제안됩니다.

> [!note]
> 모든 그룹 링크가 처음부터 SCIM 그룹과 연결되어 있으려면 ID 공급자에서 SCIM 그룹 프로비저닝을 설정하기 전에 모든 SAML 그룹 링크를 구성해야 합니다.

초기 프로비저닝 후에 그룹 링크를 추가해야 하는 경우 ID 공급자에서 SCIM 그룹 프로비저닝을 삭제(IdP 그룹 자체는 아님)한 후 다시 만들어 ID 공급자에서 SCIM 그룹을 다시 프로비저닝할 수 있습니다. 이 작업은 모든 현재 SAML 그룹 링크를 SCIM 그룹과 다시 연결합니다. 자세한 내용은 ID 공급자의 SCIM 그룹 프로비저닝 관리에 대한 문서를 참조하세요.

GitLab에서 SAML 그룹 링크를 삭제하면 해당 링크를 통한 그룹의 구성원은 그룹에 남아있습니다. 그러나 그룹 링크가 제거되었으므로 SCIM은 더 이상 해당 그룹에서 구성원을 관리하지 않습니다. 필요한 경우 수동으로 [그룹에서 구성원을 제거](../../user/group/_index.md#remove-a-member-from-the-group)할 수 있습니다.

### ID 공급자에서 그룹 동기화 구성 {#configure-group-synchronization-in-your-identity-provider}

ID 공급자에서 그룹 동기화를 구성하는 자세한 지침은 공급자의 문서를 참조하세요. 예시는 다음과 같습니다:

- [Okta Groups API](https://developer.okta.com/docs/reference/api/groups/)
- [Microsoft Entra ID(Azure AD) SCIM 그룹](https://learn.microsoft.com/en-us/entra/identity/app-provisioning/use-scim-to-provision-users-and-groups) \- 기본적으로 `displayName` 소스 속성은 사용자 친화적인 이름을 가진 SAML 그룹 링크를 찾는 데 사용됩니다. - 그러나 SAML 그룹 링크가 이름에 개체 ID를 사용하는 경우 소스 속성을 `objectId`로 업데이트해야 합니다.

> [!warning]
> 여러 SAML 그룹 링크가 동일한 GitLab 그룹에 매핑되면 사용자는 모든 매핑 그룹 링크에서 가장 높은 역할이 할당됩니다. IdP 그룹에서 제거된 사용자는 다른 SAML 그룹이 해당 그룹과 연결되어 있으면 GitLab 그룹에 남아있습니다.

Okta 애플리케이션 카탈로그의 표준 GitLab SCIM 애플리케이션은 그룹 동기화를 지원하지 않습니다. 대신 Okta를 사용하여 그룹 동기화를 위한 사용자 정의 SCIM 통합을 만들 수 있습니다. 자세한 내용은 [이슈 582729](https://gitlab.com/gitlab-org/gitlab/-/issues/582729)를 참조하세요.

## 문제 해결 {#troubleshooting}

[SCIM 문제 해결 가이드](../../user/group/saml_sso/troubleshooting_scim.md)를 참조하세요.
