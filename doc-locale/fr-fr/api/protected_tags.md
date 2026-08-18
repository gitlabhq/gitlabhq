---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des tags protégés
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [tags protégés](../user/project/protected_tags.md).

## Niveaux d'accès valides {#valid-access-levels}

Les niveaux d'accès suivants sont reconnus :

- `0` :  Aucun accès
- `30` :  Rôle Developer
- `40` :  Rôle Maintainer

## Lister les tags protégés {#list-protected-tags}

{{< history >}}

- Les informations sur la clé de déploiement ont été [introduites](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116846) dans GitLab 16.0.

{{< /history >}}

Récupère une liste de [tags protégés](../user/project/protected_tags.md) d'un projet. Cette fonction prend les paramètres de pagination `page` et `per_page` pour limiter la liste des tags protégés.

```plaintext
GET /projects/:id/protected_tags
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description                                                                      |
|-----------|-------------------|----------|----------------------------------------------------------------------------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).       |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                                         | Type    | Description |
|---------------------------------------------------|---------|-------------|
| `create_access_levels`                            | tableau   | Tableau des configurations de niveau d'accès à la création. |
| `create_access_levels[].access_level`             | entier | Niveau d'accès pour la création de tags. |
| `create_access_levels[].access_level_description` | string  | Description lisible par l'humain du niveau d'accès. |
| `create_access_levels[].deploy_key_id`            | entier | ID de la clé de déploiement avec accès en création. |
| `create_access_levels[].group_id`                 | entier | ID du groupe avec accès en création. Premium et Ultimate uniquement. |
| `create_access_levels[].id`                       | entier | ID de la configuration du niveau d'accès à la création. |
| `create_access_levels[].user_id`                  | entier | ID de l'utilisateur avec accès en création. Premium et Ultimate uniquement. |
| `name`                                            | string  | Nom du tag protégé. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_tags"
```

Exemple de réponse :

```json
[
  {
    "name": "release-1-0",
    "create_access_levels": [
      {
        "id":1,
        "access_level": 40,
        "access_level_description": "Maintainers"
      },
      {
        "id": 2,
        "access_level": 40,
        "access_level_description": "Deploy key",
        "deploy_key_id": 1
      }
    ]
  }
]
```

## Récupérer un tag protégé ou un tag protégé générique {#get-a-protected-tag-or-wildcard-protected-tag}

Récupère un tag protégé ou un tag protégé générique unique.

```plaintext
GET /projects/:id/protected_tags/:name
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `name`    | string            | Oui      | Nom du tag ou du générique. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                                         | Type    | Description |
|---------------------------------------------------|---------|-------------|
| `create_access_levels`                            | tableau   | Tableau des configurations de niveau d'accès à la création. |
| `create_access_levels[].access_level`             | entier | Niveau d'accès pour la création de tags. |
| `create_access_levels[].access_level_description` | string  | Description lisible par l'humain du niveau d'accès. |
| `create_access_levels[].deploy_key_id`            | entier | ID de la clé de déploiement avec accès en création. |
| `create_access_levels[].group_id`                 | entier | ID du groupe avec accès en création. Premium et Ultimate uniquement. |
| `create_access_levels[].id`                       | entier | ID de la configuration du niveau d'accès à la création. |
| `create_access_levels[].user_id`                  | entier | ID de l'utilisateur avec accès en création. Premium et Ultimate uniquement. |
| `name`                                            | string  | Nom du tag protégé. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_tags/release-1-0"
```

Exemple de réponse :

```json
{
  "name": "release-1-0",
  "create_access_levels": [
    {
      "id": 1,
      "access_level": 40,
      "access_level_description": "Maintainers"
    }
  ]
}
```

## Protéger un tag de dépôt {#protect-a-repository-tag}

{{< history >}}

- La configuration `deploy_key_id` a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166866) dans GitLab 17.5.
- La configuration `deploy_key_id` a été [déplacée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224542) de GitLab Premium vers GitLab Free dans GitLab 18.10.

{{< /history >}}

Protège un tag de dépôt unique, ou plusieurs tags de dépôt de projet, à l'aide d'un tag protégé générique.

```plaintext
POST /projects/:id/protected_tags
```

Attributs pris en charge :

