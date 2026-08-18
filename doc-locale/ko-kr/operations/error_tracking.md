---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 오류 추적
description: "오류 추적, 로깅, 디버깅 및 데이터 보존입니다."
---

오류 추적은 개발자가 애플리케이션에서 생성되는 오류를 발견하고 볼 수 있도록 도움을 줍니다. 오류 정보가 코드가 개발되는 위치에서 표시되므로 오류 추적은 효율성과 인식을 높입니다. 사용자는 [GitLab 통합 오류 추적](integrated_error_tracking.md)과 [Sentry 기반](sentry_error_tracking.md) 백엔드 중에서 선택할 수 있습니다.

## 전제 조건 {#prerequisites}

오류 추적이 작동하려면 다음이 필요합니다:

- **Your application configured with the Sentry SDK**: 오류가 발생하면 Sentry SDK는 오류에 대한 정보를 캡처하고 네트워크를 통해 백엔드로 전송합니다. 백엔드는 모든 오류에 대한 정보를 저장합니다.
- **오류 추적 백엔드**: 백엔드는 GitLab 자체이거나 Sentry일 수 있습니다.
  - GitLab 백엔드를 사용하려면 [GitLab 통합 오류 추적](integrated_error_tracking.md)을 참조하세요. 통합 오류 추적은 GitLab.com에서만 사용할 수 있습니다.
  - Sentry를 백엔드로 사용하려면 [Sentry 오류 추적](sentry_error_tracking.md)을 참조하세요. Sentry 기반 오류 추적은 GitLab.com, GitLab Dedicated, GitLab Self-Managed에서 사용할 수 있습니다.

## 오류 추적 작동 방식 {#how-error-tracking-works}

다음 표는 각 GitLab 제공 서비스의 기능에 대한 개요를 제공합니다:

| 기능 | 사용 가능성 | 데이터 수집 | 데이터 저장소 | 데이터 조회 |
| ----------- | ----------- | ----------- | ----------- | ----------- |
| [GitLab 통합 오류 추적](integrated_error_tracking.md) | GitLab.com | [Sentry SDK](https://github.com/getsentry/sentry?tab=readme-ov-file#official-sentry-sdks)와 함께 | GitLab.com에서 | GitLab.com과 함께 |
| [Sentry 기반 오류 추적](sentry_error_tracking.md) | GitLab.com, GitLab Dedicated, GitLab Self-Managed | [Sentry SDK](https://github.com/getsentry/sentry?tab=readme-ov-file#official-sentry-sdks)와 함께 | Sentry 인스턴스(Cloud Sentry.io 또는 [자체 호스팅 Sentry](https://develop.sentry.dev/self-hosted/))에서 | GitLab.com 또는 Sentry 인스턴스와 함께 |
