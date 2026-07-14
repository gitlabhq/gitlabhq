---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GraphQL API를 사용하여 최상위 그룹의 감사 이벤트 스트리밍 대상을 관리합니다. HTTP 및 Google Cloud Logging 구성을 포함합니다.
title: 최상위 그룹을 위한 감사 이벤트 스트리밍 GraphQL API
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 사용자 정의 HTTP 헤더 API는 GitLab 15.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/361216) 되었으며 `streaming_audit_event_headers`라는 [플래그](../feature_flags.md)를 사용합니다. 기본적으로 비활성화됨.
- 사용자 정의 HTTP 헤더 API [는 GitLab.com 및 GitLab Self-Managed에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/362941)되었으며 GitLab 15.2에서 제공됩니다.
- 사용자 정의 HTTP 헤더 API [는 GitLab 15.3에서 일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/366524)되었습니다. [`streaming_audit_event_headers` 기능 플래그](https://gitlab.com/gitlab-org/gitlab/-/issues/362941)가 제거되었습니다.
- 사용자 지정 검증 토큰 API 지원 [은 GitLab 15.4에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/360813)되었습니다.
- [`ff_external_audit_events` 기능 플래그](https://gitlab.com/gitlab-org/gitlab/-/issues/393772)는 GitLab 16.2에서 기본적으로 활성화되었습니다.
- 사용자 지정 대상 이름 API 지원 [은 GitLab 16.2에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/413894)되었습니다.
- API [`ff_external_audit_events` 기능 플래그](https://gitlab.com/gitlab-org/gitlab/-/issues/417708)는 GitLab 16.4에서 제거되었습니다.

{{< /history >}}

GraphQL API를 사용하여 최상위 그룹의 감사 이벤트 스트리밍 대상을 관리합니다.

## HTTP 대상 {#http-destinations}

최상위 그룹을 위한 HTTP 스트리밍 대상을 관리합니다.

### 새 스트리밍 대상 추가 {#add-a-new-streaming-destination}

최상위 그룹에 새 스트리밍 대상을 추가합니다.

> [!warning]
> 스트리밍 대상은 **전체** 감사 이벤트 데이터를 수신하며, 여기에는 민감한 정보가 포함될 수 있습니다. 스트리밍 대상을 신뢰하는지 확인합니다.

전제 조건:

- 최상위 그룹의 소유자 역할입니다.

스트리밍을 활성화하고 최상위 그룹에 대상을 추가하려면 `externalAuditEventDestinationCreate` 변형을 사용합니다.

```graphql
mutation {
  externalAuditEventDestinationCreate(input: { destinationUrl: "https://mydomain.io/endpoint/ingest", groupPath: "my-group" } ) {
    errors
    externalAuditEventDestination {
      id
      name
      destinationUrl
      verificationToken
      group {
        name
      }
    }
  }
}
```

GraphQL `externalAuditEventDestinationCreate` 변형을 사용하여 선택적으로 자신의 검증 토큰(기본 GitLab 생성 토큰 대신)을 지정할 수 있습니다. 검증 토큰 길이는 16~24자 범위 내여야 하며 후행 공백은 제거되지 않습니다. 암호화 방식으로 안전한 고유 값을 설정해야 합니다. 예를 들어:

```graphql
mutation {
  externalAuditEventDestinationCreate(input: { destinationUrl: "https://mydomain.io/endpoint/ingest", groupPath: "my-group", verificationToken: "unique-random-verification-token-here" } ) {
    errors
    externalAuditEventDestination {
      id
      name
      destinationUrl
      verificationToken
      group {
        name
      }
    }
  }
}
```

GraphQL `externalAuditEventDestinationCreate` 변형을 사용하여 선택적으로 자신의 대상 이름(기본 GitLab 생성 이름 대신)을 지정할 수 있습니다. 이름 길이는 72자를 초과할 수 없으며 후행 공백은 제거되지 않습니다. 이 값은 그룹 범위 내에서 고유해야 합니다. 예를 들어:

```graphql
mutation {
  externalAuditEventDestinationCreate(input: { destinationUrl: "https://mydomain.io/endpoint/ingest", name: "destination-name-here", groupPath: "my-group" }) {
    errors
    externalAuditEventDestination {
      id
      name
      destinationUrl
      verificationToken
      group {
        name
      }
    }
  }
}
```

이벤트 스트리밍은 다음 조건에서 활성화됩니다:

- 반환된 `errors` 객체가 비어 있습니다.
- API가 `200 OK`로 응답합니다.

GraphQL `auditEventsStreamingHeadersCreate` 변형을 사용하여 HTTP 헤더를 추가할 수 있습니다. [모든 스트리밍 대상 나열](#list-streaming-destinations)을 통해 대상 ID를 검색하거나 위의 변형에서 검색할 수 있습니다.

```graphql
mutation {
  auditEventsStreamingHeadersCreate(input: {
    destinationId: "gid://gitlab/AuditEvents::ExternalAuditEventDestination/1",
     key: "foo",
     value: "bar",
     active: false
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

반환된 `errors` 객체가 비어 있으면 헤더가 생성됩니다.

### 스트리밍 대상 나열 {#list-streaming-destinations}

최상위 그룹의 스트리밍 대상을 나열합니다.

전제 조건:

- 최상위 그룹의 소유자 역할입니다.

`externalAuditEventDestinations` 쿼리 유형을 사용하여 최상위 그룹의 스트리밍 대상 목록을 볼 수 있습니다.

```graphql
query {
  group(fullPath: "my-group") {
    id
    externalAuditEventDestinations {
      nodes {
        destinationUrl
        verificationToken
        id
        name
        headers {
          nodes {
            key
            value
            id
            active
          }
        }
        eventTypeFilters
        namespaceFilter {
          id
          namespace {
            id
            name
            fullName
          }
        }
      }
    }
  }
}
```

결과 목록이 비어 있으면 해당 그룹에 대해 감사 스트리밍이 활성화되지 않습니다.

### 스트리밍 대상 업데이트 {#update-streaming-destinations}

최상위 그룹의 스트리밍 대상을 업데이트합니다.

전제 조건:

- 최상위 그룹의 소유자 역할입니다.

그룹의 스트리밍 대상을 업데이트하려면 `externalAuditEventDestinationUpdate` 변형 유형을 사용합니다. [모든 스트리밍 대상 나열](#list-streaming-destinations)을 통해 대상 ID를 검색할 수 있습니다.

```graphql
mutation {
  externalAuditEventDestinationUpdate(input: {
    id:"gid://gitlab/AuditEvents::ExternalAuditEventDestination/1",
    destinationUrl: "https://www.new-domain.com/webhook",
    name: "destination-name"} ) {
    errors
    externalAuditEventDestination {
      id
      name
      destinationUrl
      verificationToken
      group {
        name
      }
    }
  }
}
```

스트리밍 대상은 다음 조건에서 업데이트됩니다:

- 반환된 `errors` 객체가 비어 있습니다.
- API가 `200 OK`로 응답합니다.

그룹의 소유자 역할을 가진 사용자는 `auditEventsStreamingHeadersUpdate` 변형 유형을 사용하여 스트리밍 대상의 사용자 정의 HTTP 헤더를 업데이트할 수 있습니다. [모든 사용자 정의 HTTP 헤더 나열](#list-streaming-destinations)을 통해 사용자 정의 HTTP 헤더 ID를 검색할 수 있습니다.

```graphql
mutation {
  auditEventsStreamingHeadersUpdate(input: { headerId: "gid://gitlab/AuditEvents::Streaming::Header/2", key: "new-key", value: "new-value", active: false }) {
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

그룹 소유자는 GraphQL `auditEventsStreamingHeadersDestroy` 변형을 사용하여 HTTP 헤더를 제거할 수 있습니다. [모든 사용자 정의 HTTP 헤더 나열](#list-streaming-destinations)을 통해 헤더 ID를 검색할 수 있습니다.

```graphql
mutation {
  auditEventsStreamingHeadersDestroy(input: { headerId: "gid://gitlab/AuditEvents::Streaming::Header/1" }) {
    errors
  }
}
```

반환된 `errors` 객체가 비어 있으면 헤더가 삭제됩니다.

### 스트리밍 대상 삭제 {#delete-streaming-destinations}

최상위 그룹의 스트리밍 대상을 삭제합니다.

마지막 대상이 성공적으로 삭제되면 그룹에 대한 스트리밍이 비활성화됩니다.

전제 조건:

- 최상위 그룹의 소유자 역할입니다.

그룹의 소유자 역할을 가진 사용자는 `externalAuditEventDestinationDestroy` 변형 유형을 사용하여 스트리밍 대상을 삭제할 수 있습니다. [모든 스트리밍 대상 나열](#list-streaming-destinations)을 통해 대상 ID를 검색할 수 있습니다.

```graphql
mutation {
  externalAuditEventDestinationDestroy(input: { id: destination }) {
    errors
  }
}
```

스트리밍 대상은 다음 조건에서 삭제됩니다:

- 반환된 `errors` 객체가 비어 있습니다.
- API가 `200 OK`로 응답합니다.

그룹 소유자는 GraphQL `auditEventsStreamingHeadersDestroy` 변형을 사용하여 HTTP 헤더를 제거할 수 있습니다. [모든 사용자 정의 HTTP 헤더 나열](#list-streaming-destinations)을 통해 헤더 ID를 검색할 수 있습니다.

```graphql
mutation {
  auditEventsStreamingHeadersDestroy(input: { headerId: "gid://gitlab/AuditEvents::Streaming::Header/1" }) {
    errors
  }
}
```

반환된 `errors` 객체가 비어 있으면 헤더가 삭제됩니다.

### 이벤트 유형 필터 {#event-type-filters}

{{< history >}}

- 이벤트 유형 필터 API [는 GitLab 15.7에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/344845)되었습니다.

{{< /history >}}

이 기능이 그룹에 대해 활성화된 경우 API를 사용하여 사용자가 대상별로 스트리밍된 감사 이벤트를 필터링하도록 허용할 수 있습니다. 기능이 필터 없이 활성화된 경우 대상은 모든 감사 이벤트를 수신합니다.

이벤트 유형 필터가 설정된 스트리밍 대상에는 **필터링됨** ({{< icon name="filter" >}}) 레이블이 있습니다.

#### 이벤트 유형 필터를 추가하기 위해 API 사용 {#use-the-api-to-add-an-event-type-filter}

전제 조건:

- 그룹의 Owner 역할이 있어야 합니다.

`auditEventsStreamingDestinationEventsAdd` 쿼리 유형을 사용하여 이벤트 유형 필터 목록을 추가할 수 있습니다:

```graphql
mutation {
    auditEventsStreamingDestinationEventsAdd(input: {
        destinationId: "gid://gitlab/AuditEvents::ExternalAuditEventDestination/1",
        eventTypeFilters: ["list of event type filters"]}){
        errors
        eventTypeFilters
    }
}
```

이벤트 유형 필터는 다음 조건에서 추가됩니다:

- 반환된 `errors` 객체가 비어 있습니다.
- API가 `200 OK`로 응답합니다.

#### 이벤트 유형 필터를 제거하기 위해 API 사용 {#use-the-api-to-remove-an-event-type-filter}

전제 조건:

- 그룹의 Owner 역할이 있어야 합니다.

`auditEventsStreamingDestinationEventsRemove` 변형 유형을 사용하여 이벤트 유형 필터 목록을 제거할 수 있습니다:

```graphql
mutation {
    auditEventsStreamingDestinationEventsRemove(input: {
    destinationId: "gid://gitlab/AuditEvents::ExternalAuditEventDestination/1",
    eventTypeFilters: ["list of event type filters"]
  }){
    errors
  }
}
```

이벤트 유형 필터는 다음 조건에서 제거됩니다:

- 반환된 `errors` 객체가 비어 있습니다.
- API가 `200 OK`로 응답합니다.

### 네임스페이스 필터 {#namespace-filters}

{{< history >}}

- 네임스페이스 필터 API [는 GitLab 16.7에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/344845)되었습니다.

{{< /history >}}

그룹에 네임스페이스 필터를 적용하면 사용자는 그룹의 특정 부분 그룹 또는 프로젝트에 대해 대상별로 스트리밍된 감사 이벤트를 필터링할 수 있습니다. 그 외의 경우 대상은 모든 감사 이벤트를 수신합니다.

네임스페이스 필터가 설정된 스트리밍 대상에는 **필터링됨** ({{< icon name="filter" >}}) 레이블이 있습니다.

#### 네임스페이스 필터를 추가하기 위해 API 사용 {#use-the-api-to-add-a-namespace-filter}

전제 조건:

- 그룹의 Owner 역할이 있어야 합니다.

`auditEventsStreamingHttpNamespaceFiltersAdd` 변형 유형을 사용하여 부분 그룹과 프로젝트 모두에 대한 네임스페이스 필터를 추가할 수 있습니다.

네임스페이스 필터는 다음 조건에서 추가됩니다:

- API가 빈 `errors` 객체를 반환합니다.
- API가 `200 OK`로 응답합니다.

##### 부분 그룹을 위한 변형 {#mutation-for-subgroup}

```graphql
mutation auditEventsStreamingHttpNamespaceFiltersAdd {
  auditEventsStreamingHttpNamespaceFiltersAdd(input: {
    destinationId: "gid://gitlab/AuditEvents::ExternalAuditEventDestination/1",
    groupPath: "path/to/subgroup"
  }) {
    errors
    namespaceFilter {
      id
      namespace {
        id
        name
        fullName
      }
    }
  }
}
```

##### 프로젝트를 위한 변형 {#mutation-for-project}

```graphql
mutation auditEventsStreamingHttpNamespaceFiltersAdd {
  auditEventsStreamingHttpNamespaceFiltersAdd(input: {
    destinationId: "gid://gitlab/AuditEvents::ExternalAuditEventDestination/1",
    projectPath: "path/to/project"
  }) {
    errors
    namespaceFilter {
      id
      namespace {
        id
        name
        fullName
      }
    }
  }
}
```

#### 네임스페이스 필터를 제거하기 위해 API 사용 {#use-the-api-to-remove-a-namespace-filter}

전제 조건:

- 그룹의 Owner 역할이 있어야 합니다.

`auditEventsStreamingHttpNamespaceFiltersDelete` 변형 유형을 사용하여 네임스페이스 필터를 제거할 수 있습니다:

```graphql
mutation auditEventsStreamingHttpNamespaceFiltersDelete {
  auditEventsStreamingHttpNamespaceFiltersDelete(input: {
    namespaceFilterId: "gid://gitlab/AuditEvents::Streaming::HTTP::NamespaceFilter/5"
  }) {
    errors
  }
}
```

네임스페이스 필터는 다음 조건에서 제거됩니다:

- 반환된 `errors` 객체가 비어 있습니다.
- API가 `200 OK`로 응답합니다.

## Google Cloud Logging 대상 {#google-cloud-logging-destinations}

{{< history >}}

- [GitLab 16.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/409422)되었습니다.

{{< /history >}}

최상위 그룹을 위한 Google Cloud Logging 대상을 관리합니다.

Google Cloud Logging 스트리밍 감사 이벤트를 설정하기 전에 [사전 요구 사항](../../user/compliance/audit_event_streaming.md#prerequisites)을 충족해야 합니다.

### 새 Google Cloud Logging 대상 추가 {#add-a-new-google-cloud-logging-destination}

최상위 그룹에 새 Google Cloud Logging 구성 대상을 추가합니다.

전제 조건:

- 최상위 그룹의 소유자 역할입니다.
- 서비스 계정을 만들고 Google Cloud Logging을 활성화할 수 있는 필수 권한이 있는 Google Cloud 프로젝트입니다.

스트리밍을 활성화하고 구성을 추가하려면 GraphQL API에서 `googleCloudLoggingConfigurationCreate` 변형을 사용합니다.

```graphql
mutation {
  googleCloudLoggingConfigurationCreate(input: { groupPath: "my-group", googleProjectIdName: "my-google-project", clientEmail: "my-email@my-google-project.iam.gservice.account.com", privateKey: "YOUR_PRIVATE_KEY", logIdName: "audit-events", name: "destination-name" } ) {
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

이벤트 스트리밍은 다음 조건에서 활성화됩니다:

- 반환된 `errors` 객체가 비어 있습니다.
- API가 `200 OK`로 응답합니다.

### Google Cloud Logging 구성 나열 {#list-google-cloud-logging-configurations}

최상위 그룹의 모든 Google Cloud Logging 구성 대상을 나열합니다.

전제 조건:

- 최상위 그룹의 소유자 역할입니다.

`googleCloudLoggingConfigurations` 쿼리 유형을 사용하여 최상위 그룹의 스트리밍 구성 목록을 볼 수 있습니다.

```graphql
query {
  group(fullPath: "my-group") {
    id
    googleCloudLoggingConfigurations {
      nodes {
        id
        logIdName
        googleProjectIdName
        clientEmail
        name
      }
    }
  }
}
```

결과 목록이 비어 있으면 해당 그룹에 대해 감사 스트리밍이 활성화되지 않습니다.

업데이트 및 삭제 변형을 위해 이 쿼리로 반환된 ID 값이 필요합니다.

### Google Cloud Logging 구성 업데이트 {#update-google-cloud-logging-configurations}

최상위 그룹의 Google Cloud Logging 구성 대상을 업데이트합니다.

전제 조건:

- 최상위 그룹의 소유자 역할입니다.

최상위 그룹의 스트리밍 구성을 업데이트하려면 `googleCloudLoggingConfigurationUpdate` 변형 유형을 사용합니다. [모든 외부 대상 나열](#list-google-cloud-logging-configurations)을 통해 구성 ID를 검색할 수 있습니다.

```graphql
mutation {
  googleCloudLoggingConfigurationUpdate(
    input: {id: "gid://gitlab/AuditEvents::GoogleCloudLoggingConfiguration/1", googleProjectIdName: "my-google-project", clientEmail: "my-email@my-google-project.iam.gservice.account.com", privateKey: "YOUR_PRIVATE_KEY", logIdName: "audit-events", name: "updated-destination-name" }
  ) {
    errors
    googleCloudLoggingConfiguration {
      id
      logIdName
      googleProjectIdName
      clientEmail
      name
    }
  }
}
```

스트리밍 구성은 다음 조건에서 업데이트됩니다:

- 반환된 `errors` 객체가 비어 있습니다.
- API가 `200 OK`로 응답합니다.

### Google Cloud Logging 구성 삭제 {#delete-google-cloud-logging-configurations}

최상위 그룹의 스트리밍 대상을 삭제합니다.

마지막 대상이 성공적으로 삭제되면 그룹에 대한 스트리밍이 비활성화됩니다.

전제 조건:

- 최상위 그룹의 소유자 역할입니다.

그룹의 소유자 역할을 가진 사용자는 `googleCloudLoggingConfigurationDestroy` 변형 유형을 사용하여 스트리밍 구성을 삭제할 수 있습니다. [모든 스트리밍 대상 나열](#list-google-cloud-logging-configurations)을 통해 구성 ID를 검색할 수 있습니다.

```graphql
mutation {
  googleCloudLoggingConfigurationDestroy(input: { id: "gid://gitlab/AuditEvents::GoogleCloudLoggingConfiguration/1" }) {
    errors
  }
}
```

스트리밍 구성은 다음 조건에서 삭제됩니다:

- 반환된 `errors` 객체가 비어 있습니다.
- API가 `200 OK`로 응답합니다.
