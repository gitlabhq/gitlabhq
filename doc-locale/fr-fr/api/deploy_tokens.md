---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des jetons de déploiement
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les [jetons de déploiement](../user/project/deploy_tokens/_index.md).

## Lister tous les jetons de déploiement {#list-all-deploy-tokens}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lister tous les jetons de déploiement sur l'instance GitLab. Ce point de terminaison nécessite un accès administrateur.

```plaintext
GET /deploy_tokens
```

Paramètres :

| Attribut | Type     | Obligatoire               | Description |
|-----------|----------|------------------------|-------------|
| `active`  | boolean  | Non | Limiter par statut actif. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/deploy_tokens"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "MyToken",
    "username": "gitlab+deploy-token-1",
    "expires_at": "2020-02-14T00:00:00.000Z",
    "revoked": false,
    "expired": false,
    "scopes": [
      "read_repository",
      "read_registry"
    ]
  }
]
```

## Jetons de déploiement de projet {#project-deploy-tokens}

Les endpoints de l'API de jeton de déploiement de projet nécessitent le rôle Maintainer ou Owner pour le projet.

### Lister les jetons de déploiement d'un projet {#list-project-deploy-tokens}

Lister les jetons de déploiement d'un projet.

```plaintext
GET /projects/:id/deploy_tokens
```

Paramètres :

| Attribut      | Type           | Obligatoire               | Description |
|:---------------|:---------------|:-----------------------|:------------|
| `id`           | entier ou chaîne de caractères | Oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `active`       | boolean        | Non | Limiter par statut actif. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/deploy_tokens"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "MyToken",
    "username": "gitlab+deploy-token-1",
    "expires_at": "2020-02-14T00:00:00.000Z",
    "revoked": false,
    "expired": false,
    "scopes": [
      "read_repository",
      "read_registry"
    ]
  }
]
```

### Récupérer un jeton de déploiement de projet {#retrieve-a-project-deploy-token}

Récupérer le jeton de déploiement d'un projet par son ID.

```plaintext
GET /projects/:id/deploy_tokens/:token_id
```

Paramètres :

| Attribut  | Type           | Obligatoire               | Description |
| ---------- | -------------- | ---------------------- | ----------- |
| `id`       | entier ou chaîne de caractères | Oui | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `token_id` | integer        | Oui | ID du jeton de déploiement |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/deploy_tokens/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "name": "MyToken",
  "username": "gitlab+deploy-token-1",
  "expires_at": "2020-02-14T00:00:00.000Z",
  "revoked": false,
  "expired": false,
  "scopes": [
    "read_repository",
    "read_registry"
  ]
}
```

### Créer un jeton de déploiement de projet {#create-a-project-deploy-token}

Créer un jeton de déploiement de projet.

```plaintext
POST /projects/:id/deploy_tokens
```

Paramètres :

| Attribut    | Type             | Obligatoire               | Description |
| ------------ | ---------------- | ---------------------- | ----------- |
| `id`         | entier ou chaîne de caractères   | Oui | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `name`       | string           | Oui | Nom du nouveau jeton de déploiement |
| `scopes`     | tableau de chaînes de caractères | Oui | Indique les portées du jeton de déploiement. Doit être au moins l'une des valeurs suivantes : `read_repository`, `read_registry`, `write_registry`, `read_package_registry`, `write_package_registry`, `read_virtual_registry` ou `write_virtual_registry`. |
| `expires_at` | datetime         | Non | Date d'expiration du jeton de déploiement. N'expire pas si aucune valeur n'est fournie. Format ISO 8601 attendu (`2019-03-15T08:00:00Z`) |
| `username`   | string           | Non | Nom d'utilisateur du jeton de déploiement. La valeur par défaut est `gitlab+deploy-token-{n}` |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"name": "My deploy token", "expires_at": "2021-01-01", "username": "custom-user", "scopes": ["read_repository"]}' \
  --url "https://gitlab.example.com/api/v4/projects/5/deploy_tokens/"
```

Exemple de réponse :

```json
{
  "id": 1,
  "name": "My deploy token",
  "username": "custom-user",
  "expires_at": "2021-01-01T00:00:00.000Z",
  "token": "jMRvtPNxrn3crTAGukpZ",
  "revoked": false,
  "expired": false,
  "scopes": [
    "read_repository"
  ]
}
```

### Supprimer un jeton de déploiement de projet {#delete-a-project-deploy-token}

Supprimer un jeton de déploiement du projet.

