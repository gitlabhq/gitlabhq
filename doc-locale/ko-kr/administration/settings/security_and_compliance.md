---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: 보안 및 규정 준수 설정
description: 패키지 리포지토리가 동기화되는 방법을 포함하여 보안 및 규정 준수 관리 설정을 구성합니다.
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## 종속성 검사 {#dependency-scanning}

### SBOM 스캔 API 제한 {#sbom-scan-api-limits}

[종속성 검사 SBOM 기능](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md) 은 [사전 정의된 제한](../instance_limits.md#dependency-scanning-using-sbom-limits)이 있는 내부 API를 사용합니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

이러한 제한에 대해 다양한 값을 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **보안 및 규정 준수**를 선택합니다.
1. **종속성 검사**를 확장합니다.
1. 모든 속도 제한의 값을 변경하거나, 속도 제한을 `0`로 설정하여 비활성화합니다.
1. **변경 사항 저장**을 선택합니다.

## 패키지 메타데이터 데이터베이스 동기화 {#package-metadata-database-synchronization}

### 동기화할 패키지 레지스트리 메타데이터 선택 {#choose-package-registry-metadata-to-sync}

GitLab 패키지 메타데이터 데이터베이스(PMDB)와 동기화하려는 패키지를 선택하여 [라이선스 준수](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md) 및 [지속적 취약성 스캔](../../user/application_security/continuous_vulnerability_scanning/_index.md)을 수행합니다:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **보안 및 규정 준수**를 선택합니다.
1. **라이선스 준수**를 확장합니다.
1. **동기화할 패키지 레지스트리 메타데이터**에서 동기화하려는 패키지 레지스트리의 체크박스를 선택하거나 해제합니다.
1. **변경 사항 저장**을 선택합니다.

이 데이터 동기화가 작동하려면 GitLab 인스턴스에서 `storage.googleapis.com` 도메인으로의 아웃바운드 네트워크 트래픽을 허용해야 합니다. [패키지 메타데이터 데이터베이스 활성화](../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database)에서 설명한 오프라인 설정 지침을 참조하세요.

### 보안 고려 사항 {#security-considerations}

PMDB는 공개적으로 액세스 가능한(읽기 전용) Google Cloud Storage 버킷에 라이선스 및 권고 데이터를 게시하는 서비스입니다. 누구나 버킷을 읽을 수 있지만, 승인된 GitLab 유지관리자만 IAM 제어를 통해 쓰기 액세스 권한이 있습니다. GitLab은 보안된 PostgreSQL 데이터베이스에서 데이터를 지속적으로 수집하고 OIDC 인증을 사용하는 비공개 서비스를 통해 내보냅니다. GitLab 인스턴스는 공개 버킷에서 데이터를 동기화하고, 스키마 유효성을 검사한 다음, 검증된 데이터를 GitLab 데이터베이스로 업서트합니다.
