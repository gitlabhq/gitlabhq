---
stage: Developer Experience
group: API Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Interaction programmatique avec GitLab.
title: API GraphQL
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[GraphQL](https://graphql.org/) est un langage de requête pour les API. Vous pouvez l'utiliser pour demander exactement les données dont vous avez besoin, et ainsi limiter le nombre de requêtes nécessaires.

Les données GraphQL sont organisées en types, de sorte que votre client peut utiliser des [bibliothèques GraphQL côté client](https://graphql.org/community/tools-and-libraries/) pour consommer l'API et éviter l'analyse manuelle.

L'API GraphQL est [sans version](https://graphql.org/learn/schema-design/#versioning).

## Premiers pas {#getting-started}

Si vous débutez avec l'API GraphQL de GitLab, consultez [Prise en main de l'API GraphQL de GitLab](getting_started.md).

Vous pouvez consulter les ressources disponibles dans la [référence de l'API GraphQL](reference/_index.md).

Le point de terminaison de l'API GraphQL de GitLab est situé à `/api/graphql`.

### Explorateur GraphQL interactif {#interactive-graphql-explorer}

Explorez l'API GraphQL à l'aide de l'explorateur GraphQL interactif, soit :

- [Sur GitLab.com](https://gitlab.com/-/graphql-explorer).
- Sur GitLab Self-Managed à l'adresse `https://<your-gitlab-site.com>/-/graphql-explorer`.

Pour plus d'informations, consultez [GraphiQL](getting_started.md#graphiql).

### Afficher des exemples GraphQL {#view-graphql-examples}

Vous pouvez utiliser des exemples de requêtes qui extraient des données de projets publics sur GitLab.com :

- [Créer un rapport d'audit](audit_report.md)
- [Identifier les tableaux des tickets](sample_issue_boards.md)
- [Interroger les utilisateurs](users_example.md)
- [Utiliser des emoji personnalisés](custom_emoji.md)

La page [de prise en main](getting_started.md) présente différentes méthodes pour personnaliser les requêtes GraphQL.

### Authentification {#authentication}

Vous pouvez accéder à certaines requêtes sans authentification, mais d'autres nécessitent une authentification. Les mutations nécessitent toujours une authentification.

Vous pouvez vous authentifier à l'aide de l'un des éléments suivants :

- [Jeton](#token-authentication)
- [Cookie de session](#session-cookie-authentication)

Si les informations d'authentification ne sont pas valides, GitLab renvoie un message d'erreur avec un code de statut `401` :

```json
{"errors":[{"message":"Invalid token"}]}
```

#### Authentification par jeton {#token-authentication}

Utilisez l'un des jetons suivants pour vous authentifier auprès de l'API GraphQL :

- [Jetons OAuth 2.0](../oauth2.md)
- [Jetons d'accès personnels](../../user/profile/personal_access_tokens.md)
- [Jetons d'accès au projet](../../user/project/settings/project_access_tokens.md)
- [Jetons d'accès de groupe](../../user/group/settings/group_access_tokens.md)

Authentifiez-vous avec un jeton en le transmettant dans un [en-tête de requête](#header-authentication) ou en tant que [paramètre](#parameter-authentication).

Les jetons nécessitent la bonne [portée](#token-scopes).

##### Authentification par en-tête {#header-authentication}

Exemple d'authentification par jeton utilisant un en-tête de requête `Authorization: Bearer <token>` :

```shell
curl --request POST \
  --url "https://gitlab.com/api/graphql" \
  --header "Authorization: Bearer <token>" \
  --header "Content-Type: application/json" \
  --data "{\"query\": \"query {currentUser {name}}\"}"
```

##### Authentification par paramètre {#parameter-authentication}

Exemple d'utilisation d'un jeton OAuth 2.0 dans le paramètre `access_token` :

```shell
curl --request POST \
  --url "https://gitlab.com/api/graphql?access_token=<oauth_token>" \
  --header "Content-Type: application/json" \
  --data "{\"query\": \"query {currentUser {name}}\"}"
```

Vous pouvez transmettre des jetons d'accès personnels, de projet ou de groupe en utilisant le paramètre `private_token` :

```shell
curl --request POST \
  --url "https://gitlab.com/api/graphql?private_token=<access_token>" \
  --header "Content-Type: application/json" \
  --data "{\"query\": \"query {currentUser {name}}\"}"
```

##### Portées des jetons {#token-scopes}

Les jetons doivent avoir la bonne portée pour accéder à l'API GraphQL, soit :

| Portée      | Accès |
|------------|--------|
| `read_api` | Accorde un accès en lecture à l'API. Suffisant pour les requêtes. |
| `api`      | Accorde un accès en lecture et en écriture à l'API. Requis par les mutations. |

#### Authentification par cookie de session {#session-cookie-authentication}

La connexion à l'application principale GitLab définit un cookie de session `_gitlab_session`.

L'[explorateur GraphQL interactif](#interactive-graphql-explorer) et le frontend web de GitLab utilisent cette méthode d'authentification.

### Autorisation {#authorization}

Une fois authentifié, l'API GraphQL vérifie vos permissions pour chaque ressource demandée. La façon dont l'API signale les échecs d'autorisation dépend du type d'opération.

#### Champs de requête {#query-fields}

Les champs de requête renvoient `null` lorsque vous n'avez pas la permission d'accéder à une ressource. La réponse n'inclut pas de message d'erreur.

Ce comportement est intentionnel. L'API renvoie la même réponse `null` pour les ressources non autorisées et inexistantes, afin que les clients ne puissent pas énumérer les ressources existant sur le serveur.

Par exemple, si vous interrogez un champ qui nécessite un rôle ou un module complémentaire que vous ne possédez pas, aucune entrée n'est affichée dans le tableau `errors` :

```json
{
  "data": {
    "group": {
      "fieldRequiringPermission": null
    }
  }
}
```

Pour les [champs de connexion](getting_started.md#pagination) qui utilisent le modèle de pagination Relay, vous pouvez distinguer un échec d'autorisation d'un résultat vide :

- `"field": null` signifie que vous n'avez pas la permission d'accéder à cette ressource.
- `"field": { "nodes": [] }` signifie que vous avez la permission, mais qu'aucune donnée ne correspond à votre requête.

Si vous recevez un `null` inattendu, vérifiez que :

- Votre jeton dispose des [portées](#token-scopes) requises.
- Votre rôle atteint le niveau d'accès minimum documenté dans la [référence de l'API GraphQL](reference/_index.md).
- Votre instance dispose du niveau d'abonnement, des fonctionnalités ou des modules complémentaires requis et activés.

#### Mutations {#mutations}

Les mutations renvoient un message d'erreur en cas d'échec d'autorisation. L'erreur apparaît dans le tableau `errors` de niveau supérieur avec un champ de données `null` :

```json
{
  "data": {
    "mutationName": null
  },
  "errors": [
    {
      "message": "The resource that you are attempting to access does not exist or you don't have permission to perform this action",
      "locations": [{ "line": 2, "column": 3 }],
      "path": ["mutationName"]
    }
  ]
}
```

Le message d'erreur peut varier selon le type de ressource.

## Identifiants d'objets {#object-identifiers}

L'API GraphQL de GitLab utilise un mélange d'identifiants.

Les [ID globaux](#global-ids), les chemins complets et les ID internes (IID) sont tous utilisés comme arguments dans l'API GraphQL de GitLab, mais souvent une partie particulière du schéma n'accepte pas tous ces éléments en même temps.

Bien que l'API GraphQL de GitLab n'ait pas toujours été cohérente sur ce point, en général vous pouvez vous attendre à :

- Si l'objet est un projet, un groupe ou un espace de nommage, vous utilisez le chemin complet de l'objet.
- Si un objet possède un IID, vous utilisez une combinaison du chemin complet et de l'IID.
- Pour les autres objets, vous utilisez un [ID global](#global-ids).

Par exemple, rechercher un projet par son chemin complet `"gitlab-org/gitlab"` :

```graphql
{
  project(fullPath: "gitlab-org/gitlab") {
    id
    fullPath
  }
}
```

Autre exemple, verrouiller un ticket par le chemin complet de son projet `"gitlab-org/gitlab"` et l'IID du ticket `"1"` :

```graphql
mutation {
  issueSetLocked(input: { projectPath: "gitlab-org/gitlab", iid: "1", locked: true }) {
    issue {
      id
      iid
    }
  }
}
```

Exemple de recherche d'un runner CI par son ID global :

```graphql
{
  runner(id: "gid://gitlab/Ci::Runner/1") {
    id
  }
}
```

Historiquement, l'API GraphQL de GitLab a été incohérente dans la typisation des champs et arguments de chemin complet et d'IID, mais en général :

- Les champs et arguments de chemin complet sont de type GraphQL `ID`.
- Les champs et arguments IID sont de type GraphQL `String`.

### ID globaux {#global-ids}

Dans l'API GraphQL de GitLab, un champ ou argument nommé `id` est presque toujours un [ID global](https://graphql.org/learn/global-object-identification/) et jamais un ID de clé primaire de base de données. Un ID global dans l'API GraphQL de GitLab commence par `"gid://gitlab/"`. Par exemple, `"gid://gitlab/Issue/123"`.

Les ID globaux sont une convention utilisée pour la mise en cache et la récupération dans certaines bibliothèques côté client.

Les ID globaux GitLab sont susceptibles de changer. En cas de modification, l'utilisation de l'ancien ID global comme argument est dépréciée et prise en charge conformément au processus de [dépréciation et changement majeur](#breaking-changes). Vous ne devez pas supposer qu'un ID global mis en cache sera valide au-delà de la durée d'un cycle de dépréciation de l'API GraphQL de GitLab.

## Requêtes de niveau supérieur disponibles {#available-top-level-queries}

Les points d'entrée de niveau supérieur pour toutes les requêtes sont définis dans le [type `Query`](reference/_index.md#query-type) dans la référence GraphQL.

### Requêtes multiplex {#multiplex-queries}

GitLab prend en charge le regroupement de requêtes en une seule demande. Pour plus d'informations, consultez [Multiplex](https://graphql-ruby.org/queries/multiplex.html).

## Changements majeurs {#breaking-changes}

L'API GraphQL de GitLab est [sans version](https://graphql.org/learn/best-practices/#versioning) et les modifications apportées à l'API sont principalement rétrocompatibles.

Cependant, GitLab modifie parfois l'API GraphQL d'une manière qui n'est pas rétrocompatible. Ces modifications sont considérées comme des changements majeurs, et peuvent inclure la suppression ou le renommage de champs, d'arguments ou d'autres parties du schéma. Lors de la création d'un changement majeur, GitLab suit un [processus de dépréciation et de suppression](#deprecation-and-removal-process).

Pour éviter qu'un changement majeur n'affecte vos intégrations, vous devez :

- Vous familiariser avec le [processus de dépréciation et de suppression](#deprecation-and-removal-process).
- Vérifier régulièrement [vos appels API par rapport au futur schéma avec changements majeurs](#verify-against-the-future-breaking-change-schema).

Pour GitLab Self-Managed, le [retour](../../update/convert_to_ee/revert.md) d'une instance EE vers CE entraîne des changements majeurs.

### Exemptions aux changements majeurs {#breaking-change-exemptions}

Les éléments du schéma étiquetés comme expérimentaux dans la [référence de l'API GraphQL](reference/_index.md) sont exempts du processus de dépréciation. Ces éléments peuvent être supprimés ou modifiés à tout moment sans préavis.

Les champs masqués par un feature flag et désactivés par défaut ne suivent pas le processus de dépréciation et de suppression. Ces champs peuvent être supprimés à tout moment sans préavis.

> [!warning]
> GitLab s'efforce de suivre le [processus de dépréciation et de suppression](#deprecation-and-removal-process). GitLab peut apporter des changements majeurs immédiats à l'API GraphQL pour corriger des problèmes critiques de sécurité ou de performance si le processus de dépréciation présentait un risque significatif.

### Vérifier par rapport au futur schéma avec changements majeurs {#verify-against-the-future-breaking-change-schema}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/353642) dans GitLab 15.6.

{{< /history >}}

Vous pouvez effectuer des appels vers l'API GraphQL comme si tous les éléments dépréciés avaient déjà été supprimés. Ainsi, vous pouvez vérifier les appels API avant une [release avec changements majeurs](#deprecation-and-removal-process), avant que les éléments soient réellement supprimés du schéma.

Pour effectuer ces appels, ajoutez un paramètre de requête `remove_deprecated=true` au point de terminaison de l'API GraphQL. Par exemple, `https://gitlab.com/api/graphql?remove_deprecated=true` pour GraphQL sur GitLab.com.

### Processus de dépréciation et de suppression {#deprecation-and-removal-process}

Les parties du schéma marquées pour suppression de l'API GraphQL de GitLab sont d'abord dépréciées mais restent disponibles pendant au moins six releases. Elles sont ensuite entièrement supprimées lors de la prochaine version majeure `XX.0`.

Les éléments sont marqués comme dépréciés dans :

- Le [schéma](https://spec.graphql.org/October2021/#sec--deprecated).
- La [référence de l'API GraphQL](reference/_index.md).
- Le [calendrier de suppression des fonctionnalités dépréciées](../../update/deprecations.md), qui est lié depuis les notes de release.
- Les requêtes d'introspection de l'API GraphQL.

Le message de dépréciation fournit une alternative à l'élément de schéma déprécié, le cas échéant.

Pour éviter de subir des changements majeurs, vous devez supprimer le schéma déprécié de vos appels à l'API GraphQL dès que possible. Vous devez [vérifier vos appels API par rapport au schéma sans les éléments de schéma dépréciés](#verify-against-the-future-breaking-change-schema).

#### Exemple de dépréciation {#deprecation-example}

Les champs suivants sont dépréciés dans différentes versions mineures, mais tous deux supprimés dans GitLab 17.0 :

| Champ déprécié dans | Raison |
|:--------------------|:-------|
| 15.7                | GitLab dispose traditionnellement de 12 versions mineures par version majeure. Pour s'assurer que le champ est disponible pendant 6 releases supplémentaires, il est supprimé dans la version majeure 17.0 (et non 16.0). |
| 16.6                | La suppression dans la version 17.0 permet une disponibilité de 6 mois. |

### Liste des éléments supprimés {#list-of-removed-items}

Consultez la [liste des éléments supprimés](removed_items.md) dans les releases précédentes.

## Limites {#limits}

Les limites suivantes s'appliquent à l'API GraphQL de GitLab.

| Limite                                                 | Valeur par défaut |
|:------------------------------------------------------|:--------|
| Taille de page maximale                                     | 100 enregistrements (nœuds) par page. S'applique à la plupart des connexions dans l'API. Certaines connexions peuvent avoir des limites de taille de page maximale différentes, supérieures ou inférieures. |
| [Complexité maximale des requêtes](#maximum-query-complexity) | 200 pour les requêtes non authentifiées et 250 pour les requêtes authentifiées. |
| Taille maximale des requêtes                                    | 10 000 caractères par requête ou mutation. Si cette limite est atteinte, utilisez des [variables](https://graphql.org/learn/queries/#variables) et des [fragments](https://graphql.org/learn/queries/#fragments) pour réduire la taille de la requête ou de la mutation. Supprimez les espaces blancs en dernier recours. |
| Limites de débit                                           | Pour GitLab.com, consultez les [limites de débit spécifiques à GitLab.com](../../user/gitlab_com/_index.md#rate-limits-on-gitlabcom). |
| [Limites de données](#data-limits)                           | Les requêtes de blob sont limitées à 20 Mo lorsque plusieurs chemins de blob sont spécifiés. |
| Délai d'expiration des requêtes                                       | 30 secondes. |

### Complexité maximale des requêtes {#maximum-query-complexity}

L'API GraphQL de GitLab évalue la complexité d'une requête. En général, les requêtes plus volumineuses ont un score de complexité plus élevé. Cette limite est conçue pour protéger l'API contre l'exécution de requêtes susceptibles d'avoir un impact négatif sur ses performances globales.

Vous pouvez [interroger](getting_started.md#query-complexity) le score de complexité d'une requête et la limite pour la demande.

Si une requête dépasse la limite de complexité, une réponse avec un message d'erreur est renvoyée.

En général, chaque champ dans une requête ajoute `1` au score de complexité, bien que cela puisse être supérieur ou inférieur pour des champs particuliers. Parfois, l'ajout de certains arguments peut également augmenter la complexité d'une requête.

### Limites de données {#data-limits}

Les requêtes de blob sont limitées à :

- Un seul blob de n'importe quelle taille.
- Plusieurs blobs avec une taille totale de 20 Mo ou moins.

Les blobs de plus de 20 Mo doivent être demandés individuellement. Cette limite s'applique uniquement lorsque vous demandez des champs contenant des données blob.

Vous devrez peut-être limiter le nombre de chemins dans vos requêtes pour rester dans la limite de données. Effectuez une requête pour le champ `size` en excluant les champs de données :

```gql
{
  project(fullPath: "gitlab-org/gitlab") {
    repository {
      blobs(paths: ["big_file.rb", "small_file.rb", "huge_file.rb", ..., etc.], ref: "master") {
        nodes {
          path
          size
        }
      }
    }
  }
}
```

Utilisez la réponse pour calculer la taille totale et vous assurer que les requêtes suivantes ne dépassent pas la limite de données de 20 Mo.

## Résoudre les mutations détectées comme spam {#resolve-mutations-detected-as-spam}

Les mutations GraphQL peuvent être détectées comme spam. Si une mutation est détectée comme spam et que :

- Un service CAPTCHA n'est pas configuré, une [erreur de niveau supérieur GraphQL](https://spec.graphql.org/June2018/#sec-Errors) est déclenchée. Par exemple :

  ```json
  {
    "errors": [
      {
        "message": "Request denied. Spam detected",
        "locations": [ { "line": 6, "column": 7 } ],
        "path": [ "updateSnippet" ],
        "extensions": {
          "spam": true
        }
      }
    ],
    "data": {
      "updateSnippet": {
        "snippet": null
      }
    }
  }
  ```

- Un service CAPTCHA est configuré, vous recevez une réponse avec :
  - `needsCaptchaResponse` défini sur `true`.
  - Les champs `spamLogId` et `captchaSiteKey` définis.

  Par exemple :

  ```json
  {
    "errors": [
      {
        "message": "Request denied. Solve CAPTCHA challenge and retry",
        "locations": [ { "line": 6, "column": 7 } ],
        "path": [ "updateSnippet" ],
        "extensions": {
          "needsCaptchaResponse": true,
          "captchaSiteKey": "6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI",
          "spamLogId": 67
        }
      }
    ],
    "data": {
      "updateSnippet": {
        "snippet": null,
      }
    }
  }
  ```

- Utilisez le `captchaSiteKey` pour obtenir une valeur de réponse CAPTCHA à l'aide de l'API CAPTCHA appropriée. Seul [Google reCAPTCHA v2](https://developers.google.com/recaptcha/docs/display) est pris en charge.
- Soumettez à nouveau la requête avec les en-têtes `X-GitLab-Captcha-Response` et `X-GitLab-Spam-Log-Id` définis.

> [!note]
> L'implémentation GitLab GraphiQL ne permet pas de transmettre des en-têtes, la requête doit donc être une requête cURL. `--data-binary` est utilisé pour gérer correctement les guillemets doubles échappés dans la requête intégrée au JSON.

```shell
export CAPTCHA_RESPONSE="<CAPTCHA response obtained from CAPTCHA service>"
export SPAM_LOG_ID="<spam_log_id obtained from initial REST response>"
curl --request POST \
  --header "Authorization: Bearer $PRIVATE_TOKEN" \
  --header "Content-Type: application/json" \
  --header "X-GitLab-Captcha-Response: $CAPTCHA_RESPONSE" \
  --header "X-GitLab-Spam-Log-Id: $SPAM_LOG_ID" \
  --data-binary '{"query": "mutation {createSnippet(input: {title: \"Title\" visibilityLevel: public blobActions: [ { action: create filePath: \"BlobPath\" content: \"BlobContent\" } ] }) { snippet { id title } errors }}"}' "https://gitlab.example.com/api/graphql"
```
