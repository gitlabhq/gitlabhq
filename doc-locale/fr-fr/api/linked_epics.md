---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des epics liés (obsolète)
---

{{< details >}}

- Édition : Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/352493) dans GitLab 14.9 [avec un flag](../administration/feature_flags/_index.md) nommé `related_epics_widget`. Activé par défaut.
- [Feature flag `related_epics_widget`](https://gitlab.com/gitlab-org/gitlab/-/issues/357089) supprimé dans GitLab 15.0.

{{< /history >}}

> [!warning]
> L'API REST Epics a été [dépréciée](https://gitlab.com/gitlab-org/gitlab/-/issues/460668) dans GitLab 17.0 et sa suppression est prévue dans la v5 de l'API. De GitLab 17.4 à 18.0, si [le nouvel aspect des epics](../user/group/epics/_index.md#epics-as-work-items) est activé, et dans GitLab 18.1 et versions ultérieures, utilisez plutôt l'API Work Items. Pour plus d'informations, voir [migrer les API epics vers les éléments de travail](graphql/epic_work_items_api_migration_guide.md). Ce changement est un changement cassant.

Si la fonctionnalité Related Epics n'est pas disponible dans votre plan GitLab, un code de statut `403` est retourné.

## Lister tous les liens d'epics liés pour un groupe {#list-all-related-epic-links-for-a-group}

Liste tous les liens d'epics liés pour un groupe spécifié et ses sous-groupes. L'utilisateur doit avoir accès à la fois à `source_epic` et à `target_epic` pour visualiser le lien d'epic lié.

```plaintext
GET /groups/:id/related_epic_links
```

Attributs pris en charge :

| Attribut  | Type           | Obligatoire               | Description                                                               |
| ---------- | -------------- | ---------------------- | ------------------------------------------------------------------------- |
| `id`       | entier ou chaîne | Oui | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `created_after` | string | non | Retourne les liens d'epics liés créés à partir de la date/heure donnée ou après. Format : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`)  |
| `created_before` | string | non | Retourne les liens d'epics liés créés jusqu'à la date/heure donnée ou avant. Format : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) |
| `updated_after` | string | non | Retourne les liens d'epics liés mis à jour à partir de la date/heure donnée ou après. Format : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`)  |
| `updated_before` | string | non | Retourne les liens d'epics liés mis à jour jusqu'à la date/heure donnée ou avant. Format : ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/related_epic_links"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "created_at": "2022-01-31T15:10:44.988Z",
    "updated_at": "2022-01-31T15:10:44.988Z",
    "link_type": "relates_to",
    "source_epic": {
      "id": 21,
      "iid": 1,
      "color": "#1068bf",
      "text_color": "#FFFFFF",
      "group_id": 26,
      "parent_id": null,
      "parent_iid": null,
      "title": "Aspernatur recusandae distinctio omnis et qui est iste.",
      "description": "some description",
      "confidential": false,
      "author": {
        "id": 15,
        "username": "trina",
        "name": "Theresia Robel",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/085e28df717e16484cbf6ceca75e9a93?s=80&d=identicon",
        "web_url": "http://gitlab.example.com/trina"
      },
      "start_date": null,
      "end_date": null,
      "due_date": null,
      "state": "opened",
      "web_url": "http://gitlab.example.com/groups/flightjs/-/epics/1",
      "references": {
        "short": "&1",
        "relative": "&1",
        "full": "flightjs&1"
      },
      "created_at": "2022-01-31T15:10:44.988Z",
      "updated_at": "2022-03-16T09:32:35.712Z",
      "closed_at": null,
      "labels": [],
      "upvotes": 0,
      "downvotes": 0,
      "_links": {
        "self": "http://gitlab.example.com/api/v4/groups/26/epics/1",
        "epic_issues": "http://gitlab.example.com/api/v4/groups/26/epics/1/issues",
        "group": "http://gitlab.example.com/api/v4/groups/26",
        "parent": null
      }
    },
    "target_epic": {
      "id": 25,
      "iid": 5,
      "color": "#1068bf",
      "text_color": "#FFFFFF",
      "group_id": 26,
      "parent_id": null,
      "parent_iid": null,
      "title": "Aut assumenda id nihil distinctio fugiat vel numquam est.",
      "description": "some description",
      "confidential": false,
      "author": {
        "id": 3,
        "username": "valerie",
        "name": "Erika Wolf",
        "state": "active",
        "avatar_url": "https://www.gravatar.com/avatar/9ef7666abb101418a4716a8ed4dded80?s=80&d=identicon",
        "web_url": "http://gitlab.example.com/valerie"
      },
      "start_date": null,
      "end_date": null,
      "due_date": null,
      "state": "opened",
      "web_url": "http://gitlab.example.com/groups/flightjs/-/epics/5",
      "references": {
        "short": "&5",
        "relative": "&5",
        "full": "flightjs&5"
      },
      "created_at": "2022-01-31T15:10:45.080Z",
      "updated_at": "2022-03-16T09:32:35.842Z",
      "closed_at": null,
      "labels": [],
      "upvotes": 0,
      "downvotes": 0,
      "_links": {
        "self": "http://gitlab.example.com/api/v4/groups/26/epics/5",
        "epic_issues": "http://gitlab.example.com/api/v4/groups/26/epics/5/issues",
        "group": "http://gitlab.example.com/api/v4/groups/26",
        "parent": null
      }
    },
  }
]
```

## Lister tous les epics liés pour un epic {#list-all-linked-epics-for-an-epic}

Liste tous les epics liés pour un epic spécifié.

```plaintext
GET /groups/:id/epics/:epic_iid/related_epics
```

Attributs pris en charge :

| Attribut  | Type           | Obligatoire               | Description                                                               |
| ---------- | -------------- | ---------------------- | ------------------------------------------------------------------------- |
| `epic_iid` | entier        | Oui | ID interne de l'epic d'un groupe                                             |
| `id`       | entier ou chaîne | Oui | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |

Exemple de requête :

```shell
curl --request GET \
 --header "PRIVATE-TOKEN: <your_access_token>" \
 --url "https://gitlab.example.com/api/v4/groups/:id/epics/:epic_iid/related_epics"
