---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API GLQL
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduites](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209517) dans GitLab 18.7.

{{< /history >}}

Utilisez cette API pour exécuter des requêtes [GitLab Query Language (GLQL)](../user/glql/_index.md) par programmation. GLQL fournit un langage de requête simplifié pour rechercher et filtrer les [ressources GitLab](../user/glql/_index.md#supported-areas) telles que les tickets, les merge requests et les epics dans les projets et les groupes.

Prérequis :

- Le groupe ou le projet doit autoriser l'accès à ses données.
- Pour les groupes et projets privés, vous devez utiliser [un jeton d'accès personnel](../user/profile/personal_access_tokens.md) avec les permissions appropriées.

## Exécuter une requête GLQL {#execute-a-glql-query}

Exécute une requête GLQL pour rechercher et filtrer les ressources GitLab.

```plaintext
POST /glql
```

> [!note]
> Cet endpoint applique une limite de débit aux requêtes en fonction du SHA de la requête. Les requêtes identiques qui expirent sont suivies et peuvent être temporairement bloquées si elles sont exécutées trop fréquemment.

Attributs pris en charge :

| Attribut   | Type   | Obligatoire | Description                                                                                                                           |
|-------------|--------|----------|---------------------------------------------------------------------------------------------------------------------------------------|
| `glql_yaml` | string | Oui      | La requête GLQL avec une configuration YAML optionnelle. Taille maximale :  10 000 octets (10 Ko). Voir [Formats de requête](#query-formats) pour plus de détails. |
| `after`     | string | Non       | Curseur pour la pagination. Utilisez la valeur `data.pageInfo.endCursor` d'une requête précédente pour récupérer la page suivante des résultats.               |

### Formats de requête {#query-formats}

Le paramètre `glql_yaml` accepte le format YAML avec une clé `query` :

```yaml
fields: id,title,author
group: my-group
limit: 10
sort: created desc
query: state = opened
```

### Options de configuration {#configuration-options}

Les options de configuration suivantes peuvent être incluses dans le YAML :

| Option    | Type    | Obligatoire | Description |
|-----------|---------|----------|-------------|
| `fields`  | string  | Non       | Liste de champs séparés par des virgules à retourner. Par défaut : `title`. Voir les [champs disponibles](#available-fields). |
| `group`   | string  | Non       | Limite la portée de la requête à un groupe spécifique. Ne peut pas être utilisé avec `project`. Si `group` est également spécifié dans la requête, la valeur de la requête prend le dessus. |
| `limit`   | entier | Non       | Nombre maximum de résultats à retourner. Doit être compris entre 1 et 100. Par défaut : `100`. |
| `project` | string  | Non       | Limite la portée de la requête à un projet spécifique. Format : `group/project`. Si `project` est également spécifié dans la requête, la valeur de la requête prend le dessus. |
| `sort`    | string  | Non       | Ordre de tri des résultats. Format : `field direction` (par exemple, `created asc` ou `created desc`). |

### Champs disponibles {#available-fields}

L'option de configuration `fields` est définie par les [champs disponibles de GLQL](../user/glql/fields.md).

### Syntaxe de requête GLQL {#glql-query-syntax}

La syntaxe de requête est définie par [GLQL](../user/glql/_index.md#query-syntax).

### Attributs de réponse {#response-attributes}

En cas de succès, retourne [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                       | Type    | Description |
|---------------------------------|---------|-------------|
| `data`                          | objet  | Contient les résultats de la requête. |
| `data.count`                    | entier | Nombre total de résultats correspondants. |
| `data.nodes`                    | tableau   | Tableau des ressources correspondantes avec les champs demandés. |
| `data.pageInfo`                 | objet  | Informations de pagination. |
| `data.pageInfo.endCursor`       | string  | Curseur pour récupérer la page suivante des résultats. |
| `data.pageInfo.hasNextPage`     | boolean | Indique si d'autres résultats sont disponibles. |
| `data.pageInfo.hasPreviousPage` | boolean | Indique si des résultats précédents sont disponibles. |
| `data.pageInfo.startCursor`     | string  | Curseur pour récupérer la page précédente des résultats. |
| `error`                         | string  | Message d'erreur si la requête a échoué. |
| `fields`                        | tableau   | Tableau des définitions de champs. |
| `fields[].key`                  | string  | L'identifiant unique du champ. |
| `fields[].label`                | string  | Le nom du champ lisible par l'humain. |
| `fields[].name`                 | string  | Le nom de champ commun qui unifie les champs similaires. Par exemple, les clés `created` et `createdAt` ont le nom `createdAt`. |
| `success`                       | boolean | Indique si la requête a réussi. |

### Exemple : Requête basique {#example-basic-query}

Rechercher des tickets ouverts dans un groupe :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "query: group = \"my-group\" AND state = opened"
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

Exemple de réponse :

```json
{
  "data": {
    "count": 1,
    "nodes": [
      {
        "id": "gid://gitlab/Issue/123",
        "iid": "123",
        "reference": "#123",
        "state": "OPEN",
        "title": "Add an example of GoLang HTTP server",
        "webUrl": "https://gitlab.example.com/my-group/my-project/-/issues/123",
        "widgets": null
      }
    ],
    "pageInfo": {
      "endCursor": "eyJpZCI6IjEyMyJ9",
      "hasNextPage": false,
      "hasPreviousPage": false,
      "startCursor": "eyJpZCI6IjEyMyJ9"
    }
  },
  "error": null,
  "fields": [
    {
      "key": "title",
      "label": "Title",
      "name": "title"
    }
  ],
  "success": true
}
```

### Exemple : Requête avec configuration front matter {#example-query-with-front-matter-configuration}

Rechercher avec des champs personnalisés et un tri :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "fields: id,title,author,state\ngroup: my-group\nlimit: 5\nsort: created desc\nquery: state = opened"
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

Exemple de réponse :

```json
{
  "data": {
    "count": 2,
    "nodes": [
      {
        "author": {
          "avatarUrl": "https://www.gravatar.com/avatar/4a17cff4a15e98966063bd203d88aceac682c623e74943a08cdbe0cce87c6d7c?s=80&d=identicon",
          "id": "gid://gitlab/User/123",
          "name": "John Doe",
          "username": "johndoe",
          "webUrl": "https://gitlab.example.com/johndoe"
        },
        "id": "gid://gitlab/Issue/123",
        "iid": "123",
        "reference": "#123",
        "state": "OPEN",
        "title": "Add an example of GoLang HTTP server",
        "webUrl": "https://gitlab.example.com/my-group/my-project/-/issues/123",
        "widgets": null
      },
      {
        "author": {
          "avatarUrl": "https://www.gravatar.com/avatar/4a17cff4a15e98966063bd203d88aceac682c623e74943a08cdbe0cce87c6d7c?s=80&d=identicon",
          "id": "gid://gitlab/User/122",
          "name": "Jane Doe",
          "username": "janedoe",
          "webUrl": "https://gitlab.example.com/janedoe"
        },
        "id": "gid://gitlab/Issue/122",
        "iid": "122",
        "reference": "#122",
        "state": "OPEN",
        "title": "HTTP server examples for all programming languages",
        "webUrl": "https://gitlab.example.com/groups/my-group/-/issues/122",
        "widgets": null
      }
    ],
    "pageInfo": {
      "endCursor": "eyJpZCI6IjEyMyJ9",
      "hasNextPage": false,
      "hasPreviousPage": false,
      "startCursor": "eyJpZCI6IjEyMyJ9"
    }
  },
  "error": null,
  "fields": [
    {
      "key": "id",
      "label": "ID",
      "name": "id"
    },
    {
      "key": "title",
      "label": "Title",
      "name": "title"
    },
    {
      "key": "author",
      "label": "Author",
      "name": "author"
    },
    {
      "key": "state",
      "label": "State",
      "name": "state"
    }
  ],
  "success": true
}
```

### Exemple : Requête avec portée de projet {#example-query-with-project-scope}

Rechercher dans un projet spécifique :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "query: project = \"my-group/my-project\" AND state = opened"
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

### Exemple : Requête avec la fonction `currentUser()` {#example-query-with-currentuser-function}

Rechercher des tickets assignés à l'utilisateur actuel :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "fields: id,title,assignees\nquery: group = \"my-group\" AND assignee = currentUser()"
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

Exemple de réponse :

```json
{
  "data": {
    "count": 1,
    "nodes": [
      {
        "assignees": {
          "nodes": [
            {
              "avatarUrl": "https://www.gravatar.com/avatar/4a17cff4a15e98966063bd203d88aceac682c623e74943a08cdbe0cce87c6d7c?s=80&d=identicon",
              "id": "gid://gitlab/User/123",
              "name": "John Doe",
              "username": "johndoe",
              "webUrl": "https://gitlab.example.com/johndoe"
            }
          ]
        },
        "id": "gid://gitlab/Issue/123",
        "iid": "123",
        "reference": "#123",
        "state": "OPEN",
        "title": "Add an example of GoLang HTTP server",
        "webUrl": "https://gitlab.example.com/my-group/my-project/-/issues/123",
        "widgets": null
      }
    ],
    "pageInfo": {
      "endCursor": "eyJpZCI6IjEyMyJ9",
      "hasNextPage": false,
      "hasPreviousPage": false,
      "startCursor": "eyJpZCI6IjEyMyJ9"
    }
  },
  "error": null,
  "fields": [
    {
      "key": "id",
      "label": "ID",
      "name": "id"
    },
    {
      "key": "title",
      "label": "Title",
      "name": "title"
    },
    {
      "key": "assignees",
      "label": "Assignees",
      "name": "assignees"
    }
  ],
  "success": true
}
```

### Exemple : Requête avec limite et pagination {#example-query-with-limit-and-pagination}

Récupérer un nombre limité de résultats et les parcourir par pagination :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "limit: 2\nquery: group = \"my-group\" AND state = opened"
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

Exemple de réponse :

```json
{
  "data": {
    "count": 68,
    "nodes": [
      {
        "id": "gid://gitlab/Issue/321",
        "iid": "321",
        "reference": "#321",
        "state": "OPEN",
        "title": "Corrupti consectetur impedit non blanditiis hic vitae minus.",
        "webUrl": "https://gitlab.example.com/my-group/my-project/-/issues/321",
        "widgets": null
      },
      {
        "id": "gid://gitlab/WorkItem/322",
        "iid": "322",
        "reference": "#322",
        "state": "OPEN",
        "title": "Ipsa cupiditate corrupti vel maxime quasi at assumenda repellat quod.",
        "webUrl": "https://gitlab.example.com/my-group/my-project/-/issues/322",
        "widgets": null
      }
    ],
    "pageInfo": {
      "endCursor": "eyJpZCI6IjIifQ==",
      "hasNextPage": true,
      "hasPreviousPage": false,
      "startCursor": "eyJpZCI6IjEyMyJ9"
    }
  },
  "error": null,
  "fields": [
    {
      "key": "title",
      "label": "Title",
      "name": "title"
    }
  ],
  "success": true
}
```

Pour récupérer la page suivante, utilisez la valeur `endCursor` de la réponse précédente :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "glql_yaml": "limit: 2\nquery: group = \"my-group\" AND state = opened",
    "after": "eyJpZCI6IjIifQ=="
  }' \
  --url "https://gitlab.example.com/api/v4/glql"
```

## Limitation de débit {#rate-limiting}

L'API GLQL implémente une limite de débit basée sur le hachage SHA-256 de la requête. Les requêtes qui expirent sont suivies. Si une requête particulière qui expire est exécutée trop fréquemment, elle est temporairement bloquée.

En cas de limite de débit atteinte, l'API retourne un code de statut `429 Too Many Requests` avec un message d'erreur :

```json
{
  "error": "Query temporarily blocked due to repeated timeouts. Please try again later or narrow your search scope."
}
```

## Gestion des erreurs {#error-handling}

L'API retourne les codes de statut HTTP suivants :

| Code de statut                 | Description |
|-----------------------------|-------------|
| `200 Success`               | Requête exécutée avec succès. |
| `400 Bad Request`           | Syntaxe de requête invalide, paramètres requis manquants ou taille de l'entrée dépassée. |
| `401 Unauthorized`          | Authentification requise ou identifiants invalides. |
| `403 Forbidden`             | Permissions insuffisantes ou portée OAuth requise manquante. |
| `429 Too Many Requests`     | Limite de débit de requête dépassée. |
| `500 Internal Server Error` | Erreur serveur lors de l'exécution de la requête. |

### Exemples de réponses d'erreur {#error-response-examples}

- Paramètre requis manquant :

  ```json
  {
    "error": "glql_yaml is missing, glql_yaml is empty"
  }
  ```

- Syntaxe GLQL invalide :

  ```json
  {
    "error": "400 Bad request - Error: Unexpected `invalid syntax @@@ ###`, expected operator (one of IN, =, !=, >, or <)"
  }
  ```

- Taille d'entrée dépassée :

  ```json
  {
    "error": "400 Bad request - Input exceeds maximum size"
  }
  ```

- Projet inexistant :

  ```json
  {
    "error": "400 Bad request - Error: Project does not exist or you do not have access to it"
  }
  ```

- Groupe inexistant :

  ```json
  {
    "error": "400 Bad request - Error: Group does not exist or you do not have access to it"
  }
  ```

- Limite de débit dépassée :

  ```json
  {
    "error": "Query temporarily blocked due to repeated timeouts. Please try again later or narrow your search scope."
  }
  ```

- Champ invalide

  ```json
  {
    "error": "Field 'title' doesn't exist on type 'WorkItem' (Did you mean `title`?)"
  }
  ```

> [!note]
> Les erreurs de mauvaise requête GraphQL sont transmises au champ `error` de l'API lorsque cela est applicable avec le code d'erreur `400`.

## Limites et contraintes {#limits-and-constraints}

L'API GLQL a les limites suivantes :

- Taille maximale d'entrée : 10 000 octets (10 Ko) pour le paramètre `glql_yaml`.
- Limite maximale de requête : 100 résultats par requête.
- Limite par défaut : 100 résultats si non spécifié.
- Pagination : Seule la pagination vers l'avant est prise en charge en utilisant l'attribut `after` avec la valeur `endCursor` d'une réponse précédente.
- Limitation de débit : Les requêtes sont soumises à une limite de débit basée sur le hachage SHA-256 de la requête.

## Sujets connexes {#related-topics}

- [Documentation du langage de requête GLQL](../user/glql/_index.md)
- [Authentification de l'API REST](rest/authentication.md)
- [Authentification OAuth 2.0](oauth2.md)
