---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des branches protégées
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [branches protégées](../user/project/repository/branches/protected.md).

GitLab Premium et GitLab Ultimate prennent en charge des protections plus granulaires pour les push vers les branches. Les administrateurs peuvent accorder l'autorisation de modifier et de pousser vers des branches protégées uniquement aux clés de déploiement, au lieu d'utilisateurs spécifiques.

## Niveaux d'accès valides {#valid-access-levels}

La méthode `ProtectedRefAccess.allowed_access_levels` définit les niveaux d'accès suivants utilisés dans les configurations de push, de fusion et de déprotection.

- `0` :  Aucun accès - Valide pour les niveaux d'accès push et fusion uniquement. Non valide pour les niveaux d'accès de déprotection.
- `30` :  Développeur
- `40` :  Mainteneur
- `60` :  Administrateur - Valide pour GitLab Self-Managed uniquement.

En plus des niveaux d'accès basés sur les rôles, vous pouvez attribuer l'accès par :

- Utilisateur (`user_id`) :  Valide pour les niveaux d'accès push, fusion et déprotection.
- Groupe (`group_id`) :  Valide pour les niveaux d'accès push, fusion et déprotection. Le groupe doit avoir le rôle Développeur, Mainteneur ou Propriétaire pour le projet.
- Clé de déploiement (`deploy_key_id`) :  Valide pour les niveaux d'accès push uniquement.

Pour plus d'informations, consultez les [exemples de protection des branches du dépôt](#protect-repository-branches).

> [!note]
> Pour éviter de verrouiller définitivement les paramètres de protection d'une branche, assurez-vous qu'au moins un utilisateur ou groupe conserve à tout moment les autorisations de déprotection pour la branche. Pour plus d'informations, consultez [contrôler qui peut déprotéger les branches](../user/project/repository/branches/protected.md#control-who-can-unprotect-branches).

## Lister les branches protégées {#list-protected-branches}

{{< history >}}

- Les informations sur la clé de déploiement ont été [introduites](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/116846) dans GitLab 16.0.

{{< /history >}}

Obtenez une liste des [branches protégées](../user/project/repository/branches/protected.md) d'un projet telles qu'elles sont définies dans l'interface utilisateur. Si un caractère générique est défini, il est retourné à la place du nom exact des branches qui correspondent à ce caractère générique.

```plaintext
GET /projects/:id/protected_branches
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé par URL du projet](rest/_index.md#namespaced-paths). |
| `search`  | string            | Non       | Nom ou partie du nom des branches protégées à rechercher. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                                        | Type    | Description |
|--------------------------------------------------|---------|-------------|
| `allow_force_push`                               | boolean | Si `true`, le push forcé est autorisé sur cette branche. |
| `code_owner_approval_required`                   | boolean | Si `true`, l'approbation du propriétaire du code est requise pour les push vers cette branche. |
| `id`                                             | entier | ID de la branche protégée. |
| `inherited`                                      | boolean | Si `true`, les paramètres de protection sont hérités du groupe parent. Premium et Ultimate uniquement. |
| `merge_access_levels`                            | tableau   | Tableau des configurations de niveau d'accès pour la fusion. |
| `merge_access_levels[].access_level`             | entier | Niveau d'accès pour la fusion. |
| `merge_access_levels[].access_level_description` | string  | Description lisible du niveau d'accès. |
| `merge_access_levels[].group_id`                 | entier | ID du groupe avec accès à la fusion. Premium et Ultimate uniquement. |
| `merge_access_levels[].id`                       | entier | ID de la configuration du niveau d'accès pour la fusion. |
| `merge_access_levels[].user_id`                  | entier | ID de l'utilisateur avec accès à la fusion. Premium et Ultimate uniquement. |
| `name`                                           | string  | Nom de la branche protégée. |
| `push_access_levels`                             | tableau   | Tableau des configurations de niveau d'accès pour le push. |
| `push_access_levels[].access_level`              | entier | Niveau d'accès pour le push. |
| `push_access_levels[].access_level_description`  | string  | Description lisible du niveau d'accès. |
| `push_access_levels[].deploy_key_id`             | entier | ID de la clé de déploiement avec accès push. |
| `push_access_levels[].group_id`                  | entier | ID du groupe avec accès push. Premium et Ultimate uniquement. |
| `push_access_levels[].id`                        | entier | ID de la configuration du niveau d'accès pour le push. |
| `push_access_levels[].user_id`                   | entier | ID de l'utilisateur avec accès push. Premium et Ultimate uniquement. |

Dans l'exemple de requête suivant, l'ID du projet est `5`.

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches"
```

