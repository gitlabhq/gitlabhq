---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: 인스턴스가 허용하는 단일 웹후크 이벤트 수에 대한 제한을 구성합니다.
title: 웹후크 이벤트 활동 제한 및 대량 웹후크 이벤트
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

좋은 시스템 성능을 유지하고 활동 피드에서 스팸을 방지하려면 **Push event activities limit**을(를) 설정합니다. 기본적으로 GitLab은 이 제한을 `3`로 설정합니다. 3개 이상의 브랜치와 태그에 영향을 미치는 변경 사항을 푸시하면 GitLab은 개별 푸시 이벤트 대신 대량 푸시 이벤트를 생성합니다.

예를 들어 4개의 브랜치에 동시에 푸시하면 활동 피드에 4개의 별도 푸시 이벤트 대신 {{< icon name="commit" >}} `Pushed to 4 branches at (project name)` 이벤트 1개가 표시됩니다.

대량 푸시 이벤트는 표준 푸시 이벤트와 다르게 작동합니다:

- 활동 피드:  개별 푸시 이벤트 대신 단일 대량 푸시 항목이 나타납니다.
- 이벤트 API:  `commit_count: 0` 및 푸시된 참조의 수를 보여주는 `ref_count`와 함께 대량 푸시 이벤트를 반환합니다. 개별 커밋 세부 정보(`commit_from`, `commit_to`, `ref`, `commit_title`)는 `null`입니다.

통합 또는 외부 시스템이 푸시된 각 참조를 개별적으로 처리해야 하는 경우:

- 푸시당 참조 수를 `push_event_activities_limit` 아래로 유지합니다.
- 큰 푸시를 여러 개의 작은 푸시로 분할합니다.

> [!note]
> 웹후크 트리거링은 `push_event_hooks_limit` 설정으로 별도로 제어됩니다. 자세한 내용은 [push event limits](../../user/project/integrations/webhooks.md#push-event-limits)를 참조하세요.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

다른 **Push event activities limit**을(를) 설정하려면 다음 중 하나를 선택합니다:

- [application settings API](../../api/settings.md#available-settings)에서 `push_event_activities_limit`을(를) 설정합니다.

- GitLab UI에서:
  1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
  1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
  1. **성능 최적화**를 확장합니다.
  1. **Push event activities limit** 설정을 편집합니다.
  1. **변경 사항 저장**을 선택합니다.

값은 `0` 이상이어야 합니다. 이 값을 `0`로 설정하면 제한이 비활성화되지 않습니다.
