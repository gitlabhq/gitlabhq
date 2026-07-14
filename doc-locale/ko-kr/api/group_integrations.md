---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 그룹 통합 API
description: "REST API를 통해 그룹의 통합을 설정하고 관리합니다."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab 17.9에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/328496).

{{< /history >}}

이 API를 사용하여 그룹 및 하위 그룹에 대한 [통합](../user/project/integrations/_index.md)을 관리합니다.

전제 조건:

- 그룹에 대해 유지 관리자 또는 소유자 역할이 필요합니다.

## 모든 활성 통합 나열 {#list-all-active-integrations}

모든 활성 그룹 통합의 목록을 가져옵니다. `vulnerability_events` 필드는 GitLab Enterprise Edition에서만 사용할 수 있습니다.

```plaintext
GET /groups/:id/integrations
```

예제 응답:

```json
[
  {
    "id": 75,
    "title": "Jenkins CI",
    "slug": "jenkins",
    "created_at": "2019-11-20T11:20:25.297Z",
    "updated_at": "2019-11-20T12:24:37.498Z",
    "active": true,
    "commit_events": true,
    "push_events": true,
    "issues_events": true,
    "alert_events": true,
    "confidential_issues_events": true,
    "merge_requests_events": true,
    "tag_push_events": false,
    "deployment_events": false,
    "note_events": true,
    "confidential_note_events": true,
    "pipeline_events": true,
    "wiki_page_events": true,
    "job_events": true,
    "comment_on_event_enabled": true,
    "inherited": false,
    "vulnerability_events": true
  },
  {
    "id": 76,
    "title": "Alerts endpoint",
    "slug": "alerts",
    "created_at": "2019-11-20T11:20:25.297Z",
    "updated_at": "2019-11-20T12:24:37.498Z",
    "active": true,
    "commit_events": true,
    "push_events": true,
    "issues_events": true,
    "alert_events": true,
    "confidential_issues_events": true,
    "merge_requests_events": true,
    "tag_push_events": true,
    "deployment_events": false,
    "note_events": true,
    "confidential_note_events": true,
    "pipeline_events": true,
    "wiki_page_events": true,
    "job_events": true,
    "comment_on_event_enabled": true,
    "inherited": false,
    "vulnerability_events": true
  }
]
```

## Asana {#asana}

### Asana 설정 {#set-up-asana}