L'exemple de réponse suivant comprend :

- Deux branches protégées avec les IDs `100` et `101`.
- `push_access_levels` avec les IDs `1001`, `1002` et `1003`.
- `merge_access_levels` avec les IDs `2001` et `2002`.

```json
[
  {
    "id": 100,
    "name": "main",
    "push_access_levels": [
      {
        "id":  1001,
        "access_level": 40,
        "access_level_description": "Maintainers"
      },
      {
        "id": 1002,
        "access_level": 40,
        "access_level_description": "Deploy key",
        "deploy_key_id": 1
      }
    ],
    "merge_access_levels": [
      {
        "id":  2001,
        "access_level": 40,
        "access_level_description": "Maintainers"
      }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false
  },
  {
    "id": 101,
    "name": "release/*",
    "push_access_levels": [
      {
        "id":  1003,
        "access_level": 40,
        "access_level_description": "Maintainers"
      }
    ],
    "merge_access_levels": [
      {
        "id":  2002,
        "access_level": 40,
        "access_level_description": "Maintainers"
      }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false
  }
]
```

Les utilisateurs de GitLab Premium ou Ultimate voient également les paramètres `user_id`, `group_id` et `inherited`. Si le paramètre `inherited` existe, le paramètre a été hérité du groupe du projet.

L'exemple de réponse suivant comprend :

- Une branche protégée avec l'ID `100`.
- `push_access_levels` avec les IDs `1001` et `1002`.
- `merge_access_levels` avec l'ID `2001`.

```json
[
  {
    "id": 101,
    "name": "main",
    "push_access_levels": [
      {
        "id":  1001,
        "access_level": 40,
        "user_id": null,
        "group_id": null,
        "access_level_description": "Maintainers"
      },
      {
        "id": 1002,
        "access_level": 40,
        "access_level_description": "Deploy key",
        "deploy_key_id": 1,
        "user_id": null,
        "group_id": null
      }
    ],
    "merge_access_levels": [
      {
        "id":  2001,
        "access_level": null,
        "user_id": null,
        "group_id": 1234,
        "access_level_description": "Example Merge Group"
      }
    ],
    "allow_force_push":false,
    "code_owner_approval_required": false,
    "inherited": true
  }
]
```

## Récupérer une branche protégée ou une branche protégée avec caractère générique {#retrieve-a-protected-branch-or-wildcard-protected-branch}

Récupère une branche protégée spécifiée ou une branche protégée avec caractère générique.

