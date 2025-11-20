---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GraphQL APIを使用して、HTTPおよびGoogle Cloud Loggingの設定を含む、トップレベルグループの監査イベントストリーミングのストリーミング先を管理します。
title: トップレベルグループの監査イベントストリーミングGraphQL API
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- カスタムHTTPヘッダーAPIは、`streaming_audit_event_headers`という[機能フラグ](../feature_flags.md)付きで、GitLab 15.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/361216)されました。デフォルトでは無効になっています。
- カスタムHTTPヘッダーAPIが、[GitLab.comとGitLab Self-Managedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/362941)（GitLab 15.2）。
- カスタムHTTPヘッダーAPIは、GitLab 15.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/366524)されました。[機能フラグ`streaming_audit_event_headers`](https://gitlab.com/gitlab-org/gitlab/-/issues/362941)は削除されました。
- ユーザー指定の検証トークンAPIのサポートがGitLab 15.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/360813)。
- [機能フラグ`ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/393772)は、GitLab 16.2でデフォルトで有効になっています。
- ユーザー指定のストリーミング先名APIサポートは、GitLab 16.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/413894)。
- APIの[機能フラグ`ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/417708)は、GitLab 16.4で削除されました。

{{< /history >}}

GraphQL APIを使用して、トップレベルグループの監査イベントストリーミングのストリーミング先を管理します。

## HTTPの送信先 {#http-destinations}

トップレベルグループのHTTP監査イベントストリーミングのストリーミング先を管理します。

### 新しいストリーミング先の追加 {#add-a-new-streaming-destination}

トップレベルグループに新しいストリーミング先を追加します。

{{< alert type="warning" >}}

ストリーミング先は、**すべて**の監査イベントデータを受信します。これには機密情報が含まれる可能性があります。ストリーミング先を信頼できることを確認してください。

{{< /alert >}}

前提要件: 

- トップレベルグループのオーナーロール。

監査イベントストリーミングを有効にして、トップレベルグループにストリーミング先を追加するには、`externalAuditEventDestinationCreate`ミューテーションを使用します。

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

オプションで、GraphQL `externalAuditEventDestinationCreate`ミューテーションを使用して、（デフォルトのGitLab生成の代わりに）独自の検証トークンを指定できます。検証トークンの長さは16〜24文字で、末尾の空白はトリミングされません。暗号論的にランダムで一意の値を設定する必要があります。例: 

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

オプションで、GraphQL `externalAuditEventDestinationCreate`ミューテーションを使用して、（デフォルトのGitLab生成の代わりに）独自のストリーミング先名を指定できます。名前の長さは72文字を超えてはならず、末尾の空白はトリミングされません。この値は、グループに対して一意のスコープである必要があります。例: 

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

イベントストリーミングが有効になるのは、次の場合です:

- 返された`errors`オブジェクトが空です。
- APIが`200 OK`で応答します。