```

Exemple de réponse :

```json
[
   {
      "id":2,
      "iid":2,
      "color":"#1068bf",
      "text_color":"#FFFFFF",
      "group_id":2,
      "parent_id":null,
      "parent_iid":null,
      "title":"My title 2",
      "description":null,
      "confidential":false,
      "author":{
         "id":3,
         "username":"user3",
         "name":"Sidney Jones4",
         "state":"active",
         "avatar_url":"https://www.gravatar.com/avatar/82797019f038ab535a84c6591e7bc936?s=80u0026d=identicon",
         "web_url":"http://localhost/user3"
      },
      "start_date":null,
      "end_date":null,
      "due_date":null,
      "state":"opened",
      "web_url":"http://localhost/groups/group1/-/epics/2",
      "references":{
         "short":"u00262",
         "relative":"u00262",
         "full":"group1u00262"
      },
      "created_at":"2022-03-10T18:35:24.479Z",
      "updated_at":"2022-03-10T18:35:24.479Z",
      "closed_at":null,
      "labels":[

      ],
      "upvotes":0,
      "downvotes":0,
      "_links":{
         "self":"http://localhost/api/v4/groups/2/epics/2",
         "epic_issues":"http://localhost/api/v4/groups/2/epics/2/issues",
         "group":"http://localhost/api/v4/groups/2",
         "parent":null
      },
      "related_epic_link_id":1,
      "link_type":"relates_to",
      "link_created_at":"2022-03-10T18:35:24.496+00:00",
      "link_updated_at":"2022-03-10T18:35:24.496+00:00"
   }
]
```

## Créer un lien d'epic lié {#create-a-related-epic-link}

{{< history >}}

- Le rôle minimum requis pour le groupe [a été modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/381308) de Reporter à Invité dans GitLab 15.8.

{{< /history >}}

Crée une relation bidirectionnelle entre deux epics. L'utilisateur doit avoir le rôle Invité, Planificateur, Reporter, Developer, Maintainer ou Owner pour les deux groupes.

```plaintext
POST /groups/:id/epics/:epic_iid/related_epics
```

Attributs pris en charge :

| Attribut           | Type           | Obligatoire                    | Description                           |
|---------------------|----------------|-----------------------------|---------------------------------------|
| `epic_iid`          | entier        | Oui      | ID interne de l'epic d'un groupe.        |
| `id`                | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `target_epic_iid`   | entier ou chaîne | Oui      | ID interne de l'epic d'un groupe cible. |
| `target_group_id`   | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du groupe cible](rest/_index.md#namespaced-paths). |
| `link_type`         | string         | Non      | Type de la relation (`relates_to`, `blocks`, `is_blocked_by`), par défaut `relates_to`. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/26/epics/1/related_epics?target_group_id=26&target_epic_iid=5"
```

Exemple de réponse :

