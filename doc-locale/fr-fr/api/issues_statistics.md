---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation pour l'API REST des statistiques des tickets dans GitLab."
title: API de statistiques des tickets
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour récupérer des statistiques sur les [tickets](../user/project/issues/_index.md). Chaque appel à cette API nécessite une authentification.

Si un utilisateur n'est pas membre d'un projet et que le projet est privé, une requête `GET` sur ce projet renvoie un code de statut `404`.

## Récupérer les statistiques des tickets pour un utilisateur {#retrieve-issues-statistics-for-a-user}

Récupère des statistiques sur les tickets accessibles par l'utilisateur actuel. Par défaut, seuls les tickets créés par l'utilisateur actuel sont renvoyés. Pour obtenir tous les tickets, définissez l'attribut `scope` sur `all`.

```plaintext
GET /issues_statistics
GET /issues_statistics?labels=foo
GET /issues_statistics?labels=foo,bar
GET /issues_statistics?labels=foo,bar&state=opened
GET /issues_statistics?milestone=1.0.0
GET /issues_statistics?milestone=1.0.0&state=opened
GET /issues_statistics?iids[]=42&iids[]=43
GET /issues_statistics?author_id=5
GET /issues_statistics?assignee_id=5
GET /issues_statistics?my_reaction_emoji=star
GET /issues_statistics?search=foo&in=title
GET /issues_statistics?confidential=true
```

| Attribut           | Type             | Obligatoire   | Description                                                                                                                                         |
| ------------------- | ---------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `labels`            | string           | non         | Liste de noms de labels séparés par des virgules ; les tickets doivent avoir tous les labels pour être renvoyés. `None` liste tous les tickets sans label. `Any` liste tous les tickets avec au moins un label. |
| `milestone`         | string           | non         | Le titre du jalon. `None` liste tous les tickets sans jalon. `Any` liste tous les tickets qui ont un jalon assigné.                             |
| `scope`             | string           | non         | Renvoyer les tickets pour la portée donnée : `created_by_me`, `assigned_to_me` ou `all`. Par défaut, `created_by_me` |
| `author_id`         | entier          | non         | Renvoyer les tickets créés par l'utilisateur avec l'`id` donné. Mutuellement exclusif avec `author_username`. À combiner avec `scope=all` ou `scope=assigned_to_me`. |
| `author_username`   | string           | non         | Renvoyer les tickets créés par le `username` donné. Similaire à `author_id` et mutuellement exclusif avec `author_id`. |
| `assignee_id`       | entier          | non         | Renvoyer les tickets assignés à l'utilisateur avec l'`id` donné. Mutuellement exclusif avec `assignee_username`. `None` renvoie les tickets non assignés. `Any` renvoie les tickets avec un assigné. |
| `assignee_username` | tableau de chaînes     | non         | Renvoyer les tickets assignés au `username` donné. Similaire à `assignee_id` et mutuellement exclusif avec `assignee_id`. Dans GitLab CE, le tableau `assignee_username` ne doit contenir qu'une seule valeur, sans quoi une erreur de paramètre invalide est renvoyée. |
| `epic_id`           | entier      | non         | Renvoyer les tickets associés à l'ID d'epic donné. `None` renvoie les tickets qui ne sont pas associés à un epic. `Any` renvoie les tickets qui sont associés à un epic. Premium et Ultimate uniquement. |
| `my_reaction_emoji` | string           | non         | Renvoyer les tickets ayant reçu une réaction de l'utilisateur authentifié avec l'`emoji` donné. `None` renvoie les tickets n'ayant reçu aucune réaction. `Any` renvoie les tickets ayant reçu au moins une réaction. |
| `iids[]`            | tableau d'entiers    | non         | Renvoyer uniquement les tickets ayant l'`iid` donné                                                                                                       |
| `search`            | string           | non         | Rechercher des tickets par rapport à leur `title` et leur `description`                                                                                               |
| `in`                | string           | non         | Modifier la portée de l'attribut `search`. `title`, `description`, ou une chaîne les joignant avec une virgule. La valeur par défaut est `title,description`             |
| `created_after`     | datetime         | non         | Renvoyer les tickets créés à partir de l'heure donnée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`) |
| `created_before`    | datetime         | non         | Renvoyer les tickets créés jusqu'à l'heure donnée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`) |
| `updated_after`     | datetime         | non         | Renvoyer les tickets mis à jour à partir de l'heure donnée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`) |
| `updated_before`    | datetime         | non         | Renvoyer les tickets mis à jour jusqu'à l'heure donnée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`) |
| `confidential`      | boolean          | non         | Filtrer les tickets confidentiels ou publics.                                                                                                               |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/issues_statistics"
```

