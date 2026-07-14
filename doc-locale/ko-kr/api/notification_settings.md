---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 알림 설정 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 GitLab에서 알림 설정을 관리합니다. 자세한 내용은 [알림 이메일](../user/profile/notifications.md)을 참조하세요.

## 알림 수준 {#notification-levels}

알림 수준은 `NotificationSetting.level` 모델 열거형에 정의됩니다. 인식되는 수준은 다음과 같습니다:

- `disabled`:  모든 알림을 끕니다
- `participating`:  참여한 스레드의 알림을 수신합니다
- `watch`:  대부분의 활동에 대한 알림을 수신합니다
- `global`:  전역 알림 설정을 사용합니다
- `mention`:  댓글에서 언급될 때 알림을 수신합니다
- `custom`:  선택한 이벤트에 대한 알림을 수신합니다

`custom` 수준을 사용하면 특정 이메일 이벤트를 제어할 수 있습니다. 사용 가능한 이벤트는 `NotificationSetting.email_events`에 의해 반환됩니다. 인식되는 이벤트는 다음과 같습니다:

| 이벤트                          | 설명 |
| ------------------------------ | ----------- |
| `approver`                     | 승인할 수 있는 머지 리퀘스트를 만들었습니다 |
| `change_reviewer_merge_request`| 머지 리퀘스트의 검토자가 변경되었을 때 |
| `close_issue`                  | 이슈가 종료되었을 때 |
| `close_merge_request`          | 머지 리퀘스트가 종료되었을 때 |
| `failed_pipeline`              | 파이프라인이 실패했을 때 |
| `fixed_pipeline`               | 이전에 실패한 파이프라인이 수정되었을 때 |
| `issue_due`                    | 이슈가 내일 만료될 때 |
| `merge_merge_request`          | 머지 리퀘스트가 병합되었을 때 |
| `merge_when_pipeline_succeeds` | 머지 리퀘스트가 자동 병합으로 설정되었을 때 |
| `moved_project`                | 프로젝트가 이동되었을 때 |
| `new_epic`                     | 새 에픽이 생성되었을 때(Premium 및 Ultimate 티어에서) |
| `new_issue`                    | 새 이슈가 생성되었을 때 |
| `new_merge_request`            | 새 머지 리퀘스트가 생성되었을 때 |
| `new_note`                     | 누군가 댓글을 추가했을 때 |
| `new_release`                  | 새 릴리스가 게시되었을 때 |
| `push_to_merge_request`        | 누군가 머지 리퀘스트에 푸시했을 때 |
| `reassign_issue`               | 이슈가 재할당되었을 때 |
| `reassign_merge_request`       | 머지 리퀘스트가 재할당되었을 때 |
| `reopen_issue`                 | 이슈가 다시 열렸을 때 |
| `reopen_merge_request`         | 머지 리퀘스트가 다시 열렸을 때 |
| `success_pipeline`             | 파이프라인이 성공적으로 완료되었을 때 |

## 전역 알림 설정 검색 {#retrieve-global-notification-settings}

전역 알림 수준 및 이메일 주소를 검색합니다.

```plaintext
GET /notification_settings
```

예제 요청:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/notification_settings"
```

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)을 반환하고 다음 응답 속성이 표시됩니다:

| 속성            | 유형   | 설명 |
| -------------------- | ------ | ----------- |
| `level`              | 문자열 | 전역 알림 수준 |
| `notification_email` | 문자열 | 알림을 보내는 이메일 주소 |

응답 예시:

```json
{
  "level": "participating",
  "notification_email": "admin@example.com"
}
```

## 전역 알림 설정 업데이트 {#update-global-notification-settings}

알림 설정 및 이메일 주소를 업데이트합니다.

```plaintext
PUT /notification_settings
```

예제 요청:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/notification_settings?level=watch"
```

지원되는 속성:

