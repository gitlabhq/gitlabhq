---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation pour l'API REST dédiée aux tickets dans GitLab."
title: API Issues
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [tickets](../user/project/issues/_index.md). Vous pouvez :

- Créer, mettre à jour et supprimer des tickets.
- Gérer les métadonnées des tickets, comme les assignés, les labels, les jalons et le suivi du temps.
- Référencer de manière croisée les tickets et les merge requests.
- Suivre le déplacement et la promotion des tickets entre projets et epics.
- Contrôler l'accès et la visibilité grâce aux vérifications d'autorisation.

Si un utilisateur n'est pas membre d'un projet privé, une requête `GET` sur ce projet entraîne un code de statut `404`.

Les réponses de cette API sont [paginées](rest/_index.md#pagination) et renvoient 20 résultats par défaut.

> [!note]
> L'attribut `references.relative` est relatif au groupe ou au projet du ticket demandé. Lorsqu'un ticket est récupéré depuis son projet, le format `relative` est identique au format `short`. Lorsqu'il est demandé entre des groupes ou des projets, il est censé être identique au format `full`.

## Lister tous les tickets {#list-all-issues}

Liste tous les tickets auxquels l'utilisateur authentifié a accès. Par défaut, renvoie uniquement les tickets créés par l'utilisateur actuel. Pour lister tous les tickets, utilisez le paramètre `scope=all`.

```plaintext
GET /issues
GET /issues?assignee_id=5
GET /issues?author_id=5
GET /issues?confidential=true
GET /issues?iids[]=42&iids[]=43
GET /issues?labels=foo
GET /issues?labels=foo,bar
GET /issues?labels=foo,bar&state=opened
GET /issues?milestone=1.0.0
GET /issues?milestone=1.0.0&state=opened
GET /issues?my_reaction_emoji=star
GET /issues?search=foo&in=title
GET /issues?state=closed
GET /issues?state=opened
```

Attributs pris en charge :

| Attribut                       | Type          | Obligatoire   | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
|---------------------------------|---------------| ---------- |------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `assignee_id`                   | integer       | Non         | Renvoie les tickets assignés à l'utilisateur donné via son `id`. Mutuellement exclusif avec `assignee_username`. `None` renvoie les tickets non assignés. `Any` renvoie les tickets avec un assigné.                                                                                                                                                                                                                                                                                                                                                                                                   |
| `assignee_username`             | tableau de chaînes  | Non         | Renvoie les tickets assignés au `username` donné. Similaire à `assignee_id` et mutuellement exclusif avec `assignee_id`. Dans GitLab CE, le tableau `assignee_username` ne doit contenir qu'une seule valeur. Sinon, une erreur de paramètre invalide est renvoyée. Seuls les tickets assignés à tous les utilisateurs transmis sont renvoyés. |
| `author_id`                     | integer       | Non         | Renvoie les tickets créés par l'utilisateur donné via son `id`. Mutuellement exclusif avec `author_username`. À combiner avec `scope=all` ou `scope=assigned_to_me`.                                                                                                                                                                                                                                                                                                                                                                                                                           |
| `author_username`               | string        | Non         | Renvoie les tickets créés par le `username` donné. Similaire à `author_id` et mutuellement exclusif avec `author_id`.                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `confidential`                  | boolean       | Non         | Filtre les tickets confidentiels ou publics.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| `created_after`                 | datetime      | Non         | Renvoie les tickets créés à partir de la date donnée (incluse). Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`).                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| `created_before`                | datetime      | Non         | Renvoie les tickets créés jusqu'à la date donnée (incluse). Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`).                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `due_date`                      | string        | Non         | Renvoie les tickets sans date d'échéance, en retard, ou dont la date d'échéance est cette semaine, ce mois-ci, ou entre il y a deux semaines et le mois prochain. Accepte : `0` (pas de date d'échéance), `any`, `today`, `tomorrow`, `overdue`, `week`, `month`, `next_month_and_previous_two_weeks`.                                                                                                                                                                                                                                                                                                        |
| `epic_id`        | integer       | Non         | Renvoie les tickets associés à l'ID d'epic donné. `None` renvoie les tickets non associés à un epic. `Any` renvoie les tickets associés à un epic. Premium et Ultimate uniquement.                                                                                                                                                                                                                                                                                                                                                                         |
| `health_status`  | string        | Non         | Renvoie les tickets avec le `health_status` spécifié. _([Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/370721) dans GitLab 15.4)._ Dans [GitLab 15.5 et versions ultérieures](https://gitlab.com/gitlab-org/gitlab/-/issues/370721), `None` renvoie les tickets sans état de santé assigné, et `Any` renvoie les tickets avec un état de santé assigné. Ultimate uniquement.                                                                                                                                                                                                                |
| `iids[]`                        | tableau d'entiers | Non         | Renvoie uniquement les tickets ayant l'`iid` donné.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `in`                            | string        | Non         | Modifie la portée de l'attribut `search`. `title`, `description`, ou une chaîne les combinant avec une virgule. La valeur par défaut est `title,description`.                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `issue_type`                    | string        | Non         | Filtre selon un type de ticket donné. L'un des suivants : `issue`, `incident`, `test_case` ou `task`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| `iteration_id`                  | integer       | Non         | Renvoie les tickets assignés à l'ID d'itération donné. `None` renvoie les tickets n'appartenant pas à une itération. `Any` renvoie les tickets appartenant à une itération. Mutuellement exclusif avec `iteration_title`. Premium et Ultimate uniquement.                                                                                                                                                                                                                                                                                                                                    |
| `iteration_title`               | string        | Non       | Renvoie les tickets assignés à l'itération avec le titre donné. Similaire à `iteration_id` et mutuellement exclusif avec `iteration_id`. Premium et Ultimate uniquement.                                                                                                                                                                                                                                                                                                                                                                                                         |
| `labels`                        | string        | Non         | Liste de noms de labels séparés par des virgules ; les tickets doivent avoir tous les labels pour être renvoyés. `None` liste tous les tickets sans label. `Any` liste tous les tickets avec au moins un label. `No+Label` (Déprécié) liste tous les tickets sans label. Les noms prédéfinis ne sont pas sensibles à la casse.                                                                                                                                                                                                                                                                                               |
| `milestone_id`                  | string        | Non         | Renvoie les tickets assignés aux jalons avec une valeur de plage de temps donnée (`None`, `Any`, `Upcoming` et `Started`). `None` liste tous les tickets sans jalon. `Any` liste tous les tickets ayant un jalon assigné. `Upcoming` liste tous les tickets assignés aux jalons à venir. `Started` liste tous les tickets assignés aux jalons ouverts et démarrés. La logique pour `Upcoming` et `Started` diffère de celle utilisée dans l'[API GraphQL](../user/project/milestones/_index.md#special-milestone-filters). `milestone` et `milestone_id` sont mutuellement exclusifs. |
| `milestone`                     | string        | Non         | Le titre du jalon. `None` liste tous les tickets sans jalon. `Any` liste tous les tickets ayant un jalon assigné. L'utilisation de `None` ou `Any` sera [dépréciée dans le futur](https://gitlab.com/gitlab-org/gitlab/-/issues/336044). Utilisez plutôt l'attribut `milestone_id`. `milestone` et `milestone_id` sont mutuellement exclusifs.                                                                                                                                                                                                                                   |
| `my_reaction_emoji`             | string        | Non         | Renvoie les tickets auxquels l'utilisateur authentifié a réagi avec l'`emoji` donné. `None` renvoie les tickets sans réaction. `Any` renvoie les tickets avec au moins une réaction.                                                                                                                                                                                                                                                                                                                                                                                                    |
| `non_archived`                  | boolean       | Non         | Renvoie les tickets uniquement des projets non archivés. Si `false`, la réponse renvoie les tickets des projets archivés et non archivés. La valeur par défaut est `true`.                                                                                                                                                                                                                                                                                                                                                                                                                |
| `not`                           | Hash          | Non         | Renvoie les tickets ne correspondant pas aux paramètres fournis. Accepte : `assignee_id`, `assignee_username`, `author_id`, `author_username`, `iids`, `iteration_id`, `iteration_title`, `labels`, `milestone`, `milestone_id` et `weight`.                                                                                                                                                                                                                                                                                                                                   |
| `order_by`                      | string        | Non         | Renvoie les tickets triés par les champs `created_at`, `due_date`, `label_priority`, `milestone_due`, `popularity`, `priority`, `relative_position`, `title`, `updated_at` ou `weight`. La valeur par défaut est `created_at`.                                                                                                                                                                                                                                                                                                                                                               |
| `scope`                         | string        | Non         | Renvoie les tickets pour la portée donnée : `created_by_me`, `assigned_to_me` ou `all`. La valeur par défaut est `created_by_me`.                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `search`                        | string        | Non         | Recherche des tickets d'après leur `title` et leur `description`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `sort`                          | string        | Non         | Renvoie les tickets triés dans l'ordre `asc` ou `desc`. La valeur par défaut est `desc`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `state`                         | string        | Non         | Renvoie `all` les tickets ou seulement ceux qui sont `opened` ou `closed`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| `updated_after`                 | datetime      | Non         | Renvoie les tickets mis à jour à partir de la date donnée (incluse). Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`).                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| `updated_before`                | datetime      | Non         | Renvoie les tickets mis à jour jusqu'à la date donnée (incluse). Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`).                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `weight`                        | integer       | Non         | Renvoie les tickets avec le poids `weight` spécifié. `None` renvoie les tickets sans poids assigné. `Any` renvoie les tickets avec un poids assigné. Premium et Ultimate uniquement.                                                                                                                                                                                                                                                                                                                                                                                                      |
| `with_labels_details`           | boolean       | Non         | Si `true`, la réponse renvoie plus de détails pour chaque label dans le champ labels : `:name`, `:color`, `:description`, `:description_html`, `:text_color`. La valeur par défaut est `false`.                                                                                                                                                                                                                                                                                                                                                                                                |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/issues"
```

Exemple de réponse :

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
      "assignees" : [{
         "state" : "active",
         "id" : 1,
         "name" : "Administrator",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root"
      }],
      "assignee" : {
         "state" : "active",
         "id" : 1,
         "name" : "Administrator",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root"
      },
      "type" : "ISSUE",
      "updated_at" : "2016-01-04T15:31:51.081Z",
      "closed_at" : null,
      "closed_by" : null,
      "id" : 76,
      "title" : "Consequatur vero maxime deserunt laboriosam est voluptas dolorem.",
      "created_at" : "2016-01-04T15:31:51.081Z",
      "moved_to_id" : null,
      "iid" : 6,
      "labels" : ["foo", "bar"],
      "upvotes": 4,
      "downvotes": 0,
      "merge_requests_count": 0,
      "user_notes_count": 1,
      "start_date": null,
      "due_date": "2016-07-22",
      "imported":false,
      "imported_from": "none",
      "web_url": "http://gitlab.example.com/my-group/my-project/issues/6",
      "references": {
        "short": "#6",
        "relative": "my-group/my-project#6",
        "full": "my-group/my-project#6"
      },
      "time_stats": {
         "time_estimate": 0,
         "total_time_spent": 0,
         "human_time_estimate": null,
         "human_total_time_spent": null
      },
      "has_tasks": true,
      "task_status": "10 of 15 tasks completed",
      "confidential": false,
      "discussion_locked": false,
      "issue_type": "issue",
      "severity": "UNKNOWN",
      "_links":{
         "self":"http://gitlab.example.com/api/v4/projects/1/issues/76",
         "notes":"http://gitlab.example.com/api/v4/projects/1/issues/76/notes",
         "award_emoji":"http://gitlab.example.com/api/v4/projects/1/issues/76/award_emoji",
         "project":"http://gitlab.example.com/api/v4/projects/1",
         "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
      },
      "task_completion_status":{
         "count":0,
         "completed_count":0
      }
   }
]
```

Les tickets créés par des utilisateurs sur GitLab Premium ou Ultimate incluent la propriété `weight` :

```json
[
   {
      "state" : "opened",
      "description" : "Ratione dolores corrupti mollitia soluta quia.",
      "weight": null,
      ...
   }
]
```

Les tickets créés par des utilisateurs sur GitLab Premium ou Ultimate incluent la propriété `epic` :

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

Les tickets créés par des utilisateurs sur GitLab Premium ou Ultimate incluent la propriété `iteration` :

```json
{
   "iteration": {
      "id":90,
      "iid":4,
      "sequence":2,
      "group_id":162,
      "title":null,
      "description":null,
      "state":2,
      "created_at":"2022-03-14T05:21:11.929Z",
      "updated_at":"2022-03-14T05:21:11.929Z",
      "start_date":"2022-03-08",
      "due_date":"2022-03-14",
      "web_url":"https://gitlab.com/groups/my-group/-/iterations/90"
   }
   ...
}
```

Les tickets créés par des utilisateurs sur GitLab Ultimate incluent la propriété `health_status` :

```json
[
   {
      "state" : "opened",
      "description" : "Ratione dolores corrupti mollitia soluta quia.",
      "health_status": "on_track",
      ...
   }
]
```

> [!warning]
> La colonne `assignee` est dépréciée. Nous l'affichons désormais comme un tableau à un seul élément `assignees` pour être conforme à l'API GitLab EE.
>
> L'attribut `epic_iid` est déprécié et [programmé pour suppression](https://gitlab.com/gitlab-org/gitlab/-/issues/35157) dans la version 5 de l'API. Utilisez plutôt `iid` de l'attribut `epic`.

## Lister tous les tickets de groupe {#list-all-group-issues}

Liste tous les tickets d'un groupe spécifié.

Si le groupe est privé, vous devez fournir des identifiants pour vous authentifier. La méthode recommandée consiste à utiliser des [jetons d'accès personnels](../user/profile/personal_access_tokens.md).

```plaintext
GET /groups/:id/issues
GET /groups/:id/issues?assignee_id=5
GET /groups/:id/issues?author_id=5
GET /groups/:id/issues?confidential=true
GET /groups/:id/issues?iids[]=42&iids[]=43
GET /groups/:id/issues?labels=foo
GET /groups/:id/issues?labels=foo,bar
GET /groups/:id/issues?labels=foo,bar&state=opened
GET /groups/:id/issues?milestone=1.0.0
GET /groups/:id/issues?milestone=1.0.0&state=opened
GET /groups/:id/issues?my_reaction_emoji=star
GET /groups/:id/issues?search=issue+title+or+description
GET /groups/:id/issues?state=closed
GET /groups/:id/issues?state=opened
```

Attributs pris en charge :

| Attribut           | Type             | Obligatoire   | Description                                                                                                                   |
| ------------------- | ---------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `id`                | integer ou string   | Oui        | L'ID global ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe.                 |
| `assignee_id`       | integer          | Non         | Renvoie les tickets assignés à l'utilisateur donné via son `id`. Mutuellement exclusif avec `assignee_username`. `None` renvoie les tickets non assignés. `Any` renvoie les tickets avec un assigné. |
| `assignee_username` | tableau de chaînes     | Non         | Renvoie les tickets assignés au `username` donné. Similaire à `assignee_id` et mutuellement exclusif avec `assignee_id`. Dans GitLab CE, le tableau `assignee_username` ne doit contenir qu'une seule valeur. Sinon, une erreur de paramètre invalide est renvoyée. Seuls les tickets assignés à tous les utilisateurs transmis sont renvoyés. |
| `author_id`         | integer          | Non         | Renvoie les tickets créés par l'utilisateur donné via son `id`. Mutuellement exclusif avec `author_username`. À combiner avec `scope=all` ou `scope=assigned_to_me`. |
| `author_username`   | string           | Non         | Renvoie les tickets créés par le `username` donné. Similaire à `author_id` et mutuellement exclusif avec `author_id`. |
| `confidential`     | boolean          | Non         | Filtre les tickets confidentiels ou publics.                                                                                         |
| `created_after`     | datetime         | Non         | Renvoie les tickets créés à partir de la date donnée (incluse). Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `created_before`    | datetime         | Non         | Renvoie les tickets créés jusqu'à la date donnée (incluse). Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `due_date`          | string           | Non         | Renvoie les tickets sans date d'échéance, en retard, ou dont la date d'échéance est cette semaine, ce mois-ci, ou entre il y a deux semaines et le mois prochain. Accepte : `0` (pas de date d'échéance), `any`, `today`, `tomorrow`, `overdue`, `week`, `month`, `next_month_and_previous_two_weeks`. |
| `epic_id`           | integer      | Non         | Renvoie les tickets associés à l'ID d'epic donné. `None` renvoie les tickets non associés à un epic. `Any` renvoie les tickets associés à un epic. Premium et Ultimate uniquement. |
| `iids[]`            | tableau d'entiers    | Non         | Renvoie uniquement les tickets ayant l'`iid` donné.                                                                                 |
| `issue_type`        | string           | Non         | Filtre selon un type de ticket donné. L'un des suivants : `issue`, `incident`, `test_case` ou `task`. |
| `iteration_id`      | integer | Non         | Renvoie les tickets assignés à l'ID d'itération donné. `None` renvoie les tickets n'appartenant pas à une itération. `Any` renvoie les tickets appartenant à une itération. Mutuellement exclusif avec `iteration_title`. Premium et Ultimate uniquement. |
| `iteration_title`   | string | Non       | Renvoie les tickets assignés à l'itération avec le titre donné. Similaire à `iteration_id` et mutuellement exclusif avec `iteration_id`. Premium et Ultimate uniquement.|
| `labels`            | string           | Non         | Liste de noms de labels séparés par des virgules ; les tickets doivent avoir tous les labels pour être renvoyés. `None` liste tous les tickets sans label. `Any` liste tous les tickets avec au moins un label. `No+Label` (Déprécié) liste tous les tickets sans label. Les noms prédéfinis ne sont pas sensibles à la casse. |
| `milestone`         | string           | Non         | Le titre du jalon. `None` liste tous les tickets sans jalon. `Any` liste tous les tickets ayant un jalon assigné.       |
| `my_reaction_emoji` | string           | Non         | Renvoie les tickets auxquels l'utilisateur authentifié a réagi avec l'`emoji` donné. `None` renvoie les tickets sans réaction. `Any` renvoie les tickets avec au moins une réaction. |
| `non_archived`      | boolean          | Non         | Renvoie les tickets des projets non archivés. La valeur par défaut est true. |
| `not`               | Hash             | Non         | Renvoie les tickets ne correspondant pas aux paramètres fournis. Accepte : `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `my_reaction_emoji`, `search`, `in`. |
| `order_by`          | string           | Non         | Renvoie les tickets triés par les champs `created_at`, `updated_at`, `priority`, `due_date`, `relative_position`, `label_priority`, `milestone_due`, `popularity`, `weight`. La valeur par défaut est `created_at`                                                               |
| `scope`             | string           | Non         | Renvoie les tickets pour la portée donnée : `created_by_me`, `assigned_to_me` ou `all`. La valeur par défaut est `all`. |
| `search`            | string           | Non         | Recherche des tickets de groupe d'après leur `title` et leur `description`.                                                                   |
| `sort`              | string           | Non         | Renvoie les tickets triés dans l'ordre `asc` ou `desc`. La valeur par défaut est `desc`.                                                              |
| `state`             | string           | Non         | Renvoie tous les tickets ou seulement ceux qui sont `opened` ou `closed`.                                                                 |
| `updated_after`     | datetime         | Non         | Renvoie les tickets mis à jour à partir de la date donnée (incluse). Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `updated_before`    | datetime         | Non         | Renvoie les tickets mis à jour jusqu'à la date donnée (incluse). Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `weight` | integer       | Non         | Renvoie les tickets avec le poids `weight` spécifié. `None` renvoie les tickets sans poids assigné. `Any` renvoie les tickets avec un poids assigné. Premium et Ultimate uniquement. |
| `with_labels_details` | boolean        | Non         | Si `true`, la réponse renvoie plus de détails pour chaque label dans le champ labels : `:name`, `:color`, `:description`, `:description_html`, `:text_color`. La valeur par défaut est `false`. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/4/issues"
```

Exemple de réponse :

```json
[
   {
      "project_id" : 4,
      "milestone" : {
         "due_date" : null,
         "project_id" : 4,
         "state" : "closed",
         "description" : "Rerum est voluptatem provident consequuntur molestias similique ipsum dolor.",
         "iid" : 3,
         "id" : 11,
         "title" : "v3.0",
         "created_at" : "2016-01-04T15:31:39.788Z",
         "updated_at" : "2016-01-04T15:31:39.788Z"
      },
      "author" : {
         "state" : "active",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root",
         "id" : 1,
         "name" : "Administrator"
      },
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "state" : "closed",
      "iid" : 1,
      "assignees" : [{
         "avatar_url" : null,
         "web_url" : "https://gitlab.example.com/lennie",
         "state" : "active",
         "username" : "lennie",
         "id" : 9,
         "name" : "Dr. Luella Kovacek"
      }],
      "assignee" : {
         "avatar_url" : null,
         "web_url" : "https://gitlab.example.com/lennie",
         "state" : "active",
         "username" : "lennie",
         "id" : 9,
         "name" : "Dr. Luella Kovacek"
      },
      "type" : "ISSUE",
      "labels" : ["foo", "bar"],
      "upvotes": 4,
      "downvotes": 0,
      "merge_requests_count": 0,
      "id" : 41,
      "title" : "Ut commodi ullam eos dolores perferendis nihil sunt.",
      "updated_at" : "2016-01-04T15:31:46.176Z",
      "created_at" : "2016-01-04T15:31:46.176Z",
      "closed_at" : null,
      "closed_by" : null,
      "user_notes_count": 1,
      "due_date": null,
      "imported": false,
      "imported_from": "none",
      "web_url": "http://gitlab.example.com/my-group/my-project/issues/1",
      "references": {
        "short": "#1",
        "relative": "my-project#1",
        "full": "my-group/my-project#1"
      },
      "time_stats": {
         "time_estimate": 0,
         "total_time_spent": 0,
         "human_time_estimate": null,
         "human_total_time_spent": null
      },
      "has_tasks": true,
      "task_status": "10 of 15 tasks completed",
      "confidential": false,
      "discussion_locked": false,
      "issue_type": "issue",
      "severity": "UNKNOWN",
      "_links":{
         "self":"http://gitlab.example.com/api/v4/projects/4/issues/41",
         "notes":"http://gitlab.example.com/api/v4/projects/4/issues/41/notes",
         "award_emoji":"http://gitlab.example.com/api/v4/projects/4/issues/41/award_emoji",
         "project":"http://gitlab.example.com/api/v4/projects/4",
         "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
      },
      "task_completion_status":{
         "count":0,
         "completed_count":0
      }
   }
]
```

Les tickets créés par des utilisateurs sur GitLab Premium ou Ultimate incluent la propriété `weight` :

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "weight": null,
      ...
   }
]
```

Les tickets créés par des utilisateurs sur GitLab Premium ou Ultimate incluent la propriété `epic` :

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

Les tickets créés par des utilisateurs sur GitLab Ultimate incluent la propriété `health_status` :

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "at_risk",
      ...
   }
]
```

