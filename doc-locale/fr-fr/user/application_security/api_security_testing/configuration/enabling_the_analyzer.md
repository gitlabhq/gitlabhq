---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Activer l'analyseur"
---

Vous pouvez spécifier l'API que vous souhaitez analyser en utilisant :

- [Spécification OpenAPI v2 ou v3](#openapi-specification)
- [Schéma GraphQL](#graphql-schema)
- [HTTP Archive (HAR)](#http-archive-har)
- [Collection Postman v2.0 ou v2.1](#postman-collection)

## Spécification OpenAPI {#openapi-specification}

La [spécification OpenAPI](https://www.openapis.org/) (anciennement la spécification Swagger) est un format de description d'API pour les API REST. Cette section vous explique comment configurer l'analyse de test de sécurité des API à l'aide d'une spécification OpenAPI pour fournir des informations sur l'API cible à tester. Les spécifications OpenAPI sont fournies en tant que ressource du système de fichiers ou URL. Les formats OpenAPI JSON et YAML sont tous deux pris en charge.

Le test de sécurité des API utilise un document OpenAPI pour générer le corps de la requête. Lorsqu'un corps de requête est requis, la génération du corps est limitée aux types de corps suivants :

- `application/x-www-form-urlencoded`
- `multipart/form-data`
- `application/json`
- `application/xml`

## OpenAPI et les types de médias {#openapi-and-media-types}

Un type de média (anciennement connu sous le nom de type MIME) est un identifiant pour les formats de fichiers et le contenu de format transmis. Un document OpenAPI vous permet de spécifier qu'une opération donnée peut accepter différents types de médias, donc une requête donnée peut envoyer des données en utilisant différents contenus de fichiers. Par exemple, une opération `PUT /user` pour mettre à jour les données utilisateur pourrait accepter des données au format XML (type de média `application/xml`) ou JSON (type de média `application/json`). OpenAPI 2.x vous permet de spécifier les types de médias acceptés globalement ou par opération, et OpenAPI 3.x vous permet de spécifier les types de médias acceptés par opération. Le test de sécurité des API vérifie les types de médias répertoriés et tente de produire des exemples de données pour chaque type de média pris en charge.

- Le comportement par défaut consiste à sélectionner l'un des types de médias pris en charge à utiliser. Le premier type de média pris en charge est choisi dans la liste. Ce comportement est configurable.

Il n'est pas toujours souhaitable de tester la même opération (par exemple, `POST /user`) en utilisant différents types de médias (par exemple, `application/json` et `application/xml`). Par exemple, si l'application cible exécute le même code quel que soit le type de contenu de la requête, il faudra plus de temps pour terminer la session de test, et elle peut signaler des vulnérabilités en double liées au corps de la requête selon l'application cible.

La variable d'environnement `APISEC_OPENAPI_ALL_MEDIA_TYPES` vous permet de spécifier s'il faut utiliser ou non tous les types de médias pris en charge au lieu d'un seul lors de la génération de requêtes pour une opération donnée. Lorsque la variable d'environnement `APISEC_OPENAPI_ALL_MEDIA_TYPES` est définie sur une valeur quelconque, le test de sécurité des API tente de générer des requêtes pour tous les types de médias pris en charge au lieu d'un seul dans une opération donnée. Cela entraînera un allongement du temps de test, car le test est répété pour chaque type de média fourni.

Alternativement, la variable `APISEC_OPENAPI_MEDIA_TYPES` est utilisée pour fournir une liste de types de médias qui seront chacun testés. Fournir plus d'un type de média entraîne un allongement du temps de test, car le test est effectué pour chaque type de média sélectionné. Lorsque la variable d'environnement `APISEC_OPENAPI_MEDIA_TYPES` est définie sur une liste de types de médias, seuls les types de médias répertoriés sont inclus lors de la création des requêtes.

Les types de médias multiples dans `APISEC_OPENAPI_MEDIA_TYPES` sont séparés par un deux-points (`:`). Par exemple, pour limiter la génération de requêtes aux types de médias `application/x-www-form-urlencoded` et `multipart/form-data`, définissez la variable d'environnement `APISEC_OPENAPI_MEDIA_TYPES` sur `application/x-www-form-urlencoded:multipart/form-data`. Seuls les types de médias pris en charge dans cette liste sont inclus lors de la création des requêtes ; les types de médias non pris en charge sont toujours ignorés. Le texte d'un type de média peut contenir différentes sections. Par exemple, `application/vnd.api+json; charset=UTF-8` est un composé de `type "/" [tree "."] subtype ["+" suffix]* [";" parameter]`. Les paramètres ne sont pas pris en compte lors du filtrage des types de médias lors de la génération des requêtes.

Les variables d'environnement `APISEC_OPENAPI_ALL_MEDIA_TYPES` et `APISEC_OPENAPI_MEDIA_TYPES` vous permettent de décider comment gérer les types de médias. Ces paramètres sont mutuellement exclusifs. Si les deux sont activés, le test de sécurité des API signale une erreur.

### Configurer le test de sécurité des API avec une spécification OpenAPI {#configure-api-security-testing-with-an-openapi-specification}

Pour configurer l'analyse de test de sécurité des API avec une spécification OpenAPI :

1. [Incluez](../../../../ci/yaml/_index.md#includetemplate) le [modèle `API-Security.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml) dans votre fichier `.gitlab-ci.yml`.
1. Le [fichier de configuration](variables.md#configuration-files) contient plusieurs profils de test définis avec différentes vérifications activées. Commencez par le profil `Quick`. Les tests avec ce profil se terminent plus rapidement, ce qui facilite la validation de la configuration. Fournissez le profil en ajoutant la variable CI/CD `APISEC_PROFILE` à votre fichier `.gitlab-ci.yml`.
1. Fournissez l'emplacement de la spécification OpenAPI sous forme de fichier ou d'URL. Spécifiez l'emplacement en ajoutant la variable `APISEC_OPENAPI`.
1. L'URL de base de l'instance d'API cible est également requise. Fournissez-la en utilisant la variable `APISEC_TARGET_URL` ou un fichier `environment_url.txt`.

   Ajouter l'URL dans un fichier `environment_url.txt` à la racine de votre projet est idéal pour les tests dans des environnements dynamiques. Pour exécuter le test de sécurité des API contre une application créée dynamiquement lors d'un pipeline CI/CD GitLab, demandez à l'application de conserver son URL dans un fichier `environment_url.txt`. Le test de sécurité des API analyse automatiquement ce fichier pour trouver sa cible d'analyse. Vous pouvez voir un exemple dans le [CI YAML Auto DevOps](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml) de GitLab.

Exemple de configuration complète utilisant une spécification OpenAPI :

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
```

Il s'agit d'une configuration minimale pour le test de sécurité des API. À partir de là, vous pouvez :

- [Exécuter votre première analyse](#running-your-first-scan).
- [Ajouter une authentification](customizing_analyzer_settings.md#authentication).
- Apprendre à [gérer les faux positifs](#handling-false-positives).

## HTTP Archive (HAR) {#http-archive-har}

Le [format HTTP Archive (HAR)](../../api_fuzzing/create_har_files.md) est un format de fichier d'archive pour la journalisation des transactions HTTP. Lorsqu'il est utilisé avec le scanner de test de sécurité des API GitLab, le fichier HAR doit contenir des enregistrements d'appels à l'API web à tester. Le scanner de test de sécurité des API extrait toutes les requêtes et les utilise pour effectuer les tests.

Vous pouvez utiliser divers outils pour générer des fichiers HAR :

- [Insomnia Core](https://insomnia.rest/) : Client API
- [Chrome](https://www.google.com/chrome/) : Navigateur
- [Firefox](https://www.mozilla.org/en-US/firefox/) : Navigateur
- [Fiddler](https://www.telerik.com/fiddler) : Proxy de débogage Web
- [GitLab HAR Recorder](https://gitlab.com/gitlab-org/security-products/har-recorder) : Ligne de commande

> [!warning]
> Les fichiers HAR peuvent contenir des informations sensibles telles que des jetons d'authentification, des clés API et des cookies de session. Vérifiez le contenu du fichier HAR avant de l'ajouter à un dépôt.

### Analyse de test de sécurité des API avec un fichier HAR {#api-security-testing-scanning-with-a-har-file}

Pour configurer le test de sécurité des API afin d'utiliser un fichier HAR qui fournit des informations sur l'API cible à tester :

1. [Incluez](../../../../ci/yaml/_index.md#includetemplate) le [modèle `API-Security.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml) dans votre fichier `.gitlab-ci.yml`.
1. Le [fichier de configuration](variables.md#configuration-files) contient plusieurs profils de test définis avec différentes vérifications activées. Commencez par le profil `Quick`. Les tests avec ce profil se terminent plus rapidement, ce qui facilite la validation de la configuration.

   Fournissez le profil en ajoutant la variable CI/CD `APISEC_PROFILE` à votre fichier `.gitlab-ci.yml`.
1. Fournissez l'emplacement du fichier HAR. Vous pouvez fournir l'emplacement sous forme de chemin de fichier ou d'URL. Spécifiez l'emplacement en ajoutant la variable `APISEC_HAR`.
1. L'URL de base de l'instance d'API cible est également requise. Fournissez-la en utilisant la variable `APISEC_TARGET_URL` ou un fichier `environment_url.txt`.

   Ajouter l'URL dans un fichier `environment_url.txt` à la racine de votre projet est idéal pour les tests dans des environnements dynamiques. Pour exécuter le test de sécurité des API contre une application créée dynamiquement lors d'un pipeline CI/CD GitLab, demandez à l'application de conserver son URL dans un fichier `environment_url.txt`. Le test de sécurité des API analyse automatiquement ce fichier pour trouver sa cible d'analyse. Vous pouvez voir un exemple dans le [CI YAML Auto DevOps](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml) de GitLab.

Exemple de configuration complète utilisant un fichier HAR :

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_HAR: test-api-recording.har
  APISEC_TARGET_URL: http://test-deployment/
```

Cet exemple est une configuration minimale pour le test de sécurité des API. À partir de là, vous pouvez :

- [Exécuter votre première analyse](#running-your-first-scan).
- [Ajouter une authentification](customizing_analyzer_settings.md#authentication).
- Apprendre à [gérer les faux positifs](#handling-false-positives).

## Schéma GraphQL {#graphql-schema}

{{< history >}}

- La prise en charge du schéma GraphQL a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/352780) dans GitLab 15.4.

{{< /history >}}

GraphQL est un langage de requête pour votre API et une alternative aux API REST. Le test de sécurité des API prend en charge le test des points de terminaison GraphQL de plusieurs façons :

- Tester en utilisant le schéma GraphQL. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/352780) dans GitLab 15.4.
- Tester en utilisant un enregistrement (HAR) de requêtes GraphQL.
- Tester en utilisant une collection Postman contenant des requêtes GraphQL.

Cette section documente comment tester en utilisant un schéma GraphQL. La prise en charge du schéma GraphQL dans le test de sécurité des API est capable d'interroger le schéma depuis les points de terminaison qui prennent en charge [l'introspection](https://graphql.org/learn/introspection/). L'introspection est activée par défaut pour permettre aux outils comme GraphiQL de fonctionner. Pour plus de détails sur la façon d'activer l'introspection, consultez la documentation de votre framework GraphQL.

### Analyse de test de sécurité des API avec une URL de point de terminaison GraphQL {#api-security-testing-scanning-with-a-graphql-endpoint-url}

La prise en charge GraphQL dans le test de sécurité des API est capable d'interroger un point de terminaison GraphQL pour le schéma.

> [!note]
> Le point de terminaison GraphQL doit prendre en charge les requêtes d'introspection pour que cette méthode fonctionne correctement.

Pour configurer le test de sécurité des API afin d'utiliser une URL de point de terminaison GraphQL qui fournit des informations sur l'API cible à tester :

1. [Incluez](../../../../ci/yaml/_index.md#includetemplate) le [modèle `API-Security.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml) dans votre fichier `.gitlab-ci.yml`.
1. Fournissez le chemin vers le point de terminaison GraphQL, par exemple `/api/graphql`. Spécifiez l'emplacement en ajoutant la variable `APISEC_GRAPHQL`.
1. L'URL de base de l'instance d'API cible est également requise. Fournissez-la en utilisant la variable `APISEC_TARGET_URL` ou un fichier `environment_url.txt`.

   Ajouter l'URL dans un fichier `environment_url.txt` à la racine de votre projet est idéal pour les tests dans des environnements dynamiques. Pour plus d'informations, consultez [les solutions pour les environnements dynamiques](../troubleshooting.md#dynamic-environment-solutions).

Exemple de configuration complète utilisant un chemin de point de terminaison GraphQL :

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

api_security:
  variables:
    APISEC_GRAPHQL: /api/graphql
    APISEC_TARGET_URL: http://test-deployment/
```

Cet exemple est une configuration minimale pour le test de sécurité des API. À partir de là, vous pouvez :

- [Exécuter votre première analyse](#running-your-first-scan).
- [Ajouter une authentification](customizing_analyzer_settings.md#authentication).
- Apprendre à [gérer les faux positifs](#handling-false-positives).

### Analyse de test de sécurité des API avec un fichier de schéma GraphQL {#api-security-testing-scanning-with-a-graphql-schema-file}

Le test de sécurité des API peut utiliser un fichier de schéma GraphQL pour comprendre et tester un point de terminaison GraphQL dont l'introspection est désactivée. Pour utiliser un fichier de schéma GraphQL, il doit être au format JSON d'introspection. Un schéma GraphQL peut être converti au format JSON d'introspection à l'aide d'un outil tiers en ligne : <https://transform.tools/graphql-to-introspection-json>.

Pour configurer le test de sécurité des API afin d'utiliser un fichier de schéma GraphQL qui fournit des informations sur l'API cible à tester :

1. [Incluez](../../../../ci/yaml/_index.md#includetemplate) le [modèle `API-Security.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml) dans votre fichier `.gitlab-ci.yml`.
1. Fournissez le chemin du point de terminaison GraphQL, par exemple `/api/graphql`. Spécifiez le chemin en ajoutant la variable `APISEC_GRAPHQL`.
1. Fournissez l'emplacement du fichier de schéma GraphQL. Vous pouvez fournir l'emplacement sous forme de chemin de fichier ou d'URL. Spécifiez l'emplacement en ajoutant la variable `APISEC_GRAPHQL_SCHEMA`.
1. L'URL de base de l'instance d'API cible est également requise. Fournissez-la en utilisant la variable `APISEC_TARGET_URL` ou un fichier `environment_url.txt`.

   Ajouter l'URL dans un fichier `environment_url.txt` à la racine de votre projet est idéal pour les tests dans des environnements dynamiques. Pour plus d'informations, consultez [les solutions pour les environnements dynamiques](../troubleshooting.md#dynamic-environment-solutions).

Exemple de configuration complète utilisant un fichier de schéma GraphQL :

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

api_security:
  variables:
    APISEC_GRAPHQL: /api/graphql
    APISEC_GRAPHQL_SCHEMA: test-api-graphql.schema
    APISEC_TARGET_URL: http://test-deployment/
```

Exemple de configuration complète utilisant une URL de fichier de schéma GraphQL :

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

api_security:
  variables:
    APISEC_GRAPHQL: /api/graphql
    APISEC_GRAPHQL_SCHEMA: http://file-store/files/test-api-graphql.schema
    APISEC_TARGET_URL: http://test-deployment/
```

Cet exemple est une configuration minimale pour le test de sécurité des API. À partir de là, vous pouvez :

- [Exécuter votre première analyse](#running-your-first-scan).
- [Ajouter une authentification](customizing_analyzer_settings.md#authentication).
- Apprendre à [gérer les faux positifs](#handling-false-positives).

## Collection Postman {#postman-collection}

Le [client API Postman](https://www.postman.com/product/api-client/) est un outil populaire que les développeurs et les testeurs utilisent pour appeler différents types d'API. Les définitions d'API [peuvent être exportées sous forme de fichier de collection Postman](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-collections) pour être utilisées avec le test de sécurité des API. Lors de l'exportation, assurez-vous de sélectionner une version prise en charge de la collection Postman : v2.0 ou v2.1.

Lorsqu'elles sont utilisées avec le scanner de test de sécurité des API GitLab, les collections Postman doivent contenir des définitions de l'API web à tester avec des données valides. Le scanner de test de sécurité des API extrait toutes les définitions d'API et les utilise pour effectuer les tests.

> [!warning]
> Les fichiers de collection Postman peuvent contenir des informations sensibles telles que des jetons d'authentification, des clés API et des cookies de session. Vérifiez le contenu du fichier de collection Postman avant de l'ajouter à un dépôt.

### Analyse de test de sécurité des API avec un fichier de collection Postman {#api-security-testing-scanning-with-a-postman-collection-file}

Pour configurer le test de sécurité des API afin d'utiliser un fichier de collection Postman qui fournit des informations sur l'API cible à tester :

1. [Incluez](../../../../ci/yaml/_index.md#includetemplate) le [modèle `API-Security.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml).
1. Le [fichier de configuration](variables.md#configuration-files) contient plusieurs profils de test définis avec différentes vérifications activées. Commencez par le profil `Quick`. Les tests avec ce profil se terminent plus rapidement, ce qui facilite la validation de la configuration.

   Fournissez le profil en ajoutant la variable CI/CD `APISEC_PROFILE` à votre fichier `.gitlab-ci.yml`.
1. Fournissez l'emplacement du fichier de collection Postman sous forme de fichier ou d'URL. Spécifiez l'emplacement en ajoutant la variable `APISEC_POSTMAN_COLLECTION`.
1. L'URL de base de l'instance d'API cible est également requise. Fournissez-la en utilisant la variable `APISEC_TARGET_URL` ou un fichier `environment_url.txt`.

   Ajouter l'URL dans un fichier `environment_url.txt` à la racine de votre projet est idéal pour les tests dans des environnements dynamiques. Pour exécuter le test de sécurité des API contre une application créée dynamiquement lors d'un pipeline CI/CD GitLab, demandez à l'application de conserver son URL dans un fichier `environment_url.txt`. Le test de sécurité des API analyse automatiquement ce fichier pour trouver sa cible d'analyse. Vous pouvez voir un exemple dans le [CI YAML Auto DevOps](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml) de GitLab.

Exemple de configuration complète utilisant une collection Postman :

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection_serviceA.json
  APISEC_TARGET_URL: http://test-deployment/
```

Il s'agit d'une configuration minimale pour le test de sécurité des API. À partir de là, vous pouvez :

- [Exécuter votre première analyse](#running-your-first-scan).
- [Ajouter une authentification](customizing_analyzer_settings.md#authentication).
- Apprendre à [gérer les faux positifs](#handling-false-positives).

### Variables Postman {#postman-variables}

{{< history >}}

- La prise en charge du format de fichier d'environnement Postman a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/356312) dans GitLab 15.1.
- La prise en charge de plusieurs fichiers de variables a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/356312) dans GitLab 15.1.
- La prise en charge des portées de variables Postman : Global et Environnement a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/356312) dans GitLab 15.1.

{{< /history >}}

#### Variables dans le client Postman {#variables-in-postman-client}

Postman permet au développeur de définir des espaces réservés pouvant être utilisés dans différentes parties des requêtes. Ces espaces réservés sont appelés variables, comme expliqué dans [l'utilisation des variables](https://learning.postman.com/docs/sending-requests/variables/variables/#using-variables). Vous pouvez utiliser des variables pour stocker et réutiliser des valeurs dans vos requêtes et scripts. Par exemple, vous pouvez modifier la collection pour ajouter des variables au document :

![Vue de l'onglet de variable de la collection en édition](img/dast_api_postman_collection_edit_variable_v18_5.png)

Ou alternativement, vous pouvez ajouter des variables dans un environnement :

![Vue d'édition des variables d'environnement](img/dast_api_postman_environment_edit_variable_v18_5.png)

Vous pouvez ensuite utiliser les variables dans des sections telles que l'URL, les en-têtes et autres :

![Vue d'édition de la requête utilisant des variables](img/dast_api_postman_request_edit_v18_5.png)

Postman a évolué d'un outil client basique avec une belle expérience UX vers un écosystème plus complexe permettant de tester des API avec des scripts, de créer des collections complexes qui déclenchent des requêtes secondaires et de définir des variables tout au long du processus. Toutes les fonctionnalités de l'écosystème Postman ne sont pas prises en charge. Par exemple, les scripts ne sont pas pris en charge. L'objectif principal de la prise en charge de Postman est d'ingérer les définitions de collection Postman utilisées par le client Postman et leurs variables associées définies dans le workspace, les environnements et les collections elles-mêmes.

Postman permet de créer des variables dans différentes portées. Chaque portée a un niveau de visibilité différent dans les outils Postman. Par exemple, vous pouvez créer une variable dans une _portée d'environnement global_ qui est visible par chaque définition d'opération et workspace. Vous pouvez également créer une variable dans une _portée d'environnement_ spécifique qui n'est visible et utilisée que lorsque cet environnement spécifique est sélectionné. Certaines portées ne sont pas toujours disponibles, par exemple dans l'écosystème Postman, vous pouvez créer des requêtes dans le client Postman, ces requêtes n'ont pas de portée _locale_, mais les scripts de test en ont.

Les portées de variables dans Postman peuvent être un sujet intimidant et tout le monde n'y est pas familier. Lisez [les portées de variables](https://learning.postman.com/docs/sending-requests/variables/variables/#variable-scopes) dans la documentation Postman avant de continuer.

Comme mentionné précédemment, il existe différentes portées de variables, et chacune d'elles a un objectif et peut être utilisée pour apporter plus de flexibilité à votre document Postman. Il y a une remarque importante sur la façon dont les valeurs des variables sont calculées, selon la documentation Postman :

> [!note]
> Si une variable portant le même nom est déclarée dans deux portées différentes, la valeur stockée dans la variable avec la portée la plus étroite est utilisée. Par exemple, s'il existe une variable globale nommée `username` et une variable locale nommée `username`, la valeur locale est utilisée lors de l'exécution de la requête.

Ce qui suit est un résumé des portées de variables prises en charge par le client Postman et le test de sécurité des API :

- **Global Environment (Global) scope** est un environnement prédéfini spécial disponible dans tout un workspace. Vous pouvez également désigner la portée de l'_environnement global_ comme la portée _globale_. Le client Postman permet d'exporter l'environnement global dans un fichier JSON, qui peut être utilisé avec le test de sécurité des API.
- **Portée de l'environnement** est un groupe nommé de variables créées par un utilisateur dans le client Postman. Le client Postman prend en charge un seul environnement actif ainsi que l'environnement global. Les variables définies dans un environnement actif créé par l'utilisateur ont priorité sur les variables définies dans l'environnement global. Le client Postman permet d'exporter votre environnement dans un fichier JSON, qui peut être utilisé avec le test de sécurité des API.
- **Collection scope** est un groupe de variables déclarées dans une collection donnée. Les variables de collection sont disponibles pour la collection dans laquelle elles ont été déclarées ainsi que pour les requêtes ou collections imbriquées. Les variables définies dans la portée de collection ont priorité sur la portée de l'_environnement global_ et également sur la portée de l'_environnement_. Le client Postman peut exporter une ou plusieurs collections dans un fichier JSON ; ce fichier JSON contient les collections, les requêtes et les variables de collection sélectionnées.
- **API security testing scope** est une nouvelle portée ajoutée par le test de sécurité des API pour permettre aux utilisateurs de fournir des variables supplémentaires ou de remplacer les variables définies dans d'autres portées prises en charge. Cette portée n'est pas prise en charge par Postman. Les variables de la _portée de test de sécurité des API_ sont fournies à l'aide d'un [format de fichier JSON personnalisé](#api-security-testing-scope-custom-json-file-format).
  - Remplacer les valeurs définies dans l'environnement ou la collection
  - Définir des variables à partir de scripts
  - Définir une seule ligne de données à partir de la _portée de données_ non prise en charge
- **Data scope** est un groupe de variables dont les noms et les valeurs proviennent de fichiers JSON ou CSV. Un exécuteur de collection Postman comme [Newman](https://learning.postman.com/docs/collections/using-newman-cli/command-line-integration-with-newman/) ou [Postman Collection Runner](https://learning.postman.com/docs/collections/running-collections/intro-to-collection-runs/) exécute les requêtes d'une collection autant de fois qu'il y a d'entrées dans le fichier JSON ou CSV. Un bon cas d'utilisation de ces variables est d'automatiser les tests à l'aide de scripts dans Postman. Le test de sécurité des API ne prend pas en charge la lecture de données depuis un fichier CSV ou JSON.
- **Local scope** correspond aux variables définies dans les scripts Postman. Le test de sécurité des API ne prend pas en charge les scripts Postman et, par extension, les variables définies dans les scripts. Vous pouvez toujours fournir des valeurs pour les variables définies dans les scripts en les définissant dans l'une des portées prises en charge ou dans le format JSON personnalisé.

Toutes les portées ne sont pas prises en charge par le test de sécurité des API et les variables définies dans les scripts ne sont pas prises en charge. Le tableau suivant est trié de la portée la plus large à la portée la plus étroite.

| Portée                      | Postman | Test de sécurité des API | Commentaire                                    |
|----------------------------|:-------:|:--------------------:|:-------------------------------------------|
| Environnement global         |   Oui   |         Oui          | Environnement prédéfini spécial            |
| Environnement                |   Oui   |         Oui          | Environnements nommés                         |
| Collection                 |   Oui   |         Oui          | Défini dans votre collection Postman         |
| Portée de test de sécurité des API |   Non    |         Oui          | Portée personnalisée ajoutée par le test de sécurité des API |
| Données                       |   Oui   |          Non          | Fichiers externes au format CSV ou JSON       |
| Local                      |   Oui   |          Non          | Variables définies dans les scripts               |

Pour plus de détails sur la façon de définir et d'exporter des variables dans différentes portées, consultez :

- [Définition des variables de collection](https://learning.postman.com/docs/sending-requests/variables/variables/#defining-collection-variables)
- [Définition des variables d'environnement](https://learning.postman.com/docs/sending-requests/variables/variables/#defining-environment-variables)
- [Définition des variables globales](https://learning.postman.com/docs/sending-requests/variables/variables/#defining-global-variables)

##### Exportation depuis le client Postman {#exporting-from-postman-client}

Le client Postman vous permet d'exporter différents formats de fichiers ; par exemple, vous pouvez exporter une collection Postman ou un environnement Postman. L'environnement exporté peut être l'environnement global (qui est toujours disponible) ou tout environnement personnalisé que vous avez précédemment créé. Lorsque vous exportez une collection Postman, elle peut ne contenir que des déclarations pour les variables de portée _collection_ et _locale_ ; les variables de portée _environnement_ ne sont pas incluses.

Pour obtenir la déclaration des variables de portée _environnement_, vous devez exporter un environnement donné au moment voulu. Chaque fichier exporté inclut uniquement les variables de l'environnement sélectionné.

Pour plus de détails sur l'exportation de variables dans différentes portées prises en charge, consultez :

- [Exportation des collections](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-collections)
- [Exportation des environnements](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)
- [Téléchargement des environnements globaux](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)

#### Portée de test de sécurité des API, format de fichier JSON personnalisé {#api-security-testing-scope-custom-json-file-format}

Le format de fichier JSON personnalisé est un objet JSON où chaque propriété d'objet représente un nom de variable et la valeur de propriété représente la valeur de variable. Ce fichier peut être créé à l'aide de votre éditeur de texte préféré, ou il peut être produit par un job antérieur dans votre pipeline.

Cet exemple définit deux variables `base_url` et `token` dans la portée de test de sécurité des API :

```json
{
  "base_url": "http://127.0.0.1/",
  "token": "Token 84816165151"
}
```

#### Utilisation des portées avec le test de sécurité des API {#using-scopes-with-api-security-testing}

Les portées : _global_, _environment_, _collection_ et _GitLab API security testing_ sont prises en charge dans [GitLab 15.1 et versions ultérieures](https://gitlab.com/gitlab-org/gitlab/-/issues/356312). GitLab 15.0 et versions antérieures ne prennent en charge que les portées _collection_ et _GitLab API security testing_.

Le tableau suivant fournit une référence rapide pour mapper les fichiers/URLs de portée aux variables de configuration du test de sécurité des API :

| Portée              |  Comment fournir |
| ------------------ | --------------- |
| Environnement global | APISEC_POSTMAN_COLLECTION_VARIABLES |
| Environnement        | APISEC_POSTMAN_COLLECTION_VARIABLES |
| Collection         | APISEC_POSTMAN_COLLECTION           |
| Portée de test de sécurité des API | APISEC_POSTMAN_COLLECTION_VARIABLES |
| Données               | Non pris en charge   |
| Local              | Non pris en charge   |

Le document de collection Postman inclut automatiquement toutes les variables de portée _collection_. La collection Postman est fournie avec la variable de configuration `APISEC_POSTMAN_COLLECTION`. Cette variable peut être définie sur une seule [collection Postman exportée](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-collections).

Les variables d'autres portées sont fournies via la variable de configuration `APISEC_POSTMAN_COLLECTION_VARIABLES`. La variable de configuration prend en charge une liste de fichiers délimitée par une virgule (`,`) dans [GitLab 15.1 et versions ultérieures](https://gitlab.com/gitlab-org/gitlab/-/issues/356312). GitLab 15.0 et versions antérieures ne prennent en charge qu'un seul fichier. L'ordre des fichiers fournis n'est pas important car les fichiers fournissent les informations de portée nécessaires.

La variable de configuration `APISEC_POSTMAN_COLLECTION_VARIABLES` peut être définie sur :

- [Environnement global exporté](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)
- [Environnements exportés](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)
- [Format JSON personnalisé de test de sécurité des API](#api-security-testing-scope-custom-json-file-format)

#### Variables Postman non définies {#undefined-postman-variables}

Il est possible que le moteur de test de sécurité des API ne trouve pas toutes les références de variables que votre fichier de collection Postman utilise. Certains cas peuvent être :

- Vous utilisez des variables de portée _data_ ou _locale_, et comme indiqué précédemment, ces portées ne sont pas prises en charge par le test de sécurité des API. Ainsi, en supposant que les valeurs de ces variables n'ont pas été fournies via [la portée de test de sécurité des API](#api-security-testing-scope-custom-json-file-format), les valeurs des variables de portée _data_ et _locale_ sont indéfinies.
- Un nom de variable a été saisi incorrectement et le nom ne correspond pas à la variable définie.
- Le client Postman prend en charge une nouvelle variable dynamique qui n'est pas prise en charge par le test de sécurité des API.

Lorsque c'est possible, le test de sécurité des API adopte le même comportement que le client Postman lors du traitement des variables non définies. Le texte de la référence de variable reste identique et il n'y a pas de substitution de texte. Le même comportement s'applique également à toutes les variables dynamiques non prises en charge.

Par exemple, si une définition de requête dans la collection Postman référence la variable `{{full_url}}` et que la variable n'est pas trouvée, elle reste inchangée avec la valeur `{{full_url}}`.

#### Variables Postman dynamiques {#dynamic-postman-variables}

En plus des variables qu'un utilisateur peut définir à différents niveaux de portée, Postman dispose d'un ensemble de variables prédéfinies appelées variables _dynamiques_. Les [variables _dynamiques_](https://learning.postman.com/docs/tests-and-scripts/write-scripts/variables-list/) sont déjà définies et leur nom est préfixé par un signe dollar (`$`), par exemple `$guid`. Les variables _dynamiques_ peuvent être utilisées comme n'importe quelle autre variable et, dans le client Postman, elles produisent des valeurs aléatoires lors de l'exécution de la requête/collection.

Une différence importante entre le test de sécurité des API et Postman est que le test de sécurité des API renvoie la même valeur pour chaque utilisation des mêmes variables dynamiques. Cela diffère du comportement du client Postman qui renvoie une valeur aléatoire à chaque utilisation de la même variable dynamique. En d'autres termes, le test de sécurité des API utilise des valeurs statiques pour les variables dynamiques tandis que Postman utilise des valeurs aléatoires.

Les variables dynamiques prises en charge lors du processus d'analyse sont :

| Variable    | Valeur       |
| ----------- | ----------- |
| `$guid` | `611c2e81-2ccb-42d8-9ddc-2d0bfa65c1b4` |
| `$isoTimestamp` | `2020-06-09T21:10:36.177Z` |
| `$randomAbbreviation` | `PCI` |
| `$randomAbstractImage` | `http://no-a-valid-host/640/480/abstract` |
| `$randomAdjective` | `auxiliary` |
| `$randomAlphaNumeric` | `a` |
| `$randomAnimalsImage` | `http://no-a-valid-host/640/480/animals` |
| `$randomAvatarImage` | `https://no-a-valid-host/path/to/some/image.jpg` |
| `$randomBankAccount` | `09454073` |
| `$randomBankAccountBic` | `EZIAUGJ1` |
| `$randomBankAccountIban` | `MU20ZPUN3039684000618086155TKZ` |
| `$randomBankAccountName` | `Home Loan Account` |
| `$randomBitcoin` | `3VB8JGT7Y4Z63U68KGGKDXMLLH5` |
| `$randomBoolean` | `true` |
| `$randomBs` | `killer leverage schemas` |
| `$randomBsAdjective` | `viral` |
| `$randomBsBuzz` | `repurpose` |
| `$randomBsNoun` | `markets` |
| `$randomBusinessImage` | `http://no-a-valid-host/640/480/business` |
| `$randomCatchPhrase` | `Future-proofed heuristic open architecture` |
| `$randomCatchPhraseAdjective` | `Business-focused` |
| `$randomCatchPhraseDescriptor` | `bandwidth-monitored` |
| `$randomCatchPhraseNoun` | `superstructure` |
| `$randomCatsImage` | `http://no-a-valid-host/640/480/cats` |
| `$randomCity` | `Spinkahaven` |
| `$randomCityImage` | `http://no-a-valid-host/640/480/city` |
| `$randomColor` | `fuchsia` |
| `$randomCommonFileExt` | `wav` |
| `$randomCommonFileName` | `well_modulated.mpg4` |
| `$randomCommonFileType` | `audio` |
| `$randomCompanyName` | `Grady LLC` |
| `$randomCompanySuffix` | `Inc` |
| `$randomCountry` | `Kazakhstan` |
| `$randomCountryCode` | `MD` |
| `$randomCreditCardMask` | `3622` |
| `$randomCurrencyCode` | `ZMK` |
| `$randomCurrencyName` | `Pound Sterling` |
| `$randomCurrencySymbol` | `£` |
| `$randomDatabaseCollation` | `utf8_general_ci` |
| `$randomDatabaseColumn` | `updatedAt` |
| `$randomDatabaseEngine` | `Memory` |
| `$randomDatabaseType` | `text` |
| `$randomDateFuture` | `Tue Mar 17 2020 13:11:50 GMT+0530 (India Standard Time)` |
| `$randomDatePast` | `Sat Mar 02 2019 09:09:26 GMT+0530 (India Standard Time)` |
| `$randomDateRecent` | `Tue Jul 09 2019 23:12:37 GMT+0530 (India Standard Time)` |
| `$randomDepartment` | `Electronics` |
| `$randomDirectoryPath` | `/usr/local/bin` |
| `$randomDomainName` | `trevor.info` |
| `$randomDomainSuffix` | `org` |
| `$randomDomainWord` | `jaden` |
| `$randomEmail` | `Iva.Kovacek61@no-a-valid-host.com` |
| `$randomExampleEmail` | `non-a-valid-user@example.net` |
| `$randomFashionImage` | `http://no-a-valid-host/640/480/fashion` |
| `$randomFileExt` | `war` |
| `$randomFileName` | `neural_sri_lanka_rupee_gloves.gdoc` |
| `$randomFilePath` | `/home/programming_chicken.cpio` |
| `$randomFileType` | `application` |
| `$randomFirstName` | `Chandler` |
| `$randomFoodImage` | `http://no-a-valid-host/640/480/food` |
| `$randomFullName` | `Connie Runolfsdottir` |
| `$randomHexColor` | `#47594a` |
| `$randomImageDataUri` | `data:image/svg+xml;charset=UTF-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20version%3D%221.1%22%20baseProfile%3D%22full%22%20width%3D%22undefined%22%20height%3D%22undefined%22%3E%20%3Crect%20width%3D%22100%25%22%20height%3D%22100%25%22%20fill%3D%22grey%22%2F%3E%20%20%3Ctext%20x%3D%220%22%20y%3D%2220%22%20font-size%3D%2220%22%20text-anchor%3D%22start%22%20fill%3D%22white%22%3Eundefinedxundefined%3C%2Ftext%3E%20%3C%2Fsvg%3E` |
| `$randomImageUrl` | `http://no-a-valid-host/640/480` |
| `$randomIngverb` | `navigating` |
| `$randomInt` | `494` |
| `$randomIP` | `241.102.234.100` |
| `$randomIPV6` | `dbe2:7ae6:119b:c161:1560:6dda:3a9b:90a9` |
| `$randomJobArea` | `Mobility` |
| `$randomJobDescriptor` | `Senior` |
| `$randomJobTitle` | `International Creative Liaison` |
| `$randomJobType` | `Supervisor` |
| `$randomLastName` | `Schneider` |
| `$randomLatitude` | `55.2099` |
| `$randomLocale` | `ny` |
| `$randomLongitude` | `40.6609` |
| `$randomLoremLines` | `Ducimus in ut mollitia.\nA itaque non.\nHarum temporibus nihil voluptas.\nIste in sed et nesciunt in quaerat sed.` |
| `$randomLoremParagraph` | `Ab aliquid odio iste quo voluptas voluptatem dignissimos velit. Recusandae facilis qui commodi ea magnam enim nostrum quia quis. Nihil est suscipit assumenda ut voluptatem sed. Esse ab voluptas odit qui molestiae. Rem est nesciunt est quis ipsam expedita consequuntur.` |
| `$randomLoremParagraphs` | `Voluptatem rem magnam aliquam ab id aut quaerat. Placeat provident possimus voluptatibus dicta velit non aut quasi. Mollitia et aliquam expedita sunt dolores nam consequuntur. Nam dolorum delectus ipsam repudiandae et ipsam ut voluptatum totam. Nobis labore labore recusandae ipsam quo.` |
| `$randomLoremSentence` | `Molestias consequuntur nisi non quod.` |
| `$randomLoremSentences` | `Et sint voluptas similique iure amet perspiciatis vero sequi atque. Ut porro sit et hic. Neque aspernatur vitae fugiat ut dolore et veritatis. Ab iusto ex delectus animi. Voluptates nisi iusto. Impedit quod quae voluptate qui.` |
| `$randomLoremSlug` | `eos-aperiam-accusamus, beatae-id-molestiae, qui-est-repellat` |
| `$randomLoremText` | `Quisquam asperiores exercitationem ut ipsum. Aut eius nesciunt. Et reiciendis aut alias eaque. Nihil amet laboriosam pariatur eligendi. Sunt ullam ut sint natus ducimus. Voluptas harum aspernatur soluta rem nam.` |
| `$randomLoremWord` | `est` |
| `$randomLoremWords` | `vel repellat nobis` |
| `$randomMACAddress` | `33:d4:68:5f:b4:c7` |
| `$randomMimeType` | `audio/vnd.vmx.cvsd` |
| `$randomMonth` | `February` |
| `$randomNamePrefix` | `Dr.` |
| `$randomNameSuffix` | `MD` |
| `$randomNatureImage` | `http://no-a-valid-host/640/480/nature` |
| `$randomNightlifeImage` | `http://no-a-valid-host/640/480/nightlife` |
| `$randomNoun` | `bus` |
| `$randomPassword` | `t9iXe7COoDKv8k3` |
| `$randomPeopleImage` | `http://no-a-valid-host/640/480/people` |
| `$randomPhoneNumber` | `700-008-5275` |
| `$randomPhoneNumberExt` | `27-199-983-3864` |
| `$randomPhrase` | `You can't program the monitor without navigating the mobile XML program!` |
| `$randomPrice` | `531.55` |
| `$randomProduct` | `Pizza` |
| `$randomProductAdjective` | `Unbranded` |
| `$randomProductMaterial` | `Steel` |
| `$randomProductName` | `Handmade Concrete Tuna` |
| `$randomProtocol` | `https` |
| `$randomSemver` | `7.0.5` |
| `$randomSportsImage` | `http://no-a-valid-host/640/480/sports` |
| `$randomStreetAddress` | `5742 Harvey Streets` |
| `$randomStreetName` | `Kuhic Island` |
| `$randomTransactionType` | `payment` |
| `$randomTransportImage` | `http://no-a-valid-host/640/480/transport` |
| `$randomUrl` | `https://no-a-valid-host.net` |
| `$randomUserAgent` | `Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.9.8; rv:15.6) Gecko/20100101 Firefox/15.6.6` |
| `$randomUserName` | `Jarrell.Gutkowski` |
| `$randomUUID` | `6929bb52-3ab2-448a-9796-d6480ecad36b` |
| `$randomVerb` | `navigate` |
| `$randomWeekday` | `Thursday` |
| `$randomWord` | `withdrawal` |
| `$randomWords` | `Samoa Synergistic sticky copying Grocery` |
| `$timestamp` | `1562757107` |

#### Exemple : Portée globale {#example-global-scope}

Dans cet exemple, [la portée _globale_ est exportée](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments) depuis le client Postman sous le nom `global-scope.json` et fournie au test de sécurité des API via la variable de configuration `APISEC_POSTMAN_COLLECTION_VARIABLES`.

Voici un exemple d'utilisation de `APISEC_POSTMAN_COLLECTION_VARIABLES` :

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection.json
  APISEC_POSTMAN_COLLECTION_VARIABLES: global-scope.json
  APISEC_TARGET_URL: http://test-deployment/
```

#### Exemple : Portée d'environnement {#example-environment-scope}

Dans cet exemple, [la portée _d'environnement_ est exportée](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments) depuis le client Postman sous le nom `environment-scope.json` et fournie au test de sécurité des API via la variable de configuration `APISEC_POSTMAN_COLLECTION_VARIABLES`.

Voici un exemple d'utilisation de `APISEC_POSTMAN_COLLECTION_VARIABLES` :

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection.json
  APISEC_POSTMAN_COLLECTION_VARIABLES: environment-scope.json
  APISEC_TARGET_URL: http://test-deployment/
```

#### Exemple : Portée de collection {#example-collection-scope}

Les variables de portée _collection_ sont incluses dans le fichier de collection Postman exporté et fournies via la variable de configuration `APISEC_POSTMAN_COLLECTION`.

Voici un exemple d'utilisation de `APISEC_POSTMAN_COLLECTION` :

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection.json
  APISEC_TARGET_URL: http://test-deployment/
```

#### Exemple : Portée de test de sécurité des API {#example-api-security-testing-scope}

La portée de test de sécurité des API est utilisée à deux fins principales : définir des variables de portée _data_ et _locale_ qui ne sont pas prises en charge par le test de sécurité des API, et modifier la valeur d'une variable existante définie dans une autre portée. La portée de test de sécurité des API est fournie via la variable de configuration `APISEC_POSTMAN_COLLECTION_VARIABLES`.

Voici un exemple d'utilisation de `APISEC_POSTMAN_COLLECTION_VARIABLES` :

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection.json
  APISEC_POSTMAN_COLLECTION_VARIABLES: dast-api-scope.json
  APISEC_TARGET_URL: http://test-deployment/
```

Le fichier `dast-api-scope.json` utilise le [format de fichier JSON personnalisé](#api-security-testing-scope-custom-json-file-format). Ce JSON est un objet avec des paires clé-valeur pour les propriétés. Les clés sont les noms des variables et les valeurs sont les valeurs des variables. Par exemple :

```json
{
  "base_url": "http://127.0.0.1/",
  "token": "Token 84816165151"
}
```

#### Exemple : Portées multiples {#example-multiple-scopes}

Dans cet exemple, une portée _globale_, une portée _d'environnement_ et une portée _de collection_ sont configurées. La première étape consiste à exporter les différentes portées.

- [Exportez la portée _globale_](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments) sous le nom `global-scope.json`
- [Exportez la portée _d'environnement_](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments) sous le nom `environment-scope.json`
- Exportez la collection Postman qui inclut la portée _collection_ sous le nom `postman-collection.json`

La collection Postman est fournie à l'aide de la variable `APISEC_POSTMAN_COLLECTION`, tandis que les autres portées sont fournies à l'aide de `APISEC_POSTMAN_COLLECTION_VARIABLES`. Le test de sécurité des API peut identifier quelle portée correspond aux fichiers fournis en utilisant les données contenues dans chaque fichier.

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection.json
  APISEC_POSTMAN_COLLECTION_VARIABLES: global-scope.json,environment-scope.json
  APISEC_TARGET_URL: http://test-deployment/
```

#### Exemple : Modification de la valeur d'une variable {#example-changing-a-variables-value}

Lors de l'utilisation de portées exportées, il arrive souvent que la valeur d'une variable doive être modifiée pour être utilisée avec le test de sécurité des API. Par exemple, une variable de portée _collection_ pourrait contenir une variable nommée `api_version` avec une valeur `v2`, tandis que votre test nécessite une valeur `v1`. Au lieu de modifier la collection exportée pour changer la valeur, la portée de test de sécurité des API peut être utilisée pour modifier sa valeur. Cela fonctionne car la portée _de test de sécurité des API_ a priorité sur toutes les autres portées.

Les variables de portée _collection_ sont incluses dans le fichier de collection Postman exporté et fournies via la variable de configuration `APISEC_POSTMAN_COLLECTION`.

La portée de test de sécurité des API est fournie via la variable de configuration `APISEC_POSTMAN_COLLECTION_VARIABLES`. Mais d'abord, créez le fichier. Le fichier `dast-api-scope.json` utilise le [format de fichier JSON personnalisé](#api-security-testing-scope-custom-json-file-format). Ce JSON est un objet avec des paires clé-valeur pour les propriétés. Les clés sont les noms des variables et les valeurs sont les valeurs des variables. Par exemple :

```json
{
  "api_version": "v1"
}
```

La définition CI :

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection.json
  APISEC_POSTMAN_COLLECTION_VARIABLES: dast-api-scope.json
  APISEC_TARGET_URL: http://test-deployment/
```

#### Exemple : Modification de la valeur d'une variable avec plusieurs portées {#example-changing-a-variables-value-with-multiple-scopes}

Lors de l'utilisation de portées exportées, il arrive souvent que la valeur d'une variable doive être modifiée pour être utilisée avec le test de sécurité des API. Par exemple, une portée _d'environnement_ pourrait contenir une variable nommée `api_version` avec une valeur `v2`, tandis que votre test nécessite une valeur `v1`. Au lieu de modifier le fichier exporté pour changer la valeur, la portée de test de sécurité des API peut être utilisée. Cela fonctionne car la portée _de test de sécurité des API_ a priorité sur toutes les autres portées.

Dans cet exemple, une portée _globale_, une portée _d'environnement_, une portée _de collection_ et une portée _de test de sécurité des API_ sont configurées. La première étape consiste à exporter et créer les différentes portées.

- [Exportez la portée _globale_](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments) sous le nom `global-scope.json`
- [Exportez la portée _d'environnement_](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments) sous le nom `environment-scope.json`
- Exportez la collection Postman qui inclut la portée _collection_ sous le nom `postman-collection.json`

La portée de test de sécurité des API est utilisée en créant un fichier `dast-api-scope.json` à l'aide du [format de fichier JSON personnalisé](#api-security-testing-scope-custom-json-file-format). Ce JSON est un objet avec des paires clé-valeur pour les propriétés. Les clés sont les noms des variables et les valeurs sont les valeurs des variables. Par exemple :

```json
{
  "api_version": "v1"
}
```

La collection Postman est fournie à l'aide de la variable `APISEC_POSTMAN_COLLECTION`, tandis que les autres portées sont fournies à l'aide de `APISEC_POSTMAN_COLLECTION_VARIABLES`. Le test de sécurité des API peut identifier quelle portée correspond aux fichiers fournis en utilisant les données contenues dans chaque fichier.

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection.json
  APISEC_POSTMAN_COLLECTION_VARIABLES: global-scope.json,environment-scope.json,dast-api-scope.json
  APISEC_TARGET_URL: http://test-deployment/
```

## Exécution de votre première analyse {#running-your-first-scan}

Lorsqu'il est correctement configuré, un pipeline CI/CD contient une étape `dast` et un job `dast_api`. Le job échoue uniquement lorsqu'une configuration invalide est fournie. En fonctionnement normal, le job réussit toujours, même si des vulnérabilités sont identifiées lors des tests.

Les vulnérabilités sont affichées dans l'onglet **Sécurité** du pipeline avec le nom de la suite. Lors des tests sur la branche par défaut du dépôt, les vulnérabilités du test de sécurité des API sont également affichées dans le rapport de vulnérabilités de la section Sécurité et conformité.

Pour éviter un nombre excessif de vulnérabilités signalées, le scanner de test de sécurité des API limite le nombre de vulnérabilités qu'il signale par opération.

## Affichage des vulnérabilités du test de sécurité des API {#viewing-api-security-testing-vulnerabilities}

L'analyseur de test de sécurité des API produit un rapport JSON qui est collecté et utilisé [pour renseigner les vulnérabilités dans les écrans de vulnérabilités GitLab](#view-details-of-an-api-security-testing-vulnerability).

Consultez [la gestion des faux positifs](#handling-false-positives) pour obtenir des informations sur les modifications de configuration que vous pouvez apporter pour limiter le nombre de faux positifs signalés.

### Afficher les détails d'une vulnérabilité du test de sécurité des API {#view-details-of-an-api-security-testing-vulnerability}

Suivez ces étapes pour afficher les détails d'une vulnérabilité :

1. Vous pouvez afficher les vulnérabilités dans un projet ou un merge request :

   - Dans un projet, accédez à la page **Sécurisation** > **Rapport de vulnérabilités** du projet. Cette page affiche toutes les vulnérabilités de la branche par défaut uniquement.
   - Dans un merge request, accédez à la section **Sécurité** du merge request et sélectionnez le bouton **Étendre**. Les vulnérabilités du test de sécurité des API sont disponibles dans une section intitulée **DAST detected N potential vulnerabilities**. Sélectionnez le titre pour afficher les détails de la vulnérabilité.

1. Sélectionnez le titre des vulnérabilités pour afficher les détails. Le tableau ci-dessous décrit ces détails.

   | Champ               | Description                                                                             |
   |:--------------------|:----------------------------------------------------------------------------------------|
   | Description         | Description de la vulnérabilité, y compris ce qui a été modifié.                           |
   | Projet             | Espace de nommage et projet dans lesquels la vulnérabilité a été détectée.                          |
   | Méthode              | Méthode HTTP utilisée pour détecter la vulnérabilité.                                           |
   | URL                 | URL à laquelle la vulnérabilité a été détectée.                                            |
   | Requête             | La requête HTTP qui a causé la vulnérabilité.                                         |
   | Réponse non modifiée | Réponse à une requête non modifiée. Une réponse fonctionnelle typique ressemble à une réponse non modifiée.|
   | Réponse réelle     | Réponse reçue de la requête de test.                                                    |
   | Preuve            | Comment GitLab a déterminé qu'une vulnérabilité s'est produite.                                         |
   | Identifiants         | La vérification de test de sécurité des API utilisée pour trouver cette vulnérabilité.                         |
   | Gravité            | Gravité de la vulnérabilité.                                                          |
   | Type de scanner        | Scanner utilisé pour effectuer les tests.                                                        |

### Tableau de bord de sécurité {#security-dashboard}

Le tableau de bord de sécurité est un bon endroit pour obtenir une vue d'ensemble de toutes les vulnérabilités de sécurité dans vos groupes, projets et pipelines. Pour plus d'informations, consultez la [documentation du tableau de bord de sécurité](../../security_dashboard/_index.md).

### Interaction avec les vulnérabilités {#interacting-with-the-vulnerabilities}

Une fois qu'une vulnérabilité est trouvée, vous pouvez interagir avec elle. En savoir plus sur la façon de [traiter les vulnérabilités](../../vulnerabilities/_index.md).

### Gestion des faux positifs {#handling-false-positives}

Les faux positifs peuvent être gérés de plusieurs façons :

- Ignorer la vulnérabilité.
- Certaines vérifications ont plusieurs méthodes pour détecter quand une vulnérabilité est identifiée, appelées _Assertions_. Les assertions peuvent également être désactivées et configurées. Par exemple, le scanner de test de sécurité des API utilise par défaut les codes d'état HTTP pour aider à identifier quand quelque chose est un vrai problème. Si une API renvoie une erreur 500 lors des tests, cela crée une vulnérabilité. Ce n'est pas toujours souhaitable, car certains frameworks renvoient souvent des erreurs 500.
- Désactiver la vérification produisant le faux positif. Cela empêche la vérification de générer des vulnérabilités. Des exemples de vérifications sont le contrôle d'injection SQL et le contrôle de détournement JSON.

#### Désactiver une vérification {#turn-off-a-check}

Les vérifications effectuent des tests d'un type spécifique et peuvent être activées et désactivées pour des profils de configuration spécifiques. Les [fichiers de configuration](variables.md#configuration-files) fournis définissent plusieurs profils que vous pouvez utiliser. La définition du profil dans le fichier de configuration répertorie toutes les vérifications actives lors d'une analyse. Pour désactiver une vérification spécifique, supprimez-la de la définition du profil dans le fichier de configuration. Les profils sont définis dans la section `Profiles` du fichier de configuration.

Exemple de définition de profil :

```yaml
Profiles:
  - Name: Quick
    DefaultProfile: Empty
    Routes:
      - Route: *Route0
        Checks:
          - Name: ApplicationInformationCheck
          - Name: CleartextAuthenticationCheck
          - Name: FrameworkDebugModeCheck
          - Name: HtmlInjectionCheck
          - Name: InsecureHttpMethodsCheck
          - Name: JsonHijackingCheck
          - Name: JsonInjectionCheck
          - Name: SensitiveInformationCheck
          - Name: SessionCookieCheck
          - Name: SqlInjectionCheck
          - Name: TokenCheck
          - Name: XmlInjectionCheck
```

Pour désactiver le contrôle de détournement JSON, vous pouvez supprimer ces lignes :

```yaml
          - Name: JsonHijackingCheck
```

Cela donne le YAML suivant :

```yaml
- Name: Quick
  DefaultProfile: Empty
  Routes:
    - Route: *Route0
      Checks:
        - Name: ApplicationInformationCheck
        - Name: CleartextAuthenticationCheck
        - Name: FrameworkDebugModeCheck
        - Name: HtmlInjectionCheck
        - Name: InsecureHttpMethodsCheck
        - Name: JsonInjectionCheck
        - Name: SensitiveInformationCheck
        - Name: SessionCookieCheck
        - Name: SqlInjectionCheck
        - Name: TokenCheck
        - Name: XmlInjectionCheck
```

#### Désactiver une assertion pour une vérification {#turn-off-an-assertion-for-a-check}

Les assertions détectent les vulnérabilités dans les tests produits par les vérifications. De nombreuses vérifications prennent en charge plusieurs assertions telles que l'analyse de journaux, l'analyse de réponse et le code d'état. Lorsqu'une vulnérabilité est trouvée, l'assertion utilisée est indiquée. Pour identifier quelles assertions sont activées par défaut, consultez la configuration par défaut des vérifications dans le fichier de configuration. La section est appelée `Checks`.

Cet exemple montre le contrôle d'injection SQL :

```yaml
- Name: SqlInjectionCheck
  Configuration:
    UserInjections: []
  Assertions:
    - Name: LogAnalysisAssertion
    - Name: ResponseAnalysisAssertion
    - Name: StatusCodeAssertion
```

Vous pouvez voir que trois assertions sont activées par défaut. Une source courante de faux positifs est `StatusCodeAssertion`. Pour la désactiver, modifiez sa configuration dans la section `Profiles`. Cet exemple ne fournit que les deux autres assertions (`LogAnalysisAssertion`, `ResponseAnalysisAssertion`). Cela empêche `SqlInjectionCheck` d'utiliser `StatusCodeAssertion` :

```yaml
Profiles:
  - Name: Quick
    DefaultProfile: Empty
    Routes:
      - Route: *Route0
        Checks:
          - Name: ApplicationInformationCheck
          - Name: CleartextAuthenticationCheck
          - Name: FrameworkDebugModeCheck
          - Name: HtmlInjectionCheck
          - Name: InsecureHttpMethodsCheck
          - Name: JsonHijackingCheck
          - Name: JsonInjectionCheck
          - Name: SensitiveInformationCheck
          - Name: SessionCookieCheck
          - Name: SqlInjectionCheck
            Assertions:
              - Name: LogAnalysisAssertion
              - Name: ResponseAnalysisAssertion
          - Name: TokenCheck
          - Name: XmlInjectionCheck
```
