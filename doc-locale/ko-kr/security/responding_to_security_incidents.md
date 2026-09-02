---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 보안 사건에 대응하기
---

보안 사건이 발생했을 때는 주로 조직에서 정의한 프로세스를 따라야 합니다. GitLab 보안 운영팀이 이 가이드를 작성했습니다:

- GitLab Self-Managed 인스턴스 및 GitLab.com의 그룹 관리자와 유지관리자를 위한 것입니다.
- GitLab 서비스와 관련된 다양한 보안 사건에 대응하는 방법에 대한 추가 정보와 모범 사례를 제공합니다.
- 보안 사건을 처리하기 위해 조직에서 정의한 프로세스를 보완하는 것입니다. 이것은 **대체가 아닙니다**.

이 가이드를 사용하면 GitLab과 관련된 보안 사건을 처리하는 데 자신감을 가질 수 있습니다. 필요한 경우 이 가이드는 GitLab 문서의 다른 부분으로 연결됩니다.

> [!warning]
> 이 가이드에 제시된 제안 및 권장사항을 자신의 책임 하에 사용하세요.

## 일반적인 보안 사건 시나리오 {#common-security-incident-scenarios}

### 공용 인터넷에 노출된 자격 증명 {#credential-exposure-to-public-internet}

이 시나리오는 잘못된 구성이나 인적 오류로 인해 민감한 인증 또는 인증 정보가 인터넷에 노출된 보안 이벤트를 의미합니다. 이러한 정보는 다음을 포함할 수 있습니다:

- 비밀번호입니다.
- 개인 액세스 토큰입니다.
- 그룹/프로젝트 액세스 토큰입니다.
- 러너 토큰입니다.
- 파이프라인 트리거 토큰입니다.
- SSH 키입니다.

이 시나리오는 GitLab 서비스를 통한 타사 자격 증명에 대한 민감한 정보 노출을 포함할 수도 있습니다. 노출은 예를 들어 공용 GitLab 프로젝트에 우발적으로 커밋하거나 CI/CD 설정을 잘못 구성하여 발생할 수 있습니다. 자세한 정보는 다음을 참조하세요.

