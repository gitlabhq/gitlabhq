---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des duplications de projets
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les duplications de projets GitLab. Pour plus d'informations, consultez [les duplications](../user/project/repository/forking_workflow.md).

## Créer une duplication d'un projet {#create-a-fork-of-a-project}

Créez une duplication du projet spécifié.

Prérequis :

- Vous devez être authentifié.

L'opération de duplication d'un projet est asynchrone et est effectuée dans un job d'arrière-plan. La requête retourne immédiatement. Pour déterminer si la duplication du projet est terminée, interrogez le `import_status` pour le nouveau projet.

```plaintext
POST /projects/:id/fork
```

| Attribut                | Type              | Obligatoire | Description |
|:-------------------------|:------------------|:---------|:------------|
| `id`                     | entier ou chaîne | Oui      | L'identifiant ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `branches`               | string            | Non       | Branches à dupliquer (vide pour toutes les branches). |
| `description`            | string            | Non       | La description assignée au projet résultant après la duplication. |
| `mr_default_target_self` | boolean           | Non       | Pour les projets dupliqués, ciblez les merge requests vers ce projet. Si `false`, la cible est le projet en amont. |
| `name`                   | string            | Non       | Le nom assigné au projet résultant après la duplication. |
| `namespace_id`           | entier           | Non       | L'identifiant de l'espace de nommage vers lequel le projet est dupliqué. |
| `namespace_path`         | string            | Non       | Le chemin de l'espace de nommage vers lequel le projet est dupliqué. |
| `namespace`              | entier ou chaîne | Non       | _(Obsolète)_ L'identifiant ou le chemin de l'espace de nommage vers lequel le projet est dupliqué. |
| `path`                   | string            | Non       | Le chemin assigné au projet résultant après la duplication. |
| `visibility`             | string            | Non       | Le [niveau de visibilité](projects.md#project-visibility-level) assigné au projet résultant après la duplication. |

> [!note]
> Lorsque vous utilisez un compte de service pour dupliquer un projet, vous devez fournir soit `namespace_id` soit `namespace_path`. Les comptes de service ne peuvent pas dupliquer des projets vers leur espace de nommage personnel. Pour plus d'informations, consultez [ajouter un compte de service à un groupe ou un projet](../user/profile/service_accounts.md#add-a-service-account-to-a-group-or-project).

## Lister toutes les duplications d'un projet {#list-all-forks-of-a-project}

Listez toutes les duplications du projet spécifié. Retourne uniquement les duplications qui vous sont accessibles.

```plaintext
GET /projects/:id/forks
```

Attributs pris en charge :

| Attribut                     | Type              | Obligatoire | Description |
|:------------------------------|:------------------|:---------|:------------|
| `id`                          | entier ou chaîne | Oui      | L'identifiant ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `archived`                    | boolean           | Non       | Limiter par statut archivé. |
| `membership`                  | boolean           | Non       | Limiter aux projets dont l'utilisateur actuel est membre. |
| `min_access_level`            | entier           | Non       | Limiter aux projets pour lesquels l'utilisateur actuel dispose au moins du niveau d'accès spécifié. Valeurs possibles :  `5` (accès minimum), `10` (Guest), `15` (Planificateur), `20` (Reporter), `25` (Responsable sécurité), `30` (Developer), `40` (Maintainer) ou `50` (Owner). |
| `order_by`                    | string            | Non       | Retourner les projets triés par champs `id`, `name`, `path`, `created_at`, `updated_at`, `star_count` ou `last_activity_at`. La valeur par défaut est `created_at`. |
| `owned`                       | boolean           | Non       | Limiter aux projets explicitement possédés par l'utilisateur actuel. |
| `search`                      | string            | Non       | Retourner la liste des projets correspondant aux critères de recherche. |
| `simple`                      | boolean           | Non       | Retourner uniquement les champs limités pour chaque projet. Sans authentification, cette opération est sans effet ; seuls les champs simples sont retournés. |
| `sort`                        | string            | Non       | Retourner les projets triés dans l'ordre `asc` ou `desc`. La valeur par défaut est `desc`. |
| `starred`                     | boolean           | Non       | Limiter aux projets mis en favoris par l'utilisateur actuel. |
| `statistics`                  | boolean           | Non       | Inclure les statistiques du projet. Disponible uniquement pour les utilisateurs avec le rôle Reporter, Developer, Maintainer ou Owner. |
| `updated_after`               | datetime          | Non       | Limiter les résultats aux projets mis à jour après le moment spécifié. Format : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) dans GitLab 15.10. |
| `updated_before`              | datetime          | Non       | Limiter les résultats aux projets mis à jour avant le moment spécifié. Format : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) dans GitLab 15.10. |
| `visibility`                  | string            | Non       | Limiter par visibilité `public`, `internal` ou `private`. |
| `with_custom_attributes`      | boolean           | Non       | Inclure les [attributs personnalisés](custom_attributes.md) dans la réponse. _(administrateurs uniquement)_ |
| `with_issues_enabled`         | boolean           | Non       | Limiter par fonctionnalité des tickets activée. |
| `with_merge_requests_enabled` | boolean           | Non       | Limiter par fonctionnalité des merge requests activée. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/forks"
```

Exemples de réponses :

```json
[
  {
    "id": 3,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "internal",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
    "web_url": "http://example.com/diaspora/diaspora-project-site",
    "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora project"
    ],
    "topics": [
      "example",
      "disapora project"
    ],
    "name": "Diaspora Project Site",
    "name_with_namespace": "Diaspora / Diaspora Project Site",
    "path": "diaspora-project-site",
    "path_with_namespace": "diaspora/diaspora-project-site",
    "repository_object_format": "sha1",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora"
    },
    "import_status": "none",
    "archived": true,
    "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 1,
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  }
]
```

## Créer une relation de duplication {#create-a-fork-relationship}

Créez une relation de duplication entre deux projets spécifiés.

Prérequis :

- Vous devez être administrateur ou avoir le rôle Owner sur le projet.

```plaintext
POST /projects/:id/fork/:forked_from_id
```

Attributs pris en charge :

| Attribut        | Type              | Obligatoire | Description |
|:-----------------|:------------------|:---------|:------------|
| `forked_from_id` | ID                | Oui      | L'identifiant du projet depuis lequel la duplication a été effectuée. |
| `id`             | entier ou chaîne | Oui      | L'identifiant ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |

## Supprimer une relation de duplication {#delete-a-fork-relationship}

Supprimez une relation de duplication entre deux projets spécifiés.

Prérequis :

- Vous devez être administrateur ou avoir le rôle Owner sur le projet.

```plaintext
DELETE /projects/:id/fork
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | entier ou chaîne | Oui      | L'identifiant ou le [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