> [!warning]
> La colonne `assignee` est dépréciée. Nous l'affichons désormais comme un tableau à un seul élément `assignees` pour être conforme à l'API GitLab EE.
>
> L'attribut `epic_iid` est déprécié et [programmé pour suppression](https://gitlab.com/gitlab-org/gitlab/-/issues/35157) dans la version 5 de l'API. Utilisez plutôt `iid` de l'attribut `epic`.

## Lister tous les tickets de projet {#list-all-project-issues}

{{< history >}}

- Prise en charge de la pagination par jeu de clés introduite dans GitLab 18.3.

{{< /history >}}

Liste tous les tickets d'un projet spécifié.

Si le projet est privé, vous devez fournir des identifiants pour vous authentifier. La méthode recommandée consiste à utiliser des [jetons d'accès personnels](../user/profile/personal_access_tokens.md).

```plaintext
GET /projects/:id/issues
GET /projects/:id/issues?assignee_id=5
GET /projects/:id/issues?author_id=5
GET /projects/:id/issues?confidential=true
GET /projects/:id/issues?iids[]=42&iids[]=43
GET /projects/:id/issues?labels=foo
GET /projects/:id/issues?labels=foo,bar
GET /projects/:id/issues?labels=foo,bar&state=opened
GET /projects/:id/issues?milestone=1.0.0
GET /projects/:id/issues?milestone=1.0.0&state=opened
GET /projects/:id/issues?my_reaction_emoji=star
GET /projects/:id/issues?search=issue+title+or+description
GET /projects/:id/issues?state=closed
GET /projects/:id/issues?state=opened
```

Attributs pris en charge :

| Attribut             | Type           | Obligatoire | Description |
| --------------------- | -------------- | -------- | ----------- |
| `id`                  | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `assignee_id`         | integer        | Non       | Renvoie les tickets assignés à l'utilisateur donné via son `id`. Mutuellement exclusif avec `assignee_username`. `None` renvoie les tickets non assignés. `Any` renvoie les tickets avec un assigné. |
| `assignee_username`   | tableau de chaînes   | Non       | Renvoie les tickets assignés au `username` donné. Similaire à `assignee_id` et mutuellement exclusif avec `assignee_id`. Dans GitLab CE, le tableau `assignee_username` ne doit contenir qu'une seule valeur. Sinon, une erreur de paramètre invalide est renvoyée. Seuls les tickets assignés à tous les utilisateurs transmis sont renvoyés. |
| `author_id`           | integer        | Non       | Renvoie les tickets créés par l'utilisateur donné via son `id`. Mutuellement exclusif avec `author_username`. À combiner avec `scope=all` ou `scope=assigned_to_me`. |
| `author_username`     | string         | Non       | Renvoie les tickets créés par le `username` donné. Similaire à `author_id` et mutuellement exclusif avec `author_id`. |
| `confidential`        | boolean        | Non       | Filtre les tickets confidentiels ou publics. |
| `created_after`       | datetime       | Non       | Renvoie les tickets créés à partir de la date donnée (incluse). Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `created_before`      | datetime       | Non       | Renvoie les tickets créés jusqu'à la date donnée (incluse). Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `due_date`            | string         | Non       | Renvoie les tickets sans date d'échéance, en retard, ou dont la date d'échéance est cette semaine, ce mois-ci, ou entre il y a deux semaines et le mois prochain. Accepte : `0` (pas de date d'échéance), `any`, `today`, `tomorrow`, `overdue`, `week`, `month`, `next_month_and_previous_two_weeks`. |
| `epic_id`             | integer        | Non       | Renvoie les tickets associés à l'ID d'epic donné. `None` renvoie les tickets non associés à un epic. `Any` renvoie les tickets associés à un epic. Premium et Ultimate uniquement. |
| `iids[]`              | tableau d'entiers  | Non       | Renvoie uniquement les tickets ayant l'`iid` donné. |
| `issue_type`          | string         | Non       | Filtre selon un type de ticket donné. L'un des suivants : `issue`, `incident`, `test_case` ou `task`. |
| `iteration_id`        | integer        | Non       | Renvoie les tickets assignés à l'ID d'itération donné. `None` renvoie les tickets n'appartenant pas à une itération. `Any` renvoie les tickets appartenant à une itération. Mutuellement exclusif avec `iteration_title`. Premium et Ultimate uniquement. |
| `iteration_title`     | string         | Non       | Renvoie les tickets assignés à l'itération avec le titre donné. Similaire à `iteration_id` et mutuellement exclusif avec `iteration_id`. Premium et Ultimate uniquement. |
| `labels`              | string         | Non       | Liste de noms de labels séparés par des virgules ; les tickets doivent avoir tous les labels pour être renvoyés. `None` liste tous les tickets sans label. `Any` liste tous les tickets avec au moins un label. `No+Label` (Déprécié) liste tous les tickets sans label. Les noms prédéfinis ne sont pas sensibles à la casse. |
| `milestone`           | string         | Non       | Le titre du jalon. `None` liste tous les tickets sans jalon. `Any` liste tous les tickets ayant un jalon assigné. |
| `my_reaction_emoji`   | string         | Non       | Renvoie les tickets auxquels l'utilisateur authentifié a réagi avec l'`emoji` donné. `None` renvoie les tickets sans réaction. `Any` renvoie les tickets avec au moins une réaction. |
| `not`                 | Hash           | Non       | Renvoie les tickets ne correspondant pas aux paramètres fournis. Accepte : `labels`, `milestone`, `author_id`, `author_username`, `assignee_id`, `assignee_username`, `my_reaction_emoji`, `search`, `in`. |
| `order_by`            | string         | Non       | Renvoie les tickets triés par les champs `created_at`, `updated_at`, `priority`, `due_date`, `relative_position`, `label_priority`, `milestone_due`, `popularity`, `weight`. La valeur par défaut est `created_at`. |
| `scope`               | string         | Non       | Renvoie les tickets pour la portée donnée : `created_by_me`, `assigned_to_me` ou `all`. La valeur par défaut est `all`. |
| `search`              | string         | Non       | Recherche des tickets de projet d'après leur `title` et leur `description`. |
| `sort`                | string         | Non       | Renvoie les tickets triés dans l'ordre `asc` ou `desc`. La valeur par défaut est `desc`. |
| `state`               | string         | Non       | Renvoie tous les tickets ou seulement ceux qui sont `opened` ou `closed`. |
| `updated_after`       | datetime       | Non       | Renvoie les tickets mis à jour à partir de la date donnée (incluse). Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `updated_before`      | datetime       | Non       | Renvoie les tickets mis à jour jusqu'à la date donnée (incluse). Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). |
| `weight`              | integer        | Non       | Renvoie les tickets avec le poids `weight` spécifié. `None` renvoie les tickets sans poids assigné. `Any` renvoie les tickets avec un poids assigné. Premium et Ultimate uniquement. |
| `with_labels_details` | boolean        | Non       | Si `true`, la réponse renvoie plus de détails pour chaque label dans le champ labels : `:name`, `:color`, `:description`, `:description_html`, `:text_color`. La valeur par défaut est `false`. |
| `cursor`              | string         | Non       | Paramètre utilisé dans la pagination par jeu de clés. |