GraphQL `auditEventsStreamingHeadersCreate`ミューテーションを使用して、HTTPヘッダーを追加できます。ストリーミング先IDは、グループの[ストリーミング先をすべてリストする](#list-streaming-destinations)か、上記のミューテーションから取得することができます。

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

返された`errors`オブジェクトが空の場合、ヘッダーが作成されます。

### ストリーミング先をリスト {#list-streaming-destinations}

トップレベルグループのストリーミング先をリストします。

前提要件: 

- トップレベルグループのオーナーロール。

`externalAuditEventDestinations`クエリタイプを使用して、トップレベルグループのストリーミング先のリストを表示できます。

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

結果のリストが空の場合、監査イベントストリーミングはそのグループに対して有効になっていません。

### ストリーミング先を更新する {#update-streaming-destinations}

トップレベルグループのストリーミング先を更新します。

前提要件: 

- トップレベルグループのオーナーロール。

グループのストリーミング先を更新するには、`externalAuditEventDestinationUpdate`ミューテーションタイプを使用します。ストリーミング先IDは、グループの[ストリーミング先をすべてリストする](#list-streaming-destinations)ことで取得することができます。

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

ストリーミング先が更新されるのは、次の場合です:

- 返された`errors`オブジェクトが空です。
- APIが`200 OK`で応答します。

グループのオーナーロールを持つユーザーは、`auditEventsStreamingHeadersUpdate`ミューテーションタイプを使用して、ストリーミング先のカスタムHTTPヘッダーを更新できます。グループの[カスタムHTTPヘッダーをすべてリストする](#list-streaming-destinations)ことで、カスタムHTTPヘッダーIDを取得することができます。

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

グループオーナーは、GraphQL `auditEventsStreamingHeadersDestroy`ミューテーションを使用してHTTPヘッダーを削除できます。グループの[カスタムHTTPヘッダーをすべてリストする](#list-streaming-destinations)ことで、ヘッダーIDを取得することができます。

```graphql
mutation {
  auditEventsStreamingHeadersDestroy(input: { headerId: "gid://gitlab/AuditEvents::Streaming::Header/1" }) {
    errors
  }
}
```

返された`errors`オブジェクトが空の場合、ヘッダーは削除されます。

### ストリーミング先を削除する {#delete-streaming-destinations}

トップレベルグループのストリーミング先を削除します。

最後のストリーミング先が正常に削除されると、グループのストリーミングは無効になります。

前提要件: 

- トップレベルグループのオーナーロール。

グループのオーナーロールを持つユーザーは、`externalAuditEventDestinationDestroy`ミューテーションタイプを使用して、ストリーミング先を削除できます。ストリーミング先IDは、グループの[ストリーミング先をすべてリストする](#list-streaming-destinations)ことで取得することができます。

```graphql
mutation {
  externalAuditEventDestinationDestroy(input: { id: destination }) {
    errors
  }
}
```

ストリーミング先が削除されるのは、次の場合です:

- 返された`errors`オブジェクトが空です。
- APIが`200 OK`で応答します。

グループオーナーは、GraphQL `auditEventsStreamingHeadersDestroy`ミューテーションを使用してHTTPヘッダーを削除できます。グループの[カスタムHTTPヘッダーをすべてリストする](#list-streaming-destinations)ことで、ヘッダーIDを取得することができます。

```graphql
mutation {
  auditEventsStreamingHeadersDestroy(input: { headerId: "gid://gitlab/AuditEvents::Streaming::Header/1" }) {
    errors
  }
}
```

返された`errors`オブジェクトが空の場合、ヘッダーは削除されます。

### イベントタイプのフィルター {#event-type-filters}

{{< history >}}

- イベントタイプのフィルターAPIがGitLab 15.7で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/344845)。

{{< /history >}}

この機能がグループに対して有効になっている場合、APIを使用して、ユーザーがストリーミング先ごとに監査イベントをフィルタリングできるようにすることができます。機能がフィルターなしで有効になっている場合、送信先はすべての監査イベントを受信します。

イベントタイプのフィルターが設定されているストリーミング先には、**フィルタリング済み** ({{< icon name="filter" >}}) ラベルが付きます。

#### APIを使用してイベントタイプのフィルターを追加する {#use-the-api-to-add-an-event-type-filter}

前提要件: 

- グループのオーナーロールを持っている必要があります。

`auditEventsStreamingDestinationEventsAdd`クエリタイプを使用して、イベントタイプのフィルターのリストを追加できます:

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

イベントタイプの種類のフィルターは、次の場合に追加されます:

- 返された`errors`オブジェクトが空です。
- APIが`200 OK`で応答します。

#### APIを使用してイベントタイプのフィルターを削除する {#use-the-api-to-remove-an-event-type-filter}

前提要件: 

- グループのオーナーロールを持っている必要があります。

`auditEventsStreamingDestinationEventsRemove`ミューテーションタイプを使用して、イベントタイプのフィルターのリストを削除できます:

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

イベントタイプのフィルターが削除されるのは、次の場合です:

- 返された`errors`オブジェクトが空です。
- APIが`200 OK`で応答します。

### ネームスペースフィルター {#namespace-filters}

{{< history >}}

- ネームスペースフィルターAPIがGitLab 16.7で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/344845)。

{{< /history >}}

ネームスペースフィルターをグループに適用すると、ユーザーは、グループの特定のサブグループまたはプロジェクトのストリーミング先ごとにストリーミングされた監査イベントをフィルタリングできます。それ以外の場合、ストリーミング先はすべての監査イベントを受信します。

ネームスペースフィルターが設定されているストリーミング先には、**フィルタリング済み** ({{< icon name="filter" >}}) ラベルが付きます。

#### APIを使用してネームスペースフィルターを追加する {#use-the-api-to-add-a-namespace-filter}

前提要件: 

- グループのオーナーロールを持っている必要があります。

`auditEventsStreamingHttpNamespaceFiltersAdd`ミューテーションタイプを使用して、サブグループとプロジェクトの両方に対してネームスペースフィルターを追加できます。

ネームスペースフィルターは、次の条件に該当する場合に追加されます:

- APIが空の`errors`オブジェクトを返す場合。
- APIが`200 OK`で応答します。

##### サブグループのミューテーション {#mutation-for-subgroup}

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

##### プロジェクトのミューテーション {#mutation-for-project}

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

#### APIを使用してネームスペースフィルターを削除する {#use-the-api-to-remove-a-namespace-filter}

前提要件: 

- グループのオーナーロールを持っている必要があります。

`auditEventsStreamingHttpNamespaceFiltersDelete`ミューテーションタイプを使用して、ネームスペースフィルターを削除できます:

```graphql
mutation auditEventsStreamingHttpNamespaceFiltersDelete {
  auditEventsStreamingHttpNamespaceFiltersDelete(input: {
    namespaceFilterId: "gid://gitlab/AuditEvents::Streaming::HTTP::NamespaceFilter/5"
  }) {
    errors
  }
}
```

ネームスペースフィルターは、次の条件に該当する場合に削除されます:

- 返された`errors`オブジェクトが空です。
- APIが`200 OK`で応答します。

## Google Cloud Loggingの送信先 {#google-cloud-logging-destinations}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/409422)されました。

{{< /history >}}

トップレベルグループのGoogle Cloud Loggingストリーミング先を管理します。

Google Cloud Logging監査イベントのストリーミングを設定する前に、[前提条件](../../user/compliance/audit_event_streaming.md#prerequisites)を満たす必要があります。

### 新しいGoogle Cloud Loggingの送信先を追加 {#add-a-new-google-cloud-logging-destination}

トップレベルグループに新しいGoogle Cloud Logging設定のストリーミング先を追加します。

前提要件: 

- トップレベルグループのオーナーロール。
- サービスアカウントを作成し、Google Cloud Loggingを有効にするために必要な権限を持つGoogle Cloudプロジェクト。

ストリーミングを有効にして設定を追加するには、GraphQL APIで`googleCloudLoggingConfigurationCreate`ミューテーションを使用します。

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

イベントストリーミングが有効になるのは、次の場合です:

- 返された`errors`オブジェクトが空です。
- APIが`200 OK`で応答します。

### Google Cloud Logging設定を一覧表示する {#list-google-cloud-logging-configurations}

トップレベルグループのすべてのGoogle Cloud Logging設定のストリーミング先をリストします。

前提要件: 

- トップレベルグループのオーナーロール。

`googleCloudLoggingConfigurations`クエリタイプを使用して、トップレベルグループの監査イベントストリーミングの設定のリストを表示できます。

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

結果のリストが空の場合、監査イベントストリーミングはそのグループに対して有効になっていません。

更新および削除ミューテーションには、このクエリから返されたID値が必要です。

### Google Cloud Logging設定を更新する {#update-google-cloud-logging-configurations}

トップレベルグループのGoogle Cloud Logging設定のストリーミング先を更新します。

前提要件: 

- トップレベルグループのオーナーロール。

トップレベルグループの監査イベントストリーミングの設定を更新するには、`googleCloudLoggingConfigurationUpdate`ミューテーションタイプを使用します。設定IDは、[外部のストリーミング先をすべて一覧表示](#list-google-cloud-logging-configurations)ことで取得することができます。

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

ストリーミングの設定が更新されるのは、次の場合です:

- 返された`errors`オブジェクトが空です。
- APIが`200 OK`で応答します。

### Google Cloud Logging設定を削除する {#delete-google-cloud-logging-configurations}

トップレベルグループのストリーミング先を削除します。

最後のストリーミング先が正常に削除されると、グループのストリーミングは無効になります。

前提要件: 

- トップレベルグループのオーナーロール。

グループのオーナーロールを持つユーザーは、`googleCloudLoggingConfigurationDestroy`ミューテーションタイプを使用して、監査イベントストリーミングの設定を削除できます。設定IDは、グループの[ストリーミング先をすべてリストする](#list-google-cloud-logging-configurations)ことで取得することができます。

```graphql
mutation {
  googleCloudLoggingConfigurationDestroy(input: { id: "gid://gitlab/AuditEvents::GoogleCloudLoggingConfiguration/1" }) {
    errors
  }
}
```

ストリーミングの設定が削除されるのは、次の場合です:

- 返された`errors`オブジェクトが空です。
- APIが`200 OK`で応答します。
