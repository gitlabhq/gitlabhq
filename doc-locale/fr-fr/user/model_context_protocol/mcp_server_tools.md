---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Utilisez ces outils pour interagir avec GitLab via le serveur MCP GitLab.
title: Outils du serveur MCP GitLab
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : version bêta

{{< /details >}}

> [!warning]
> Pour donner votre avis sur cette fonctionnalité, laissez un commentaire dans le [ticket 561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564).

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
| `assignee_ids` | tableau d'entiers | Non       | Tableau des ID des utilisateurs assignés. |
| `milestone_id` | entier           | Non       | ID du jalon. |
| `labels`       | tableau de chaînes de caractères  | Non       | Tableau des noms de label. |
| `confidential` | booléen           | Non       | Définit le ticket comme confidentiel. La valeur par défaut est `false`. |
| `epic_id`      | entier           | Non       | ID de l'epic lié. |

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
| `issue_iid` | entier | Oui      | ID interne du ticket. |

Exemple :

```plaintext
Get details for issue 42 in project 123
```

## `create_merge_request` {#create_merge_request}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/571243) dans GitLab 18.5.
- [Ajout](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217458) de `assignee_ids`, `reviewer_ids`, `description`, `labels` et `milestone_id` dans GitLab 18.8.

{{< /history >}}

Crée une merge request dans un projet GitLab.

| Paramètre           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | chaîne            | Oui      | ID ou chemin encodé en URL du projet. |
| `title`             | chaîne            | Oui      | Titre de la merge request. |
| `source_branch`     | chaîne            | Oui      | Nom de la branche source. |
| `target_branch`     | chaîne            | Oui      | Nom de la branche cible. |
| `target_project_id` | entier           | Non       | ID du projet cible. |
| `assignee_ids`      | tableau d'entiers | Non       | Tableau des ID des assignés de la merge request. Définir sur `0` ou une valeur vide pour retirer tous les assignés. |
| `reviewer_ids`      | tableau d'entiers | Non       | Tableau des ID des relecteurs de la merge request. Définir sur `0` ou une valeur vide pour retirer tous les relecteurs. |
| `description`       | chaîne            | Non       | Description de la merge request. |
| `labels`            | tableau de chaînes de caractères  | Non       | Tableau des noms de label. Définir sur une chaîne vide pour retirer tous les labels. |
| `milestone_id`      | entier           | Non       | ID du jalon. |

Exemple :

```plaintext
Create a merge request in project gitlab-org/gitlab titled "Bug fix broken specs"
from branch "fix/specs-broken" into "master" and enable squash
```

## `get_merge_request` {#get_merge_request}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201838) dans GitLab 18.4.
- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/605878) pour accepter `url` et renvoyer les facettes de données associées dans GitLab 19.3.

{{< /history >}}

Récupère une merge request et, de manière optionnelle, ses diffs, commits, notes, pipelines ou discussions. Seule la merge request de base est renvoyée, sauf si vous demandez des données associées avec le paramètre `include`.

| Paramètre           | Type    | Obligatoire | Description |
|---------------------|---------|----------|-------------|
| `url`               | chaîne  | Non       | URL GitLab de la merge request. Fournissez cette valeur, ou `project_id` et `merge_request_iid`. |
| `project_id`        | chaîne  | Non       | ID ou chemin encodé en URL du projet. Obligatoire si `url` est manquant. |
| `merge_request_iid` | entier | Non       | ID interne de la merge request. Obligatoire si `url` est manquant. |
| `include`           | tableau   | Non       | Facettes associées à renvoyer avec la merge request. Une parmi `diffs`, `commits`, `notes`, `pipelines` ou `discussions`. Limité à une facette par appel. |
| `notes_after`       | chaîne  | Non       | Curseur pour la pagination vers l'avant des notes. S'applique uniquement lorsque `include` est `["notes"]`. |
| `notes_first`       | entier | Non       | Nombre de notes à renvoyer après le curseur, jusqu'à 100. S'applique uniquement lorsque `include` est `["notes"]`. |

La facette `diffs` renvoie uniquement les statistiques de modifications : totaux globaux et ajouts et suppressions par fichier. Pour obtenir le texte du patch, utilisez `get_merge_request_diffs`.

Exemple :

```plaintext
Get merge request 15 in project gitlab-org/gitlab with its commits
```

## `list_duo_sessions` {#list_duo_sessions}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248587) dans GitLab 19.3.

{{< /history >}}

Répertorie vos sessions GitLab Duo Agent Platform, à l'exclusion des sessions Duo Chat. Chaque session inclut son statut individuel, un aperçu de l'objectif, la définition du flow et un horodatage de création. Les sessions de projet incluent également une URL de session. L'aperçu de l'objectif peut être tronqué.

| Paramètre      | Type    | Obligatoire | Description |
|----------------|---------|----------|-------------|
| `url`          | chaîne  | Non       | URL GitLab du projet par lequel filtrer les sessions. Ne pas utiliser avec `project_id`. |
| `project_id`   | chaîne  | Non       | ID numérique ou chemin complet du projet par lequel filtrer les sessions. Ne pas utiliser avec `url`. |
| `status_group` | chaîne  | Non       | Groupe de statuts de session. Un parmi `active`, `paused`, `awaiting_input`, `completed`, `failed` ou `canceled`. |
| `after`        | chaîne  | Non       | Curseur pour la pagination vers l'avant. |
| `first`        | entier | Non       | Nombre de sessions à renvoyer pour la pagination vers l'avant. La valeur par défaut est 20, le maximum est 100. |