Cet endpoint prend en charge la pagination basée sur un offset et la pagination [basée sur un jeu de clés](rest/_index.md#keyset-based-pagination). Vous devriez utiliser la pagination basée sur un jeu de clés lorsque vous demandez des pages de résultats consécutives.

En savoir plus sur la [pagination](rest/_index.md#pagination).

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues"
```

Exemple de réponse :

```json
[
   {
      "project_id" : 4,
      "milestone" : {
         "due_date" : null,
         "project_id" : 4,
         "state" : "closed",
         "description" : "Rerum est voluptatem provident consequuntur molestias similique ipsum dolor.",
         "iid" : 3,
         "id" : 11,
         "title" : "v3.0",
         "created_at" : "2016-01-04T15:31:39.788Z",
         "updated_at" : "2016-01-04T15:31:39.788Z"
      },
      "author" : {
         "state" : "active",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root",
         "id" : 1,
         "name" : "Administrator"
      },
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "state" : "closed",
      "iid" : 1,
      "assignees" : [{
         "avatar_url" : null,
         "web_url" : "https://gitlab.example.com/lennie",
         "state" : "active",
         "username" : "lennie",
         "id" : 9,
         "name" : "Dr. Luella Kovacek"
      }],
      "assignee" : {
         "avatar_url" : null,
         "web_url" : "https://gitlab.example.com/lennie",
         "state" : "active",
         "username" : "lennie",
         "id" : 9,
         "name" : "Dr. Luella Kovacek"
      },
      "type" : "ISSUE",
      "labels" : ["foo", "bar"],
      "upvotes": 4,
      "downvotes": 0,
      "merge_requests_count": 0,
      "id" : 41,
      "title" : "Ut commodi ullam eos dolores perferendis nihil sunt.",
      "updated_at" : "2016-01-04T15:31:46.176Z",
      "created_at" : "2016-01-04T15:31:46.176Z",
      "closed_at" : "2016-01-05T15:31:46.176Z",
      "closed_by" : {
         "state" : "active",
         "web_url" : "https://gitlab.example.com/root",
         "avatar_url" : null,
         "username" : "root",
         "id" : 1,
         "name" : "Administrator"
      },
      "user_notes_count": 1,
      "due_date": "2016-07-22",
      "imported": false,
      "imported_from": "none",
      "web_url": "http://gitlab.example.com/my-group/my-project/issues/1",
      "references": {
        "short": "#1",
        "relative": "#1",
        "full": "my-group/my-project#1"
      },
      "time_stats": {
         "time_estimate": 0,
         "total_time_spent": 0,
         "human_time_estimate": null,
         "human_total_time_spent": null
      },
      "has_tasks": true,
      "task_status": "10 of 15 tasks completed",
      "confidential": false,
      "discussion_locked": false,
      "issue_type": "issue",
      "severity": "UNKNOWN",
      "_links":{
         "self":"http://gitlab.example.com/api/v4/projects/4/issues/41",
         "notes":"http://gitlab.example.com/api/v4/projects/4/issues/41/notes",
         "award_emoji":"http://gitlab.example.com/api/v4/projects/4/issues/41/award_emoji",
         "project":"http://gitlab.example.com/api/v4/projects/4",
         "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
      },
      "task_completion_status":{
         "count":0,
         "completed_count":0
      }
   }
]
```

Les tickets créés par des utilisateurs sur GitLab Premium ou Ultimate incluent la propriété `weight` :

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "weight": null,
      ...
   }
]
```

Les tickets créés par des utilisateurs sur GitLab Premium ou Ultimate incluent la propriété `epic` :

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

Les tickets créés par des utilisateurs sur GitLab Ultimate incluent la propriété `health_status` :

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "at_risk",
      ...
   }
]
```

> [!warning]
> La colonne `assignee` est dépréciée. Nous l'affichons désormais comme un tableau à un seul élément `assignees` pour être conforme à l'API GitLab EE.
>
> L'attribut `epic_iid` est déprécié et [programmé pour suppression](https://gitlab.com/gitlab-org/gitlab/-/issues/35157) dans la version 5 de l'API. Utilisez plutôt `iid` de l'attribut `epic`.

## Récupérer un ticket {#retrieve-an-issue}

Réservé aux administrateurs.

Récupère un ticket spécifié.

La méthode recommandée consiste à utiliser des [jetons d'accès personnels](../user/profile/personal_access_tokens.md).

```plaintext
GET /issues/:id
```

Attributs pris en charge :

| Attribut   | Type    | Obligatoire | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer | Oui      | L'ID du ticket.                 |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/issues/41"
```