```plaintext
GET /projects/:id/protected_branches/:name
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé par URL du projet](rest/_index.md#namespaced-paths). |
| `name`    | string            | Oui      | Nom de la branche ou du caractère générique. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                                        | Type    | Description |
|--------------------------------------------------|---------|-------------|
| `allow_force_push`                               | boolean | Si `true`, le push forcé est autorisé sur cette branche. |
| `code_owner_approval_required`                   | boolean | Si `true`, l'approbation du propriétaire du code est requise pour les push vers cette branche. |
| `id`                                             | entier | ID de la branche protégée. |
| `merge_access_levels`                            | tableau   | Tableau des configurations de niveau d'accès pour la fusion. |
| `merge_access_levels[].access_level`             | entier | Niveau d'accès pour la fusion. |
| `merge_access_levels[].access_level_description` | string  | Description lisible du niveau d'accès. |
| `merge_access_levels[].group_id`                 | entier | ID du groupe avec accès à la fusion. Premium et Ultimate uniquement. |
| `merge_access_levels[].id`                       | entier | ID de la configuration du niveau d'accès pour la fusion. |
| `merge_access_levels[].user_id`                  | entier | ID de l'utilisateur avec accès à la fusion. Premium et Ultimate uniquement. |
| `name`                                           | string  | Nom de la branche protégée. |
| `push_access_levels`                             | tableau   | Tableau des configurations de niveau d'accès pour le push. |
| `push_access_levels[].access_level`              | entier | Niveau d'accès pour le push. |
| `push_access_levels[].access_level_description`  | string  | Description lisible du niveau d'accès. |
| `push_access_levels[].group_id`                  | entier | ID du groupe avec accès push. Premium et Ultimate uniquement. |
| `push_access_levels[].id`                        | entier | ID de la configuration du niveau d'accès pour le push. |
| `push_access_levels[].user_id`                   | entier | ID de l'utilisateur avec accès push. Premium et Ultimate uniquement. |

Dans l'exemple de requête suivant, l'ID du projet est `5` et le nom de la branche est `main` :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches/main"
```

Exemple de réponse :

```json
{
  "id": 101,
  "name": "main",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": 40,
      "access_level_description": "Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": 40,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

Les utilisateurs de GitLab Premium ou Ultimate voient également les paramètres `user_id` et `group_id`.

Exemple de réponse :

```json
{
  "id": 101,
  "name": "main",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": null,
      "user_id": null,
      "group_id": 1234,
      "access_level_description": "Example Merge Group"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

## Protéger les branches du dépôt {#protect-repository-branches}

{{< history >}}

- La configuration `deploy_key_id` a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166598) dans GitLab 17.5.
- La configuration `deploy_key_id` a été [déplacée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224542) de GitLab Premium vers GitLab Free dans GitLab 18.10.

{{< /history >}}

Protégez une seule branche du dépôt ou plusieurs branches du dépôt du projet en utilisant une branche protégée avec caractère générique.

```plaintext
POST /projects/:id/protected_branches
```

Attributs pris en charge :

