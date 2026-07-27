---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Optimisation des performances et vitesse de test
---

Les outils de sécurité qui effectuent des tests d'analyse dynamique, tels que les tests de sécurité des API, réalisent les tests en envoyant des requêtes à une instance de votre application en cours d'exécution. Les requêtes sont conçues pour tester des vulnérabilités spécifiques qui pourraient exister dans votre application. La vitesse d'un test d'analyse dynamique dépend des éléments suivants :

- Combien de requêtes par seconde peuvent être envoyées à votre application par les outils GitLab
- La vitesse à laquelle votre application répond aux requêtes
- Combien de requêtes doivent être envoyées pour tester l'application
  - De combien d'opérations votre API est composée
  - Combien de champs contient chaque opération (corps JSON, en-têtes, chaîne de requête, cookies, etc.)

Si le job de test de sécurité des API prend toujours plus de temps que prévu après avoir suivi les conseils de ce guide de performances, contactez le support pour obtenir de l'aide supplémentaire.

## Diagnostic des problèmes de performances {#diagnosing-performance-issues}

La première étape pour résoudre les problèmes de performances consiste à comprendre ce qui contribue au temps de test plus long que prévu. Parmi les problèmes fréquemment signalés, on trouve :

- Les tests de sécurité des API s'exécutent sur un runner avec peu de vCPU
- L'application est déployée sur une instance lente/mono-CPU et n'est pas en mesure de suivre la charge de test
- L'application contient une opération lente qui impacte la vitesse globale du test (> 1/2 seconde)
- L'application contient une opération qui renvoie une grande quantité de données (> 500 Ko+)
- L'application contient un grand nombre d'opérations (> 40)

### L'application contient une opération lente qui impacte la vitesse globale du test (> 1/2 seconde) {#the-application-contains-a-slow-operation-that-impacts-the-overall-test-speed--12-second}

La sortie du job de test de sécurité des API contient des informations utiles sur la vitesse de test, les temps de réponse des opérations et des informations récapitulatives. L'exemple de sortie suivant montre comment vous pouvez utiliser une sortie récapitulative pour identifier les problèmes de performances :

```shell
API SECURITY: Loaded 10 operations from: assets/har-large-response/large_responses.har
API SECURITY:
API SECURITY: Testing operation [1/10]: 'GET http://target:7777/api/large_response_json'.
API SECURITY:  - Parameters: (Headers: 4, Query: 0, Body: 0)
API SECURITY:  - Request body size: 0 Bytes (0 bytes)
API SECURITY:
API SECURITY: Finished testing operation 'GET http://target:7777/api/large_response_json'.
API SECURITY:  - Excluded Parameters: (Headers: 0, Query: 0, Body: 0)
API SECURITY:  - Performed 767 requests
API SECURITY:  - Average response body size: 130 MB
API SECURITY:  - Average call time: 2 seconds and 82.69 milliseconds (2.082693 seconds)
API SECURITY:  - Time to complete: 14 minutes, 8 seconds and 788.36 milliseconds (848.788358 seconds)
```

L'extrait de sortie de la console du job commence par le nombre d'opérations trouvées (10). Ensuite, il notifie que le test a démarré sur une opération spécifique et qu'un récapitulatif de l'opération a été complété. Le récapitulatif indique qu'il a fallu 767 requêtes aux tests de sécurité des API pour tester complètement cette opération et ses champs associés. Le récapitulatif indique également que l'opération avait un temps de réponse moyen de 2 secondes et a pris 14 minutes pour se terminer.

Un temps de réponse moyen de 2 secondes est un bon indicateur initial que cette opération spécifique prend beaucoup de temps à tester. Le récapitulatif montre également une taille de corps de réponse importante, ce qui provoque le long temps de réponse. La majeure partie du temps de réponse pour chaque requête est consacrée au transfert des données du corps de la réponse.

Pour ce problème, l'équipe pourrait décider de :

