---
stage: GitLab Dedicated
group: US Public Sector Services
info: All material changes to this page must be approved by the [FedRAMP Compliance team](https://handbook.gitlab.com/handbook/security/security-assurance/security-compliance/fedramp-compliance/#gitlabs-fedramp-initiative). To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments.
title: NIST 800-53 준수
---

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

본 페이지는 NIST 800-53 제어 사항을 충족하기 위해 GitLab Self-Managed 인스턴스를 구성하려는 GitLab 관리자를 위한 참고 자료입니다. 관리자가 가질 수 있는 다양한 요구 사항으로 인해 GitLab은 특정 구성 지침을 제공하지 않습니다. NIST 800-53 보안 제어 사항을 충족하는 GitLab 인스턴스를 배포하기 전에 기술 세부 사항을 위해 고객 솔루션 아키텍트와 함께 작업해야 합니다.

## 범위 {#scope}

본 페이지는 NIST 800-53 제어 집합의 구조를 따릅니다. 페이지의 범위가 주로 GitLab 자체에 대한 구성으로 제한되어 있으므로 모든 제어 집합이 적용되는 것은 아닙니다. 구성 세부 사항은 플랫폼 독립적이어야 합니다.

GitLab 지침은 완전히 준수하는 시스템을 구성하지 않습니다. 정부 데이터를 처리하기 전에 다음을 수행해야 합니다:

- 전체 기술 스택의 추가 구성 및 강화를 계획합니다.
- 보안 구성에 대한 독립적인 평가를 고려합니다.
- [지원되는 클라우드 공급자](../install/cloud_providers.md)에서 배포의 차이를 이해하고 사용 가능한 경우 특정 지침을 따릅니다.

## 준수 기능 {#compliance-features}

GitLab은 GitLab의 중요한 제어 사항 및 워크플로를 자동화하는 데 사용할 수 있는 여러 [준수 기능](../administration/compliance/compliance_features.md)을 제공합니다. NIST 800-53에 맞춰 구성을 만들기 전에 이러한 기본 기능을 활성화해야 합니다.

## 제어 집합별 구성 {#configuration-by-control-family}

### 시스템 및 서비스 수집(SA) {#system-and-service-acquisition-sa}

GitLab은 [DevSecOps 플랫폼](../devsecops.md)으로 개발 수명 주기 전체에 보안을 통합합니다. 근본적으로 GitLab을 사용하여 SA 제어 집합의 광범위한 제어 사항을 다룰 수 있습니다.

#### 시스템 개발 수명 주기 {#system-development-lifecycle}

GitLab을 사용하여 이 요구 사항의 핵심을 충족할 수 있습니다. GitLab은 작업을 [구성](../user/project/organize_work_with_projects.md)하고 [계획하고 추적](../topics/plan_and_track.md)할 수 있는 플랫폼을 제공합니다. NIST 800-53은 보안이 애플리케이션 개발에 통합되도록 요구합니다. [CI/CD 파이프라인](../topics/build_your_application.md)을 구성하여 코드를 지속적으로 테스트하면서 동시에 보안 정책을 강화할 수 있습니다. GitLab에는 고객 애플리케이션 개발에 통합할 수 있는 보안 도구 모음이 포함되어 있으며 다음을 포함하되 이에 국한되지 않습니다:

- [보안 구성](../user/application_security/detect/security_configuration.md)
- [컨테이너 스캔](../user/application_security/container_scanning/_index.md)
- [종속성 검사](../user/application_security/dependency_scanning/_index.md)
- [정적 애플리케이션 보안 테스트](../user/application_security/sast/_index.md)
- [코드 기반 인프라(IaC) 검사](../user/application_security/iac_scanning/_index.md)
- [시크릿 검색](../user/application_security/secret_detection/_index.md)
- [DAST](../user/application_security/dast/_index.md)
- [API 퍼징](../user/application_security/api_fuzzing/_index.md)
- [범위 기반 퍼징 테스트](../user/application_security/coverage_fuzzing/_index.md)

CI/CD 파이프라인 외에도 GitLab은 [릴리스 구성 방법에 대한 자세한 지침](../user/project/releases/_index.md)을 제공합니다. 릴리스는 CI/CD 파이프라인으로 생성될 수 있으며 리포지토리의 소스 코드의 모든 브랜치의 스냅샷을 생성합니다. 릴리스 생성 지침은 [릴리스 생성](../user/project/releases/_index.md#create-a-release)에 포함되어 있습니다. NIST 800-53 또는 FedRAMP 준수에 대한 중요한 고려 사항은 릴리스된 코드가 서명되어야 하고 코드의 진정성을 확인하며 시스템 및 정보 무결성(SI) 제어 집합의 요구 사항을 충족해야 한다는 것입니다.

### 접근 제어(AC) 및 식별 및 인증(IA) {#access-control-ac-and-identification-and-authentication-ia}

GitLab 배포에서 접근 관리는 각 고객마다 고유합니다. GitLab은 ID 공급자 및 GitLab 기본 인증 구성과의 배포를 다루는 광범위한 설명서를 제공합니다. GitLab 인스턴스에 대한 인증 방법을 결정하기 전에 조직 요구 사항을 고려하는 것이 중요합니다.

#### ID 공급자 {#identity-providers}

GitLab의 접근 관리는 UI를 통해 또는 기존 ID 공급자와 통합하여 관리할 수 있습니다. FedRAMP 요구 사항을 충족하려면 기존 ID 공급자가 [FedRAMP 마켓플레이스](https://marketplace.fedramp.gov/products)에서 FedRAMP 승인되었는지 확인합니다. PIV와 같은 요구 사항을 충족하려면 GitLab Self-Managed에서 기본 인증을 사용하는 대신 ID 공급자를 사용해야 합니다.

GitLab은 다양한 ID 공급자 및 프로토콜 구성을 위한 리소스를 제공합니다.

- [LDAP](../administration/auth/ldap/_index.md)

- [SAML](../integration/saml.md)

- ID 공급자에 대한 자세한 내용은 [GitLab 인증 및 권한 부여](../administration/auth/_index.md)를 참조합니다.

#### GitLab 기본 사용자 인증 구성 {#native-gitlab-user-authentication-configurations}

**Account management and classification** \- GitLab을 사용하면 관리자가 민감도 및 접근 요구 사항이 다양한 사용자를 추적할 수 있습니다. GitLab은 세분화된 접근을 위한 옵션을 제공하여 최소 권한의 개념과 역할 기반 접근을 지원합니다. 프로젝트 수준에서 다음 역할이 지원됩니다.

- Guest

- Reporter

- Developer

- Maintainer

- Owner

[프로젝트 수준 권한](../user/permissions.md#project-permissions)에 대한 추가 세부 사항은 설명서에서 찾을 수 있습니다. GitLab은 또한 고유한 권한 요구 사항이 있는 고객을 위해 [사용자 지정 역할](../user/custom_roles/_index.md)을 지원합니다.

GitLab은 고유한 사용 사례를 위해 다음 사용자 유형을 지원합니다:

- [감사자 사용자](../administration/auditor_users.md) \- 감사자 역할은 **운영자** 영역 및 프로젝트/그룹 설정을 제외한 모든 그룹, 프로젝트 및 기타 리소스에 대한 읽기 전용 접근을 제공합니다. 감사자 역할을 사용하여 특정 프로젝트에 대한 접근 권한이 필요한 타사 감사자와 협력할 때 사용할 수 있습니다.

- [외부 사용자](../administration/external_users.md) \- 외부 사용자를 설정하여 조직의 일부가 아닐 수 있는 사용자에게 제한된 접근을 제공할 수 있습니다. 일반적으로 이를 사용하여 계약자 또는 기타 타사에 대한 접근 관리를 충족할 수 있습니다. IA-4(4)와 같은 제어는 조직 외 사용자를 식별하고 회사 정책에 따라 관리해야 합니다. 외부 사용자를 설정하면 기본적으로 프로젝트에 대한 접근을 제한하고 관리자가 조직에 고용되지 않은 사용자를 식별하는 데 도움을 주어 조직의 위험을 줄일 수 있습니다.

- [서비스 계정](../user/profile/service_accounts.md) \- 자동화된 작업을 수용하기 위해 서비스 계정을 추가할 수 있습니다. 서비스 계정은 라이선스에서 사용자를 사용하지 않습니다.

**운영자** 영역 - **운영자** 영역에서 관리자는 [권한 내보내기](../administration/admin_area.md#user-permission-export), [사용자 ID 검토](../administration/admin_area.md#user-identities), [그룹 관리](../administration/admin_area.md#administering-groups) 등을 수행할 수 있습니다. FedRAMP / NIST 800-53 요구 사항을 충족하는 데 사용할 수 있는 기능:

- 손상이 의심될 때 [사용자 비밀번호 재설정](reset_user_password.md)합니다.

- [사용자 잠금 해제](unlock_user.md). 기본적으로 GitLab은 실패한 로그인 시도 10회 후 사용자를 잠급니다. 사용자는 10분 동안 또는 관리자가 사용자의 잠금을 해제할 때까지 잠긴 상태로 유지됩니다. GitLab 16.5 이상에서는 관리자가 [API를 사용](../api/settings.md#available-settings)하여 최대 로그인 시도 및 잠금 상태로 남아 있는 시간을 구성할 수 있습니다. AC-7의 지침에 따라 FedRAMP는 계정 잠금에 대한 매개변수를 정의하기 위해 NIST 800-63B를 참조하며, 기본 설정이 이를 만족합니다.

- [남용 보고서](../administration/review_abuse_reports.md) 또는 [스팸 로그](../administration/review_spam_logs.md)를 검토합니다. FedRAMP는 조직에서 비정상적인 사용에 대해 계정을 모니터링하도록 요구합니다(AC-2(12)). GitLab을 사용하면 사용자가 남용 보고서에서 남용을 표시할 수 있으며, 관리자는 조사 중에 접근을 제거할 수 있습니다. 스팸 로그는 **스팸 로그** 섹션 **운영자** 영역에 통합됩니다. 관리자는 해당 영역에서 플래그된 사용자를 제거, 차단 또는 신뢰할 수 있습니다.

- [암호 저장소 매개 변수 설정](../user/profile/user_passwords.md)합니다. 저장된 암호는 SC-13에 설명된 대로 FIPS 140-2 또는 140-3을 충족해야 합니다. PBKDF2+SHA512는 FIPS 모드가 활성화되었을 때 FIPS 호환 암호를 사용하여 지원됩니다.

- [자격 증명 인벤토리](../administration/credentials_inventory.md)를 통해 관리자는 GitLab Self-Managed 인스턴스에서 사용하는 모든 암호를 한 곳에서 검토할 수 있습니다. 자격 증명, 토큰 및 키의 통합 보기는 암호를 검토하거나 자격 증명을 회전하는 것과 같은 요구 사항을 충족하는 데 도움이 될 수 있습니다.

- [암호 복잡도 요구 사항 수정](../administration/settings/sign_up_restrictions.md#modify-password-complexity-requirements). FedRAMP는 IA-5에서 NIST 800-63B를 따르면서 암호 길이 요구 사항을 설정합니다. GitLab은 8-128자 암호를 지원하며 기본값은 8자입니다.

- [기본 세션 기간](../administration/settings/account_and_limit_settings.md#customize-the-default-session-duration) \- FedRAMP는 일정 시간 동안 비활성 상태인 사용자를 로그아웃해야 한다고 규정합니다. FedRAMP는 시간 기간을 지정하지 않지만 권한 있는 사용자의 경우 표준 작업 기간이 끝날 때 로그아웃해야 한다는 것을 명시합니다. 관리자는 [기본 세션 기간](../administration/settings/account_and_limit_settings.md#customize-the-default-session-duration)을 설정할 수 있습니다.

- [새로운 사용자 프로비저닝](../user/profile/account/create_accounts.md) \- 관리자는 **운영자** 영역 UI를 사용하여 GitLab 계정에 대한 새로운 사용자를 생성할 수 있습니다. IA-5 준수에 따라 GitLab은 새 사용자가 처음 로그인할 때 비밀번호를 변경하도록 요구합니다.

- 사용자 프로비저닝 해제 - 관리자는 [**운영자** 영역 UI에서 사용자를 제거](../user/profile/account/delete_account.md#delete-users-and-user-contributions)할 수 있습니다. 사용자를 삭제하는 대신 [사용자를 차단](../administration/moderate_users.md#block-a-user)하고 모든 접근을 제거할 수 있습니다. 사용자를 차단하면 리포지토리의 데이터를 유지하면서 모든 접근을 제거합니다. 차단된 사용자는 사용자 수에 영향을 주지 않습니다.

- 사용자 비활성화 - 계정 검토 중에 식별된 비활성 사용자는 [일시적으로 비활성화될 수 있습니다](../administration/moderate_users.md#deactivate-a-user). 비활성화는 차단과 유사하지만 몇 가지 중요한 차이가 있습니다. 사용자를 비활성화하면 사용자가 GitLab UI에 로그인하지 못하도록 하지 않습니다. 비활성화된 사용자는 로그인하여 다시 활성화할 수 있습니다. 비활성화된 사용자:
  - 리포지토리 또는 API에 액세스할 수 없습니다.

  - 슬래시 명령을 사용할 수 없습니다. 자세한 내용은 슬래시 명령을 참조합니다.

  - 사용자를 사용하지 않습니다.

#### 추가 식별 방법 {#additional-identification-methods}

**이중 인증** - [GitLab에서 다음 두 번째 요소를 지원합니다](../user/profile/account/two_factor_authentication.md):

- 일회용 암호 인증기

- WebAuthn 장치

[2단계 인증 활성화 지침](../user/profile/account/two_factor_authentication.md#enable-two-factor-authentication)이 설명서에 제공됩니다. FedRAMP를 추구하는 고객은 FedRAMP 승인되고 FIPS 요구 사항을 지원하는 2단계 공급자를 고려해야 합니다. FedRAMP 승인 공급자는 [FedRAMP 마켓플레이스](https://marketplace.fedramp.gov/products)에서 찾을 수 있습니다. 두 번째 요소를 선택할 때 NIST 및 FedRAMP는 WebAuthn과 같은 피싱 방지 인증을 사용해야 한다고 지시합니다(IA-2).

**SSH 키**

- GitLab은 SSH 키를 구성하여 Git으로 인증하고 통신하는 방법에 대한 [지침을 제공](../user/ssh.md)합니다. [커밋을 서명](../user/project/repository/signed_commits/ssh.md)할 수 있으므로 공개 키를 가진 모든 사용자에게 추가 검증을 제공합니다.

- 키는 FIPS 140-2 및 FIPS 140-3 검증된 암호 사용과 같은 적용 가능한 강도 및 복잡성 요구 사항을 충족하도록 구성해야 합니다. 관리자는 [최소 키 기술 및 키 길이를 제한](ssh_keys_restrictions.md)할 수 있습니다. 또한 GitLab은 [손상된 키를 차단](../user/ssh.md#add-an-ssh-key-to-your-gitlab-account)합니다.

**개인 액세스 토큰**

GitLab은 [개인 액세스 토큰](../user/profile/personal_access_tokens.md)을 구성하고 관리하는 방법에 대한 지침을 제공합니다. GitLab은 적용 가능한 사용 사례에 필요한 권한으로만 토큰 범위를 지정하는 데 사용할 수 있는 [세분화된 권한](../auth/tokens/fine_grained_access_tokens.md)을 지원합니다.

#### 기타 접근 제어 집합 개념 {#other-access-control-family-concepts}

**System Use Notifications**

연방 요구 사항은 종종 로그인 시 배너의 필요성을 설명합니다. 이를 ID 공급자 및 [GitLab 배너 기능](../administration/broadcast_messages.md)을 통해 구성할 수 있습니다.

**External Connections**

모든 외부 연결을 문서화하고 준수 요구 사항을 충족하는지 확인하는 것이 중요합니다. 예를 들어 타사와 API 통합을 설정하면 해당 타사가 고객 데이터를 보호하는 방식에 따라 데이터 처리 요구 사항을 위반할 수 있습니다. 모든 외부 연결을 검토하고 활성화하기 전에 보안 영향을 이해하는 것이 중요합니다. FedRAMP 또는 유사한 인증을 추구하는 고객의 경우 다른 비FedRAMP 승인 서비스 또는 더 낮은 데이터 영향 수준의 서비스에 연결하면 권한 부여 경계를 위반할 수 있습니다.

**Personal Identity Verification (PIV)**

개인 신원 확인 카드는 연방 요구 사항을 충족하는 조직의 요구 사항일 수 있습니다. PIV 요구 사항을 충족하기 위해 GitLab은 고객이 PIV 지원 ID 솔루션을 SAML과 연결해야 합니다. SAML 설명서에 대한 링크는 본 가이드의 앞부분에 제공됩니다.

### 감사 및 책임(AU) {#audit-and-accountability-au}

NIST 800-53은 조직이 보안 관련 이벤트를 모니터링하고, 이러한 이벤트를 분석하고, 경고를 생성하고, 경고의 중요도에 따라 경고를 조사하도록 요구합니다. GitLab은 보안 정보 및 이벤트 관리(SIEM) 솔루션으로 라우팅할 수 있는 광범위한 보안 이벤트를 제공합니다.

#### 이벤트 유형 {#event-types}

GitLab은 [구성 가능한 감사 이벤트 로그 유형](../administration/compliance/audit_event_streaming.md)을 설명하며, 이는 스트림되고/또는 데이터베이스에 저장될 수 있습니다. 관리자는 GitLab 인스턴스에 대해 캡처하려는 이벤트를 구성할 수 있습니다.

**Log System**

GitLab에는 모든 것을 기록할 수 있는 고급 로그 시스템이 포함되어 있습니다. GitLab은 [로그 시스템 로그 유형에 대한 지침](../administration/logs/_index.md#importerlog)을 제공하며, 이는 다양한 출력을 포함합니다. 추가 세부 사항은 연결된 지침을 검토합니다.

스트리밍 이벤트

GitLab 관리자는 [이벤트 스트리밍 기능](../user/compliance/audit_event_streaming.md)을 사용하여 SIEM 또는 기타 저장소 위치로 감사 이벤트를 스트림할 수 있습니다. 관리자는 여러 대상을 구성하고 이벤트 헤더를 설정할 수 있습니다. GitLab은 [이벤트 스트리밍에 대한 예제를 제공](../user/compliance/audit_event_schema.md)하며, 이는 헤더, HTTP 및 HTTPS 이벤트의 페이로드 등을 설명합니다.

관리자가 FedRAMP 또는 NIST 800-53 AU-2 요구 사항을 검토하고 필요한 감사 이벤트 유형에 매핑되는 감사 이벤트를 구현하는 것이 중요합니다. AU-2는 다음과 같은 이벤트 버킷을 식별합니다:

- 성공 및 실패한 계정 로그온 이벤트

- 계정 관리 이벤트

- 개체 접근

- 정책 변경

- 권한 기능

- 프로세스 추적

- 시스템 이벤트

- 웹 애플리케이션:

  - 모든 관리자 활동

  - 인증 확인

  - 권한 부여 확인

  - 데이터 삭제

  - 데이터 접근

  - 데이터 변경

  - 권한 변경

관리자는 GitLab에서 이벤트를 활성화할 때 필요한 이벤트 유형과 추가 조직 요구 사항을 모두 고려해야 합니다.

**측정항목**

보안 이벤트 외에도 관리자는 가동 시간을 지원하기 위해 애플리케이션의 성능을 보려고 할 수 있습니다. GitLab은 [GitLab 인스턴스에서 지원되는 측정항목에 대한 강력한 설명서 모음](../administration/monitoring/_index.md)을 제공합니다.

**스토리지**

고객은 로그가 준수 요구 사항을 충족하는 장기 저장소 솔루션에 저장되도록 해야 합니다. 예를 들어 FedRAMP는 로그를 1년 동안 저장하도록 요구합니다. 고객 조직은 수집된 데이터의 영향에 따라 국립 기록 관리청 요구 사항을 충족해야 할 수도 있습니다. 수집된 기록의 영향을 검토하고 적용 가능한 준수 요구 사항을 이해하는 것이 중요합니다.

### 사건 대응(IR) {#incident-response-ir}

감사 이벤트를 구성한 후에는 이러한 이벤트를 모니터링해야 합니다. GitLab은 SIEM 또는 기타 보안 도구에서 시스템 경고를 컴파일하고, 경고 및 사건을 분류하고, 이해 관계자에게 알리기 위한 중앙 집중식 관리 인터페이스를 제공합니다. [사건 관리 설명서](../operations/incident_management/_index.md)는 GitLab을 사용하여 보안 사건 대응 조직에서 앞서 언급한 활동을 실행하는 방법을 설명합니다.

**Incident Response Lifecycle**

GitLab은 조직의 전체 사건 대응 수명 주기를 관리할 수 있습니다. 사건 대응 요구 사항을 충족하는 데 도움이 될 수 있는 다음 리소스를 검토합니다:

- [경고](../operations/incident_management/alerts.md)

- [사건](../operations/incident_management/incidents.md)

- [온콜 일정](../operations/incident_management/oncall_schedules.md)

- [상태 페이지](../operations/incident_management/status_page.md)

### 구성 관리(CM) {#configuration-management-cm}

**Change Control**

근본적으로 GitLab은 변경 제어와 관련된 구성 관리 요구 사항을 충족할 수 있습니다. 이슈 및 머지 리퀘스트는 변경 사항을 지원하는 주요 방법입니다.

이슈는 변경 사항을 구현하기 전에 메타데이터 및 승인을 캡처하는 유연한 플랫폼입니다. [작업 계획 및 추적](../topics/plan_and_track.md)에 대한 GitLab 설명서를 검토하여 GitLab 기능을 사용하여 구성 관리 제어 사항을 충족하는 방법을 완전히 이해합니다.

머지 리퀘스트는 소스 브랜치에서 대상 브랜치로 변경 사항을 표준화하는 방법을 제공합니다. NIST 800-53의 맥락에서 코드를 병합하기 전에 승인을 수집하는 방법과 조직 내에서 코드를 병합할 수 있는 사람을 고려하는 것이 중요합니다. GitLab은 [머지 리퀘스트의 승인에 사용 가능한 다양한 설정](../user/project/merge_requests/approvals/_index.md)에 대한 지침을 제공합니다. 필요한 검토를 완료한 후 승인 및 병합 권한만 적절한 역할에 할당하는 것을 고려합니다. 고려할 추가 병합 설정:

- 커밋이 추가될 때 모든 승인 제거 - 머지 리퀘스트에 새로운 커밋이 만들어질 때 승인이 이월되지 않도록 합니다.

- 코드 변경 검토를 해제할 수 있는 개인을 제한합니다.

- [코드 소유자](../user/project/codeowners/_index.md#codeowners-file)를 할당하여 머지 리퀘스트를 통해 민감한 코드 또는 구성이 변경될 때 알림을 받습니다.

- [코드 변경 병합을 허용하기 전에 모든 열린 댓글이 해결되었는지 확인](../user/project/merge_requests/_index.md#prevent-merge-unless-all-threads-are-resolved)합니다.

- [푸시 규칙 구성](../user/project/repository/push_rules.md) \- 푸시 규칙을 구성하여 서명된 코드 검토, 사용자 확인 등과 같은 요구 사항을 충족할 수 있습니다.

**Testing and Validation of Changes**

[CI/CD 파이프라인](../topics/build_your_application.md)은 변경 사항을 테스트하고 검증하는 중요한 구성 요소입니다. 특정 사용 사례에 대해 충분한 테스트 및 검증 파이프라인을 구현하는 것은 고객의 책임입니다. 서비스를 선택할 때 해당 파이프라인이 실행되는 위치를 고려합니다. 외부 서비스에 연결하면 정부 데이터가 저장되고 처리될 수 있는 설정된 권한 부여 경계를 위반할 수 있습니다. GitLab은 FIPS 지원 시스템에서 실행되도록 구성된 러너 컨테이너 이미지를 제공합니다. GitLab은 [보호된 브랜치를 구성](../user/project/repository/branches/protected.md)하는 방법 및 [파이프라인 보안을 구현](../ci/pipelines/_index.md#pipeline-security-on-protected-branches)하는 방법을 포함하여 파이프라인에 대한 강화 지침을 제공합니다. 또한 고객은 [필수 확인](../user/project/merge_requests/status_checks.md)을 할당하여 코드를 병합하기 전에 모든 확인이 통과했는지 확인하는 것을 고려할 수 있습니다.

**Component Inventory**

NIST 800-53은 클라우드 서비스 공급자가 구성 요소 인벤토리를 유지하도록 요구합니다. GitLab은 기본 하드웨어를 직접 추적할 수 없지만 컨테이너 및 종속성 검사를 통해 소프트웨어 인벤토리를 생성할 수 있습니다. GitLab은 [컨테이너 검사 및 종속성 검사가 감지할 수 있는 종속성](../user/application_security/comparison_dependency_and_container_scanning.md)을 설명합니다. GitLab은 [소프트웨어 구성 요소 인벤토리](../user/application_security/dependency_list/_index.md)에서 사용할 수 있는 종속성 목록 생성에 대한 추가 설명서를 제공합니다. Software Bill of Materials 지원은 공급망 위험 관리 아래 이 문서의 추가 아래에서 다룹니다.

**Container Registry**

GitLab은 고도로 가상화되고 확장 가능한 환경에서 컨테이너를 배포하기 위한 권한 있는 리포지토리로 사용할 수 있는 GitLab 프로젝트의 컨테이너 이미지를 저장하는 통합 컨테이너 레지스트리를 제공합니다. [컨테이너 레지스트리 관리 지침](../administration/packages/container_registry.md)을 검토할 수 있습니다.

### 우발 계획(CP) {#contingency-planning-cp}

GitLab은 핵심 우발 계획 요구 사항을 충족하는 데 도움이 될 수 있는 지침 및 서비스를 제공합니다. 포함된 설명서를 검토하고 우발 계획 활동에 대한 조직 요구 사항을 충족하도록 계획하는 것이 중요합니다. 우발 계획은 각 조직에 고유하므로 우발 계획을 수립하기 전에 조직 요구 사항을 고려하는 것이 중요합니다.

**Selecting a GitLab Architecture**

GitLab은 GitLab Self-Managed 인스턴스에서 지원되는 아키텍처에 대한 광범위한 설명서를 제공합니다. GitLab은 다음과 같은 클라우드 서비스 공급자를 지원합니다:

- [Azure](../install/azure/_index.md)

- [Google Cloud Platform](../install/google_cloud_platform/_index.md)

- [Amazon Web Services](../install/aws/_index.md)

GitLab은 [고객이 참고 아키텍처 및 가용성 모델을 선택하도록 지원하기 위한 결정 트리](../administration/reference_architectures/_index.md#decision-tree)를 제공합니다. 대부분의 클라우드 서비스 공급자는 관리되는 서비스에 대해 지역 내에서 복원력을 제공합니다. 아키텍처를 선택할 때는 조직의 다운타임 허용 범위와 데이터의 중요성을 고려하는 것이 중요합니다. GitLab Geo는 추가 복제 및 장애 조치 기능을 고려할 수 있습니다.

**Identify Critical Assets**

NIST 800-53은 가동 중단 시 우선순위 복원을 보장하기 위해 중요 자산을 식별하도록 요구합니다. 고려할 중요 자산에는 Gitaly 노드 및 PostgreSQL 데이터베이스가 포함됩니다. 고객은 필요에 따라 백업 또는 복제가 필요한 추가 자산을 식별해야 합니다.

**Backups**

설명서는 중요한 구성 요소에 대한 백업 전략을 설명합니다:

- [PostgreSQL 데이터베이스](../administration/backup_restore/backup_gitlab.md#postgresql-databases)

- [Git 리포지토리](../administration/backup_restore/backup_gitlab.md#git-repositories)

- [Blob](../administration/backup_restore/backup_gitlab.md#blobs)

- [Container Registry](../administration/backup_restore/backup_gitlab.md#container-registry)

- [Redis](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/#backing-up-redis-data)

- [구성 파일](../administration/backup_restore/backup_gitlab.md#storing-configuration-files)

- [Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshot-restore.html)

GitLab Geo

GitLab Geo는 NIST 800-53 준수를 추구하는 모든 구현의 중요한 구성 요소일 가능성이 높습니다. [사용 가능한 설명서](../administration/geo/_index.md)를 검토하여 Geo가 각 사용 사례에 맞게 적절히 구성되도록 하는 것이 중요합니다.

Geo를 구현하면 다음과 같은 이점을 제공합니다:

- 분산된 개발자가 대규모 리포지토리 및 프로젝트를 복제하고 페치하는 데 걸리는 시간을 분 단위에서 초 단위로 줄입니다.

- 개발자가 아이디어를 제공하고 여러 지역에서 병렬로 작업할 수 있게 합니다.

- 기본 및 보조 사이트 간의 읽기 전용 로드 균형을 맞춥니다.

- GitLab 웹 인터페이스에서 사용 가능한 데이터를 읽을 수 있을 뿐만 아니라 프로젝트를 복제하고 페치하는 데 사용할 수 있습니다(제한 사항 참조).

- 먼 오피스 간의 느린 연결을 극복하여 분산된 팀의 속도를 개선함으로써 시간을 절약합니다.

- 자동화된 작업, 사용자 지정 통합 및 내부 워크플로의 로드 시간을 줄이는 데 도움이 됩니다.

- 재해 복구 시나리오에서 보조 사이트로 빠르게 장애 조치할 수 있습니다.

- 보조 사이트로의 계획된 장애 조치를 허용합니다.

Geo는 다음과 같은 핵심 기능을 제공합니다:

- 읽기 전용 보조 사이트: 하나의 기본 GitLab 사이트를 유지하면서 분산된 팀을 위한 읽기 전용 보조 사이트를 활성화합니다.

- 인증 시스템 후크: 보조 사이트는 기본 인스턴스에서 모든 인증 데이터(사용자 계정 및 로그인 등)를 수신합니다.

- 직관적인 UI: 보조 사이트는 기본 사이트와 동일한 웹 인터페이스를 사용합니다. 또한 쓰기 작업을 차단하고 사용자가 보조 사이트에 있음을 명확히 하는 시각적 알림이 있습니다.

추가 Geo 리소스:

- [Geo 설정](../administration/geo/setup/_index.md)

- [Geo 실행 요구 사항](../administration/geo/_index.md#requirements-for-running-geo)

- [Geo 제한 사항](../administration/geo/_index.md)

- [Geo 재해 복구 단계](../administration/geo/disaster_recovery/_index.md)

**PostgreSQL**

GitLab은 [복제 및 장애 조치를 사용하여 PostgreSQL 클러스터를 구성하는 방법에 대한 지침](../administration/postgresql/replication_and_failover.md)을 제공합니다. 데이터의 중요도와 GitLab 인스턴스의 최대 허용 가동 중단 시간에 따라 복제 및 장애 조치를 활성화하도록 PostgreSQL을 구성하는 것을 고려합니다.

**Gitaly**

Gitaly를 구성할 때 가용성, 복구 가능성 및 복원력 간의 장단점을 고려합니다. GitLab은 [Gitaly 기능](../administration/gitaly/gitaly_geo_capabilities.md)에 대한 광범위한 설명서를 제공하며, 이는 NIST 800-53 요구 사항을 충족하기 위한 올바른 구성을 결정하는 데 도움이 됩니다.

### 계획(PL) {#planning-pl}

계획 제어 집합에는 정책, 절차 및 기타 제어된 문서의 유지 관리가 포함됩니다. GitLab을 활용하여 제어된 문서의 수명 주기를 관리하는 것을 고려합니다. 예를 들어 제어된 문서를 [마크다운](../user/markdown.md)으로 버전 제어 상태로 저장할 수 있습니다. 문서에 대한 모든 변경 사항은 조직의 승인 규칙을 적용하는 머지 리퀘스트를 통해 이루어져야 합니다. 머지 리퀘스트는 제어된 문서에 대한 변경 사항의 명확한 기록을 제공하며, 이를 감사 중에 사용하여 문서 소유자와 같은 적절한 담당자의 연간 검토 및 승인을 입증할 수 있습니다.

### 위험 평가 및 시스템 및 정보 무결성(RA) {#risk-assessment-and-system-and-information-integrity-ra}

#### 검사 {#scanning}

NIST 800-53은 취약성 및 결함 수정에 대한 지속적인 모니터링을 요구합니다. 인프라 검사 외에도 FedRAMP와 같은 준수 프레임워크는 컨테이너 및 DAST 검사를 월간 보고 요구 사항에 포함했습니다. GitLab은 [컨테이너 검사를 지원할 수 있는 보안 도구](../user/application_security/container_scanning/_index.md)를 제공하며 [Trivy](https://github.com/aquasecurity/trivy) 및 [Grype](https://github.com/anchore/grype) 검사기를 포함합니다. 또한 GitLab은 [종속성 검사 기능](../user/application_security/dependency_scanning/_index.md)을 제공합니다. GitLab의 DAST는 웹 애플리케이션 검사 요구 사항을 충족하는 데 사용할 수 있습니다. [GitLab DAST](../user/application_security/dast/_index.md)를 구성하여 파이프라인에서 실행하고 실행 중인 웹 애플리케이션에 대한 취약성 보고서를 생성할 수 있습니다.

애플리케이션 코드를 보호하고 관리하는 데 사용할 수 있는 추가 보안 기능은 다음을 포함합니다:

- [정적 애플리케이션 보안 테스팅(SAST)](../user/application_security/sast/_index.md)

- [시크릿 검색](../user/application_security/secret_detection/_index.md)

- [API 보안](../user/application_security/api_security/_index.md)

#### 패치 관리 {#patch-management}

GitLab은 설명서에서 [릴리스 및 유지 관리 정책](../policy/maintenance.md)을 문서화합니다. GitLab 인스턴스를 업그레이드하기 전에 [업그레이드 계획](../update/plan_your_upgrade.md), [가동 중단 없이 업그레이드](../update/zero_downtime.md) 및 기타 [업그레이드 경로](../update/upgrade_paths.md)를 지원할 수 있는 사용 가능한 지침을 검토합니다.

[보안 대시보드](../user/application_security/security_dashboard/_index.md)를 구성하여 시간이 지남에 따라 취약성 데이터를 추적할 수 있으며, 이를 사용하여 취약성 관리 프로그램의 추세를 식별할 수 있습니다.

### 공급망 위험 관리(SR) {#supply-chain-risk-management-sr}

#### Software Bill of Materials {#software-bill-of-materials}

GitLab 종속성 및 컨테이너 검사기는 SBOM 생성을 지원합니다. 컨테이너 및 종속성 검사에서 SBOM 보고서를 활성화하면 고객 조직이 소프트웨어 공급망과 소프트웨어 구성 요소와 관련된 위험을 이해할 수 있습니다. GitLab 검사기는 [CycloneDX 형식 보고서를 지원](../ci/yaml/artifacts_reports.md#artifactsreportsdotenv)합니다.

### 시스템 및 통신 보호(SC) {#system-and-communication-protection-sc}

#### FIPS 준수 {#fips-compliance}

NIST 800-53을 기반으로 하는 준수 프로그램(예: FedRAMP)은 모든 적용 가능한 암호화 모듈에 대해 FIPS 준수를 요구합니다. GitLab은 컨테이너 이미지의 FIPS 버전을 릴리스했으며 GitLab을 구성하여 FIPS 준수 표준을 충족하는 방법에 대한 지침을 제공합니다. 특정 기능은 FIPS 모드에서 사용하거나 지원되지 않습니다.

GitLab이 FIPS 호환 이미지를 제공하지만 기본 인프라를 구성하고 환경을 평가하여 FIPS 검증된 암호를 적용하는 것은 고객의 책임입니다.

### 시스템 및 정보 무결성(SI) {#system-and-information-integrity-si}

#### 보안 경고, 권고 및 지시 {#security-alerts-advisories-and-directives}

GitLab은 [권고 데이터베이스](../user/application_security/gitlab_advisory_database/_index.md)를 유지하여 소프트웨어 및 종속성과 관련된 보안 취약성을 추적합니다. GitLab은 CVE 번호 부여 기관(CNA)입니다. [CVE ID 요청](../user/application_security/cve_id_request.md) 생성을 위해 이 페이지를 따릅니다.

#### 이메일 {#email}

GitLab은 [GitLab 애플리케이션 인스턴스에서 사용자에게 이메일 알림 전송](../administration/email_from_gitlab.md#sending-emails-to-users-from-gitlab)을 지원합니다. DHS BOD 18-01 지침은 스팸 보호로서 발신 메시지에 대해 도메인 기반 메시지 인증, 보고 및 준수(DMARC)를 구성해야 한다고 나타냅니다. GitLab은 [SMTP에 대한 구성 지침](https://docs.gitlab.com/omnibus/settings/smtp/)을 광범위한 이메일 공급자 범위에 제공하며, 이를 사용하여 이 요구 사항을 충족하는 데 도움이 될 수 있습니다.

### 기타 서비스 및 개념 {#other-services-and-concepts}

#### 러너 {#runners}

러너는 모든 GitLab 배포에서 다양한 작업 및 도구에 필요합니다. 데이터 경계 요구 사항을 유지하기 위해 고객은 권한 부여 경계 내에 [자체 관리 러너](https://docs.gitlab.com/runner/)를 배포해야 할 수 있습니다. GitLab은 [러너 구성](../ci/runners/configure_runners.md)에 대한 자세한 정보를 제공하며, 다음과 같은 개념을 포함합니다:

- 최대 작업 시간 제한

- 민감한 정보 보호

- 긴 폴링 구성

- 인증 토큰 보안 및 토큰 회전

- 민감한 정보 노출 방지

- 러너 변수

#### API 활용 {#leveraging-apis}

GitLab은 [REST](../api/rest/_index.md) 및 [GraphQL](../api/graphql/_index.md) API를 포함하여 애플리케이션을 지원하는 강력한 API 모음을 제공합니다. API 보안은 API 엔드포인트를 호출하는 사용자 및 작업에 대한 인증을 올바르게 구성하여 시작됩니다. GitLab은 접근 토큰(FIPS에서 지원하지 않는 개인 액세스 토큰) 및 OAuth 2.0 토큰을 구성하여 접근을 제어하도록 권장합니다.

#### 확장 {#extensions}

[확장](../editor_extensions/_index.md)은 설정된 통합에 따라 NIST 800-53 요구 사항을 충족할 수 있습니다. 편집기 및 IDE 확장은 예를 들어 허용될 수 있지만 타사와의 통합은 권한 부여 경계 요구 사항을 위반할 수 있습니다. 데이터가 고객의 권한 부여 경계 외부로 전송되는 위치를 이해하기 위해 모든 확장을 검증하는 것은 고객의 책임입니다.

### 추가 리소스 {#additional-resources}

GitLab은 다음과 같은 주제를 다루는 GitLab Self-Managed 고객을 위한 [강화 가이드](hardening.md)를 제공합니다:

- [애플리케이션 강화 권장 사항](hardening_application_recommendations.md)

- [CI/CD 강화 권장 사항](hardening_cicd_recommendations.md)

- [구성 권장 사항](hardening_configuration_recommendations.md)

- [운영 체제 권장 사항](hardening_operating_system_recommendations.md)

GitLab CIS 벤치마크 가이드 - GitLab은 [CIS 벤치마크](https://about.gitlab.com/blog/gitlab-introduces-new-cis-benchmark-for-improved-security/)를 게시하여 애플리케이션의 강화 결정을 안내합니다. 이를 본 가이드와 함께 사용하여 NIST 800-53 제어 사항에 따라 환경을 강화할 수 있습니다. CIS 벤치마크의 모든 제안이 NIST 800-53 제어 사항과 직접 일치하지는 않지만 GitLab 인스턴스를 유지 관리하기 위한 모범 사례로 사용됩니다.
