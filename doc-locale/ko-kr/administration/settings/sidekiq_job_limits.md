---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sidekiq 작업 크기 제한
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

[Sidekiq](../sidekiq/_index.md) 작업을 Redis에 저장합니다. Redis의 과도한 메모리 사용을 피하기 위해 다음을 수행합니다:

- Redis에 저장하기 전에 작업 인자를 압축합니다.
- 압축 후 지정된 임계값 제한을 초과하는 작업을 거부합니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

Sidekiq 작업 크기 제한에 액세스하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **Sidekiq 작업 크기 제한**을 확장합니다.
1. 압축 임계값 또는 크기 제한을 조정합니다. **Track** 모드를 선택하여 압축을 비활성화할 수 있습니다.

## 사용 가능한 설정 {#available-settings}

| 설정                                   | 기본값          | 설명                                                                                                                                                                   |
|-------------------------------------------|------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 제한 모드                             | 압축         | 이 모드는 지정된 임계값에서 작업을 압축하고 압축 후 지정된 제한을 초과하는 경우 거부합니다.                                               |
| Sidekiq 작업 압축 임계값(바이트) | 100,000(100KB) | 인자의 크기가 이 임계값을 초과하면 Redis에 저장되기 전에 압축됩니다.                                                                          |
| Sidekiq 작업 크기 제한(바이트)            | 0                | 압축 후 이 크기를 초과하는 작업은 거부됩니다. 이는 Redis의 과도한 메모리 사용으로 인한 불안정성을 방지합니다. 이 값을 0으로 설정하면 작업 거부를 방지합니다.     |

이 값들을 변경한 후 [Sidekiq 다시 시작](../restart_gitlab.md)합니다.
