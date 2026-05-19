---
stage: Analytics
group: Knowledge Graph
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: REST APIを使用して、クエリを実行し、スキーマを取得する、クラスターのヘルスチェックをOrbitに対して行います。
title: Orbit API
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.10で`knowledge_graph`という名前の[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/19744)されました。この機能は[実験的機能](../policy/development_stages_support.md)であり、[GitLabテスト規約](https://handbook.gitlab.com/handbook/legal/testing-agreement/)の対象となります。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

このAPIを使用して、クエリを実行し、スキーマを取得する、クラスターのヘルスチェックを[Orbit](https://gitlab.com/gitlab-org/orbit/knowledge-graph)に対して行います。

## クエリを作成する {#create-a-query}

Orbit gRPCサービスに対してクエリを作成し、実行します。

```plaintext
POST /api/v4/orbit/query
```

サポートされている属性は以下のとおりです: 

| 属性         | タイプ   | 必須 | 説明                                                |
|-------------------|--------|----------|------------------------------------------------------------|
| `query`           | オブジェクト | はい      | クエリDSLオブジェクト。                                      |
| `query_type`      | 文字列 | いいえ       | クエリ言語。`json`のみがサポートされています。デフォルトは`json`です。 |
| `response_format` | 文字列 | いいえ       | `raw`または`llm`のいずれか。デフォルトは`raw`です。                   |

成功した場合は、[`200 OK`](rest/troubleshooting.md#status-codes)と以下のレスポンス属性が返されます。

| 属性           | タイプ            | 説明                                              |
|---------------------|-----------------|----------------------------------------------------------|
| `result`            | 配列または文字列 | クエリ結果。`raw`の場合は配列、`llm`の場合は文字列。 |
| `query_type`        | 文字列          | クエリ言語。`json`など。                  |
| `raw_query_strings` | 文字列配列    | 実行された基盤となるクエリ。                    |
| `row_count`         | 整数         | 返された行数。                             |

### 例 {#examples}

ユーザー名でユーザーを取得する:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "query": {
      "query_type": "search",
      "node": {"id": "u", "entity": "User", "filters": {"username": "john_smith"}}
    }
  }' \
  --url "https://gitlab.example.com/api/v4/orbit/query"
```

レスポンス例: 

```json
{
  "result": [
    {
      "u_id": 1,
      "u_username": "john_smith",
      "u_name": "John Smith",
      "u_state": "active",
      "u_type": "User"
    }
  ],
  "query_type": "search",
  "row_count": 1
}
```

プロジェクトでマージされたマージリクエストを見つける:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "query": {
      "query_type": "traversal",
      "nodes": [
        {"id": "p", "entity": "Project", "node_ids": [8]},
        {"id": "mr", "entity": "MergeRequest", "filters": {"state": "merged"}}
      ],
      "relationships": [{"type": "IN_PROJECT", "from": "mr", "to": "p"}]
    }
  }' \
  --url "https://gitlab.example.com/api/v4/orbit/query"
```

レスポンス例: 

```json
{
  "result": [
    {
      "p_name": "Diaspora Client",
      "p_full_path": "diaspora/diaspora-client",
      "mr_id": 43,
      "mr_iid": 1,
      "mr_title": "Resolve connection timeout on large payloads",
      "mr_state": "merged"
    },
    {
      "mr_id": 44,
      "mr_iid": 2,
      "mr_title": "Replace deprecated API calls in federation module",
      "mr_state": "merged"
    }
  ],
  "query_type": "traversal",
  "row_count": 2
}
```

プロジェクトごとのマージリクエスト数をカウントする:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "query": {
      "query_type": "aggregation",
      "nodes": [
        {"id": "p", "entity": "Project"},
        {"id": "mr", "entity": "MergeRequest"}
      ],
      "relationships": [{"type": "IN_PROJECT", "from": "mr", "to": "p"}],
      "aggregations": [{"function": "count", "target": "mr", "group_by": "p", "alias": "mr_count"}]
    }
  }' \
  --url "https://gitlab.example.com/api/v4/orbit/query"
```

レスポンス例: 

```json
{
  "result": [
    {"p_name": "Diaspora Client", "p_full_path": "diaspora/diaspora-client", "mr_count": 8},
    {"p_name": "Puppet", "p_full_path": "brightbox/puppet", "mr_count": 6}
  ],
  "query_type": "aggregation",
  "row_count": 2
}
```

ユーザーの送信ネイバーを見つける:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "query": {
      "query_type": "neighbors",
      "node": {"id": "u", "entity": "User", "node_ids": [43]},
      "neighbors": {"node": "u"}
    }
  }' \
  --url "https://gitlab.example.com/api/v4/orbit/query"
```

レスポンス例: 

```json
{
  "result": [
    {
      "_gkg_relationship_type": "MEMBER_OF",
      "_gkg_neighbor_type": "Project",
      "id": 5,
      "name": "Diaspora Client"
    },
    {
      "_gkg_relationship_type": "MEMBER_OF",
      "_gkg_neighbor_type": "Group",
      "id": 29,
      "name": "diaspora"
    },
    {
      "_gkg_relationship_type": "AUTHORED",
      "_gkg_neighbor_type": "MergeRequest",
      "id": 43,
      "title": "Resolve connection timeout on large payloads"
    }
  ],
  "query_type": "neighbors",
  "row_count": 3
}
```

2つのプロジェクト間の最短パスを見つける:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "query": {
      "query_type": "path_finding",
      "nodes": [
        {"id": "p1", "entity": "Project", "node_ids": [8]},
        {"id": "p2", "entity": "Project", "node_ids": [5]}
      ],
      "path": {"type": "shortest", "from": "p1", "to": "p2", "max_depth": 3}
    }
  }' \
  --url "https://gitlab.example.com/api/v4/orbit/query"