```json
{
  "id": 1,
  "created_at": "2022-01-31T15:10:44.988Z",
  "updated_at": "2022-01-31T15:10:44.988Z",
  "link_type": "relates_to",
  "source_epic": {
    "id": 21,
    "iid": 1,
    "color": "#1068bf",
    "text_color": "#FFFFFF",
    "group_id": 26,
    "parent_id": null,
    "parent_iid": null,
    "title": "Aspernatur recusandae distinctio omnis et qui est iste.",
    "description": "some description",
    "confidential": false,
    "author": {
      "id": 15,
      "username": "trina",
      "name": "Theresia Robel",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/085e28df717e16484cbf6ceca75e9a93?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/trina"
    },
    "start_date": null,
    "end_date": null,
    "due_date": null,
    "state": "opened",
    "web_url": "http://gitlab.example.com/groups/flightjs/-/epics/1",
    "references": {
      "short": "&1",
      "relative": "&1",
      "full": "flightjs&1"
    },
    "created_at": "2022-01-31T15:10:44.988Z",
    "updated_at": "2022-03-16T09:32:35.712Z",
    "closed_at": null,
    "labels": [],
    "upvotes": 0,
    "downvotes": 0,
    "_links": {
      "self": "http://gitlab.example.com/api/v4/groups/26/epics/1",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/26/epics/1/issues",
      "group": "http://gitlab.example.com/api/v4/groups/26",
      "parent": null
    }
  },
  "target_epic": {
    "id": 25,
    "iid": 5,
    "color": "#1068bf",
    "text_color": "#FFFFFF",
    "group_id": 26,
    "parent_id": null,
    "parent_iid": null,
    "title": "Aut assumenda id nihil distinctio fugiat vel numquam est.",
    "description": "some description",
    "confidential": false,
    "author": {
      "id": 3,
      "username": "valerie",
      "name": "Erika Wolf",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/9ef7666abb101418a4716a8ed4dded80?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/valerie"
    },
    "start_date": null,
    "end_date": null,
    "due_date": null,
    "state": "opened",
    "web_url": "http://gitlab.example.com/groups/flightjs/-/epics/5",
    "references": {
      "short": "&5",
      "relative": "&5",
      "full": "flightjs&5"
    },
    "created_at": "2022-01-31T15:10:45.080Z",
    "updated_at": "2022-03-16T09:32:35.842Z",
    "closed_at": null,
    "labels": [],
    "upvotes": 0,
    "downvotes": 0,
    "_links": {
      "self": "http://gitlab.example.com/api/v4/groups/26/epics/5",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/26/epics/5/issues",
      "group": "http://gitlab.example.com/api/v4/groups/26",
      "parent": null
    }
  },
}
```

## Supprimer un lien d'epic lié {#delete-a-related-epic-link}

{{< history >}}

- Le rôle minimum requis pour le groupe [a été modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/381308) de Reporter à Invité dans GitLab 15.8.

{{< /history >}}

Supprime une relation bidirectionnelle entre deux epics spécifiés. L'utilisateur doit avoir le rôle Invité, Planificateur, Reporter, Developer, Maintainer ou Owner pour les deux groupes.

```plaintext
DELETE /groups/:id/epics/:epic_iid/related_epics/:related_epic_link_id
```

Attributs pris en charge :

| Attribut                | Type           | Obligatoire                    | Description                           |
|--------------------------|----------------|-----------------------------|---------------------------------------|
| `epic_iid`               | entier        | Oui      | ID interne de l'epic d'un groupe.        |
| `id`                     | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `related_epic_link_id`   | entier ou chaîne | Oui      | ID interne d'un lien d'epic lié. |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/26/epics/1/related_epics/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "created_at": "2022-01-31T15:10:44.988Z",
  "updated_at": "2022-01-31T15:10:44.988Z",
  "link_type": "relates_to",
  "source_epic": {
    "id": 21,
    "iid": 1,
    "color": "#1068bf",
    "text_color": "#FFFFFF",
    "group_id": 26,
    "parent_id": null,
    "parent_iid": null,
    "title": "Aspernatur recusandae distinctio omnis et qui est iste.",
    "description": "some description",
    "confidential": false,
    "author": {
      "id": 15,
      "username": "trina",
      "name": "Theresia Robel",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/085e28df717e16484cbf6ceca75e9a93?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/trina"
    },
    "start_date": null,
    "end_date": null,
    "due_date": null,
    "state": "opened",
    "web_url": "http://gitlab.example.com/groups/flightjs/-/epics/1",
    "references": {
      "short": "&1",
      "relative": "&1",
      "full": "flightjs&1"
    },
    "created_at": "2022-01-31T15:10:44.988Z",
    "updated_at": "2022-03-16T09:32:35.712Z",
    "closed_at": null,
    "labels": [],
    "upvotes": 0,
    "downvotes": 0,
    "_links": {
      "self": "http://gitlab.example.com/api/v4/groups/26/epics/1",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/26/epics/1/issues",
      "group": "http://gitlab.example.com/api/v4/groups/26",
      "parent": null
    }
  },
  "target_epic": {
    "id": 25,
    "iid": 5,
    "color": "#1068bf",
    "text_color": "#FFFFFF",
    "group_id": 26,
    "parent_id": null,
    "parent_iid": null,
    "title": "Aut assumenda id nihil distinctio fugiat vel numquam est.",
    "description": "some description",
    "confidential": false,
    "author": {
      "id": 3,
      "username": "valerie",
      "name": "Erika Wolf",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/9ef7666abb101418a4716a8ed4dded80?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/valerie"
    },
    "start_date": null,
    "end_date": null,
    "due_date": null,
    "state": "opened",
    "web_url": "http://gitlab.example.com/groups/flightjs/-/epics/5",
    "references": {
      "short": "&5",
      "relative": "&5",
      "full": "flightjs&5"
    },
    "created_at": "2022-01-31T15:10:45.080Z",
    "updated_at": "2022-03-16T09:32:35.842Z",
    "closed_at": null,
    "labels": [],
    "upvotes": 0,
    "downvotes": 0,
    "_links": {
      "self": "http://gitlab.example.com/api/v4/groups/26/epics/5",
      "epic_issues": "http://gitlab.example.com/api/v4/groups/26/epics/5/issues",
      "group": "http://gitlab.example.com/api/v4/groups/26",
      "parent": null
    }
  },
}
```
