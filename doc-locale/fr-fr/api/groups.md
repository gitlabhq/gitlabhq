---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisez l'API Groups pour gérer les groupes, les sous-groupes et l'accès aux projets."
title: API Groups
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour afficher et gérer les groupes GitLab. Pour plus d'informations, voir [les groupes](../user/group/_index.md).

Les réponses des endpoints peuvent varier selon les [autorisations](../user/permissions.md) de l'utilisateur authentifié dans le groupe.

## Récupérer un groupe {#retrieve-a-group}

Récupère les détails d'un groupe. Cet endpoint est accessible sans authentification si le groupe est accessible publiquement. Si l'utilisateur qui effectue la demande est un administrateur, des informations supplémentaires sont renvoyées. Avec l'authentification, renvoie `runners_token` et `enabled_git_access_protocol` pour le groupe si l'utilisateur est un administrateur ou possède le rôle Owner.

```plaintext
GET /groups/:id
```

Paramètres :

| Attribut                | Type           | Obligatoire | Description |
|--------------------------|----------------|----------|-------------|
| `id`                     | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `with_custom_attributes` | boolean        | non       | Inclure les [attributs personnalisés](custom_attributes.md) dans la réponse (administrateurs uniquement). |
| `with_projects`          | boolean        | non       | Inclure les détails des projets appartenant au groupe spécifié (par défaut `true`). (Déprécié, [suppression prévue dans l'API v5](https://gitlab.com/gitlab-org/gitlab/-/issues/213797). Pour obtenir les détails de tous les projets d'un groupe, utilisez l'[endpoint listant les projets d'un groupe](#list-projects).) |

> [!note]
> Les attributs `projects` et `shared_projects` dans la réponse sont dépréciés et leur [suppression est prévue dans l'API v5](https://gitlab.com/gitlab-org/gitlab/-/issues/213797). Pour obtenir les détails de tous les projets d'un groupe, utilisez soit l'endpoint [listant les projets d'un groupe](#list-projects), soit l'endpoint [listant les projets partagés d'un groupe](#list-shared-projects).

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/4"
```

Cet endpoint renvoie un maximum de 100 projets et projets partagés. Pour obtenir les détails de tous les projets d'un groupe, utilisez plutôt l'[endpoint listant les projets d'un groupe](#list-projects).

Exemple de réponse :

```json
{
  "id": 4,
  "name": "Twitter",
  "path": "twitter",
  "description": "Aliquid qui quis dignissimos distinctio ut commodi voluptas est.",
  "visibility": "public",
  "avatar_url": null,
  "web_url": "https://gitlab.example.com/groups/twitter",
  "request_access_enabled": false,
  "repository_storage": "default",
  "full_name": "Twitter",
  "full_path": "twitter",
  "runners_token": "ba324ca7b1c77fc20bb9",
  "file_template_project_id": 1,
  "parent_id": null,
  "enabled_git_access_protocol": "all",
  "created_at": "2020-01-15T12:36:29.590Z",
  "shared_with_groups": [
    {
      "group_id": 28,
      "group_name": "H5bp",
      "group_full_path": "h5bp",
      "group_access_level": 20,
      "expires_at": null
    }
  ],
  "prevent_sharing_groups_outside_hierarchy": false,
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "projects": [ // Deprecated and will be removed in API v5
    {
      "id": 7,
      "description": "Voluptas veniam qui et beatae voluptas doloremque explicabo facilis.",
      "default_branch": "main",
      "tag_list": [], //deprecated, use `topics` instead
      "topics": [],
      "archived": false,
      "visibility": "public",
      "ssh_url_to_repo": "git@gitlab.example.com:twitter/typeahead-js.git",
      "http_url_to_repo": "https://gitlab.example.com/twitter/typeahead-js.git",
      "web_url": "https://gitlab.example.com/twitter/typeahead-js",
      "name": "Typeahead.Js",
      "name_with_namespace": "Twitter / Typeahead.Js",
      "path": "typeahead-js",
      "path_with_namespace": "twitter/typeahead-js",
      "issues_enabled": true,
      "merge_requests_enabled": true,
      "wiki_enabled": true,
      "jobs_enabled": true,
      "snippets_enabled": false,
      "container_registry_enabled": true,
      "created_at": "2016-06-17T07:47:25.578Z",
      "last_activity_at": "2016-06-17T07:47:25.881Z",
      "shared_runners_enabled": true,
      "creator_id": 1,
      "namespace": {
        "id": 4,
        "name": "Twitter",
        "path": "twitter",
        "kind": "group"
      },
      "avatar_url": null,
      "star_count": 0,
      "forks_count": 0,
      "open_issues_count": 3,
      "public_jobs": true,
      "shared_with_groups": [],
      "request_access_enabled": false
    },
    {
      "id": 6,
      "description": "Aspernatur omnis repudiandae qui voluptatibus eaque.",
      "default_branch": "main",
      "tag_list": [], //deprecated, use `topics` instead
      "topics": [],
      "archived": false,
      "visibility": "internal",
      "ssh_url_to_repo": "git@gitlab.example.com:twitter/flight.git",
      "http_url_to_repo": "https://gitlab.example.com/twitter/flight.git",
      "web_url": "https://gitlab.example.com/twitter/flight",
      "name": "Flight",
      "name_with_namespace": "Twitter / Flight",
      "path": "flight",
      "path_with_namespace": "twitter/flight",
      "issues_enabled": true,
      "merge_requests_enabled": true,
      "wiki_enabled": true,
      "jobs_enabled": true,
      "snippets_enabled": false,
      "container_registry_enabled": true,
      "created_at": "2016-06-17T07:47:24.661Z",
      "last_activity_at": "2016-06-17T07:47:24.838Z",
      "shared_runners_enabled": true,
      "creator_id": 1,
      "namespace": {
        "id": 4,
        "name": "Twitter",
        "path": "twitter",
        "kind": "group"
      },
      "avatar_url": null,
      "star_count": 0,
      "forks_count": 0,
      "open_issues_count": 8,
      "public_jobs": true,
      "shared_with_groups": [],
      "request_access_enabled": false
    }
  ],
  "shared_projects": [ // Deprecated and will be removed in API v5
    {
      "id": 8,
      "description": "Velit eveniet provident fugiat saepe eligendi autem.",
      "default_branch": "main",
      "tag_list": [], //deprecated, use `topics` instead
      "topics": [],
      "archived": false,
      "visibility": "private",
      "ssh_url_to_repo": "git@gitlab.example.com:h5bp/html5-boilerplate.git",
      "http_url_to_repo": "https://gitlab.example.com/h5bp/html5-boilerplate.git",
      "web_url": "https://gitlab.example.com/h5bp/html5-boilerplate",
      "name": "Html5 Boilerplate",
      "name_with_namespace": "H5bp / Html5 Boilerplate",
      "path": "html5-boilerplate",
      "path_with_namespace": "h5bp/html5-boilerplate",
      "issues_enabled": true,
      "merge_requests_enabled": true,
      "wiki_enabled": true,
      "jobs_enabled": true,
      "snippets_enabled": false,
      "container_registry_enabled": true,
      "created_at": "2016-06-17T07:47:27.089Z",
      "last_activity_at": "2016-06-17T07:47:27.310Z",
      "shared_runners_enabled": true,
      "creator_id": 1,
      "namespace": {
        "id": 5,
        "name": "H5bp",
        "path": "h5bp",
        "kind": "group"
      },
      "avatar_url": null,
      "star_count": 0,
      "forks_count": 0,
      "open_issues_count": 4,
      "public_jobs": true,
      "shared_with_groups": [
        {
          "group_id": 4,
          "group_name": "Twitter",
          "group_full_path": "twitter",
          "group_access_level": 30,
          "expires_at": null
        },
        {
          "group_id": 3,
          "group_name": "Gitlab Org",
          "group_full_path": "gitlab-org",
          "group_access_level": 10,
          "expires_at": "2018-08-14"
        }
      ]
    }
  ],
  "ip_restriction_ranges": null,
  "math_rendering_limits_enabled": true,
  "lock_math_rendering_limits_enabled": false
}
```

L'attribut `prevent_sharing_groups_outside_hierarchy` est présent uniquement sur les groupes principaux.

Les utilisateurs de [GitLab Premium ou Ultimate](https://about.gitlab.com/pricing/) voient également les attributs :

- `shared_runners_minutes_limit`
- `extra_shared_runners_minutes_limit`
- `marked_for_deletion_on`
- `membership_lock`
- `wiki_access_level`
- `duo_features_enabled`
- `lock_duo_features_enabled`
- `duo_availability`
- `experiment_features_enabled`

Attributs de réponse supplémentaires :

```json
{
  "id": 4,
  "description": "Aliquid qui quis dignissimos distinctio ut commodi voluptas est.",
  "shared_runners_minutes_limit": 133,
  "extra_shared_runners_minutes_limit": 133,
  "marked_for_deletion_on": "2020-04-03",
  "membership_lock": false,
  "wiki_access_level": "disabled",
  "duo_features_enabled": true,
  "lock_duo_features_enabled": false,
  "duo_availability": "default_on",
  "experiment_features_enabled": false,
  ...
}
```

Lors de l'ajout du paramètre `with_projects=false`, les projets ne sont pas renvoyés.

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/4?with_projects=false"
```

Exemple de réponse :

```json
{
  "id": 4,
  "name": "Twitter",
  "path": "twitter",
  "description": "Aliquid qui quis dignissimos distinctio ut commodi voluptas est.",
  "visibility": "public",
  "avatar_url": null,
  "web_url": "https://gitlab.example.com/groups/twitter",
  "request_access_enabled": false,
  "repository_storage": "default",
  "full_name": "Twitter",
  "full_path": "twitter",
  "file_template_project_id": 1,
  "parent_id": null
}
```

## Lister les groupes {#list-groups}

### Lister tous les groupes {#list-all-groups}

Répertorie les groupes visibles pour l'utilisateur authentifié. Lorsqu'il est accédé sans authentification, seuls les groupes publics sont renvoyés.

Par défaut, cette requête renvoie 20 résultats à la fois car les résultats de l'API [sont paginés](rest/_index.md#pagination).

Lorsqu'il est accédé sans authentification, cet endpoint prend également en charge la [pagination par jeu de clés](rest/_index.md#keyset-based-pagination) :

- Lors de la demande de pages consécutives de résultats, vous devez utiliser la pagination par jeu de clés.
- Au-delà d'une limite de décalage spécifique (spécifiée par le [décalage maximum autorisé par l'API REST pour la pagination basée sur le décalage](../administration/instance_limits.md#max-offset-allowed-by-the-rest-api-for-offset-based-pagination)), la pagination par décalage n'est pas disponible.

Paramètres :

| Attribut                | Type              | Obligatoire | Description |
|--------------------------|-------------------|----------|-------------|
| `skip_groups`            | tableau d'entiers | non       | Ignorer les IDs de groupe transmis. |
| `all_available`          | boolean           | non       | Lorsque `true`, renvoie tous les groupes accessibles. Lorsque `false`, renvoie uniquement les groupes dont l'utilisateur est membre. Par défaut `false` pour les utilisateurs, `true` pour les administrateurs. Les requêtes non authentifiées renvoient toujours tous les groupes publics. Les attributs `owned` et `min_access_level` sont prioritaires. |
| `search`                 | string            | non       | Renvoyer la liste des groupes autorisés correspondant aux critères de recherche. |
| `order_by`               | string            | non       | Trier les groupes par `name`, `path`, `id` ou `similarity`. La valeur par défaut est `name`. |
| `sort`                   | string            | non       | Ordonner les groupes par ordre `asc` ou `desc`. La valeur par défaut est `asc`. |
| `statistics`             | boolean           | non       | Inclure les statistiques du groupe (administrateurs uniquement).<br> Pour les groupes principaux, la réponse renvoie les données complètes de `root_storage_statistics` affichées dans l'interface utilisateur. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/469254) dans GitLab 17.4. |
| `visibility`             | string            | non       | Limiter aux groupes avec la visibilité `public`, `internal` ou `private`. |
| `with_custom_attributes` | boolean           | non       | Inclure les [attributs personnalisés](custom_attributes.md) dans la réponse (administrateurs uniquement). |
| `owned`                  | boolean           | non       | Limiter aux groupes explicitement détenus par l'utilisateur actuel. |
| `min_access_level`       | entier           | non       | Limiter aux groupes où l'utilisateur actuel dispose au moins du niveau d'accès spécifié. Valeurs possibles : `5` (accès minimum), `10` (Guest), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer) ou `50` (Owner). |
| `top_level_only`         | boolean           | non       | Limiter aux groupes principaux, en excluant tous les sous-groupes. |
| `repository_storage`     | string            | non       | Filtrer par stockage de dépôt utilisé par le groupe (administrateurs uniquement). [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/419643) dans GitLab 16.3. Premium et Ultimate uniquement. |
| `marked_for_deletion_on` | date              | non       | Filtrer par date à laquelle le groupe a été marqué pour suppression. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/429315) dans GitLab 17.1. Premium et Ultimate uniquement. |
| `active`                 | boolean           | non       | Limiter aux groupes qui ne sont pas archivés et non marqués pour suppression. |
| `archived`               | boolean           | non       | Limiter aux groupes archivés. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/519587) dans GitLab 18.2. |

