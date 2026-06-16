---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des itérations de groupe
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour accéder aux [itérations de groupe](../user/group/iterations/_index.md).

Pour les itérations de projet, utilisez l'[API des itérations de projet](iterations.md).

## Lister toutes les itérations de groupe {#list-all-group-iterations}

Liste toutes les itérations pour un groupe spécifié.

Les itérations créées par **Activer la programmation automatique** dans les [cadences d'itération](../user/group/iterations/_index.md#iteration-cadences) renvoient `null` pour les champs `title` et `description`.

```plaintext
GET /groups/:id/iterations
GET /groups/:id/iterations?state=opened
GET /groups/:id/iterations?state=closed
GET /groups/:id/iterations?search=version
GET /groups/:id/iterations?include_ancestors=false
GET /groups/:id/iterations?include_descendants=true
GET /groups/:id/iterations?updated_before=2013-10-02T09%3A24%3A18Z
GET /groups/:id/iterations?updated_after=2013-10-02T09%3A24%3A18Z
```

| Attribut             | Type     | Obligatoire | Description |
| --------------------- | -------- | -------- | ----------- |
| `state`               | string   | non       | 'Renvoie les itérations `opened`, `upcoming`, `current`, `closed` ou `all`.' |
| `search`              | string   | non       | Renvoie uniquement les itérations dont le titre correspond à la chaîne fournie.                              |
| `in`                  | tableau de chaînes | non | Champs dans lesquels la recherche approximative doit être effectuée avec la requête donnée dans l'argument `search`. Les options disponibles sont `title` et `cadence_title`. La valeur par défaut est `[title]`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/350991) dans GitLab 16.2. |
| `include_ancestors`   | boolean  | non       | Inclure les itérations pour le groupe et ses ancêtres. La valeur par défaut est `true`.                    |
| `include_descendants` | boolean  | non       | Inclure les itérations pour le groupe et ses descendants. La valeur par défaut est `false`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135764) dans GitLab 16.7. |
| `updated_before`      | datetime | non       | Renvoie uniquement les itérations mises à jour avant la date et l'heure données. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/378662) dans GitLab 15.10. |
| `updated_after`       | datetime | non       | Renvoie uniquement les itérations mises à jour après la date et l'heure données. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/378662) dans GitLab 15.10. |

Exemple de requête :

```shell
  curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/iterations"
```

Exemple de réponse :

```json
[
  {
    "id": 53,
    "iid": 13,
    "sequence": 1,
    "group_id": 5,
    "title": "Iteration II",
    "description": "Ipsum Lorem ipsum",
    "state": 2,
    "created_at": "2020-01-27T05:07:12.573Z",
    "updated_at": "2020-01-27T05:07:12.573Z",
    "due_date": "2020-02-01",
    "start_date": "2020-02-14",
    "web_url": "http://gitlab.example.com/groups/my-group/-/iterations/13"
  }
]
```
