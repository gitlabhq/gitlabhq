---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Dépannage des jobs de fuzzing d'API"
---

## Le job de fuzzing d'API expire après N heures {#api-fuzzing-job-times-out-after-n-hours}

Pour les dépôts plus volumineux, le job de fuzzing d'API pourrait expirer sur le [runner hébergé de petite taille sur Linux](../../../ci/runners/hosted_runners/linux.md#machine-types-available-for-linux---x86-64), qui est défini par défaut. Si cela se produit dans vos jobs, vous devriez passer à un [runner plus grand](performance.md#using-a-larger-runner).

Consultez les sections de documentation suivantes pour obtenir de l'aide :

- [Optimisation des performances et vitesse des tests](performance.md)
- [Utilisation d'un runner plus grand](performance.md#using-a-larger-runner)
- [Exclusion des opérations par chemin](configuration/customizing_analyzer_settings.md#exclude-paths)
- [Exclusion des opérations lentes](performance.md#excluding-slow-operations)

## Le job de fuzzing d'API prend trop de temps à se terminer {#api-fuzzing-job-takes-too-long-to-complete}

Voir [l'optimisation des performances et la vitesse des tests](performance.md)

## Erreur : `Error waiting for API fuzzing 'http://127.0.0.1:5000' to become available` {#error-error-waiting-for-api-fuzzing-http1270015000-to-become-available}

Un bogue existe dans les versions de l'analyseur de fuzzing d'API antérieures à la v1.6.196 qui peut provoquer l'échec d'un processus d'arrière-plan dans certaines conditions. La solution consiste à mettre à jour vers une version plus récente de l'analyseur de fuzzing d'API.

Les informations de version se trouvent dans les détails du job `apifuzzer_fuzz`.

Si le problème se produit avec les versions v1.6.196 ou supérieures, contactez le support et fournissez les informations suivantes :

1. Référencez cette section de dépannage et demandez que le problème soit transmis à l'équipe d'analyse dynamique.
1. La sortie complète de la console du job.
1. Le fichier `gl-api-security-scanner.log` disponible en tant qu'artefact de job. Dans le panneau de droite de la page de détails du job, sélectionnez le bouton **Parcourir**.
1. La définition du job `apifuzzer_fuzz` de votre fichier `.gitlab-ci.yml`.

**Error message**

- Dans [GitLab 15.6 et versions ultérieures](https://gitlab.com/gitlab-org/gitlab/-/issues/376078), `Error waiting for API Fuzzing 'http://127.0.0.1:5000' to become available`
- Dans GitLab 15.5 et versions antérieures, `Error waiting for API Security 'http://127.0.0.1:5000' to become available`.

### `Failed to start session with scanner. Please retry, and if the problem persists reach out to support.` {#failed-to-start-session-with-scanner-please-retry-and-if-the-problem-persists-reach-out-to-support}

Le moteur de fuzzing d'API génère un message d'erreur lorsqu'il ne peut pas établir une connexion avec le composant d'application du scanner. Le message d'erreur est affiché dans la fenêtre de sortie du job `apifuzzer_fuzz`. Une cause fréquente de ce problème est que le composant d'arrière-plan ne peut pas utiliser le port sélectionné car il est déjà utilisé. Cette erreur peut se produire de manière intermittente si le timing joue un rôle (condition de course). Ce problème se produit le plus souvent dans les environnements Kubernetes lorsque d'autres services sont mappés dans le conteneur, provoquant des conflits de ports.

Avant de procéder à une solution, il est important de confirmer que le message d'erreur a été produit parce que le port était déjà utilisé. Pour confirmer que c'était la cause :

1. Accédez à la console du job.
1. Recherchez l'artefact `gl-api-security-scanner.log`. Vous pouvez soit télécharger tous les artefacts en sélectionnant **Télécharger** puis rechercher le fichier, soit commencer directement la recherche en sélectionnant **Parcourir**.
1. Ouvrez le fichier `gl-api-security-scanner.log` dans un éditeur de texte.
1. Si le message d'erreur a été produit parce que le port était déjà utilisé, vous devriez voir dans le fichier un message similaire au suivant :

- Dans [GitLab 15.5 et versions ultérieures](https://gitlab.com/gitlab-org/gitlab/-/issues/367734) :

  ```log
  Failed to bind to address http://127.0.0.1:5500: address already in use.
  ```

- Dans GitLab 15.4 et versions antérieures :

  ```log
  Failed to bind to address http://[::]:5000: address already in use.
  ```

Le texte `http://[::]:5000` dans le message précédent pourrait être différent dans votre cas, par exemple il pourrait être `http://[::]:5500` ou `http://127.0.0.1:5500`. Tant que les parties restantes du message d'erreur sont identiques, il est raisonnable de supposer que le port était déjà utilisé.

Si vous n'avez pas trouvé de preuve que le port était déjà utilisé, vérifiez les autres sections de dépannage qui traitent également du même message d'erreur affiché dans la sortie de la console du job. S'il n'y a plus d'options, n'hésitez pas à [obtenir de l'aide ou à demander une amélioration](_index.md#get-support-or-request-an-improvement) via les canaux appropriés.

Une fois que vous avez confirmé que le problème a été produit parce que le port était déjà utilisé. Ensuite, [GitLab 15.5 et versions ultérieures](https://gitlab.com/gitlab-org/gitlab/-/issues/367734) a introduit la variable CI/CD de configuration `FUZZAPI_API_PORT`. Cette variable CI/CD de configuration permet de définir un numéro de port fixe pour le composant d'arrière-plan du scanner.

**Solution**

1. Assurez-vous que votre fichier `.gitlab-ci.yml` définit la variable CI/CD de configuration `FUZZAPI_API_PORT`.
1. Mettez à jour la valeur de `FUZZAPI_API_PORT` avec n'importe quel numéro de port disponible supérieur à 1024. Vérifiez que la nouvelle valeur n'est pas utilisée par GitLab. Consultez la liste complète des ports utilisés par GitLab dans [Paramètres par défaut du package](../../../administration/package_information/defaults.md#ports)

## Erreur : `Errors were found during validation of the document using the published OpenAPI schema` {#error-errors-were-found-during-validation-of-the-document-using-the-published-openapi-schema}

Au début d'un job de fuzzing d'API, la spécification OpenAPI est validée par rapport au [schéma publié](https://github.com/OAI/OpenAPI-Specification/tree/master/schemas). Cette erreur s'affiche lorsque la spécification OpenAPI fournie comporte des erreurs de validation :

```plaintext
Error, the OpenAPI document is not valid.
Errors were found during validation of the document using the published OpenAPI schema
```

Des erreurs peuvent être introduites lors de la création manuelle d'une spécification OpenAPI, ainsi que lors de la génération du schéma.

Pour les spécifications OpenAPI générées automatiquement, les erreurs de validation sont souvent le résultat d'annotations de code manquantes.

**Error message**

- `Error, the OpenAPI document is not valid. Errors were found during validation of the document using the published OpenAPI schema`
  - `OpenAPI 2.0 schema validation error ...`
  - `OpenAPI 3.0.x schema validation error ...`

**Solution**

**For generated OpenAPI Specifications**

1. Identifiez les erreurs de validation.
   1. Utilisez le [Swagger Editor](https://editor.swagger.io/) pour identifier les problèmes de validation dans votre spécification. La nature visuelle du Swagger Editor facilite la compréhension de ce qui doit être modifié.
   1. Vous pouvez également consulter la sortie du journal et rechercher les avertissements de validation de schéma. Ils sont préfixés par des messages tels que `OpenAPI 2.0 schema validation error` ou `OpenAPI 3.0.x schema validation error`. Chaque validation échouée fournit des informations supplémentaires sur `location` et `description`. Les messages de validation de schéma JSON peuvent être complexes, et les éditeurs peuvent vous aider à valider les documents de schéma.
1. Consultez la documentation relative à la génération OpenAPI utilisée par votre framework/pile technologique. Identifiez les modifications nécessaires pour produire un document OpenAPI correct.
1. Une fois les problèmes de validation résolus, relancez votre pipeline.

**For manually created OpenAPI Specifications**

1. Identifiez les erreurs de validation.
   1. La solution la plus simple consiste à utiliser un outil visuel pour modifier et valider le document OpenAPI. Par exemple, le [Swagger Editor](https://editor.swagger.io/) met en évidence les erreurs de schéma et les solutions possibles.
   1. Vous pouvez également consulter la sortie du journal et rechercher les avertissements de validation de schéma. Ils sont préfixés par des messages tels que `OpenAPI 2.0 schema validation error` ou `OpenAPI 3.0.x schema validation error`. Chaque validation échouée fournit des informations supplémentaires sur `location` et `description`. Corrigez chacun des échecs de validation, puis soumettez à nouveau le document OpenAPI. Les messages de validation de schéma JSON peuvent être complexes, et les éditeurs peuvent vous aider à valider les documents de schéma.
1. Une fois les problèmes de validation résolus, relancez votre pipeline.

## `Failed to start scanner session (version header not found)` {#failed-to-start-scanner-session-version-header-not-found}

Le moteur de fuzzing d'API génère un message d'erreur lorsqu'il ne peut pas établir une connexion avec le composant d'application du scanner. Le message d'erreur est affiché dans la fenêtre de sortie du job `apifuzzer_fuzz`. Une cause fréquente de ce problème est la modification de la variable CI/CD `FUZZAPI_API` par rapport à sa valeur par défaut.

**Error message**

- `Failed to start scanner session (version header not found).`

**Solution**

- Supprimez la variable `FUZZAPI_API` du fichier `.gitlab-ci.yml`. La valeur est héritée du modèle CI/CD de fuzzing d'API. Utilisez cette méthode plutôt que de définir manuellement une valeur.
- Si la suppression de la variable n'est pas possible, vérifiez si cette valeur a changé dans la dernière version du [modèle CI/CD de fuzzing d'API](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml). Si c'est le cas, mettez à jour la valeur dans le fichier `.gitlab-ci.yml`.

## `Application cannot determine the base URL for the target API` {#application-cannot-determine-the-base-url-for-the-target-api}

L'analyseur de fuzzing d'API génère un message d'erreur lorsqu'il ne peut pas déterminer l'API cible après inspection du document OpenAPI. Ce message d'erreur s'affiche lorsque l'API cible n'a pas été définie dans le fichier `.gitlab-ci.yml`, qu'elle n'est pas disponible dans le fichier `environment_url.txt`, et qu'elle ne peut pas être calculée à l'aide du document OpenAPI.

Il existe un ordre de priorité dans lequel l'analyseur de fuzzing d'API tente d'obtenir l'API cible lors de la vérification des différentes sources. Premièrement, il tente d'utiliser `FUZZAPI_TARGET_URL`. Si la variable CI/CD d'environnement n'a pas été définie, l'analyseur de fuzzing d'API tente d'utiliser le fichier `environment_url.txt`. S'il n'existe pas de fichier `environment_url.txt`, l'analyseur de fuzzing d'API utilise alors le contenu du document OpenAPI et l'URL fournie dans `FUZZAPI_OPENAPI` (si une URL est fournie) pour tenter de calculer l'API cible.

La solution la mieux adaptée dépend de si votre API cible change ou non pour chaque déploiement :

- Si l'API cible est la même pour chaque déploiement (environnement statique), utilisez la [solution d'environnement statique](#static-environment-solution).
- Si l'API cible change pour chaque déploiement, utilisez une [solution d'environnement dynamique](#dynamic-environment-solutions).

### Solution d'environnement statique {#static-environment-solution}

Cette solution est destinée aux pipelines dans lesquels l'URL de l'API cible ne change pas (est statique).

**Add environmental variable**

Pour les environnements où l'API cible reste la même, vous devez spécifier l'URL cible en utilisant la variable CI/CD d'environnement `FUZZAPI_TARGET_URL`. Dans votre fichier `.gitlab-ci.yml`, ajoutez une variable `FUZZAPI_TARGET_URL`. La variable doit être définie sur l'URL de base de la cible de test d'API. Par exemple :

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OPENAPI: test-api-specification.json
```

### Solutions d'environnement dynamique {#dynamic-environment-solutions}

Dans un environnement dynamique, votre API cible change pour chaque déploiement différent. Dans ce cas, il y a plus d'une solution possible : envisagez d'utiliser le fichier `environment_url.txt` pour les environnements dynamiques.

**Utiliser `environment_url.txt`**

Pour prendre en charge les environnements dynamiques dans lesquels l'URL de l'API cible change à chaque pipeline, le fuzzing d'API prend en charge l'utilisation d'un fichier `environment_url.txt` contenant l'URL à utiliser. Ce fichier n'est pas intégré dans le dépôt, il est plutôt créé pendant le pipeline par le job qui déploie la cible de test et collecté comme artefact pouvant être utilisé par les jobs ultérieurs dans le pipeline. Le job qui crée le fichier `environment_url.txt` doit s'exécuter avant le job de fuzzing d'API.

1. Modifiez le job de déploiement de la cible de test en ajoutant l'URL de base dans un fichier `environment_url.txt` à la racine de votre projet.
1. Modifiez le job de déploiement de la cible de test en collectant le fichier `environment_url.txt` comme artefact.

Exemple :

```yaml
deploy-test-target:
  script:
    # Perform deployment steps
    # Create environment_url.txt (example)
    - echo http://${CI_PROJECT_ID}-${CI_ENVIRONMENT_SLUG}.example.org > environment_url.txt

  artifacts:
    paths:
      - environment_url.txt
```

## Utiliser OpenAPI avec un schéma invalide {#use-openapi-with-an-invalid-schema}

Il existe des cas où le document est autogénéré avec un schéma invalide ou ne peut pas être modifié manuellement dans un délai raisonnable. Dans ces scénarios, le fuzzing d'API est en mesure d'effectuer une validation assouplie en définissant la variable `FUZZAPI_OPENAPI_RELAXED_VALIDATION`. Fournissez un document OpenAPI entièrement conforme pour éviter des comportements inattendus.

### Modifier un fichier OpenAPI non conforme {#edit-a-non-compliant-openapi-file}

Utilisez un éditeur pour détecter et corriger les éléments qui ne sont pas conformes aux spécifications OpenAPI. Un éditeur fournit généralement une validation de document et des suggestions pour créer un document OpenAPI conforme au schéma. Les éditeurs suggérés incluent :

| Éditeur                                             | OpenAPI 2.0                   | OpenAPI 3.0.x                 | OpenAPI 3.1.x |
|----------------------------------------------------|-------------------------------|-------------------------------|---------------|
| [Swagger Editor](https://editor.swagger.io/)       | {{< icon name="check-circle" >}} YAML, JSON | {{< icon name="check-circle" >}} YAML, JSON | {{< icon name="dotted-circle" >}} YAML, JSON |
| [Stoplight Studio](https://stoplight.io/solutions) | {{< icon name="check-circle" >}} YAML, JSON | {{< icon name="check-circle" >}} YAML, JSON | {{< icon name="check-circle" >}} YAML, JSON |

Si votre document OpenAPI est généré manuellement, chargez votre document dans l'éditeur et corrigez tout ce qui n'est pas conforme. Si votre document est généré automatiquement, chargez-le dans votre éditeur pour identifier les problèmes dans le schéma, puis accédez à l'application et effectuez les corrections en fonction du framework que vous utilisez.

### Activer la validation assouplie d'OpenAPI {#enable-openapi-relaxed-validation}

La validation assouplie est destinée aux cas où le document OpenAPI ne peut pas satisfaire les spécifications OpenAPI, mais contient néanmoins suffisamment de contenu pour être utilisé par différents outils. Une validation est effectuée mais de manière moins stricte en ce qui concerne le schéma du document.

Le fuzzing d'API peut toujours essayer de consommer un document OpenAPI qui ne respecte pas entièrement les spécifications OpenAPI. Pour indiquer à l'analyseur de fuzzing d'API d'effectuer une validation assouplie, définissez la variable `FUZZAPI_OPENAPI_RELAXED_VALIDATION` sur n'importe quelle valeur, par exemple :

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick-10
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_OPENAPI_RELAXED_VALIDATION: 'On'
```

## `No operation in the OpenAPI document is consuming any supported media type` {#no-operation-in-the-openapi-document-is-consuming-any-supported-media-type}

Le fuzzing d'API utilise les types de médias spécifiés dans le document OpenAPI pour générer des requêtes. Si aucune requête ne peut être créée en raison de l'absence de types de médias pris en charge, une erreur est générée.

**Error message**

- `Error, no operation in the OpenApi document is consuming any supported media type. Check 'OpenAPI Specification' to check the supported media types.`

**Solution**

1. Consultez les types de médias pris en charge dans la section [Spécification OpenAPI](configuration/enabling_the_analyzer.md#openapi-specification).
1. Modifiez votre document OpenAPI en permettant à au moins une opération donnée d'accepter l'un des types de médias pris en charge. Alternativement, un type de média pris en charge pourrait être défini au niveau du document OpenAPI et s'appliquer à toutes les opérations. Cette étape peut nécessiter des modifications dans votre application pour s'assurer que le type de média pris en charge est accepté par l'application.

## Erreur : `The SSL connection could not be established, see inner exception.` {#error-the-ssl-connection-could-not-be-established-see-inner-exception}

Le fuzzing d'API est compatible avec un large éventail de configurations TLS, y compris les protocoles et les chiffrements obsolètes. Malgré une large prise en charge, vous pourriez rencontrer des erreurs de connexion, comme celle-ci :

```plaintext
Error, error occurred trying to download `<URL>`:
There was an error when retrieving content from Uri:' <URL>'.
Error:The SSL connection could not be established, see inner exception.
```

Cette erreur se produit parce que le fuzzing d'API n'a pas pu établir une connexion sécurisée avec le serveur à l'URL indiquée.

Pour résoudre le problème :

Si l'hôte dans le message d'erreur prend en charge les connexions non TLS, remplacez `https://` par `http://` dans votre configuration. Par exemple, si une erreur se produit avec la configuration suivante :

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_TARGET_URL: https://test-deployment/
  FUZZAPI_OPENAPI: https://specs/openapi.json
```

Changez le préfixe de `FUZZAPI_OPENAPI` de `https://` en `http://` :

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_TARGET_URL: https://test-deployment/
  FUZZAPI_OPENAPI: http://specs/openapi.json
```

Si vous ne pouvez pas utiliser une connexion non TLS pour accéder à l'URL, contactez l'équipe de support pour obtenir de l'aide.

Vous pouvez accélérer l'investigation avec l'[outil testssl.sh](https://testssl.sh/). Depuis une machine disposant d'un shell bash et d'une connectivité au serveur concerné :

1. Téléchargez le dernier fichier `zip` ou `tar.gz` de la release et extrayez-le depuis <https://github.com/drwetter/testssl.sh/releases>.
1. Exécutez `./testssl.sh --log https://specs`.
1. Joignez le fichier journal à votre ticket de support.

## `ERROR: Job failed: failed to pull image` {#error-job-failed-failed-to-pull-image}

Ce message d'erreur se produit lors de l'extraction d'une image depuis un registre de conteneurs qui nécessite une authentification pour y accéder (il n'est pas public).

Dans la sortie de la console du job, l'erreur ressemble à :

```plaintext
Running with gitlab-runner 15.6.0~beta.186.ga889181a (a889181a)
  on blue-2.shared.runners-manager.gitlab.com/default XxUrkriX
Resolving secrets
00:00
Preparing the "docker+machine" executor
00:06
Using Docker executor with image registry.gitlab.com/security-products/api-security:2 ...
Starting service registry.example.com/my-target-app:latest ...
Pulling docker image registry.example.com/my-target-app:latest ...
WARNING: Failed to pull image with policy "always": Error response from daemon: Get https://registry.example.com/my-target-app/manifests/latest: unauthorized (manager.go:237:0s)
ERROR: Job failed: failed to pull image "registry.example.com/my-target-app:latest" with specified policies [always]: Error response from daemon: Get https://registry.example.com/my-target-app/manifests/latest: unauthorized (manager.go:237:0s)
```

**Error message**

- Dans GitLab 15.9 et versions antérieures, `ERROR: Job failed: failed to pull image` suivi de `Error response from daemon: Get IMAGE: unauthorized`.

**Solution**

Les identifiants d'authentification sont fournis à l'aide des méthodes décrites dans la section de documentation [Accéder à une image depuis un registre de conteneurs privé](../../../ci/docker/using_docker_images.md#access-an-image-from-a-private-container-registry). La méthode utilisée est dictée par votre fournisseur de registre de conteneurs et sa configuration. Si vous utilisez un registre de conteneurs fourni par un tiers, tel qu'un fournisseur cloud (Azure, Google Cloud (GCP), AWS, etc.), consultez la documentation du fournisseur pour obtenir des informations sur la façon de s'authentifier auprès de leurs registres de conteneurs.

L'exemple suivant utilise la méthode d'authentification par [identifiants définis statiquement](../../../ci/docker/using_docker_images.md#use-statically-defined-credentials). Dans cet exemple, le registre de conteneurs est `registry.example.com` et l'image est `my-target-app:latest`.

1. Lisez comment [déterminer vos données `DOCKER_AUTH_CONFIG`](../../../ci/docker/using_docker_images.md#determine-your-docker_auth_config-data) pour comprendre comment calculer la valeur de la variable pour `DOCKER_AUTH_CONFIG`. La variable CI/CD de configuration `DOCKER_AUTH_CONFIG` contient la configuration Docker JSON pour fournir les informations d'authentification appropriées. Par exemple, pour accéder au registre de conteneurs privé : `registry.example.com` avec les identifiants `abcdefghijklmn`, le JSON Docker ressemble à :

   ```json
   {
       "auths": {
           "registry.example.com": {
               "auth": "abcdefghijklmn"
           }
       }
   }
   ```

1. Ajoutez `DOCKER_AUTH_CONFIG` en tant que variable CI/CD. Plutôt que d'ajouter la variable de configuration directement dans votre fichier `.gitlab-ci.yml`, vous devriez créer une [variable CI/CD](../../../ci/variables/_index.md#for-a-project) de projet.
1. Relancez votre job, et les identifiants définis statiquement sont désormais utilisés pour se connecter au registre de conteneurs privé `registry.example.com`, et vous permettent d'extraire l'image `my-target-app:latest`. En cas de succès, la console du job affiche une sortie similaire à :

   ```log
   Running with gitlab-runner 15.6.0~beta.186.ga889181a (a889181a)
     on blue-4.shared.runners-manager.gitlab.com/default J2nyww-s
   Resolving secrets
   00:00
   Preparing the "docker+machine" executor
   00:56
   Using Docker executor with image registry.gitlab.com/security-products/api-security:2 ...
   Starting service registry.example.com/my-target-app:latest ...
   Authenticating with credentials from $DOCKER_AUTH_CONFIG
   Pulling docker image registry.example.com/my-target-app:latest ...
   Using docker image sha256:139c39668e5e4417f7d0eb0eeb74145ba862f4f3c24f7c6594ecb2f82dc4ad06 for registry.example.com/my-target-app:latest with digest registry.example.com/my-target-
   app@sha256:2b69fc7c3627dbd0ebaa17674c264fcd2f2ba21ed9552a472acf8b065d39039c ...
   Waiting for services to be up and running (timeout 30 seconds)...
   ```

## Erreur : `sudo: The "no new privileges" flag is set, which prevents sudo from running as root.` {#error-sudo-the-no-new-privileges-flag-is-set-which-prevents-sudo-from-running-as-root}

À partir de la v5 de l'analyseur, un utilisateur non-root est utilisé par défaut. Cela nécessite l'utilisation de `sudo` lors des opérations privilégiées.

Cette erreur se produit avec une configuration spécifique du démon de conteneur qui empêche les conteneurs en cours d'exécution d'obtenir de nouvelles autorisations. Dans la plupart des cas, il ne s'agit pas de la configuration par défaut, c'est quelque chose de spécifiquement configuré, souvent dans le cadre d'un guide de renforcement de la sécurité.

**Error message**

Ce problème peut être identifié par le message d'erreur généré lorsqu'un `before_script` ou un `FUZZAPI_PRE_SCRIPT` est exécuté :

```shell
$ sudo apk add nodejs

sudo: The "no new privileges" flag is set, which prevents sudo from running as root.

sudo: If sudo is running in a container, you may need to adjust the container configuration to disable the flag.
```

**Solution**

Ce problème peut être contourné de la manière suivante :

- Exécutez le conteneur en tant qu'utilisateur `root`. Il est recommandé de tester cette configuration, car elle peut ne pas fonctionner dans tous les cas. Cela peut être fait en modifiant la configuration CI/CD et en vérifiant la sortie du job pour s'assurer que `whoami` renvoie `root` et non `gitlab`. Si `gitlab` est affiché, utilisez une autre solution de contournement. Une fois testé, le `before_script` peut être supprimé.

  ```yaml
  apifuzzer_fuzz:
    image:
      name: $SECURE_ANALYZERS_PREFIX/$FUZZAPI_IMAGE:$FUZZAPI_VERSION$FUZZAPI_IMAGE_SUFFIX
      docker:
        user: root
   before_script:
     - whoami
  ```

  _Exemple de sortie de la console du job :_

  ```log
  Executing "step_script" stage of the job script
  Using docker image sha256:8b95f188b37d6b342dc740f68557771bb214fe520a5dc78a88c7a9cc6a0f9901 for registry.gitlab.com/security-products/api-security:5 with digest registry.gitlab.com/security-products/api-security@sha256:092909baa2b41db8a7e3584f91b982174772abdfe8ceafc97cf567c3de3179d1 ...
  $ whoami
  root
  $ /peach/analyzer-api-fuzzing
  17:17:14 [INF] API Security: Gitlab API Security
  17:17:14 [INF] API Security: -------------------
  17:17:14 [INF] API Security:
  17:17:14 [INF] API Security: version: 5.7.0
  ```

- Enveloppez le conteneur et ajoutez les dépendances nécessaires lors de la compilation. Cette option présente l'avantage de s'exécuter avec des privilèges inférieurs à ceux de root, ce qui peut être une exigence pour certains clients.

  1. Créez un nouveau fichier `Dockerfile` qui enveloppe l'image existante.

     ```yaml
     ARG SECURE_ANALYZERS_PREFIX
     ARG FUZZAPI_IMAGE
     ARG FUZZAPI_VERSION
     ARG FUZZAPI_IMAGE_SUFFIX
     FROM $SECURE_ANALYZERS_PREFIX/$FUZZAPI_IMAGE:$FUZZAPI_VERSION$FUZZAPI_IMAGE_SUFFIX
     USER root

     RUN pip install ...
     RUN apk add ...

     USER gitlab
     ```

  1. Compilez la nouvelle image et poussez-la vers votre registre de conteneurs local avant le démarrage du job de fuzzing d'API. L'image doit être supprimée une fois le job terminé.

     ```shell
     TARGET_NAME=apifuzz-$CI_COMMIT_SHA
     docker build -t $TARGET_IMAGE \
       --build-arg "SECURE_ANALYZERS_PREFIX=$SECURE_ANALYZERS_PREFIX" \
       --build-arg "FUZZAPI_IMAGE=$APISEC_IMAGE" \
       --build-arg "FUZZAPI_VERSION=$APISEC_VERSION" \
       --build-arg "FUZZAPI_IMAGE_SUFFIX=$APISEC_IMAGE_SUFFIX" \
       .
     docker login -u gitlab-ci-token -p $CI_JOB_TOKEN $CI_REGISTRY
     docker push $TARGET_IMAGE
     ```

  1. Étendez le job `apifuzzer_fuzz` et utilisez le nouveau nom d'image.

     ```yaml
     apifuzzer_fuzz:
       image: apifuzz-$CI_COMMIT_SHA
     ```

  1. Supprimez le conteneur temporaire du registre de conteneurs. Voir [cette page de documentation pour obtenir des informations sur la suppression d'images de conteneurs.](../../packages/container_registry/delete_container_registry_images.md)

- Modifiez la configuration du GitLab Runner en désactivant l'indicateur no-new-privileges. Cela pourrait avoir des implications en matière de sécurité et devrait être discuté avec vos équipes opérationnelles et de sécurité.

## `Index was outside the bounds of the array at Peach.Web.Runner.Services.RunnerOptions.GetHeaders()` {#index-was-outside-the-bounds-of-the-array-at-peachwebrunnerservicesrunneroptionsgetheaders}

Ce message d'erreur indique que l'analyseur de fuzzing d'API n'est pas en mesure d'analyser la valeur de la variable CI/CD de configuration `FUZZAPI_REQUEST_HEADERS` ou `FUZZAPI_REQUEST_HEADERS_BASE64`.

**Error message**

Ce problème peut être identifié par deux messages d'erreur. Le premier message d'erreur est visible dans la sortie de la console du job et le second dans le fichier `gl-api-security-scanner.log`.

_Message d'erreur de la console du job :_

```plaintext
05:48:38 [ERR] API Security: Testing failed: An unexpected exception occurred: Index was outside the bounds of the array.
```

_Message d'erreur de `gl_api_security-scanner.log` :_

```plaintext
08:45:43.616 [ERR] <Peach.Web.Core.Services.WebRunnerMachine> Unexpected exception in WebRunnerMachine::Run()
System.IndexOutOfRangeException: Index was outside the bounds of the array.
   at Peach.Web.Runner.Services.RunnerOptions.GetHeaders() in /builds/gitlab-org/security-products/analyzers/api-fuzzing-src/web/PeachWeb/Runner/Services/[RunnerOptions.cs:line 362
   at Peach.Web.Runner.Services.RunnerService.Start(Job job, IRunnerOptions options) in /builds/gitlab-org/security-products/analyzers/api-fuzzing-src/web/PeachWeb/Runner/Services/RunnerService.cs:line 67
   at Peach.Web.Core.Services.WebRunnerMachine.Run(IRunnerOptions runnerOptions, CancellationToken token) in /builds/gitlab-org/security-products/analyzers/api-fuzzing-src/web/PeachWeb/Core/Services/WebRunnerMachine.cs:line 321
08:45:43.634 [WRN] <Peach.Web.Core.Services.WebRunnerMachine> * Session failed: An unexpected exception occurred: Index was outside the bounds of the array.
08:45:43.677 [INF] <Peach.Web.Core.Services.WebRunnerMachine> Finished testing. Performed a total of 0 requests.
```

**Solution**

Ce problème se produit en raison d'une variable CI/CD `FUZZAPI_REQUEST_HEADERS` ou `FUZZAPI_REQUEST_HEADERS_BASE64` mal formée. Le format attendu est un ou plusieurs en-têtes de construction `Header: value` séparés par une virgule. La solution consiste à corriger la syntaxe pour correspondre à ce qui est attendu.

_Exemples valides :_

- `Authorization: Bearer XYZ`
- `X-Custom: Value,Authorization: Bearer XYZ`

_Exemples invalides :_

- `Header:,value`
- `HeaderA: value,HeaderB:,HeaderC: value`
- `Header`
