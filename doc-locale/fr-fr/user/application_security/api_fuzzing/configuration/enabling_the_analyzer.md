---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Activer l'analyseur"
---

Prérequis :

- L'un des types d'API web suivants :
  - API REST
  - SOAP
  - GraphQL
  - Corps de formulaires, JSON ou XML
- L'un des actifs suivants pour fournir des API à tester :
  - Définition d'API OpenAPI v2 ou v3
  - Archive HTTP (HAR) des requêtes API à tester
  - Collection Postman v2.0 ou v2.1

  > [!warning]
  > N'exécutez **jamais** de tests de fuzzing contre un serveur de production. Non seulement il peut effectuer n'importe quelle fonction que l'API peut effectuer, mais il peut également déclencher des bogues dans l'API. Cela inclut des actions telles que la modification et la suppression de données. N'exécutez le fuzzing que contre un serveur de test.

Pour activer le fuzzing d'API web, utilisez le formulaire de configuration du fuzzing d'API web.

- Pour les instructions de configuration manuelle, consultez la section correspondante, en fonction du type d'API :
  - [Spécification OpenAPI](#openapi-specification)
  - [Schéma GraphQL](#graphql-schema)
  - [HTTP Archive (HAR)](#http-archive-har)
  - [Postman Collection](#postman-collection)
- Sinon, consultez [le formulaire de configuration du fuzzing d'API web](#web-api-fuzzing-configuration-form).

Les fichiers de configuration du fuzzing d'API doivent se trouver dans le répertoire `.gitlab` de votre dépôt.

## Formulaire de configuration du fuzzing d'API web {#web-api-fuzzing-configuration-form}

Le formulaire de configuration du fuzzing d'API vous aide à créer ou à modifier la configuration du fuzzing d'API de votre projet. Le formulaire vous permet de choisir des valeurs pour les options de fuzzing d'API les plus courantes et génère un extrait YAML que vous pouvez coller dans votre configuration CI/CD GitLab.

### Configurer le fuzzing d'API web dans l'interface utilisateur {#configure-web-api-fuzzing-in-the-ui}

Pour générer un extrait de configuration du fuzzing d'API :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Configuration de la sécurité**.
1. Dans la ligne **Test de l'API par injection de données aléatoires**, sélectionnez **Activer le fuzzing d'API**.
1. Remplissez les champs. Pour plus de détails, consultez [les variables CI/CD disponibles](variables.md).
1. Sélectionnez **Générer un extrait de code**. Une boîte de dialogue s'ouvre avec l'extrait YAML correspondant aux options que vous avez sélectionnées dans le formulaire.
1. Effectuez l'une des opérations suivantes :
   1. Pour copier l'extrait dans votre presse-papiers, sélectionnez **Copier uniquement le code**.
   1. Pour ajouter l'extrait au fichier `.gitlab-ci.yml` de votre projet, sélectionnez **Copier le code et ouvrir le fichier `.gitlab-ci.yml`**. L'éditeur de pipeline s'ouvre.
      1. Collez l'extrait dans le fichier `.gitlab-ci.yml`.
      1. Sélectionnez l'onglet **Lint** pour confirmer que le fichier `.gitlab-ci.yml` modifié est valide.
      1. Sélectionnez l'onglet **Éditer**, puis sélectionnez **Valider les modifications**.

Lorsque l'extrait est validé dans le fichier `.gitlab-ci.yml`, les pipelines incluent un job de fuzzing d'API.

## Spécification OpenAPI {#openapi-specification}

La [spécification OpenAPI](https://www.openapis.org/) (anciennement la spécification Swagger) est un format de description d'API pour les API REST. Cette section vous montre comment configurer le fuzzing d'API en utilisant une spécification OpenAPI pour fournir des informations sur l'API cible à tester. Les spécifications OpenAPI sont fournies sous forme de ressource du système de fichiers ou d'URL. Les formats OpenAPI JSON et YAML sont tous deux pris en charge.

Le fuzzing d'API utilise un document OpenAPI pour générer le corps de la requête. Lorsqu'un corps de requête est requis, la génération du corps est limitée à ces types de corps :

- `application/x-www-form-urlencoded`
- `multipart/form-data`
- `application/json`
- `application/xml`

## OpenAPI et les types de médias {#openapi-and-media-types}

Un type de média (anciennement connu sous le nom de type MIME) est un identifiant pour les formats de fichiers et le contenu des formats transmis. Un document OpenAPI vous permet de spécifier qu'une opération donnée peut accepter différents types de médias, donc une requête donnée peut envoyer des données en utilisant différents contenus de fichiers. Par exemple, une opération `PUT /user` pour mettre à jour les données d'un utilisateur pourrait accepter des données au format XML (type de média `application/xml`) ou JSON (type de média `application/json`). OpenAPI 2.x vous permet de spécifier les types de médias acceptés globalement ou par opération, et OpenAPI 3.x vous permet de spécifier les types de médias acceptés par opération. Le fuzzing d'API vérifie les types de médias répertoriés et tente de produire des exemples de données pour chaque type de média pris en charge.

- Le comportement par défaut est de sélectionner l'un des types de médias pris en charge à utiliser. Le premier type de média pris en charge est choisi dans la liste. Ce comportement est configurable.

Tester la même opération (par exemple, `POST /user`) en utilisant différents types de médias (par exemple, `application/json` et `application/xml`) n'est pas toujours souhaitable. Par exemple, si l'application cible exécute le même code quel que soit le type de contenu de la requête, cela prend plus de temps pour terminer la session de test, et peut signaler des vulnérabilités en double liées au corps de la requête selon l'application cible.

La variable d'environnement `FUZZAPI_OPENAPI_ALL_MEDIA_TYPES` vous permet de spécifier si oui ou non utiliser tous les types de médias pris en charge au lieu d'un seul lors de la génération de requêtes pour une opération donnée. Lorsque la variable d'environnement `FUZZAPI_OPENAPI_ALL_MEDIA_TYPES` est définie sur n'importe quelle valeur, le fuzzing d'API tente de générer des requêtes pour tous les types de médias pris en charge au lieu d'un seul dans une opération donnée. Cela entraîne un allongement des tests car les tests sont répétés pour chaque type de média fourni.

Alternativement, la variable `FUZZAPI_OPENAPI_MEDIA_TYPES` est utilisée pour fournir une liste de types de médias dont chacun est testé. Fournir plus d'un type de média entraîne un allongement des tests, car les tests sont effectués pour chaque type de média sélectionné. Lorsque la variable d'environnement `FUZZAPI_OPENAPI_MEDIA_TYPES` est définie sur une liste de types de médias, seuls les types de médias répertoriés sont inclus lors de la création des requêtes.

Les types de médias multiples dans `FUZZAPI_OPENAPI_MEDIA_TYPES` doivent être séparés par un deux-points (`:`). Par exemple, pour limiter la génération de requêtes aux types de médias `application/x-www-form-urlencoded` et `multipart/form-data`, définissez la variable d'environnement `FUZZAPI_OPENAPI_MEDIA_TYPES` sur `application/x-www-form-urlencoded:multipart/form-data`. Seuls les types de médias pris en charge dans cette liste sont inclus lors de la création des requêtes, bien que les types de médias non pris en charge soient toujours ignorés. Un texte de type de média peut contenir différentes sections. Par exemple, `application/vnd.api+json; charset=UTF-8` est un composé de `type "/" [tree "."] subtype ["+" suffix]* [";" parameter]`. Les paramètres ne sont pas pris en compte lors du filtrage des types de médias lors de la génération des requêtes.

Les variables d'environnement `FUZZAPI_OPENAPI_ALL_MEDIA_TYPES` et `FUZZAPI_OPENAPI_MEDIA_TYPES` vous permettent de décider comment gérer les types de médias. Ces paramètres sont mutuellement exclusifs. Si les deux sont activés, le fuzzing d'API signale une erreur.

### Configurer le fuzzing d'API web avec une spécification OpenAPI {#configure-web-api-fuzzing-with-an-openapi-specification}

Pour configurer le fuzzing d'API dans GitLab avec une spécification OpenAPI :

1. Ajoutez l'étape `fuzz` à votre fichier `.gitlab-ci.yml`.
1. [Incluez](../../../../ci/yaml/_index.md#includetemplate) le [modèle `API-Fuzzing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml) dans votre fichier `.gitlab-ci.yml`.
1. Fournissez le profil en ajoutant la variable CI/CD `FUZZAPI_PROFILE` à votre fichier `.gitlab-ci.yml`. Le profil spécifie combien de tests sont exécutés. Remplacez `Quick-10` par le profil que vous choisissez. Pour plus de détails, consultez [les profils de fuzzing d'API](customizing_analyzer_settings.md#api-fuzzing-profiles).

   ```yaml
   variables:
     FUZZAPI_PROFILE: Quick-10
   ```

1. Fournissez l'emplacement de la spécification OpenAPI. Vous pouvez fournir la spécification sous forme de fichier ou d'URL. Spécifiez l'emplacement en ajoutant la variable `FUZZAPI_OPENAPI`.
1. Fournissez l'URL de base de l'instance d'API cible. Utilisez soit la variable `FUZZAPI_TARGET_URL`, soit un fichier `environment_url.txt`.

   L'ajout de l'URL dans un fichier `environment_url.txt` à la racine de votre projet est idéal pour les tests dans des environnements dynamiques. Pour exécuter le fuzzing d'API contre une application créée dynamiquement lors d'un pipeline CI/CD GitLab, demandez à l'application de conserver son URL dans un fichier `environment_url.txt`. Le fuzzing d'API analyse automatiquement ce fichier pour trouver sa cible d'analyse. Vous pouvez voir un exemple de cela dans le [YAML CI Auto DevOps](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml).

Exemple de fichier `.gitlab-ci.yml` utilisant une spécification OpenAPI :

   ```yaml
   stages:
     - fuzz

   include:
     - template: Security/API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
     FUZZAPI_OPENAPI: test-api-specification.json
     FUZZAPI_TARGET_URL: http://test-deployment/
   ```

Il s'agit d'une configuration minimale pour le fuzzing d'API. À partir de là, vous pouvez :

- [Exécuter votre première analyse](#running-your-first-scan).
- [Ajouter l'authentification](customizing_analyzer_settings.md#authentication).
- Apprendre à [gérer les faux positifs](#handling-false-positives).

Pour plus de détails sur les options de configuration du fuzzing d'API, consultez [les variables CI/CD disponibles](variables.md).

## Archive HTTP (HAR) {#http-archive-har}

Le [format d'archive HTTP (HAR)](http://www.softwareishard.com/blog/har-12-spec/) est un format de fichier d'archive pour la journalisation des transactions HTTP. Lorsqu'il est utilisé avec le fuzzer d'API GitLab, le fichier HAR doit contenir des enregistrements d'appels à l'API web à tester. Le fuzzer d'API extrait toutes les requêtes et les utilise pour effectuer les tests.

Pour plus de détails, notamment sur la façon de créer un fichier HAR, consultez [le format d'archive HTTP](../create_har_files.md).

> [!warning]
> Les fichiers HAR peuvent contenir des informations sensibles telles que des jetons d'authentification, des clés d'API et des cookies de session. Vous devez examiner le contenu du fichier HAR avant de l'ajouter à un dépôt.

### Configurer le fuzzing d'API web avec un fichier HAR {#configure-web-api-fuzzing-with-a-har-file}

Pour configurer le fuzzing d'API afin d'utiliser un fichier HAR :

1. Ajoutez l'étape `fuzz` à votre fichier `.gitlab-ci.yml`.
1. [Incluez](../../../../ci/yaml/_index.md#includetemplate) le [modèle `API-Fuzzing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml) dans votre fichier `.gitlab-ci.yml`.
1. Fournissez le profil en ajoutant la variable CI/CD `FUZZAPI_PROFILE` à votre fichier `.gitlab-ci.yml`. Le profil spécifie combien de tests sont exécutés. Remplacez `Quick-10` par le profil que vous choisissez. Pour plus de détails, consultez [les profils de fuzzing d'API](customizing_analyzer_settings.md#api-fuzzing-profiles).

   ```yaml
   variables:
     FUZZAPI_PROFILE: Quick-10
   ```

1. Fournissez l'emplacement de la spécification HAR. Vous pouvez fournir la spécification sous forme de fichier ou d'URL. Spécifiez l'emplacement en ajoutant la variable `FUZZAPI_HAR`.
1. L'URL de base de l'instance d'API cible est également requise. Fournissez-la en utilisant la variable `FUZZAPI_TARGET_URL` ou un fichier `environment_url.txt`.

   L'ajout de l'URL dans un fichier `environment_url.txt` à la racine de votre projet est idéal pour les tests dans des environnements dynamiques. Pour exécuter le fuzzing d'API contre une application créée dynamiquement lors d'un pipeline CI/CD GitLab, demandez à l'application de conserver son domaine dans un fichier `environment_url.txt`. Le fuzzing d'API analyse automatiquement ce fichier pour trouver sa cible d'analyse. Vous pouvez voir un [exemple de ceci dans le YAML CI Auto DevOps GitLab](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml).

Exemple de fichier `.gitlab-ci.yml` utilisant un fichier HAR :

   ```yaml
   stages:
     - fuzz

   include:
     - template: Security/API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
     FUZZAPI_HAR: test-api-recording.har
     FUZZAPI_TARGET_URL: http://test-deployment/
   ```

Cet exemple est une configuration minimale pour le fuzzing d'API. À partir de là, vous pouvez :

- [Exécuter votre première analyse](#running-your-first-scan).
- [Ajouter l'authentification](customizing_analyzer_settings.md#authentication).
- Apprendre à [gérer les faux positifs](#handling-false-positives).

Pour plus de détails sur les options de configuration du fuzzing d'API, consultez [les variables CI/CD disponibles](variables.md).

## Schéma GraphQL {#graphql-schema}

{{< history >}}

- La prise en charge du schéma GraphQL a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/352780) dans GitLab 15.4.

{{< /history >}}

GraphQL est un langage de requête pour votre API et une alternative aux API REST. Le fuzzing d'API prend en charge le test des points de terminaison GraphQL de plusieurs façons :

- Tester en utilisant le schéma GraphQL. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/352780) dans GitLab 15.4.
- Tester en utilisant un enregistrement (HAR) de requêtes GraphQL.
- Tester en utilisant une Postman Collection contenant des requêtes GraphQL.

Cette section documente comment tester en utilisant un schéma GraphQL. La prise en charge du schéma GraphQL dans le fuzzing d'API est capable d'interroger le schéma depuis des points de terminaison qui prennent en charge l'introspection. L'introspection est activée par défaut pour permettre à des outils tels que GraphiQL de fonctionner.

### Analyse du fuzzing d'API avec une URL de point de terminaison GraphQL {#api-fuzzing-scanning-with-a-graphql-endpoint-url}

La prise en charge de GraphQL dans le fuzzing d'API est capable d'interroger un point de terminaison GraphQL pour obtenir le schéma.

> [!note]
> Le point de terminaison GraphQL doit prendre en charge les requêtes d'introspection pour que cette méthode fonctionne correctement.

Pour configurer le fuzzing d'API afin d'utiliser une URL de point de terminaison GraphQL qui fournit des informations sur l'API cible à tester :

1. [Incluez](../../../../ci/yaml/_index.md#includetemplate) le [modèle `API-Fuzzing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml) dans votre fichier `.gitlab-ci.yml`.
1. Fournissez le chemin du point de terminaison GraphQL, par exemple `/api/graphql`. Spécifiez le chemin en ajoutant la variable `FUZZAPI_GRAPHQL`.
1. L'URL de base de l'instance d'API cible est également requise. Fournissez-la en utilisant la variable `FUZZAPI_TARGET_URL` ou un fichier `environment_url.txt`.

   L'ajout de l'URL dans un fichier `environment_url.txt` à la racine de votre projet est idéal pour les tests dans des environnements dynamiques. Pour plus d'informations, consultez [les solutions pour les environnements dynamiques](../troubleshooting.md#dynamic-environment-solutions).

Exemple complet de configuration utilisant une URL de point de terminaison GraphQL :

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

apifuzzer_fuzz:
  variables:
    FUZZAPI_GRAPHQL: /api/graphql
    FUZZAPI_TARGET_URL: http://test-deployment/
```

Cet exemple est une configuration minimale pour le fuzzing d'API. À partir de là, vous pouvez :

- [Exécuter votre première analyse](#running-your-first-scan).
- [Ajouter l'authentification](customizing_analyzer_settings.md#authentication).
- Apprendre à [gérer les faux positifs](#handling-false-positives).

### Fuzzing d'API avec un fichier de schéma GraphQL {#api-fuzzing-with-a-graphql-schema-file}

Le fuzzing d'API peut utiliser un fichier de schéma GraphQL pour comprendre et tester un point de terminaison GraphQL dont l'introspection est désactivée. Pour utiliser un fichier de schéma GraphQL, il doit être au format JSON d'introspection. Un schéma GraphQL peut être converti au format JSON d'introspection à l'aide d'un outil tiers en ligne : <https://transform.tools/graphql-to-introspection-json>.

Pour configurer le fuzzing d'API afin d'utiliser un fichier de schéma GraphQL qui fournit des informations sur l'API cible à tester :

1. [Incluez](../../../../ci/yaml/_index.md#includetemplate) le [modèle `API-Fuzzing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml) dans votre fichier `.gitlab-ci.yml`.
1. Fournissez le chemin du point de terminaison GraphQL, par exemple `/api/graphql`. Spécifiez le chemin en ajoutant la variable `FUZZAPI_GRAPHQL`.
1. Fournissez l'emplacement du fichier de schéma GraphQL. Vous pouvez fournir l'emplacement sous forme de chemin de fichier ou d'URL. Spécifiez l'emplacement en ajoutant la variable `FUZZAPI_GRAPHQL_SCHEMA`.
1. L'URL de base de l'instance d'API cible est également requise. Fournissez-la en utilisant la variable `FUZZAPI_TARGET_URL` ou un fichier `environment_url.txt`.

   L'ajout de l'URL dans un fichier `environment_url.txt` à la racine de votre projet est idéal pour les tests dans des environnements dynamiques. Pour plus d'informations, consultez [les solutions pour les environnements dynamiques](../troubleshooting.md#dynamic-environment-solutions).

Exemple complet de configuration utilisant un fichier de schéma GraphQL :

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

apifuzzer_fuzz:
  variables:
    FUZZAPI_GRAPHQL: /api/graphql
    FUZZAPI_GRAPHQL_SCHEMA: test-api-graphql.schema
    FUZZAPI_TARGET_URL: http://test-deployment/
```

Exemple complet de configuration utilisant une URL de fichier de schéma GraphQL :

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

apifuzzer_fuzz:
  variables:
    FUZZAPI_GRAPHQL: /api/graphql
    FUZZAPI_GRAPHQL_SCHEMA: http://file-store/files/test-api-graphql.schema
    FUZZAPI_TARGET_URL: http://test-deployment/
```

Cet exemple est une configuration minimale pour le fuzzing d'API. À partir de là, vous pouvez :

- [Exécuter votre première analyse](#running-your-first-scan).
- [Ajouter l'authentification](customizing_analyzer_settings.md#authentication).
- Apprendre à [gérer les faux positifs](#handling-false-positives).

## Postman Collection {#postman-collection}

Le [client API Postman](https://www.postman.com/product/api-client/) est un outil populaire que les développeurs et les testeurs utilisent pour appeler différents types d'API. Les définitions d'API [peuvent être exportées sous forme de fichier Postman Collection](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-collections) pour une utilisation avec le fuzzing d'API. Lors de l'exportation, assurez-vous de sélectionner une version prise en charge de Postman Collection : v2.0 ou v2.1.

Lorsqu'elles sont utilisées avec le fuzzer d'API GitLab, les Postman Collections doivent contenir des définitions de l'API web à tester avec des données valides. Le fuzzer d'API extrait toutes les définitions d'API et les utilise pour effectuer les tests.

> [!warning]
> Les fichiers Postman Collection peuvent contenir des informations sensibles telles que des jetons d'authentification, des clés d'API et des cookies de session. Vous devez examiner le contenu du fichier Postman Collection avant de l'ajouter à un dépôt.

### Configurer le fuzzing d'API web avec un fichier Postman Collection {#configure-web-api-fuzzing-with-a-postman-collection-file}

Pour configurer le fuzzing d'API afin d'utiliser un fichier Postman Collection :

1. Ajoutez l'étape `fuzz` à votre fichier `.gitlab-ci.yml`.
1. [Incluez](../../../../ci/yaml/_index.md#includetemplate) le [modèle `API-Fuzzing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml) dans votre fichier `.gitlab-ci.yml`.
1. Fournissez le profil en ajoutant la variable CI/CD `FUZZAPI_PROFILE` à votre fichier `.gitlab-ci.yml`. Le profil spécifie combien de tests sont exécutés. Remplacez `Quick-10` par le profil que vous choisissez. Pour plus de détails, consultez [les profils de fuzzing d'API](customizing_analyzer_settings.md#api-fuzzing-profiles).

   ```yaml
   variables:
     FUZZAPI_PROFILE: Quick-10
   ```

1. Fournissez l'emplacement de la spécification Postman Collection. Vous pouvez fournir la spécification sous forme de fichier ou d'URL. Spécifiez l'emplacement en ajoutant la variable `FUZZAPI_POSTMAN_COLLECTION`.
1. Fournissez l'URL de base de l'instance d'API cible. Utilisez soit la variable `FUZZAPI_TARGET_URL`, soit un fichier `environment_url.txt`.

   L'ajout de l'URL dans un fichier `environment_url.txt` à la racine de votre projet est idéal pour les tests dans des environnements dynamiques. Pour exécuter le fuzzing d'API contre une application créée dynamiquement lors d'un pipeline CI/CD GitLab, demandez à l'application de conserver son domaine dans un fichier `environment_url.txt`. Le fuzzing d'API analyse automatiquement ce fichier pour trouver sa cible d'analyse. Vous pouvez voir un exemple de cela dans le [YAML CI Auto DevOps GitLab](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml).

Exemple de fichier `.gitlab-ci.yml` utilisant un fichier Postman Collection :

   ```yaml
   stages:
     - fuzz

   include:
     - template: Security/API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
     FUZZAPI_POSTMAN_COLLECTION: postman-collection_serviceA.json
     FUZZAPI_TARGET_URL: http://test-deployment/
   ```

Il s'agit d'une configuration minimale pour le fuzzing d'API. À partir de là, vous pouvez :

- [Exécuter votre première analyse](#running-your-first-scan).
- [Ajouter l'authentification](customizing_analyzer_settings.md#authentication).
- Apprendre à [gérer les faux positifs](#handling-false-positives).

Pour plus de détails sur les options de configuration du fuzzing d'API, consultez [les variables CI/CD disponibles](variables.md).

### Variables Postman {#postman-variables}

{{< history >}}

- La prise en charge du format de fichier d'environnement Postman a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/356312) dans GitLab 15.1.
- La prise en charge de plusieurs fichiers de variables a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/356312) dans GitLab 15.1.
- La prise en charge des portées de variables Postman : globale et d'environnement a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/356312) dans GitLab 15.1.

{{< /history >}}

#### Variables dans le client Postman {#variables-in-postman-client}

Postman permet au développeur de définir des espaces réservés qui peuvent être utilisés dans différentes parties des requêtes. Ces espaces réservés sont appelés variables, comme expliqué dans [l'utilisation des variables](https://learning.postman.com/docs/sending-requests/variables/variables/). Vous pouvez utiliser des variables pour stocker et réutiliser des valeurs dans vos requêtes et vos scripts. Par exemple, vous pouvez modifier la collection pour ajouter des variables au document :

![Vue de l'onglet des variables de la collection modifiée](img/api_fuzzing_postman_collection_edit_variable_v18_5.png)

Ou bien, vous pouvez ajouter des variables dans un environnement :

![Vue de modification des variables d'environnement](img/api_fuzzing_postman_environment_edit_variable_v18_5.png)

Vous pouvez ensuite utiliser les variables dans des sections telles que l'URL, les en-têtes et autres :

![Vue de modification de la requête à l'aide des variables](img/api_fuzzing_postman_request_edit_v18_5.png)

Postman est passé d'un outil client de base avec une belle expérience UX à un écosystème plus complexe qui permet de tester les API avec des scripts, de créer des collections complexes qui déclenchent des requêtes secondaires, et de définir des variables au fil du parcours. Toutes les fonctionnalités de l'écosystème Postman ne sont pas prises en charge. Par exemple, les scripts ne sont pas pris en charge. L'objectif principal de la prise en charge de Postman est d'ingérer les définitions de Postman Collection utilisées par le client Postman et leurs variables associées définies dans l'espace de travail, les environnements et les collections elles-mêmes.

Postman permet de créer des variables dans différentes portées. Chaque portée a un niveau de visibilité différent dans les outils Postman. Par exemple, vous pouvez créer une variable dans une portée d'environnement global qui est visible par chaque définition d'opération et espace de travail. Vous pouvez également créer une variable dans une portée d'environnement spécifique qui n'est visible et utilisée que lorsque cet environnement spécifique est sélectionné. Certaines portées ne sont pas toujours disponibles, par exemple dans l'écosystème Postman, vous pouvez créer des requêtes dans le client Postman ; ces requêtes n'ont pas de portée locale, mais les scripts de test en ont une.

Les portées de variables dans Postman peuvent être un sujet intimidant et tout le monde n'en est pas familier. Lisez [les portées de variables](https://learning.postman.com/docs/sending-requests/variables/variables/#variable-scopes) dans la documentation Postman avant de continuer.

Comme mentionné précédemment, il existe différentes portées de variables, et chacune a un but et peut être utilisée pour apporter plus de flexibilité à votre document Postman. Il y a une note importante sur la façon dont les valeurs des variables sont calculées, selon la documentation Postman :

> [!note]
> Si une variable avec le même nom est déclarée dans deux portées différentes, la valeur stockée dans la variable avec la portée la plus étroite est utilisée. Par exemple, s'il existe une variable globale nommée `username` et une variable locale nommée `username`, la valeur locale est utilisée lors de l'exécution de la requête.

Voici un résumé des portées de variables prises en charge par le client Postman et le fuzzing d'API :

- **Portée d'environnement global (global)** est un environnement prédéfini spécial disponible dans tout un espace de travail. La portée de l'environnement global peut également être appelée la portée globale. Le client Postman permet d'exporter l'environnement global dans un fichier JSON, qui peut être utilisé avec le fuzzing d'API.
- **Portée de l'environnement** est un groupe nommé de variables créé par un utilisateur dans le client Postman. Le client Postman prend en charge un seul environnement actif ainsi que l'environnement global. Les variables définies dans un environnement actif créé par l'utilisateur ont priorité sur les variables définies dans l'environnement global. Le client Postman permet d'exporter votre environnement dans un fichier JSON, qui peut être utilisé avec le fuzzing d'API.
- **Portée de collection** est un groupe de variables déclarées dans une collection donnée. Les variables de collection sont disponibles pour la collection dans laquelle elles ont été déclarées ainsi que pour les requêtes ou collections imbriquées. Les variables définies dans la portée de collection ont priorité sur la portée de l'environnement global ainsi que sur la portée d'environnement. Le client Postman peut exporter une ou plusieurs collections dans un fichier JSON ; ce fichier JSON contient les collections, les requêtes et les variables de collection sélectionnées.
- **Portée de fuzzing d'API** est une nouvelle portée ajoutée par le fuzzing d'API pour permettre aux utilisateurs de fournir des variables supplémentaires ou de remplacer des variables définies dans d'autres portées prises en charge. Cette portée n'est pas prise en charge par Postman. Les variables de la portée de fuzzing d'API sont fournies à l'aide d'un [format de fichier JSON personnalisé](#api-fuzzing-scope-custom-json-file-format).
  - Remplacer les valeurs définies dans l'environnement ou la collection
  - Définir des variables à partir de scripts
  - Définir une seule ligne de données à partir de la _portée de données_ non prise en charge
- **Portée de données** est un groupe de variables dont les noms et les valeurs proviennent de fichiers JSON ou CSV. Un exécuteur de collection Postman tel que [Newman](https://learning.postman.com/docs/collections/using-newman-cli/command-line-integration-with-newman/) ou [Postman Collection Runner](https://learning.postman.com/docs/collections/running-collections/intro-to-collection-runs/) exécute les requêtes d'une collection autant de fois qu'il y a d'entrées dans le fichier JSON ou CSV. Un bon cas d'utilisation pour ces variables est d'automatiser les tests à l'aide de scripts dans Postman. Le fuzzing d'API ne prend pas en charge la lecture de données depuis un fichier CSV ou JSON.
- **Portée locale** regroupe les variables définies dans les scripts Postman. Le fuzzing d'API ne prend pas en charge les scripts Postman et, par extension, les variables définies dans les scripts. Vous pouvez toujours fournir des valeurs pour les variables définies dans les scripts en les définissant dans l'une des portées prises en charge ou dans le format JSON personnalisé.

Toutes les portées ne sont pas prises en charge par le fuzzing d'API et les variables définies dans les scripts ne sont pas prises en charge. Le tableau suivant est trié de la portée la plus large à la plus étroite.

| Portée              | Postman   | Fuzzing d'API | Commentaire |
| ------------------ |:---------:|:-----------:| :-------|
| Environnement global | Oui       | Oui         | Environnement prédéfini spécial |
| Environnement        | Oui       | Oui         | Environnements nommés |
| Collection         | Oui       | Oui         | Défini dans votre collection Postman |
| Portée du fuzzing d'API  | Non        | Oui         | Portée personnalisée ajoutée par le fuzzing d'API |
| Données               | Oui       | Non          | Fichiers externes au format CSV ou JSON |
| Local              | Oui       | Non          | Variables définies dans les scripts |

Pour plus de détails sur la façon de définir et d'exporter des variables dans différentes portées, consultez :

- [Définir des variables de collection](https://learning.postman.com/docs/sending-requests/variables/variables/#defining-collection-variables)
- [Définir des variables d'environnement](https://learning.postman.com/docs/sending-requests/variables/variables/#defining-environment-variables)
- [Définir des variables globales](https://learning.postman.com/docs/sending-requests/variables/variables/#defining-global-variables)

#### Exportation depuis le client Postman {#exporting-from-postman-client}

Le client Postman vous permet d'exporter différents formats de fichiers, par exemple, vous pouvez exporter une collection Postman ou un environnement Postman. L'environnement exporté peut être l'environnement global (qui est toujours disponible) ou n'importe quel environnement personnalisé que vous avez créé précédemment. Lorsque vous exportez une Postman Collection, elle peut contenir uniquement des déclarations pour les variables de portée de collection et locale ; les variables de portée d'environnement ne sont pas incluses.

Pour obtenir la déclaration des variables de portée d'environnement, vous devez exporter un environnement donné au moment voulu. Chaque fichier exporté inclut uniquement les variables de l'environnement sélectionné.

Pour plus de détails sur l'exportation des variables dans différentes portées prises en charge, consultez :

- [Exporter les collections](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-collections)
- [Exporter les environnements](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)
- [Télécharger les environnements globaux](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)

#### Portée du fuzzing d'API, format de fichier JSON personnalisé {#api-fuzzing-scope-custom-json-file-format}

Le format de fichier JSON personnalisé est un objet JSON où chaque propriété d'objet représente un nom de variable et la valeur de la propriété représente la valeur de la variable. Ce fichier peut être créé à l'aide de votre éditeur de texte préféré, ou il peut être produit par un job antérieur dans votre pipeline.

Cet exemple définit deux variables `base_url` et `token` dans la portée du fuzzing d'API :

```json
{
  "base_url": "http://127.0.0.1/",
  "token": "Token 84816165151"
}
```

#### Utilisation des portées avec le fuzzing d'API {#using-scopes-with-api-fuzzing}

Les portées : globale, d'environnement, de collection et GitLab API fuzzing sont prises en charge dans [GitLab 15.1 et versions ultérieures](https://gitlab.com/gitlab-org/gitlab/-/issues/356312). GitLab 15.0 et versions antérieures ne prennent en charge que les portées de collection et de fuzzing d'API GitLab.

Le tableau suivant fournit une référence rapide pour mapper les fichiers/URL de portée aux variables de configuration du fuzzing d'API :

| Portée              |  Comment fournir |
| ------------------ | --------------- |
| Environnement global | FUZZAPI_POSTMAN_COLLECTION_VARIABLES |
| Environnement        | FUZZAPI_POSTMAN_COLLECTION_VARIABLES |
| Collection         | FUZZAPI_POSTMAN_COLLECTION           |
| Portée du fuzzing d'API  | FUZZAPI_POSTMAN_COLLECTION_VARIABLES |
| Données               | Non pris en charge   |
| Local              | Non pris en charge   |

Le document Postman Collection inclut automatiquement toutes les variables de portée de collection. La Postman Collection est fournie avec la variable de configuration `FUZZAPI_POSTMAN_COLLECTION`. Cette variable peut être définie sur une seule [Postman Collection exportée](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-collections).

Les variables des autres portées sont fournies via la variable de configuration `FUZZAPI_POSTMAN_COLLECTION_VARIABLES`. La variable de configuration prend en charge une liste de fichiers délimitée par une virgule (`,`) dans [GitLab 15.1 et versions ultérieures](https://gitlab.com/gitlab-org/gitlab/-/issues/356312). GitLab 15.0 et versions antérieures ne prennent en charge qu'un seul fichier. L'ordre des fichiers fournis n'est pas important car les fichiers fournissent les informations de portée nécessaires.

La variable de configuration `FUZZAPI_POSTMAN_COLLECTION_VARIABLES` peut être définie sur :

- [Environnement global exporté](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)
- [Environnements exportés](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)
- [Format JSON personnalisé du fuzzing d'API](#api-fuzzing-scope-custom-json-file-format)

#### Variables Postman non définies {#undefined-postman-variables}

Il est possible que le moteur de fuzzing d'API ne trouve pas toutes les références de variables utilisées par votre fichier Postman Collection. Certains cas peuvent être :

- Vous utilisez des variables de portée de données ou locale, et comme indiqué précédemment, ces portées ne sont pas prises en charge par le fuzzing d'API. Ainsi, en supposant que les valeurs de ces variables n'ont pas été fournies via [la portée du fuzzing d'API](#api-fuzzing-scope-custom-json-file-format), alors les valeurs des variables de portée de données et locale sont indéfinies.
- Un nom de variable a été saisi incorrectement et le nom ne correspond pas à la variable définie.
- Le client Postman prend en charge une nouvelle variable dynamique qui n'est pas prise en charge par le fuzzing d'API.

Dans la mesure du possible, le fuzzing d'API adopte le même comportement que le client Postman lorsqu'il traite des variables indéfinies. Le texte de la référence de variable reste identique et il n'y a pas de substitution de texte. Le même comportement s'applique également à toutes les variables dynamiques non prises en charge.

Par exemple, si une définition de requête dans la Postman Collection référence la variable `{{full_url}}` et que la variable n'est pas trouvée, elle reste inchangée avec la valeur `{{full_url}}`.

#### Variables Postman dynamiques {#dynamic-postman-variables}

En plus des variables qu'un utilisateur peut définir à différents niveaux de portée, Postman dispose d'un ensemble de variables prédéfinies appelées variables dynamiques. Les [variables dynamiques](https://learning.postman.com/docs/tests-and-scripts/write-scripts/variables-list/) sont déjà définies et leur nom est précédé d'un signe dollar (`$`), par exemple, `$guid`. Les variables dynamiques peuvent être utilisées comme n'importe quelle autre variable et, dans le client Postman, elles produisent des valeurs aléatoires lors de l'exécution de la requête ou de la collection.

Une différence importante entre le fuzzing d'API et Postman est que le fuzzing d'API retourne la même valeur pour chaque utilisation des mêmes variables dynamiques. Cela diffère du comportement du client Postman qui retourne une valeur aléatoire à chaque utilisation de la même variable dynamique. En d'autres termes, le fuzzing d'API utilise des valeurs statiques pour les variables dynamiques tandis que Postman utilise des valeurs aléatoires.

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

Dans cet exemple, [la portée globale est exportée](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments) depuis le client Postman sous le nom `global-scope.json` et fournie au fuzzing d'API via la variable de configuration `FUZZAPI_POSTMAN_COLLECTION_VARIABLES`.

Voici un exemple d'utilisation de `FUZZAPI_POSTMAN_COLLECTION_VARIABLES` :

```yaml
stages:
     - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick-10
  FUZZAPI_POSTMAN_COLLECTION: postman-collection.json
  FUZZAPI_POSTMAN_COLLECTION_VARIABLES: global-scope.json
  FUZZAPI_TARGET_URL: http://test-deployment/
```

#### Exemple : Portée d'environnement {#example-environment-scope}

Dans cet exemple, [la portée d'environnement est exportée](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments) depuis le client Postman sous le nom `environment-scope.json` et fournie au fuzzing d'API via la variable de configuration `FUZZAPI_POSTMAN_COLLECTION_VARIABLES`.

Voici un exemple d'utilisation de `FUZZAPI_POSTMAN_COLLECTION_VARIABLES` :

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_POSTMAN_COLLECTION: postman-collection.json
  FUZZAPI_POSTMAN_COLLECTION_VARIABLES: environment-scope.json
  FUZZAPI_TARGET_URL: http://test-deployment/
```

#### Exemple : Portée de collection {#example-collection-scope}

Les variables de portée de collection sont incluses dans le fichier Postman Collection exporté et fournies via la variable de configuration `FUZZAPI_POSTMAN_COLLECTION`.

Voici un exemple d'utilisation de `FUZZAPI_POSTMAN_COLLECTION` :

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_POSTMAN_COLLECTION: postman-collection.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_POSTMAN_COLLECTION_VARIABLES: variable-collection-dictionary.json
```

#### Exemple : Portée du fuzzing d'API {#example-api-fuzzing-scope}

La portée du fuzzing d'API est utilisée à deux fins principales : définir des variables de portée _données_ et _locale_ qui ne sont pas prises en charge par le fuzzing d'API, et modifier la valeur d'une variable existante définie dans une autre portée. La portée du fuzzing d'API est fournie via la variable de configuration `FUZZAPI_POSTMAN_COLLECTION_VARIABLES`.

Voici un exemple d'utilisation de `FUZZAPI_POSTMAN_COLLECTION_VARIABLES` :

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_POSTMAN_COLLECTION: postman-collection.json
  FUZZAPI_POSTMAN_COLLECTION_VARIABLES: api-fuzzing-scope.json
  FUZZAPI_TARGET_URL: http://test-deployment/
```

Le fichier `api-fuzzing-scope.json` utilise le [format de fichier JSON personnalisé](#api-fuzzing-scope-custom-json-file-format) du fuzzing d'API. Ce JSON est un objet avec des paires clé-valeur pour les propriétés. Les clés sont les noms des variables, et les valeurs sont les valeurs des variables. Par exemple :

```json
{
  "base_url": "http://127.0.0.1/",
  "token": "Token 84816165151"
}
```

#### Exemple : Portées multiples {#example-multiple-scopes}

Dans cet exemple, une portée globale, une portée d'environnement et une portée de collection sont configurées. La première étape consiste à exporter les différentes portées.

- [Exporter la portée globale](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments) sous le nom `global-scope.json`
- [Exporter la portée d'environnement](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments) sous le nom `environment-scope.json`
- Exporter la Postman Collection qui inclut la portée de _collection_ sous le nom `postman-collection.json`

La Postman Collection est fournie à l'aide de la variable `FUZZAPI_POSTMAN_COLLECTION`, tandis que les autres portées sont fournies à l'aide de la variable `FUZZAPI_POSTMAN_COLLECTION_VARIABLES`. Le fuzzing d'API peut identifier quelle portée correspond aux fichiers fournis en utilisant les données contenues dans chaque fichier.

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_POSTMAN_COLLECTION: postman-collection.json
  FUZZAPI_POSTMAN_COLLECTION_VARIABLES: global-scope.json,environment-scope.json
  FUZZAPI_TARGET_URL: http://test-deployment/
```

#### Exemple : Modification de la valeur d'une variable {#example-changing-variables-value}

Lors de l'utilisation de portées exportées, il est souvent nécessaire de modifier la valeur d'une variable pour l'utiliser avec le fuzzing d'API. Par exemple, une variable de portée de _collection_ pourrait contenir une variable nommée `api_version` avec une valeur de `v2`, tandis que votre test nécessite une valeur de `v1`. Au lieu de modifier la collection exportée pour changer la valeur, la portée du fuzzing d'API peut être utilisée pour changer sa valeur. Cela fonctionne car la portée du fuzzing d'API a priorité sur toutes les autres portées.

Les variables de portée de collection sont incluses dans le fichier Postman Collection exporté et fournies via la variable de configuration `FUZZAPI_POSTMAN_COLLECTION`.

La portée du fuzzing d'API est fournie via la variable de configuration `FUZZAPI_POSTMAN_COLLECTION_VARIABLES`, mais vous devez d'abord créer le fichier. Le fichier `api-fuzzing-scope.json` utilise le [format de fichier JSON personnalisé](#api-fuzzing-scope-custom-json-file-format) du fuzzing d'API. Ce JSON est un objet avec des paires clé-valeur pour les propriétés. Les clés sont les noms des variables, et les valeurs sont les valeurs des variables. Par exemple :

```json
{
  "api_version": "v1"
}
```

La définition CI :

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_POSTMAN_COLLECTION: postman-collection.json
  FUZZAPI_POSTMAN_COLLECTION_VARIABLES: api-fuzzing-scope.json
  FUZZAPI_TARGET_URL: http://test-deployment/
```

#### Exemple : Modification de la valeur d'une variable avec plusieurs portées {#example-changing-a-variables-value-with-multiple-scopes}

Lors de l'utilisation de portées exportées, il est souvent nécessaire de modifier la valeur d'une variable pour l'utiliser avec le fuzzing d'API. Par exemple, une portée d'environnement pourrait contenir une variable nommée `api_version` avec une valeur de `v2`, tandis que votre test nécessite une valeur de `v1`. Au lieu de modifier le fichier exporté pour changer la valeur, la portée du fuzzing d'API peut être utilisée. Cela fonctionne car la portée du fuzzing d'API a priorité sur toutes les autres portées.

Dans cet exemple, une portée globale, une portée d'environnement, une portée de collection et une portée de fuzzing d'API sont configurées. La première étape consiste à exporter et créer vos différentes portées.

- [Exporter la portée globale](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments) sous le nom `global-scope.json`
- [Exporter la portée d'environnement](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments) sous le nom `environment-scope.json`
- Exporter la Postman Collection qui inclut la portée de collection sous le nom `postman-collection.json`

La portée du fuzzing d'API est utilisée en créant un fichier `api-fuzzing-scope.json` à l'aide du [format de fichier JSON personnalisé](#api-fuzzing-scope-custom-json-file-format) du fuzzing d'API. Ce JSON est un objet avec des paires clé-valeur pour les propriétés. Les clés sont les noms des variables, et les valeurs sont les valeurs des variables. Par exemple :

```json
{
  "api_version": "v1"
}
```

La Postman Collection est fournie à l'aide de la variable `FUZZAPI_POSTMAN_COLLECTION`, tandis que les autres portées sont fournies à l'aide de la variable `FUZZAPI_POSTMAN_COLLECTION_VARIABLES`. Le fuzzing d'API peut identifier quelle portée correspond aux fichiers fournis en utilisant les données contenues dans chaque fichier.

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_POSTMAN_COLLECTION: postman-collection.json
  FUZZAPI_POSTMAN_COLLECTION_VARIABLES: global-scope.json,environment-scope.json,api-fuzzing-scope.json
  FUZZAPI_TARGET_URL: http://test-deployment/
```

## Exécution de votre première analyse {#running-your-first-scan}

Lorsqu'il est correctement configuré, un pipeline CI/CD contient une étape `fuzz` et un job `apifuzzer_fuzz` ou `apifuzzer_fuzz_dnd`. Le job échoue uniquement lorsqu'une configuration invalide est fournie. En fonctionnement normal, le job réussit toujours, même si des défauts sont identifiés lors des tests de fuzzing.

Les défauts sont affichés dans l'onglet du pipeline **Sécurité** avec le nom de la suite. Lors des tests sur la branche par défaut des dépôts, les défauts de fuzzing sont également affichés dans le rapport de vulnérabilités de sécurité et conformité.

Pour éviter un nombre excessif de défauts signalés, le scanner de fuzzing d'API limite le nombre de défauts qu'il signale.

## Affichage des défauts de fuzzing {#viewing-fuzzing-faults}

L'analyseur de fuzzing d'API produit un rapport JSON qui est collecté et utilisé [pour renseigner les défauts dans les écrans de vulnérabilité GitLab](#view-details-of-an-api-fuzzing-vulnerability). Les défauts de fuzzing apparaissent comme des vulnérabilités avec une gravité Inconnue.

Les défauts que le fuzzing d'API trouve nécessitent une investigation manuelle et ne sont pas associés à un type de vulnérabilité spécifique. Ils nécessitent une investigation pour déterminer s'ils constituent un problème de sécurité et s'ils doivent être corrigés. Consultez [la gestion des faux positifs](#handling-false-positives) pour obtenir des informations sur les modifications de configuration que vous pouvez apporter pour limiter le nombre de faux positifs signalés.

### Afficher les détails d'une vulnérabilité de fuzzing d'API {#view-details-of-an-api-fuzzing-vulnerability}

Les défauts détectés par le fuzzing d'API se produisent dans l'application web en direct et nécessitent une investigation manuelle pour déterminer s'il s'agit de vulnérabilités. Les défauts de fuzzing sont inclus comme vulnérabilités avec une gravité Inconnue. Pour faciliter l'investigation des défauts de fuzzing, des informations détaillées sont fournies sur les messages HTTP envoyés et reçus ainsi qu'une description des modifications effectuées.

Suivez ces étapes pour afficher les détails d'un défaut de fuzzing :

1. Vous pouvez afficher les défauts dans un projet ou dans un merge request :

   - Dans un projet, accédez à la page **Sécurisation** > **Rapport de vulnérabilités** du projet. Cette page affiche toutes les vulnérabilités de la branche par défaut uniquement.
   - Dans un merge request, accédez à la section **Sécurité** du merge request et sélectionnez le bouton **Étendre**. Les défauts de fuzzing d'API sont disponibles dans une section intitulée **Le test de fuzzing de l'API a détecté N vulnérabilités potentielles**. Sélectionnez le titre pour afficher les détails du défaut.

1. Sélectionnez le titre du défaut pour afficher les détails du défaut. Le tableau ci-dessous décrit ces détails.

   | Champ               | Description                                                                             |
   |:--------------------|:----------------------------------------------------------------------------------------|
   | Description         | Description du défaut, notamment ce qui a été modifié.                                   |
   | Projet             | Espace de nommage et projet dans lequel la vulnérabilité a été détectée.                          |
   | Méthode              | Méthode HTTP utilisée pour détecter la vulnérabilité.                                           |
   | URL                 | URL à laquelle la vulnérabilité a été détectée.                                            |
   | Requête             | La requête HTTP qui a causé le défaut.                                                 |
   | Réponse non modifiée | Réponse d'une requête non modifiée. Une réponse de travail typique ressemble à une réponse non modifiée. |
   | Réponse réelle     | Réponse reçue de la requête fuzzée.                                                  |
   | Preuve            | Comment GitLab a déterminé qu'un défaut s'est produit.                                                 |
   | Identifiants         | La vérification de fuzzing utilisée pour trouver ce défaut.                                              |
   | Gravité            | La gravité du résultat est toujours Inconnue.                                              |
   | Type de scanner        | Scanner utilisé pour effectuer les tests.                                                        |

### Tableau de bord de sécurité {#security-dashboard}

Les défauts de fuzzing apparaissent comme des vulnérabilités avec une gravité Inconnue. Le tableau de bord de sécurité est un bon endroit pour obtenir une vue d'ensemble de toutes les vulnérabilités de sécurité dans vos groupes, projets et pipelines. Pour plus d'informations, consultez la [documentation du tableau de bord de sécurité](../../security_dashboard/_index.md).

### Interaction avec les vulnérabilités {#interacting-with-the-vulnerabilities}

Les défauts de fuzzing apparaissent comme des vulnérabilités avec une gravité Inconnue. Après la détection d'un défaut, vous pouvez interagir avec lui. En savoir plus sur la façon de [traiter les vulnérabilités](../../vulnerabilities/_index.md).

## Gestion des faux positifs {#handling-false-positives}

Les faux positifs peuvent être gérés de deux façons :

- Désactivez la vérification qui produit le faux positif. Cela empêche la vérification de générer des défauts. Des exemples de vérifications sont `JSONFuzzingCheck` et `FormBodyFuzzingCheck`.
- Les vérifications de fuzzing disposent de plusieurs méthodes pour détecter quand un défaut est identifié, appelées « assertions ». Les assertions peuvent également être désactivées et configurées. Par exemple, le fuzzer d'API utilise par défaut les codes d'état HTTP pour aider à identifier quand quelque chose est un vrai problème. Si une API retourne une erreur 500 lors des tests, cela crée un défaut. Ce n'est pas toujours souhaitable, car certains frameworks retournent souvent des erreurs 500.

### Désactiver une vérification {#turn-off-a-check}

Les vérifications effectuent des tests d'un type spécifique et peuvent être activées et désactivées pour des profils de configuration spécifiques. Le fichier de configuration par défaut définit plusieurs profils que vous pouvez utiliser. La définition du profil dans le fichier de configuration liste toutes les vérifications qui sont actives lors d'une analyse. Pour désactiver une vérification spécifique, supprimez-la de la définition du profil dans le fichier de configuration. Les profils sont définis dans la section `Profiles` du fichier de configuration.

Exemple de définition de profil :

```yaml
Profiles:
  - Name: Quick-10
    DefaultProfile: Quick
    Routes:
      - Route: *Route0
        Checks:
          - Name: FormBodyFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
          - Name: GeneralFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
          - Name: JsonFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
          - Name: XmlFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
```

Pour désactiver la vérification `GeneralFuzzingCheck`, vous pouvez supprimer ces lignes :

```yaml
- Name: GeneralFuzzingCheck
  Configuration:
    FuzzingCount: 10
    UnicodeFuzzing: true
```

Cela donne le YAML suivant :

```yaml
- Name: Quick-10
  DefaultProfile: Quick
  Routes:
    - Route: *Route0
      Checks:
        - Name: FormBodyFuzzingCheck
          Configuration:
            FuzzingCount: 10
            UnicodeFuzzing: true
        - Name: JsonFuzzingCheck
          Configuration:
            FuzzingCount: 10
            UnicodeFuzzing: true
        - Name: XmlFuzzingCheck
          Configuration:
            FuzzingCount: 10
            UnicodeFuzzing: true
```

### Désactiver une assertion pour une vérification {#turn-off-an-assertion-for-a-check}

Les assertions détectent les défauts dans les tests produits par les vérifications. De nombreuses vérifications prennent en charge plusieurs assertions telles que l'analyse des journaux, l'analyse des réponses et le code d'état. Lorsqu'un défaut est trouvé, l'assertion utilisée est fournie. Pour identifier les assertions activées par défaut, consultez la configuration par défaut des vérifications dans le fichier de configuration. La section s'appelle `Checks`.

Cet exemple montre la vérification `FormBodyFuzzingCheck` :

```yaml
Checks:
  - Name: FormBodyFuzzingCheck
    Configuration:
      FuzzingCount: 30
      UnicodeFuzzing: true
    Assertions:
      - Name: LogAnalysisAssertion
      - Name: ResponseAnalysisAssertion
      - Name: StatusCodeAssertion
```

Vous pouvez voir que trois assertions sont activées par défaut. Une source courante de faux positifs est `StatusCodeAssertion`. Pour la désactiver, modifiez sa configuration dans la section `Profiles`. Cet exemple ne fournit que les deux autres assertions (`LogAnalysisAssertion`, `ResponseAnalysisAssertion`). Cela empêche `FormBodyFuzzingCheck` d'utiliser `StatusCodeAssertion` :

```yaml
Profiles:
  - Name: Quick-10
    DefaultProfile: Quick
    Routes:
      - Route: *Route0
        Checks:
          - Name: FormBodyFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
            Assertions:
              - Name: LogAnalysisAssertion
              - Name: ResponseAnalysisAssertion
          - Name: GeneralFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
          - Name: JsonFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
          - Name: XmlInjectionCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
```
