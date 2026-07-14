---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des alias de projet
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [alias de projet](../user/project/working_with_projects.md#project-aliases). Après avoir créé un alias pour un projet, les utilisateurs peuvent cloner le dépôt avec l'alias, ce qui peut être utile lors de la migration de dépôts.

Toutes les méthodes nécessitent une autorisation administrateur.

## Lister tous les alias de projet {#list-all-project-aliases}

Obtenir la liste de tous les alias de projet :

```plaintext
GET /project_aliases
```

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut    | Type    | Description |
|--------------|---------|-------------|
| `id`         | integer | ID de l'alias de projet. |
| `name`       | string  | Nom de l'alias. |
| `project_id` | integer | ID du projet associé. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_aliases"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "project_id": 1,
    "name": "gitlab-foss"
  },
  {
    "id": 2,
    "project_id": 2,
    "name": "gitlab"
  }
]
```

## Récupérer un alias de projet {#retrieve-a-project-alias}

Récupère les détails d'un alias de projet :

```plaintext
GET /project_aliases/:name
```

Attributs pris en charge :

| Attribut | Type   | Obligatoire | Description           |
|-----------|--------|----------|-----------------------|
| `name`    | string | Oui      | Le nom de l'alias. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut    | Type    | Description |
|--------------|---------|-------------|
| `id`         | integer | ID de l'alias de projet. |
| `name`       | string  | Nom de l'alias. |
| `project_id` | integer | ID du projet associé. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_aliases/gitlab"
```

Exemple de réponse :

```json
{
  "id": 1,
  "project_id": 1,
  "name": "gitlab"
}
```

## Créer un alias de projet {#create-a-project-alias}

Ajouter un nouvel alias pour un projet :

```plaintext
POST /project_aliases
```

Attributs pris en charge :

| Attribut    | Type              | Obligatoire | Description |
|--------------|-------------------|----------|-------------|
| `name`       | string            | Oui      | Nom de l'alias. Doit être unique. |
| `project_id` | integer ou string | Oui      | ID ou chemin du projet. |

En cas de succès, renvoie [`201 Created`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut    | Type    | Description |
|--------------|---------|-------------|
| `id`         | integer | ID de l'alias de projet. |
| `name`       | string  | Nom de l'alias. |
| `project_id` | integer | ID du projet associé. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_aliases" \
  --form "project_id=1" \
  --form "name=gitlab"
```

Vous pouvez également utiliser le chemin du projet :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_aliases" \
  --form "project_id=gitlab-org/gitlab" \
  --form "name=gitlab"
```

Exemple de réponse :

```json
{
  "id": 1,
  "project_id": 1,
  "name": "gitlab"
}
```

## Supprimer un alias de projet {#delete-a-project-alias}

Supprimer un alias de projet :

```plaintext
DELETE /project_aliases/:name
```

Attributs pris en charge :

| Attribut | Type   | Obligatoire | Description           |
|-----------|--------|----------|-----------------------|
| `name`    | string | Oui      | Nom de l'alias. |

En cas de succès, renvoie [`204 No Content`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/project_aliases/gitlab"
```
