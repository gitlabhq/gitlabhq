---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 브로드캐스트 메시지 API
description: "사용자 역할 타겟팅, 경로 필터링 및 사용자 지정 가능한 테마로 브로드캐스트 메시지를 관리합니다."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `target_access_levels` GitLab 14.8에서 [도입](https://gitlab.com/gitlab-org/growth/team-tasks/-/issues/461) 되었으며 [플래그](../administration/feature_flags/_index.md) `role_targeted_broadcast_messages`로 이름이 지정되었습니다. 기본적으로 비활성화됨.
- `color` 매개변수가 GitLab 15.6에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95829)되었습니다.
- `theme` GitLab 17.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/498900)되었습니다.

{{< /history >}}

이 API를 사용하여 UI에 표시되는 배너 및 알림과 상호 작용합니다. 자세한 내용은 [브로드캐스트 메시지](../administration/broadcast_messages.md)를 참조하세요.

GET 요청은 인증이 필요하지 않습니다. 다른 모든 브로드캐스트 메시지 API 엔드포인트는 관리자만 액세스할 수 있습니다. 비 GET 요청:

- 게스트는 `401 Unauthorized`로 귀결됩니다.
- 일반 사용자는 `403 Forbidden`로 귀결됩니다.

## 모든 브로드캐스트 메시지 나열 {#list-all-broadcast-messages}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

모든 브로드캐스트 메시지를 나열합니다.

```plaintext
GET /broadcast_messages
```

요청 예시:

```shell
curl "https://gitlab.example.com/api/v4/broadcast_messages"
```

응답 예시:

```json
[
    {
        "message":"Example broadcast message",
        "starts_at":"2016-08-24T23:21:16.078Z",
        "ends_at":"2016-08-26T23:21:16.080Z",
        "font":"#FFFFFF",
        "id":1,
        "active": false,
        "target_access_levels": [10,30],
        "target_path": "*/welcome",
        "broadcast_type": "banner",
        "dismissable": false,
        "theme": "indigo"
    }
]
```

## 브로드캐스트 메시지 검색 {#retrieve-a-broadcast-message}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

지정된 브로드캐스트 메시지를 검색합니다.

```plaintext
GET /broadcast_messages/:id
```

매개변수:

| 속성 | 유형    | 필수 | 설명                          |
|:----------|:--------|:---------|:-------------------------------------|
| `id`      | 정수 | 예      | 검색할 브로드캐스트 메시지의 ID입니다. |

요청 예시:

```shell
curl "https://gitlab.example.com/api/v4/broadcast_messages/1"
```

응답 예시:

```json
{
    "message":"Deploy in progress",
    "starts_at":"2016-08-24T23:21:16.078Z",
    "ends_at":"2016-08-26T23:21:16.080Z",
    "font":"#FFFFFF",
    "id":1,
    "active":false,
    "target_access_levels": [10,30],
    "target_path": "*/welcome",
    "broadcast_type": "banner",
    "dismissable": false,
    "theme": "indigo"
}
```

## 브로드캐스트 메시지 생성 {#create-a-broadcast-message}

> [!warning]
> 브로드캐스트 메시지는 타겟팅 설정에 관계없이 API를 통해 공개적으로 액세스할 수 있습니다. 민감하거나 기밀 정보를 포함하지 않으며, 브로드캐스트 메시지를 사용하여 특정 그룹 또는 프로젝트에 개인 정보를 전달하지 않습니다.

브로드캐스트 메시지를 생성합니다.

```plaintext
POST /broadcast_messages
```

매개변수:

| 속성              | 유형              | 필수 | 설명 |
|:-----------------------|:------------------|:---------|:------------|
| `message`              | 문자열            | 예      | 표시할 메시지입니다. |
| `starts_at`            | 날짜/시간          | 아니요       | 시작 시간(기본값은 UTC의 현재 시간)입니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |
| `ends_at`              | 날짜/시간          | 아니요       | 종료 시간(기본값은 UTC의 현재 시간으로부터 1시간)입니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |
| `font`                 | 문자열            | 아니요       | 전경 색상 16진수 코드입니다. |
| `target_access_levels` | 정수 배열 | 아니요       | 브로드캐스트 메시지의 대상 액세스 수준(역할)입니다. |
| `target_path`          | 문자열            | 아니요       | 브로드캐스트 메시지의 대상 경로입니다. |
| `broadcast_type`       | 문자열            | 아니요       | 모양 유형(기본값: 배너) |
| `dismissable`          | 부울           | 아니요       | 사용자가 메시지를 해제할 수 있습니까? |
| `theme`                | 문자열            | 아니요       | 브로드캐스트 메시지의 색상 테마(배너만 해당)입니다. |

