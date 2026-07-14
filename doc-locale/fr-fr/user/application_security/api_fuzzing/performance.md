---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Réglage des performances et vitesse des tests
---

Les outils de sécurité qui effectuent des tests de fuzzing d'API, tels que l'API fuzzing, réalisent les tests en envoyant des requêtes à une instance de votre application en cours d'exécution. Les requêtes sont mutées par le moteur de fuzzing afin de déclencher un comportement inattendu qui pourrait exister dans votre application. La vitesse d'un test de fuzzing d'API dépend des éléments suivants :

- Combien de requêtes par seconde peuvent être envoyées à votre application par les outils GitLab
- La rapidité avec laquelle votre application répond aux requêtes
- Combien de requêtes doivent être envoyées pour tester l'application
  - Combien d'opérations votre API comprend
  - Combien de champs contient chaque opération (corps JSON, en-têtes, chaîne de requête, cookies, etc.)

Si le job de test de fuzzing d'API prend encore plus de temps que prévu après avoir suivi les conseils de ce guide de performance, contactez le support pour obtenir une assistance supplémentaire.

## Diagnostic des problèmes de performance {#diagnosing-performance-issues}

La première étape pour résoudre les problèmes de performance est de comprendre ce qui contribue à un temps de test plus long que prévu. Voici quelques problèmes fréquemment signalés :

- L'API fuzzing s'exécute sur un runner à faible vCPU
- L'application est déployée sur une instance lente/à processeur unique et n'est pas en mesure de suivre la charge de test
- L'application contient une opération lente qui impacte la vitesse globale du test (> 1/2 seconde)
- L'application contient une opération qui renvoie une grande quantité de données (> 500 Ko+)
- L'application contient un grand nombre d'opérations (> 40)

### L'application contient une opération lente qui impacte la vitesse globale du test (> 1/2 seconde) {#the-application-contains-a-slow-operation-that-impacts-the-overall-test-speed--12-second}

La sortie du job d'API fuzzing contient des informations utiles sur la vitesse des tests, les temps de réponse des opérations et des informations récapitulatives. Utilisez l'exemple de sortie suivant pour identifier les problèmes de performance :

```shell
API Fuzzing: Loaded 10 operations from: assets/har-large-response/large_responses.har
API Fuzzing:
API Fuzzing: Testing operation [1/10]: 'GET http://target:7777/api/large_response_json'.
API Fuzzing:  - Parameters: (Headers: 4, Query: 0, Body: 0)
API Fuzzing:  - Request body size: 0 Bytes (0 bytes)
API Fuzzing:
API Fuzzing: Finished testing operation 'GET http://target:7777/api/large_response_json'.
API Fuzzing:  - Excluded Parameters: (Headers: 0, Query: 0, Body: 0)
API Fuzzing:  - Performed 767 requests
API Fuzzing:  - Average response body size: 130 MB
API Fuzzing:  - Average call time: 2 seconds and 82.69 milliseconds (2.082693 seconds)
API Fuzzing:  - Time to complete: 14 minutes, 8 seconds and 788.36 milliseconds (848.788358 seconds)
```

L'extrait de sortie de la console du job commence par le nombre d'opérations trouvées (10). Viennent ensuite des notifications indiquant que le test a démarré sur une opération spécifique, et qu'un récapitulatif d'opération a été complété. Le récapitulatif indique que l'API fuzzing a effectué 767 requêtes pour tester entièrement cette opération et ses champs associés. Le récapitulatif indique également que cette opération a pris 14 minutes pour se terminer, avec un temps de réponse moyen de 2 secondes.

Un temps de réponse moyen de deux secondes est un indicateur initial que cette opération spécifique prend beaucoup de temps à tester. Vous pouvez également constater que la taille du corps de la réponse est importante, ce qui est la cause du long temps de réponse. La majeure partie du temps de réponse pour chaque requête est consacrée au transfert des données du corps de la réponse.

Pour ce problème, l'équipe pourrait décider de :

