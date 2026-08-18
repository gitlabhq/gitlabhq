---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 단일 테넌트 SaaS 솔루션의 이용 가능한 기능 및 이점을 알아봅니다.
title: GitLab Dedicated
---

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Dedicated

{{< /details >}}

GitLab Dedicated는 다음을 특징으로 하는 단일 테넌트 SaaS 솔루션입니다:

- 완전히 격리됩니다.
- 선호하는 AWS 클라우드 리전에 배포됩니다.
- GitLab에서 호스팅하고 유지 관리합니다.

각 인스턴스는 다음을 제공합니다:

- [고가용성](../../administration/dedicated/create_instance/data_residency_high_availability.md)(재해 복구 포함)
- [정기적인 업데이트](../../administration/dedicated/maintenance.md)(최신 기능 포함)
- 엔터프라이즈급 보안 조치.

GitLab Dedicated를 사용하면 다음을 할 수 있습니다:

- 운영 효율성을 높입니다.
- 인프라 관리 오버헤드를 줄입니다.
- 조직의 민첩성을 개선합니다.
- 엄격한 규정 준수 요구 사항을 충족합니다.

## 기본 URL {#default-urls}

GitLab Dedicated는 환경 유형에 따라 각 테넌트에 기본 URL 집합을 할당합니다. `tenant_name`을 테넌트의 이름으로 바꿉니다.

| 구성 요소                          | 프로덕션                              | 사전 프로덕션                                |
|------------------------------------|-----------------------------------------|-----------------------------------------------|
| GitLab 인스턴스                    | `tenant_name.gitlab-dedicated.com`      | `tenant_name.gitlab-dedicated.systems`        |
| GitLab Pages                       | `tenant_name.gitlab-dedicated.site`     | `tenant_name.gitlab-dedicated-pages.systems`  |
| Switchboard(관리 콘솔)   | `console.gitlab-dedicated.com`          | `console.gitlab-dedicated.systems`            |

