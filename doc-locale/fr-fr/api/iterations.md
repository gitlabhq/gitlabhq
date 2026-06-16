---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des itérations de projet
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour accéder aux [itérations de projet](../user/group/iterations/_index.md).

Pour les itérations de groupe, utilisez l'[API des itérations de groupe](group_iterations.md).

Nous n'avons plus d'itérations au niveau du projet, mais vous pouvez utiliser cet endpoint pour récupérer les itérations des groupes ancêtres du projet.

## Répertorier toutes les itérations de projet {#list-all-project-iterations}

Répertorie toutes les itérations pour un projet spécifié.

Les itérations créées par **Activer la programmation automatique** dans les [cadences d'itération](../user/group/iterations/_index.md#iteration-cadences) renvoient `null` pour les champs `title` et `description`.

```plaintext
GET /projects/:id/iterations
GET /projects/:id/iterations?state=opened
GET /projects/:id/iterations?state=closed
GET /projects/:id/iterations?search=version
GET /projects/:id/iterations?include_ancestors=false
GET /projects/:id/iterations?include_descendants=true
GET /projects/:id/iterations?updated_before=2013-10-02T09%3A24%3A18Z
GET /projects/:id/iterations?updated_after=2013-10-02T09%3A24%3A18Z
```

| Attribut             | Type     | Obligatoire | Description |
| --------------------- | -------- | -------- | ----------- |
| `state`               | string   | non       | 'Renvoie les itérations `opened`, `upcoming`, `current`, `closed` ou `all`.'                       |
| `search`              | string   | non       | Renvoie uniquement les itérations dont le titre correspond à la chaîne fournie.                              |
| `in`                  | tableau de chaînes | non | Champs dans lesquels la recherche approximative doit être effectuée avec la requête donnée dans l'argument `search`. Les options disponibles sont `title` et `cadence_title`. La valeur par défaut est `[title]`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/350991) dans GitLab 16.2. |
| `include_ancestors`   | boolean  | non       | Inclut les itérations pour le groupe parent et ses ancêtres. La valeur par défaut est `true`.                    |
| `include_descendants` | boolean  | non       | Inclut les itérations pour le groupe parent et ses descendants. La valeur par défaut est `false`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135764) dans GitLab 16.7. |
| `updated_before`      | datetime | non       | Renvoie uniquement les itérations mises à jour avant la datetime donnée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/378662) dans GitLab 15.10. |
| `updated_after`       | datetime | non       | Renvoie uniquement les itérations mises à jour après la datetime donnée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`). [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/378662) dans GitLab 15.10. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/iterations"
```

Exemple de réponse :

```json
[
  {
    "id": 53,
    "iid": 13,
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
