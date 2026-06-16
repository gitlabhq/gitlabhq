---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Epics (déprécié)
description: "Consultez la documentation officielle de l'API GitLab pour les epics. Découvrez comment répertorier, créer, mettre à jour et supprimer des epics dans vos groupes de manière programmatique et efficace."
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> L'API REST Epics a été [dépréciée](https://gitlab.com/gitlab-org/gitlab/-/issues/460668) dans GitLab 17.0 et sa suppression est prévue dans la v5 de l'API. De GitLab 17.4 à 18.0, si [le nouvel aspect des epics](../user/group/epics/_index.md#epics-as-work-items) est activé, et dans GitLab 18.1 et versions ultérieures, utilisez plutôt l'API Work Items. Pour plus d'informations, voir [migrer les API epics vers les éléments de travail](graphql/epic_work_items_api_migration_guide.md). Ce changement est un changement cassant.

Chaque appel d'API à un epic doit être authentifié.

Si un utilisateur n'est pas membre d'un groupe privé, une requête `GET` sur ce groupe renvoie un code de statut `404`.

Si la fonctionnalité epics n'est pas disponible, un code de statut `403` est renvoyé.

## ID d'Epic hérités et ID WorkItem {#legacy-epic-ids-and-workitem-ids}

L'ID d'Epic hérité n'est pas le même que l'ID WorkItem. Seul le `iid` correspond. Cependant, pour récupérer l'ID WorkItem correspondant à un epic, la réponse inclut un `work_item_id`.

Cet ID peut être utilisé pour l'API GraphQL WorkItem, par ex. le `work_item_id` correspondrait à l'ID global `gid://gitlab/WorkItem/123` dans l'API GraphQL WorkItem.

## API des tickets d'epic {#epic-issues-api}

L'[API des tickets d'epic](epic_issues.md) vous permet d'interagir avec les tickets associés à un epic.

## Intégration des dates de jalon {#milestone-dates-integration}

Étant donné que la date de début et la date d'échéance peuvent être dynamiquement extraites des jalons de tickets associés, des champs supplémentaires s'affichent lorsque l'utilisateur dispose des permissions de modification. Ceux-ci comprennent deux champs booléens `start_date_is_fixed` et `due_date_is_fixed`, et quatre champs de date `start_date_fixed`, `start_date_from_inherited_source`, `due_date_fixed` et `due_date_from_inherited_source`.

- `end_date` a été déprécié en faveur de `due_date`.
- `start_date_from_milestones` a été déprécié en faveur de `start_date_from_inherited_source`
- `due_date_from_milestones` a été déprécié en faveur de `due_date_from_inherited_source`

## Répertorier tous les epics d'un groupe {#list-all-group-epics}

Répertorie tous les epics pour un groupe spécifié et ses sous-groupes.

