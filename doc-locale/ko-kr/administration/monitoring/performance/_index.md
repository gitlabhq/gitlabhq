---
stage: Shared responsibility based on functional area
group: Shared responsibility based on functional area
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: GitLab 성능 모니터링
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab 성능 모니터링을 통해 성능 병목 현상이 사용자에게 영향을 미치기 전에 감지합니다. 느린 응답 시간이나 메모리 문제가 발생할 때 SQL 쿼리, Ruby 처리 및 시스템 리소스에 대한 자세한 메트릭을 통해 정확한 원인을 파악합니다.

성능 모니터링을 구현하는 관리자는 잠재적 문제가 인스턴스 전역 이슈로 확대되기 전에 즉시 알림을 받습니다. 트랜잭션 시간, 쿼리 실행 성능 및 메모리 사용량을 추적하여 조직의 최적 GitLab 성능을 유지합니다.

GitLab 성능 모니터링을 구성하는 방법에 대한 자세한 내용은 다음을 참조하세요:

- [Prometheus 문서](../prometheus/_index.md).
- [Grafana 구성](grafana_configuration.md).
- [성능 표시줄](performance_bar.md).

두 가지 유형의 메트릭을 수집합니다:

1. 트랜잭션 특정 메트릭.
1. 샘플 메트릭.

## 트랜잭션 메트릭 {#transaction-metrics}

트랜잭션 메트릭은 단일 트랜잭션과 연결할 수 있는 메트릭입니다. 여기에는 트랜잭션 기간, 실행된 SQL 쿼리의 타이밍 및 HAML 뷰 렌더링에 소요된 시간과 같은 통계가 포함됩니다. 이러한 메트릭은 모든 Rack 요청 및 처리된 Sidekiq 작업에 대해 수집됩니다.

## 샘플 메트릭 {#sampled-metrics}

샘플 메트릭은 단일 트랜잭션과 연결할 수 없는 메트릭입니다. 예를 들어 가비지 컬렉션 통계 및 유지된 Ruby 객체가 포함됩니다. 이러한 메트릭은 정기적인 간격으로 수집됩니다. 이 간격은 두 부분으로 구성됩니다:

1. 사용자 정의 간격.
1. 간격 위에 추가된 무작위로 생성된 오프셋이며, 같은 오프셋을 연속해서 두 번 사용할 수 없습니다.

실제 간격은 정의된 간격의 절반부터 간격보다 절반 위까지 어디든 될 수 있습니다. 예를 들어 사용자 정의 간격이 15초인 경우 실제 간격은 7.5에서 22.5 사이의 어디든 될 수 있습니다. 간격은 프로세스의 수명 기간 동안 한 번 생성되어 재사용되는 대신 모든 샘플링 실행에 대해 다시 생성됩니다.

사용자 정의 간격은 환경 변수를 통해 지정할 수 있습니다. 다음 환경 변수는 인식됩니다:

- `RUBY_SAMPLER_INTERVAL_SECONDS`
- `DATABASE_SAMPLER_INTERVAL_SECONDS`
- `ACTION_CABLE_SAMPLER_INTERVAL_SECONDS`
- `PUMA_SAMPLER_INTERVAL_SECONDS`
- `THREADS_SAMPLER_INTERVAL_SECONDS`
- `GLOBAL_SEARCH_SAMPLER_INTERVAL_SECONDS`