```plaintext
GET /groups
```

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "path": "foo-bar",
    "description": "An interesting group",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "owner",
    "emails_disabled": null,
    "emails_enabled": null,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch": null,
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
      "allowed_to_push": [
          {
              "access_level": 40
          }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
          {
              "access_level": 40
          }
      ]
    },
    "avatar_url": "http://localhost:3000/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://localhost:3000/groups/foo-bar",
    "request_access_enabled": false,
    "repository_storage": "default",
    "full_name": "Foobar Group",
    "full_path": "foo-bar",
    "file_template_project_id": 1,
    "parent_id": null,
    "created_at": "2020-01-15T12:36:29.590Z",
    "ip_restriction_ranges": null
  }
]
```

Lors de l'ajout du paramètre `statistics=true` et que l'utilisateur authentifié est un administrateur, des statistiques de groupe supplémentaires sont renvoyées. Pour les groupes principaux, `root_storage_statistics` sont également ajoutés.

```plaintext
GET /groups?statistics=true
```

Lorsque le paramètre `statistics=true` est utilisé et que l'utilisateur authentifié est un administrateur, la réponse inclut des informations sur la taille de stockage du registre de conteneurs :

- `container_registry_size` : Taille de stockage totale en octets utilisée par tous les dépôts de conteneurs dans le groupe et ses sous-groupes. Calculée comme la somme de toutes les tailles de dépôts dans les projets et sous-groupes du groupe. Disponible uniquement lorsque la base de données de métadonnées du registre de conteneurs est activée.
- `container_registry_size_is_estimated` : Indique si la taille est un calcul exact basé sur les données réelles de tous les dépôts (`false`) ou estimée en raison de contraintes de performance (`true`).

Pour les instances GitLab Self-Managed, la [base de données de métadonnées du registre de conteneurs](../administration/packages/container_registry_metadata_database.md) doit être activée pour inclure les attributs de taille du registre de conteneurs.

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "path": "foo-bar",
    "description": "An interesting group",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "owner",
    "emails_disabled": null,
    "emails_enabled": null,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch": null,
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
      "allowed_to_push": [
          {
              "access_level": 40
          }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
          {
              "access_level": 40
          }
      ]
    },
    "avatar_url": "http://localhost:3000/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://localhost:3000/groups/foo-bar",
    "request_access_enabled": false,
    "repository_storage": "default",
    "full_name": "Foobar Group",
    "full_path": "foo-bar",
    "file_template_project_id": 1,
    "parent_id": null,
    "created_at": "2020-01-15T12:36:29.590Z",
    "statistics": {
      "storage_size": 363,
      "repository_size": 33,
      "wiki_size": 100,
      "lfs_objects_size": 123,
      "job_artifacts_size": 57,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 50,
      "uploads_size": 0
    },
    "root_storage_statistics": {
      "build_artifacts_size": 0,
      "container_registry_size": 0,
      "container_registry_size_is_estimated": false,
      "dependency_proxy_size": 0,
      "lfs_objects_size": 0,
      "packages_size": 0,
      "pipeline_artifacts_size": 0,
      "repository_size": 0,
      "snippets_size": 0,
      "storage_size": 0,
      "uploads_size": 0,
      "wiki_size": 0
  },
    "wiki_access_level": "private",
    "duo_features_enabled": true,
    "lock_duo_features_enabled": false,
    "duo_availability": "default_on",
    "experiment_features_enabled": false,
  }
]
```

Les utilisateurs de [GitLab Premium ou Ultimate](https://about.gitlab.com/pricing/) voient également les attributs `wiki_access_level`, `duo_features_enabled`, `lock_duo_features_enabled`, `duo_availability` et `experiment_features_enabled`.

Vous pouvez rechercher des groupes par nom ou par chemin, voir ci-dessous.

Vous pouvez filtrer par [attributs personnalisés](custom_attributes.md) avec :

```plaintext
GET /groups?custom_attributes[key]=value&custom_attributes[other_key]=other_value
```

#### Pagination des groupes {#group-pagination}

Par défaut, seuls 20 groupes sont affichés à la fois car les résultats de l'API sont paginés.

Pour en obtenir davantage (jusqu'à 100), transmettez les éléments suivants comme argument à l'appel d'API :

```plaintext
/groups?per_page=100
```

Et pour changer de page, ajoutez :

```plaintext
/groups?per_page=100&page=2
```

### Rechercher un groupe {#search-for-a-group}

Rechercher des groupes correspondant à une chaîne dans leur nom ou leur chemin.

```plaintext
GET /groups?search=foobar
```

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "path": "foo-bar",
    "description": "An interesting group"
  }
]
```

## Lister les détails d'un groupe {#list-group-details}

### Lister les projets {#list-projects}

Répertorie les projets d'un groupe. Lorsqu'il est accédé sans authentification, seuls les projets publics sont renvoyés.

Par défaut, cette requête renvoie 20 résultats à la fois car les résultats de l'API [sont paginés](rest/_index.md#pagination).

```plaintext
GET /groups/:id/projects
```

Paramètres :

| Attribut                     | Type           | Obligatoire | Description |
|-------------------------------|----------------|----------|-------------|
| `id`                          | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `active`                      | boolean        | non       | Limiter par statut du projet. Lorsque `true`, renvoie les projets actifs. Lorsque `false`, renvoie les projets archivés ou marqués pour suppression. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218053) dans GitLab 18.8. |
| `archived`                    | boolean        | non       | Limiter par statut archivé. |
| `visibility`                  | string         | non       | Limiter par visibilité `public`, `internal` ou `private`. |
| `order_by`                    | string         | non       | Renvoyer les projets triés par champs `id`, `name`, `path`, `created_at`, `updated_at`, `similarity` <sup>1</sup>, `star_count` ou `last_activity_at`. La valeur par défaut est `created_at`. |
| `sort`                        | string         | non       | Renvoyer les projets triés dans l'ordre `asc` ou `desc`. La valeur par défaut est `desc`. |
| `search`                      | string         | non       | Renvoyer la liste des projets autorisés correspondant aux critères de recherche. |
| `simple`                      | boolean        | non       | Renvoyer uniquement les champs limités pour chaque projet. Il s'agit d'une opération sans effet sans authentification, où seuls les champs simples sont renvoyés. |
| `owned`                       | boolean        | non       | Limiter aux projets détenus par l'utilisateur actuel. |
| `starred`                     | boolean        | non       | Limiter aux projets mis en favoris par l'utilisateur actuel. |
| `topic`                       | string         | non       | Renvoyer les projets correspondant au sujet. |
| `with_issues_enabled`         | boolean        | non       | Limiter aux projets avec la fonctionnalité de tickets activée. La valeur par défaut est `false`. |
| `with_merge_requests_enabled` | boolean        | non       | Limiter aux projets avec la fonctionnalité de merge requests activée. La valeur par défaut est `false`. |
| `with_shared`                 | boolean        | non       | Inclure les projets partagés avec ce groupe. La valeur par défaut est `true`. |
| `include_subgroups`           | boolean        | non       | Inclure les projets dans les sous-groupes de ce groupe. La valeur par défaut est `false`. |
| `min_access_level`            | entier        | non       | Limiter aux projets où l'utilisateur actuel dispose au moins du niveau d'accès spécifié. Valeurs possibles : `5` (accès minimum), `10` (Guest), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer) ou `50` (Owner). |
| `with_custom_attributes`      | boolean        | non       | Inclure les [attributs personnalisés](custom_attributes.md) dans la réponse (administrateurs uniquement). |
| `with_security_reports`       | boolean        | non       | Renvoyer uniquement les projets disposant d'artefacts de rapports de sécurité dans l'un de leurs builds. Cela signifie « projets avec les rapports de sécurité activés ». La valeur par défaut est `false`. Ultimate uniquement. |

**Remarques** :

1. Trie les résultats selon un score de similarité calculé à partir du paramètre URL `search`. Lorsque vous utilisez `order_by=similarity`, le paramètre `sort` est ignoré. Lorsque le paramètre `search` n'est pas fourni, l'API renvoie les projets triés par `name`.

Exemple de réponse :

```json
[
  {
    "id": 9,
    "description": "foo",
    "default_branch": "main",
    "tag_list": [], //deprecated, use `topics` instead
    "topics": [],
    "archived": false,
    "visibility": "internal",
    "ssh_url_to_repo": "git@gitlab.example.com/html5-boilerplate.git",
    "http_url_to_repo": "http://gitlab.example.com/h5bp/html5-boilerplate.git",
    "web_url": "http://gitlab.example.com/h5bp/html5-boilerplate",
    "name": "Html5 Boilerplate",
    "name_with_namespace": "Experimental / Html5 Boilerplate",
    "path": "html5-boilerplate",
    "path_with_namespace": "h5bp/html5-boilerplate",
    "issues_enabled": true,
    "merge_requests_enabled": true,
    "wiki_enabled": true,
    "jobs_enabled": true,
    "snippets_enabled": true,
    "created_at": "2016-04-05T21:40:50.169Z",
    "last_activity_at": "2016-04-06T16:52:08.432Z",
    "shared_runners_enabled": true,
    "creator_id": 1,
    "namespace": {
      "id": 5,
      "name": "Experimental",
      "path": "h5bp",
      "kind": "group"
    },
    "avatar_url": null,
    "star_count": 1,
    "forks_count": 0,
    "open_issues_count": 3,
    "public_jobs": true,
    "shared_with_groups": [],
    "request_access_enabled": false
  }
]
```

> [!note]
> Pour distinguer un projet du groupe d'un projet partagé avec le groupe, l'attribut `namespace` peut être utilisé. Lorsqu'un projet a été partagé avec le groupe, son `namespace` diffère du groupe pour lequel la requête est effectuée.

### Lister les projets partagés {#list-shared-projects}

Répertorie les projets partagés avec un groupe. Lorsqu'il est accédé sans authentification, seuls les projets partagés publics sont renvoyés.

Par défaut, cette requête renvoie 20 résultats à la fois car les résultats de l'API [sont paginés](rest/_index.md#pagination).

```plaintext
GET /groups/:id/projects/shared
```

Paramètres :

| Attribut                     | Type           | Obligatoire | Description |
| ----------------------------- | -------------- | -------- | ----------- |
| `id`                          | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `archived`                    | boolean        | non       | Limiter par statut archivé. |
| `visibility`                  | string         | non       | Limiter par visibilité `public`, `internal` ou `private`. |
| `order_by`                    | string         | non       | Renvoyer les projets triés par champs `id`, `name`, `path`, `created_at`, `updated_at`, `star_count` ou `last_activity_at`. La valeur par défaut est `created_at`. |
| `sort`                        | string         | non       | Renvoyer les projets triés dans l'ordre `asc` ou `desc`. La valeur par défaut est `desc`. |
| `search`                      | string         | non       | Renvoyer la liste des projets autorisés correspondant aux critères de recherche. |
| `simple`                      | boolean        | non       | Renvoyer uniquement les champs limités pour chaque projet. Il s'agit d'une opération sans effet sans authentification, où seuls les champs simples sont renvoyés. |
| `starred`                     | boolean        | non       | Limiter aux projets mis en favoris par l'utilisateur actuel. |
| `with_issues_enabled`         | boolean        | non       | Limiter aux projets avec la fonctionnalité de tickets activée. La valeur par défaut est `false`. |
| `with_merge_requests_enabled` | boolean        | non       | Limiter aux projets avec la fonctionnalité de merge requests activée. La valeur par défaut est `false`. |
| `min_access_level`            | entier        | non       | Limiter aux projets où l'utilisateur actuel dispose au moins du niveau d'accès spécifié. Valeurs possibles : `5` (accès minimum), `10` (Guest), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer) ou `50` (Owner). |
| `with_custom_attributes`      | boolean        | non       | Inclure les [attributs personnalisés](custom_attributes.md) dans la réponse (administrateurs uniquement). |

Exemple de réponse :

```json
[
   {
      "id":8,
      "description":"Shared project for Html5 Boilerplate",
      "name":"Html5 Boilerplate",
      "name_with_namespace":"H5bp / Html5 Boilerplate",
      "path":"html5-boilerplate",
      "path_with_namespace":"h5bp/html5-boilerplate",
      "created_at":"2020-04-27T06:13:22.642Z",
      "default_branch":"main",
      "tag_list":[], //deprecated, use `topics` instead
      "topics":[],
      "ssh_url_to_repo":"ssh://git@gitlab.com/h5bp/html5-boilerplate.git",
      "http_url_to_repo":"https://gitlab.com/h5bp/html5-boilerplate.git",
      "web_url":"https://gitlab.com/h5bp/html5-boilerplate",
      "readme_url":"https://gitlab.com/h5bp/html5-boilerplate/-/blob/main/README.md",
      "avatar_url":null,
      "star_count":0,
      "forks_count":4,
      "last_activity_at":"2020-04-27T06:13:22.642Z",
      "namespace":{
         "id":28,
         "name":"H5bp",
         "path":"h5bp",
         "kind":"group",
         "full_path":"h5bp",
         "parent_id":null,
         "avatar_url":null,
         "web_url":"https://gitlab.com/groups/h5bp"
      },
      "_links":{
         "self":"https://gitlab.com/api/v4/projects/8",
         "issues":"https://gitlab.com/api/v4/projects/8/issues",
         "merge_requests":"https://gitlab.com/api/v4/projects/8/merge_requests",
         "repo_branches":"https://gitlab.com/api/v4/projects/8/repository/branches",
         "labels":"https://gitlab.com/api/v4/projects/8/labels",
         "events":"https://gitlab.com/api/v4/projects/8/events",
         "members":"https://gitlab.com/api/v4/projects/8/members"
      },
      "empty_repo":false,
      "archived":false,
      "visibility":"public",
      "resolve_outdated_diff_discussions":false,
      "container_registry_enabled":true,
      "container_expiration_policy":{
         "cadence":"7d",
         "enabled":true,
         "keep_n":null,
         "older_than":null,
         "name_regex":null,
         "name_regex_keep":null,
         "next_run_at":"2020-05-04T06:13:22.654Z"
      },
      "issues_enabled":true,
      "merge_requests_enabled":true,
      "wiki_enabled":true,
      "jobs_enabled":true,
      "snippets_enabled":true,
      "can_create_merge_request_in":true,
      "issues_access_level":"enabled",
      "repository_access_level":"enabled",
      "merge_requests_access_level":"enabled",
      "forking_access_level":"enabled",
      "wiki_access_level":"enabled",
      "builds_access_level":"enabled",
      "snippets_access_level":"enabled",
      "pages_access_level":"enabled",
      "security_and_compliance_access_level":"enabled",
      "emails_disabled":null,
      "emails_enabled": null,
      "shared_runners_enabled":true,
      "lfs_enabled":true,
      "creator_id":1,
      "import_status":"failed",
      "open_issues_count":10,
      "ci_default_git_depth":50,
      "ci_forward_deployment_enabled":true,
      "ci_forward_deployment_rollback_allowed": true,
      "ci_allow_fork_pipelines_to_run_in_parent_project":true,
      "public_jobs":true,
      "build_timeout":3600,
      "auto_cancel_pending_pipelines":"enabled",
      "ci_config_path":null,
      "shared_with_groups":[
         {
            "group_id":24,
            "group_name":"Commit451",
            "group_full_path":"Commit451",
            "group_access_level":30,
            "expires_at":null
         }
      ],
      "only_allow_merge_if_pipeline_succeeds":false,
      "request_access_enabled":true,
      "only_allow_merge_if_all_discussions_are_resolved":false,
      "remove_source_branch_after_merge":true,
      "printing_merge_request_link_enabled":true,
      "merge_method":"merge",
      "suggestion_commit_message":null,
      "auto_devops_enabled":true,
      "auto_devops_deploy_strategy":"continuous",
      "autoclose_referenced_issues":true,
      "repository_storage":"default"
   }
]
```

### Lister tous les utilisateurs SAML {#list-all-saml-users}

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193748) dans GitLab 18.1.

{{< /history >}}

Répertorie tous les utilisateurs SAML pour un groupe principal donné.

Utilisez les `page` et `per_page` [paramètres de pagination](rest/_index.md#offset-based-pagination) pour filtrer les résultats.

```plaintext
GET /groups/:id/saml_users
```

Attributs pris en charge :

| Attribut        | Type           | Obligatoire | Description |
|:-----------------|:---------------|:---------|:------------|
| `id`             | entier ou chaîne | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un groupe principal. |
| `username`       | string         | non       | Renvoie un utilisateur avec un nom d'utilisateur donné. |
| `search`         | string         | non       | Renvoie les utilisateurs dont le nom, l'e-mail ou le nom d'utilisateur correspond. Utilisez des valeurs partielles pour augmenter les résultats. |
| `active`         | boolean        | non       | Renvoie uniquement les utilisateurs actifs. |
| `blocked`        | boolean        | non       | Renvoie uniquement les utilisateurs bloqués. |
| `created_after`  | datetime       | non       | Renvoie les utilisateurs créés après l'heure spécifiée. Format : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). |
| `created_before` | datetime       | non       | Renvoie les utilisateurs créés avant l'heure spécifiée. Format : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/saml_users"
```

