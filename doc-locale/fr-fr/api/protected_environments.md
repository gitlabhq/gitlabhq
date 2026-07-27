---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des environnements protégés
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les [environnements protégés](../ci/environments/protected_environments.md).

> [!note]
> Pour les environnements protégés au niveau du groupe, consultez l'[API des environnements protégés au niveau du groupe](group_protected_environments.md)

## Niveaux d'accès valides {#valid-access-levels}

Les niveaux d'accès sont définis dans la méthode `ProtectedEnvironments::DeployAccessLevel::ALLOWED_ACCESS_LEVELS`. Actuellement, les niveaux suivants sont reconnus :

```plaintext
30 => Developer access
40 => Maintainer access
60 => Admin access
```

## Types d'héritage de groupe {#group-inheritance-types}

L'héritage de groupe permet aux niveaux d'accès de déploiement et aux règles d'accès de prendre en compte l'appartenance héritée à un groupe. Les types d'héritage de groupe sont définis par `ProtectedEnvironments::Authorizable::GROUP_INHERITANCE_TYPE`. Les types suivants sont reconnus :

```plaintext
0 => Direct group membership only (default)
1 => All inherited groups
```

## Lister les environnements protégés {#list-protected-environments}

Récupère la liste des environnements protégés d'un projet :

```plaintext
GET /projects/:id/protected_environments
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_environments/"
```

Exemple de réponse :

```json
[
   {
      "name":"production",
      "deploy_access_levels":[
         {
            "id": 12,
            "access_level":40,
            "access_level_description":"Maintainers",
            "user_id":null,
            "group_id":null,
            "group_inheritance_type": 0
         }
      ],
      "required_approval_count": 0
   }
]
```

## Obtenir un seul environnement protégé {#get-a-single-protected-environment}

Récupère un seul environnement protégé :

```plaintext
GET /projects/:id/protected_environments/:name
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `name` | string | oui | Le nom de l'environnement protégé |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_environments/production"
```

Exemple de réponse :

```json
{
   "name":"production",
   "deploy_access_levels":[
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "Maintainers",
         "user_id": null,
         "group_id": null,
         "group_inheritance_type": 0
      }
   ],
   "required_approval_count": 0
}
```

## Protéger un seul environnement {#protect-a-single-environment}

Protège un seul environnement :

