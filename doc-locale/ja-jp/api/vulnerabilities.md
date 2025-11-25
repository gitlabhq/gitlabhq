---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 脆弱性API
description: REST API（非推奨）を使用してGitLabの脆弱性を管理します。取得、確認、解決、無視、および復元操作をサポートします。代わりにGraphQLを使用してください。
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

{{< alert type="note" >}}

以前のVulnerabilities APIはVulnerability Findings APIに名前が変更され、そのドキュメントは[別の場所](vulnerability_findings.md)に移動されました。このドキュメントでは、[脆弱性](https://gitlab.com/groups/gitlab-org/-/epics/634)へのアクセスを提供する新しいVulnerabilities APIについて説明します。

{{< /alert >}}

{{< alert type="warning" >}}

このAPIは、非推奨になる過程にあり、不安定であると見なされています。レスポンスペイロードは、GitLabのリリース全体で変更または破損する可能性があります。代わりに[GraphQL API](graphql/reference/_index.md#queryvulnerabilities)を使用してください。詳細については、[GraphQLの例](#replace-vulnerability-rest-api-with-graphql)を参照してください。

{{< /alert >}}

脆弱性に対するすべてのAPIコールは[認証](rest/authentication.md)されている必要があります。

認証済みユーザーに[脆弱性レポート](../user/permissions.md#application-security)を表示する権限がない場合、このリクエストは`403 Forbidden`ステータスコードを返します。

## 単一の脆弱性 {#single-vulnerability}

単一の脆弱性を取得します

```plaintext
GET /vulnerabilities/:id
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | 取得する脆弱性のID |

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

## 脆弱性の確認 {#confirm-vulnerability}

特定の脆弱性を確認します。脆弱性が既に確認されている場合は、ステータスコード`304`を返します。

認証済みユーザーに[脆弱性ステータスを変更](../user/permissions.md#application-security)する権限がない場合、このリクエストは`403`ステータスコードになります。

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

## 脆弱性の解決 {#resolve-vulnerability}

特定の脆弱性を解決します。脆弱性が既に解決されている場合は、ステータスコード`304`を返します。

認証済みユーザーに[脆弱性ステータスを変更](../user/permissions.md#application-security)する権限がない場合、このリクエストは`403`ステータスコードになります。

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

## 脆弱性の無視 {#dismiss-vulnerability}

特定の脆弱性を無視します。脆弱性が既に無視されている場合は、ステータスコード`304`を返します。

認証済みユーザーに[脆弱性ステータスを変更](../user/permissions.md#application-security)する権限がない場合、このリクエストは`403`ステータスコードになります。

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

## 検出された状態への脆弱性の復元 {#revert-vulnerability-to-detected-state}

特定の脆弱性を検出された状態に戻します。脆弱性が既に検出された状態にある場合は、ステータスコード`304`を返します。

認証済みユーザーに[脆弱性ステータスを変更](../user/permissions.md#application-security)する権限がない場合、このリクエストは`403`ステータスコードになります。

```plaintext
POST /vulnerabilities/:id/revert
```

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | 検出された状態に戻す脆弱性のID |

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

## GraphQLによる脆弱性REST APIの置き換え {#replace-vulnerability-rest-api-with-graphql}

脆弱性REST APIエンドポイントの[今後の非推奨](https://gitlab.com/groups/gitlab-org/-/epics/5118)に備えて、以下の例を使用して、GraphQL APIで同等の操作を実行します。

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

### GraphQL - 脆弱性の解決 {#graphql---resolve-vulnerability}

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

### GraphQL - 脆弱性の無視 {#graphql---dismiss-vulnerability}

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

### GraphQL - 検出された状態への脆弱性の復元 {#graphql---revert-vulnerability-to-detected-state}

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
