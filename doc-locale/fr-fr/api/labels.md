---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des labels de projet
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- L'attribut `archived` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/4233) dans GitLab 18.3 [avec un indicateur](../administration/feature_flags/_index.md) nommé `labels_archive`.
- [Disponible généralement](https://gitlab.com/gitlab-org/gitlab/-/issues/556700) dans GitLab 18.10. L'indicateur de fonctionnalité `labels_archive` a été supprimé.

{{< /history >}}

Utilisez cette API pour gérer les [labels de projet](../user/project/labels.md).

Pour les labels de groupe, utilisez l'[API des labels de groupe](group_labels.md).

## Lister tous les labels de projet {#list-all-project-labels}

Liste tous les labels d'un projet spécifié.

Par défaut, cette requête renvoie 20 résultats à la fois car les résultats de l'API [sont paginés](rest/_index.md#pagination).

```plaintext
GET /projects/:id/labels
```

| Attribut     | Type           | Obligatoire | Description                                                                                                                                                                  |
| ---------     | -------        | -------- | ---------------------                                                                                                                                                        |
| `id`          | entier ou chaîne de caractères | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths)                                                              |
| `with_counts` | boolean        | non       | Indique si les comptages de tickets et de merge requests doivent être inclus ou non. La valeur par défaut est `false`. |
| `include_ancestor_groups` | boolean | non | Inclure les groupes ancêtres. La valeur par défaut est `true`. |
| `search` | string | non | Mot-clé pour filtrer les labels. |
| `archived` | boolean | non | Si `true`, retourne uniquement les labels archivés. Si non défini, retourne tous les labels. |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels?with_counts=true"
```

Exemple de réponse :

```json
[
  {
    "id" : 1,
    "name" : "bug",
    "color" : "#d9534f",
    "text_color" : "#FFFFFF",
    "description": "Bug reported by user",
    "description_html": "Bug reported by user",
    "open_issues_count": 1,
    "closed_issues_count": 0,
    "open_merge_requests_count": 1,
    "subscribed": false,
    "priority": 10,
    "is_project_label": true,
    "archived": false
  },
  {
    "id" : 4,
    "color" : "#d9534f",
    "text_color" : "#FFFFFF",
    "name" : "confirmed",
    "description": "Confirmed issue",
    "description_html": "Confirmed issue",
    "open_issues_count": 2,
    "closed_issues_count": 5,
    "open_merge_requests_count": 0,
    "subscribed": false,
    "priority": null,
    "is_project_label": true,
    "archived": false
  },
  {
    "id" : 7,
    "name" : "critical",
    "color" : "#d9534f",
    "text_color" : "#FFFFFF",
    "description": "Critical issue. Need fix ASAP",
    "description_html": "Critical issue. Need fix ASAP",
    "open_issues_count": 1,
    "closed_issues_count": 3,
    "open_merge_requests_count": 1,
    "subscribed": false,
    "priority": null,
    "is_project_label": true,
    "archived": false
  },
  {
    "id" : 8,
    "name" : "documentation",
    "color" : "#f0ad4e",
    "text_color" : "#FFFFFF",
    "description": "Issue about documentation",
    "description_html": "Issue about documentation",
    "open_issues_count": 1,
    "closed_issues_count": 0,
    "open_merge_requests_count": 2,
    "subscribed": false,
    "priority": null,
    "is_project_label": false,
    "archived": false
  },
  {
    "id" : 9,
    "color" : "#5cb85c",
    "text_color" : "#FFFFFF",
    "name" : "enhancement",
    "description": "Enhancement proposal",
    "description_html": "Enhancement proposal",
    "open_issues_count": 1,
    "closed_issues_count": 0,
    "open_merge_requests_count": 1,
    "subscribed": true,
    "priority": null,
    "is_project_label": true,
    "archived": false
  }
]
```

## Récupérer un label de projet {#retrieve-a-project-label}

Récupère un label spécifié pour un projet.

```plaintext
GET /projects/:id/labels/:label_id
```

| Attribut     | Type           | Obligatoire | Description                                                                                                                                                                  |
| ---------     | -------        | -------- | ---------------------                                                                                                                                                        |
| `id`          | entier ou chaîne de caractères | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths)                                                              |
| `label_id` | entier ou chaîne de caractères | oui | L'ID ou le titre du label d'un projet. |
| `include_ancestor_groups` | boolean | non | Inclure les groupes ancêtres. La valeur par défaut est `true`. |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels/bug"
```

Exemple de réponse :

```json
{
  "id" : 1,
  "name" : "bug",
  "color" : "#d9534f",
  "text_color" : "#FFFFFF",
  "description": "Bug reported by user",
  "description_html": "Bug reported by user",
  "open_issues_count": 1,
  "closed_issues_count": 0,
  "open_merge_requests_count": 1,
  "subscribed": false,
  "priority": 10,
  "is_project_label": true,
  "archived": false
}
```

## Créer un label de projet {#create-a-project-label}

Crée un label pour un projet spécifié avec le nom et la couleur indiqués.

```plaintext
POST /projects/:id/labels
```

| Attribut     | Type    | Obligatoire | Description                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id`      | entier ou chaîne de caractères    | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `name`        | string  | oui      | Le nom du label        |
| `color`       | string  | oui      | La couleur du label exprimée en notation hexadécimale à 6 chiffres avec le signe « # » en tête (par exemple, #FFAABB) ou l'un des [noms de couleurs CSS](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords) |
| `description` | string  | non       | La description du label |
| `priority`    | integer | non       | La priorité du label. Doit être supérieure ou égale à zéro ou `null` pour supprimer la priorité. |
| `archived`    | boolean | non       | Si `true`, marque le label comme archivé. Valeur par défaut : `false`. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels" \
  --data "name=feature&color=#5843AD"
```