Le filtre `status_group` peut renvoyer des sessions avec plusieurs statuts individuels. Chaque appel renvoie une seule page de résultats. Si d'autres pages existent, la réponse inclut `pageInfo.endCursor` que vous pouvez transmettre en tant que `after`.

Exemple :

```plaintext
List my active Duo Agent Platform sessions in gitlab-org/gitlab
```

## `list_merge_requests` {#list_merge_requests}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/246413) dans GitLab 19.3.

{{< /history >}}

Répertorie ou recherche des merge requests dans un projet GitLab, en renvoyant des métadonnées compactes de merge request.

| Paramètre           | Type    | Obligatoire | Description |
|---------------------|---------|----------|-------------|
| `url`               | chaîne  | Non       | URL du projet. Fournissez exactement une valeur parmi `url` ou `project_id`. |
| `project_id`        | chaîne  | Non       | ID ou chemin complet du projet. Fournissez exactement une valeur parmi `url` ou `project_id`. |
| `author_username`   | chaîne  | Non       | Filtrer par nom d'utilisateur de l'auteur de la merge request. |
| `assignee_username` | chaîne  | Non       | Filtrer par nom d'utilisateur d'un assigné. |
| `reviewer_username` | chaîne  | Non       | Filtrer par nom d'utilisateur d'un relecteur. |
| `state`             | chaîne  | Non       | Filtrer par statut. Une parmi `opened`, `closed`, `merged`, `locked` ou `all`. Omettez ce paramètre pour inclure tous les statuts. |
| `scope`             | chaîne  | Non       | Filtrer par rapport à l'utilisateur authentifié. L'un des types suivants : `created_by_me`, `assigned_to_me` ou `review_requested`. Un nom d'utilisateur explicite est prioritaire pour ce champ. |
| `milestone`         | chaîne  | Non       | Filtrer par titre du jalon. |
| `labels`            | chaîne  | Non       | Liste de noms de labels séparés par des virgules. Seules les merge requests ayant tous ces labels sont renvoyées. |
| `search`            | chaîne  | Non       | Requête de recherche correspondant au titre et à la description de la merge request. |
| `after`             | chaîne  | Non       | Curseur pour la pagination vers l'avant. |
| `first`             | entier | Non       | Nombre de merge requests à renvoyer pour la pagination vers l'avant. La valeur par défaut est 20, le maximum est 100. |

Pour récupérer une seule merge request en détail complet, utilisez `get_merge_request`. Ses diffs, commits et notes sont disponibles via `get_merge_request_diffs`, `get_merge_request_commits` et `get_merge_request_notes`. Pour une recherche en texte intégral sur tous les types de ressources, utilisez `search`.

Exemple :

```plaintext
List my open merge requests in gitlab-org/gitlab
```

## `get_merge_request_commits` {#get_merge_request_commits}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055) dans GitLab 18.4.

{{< /history >}}

Récupère la liste des commits d'une merge request GitLab spécifique.

| Paramètre           | Type    | Obligatoire | Description |
|---------------------|---------|----------|-------------|
| `id`                | chaîne  | Oui      | ID ou chemin encodé en URL du projet. |
| `merge_request_iid` | entier | Oui      | ID interne de la merge request. |
| `per_page`          | entier | Non       | Nombre de commits par page. |
| `page`              | entier | Non       | Numéro de page actuel. |

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
| `merge_request_iid` | entier | Oui      | ID interne de la merge request. |
| `per_page`          | entier | Non       | Nombre de diffs par page. |
| `page`              | entier | Non       | Numéro de page actuel. |

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
| `merge_request_iid` | entier | Oui      | ID interne de la merge request. |

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
| `merge_request_iid` | entier | Non       | ID interne de la merge request. Obligatoire si `url` est manquant. |
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
| `merge_request_iid` | entier | Non       | ID interne de la merge request. Obligatoire si `url` est manquant.                                |
| `after`             | chaîne  | Non       | Curseur pour la pagination vers l'avant.                                                                 |
| `before`            | chaîne  | Non       | Curseur pour la pagination vers l'arrière.                                                                |
| `first`             | entier | Non       | Nombre de notes à retourner pour la pagination vers l'avant.                                              |
| `last`              | entier | Non       | Nombre de notes à retourner pour la pagination vers l'arrière.                                             |

Chaque note retournée inclut son ID de discussion, ce qui permet de regrouper les notes associées en fils de discussion.

Exemple :

```plaintext
Show me all comments on merge request 5 in project gitlab-org/gitlab
```

## `save_merge_request_review` {#save_merge_request_review}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/605881) dans GitLab 19.4.

{{< /history >}}

Écrit des artefacts de revue de merge request en tant qu'utilisateur authentifié. Chaque appel effectue exactement une opération, sélectionnée avec le paramètre `method` :

