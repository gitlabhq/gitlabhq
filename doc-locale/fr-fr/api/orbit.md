---
stage: Analytics
group: Knowledge Graph
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "API REST pour exécuter des requêtes, récupérer des schémas et vérifier la santé du cluster pour Orbit."
title: API Orbit
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com
- Statut :  Expérience

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/19744) dans GitLab 18.10 [avec un indicateur](../administration/feature_flags/_index.md) nommé `knowledge_graph`. Cette fonctionnalité est une [expérimentation](../policy/development_stages_support.md) soumise au [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible à des fins de test, mais n'est pas prête pour une utilisation en production.

Utilisez cette API REST pour exécuter des requêtes, récupérer des schémas et vérifier la santé du cluster pour [Orbit](https://gitlab.com/gitlab-org/orbit/knowledge-graph).

## Créer une requête {#create-a-query}

Crée et exécute une requête sur le service gRPC Orbit.

```plaintext
POST /api/v4/orbit/query
```

Attributs pris en charge :

| Attribut         | Type   | Obligatoire | Description                                                |
|-------------------|--------|----------|------------------------------------------------------------|
| `query`           | object | Oui      | L'objet DSL de requête.                                      |
| `query_type`      | string | Non       | Le langage de requête. Seul `json` est pris en charge. La valeur par défaut est `json`. |
| `response_format` | string | Non       | L'un des formats `raw` ou `llm`. La valeur par défaut est `raw`.                   |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut           | Type            | Description                                              |
|---------------------|-----------------|----------------------------------------------------------|
| `result`            | array ou string | Les résultats de la requête. Un tableau lorsque `raw`, une chaîne lorsque `llm`. |
| `query_type`        | string          | Le langage de requête, par exemple `json`.                  |
| `raw_query_strings` | string array    | Les requêtes sous-jacentes qui ont été exécutées.                    |
| `row_count`         | integer         | Le nombre de lignes retournées.                             |

### Exemples {#examples}

Récupérer un utilisateur par nom d'utilisateur :

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

Exemple de réponse :

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

Rechercher les merge requests fusionnées dans un projet :

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

Exemple de réponse :

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

Compter les merge requests par projet :

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

Exemple de réponse :

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

Rechercher les voisins sortants d'un utilisateur :

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

Exemple de réponse :

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

Rechercher le chemin le plus court entre deux projets :

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

Exemple de réponse :

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

## Récupérer le schéma {#retrieve-the-schema}

Récupère le schéma Orbit.

```plaintext
GET /api/v4/orbit/schema
```

Attributs pris en charge :

| Attribut         | Type   | Obligatoire | Description                              |
|-------------------|--------|----------|------------------------------------------|
| `expand`          | string | Non       | Noms de nœuds séparés par des virgules à développer.    |
| `response_format` | string | Non       | L'un des formats `raw` ou `llm`. La valeur par défaut est `raw`. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut        | Type         | Description                    |
|------------------|--------------|--------------------------------|
| `schema_version` | string       | La version du schéma.     |
| `domains`        | object array | Les définitions de domaine.        |
| `nodes`          | object array | Les définitions de types de nœuds.     |
| `edges`          | object array | Les définitions de types d'arêtes.     |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/orbit/schema?expand=MergeRequest"
```

Exemple de réponse :

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

## Récupérer la santé du cluster {#retrieve-cluster-health}

Récupère la santé du cluster et l'état des composants. Ce point de terminaison renvoie toujours `200 OK`, même lorsque le service est inaccessible. Vérifiez le champ `status` pour déterminer l'état de santé.

```plaintext
GET /api/v4/orbit/status
```

Attributs pris en charge :

| Attribut         | Type   | Obligatoire | Description                              |
|-------------------|--------|----------|------------------------------------------|
| `response_format` | string | Non       | L'un des formats `raw` ou `llm`. La valeur par défaut est `raw`. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut    | Type         | Description                                                     |
|--------------|--------------|-----------------------------------------------------------------|
| `status`     | string       | L'état de santé du cluster, par exemple `healthy` ou `unknown`.  |
| `timestamp`  | string       | L'horodatage du contrôle de santé.                              |
| `version`    | string       | La version du service.                                            |
| `components` | object array | Les états des composants individuels.                              |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/orbit/status"
```

Exemple de réponse :

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

## Lister tous les outils {#list-all-tools}

Liste toutes les opérations Orbit disponibles.

```plaintext
GET /api/v4/orbit/tools
```

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et un tableau d'objets outil avec les attributs suivants :

| Attribut     | Type   | Description                         |
|---------------|--------|-------------------------------------|
| `name`        | string | Le nom de l'outil.               |
| `description` | string | La description de l'outil.        |
| `parameters`  | object | Le schéma de paramètres de l'outil.  |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/orbit/tools"
```

Exemple de réponse :

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
