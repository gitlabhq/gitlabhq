---
stage: GitLab Dedicated
group: US Public Sector Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>.
title: GitLab Dedicated for Government 공유 책임 모델
---

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Dedicated for Government

{{< /details >}}

GitLab Dedicated for Government는 연방 기관과의 공유 책임 모델을 포함하는 FedRAMP Moderate 인증을 유지합니다. 연방 기관은 Dedicated for Government GitLab 인스턴스를 운영할 때의 책임과 GitLab 인증에서 상속할 수 있는 책임을 이해해야 합니다. 이 문서는 다음을 이해할 수 있도록 도와줍니다:

- 인증 경계 및 고급 구성 요소입니다.
- GitLab 인스턴스 내에서 보안 및 준수 관리에 대한 책임입니다.
- 공유 책임 모델에 영향을 미칠 수 있는 선택적 기능 및 기능입니다.

## 리소스 {#resources}

NIST 800-53 컨트롤과 연결된 고객 책임의 자세한 분석을 위해 [FedRAMP 패키지 요청 양식](https://www.fedramp.gov/resources/documents/Agency_Package_Request_Form.pdf)을 사용하여 GitLab Dedicated for Government FedRAMP 패키지를 요청하세요. GitLab 패키지 ID는 `FR2411959145`입니다. Connect.gov의 FedRAMP 패키지에서 사용할 수 있는 Control Implementation Summary/Customer Responsibility Matrix Excel 템플릿은 책임을 이해해야 하는 모든 연방 기관에 필수입니다.

[GitLab Dedicated for Government 보안 구성 가이드](dedicated_for_government_secure_config_guide.md)는 이 책임 가이드를 기반으로 특정 구성 지침과 GitLab 설명서에 대한 매핑을 제공합니다.

## 인증 경계 {#authorization-boundary}

![경계의 각 측면에 있는 GitLab 관리 및 고객 관리 리소스입니다.](img/gdg_boundary_diagram_v19_3.png)

## 책임 개요 {#responsibility-overview}

다음 섹션은 표준 GitLab Dedicated for Government 배포에서 고객과 GitLab이 다루는 광범위한 책임을 이해할 수 있도록 도와줍니다. 섹션은 고객 및 GitLab 소유 책임을 설명하는 기능 섹션으로 나뉩니다. 연방 기관이 GitLab 파트너와 협력하여 특정 배포에 적용 가능한 책임을 확인하는 것이 중요합니다. 고객 책임에 영향을 미칠 수 있는 선택적 기능 및 사용자 정의:

1. [사용자 정의 도메인](../subscriptions/gitlab_dedicated/_index.md#custom-domains) \- 고객은 기본 도메인을 사용하지 않고 사용자 정의 도메인을 구성할 수 있습니다.
1. [자체 관리 러너](../subscriptions/gitlab_dedicated/_index.md#self-managed-runners) \- 고객은 CI/CD 워크로드를 지원하기 위해 러너를 연결할 수 있습니다.
1. 연방 기관 ID 제공자 - GitLab은 Single Sign-On을 위해 SAML 및 OpenID Connect(OIDC) 제공자 사용을 지원합니다. PIV/CAC 인증을 지원하려면 고객이 자신의 ID 제공자를 제공해야 합니다.
1. [향상된 네트워크 연결](../subscriptions/gitlab_dedicated/_index.md#secure-networking) \- 고객은 애플리케이션 구성 또는 인프라 설정을 통해 GitLab 엔지니어의 지원을 받아 IP 허용 목록을 구성할 수 있습니다. 인바운드 및 아웃바운드 연결을 위해 PrivateLink를 통해 개인 연결이 지원됩니다.
1. [고객 관리 암호화](../administration/dedicated/encryption.md#customer-managed-encryption) \- 고객은 자신의 암호화 키를 제공할 수 있습니다.

### 인프라 관리 {#infrastructure-management}

GitLab은 다음을 담당합니다:

- 가상 머신 및 K8s 패칭 - Dedicated for Government 엔지니어는 각 고객 테넌트에 대한 AWS의 기본 인프라를 관리합니다. 유지 보수는 기본 인프라를 최신 보안 패치로 업데이트하기 위해 매주 예약됩니다.
- STIG/CIS 벤치마크 적용을 포함한 인프라 강화입니다.
- FIPS 검증 암호를 사용하여 저장 중 및 전송 중인 데이터 암호화입니다.
- 플랫폼 가동 시간 - Dedicated for Government는 백업, 페일오버 및 환경에 대한 RTO 및 RPO를 검증하기 위한 모든 테스트 관리를 담당합니다.
- AWS 네트워크 인프라 내의 IP 허용 목록 유지 관리입니다. 고객은 GitLab 인스턴스에 연결하기 위해 명시적으로 허용해야 하는 도메인 및 고객 IP 목록을 제공할 수 있습니다. GitLab은 요청된 후 해당 허용 목록을 구성할 책임이 있습니다.
- Cloudflare 웹 애플리케이션 방화벽 및 DNS의 유지 관리입니다.
- BYOK를 사용하도록 선택한 경우 GitLab은 AWS 계정 ID를 제공해야 합니다.
- GitLab 애플리케이션에서 생성된 아웃바운드 이메일에 대한 DMARC 및 스팸 보호 구성입니다.

고객은 다음을 담당합니다:

- Dedicated for Government 경계에 연결된 모든 인프라의 유지 관리입니다.
- 애플리케이션 내의 IP 허용 목록 구성입니다.
- Bring Your Own Domain 기능을 사용하도록 선택한 경우 도메인을 DNSSEC과 같은 FedRAMP 요구 사항에 따라 구성해야 합니다.
- BYOK를 사용하도록 선택한 경우 KMS 키 및 키 정책 생성 및 관리, GitLab 제공 AWS 계정 ID에 대한 액세스 부여입니다.
- 다음과 같은 지원 문제를 통해 특정 인프라 구성을 요청하는 것입니다:
  - 참조 아키텍처
  - 총 리포지토리 용량
  - 테넌트 이름
  - 가용 영역
  - 라이선스 키

## 책임 {#responsibilities}

다음 섹션은 표준 GitLab Dedicated for Government 배포에서 고객과 GitLab이 다루는 광범위한 책임을 이해할 수 있도록 도와줍니다. 각 섹션은 기능 영역별로 구성되어 있으며 고객 및 GitLab 소유 책임을 설명합니다. GitLab 파트너와 협력하여 특정 배포에 적용 가능한 책임을 확인하세요.

고객 책임에 영향을 미칠 수 있는 선택적 기능 및 사용자 정의:

- [사용자 정의 도메인](../subscriptions/gitlab_dedicated/_index.md#custom-domains): 기본 도메인을 사용하지 않고 사용자 정의 도메인을 구성하세요.
- [자체 관리 러너](../subscriptions/gitlab_dedicated/_index.md#self-managed-runners): CI/CD 워크로드를 지원하기 위해 러너를 연결하세요.
- 연방 기관 ID 제공자: GitLab은 Single Sign-On을 위해 SAML 및 OpenID Connect(OIDC)를 지원합니다. PIV/CAC 인증을 지원하려면 자신의 ID 제공자를 제공해야 합니다.
- [향상된 네트워크 연결](../subscriptions/gitlab_dedicated/_index.md#secure-networking): 애플리케이션 구성 또는 인프라 설정을 통해 GitLab 엔지니어의 지원을 받아 IP 허용 목록을 구성하세요. 인바운드 및 아웃바운드 연결을 위해 PrivateLink를 통해 개인 연결이 지원됩니다.
- [고객 관리 암호화](../administration/dedicated/encryption.md#customer-managed-encryption): 자신의 암호화 키를 제공하세요.
- [공개 가시성](#public-visibility-and-open-source-code-sharing): 인스턴스에 대해 공개 가시성을 켜고 특정 그룹 또는 프로젝트에 대한 가시성을 구성하세요.
- [GitLab Duo](#gitlab-duo-and-the-ai-gateway): GitLab Duo Self-Hosted가 필요합니다. AI Gateway를 설치하고 유지 관리합니다.

### 인프라 관리 {#infrastructure-management-1}

GitLab은 다음을 담당합니다:

- Dedicated for Government 엔지니어는 AWS의 각 고객 테넌트에 대한 가상 머신 및 Kubernetes 패칭을 관리합니다. 유지 보수는 기본 인프라를 최신 보안 패치로 업데이트하기 위해 매주 예약됩니다.
- STIG 및 CIS 벤치마크가 적용된 인프라가 강화됩니다.
- 저장 중 및 전송 중인 데이터는 FIPS 검증 암호로 암호화됩니다.
- Dedicated for Government는 백업, 페일오버 및 환경에 대한 RTO 및 RPO를 검증하기 위한 테스트를 관리합니다.
- AWS 네트워크 인프라 내에서 IP 허용 목록이 유지됩니다. GitLab 인스턴스에 연결하기 위해 명시적으로 허용할 도메인 및 IP 목록을 제공할 수 있습니다. GitLab은 사용자가 요청한 후 해당 허용 목록을 구성합니다.
- Cloudflare 웹 애플리케이션 방화벽 및 DNS는 GitLab에서 유지 관리됩니다.
- BYOK를 사용하도록 선택한 경우 GitLab은 AWS 계정 ID를 제공합니다.
- DMARC 및 스팸 보호는 GitLab 애플리케이션에서 생성된 아웃바운드 이메일에 대해 구성됩니다.

고객은 다음을 담당합니다:

- Dedicated for Government 경계에 연결된 모든 인프라를 유지 관리하는 것입니다.
- 애플리케이션 내에서 IP 허용 목록을 구성하는 것입니다.
- Bring Your Own Domain 기능을 사용하는 경우 DNSSEC과 같은 FedRAMP 요구 사항에 따라 도메인을 구성하는 것입니다.
- BYOK를 사용하는 경우 KMS 키 및 키 정책을 생성하고 관리하며 GitLab 제공 AWS 계정 ID에 대한 액세스를 부여하는 것입니다.
- 다음과 같은 지원 문제를 통해 특정 인프라 구성을 요청하는 것입니다:
  - 참조 아키텍처
  - 총 리포지토리 용량
  - 테넌트 이름
  - 가용 영역
  - 라이선스 키
  - 루트 사용자 비밀번호
  - 릴리스 롤아웃 및 유지 관리 일정

### GitLab 애플리케이션 {#gitlab-application}

GitLab은 다음을 담당합니다:

- GitLab 애플리케이션은 주간 유지 보수 기간 동안 업그레이드됩니다.

고객은 다음을 담당합니다:

- CI/CD 및 그룹 및 프로젝트 수준 설정을 포함한 GitLab 애플리케이션을 구성하는 것입니다.
- 고객 관리 워크로드에서 실행될 수 있는 최신 GitLab 제공 컨테이너를 가져오는 것입니다.

### 모니터링 {#monitoring}

GitLab은 다음을 담당합니다:

- AWS 인프라 및 보안 도구에서 생성된 보안 이벤트는 GitLab에서 모니터링됩니다.
- 가동 시간 및 플랫폼 안정성 메트릭을 포함한 인프라 메트릭은 GitLab에서 모니터링됩니다.
- 감사 로그는 규정 요구 사항에 따라 보존됩니다.
- GitLab은 인증 경계 내의 기본 인프라 구성 요소에서 보안 사건에 응답하며, NIST 800-61에 따라 영향을 받는 고객 및 US-CERT에 사건을 보고하는 것을 포함합니다.

고객은 다음을 담당합니다:

- 애플리케이션 로그를 사용하는 것입니다. GitLab Support 티켓을 통해 S3의 로그 액세스를 요청하세요.
- 자체 관리 인프라를 모니터링하는 것입니다.
- 고객 인스턴스에 연결된 자체 관리 인프라에서 생성된 모든 감사 로그를 보존하는 것입니다.
- GitLab 애플리케이션 로그 또는 FedRAMP 경계에 영향을 미칠 수 있는 자체 관리 인프라 내에서 감지된 사건을 보고하는 것입니다.

### 취약성 관리 {#vulnerability-management}

GitLab은 다음의 스캔 및 패칭을 담당합니다:

- 웹 애플리케이션입니다. GitLab은 GitLab DAST로 대표 웹 애플리케이션을 스캔하고 식별된 취약성을 패치합니다.
- 컨테이너입니다. GitLab은 AWS Elastic Container Registry의 모든 컨테이너 이미지를 스캔하고 패치하며, 이는 프로덕션 워크로드 내에서 실행되는 컨테이너를 빌드하는 데 사용됩니다. GitLab은 또한 다음 컨테이너 이미지를 스캔하고 패치하며, GitLab에서 가져와 자신의 인프라 및 CI/CD 워크로드에서 실행할 수 있습니다:
  - GitLab DAST 이미지
  - GitLab 컨테이너 레지스트리 Scanner 이미지
  - GitLab API 보안 이미지
  - GitLab SAST 이미지
  - GitLab 코드 기반 인프라 Analyzer 이미지
  - GitLab 시크릿 검색 이미지
  - GitLab 러너 및 러너 Helper 이미지
  - GitLab 종속성 검사 이미지
- 인프라입니다. GitLab은 Dedicated for Government 인증 경계 내에서 사용 중인 모든 VM 및 AMI를 스캔합니다.

고객은 다음을 담당합니다:

- 인증 경계 외부이지만 연결된 자산을 스캔하고 패칭하는 것입니다.
- 배포된 이미지의 취약성을 감지하고 수정하기 위한 프로세스를 설정하는 것입니다.
- GitLab 인스턴스 내에서 관리되는 코드에 특정하거나 CI/CD 워크로드에서 생성된 취약성을 분류하고 수정하는 것입니다.
- GitLab에서 가져와 자신의 인프라에서 실행하는 모든 GitLab 제공 이미지를 스캔하는 것입니다.
- GitLab 제공 이미지에서 취약성을 발견할 때 GitLab과 협력하여 패칭 타임라인을 결정하는 것입니다.

### ID 및 액세스 관리 {#identity-and-access-management}

GitLab은 다음을 담당합니다:

- SAML 및 OIDC를 통한 통합 지원입니다.
- GitLab 인스턴스의 첫 번째 관리자를 프로비저닝하는 것입니다.
- 인증 경계 내의 인프라에 대한 액세스 관리입니다.

고객은 다음을 담당합니다:

- ID 및 액세스 관리 솔루션을 관리하는 것입니다.
- FIPS 준수 및 피싱 저항 두 번째 요소를 포함한 직원에게 인증자를 배포하는 것입니다.
- GitLab 인스턴스 내의 사용자 액세스를 관리하는 것입니다.

### 준수 {#compliance}

GitLab은 다음을 담당합니다:

- 인증 경계의 연간 감사 및 침투 테스트를 수행하는 것입니다.
- 주요 변경 요청을 제출하는 것입니다.
- Plan of Actions and Milestones를 포함한 지속적 모니터링 아티팩트를 유지 관리하는 것입니다.
- System Security Plan 및 첨부 파일을 유지 관리하는 것입니다.

고객은 다음을 담당합니다:

- Dedicated for Government 인증 경계에 연결된 모든 인프라를 포함한 기관 인증 서류 및 자료를 제출하는 것입니다.
- GitLab Information System Security Officer(ISSO)와 함께 월간 지속적 모니터링 제출 사항을 검토하는 것입니다.

### 공개 가시성 및 오픈 소스 코드 공유 {#public-visibility-and-open-source-code-sharing}

연방 기관은 예를 들어 SHARE IT Act에 따라 공개적으로 코드를 공유해야 할 수 있습니다. 기본적으로 GitLab Dedicated for Government는 인스턴스에 대한 공개 가시성 수준을 제한합니다. 최상위 관리자는 그룹 또는 프로젝트를 공개할 수 있게 하기 전에 공개 가시성을 켜야 합니다. 구성 단계는 [가시성 수준 제한](../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels) 및 [프로젝트 및 그룹 가시성](../user/public_access.md)을 참조하세요.

GitLab은 다음을 담당합니다:

- 프로젝트 또는 그룹 가시성 설정과 무관하게 변경되지 않는 인프라 및 FedRAMP 경계 컨트롤을 유지 관리합니다.

고객은 다음을 담당합니다:

- 인스턴스에 대해 공개 가시성을 켜고 특정 그룹 또는 프로젝트에 대한 가시성을 구성하는 것입니다.
- 공개 요구 사항에서 면제되는 사항을 결정하고 문서화하는 것입니다. GitLab은 이러한 면제를 적용하거나 검증하지 않습니다.
- 공개 그룹 및 프로젝트가 통제되지 않은 분류 정보(CUI), 개인식별정보(PII) 또는 기타 통제된 데이터를 노출하지 않는지 확인하는 것입니다. [역할 및 권한](../user/permissions.md)을 참조하세요.
- [시크릿 검색](../user/application_security/secret_detection/_index.md)을 활성화하고 리포지토리를 공개하기 전에 [자격 증명 인벤토리](../administration/credentials_inventory.md)를 검토하는 것입니다. 인증되지 않은 사용자는 공개 리포지토리를 복제할 수 있습니다.
- CI/CD 작업 로그, 스캔 결과 및 러너 토큰이 노출되지 않는지 확인하는 것입니다. [파이프라인 보안](../ci/pipeline_security/_index.md)을 참조하세요.
- 이슈, 컨테이너 레지스트리 및 파이프라인과 같은 공개 프로젝트 내의 개별 기능을 필요할 때만 멤버만으로 제한하는 것입니다. [프로젝트 가시성 변경](../user/public_access.md#change-project-visibility) 및 [프로젝트의 개별 기능의 가시성 변경](../user/public_access.md#change-the-visibility-of-individual-features-in-a-project)을 참조하세요.

### GitLab Duo 및 AI Gateway {#gitlab-duo-and-the-ai-gateway}

GitLab Dedicated for Government는 GitLab 관리 AI Gateway 및 모델 대신 [자체 호스팅 AI Gateway](../administration/gitlab_duo/configure/gitlab_dedicated_for_government.md)가 필요합니다.

GitLab은 다음을 담당합니다:

- 요청한 후 인스턴스와 자체 호스팅 AI Gateway 간의 네트워크 연결을 활성화하는 것입니다.

고객은 다음을 담당합니다:

- AWS GovCloud 환경에서 [AI Gateway](../install/install_ai_gateway.md)를 설치하고 유지 관리하며, 보안 업데이트를 적용하고 이미지를 검증하는 것을 포함합니다.
- GitLab Duo와 함께 사용되는 대형 언어 모델을 선택, 호스팅 및 유지 관리하는 것입니다.
- AI Gateway, 인스턴스 및 선택한 모델 간의 네트워크 액세스를 구성하는 것입니다.