```plaintext
POST /projects/:id/protected_environments
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`                            | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `name`                          | string         | oui | Le nom de l'environnement. |
| `deploy_access_levels`          | tableau          | oui | Tableau des niveaux d'accès autorisés à déployer, chacun étant décrit par un hash. |
| `approval_rules`                | tableau          | non  | Tableau des niveaux d'accès autorisés à approuver, chacun étant décrit par un hash. Voir [Règles d'approbation multiples](../ci/environments/deployment_approvals.md#add-multiple-approval-rules). |

Les éléments des tableaux `deploy_access_levels` et `approval_rules` doivent être l'un des suivants : `user_id`, `group_id` ou `access_level`, et prendre la forme `{user_id: integer}`, `{group_id: integer}` ou `{access_level: integer}`. Facultativement, vous pouvez spécifier `group_inheritance_type` pour chacun, en choisissant parmi les [types d'héritage de groupe valides](#group-inheritance-types).

Chaque utilisateur doit avoir accès au projet et chaque groupe doit [avoir ce projet partagé](../user/project/members/sharing_projects_groups.md).

```shell
curl --header 'Content-Type: application/json' \
     --request POST \
     --data '{"name": "production", "deploy_access_levels": [{"group_id": 9899826}], "approval_rules": [{"group_id": 134}, {"group_id": 135, "required_approvals": 2}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/22034114/protected_environments"
```

Exemple de réponse :

```json
{
   "name": "production",
   "deploy_access_levels": [
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "protected-access-group",
         "user_id": null,
         "group_id": 9899826,
         "group_inheritance_type": 0
      }
   ],
   "required_approval_count": 0,
   "approval_rules": [
      {
         "id": 38,
         "user_id": null,
         "group_id": 134,
         "access_level": null,
         "access_level_description": "qa-group",
         "required_approvals": 1,
         "group_inheritance_type": 0
      },
      {
         "id": 39,
         "user_id": null,
         "group_id": 135,
         "access_level": null,
         "access_level_description": "security-group",
         "required_approvals": 2,
         "group_inheritance_type": 0
      }
   ]
}
```

## Mettre à jour un environnement protégé {#update-a-protected-environment}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/351854) dans GitLab 15.4.

{{< /history >}}

Met à jour un seul environnement.

```plaintext
PUT /projects/:id/protected_environments/:name
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`                            | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `name`                          | string         | oui | Le nom de l'environnement. |
| `deploy_access_levels`          | tableau          | non  | Tableau des niveaux d'accès autorisés à déployer, chacun étant décrit par un hash. |
| `approval_rules`                | tableau          | non  | Tableau des niveaux d'accès autorisés à approuver, chacun étant décrit par un hash. Voir [Règles d'approbation multiples](../ci/environments/deployment_approvals.md#add-multiple-approval-rules) pour plus d'informations. |

Les éléments des tableaux `deploy_access_levels` et `approval_rules` doivent être l'un des suivants : `user_id`, `group_id` ou `access_level`, et prendre la forme `{user_id: integer}`, `{group_id: integer}` ou `{access_level: integer}`. Facultativement, vous pouvez spécifier `group_inheritance_type` pour chacun, en choisissant parmi les [types d'héritage de groupe valides](#group-inheritance-types).

Pour mettre à jour :

- **`user_id`** : Assurez-vous que l'utilisateur mis à jour a accès au projet. Vous devez également transmettre le `id` d'un `deploy_access_level` ou d'un `approval_rule` dans le hash correspondant.
- **`group_id`** : Assurez-vous que le groupe mis à jour [a ce projet partagé](../user/project/members/sharing_projects_groups.md). Vous devez également transmettre le `id` d'un `deploy_access_level` ou d'un `approval_rule` dans le hash correspondant.

Pour supprimer :

- Vous devez transmettre `_destroy` défini à `true`. Consultez les exemples suivants.

### Exemple : Créer un enregistrement `deploy_access_level` {#example-create-a-deploy_access_level-record}

```shell
curl --header 'Content-Type: application/json' \
     --request PUT \
     --data '{"deploy_access_levels": [{"group_id": 9899829, access_level: 40}]' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
```

Exemple de réponse :

```json
{
   "name": "production",
   "deploy_access_levels": [
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "protected-access-group",
         "user_id": null,
         "group_id": 9899829,
         "group_inheritance_type": 1
      }
   ],
   "required_approval_count": 0
}
```

### Exemple : Mettre à jour un enregistrement `deploy_access_level` {#example-update-a-deploy_access_level-record}

```shell
curl --header 'Content-Type: application/json' \
     --request PUT \
     --data '{"deploy_access_levels": [{"id": 12, "group_id": 22034120}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
```

```json
{
   "name": "production",
   "deploy_access_levels": [
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "protected-access-group",
         "user_id": null,
         "group_id": 22034120,
         "group_inheritance_type": 0
      }
   ],
   "required_approval_count": 2
}
```

### Exemple : Supprimer un enregistrement `deploy_access_level` {#example-delete-a-deploy_access_level-record}

```shell
curl --header 'Content-Type: application/json' \
     --request PUT \
     --data '{"deploy_access_levels": [{"id": 12, "_destroy": true}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
```

Exemple de réponse :

```json
{
   "name": "production",
   "deploy_access_levels": [],
   "required_approval_count": 0
}
```

### Exemple : Créer un enregistrement `approval_rule` {#example-create-an-approval_rule-record}

```shell
curl --header 'Content-Type: application/json' \
     --request PUT \
     --data '{"approval_rules": [{"group_id": 134, "required_approvals": 1}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
```

Exemple de réponse :

```json
{
   "name": "production",
   "approval_rules": [
      {
         "id": 38,
         "user_id": null,
         "group_id": 134,
         "access_level": null,
         "access_level_description": "qa-group",
         "required_approvals": 1,
         "group_inheritance_type": 0
      }
   ]
}
```

### Exemple : Mettre à jour un enregistrement `approval_rule` {#example-update-an-approval_rule-record}

```shell
curl --header 'Content-Type: application/json' \
     --request PUT \
     --data '{"approval_rules": [{"id": 38, "group_id": 135, "required_approvals": 2}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
```

```json
{
   "name": "production",
   "approval_rules": [
      {
         "id": 38,
         "user_id": null,
         "group_id": 135,
         "access_level": null,
         "access_level_description": "security-group",
         "required_approvals": 2,
         "group_inheritance_type": 0
      }
   ]
}
```

### Exemple : Supprimer un enregistrement `approval_rule` {#example-delete-an-approval_rule-record}

```shell
curl --header 'Content-Type: application/json' \
     --request PUT \
     --data '{"approval_rules": [{"id": 38, "_destroy": true}]}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/22034114/protected_environments/production"
```

Exemple de réponse :

```json
{
   "name": "production",
   "approval_rules": []
}
```

## Déprotéger un seul environnement {#unprotect-a-single-environment}

Déprotège l'environnement protégé donné :

```plaintext
DELETE /projects/:id/protected_environments/:name
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `name` | string | oui | Le nom de l'environnement protégé. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/protected_environments/staging"
```