Exemple de réponse :

```json
[
  {
    "id": 66,
    "username": "user22",
    "name": "Sidney Jones22",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/xxx?s=80&d=identicon",
    "web_url": "http://my.gitlab.com/user22",
    "created_at": "2021-09-10T12:48:22.381Z",
    "bio": "",
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "job_title": "",
    "pronouns": null,
    "bot": false,
    "work_information": null,
    "followers": 0,
    "following": 0,
    "local_time": null,
    "last_sign_in_at": null,
    "confirmed_at": "2021-09-10T12:48:22.330Z",
    "last_activity_on": null,
    "email": "user22@example.org",
    "theme_id": 1,
    "color_scheme_id": 1,
    "projects_limit": 100000,
    "current_sign_in_at": null,
    "identities": [
      {
        "provider": "group_saml",
        "extern_uid": "2435223452345",
        "saml_provider_id": 1
      }
    ],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": false,
    "commit_email": "user22@example.org",
    "shared_runners_minutes_limit": null,
    "extra_shared_runners_minutes_limit": null,
    "scim_identities": [
      {
        "extern_uid": "2435223452345",
        "group_id": 1,
        "active": true
      }
    ]
  },
  ...
]
```

### Lister les utilisateurs provisionnés {#list-provisioned-users}

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Répertorie les utilisateurs provisionnés par un groupe. N'inclut pas les sous-groupes.

Nécessite le rôle Maintainer ou Owner sur le groupe.

```plaintext
GET /groups/:id/provisioned_users
```

Paramètres :

| Attribut        | Type           | Obligatoire | Description |
|:-----------------|:---------------|:---------|:------------|
| `id`             | entier ou chaîne | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `username`       | string         | non       | Renvoyer un seul utilisateur avec un nom d'utilisateur spécifique. |
| `search`         | string         | non       | Rechercher des utilisateurs par nom, e-mail, nom d'utilisateur. |
| `active`         | boolean        | non       | Renvoie uniquement les utilisateurs actifs. |
| `blocked`        | boolean        | non       | Renvoie uniquement les utilisateurs bloqués. |
| `created_after`  | datetime       | non       | Renvoie les utilisateurs créés après l'heure spécifiée. |
| `created_before` | datetime       | non       | Renvoie les utilisateurs créés avant l'heure spécifiée. |

Exemple de réponse :

```json
[
  {
    "id": 66,
    "username": "user22",
    "name": "John Doe22",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/xxx?s=80&d=identicon",
    "web_url": "http://my.gitlab.com/user22",
    "created_at": "2021-09-10T12:48:22.381Z",
    "bio": "",
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "job_title": "",
    "pronouns": null,
    "bot": false,
    "work_information": null,
    "followers": 0,
    "following": 0,
    "local_time": null,
    "last_sign_in_at": null,
    "confirmed_at": "2021-09-10T12:48:22.330Z",
    "last_activity_on": null,
    "email": "user22@example.org",
    "theme_id": 1,
    "color_scheme_id": 1,
    "projects_limit": 100000,
    "current_sign_in_at": null,
    "identities": [ ],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": false,
    "commit_email": "user22@example.org",
    "shared_runners_minutes_limit": null,
    "extra_shared_runners_minutes_limit": null
  },
  ...
]
```

### Lister les sous-groupes {#list-subgroups}

Répertorie les sous-groupes directs visibles dans un groupe.

Par défaut, cette requête renvoie 20 résultats à la fois car les résultats de l'API [sont paginés](rest/_index.md#pagination).

Si vous demandez cette liste en tant que :

- Utilisateur non authentifié, la réponse renvoie uniquement les groupes publics.
- Utilisateur authentifié, la réponse renvoie uniquement les groupes dont vous êtes membre et n'inclut pas les groupes publics.

Paramètres :

| Attribut                | Type              | Obligatoire | Description |
| ------------------------ | ----------------- | -------- | ----------- |
| `id`                     | entier ou chaîne    | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe du groupe parent immédiat. |
| `skip_groups`            | tableau d'entiers | non       | Ignorer les IDs de groupe transmis. |
| `all_available`          | boolean           | non       | Afficher tous les groupes auxquels vous avez accès (par défaut `false` pour les utilisateurs authentifiés, `true` pour les administrateurs). Les attributs `owned` et `min_access_level` sont prioritaires. |
| `search`                 | string            | non       | Renvoyer la liste des groupes autorisés correspondant aux critères de recherche. Seuls les chemins courts des sous-groupes sont recherchés (pas les chemins complets). |
| `order_by`               | string            | non       | Trier les groupes par `name`, `path` ou `id`. La valeur par défaut est `name`. |
| `sort`                   | string            | non       | Ordonner les groupes par ordre `asc` ou `desc`. La valeur par défaut est `asc`. |
| `statistics`             | boolean           | non       | Inclure les statistiques du groupe (administrateurs uniquement). |
| `with_custom_attributes` | boolean           | non       | Inclure les [attributs personnalisés](custom_attributes.md) dans la réponse (administrateurs uniquement). |
| `owned`                  | boolean           | non       | Limiter aux groupes explicitement détenus par l'utilisateur actuel. |
| `min_access_level`       | entier           | non       | Limiter aux groupes où l'utilisateur actuel dispose au moins du niveau d'accès spécifié. Valeurs possibles : `5` (accès minimum), `10` (Guest), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer) ou `50` (Owner). |
| `all_available`          | boolean           | non       | Lorsque `true`, renvoie tous les groupes accessibles. Lorsque `false`, renvoie uniquement les groupes dont l'utilisateur est membre. Par défaut `false` pour les utilisateurs, `true` pour les administrateurs. Les requêtes non authentifiées renvoient toujours tous les groupes publics. Les attributs `owned` et `min_access_level` sont prioritaires. |
| `active`                 | boolean           | non       | Limiter aux groupes qui ne sont pas archivés et non marqués pour suppression. |

