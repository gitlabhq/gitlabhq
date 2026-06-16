---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 외부 데이터베이스에 대한 모니터링 및 로깅 설정
---

외부 PostgreSQL 데이터베이스 시스템에는 성능 모니터링 및 문제 해결을 위한 다양한 로깅 옵션이 있지만, 기본적으로 활성화되지 않습니다. 이 섹션에서는 자체 관리 PostgreSQL에 대한 권장 사항과 PostgreSQL 관리형 서비스를 제공하는 주요 공급자에 대한 권장 사항을 제공합니다.

## 권장 PostgreSQL 로깅 설정 {#recommended-postgresql-logging-settings}

다음 로깅 설정을 활성화해야 합니다:

- `log_statement=ddl`: 데이터베이스 모델 정의(DDL)의 변경 사항을 로깅합니다. 예를 들어 객체의 `CREATE`, `ALTER` 또는 `DROP` 이를 통해 성능 문제를 일으킬 수 있는 최근 모델 변경 사항을 추적하고, 보안 위반 및 인적 오류를 파악할 수 있습니다.
- `log_lock_waits=on`: 장시간 [잠금](https://www.postgresql.org/docs/16/explicit-locking.html)을 유지하는 프로세스를 로깅합니다. 이는 쿼리 성능 저하의 일반적인 원인입니다.
- `log_temp_files=0`: 쿼리 성능 저하를 나타낼 수 있는 집약적이고 비정상적인 임시 파일의 사용 현황을 로깅합니다.
- `log_autovacuum_min_duration=0`: 모든 autovacuum 실행을 로깅합니다. Autovacuum은 전체 PostgreSQL 엔진 성능을 위한 핵심 구성 요소입니다. 데드 튜플이 테이블에서 제거되지 않는 경우 문제 해결 및 튜닝에 필수적입니다.
- `log_min_duration_statement=1000`: 느린 쿼리(1초보다 느린)를 로깅합니다.

이러한 매개 변수 설정에 대한 전체 설명은 [PostgreSQL 오류 보고 및 로깅 설명서](https://www.postgresql.org/docs/16/runtime-config-logging.html#RUNTIME-CONFIG-LOGGING-WHAT)에서 확인할 수 있습니다.

## Amazon RDS {#amazon-rds}

Amazon 관계형 데이터베이스 서비스(RDS)는 다양한 [모니터링 메트릭](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Monitoring.html) 과 [로깅 인터페이스](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Monitor_Logs_Events.html)를 제공합니다. 다음은 구성해야 할 몇 가지입니다:

- [권장 PostgreSQL 로깅 설정](#recommended-postgresql-logging-settings) 을 모두 [RDS 파라미터 그룹](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithDBInstanceParamGroups.html)을 통해 변경합니다.
  - 권장 로깅 매개 변수가 RDS에서 [동적](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.Parameters.html)이므로, 이러한 설정을 변경한 후 재부팅할 필요가 없습니다.
  - PostgreSQL 로그는 [RDS 콘솔](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/logs-events-streams-console.html)을 통해 확인할 수 있습니다.
- [RDS 성능 인사이트](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PerfInsights.html)를 활성화하면 데이터베이스 부하를 시각화하고 PostgreSQL 데이터베이스 엔진의 많은 중요한 성능 메트릭을 확인할 수 있습니다.
- [RDS Enhanced Monitoring](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Monitoring.OS.html)을 활성화하여 운영 체제 메트릭을 모니터링합니다. 이러한 메트릭은 데이터베이스 성능에 영향을 미치는 기본 하드웨어 및 OS의 병목 현상을 나타낼 수 있습니다.
  - 프로덕션 환경에서는 많은 성능 문제의 원인이 될 수 있는 리소스 사용량의 마이크로 버스트를 캡처하기 위해 모니터링 간격을 10초 이하로 설정합니다. 콘솔에서 `Granularity=10`을 설정하거나 CLI에서 `monitoring-interval=10`을 설정합니다.
