---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: PostgreSQL을 스케일링하도록 구성
description: PostgreSQL을 스케일링하도록 구성합니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

이 섹션에서는 GitLab에서 [참조 아키텍처](../reference_architectures/_index.md) 중 하나와 함께 사용할 PostgreSQL 데이터베이스를 구성하는 방법을 안내합니다.

## 구성 옵션 {#configuration-options}

다음 PostgreSQL 구성 옵션 중 하나를 선택합니다:

### Linux 패키지 설치를 위한 독립 실행형 PostgreSQL {#standalone-postgresql-for-linux-package-installations}

이 설정은 [Linux 패키지](https://about.gitlab.com/install/)(CE 또는 EE)를 사용하여 GitLab을 설치하고 번들된 PostgreSQL의 서비스만 활성화하려는 경우에 적용됩니다.

[독립 실행형 PostgreSQL 인스턴스 설정](standalone.md)하는 방법(Linux 패키지 설치용)을 읽으세요.

### 자신의 PostgreSQL 인스턴스 제공 {#provide-your-own-postgresql-instance}

이 설정은 [Linux 패키지](https://about.gitlab.com/install/) (CE 또는 EE)를 사용하여 GitLab을 설치했거나 [직접 컴파일](../../install/self_compiled/_index.md)하여 설치했지만 자신의 외부 PostgreSQL 서버를 사용하려는 경우에 적용됩니다.

[외부 PostgreSQL 인스턴스 설정](external.md)하는 방법을 읽으세요.

외부 데이터베이스를 설정할 때 모니터링 및 문제 해결에 유용한 메트릭이 있습니다. 외부 데이터베이스를 설정할 때 다양한 데이터베이스 관련 문제를 해결하기 위해 필요한 모니터링 및 로깅 설정이 있습니다. [외부 데이터베이스를 위한 모니터링 및 로깅 설정](external_metrics.md)에 대해 자세히 읽으세요.

### Linux 패키지 설치를 위한 PostgreSQL 복제 및 장애 조치 {#postgresql-replication-and-failover-for-linux-package-installations}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

이 설정은 [Linux **Enterprise Edition**(EE) 패키지](https://about.gitlab.com/install/?version=ee)를 사용하여 GitLab을 설치한 경우에 적용됩니다.

PostgreSQL, PgBouncer, Patroni와 같이 필요한 모든 도구가 패키지에 번들되어 있으므로 전체 PostgreSQL 인프라(기본, 복제본)를 설정하는 데 사용할 수 있습니다.

[PostgreSQL 복제 및 장애 조치 설정](replication_and_failover.md)하는 방법(Linux 패키지 설치용)을 읽으세요.

## 관련 항목 {#related-topics}

- [PostgreSQL 확장 관리](extensions.md)
- [번들된 PgBouncer 서비스 작업](pgbouncer.md)
- [데이터베이스 로드 밸런싱](database_load_balancing.md)
- [GitLab 데이터베이스를 다른 PostgreSQL 인스턴스로 이동하기](moving.md)
- GitLab 개발용 데이터베이스 가이드
- [외부 데이터베이스 업그레이드](external_upgrade.md)
- [PostgreSQL용 운영 체제 업그레이드](upgrading_os.md)