```plaintext
GET /groups/:id/subgroups
```

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "path": "foo-bar",
    "description": "An interesting group",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "owner",
    "emails_disabled": null,
    "emails_enabled": null,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch": null,
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
      "allowed_to_push": [
          {
              "access_level": 40
          }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
          {
              "access_level": 40
          }
      ]
    },
    "avatar_url": "http://gitlab.example.com/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://gitlab.example.com/groups/foo-bar",
    "request_access_enabled": false,
    "repository_storage": "default",
    "full_name": "Foobar Group",
    "full_path": "foo-bar",
    "file_template_project_id": 1,
    "parent_id": 123,
    "created_at": "2020-01-15T12:36:29.590Z"
  }
]
```

Les utilisateurs de [GitLab Premium ou Ultimate](https://about.gitlab.com/pricing/) voient également les attributs `wiki_access_level`, `duo_features_enabled`, `lock_duo_features_enabled`, `duo_availability` et `experiment_features_enabled`.

### Lister les groupes descendants {#list-descendant-groups}

Répertorie les groupes descendants visibles d'un groupe. Lorsqu'il est accédé sans authentification, seuls les groupes publics sont renvoyés.

Par défaut, cette requête renvoie 20 résultats à la fois car les résultats de l'API [sont paginés](rest/_index.md#pagination).

Paramètres :

| Attribut                | Type              | Obligatoire | Description |
| ------------------------ | ----------------- | -------- | ----------- |
| `id`                     | entier ou chaîne    | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe du groupe parent immédiat. |
| `skip_groups`            | tableau d'entiers | non       | Ignorer les IDs de groupe transmis. |
| `all_available`          | boolean           | non       | Lorsque `true`, renvoie tous les groupes accessibles. Lorsque `false`, renvoie uniquement les groupes dont l'utilisateur est membre. Par défaut `false` pour les utilisateurs, `true` pour les administrateurs. Les requêtes non authentifiées renvoient toujours tous les groupes publics. Les attributs `owned` et `min_access_level` sont prioritaires. |
| `search`                 | string            | non       | Renvoyer la liste des groupes autorisés correspondant aux critères de recherche. Seuls les chemins courts des groupes descendants sont recherchés (pas les chemins complets). |
| `order_by`               | string            | non       | Trier les groupes par `name`, `path` ou `id`. La valeur par défaut est `name`. |
| `sort`                   | string            | non       | Ordonner les groupes par ordre `asc` ou `desc`. La valeur par défaut est `asc`. |
| `statistics`             | boolean           | non       | Inclure les statistiques du groupe (administrateurs uniquement). |
| `with_custom_attributes` | boolean           | non       | Inclure les [attributs personnalisés](custom_attributes.md) dans la réponse (administrateurs uniquement). |
| `owned`                  | boolean           | non       | Limiter aux groupes explicitement détenus par l'utilisateur actuel. |
| `min_access_level`       | entier           | non       | Limiter aux groupes où l'utilisateur actuel dispose au moins du niveau d'accès spécifié. Valeurs possibles : `5` (accès minimum), `10` (Guest), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer) ou `50` (Owner). |
| `active`                 | boolean           | non       | Limiter aux groupes qui ne sont pas archivés et non marqués pour suppression. |

```plaintext
GET /groups/:id/descendant_groups
```

```json
[
  {
    "id": 2,
    "name": "Bar Group",
    "path": "bar",
    "description": "A subgroup of Foo Group",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "owner",
    "emails_disabled": null,
    "emails_enabled": null,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch": null,
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
      "allowed_to_push": [
          {
              "access_level": 40
          }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
          {
              "access_level": 40
          }
      ]
    },
    "avatar_url": "http://gitlab.example.com/uploads/group/avatar/1/bar.jpg",
    "web_url": "http://gitlab.example.com/groups/foo/bar",
    "request_access_enabled": false,
    "full_name": "Bar Group",
    "full_path": "foo/bar",
    "file_template_project_id": 1,
    "parent_id": 123,
    "created_at": "2020-01-15T12:36:29.590Z"
  },
  {
    "id": 3,
    "name": "Baz Group",
    "path": "baz",
    "description": "A subgroup of Bar Group",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "owner",
    "emails_disabled": null,
    "emails_enabled": null,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch": null,
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
      "allowed_to_push": [
          {
              "access_level": 40
          }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
          {
              "access_level": 40
          }
      ]
    },
    "avatar_url": "http://gitlab.example.com/uploads/group/avatar/1/baz.jpg",
    "web_url": "http://gitlab.example.com/groups/foo/bar/baz",
    "request_access_enabled": false,
    "full_name": "Baz Group",
    "full_path": "foo/bar/baz",
    "file_template_project_id": 1,
    "parent_id": 123,
    "created_at": "2020-01-15T12:36:29.590Z"
  }
]
```

Les utilisateurs de [GitLab Premium ou Ultimate](https://about.gitlab.com/pricing/) voient également les attributs `wiki_access_level`, `duo_features_enabled`, `lock_duo_features_enabled`, `duo_availability` et `experiment_features_enabled`.

### Lister les groupes partagés {#list-shared-groups}

Répertorie les groupes dans lesquels le groupe donné a été invité. Lorsqu'il est accédé sans authentification, seuls les groupes partagés publics sont renvoyés.

Par défaut, cette requête renvoie 20 résultats à la fois car les résultats de l'API [sont paginés](rest/_index.md#pagination).

Paramètres :

| Attribut                             | Type              | Obligatoire | Description |
| ------------------------------------- | ----------------- | -------- | ---------- |
| `id`                                  | entier ou chaîne    | oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `skip_groups`                         | tableau d'entiers | non       | Ignorer les IDs de groupe spécifiés. |
| `search`                              | string            | non       | Renvoyer la liste des groupes autorisés correspondant aux critères de recherche. |
| `order_by`                            | string            | non       | Trier les groupes par `name`, `path`, `id` ou `similarity`. La valeur par défaut est `name`. |
| `sort`                                | string            | non       | Ordonner les groupes par ordre `asc` ou `desc`. La valeur par défaut est `asc`. |
| `visibility`                          | string            | non       | Limiter aux groupes avec la visibilité `public`, `internal` ou `private`. |
| `min_access_level`                    | entier           | non       | Limiter aux groupes où l'utilisateur actuel dispose au moins du niveau d'accès spécifié. Valeurs possibles : `5` (accès minimum), `10` (Guest), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer) ou `50` (Owner). |
| `with_custom_attributes`              | boolean           | non       | Inclure les [attributs personnalisés](custom_attributes.md) dans la réponse (administrateurs uniquement). |

```plaintext
GET /groups/:id/groups/shared
```

Exemple de réponse :

```json
[
  {
    "id": 101,
    "web_url": "http://gitlab.example.com/groups/some_path",
    "name": "group1",
    "path": "some_path",
    "description": "",
    "visibility": "public",
    "share_with_group_lock": "false",
    "require_two_factor_authentication": "false",
    "two_factor_grace_period": 48,
    "project_creation_level": "maintainer",
    "auto_devops_enabled": "nil",
    "subgroup_creation_level": "maintainer",
    "emails_disabled": "false",
    "emails_enabled": "true",
    "mentions_disabled": "nil",
    "lfs_enabled": "true",
    "math_rendering_limits_enabled": "true",
    "lock_math_rendering_limits_enabled": "false",
    "default_branch": "nil",
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
        "allowed_to_push": [
          {
              "access_level": 30
          }
        ],
        "allow_force_push": "true",
        "allowed_to_merge": [
          {
              "access_level": 30
          }
        ],
        "developer_can_initial_push": "false",
        "code_owner_approval_required": "false"
    },
    "avatar_url": "http://gitlab.example.com/uploads/-/system/group/avatar/101/banana_sample.gif",
    "request_access_enabled": "true",
    "full_name": "group1",
    "full_path": "some_path",
    "created_at": "2024-06-06T09:39:30.056Z",
    "parent_id": "nil",
    "organization_id": 1,
    "shared_runners_setting": "enabled",
    "ldap_cn": "nil",
    "ldap_access": "nil",
    "wiki_access_level": "enabled"
  }
]
```

### Lister les groupes invités {#list-invited-groups}

Répertorie les groupes invités dans un groupe. Lorsqu'il est accédé sans authentification, seuls les groupes invités publics sont renvoyés. Cet endpoint est soumis à une limite de débit de 60 requêtes par minute par utilisateur (pour les utilisateurs authentifiés) ou par IP (pour les utilisateurs non authentifiés).

Par défaut, cette requête renvoie 20 résultats à la fois car les résultats de l'API [sont paginés](rest/_index.md#pagination).

Paramètres :

| Attribut                             | Type              | Obligatoire | Description |
| ------------------------------------- | ----------------- | -------- | ---------- |
| `id`                                  | entier ou chaîne    | oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `search`                              | string            | non       | Renvoyer la liste des groupes autorisés correspondant aux critères de recherche. |
| `min_access_level`                    | entier           | non       | Limiter aux groupes où l'utilisateur actuel dispose au moins du niveau d'accès spécifié. Valeurs possibles : `5` (accès minimum), `10` (Guest), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer) ou `50` (Owner). |
| `relation`                            | tableau de chaînes  | non       | Filtrer les groupes par relation (directe ou héritée). |
| `with_custom_attributes`              | boolean           | non       | Inclure les [attributs personnalisés](custom_attributes.md) dans la réponse (administrateurs uniquement). |

```plaintext
GET /groups/:id/invited_groups
```

Exemple de réponse :

```json
[
  {
    "id": 33,
    "web_url": "http://gitlab.example.com/groups/flightjs",
    "name": "Flightjs",
    "path": "flightjs",
    "description": "Illo dolorum tempore eligendi minima ducimus provident.",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "maintainer",
    "emails_disabled": false,
    "emails_enabled": true,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "math_rendering_limits_enabled": true,
    "lock_math_rendering_limits_enabled": false,
    "default_branch": null,
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
      "allowed_to_push": [
        {
          "access_level": 40
        }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
        {
          "access_level": 40
        }
      ],
      "developer_can_initial_push": false
    },
    "avatar_url": null,
    "request_access_enabled": true,
    "full_name": "Flightjs",
    "full_path": "flightjs",
    "created_at": "2024-07-09T10:31:08.307Z",
    "parent_id": null,
    "organization_id": 1,
    "shared_runners_setting": "enabled",
    "ldap_cn": null,
    "ldap_access": null,
    "wiki_access_level": "enabled"
  }
]
```

### Lister les événements d'audit {#list-audit-events}

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les événements d'audit de groupe sont accessibles via l'[API des événements d'audit de groupe](audit_events.md#group-audit-events)

## Gérer les groupes {#manage-groups}

### Créer un groupe {#create-a-group}

> [!note]
> Sur GitLab.com, vous devez utiliser l'interface utilisateur GitLab pour créer des groupes sans groupe parent. Vous ne pouvez pas utiliser l'API pour cela.

Crée un nouveau groupe de projet. Disponible uniquement pour les utilisateurs pouvant créer des groupes.

```plaintext
POST /groups
```

Paramètres :

| Attribut                            | Type    | Obligatoire | Description |
|--------------------------------------|---------|----------|-------------|
| `name`                               | string  | oui      | Le nom du groupe. |
| `path`                               | string  | oui      | Le chemin du groupe. |
| `auto_devops_enabled`                | boolean | non       | Par défaut, utilise le pipeline Auto DevOps pour tous les projets de ce groupe. |
| `avatar`                             | mixed   | non       | Fichier image pour l'avatar du groupe. |
| `default_branch`                     | string  | non       | Le nom de la [branche par défaut](../user/project/repository/branches/default.md) pour les projets du groupe. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/442298) dans GitLab 16.11. |
| `default_branch_protection`          | entier | non       | [Déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/408314) dans GitLab 17.0. Utilisez `default_branch_protection_defaults` à la place. |
| `default_branch_protection_defaults` | hash    | non       | Introduit dans GitLab 17.0. Pour les options disponibles, voir [Options pour `default_branch_protection_defaults`](#options-for-default_branch_protection_defaults). |
| `description`                        | string  | non       | La description du groupe. |
| `enabled_git_access_protocol`        | string  | non       | Protocoles activés pour l'accès Git. Les valeurs autorisées sont : `ssh`, `http` et `all` pour autoriser les deux protocoles. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/436618) dans GitLab 16.9. |
| `emails_disabled`                    | boolean | non       | ([Déprécié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127899) dans GitLab 16.5.) Désactiver les notifications par e-mail. Utilisez `emails_enabled` à la place. |
| `emails_enabled`                     | boolean | non       | Activer les notifications par e-mail. |
| `lfs_enabled`                        | boolean | non       | Activer/désactiver le stockage de fichiers volumineux (LFS) pour les projets de ce groupe. |
| `mentions_disabled`                  | boolean | non       | Désactiver la possibilité pour un groupe d'être mentionné. |
| `organization_id`                    | entier | non       | L'ID d'organisation pour le groupe. |
| `parent_id`                          | entier | non       | L'ID du groupe parent pour créer un groupe imbriqué. |
| `project_creation_level`             | string  | non       | Déterminer si les développeurs peuvent créer des projets dans le groupe. Peut être `administrator` (utilisateurs avec le mode Admin activé), `noone` (Personne), `maintainer` (utilisateurs avec le rôle Maintainer) ou `developer` (utilisateurs avec le rôle Developer ou Maintainer). |
| `request_access_enabled`             | boolean | non       | Autoriser les utilisateurs à demander l'accès en tant que membre. |
| `require_two_factor_authentication`  | boolean | non       | Exiger que tous les utilisateurs de ce groupe configurent l'authentification à deux facteurs. |
| `share_with_group_lock`              | boolean | non       | Empêcher le partage d'un projet avec un autre groupe au sein de ce groupe. |
| `subgroup_creation_level`            | string  | non       | Autorisé à [créer des sous-groupes](../user/group/subgroups/_index.md#create-a-subgroup). Peut être `owner` (utilisateurs avec le rôle Owner) ou `maintainer` (utilisateurs avec le rôle Maintainer). |
| `two_factor_grace_period`            | entier | non       | Délai avant l'application de l'authentification à deux facteurs (en heures). |
| `visibility`                         | string  | non       | La visibilité du groupe. Peut être `private`, `internal` ou `public`. |
| `membership_lock`                    | boolean | non       | Les utilisateurs ne peuvent pas être ajoutés aux projets de ce groupe. Premium et Ultimate uniquement. |
| `extra_shared_runners_minutes_limit` | entier | non       | Peut être défini par les administrateurs uniquement. Minutes de calcul supplémentaires pour ce groupe. GitLab Self-Managed, Premium et Ultimate uniquement. |
| `shared_runners_minutes_limit`       | entier | non       | Peut être défini par les administrateurs uniquement. Nombre maximum de minutes de calcul mensuelles pour ce groupe. Peut être `nil` (par défaut ; hérite du paramètre système par défaut), `0` (illimité) ou `> 0`. GitLab Self-Managed, Premium et Ultimate uniquement. |
| `wiki_access_level`                  | string  | non       | Le niveau d'accès au wiki. Peut être `disabled`, `private` ou `enabled`. Premium et Ultimate uniquement. |
| `duo_availability` | string | non | Paramètre de disponibilité de GitLab Duo. Les valeurs valides sont : `default_on`, `default_off`, `never_on`. Remarque : Dans l'interface utilisateur, `never_on` s'affiche comme « Always Off ». |
| `experiment_features_enabled` | boolean | non | Activer les fonctionnalités expérimentales pour ce groupe. |

#### Options pour `default_branch_protection` {#options-for-default_branch_protection}

L'attribut `default_branch_protection` détermine si les utilisateurs avec le rôle Developer ou Maintainer peuvent pousser vers la [branche par défaut](../user/project/repository/branches/default.md) applicable, comme décrit dans le tableau suivant :

| Valeur | Description |
|-------|-------------|
| `0`   | Aucune protection. Les utilisateurs avec le rôle Developer ou Maintainer peuvent : <br>\- Pousser de nouveaux commits.<br>\- Forcer la poussée des modifications.<br>\- Supprimer la branche. |
| `1`   | Protection partielle. Les utilisateurs avec le rôle Developer ou Maintainer peuvent : <br>\- Pousser de nouveaux commits. |
| `2`   | Protection complète. Seuls les utilisateurs avec le rôle Maintainer peuvent : <br>\- Pousser de nouveaux commits. |
| `3`   | Protégé contre les poussées. Les utilisateurs avec le rôle Maintainer peuvent : <br>\- Pousser de nouveaux commits.<br>\- Forcer la poussée des modifications.<br>\- Accepter des merge requests.<br>Les utilisateurs avec le rôle Developer peuvent :<br>\- Accepter des merge requests. |
| `4`   | Protection complète après la première poussée. L'utilisateur avec le rôle Developer peut : <br>\- Pousser un commit vers un dépôt vide.<br> Les utilisateurs avec le rôle Maintainer peuvent : <br>\- Pousser de nouveaux commits.<br>\- Accepter des merge requests. |

#### Options pour `default_branch_protection_defaults` {#options-for-default_branch_protection_defaults}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/408314) dans GitLab 17.0.

{{< /history >}}

L'attribut `default_branch_protection_defaults` décrit les valeurs par défaut de protection de la branche par défaut. Tous les paramètres sont optionnels.

| Clé                            | Type    | Description |
|:-------------------------------|:--------|:------------|
| `allowed_to_push`              | tableau   | Un tableau des niveaux d'accès autorisés à pousser. Prend en charge Developer (30) ou Maintainer (40). |
| `allow_force_push`             | boolean | Autoriser la poussée forcée pour tous les utilisateurs disposant d'un accès en poussée. |
| `allowed_to_merge`             | tableau   | Un tableau des niveaux d'accès autorisés à fusionner. Prend en charge Developer (30) ou Maintainer (40). |
| `developer_can_initial_push`   | boolean | Autoriser les développeurs à effectuer la première poussée. |
| `code_owner_approval_required` | boolean | Exiger l'approbation du propriétaire du code. |

### Créer un sous-groupe {#create-a-subgroup}

Cette procédure est similaire à la création d'un [nouveau groupe](#create-a-group). Vous avez besoin du `parent_id` obtenu lors de l'appel [List groups](#list-groups). Vous pouvez ensuite saisir les valeurs souhaitées :

- `subgroup_path`
- `subgroup_name`

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"path": "<subgroup_path>", "name": "<subgroup_name>", "parent_id": <parent_group_id> }' \
  --url "https://gitlab.example.com/api/v4/groups/"
```

