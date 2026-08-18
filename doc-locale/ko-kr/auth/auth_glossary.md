---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 인증 및 권한 부여 용어집
description: "인증, 권한 부여, 권한, 역할 및 액세스 제어 용어."
---

이 용어집은 GitLab의 인증, 권한 부여 및 액세스 제어와 관련된 용어를 정의합니다.

## ID 및 페더레이션 {#identity-and-federation}

시스템 전체에서 사용자 ID를 설정하고 확인하는 외부 ID 공급자 및 프로토콜입니다. 이 용어들은 GitLab이 엔터프라이즈 ID 관리 시스템과 통합되어 사용자 인증을 중앙 집중식으로 관리하는 방식을 설명합니다.

ID 공급자(IdP) : Okta 또는 OneLogin과 같은 사용자 ID를 관리하는 서비스입니다.

서비스 공급자(SP) : 인증을 외부 ID 공급자에게 위임하는 애플리케이션입니다. SAML 또는 OIDC 인증으로 구성될 때 GitLab은 서비스 공급자 역할을 합니다.

Single Sign-On(SSO) : 사용자가 단일 자격 증명 세트로 여러 애플리케이션에 액세스할 수 있도록 하는 인증 방법입니다. SSO를 사용하면 사용자가 ID 공급자를 통해 한 번 인증한 후 자격 증명을 다시 입력하지 않고 GitLab 및 기타 연결된 서비스에 액세스할 수 있습니다.

SAML : ID 공급자와 서비스 공급자 간의 인증 및 권한 부여 데이터를 교환하기 위한 XML 기반 프로토콜인 Security Assertion Markup Language입니다. GitLab은 엔터프라이즈 Single Sign-On을 위해 [SAML 인증](../integration/saml.md)을 지원합니다.

LDAP : 디렉토리 정보 서비스에 액세스하고 유지하기 위한 표준인 Lightweight Directory Access Protocol입니다. GitLab은 [LDAP 서버](../administration/auth/ldap/_index.md)와 통합되어 사용자를 인증하고 계정 정보를 동기화합니다.

SCIM : 사용자 프로비저닝 및 프로비저닝 해제를 자동화하기 위한 표준인 System for Cross-domain Identity Management입니다. GitLab은 [SCIM](../user/group/saml_sso/scim_setup.md)을 지원하여 ID 공급자로부터 사용자 수명 주기 이벤트를 동기화합니다.

OIDC(OpenID Connect) : ID 확인을 제공하는 OAuth 2.0 기반의 인증 계층입니다. GitLab은 인증을 위해 [OIDC](../administration/auth/oidc.md)를 지원하며 외부 애플리케이션을 위한 OIDC 공급자로 작동합니다.

OAuth : 비밀번호를 공유하지 않고 사용자를 대신하여 GitLab 리소스에 액세스하기 위한 권한 부여 프로토콜입니다. [OAuth](../integration/oauth_provider.md)는 타사 통합 및 ID 공급자로서의 GitLab을 지원합니다.

Assertion : 이름이나 역할과 같은 사용자 ID에 대한 정보입니다. 클레임 또는 속성으로도 알려져 있습니다.

Claim : 인증 토큰에 포함된 사용자 ID 또는 속성에 대한 정보입니다. 클레임은 OAuth, OIDC 및 JWT 토큰에서 사용자 이름, 이메일 또는 그룹 멤버십과 같은 세부 정보를 전달하는 데 사용됩니다.

Provisioning : 사용자 계정 및 액세스 권한을 생성하고 구성하는 자동화된 프로세스입니다. SCIM 또는 LDAP를 사용하여 외부 ID 시스템의 사용자를 GitLab으로 동기화할 수 있습니다.

Assertion consumer service URL : 사용자가 ID 공급자를 사용하여 성공적으로 인증한 후 리디렉션되는 GitLab의 엔드포인트입니다.

Issuer : GitLab이 ID 공급자에게 자신을 식별하는 방식입니다. 신뢰 당사자 신뢰 식별자로도 알려져 있습니다.

Certificate fingerprint : SAML 통신이 서버가 올바른 인증서로 통신에 서명하고 있는지 확인하여 보안을 확보합니다. 인증서 지문으로도 알려져 있습니다.

## 인증 {#authentication}

GitLab에 대한 액세스 권한을 부여하기 전에 사용자 ID를 확인하는 방법 및 자격 증명입니다. 인증은 시스템에 대한 액세스 권한을 부여하기 전에 사용자의 신원을 확인합니다. [인증 방법](user_authentication.md)에는 비밀번호, 2단계 인증, SSH 키, 개인 액세스 토큰 및 외부 ID 공급자와의 통합이 포함됩니다.

Passkey : 디바이스에 저장된 암호화 자격 증명을 사용하는 비밀번호 없는 인증 방법입니다. [Passkey](passkeys.md)는 생체 인식 또는 디바이스 PIN을 사용하는 피싱 방지 인증을 제공합니다.