Exemple de réponse :

```json
{
  "id": 1,
  "milestone": {
    "due_date": null,
    "project_id": 4,
    "state": "closed",
    "description": "Rerum est voluptatem provident consequuntur molestias similique ipsum dolor.",
    "iid": 3,
    "id": 11,
    "title": "v3.0",
    "created_at": "2016-01-04T15:31:39.788Z",
    "updated_at": "2016-01-04T15:31:39.788Z",
    "closed_at": "2016-01-05T15:31:46.176Z"
  },
  "author": {
    "state": "active",
    "web_url": "https://gitlab.example.com/root",
    "avatar_url": null,
    "username": "root",
    "id": 1,
    "name": "Administrator"
  },
  "description": "Omnis vero earum sunt corporis dolor et placeat.",
  "state": "closed",
  "iid": 1,
  "assignees": [
    {
      "avatar_url": null,
      "web_url": "https://gitlab.example.com/lennie",
      "state": "active",
      "username": "lennie",
      "id": 9,
      "name": "Dr. Luella Kovacek"
    }
  ],
  "assignee": {
    "avatar_url": null,
    "web_url": "https://gitlab.example.com/lennie",
    "state": "active",
    "username": "lennie",
    "id": 9,
    "name": "Dr. Luella Kovacek"
  },
  "type": "ISSUE",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "merge_requests_count": 0,
  "title": "Ut commodi ullam eos dolores perferendis nihil sunt.",
  "updated_at": "2016-01-04T15:31:46.176Z",
  "created_at": "2016-01-04T15:31:46.176Z",
  "closed_at": null,
  "closed_by": null,
  "subscribed": false,
  "user_notes_count": 1,
  "due_date": null,
  "imported": false,
  "imported_from": "none",
  "web_url": "http://example.com/my-group/my-project/issues/1",
  "references": {
    "short": "#1",
    "relative": "#1",
    "full": "my-group/my-project#1"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "confidential": false,
  "discussion_locked": false,
  "issue_type": "issue",
  "severity": "UNKNOWN",
  "task_completion_status": {
    "count": 0,
    "completed_count": 0
  },
  "weight": null,
  "has_tasks": false,
  "_links": {
    "self": "http://gitlab.example:3000/api/v4/projects/1/issues/1",
    "notes": "http://gitlab.example:3000/api/v4/projects/1/issues/1/notes",
    "award_emoji": "http://gitlab.example:3000/api/v4/projects/1/issues/1/award_emoji",
    "project": "http://gitlab.example:3000/api/v4/projects/1",
    "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
  },
  "moved_to_id": null,
  "service_desk_reply_to": "service.desk@gitlab.com"
}
```

Les tickets créés par des utilisateurs sur GitLab Premium ou Ultimate incluent la propriété `weight` :

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "weight": null,
   ...
}
```

Les tickets créés par des utilisateurs sur GitLab Premium ou Ultimate incluent la propriété `epic` :

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic": {
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

Les utilisateurs de [GitLab Ultimate](https://about.gitlab.com/pricing/) peuvent également voir la propriété `health_status` :

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

> [!warning]
> La colonne `assignee` est dépréciée. Nous l'affichons désormais comme un tableau à un seul élément `assignees` pour être conforme à l'API GitLab EE.
>
> L'attribut `epic_iid` est déprécié et [programmé pour suppression](https://gitlab.com/gitlab-org/gitlab/-/issues/35157) dans la version 5 de l'API. Utilisez plutôt `iid` de l'attribut `epic`.

## Récupérer un ticket de projet {#retrieve-a-project-issue}

Récupère un ticket spécifié pour un projet.

Si le projet est privé ou le ticket est confidentiel, vous devez fournir des identifiants pour vous authentifier. La méthode recommandée consiste à utiliser des [jetons d'accès personnels](../user/profile/personal_access_tokens.md).

```plaintext
GET /projects/:id/issues/:issue_iid
```

Attributs pris en charge :

| Attribut   | Type    | Obligatoire | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Oui      | L'ID interne du ticket d'un projet. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/41"
```

Exemple de réponse :

```json
{
   "project_id" : 4,
   "milestone" : {
      "due_date" : null,
      "project_id" : 4,
      "state" : "closed",
      "description" : "Rerum est voluptatem provident consequuntur molestias similique ipsum dolor.",
      "iid" : 3,
      "id" : 11,
      "title" : "v3.0",
      "created_at" : "2016-01-04T15:31:39.788Z",
      "updated_at" : "2016-01-04T15:31:39.788Z",
      "closed_at" : "2016-01-05T15:31:46.176Z"
   },
   "author" : {
      "state" : "active",
      "web_url" : "https://gitlab.example.com/root",
      "avatar_url" : null,
      "username" : "root",
      "id" : 1,
      "name" : "Administrator"
   },
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "state" : "closed",
   "iid" : 1,
   "assignees" : [{
      "avatar_url" : null,
      "web_url" : "https://gitlab.example.com/lennie",
      "state" : "active",
      "username" : "lennie",
      "id" : 9,
      "name" : "Dr. Luella Kovacek"
   }],
   "assignee" : {
      "avatar_url" : null,
      "web_url" : "https://gitlab.example.com/lennie",
      "state" : "active",
      "username" : "lennie",
      "id" : 9,
      "name" : "Dr. Luella Kovacek"
   },
   "type" : "ISSUE",
   "labels" : [],
   "upvotes": 4,
   "downvotes": 0,
   "merge_requests_count": 0,
   "id" : 41,
   "title" : "Ut commodi ullam eos dolores perferendis nihil sunt.",
   "updated_at" : "2016-01-04T15:31:46.176Z",
   "created_at" : "2016-01-04T15:31:46.176Z",
   "closed_at" : null,
   "closed_by" : null,
   "subscribed": false,
   "user_notes_count": 1,
   "due_date": null,
   "imported": false,
   "imported_from": "none",
   "web_url": "http://gitlab.example.com/my-group/my-project/issues/1",
   "references": {
     "short": "#1",
     "relative": "#1",
     "full": "my-group/my-project#1"
   },
   "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
   },
   "confidential": false,
   "discussion_locked": false,
   "issue_type": "issue",
   "severity": "UNKNOWN",
   "_links": {
      "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
      "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
      "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
      "project": "http://gitlab.example.com/api/v4/projects/1",
      "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
   },
   "task_completion_status":{
      "count":0,
      "completed_count":0
   }
}
```

Les tickets créés par des utilisateurs sur GitLab Premium ou Ultimate incluent la propriété `weight` :

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "weight": null,
   ...
}
```

Les tickets créés par des utilisateurs sur GitLab Premium ou Ultimate incluent la propriété `epic` :

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

Les utilisateurs de [GitLab Ultimate](https://about.gitlab.com/pricing/) peuvent également voir la propriété `health_status` :

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

> [!warning]
> La colonne `assignee` est dépréciée. Nous l'affichons désormais comme un tableau à un seul élément `assignees` pour être conforme à l'API GitLab EE.
>
> L'attribut `epic_iid` est déprécié et [programmé pour suppression](https://gitlab.com/gitlab-org/gitlab/-/issues/35157) dans la version 5 de l'API. Utilisez plutôt `iid` de l'attribut `epic`.

## Créer un ticket {#create-an-issue}

Crée un ticket pour un projet spécifié.

```plaintext
POST /projects/:id/issues
```

Attributs pris en charge :

| Attribut                                 | Type           | Obligatoire | Description  |
|-------------------------------------------|----------------|----------|--------------|
| `id`                                      | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `assignee_id`                             | integer        | Non       | L'ID de l'utilisateur à qui assigner le ticket. Disponible uniquement sur GitLab Free. |
| `assignee_ids`                            | tableau d'entiers  | Non       | Les IDs des utilisateurs à qui assigner le ticket. Premium et Ultimate uniquement.|
| `confidential`                            | boolean        | Non       | Définir un ticket comme confidentiel. La valeur par défaut est `false`.  |
| `created_at`                              | string         | Non       | Date de création du ticket. Chaîne de date/heure au format ISO 8601, par exemple `2016-03-11T03:45:40Z`. Nécessite des droits d'administrateur ou de propriétaire du projet/groupe. |
| `description`                             | string         | Non       | La description du ticket. Limité à 1 048 576 caractères. |
| `discussion_to_resolve`                   | string         | Non       | L'ID d'une discussion à résoudre. Ce champ préremprit le ticket avec une description par défaut et marque la discussion comme résolue. À utiliser en combinaison avec `merge_request_to_resolve_discussions_of`. |
| `due_date`                                | string         | Non       | La date d'échéance. Chaîne de date/heure au format `YYYY-MM-DD`, par exemple `2016-03-11`. |
| `epic_id`                                 | integer | Non | ID de l'epic auquel ajouter le ticket. Les valeurs valides sont supérieures ou égales à 0. Premium et Ultimate uniquement. |
| `epic_iid`                                | integer | Non | IID de l'epic auquel ajouter le ticket. Les valeurs valides sont supérieures ou égales à 0\. (déprécié, [programmé pour suppression](https://gitlab.com/gitlab-org/gitlab/-/issues/35157) dans la version 5 de l'API). Premium et Ultimate uniquement. |
| `iid`                                     | integer ou string | Non       | L'ID interne du ticket du projet (nécessite des droits d'administrateur ou de propriétaire du projet). |
| `issue_type`                              | string         | Non       | Le type de ticket. L'un des suivants : `issue`, `incident`, `test_case` ou `task`. La valeur par défaut est `issue`. |
| `labels`                                  | string         | Non       | Noms de labels séparés par des virgules à assigner au nouveau ticket. Si un label n'existe pas déjà, cela crée un nouveau label de projet et l'assigne au ticket.  |
| `merge_request_to_resolve_discussions_of` | integer        | Non       | L'IID d'une merge request dans laquelle résoudre tous les tickets. Ce champ préremprit le ticket avec une description par défaut et marque toutes les discussions comme résolues. Lorsqu'une description ou un titre est fourni, ces valeurs ont la priorité sur les valeurs par défaut.|
| `milestone_id`                            | integer        | Non       | L'ID global d'un jalon à assigner au ticket. Pour trouver le `milestone_id` associé à un jalon, consultez un ticket auquel le jalon est assigné et [utilisez l'API](#retrieve-a-project-issue) pour récupérer les détails du ticket. Mutuellement exclusif avec `milestone`. |
| `milestone`                               | string         | Non       | Le titre d'un jalon de projet ou de groupe ancêtre à assigner au ticket. Correspondance exacte (sensible à la casse). Mutuellement exclusif avec `milestone_id`. |
| `title`                                   | string         | Oui      | Le titre d'un ticket. |
| `weight`                                  | integer        | Non       | Le poids du ticket. Les valeurs valides sont supérieures ou égales à 0. Premium et Ultimate uniquement. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues?title=Issues%20with%20auth&labels=bug"
```