- Utiliser un runner avec davantage de vCPU, car cela permet aux tests de sécurité des API de paralléliser le travail effectué. Cela contribue à réduire le temps de test, mais ramener le test en dessous de 10 minutes peut encore être problématique sans passer à une machine avec un CPU puissant, en raison du temps nécessaire pour tester l'opération. Bien que les runners plus grands soient plus coûteux, vous payez également moins de minutes si les exécutions de jobs sont plus rapides.
- [Exclure cette opération](#excluding-slow-operations) des tests de sécurité des API. Bien que ce soit la solution la plus simple, elle présente l'inconvénient d'une lacune dans la couverture des tests de sécurité.
- [Exclure l'opération des tests de sécurité des API sur les branches de fonctionnalité, mais l'inclure dans le test de la branche par défaut](#excluding-operations-in-feature-branches-but-not-default-branch).
- [Diviser les tests de sécurité des API en plusieurs jobs](#splitting-a-test-into-multiple-jobs).

La solution probable consiste à utiliser une combinaison de ces solutions pour atteindre un temps de test acceptable, en supposant que les exigences de votre équipe se situent dans une plage de 5 à 7 minutes.

## Résolution des problèmes de performances {#addressing-performance-issues}

Les sections suivantes documentent diverses options pour résoudre les problèmes de performances liés aux tests de sécurité des API :

- [Utiliser un runner plus grand](#using-a-larger-runner)
- [Exclusion des opérations lentes](#excluding-slow-operations)
- [Diviser un test en plusieurs jobs](#splitting-a-test-into-multiple-jobs)
- [Exclure des opérations dans les branches de fonctionnalité, mais pas dans la branche par défaut](#excluding-operations-in-feature-branches-but-not-default-branch)

### Utiliser un runner plus grand {#using-a-larger-runner}

L'un des moyens les plus simples d'améliorer les performances peut être obtenu en utilisant un [runner plus grand](../../../ci/runners/hosted_runners/linux.md#machine-types-available-for-linux---x86-64) avec les tests de sécurité des API. Ce tableau présente les statistiques collectées lors du benchmarking d'une API REST Java Spring Boot. Dans ce benchmark, la cible et les tests de sécurité des API partagent une seule instance de runner.

| Tag du runner hébergé sur Linux           | Requêtes par seconde |
|------------------------------------|-----------|
| `saas-linux-small-amd64` (par défaut) | 255 |
| `saas-linux-medium-amd64`          | 400 |

Ce tableau montre comment l'augmentation de la taille du runner et du nombre de vCPU peut avoir un impact important sur la vitesse/les performances des tests.

Voici un exemple de définition de job pour les tests de sécurité des API qui ajoute une section `tags` pour utiliser le runner GitLab hébergé de taille moyenne sur Linux. Le job étend la définition de job incluse via le modèle de test de sécurité des API.

```yaml
api_security:
  tags:
  - saas-linux-medium-amd64
```

Dans le fichier `gl-api-security-scanner.log`, vous pouvez rechercher la chaîne `Starting work item processor` pour inspecter le max DOP (degré de parallélisme) rapporté. Le max DOP doit être supérieur ou égal au nombre de vCPU attribués au runner. Si vous ne parvenez pas à identifier le problème, ouvrez un ticket auprès du support pour obtenir de l'aide.

Exemple d'entrée de journal :

`17:00:01.084 [INF] <Peach.Web.Core.Services.WebRunnerMachine> Starting work item processor with 4 max DOP`

### Exclure les opérations lentes {#excluding-slow-operations}

Dans le cas d'une ou deux opérations lentes, l'équipe pourrait décider d'ignorer le test de ces opérations. L'exclusion de l'opération s'effectue à l'aide de la variable de configuration `APISEC_EXCLUDE_PATHS` [comme expliqué dans cette section.](configuration/customizing_analyzer_settings.md#exclude-paths)

Cet exemple montre une opération qui renvoie une grande quantité de données. L'opération est `GET http://target:7777/api/large_response_json`. Pour l'exclure, fournissez la variable de configuration `APISEC_EXCLUDE_PATHS` avec la partie chemin de l'URL de l'opération `/api/large_response_json`.

Pour vérifier que l'opération est exclue, exécutez le job de test de sécurité des API et examinez la sortie de la console du job. Elle inclut une liste des opérations incluses et exclues à la fin du test.

```yaml
api_security:
  variables:
    APISEC_EXCLUDE_PATHS: /api/large_response_json
```

> [!warning]
> L'exclusion d'opérations des tests pourrait permettre à certaines vulnérabilités de passer inaperçues.

### Diviser un test en plusieurs jobs {#splitting-a-test-into-multiple-jobs}

La division d'un test en plusieurs jobs est prise en charge par les tests de sécurité des API grâce à l'utilisation de [`APISEC_EXCLUDE_PATHS`](configuration/customizing_analyzer_settings.md#exclude-paths) et [`APISEC_EXCLUDE_URLS`](configuration/customizing_analyzer_settings.md#exclude-urls). Lors de la division d'un test, un bon modèle consiste à désactiver le job `dast_api` et à le remplacer par deux jobs avec des noms identifiants. Cet exemple montre deux jobs. Chaque job teste une version de l'API, comme le reflètent leurs noms. Cependant, cette technique peut être appliquée à n'importe quelle situation, pas seulement aux versions d'une API.

Les règles utilisées dans les jobs `APISEC_v1` et `APISEC_v2` sont copiées à partir du [modèle de test de sécurité des API](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml).

```yaml
# Disable the main dast_api job
api_security:
  rules:
  - if: $CI_COMMIT_BRANCH
    when: never

APISEC_v1:
  extends: dast_api
  variables:
    APISEC_EXCLUDE_PATHS: /api/v1/**
  rules:
  - if: $APISEC_DISABLED == 'true' || $APISEC_DISABLED == '1'
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == 'true' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == '1' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $CI_COMMIT_BRANCH &&
        $CI_GITLAB_FIPS_MODE == "true"
    variables:
      APISEC_IMAGE_SUFFIX: "-fips"
  - if: $CI_COMMIT_BRANCH

APISEC_v2:
  variables:
    APISEC_EXCLUDE_PATHS: /api/v2/**
  rules:
  - if: $APISEC_DISABLED == 'true' || $APISEC_DISABLED == '1'
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == 'true' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == '1' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $CI_COMMIT_BRANCH &&
        $CI_GITLAB_FIPS_MODE == "true"
    variables:
      APISEC_IMAGE_SUFFIX: "-fips"
  - if: $CI_COMMIT_BRANCH
```

### Exclure des opérations dans les branches de fonctionnalité, mais pas dans la branche par défaut {#excluding-operations-in-feature-branches-but-not-default-branch}

Dans le cas d'une ou deux opérations lentes, l'équipe pourrait décider d'ignorer le test de ces opérations, ou de les exclure des tests de branche de fonctionnalité, mais de les inclure pour les tests de branche par défaut. L'exclusion de l'opération s'effectue à l'aide de la variable de configuration `APISEC_EXCLUDE_PATHS` [comme expliqué dans cette section.](configuration/customizing_analyzer_settings.md#exclude-paths)

Cet exemple montre une opération qui renvoie une grande quantité de données. L'opération est `GET http://target:7777/api/large_response_json`. Pour l'exclure, fournissez la variable de configuration `APISEC_EXCLUDE_PATHS` avec la partie chemin de l'URL de l'opération `/api/large_response_json`. La configuration désactive le job principal `dast_api` et crée deux nouveaux jobs `APISEC_main` et `APISEC_branch`. Le `APISEC_branch` est configuré pour exclure l'opération longue et s'exécuter uniquement sur les branches non par défaut (par exemple, les branches de fonctionnalité). La branche `APISEC_main` est configurée pour s'exécuter uniquement sur la branche par défaut (`main` dans cet exemple). Les jobs `APISEC_branch` s'exécutent plus rapidement, permettant des cycles de développement rapides, tandis que le job `APISEC_main`, qui s'exécute uniquement sur les builds de la branche par défaut, prend plus de temps à s'exécuter.

Pour vérifier que l'opération est exclue, exécutez le job de test de sécurité des API et examinez la sortie de la console du job. Elle inclut une liste des opérations incluses et exclues à la fin du test.

```yaml
# Disable the main job so you can create two jobs with
# different names
api_security:
  rules:
  - if: $CI_COMMIT_BRANCH
    when: never

# API security testing for feature branch work, excludes /api/large_response_json
APISEC_branch:
  extends: dast_api
  variables:
    APISEC_EXCLUDE_PATHS: /api/large_response_json
  rules:
  - if: $APISEC_DISABLED == 'true' || $APISEC_DISABLED == '1'
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == 'true' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == '1' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $CI_COMMIT_BRANCH &&
        $CI_GITLAB_FIPS_MODE == "true"
    variables:
      APISEC_IMAGE_SUFFIX: "-fips"
  - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    when: never
  - if: $CI_COMMIT_BRANCH

# API security testing for default branch (main in this case)
# Includes the long running operations
APISEC_main:
  extends: dast_api
  rules:
  - if: $APISEC_DISABLED == 'true' || $APISEC_DISABLED == '1'
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == 'true' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $APISEC_DISABLED_FOR_DEFAULT_BRANCH == '1' &&
        $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
    when: never
  - if: $CI_COMMIT_BRANCH &&
        $CI_GITLAB_FIPS_MODE == "true"
    variables:
      APISEC_IMAGE_SUFFIX: "-fips"
  - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```
