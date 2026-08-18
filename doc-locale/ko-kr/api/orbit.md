---
stage: Analytics
group: Knowledge Graph
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 쿼리를 실행하고 스키마를 검색하며 Orbit의 클러스터 상태를 확인하는 REST API입니다.
title: Orbit API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com
- 상태:  실험적 기능

{{< /details >}}

{{< history >}}

- GitLab 18.10에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/19744) 되었으며 [플래그](../administration/feature_flags/_index.md) `knowledge_graph`로 명명되었습니다. 이 기능은 [실험](../policy/development_stages_support.md) 이며 [GitLab 테스트 계약](https://handbook.gitlab.com/handbook/legal/testing-agreement/)의 적용을 받습니다.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요. 이 기능은 테스트용으로 사용할 수 있지만, 프로덕션 환경에서 사용할 준비가 되지 않았습니다.

이 API를 사용하여 [Orbit](https://gitlab.com/gitlab-org/orbit/knowledge-graph)에 대한 쿼리를 실행하고 스키마를 검색하며 클러스터 상태를 확인합니다.

## 쿼리 생성 {#create-a-query}

Orbit gRPC 서비스에 대해 쿼리를 생성하고 실행합니다.

```plaintext
POST /api/v4/orbit/query
```

지원되는 속성:

| 속성         | 유형   | 필수 | 설명                                                |
|-------------------|--------|----------|------------------------------------------------------------|
| `query`           | 객체 | 예      | 쿼리 DSL 개체입니다.                                      |
| `query_type`      | 문자열 | 아니요       | 쿼리 언어입니다. `json`만 지원됩니다. 기본값은 `json`입니다. |
| `response_format` | 문자열 | 아니요       | `raw` 또는 `llm` 중 하나입니다. 기본값은 `raw`입니다.                   |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성           | 유형            | 설명                                              |
|---------------------|-----------------|----------------------------------------------------------|
| `result`            | 배열 또는 문자열 | 쿼리 결과입니다. `raw`일 때는 배열이고 `llm`일 때는 문자열입니다. |
| `query_type`        | 문자열          | 쿼리 언어(예: `json`)입니다.                  |
| `raw_query_strings` | 문자열 배열    | 실행된 기본 쿼리입니다.                    |
| `row_count`         | 정수         | 반환된 행의 수입니다.                             |

### 예제 {#examples}

사용자를 사용자 이름으로 검색:

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

응답 예시:

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

프로젝트에서 머지 리퀘스트를 병합된 상태로 찾기:

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

응답 예시:

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

프로젝트당 머지 리퀘스트 수 계산:

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

응답 예시:

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

사용자의 나가는 이웃 찾기:

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

응답 예시:

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

두 프로젝트 간의 최단 경로 찾기:

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

응답 예시:

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

## 스키마 검색 {#retrieve-the-schema}

Orbit 스키마를 검색합니다.

```plaintext
GET /api/v4/orbit/schema
```

지원되는 속성:

| 속성         | 유형   | 필수 | 설명                              |
|-------------------|--------|----------|------------------------------------------|
| `expand`          | 문자열 | 아니요       | 확장할 쉼표로 구분된 노드 이름입니다.    |
| `response_format` | 문자열 | 아니요       | `raw` 또는 `llm` 중 하나입니다. 기본값은 `raw`입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성        | 유형         | 설명                    |
|------------------|--------------|--------------------------------|
| `schema_version` | 문자열       | 스키마의 버전입니다.     |
| `domains`        | 객체 배열 | 도메인 정의입니다.        |
| `nodes`          | 객체 배열 | 노드 유형 정의입니다.     |
| `edges`          | 객체 배열 | 엣지 유형 정의입니다.     |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/orbit/schema?expand=MergeRequest"
```

응답 예시:

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

## 클러스터 상태 검색 {#retrieve-cluster-health}

클러스터 상태 및 구성 요소 상태를 검색합니다. 이 엔드포인트는 서비스에 도달할 수 없는 경우에도 항상 `200 OK`을 반환합니다. 상태를 확인하려면 `status` 필드를 확인하세요.

```plaintext
GET /api/v4/orbit/status
```

지원되는 속성:

| 속성         | 유형   | 필수 | 설명                              |
|-------------------|--------|----------|------------------------------------------|
| `response_format` | 문자열 | 아니요       | `raw` 또는 `llm` 중 하나입니다. 기본값은 `raw`입니다. |

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)와 다음 응답 속성을 반환합니다:

| 속성    | 유형         | 설명                                                     |
|--------------|--------------|-----------------------------------------------------------------|
| `status`     | 문자열       | 클러스터 상태(예: `healthy` 또는 `unknown`)입니다.  |
| `timestamp`  | 문자열       | 상태 확인의 타임스탬프입니다.                              |
| `version`    | 문자열       | 서비스 버전입니다.                                            |
| `components` | 객체 배열 | 개별 구성 요소 상태입니다.                              |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/orbit/status"
```

응답 예시:

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

## 모든 도구 나열 {#list-all-tools}

사용 가능한 모든 Orbit 작업을 나열합니다.

```plaintext
GET /api/v4/orbit/tools
```

성공하면 [`200 OK`](rest/troubleshooting.md#status-codes)을 반환하고 다음 속성을 포함하는 도구 개체 배열을 제공합니다:

| 속성     | 유형   | 설명                         |
|---------------|--------|-------------------------------------|
| `name`        | 문자열 | 도구의 이름입니다.               |
| `description` | 문자열 | 도구에 대한 설명입니다.        |
| `parameters`  | 객체 | 도구의 매개 변수 스키마입니다.  |

요청 예시:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/orbit/tools"
```

응답 예시:

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