2단계 인증(2FA) : 사용자가 비밀번호 외에 두 번째 형식의 인증을 제공하도록 요구하는 추가 보안 계층입니다. GitLab은 인증 앱 및 복구 코드를 포함한 다양한 [2FA 방법](../user/profile/account/two_factor_authentication.md)을 지원합니다.

Session : 사용자가 GitLab에 로그인한 후 유지되는 임시 인증된 상태입니다. 세션은 세션이 만료되거나 종료될 때까지 요청 간에 유지됩니다.

SSH 키 : Git 리포지토리에 액세스할 때 안전한 인증을 위해 사용되는 암호화 키입니다. [SSH 키](../user/ssh.md)는 Git 작업을 위한 비밀번호 기반 인증에 대한 안전한 대안을 제공합니다.

개인 액세스 토큰 : GitLab API 또는 Git over HTTPS를 사용할 때 인증을 위해 비밀번호 대신 사용되는 토큰입니다. [개인 액세스 토큰](../user/profile/personal_access_tokens.md)은 수행할 수 있는 작업을 제한하는 정의된 범위를 가집니다.

Group access token : 해당 그룹 및 모든 하위 그룹의 자동화된 작업을 위해 특정 그룹으로 범위가 지정된 토큰입니다. [Group access token](../user/group/settings/group_access_tokens.md)은 그룹 권한을 상속하며 API 액세스 및 Git 작업을 지원합니다.

프로젝트 액세스 토큰 : 해당 프로젝트의 자동화된 작업을 위해 특정 프로젝트로 범위가 지정된 토큰입니다. [프로젝트 액세스 토큰](../user/project/settings/project_access_tokens.md)은 일반적으로 CI/CD 파이프라인 및 프로젝트 특정 액세스가 필요한 통합에 사용됩니다.

배포 토큰 : 배포 자동화를 위한 제한된 범위의 토큰입니다. [배포 토큰](../user/project/deploy_tokens/_index.md)은 사용자 계정이 필요하지 않고 리포지토리 및 패키지 레지스트리에 대한 읽기 전용 또는 쓰기 액세스를 제공합니다.

JWT(JSON Web Token) : 당사자 간에 정보를 안전하게 전송하기 위한 압축된 토큰 형식입니다. GitLab은 CI/CD 작업 인증, OAuth 플로우 및 서비스 간 통신을 위해 JWT를 사용합니다.