| Attribut                      | Type              | Obligatoire | Description |
|--------------------------------|-------------------|----------|-------------|
| `id`                           | entier ou chaîne | Oui      | ID ou [chemin encodé par URL du projet](rest/_index.md#namespaced-paths). |
| `name`                         | string            | Oui      | Nom de la branche ou du caractère générique. |
| `allow_force_push`             | boolean           | Non       | Si `true`, les membres pouvant effectuer un push vers cette branche peuvent également effectuer un push forcé. La valeur par défaut est `false`. |
| `allowed_to_merge`             | tableau             | Non       | Tableau des niveaux d'accès pour la fusion, chacun décrit par un hash de la forme `{user_id: integer}`, `{group_id: integer}` ou `{access_level: integer}`. Premium et Ultimate uniquement. |
| `allowed_to_push`              | tableau             | Non       | Tableau des niveaux d'accès pour le push, chacun décrit par un hash de la forme `{user_id: integer}`, `{group_id: integer}`, `{deploy_key_id: integer}` ou `{access_level: integer}`. `user_id`, `group_id` et `access_level` sont réservés à Premium et Ultimate. |
| `allowed_to_unprotect`         | tableau             | Non       | Tableau des niveaux d'accès pour la déprotection, chacun décrit par un hash de la forme `{user_id: integer}`, `{group_id: integer}` ou `{access_level: integer}`. Le niveau d'accès `No access` n'est pas disponible pour ce champ. Premium et Ultimate uniquement. |
| `code_owner_approval_required` | boolean           | Non       | Si `true`, empêche les push vers cette branche si elle correspond à un élément du [fichier `CODEOWNERS`](../user/project/codeowners/_index.md). La valeur par défaut est `false`. Premium et Ultimate uniquement. |
| `merge_access_level`           | entier           | Non       | Niveaux d'accès autorisés à fusionner. La valeur par défaut est `40` (rôle Mainteneur). |
| `push_access_level`            | entier           | Non       | Niveaux d'accès autorisés à effectuer un push. La valeur par défaut est `40` (rôle Mainteneur). |
| `unprotect_access_level`       | entier           | Non       | Niveaux d'accès autorisés à déprotéger. La valeur par défaut est `40` (rôle Mainteneur). `0` (Aucun accès) n'est pas valide. |

Lorsque vous configurez des niveaux d'accès :

- Vous pouvez définir plusieurs niveaux d'accès simultanément pour `allowed_to_push` et `allowed_to_merge`.
- Le niveau d'accès le plus permissif détermine qui peut effectuer l'action.
- N'incluez pas `id` dans les tableaux `allowed_to_push`, `allowed_to_merge` ou `allowed_to_unprotect`. Le champ `id` identifie un enregistrement de niveau d'accès existant et n'est valide que lorsque vous [mettez à jour une branche protégée](#update-a-protected-branch). Si vous incluez un `id` qui ne correspond pas à un enregistrement existant, l'API retourne `404 Not Found`.

Ce comportement diffère de l'interface utilisateur, qui efface automatiquement les autres sélections de rôle lorsque vous sélectionnez **Personne** (`access_level: 0`).

En cas de succès, retourne [`201 Created`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                                            | Type    | Description |
|------------------------------------------------------|---------|-------------|
| `allow_force_push`                                   | boolean | Si `true`, le push forcé est autorisé sur cette branche. |
| `code_owner_approval_required`                       | boolean | Si `true`, l'approbation du propriétaire du code est requise pour les push vers cette branche. |
| `id`                                                 | entier | ID de la branche protégée. |
| `merge_access_levels`                                | tableau   | Tableau des configurations de niveau d'accès pour la fusion. |
| `merge_access_levels[].access_level`                 | entier | Niveau d'accès pour la fusion. |
| `merge_access_levels[].access_level_description`     | string  | Description lisible du niveau d'accès. |
| `merge_access_levels[].group_id`                     | entier | ID du groupe avec accès à la fusion. Premium et Ultimate uniquement. |
| `merge_access_levels[].id`                           | entier | ID de la configuration du niveau d'accès pour la fusion. |
| `merge_access_levels[].user_id`                      | entier | ID de l'utilisateur avec accès à la fusion. Premium et Ultimate uniquement. |
| `name`                                               | string  | Nom de la branche protégée. |
| `push_access_levels`                                 | tableau   | Tableau des configurations de niveau d'accès pour le push. |
| `push_access_levels[].access_level`                  | entier | Niveau d'accès pour le push. |
| `push_access_levels[].access_level_description`      | string  | Description lisible du niveau d'accès. |
| `push_access_levels[].deploy_key_id`                 | entier | ID de la clé de déploiement avec accès push. |
| `push_access_levels[].group_id`                      | entier | ID du groupe avec accès push. Premium et Ultimate uniquement. |
| `push_access_levels[].id`                            | entier | ID de la configuration du niveau d'accès pour le push. |
| `push_access_levels[].user_id`                       | entier | ID de l'utilisateur avec accès push. Premium et Ultimate uniquement. |
| `unprotect_access_levels`                            | tableau   | Tableau des configurations de niveau d'accès pour la déprotection. |
| `unprotect_access_levels[].access_level`             | entier | Niveau d'accès pour la déprotection. |
| `unprotect_access_levels[].access_level_description` | string  | Description lisible du niveau d'accès. |
| `unprotect_access_levels[].group_id`                 | entier | ID du groupe avec accès à la déprotection. Premium et Ultimate uniquement. |
| `unprotect_access_levels[].id`                       | entier | ID de la configuration du niveau d'accès pour la déprotection. |
| `unprotect_access_levels[].user_id`                  | entier | ID de l'utilisateur avec accès à la déprotection. Premium et Ultimate uniquement. |

Dans l'exemple de requête suivant, l'ID du projet est `5` et le nom de la branche est `*-stable`.

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches?name=*-stable&push_access_level=30&merge_access_level=30&unprotect_access_level=40"
```

L'exemple de réponse comprend :

- Une branche protégée avec l'ID `101`.
- `push_access_levels` avec l'ID `1001`.
- `merge_access_levels` avec l'ID `2001`.
- `unprotect_access_levels` avec l'ID `3001`.

```json
{
  "id": 101,
  "name": "*-stable",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": 30,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": 30,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "unprotect_access_levels": [
    {
      "id":  3001,
      "access_level": 40,
      "access_level_description": "Maintainers"
    }
  ],
  "allow_force_push":false,
  "code_owner_approval_required": false
}
```

Les utilisateurs de GitLab Premium ou Ultimate voient également les paramètres `user_id` et `group_id` :

L'exemple de réponse suivant comprend :

- Une branche protégée avec l'ID `101`.
- `push_access_levels` avec l'ID `1001`.
- `merge_access_levels` avec l'ID `2001`.
- `unprotect_access_levels` avec l'ID `3001`.

```json
{
  "id": 1,
  "name": "*-stable",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": 30,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": 30,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Developers + Maintainers"
    }
  ],
  "unprotect_access_levels": [
    {
      "id":  3001,
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

### Exemple avec accès push utilisateur et accès fusion groupe {#example-with-user-push-access-and-group-merge-access}

{{< details >}}

- Édition :  Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les éléments du tableau `allowed_to_push` / `allowed_to_merge` / `allowed_to_unprotect` doivent prendre la forme `{user_id: integer}`, `{group_id: integer}` ou `{access_level: integer}`. Chaque utilisateur doit avoir accès au projet et chaque groupe doit [avoir ce projet partagé](../user/project/members/sharing_projects_groups.md). Ces niveaux d'accès permettent un contrôle plus granulaire sur l'accès aux branches protégées. Pour plus d'informations, consultez [configurer les autorisations de groupe](../user/project/repository/branches/protected.md#with-group-permissions).

L'exemple de requête suivant crée une branche protégée avec un accès push utilisateur et un accès fusion groupe. Le `user_id` est `2` et le `group_id` est `3`.

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches?name=*-stable&allowed_to_push%5B%5D%5Buser_id%5D=2&allowed_to_merge%5B%5D%5Bgroup_id%5D=3"
```

L'exemple de réponse suivant comprend :

- Une branche protégée avec l'ID `101`.
- `push_access_levels` avec l'ID `1001`.
- `merge_access_levels` avec l'ID `2001`.
- `unprotect_access_levels` avec l'ID `3001`.

```json
{
  "id": 101,
  "name": "*-stable",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": null,
      "user_id": 2,
      "group_id": null,
      "access_level_description": "Administrator"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": null,
      "user_id": null,
      "group_id": 3,
      "access_level_description": "Example Merge Group"
    }
  ],
  "unprotect_access_levels": [
    {
      "id":  3001,
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

### Exemple avec accès par clé de déploiement {#example-with-deploy-key-access}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166598) dans GitLab 17.5.
- [Déplacé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224542) de GitLab Premium vers GitLab Free dans GitLab 18.10.

{{< /history >}}

Les éléments du tableau `allowed_to_push` doivent prendre la forme `{user_id: integer}`, `{group_id: integer}`, `{deploy_key_id: integer}` ou `{access_level: integer}`. La clé de déploiement doit être activée pour votre projet et doit avoir un accès en écriture à votre dépôt de projet. Pour les autres exigences, consultez [autoriser les clés de déploiement à effectuer un push vers une branche protégée](../user/project/repository/branches/protected.md#enable-deploy-key-access).

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches?name=*-stable&allowed_to_push[][deploy_key_id]=1"
```

L'exemple de réponse suivant comprend :

- Une branche protégée avec l'ID `101`.
- `push_access_levels` avec l'ID `1001`.
- `merge_access_levels` avec l'ID `2001`.
- `unprotect_access_levels` avec l'ID `3001`.

```json
{
  "id": 101,
  "name": "*-stable",
  "push_access_levels": [
    {
      "id":  1001,
      "access_level": null,
      "user_id": null,
      "group_id": null,
      "deploy_key_id": 1,
      "access_level_description": "Deploy"
    }
  ],
  "merge_access_levels": [
    {
      "id":  2001,
      "access_level": 40,
      "user_id": null,
      "group_id": null,
      "access_level_description": "Maintainers"
    }
  ],
  "unprotect_access_levels": [
    {
      "id":  3001,
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

### Exemple avec accès autoriser à pousser et autoriser à fusionner {#example-with-allow-to-push-and-allow-to-merge-access}

{{< details >}}

- Édition :  Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Déplacé vers GitLab Premium dans la version 13.9.

{{< /history >}}

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "main",
    "allowed_to_push": [
      {"access_level": 30}
    ],
    "allowed_to_merge": [
      {"access_level": 30},
      {"access_level": 40}
    ]
  }' \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches"
```

L'exemple de réponse suivant comprend :

- Une branche protégée avec l'ID `105`.
- `push_access_levels` avec l'ID `1001`.
- `merge_access_levels` avec les IDs `2001` et `2002`.
- `unprotect_access_levels` avec l'ID `3001`.

```json
{
    "id": 105,
    "name": "main",
    "push_access_levels": [
        {
            "id": 1001,
            "access_level": 30,
            "access_level_description": "Developers + Maintainers",
            "user_id": null,
            "group_id": null
        }
    ],
    "merge_access_levels": [
        {
            "id": 2001,
            "access_level": 30,
            "access_level_description": "Developers + Maintainers",
            "user_id": null,
            "group_id": null
        },
        {
            "id": 2002,
            "access_level": 40,
            "access_level_description": "Maintainers",
            "user_id": null,
            "group_id": null
        }
    ],
    "unprotect_access_levels": [
        {
            "id": 3001,
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

### Exemples avec niveaux d'accès de déprotection {#examples-with-unprotect-access-levels}

{{< details >}}

- Édition :  Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Pour créer une branche protégée où seul un groupe spécifique peut déprotéger la branche :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "production",
    "allowed_to_unprotect": [
      {"group_id": 789}
    ]
  }' \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches"
```

Pour permettre à plusieurs types d'utilisateurs de déprotéger une branche :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "main",
    "allowed_to_unprotect": [
      {"user_id": 123},
      {"group_id": 456},
      {"access_level": 40}
    ]
  }' \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches"
```

Cette configuration permet à ces utilisateurs de déprotéger la branche :

- L'utilisateur avec l'ID `123`.
- Les membres du groupe avec l'ID `456`.
- Les utilisateurs avec le rôle Mainteneur ou Propriétaire (niveau d'accès 40).

## Déprotéger les branches du dépôt {#unprotect-repository-branches}

Déprotège la branche protégée ou la branche protégée avec caractère générique spécifiée.

```plaintext
DELETE /projects/:id/protected_branches/:name
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé par URL du projet](rest/_index.md#namespaced-paths). |
| `name`    | string            | Oui      | Nom de la branche. |

En cas de succès, retourne [`204 No Content`](rest/troubleshooting.md#status-codes).

Dans l'exemple de requête suivant, l'ID du projet est `5` et le nom de la branche est `*-stable` :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches/*-stable"
```

## Mettre à jour une branche protégée {#update-a-protected-branch}

{{< history >}}

- La configuration `deploy_key_id` a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166598) dans GitLab 17.5.

{{< /history >}}

Mettre à jour une branche protégée.

```plaintext
PATCH /projects/:id/protected_branches/:name
```

Attributs pris en charge :

| Attribut                      | Type              | Obligatoire | Description |
|--------------------------------|-------------------|----------|-------------|
| `id`                           | entier ou chaîne | Oui      | ID ou [chemin encodé par URL du projet](rest/_index.md#namespaced-paths). |
| `name`                         | string            | Oui      | Nom de la branche ou du caractère générique. |
| `allow_force_push`             | boolean           | Non       | Si `true`, les membres pouvant effectuer un push vers cette branche peuvent également effectuer un push forcé. |
| `allowed_to_merge`             | tableau             | Non       | Tableau des niveaux d'accès pour la fusion, chacun décrit par un hash de la forme `{user_id: integer}`, `{group_id: integer}` ou `{access_level: integer}`. Premium et Ultimate uniquement. |
| `allowed_to_push`              | tableau             | Non       | Tableau des niveaux d'accès pour le push, chacun décrit par un hash de la forme `{user_id: integer}`, `{group_id: integer}`, `{deploy_key_id: integer}` ou `{access_level: integer}`. `user_id`, `group_id` et `access_level` sont réservés à Premium et Ultimate. |
| `allowed_to_unprotect`         | tableau             | Non       | Tableau des niveaux d'accès pour la déprotection, chacun décrit par un hash de la forme `{user_id: integer}`, `{group_id: integer}`, `{access_level: integer}` ou `{id: integer, _destroy: true}` pour supprimer un niveau d'accès existant. Le niveau d'accès `No access` n'est pas disponible pour ce champ. Premium et Ultimate uniquement. |
| `code_owner_approval_required` | boolean           | Non       | Si `true`, empêche les push vers cette branche si elle correspond à un élément du [fichier `CODEOWNERS`](../user/project/codeowners/_index.md). Premium et Ultimate uniquement. |

Pour plus d'informations sur la façon dont les niveaux d'accès interagissent lorsque vous définissez plusieurs valeurs, consultez [protéger les branches du dépôt](#protect-repository-branches).

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                                            | Type    | Description |
|------------------------------------------------------|---------|-------------|
| `allow_force_push`                                   | boolean | Si `true`, le push forcé est autorisé sur cette branche. |
| `code_owner_approval_required`                       | boolean | Si `true`, l'approbation du propriétaire du code est requise pour les push vers cette branche. |
| `id`                                                 | entier | ID de la branche protégée. |
| `merge_access_levels`                                | tableau   | Tableau des configurations de niveau d'accès pour la fusion. |
| `merge_access_levels[].access_level`                 | entier | Niveau d'accès pour la fusion. |
| `merge_access_levels[].access_level_description`     | string  | Description lisible du niveau d'accès. |
| `merge_access_levels[].group_id`                     | entier | ID du groupe avec accès à la fusion. Premium et Ultimate uniquement. |
| `merge_access_levels[].id`                           | entier | ID de la configuration du niveau d'accès pour la fusion. |
| `merge_access_levels[].user_id`                      | entier | ID de l'utilisateur avec accès à la fusion. Premium et Ultimate uniquement. |
| `name`                                               | string  | Nom de la branche protégée. |
| `push_access_levels`                                 | tableau   | Tableau des configurations de niveau d'accès pour le push. |
| `push_access_levels[].access_level`                  | entier | Niveau d'accès pour le push. |
| `push_access_levels[].access_level_description`      | string  | Description lisible du niveau d'accès. |
| `push_access_levels[].deploy_key_id`                 | entier | ID de la clé de déploiement avec accès push. |
| `push_access_levels[].group_id`                      | entier | ID du groupe avec accès push. Premium et Ultimate uniquement. |
| `push_access_levels[].id`                            | entier | ID de la configuration du niveau d'accès pour le push. |
| `push_access_levels[].user_id`                       | entier | ID de l'utilisateur avec accès push. Premium et Ultimate uniquement. |
| `unprotect_access_levels`                            | tableau   | Tableau des configurations de niveau d'accès pour la déprotection. |
| `unprotect_access_levels[].access_level`             | entier | Niveau d'accès pour la déprotection. |
| `unprotect_access_levels[].access_level_description` | string  | Description lisible du niveau d'accès. |
| `unprotect_access_levels[].group_id`                 | entier | ID du groupe avec accès à la déprotection. Premium et Ultimate uniquement. |
| `unprotect_access_levels[].id`                       | entier | ID de la configuration du niveau d'accès pour la déprotection. |
| `unprotect_access_levels[].user_id`                  | entier | ID de l'utilisateur avec accès à la déprotection. Premium et Ultimate uniquement. |

Exemple de requête :

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches/feature-branch?allow_force_push=true&code_owner_approval_required=true"
```

Les éléments des tableaux `allowed_to_push`, `allowed_to_merge` et `allowed_to_unprotect` doivent être l'un des éléments suivants : `user_id`, `group_id` ou `access_level`, et prendre la forme `{user_id: integer}`, `{group_id: integer}` ou `{access_level: integer}`.

`allowed_to_push` inclut un élément supplémentaire, `deploy_key_id`, qui prend la forme `{deploy_key_id: integer}`.

Pour mettre à jour :

- `user_id` :  Assurez-vous que l'utilisateur mis à jour a accès au projet. Incluez le `id` de l'enregistrement du niveau d'accès dans le hash.
- `group_id` :  Assurez-vous que le groupe mis à jour [a ce projet partagé](../user/project/members/sharing_projects_groups.md). Incluez le `id` de l'enregistrement du niveau d'accès dans le hash.
- `deploy_key_id` :  Assurez-vous que la clé de déploiement est activée pour votre projet et dispose d'un accès en écriture à votre dépôt de projet.

Pour mettre à jour tout autre champ d'un enregistrement de niveau d'accès existant, incluez le `id` de l'enregistrement dans le hash.

Pour supprimer, vous devez passer `_destroy` défini sur `true`. Consultez les exemples suivants.

### Exemple : créer un enregistrement `push_access_level` {#example-create-a-push_access_level-record}

```shell
curl --header 'Content-Type: application/json' --request PATCH \
  --data '{"allowed_to_push": [{"access_level": 40}]}' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/22034114/protected_branches/main"
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
  --data '{"allowed_to_push": [{"id": 12, "access_level": 0}]}' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/22034114/protected_branches/main"
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
  --url "https://gitlab.example.com/api/v4/projects/22034114/protected_branches/main"
```

Exemple de réponse :

```json
{
   "name": "main",
   "push_access_levels": []
}
```

### Exemple : mettre à jour un enregistrement `unprotect_access_level` {#example-update-an-unprotect_access_level-record}

Prérequis :

- Les utilisateurs qui appellent cette API doivent être inclus dans la configuration `allowed_to_unprotect`.
- L'utilisateur spécifié par `user_id` doit être membre du projet.
- Les groupes spécifiés par `group_id` doivent avoir accès au projet.

Pour modifier qui peut déprotéger une branche protégée existante, incluez le `id` de l'enregistrement du niveau d'accès existant. Par exemple :

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "allowed_to_unprotect": [
      {"id": 17486, "user_id": 3791}
    ]
  }' \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_branches/main"
```

Pour supprimer des niveaux d'accès spécifiques, utilisez `_destroy: true`.

## Sujets connexes {#related-topics}

- [Branches protégées](../user/project/repository/branches/protected.md)
- [Branches](../user/project/repository/branches/_index.md)
- [API Branches](branches.md)
