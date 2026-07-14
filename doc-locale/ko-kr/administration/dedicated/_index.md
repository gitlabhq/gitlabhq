---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Dedicated를 시작하세요.
title: GitLab Dedicated 관리
---

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab Dedicated

{{< /details >}}

GitLab Dedicated를 사용하여 AWS에서 호스팅하는 완전 관리형 단일 테넌트 인스턴스에서 GitLab을 실행합니다. GitLab Dedicated 관리 포털인 Switchboard를 통해 인스턴스 구성에 대한 제어를 유지하며, GitLab은 기반 인프라를 관리합니다.

자세한 내용은 [구독 페이지](../../subscriptions/gitlab_dedicated/_index.md)를 참조하세요.

## 아키텍처 개요 {#architecture-overview}

GitLab Dedicated는 다음을 제공하는 안전한 인프라에서 실행됩니다:

- AWS의 완전히 격리된 테넌트 환경
- 자동 장애 조치를 포함한 높은 가용성
- 지역 기반 재해 복구
- 정기적인 업데이트 및 유지 관리
- 엔터프라이즈 수준의 보안 제어

자세한 내용은 [GitLab Dedicated 아키텍처](architecture.md)를 참조하세요.

## 인프라 구성 {#configure-infrastructure}

| 기능 | 설명 | 설정 방법 |
|------------|-------------|---------------------|
| [AWS 데이터 리전](create_instance/data_residency_high_availability.md#region-selection) | 기본 운영, 재해 복구 및 백업을 위한 리전을 선택합니다. GitLab은 이러한 리전에 데이터를 복제합니다. | 온보딩 |
| [유지 관리 창](maintenance.md#maintenance-windows) | 주간 4시간 유지 관리 창을 선택합니다. GitLab은 이 기간 동안 업데이트, 구성 변경 및 보안 패치를 수행합니다. | 온보딩 |
| [릴리스 관리](releases.md#release-rollout-schedule) | GitLab은 매월 새로운 기능과 보안 패치로 인스턴스를 업데이트합니다. | 기본적으로 <br>사용 가능 |
| [Geo 재해 복구](disaster_recovery.md) | 온보딩 중에 보조 리전을 선택합니다. GitLab은 Geo를 사용하여 선택한 리전에 복제된 보조 사이트를 유지합니다. | 온보딩 |
| [자동 백업](disaster_recovery.md#automated-backups) | GitLab은 선택한 AWS 리전에 데이터를 백업합니다. | 기본적으로 <br>사용 가능 |

## 인스턴스 보안 {#secure-your-instance}

| 기능 | 설명 | 설정 방법 |
|------------|-------------|-----------------|
| [데이터 암호화](encryption.md) | GitLab은 AWS에서 제공하는 인프라를 통해 저장 시 및 전송 중 데이터를 암호화합니다. | 기본적으로 <br>사용 가능 |
| [고객 관리 암호화 키](encryption.md#customer-managed-encryption) | GitLab 관리 AWS KMS 키를 사용하는 대신 암호화를 위해 자신의 AWS KMS 키를 제공할 수 있습니다. GitLab은 이러한 키를 인스턴스와 통합하여 저장된 데이터를 암호화합니다. | 온보딩 |
| [GitLab SAML SSO](configure_instance/authentication/saml.md) | SAML ID 공급자에 대한 연결을 구성합니다. GitLab은 인증 플로우를 처리합니다. | Switchboard |
| [IP 허용 목록](configure_instance/network_security.md#ip-allowlist) | 승인된 IP 주소를 지정합니다. GitLab은 승인되지 않은 액세스 시도를 차단합니다. | Switchboard |
| [사용자 지정 인증서 기관](configure_instance/network_security.md#custom-certificate-authorities-for-external-services) | SSL 인증서를 가져옵니다. GitLab은 개인 서비스로의 보안 연결을 유지합니다. | Switchboard |
| [규정 준수 프레임워크](../../subscriptions/gitlab_dedicated/_index.md#monitoring) | GitLab은 SOC 2, ISO 27001 및 기타 프레임워크에 대한 규정 준수를 유지합니다. [Trust Center](https://trust.gitlab.com/?product=gitlab-dedicated)를 통해 보고서에 액세스할 수 있습니다. | 기본적으로 <br>사용 가능 |
| [비상 액세스 프로토콜](../../subscriptions/gitlab_dedicated/_index.md#access-controls) | GitLab은 긴급한 상황에 대한 제어된 비상용 절차를 제공합니다. | 기본적으로 <br>사용 가능 |

## 네트워킹 설정 {#set-up-networking}

| 기능 | 설명 | 설정 방법 |
|------------|-------------|-----------------|
| [사용자 지정 도메인](configure_instance/network_security.md#custom-domains) | 도메인 이름을 제공하고 DNS 레코드를 구성합니다. GitLab은 Let's Encrypt를 통해 SSL 인증서를 관리합니다. | 지원 티켓 |
| [인바운드 PrivateLink 연결](configure_instance/network_security.md#inbound-privatelink-connections) | GitLab은 엔드포인트 서비스를 생성합니다. AWS 계정에서 VPC 엔드포인트를 생성하여 GitLab 인스턴스에 연결합니다. | Switchboard |
| [아웃바운드 PrivateLink 연결](configure_instance/network_security.md#outbound-privatelink-connections) | AWS 계정에서 엔드포인트 서비스를 생성합니다. GitLab은 서비스에 연결하기 위해 VPC 엔드포인트를 생성합니다. | Switchboard |
| [프라이빗 호스팅 영역](configure_instance/network_security.md#private-hosted-zones) | 내부 DNS 요구 사항을 정의합니다. GitLab은 인스턴스 네트워크에서 DNS 확인을 구성합니다. | Switchboard |

## 플랫폼 도구 사용 {#use-platform-tools}

| 기능 | 설명 | 설정 방법 |
|------------|-------------|-----------------|
| [GitLab Pages](../../subscriptions/gitlab_dedicated/_index.md#gitlab-pages) | GitLab은 전용 도메인에서 정적 웹사이트를 호스팅합니다. 리포지토리에서 사이트를 게시할 수 있습니다. | 기본적으로 <br>사용 가능 |
| [고급 검색](../../integration/advanced_search/elasticsearch.md) | GitLab은 검색 인프라를 유지합니다. 코드, 이슈 및 머지 리퀘스트를 검색할 수 있습니다. | 기본적으로 <br>사용 가능 |
| [호스팅된 러너 (베타)](hosted_runners.md) | 구독을 구매하고 호스팅된 러너를 구성합니다. GitLab은 자동 크기 조정 CI/CD 인프라를 관리합니다. | Switchboard |
| [ClickHouse](../../integration/clickhouse.md) | GitLab은 ClickHouse 인프라 및 통합을 유지합니다. [GitLab Duo 및 SDLC 동향](../../user/analytics/duo_and_sdlc_trends.md) 및 [CI/CD 분석](../../ci/runners/runner_fleet_dashboard.md)과 같은 모든 고급 분석 기능에 액세스할 수 있습니다. | 기본적으로 <br>[적격 고객](../../subscriptions/gitlab_dedicated/_index.md#clickhouse-cloud)을 위해 사용 가능 |

## 일일 운영 관리 {#manage-daily-operations}

| 기능 | 설명 | 설정 방법 |
|------------|-------------|-----------------|
| [애플리케이션 로그](monitor.md) | GitLab은 모니터링 및 문제 해결을 위해 AWS S3 버킷에 로그를 전달합니다. 로그에 액세스할 수 있는 사용자 및 역할을 관리합니다. | Switchboard |
| [이메일 서비스](configure_instance/users_notifications.md#smtp-email-service) | GitLab은 GitLab Dedicated 인스턴스에서 이메일을 보내기 위해 기본적으로 AWS SES를 제공합니다. 자신의 SMTP 이메일 서비스를 구성할 수도 있습니다. | 지원 티켓 (커스텀 <br/>서비스 필요)  |
| [Switchboard 액세스 및 <br>알림](configure_instance/users_notifications.md) | Switchboard 권한 및 알림 설정을 관리합니다. GitLab은 Switchboard 인프라를 유지합니다. | Switchboard |
| [Switchboard SSO](configure_instance/authentication/_index.md#configure-switchboard-sso) | 조직의 ID 공급자를 구성하고 필요한 세부 정보를 GitLab에 제공합니다. GitLab은 Switchboard에 대한 SSO(Single Sign-On)를 구성합니다. | 지원 티켓 |

## 시작하기 {#get-started}

GitLab Dedicated를 시작하려면:

1. [GitLab Dedicated 인스턴스 생성](create_instance/_index.md).
1. [GitLab Dedicated 인스턴스 구성](configure_instance/_index.md).
1. [호스팅된 러너 생성](hosted_runners.md).
