---
stage: Developer Experience
group: API Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Exécuter des requêtes et des mutations de l'API GraphQL"
description: "Guide d'exécution des requêtes et mutations GraphQL avec des exemples."
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Ce guide présente l'utilisation de base de l'API GraphQL de GitLab.

## Exemples d'exécution {#running-examples}

Les exemples documentés ici peuvent être exécutés à l'aide des éléments suivants :

- [GraphiQL](#graphiql).
- [Ligne de commande](#command-line).
- [Console Rails](#rails-console).

### GraphiQL {#graphiql}

GraphiQL (prononcé « graphical ») vous permet d'exécuter de vraies requêtes GraphQL sur l'API de manière interactive. Il facilite l'exploration du schéma en fournissant une interface utilisateur avec la coloration syntaxique et l'autocomplétion.

Pour la plupart des personnes, l'utilisation de GraphiQL sera le moyen le plus simple d'explorer l'API GraphQL de GitLab.

Vous pouvez utiliser GraphiQL :

- [Sur GitLab.com](https://gitlab.com/-/graphql-explorer).
- Sur GitLab Self-Managed à l'adresse `https://<your-gitlab-site.com>/-/graphql-explorer`.

Connectez-vous d'abord à GitLab pour authentifier les requêtes avec votre compte GitLab.

Pour commencer, consultez les [exemples de requêtes et de mutations](#queries-and-mutations).

### Ligne de commande {#command-line}

Vous pouvez exécuter des requêtes GraphQL dans une requête `curl` sur la ligne de commande de votre ordinateur local. Les requêtes `POST` sont envoyées à `/api/graphql` avec la requête en tant que charge utile. Vous pouvez autoriser votre requête en générant un [jeton d'accès personnel](../../user/profile/personal_access_tokens.md) à utiliser comme jeton bearer. En savoir plus sur l'[authentification GraphQL](_index.md#authentication).

Exemple :

```shell
GRAPHQL_TOKEN=<your-token>
curl --request POST \
  --url "https://gitlab.com/api/graphql" \
  --header "Authorization: Bearer $GRAPHQL_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{\"query\": \"query {currentUser {name}}\"}"
```

Pour imbriquer des chaînes dans la chaîne de requête, encapsulez les données entre guillemets simples ou échappez les chaînes avec ` \\ ` :

```shell
curl --request POST \
  --url "https://gitlab.com/api/graphql" \
  --header "Authorization: Bearer $GRAPHQL_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"query": "query {project(fullPath: \"<group>/<subgroup>/<project>\") {jobs {nodes {id duration}}}}"}'
  # or "{\"query\": \"query {project(fullPath: \\\"<group>/<subgroup>/<project>\\\") {jobs {nodes {id duration}}}}\"}"
```

### Console Rails {#rails-console}

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les requêtes GraphQL peuvent être exécutées dans une [session de console Rails](../../administration/operations/rails_console.md#starting-a-rails-console-session). Par exemple, pour rechercher des projets :

```ruby
current_user = User.find_by_id(1)
query = <<~EOQ
query securityGetProjects($search: String!) {
  projects(search: $search) {
    nodes {
      path
    }
  }
}
EOQ

variables = { "search": "gitlab" }

result = GitlabSchema.execute(query, variables: variables, context: { current_user: current_user })
result.to_h
```

## Requêtes et mutations {#queries-and-mutations}

L'API GraphQL de GitLab peut être utilisée pour effectuer :

- Des requêtes pour la récupération de données.
- Des [mutations](#mutations) pour créer, mettre à jour et supprimer des données.

> [!note]
> Dans l'API GraphQL de GitLab, `id` fait référence à un [ID global](https://graphql.org/learn/global-object-identification/), qui est un identifiant d'objet au format `"gid://gitlab/Issue/123"`. Pour plus d'informations, consultez [les ID globaux](_index.md#global-ids).

Le [schéma GraphQL de GitLab](reference/_index.md) décrit les objets et les champs disponibles pour les clients afin d'effectuer des requêtes, ainsi que leurs types de données correspondants.

Exemple : Obtenez uniquement les noms de tous les projets auxquels l'utilisateur actuellement authentifié peut accéder (jusqu'à une limite) dans le groupe `gitlab-org`.

```graphql
query {
  group(fullPath: "gitlab-org") {
    id
    name
    projects {
      nodes {
        name
      }
    }
  }
}
```

Exemple : Obtenez un projet spécifique et le titre du ticket n° 2.

```graphql
query {
  project(fullPath: "gitlab-org/graphql-sandbox") {
    name
    issue(iid: "2") {
      title
    }
  }
}
```

### Traversée de graphe {#graph-traversal}

Lors de la récupération des nœuds enfants, utilisez :

- La syntaxe `edges { node { } }`.
- La syntaxe abrégée `nodes { }`.

Sous-jacent à tout cela se trouve un graphe que vous traversez, d'où le nom GraphQL.

Exemple : Obtenez le nom d'un projet et les titres de tous ses tickets.

```graphql
query {
  project(fullPath: "gitlab-org/graphql-sandbox") {
    name
    issues {
      nodes {
        title
        description
      }
    }
  }
}
```

En savoir plus sur les requêtes :  [Documentation GraphQL](https://graphql.org/learn/queries/)

### Autorisation {#authorization}

Si vous êtes connecté à GitLab et que vous utilisez [GraphiQL](#graphiql), toutes les requêtes sont effectuées en votre nom, en tant qu'utilisateur authentifié. Pour plus d'informations, consultez [l'authentification GraphQL](_index.md#authentication).

### Mutations {#mutations}

Les mutations apportent des modifications aux données. Nous pouvons mettre à jour, supprimer ou créer de nouveaux enregistrements. Les mutations utilisent généralement des InputTypes et des variables, qui n'apparaissent pas ici.

Les mutations comprennent :

- Des entrées. Par exemple, des arguments, tels que la réaction emoji que vous souhaitez ajouter et à quel objet.
- Des instructions de retour. C'est-à-dire ce que vous souhaitez récupérer en cas de succès.
- Des erreurs. Demandez toujours ce qui s'est mal passé, au cas où.

#### Mutations de création {#creation-mutations}

Exemple : Prenons un peu de thé - ajoutez une réaction emoji `:tea:` à un ticket.

```graphql
mutation {
  awardEmojiAdd(input: { awardableId: "gid://gitlab/Issue/27039960",
      name: "tea"
    }) {
    awardEmoji {
      name
      description
      unicode
      emoji
      unicodeVersion
      user {
        name
      }
    }
    errors
  }
}
```

Exemple : Ajoutez un commentaire au ticket. Cet exemple utilise l'ID du ticket `GitLab.com`. Si vous utilisez une instance locale, vous devez obtenir l'ID d'un ticket sur lequel vous pouvez écrire.

```graphql
mutation {
  createNote(input: { noteableId: "gid://gitlab/Issue/27039960",
      body: "*sips tea*"
    }) {
    note {
      id
      body
      discussion {
        id
      }
    }
    errors
  }
}
```

#### Mutations de mise à jour {#update-mutations}

Lorsque vous voyez le résultat `id` de la note que vous avez créée, prenez-en note. Modifions-la pour siroter plus vite.

```graphql
mutation {
  updateNote(input: { id: "gid://gitlab/Note/<note ID>",
      body: "*SIPS TEA*"
    }) {
    note {
      id
      body
    }
    errors
  }
}
```

#### Mutations de suppression {#deletion-mutations}

Supprimons le commentaire, car notre thé est terminé.

```graphql
mutation {
  destroyNote(input: { id: "gid://gitlab/Note/<note ID>" }) {
    note {
      id
      body
    }
    errors
  }
}
```

Vous devriez obtenir quelque chose comme le résultat suivant :

```json
{
  "data": {
    "destroyNote": {
      "errors": [],
      "note": null
    }
  }
}
```

La note demandée n'existe plus, donc la valeur renvoyée pour ce champ est `null`.

En savoir plus sur les mutations :  [Documentation GraphQL](https://graphql.org/learn/queries/#mutations).

### Mettre à jour les paramètres du projet {#update-project-settings}

Vous pouvez mettre à jour plusieurs paramètres de projet dans une seule mutation GraphQL. Cet exemple est une solution de contournement pour [le changement majeur](../../update/deprecations.md#cicd-job-token---authorized-groups-and-projects-allowlist-enforcement) dans le comportement de portée de `CI_JOB_TOKEN`.

```graphql
mutation DisableCI_JOB_TOKENscope {
  projectCiCdSettingsUpdate(input:{fullPath: "<namespace>/<project-name>", inboundJobTokenScopeEnabled: false}) {
    ciCdSettings {
      inboundJobTokenScopeEnabled
    }
    errors
  }
}
```

### Requêtes d'introspection {#introspection-queries}

Les clients peuvent interroger le point de terminaison GraphQL pour obtenir des informations sur son schéma en effectuant une [requête d'introspection](https://graphql.org/learn/introspection/). Ces requêtes sont destinées à être utilisées comme outil de découverte et de diagnostic.

- Dans les environnements de développement et de test, les requêtes d'introspection s'exécutent sur le schéma en direct.
- Dans les environnements de production, les requêtes d'introspection renvoient un schéma statique.
  - Les requêtes d'introspection ne doivent pas être utilisées pour récupérer des données dans les environnements de production. Pour plus d'informations, voir :
    - [GraphQL Introspection in Production](https://graphql.org/learn/introspection/#introspection-in-production)
    - [Apollo Introspection in Production](https://www.apollographql.com/blog/why-you-should-disable-graphql-introspection-in-production#what-do-we-need-introspection-for)
  - Toutes les requêtes d'introspection renvoient la même réponse statique, quelle que soit la méthode de requête ou les paramètres.
  - Le schéma statique est mis à jour automatiquement pour correspondre au schéma actuel.
  - Les requêtes d'introspection renvoient l'un des deux fichiers de schéma statique :
    - `public/-/graphql/introspection_result.json` :  Schéma complet, incluant les champs obsolètes.
    - `public/-/graphql/introspection_result_no_deprecated.json` :  Schéma sans champs obsolètes.

Pour demander le schéma, envoyez ce qui suit dans le corps de la requête :

```json
{
  "query": "{ __schema { types { name } } }"
}
```

Pour demander le schéma sans les champs obsolètes, incluez `remove_deprecated: true` dans le corps de la requête :

```json
{
  "query": "{ __schema { types { name } } }",
  "remove_deprecated": true
}
```

#### Requêtes d'introspection GraphiQL {#graphiql-introspection-queries}

Le [GraphiQL Query Explorer](#graphiql) utilise une requête d'introspection pour :

- Acquérir des connaissances sur le schéma GraphQL de GitLab.
- Effectuer l'autocomplétion.
- Fournir son onglet interactif `Docs`.

En savoir plus sur l'introspection :  [Documentation GraphQL](https://graphql.org/learn/introspection/)

### Complexité des requêtes {#query-complexity}

Le [score et la limite de complexité](_index.md#maximum-query-complexity) calculés pour une requête peuvent être révélés aux clients en interrogeant `queryComplexity`.

```graphql
query {
  queryComplexity {
    score
    limit
  }

  project(fullPath: "gitlab-org/graphql-sandbox") {
    name
  }
}
```

## Tri {#sorting}

Certains points de terminaison GraphQL de GitLab vous permettent de spécifier comment trier une collection d'objets. Vous ne pouvez trier que selon ce que le schéma vous autorise.

Exemple : Les tickets peuvent être triés par date de création :

```graphql
query {
  project(fullPath: "gitlab-org/graphql-sandbox") {
   name
    issues(sort: created_asc) {
      nodes {
        title
        createdAt
      }
    }
  }
}
```

## Pagination {#pagination}

La pagination est un moyen de ne demander qu'un sous-ensemble d'enregistrements, comme les dix premiers. Si vous en voulez davantage, vous pouvez effectuer une autre requête au serveur pour les dix suivants sous la forme de quelque chose comme `give me the next ten records`.

Par défaut, l'API GraphQL de GitLab renvoie 100 enregistrements par page. Pour modifier ce comportement, utilisez les arguments `first` ou `last`. Les deux arguments prennent une valeur, donc `first: 10` renvoie les dix premiers enregistrements, et `last: 10` les dix derniers. Il y a une limite au nombre d'enregistrements renvoyés par page, qui est généralement de `100`.

Exemple : Récupérez uniquement les deux premiers tickets (découpage). Le champ `cursor` vous donne une position à partir de laquelle vous pouvez récupérer des enregistrements supplémentaires par rapport à celui-ci.

```graphql
query {
  project(fullPath: "gitlab-org/graphql-sandbox") {
    name
    issues(first: 2) {
      edges {
        node {
          title
        }
      }
      pageInfo {
        endCursor
        hasNextPage
      }
    }
  }
}
```

Exemple : Récupérez les trois suivants. (La valeur du curseur `eyJpZCI6IjI3MDM4OTMzIiwiY3JlYXRlZF9hdCI6IjIwMTktMTEtMTQgMDU6NTY6NDQgVVRDIn0` peut être différente, mais c'est la valeur `cursor` renvoyée pour le deuxième ticket retourné ci-dessus.)

```graphql
query {
  project(fullPath: "gitlab-org/graphql-sandbox") {
    name
    issues(first: 3, after: "eyJpZCI6IjI3MDM4OTMzIiwiY3JlYXRlZF9hdCI6IjIwMTktMTEtMTQgMDU6NTY6NDQgVVRDIn0") {
      edges {
        node {
          title
        }
        cursor
      }
      pageInfo {
        endCursor
        hasNextPage
      }
    }
  }
}
```

En savoir plus sur la pagination et les curseurs :  [Documentation GraphQL](https://graphql.org/learn/pagination/)

## Chargements de fichiers {#file-uploads}

Certaines mutations acceptent des chargements de fichiers comme arguments. Ces mutations utilisent la [spécification de requête multipart GraphQL](https://github.com/jaydenseric/graphql-multipart-request-spec), qui vous permet d'envoyer des fichiers avec vos opérations GraphQL à l'aide de requêtes `multipart/form-data`.

Les mutations qui prennent en charge les chargements de fichiers ont des arguments de type `Upload`. Vous pouvez identifier ces mutations dans la [référence de l'API GraphQL](reference/_index.md) en recherchant des arguments avec le type scalaire `Upload`.

Les mutations de chargement de fichiers ne peuvent pas être exécutées via [GraphiQL](#graphiql). Vous devez utiliser un outil [en ligne de commande](#command-line) comme `curl` ou une bibliothèque cliente GraphQL compatible.

Une requête de chargement multipart comporte trois parties clés :

- `operations` :  Une chaîne JSON contenant la requête GraphQL et les variables, avec les valeurs de fichier définies sur `null`.
- `map` :  Un objet JSON qui mappe les clés de fichier aux chemins de variables dans les opérations.
- Les champs de fichier eux-mêmes, référencés par les clés utilisées dans `map`.

Pour charger un design sur un ticket à l'aide de la mutation `designManagementUpload` :

```shell
GRAPHQL_TOKEN=<your-token>
curl --request POST \
  --url "https://gitlab.com/api/graphql" \
  --header "Authorization: Bearer $GRAPHQL_TOKEN" \
  --form 'operations={"query": "mutation ($files: [Upload!]!, $projectPath: ID!, $iid: ID!) { designManagementUpload(input: { projectPath: $projectPath, iid: $iid, files: $files }) { designs { filename } errors } }", "variables": {"files": [null], "projectPath": "<group>/<project>", "iid": "<issue-iid>"}}' \
  --form 'map={"0": ["variables.files.0"]}' \
  --form '0=@/path/to/your/design.png'
```

Pour importer des éléments de travail à partir d'un fichier CSV à l'aide de la mutation `workItemsCsvImport` :

```shell
GRAPHQL_TOKEN=<your-token>
curl --request POST \
  --url "https://gitlab.com/api/graphql" \
  --header "Authorization: Bearer $GRAPHQL_TOKEN" \
  --form 'operations={"query": "mutation ($projectPath: ID!, $file: Upload!) { workItemsCsvImport(input: { projectPath: $projectPath, file: $file }) { message errors } }", "variables": {"projectPath": "<group>/<project>", "file": null}}' \
  --form 'map={"0": ["variables.file"]}' \
  --form '0=@/path/to/your/work-items.csv'
```

Pour charger plusieurs fichiers dans une seule requête, ajoutez des entrées supplémentaires à la fois à `map` et aux champs du formulaire :

```shell
GRAPHQL_TOKEN=<your-token>
curl --request POST \
  --url "https://gitlab.com/api/graphql" \
  --header "Authorization: Bearer $GRAPHQL_TOKEN" \
  --form 'operations={"query": "mutation ($files: [Upload!]!, $projectPath: ID!, $iid: ID!) { designManagementUpload(input: { projectPath: $projectPath, iid: $iid, files: $files }) { designs { filename } errors } }", "variables": {"files": [null, null], "projectPath": "<group>/<project>", "iid": "<issue-iid>"}}' \
  --form 'map={"0": ["variables.files.0"], "1": ["variables.files.1"]}' \
  --form '0=@/path/to/first-design.png' \
  --form '1=@/path/to/second-design.png'
```

## Modifier l'URL de requête {#changing-the-query-url}

Il est parfois nécessaire d'envoyer des requêtes GraphQL à une URL différente. Par exemple, les requêtes `GeoNode`, qui ne fonctionnent que sur une URL de site Geo secondaire.

Pour modifier l'URL d'une requête GraphQL dans l'explorateur GraphiQL, définissez un en-tête personnalisé dans la zone d'en-tête de GraphiQL (zone en bas à gauche, juste à l'endroit où se trouvent les variables) :

```json
{
  "REQUEST_PATH": "<the URL to make the graphQL request against>"
}
```