Impersonation : 권한이 있는 사용자가 일시적으로 다른 사용자로 행동할 수 있도록 하는 관리 기능입니다. [Impersonation](../api/rest/authentication.md#impersonation-tokens)은 사용자별 이슈를 해결하는 데 사용되는 경우가 있습니다.

## 사용자 및 계정 관리 {#user-and-account-management}

GitLab에서 다양한 액세스 수준 및 기능을 정의하는 계정 유형 및 사용자 범주입니다. 이 용어들은 시스템과 상호 작용할 수 있는 다양한 종류의 계정을 설명합니다.

User account : GitLab에 액세스하는 사람을 나타내는 개별 계정입니다. 사용자 계정은 서로 다른 그룹 및 프로젝트 전체에서 다양한 역할을 할당받을 수 있습니다.

User types : 사용자 계정에 할당되고 허용 가능한 작업 집합을 암시적으로 부여하는 유형입니다. 유형에는 Regular, Auditor 및 Administrator가 포함됩니다. 유형은 역할 및 권한과 다릅니다.

Administrator users : 가장 높은 수준의 시스템 액세스 권한을 가진 사용자 유형입니다. 관리자 액세스 권한을 가진 사용자는 인스턴스 전체 설정을 구성하고, 다른 사용자를 관리하며, 모든 그룹 및 프로젝트 전체에서 관리 작업을 수행할 수 있습니다.

### Auditor users {#auditor-users}

모든 그룹, 프로젝트 및 관리 함수에 대한 읽기 전용 액세스 권한을 가진 특수 사용자 유형입니다. [Auditor users](../administration/auditor_users.md)는 변경할 수 없지만 규정 준수 및 보안 목적을 위해 콘텐츠를 볼 수 있습니다.

External users : 조직 외부로 지정되어 내부 프로젝트 및 그룹에 대한 액세스가 제한되는 사용자입니다. [External users](../administration/external_users.md)는 직접 멤버십이 있는 프로젝트에만 액세스할 수 있습니다.

서비스 계정 : 자동화된 작업을 수행하고, 데이터에 액세스하거나 예약된 프로세스를 실행하도록 설계된 비인간 사용자 계정입니다. [서비스 계정](../user/profile/service_accounts.md)은 일반적으로 파이프라인 또는 타사 통합에서 사용됩니다.

## 권한 부여 및 액세스 제어 {#authorization-and-access-control}

GitLab에서 인증된 사용자가 수행할 수 있는 작업을 결정하는 프레임워크 및 프로세스입니다. 권한 부여는 사용자 ID, 역할 및 리소스 소유권을 기반으로 권한을 평가합니다.

Access control : 인증(사용자가 누구인지 확인)과 권한 부여(사용자가 수행할 수 있는 작업 결정)를 기반으로 리소스에 대한 액세스를 제한하는 관행입니다.

Authorization : 인증된 사용자가 GitLab에서 수행할 수 있는 작업을 결정하는 프로세스입니다. 권한 부여는 할당된 사용자 역할, 권한 및 그룹 및 프로젝트의 멤버십을 기반으로 합니다.

RBAC(Role-Based Access Control) : 사용자에게 직접 권한을 할당하기보다는 역할을 통해 권한을 할당하는 액세스 제어 모델입니다. GitLab에서는 사용자가 그룹 또는 프로젝트에서 할당된 역할을 기반으로 권한을 받습니다.

Policy : 보안 주체가 리소스에 대해 수행할 수 있는 작업을 결정하는 권한 부여 규칙 집합입니다. GitLab은 [Declarative Policy framework](../development/policies.md)를 사용하여 액세스 제어 결정을 시행합니다.

## 권한 및 역할 {#permissions-and-roles}

사용자가 리소스에 대해 수행할 수 있는 작업을 정의하는 구성 요소입니다. 권한은 역할로 결합되며, 이는 사용자에게 할당되어 특정 기능을 부여합니다.

Permission : 사용자가 GitLab 리소스에 대해 수행할 수 있는 [특정 작업](../user/permissions.md)(이슈 생성, 코드 푸시 또는 프로젝트 설정 관리)입니다.

Roles : 사용자에게 할당되어 그룹 및 프로젝트에서 수행할 수 있는 작업을 정의하는 하나 이상의 권한 집합입니다. 역할에는 기본 역할과 사용자 지정 역할이 모두 포함됩니다.

Default roles : 모든 GitLab 인스턴스에서 사용 가능한 [미리 정의된 역할](../user/permissions.md)입니다. 각 역할에는 특정 권한 집합이 포함됩니다. 사용 가능한 기본 역할은 다음과 같습니다: `Minimal Access`, `Guest`, `Planner`, `Reporter`, `Security Manager`, `Developer`, `Maintainer`, `Owner`.

사용자 지정 역할 : 조직의 요구사항을 충족하기 위해 GitLab 인스턴스에 대해 생성하는 역할입니다. 각 [사용자 지정 역할](../user/custom_roles/_index.md)은 기본 역할을 추가 권한으로 확장합니다.

Scopes : 특정 조직 수준에서 토큰 또는 OAuth 애플리케이션에 사용 가능한 권한입니다. GitLab은 범위를 사용하여 개인 액세스 토큰, group access token, 프로젝트 액세스 토큰 및 OAuth 애플리케이션에 부여된 액세스를 결정합니다.

## 조직 구조 {#organizational-structure}

리소스를 구성하고 액세스를 제어하는 계층적 컨테이너 및 관계입니다. 이러한 구조는 권한이 그룹, 프로젝트 및 네임스페이스를 통해 흐르는 방식을 결정합니다.

네임스페이스 : 그룹과 프로젝트를 계층적 구조로 구성하는 컨테이너입니다. 네임스페이스는 리소스 경로 및 권한 상속을 결정합니다. 각 사용자는 개인 네임스페이스를 가지며, 그룹은 팀을 위한 공유 네임스페이스를 제공합니다.

Group : 효율적인 구성 및 권한 관리를 가능하게 하는 관련 프로젝트 및 사용자의 모음입니다. 그룹은 하위 그룹을 포함할 수 있으며 상위 그룹으로부터 권한을 상속합니다.

Member : 특정 그룹 또는 프로젝트에 액세스가 부여된 사용자입니다. 멤버는 해당 리소스의 권한을 결정하는 할당된 역할을 가집니다.

Membership : 해당 리소스의 액세스 권한을 정의하는 사용자와 특정 그룹 또는 프로젝트 간의 연결입니다. 사용자는 여러 그룹 및 프로젝트 전체에서 서로 다른 멤버십 및 역할을 가질 수 있습니다.

Boundaries : 권한 및 정책을 적용할 수 있는 조직 수준입니다:

<!-- markdownlint-disable MD007 -->

  - Instance: 전체 GitLab 인스턴스에 적용됩니다.
  - Group: 특정 그룹 및 모든 하위 그룹 또는 프로젝트에 적용됩니다.
  - Project: 단일 프로젝트에만 적용됩니다.
  - User: 특정 사용자에 의해 수행되거나 특정 사용자를 대신하여 수행되는 작업에 적용됩니다.

<!-- markdownlint-disable MD007 -->

Inheritance : 상위 그룹에서 하위 그룹 및 프로젝트로의 권한의 자동 플로우입니다. 상속은 더 높은 수준에서 부여된 권한을 모든 중첩된 하위 그룹 및 프로젝트에 적용하여 액세스 관리를 간소화합니다.

Visibility : 콘텐츠를 보고 액세스할 수 있는 사용자를 제어하는 [설정](../user/public_access.md)입니다:

<!-- markdownlint-disable MD007 -->

  - Public: GitLab 계정이 없는 사용자를 포함한 모든 사용자에게 표시됩니다.
  - Internal: 인증된 모든 GitLab 사용자에게 표시됩니다.
  - Private: 멤버에게만 표시됩니다.

<!-- markdownlint-disable MD007 -->
