---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GraphQL APIを使用して、GitLabインスタンス全体の監査イベントストリーミング先を管理します。これには、HTTPおよびGoogle Cloud Logging設定が含まれます。
title: インスタンスの監査イベントストリーミングGraphQL API
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.0で`ff_external_audit_events`[フラグ](../feature_flags.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/335175)されました。デフォルトでは無効になっています。
- インスタンスレベルのストリーミング先のカスタムHTTPヘッダーのAPIは、GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/404560)されました。`ff_external_audit_events`という名前の[フラグ付き](../feature_flags.md)。デフォルトでは無効になっています。
- [機能フラグ`ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/393772)は、GitLab 16.2でデフォルトで有効になっています。
- ユーザー指定のストリーミング先名APIサポートは、GitLab 16.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/413894)。
- インスタンスのストリーミング先は、GitLab 16.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/393772)されました。[機能フラグ`ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/417708)は削除されました。

{{< /history >}}

GraphQL APIを使用して、インスタンスの監査イベントストリーミング先を管理します。

## HTTPの送信先 {#http-destinations}

インスタンス全体のHTTPストリーミング先を管理します。

### 新しいHTTPの送信先を追加 {#add-a-new-http-destination}

新しいHTTPストリーミング先をインスタンスに追加します。

前提要件: 

- インスタンスの管理者アクセス制御。

ストリーミングを有効にしてストリーミング先を追加するには、GraphQL APIで`instanceExternalAuditEventDestinationCreate`ミューテーションを使用します。

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

イベントストリーミングが有効になるのは、次の場合です:

- 返された`errors`オブジェクトが空です。
- APIが`200 OK`で応答します。

オプションで、GraphQL `instanceExternalAuditEventDestinationCreate`ミューテーションを使用して、（デフォルトのGitLab生成の代わりに）独自のストリーミング先名を指定できます。名前の長さは72文字を超えてはならず、末尾の空白はトリミングされません。この値は一意である必要があります。例: 

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