- [GitLab 토큰 개요](tokens/_index.md)
- [GitLab CI/CD 변수 보안](../ci/variables/_index.md#cicd-variable-security)

#### 대응 {#response}

자격 증명 노출과 관련된 보안 사건은 토큰의 유형 및 관련 권한에 따라 낮음에서 중대함까지 다양한 심각도를 가질 수 있습니다. 이러한 사건에 대응할 때는 다음을 수행해야 합니다:

- 토큰의 유형과 범위를 결정합니다.
- 토큰 정보에 기반하여 토큰 소유자와 관련 팀을 식별합니다.
  - 개인 액세스 토큰의 경우 [개인 액세스 토큰 API](../api/personal_access_tokens.md#retrieve-a-personal-access-token)를 사용하여 토큰 세부 정보를 빠르게 검색할 수 있습니다.
- 범위와 잠재적 영향을 평가한 후 토큰을 [취소](../api/personal_access_tokens.md#revoke-a-personal-access-token)하거나 [회전](../api/group_access_tokens.md#rotate-a-group-access-token)합니다. 프로덕션 토큰을 취소하는 것은 노출된 토큰으로 인한 보안 위험과 토큰 취소로 인한 가용성 위험 사이의 균형입니다. 다음의 경우에만 토큰을 취소하세요:
  - 토큰 취소의 잠재적 영향에 대해 확신합니다.
  - 회사의 보안 사건 대응 가이드라인을 따릅니다.
- 자격 증명 노출 시간과 자격 증명을 취소한 시간을 기록합니다.
- 노출된 토큰과 관련된 무단 활동을 식별하기 위해 GitLab 감사 로그를 검토합니다. 토큰의 범위 및 유형에 따라 다음과 관련된 감사 이벤트를 검색합니다:
  - 새로 생성된 사용자입니다.
  - 토큰입니다.
  - 악의적인 파이프라인입니다.
  - 코드 변경 사항입니다.
  - 프로젝트 설정 변경 사항입니다.

#### 이벤트 유형 {#event-types}

- 그룹 또는 네임스페이스에 사용 가능한 [감사 이벤트](../administration/compliance/audit_event_reports.md)를 검토합니다.
- 공격자는 지속성을 유지하기 위해 토큰, SSH 키 또는 사용자 계정을 생성하려고 시도할 수 있습니다. 이러한 활동과 관련된 [감사 이벤트](../user/compliance/audit_event_types.md)를 찾습니다.
- CI 관련 [감사 이벤트](../user/compliance/audit_event_types.md#continuous-integration)에 집중하여 CI/CD 변수 수정 사항을 식별합니다.
- 공격자가 실행한 파이프라인에 대한 [작업 로그](../administration/cicd/job_logs.md)를 검토합니다

### 의심되는 손상된 사용자 계정 {#suspected-compromised-user-account}

#### 대응 {#response-1}

사용자 계정이나 봇 계정이 손상되었다고 의심하면 다음을 수행해야 합니다:

- 현재 위험을 완화하기 위해 [사용자를 차단](../administration/moderate_users.md#block-a-user)합니다.
- 사용자가 액세스했을 수 있는 모든 자격 증명을 재설정합니다. 예를 들어, 유지관리자 또는 소유자 역할을 가진 사용자는 보호된 [CI/CD 변수](../ci/variables/_index.md) 및 [러너 등록 토큰](tokens/_index.md#runner-registration-tokens-legacy)을 볼 수 있습니다.
- [사용자 비밀번호 재설정](reset_user_password.md)합니다.
- 사용자가 [2단계 인증을 활성화](../user/profile/account/two_factor_authentication.md)하도록 하고, [인스턴스 또는 그룹에 대해 2FA 적용](two_factor_authentication.md)을 고려하세요.
- 조사를 완료하고 영향을 완화한 후 사용자를 차단 해제합니다.

#### 이벤트 유형 {#event-types-1}

의심한 계정 행동을 식별하기 위해 사용 가능한 [감사 이벤트](../administration/compliance/audit_event_reports.md)를 검토합니다. 예를 들어:

- 의심스러운 로그인 이벤트입니다.
- 개인, 프로젝트 및 그룹 액세스 토큰의 생성 또는 삭제입니다.
- SSH 또는 GPG 키의 생성 또는 삭제입니다.
- 2단계 인증의 생성, 수정 또는 삭제입니다.
- 리포지토리 변경 사항입니다.
- 그룹 또는 프로젝트 구성 변경 사항입니다.
- 러너 추가 또는 수정입니다.
- 웹후크 또는 Git 후크 추가 또는 수정입니다.
- 권한이 있는 OAuth 애플리케이션 추가 또는 수정입니다.
- 연결된 SAML 신원 제공자 변경 사항입니다.
- 이메일 주소 또는 알림 변경 사항입니다.

### CI/CD 관련 보안 사건 {#cicd-related-security-incidents}

CI/CD 파이프라인은 현대 소프트웨어 개발의 핵심 부분이며 주로 개발자와 SRE가 코드를 빌드, 테스트 및 프로덕션에 배포하는 데 사용됩니다. 이러한 워크플로우가 프로덕션 환경에 연결되어 있으므로 CI/CD 파이프라인 내의 민감한 비밀에 액세스해야 하는 경우가 많습니다. CI/CD와 관련된 보안 사건은 설정에 따라 다를 수 있지만 대체로 다음과 같이 분류할 수 있습니다:

- 노출된 GitLab CI/CD 작업 토큰과 관련된 보안 사건입니다.
- 잘못 구성된 GitLab CI/CD를 통해 노출된 비밀입니다.

#### 대응 {#response-2}

##### 노출된 GitLab CI/CD 작업 토큰 {#exposed-gitlab-cicd-job-token}

파이프라인 작업이 실행되려고 할 때 GitLab은 고유한 토큰을 생성하여 `CI_JOB_TOKEN` [미리 정의된 변수](../ci/variables/predefined_variables.md)로 주입합니다. GitLab CI/CD 작업 토큰을 사용하여 특정 API 엔드포인트로 인증할 수 있습니다. 이 토큰은 작업을 실행하게 된 사용자와 동일한 API 액세스 권한을 가집니다. 토큰은 파이프라인 작업이 실행되는 동안만 유효합니다. 작업이 완료된 후 토큰이 만료되고 더 이상 사용할 수 없습니다.

일반적인 상황에서 `CI_JOB_TOKEN`은 작업 로그에 표시되지 않습니다. 그러나 다음과 같은 방법으로 이 데이터를 의도하지 않게 노출할 수 있습니다:

- 파이프라인에서 상세 로깅을 활성화합니다.
- 셸 환경 변수를 콘솔에 출력하는 명령을 실행합니다.
- 러너 인프라를 적절히 보호하지 못하면 이 데이터가 의도하지 않게 노출될 수 있습니다.

이러한 경우에는 다음을 수행해야 합니다:

- 리포지토리의 소스 코드에 최근 수정 사항이 있는지 확인합니다. 수정된 파일의 커밋 이력을 확인하여 변경을 수행한 계정을 결정할 수 있습니다. 의심스러운 편집이 있다고 의심하면 [의심되는 손상된 사용자 계정 가이드](responding_to_security_incidents.md#suspected-compromised-user-account)를 사용하여 사용자 활동을 조사합니다.
- 해당 파일에 의해 호출되는 모든 코드에 대한 의심스러운 수정은 문제를 야기할 수 있으므로 조사해야 하며 노출된 비밀로 이어질 수 있습니다.
- 취소의 프로덕션 영향을 결정한 후 노출된 비밀 회전을 고려하세요.
- 사용자 및 프로젝트 설정에 대한 의심스러운 수정 사항이 있는지 사용 가능한 [감사 로그](../administration/compliance/audit_event_reports.md)를 검토합니다.

##### 잘못 구성된 GitLab CI/CD를 통해 노출된 비밀 {#secrets-exposed-through-misconfigured-gitlab-cicd}

CI/CD 변수로 저장된 비밀이 [마스킹](../ci/variables/_index.md#mask-a-cicd-variable)되지 않으면 작업 로그에 노출될 수 있습니다. 예를 들어 환경 변수를 출력하거나 상세한 오류 메시지를 만날 수 있습니다. 프로젝트 가시성에 따라 작업 로그는 회사 내에서 액세스하거나 프로젝트가 공용인 경우 인터넷을 통해 액세스할 수 있습니다. 이러한 유형의 보안 사건을 완화하기 위해 다음을 수행해야 합니다:

- [노출된 비밀 가이드](#credential-exposure-to-public-internet)를 따라 노출된 비밀을 취소합니다.
- 변수 마스킹을 고려하세요. 이렇게 하면 변수가 작업 로그에 직접 반영되는 것을 방지합니다. 그러나 마스킹은 완벽하지 않습니다. 예를 들어 마스킹된 변수는 여전히 아티팩트 파일에 기록되거나 원격 시스템으로 전송될 수 있습니다.
- 변수 보호를 고려하세요. 이렇게 하면 보호된 브랜치에서만 사용할 수 있습니다.
- 공용 파이프라인을 비활성화하여 작업 로그 및 아티팩트에 대한 공개 액세스를 방지하는 것을 고려하세요.
- 아티팩트 보관 및 만료 정책을 검토합니다.
- 모범 사례에 대한 자세한 정보를 보려면 CI/CD [작업 토큰 보안 가이드](../ci/jobs/ci_job_token.md#gitlab-cicd-job-token-security)를 따릅니다.
- 노출된 비밀 시스템(예: AWS의 CloudTrail 로그 또는 GCP의 CloudAudit 로그)에 대한 감사 로그를 검토하여 노출 시점에 의심스러운 변경이 있었는지 확인합니다.
- 사용자 및 프로젝트 설정에 대한 의심스러운 수정 사항이 있는지 사용 가능한 감사 로그를 검토합니다.

### 의심되는 손상된 인스턴스 {#suspected-compromised-instance}

GitLab Self-Managed 고객 및 관리자는 다음을 담당합니다:

- 기본 인프라의 보안입니다.
- GitLab 설치를 최신으로 유지합니다.

[정기적으로 GitLab을 업데이트](../policy/maintenance.md)하고 운영 체제와 소프트웨어를 업데이트하며 공급업체 가이드에 따라 호스트를 강화하는 것이 중요합니다.

#### 대응 {#response-3}

GitLab 인스턴스가 손상되었다고 의심하면 다음을 수행해야 합니다:

- 의심한 계정 행동을 확인하기 위해 사용 가능한 [감사 이벤트](../administration/compliance/audit_event_reports.md)를 검토합니다.
- [모든 사용자](../administration/moderate_users.md)(관리자 루트 사용자 포함)를 검토하고 필요한 경우 [의심되는 손상된 사용자 계정 가이드](responding_to_security_incidents.md#suspected-compromised-user-account)의 단계를 따릅니다.
- 자격 증명 인벤토리를 검토합니다(사용 가능한 경우).
- 민감한 자격 증명, 변수, 토큰 및 비밀을 변경합니다. 예를 들어 인스턴스 구성, 데이터베이스, CI/CD 파이프라인 또는 다른 곳에 있는 것들입니다.
- GitLab을 최신 버전으로 업데이트하고 모든 보안 패치 릴리스 후에 업데이트할 계획을 수립합니다.
- 또한 다음의 제안 사항들은 악의적인 공격자로부터 서버가 손상되었을 때 사건 대응 계획에서 실행되는 일반적인 단계입니다:
  1. 모든 서버 상태 및 로그를 나중에 조사할 수 있도록 쓰기 전용 위치에 저장합니다.
  1. 인식하지 못한 백그라운드 프로세스를 찾습니다.
  1. 시스템의 열린 포트를 확인합니다. 저희의 [기본 포트 가이드](../administration/package_information/defaults.md)를 시작점으로 사용할 수 있습니다.
  1. 알려진 양호한 백업에서 호스트를 다시 구축하거나 처음부터 구축하고 최신 보안 패치를 모두 적용합니다.
  1. 네트워크 로그에서 일반적이지 않은 트래픽을 검토합니다.
  1. 네트워크 모니터링 및 네트워크 수준 제어를 설정합니다.
  1. 인바운드 및 아웃바운드 네트워크 액세스를 권한이 있는 사용자 및 서버만으로 제한합니다.
  1. 모든 로그를 독립적인 쓰기 전용 데이터 저장소로 라우팅합니다.

#### 이벤트 유형 {#event-types-2}

시스템 설정, 사용자 권한 및 사용자 로그인 이벤트와 관련된 변경 사항을 결정하기 위해 [시스템 액세스 감사 이벤트](../user/compliance/audit_event_types.md#system-access)를 검토합니다.

### 잘못 구성된 프로젝트 또는 그룹 설정 {#misconfigured-project-or-group-settings}

보안 사건은 프로젝트 또는 그룹 설정이 부적절하게 구성되어 민감하거나 소유권 있는 데이터에 대한 무단 액세스로 이어질 수 있습니다. 이러한 사건에는 다음이 포함될 수 있지만 이에 국한되지 않습니다:

- 프로젝트 가시성 변경 사항입니다.
- 머지 리퀘스트 승인 설정 수정입니다.
- 프로젝트 삭제입니다.
- 프로젝트에 대한 의심스러운 웹후크 추가입니다.
- 보호된 브랜치 설정 변경 사항입니다.

#### 대응 {#response-4}

프로젝트 설정에 대한 무단 수정이 의심되면 다음 단계를 고려하세요:

- 사용 가능한 [감사 이벤트](../administration/compliance/audit_event_reports.md)를 검토하여 조치를 담당하는 사용자를 식별합니다.
- 사용자 계정이 의심스러워 보이면 [의심되는 손상된 사용자 계정 가이드](responding_to_security_incidents.md#suspected-compromised-user-account)에 설명된 단계를 따릅니다.
- 감사 이벤트를 참조하고 프로젝트 소유자 및 유지관리자와 상담하여 설정을 원래 상태로 복원하는 것을 고려하세요.

#### 이벤트 유형 {#event-types-3}

- 감사 로그는 `target_type` 필드를 기반으로 필터링할 수 있습니다. 보안 사건 상황에 따라 이 필드에 필터를 적용하여 범위를 좁힙니다.
- [컴플라이언스 관리](../user/compliance/audit_event_types.md#compliance-management) 및 [그룹 및 프로젝트의 감사 이벤트](../user/compliance/audit_event_types.md#groups-and-projects)의 특정 감사 이벤트를 찾습니다.

### 보안 사건에 대해 GitLab에 지원을 요청 {#engaging-gitlab-for-assistance-with-a-security-incident}

GitLab에 도움을 요청하기 전에 [GitLab 문서](https://docs.gitlab.com)를 검색하세요. 예비 조사를 완료하고 추가 질문이 있거나 지원이 필요한 경우 지원 담당자에게 문의해야 합니다. GitLab 지원으로부터 지원을 받을 자격은 [라이선스로 결정](https://support.gitlab.com/hc/en-us/articles/11626483177756-GitLab-Support#gitlab-support-service-levels)됩니다.

### 보안 모범 사례 {#security-best-practices}

환경을 관리하기 위한 제안 사항을 보려면 [GitLab 보안 문서](_index.md)를 검토하세요.

#### 강화 권장사항 {#hardening-recommendations}

GitLab 환경의 보안 태세를 개선하는 방법에 대한 자세한 내용은 [강화 권장 사항](hardening.md)을 참조하세요.

[Git 남용 속도 제한](../user/group/reporting/git_abuse_rate_limit.md)에 자세히 설명된 대로 남용 속도 제한 구현을 고려할 수도 있습니다. 남용 속도 제한을 설정하면 특정 유형의 보안 사건을 자동으로 완화하는 데 도움이 될 수 있습니다.

### 탐지 {#detections}

GitLab SIRT는 [GitLab SIRT 공용 프로젝트](https://gitlab.com/gitlab-security-oss/guard/-/tree/main/detections)에서 탐지의 활성 저장소를 유지합니다.

이 저장소의 탐지는 감사 이벤트를 기반으로 하며 일반 Sigma 규칙 형식입니다. 시그마 규칙 변환기를 사용하여 원하는 형식으로 규칙을 얻을 수 있습니다. Sigma 형식 및 관련 도구에 대한 자세한 정보는 저장소를 참조하세요. GitLab 감사 로그를 SIEM으로 수집했는지 확인하세요. 감사 이벤트를 원하는 대상으로 스트리밍하려면 [자체 관리 인스턴스용](../administration/compliance/audit_event_streaming.md) 또는 [GitLab.com 최상위 그룹용](../user/compliance/audit_event_streaming.md) 감사 이벤트 스트리밍 가이드를 따라야 합니다.
