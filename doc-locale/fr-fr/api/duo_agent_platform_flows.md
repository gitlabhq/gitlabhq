---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "API REST pour créer, démarrer et gérer les flows de la plateforme GitLab Duo Agent."
title: API Flows
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour créer et gérer des [flows](../user/duo_agent_platform/flows/_index.md) dans la [plateforme GitLab Duo Agent](../user/duo_agent_platform/_index.md). Les flows sont des combinaisons d'agents d'IA qui travaillent ensemble pour accomplir des tâches de développement, comme la correction de bugs, l'écriture de code ou la résolution de vulnérabilités.

## Créer un flow {#create-a-flow}

{{< details >}}

- Statut :  Expérience

{{< /details >}}

Crée et démarre un nouveau flow.

```plaintext
POST /ai/duo_workflows/workflows
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
|-----------|------|----------|-------------|
| `additional_context` | tableau d'objets | Non | Contexte supplémentaire pour le flow. Chaque élément doit être un objet comportant au minimum une clé `Category` (chaîne) et `Content` (chaîne, JSON sérialisé). |
| `agent_privileges` | tableau d'entiers | Non | ID de privilèges que l'agent d'IA est autorisé à utiliser. Par défaut, tous les privilèges sont accordés. Voir [Répertorier tous les privilèges des agents](#list-all-agent-privileges). |
| `ai_catalog_item_consumer_id` | entier | Non | ID du consommateur d'élément du catalogue d'IA qui configure l'élément du catalogue à exécuter. Nécessite `project_id`. Ne peut pas être utilisé avec `workflow_definition` ; si les deux sont fournis, `ai_catalog_item_consumer_id` est prioritaire. Voir [Rechercher l'ID du consommateur](#look-up-the-consumer-id). |
| `ai_catalog_item_version_id` | entier | Non | ID de la version de l'élément du catalogue d'IA qui est à l'origine de la configuration du flow. |
| `allow_agent_to_request_user` | boolean | Non | Lorsque la valeur est `true` (par défaut), l'agent d'IA peut s'interrompre pour poser des questions à l'utilisateur avant de continuer. Lorsque la valeur est `false`, l'agent d'IA s'exécute jusqu'à la fin sans saisie de l'utilisateur. |
| `environment` | string | Non | Environnement d'exécution. L'un des suivants : `ide`, `web`, `chat_partial`, `chat`, `ambient`. |
| `goal` | string | Non | Description de la tâche que l'agent d'IA doit accomplir. Exemple : `Fix the failing pipeline`. |
| `image` | string | Non | Image de conteneur à utiliser lors de l'exécution du flow dans un pipeline CI. Doit satisfaire aux [exigences relatives aux images personnalisées](../user/duo_agent_platform/flows/execution.md#custom-image-requirements). Exemple : `registry.gitlab.com/gitlab-org/duo-workflow/custom-image:latest`. |
| `issue_id` | entier | Non | IID du ticket à associer au flow. Nécessite `project_id`. |
| `merge_request_id` | entier | Non | IID du merge request à associer au flow. Nécessite `project_id`. |
| `namespace_id` | string | Non | ID ou chemin de l'espace de nommage à associer au flow. |
| `pre_approved_agent_privileges` | tableau d'entiers | Non | ID de privilèges que l'agent d'IA peut utiliser sans demander l'approbation de l'utilisateur. Doit être un sous-ensemble de `agent_privileges`. |
| `project_id` | string | Non | ID ou chemin du projet à associer au flow. |
| `shallow_clone` | boolean | Non | Indique s'il faut utiliser un clone superficiel du dépôt lors de l'exécution. Par défaut : `true`. |
| `source_branch` | string | Non | Branche source pour le pipeline CI. Par défaut, il s'agit de la branche par défaut du projet. |
| `start_workflow` | boolean | Non | Lorsque la valeur est `true`, le flow démarre immédiatement après sa création. |
| `workflow_definition` | string | Non | Identifiant du type de flow. Exemple : `developer/v1`. Ne peut pas être utilisé avec `ai_catalog_item_consumer_id` ; si les deux sont fournis, `ai_catalog_item_consumer_id` est prioritaire. |

En cas de succès, renvoie [`201 Created`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type | Description |
|-----------|------|-------------|
| `agent_privileges` | tableau d'entiers | ID de privilèges attribués à l'agent d'IA. |
| `agent_privileges_names` | tableau de chaînes | Noms correspondant à `agent_privileges`. |
| `ai_catalog_item_version_id` | entier | ID de la version de l'élément du catalogue d'IA. `null` si non défini. |
| `allow_agent_to_request_user` | boolean | Lorsque la valeur est `true`, l'agent d'IA peut s'interrompre pour attendre une saisie de l'utilisateur. |
| `environment` | string | Environnement d'exécution. `null` si non défini. |
| `gitlab_url` | string | URL de base de l'instance GitLab. |
| `id` | entier | ID du flow. |
| `image` | string | Image de conteneur pour l'exécution du pipeline CI. `null` si non définie. |
| `mcp_enabled` | boolean | Indique si les outils `MCP` (Model Context Protocol) sont activés pour ce flow. |
| `namespace_id` | entier | ID de l'espace de nommage associé. `null` si non défini. |
| `pre_approved_agent_privileges` | tableau d'entiers | ID de privilèges que l'agent d'IA peut utiliser sans demander d'approbation. |
| `pre_approved_agent_privileges_names` | tableau de chaînes | Noms correspondant à `pre_approved_agent_privileges`. |
| `project_id` | entier | ID du projet associé. `null` si non défini. |
| `status` | string | Statut actuel du flow. L'un des suivants : `created`, `running`, `paused`, `finished`, `failed`, `stopped`, `input_required`, `plan_approval_required` ou `tool_call_approval_required`. |
| `summary` | string | Bref résumé textuel du workflow. |
| `title` | string | Titre de la session. |
| `workflow_definition` | string | Identifiant du type de flow. |
| `workload` | objet | Informations sur la charge de travail. |
| `workload.id` | string | ID de la charge de travail. |
| `workload.message` | string | Message de statut de la charge de travail. |

### Rechercher l'ID du consommateur {#look-up-the-consumer-id}

Avant de pouvoir utiliser `ai_catalog_item_consumer_id`, vous devez utiliser l'API GraphQL pour récupérer l'ID depuis le [catalogue d'IA](../user/duo_agent_platform/ai_catalog.md). L'élément doit déjà être activé pour le projet.

```graphql
query {
  aiCatalogConfiguredItems(projectId: "gid://gitlab/Project/<project_id>") {
    nodes {
      id
      item { name }
    }
  }
}
```

Le champ `id` est un ID global au format `gid://gitlab/AiCatalogItemConsumer/<numeric_id>`. Utilisez le suffixe numérique comme valeur de `ai_catalog_item_consumer_id`.

