---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: 애플리케이션 성능을 모니터링하고 성능 문제를 해결합니다.
ignore_in_report: true
title: 통합관찰
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 상태: 실험적 기능

{{< /details >}}

{{< history >}}

- [GitLab 18.1](https://gitlab.com/gitlab-org/embody-team/experimental-observability/documentation/-/work_items/6)에서 모든 사용자가 사용 가능한 실험으로 도입되었습니다.

{{< /history >}}

GitLab 관찰성은 분산 추적, 메트릭 및 로그를 모두 하나의 플랫폼에서 제공합니다. 카디널리티 제한이 없습니다. 팀이 배워야 할 별도의 도구가 없습니다.

GitLab 관찰성을 사용하여:

- 마이크로서비스 전반에 걸친 분산 추적을 통해 애플리케이션 성능을 모니터링합니다.
- 코드 변경을 프로덕션 이슈와 연관시킵니다.
- CI/CD 파이프라인을 코드 변경 없이 자동으로 계측합니다.
- OpenTelemetry 표준을 사용하여 높은 카디널리티 메트릭을 제한 없이 전송합니다.

GitLab 관찰성은 적극적으로 진화하고 있는 실험 기능입니다. 지금 바로 추적, 로그 및 메트릭을 전송할 수 있습니다. 워크플로에 익숙해지려면 먼저 중요하지 않은 서비스에서 시도한 후 필요에 따라 사용을 확대합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 자세한 개요를 보려면 [GitLab 관찰성(O11y) 소개](https://www.youtube.com/watch?v=XI9ZruyNEgs)를 참조하세요.
<!-- Video published on 2025-06-18 -->

GitLab 관찰성은 모든 티어에서 사용 가능하며 무료입니다. [피드백 공유 또는 기능 요청](#share-your-feedback)

## 시작하기 {#get-started}

1. [GitLab Self-Managed 인스턴스](setup_self_managed.md)에서 또는 [GitLab.com](setup_gitlab_com.md)에서 관찰성을 설정합니다.
1. OTLP 엔드포인트를 추가하여 [원격 분석 전송을 시작](send.md)하거나 [CI/CD 파이프라인 원격 분석을 봅니다](ci_cd.md).
1. 첫 번째 추적을 봅니다.
1. 느린 요청을 디버깅합니다.
1. [API에 액세스](api_access.md)하여 프로그래밍 방식으로 데이터를 쿼리합니다.

<div class="video-fallback">
  보기: <a href="https://www.youtube.com/watch?v=lZtgor6chMs">GitLab 관찰성 설정</a>
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/lZtgor6chMs" frameborder="0" allowfullscreen> </iframe>
</figure>
<!-- Video published on 2026-05-04 -->

## 실제 사용 사례 {#real-world-usage}

GitLab 관찰성은 전 세계 팀에서 애플리케이션 및 인프라를 모니터링하는 데 사용되고 있습니다.

<!-- TODO: Add usage demonstration video showing real debugging workflow
<i class="fa-youtube-play" aria-hidden="true"></i>
For a usage demonstration, see [How to Debug Production Issues with GitLab Observability](VIDEO_URL).
-->

사용자는 GitLab.com의 GitLab 관찰성으로 시스템을 적극적으로 모니터링하고 있습니다(2026년 4월 21일 주 기준):

- 일일 처리되는 추적은 5,700만 개 이상입니다.
- 적극적으로 모니터링되는 서비스는 3,000개 이상입니다.

## 주요 기능 {#key-features}

### 성능 모니터링, 이슈 추적 {#monitor-performance-trace-issues}

이슈를 더 빠르게 찾아 디버깅합니다.

- 향상된 개발 워크플로입니다. 코드 변경을 애플리케이션 성능 메트릭과 직접 연관시켜 배포가 이슈를 야기하는 시점을 파악합니다.
- 간소화된 인시던트 대응입니다. 한 곳에서 최근 배포, 코드 변경 및 관련 개발자를 봅니다.

이슈가 발생했을 때 다음을 봅니다:

- 느린 쿼리를 보여주는 성능 추적입니다.
- 변경 사항을 도입한 머지 리퀘스트입니다.
- 이를 수정할 수 있는 개발자입니다.
- 이를 배포한 배포입니다.

### 통합 플랫폼 {#unified-platform}

다음을 결합하는 통합 대시보드를 통해 애플리케이션 성능을 모니터링합니다:

- 분산 추적입니다. 마이크로서비스 전반의 요청을 따라 병목 지점을 파악합니다.
- 메트릭입니다. 시간이 지남에 따라 애플리케이션 및 인프라 성능을 추적합니다.
- 로그입니다. 로그 항목을 추적 및 메트릭과 연관시켜 완전한 컨텍스트를 제공합니다.

중앙 집중식 관리는 다음을 제공합니다:

- 간소화된 액세스 관리입니다. 새로운 엔지니어는 코드 리포지토리 액세스 권한을 받을 때 프로덕션 관찰성 데이터에 대한 액세스를 자동으로 얻습니다.
- 컨텍스트 전환이 없습니다. GitLab을 떠나지 않고 모니터링 데이터에 액세스합니다.

### 개발자 친화적 통합 {#developer-friendly-integration}

GitLab 관찰성을 평가하는 동안 동일한 OpenTelemetry 데이터를 여러 백엔드로 전송합니다.

- Datadog 또는 New Relic에서 마이그레이션합니다. OpenTelemetry를 사용 중인 경우 OTLP 엔드포인트를 변경하기만 하면 됩니다.
- 공급업체 종속성이 없습니다. 표준 OpenTelemetry 계측 라이브러리를 사용합니다. OTLP 엔드포인트를 변경하여 언제든지 제공자를 전환합니다.

### 빠른 설정 및 계측 {#fast-setup-and-instrumentation}

대부분의 팀은 기능을 활성화한 후 5~10분 내에 첫 번째 추적을 볼 수 있습니다.

- 미리 작성된 대시보드입니다. 일반적인 사용 사례에 대한 템플릿으로 시작합니다.
- 자동 CI/CD 계측입니다. 하나의 환경 변수를 설정하면 GitLab이 CI/CD 파이프라인을 자동으로 계측합니다.

### 비용 효과적이고 확장 가능 {#cost-effective-and-scalable}

- 모든 티어에서 무료입니다. 사용자당, 메트릭당 또는 호스트당 요금이 없습니다. 추적, 메트릭 또는 로그에 대한 제한이 없습니다.
- 카디널리티 제한이 없습니다. 비용 우려 없이 높은 카디널리티 메트릭을 전송합니다.
- 오픈 소스 모델입니다. 기능 및 수정 사항을 직접 제공합니다.
- 예측 가능한 비용입니다. 메트릭 폭증으로 인한 예기치 않은 청구 없습니다.

### 규정 준수 및 감사 추적 {#compliance-and-audit-trails}

통합은 코드 변경과 시스템 동작을 연결하는 포괄적인 감사 추적을 생성하며, 이는 규정 준수 요구 사항 및 사후 인시던트 분석에 유용합니다.

## 자세히 알아보기 {#learn-more}

- [관찰성 API에 액세스](api_access.md)합니다. 프로그래밍 방식으로 추적, 메트릭 및 로그를 쿼리합니다.
- [OpenTelemetry 설명서](https://opentelemetry.io/docs/instrumentation/)입니다. 언어별 계측 가이드입니다.
- [GitLab 관찰성 템플릿](https://gitlab.com/gitlab-org/embody-team/experimental-observability/o11y-templates/)입니다. 미리 작성된 대시보드 및 예제입니다.
- [제안된 기능](https://gitlab.com/gitlab-org/embody-team/experimental-observability/gitlab_o11y/-/issues/8)

## 도움말 받기 {#get-help}

- [Discord 커뮤니티](https://discord.com/channels/778180511088640070/1379585187909861546)입니다. 다른 사용자와의 대화에 참여합니다.
- [GitLab 이슈](https://gitlab.com/gitlab-org/embody-team/experimental-observability/gitlab_o11y/-/issues)입니다. 버그를 보고하거나 기능을 요청합니다.
- [문제 해결 정보](troubleshooting.md)입니다.

## 피드백 공유 {#share-your-feedback}

GitLab 관찰성은 사용자 피드백에 따라 개선됩니다. 피드백을 제공하려면:

- [Discord 채널](https://discord.com/channels/778180511088640070/1379585187909861546)에 참여합니다.
- [이슈를 열어](https://gitlab.com/gitlab-org/embody-team/experimental-observability/gitlab_o11y/-/issues) 버그를 보고하거나 기능을 요청합니다.