| Méthode               | Action |
|----------------------|--------|
| `create_note`        | Ajoute un commentaire de premier niveau. |
| `reply_discussion`   | Répond dans une discussion existante. |
| `create_diff_note`   | Commente une ligne de diff spécifique. |
| `resolve_discussion` | Résout ou annule la résolution d'une discussion. |
| `submit_review`      | Publie plusieurs commentaires de diff et un résumé optionnel en un seul appel. |
| `post_duo_review`    | Demande à GitLab Duo de réviser la merge request. Nécessite GitLab Duo Code Review. |

| Paramètre           | Type    | Obligatoire | Description |
|---------------------|---------|----------|-------------|
| `url`               | chaîne  | Non       | URL de la merge request GitLab. Obligatoire si `project_id` et `merge_request_iid` sont manquants. |
| `project_id`        | chaîne  | Non       | ID ou chemin du projet. Obligatoire si `url` est manquant. |
| `merge_request_iid` | entier | Non       | ID interne de la merge request. Obligatoire si `url` est manquant. |
| `method`            | chaîne  | Oui      | L'opération à effectuer. Les paramètres appartenant à une méthode différente sont rejetés. |
| `body`              | chaîne  | Non       | Texte de la note. Obligatoire pour `create_note`, `reply_discussion` et `create_diff_note`. Les lignes ne peuvent pas commencer par `/` pour éviter de déclencher des actions rapides (par exemple, `/merge`). |
| `discussion_id`     | chaîne  | Non       | Discussion sur laquelle agir. Obligatoire pour `reply_discussion` et `resolve_discussion`. Accepte un ID global ou un ID de discussion simple. |
| `internal`          | booléen | Non       | Pour `create_note`, marque la note comme interne. |
| `resolved`          | booléen | Non       | Pour `resolve_discussion` : `true` résout, `false` annule la résolution. Obligatoire pour cette méthode. |
| `old_path`          | chaîne  | Non       | Pour `create_diff_note`, le chemin du fichier avant la modification. Fournissez `old_path` ou `new_path`, ou les deux. |
| `new_path`          | chaîne  | Non       | Pour `create_diff_note`, le chemin du fichier après la modification. |
| `old_line`          | entier | Non       | Pour `create_diff_note`, le numéro de ligne dans l'ancienne version. Fournissez `old_line` ou `new_line`, ou les deux. |
| `new_line`          | entier | Non       | Pour `create_diff_note`, le numéro de ligne dans la nouvelle version. |
| `comments`          | tableau   | Non       | Pour `submit_review`, 1 à 20 commentaires de diff. Chaque entrée prend `file` et `body` (obligatoires), et `old_line`, `new_line` et `suggestion` (optionnels). Obligatoire pour cette méthode. `file` est le chemin après modification ; pour les fichiers renommés, utilisez `create_diff_note` à la place. |
| `verdict`           | chaîne  | Non       | Pour `submit_review`, un verdict global préfixé à la note de résumé. |
| `summary`           | chaîne  | Non       | Pour `submit_review`, une note de résumé publiée après les commentaires de diff. |
| `summary_internal`  | booléen | Non       | Pour `submit_review`, marque la note de résumé comme interne. |

Exemple :

```plaintext
Review merge request 42 in project gitlab-org/gitlab and leave your findings as diff comments with a summary
```

## `add_branch` {#add_branch}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/605877) dans GitLab 19.3. `create_branch` est également accepté comme alias.

{{< /history >}}

Ajoute une branche à un projet GitLab depuis une référence source.

| Paramètre    | Type   | Obligatoire | Description |
|--------------|--------|----------|-------------|
| `url`        | chaîne | Non       | URL GitLab du projet. Fournissez cette valeur, ou `project_id`. |
| `project_id` | chaîne | Non       | ID ou chemin du projet. Obligatoire si `url` n'est pas fourni. |
| `branch`     | chaîne | Oui      | Nom de la nouvelle branche. |
| `ref`        | chaîne | Oui      | Nom de branche ou SHA de commit à partir duquel créer la nouvelle branche. |

Exemple :

```plaintext
Create a branch named feature/x from main in project gitlab-org/gitlab
```

## `get_repository_file` {#get_repository_file}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248744) dans GitLab 19.3.

{{< /history >}}

Récupère le contenu d'un seul fichier d'un dépôt à une référence spécifique.

Le contenu provient du dépôt, et non de votre système de fichiers local. Le fichier est renvoyé tel que validé à `ref`, de sorte que les modifications non validées dans un checkout local ne sont pas incluses.

| Paramètre    | Type    | Obligatoire | Description |
|--------------|---------|----------|-------------|
| `url`        | chaîne  | Non       | URL du fichier, par exemple `https://gitlab.example.com/my-group/my-project/-/blob/main/app/models/user.rb`. Fournissez cette valeur, ou `project_id`, `file_path` et `ref`. |
| `project_id` | chaîne  | Non       | ID ou chemin complet du projet. Obligatoire si `url` n'est pas fourni. |
| `file_path`  | chaîne  | Non       | Chemin du fichier relatif à la racine du dépôt. Obligatoire si `url` n'est pas fourni. |
| `ref`        | chaîne  | Non       | Nom de branche, nom de tag ou SHA de commit. Utilisez `HEAD` pour la branche par défaut. Obligatoire si `url` n'est pas fourni. |
| `offset`     | entier | Non       | Ligne indexée à partir de zéro à partir de laquelle commencer la lecture. La valeur par défaut est `0`. |
| `limit`      | entier | Non       | Nombre maximum de lignes à renvoyer. La valeur par défaut et le maximum sont `2000`. |

