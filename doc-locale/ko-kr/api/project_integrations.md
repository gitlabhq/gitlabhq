---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 통합 API
description: "REST API로 프로젝트의 통합을 설정하고 관리합니다."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 프로젝트의 [통합](../user/project/integrations/_index.md)을 관리합니다.

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 있어야 합니다.

## 모든 활성 통합 나열 {#list-all-active-integrations}

{{< history >}}

- `vulnerability_events` 필드가 GitLab 16.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131831)되었습니다.
- `inherited` 필드가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154915) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `inherited` 필드는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

모든 활성 프로젝트 통합 목록을 가져옵니다. `vulnerability_events` 필드는 GitLab Enterprise Edition에서만 사용 가능합니다.

```plaintext
GET /projects/:id/integrations
```

응답 예시:

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

## Apple App Store Connect {#apple-app-store-connect}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Apple App Store Connect 설정 {#set-up-apple-app-store-connect}

프로젝트에 대한 Apple App Store Connect 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/apple_app_store
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `app_store_issuer_id` | 문자열 | 예 | Apple App Store Connect 발급자 ID입니다. |
| `app_store_key_id` | 문자열 | 예 | Apple App Store Connect 키 ID입니다. |
| `app_store_private_key_file_name` | 문자열 | 예 | Apple App Store Connect 개인 키 파일 이름입니다. |
| `app_store_private_key` | 문자열 | 예 | Apple App Store Connect 개인 키입니다. |
| `app_store_protected_refs` | 부울 | 아니요 | 보호된 브랜치 및 태그에만 변수를 설정합니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Apple App Store Connect 비활성화 {#disable-apple-app-store-connect}

프로젝트에 대한 Apple App Store Connect 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/apple_app_store
```

### Apple App Store Connect 설정 가져오기 {#get-apple-app-store-connect-settings}

프로젝트에 대한 Apple App Store Connect 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/apple_app_store
```

## Asana {#asana}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Asana 설정 {#set-up-asana}

프로젝트에 대한 Asana 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/asana
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `api_key` | 문자열 | 예 | 사용자 API 토큰입니다. 사용자가 작업에 액세스할 수 있어야 합니다. 모든 댓글은 이 사용자에게 귀속됩니다. |
| `restrict_to_branch` | 문자열 | 아니요 | 자동으로 검사할 쉼표로 구분된 브랜치 목록입니다. 모든 브랜치를 포함하려면 공백으로 두세요. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Asana 비활성화 {#disable-asana}

프로젝트에 대한 Asana 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/asana
```

### Asana 설정 가져오기 {#get-asana-settings}

프로젝트에 대한 Asana 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/asana
```

## Assembla {#assembla}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Assembla 설정 {#set-up-assembla}

프로젝트에 대한 Assembla 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/assembla
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `token` | 문자열 | 예 | 인증 토큰입니다. |
| `subdomain` | 문자열 | 아니요 | 서브도메인 설정입니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Assembla 비활성화 {#disable-assembla}

프로젝트에 대한 Assembla 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/assembla
```

### Assembla 설정 가져오기 {#get-assembla-settings}

프로젝트에 대한 Assembla 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/assembla
```

## Atlassian Bamboo {#atlassian-bamboo}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Atlassian Bamboo 설정 {#set-up-atlassian-bamboo}

프로젝트에 대한 Atlassian Bamboo 통합을 설정합니다.

Bamboo에서 자동 리비전 레이블 지정 및 리포지토리 트리거를 구성해야 합니다.

```plaintext
PUT /projects/:id/integrations/bamboo
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `bamboo_url` | 문자열 | 예 | Bamboo 루트 URL(예: `https://bamboo.example.com`)입니다. |
| `enable_ssl_verification` | 부울 | 아니요 | SSL 검증을 활성화합니다. `true`(활성화됨)을 기본값으로 사용합니다. |
| `build_key` | 문자열 | 예 | Bamboo 빌드 계획 키(예: `KEY`)입니다. |
| `username` | 문자열 | 예 | Bamboo 서버에 대한 API 액세스 권한이 있는 사용자입니다. |
| `password` | 문자열 | 예 | 사용자의 비밀번호입니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Atlassian Bamboo 비활성화 {#disable-atlassian-bamboo}

프로젝트에 대한 Atlassian Bamboo 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/bamboo
```

### Atlassian Bamboo 설정 가져오기 {#get-atlassian-bamboo-settings}

프로젝트에 대한 Atlassian Bamboo 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/bamboo
```

## Bugzilla {#bugzilla}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Bugzilla 설정 {#set-up-bugzilla}

프로젝트에 대한 Bugzilla 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/bugzilla
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | 문자열 | 예 |  새 이슈의 URL입니다. |
| `issues_url` | 문자열 | 예 | 이슈의 URL입니다. |
| `project_url` | 문자열 | 예 | 프로젝트의 URL입니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Bugzilla 비활성화 {#disable-bugzilla}

프로젝트에 대한 Bugzilla 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/bugzilla
```

### Bugzilla 설정 가져오기 {#get-bugzilla-settings}

프로젝트에 대한 Bugzilla 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/bugzilla
```

## Buildkite {#buildkite}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Buildkite 설정 {#set-up-buildkite}

프로젝트에 대한 Buildkite 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/buildkite
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `token` | 문자열 | 예 | GitLab 리포지토리를 사용하여 Buildkite 파이프라인을 만든 후 가져오는 토큰입니다. |
| `project_url` | 문자열 | 예 | 파이프라인 URL(예: `https://buildkite.com/example/pipeline`)입니다. |
| `enable_ssl_verification` | 부울 | 아니요 | **더 이상 사용되지 않음**:  이 매개변수는 SSL 검증이 항상 활성화되어 있으므로 효과가 없습니다. |
| `push_events` | 부울 | 아니요 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니요 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니요 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Buildkite 비활성화 {#disable-buildkite}

프로젝트에 대한 Buildkite 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/buildkite
```

### Buildkite 설정 가져오기 {#get-buildkite-settings}

프로젝트에 대한 Buildkite 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/buildkite
```

## Campfire Classic {#campfire-classic}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

Campfire Classic과 통합할 수 있습니다. 그러나 Campfire Classic은 Basecamp에서 [더 이상 판매하지 않는](https://gitlab.com/gitlab-org/gitlab/-/issues/329337) 오래된 제품입니다.

### Campfire Classic 설정 {#set-up-campfire-classic}

프로젝트에 대한 Campfire Classic 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/campfire
```

매개변수:

| 매개변수     | 유형    | 필수 | 설명                                                                                 |
|---------------|---------|----------|---------------------------------------------------------------------------------------------|
| `token`       | 문자열  | 예     | Campfire Classic의 API 인증 토큰입니다. 토큰을 얻으려면 Campfire Classic에 로그인하여 **My info**를 선택하세요. |
| `subdomain`   | 문자열  | 아니요    | 로그인했을 때 `.campfirenow.com` 서브도메인입니다. |
| `room`        | 문자열  | 아니요    | Campfire Classic 대화방 URL의 ID 부분입니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Campfire Classic 비활성화 {#disable-campfire-classic}

프로젝트에 대한 Campfire Classic 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/campfire
```

### Campfire Classic 설정 가져오기 {#get-campfire-classic-settings}

프로젝트에 대한 Campfire Classic 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/campfire
```

## ClickUp {#clickup}

{{< history >}}

- [GitLab 16.1에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120732).
- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### ClickUp 설정 {#set-up-clickup}

프로젝트에 대한 ClickUp 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/clickup
```

매개변수:

| 매개변수     | 유형   | 필수 | 설명    |
| ------------- | ------ | -------- | -------------- |
| `issues_url`  | 문자열 | 예     | 이슈의 URL입니다.     |
| `project_url` | 문자열 | 예     | 프로젝트의 URL입니다.   |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### ClickUp 비활성화 {#disable-clickup}

프로젝트에 대한 ClickUp 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/clickup
```

### ClickUp 설정 가져오기 {#get-clickup-settings}

프로젝트에 대한 ClickUp 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/clickup
```

## Confluence Workspace {#confluence-workspace}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

Confluence Cloud Workspace를 프로젝트 위키로 사용합니다.

### Confluence Workspace 설정 {#set-up-confluence-workspace}

프로젝트에 대한 Confluence Workspace 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/confluence
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `confluence_url` | 문자열 | 예 | `atlassian.net`에서 호스팅되는 Confluence Workspace의 URL입니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Confluence Workspace 비활성화 {#disable-confluence-workspace}

프로젝트에 대한 Confluence Workspace 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/confluence
```

### Confluence Workspace 설정 가져오기 {#get-confluence-workspace-settings}

프로젝트에 대한 Confluence Workspace 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/confluence
```

## 사용자 정의 이슈 추적기 {#custom-issue-tracker}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### 사용자 정의 이슈 추적기 설정 {#set-up-a-custom-issue-tracker}

프로젝트에 대한 사용자 정의 이슈 추적기를 설정합니다.

```plaintext
PUT /projects/:id/integrations/custom-issue-tracker
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | 문자열 | 예 |  새 이슈의 URL입니다. |
| `issues_url` | 문자열 | 예 | 이슈의 URL입니다. |
| `project_url` | 문자열 | 예 | 프로젝트의 URL입니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### 사용자 정의 이슈 추적기 비활성화 {#disable-a-custom-issue-tracker}

프로젝트에 대한 사용자 정의 이슈 추적기를 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/custom-issue-tracker
```

### 사용자 정의 이슈 추적기 설정 가져오기 {#get-custom-issue-tracker-settings}

프로젝트에 대한 사용자 정의 이슈 추적기 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/custom-issue-tracker
```

## Datadog {#datadog}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Datadog 설정 {#set-up-datadog}

프로젝트에 대한 Datadog 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/datadog
```

매개변수:

| 매개변수              | 유형    | 필수 | 설명                                                                                                                                                                            |
|------------------------|---------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `api_key`              | 문자열  | 예     | Datadog 인증에 사용되는 [API 키](https://docs.datadoghq.com/account_management/api-app-keys/)입니다. |
| `datadog_ci_visibility`| 부울 | 예     | Datadog에서 파이프라인 및 작업 이벤트 수집을 활성화하여 파이프라인 실행 추적을 표시합니다. |
| `api_url`              | 문자열  | 아니요    | Datadog 사이트의 전체 URL입니다. |
| `datadog_env`          | 문자열  | 아니요    | 자체 관리형 배포의 경우 Datadog로 전송되는 모든 데이터에 대한 `env%` 태그입니다. |
| `datadog_service`      | 문자열  | 아니요    | Datadog에서 모든 데이터를 태그할 GitLab 인스턴스입니다. 여러 자체 관리형 배포를 관리할 때 사용할 수 있습니다. |
| `datadog_site`         | 문자열  | 아니요    | 데이터를 전송할 Datadog 사이트입니다. EU 사이트로 데이터를 전송하려면 `datadoghq.eu`을(를) 사용합니다. |
| `datadog_tags`         | 문자열  | 아니요    | Datadog의 사용자 정의 태그입니다. 한 줄에 하나의 태그를 `key:value\nkey2:value2` 형식으로 지정합니다. |
| `archive_trace_events` | 부울 | 아니요    | 활성화되면 작업 로그가 Datadog에 의해 수집되고 파이프라인 실행 추적과 함께 표시됩니다([GitLab 15.3에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/346339)). |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Datadog 비활성화 {#disable-datadog}

프로젝트에 대한 Datadog 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/datadog
```

### Datadog 설정 가져오기 {#get-datadog-settings}

프로젝트에 대한 Datadog 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/datadog
```

## Diffblue Cover {#diffblue-cover}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Diffblue Cover 설정 {#set-up-diffblue-cover}

프로젝트에 대한 Diffblue Cover 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/diffblue-cover
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `diffblue_license_key` | 문자열 | 예 | Diffblue Cover 라이선스 키입니다. |
| `diffblue_access_token_name` | 문자열 | 예 | 파이프라인에서 Diffblue Cover에서 사용하는 액세스 토큰 이름입니다. |
| `diffblue_access_token_secret` | 문자열  | 예 | 파이프라인에서 Diffblue Cover에서 사용하는 액세스 토큰 비밀입니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Diffblue Cover 비활성화 {#disable-diffblue-cover}

프로젝트에 대한 Diffblue Cover 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/diffblue-cover
```

### Diffblue Cover 설정 가져오기 {#get-diffblue-cover-settings}

프로젝트에 대한 Diffblue Cover 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/diffblue-cover
```

## Discord 알림 {#discord-notifications}

{{< history >}}

- `_channel` 매개변수가 GitLab 16.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125621)되었습니다.
- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Discord 알림 설정 {#set-up-discord-notifications}

프로젝트에 대한 Discord 알림을 설정합니다.

```plaintext
PUT /projects/:id/integrations/discord
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 문자열 | 예 | Discord 웹후크(예: `https://discord.com/api/webhooks/...`)입니다. |
| `branches_to_be_notified` | 문자열 | 아니요 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `confidential_issues_events` | 부울 | 아니요 | 기밀 이슈 이벤트에 대한 알림을 활성화합니다. |
| `confidential_issue_channel` | 문자열 | 아니요 | 기밀 이슈 이벤트에 대한 알림을 받기 위한 웹후크 재정의입니다. |
| `confidential_note_events` | 부울 | 아니요 | 기밀 노트 이벤트에 대한 알림을 활성화합니다. |
| `confidential_note_channel` | 문자열 | 아니요 | 기밀 노트 이벤트에 대한 알림을 받기 위한 웹후크 재정의입니다. |
| `deployment_events` | 부울 | 아니요 | 배포 이벤트에 대한 알림을 활성화합니다. |
| `deployment_channel` | 문자열 | 아니요 | 배포 이벤트에 대한 알림을 받기 위한 웹후크 재정의입니다. |
| `group_confidential_mentions_events` | 부울 | 아니요 | 그룹 기밀 언급 이벤트에 대한 알림을 활성화합니다. |
| `group_confidential_mentions_channel` | 문자열 | 아니요 | 그룹 기밀 언급 이벤트에 대한 알림을 받기 위한 웹후크 재정의입니다. |
| `group_mentions_events` | 부울 | 아니요 | 그룹 언급 이벤트에 대한 알림을 활성화합니다. |
| `group_mentions_channel` | 문자열 | 아니요 | 그룹 언급 이벤트에 대한 알림을 받기 위한 웹후크 재정의입니다. |
| `issues_events` | 부울 | 아니요 | 이슈 이벤트에 대한 알림을 활성화합니다. |
| `issue_channel` | 문자열 | 아니요 | 이슈 이벤트에 대한 알림을 받기 위한 웹후크 재정의입니다. |
| `merge_requests_events` | 부울 | 아니요 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `merge_request_channel` | 문자열 | 아니요 | 머지 리퀘스트 이벤트에 대한 알림을 받기 위한 웹후크 재정의입니다. |
| `note_events` | 부울 | 아니요 | 노트 이벤트에 대한 알림을 활성화합니다. |
| `note_channel` | 문자열 | 아니요 | 노트 이벤트에 대한 알림을 받기 위한 웹후크 재정의입니다. |
| `notify_only_broken_pipelines` | 부울 | 아니요 | 실패한 파이프라인에 대한 알림을 전송합니다. |
| `notify_only_when_pipeline_status_changes` | 부울 | 아니요 | ref의 파이프라인 상태가 변경될 때만 알림을 전송합니다. |
| `pipeline_events` | 부울 | 아니요 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `pipeline_channel` | 문자열 | 아니요 | 파이프라인 이벤트에 대한 알림을 받기 위한 웹후크 재정의입니다. |
| `push_events` | 부울 | 아니요 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `push_channel` | 문자열 | 아니요 | 푸시 이벤트에 대한 알림을 받기 위한 웹후크 재정의입니다. |
| `tag_push_events` | 부울 | 아니요 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_channel` | 문자열 | 아니요 | 태그 푸시 이벤트에 대한 알림을 받기 위한 웹후크 재정의입니다. |
| `wiki_page_events` | 부울 | 아니요 | 위키 페이지 이벤트에 대한 알림을 활성화합니다. |
| `wiki_page_channel` | 문자열 | 아니요 | 위키 페이지 이벤트에 대한 알림을 받기 위한 웹후크 재정의입니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Discord 알림 비활성화 {#disable-discord-notifications}

프로젝트에 대한 Discord 알림을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/discord
```

### Discord 알림 설정 가져오기 {#get-discord-notifications-settings}

프로젝트에 대한 Discord 알림 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/discord
```

## Drone {#drone}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Drone 설정 {#set-up-drone}

프로젝트에 대한 Drone 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/drone-ci
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `token` | 문자열 | 예 | Drone CI 토큰입니다. |
| `drone_url` | 문자열 | 예 | Drone CI URL(예: `http://drone.example.com`)입니다. |
| `enable_ssl_verification` | 부울 | 아니요 | SSL 검증을 활성화합니다. `true`(활성화됨)을 기본값으로 사용합니다. |
| `push_events` | 부울 | 아니요 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니요 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니요 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Drone 비활성화 {#disable-drone}

프로젝트에 대한 Drone 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/drone-ci
```

### Drone 설정 가져오기 {#get-drone-settings}

프로젝트에 대한 Drone 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/drone-ci
```

## 푸시 시 이메일 {#emails-on-push}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### 푸시 시 이메일 설정 {#set-up-emails-on-push}

프로젝트에 대한 푸시 시 이메일 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/emails-on-push
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `recipients` | 문자열 | 예 | 공백으로 구분된 이메일입니다. |
| `disable_diffs` | 부울 | 아니요 | 코드 차이를 비활성화합니다. |
| `send_from_committer_email` | 부울 | 아니요 | 커미터에서 보냅니다. |
| `push_events` | 부울 | 아니요 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니요 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `branches_to_be_notified` | 문자열 | 아니요 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 태그 푸시의 경우 항상 알림이 발생합니다. 기본값은 `all`입니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### 푸시 시 이메일 비활성화 {#disable-emails-on-push}

프로젝트에 대한 푸시 시 이메일 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/emails-on-push
```

### 푸시 시 이메일 설정 가져오기 {#get-emails-on-push-settings}

프로젝트에 대한 푸시 시 이메일 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/emails-on-push
```

## 엔지니어링 워크플로우 관리(EWM) {#engineering-workflow-management-ewm}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### EWM 설정 {#set-up-ewm}

프로젝트에 대한 EWM 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/ewm
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | 문자열 | 예 | 새 이슈의 URL입니다. |
| `project_url`   | 문자열 | 예 | 프로젝트의 URL입니다. |
| `issues_url`    | 문자열 | 예 | 이슈의 URL입니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### EWM 비활성화 {#disable-ewm}

프로젝트에 대한 EWM 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/ewm
```

### EWM 설정 가져오기 {#get-ewm-settings}

프로젝트에 대한 EWM 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/ewm
```

## 외부 위키 {#external-wiki}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### 외부 위키 설정 {#set-up-an-external-wiki}

프로젝트에 대한 외부 위키를 설정합니다.

```plaintext
PUT /projects/:id/integrations/external-wiki
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `external_wiki_url` | 문자열 | 예 | 외부 위키의 URL입니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### 외부 위키 비활성화 {#disable-an-external-wiki}

프로젝트에 대한 외부 위키를 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/external-wiki
```

### 외부 위키 설정 가져오기 {#get-external-wiki-settings}

프로젝트에 대한 외부 위키 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/external-wiki
```

## GitGuardian {#gitguardian}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `git_guardian_integration`라는 이름의 [플래그와 함께](../administration/feature_flags/_index.md) [GitLab 16.9에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/435706). 기본적으로 활성화됨. GitLab.com에서 비활성화되었습니다.
- GitLab 17.7에서 GitLab.com에서 [활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/438695#note_2226917025)되었습니다.
- GitLab 17.8에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176391)합니다. 기능 플래그 `git_guardian_integration` 제거됨.
- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

[GitGuardian](https://www.gitguardian.com/)은 API 키 및 비밀번호와 같은 민감한 데이터를 소스 코드 리포지토리에서 탐지하는 사이버 보안 서비스입니다. Git 리포지토리를 스캔하고 정책 위반을 경고하며 조직이 해커가 악용할 수 있는 보안 이슈를 수정하기 전에 해결할 수 있습니다.

GitGuardian 정책을 기반으로 커밋을 거부하도록 GitLab을 구성할 수 있습니다.

알려진 이슈 및 이슈 해결 단계는 [GitGuardian 이슈 해결](../user/project/integrations/git_guardian.md#troubleshooting)을 참조하세요.

### GitGuardian 설정 {#set-up-gitguardian}

프로젝트에 대한 GitGuardian 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/git-guardian
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명                                   |
| --------- | ---- | -------- |-----------------------------------------------|
| `token` | 문자열 | 예 | `scan` 범위가 있는 GitGuardian API 토큰입니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### GitGuardian 비활성화 {#disable-gitguardian}

프로젝트에 대한 GitGuardian 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/git-guardian
```

### GitGuardian 설정 가져오기 {#get-gitguardian-settings}

프로젝트에 대한 GitGuardian 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/git-guardian
```

## GitHub {#github}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### GitHub 설정 {#set-up-github}

프로젝트에 대한 GitHub 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/github
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `token` | 문자열 | 예 | `repo:status` OAuth 범위가 있는 GitHub API 토큰입니다. |
| `repository_url` | 문자열 | 예 | GitHub 리포지토리 URL입니다. |
| `static_context` | 부울 | 아니요 | GitLab 인스턴스의 호스트 이름을 [상태 확인 이름](../user/project/integrations/github.md#static-or-dynamic-status-check-names)에 추가합니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### GitHub 비활성화 {#disable-github}

프로젝트의 GitHub 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/github
```

### GitHub 설정 보기 {#get-github-settings}

프로젝트의 GitHub 통합 설정을 보여줍니다.

```plaintext
GET /projects/:id/integrations/github
```

## GitLab for Jira Cloud 앱 {#gitlab-for-jira-cloud-app}

GitLab for Jira Cloud 앱 통합은 [Jira의 그룹 링크 및 언링크](../integration/jira/connect-app.md#configure-the-gitlab-for-jira-cloud-app)를 통해 자동으로 활성화되거나 비활성화됩니다. GitLab 통합 양식이나 API를 사용하여 통합을 활성화하거나 비활성화할 수 없습니다.

### 프로젝트의 통합 업데이트 {#update-integration-for-a-project}

이 API 엔드포인트를 사용하여 Jira의 그룹 링크로 만든 통합을 업데이트합니다.

```plaintext
PUT /projects/:id/integrations/jira-cloud-app
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `jira_cloud_app_service_ids` | 문자열 | 아니요 | Jira Service Management 서비스 ID입니다. 여러 ID를 구분하려면 쉼표(`,`)를 사용하세요. |
| `jira_cloud_app_enable_deployment_gating` | 부울 | 아니요 | Jira Service Management에서 차단된 GitLab 배포에 대해 배포 제어를 활성화합니다. |
| `jira_cloud_app_deployment_gating_environments` | 문자열 | 아니요 | 배포 제어를 활성화할 환경(production, staging, testing 또는 development)입니다. 배포 제어가 활성화된 경우 필수입니다. 여러 환경을 구분하려면 쉼표(`,`)를 사용하세요. |

### GitLab for Jira Cloud 앱 설정 보기 {#get-gitlab-for-jira-cloud-app-settings}

프로젝트의 GitLab for Jira Cloud 앱 통합 설정을 보여줍니다.

```plaintext
GET /projects/:id/integrations/jira-cloud-app
```

## GitLab for Slack 앱 {#gitlab-for-slack-app}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### GitLab for Slack 앱 설정 {#set-up-gitlab-for-slack-app}

프로젝트의 GitLab for Slack 앱 통합을 업데이트합니다.

GitLab API만으로는 얻을 수 없는 OAuth 2.0 토큰이 필요하므로 API를 통해 GitLab for Slack 앱을 만들 수 없습니다. 대신 GitLab UI에서 [앱을 설치](../user/project/integrations/gitlab_slack_application.md#install-the-gitlab-for-slack-app)해야 합니다. 그러면 이 API 엔드포인트를 사용하여 통합을 업데이트할 수 있습니다.

```plaintext
PUT /projects/:id/integrations/gitlab-slack-application
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `channel` | 문자열 | 아니요 | 다른 채널이 구성되지 않은 경우 사용할 기본 채널입니다. |
| `notify_only_broken_pipelines` | 부울 | 아니요 | 실패한 파이프라인에 대한 알림을 전송합니다. |
| `notify_only_when_pipeline_status_changes` | 부울 | 아니요 | ref의 파이프라인 상태가 변경될 때만 알림을 전송합니다. |
| `notify_only_default_branch` | 부울 | 아니요 | **더 이상 사용되지 않음**:  이 매개변수는 `branches_to_be_notified`로 대체되었습니다. |
| `branches_to_be_notified` | 문자열 | 아니요 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `alert_events` | 부울 | 아니요 | 알림 이벤트에 대한 알림을 활성화합니다. |
| `issues_events` | 부울 | 아니요 | 이슈 이벤트에 대한 알림을 활성화합니다. |
| `confidential_issues_events` | 부울 | 아니요 | 기밀 이슈 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니요 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `note_events` | 부울 | 아니요 | 노트 이벤트에 대한 알림을 활성화합니다. |
| `confidential_note_events` | 부울 | 아니요 | 기밀 노트 이벤트에 대한 알림을 활성화합니다. |
| `deployment_events` | 부울 | 아니요 | 배포 이벤트에 대한 알림을 활성화합니다. |
| `incidents_events` | 부울 | 아니요 | 인시던트 이벤트에 대한 알림을 활성화합니다. |
| `pipeline_events` | 부울 | 아니요 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `push_events` | 부울 | 아니요 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니요 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `vulnerability_events` | 부울 | 아니요 | 취약성 이벤트에 대한 알림을 활성화합니다. |
| `wiki_page_events` | 부울 | 아니요 | 위키 페이지 이벤트에 대한 알림을 활성화합니다. |
| `labels_to_be_notified` | 문자열 | 아니요 | 알림을 보낼 레이블입니다. 설정하지 않으면 모든 이벤트에 대한 알림을 받습니다. |
| `labels_to_be_notified_behavior` | 문자열 | 아니요 | 알림을 받을 레이블입니다. 유효한 옵션은 `match_any` 및 `match_all`입니다. `match_any`로 기본값이 설정됩니다. |
| `push_channel` | 문자열 | 아니요 | 푸시 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `issue_channel` | 문자열 | 아니요 | 이슈 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `confidential_issue_channel` | 문자열 | 아니요 | 기밀 이슈 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `merge_request_channel` | 문자열 | 아니요 | 머지 리퀘스트 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `note_channel` | 문자열 | 아니요 | 노트 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `confidential_note_channel` | 문자열 | 아니요 | 기밀 노트 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `tag_push_channel` | 문자열 | 아니요 | 태그 푸시 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `pipeline_channel` | 문자열 | 아니요 | 파이프라인 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `wiki_page_channel` | 문자열 | 아니요 | 위키 페이지 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `deployment_channel` | 문자열 | 아니요 | 배포 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `incident_channel` | 문자열 | 아니요 | 인시던트 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `vulnerability_channel` | 문자열 | 아니요 | 취약성 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `alert_channel` | 문자열 | 아니요 | 알림 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### GitLab for Slack 앱 비활성화 {#disable-gitlab-for-slack-app}

프로젝트의 GitLab for Slack 앱 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/gitlab-slack-application
```

### GitLab for Slack 앱 설정 보기 {#get-gitlab-for-slack-app-settings}

프로젝트의 GitLab for Slack 앱 통합 설정을 보여줍니다.

```plaintext
GET /projects/:id/integrations/gitlab-slack-application
```

## Google Chat {#google-chat}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Google Chat 설정 {#set-up-google-chat}

프로젝트의 Google Chat 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/hangouts-chat
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 문자열 | 예 | Hangouts Chat 웹후크입니다(예: `https://chat.googleapis.com/v1/spaces...`). |
| `notify_only_broken_pipelines` | 부울 | 아니요 | 실패한 파이프라인에 대한 알림을 전송합니다. |
| `notify_only_when_pipeline_status_changes` | 부울 | 아니요 | ref의 파이프라인 상태가 변경될 때만 알림을 전송합니다. |
| `notify_only_default_branch` | 부울 | 아니요 | **더 이상 사용되지 않음**:  이 매개변수는 `branches_to_be_notified`로 대체되었습니다. |
| `branches_to_be_notified` | 문자열 | 아니요 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `push_events` | 부울 | 아니요 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `issues_events` | 부울 | 아니요 | 이슈 이벤트에 대한 알림을 활성화합니다. |
| `confidential_issues_events` | 부울 | 아니요 | 기밀 이슈 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니요 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니요 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `note_events` | 부울 | 아니요 | 노트 이벤트에 대한 알림을 활성화합니다. |
| `confidential_note_events` | 부울 | 아니요 | 기밀 노트 이벤트에 대한 알림을 활성화합니다. |
| `pipeline_events` | 부울 | 아니요 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `wiki_page_events` | 부울 | 아니요 | 위키 페이지 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Google Chat 비활성화 {#disable-google-chat}

프로젝트의 Google Chat 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/hangouts-chat
```

### Google Chat 설정 보기 {#get-google-chat-settings}

프로젝트의 Google Chat 통합 설정을 보여줍니다.

```plaintext
GET /projects/:id/integrations/hangouts-chat
```

## Google Artifact Management {#google-artifact-management}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com
- 상태:  베타

{{< /details >}}

{{< history >}}

- GitLab 16.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/425066) 되었습니다 [베타](../policy/development_stages_support.md) 기능 [플래그](../administration/feature_flags/_index.md) `google_cloud_support_feature_flag` 이름으로. 기본적으로 비활성화됨.
- GitLab 17.1에서 [GitLab.com에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472)되었습니다. 기능 플래그 `google_cloud_support_feature_flag` 제거됨.
- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

이 기능은 [베타](../policy/development_stages_support.md) 상태입니다.

### Google Artifact Management 설정 {#set-up-google-artifact-management}

프로젝트의 Google Artifact Management 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/google-cloud-platform-artifact-registry
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `artifact_registry_project_id` | 문자열 | 예 | Google Cloud 프로젝트의 ID입니다. |
| `artifact_registry_location` | 문자열 | 예 | Artifact Registry 리포지토리의 위치입니다. |
| `artifact_registry_repositories` | 문자열 | 예 | Artifact Registry의 리포지토리입니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Google Artifact Management 비활성화 {#disable-google-artifact-management}

프로젝트의 Google Artifact Management 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/google-cloud-platform-artifact-registry
```

### Google Artifact Management 설정 보기 {#get-google-artifact-management-settings}

프로젝트의 Google Artifact Management 통합 설정을 보여줍니다.

```plaintext
GET /projects/:id/integrations/google-cloud-platform-artifact-registry
```

## Google Cloud Identity and Access Management (IAM) {#google-cloud-identity-and-access-management-iam}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com
- 상태:  베타

{{< /details >}}

{{< history >}}

- GitLab 16.10에서 [베타](../policy/development_stages_support.md) 기능 [플래그](../administration/feature_flags/_index.md) `google_cloud_support_feature_flag` 이름으로 도입되었습니다. 기본적으로 비활성화됨.
- GitLab 17.1에서 [GitLab.com에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472)되었습니다. 기능 플래그 `google_cloud_support_feature_flag` 제거됨.
- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

이 기능은 [베타](../policy/development_stages_support.md) 상태입니다.

### Google Cloud Identity and Access Management 설정 {#set-up-google-cloud-identity-and-access-management}

프로젝트의 Google Cloud Identity and Access Management 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/google-cloud-platform-workload-identity-federation
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `workload_identity_federation_project_id` | 문자열 | 예 | Workload Identity Federation의 Google Cloud 프로젝트 ID입니다. |
| `workload_identity_federation_project_number` | 정수 | 예 | Workload Identity Federation의 Google Cloud 프로젝트 번호입니다. |
| `workload_identity_pool_id` | 문자열 | 예 | 워크로드 ID 풀의 ID입니다. |
| `workload_identity_pool_provider_id` | 문자열 | 예 | 워크로드 ID 풀 제공자의 ID입니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Google Cloud Identity and Access Management 비활성화 {#disable-google-cloud-identity-and-access-management}

프로젝트의 Google Cloud Identity and Access Management 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/google-cloud-platform-workload-identity-federation
```

### Google Cloud Identity and Access Management 보기 {#get-google-cloud-identity-and-access-management}

프로젝트의 Google Cloud Identity and Access Management 설정을 보여줍니다.

```plaintext
GET /projects/:id/integration/google-cloud-platform-workload-identity-federation
```

## Google Play {#google-play}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Google Play 설정 {#set-up-google-play}

프로젝트의 Google Play 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/google-play
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `package_name` | 문자열 | 예 | Google Play에서 앱의 패키지 이름입니다. |
| `service_account_key` | 문자열 | 예 | Google Play 서비스 계정 키입니다. |
| `service_account_key_file_name` | 문자열 | 예 | Google Play 서비스 계정 키의 파일 이름입니다. |
| `google_play_protected_refs` | 부울 | 아니요 | 보호된 브랜치 및 태그에만 변수를 설정합니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Google Play 비활성화 {#disable-google-play}

프로젝트의 Google Play 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/google-play
```

### Google Play 설정 보기 {#get-google-play-settings}

프로젝트의 Google Play 통합 설정을 보여줍니다.

```plaintext
GET /projects/:id/integrations/google-play
```

## Harbor {#harbor}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Harbor 설정 {#set-up-harbor}

프로젝트의 Harbor 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/harbor
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `url` | 문자열 | 예 | GitLab 프로젝트에 연결된 Harbor 인스턴스의 기본 URL입니다. 예를 들어, `https://demo.goharbor.io`입니다. |
| `project_name` | 문자열 | 예 | Harbor 인스턴스의 프로젝트 이름입니다. 예를 들어, `testproject`입니다. |
| `username` | 문자열 | 예 | Harbor 인터페이스에서 생성된 사용자 이름입니다. |
| `password` | 문자열 | 예 | 사용자의 비밀번호입니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Harbor 비활성화 {#disable-harbor}

프로젝트의 Harbor 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/harbor
```

### Harbor 설정 보기 {#get-harbor-settings}

프로젝트의 Harbor 통합 설정을 보여줍니다.

```plaintext
GET /projects/:id/integrations/harbor
```

## irker (IRC 게이트웨이) {#irker-irc-gateway}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### irker 설정 {#set-up-irker}

프로젝트의 irker 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/irker
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `recipients` | 문자열 | 예 | 쉼표로 구분된 채널 또는 이메일 주소 목록입니다. |
| `default_irc_uri` | 문자열 | 아니요 | 각 수신자 앞에 추가할 URI입니다. 기본값은 `irc://irc.network.net:6697/`입니다. |
| `server_host` | 문자열 | 아니요 | irker 데몬 호스트명입니다. 기본값은 `localhost`입니다. |
| `server_port` | 정수 | 아니요 | irker 데몬 포트입니다. 기본값은 `6659`입니다. |
| `colorize_messages` | 부울 | 아니요 | 메시지를 색상화합니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### irker 비활성화 {#disable-irker}

프로젝트의 irker 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/irker
```

### irker 설정 보기 {#get-irker-settings}

프로젝트의 irker 통합 설정을 보여줍니다.

```plaintext
GET /projects/:id/integrations/irker
```

## Jenkins {#jenkins}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Jenkins 설정 {#set-up-jenkins}

프로젝트의 Jenkins 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/jenkins
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `jenkins_url` | 문자열 | 예 | Jenkins 서버의 URL입니다. |
| `enable_ssl_verification` | 부울 | 아니요 | SSL 검증을 활성화합니다. `true`(활성화됨)을 기본값으로 사용합니다. |
| `project_name` | 문자열 | 예 | Jenkins 프로젝트의 이름입니다. |
| `username` | 문자열 | 아니요 | Jenkins 서버의 사용자 이름입니다. |
| `password` | 문자열 | 아니요 | Jenkins 서버의 비밀번호입니다. |
| `push_events` | 부울 | 아니요 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니요 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니요 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Jenkins 비활성화 {#disable-jenkins}

프로젝트의 Jenkins 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/jenkins
```

### Jenkins 설정 보기 {#get-jenkins-settings}

프로젝트의 Jenkins 통합 설정을 보여줍니다.

```plaintext
GET /projects/:id/integrations/jenkins
```

## JetBrains TeamCity {#jetbrains-teamcity}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### JetBrains TeamCity 설정 {#set-up-jetbrains-teamcity}

프로젝트의 JetBrains TeamCity 통합을 설정합니다.

TeamCity의 빌드 구성은 빌드 번호 형식 `%build.vcs.number%`을 사용해야 합니다. VCS 루트의 고급 설정에서 모든 브랜치의 모니터링을 구성하여 머지 리퀘스트를 빌드할 수 있습니다.

```plaintext
PUT /projects/:id/integrations/teamcity
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `teamcity_url` | 문자열 | 예 | TeamCity 루트 URL입니다(예: `https://teamcity.example.com`). |
| `enable_ssl_verification` | 부울 | 아니요 | SSL 검증을 활성화합니다. `true`(활성화됨)을 기본값으로 사용합니다. |
| `build_type` | 문자열 | 예 | TeamCity 프로젝트의 빌드 구성 ID입니다. |
| `username` | 문자열 | 예 | 수동 빌드를 트리거할 권한이 있는 사용자입니다. |
| `password` | 문자열 | 예 | 사용자의 비밀번호입니다. |
| `push_events` | 부울 | 아니요 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니요 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### JetBrains TeamCity 비활성화 {#disable-jetbrains-teamcity}

프로젝트의 JetBrains TeamCity 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/teamcity
```

### JetBrains TeamCity 설정 보기 {#get-jetbrains-teamcity-settings}

프로젝트의 JetBrains TeamCity 통합 설정을 보여줍니다.

```plaintext
GET /projects/:id/integrations/teamcity
```

## Jira 이슈 {#jira-issues}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Jira 이슈 설정 {#set-up-jira-issues}

프로젝트의 [Jira 이슈 통합](../integration/jira/configure.md)을 설정합니다.

```plaintext
PUT /projects/:id/integrations/jira
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `url`           | 문자열 | 예 | 이 GitLab 프로젝트에 연결되는 Jira 프로젝트의 URL입니다(예: `https://jira.example.com`). |
| `api_url`   | 문자열 | 아니요 | Jira 인스턴스 API의 기본 URL입니다. 설정하지 않으면 웹 URL 값이 사용됩니다(예: `https://jira-api.example.com`). |
| `username`      | 문자열 | 아니요   | Jira에 사용할 이메일 또는 사용자 이름입니다. Jira Cloud의 경우 이메일을 사용하고, Jira Data Center 및 Jira Server의 경우 사용자 이름을 사용합니다. 기본 인증(`jira_auth_type`이 `0`)을 사용할 때 필수입니다. |
| `password`      | 문자열 | 예  | Jira에 사용할 Jira API 토큰, 비밀번호 또는 개인 액세스 토큰입니다. 기본 인증(`jira_auth_type`이 `0`)을 사용할 때는 Jira Cloud의 API 토큰 또는 Jira Data Center나 Jira Server의 비밀번호를 사용합니다. Jira 개인 액세스 토큰(`jira_auth_type`이 `1`)의 경우 개인 액세스 토큰을 사용합니다. |
| `jira_auth_type`| 정수 | 아니요  | Jira에 사용할 인증 방법입니다. 기본 인증에는 `0`을, Jira 개인 액세스 토큰에는 `1`를 사용합니다. `0`로 기본값이 설정됩니다. |
| `jira_issue_prefix` | 문자열 | 아니요 | Jira 이슈 키와 일치시킬 접두사입니다. |
| `jira_issue_regex` | 문자열 | 아니요 | Jira 이슈 키와 일치시킬 정규 표현식입니다. |
| `jira_issue_transition_automatic` | 부울 | 아니요 | [자동 이슈 전환](../integration/jira/issues.md#automatic-issue-transitions)을 활성화합니다. 활성화된 경우 `jira_issue_transition_id`보다 우선합니다. `false`로 기본값이 설정됩니다. |
| `jira_issue_transition_id` | 문자열 | 아니요 | [사용자 지정 이슈 전환](../integration/jira/issues.md#custom-issue-transitions)을 위한 하나 이상의 전환의 ID입니다.`jira_issue_transition_automatic`이 활성화된 경우 무시됩니다. 기본값은 빈 문자열이며, 이는 사용자 지정 전환을 비활성화합니다. |
| `commit_events` | 부울 | 아니요 | 커밋 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니요 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `comment_on_event_enabled` | 부울 | 아니요 | 각 GitLab 이벤트(커밋 또는 머지 리퀘스트)에 대해 Jira 이슈에 댓글을 활성화합니다. |
| `issues_enabled` | 부울 | 아니요 | GitLab에서 Jira 이슈 보기를 활성화합니다. [GitLab 17.0에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/267015). |
| `project_keys` | 문자열 배열 | 아니요 | Jira 프로젝트의 키입니다. `issues_enabled`이 `true`일 때 이 설정은 GitLab에서 어느 Jira 프로젝트의 이슈를 볼 것인지를 지정합니다. [GitLab 17.0에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/267015). |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |
| `vulnerabilities_enabled` | 부울 | 아니요 | GitLab EE에서만 사용 가능합니다. `true`로 설정하면 GitLab 취약성에 대해 Jira 이슈를 만듭니다.|
| `vulnerabilities_issuetype` | 숫자 | 아니요 | GitLab EE에서만 사용 가능합니다. 취약성에서 이슈를 만들 때 사용할 Jira 이슈 유형의 ID입니다. |
| `project_key` | 문자열 | 아니요 | GitLab EE에서만 사용 가능합니다. 취약성에서 이슈를 만들 때 사용할 프로젝트의 키입니다. 취약성에서 이슈를 만드는 통합을 사용할 경우 이 매개변수는 필수입니다. |
| `customize_jira_issue_enabled` | 부울 | 아니요 | GitLab EE에서만 사용 가능합니다. `true`로 설정하면 취약성에서 Jira 이슈를 만들 때 Jira 인스턴스에서 미리 입력된 양식을 엽니다. |

### Jira 비활성화 {#disable-jira}

프로젝트의 Jira 이슈 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/jira
```

### Jira 설정 보기 {#get-jira-settings}

프로젝트의 Jira 이슈 통합 설정을 보여줍니다.

```plaintext
GET /projects/:id/integrations/jira
```

## Linear {#linear}

{{< history >}}

- GitLab 18.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198297)되었습니다.

{{< /history >}}

### Linear 설정 {#set-up-linear}

그룹의 Linear 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/linear
```

매개변수:

| 매개변수     | 유형   | 필수 | 설명    |
| ------------- | ------ | -------- | -------------- |
| `workspace_url`  | 문자열 | 예     | 이슈의 URL입니다.     |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Linear 비활성화 {#disable-linear}

그룹의 Linear 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/linear
```

### Linear 설정 보기 {#get-linear-settings}

그룹의 Linear 통합 설정을 보여줍니다.

```plaintext
GET /projects/:id/integrations/linear
```

## Matrix 알림 {#matrix-notifications}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Matrix 알림 설정 {#set-up-matrix-notifications}

프로젝트의 Matrix 알림을 설정합니다.

```plaintext
PUT /projects/:id/integrations/matrix
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `hostname`   | 문자열 | 아니요 | Matrix 서버의 사용자 지정 호스트명입니다. 기본값은 `https://matrix.org`입니다. |
| `token`   | 문자열 | 예 | Matrix 액세스 토큰입니다(예: `syt-zyx57W2v1u123ew11`). |
| `room` | 문자열 | 예 | 대상 방의 고유 식별자입니다(형식 `!qPKKM111FFKKsfoCVy:matrix.org`). |
| `notify_only_broken_pipelines` | 부울 | 아니요 | 실패한 파이프라인에 대한 알림을 전송합니다. |
| `notify_only_when_pipeline_status_changes` | 부울 | 아니요 | ref의 파이프라인 상태가 변경될 때만 알림을 전송합니다. |
| `branches_to_be_notified` | 문자열 | 아니요 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `push_events` | 부울 | 아니요 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `issues_events` | 부울 | 아니요 | 이슈 이벤트에 대한 알림을 활성화합니다. |
| `confidential_issues_events` | 부울 | 아니요 | 기밀 이슈 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니요 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니요 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `note_events` | 부울 | 아니요 | 노트 이벤트에 대한 알림을 활성화합니다. |
| `confidential_note_events` | 부울 | 아니요 | 기밀 노트 이벤트에 대한 알림을 활성화합니다. |
| `pipeline_events` | 부울 | 아니요 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `wiki_page_events` | 부울 | 아니요 | 위키 페이지 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Matrix 알림 비활성화 {#disable-matrix-notifications}

프로젝트의 Matrix 알림을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/matrix
```

### Matrix 알림 설정 보기 {#get-matrix-notifications-settings}

프로젝트의 Matrix 알림 설정을 보여줍니다.

```plaintext
GET /projects/:id/integrations/matrix
```

## Mattermost 알림 {#mattermost-notifications}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Mattermost 알림 설정 {#set-up-mattermost-notifications}

프로젝트의 Mattermost 알림을 설정합니다.

```plaintext
PUT /projects/:id/integrations/mattermost
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 문자열 | 예 | Mattermost 알림 웹후크입니다(예: `http://mattermost.example.com/hooks/...`). |
| `username` | 문자열 | 아니요 | Mattermost 알림 사용자 이름입니다. |
| `channel` | 문자열 | 아니요 | 다른 채널이 구성되지 않은 경우 사용할 기본 채널입니다. |
| `notify_only_broken_pipelines` | 부울 | 아니요 | 실패한 파이프라인에 대한 알림을 전송합니다. |
| `notify_only_when_pipeline_status_changes` | 부울 | 아니요 | ref의 파이프라인 상태가 변경될 때만 알림을 전송합니다. |
| `notify_only_default_branch` | 부울 | 아니요 | **더 이상 사용되지 않음**:  이 매개변수는 `branches_to_be_notified`로 대체되었습니다. |
| `branches_to_be_notified` | 문자열 | 아니요 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `labels_to_be_notified` | 문자열 | 아니요 | 알림을 보낼 레이블입니다. 모든 이벤트에 대한 알림을 받으려면 비워둡니다. |
| `labels_to_be_notified_behavior` | 문자열 | 아니요 | 알림을 받을 레이블입니다. 유효한 옵션은 `match_any` 및 `match_all`입니다. 기본값은 `match_any`입니다. |
| `push_events` | 부울 | 아니요 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `issues_events` | 부울 | 아니요 | 이슈 이벤트에 대한 알림을 활성화합니다. |
| `confidential_issues_events` | 부울 | 아니요 | 기밀 이슈 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니요 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니요 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `note_events` | 부울 | 아니요 | 노트 이벤트에 대한 알림을 활성화합니다. |
| `confidential_note_events` | 부울 | 아니요 | 기밀 노트 이벤트에 대한 알림을 활성화합니다. |
| `pipeline_events` | 부울 | 아니요 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `wiki_page_events` | 부울 | 아니요 | 위키 페이지 이벤트에 대한 알림을 활성화합니다. |
| `push_channel` | 문자열 | 아니요 | 푸시 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `issue_channel` | 문자열 | 아니요 | 이슈 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `confidential_issue_channel` | 문자열 | 아니요 | 기밀 이슈 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `merge_request_channel` | 문자열 | 아니요 | 머지 리퀘스트 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `note_channel` | 문자열 | 아니요 | 노트 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `confidential_note_channel` | 문자열 | 아니요 | 기밀 노트 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `tag_push_channel` | 문자열 | 아니요 | 태그 푸시 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `pipeline_channel` | 문자열 | 아니요 | 파이프라인 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `wiki_page_channel` | 문자열 | 아니요 | 위키 페이지 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Mattermost 알림 비활성화 {#disable-mattermost-notifications}

프로젝트에 대해 Mattermost 알림을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/mattermost
```

### Mattermost 알림 설정 가져오기 {#get-mattermost-notifications-settings}

프로젝트에 대한 Mattermost 알림 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/mattermost
```

## Mattermost 슬래시 명령어 {#mattermost-slash-commands}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Mattermost 슬래시 명령어 설정 {#set-up-mattermost-slash-commands}

프로젝트에 대해 Mattermost 슬래시 명령어를 설정합니다.

```plaintext
PUT /projects/:id/integrations/mattermost-slash-commands
```

매개변수:

| 매개변수 | 유형   | 필수 | 설명           |
| --------- | ------ | -------- | --------------------- |
| `token`   | 문자열 | 예      | Mattermost 토큰입니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Mattermost 슬래시 명령어 비활성화 {#disable-mattermost-slash-commands}

프로젝트에 대해 Mattermost 슬래시 명령어를 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/mattermost-slash-commands
```

### Mattermost 슬래시 명령어 설정 가져오기 {#get-mattermost-slash-commands-settings}

프로젝트에 대한 Mattermost 슬래시 명령어 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/mattermost-slash-commands
```

## Microsoft Teams 알림 {#microsoft-teams-notifications}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Microsoft Teams 알림 설정 {#set-up-microsoft-teams-notifications}

프로젝트에 대해 Microsoft Teams 알림을 설정합니다.

```plaintext
PUT /projects/:id/integrations/microsoft-teams
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 문자열 | 예 | Microsoft Teams 웹후크(예: `https://outlook.office.com/webhook/...`)입니다. |
| `notify_only_broken_pipelines` | 부울 | 아니요 | 실패한 파이프라인에 대한 알림을 전송합니다. |
| `notify_only_when_pipeline_status_changes` | 부울 | 아니요 | ref의 파이프라인 상태가 변경될 때만 알림을 전송합니다. |
| `notify_only_default_branch` | 부울 | 아니요 | **더 이상 사용되지 않음**:  이 매개변수는 `branches_to_be_notified`로 대체되었습니다. |
| `branches_to_be_notified` | 문자열 | 아니요 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `push_events` | 부울 | 아니요 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `issues_events` | 부울 | 아니요 | 이슈 이벤트에 대한 알림을 활성화합니다. |
| `confidential_issues_events` | 부울 | 아니요 | 기밀 이슈 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니요 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니요 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `note_events` | 부울 | 아니요 | 노트 이벤트에 대한 알림을 활성화합니다. |
| `confidential_note_events` | 부울 | 아니요 | 기밀 노트 이벤트에 대한 알림을 활성화합니다. |
| `pipeline_events` | 부울 | 아니요 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `wiki_page_events` | 부울 | 아니요 | 위키 페이지 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Microsoft Teams 알림 비활성화 {#disable-microsoft-teams-notifications}

프로젝트에 대해 Microsoft Teams 알림을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/microsoft-teams
```

### Microsoft Teams 알림 설정 가져오기 {#get-microsoft-teams-notifications-settings}

프로젝트에 대한 Microsoft Teams 알림 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/microsoft-teams
```

## Mock CI {#mock-ci}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

이 통합은 개발 환경에서만 사용할 수 있습니다. Mock CI 서버 예제는 [`gitlab-org/gitlab-mock-ci-service`](https://gitlab.com/gitlab-org/gitlab-mock-ci-service)를 참조하세요.

### Mock CI 설정 {#set-up-mock-ci}

프로젝트에 대해 Mock CI 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/mock-ci
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `mock_service_url` | 문자열 | 예 | Mock CI 통합의 URL입니다. |
| `enable_ssl_verification` | 부울 | 아니요 | SSL 검증을 활성화합니다. `true`(활성화됨)을 기본값으로 사용합니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Mock CI 비활성화 {#disable-mock-ci}

프로젝트에 대해 Mock CI 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/mock-ci
```

### Mock CI 설정 가져오기 {#get-mock-ci-settings}

프로젝트에 대한 Mock CI 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/mock-ci
```

## Packagist {#packagist}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Packagist 설정 {#set-up-packagist}

프로젝트에 대해 Packagist 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/packagist
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `username` | 문자열 | 예 | Packagist 계정의 사용자 이름입니다. |
| `token` | 문자열 | 예 | Packagist 서버의 API 토큰입니다. |
| `server` | 부울 | 아니요 | Packagist 서버의 URL입니다. 기본값은 `https://packagist.org`입니다. |
| `push_events` | 부울 | 아니요 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니요 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니요 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Packagist 비활성화 {#disable-packagist}

프로젝트에 대해 Packagist 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/packagist
```

### Packagist 설정 가져오기 {#get-packagist-settings}

프로젝트에 대한 Packagist 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/packagist
```

## Phorge {#phorge}

{{< history >}}

- [GitLab 16.11에서 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145863)됨.
- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Phorge 설정 {#set-up-phorge}

프로젝트에 대해 Phorge 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/phorge
```

매개변수:

| 매개변수       | 유형   | 필수 | 설명           |
|-----------------|--------|----------|-----------------------|
| `issues_url`    | 문자열 | 예     | 이슈의 URL입니다.     |
| `project_url`   | 문자열 | 예     | 프로젝트의 URL입니다.   |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Phorge 비활성화 {#disable-phorge}

프로젝트에 대해 Phorge 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/phorge
```

### Phorge 설정 가져오기 {#get-phorge-settings}

프로젝트에 대한 Phorge 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/phorge
```

## 파이프라인 상태 이메일 {#pipeline-status-emails}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### 파이프라인 상태 이메일 설정 {#set-up-pipeline-status-emails}

프로젝트에 대해 파이프라인 상태 이메일을 설정합니다.

```plaintext
PUT /projects/:id/integrations/pipelines-email
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `recipients` | 문자열 | 예 | 쉼표로 구분된 수신인 이메일 주소 목록입니다. |
| `notify_only_broken_pipelines` | 부울 | 아니요 | 실패한 파이프라인에 대한 알림을 전송합니다. |
| `branches_to_be_notified` | 문자열 | 아니요 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `notify_only_default_branch` | 부울 | 아니요 | 기본 브랜치에 대한 알림을 보냅니다. |
| `pipeline_events` | 부울 | 아니요 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### 파이프라인 상태 이메일 비활성화 {#disable-pipeline-status-emails}

프로젝트에 대해 파이프라인 상태 이메일을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/pipelines-email
```

### 파이프라인 상태 이메일 설정 가져오기 {#get-pipeline-status-emails-settings}

프로젝트에 대한 파이프라인 상태 이메일 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/pipelines-email
```

## Pivotal Tracker {#pivotal-tracker}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Pivotal Tracker 설정 {#set-up-pivotal-tracker}

프로젝트에 대해 Pivotal Tracker 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/pivotaltracker
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `token` | 문자열 | 예 | Pivotal Tracker 토큰입니다. |
| `restrict_to_branch` | 부울 | 아니요 | 자동으로 검사할 브랜치의 쉼표 구분 목록입니다. 모든 브랜치를 포함하려면 공백으로 두세요. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Pivotal Tracker 비활성화 {#disable-pivotal-tracker}

프로젝트에 대해 Pivotal Tracker 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/pivotaltracker
```

### Pivotal Tracker 설정 가져오기 {#get-pivotal-tracker-settings}

프로젝트에 대한 Pivotal Tracker 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/pivotaltracker
```

## Pumble {#pumble}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Pumble 설정 {#set-up-pumble}

프로젝트에 대해 Pumble 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/pumble
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 문자열 | 예 | Pumble 웹후크(예: `https://api.pumble.com/workspaces/x/...`)입니다. |
| `branches_to_be_notified` | 문자열 | 아니요 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `confidential_issues_events` | 부울 | 아니요 | 기밀 이슈 이벤트에 대한 알림을 활성화합니다. |
| `confidential_note_events` | 부울 | 아니요 | 기밀 노트 이벤트에 대한 알림을 활성화합니다. |
| `issues_events` | 부울 | 아니요 | 이슈 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니요 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `note_events` | 부울 | 아니요 | 노트 이벤트에 대한 알림을 활성화합니다. |
| `notify_only_broken_pipelines` | 부울 | 아니요 | 실패한 파이프라인에 대한 알림을 전송합니다. |
| `pipeline_events` | 부울 | 아니요 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `push_events` | 부울 | 아니요 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니요 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `wiki_page_events` | 부울 | 아니요 | 위키 페이지 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Pumble 비활성화 {#disable-pumble}

프로젝트에 대해 Pumble 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/pumble
```

### Pumble 설정 가져오기 {#get-pumble-settings}

프로젝트에 대한 Pumble 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/pumble
```

## Pushover {#pushover}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Pushover 설정 {#set-up-pushover}

프로젝트에 대해 Pushover 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/pushover
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `api_key` | 문자열 | 예 | 애플리케이션 키입니다. |
| `user_key` | 문자열 | 예 | 사용자 키입니다. |
| `priority` | 문자열 | 예 | 우선순위입니다. |
| `device` | 문자열 | 아니요 | 모든 활성 장치에 대해 비워둡니다. |
| `sound` | 문자열 | 아니요 | 알림의 사운드입니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Pushover 비활성화 {#disable-pushover}

프로젝트에 대해 Pushover 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/pushover
```

### Pushover 설정 가져오기 {#get-pushover-settings}

프로젝트에 대한 Pushover 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/pushover
```

## Redmine {#redmine}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Redmine 설정 {#set-up-redmine}

프로젝트에 대해 Redmine 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/redmine
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | 문자열 | 예 | 새 이슈의 URL입니다. |
| `project_url` | 문자열 | 예 | 프로젝트의 URL입니다. |
| `issues_url` | 문자열 | 예 | 이슈의 URL입니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Redmine 비활성화 {#disable-redmine}

프로젝트에 대해 Redmine 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/redmine
```

### Redmine 설정 가져오기 {#get-redmine-settings}

프로젝트에 대한 Redmine 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/redmine
```

## Slack 알림 {#slack-notifications}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Slack 알림 설정 {#set-up-slack-notifications}

프로젝트에 대해 Slack 알림을 설정합니다.

```plaintext
PUT /projects/:id/integrations/slack
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 문자열 | 예 | Slack 알림 웹후크(예: `https://hooks.slack.com/services/...`)입니다. |
| `username` | 문자열 | 아니요 | Slack 알림 사용자 이름입니다. |
| `channel` | 문자열 | 아니요 | 다른 채널이 구성되지 않은 경우 사용할 기본 채널입니다. |
| `notify_only_broken_pipelines` | 부울 | 아니요 | 실패한 파이프라인에 대한 알림을 전송합니다. |
| `notify_only_when_pipeline_status_changes` | 부울 | 아니요 | ref의 파이프라인 상태가 변경될 때만 알림을 전송합니다. |
| `notify_only_default_branch` | 부울 | 아니요 | **더 이상 사용되지 않음**:  이 매개변수는 `branches_to_be_notified`로 대체되었습니다. |
| `branches_to_be_notified` | 문자열 | 아니요 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `labels_to_be_notified` | 문자열 | 아니요 | 알림을 보낼 레이블입니다. 모든 이벤트에 대한 알림을 받으려면 비워둡니다. |
| `labels_to_be_notified_behavior` | 문자열 | 아니요 | 알림을 받을 레이블입니다. 유효한 옵션은 `match_any` 및 `match_all`입니다. 기본값은 `match_any`입니다. |
| `alert_channel` | 문자열 | 아니요 | 알림 이벤트를 받을 채널의 이름입니다. |
| `alert_events` | 부울 | 아니요 | 알림 이벤트에 대한 알림을 활성화합니다. |
| `commit_events` | 부울 | 아니요 | 커밋 이벤트에 대한 알림을 활성화합니다. |
| `confidential_issue_channel` | 문자열 | 아니요 | 기밀 이슈 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `confidential_issues_events` | 부울 | 아니요 | 기밀 이슈 이벤트에 대한 알림을 활성화합니다. |
| `confidential_note_channel` | 문자열 | 아니요 | 기밀 노트 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `confidential_note_events` | 부울 | 아니요 | 기밀 노트 이벤트에 대한 알림을 활성화합니다. |
| `deployment_channel` | 문자열 | 아니요 | 배포 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `deployment_events` | 부울 | 아니요 | 배포 이벤트에 대한 알림을 활성화합니다. |
| `incident_channel` | 문자열 | 아니요 | 인시던트 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `incidents_events` | 부울 | 아니요 | 인시던트 이벤트에 대한 알림을 활성화합니다. |
| `issue_channel` | 문자열 | 아니요 | 이슈 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `issues_events` | 부울 | 아니요 | 이슈 이벤트에 대한 알림을 활성화합니다. |
| `job_events` | 부울 | 아니요 | 작업 이벤트에 대한 알림을 활성화합니다. |
| `merge_request_channel` | 문자열 | 아니요 | 머지 리퀘스트 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `merge_requests_events` | 부울 | 아니요 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `note_channel` | 문자열 | 아니요 | 노트 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `note_events` | 부울 | 아니요 | 노트 이벤트에 대한 알림을 활성화합니다. |
| `pipeline_channel` | 문자열 | 아니요 | 파이프라인 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `pipeline_events` | 부울 | 아니요 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `push_channel` | 문자열 | 아니요 | 푸시 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `push_events` | 부울 | 아니요 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_channel` | 문자열 | 아니요 | 태그 푸시 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `tag_push_events` | 부울 | 아니요 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `wiki_page_channel` | 문자열 | 아니요 | 위키 페이지 이벤트에 대한 알림을 받을 채널의 이름입니다. |
| `wiki_page_events` | 부울 | 아니요 | 위키 페이지 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Slack 알림 비활성화 {#disable-slack-notifications}

프로젝트에 대해 Slack 알림을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/slack
```

### Slack 알림 설정 가져오기 {#get-slack-notifications-settings}

프로젝트에 대한 Slack 알림 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/slack
```

## Squash TM {#squash-tm}

{{< history >}}

- [GitLab 15.10에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/337855).
- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Squash TM 설정 {#set-up-squash-tm}

프로젝트에 대해 Squash TM 통합 설정을 설정합니다.

```plaintext
PUT /projects/:id/integrations/squash-tm
```

매개변수:

| 매개변수               | 유형   | 필수 | 설명                   |
|-------------------------|--------|----------|-------------------------------|
| `url`                   | 문자열 | 예      | Squash TM 웹후크의 URL입니다. |
| `token`                 | 문자열 | 아니요       | 비밀 토큰입니다.                 |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Squash TM 비활성화 {#disable-squash-tm}

프로젝트에 대해 Squash TM 통합을 비활성화합니다. 통합 설정이 보존됩니다.

```plaintext
DELETE /projects/:id/integrations/squash-tm
```

### Squash TM 설정 가져오기 {#get-squash-tm-settings}

프로젝트에 대한 Squash TM 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/squash-tm
```

## Telegram {#telegram}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Telegram 설정 {#set-up-telegram}

프로젝트에 대해 Telegram 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/telegram
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `hostname`   | 문자열 | 아니요 | Telegram API의 사용자 지정 호스트 이름(GitLab 17.1에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/461313))입니다. 기본값은 `https://api.telegram.org`입니다. |
| `token`   | 문자열 | 예 | Telegram 봇 토큰(예: `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`)입니다. |
| `room` | 문자열 | 예 | 대상 채팅의 고유 식별자 또는 대상 채널의 사용자 이름(형식: `@channelusername`)입니다. |
| `thread` | 정수 | 아니요 | 대상 메시지 스레드(포럼 수퍼그룹의 주제)에 대한 고유 식별자입니다. [GitLab 16.11에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/441097)됨. |
| `notify_only_broken_pipelines` | 부울 | 아니요 | 실패한 파이프라인에 대한 알림을 전송합니다. |
| `notify_only_when_pipeline_status_changes` | 부울 | 아니요 | ref의 파이프라인 상태가 변경될 때만 알림을 전송합니다. |
| `branches_to_be_notified` | 문자열 | 아니요 | 알림을 보낼 브랜치([GitLab 16.5에 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134361)됨)입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `push_events` | 부울 | 예 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `issues_events` | 부울 | 예 | 이슈 이벤트에 대한 알림을 활성화합니다. |
| `confidential_issues_events` | 부울 | 예 | 기밀 이슈 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 예 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 예 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `note_events` | 부울 | 예 | 노트 이벤트에 대한 알림을 활성화합니다. |
| `confidential_note_events` | 부울 | 예 | 기밀 노트 이벤트에 대한 알림을 활성화합니다. |
| `pipeline_events` | 부울 | 예 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `wiki_page_events` | 부울 | 예 | 위키 페이지 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Telegram 비활성화 {#disable-telegram}

프로젝트에 대해 Telegram 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/telegram
```

### Telegram 설정 가져오기 {#get-telegram-settings}

프로젝트에 대한 Telegram 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/telegram
```

## Unify Circuit {#unify-circuit}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Unify Circuit 설정 {#set-up-unify-circuit}

프로젝트에 대해 Unify Circuit 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/unify-circuit
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 문자열 | 예 | Unify Circuit 웹후크(예: `https://circuit.com/rest/v2/webhooks/incoming/...`)입니다. |
| `notify_only_broken_pipelines` | 부울 | 아니요 | 실패한 파이프라인에 대한 알림을 전송합니다. |
| `notify_only_when_pipeline_status_changes` | 부울 | 아니요 | ref의 파이프라인 상태가 변경될 때만 알림을 전송합니다. |
| `branches_to_be_notified` | 문자열 | 아니요 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `push_events` | 부울 | 아니요 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `issues_events` | 부울 | 아니요 | 이슈 이벤트에 대한 알림을 활성화합니다. |
| `confidential_issues_events` | 부울 | 아니요 | 기밀 이슈 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니요 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니요 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `note_events` | 부울 | 아니요 | 노트 이벤트에 대한 알림을 활성화합니다. |
| `confidential_note_events` | 부울 | 아니요 | 기밀 노트 이벤트에 대한 알림을 활성화합니다. |
| `pipeline_events` | 부울 | 아니요 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `wiki_page_events` | 부울 | 아니요 | 위키 페이지 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Unify Circuit 비활성화 {#disable-unify-circuit}

프로젝트의 Unify Circuit 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/unify-circuit
```

### Unify Circuit 설정 가져오기 {#get-unify-circuit-settings}

프로젝트의 Unify Circuit 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/unify-circuit
```

## Webex Teams {#webex-teams}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### Webex Teams 설정 {#set-up-webex-teams}

프로젝트의 Webex Teams을 설정합니다.

```plaintext
PUT /projects/:id/integrations/webex-teams
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `webhook` | 문자열 | 예 | Webex Teams 웹후크입니다(예: `https://api.ciscospark.com/v1/webhooks/incoming/...`). |
| `notify_only_broken_pipelines` | 부울 | 아니요 | 실패한 파이프라인에 대한 알림을 전송합니다. |
| `branches_to_be_notified` | 문자열 | 아니요 | 알림을 보낼 브랜치입니다. 유효한 옵션은 `all`, `default`, `protected`, `default_and_protected`입니다. 기본값은 `default`입니다. |
| `push_events` | 부울 | 아니요 | 푸시 이벤트에 대한 알림을 활성화합니다. |
| `issues_events` | 부울 | 아니요 | 이슈 이벤트에 대한 알림을 활성화합니다. |
| `confidential_issues_events` | 부울 | 아니요 | 기밀 이슈 이벤트에 대한 알림을 활성화합니다. |
| `merge_requests_events` | 부울 | 아니요 | 머지 리퀘스트 이벤트에 대한 알림을 활성화합니다. |
| `tag_push_events` | 부울 | 아니요 | 태그 푸시 이벤트에 대한 알림을 활성화합니다. |
| `note_events` | 부울 | 아니요 | 노트 이벤트에 대한 알림을 활성화합니다. |
| `confidential_note_events` | 부울 | 아니요 | 기밀 노트 이벤트에 대한 알림을 활성화합니다. |
| `pipeline_events` | 부울 | 아니요 | 파이프라인 이벤트에 대한 알림을 활성화합니다. |
| `wiki_page_events` | 부울 | 아니요 | 위키 페이지 이벤트에 대한 알림을 활성화합니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### Webex Teams 비활성화 {#disable-webex-teams}

프로젝트의 Webex Teams을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/webex-teams
```

### Webex Teams 설정 가져오기 {#get-webex-teams-settings}

프로젝트의 Webex Teams 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/webex-teams
```

## YouTrack {#youtrack}

{{< history >}}

- `use_inherited_settings` 매개변수가 GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) 되었으며 [플래그](../administration/feature_flags/_index.md) `integration_api_inheritance`이(가) 지정되어 있습니다. 기본적으로 비활성화됨.
- `use_inherited_settings` 매개변수는 GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/467186)합니다. 기능 플래그 `integration_api_inheritance` 제거됨.

{{< /history >}}

### YouTrack 설정 {#set-up-youtrack}

프로젝트의 YouTrack 통합을 설정합니다.

```plaintext
PUT /projects/:id/integrations/youtrack
```

매개변수:

| 매개변수 | 유형 | 필수 | 설명 |
| --------- | ---- | -------- | ----------- |
| `issues_url` | 문자열 | 예 | 이슈의 URL입니다. |
| `project_url` | 문자열 | 예 | 프로젝트의 URL입니다. |
| `use_inherited_settings` | 부울 | 아니요 | 기본 설정을 상속할지 여부를 나타냅니다. `false`로 기본값이 설정됩니다. |

### YouTrack 비활성화 {#disable-youtrack}

프로젝트의 YouTrack 통합을 비활성화합니다. 통합 설정이 재설정됩니다.

```plaintext
DELETE /projects/:id/integrations/youtrack
```

### YouTrack 설정 가져오기 {#get-youtrack-settings}

프로젝트의 YouTrack 통합 설정을 가져옵니다.

```plaintext
GET /projects/:id/integrations/youtrack
```
