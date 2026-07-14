---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GraphQL API를 사용하여 전체 GitLab 인스턴스의 감시 이벤트 스트리밍 대상을 관리합니다. HTTP 및 Google Cloud Logging 구성을 포함합니다.
title: 인스턴스에 대한 감시 이벤트 스트리밍 GraphQL API
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/335175) 되었으며 `ff_external_audit_events` [플래그](../feature_flags.md)라는 이름으로 제공됩니다. 기본적으로 비활성화됨.
- 인스턴스 수준 스트리밍 대상을 위한 사용자 정의 HTTP 헤더의 API가 GitLab 16.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/404560) 되었으며 `ff_external_audit_events` [플래그](../feature_flags.md)라는 이름으로 제공됩니다. 기본적으로 비활성화됨.
- [`ff_external_audit_events` 기능 플래그](https://gitlab.com/gitlab-org/gitlab/-/issues/393772)는 GitLab 16.2에서 기본적으로 활성화되었습니다.
- 사용자 지정 대상 이름 API 지원은 GitLab 16.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/413894)되었습니다.
- 인스턴스 스트리밍 대상은 GitLab 16.4에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/393772)해졌습니다. [`ff_external_audit_events` 기능 플래그](https://gitlab.com/gitlab-org/gitlab/-/issues/417708)가 제거되었습니다.

{{< /history >}}

GraphQL API를 사용하여 인스턴스에 대한 감시 이벤트 스트리밍 대상을 관리합니다.

## HTTP 대상 {#http-destinations}

전체 인스턴스에 대한 HTTP 스트리밍 대상을 관리합니다.

### 새로운 HTTP 대상 추가 {#add-a-new-http-destination}

인스턴스에 새로운 HTTP 스트리밍 대상을 추가합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스입니다.

스트리밍을 활성화하고 대상을 추가하려면 GraphQL API에서 `instanceExternalAuditEventDestinationCreate` 변이를 사용합니다.

```graphql
mutation {
  instanceExternalAuditEventDestinationCreate(input: { destinationUrl: "https://mydomain.io/endpoint/ingest"}) {
    errors
    instanceExternalAuditEventDestination {
      destinationUrl
      id
      name
      verificationToken
    }
  }
}
```

이벤트 스트리밍은 다음의 경우 활성화됩니다:

- 반환된 `errors` 개체가 비어 있습니다.
- API는 `200 OK`로 응답합니다.

GraphQL `instanceExternalAuditEventDestinationCreate` 변이를 사용하여 기본 GitLab 생성 이름 대신 자신의 대상 이름을 지정할 수 있습니다. 이름 길이는 72자를 초과할 수 없으며 후행 공백은 제거되지 않습니다. 이 값은 고유해야 합니다. 예를 들어:

```graphql
mutation {
  instanceExternalAuditEventDestinationCreate(input: { destinationUrl: "https://mydomain.io/endpoint/ingest", name: "destination-name-here"}) {
    errors
    instanceExternalAuditEventDestination {
      destinationUrl
      id
      name
      verificationToken
    }
  }
}
```

인스턴스 관리자는 GraphQL `auditEventsStreamingInstanceHeadersCreate` 변이를 사용하여 HTTP 헤더를 추가할 수 있습니다. 대상 ID는 인스턴스에 대해 [모든 스트리밍 대상을 나열](#list-streaming-destinations)하거나 이전 변이에서 검색할 수 있습니다.

```graphql
mutation {
  auditEventsStreamingInstanceHeadersCreate(input:
    {
      destinationId: "gid://gitlab/AuditEvents::InstanceExternalAuditEventDestination/42",
      key: "foo",
      value: "bar",
      active: true
    }) {
    errors
    header {
      id
      key
      value
      active
    }
  }
}
```

헤더는 반환된 `errors` 개체가 비어 있으면 생성됩니다.

### 스트리밍 대상 나열 {#list-streaming-destinations}

인스턴스의 모든 HTTP 스트리밍 대상을 나열합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스입니다.

인스턴스에 대한 스트리밍 대상 목록을 보려면 `instanceExternalAuditEventDestinations` 쿼리 유형을 사용합니다.

```graphql
query {
  instanceExternalAuditEventDestinations {
    nodes {
      id
      name
      destinationUrl
      verificationToken
      headers {
        nodes {
          id
          key
          value
          active
        }
      }
      eventTypeFilters
    }
  }
}
```

결과 목록이 비어 있으면 인스턴스에 대해 감시 스트리밍이 활성화되지 않았습니다.

업데이트 및 삭제 변이를 위해 이 쿼리에서 반환한 ID 값이 필요합니다.

### 스트리밍 대상 업데이트 {#update-streaming-destinations}

인스턴스에 대한 HTTP 스트리밍 대상을 업데이트합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스입니다.

인스턴스에 대한 스트리밍 대상을 업데이트하려면 `instanceExternalAuditEventDestinationUpdate` 변이 유형을 사용합니다. 대상 ID는 인스턴스에 대해 [모든 외부 대상을 나열](#list-streaming-destinations)하여 검색할 수 있습니다.

```graphql
mutation {
  instanceExternalAuditEventDestinationUpdate(input: {
    id: "gid://gitlab/AuditEvents::InstanceExternalAuditEventDestination/1",
    destinationUrl: "https://www.new-domain.com/webhook",
    name: "destination-name"}) {
    errors
    instanceExternalAuditEventDestination {
      destinationUrl
      id
      name
      verificationToken
    }
  }
}
```

스트리밍 대상은 다음의 경우 업데이트됩니다:

- 반환된 `errors` 개체가 비어 있습니다.
- API는 `200 OK`로 응답합니다.

인스턴스 관리자는 `auditEventsStreamingInstanceHeadersUpdate` 변이 유형을 사용하여 스트리밍 대상 사용자 정의 HTTP 헤더를 업데이트할 수 있습니다. 사용자 정의 HTTP 헤더 ID는 인스턴스에 대해 [모든 사용자 정의 HTTP 헤더를 나열](#list-streaming-destinations)하여 검색할 수 있습니다.

```graphql
mutation {
  auditEventsStreamingInstanceHeadersUpdate(input: { headerId: "gid://gitlab/AuditEvents::Streaming::InstanceHeader/2", key: "new-key", value: "new-value", active: false }) {
    errors
    header {
      id
      key
      value
      active
    }
  }
}
```

헤더는 반환된 `errors` 개체가 비어 있으면 업데이트됩니다.

### 스트리밍 대상 삭제 {#delete-streaming-destinations}

전체 인스턴스에 대한 스트리밍 대상을 삭제합니다.

마지막 대상이 성공적으로 삭제되면 인스턴스에 대해 스트리밍이 비활성화됩니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스입니다.

스트리밍 대상을 삭제하려면 `instanceExternalAuditEventDestinationDestroy` 변이 유형을 사용합니다. 대상 ID는 인스턴스에 대해 [모든 스트리밍 대상을 나열](#list-streaming-destinations)하여 검색할 수 있습니다.

```graphql
mutation {
  instanceExternalAuditEventDestinationDestroy(input: { id: "gid://gitlab/AuditEvents::InstanceExternalAuditEventDestination/1" }) {
    errors
  }
}
```

스트리밍 대상은 다음의 경우 삭제됩니다:

- 반환된 `errors` 개체가 비어 있습니다.
- API는 `200 OK`로 응답합니다.

HTTP 헤더를 제거하려면 GraphQL `auditEventsStreamingInstanceHeadersDestroy` 변이를 사용합니다. 헤더 ID를 검색하려면 인스턴스에 대해 [모든 사용자 정의 HTTP 헤더를 나열](#list-streaming-destinations)합니다.

```graphql
mutation {
  auditEventsStreamingInstanceHeadersDestroy(input: { headerId: "gid://gitlab/AuditEvents::Streaming::InstanceHeader/<id>" }) {
    errors
  }
}
```

헤더는 반환된 `errors` 개체가 비어 있으면 삭제됩니다.

### 이벤트 유형 필터 {#event-type-filters}

{{< history >}}

- 이벤트 유형 필터 API는 GitLab 16.2에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/10868)되었습니다.

{{< /history >}}

인스턴스에 대해 이 기능이 활성화되면 API를 사용하여 사용자가 대상당 스트리밍된 감시 이벤트를 필터링할 수 있습니다. 기능이 필터 없이 활성화되면 대상이 모든 감시 이벤트를 수신합니다.

이벤트 유형 필터가 설정된 스트리밍 대상은 **필터링됨** ({{< icon name="filter" >}}) 레이블을 가집니다.

#### API를 사용하여 이벤트 유형 필터 추가 {#use-the-api-to-add-an-event-type-filter}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

`auditEventsStreamingDestinationInstanceEventsAdd` 변이를 사용하여 이벤트 유형 필터 목록을 추가할 수 있습니다:

```graphql
mutation {
    auditEventsStreamingDestinationInstanceEventsAdd(input: {
        destinationId: "gid://gitlab/AuditEvents::InstanceExternalAuditEventDestination/1",
        eventTypeFilters: ["list of event type filters"]}){
        errors
        eventTypeFilters
    }
}
```

이벤트 유형 필터는 다음의 경우 추가됩니다:

- 반환된 `errors` 개체가 비어 있습니다.
- API는 `200 OK`로 응답합니다.

#### API를 사용하여 이벤트 유형 필터 제거 {#use-the-api-to-remove-an-event-type-filter}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

`auditEventsStreamingDestinationInstanceEventsRemove` 변이를 사용하여 이벤트 유형 필터 목록을 제거할 수 있습니다:

```graphql
mutation {
    auditEventsStreamingDestinationInstanceEventsRemove(input: {
    destinationId: "gid://gitlab/AuditEvents::InstanceExternalAuditEventDestination/1",
    eventTypeFilters: ["list of event type filters"]
  }){
    errors
  }
}
```

이벤트 유형 필터는 다음의 경우 제거됩니다:

- 반환된 `errors` 개체가 비어 있습니다.
- API는 `200 OK`로 응답합니다.

## Google Cloud Logging 대상 {#google-cloud-logging-destinations}

{{< history >}}

- GitLab 16.5에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/11303)되었습니다.

{{< /history >}}

전체 인스턴스에 대한 Google Cloud Logging 대상을 관리합니다.

Google Cloud Logging 스트리밍 감시 이벤트를 설정하기 전에 [필수 요건](../../administration/compliance/audit_event_streaming.md#prerequisites)을 만족해야 합니다.

### 새로운 Google Cloud Logging 대상 추가 {#add-a-new-google-cloud-logging-destination}

인스턴스에 새로운 Google Cloud Logging 구성 대상을 추가합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있습니다.
- 서비스 계정을 만들고 Google Cloud Logging을 활성화할 수 있는 필요한 권한이 있는 Google Cloud 프로젝트가 있습니다.

스트리밍을 활성화하고 구성을 추가하려면 GraphQL API에서 `instanceGoogleCloudLoggingConfigurationCreate` 변이를 사용합니다.

```graphql
mutation {
  instanceGoogleCloudLoggingConfigurationCreate(input: { googleProjectIdName: "my-google-project", clientEmail: "my-email@my-google-project.iam.gservice.account.com", privateKey: "YOUR_PRIVATE_KEY", logIdName: "audit-events", name: "destination-name" } ) {
    errors
    googleCloudLoggingConfiguration {
      id
      googleProjectIdName
      logIdName
      clientEmail
      name
    }
    errors
  }
}
```

이벤트 스트리밍은 다음의 경우 활성화됩니다:

- 반환된 `errors` 개체가 비어 있습니다.
- API는 `200 OK`로 응답합니다.

### Google Cloud Logging 구성 나열 {#list-google-cloud-logging-configurations}

인스턴스의 모든 Google Cloud Logging 구성 대상을 나열합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있습니다.

`instanceGoogleCloudLoggingConfigurations` 쿼리 유형을 사용하여 인스턴스에 대한 스트리밍 구성 목록을 볼 수 있습니다.

```graphql
query {
  instanceGoogleCloudLoggingConfigurations {
    nodes {
      id
      logIdName
      googleProjectIdName
      clientEmail
      name
    }
  }
}
```

결과 목록이 비어 있으면 인스턴스에 대해 감시 스트리밍이 활성화되지 않았습니다.

업데이트 및 삭제 변이를 위해 이 쿼리에서 반환한 ID 값이 필요합니다.

### Google Cloud Logging 구성 업데이트 {#update-google-cloud-logging-configurations}

인스턴스에 대한 Google Cloud Logging 구성 대상을 업데이트합니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있습니다.

인스턴스에 대한 스트리밍 구성을 업데이트하려면 `instanceGoogleCloudLoggingConfigurationUpdate` 변이 유형을 사용합니다. 구성 ID는 [모든 외부 대상을 나열](#list-google-cloud-logging-configurations)하여 검색할 수 있습니다.

```graphql
mutation {
  instanceGoogleCloudLoggingConfigurationUpdate(
    input: {id: "gid://gitlab/AuditEvents::Instance::GoogleCloudLoggingConfiguration/1", googleProjectIdName: "updated-google-id", clientEmail: "updated@my-google-project.iam.gservice.account.com", privateKey: "YOUR_PRIVATE_KEY", logIdName: "audit-events", name: "updated name"}
  ) {
    errors
    instanceGoogleCloudLoggingConfiguration {
      id
      logIdName
      googleProjectIdName
      clientEmail
      name
    }
  }
}
```

스트리밍 구성은 다음의 경우 업데이트됩니다:

- 반환된 `errors` 개체가 비어 있습니다.
- API는 `200 OK`로 응답합니다.

### Google Cloud Logging 구성 삭제 {#delete-google-cloud-logging-configurations}

인스턴스에 대한 스트리밍 대상을 삭제합니다.

마지막 대상이 성공적으로 삭제되면 인스턴스에 대해 스트리밍이 비활성화됩니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있습니다.

스트리밍 구성을 삭제하려면 `instanceGoogleCloudLoggingConfigurationDestroy` 변이 유형을 사용합니다. 구성 ID는 인스턴스에 대해 [모든 스트리밍 대상을 나열](#list-google-cloud-logging-configurations)하여 검색할 수 있습니다.

```graphql
mutation {
  instanceGoogleCloudLoggingConfigurationDestroy(input: { id: "gid://gitlab/AuditEvents::Instance::GoogleCloudLoggingConfiguration/1" }) {
    errors
  }
}
```

스트리밍 구성은 다음의 경우 삭제됩니다:

- 반환된 `errors` 개체가 비어 있습니다.
- API는 `200 OK`로 응답합니다.