La réponse contient un objet `metadata` avec `total_lines`, `returned_lines`, `truncated` et `size_bytes`. Lorsque la réponse ne couvre qu'une partie du fichier, `system_instruction` indique le `offset` à utiliser lors du prochain appel.

Cet outil renvoie du texte uniquement. Les fichiers binaires et les fichiers stockés dans Git LFS renvoient une erreur. Les fichiers qu'un projet exclut du contexte GitLab Duo renvoient également une erreur.

Exemple :

```plaintext
Show me app/models/user.rb from the main branch of my-group/my-project
```

## `get_commit` {#get_commit}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/605874) dans GitLab 19.3.

{{< /history >}}

Récupère les métadonnées d'un seul commit, et optionnellement son diff ou ses notes.

| Paramètre     | Type    | Obligatoire | Description |
|---------------|---------|----------|-------------|
| `url`         | chaîne  | Non       | URL du commit GitLab. Obligatoire si `project_id` et `commit_sha` ne sont pas fournis. |
| `project_id`  | chaîne  | Non       | ID ou chemin encodé en URL du projet. Obligatoire si `url` n'est pas fourni. |
| `commit_sha`  | chaîne  | Non       | Commit à rechercher. Accepte un SHA complet ou abrégé, un nom de branche ou un nom de tag. Obligatoire si `url` n'est pas fourni. |
| `include`     | tableau   | Non       | Facette associée à récupérer en ligne, une par appel (`diff` ou `notes`). Les métadonnées de base sont toujours renvoyées. |
| `diff_detail` | chaîne  | Non       | Niveau de détail dans le diff du commit. S'applique uniquement lorsque `include` contient `diff`. Peut être soit `stats` soit `full_patch`. La valeur par défaut est `stats`. |
| `notes_after` | chaîne  | Non       | Jeton pour récupérer la page suivante de notes. S'applique uniquement lorsque `include` contient `notes`. |
| `notes_first` | entier | Non       | Nombre de notes à renvoyer par page (maximum 100). S'applique uniquement lorsque `include` contient `notes`. |

Avec `diff_detail` défini sur `stats`, la facette diff renvoie le nombre de lignes par fichier et le résumé. Avec `full_patch`, elle renvoie le texte du patch.

Exemple :

```plaintext
Show me commit abc123 in gitlab-org/gitlab with its diff stats
```

## `get_pipeline` {#get_pipeline}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/605853) dans GitLab 19.3.

{{< /history >}}

Récupère un pipeline, et optionnellement ses jobs, pipelines downstream ou jobs bridge (déclencheurs).

| Paramètre     | Type    | Obligatoire | Description |
|---------------|---------|----------|-------------|
| `id`          | chaîne  | Oui      | ID ou chemin complet du projet. |
| `pipeline_id` | entier | Oui      | ID du pipeline. |
| `include`     | tableau   | Non       | Facette à inclure avec le pipeline, une par appel : `jobs`, `downstream_pipelines` ou `bridge_jobs`. |
| `job_status`  | chaîne  | Non       | Filtre la facette `jobs` par statut (par exemple, `failed`). S'applique uniquement lorsque `include` est `jobs`. |
| `first`       | entier | Non       | Nombre d'éléments à renvoyer pour la facette `include` sélectionnée. La valeur par défaut est `20`, le maximum est `100`. |
| `after`       | chaîne  | Non       | Curseur pour la pagination vers l'avant de la facette `include` sélectionnée. Utilisez le `page_info.end_cursor` de la réponse précédente. |

Le `downstream_pipeline` d'un job bridge est omis (`null`) à la fois lorsque le job déclencheur n'a pas encore déclenché de pipeline downstream, et lorsque vous n'avez pas accès à ce pipeline.

Chaque pipeline downstream inclut un `project_full_path`, car un pipeline downstream peut appartenir à un projet différent. Utilisez cette valeur comme `id` d'un appel de suivi.

Exemples :

- Obtenir un pipeline :

  ```plaintext
  Get the status of pipeline 12345 in project gitlab-org/gitlab
  ```

- Obtenir les jobs en échec d'un pipeline :

  ```plaintext
  Show me the failed jobs in pipeline 12345 for project gitlab-org/gitlab
  ```

- Obtenir les pipelines downstream d'un pipeline :

  ```plaintext
  Show me the downstream pipelines triggered by pipeline 12345 in project gitlab-org/gitlab
  ```

## `get_pipeline_jobs` {#get_pipeline_jobs}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203055) dans GitLab 18.4.

{{< /history >}}

Récupère les jobs d'un pipeline CI/CD GitLab spécifique. Pour obtenir les jobs avec le reste des données du pipeline en un seul appel, utilisez l'outil `get_pipeline` avec `include: jobs` à la place.

