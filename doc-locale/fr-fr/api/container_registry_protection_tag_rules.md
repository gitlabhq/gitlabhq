---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation pour l'API REST des règles de protection des tags du registre de conteneurs dans GitLab."
title: API des règles de protection des tags du registre de conteneurs
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduites](https://gitlab.com/gitlab-org/gitlab/-/issues/581199) dans GitLab 18.7.

{{< /history >}}

Utilisez cette API REST pour gérer les [tags de conteneurs protégés](../user/packages/container_registry/protected_container_tags.md).

## Lister les règles de protection des tags du registre de conteneurs {#list-container-registry-protection-tag-rules}

Récupère une liste des règles de protection des tags du registre de conteneurs pour un projet.

```plaintext
GET /api/v4/projects/:id/registry/protection/tag/rules
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description                                                                     |
|-----------|-------------------|----------|---------------------------------------------------------------------------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet.      |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type | Description |
|-----------|------|-------------|
| `id` | entier | L'ID de la règle de protection des tags de conteneurs. |
| `minimum_access_level_for_delete` | string | Le niveau d'accès minimum requis pour supprimer le tag. Valeurs possibles : `maintainer`, `owner` ou `admin`. |
| `minimum_access_level_for_push` | string | Le niveau d'accès minimum requis pour envoyer (push) vers le tag. Valeurs possibles : `maintainer`, `owner` ou `admin`. |
| `project_id` | entier | L'ID du projet. |
| `tag_name_pattern` | string | Le modèle de nom de tag. Par exemple, `v*-release` ou `latest`. |

Peut retourner les codes de statut suivants :

- `200 OK` :  Une liste de règles de protection.
- `401 Unauthorized` :  Le jeton d'accès est invalide.
- `403 Forbidden` :  L'utilisateur n'a pas la permission de lister les règles de protection pour ce projet.
- `404 Not Found` :  Le projet est introuvable.

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/tag/rules"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "project_id": 7,
    "tag_name_pattern": "v*-release",
    "minimum_access_level_for_push": "maintainer",
    "minimum_access_level_for_delete": "maintainer"
  },
  {
    "id": 2,
    "project_id": 7,
    "tag_name_pattern": "latest",
    "minimum_access_level_for_push": "owner",
    "minimum_access_level_for_delete": "owner"
  }
]
```

## Créer une règle de protection des tags du registre de conteneurs {#create-a-container-registry-protection-tag-rule}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/581199) dans GitLab 18.8.

{{< /history >}}

Crée une règle de protection des tags du registre de conteneurs pour un projet.

```plaintext
POST /api/v4/projects/:id/registry/protection/tag/rules
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
|-----------|------|----------|-------------|
| `id` | entier ou chaîne | Oui | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `tag_name_pattern` | string | Oui | Modèle de nom de tag de conteneur protégé par la règle de protection. Par exemple, `v*-release`. Caractère générique `*` autorisé. |
| `minimum_access_level_for_push` | string | Oui | Niveau d'accès GitLab minimum requis pour envoyer (push) des tags de conteneurs. Valeurs possibles : `maintainer`, `owner` ou `admin`. |
| `minimum_access_level_for_delete` | string | Oui | Niveau d'accès GitLab minimum requis pour supprimer des tags de conteneurs. Valeurs possibles : `maintainer`, `owner` ou `admin`. |

En cas de succès, retourne [`201 Created`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type | Description |
|-----------|------|-------------|
| `id` | entier | L'identifiant unique de la règle de tag de conteneur. |
| `project_id` | entier | L'ID du projet auquel appartient cette règle de tag de conteneur. |
| `tag_name_pattern` | string | Le modèle glob utilisé pour correspondre aux noms de tags de conteneurs. Par exemple, `v*-release`. |
| `minimum_access_level_for_push` | string | Le niveau d'accès minimum requis pour envoyer (push) des tags de conteneurs correspondant à ce modèle. Valeurs possibles : `maintainer`, `owner` ou `admin`. |
| `minimum_access_level_for_delete` | string | Le niveau d'accès minimum requis pour supprimer des tags de conteneurs correspondant à ce modèle. Valeurs possibles : `maintainer`, `owner` ou `admin`. |

Peut retourner les codes de statut suivants :

- `201 Created` :  La règle de protection a été créée avec succès.
- `400 Bad Request` :  La règle de protection est invalide.
- `401 Unauthorized` :  Le jeton d'accès est invalide.
- `403 Forbidden` :  L'utilisateur n'a pas la permission de créer une règle de protection.
- `404 Not Found` :  Le projet est introuvable.
- `422 Unprocessable Entity` :  La règle de protection n'a pas pu être créée. Par exemple, parce que `tag_name_pattern` est déjà utilisé.

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/tag/rules" \
  --data '{
        "tag_name_pattern": "v*-release",
        "minimum_access_level_for_push": "maintainer",
        "minimum_access_level_for_delete": "maintainer"
    }'
```

Exemple de réponse :

```json
{
  "id": 1,
  "project_id": 7,
  "tag_name_pattern": "v*-release",
  "minimum_access_level_for_push": "maintainer",
  "minimum_access_level_for_delete": "maintainer"
}
```

## Mettre à jour une règle de protection des tags du registre de conteneurs {#update-a-container-registry-protection-tag-rule}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/581199) dans GitLab 18.9.

{{< /history >}}

Met à jour une règle de protection des tags du registre de conteneurs pour un projet.

```plaintext
PATCH /api/v4/projects/:id/registry/protection/tag/rules/:protection_rule_id
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
|-----------|------|----------|-------------|
| `id` | entier ou chaîne | Oui | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `protection_rule_id` | entier | Oui | ID de la règle de protection des tags à mettre à jour. |
| `minimum_access_level_for_delete` | string | Non | Niveau d'accès minimum requis pour supprimer des tags de conteneurs. Valeurs possibles : `maintainer`, `owner` ou `admin`. Pour annuler la valeur, utilisez une chaîne vide (`""`). |
| `minimum_access_level_for_push` | string | Non | Niveau d'accès minimum requis pour envoyer (push) des tags de conteneurs. Valeurs possibles : `maintainer`, `owner` ou `admin`. Pour annuler la valeur, utilisez une chaîne vide (`""`). |
| `tag_name_pattern` | string | Non | Modèle de nom de tag de conteneur protégé par la règle de protection. Par exemple, `v*-release`. Caractère générique `*` autorisé. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type | Description |
|-----------|------|-------------|
| `id` | entier | L'identifiant unique de la règle de tag de conteneur. |
| `project_id` | entier | L'ID du projet auquel appartient cette règle de tag de conteneur. |
| `tag_name_pattern` | string | Le modèle glob utilisé pour correspondre aux noms de tags de conteneurs. Par exemple, `v*-release`. |
| `minimum_access_level_for_push` | string | Le niveau d'accès minimum requis pour envoyer (push) des tags de conteneurs correspondant à ce modèle. Valeurs possibles : `maintainer`, `owner` ou `admin`. |
| `minimum_access_level_for_delete` | string | Le niveau d'accès minimum requis pour supprimer des tags de conteneurs correspondant à ce modèle. Valeurs possibles : `maintainer`, `owner` ou `admin`. |

Peut retourner les codes de statut suivants :

- `200 OK` :  La règle de protection a été mise à jour avec succès.
- `400 Bad Request` :  La règle de protection est invalide.
- `401 Unauthorized` :  Le jeton d'accès est invalide.
- `403 Forbidden` :  L'utilisateur n'a pas la permission de mettre à jour la règle de protection.
- `404 Not Found` :  Le projet est introuvable.
- `422 Unprocessable Entity` :  La règle de protection n'a pas pu être mise à jour. Par exemple, parce que `tag_name_pattern` est déjà utilisé.

Exemple de requête :

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/tag/rules/1" \
  --data '{
       "tag_name_pattern": "v*-stable"
    }'
```

Exemple de réponse :

```json
{
  "id": 1,
  "project_id": 7,
  "tag_name_pattern": "v*-stable",
  "minimum_access_level_for_push": "maintainer",
  "minimum_access_level_for_delete": "maintainer"
}
```

## Supprimer une règle de protection des tags du registre de conteneurs {#delete-a-container-registry-protection-tag-rule}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/581199) dans GitLab 18.9.

{{< /history >}}

Supprime une règle de protection des tags du registre de conteneurs d'un projet.

```plaintext
DELETE /api/v4/projects/:id/registry/protection/tag/rules/:protection_rule_id
```

Attributs pris en charge :

| Attribut | Type | Obligatoire | Description |
|-----------|------|----------|-------------|
| `id` | entier ou chaîne | Oui | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `protection_rule_id` | entier | Oui | ID de la règle de protection des tags du registre de conteneurs à supprimer. |

En cas de succès, retourne [`204 No Content`](rest/troubleshooting.md#status-codes).

Peut retourner les codes de statut suivants :

- `204 No Content` :  La règle de protection a été supprimée avec succès.
- `400 Bad Request` :  Le `id` ou le `protection_rule_id` sont manquants ou invalides.
- `401 Unauthorized` :  Le jeton d'accès est invalide.
- `403 Forbidden` :  L'utilisateur n'a pas la permission de supprimer la règle de protection.
- `404 Not Found` :  Le projet ou la règle de protection est introuvable.

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/registry/protection/tag/rules/1"
```
