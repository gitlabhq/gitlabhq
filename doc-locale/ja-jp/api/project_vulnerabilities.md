---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: プロジェクトの脆弱性API
description: プロジェクトの脆弱性をリストおよび作成するためのProject Vulnerabilities API。認証と適切な権限が必要です。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- `last_edited_at` GitLab 16.7で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/268154)になりました。
- `start_date` GitLab 16.7で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/268154)になりました。
- `updated_by_id` GitLab 16.7で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/268154)になりました。
- `last_edited_by_id` GitLab 16.7で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/268154)になりました。
- `due_date` GitLab 16.7で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/268154)になりました。

{{< /history >}}

{{< alert type="warning" >}}

このAPIは非推奨になる過程にあり、不安定であると見なされています。レスポンスペイロードは、GitLabのリリース間で変更または破損する可能性があります。代わりに[GraphQL API](graphql/reference/_index.md#queryvulnerabilities)を使用してください。

{{< /alert >}}

このAPIを使用して、[プロジェクトの脆弱性](../user/application_security/vulnerabilities/_index.md)を管理します。このAPIのすべての呼び出しには認証が必要です。

ユーザーがプライベートプロジェクトのメンバーでない場合、プライベートプロジェクトへのリクエストは、`404 Not Found`ステータスコードを返します。

## 脆弱性のページネーション {#vulnerabilities-pagination}

APIの結果はページネーションされており、`GET`リクエストはデフォルトで一度に20件の結果を返します。

詳細については、[ページネーション](rest/_index.md#pagination)を参照してください。

## プロジェクトの脆弱性 {#list-project-vulnerabilities}

プロジェクトのすべての脆弱性をリストします。

認証済みユーザーが[プロジェクトセキュリティダッシュボードを使用する](../user/permissions.md#project-members-permissions)権限を持っていない場合、このプロジェクトの脆弱性に対する`GET`リクエストは、`403`ステータスコードになります。

```plaintext
GET /projects/:id/vulnerabilities
```

| 属性     | 型           | 必須 | 説明                                                                                                                                                                 |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。                                                            |

```shell
curl --request GET \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/4/vulnerabilities"
```

レスポンス例:

```json
[
    {
        "author_id": 1,
        "confidence": "medium",
        "created_at": "2020-04-07T14:01:04.655Z",
        "description": null,
        "dismissed_at": null,
        "dismissed_by_id": null,
        "finding": {
            "confidence": "medium",
            "created_at": "2020-04-07T14:01:04.630Z",
            "id": 103,
            "location_fingerprint": "228998b5db51d86d3b091939e2f5873ada0a14a1",
            "metadata_version": "2.0",
            "name": "Regular Expression Denial of Service in debug",
            "primary_identifier_id": 135,
            "project_id": 24,
            "raw_metadata": "{\"category\":\"dependency_scanning\",\"name\":\"Regular Expression Denial of Service\",\"message\":\"Regular Expression Denial of Service in debug\",\"description\":\"The debug module is vulnerable to regular expression denial of service when untrusted user input is passed into the `o` formatter. It takes around 50k characters to block for 2 seconds making this a low severity issue.\",\"cve\":\"yarn.lock:debug:gemnasium:37283ed4-0380-40d7-ada7-2d994afcc62a\",\"severity\":\"Unknown\",\"solution\":\"Upgrade to latest versions.\",\"scanner\":{\"id\":\"gemnasium\",\"name\":\"Gemnasium\"},\"location\":{\"file\":\"yarn.lock\",\"dependency\":{\"package\":{\"name\":\"debug\"},\"version\":\"1.0.5\"}},\"identifiers\":[{\"type\":\"gemnasium\",\"name\":\"Gemnasium-37283ed4-0380-40d7-ada7-2d994afcc62a\",\"value\":\"37283ed4-0380-40d7-ada7-2d994afcc62a\",\"url\":\"https://deps.sec.gitlab.com/packages/npm/debug/versions/1.0.5/advisories\"}],\"links\":[{\"url\":\"https://nodesecurity.io/advisories/534\"},{\"url\":\"https://github.com/visionmedia/debug/issues/501\"},{\"url\":\"https://github.com/visionmedia/debug/pull/504\"}],\"remediations\":[null]}",
            "report_type": "dependency_scanning",
            "scanner_id": 63,
            "severity": "low",
            "updated_at": "2020-04-07T14:01:04.664Z",
            "uuid": "f1d528ae-d0cc-47f6-a72f-936cec846ae7",
            "vulnerability_id": 103
        },
        "id": 103,
        "project": {
            "created_at": "2020-04-07T13:54:25.634Z",
            "description": "",
            "id": 24,
            "name": "security-reports",
            "name_with_namespace": "gitlab-org / security-reports",
            "path": "security-reports",
            "path_with_namespace": "gitlab-org/security-reports"
        },
        "project_default_branch": "main",
        "report_type": "dependency_scanning",
        "resolved_at": null,
        "resolved_by_id": null,
        "resolved_on_default_branch": false,
        "severity": "low",
        "state": "detected",
        "title": "Regular Expression Denial of Service in debug",
        "updated_at": "2020-04-07T14:01:04.655Z"
    }
]
```

## 新規脆弱性 {#new-vulnerability}

新しい脆弱性を作成します。

認証済みユーザーに[新しい脆弱性を作成する](../user/permissions.md#project-members-permissions)権限がない場合、このリクエストは`403`ステータスコードになります。

```plaintext
POST /projects/:id/vulnerabilities?finding_id=<your_finding_id>
```

| 属性           | 型              | 必須   | 説明                                                                                                                  |
| ------------------- | ----------------- | ---------- | -----------------------------------------------------------------------------------------------------------------------------|
| `id`                | 整数または文字列 | はい        | 認証済みユーザーがメンバーになっているプロジェクトの[URLエンコードされたパス](rest/_index.md#namespaced-paths)またはID  |
| `finding_id`        | 整数または文字列 | はい        | 新しい脆弱性を作成するための脆弱性の検索ID |

新しく作成された脆弱性の他の属性は、ソース脆弱性の検索から、またはこれらのデフォルト値で入力された値です:

| 属性    | 値                                                 |
|--------------|-------------------------------------------------------|
| `author`     | 認証済みユーザー                                |
| `title`      | 脆弱性の検索の`name`属性       |
| `state`      | `opened`                                              |
| `severity`   | 脆弱性の検索の`severity`属性   |
| `confidence` | 脆弱性の検索の`confidence`属性 |

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/1/vulnerabilities?finding_id=1"
```

レスポンス例:

```json
{
    "author_id": 1,
    "confidence": "medium",
    "created_at": "2020-04-07T14:01:04.655Z",
    "description": null,
    "dismissed_at": null,
    "dismissed_by_id": null,
    "finding": {
        "confidence": "medium",
        "created_at": "2020-04-07T14:01:04.630Z",
        "id": 103,
        "location_fingerprint": "228998b5db51d86d3b091939e2f5873ada0a14a1",
        "metadata_version": "2.0",
        "name": "Regular Expression Denial of Service in debug",
        "primary_identifier_id": 135,
        "project_id": 24,
        "raw_metadata": "{\"category\":\"dependency_scanning\",\"name\":\"Regular Expression Denial of Service\",\"message\":\"Regular Expression Denial of Service in debug\",\"description\":\"The debug module is vulnerable to regular expression denial of service when untrusted user input is passed into the `o` formatter. It takes around 50k characters to block for 2 seconds making this a low severity issue.\",\"cve\":\"yarn.lock:debug:gemnasium:37283ed4-0380-40d7-ada7-2d994afcc62a\",\"severity\":\"Unknown\",\"solution\":\"Upgrade to latest versions.\",\"scanner\":{\"id\":\"gemnasium\",\"name\":\"Gemnasium\"},\"location\":{\"file\":\"yarn.lock\",\"dependency\":{\"package\":{\"name\":\"debug\"},\"version\":\"1.0.5\"}},\"identifiers\":[{\"type\":\"gemnasium\",\"name\":\"Gemnasium-37283ed4-0380-40d7-ada7-2d994afcc62a\",\"value\":\"37283ed4-0380-40d7-ada7-2d994afcc62a\",\"url\":\"https://deps.sec.gitlab.com/packages/npm/debug/versions/1.0.5/advisories\"}],\"links\":[{\"url\":\"https://nodesecurity.io/advisories/534\"},{\"url\":\"https://github.com/visionmedia/debug/issues/501\"},{\"url\":\"https://github.com/visionmedia/debug/pull/504\"}],\"remediations\":[null]}",
        "report_type": "dependency_scanning",
        "scanner_id": 63,
        "severity": "low",
        "updated_at": "2020-04-07T14:01:04.664Z",
        "uuid": "f1d528ae-d0cc-47f6-a72f-936cec846ae7",
        "vulnerability_id": 103
    },
    "id": 103,
    "project": {
        "created_at": "2020-04-07T13:54:25.634Z",
        "description": "",
        "id": 24,
        "name": "security-reports",
        "name_with_namespace": "gitlab-org / security-reports",
        "path": "security-reports",
        "path_with_namespace": "gitlab-org/security-reports"
    },
    "project_default_branch": "main",
    "report_type": "dependency_scanning",
    "resolved_at": null,
    "resolved_by_id": null,
    "resolved_on_default_branch": false,
    "severity": "low",
    "state": "detected",
    "title": "Regular Expression Denial of Service in debug",
    "updated_at": "2020-04-07T14:01:04.655Z"
}
```

### エラー {#errors}

このエラーは、脆弱性の作成元として選択された検索が見つからない場合、または別の脆弱性にすでに関連付けられている場合に発生します:

```plaintext
A Vulnerability Finding is not found or already attached to a different Vulnerability
```

ステータスコード: `400`

レスポンス例:

```json
{
  "message": {
    "base": [
      "finding is not found or is already attached to a vulnerability"
    ]
  }
}
```
