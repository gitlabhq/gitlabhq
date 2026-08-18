---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Utilisez ces outils pour interagir avec GitLab via le serveur MCP GitLab.
title: Outils du serveur MCP GitLab
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : version bêta

{{< /details >}}

> [!warning]
> Pour donner votre avis sur cette fonctionnalité, laissez un commentaire sur [l'ticket 561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564).

Le serveur MCP GitLab fournit un ensemble d'outils qui s'intègrent à vos workflows GitLab existants. Vous pouvez utiliser ces outils pour interagir directement avec GitLab et effectuer des opérations GitLab courantes.

## `get_mcp_server_version` {#get_mcp_server_version}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200105) dans GitLab 18.3.

{{< /history >}}

Retourne la version actuelle du serveur MCP GitLab.

Exemple :

```plaintext
What version of the GitLab MCP server am I connected to?
```

## `create_issue` {#create_issue}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055) dans GitLab 18.4.

{{< /history >}}

Crée un nouveau ticket dans un projet GitLab.

| Paramètre      | Type              | Obligatoire | Description |
|----------------|-------------------|----------|-------------|
| `id`           | chaîne            | Oui      | ID ou chemin encodé en URL du projet. |
| `title`        | chaîne            | Oui      | Titre du ticket. |
| `description`  | chaîne            | Non       | Description du ticket. |
| `assignee_ids` | array of integers | Non       | Tableau des ID des utilisateurs assignés. |
| `milestone_id` | integer           | Non       | ID du jalon. |
| `labels`       | array of strings  | Non       | Tableau des noms de label. |
| `confidential` | booléen           | Non       | Définit le ticket comme confidentiel. La valeur par défaut est `false`. |
| `epic_id`      | integer           | Non       | ID de l'epic lié. |

Exemple :

```plaintext
Create a new issue titled "Fix login bug" in project 123 with description
"Users cannot log in with special characters in password"
```

## `get_issue` {#get_issue}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201838) dans GitLab 18.4.

{{< /history >}}

Récupère des informations détaillées sur un ticket GitLab spécifique.

| Paramètre   | Type    | Obligatoire | Description |
|-------------|---------|----------|-------------|
| `id`        | chaîne  | Oui      | ID ou chemin encodé en URL du projet. |
| `issue_iid` | integer | Oui      | ID interne du ticket. |

Exemple :

```plaintext
Get details for issue 42 in project 123
```

## `create_merge_request` {#create_merge_request}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/571243) dans GitLab 18.5.
- `assignee_ids`, `reviewer_ids`, `description`, `labels` et `milestone_id` [ajoutés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217458) dans GitLab 18.8.

{{< /history >}}

Crée une merge request dans un projet GitLab.

| Paramètre           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | chaîne            | Oui      | ID ou chemin encodé en URL du projet. |
| `title`             | chaîne            | Oui      | Titre de la merge request. |
| `source_branch`     | chaîne            | Oui      | Nom de la branche source. |
| `target_branch`     | chaîne            | Oui      | Nom de la branche cible. |
| `target_project_id` | integer           | Non       | ID du projet cible. |
| `assignee_ids`      | array of integers | Non       | Tableau des ID des assignés de la merge request. Définir sur `0` ou une valeur vide pour retirer tous les assignés. |
| `reviewer_ids`      | array of integers | Non       | Tableau des ID des relecteurs de la merge request. Définir sur `0` ou une valeur vide pour retirer tous les relecteurs. |
| `description`       | chaîne            | Non       | Description de la merge request. |
| `labels`            | array of strings  | Non       | Tableau des noms de label. Définir sur une chaîne vide pour retirer tous les labels. |
| `milestone_id`      | integer           | Non       | ID du jalon. |

Exemple :

```plaintext
Create a merge request in project gitlab-org/gitlab titled "Bug fix broken specs"
from branch "fix/specs-broken" into "master" and enable squash
```

## `get_merge_request` {#get_merge_request}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201838) dans GitLab 18.4.

{{< /history >}}

Récupère des informations détaillées sur une merge request GitLab spécifique.

| Paramètre           | Type    | Obligatoire | Description |
|---------------------|---------|----------|-------------|
| `id`                | chaîne  | Oui      | ID ou chemin encodé en URL du projet. |
| `merge_request_iid` | integer | Oui      | ID interne de la merge request. |

Exemple :

```plaintext
Get details for merge request 15 in project gitlab-org/gitlab
```

## `get_merge_request_commits` {#get_merge_request_commits}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055) dans GitLab 18.4.

{{< /history >}}

Récupère la liste des commits d'une merge request GitLab spécifique.

| Paramètre           | Type    | Obligatoire | Description |
|---------------------|---------|----------|-------------|
| `id`                | chaîne  | Oui      | ID ou chemin encodé en URL du projet. |
| `merge_request_iid` | integer | Oui      | ID interne de la merge request. |
| `per_page`          | integer | Non       | Nombre de commits par page. |
| `page`              | integer | Non       | Numéro de page actuel. |

Exemple :

```plaintext
Show me all commits in merge request 42 from project 123
```

## `get_merge_request_diffs` {#get_merge_request_diffs}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055) dans GitLab 18.4.

{{< /history >}}

Récupère les diffs d'une merge request GitLab spécifique.

| Paramètre           | Type    | Obligatoire | Description |
|---------------------|---------|----------|-------------|
| `id`                | chaîne  | Oui      | ID ou chemin encodé en URL du projet. |
| `merge_request_iid` | integer | Oui      | ID interne de la merge request. |
| `per_page`          | integer | Non       | Nombre de diffs par page. |
| `page`              | integer | Non       | Numéro de page actuel. |

Exemple :

```plaintext
What files were changed in merge request 25 in the gitlab project?
```

## `get_merge_request_pipelines` {#get_merge_request_pipelines}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055) dans GitLab 18.4.

{{< /history >}}

Récupère les pipelines d'une merge request GitLab spécifique.

| Paramètre           | Type    | Obligatoire | Description |
|---------------------|---------|----------|-------------|
| `id`                | chaîne  | Oui      | ID ou chemin encodé en URL du projet. |
| `merge_request_iid` | integer | Oui      | ID interne de la merge request. |

Exemple :

```plaintext
Show me all pipelines for merge request 42 in project gitlab-org/gitlab
```

## `create_merge_request_note` {#create_merge_request_note}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/597494) dans GitLab 19.2.

{{< /history >}}

Ajoute un commentaire ou une réponse à une discussion sur une merge request GitLab en tant qu'utilisateur authentifié.

| Paramètre           | Type    | Obligatoire | Description |
|---------------------|---------|----------|-------------|
| `url`               | chaîne  | Non       | URL de la merge request GitLab. Obligatoire si `project_id` et `merge_request_iid` sont manquants. |
| `project_id`        | chaîne  | Non       | ID ou chemin encodé en URL du projet. Obligatoire si `url` est manquant. |
| `merge_request_iid` | integer | Non       | ID interne de la merge request. Obligatoire si `url` est manquant. |
| `body`              | chaîne  | Oui      | Contenu de la note. Les lignes ne peuvent pas commencer par `/` pour éviter de déclencher des actions rapides (par exemple, `/merge`). |
| `discussion_id`     | chaîne  | Non       | ID global de la discussion à laquelle répondre (au format `gid://gitlab/Discussion/<id>`). Si absent, crée une nouvelle note de niveau supérieur. |

Exemple :

```plaintext
Reply "Thanks, fixed in the latest push" to merge request 42 in project gitlab-org/gitlab
```

## `get_merge_request_notes` {#get_merge_request_notes}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/597494) dans GitLab 19.2.

{{< /history >}}

Récupère les notes (commentaires et notes système) d'une merge request GitLab spécifique.

| Paramètre           | Type    | Obligatoire | Description                                                                                    |
|---------------------|---------|----------|--------------------------------------------------------------------------------------------------|
| `url`               | chaîne  | Non       | URL de la merge request GitLab. Obligatoire si `project_id` et `merge_request_iid` sont manquants.   |
| `project_id`        | chaîne  | Non       | ID ou chemin encodé en URL du projet. Obligatoire si `url` est manquant.                           |
| `merge_request_iid` | integer | Non       | ID interne de la merge request. Obligatoire si `url` est manquant.                                |
| `after`             | chaîne  | Non       | Curseur pour la pagination vers l'avant.                                                                 |
| `before`            | chaîne  | Non       | Curseur pour la pagination vers l'arrière.                                                                |
| `first`             | integer | Non       | Nombre de notes à retourner pour la pagination vers l'avant.                                              |
| `last`              | integer | Non       | Nombre de notes à retourner pour la pagination vers l'arrière.                                             |

Chaque note retournée inclut son ID de discussion, ce qui permet de regrouper les notes associées en fils de discussion.

Exemple :

```plaintext
Show me all comments on merge request 5 in project gitlab-org/gitlab
```

## `get_pipeline_jobs` {#get_pipeline_jobs}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055) dans GitLab 18.4.

{{< /history >}}

Récupère les jobs d'un pipeline CI/CD GitLab spécifique.

| Paramètre     | Type    | Obligatoire | Description |
|---------------|---------|----------|-------------|
| `id`          | chaîne  | Oui      | ID ou chemin encodé en URL du projet. |
| `pipeline_id` | integer | Oui      | ID du pipeline. |
| `per_page`    | integer | Non       | Nombre de jobs par page. |
| `page`        | integer | Non       | Numéro de page actuel. |

Exemple :

```plaintext
Show me all jobs in pipeline 12345 for project gitlab-org/gitlab
```

## `get_job_log` {#get_job_log}

Récupère la trace (sortie du journal) d'un job CI/CD spécifique.

| Paramètre | Type    | Obligatoire | Description |
|-----------|---------|----------|-------------|
| `id`      | chaîne  | Oui      | ID ou chemin encodé en URL du projet. |
| `job_id`  | integer | Oui      | ID du job. |

Exemple :

```plaintext
Show me the log output for job 88 in project gitlab-org/gitlab
```

## `manage_pipeline` {#manage_pipeline}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/work_items/583826) dans GitLab 18.10.

{{< /history >}}

Gère les pipelines CI/CD dans un projet GitLab.

| Paramètre     | Type    | Obligatoire    | Description |
|---------------|---------|-------------|-------------|
| `id`          | chaîne  | Oui         | ID ou chemin encodé en URL du projet. |
| `list`        | booléen | Non          | Si `true`, liste tous les pipelines d'un projet. |
| `ref`         | chaîne  | Non          | Nom de la branche ou du tag. Si défini, crée un nouveau pipeline sur une branche ou un tag. Facultatif pour le filtrage des listes. |
| `pipeline_id` | integer | Non          | ID du pipeline. Si seul ce paramètre est défini, supprime un pipeline et toutes les données associées. |
| `retry`       | booléen | Non          | Si `true` et `pipeline_id` sont définis, relance les jobs du pipeline échoués ou annulés. |
| `cancel`      | booléen | Non          | Si `true` et `pipeline_id` sont définis, annule tous les jobs d'un pipeline en cours d'exécution. |
| `name`        | chaîne  | Non          | Nom du pipeline. Si ce paramètre et `pipeline_id` sont définis, met à jour les métadonnées du pipeline. |
| `variables`   | array   | Non          | Variables du pipeline au format tableau (`[{key, value, variable_type}]`). |
| `inputs`      | hash    | Non          | Paramètres d'entrée du pipeline sous forme de paires clé-valeur. |
| `page`        | integer | Non          | Numéro de page actuel. La valeur par défaut est `1`. |
| `per_page`    | integer | Non          | Nombre d'éléments par page. La valeur par défaut est `20`. |

Exemples :

- Lister les pipelines :

  ```plaintext
  List all pipelines for project gitlab-org/gitlab
  ```

- Créer un pipeline :

  ```plaintext
  Create a pipeline on the main branch for project gitlab-org/gitlab
  ```

- Mettre à jour un pipeline :

  ```plaintext
  Rename pipeline 12345 to "My deploy pipeline" in project gitlab-org/gitlab
  ```

- Relancer un pipeline :

  ```plaintext
  Retry failed jobs in pipeline 12345 for project gitlab-org/gitlab
  ```

- Annuler un pipeline :

  ```plaintext
  Cancel pipeline 12345 in project gitlab-org/gitlab
  ```

- Supprimer un pipeline :

  ```plaintext
  Delete pipeline 12345 in project gitlab-org/gitlab
  ```

## `create_workitem_note` {#create_workitem_note}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/581890) dans GitLab 18.7.

{{< /history >}}

Crée une nouvelle note (commentaire) sur un élément de travail GitLab.

| Paramètre       | Type    | Obligatoire | Description |
|-----------------|---------|----------|-------------|
| `body`          | chaîne  | Oui      | Contenu de la note. |
| `url`           | chaîne  | Non       | URL de l'élément de travail. Obligatoire si `group_id` ou `project_id` et `work_item_iid` sont manquants. |
| `group_id`      | chaîne  | Non       | ID ou chemin du groupe. Obligatoire si `url` et `project_id` sont manquants. |
| `project_id`    | chaîne  | Non       | ID ou chemin du projet. Obligatoire si `url` et `group_id` sont manquants. |
| `work_item_iid` | integer | Non       | ID interne de l'élément de travail. Obligatoire si `url` est manquant. |
| `internal`      | booléen | Non       | Marque la note comme interne (visible uniquement par les utilisateurs ayant le rôle Reporter, Developer, Maintainer ou Owner pour le projet). La valeur par défaut est `false`. |
| `discussion_id` | chaîne  | Non       | ID global de la discussion à laquelle répondre (au format `gid://gitlab/Discussion/<id>`). |

Exemple :

```plaintext
Add a comment "This looks good to me" to work item 42 in project gitlab-org/gitlab
```

## `get_workitem_notes` {#get_workitem_notes}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/581892) dans GitLab 18.7.

{{< /history >}}

Récupère toutes les notes (commentaires) d'un élément de travail GitLab spécifique.

| Paramètre       | Type    | Obligatoire | Description |
|-----------------|---------|----------|-------------|
| `url`           | chaîne  | Non       | URL de l'élément de travail. Obligatoire si `group_id` ou `project_id` et `work_item_iid` sont manquants. |
| `group_id`      | chaîne  | Non       | ID ou chemin du groupe. Obligatoire si `url` et `project_id` sont manquants. |
| `project_id`    | chaîne  | Non       | ID ou chemin du projet. Obligatoire si `url` et `group_id` sont manquants. |
| `work_item_iid` | integer | Non       | ID interne de l'élément de travail. Obligatoire si `url` est manquant. |
| `after`         | chaîne  | Non       | Curseur pour la pagination vers l'avant. |
| `before`        | chaîne  | Non       | Curseur pour la pagination vers l'arrière. |
| `first`         | integer | Non       | Nombre de notes à retourner pour la pagination vers l'avant. |
| `last`          | integer | Non       | Nombre de notes à retourner pour la pagination vers l'arrière. |

Exemple :

```plaintext
Show me all comments on work item 42 in project gitlab-org/gitlab
```

## `link_work_items` {#link_work_items}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230221) dans GitLab 19.0.

{{< /history >}}

Lie un élément de travail à un ou plusieurs autres éléments de travail avec un type de relation.

| Paramètre        | Type             | Obligatoire | Description |
|------------------|------------------|----------|-------------|
| `work_items_ids` | array of strings | Oui      | ID globaux des éléments de travail à lier (au format `gid://gitlab/WorkItem/<id>`). Maximum 10 éléments. |
| `url`            | chaîne           | Non       | URL de l'élément de travail source. Obligatoire si `group_id` ou `project_id` et `work_item_iid` sont manquants. |
| `group_id`       | chaîne           | Non       | ID ou chemin du groupe. Obligatoire si `url` et `project_id` sont manquants. |
| `project_id`     | chaîne           | Non       | ID ou chemin du projet. Obligatoire si `url` et `group_id` sont manquants. |
| `work_item_iid`  | integer          | Non       | ID interne de l'élément de travail source. Obligatoire si `url` est manquant. |
| `link_type`      | chaîne           | Non       | Type de relation. L'un des types suivants : `relates_to`, `blocks` ou `blocked_by`. La valeur par défaut est `relates_to`. Les types `blocks` et `blocked_by` nécessitent GitLab Premium ou GitLab Ultimate. |

Exemple :

```plaintext
Mark work item 42 in project gitlab-org/gitlab as blocked by work item 40
```

## `get_saved_view_work_items` {#get_saved_view_work_items}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227911) dans GitLab 18.11.

{{< /history >}}

Récupère une vue enregistrée et sa liste d'éléments de travail depuis un espace de nommage. L'outil applique les filtres et l'ordre de tri de la vue enregistrée aux éléments de travail retournés.

| Paramètre       | Type    | Obligatoire | Description |
|-----------------|---------|----------|-------------|
| `saved_view_id` | chaîne  | Oui      | ID global de la vue enregistrée (au format `gid://gitlab/WorkItems::SavedViews::SavedView/<id>`). |
| `url`           | chaîne  | Non       | URL de l'espace de nommage (projet ou groupe). Obligatoire si `group_id` ou `project_id` est manquant. |
| `group_id`      | chaîne  | Non       | ID ou chemin du groupe. Obligatoire si `url` et `project_id` sont manquants. |
| `project_id`    | chaîne  | Non       | ID ou chemin du projet. Obligatoire si `url` et `group_id` sont manquants. |
| `after`         | chaîne  | Non       | Curseur pour la pagination vers l'avant. |
| `first`         | integer | Non       | Nombre d'éléments de travail à retourner. Maximum 100. |

Exemple :

```plaintext
Show me the work items in this saved view: <URL>
```

## `search` {#search}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/566143) dans GitLab 18.4.
- Recherche de groupes et de projets et tri et classement des résultats [ajoutés](https://gitlab.com/gitlab-org/gitlab/-/issues/571132) dans GitLab 18.6.
- [Renommé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214734) de `gitlab_search` en `search` dans GitLab 18.8.

{{< /history >}}

Recherche un terme dans l'ensemble de l'instance GitLab avec l'API de recherche. Cet outil est disponible pour la recherche globale, par groupe et par projet. Les portées disponibles dépendent du [type de recherche](../search/_index.md).

| Paramètre      | Type             | Obligatoire | Description |
|----------------|------------------|----------|-------------|
| `scope`        | chaîne           | Oui      | Portée de la recherche (par exemple, `issues`, `merge_requests` ou `projects`). |
| `search`       | chaîne           | Oui      | Terme de recherche. |
| `group_id`     | chaîne           | Non       | ID ou chemin encodé en URL du groupe dans lequel vous souhaitez effectuer la recherche. |
| `project_id`   | chaîne           | Non       | ID ou chemin encodé en URL du projet dans lequel vous souhaitez effectuer la recherche. |
| `state`        | chaîne           | Non       | État des résultats de recherche (pour `issues` et `merge_requests`). |
| `confidential` | booléen          | Non       | Filtre les résultats par confidentialité (pour `issues`). La valeur par défaut est `false`. |
| `fields`       | array of strings | Non       | Tableau des champs dans lesquels vous souhaitez effectuer la recherche (pour `issues` et `merge_requests`). |
| `order_by`     | chaîne           | Non       | Attribut selon lequel classer les résultats. La valeur par défaut est `created_at` pour la recherche de base et la pertinence pour la recherche avancée. |
| `sort`         | chaîne           | Non       | Sens du tri des résultats. La valeur par défaut est `desc`. |
| `per_page`     | integer          | Non       | Nombre de résultats par page. La valeur par défaut est `20`. |
| `page`         | integer          | Non       | Numéro de page actuel. La valeur par défaut est `1`. |

Exemple :

```plaintext
Search issues for "flaky test" across GitLab
```

## `search_labels` {#search_labels}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218121) dans GitLab 18.9.

{{< /history >}}

Recherche des labels dans un projet ou un groupe GitLab.

| Paramètre    | Type    | Obligatoire | Description |
|--------------|---------|----------|-------------|
| `full_path`  | chaîne  | Oui      | Chemin complet du projet ou du groupe (par exemple, `group/project`). |
| `is_project` | booléen | Oui      | Indique si la recherche doit être effectuée dans un projet (`true`) ou un groupe (`false`). |
| `search`     | chaîne  | Non       | Terme de recherche pour filtrer les labels par titre. |

Lorsque vous recherchez des labels de groupe, les résultats incluent les labels des groupes ancêtres et descendants.

Exemple :

```plaintext
Show me all labels in project gitlab-org/gitlab
```

## `semantic_code_search` {#semantic_code_search}

{{< details >}}

- Module complémentaire : GitLab Duo Core, GitLab Duo Pro ou GitLab Duo Enterprise
- Offre : GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/569624) en tant que [version expérimentale](../../policy/development_stages_support.md#experiment) dans GitLab 18.5 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `code_snippet_search_graphqlapi`. Désactivés par défaut.
- Recherche par chemin de projet [ajoutée](https://gitlab.com/gitlab-org/gitlab/-/issues/575234) dans GitLab 18.6.
- [Passé](https://gitlab.com/gitlab-org/gitlab/-/issues/568359) de la version expérimentale à la [version bêta](../../policy/development_stages_support.md#beta) dans GitLab 18.7. Le feature flag `code_snippet_search_graphqlapi` a été supprimé.
- [Ajouté](https://gitlab.com/gitlab-org/gitlab/-/issues/581105) à l'interface utilisateur GitLab dans GitLab 18.7 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `mcp_client`. Désactivés par défaut.
- [Mis à jour](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228569) pour utiliser l'[API REST](../../api/search.md#semantic-search) dans GitLab 18.11 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `mcp_semantic_code_search_use_rest_api`. Désactivés par défaut.
- Utilisation de l'[API REST généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239364) dans GitLab 19.1. Le feature flag `mcp_semantic_code_search_use_rest_api` a été supprimé.

{{< /history >}}

> [!flag]
> Un feature flag contrôle la disponibilité de cette fonctionnalité. Pour plus d'informations, consultez l'historique.

Recherche des extraits de code pertinents dans un projet GitLab. Pour plus d'informations, notamment sur la configuration et l'activation, consultez [la recherche sémantique de code](../gitlab_duo/semantic_code_search.md).

| Paramètre        | Type    | Obligatoire | Description |
|------------------|---------|----------|-------------|
| `semantic_query` | chaîne  | Oui      | Requête de recherche pour le code. |
| `project_id`     | chaîne  | Oui      | ID ou chemin du projet. |
| `directory_path` | chaîne  | Non       | Chemin du répertoire (par exemple, `app/services/`). |
| `knn`            | integer | Non       | Nombre de voisins les plus proches utilisés pour trouver des extraits de code similaires. La valeur par défaut est `64`. |
| `limit`          | integer | Non       | Nombre maximum de résultats à retourner. La valeur par défaut est `20`. |

Pour de meilleurs résultats, décrivez la fonctionnalité ou le comportement qui vous intéresse plutôt que d'utiliser des mots-clés génériques ou des noms de fonction ou de variable spécifiques.

Exemple :

```plaintext
How are authorizations managed in this project?
```

## `attach_scan_profile` {#attach_scan_profile}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240685) dans GitLab 19.2.

{{< /history >}}

Associe le profil d'analyse de sécurité donné aux projets spécifiés, ou à tous les projets appartenant aux groupes spécifiés.

| Paramètre                  | Type             | Obligatoire | Description |
|----------------------------|------------------|----------|-------------|
| `security_scan_profile_id` | chaîne           | Oui      | ID global du profil d'analyse de sécurité (par exemple, `gid://gitlab/Security::ScanProfile/1`). |
| `project_ids`              | array of strings | Non       | Tableau des ID globaux des projets (par exemple, `[gid://gitlab/Project/1]`). Ce paramètre est obligatoire sauf si `group_ids` est fourni. |
| `group_ids`                | array of strings | Non       | Tableau des ID globaux des groupes (par exemple, `[gid://gitlab/Group/1]`). Ce paramètre est obligatoire sauf si `project_ids` est fourni. |

Exemple :

```plaintext
Attach `gid://gitlab/Security::ScanProfile/1` to all projects under `gid://gitlab/Group/1`.
```