```plaintext
DELETE /projects/:id/deploy_tokens/:token_id
```

Paramètres :

| Attribut  | Type           | Obligatoire               | Description |
| ---------- | -------------- | ---------------------- | ----------- |
| `id`       | entier ou chaîne de caractères | Oui | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `token_id` | integer        | Oui | ID du jeton de déploiement |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/deploy_tokens/13"
```

## Jetons de déploiement de groupe {#group-deploy-tokens}

Les utilisateurs ayant le rôle Maintainer ou Owner pour le groupe peuvent lister les jetons de déploiement du groupe. Seuls les Owners du groupe peuvent créer et supprimer des jetons de déploiement de groupe.

### Lister les jetons de déploiement d'un groupe {#list-group-deploy-tokens}

Lister les jetons de déploiement d'un groupe

```plaintext
GET /groups/:id/deploy_tokens
```

Paramètres :

| Attribut      | Type           | Obligatoire               | Description |
|:---------------|:---------------|:-----------------------|:------------|
| `id`           | entier ou chaîne de caractères | Oui | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `active`       | boolean        | Non | Limiter par statut actif. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url"https://gitlab.example.com/api/v4/groups/1/deploy_tokens"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "MyToken",
    "username": "gitlab+deploy-token-1",
    "expires_at": "2020-02-14T00:00:00.000Z",
    "revoked": false,
    "expired": false,
    "scopes": [
      "read_repository",
      "read_registry"
    ]
  }
]
```

### Récupérer un jeton de déploiement de groupe {#retrieve-a-group-deploy-token}

Récupérer le jeton de déploiement d'un groupe par son ID.

```plaintext
GET /groups/:id/deploy_tokens/:token_id
```

Paramètres :

| Attribut   | Type           | Obligatoire               | Description |
| ----------- | -------------- | ---------------------- | ----------- |
| `id`        | entier ou chaîne de caractères | Oui | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `token_id`  | integer        | Oui | ID du jeton de déploiement |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/deploy_tokens/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "name": "MyToken",
  "username": "gitlab+deploy-token-1",
  "expires_at": "2020-02-14T00:00:00.000Z",
  "revoked": false,
  "expired": false,
  "scopes": [
    "read_repository",
    "read_registry"
  ]
}
```

### Créer un jeton de déploiement de groupe {#create-a-group-deploy-token}

Créer un jeton de déploiement de groupe.

```plaintext
POST /groups/:id/deploy_tokens
```

Paramètres :

| Attribut    | Type | Obligatoire  | Description |
| ------------ | ---- | --------- | ----------- |
| `id`         | entier ou chaîne de caractères   | Oui | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `name`       | string           | Oui | Nom du nouveau jeton de déploiement |
| `scopes`     | tableau de chaînes de caractères | Oui | Indique les portées du jeton de déploiement. Doit être au moins l'une des valeurs suivantes : `read_repository`, `read_registry`, `write_registry`, `read_package_registry` ou `write_package_registry`. |
| `expires_at` | datetime         | Non | Date d'expiration du jeton de déploiement. N'expire pas si aucune valeur n'est fournie. Format ISO 8601 attendu (`2019-03-15T08:00:00Z`) |
| `username`   | string           | Non | Nom d'utilisateur du jeton de déploiement. La valeur par défaut est `gitlab+deploy-token-{n}` |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"name": "My deploy token", "expires_at": "2021-01-01", "username": "custom-user", "scopes": ["read_repository"]}' \
  --url "https://gitlab.example.com/api/v4/groups/5/deploy_tokens/"
```

Exemple de réponse :

```json
{
  "id": 1,
  "name": "My deploy token",
  "username": "custom-user",
  "expires_at": "2021-01-01T00:00:00.000Z",
  "token": "jMRvtPNxrn3crTAGukpZ",
  "revoked": false,
  "expired": false,
  "scopes": [
    "read_registry"
  ]
}
```

### Supprimer un jeton de déploiement de groupe {#delete-a-group-deploy-token}

Supprimer un jeton de déploiement du groupe.

```plaintext
DELETE /groups/:id/deploy_tokens/:token_id
```

Paramètres :

| Attribut   | Type           | Obligatoire               | Description |
| ----------- | -------------- | ---------------------- | ----------- |
| `id`        | entier ou chaîne de caractères | Oui | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `token_id`  | integer        | Oui | ID du jeton de déploiement |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/deploy_tokens/13"
```
