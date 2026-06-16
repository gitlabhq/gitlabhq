---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des labels de groupe
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- L'attribut `archived` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/4233) dans GitLab 18.3 [avec un indicateur](../administration/feature_flags/_index.md) nommé `labels_archive`.
- [Disponible de manière générale](https://gitlab.com/gitlab-org/gitlab/-/issues/556700) dans GitLab 18.10. L'indicateur de fonctionnalité `labels_archive` a été supprimé.

{{< /history >}}

Utilisez cette API pour gérer les [labels de groupe](../user/project/labels.md#types-of-labels).

Pour les labels de projet, utilisez l'[API des labels de projet](labels.md).

## Lister les labels de groupe {#list-group-labels}

Récupère tous les labels d'un groupe donné.

```plaintext
GET /groups/:id/labels
```

| Attribut     | Type           | Obligatoire | Description                                                                                                                                                                  |
| ---------     | ----           | -------- | -----------                                                                                                                                                                  |
| `id`          | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe.                                                               |
| `with_counts` | boolean        | non       | Indique si les nombres de tickets et de merge requests doivent être inclus ou non. La valeur par défaut est `false`. |
| `include_ancestor_groups` | boolean | non | Inclure les groupes ancêtres. La valeur par défaut est `true`. |
| `include_descendant_groups` | boolean | non | Inclure les groupes descendants. La valeur par défaut est `false`. |
| `only_group_labels` | boolean | non | Basculer pour inclure uniquement les labels de groupe ou également les labels de projet. La valeur par défaut est `true`. |
| `search` | string | non | Mot-clé pour filtrer les labels. |
| `archived` | boolean | non | Si `true`, retourne uniquement les labels archivés. Si non défini, retourne tous les labels. |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/labels?with_counts=true"
```

Exemple de réponse :

```json
[
  {
    "id": 7,
    "name": "bug",
    "color": "#FF0000",
    "text_color" : "#FFFFFF",
    "description": null,
    "description_html": null,
    "open_issues_count": 0,
    "closed_issues_count": 0,
    "open_merge_requests_count": 0,
    "subscribed": false,
    "archived": false
  },
  {
    "id": 4,
    "name": "feature",
    "color": "#228B22",
    "text_color" : "#FFFFFF",
    "description": null,
    "description_html": null,
    "open_issues_count": 0,
    "closed_issues_count": 0,
    "open_merge_requests_count": 0,
    "subscribed": false,
    "archived": false
  }
]
```

## Obtenir un seul label de groupe {#get-a-single-group-label}

Récupère un seul label pour un groupe donné.

```plaintext
GET /groups/:id/labels/:label_id
```

| Attribut     | Type           | Obligatoire | Description                                                                                                                                                                  |
| ---------     | ----           | -------- | -----------                                                                                                                                                                  |
| `id`          | entier ou chaîne | oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe.                                                               |
| `label_id` | entier ou chaîne | oui | L'identifiant ou le titre du label d'un groupe. |
| `include_ancestor_groups` | boolean | non | Inclure les groupes ancêtres. La valeur par défaut est `true`. |
| `include_descendant_groups` | boolean | non | Inclure les groupes descendants. La valeur par défaut est `false`. |
| `only_group_labels` | boolean | non | Basculer pour inclure uniquement les labels de groupe ou également les labels de projet. La valeur par défaut est `true`. |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/labels/bug"
```

Exemple de réponse :

```json
{
  "id": 7,
  "name": "bug",
  "color": "#FF0000",
  "text_color" : "#FFFFFF",
  "description": null,
  "description_html": null,
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": false,
  "archived": false
}
```

## Créer un nouveau label de groupe {#create-a-new-group-label}

Crée un nouveau label de groupe pour un groupe donné.

```plaintext
POST /groups/:id/labels
```

| Attribut     | Type    | Obligatoire | Description                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id` | entier ou chaîne | oui | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `name`        | string  | oui      | Le nom du label        |
| `color`       | string  | oui      | La couleur du label donnée en notation hexadécimale à 6 chiffres avec le signe '#' en tête (par exemple, #FFAABB) ou l'un des [noms de couleurs CSS](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords) |
| `description` | string  | non       | La description du label, |
| `archived`    | boolean | non       | Si `true`, marque le label comme archivé. Valeur par défaut : `false`. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "Feature Proposal",
    "color": "#FFA500",
    "description": "Describes new ideas"
  }' \
  --url "https://gitlab.example.com/api/v4/groups/5/labels"
```

Exemple de réponse :

```json
{
  "id": 9,
  "name": "Feature Proposal",
  "color": "#FFA500",
  "text_color" : "#FFFFFF",
  "description": "Describes new ideas",
  "description_html": "Describes new ideas",
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": false,
  "archived": false
}
```

## Mettre à jour un label de groupe {#update-a-group-label}

Met à jour un label de groupe existant. Au moins un paramètre est requis pour mettre à jour le label de groupe.

```plaintext
PUT /groups/:id/labels/:label_id
```

| Attribut     | Type    | Obligatoire | Description                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id` | entier ou chaîne | oui | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `label_id` | entier ou chaîne | oui | L'identifiant ou le titre du label d'un groupe. |
| `new_name`    | string  | non      | Le nouveau nom du label        |
| `color`       | string  | non      | La couleur du label donnée en notation hexadécimale à 6 chiffres avec le signe '#' en tête (par exemple, #FFAABB) ou l'un des [noms de couleurs CSS](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords) |
| `description` | string  | non       | La description du label. |
| `archived`    | boolean | non       | Si `true`, marque le label comme archivé. Valeur par défaut : `false`. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"new_name": "Feature Idea"}' \
  --url "https://gitlab.example.com/api/v4/groups/5/labels/Feature%20Proposal"
```

Exemple de réponse :

```json
{
  "id": 9,
  "name": "Feature Idea",
  "color": "#FFA500",
  "text_color" : "#FFFFFF",
  "description": "Describes new ideas",
  "description_html": "Describes new ideas",
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": false,
  "archived": false
}
```

> [!note]
> Un ancien point de terminaison `PUT /groups/:id/labels` avec `name` dans les paramètres est toujours disponible, mais déprécié.

## Supprimer un label de groupe {#delete-a-group-label}

Supprime un label de groupe avec un nom donné.

```plaintext
DELETE /groups/:id/labels/:label_id
```

| Attribut | Type    | Obligatoire | Description           |
| --------- | ------- | -------- | --------------------- |
| `id`      | entier ou chaîne    | oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `label_id` | entier ou chaîne | oui | L'identifiant ou le titre du label d'un groupe. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/labels/bug"
```

> [!note]
> Un ancien point de terminaison `DELETE /groups/:id/labels` avec `name` dans les paramètres est toujours disponible, mais déprécié.

## S'abonner à un label de groupe {#subscribe-to-a-group-label}

Abonne l'utilisateur authentifié à un label de groupe pour recevoir des notifications. Si l'utilisateur est déjà abonné au label, le code de statut `304` est retourné.

```plaintext
POST /groups/:id/labels/:label_id/subscribe
```

| Attribut  | Type              | Obligatoire | Description                          |
| ---------- | ----------------- | -------- | ------------------------------------ |
| `id`      | entier ou chaîne    | oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `label_id` | entier ou chaîne | oui      | L'identifiant ou le titre du label d'un groupe. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/labels/9/subscribe"
```

Exemple de réponse :

```json
{
  "id": 9,
  "name": "Feature Idea",
  "color": "#FFA500",
  "text_color" : "#FFFFFF",
  "description": "Describes new ideas",
  "description_html": "Describes new ideas",
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": true,
  "archived": false
}
```

## Se désabonner d'un label de groupe {#unsubscribe-from-a-group-label}

Désabonne l'utilisateur authentifié d'un label de groupe afin de ne plus recevoir de notifications de celui-ci. Si l'utilisateur n'est pas abonné au label, le code de statut `304` est retourné.

```plaintext
POST /groups/:id/labels/:label_id/unsubscribe
```

| Attribut  | Type              | Obligatoire | Description                          |
| ---------- | ----------------- | -------- | ------------------------------------ |
| `id`      | entier ou chaîne    | oui      | L'identifiant ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |
| `label_id` | entier ou chaîne | oui      | L'identifiant ou le titre du label d'un groupe. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/labels/9/unsubscribe"
```

Exemple de réponse :

```json
{
  "id": 9,
  "name": "Feature Idea",
  "color": "#FFA500",
  "text_color" : "#FFFFFF",
  "description": "Describes new ideas",
  "description_html": "Describes new ideas",
  "open_issues_count": 0,
  "closed_issues_count": 0,
  "open_merge_requests_count": 0,
  "subscribed": false,
  "archived": false
}
```