Exemple de réponse :

```json
{
   "project_id" : 4,
   "id" : 84,
   "created_at" : "2016-01-07T12:44:33.959Z",
   "iid" : 14,
   "title" : "Issues with auth",
   "state" : "opened",
   "assignees" : [],
   "assignee" : null,
   "type" : "ISSUE",
   "labels" : [
      "bug"
   ],
   "upvotes": 4,
   "downvotes": 0,
   "merge_requests_count": 0,
   "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe",
      "id" : 18,
      "username" : "eileen.lowe"
   },
   "description" : null,
   "updated_at" : "2016-01-07T12:44:33.959Z",
   "closed_at" : null,
   "closed_by" : null,
   "milestone" : null,
   "subscribed" : true,
   "user_notes_count": 0,
   "due_date": null,
   "web_url": "http://gitlab.example.com/my-group/my-project/issues/14",
   "references": {
     "short": "#14",
     "relative": "#14",
     "full": "my-group/my-project#14"
   },
   "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
   },
   "confidential": false,
   "discussion_locked": false,
   "issue_type": "issue",
   "severity": "UNKNOWN",
   "_links": {
      "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
      "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
      "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
      "project": "http://gitlab.example.com/api/v4/projects/1",
      "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
   },
   "task_completion_status":{
      "count":0,
      "completed_count":0
   }
}
```

Si le projet cible a **Tickets** [désactivé](../user/project/settings/_index.md#toggle-project-features), vous recevez la réponse `403`, ainsi que le message :

```json
{
   "message": "403 Forbidden"
}
```

Les tickets créés par des utilisateurs sur GitLab Premium ou Ultimate incluent la propriété `weight` :

```json
{
   "project_id" : 4,
   "description" : null,
   "weight": null,
   ...
}
```

Les tickets créés par des utilisateurs sur GitLab Premium ou Ultimate incluent la propriété `epic` :

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

Les tickets créés par des utilisateurs sur GitLab Ultimate incluent la propriété `health_status` :

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

> [!warning]
> La colonne `assignee` est dépréciée. Nous l'affichons désormais comme un tableau à un seul élément `assignees` pour être conforme à l'API GitLab EE.
>
> L'attribut `epic_iid` est déprécié et [programmé pour suppression](https://gitlab.com/gitlab-org/gitlab/-/issues/35157) dans la version 5 de l'API. Utilisez plutôt `iid` de l'attribut `epic`.

### Limites de débit {#rate-limits}

Pour aider à prévenir les abus, les utilisateurs peuvent être limités à un nombre spécifique de requêtes `Create` par minute. Pour plus d'informations, consultez les [limites de débit sur la création de tickets et d'epics](../administration/settings/rate_limit_on_issues_creation.md).

## Mettre à jour un ticket {#update-an-issue}

Met à jour un ticket spécifié pour un projet. Cette requête est également utilisée pour fermer ou rouvrir un ticket à l'aide du paramètre `state_event`

Au moins l'un des paramètres suivants est requis pour que la requête aboutisse :

- `:assignee_id`
- `:assignee_ids`
- `:confidential`
- `:created_at`
- `:description`
- `:discussion_locked`
- `:due_date`
- `:issue_type`
- `:labels`
- `:milestone_id`
- `:state_event`
- `:title`

```plaintext
PUT /projects/:id/issues/:issue_iid
```

Attributs pris en charge :

| Attribut      | Type    | Obligatoire | Description                                                                                                |
|----------------|---------|----------|------------------------------------------------------------------------------------------------------------|
| `id`           | integer ou string | Oui | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid`    | integer | Oui      | L'ID interne du ticket d'un projet.                                                                       |
| `add_labels`   | string  | Non       | Noms de labels séparés par des virgules à ajouter à un ticket. Si un label n'existe pas déjà, cela crée un nouveau label de projet et l'assigne au ticket. |
| `assignee_ids` | tableau d'entiers | Non | L'ID des utilisateurs à qui assigner le ticket. Définir à `0` ou fournir une valeur vide pour désassigner tous les assignés. |
| `confidential` | boolean | Non       | Met à jour un ticket pour le rendre confidentiel.                                                                        |
| `description`  | string  | Non       | La description du ticket. Limité à 1 048 576 caractères.        |
| `discussion_locked` | boolean | Non  | Indicateur signalant si la discussion du ticket est verrouillée. Si la discussion est verrouillée, seuls les membres du projet peuvent ajouter ou modifier des commentaires. |
| `due_date`     | string  | Non       | La date d'échéance. Chaîne de date/heure au format `YYYY-MM-DD`, par exemple `2016-03-11`.                                           |
| `epic_id`      | integer | Non | ID de l'epic auquel ajouter le ticket. Les valeurs valides sont supérieures ou égales à 0. Premium et Ultimate uniquement. |
| `epic_iid`     | integer | Non | IID de l'epic auquel ajouter le ticket. Les valeurs valides sont supérieures ou égales à 0\. (déprécié, [programmé pour suppression](https://gitlab.com/gitlab-org/gitlab/-/issues/35157) dans la version 5 de l'API). Premium et Ultimate uniquement. |
| `issue_type`   | string  | Non       | Met à jour le type de ticket. L'un des suivants : `issue`, `incident` ou `test_case`. |
| `labels`       | string  | Non       | Noms de labels séparés par des virgules pour un ticket. Définir sur une chaîne vide pour désassigner tous les labels. Si un label n'existe pas déjà, cela crée un nouveau label de projet et l'assigne au ticket. |
| `milestone_id` | integer | Non       | L'ID global d'un jalon à assigner au ticket. Définir à `0` ou fournir une valeur vide pour désassigner un jalon. Mutuellement exclusif avec `milestone`.|
| `milestone`    | string  | Non       | Le titre d'un jalon de projet ou de groupe ancêtre à assigner au ticket. Correspondance exacte (sensible à la casse). Mutuellement exclusif avec `milestone_id`. |
| `remove_labels`| string  | Non       | Noms de labels séparés par des virgules à retirer d'un ticket.                                                       |
| `state_event`  | string  | Non       | L'événement d'état d'un ticket. Pour fermer le ticket, utilisez `close`, et pour le rouvrir, utilisez `reopen`.                      |
| `title`        | string  | Non       | Le titre d'un ticket.                                                                                      |
| `updated_at`   | string  | Non       | Date de mise à jour du ticket. Chaîne de date/heure au format ISO 8601, par exemple `2016-03-11T03:45:40Z` (nécessite des droits d'administrateur ou de propriétaire du projet). Les valeurs de chaîne vide ou null ne sont pas acceptées.|
| `weight`       | integer | Non       | Le poids du ticket. Les valeurs valides sont supérieures ou égales à 0. Premium et Ultimate uniquement.           |

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/85?state_event=close"
```

Exemple de réponse :

```json
{
   "created_at" : "2016-01-07T12:46:01.410Z",
   "author" : {
      "name" : "Alexandra Bashirian",
      "avatar_url" : null,
      "username" : "eileen.lowe",
      "id" : 18,
      "state" : "active",
      "web_url" : "https://gitlab.example.com/eileen.lowe"
   },
   "state" : "closed",
   "title" : "Issues with auth",
   "project_id" : 4,
   "description" : null,
   "updated_at" : "2016-01-07T12:55:16.213Z",
   "closed_at" : "2016-01-08T12:55:16.213Z",
   "closed_by" : {
      "state" : "active",
      "web_url" : "https://gitlab.example.com/root",
      "avatar_url" : null,
      "username" : "root",
      "id" : 1,
      "name" : "Administrator"
    },
   "iid" : 15,
   "labels" : [
      "bug"
   ],
   "upvotes": 4,
   "downvotes": 0,
   "merge_requests_count": 0,
   "id" : 85,
   "assignees" : [],
   "assignee" : null,
   "milestone" : null,
   "subscribed" : true,
   "user_notes_count": 0,
   "due_date": "2016-07-22",
   "web_url": "http://gitlab.example.com/my-group/my-project/issues/15",
   "references": {
     "short": "#15",
     "relative": "#15",
     "full": "my-group/my-project#15"
   },
   "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
   },
   "confidential": false,
   "discussion_locked": false,
   "issue_type": "issue",
   "severity": "UNKNOWN",
   "_links": {
      "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
      "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
      "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
      "project": "http://gitlab.example.com/api/v4/projects/1",
      "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"

   },
   "task_completion_status":{
      "count":0,
      "completed_count":0
   }
}
```

Les tickets créés par des utilisateurs sur GitLab Premium ou Ultimate incluent la propriété `weight` :

```json
{
   "project_id" : 4,
   "description" : null,
   "weight": null,
   ...
}
```

Les tickets créés par des utilisateurs sur GitLab Premium ou Ultimate incluent la propriété `epic` :

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

Les tickets créés par des utilisateurs sur GitLab Ultimate incluent la propriété `health_status` :

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

> [!warning]
> Dépréciations :
>
> - L'attribut `epic_iid` est déprécié et [programmé pour suppression](https://gitlab.com/gitlab-org/gitlab/-/issues/35157) dans la version 5 de l'API. Utilisez plutôt `iid` de l'attribut `epic`.
> - La colonne `assignee` est dépréciée. Nous l'affichons désormais comme un tableau à un seul élément `assignees` pour être conforme à l'API GitLab EE.

## Supprimer un ticket {#delete-an-issue}

{{< history >}}

- Les utilisateurs peuvent supprimer les tickets qu'ils ont créés, [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/371104) dans GitLab 18.10.

{{< /history >}}

Les utilisateurs ayant le rôle Planificateur ou Propriétaire peuvent supprimer n'importe quel ticket. Les autres membres du projet peuvent supprimer les tickets qu'ils ont créés.

Supprime un ticket spécifié d'un projet.

```plaintext
DELETE /projects/:id/issues/:issue_iid
```

Attributs pris en charge :

| Attribut   | Type    | Obligatoire | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Oui      | L'ID interne du ticket d'un projet. |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/85"
```

En cas de succès, renvoie [`204 No Content`](rest/troubleshooting.md#status-codes).

## Réordonner un ticket {#reorder-an-issue}

Réordonne un ticket spécifié au sein d'un projet. Vous pouvez voir les résultats lors du [tri manuel des tickets](../user/project/issues/sorting_issue_lists.md#manual-sorting).

```plaintext
PUT /projects/:id/issues/:issue_iid/reorder
```

Attributs pris en charge :

| Attribut   | Type    | Obligatoire | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Oui      | L'ID interne du ticket du projet. |
| `move_after_id` | integer | Non | L'ID global du ticket d'un projet qui doit être placé après ce ticket. |
| `move_before_id` | integer | Non | L'ID global du ticket d'un projet qui doit être placé avant ce ticket. |

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/85/reorder?move_after_id=51&move_before_id=92"
```

## Déplacer un ticket {#move-an-issue}

Déplace un ticket spécifié vers un projet différent. Si le projet cible est le projet source ou si l'utilisateur ne dispose pas des autorisations suffisantes, un message d'erreur avec le code de statut `400` est renvoyé.