Les réponses sont [paginées](rest/_index.md#pagination) et renvoient 20 résultats par défaut.

> [!note]
> `references.relative` est relatif au groupe depuis lequel l'epic est demandé. Lorsqu'un epic est récupéré depuis son groupe d'origine, le format `relative` est le même que le format `short`. Lorsqu'un epic est demandé entre des groupes, le format `relative` est censé être le même que le format `full`.

```plaintext
GET /groups/:id/epics
GET /groups/:id/epics?author_id=5
GET /groups/:id/epics?labels=bug,reproduced
GET /groups/:id/epics?state=opened
```

| Attribut           | Type             | Obligatoire   | Description                                                                                                                 |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------- |
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe               |
| `author_id`         | entier          | non         | Renvoyer les epics créés par l'utilisateur avec l'`id` donné                                                                                 |
| `author_username`   | string           | non         | Renvoyer les epics créés par l'utilisateur avec le `username` donné. |
| `labels`            | string           | non         | Renvoyer les epics correspondant à une liste de noms de labels séparés par des virgules. Les noms de labels du groupe de l'epic ou d'un groupe parent peuvent être utilisés |
| `with_labels_details` | boolean        | non         | Si `true`, la réponse renvoie plus de détails pour chaque label dans le champ labels : `:name`, `:color`, `:description`, `:description_html`, `:text_color`. La valeur par défaut est `false`. |
| `order_by`          | string           | non         | Renvoyer les epics classés par les champs `created_at`, `updated_at` ou `title`. La valeur par défaut est `created_at`                              |
| `sort`              | string           | non         | Renvoyer les epics triés dans l'ordre `asc` ou `desc`. La valeur par défaut est `desc`                                                             |
| `search`            | string           | non         | Rechercher des epics par rapport à leur `title` et `description`                                                                        |
| `state`             | string           | non         | Rechercher des epics par rapport à leur `state`, filtres possibles : `opened`, `closed` et `all`, valeur par défaut : `all`                          |
| `created_after`     | datetime         | non         | Renvoyer les epics créés à la date donnée ou après. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`) |
| `created_before`    | datetime         | non         | Renvoyer les epics créés à la date donnée ou avant. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`) |
| `updated_after`     | datetime         | non         | Renvoyer les epics mis à jour à la date donnée ou après. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`) |
| `updated_before`    | datetime         | non         | Renvoyer les epics mis à jour à la date donnée ou avant. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`) |
| `include_ancestor_groups` | boolean    | non         | Inclure les epics des ancêtres du groupe demandé. La valeur par défaut est `false`                                                      |
| `include_descendant_groups` | boolean  | non         | Inclure les epics des descendants du groupe demandé. La valeur par défaut est `true`                                                     |
| `my_reaction_emoji` | string           | non         | Renvoyer les epics auxquels l'utilisateur authentifié a réagi avec l'emoji donné. `None` renvoie les epics sans réaction. `Any` renvoie les epics ayant reçu au moins une réaction. |
| `not` | Hash | non | Renvoyer les epics qui ne correspondent pas aux paramètres fournis. Accepte : `author_id`, `author_username` et `labels`. |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics"
```

Exemple de réponse :

```json
[
  {
  "id": 29,
  "work_item_id": 1032,
  "iid": 4,
  "group_id": 7,
  "parent_id": 23,
  "parent_iid": 3,
  "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "state": "opened",
  "confidential": "false",
  "web_url": "http://gitlab.example.com/groups/test/-/epics/4",
  "reference": "&4",
  "references": {
    "short": "&4",
    "relative": "&4",
    "full": "test&4"
  },
  "author": {
    "id": 10,
    "name": "Lu Mayer",
    "username": "kam",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/kam"
  },
  "start_date": null,
  "start_date_is_fixed": false,
  "start_date_fixed": null,
  "start_date_from_milestones": null,       //deprecated in favor of start_date_from_inherited_source
  "start_date_from_inherited_source": null,
  "end_date": "2018-07-31",                 //deprecated in favor of due_date
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31", //deprecated in favor of start_date_from_inherited_source
  "due_date_from_inherited_source": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "closed_at": "2018-08-18T12:22:05.239Z",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "color": "#1068bf",
  "_links":{
      "self": "http://gitlab.example.com/api/v4/groups/7/epics/4",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/7/epics/4/issues",
      "group":"http://gitlab.example.com/api/v4/groups/7",
      "parent":"http://gitlab.example.com/api/v4/groups/7/epics/3"
  }
  },
  {
  "id": 50,
  "work_item_id": 1035,
  "iid": 35,
  "group_id": 17,
  "parent_id": 19,
  "parent_iid": 1,
  "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "state": "opened",
  "web_url": "http://gitlab.example.com/groups/test/sample/-/epics/35",
  "reference": "&4",
  "references": {
    "short": "&4",
    "relative": "sample&4",
    "full": "test/sample&4"
  },
  "author": {
    "id": 10,
    "name": "Lu Mayer",
    "username": "kam",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/kam"
  },
  "start_date": null,
  "start_date_is_fixed": false,
  "start_date_fixed": null,
  "start_date_from_milestones": null,       //deprecated in favor of start_date_from_inherited_source
  "start_date_from_inherited_source": null,
  "end_date": "2018-07-31",                 //deprecated in favor of due_date
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31", //deprecated in favor of start_date_from_inherited_source
  "due_date_from_inherited_source": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "closed_at": "2018-08-18T12:22:05.239Z",
  "imported": false,
  "imported_from": "none",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "color": "#1068bf",
  "_links":{
      "self": "http://gitlab.example.com/api/v4/groups/17/epics/35",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/17/epics/35/issues",
      "group":"http://gitlab.example.com/api/v4/groups/17",
      "parent":"http://gitlab.example.com/api/v4/groups/17/epics/1"
  }
  }
]
```

## Récupérer un epic {#retrieve-an-epic}

Récupère un epic spécifié pour un groupe.

```plaintext
GET /groups/:id/epics/:epic_iid
```

| Attribut           | Type             | Obligatoire   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe                |
| `epic_iid`          | entier ou chaîne   | oui        | L'ID interne de l'epic.  |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5"
```