インスタンスの管理者は、GraphQL `auditEventsStreamingInstanceHeadersCreate`ミューテーションを使用してHTTPヘッダーを追加できます。ストリーミング先IDは、インスタンスの[ストリーミング先をすべて一覧表示](#list-streaming-destinations)するか、前のミューテーションから取得することができます。

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

返された`errors`オブジェクトが空の場合、ヘッダーが作成されます。

### ストリーミング先をリスト {#list-streaming-destinations}

インスタンスのすべてのHTTPストリーミング先を一覧表示します。

前提要件: 

- インスタンスの管理者アクセス制御。

インスタンスのストリーミング先のリストを表示するには、`instanceExternalAuditEventDestinations`クエリタイプを使用します。

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

結果のリストが空の場合、インスタンスに対して監査ストリーミングは有効になっていません。

更新および削除ミューテーションには、このクエリから返されたID値が必要です。

### ストリーミング先を更新する {#update-streaming-destinations}

インスタンスのHTTPストリーミング先を更新します。

前提要件: 

- インスタンスの管理者アクセス制御。

インスタンスのストリーミング先を更新するには、`instanceExternalAuditEventDestinationUpdate`ミューテーションタイプを使用します。ストリーミング先IDは、インスタンスの[外部のストリーミング先をすべて一覧表示](#list-streaming-destinations)することで取得することができます。

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

ストリーミング先が更新されるのは、次の場合です:

- 返された`errors`オブジェクトが空です。
- APIが`200 OK`で応答します。

インスタンスの管理者は、`auditEventsStreamingInstanceHeadersUpdate`ミューテーションタイプを使用して、ストリーミング先のカスタムHTTPヘッダーを更新できます。カスタムHTTPヘッダーIDは、インスタンスの[カスタムHTTPヘッダーをすべて一覧表示](#list-streaming-destinations)することで取得することができます。

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

返された`errors`オブジェクトが空の場合、ヘッダーが更新されます。

### ストリーミング先を削除する {#delete-streaming-destinations}

インスタンス全体のストリーミング先を削除します。

最後のストリーミング先が正常に削除されると、インスタンスのストリーミングは無効になります。

前提要件: 

- インスタンスの管理者アクセス制御。

ストリーミング先を削除するには、`instanceExternalAuditEventDestinationDestroy`ミューテーションタイプを使用します。ストリーミング先IDは、インスタンスの[ストリーミング先をすべて一覧表示](#list-streaming-destinations)することで取得することができます。

```graphql
mutation {
  instanceExternalAuditEventDestinationDestroy(input: { id: "gid://gitlab/AuditEvents::InstanceExternalAuditEventDestination/1" }) {
    errors
  }
}
```

ストリーミング先が削除されるのは、次の場合です:

- 返された`errors`オブジェクトが空です。
- APIが`200 OK`で応答します。

HTTPヘッダーを削除するには、GraphQL `auditEventsStreamingInstanceHeadersDestroy`ミューテーションを使用します。ヘッダーIDを取得するには、インスタンスの[カスタムHTTPヘッダーをすべて一覧表示](#list-streaming-destinations)します。

```graphql
mutation {
  auditEventsStreamingInstanceHeadersDestroy(input: { headerId: "gid://gitlab/AuditEvents::Streaming::InstanceHeader/<id>" }) {
    errors
  }
}
```

返された`errors`オブジェクトが空の場合、ヘッダーは削除されます。

### イベントタイプのフィルター {#event-type-filters}

{{< history >}}

- イベントの種類のフィルターAPIは、GitLab 16.2で[導入](https://gitlab.com/groups/gitlab-org/-/epics/10868)されました。

{{< /history >}}

この機能がインスタンスに対して有効になっている場合、APIを使用して、ストリーミングされた監査イベントをストリーミング先ごとにフィルタリングできます。機能がフィルターなしで有効になっている場合、送信先はすべての監査イベントを受信します。

イベントタイプのフィルターが設定されているストリーミング先には、**フィルタリング済み** ({{< icon name="filter" >}}) ラベルが付きます。

#### APIを使用してイベントタイプのフィルターを追加する {#use-the-api-to-add-an-event-type-filter}

前提要件: 

- インスタンスに対する管理者アクセス権が必要です。

`auditEventsStreamingDestinationInstanceEventsAdd`ミューテーションを使用して、イベントの種類のフィルターのリストを追加できます:

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

イベントタイプの種類のフィルターは、次の場合に追加されます:

- 返された`errors`オブジェクトが空です。
- APIが`200 OK`で応答します。

#### APIを使用してイベントタイプのフィルターを削除する {#use-the-api-to-remove-an-event-type-filter}

前提要件: 

- インスタンスに対する管理者アクセス権が必要です。

`auditEventsStreamingDestinationInstanceEventsRemove`ミューテーションを使用して、イベントの種類のフィルターのリストを削除できます:

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

イベントタイプのフィルターが削除されるのは、次の場合です:

- 返された`errors`オブジェクトが空です。
- APIが`200 OK`で応答します。

## Google Cloud Loggingの送信先 {#google-cloud-logging-destinations}

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/groups/gitlab-org/-/epics/11303)されました。

{{< /history >}}

インスタンス全体のGoogle Cloud Loggingの送信先を管理します。

Google Cloud Logging監査イベントのストリーミングを設定する前に、[前提条件](../../administration/compliance/audit_event_streaming.md#prerequisites)を満たす必要があります。

### 新しいGoogle Cloud Loggingの送信先を追加 {#add-a-new-google-cloud-logging-destination}

新しいGoogle Cloud Logging設定のストリーミング先をインスタンスに追加します。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。
- サービスアカウントを作成し、Google Cloud Loggingを有効にするために必要な権限を持つGoogle Cloudプロジェクトが必要です。

ストリーミングを有効にして設定を追加するには、GraphQL APIで`instanceGoogleCloudLoggingConfigurationCreate`ミューテーションを使用します。

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

イベントストリーミングが有効になるのは、次の場合です:

- 返された`errors`オブジェクトが空です。
- APIが`200 OK`で応答します。

### Google Cloud Logging設定を一覧表示する {#list-google-cloud-logging-configurations}

インスタンスのすべてのGoogle Cloud Logging設定のストリーミング先を一覧表示します。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

インスタンスのストリーミング設定のリストを表示するには、`instanceGoogleCloudLoggingConfigurations`クエリタイプを使用します。

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

結果のリストが空の場合、インスタンスに対して監査ストリーミングは有効になっていません。

更新および削除ミューテーションには、このクエリから返されたID値が必要です。

### Google Cloud Logging設定を更新する {#update-google-cloud-logging-configurations}

インスタンスのGoogle Cloud Logging設定のストリーミング先を更新します。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

インスタンスの設定を更新するには、`instanceGoogleCloudLoggingConfigurationUpdate`ミューテーションタイプを使用します。設定IDは、[外部のストリーミング先をすべて一覧表示](#list-google-cloud-logging-configurations)ことで取得することができます。

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

ストリーミングの設定が更新されるのは、次の場合です:

- 返された`errors`オブジェクトが空です。
- APIが`200 OK`で応答します。

### Google Cloud Logging設定を削除する {#delete-google-cloud-logging-configurations}

インスタンスのストリーミング先を削除します。

最後のストリーミング先が正常に削除されると、インスタンスのストリーミングは無効になります。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

設定を削除するには、`instanceGoogleCloudLoggingConfigurationDestroy`ミューテーションタイプを使用します。設定IDは、インスタンスの[ストリーミング先をすべて一覧表示](#list-google-cloud-logging-configurations)することで取得することができます。

```graphql
mutation {
  instanceGoogleCloudLoggingConfigurationDestroy(input: { id: "gid://gitlab/AuditEvents::Instance::GoogleCloudLoggingConfiguration/1" }) {
    errors
  }
}
```

ストリーミングの設定が削除されるのは、次の場合です:

- 返された`errors`オブジェクトが空です。
- APIが`200 OK`で応答します。
