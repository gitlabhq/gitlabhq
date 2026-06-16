---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation sur l'API REST pour les branches Git dans GitLab."
title: API Branches
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [branches Git](../user/project/repository/branches/_index.md).

Pour modifier les protections de branche configurées pour un projet, utilisez l'[API des branches protégées](protected_branches.md).

## Lister toutes les branches du dépôt {#list-all-repository-branches}

Liste toutes les branches du dépôt d'un projet, triées par nom dans l'ordre alphabétique. Recherchez par nom ou utilisez des expressions régulières pour trouver des modèles de branche spécifiques. Retourne des informations détaillées sur la branche, notamment son statut de protection, son statut de fusion et les détails du commit.

> [!note]
> Ce point de terminaison est accessible sans authentification si le dépôt est accessible publiquement.

```plaintext
GET /projects/:id/repository/branches
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `regex`   | string            | Non       | Retourne la liste des branches dont les noms correspondent à une expression régulière [re2](https://github.com/google/re2/wiki/Syntax). Ne peut pas être utilisé conjointement avec `search`. |
| `search`  | string            | Non       | Retourne la liste des branches contenant la chaîne de recherche. Vous pouvez utiliser `^term` pour trouver les branches qui commencent par `term`, et `term$` pour trouver les branches qui se terminent par `term`. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                  | Type                | Description |
|----------------------------|---------------------|-------------|
| `can_push`                 | boolean             | Si `true`, l'utilisateur authentifié peut pousser vers cette branche. |
| `commit`                   | objet              | Détails sur le commit le plus récent sur la branche. |
| `commit.author_email`      | string              | Adresse e-mail de l'utilisateur qui a rédigé la modification. |
| `commit.author_name`       | string              | Nom de l'utilisateur qui a rédigé la modification. |
| `commit.authored_date`     | datetime (ISO 8601) | Date à laquelle le commit a été rédigé. |
| `commit.committed_date`    | datetime (ISO 8601) | Date à laquelle le commit a été soumis. |
| `commit.committer_email`   | string              | Adresse e-mail de l'utilisateur qui a soumis la modification. |
| `commit.committer_name`    | string              | Nom de l'utilisateur qui a soumis la modification. |
| `commit.created_at`        | datetime (ISO 8601) | Date à laquelle le commit a été créé. |
| `commit.extended_trailers` | objet              | Trailers Git étendus analysés depuis le message de commit. |
| `commit.id`                | string              | SHA complet du commit. |
| `commit.message`           | string              | Message de commit complet. |
| `commit.parent_ids`        | tableau               | Tableau des SHA des commits parents. |
| `commit.short_id`          | string              | SHA abrégé du commit. |
| `commit.title`             | string              | Titre du message de commit. |
| `commit.trailers`          | objet              | Trailers Git analysés depuis le message de commit. |
| `commit.web_url`           | string              | URL pour afficher le commit dans l'interface utilisateur GitLab. |
| `default`                  | boolean             | Si `true`, la branche est la branche par défaut du projet. |
| `developers_can_merge`     | boolean             | Si `true`, les utilisateurs avec le rôle Developer, Maintainer ou Owner peuvent fusionner vers cette branche. |
| `developers_can_push`      | boolean             | Si `true`, les utilisateurs avec le rôle Developer, Maintainer ou Owner peuvent pousser vers cette branche. |
| `merged`                   | boolean             | Si `true`, la branche a été fusionnée dans la branche par défaut. |
| `name`                     | string              | Nom de la branche. |
| `protected`                | boolean             | Si `true`, la branche est protégée contre les push forcés et la suppression. |
| `web_url`                  | string              | URL pour afficher la branche dans l'interface utilisateur GitLab. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/branches"
```

Exemple de réponse :

```json
[
  {
    "name": "main",
    "merged": false,
    "protected": true,
    "default": true,
    "developers_can_push": false,
    "developers_can_merge": false,
    "can_push": true,
    "web_url": "https://gitlab.example.com/my-group/my-project/-/tree/main",
    "commit": {
      "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
      "short_id": "7b5c3cc",
      "created_at": "2024-06-28T03:44:20-07:00",
      "parent_ids": [
        "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
      ],
      "title": "add projects API",
      "message": "add projects API",
      "author_name": "John Smith",
      "author_email": "john@example.com",
      "authored_date": "2024-06-27T05:51:39-07:00",
      "committer_name": "John Smith",
      "committer_email": "john@example.com",
      "committed_date": "2024-06-28T03:44:20-07:00",
      "trailers": {},
      "extended_trailers": {},
      "web_url": "https://gitlab.example.com/my-group/my-project/-/commit/7b5c3cc8be40ee161ae89a06bba6229da1032a0c"
    }
  },
  ...
]
```

## Récupérer une branche du dépôt {#retrieve-a-repository-branch}

