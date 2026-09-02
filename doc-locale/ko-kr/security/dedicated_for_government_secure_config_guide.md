---
stage: GitLab Dedicated
group: US Public Sector Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>.
title: GitLab Dedicated for Government 보안 구성 가이드
---

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Dedicated for Government

{{< /details >}}

FedRAMP는 클라우드 서비스 제공자에게 [보안 구성 가이드](https://www.fedramp.gov/docs/rev5/balance/secure-configuration-guide/)를 작성, 유지 관리 및 게시할 것을 요구합니다. 이 명령에는 필수 및 권장 기준이 모두 포함됩니다. 이 페이지를 사용하여 Dedicated for Government 인스턴스를 강화하고 최신 FedRAMP 지침에 맞춥니다.

필수 기준:

- 전체 클라우드 서비스 제공에 대한 엔터프라이즈 액세스를 제어하는 최상위 관리자 계정에 안전하게 액세스, 구성, 운영 및 해제하는 방법에 대한 지침입니다.
- 최상위 관리자 계정에서만 운영할 수 있는 보안 관련 설정 및 보안 영향에 대한 설명입니다.

권장 기준:

- 권한이 있는 계정에서만 운영할 수 있는 보안 관련 설정 및 보안 영향에 대한 설명입니다.
- 초기에 프로비저닝될 때 최상위 관리자 계정 및 권한 있는 계정에 대한 보안 기본값입니다.

GitLab은 미국 연방 기관 및 공공 부문을 담당하는 조직을 위해 광범위한 구성 지침을 제공합니다. [투명성을 핵심 가치](https://handbook.gitlab.com/handbook/values/#transparency)로 삼아, [GitLab 문서](https://docs.gitlab.com)는 이미 보안 구성 가이드의 필수 요소를 자세히 다루고 있습니다.

## 아키텍처 {#architecture}

[GitLab Dedicated for Government](../subscriptions/gitlab_dedicated_for_government/_index.md)는 정부 기관을 위해 목적에 맞게 구축된 단일 테넌트 SaaS 솔루션입니다. [FedRAMP Moderate Authority to Operate (ATO)](https://marketplace.fedramp.gov/products/FR2411959145)를 보유하고 있으며 AWS GovCloud에서 실행되고 완전한 인프라 수준의 격리를 제공합니다. 각 고객 환경은 전용 AWS 계정에 있으며 다른 테넌트와 분리되어 있습니다.

아키텍처에는 두 가지 구분되는 관리 계층이 있습니다:

인프라 관리 계층 : GitLab에서 관리합니다.

애플리케이션 관리 계층 : 고객 관리자가 제어합니다.

이 가이드의 구성 설정을 검토하기 전에 GitLab Dedicated for Government의 [공동 책임 모델](dedicated_for_government_shared_responsibility_model.md)을 검토하세요. 공동 책임 모델은 연방 기관 관리자가 적용해야 할 보안을 강화해야 하는 이유를 이해하기 위한 기초입니다.

## 요구사항 1: 최상위 관리자 계정 수명 주기 {#requirement-1-top-level-administrator-account-lifecycle}

이 섹션은 안전한 설정 및 일상적인 운영부터 안전한 해제까지 최상위 관리자 계정의 전체 수명 주기를 다룹니다.

FedRAMP 요구사항: 전체 클라우드 서비스 제공에 대한 엔터프라이즈 액세스를 제어하는 최상위 관리 계정에 안전하게 액세스, 구성, 운영 및 해제하는 방법을 설명하세요.

### 액세스 수명 주기 {#access-lifecycle}

GitLab Dedicated for Government 인스턴스를 구매하면 GitLab Dedicated 팀이 초기 최상위 관리자 계정을 프로비저닝합니다. 그런 다음 Dedicated 엔지니어는 ID 관리 솔루션과의 통합을 구성하는 데 도움을 줍니다. 구성되면 인스턴스에 대한 액세스 관리를 완벽하게 제어할 수 있습니다.

GitLab Dedicated for Government는 단일 로그인을 위해 [SAML 및 OpenID Connect (OIDC)](../subscriptions/gitlab_dedicated_for_government/_index.md#authentication-and-authorization)를 지원하므로 기존 정부 ID 인프라를 통해 관리 인증을 라우팅할 수 있습니다. FedRAMP에 대한 모든 관련 PIV/CAC 요구사항을 충족하기 위해 ID 제공자를 통합할 책임이 있습니다.

전체 액세스 수명 주기는 다음을 참조하세요:

- [사용자 추가](../user/profile/account/create_accounts.md#create-a-user-with-an-authentication-integration)
- [사용자 제거 또는 삭제](../user/profile/account/delete_account.md#delete-users-and-user-contributions)

관리자는 필요에 따라 다른 관리자를 추가하고 제거할 수 있습니다. GitLab은 전용 관리자 계정을 만들거나 [관리자 모드](../administration/settings/sign_in_restrictions.md#admin-mode)를 켜도록 권장합니다. 이는 관리자가 관리 영역에 액세스하기 전에 명시적으로 세션을 상향식으로 올려야 하는 기본 제공 보안 제어입니다. 어느 접근 방식이든 권한 있는 계정이 해당 권한 있는 기능에만 사용되도록 보장합니다.

ID 플랫폼이 통합되면 최상위 관리자는 초기 사용자 기반을 구축하기 위해 사용자를 프로비저닝할 수 있습니다. 모든 사용자 계정에 최소 권한 원칙을 적용하세요. 프로젝트가 설정되면 프로젝트 수준의 다음 역할을 통해 특정 사용자에게 액세스를 할당할 수 있습니다:

- 최소 액세스
- Guest
- Planner
- Reporter
- Developer
- Maintainer
- Owner

GitLab은 고유한 사용 사례를 위해 다음 사용자 유형을 지원합니다:

- [감사자 사용자](../administration/auditor_users.md): 관리 영역 및 프로젝트 또는 그룹 설정을 제외한 모든 그룹, 프로젝트 및 기타 리소스에 대한 읽기 전용 액세스를 제공합니다. 프로세스를 검증하기 위해 특정 프로젝트에 액세스해야 하는 제3자 감사자와 협력할 때 감사자 역할을 사용하세요.
- [외부 사용자](../administration/external_users.md): 계약자 또는 기타 제3자와 같이 조직 외부의 사용자에게 제한된 액세스를 제공합니다. IA-4(4)와 같은 제어는 조직 외 사용자를 식별하고 회사 정책에 따라 관리해야 합니다. 외부 사용자 설정은 기본적으로 프로젝트에 대한 액세스를 제한하고 관리자가 조직에서 근무하지 않는 사용자를 식별할 수 있도록 하여 위험을 줄입니다.
- [서비스 계정](../user/profile/service_accounts.md): 자동화된 작업을 수용합니다. 서비스 계정은 라이선스에서 사용자를 사용하지 않습니다.

GitLab은 고유한 권한 요구사항을 위해 [사용자 지정 역할](../user/custom_roles/_index.md)을 지원합니다. 자세한 내용은 [프로젝트 권한](../user/permissions.md#project-permissions) 및 [그룹 권한](../user/permissions.md#group-permissions)을 참조하세요.

충분한 사용자 구조가 ID 플랫폼에서 프로비저닝된 관리자와 함께 설정되면 최상위 관리자 계정을 break-glass 계정으로 취급하고 모든 다른 관리 활동은 표준 ID 제공자를 통해 이루어집니다.

## 요구사항 2 {#requirement-2}

FedRAMP 요구사항: 최상위 관리 계정에서만 운영할 수 있는 보안 관련 설정 및 보안 영향에 대한 설명을 제공하세요.

이 섹션은 Dedicated for Government에서 특별히 사용 가능한 구성 설정을 열거하고 고객에게 [GitLab 관리](../administration/_index.md)에 대해 이미 사용 가능한 광범위한 문서를 안내합니다.

### 최상위 관리자에 의한 인프라 구성 {#infrastructure-configurations-by-top-level-administrators}

GitLab Dedicated for Government는 GitLab 지원 팀에 대한 요청을 통해 트리거되는 최상위 고객 관리자가 요청할 수 있는 특정 인프라 수준의 보안 및 아키텍처 구성을 허용합니다.

이러한 구성에는 다음이 포함됩니다:

- 예를 들어 PrivateLink를 통해 테넌트 외부의 리소스와 네트워크 연결을 설정합니다.
- 고객 제공 키 가져오기(Bring-Your-Own-Key) - 고객은 GitLab 테넌트가 고객 제공 키를 사용하도록 요청할 수 있습니다.
- 사용자 지정 도메인 설정 - 고객은 표준 Dedicated for Government 도메인이 아닌 고객 제공 도메인을 사용하도록 GitLab 테넌트를 요청할 수 있습니다. 제공된 도메인이 DNSSEC에 대한 모든 관련 명령을 충족하는지 확인할 책임은 고객의 것입니다.
- 참조 아키텍처 선택
- 총 리포지토리 용량 선택
- 테넌트 이름 선택
- 가용 영역 선택
- 라이선스 키 받기
- 루트 사용자 비밀번호 설정
- 릴리스 롤아웃/유지 관리 일정 선택
- 인바운드 및 아웃바운드 IP/도메인 허용 목록 설정

## 권장사항 1 {#recommendation-1}

FedRAMP 권장사항: 권한 있는 계정에서만 운영할 수 있는 보안 관련 설정 및 보안 영향에 대한 설명을 제공하세요.

## 요구사항 2: 최상위 관리자 계정에 대한 보안 설정 {#requirement-2-security-settings-for-top-level-administrator-accounts}

최상위 관리자만 사용 가능한 보안 설정은 전체 인스턴스의 보안 상태에 직접적인 영향을 미칩니다.

FedRAMP 요구사항: 최상위 관리 계정에서만 운영할 수 있는 보안 관련 설정 및 보안 영향에 대한 설명을 제공하세요.

### 최상위 관리자를 위한 인프라 구성 {#infrastructure-configurations-for-top-level-administrators}

GitLab Dedicated for Government는 GitLab 지원 팀을 통해 요청할 수 있는 특정 인프라 수준의 보안 및 아키텍처 구성을 지원합니다.

이러한 구성에는 다음이 포함됩니다:

- 예를 들어 PrivateLink를 통한 테넌트 외부의 리소스와의 네트워크 연결
- 고객 관리 암호화: GitLab 테넌트가 고객 제공 암호화 키를 사용하도록 요청합니다. KMS 키 및 키 정책을 만들고 관리할 책임이 있습니다.
- 사용자 지정 도메인: 표준 Dedicated for Government 도메인이 아닌 고객 제공 도메인을 요청하세요. 도메인이 DNSSEC에 대한 모든 관련 명령을 충족하는지 확인할 책임이 있습니다.
- 참조 아키텍처 선택
- 총 리포지토리 용량
- 테넌트 이름
- 가용 영역
- 라이선스 키
- 루트 사용자 비밀번호
- 릴리스 롤아웃 및 유지 관리 일정
- 인바운드 및 아웃바운드 IP 및 도메인 허용 목록

### 공개 가시성 {#public-visibility}

기본적으로 GitLab은 인스턴스의 공개 가시성 수준을 제한합니다. 최상위 관리자는 관리 영역에서 인스턴스의 공개 가시성을 켠 다음 특정 그룹 또는 프로젝트의 가시성을 구성할 수 있습니다. 공개 가시성을 켜면 책임이 확대됩니다. 자세한 내용은 공동 책임 모델의 [공개 가시성 및 오픈 소스 코드 공유](dedicated_for_government_shared_responsibility_model.md#public-visibility-and-open-source-code-sharing)를 참조하세요.

## 권장사항 1: 권한 있는 계정에 대한 보안 설정 {#recommendation-1-security-settings-for-privileged-accounts}

최상위 관리자 아래의 권한 있는 계정은 인스턴스 및 해당 데이터의 보안에 크게 영향을 미칠 수 있는 설정에 액세스할 수 있습니다.

FedRAMP 권장사항: 권한 있는 계정에서만 운영할 수 있는 보안 관련 설정 및 보안 영향에 대한 설명을 제공하세요.

최상위 관리자와 ID 제공자를 통해 프로비저닝된 관리자 계정은 기능상 동등합니다. 초기 설정에만 최상위 계정을 사용하세요. 이후의 모든 보안 설정 및 구성을 위해 ID 제공자를 통해 프로비저닝된 관리자 계정을 사용하세요. 사용 가능한 모든 구성은 [GitLab 관리](../administration/_index.md)를 참조하세요.

### 시스템 개발 수명 주기 및 변경 관리 {#system-development-lifecycle-and-change-management}

관리자는 소프트웨어 개발 수명 주기(SDLC)를 보호하고 변경 관리 관행을 수립하기 위한 광범위한 도구 모음을 보유하고 있습니다. 자세한 내용은 [CI/CD로 코드 빌드 및 관리](../topics/build_your_application.md)를 참조하세요.

[파이프라인 보안](../ci/pipeline_security/_index.md) 문서를 검토하여 보안을 염두에 두고 CI/CD 파이프라인을 설계하는 방법을 이해하세요. [NIST 800-53 규정 준수 가이드](hardening_nist_800_53.md#configuration-management-cm)는 변경 제어 및 보안 분기를 설정하는 방법에 대한 자세한 정보를 제공합니다. 사용 가능한 변경 관리 구성을 검토하여 승인된 변경만 코드베이스에 적용되도록 하세요.

### 위험 평가 및 시스템 및 정보 무결성 {#risk-assessment-and-system-and-information-integrity}

코드를 보호하기 위한 도구를 설정할 책임이 있습니다. GitLab은 다음을 포함하여 애플리케이션 개발에 통합할 수 있는 [탐지 도구](../user/application_security/detect/_index.md) 모음을 포함합니다:

- [보안 구성](../user/application_security/detect/security_configuration.md)
- [컨테이너 스캔](../user/application_security/container_scanning/_index.md)
- [종속성 검사](../user/application_security/dependency_scanning/_index.md)
- [정적 애플리케이션 보안 테스팅(SAST)](../user/application_security/sast/_index.md)
- [IaC 스캔](../user/application_security/iac_scanning/_index.md)
- [시크릿 검색](../user/application_security/secret_detection/_index.md)
- [DAST](../user/application_security/dast/_index.md)
- [API 퍼징](../user/application_security/api_fuzzing/_index.md)
- [범위 기반 퍼징 테스트](../user/application_security/coverage_fuzzing/_index.md)

특정 CI 작업을 적용하여 병합되기 전에 모든 코드가 취약성에 대해 평가되도록 할 수 있습니다.

### 액세스 관리 {#access-management}

다음 역할은 표준 사용자 액세스 이상의 권한 있는 기능을 가집니다:

- Maintainer
- Owner

이러한 역할은 프로젝트 및 그룹에 사용자를 프로비저닝할 때 주의 깊게 검토해야 하는 [광범위한 권한 문서](../user/permissions.md)를 포함합니다.

#### 관리 영역의 액세스 관리 {#access-management-in-the-admin-area}

관리 영역에서 관리자는 [권한 내보내기](../administration/admin_area.md#user-permission-export), [사용자 ID 검토](../administration/admin_area.md#user-identities), [그룹 관리](../administration/admin_area.md#administering-groups) 등을 수행할 수 있습니다. FedRAMP 및 NIST 800-53 요구사항을 충족하는 데 유용한 기능은 다음과 같습니다:

- 손상이 의심될 때 [사용자 비밀번호 재설정](reset_user_password.md)합니다.
- [사용자 잠금 해제](unlock_user.md). 기본적으로 GitLab은 실패한 로그인 시도 10회 후 사용자를 잠급니다. 사용자는 10분 동안 또는 관리자가 잠금을 해제할 때까지 잠긴 상태로 유지됩니다. AC-7의 지침에 따라 FedRAMP는 계정 잠금에 대한 매개변수를 정의하기 위해 NIST 800-63B를 참조하며, 기본 설정이 이를 만족합니다.
- [남용 보고서](../administration/review_abuse_reports.md) 또는 [스팸 로그](../administration/review_spam_logs.md)를 검토합니다. FedRAMP는 조직에서 비정상적인 사용에 대해 계정을 모니터링하도록 요구합니다(AC-2(12)). 사용자는 남용 보고서에서 남용을 플래그할 수 있으며, 관리자는 조사 대기 중에 액세스를 제거할 수 있습니다. 스팸 로그는 관리 영역의 **스팸 로그** 섹션에 통합됩니다. 관리자는 해당 영역에서 플래그된 사용자를 제거, 차단 또는 신뢰할 수 있습니다.
- [자격 증명 인벤토리](../administration/credentials_inventory.md): 한 곳에서 GitLab 인스턴스에서 사용되는 모든 비밀을 검토합니다. 자격 증명, 토큰 및 키의 통합 보기는 비밀번호 검토 또는 자격 증명 회전과 같은 요구사항을 충족하는 데 도움이 될 수 있습니다.
- [기본 세션 기간](../administration/settings/account_and_limit_settings.md#customize-the-default-session-duration): FedRAMP는 비활성 사용자가 일정 시간 후에 로그아웃되도록 요구합니다. FedRAMP는 시간 기간을 지정하지 않지만 권한 있는 사용자는 표준 작업 기간이 끝날 때 로그아웃되어야 한다고 명시합니다.
- [새 사용자 프로비저닝](../user/profile/account/create_accounts.md): 관리 영역 UI를 통해 사용자를 만듭니다. IA-5 준수에 따라 GitLab은 새 사용자가 처음 로그인할 때 비밀번호를 변경하도록 요구합니다.
- 사용자 프로비저닝 해제: [관리 영역 UI를 통해 사용자 제거](../user/profile/account/delete_account.md#delete-users-and-user-contributions)합니다. 또는 [사용자 차단](../administration/moderate_users.md#block-a-user)하여 리포지토리의 데이터를 유지하면서 모든 액세스를 제거할 수 있습니다. 차단된 사용자는 사용자 수를 줄이지 않습니다.
- 사용자 비활성화: 계정 검토 중에 식별된 비활성 사용자는 [임시로 비활성화할 수 있습니다](../administration/moderate_users.md#deactivate-a-user). 차단과 달리 사용자를 비활성화하면 GitLab UI에 로그인하지 못하도록 하지 않습니다. 비활성화된 사용자는 로그인하여 다시 활성화할 수 있습니다. 비활성화된 사용자:
  - 리포지토리 또는 API에 액세스할 수 없습니다.
  - 슬래시 명령을 사용할 수 없습니다.
  - 사용자를 사용하지 않습니다.

### SSH 키 {#ssh-keys}

GitLab은 SSH 키를 구성하여 Git으로 인증하고 통신하는 방법에 대한 [지침을 제공](../user/ssh.md)합니다. [커밋을 서명](../user/project/repository/signed_commits/ssh.md)할 수 있으므로 공개 키를 가진 모든 사용자에게 추가 검증을 제공합니다. 관리자는 [최소 키 기술 및 키 길이를 설정](ssh_keys_restrictions.md)할 수 있습니다.

SSH 키가 FIPS 검증 암호화 모듈로 생성되도록 하는 것은 사용자의 책임입니다.

### 토큰 관리 {#token-management}

GitLab은 [개인 액세스 토큰](../user/profile/personal_access_tokens.md)을 구성하고 관리하는 방법에 대한 지침을 제공합니다. GitLab은 적용 가능한 사용 사례에 필요한 권한으로만 토큰 범위를 지정하는 데 사용할 수 있는 [세분화된 권한](../auth/tokens/fine_grained_access_tokens.md)을 지원합니다. 손상된 토큰의 영향을 제한하기 위해 사용자 및 서비스 계정 토큰에 필요한 최소 권한만 프로비저닝하세요.

### 감사 로깅 및 인시던트 관리 {#audit-logging-and-incident-management}

애플리케이션 로그를 사용할 책임이 있습니다. 테넌트의 S3 버킷에서 특정 로그에 액세스하려면 GitLab 지원팀에 문의하세요. 기본 인프라 로그는 Dedicated for Government 엔지니어가 관리하고 GitLab Security에서 모니터링합니다.

### 이메일 {#email}

GitLab은 [이메일 알림 전송](../administration/email_from_gitlab.md) 및 [애플리케이션 알림 이메일 구성](../user/profile/notifications.md)을 지원합니다. DHS Binding Operational Directive 18-01은 스팸 방지로 발신 메시지에 대해 Domain-based Message Authentication, Reporting and Conformance (DMARC)를 구성해야 합니다. GitLab Dedicated for Government는 기본적으로 이 구성을 제공합니다. 해당 기능이 필요하지 않으면 이메일 알림을 끌 수 있습니다.

### GitLab 러너 {#gitlab-runners}

Dedicated for Government 고객은 테넌트 외부에서 자신의 [자체 관리 러너](../ci/runners/_index.md)를 빌드하고 관리해야 합니다. 구성 지침은 [러너 구성](../ci/runners/configure_runners.md)을 참조하세요. FedRAMP 요구사항 준수를 보장하기 위해 제공된 FIPS 버전을 사용하여 러너를 빌드하세요.

러너는 FedRAMP 경계에 연결된 중요한 인프라의 확장입니다. 잘못 구성되거나 손상된 러너는 CI/CD 파이프라인 및 다운스트림 아티팩트에 공급 체인 위험을 초래할 수 있습니다. Dedicated 경계 외부의 격리되고 강화된 환경에 러너를 배포합니다. 러너 인증 토큰에 대한 액세스를 안전하게 관리하고 제로 트러스트 원칙을 따르며 정기적으로 회전합니다. 러너 활동에 대한 감사 로깅을 구성하고 모니터링합니다.

## 권장사항 2: 관리자 계정에 대한 보안 기본값 {#recommendation-2-secure-defaults-for-administrator-accounts}

계정이 처음 프로비저닝될 때 보안 기본값을 구성하면 구성 오류의 위험을 줄이고 처음부터 강력한 보안 기준을 설정합니다.

FedRAMP 권장사항: 초기에 프로비저닝될 때 최상위 관리 계정 및 권한 있는 계정에 대해 권장되는 보안 기본값으로 모든 설정을 설정하세요.

최상위 관리자 계정은 첫 번째 로그인에서 강력한 비밀번호를 구성할 수 있도록 프로비저닝됩니다. FedRAMP 요구사항에 따라 루트 사용자를 위해 [2단계 인증(2FA)을 등록](../user/profile/account/two_factor_authentication.md)해야 합니다. GitLab은 FIPS 규정을 준수하고 피싱에 강한 WebAuthn 장치를 포함한 광범위한 인수를 지원합니다.

제로 트러스트 보안 원칙에 맞추려면 다음을 수행해야 합니다:

- 루트 사용자뿐만 아니라 모든 권한 있는 계정에 2FA를 요구합니다.
- 관리 액세스를 부여하기 전에 장치 상태 및 사용자 컨텍스트를 확인하는 조건부 액세스 정책을 구현합니다.
- 세션 타임아웃을 적용하고 중요한 작업에 대해 재인증을 요구합니다.
- 모든 인증 메커니즘에 FIPS 검증 암호화 모듈을 사용합니다.
- 필요한 관리 권한만 부여되었는지 정기적으로 감사하고 검증합니다.

통합된 ID 제공자를 통해 프로비저닝된 추가 관리자는 다음과 같은 조직 제어를 충족해야 합니다:

- 비밀번호 길이 및 복잡성 적용
- 실패한 로그인 잠금
- PIV/CAC 인증
- 조직에서 관리하는 2단계 인증
- 비활성 사용자 잠금

## 추가 리소스 {#additional-resources}

GitLab은 관리자의 보안을 강화하는 결정을 안내하기 위해 [CIS Benchmark](https://about.gitlab.com/blog/gitlab-introduces-new-cis-benchmark-for-improved-security/)를 게시했습니다. 이를 시작점으로 사용하여 인스턴스 내에서 안전한 프로젝트 및 애플리케이션 리소스를 빌드하세요.
