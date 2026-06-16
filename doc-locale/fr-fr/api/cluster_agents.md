---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API de l'agent Kubernetes"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- API des jetons d'agent [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/347046) dans GitLab 15.0.

{{< /history >}}

Utilisez cette API pour interagir avec l'[agent GitLab pour Kubernetes](../user/clusters/agent/_index.md).

## Lister tous les agents {#list-all-agents}

Liste tous les agents enregistrés pour le projet.

Vous devez disposer du rôle Developer, Maintainer ou Owner pour utiliser ce point de terminaison.

```plaintext
GET /projects/:id/cluster_agents
```

Paramètres :

| Attribut | Type              | Obligatoire  | Description                                                                                                     |
|-----------|-------------------|-----------|-----------------------------------------------------------------------------------------------------------------|
| `id`      | entier ou chaîne | oui       | ID ou [chemin encodé URL du projet](rest/_index.md#namespaced-paths) géré par l'utilisateur authentifié |

Réponse :

La réponse est une liste d'agents avec les champs suivants :

| Attribut                            | Type     | Description                                          |
|--------------------------------------|----------|------------------------------------------------------|
| `id`                                 | entier  | ID de l'agent                                      |
| `name`                               | string   | Nom de l'agent                                    |
| `config_project`                     | objet   | Objet représentant le projet auquel appartient l'agent |
| `config_project.id`                  | entier  | ID du projet                                    |
| `config_project.description`         | string   | Description du projet                           |
| `config_project.name`                | string   | Nom du projet                                  |
| `config_project.name_with_namespace` | string   | Nom complet avec l'espace de nommage du projet              |
| `config_project.path`                | string   | Chemin vers le projet                                  |
| `config_project.path_with_namespace` | string   | Chemin complet avec l'espace de nommage vers le projet              |
| `config_project.created_at`          | string   | Date et heure ISO8601 de création du projet        |
| `created_at`                         | string   | Date et heure ISO8601 de création de l'agent          |
| `created_by_user_id`                 | entier  | ID de l'utilisateur qui a créé l'agent                 |

Exemple de requête :

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "agent-1",
    "config_project": {
      "id": 20,
      "description": "",
      "name": "test",
      "name_with_namespace": "Administrator / test",
      "path": "test",
      "path_with_namespace": "root/test",
      "created_at": "2022-03-20T20:42:40.221Z"
    },
    "created_at": "2022-04-20T20:42:40.221Z",
    "created_by_user_id": 42
  },
  {
    "id": 2,
    "name": "agent-2",
    "config_project": {
      "id": 20,
      "description": "",
      "name": "test",
      "name_with_namespace": "Administrator / test",
      "path": "test",
      "path_with_namespace": "root/test",
      "created_at": "2022-03-20T20:42:40.221Z"
    },
    "created_at": "2022-04-20T20:42:40.221Z",
    "created_by_user_id": 42
  }
]
```

## Récupérer un agent {#retrieve-an-agent}

Récupère les détails d'un agent unique.

Vous devez disposer du rôle Developer, Maintainer ou Owner pour utiliser ce point de terminaison.

```plaintext
GET /projects/:id/cluster_agents/:agent_id
```

Paramètres :

| Attribut  | Type              | Obligatoire | Description                                                                                                     |
|------------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`       | entier ou chaîne | oui      | ID ou [chemin encodé URL du projet](rest/_index.md#namespaced-paths) géré par l'utilisateur authentifié |
| `agent_id` | entier           | oui      | ID de l'agent                                                                                                 |

Réponse :

La réponse est un agent unique avec les champs suivants :

| Attribut                            | Type    | Description                                          |
|--------------------------------------|---------|------------------------------------------------------|
| `id`                                 | entier | ID de l'agent                                      |
| `name`                               | string  | Nom de l'agent                                    |
| `config_project`                     | objet  | Objet représentant le projet auquel appartient l'agent |
| `config_project.id`                  | entier | ID du projet                                    |
| `config_project.description`         | string  | Description du projet                           |
| `config_project.name`                | string  | Nom du projet                                  |
| `config_project.name_with_namespace` | string  | Nom complet avec l'espace de nommage du projet              |
| `config_project.path`                | string  | Chemin vers le projet                                  |
| `config_project.path_with_namespace` | string  | Chemin complet avec l'espace de nommage vers le projet              |
| `config_project.created_at`          | string  | Date et heure ISO8601 de création du projet        |
| `created_at`                         | string  | Date et heure ISO8601 de création de l'agent          |
| `created_by_user_id`                 | entier | ID de l'utilisateur qui a créé l'agent                 |

Exemple de requête :

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "name": "agent-1",
  "config_project": {
    "id": 20,
    "description": "",
    "name": "test",
    "name_with_namespace": "Administrator / test",
    "path": "test",
    "path_with_namespace": "root/test",
    "created_at": "2022-03-20T20:42:40.221Z"
  },
  "created_at": "2022-04-20T20:42:40.221Z",
  "created_by_user_id": 42
}
```

## Créer un agent {#create-an-agent}

Crée un nouvel agent pour le projet.

Vous devez disposer du rôle Maintainer ou Owner pour utiliser ce point de terminaison.

```plaintext
POST /projects/:id/cluster_agents
```

Paramètres :

| Attribut | Type              | Obligatoire | Description                                                                                                     |
|-----------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`      | entier ou chaîne | oui      | ID ou [chemin encodé URL du projet](rest/_index.md#namespaced-paths) géré par l'utilisateur authentifié |
| `name`    | string            | oui      | Nom de l'agent                                                                                              |

Réponse :

La réponse est le nouvel agent avec les champs suivants :

| Attribut                            | Type    | Description                                          |
|--------------------------------------|---------|------------------------------------------------------|
| `id`                                 | entier | ID de l'agent                                      |
| `name`                               | string  | Nom de l'agent                                    |
| `config_project`                     | objet  | Objet représentant le projet auquel appartient l'agent |
| `config_project.id`                  | entier | ID du projet                                    |
| `config_project.description`         | string  | Description du projet                           |
| `config_project.name`                | string  | Nom du projet                                  |
| `config_project.name_with_namespace` | string  | Nom complet avec l'espace de nommage du projet              |
| `config_project.path`                | string  | Chemin vers le projet                                  |
| `config_project.path_with_namespace` | string  | Chemin complet avec l'espace de nommage vers le projet              |
| `config_project.created_at`          | string  | Date et heure ISO8601 de création du projet        |
| `created_at`                         | string  | Date et heure ISO8601 de création de l'agent          |
| `created_by_user_id`                 | entier | ID de l'utilisateur qui a créé l'agent                 |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents" \
  --data '{"name":"some-agent"}'
```

Exemple de réponse :

```json
{
  "id": 1,
  "name": "agent-1",
  "config_project": {
    "id": 20,
    "description": "",
    "name": "test",
    "name_with_namespace": "Administrator / test",
    "path": "test",
    "path_with_namespace": "root/test",
    "created_at": "2022-03-20T20:42:40.221Z"
  },
  "created_at": "2022-04-20T20:42:40.221Z",
  "created_by_user_id": 42
}
```

## Supprimer un agent {#delete-an-agent}

Supprime un enregistrement d'agent existant.

Vous devez disposer du rôle Maintainer ou Owner pour utiliser ce point de terminaison.

```plaintext
DELETE /projects/:id/cluster_agents/:agent_id
```

Paramètres :

| Attribut  | Type              | Obligatoire | Description                                                                                                     |
|------------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`       | entier ou chaîne | oui      | ID ou [chemin encodé URL du projet](rest/_index.md#namespaced-paths) géré par l'utilisateur authentifié |
| `agent_id` | entier           | oui      | ID de l'agent                                                                                                 |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/1"
```

## Lister tous les jetons d'agent {#list-all-agent-tokens}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/347046) dans GitLab 15.0.

{{< /history >}}

Liste tous les jetons actifs d'un agent.

Vous devez disposer du rôle Developer, Maintainer ou Owner pour utiliser ce point de terminaison.

```plaintext
GET /projects/:id/cluster_agents/:agent_id/tokens
```

Attributs pris en charge :

| Attribut  | Type              | Obligatoire  | Description                                                                                                      |
|------------|-------------------|-----------|------------------------------------------------------------------------------------------------------------------|
| `id`       | entier ou chaîne | oui       | ID ou [chemin encodé URL du projet](rest/_index.md#namespaced-paths) géré par l'utilisateur authentifié. |
| `agent_id` | entier ou chaîne | oui       | ID de l'agent.                                                                                                 |

Réponse :

La réponse est une liste de jetons avec les champs suivants :

| Attribut            | Type           | Description                                                       |
|----------------------|----------------|-------------------------------------------------------------------|
| `id`                 | entier        | ID du jeton.                                                  |
| `name`               | string         | Nom du jeton.                                                |
| `description`        | chaîne ou null | Description du jeton.                                         |
| `agent_id`           | entier        | ID de l'agent auquel appartient le jeton.                             |
| `status`             | string         | Le statut du jeton. Les valeurs valides sont `active` et `revoked`. |
| `created_at`         | string         | Date et heure ISO8601 de création du jeton.                      |
| `created_by_user_id` | string         | ID utilisateur de l'utilisateur qui a créé le jeton.                        |

Exemple de requête :

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/tokens"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "abcd",
    "description": "Some token",
    "agent_id": 5,
    "status": "active",
    "created_at": "2022-03-25T14:12:11.497Z",
    "created_by_user_id": 1
  },
  {
    "id": 2,
    "name": "foobar",
    "description": null,
    "agent_id": 5,
    "status": "active",
    "created_at": "2022-03-25T14:12:11.497Z",
    "created_by_user_id": 1
  }
]
```

> [!note]
> Le champ `last_used_at` d'un jeton n'est retourné que lors de la récupération d'un seul jeton d'agent.

## Récupérer un jeton d'agent {#retrieve-an-agent-token}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/347046) dans GitLab 15.0.

{{< /history >}}

Récupère un seul jeton d'agent.

Vous devez disposer du rôle Developer, Maintainer ou Owner pour utiliser ce point de terminaison.

Retourne un `404` si le jeton d'agent a été révoqué.

```plaintext
GET /projects/:id/cluster_agents/:agent_id/tokens/:token_id
```

Attributs pris en charge :

| Attribut  | Type              | Obligatoire | Description                                                                                                       |
|------------|-------------------|----------|-------------------------------------------------------------------------------------------------------------------|
| `id`       | entier ou chaîne | oui      | ID ou [chemin encodé URL du projet](rest/_index.md#namespaced-paths) géré par l'utilisateur authentifié.  |
| `agent_id` | entier           | oui      | ID de l'agent.                                                                                                  |
| `token_id` | entier           | oui      | ID du jeton.                                                                                                  |

Réponse :

La réponse est un seul jeton avec les champs suivants :

| Attribut            | Type           | Description                                                       |
|----------------------|----------------|-------------------------------------------------------------------|
| `id`                 | entier        | ID du jeton.                                                  |
| `name`               | string         | Nom du jeton.                                                |
| `description`        | chaîne ou null | Description du jeton.                                         |
| `agent_id`           | entier        | ID de l'agent auquel appartient le jeton.                             |
| `status`             | string         | Le statut du jeton. Les valeurs valides sont `active` et `revoked`. |
| `created_at`         | string         | Date et heure ISO8601 de création du jeton.                      |
| `created_by_user_id` | string         | ID utilisateur de l'utilisateur qui a créé le jeton.                        |
| `last_used_at`       | chaîne ou null | Date et heure ISO8601 de la dernière utilisation du jeton.                    |

Exemple de requête :

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/token/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "name": "abcd",
  "description": "Some token",
  "agent_id": 5,
  "status": "active",
  "created_at": "2022-03-25T14:12:11.497Z",
  "created_by_user_id": 1,
  "last_used_at": null
}
```

## Créer un jeton d'agent {#create-an-agent-token}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/347046) dans GitLab 15.0.
- La limite de deux jetons a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/361030/) dans GitLab 16.1 avec un [indicateur](../administration/feature_flags/_index.md) nommé `cluster_agents_limit_tokens_created`.
- La limite de deux jetons est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/412399) dans GitLab 16.2. L'indicateur de fonctionnalité `cluster_agents_limit_tokens_created` a été supprimé.

{{< /history >}}

Crée un nouveau jeton pour un agent.

Vous devez disposer du rôle Maintainer ou Owner pour utiliser ce point de terminaison.

Un agent ne peut avoir que deux jetons actifs à la fois.

```plaintext
POST /projects/:id/cluster_agents/:agent_id/tokens
```

Attributs pris en charge :

| Attribut     | Type              | Obligatoire | Description                                                                                                      |
|---------------|-------------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`          | entier ou chaîne | oui      | ID ou [chemin encodé URL du projet](rest/_index.md#namespaced-paths) géré par l'utilisateur authentifié. |
| `agent_id`    | entier           | oui      | ID de l'agent.                                                                                                 |
| `name`        | string            | oui      | Nom du jeton.                                                                                              |
| `description` | string            | non       | Description du jeton.                                                                                       |

Réponse :

La réponse est le nouveau jeton avec les champs suivants :

| Attribut            | Type           | Description                                                       |
|----------------------|----------------|-------------------------------------------------------------------|
| `id`                 | entier        | ID du jeton.                                                  |
| `name`               | string         | Nom du jeton.                                                |
| `description`        | chaîne ou null | Description du jeton.                                         |
| `agent_id`           | entier        | ID de l'agent auquel appartient le jeton.                             |
| `status`             | string         | Le statut du jeton. Les valeurs valides sont `active` et `revoked`. |
| `created_at`         | string         | Date et heure ISO8601 de création du jeton.                      |
| `created_by_user_id` | string         | ID utilisateur de l'utilisateur qui a créé le jeton.                        |
| `last_used_at`       | chaîne ou null | Date et heure ISO8601 de la dernière utilisation du jeton.                    |
| `token`              | string         | La valeur secrète du jeton.                                           |

> [!note]
> Le `token` n'est retourné que dans la réponse du point de terminaison `POST` et ne peut pas être récupéré ultérieurement.

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/tokens" \
  --data '{"name":"some-token"}'
```

Exemple de réponse :

```json
{
  "id": 1,
  "name": "abcd",
  "description": "Some token",
  "agent_id": 5,
  "status": "active",
  "created_at": "2022-03-25T14:12:11.497Z",
  "created_by_user_id": 1,
  "last_used_at": null,
  "token": "qeY8UVRisx9y3Loxo1scLxFuRxYcgeX3sxsdrpP_fR3Loq4xyg"
}
```

## Révoquer un jeton d'agent {#revoke-an-agent-token}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/347046) dans GitLab 15.0.

{{< /history >}}

Révoque un jeton d'agent.

Vous devez disposer du rôle Maintainer ou Owner pour utiliser ce point de terminaison.

```plaintext
DELETE /projects/:id/cluster_agents/:agent_id/tokens/:token_id
```

Attributs pris en charge :

| Attribut | Type | Requis | Description | |------------|-------------------|----------|---------------------------------------------------------------------------------------------------------------- -| | `id` | entier ou chaîne | oui | ID ou [chemin encodé URL du projet](rest/_index.md#namespaced-paths) géré par l'utilisateur authentifié. | | `agent_id` | entier | oui | ID de l'agent. | | `token_id` | entier | oui | ID du jeton. |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/tokens/1"
```

## Agents réceptifs {#receptive-agents}

{{< details >}}

- Édition : Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/12180) dans GitLab 17.4.

{{< /history >}}

Les [agents réceptifs](../user/clusters/agent/_index.md#receptive-agents) permettent à GitLab de s'intégrer aux clusters Kubernetes qui ne peuvent pas établir de connexion réseau avec l'instance GitLab, mais auxquels GitLab peut se connecter.

### Lister toutes les configurations d'URL {#list-all-url-configurations}

Liste toutes les configurations d'URL pour un agent spécifié.

Vous devez disposer du rôle Developer, Maintainer ou Owner pour utiliser ce point de terminaison.

```plaintext
GET /projects/:id/cluster_agents/:agent_id/url_configurations
```

Attributs pris en charge :

| Attribut  | Type              | Obligatoire  | Description                                                                                                           |
|------------|-------------------|-----------|-----------------------------------------------------------------------------------------------------------------------|
| `id`       | entier ou chaîne | oui       | ID ou [chemin encodé URL du projet](rest/_index.md#namespaced-paths) géré par l'utilisateur authentifié. |
| `agent_id` | entier ou chaîne | oui       | ID de l'agent.                                                                                                      |

Réponse :

La réponse est une liste de configurations d'URL avec les champs suivants :

| Attribut            | Type           | Description                                                                 |
|----------------------|----------------|-----------------------------------------------------------------------------|
| `id`                 | entier        | ID de la configuration d'URL.                                                |
| `agent_id`           | entier        | ID de l'agent auquel appartient la configuration d'URL.                           |
| `url`                | string         | URL pour cette configuration d'URL.                                             |
| `public_key`         | string         | (facultatif) Clé publique encodée en Base64 si l'authentification JWT est utilisée.         |
| `client_cert`        | string         | (facultatif) Certificat client au format PEM si l'authentification mTLS est utilisée. |
| `ca_cert`            | string         | (facultatif) Certificat CA au format PEM pour vérifier le point de terminaison de l'agent.       |
| `tls_host`           | string         | (facultatif) Nom d'hôte TLS pour vérifier le nom du serveur dans le point de terminaison de l'agent.       |

Exemple de requête :

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/url_configurations"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "agent_id": 5,
    "url": "grpcs://agent.example.com:4242",
    "public_key": "..."
  }
]
```

> [!note]
> Soit `public_key` soit `client_cert` est défini, mais jamais les deux.

### Récupérer une configuration d'URL {#retrieve-a-url-configuration}

Récupère une configuration d'URL d'agent unique.

Vous devez disposer du rôle Developer, Maintainer ou Owner pour utiliser ce point de terminaison.

```plaintext
GET /projects/:id/cluster_agents/:agent_id/url_configurations/:url_configuration_id
```

Attributs pris en charge :

| Attribut              | Type              | Obligatoire | Description                                                                                                            |
|------------------------|-------------------|----------|------------------------------------------------------------------------------------------------------------------------|
| `id`                   | entier ou chaîne | oui      | ID ou [chemin encodé URL du projet](rest/_index.md#namespaced-paths) géré par l'utilisateur authentifié.  |
| `agent_id`             | entier           | oui      | ID de l'agent.                                                                                                       |
| `url_configuration_id` | entier           | oui      | ID de la configuration d'URL.                                                                                           |

Réponse :

La réponse est une configuration d'URL unique avec les champs suivants :

| Attribut            | Type           | Description                                                                 |
|----------------------|----------------|-----------------------------------------------------------------------------|
| `id`                 | entier        | ID de la configuration d'URL.                                                |
| `agent_id`           | entier        | ID de l'agent auquel appartient la configuration d'URL.                           |
| `url`                | string         | URL de l'agent pour cette configuration d'URL.                                             |
| `public_key`         | string         | (facultatif) Clé publique encodée en Base64 si l'authentification JWT est utilisée.         |
| `client_cert`        | string         | (facultatif) Certificat client au format PEM si l'authentification mTLS est utilisée. |
| `ca_cert`            | string         | (facultatif) Certificat CA au format PEM pour vérifier le point de terminaison de l'agent.       |
| `tls_host`           | string         | (facultatif) Nom d'hôte TLS pour vérifier le nom du serveur dans le point de terminaison de l'agent.       |

Exemple de requête :

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/url_configurations/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "agent_id": 5,
  "url": "grpcs://agent.example.com:4242",
  "public_key": "..."
}
```

> [!note]
> Soit `public_key` soit `client_cert` est défini, mais jamais les deux.

### Créer une configuration d'URL {#create-a-url-configuration}

Crée une nouvelle configuration d'URL pour un agent.

Vous devez disposer du rôle Maintainer ou Owner pour utiliser ce point de terminaison.

Un agent ne peut avoir qu'une seule configuration d'URL à la fois.

```plaintext
POST /projects/:id/cluster_agents/:agent_id/url_configurations
```

Attributs pris en charge :

| Attribut     | Type              | Obligatoire | Description                                                                                                           |
|---------------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------------|
| `id`          | entier ou chaîne | oui      | ID ou [chemin encodé URL du projet](rest/_index.md#namespaced-paths) géré par l'utilisateur authentifié. |
| `agent_id`    | entier           | oui      | ID de l'agent.                                                                                                      |
| `url`         | string            | oui      | URL de l'agent pour cette configuration d'URL.                                                                                 |
| `client_cert` | string            | non       | Certificat client au format PEM si l'authentification mTLS doit être utilisée. Doit être fourni avec `client_key`.           |
| `client_key`  | string            | non       | Clé client au format PEM si l'authentification mTLS doit être utilisée. Doit être fourni avec `client_cert`.                  |
| `ca_cert`     | string            | non       | Certificat CA au format PEM pour vérifier le point de terminaison de l'agent.                                                            |
| `tls_host`    | string            | non       | Nom d'hôte TLS pour vérifier le nom du serveur dans le point de terminaison de l'agent.                                                            |

Réponse :

La réponse est la nouvelle configuration d'URL avec les champs suivants :

| Attribut            | Type           | Description                                                                 |
|----------------------|----------------|-----------------------------------------------------------------------------|
| `id`                 | entier        | ID de la configuration d'URL.                                                |
| `agent_id`           | entier        | ID de l'agent auquel appartient la configuration d'URL.                           |
| `url`                | string         | URL de l'agent pour cette configuration d'URL.                                             |
| `public_key`         | string         | (facultatif) Clé publique encodée en Base64 si l'authentification JWT est utilisée.         |
| `client_cert`        | string         | (facultatif) Certificat client au format PEM si l'authentification mTLS est utilisée. |
| `ca_cert`            | string         | (facultatif) Certificat CA au format PEM pour vérifier le point de terminaison de l'agent.       |
| `tls_host`           | string         | (facultatif) Nom d'hôte TLS pour vérifier le nom du serveur dans le point de terminaison de l'agent.       |

Exemple de requête pour créer une configuration d'URL avec un jeton JWT :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/url_configurations" \
  --data '{"url":"grpcs://agent.example.com:4242"}'
```

Exemple de réponse pour l'authentification JWT :

```json
{
  "id": 1,
  "agent_id": 5,
  "url": "grpcs://agent.example.com:4242",
  "public_key": "..."
}
```

Exemple de requête pour créer une configuration d'URL avec mTLS à l'aide d'un certificat client et d'une clé provenant des fichiers `client.pem` et `client-key.pem` :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/url_configurations" \
  --data '{"url":"grpcs://agent.example.com:4242", \
           "client_cert":"'"$(awk -v ORS='\\n' '1' client.pem)"'", \
           "client_key":"'"$(awk -v ORS='\\n' '1' client-key.pem)"'"}'
```

Exemple de réponse pour mTLS :

```json
{
  "id": 1,
  "agent_id": 5,
  "url": "grpcs://agent.example.com:4242",
  "client_cert": "..."
}
```

> [!note]
> Si `client_cert` et `client_key` ne sont pas fournis, une paire de clés privée-publique est générée et l'authentification JWT est utilisée à la place de mTLS.

### Supprimer une configuration d'URL {#delete-a-url-configuration}

Supprime une configuration d'URL d'agent.

Vous devez disposer du rôle Maintainer ou Owner pour utiliser ce point de terminaison.

```plaintext
DELETE /projects/:id/cluster_agents/:agent_id/url_configurations/:url_configuration_id
```

Attributs pris en charge :

| Attribut              | Type              | Obligatoire | Description                                                                                                           |
|------------------------|-------------------|----------|-----------------------------------------------------------------------------------------------------------------------|
| `id`                   | entier ou chaîne | oui      | ID ou [chemin encodé URL du projet](rest/_index.md#namespaced-paths) géré par l'utilisateur authentifié. |
| `agent_id`             | entier           | oui      | ID de l'agent.                                                                                                      |
| `url_configuration_id` | entier           | oui      | ID de la configuration d'URL.                                                                                          |

Exemple de requête :

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/20/cluster_agents/5/url_configurations/1
```