| 속성                      | 유형    | 필수 | 설명 |
| ------------------------------ | ------- | -------- | ----------- |
| `approver`                     | 부울 | 아니요       | 승인할 수 있는 머지 리퀘스트를 생성할 때 알림을 켭니다 |
| `change_reviewer_merge_request`| 부울 | 아니요       | 머지 리퀘스트의 검토자가 변경될 때 알림을 켭니다 |
| `close_issue`                  | 부울 | 아니요       | 이슈가 종료될 때 알림을 켭니다 |
| `close_merge_request`          | 부울 | 아니요       | 머지 리퀘스트가 종료될 때 알림을 켭니다 |
| `failed_pipeline`              | 부울 | 아니요       | 파이프라인이 실패할 때 알림을 켭니다 |
| `fixed_pipeline`               | 부울 | 아니요       | 이전에 실패한 파이프라인이 수정될 때 알림을 켭니다 |
| `issue_due`                    | 부울 | 아니요       | 이슈가 내일 만료될 때 알림을 켭니다 |
| `level`                        | 문자열  | 아니요       | 전역 알림 수준 |
| `merge_merge_request`          | 부울 | 아니요       | 머지 리퀘스트가 병합될 때 알림을 켭니다 |
| `merge_when_pipeline_succeeds` | 부울 | 아니요       | 머지 리퀘스트가 자동 병합으로 설정될 때 알림을 켭니다 |
| `moved_project`                | 부울 | 아니요       | 프로젝트가 이동할 때 알림을 켭니다 |
| `new_epic`                     | 부울 | 아니요       | 새 에픽이 생성될 때 알림을 켭니다(Premium 및 Ultimate 티어에서) |
| `new_issue`                    | 부울 | 아니요       | 새 이슈가 생성될 때 알림을 켭니다 |
| `new_merge_request`            | 부울 | 아니요       | 새 머지 리퀘스트가 생성될 때 알림을 켭니다 |
| `new_note`                     | 부울 | 아니요       | 새 댓글이 추가될 때 알림을 켭니다 |
| `new_release`                  | 부울 | 아니요       | 새 릴리스가 게시될 때 알림을 켭니다 |
| `notification_email`           | 문자열  | 아니요       | 알림을 보내는 이메일 주소 |
| `push_to_merge_request`        | 부울 | 아니요       | 누군가 머지 리퀘스트에 푸시할 때 알림을 켭니다 |
| `reassign_issue`               | 부울 | 아니요       | 이슈가 재할당될 때 알림을 켭니다 |
| `reassign_merge_request`       | 부울 | 아니요       | 머지 리퀘스트가 재할당될 때 알림을 켭니다 |
| `reopen_issue`                 | 부울 | 아니요       | 이슈가 다시 열릴 때 알림을 켭니다 |
| `reopen_merge_request`         | 부울 | 아니요       | 머지 리퀘스트가 다시 열릴 때 알림을 켭니다 |
| `success_pipeline`             | 부울 | 아니요       | 파이프라인이 성공적으로 완료될 때 알림을 켭니다 |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)을 반환하고 다음 응답 속성이 표시됩니다:

| 속성            | 유형   | 설명 |
| -------------------- | ------ | ----------- |
| `level`              | 문자열 | 전역 알림 수준 |
| `notification_email` | 문자열 | 알림을 보내는 이메일 주소 |

응답 예시:

```json
{
  "level": "watch",
  "notification_email": "admin@example.com"
}
```

## 알림 설정 검색 {#retrieve-notification-settings}

지정된 그룹 또는 프로젝트의 알림 수준을 검색합니다.

```plaintext
GET /groups/:id/notification_settings
GET /projects/:id/notification_settings
```