Exemple de réponse :

```json
{
  "statistics": {
    "counts": {
      "all": 20,
      "closed": 5,
      "opened": 15
    }
  }
}
```

## Récupérer les statistiques des tickets pour un groupe {#retrieve-issues-statistics-for-a-group}

Récupère des statistiques sur les tickets dans un groupe spécifié.

```plaintext
GET /groups/:id/issues_statistics
GET /groups/:id/issues_statistics?labels=foo
GET /groups/:id/issues_statistics?labels=foo,bar
GET /groups/:id/issues_statistics?labels=foo,bar&state=opened
GET /groups/:id/issues_statistics?milestone=1.0.0
GET /groups/:id/issues_statistics?milestone=1.0.0&state=opened
GET /groups/:id/issues_statistics?iids[]=42&iids[]=43
GET /groups/:id/issues_statistics?search=issue+title+or+description
GET /groups/:id/issues_statistics?author_id=5
GET /groups/:id/issues_statistics?assignee_id=5
GET /groups/:id/issues_statistics?my_reaction_emoji=star
GET /groups/:id/issues_statistics?confidential=true
```

| Attribut           | Type             | Obligatoire   | Description                                                                                                                   |
| ------------------- | ---------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe                 |
| `labels`            | string           | non         | Liste de noms de labels séparés par des virgules ; les tickets doivent avoir tous les labels pour être renvoyés. `None` liste tous les tickets sans label. `Any` liste tous les tickets avec au moins un label. |
| `iids[]`            | tableau d'entiers    | non         | Renvoyer uniquement les tickets ayant l'`iid` donné                                                                                 |
| `milestone`         | string           | non         | Le titre du jalon. `None` liste tous les tickets sans jalon. `Any` liste tous les tickets qui ont un jalon assigné.       |
| `scope`             | string           | non         | Renvoyer les tickets pour la portée donnée : `created_by_me`, `assigned_to_me` ou `all`. |
| `author_id`         | entier          | non         | Renvoyer les tickets créés par l'utilisateur avec l'`id` donné. Mutuellement exclusif avec `author_username`. À combiner avec `scope=all` ou `scope=assigned_to_me`. |
| `author_username`   | string           | non         | Renvoyer les tickets créés par le `username` donné. Similaire à `author_id` et mutuellement exclusif avec `author_id`. |
| `assignee_id`       | entier          | non         | Renvoyer les tickets assignés à l'utilisateur avec l'`id` donné. Mutuellement exclusif avec `assignee_username`. `None` renvoie les tickets non assignés. `Any` renvoie les tickets avec un assigné. |
| `assignee_username` | tableau de chaînes     | non         | Renvoyer les tickets assignés au `username` donné. Similaire à `assignee_id` et mutuellement exclusif avec `assignee_id`. Dans GitLab CE, le tableau `assignee_username` ne doit contenir qu'une seule valeur, sans quoi une erreur de paramètre invalide est renvoyée. |
| `my_reaction_emoji` | string           | non         | Renvoyer les tickets ayant reçu une réaction de l'utilisateur authentifié avec l'`emoji` donné. `None` renvoie les tickets n'ayant reçu aucune réaction. `Any` renvoie les tickets ayant reçu au moins une réaction. |
| `search`            | string           | non         | Rechercher des tickets du groupe par rapport à leur `title` et leur `description`                                                                   |
| `created_after`     | datetime         | non         | Renvoyer les tickets créés à partir de l'heure donnée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`) |
| `created_before`    | datetime         | non         | Renvoyer les tickets créés jusqu'à l'heure donnée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`) |
| `updated_after`     | datetime         | non         | Renvoyer les tickets mis à jour à partir de l'heure donnée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`) |
| `updated_before`    | datetime         | non         | Renvoyer les tickets mis à jour jusqu'à l'heure donnée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`) |
| `confidential`      | boolean          | non         | Filtrer les tickets confidentiels ou publics.                                                                                         |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/4/issues_statistics"
```

