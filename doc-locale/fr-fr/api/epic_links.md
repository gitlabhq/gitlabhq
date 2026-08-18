---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Epic Links (obsolète)
description: "Consultez la documentation de l'API REST GitLab pour les Epic Links. Découvrez comment gérer, créer et supprimer par programmation des relations d'epic parent et enfant de manière efficace."
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> L'API REST Epics a été [dépréciée](https://gitlab.com/gitlab-org/gitlab/-/issues/460668) dans GitLab 17.0 et sa suppression est prévue dans la v5 de l'API. De GitLab 17.4 à 18.0, si [le nouveau look pour les epics](../user/group/epics/_index.md#epics-as-work-items) est activé, et dans GitLab 18.1 et versions ultérieures, utilisez plutôt l'API Work Items. Pour plus d'informations, consultez [migrer les API d'epic vers les éléments de travail](graphql/epic_work_items_api_migration_guide.md). Ce changement est un changement majeur.

Gère les [relations d'epic parent-enfant](../user/work_items/child_items.md#work-with-multi-level-hierarchies).

Chaque appel d'API REST à `epic_links` doit être authentifié.

Si un utilisateur n'est pas membre d'un groupe privé, une requête `GET` sur ce groupe renvoie un code de statut `404`.

Les Epics multi-niveaux sont disponibles uniquement dans [GitLab Ultimate](https://about.gitlab.com/pricing/). Si la fonctionnalité Multi-level Epics n'est pas disponible, un code de statut `403` est retourné.

## Lister tous les epics enfants d'un epic {#list-all-child-epics-of-an-epic}

Lister tous les epics enfants d'un epic.

```plaintext
GET /groups/:id/epics/:epic_iid/epics
```

| Attribut  | Type           | Obligatoire | Description                                                                                                   |
| ---------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------- |
| `id`       | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `epic_iid` | entier        | oui      | L'ID interne de l'epic.                                                                                  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/epics"
```

Exemple de réponse :

```json
[
  {
    "id": 29,
    "iid": 6,
    "group_id": 1,
    "parent_id": 5,
    "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
    "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
    "author": {
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
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
    "labels": []
  }
]
```

## Assigner un epic enfant {#assign-a-child-epic}

Crée une association entre deux epics, en désignant l'un comme l'epic parent et l'autre comme l'epic enfant. Un epic parent peut avoir plusieurs epics enfants. Si le nouvel epic enfant appartenait déjà à un autre epic, il est désassigné de ce parent précédent.

```plaintext
POST /groups/:id/epics/:epic_iid/epics/:child_epic_id
```

| Attribut       | Type           | Obligatoire | Description                                                                                                        |
| --------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------ |
| `id`            | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe      |
| `epic_iid`      | entier        | oui      | L'ID interne de l'epic.                                                                                       |
| `child_epic_id` | entier        | oui      | L'ID global de l'epic enfant. L'ID interne ne peut pas être utilisé car il peut entrer en conflit avec des epics d'autres groupes. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/epics/6"

```

Exemple de réponse :

```json
{
  "id": 6,
  "iid": 38,
  "group_id": 1,
  "parent_id": 5,
  "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "author": {
    "id": 10,
    "name": "Lu Mayer",
    "username": "kam",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
    "web_url": "http://localhost:3001/kam"
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
  "labels": []
}
```

## Créer et assigner un epic enfant {#create-and-assign-a-child-epic}

Crée un nouvel epic et l'associe à l'epic parent fourni. La réponse est un objet `LinkedEpic`.

```plaintext
POST /groups/:id/epics/:epic_iid/epics
```

| Attribut       | Type           | Obligatoire | Description                                                                                                        |
| --------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------ |
| `id`            | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe      |
| `epic_iid`      | entier        | oui      | L'ID interne de l'epic (futur parent).                                                                       |
| `title`         | string         | oui      | Le titre d'un epic nouvellement créé.                                                                                 |
| `confidential`  | boolean        | non       | Indique si l'epic doit être confidentiel. Le paramètre est ignoré si le feature flag `confidential_epics` est désactivé. Par défaut, il correspond à l'état de confidentialité de l'epic parent.  |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/5/epics?title=Newpic"
```

Exemple de réponse :

```json
{
  "id": 24,
  "iid": 2,
  "title": "child epic",
  "group_id": 49,
  "parent_id": 23,
  "has_children": false,
  "has_issues": false,
  "reference":  "&2",
  "url": "http://localhost/groups/group16/-/epics/2",
  "relation_url": "http://localhost/groups/group16/-/epics/1/links/24"
}
```

## Réordonner un epic enfant {#re-order-a-child-epic}

```plaintext
PUT /groups/:id/epics/:epic_iid/epics/:child_epic_id
```

| Attribut        | Type           | Obligatoire | Description                                                                                                        |
| ---------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------ |
| `id`             | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe.     |
| `epic_iid`       | entier        | oui      | L'ID interne de l'epic.                                                                                       |
| `child_epic_id`  | entier        | oui      | L'ID global de l'epic enfant. L'ID interne ne peut pas être utilisé car il peut entrer en conflit avec des epics d'autres groupes. |
| `move_before_id` | entier        | non       | L'ID global d'un epic frère qui doit être placé avant l'epic enfant.                                       |
| `move_after_id`  | entier        | non       | L'ID global d'un epic frère qui doit être placé après l'epic enfant.                                        |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/4/epics/5"
```

Exemple de réponse :

```json
[
  {
    "id": 29,
    "iid": 6,
    "group_id": 1,
    "parent_id": 5,
    "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
    "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
    "author": {
      "id": 10,
      "name": "Lu Mayer",
      "username": "kam",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
      "web_url": "http://localhost:3001/kam"
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
    "labels": []
  }
]
```

## Désassigner un epic enfant {#unassign-a-child-epic}

Désassigner un epic enfant d'un epic parent.

```plaintext
DELETE /groups/:id/epics/:epic_iid/epics/:child_epic_id
```

| Attribut       | Type           | Obligatoire | Description                                                                                                        |
| --------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------ |
| `id`            | entier ou chaîne | oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe.     |
| `epic_iid`      | entier        | oui      | L'ID interne de l'epic.                                                                                       |
| `child_epic_id` | entier        | oui      | L'ID global de l'epic enfant. L'ID interne ne peut pas être utilisé car il peut entrer en conflit avec des epics d'autres groupes. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/epics/4/epics/5"
```

Exemple de réponse :

```json
{
  "id": 5,
  "iid": 38,
  "group_id": 1,
  "parent_id": null,
  "title": "Accusamus iste et ullam ratione voluptatem omnis debitis dolor est.",
  "description": "Molestias dolorem eos vitae expedita impedit necessitatibus quo voluptatum.",
  "author": {
    "id": 10,
    "name": "Lu Mayer",
    "username": "kam",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/018729e129a6f31c80a6327a30196823?s=80&d=identicon",
    "web_url": "http://localhost:3001/kam"
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
  "labels": []
}
```