Si un label ou un jalon donné portant le même nom existe également dans le projet cible, il est alors assigné au ticket déplacé.

```plaintext
POST /projects/:id/issues/:issue_iid/move
```

Attributs pris en charge :

| Attribut       | Type    | Obligatoire | Description                          |
|-----------------|---------|----------|--------------------------------------|
| `id`            | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).  |
| `issue_iid`     | integer | Oui      | L'ID interne du ticket d'un projet. |
| `to_project_id` | integer | Oui      | L'ID du nouveau projet.            |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --form to_project_id=5 \
  --url "https://gitlab.example.com/api/v4/projects/4/issues/85/move"
```

Exemple de réponse :

```json
{
  "id": 92,
  "iid": 11,
  "project_id": 5,
  "title": "Sit voluptas tempora quisquam aut doloribus et.",
  "description": "Repellat voluptas quibusdam voluptatem exercitationem.",
  "state": "opened",
  "created_at": "2016-04-05T21:41:45.652Z",
  "updated_at": "2016-04-07T12:20:17.596Z",
  "closed_at": null,
  "closed_by": null,
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "merge_requests_count": 0,
  "milestone": null,
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "assignee": {
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  },
  "type" : "ISSUE",
  "author": {
    "name": "Kris Steuber",
    "username": "solon.cremin",
    "id": 10,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7a190fecbaa68212a4b68aeb6e3acd10?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/solon.cremin"
  },
  "due_date": null,
  "imported": false,
  "imported_from": "none",
  "web_url": "http://gitlab.example.com/my-group/my-project/issues/11",
  "references": {
    "short": "#11",
    "relative": "#11",
    "full": "my-group/my-project#11"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "confidential": false,
  "discussion_locked": false,
  "issue_type": "issue",
  "severity": "UNKNOWN",
  "_links": {
    "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
    "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
    "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
    "project": "http://gitlab.example.com/api/v4/projects/1",
    "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
  },
  "task_completion_status":{
     "count":0,
     "completed_count":0
  }
}
```

Les tickets créés par des utilisateurs sur GitLab Premium ou Ultimate incluent la propriété `weight` :

```json
{
  "project_id": 5,
  "description": "Repellat voluptas quibusdam voluptatem exercitationem.",
  "weight": null,
  ...
}
```

Les tickets créés par des utilisateurs sur GitLab Premium ou Ultimate incluent la propriété `epic` :

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

Les tickets créés par des utilisateurs sur GitLab Ultimate incluent la propriété `health_status` :

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

> [!warning]
> La colonne `assignee` est dépréciée. Nous l'affichons désormais comme un tableau à un seul élément `assignees` pour être conforme à l'API GitLab EE.
>
> L'attribut `epic_iid` est déprécié et [programmé pour suppression](https://gitlab.com/gitlab-org/gitlab/-/issues/35157) dans la version 5 de l'API. Utilisez plutôt `iid` de l'attribut `epic`.

## Cloner un ticket {#clone-an-issue}

Clone un ticket spécifié vers un projet donné. Copie autant de données que possible à condition que le projet cible contienne des critères équivalents, tels que des labels ou des jalons.

Si vous ne disposez pas des autorisations suffisantes, un message d'erreur avec le code de statut `400` est renvoyé.

```plaintext
POST /projects/:id/issues/:issue_iid/clone
```

Attributs pris en charge :

| Attribut       | Type           | Obligatoire               | Description                       |
| --------------- | -------------- | ---------------------- | --------------------------------- |
| `id`            | integer ou string | Oui | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid`     | integer        | Oui | ID interne du ticket d'un projet. |
| `to_project_id` | integer        | Oui | ID du nouveau projet.            |
| `with_notes`    | boolean        | Non | Cloner le ticket avec les [notes](notes.md). La valeur par défaut est `false`. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/1/clone?with_notes=true&to_project_id=6"
```

Exemple de réponse :

```json
{
  "id":290,
  "iid":1,
  "project_id":143,
  "title":"foo",
  "description":"closed",
  "state":"opened",
  "created_at":"2021-09-14T22:24:11.696Z",
  "updated_at":"2021-09-14T22:24:11.696Z",
  "closed_at":null,
  "closed_by":null,
  "labels":[

  ],
  "milestone":null,
  "assignees":[
    {
      "id":179,
      "name":"John Doe2",
      "username":"john",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/10fc7f102be8de7657fb4d80898bbfe3?s=80\u0026d=identicon",
      "web_url":"https://gitlab.example.com/john"
    }
  ],
  "author":{
    "id":179,
    "name":"John Doe2",
    "username":"john",
    "state":"active",
    "avatar_url":"https://www.gravatar.com/avatar/10fc7f102be8de7657fb4d80898bbfe3?s=80\u0026d=identicon",
    "web_url":"https://gitlab.example.com/john"
  },
  "type":"ISSUE",
  "assignee":{
    "id":179,
    "name":"John Doe2",
    "username":"john",
    "state":"active",
    "avatar_url":"https://www.gravatar.com/avatar/10fc7f102be8de7657fb4d80898bbfe3?s=80\u0026d=identicon",
    "web_url":"https://gitlab.example.com/john"
  },
  "user_notes_count":1,
  "merge_requests_count":0,
  "upvotes":0,
  "downvotes":0,
  "due_date":null,
  "imported":false,
  "imported_from": "none",
  "confidential":false,
  "discussion_locked":null,
  "issue_type":"issue",
  "severity": "UNKNOWN",
  "web_url":"https://gitlab.example.com/namespace1/project2/-/issues/1",
  "time_stats":{
    "time_estimate":0,
    "total_time_spent":0,
    "human_time_estimate":null,
    "human_total_time_spent":null
  },
  "task_completion_status":{
    "count":0,
    "completed_count":0
  },
  "blocking_issues_count":0,
  "has_tasks":false,
  "_links":{
    "self":"https://gitlab.example.com/api/v4/projects/143/issues/1",
    "notes":"https://gitlab.example.com/api/v4/projects/143/issues/1/notes",
    "award_emoji":"https://gitlab.example.com/api/v4/projects/143/issues/1/award_emoji",
    "project":"https://gitlab.example.com/api/v4/projects/143",
    "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
  },
  "references":{
    "short":"#1",
    "relative":"#1",
    "full":"namespace1/project2#1"
  },
  "subscribed":true,
  "moved_to_id":null,
  "service_desk_reply_to":null
}
```

## Notifications {#notifications}

Les requêtes suivantes sont liées aux [notifications par e-mail](../user/profile/notifications.md) pour les tickets.

### S'abonner à un ticket {#subscribe-to-an-issue}

Abonne l'utilisateur authentifié à un ticket spécifié pour recevoir des notifications. Si l'utilisateur est déjà abonné au ticket, le code de statut `304` est renvoyé.

```plaintext
POST /projects/:id/issues/:issue_iid/subscribe
```

Attributs pris en charge :

| Attribut   | Type    | Obligatoire | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Oui      | L'ID interne du ticket d'un projet. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/subscribe"
```

Exemple de réponse :

```json
{
  "id": 92,
  "iid": 11,
  "project_id": 5,
  "title": "Sit voluptas tempora quisquam aut doloribus et.",
  "description": "Repellat voluptas quibusdam voluptatem exercitationem.",
  "state": "opened",
  "created_at": "2016-04-05T21:41:45.652Z",
  "updated_at": "2016-04-07T12:20:17.596Z",
  "closed_at": null,
  "closed_by": null,
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "merge_requests_count": 0,
  "milestone": null,
  "assignees": [{
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  }],
  "assignee": {
    "name": "Miss Monserrate Beier",
    "username": "axel.block",
    "id": 12,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/46f6f7dc858ada7be1853f7fb96e81da?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/axel.block"
  },
  "type" : "ISSUE",
  "author": {
    "name": "Kris Steuber",
    "username": "solon.cremin",
    "id": 10,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7a190fecbaa68212a4b68aeb6e3acd10?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/solon.cremin"
  },
  "due_date": null,
  "web_url": "http://gitlab.example.com/my-group/my-project/issues/11",
  "references": {
    "short": "#11",
    "relative": "#11",
    "full": "my-group/my-project#11"
  },
  "time_stats": {
    "time_estimate": 0,
    "total_time_spent": 0,
    "human_time_estimate": null,
    "human_total_time_spent": null
  },
  "confidential": false,
  "discussion_locked": false,
  "issue_type": "issue",
  "severity": "UNKNOWN",
  "_links": {
    "self": "http://gitlab.example.com/api/v4/projects/1/issues/2",
    "notes": "http://gitlab.example.com/api/v4/projects/1/issues/2/notes",
    "award_emoji": "http://gitlab.example.com/api/v4/projects/1/issues/2/award_emoji",
    "project": "http://gitlab.example.com/api/v4/projects/1",
    "closed_as_duplicate_of": "http://gitlab.example.com/api/v4/projects/1/issues/75"
  },
  "task_completion_status":{
     "count":0,
     "completed_count":0
  }
}
```

Les tickets créés par des utilisateurs sur GitLab Premium ou Ultimate incluent la propriété `weight` :

```json
{
  "project_id": 5,
  "description": "Repellat voluptas quibusdam voluptatem exercitationem.",
  "weight": null,
  ...
}
```

Les tickets créés par des utilisateurs sur GitLab Premium ou Ultimate incluent la propriété `epic` :

```json
{
   "project_id" : 4,
   "description" : "Omnis vero earum sunt corporis dolor et placeat.",
   "epic_iid" : 5, //deprecated, use `iid` of the `epic` attribute
   "epic": {
     "id" : 42,
     "iid" : 5,
     "title": "My epic epic",
     "url" : "/groups/h5bp/-/epics/5",
     "group_id": 8
   },
   ...
}
```

Les tickets créés par des utilisateurs sur GitLab Ultimate incluent la propriété `health_status` :

```json
[
   {
      "project_id" : 4,
      "description" : "Omnis vero earum sunt corporis dolor et placeat.",
      "health_status": "on_track",
      ...
   }
]
```

> [!warning]
> La colonne `assignee` est dépréciée. Nous l'affichons désormais comme un tableau à un seul élément `assignees` pour être conforme à l'API GitLab EE.
>
> L'attribut `epic_iid` est déprécié et [programmé pour suppression](https://gitlab.com/gitlab-org/gitlab/-/issues/35157) dans la version 5 de l'API. Utilisez plutôt `iid` de l'attribut `epic`.

### Se désabonner d'un ticket {#unsubscribe-from-an-issue}

Désabonne l'utilisateur authentifié d'un ticket spécifié pour ne plus recevoir de notifications. Si l'utilisateur n'est pas abonné au ticket, le code de statut `304` est renvoyé.

```plaintext
POST /projects/:id/issues/:issue_iid/unsubscribe
```

Attributs pris en charge :

| Attribut   | Type    | Obligatoire | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Oui      | L'ID interne du ticket d'un projet. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/unsubscribe"
```

Exemple de réponse :

```json
{
  "id": 93,
  "iid": 12,
  "project_id": 5,
  "title": "Incidunt et rerum ea expedita iure quibusdam.",
  "description": "Et cumque architecto sed aut ipsam.",
  "state": "opened",
  "created_at": "2016-04-05T21:41:45.217Z",
  "updated_at": "2016-04-07T13:02:37.905Z",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "merge_requests_count": 0,
  "milestone": null,
  "assignee": {
    "name": "Edwardo Grady",
    "username": "keyon",
    "id": 21,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/3e6f06a86cf27fa8b56f3f74f7615987?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/keyon"
  },
  "type" : "ISSUE",
  "closed_at": null,
  "closed_by": null,
  "author": {
    "name": "Vivian Hermann",
    "username": "orville",
    "id": 11,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/5224fd70153710e92fb8bcf79ac29d67?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/orville"
  },
  "subscribed": false,
  "due_date": null,
  "web_url": "http://gitlab.example.com/my-group/my-project/issues/12",
  "references": {
    "short": "#12",
    "relative": "#12",
    "full": "my-group/my-project#12"
  },
  "confidential": false,
  "discussion_locked": false,
  "issue_type": "issue",
  "severity": "UNKNOWN",
  "task_completion_status":{
     "count":0,
     "completed_count":0
  }
}
```

## Créer un élément de la liste de tâches pour un ticket {#create-a-to-do-item-for-an-issue}

Crée un élément de la liste de tâches pour l'utilisateur actuel sur un ticket spécifié. Si un élément de la liste de tâches existe déjà pour l'utilisateur sur ce ticket, le code de statut `304` est renvoyé.

```plaintext
POST /projects/:id/issues/:issue_iid/todo
```

Attributs pris en charge :

| Attribut   | Type    | Obligatoire | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Oui      | L'ID interne du ticket d'un projet. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/todo"
```

Exemple de réponse :

```json
{
  "id": 112,
  "project": {
    "id": 5,
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
  "target_type": "Issue",
  "target": {
    "id": 93,
    "iid": 10,
    "project_id": 5,
    "title": "Vel voluptas atque dicta mollitia adipisci qui at.",
    "description": "Tempora laboriosam sint magni sed voluptas similique.",
    "state": "closed",
    "created_at": "2016-06-17T07:47:39.486Z",
    "updated_at": "2016-07-01T11:09:13.998Z",
    "labels": [],
    "milestone": {
      "id": 26,
      "iid": 1,
      "project_id": 5,
      "title": "v0.0",
      "description": "Accusantium nostrum rerum quae quia quis nesciunt suscipit id.",
      "state": "closed",
      "created_at": "2016-06-17T07:47:33.832Z",
      "updated_at": "2016-06-17T07:47:33.832Z",
      "due_date": null
    },
    "assignees": [{
      "name": "Jarret O'Keefe",
      "username": "francisca",
      "id": 14,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a7fa515d53450023c83d62986d0658a8?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/francisca"
    }],
    "assignee": {
      "name": "Jarret O'Keefe",
      "username": "francisca",
      "id": 14,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a7fa515d53450023c83d62986d0658a8?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/francisca"
    },
    "type" : "ISSUE",
    "author": {
      "name": "Maxie Medhurst",
      "username": "craig_rutherford",
      "id": 12,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/craig_rutherford"
    },
    "subscribed": true,
    "user_notes_count": 7,
    "upvotes": 0,
    "downvotes": 0,
    "merge_requests_count": 0,
    "due_date": null,
    "web_url": "http://gitlab.example.com/my-group/my-project/issues/10",
    "references": {
      "short": "#10",
      "relative": "#10",
      "full": "my-group/my-project#10"
    },
    "confidential": false,
    "discussion_locked": false,
    "issue_type": "issue",
    "severity": "UNKNOWN",
    "task_completion_status":{
       "count":0,
       "completed_count":0
    }
  },
  "target_url": "https://gitlab.example.com/gitlab-org/gitlab-ci/issues/10",
  "body": "Vel voluptas atque dicta mollitia adipisci qui at.",
  "state": "pending",
  "created_at": "2016-07-01T11:09:13.992Z"
}
```

> [!warning]
> La colonne `assignee` est dépréciée. Nous l'affichons désormais comme un tableau à un seul élément `assignees` pour être conforme à l'API GitLab EE.

## Promouvoir un ticket en epic {#promote-an-issue-to-an-epic}

{{< details >}}

- Édition :  Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Promeut un ticket spécifié en epic en ajoutant un commentaire avec l'action rapide [`/promote_to`](../user/project/quick_actions.md#promote_to).

Pour plus d'informations, consultez [promouvoir un ticket en epic](../user/project/issues/managing_issues.md#promote-an-issue-to-an-epic).

```plaintext
POST /projects/:id/issues/:issue_iid/notes
```

Attributs pris en charge :

| Attribut   | Type           | Obligatoire | Description |
| :---------- | :------------- | :------- | :---------- |
| `id`        | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid` | integer        | Oui      | L'ID interne du ticket d'un projet. |
| `body`      | String         | Oui      | Le contenu d'une note. Doit contenir `/promote` au début d'une nouvelle ligne. Si la note contient uniquement `/promote`, le ticket est promu, mais aucun commentaire n'est ajouté. Sinon, les autres lignes forment un commentaire.|

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/11/notes?body=Lets%20promote%20this%20to%20an%20epic%0A%0A%2Fpromote"
```

Exemple de réponse :

```json
{
   "id":699,
   "type":null,
   "body":"Lets promote this to an epic",
   "attachment":null,
   "author": {
      "id":1,
      "name":"Alexandra Bashirian",
      "username":"eileen.lowe",
      "state":"active",
      "avatar_url":"https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url":"https://gitlab.example.com/eileen.lowe"
   },
   "created_at":"2020-12-03T12:27:17.844Z",
   "updated_at":"2020-12-03T12:27:17.844Z",
   "system":false,
   "noteable_id":461,
   "noteable_type":"Issue",
   "resolvable":false,
   "confidential":false,
   "noteable_iid":33,
   "commands_changes": {
      "promote_to_epic":true
   }
}
```

## Suivi du temps {#time-tracking}

Les requêtes suivantes sont liées au [suivi du temps](../user/project/time_tracking.md) sur les tickets.

### Définir une estimation de temps pour un ticket {#set-a-time-estimate-for-an-issue}

Définit un temps de travail estimé pour un ticket spécifié.

```plaintext
POST /projects/:id/issues/:issue_iid/time_estimate
```

Attributs pris en charge :

| Attribut   | Type    | Obligatoire | Description                              |
|-------------|---------|----------|------------------------------------------|
| `duration`  | string  | Oui      | La durée dans un format lisible par l'utilisateur. Par exemple : `3h30m`. |
| `id`        | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).      |
| `issue_iid` | integer | Oui      | L'ID interne du ticket d'un projet.     |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/time_estimate?duration=3h30m"
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