Exemple de réponse :

```json
{
  "id": 30,
  "work_item_id": 1099,
  "iid": 5,
  "group_id": 7,
  "parent_id": null,
  "parent_iid": null,
  "title": "Ea cupiditate dolores ut vero consequatur quasi veniam voluptatem et non.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "state": "opened",
  "imported": false,
  "imported_from": "none",
  "web_url": "http://gitlab.example.com/groups/test/-/epics/5",
  "reference": "&5",
  "references": {
    "short": "&5",
    "relative": "&5",
    "full": "test&5"
  },
  "author":{
    "id": 7,
    "name": "Pamella Huel",
    "username": "arnita",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/arnita"
  },
  "start_date": null,
  "start_date_is_fixed": false,
  "start_date_fixed": null,
  "start_date_from_milestones": null,       //deprecated in favor of start_date_from_inherited_source
  "start_date_from_inherited_source": null,
  "end_date": "2018-07-31",                 //deprecated in favor of due_date
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31", //deprecated in favor of start_date_from_inherited_source
  "due_date_from_inherited_source": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "closed_at": "2018-08-18T12:22:05.239Z",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "color": "#1068bf",
  "subscribed": true,
  "_links":{
      "self": "http://gitlab.example.com/api/v4/groups/7/epics/5",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/7/epics/5/issues",
      "group":"http://gitlab.example.com/api/v4/groups/7",
      "parent": null
  }
}
```

## Créer un epic {#create-an-epic}

Crée un epic pour un groupe spécifié.

> [!note]
> À partir de GitLab [11.3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/6448), `start_date` et `end_date` ne doivent plus être attribués directement, car ils représentent désormais des valeurs composites. Vous pouvez le configurer via les champs `*_is_fixed` et `*_fixed` à la place.

```plaintext
POST /groups/:id/epics
```

