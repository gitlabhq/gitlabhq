---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des environnements protégés au niveau du groupe
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/215888) dans GitLab 14.0. [Déployé derrière le flag `group_level_protected_environments`](../administration/feature_flags/_index.md), désactivé par défaut.
- [Feature flag `group_level_protected_environments`](https://gitlab.com/gitlab-org/gitlab/-/issues/331085) supprimé dans GitLab 14.3.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/331085) dans GitLab 14.3.

{{< /history >}}

Utilisez cette API pour interagir avec les [environnements protégés au niveau du groupe](../ci/environments/protected_environments.md#group-level-protected-environments).

> [!note]
> Pour les environnements protégés, voir [l'API des environnements protégés](protected_environments.md)

## Niveaux d'accès valides {#valid-access-levels}

Les niveaux d'accès sont définis dans la méthode `ProtectedEnvironments::DeployAccessLevel::ALLOWED_ACCESS_LEVELS`. Actuellement, ces niveaux sont reconnus :

```plaintext
30 => Developer access
40 => Maintainer access
60 => Admin access
```

## Lister tous les environnements protégés au niveau du groupe {#list-all-group-level-protected-environments}

Liste tous les environnements protégés pour un groupe spécifié.

```plaintext
GET /groups/:id/protected_environments
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé dans l'URL](rest/_index.md#namespaced-paths) du groupe maintenu par l'utilisateur authentifié. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_environments/"
```

Exemple de réponse :

```json
[
   {
      "name":"production",
      "deploy_access_levels":[
         {
            "id": 12,
            "access_level": 40,
            "access_level_description": "Maintainers",
            "user_id": null,
            "group_id": null
         }
      ],
      "required_approval_count": 0
   }
]
```

## Récupérer un seul environnement protégé {#retrieve-a-single-protected-environment}

Récupère un environnement protégé spécifié à partir d'un groupe.

```plaintext
GET /groups/:id/protected_environments/:name
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé dans l'URL](rest/_index.md#namespaced-paths) du groupe maintenu par l'utilisateur authentifié. |
| `name`    | string | oui    | Le [niveau de déploiement](../ci/environments/_index.md#deployment-tier-of-environments) de l'environnement protégé. Valeurs possibles : `production`, `staging`, `testing`, `development` ou `other`.|

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_environments/production"
```

Exemple de réponse :

```json
{
   "name":"production",
   "deploy_access_levels":[
      {
         "id": 12,
         "access_level":40,
         "access_level_description":"Maintainers",
         "user_id":null,
         "group_id":null
      }
   ],
   "required_approval_count": 0
}
```

## Protéger un seul environnement {#protect-a-single-environment}

Protège un seul environnement.

```plaintext
POST /groups/:id/protected_environments
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | L'ID ou le [chemin encodé dans l'URL](rest/_index.md#namespaced-paths) du groupe maintenu par l'utilisateur authentifié. |
| `name`    | string | oui    | Le [niveau de déploiement](../ci/environments/_index.md#deployment-tier-of-environments) de l'environnement protégé. Valeurs possibles : `production`, `staging`, `testing`, `development` ou `other`.|
| `deploy_access_levels`          | tableau          | oui | Tableau des niveaux d'accès autorisés à déployer, chacun décrit par un hash. Valeurs possibles : `user_id`, `group_id` ou `access_level`. Ils prennent la forme de `{user_id: integer}`, `{group_id: integer}` ou `{access_level: integer}`. |
| `approval_rules`                | tableau          | non  | Tableau des niveaux d'accès autorisés à approuver, chacun décrit par un hash. Valeurs possibles : `user_id`, `group_id` ou `access_level`. Ils prennent la forme de `{user_id: integer}`, `{group_id: integer}` ou `{access_level: integer}`. Vous pouvez également spécifier le nombre d'approbations requises de l'entité spécifiée avec le champ `required_approvals`. Voir [Règles d'approbation multiples](../ci/environments/deployment_approvals.md#add-multiple-approval-rules) pour plus d'informations. |

Les `user_id` assignables sont les utilisateurs qui appartiennent au groupe donné avec le rôle Maintainer (ou supérieur). Les `group_id` assignables sont les sous-groupes du groupe donné.

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_environments" \
  --data '{"name": "production", "deploy_access_levels": [{"group_id": 9899826}]}'
```

Exemple de réponse :

```json
{
   "name":"production",
   "deploy_access_levels":[
      {
         "id": 12,
         "access_level": 40,
         "access_level_description": "protected-access-group",
         "user_id": null,
         "group_id": 9899826
      }
   ],
   "required_approval_count": 0
}
```

Un exemple avec plusieurs règles d'approbation :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/128/protected_environments" \
  --data '{
    "name": "production",
    "deploy_access_levels": [{"group_id": 138}],
    "approval_rules": [
      {"group_id": 134},
      {"group_id": 135, "required_approvals": 2}
    ]
  }'
```

Dans cette configuration, le groupe opérateur `"group_id": 138` peut exécuter le job de déploiement vers `production` uniquement après que le groupe QA `"group_id": 134` et le groupe sécurité `"group_id": 135` ont approuvé le déploiement.

## Mettre à jour un environnement protégé {#update-a-protected-environment}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/351854) dans GitLab 15.4.

{{< /history >}}

Met à jour un seul environnement.

```plaintext
PUT /groups/:id/protected_environments/:name
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | entier ou chaîne | oui | L'ID ou le [chemin encodé dans l'URL](rest/_index.md#namespaced-paths) du groupe maintenu par l'utilisateur authentifié. |
| `name`    | string | oui    | Le [niveau de déploiement](../ci/environments/_index.md#deployment-tier-of-environments) de l'environnement protégé. Valeurs possibles : `production`, `staging`, `testing`, `development` ou `other`.|
| `deploy_access_levels`          | tableau          | non | Tableau des niveaux d'accès autorisés à déployer, chacun décrit par un hash. Valeurs possibles : `user_id`, `group_id` ou `access_level`. Ils prennent la forme de `{user_id: integer}`, `{group_id: integer}` ou `{access_level: integer}`. |
| `required_approval_count` | entier        | non       | Le nombre d'approbations requises pour déployer dans cet environnement. |
| `approval_rules`                | tableau          | non  | Tableau des niveaux d'accès autorisés à approuver, chacun décrit par un hash. Valeurs possibles : `user_id`, `group_id` ou `access_level`. Ils prennent la forme de `{user_id: integer}`, `{group_id: integer}` ou `{access_level: integer}`. Vous pouvez également spécifier le nombre d'approbations requises de l'entité spécifiée avec le champ `required_approvals`. Voir [Règles d'approbation multiples](../ci/environments/deployment_approvals.md#add-multiple-approval-rules) pour plus d'informations. |

Pour mettre à jour :

- **`user_id`** : Assurez-vous que l'utilisateur mis à jour appartient au groupe donné avec le rôle Maintainer (ou supérieur). Vous devez également transmettre l'`id` d'un `deploy_access_level` ou d'un `approval_rule` dans le hash correspondant.
- **`group_id`** : Assurez-vous que le groupe mis à jour est un sous-groupe du groupe auquel appartient cet environnement protégé. Vous devez également transmettre l'`id` d'un `deploy_access_level` ou d'un `approval_rule` dans le hash correspondant.

Pour supprimer :

- Vous devez transmettre `_destroy` défini sur `true`. Voir les exemples suivants.

### Exemple : Créer un enregistrement `deploy_access_level` {#example-create-a-deploy_access_level-record}

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production" \
  --data '{"deploy_access_levels": [{"group_id": 9899829, "access_level": 40}]}'
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
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production" \
  --data '{"deploy_access_levels": [{"id": 12, "group_id": 22034120}]}'
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
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production" \
  --data '{"deploy_access_levels": [{"id": 12, "_destroy": true}]}'
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
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production" \
  --data '{"approval_rules": [{"group_id": 134, "required_approvals": 1}]}'
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
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production" \
  --data '{"approval_rules": [{"id": 38, "group_id": 135, "required_approvals": 2}]}'
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
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/22034114/protected_environments/production" \
  --data '{"approval_rules": [{"id": 38, "_destroy": true}]}'
```

Exemple de réponse :

```json
{
   "name": "production",
   "approval_rules": []
}
```

## Retirer la protection d'un seul environnement {#unprotect-a-single-environment}

Retire la protection de l'environnement protégé donné.

```plaintext
DELETE /groups/:id/protected_environments/:name
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID ou le [chemin encodé dans l'URL](rest/_index.md#namespaced-paths) du groupe maintenu par l'utilisateur authentifié. |
| `name`    | string | oui    | Le [niveau de déploiement](../ci/environments/_index.md#deployment-tier-of-environments) de l'environnement protégé. Valeurs possibles : `production`, `staging`, `testing`, `development` ou `other`.|

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/protected_environments/staging"
```

La réponse devrait retourner un code 200.
