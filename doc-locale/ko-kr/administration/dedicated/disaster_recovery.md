---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab Dedicated 인스턴스의 복구 목표, 페일오버 프로세스 및 지역별 백업 전략."
title: GitLab Dedicated를 위한 재해 복구
---

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab Dedicated

{{< /details >}}

GitLab Dedicated는 주 지역을 사용할 수 없게 되었을 때 인스턴스를 복구하기 위한 자동 재해 복구를 제공합니다. 전체 복구 목표를 충족하려면 다음이 필요합니다:

- [인스턴스를 생성](create_instance/_index.md)할 때 주 지역과 보조 지역을 구성합니다.
- [GitLab Dedicated에서 지원하는](create_instance/data_residency_high_availability.md#supported-regions) 지역을 선택합니다.

보조 지역이 구성되지 않은 경우 복구는 백업 복구로만 제한됩니다.

## 복구 목표 {#recovery-objectives}

GitLab Dedicated는 다음 복구 목표를 포함한 재해 복구를 제공합니다:

- 복구 시간 목표(RTO):  서비스가 8시간 이내에 보조 지역으로 복구됩니다.
- 복구 지점 목표(RPO):  데이터 손실은 최근 변경 사항의 최대 4시간으로 제한되며, 재해가 마지막 백업을 기준으로 발생한 시점에 따라 달라집니다.

## Geo 복제 {#geo-replication}

인스턴스를 생성할 때 환경의 주 지역과 보조 지역을 선택합니다. Geo는 다음을 포함하여 이러한 지역 간에 데이터를 지속적으로 복제합니다:

- 데이터베이스 내용
- 리포지토리 스토리지
- 오브젝트 스토리지

## 자동 백업 {#automated-backups}

GitLab은 스냅샷을 생성하여 모든 GitLab Dedicated 데이터 저장소(데이터베이스 및 Git 리포지토리 포함)의 자동 백업을 4시간마다(하루에 6회) 수행합니다.

백업은 테스트되고 30일 동안 보관되며 선택한 보조 지역에 저장됩니다. 추가 보호를 위해 AWS에 의해 지리적으로 복제됩니다.

데이터베이스 백업:

- 특정 시점의 복구를 위해 주 지역에서 지속적인 로그 기반 백업을 사용합니다.
- 거의 실시간에 가까운 복사본을 제공하기 위해 보조 지역으로 스트림 복제를 수행합니다.

오브젝트 스토리지 백업은 지리적 복제 및 버전 관리를 사용하여 백업 보호를 제공합니다.

4시간 백업 빈도는 RPO(복구 지점 목표)를 지원하여 4시간 이상의 데이터 손실이 없도록 합니다.

## 재해 커버 {#disaster-coverage}

재해 복구는 보장된 복구 목표를 포함한 이러한 시나리오를 포함합니다:

- 부분 지역 정전(예: 가용성 영역 장애)
- 주 지역의 완전한 정전

이러한 시나리오는 보장되지 않은 복구 목표 없이 최선의 노력 기반으로 처리됩니다:

- 주 지역과 보조 지역 모두 손실
- 글로벌 인터넷 정전
- 데이터 손상 이슈

## 서비스 제한 {#service-limitations}

재해 복구에는 다음과 같은 서비스 제한이 있습니다:

- 고급 검색 인덱스는 지속적으로 복제되지 않습니다. 페일오버 후 보조 지역이 승격될 때 이러한 인덱스가 다시 생성됩니다. 기본 검색은 재구성 중에도 사용 가능합니다.
- ClickHouse Cloud는 주 지역에만 프로비저닝됩니다. 이 서비스가 필요한 기능은 주 지역이 완전히 다운된 경우 사용할 수 없습니다.
- 프로덕션 미리보기 환경에는 보조 인스턴스가 없습니다.
- 호스팅 러너는 주 지역에서만 지원되며 보조 인스턴스에서는 재구성할 수 없습니다.
- 일부 지역은 AWS 서비스 제약 조건으로 인해 기능 가용성이 제한됩니다. 자세한 내용은 [지원되는 지역](create_instance/data_residency_high_availability.md#supported-regions)을 참조하세요. 이러한 기능 제한은 재해 복구 기능 또는 RTO 및 RPO 대상에 영향을 주지 않습니다.

GitLab은 다음을 제공하지 않습니다:

- 페일오버 이벤트의 프로그래밍 방식 모니터링
- 고객이 시작한 재해 복구 테스트

## 페일오버 프로세스 {#failover-process}

완전한 지역 장애 또는 빠르게 복구할 수 없는 중요한 구성 요소 장애로 인해 인스턴스를 사용할 수 없게 되면 GitLab Dedicated 팀은:

1. 모니터링 시스템에 의해 경고를 받습니다.
1. 페일오버가 필요한지 조사합니다.
1. 페일오버가 필요한 경우:
   1. 페일오버가 진행 중임을 알립니다.
   1. 보조 지역을 주 지역으로 승격합니다.
   1. `<customer>.gitlab-dedicated.com`에 대한 DNS 레코드를 업데이트하여 새로 승격된 지역을 가리킵니다.
   1. 페일오버가 완료될 때 알립니다.

PrivateLink를 사용하는 경우 보조 지역의 PrivateLink 엔드포인트를 대상으로 하도록 내부 네트워킹 구성을 업데이트해야 합니다. 다운타임을 최소화하려면 재해가 발생하기 전에 보조 지역에 동등한 PrivateLink 엔드포인트를 구성합니다.

페일오버 프로세스는 일반적으로 90분 이내에 완료됩니다. 프로세스 전반에 걸쳐 GitLab은 다음 중 하나 이상을 통해 사용자와 통신합니다:

- Switchboard의 운영 담당자 연락처 정보
- Slack
- 지원 티켓

GitLab은 복구 프로세스 전반에 걸쳐 팀과 조정하기 위해 임시 Slack 채널과 Zoom 브리지를 설정할 수 있습니다.

## 관련 항목 {#related-topics}

- [데이터 거주지와 고가용성](create_instance/data_residency_high_availability.md)
- [GitLab Dedicated 아키텍처](architecture.md)
