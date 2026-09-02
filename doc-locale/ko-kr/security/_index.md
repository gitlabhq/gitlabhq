---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "SSH 키 제한, 2FA, 토큰, 강화."
title: GitLab 보안
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## 일반 정보 {#general-information}

이 섹션에서는 플랫폼에 대한 일반 정보 및 권장 사항을 다룹니다.

- [암호 및 OAuth 토큰 저장](../user/profile/user_passwords.md)
- [통합 인증을 통해 생성된 사용자의 암호 생성](../user/profile/user_passwords.md)
- [CRIME 취약성 관리](crime_vulnerability.md)
- [타사 통합에 대한 비밀 로테이션](rotate_integrations_secrets.md)

## 권장 사항 {#recommendations}

GitLab 환경의 보안 태세를 개선하는 방법에 대한 자세한 내용은 [강화 권장 사항](hardening.md)을 참조하세요.

### 백신 소프트웨어 {#antivirus-software}

일반적으로 GitLab 호스트에서 백신 소프트웨어를 실행하는 것은 권장되지 않습니다.

그러나 하나를 사용해야 하는 경우, 시스템에서 GitLab의 모든 위치를 검사에서 제외해야 합니다. 그렇지 않으면 거짓 양성으로 격리될 수 있습니다.

특히 다음 GitLab 디렉터리를 검사에서 제외해야 합니다:

- `/var/opt/gitlab`
- `/etc/gitlab/`
- `/var/log/gitlab/`
- `/opt/gitlab/`

이러한 모든 디렉터리는 [Linux 패키지 구성 문서](https://docs.gitlab.com/omnibus/settings/configuration/)에서 확인할 수 있습니다.

### 사용자 계정 {#user-accounts}

- [인증 옵션 검토](../administration/auth/_index.md).
- [암호 복잡도 요구 사항 수정](../administration/settings/sign_up_restrictions.md#modify-password-complexity-requirements).
- [SSH 키 기술 제한 및 최소 키 길이 요구](ssh_keys_restrictions.md).
- [등록 제한으로 계정 생성 제한](../administration/settings/sign_up_restrictions.md).
- [새 계정 생성 시 이메일 확인 전송](user_email_confirmation.md)
- [2단계 인증 적용](two_factor_authentication.md)하여 사용자가 [2단계 인증 활성화](../user/profile/account/two_factor_authentication.md)하도록 요구합니다.
- [여러 IP에서의 로그인 제한](../administration/reporting/ip_addr_restrictions.md).
- [사용자 암호를 재설정하는 방법](reset_user_password.md).
- [잠긴 사용자의 잠금을 해제하는 방법](unlock_user.md).

### 데이터 액세스 {#data-access}

- [프로젝트 멤버십에 대한 보안 고려 사항](../user/project/members/_index.md#security-considerations).
- [사용자 파일 업로드 보호 및 제거](user_file_uploads.md).
- [사용자 개인정보 보호를 위한 연결된 이미지 프록시](asset_proxy.md).

### 플랫폼 사용 및 설정 {#platform-usage-and-settings}

- [GitLab 토큰 유형 및 사용 검토](tokens/_index.md).
- [속도 제한 구성하여 보안 및 가용성 개선하는 방법](rate_limits.md).
- [아웃바운드 웹후크 요청을 필터링하는 방법](webhooks.md).
- [가져오기 및 내보내기 제한 및 시간 초과를 구성하는 방법](../administration/settings/import_and_export_settings.md).
- [러너 보안 고려 사항 및 권장 사항 검토](https://docs.gitlab.com/runner/security/).
- [CI/CD 변수 보안 고려 사항 검토](../ci/variables/_index.md#cicd-variable-security).
- [파이프라인 보안 - CI/CD 파이프라인에서 비밀의 사용 및 보호](../ci/pipeline_security/_index.md).
- [인스턴스 전체 규정 준수 및 보안 정책 관리](compliance_security_policy_management.md).

### 패칭 {#patching}

GitLab Self-Managed 고객 및 관리자는 기본 호스트의 보안과 GitLab을 최신 상태로 유지할 책임이 있습니다. [GitLab을 정기적으로 패치](../policy/maintenance.md)하고, 운영 체제 및 소프트웨어를 패치하며, 공급 업체의 지침에 따라 호스트를 강화하는 것이 중요합니다.

## 모니터링 {#monitoring}

### 로그 {#logs}

- [GitLab에서 생성된 로그 유형 및 내용 검토](../administration/logs/_index.md).
- [러너 작업 로그 정보 검토](../administration/cicd/job_logs.md).
- [상관 ID를 사용하여 로그를 추적하는 방법](../administration/logs/tracing_correlation_id.md).
- [로깅 구성 및 액세스](https://docs.gitlab.com/omnibus/settings/logs/).
- [감사 이벤트 스트리밍을 구성하는 방법](../administration/compliance/audit_event_streaming.md).

## 대응 {#response}

- [보안 사건에 대응](responding_to_security_incidents.md).

## 속도 제한 {#rate-limits}

속도 제한에 대한 정보는 [속도 제한](rate_limits.md)을 참조하세요.
