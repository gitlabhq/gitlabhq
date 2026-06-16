---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: Geo 조정
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

사이트에서 실행할 수 있는 동시 작업의 수를 제한할 수 있습니다.

## 동기화/검증 동시성 값 변경 {#changing-the-syncverification-concurrency-values}

**프라이머리** 사이트에서:

1. 우측 상단 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **Geo** > **사이트**를 선택합니다.
1. 조정할 보조 사이트의 **편집**을 선택합니다.
1. **설정 조정**에서 Geo의 성능을 개선하기 위해 조정할 수 있는 여러 변수가 있습니다:

   - 리포지토리 동기화 동시성 제한
   - 파일 동기화 동시성 제한
   - 컨테이너 리포지토리 동기화 동시성 제한
   - 검증 동시성 제한

동시성 값을 증가시키면 예약된 작업의 수가 증가합니다. 그러나 사용 가능한 Sidekiq 스레드의 수도 증가하지 않으면 더 많은 다운로드가 병렬로 진행되지 않을 수 있습니다. 예를 들어 리포지토리 동기화 동시성을 25에서 50으로 증가시킨 경우 Sidekiq 스레드의 수도 25에서 50으로 증가시킬 수 있습니다. [Sidekiq 동시성 설명서](../../sidekiq/extra_sidekiq_processes.md#concurrency)를 참조하여 자세한 내용을 확인하세요.

## 낮은 기본 설정 조정 {#tuning-low-default-settings}

새로운 Geo 사이트를 설정할 때 과도한 부하를 방지하기 위해 GitLab 18.0부터 Geo의 동시성 설정은 대부분의 환경에서 낮은 기본값으로 설정됩니다. 이러한 설정을 증가시키려면:

1. 우측 상단 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **Geo** > **사이트**를 선택합니다.
1. 진행 속도가 너무 느린 데이터 유형을 결정합니다.
1. 프라이머리 사이트와 보조 사이트의 부하 지표를 모니터링합니다.
1. 동시성 제한을 10씩 증가시켜 보수적으로 진행합니다.
1. 최소 3분 동안 진행 상황과 부하 지표의 변화를 모니터링합니다.
1. 부하 지표가 원하는 최댓값에 도달하거나 동기화 및 검증이 원하는 속도로 진행될 때까지 제한을 계속 증가시킵니다.

## 리포지토리 재검증 {#repository-re-verification}

[자동 백그라운드 검증](../disaster_recovery/background_verification.md)을 참조하세요.
