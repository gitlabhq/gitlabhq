---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 인증 및 권한 부여 모범 사례
description: "인증, 권한 부여 및 액세스 관리를 위한 보안 권장 사항 및 모범 사례입니다."
---

GitLab 인스턴스를 보호하고 적절한 액세스 제어를 유지하려면 다음 보안 모범 사례를 따르세요. 이 권장 사항을 따르면 조직 전반에서 생산성을 제한하지 않으면서 안전한 액세스를 유지할 수 있습니다.

## 보안 원칙 {#security-principles}

액세스 제어 전략의 기초를 형성하는 기본적인 보안 원칙을 수립합니다.

### 최소 권한 원칙 {#principle-of-least-privilege}

이 원칙은 손상된 계정이나 내부 위협으로 인한 잠재적 손실을 제한하여 보안 위험을 줄입니다.

- 사용자에게 작업을 완료하기 위해 필요한 최소한의 권한을 부여합니다.
- 최소 액세스 또는 게스트 역할을 최상위 그룹에 할당한 다음 필요한 특정 하위 그룹 및 프로젝트에만 더 높은 권한을 부여합니다.
- 민감한 설정에 대한 액세스를 제한하는 사용자 지정 역할을 구현하여 소유자 및 유지보수자의 수를 최소화합니다.
- 토큰을 생성할 때 가능한 가장 제한된 범위를 사용하거나 특정 목적을 위해 다양한 범위를 가진 여러 토큰을 생성합니다.

### 계층적 권한 관리 {#hierarchical-permission-management}

권한을 조직 구조와 일치하도록 구성하여 관리 오버헤드를 줄입니다.

- 가능하면 프로젝트 멤버십 권한 대신 그룹 멤버십 권한을 적용하여 관리 오버헤드를 줄입니다.
- 조직의 중앙화된 액세스 제어 및 보고를 활성화하려면 조직을 위한 단일 최상위 그룹을 만듭니다.
- 그룹 계층을 조직 구조와 일치하도록 구성하고 명확한 소유권 경계를 설정합니다.

### 심층 방어 {#defense-in-depth}

여러 보안 제어를 계층화하여 다양한 유형의 공격 및 오류로부터 보호합니다. 한 제어가 실패하면 다른 제어가 백업 보호를 제공합니다.

- [보호 브랜치](../user/project/repository/branches/protected.md)를 중요 애플리케이션에 설정하여 승인되지 않은 변경을 방지합니다.
- [보호 환경](../ci/environments/protected_environments.md)을 구성하여 배포를 특정 역할 또는 사용자로 제한합니다.
- [보호 컨테이너](../user/packages/container_registry/container_repository_protection_rules.md)를 사용하여 민감한 아티팩트에 대한 추가 보안을 추가합니다.

## 인증 및 자격증명 {#authentication-and-credentials}

GitLab 인스턴스에 대한 승인되지 않은 액세스를 방지하는 강력한 인증 방법을 구현합니다.

### 암호 보안 {#password-security}

암호는 제한 사항에도 불구하고 주요 인증 방법으로 남아 있습니다. 강력한 암호 정책은 조직의 보안 표준을 충족하는 강력한 암호를 요구하여 자격증명 기반 공격의 위험을 줄입니다.

