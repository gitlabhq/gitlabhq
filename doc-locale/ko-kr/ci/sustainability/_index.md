---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 지속 가능성 도구를 사용하여 CI/CD 파이프라인의 탄소 발자국을 측정하고 줄입니다.
title: 파이프라인 지속 가능성
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> 이 페이지에 설명된 지속 가능성 도구는 타사 통합입니다. GitLab은 이러한 도구를 유지하거나 지원하지 않으며, 이러한 도구가 규제 또는 규정 준수 요구 사항을 충족한다는 표시를 하지 않습니다.

CI/CD 파이프라인은 탄소 배출을 생성하는 계산 리소스를 소비합니다. 타사 도구를 통합하여 소프트웨어 개발 워크플로우에서 Scope 3 배출을 측정 및 줄이고 지속 가능성 보고 및 규제 준수를 수행할 수 있습니다.

Scope 3 배출은 CI/CD 파이프라인을 실행하는 클라우드 인프라를 포함한 공급망 및 공급업체의 간접 배출입니다.

지속 가능성 도구를 파이프라인에 통합하면 다음과 같은 이점을 제공합니다:

- CI/CD 인프라에서 탄소 배출을 추적 및 보고합니다.
- 리소스 집약적인 작업과 최적화 기회를 파악합니다.
- 러너 선택 및 작업 스케줄링에 관한 데이터 기반 결정을 내립니다.
- 지속 가능성 목표 및 규제 요구 사항을 충족합니다.

## 배출량 측정 {#emission-measurement}

CI/CD 파이프라인 배출은 작업 실행에 사용되는 계산 리소스에서 나옵니다. 탄소 발자국은 CPU 사용률, 메모리 사용량 및 실행 시간의 에너지 소비에 따라 달라집니다. 전기 1단위당 탄소 배출을 나타내며 지역 및 시간에 따라 변하는 탄소 강도에 따라서도 달라집니다. 클라우드 제공자, 데이터 센터 위치 및 하드웨어 효율성과 같은 인프라 요소도 전체 영향에 기여합니다.

지속 가능성 도구는 배출량을 계산하기 위해 다양한 접근 방식을 사용합니다:

- 추정 모델은 CPU 사용 패턴 및 사전 계산된 전력 곡선을 기반으로 에너지 소비를 계산합니다.
- 실제 측정은 클라우드 제공자 API를 사용하여 실제 리소스 소비 데이터를 검색합니다.
- 탄소 강도 조회는 [Electricity Maps](https://app.electricitymaps.com/dashboard)와 같은 서비스를 쿼리하여 지역별 탄소 계수 및 시간 기반 변동을 적용합니다.

## Eco CI를 사용한 배출량 측정 {#measure-emissions-with-eco-ci}

Eco CI는 CI/CD 파이프라인의 에너지 소비 및 탄소 배출을 측정합니다. 파이프라인 작업 내에서 경량 bash 스크립트로 실행되며 별도의 서버나 데이터베이스가 필요하지 않습니다.

자세한 내용은 [Eco CI](eco_ci.md)를 참조하세요.

## 모범 사례 {#best-practices}

CI/CD 파이프라인의 탄소 발자국을 줄이기 위한 다음 전략을 고려합니다.

### 작업 실행 최적화 {#optimize-job-execution}

작업 실행을 최적화하려면:

- 캐싱을 사용하여 중복 작업을 피합니다.
- 여러 작업의 시작 부분에서 리소스 집약적인 빌드를 수행하는 대신 초기 작업에서 빌드를 한 번 실행합니다. 그런 다음 출력을 필요로 하는 모든 이후 작업과 아티팩트로 공유합니다.
- 폭주 작업을 방지하기 위해 적절한 제한 시간 값을 설정합니다.
- 더 작은 Docker 이미지를 사용하여 다운로드 및 시작 시간을 줄입니다.

### 효율적인 러너 선택 {#choose-efficient-runners}

효율적인 러너를 선택하려면:

- 워크로드 요구 사항과 일치하는 러너 인스턴스 유형을 선택합니다.
- 간단한 작업을 위해 리소스를 과도하게 프로비저닝하지 않습니다.
- 중요하지 않은 워크로드에 스팟 인스턴스 사용을 고려합니다.
- 자동 크기 조정을 사용하여 용량을 수요와 일치시킵니다.

### 전략적으로 스케줄링 {#schedule-strategically}

전략적으로 스케줄링하려면:

- CI 서버 지역에서 대부분의 재생 에너지를 사용할 수 있을 때 리소스 집약적인 파이프라인을 실행하도록 스케줄링합니다. [Electricity Maps](https://app.electricitymaps.com/map/live/hourly)를 확인하여 최적의 시간과 지역을 찾습니다. 정오는 보통 좋은 기본 선택입니다.
- 긴급하지 않은 파이프라인에 대해 탄소 인식 스케줄링을 고려합니다.
- 유사한 작업을 함께 일괄 처리하여 리소스 사용률을 개선합니다.

### 모니터링 및 반복 {#monitor-and-iterate}

지속 가능성 노력에 대해 모니터링하고 반복하려면:

- 파이프라인에 대한 기준 메트릭을 설정합니다.
- 배출 감소 목표를 설정합니다.
- 최적화 기회에 대해 정기적으로 영향도 높은 작업을 검토합니다.
- 팀과 지속 가능성 메트릭을 공유합니다.

## 관련 항목 {#related-topics}

- [파이프라인 효율성](../pipelines/pipeline_efficiency.md)
- [종속성 캐싱](../caching/_index.md)
- [예약된 파이프라인](../pipelines/schedules.md)