그룹에 대해 Asana 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/asana
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `api_key` | 문자열 | 예 | 사용자 API 토큰입니다. 사용자는 작업에 액세스할 수 있어야 합니다. 모든 댓글은 이 사용자에게 귀속됩니다. |
| `restrict_to_branch` | 문자열 | 아니오 | 자동으로 검사할 쉼표로 구분된 브랜치 목록입니다. 모든 브랜치를 포함하려면 비워 둡니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Asana 비활성화 {#disable-asana}

그룹에 대해 Asana 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/asana
```

### Asana 설정 가져오기 {#get-asana-settings}

그룹에 대한 Asana 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/asana
```

## Assembla {#assembla}

### Assembla 설정 {#set-up-assembla}

그룹에 대해 Assembla 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/assembla
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `token` | 문자열 | 예 | 인증 토큰입니다. |
| `subdomain` | 문자열 | 아니오 | 하위 도메인 설정입니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Assembla 비활성화 {#disable-assembla}

그룹에 대해 Assembla 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/assembla
```

### Assembla 설정 가져오기 {#get-assembla-settings}

그룹에 대한 Assembla 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/assembla
```

## Atlassian Bamboo {#atlassian-bamboo}

### Atlassian Bamboo 설정 {#set-up-atlassian-bamboo}

그룹에 대해 Atlassian Bamboo 통합을 설정합니다.

Bamboo에서 자동 버전 레이블 지정 및 저장소 트리거를 구성해야 합니다.

```plaintext
PUT /groups/:id/integrations/bamboo
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `bamboo_url` | 문자열 | 예 | Bamboo 루트 URL(예: `https://bamboo.example.com`)입니다. |
| `enable_ssl_verification` | 부울 | 아니오 | SSL 확인을 활성화합니다. `true`(활성화됨)으로 기본값이 지정됩니다. |
| `build_key` | 문자열 | 예 | Bamboo 빌드 계획 키(예: `KEY`)입니다. |
| `username` | 문자열 | 예 | Bamboo 서버에 API 액세스 권한이 있는 사용자입니다. |
| `password` | 문자열 | 예 | 사용자의 비밀번호입니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Atlassian Bamboo 비활성화 {#disable-atlassian-bamboo}

그룹에 대해 Atlassian Bamboo 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/bamboo
```

### Atlassian Bamboo 설정 가져오기 {#get-atlassian-bamboo-settings}

그룹에 대한 Atlassian Bamboo 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/bamboo
```

## Bugzilla {#bugzilla}

### Bugzilla 설정 {#set-up-bugzilla}

그룹에 대해 Bugzilla 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/bugzilla
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | 문자열 | 예 |  새 이슈의 URL입니다. |
| `issues_url` | 문자열 | 예 | 이슈의 URL입니다. |
| `project_url` | 문자열 | 예 | 프로젝트의 URL입니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Bugzilla 비활성화 {#disable-bugzilla}

그룹에 대해 Bugzilla 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/bugzilla
```

### Bugzilla 설정 가져오기 {#get-bugzilla-settings}

그룹에 대한 Bugzilla 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/bugzilla
```

## Buildkite {#buildkite}

### Buildkite 설정 {#set-up-buildkite}

그룹에 대해 Buildkite 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/buildkite
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `token` | 문자열 | 예 | Buildkite 프로젝트 GitLab 토큰입니다. |
| `project_url` | 문자열 | 예 | 파이프라인 URL(예: `https://buildkite.com/example/pipeline`)입니다. |
| `enable_ssl_verification` | 부울 | 아니오 | **더 이상 사용되지 않음**:  SSL 확인이 항상 활성화되어 있기 때문에 이 매개 변수는 적용되지 않습니다. |
| `push_events` | 부울 | 아니오 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니오 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니오 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Buildkite 비활성화 {#disable-buildkite}

그룹에 대해 Buildkite 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/buildkite
```

### Buildkite 설정 가져오기 {#get-buildkite-settings}

그룹에 대한 Buildkite 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/buildkite
```

## Campfire Classic {#campfire-classic}

Campfire Classic과 통합할 수 있습니다. 그러나 Campfire Classic은 Basecamp에서 [더 이상 판매되지 않는](https://gitlab.com/gitlab-org/gitlab/-/issues/329337) 구식 제품입니다.

### Campfire Classic 설정 {#set-up-campfire-classic}

그룹에 대해 Campfire Classic 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/campfire
```

매개 변수:

| 매개 변수     | 유형    | 필수 | 설명                                                                                 |
|---------------|---------|----------|---------------------------------------------------------------------------------------------|
| `token`       | 문자열  | 예     | Campfire Classic의 API 인증 토큰입니다. 토큰을 가져오려면 Campfire Classic에 로그인하고 **My info**를 선택합니다. |
| `subdomain`   | 문자열  | 아니오    | 로그인했을 때 `.campfirenow.com` 하위 도메인입니다. |
| `room`        | 문자열  | 아니오    | Campfire Classic 채팅방 URL의 ID 부분입니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Campfire Classic 비활성화 {#disable-campfire-classic}

그룹에 대해 Campfire Classic 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/campfire
```

### Campfire Classic 설정 가져오기 {#get-campfire-classic-settings}

그룹에 대한 Campfire Classic 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/campfire
```

## ClickUp {#clickup}

### ClickUp 설정 {#set-up-clickup}

그룹에 대해 ClickUp 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/clickup
```

매개 변수:

| 매개 변수     | 유형   | 필수 | 설명    |
| ------------- | ------ | -------- | -------------- |
| `issues_url`  | 문자열 | 예     | 이슈의 URL입니다.     |
| `project_url` | 문자열 | 예     | 프로젝트의 URL입니다.   |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### ClickUp 비활성화 {#disable-clickup}

그룹에 대해 ClickUp 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/clickup
```

### ClickUp 설정 가져오기 {#get-clickup-settings}

그룹에 대한 ClickUp 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/clickup
```

## Confluence Workspace {#confluence-workspace}

### Confluence Workspace 설정 {#set-up-confluence-workspace}

그룹에 대해 Confluence Workspace 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/confluence
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `confluence_url` | 문자열 | 예 | `atlassian.net`에 호스팅된 Confluence Workspace의 URL입니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Confluence Workspace 비활성화 {#disable-confluence-workspace}

그룹에 대해 Confluence Workspace 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/confluence
```

### Confluence Workspace 설정 가져오기 {#get-confluence-workspace-settings}

그룹에 대한 Confluence Workspace 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/confluence
```

## 사용자 지정 이슈 추적기 {#custom-issue-tracker}

### 사용자 지정 이슈 추적기 설정 {#set-up-a-custom-issue-tracker}

그룹에 대해 사용자 지정 이슈 추적기를 설정합니다.

```plaintext
PUT /groups/:id/integrations/custom-issue-tracker
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | 문자열 | 예 |  새 이슈의 URL입니다. |
| `issues_url` | 문자열 | 예 | 이슈의 URL입니다. |
| `project_url` | 문자열 | 예 | 프로젝트의 URL입니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### 사용자 지정 이슈 추적기 비활성화 {#disable-a-custom-issue-tracker}

그룹에 대해 사용자 지정 이슈 추적기를 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/custom-issue-tracker
```

### 사용자 지정 이슈 추적기 설정 가져오기 {#get-custom-issue-tracker-settings}

그룹에 대한 사용자 지정 이슈 추적기 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/custom-issue-tracker
```

## Datadog {#datadog}

### Datadog 설정 {#set-up-datadog}

그룹에 대해 Datadog 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/datadog
```

매개 변수:

| 매개 변수              | 유형    | 필수 | 설명                                                                                                                                                                            |
|------------------------|---------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `api_key`              | 문자열  | 예     | Datadog로 인증하는 데 사용되는 API 키입니다.                                                                                                                                          |
| `api_url`              | 문자열  | 아니오    | (고급) Datadog 사이트의 전체 URL입니다.                                                                                                                                          |
| `datadog_env`          | 문자열  | 아니오    | 자체 관리 배포의 경우 Datadog으로 전송되는 모든 데이터에 대해 `env%` 태그를 설정합니다.                                                                                                      |
| `datadog_service`      | 문자열  | 아니오    | Datadog에서 이 GitLab 인스턴스의 모든 데이터에 태그를 지정합니다. 여러 자체 관리 배포를 관리할 때 사용할 수 있습니다.                                                                          |
| `datadog_site`         | 문자열  | 아니오    | 데이터를 전송할 Datadog 사이트입니다. EU 사이트로 데이터를 전송하려면 `datadoghq.eu`을 사용합니다.                                                                                                      |
| `datadog_tags`         | 문자열  | 아니오    | Datadog의 사용자 지정 태그입니다. `key:value\nkey2:value2` 형식으로 한 줄에 하나의 태그를 지정합니다.                                                                                                 |
| `archive_trace_events` | 부울 | 아니오    | 활성화되면 작업 로그가 Datadog에 의해 수집되고 파이프라인 실행 추적과 함께 표시됩니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Datadog 비활성화 {#disable-datadog}

그룹에 대해 Datadog 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/datadog
```

### Datadog 설정 가져오기 {#get-datadog-settings}

그룹에 대한 Datadog 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/datadog
```

## Diffblue Cover {#diffblue-cover}

### Diffblue Cover 설정 {#set-up-diffblue-cover}

그룹에 대해 Diffblue Cover 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/diffblue-cover
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `diffblue_license_key` | 문자열 | 예 | Diffblue Cover 라이센스 키입니다. |
| `diffblue_access_token_name` | 문자열 | 예 | 파이프라인에서 Diffblue Cover에서 사용하는 액세스 토큰 이름입니다. |
| `diffblue_access_token_secret` | 문자열  | 예 | 파이프라인에서 Diffblue Cover에서 사용하는 액세스 토큰 시크릿입니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Diffblue Cover 비활성화 {#disable-diffblue-cover}

그룹에 대해 Diffblue Cover 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/diffblue-cover
```

### Diffblue Cover 설정 가져오기 {#get-diffblue-cover-settings}

그룹에 대한 Diffblue Cover 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/diffblue-cover
```

## Discord 알림 {#discord-notifications}

### Discord 알림 설정 {#set-up-discord-notifications}

그룹에 대해 Discord 알림을 설정합니다.

```plaintext
PUT /groups/:id/integrations/discord
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 문자열 | 예 | Discord 웹후크(예: `https://discord.com/api/webhooks/...`)입니다. |
| `branches_to_be_notified` | 문자열 | 아니오 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `confidential_issues_events` | 부울 | 아니오 | 기밀 이슈 이벤트에 대한 알림을 활성화합니다. |
| `confidential_issue_channel` | 문자열 | 아니오 | 기밀 이슈 이벤트에 대한 알림을 수신하기 위한 웹후크 재정의입니다. |
| `confidential_note_events` | 부울 | 아니오 | 기밀 노트 이벤트에 대한 알림을 활성화합니다. |
| `confidential_note_channel` | 문자열 | 아니오 | 기밀 노트 이벤트에 대한 알림을 수신하기 위한 웹후크 재정의입니다. |
| `deployment_events` | 부울 | 아니오 | 배포 이벤트에 대한 알림을 활성화합니다. |
| `deployment_channel` | 문자열 | 아니오 | 배포 이벤트에 대한 알림을 수신하기 위한 웹후크 재정의입니다. |
| `group_confidential_mentions_events` | 부울 | 아니오 | 그룹 기밀 언급 이벤트에 대한 알림을 활성화합니다. |
| `group_confidential_mentions_channel` | 문자열 | 아니오 | 그룹 기밀 언급 이벤트에 대한 알림을 수신하기 위한 웹후크 재정의입니다. |
| `group_mentions_events` | 부울 | 아니오 | 그룹 언급 이벤트에 대한 알림을 활성화합니다. |
| `group_mentions_channel` | 문자열 | 아니오 | 그룹 언급 이벤트에 대한 알림을 수신하기 위한 웹후크 재정의입니다. |
| `issues_events` | 부울 | 아니오 | 이슈 이벤트에 대한 알림을 활성화합니다. |
| `issue_channel` | 문자열 | 아니오 | 이슈 이벤트에 대한 알림을 수신하기 위한 웹후크 재정의입니다. |
| `merge_requests_events` | 부울 | 아니오 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `merge_request_channel` | 문자열 | 아니오 | 머지 리퀘스트 이벤트에 대한 알림을 수신하기 위한 웹후크 재정의입니다. |
| `note_events` | 부울 | 아니오 | 노트 이벤트에 대한 알림을 활성화합니다. |
| `note_channel` | 문자열 | 아니오 | 노트 이벤트에 대한 알림을 수신하기 위한 웹후크 재정의입니다. |
| `notify_only_broken_pipelines` | 부울 | 아니오 | 손상된 파이프라인에 대한 알림을 보냅니다. |
| `notify_only_when_pipeline_status_changes` | 부울 | 아니오 | ref의 파이프라인 상태가 변경될 때만 알림을 보냅니다. |
| `pipeline_events` | 부울 | 아니오 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `pipeline_channel` | 문자열 | 아니오 | 파이프라인 이벤트에 대한 알림을 수신하기 위한 웹후크 재정의입니다. |
| `push_events` | 부울 | 아니오 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `push_channel` | 문자열 | 아니오 | 푸시 이벤트에 대한 알림을 수신하기 위한 웹후크 재정의입니다. |
| `tag_push_events` | 부울 | 아니오 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_channel` | 문자열 | 아니오 | 태그 푸시 이벤트에 대한 알림을 수신하기 위한 웹후크 재정의입니다. |
| `wiki_page_events` | 부울 | 아니오 | 위키 페이지 이벤트에 대한 알림을 활성화합니다. |
| `wiki_page_channel` | 문자열 | 아니오 | 위키 페이지 이벤트에 대한 알림을 수신하기 위한 웹후크 재정의입니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Discord 알림 비활성화 {#disable-discord-notifications}

그룹에 대해 Discord 알림을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/discord
```

### Discord 알림 설정 가져오기 {#get-discord-notifications-settings}

그룹에 대한 Discord 알림 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/discord
```

## Drone {#drone}

### Drone 설정 {#set-up-drone}

그룹에 대해 Drone 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/drone-ci
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `token` | 문자열 | 예 | Drone CI 프로젝트별 토큰입니다. |
| `drone_url` | 문자열 | 예 | `http://drone.example.com`입니다. |
| `enable_ssl_verification` | 부울 | 아니오 | SSL 확인을 활성화합니다. `true`(활성화됨)으로 기본값이 지정됩니다. |
| `push_events` | 부울 | 아니오 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니오 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니오 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Drone 비활성화 {#disable-drone}

그룹에 대해 Drone 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/drone-ci
```

### Drone 설정 가져오기 {#get-drone-settings}

그룹에 대한 Drone 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/drone-ci
```

## 푸시 시 이메일 {#emails-on-push}

### 푸시 시 이메일 설정 {#set-up-emails-on-push}

그룹에 대해 푸시 시 이메일 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/emails-on-push
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `recipients` | 문자열 | 예 | 공백으로 구분된 이메일입니다. |
| `disable_diffs` | 부울 | 아니오 | 코드 차이를 비활성화합니다. |
| `send_from_committer_email` | 부울 | 아니오 | 커미터에서 보냅니다. |
| `push_events` | 부울 | 아니오 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니오 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `branches_to_be_notified` | 문자열 | 아니오 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 태그 푸시에 대해서는 항상 알림이 발생합니다. 기본값은 `all`입니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### 푸시 시 이메일 비활성화 {#disable-emails-on-push}

그룹에 대해 푸시 시 이메일 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/emails-on-push
```

### 푸시 시 이메일 설정 가져오기 {#get-emails-on-push-settings}

그룹에 대한 푸시 시 이메일 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/emails-on-push
```

## 엔지니어링 워크플로우 관리(EWM) {#engineering-workflow-management-ewm}

### EWM 설정 {#set-up-ewm}

그룹에 대해 EWM 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/ewm
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | 문자열 | 예 | 새 이슈의 URL입니다. |
| `project_url`   | 문자열 | 예 | 프로젝트의 URL입니다. |
| `issues_url`    | 문자열 | 예 | 이슈의 URL입니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### EWM 비활성화 {#disable-ewm}

그룹에 대해 EWM 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/ewm
```

### EWM 설정 가져오기 {#get-ewm-settings}

그룹에 대한 EWM 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/ewm
```

## 외부 위키 {#external-wiki}

### 외부 위키 설정 {#set-up-an-external-wiki}

그룹에 대해 외부 위키를 설정합니다.

```plaintext
PUT /groups/:id/integrations/external-wiki
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `external_wiki_url` | 문자열 | 예 | 외부 위키의 URL입니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### 외부 위키 비활성화 {#disable-an-external-wiki}

그룹에 대해 외부 위키를 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/external-wiki
```

### 외부 위키 설정 가져오기 {#get-external-wiki-settings}

그룹에 대한 외부 위키 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/external-wiki
```

## GitGuardian {#gitguardian}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!flag]
> GitLab 자체 관리에서는 기본적으로 이 기능을 사용할 수 있습니다. 기능을 숨기려면 관리자에게 [기능 플래그 비활성화](../administration/feature_flags/_index.md)를 요청하여 `git_guardian_integration`라는 이름의 기능을 비활성화합니다. GitLab.com에서는 이 기능을 사용할 수 없습니다. GitLab Dedicated에서는 이 기능을 사용할 수 있습니다.

[GitGuardian](https://www.gitguardian.com/)은 소스 코드 저장소에서 API 키 및 비밀번호와 같은 민감한 데이터를 탐지하는 사이버 보안 서비스입니다. Git 저장소를 스캔하고 정책 위반을 경고하며 해커가 보안 문제를 악용하기 전에 이를 수정하도록 조직을 지원합니다.

GitGuardian 정책에 따라 커밋을 거부하도록 GitLab을 구성할 수 있습니다.

알려진 문제 및 문제 해결 단계는 [GitGuardian 문제 해결](../user/project/integrations/git_guardian.md#troubleshooting)을 참조하세요.

### GitGuardian 설정 {#set-up-gitguardian}

그룹에 대해 GitGuardian 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/git-guardian
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명                                   |
| --------- | ---- | -------- |-----------------------------------------------|
| `token` | 문자열 | 예 | `scan` 범위가 있는 GitGuardian API 토큰입니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### GitGuardian 비활성화 {#disable-gitguardian}

그룹에 대해 GitGuardian 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/git-guardian
```

### GitGuardian 설정 가져오기 {#get-gitguardian-settings}

그룹에 대한 GitGuardian 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/git-guardian
```

## GitHub {#github}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

### GitHub 설정 {#set-up-github}

그룹에 대해 GitHub 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/github
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `token` | 문자열 | 예 | `repo:status` OAuth 범위가 있는 GitHub API 토큰입니다. |
| `repository_url` | 문자열 | 예 | GitHub 저장소 URL입니다. |
| `static_context` | 부울 | 아니오 | GitLab 인스턴스의 호스트명을 [상태 확인 이름](../user/project/integrations/github.md#static-or-dynamic-status-check-names)에 추가합니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### GitHub 비활성화 {#disable-github}

그룹에 대해 GitHub 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/github
```

### GitHub 설정 가져오기 {#get-github-settings}

그룹에 대한 GitHub 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/github
```

## Jira Cloud용 GitLab {#gitlab-for-jira-cloud-app}

Jira Cloud용 GitLab 통합은 [Jira의 그룹 연결 및 연결 해제](../integration/jira/connect-app.md#configure-the-gitlab-for-jira-cloud-app)를 통해 자동으로 활성화 또는 비활성화됩니다. GitLab 통합 양식 또는 API를 사용하여 통합을 활성화 또는 비활성화할 수 없습니다.

### 그룹에 대한 통합 업데이트 {#update-integration-for-a-group}

이 API 끝점을 사용하여 Jira에서 그룹 연결을 통해 생성한 통합을 업데이트합니다.

```plaintext
PUT /groups/:id/integrations/jira-cloud-app
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `jira_cloud_app_service_ids` | 문자열 | 아니오 | Jira Service Management 서비스 ID입니다. 쉼표(`,`)를 사용하여 여러 ID를 분리합니다. |
| `jira_cloud_app_enable_deployment_gating` | 부울 | 아니오 | Jira Service Management에서 차단된 GitLab 배포에 대한 배포 게이팅을 활성화합니다. |
| `jira_cloud_app_deployment_gating_environments` | 문자열 | 아니오 | 배포 게이팅을 활성화할 환경(프로덕션, 스테이징, 테스트 또는 개발)입니다. 배포 게이팅이 활성화된 경우 필수입니다. 쉼표(`,`)를 사용하여 여러 환경을 분리합니다. |

### Jira Cloud용 GitLab 설정 가져오기 {#get-gitlab-for-jira-cloud-app-settings}

그룹에 대한 Jira Cloud용 GitLab 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/jira-cloud-app
```

## Slack용 GitLab {#gitlab-for-slack-app}

### Slack용 GitLab 설정 {#set-up-gitlab-for-slack-app}

그룹에 대한 Slack용 GitLab 통합을 업데이트합니다.

GitLab API만으로는 얻을 수 없는 OAuth 2.0 토큰이 필요하므로 API를 통해 Slack용 GitLab을 만들 수 없습니다. 대신 GitLab UI에서 [앱을 설치](../user/project/integrations/gitlab_slack_application.md#install-the-gitlab-for-slack-app)해야 합니다. 그런 다음 이 API 끝점을 사용하여 통합을 업데이트할 수 있습니다.

```plaintext
PUT /groups/:id/integrations/gitlab-slack-application
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `channel` | 문자열 | 아니오 | 다른 채널이 구성되지 않은 경우 사용할 기본 채널입니다. |
| `notify_only_broken_pipelines` | 부울 | 아니오 | 손상된 파이프라인에 대한 알림을 보냅니다. |
| `notify_only_when_pipeline_status_changes` | 부울 | 아니오 | ref의 파이프라인 상태가 변경될 때만 알림을 보냅니다. |
| `notify_only_default_branch` | 부울 | 아니오 | **더 이상 사용되지 않음**:  이 매개 변수는 `branches_to_be_notified`로 대체되었습니다. |
| `branches_to_be_notified` | 문자열 | 아니오 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `alert_events` | 부울 | 아니오 | 경고 이벤트에 대한 알림을 활성화합니다. |
| `issues_events` | 부울 | 아니오 | 이슈 이벤트에 대한 알림을 활성화합니다. |
| `confidential_issues_events` | 부울 | 아니오 | 기밀 이슈 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니오 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `note_events` | 부울 | 아니오 | 노트 이벤트에 대한 알림을 활성화합니다. |
| `confidential_note_events` | 부울 | 아니오 | 기밀 노트 이벤트에 대한 알림을 활성화합니다. |
| `deployment_events` | 부울 | 아니오 | 배포 이벤트에 대한 알림을 활성화합니다. |
| `incidents_events` | 부울 | 아니오 | 인시던트 이벤트에 대한 알림을 활성화합니다. |
| `pipeline_events` | 부울 | 아니오 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `push_events` | 부울 | 아니오 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니오 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `vulnerability_events` | 부울 | 아니오 | 취약성 이벤트에 대한 알림을 활성화합니다. |
| `wiki_page_events` | 부울 | 아니오 | 위키 페이지 이벤트에 대한 알림을 활성화합니다. |
| `labels_to_be_notified` | 문자열 | 아니오 | 알림을 보낼 레이블입니다. 설정되지 않은 경우 모든 이벤트에 대한 알림을 수신합니다. |
| `labels_to_be_notified_behavior` | 문자열 | 아니오 | 알림을 받을 레이블입니다. 유효한 옵션은 `match_any`과(와) `match_all`입니다. `match_any`로 기본값이 설정됩니다. |
| `push_channel` | 문자열 | 아니오 | 푸시 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `issue_channel` | 문자열 | 아니오 | 이슈 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `confidential_issue_channel` | 문자열 | 아니오 | 기밀 이슈 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `merge_request_channel` | 문자열 | 아니오 | 머지 리퀘스트 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `note_channel` | 문자열 | 아니오 | 노트 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `confidential_note_channel` | 문자열 | 아니오 | 기밀 노트 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `tag_push_channel` | 문자열 | 아니오 | 태그 푸시 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `pipeline_channel` | 문자열 | 아니오 | 파이프라인 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `wiki_page_channel` | 문자열 | 아니오 | 위키 페이지 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `deployment_channel` | 문자열 | 아니오 | 배포 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `incident_channel` | 문자열 | 아니오 | 인시던트 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `vulnerability_channel` | 문자열 | 아니오 | 취약성 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `alert_channel` | 문자열 | 아니오 | 경고 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### GitLab for Slack app 비활성화 {#disable-gitlab-for-slack-app}

그룹에 대해 GitLab for Slack app 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/gitlab-slack-application
```

### GitLab for Slack app 설정 가져오기 {#get-gitlab-for-slack-app-settings}

그룹에 대해 GitLab for Slack app 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/gitlab-slack-application
```

## Google Chat {#google-chat}

### Google Chat 설정 {#set-up-google-chat}

그룹에 대해 Google Chat 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/hangouts-chat
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 문자열 | 예 | Hangouts Chat 웹후크(예: `https://chat.googleapis.com/v1/spaces...`). |
| `notify_only_broken_pipelines` | 부울 | 아니오 | 손상된 파이프라인에 대한 알림을 보냅니다. |
| `notify_only_when_pipeline_status_changes` | 부울 | 아니오 | ref의 파이프라인 상태가 변경될 때만 알림을 보냅니다. |
| `notify_only_default_branch` | 부울 | 아니오 | **더 이상 사용되지 않음**:  이 매개 변수는 `branches_to_be_notified`로 대체되었습니다. |
| `branches_to_be_notified` | 문자열 | 아니오 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `push_events` | 부울 | 아니오 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `issues_events` | 부울 | 아니오 | 이슈 이벤트에 대한 알림을 활성화합니다. |
| `confidential_issues_events` | 부울 | 아니오 | 기밀 이슈 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니오 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니오 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `note_events` | 부울 | 아니오 | 노트 이벤트에 대한 알림을 활성화합니다. |
| `confidential_note_events` | 부울 | 아니오 | 기밀 노트 이벤트에 대한 알림을 활성화합니다. |
| `pipeline_events` | 부울 | 아니오 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `wiki_page_events` | 부울 | 아니오 | 위키 페이지 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Google Chat 비활성화 {#disable-google-chat}

그룹에 대해 Google Chat 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/hangouts-chat
```

### Google Chat 설정 가져오기 {#get-google-chat-settings}

그룹에 대해 Google Chat 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/hangouts-chat
```

## Google Artifact Management {#google-artifact-management}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com
- 상태:  베타

{{< /details >}}

이 기능은 [베타](../policy/development_stages_support.md) 버전입니다.

### Google Artifact Management 설정 {#set-up-google-artifact-management}

그룹에 대해 Google Artifact Management 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/google-cloud-platform-artifact-registry
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `artifact_registry_project_id` | 문자열 | 예 | Google Cloud 프로젝트의 ID입니다. |
| `artifact_registry_location` | 문자열 | 예 | Artifact Registry 리포지토리의 위치입니다. |
| `artifact_registry_repositories` | 문자열 | 예 | Artifact Registry의 리포지토리입니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Google Artifact Management 비활성화 {#disable-google-artifact-management}

그룹에 대해 Google Artifact Management 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/google-cloud-platform-artifact-registry
```

### Google Artifact Management 설정 가져오기 {#get-google-artifact-management-settings}

그룹에 대해 Google Artifact Management 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/google-cloud-platform-artifact-registry
```

## Google Cloud Identity and Access Management (IAM) {#google-cloud-identity-and-access-management-iam}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com
- 상태:  베타

{{< /details >}}

이 기능은 [베타](../policy/development_stages_support.md) 버전입니다.

### Google Cloud Identity and Access Management 설정 {#set-up-google-cloud-identity-and-access-management}

그룹에 대해 Google Cloud Identity and Access Management 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/google-cloud-platform-workload-identity-federation
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `workload_identity_federation_project_id` | 문자열 | 예 | Workload Identity Federation을 위한 Google Cloud 프로젝트 ID입니다. |
| `workload_identity_federation_project_number` | 정수 | 예 | Workload Identity Federation을 위한 Google Cloud 프로젝트 번호입니다. |
| `workload_identity_pool_id` | 문자열 | 예 | 워크로드 아이덴티티 풀의 ID입니다. |
| `workload_identity_pool_provider_id` | 문자열 | 예 | 워크로드 아이덴티티 풀 공급자의 ID입니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Google Cloud Identity and Access Management 비활성화 {#disable-google-cloud-identity-and-access-management}

그룹에 대해 Google Cloud Identity and Access Management 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/google-cloud-platform-workload-identity-federation
```

### Google Cloud Identity and Access Management 가져오기 {#get-google-cloud-identity-and-access-management}

그룹에 대해 Google Cloud Identity and Access Management 설정을 가져옵니다.

```plaintext
GET /groups/:id/integration/google-cloud-platform-workload-identity-federation
```

## Harbor {#harbor}

### Harbor 설정 {#set-up-harbor}

그룹에 대해 Harbor 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/harbor
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `url` | 문자열 | 예 | GitLab 프로젝트에 연결된 Harbor 인스턴스의 기본 URL입니다. 예를 들어, `https://demo.goharbor.io`입니다. |
| `project_name` | 문자열 | 예 | Harbor 인스턴스의 프로젝트 이름입니다. 예를 들어, `testproject`입니다. |
| `username` | 문자열 | 예 | Harbor 인터페이스에서 생성한 사용자 이름입니다. |
| `password` | 문자열 | 예 | 사용자의 비밀번호입니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Harbor 비활성화 {#disable-harbor}

그룹에 대해 Harbor 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/harbor
```

### Harbor 설정 가져오기 {#get-harbor-settings}

그룹에 대해 Harbor 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/harbor
```

## irker (IRC gateway) {#irker-irc-gateway}

### irker 설정 {#set-up-irker}

그룹에 대해 irker 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/irker
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `recipients` | 문자열 | 예 | 공백으로 구분된 수신자 또는 채널입니다. |
| `default_irc_uri` | 문자열 | 아니오 | `irc://irc.network.net:6697/`입니다. |
| `server_host` | 문자열 | 아니오 | localhost. |
| `server_port` | 정수 | 아니오 | 6659\. |
| `colorize_messages` | 부울 | 아니오 | 메시지를 컬러화합니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### irker 비활성화 {#disable-irker}

그룹에 대해 irker 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/irker
```

### irker 설정 가져오기 {#get-irker-settings}

그룹에 대해 irker 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/irker
```

## JetBrains TeamCity {#jetbrains-teamcity}

### JetBrains TeamCity 설정 {#set-up-jetbrains-teamcity}

그룹에 대해 JetBrains TeamCity 통합을 설정합니다.

TeamCity의 빌드 구성은 빌드 번호 형식 `%build.vcs.number%`을(를) 사용해야 합니다. VCS 루트의 고급 설정에서 모든 브랜치에 대한 모니터링을 구성하여 머지 리퀘스트가 빌드될 수 있도록 합니다.

```plaintext
PUT /groups/:id/integrations/teamcity
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `teamcity_url` | 문자열 | 예 | TeamCity 루트 URL(예: `https://teamcity.example.com`). |
| `enable_ssl_verification` | 부울 | 아니오 | SSL 확인을 활성화합니다. `true`(활성화됨)으로 기본값이 지정됩니다. |
| `build_type` | 문자열 | 예 | 구성 ID를 빌드합니다. |
| `username` | 문자열 | 예 | 수동 빌드를 트리거할 수 있는 권한이 있는 사용자입니다. |
| `password` | 문자열 | 예 | 사용자의 비밀번호입니다. |
| `push_events` | 부울 | 아니오 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니오 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### JetBrains TeamCity 비활성화 {#disable-jetbrains-teamcity}

그룹에 대해 JetBrains TeamCity 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/teamcity
```

### JetBrains TeamCity 설정 가져오기 {#get-jetbrains-teamcity-settings}

그룹에 대해 JetBrains TeamCity 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/teamcity
```

## Jira {#jira}

### Jira 설정 {#set-up-jira}

그룹에 대해 Jira 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/jira
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `url`           | 문자열 | 예 | 이 GitLab 프로젝트에 연결할 Jira 프로젝트의 URL입니다(예: `https://jira.example.com`). |
| `api_url`   | 문자열 | 아니오 | Jira 인스턴스 API의 기본 URL입니다. 설정되지 않은 경우 웹 URL 값이 사용됩니다(예: `https://jira-api.example.com`). |
| `username`      | 문자열 | 아니오   | Jira와 함께 사용할 이메일 또는 사용자 이름입니다. Jira Cloud는 이메일을, Jira Data Center와 Jira Server는 사용자 이름을 사용합니다. 기본 인증을 사용할 때 필수입니다(`jira_auth_type`이(가) `0`). |
| `password`      | 문자열 | 예  | Jira와 함께 사용할 Jira API 토큰, 비밀번호 또는 개인 액세스 토큰입니다. 인증 방법이 기본(`jira_auth_type`이(가) `0`)인 경우, Jira Cloud는 API 토큰을, Jira Data Center 또는 Jira Server는 비밀번호를 사용합니다. 인증 방법이 Jira 개인 액세스 토큰(`jira_auth_type`이(가) `1`)인 경우, 개인 액세스 토큰을 사용합니다. |
| `jira_auth_type`| 정수 | 아니오  | Jira와 함께 사용할 인증 방법입니다. `0`은(는) 기본 인증을 의미합니다. `1`은(는) Jira 개인 액세스 토큰을 의미합니다. `0`로 기본값이 설정됩니다. |
| `jira_issue_prefix` | 문자열 | 아니오 | Jira 이슈 키와 일치하는 접두사입니다. |
| `jira_issue_regex` | 문자열 | 아니오 | Jira 이슈 키와 일치하는 정규식입니다. |
| `jira_issue_transition_automatic` | 부울 | 아니오 | [자동 이슈 전환](../integration/jira/issues.md#automatic-issue-transitions)을(를) 활성화합니다. 활성화된 경우 `jira_issue_transition_id`보다 우선합니다. `false`로 기본값이 설정됩니다. |
| `jira_issue_transition_id` | 문자열 | 아니오 | [사용자 정의 이슈 전환](../integration/jira/issues.md#custom-issue-transitions)의 하나 이상의 전환 ID입니다. `jira_issue_transition_automatic`이(가) 활성화된 경우 무시됩니다. 기본값은 빈 문자열로, 사용자 정의 전환을 비활성화합니다. |
| `commit_events` | 부울 | 아니오 | 커밋 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니오 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `comment_on_event_enabled` | 부울 | 아니오 | 각 GitLab 이벤트(커밋 또는 머지 리퀘스트)에서 Jira 이슈의 주석을 활성화합니다. |
| `issues_enabled` | 부울 | 아니오 | GitLab에서 Jira 이슈를 볼 수 있도록 설정합니다. |
| `project_keys` | 문자열 배열 | 아니오 | Jira 프로젝트의 키입니다. `issues_enabled`이(가) `true`일 때, 이 설정은 GitLab에서 볼 이슈를 가져올 Jira 프로젝트를 지정합니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Jira 비활성화 {#disable-jira}

그룹에 대해 Jira 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/jira
```

### Jira 설정 가져오기 {#get-jira-settings}

그룹에 대해 Jira 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/jira
```

## Linear {#linear}

{{< history >}}

- [GitLab 18.3에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198297).

{{< /history >}}

### Linear 설정 {#set-up-linear}

그룹에 대해 Linear 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/linear
```

매개 변수:

| 매개 변수     | 유형   | 필수 | 설명    |
| ------------- | ------ | -------- | -------------- |
| `workspace_url`  | 문자열 | 예     | 이슈의 URL입니다.     |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Linear 비활성화 {#disable-linear}

그룹에 대해 Linear 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/linear
```

### Linear 설정 가져오기 {#get-linear-settings}

그룹에 대해 Linear 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/linear
```

## Matrix 알림 {#matrix-notifications}

### Matrix 알림 설정 {#set-up-matrix-notifications}

그룹에 대해 Matrix 알림을 설정합니다.

```plaintext
PUT /groups/:id/integrations/matrix
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `hostname`   | 문자열 | 아니오 | Matrix 서버의 사용자 정의 호스트 이름입니다. 기본값은 `https://matrix.org`입니다. |
| `token`   | 문자열 | 예 | Matrix 액세스 토큰(예: `syt-zyx57W2v1u123ew11`). |
| `room` | 문자열 | 예 | 대상 방의 고유 식별자(`!qPKKM111FFKKsfoCVy:matrix.org` 형식). |
| `notify_only_broken_pipelines` | 부울 | 아니오 | 손상된 파이프라인에 대한 알림을 보냅니다. |
| `notify_only_when_pipeline_status_changes` | 부울 | 아니오 | ref의 파이프라인 상태가 변경될 때만 알림을 보냅니다. |
| `branches_to_be_notified` | 문자열 | 아니오 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `push_events` | 부울 | 아니오 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `issues_events` | 부울 | 아니오 | 이슈 이벤트에 대한 알림을 활성화합니다. |
| `confidential_issues_events` | 부울 | 아니오 | 기밀 이슈 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니오 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니오 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `note_events` | 부울 | 아니오 | 노트 이벤트에 대한 알림을 활성화합니다. |
| `confidential_note_events` | 부울 | 아니오 | 기밀 노트 이벤트에 대한 알림을 활성화합니다. |
| `pipeline_events` | 부울 | 아니오 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `wiki_page_events` | 부울 | 아니오 | 위키 페이지 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Matrix 알림 비활성화 {#disable-matrix-notifications}

그룹에 대해 Matrix 알림을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/matrix
```

### Matrix 알림 설정 가져오기 {#get-matrix-notifications-settings}

그룹에 대해 Matrix 알림 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/matrix
```

## Mattermost 알림 {#mattermost-notifications}

### Mattermost 알림 설정 {#set-up-mattermost-notifications}

그룹에 대해 Mattermost 알림을 설정합니다.

```plaintext
PUT /groups/:id/integrations/mattermost
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 문자열 | 예 | Mattermost 알림 웹후크(예: `http://mattermost.example.com/hooks/...`). |
| `username` | 문자열 | 아니오 | Mattermost 알림 사용자 이름입니다. |
| `channel` | 문자열 | 아니오 | 다른 채널이 구성되지 않은 경우 사용할 기본 채널입니다. |
| `notify_only_broken_pipelines` | 부울 | 아니오 | 손상된 파이프라인에 대한 알림을 보냅니다. |
| `notify_only_when_pipeline_status_changes` | 부울 | 아니오 | ref의 파이프라인 상태가 변경될 때만 알림을 보냅니다. |
| `notify_only_default_branch` | 부울 | 아니오 | **더 이상 사용되지 않음**:  이 매개 변수는 `branches_to_be_notified`로 대체되었습니다. |
| `branches_to_be_notified` | 문자열 | 아니오 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `labels_to_be_notified` | 문자열 | 아니오 | 알림을 보낼 레이블입니다. 모든 이벤트에 대한 알림을 받도록 비워 둡니다. |
| `labels_to_be_notified_behavior` | 문자열 | 아니오 | 알림을 받을 레이블입니다. 유효한 옵션은 `match_any`과(와) `match_all`입니다. 기본값은 `match_any`입니다. |
| `push_events` | 부울 | 아니오 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `issues_events` | 부울 | 아니오 | 이슈 이벤트에 대한 알림을 활성화합니다. |
| `confidential_issues_events` | 부울 | 아니오 | 기밀 이슈 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니오 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니오 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `note_events` | 부울 | 아니오 | 노트 이벤트에 대한 알림을 활성화합니다. |
| `confidential_note_events` | 부울 | 아니오 | 기밀 노트 이벤트에 대한 알림을 활성화합니다. |
| `pipeline_events` | 부울 | 아니오 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `wiki_page_events` | 부울 | 아니오 | 위키 페이지 이벤트에 대한 알림을 활성화합니다. |
| `push_channel` | 문자열 | 아니오 | 푸시 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `issue_channel` | 문자열 | 아니오 | 이슈 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `confidential_issue_channel` | 문자열 | 아니오 | 기밀 이슈 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `merge_request_channel` | 문자열 | 아니오 | 머지 리퀘스트 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `note_channel` | 문자열 | 아니오 | 노트 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `confidential_note_channel` | 문자열 | 아니오 | 기밀 노트 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `tag_push_channel` | 문자열 | 아니오 | 태그 푸시 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `pipeline_channel` | 문자열 | 아니오 | 파이프라인 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `wiki_page_channel` | 문자열 | 아니오 | 위키 페이지 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Mattermost 알림 비활성화 {#disable-mattermost-notifications}

그룹에 대해 Mattermost 알림을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/mattermost
```

### Mattermost 알림 설정 가져오기 {#get-mattermost-notifications-settings}

그룹에 대해 Mattermost 알림 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/mattermost
```

## Mattermost 슬래시 명령 {#mattermost-slash-commands}

### Mattermost 슬래시 명령 설정 {#set-up-mattermost-slash-commands}

그룹에 대해 Mattermost 슬래시 명령을 설정합니다.

```plaintext
PUT /groups/:id/integrations/mattermost-slash-commands
```

매개 변수:

| 매개 변수 | 유형   | 필수 | 설명           |
| --------- | ------ | -------- | --------------------- |
| `token`   | 문자열 | 예      | Mattermost 토큰입니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Mattermost 슬래시 명령 비활성화 {#disable-mattermost-slash-commands}

그룹에 대해 Mattermost 슬래시 명령을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/mattermost-slash-commands
```

### Mattermost 슬래시 명령 설정 가져오기 {#get-mattermost-slash-commands-settings}

그룹에 대해 Mattermost 슬래시 명령 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/mattermost-slash-commands
```

## Microsoft Teams 알림 {#microsoft-teams-notifications}

### Microsoft Teams 알림 설정 {#set-up-microsoft-teams-notifications}

그룹에 대해 Microsoft Teams 알림을 설정합니다.

```plaintext
PUT /groups/:id/integrations/microsoft-teams
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 문자열 | 예 | Microsoft Teams 웹후크(예: `https://outlook.office.com/webhook/...`). |
| `notify_only_broken_pipelines` | 부울 | 아니오 | 손상된 파이프라인에 대한 알림을 보냅니다. |
| `notify_only_when_pipeline_status_changes` | 부울 | 아니오 | ref의 파이프라인 상태가 변경될 때만 알림을 보냅니다. |
| `notify_only_default_branch` | 부울 | 아니오 | **더 이상 사용되지 않음**:  이 매개 변수는 `branches_to_be_notified`로 대체되었습니다. |
| `branches_to_be_notified` | 문자열 | 아니오 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `push_events` | 부울 | 아니오 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `issues_events` | 부울 | 아니오 | 이슈 이벤트에 대한 알림을 활성화합니다. |
| `confidential_issues_events` | 부울 | 아니오 | 기밀 이슈 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니오 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니오 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `note_events` | 부울 | 아니오 | 노트 이벤트에 대한 알림을 활성화합니다. |
| `confidential_note_events` | 부울 | 아니오 | 기밀 노트 이벤트에 대한 알림을 활성화합니다. |
| `pipeline_events` | 부울 | 아니오 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `wiki_page_events` | 부울 | 아니오 | 위키 페이지 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Microsoft Teams 알림 비활성화 {#disable-microsoft-teams-notifications}

그룹에 대해 Microsoft Teams 알림을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/microsoft-teams
```

### Microsoft Teams 알림 설정 가져오기 {#get-microsoft-teams-notifications-settings}

그룹에 대해 Microsoft Teams 알림 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/microsoft-teams
```

## Mock CI {#mock-ci}

이 통합은 개발 환경에서만 사용 가능합니다. Mock CI 서버의 예는 [`gitlab-org/gitlab-mock-ci-service`](https://gitlab.com/gitlab-org/gitlab-mock-ci-service)을(를) 참조하세요.

### Mock CI 설정 {#set-up-mock-ci}

그룹에 대해 Mock CI 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/mock-ci
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `mock_service_url` | 문자열 | 예 | Mock CI 통합의 URL입니다. |
| `enable_ssl_verification` | 부울 | 아니오 | SSL 확인을 활성화합니다. `true`(활성화됨)으로 기본값이 지정됩니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Mock CI 비활성화 {#disable-mock-ci}

그룹에 대해 Mock CI 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/mock-ci
```

### Mock CI 설정 가져오기 {#get-mock-ci-settings}

그룹에 대해 Mock CI 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/mock-ci
```

## Packagist {#packagist}

### Packagist 설정 {#set-up-packagist}

그룹에 대해 Packagist 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/packagist
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `username` | 문자열 | 예 | Packagist 계정의 사용자 이름입니다. |
| `token` | 문자열 | 예 | Packagist 서버의 API 토큰입니다. |
| `server` | 부울 | 아니오 | Packagist 서버의 URL입니다. 기본값 `<https://packagist.org>`로 비워 둡니다. |
| `push_events` | 부울 | 아니오 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니오 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니오 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Packagist 비활성화 {#disable-packagist}

그룹에 대해 Packagist 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/packagist
```

### Packagist 설정 가져오기 {#get-packagist-settings}

그룹의 Packagist 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/packagist
```

## Phorge {#phorge}

### Phorge 설정 {#set-up-phorge}

그룹의 Phorge 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/phorge
```

매개 변수:

| 매개 변수       | 유형   | 필수 | 설명           |
|-----------------|--------|----------|-----------------------|
| `issues_url`    | 문자열 | 예     | 이슈의 URL입니다.     |
| `project_url`   | 문자열 | 예     | 프로젝트의 URL입니다.   |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Phorge 비활성화 {#disable-phorge}

그룹의 Phorge 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/phorge
```

### Phorge 설정 가져오기 {#get-phorge-settings}

그룹의 Phorge 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/phorge
```

## 파이프라인 상태 이메일 {#pipeline-status-emails}

### 파이프라인 상태 이메일 설정 {#set-up-pipeline-status-emails}

그룹의 파이프라인 상태 이메일을 설정합니다.

```plaintext
PUT /groups/:id/integrations/pipelines-email
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `recipients` | 문자열 | 예 | 쉼표로 구분된 수신자 이메일 주소 목록입니다. |
| `notify_only_broken_pipelines` | 부울 | 아니오 | 손상된 파이프라인에 대한 알림을 보냅니다. |
| `branches_to_be_notified` | 문자열 | 아니오 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `notify_only_default_branch` | 부울 | 아니오 | 기본 브랜치에 대한 알림을 전송합니다. |
| `pipeline_events` | 부울 | 아니오 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### 파이프라인 상태 이메일 비활성화 {#disable-pipeline-status-emails}

그룹의 파이프라인 상태 이메일을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/pipelines-email
```

### 파이프라인 상태 이메일 설정 가져오기 {#get-pipeline-status-emails-settings}

그룹의 파이프라인 상태 이메일 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/pipelines-email
```

## Pivotal Tracker {#pivotal-tracker}

### Pivotal Tracker 설정 {#set-up-pivotal-tracker}

그룹의 Pivotal Tracker 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/pivotaltracker
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `token` | 문자열 | 예 | Pivotal Tracker 토큰입니다. |
| `restrict_to_branch` | 부울 | 아니오 | 자동으로 검사할 브랜치의 쉼표로 구분된 목록입니다. 모든 브랜치를 포함하려면 비워 둡니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Pivotal Tracker 비활성화 {#disable-pivotal-tracker}

그룹의 Pivotal Tracker 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/pivotaltracker
```

### Pivotal Tracker 설정 가져오기 {#get-pivotal-tracker-settings}

그룹의 Pivotal Tracker 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/pivotaltracker
```

## Pumble {#pumble}

### Pumble 설정 {#set-up-pumble}

그룹의 Pumble 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/pumble
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 문자열 | 예 | Pumble 웹후크 (예: `https://api.pumble.com/workspaces/x/...`). |
| `branches_to_be_notified` | 문자열 | 아니오 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `confidential_issues_events` | 부울 | 아니오 | 기밀 이슈 이벤트에 대한 알림을 활성화합니다. |
| `confidential_note_events` | 부울 | 아니오 | 기밀 노트 이벤트에 대한 알림을 활성화합니다. |
| `issues_events` | 부울 | 아니오 | 이슈 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니오 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `note_events` | 부울 | 아니오 | 노트 이벤트에 대한 알림을 활성화합니다. |
| `notify_only_broken_pipelines` | 부울 | 아니오 | 손상된 파이프라인에 대한 알림을 보냅니다. |
| `notify_only_when_pipeline_status_changes` | 부울 | 아니오 | ref의 파이프라인 상태가 변경될 때만 알림을 보냅니다. |
| `pipeline_events` | 부울 | 아니오 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `push_events` | 부울 | 아니오 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니오 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `wiki_page_events` | 부울 | 아니오 | 위키 페이지 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Pumble 비활성화 {#disable-pumble}

그룹의 Pumble 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/pumble
```

### Pumble 설정 가져오기 {#get-pumble-settings}

그룹의 Pumble 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/pumble
```

## Pushover {#pushover}

### Pushover 설정 {#set-up-pushover}

그룹의 Pushover 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/pushover
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `api_key` | 문자열 | 예 | 응용 프로그램 키입니다. |
| `user_key` | 문자열 | 예 | 사용자 키입니다. |
| `priority` | 문자열 | 예 | 우선순위입니다. |
| `device` | 문자열 | 아니오 | 모든 활성 장치는 공백으로 두세요. |
| `sound` | 문자열 | 아니오 | 알림의 음성입니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Pushover 비활성화 {#disable-pushover}

그룹의 Pushover 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/pushover
```

### Pushover 설정 가져오기 {#get-pushover-settings}

그룹의 Pushover 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/pushover
```

## Redmine {#redmine}

### Redmine 설정 {#set-up-redmine}

그룹의 Redmine 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/redmine
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | 문자열 | 예 | 새 이슈의 URL입니다. |
| `project_url` | 문자열 | 예 | 프로젝트의 URL입니다. |
| `issues_url` | 문자열 | 예 | 이슈의 URL입니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Redmine 비활성화 {#disable-redmine}

그룹의 Redmine 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/redmine
```

### Redmine 설정 가져오기 {#get-redmine-settings}

그룹의 Redmine 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/redmine
```

## Slack 알림 {#slack-notifications}

### Slack 알림 설정 {#set-up-slack-notifications}

그룹의 Slack 알림을 설정합니다.

```plaintext
PUT /groups/:id/integrations/slack
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 문자열 | 예 | Slack 알림 웹후크 (예: `https://hooks.slack.com/services/...`). |
| `username` | 문자열 | 아니오 | Slack 알림 사용자 이름입니다. |
| `channel` | 문자열 | 아니오 | 다른 채널이 구성되지 않은 경우 사용할 기본 채널입니다. |
| `notify_only_broken_pipelines` | 부울 | 아니오 | 손상된 파이프라인에 대한 알림을 보냅니다. |
| `notify_only_when_pipeline_status_changes` | 부울 | 아니오 | ref의 파이프라인 상태가 변경될 때만 알림을 보냅니다. |
| `notify_only_default_branch` | 부울 | 아니오 | **더 이상 사용되지 않음**:  이 매개 변수는 `branches_to_be_notified`로 대체되었습니다. |
| `branches_to_be_notified` | 문자열 | 아니오 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `labels_to_be_notified` | 문자열 | 아니오 | 알림을 보낼 레이블입니다. 모든 이벤트에 대한 알림을 받도록 비워 둡니다. |
| `labels_to_be_notified_behavior` | 문자열 | 아니오 | 알림을 받을 레이블입니다. 유효한 옵션은 `match_any`과(와) `match_all`입니다. 기본값은 `match_any`입니다. |
| `alert_channel` | 문자열 | 아니오 | 경고 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `alert_events` | 부울 | 아니오 | 경고 이벤트에 대한 알림을 활성화합니다. |
| `commit_events` | 부울 | 아니오 | 커밋 이벤트에 대한 알림을 활성화합니다. |
| `confidential_issue_channel` | 문자열 | 아니오 | 기밀 이슈 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `confidential_issues_events` | 부울 | 아니오 | 기밀 이슈 이벤트에 대한 알림을 활성화합니다. |
| `confidential_note_channel` | 문자열 | 아니오 | 기밀 노트 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `confidential_note_events` | 부울 | 아니오 | 기밀 노트 이벤트에 대한 알림을 활성화합니다. |
| `deployment_channel` | 문자열 | 아니오 | 배포 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `deployment_events` | 부울 | 아니오 | 배포 이벤트에 대한 알림을 활성화합니다. |
| `incident_channel` | 문자열 | 아니오 | 인시던트 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `incidents_events` | 부울 | 아니오 | 인시던트 이벤트에 대한 알림을 활성화합니다. |
| `issue_channel` | 문자열 | 아니오 | 이슈 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `issues_events` | 부울 | 아니오 | 이슈 이벤트에 대한 알림을 활성화합니다. |
| `job_events` | 부울 | 아니오 | 작업 이벤트에 대한 알림을 활성화합니다. |
| `merge_request_channel` | 문자열 | 아니오 | 머지 리퀘스트 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `merge_requests_events` | 부울 | 아니오 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `note_channel` | 문자열 | 아니오 | 노트 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `note_events` | 부울 | 아니오 | 노트 이벤트에 대한 알림을 활성화합니다. |
| `pipeline_channel` | 문자열 | 아니오 | 파이프라인 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `pipeline_events` | 부울 | 아니오 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `push_channel` | 문자열 | 아니오 | 푸시 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `push_events` | 부울 | 아니오 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_channel` | 문자열 | 아니오 | 태그 푸시 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `tag_push_events` | 부울 | 아니오 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `wiki_page_channel` | 문자열 | 아니오 | 위키 페이지 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `wiki_page_events` | 부울 | 아니오 | 위키 페이지 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Slack 알림 비활성화 {#disable-slack-notifications}

그룹의 Slack 알림을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/slack
```

### Slack 알림 설정 가져오기 {#get-slack-notifications-settings}

그룹의 Slack 알림 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/slack
```

## Squash TM {#squash-tm}

### Squash TM 설정 {#set-up-squash-tm}

그룹의 Squash TM 통합 설정을 설정합니다.

```plaintext
PUT /groups/:id/integrations/squash-tm
```

매개 변수:

| 매개 변수               | 유형   | 필수 | 설명                   |
|-------------------------|--------|----------|-------------------------------|
| `url`                   | 문자열 | 예      | Squash TM 웹후크의 URL입니다. |
| `token`                 | 문자열 | 아니오       | 비밀 토큰입니다.                 |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Squash TM 비활성화 {#disable-squash-tm}

그룹의 Squash TM 통합을 비활성화합니다. 통합 설정이 유지됩니다.

```plaintext
DELETE /groups/:id/integrations/squash-tm
```

### Squash TM 설정 가져오기 {#get-squash-tm-settings}

그룹의 Squash TM 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/squash-tm
```

## Telegram {#telegram}

### Telegram 설정 {#set-up-telegram}

그룹의 Telegram 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/telegram
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `hostname`   | 문자열 | 아니오 | Telegram API의 사용자 지정 호스트 이름입니다. 기본값은 `https://api.telegram.org`입니다. |
| `token`   | 문자열 | 예 | Telegram 봇 토큰입니다 (예: `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`). |
| `room` | 문자열 | 예 | 대상 채팅의 고유 식별자 또는 대상 채널의 사용자 이름입니다 (`@channelusername` 형식). |
| `thread` | 정수 | 아니오 | 대상 메시지 스레드 (포럼 슈퍼그룹의 주제)의 고유 식별자입니다. |
| `notify_only_broken_pipelines` | 부울 | 아니오 | 손상된 파이프라인에 대한 알림을 보냅니다. |
| `notify_only_when_pipeline_status_changes` | 부울 | 아니오 | ref의 파이프라인 상태가 변경될 때만 알림을 보냅니다. |
| `branches_to_be_notified` | 문자열 | 아니오 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `push_events` | 부울 | 예 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `issues_events` | 부울 | 예 | 이슈 이벤트에 대한 알림을 활성화합니다. |
| `confidential_issues_events` | 부울 | 예 | 기밀 이슈 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 예 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 예 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `note_events` | 부울 | 예 | 노트 이벤트에 대한 알림을 활성화합니다. |
| `confidential_note_events` | 부울 | 예 | 기밀 노트 이벤트에 대한 알림을 활성화합니다. |
| `pipeline_events` | 부울 | 예 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `wiki_page_events` | 부울 | 예 | 위키 페이지 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Telegram 비활성화 {#disable-telegram}

그룹의 Telegram 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/telegram
```

### Telegram 설정 가져오기 {#get-telegram-settings}

그룹의 Telegram 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/telegram
```

## Unify Circuit {#unify-circuit}

### Unify Circuit 설정 {#set-up-unify-circuit}

그룹의 Unify Circuit 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/unify-circuit
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 문자열 | 예 | Unify Circuit 웹후크 (예: `https://circuit.com/rest/v2/webhooks/incoming/...`). |
| `notify_only_broken_pipelines` | 부울 | 아니오 | 손상된 파이프라인에 대한 알림을 보냅니다. |
| `notify_only_when_pipeline_status_changes` | 부울 | 아니오 | ref의 파이프라인 상태가 변경될 때만 알림을 보냅니다. |
| `branches_to_be_notified` | 문자열 | 아니오 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `push_events` | 부울 | 아니오 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `issues_events` | 부울 | 아니오 | 이슈 이벤트에 대한 알림을 활성화합니다. |
| `confidential_issues_events` | 부울 | 아니오 | 기밀 이슈 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니오 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니오 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `note_events` | 부울 | 아니오 | 노트 이벤트에 대한 알림을 활성화합니다. |
| `confidential_note_events` | 부울 | 아니오 | 기밀 노트 이벤트에 대한 알림을 활성화합니다. |
| `pipeline_events` | 부울 | 아니오 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `wiki_page_events` | 부울 | 아니오 | 위키 페이지 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Unify Circuit 비활성화 {#disable-unify-circuit}

그룹의 Unify Circuit 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/unify-circuit
```

### Unify Circuit 설정 가져오기 {#get-unify-circuit-settings}

그룹의 Unify Circuit 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/unify-circuit
```

## Webex Teams {#webex-teams}

### Webex Teams 설정 {#set-up-webex-teams}

그룹의 Webex Teams를 설정합니다.

```plaintext
PUT /groups/:id/integrations/webex-teams
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 문자열 | 예 | Webex Teams 웹후크 (예: `https://api.ciscospark.com/v1/webhooks/incoming/...`). |
| `notify_only_broken_pipelines` | 부울 | 아니오 | 손상된 파이프라인에 대한 알림을 보냅니다. |
| `notify_only_when_pipeline_status_changes` | 부울 | 아니오 | ref의 파이프라인 상태가 변경될 때만 알림을 보냅니다. |
| `branches_to_be_notified` | 문자열 | 아니오 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `push_events` | 부울 | 아니오 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `issues_events` | 부울 | 아니오 | 이슈 이벤트에 대한 알림을 활성화합니다. |
| `confidential_issues_events` | 부울 | 아니오 | 기밀 이슈 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니오 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니오 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `note_events` | 부울 | 아니오 | 노트 이벤트에 대한 알림을 활성화합니다. |
| `confidential_note_events` | 부울 | 아니오 | 기밀 노트 이벤트에 대한 알림을 활성화합니다. |
| `pipeline_events` | 부울 | 아니오 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `wiki_page_events` | 부울 | 아니오 | 위키 페이지 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Webex Teams 비활성화 {#disable-webex-teams}

그룹의 Webex Teams를 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/webex-teams
```

### Webex Teams 설정 가져오기 {#get-webex-teams-settings}

그룹의 Webex Teams 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/webex-teams
```

## YouTrack {#youtrack}

### YouTrack 설정 {#set-up-youtrack}

그룹의 YouTrack 통합을 설정합니다.

```plaintext
PUT /groups/:id/integrations/youtrack
```

매개 변수:

| 매개 변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `issues_url` | 문자열 | 예 | 이슈의 URL입니다. |
| `project_url` | 문자열 | 예 | 프로젝트의 URL입니다. |
| `use_inherited_settings` | 부울 | 아니오 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### YouTrack 비활성화 {#disable-youtrack}

그룹의 YouTrack 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /groups/:id/integrations/youtrack
```

### YouTrack 설정 가져오기 {#get-youtrack-settings}

그룹의 YouTrack 통합 설정을 가져옵니다.

```plaintext
GET /groups/:id/integrations/youtrack
```