Exemple de requête utilisant un type de flow intégré :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "project_id": "5",
    "goal": "Fix the failing pipeline by correcting the syntax error in .gitlab-ci.yml",
    "workflow_definition": "developer/v1",
    "start_workflow": true
  }' \
  --url "https://gitlab.example.com/api/v4/ai/duo_workflows/workflows"
```

Exemple de requête utilisant un flow configuré via le catalogue :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "project_id": "5",
    "goal": "Fix the failing pipeline by correcting the syntax error in .gitlab-ci.yml",
    "ai_catalog_item_consumer_id": 12,
    "start_workflow": true
  }' \
  --url "https://gitlab.example.com/api/v4/ai/duo_workflows/workflows"
```

Exemple de réponse :

```json
{
  "id": 1,
  "project_id": 5,
  "namespace_id": null,
  "agent_privileges": [1, 2, 3, 4, 5, 6],
  "agent_privileges_names": [
    "read_write_files",
    "read_only_gitlab",
    "read_write_gitlab",
    "run_commands",
    "use_git",
    "run_mcp_tools"
  ],
  "pre_approved_agent_privileges": [],
  "pre_approved_agent_privileges_names": [],
  "workflow_definition": "developer/v1",
  "status": "running",
  "allow_agent_to_request_user": true,
  "image": null,
  "environment": null,
  "ai_catalog_item_version_id": null,
  "workload": {
    "id": "abc-123",
    "message": "Workflow started"
  },
  "mcp_enabled": false,
  "gitlab_url": "https://gitlab.example.com"
}
```

## Répertorier tous les privilèges des agents {#list-all-agent-privileges}

Répertorie tous les privilèges d'agent d'IA disponibles avec leurs ID, noms, descriptions et indique si chacun est activé par défaut.

```plaintext
GET /ai/duo_workflows/workflows/agent_privileges
```

Ce point de terminaison ne prend en charge aucun attribut.

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type | Description |
|-----------|------|-------------|
| `all_privileges` | tableau d'objets | Tous les privilèges d'agent d'IA disponibles. |
| `all_privileges[].default_enabled` | boolean | Indique si le privilège est activé par défaut. |
| `all_privileges[].description` | string | Description lisible par l'humain de ce que le privilège autorise. |
| `all_privileges[].id` | entier | ID de privilège. |
| `all_privileges[].name` | string | Nom de privilège lisible par machine. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/ai/duo_workflows/workflows/agent_privileges"
```

Exemple de réponse :

```json
{
  "all_privileges": [
    {
      "id": 1,
      "name": "read_write_files",
      "description": "Allow local filesystem read/write access",
      "default_enabled": true
    },
    {
      "id": 2,
      "name": "read_only_gitlab",
      "description": "Allow read only access to GitLab APIs",
      "default_enabled": true
    },
    {
      "id": 3,
      "name": "read_write_gitlab",
      "description": "Allow write access to GitLab APIs",
      "default_enabled": true
    },
    {
      "id": 4,
      "name": "run_commands",
      "description": "Allow running any commands",
      "default_enabled": true
    },
    {
      "id": 5,
      "name": "use_git",
      "description": "Allow git commits, push and other git commands",
      "default_enabled": true
    },
    {
      "id": 6,
      "name": "run_mcp_tools",
      "description": "Allow running MCP tools",
      "default_enabled": true
    }
  ]
}
```