### Planifier la suppression d'un groupe {#schedule-a-group-for-deletion}

{{< history >}}

- [Disponible globalement](https://gitlab.com/gitlab-org/gitlab/-/issues/389557) dans GitLab 16.0. Premium et Ultimate uniquement.
- [Déplacé](https://gitlab.com/groups/gitlab-org/-/epics/17208) de GitLab Premium vers GitLab Free dans GitLab 18.0.

{{< /history >}}

Planifie la suppression d'un groupe. Les groupes sont supprimés à la fin de la période de rétention :

- Sur GitLab.com, les groupes sont conservés pendant 30 jours.
- Sur GitLab Self-Managed, la période de rétention est contrôlée par les [paramètres de l'instance](../administration/settings/visibility_and_access_controls.md#deletion-protection).

Ce point de terminaison peut également supprimer immédiatement un sous-groupe qui était précédemment planifié pour suppression.

Prérequis :

- Vous devez être administrateur ou avoir le rôle Owner pour le groupe.

```plaintext
DELETE /groups/:id
```

| Attribut            | Type              | Obligatoire | Description |
|----------------------|-------------------|----------|-------------|
| `id`                 | entier ou chaîne | Oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `full_path`          | string            | Conditionnel       | Le chemin complet vers le sous-groupe. Utilisé pour confirmer la suppression du sous-groupe. Si `permanently_remove` est `true`, cet attribut est requis. Pour trouver le chemin du sous-groupe, consultez les [détails du groupe](groups.md#retrieve-a-group). |
| `permanently_remove` | booléen/chaîne    | Non       | Si `true`, supprime immédiatement un sous-groupe déjà planifié pour suppression. Impossible de supprimer les groupes principaux. |

En cas de succès, retourne un code de statut [`202 Accepted`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Accept: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/:id"
```

> [!note]
> Vous ne pouvez pas supprimer un groupe GitLab.com lié à un abonnement. Vous devez d'abord [lier l'abonnement](../subscriptions/manage_subscription.md#link-subscription-to-a-group) à un autre groupe.

#### Supprimer définitivement un groupe {#delete-a-group-permanently}

Contourne la période de rétention configurée et supprime définitivement un groupe et ses données.

Prérequis :

- Vous devez être administrateur ou avoir le rôle Owner pour le groupe.

```plaintext
DELETE /groups/:id
```

| Attribut            | Type              | Obligatoire | Description |
|----------------------|-------------------|----------|-------------|
| `id`                 | entier ou chaîne | Oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `full_path`          | string            | Oui       | Le chemin complet modifié du sous-groupe après planification de sa suppression. Si `permanently_remove` est `true`, cet attribut est requis. Pour confirmer le chemin complet modifié, [récupérez le groupe](#retrieve-a-group). |
| `permanently_remove` | booléen/chaîne    | Oui       | Si `true`, supprime définitivement un sous-groupe déjà planifié pour suppression. Impossible de supprimer les groupes principaux. |

En cas de succès, retourne un code de statut [`202 Accepted`](rest/troubleshooting.md#status-codes).

Pour supprimer définitivement un groupe planifié pour suppression, vous devez :

1. Planifier la suppression du groupe via un appel API.
1. Dans un second appel API, supprimer le groupe.

Par exemple :

```shell
# Schedule a group for deletion
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Accept: application/json" \
  --url "https://gitlab.example.com/api/v4/groups/:id"

# Permanently delete a group scheduled for deletion
# Use the modified full_path of the subgroup
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --data '{"full_path": "<path-after-soft-delete>", "permanently_remove": "true"}' \
  --url "https://gitlab.example.com/api/v4/groups/:id"
```

#### Restaurer un groupe marqué pour suppression {#restore-a-group-marked-for-deletion}

Restaure un groupe précédemment marqué pour suppression.

```plaintext
POST /groups/:id/restore
```

Paramètres :

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |

### Archiver un groupe {#archive-a-group}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/481969) dans GitLab 18.0 [avec un flag](../administration/feature_flags/_index.md) nommé `archive_group`. Désactivé par défaut.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/526771) dans GitLab 18.9. L'indicateur de fonctionnalité `archive_group` a été supprimé.

{{< /history >}}

Archiver un groupe.

Prérequis :

- Vous devez être administrateur ou avoir le rôle Owner pour le groupe.

Ce point de terminaison retourne une erreur d'entité non traitable `422` si le groupe est déjà archivé.

```plaintext
POST /groups/:id/archive
```

Paramètres :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe appartenant à l'utilisateur authentifié. |

Exemple de réponse :

```json
{
  "id": 96,
  "web_url": "https://gitlab.example.com/groups/test-1",
  "name": "test-1",
  "path": "test-1",
  "description": "",
  "visibility": "public",
  "share_with_group_lock": false,
  "require_two_factor_authentication": false,
  "two_factor_grace_period": 48,
  "project_creation_level": "developer",
  "auto_devops_enabled": null,
  "subgroup_creation_level": "maintainer",
  "emails_disabled": false,
  "emails_enabled": true,
  "mentions_disabled": null,
  "lfs_enabled": true,
  "archived": true,
  "math_rendering_limits_enabled": true,
  "lock_math_rendering_limits_enabled": false,
  "default_branch": null,
  "default_branch_protection": 2,
  "default_branch_protection_defaults": {
    "allowed_to_push": [
      {
        "access_level": 40
      }
    ],
    "allow_force_push": false,
    "allowed_to_merge": [
      {
        "access_level": 40
      }
    ],
    "developer_can_initial_push": false
  },
  "avatar_url": null,
  "request_access_enabled": true,
  "full_name": "test-1",
  "full_path": "test-1",
  "created_at": "2025-03-25T12:05:24.813Z",
  "parent_id": null,
  "organization_id": 1,
  "shared_runners_setting": "enabled",
  "max_artifacts_size": null,
  "ldap_cn": null,
  "ldap_access": null,
  "wiki_access_level": "enabled",
  "shared_with_groups": [],
  "prevent_sharing_groups_outside_hierarchy": false,
  "shared_runners_minutes_limit": null,
  "extra_shared_runners_minutes_limit": null,
  "prevent_forking_outside_group": null,
  "membership_lock": false
}
```

#### Désarchiver un groupe {#unarchive-a-group}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/481969) dans GitLab 18.0 [avec un flag](../administration/feature_flags/_index.md) nommé `archive_group`. Désactivé par défaut.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/526771) dans GitLab 18.9. L'indicateur de fonctionnalité `archive_group` a été supprimé.

{{< /history >}}

Désarchiver un groupe.

Prérequis :

- Vous devez être administrateur ou avoir le rôle Owner pour le groupe.

Ce point de terminaison retourne une erreur d'entité non traitable `422` si le groupe n'est pas archivé.

```plaintext
POST /groups/:id/unarchive
```

Paramètres :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe appartenant à l'utilisateur authentifié. |

Exemple de réponse :

```json
{
  "id": 96,
  "web_url": "https://gitlab.example.com/groups/test-1",
  "name": "test-1",
  "path": "test-1",
  "description": "",
  "visibility": "public",
  "share_with_group_lock": false,
  "require_two_factor_authentication": false,
  "two_factor_grace_period": 48,
  "project_creation_level": "developer",
  "auto_devops_enabled": null,
  "subgroup_creation_level": "maintainer",
  "emails_disabled": false,
  "emails_enabled": true,
  "mentions_disabled": null,
  "lfs_enabled": true,
  "archived": false,
  "math_rendering_limits_enabled": true,
  "lock_math_rendering_limits_enabled": false,
  "default_branch": null,
  "default_branch_protection": 2,
  "default_branch_protection_defaults": {
    "allowed_to_push": [
      {
        "access_level": 40
      }
    ],
    "allow_force_push": false,
    "allowed_to_merge": [
      {
        "access_level": 40
      }
    ],
    "developer_can_initial_push": false
  },
  "avatar_url": null,
  "request_access_enabled": true,
  "full_name": "test-1",
  "full_path": "test-1",
  "created_at": "2025-03-25T12:05:24.813Z",
  "parent_id": null,
  "organization_id": 1,
  "shared_runners_setting": "enabled",
  "max_artifacts_size": null,
  "ldap_cn": null,
  "ldap_access": null,
  "wiki_access_level": "enabled",
  "shared_with_groups": [],
  "prevent_sharing_groups_outside_hierarchy": false,
  "shared_runners_minutes_limit": null,
  "extra_shared_runners_minutes_limit": null,
  "prevent_forking_outside_group": null,
  "membership_lock": false
}
```

### Transférer un groupe {#transfer-a-group}

Transfère un groupe vers un nouveau groupe parent ou transforme un sous-groupe en groupe principal.

Prérequis :

- Vous devez avoir le rôle Owner pour le groupe.
- Si vous transférez un groupe, vous devez avoir la permission de [créer un sous-groupe](../user/group/subgroups/_index.md#create-a-subgroup) dans le nouveau groupe parent.
- Si vous transformez un sous-groupe, vous devez avoir la [permission de créer un groupe principal](../administration/user_settings.md).

```plaintext
POST /groups/:id/transfer
```

Paramètres :

| Attribut  | Type    | Obligatoire | Description |
|------------|---------|----------|-------------|
| `id`       | entier | oui      | ID du groupe à transférer. |
| `id`       | entier | oui      | ID du groupe à transférer. |
| `group_id` | entier | non       | ID du nouveau groupe parent. Si non spécifié, le groupe est transformé en groupe principal. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/4/transfer?group_id=7"
```

#### Lister tous les emplacements disponibles pour le transfert de groupe {#list-all-locations-available-for-group-transfer}

Liste tous les groupes parents disponibles pour transférer un groupe spécifié.

```plaintext
GET /groups/:id/transfer_locations
```

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du groupe à transférer](rest/_index.md#namespaced-paths). |
| `search`  | string            | Non       | Le nom d'un groupe spécifique à rechercher. |

Exemple de requête :

```shell
curl --request GET \
    --url "https://gitlab.example.com/api/v4/groups/1/transfer_locations"
```

Exemple de réponse :

```json
[
  {
    "id": 27,
    "web_url": "https://gitlab.example.com/groups/gitlab",
    "name": "GitLab",
    "avatar_url": null,
    "full_name": "GitLab",
    "full_path": "GitLab"
  },
  {
    "id": 31,
    "web_url": "https://gitlab.example.com/groups/foobar",
    "name": "FooBar",
    "avatar_url": null,
    "full_name": "FooBar",
    "full_path": "FooBar"
  }
]
```

#### Transférer un projet vers un groupe {#transfer-a-project-to-a-group}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Transfère un projet vers un autre espace de nommage de groupe. Vous pouvez également utiliser le point de terminaison [transférer un projet vers un nouvel espace de nommage](projects.md#transfer-a-project-to-a-new-namespace).

> [!note]
> Le processus de transfert peut échouer si des packages étiquetés existent dans le dépôt du projet.

Prérequis :

- Vous devez être administrateur de l'instance.

```plaintext
POST /groups/:id/projects/:project_id
```

Paramètres :

| Attribut    | Type           | Obligatoire | Description |
| ------------ | -------------- | -------- | ----------- |
| `id`         | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du groupe cible](rest/_index.md#namespaced-paths). |
| `project_id` | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/4/projects/56"
```

### Inviter des groupes {#invite-groups}

Ces points de terminaison sont utilisés pour les invitations de groupes. Pour plus d'informations, voir [inviter un groupe dans un groupe](../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-group).

#### Créer une invitation de groupe {#create-a-group-invitation}

Crée une invitation de groupe qui ajoute un groupe cible à un groupe spécifié.

```plaintext
POST /groups/:id/share
```

Paramètres :

| Attribut        | Type              | Obligatoire | Description |
|------------------|-------------------|----------|-------------|
| `id`             | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du groupe cible](rest/_index.md#namespaced-paths). |
| `group_id`       | entier           | oui      | L'ID du groupe à inviter. |
| `group_access`   | entier           | oui      | Le `access_level` par défaut à attribuer au groupe invité. Valeurs possibles : `5` (accès minimum), `10` (Guest), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer) ou `50` (Owner). |
| `expires_at`     | date (ISO 8601)   | non       | La date d'expiration de l'invitation du groupe. |
| `member_role_id` | entier           | non       | L'ID d'un [rôle personnalisé](../user/custom_roles/_index.md#assign-a-custom-role-to-an-invited-group) à attribuer au groupe invité. Si défini, `group_access` doit correspondre au rôle par défaut utilisé pour créer le rôle personnalisé. |

Retourne `200` et les détails du groupe en cas de succès.

#### Supprimer une invitation de groupe {#delete-a-group-invitation}

Supprime une invitation de groupe et retire l'accès au groupe cible pour le groupe spécifié.

```plaintext
DELETE /groups/:id/share/:group_id
```

| Attribut  | Type           | Obligatoire | Description |
|------------|----------------|----------|-------------|
| `id`       | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL du groupe cible](rest/_index.md#namespaced-paths). |
| `group_id` | entier        | oui      | L'ID du groupe à désinviter. |

Retourne `204` et aucun contenu en cas de succès.

## Mettre à jour les attributs d'un groupe {#update-group-attributes}

{{< history >}}

- [Disponible globalement](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/183101) dans GitLab 18.0. L'indicateur de fonctionnalité `limit_unique_project_downloads_per_namespace_user` a été supprimé.
- `web_based_commit_signing_enabled` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193928) dans GitLab 18.2 [avec un flag](../administration/feature_flags/_index.md) nommé `use_web_based_commit_signing_enabled`. Désactivé par défaut.
- `allow_personal_snippets` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200575) dans GitLab 18.5 [avec un flag](../administration/feature_flags/_index.md) nommé `allow_personal_snippets_setting`. Désactivé par défaut.
- `allow_personal_snippets` [disponible globalement](https://gitlab.com/gitlab-org/gitlab/-/work_items/583564) dans GitLab 18.9. L'indicateur de fonctionnalité `allow_personal_snippets_setting` a été supprimé.

{{< /history >}}

> [!flag]
> La disponibilité de l'attribut `web_based_commit_signing_enabled` est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible à des fins de test, mais n'est pas prête pour une utilisation en production.

Met à jour les attributs d'un groupe spécifié.

Prérequis :

- Vous devez être administrateur ou avoir le rôle Owner pour le groupe.

```plaintext
PUT /groups/:id
```

| Attribut                                            | Type              | Obligatoire | Description |
|------------------------------------------------------|-------------------|----------|-------------|
| `id`                                                 | entier           | oui      | L'identifiant du groupe. |
| `name`                                               | string            | non       | Le nom du groupe. |
| `path`                                               | string            | non       | Le chemin du groupe. |
| `auto_devops_enabled`                                | boolean           | non       | Par défaut, utilise le pipeline Auto DevOps pour tous les projets de ce groupe. |
| `avatar`                                             | mixed             | non       | Fichier image pour l'avatar du groupe. |
| `default_branch`                                     | string            | non       | Le nom de la [branche par défaut](../user/project/repository/branches/default.md) pour les projets du groupe. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/442298) dans GitLab 16.11. |
| `default_branch_protection`                          | entier           | non       | [Déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/408314) dans GitLab 17.0. Utilisez `default_branch_protection_defaults` à la place. |
| `default_branch_protection_defaults`                 | hash              | non       | [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/408314) dans GitLab 17.0. Pour les options disponibles, voir [Options pour `default_branch_protection_defaults`](#options-for-default_branch_protection_defaults). |
| `description`                                        | string            | non       | La description du groupe. |
| `enabled_git_access_protocol`                        | string            | non       | Protocoles activés pour l'accès Git. Les valeurs autorisées sont : `ssh`, `http` et `all` pour autoriser les deux protocoles. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/436618) dans GitLab 16.9. |
| `emails_disabled`                                    | boolean           | non       | ([Déprécié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127899) dans GitLab 16.5.) Désactiver les notifications par e-mail. Utilisez `emails_enabled` à la place. |
| `emails_enabled`                                     | boolean           | non       | Activer les notifications par e-mail. |
| `lfs_enabled`                                        | boolean           | non       | Activer/désactiver le stockage de fichiers volumineux (LFS) pour les projets de ce groupe. |
| `mentions_disabled`                                  | boolean           | non       | Désactiver la possibilité pour un groupe d'être mentionné. |
| `prevent_sharing_groups_outside_hierarchy`           | boolean           | non       | Voir [Empêcher le partage de groupe en dehors de la hiérarchie du groupe](../user/project/members/sharing_projects_groups.md#prevent-inviting-groups-outside-the-group-hierarchy). Cet attribut est uniquement disponible sur les groupes principaux. |
| `project_creation_level`                             | string            | non       | Déterminer si les développeurs peuvent créer des projets dans le groupe. Peut être `noone` (Personne), `maintainer` (utilisateurs avec le rôle Maintainer), ou `developer` (utilisateurs avec le rôle Developer ou Maintainer). |
| `request_access_enabled`                             | boolean           | non       | Autoriser les utilisateurs à demander l'accès en tant que membre. |
| `require_two_factor_authentication`                  | boolean           | non       | Exiger que tous les utilisateurs de ce groupe configurent l'authentification à deux facteurs. |
| `shared_runners_setting`                             | string            | non       | Voir [Options pour `shared_runners_setting`](#options-for-shared_runners_setting). Activer ou désactiver les runners d'instance pour les sous-groupes et projets d'un groupe. |
| `share_with_group_lock`                              | boolean           | non       | Empêcher le partage d'un projet avec un autre groupe au sein de ce groupe. |
| `step_up_auth_required_oauth_provider`               | string            | non       | Fournisseur OAuth requis pour l'authentification renforcée. Passez une chaîne vide pour désactiver. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/556943) dans GitLab 18.4. Disponible lorsque le feature flag `omniauth_step_up_auth_for_namespace` est activé. |
| `subgroup_creation_level`                            | string            | non       | Autorisé à [créer des sous-groupes](../user/group/subgroups/_index.md#create-a-subgroup). Peut être `owner` (utilisateurs avec le rôle Owner) ou `maintainer` (utilisateurs avec le rôle Maintainer). |
| `two_factor_grace_period`                            | entier           | non       | Délai avant l'application de l'authentification à deux facteurs (en heures). |
| `visibility`                                         | string            | non       | Le niveau de visibilité du groupe. Peut être `private`, `internal` ou `public`. |
| `extra_shared_runners_minutes_limit`                 | entier           | non       | Peut être défini par les administrateurs uniquement. Minutes de calcul supplémentaires pour ce groupe. GitLab Self-Managed, Premium et Ultimate uniquement. |
| `file_template_project_id`                           | entier           | non       | L'ID d'un projet à partir duquel charger des modèles de fichiers personnalisés. Premium et Ultimate uniquement. |
| `membership_lock`                                    | boolean           | non       | Les utilisateurs ne peuvent pas être ajoutés aux projets de ce groupe. Premium et Ultimate uniquement. |
| `prevent_forking_outside_group`                      | boolean           | non       | Lorsqu'il est activé, les utilisateurs ne peuvent pas dupliquer les projets de ce groupe vers des espaces de nommage externes. Premium et Ultimate uniquement. |
| `shared_runners_minutes_limit`                       | entier           | non       | Peut être défini par les administrateurs uniquement. Nombre maximum de minutes de calcul mensuelles pour ce groupe. Peut être `nil` (par défaut ; hérite du paramètre système par défaut), `0` (illimité) ou `> 0`. GitLab Self-Managed, Premium et Ultimate uniquement. |
| `unique_project_download_limit`                      | entier           | non       | Nombre maximum de projets uniques qu'un utilisateur peut télécharger au cours de la période de temps spécifiée avant d'être banni. Disponible uniquement sur les groupes principaux. Défaut : 0, Maximum : 10 000. Ultimate uniquement. |
| `unique_project_download_limit_interval_in_seconds`  | entier           | non       | Période de temps pendant laquelle un utilisateur peut télécharger un nombre maximum de projets avant d'être banni. Disponible uniquement sur les groupes principaux. Défaut : 0, Maximum : 864 000 secondes (10 jours). Ultimate uniquement. |
| `unique_project_download_limit_allowlist`            | tableau de chaînes  | non       | Liste des noms d'utilisateur exclus de la limite de téléchargement de projets uniques. Disponible uniquement sur les groupes principaux. Défaut : `[]`, Maximum : 100 noms d'utilisateur. Ultimate uniquement. |
| `unique_project_download_limit_alertlist`            | tableau d'entiers | non       | Liste des ID d'utilisateur qui reçoivent un e-mail lorsque la limite de téléchargement de projets uniques est dépassée. Disponible uniquement sur les groupes principaux. Défaut : `[]`, Maximum : 100 ID d'utilisateur. Ultimate uniquement. |
| `auto_ban_user_on_excessive_projects_download`       | boolean           | non       | Lorsqu'il est activé, les utilisateurs sont automatiquement bannis du groupe lorsqu'ils téléchargent plus que le nombre maximum de projets uniques spécifié par `unique_project_download_limit` et `unique_project_download_limit_interval_in_seconds`. Ultimate uniquement. |
| `ip_restriction_ranges`                              | string      | non       | Liste séparée par des virgules d'adresses IP ou de masques de sous-réseau pour restreindre l'accès au groupe. Premium et Ultimate uniquement. |
| `allowed_email_domains_list`                         | string      | non       | Liste séparée par des virgules de domaines d'adresses e-mail pour autoriser l'accès au groupe. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/351494) dans la version 17.4. GitLab Premium et Ultimate uniquement. |
| `wiki_access_level`                                  | string            | non       | Le niveau d'accès au wiki. Peut être `disabled`, `private` ou `enabled`. Premium et Ultimate uniquement. |
| `duo_availability`                                   | string | non | Paramètre de disponibilité de GitLab Duo. Les valeurs valides sont : `default_on`, `default_off`, `never_on`. Remarque : Dans l'interface utilisateur, `never_on` s'affiche comme « Always Off ». |
| `experiment_features_enabled`                        | boolean | non | Activer les fonctionnalités expérimentales pour ce groupe. |
| `math_rendering_limits_enabled`                      | boolean           | non       | Indique si les limites de rendu mathématique sont utilisées pour ce groupe. |
| `lock_math_rendering_limits_enabled`                 | boolean           | non       | Indique si les limites de rendu mathématique sont verrouillées pour tous les groupes descendants. |
| `duo_features_enabled`                               | boolean           | non       | Indique si les fonctionnalités GitLab Duo sont activées pour ce groupe. [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144931) dans GitLab 16.10. GitLab Self-Managed, Premium et Ultimate uniquement. |
| `lock_duo_features_enabled`                          | boolean           | non       | Indique si le paramètre d'activation des fonctionnalités GitLab Duo est appliqué à tous les sous-groupes. [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144931) dans GitLab 16.10. GitLab Self-Managed, Premium et Ultimate uniquement. |
| `max_artifacts_size`                                 | entier           | Non       | La taille maximale des fichiers en mégaoctets pour les artefacts de job individuels. |
| `web_based_commit_signing_enabled`                  | boolean           | Non       | Active la signature de commit par le Web pour les commits créés depuis l'interface utilisateur GitLab. Disponible uniquement pour les groupes principaux sur GitLab.com. Lorsqu'il est activé pour un groupe, s'applique à tous les projets du groupe. |
| `only_allow_merge_if_pipeline_succeeds`             | boolean           | non       | Autoriser uniquement la fusion des merge requests si le pipeline réussit. Lorsqu'il est activé pour un groupe, s'applique à tous les projets du groupe. Premium et Ultimate uniquement. |
| `allow_merge_on_skipped_pipeline`                   | boolean           | non       | Autoriser la fusion des merge requests lorsque le pipeline est ignoré. S'applique uniquement lorsque `only_allow_merge_if_pipeline_succeeds` est `true`. Premium et Ultimate uniquement. |
| `only_allow_merge_if_all_discussions_are_resolved`  | boolean           | non       | Autoriser uniquement la fusion des merge requests lorsque toutes les discussions sont résolues. Lorsqu'il est activé pour un groupe, s'applique à tous les projets du groupe. Premium et Ultimate uniquement. |
| `allow_personal_snippets`                           | boolean           | non       | Autoriser les utilisateurs enterprise de ce groupe à créer des extraits de code personnels. Lorsqu'il est désactivé, les utilisateurs enterprise ne peuvent pas créer d'extraits de code dans leur espace de nommage personnel. |

> [!note]
> Les attributs `projects` et `shared_projects` dans la réponse sont dépréciés et leur [suppression est prévue dans l'API v5](https://gitlab.com/gitlab-org/gitlab/-/issues/213797). Pour obtenir les détails de tous les projets d'un groupe, utilisez soit l'endpoint [listant les projets d'un groupe](#list-projects), soit l'endpoint [listant les projets partagés d'un groupe](#list-shared-projects).

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5?name=Experimental"
```

Cet endpoint renvoie un maximum de 100 projets et projets partagés. Pour obtenir les détails de tous les projets d'un groupe, utilisez plutôt le [point de terminaison de liste des projets d'un groupe](#list-projects).

Exemple de réponse :

```json
{
  "id": 5,
  "name": "Experimental",
  "path": "h5bp",
  "description": "foo",
  "visibility": "internal",
  "avatar_url": null,
  "web_url": "http://gitlab.example.com/groups/h5bp",
  "request_access_enabled": false,
  "repository_storage": "default",
  "full_name": "Foobar Group",
  "full_path": "h5bp",
  "file_template_project_id": 1,
  "parent_id": null,
  "enabled_git_access_protocol": "all",
  "created_at": "2020-01-15T12:36:29.590Z",
  "prevent_sharing_groups_outside_hierarchy": false,
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "allow_personal_snippets": true,
  "projects": [ // Deprecated and will be removed in API v5
    {
      "id": 9,
      "description": "foo",
      "default_branch": "main",
      "tag_list": [], //deprecated, use `topics` instead
      "topics": [],
      "public": false,
      "archived": false,
      "visibility": "internal",
      "ssh_url_to_repo": "git@gitlab.example.com/html5-boilerplate.git",
      "http_url_to_repo": "http://gitlab.example.com/h5bp/html5-boilerplate.git",
      "web_url": "http://gitlab.example.com/h5bp/html5-boilerplate",
      "name": "Html5 Boilerplate",
      "name_with_namespace": "Experimental / Html5 Boilerplate",
      "path": "html5-boilerplate",
      "path_with_namespace": "h5bp/html5-boilerplate",
      "issues_enabled": true,
      "merge_requests_enabled": true,
      "wiki_enabled": true,
      "jobs_enabled": true,
      "snippets_enabled": true,
      "created_at": "2016-04-05T21:40:50.169Z",
      "last_activity_at": "2016-04-06T16:52:08.432Z",
      "shared_runners_enabled": true,
      "creator_id": 1,
      "namespace": {
        "id": 5,
        "name": "Experimental",
        "path": "h5bp",
        "kind": "group"
      },
      "avatar_url": null,
      "star_count": 1,
      "forks_count": 0,
      "open_issues_count": 3,
      "public_jobs": true,
      "shared_with_groups": [],
      "request_access_enabled": false
    }
  ],
  "ip_restriction_ranges": null,
  "math_rendering_limits_enabled": true,
  "lock_math_rendering_limits_enabled": false
}
```

L'attribut `prevent_sharing_groups_outside_hierarchy` est présent dans la réponse uniquement pour les groupes principaux.

Les utilisateurs de [GitLab Premium ou Ultimate](https://about.gitlab.com/pricing/) voient également les attributs `wiki_access_level`, `duo_features_enabled`, `lock_duo_features_enabled`, `duo_availability` et `experiment_features_enabled`.

### Options pour `shared_runners_setting` {#options-for-shared_runners_setting}

L'attribut `shared_runners_setting` détermine si les runners d'instance sont activés pour les sous-groupes et projets d'un groupe.

| Valeur                        | Description |
|------------------------------|-------------|
| `enabled`                    | Active les runners d'instance pour tous les projets et sous-groupes de ce groupe. |
| `disabled_and_overridable`   | Désactive les runners d'instance pour tous les projets et sous-groupes de ce groupe, mais permet aux sous-groupes de remplacer ce paramètre. |
| `disabled_and_unoverridable` | Désactive les runners d'instance pour tous les projets et sous-groupes de ce groupe, et empêche les sous-groupes de remplacer ce paramètre. |
| `disabled_with_override`     | (Déprécié. Utilisez `disabled_and_overridable`) Désactive les runners d'instance pour tous les projets et sous-groupes de ce groupe, mais permet aux sous-groupes de remplacer ce paramètre. |

## Mettre à jour les avatars de groupe {#update-group-avatars}

Mettre à jour les avatars de groupe.

### Télécharger un avatar de groupe {#download-a-group-avatar}

Obtenir un avatar de groupe. Cet endpoint est accessible sans authentification si le groupe est accessible publiquement.

```plaintext
GET /groups/:id/avatar
```

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | ID du groupe. |

Exemple :

```shell
curl --header "PRIVATE-TOKEN: $GITLAB_LOCAL_TOKEN" \
  --remote-header-name \
  --remote-name \
  --url "https://gitlab.example.com/api/v4/groups/4/avatar"
```

### Téléverser un avatar de groupe {#upload-a-group-avatar}

Pour téléverser un fichier avatar depuis votre système de fichiers, utilisez l'argument `--form`. Cela force curl à publier des données en utilisant l'en-tête `Content-Type: multipart/form-data`. Le paramètre `file=` doit pointer vers un fichier sur votre système de fichiers et être précédé de `@`. Par exemple :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "avatar=@/tmp/example.png" \
  --url "https://gitlab.example.com/api/v4/groups/22"
```

### Supprimer un avatar de groupe {#remove-a-group-avatar}

Pour supprimer un avatar de groupe, utilisez une valeur vide pour l'attribut `avatar`.

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "avatar=" \
  --url "https://gitlab.example.com/api/v4/groups/22"
```

## Synchroniser un groupe avec LDAP {#sync-a-group-with-ldap}

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Synchronise un groupe spécifié avec son groupe LDAP lié.

Prérequis :

- Vous devez être administrateur ou avoir le rôle Owner pour le groupe.

```plaintext
POST /groups/:id/ldap_sync
```

| Attribut | Type                | Obligatoire | Description                            |
| --------- | ------------------- | -------- | -------------------------------------- |
| `id`      | entier ou chaîne   | Oui      | L'ID ou le chemin encodé en URL d'un groupe. |

## Gestion de l'inventaire des identifiants {#credentials-inventory-management}

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/16343) dans GitLab 18.6 [avec un indicateur](../administration/feature_flags/_index.md) nommé `manage_pat_by_group_owners_ready`. Désactivé par défaut.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/578133) dans GitLab 18.7. L'indicateur de fonctionnalité `manage_pat_by_group_owners_ready` a été supprimé.

{{< /history >}}

Afficher, révoquer et renouveler les identifiants des utilisateurs enterprise sur GitLab.com.

Prérequis :

- Vous devez avoir le rôle Owner pour le groupe.

### Lister tous les jetons d'accès personnels pour un groupe {#list-all-personal-access-tokens-for-a-group}

Liste tous les jetons d'accès personnels associés aux utilisateurs enterprise d'un groupe principal.

```plaintext
GET /groups/:id/manage/personal_access_tokens
```

| Attribut          | Type                | Obligatoire | Description |
| ------------------ | ------------------- | -------- | ----------- |
| `id`               | entier ou chaîne   | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un groupe. |
| `created_after`    | datetime (ISO 8601) | Non       | Si défini, retourne les jetons créés après l'heure spécifiée. |
| `created_before`   | datetime (ISO 8601) | Non       | Si défini, retourne les jetons créés avant l'heure spécifiée. |
| `last_used_after`  | datetime (ISO 8601) | Non       | Si défini, retourne les jetons utilisés pour la dernière fois après l'heure spécifiée. |
| `last_used_before` | datetime (ISO 8601) | Non       | Si défini, retourne les jetons utilisés pour la dernière fois avant l'heure spécifiée. |
| `revoked`          | boolean             | Non       | Si `true`, retourne uniquement les jetons révoqués. |
| `search`           | string              | Non       | Si défini, retourne les jetons qui incluent la valeur spécifiée dans le nom. |
| `state`            | string              | Non       | Si défini, retourne les jetons avec l'état spécifié. Valeurs possibles : `active` et `inactive`. |
| `sort`             | string              | Non       | Si défini, trie les résultats selon la valeur spécifiée. Valeurs possibles : `created_asc`, `created_desc`, `expires_asc`, `expires_desc`, `last_used_asc`, `last_used_desc`, `name_asc`, `name_desc`. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <group_owner_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/manage/personal_access_tokens"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "Test Token",
    "revoked": false,
    "created_at": "2020-07-23T14:31:47.729Z",
    "description": "Test Token description",
    "scopes": [
        "api"
    ],
    "user_id": 3,
    "last_used_at": "2021-10-06T17:58:37.550Z",
    "active": true,
    "expires_at": "2025-11-08"
  }
]
```

### Lister tous les jetons d'accès de groupe et de projet pour un groupe {#list-all-group-and-project-access-tokens-for-a-group}

Liste tous les jetons d'accès de groupe et de projet associés à un groupe principal.

```plaintext
GET /groups/:id/manage/resource_access_tokens
```

| Attribut          | Type                | Obligatoire | Description |
| ------------------ | ------------------- | -------- | ----------- |
| `id`               | entier ou chaîne   | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un groupe. |
| `created_after`    | datetime (ISO 8601) | Non       | Si défini, retourne les jetons créés après l'heure spécifiée. |
| `created_before`   | datetime (ISO 8601) | Non       | Si défini, retourne les jetons créés avant l'heure spécifiée. |
| `last_used_after`  | datetime (ISO 8601) | Non       | Si défini, retourne les jetons utilisés pour la dernière fois après l'heure spécifiée. |
| `last_used_before` | datetime (ISO 8601) | Non       | Si défini, retourne les jetons utilisés pour la dernière fois avant l'heure spécifiée. |
| `revoked`          | boolean             | Non       | Si `true`, retourne uniquement les jetons révoqués. |
| `search`           | string              | Non       | Si défini, retourne les jetons qui incluent la valeur spécifiée dans le nom. |
| `state`            | string              | Non       | Si défini, retourne les jetons avec l'état spécifié. Valeurs possibles : `active` et `inactive`. |
| `sort`             | string              | Non       | Si défini, trie les résultats selon la valeur spécifiée. Valeurs possibles : `created_asc`, `created_desc`, `expires_asc`, `expires_desc`, `last_used_asc`, `last_used_desc`, `name_asc`, `name_desc`. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <group_owner_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/manage/resource_access_tokens"
```

Exemple de réponse :

```json
[
  {
    "id": 12767703,
    "name": "Test Group Token",
    "revoked": false,
    "created_at": "2025-01-07T00:25:02.128Z",
    "description": "",
    "scopes": [
        "read_registry"
    ],
    "user_id": 25365147,
    "last_used_at": null,
    "active": true,
    "expires_at": "2025-06-19",
    "access_level": 10,
    "resource_type": "group",
    "resource_id": 77449520
  }
]
```

### Lister toutes les clés SSH pour un groupe {#list-all-ssh-keys-for-a-group}

Liste toutes les clés publiques SSH associées aux utilisateurs enterprise d'un groupe principal.

```plaintext
GET /groups/:id/manage/ssh_keys
```

| Attribut        | Type                | Obligatoire | Description |
| ---------------- | ------------------- | -------- | ----------- |
| `id`             | entier ou chaîne   | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) d'un groupe. |
| `created_after`  | datetime (ISO 8601) | Non       | Si défini, retourne les clés SSH créées après le temps spécifié. |
| `created_before` | datetime (ISO 8601) | Non       | Si défini, retourne les clés SSH créées avant le temps spécifié. |
| `expires_before` | datetime (ISO 8601) | Non       | Si défini, retourne les clés SSH qui expirent avant le temps spécifié. |
| `expires_after`  | datetime (ISO 8601) | Non       | Si défini, retourne les clés SSH qui expirent après le temps spécifié. |

```shell
curl --header "PRIVATE-TOKEN: <group_owner_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/manage/ssh_keys"
```

Exemple de réponse :

```json
[
  {
    "id":3,
    "title":"Sample key 3",
    "created_at":"2024-12-23T05:40:11.891Z",
    "expires_at":null,
    "last_used_at":"2024-12-23T05:40:11.891Z",
    "usage_type":"auth_and_signing",
    "user_id":3
  }
]
```

### Révoquer un jeton d'accès personnel pour un utilisateur enterprise {#revoke-a-personal-access-token-for-an-enterprise-user}

Révoque un jeton d'accès personnel spécifié pour un utilisateur enterprise.

```plaintext
DELETE groups/:id/manage/personal_access_tokens/:id
```

| Attribut | Type    | Obligatoire | Description         |
|-----------|---------|----------|---------------------|
| `id` | entier ou chaîne | Oui | ID d'un jeton d'accès personnel ou le mot-clé `self`. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/manage/personal_access_tokens/<personal_access_token_id>"
```

En cas de succès, retourne `204: No Content`.

Autres réponses possibles :

- `400: Bad Request` si la révocation n'a pas réussi.
- `401: Unauthorized` si le jeton d'accès est invalide.
- `403: Forbidden` si le jeton d'accès ne dispose pas des permissions requises.

### Révoquer un jeton d'accès de groupe ou de projet pour un utilisateur enterprise {#revoke-a-group-or-project-access-token-for-an-enterprise-user}

Révoque un jeton d'accès de groupe ou de projet spécifié pour un utilisateur enterprise associé au groupe principal.

```plaintext
DELETE groups/:id/manage/resource_access_tokens/:id
```

| Attribut | Type    | Obligatoire | Description         |
|-----------|---------|----------|---------------------|
| `id` | entier ou chaîne | Oui | ID d'un jeton d'accès à une ressource ou le mot-clé `self`. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/manage/resource_access_tokens/<personal_access_token_id>"
```

En cas de succès, retourne `204: No Content`.

Autres réponses possibles :

- `400: Bad Request` si la révocation n'a pas réussi.
- `401: Unauthorized` si le jeton d'accès est invalide.
- `403: Forbidden` si le jeton d'accès ne dispose pas des permissions requises.

### Supprimer une clé SSH pour un utilisateur enterprise {#delete-an-ssh-key-for-an-enterprise-user}

Supprime une clé publique SSH spécifiée pour un utilisateur enterprise associé au groupe principal.

```plaintext
DELETE /groups/:id/manage/ssh_keys/:key_id
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `key_id`  | entier | Oui      | ID de la clé existante.  |

En cas de succès, retourne `204: No Content`.

Autres réponses possibles :

- `400: Bad Request` si la clé SSH n'a pas été supprimée avec succès.
- `401: Unauthorized` si la clé SSH est invalide.
- `403: Forbidden` si l'utilisateur ne dispose pas des permissions requises.

### Renouveler un jeton d'accès personnel pour un utilisateur enterprise {#rotate-a-personal-access-token-for-an-enterprise-user}

Renouvelle un jeton d'accès personnel spécifié pour un utilisateur enterprise associé au groupe principal. Cela révoque le jeton précédent et crée un nouveau jeton qui expire après une semaine.

```plaintext
POST groups/:id/manage/personal_access_tokens/:id/rotate
```

| Attribut | Type      | Obligatoire | Description         |
|-----------|-----------|----------|---------------------|
| `id` | entier ou chaîne | Oui      | ID d'un jeton d'accès personnel ou le mot-clé `self`. |
| `expires_at` | date   | Non       | Date d'expiration du jeton d'accès au format ISO (`YYYY-MM-DD`). La date doit être inférieure ou égale à un an à compter de la date de renouvellement. Si non défini, le jeton expire après une semaine. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/manage/personal_access_tokens/<personal_access_token_id>/rotate"
```

Exemple de réponse :

```json
{
    "id": 42,
    "name": "Rotated Token",
    "revoked": false,
    "created_at": "2023-08-01T15:00:00.000Z",
    "description": "Test Token description",
    "scopes": ["api"],
    "user_id": 1337,
    "last_used_at": null,
    "active": true,
    "expires_at": "2023-08-15",
    "token": "s3cr3t"
}
```

En cas de succès, retourne `200: OK`.

Autres réponses possibles :

- `400: Bad Request` si la rotation n'a pas réussi.
- `401: Unauthorized` si l'une des conditions suivantes est vraie :
  - Le jeton n'existe pas.
  - Le jeton a expiré.
  - Le jeton a été révoqué.
  - Vous n'avez pas accès au jeton spécifié.
- `403: Forbidden` si le jeton n'est pas autorisé à effectuer sa propre rotation.
- `404: Not Found` si l'utilisateur possède le rôle Owner, mais que le jeton n'existe pas.
- `405: Method Not Allowed` si le jeton n'est pas un jeton d'accès personnel.

### Effectuer la rotation d'un jeton d'accès au groupe ou au projet pour un utilisateur d'entreprise {#rotate-a-group-or-project-access-token-for-an-enterprise-user}

Effectue la rotation d'un jeton d'accès au groupe ou au projet spécifié pour un utilisateur d'entreprise associé au groupe principal. Cela révoque le jeton précédent et crée un nouveau jeton qui expire après une semaine.

```plaintext
POST groups/:id/manage/resource_access_tokens/:id/rotate
```

| Attribut | Type      | Obligatoire | Description         |
|-----------|-----------|----------|---------------------|
| `id` | entier ou chaîne | Oui      | ID d'un jeton d'accès personnel ou le mot-clé `self`. |
| `expires_at` | date   | Non       | Date d'expiration du jeton d'accès au format ISO (`YYYY-MM-DD`). La date doit être inférieure ou égale à un an à compter de la date de renouvellement. Si non défini, le jeton expire après une semaine. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/manage/resource_access_tokens/<resource_access_token_id>/rotate"
```

Exemple de réponse :

```json
{
    "id": 42,
    "name": "Rotated Token",
    "revoked": false,
    "created_at": "2023-08-01T15:00:00.000Z",
    "description": "Test Token description",
    "scopes": ["api"],
    "user_id": 1337,
    "last_used_at": null,
    "active": true,
    "expires_at": "2023-08-15",
    "token": "s3cr3t"
}
```

En cas de succès, retourne `200: OK`.

Autres réponses possibles :

- `400: Bad Request` si la rotation n'a pas réussi.
- `401: Unauthorized` si l'une des conditions suivantes est vraie :
  - Le jeton n'existe pas.
  - Le jeton a expiré.
  - Le jeton a été révoqué.
  - Vous n'avez pas accès au jeton spécifié.
- `403: Forbidden` si le jeton n'est pas autorisé à effectuer sa propre rotation ou si le jeton n'est pas un jeton d'utilisateur bot.
- `404: Not Found` si l'utilisateur possède le rôle Owner, mais que le jeton n'existe pas.
