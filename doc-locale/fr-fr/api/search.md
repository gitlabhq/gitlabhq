---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API de recherche
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour [effectuer des recherches dans GitLab](../user/search/_index.md). Chaque appel à cette API nécessite une authentification.

Certaines portées sont disponibles pour la [recherche de base](../user/search/_index.md#available-scopes). Lorsque la [recherche avancée](../user/search/advanced_search.md#available-scopes) ou la [recherche de code exacte](../user/search/exact_code_search.md#available-scopes) est activée, des portées supplémentaires sont disponibles pour les opérations de [recherche globale](#search-an-instance), de [recherche dans un groupe](#search-a-group) et de [recherche dans un projet](#search-a-project).

Si vous souhaitez utiliser la recherche de base à la place, consultez [spécifier un type de recherche](../user/search/_index.md#specify-a-search-type).

L'API de recherche prend en charge la [pagination basée sur le décalage](rest/_index.md#offset-based-pagination).

## Rechercher dans une instance {#search-an-instance}

Rechercher un [terme](../user/search/advanced_search.md#syntax) dans l'ensemble de l'instance GitLab. La réponse dépend de la portée demandée.

```plaintext
GET /search
```

| Attribut          | Type             | Obligatoire | Description                                                                                                                                                                                                    |
|--------------------|------------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `scope`            | string           | Oui      | La portée dans laquelle effectuer la recherche. Les valeurs incluent `projects`, `issues`, `work_items`, `merge_requests`, `milestones`, `snippet_titles` et `users`. Les portées supplémentaires sont `wiki_blobs`, `commits`, `blobs` et `notes`.               |
| `search`           | string           | Oui      | Le terme de recherche.                                                                                                                                                                                               |
| `search_type`      | string           | Non       | Le type de recherche à utiliser. Les valeurs incluent `basic`, `advanced` et `zoekt`.                                                                                                                                       |
| `confidential`     | boolean          | Non       | Filtrer par confidentialité. Prend en charge les portées `issues` et `work_items` ; les autres portées sont ignorées.                                                                                                                                  |
| `exclude_forks`      | boolean          | Non       | Exclut les projets forqués de la recherche. Disponible pour la recherche de code exacte. Si ce paramètre n'est pas défini, les duplications seront exclues. [Introduites](https://gitlab.com/gitlab-org/gitlab/-/work_items/493281) dans GitLab 18.7.          |
| `regex`              | boolean          | Non       | Utilise des expressions régulières pour rechercher du code. Disponible pour la recherche de code exacte. Si ce paramètre n'est pas défini, les expressions régulières sont utilisées. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/521686) dans GitLab 18.9. |
| `fields`             | tableau de chaînes de caractères | Non       | Tableau des champs dans lesquels vous souhaitez effectuer la recherche ; les valeurs autorisées sont uniquement `title`. Prend en charge uniquement les portées `issues` et `merge_requests`. Premium et Ultimate uniquement.                                                            |
| `include_archived`   | boolean          | Non       | Inclut les projets archivés dans la recherche. La valeur par défaut est `false`. [Introduites](https://gitlab.com/gitlab-org/gitlab/-/work_items/493281) dans GitLab 18.7.                                                           |
| `num_context_lines`  | integer          | Non       | Nombre de lignes de contexte à inclure autour de chaque correspondance dans les résultats. Disponible uniquement pour la recherche avancée et la recherche de code exacte. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/583217) dans GitLab 18.11. |
| `state`              | string           | Non       | Filtrer par état. Prend en charge les portées `issues`, `work_items` et `merge_requests` ; les autres portées sont ignorées.                                                                                                                      |
| `type`               | tableau de chaînes de caractères | Non       | Filtrer les éléments de travail par type. S'applique uniquement à la portée `work_items`. Types disponibles : `issue`, `task`, `epic`, `incident`, `test_case`, `requirement`, `objective`, `key_result`, `ticket`.                          |
| `order_by`           | string           | Non       | Les valeurs autorisées sont uniquement `created_at`. Si ce paramètre n'est pas défini, les résultats sont triés par `created_at` dans l'ordre décroissant pour la recherche de base, ou par les documents les plus pertinents pour la recherche avancée.                              |
| `sort`               | string           | Non       | Les valeurs autorisées sont uniquement `asc` ou `desc`. Si ce paramètre n'est pas défini, les résultats sont triés par `created_at` dans l'ordre décroissant pour la recherche de base, ou par les documents les plus pertinents pour la recherche avancée.                           |

### Portée : `projects` {#scope-projects}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=projects&search=flight"
```

Exemple de réponse :

```json
[
  {
    "id": 6,
    "description": "Nobis sed ipsam vero quod cupiditate veritatis hic.",
    "name": "Flight",
    "name_with_namespace": "Twitter / Flight",
    "path": "flight",
    "path_with_namespace": "twitter/flight",
    "created_at": "2017-09-05T07:58:01.621Z",
    "default_branch": "main",
    "tag_list":[], //deprecated, use `topics` instead
    "topics":[],
    "ssh_url_to_repo": "ssh://jarka@localhost:2222/twitter/flight.git",
    "http_url_to_repo": "http://localhost:3000/twitter/flight.git",
    "web_url": "http://localhost:3000/twitter/flight",
    "readme_url": "http://localhost:3000/twitter/flight/-/blob/main/README.md",
    "avatar_url": null,
    "star_count": 0,
    "forks_count": 0,
    "last_activity_at": "2018-01-31T09:56:30.902Z"
  }
]
```

### Portée : `issues` {#scope-issues}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=issues&search=file"
```

Exemple de réponse :

```json
[
  {
    "id": 83,
    "iid": 1,
    "project_id": 12,
    "title": "Add file",
    "description": "Add first file",
    "state": "opened",
    "created_at": "2018-01-24T06:02:15.514Z",
    "updated_at": "2018-02-06T12:36:23.263Z",
    "closed_at": null,
    "labels":[],
    "milestone": null,
    "assignees": [{
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    }],
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    },
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "discussion_locked": null,
    "web_url": "http://localhost:3000/h5bp/7bp/subgroup-prj/issues/1",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

> [!note]
> La colonne `assignee` est obsolète. Elle est affichée sous forme de tableau `assignees` d'une seule entrée pour être conforme à l'API GitLab EE.

### Portée : `work_items` {#scope-work_items}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=work_items&search=migrate"
```

Exemple de réponse :

```json
[
  {
    "id": 142,
    "iid": 9,
    "project_id": 12,
    "title": "Migrate to new database",
    "description": "Database migration task",
    "state": "opened",
    "created_at": "2018-03-15T08:12:31.489Z",
    "updated_at": "2018-03-20T14:22:18.371Z",
    "closed_at": null,
    "labels": ["backend"],
    "milestone": null,
    "assignees": [{
      "id": 25,
      "name": "John Doe",
      "username": "john.doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/a1b2c3d4e5f6g7h8i9j0?s=80&d=identicon",
      "web_url": "http://localhost:3000/john.doe"
    }],
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "type": "TASK",
    "user_notes_count": 2,
    "upvotes": 1,
    "downvotes": 0,
    "due_date": "2018-04-01",
    "confidential": false,
    "discussion_locked": null,
    "web_url": "http://localhost:3000/my-group/my-project/-/work_items/9",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

Vous pouvez filtrer les éléments de travail par type à l'aide du paramètre `type` :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=work_items&search=backend&type[]=task&type[]=issue"
```

### Portée : `merge_requests` {#scope-merge_requests}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=merge_requests&search=file"
```

Exemple de réponse :

```json
[
  {
    "id": 56,
    "iid": 8,
    "project_id": 6,
    "title": "Add first file",
    "description": "This is a test MR to add file",
    "state": "opened",
    "created_at": "2018-01-22T14:21:50.830Z",
    "updated_at": "2018-02-06T12:40:33.295Z",
    "target_branch": "main",
    "source_branch": "jaja-test",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 5,
      "name": "Jacquelyn Kutch",
      "username": "abigail",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/3138c66095ee4bd11a508c2f7f7772da?s=80&d=identicon",
      "web_url": "http://localhost:3000/abigail"
    },
    "source_project_id": 6,
    "target_project_id": 6,
    "labels": [
      "ruby",
      "tests"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 13,
      "iid": 3,
      "project_id": 6,
      "title": "v2.0",
      "description": "Qui aut qui eos dolor beatae itaque tempore molestiae.",
      "state": "active",
      "created_at": "2017-09-05T07:58:29.099Z",
      "updated_at": "2017-09-05T07:58:29.099Z",
      "due_date": null,
      "start_date": null
    },
    "merge_when_pipeline_succeeds": false,
    "merge_status": "can_be_merged",
    "sha": "78765a2d5e0a43585945c58e61ba2f822e4d090b",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 0,
    "discussion_locked": null,
    "should_remove_source_branch": null,
    "force_remove_source_branch": true,
    "web_url": "http://localhost:3000/twitter/flight/merge_requests/8",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

### Portée : `milestones` {#scope-milestones}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=milestones&search=release"
```

Exemple de réponse :

```json
[
  {
    "id": 44,
    "iid": 1,
    "project_id": 12,
    "title": "next release",
    "description": "Next release milestone",
    "state": "active",
    "created_at": "2018-02-06T12:43:39.271Z",
    "updated_at": "2018-02-06T12:44:01.298Z",
    "due_date": "2018-04-18",
    "start_date": "2018-02-04"
  }
]
```

### Portée : `snippet_titles` {#scope-snippet_titles}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=snippet_titles&search=sample"
```

Exemple de réponse :

```json
[
  {
    "id": 50,
    "title": "Sample file",
    "file_name": "file.rb",
    "description": "Simple ruby file",
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "updated_at": "2018-02-06T12:49:29.104Z",
    "created_at": "2017-11-28T08:20:18.071Z",
    "project_id": 9,
    "web_url": "http://localhost:3000/root/jira-test/snippets/50"
  }
]
```

### Portée : `users` {#scope-users}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=users&search=doe"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://localhost/user1"
  }
]
```

### Portée : `wiki_blobs` {#scope-wiki_blobs}

{{< details >}}

- Édition : Premium, Ultimate

{{< /details >}}

Utilisez cette portée pour effectuer des recherches dans les wikis.

Cette portée est disponible uniquement lorsque [la recherche avancée est activée](../user/search/advanced_search.md#use-advanced-search).

Les filtres suivants sont disponibles pour cette portée :

- `filename`
- `path`
- `extension`

Pour utiliser un filtre, incluez-le dans votre requête (par exemple, `a query filename:some_name*`).

Vous pouvez utiliser des caractères génériques (`*`) pour la correspondance glob.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=wiki_blobs&search=bye"
```

Exemple de réponse :

```json

[
  {
    "basename": "home",
    "data": "hello\n\nand bye\n\nend",
    "path": "home.md",
    "filename": "home.md",
    "id": null,
    "ref": "main",
    "startline": 5,
    "project_id": 6,
    "group_id": null
  }
]
```

> [!note]
> `filename` est obsolète en faveur de `path`. Les deux renvoient le chemin complet du fichier dans le dépôt, mais à l'avenir, `filename` est destiné à n'être que le nom du fichier et non le chemin complet. Pour plus de détails, consultez [le ticket 34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521).

### Portée : `commits` {#scope-commits}

{{< details >}}

- Édition : Premium, Ultimate

{{< /details >}}

Cette portée est disponible uniquement lorsque [la recherche avancée est activée](../user/search/advanced_search.md#use-advanced-search).

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=commits&search=bye"
```

Exemple de réponse :

```json

[
  {
  "id": "4109c2d872d5fdb1ed057400d103766aaea97f98",
  "short_id": "4109c2d8",
  "title": "goodbye $.browser",
  "created_at": "2013-02-18T22:02:54.000Z",
  "parent_ids": [
    "59d05353ab575bcc2aa958fe1782e93297de64c9"
  ],
  "message": "goodbye $.browser\n",
  "author_name": "angus croll",
  "author_email": "anguscroll@gmail.com",
  "authored_date": "2013-02-18T22:02:54.000Z",
  "committer_name": "angus croll",
  "committer_email": "anguscroll@gmail.com",
  "committed_date": "2013-02-18T22:02:54.000Z",
  "project_id": 6
  }
]
```

### Portée : `blobs` {#scope-blobs}

{{< details >}}

- Édition : Premium, Ultimate

{{< /details >}}

Utilisez cette portée pour effectuer des recherches dans le code.

Cette portée est disponible uniquement lorsque la [recherche avancée](../user/search/advanced_search.md#use-advanced-search) ou la [recherche de code exacte](../user/search/exact_code_search.md#use-exact-code-search) est activée.

Les filtres suivants sont disponibles pour cette portée :

- `filename`
- `path`
- `extension`

Pour utiliser un filtre, incluez-le dans votre requête (par exemple, `a query filename:some_name*`).

Vous pouvez utiliser des caractères génériques (`*`) pour la correspondance glob.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=blobs&search=installation"
```

Exemple de réponse :

```json

[
  {
    "basename": "README",
    "data": "```\n\n## Installation\n\nQuick start using the [pre-built",
    "path": "README.md",
    "filename": "README.md",
    "id": null,
    "ref": "main",
    "startline": 46,
    "project_id": 6
  }
]
```

> [!note]
> `filename` est obsolète en faveur de `path`. Les deux renvoient le chemin complet du fichier dans le dépôt, mais à l'avenir, `filename` est destiné à n'être que le nom du fichier et non le chemin complet. Pour plus de détails, consultez [le ticket 34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521). La syntaxe Elasticsearch peut ne pas fonctionner correctement avec la recherche de code exacte. Remplacez les requêtes avec caractères génériques Elasticsearch par des expressions régulières pour la recherche de code exacte. Pour plus d'informations, consultez [le ticket 521686](https://gitlab.com/gitlab-org/gitlab/-/issues/521686).

### Portée : `notes` {#scope-notes}

{{< details >}}

- Édition : Premium, Ultimate

{{< /details >}}

Cette portée est disponible uniquement lorsque [la recherche avancée est activée](../user/search/advanced_search.md#use-advanced-search).

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=notes&search=maxime"
```

Exemple de réponse :

```json
[
  {
    "id": 191,
    "body": "Harum maxime consequuntur et et deleniti assumenda facilis.",
    "attachment": null,
    "author": {
      "id": 23,
      "name": "User 1",
      "username": "user1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/111d68d06e2d317b5a59c2c6c5bad808?s=80&d=identicon",
      "web_url": "http://localhost:3000/user1"
    },
    "created_at": "2017-09-05T08:01:32.068Z",
    "updated_at": "2017-09-05T08:01:32.068Z",
    "system": false,
    "noteable_id": 22,
    "noteable_type": "Issue",
    "project_id": 6,
    "noteable_iid": 2
  }
]
```

## Rechercher dans un groupe {#search-a-group}

Rechercher un [terme](../user/search/_index.md) dans le groupe spécifié.

Si un utilisateur n'est pas membre d'un groupe et que le groupe est privé, une requête `GET` sur ce groupe renvoie un code d'état `404 Not Found`.

```plaintext
GET /groups/:id/search
```

| Attribut          | Type              | Obligatoire | Description                                                                                                                                                                                                    |
|--------------------|-------------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`               | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe.                                                                                                                                    |
| `scope`            | string            | Oui      | La portée dans laquelle effectuer la recherche. Les valeurs incluent `projects`, `issues`, `work_items`, `merge_requests`, `milestones` et `users`. Les portées supplémentaires sont `wiki_blobs`, `commits`, `blobs` et `notes`.                                 |
| `search`           | string            | Oui      | Le terme de recherche.                                                                                                                                                                                               |
| `search_type`      | string            | Non       | Le type de recherche à utiliser. Les valeurs incluent `basic`, `advanced` et `zoekt`.                                                                                                                                       |
| `confidential`     | boolean           | Non       | Filtrer par confidentialité. Prend en charge les portées `issues` et `work_items` ; les autres portées sont ignorées.                                                                                                                                  |
| `exclude_forks`      | boolean           | Non       | Exclut les projets forqués de la recherche. Disponible pour la recherche de code exacte. Si ce paramètre n'est pas défini, les duplications seront exclues. [Introduites](https://gitlab.com/gitlab-org/gitlab/-/work_items/493281) dans GitLab 18.7.          |
| `regex`              | boolean           | Non       | Utilise des expressions régulières pour rechercher du code. Disponible pour la recherche de code exacte. Si ce paramètre n'est pas défini, les expressions régulières sont utilisées. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/521686) dans GitLab 18.9. |
| `fields`             | tableau de chaînes de caractères  | Non       | Tableau des champs dans lesquels vous souhaitez effectuer la recherche ; les valeurs autorisées sont uniquement `title`. Prend en charge uniquement les portées `issues` et `merge_requests`. Premium et Ultimate uniquement.                                                            |
| `include_archived`   | boolean           | Non       | Inclut les projets archivés dans la recherche. La valeur par défaut est `false`. [Introduites](https://gitlab.com/gitlab-org/gitlab/-/work_items/493281) dans GitLab 18.7.                                                           |
| `num_context_lines`  | integer           | Non       | Nombre de lignes de contexte à inclure autour de chaque correspondance dans les résultats. Disponible uniquement pour la recherche avancée et la recherche de code exacte. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/583217) dans GitLab 18.11. |
| `state`              | string            | Non       | Filtrer par état. Prend en charge les portées `issues`, `work_items` et `merge_requests` ; les autres portées sont ignorées.                                                                                                                      |
| `type`               | tableau de chaînes de caractères  | Non       | Filtrer les éléments de travail par type. S'applique uniquement à la portée `work_items`. Types disponibles : `issue`, `task`, `epic`, `incident`, `test_case`, `requirement`, `objective`, `key_result`, `ticket`.                          |
| `order_by`           | string            | Non       | Les valeurs autorisées sont uniquement `created_at`. Si ce paramètre n'est pas défini, les résultats sont triés par `created_at` dans l'ordre décroissant pour la recherche de base, ou par les documents les plus pertinents pour la recherche avancée.                              |
| `sort`               | string            | Non       | Les valeurs autorisées sont uniquement `asc` ou `desc`. Si ce paramètre n'est pas défini, les résultats sont triés par `created_at` dans l'ordre décroissant pour la recherche de base, ou par les documents les plus pertinents pour la recherche avancée.                           |

La réponse dépend de la portée demandée.

### Portée : `projects` {#scope-projects-1}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/search?scope=projects&search=flight"
```

Exemple de réponse :

```json
[
  {
    "id": 6,
    "description": "Nobis sed ipsam vero quod cupiditate veritatis hic.",
    "name": "Flight",
    "name_with_namespace": "Twitter / Flight",
    "path": "flight",
    "path_with_namespace": "twitter/flight",
    "created_at": "2017-09-05T07:58:01.621Z",
    "default_branch": "main",
    "tag_list":[], //deprecated, use `topics` instead
    "topics":[],
    "ssh_url_to_repo": "ssh://jarka@localhost:2222/twitter/flight.git",
    "http_url_to_repo": "http://localhost:3000/twitter/flight.git",
    "web_url": "http://localhost:3000/twitter/flight",
    "readme_url": "http://localhost:3000/twitter/flight/-/blob/main/README.md",
    "avatar_url": null,
    "star_count": 0,
    "forks_count": 0,
    "last_activity_at": "2018-01-31T09:56:30.902Z"
  }
]
```

### Portée : `issues` {#scope-issues-1}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/search?scope=issues&search=file"
```

Exemple de réponse :

```json
[
  {
    "id": 83,
    "iid": 1,
    "project_id": 12,
    "title": "Add file",
    "description": "Add first file",
    "state": "opened",
    "created_at": "2018-01-24T06:02:15.514Z",
    "updated_at": "2018-02-06T12:36:23.263Z",
    "closed_at": null,
    "labels":[],
    "milestone": null,
    "assignees": [{
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    }],
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    },
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "discussion_locked": null,
    "web_url": "http://localhost:3000/h5bp/7bp/subgroup-prj/issues/1",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

> [!note]
> La colonne `assignee` est obsolète. Il s'agit désormais d'un tableau `assignees` d'une seule entrée.

### Portée : `work_items` {#scope-work_items-1}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/search?scope=work_items&search=migrate"
```

Exemple de réponse :

```json
[
  {
    "id": 142,
    "iid": 9,
    "project_id": 12,
    "title": "Migrate to new database",
    "description": "Database migration task",
    "state": "opened",
    "created_at": "2018-03-15T08:12:31.489Z",
    "updated_at": "2018-03-20T14:22:18.371Z",
    "closed_at": null,
    "labels": ["backend"],
    "milestone": null,
    "assignees": [{
      "id": 25,
      "name": "John Doe",
      "username": "john.doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/a1b2c3d4e5f6g7h8i9j0?s=80&d=identicon",
      "web_url": "http://localhost:3000/john.doe"
    }],
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "type": "TASK",
    "user_notes_count": 2,
    "upvotes": 1,
    "downvotes": 0,
    "due_date": "2018-04-01",
    "confidential": false,
    "discussion_locked": null,
    "web_url": "http://localhost:3000/my-group/my-project/-/work_items/9",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

Vous pouvez filtrer les éléments de travail par type à l'aide du paramètre `type` :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/search?scope=work_items&search=backend&type[]=task&type[]=issue"
```

### Portée : `merge_requests` {#scope-merge_requests-1}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/search?scope=merge_requests&search=file"
```

Exemple de réponse :

```json
[
  {
    "id": 56,
    "iid": 8,
    "project_id": 6,
    "title": "Add first file",
    "description": "This is a test MR to add file",
    "state": "opened",
    "created_at": "2018-01-22T14:21:50.830Z",
    "updated_at": "2018-02-06T12:40:33.295Z",
    "target_branch": "main",
    "source_branch": "jaja-test",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 5,
      "name": "Jacquelyn Kutch",
      "username": "abigail",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/3138c66095ee4bd11a508c2f7f7772da?s=80&d=identicon",
      "web_url": "http://localhost:3000/abigail"
    },
    "source_project_id": 6,
    "target_project_id": 6,
    "labels": [
      "ruby",
      "tests"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 13,
      "iid": 3,
      "project_id": 6,
      "title": "v2.0",
      "description": "Qui aut qui eos dolor beatae itaque tempore molestiae.",
      "state": "active",
      "created_at": "2017-09-05T07:58:29.099Z",
      "updated_at": "2017-09-05T07:58:29.099Z",
      "due_date": null,
      "start_date": null
    },
    "merge_when_pipeline_succeeds": false,
    "merge_status": "can_be_merged",
    "sha": "78765a2d5e0a43585945c58e61ba2f822e4d090b",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 0,
    "discussion_locked": null,
    "should_remove_source_branch": null,
    "force_remove_source_branch": true,
    "web_url": "http://localhost:3000/twitter/flight/merge_requests/8",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

### Portée : `milestones` {#scope-milestones-1}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/search?scope=milestones&search=release"
```

Exemple de réponse :

```json
[
  {
    "id": 44,
    "iid": 1,
    "project_id": 12,
    "title": "next release",
    "description": "Next release milestone",
    "state": "active",
    "created_at": "2018-02-06T12:43:39.271Z",
    "updated_at": "2018-02-06T12:44:01.298Z",
    "due_date": "2018-04-18",
    "start_date": "2018-02-04"
  }
]
```

### Portée : `users` {#scope-users-1}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/search?scope=users&search=doe"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://localhost/user1"
  }
]
```

### Portée : `wiki_blobs` {#scope-wiki_blobs-1}

{{< details >}}

- Édition : Premium, Ultimate

{{< /details >}}

Utilisez cette portée pour effectuer des recherches dans les wikis.

Cette portée est disponible uniquement lorsque [la recherche avancée est activée](../user/search/advanced_search.md#use-advanced-search).

Les filtres suivants sont disponibles pour cette portée :

- `filename`
- `path`
- `extension`

Pour utiliser un filtre, incluez-le dans votre requête (par exemple, `a query filename:some_name*`).

Vous pouvez utiliser des caractères génériques (`*`) pour la correspondance glob.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/6/search?scope=wiki_blobs&search=bye"
```

Exemple de réponse :

```json

[
  {
    "basename": "home",
    "data": "hello\n\nand bye\n\nend",
    "path": "home.md",
    "filename": "home.md",
    "id": null,
    "ref": "main",
    "startline": 5,
    "project_id": 6,
    "group_id": 1
  }
]
```

> [!note]
> `filename` est obsolète en faveur de `path`. Les deux renvoient le chemin complet du fichier dans le dépôt, mais à l'avenir, `filename` est destiné à n'être que le nom du fichier et non le chemin complet. Pour plus de détails, consultez [le ticket 34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521).

### Portée : `commits` {#scope-commits-1}

{{< details >}}

- Édition : Premium, Ultimate

{{< /details >}}

Cette portée est disponible uniquement lorsque [la recherche avancée est activée](../user/search/advanced_search.md#use-advanced-search).

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/6/search?scope=commits&search=bye"
```

Exemple de réponse :

```json

[
  {
  "id": "4109c2d872d5fdb1ed057400d103766aaea97f98",
  "short_id": "4109c2d8",
  "title": "goodbye $.browser",
  "created_at": "2013-02-18T22:02:54.000Z",
  "parent_ids": [
    "59d05353ab575bcc2aa958fe1782e93297de64c9"
  ],
  "message": "goodbye $.browser\n",
  "author_name": "angus croll",
  "author_email": "anguscroll@gmail.com",
  "authored_date": "2013-02-18T22:02:54.000Z",
  "committer_name": "angus croll",
  "committer_email": "anguscroll@gmail.com",
  "committed_date": "2013-02-18T22:02:54.000Z",
  "project_id": 6
  }
]
```

### Portée : `blobs` {#scope-blobs-1}

{{< details >}}

- Édition : Premium, Ultimate

{{< /details >}}

Utilisez cette portée pour effectuer des recherches dans le code.

Cette portée est disponible uniquement lorsque la [recherche avancée](../user/search/advanced_search.md#use-advanced-search) ou la [recherche de code exacte](../user/search/exact_code_search.md#use-exact-code-search) est activée.

Les filtres suivants sont disponibles pour cette portée :

- `filename`
- `path`
- `extension`

Pour utiliser un filtre, incluez-le dans votre requête (par exemple, `a query filename:some_name*`).

Vous pouvez utiliser des caractères génériques (`*`) pour la correspondance glob.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/6/search?scope=blobs&search=installation"
```

Exemple de réponse :

```json

[
  {
    "basename": "README",
    "data": "```\n\n## Installation\n\nQuick start using the [pre-built",
    "path": "README.md",
    "filename": "README.md",
    "id": null,
    "ref": "main",
    "startline": 46,
    "project_id": 6
  }
]
```

> [!note]
> `filename` est obsolète en faveur de `path`. Les deux renvoient le chemin complet du fichier dans le dépôt, mais à l'avenir, `filename` est destiné à n'être que le nom du fichier et non le chemin complet. Pour plus de détails, consultez [le ticket 34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521). La syntaxe Elasticsearch peut ne pas fonctionner correctement avec la recherche de code exacte. Remplacez les requêtes avec caractères génériques Elasticsearch par des expressions régulières pour la recherche de code exacte. Pour plus d'informations, consultez [le ticket 521686](https://gitlab.com/gitlab-org/gitlab/-/issues/521686).

### Portée : `notes` {#scope-notes-1}

{{< details >}}

- Édition : Premium, Ultimate

{{< /details >}}

Cette portée est disponible uniquement lorsque [la recherche avancée est activée](../user/search/advanced_search.md#use-advanced-search).

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/6/search?scope=notes&search=maxime"
```

Exemple de réponse :

```json
[
  {
    "id": 191,
    "body": "Harum maxime consequuntur et et deleniti assumenda facilis.",
    "attachment": null,
    "author": {
      "id": 23,
      "name": "User 1",
      "username": "user1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/111d68d06e2d317b5a59c2c6c5bad808?s=80&d=identicon",
      "web_url": "http://localhost:3000/user1"
    },
    "created_at": "2017-09-05T08:01:32.068Z",
    "updated_at": "2017-09-05T08:01:32.068Z",
    "system": false,
    "noteable_id": 22,
    "noteable_type": "Issue",
    "project_id": 6,
    "noteable_iid": 2
  }
]
```

## Rechercher dans un projet {#search-a-project}

Rechercher un [terme](../user/search/_index.md) dans le projet spécifié.

Si un utilisateur n'est pas membre d'un projet et que le projet est privé, une requête `GET` sur ce projet renvoie un code d'état `404`.

```plaintext
GET /projects/:id/search
```

| Attribut      | Type              | Obligatoire | Description                                                                                                                                                                                                    |
|----------------|-------------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`                 | entier ou chaîne de caractères | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).                                                                                                                                  |
| `scope`              | string            | Oui      | La portée dans laquelle effectuer la recherche. Les valeurs incluent `issues`, `work_items`, `merge_requests`, `milestones` et `users`. Les portées supplémentaires sont `wiki_blobs`, `commits`, `blobs` et `notes`.                                             |
| `search`             | string            | Oui      | Le terme de recherche.                                                                                                                                                                                               |
| `search_type`        | string            | Non       | Le type de recherche à utiliser. Les valeurs incluent `basic`, `advanced` et `zoekt`.                                                                                                                                       |
| `confidential`       | boolean           | Non       | Filtrer par confidentialité. Prend en charge les portées `issues` et `work_items` ; les autres portées sont ignorées.                                                                                                                                  |
| `regex`              | boolean           | Non       | Utilise des expressions régulières pour rechercher du code. Disponible pour la recherche de code exacte. Si ce paramètre n'est pas défini, les expressions régulières sont utilisées. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/521686) dans GitLab 18.9. |
| `fields`             | tableau de chaînes de caractères  | Non       | Tableau des champs dans lesquels vous souhaitez effectuer la recherche ; les valeurs autorisées sont uniquement `title`. Prend en charge uniquement les portées `issues` et `merge_requests`. Premium et Ultimate uniquement.                                                            |
| `num_context_lines`  | integer           | Non       | Nombre de lignes de contexte à inclure autour de chaque correspondance dans les résultats. Disponible uniquement pour la recherche avancée et la recherche de code exacte. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/583217) dans GitLab 18.11. |
| `ref`                | string            | Non       | Le nom d'une branche ou d'un tag du dépôt sur lequel effectuer la recherche. La branche par défaut du projet est utilisée par défaut. Applicable uniquement pour les portées `blobs`, `commits` et `wiki_blobs`.                                         |
| `state`              | string            | Non       | Filtrer par état. Prend en charge les portées `issues`, `work_items` et `merge_requests` ; les autres portées sont ignorées.                                                                                                                      |
| `type`               | tableau de chaînes de caractères  | Non       | Filtrer les éléments de travail par type. S'applique uniquement à la portée `work_items`. Types disponibles : `issue`, `task`, `epic`, `incident`, `test_case`, `requirement`, `objective`, `key_result`, `ticket`.                          |
| `order_by`           | string            | Non       | Les valeurs autorisées sont uniquement `created_at`. Si ce paramètre n'est pas défini, les résultats sont triés par `created_at` dans l'ordre décroissant pour la recherche de base, ou par les documents les plus pertinents pour la recherche avancée.                              |
| `sort`               | string            | Non       | Les valeurs autorisées sont uniquement `asc` ou `desc`. Si ce paramètre n'est pas défini, les résultats sont triés par `created_at` dans l'ordre décroissant pour la recherche de base, ou par les documents les plus pertinents pour la recherche avancée.                           |

La réponse dépend de la portée demandée.

### Portée : `issues` {#scope-issues-2}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/12/search?scope=issues&search=file"
```

Exemple de réponse :

```json
[
  {
    "id": 83,
    "iid": 1,
    "project_id": 12,
    "title": "Add file",
    "description": "Add first file",
    "state": "opened",
    "created_at": "2018-01-24T06:02:15.514Z",
    "updated_at": "2018-02-06T12:36:23.263Z",
    "closed_at": null,
    "labels":[],
    "milestone": null,
    "assignees": [{
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    }],
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    },
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "discussion_locked": null,
    "web_url": "http://localhost:3000/h5bp/7bp/subgroup-prj/issues/1",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

> [!note]
> La colonne `assignee` est obsolète. Il s'agit désormais d'un tableau `assignees` d'une seule entrée.

### Portée : `work_items` {#scope-work_items-2}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/12/search?scope=work_items&search=migrate"
```

Exemple de réponse :

```json
[
  {
    "id": 142,
    "iid": 9,
    "project_id": 12,
    "title": "Migrate to new database",
    "description": "Database migration task",
    "state": "opened",
    "created_at": "2018-03-15T08:12:31.489Z",
    "updated_at": "2018-03-20T14:22:18.371Z",
    "closed_at": null,
    "labels": ["backend"],
    "milestone": null,
    "assignees": [{
      "id": 25,
      "name": "John Doe",
      "username": "john.doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/a1b2c3d4e5f6g7h8i9j0?s=80&d=identicon",
      "web_url": "http://localhost:3000/john.doe"
    }],
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "type": "TASK",
    "user_notes_count": 2,
    "upvotes": 1,
    "downvotes": 0,
    "due_date": "2018-04-01",
    "confidential": false,
    "discussion_locked": null,
    "web_url": "http://localhost:3000/my-group/my-project/-/work_items/9",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

Vous pouvez filtrer les éléments de travail par type à l'aide du paramètre `type` :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/12/search?scope=work_items&search=backend&type[]=task&type[]=issue"
```

### Portée : `merge_requests` {#scope-merge_requests-2}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/6/search?scope=merge_requests&search=file"
```

Exemple de réponse :

```json
[
  {
    "id": 56,
    "iid": 8,
    "project_id": 6,
    "title": "Add first file",
    "description": "This is a test MR to add file",
    "state": "opened",
    "created_at": "2018-01-22T14:21:50.830Z",
    "updated_at": "2018-02-06T12:40:33.295Z",
    "target_branch": "main",
    "source_branch": "jaja-test",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 5,
      "name": "Jacquelyn Kutch",
      "username": "abigail",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/3138c66095ee4bd11a508c2f7f7772da?s=80&d=identicon",
      "web_url": "http://localhost:3000/abigail"
    },
    "source_project_id": 6,
    "target_project_id": 6,
    "labels": [
      "ruby",
      "tests"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 13,
      "iid": 3,
      "project_id": 6,
      "title": "v2.0",
      "description": "Qui aut qui eos dolor beatae itaque tempore molestiae.",
      "state": "active",
      "created_at": "2017-09-05T07:58:29.099Z",
      "updated_at": "2017-09-05T07:58:29.099Z",
      "due_date": null,
      "start_date": null
    },
    "merge_when_pipeline_succeeds": false,
    "merge_status": "can_be_merged",
    "sha": "78765a2d5e0a43585945c58e61ba2f822e4d090b",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 0,
    "discussion_locked": null,
    "should_remove_source_branch": null,
    "force_remove_source_branch": true,
    "web_url": "http://localhost:3000/twitter/flight/merge_requests/8",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

### Portée : `milestones` {#scope-milestones-2}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/12/search?scope=milestones&search=release"
```

Exemple de réponse :

```json
[
  {
    "id": 44,
    "iid": 1,
    "project_id": 12,
    "title": "next release",
    "description": "Next release milestone",
    "state": "active",
    "created_at": "2018-02-06T12:43:39.271Z",
    "updated_at": "2018-02-06T12:44:01.298Z",
    "due_date": "2018-04-18",
    "start_date": "2018-02-04"
  }
]
```

### Portée : `users` {#scope-users-2}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/6/search?scope=users&search=doe"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://localhost/user1"
  }
]
```

### Portée : `wiki_blobs` {#scope-wiki_blobs-2}

Utilisez cette portée pour effectuer des recherches dans les wikis.

Les filtres suivants sont disponibles pour cette portée :

- `filename`
- `path`
- `extension`

Pour utiliser un filtre, incluez-le dans votre requête (par exemple, `a query filename:some_name*`).

Vous pouvez utiliser des caractères génériques (`*`) pour la correspondance glob.

Les recherches de blobs wiki sont effectuées sur les noms de fichiers et les contenus. Résultats de recherche :

- Les résultats trouvés dans les noms de fichiers sont affichés avant les résultats trouvés dans les contenus.
- Peuvent contenir plusieurs correspondances pour le même blob, car la chaîne de recherche peut être trouvée à la fois dans le nom du fichier et dans le contenu, ou peut apparaître plusieurs fois dans le contenu.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/6/search?scope=wiki_blobs&search=bye"
```

Exemple de réponse :

```json

[
  {
    "basename": "home",
    "data": "hello\n\nand bye\n\nend",
    "path": "home.md",
    "filename": "home.md",
    "id": null,
    "ref": "main",
    "startline": 5,
    "project_id": 6,
    "group_id": 1
  }
]
```

> [!note]
> `filename` est obsolète en faveur de `path`. Les deux renvoient le chemin complet du fichier dans le dépôt, mais à l'avenir, `filename` est destiné à n'être que le nom du fichier et non le chemin complet. Pour plus de détails, consultez [le ticket 34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521).

### Portée : `commits` {#scope-commits-2}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/6/search?scope=commits&search=bye"
```

Exemple de réponse :

```json

[
  {
  "id": "4109c2d872d5fdb1ed057400d103766aaea97f98",
  "short_id": "4109c2d8",
  "title": "goodbye $.browser",
  "created_at": "2013-02-18T22:02:54.000Z",
  "parent_ids": [
    "59d05353ab575bcc2aa958fe1782e93297de64c9"
  ],
  "message": "goodbye $.browser\n",
  "author_name": "angus croll",
  "author_email": "anguscroll@gmail.com",
  "authored_date": "2013-02-18T22:02:54.000Z",
  "committer_name": "angus croll",
  "committer_email": "anguscroll@gmail.com",
  "committed_date": "2013-02-18T22:02:54.000Z",
  "project_id": 6
  }
]
```

### Portée : `blobs` {#scope-blobs-2}

Utilisez cette portée pour effectuer des recherches dans le code.

Les filtres suivants sont disponibles pour cette portée :

- `filename`
- `path`
- `extension`

Pour utiliser un filtre, incluez-le dans votre requête (par exemple, `a query filename:some_name*`).

Vous pouvez utiliser des caractères génériques (`*`) pour la correspondance glob.

Les recherches de blobs sont effectuées sur les noms de fichiers et les contenus. Résultats de recherche :

- Les résultats trouvés dans les noms de fichiers sont affichés avant les résultats trouvés dans les contenus.
- Peuvent contenir plusieurs correspondances pour le même blob, car la chaîne de recherche peut être trouvée à la fois dans le nom du fichier et dans le contenu, ou peut apparaître plusieurs fois dans le contenu.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/6/search?scope=blobs&search=keyword%20filename:*.py"
```

Exemple de réponse :

```json

[
  {
    "basename": "README",
    "data": "```\n\n## Installation\n\nQuick start using the [pre-built",
    "path": "README.md",
    "filename": "README.md",
    "id": null,
    "ref": "main",
    "startline": 46,
    "project_id": 6
  }
]
```

> [!note]
> `filename` est obsolète en faveur de `path`. Les deux renvoient le chemin complet du fichier dans le dépôt, mais à l'avenir, `filename` est destiné à n'être que le nom du fichier et non le chemin complet. Pour plus de détails, consultez [le ticket 34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521). La syntaxe Elasticsearch peut ne pas fonctionner correctement avec la recherche de code exacte. Remplacez les requêtes avec caractères génériques Elasticsearch par des expressions régulières pour la recherche de code exacte. Pour plus d'informations, consultez [le ticket 521686](https://gitlab.com/gitlab-org/gitlab/-/issues/521686).

### Portée : `notes` {#scope-notes-2}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/6/search?scope=notes&search=maxime"
```

Exemple de réponse :

```json
[
  {
    "id": 191,
    "body": "Harum maxime consequuntur et et deleniti assumenda facilis.",
    "attachment": null,
    "author": {
      "id": 23,
      "name": "User 1",
      "username": "user1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/111d68d06e2d317b5a59c2c6c5bad808?s=80&d=identicon",
      "web_url": "http://localhost:3000/user1"
    },
    "created_at": "2017-09-05T08:01:32.068Z",
    "updated_at": "2017-09-05T08:01:32.068Z",
    "system": false,
    "noteable_id": 22,
    "noteable_type": "Issue",
    "project_id": 6,
    "noteable_iid": 2
  }
]
```