- [암호 복잡성 요구사항](../administration/settings/sign_up_restrictions.md#modify-password-complexity-requirements)을 조직에 적합하도록 구성합니다.
- [손상된 암호 감지](../user/profile/user_passwords.md)를 활성화하여 알려진 손상된 암호의 사용을 방지합니다.

### 2단계 인증 {#two-factor-authentication}

2FA는 두 번째 확인 형식을 요구하여 보안을 크게 향상시킵니다. 암호가 손상되더라도 2FA는 승인되지 않은 액세스를 방지합니다.

- [2단계 인증](../user/profile/account/two_factor_authentication.md)을 모든 사용자, 특히 권한이 높은 사용자에게 요구합니다.
- 2FA 설정에 대한 명확한 문서 및 지원을 제공하여 사용자 채택을 보장합니다.
- 계정 잠금을 방지하기 위해 백업 복구 방법을 구현합니다.

### 토큰 기반 인증 {#token-based-authentication}

토큰은 GitLab 리소스에 대한 안전한 프로그래밍 방식의 액세스를 제공합니다. 다양한 토큰 유형은 다양한 목적을 제공하며 서로 다른 보안 영향을 미칩니다.

- [개인 액세스 토큰](../user/profile/personal_access_tokens.md)을 정기적으로 그리고 만료되기 전에 교체합니다.
- 자동화된 프로세스의 경우 개인 토큰 대신 [그룹 액세스 토큰](../user/group/settings/group_access_tokens.md) 및 [프로젝트 액세스 토큰](../user/project/settings/project_access_tokens.md)을 사용합니다.
- 토큰을 안전하게 저장하고 리포지토리에 커밋하지 마세요.

### SSH 키 인증 {#ssh-key-authentication}

SSH 키는 Git 리포지토리에 대한 안전하고 암호 없는 액세스를 제공합니다. 적절한 키 관리는 보안 유지에 필수적입니다.

- 강력한 SSH 키 알고리즘(최소한 RSA 2048비트 또는 Ed25519)을 사용합니다.
- [SSH 키 제한](../security/ssh_keys_restrictions.md)을 구성하여 보안 표준을 적용합니다.
- 정기적으로 SSH 키를 감사하고 교체하세요. 특히 서비스 계정의 경우 더욱 그렇습니다.

## 액세스 관리 {#access-management}

누가 어떤 리소스에 액세스할 수 있는지 제어하고 해당 권한을 시간 경과에 따라 모니터링합니다. 효과적인 액세스 관리는 보안 요구사항과 운영 효율성의 균형을 맞춥니다.

### 사용자 유형 관리 {#user-type-management}

다양한 사용자 유형은 조직과의 관계 및 보안 요구사항에 따라 다양한 액세스 수준이 필요합니다. 사용자를 올바르게 분류하면 적절한 액세스 경계를 적용할 수 있습니다.

- 계약자 및 제3자를 [외부 사용자](../administration/external_users.md)로 지정하여 내부 프로젝트에 대한 해당 가시성을 자동으로 제한합니다.
- 리포지토리와의 제한된 상호 작용이 필요한 외부 협력자에게 게스트 역할을 할당합니다.
- 인스턴스 전체에서 읽기 전용 액세스가 필요한 규정 준수 및 보안 담당자를 위해 [감사자 사용자](../administration/auditor_users.md)를 사용합니다.

### 정기적 액세스 검토 {#regular-access-reviews}

정기적 액세스 검토는 역할 및 책임이 시간에 따라 변경됨에 따라 사용자 권한이 적절한 상태로 유지되도록 합니다. 정기적 검토는 부적절한 액세스가 보안 위험이 되기 전에 식별하고 해결하는 데 도움이 됩니다.

- 정기적 액세스 검토를 수행하여 사용자 권한을 확인하고 불일치 사항을 즉시 해결합니다.
- [사용자 내보내기](../administration/admin_area.md#user-permission-export) 및 [그룹 내보내기](../user/group/manage.md#export-members-as-csv) 기능을 사용하여 포괄적인 액세스 보고서를 생성합니다.
- 사용자가 조직을 떠나거나 역할을 변경할 때 즉시 액세스를 제거합니다.

### 액세스 모니터링 및 감사 {#access-monitoring-and-auditing}

액세스 패턴 및 권한 변경의 지속적인 모니터링은 보안 사고를 감지하고 규정 준수를 유지하는 데 도움이 됩니다. 감사 추적은 누가 어떤 리소스에 언제 액세스했는지에 대한 가시성을 제공합니다.

- [감사 이벤트 스트리밍](../administration/compliance/audit_event_streaming.md)을 SIEM 도구로 구성하여 실시간 보안 모니터링을 수행합니다.
- [자격증명 인벤토리](../administration/credentials_inventory.md)를 정기적으로 검토하여 사용되지 않거나 과도한 권한이 있는 토큰을 식별합니다.
- 승인되지 않은 액세스 변경 또는 권한 상향식 조정을 모니터링합니다.

## 조직 규모 조정 {#organizational-scaling}

다양한 조직 규모 및 구조는 권한 관리에 대한 다양한 접근 방식을 필요로 합니다. 성장하면서 안전을 유지하려면 액세스 제어 관행을 조정하세요.

### 기초 수준(1-50명) {#foundation-level-1-50-users}

생산성을 방해할 수 있는 복잡한 프로세스 없이 좋은 기초를 수립하는 데 집중합니다.

- 기본 역할로 시작하고 프로젝트별이 아닌 그룹 수준에서 권한을 할당합니다.
- 향후 참고를 위해 권한 결정 및 근거를 문서화합니다.
- GitLab 권한 모델 및 보안 관행에 대해 핵심 팀을 교육합니다.
- 그룹 수준의 CI/CD 구성을 설정하여 일관된 보안 관행을 적용합니다.

### 성장 수준(50-200명) {#growth-level-50-200-users}

보안 요구사항과 확장 가능한 프로세스의 필요성의 균형을 맞춥니다.

- [LDAP](../user/group/access_and_permissions.md#manage-group-memberships-with-ldap) 또는 [SAML](../user/group/saml_sso/group_sync.md)을 사용자 그룹과 통합하여 관리를 단순화합니다.
- 공유 리소스 및 민감한 리소스를 위한 별도의 하위 그룹을 만들어 액세스를 제어합니다.
- 팀원을 위한 공식적인 온보딩 및 오프보딩 프로세스를 개발합니다.
- 깊게 중첩된 그룹 구조를 최소화합니다(대부분의 조직의 경우 4-5 수준으로 제한).

### 엔터프라이즈 수준(200명 이상) {#enterprise-level-200-users}

엔터프라이즈급 제어 및 거버넌스 프로세스를 구현합니다.

- [사용자 지정 역할](../user/custom_roles/_index.md)을 개발하여 고유한 액세스 필요를 충족하면서 높은 권한을 가진 사용자의 수를 줄입니다.
- GitLab API를 사용하여 대량 액세스 작업을 자동화하여 수동 프로비저닝 오버헤드를 줄입니다.
- 비즈니스 중단을 방지하기 위해 권한 변경에 대한 거버넌스 프로세스를 수립합니다.
- 권한이 있는 역할에 대해 시간 제한 액세스를 구현하고 업무 분리를 위한 규정 준수 프레임워크를 구현합니다.

## 리포지토리 및 CI/CD 보안 {#repository-and-cicd-security}

코드, 배포 및 자동화된 프로세스를 승인되지 않은 변경 및 액세스로부터 보호합니다. 이 제어를 통해 소프트웨어 개발 및 배포 파이프라인의 무결성을 보장합니다.

### 파이프라인 보안 {#pipeline-security}

CI/CD 파이프라인은 애플리케이션을 배포하고 민감한 리소스에 액세스할 수 있는 높은 권한을 자주 가집니다. 파이프라인 실행 보안은 승인되지 않은 작업을 방지하고 배포 프로세스를 보호합니다.

- [작업 권한](../ci/jobs/fine_grained_permissions.md)을 사용하여 파이프라인 실행 중 액세스할 수 있는 리소스를 제어합니다.
- 중요 배포 스테이지에 대해 [승인 게이트](../ci/environments/deployment_approvals.md)를 구성합니다.
- 환경별 러너 또는 러너 태그를 사용하여 배포를 격리하고 민감한 프로덕션 리소스에 대한 액세스를 제한합니다.

### 리포지토리 보호 {#repository-protection}

소스 코드 리포지토리에는 조직의 지적 재산이 포함되어 있으며 승인되지 않은 변경으로부터 보호가 필요합니다. 리포지토리 보안 제어는 코드 무결성을 보장하고 악의적인 수정을 방지합니다.

- [푸시 규칙](../user/project/repository/push_rules.md)을 구현하여 커밋 표준을 적용하고 민감한 데이터 노출을 방지합니다.
- 변경 사항을 보호된 브랜치에 병합하기 전에 승인 규칙을 통해 [코드 검토](../user/project/merge_requests/approvals/rules.md)를 요구합니다.
- [서명된 커밋](../user/project/repository/signed_commits/_index.md)을 사용하여 커밋 진정성의 암호화 확인을 제공합니다.

### API 및 자동화 보안 {#api-and-automation-security}

자동화된 프로세스 및 API 통합은 광범위한 액세스를 가진 장기 자격증명을 자주 사용합니다. 이러한 비인간 액세스 패턴은 자격증명 악용을 방지하기 위해 특별한 보안 고려사항이 필요합니다.

- 개인 토큰 대신 자동화된 프로세스를 위해 제한된 권한이 있는 서비스 계정을 사용합니다.
- 자동화 및 CI/CD 파이프라인에서 사용되는 자격증명을 정기적으로 교체합니다.
- 비정상적인 행동 또는 권한 상향식 조정 시도에 대해 자동화된 액세스 패턴을 모니터링합니다.
- API 액세스를 위해 토큰을 생성할 때 가능한 가장 구체적인 범위를 사용합니다.
- API 통합에 대해 오류 처리 및 로깅을 구현합니다.
- API 요청의 속도 제한을 설정하여 악용을 방지하고 시스템 안정성을 보장합니다.