`target_access_levels`은 `Gitlab::Access` 모듈에 정의되어 있습니다. 다음 수준이 유효합니다:

- 게스트 (`10`)
- 플래너 (`15`)
- 리포터 (`20`)
- 보안 관리자 (`25`)
- Developer (`30`)
- Maintainer (`40`)
- Owner (`50`)

`theme` 옵션은 `System::BroadcastMessage` 클래스에 정의되어 있습니다. 다음 테마가 유효합니다:

- `indigo` (기본값)
- `light-indigo`
- `blue`
- `light-blue`
- `green`
- `light-green`
- `red`
- `light-red`
- `dark`
- `light`

요청 예시:

```shell
curl --data "message=Deploy in progress&target_access_levels[]=10&target_access_levels[]=30&theme=red" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/broadcast_messages"
```

응답 예시:

```json
{
    "message":"Deploy in progress",
    "starts_at":"2016-08-26T00:41:35.060Z",
    "ends_at":"2016-08-26T01:41:35.060Z",
    "font":"#FFFFFF",
    "id":1,
    "active": true,
    "target_access_levels": [10,30],
    "target_path": "*/welcome",
    "broadcast_type": "notification",
    "dismissable": false,
    "theme": "red"
}
```

## 브로드캐스트 메시지 업데이트 {#update-a-broadcast-message}

> [!warning]
> 브로드캐스트 메시지는 타겟팅 설정에 관계없이 API를 통해 공개적으로 액세스할 수 있습니다. 민감하거나 기밀 정보를 포함하지 않으며, 브로드캐스트 메시지를 사용하여 특정 그룹 또는 프로젝트에 개인 정보를 전달하지 않습니다.

지정된 브로드캐스트 메시지를 업데이트합니다.

```plaintext
PUT /broadcast_messages/:id
```

매개변수:

| 속성              | 유형              | 필수 | 설명 |
|:-----------------------|:------------------|:---------|:------------|
| `id`                   | 정수           | 예      | 업데이트할 브로드캐스트 메시지의 ID입니다. |
| `message`              | 문자열            | 아니요       | 표시할 메시지입니다. |
| `starts_at`            | 날짜/시간          | 아니요       | 시작 시간(UTC)입니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |
| `ends_at`              | 날짜/시간          | 아니요       | 종료 시간(UTC)입니다. ISO 8601 형식으로 예상됩니다(`2019-03-15T08:00:00Z`) |
| `font`                 | 문자열            | 아니요       | 전경 색상 16진수 코드입니다. |
| `target_access_levels` | 정수 배열 | 아니요       | 브로드캐스트 메시지의 대상 액세스 수준(역할)입니다. |
| `target_path`          | 문자열            | 아니요       | 브로드캐스트 메시지의 대상 경로입니다. |
| `broadcast_type`       | 문자열            | 아니요       | 모양 유형(기본값: 배너) |
| `dismissable`          | 부울           | 아니요       | 사용자가 메시지를 해제할 수 있습니까? |
| `theme`                | 문자열            | 아니요       | 브로드캐스트 메시지의 색상 테마(배너만 해당)입니다. |

`target_access_levels`은 `Gitlab::Access` 모듈에 정의되어 있습니다. 다음 수준이 유효합니다:

- 게스트 (`10`)
- 플래너 (`15`)
- 리포터 (`20`)
- Developer (`30`)
- Maintainer (`40`)
- Owner (`50`)

`theme` 옵션은 `System::BroadcastMessage` 클래스에 정의되어 있습니다. 다음 테마가 유효합니다:

- `indigo` (기본값)
- `light-indigo`
- `blue`
- `light-blue`
- `green`
- `light-green`
- `red`
- `light-red`
- `dark`
- `light`

요청 예시:

```shell
curl --request PUT \
  --data "message=Update message" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/broadcast_messages/1"
```

응답 예시:

```json
{
    "message":"Update message",
    "starts_at":"2016-08-26T00:41:35.060Z",
    "ends_at":"2016-08-26T01:41:35.060Z",
    "font":"#FFFFFF",
    "id":1,
    "active": true,
    "target_access_levels": [10,30],
    "target_path": "*/welcome",
    "broadcast_type": "notification",
    "dismissable": false,
    "theme": "indigo"
}
```

## 브로드캐스트 메시지 삭제 {#delete-a-broadcast-message}

지정된 브로드캐스트 메시지를 삭제합니다.

```plaintext
DELETE /broadcast_messages/:id
```

매개변수:

| 속성 | 유형    | 필수 | 설명                        |
|:----------|:--------|:---------|:-----------------------------------|
| `id`      | 정수 | 예      | 삭제할 브로드캐스트 메시지의 ID입니다. |

요청 예시:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/broadcast_messages/1"
```