Récupère une branche du dépôt de projet spécifiée.

> [!note]
> Ce point de terminaison est accessible sans authentification si le dépôt est accessible publiquement.

```plaintext
GET /projects/:id/repository/branches/:branch
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `branch`  | string            | Oui      | [Nom encodé dans l'URL](rest/_index.md#namespaced-paths) de la branche. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                | Type    | Description |
|--------------------------|---------|-------------|
| `can_push`               | boolean | Indique si l'utilisateur authentifié peut pousser vers cette branche. |
| `commit`                 | objet  | Détails sur le dernier commit sur la branche. |
| `commit.author_email`    | string  | Adresse e-mail de l'auteur du commit. |
| `commit.author_name`     | string  | Nom de l'auteur du commit. |
| `commit.authored_date`   | string  | Date et heure auxquelles le commit a été rédigé, au format ISO 8601. |
| `commit.committer_email` | string  | Adresse e-mail de l'utilisateur qui a soumis la modification. |
| `commit.committer_name`  | string  | Nom de l'utilisateur qui a soumis la modification. |
| `commit.committed_date`  | string  | Date et heure auxquelles le commit a été soumis, au format ISO 8601. |
| `commit.created_at`      | string  | Date et heure auxquelles le commit a été créé, au format ISO 8601. |
| `commit.extended_trailers` | objet  | Trailers Git étendus analysés depuis le message de commit. |
| `commit.id`              | string  | SHA complet du commit. |
| `commit.message`         | string  | Message de commit complet. |
| `commit.parent_ids`      | tableau   | Tableau des SHA des commits parents. |
| `commit.short_id`        | string  | SHA abrégé du commit. |
| `commit.title`           | string  | Titre du message de commit. |
| `commit.trailers`        | objet  | Trailers Git analysés depuis le message de commit. |
| `commit.web_url`         | string  | URL pour afficher le commit dans l'interface utilisateur GitLab. |
| `default`                | boolean | Indique si c'est la branche par défaut du projet. |
| `developers_can_merge`   | boolean | Indique si les utilisateurs avec le rôle Developer peuvent fusionner vers cette branche. |
| `developers_can_push`    | boolean | Indique si les utilisateurs avec le rôle Developer peuvent pousser vers cette branche. |
| `merged`                 | boolean | Indique si la branche a été fusionnée dans la branche par défaut. |
| `name`                   | string  | Nom de la branche. |
| `protected`              | boolean | Indique si la branche est protégée contre les push forcés et la suppression. |
| `web_url`                | string  | URL pour afficher la branche dans l'interface utilisateur GitLab. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/branches/main"
```

Exemple de réponse :

```json
{
  "name": "main",
  "merged": false,
  "protected": true,
  "default": true,
  "developers_can_push": false,
  "developers_can_merge": false,
  "can_push": true,
  "web_url": "https://gitlab.example.com/my-group/my-project/-/tree/main",
  "commit": {
    "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
    "short_id": "7b5c3cc",
    "created_at": "2012-06-28T03:44:20-07:00",
    "parent_ids": [
      "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
    ],
    "title": "add projects API",
    "message": "add projects API",
    "author_name": "John Smith",
    "author_email": "john@example.com",
    "authored_date": "2012-06-27T05:51:39-07:00",
    "committer_name": "John Smith",
    "committer_email": "john@example.com",
    "committed_date": "2012-06-28T03:44:20-07:00",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/my-group/my-project/-/commit/7b5c3cc8be40ee161ae89a06bba6229da1032a0c"
  }
}
```

## Protéger une branche du dépôt {#protect-repository-branch}

