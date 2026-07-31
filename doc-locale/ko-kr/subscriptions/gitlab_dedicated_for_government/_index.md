---
stage: GitLab Dedicated
group: US Public Sector Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 정부 기관 및 규제 산업을 위한 단일 테넌트 SaaS 솔루션입니다.
title: GitLab Dedicated for Government
---

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Dedicated for Government

{{< /details >}}

GitLab Dedicated for Government은 정부 기관 및 규제 산업 조직을 위해 설계된 단일 테넌트 SaaS 솔루션입니다. GitLab은 모든 인프라, 운영 및 규정 준수 요구사항을 관리하므로 팀이 개발에 집중할 수 있습니다.

인스턴스에는 다음과 같은 기능이 있습니다:

- 완전한 GitLab Ultimate 기능 세트 및 DevSecOps 플랫폼
- US-West 지역의 [AWS GovCloud](https://docs.aws.amazon.com/govcloud-us/latest/UserGuide/whatis.html)에 배포된 전용 AWS 계정의 격리된 인프라
- 고가용성 및 재해 복구

## 규정 준수 인증 {#compliance-certifications}

GitLab Dedicated for Government은 다음 프로그램으로 인증되었으므로 기관이 추가 규정 준수 검토 없이 조달 및 배포할 수 있습니다:

[FedRAMP Moderate](https://marketplace.fedramp.gov/products/FR2411959145?cache=true) : 운영 권한(ATO)을 포함하여 클라우드 서비스에 대한 연방 보안 요구사항을 충족합니다.

[GovRAMP](https://govramp.org/product-list/) (패키지 ID: SR25098) : 클라우드 서비스에 대한 주 및 지방 정부 보안 요구사항을 충족합니다.

[TX-RAMP](https://dir.texas.gov/information-security/texas-risk-and-authorization-management-program-tx-ramp) Level 2 (TX-RAMP ID: TX1549412) : 클라우드 서비스에 대한 텍사스 주 보안 요구사항을 충족합니다.

## 보안 아키텍처 {#security-architecture}

인스턴스에는 다음과 같은 보안 제어가 포함됩니다:

- 연방 및 주 요구사항에 맞춘 지속적인 모니터링을 포함한 FedRAMP Moderate 및 GovRAMP 규정 준수
- US-West 지역의 AWS GovCloud 인프라를 통한 데이터 주권 보장
- 다른 모든 테넌트와 분리된 전용 AWS 계정의 격리된 인프라
- 보관 중인 데이터 및 전송 중인 데이터에 대한 FIPS 요구사항을 충족하는 암호화 표준
- 최소 권한 원칙을 따르고 포괄적인 감사 추적을 포함한 액세스 제어

보안 책임의 자세한 분석은 [공유 책임 모델](../../security/dedicated_for_government_shared_responsibility_model.md)과 [보안 구성 가이드](../../security/dedicated_for_government_secure_config_guide.md)를 참조하세요.

### 데이터 거주지 및 인프라 격리 {#data-residency-and-infrastructure-isolation}

미국 데이터 거주지 요구사항을 충족하기 위해 인스턴스는 US-West 지역의 [AWS GovCloud](https://docs.aws.amazon.com/govcloud-us/latest/UserGuide/whatis.html)에 배포됩니다. GitLab 인스턴스는 AWS GovCloud에서만 실행됩니다. 사용자 자신의 워크로드 및 인접한 시스템은 GCP 또는 Azure를 포함한 모든 플랫폼에서 실행되고 인스턴스와 통합될 수 있습니다.

리포지토리, 데이터베이스, 아티팩트 및 백업을 포함한 모든 고객 데이터는 AWS GovCloud 경계 내에 유지됩니다. 환경은 GitLab.com과의 완전한 격리 상태에서 GitLab 애플리케이션을 호스팅하는 데 필요한 모든 인프라를 포함합니다.

데이터는 FIPS 준수 암호화 표준을 사용하여 보관 중 및 전송 중에 암호화됩니다.

### 액세스 제어 {#access-controls}

환경은 여러 계층의 보안 제어를 통해 보호됩니다:

- 엔지니어는 테넌트 환경에 직접 액세스할 수 없으며 역할에 필요한 최소 권한으로 운영됩니다.
- 인프라는 보안 위협 및 이상을 감지하기 위해 주 7일, 24시간 모니터링됩니다.
- 모든 액세스 및 변경사항은 GitLab 보안 인시던트 대응팀에 의해 기록되고 검토됩니다.
- 액세스 요청은 정부 규정 준수 요구사항에 맞춘 공식 보안 정책 및 승인 워크플로를 따릅니다.

## 이용 가능한 기능 {#available-features}

GitLab Dedicated for Government는 완전한 GitLab Ultimate 기능 세트를 제공합니다. 이러한 기능은 FedRAMP 및 GovRAMP 규정 준수 및 정부 보안 프레임워크 내에서 작동하도록 설계되었습니다.

### 가용성 및 확장성 {#availability-and-scalability}

인스턴스는 고가용성이 활성화된 [클라우드 네이티브 하이브리드 참조 아키텍처](../../administration/reference_architectures/_index.md#cloud-native-hybrid)의 수정된 버전을 활용합니다.

[온보딩](../../administration/dedicated/create_instance/_index.md#create-your-instance) 시 GitLab은 사용자 수에 따라 가장 가까운 참조 아키텍처 크기와 일치합니다.

> [!note]
> 게시된 [참조 아키텍처](../../administration/reference_architectures/_index.md)는 기초로 제공됩니다. GitLab Dedicated for Government은 보안 및 규정 준수 강화를 위해 추가 AWS 서비스로 이를 확장하므로 비용이 표준 참조 아키텍처 추정과 다릅니다.

### 재해 복구 {#disaster-recovery}

GitLab은 데이터베이스 및 Git 리포지토리를 포함한 모든 데이터 저장소를 백업합니다. 이러한 백업은 테스트되며 기본적으로 추가 중복성을 위해 별도의 클라우드 지역에 안전하게 저장됩니다.

### 인증 및 권한 부여 {#authentication-and-authorization}

다음을 사용하여 단일 사인온(SSO)을 구성할 수 있습니다:

- [SAML](../../administration/dedicated/configure_instance/authentication/saml.md)
- [OpenID Connect (OIDC)](../../administration/dedicated/configure_instance/authentication/openid_connect.md)

인스턴스는 서비스 제공자 역할을 하며 사용자가 GitLab이 IdP(ID 제공자)와 통신할 수 있도록 필요한 구성을 제공합니다.

인스턴스에 대해 여러 ID 제공자를 구성할 수 있습니다.

### 이메일 전달 {#email-delivery}

이메일은 [Amazon Simple Email Service (Amazon SES)](https://aws.amazon.com/ses/)를 사용하여 전송됩니다. Amazon SES로의 연결은 암호화됩니다.

Amazon SES 대신 SMTP 서버를 사용하여 애플리케이션 이메일을 보내려면 [사용자 자신의 이메일 서비스를 구성](../../administration/dedicated/configure_instance/users_notifications.md#smtp-email-service)할 수 있습니다.

### 고급 검색 {#advanced-search}

[고급 검색](../../user/search/advanced_search.md) 기능이 포함됩니다. 코드, 작업 항목, 머지 리퀘스트 등을 포함한 전체 GitLab 인스턴스에서 검색할 수 있습니다.

### GitLab Duo {#gitlab-duo}

[GitLab Duo](../../user/gitlab_duo/_index.md) AI 기능은 FedRAMP 및 GovRAMP로 인증되었으며 추가 규정 준수 검토 없이 연방, 주, 지방 및 교육 기관에서 사용할 수 있습니다. 사용 가능한 기능은 다음과 같습니다:

- [GitLab Duo Code Suggestions](../../user/project/repository/code_suggestions/_index.md)
- [GitLab Duo 취약성 설명](../../user/application_security/analyze/duo.md)
- [GitLab Duo 취약성 해결](../../user/application_security/remediate/duo.md)
- [GitLab Duo Chat](../../user/gitlab_duo_chat/_index.md)

## 이용 불가능한 기능 {#unavailable-features}

FedRAMP 및 GovRAMP 인증을 유지하고 정부 보안 요구사항을 충족하기 위해 일부 GitLab 기능은 GitLab Dedicated for Government에서 사용할 수 없습니다.

### 인증, 보안 및 네트워킹 {#authentication-security-and-networking}

| 기능                              | 대체 방법 |
| ------------------------------------ | ----------- |
| LDAP 또는 Kerberos 인증      | ID 제공자와 함께 SAML 또는 OIDC 사용 |
| FortiAuthenticator 또는 FortiToken 2FA | ID 제공자 MFA 사용 |

### 통신 및 협업 {#communication-and-collaboration}

| 기능        | 대체 방법 |
| -------------- | ----------- |
| 이메일로 회신 | 웹 인터페이스 사용 |
| Service Desk   | 이슈 추적 사용 |
| Mattermost     | 외부 채팅 도구 사용 |

### 개발 및 AI 기능 {#development-and-ai-features}

| 기능                                                            | 대체 방법 |
| ------------------------------------------------------------------ | ----------- |
| 일부 [GitLab Duo AI 기능](../../user/gitlab_duo/_index.md) | [지원되는 AI 기능](../../user/gitlab_duo/_index.md) 참조 |
| [서버 측 Git 훅](../../administration/server_hooks.md)      | [푸시 규칙](../../user/project/repository/push_rules.md) 또는 [웹후크](../../user/project/integrations/webhooks.md) 사용 |
| GitLab 사용자 인터페이스 외부에서 구성된 기능           | 지원팀에 문의 |

### 애플리케이션 기능 {#application-features}

사용자 정의 도메인이 구성된 경우 GitLab Pages를 사용할 수 없습니다. 사용자 정의 도메인을 구성하면 원래 `tenant_name.gitlab-dedicated.com` 도메인을 더 이상 사용할 수 없게 되어 GitLab Pages의 기능이 중단됩니다.

### 운영 기능 {#operational-features}

다음과 같은 운영 기능은 사용할 수 없습니다:

- Geo
- 셀프 서비스 구매 및 구성

### 기능 플래그 {#feature-flags}

기능 플래그는 인스턴스에서 어떤 기능을 사용할 수 있는지를 제어합니다:

- 기본적으로 활성화된 플래그가 있는 기능만 사용 가능합니다
- 기본적으로 비활성화된 플래그가 있는 기능은 사용할 수 없습니다
- 기능 플래그를 수정할 수 없습니다

## 서비스 운영 {#service-operations}

GitLab은 정부 특화 운영 프로세스를 사용하여 인스턴스에 대한 모든 유지 관리, 모니터링 및 지원을 관리합니다. 이러한 프로세스는 모든 유지 관리 및 지원 활동 전반에 걸쳐 규정 준수, 보안 및 안정성을 우선 순위로 합니다.

### 유지 관리 {#maintenance}

인스턴스는 정해진 주간 시간 동안 유지 관리를 받습니다. 자세한 내용은 [유지 관리 시간 일정](../../administration/dedicated/maintenance.md#maintenance-window-schedule)을 참조하세요.

### 릴리스 및 버전 {#releases-and-versions}

인스턴스는 최신 GitLab 버전보다 한 단계 뒤의 릴리스를 실행합니다. 예를 들어 최신 버전이 16.8이면 인스턴스는 16.7을 실행합니다.

이 방식은 안정성을 제공하는 동시에 긴급 유지 관리를 통해 중요한 보안 패치를 받습니다. 자세한 내용은 [릴리스 롤아웃 일정](../../administration/dedicated/releases.md#release-rollout-schedule)을 참조하세요.

### 서비스 수준 계약 {#service-level-agreement}

인스턴스는 월간 99.9% 가용성의 서비스 수준 계약(SLA)을 유지합니다. GitLab은 이 SLA 약정의 제공을 지원하기 위해 내부 서비스 수준 목표(SLO)를 사용합니다.

다음 목표가 적용됩니다:

- 복구 지점 목표(RPO) 목표: 재해 복구 시나리오에서 최대 4시간의 데이터 손실 시간
- 복구 시간 목표(RTO) 목표: 서비스 복구는 인시던트 심각도 및 영향에 따라 우선 순위가 지정됩니다

GitLab은 데이터 무결성 및 보안을 보장하면서 가능한 한 빨리 서비스를 복구하기 위해 노력합니다.

## 영업팀 문의 {#contact-sales}

시작할 준비가 되셨나요? [영업팀에 문의](https://about.gitlab.com/sales/)하여 요구사항을 논의하고 조직의 규정 준수 및 보안 필요를 지원하는 방법을 알아보세요.
