---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation pour l'API REST des merge requests dans GitLab."
title: API Merge requests
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

<!-- Do not remove these outdated lines until the changes are actually implemented in the API -->

{{< history >}}

- `reference` [obsolète](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20354) dans GitLab 12.7.
- `merged_by` [obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/350534) dans GitLab 14.7.
- `merge_status` [obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/3169#note_1162532204) en faveur de `detailed_merge_status` dans GitLab 15.6.
- `with_merge_status_recheck` [modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115948) dans GitLab 15.11 [avec un indicateur](../administration/feature_flags/_index.md) nommé `restrict_merge_status_recheck` pour être ignoré pour les requêtes des utilisateurs ayant des permissions insuffisantes. Désactivé par défaut.
- `approvals_before_merge` [obsolète](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119503) dans GitLab 16.0.
- `prepared_at` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122001) dans GitLab 16.1.
- `merge_user_id` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002) dans GitLab 17.0.
- `merge_user_username` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002) dans GitLab 17.0.
- La valeur `merged_at` de `order_by` [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147052) dans GitLab 17.2.
- `merge_after` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165092) dans GitLab 17.5.
- `security_policy_violations` [disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/473704) dans GitLab 18.4. L'indicateur de fonctionnalité `policy_mergability_check` a été supprimé.
- Le paramètre de filtre `draft` [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234098) dans GitLab 19.0.
- Le paramètre de filtre `wip` [obsolète](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234098) dans GitLab 19.0.

{{< /history >}}

Utilisez cette API pour gérer les [merge requests](../user/project/merge_requests/_index.md). Vous pouvez :

- Automatisez toute partie du processus de revue de code.
- Connectez les modifications de code à des outils externes.
- Envoyez les informations des merge requests à des systèmes non GitLab dans le format de votre choix.
- Mettez à jour, approuvez, fusionnez ou bloquez des merge requests en fonction de données provenant de systèmes externes.

Tous les appels API vers des informations non publiques nécessitent une authentification.

## Suppressions dans l'API v5 {#removals-in-api-v5}

L'attribut `approvals_before_merge` est obsolète et [est prévu pour suppression](rest/deprecations.md) dans l'API v5 en faveur de l'[API d'approbation des merge requests](merge_request_approvals.md).

## Lister les merge requests {#list-merge-requests}

Listez toutes les merge requests accessibles à l'utilisateur authentifié. Par défaut, ne retourne que les merge requests créées par l'utilisateur actuel. Utilisez `scope=all` pour récupérer toutes les merge requests.

Utilisez le paramètre `state` pour obtenir uniquement les merge requests avec un état donné (`opened`, `closed`, `locked`, ou `merged`) ou tous les états (`all`). La recherche par `locked` ne renvoie généralement aucun résultat, car cet état est de courte durée et transitoire. Utilisez les paramètres de pagination `page` et `per_page` pour restreindre la liste des merge requests.

```plaintext
GET /merge_requests
GET /merge_requests?state=opened
GET /merge_requests?state=all
GET /merge_requests?milestone=release
GET /merge_requests?labels=bug,reproduced
GET /merge_requests?author_id=5
GET /merge_requests?author_username=gitlab-bot
GET /merge_requests?my_reaction_emoji=star
GET /merge_requests?scope=assigned_to_me
GET /merge_requests?scope=reviews_for_me
GET /merge_requests?search=foo&in=title
```

Attributs pris en charge :