예제 요청:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/notification_settings"
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/8/notification_settings"
```

지원되는 속성:

| 속성 | 유형              | 필수 | 설명 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 정수 또는 문자열 | 예      | 그룹 또는 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)을 반환하고 다음 응답 속성이 표시됩니다:

| 속성 | 유형   | 설명 |
| --------- | ------ | ----------- |
| `level`   | 문자열 | 알림 수준 |

표준 알림 수준에 대한 예제 응답:

```json
{
  "level": "global"
}
```

사용자 정의 알림 수준이 있는 그룹에 대한 예제 응답:

```json
{
  "level": "custom",
  "events": {
    "new_release": null,
    "new_note": null,
    "new_issue": null,
    "reopen_issue": null,
    "close_issue": null,
    "reassign_issue": null,
    "issue_due": null,
    "new_merge_request": null,
    "push_to_merge_request": null,
    "reopen_merge_request": null,
    "close_merge_request": null,
    "reassign_merge_request": null,
    "change_reviewer_merge_request": null,
    "merge_merge_request": null,
    "failed_pipeline": null,
    "fixed_pipeline": null,
    "success_pipeline": null,
    "moved_project": true,
    "merge_when_pipeline_succeeds": false,
    "new_epic": null
  }
}
```

이 응답에서:

- `true`은(는) 알림이 켜져 있음을 나타냅니다.
- `false`은(는) 알림이 꺼져 있음을 나타냅니다.
- `null`은(는) 알림이 기본 설정을 사용함을 나타냅니다.

> [!note]
> `new_epic` 속성은 Premium 및 Ultimate 티어에서만 사용할 수 있습니다.

## 그룹 또는 프로젝트 알림 설정 업데이트 {#update-group-or-project-notification-settings}

그룹 또는 프로젝트의 알림 설정을 업데이트합니다.

```plaintext
PUT /groups/:id/notification_settings
PUT /projects/:id/notification_settings
```

예제 요청:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/notification_settings?level=watch"
```

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/8/notification_settings?level=custom&new_note=true"
```

지원되는 속성:

| 속성                      | 유형              | 필수 | 설명 |
| ------------------------------ | ----------------- | -------- | ----------- |
| `approver`                     | 부울           | 아니요       | 승인할 수 있는 머지 리퀘스트를 생성할 때 알림을 켭니다 |
| `change_reviewer_merge_request`| 부울           | 아니요       | 머지 리퀘스트의 검토자가 변경될 때 알림을 켭니다 |
| `close_issue`                  | 부울           | 아니요       | 이슈가 종료될 때 알림을 켭니다 |
| `close_merge_request`          | 부울           | 아니요       | 머지 리퀘스트가 종료될 때 알림을 켭니다 |
| `failed_pipeline`              | 부울           | 아니요       | 파이프라인이 실패할 때 알림을 켭니다 |
| `fixed_pipeline`               | 부울           | 아니요       | 이전에 실패한 파이프라인이 수정될 때 알림을 켭니다 |
| `id`                           | 정수 또는 문자열 | 예      | 그룹 또는 프로젝트의 ID 또는 [URL 인코딩 경로](rest/_index.md#namespaced-paths) |
| `issue_due`                    | 부울           | 아니요       | 이슈가 내일 만료될 때 알림을 켭니다 |
| `level`                        | 문자열            | 아니요       | 이 그룹 또는 프로젝트의 알림 수준 |
| `merge_merge_request`          | 부울           | 아니요       | 머지 리퀘스트가 병합될 때 알림을 켭니다 |
| `merge_when_pipeline_succeeds` | 부울           | 아니요       | 머지 리퀘스트가 파이프라인이 성공할 때 병합하도록 설정될 때 알림을 켭니다 |
| `moved_project`                | 부울           | 아니요       | 프로젝트가 이동할 때 알림을 켭니다 |
| `new_epic`                     | 부울           | 아니요       | 새 에픽이 생성될 때 알림을 켭니다(Premium 및 Ultimate 티어에서) |
| `new_issue`                    | 부울           | 아니요       | 새 이슈가 생성될 때 알림을 켭니다 |
| `new_merge_request`            | 부울           | 아니요       | 새 머지 리퀘스트가 생성될 때 알림을 켭니다 |
| `new_note`                     | 부울           | 아니요       | 새 댓글이 추가될 때 알림을 켭니다 |
| `new_release`                  | 부울           | 아니요       | 새 릴리스가 게시될 때 알림을 켭니다 |
| `push_to_merge_request`        | 부울           | 아니요       | 누군가 머지 리퀘스트에 푸시할 때 알림을 켭니다 |
| `reassign_issue`               | 부울           | 아니요       | 이슈가 재할당될 때 알림을 켭니다 |
| `reassign_merge_request`       | 부울           | 아니요       | 머지 리퀘스트가 재할당될 때 알림을 켭니다 |
| `reopen_issue`                 | 부울           | 아니요       | 이슈가 다시 열릴 때 알림을 켭니다 |
| `reopen_merge_request`         | 부울           | 아니요       | 머지 리퀘스트가 다시 열릴 때 알림을 켭니다 |
| `success_pipeline`             | 부울           | 아니요       | 파이프라인이 성공적으로 완료될 때 알림을 켭니다 |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)을 반환하고 다음 응답 형식 중 하나가 표시됩니다.

비사용자 정의 알림 수준의 경우:

```json
{
  "level": "watch"
}
```

사용자 정의 알림 수준의 경우 응답에 각 알림의 상태를 나타내는 `events` 객체가 포함됩니다:

```json
{
  "level": "custom",
  "events": {
    "new_release": null,
    "new_note": true,
    "new_issue": false,
    "reopen_issue": null,
    "close_issue": null,
    "reassign_issue": null,
    "issue_due": null,
    "new_merge_request": null,
    "push_to_merge_request": null,
    "reopen_merge_request": null,
    "close_merge_request": null,
    "reassign_merge_request": null,
    "change_reviewer_merge_request": null,
    "merge_merge_request": null,
    "failed_pipeline": false,
    "fixed_pipeline": null,
    "success_pipeline": null,
    "moved_project": false,
    "merge_when_pipeline_succeeds": false,
    "new_epic": null
  }
}
```

이 응답에서:

- `true`은(는) 알림이 켜져 있음을 나타냅니다.
- `false`은(는) 알림이 꺼져 있음을 나타냅니다.
- `null`은(는) 알림이 기본 설정을 사용함을 나타냅니다.

> [!note]
> `new_epic` 속성은 Premium 및 Ultimate 티어에서만 사용할 수 있습니다.