- Utiliser un runner avec plus de vCPUs, car cela permet à l'API fuzzing de paralléliser le travail effectué. Cela contribue à réduire le temps de test, mais ramener le test en dessous de 10 minutes pourrait encore être problématique sans passer à une machine à CPU élevé, en raison du temps que prend l'opération pour être testée. Bien que les runners plus grands soient plus coûteux, vous payez également moins de minutes si les exécutions de job sont plus rapides.
- [Exclure cette opération](#excluding-slow-operations) du test d'API fuzzing. Bien que ce soit la solution la plus simple, elle présente l'inconvénient d'une lacune dans la couverture des tests de sécurité.
- [Exclure l'opération des tests d'API fuzzing sur les branches de fonctionnalité, mais l'inclure dans le test de la branche par défaut](#excluding-operations-in-feature-branches-but-not-default-branch).
- [Diviser les tests d'API fuzzing en plusieurs jobs](#splitting-a-test-into-multiple-jobs).

La solution probable consiste à utiliser une combinaison de ces solutions pour atteindre un temps de test acceptable, en supposant que les exigences de votre équipe se situent dans la plage de 5 à 7 minutes.

## Résolution des problèmes de performance {#addressing-performance-issues}

Les sections suivantes documentent diverses options pour résoudre les problèmes de performance liés à l'API fuzzing :

- [Utiliser un runner plus grand](#using-a-larger-runner)
- [Exclure les opérations lentes](#excluding-slow-operations)
- [Diviser un test en plusieurs jobs](#splitting-a-test-into-multiple-jobs)
- [Exclure les opérations dans les branches de fonctionnalité, mais pas dans la branche par défaut](#excluding-operations-in-feature-branches-but-not-default-branch)

### Utiliser un runner plus grand {#using-a-larger-runner}

L'un des moyens les plus simples d'améliorer les performances peut être obtenu en utilisant un [runner plus grand](../../../ci/runners/hosted_runners/linux.md#machine-types-available-for-linux---x86-64) avec l'API fuzzing. Ce tableau présente les statistiques collectées lors du benchmarking d'une API REST Java Spring Boot. Dans ce benchmark, la cible et l'API fuzzing partagent une seule instance de runner.

| Tag du runner hébergé sur Linux           | Requêtes par seconde |
|------------------------------------|-----------|
| `saas-linux-small-amd64` (par défaut) | 255 |
| `saas-linux-medium-amd64`          | 400 |

Ce tableau montre comment l'augmentation de la taille du runner et du nombre de vCPUs peut avoir un impact important sur la vitesse/performance des tests.

Voici un exemple de définition de job pour l'API fuzzing qui ajoute une section `tags` pour utiliser le runner GitLab hébergé de taille moyenne sur Linux. Le job étend la définition de job incluse via le modèle d'API fuzzing.

```yaml
apifuzzer_fuzz:
  tags:
  - saas-linux-medium-amd64
```

Dans le fichier `gl-api-security-scanner.log`, vous pouvez rechercher la chaîne `Starting work item processor` pour inspecter le DOP max rapporté (degré de parallélisme). Le DOP max doit être supérieur ou égal au nombre de vCPUs assignés au runner. Si vous n'êtes pas en mesure d'identifier le problème, ouvrez un ticket auprès du support pour obtenir de l'aide.

Exemple d'entrée de journal :

`17:00:01.084 [INF] <Peach.Web.Core.Services.WebRunnerMachine> Starting work item processor with 4 max DOP`

### Exclure les opérations lentes {#excluding-slow-operations}

Dans le cas d'une ou deux opérations lentes, l'équipe pourrait décider de ne pas tester ces opérations. L'exclusion de l'opération s'effectue à l'aide de la `FUZZAPI_EXCLUDE_PATHS` configuration [variable comme expliqué dans cette section.](configuration/customizing_analyzer_settings.md#exclude-paths)

Cet exemple montre une opération qui renvoie une grande quantité de données. L'opération est `GET http://target:7777/api/large_response_json`. Pour l'exclure, fournissez la variable de configuration `FUZZAPI_EXCLUDE_PATHS` avec la portion de chemin de l'URL de l'opération `/api/large_response_json`.

Pour vérifier que l'opération est exclue, exécutez le job d'API fuzzing et examinez la sortie de la console du job. Elle inclut une liste des opérations incluses et exclues à la fin du test.

```yaml
apifuzzer_fuzz:
  variables:
    FUZZAPI_EXCLUDE_PATHS: /api/large_response_json
```

> [!warning]
> L'exclusion d'opérations des tests pourrait permettre à certaines vulnérabilités de passer inaperçues.

### Diviser un test en plusieurs jobs {#splitting-a-test-into-multiple-jobs}

La division d'un test en plusieurs jobs est prise en charge par l'API fuzzing grâce à l'utilisation de [`FUZZAPI_EXCLUDE_PATHS`](configuration/customizing_analyzer_settings.md#exclude-paths) et [`FUZZAPI_EXCLUDE_URLS`](configuration/customizing_analyzer_settings.md#exclude-urls). Lors de la division d'un test, un bon modèle consiste à désactiver le job `apifuzzer_fuzz` et à le remplacer par deux jobs avec des noms identifiants. Cet exemple montre deux jobs. Chaque job teste une version de l'API, comme leurs noms l'indiquent. Cependant, cette technique peut être appliquée à n'importe quelle situation, pas seulement avec des versions d'une API.

Les règles utilisées dans les jobs `apifuzzer_v1` et `apifuzzer_v2` sont copiées depuis le [modèle d'API fuzzing](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/DAST-API.gitlab-ci.yml).

```yaml
# Disable the main apifuzzer_fuzz job
apifuzzer_fuzz:
  rules:
    - if: $CI_COMMIT_BRANCH
      when: never

apifuzzer_v1:
  extends: apifuzzer_fuzz
  variables:
    FUZZAPI_EXCLUDE_PATHS: /api/v1/**
  rules:
    - if: $API_FUZZING_DISABLED == 'true' || $API_FUZZING_DISABLED == '1'
      when: never
    - if: $API_FUZZING_DISABLED_FOR_DEFAULT_BRANCH == 'true' &&
            $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
      when: never
    - if: $API_FUZZING_DISABLED_FOR_DEFAULT_BRANCH == '1' &&
            $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
      when: never
    - if: $CI_COMMIT_BRANCH &&
          $CI_GITLAB_FIPS_MODE == "true"
      variables:
          FUZZAPI_IMAGE_SUFFIX: "-fips"
    - if: $CI_COMMIT_BRANCH

apifuzzer_v2:
  variables:
    FUZZAPI_EXCLUDE_PATHS: /api/v2/**
  rules:
    - if: $API_FUZZING_DISABLED == 'true' || $API_FUZZING_DISABLED == '1'
      when: never
    - if: $API_FUZZING_DISABLED_FOR_DEFAULT_BRANCH &&
            $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
      when: never
    - if: $CI_COMMIT_BRANCH &&
          $CI_GITLAB_FIPS_MODE == "true"
      variables:
          FUZZAPI_IMAGE_SUFFIX: "-fips"
    - if: $CI_COMMIT_BRANCH
```

### Exclure les opérations dans les branches de fonctionnalité, mais pas dans la branche par défaut {#excluding-operations-in-feature-branches-but-not-default-branch}

Dans le cas d'une ou deux opérations lentes, l'équipe pourrait décider de ne pas tester ces opérations, ou de les exclure des tests sur les branches de fonctionnalité, mais de les inclure pour les tests sur la branche par défaut. L'exclusion de l'opération s'effectue à l'aide de la `FUZZAPI_EXCLUDE_PATHS` configuration [variable comme expliqué dans cette section.](configuration/customizing_analyzer_settings.md#exclude-paths)

Cet exemple montre une opération qui renvoie une grande quantité de données. L'opération est `GET http://target:7777/api/large_response_json`. Pour l'exclure, fournissez la variable de configuration `FUZZAPI_EXCLUDE_PATHS` avec la portion de chemin de l'URL de l'opération `/api/large_response_json`. La configuration désactive le job principal `apifuzzer_fuzz` et crée deux nouveaux jobs `apifuzzer_main` et `apifuzzer_branch`. Le `apifuzzer_branch` est configuré pour exclure l'opération longue et s'exécuter uniquement sur les branches non par défaut (par exemple, les branches de fonctionnalité). La branche `apifuzzer_main` est configurée pour s'exécuter uniquement sur la branche par défaut (`main` dans cet exemple). Les jobs `apifuzzer_branch` s'exécutent plus rapidement, permettant des cycles de développement rapides, tandis que le job `apifuzzer_main`, qui ne s'exécute que sur les builds de la branche par défaut, prend plus de temps à s'exécuter.

Pour vérifier que l'opération est exclue, exécutez le job d'API fuzzing et examinez la sortie de la console du job. Elle inclut une liste des opérations incluses et exclues à la fin du test.

```yaml
# Disable the main job so you can create two jobs with
# different names
apifuzzer_fuzz:
  rules:
    - if: $CI_COMMIT_BRANCH
      when: never

# API fuzzing for feature branch work, excludes /api/large_response_json
apifuzzer_branch:
  extends: apifuzzer_fuzz
  variables:
    FUZZAPI_EXCLUDE_PATHS: /api/large_response_json
  rules:
    - if: $API_FUZZING_DISABLED == 'true' || $API_FUZZING_DISABLED == '1'
      when: never
    - if: $API_FUZZING_DISABLED_FOR_DEFAULT_BRANCH &&
            $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
      when: never
    - if: $CI_COMMIT_BRANCH &&
          $CI_GITLAB_FIPS_MODE == "true"
      variables:
          FUZZAPI_IMAGE_SUFFIX: "-fips"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: never
    - if: $CI_COMMIT_BRANCH

# API fuzzing for default branch (main in this case)
# Includes the long running operations
apifuzzer_main:
  extends: apifuzzer_fuzz
  rules:
    - if: $API_FUZZING_DISABLED == 'true' || $API_FUZZING_DISABLED == '1'
      when: never
    - if: $API_FUZZING_DISABLED_FOR_DEFAULT_BRANCH &&
            $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
      when: never
    - if: $CI_COMMIT_BRANCH &&
          $CI_GITLAB_FIPS_MODE == "true"
      variables:
          FUZZAPI_IMAGE_SUFFIX: "-fips"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```