### Réinitialiser l'estimation de temps pour un ticket {#reset-the-time-estimate-for-an-issue}

Réinitialise le temps estimé pour un ticket spécifié à 0 seconde.

```plaintext
POST /projects/:id/issues/:issue_iid/reset_time_estimate
```

Attributs pris en charge :

| Attribut   | Type    | Obligatoire | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Oui      | L'ID interne du ticket d'un projet. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/reset_time_estimate"
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

### Ajouter du temps passé pour un ticket {#add-spent-time-for-an-issue}

Ajoute du temps passé pour un ticket spécifié.

```plaintext
POST /projects/:id/issues/:issue_iid/add_spent_time
```

Attributs pris en charge :

| Attribut   | Type    | Obligatoire | Description                              |
|-------------|---------|----------|------------------------------------------|
| `duration`  | string  | Oui      | La durée dans un format lisible par l'utilisateur. Par exemple : `3h30m` |
| `id`        | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid` | integer | Oui      | L'ID interne du ticket d'un projet.    |
| `summary`   | string  | Non       | Un résumé de la façon dont le temps a été utilisé.  |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/add_spent_time?duration=1h"
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

### Réinitialiser le temps passé pour un ticket {#reset-spent-time-for-an-issue}

Réinitialise le temps total passé pour un ticket spécifié à 0 seconde.

```plaintext
POST /projects/:id/issues/:issue_iid/reset_spent_time
```

Attributs pris en charge :

| Attribut   | Type    | Obligatoire | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid` | integer | Oui      | L'ID interne du ticket d'un projet. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/reset_spent_time"
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

### Récupérer les statistiques de suivi du temps pour un ticket {#retrieve-time-tracking-stats-for-an-issue}

Récupère les statistiques de suivi du temps pour un ticket spécifié dans un format lisible par l'utilisateur (par exemple, `1h30m`) et en nombre de secondes.