Consultez [`POST /projects/:id/protected_branches`](protected_branches.md#protect-repository-branches) pour obtenir des informations sur la protection des branches du dépôt.

## Déprotéger une branche du dépôt {#unprotect-repository-branch}

Consultez [`DELETE /projects/:id/protected_branches/:name`](protected_branches.md#unprotect-repository-branches) pour obtenir des informations sur la déprotection des branches du dépôt.

## Créer une branche dans le dépôt {#create-repository-branch}

Crée une nouvelle branche dans le dépôt.

```plaintext
POST /projects/:id/repository/branches
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `branch`  | string            | Oui      | Nom de la branche. Ne peut pas contenir d'espaces ni de caractères spéciaux, à l'exception des tirets et des tirets de soulignement. |
| `ref`     | string            | Oui      | Nom de branche ou SHA de commit à partir duquel créer la branche. |

En cas de succès, renvoie [`201 Created`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                  | Type    | Description |
|----------------------------|---------|-------------|
| `can_push`                 | boolean | Si `true`, l'utilisateur authentifié peut pousser vers cette branche. |
| `commit`                   | objet  | Détails sur le dernier commit sur la branche. |
| `commit.author_email`      | string  | Adresse e-mail de l'auteur du commit. |
| `commit.author_name`       | string  | Nom de l'auteur du commit. |
| `commit.authored_date`     | string  | Date et heure auxquelles le commit a été rédigé, au format ISO 8601. |
| `commit.committed_date`    | string  | Date et heure auxquelles le commit a été soumis, au format ISO 8601. |
| `commit.committer_email`   | string  | Adresse e-mail de l'utilisateur qui a soumis la modification. |
| `commit.committer_name`    | string  | Nom de l'utilisateur qui a soumis la modification. |
| `commit.created_at`        | string  | Date et heure auxquelles le commit a été créé, au format ISO 8601. |
| `commit.extended_trailers` | objet  | Trailers Git étendus analysés depuis le message de commit. |
| `commit.id`                | string  | SHA complet du commit. |
| `commit.message`           | string  | Message de commit complet. |
| `commit.parent_ids`        | tableau   | Tableau des SHA des commits parents. |
| `commit.short_id`          | string  | SHA abrégé du commit. |
| `commit.title`             | string  | Titre du message de commit. |
| `commit.trailers`          | objet  | Trailers Git analysés depuis le message de commit. |
| `commit.web_url`           | string  | URL pour afficher le commit dans l'interface utilisateur GitLab. |
| `default`                  | boolean | Si `true`, définit cette branche comme branche par défaut du projet. |
| `developers_can_merge`     | boolean | Si `true`, les utilisateurs avec le rôle Developer peuvent fusionner vers cette branche. |
| `developers_can_push`      | boolean | Si `true`, les utilisateurs avec le rôle Developer peuvent pousser vers cette branche. |
| `merged`                   | boolean | Si `true`, la branche a été fusionnée dans la branche par défaut. |
| `name`                     | string  | Nom de la branche. |
| `protected`                | boolean | Si `true`, la branche est protégée contre les push forcés et la suppression. |
| `web_url`                  | string  | URL pour afficher la branche dans l'interface utilisateur GitLab. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/branches?branch=newbranch&ref=main"
```

Exemple de réponse :

```json
{
  "commit": {
    "id": "7b5c3cc8be40ee161ae89a06bba6229da1032a0c",
    "short_id": "7b5c3cc",
    "created_at": "2012-06-28T03:44:20-07:00",
    "parent_ids": [
      "4ad91d3c1144c406e50c7b33bae684bd6837faf8"
    ],
    "title": "add projects API",
    "message": "add projects API",
    "author_name": "John Smith",
    "author_email": "john@example.com",
    "authored_date": "2012-06-27T05:51:39-07:00",
    "committer_name": "John Smith",
    "committer_email": "john@example.com",
    "committed_date": "2012-06-28T03:44:20-07:00",
    "trailers": {},
    "extended_trailers": {},
    "web_url": "https://gitlab.example.com/my-group/my-project/-/commit/7b5c3cc8be40ee161ae89a06bba6229da1032a0c"
  },
  "name": "newbranch",
  "merged": false,
  "protected": false,
  "default": false,
  "developers_can_push": false,
  "developers_can_merge": false,
  "can_push": true,
  "web_url": "https://gitlab.example.com/my-group/my-project/-/tree/newbranch"
}
```

## Supprimer une branche du dépôt {#delete-repository-branch}

Supprime une branche spécifiée du dépôt.

> [!note]
> En cas d'erreur, un message d'explication est fourni.

```plaintext
DELETE /projects/:id/repository/branches/:branch
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `branch`  | string            | Oui      | [Nom encodé dans l'URL](rest/_index.md#namespaced-paths) de la branche. Impossible de supprimer la branche par défaut ou les branches protégées. |

En cas de succès, retourne [`204 No Content`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/branches/newbranch"
```

> [!note]
> La suppression d'une branche n'efface pas complètement toutes les données associées. Certaines informations sont conservées pour maintenir l'historique du projet et pour prendre en charge les processus de récupération. Pour plus d'informations, consultez [gérer les informations sensibles](../topics/git/undo.md#handle-sensitive-information).

## Supprimer toutes les branches fusionnées {#delete-all-merged-branches}

Supprime toutes les branches fusionnées dans la branche par défaut du projet.

> [!note]
> Les [branches protégées](../user/project/repository/branches/protected.md) ne sont pas supprimées dans le cadre de cette opération.

```plaintext
DELETE /projects/:id/repository/merged_branches
```

Attributs pris en charge :

| Attribut | Type              | Obligatoire | Description |
|-----------|-------------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

En cas de succès, retourne [`202 Accepted`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/merged_branches"
```

## Sujets connexes {#related-topics}

- [Branches](../user/project/repository/branches/_index.md)
- [Branches protégées](../user/project/repository/branches/protected.md)
- [API des branches protégées](protected_branches.md)
