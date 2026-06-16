---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 脆弱性API
description: GitLabの脆弱性をREST APIで管理します（非推奨）。取得、確認、解決、無視、および元に戻す操作をサポートします。代わりにGraphQLを使用します。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- `last_edited_at`は、GitLab 16.7で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/268154)になりました。
- `start_date`は、GitLab 16.7で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/268154)になりました。
- `updated_by_id`は、GitLab 16.7で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/268154)になりました。
- `last_edited_by_id`は、GitLab 16.7で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/268154)になりました。
- `due_date`は、GitLab 16.7で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/268154)になりました。

{{< /history >}}

> [!note]
> 以前の脆弱性APIは、Vulnerability Findings APIに名前が変更され、そのドキュメントは[別の場所](vulnerability_findings.md)に移動されました。このドキュメントでは、[脆弱性](https://gitlab.com/groups/gitlab-org/-/epics/634)へのアクセスを提供する新しい脆弱性APIについて説明します。

脆弱性へのすべてのAPIコールは、[認証](rest/authentication.md)されている必要があります。

認証済みユーザーに[脆弱性レポート](../user/permissions.md#project-application-security)を表示する権限がない場合、このリクエストは`403 Forbidden`ステータスコードを返します。

> [!warning]
> このAPIは非推奨となる過程にあり、不安定と見なされています。レスポンスペイロードは、GitLabのリリース間で変更または破損する可能性があります。代わりに[GraphQL API](graphql/reference/_index.md#queryvulnerabilities)を使用します。詳細については、[GraphQLの例](#replace-vulnerability-rest-api-with-graphql)を参照してください。

## 脆弱性を取得する {#retrieve-a-vulnerability}

指定された脆弱性を取得します。

```plaintext
GET /vulnerabilities/:id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | 脆弱性のID（取得対象） |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/vulnerabilities/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "opened",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "closed_by_id": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "closed_at": null
}
```

## 脆弱性の確認 {#confirm-a-vulnerability}

指定された脆弱性を確認します。脆弱性がすでに確認されている場合、ステータスコード`304`を返します。

認証済みユーザーに[脆弱性](../user/permissions.md#project-application-security)ステータスを変更する権限がない場合、このリクエストは`403`ステータスコードになります。

```plaintext
POST /vulnerabilities/:id/confirm
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | 確認する脆弱性のID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/vulnerabilities/5/confirm"
```

レスポンス例: 

```json
{
  "id": 2,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "confirmed",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "closed_by_id": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "closed_at": null
}
```

## 脆弱性を解決する {#resolve-a-vulnerability}

指定された脆弱性を解決します。脆弱性がすでに解決されている場合、ステータスコード`304`を返します。

認証済みユーザーに[脆弱性](../user/permissions.md#project-application-security)ステータスを変更する権限がない場合、このリクエストは`403`ステータスコードになります。

```plaintext
POST /vulnerabilities/:id/resolve
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | 解決する脆弱性のID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/vulnerabilities/5/resolve"
```

レスポンス例: 

```json
{
  "id": 2,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "resolved",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "closed_by_id": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "closed_at": null
}
```

## 脆弱性を無視する {#dismiss-a-vulnerability}

指定された脆弱性を無視します。脆弱性がすでに無視されている場合、ステータスコード`304`を返します。

認証済みユーザーに[脆弱性](../user/permissions.md#project-application-security)ステータスを変更する権限がない場合、このリクエストは`403`ステータスコードになります。

```plaintext
POST /vulnerabilities/:id/dismiss
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | 無視する脆弱性のID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/vulnerabilities/5/dismiss"
```

レスポンス例: 

```json
{
  "id": 2,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "closed",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "closed_by_id": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "closed_at": null
}
```

## 脆弱性を検出状態に戻す {#revert-a-vulnerability-to-the-detected-state}

指定された脆弱性を検出状態に戻します。脆弱性がすでに検出状態である場合、ステータスコード`304`を返します。

認証済みユーザーに[脆弱性](../user/permissions.md#project-application-security)ステータスを変更する権限がない場合、このリクエストは`403`ステータスコードになります。

```plaintext
POST /vulnerabilities/:id/revert
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | 検出状態に戻す脆弱性のID |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/vulnerabilities/5/revert"
```

レスポンス例: 

```json
{
  "id": 2,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "detected",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "closed_by_id": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "closed_at": null
}
```

## 脆弱性REST APIをGraphQLに置き換える {#replace-vulnerability-rest-api-with-graphql}

脆弱性REST APIエンドポイントの[今後の非推奨](https://gitlab.com/groups/gitlab-org/-/epics/5118)に備えるため、以下の例を使用してGraphQL APIで同等の操作を実行してください。

### GraphQL - 単一の脆弱性 {#graphql---single-vulnerability}

[`Query.vulnerability`](graphql/reference/_index.md#queryvulnerability)を使用してください。

```graphql
{
  vulnerability(id: "gid://gitlab/Vulnerability/20345379") {
    title
    description
    state
    severity
    reportType
    project {
      id
      name
      fullPath
    }
    detectedAt
    confirmedAt
    resolvedAt
    resolvedBy {
      id
      username
    }
  }
}
```

レスポンス例: 

```json
{
  "data": {
    "vulnerability": {
      "title": "Improper Input Validation in railties",
      "description": "A remote code execution vulnerability in development mode Rails beta3 can allow an attacker to guess the automatically generated development mode secret token. This secret token can be used in combination with other Rails internals to escalate to a remote code execution exploit.",
      "state": "RESOLVED",
      "severity": "CRITICAL",
      "reportType": "DEPENDENCY_SCANNING",
      "project": {
        "id": "gid://gitlab/Project/6102100",
        "name": "security-reports",
        "fullPath": "gitlab-examples/security/security-reports"
      },
      "detectedAt": "2021-10-14T03:13:41Z",
      "confirmedAt": "2021-12-14T01:45:56Z",
      "resolvedAt": "2021-12-14T01:45:59Z",
      "resolvedBy": {
        "id": "gid://gitlab/User/480804",
        "username": "thiagocsf"
      }
    }
  }
}
```

### GraphQL - 脆弱性の確認 {#graphql---confirm-vulnerability}

[`Mutation.vulnerabilityConfirm`](graphql/reference/_index.md#mutationvulnerabilityconfirm)を使用してください。

```graphql
mutation {
  vulnerabilityConfirm(input: { id: "gid://gitlab/Vulnerability/23577695"}) {
    vulnerability {
      state
    }
    errors
  }
}
```

レスポンス例: 

```json
{
  "data": {
    "vulnerabilityConfirm": {
      "vulnerability": {
        "state": "CONFIRMED"
      },
      "errors": []
    }
  }
}
```

### GraphQL - 脆弱性を解決する {#graphql---resolve-vulnerability}

[`Mutation.vulnerabilityResolve`](graphql/reference/_index.md#mutationvulnerabilityresolve)を使用してください。

```graphql
mutation {
  vulnerabilityResolve(input: { id: "gid://gitlab/Vulnerability/23577695"}) {
    vulnerability {
      state
    }
    errors
  }
}
```

レスポンス例: 

```json
{
  "data": {
    "vulnerabilityConfirm": {
      "vulnerability": {
        "state": "RESOLVED"
      },
      "errors": []
    }
  }
}
```

### GraphQL - 脆弱性を無視する {#graphql---dismiss-vulnerability}

[`Mutation.vulnerabilityDismiss`](graphql/reference/_index.md#mutationvulnerabilitydismiss)を使用してください。

```graphql
mutation {
  vulnerabilityDismiss(input: { id: "gid://gitlab/Vulnerability/23577695"}) {
    vulnerability {
      state
    }
    errors
  }
}
```

レスポンス例: 

```json
{
  "data": {
    "vulnerabilityConfirm": {
      "vulnerability": {
        "state": "DISMISSED"
      },
      "errors": []
    }
  }
}
```

### GraphQL - 脆弱性を検出状態に戻す {#graphql---revert-vulnerability-to-the-detected-state}

[`Mutation.vulnerabilityRevertToDetected`](graphql/reference/_index.md#mutationvulnerabilityreverttodetected)を使用してください。

```graphql
mutation {
  vulnerabilityRevertToDetected(input: { id: "gid://gitlab/Vulnerability/20345379"}) {
    vulnerability {
      state
    }
    errors
  }
}
```

レスポンス例: 

```json
{
  "data": {
    "vulnerabilityConfirm": {
      "vulnerability": {
        "state": "DETECTED"
      },
      "errors": []
    }
  }
}
```