```

レスポンス例: 

```json
{
  "result": [
    {
      "depth": 2,
      "path": [
        {"id": 8, "entity_type": "Project", "name": "Diaspora Client", "full_path": "diaspora/diaspora-client"},
        {"id": 43, "entity_type": "User", "name": "John Smith", "username": "john_smith"},
        {"id": 5, "entity_type": "Project", "name": "Puppet", "full_path": "brightbox/puppet"}
      ],
      "edges": ["MEMBER_OF", "MEMBER_OF"]
    }
  ],
  "query_type": "path_finding",
  "row_count": 1
}
```

## スキーマを取得する {#retrieve-the-schema}

Orbitスキーマを取得する。

```plaintext
GET /api/v4/orbit/schema
```

サポートされている属性は以下のとおりです: 

| 属性         | タイプ   | 必須 | 説明                              |
|-------------------|--------|----------|------------------------------------------|
| `expand`          | 文字列 | いいえ       | 展開するカンマ区切りのノード名。    |
| `response_format` | 文字列 | いいえ       | `raw`または`llm`のいずれか。デフォルトは`raw`です。 |

成功した場合は、[`200 OK`](rest/troubleshooting.md#status-codes)と以下のレスポンス属性が返されます。

| 属性        | タイプ         | 説明                    |
|------------------|--------------|--------------------------------|
| `schema_version` | 文字列       | スキーマのバージョン。     |
| `domains`        | オブジェクト配列 | ドメイン定義。        |
| `nodes`          | オブジェクト配列 | ノードタイプの定義。     |
| `edges`          | オブジェクト配列 | エッジタイプの定義。     |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/orbit/schema?expand=MergeRequest"
```

レスポンス例: 

```json
{
  "schema_version": "0.1",
  "domains": [
    {"name": "ci", "description": "Entities related to CI/CD pipelines, stages, and jobs.", "node_names": ["Job", "Pipeline", "Stage"]},
    {"name": "code_review", "node_names": ["MergeRequest", "MergeRequestDiff", "MergeRequestDiffFile"]},
    {"name": "core", "node_names": ["Group", "Note", "Project", "User"]},
    {"name": "plan", "node_names": ["Label", "Milestone", "WorkItem"]},
    {"name": "security", "node_names": ["Finding", "SecurityScan", "Vulnerability"]},
    {"name": "source_code", "node_names": ["Branch", "Definition", "Directory", "File", "ImportedSymbol"]}
  ],
  "nodes": [],
  "edges": []
}
```

## クラスターヘルスを取得する {#retrieve-cluster-health}

クラスターヘルスとコンポーネントステータスを取得する。このエンドポイントは、サービスに到達できない場合でも、常に`200 OK`を返します。ヘルスを判断するには、`status`フィールドを確認してください。

```plaintext
GET /api/v4/orbit/status
```

サポートされている属性は以下のとおりです: 

| 属性         | タイプ   | 必須 | 説明                              |
|-------------------|--------|----------|------------------------------------------|
| `response_format` | 文字列 | いいえ       | `raw`または`llm`のいずれか。デフォルトは`raw`です。 |

成功した場合は、[`200 OK`](rest/troubleshooting.md#status-codes)と以下のレスポンス属性が返されます。

| 属性    | タイプ         | 説明                                                     |
|--------------|--------------|-----------------------------------------------------------------|
| `status`     | 文字列       | クラスターのヘルスステータス。`healthy`または`unknown`など。  |
| `timestamp`  | 文字列       | ヘルスチェックのタイムスタンプ。                              |
| `version`    | 文字列       | サービスのバージョン。                                            |
| `components` | オブジェクト配列 | 個々のコンポーネントステータス。                              |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/orbit/status"
```

レスポンス例: 

```json
{
  "status": "healthy",
  "timestamp": "2026-03-05T15:08:35.885160548+00:00",
  "version": "0.1.0",
  "components": [
    {"name": "gkg-indexer", "status": "healthy", "replicas": {"ready": 1, "desired": 1}, "metrics": {}},
    {"name": "gkg-webserver", "status": "healthy", "replicas": {"ready": 1, "desired": 1}, "metrics": {}},
    {"name": "clickhouse", "status": "healthy", "replicas": {"ready": 0, "desired": 0}, "metrics": {}}
  ]
}
```

## すべてのツールを一覧表示する {#list-all-tools}

利用可能なすべてのOrbit操作を一覧表示します。

```plaintext
GET /api/v4/orbit/tools
```

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と、以下の属性を持つツールオブジェクトの配列を返します:

| 属性     | タイプ   | 説明                         |
|---------------|--------|-------------------------------------|
| `name`        | 文字列 | ツールの名前。               |
| `description` | 文字列 | ツールの説明。        |
| `parameters`  | オブジェクト | ツールのパラメータスキーマ。  |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/orbit/tools"
```

レスポンス例: 

```json
[
  {
    "name": "query_graph",
    "description": "Execute graph queries to find nodes, traverse relationships...",
    "parameters": {
      "type": "object",
      "required": ["query"],
      "properties": {"query": {"type": "object"}}
    }
  },
  {
    "name": "get_graph_schema",
    "description": "List the GitLab Knowledge Graph schema...",
    "parameters": {
      "type": "object",
      "properties": {"expand_nodes": {"type": "array"}}
    }
  }
]
```