기본 GitLab 인스턴스 URL을 [사용자 정의 도메인](#custom-domains)으로 바꿀 수 있습니다. GitLab Pages에는 사용자 정의 도메인이 지원되지 않으며, Switchboard URL은 사용자 정의할 수 없습니다.

## 이용 가능한 기능 {#available-features}

이 섹션에서는 GitLab Dedicated에 사용 가능한 주요 기능을 나열합니다.

### 보안 {#security}

GitLab Dedicated는 데이터를 보호하고 인스턴스에 대한 액세스를 제어하는 다음과 같은 보안 기능을 제공합니다.

#### 인증 및 권한 부여 {#authentication-and-authorization}

GitLab Dedicated는 [SAML](../../administration/dedicated/configure_instance/authentication/saml.md) 및 [OpenID Connect(OIDC)](../../administration/dedicated/configure_instance/authentication/openid_connect.md) 공급자를 지원하여 Single Sign-On(SSO)을 구성할 수 있습니다.

지원되는 공급자를 사용하여 Single Sign-On(SSO)을 구성할 수 있습니다. 인스턴스는 서비스 공급자로 작동하며, GitLab이 ID 공급자(IdP)와 통신하도록 필요한 구성을 제공합니다.

#### 보안 네트워킹 {#secure-networking}

두 가지 연결 옵션을 사용할 수 있습니다:

- IP 허용 목록이 있는 공개 연결: 기본적으로 인스턴스는 공개적으로 액세스할 수 있습니다. [IP 허용 목록을 구성](../../administration/dedicated/configure_instance/network_security.md#ip-allowlist)하여 지정된 IP 주소에 대한 액세스를 제한할 수 있습니다.
- AWS PrivateLink를 사용한 비공개 연결: [AWS PrivateLink](https://aws.amazon.com/privatelink/)를 구성하여 [인바운드](../../administration/dedicated/configure_instance/network_security.md#inbound-privatelink-connections) 및 [아웃바운드](../../administration/dedicated/configure_instance/network_security.md#outbound-privatelink-connections) PrivateLink 연결을 설정할 수 있습니다.

공개되지 않은 인증서를 사용하는 내부 리소스에 대한 비공개 연결의 경우 [신뢰할 수 있는 인증서를 지정](../../administration/dedicated/configure_instance/network_security.md#custom-certificate-authorities-for-external-services)할 수도 있습니다.

##### 웹후크 및 통합을 위한 비공개 연결 {#private-connectivity-for-webhooks-and-integrations}

웹후크 및 통합이 공개 인터넷에서 액세스할 수 없는 서비스에 연결해야 하는 경우 비공개 연결을 위해 AWS PrivateLink를 사용할 수 있습니다. GitLab Dedicated는 SaaS 서비스이므로 네트워크의 로컬 IP 주소에 직접 연결할 수 없습니다.

내부 서비스에 대해 비공개 연결을 설정하려면:

1. 내부 서비스에 호스트 이름을 할당합니다.
1. Private Hosted Zone(PHZ) 레코드를 구성하여 아웃바운드 PrivateLink 연결을 통해 이러한 호스트 이름으로 라우팅합니다.
1. 아웃바운드 PrivateLink 연결의 10개 엔드포인트 제한을 고려합니다.

10개 이상의 엔드포인트에 연결해야 하는 경우 [`terraform-outbound-proxy`](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-outbound-proxy) Terraform 모듈을 사용하여 VPC에 역방향 프록시를 배포할 수 있습니다. 이 방법은 더 적은 PrivateLink 연결을 통해 여러 서비스를 라우팅합니다.

#### 데이터 암호화 {#data-encryption}

데이터는 최신 암호화 표준을 사용하여 저장 중 및 전송 중에 암호화됩니다.

선택적으로 저장 중인 데이터에 자체 AWS Key Management Service(KMS) 암호화 키를 사용할 수 있습니다. 이 옵션을 사용하면 GitLab에 저장하는 데이터를 완벽하게 제어할 수 있습니다.

자세한 내용은 [GitLab Dedicated 암호화](../../administration/dedicated/encryption.md)를 참조하세요.

#### 이메일 서비스 {#email-service}

기본적으로 [Amazon Simple Email Service(Amazon SES)](https://aws.amazon.com/ses/)를 사용하여 이메일을 안전하게 보냅니다. 대신 [자체 이메일 서비스를 구성](../../administration/dedicated/configure_instance/users_notifications.md#smtp-email-service)하여 SMTP를 사용할 수 있습니다.

#### 웹 애플리케이션 방화벽 {#web-application-firewall}

{{< details >}}

- 상태:  제한적 출시

{{< /details >}}

Cloudflare는 분산 서비스 거부(DDoS) 보호 및 관련 보안 기능을 위한 웹 애플리케이션 방화벽(WAF)으로 구현됩니다. WAF 구현 및 구성은 GitLab SRE 팀에서 관리합니다. WAF 구성 또는 로그에 직접 액세스할 수 없습니다.

### 규정 준수 {#compliance}

GitLab Dedicated는 데이터의 보안과 신뢰성을 보장하기 위해 다양한 규정, 인증 및 규정 준수 프레임워크를 준수합니다.

#### 규정 준수 및 인증 세부 정보 보기 {#view-compliance-and-certification-details}

[GitLab Dedicated Trust Center](https://trust.gitlab.com/?product=gitlab-dedicated)에서 규정 준수 및 인증 세부 정보를 보고 규정 준수 아티팩트를 다운로드할 수 있습니다.

#### 액세스 제어 {#access-controls}

GitLab Dedicated는 환경을 보호하기 위해 엄격한 액세스 제어를 구현합니다:

- 필요한 최소 권한만 부여하는 최소 권한 원칙을 따릅니다.
- AWS 조직에 대한 액세스를 선택한 GitLab 팀 멤버로 제한합니다.
- 사용자 계정에 대한 포괄적인 보안 정책 및 액세스 요청을 구현합니다.
- 자동화된 작업 및 긴급 액세스를 위해 단일 Hub 계정을 사용합니다.
- GitLab Dedicated 엔지니어는 고객 환경에 직접 액세스할 수 없습니다.

[긴급 상황](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/incident-management/-/blob/main/procedures/break-glass.md#break-glass-procedure)에서 GitLab 엔지니어는 다음을 수행해야 합니다:

1. Hub 계정을 사용하여 고객 리소스에 액세스합니다.
1. 승인 프로세스를 통해 액세스를 요청합니다.
1. Hub 계정을 통해 임시 IAM 역할을 맡습니다.

Hub 및 테넌트 계정의 모든 작업은 CloudTrail에 기록됩니다.

#### 모니터링 {#monitoring}

테넌트 계정에서 GitLab Dedicated는 다음을 사용합니다:

- 침입 탐지 및 맬웨어 검사를 위한 AWS GuardDuty
- 비정상적인 이벤트를 감지하기 위한 GitLab Security Incident Response Team의 인프라 로그 모니터링.

#### 감사 및 관찰성 {#audit-and-observability}

감사 및 관찰성 목적으로 [애플리케이션 로그](../../administration/dedicated/monitor.md)에 액세스할 수 있습니다. 이러한 로그는 시스템 활동 및 사용자 작업에 대한 통찰력을 제공하여 인스턴스를 모니터링하고 규정 준수 요구 사항을 유지하는 데 도움이 됩니다.

### 사용자 정의 도메인 {#custom-domains}

기본적으로 GitLab Dedicated 인스턴스는 [기본 URL](#default-urls)에서 액세스할 수 있습니다. 사용자 정의 도메인을 구성하여 `gitlab.company.com`과 같이 자신의 도메인 이름을 대신 사용할 수 있습니다.

사용자 정의 도메인을 사용하려면:

- GitLab Self-Managed에서 마이그레이션할 때 기존 URL을 유지합니다.
- 모든 도구에서 조직의 도메인을 유지합니다.
- 기존 인증서 관리 또는 도메인 정책과 통합합니다.

다음을 위해 사용자 정의 도메인을 구성할 수 있습니다:

- 기본 GitLab 인스턴스
- 컨테이너 레지스트리(예: `registry.company.com`)
- Kubernetes용 GitLab 에이전트 서버(예: `kas.company.com`)

자세한 내용은 [사용자 정의 도메인](../../administration/dedicated/configure_instance/network_security.md#custom-domains)을 참조하세요.

> [!note]
> GitLab Pages에는 사용자 정의 도메인이 지원되지 않습니다. Pages 사이트는 GitLab Dedicated 인스턴스에 대해 구성된 사용자 정의 도메인에 관계없이 기본 Pages URL에서만 액세스할 수 있습니다.

### 객체 스토리지 다운로드 {#object-storage-downloads}

기본적으로 GitLab Dedicated는 최적의 성능을 위해 S3에서 직접 다운로드를 활성화합니다(`proxy_download = false`). 프록시된 다운로드는 지원되지 않습니다. 다음 설정은 `true`로 설정할 수 없습니다:

- 통합 객체 스토리지 구성에서 `proxy_download`
- Dependency Proxy 객체 스토리지 구성에서 `dependency_proxy_object_store_proxy_download`

직접 다운로드를 지원하는 객체 유형은 다음과 같습니다:

- [CI/CD 작업 아티팩트](../../administration/cicd/job_artifacts.md)
- [종속성 프록시 파일](../../administration/packages/dependency_proxy.md)
- [머지 리퀘스트 차이](../../administration/merge_request_diffs.md)
- [Git Large File Storage(LFS) 객체](../../administration/lfs/_index.md)
- [프로젝트 패키지(예: PyPI, Maven 또는 NuGet)](../../administration/packages/_index.md)
- [컨테이너 레지스트리 컨테이너](../../administration/packages/container_registry.md)
- [사용자 업로드](../../administration/uploads.md)

위의 객체 유형 중 하나를 다운로드하면 브라우저 또는 클라이언트는 GitLab 인프라를 통해 라우팅되지 않고 Amazon S3에 직접 연결됩니다.

### 애플리케이션 {#application}

GitLab Dedicated는 몇 가지 예외를 제외하고 자체 관리 [Ultimate 기능 집합](https://about.gitlab.com/pricing/feature-comparison/)과 함께 제공됩니다. 자세한 내용은 [이용 불가능한 기능](#unavailable-features)을 참조하세요.

#### 고급 검색 {#advanced-search}

GitLab Dedicated는 [고급 검색 기능](../../integration/advanced_search/elasticsearch.md)을 사용합니다.

#### ClickHouse Cloud {#clickhouse-cloud}

ClickHouse Cloud 통합을 통해 [고급 분석 기능](../../integration/clickhouse.md)에 액세스할 수 있으며, 이는 적격 고객에 대해 기본적으로 활성화됩니다. 다음 경우에 적격입니다:

- GitLab Dedicated 테넌트가 상용 AWS 리전에 배포됩니다. GitLab Dedicated for Government는 지원되지 않습니다.
- ClickHouse Cloud는 지원되는 리전에서만 사용 가능합니다. 자세한 내용은 [지원되는 리전](../../administration/dedicated/create_instance/data_residency_high_availability.md#supported-regions)을 참조하세요.

#### GitLab Pages {#gitlab-pages}

GitLab Dedicated에서 [GitLab Pages](../../user/project/pages/_index.md)를 사용하여 정적 웹사이트를 호스팅할 수 있습니다. Pages는 기본적으로 활성화됩니다.

웹사이트는 기본 Pages URL을 사용합니다.

> [!note]
> 사용자 정의 도메인은 지원되지 않습니다. `gitlab.my-company.com`와 같은 사용자 정의 도메인을 추가하면 기본 Pages URL에서 웹사이트에 계속 액세스합니다.

GitLab Self-Managed에서 마이그레이션하고 레거시 와일드카드 도메인(예: `*.gitlab-pages.company.com`)을 보존하려면 [`terraform-gitlab-pages-redirect`](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-gitlab-pages-redirect) Terraform 모듈을 사용하여 기존 와일드카드 도메인에서 기본 Pages URL로 issue 301 리디렉션을 발급할 수 있습니다.

웹사이트에 대한 액세스를 제어하려면:

- [GitLab Pages 액세스 제어](../../user/project/pages/pages_access_control.md)
- [IP 허용 목록](../../administration/dedicated/configure_instance/network_security.md#ip-allowlist)

기존 IP 허용 목록이 Pages 웹사이트에 적용됩니다.

재해 복구 중에 페일오버가 발생하면 사이트는 보조 리전에서 계속 작동합니다.

#### 호스팅된 러너 {#hosted-runners}

[GitLab Dedicated용 호스팅된 러너](../../administration/dedicated/hosted_runners.md)를 사용하면 유지 관리 오버헤드 없이 CI/CD 워크로드를 확장할 수 있습니다.

#### 자체 관리 러너 {#self-managed-runners}

호스팅된 러너 사용 대신 GitLab Dedicated 인스턴스에 자신의 러너를 사용할 수 있습니다.

자체 관리 러너를 사용하려면 소유하거나 관리하는 인프라에 [GitLab Runner](https://docs.gitlab.com/runner/install/)를 설치합니다.

#### OpenID Connect 및 SCIM {#openid-connect-and-scim}

인스턴스에 대한 IP 제한을 유지하면서 [사용자 관리를 위한 SCIM](../../api/scim.md) 또는 [OpenID Connect ID 공급자로서의 GitLab](../../integration/openid_connect_provider.md)을 사용할 수 있습니다.

IP 허용 목록과 함께 이러한 기능을 사용하려면:

- [IP 허용 목록에 대해 SCIM 프로비저닝 활성화](../../administration/dedicated/configure_instance/network_security.md#enable-scim-provisioning-for-your-ip-allowlist)
- [IP 허용 목록에 대해 OpenID Connect 활성화](../../administration/dedicated/configure_instance/network_security.md#enable-openid-connect-for-your-ip-allowlist)

### 사전 프로덕션 환경 {#pre-production-environments}

GitLab Dedicated는 프로덕션 환경의 구성과 일치하는 사전 프로덕션 환경을 지원합니다. 사전 프로덕션 환경을 다음과 같이 사용할 수 있습니다:

- 프로덕션에 구현하기 전에 새로운 기능을 테스트합니다.
- 프로덕션에 적용하기 전에 구성 변경을 테스트합니다.

사전 프로덕션 환경은 GitLab Dedicated 구독에 추가로 구매해야 하며 추가 라이선스는 필요하지 않습니다.

다음과 같은 기능을 사용할 수 있습니다:

- 유연한 크기 조정: 프로덕션 환경의 크기와 일치하거나 더 작은 참조 아키텍처를 사용합니다.
- 버전 일관성: 프로덕션 환경과 동일한 GitLab 버전을 실행합니다.

제한 사항:

- 단일 리전 배포만 가능합니다.
- SLA 약정 없음.
- 프로덕션보다 새로운 버전을 실행할 수 없습니다.

## GitLab에서 관리하는 설정 {#settings-managed-by-gitlab}

Admin 영역을 통해 대부분의 설정을 수정할 수 있지만 GitLab은 시스템 안정성과 보안을 보장하기 위해 특정 설정을 자동으로 관리합니다.

### 속도 제한 {#rate-limits}

GitLab은 인스턴스 크기를 기반으로 속도 제한을 구성하고 최적의 성능을 보장하기 위해 유지 관리 기간 동안 자동으로 기본값으로 재설정합니다. 이러한 제한은 단일 사용자 또는 자동화가 인스턴스의 다른 사용자에 대한 성능을 저하시키지 않도록 합니다.

GitLab Dedicated에서 속도 제한이 작동하는 방식에 대한 자세한 내용은 [인증된 사용자 속도 제한](../../administration/dedicated/user_rate_limits.md)을 참조하세요.

### Gitaly 스토리지 가중치 {#gitaly-storage-weights}

GitLab은 새로운 리포지토리를 Gitaly 노드에 고르게 분산하도록 스토리지 가중치를 구성합니다. Admin 영역에서 스토리지 가중치를 수정하면 GitLab은 다음 배포 중에 변경 사항을 덮어씁니다.

## 이용 불가능한 기능 {#unavailable-features}

이 섹션에서는 GitLab Dedicated에 사용할 수 없는 기능을 나열합니다.

### 인증, 보안 및 네트워킹 {#authentication-security-and-networking}

| 기능                                       | 설명                                                           | 영향                                                       |
| --------------------------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------ |
| LDAP 인증                           | 회사 LDAP/Active Directory 자격 증명을 사용한 인증.     | 대신 GitLab 특정 비밀번호 또는 액세스 토큰을 사용해야 합니다. |
| 스마트 카드 인증                     | 향상된 보안을 위해 스마트 카드를 사용한 인증.               | 기존 스마트 카드 인프라를 사용할 수 없습니다.               |
| Kerberos 인증                       | Kerberos 프로토콜을 사용한 Single Sign-On 인증.                | GitLab에 별도로 인증해야 합니다.                      |
| FortiAuthenticator/FortiToken 2FA             | Fortinet 보안 솔루션을 사용한 2단계 인증.          | 기존 Fortinet 2FA 인프라를 통합할 수 없습니다.       |
| HTTPS를 사용한 Git 클론(사용자 이름/암호)  | HTTPS를 통한 사용자 이름 및 암호 인증을 사용한 Git 작업. | Git 작업을 위해 액세스 토큰을 사용해야 합니다.                   |
| SSH 인증서 인증                   | CA에서 발급한 인증서를 사용한 SSH 인증.                      | SSH 키와 같은 다른 SSH 인증 방법을 사용해야 합니다.    |
| [Sigstore](../../ci/yaml/signing_examples.md) | 소프트웨어 공급망 보안을 위한 키리스 서명 및 검증.  | 기존 코드 서명 방법을 사용해야 합니다.                   |
| 포트 리매핑                                | SSH(22)와 같은 포트를 다른 인바운드 포트로 리매핑합니다.                 | GitLab Dedicated는 기본 통신 포트만 사용합니다.      |

### 통신 및 협업 {#communication-and-collaboration}

| 기능        | 설명                                                         | 영향                                                     |
| -------------- | ------------------------------------------------------------------- | ---------------------------------------------------------- |
| 이메일로 회신 | 이메일을 통해 GitLab 알림 및 토론에 응답합니다.      | GitLab 웹 인터페이스를 사용하여 응답해야 합니다.                  |
| Service Desk   | 외부 사용자가 이메일을 통해 이슈를 생성하기 위한 티켓팅 시스템. | 외부 사용자는 이슈를 생성하려면 GitLab 계정을 가지고 있어야 합니다. |

### 개발 및 AI 기능 {#development-and-ai-features}

| 기능                                | 설명                                                       | 영향                                       |
|----------------------------------------|-------------------------------------------------------------------|----------------------------------------------|
| 일부 GitLab Duo AI 기능        | 취약성 감지 및 생산성을 위한 AI 기반 기능. | 개발 작업을 위한 제한된 AI 지원. |
| 비활성화된 기능 플래그 뒤의 기능 | 개발 중인 실험 및 베타 기능.                   | 실험적 또는 베타 기능에 액세스할 수 없습니다.  |

AI 기능에 대한 자세한 내용은 [GitLab Duo](../../user/gitlab_duo/_index.md)를 참조하세요.

#### 기능 플래그 {#feature-flags}

기능 플래그는 새로운, [실험 및 베타 기능](../../development/documentation/experiment_beta.md)의 개발 및 출시를 지원하는 데 사용됩니다. GitLab Dedicated에서:

- 기능 플래그를 수정할 수 없습니다.
- 기본적으로 활성화된 기능을 사용할 수 있습니다.
- 기본적으로 비활성화된 기능은 사용할 수 없으며 활성화할 수 없습니다.

기능이 일반적으로 사용 가능해지면 배포를 위한 [릴리스 일정](../../administration/dedicated/maintenance.md)을 따르는 동일한 버전에서 사용 가능합니다.

### GitLab Pages {#gitlab-pages-1}

| 기능                | 설명                                                     | 영향 |
| ---------------------- | --------------------------------------------------------------- | ------ |
| 사용자 정의 도메인         | 사용자 정의 도메인 이름에서 GitLab Pages 사이트를 호스팅합니다.                 | Pages 사이트는 기본 Pages URL을 사용하여만 액세스할 수 있습니다. |
| URL 경로의 네임스페이스 | 네임스페이스 기반 URL 구조로 Pages 사이트를 구성합니다.        | 제한된 URL 구성 옵션. |

### 운영 기능 {#operational-features}

다음과 같은 운영 기능은 사용할 수 없습니다:

- 기본 보조 리전을 넘어 Geo 복제를 위한 여러 보조 리전
- [Geo 프록시](../../administration/geo/secondary_proxy/_index.md) 및 통합 URL 사용
- 셀프 서비스 구매 및 구성
- GCP 또는 Azure와 같은 AWS가 아닌 클라우드 공급자로의 배포 지원
- Grafana 및 OpenSearch와 같은 Switchboard의 관찰성 대시보드

### 서버 액세스가 필요한 기능 {#features-that-require-server-access}

다음 기능은 직접 서버 액세스가 필요하며 구성할 수 없습니다:

| 기능                                                       | 설명                                                        | 영향                                                                                                                    |
| ------------------------------------------------------------- | ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------- |
| [서버 측 Git 훅](../../administration/server_hooks.md) | Git 이벤트(사전 수신, 사후 수신)에서 실행되는 사용자 정의 스크립트. | [푸시 규칙](../../user/project/repository/push_rules.md) 또는 [웹후크](../../user/project/integrations/webhooks.md)를 사용합니다. |

> [!note]
> 서버 측 Git 훅은 보안 및 성능상의 이유로 지원되지 않습니다. 대신 [푸시 규칙](../../user/project/repository/push_rules.md)을 사용하여 리포지토리 정책을 적용하거나 [웹후크](../../user/project/integrations/webhooks.md)를 사용하여 Git 이벤트에서 외부 작업을 트리거합니다.

## 서비스 수준 가용성 {#service-level-availability}

GitLab Dedicated는 99.9% 가용성의 월간 서비스 수준 목표를 유지합니다.

서비스 수준 가용성은 달력 월 동안 GitLab Dedicated를 사용할 수 있는 시간의 백분율을 측정합니다. GitLab은 다음 핵심 서비스를 기반으로 가용성을 계산합니다:

| 서비스 영역       | 포함된 기능                                                                 |
| ------------------ | --------------------------------------------------------------------------------- |
| 웹 인터페이스      | GitLab 이슈, 머지 리퀘스트, GitLab API, HTTPS를 통한 Git 작업 |
| 컨테이너 레지스트리 | 레지스트리 HTTPS 요청                                                           |
| Git 작업     | SSH를 통한 Git 푸시, 풀 및 클론 작업                                     |

### 서비스 수준 제외 {#service-level-exclusions}

다음은 서비스 수준 가용성 계산에 포함되지 않습니다:

- 고객 잘못 구성으로 인한 서비스 중단
- GitLab 제어 범위 외의 고객 또는 클라우드 공급자 인프라 문제
- 예정된 유지 관리 기간
- 중요 보안 또는 데이터 문제에 대한 긴급 유지 관리
- 자연재해, 광범위한 인터넷 중단, 데이터 센터 장애 또는 GitLab 제어 범위 외의 기타 이벤트로 인한 서비스 중단.

### 재해 복구 {#disaster-recovery}

재해 복구에 대한 자세한 내용(복구 목표 포함)은 [GitLab Dedicated용 재해 복구](../../administration/dedicated/disaster_recovery.md)를 참조하세요.

## GitLab Dedicated로 마이그레이션 {#migrate-to-gitlab-dedicated}

GitLab Dedicated로 데이터를 마이그레이션하려면:

- 다른 GitLab 인스턴스에서:
  - [직접 전송](../../user/group/import/_index.md)을 사용합니다.
  - [직접 전송 API](../../api/bulk_imports.md)를 사용합니다.
- 타사 서비스에서:
  - [가져오기 소스](../../user/import/_index.md)(마이그레이션 도구)를 사용합니다.
- 복잡한 마이그레이션의 경우:
  - [Professional Services](../../user/import/_index.md#migrate-by-engaging-professional-services)를 참여하세요.

## 만료된 구독 {#expired-subscriptions}

구독이 만료되기 전에 종료 날짜가 다가오고 있다는 알림을 받습니다.

구독이 만료되면 30일 동안 인스턴스에 액세스할 수 있습니다.

데이터를 보존하려면 만료 후 15일 이내에 계정 팀에 문의하거나 지원팀에 이메일을 보내 데이터 보존을 요청하세요.

이 30일 기간 동안 다음을 할 수 있습니다:

- 지원팀에 이메일을 보내 데이터를 검색할 추가 시간을 요청합니다.
- 마이그레이션 지원 또는 오프보딩 지원을 위해 Professional Services를 참여하세요.

30일 후 데이터를 보관하거나 다른 인스턴스로 마이그레이션하지 않으면 인스턴스가 종료되고 모든 고객 콘텐츠가 삭제됩니다. 여기에는 모든 프로젝트, 리포지토리, 이슈, 머지 리퀘스트 및 기타 데이터가 포함됩니다.

인스턴스 종료 후 90일 후 계정 제거 확인을 요청할 수 있습니다. 확인은 계정이 폐쇄되었음을 나타내는 AWS의 이메일로 제공됩니다.

## 시작하기 {#get-started}

GitLab Dedicated에 대한 자세한 내용이나 데모를 요청하려면 [GitLab Dedicated](https://about.gitlab.com/dedicated/)를 참조하세요.

GitLab Dedicated 인스턴스 설정에 대한 자세한 내용은 [GitLab Dedicated 인스턴스 만들기](../../administration/dedicated/create_instance/_index.md)를 참조하세요.
