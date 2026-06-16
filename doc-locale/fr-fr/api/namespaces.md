---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Espaces de nommage
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- La visibilité des champs liés à la facturation a changé dans GitLab 18.3 [avec un indicateur](../administration/feature_flags/_index.md) nommé `restrict_namespace_api_billing_fields`. Désactivé par défaut.
- Visibilité des champs liés à la facturation [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/565598) dans GitLab 18.9. L'indicateur de fonctionnalité `restrict_namespace_api_billing_fields` a été supprimé.

{{< /history >}}

Utilisez cette API pour interagir avec les espaces de nommage, une catégorie de ressources spéciale utilisée pour organiser les utilisateurs et les groupes. Pour plus d'informations, consultez [les espaces de nommage](../user/namespace/_index.md).

Cette API utilise la [pagination](rest/_index.md#pagination) pour filtrer les résultats.

## Répertorier tous les espaces de nommage {#list-all-namespaces}

{{< history >}}

- `top_level_only` [introduit](https://gitlab.com/gitlab-org/customers-gitlab-com/-/issues/7600) dans GitLab 16.8.

{{< /history >}}

Répertorie tous les espaces de nommage disponibles pour l'utilisateur actuel. Si l'utilisateur est un administrateur, ce point de terminaison renvoie tous les espaces de nommage de l'instance.

```plaintext
GET /namespaces
```

| Attribut          | Type    | Obligatoire | Description                                                                             |
|--------------------|---------|----------|-----------------------------------------------------------------------------------------|
| `search`           | string  | non       | Renvoie uniquement les espaces de nommage dont le nom ou le chemin contient la valeur spécifiée.         |
| `owned_only`       | boolean | non       | Si `true`, renvoie uniquement les espaces de nommage de l'utilisateur actuel.                                 |
| `top_level_only`   | boolean | non       | Dans GitLab 16.8 et les versions ultérieures, si `true`, renvoie uniquement les espaces de nommage de niveau supérieur.                 |
| `full_path_search` | boolean | non       | Si `true`, le paramètre `search` est comparé au chemin complet des espaces de nommage. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/namespaces"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "user1",
    "path": "user1",
    "kind": "user",
    "full_path": "user1",
    "parent_id": null,
    "avatar_url": "https://secure.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/user1",
    "billable_members_count": 1,
    "plan": "ultimate",
    "end_date": null,
    "trial_ends_on": null,
    "trial": false,
    "root_repository_size": 100,
    "projects_count": 3
  },
  {
    "id": 2,
    "name": "group1",
    "path": "group1",
    "kind": "group",
    "full_path": "group1",
    "parent_id": null,
    "avatar_url": null,
    "web_url": "https://gitlab.example.com/groups/group1",
    "members_count_with_descendants": 2,
    "billable_members_count": 2,
    "plan": "ultimate",
    "end_date": null,
    "trial_ends_on": null,
    "trial": false,
    "root_repository_size": 100,
    "projects_count": 3
  },
  {
    "id": 3,
    "name": "bar",
    "path": "bar",
    "kind": "group",
    "full_path": "foo/bar",
    "parent_id": 9,
    "avatar_url": null,
    "web_url": "https://gitlab.example.com/groups/foo/bar",
    "members_count_with_descendants": 5,
    "billable_members_count": 5,
    "end_date": null,
    "trial_ends_on": null,
    "trial": false,
    "root_repository_size": 100,
    "projects_count": 3
  }
]
```

Des attributs supplémentaires peuvent être renvoyés pour les propriétaires de groupes ou sur GitLab.com :

```json
[
  {
    ...
    "max_seats_used": 3,
    "max_seats_used_changed_at":"2025-05-15T12:00:02.000Z",
    "seats_in_use": 2,
    "projects_count": 1,
    "root_repository_size":0,
    "members_count_with_descendants":26,
    "plan": "free",
    ...
  }
]
```

## Récupérer les détails d'un espace de nommage {#retrieve-namespace-details}

Récupère les détails d'un espace de nommage spécifié.

```plaintext
GET /namespaces/:id
```

| Attribut | Type           | Obligatoire | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | entier ou chaîne de caractères | oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) de l'espace de nommage. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/namespaces/2"
```

Exemple de réponse :

```json
{
  "id": 2,
  "name": "group1",
  "path": "group1",
  "kind": "group",
  "full_path": "group1",
  "parent_id": null,
  "avatar_url": null,
  "web_url": "https://gitlab.example.com/groups/group1",
  "members_count_with_descendants": 2,
  "billable_members_count": 2,
  "max_seats_used": 0,
  "seats_in_use": 0,
  "plan": "default",
  "end_date": null,
  "trial_ends_on": null,
  "trial": false,
  "root_repository_size": 100,
  "projects_count": 3
}
```

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/namespaces/group1"
```

Exemple de réponse :

```json
{
  "id": 2,
  "name": "group1",
  "path": "group1",
  "kind": "group",
  "full_path": "group1",
  "parent_id": null,
  "avatar_url": null,
  "web_url": "https://gitlab.example.com/groups/group1",
  "members_count_with_descendants": 2,
  "billable_members_count": 2,
  "max_seats_used": 0,
  "seats_in_use": 0,
  "plan": "default",
  "end_date": null,
  "trial_ends_on": null,
  "trial": false,
  "root_repository_size": 100
}
```

## Vérifier la disponibilité d'un espace de nommage {#verify-namespace-availability}

Vérifie si un espace de nommage spécifié existe. Si l'espace de nommage existe, le point de terminaison suggère un autre nom.

```plaintext
GET /namespaces/:namespace/exists
```

| Attribut   | Type    | Obligatoire | Description |
| ----------- | ------- | -------- | ----------- |
| `namespace` | string  | oui      | Chemin de l'espace de nommage. |
| `parent_id` | entier | non       | ID de l'espace de nommage parent. Si non spécifié, renvoie uniquement les espaces de nommage de niveau supérieur. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/namespaces/my-group/exists?parent_id=1"
```

Exemple de réponse :

```json
{
    "exists": true,
    "suggests": [
        "my-group1"
    ]
}
```