| Paramètre     | Type    | Obligatoire | Description |
|---------------|---------|----------|-------------|
| `id`          | chaîne  | Oui      | ID ou chemin encodé en URL du projet. |
| `pipeline_id` | entier | Oui      | ID du pipeline. |
| `per_page`    | entier | Non       | Nombre de jobs par page. |
| `page`        | entier | Non       | Numéro de page actuel. |

Exemple :

```plaintext
Show me all jobs in pipeline 12345 for project gitlab-org/gitlab
```

## `get_job` {#get_job}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/605856) dans GitLab 19.3.
- [Renommé](https://gitlab.com/gitlab-org/gitlab/-/work_items/605856) depuis `get_job_log` dans GitLab 19.3. `get_job_log` continue de fonctionner comme alias et renvoie toujours la facette `log`, limitée à `byte_limit`.

{{< /history >}}

Récupère les métadonnées d'un job CI/CD, et optionnellement sa trace/son journal.

| Paramètre     | Type    | Obligatoire | Description |
|---------------|---------|----------|-------------|
| `id`          | chaîne  | Oui      | ID ou chemin complet du projet. |
| `job_id`      | entier | Oui      | ID du job. |
| `include`     | tableau   | Non       | Facette à inclure avec le job, une par appel : `log`. |
| `byte_offset` | entier | Non       | Décalage en octets à partir duquel commencer la lecture du journal du job. S'applique uniquement lorsque `include` est `log`. La valeur par défaut est `0`. |
| `byte_limit`  | entier | Non       | Nombre maximum d'octets du journal du job à renvoyer. S'applique uniquement lorsque `include` est `log`. La valeur par défaut et le maximum sont `512000`. |

Lorsque le journal est plus long que `byte_limit`, la réponse indique la taille totale et vous fournit le `byte_offset` à utiliser pour la prochaine fenêtre.

Exemples :

- Obtenir les métadonnées d'un job :

  ```plaintext
  Get the status of job 88 in project gitlab-org/gitlab
  ```

- Obtenir le journal d'un job :

  ```plaintext
  Show me the log output for job 88 in project gitlab-org/gitlab
  ```

## `list_pipelines` {#list_pipelines}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/605854) dans GitLab 19.3.

{{< /history >}}

Répertorie les pipelines dans un projet GitLab, avec des filtres optionnels.

| Paramètre        | Type    | Obligatoire | Description |
|------------------|---------|----------|-------------|
| `id`             | chaîne  | Oui      | ID ou chemin encodé en URL du projet. |
| `ref`            | chaîne  | Non       | Nom de la branche ou du tag. Filtre les pipelines par référence. |
| `status`         | chaîne  | Non       | Filtre les pipelines par statut (par exemple, `running`, `success`, `failed`). |
| `source`         | chaîne  | Non       | Filtre les pipelines par source (par exemple, `push`, `web`, `schedule`). |
| `created_after`  | chaîne  | Non       | Renvoie les pipelines créés après la date/heure spécifiée (format ISO 8601). |
| `created_before` | chaîne  | Non       | Renvoie les pipelines créés avant la date/heure spécifiée (format ISO 8601). |
| `order_by`       | chaîne  | Non       | Trie les pipelines par `id`, `status`, `ref`, `updated_at` ou `user_id`. La valeur par défaut est `id`. |
| `sort`           | chaîne  | Non       | Sens du tri, `asc` ou `desc`. La valeur par défaut est `desc`. |
| `page`           | entier | Non       | Numéro de page actuel. La valeur par défaut est `1`. |
| `per_page`       | entier | Non       | Nombre d'éléments par page. La valeur par défaut est `20`. |

Les pipelines enfants sont exclus des résultats par défaut. Pour ne renvoyer que les pipelines enfants, définissez `source` sur `parent_pipeline`.

L'ordre par défaut (`id`, `desc`) renvoie les pipelines avec l'ID le plus élevé en premier. L'ordre par ID correspond généralement à l'ordre de création, mais les deux ne sont pas garantis d'être identiques. Utilisez `created_after` ou `created_before` pour filtrer par une limite de temps explicite. Un appelant peut parcourir les résultats et s'arrêter au premier pipeline en dehors de sa plage cible.

Exemple :

```plaintext
List all failed pipelines on the main branch for project gitlab-org/gitlab
```

## `save_pipeline` {#save_pipeline}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/605855) dans GitLab 19.3.

{{< /history >}}

Exécute, relance ou annule un pipeline CI/CD dans un projet GitLab. Pour mettre à jour les métadonnées du pipeline ou supprimer un pipeline, utilisez l'outil `manage_pipeline` à la place. Pour répertorier les pipelines, utilisez l'outil `list_pipelines` à la place.

| Paramètre     | Type    | Obligatoire    | Description |
|---------------|---------|-------------|-------------|
| `url`         | chaîne  | Non          | URL GitLab du projet. Utilisé uniquement pour créer un pipeline. Fournissez cette valeur, ou `project_id`. |
| `project_id`  | chaîne  | Non          | ID ou chemin complet du projet. Utilisé uniquement pour créer un pipeline. Fournissez cette valeur, ou `url`. |
| `pipeline_id` | entier | Non          | ID d'un pipeline existant à cibler. Lorsque défini, nécessite `action`. Omettez ce paramètre pour créer un nouveau pipeline. |
| `action`      | chaîne  | Non          | Action de cycle de vie à effectuer sur `pipeline_id` : `retry` ou `cancel`. Obligatoire lorsque `pipeline_id` est défini. |
| `ref`         | chaîne  | Non          | Nom de la branche ou du tag. Obligatoire pour créer un pipeline (lorsque `pipeline_id` est absent). |
| `variables`   | tableau   | Non          | Variables du pipeline au format tableau (`[{key, value, variable_type}]`). |
| `inputs`      | hash    | Non          | Paramètres d'entrée du pipeline sous forme de paires clé-valeur. |

Exemples :

- Créer un pipeline :

  ```plaintext
  Create a pipeline on the main branch for project gitlab-org/gitlab
  ```

- Relancer un pipeline :

  ```plaintext
  Retry failed jobs in pipeline 12345 for project gitlab-org/gitlab
  ```

- Annuler un pipeline :

  ```plaintext
  Cancel pipeline 12345 in project gitlab-org/gitlab
  ```

## `manage_pipeline` {#manage_pipeline}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/work_items/583826) dans GitLab 18.10.
- [Supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/247806) l'action `list` en faveur de l'outil `list_pipelines` dans GitLab 19.3.
- [Supprimé](https://gitlab.com/gitlab-org/gitlab/-/work_items/605855) les actions `create`, `retry` et `cancel` en faveur de l'outil `save_pipeline` dans GitLab 19.3.

{{< /history >}}

Met à jour les métadonnées du pipeline ou supprime un pipeline dans un projet GitLab. Pour créer, relancer ou annuler un pipeline, utilisez l'outil `save_pipeline` à la place. Pour répertorier les pipelines, utilisez l'outil `list_pipelines` à la place.

| Paramètre     | Type    | Obligatoire    | Description |
|---------------|---------|-------------|-------------|
| `id`          | chaîne  | Oui         | ID ou chemin encodé en URL du projet. |
| `pipeline_id` | entier | Oui         | ID du pipeline. Si seul ce paramètre est défini, supprime un pipeline et toutes les données associées. |
| `name`        | chaîne  | Non          | Nom du pipeline. Si ce paramètre et `pipeline_id` sont définis, met à jour les métadonnées du pipeline. |

Exemples :

- Mettre à jour un pipeline :

  ```plaintext
  Rename pipeline 12345 to "My deploy pipeline" in project gitlab-org/gitlab
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
| `work_item_iid` | entier | Non       | ID interne de l'élément de travail. Obligatoire si `url` est manquant. |
| `internal`      | booléen | Non       | Marque la note comme interne (visible uniquement par les utilisateurs ayant le rôle Rapporteur, Développeur, Chargé de maintenance ou Propriétaire pour le projet). La valeur par défaut est `false`. |
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
| `work_item_iid` | entier | Non       | ID interne de l'élément de travail. Obligatoire si `url` est manquant. |
| `after`         | chaîne  | Non       | Curseur pour la pagination vers l'avant. |
| `before`        | chaîne  | Non       | Curseur pour la pagination vers l'arrière. |
| `first`         | entier | Non       | Nombre de notes à retourner pour la pagination vers l'avant. |
| `last`          | entier | Non       | Nombre de notes à retourner pour la pagination vers l'arrière. |

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
| `work_items_ids` | tableau de chaînes de caractères | Oui      | ID globaux des éléments de travail à lier (au format `gid://gitlab/WorkItem/<id>`). 10 éléments maximum. |
| `url`            | chaîne           | Non       | URL de l'élément de travail source. Obligatoire si `group_id` ou `project_id` et `work_item_iid` sont manquants. |
| `group_id`       | chaîne           | Non       | ID ou chemin du groupe. Obligatoire si `url` et `project_id` sont manquants. |
| `project_id`     | chaîne           | Non       | ID ou chemin du projet. Obligatoire si `url` et `group_id` sont manquants. |
| `work_item_iid`  | entier          | Non       | ID interne de l'élément de travail source. Obligatoire si `url` est manquant. |
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
| `first`         | entier | Non       | Nombre d'éléments de travail à retourner. 100 maximum. |

Exemple :

```plaintext
Show me the work items in this saved view: <URL>
```

## `save_work_item` {#save_work_item}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/605852) dans GitLab 19.4.

{{< /history >}}

Crée ou met à jour un élément de travail GitLab, tel qu'un ticket, une tâche ou un epic. Omettez `work_item_iid` pour créer un nouvel élément de travail. Fournissez `work_item_iid` ou une URL d'élément de travail pour mettre à jour un élément existant. Les noms d'outils `create_work_item` et `update_work_item` sont des alias pour cet outil.

| Paramètre          | Type              | Obligatoire | Description |
|--------------------|-------------------|----------|-------------|
| `url`              | chaîne            | Non       | URL GitLab pour le projet, le groupe ou l'élément de travail. Fournissez exactement une valeur parmi `url`, `project_id` ou `group_id`. |
| `group_id`         | chaîne            | Non       | ID ou chemin du groupe. Obligatoire si `url` et `project_id` sont manquants. |
| `project_id`       | chaîne            | Non       | ID ou chemin du projet. Obligatoire si `url` et `group_id` sont manquants. |
| `work_item_iid`    | entier           | Non       | ID interne de l'élément de travail à mettre à jour. Omettez ce paramètre pour créer un nouvel élément de travail. |
| `title`            | chaîne            | Non       | Titre de l'élément de travail. Obligatoire lors de la création d'un élément de travail. |
| `type_name`        | chaîne            | Non       | Nom du type d'élément de travail, par exemple `Issue`, `Task` ou `Epic`. Obligatoire lors de la création d'un élément de travail. Les types valides dépendent de l'espace de nommage et de la licence. |
| `description`      | chaîne            | Non       | Description en GitLab Flavored Markdown. Maximum 1 048 576 caractères. |
| `assignee_ids`     | tableau d'entiers | Non       | ID d'utilisateurs à assigner à l'élément de travail. Maximum 100 éléments. |
| `label_ids`        | tableau de chaînes de caractères  | Non       | ID de labels ou ID globaux. Création uniquement ; lors d'une mise à jour, utilisez `add_label_ids` ou `remove_label_ids`. Maximum 100 éléments. |
| `add_label_ids`    | tableau de chaînes de caractères  | Non       | Mise à jour uniquement. ID de labels ou ID globaux à ajouter. Maximum 100 éléments. |
| `remove_label_ids` | tableau de chaînes de caractères  | Non       | Mise à jour uniquement. ID de labels ou ID globaux à supprimer. Maximum 100 éléments. |
| `confidential`     | booléen           | Non       | Définit la confidentialité de l'élément de travail. |
| `start_date`       | chaîne            | Non       | Date de début, au format `YYYY-MM-DD`. |
| `due_date`         | chaîne            | Non       | Date d'échéance, au format `YYYY-MM-DD`. |
| `state`            | chaîne            | Non       | Mise à jour uniquement. `closed` ferme l'élément de travail, `opened` le rouvre. |
| `parent_id`        | chaîne            | Non       | ID global ou ID numérique de l'élément enfant parent. |
| `todo_action`      | chaîne            | Non       | Mise à jour uniquement. `add` ajoute une tâche à faire pour l'utilisateur actuel, `mark_as_done` marque les tâches à faire comme effectuées. |
| `todo_id`          | chaîne            | Non       | Mise à jour uniquement. ID global ou ID numérique de la tâche à faire. Omettez ce paramètre pour mettre à jour toutes les tâches à faire de l'élément de travail. |
| `health_status`    | chaîne            | Non       | Statut de santé. L'un des types suivants : `onTrack`, `needsAttention` ou `atRisk`. GitLab Ultimate uniquement. |
| `weight`           | entier           | Non       | Poids de l'élément de travail. Doit être 0 ou supérieur. GitLab Premium et GitLab Ultimate uniquement. |
| `clear_weight`     | booléen           | Non       | Mise à jour uniquement. Supprime le poids. Est prioritaire sur `weight`. GitLab Premium et GitLab Ultimate uniquement. |
| `status_id`        | chaîne            | Non       | ID global du statut à définir. GitLab Premium et GitLab Ultimate uniquement. |
| `is_fixed`         | booléen           | Non       | Indique si les dates de début et d'échéance sont fixes. Lorsque `false`, les dates sont agrégées depuis les éléments enfants et `start_date` ainsi que `due_date` sont ignorés. GitLab Premium et GitLab Ultimate uniquement. |
| `agent_plan`       | chaîne            | Non       | Contenu Markdown du plan d'agent. GitLab Ultimate uniquement. Nécessite la fonctionnalité workplan. |

Exemple :

```plaintext
Create a task "Update the onboarding guide" in project gitlab-org/gitlab and assign it to me
```

## `search` {#search}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/566143) dans GitLab 18.4.
- Recherche de groupes et de projets et tri et classement des résultats [ajoutés](https://gitlab.com/gitlab-org/gitlab/-/issues/571132) dans GitLab 18.6.
- [Renommée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214734) de `gitlab_search` en `search` dans GitLab 18.8.

{{< /history >}}

Recherche un terme dans l'ensemble de l'instance GitLab avec l'API de recherche. Cet outil est disponible pour la recherche globale, par groupe et par projet. Les portées disponibles dépendent du [type de recherche](../search/_index.md).

| Paramètre      | Type             | Obligatoire | Description |
|----------------|------------------|----------|-------------|
| `scope`        | chaîne           | Oui      | Portée de la recherche (par exemple, `work_items`, `merge_requests` ou `projects`). |
| `search`       | chaîne           | Oui      | Terme de recherche. |
| `group_id`     | chaîne           | Non       | ID ou chemin encodé en URL du groupe dans lequel vous souhaitez effectuer la recherche. |
| `project_id`   | chaîne           | Non       | ID ou chemin encodé en URL du projet dans lequel vous souhaitez effectuer la recherche. |
| `state`        | chaîne           | Non       | État des résultats de recherche (pour `work_items` et `merge_requests`). |
| `confidential` | booléen          | Non       | Filtre les résultats par confidentialité (pour `work_items`). La valeur par défaut est `false`. |
| `fields`       | tableau de chaînes de caractères | Non       | Tableau des champs dans lesquels vous souhaitez effectuer la recherche (pour `work_items` et `merge_requests`). |
| `order_by`     | chaîne           | Non       | Attribut selon lequel classer les résultats. La valeur par défaut est `created_at` pour la recherche de base et la pertinence pour la recherche avancée. |
| `sort`         | chaîne           | Non       | Sens du tri des résultats. La valeur par défaut est `desc`. |
| `per_page`     | entier          | Non       | Nombre de résultats par page. La valeur par défaut est `20`. |
| `page`         | entier          | Non       | Numéro de page actuel. La valeur par défaut est `1`. |

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

Lorsque vous recherchez des labels de groupe, les résultats incluent les labels des groupes ascendants et descendants.

Exemple :

```plaintext
Show me all labels in project gitlab-org/gitlab
```

## `list_wiki_pages` {#list_wiki_pages}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240973) dans GitLab 19.3.

{{< /history >}}

Répertorie les pages wiki dans un projet ou groupe GitLab.

| Paramètre    | Type    | Obligatoire | Description |
|--------------|---------|----------|-------------|
| `project_id` | chaîne  | Non       | Chemin complet ou ID numérique du projet (par exemple, `gitlab-org/gitlab` ou `278964`). |
| `group_id`   | chaîne  | Non       | Chemin complet ou ID numérique du groupe (par exemple, `gitlab-org` ou `9970`). |
| `first`      | entier | Non       | Nombre de pages wiki à renvoyer pour la pagination vers l'avant (maximum 100). |
| `after`      | chaîne  | Non       | Curseur pour la pagination vers l'avant. |

Fournissez uniquement un `project_id` ou un `group_id`. Chaque appel renvoie une seule page de résultats. Si d'autres pages existent, la réponse inclut un `end_cursor` que vous pouvez transmettre en tant que `after` pour récupérer la page suivante.

Exemple :

```plaintext
List the wiki pages in gitlab-org/gitlab
```

## `semantic_code_search` {#semantic_code_search}

{{< details >}}

- Module d'extension : GitLab Duo Core, GitLab Duo Pro ou GitLab Duo Enterprise
- Offre : GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/569624) en [version expérimentale](../../policy/development_stages_support.md#experiment) dans GitLab 18.5 [avec le feature flag](../../administration/feature_flags/_index.md) `code_snippet_search_graphqlapi`. Désactivés par défaut.
- [Ajout](https://gitlab.com/gitlab-org/gitlab/-/issues/575234) de la recherche par chemin de projet dans GitLab 18.6.
- [Passage](https://gitlab.com/gitlab-org/gitlab/-/issues/568359) de la version expérimentale à la [version bêta](../../policy/development_stages_support.md#beta) dans GitLab 18.7. Suppression du feature flag `code_snippet_search_graphqlapi`.
- [Ajout](https://gitlab.com/gitlab-org/gitlab/-/issues/581105) à l'interface utilisateur GitLab dans GitLab 18.7 [avec le feature flag](../../administration/feature_flags/_index.md) `mcp_client`. Désactivés par défaut.
- [Mise à jour](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228569) pour utiliser l'[API REST](../../api/search.md#semantic-search) dans GitLab 18.11 [avec le feature flag](../../administration/feature_flags/_index.md) `mcp_semantic_code_search_use_rest_api`. Désactivés par défaut.
- Passage de l'utilisation de l'API REST [en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239364) dans GitLab 19.1. Suppression du feature flag `mcp_semantic_code_search_use_rest_api`.

{{< /history >}}

> [!flag]
> Un feature flag contrôle la disponibilité de cette fonctionnalité. Pour plus d'informations, consultez l'historique.

Recherche des extraits de code pertinents dans un projet GitLab. Pour plus d'informations, notamment sur la configuration et l'activation, consultez [la recherche sémantique de code](../gitlab_duo/semantic_code_search.md).

| Paramètre        | Type    | Obligatoire | Description |
|------------------|---------|----------|-------------|
| `semantic_query` | chaîne  | Oui      | Requête de recherche pour le code. |
| `project_id`     | chaîne  | Oui      | ID ou chemin du projet. |
| `directory_path` | chaîne  | Non       | Chemin du répertoire (par exemple, `app/services/`). |
| `knn`            | entier | Non       | Nombre de voisins les plus proches utilisés pour trouver des extraits de code similaires. La valeur par défaut est `64`. |
| `limit`          | entier | Non       | Nombre maximum de résultats à retourner. La valeur par défaut est `20`. |

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
| `project_ids`              | tableau de chaînes de caractères | Non       | Tableau des ID globaux des projets (par exemple, `[gid://gitlab/Project/1]`). Ce paramètre est obligatoire sauf si `group_ids` est fourni. |
| `group_ids`                | tableau de chaînes de caractères | Non       | Tableau des ID globaux des groupes (par exemple, `[gid://gitlab/Group/1]`). Ce paramètre est obligatoire sauf si `project_ids` est fourni. |

Exemple :

```plaintext
Attach `gid://gitlab/Security::ScanProfile/1` to all projects under `gid://gitlab/Group/1`.
```