Si le projet est privé ou si le ticket est confidentiel, vous devez fournir des identifiants pour vous autoriser. La méthode recommandée consiste à utiliser des [jetons d'accès personnels](../user/profile/personal_access_tokens.md).

```plaintext
GET /projects/:id/issues/:issue_iid/time_stats
```

Attributs pris en charge :

| Attribut   | Type    | Obligatoire | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Oui      | L'ID interne du ticket d'un projet. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/time_stats"
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

## Merge requests {#merge-requests}

Les requêtes suivantes sont liées aux relations entre les tickets et les merge requests.

### Lister toutes les merge requests liées à un ticket {#list-all-merge-requests-related-to-an-issue}

Liste toutes les merge requests liées à un ticket spécifié.

Si le projet est privé ou le ticket est confidentiel, vous devez fournir des identifiants pour vous authentifier. La méthode recommandée consiste à utiliser des [jetons d'accès personnels](../user/profile/personal_access_tokens.md).

```plaintext
GET /projects/:id/issues/:issue_iid/related_merge_requests
```

Attributs pris en charge :

| Attribut   | Type    | Obligatoire | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Oui      | L'ID interne du ticket d'un projet. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/11/related_merge_requests"
```

Exemple de réponse :

```json
[
  {
    "id": 29,
    "iid": 11,
    "project_id": 1,
    "title": "Provident eius eos blanditiis consequatur neque odit.",
    "description": "Ut consequatur ipsa aspernatur quisquam voluptatum fugit. Qui harum corporis quo fuga ut incidunt veritatis. Autem necessitatibus et harum occaecati nihil ea.\r\n\r\ntwitter/flight#8",
    "state": "opened",
    "created_at": "2018-09-18T14:36:15.510Z",
    "updated_at": "2018-09-19T07:45:13.089Z",
    "closed_by": null,
    "closed_at": null,
    "target_branch": "v2.x",
    "source_branch": "so_long_jquery",
    "user_notes_count": 9,
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 14,
      "name": "Verna Hills",
      "username": "lawanda_reinger",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/de68a91aeab1cff563795fb98a0c2cc0?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/lawanda_reinger"
    },
    "assignee": {
      "id": 19,
      "name": "Jody Baumbach",
      "username": "felipa.kuvalis",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/6541fc75fc4e87e203529bd275fafd07?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/felipa.kuvalis"
    },
    "source_project_id": 1,
    "target_project_id": 1,
    "labels": [],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 27,
      "iid": 2,
      "project_id": 1,
      "title": "v1.0",
      "description": "Et tenetur voluptatem minima doloribus vero dignissimos vitae.",
      "state": "active",
      "created_at": "2018-09-18T14:35:44.353Z",
      "updated_at": "2018-09-18T14:35:44.353Z",
      "due_date": null,
      "start_date": null,
      "web_url": "https://gitlab.example.com/twitter/flight/milestones/2"
    },
    "merge_when_pipeline_succeeds": false,
    "merge_status": "cannot_be_merged",
    "sha": "3b7b528e9353295c1c125dad281ac5b5deae5f12",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "discussion_locked": null,
    "should_remove_source_branch": null,
    "force_remove_source_branch": false,
    "reference": "!11",
    "web_url": "https://gitlab.example.com/twitter/flight/merge_requests/4",
    "references": {
      "short": "!4",
      "relative": "!4",
      "full": "twitter/flight!4"
    },
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
    "changes_count": "10",
    "latest_build_started_at": "2018-12-05T01:16:41.723Z",
    "latest_build_finished_at": "2018-12-05T02:35:54.046Z",
    "first_deployed_to_production_at": null,
    "pipeline": {
      "id": 38980952,
      "sha": "81c6a84c7aebd45a1ac2c654aa87f11e32338e0a",
      "ref": "test-branch",
      "status": "success",
      "web_url": "https://gitlab.com/gitlab-org/gitlab/pipelines/38980952"
    },
    "head_pipeline": {
      "id": 38980952,
      "sha": "81c6a84c7aebd45a1ac2c654aa87f11e32338e0a",
      "ref": "test-branch",
      "status": "success",
      "web_url": "https://gitlab.example.com/twitter/flight/pipelines/38980952",
      "before_sha": "3c738a37eb23cf4c0ed0d45d6ddde8aad4a8da51",
      "tag": false,
      "yaml_errors": null,
      "user": {
        "id": 19,
        "name": "Jody Baumbach",
        "username": "felipa.kuvalis",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/6541fc75fc4e87e203529bd275fafd07?s=80&d=identicon",
        "web_url": "https://gitlab.example.com/felipa.kuvalis"
      },
      "created_at": "2018-12-05T01:16:13.342Z",
      "updated_at": "2018-12-05T02:35:54.086Z",
      "started_at": "2018-12-05T01:16:41.723Z",
      "finished_at": "2018-12-05T02:35:54.046Z",
      "committed_at": null,
      "duration": 4436,
      "coverage": "46.68",
      "detailed_status": {
        "icon": "status_warning",
        "text": "passed",
        "label": "passed with warnings",
        "group": "success-with-warnings",
        "tooltip": "passed",
        "has_details": true,
        "details_path": "/twitter/flight/pipelines/38",
        "illustration": null,
        "favicon": "https://gitlab.example.com/assets/ci_favicons/favicon_status_success-8451333011eee8ce9f2ab25dc487fe24a8758c694827a582f17f42b0a90446a2.png"
      },
      "archived": false
    },
    "diff_refs": {
      "base_sha": "d052d768f0126e8cddf80afd8b1eb07f406a3fcb",
      "head_sha": "81c6a84c7aebd45a1ac2c654aa87f11e32338e0a",
      "start_sha": "d052d768f0126e8cddf80afd8b1eb07f406a3fcb"
    },
    "merge_error": null,
    "user": {
      "can_merge": true
    }
  }
]
```

### Lister toutes les merge requests qui ferment un ticket lors du merge {#list-all-merge-requests-that-close-an-issue-on-merge}

Liste toutes les merge requests qui ferment un ticket spécifié lors du merge.

Si le projet est privé ou le ticket est confidentiel, vous devez fournir des identifiants pour vous authentifier. La méthode recommandée consiste à utiliser des [jetons d'accès personnels](../user/profile/personal_access_tokens.md).

```plaintext
GET /projects/:id/issues/:issue_iid/closed_by
```

Attributs pris en charge :

| Attribut   | Type           | Obligatoire | Description                        |
| ----------- | ---------------| -------- | ---------------------------------- |
| `id`        | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `issue_iid` | integer        | Oui      | L'ID interne du ticket d'un projet. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/11/closed_by"
```

Exemple de réponse :

```json
[
  {
    "id": 6471,
    "iid": 6432,
    "project_id": 1,
    "title": "add a test for cgi lexer options",
    "description": "closes #11",
    "state": "opened",
    "created_at": "2017-04-06T18:33:34.168Z",
    "updated_at": "2017-04-09T20:10:24.983Z",
    "target_branch": "main",
    "source_branch": "feature.custom-highlighting",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "name": "Administrator",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/root"
    },
    "assignee": null,
    "source_project_id": 1,
    "target_project_id": 1,
    "closed_at": null,
    "closed_by": null,
    "labels": [],
    "draft": false,
    "work_in_progress": false,
    "milestone": null,
    "merge_when_pipeline_succeeds": false,
    "merge_status": "unchecked",
    "sha": "5a62481d563af92b8e32d735f2fa63b94e806835",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 1,
    "should_remove_source_branch": null,
    "force_remove_source_branch": false,
    "web_url": "https://gitlab.example.com/gitlab-org/gitlab-test/merge_requests/6432",
    "reference": "!6432",
    "references": {
      "short": "!6432",
      "relative": "!6432",
      "full": "gitlab-org/gitlab-test!6432"
    },
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

## Lister tous les participants d'un ticket {#list-all-participants-in-an-issue}

Liste tous les utilisateurs qui sont participants d'un ticket spécifié.

Si le projet est privé ou le ticket est confidentiel, vous devez fournir des identifiants pour vous authentifier. La méthode recommandée consiste à utiliser des [jetons d'accès personnels](../user/profile/personal_access_tokens.md).

```plaintext
GET /projects/:id/issues/:issue_iid/participants
```

Attributs pris en charge :

| Attribut   | Type    | Obligatoire | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Oui      | L'ID interne du ticket d'un projet. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  -url "https://gitlab.example.com/api/v4/projects/5/issues/93/participants"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/user1"
  },
  {
    "id": 5,
    "name": "John Doe5",
    "username": "user5",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/4aea8cf834ed91844a2da4ff7ae6b491?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/user5"
  }
]
```

## Commentaires sur les tickets {#comments-on-issues}

Interagissez avec les commentaires en utilisant l'[API des notes](notes.md).

## Récupérer les détails de l'agent utilisateur pour un ticket {#retrieve-user-agent-details-for-an-issue}

Disponible uniquement pour les administrateurs.

Récupère la chaîne de l'agent utilisateur et l'adresse IP de l'utilisateur qui a créé un ticket spécifié. Utilisé pour le suivi des spams.

```plaintext
GET /projects/:id/issues/:issue_iid/user_agent_detail
```

Attributs pris en charge :

| Attribut   | Type    | Obligatoire | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Oui      | L'ID interne du ticket d'un projet. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/user_agent_detail"
```

Exemple de réponse :

```json
{
  "user_agent": "AppleWebKit/537.36",
  "ip_address": "127.0.0.1",
  "akismet_submitted": false
}
```

## Lister les événements d'état d'un ticket {#list-issue-state-events}

Pour suivre l'état défini, qui l'a défini et quand cela s'est produit, utilisez l'[API des événements d'état de ressource](resource_state_events.md#issues).

## Incidents {#incidents}

Les requêtes suivantes sont disponibles uniquement pour les [incidents](../operations/incident_management/incidents.md).

### Téléverser une image de métrique pour un incident {#upload-a-metric-image-for-an-incident}

Disponible uniquement pour les [incidents](../operations/incident_management/incidents.md).

Téléverse une capture d'écran de graphiques de métriques à afficher dans l'onglet **Métriques** d'un incident spécifié. Lorsque vous téléversez une image, vous pouvez l'associer à du texte ou à un lien vers le graphique d'origine. Si vous ajoutez une URL, vous pouvez accéder au graphique d'origine en sélectionnant le lien hypertexte au-dessus de l'image téléversée.

```plaintext
POST /projects/:id/issues/:issue_iid/metric_images
```

Attributs pris en charge :

| Attribut   | Type    | Obligatoire | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Oui      | L'ID interne du ticket d'un projet. |
| `file` | file | Oui      | Le fichier image à téléverser. |
| `url` | string | Non      | L'URL pour afficher plus d'informations sur les métriques. |
| `url_text` | string | Non      | Une description de l'image ou de l'URL. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --form 'file=@/path/to/file.png' \
  --form 'url=http://example.com' \
  --form 'url_text=Example website' \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/metric_images"
```

Exemple de réponse :

```json
{
    "id": 23,
    "created_at": "2020-11-13T00:06:18.084Z",
    "filename": "file.png",
    "file_path": "/uploads/-/system/issuable_metric_image/file/23/file.png",
    "url": "http://example.com",
    "url_text": "Example website"
}
```

### Lister toutes les images de métriques pour un incident {#list-all-metric-images-for-an-incident}

Disponible uniquement pour les [incidents](../operations/incident_management/incidents.md).

Liste toutes les captures d'écran de graphiques de métriques affichées dans l'onglet **Métriques** d'un incident spécifié.

```plaintext
GET /projects/:id/issues/:issue_iid/metric_images
```

Attributs pris en charge :

| Attribut   | Type    | Obligatoire | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Oui      | L'ID interne du ticket d'un projet. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  -url "https://gitlab.example.com/api/v4/projects/5/issues/93/metric_images"
```

Exemple de réponse :

```json
[
    {
        "id": 17,
        "created_at": "2020-11-12T20:07:58.156Z",
        "filename": "sample_2054",
        "file_path": "/uploads/-/system/issuable_metric_image/file/17/sample_2054.png",
        "url": "example.com/metric"
    },
    {
        "id": 18,
        "created_at": "2020-11-12T20:14:26.441Z",
        "filename": "sample_2054",
        "file_path": "/uploads/-/system/issuable_metric_image/file/18/sample_2054.png",
        "url": "example.com/metric"
    }
]
```

### Mettre à jour une image de métrique pour un incident {#update-a-metric-image-for-an-incident}

Disponible uniquement pour les [incidents](../operations/incident_management/incidents.md).

Met à jour les attributs d'une image de métrique spécifiée affichée dans l'onglet **Métriques** d'un incident.

```plaintext
PUT /projects/:id/issues/:issue_iid/metric_images/:image_id
```

Attributs pris en charge :

| Attribut   | Type    | Obligatoire | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Oui      | L'ID interne du ticket d'un projet. |
| `image_id` | integer | Oui      | L'ID de l'image. |
| `url` | string | Non      | L'URL pour afficher plus d'informations sur les métriques. |
| `url_text` | string | Non      | Une description de l'image ou de l'URL. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --request PUT \
  --form 'url=http://example.com' \
  --form 'url_text=Example website' \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/metric_images/1"
```

Exemple de réponse :

```json
{
    "id": 23,
    "created_at": "2020-11-13T00:06:18.084Z",
    "filename": "file.png",
    "file_path": "/uploads/-/system/issuable_metric_image/file/23/file.png",
    "url": "http://example.com",
    "url_text": "Example website"
}
```

### Supprimer une image de métrique d'un incident {#delete-a-metric-image-from-an-incident}

Disponible uniquement pour les [incidents](../operations/incident_management/incidents.md).

Supprime une image de métrique spécifiée de l'onglet **Métriques** d'un incident.

```plaintext
DELETE /projects/:id/issues/:issue_iid/metric_images/:image_id
```

Attributs pris en charge :

| Attribut   | Type    | Obligatoire | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | integer ou string | Oui      | L'ID global ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).  |
| `issue_iid` | integer | Oui      | L'ID interne du ticket d'un projet. |
| `image_id` | integer | Oui      | L'ID de l'image. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --request DELETE \
  --url "https://gitlab.example.com/api/v4/projects/5/issues/93/metric_images/1"
```

Peut retourner les codes de statut suivants :

- `204 No Content`, si l'image a été supprimée avec succès.
- `400 Bad Request`, si l'image n'a pas pu être supprimée.