| Attribut             | Type              | Obligatoire | Description |
|-----------------------|-------------------|----------|-------------|
| `id`                  | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `name`                | string            | Oui      | Nom du tag ou du générique. |
| `allowed_to_create`   | tableau             | Non       | Tableau des niveaux d'accès autorisés à créer des tags, chacun décrit par un hachage de la forme `{user_id: integer}`, `{group_id: integer}`, `{deploy_key_id: integer}` ou `{access_level: integer}`. `user_id`, `group_id` et `access_level` sont réservés à Premium et Ultimate. |
| `create_access_level` | entier           | Non       | Niveaux d'accès autorisés à créer. La valeur par défaut est `40` (rôle Maintainer). |

En cas de succès, renvoie [`201 Created`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                                         | Type    | Description |
|---------------------------------------------------|---------|-------------|
| `create_access_levels`                            | tableau   | Tableau des configurations de niveau d'accès à la création. |
| `create_access_levels[].access_level`             | entier | Niveau d'accès pour la création de tags. |
| `create_access_levels[].access_level_description` | string  | Description lisible par l'humain du niveau d'accès. |
| `create_access_levels[].deploy_key_id`            | entier | ID de la clé de déploiement avec accès en création. |
| `create_access_levels[].group_id`                 | entier | ID du groupe avec accès en création. Premium et Ultimate uniquement. |
| `create_access_levels[].id`                       | entier | ID de la configuration du niveau d'accès à la création. |
| `create_access_levels[].user_id`                  | entier | ID de l'utilisateur avec accès en création. Premium et Ultimate uniquement. |
| `name`                                            | string  | Nom du tag protégé. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_tags" \
  --data '{
   "allowed_to_create" : [
      {
         "user_id" : 1
      },
      {
         "access_level" : 30
      }
   ],
   "create_access_level" : 30,
   "name" : "*-stable"
}'
```

Exemple de réponse :

```json
{
  "name": "*-stable",
  "create_access_levels": [
    {
      "id": 1,
      "access_level": 30,
      "access_level_description": "Developers + Maintainers"
    }
  ]
}
```

### Exemple avec accès utilisateur et groupe {#example-with-user-and-group-access}

Les éléments du tableau `allowed_to_create` doivent prendre la forme `{user_id: integer}`, `{group_id: integer}`, `{deploy_key_id: integer}` ou `{access_level: integer}`. Chaque utilisateur doit avoir accès au projet et chaque groupe doit [avoir ce projet partagé](../user/project/members/sharing_projects_groups.md). Ces niveaux d'accès permettent un contrôle plus granulaire sur l'accès aux tags protégés. Pour plus d'informations, consultez [ajouter un groupe aux tags protégés](../user/project/protected_tags.md#add-a-group-to-protected-tags).

Cet exemple de requête illustre comment créer un tag protégé qui autorise l'accès en création à un utilisateur et un groupe spécifiques :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_tags" \
  --data "name=*-stable" \
  --data "allowed_to_create[][user_id]=10" \
  --data "allowed_to_create[][group_id]=20"
```

Cet exemple de réponse inclut :

- Un tag protégé avec le nom `"*-stable"`.
- `create_access_levels` avec l'ID `1` pour l'utilisateur avec l'ID `10`.
- `create_access_levels` avec l'ID `2` pour le groupe avec l'ID `20`.

```json
{
  "name": "*-stable",
  "create_access_levels": [
    {
      "id": 1,
      "access_level": null,
      "user_id": 10,
      "group_id": null,
      "access_level_description": "Administrator"
    },
    {
      "id": 2,
      "access_level": null,
      "user_id": null,
      "group_id": 20,
      "access_level_description": "Example Create Group"
    }
  ]
}
```

## Retirer la protection des tags de dépôt {#unprotect-repository-tags}

Retire la protection du tag protégé ou du tag protégé générique donné.

```plaintext
DELETE /projects/:id/protected_tags/:name
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `name`    | string            | Oui      | Nom du tag. |

En cas de succès, renvoie [`204 No Content`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_tags/*-stable"
```

## Sujets connexes {#related-topics}

- [API des tags](tags.md) pour tous les tags
- Documentation utilisateur des [tags](../user/project/repository/tags/_index.md)
- Documentation utilisateur des [tags protégés](../user/project/protected_tags.md)
