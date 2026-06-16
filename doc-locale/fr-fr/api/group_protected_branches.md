---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des branches protégées au niveau du groupe
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/500250) dans GitLab 17.6. L'indicateur de fonctionnalité `group_protected_branches` a été supprimé.

{{< /history >}}

Utilisez cette API pour gérer les [paramètres des branches protégées](../user/project/repository/branches/protected.md#in-a-group) qui sont héritées par tous les projets d'un groupe. Les branches protégées de groupe ne prennent en charge que les [niveaux d'accès valides](#valid-access-levels). Les utilisateurs individuels et les groupes ne peuvent pas être spécifiés.

> [!warning]
> Les paramètres des branches protégées pour les groupes sont limités aux groupes principaux uniquement.

## Niveaux d'accès valides {#valid-access-levels}

Les niveaux d'accès sont définis dans la méthode `ProtectedRefAccess.allowed_access_levels`. Ces niveaux sont reconnus :

```plaintext
0  => No access
30 => Developer access
40 => Maintainer access
60 => Admin access
```

## Lister les branches protégées {#list-protected-branches}

Récupère la liste des branches protégées d'un groupe. Si un caractère générique est défini, il est retourné à la place du nom exact des branches qui correspondent à ce caractère générique.

```plaintext
GET /groups/:id/protected_branches
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `search` | string | non | Nom ou partie du nom des branches protégées à rechercher. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_branches"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "main",
    "push_access_levels": [
      {
        "id":  1,
        "access_level": 40,
        "user_id": null,
        "group_id": null,
        "access_level_description": "Maintainers"
      }
    ],
    "merge_access_levels": [
      {
        "id":  1,
        "access_level": 40,
        "user_id": null,
        "group_id": null,
        "access_level_description": "Maintainers"
      }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false
  },
  {
    "id": 1,
    "name": "release/*",
    "push_access_levels": [
      {
        "id":  1,
        "access_level": 40,
        "user_id": null,
        "group_id": null,
        "access_level_description": "Maintainers"
      }
    ],
    "merge_access_levels": [
      {
        "id":  1,
        "access_level": 40,
        "user_id": null,
        "group_id": null,
        "access_level_description": "Maintainers"
      }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false
  },
  ...
]
```

## Obtenir une seule branche protégée ou une branche protégée avec caractère générique {#get-a-single-protected-branch-or-wildcard-protected-branch}

Récupère une seule branche protégée ou une branche protégée avec caractère générique.

```plaintext
GET /groups/:id/protected_branches/:name
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `name` | string | oui | Le nom de la branche ou du caractère générique. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_branches/main"
```

Exemple de réponse :

```json
{
  "id": 1,
  "name": "main",
  "push_access_levels": [
    {
      "id":  1,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  1,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

## Protéger des branches de dépôt {#protect-repository-branches}

Protège une seule branche de dépôt à l'aide d'une branche protégée avec caractère générique.

```plaintext
POST /groups/:id/protected_branches
```

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_branches?name=*-stable&push_access_level=30&merge_access_level=30&unprotect_access_level=40"
```

| Attribut                                    | Type | Obligatoire | Description |
| -------------------------------------------- | ---- | -------- | ----------- |
| `id`                                         | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `name`                                       | string         | oui | Le nom de la branche ou du caractère générique. |
| `allow_force_push`                           | boolean        | non  | Autoriser tous les utilisateurs disposant d'un accès en push à forcer le push. Par défaut : `false`. |
| `allowed_to_merge`                           | tableau          | non  | Tableau des niveaux d'accès autorisés à fusionner, chacun décrit par un hachage de la forme `{user_id: integer}`, `{group_id: integer}` ou `{access_level: integer}`. |
| `allowed_to_push`                            | tableau          | non  | Tableau des niveaux d'accès autorisés à pousser, chacun décrit par un hachage de la forme `{user_id: integer}`, `{group_id: integer}` ou `{access_level: integer}`. |
| `allowed_to_unprotect`                       | tableau          | non  | Tableau des niveaux d'accès autorisés à ôter la protection, chacun décrit par un hachage de la forme `{user_id: integer}`, `{group_id: integer}` ou `{access_level: integer}`. |
| `code_owner_approval_required`               | boolean        | non  | Empêcher les pushs vers cette branche si elle correspond à un élément du [fichier `CODEOWNERS`](../user/project/codeowners/_index.md). Par défaut : `false`. |
| `merge_access_level`                         | entier        | non  | Niveaux d'accès autorisés à fusionner. Valeur par défaut : `40`, rôle Maintainer. |
| `push_access_level`                          | entier        | non  | Niveaux d'accès autorisés à pousser. Valeur par défaut : `40`, rôle Maintainer. |
| `unprotect_access_level`                     | entier        | non  | Niveaux d'accès autorisés à ôter la protection. Valeur par défaut : `40`, rôle Maintainer. |

Exemple de réponse :

```json
{
  "id": 1,
  "name": "*-stable",
  "push_access_levels": [
    {
      "id":  1,
      "access_level": 30,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  1,
      "access_level": 30,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "unprotect_access_levels": [
    {
      "id":  1,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

### Exemple avec des niveaux d'accès {#example-with-access-levels}

Utilisez les niveaux d'accès pour configurer les branches protégées de groupe :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "main",
    "allowed_to_push": [{"access_level": 30}],
    "allowed_to_merge": [{
        "access_level": 30
      },{
        "access_level": 40
      }
    ]}'
    --url "https://gitlab.example.com/api/v4/groups/5/protected_branches"
```

Exemple de réponse :

```json
{
    "id": 5,
    "name": "main",
    "push_access_levels": [
        {
            "id": 1,
            "access_level": 30,
            "access_level_description": "Developers + Maintainers",
            "user_id": null,
            "group_id": null
        }
    ],
    "merge_access_levels": [
        {
            "id": 1,
            "access_level": 30,
            "access_level_description": "Developers + Maintainers",
            "user_id": null,
            "group_id": null
        },
        {
            "id": 2,
            "access_level": 40,
            "access_level_description": "Maintainers",
            "user_id": null,
            "group_id": null
        }
    ],
    "unprotect_access_levels": [
        {
            "id": 1,
            "access_level": 40,
            "access_level_description": "Maintainers",
            "user_id": null,
            "group_id": null
        }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false
}
```

## Ôter la protection des branches de dépôt {#unprotect-repository-branches}

Ôte la protection de la branche protégée ou de la branche protégée avec caractère générique indiquée.

```plaintext
DELETE /groups/:id/protected_branches/:name
```

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_branches/*-stable"
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `name` | string | oui | Le nom de la branche. |

Exemple de réponse :

```json
{
   "name": "main",
   "push_access_levels": [
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "Maintainers",
         "user_id": null,
         "group_id": null
      }
   ]
}
```

## Mettre à jour une branche protégée {#update-a-protected-branch}

Met à jour une branche protégée.

```plaintext
PATCH /groups/:id/protected_branches/:name
```

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_branches/feature-branch?allow_force_push=true&code_owner_approval_required=true"
```

| Attribut                                    | Type           | Obligatoire | Description                                                                                                                          |
| -------------------------------------------- | ---- | -------- | ----------- |
| `id`                                         | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe.                       |
| `name`                                       | string         | oui      | Le nom de la branche.                                                                                                               |
| `allow_force_push`                           | boolean        | non       | Lorsqu'il est activé, les membres pouvant pousser vers cette branche peuvent également forcer le push.                                                               |
| `allowed_to_push`                            | tableau          | non       | Tableau des niveaux d'accès en push, chacun décrit par un hachage.                                                                          |
| `allowed_to_merge`                           | tableau          | non       | Tableau des niveaux d'accès en fusion, chacun décrit par un hachage.                                                                         |
| `allowed_to_unprotect`                       | tableau          | non       | Tableau des niveaux d'accès pour ôter la protection, chacun décrit par un hachage.                                                                     |
| `code_owner_approval_required`               | boolean        | non       | Empêcher les pushs vers cette branche si elle correspond à un élément du [fichier `CODEOWNERS`](../user/project/codeowners/_index.md). Par défaut : `false`. |

Les éléments des tableaux `allowed_to_push`, `allowed_to_merge` et `allowed_to_unprotect` doivent prendre la forme `{access_level: integer}`. Chaque niveau d'accès doit être une valeur valide parmi les [niveaux d'accès valides](#valid-access-levels).

- Pour mettre à jour les niveaux d'accès, vous devez également passer le `id` de `access_level` dans le hachage correspondant.
- Pour supprimer des niveaux d'accès, vous devez passer `_destroy` défini à `true`. Consultez les exemples suivants.

### Exemple : créer un enregistrement `push_access_level` {#example-create-a-push_access_level-record}

```shell
curl --header 'Content-Type: application/json' --request PATCH \
  --data '{"allowed_to_push": [{access_level: 40}]}' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_branches/main"
```

Exemple de réponse :

```json
{
   "name": "main",
   "push_access_levels": [
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "Maintainers",
         "user_id": null,
         "group_id": null
      }
   ]
}
```

### Exemple : mettre à jour un enregistrement `push_access_level` {#example-update-a-push_access_level-record}

```shell
curl --header 'Content-Type: application/json' --request PATCH \
  --data '{"allowed_to_push": [{"id": 12, "access_level": 0}]' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_branches/main"
```

Exemple de réponse :

```json
{
   "name": "main",
   "push_access_levels": [
      {
         "id": 12,
         "access_level": 0,
         "access_level_description": "No One",
         "user_id": null,
         "group_id": null
      }
   ]
}
```

### Exemple : supprimer un enregistrement `push_access_level` {#example-delete-a-push_access_level-record}

```shell
curl --header 'Content-Type: application/json' --request PATCH \
  --data '{"allowed_to_push": [{"id": 12, "_destroy": true}]}' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_branches/main"
```

Exemple de réponse :

```json
{
   "name": "main",
   "push_access_levels": []
}
```