Exemple de réponse :

```json
{
  "statistics": {
    "counts": {
      "all": 20,
      "closed": 5,
      "opened": 15
    }
  }
}
```

## Récupérer les statistiques des tickets pour un projet {#retrieve-issues-statistics-for-a-project}

Récupère des statistiques sur les tickets dans un projet spécifié.

```plaintext
GET /projects/:id/issues_statistics
GET /projects/:id/issues_statistics?labels=foo
GET /projects/:id/issues_statistics?labels=foo,bar
GET /projects/:id/issues_statistics?labels=foo,bar&state=opened
GET /projects/:id/issues_statistics?milestone=1.0.0
GET /projects/:id/issues_statistics?milestone=1.0.0&state=opened
GET /projects/:id/issues_statistics?iids[]=42&iids[]=43
GET /projects/:id/issues_statistics?search=issue+title+or+description
GET /projects/:id/issues_statistics?author_id=5
GET /projects/:id/issues_statistics?assignee_id=5
GET /projects/:id/issues_statistics?my_reaction_emoji=star
GET /projects/:id/issues_statistics?confidential=true
```

| Attribut           | Type             | Obligatoire   | Description                                                                                                                   |
| ------------------- | ---------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `id`                | entier ou chaîne   | oui        | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths)               |
| `iids[]`            | tableau d'entiers    | non         | Renvoyer uniquement les tickets ayant l'`iid` donné                                                                              |
| `labels`            | string           | non         | Liste de noms de labels séparés par des virgules ; les tickets doivent avoir tous les labels pour être renvoyés. `None` liste tous les tickets sans label. `Any` liste tous les tickets avec au moins un label. |
| `milestone`         | string           | non         | Le titre du jalon. `None` liste tous les tickets sans jalon. `Any` liste tous les tickets qui ont un jalon assigné.       |
| `scope`             | string           | non         | Renvoyer les tickets pour la portée donnée : `created_by_me`, `assigned_to_me` ou `all`. |
| `author_id`         | entier          | non         | Renvoyer les tickets créés par l'utilisateur avec l'`id` donné. Mutuellement exclusif avec `author_username`. À combiner avec `scope=all` ou `scope=assigned_to_me`. |
| `author_username`   | string           | non         | Renvoyer les tickets créés par le `username` donné. Similaire à `author_id` et mutuellement exclusif avec `author_id`. |
| `assignee_id`       | entier          | non         | Renvoyer les tickets assignés à l'utilisateur avec l'`id` donné. Mutuellement exclusif avec `assignee_username`. `None` renvoie les tickets non assignés. `Any` renvoie les tickets avec un assigné. |
| `assignee_username` | tableau de chaînes     | non         | Renvoyer les tickets assignés au `username` donné. Similaire à `assignee_id` et mutuellement exclusif avec `assignee_id`. Dans GitLab CE, le tableau `assignee_username` ne doit contenir qu'une seule valeur, sans quoi une erreur de paramètre invalide est renvoyée. |
| `my_reaction_emoji` | string           | non         | Renvoyer les tickets ayant reçu une réaction de l'utilisateur authentifié avec l'`emoji` donné. `None` renvoie les tickets n'ayant reçu aucune réaction. `Any` renvoie les tickets ayant reçu au moins une réaction. |
| `search`            | string           | non         | Rechercher des tickets du projet par rapport à leur `title` et leur `description`                                                                 |
| `created_after`     | datetime         | non         | Renvoyer les tickets créés à partir de l'heure donnée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`) |
| `created_before`    | datetime         | non         | Renvoyer les tickets créés jusqu'à l'heure donnée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`) |
| `updated_after`     | datetime         | non         | Renvoyer les tickets mis à jour à partir de l'heure donnée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`) |
| `updated_before`    | datetime         | non         | Renvoyer les tickets mis à jour jusqu'à l'heure donnée. Attendu au format ISO 8601 (`2019-03-15T08:00:00Z`) |
| `confidential`      | boolean          | non         | Filtrer les tickets confidentiels ou publics.                                                                                         |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/issues_statistics"
```

Exemple de réponse :

```json
{
  "statistics": {
    "counts": {
      "all": 20,
      "closed": 5,
      "opened": 15
    }
  }
}
```
