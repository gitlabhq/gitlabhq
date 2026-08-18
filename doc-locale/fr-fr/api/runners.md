---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Runners
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [runners](../ci/runners/_index.md) enregistrés dans une instance.

Pour créer un nouveau runner d'instance, de groupe ou de projet, utilisez l'endpoint [`POST /user/runners`](users.md#create-a-runner-linked-to-a-user). Utilisez cette API pour gérer les runners existants.

La [pagination](rest/_index.md#pagination) est disponible sur les endpoints d'API suivants (ils renvoient 20 éléments par défaut) :

```plaintext
GET /runners
GET /runners/all
GET /runners/:id/jobs
GET /projects/:id/runners
GET /groups/:id/runners
```

## Jetons d'enregistrement et d'authentification {#registration-and-authentication-tokens}

Pour connecter un runner à GitLab, vous avez besoin de deux jetons.

| Jeton | Description |
| ----- | ----------- |
| Jeton d'enregistrement (hérité) | Jeton utilisé pour [enregistrer le runner](https://docs.gitlab.com/runner/register/). Il peut être [obtenu via GitLab](../ci/runners/_index.md). |
| Jeton d'authentification | Jeton utilisé pour authentifier le runner auprès de l'instance GitLab. Le jeton est obtenu automatiquement lorsque vous [enregistrez un runner](https://docs.gitlab.com/runner/register/) ou via l'API Runners lorsque vous [enregistrez manuellement un runner](#create-a-runner) ou [réinitialisez le jeton d'authentification](#reset-runners-authentication-token-by-using-the-runner-id). Vous pouvez également obtenir le jeton en utilisant l'endpoint [`POST /user/runners`](users.md#create-a-runner-linked-to-a-user). |

Voici un exemple illustrant comment utiliser les jetons pour l'enregistrement d'un runner :

1. Enregistrez le runner en utilisant l'API GitLab avec un jeton d'enregistrement pour recevoir un jeton d'authentification.
1. Ajoutez le jeton d'authentification au [fichier de configuration du runner](https://docs.gitlab.com/runner/commands/#configuration-file) :

   ```toml
   [[runners]]
     token = "<authentication_token>"
   ```

GitLab et le runner sont alors connectés.

## Lister tous les runners disponibles {#list-all-available-runners}

Liste tous les runners disponibles pour l'utilisateur.

Prérequis :

- Pour les runners de groupe, vous devez avoir le rôle Owner dans l'espace de nommage propriétaire.
- Pour les runners de projet, vous devez avoir le rôle Responsable sécurité, Maintainer ou Owner dans un projet assigné au runner.

```plaintext
GET /runners
GET /runners?scope=active
GET /runners?type=project_type
GET /runners?status=online
GET /runners?paused=true
GET /runners?tag_list=tag1,tag2
```

| Attribut        | Type         | Obligatoire | Description |
|------------------|--------------|----------|-------------|
| `scope`          | string       | non       | Déprécié : Utilisez `type` ou `status` à la place. La portée des runners à retourner, parmi : `active`, `paused`, `online` et `offline` ; affiche tous les runners si aucune valeur n'est fournie |
| `type`           | string       | non       | Le type de runners à retourner, parmi : `instance_type`, `group_type`, `project_type` |
| `status`         | string       | non       | Le statut des runners à retourner, parmi : `online`, `offline`, `stale`, ou `never_contacted`.<br/>Les autres valeurs possibles sont les valeurs obsolètes `active` et `paused`.<br/>La demande de runners `offline` peut également retourner des runners `stale` car `stale` est inclus dans `offline`. |
| `paused`         | boolean      | non       | Indique s'il faut inclure uniquement les runners qui acceptent ou ignorent les nouveaux jobs |
| `tag_list`       | tableau de chaînes | non       | Une liste de tags de runner |
| `version_prefix` | string       | non       | Le préfixe de la version des runners à retourner. Par exemple, `15.0`, `14`, `16.1.241` |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runners"
```

> [!warning]
> Obsolescences :
>
> - Les valeurs `active` et `paused` du paramètre de requête `status` sont obsolètes et leur suppression est planifiée dans [une future version de l'API REST](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). Utilisez le paramètre de requête `paused` à la place.
> - L'attribut `active` dans la réponse est obsolète et sa suppression est planifiée dans [une future version de l'API REST](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). Utilisez l'attribut `paused` à la place.
> - L'attribut `ip_address` dans la réponse est obsolète [dans GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159) et sa suppression est planifiée dans [une future version de l'API REST](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). Dans GitLab 17.0, cet attribut renvoie une chaîne vide. L'attribut `ipAddress` peut être trouvé dans le gestionnaire de runner correspondant. Il est uniquement disponible via le type GraphQL [`CiRunnerManager`](graphql/reference/_index.md#cirunnermanager).

Exemple de réponse :

```json
[
    {
        "active": true,
        "paused": false,
        "description": "test-1-20150125",
        "id": 6,
        "ip_address": "",
        "is_shared": false,
        "runner_type": "project_type",
        "name": null,
        "online": true,
        "status": "online",
        "job_execution_status": "idle"
    },
    {
        "active": true,
        "paused": false,
        "description": "test-2-20150125",
        "id": 8,
        "ip_address": "",
        "is_shared": false,
        "runner_type": "group_type",
        "name": null,
        "online": false,
        "status": "offline",
        "job_execution_status": "idle"
    }
]
```

## Lister tous les runners {#list-all-runners}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Liste tous les runners dans l'instance GitLab (projet et partagés).

Prérequis :

- Vous devez disposer d'un accès administrateur ou d'un accès auditeur.

```plaintext
GET /runners/all
GET /runners/all?scope=online
GET /runners/all?type=project_type
GET /runners/all?status=online
GET /runners/all?paused=true
GET /runners/all?tag_list=tag1,tag2
```

| Attribut        | Type         | Obligatoire | Description |
|------------------|--------------|----------|-------------|
| `scope`          | string       | non       | Déprécié : Utilisez `type` ou `status` à la place. La portée des runners à retourner, parmi : `specific`, `shared`, `active`, `paused`, `online` et `offline` ; affiche tous les runners si aucune valeur n'est fournie |
| `type`           | string       | non       | Le type de runners à retourner, parmi : `instance_type`, `group_type`, `project_type` |
| `status`         | string       | non       | Le statut des runners à retourner, parmi : `online`, `offline`, `stale`, ou `never_contacted`.<br/>Les autres valeurs possibles sont les valeurs obsolètes `active` et `paused`.<br/>La demande de runners `offline` peut également retourner des runners `stale` car `stale` est inclus dans `offline`. |
| `paused`         | boolean      | non       | Indique s'il faut inclure uniquement les runners qui acceptent ou ignorent les nouveaux jobs |
| `tag_list`       | tableau de chaînes | non       | Une liste de tags de runner |
| `version_prefix` | string       | non       | Le préfixe de la version des runners à retourner. Par exemple, `15.0`, `16.1.241` |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runners/all"
```

> [!warning]
> Obsolescences :
>
> - Les valeurs `active` et `paused` du paramètre de requête `status` sont obsolètes et leur suppression est planifiée dans [une future version de l'API REST](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). Utilisez le paramètre de requête `paused` à la place.
> - L'attribut `active` dans la réponse est obsolète et sa suppression est planifiée dans [une future version de l'API REST](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). Utilisez l'attribut `paused` à la place.
> - L'attribut `ip_address` dans la réponse est obsolète [dans GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159) et sa suppression est planifiée dans [une future version de l'API REST](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). Dans GitLab 17.0, cet attribut renvoie une chaîne vide. L'attribut `ipAddress` peut être trouvé dans le gestionnaire de runner correspondant. Il est uniquement disponible via le type GraphQL [`CiRunnerManager`](graphql/reference/_index.md#cirunnermanager).

Exemple de réponse :

```json
[
    {
        "active": true,
        "paused": false,
        "description": "shared-runner-1",
        "id": 1,
        "ip_address": "",
        "is_shared": true,
        "runner_type": "instance_type",
        "name": null,
        "online": true,
        "status": "online",
        "job_execution_status": "idle"
    },
    {
        "active": true,
        "paused": false,
        "description": "shared-runner-2",
        "id": 3,
        "ip_address": "",
        "is_shared": true,
        "runner_type": "instance_type",
        "name": null,
        "online": false,
        "status": "offline",
        "job_execution_status": "idle"
    },
    {
        "active": true,
        "paused": false,
        "description": "test-1-20150125",
        "id": 6,
        "ip_address": "",
        "is_shared": false,
        "runner_type": "project_type",
        "name": null,
        "online": true,
        "status": "paused",
        "job_execution_status": "idle"
    },
    {
        "active": true,
        "paused": false,
        "description": "test-2-20150125",
        "id": 8,
        "ip_address": "",
        "is_shared": false,
        "runner_type": "group_type",
        "name": null,
        "online": false,
        "status": "offline",
        "job_execution_status": "idle"
    }
]
```

Pour afficher plus de 20 runners, utilisez la [pagination](rest/_index.md#pagination).

## Récupérer les détails d'un runner {#retrieve-runners-details}

Récupère les détails d'un runner.

Les détails des runners d'instance sont disponibles pour tous les utilisateurs authentifiés via cet endpoint.

Prérequis :

- Accès utilisateur : Vous devez disposer de l'un des éléments suivants :
  - Pour les runners de groupe : Le rôle Maintainer ou Owner dans l'espace de nommage propriétaire.
  - Pour les runners de projet : Le rôle Responsable sécurité, Maintainer ou Owner dans le projet qui possède le runner.
  - Un rôle personnalisé avec la permission `admin_runners` dans le groupe ou le projet concerné.
- Un jeton d'accès avec la portée `manage_runner` et le rôle approprié.

```plaintext
GET /runners/:id
```

| Attribut | Type    | Obligatoire | Description |
|-----------|---------|----------|-------------|
| `id`      | integer | oui      | L'identifiant d'un runner |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runners/6"
```

> [!warning]
> Obsolescences :
>
> - L'attribut `active` dans la réponse est obsolète et sa suppression est planifiée dans [une future version de l'API REST](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). Utilisez l'attribut `paused` à la place.
> - L'attribut `ip_address` dans la réponse est obsolète [dans GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159) et sa suppression est planifiée dans [une future version de l'API REST](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). Dans GitLab 17.0, cet attribut renvoie une chaîne vide. L'attribut `ipAddress` peut être trouvé dans le gestionnaire de runner correspondant. Il est uniquement disponible via le type GraphQL [`CiRunnerManager`](graphql/reference/_index.md#cirunnermanager).
> - Les attributs `version`, `revision`, `platform` et `architecture` dans la réponse sont obsolètes [dans GitLab 17.0](https://gitlab.com/gitlab-org/gitlab/-/issues/457128) et leur suppression est planifiée dans [une future version de l'API REST](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). Les mêmes attributs peuvent être trouvés dans le gestionnaire de runner correspondant. Il est uniquement disponible via le type GraphQL [`CiRunnerManager`](graphql/reference/_index.md#cirunnermanager).

Exemple de réponse :

```json
{
    "active": true,
    "paused": false,
    "architecture": null,
    "description": "test-1-20150125",
    "id": 6,
    "ip_address": "",
    "is_shared": false,
    "runner_type": "project_type",
    "contacted_at": "2016-01-25T16:39:48.066Z",
    "maintenance_note": null,
    "name": null,
    "online": true,
    "status": "online",
    "job_execution_status": "idle",
    "platform": null,
    "projects": [
        {
            "id": 1,
            "name": "GitLab Community Edition",
            "name_with_namespace": "GitLab.org / GitLab Community Edition",
            "path": "gitlab-foss",
            "path_with_namespace": "gitlab-org/gitlab-foss"
        }
    ],
    "revision": null,
    "tag_list": [
        "ruby",
        "mysql"
    ],
    "version": null,
    "access_level": "ref_protected",
    "maximum_timeout": 3600
}
```

## Mettre à jour les détails d'un runner {#update-runners-details}

Met à jour les détails d'un runner.

```plaintext
PUT /runners/:id
```

Prérequis :

- Accès utilisateur : Vous devez disposer de l'un des éléments suivants :
  - Pour les runners d'instance : Accès administrateur à l'instance GitLab.
  - Pour les runners de groupe : Rôle Owner dans l'espace de nommage propriétaire.
  - Pour les runners de projet : Le rôle Maintainer ou Owner dans un projet assigné au runner.
  - Un rôle personnalisé avec la permission `admin_runners` dans le groupe ou le projet concerné.
- Un jeton d'accès avec la portée `manage_runner` et le rôle approprié.

| Attribut          | Type    | Obligatoire | Description |
|--------------------|---------|----------|-------------|
| `id`               | integer | oui      | L'identifiant d'un runner |
| `description`      | string  | non       | La description du runner |
| `active`           | boolean | non       | Déprécié : Utilisez plutôt `paused`. Indicateur signalant si le runner est autorisé à recevoir des jobs |
| `paused`           | boolean | non       | Indique si le runner doit ignorer les nouveaux jobs |
| `tag_list`         | array   | non       | La liste des tags du runner |
| `run_untagged`     | boolean | non       | Indique si le runner peut exécuter des jobs sans tag |
| `locked`           | boolean | non       | Indique si le runner est verrouillé |
| `access_level`     | string  | non       | Le niveau d'accès du runner ; `not_protected` ou `ref_protected` |
| `maximum_timeout`  | integer | non       | Délai d'expiration maximal qui limite la durée (en secondes) pendant laquelle les runners peuvent exécuter des jobs |
| `maintenance_note` | string  | non       | Notes de maintenance en texte libre pour le runner (1024 caractères) |

```shell
curl --request PUT \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runners/6" \
     --form "description=test-1-20150125-test" \
     --form "tag_list=ruby,mysql,tag1,tag2"
```

> [!warning]
> Obsolescences :
>
> - Le paramètre de requête `active` est obsolète et sa suppression est planifiée dans [une future version de l'API REST](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). Utilisez l'attribut `paused` à la place.
> - L'attribut `ip_address` dans la réponse est obsolète [dans GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159) et sa suppression est planifiée dans [une future version de l'API REST](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). Dans GitLab 17.0, cet attribut renvoie une chaîne vide. L'attribut `ipAddress` peut être trouvé dans le gestionnaire de runner correspondant. Il est uniquement disponible via le type GraphQL [`CiRunnerManager`](graphql/reference/_index.md#cirunnermanager).

Exemple de réponse :

```json
{
    "active": true,
    "architecture": null,
    "description": "test-1-20150125-test",
    "id": 6,
    "ip_address": "",
    "is_shared": false,
    "runner_type": "group_type",
    "contacted_at": "2016-01-25T16:39:48.066Z",
    "maintenance_note": null,
    "name": null,
    "online": true,
    "status": "online",
    "job_execution_status": "idle",
    "platform": null,
    "projects": [
        {
            "id": 1,
            "name": "GitLab Community Edition",
            "name_with_namespace": "GitLab.org / GitLab Community Edition",
            "path": "gitlab-foss",
            "path_with_namespace": "gitlab-org/gitlab-foss"
        }
    ],
    "revision": null,
    "tag_list": [
        "ruby",
        "mysql",
        "tag1",
        "tag2"
    ],
    "version": null,
    "access_level": "ref_protected",
    "maximum_timeout": null
}
```

### Mettre en pause un runner {#pause-a-runner}

Mettre en pause un runner.

Prérequis :

- Accès utilisateur : Vous devez disposer de l'un des éléments suivants :
  - Pour les runners d'instance : Accès administrateur à l'instance GitLab.
  - Pour les runners de groupe : Rôle Owner dans l'espace de nommage propriétaire.
  - Pour les runners de projet : Le rôle Maintainer ou Owner dans un projet assigné au runner.
  - Un rôle personnalisé avec la permission `admin_runners` dans le groupe ou le projet concerné.
- Un jeton d'accès avec la portée `manage_runner` et le rôle approprié.

```plaintext
PUT --form "paused=true" /runners/:runner_id

# --or--

# Deprecated: removal planned in 16.0
PUT --form "active=false" /runners/:runner_id
```

| Attribut   | Type    | Obligatoire | Description |
|-------------|---------|----------|-------------|
| `runner_id` | integer | oui      | L'identifiant d'un runner |

```shell
curl --request PUT \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "paused=true"  \
     --url "https://gitlab.example.com/api/v4/runners/6"

# --or--

# Deprecated: removal planned in 16.0
curl --request PUT \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "active=false"  \
     --url "https://gitlab.example.com/api/v4/runners/6"
```

> [!warning]
> L'attribut de formulaire `active` est obsolète et sa suppression est planifiée dans [une future version de l'API REST](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). Utilisez l'attribut `paused` à la place.

## Lister tous les jobs traités par un runner {#list-all-jobs-processed-by-a-runner}

Liste tous les jobs en cours de traitement ou traités par le runner spécifié. La liste des jobs est limitée aux projets dans lesquels l'utilisateur a le rôle Reporter, Developer, Maintainer ou Owner.

```plaintext
GET /runners/:id/jobs
```

| Attribut   | Type    | Obligatoire | Description |
|-------------|---------|----------|-------------|
| `id`        | integer | oui      | L'identifiant d'un runner |
| `system_id` | string  | non       | Identifiant système de la machine sur laquelle le gestionnaire de runner s'exécute |
| `status`    | string  | non       | Statut du job ; parmi : `running`, `success`, `failed`, `canceled` |
| `order_by`  | string  | non       | Trier les jobs par `id` |
| `sort`      | string  | non       | Trier les jobs dans l'ordre `asc` ou `desc` (par défaut : `desc`). Si `sort` est spécifié, `order_by` doit également être spécifié |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runners/1/jobs?status=running"
```

Exemple de réponse :

```json
[
    {
        "id": 2,
        "status": "running",
        "stage": "test",
        "name": "test",
        "ref": "main",
        "tag": false,
        "coverage": null,
        "created_at": "2017-11-16T08:50:29.000Z",
        "started_at": "2017-11-16T08:51:29.000Z",
        "finished_at": "2017-11-16T08:53:29.000Z",
        "duration": 120,
        "queued_duration": 2,
        "user": {
            "id": 1,
            "name": "John Doe2",
            "username": "user2",
            "state": "active",
            "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
            "web_url": "http://localhost/user2",
            "created_at": "2017-11-16T18:38:46.000Z",
            "bio": null,
            "location": null,
            "public_email": "",
            "linkedin": "",
            "twitter": "",
            "website_url": "",
            "organization": null
        },
        "commit": {
            "id": "97de212e80737a608d939f648d959671fb0a0142",
            "short_id": "97de212e",
            "title": "Update configuration\r",
            "created_at": "2017-11-16T08:50:28.000Z",
            "parent_ids": [
                "1b12f15a11fc6e62177bef08f47bc7b5ce50b141",
                "498214de67004b1da3d820901307bed2a68a8ef6"
            ],
            "message": "See merge request !123",
            "author_name": "John Doe2",
            "author_email": "user2@example.org",
            "authored_date": "2017-11-16T08:50:27.000Z",
            "committer_name": "John Doe2",
            "committer_email": "user2@example.org",
            "committed_date": "2017-11-16T08:50:27.000Z"
        },
        "pipeline": {
            "id": 2,
            "sha": "97de212e80737a608d939f648d959671fb0a0142",
            "ref": "main",
            "status": "running"
        },
        "project": {
            "id": 1,
            "description": null,
            "name": "project1",
            "name_with_namespace": "John Doe2 / project1",
            "path": "project1",
            "path_with_namespace": "namespace1/project1",
            "created_at": "2017-11-16T18:38:46.620Z"
        }
    }
]
```

## Lister tous les gestionnaires d'un runner {#list-all-runners-managers}

Liste tous les gestionnaires d'un runner.

```plaintext
GET /runners/:id/managers
```

| Attribut | Type    | Obligatoire | Description |
|-----------|---------|----------|-------------|
| `id`      | integer | oui      | L'identifiant d'un runner |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runners/1/managers"
```

Exemple de réponse :

```json
[
    {
      "id": 1,
      "system_id": "s_89e5e9956577",
      "version": "16.11.1",
      "revision": "535ced5f",
      "platform": "linux",
      "architecture": "amd64",
      "created_at": "2024-06-09T11:12:02.507Z",
      "contacted_at": "2024-06-09T06:30:09.355Z",
      "ip_address": "127.0.0.1",
      "status": "offline",
      "job_execution_status": "idle"
    },
    {
      "id": 2,
      "system_id": "runner-2",
      "version": "16.11.0",
      "revision": "91a27b2a",
      "platform": "linux",
      "architecture": "amd64",
      "created_at": "2024-06-09T09:12:02.507Z",
      "contacted_at": "2024-06-09T06:30:09.355Z",
      "ip_address": "127.0.0.1",
      "status": "offline",
      "job_execution_status": "idle"
    }
]
```

## Lister tous les runners d'un projet {#list-all-of-a-projects-runners}

Liste tous les runners disponibles dans le projet, y compris ceux des groupes ancêtres et [tous les runners d'instance autorisés](../ci/runners/runners_scope.md#enable-instance-runners-for-a-project).

Prérequis :

- Vous devez être administrateur de l'instance GitLab ou disposer au minimum du rôle Maintainer ou Auditor pour le projet cible.

```plaintext
GET /projects/:id/runners
GET /projects/:id/runners?scope=active
GET /projects/:id/runners?type=project_type
GET /projects/:id/runners?status=online
GET /projects/:id/runners?paused=true
GET /projects/:id/runners?tag_list=tag1,tag2
```

| Attribut        | Type           | Obligatoire | Description |
|------------------|----------------|----------|-------------|
| `id`             | entier ou chaîne de caractères | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `scope`          | string         | non       | Déprécié : Utilisez `type` ou `status` à la place. La portée des runners à retourner, parmi : `active`, `paused`, `online` et `offline` ; affiche tous les runners si aucune valeur n'est fournie |
| `type`           | string         | non       | Le type de runners à retourner, parmi : `instance_type`, `group_type`, `project_type` |
| `status`         | string         | non       | Le statut des runners à retourner, parmi : `online`, `offline`, `stale`, ou `never_contacted`.<br/>Les autres valeurs possibles sont les valeurs obsolètes `active` et `paused`.<br/>La demande de runners `offline` peut également retourner des runners `stale` car `stale` est inclus dans `offline`. |
| `paused`         | boolean        | non       | Indique s'il faut inclure uniquement les runners qui acceptent ou ignorent les nouveaux jobs |
| `tag_list`       | tableau de chaînes   | non       | Une liste de tags de runner |
| `version_prefix` | string         | non       | Le préfixe de la version des runners à retourner. Par exemple, `15.0`, `14`, `16.1.241` |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/runners"
```

> [!warning]
> Obsolescences :
>
> - Les valeurs `active` et `paused` du paramètre de requête `status` sont obsolètes et leur suppression est planifiée dans [une future version de l'API REST](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). Utilisez le paramètre de requête `paused` à la place.
> - L'attribut `active` dans la réponse est obsolète et sa suppression est planifiée dans [une future version de l'API REST](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). Utilisez l'attribut `paused` à la place.
> - L'attribut `ip_address` dans la réponse est obsolète [dans GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159) et sa suppression est planifiée dans [une future version de l'API REST](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). Dans GitLab 17.0, cet attribut renvoie une chaîne vide dans GitLab 17.0. L'attribut `ipAddress` peut être trouvé dans le gestionnaire de runner correspondant. Il est uniquement disponible via le type GraphQL [`CiRunnerManager`](graphql/reference/_index.md#cirunnermanager).

Exemple de réponse :

```json
[
    {
        "active": true,
        "paused": false,
        "description": "test-2-20150125",
        "id": 8,
        "ip_address": "",
        "is_shared": false,
        "runner_type": "project_type",
        "name": null,
        "online": false,
        "status": "offline",
        "job_execution_status": "idle"
    },
    {
        "active": true,
        "paused": false,
        "description": "development_runner",
        "id": 5,
        "ip_address": "",
        "is_shared": true,
        "runner_type": "instance_type",
        "name": null,
        "online": true,
        "status": "online",
        "job_execution_status": "idle"
    }
]
```

## Assigner un runner à un projet {#assign-a-runner-to-project}

Assigner un runner de projet disponible au projet.

Prérequis :

- Accès utilisateur : Vous devez disposer de l'un des éléments suivants :

  - Le rôle Maintainer ou Owner pour le projet qui possède le runner et le projet cible.
  - Un rôle personnalisé avec la permission `admin_runners` dans le groupe ou le projet concerné.

```plaintext
POST /projects/:id/runners
```

| Attribut   | Type           | Obligatoire | Description |
|-------------|----------------|----------|-------------|
| `id`        | entier ou chaîne de caractères | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `runner_id` | integer        | oui      | L'identifiant d'un runner |

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/runners" \
     --form "runner_id=9"
```

> [!warning]
> L'attribut `ip_address` dans la réponse est obsolète [dans GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159) et sa suppression est planifiée dans [une future version de l'API REST](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). Dans GitLab 17.0, cet attribut renvoie une chaîne vide. L'attribut `ipAddress` peut être trouvé dans le gestionnaire de runner correspondant. Il est uniquement disponible via le type GraphQL [`CiRunnerManager`](graphql/reference/_index.md#cirunnermanager).

Exemple de réponse :

```json
{
    "active": true,
    "description": "test-2016-02-01",
    "id": 9,
    "ip_address": "",
    "is_shared": false,
    "runner_type": "project_type",
    "name": null,
    "online": true,
    "status": "online",
    "job_execution_status": "idle"
}
```

## Désassigner un runner d'un projet {#unassign-a-runner-from-project}

Désassigner un runner de projet du projet. Vous ne pouvez pas désassigner un runner du projet propriétaire. Si vous tentez cette action, une erreur se produit. Utilisez l'appel pour [supprimer un runner](#delete-a-runner) à la place.

Prérequis :

- Vous ne devez pas verrouiller le runner, sauf si vous êtes administrateur.
- Accès utilisateur : Vous devez disposer de l'un des éléments suivants :
  - Le rôle Maintainer ou Owner dans le projet que vous souhaitez désassigner.
  - Un rôle personnalisé avec la permission `admin_runners` dans le groupe ou le projet concerné.
- Un jeton d'accès avec la portée `manage_runner` et le rôle approprié.

```plaintext
DELETE /projects/:id/runners/:runner_id
```

| Attribut   | Type           | Obligatoire | Description |
|-------------|----------------|----------|-------------|
| `id`        | entier ou chaîne de caractères | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `runner_id` | integer        | oui      | L'identifiant d'un runner |

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/runners/9"
```

## Lister tous les runners d'un groupe {#list-all-of-a-groups-runners}

Liste tous les runners disponibles dans le groupe et ses groupes ancêtres, y compris [tous les runners d'instance autorisés](../ci/runners/runners_scope.md#enable-instance-runners-for-a-group).

Prérequis :

- Accès utilisateur : Vous devez disposer de l'un des éléments suivants :
  - Accès administrateur à l'instance GitLab.
  - Rôle Owner ou Auditor dans le groupe.
  - Un rôle personnalisé avec la permission `admin_runners` dans le groupe.
- Un jeton d'accès avec la portée `manage_runner` et le rôle approprié.

```plaintext
GET /groups/:id/runners
GET /groups/:id/runners?type=group_type
GET /groups/:id/runners/all?status=online
GET /groups/:id/runners/all?paused=true
GET /groups/:id/runners?tag_list=tag1,tag2
```

| Attribut        | Type         | Obligatoire | Description |
|------------------|--------------|----------|-------------|
| `id`             | integer      | oui      | L'identifiant du groupe |
| `type`           | string       | non       | Le type de runners à retourner, parmi : `instance_type`, `group_type`, `project_type`. La valeur `project_type` est [obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/351466) et sa suppression est planifiée dans GitLab 15.0 |
| `status`         | string       | non       | Le statut des runners à retourner, parmi : `online`, `offline`, `stale`, ou `never_contacted`.<br/>Les autres valeurs possibles sont les valeurs obsolètes `active` et `paused`.<br/>La demande de runners `offline` peut également retourner des runners `stale` car `stale` est inclus dans `offline`. |
| `paused`         | boolean      | non       | Indique s'il faut inclure uniquement les runners qui acceptent ou ignorent les nouveaux jobs |
| `tag_list`       | tableau de chaînes | non       | Une liste de tags de runner |
| `version_prefix` | string       | non       | Le préfixe de la version des runners à retourner. Par exemple, `15.0`, `14`, `16.1.241` |

> [!warning]
> Obsolescences :
>
> - Les valeurs `active` et `paused` du paramètre de requête `status` sont obsolètes et leur suppression est planifiée dans [une future version de l'API REST](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). Utilisez le paramètre de requête `paused` à la place.
> - L'attribut `active` dans la réponse est obsolète et sa suppression est planifiée dans [une future version de l'API REST](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). Utilisez l'attribut `paused` à la place.

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/groups/9/runners"
```

> [!warning]
> L'attribut `ip_address` dans la réponse est obsolète [dans GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159) et sa suppression est planifiée dans [une future version de l'API REST](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). Dans GitLab, l'attribut renvoie une chaîne vide. L'attribut `ipAddress` peut être trouvé dans le gestionnaire de runner correspondant. Il est uniquement disponible via le type GraphQL [`CiRunnerManager`](graphql/reference/_index.md#cirunnermanager).

Exemple de réponse :

```json
[
  {
    "id": 3,
    "description": "Shared",
    "ip_address": "",
    "active": true,
    "paused": false,
    "is_shared": true,
    "runner_type": "instance_type",
    "name": "gitlab-runner",
    "online": null,
    "status": "never_contacted",
    "job_execution_status": "idle"
  },
  {
    "id": 6,
    "description": "Test",
    "ip_address": "",
    "active": true,
    "paused": false,
    "is_shared": true,
    "runner_type": "instance_type",
    "name": "gitlab-runner",
    "online": false,
    "status": "offline",
    "job_execution_status": "idle"
  },
  {
    "id": 8,
    "description": "Test 2",
    "ip_address": "",
    "active": true,
    "paused": false,
    "is_shared": false,
    "runner_type": "group_type",
    "name": "gitlab-runner",
    "online": null,
    "status": "never_contacted",
    "job_execution_status": "idle"
  }
]
```

## Créer un runner {#create-a-runner}

> [!warning]
> L'endpoint utilise des jetons d'enregistrement ([obsolètes](https://gitlab.com/gitlab-org/gitlab/-/issues/380872)), qui sont désactivés par défaut dans GitLab 17.0 et versions ultérieures. Utilisez [`POST /user/runners`](users.md#create-a-runner-linked-to-a-user) à la place pour créer des runners avec le workflow recommandé.

Créer un runner avec un jeton d'enregistrement de runner.

Cet endpoint renvoie un code de statut `HTTP 410 Gone` si l'enregistrement avec des jetons d'enregistrement de runner est désactivé dans les paramètres du projet ou du groupe. Si l'enregistrement avec des jetons d'enregistrement de runner est désactivé, utilisez l'endpoint [`POST /user/runners`](users.md#create-a-runner-linked-to-a-user) pour créer et enregistrer des runners à la place.

```plaintext
POST /runners
```

| Attribut          | Type         | Obligatoire | Description |
|--------------------|--------------|----------|-------------|
| `token`            | string       | oui      | [Jeton d'enregistrement](#registration-and-authentication-tokens) |
| `description`      | string       | non       | Description du runner |
| `info`             | hash         | non       | Métadonnées du runner. Vous pouvez inclure `name`, `version`, `revision`, `platform` et `architecture`, mais seuls `version`, `platform` et `architecture` sont affichés dans la zone **Admin** de l'interface utilisateur |
| `active`           | boolean      | non       | Déprécié : Utilisez plutôt `paused`. Indique si le runner est autorisé à recevoir de nouveaux jobs |
| `paused`           | boolean      | non       | Indique si le runner doit ignorer les nouveaux jobs |
| `locked`           | boolean      | non       | Indique si le runner doit être verrouillé pour le projet actuel |
| `run_untagged`     | boolean      | non       | Indique si le runner doit traiter les jobs sans tag |
| `tag_list`         | tableau de chaînes | non       | Une liste de tags de runner |
| `access_level`     | string       | non       | Le niveau d'accès du runner ; `not_protected` ou `ref_protected` |
| `maximum_timeout`  | integer      | non       | Délai d'expiration maximal qui limite la durée (en secondes) pendant laquelle les runners peuvent exécuter des jobs |
| `maintainer_note`  | string       | non       | [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/350730), voir `maintenance_note` |
| `maintenance_note` | string       | non       | Notes de maintenance en texte libre pour le runner (1024 caractères) |

```shell
curl --request POST \
     --url "https://gitlab.example.com/api/v4/runners" \
     --form "token=<registration_token>" --form "description=test-1-20150125-test" \
     --form "tag_list=ruby,mysql,tag1,tag2"
```

Réponse :

| Statut | Description |
|--------|-------------|
| 201    | Le runner a été créé |
| 403    | Jeton d'enregistrement de runner invalide |
| 410    | Enregistrement du runner désactivé |

Exemple de réponse :

```json
{
    "id": 12345,
    "token": "6337ff461c94fd3fa32ba3b1ff4125",
    "token_expires_at": "2021-09-27T21:05:03.203Z"
}
```

## Supprimer un runner {#delete-a-runner}

Vous pouvez supprimer un runner en spécifiant :

- L'identifiant du runner
- Le jeton d'authentification du runner

### Supprimer un runner par identifiant {#delete-a-runner-by-id}

Pour supprimer le runner par identifiant, utilisez votre jeton d'accès avec l'identifiant du runner :

Prérequis :

- Accès utilisateur : Vous devez disposer de l'un des éléments suivants :
  - Pour les runners d'instance : Accès administrateur à l'instance GitLab.
  - Pour les runners de groupe : Rôle Owner dans l'espace de nommage propriétaire.
  - Pour les runners de projet : Le rôle Maintainer ou Owner dans le projet qui possède le runner.
  - Un rôle personnalisé avec la permission `admin_runners` dans le groupe ou le projet concerné.
- Un jeton d'accès avec la portée `manage_runner` et le rôle approprié.

```plaintext
DELETE /runners/:id
```

| Attribut | Type    | Obligatoire | Description |
|-----------|---------|----------|-------------|
| `id`      | integer | oui      | L'identifiant d'un runner. L'identifiant est visible dans l'interface utilisateur sous **Paramètres** > **CI/CD**. Développez **Runners**, et sous **Supprimer le runner** se trouve un identifiant précédé du signe dièse, par exemple `#6`. |

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runners/6"
```

### Supprimer un runner par jeton d'authentification {#delete-a-runner-by-authentication-token}

Supprimer le runner en utilisant son jeton d'authentification.

```plaintext
DELETE /runners
```

| Attribut | Type   | Obligatoire | Description |
|-----------|--------|----------|-------------|
| `token`   | string | oui      | Le [jeton d'authentification](#registration-and-authentication-tokens) du runner. |

```shell
curl --request DELETE \
     --url "https://gitlab.example.com/api/v4/runners" \
     --form "token=<authentication_token>"
```

Réponse :

| Statut | Description |
|--------|-------------|
| 204    | Le runner a été supprimé |

## Vérifier l'authentification d'un runner enregistré {#verify-authentication-for-a-registered-runner}

Valide les identifiants d'authentification d'un runner enregistré.

```plaintext
POST /runners/verify
```

| Attribut   | Type   | Obligatoire | Description |
|-------------|--------|----------|-------------|
| `token`     | string | oui      | Le [jeton d'authentification](#registration-and-authentication-tokens) du runner. |
| `system_id` | string | non       | L'identifiant système du runner. Cet attribut est requis si `token` commence par `glrt-`. |

```shell
curl --request POST \
     --url "https://gitlab.example.com/api/v4/runners/verify" \
     --form "token=<authentication_token>"
```

Réponse :

| Statut | Description |
|--------|-------------|
| 200    | Les identifiants sont valides |
| 403    | Les identifiants sont invalides |

Exemple de réponse :

```json
{
    "id": 12345,
    "token": "glrt-6337ff461c94fd3fa32ba3b1ff4125",
    "token_expires_at": "2021-09-27T21:05:03.203Z"
}
```

## Réinitialiser le jeton d'enregistrement du runner de l'instance {#reset-instances-runner-registration-token}

> [!warning]
> L'option de transmission de jetons d'enregistrement de runner et la prise en charge de certains arguments de configuration sont considérées comme héritées et ne sont pas recommandées. Utilisez le [workflow de création de runner](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token) pour générer un jeton d'authentification afin d'enregistrer les runners. Ce processus offre une traçabilité complète de la propriété des runners et renforce la sécurité de votre flotte de runners.
>
> Pour plus d'informations, consultez [Migrer vers le nouveau workflow de création de runner](../ci/runners/new_creation_workflow.md).

Réinitialiser le jeton d'enregistrement du runner pour l'instance GitLab.

```plaintext
POST /runners/reset_registration_token
```

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runners/reset_registration_token"
```

## Réinitialiser le jeton d'enregistrement du runner du projet {#reset-projects-runner-registration-token}

> [!warning]
> L'option de transmission de jetons d'enregistrement de runner et la prise en charge de certains arguments de configuration sont considérées comme héritées et ne sont pas recommandées. Utilisez le [workflow de création de runner](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token) pour générer un jeton d'authentification afin d'enregistrer les runners. Ce processus offre une traçabilité complète de la propriété des runners et renforce la sécurité de votre flotte de runners. Pour plus d'informations, consultez [Migrer vers le nouveau workflow de création de runner](../ci/runners/new_creation_workflow.md).

Réinitialiser le jeton d'enregistrement du runner pour un projet.

```plaintext
POST /projects/:id/runners/reset_registration_token
```

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/runners/reset_registration_token"
```

## Réinitialiser le jeton d'enregistrement du runner du groupe {#reset-groups-runner-registration-token}

> [!warning]
> L'option de transmission de jetons d'enregistrement de runner et la prise en charge de certains arguments de configuration sont considérées comme héritées et ne sont pas recommandées. Utilisez le [workflow de création de runner](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token) pour générer un jeton d'authentification afin d'enregistrer les runners. Ce processus offre une traçabilité complète de la propriété des runners et renforce la sécurité de votre flotte de runners. Pour plus d'informations, consultez [Migrer vers le nouveau workflow de création de runner](../ci/runners/new_creation_workflow.md).

Réinitialiser le jeton d'enregistrement du runner pour un groupe.

```plaintext
POST /groups/:id/runners/reset_registration_token
```

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/groups/9/runners/reset_registration_token"
```

## Réinitialiser le jeton d'authentification du runner en utilisant l'identifiant du runner {#reset-runners-authentication-token-by-using-the-runner-id}

Réinitialiser le jeton d'authentification du runner en utilisant son identifiant de runner.

Prérequis :

- Accès utilisateur : Vous devez disposer de l'un des éléments suivants :
  - Pour les runners d'instance : Accès administrateur à l'instance GitLab.
  - Pour les runners de groupe : Rôle Owner dans l'espace de nommage propriétaire.
  - Pour les runners de projet : Le rôle Maintainer ou Owner dans un projet assigné au runner.
  - Un rôle personnalisé avec la permission `admin_runners` dans le groupe ou le projet concerné.
- Un jeton d'accès avec la portée `manage_runner` et le rôle approprié.

```plaintext
POST /runners/:id/reset_authentication_token
```

| Attribut | Type    | Obligatoire | Description |
|-----------|---------|----------|-------------|
| `id`      | integer | oui      | L'identifiant d'un runner |

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/runners/1/reset_authentication_token"
```

Exemple de réponse :

```json
{
    "token": "6337ff461c94fd3fa32ba3b1ff4125",
    "token_expires_at": "2021-09-27T21:05:03.203Z"
}
```

## Réinitialiser le jeton d'authentification du runner en utilisant le jeton actuel {#reset-runners-authentication-token-by-using-the-current-token}

Réinitialiser le jeton d'authentification du runner en utilisant la valeur du jeton actuel comme entrée.

```plaintext
POST /runners/reset_authentication_token
```

| Attribut | Type   | Obligatoire | Description |
|-----------|--------|----------|-------------|
| `token`   | string | oui      | Le jeton d'authentification du runner |

```shell
curl --request POST \
     --form "token=<current token>" \
     --url "https://gitlab.example.com/api/v4/runners/reset_authentication_token"
```

Exemple de réponse :

```json
{
    "token": "6337ff461c94fd3fa32ba3b1ff4125",
    "token_expires_at": "2021-09-27T21:05:03.203Z"
}
```

## Découvrir les informations du Job Router {#discover-job-router-information}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/19607) dans GitLab 18.7 [avec des feature flags](../administration/feature_flags/_index.md) nommés `job_router` et `job_router_instance_runners`. Désactivé par défaut.

{{< /history >}}

Obtenir les informations de découverte du Job Router pour un runner.

Prérequis :

- Vous devez fournir un jeton d'authentification de runner valide.

```plaintext
GET /runners/router/discovery
```

```shell
curl --header "Runner-Token: <runner_authentication_token>" \
     --url "https://gitlab.example.com/api/v4/runners/router/discovery"
```

Réponse :

La réponse contient les champs suivants :

| Attribut    | Type     | Description           |
|--------------|----------|-----------------------|
| `server_url` | string   | URL vers le Job Router |

La réponse est retournée avec l'un des codes de statut suivants :

| Statut | Description                                   |
|--------|-----------------------------------------------|
| `200`  | Informations du Job Router récupérées avec succès |
| `403`  | Interdit                                     |
| `501`  | Le Job Router n'est pas disponible                   |

Exemple de réponse :

```json
{
    "server_url": "wss://kas.example.com"
}
```
