---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: 애플리케이션 성능을 모니터링하고 성능 문제를 해결합니다.
ignore_in_report: true
title: 통합관찰을 위한 CI/CD 파이프라인 원격 측정 표시
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 상태: 실험적 기능

{{< /details >}}

활성화되면 GitLab Observability이 CI/CD 파이프라인을 자동으로 계측하여 파이프라인 성능, 작업 기간 및 실행 흐름에 대한 가시성을 제공하며, 코드 변경이 필요하지 않습니다.

- 파이프라인을 느리게 하는 작업에 대한 가시성
- 시간 경과에 따른 파이프라인 성능 변화
- 배포 프로세스의 병목 현상

## 파이프라인 계측 활성화 {#enable-pipeline-instrumentation}

자동 파이프라인 계측을 활성화하려면 `GITLAB_OBSERVABILITY_EXPORT` CI/CD 변수를 프로젝트 또는 그룹에 추가합니다:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **변수**를 확장합니다.
1. **변수 추가**를 선택합니다.
1. 변수를 구성합니다:
   - **키**: `GITLAB_OBSERVABILITY_EXPORT`
   - **Value (값)**: `traces`, `metrics`, `logs` 중 하나 이상 (여러 값의 경우 쉼표로 구분)
   - **유형**: 변수
   - **환경 범위**: 모두 (또는 특정 환경)
1. **변수 추가**를 선택합니다.

## 계측 유형 {#instrumentation-types}

`GITLAB_OBSERVABILITY_EXPORT` 변수는 다음 값을 허용합니다:

- `traces`: 실행 흐름, 작업 종속성 및 시간을 보여주는 분산 추적을 내보냅니다.
- `metrics`: 파이프라인 기간, 작업 성공률 및 리소스 사용량에 대한 메트릭을 내보냅니다.
- `logs`: 파이프라인 실행의 구조화된 로그를 내보냅니다.

쉼표로 구분하여 여러 유형을 활성화할 수 있습니다:

```plaintext
traces,metrics,logs
```

## 작동 방식 {#how-it-works}

변수가 설정되면 GitLab이 자동으로 다음을 수행합니다:

1. 각 파이프라인이 완료된 후 파이프라인 실행 데이터를 캡처합니다.
1. 데이터를 구성에 따라 OpenTelemetry 형식으로 변환합니다.
1. 원격 측정 데이터를 GitLab Observability 인스턴스로 내보냅니다.
1. 데이터를 관찰성 대시보드에서 사용 가능하게 만듭니다.

`.gitlab-ci.yml` 파일을 변경할 필요가 없습니다. 계측은 백그라운드에서 자동으로 수행됩니다.

## 파이프라인 원격 측정 보기 {#view-pipeline-telemetry}

계측이 활성화된 상태로 파이프라인을 실행한 후:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **통합관찰** > **서비스**를 선택합니다.
1. `gitlab-ci` 서비스를 선택하여 파이프라인 실행에서 추적, 메트릭 및 로그를 확인합니다.

[GitLab Observability 템플릿](https://gitlab.com/gitlab-org/embody-team/experimental-observability/o11y-templates/)의 CI/CD 대시보드 템플릿은 파이프라인 성능 분석을 위한 미리 작성된 시각화를 제공합니다.

## 관련 항목 {#related-topics}

- [통합관찰 문제 해결](troubleshooting.md)