| Attribut                   | Type          | Obligatoire | Description |
|-----------------------------|---------------|----------|-------------|
| `approved_by_ids[]`         | tableau d'entiers | Non       | Retourne les merge requests approuvées par tous les utilisateurs avec l'`id` donné, jusqu'à 5 utilisateurs. `None` retourne les merge requests sans approbation. `Any` retourne les merge requests avec une approbation. |
| `approved_by_usernames[]`   | tableau de chaînes  | Non       | Retourne les merge requests approuvées par tous les utilisateurs avec l'`username` donné, jusqu'à 5 utilisateurs. `None` retourne les merge requests sans approbation. `Any` retourne les merge requests avec une approbation. |
| `approver_ids[]`            | tableau d'entiers | Non       | Retourne les merge requests dont tous les utilisateurs avec l'`id` spécifié sont des approbateurs éligibles selon les règles d'approbation. `None` retourne les merge requests sans approbateur éligible. `Any` retourne les merge requests avec au moins un approbateur éligible. Premium et Ultimate uniquement. |
| `assignee_id`               | entier ou chaîne | Non   | Retourne les merge requests assignées à l'utilisateur avec l'`id` donné. `None` retourne les merge requests non assignées. `Any` retourne les merge requests avec un assigné. Mutuellement exclusif avec `assignee_username`. |
| `assignee_username[]`       | tableau de chaînes  | Non       | Retourne les merge requests assignées aux noms d'utilisateur donnés. Mutuellement exclusif avec `assignee_id`. |
| `author_id`                 | entier       | Non       | Retourne les merge requests créées par l'utilisateur avec l'`id` donné. Mutuellement exclusif avec `author_username`. À combiner avec `scope=all` ou `scope=assigned_to_me`. |
| `author_username`           | string        | Non       | Retourne les merge requests créées par le `username` donné. Mutuellement exclusif avec `author_id`. |
| `created_after`             | datetime      | Non       | Retourne les merge requests créées à la date et l'heure données ou après. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `created_before`            | datetime      | Non       | Retourne les merge requests créées à la date et l'heure données ou avant. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `deployed_after`            | datetime      | Non       | Retourne les merge requests déployées après la date/l'heure donnée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `deployed_before`           | datetime      | Non       | Retourne les merge requests déployées avant la date/l'heure donnée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `environment`               | string        | Non       | Retourne les merge requests déployées dans l'environnement donné. |
| `in`                        | string        | Non       | Modifie la portée de l'attribut `search`. `title`, `description`, ou une chaîne les joignant par une virgule. La valeur par défaut est `title,description`. |
| `labels`                    | string        | Non       | Retourne les merge requests correspondant à une liste de labels séparés par des virgules. `None` liste toutes les merge requests sans label. `Any` liste toutes les merge requests avec au moins un label. Les noms prédéfinis ne sont pas sensibles à la casse. |
| `merge_user_id`             | entier       | Non       | Retourne les merge requests fusionnées par l'utilisateur avec l'`id` donné. Mutuellement exclusif avec `merge_user_username`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002) dans GitLab 17.0. |
| `merge_user_username`       | string        | Non       | Retourne les merge requests fusionnées par l'utilisateur avec le `username` donné. Mutuellement exclusif avec `merge_user_id`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002) dans GitLab 17.0. |
| `milestone`                 | string        | Non       | Retourne les merge requests pour un jalon spécifique. `None` retourne les merge requests sans jalon. `Any` retourne les merge requests avec un jalon assigné. |
| `my_reaction_emoji`         | string        | Non       | Retourne les merge requests auxquelles l'utilisateur authentifié a réagi avec l'`emoji` donné. `None` retourne les tickets sans réaction. `Any` retourne les tickets avec au moins une réaction. |
| `non_archived`              | boolean       | Non       | Si `true`, retourne uniquement les merge requests des projets non archivés. La valeur par défaut est `false`. |
| `not`                       | hash          | Non       | Retourne les merge requests ne correspondant pas aux paramètres fournis. Accepte : `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `reviewer_id`, `reviewer_username`, `my_reaction_emoji`. |
| `order_by`                  | string        | Non       | Retourne les merge requests triées par les champs `created_at`, `updated_at`, `merged_at` ([introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147052) dans GitLab 17.2), `label_priority`, `priority`, `milestone_due`, `popularity`, ou `title`. La valeur par défaut est `created_at`. |
| `reviewer_id`               | entier ou chaîne | Non   | Retourne les merge requests dont l'utilisateur est [relecteur](../user/project/merge_requests/reviews/_index.md) avec l'`id` donné. `None` retourne les merge requests sans relecteur. `Any` retourne les merge requests avec un relecteur quelconque. Mutuellement exclusif avec `reviewer_username`. |
| `reviewer_username`         | string        | Non       | Retourne les merge requests dont l'utilisateur est [relecteur](../user/project/merge_requests/reviews/_index.md) avec le `username` donné. `None` retourne les merge requests sans relecteur. `Any` retourne les merge requests avec un relecteur quelconque. Mutuellement exclusif avec `reviewer_id`. |
| `scope`                     | string        | Non       | Retourne les merge requests pour la portée donnée : `created_by_me`, `assigned_to_me`, `reviews_for_me`, ou `all`. `reviews_for_me` retourne les merge requests où l'utilisateur actuel est assigné comme relecteur. La valeur par défaut est `created_by_me`. |
| `search`                    | string        | Non       | Recherche des merge requests par rapport à leur `title` et leur `description`. À combiner avec l'attribut `in`. |
| `sort`                      | string        | Non       | Retourne les merge requests triées dans l'ordre `asc` ou `desc`. La valeur par défaut est `desc`. |
| `source_branch`             | string        | Non       | Retourne les merge requests avec la branche source donnée. |
| `state`                     | string        | Non       | Retourne toutes les merge requests (`all`) ou uniquement celles qui sont `opened`, `closed`, `locked`, ou `merged`. La valeur par défaut est `all`. |
| `target_branch`             | string        | Non       | Retourne les merge requests avec la branche cible donnée. |
| `updated_after`             | datetime      | Non       | Retourne les merge requests mises à jour à la date et l'heure données ou après. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `updated_before`            | datetime      | Non       | Retourne les merge requests mises à jour à la date et l'heure données ou avant. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `view`                      | string        | Non       | Si `simple`, retourne l'`iid`, l'URL, le titre, la description et l'état de base de la merge request. |
| `draft`                         | boolean        | Non       | Filtre les merge requests par leur statut `draft`. `true` retourne uniquement les merge requests en brouillon, `false` retourne les merge requests qui ne sont pas en brouillon. Mutuellement exclusif avec `wip`. |
| `wip`                           | string         | Non       | [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234098) dans GitLab 19.0. Utilisez `draft` à la place. Filtre les merge requests par leur statut `wip`. `yes` retourne uniquement les merge requests en brouillon, `no` retourne les merge requests qui ne sont pas en brouillon. |
| `with_labels_details`       | boolean       | Non       | Si `true`, la réponse renvoie plus de détails pour chaque label dans le champ labels : `:name`, `:color`, `:description`, `:description_html`, `:text_color`. La valeur par défaut est `false`. |
| `with_merge_status_recheck` | boolean       | Non       | Si `true`, cette projection demande (sans garantie) un recalcul asynchrone du champ `merge_status`. Activez le [feature flag](../administration/feature_flags/_index.md) `restrict_merge_status_recheck` pour ignorer cet attribut lorsqu'il est demandé par des utilisateurs sans le rôle Développeur, Mainteneur ou Propriétaire. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes). Si `view` est défini sur `simple`, retourne un sous-ensemble de champs. Sinon, les attributs de la réponse incluent :

| Attribut                                | Type     | Description |
|------------------------------------------|----------|-------------|
| `allow_collaboration`                    | boolean  | Si `true`, cette duplication autorise la collaboration des membres pouvant fusionner vers la branche cible. Utilisé uniquement pour les merge requests issues de duplications. |
| `allow_maintainer_to_push`               | boolean  | Obsolète. Utilisez `allow_collaboration` à la place. |
| `approvals_before_merge`                 | entier  | [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) dans GitLab 16.0. Pour configurer les règles d'approbation, consultez plutôt l'[API d'approbation des merge requests](merge_request_approvals.md). GitLab Premium et Ultimate uniquement. |
| `assignee[]`                             | objet   | Obsolète. Utilisez `assignees` à la place. |
| `assignees[]`                            | tableau    | Utilisateurs assignés à la merge request. |
| `assignees.avatar_url`                   | string   | URL complète de l'image d'avatar de l'assigné. |
| `assignees.id`                           | entier  | L'identifiant unique de l'assigné. |
| `assignees.locked`                       | boolean  | Si `true`, le compte de l'assigné est verrouillé en raison de tentatives d'authentification échouées, et il ne peut pas se connecter tant que le verrouillage n'expire pas ou qu'un administrateur ne déverrouille pas le compte. |
| `assignees.name`                         | string   | Nom d'affichage de l'assigné. Peut être masqué, en fonction des permissions de l'utilisateur actuel. |
| `assignees.public_email`                 | string   | L'adresse e-mail publique de l'assigné. |
| `assignees.state`                        | string   | État actuel du compte utilisateur de l'assigné. Valeurs possibles : `active`, `blocked`, ou `deactivated`. |
| `assignees.username`                     | string   | Nom d'utilisateur de l'assigné de la merge request. |
| `assignees.web_url`                      | string   | URL complète vers la page de profil de l'assigné. |
| `author[]`                               | objet   | Objet contenant des informations sur l'utilisateur qui a créé la merge request. |
| `author.avatar_url`                      | string   | URL complète de l'image d'avatar de l'auteur. |
| `author.id`                              | entier  | L'identifiant unique de l'utilisateur qui a créé la merge request. |
| `author.locked`                          | boolean  | Si `true`, le compte de l'auteur est verrouillé en raison de tentatives d'authentification échouées, et il ne peut pas se connecter tant que le verrouillage n'expire pas ou qu'un administrateur ne déverrouille pas le compte. |
| `author.name`                            | string   | Nom d'affichage de l'auteur. Peut être masqué, en fonction des permissions de l'utilisateur actuel. |
| `author.public_email`                    | string   | L'adresse e-mail publique de l'auteur. |
| `author.state`                           | string   | État actuel du compte utilisateur. Valeurs possibles : `active`, `blocked`, ou `deactivated`. |
| `author.username`                        | string   | Nom d'utilisateur de l'auteur de la merge request. |
| `author.web_url`                         | string   | URL complète vers la page de profil de l'auteur. |
| `blocking_discussions_resolved`          | boolean  | Si `true`, tous les fils de discussion de la merge request doivent être résolus avant la fusion. |
| `closed_at`                              | dateTime | Horodatage de la fermeture de la merge request. |
| `closed_by[]`                            | objet   | Objet contenant des informations sur l'utilisateur qui a fermé la merge request. Si `null`, la merge request est ouverte. |
| `closed_by.avatar_url`                   | string   | URL complète de l'image d'avatar de l'utilisateur qui a fermé la merge request. |
| `closed_by.id`                           | entier  | L'identifiant unique de l'utilisateur qui a fermé la merge request. |
| `closed_by.locked`                       | boolean  | Si `true`, le compte de l'utilisateur qui a fermé la merge request est verrouillé en raison de tentatives d'authentification échouées, et il ne peut pas se connecter tant que le verrouillage n'expire pas ou qu'un administrateur ne déverrouille pas le compte. |
| `closed_by.name`                         | string   | Nom d'affichage de l'utilisateur qui a fermé la merge request. Peut être masqué, en fonction des permissions de l'utilisateur actuel. |
| `closed_by.public_email`                 | string   | L'adresse e-mail publique de l'utilisateur qui a fermé la merge request. |
| `closed_by.state`                        | string   | État actuel du compte de l'utilisateur qui a fermé la merge request. Valeurs possibles : `active`, `blocked`, ou `deactivated`. |
| `closed_by.username`                     | string   | Nom d'utilisateur de l'utilisateur qui a fermé la merge request. |
| `closed_by.web_url`                      | string   | URL complète vers la page de profil de l'utilisateur qui a fermé la merge request. |
| `created_at`                             | dateTime | Horodatage de la création de la merge request. |
| `description`                            | string   | Description de la merge request. Contient le Markdown rendu en HTML pour la mise en cache. |
| `description_html`                       | string   | Si `render_html` est défini, la version HTML rendue de la description. |
| `detailed_merge_status`                  | string   | Informations détaillées sur le statut de fusion. Voir [statut de fusion](#merge-status) pour une liste des valeurs potentielles. |
| `discussion_locked`                      | boolean  | Si `true`, les discussions sont verrouillées. Seuls les membres du projet peuvent ajouter, modifier ou résoudre des commentaires dans les discussions verrouillées. |
| `downvotes`                              | entier  | Nombre de votes négatifs pour la merge request. |
| `draft`                                  | boolean  | Si `true`, la merge request est marquée dans un état `draft`. |
| `force_remove_source_branch`             | boolean  | Si `true`, les paramètres du projet imposent la suppression de la branche source après la fusion. |
| `has_conflicts`                          | boolean  | Si `true`, la merge request présente des conflits et ne peut pas être fusionnée. Dépend de la propriété `merge_status`. Retourne `false` sauf si `merge_status` est `cannot_be_merged`. |
| `id`                                     | entier  | L'identifiant unique de la merge request. |
| `iid`                                    | entier  | L'identifiant interne de la merge request dans le projet. |
| `imported`                               | boolean  | Si `true`, la merge request a été importée. |
| `imported_from`                          | string   | Source de l'import, comme `Bitbucket`. |
| `labels[]`                               | tableau    | Tableau des labels assignés à la merge request. Si `with_labels_details` est `true`, retourne un tableau pour chaque label. |
| `labels.archived`                        | boolean  | Si `with_labels_details` est `true`, le label est archivé. |
| `labels.color`                           | string   | Si `with_labels_details` est `true`, la couleur d'arrière-plan du label. |
| `labels.description`                     | string   | Si `with_labels_details` est `true`, le texte de description du label. Si `null`, le label n'a pas de description. |
| `labels.description_html`.               | string   | Si `with_labels_details` est `true`, la description rendue en HTML du label. Si `null`, le label n'a pas de description. |
| `labels.id`                              | entier  | Si `with_labels_details` est `true`, l'identifiant unique du label. |
| `labels.name`                            | string   | Si `with_labels_details` est `true`, le nom du label. |
| `labels.text_color`                      | string   | Si `with_labels_details` est `true`, la couleur du texte du label. |
| `merge_after`                            | dateTime | Si défini, horodatage à partir duquel la merge request peut être fusionnée. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/510992) dans GitLab 17.8. |
| `merge_commit_sha`                       | string   | Si défini, le SHA du commit de fusion de la merge request. Retourne `null` jusqu'à la fusion. |
| `merge_status`                           | string   | Statut de la merge request. Utilisez plutôt `detailed_merge_status`, qui tient compte de tous les statuts potentiels. Affecte la propriété `has_conflicts`. Pour les notes importantes sur les données de réponse, voir [notes sur la réponse d'une merge request unique](#single-merge-request-response-notes). [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/3169#note_1162532204) dans GitLab 15.6.  |
| `merge_user`                             | objet   | Objet contenant des informations sur l'utilisateur qui a fusionné la merge request, l'a définie en fusion automatique, ou `null`. |
| `merge_when_pipeline_succeeds`           | boolean  | Si `true`, la merge request est définie en fusion automatique. |
| `merged_at`                              | dateTime | Horodatage de la fusion de la merge request. |
| `merged_by[]`                            | objet   | Obsolète. Utilisez `merge_user` à la place. |
| `milestone[]`                            | objet   | Objet contenant des informations sur le jalon assigné à la merge request. |
| `milestone.created_at`                   | dateTime | Horodatage de la création du jalon. |
| `milestone.description`                  | string   | Texte de description du jalon. Si `null`, le jalon n'a pas de description. |
| `milestone.due_date`                     | date     | Date d'échéance du jalon. Si `null`, le jalon n'a pas de date d'échéance. |
| `milestone.expired`                      | boolean  | Si `true`, le jalon a expiré. |
| `milestone.group_id`                     | entier  | Identifiant du groupe auquel appartient le jalon. Inclus uniquement si le jalon est un jalon de groupe. |
| `milestone.id`                           | entier  | Identifiant unique du jalon. |
| `milestone.iid`                          | entier  | Identifiant interne du jalon dans le projet ou le groupe. |
| `milestone.project_id`                   | entier  | Identifiant du projet auquel appartient le jalon. Inclus uniquement si le jalon est un jalon de projet. |
| `milestone.start_date`                   | date     | Date de début du jalon. Si `null`, le jalon n'a pas de date de début |
| `milestone.state`                        | string   | État actuel du jalon, comme `active` ou `closed`. |
| `milestone.title`                        | string   | Nom du jalon. |
| `milestone.updated_at`                   | dateTime | Horodatage de la dernière mise à jour du jalon. |
| `milestone.web_url`                      | string   | URL web complète pour afficher le jalon. |
| `prepared_at`                            | dateTime | Horodatage de la préparation de la merge request. Ce champ est renseigné une seule fois, uniquement après la complétion de toutes les [étapes de préparation](#preparation-steps), et n'est pas mis à jour si d'autres modifications sont ajoutées. |
| `project_id`                             | entier  | L'identifiant du projet contenant la merge request. |
| `reference`                              | string   | Obsolète. Utilisez `references` à la place. |
| `references[]`                           | objet   | Objet avec toutes les références internes de la merge request. |
| `references.full`                        | string   | Référence complète d'une merge request, incluant le chemin complet du projet, comme `gitlab-org/gitlab!123`. Lorsqu'elle est demandée entre groupes ou projets, identique à `references.relative`. |
| `references.relative`                    | string   | Référence relative à un projet ou groupe spécifique : `!123` pour une merge request dans le projet actuel, ou `other-project!123` pour un autre projet dans le même groupe. |
| `references.short`                       | string   | Référence la plus courte possible vers une merge request, comme `!123`. Lorsqu'elle est récupérée depuis le projet de la merge request, identique à `references.relative`. |
| `reviewers[]`                            | tableau    | Relecteurs de la merge request. |
| `reviewers.avatar_url`                   | string   | URL complète de l'image d'avatar du relecteur. |
| `reviewers.id`                           | entier  | L'identifiant unique du relecteur. |
| `reviewers.locked`                       | boolean  | Si `true`, le compte du relecteur est verrouillé en raison de tentatives d'authentification échouées, et il ne peut pas se connecter tant que le verrouillage n'expire pas ou qu'un administrateur ne déverrouille pas le compte. |
| `reviewers.name`                         | string   | Nom d'affichage du relecteur. Peut être masqué, en fonction des permissions de l'utilisateur actuel. |
| `reviewers.public_email`                 | string   | L'adresse e-mail publique du relecteur. |
| `reviewers.state`                        | string   | État actuel du compte utilisateur du relecteur. Valeurs possibles : `active`, `blocked`, ou `deactivated`. |
| `reviewers.username`                     | string   | Nom d'utilisateur du relecteur de la merge request. |
| `reviewers.web_url`                      | string   | URL complète vers la page de profil du relecteur. |
| `sha`                                    | string   | SHA du commit head dans la branche source. |
| `should_remove_source_branch`            | boolean  | Si `true`, la branche source est supprimée après la fusion. |
| `source_branch`                          | string   | Nom de la branche source. |
| `source_project_id`                      | entier  | Identifiant du projet source. |
| `squash`                                 | boolean  | Si `true`, les commits sont squashés lors de la fusion. |
| `squash_commit_sha`                      | string   | Si défini, le SHA du commit squash. Vide jusqu'à la fusion. |
| `squash_on_merge`                        | boolean  | Si `true`, les commits sont squashés lors de la fusion. |
| `state`                                  | string   | L'état actuel de la merge request. Valeurs possibles : `opened`, `closed`, `merged`, ou `locked`. |
| `target_branch`                          | string   | Nom de la branche cible. |
| `target_project_id`                      | entier  | Identifiant du projet cible. |
| `task_completion_status[]`               | objet   | Objet contenant des informations sur l'état d'avancement de la liste de tâches. |
| `task_completion_status.completed_count` | entier  | Nombre d'éléments de liste de tâches complétés dans la description de la merge request. Retourne `0` si la merge request n'a pas de description ou pas d'éléments de liste de tâches. |
| `task_completion_status.count`           | entier  | Nombre total d'éléments de liste de tâches trouvés dans la description de la merge request. Retourne `0` si la merge request n'a pas de description ou pas d'éléments de liste de tâches. |
| `time_stats[]`                           | objet   | Objet contenant des informations sur le suivi du temps pour cette merge request. |
| `time_stats.human_time_estimate`         | string   | Format lisible par l'humain de `time_stats.time_estimate`, comme `3h 30m`. |
| `time_stats.human_total_time_spent`      | string   | Format lisible par l'humain de `time_stats.total_time_spent`, comme `3h 30m`. |
| `time_stats.time_estimate`               | entier  | Temps estimé pour compléter la merge request, en secondes. |
| `time_stats.total_time_spent`            | entier  | Temps total passé à travailler sur la merge request, en secondes. |
| `title`                                  | string   | Le titre de la merge request. |
| `title_html`                             | string   | Si `render_html` est `true`, la version HTML rendue du titre. |
| `updated_at`                             | dateTime | Horodatage de la dernière mise à jour de la merge request. |
| `upvotes`                                | entier  | Nombre de votes positifs pour la merge request. |
| `user_notes_count`                       | entier  | Nombre de commentaires utilisateur. |
| `web_url`                                | string   | URL web pour afficher la merge request. |
| `work_in_progress`                       | boolean  | Obsolète. Utilisez `draft` à la place. |

Autres réponses possibles :

- `401 Unauthorized` si le jeton d'accès est invalide.
- `408 Request Timeout` si la requête de base de données expire.
- `422 Unprocessable Entity` si la validation a échoué.
- `429 Too Many Requests` si le paramètre `search` est utilisé et que la requête a été soumise à une limite de débit.

Exemple de réponse :

```json
[
  {
    "id": 1,
    "iid": 1,
    "project_id": 3,
    "title": "test1",
    "description": "fixed login page css paddings",
    "state": "merged",
    "imported": false,
    "imported_from": "none",
    "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merge_user": {
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merged_at": "2018-09-07T11:16:17.520Z",
    "merge_after": "2018-09-07T11:16:00.000Z",
    "prepared_at": "2018-09-04T11:16:17.520Z",
    "closed_by": null,
    "closed_at": null,
    "created_at": "2017-04-29T08:46:00Z",
    "updated_at": "2017-04-29T08:46:00Z",
    "target_branch": "main",
    "source_branch": "test1",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignee": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignees": [{
      "name": "Miss Monserrate Beier",
      "username": "axel.block",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/axel.block"
    }],
    "reviewers": [{
      "id": 2,
      "name": "Sam Bauch",
      "username": "kenyatta_oconnell",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/956c92487c6f6f7616b536927e22c9a0?s=80&d=identicon",
      "web_url": "http://gitlab.example.com//kenyatta_oconnell"
    }],
    "source_project_id": 2,
    "target_project_id": 3,
    "labels": [
      "Community contribution",
      "Manage"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 5,
      "iid": 1,
      "project_id": 3,
      "title": "v2.0",
      "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
      "state": "closed",
      "created_at": "2015-02-02T19:49:26.013Z",
      "updated_at": "2015-02-02T19:49:26.013Z",
      "due_date": "2018-09-22",
      "start_date": "2018-08-08",
      "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
    },
    "merge_when_pipeline_succeeds": true,
    "merge_status": "can_be_merged",
    "detailed_merge_status": "not_open",
    "sha": "8888888888888888888888888888888888888888",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 1,
    "discussion_locked": null,
    "should_remove_source_branch": true,
    "force_remove_source_branch": false,
    "allow_collaboration": false,
    "allow_maintainer_to_push": false,
    "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
    "references": {
      "short": "!1",
      "relative": "my-group/my-project!1",
      "full": "my-group/my-project!1"
    },
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "squash": false,
    "task_completion_status":{
      "count":0,
      "completed_count":0
    }
  }
]
```

### Notes sur la réponse de liste des merge requests {#merge-requests-list-response-notes}

- L'affichage des merge requests peut ne pas mettre à jour de manière proactive `merge_status` (ce qui affecte également `has_conflicts`), car cette opération peut être coûteuse. Si vous avez besoin de la valeur de ces champs depuis cet endpoint, définissez le paramètre `with_merge_status_recheck` sur `true` dans la requête.
- Pour les notes sur les champs d'objet des merge requests, voir [notes sur la réponse d'une merge request unique](#single-merge-request-response-notes).

## Lister les merge requests d'un projet {#list-project-merge-requests}

Listez toutes les merge requests d'un projet.

```plaintext
GET /projects/:id/merge_requests
GET /projects/:id/merge_requests?state=opened
GET /projects/:id/merge_requests?state=all
GET /projects/:id/merge_requests?iids[]=42&iids[]=43
GET /projects/:id/merge_requests?milestone=release
GET /projects/:id/merge_requests?labels=bug,reproduced
GET /projects/:id/merge_requests?my_reaction_emoji=star
```

Attributs pris en charge :

| Attribut                       | Type           | Obligatoire | Description |
| ------------------------------- | -------------- | -------- | ----------- |
| `id`                            | entier ou chaîne | Oui   | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `iids[]`                        | tableau d'entiers  | Non       | Retourne les merge requests correspondant aux IID fournis. |
| `approved_by_ids[]`             | tableau d'entiers  | Non       | Retourne les merge requests approuvées par tous les utilisateurs avec l'`id` donné, jusqu'à 5 utilisateurs. `None` retourne les merge requests sans approbation. `Any` retourne les merge requests avec une approbation. |
| `approved_by_usernames[]`       | tableau de chaînes   | Non       | Retourne les merge requests approuvées par tous les utilisateurs avec l'`username` donné, jusqu'à 5 utilisateurs. `None` retourne les merge requests sans approbation. `Any` retourne les merge requests avec une approbation. |
| `approver_ids[]`                | tableau d'entiers  | Non       | Retourne les merge requests dont tous les utilisateurs avec l'`id` spécifié sont des approbateurs éligibles selon les règles d'approbation. `None` retourne les merge requests sans approbateur éligible. `Any` retourne les merge requests avec au moins un approbateur éligible. Premium et Ultimate uniquement. |
| `assignee_id`                   | entier ou chaîne | Non    | Retourne les merge requests assignées à l'utilisateur avec l'`id` donné. `None` retourne les merge requests non assignées. `Any` retourne les merge requests avec un assigné. Mutuellement exclusif avec `assignee_username`. |
| `assignee_username[]`           | tableau de chaînes   | Non       | Retourne les merge requests assignées aux noms d'utilisateur donnés. Mutuellement exclusif avec `assignee_id`. |
| `author_id`                     | entier        | Non       | Retourne les merge requests créées par l'utilisateur avec l'`id` donné. Mutuellement exclusif avec `author_username`. |
| `author_username`               | string         | Non       | Retourne les merge requests créées par le `username` donné. Mutuellement exclusif avec `author_id`. |
| `created_after`                 | datetime       | Non       | Retourne les merge requests créées à la date et l'heure données ou après. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `created_before`                | datetime       | Non       | Retourne les merge requests créées à la date et l'heure données ou avant. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `deployed_after`                | datetime       | Non       | Retourne les merge requests déployées après la date et l'heure données. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `deployed_before`               | datetime       | Non       | Retourne les merge requests déployées avant la date et l'heure données. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `environment`                   | string         | Non       | Retourne les merge requests déployées dans l'environnement donné. |
| `in`                            | string         | Non       | Modifie la portée de l'attribut `search`. `title`, `description`, ou une chaîne les joignant par une virgule. La valeur par défaut est `title,description`. |
| `labels`                        | string         | Non       | Retourne les merge requests correspondant à une liste de labels séparés par des virgules. `None` liste toutes les merge requests sans label. `Any` liste toutes les merge requests avec au moins un label. Les noms prédéfinis ne sont pas sensibles à la casse. |
| `merge_user_id`                 | entier        | Non       | Retourne les merge requests fusionnées par l'utilisateur avec l'`id` donné. Mutuellement exclusif avec `merge_user_username`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002) dans GitLab 17.0. |
| `merge_user_username`           | string         | Non       | Retourne les merge requests fusionnées par l'utilisateur avec le `username` donné. Mutuellement exclusif avec `merge_user_id`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002) dans GitLab 17.0. |
| `milestone`                     | string         | Non       | Retourne les merge requests pour un jalon spécifique. `None` retourne les merge requests sans jalon. `Any` retourne les merge requests avec un jalon assigné. |
| `my_reaction_emoji`             | string         | Non       | Retourne les merge requests auxquelles l'utilisateur authentifié a réagi avec l'`emoji` donné. `None` retourne les tickets sans réaction. `Any` retourne les tickets avec au moins une réaction. |
| `not`                           | hash           | Non       | Retourne les merge requests ne correspondant pas aux paramètres fournis. Accepte : `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `reviewer_id`, `reviewer_username`, `my_reaction_emoji`. |
| `order_by`                      | string         | Non       | Retourne les merge requests triées par les champs `created_at`, `updated_at`, `merged_at` ([introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147052) dans GitLab 17.2), `label_priority`, `priority`, `milestone_due`, `popularity`, ou `title`. La valeur par défaut est `created_at`. |
| `reviewer_id`                   | entier ou chaîne | Non    | Retourne les merge requests dont l'utilisateur est [relecteur](../user/project/merge_requests/reviews/_index.md) avec l'`id` donné. `None` retourne les merge requests sans relecteur. `Any` retourne les merge requests avec un relecteur quelconque. Mutuellement exclusif avec `reviewer_username`.  |
| `reviewer_username`             | string         | Non       | Retourne les merge requests dont l'utilisateur est [relecteur](../user/project/merge_requests/reviews/_index.md) avec le `username` donné. `None` retourne les merge requests sans relecteur. `Any` retourne les merge requests avec un relecteur quelconque. Mutuellement exclusif avec `reviewer_id`. |
| `scope`                         | string         | Non       | Retourne les merge requests pour la portée donnée : `created_by_me`, `assigned_to_me`, `reviews_for_me`, ou `all`. `reviews_for_me` retourne les merge requests où l'utilisateur actuel est assigné comme relecteur. La valeur par défaut est `all`. |
| `search`                        | string         | Non       | Recherche des merge requests par rapport à leur `title` et leur `description`. À combiner avec l'attribut `in`. |
| `sort`                          | string         | Non       | Retourne les merge requests triées dans l'ordre `asc` ou `desc`. La valeur par défaut est `desc`. |
| `source_branch`                 | string         | Non       | Retourne les merge requests avec la branche source donnée. |
| `state`                         | string         | Non       | Retourne toutes les merge requests (`all`) ou uniquement celles qui sont `opened`, `closed`, `locked`, ou `merged`. La valeur par défaut est `all`. |
| `target_branch`                 | string         | Non       | Retourne les merge requests avec la branche cible donnée. |
| `updated_after`                 | datetime       | Non       | Retourne les merge requests mises à jour à la date et l'heure données ou après. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `updated_before`                | datetime       | Non       | Retourne les merge requests mises à jour à la date et l'heure données ou avant. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `view`                          | string         | Non       | Si `simple`, retourne l'`iid`, l'URL, le titre, la description et l'état de base de la merge request. |
| `draft`                     | boolean           | Non       | Filtre les merge requests par leur statut `draft`. `true` retourne uniquement les merge requests en brouillon, `false` retourne les merge requests qui ne sont pas en brouillon. Mutuellement exclusif avec `wip`. |
| `wip`                       | string            | Non       | [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234098) dans GitLab 19.0. Utilisez `draft` à la place. Filtre les merge requests par leur statut `wip`. `yes` retourne uniquement les merge requests en brouillon, `no` retourne les merge requests qui ne sont pas en brouillon. |
| `with_labels_details`           | boolean        | Non       | Si `true`, la réponse renvoie plus de détails pour chaque label dans le champ labels : `:name`, `:color`, `:description`, `:description_html`, `:text_color`. La valeur par défaut est `false`. |
| `with_merge_status_recheck`     | boolean        | Non       | Si `true`, cette projection demande (sans garantie) un recalcul asynchrone du champ `merge_status`. Activez le [feature flag](../administration/feature_flags/_index.md) `restrict_merge_status_recheck` pour ignorer cet attribut lorsqu'il est demandé par des utilisateurs sans le rôle Développeur, Mainteneur ou Propriétaire. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                          | Type     | Description |
| ---------------------------------- | -------- | ----------- |
| `[].id`                            | entier  | Identifiant de la merge request. |
| `[].iid`                           | entier  | Identifiant interne de la merge request. |
| `[].approvals_before_merge`        | entier  | Nombre d'approbations requises avant que cette merge request puisse être fusionnée. Pour configurer les règles d'approbation, voir l'[API d'approbation des merge requests](merge_request_approvals.md). [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) dans GitLab 16.0. Premium et Ultimate uniquement. |
| `[].assignee`                      | objet   | Premier assigné de la merge request. |
| `[].assignees`                     | tableau    | Assignés de la merge request. |
| `[].author`                        | objet   | Utilisateur qui a créé cette merge request. |
| `[].blocking_discussions_resolved` | boolean  | Indique si toutes les discussions sont résolues, uniquement si elles sont toutes requises avant que la merge request puisse être fusionnée. |
| `[].closed_at`                     | datetime | Horodatage de la fermeture de la merge request. |
| `[].closed_by`                     | objet   | Utilisateur qui a fermé cette merge request. |
| `[].created_at`                    | datetime | Horodatage de la création de la merge request. |
| `[].description`                   | string   | Description de la merge request. |
| `[].detailed_merge_status`         | string   | Statut de fusion détaillé de la merge request. Voir [statut de fusion](#merge-status) pour une liste des valeurs potentielles. |
| `[].discussion_locked`             | boolean  | Indique si les commentaires sur la merge request sont réservés aux membres uniquement. |
| `[].downvotes`                     | entier  | Nombre de votes négatifs pour la merge request. |
| `[].draft`                         | boolean  | Indique si la merge request est un brouillon. |
| `[].force_remove_source_branch`    | boolean  | Indique si les paramètres du projet entraînent la suppression de la branche source après la fusion. |
| `[].has_conflicts`                 | boolean  | Indique si la merge request présente des conflits et ne peut pas être fusionnée. Dépend de la propriété `merge_status`. Retourne `false` sauf si `merge_status` est `cannot_be_merged`. |
| `[].labels`                        | tableau    | Labels de la merge request. |
| `[].merge_commit_sha`              | string   | SHA du commit de fusion de la merge request. Retourne `null` jusqu'à la fusion. |
| `[].merge_status`                  | string   | Statut de la merge request. Peut être `unchecked`, `checking`, `can_be_merged`, `cannot_be_merged`, ou `cannot_be_merged_recheck`. Affecte la propriété `has_conflicts`. Pour les notes importantes sur les données de réponse, voir [Notes sur la réponse d'une merge request unique](#single-merge-request-response-notes). [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/3169#note_1162532204) dans GitLab 15.6. Utilisez `detailed_merge_status` à la place.  |
| `[].merge_user`                    | objet   | Utilisateur qui a fusionné cette merge request, l'utilisateur qui l'a définie en fusion automatique, ou `null`. |
| `[].merge_when_pipeline_succeeds`  | boolean  | Indique si la merge request est définie en fusion automatique. |
| `[].merged_at`                     | datetime | Horodatage de la fusion de la merge request. |
| `[].merged_by`                     | objet   | Utilisateur qui a fusionné cette merge request ou l'a définie en fusion automatique. [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/350534) dans GitLab 14.7, et prévu pour suppression dans la [version 5 de l'API](https://gitlab.com/groups/gitlab-org/-/epics/8115). Utilisez `merge_user` à la place.  |
| `[].milestone`                     | objet   | Jalon de la merge request. |
| `[].prepared_at`                   | datetime | Horodatage de la préparation de la merge request. Ce champ est renseigné une seule fois, uniquement après la complétion de toutes les [étapes de préparation](#preparation-steps), et n'est pas mis à jour si d'autres modifications sont ajoutées. |
| `[].project_id`                    | entier  | Identifiant du projet où réside la merge request. Toujours égal à `target_project_id`. |
| `[].reference`                     | string   | Référence interne de la merge request. Retournée au format abrégé par défaut. [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20354) dans GitLab 12.7, et prévu pour suppression dans la [version 5 de l'API](https://gitlab.com/groups/gitlab-org/-/epics/8115). Utilisez `references` à la place.  |
| `[].references`                    | objet   | Références internes de la merge request. Inclut les références `short`, `relative`, et `full`. `references.relative` est relative au groupe ou au projet de la merge request. Lorsqu'elle est récupérée depuis le projet de la merge request, les formats `relative` et `short` sont identiques. Lorsqu'elle est demandée entre groupes ou projets, les formats `relative` et `full` sont identiques.|
| `[].reviewers`                     | tableau    | Relecteurs de la merge request. |
| `[].sha`                           | string   | SHA diff head de la merge request. |
| `[].should_remove_source_branch`   | boolean  | Indique si la branche source de la merge request doit être supprimée après la fusion. |
| `[].source_branch`                 | string   | Branche source de la merge request. |
| `[].source_project_id`             | entier  | Identifiant du projet source de la merge request. Égal à `target_project_id`, sauf si la merge request provient d'une duplication. |
| `[].squash`                        | boolean  | Si `true`, tous les commits sont squashés en un seul commit lors de la fusion. [Project settings](../user/project/merge_requests/squash_and_merge.md#configure-squash-options-for-a-project) peut remplacer cette valeur. Utilisez plutôt `squash_on_merge` pour prendre en compte les options de squash du projet. |
| `[].squash_commit_sha`             | string   | SHA du commit de squash. Vide jusqu'à la fusion. |
| `[].squash_on_merge`               | boolean  | Indique si le merge request doit être soumis à un squash lors de la fusion. |
| `[].state`                         | string   | État du merge request. Peut être `opened`, `closed`, `merged`, `locked`. |
| `[].target_branch`                 | string   | Branche cible du merge request. |
| `[].target_project_id`             | entier  | ID du projet cible du merge request. |
| `[].task_completion_status`        | objet   | Statut d'avancement des tâches. Inclut `count` et `completed_count`. |
| `[].time_stats`                    | objet   | Statistiques de suivi du temps pour le merge request. Inclut `time_estimate`, `total_time_spent`, `human_time_estimate` et `human_total_time_spent`. |
| `[].title`                         | string   | Titre du merge request. |
| `[].updated_at`                    | datetime | Horodatage de la dernière mise à jour du merge request. |
| `[].upvotes`                       | entier  | Nombre de votes positifs pour la merge request. |
| `[].user_notes_count`              | entier  | Nombre de notes utilisateur du merge request. |
| `[].web_url`                       | string   | URL web du merge request. |
| `[].work_in_progress`              | boolean  | Déprécié : Utilisez `draft` à la place. Indique si la merge request est un brouillon. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "iid": 1,
    "project_id": 3,
    "title": "test1",
    "description": "fixed login page css paddings",
    "state": "merged",
    "imported": false,
    "imported_from": "none",
    "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "locked": false,
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merge_user": {
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "locked": false,
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merged_at": "2018-09-07T11:16:17.520Z",
    "merge_after": "2018-09-07T11:16:00.000Z",
    "prepared_at": "2018-09-04T11:16:17.520Z",
    "closed_by": null,
    "closed_at": null,
    "created_at": "2017-04-29T08:46:00Z",
    "updated_at": "2017-04-29T08:46:00Z",
    "target_branch": "main",
    "source_branch": "test1",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "locked": false,
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignee": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "locked": false,
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignees": [{
      "name": "Miss Monserrate Beier",
      "username": "axel.block",
      "id": 12,
      "state": "active",
      "locked": false,
      "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/axel.block"
    }],
    "reviewers": [{
      "id": 2,
      "name": "Sam Bauch",
      "username": "kenyatta_oconnell",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/956c92487c6f6f7616b536927e22c9a0?s=80&d=identicon",
      "web_url": "http://gitlab.example.com//kenyatta_oconnell"
    }],
    "source_project_id": 2,
    "target_project_id": 3,
    "labels": [
      "Community contribution",
      "Manage"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 5,
      "iid": 1,
      "project_id": 3,
      "title": "v2.0",
      "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
      "state": "closed",
      "created_at": "2015-02-02T19:49:26.013Z",
      "updated_at": "2015-02-02T19:49:26.013Z",
      "due_date": "2018-09-22",
      "start_date": "2018-08-08",
      "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
    },
    "merge_when_pipeline_succeeds": true,
    "merge_status": "can_be_merged",
    "detailed_merge_status": "not_open",
    "sha": "8888888888888888888888888888888888888888",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 1,
    "discussion_locked": null,
    "should_remove_source_branch": true,
    "force_remove_source_branch": false,
    "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
    "reference": "!1",
    "references": {
      "short": "!1",
      "relative": "!1",
      "full": "my-group/my-project!1"
    },
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "squash": false,
    "squash_on_merge": false,
    "task_completion_status":{
      "count":0,
      "completed_count":0
    },
    "has_conflicts": false,
    "blocking_discussions_resolved": true,
    "approvals_before_merge": 2
  }
]
```

Pour les notes importantes sur les données de réponse, consultez [les notes sur la liste de réponses des merge requests](#merge-requests-list-response-notes).

## Lister les merge requests d'un groupe {#list-group-merge-requests}

Lister tous les merge requests d'un groupe et de ses sous-groupes.

```plaintext
GET /groups/:id/merge_requests
GET /groups/:id/merge_requests?state=opened
GET /groups/:id/merge_requests?state=all
GET /groups/:id/merge_requests?milestone=release
GET /groups/:id/merge_requests?labels=bug,reproduced
GET /groups/:id/merge_requests?my_reaction_emoji=star
```

Attributs pris en charge :

| Attribut                   | Type              | Obligatoire | Description |
|-----------------------------|-------------------|----------|-------------|
| `id`                        | entier ou chaîne | Oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `approved_by_ids[]`         | tableau d'entiers     | Non       | Retourne les merge requests approuvées par tous les utilisateurs avec l'`id` donné, jusqu'à 5 utilisateurs. `None` retourne les merge requests sans approbation. `Any` retourne les merge requests avec une approbation. |
| `approved_by_usernames[]`   | tableau de chaînes      | Non       | Retourne les merge requests approuvées par tous les utilisateurs avec l'`username` donné, jusqu'à 5 utilisateurs. `None` retourne les merge requests sans approbation. `Any` retourne les merge requests avec une approbation. |
| `approver_ids[]`            | tableau d'entiers     | Non       | Retourne les merge requests dont tous les utilisateurs avec l'`id` spécifié sont des approbateurs éligibles selon les règles d'approbation. `None` retourne les merge requests sans approbateur éligible. `Any` retourne les merge requests avec au moins un approbateur éligible. Premium et Ultimate uniquement. |
| `assignee_id`               | entier ou chaîne | Non       | Retourne les merge requests assignées à l'utilisateur avec l'`id` donné. `None` retourne les merge requests non assignées. `Any` retourne les merge requests avec un assigné. Mutuellement exclusif avec `assignee_username`. |
| `assignee_username[]`       | tableau de chaînes      | Non       | Retourne les merge requests assignées aux noms d'utilisateur donnés. Mutuellement exclusif avec `assignee_id`. |
| `author_id`                 | entier           | Non       | Retourne les merge requests créées par l'utilisateur avec l'`id` donné. Mutuellement exclusif avec `author_username`. |
| `author_username`           | string            | Non       | Retourne les merge requests créées par le `username` donné. Mutuellement exclusif avec `author_id`. |
| `created_after`             | datetime          | Non       | Retourne les merge requests créées à la date et l'heure données ou après. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `created_before`            | datetime          | Non       | Retourne les merge requests créées à la date et l'heure données ou avant. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `deployed_after`            | datetime          | Non       | Retourne les merge requests déployées après la date et l'heure données. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `deployed_before`           | datetime          | Non       | Retourne les merge requests déployées avant la date et l'heure données. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `environment`               | string            | Non       | Retourne les merge requests déployées dans l'environnement donné. |
| `in`                        | string            | Non       | Modifie la portée de l'attribut `search`. `title`, `description`, ou une chaîne les joignant par une virgule. La valeur par défaut est `title,description`. |
| `labels`                  | string             | Non       | Retourne les merge requests correspondant à une liste de labels séparés par des virgules. `None` liste toutes les merge requests sans label. `Any` liste toutes les merge requests avec au moins un label. Les noms prédéfinis ne sont pas sensibles à la casse. |
| `merge_user_id`             | entier           | Non       | Retourne les merge requests fusionnées par l'utilisateur avec l'`id` donné. Mutuellement exclusif avec `merge_user_username`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002) dans GitLab 17.0. |
| `merge_user_username`       | string            | Non       | Retourne les merge requests fusionnées par l'utilisateur avec le `username` donné. Mutuellement exclusif avec `merge_user_id`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002) dans GitLab 17.0. |
| `milestone`                 | string            | Non       | Retourne les merge requests pour un jalon spécifique. `None` retourne les merge requests sans jalon. `Any` retourne les merge requests avec un jalon assigné. |
| `my_reaction_emoji`         | string            | Non       | Retourne les merge requests auxquelles l'utilisateur authentifié a réagi avec l'`emoji` donné. `None` retourne les tickets sans réaction. `Any` retourne les tickets avec au moins une réaction. |
| `non_archived`              | boolean           | Non       | Si `true`, retourne uniquement les merge requests des projets non archivés. La valeur par défaut est `true`. |
| `not`                       | hash              | Non       | Retourne les merge requests ne correspondant pas aux paramètres fournis. Accepte : `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `reviewer_id`, `reviewer_username`, `my_reaction_emoji`. |
| `order_by`                  | string            | Non       | Retourne les merge requests triées par les champs `created_at`, `updated_at`, `merged_at` ([introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147052) dans GitLab 17.2), `label_priority`, `priority`, `milestone_due`, `popularity`, ou `title`. La valeur par défaut est `created_at`. |
| `reviewer_id`               | entier ou chaîne | Non       | Retourne les merge requests dont l'utilisateur est [relecteur](../user/project/merge_requests/reviews/_index.md) avec l'`id` donné. `None` retourne les merge requests sans relecteur. `Any` retourne les merge requests avec un relecteur quelconque. Mutuellement exclusif avec `reviewer_username`. |
| `reviewer_username`         | string            | Non       | Retourne les merge requests dont l'utilisateur est [relecteur](../user/project/merge_requests/reviews/_index.md) avec le `username` donné. `None` retourne les merge requests sans relecteur. `Any` retourne les merge requests avec un relecteur quelconque. Mutuellement exclusif avec `reviewer_id`. |
| `scope`                     | string            | Non       | Retourne les merge requests pour la portée donnée : `created_by_me`, `assigned_to_me`, `reviews_for_me`, ou `all`. `reviews_for_me` retourne les merge requests où l'utilisateur actuel est assigné comme relecteur. La valeur par défaut est `all`. |
| `search`                    | string            | Non       | Recherche des merge requests par rapport à leur `title` et leur `description`. À combiner avec l'attribut `in`. |
| `sort`                      | string            | Non       | Retourne les merge requests triées dans l'ordre `asc` ou `desc`. La valeur par défaut est `desc`. |
| `source_branch`             | string            | Non       | Retourne les merge requests avec la branche source donnée. |
| `source_project_id`         | entier           | Non       | Retourne les merge requests ayant l'ID de projet source donné. |
| `state`                     | string            | Non       | Retourne toutes les merge requests (`all`) ou uniquement celles qui sont `opened`, `closed`, `locked`, ou `merged`. La valeur par défaut est `all`. |
| `target_branch`             | string            | Non       | Retourne les merge requests avec la branche cible donnée. |
| `updated_after`             | datetime          | Non       | Retourne les merge requests mises à jour à la date et l'heure données ou après. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `updated_before`            | datetime          | Non       | Retourne les merge requests mises à jour à la date et l'heure données ou avant. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `view`                      | string            | Non       | Si `simple`, retourne l'`iid`, l'URL, le titre, la description et l'état de base de la merge request. |
| `draft`                     | boolean           | Non       | Filtre les merge requests par leur statut `draft`. `true` retourne uniquement les merge requests en brouillon, `false` retourne les merge requests qui ne sont pas en brouillon. Mutuellement exclusif avec `wip`. |
| `wip`                       | string            | Non       | [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/234098) dans GitLab 19.0. Utilisez `draft` à la place. Filtre les merge requests par leur statut `wip`. `yes` retourne uniquement les merge requests en brouillon, `no` retourne les merge requests qui ne sont pas en brouillon. |
| `with_labels_details`       | boolean           | Non       | Si `true`, la réponse renvoie plus de détails pour chaque label dans le champ labels : `:name`, `:color`, `:description`, `:description_html`, `:text_color`. La valeur par défaut est `false`. |
| `with_merge_status_recheck` | boolean           | Non       | Si `true`, cette projection demande (sans garantie) un recalcul asynchrone du champ `merge_status`. Activez le [feature flag](../administration/feature_flags/_index.md) `restrict_merge_status_recheck` pour ignorer cet attribut lorsqu'il est demandé par des utilisateurs sans le rôle Développeur, Mainteneur ou Propriétaire. |

Dans la réponse, `group_id` représente l'ID du groupe contenant le projet où réside le merge request.

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes). Si `view` est défini sur `simple`, retourne un sous-ensemble de champs. Sinon, les attributs de la réponse incluent :