| Attribut           | Type             | Obligatoire   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe                |
| `title`             | string           | oui        | Le titre de l'epic |
| `labels`            | string           | non         | La liste de labels séparés par des virgules |
| `description`       | string           | non         | La description de l'epic. Limité à 1 048 576 caractères.  |
| `color`             | string           | non         | La couleur de l'epic. Masqué derrière un feature flag nommé `epic_highlight_color` (désactivé par défaut) |
| `confidential`      | boolean          | non         | Indique si l'epic doit être confidentiel |
| `created_at`        | string           | non         | Date de création de l'epic. Chaîne de date et heure, au format ISO 8601, par exemple `2016-03-11T03:45:40Z` . Nécessite des privilèges d'administrateur ou de propriétaire de projet/groupe |
| `start_date_is_fixed` | boolean        | non         | Indique si la date de début doit être extraite de `start_date_fixed` ou des jalons |
| `start_date_fixed`  | string           | non         | La date de début fixe d'un epic |
| `due_date_is_fixed` | boolean          | non         | Indique si la date d'échéance doit être extraite de `due_date_fixed` ou des jalons |
| `due_date_fixed`    | string           | non         | La date d'échéance fixe d'un epic |
| `parent_id`         | entier ou chaîne   | non         | L'ID d'un epic parent |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics?title=Epic&description=Epic%20description&parent_id=29"
```

Exemple de réponse :

```json
{
  "id": 33,
  "work_item_id": 1020,
  "iid": 6,
  "group_id": 7,
  "parent_id": 29,
  "parent_iid": 4,
  "title": "Epic",
  "description": "Epic description",
  "state": "opened",
  "imported": false,
  "imported_from": "none",
  "confidential": "false",
  "web_url": "http://gitlab.example.com/groups/test/-/epics/6",
  "reference": "&6",
  "references": {
    "short": "&6",
    "relative": "&6",
    "full": "test&6"
  },
  "author": {
    "name" : "Alexandra Bashirian",
    "avatar_url" : null,
    "state" : "active",
    "web_url" : "https://gitlab.example.com/eileen.lowe",
    "id" : 18,
    "username" : "eileen.lowe"
  },
  "start_date": null,
  "start_date_is_fixed": false,
  "start_date_fixed": null,
  "start_date_from_milestones": null,       //deprecated in favor of start_date_from_inherited_source
  "start_date_from_inherited_source": null,
  "end_date": "2018-07-31",                 //deprecated in favor of due_date
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31", //deprecated in favor of start_date_from_inherited_source
  "due_date_from_inherited_source": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "closed_at": "2018-08-18T12:22:05.239Z",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "color": "#1068bf",
  "_links":{
    "self": "http://gitlab.example.com/api/v4/groups/7/epics/6",
    "epic_issues": "http://gitlab.example.com/api/v4/groups/7/epics/6/issues",
    "group":"http://gitlab.example.com/api/v4/groups/7",
    "parent": "http://gitlab.example.com/api/v4/groups/7/epics/4"
  }
}
```

## Mettre à jour un epic {#update-an-epic}

Met à jour un epic spécifié pour un groupe.

```plaintext
PUT /groups/:id/epics/:epic_iid
```

| Attribut           | Type             | Obligatoire   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe                |
| `epic_iid`          | entier ou chaîne   | oui        | L'ID interne de l'epic  |
| `add_labels`        | string           | non         | Noms de labels séparés par des virgules à ajouter à un ticket. |
| `confidential`      | boolean          | non         | Indique si l'epic doit être confidentiel |
| `description`       | string           | non         | La description d'un epic. Limité à 1 048 576 caractères.  |
| `due_date_fixed`    | string           | non         | La date d'échéance fixe d'un epic |
| `due_date_is_fixed` | boolean          | non         | Indique si la date d'échéance doit être extraite de `due_date_fixed` ou des jalons |
| `labels`            | string           | non         | Noms de labels séparés par des virgules pour un ticket. Définir sur une chaîne vide pour annuler l'attribution de tous les labels. |
| `parent_id`         | entier ou chaîne   | non         | L'ID d'un epic parent. |
| `remove_labels`     | string           | non         | Noms de labels séparés par des virgules à supprimer d'un ticket. |
| `start_date_fixed`  | string           | non         | La date de début fixe d'un epic |
| `start_date_is_fixed` | boolean        | non         | Indique si la date de début doit être extraite de `start_date_fixed` ou des jalons |
| `state_event`       | string           | non         | Événement d'état pour un epic. Définir `close` pour fermer l'epic et `reopen` pour le rouvrir |
| `title`             | string           | non         | Le titre d'un epic |
| `updated_at`        | string           | non         | Date de mise à jour de l'epic. Chaîne de date et heure, au format ISO 8601, par exemple `2016-03-11T03:45:40Z` . Nécessite des privilèges d'administrateur ou de propriétaire de projet/groupe |
| `color`             | string           | non         | La couleur de l'epic. Masqué derrière un feature flag nommé `epic_highlight_color` (désactivé par défaut) |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5?title=New%20Title&parent_id=29"
```

Exemple de réponse :