Exemple de réponse :

```json
{
  "id" : 10,
  "name" : "feature",
  "color" : "#5843AD",
  "text_color" : "#FFFFFF",
  "description":null,
  "description_html":null,
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": false,
  "priority": null,
  "is_project_label": true,
  "archived": false
}
```

## Supprimer un label de projet {#delete-a-project-label}

Supprime un label spécifié d'un projet.

```plaintext
DELETE /projects/:id/labels/:label_id
```

| Attribut | Type    | Obligatoire | Description           |
| --------- | ------- | -------- | --------------------- |
| `id`            | entier ou chaîne de caractères | oui | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `label_id` | entier ou chaîne de caractères | oui | L'ID ou le titre du label d'un projet. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels/bug"
```

> [!note]
> Un ancien point de terminaison `DELETE /projects/:id/labels` avec `name` dans les paramètres est toujours disponible, mais déprécié.

## Mettre à jour un label de projet {#update-a-project-label}

Met à jour un label spécifié pour un projet avec un nouveau nom ou une nouvelle couleur. Au moins un paramètre est requis pour mettre à jour le label.

```plaintext
PUT /projects/:id/labels/:label_id
```

| Attribut       | Type    | Obligatoire                          | Description                      |
| --------------- | ------- | --------------------------------- | -------------------------------  |
| `id`      | entier ou chaîne de caractères    | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `label_id` | entier ou chaîne de caractères | oui | L'ID ou le titre du label d'un projet. |
| `new_name`      | string  | oui si `color` n'est pas fourni    | Le nouveau nom du label        |
| `color`         | string  | oui si `new_name` n'est pas fourni | La couleur du label exprimée en notation hexadécimale à 6 chiffres avec le signe « # » en tête (par exemple, #FFAABB) ou l'un des [noms de couleurs CSS](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords) |
| `description`   | string  | non                                | La nouvelle description du label |
| `priority`    | integer | non       | La nouvelle priorité du label. Doit être supérieure ou égale à zéro ou `null` pour supprimer la priorité. |
| `archived`    | boolean | non       | Si `true`, marque le label comme archivé. Valeur par défaut : `false`. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels/documentation" \
  --data "new_name=docs&color=#8E44AD&description=Documentation"
```

Exemple de réponse :

```json
{
  "id" : 8,
  "name" : "docs",
  "color" : "#8E44AD",
  "text_color" : "#FFFFFF",
  "description": "Documentation",
  "description_html": "Documentation",
  "open_issues_count": 1,
  "closed_issues_count": 0,
  "open_merge_requests_count": 2,
  "subscribed": false,
  "priority": null,
  "is_project_label": true,
  "archived": false
}
```

> [!note]
> Un ancien point de terminaison `PUT /projects/:id/labels` avec `name` ou `label_id` dans les paramètres est toujours disponible, mais déprécié.

## Promouvoir un label de projet en label de groupe {#promote-a-project-label-to-a-group-label}

Promeut un label de projet spécifié en label de groupe. Le label conserve son ID.

```plaintext
PUT /projects/:id/labels/:label_id/promote
```

| Attribut       | Type    | Obligatoire                          | Description                      |
| --------------- | ------- | --------------------------------- | -------------------------------  |
| `id`      | entier ou chaîne de caractères    | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `label_id` | entier ou chaîne de caractères | oui | L'ID ou le titre du label d'un projet. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/labels/documentation/promote"
```

Exemple de réponse :

```json
{
  "id" : 8,
  "name" : "documentation",
  "color" : "#8E44AD",
  "description": "Documentation",
  "description_html": "Documentation",
  "open_issues_count": 1,
  "closed_issues_count": 0,
  "open_merge_requests_count": 2,
  "subscribed": false,
  "archived": false
}
```

> [!note]
> Un ancien point de terminaison `PUT /projects/:id/labels/promote` avec `name` dans les paramètres est toujours disponible, mais déprécié.

## S'abonner à un label de projet {#subscribe-to-a-project-label}

Abonne l'utilisateur authentifié à un label de projet spécifié pour recevoir des notifications. Si l'utilisateur est déjà abonné au label, le code de statut `304` est retourné.

```plaintext
POST /projects/:id/labels/:label_id/subscribe
```

| Attribut  | Type              | Obligatoire | Description                          |
| ---------- | ----------------- | -------- | ------------------------------------ |
| `id`      | entier ou chaîne de caractères    | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `label_id` | entier ou chaîne de caractères | oui      | L'ID ou le titre du label d'un projet |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/labels/1/subscribe"
```

Exemple de réponse :

```json
{
  "id" : 1,
  "name" : "bug",
  "color" : "#d9534f",
  "text_color" : "#FFFFFF",
  "description": "Bug reported by user",
  "description_html": "Bug reported by user",
  "open_issues_count": 1,
  "closed_issues_count": 0,
  "open_merge_requests_count": 1,
  "subscribed": true,
  "priority": null,
  "is_project_label": true,
  "archived": false
}
```

## Se désabonner d'un label de projet {#unsubscribe-from-a-project-label}

Désabonne l'utilisateur authentifié d'un label de projet spécifié pour ne plus recevoir de notifications. Si l'utilisateur n'est pas abonné au label, le code de statut `304` est retourné.

```plaintext
POST /projects/:id/labels/:label_id/unsubscribe
```

| Attribut  | Type              | Obligatoire | Description                          |
| ---------- | ----------------- | -------- | ------------------------------------ |
| `id`      | entier ou chaîne de caractères    | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `label_id` | entier ou chaîne de caractères | oui      | L'ID ou le titre du label d'un projet |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/labels/1/unsubscribe"
```