| Attribut                                | Type     | Description |
|------------------------------------------|----------|-------------|
| `allow_collaboration`                    | boolean  | Si `true`, cette duplication autorise la collaboration des membres pouvant fusionner vers la branche cible. Utilisé uniquement pour les merge requests issues de duplications. |
| `allow_maintainer_to_push`               | boolean  | Obsolète. Utilisez `allow_collaboration` à la place. |
| `approvals_before_merge`                 | entier  | [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) dans GitLab 16.0. Pour configurer les règles d'approbation, consultez plutôt l'[API d'approbation des merge requests](merge_request_approvals.md). GitLab Premium et Ultimate uniquement. |
| `assignee[]`                             | objet   | Obsolète. Utilisez `assignees` à la place. |
| `assignees[]`                            | tableau    | Utilisateurs assignés à la merge request. |
| `assignees.avatar_url`                   | string   | URL complète de l'image d'avatar de l'assigné. |
| `assignees.id`                           | entier  | L'identifiant unique de l'assigné. |
| `assignees.locked`                       | boolean  | Si `true`, le compte de l'assigné est verrouillé en raison de tentatives d'authentification échouées, et il ne peut pas se connecter tant que le verrouillage n'expire pas ou qu'un administrateur ne déverrouille pas le compte. |
| `assignees.name`                         | string   | Nom d'affichage de l'assigné. Peut être masqué, en fonction des permissions de l'utilisateur actuel. |
| `assignees.public_email`                 | string   | L'adresse e-mail publique de l'assigné. |
| `assignees.state`                        | string   | État actuel du compte utilisateur de l'assigné. Valeurs possibles : `active`, `blocked`, ou `deactivated`. |
| `assignees.username`                     | string   | Nom d'utilisateur de l'assigné de la merge request. |
| `assignees.web_url`                      | string   | URL complète vers la page de profil de l'assigné. |
| `author[]`                               | objet   | Objet contenant des informations sur l'utilisateur qui a créé la merge request. |
| `author.avatar_url`                      | string   | URL complète de l'image d'avatar de l'auteur. |
| `author.id`                              | entier  | L'identifiant unique de l'utilisateur qui a créé la merge request. |
| `author.locked`                          | boolean  | Si `true`, le compte de l'auteur est verrouillé en raison de tentatives d'authentification échouées, et il ne peut pas se connecter tant que le verrouillage n'expire pas ou qu'un administrateur ne déverrouille pas le compte. |
| `author.name`                            | string   | Nom d'affichage de l'auteur. Peut être masqué, en fonction des permissions de l'utilisateur actuel. |
| `author.public_email`                    | string   | L'adresse e-mail publique de l'auteur. |
| `author.state`                           | string   | État actuel du compte utilisateur. Valeurs possibles : `active`, `blocked`, ou `deactivated`. |
| `author.username`                        | string   | Nom d'utilisateur de l'auteur de la merge request. |
| `author.web_url`                         | string   | URL complète vers la page de profil de l'auteur. |
| `blocking_discussions_resolved`          | boolean  | Si `true`, tous les fils de discussion de la merge request doivent être résolus avant la fusion. |
| `closed_at`                              | dateTime | Horodatage de la fermeture de la merge request. |
| `closed_by[]`                            | objet   | Objet contenant des informations sur l'utilisateur qui a fermé la merge request. Si `null`, la merge request est ouverte. |
| `closed_by.avatar_url`                   | string   | URL complète de l'image d'avatar de l'utilisateur qui a fermé la merge request. |
| `closed_by.id`                           | entier  | L'identifiant unique de l'utilisateur qui a fermé la merge request. |
| `closed_by.locked`                       | boolean  | Si `true`, le compte de l'utilisateur qui a fermé la merge request est verrouillé en raison de tentatives d'authentification échouées, et il ne peut pas se connecter tant que le verrouillage n'expire pas ou qu'un administrateur ne déverrouille pas le compte. |
| `closed_by.name`                         | string   | Nom d'affichage de l'utilisateur qui a fermé la merge request. Peut être masqué, en fonction des permissions de l'utilisateur actuel. |
| `closed_by.public_email`                 | string   | L'adresse e-mail publique de l'utilisateur qui a fermé la merge request. |
| `closed_by.state`                        | string   | État actuel du compte de l'utilisateur qui a fermé la merge request. Valeurs possibles : `active`, `blocked`, ou `deactivated`. |
| `closed_by.username`                     | string   | Nom d'utilisateur de l'utilisateur qui a fermé la merge request. |
| `closed_by.web_url`                      | string   | URL complète vers la page de profil de l'utilisateur qui a fermé la merge request. |
| `created_at`                             | dateTime | Horodatage de la création de la merge request. |
| `description`                            | string   | Description de la merge request. Contient le Markdown rendu en HTML pour la mise en cache. |
| `detailed_merge_status`                  | string   | Informations détaillées sur le statut de fusion. Voir [statut de fusion](#merge-status) pour une liste des valeurs potentielles. |
| `discussion_locked`                      | boolean  | Si `true`, les discussions sont verrouillées. Seuls les membres du projet peuvent ajouter, modifier ou résoudre des commentaires dans les discussions verrouillées. |
| `downvotes`                              | entier  | Nombre de votes négatifs pour la merge request. |
| `draft`                                  | boolean  | Si `true`, la merge request est marquée dans un état `draft`. |
| `force_remove_source_branch`             | boolean  | Si `true`, les paramètres du projet imposent la suppression de la branche source après la fusion. |
| `has_conflicts`                          | boolean  | Si `true`, la merge request présente des conflits et ne peut pas être fusionnée. Dépend de la propriété `merge_status`. Retourne `false` sauf si `merge_status` est `cannot_be_merged`. |
| `id`                                     | entier  | L'identifiant unique de la merge request. |
| `iid`                                    | entier  | L'identifiant interne de la merge request dans le projet. |
| `imported`                               | boolean  | Si `true`, la merge request a été importée. |
| `imported_from`                          | string   | Source de l'import, comme `Bitbucket`. |
| `labels[]`                               | tableau    | Tableau des labels assignés à la merge request. Si `with_labels_details` est `true`, retourne un tableau pour chaque label. |
| `labels.archived`                        | boolean  | Si `with_labels_details` est `true`, le label est archivé. |
| `labels.color`                           | string   | Si `with_labels_details` est `true`, la couleur d'arrière-plan du label. |
| `labels.description`                     | string   | Si `with_labels_details` est `true`, le texte de description du label. Si `null`, le label n'a pas de description. |
| `labels.description_html`                | string   | Si `with_labels_details` est `true`, la description rendue en HTML du label. Si `null`, le label n'a pas de description. |
| `labels.id`                              | entier  | Si `with_labels_details` est `true`, l'identifiant unique du label. |
| `labels.name`                            | string   | Si `with_labels_details` est `true`, le nom du label. |
| `labels.text_color`                      | string   | Si `with_labels_details` est `true`, la couleur du texte du label. |
| `merge_after`                            | dateTime | Si défini, horodatage à partir duquel la merge request peut être fusionnée. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/510992) dans GitLab 17.8. |
| `merge_commit_sha`                       | string   | Si défini, le SHA du commit de fusion de la merge request. Retourne `null` jusqu'à la fusion. |
| `merge_status`                           | string   | Statut de la merge request. Utilisez plutôt `detailed_merge_status`, qui tient compte de tous les statuts potentiels. Affecte la propriété `has_conflicts`. Pour les notes importantes sur les données de réponse, voir [notes sur la réponse d'une merge request unique](#single-merge-request-response-notes). [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/3169#note_1162532204) dans GitLab 15.6.  |
| `merge_user`                             | objet   | Objet contenant des informations sur l'utilisateur qui a fusionné la merge request, l'a définie en fusion automatique, ou `null`. |
| `merge_when_pipeline_succeeds`           | boolean  | Si `true`, la merge request est définie en fusion automatique. |
| `merged_at`                              | dateTime | Horodatage de la fusion de la merge request. |
| `merged_by[]`                            | objet   | Obsolète. Utilisez `merge_user` à la place. |
| `milestone[]`                            | objet   | Objet contenant des informations sur le jalon assigné à la merge request. |
| `milestone.created_at`                   | dateTime | Horodatage de la création du jalon. |
| `milestone.description`                  | string   | Texte de description du jalon. Si `null`, le jalon n'a pas de description. |
| `milestone.due_date`                     | date     | Date d'échéance du jalon. Si `null`, le jalon n'a pas de date d'échéance. |
| `milestone.expired`                      | boolean  | Si `true`, le jalon a expiré. |
| `milestone.group_id`                     | entier  | Identifiant du groupe auquel appartient le jalon. Inclus uniquement si le jalon est un jalon de groupe. |
| `milestone.id`                           | entier  | Identifiant unique du jalon. |
| `milestone.iid`                          | entier  | Identifiant interne du jalon dans le projet ou le groupe. |
| `milestone.project_id`                   | entier  | Identifiant du projet auquel appartient le jalon. Inclus uniquement si le jalon est un jalon de projet. |
| `milestone.start_date`                   | date     | Date de début du jalon. Si `null`, le jalon n'a pas de date de début |
| `milestone.state`                        | string   | État actuel du jalon, comme `active` ou `closed`. |
| `milestone.title`                        | string   | Nom du jalon. |
| `milestone.updated_at`                   | dateTime | Horodatage de la dernière mise à jour du jalon. |
| `milestone.web_url`                      | string   | URL web complète pour afficher le jalon. |
| `prepared_at`                            | dateTime | Horodatage de la préparation de la merge request. Ce champ est renseigné une seule fois, uniquement après la complétion de toutes les [étapes de préparation](#preparation-steps), et n'est pas mis à jour si d'autres modifications sont ajoutées. |
| `project_id`                             | entier  | L'identifiant du projet contenant la merge request. |
| `reference`                              | string   | Obsolète. Utilisez `references` à la place. |
| `references[]`                           | objet   | Objet avec toutes les références internes de la merge request. |
| `references.full`                        | string   | Référence complète d'une merge request, incluant le chemin complet du projet, comme `gitlab-org/gitlab!123`. Lorsqu'elle est demandée entre groupes ou projets, identique à `references.relative`. |
| `references.relative`                    | string   | Référence relative à un projet ou groupe spécifique : `!123` pour une merge request dans le projet actuel, ou `other-project!123` pour un autre projet dans le même groupe. |
| `references.short`                       | string   | Référence la plus courte possible vers une merge request, comme `!123`. Lorsqu'elle est récupérée depuis le projet de la merge request, identique à `references.relative`. |
| `reviewers[]`                            | tableau    | Relecteurs de la merge request. |
| `reviewers.avatar_url`                   | string   | URL complète de l'image d'avatar du relecteur. |
| `reviewers.id`                           | entier  | L'identifiant unique du relecteur. |
| `reviewers.locked`                       | boolean  | Si `true`, le compte du relecteur est verrouillé en raison de tentatives d'authentification échouées, et il ne peut pas se connecter tant que le verrouillage n'expire pas ou qu'un administrateur ne déverrouille pas le compte. |
| `reviewers.name`                         | string   | Nom d'affichage du relecteur. Peut être masqué, en fonction des permissions de l'utilisateur actuel. |
| `reviewers.public_email`                 | string   | L'adresse e-mail publique du relecteur. |
| `reviewers.state`                        | string   | État actuel du compte utilisateur du relecteur. Valeurs possibles : `active`, `blocked`, ou `deactivated`. |
| `reviewers.username`                     | string   | Nom d'utilisateur du relecteur de la merge request. |
| `reviewers.web_url`                      | string   | URL complète vers la page de profil du relecteur. |
| `sha`                                    | string   | SHA du commit head dans la branche source. |
| `should_remove_source_branch`            | boolean  | Si `true`, la branche source est supprimée après la fusion. |
| `source_branch`                          | string   | Nom de la branche source. |
| `source_project_id`                      | entier  | Identifiant du projet source. |
| `squash`                                 | boolean  | Si `true`, les commits sont squashés lors de la fusion. |
| `squash_commit_sha`                      | string   | Si défini, le SHA du commit squash. Vide jusqu'à la fusion. |
| `squash_on_merge`                        | boolean  | Si `true`, les commits sont squashés lors de la fusion. |
| `state`                                  | string   | L'état actuel de la merge request. Valeurs possibles : `opened`, `closed`, `merged`, ou `locked`. |
| `target_branch`                          | string   | Nom de la branche cible. |
| `target_project_id`                      | entier  | Identifiant du projet cible. |
| `task_completion_status[]`               | objet   | Objet contenant des informations sur l'état d'avancement de la liste de tâches. |
| `task_completion_status.completed_count` | entier  | Nombre d'éléments de liste de tâches complétés dans la description de la merge request. Retourne `0` si la merge request n'a pas de description ou pas d'éléments de liste de tâches. |
| `task_completion_status.count`           | entier  | Nombre total d'éléments de liste de tâches trouvés dans la description de la merge request. Retourne `0` si la merge request n'a pas de description ou pas d'éléments de liste de tâches. |
| `time_stats[]`                           | objet   | Objet contenant des informations sur le suivi du temps pour cette merge request. |
| `time_stats.human_time_estimate`         | string   | Format lisible par l'humain de `time_stats.time_estimate`, comme `3h 30m`. |
| `time_stats.human_total_time_spent`      | string   | Format lisible par l'humain de `time_stats.total_time_spent`, comme `3h 30m`. |
| `time_stats.time_estimate`               | entier  | Temps estimé pour compléter la merge request, en secondes. |
| `time_stats.total_time_spent`            | entier  | Temps total passé à travailler sur la merge request, en secondes. |
| `title`                                  | string   | Le titre de la merge request. |
| `updated_at`                             | dateTime | Horodatage de la dernière mise à jour de la merge request. |
| `upvotes`                                | entier  | Nombre de votes positifs pour la merge request. |
| `user_notes_count`                       | entier  | Nombre de commentaires utilisateur. |
| `web_url`                                | string   | URL web pour afficher la merge request. |
| `work_in_progress`                       | boolean  | Obsolète. Utilisez `draft` à la place. |

Autres réponses possibles :

- `401 Unauthorized` si le jeton d'accès est invalide.
- `404 Not Found` si le projet ou le merge request est introuvable.
- `422 Unprocessable Entity` si la validation a échoué.
- `429 Too Many Requests` si le paramètre `search` est utilisé et que la requête a été soumise à une limite de débit.

Exemple de réponse :

```json
[
  {
    "id": 1,
    "iid": 1,
    "project_id": 3,
    "title": "test1",
    "description": "fixed login page css paddings",
    "state": "merged",
    "imported": false,
    "imported_from": "none",
    "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merge_user": {
      "id": 87854,
      "name": "Douwe Maan",
      "username": "DouweM",
      "state": "active",
      "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
      "web_url": "https://gitlab.com/DouweM"
    },
    "merged_at": "2018-09-07T11:16:17.520Z",
    "merge_after": "2018-09-07T11:16:00.000Z",
    "prepared_at": "2018-09-04T11:16:17.520Z",
    "closed_by": null,
    "closed_at": null,
    "created_at": "2017-04-29T08:46:00Z",
    "updated_at": "2017-04-29T08:46:00Z",
    "target_branch": "main",
    "source_branch": "test1",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignee": {
      "id": 1,
      "name": "Administrator",
      "username": "admin",
      "state": "active",
      "avatar_url": null,
      "web_url" : "https://gitlab.example.com/admin"
    },
    "assignees": [{
      "name": "Miss Monserrate Beier",
      "username": "axel.block",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/axel.block"
    }],
    "reviewers": [{
      "id": 2,
      "name": "Sam Bauch",
      "username": "kenyatta_oconnell",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/956c92487c6f6f7616b536927e22c9a0?s=80&d=identicon",
      "web_url": "http://gitlab.example.com//kenyatta_oconnell"
    }],
    "source_project_id": 2,
    "target_project_id": 3,
    "labels": [
      "Community contribution",
      "Manage"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 5,
      "iid": 1,
      "project_id": 3,
      "title": "v2.0",
      "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
      "state": "closed",
      "created_at": "2015-02-02T19:49:26.013Z",
      "updated_at": "2015-02-02T19:49:26.013Z",
      "due_date": "2018-10-22",
      "start_date": "2018-09-08",
      "web_url": "gitlab.example.com/my-group/my-project/milestones/1"
    },
    "merge_when_pipeline_succeeds": true,
    "merge_status": "can_be_merged",
    "detailed_merge_status": "not_open",
    "sha": "8888888888888888888888888888888888888888",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 1,
    "discussion_locked": null,
    "should_remove_source_branch": true,
    "force_remove_source_branch": false,
    "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
    "references": {
      "short": "!1",
      "relative": "my-project!1",
      "full": "my-group/my-project!1"
    },
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "squash": false,
    "task_completion_status":{
      "count":0,
      "completed_count":0
    },
    "has_conflicts": false,
    "blocking_discussions_resolved": true
  }
]
```

Pour les notes importantes sur les données de réponse, consultez [les notes sur la liste de réponses des merge requests](#merge-requests-list-response-notes).

## Récupérer un merge request {#retrieve-a-merge-request}

Récupérer des informations sur un merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid
```

Attributs pris en charge :

| Attribut                        | Type              | Obligatoire | Description |
|----------------------------------|-------------------|----------|-------------|
| `id`                             | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid`              | entier           | Oui      | L'ID interne du merge request. |
| `include_diverged_commits_count` | boolean           | Non       | Si `true`, la réponse inclut les commits en retard par rapport à la branche cible. |
| `include_rebase_in_progress`     | boolean           | Non       | Si `true`, la réponse indique si une opération de rebase est en cours. |
| `render_html`                    | boolean           | Non       | Si `true`, la réponse inclut le HTML rendu pour le titre et la description. |

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes). Autres réponses possibles :

- `401 Unauthorized` si le jeton d'accès est invalide.
- `403 Forbidden` si l'accès est refusé.
- `404 Not Found` si le projet ou le merge request est introuvable.
- `408 Request Timeout` si la requête de base de données expire.
- `409 Conflict` si un conflit de verrouillage de ressource existe.
- `422 Unprocessable Entity` si la validation a échoué.
- `429 Too Many Requests` si le paramètre `search` est utilisé et que la requête a été soumise à une limite de débit.

### Réponse {#response}

| Attribut                                                   | Type     | Description |
|-------------------------------------------------------------|----------|-------------|
| `allow_collaboration`                                       | boolean  | Si `true`, cette duplication autorise la collaboration des membres pouvant fusionner vers la branche cible. Utilisé uniquement pour les merge requests issues de duplications. |
| `allow_maintainer_to_push`                                  | boolean  | Obsolète. Utilisez `allow_collaboration` à la place. |
| `approvals_before_merge`                                    | entier  | [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) dans GitLab 16.0. Pour configurer les règles d'approbation, consultez plutôt l'[API d'approbation des merge requests](merge_request_approvals.md). GitLab Premium et Ultimate uniquement. |
| `assignee[]`                                                | objet   | Obsolète. Utilisez `assignees` à la place. |
| `assignees[]`                                               | tableau    | Utilisateurs assignés à la merge request. |
| `assignees.avatar_url`                                      | string   | URL complète de l'image d'avatar de l'assigné. |
| `assignees.id`                                              | entier  | L'identifiant unique de l'assigné. |
| `assignees.locked`                                          | boolean  | Si `true`, le compte de l'assigné est verrouillé en raison de tentatives d'authentification échouées, et il ne peut pas se connecter tant que le verrouillage n'expire pas ou qu'un administrateur ne déverrouille pas le compte. |
| `assignees.name`                                            | string   | Nom d'affichage de l'assigné. Peut être masqué, en fonction des permissions de l'utilisateur actuel. |
| `assignees.public_email`                                    | string   | L'adresse e-mail publique de l'assigné. |
| `assignees.state`                                           | string   | État actuel du compte utilisateur de l'assigné. Valeurs possibles : `active`, `blocked`, ou `deactivated`. |
| `assignees.username`                                        | string   | Nom d'utilisateur de l'assigné de la merge request. |
| `assignees.web_url`                                         | string   | URL complète vers la page de profil de l'assigné. |
| `author[]`                                                  | objet   | Objet contenant des informations sur l'utilisateur qui a créé la merge request. |
| `author.avatar_url`                                         | string   | URL complète de l'image d'avatar de l'auteur. |
| `author.id`                                                 | entier  | L'identifiant unique de l'utilisateur qui a créé la merge request. |
| `author.locked`                                             | boolean  | Si `true`, le compte de l'auteur est verrouillé en raison de tentatives d'authentification échouées, et il ne peut pas se connecter tant que le verrouillage n'expire pas ou qu'un administrateur ne déverrouille pas le compte. |
| `author.name`                                               | string   | Nom d'affichage de l'auteur. Peut être masqué, en fonction des permissions de l'utilisateur actuel. |
| `author.public_email`                                       | string   | L'adresse e-mail publique de l'auteur. |
| `author.state`                                              | string   | État actuel du compte utilisateur. Valeurs possibles : `active`, `blocked`, ou `deactivated`. |
| `author.username`                                           | string   | Nom d'utilisateur de l'auteur de la merge request. |
| `author.web_url`                                            | string   | URL complète vers la page de profil de l'auteur. |
| `blocking_discussions_resolved`                             | boolean  | Si `true`, tous les fils de discussion de la merge request doivent être résolus avant la fusion. |
| `changes_count`                                             | string   | Si défini, le nombre de modifications apportées au merge request. Vide lors de la création du merge request. Se renseigne de manière asynchrone. Une chaîne, pas un entier. Lorsqu'un merge request comporte trop de modifications à afficher et à stocker, la valeur est plafonnée à 1000 et retourne la chaîne `"1000+"`. Consultez [les champs API vides pour les nouveaux merge requests](#empty-api-fields-for-new-merge-requests). |
| `closed_at`                                                 | dateTime | Horodatage de la fermeture de la merge request. |
| `closed_by[]`                                               | objet   | Objet contenant des informations sur l'utilisateur qui a fermé la merge request. Si `null`, la merge request est ouverte. |
| `closed_by.avatar_url`                                      | string   | URL complète de l'image d'avatar de l'utilisateur qui a fermé la merge request. |
| `closed_by.id`                                              | entier  | L'identifiant unique de l'utilisateur qui a fermé la merge request. |
| `closed_by.locked`                                          | boolean  | Si `true`, le compte de l'utilisateur qui a fermé la merge request est verrouillé en raison de tentatives d'authentification échouées, et il ne peut pas se connecter tant que le verrouillage n'expire pas ou qu'un administrateur ne déverrouille pas le compte. |
| `closed_by.name`                                            | string   | Nom d'affichage de l'utilisateur qui a fermé la merge request. Peut être masqué, en fonction des permissions de l'utilisateur actuel. |
| `closed_by.public_email`                                    | string   | L'adresse e-mail publique de l'utilisateur qui a fermé la merge request. |
| `closed_by.state`                                           | string   | État actuel du compte de l'utilisateur qui a fermé la merge request. Valeurs possibles : `active`, `blocked`, ou `deactivated`. |
| `closed_by.username`                                        | string   | Nom d'utilisateur de l'utilisateur qui a fermé la merge request. |
| `closed_by.web_url`                                         | string   | URL complète vers la page de profil de l'utilisateur qui a fermé la merge request. |
| `created_at`                                                | datetime | Horodatage de la création de la merge request. |
| `description`                                               | string   | Description de la merge request. Contient le Markdown rendu en HTML pour la mise en cache. |
| `detailed_merge_status`                                     | string   | Informations détaillées sur le statut de fusion. Voir [statut de fusion](#merge-status) pour une liste des valeurs potentielles. |
| `diff_refs[]`                                               | objet   | Objet contenant les références des SHA de base, de tête et de départ pour ce merge request. Correspond à la dernière version de diff du merge request. Vide lors de la création du merge request et se renseigne de manière asynchrone. Consultez [les champs API vides pour les nouveaux merge requests](#empty-api-fields-for-new-merge-requests). |
| `diff_refs.base_sha`                                        | string   | SHA du commit de base de fusion où les branches source et cible ont divergé. |
| `diff_refs.start_sha`                                       | string   | SHA du commit de la branche cible. Le point de départ du diff. Généralement identique à `base_sha`. |
| `diff_refs.head_sha`                                        | string   | SHA du commit head dans la branche source. Le dernier commit dans le merge request. |
| `discussion_locked`                                         | boolean  | Si `true`, les discussions sont verrouillées. Seuls les membres du projet peuvent ajouter, modifier ou résoudre des commentaires dans les discussions verrouillées. |
| `diverged_commits_count`                                    | entier  | Si défini, contient le nombre de commits en retard de la branche source par rapport à la branche cible. |
| `downvotes`                                                 | entier  | Nombre de votes négatifs pour la merge request. |
| `draft`                                                     | boolean  | Si `true`, la merge request est marquée dans un état `draft`. |
| `first_contribution`                                        | boolean  | Si `true`, il s'agit de la première contribution de l'auteur à ce projet. |
| `first_deployed_to_production_at`                           | datetime | Horodatage de la fin du premier déploiement. |
| `force_remove_source_branch`                                | boolean  | Si `true`, les paramètres du projet imposent la suppression de la branche source après la fusion. |
| `has_conflicts`                                             | boolean  | Si `true`, la merge request présente des conflits et ne peut pas être fusionnée. Dépend de la propriété `merge_status`. Retourne `false` sauf si `merge_status` est `cannot_be_merged`. |
| `head_pipeline[]`                                           | objet   | Pipeline qui s'exécute sur le commit HEAD de la branche source du merge request. À utiliser à la place de `pipeline`, car il contient des informations plus complètes. Exposé uniquement si l'utilisateur actuel peut voir les pipelines de ce projet. |
| `head_pipeline.before_sha`                                  | string   | SHA du commit précédant ce pipeline. |
| `head_pipeline.committed_at`                                | dateTime | Horodatage du commit. |
| `head_pipeline.coverage`                                    | number   | Pourcentage de couverture des tests, comme `98.29`. |
| `head_pipeline.created_at`                                  | dateTime | Horodatage de la création du pipeline. |
| `head_pipeline.detailed_status[]`                           | objet   | Objet contenant des champs avec le statut détaillé de ce pipeline. |
| `head_pipeline.detailed_status.action[]`                    | objet   | Si défini, objet contenant les actions disponibles pour ce pipeline. |
| `head_pipeline.detailed_status.action.button_title`         | string   | Titre du bouton pour l'action. |
| `head_pipeline.detailed_status.action.confirmation_message` | string   | Message de confirmation pour l'action. |
| `head_pipeline.detailed_status.action.icon`                 | string   | Icône pour l'action. |
| `head_pipeline.detailed_status.action.method`               | string   | Méthode HTTP pour l'action, comme `POST`. |
| `head_pipeline.detailed_status.action.path`                 | string   | Chemin pour l'action, comme `"/namespace1/project1/-/jobs/2/cancel"`. |
| `head_pipeline.detailed_status.action.title`                | string   | Titre pour l'action. |
| `head_pipeline.detailed_status.details_path`                | string   | Chemin vers la vue détaillée, comme `"/test-group/test-project/-/pipelines/287"`. |
| `head_pipeline.detailed_status.favicon`                     | string   | Chemin vers le favicon de statut. |
| `head_pipeline.detailed_status.group`                       | string   | Groupe de statut, comme `success`. |
| `head_pipeline.detailed_status.has_details`                 | boolean  | Si défini, une vue détaillée est disponible. |
| `head_pipeline.detailed_status.icon`                        | string   | Nom de l'icône de statut, comme `"status_success"`. |
| `head_pipeline.detailed_status.illustration.content`        | string   | Texte du contenu pour l'illustration, comme `"This job depends on upstream jobs that need to succeed in order for this job to be triggered"`. |
| `head_pipeline.detailed_status.illustration.image`          | string   | Chemin vers l'image d'illustration. |
| `head_pipeline.detailed_status.illustration.size`           | string   | Taille de l'illustration. |
| `head_pipeline.detailed_status.illustration.title`          | string   | Titre pour l'illustration, comme `"This job has not been triggered yet"`. |
| `head_pipeline.detailed_status.label`                       | string   | Label de statut pour le pipeline, comme `"passed"`. |
| `head_pipeline.detailed_status.text`                        | string   | Texte de statut pour le pipeline, comme `"passed"`. |
| `head_pipeline.detailed_status.tooltip`                     | string   | Texte d'info-bulle pour le pipeline, comme `"passed"`. |
| `head_pipeline.duration`                                    | entier  | Temps passé à exécuter le pipeline, en secondes. |
| `head_pipeline.finished_at`                                 | dateTime | Horodatage de la fin du pipeline. |
| `head_pipeline.id`                                          | entier  | Identifiant numérique unique du pipeline. Clé étrangère vers la table `ci_pipelines`. |
| `head_pipeline.iid`                                         | entier  | ID numérique interne du pipeline. |
| `head_pipeline.project_id`                                  | entier  | ID numérique du projet contenant le pipeline. |
| `head_pipeline.queued_duration`                             | entier  | Temps passé en file d'attente, en secondes. |
| `head_pipeline.ref`                                         | string   | Nom de la référence Git (branche ou tag) sur laquelle le pipeline s'exécute. |
| `head_pipeline.sha`                                         | string   | SHA du commit qui a déclenché le pipeline. |
| `head_pipeline.source`                                      | string   | Façon dont le pipeline a été déclenché. Par exemple `push`, `merge_request_event` ou `api` |
| `head_pipeline.started_at`                                  | dateTime | Horodatage du démarrage du pipeline. |
| `head_pipeline.status`                                      | string   | Statut actuel du pipeline. Valeurs possibles : `success`, `failed`, `running`, `pending` |
| `head_pipeline.tag`                                         | boolean  | Si `true`, ce pipeline s'exécute sur un tag Git. |
| `head_pipeline.updated_at`                                  | dateTime | Horodatage de la dernière mise à jour du pipeline. |
| `head_pipeline.user[]`                                      | objet   | Objet contenant des informations sur l'utilisateur qui a déclenché le pipeline. |
| `head_pipeline.user.avatar_url`                             | string   | URL complète vers l'image d'avatar de l'utilisateur. |
| `head_pipeline.user.id`                                     | entier  | L'identifiant unique de l'utilisateur qui a déclenché le pipeline. |
| `head_pipeline.user.locked`                                 | boolean  | Si `true`, le compte de l'utilisateur qui a déclenché le pipeline est verrouillé en raison d'échecs de tentatives d'authentification, et il ne peut pas se connecter jusqu'à ce que le verrou expire ou qu'un administrateur déverrouille le compte. |
| `head_pipeline.user.name`                                   | string   | Nom d'affichage de l'utilisateur qui a déclenché le pipeline. Peut être masqué, en fonction des permissions de l'utilisateur actuel. |
| `head_pipeline.user.public_email`                           | string   | L'adresse e-mail publique de l'utilisateur qui a déclenché le pipeline. |
| `head_pipeline.user.state`                                  | string   | État actuel du compte de l'utilisateur qui a déclenché le pipeline. Valeurs possibles : `active`, `blocked`, ou `deactivated`. |
| `head_pipeline.user.username`                               | string   | Nom d'utilisateur de l'utilisateur qui a déclenché le pipeline. |
| `head_pipeline.user.web_url`                                | string   | URL complète vers la page de profil de l'utilisateur qui a déclenché le pipeline. |
| `head_pipeline.web_url`                                     | string   | URL complète vers la page du pipeline. |
| `head_pipeline.yaml_errors`                                 | string   | Toute erreur de configuration YAML. Par exemple, `widgets:build: needs 'widgets:test'`) |
| `id`                                                        | entier  | Identifiant de la merge request. |
| `iid`                                                       | entier  | Identifiant interne de la merge request. |
| `imported`                                                  | boolean  | Si `true`, la merge request a été importée. |
| `imported_from`                                             | string   | Source de l'import, comme `Bitbucket`. |
| `labels[]`                                                  | tableau    | Tableau des labels assignés à la merge request. Si `with_labels_details` est `true`, retourne un tableau pour chaque label. |
| `labels.archived`                                           | boolean  | Si `with_labels_details` est `true`, le label est archivé. |
| `labels.color`                                              | string   | Si `with_labels_details` est `true`, la couleur d'arrière-plan du label. |
| `labels.description`                                        | string   | Si `with_labels_details` est `true`, le texte de description du label. Si `null`, le label n'a pas de description. |
| `labels.description_html`                                   | string   | Si `with_labels_details` est `true`, la description rendue en HTML du label. Si `null`, le label n'a pas de description. |
| `labels.id`                                                 | entier  | Si `with_labels_details` est `true`, l'identifiant unique du label. |
| `labels.name`                                               | string   | Si `with_labels_details` est `true`, le nom du label. |
| `labels.text_color`                                         | string   | Si `with_labels_details` est `true`, la couleur du texte du label. |
| `latest_build_finished_at`                                  | datetime | Horodatage de la fin du dernier build pour le merge request. |
| `latest_build_started_at`                                   | datetime | Horodatage du début du dernier build pour le merge request. |
| `merge_after`                                               | dateTime | Si défini, horodatage à partir duquel la merge request peut être fusionnée. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/510992) dans GitLab 17.8. |
| `merge_commit_sha`                                          | string   | Si défini, le SHA du commit de fusion de la merge request. Retourne `null` jusqu'à la fusion. |
| `merge_error`                                               | string   | Si défini, le message d'erreur affiché lorsqu'une fusion échoue. Pour vérifier la fusionnabilité, utilisez plutôt `detailed_merge_status`. |
| `merge_status`                                              | string   | Statut de la merge request. Utilisez plutôt `detailed_merge_status`, qui tient compte de tous les statuts potentiels. Affecte la propriété `has_conflicts`. Pour les notes importantes sur les données de réponse, voir [notes sur la réponse d'une merge request unique](#single-merge-request-response-notes). [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/3169#note_1162532204) dans GitLab 15.6.  |
| `merge_user[]`                                              | objet   | L'utilisateur qui a fusionné ce merge request, l'utilisateur qui l'a défini sur la fusion automatique, ou `null`. |
| `merge_when_pipeline_succeeds`                              | boolean  | Si `true`, la merge request est définie en fusion automatique. |
| `merged_at`                                                 | dateTime | Horodatage de la fusion de la merge request. |
| `merged_by[]`                                               | objet   | Utilisateur qui a fusionné cette merge request ou l'a définie en fusion automatique. [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/350534) dans GitLab 14.7, et prévu pour suppression dans la [version 5 de l'API](https://gitlab.com/groups/gitlab-org/-/epics/8115). Utilisez `merge_user` à la place.  |
| `milestone[]`                                               | objet   | Objet contenant des informations sur le jalon assigné à la merge request. |
| `milestone.created_at`                                      | dateTime | Horodatage de la création du jalon. |
| `milestone.description`                                     | string   | Texte de description du jalon. Si `null`, le jalon n'a pas de description. |
| `milestone.due_date`                                        | date     | Date d'échéance du jalon. Si `null`, le jalon n'a pas de date d'échéance. |
| `milestone.expired`                                         | boolean  | Si `true`, le jalon a expiré. |
| `milestone.group_id`                                        | entier  | Identifiant du groupe auquel appartient le jalon. Inclus uniquement si le jalon est un jalon de groupe. |
| `milestone.id`                                              | entier  | Identifiant unique du jalon. |
| `milestone.iid`                                             | entier  | Identifiant interne du jalon dans le projet ou le groupe. |
| `milestone.project_id`                                      | entier  | Identifiant du projet auquel appartient le jalon. Inclus uniquement si le jalon est un jalon de projet. |
| `milestone.start_date`                                      | date     | Date de début du jalon. Si `null`, le jalon n'a pas de date de début |
| `milestone.state`                                           | string   | État actuel du jalon, comme `active` ou `closed`. |
| `milestone.title`                                           | string   | Nom du jalon. |
| `milestone.updated_at`                                      | dateTime | Horodatage de la dernière mise à jour du jalon. |
| `milestone.web_url`                                         | string   | URL web complète pour afficher le jalon. |
| `pipeline[]`                                                | objet   | Pipeline s'exécutant sur le HEAD de la branche du merge request. Envisagez d'utiliser plutôt `head_pipeline`, car il contient plus d'informations. |
| `prepared_at`                                               | dateTime | Horodatage de la préparation de la merge request. Ce champ est renseigné une seule fois, uniquement après la complétion de toutes les [étapes de préparation](#preparation-steps), et n'est pas mis à jour si d'autres modifications sont ajoutées. |
| `project_id`                                                | entier  | L'identifiant du projet contenant la merge request. |
| `rebase_in_progress`                                        | boolean  | Si `true`, Sidekiq exécute une opération de rebase sur cette branche. |
| `reference`                                                 | string   | Obsolète. Utilisez `references` à la place. [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20354) dans GitLab 12.7, et prévu pour suppression dans la [version 5 de l'API](https://gitlab.com/groups/gitlab-org/-/epics/8115). Utilisez `references` à la place.  |
| `references[]`                                              | objet   | Objet avec toutes les références internes de la merge request. |
| `references.full`                                           | string   | Référence complète d'une merge request, incluant le chemin complet du projet, comme `gitlab-org/gitlab!123`. Lorsqu'elle est demandée entre groupes ou projets, identique à `references.relative`. |
| `references.relative`                                       | string   | Référence relative à un projet ou groupe spécifique : `!123` pour une merge request dans le projet actuel, ou `other-project!123` pour un autre projet dans le même groupe. |
| `references.short`                                          | string   | Référence la plus courte possible vers une merge request, comme `!123`. Lorsqu'elle est récupérée depuis le projet de la merge request, identique à `references.relative`. |
| `reviewers[]`                                               | tableau    | Relecteurs de la merge request. |
| `reviewers.avatar_url`                                      | string   | URL complète de l'image d'avatar du relecteur. |
| `reviewers.id`                                              | entier  | L'identifiant unique du relecteur. |
| `reviewers.locked`                                          | boolean  | Si `true`, le compte du relecteur est verrouillé en raison de tentatives d'authentification échouées, et il ne peut pas se connecter tant que le verrouillage n'expire pas ou qu'un administrateur ne déverrouille pas le compte. |
| `reviewers.name`                                            | string   | Nom d'affichage du relecteur. Peut être masqué, en fonction des permissions de l'utilisateur actuel. |
| `reviewers.public_email`                                    | string   | L'adresse e-mail publique du relecteur. |
| `reviewers.state`                                           | string   | État actuel du compte utilisateur du relecteur. Valeurs possibles : `active`, `blocked`, ou `deactivated`. |
| `reviewers.username`                                        | string   | Nom d'utilisateur du relecteur de la merge request. |
| `reviewers.web_url`                                         | string   | URL complète vers la page de profil du relecteur. |
| `sha`                                                       | string   | SHA du commit head dans la branche source. |
| `should_remove_source_branch`                               | boolean  | Si `true`, la branche source est supprimée après la fusion. |
| `source_branch`                                             | string   | Nom de la branche source. |
| `source_project_id`                                         | entier  | Identifiant du projet source. |
| `squash`                                                    | boolean  | Si `true`, les commits sont squashés lors de la fusion. |
| `squash_commit_sha`                                         | string   | Si défini, le SHA du commit squash. Vide jusqu'à la fusion. |
| `squash_on_merge`                                           | boolean  | Si `true`, les commits sont squashés lors de la fusion. |
| `state`                                                     | string   | L'état actuel de la merge request. Valeurs possibles : `opened`, `closed`, `merged`, ou `locked`. |
| `subscribed`                                                | boolean  | Si `true`, l'utilisateur authentifié actuel est abonné à ce merge request. |
| `target_branch`                                             | string   | Nom de la branche cible. |
| `target_project_id`                                         | entier  | Identifiant du projet cible. |
| `task_completion_status[]`                                  | objet   | Objet contenant des informations sur l'état d'avancement de la liste de tâches. |
| `task_completion_status.completed_count`                    | entier  | Nombre d'éléments de liste de tâches complétés dans la description de la merge request. Retourne `0` si la merge request n'a pas de description ou pas d'éléments de liste de tâches. |
| `task_completion_status.count`                              | entier  | Nombre total d'éléments de liste de tâches trouvés dans la description de la merge request. Retourne `0` si la merge request n'a pas de description ou pas d'éléments de liste de tâches. |
| `time_stats[]`                                              | objet   | Objet contenant des informations sur le suivi du temps pour cette merge request. |
| `time_stats.human_time_estimate`                            | string   | Format lisible par l'humain de `time_stats.time_estimate`, comme `3h 30m`. |
| `time_stats.human_total_time_spent`                         | string   | Format lisible par l'humain de `time_stats.total_time_spent`, comme `3h 30m`. |
| `time_stats.time_estimate`                                  | entier  | Temps estimé pour compléter la merge request, en secondes. |
| `time_stats.total_time_spent`                               | entier  | Temps total passé à travailler sur la merge request, en secondes. |
| `title`                                                     | string   | Le titre de la merge request. |
| `updated_at`                                                | datetime | Horodatage de la dernière mise à jour de la merge request. |
| `upvotes`                                                   | entier  | Nombre de votes positifs pour la merge request. |
| `user[]`                                                    | objet   | Permissions de l'utilisateur demandées pour le merge request. |
| `user.can_merge`                                            | boolean  | Si `true`, l'utilisateur authentifié actuel peut fusionner ce merge request. |
| `user_notes_count`                                          | entier  | Nombre de commentaires utilisateur. |
| `web_url`                                                   | string   | URL web pour afficher la merge request. |
| `work_in_progress`                                          | boolean  | Obsolète. Utilisez `draft` à la place. |

Exemple de réponse :

```json
{
  "id": 155016530,
  "iid": 133,
  "project_id": 15513260,
  "title": "Manual job rules",
  "description": "",
  "state": "opened",
  "imported": false,
  "imported_from": "none",
  "created_at": "2022-05-13T07:26:38.402Z",
  "updated_at": "2022-05-14T03:38:31.354Z",
  "merged_by": null, // Deprecated and will be removed in API v5. Use `merge_user` instead.
  "merge_user": null,
  "merged_at": null,
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "target_branch": "main",
  "source_branch": "manual-job-rules",
  "user_notes_count": 0,
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 4155490,
    "username": "marcel.amirault",
    "name": "Marcel Amirault",
    "state": "active",
    "avatar_url": "https://gitlab.com/uploads/-/system/user/avatar/4155490/avatar.png",
    "web_url": "https://gitlab.com/marcel.amirault"
  },
  "assignees": [],
  "assignee": null,
  "reviewers": [],
  "source_project_id": 15513260,
  "target_project_id": 15513260,
  "labels": [],
  "draft": false,
  "work_in_progress": false,
  "milestone": null,
  "merge_when_pipeline_succeeds": false,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "mergeable",
  "sha": "e82eb4a098e32c796079ca3915e07487fc4db24c",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "discussion_locked": null,
  "should_remove_source_branch": null,
  "force_remove_source_branch": true,
  "reference": "!133", // Deprecated. Use `references` instead.
  "references": {
    "short": "!133",
    "relative": "!133",
    "full": "marcel.amirault/test-project!133"
  },
  "web_url": "https://gitlab.com/marcel.amirault/test-project/-/merge_requests/133",
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "task_completion_status": {
    "count": 0,
    "completed_count": 0
  },
  "has_conflicts": false,
  "blocking_discussions_resolved": true,
  "approvals_before_merge": null, // deprecated, use [Merge request approvals API](merge_request_approvals.md)
  "subscribed": true,
  "changes_count": "1",
  "latest_build_started_at": "2022-05-13T09:46:50.032Z",
  "latest_build_finished_at": null,
  "first_deployed_to_production_at": null,
  "pipeline": { // Use `head_pipeline` instead.
    "id": 538317940,
    "iid": 1877,
    "project_id": 15513260,
    "sha": "1604b0c46c395822e4e9478777f8e54ac99fe5b9",
    "ref": "refs/merge-requests/133/merge",
    "status": "failed",
    "source": "merge_request_event",
    "created_at": "2022-05-13T09:46:39.560Z",
    "updated_at": "2022-05-13T09:47:20.706Z",
    "web_url": "https://gitlab.com/marcel.amirault/test-project/-/pipelines/538317940"
  },
  "head_pipeline": {
    "id": 538317940,
    "iid": 1877,
    "project_id": 15513260,
    "sha": "1604b0c46c395822e4e9478777f8e54ac99fe5b9",
    "ref": "refs/merge-requests/133/merge",
    "status": "failed",
    "source": "merge_request_event",
    "created_at": "2022-05-13T09:46:39.560Z",
    "updated_at": "2022-05-13T09:47:20.706Z",
    "web_url": "https://gitlab.com/marcel.amirault/test-project/-/pipelines/538317940",
    "before_sha": "1604b0c46c395822e4e9478777f8e54ac99fe5b9",
    "tag": false,
    "yaml_errors": null,
    "user": {
      "id": 4155490,
      "username": "marcel.amirault",
      "name": "Marcel Amirault",
      "state": "active",
      "avatar_url": "https://gitlab.com/uploads/-/system/user/avatar/4155490/avatar.png",
      "web_url": "https://gitlab.com/marcel.amirault"
    },
    "started_at": "2022-05-13T09:46:50.032Z",
    "finished_at": "2022-05-13T09:47:20.697Z",
    "committed_at": null,
    "duration": 30,
    "queued_duration": 10,
    "coverage": null,
    "detailed_status": {
      "icon": "status_failed",
      "text": "failed",
      "label": "failed",
      "group": "failed",
      "tooltip": "failed",
      "has_details": true,
      "details_path": "/marcel.amirault/test-project/-/pipelines/538317940",
      "illustration": null,
      "favicon": "/assets/ci_favicons/favicon_status_failed-41304d7f7e3828808b0c26771f0309e55296819a9beea3ea9fbf6689d9857c12.png"
    },
    "archived": false
  },
  "diff_refs": {
    "base_sha": "1162f719d711319a2efb2a35566f3bfdadee8bab",
    "head_sha": "e82eb4a098e32c796079ca3915e07487fc4db24c",
    "start_sha": "1162f719d711319a2efb2a35566f3bfdadee8bab"
  },
  "merge_error": null,
  "first_contribution": false,
  "user": {
    "can_merge": true
  },
  "approvals_before_merge": { // Available for GitLab Premium and Ultimate tiers only
    "id": 1,
    "title": "test1",
    "approvals_before_merge": null
  },
}
```

### Notes de réponse pour un merge request unique {#single-merge-request-response-notes}

La fusionnabilité (`merge_status`) de chaque merge request est vérifiée de manière asynchrone lorsqu'une requête est faite vers ce point de terminaison. Interrogez ce point de terminaison d'API pour obtenir le statut mis à jour. Cela affecte la propriété `has_conflicts`, car elle dépend de `merge_status`. Elle renvoie `false` sauf si `merge_status` est `cannot_be_merged`.

### Statut de fusion {#merge-status}

Utilisez `detailed_merge_status` au lieu de `merge_status` pour tenir compte de tous les statuts potentiels.

- Le champ `detailed_merge_status` peut contenir l'une des valeurs suivantes relatives au merge request :
  - `approvals_syncing` : Les approbations du merge request sont en cours de synchronisation.
  - `checking` : Git teste si une fusion valide est possible.
  - `ci_must_pass` : Un pipeline CI/CD doit réussir avant la fusion.
  - `ci_still_running` : Un pipeline CI/CD est toujours en cours d'exécution.
  - `commits_status` : La branche source doit exister et contenir des commits.
  - `conflict` : Des conflits existent entre la branche source et la branche cible.
  - `discussions_not_resolved` : Toutes les discussions doivent être résolues avant la fusion.
  - `draft_status` : Impossible de fusionner car le merge request est un brouillon.
  - `jira_association_missing` : Le titre ou la description doit faire référence à un ticket Jira. Pour configurer, consultez [exiger un ticket Jira associé pour que les merge requests soient fusionnés](../integration/jira/issues.md#require-associated-jira-issue-for-merge-requests-to-be-merged).
  - `mergeable` : La branche peut fusionner proprement dans la branche cible.
  - `merge_request_blocked` : Bloqué par un autre merge request.
  - `merge_time` : Ne peut pas être fusionné avant l'heure spécifiée.
  - `need_rebase` : Le merge request doit être rebasé.
  - `not_approved` : Une approbation est requise avant la fusion.
  - `not_open` : Le merge request doit être ouvert avant la fusion.
  - `preparing` : Le diff du merge request est en cours de création.
  - `requested_changes` : Le merge request a des relecteurs qui ont demandé des modifications.
  - `security_policy_pipeline_check` : Tous les pipelines pour le dernier commit doivent réussir avant que le merge request soit fusionné lorsque des politiques de sécurité sont appliquées.
  - `security_policy_violations` : Toutes les politiques de sécurité doivent être satisfaites.
  - `status_checks_must_pass` : Toutes les vérifications de statut doivent réussir avant la fusion.
  - `unchecked` : Git n'a pas encore testé si une fusion valide est possible.
  - `locked_paths` : Les chemins verrouillés par d'autres utilisateurs doivent être déverrouillés avant de fusionner dans la branche par défaut.
  - `locked_lfs_files` : Les fichiers LFS verrouillés par d'autres utilisateurs doivent être déverrouillés avant la fusion.
  - `title_regex` : Vérifie si le titre correspond à l'expression régulière attendue, si elle est configurée dans les paramètres du projet.

### Étapes de préparation {#preparation-steps}

Le champ `prepared_at` est renseigné une seule fois, uniquement après la fin de ces étapes :

- Créer le diff.
- Créer les pipelines.
- Vérifier la fusionnabilité.
- Lier tous les objets Git LFS.
- Envoyer les notifications.

Le champ `prepared_at` n'est pas mis à jour si d'autres modifications sont ajoutées au merge request.

## Récupérer les participants d'un merge request {#retrieve-merge-request-participants}

Récupérer les participants d'un merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/participants
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'ID interne du merge request. |

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://localhost/user1"
  },
  {
    "id": 2,
    "name": "John Doe2",
    "username": "user2",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/10fc7f102be8de7657fb4d80898bbfe3?s=80&d=identicon",
    "web_url": "http://localhost/user2"
  }
]
```

## Récupérer les relecteurs d'un merge request {#retrieve-merge-request-reviewers}

Récupérer les relecteurs d'un merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/reviewers
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'ID interne du merge request. |

Exemple de réponse :

```json
[
  {
    "user": {
      "id": 1,
      "name": "John Doe1",
      "username": "user1",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
      "web_url": "http://localhost/user1"
    },
    "state": "unreviewed",
    "created_at": "2022-07-27T17:03:27.684Z"
  },
  {
    "user": {
      "id": 2,
      "name": "John Doe2",
      "username": "user2",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/10fc7f102be8de7657fb4d80898bbfe3?s=80&d=identicon",
      "web_url": "http://localhost/user2"
    },
    "state": "reviewed",
    "created_at": "2022-07-27T17:03:27.684Z"
  }
]
```

## Récupérer les commits d'un merge request {#retrieve-merge-request-commits}

Récupérer les commits d'un merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/commits
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | Identifiant interne de la merge request. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                     | Type         | Description |
|-------------------------------|--------------|-------------|
| `commits`                     | tableau d'objets | Commits dans le merge request. |
| `commits[].id`                | string       | Identifiant du commit. |
| `commits[].short_id`          | string       | Identifiant court du commit. |
| `commits[].created_at`        | datetime     | Identique au champ `committed_date`. |
| `commits[].parent_ids`        | tableau        | Identifiants des commits parents. |
| `commits[].title`             | string       | Titre du commit. |
| `commits[].message`           | string       | Message de commit. |
| `commits[].author_name`       | string       | Nom de l'auteur du commit. |
| `commits[].author_email`      | string       | Adresse e-mail de l'auteur du commit. |
| `commits[].authored_date`     | datetime     | Date et heure de création du commit. |
| `commits[].committer_name`    | string       | Nom du contributeur. |
| `commits[].committer_email`   | string       | Adresse e-mail du contributeur. |
| `commits[].committed_date`    | datetime     | Date et heure du commit. |
| `commits[].trailers`          | objet       | Trailers Git analysés pour le commit. Les clés en double n'incluent que la dernière valeur. |
| `commits[].extended_trailers` | objet       | Trailers Git analysés pour le commit. |
| `commits[].web_url`           | string       | URL web du merge request. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/commits"
```

Exemple de réponse :

```json
[
  {
    "id": "ed899a2f4b50b4370feeea94676502b42383c746",
    "short_id": "ed899a2f4b5",
    "title": "Replace sanitize with escape once",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "authored_date": "2012-09-20T11:50:22+03:00",
    "committer_name": "Example User",
    "committer_email": "user@example.com",
    "committed_date": "2012-09-20T11:50:22+03:00",
    "created_at": "2012-09-20T11:50:22+03:00",
    "message": "Replace sanitize with escape once",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/project/-/commit/ed899a2f4b50b4370feeea94676502b42383c746"
  },
  {
    "id": "6104942438c14ec7bd21c6cd5bd995272b3faff6",
    "short_id": "6104942438c",
    "title": "Sanitize for network graph",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "authored_date": "2012-09-20T09:06:12+03:00",
    "committer_name": "Example User",
    "committer_email": "user@example.com",
    "committed_date": "2012-09-20T09:06:12+03:00",
    "created_at": "2012-09-20T09:06:12+03:00",
    "message": "Sanitize for network graph",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/project/-/commit/6104942438c14ec7bd21c6cd5bd995272b3faff6"
  }
]
```

## Récupérer les dépendances d'un merge request {#retrieve-merge-request-dependencies}

Récupérer les dépendances qui doivent être résolues avant qu'un merge request puisse être fusionné.

> [!note]
> Si l'utilisateur n'a pas accès au merge request bloquant, aucun attribut `blocking_merge_request` n'est renvoyé.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/blocks
```

Attributs pris en charge :

| Attribut           | Type           | Obligatoire | Description |
|---------------------|----------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/blocks"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "blocking_merge_request": {
      "id": 145,
      "iid": 12,
      "project_id": 7,
      "title": "Interesting MR",
      "description": "Does interesting things.",
      "state": "opened",
      "created_at": "2024-07-05T21:29:11.172Z",
      "updated_at": "2024-07-05T21:29:11.172Z",
      "merged_by": null,
      "merge_user": null,
      "merged_at": null,
      "merge_after": "2018-09-07T11:16:00.000Z",
      "closed_by": null,
      "closed_at": null,
      "target_branch": "master",
      "source_branch": "v2.x",
      "user_notes_count": 0,
      "upvotes": 0,
      "downvotes": 0,
      "author": {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      },
      "assignees": [
        {
          "id": 2,
          "username": "aiguy123",
          "name": "AI GUY",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhost/aiguy123"
        }
      ],
      "assignee": {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      },
      "reviewers": [
        {
          "id": 2,
          "username": "aiguy123",
          "name": "AI GUY",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhost/aiguy123"
        },
        {
          "id": 1,
          "username": "root",
          "name": "Administrator",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhost/root"
        }
      ],
      "source_project_id": 7,
      "target_project_id": 7,
      "labels": [],
      "draft": false,
      "imported": false,
      "imported_from": "none",
      "work_in_progress": false,
      "milestone": null,
      "merge_when_pipeline_succeeds": false,
      "merge_status": "unchecked",
      "detailed_merge_status": "unchecked",
      "sha": "ce7e4f2d0ce13cb07479bb39dc10ee3b861c08a6",
      "merge_commit_sha": null,
      "squash_commit_sha": null,
      "discussion_locked": null,
      "should_remove_source_branch": null,
      "force_remove_source_branch": true,
      "prepared_at": null,
      "reference": "!12",
      "references": {
        "short": "!12",
        "relative": "!12",
        "full": "my-group/my-project!12"
      },
      "web_url": "https://localhost/my-group/my-project/-/merge_requests/12",
      "time_stats": {
        "time_estimate": 0,
        "total_time_spent": 0,
        "human_time_estimate": null,
        "human_total_time_spent": null
      },
      "squash": false,
      "squash_on_merge": false,
      "task_completion_status": {
        "count": 0,
        "completed_count": 0
      },
      "has_conflicts": false,
      "blocking_discussions_resolved": true,
      "approvals_before_merge": null
    },
    "blocked_merge_request": {
      "id": 146,
      "iid": 13,
      "project_id": 7,
      "title": "Really cool MR",
      "description": "Adds some stuff",
      "state": "opened",
      "created_at": "2024-07-05T21:31:34.811Z",
      "updated_at": "2024-07-27T02:57:08.054Z",
      "merged_by": null,
      "merge_user": null,
      "merged_at": null,
      "merge_after": "2018-09-07T11:16:00.000Z",
      "closed_by": null,
      "closed_at": null,
      "target_branch": "master",
      "source_branch": "remove-from",
      "user_notes_count": 0,
      "upvotes": 1,
      "downvotes": 0,
      "author": {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      },
      "assignees": [
        {
          "id": 2,
          "username": "aiguy123",
          "name": "AI GUY",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhose/aiguy123"
        }
      ],
      "assignee": {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      },
      "reviewers": [
        {
          "id": 1,
          "username": "root",
          "name": "Administrator",
          "state": "active",
          "locked": false,
          "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
          "web_url": "https://localhost/root"
        }
      ],
      "source_project_id": 7,
      "target_project_id": 7,
      "labels": [],
      "draft": false,
      "imported": false,
      "imported_from": "none",
      "work_in_progress": false,
      "milestone": {
        "id": 59,
        "iid": 6,
        "project_id": 7,
        "title": "Sprint 1718897375",
        "description": "Accusantium omnis iusto a animi.",
        "state": "active",
        "created_at": "2024-06-20T15:29:35.739Z",
        "updated_at": "2024-06-20T15:29:35.739Z",
        "due_date": null,
        "start_date": null,
        "expired": false,
        "web_url": "https://localhost/my-group/my-project/-/milestones/6"
      },
      "merge_when_pipeline_succeeds": false,
      "merge_status": "cannot_be_merged",
      "detailed_merge_status": "not_approved",
      "sha": "daa75b9b17918f51f43866ff533987fda71375ea",
      "merge_commit_sha": null,
      "squash_commit_sha": null,
      "discussion_locked": null,
      "should_remove_source_branch": null,
      "force_remove_source_branch": true,
      "prepared_at": "2024-07-11T18:50:46.215Z",
      "reference": "!13",
      "references": {
        "short": "!13",
        "relative": "!13",
        "full": "my-group/my-project!12"
      },
      "web_url": "https://localhost/my-group/my-project/-/merge_requests/13",
      "time_stats": {
        "time_estimate": 0,
        "total_time_spent": 0,
        "human_time_estimate": null,
        "human_total_time_spent": null
      },
      "squash": false,
      "squash_on_merge": false,
      "task_completion_status": {
        "count": 0,
        "completed_count": 0
      },
      "has_conflicts": true,
      "blocking_discussions_resolved": true,
      "approvals_before_merge": null
    },
    "project_id": 7
  }
]
```

## Supprimer une dépendance de merge request {#delete-a-merge-request-dependency}

Supprimer une dépendance de merge request.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/blocks/:block_id
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'identifiant ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) appartenant à l'utilisateur authentifié. |
| `merge_request_iid` | entier           | Oui      | L'ID interne du merge request. |
| `block_id`          | entier           | Oui      | L'identifiant du bloc. |

Exemple de requête :

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/blocks/1"
```

Renvoie :

- `204 No Content` si la dépendance est supprimée avec succès.
- `403 Forbidden` si l'utilisateur n'a pas les permissions pour mettre à jour le merge request.
- `403 Forbidden` si l'utilisateur n'a pas les permissions pour lire le merge request bloquant.

## Créer une dépendance de merge request {#create-a-merge-request-dependency}

Créer une dépendance de merge request.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/blocks
```

Attributs pris en charge :

| Attribut                    | Type              | Obligatoire    | Description |
|------------------------------|-------------------|-------------|-------------|
| `id`                         | entier ou chaîne | Oui         | L'identifiant ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) appartenant à l'utilisateur authentifié. |
| `merge_request_iid`          | entier           | Oui         | L'identifiant interne du merge request à bloquer. |
| `blocking_merge_request_id`  | entier           | Conditionnel | L'identifiant global du merge request bloquant. Requis si `blocking_merge_request_iid` n'est pas fourni. |
| `blocking_merge_request_iid` | entier           | Conditionnel | L'IID du merge request bloquant. Requis si `blocking_merge_request_id` n'est pas fourni. |
| `blocking_project_id`        | entier ou chaîne | Non          | L'identifiant ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) qui contient le merge request bloquant. Requis lorsque `blocking_merge_request_iid` fait référence à un merge request dans un autre projet. Par défaut, le projet actuel. |

Exemple de requête utilisant IID (même projet) :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/blocks?blocking_merge_request_iid=2"
```

Exemple de requête utilisant IID (entre projets) :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/blocks?blocking_merge_request_iid=5&blocking_project_id=2"
```

Exemple de requête utilisant un identifiant global (méthode héritée) :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/blocks?blocking_merge_request_id=12345"
```

Renvoie :

- `201 Created` si la dépendance est créée avec succès.
- `400 Bad request` si l'enregistrement du merge request bloquant échoue.
- `403 Forbidden` si l'utilisateur n'a pas les permissions pour lire le merge request bloquant.
- `404 Not found` si le merge request bloquant est introuvable.
- `409 Conflict` si le bloc existe déjà.

Exemple de réponse :

```json
{
  "id": 1,
  "blocking_merge_request": {
    "id": 145,
    "iid": 12,
    "project_id": 7,
    "title": "Interesting MR",
    "description": "Does interesting things.",
    "state": "opened",
    "created_at": "2024-07-05T21:29:11.172Z",
    "updated_at": "2024-07-05T21:29:11.172Z",
    "merged_by": null,
    "merge_user": null,
    "merged_at": null,
    "merge_after": "2018-09-07T11:16:00.000Z",
    "closed_by": null,
    "closed_at": null,
    "target_branch": "master",
    "source_branch": "v2.x",
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 2,
      "username": "aiguy123",
      "name": "AI GUY",
      "state": "active",
      "locked": false,
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "https://localhost/aiguy123"
    },
    "assignees": [
      {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      }
    ],
    "assignee": {
      "id": 2,
      "username": "aiguy123",
      "name": "AI GUY",
      "state": "active",
      "locked": false,
      "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
      "web_url": "https://localhost/aiguy123"
    },
    "reviewers": [
      {
        "id": 2,
        "username": "aiguy123",
        "name": "AI GUY",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/aiguy123"
      },
      {
        "id": 1,
        "username": "root",
        "name": "Administrator",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/0?s=80&d=identicon",
        "web_url": "https://localhost/root"
      }
    ],
    "source_project_id": 7,
    "target_project_id": 7,
    "labels": [],
    "draft": false,
    "imported": false,
    "imported_from": "none",
    "work_in_progress": false,
    "milestone": null,
    "merge_when_pipeline_succeeds": false,
    "merge_status": "unchecked",
    "detailed_merge_status": "unchecked",
    "sha": "ce7e4f2d0ce13cb07479bb39dc10ee3b861c08a6",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "discussion_locked": null,
    "should_remove_source_branch": null,
    "force_remove_source_branch": true,
    "prepared_at": null,
    "reference": "!12",
    "references": {
      "short": "!12",
      "relative": "!12",
      "full": "my-group/my-project!12"
    },
    "web_url": "https://localhost/my-group/my-project/-/merge_requests/12",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "squash": false,
    "squash_on_merge": false,
    "task_completion_status": {
      "count": 0,
      "completed_count": 0
    },
    "has_conflicts": false,
    "blocking_discussions_resolved": true,
    "approvals_before_merge": null
  },
  "project_id": 7
}
```

## Récupérer les merge requests bloqués {#retrieve-blocked-merge-requests}

Récupérer les merge requests bloqués par un merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/blockees
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/blockees"
```

Exemple de réponse :

```json
[
  {
    "id": 18,
    "blocking_merge_request": {
      "id": 71,
      "iid": 10,
      "project_id": 7,
      "title": "At quaerat occaecati voluptate ex explicabo nisi.",
      "description": "Aliquid distinctio officia corrupti ad nemo natus ipsum culpa.",
      "state": "merged",
      "created_at": "2024-07-05T19:44:14.023Z",
      "updated_at": "2024-07-05T19:44:14.023Z",
      "merged_by": {
        "id": 40,
        "username": "i-user-0-1720208283",
        "name": "I User0",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/8325417f0f7919e3724957543b4414fdeca612cade1e4c0be45685fdaa2be0e2?s=80&d=identicon",
        "web_url": "http://127.0.0.1:3000/i-user-0-1720208283"
      },
      "merge_user": {
        "id": 40,
        "username": "i-user-0-1720208283",
        "name": "I User0",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/8325417f0f7919e3724957543b4414fdeca612cade1e4c0be45685fdaa2be0e2?s=80&d=identicon",
        "web_url": "http://127.0.0.1:3000/i-user-0-1720208283"
      },
      "merged_at": "2024-06-26T19:44:14.123Z",
      "closed_by": null,
      "closed_at": null,
      "target_branch": "master",
      "source_branch": "Brickwood-Brunefunc-417",
      "user_notes_count": 0,
      "upvotes": 0,
      "downvotes": 0,
      "author": {
        "id": 40,
        "username": "i-user-0-1720208283",
        "name": "I User0",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/8325417f0f7919e3724957543b4414fdeca612cade1e4c0be45685fdaa2be0e2?s=80&d=identicon",
        "web_url": "http://127.0.0.1:3000/i-user-0-1720208283"
      },
      "assignees": [],
      "assignee": null,
      "reviewers": [],
      "source_project_id": 7,
      "target_project_id": 7,
      "labels": [],
      "draft": false,
      "imported": false,
      "imported_from": "none",
      "work_in_progress": false,
      "milestone": null,
      "merge_when_pipeline_succeeds": false,
      "merge_status": "can_be_merged",
      "detailed_merge_status": "not_open",
      "merge_after": null,
      "sha": null,
      "merge_commit_sha": null,
      "squash_commit_sha": null,
      "discussion_locked": null,
      "should_remove_source_branch": null,
      "force_remove_source_branch": null,
      "prepared_at": null,
      "reference": "!10",
      "references": {
        "short": "!10",
        "relative": "!10",
        "full": "flightjs/Flight!10"
      },
      "web_url": "http://127.0.0.1:3000/flightjs/Flight/-/merge_requests/10",
      "time_stats": {
        "time_estimate": 0,
        "total_time_spent": 0,
        "human_time_estimate": null,
        "human_total_time_spent": null
      },
      "squash": false,
      "squash_on_merge": false,
      "task_completion_status": {
        "count": 0,
        "completed_count": 0
      },
      "has_conflicts": false,
      "blocking_discussions_resolved": true,
      "approvals_before_merge": null
    },
    "blocked_merge_request": {
      "id": 176,
      "iid": 14,
      "project_id": 7,
      "title": "second_mr",
      "description": "Signed-off-by: Lucas Zampieri <lzampier@redhat.com>",
      "state": "opened",
      "created_at": "2024-07-08T19:12:29.089Z",
      "updated_at": "2024-08-27T19:27:17.045Z",
      "merged_by": null,
      "merge_user": null,
      "merged_at": null,
      "closed_by": null,
      "closed_at": null,
      "target_branch": "master",
      "source_branch": "second_mr",
      "user_notes_count": 0,
      "upvotes": 0,
      "downvotes": 0,
      "author": {
        "id": 1,
        "username": "root",
        "name": "Administrator",
        "state": "active",
        "locked": false,
        "avatar_url": "https://www.gravatar.com/avatar/fc3634394c590e212d964e8e0a34c4d9b8c17c992f4d6d145d75f9c21c1c3b6e?s=80&d=identicon",
        "web_url": "http://127.0.0.1:3000/root"
      },
      "assignees": [],
      "assignee": null,
      "reviewers": [],
      "source_project_id": 7,
      "target_project_id": 7,
      "labels": [],
      "draft": false,
      "imported": false,
      "imported_from": "none",
      "work_in_progress": false,
      "milestone": null,
      "merge_when_pipeline_succeeds": false,
      "merge_status": "cannot_be_merged",
      "detailed_merge_status": "commits_status",
      "merge_after": null,
      "sha": "3a576801e528db79a75fbfea463673054ff224fb",
      "merge_commit_sha": null,
      "squash_commit_sha": null,
      "discussion_locked": null,
      "should_remove_source_branch": null,
      "force_remove_source_branch": true,
      "prepared_at": null,
      "reference": "!14",
      "references": {
        "short": "!14",
        "relative": "!14",
        "full": "flightjs/Flight!14"
      },
      "web_url": "http://127.0.0.1:3000/flightjs/Flight/-/merge_requests/14",
      "time_stats": {
        "time_estimate": 0,
        "total_time_spent": 0,
        "human_time_estimate": null,
        "human_total_time_spent": null
      },
      "squash": false,
      "squash_on_merge": false,
      "task_completion_status": {
        "count": 0,
        "completed_count": 0
      },
      "has_conflicts": true,
      "blocking_discussions_resolved": true,
      "approvals_before_merge": null
    },
    "project_id": 7
  }
]
```

## Récupérer les modifications d'un merge request {#retrieve-merge-request-changes}

> [!warning]
> Ce point de terminaison a été [déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/322117) dans GitLab 15.7 et [est prévu pour suppression](rest/deprecations.md) dans la version v5 de l'API. Utilisez plutôt le point de terminaison [liste des diffs de merge request](#list-merge-request-diffs).
> <!-- Do not remove line until endpoint is actually removed -->

Récupérer des informations sur un merge request, notamment ses fichiers et ses modifications.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/changes
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'ID interne du merge request. |
| `access_raw_diffs`  | boolean           | Non       | Récupérer les diffs de modifications via Gitaly. |
| `unidiff`           | boolean           | Non       | Présenter les diffs de modifications au format [diff unifié](https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html). La valeur par défaut est false. [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130610) dans GitLab 16.5. |

Les diffs associés à l'ensemble des modifications sont soumis aux mêmes limitations de taille que les autres diffs renvoyés par l'API ou consultés via l'interface utilisateur. Lorsque ces limites impactent les résultats, le champ `overflow` contient la valeur `true`. Récupérez les données de diff sans ces limites en ajoutant le paramètre `access_raw_diffs`, qui accède aux diffs directement depuis Gitaly, et non depuis la base de données. Cette approche est généralement plus lente et plus gourmande en ressources, mais n'est pas soumise aux limites de taille imposées aux diffs stockés en base de données. Les limites inhérentes à Gitaly s'appliquent toujours.

Exemple de réponse :

```json
{
  "id": 21,
  "iid": 1,
  "project_id": 4,
  "title": "Blanditiis beatae suscipit hic assumenda et molestias nisi asperiores repellat et.",
  "state": "reopened",
  "created_at": "2015-02-02T19:49:39.159Z",
  "updated_at": "2015-02-02T20:08:49.959Z",
  "target_branch": "secret_token",
  "source_branch": "version-1-9",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "name": "Chad Hamill",
    "username": "jarrett",
    "id": 5,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/b95567800f828948baf5f4160ebb2473?s=40&d=identicon",
    "web_url" : "https://gitlab.example.com/jarrett"
  },
  "assignee": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=40&d=identicon",
    "web_url" : "https://gitlab.example.com/root"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 4,
  "target_project_id": 4,
  "labels": [ ],
  "description": "Qui voluptatibus placeat ipsa alias quasi. Deleniti rem ut sint. Optio velit qui distinctio.",
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 4,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": null
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "mergeable",
  "subscribed" : true,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "changes_count": "1",
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "squash": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "discussion_locked": false,
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "task_completion_status":{
    "count":0,
    "completed_count":0
  },
  "changes": [
    {
    "old_path": "VERSION",
    "new_path": "VERSION",
    "a_mode": "100644",
    "b_mode": "100644",
    "diff": "@@ -1 +1 @@\ -1.9.7\ +1.9.8",
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false
    }
  ],
  "overflow": false
}
```

## Lister les diffs d'un merge request {#list-merge-request-diffs}

{{< history >}}

- `generated_file` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141576) dans GitLab 16.9 [with a flag](../administration/feature_flags/_index.md) nommé `collapse_generated_diff_files`. Désactivé par défaut.
- [Activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/432670) dans GitLab 16.10.
- `generated_file` [en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148478) dans GitLab 16.11. L'indicateur de fonctionnalité `collapse_generated_diff_files` a été supprimé.
- Les attributs de réponse `collapsed` et `too_large` ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199633) dans GitLab 18.4.

{{< /history >}}

Lister les diffs des fichiers modifiés dans un merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/diffs
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'ID interne du merge request. |
| `page`              | entier           | Non       | La page de résultats à renvoyer. La valeur par défaut est 1. |
| `per_page`          | entier           | Non       | Le nombre de résultats par page. La valeur par défaut est 20. |
| `unidiff`           | boolean           | Non       | Présenter les diffs au [format diff unifié](https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html). La valeur par défaut est false. [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130610) dans GitLab 16.5. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut        | Type    | Description |
|------------------|---------|-------------|
| `a_mode`         | string  | Ancien mode de fichier du fichier. |
| `b_mode`         | string  | Nouveau mode de fichier du fichier. |
| `collapsed`      | boolean | Les diffs du fichier sont exclus mais peuvent être récupérés à la demande. |
| `deleted_file`   | boolean | Le fichier a été supprimé. |
| `diff`           | string  | Représentation diff des modifications apportées au fichier. |
| `generated_file` | boolean | Le fichier est [marqué comme généré](../user/project/merge_requests/changes.md#collapse-generated-files). |
| `new_file`       | boolean | Le fichier a été ajouté. |
| `new_path`       | string  | Nouveau chemin du fichier. |
| `old_path`       | string  | Ancien chemin du fichier. |
| `renamed_file`   | boolean | Le fichier a été renommé. |
| `too_large`      | boolean | Les diffs du fichier sont exclus et ne peuvent pas être récupérés. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/diffs?page=1&per_page=2"
```

Exemple de réponse :

```json
[
  {
    "old_path": "README",
    "new_path": "README",
    "a_mode": "100644",
    "b_mode": "100644",
    "diff": "@@ -1 +1 @@\ -Title\ +README",
    "collapsed": false,
    "too_large": false,
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false,
    "generated_file": false
  },
  {
    "old_path": "VERSION",
    "new_path": "VERSION",
    "a_mode": "100644",
    "b_mode": "100644",
    "diff": "@@\ -1.9.7\ +1.9.8",
    "collapsed": false,
    "too_large": false,
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false,
    "generated_file": false
  }
]
```

> [!note]
> Ce point de terminaison est soumis aux [limites de diff des merge requests](../administration/instance_limits.md#diff-limits). Les merge requests qui dépassent les limites de diff renvoient des résultats limités.

## Afficher les diffs bruts d'un merge request {#show-merge-request-raw-diffs}

Afficher les diffs bruts des fichiers modifiés dans un merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/raw_diffs
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'ID interne du merge request. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et une réponse diff brute à utiliser par programmation :

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/raw_diffs"
```

Exemple de réponse :

```diff
        diff --git a/lib/api/helpers.rb b/lib/api/helpers.rb
index 31525ad523553c8d7eff163db3e539058efd6d3a..f30e36d6fdf4cd4fa25f62e08ecdbf4a7b169681 100644
--- a/lib/api/helpers.rb
+++ b/lib/api/helpers.rb
@@ -944,6 +944,10 @@ def send_git_blob(repository, blob)
       body ''
     end

+    def send_git_diff(repository, diff_refs)
+      header(*Gitlab::Workhorse.send_git_diff(repository, diff_refs))
+    end
+
     def send_git_archive(repository, **kwargs)
       header(*Gitlab::Workhorse.send_git_archive(repository, **kwargs))

diff --git a/lib/api/merge_requests.rb b/lib/api/merge_requests.rb
index e02d9eea1852f19fe5311acda6aa17465eeb422e..f32b38585398a18fea75c11d7b8ebb730eeb3fab 100644
--- a/lib/api/merge_requests.rb
+++ b/lib/api/merge_requests.rb
@@ -6,6 +6,8 @@ class MergeRequests < ::API::Base
     include PaginationParams
     include Helpers::Unidiff

+    helpers ::API::Helpers::HeadersHelpers
+
     CONTEXT_COMMITS_POST_LIMIT = 20

     before { authenticate_non_get! }
```

> [!note]
> Ce point de terminaison est soumis aux [limites de diff des merge requests](../administration/instance_limits.md#diff-limits). Les merge requests qui dépassent les limites de diff renvoient des résultats limités.

## Lister les pipelines d'un merge request {#list-merge-request-pipelines}

Lister tous les pipelines d'un merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/pipelines
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'ID interne du merge request. |

Pour restreindre la liste des pipelines de merge request, utilisez les paramètres de pagination `page` et `per_page`.

Exemple de réponse :

```json
[
  {
    "id": 77,
    "sha": "959e04d7c7a30600c894bd3c0cd0e1ce7f42c11d",
    "ref": "main",
    "status": "success"
  }
]
```

## Créer un pipeline de merge request {#create-merge-request-pipeline}

Créer un nouveau [pipeline pour un merge request](../ci/pipelines/merge_request_pipelines.md). Un pipeline créé depuis ce point de terminaison n'exécute pas un pipeline de branche/tag ordinaire. Pour créer des jobs, configurez `.gitlab-ci.yml` avec `only: [merge_requests]`.

Le nouveau pipeline peut être :

- Un pipeline de merge request détaché.
- Un [pipeline de résultats fusionnés](../ci/pipelines/merged_results_pipelines.md) si le [paramètre du projet est activé](../ci/pipelines/merged_results_pipelines.md#enable-merged-results-pipelines).

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/pipelines
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'ID interne du merge request. |

Exemple de réponse :

```json
{
  "id": 2,
  "sha": "b83d6e391c22777fca1ed3012fce84f633d7fed0",
  "ref": "refs/merge-requests/1/head",
  "status": "pending",
  "web_url": "http://localhost/user1/project1/pipelines/2",
  "before_sha": "0000000000000000000000000000000000000000",
  "tag": false,
  "yaml_errors": null,
  "user": {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://example.com"
  },
  "created_at": "2019-09-04T19:20:18.267Z",
  "updated_at": "2019-09-04T19:20:18.459Z",
  "started_at": null,
  "finished_at": null,
  "committed_at": null,
  "duration": null,
  "coverage": null,
  "detailed_status": {
    "icon": "status_pending",
    "text": "pending",
    "label": "pending",
    "group": "pending",
    "tooltip": "pending",
    "has_details": false,
    "details_path": "/user1/project1/pipelines/2",
    "illustration": null,
    "favicon": "/assets/ci_favicons/favicon_status_pending-5bdf338420e5221ca24353b6bff1c9367189588750632e9a871b7af09ff6a2ae.png"
  },
  "archived": false
}
```

## Créer un merge request {#create-a-merge-request}

Créer un nouveau merge request.

```plaintext
POST /projects/:id/merge_requests
```

| Attribut                  | Type              | Obligatoire | Description |
|----------------------------|-------------------|----------|-------------|
| `id`                       | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `source_branch`            | string            | Oui      | La branche source. |
| `target_branch`            | string            | Oui      | La branche cible. |
| `title`                    | string            | Oui      | Titre du merge request. |
| `allow_collaboration`      | boolean           | Non       | Autoriser les commits des membres pouvant fusionner dans la branche cible. |
| `approvals_before_merge`   | entier           | Non       | Nombre d'approbations requises avant que ce merge request puisse être fusionné (voir ci-dessous). Pour configurer les règles d'approbation, consultez l'[API d'approbation des merge requests](merge_request_approvals.md). [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) dans GitLab 16.0. Premium et Ultimate uniquement. |
| `allow_maintainer_to_push` | boolean           | Non       | Alias de `allow_collaboration`. |
| `assignee_id`              | entier           | Non       | Identifiant de l'utilisateur assigné. |
| `assignee_ids`             | tableau d'entiers     | Non       | L'identifiant des utilisateurs à assigner au merge request. Définissez la valeur sur `0` ou fournissez une valeur vide pour retirer tous les assignés. |
| `description`              | string            | Non       | Description de la merge request. Limité à 1 048 576 caractères. |
| `labels`                   | string            | Non       | Labels pour le merge request, sous forme de liste séparée par des virgules. Si un label n'existe pas déjà, cela crée un nouveau label de projet et l'assigne au merge request. |
| `merge_after`              | string            | Non       | Date après laquelle le merge request peut être fusionné. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/510992) dans GitLab 17.8. |
| `milestone_id`             | entier           | Non       | L'identifiant global d'un jalon. Mutuellement exclusif avec `milestone`. |
| `milestone`                | string            | Non       | Le titre d'un jalon de projet ou de groupe ancêtre à assigner au merge request. Correspondance exacte (sensible à la casse). Mutuellement exclusif avec `milestone_id`. |
| `remove_source_branch`     | boolean           | Non       | Indicateur spécifiant si un merge request doit supprimer la branche source lors de la fusion. |
| `reviewer_ids`             | tableau d'entiers     | Non       | L'identifiant des utilisateurs ajoutés en tant que relecteur au merge request. Si défini sur `0` ou laissé vide, aucun relecteur n'est ajouté. |
| `squash`                   | boolean           | Non       | Si `true`, tous les commits sont squashés en un seul commit lors de la fusion. Si non fourni, utilise par défaut le [paramètre d'option squash du projet](../user/project/merge_requests/squash_and_merge.md#configure-squash-options-for-a-project). Les paramètres du projet peuvent remplacer cette valeur au moment de la fusion. |
| `target_project_id`        | entier           | Non       | Identifiant numérique du projet cible. |

Exemple de réponse :

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "imported": false,
  "imported_from": "none",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "main",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "not_open",
  "merge_error": null,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

Pour les notes importantes sur les données de réponse, voir [notes sur la réponse d'une merge request unique](#single-merge-request-response-notes).

## Mettre à jour un merge request {#update-a-merge-request}

Mettre à jour un merge request existant.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid
```

| Attribut                  | Type              | Obligatoire | Description |
|----------------------------|-------------------|----------|-------------|
| `id`                       | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid`        | entier           | Oui      | L'identifiant d'un merge request. |
| `add_labels`               | string            | Non       | Noms de labels séparés par des virgules à ajouter à un merge request. Si un label n'existe pas déjà, cela crée un nouveau label de projet et l'assigne au merge request. |
| `allow_collaboration`      | boolean           | Non       | Autoriser les commits des membres pouvant fusionner dans la branche cible. |
| `allow_maintainer_to_push` | boolean           | Non       | Alias de `allow_collaboration`. |
| `assignee_id`              | entier           | Non       | L'identifiant de l'utilisateur à assigner au merge request. Définissez la valeur sur `0` ou fournissez une valeur vide pour retirer tous les assignés. |
| `assignee_ids`             | tableau d'entiers     | Non       | L'identifiant des utilisateurs à assigner au merge request. Définissez la valeur sur `0` ou fournissez une valeur vide pour retirer tous les assignés. |
| `description`              | string            | Non       | Description de la merge request. Limité à 1 048 576 caractères. |
| `discussion_locked`        | boolean           | Non       | Indicateur spécifiant si la discussion du merge request est verrouillée. Seuls les membres du projet peuvent ajouter, modifier ou résoudre des commentaires dans les discussions verrouillées. |
| `labels`                   | string            | Non       | Noms de labels séparés par des virgules pour un merge request. Définir sur une chaîne vide pour annuler l'attribution de tous les labels. Si un label n'existe pas déjà, cela crée un nouveau label de projet et l'assigne au merge request. |
| `merge_after`              | string            | Non       | Date après laquelle le merge request peut être fusionné. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/510992) dans GitLab 17.8. |
| `milestone_id`             | entier           | Non       | L'identifiant global d'un jalon à assigner au merge request. Définissez la valeur sur `0` ou fournissez une valeur vide pour retirer le jalon. Mutuellement exclusif avec `milestone`. |
| `milestone`                | string            | Non       | Le titre d'un jalon de projet ou de groupe ancêtre à assigner au merge request. Correspondance exacte (sensible à la casse). Mutuellement exclusif avec `milestone_id`. |
| `remove_labels`            | string            | Non       | Noms de labels séparés par des virgules à retirer d'un merge request. |
| `remove_source_branch`     | boolean           | Non       | Indicateur spécifiant si un merge request doit supprimer la branche source lors de la fusion. |
| `reviewer_ids`             | tableau d'entiers     | Non       | L'identifiant des utilisateurs définis en tant que relecteur du merge request. Définissez la valeur sur `0` ou fournissez une valeur vide pour retirer tous les relecteurs. |
| `squash`                   | boolean           | Non       | Si `true`, tous les commits sont squashés en un seul commit lors de la fusion. Si non fourni, utilise par défaut le [paramètre d'option squash du projet](../user/project/merge_requests/squash_and_merge.md#configure-squash-options-for-a-project). Si le projet est configuré pour **Exiger** ou **Ne pas autoriser** le squash, ce paramètre prend le dessus au moment de la fusion. |
| `state_event`              | string            | Non       | Nouvel état (fermer/rouvrir). |
| `target_branch`            | string            | Non       | La branche cible. |
| `title`                    | string            | Non       | Titre du merge request. |

Doit inclure au moins un attribut non obligatoire.

Exemple de réponse :

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "main",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "not_open",
  "merge_error": null,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

Pour les notes importantes sur les données de réponse, voir [notes sur la réponse d'une merge request unique](#single-merge-request-response-notes).

## Supprimer un merge request {#delete-a-merge-request}

Supprimer un merge request. Seuls les administrateurs et les propriétaires de projets peuvent supprimer des merge requests.

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid
```

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'ID interne du merge request. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/merge_requests/85"
```

## Fusionner un merge request {#merge-a-merge-request}

Accepter et fusionner les modifications soumises avec un merge request à l'aide de cette API.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/merge
```

Attributs pris en charge :

| Attribut                      | Type              | Obligatoire | Description |
|--------------------------------|-------------------|----------|-------------|
| `id`                           | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid`            | entier           | Oui      | L'ID interne du merge request. |
| `auto_merge`                   | boolean           | Non       | Si `true`, le merge request fusionne lorsque le pipeline réussit. |
| `merge_commit_message`         | string            | Non       | Message de commit de fusion personnalisé. |
| `merge_when_pipeline_succeeds` | boolean           | Non       | [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/521291) dans GitLab 17.11. Utilisez `auto_merge` à la place. |
| `sha`                          | string            | Non       | Si présent, ce SHA doit correspondre au HEAD de la branche source. Utilisez ce paramètre pour vous assurer que seuls les commits examinés sont fusionnés. |
| `should_remove_source_branch`  | boolean           | Non       | Si `true`, supprime la branche source. |
| `squash_commit_message`        | string            | Non       | Message de commit de squash personnalisé. |
| `squash`                       | boolean           | Non       | Si `true`, tous les commits sont squashés en un seul commit lors de la fusion. |

Cette API renvoie des codes de statut HTTP spécifiques en cas d'échec :

| Statut HTTP | Message                                    | Raison |
|-------------|--------------------------------------------|--------|
| `401`       | `401 Unauthorized`                         | Cet utilisateur n'est pas autorisé à accepter ce merge request. |
| `405`       | `405 Method Not Allowed`                   | Le merge request ne peut pas être fusionné. |
| `409`       | `SHA does not match HEAD of source branch` | Le paramètre `sha` fourni ne correspond pas au HEAD de la source. |
| `422`       | `Branch cannot be merged`                  | La fusion du merge request a échoué. |

Pour les notes importantes sur les données de réponse, voir [notes sur la réponse d'une merge request unique](#single-merge-request-response-notes).

Exemple de réponse :

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "main",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "not_open",
  "merge_error": null,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

## Fusionner vers le chemin de référence de fusion par défaut {#merge-to-default-merge-ref-path}

Fusionne les modifications entre les branches source et cible du merge request dans la référence `refs/merge-requests/:iid/merge` du dépôt du projet cible, si possible. Cette référence représente l'état que la branche cible aurait si une action de fusion ordinaire était effectuée.

Cette action n'est pas une action de fusion ordinaire, car elle ne modifie en aucune façon l'état de la branche cible du merge request.

Cette référence (`refs/merge-requests/:iid/merge`) n'est pas nécessairement écrasée lors de l'envoi de requêtes à cette API, bien qu'elle s'assure que la référence est dans l'état le plus récent possible.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/merge_ref
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'ID interne du merge request. |

Cette API renvoie des codes de statut HTTP spécifiques :

| Statut HTTP | Message                          | Raison |
|-------------|----------------------------------|--------|
| `200`       | _(aucun)_                         | Succès. Renvoie le commit HEAD de `refs/merge-requests/:iid/merge`. |
| `400`       | `Merge request is not mergeable` | Le merge request présente des conflits. |
| `400`       | `Merge ref cannot be updated`    |        |
| `400`       | `Unsupported operation`          | La base de données GitLab est en mode lecture seule. |

Exemple de réponse :

```json
{
  "commit_id": "854a3a7a17acbcc0bbbea170986df1eb60435f34"
}
```

## Annuler la fusion lorsque le pipeline réussit {#cancel-merge-when-pipeline-succeeds}

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/cancel_merge_when_pipeline_succeeds
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'ID interne du merge request. |

Cette API renvoie des codes de statut HTTP spécifiques :

| Statut HTTP | Message  | Raison |
|-------------|----------|--------|
| `201`       | _(aucun)_ | Succès, ou le merge request a déjà été fusionné. |
| `406`       | `Can't cancel the automatic merge` | Le merge request est fermé. |

Pour les notes importantes sur les données de réponse, voir [notes sur la réponse d'une merge request unique](#single-merge-request-response-notes).

Exemple de réponse :

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "main",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": false,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "not_open",
  "merge_error": null,
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

## Rebaser un merge request {#rebase-a-merge-request}

Rebaser automatiquement le `source_branch` du merge request par rapport à son `target_branch`.

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/rebase
```

| Attribut           | Type           | Obligatoire | Description |
|---------------------|----------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier        | Oui      | L'ID interne du merge request. |
| `skip_ci`           | boolean        | Non       | Définissez sur `true` pour ignorer la création d'un pipeline CI. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/76/merge_requests/1/rebase"
```

Cette API renvoie des codes de statut HTTP spécifiques :

| Statut HTTP | Message                                    | Raison |
|-------------|--------------------------------------------|--------|
| `202`       | _(aucun message)_ | Ajouté à la file d'attente avec succès. |
| `403`       | `Cannot push to source branch` | Vous n'avez pas l'autorisation de pousser vers la branche source du merge request. |
| `403`       | `Source branch does not exist` | Vous n'avez pas l'autorisation de pousser vers la branche source du merge request. |
| `403`       | `Source branch is protected from force push` | Vous n'avez pas l'autorisation de pousser vers la branche source du merge request. |
| `409`       | `Failed to enqueue the rebase operation` | Une transaction de longue durée a peut-être bloqué votre requête. |

Si la requête est ajoutée à la file d'attente avec succès, la réponse contient :

```json
{
  "rebase_in_progress": true
}
```

Vous pouvez interroger le point de terminaison [récupérer un merge request](#retrieve-a-merge-request) avec le paramètre `include_rebase_in_progress` pour vérifier le statut de la requête asynchrone.

Si l'opération de rebase est en cours, la réponse inclut les éléments suivants :

```json
{
  "rebase_in_progress": true,
  "merge_error": null
}
```

Une fois l'opération de rebase terminée avec succès, la réponse inclut les éléments suivants :

```json
{
  "rebase_in_progress": false,
  "merge_error": null
}
```

Si l'opération de rebase échoue, la réponse inclut les éléments suivants :

```json
{
  "rebase_in_progress": false,
  "merge_error": "Rebase failed. Please rebase locally"
}
```

## Commentaires sur les merge requests {#comments-on-merge-requests}

La ressource [notes](notes.md) permet de créer des commentaires.

## Lister les tickets qui se ferment lors de la fusion {#list-issues-that-close-on-merge}

Lister les tickets qui seraient fermés lors de la fusion d'un merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/closes_issues
```

Attributs pris en charge :

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | Identifiant interne de la merge request. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants lorsque vous utilisez le système de suivi des tickets GitLab :

| Attribut                   | Type     | Description |
|-----------------------------|----------|-------------|
| `[].assignee`               | objet   | Premier responsable du ticket. |
| `[].assignees`              | tableau    | Responsables du ticket. |
| `[].author`                 | objet   | Utilisateur qui a créé ce ticket. |
| `[].blocking_issues_count`  | entier  | Nombre de tickets que ce ticket bloque. |
| `[].closed_at`              | datetime | Horodatage de la fermeture du ticket. |
| `[].closed_by`              | objet   | Utilisateur qui a fermé ce ticket. |
| `[].confidential`           | boolean  | Indique si le ticket est confidentiel. |
| `[].created_at`             | datetime | Horodatage de la création du ticket. |
| `[].description`            | string   | Description du ticket. |
| `[].discussion_locked`      | boolean  | Indique si les commentaires sur le ticket sont réservés aux membres. |
| `[].downvotes`              | entier  | Nombre de votes négatifs reçus par le ticket. |
| `[].due_date`               | date     | Date d'échéance du ticket. |
| `[].id`                     | entier  | ID du ticket. |
| `[].iid`                    | entier  | ID interne du ticket. |
| `[].issue_type`             | string   | Type du ticket. Peut être `issue`, `incident`, `test_case`, `requirement`, `task`. |
| `[].labels`                 | tableau    | Labels du ticket. |
| `[].merge_requests_count`   | entier  | Nombre de merge requests qui ferment le ticket lors de la fusion. |
| `[].milestone`              | objet   | Jalon du ticket. |
| `[].project_id`             | entier  | ID du projet du ticket. |
| `[].state`                  | string   | État du ticket. Peut être `opened` ou `closed`. |
| `[].task_completion_status` | objet   | Inclut `count` et `completed_count`. |
| `[].time_stats`             | objet   | Statistiques de temps pour le ticket. Inclut `time_estimate`, `total_time_spent`, `human_time_estimate` et `human_total_time_spent`. |
| `[].title`                  | string   | Titre du ticket. |
| `[].type`                   | string   | Type du ticket. Identique à `issue_type`, mais en majuscules. |
| `[].updated_at`             | datetime | Horodatage de la dernière mise à jour du ticket. |
| `[].upvotes`                | entier  | Nombre de votes positifs reçus par le ticket. |
| `[].user_notes_count`       | entier  | Nombre de notes utilisateur du ticket. |
| `[].web_url`                | string   | URL web du ticket. |
| `[].weight`                 | entier  | Poids du ticket. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants lorsque vous utilisez un système de suivi des tickets externe, tel que Jira :

| Attribut  | Type    | Description |
|------------|---------|-------------|
| `[].id`    | entier | ID du ticket. |
| `[].title` | string  | Titre du ticket. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/76/merge_requests/1/closes_issues"
```

Exemple de réponse lorsque vous utilisez le système de suivi des tickets GitLab :

```json
[
  {
    "id": 76,
    "iid": 6,
    "project_id": 1,
    "title": "Consequatur vero maxime deserunt laboriosam est voluptas dolorem.",
    "description": "Ratione dolores corrupti mollitia soluta quia.",
    "state": "opened",
    "created_at": "2024-09-06T10:58:49.002Z",
    "updated_at": "2024-09-06T11:01:40.710Z",
    "closed_at": null,
    "closed_by": null,
    "labels": [
      "label"
    ],
    "milestone": {
      "project_id": 1,
      "description": "Ducimus nam enim ex consequatur cumque ratione.",
      "state": "closed",
      "due_date": null,
      "iid": 2,
      "created_at": "2016-01-04T15:31:39.996Z",
      "title": "v4.0",
      "id": 17,
      "updated_at": "2016-01-04T15:31:39.996Z"
    },
    "assignees": [
      {
        "id": 1,
        "username": "root",
        "name": "Administrator",
        "state": "active",
        "locked": false,
        "avatar_url": null,
        "web_url": "https://gitlab.example.com/root"
      }
    ],
    "author": {
      "id": 18,
      "username": "eileen.lowe",
      "name": "Alexandra Bashirian",
      "state": "active",
      "locked": false,
      "avatar_url": null,
      "web_url": "https://gitlab.example.com/eileen.lowe"
    },
    "type": "ISSUE",
    "assignee": {
      "id": 1,
      "username": "root",
      "name": "Administrator",
      "state": "active",
      "locked": false,
      "avatar_url": null,
      "web_url": "https://gitlab.example.com/root"
    },
    "user_notes_count": 1,
    "merge_requests_count": 1,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "discussion_locked": null,
    "issue_type": "issue",
    "web_url": "https://gitlab.example.com/my-group/my-project/-/issues/6",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    },
    "task_completion_status": {
      "count": 0,
      "completed_count": 0
    },
    "weight": null,
    "blocking_issues_count": 0
 }
]
```

Exemple de réponse lorsque vous utilisez un système de suivi des tickets externe, tel que Jira :

```json
[
   {
       "id" : "PROJECT-123",
       "title" : "Title of this issue"
   }
]
```

## Lister les tickets liés au merge request {#list-issues-related-to-the-merge-request}

Lister les tickets liés à un merge request à partir de son titre, de sa description, des messages de commit, des commentaires et des discussions.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/related_issues
```

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'ID interne du merge request. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/76/merge_requests/1/related_issues"
```

Exemple de réponse lorsque vous utilisez le système de suivi des tickets GitLab :

```json
[
   {
      "state" : "opened",
      "description" : "Ratione dolores corrupti mollitia soluta quia.",
      "author" : {
         "state" : "active",
         "id" : 18,
         "web_url" : "https://gitlab.example.com/eileen.lowe",
         "name" : "Alexandra Bashirian",
         "avatar_url" : null,
         "username" : "eileen.lowe"
      },
      "milestone" : {
         "project_id" : 1,
         "description" : "Ducimus nam enim ex consequatur cumque ratione.",
         "state" : "closed",
         "due_date" : null,
         "iid" : 2,
         "created_at" : "2016-01-04T15:31:39.996Z",
         "title" : "v4.0",
         "id" : 17,
         "updated_at" : "2016-01-04T15:31:39.996Z"
      },
      "project_id" : 1,
      "assignee" : {
         "state" : "active",
         "id" : 1,
         "name" : "Administrator",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root"
      },
      "updated_at" : "2016-01-04T15:31:51.081Z",
      "id" : 76,
      "title" : "Consequatur vero maxime deserunt laboriosam est voluptas dolorem.",
      "created_at" : "2016-01-04T15:31:51.081Z",
      "iid" : 6,
      "labels" : [],
      "user_notes_count": 1,
      "changes_count": "1"
   }
]
```

Exemple de réponse lorsque vous utilisez un système de suivi des tickets externe, tel que Jira :

```json
[
   {
       "id" : "PROJECT-123",
       "title" : "Title of this issue"
   }
]
```

## S'abonner à un merge request {#subscribe-to-a-merge-request}

Abonne l'utilisateur authentifié à un merge request pour recevoir des notifications.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/subscribe
```

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'ID interne du merge request. |

Si l'utilisateur est déjà abonné au merge request, le point de terminaison renvoie le code de statut `HTTP 304 Not Modified`.

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/17/subscribe"
```

Exemple de réponse :

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "main",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "not_open",
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

Pour les notes importantes sur les données de réponse, voir [notes sur la réponse d'une merge request unique](#single-merge-request-response-notes).

## Se désabonner d'un merge request {#unsubscribe-from-a-merge-request}

Désabonne l'utilisateur authentifié d'un merge request pour ne plus recevoir de notifications de ce merge request.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/unsubscribe
```

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'ID interne du merge request. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/17/unsubscribe"
```

Si l'utilisateur n'est pas abonné au merge request, le point de terminaison renvoie le code de statut `HTTP 304 Not Modified`.

Exemple de réponse :

```json
{
  "id": 1,
  "iid": 1,
  "project_id": 3,
  "title": "test1",
  "description": "fixed login page css paddings",
  "state": "merged",
  "created_at": "2017-04-29T08:46:00Z",
  "updated_at": "2017-04-29T08:46:00Z",
  "target_branch": "main",
  "source_branch": "test1",
  "upvotes": 0,
  "downvotes": 0,
  "author": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignee": {
    "id": 1,
    "name": "Administrator",
    "username": "admin",
    "state": "active",
    "avatar_url": null,
    "web_url" : "https://gitlab.example.com/admin"
  },
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "reviewers": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "source_project_id": 2,
  "target_project_id": 3,
  "labels": [
    "Community contribution",
    "Manage"
  ],
  "draft": false,
  "work_in_progress": false,
  "milestone": {
    "id": 5,
    "iid": 1,
    "project_id": 3,
    "title": "v2.0",
    "description": "Assumenda aut placeat expedita exercitationem labore sunt enim earum.",
    "state": "closed",
    "created_at": "2015-02-02T19:49:26.013Z",
    "updated_at": "2015-02-02T19:49:26.013Z",
    "due_date": "2018-09-22",
    "start_date": "2018-08-08",
    "web_url": "https://gitlab.example.com/my-group/my-project/milestones/1"
  },
  "merge_when_pipeline_succeeds": true,
  "merge_status": "can_be_merged",
  "detailed_merge_status": "not_open",
  "sha": "8888888888888888888888888888888888888888",
  "merge_commit_sha": null,
  "squash_commit_sha": null,
  "user_notes_count": 1,
  "discussion_locked": null,
  "should_remove_source_branch": true,
  "force_remove_source_branch": false,
  "allow_collaboration": false,
  "allow_maintainer_to_push": false,
  "web_url": "http://gitlab.example.com/my-group/my-project/merge_requests/1",
  "references": {
    "short": "!1",
    "relative": "!1",
    "full": "my-group/my-project!1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "squash": false,
  "subscribed": false,
  "changes_count": "1",
  "merged_by": { // Deprecated and will be removed in API v5, use `merge_user` instead
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merge_user": {
    "id": 87854,
    "name": "Douwe Maan",
    "username": "DouweM",
    "state": "active",
    "avatar_url": "https://gitlab.example.com/uploads/-/system/user/avatar/87854/avatar.png",
    "web_url": "https://gitlab.com/DouweM"
  },
  "merged_at": "2018-09-07T11:16:17.520Z",
  "merge_after": "2018-09-07T11:16:00.000Z",
  "prepared_at": "2018-09-04T11:16:17.520Z",
  "closed_by": null,
  "closed_at": null,
  "latest_build_started_at": "2018-09-07T07:27:38.472Z",
  "latest_build_finished_at": "2018-09-07T08:07:06.012Z",
  "first_deployed_to_production_at": null,
  "pipeline": {
    "id": 29626725,
    "sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "ref": "patch-28",
    "status": "success",
    "web_url": "https://gitlab.example.com/my-group/my-project/pipelines/29626725"
  },
  "diff_refs": {
    "base_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00",
    "head_sha": "2be7ddb704c7b6b83732fdd5b9f09d5a397b5f8f",
    "start_sha": "c380d3acebd181f13629a25d2e2acca46ffe1e00"
  },
  "diverged_commits_count": 2,
  "task_completion_status":{
    "count":0,
    "completed_count":0
  }
}
```

Pour les notes importantes sur les données de réponse, voir [notes sur la réponse d'une merge request unique](#single-merge-request-response-notes).

## Créer un élément de la liste de tâches {#create-a-to-do-item}

Crée manuellement un élément de la liste de tâches pour l'utilisateur actuel sur un merge request. Si un élément de la liste de tâches existe déjà pour l'utilisateur sur ce merge request, ce point de terminaison renvoie le code de statut `HTTP 304 Not Modified`.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/todo
```

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'ID interne du merge request. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/27/todo"
```

Exemple de réponse :

```json
{
  "id": 113,
  "project": {
    "id": 3,
    "name": "GitLab CI/CD",
    "name_with_namespace": "GitLab Org / GitLab CI/CD",
    "path": "gitlab-ci",
    "path_with_namespace": "gitlab-org/gitlab-ci"
  },
  "author": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/root"
  },
  "action_name": "marked",
  "target_type": "MergeRequest",
  "target": {
    "id": 27,
    "iid": 7,
    "project_id": 3,
    "title": "Et voluptas laudantium minus nihil recusandae ut accusamus earum aut non.",
    "description": "Veniam sunt nihil modi earum cumque illum delectus. Nihil ad quis distinctio quia. Autem eligendi at quibusdam repellendus.",
    "state": "merged",
    "created_at": "2016-06-17T07:48:04.330Z",
    "updated_at": "2016-07-01T11:14:15.537Z",
    "target_branch": "allow_regex_for_project_skip_ref",
    "source_branch": "backup",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "name": "Jarret O'Keefe",
      "username": "francisca",
      "id": 14,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a7fa515d53450023c83d62986d0658a8?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/francisca",
      "discussion_locked": false
    },
    "assignee": {
      "name": "Dr. Gabrielle Strosin",
      "username": "barrett.krajcik",
      "id": 4,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/733005fcd7e6df12d2d8580171ccb966?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/barrett.krajcik"
    },
    "assignees": [{
      "name": "Miss Monserrate Beier",
      "username": "axel.block",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/axel.block"
    }],
    "reviewers": [{
      "name": "Miss Monserrate Beier",
      "username": "axel.block",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/axel.block"
    }],
    "source_project_id": 3,
    "target_project_id": 3,
    "labels": [],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 27,
      "iid": 2,
      "project_id": 3,
      "title": "v1.0",
      "description": "Quis ea accusantium animi hic fuga assumenda.",
      "state": "active",
      "created_at": "2016-06-17T07:47:33.840Z",
      "updated_at": "2016-06-17T07:47:33.840Z",
      "due_date": null
    },
    "merge_when_pipeline_succeeds": false,
    "merge_status": "unchecked",
    "detailed_merge_status": "not_open",
    "subscribed": true,
    "sha": "8888888888888888888888888888888888888888",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 7,
    "changes_count": "1",
    "should_remove_source_branch": true,
    "force_remove_source_branch": false,
    "squash": false,
    "web_url": "http://example.com/my-group/my-project/merge_requests/1",
    "references": {
      "short": "!1",
      "relative": "!1",
      "full": "my-group/my-project!1"
    }
  },
  "target_url": "https://gitlab.example.com/gitlab-org/gitlab-ci/merge_requests/7",
  "body": "Et voluptas laudantium minus nihil recusandae ut accusamus earum aut non.",
  "state": "pending",
  "created_at": "2016-07-01T11:14:15.530Z"
}
```

## Récupérer les versions de diff du merge request {#retrieve-merge-request-diff-versions}

Récupérer les versions de diff pour un merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/versions
```

| Attribut           | Type    | Obligatoire | Description                           |
|---------------------|---------|----------|---------------------------------------|
| `id`                | Chaîne  | Oui      | L'ID du projet.                |
| `merge_request_iid` | entier | Oui      | L'ID interne du merge request. |

Pour une explication des SHA dans la réponse, voir [SHA dans la réponse API](#shas-in-the-api-response).

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/versions"
```

Exemple de réponse :

```json
[{
  "id": 110,
  "head_commit_sha": "33e2ee8579fda5bc36accc9c6fbd0b4fefda9e30",
  "base_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "start_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "created_at": "2016-07-26T14:44:48.926Z",
  "merge_request_id": 105,
  "state": "collected",
  "real_size": "1",
  "patch_id_sha": "d504412d5b6e6739647e752aff8e468dde093f2f"
}, {
  "id": 108,
  "head_commit_sha": "3eed087b29835c48015768f839d76e5ea8f07a24",
  "base_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "start_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "created_at": "2016-07-25T14:21:33.028Z",
  "merge_request_id": 105,
  "state": "collected",
  "real_size": "1",
  "patch_id_sha": "72c30d1f0115fc1d2bb0b29b24dc2982cbcdfd32"
}]
```

### SHA dans la réponse API {#shas-in-the-api-response}

| Champ SHA          | Objectif                                                                             |
|--------------------|-------------------------------------------------------------------------------------|
| `base_commit_sha`  | Le SHA du commit de base de fusion entre la branche source et les branches cibles.        |
| `head_commit_sha`  | Le commit HEAD de la branche source.                                               |
| `start_commit_sha` | Le SHA du commit HEAD de la branche cible lorsque cette version du diff a été créée. |

## Récupérer une version de diff d'un merge request {#retrieve-a-merge-request-diff-version}

{{< history >}}

- Les attributs de réponse `collapsed` et `too_large` ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199633) dans GitLab 18.4.

{{< /history >}}

Récupérer une version de diff spécifique pour un merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/versions/:version_id
```

Attributs pris en charge :

| Attribut           | Type    | Obligatoire | Description |
|---------------------|---------|----------|-------------|
| `id`                | Chaîne  | Oui      | ID du projet. |
| `merge_request_iid` | entier | Oui      | Identifiant interne de la merge request. |
| `version_id`        | entier | Oui      | ID de la version de diff du merge request. |
| `unidiff`           | boolean | Non       | Présenter les diffs au [format diff unifié](https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html). La valeur par défaut est false. [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130610) dans GitLab 16.5. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                     | Type         | Description |
|-------------------------------|--------------|-------------|
| `id`                          | entier      | ID de la version de diff du merge request. |
| `base_commit_sha`             | string       | SHA du commit de base de fusion entre la branche source et les branches cibles. |
| `commits`                     | tableau d'objets | Commits dans le diff du merge request. |
| `commits[].id`                | string       | Identifiant du commit. |
| `commits[].short_id`          | string       | Identifiant court du commit. |
| `commits[].created_at`        | datetime     | Identique au champ `committed_date`. |
| `commits[].parent_ids`        | tableau        | Identifiants des commits parents. |
| `commits[].title`             | string       | Titre du commit. |
| `commits[].message`           | string       | Message de commit. |
| `commits[].author_name`       | string       | Nom de l'auteur du commit. |
| `commits[].author_email`      | string       | Adresse e-mail de l'auteur du commit. |
| `commits[].authored_date`     | datetime     | Date et heure de création du commit. |
| `commits[].committer_name`    | string       | Nom du contributeur. |
| `commits[].committer_email`   | string       | Adresse e-mail du contributeur. |
| `commits[].committed_date`    | datetime     | Date et heure du commit. |
| `commits[].trailers`          | objet       | Trailers Git analysés pour le commit. Les clés en double n'incluent que la dernière valeur. |
| `commits[].extended_trailers` | objet       | Trailers Git analysés pour le commit. |
| `commits[].web_url`           | string       | URL web du merge request. |
| `created_at`                  | datetime     | Date et heure de création du merge request. |
| `diffs`                       | tableau d'objets | Diffs dans la version de diff du merge request. |
| `diffs[].a_mode`              | string       | Ancien mode de fichier du fichier. |
| `diffs[].b_mode`              | string       | Nouveau mode de fichier du fichier. |
| `diffs[].collapsed`           | boolean      | Les diffs du fichier sont exclus mais peuvent être récupérés à la demande. |
| `diffs[].deleted_file`        | boolean      | Le fichier a été supprimé. |
| `diffs[].diff`                | string       | Contenu du diff. |
| `diffs[].generated_file`      | boolean      | Le fichier est [marqué comme généré](../user/project/merge_requests/changes.md#collapse-generated-files). |
| `diffs[].new_file`            | boolean      | Le fichier a été ajouté. |
| `diffs[].new_path`            | string       | Nouveau chemin du fichier. |
| `diffs[].old_path`            | string       | Ancien chemin du fichier. |
| `diffs[].renamed_file`        | boolean      | Le fichier a été renommé. |
| `diffs[].too_large`           | boolean      | Les diffs du fichier sont exclus et ne peuvent pas être récupérés. |
| `head_commit_sha`             | string       | Commit HEAD de la branche source. |
| `merge_request_id`            | entier      | Identifiant de la merge request. |
| `patch_id_sha`                | string       | [Patch ID](https://git-scm.com/docs/git-patch-id) pour le diff du merge request. |
| `real_size`                   | string       | Nombre de modifications dans le diff du merge request. |
| `start_commit_sha`            | string       | SHA du commit HEAD de la branche cible lorsque cette version du diff a été créée. |
| `state`                       | string       | État du diff du merge request. Peut être `collected`, `overflow`, `without_files`. Valeurs obsolètes : `timeout`, `overflow_commits_safe_size`, `overflow_diff_files_limit`, `overflow_diff_lines_limit`. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/merge_requests/1/versions/1"
```

Exemple de réponse :

```json
{
  "id": 110,
  "head_commit_sha": "33e2ee8579fda5bc36accc9c6fbd0b4fefda9e30",
  "base_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "start_commit_sha": "eeb57dffe83deb686a60a71c16c32f71046868fd",
  "created_at": "2016-07-26T14:44:48.926Z",
  "merge_request_id": 105,
  "state": "collected",
  "real_size": "1",
  "patch_id_sha": "d504412d5b6e6739647e752aff8e468dde093f2f",
  "commits": [{
    "id": "33e2ee8579fda5bc36accc9c6fbd0b4fefda9e30",
    "short_id": "33e2ee85",
    "parent_ids": [],
    "title": "Change year to 2018",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "authored_date": "2016-07-26T17:44:29.000+03:00",
    "committer_name": "Administrator",
    "committer_email": "admin@example.com",
    "committed_date": "2016-07-26T17:44:29.000+03:00",
    "created_at": "2016-07-26T17:44:29.000+03:00",
    "message": "Change year to 2018",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/project/-/commit/33e2ee8579fda5bc36accc9c6fbd0b4fefda9e30"
  }, {
    "id": "aa24655de48b36335556ac8a3cd8bb521f977cbd",
    "short_id": "aa24655d",
    "parent_ids": [],
    "title": "Update LICENSE",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "authored_date": "2016-07-25T17:21:53.000+03:00",
    "committer_name": "Administrator",
    "committer_email": "admin@example.com",
    "committed_date": "2016-07-25T17:21:53.000+03:00",
    "created_at": "2016-07-25T17:21:53.000+03:00",
    "message": "Update LICENSE",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/project/-/commit/aa24655de48b36335556ac8a3cd8bb521f977cbd"
  }, {
    "id": "3eed087b29835c48015768f839d76e5ea8f07a24",
    "short_id": "3eed087b",
    "parent_ids": [],
    "title": "Add license",
    "author_name": "Administrator",
    "author_email": "admin@example.com",
    "authored_date": "2016-07-25T17:21:20.000+03:00",
    "committer_name": "Administrator",
    "committer_email": "admin@example.com",
    "committed_date": "2016-07-25T17:21:20.000+03:00",
    "created_at": "2016-07-25T17:21:20.000+03:00",
    "message": "Add license",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/project/-/commit/3eed087b29835c48015768f839d76e5ea8f07a24"
  }],
  "diffs": [{
    "old_path": "LICENSE",
    "new_path": "LICENSE",
    "a_mode": "0",
    "b_mode": "100644",
    "diff": "@@ -0,0 +1,21 @@\n+The MIT License (MIT)\n+\n+Copyright (c) 2018 Administrator\n+\n+Permission is hereby granted, free of charge, to any person obtaining a copy\n+of this software and associated documentation files (the \"Software\"), to deal\n+in the Software without restriction, including without limitation the rights\n+to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\n+copies of the Software, and to permit persons to whom the Software is\n+furnished to do so, subject to the following conditions:\n+\n+The above copyright notice and this permission notice shall be included in all\n+copies or substantial portions of the Software.\n+\n+THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\n+IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\n+FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\n+AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\n+LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\n+OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\n+SOFTWARE.\n",
    "collapsed": false,
    "too_large": false,
    "new_file": true,
    "renamed_file": false,
    "deleted_file": false,
    "generated_file": false
  }]
}
```

## Définir une estimation de temps pour un merge request {#set-a-time-estimate-for-a-merge-request}

Définit un temps de travail estimé pour ce merge request.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/time_estimate
```

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'ID interne du merge request. |
| `duration`          | string            | Oui      | La durée au format humain, par exemple `3h30m`. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/time_estimate?duration=3h30m"
```

Exemple de réponse :

```json
{
  "human_time_estimate": "3h 30m",
  "human_total_time_spent": null,
  "time_estimate": 12600,
  "total_time_spent": 0
}
```

## Réinitialiser l'estimation de temps pour un merge request {#reset-the-time-estimate-for-a-merge-request}

Réinitialise le temps estimé pour ce merge request à 0 seconde.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/reset_time_estimate
```

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'ID interne du merge request d'un projet. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/reset_time_estimate"
```

Exemple de réponse :

```json
{
  "human_time_estimate": null,
  "human_total_time_spent": null,
  "time_estimate": 0,
  "total_time_spent": 0
}
```

## Ajouter du temps passé pour un merge request {#add-spent-time-for-a-merge-request}

Ajoute du temps passé pour ce merge request.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/add_spent_time
```

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'ID interne du merge request. |
| `duration`          | string            | Oui      | La durée au format humain, par exemple `3h30m` |
| `summary`           | string            | Non       | Un résumé de la façon dont le temps a été utilisé. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/add_spent_time?duration=1h"
```

Exemple de réponse :

```json
{
  "human_time_estimate": null,
  "human_total_time_spent": "1h",
  "time_estimate": 0,
  "total_time_spent": 3600
}
```

## Réinitialiser le temps passé pour un merge request {#reset-spent-time-for-a-merge-request}

Réinitialise le temps total passé pour ce merge request à 0 seconde.

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/reset_spent_time
```

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'ID interne du merge request d'un projet. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/reset_spent_time"
```

Exemple de réponse :

```json
{
  "human_time_estimate": null,
  "human_total_time_spent": null,
  "time_estimate": 0,
  "total_time_spent": 0
}
```

## Récupérer les statistiques de suivi du temps {#retrieve-time-tracking-statistics}

Récupérer les statistiques de suivi du temps pour un merge request.

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/time_stats
```

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `merge_request_iid` | entier           | Oui      | L'ID interne du merge request. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/merge_requests/93/time_stats"
```

Exemple de réponse :

```json
{
  "human_time_estimate": "2h",
  "human_total_time_spent": "1h",
  "time_estimate": 7200,
  "total_time_spent": 3600
}
```

## Approbations {#approvals}

Pour les approbations, voir [les approbations de merge requests](merge_request_approvals.md).

## Lister les événements d'état des merge requests {#list-merge-request-state-events}

Pour savoir quel état a été défini, qui l'a fait et quand, consultez l'[API des événements d'état des ressources](resource_state_events.md#merge-requests).

## Dépannage {#troubleshooting}

### Champs API vides pour les nouveaux merge requests {#empty-api-fields-for-new-merge-requests}

Lorsque vous créez un merge request, les champs `diff_refs` et `changes_count` sont initialement vides. Ces champs sont remplis de manière asynchrone après la création du merge request. Pour plus d'informations, voir [le ticket 386562](https://gitlab.com/gitlab-org/gitlab/-/issues/386562) et la [discussion associée](https://forum.gitlab.com/t/diff-refs-empty-after-mr-is-created/78975) dans les forums GitLab.