```json
{
  "id": 33,
  "work_item_id": 1019,
  "iid": 6,
  "group_id": 7,
  "parent_id": 29,
  "parent_iid": 4,
  "title": "New Title",
  "description": "Epic description",
  "state": "opened",
  "imported": false,
  "imported_from": "none",
  "confidential": "false",
  "web_url": "http://gitlab.example.com/groups/test/-/epics/6",
  "reference": "&6",
  "references": {
    "short": "&6",
    "relative": "&6",
    "full": "test&6"
  },
  "author": {
    "name" : "Alexandra Bashirian",
    "avatar_url" : null,
    "state" : "active",
    "web_url" : "https://gitlab.example.com/eileen.lowe",
    "id" : 18,
    "username" : "eileen.lowe"
  },
  "start_date": null,
  "start_date_is_fixed": false,
  "start_date_fixed": null,
  "start_date_from_milestones": null,       //deprecated in favor of start_date_from_inherited_source
  "start_date_from_inherited_source": null,
  "end_date": "2018-07-31",                 //deprecated in favor of due_date
  "due_date": "2018-07-31",
  "due_date_is_fixed": false,
  "due_date_fixed": null,
  "due_date_from_milestones": "2018-07-31", //deprecated in favor of start_date_from_inherited_source
  "due_date_from_inherited_source": "2018-07-31",
  "created_at": "2018-07-17T13:36:22.770Z",
  "updated_at": "2018-07-18T12:22:05.239Z",
  "closed_at": "2018-08-18T12:22:05.239Z",
  "labels": [],
  "upvotes": 4,
  "downvotes": 0,
  "color": "#1068bf"
}
```

## Supprimer un epic {#delete-an-epic}

{{< history >}}

- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/452189) dans GitLab 16.11. Dans GitLab 16.10 et versions antérieures, si vous supprimez un epic, tous ses epics enfants et leurs descendants sont également supprimés. Si nécessaire, vous pouvez supprimer les epics enfants de l'epic parent avant de le supprimer.

{{< /history >}}

Supprime un epic spécifié d'un groupe.

```plaintext
DELETE /groups/:id/epics/:epic_iid
```

| Attribut           | Type             | Obligatoire   | Description                                                                            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe                |
| `epic_iid`          | entier ou chaîne   | oui        | L'ID interne de l'epic.  |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5"
```

## Créer un élément de la liste de tâches pour un epic {#create-a-to-do-item-for-an-epic}

Crée un élément de la liste de tâches pour l'utilisateur actuel sur un epic spécifié. Si un élément de la liste de tâches existe déjà pour l'utilisateur sur cet epic, le code de statut 304 est renvoyé.

```plaintext
POST /groups/:id/epics/:epic_iid/todo
```

| Attribut   | Type    | Obligatoire | Description                          |
|-------------|---------|----------|--------------------------------------|
| `id`        | entier ou chaîne | oui   | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe  |
| `epic_iid` | entier | oui          | L'ID interne de l'epic d'un groupe |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/todo"
```

Exemple de réponse :

```json
{
  "id": 112,
  "group": {
    "id": 1,
    "name": "Gitlab",
    "path": "gitlab",
    "kind": "group",
    "full_path": "base/gitlab",
    "parent_id": null
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
  "target_type": "epic",
  "target": {
    "id": 30,
    "iid": 5,
    "group_id": 1,
    "title": "Ea cupiditate dolores ut vero consequatur quasi veniam voluptatem et non.",
    "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
    "author":{
      "id": 7,
      "name": "Pamella Huel",
      "username": "arnita",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/a2f5c6fcef64c9c69cb8779cb292be1b?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/arnita"
    },
    "web_url": "http://gitlab.example.com/groups/test/-/epics/5",
    "reference": "&5",
    "references": {
      "short": "&5",
      "relative": "&5",
      "full": "test&5"
    },
    "start_date": null,
    "end_date": null,
    "created_at": "2018-01-21T06:21:13.165Z",
    "updated_at": "2018-01-22T12:41:41.166Z",
    "closed_at": "2018-08-18T12:22:05.239Z"
  },
  "target_url": "https://gitlab.example.com/groups/epics/5",
  "body": "Vel voluptas atque dicta mollitia adipisci qui at.",
  "state": "pending",
  "created_at": "2016-07-01T11:09:13.992Z"
}
```
