---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Analyseur de test de sécurité des API
---

{{< details >}}

- Édition : Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Renommé](https://gitlab.com/gitlab-org/gitlab/-/issues/457449) dans GitLab 17.0 de « Analyseur DAST API » en « Analyseur de test de sécurité des API ».

{{< /history >}}

Testez les API web pour aider à découvrir des bogues et des problèmes de sécurité potentiels que d'autres processus d'assurance qualité pourraient manquer. Utilisez le test de sécurité des API en complément d'autres analyseurs de sécurité et de vos propres processus de test. Vous pouvez exécuter des tests de sécurité des API dans le cadre de votre flux de travail CI/CD, [à la demande](../dast/on-demand_scan.md), ou les deux.

> [!warning]
> N'exécutez pas de test de sécurité des API contre un serveur de production. Non seulement il peut exécuter toutes les fonctions que l'API peut exécuter, mais il peut également déclencher des bogues dans l'API. Cela inclut des actions telles que la modification et la suppression de données. Exécutez uniquement les tests de sécurité des API contre un serveur de test.

## Premiers pas {#getting-started}

Commencez avec le test de sécurité des API en modifiant votre configuration CI/CD.

Prérequis :

- Vous disposez d'une API web utilisant l'un des types d'API pris en charge :
  - API REST
  - SOAP
  - GraphQL
  - Corps de formulaires, JSON ou XML
- Vous disposez d'une spécification d'API dans l'un des formats suivants :
  - [Spécification OpenAPI v2 ou v3](configuration/enabling_the_analyzer.md#openapi-specification)
  - [Schéma GraphQL](configuration/enabling_the_analyzer.md#graphql-schema)
  - [HTTP Archive (HAR)](configuration/enabling_the_analyzer.md#http-archive-har)
  - [Collection Postman v2.0 ou v2.1](configuration/enabling_the_analyzer.md#postman-collection)

  Chaque analyse prend en charge exactement une spécification. Pour analyser plusieurs spécifications, utilisez plusieurs analyses.
- Vous disposez d'un [GitLab Runner](../../../ci/runners/_index.md) disponible, avec l'[exécuteur `docker`](https://docs.gitlab.com/runner/executors/docker/) sur Linux/amd64.
- Vous disposez d'une application cible déployée. Pour plus de détails, consultez les [options de déploiement](#application-deployment-options).
- L'étape `dast` est ajoutée à la définition de votre pipeline CI/CD, après l'étape `deploy`. Par exemple :

  ```yaml
  stages:
    - build
    - test
    - deploy
    - dast
  ```

Pour activer le test de sécurité des API, vous devez modifier votre fichier YAML de configuration GitLab CI/CD en fonction des besoins spécifiques de votre environnement. Vous pouvez spécifier l'API que vous souhaitez analyser en utilisant :

- [Spécification OpenAPI v2 ou v3](configuration/enabling_the_analyzer.md#openapi-specification)
- [Schéma GraphQL](configuration/enabling_the_analyzer.md#graphql-schema)
- [HTTP Archive (HAR)](configuration/enabling_the_analyzer.md#http-archive-har)
- [Collection Postman v2.0 ou v2.1](configuration/enabling_the_analyzer.md#postman-collection)

## Comprendre les résultats {#understanding-the-results}

Pour afficher le résultat d'une analyse de sécurité :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Pipelines**.
1. Sélectionnez le pipeline.
1. Sélectionnez l'onglet **Sécurité**.
1. Sélectionnez une vulnérabilité pour en afficher les détails, notamment :
   - Statut : Indique si la vulnérabilité a été triée ou résolue.
   - Description : Explique la cause de la vulnérabilité, son impact potentiel et les étapes de remédiation recommandées.
   - Gravité : Classifiée en six niveaux selon l'impact. [En savoir plus sur les niveaux de gravité](../vulnerabilities/severities.md).
   - Analyseur : Identifie quel analyseur a détecté la vulnérabilité.
   - Méthode : Établit le type d'interaction avec le serveur vulnérable.
   - URL : Indique l'emplacement de la vulnérabilité.
   - Preuve : Décrit le cas de test permettant de prouver la présence d'une vulnérabilité donnée.
   - Identifiants : Une liste de références utilisées pour classer la vulnérabilité, telles que les identifiants CWE.

Vous pouvez également télécharger les résultats de l'analyse de sécurité :

- Dans l'onglet **Sécurité** du pipeline, sélectionnez **Télécharger les résultats**.

Pour plus de détails, consultez le [rapport de sécurité du pipeline](../detect/security_scanning_results.md).

> [!note]
> Les résultats sont générés sur les branches de fonctionnalités. Lorsqu'ils sont fusionnés dans la branche par défaut, ils deviennent des vulnérabilités. Cette distinction est importante lors de l'évaluation de votre posture de sécurité.

## Optimisation {#optimization}

Pour tirer le meilleur parti du test de sécurité des API, suivez ces recommandations :

- Configurez les runners pour utiliser la [politique always pull](https://docs.gitlab.com/runner/executors/docker/#using-the-always-pull-policy) afin d'exécuter les dernières versions des analyseurs.
- Par défaut, le test de sécurité des API télécharge tous les artefacts définis par les jobs précédents dans le pipeline. Si votre job DAST ne repose pas sur `environment_url.txt` pour définir l'URL testée ou sur d'autres fichiers créés par des jobs précédents, vous ne devriez pas télécharger les artefacts. Pour éviter de télécharger des artefacts, étendez le job CI/CD de l'analyseur afin de ne spécifier aucune dépendance. Par exemple, pour l'analyseur de test de sécurité des API, ajoutez ce qui suit à votre fichier `.gitlab-ci.yml` :

  ```yaml
  api_security:
    dependencies: []
  ```

Pour configurer le test de sécurité des API pour votre application ou environnement particulier, consultez la liste complète des [options de configuration](configuration/_index.md).

## Déploiement {#roll-out}

Lors de l'exécution dans votre pipeline CI/CD, l'analyse de sécurité des API s'exécute par défaut dans l'étape `dast`. Pour vous assurer que l'analyse de sécurité des API examine le code le plus récent, vérifiez que votre pipeline CI/CD déploie les modifications dans un environnement de test lors d'une étape précédant l'étape `dast`.

Si votre pipeline est configuré pour déployer sur le même serveur web à chaque exécution, le lancement d'un pipeline pendant qu'un autre est toujours en cours d'exécution pourrait provoquer une condition de concurrence dans laquelle un pipeline écrase le code d'un autre. L'API à analyser doit être exclue de toute modification pendant la durée d'une analyse de sécurité des API. Les seules modifications apportées à l'API doivent provenir de l'analyseur de test de sécurité des API. Les modifications apportées à l'API (par exemple, par des utilisateurs, des tâches planifiées, des modifications de base de données, des modifications de code, d'autres pipelines ou d'autres analyseurs) pendant une analyse pourraient entraîner des résultats inexacts.

### Exemples de configurations d'analyse de sécurité des API {#example-api-security-testing-scanning-configurations}

Les projets suivants illustrent l'analyse de sécurité des API :

- [Exemple de projet avec spécification OpenAPI v3](https://gitlab.com/gitlab-org/security-products/demos/api-dast/openapi-v3-example)
- [Exemple de projet avec spécification OpenAPI v2](https://gitlab.com/gitlab-org/security-products/demos/api-dast/openapi-example)
- [Exemple de projet HTTP Archive (HAR)](https://gitlab.com/gitlab-org/security-products/demos/api-dast/har-example)
- [Exemple de projet Collection Postman](https://gitlab.com/gitlab-org/security-products/demos/api-dast/postman-example)
- [Exemple de projet GraphQL](https://gitlab.com/gitlab-org/security-products/demos/api-dast/graphql-example)
- [Exemple de projet SOAP](https://gitlab.com/gitlab-org/security-products/demos/api-dast/soap-example)
- [Jeton d'authentification avec Selenium](https://gitlab.com/gitlab-org/security-products/demos/api-dast/auth-token-selenium)

### Options de déploiement d'application {#application-deployment-options}

Le test de sécurité des API nécessite qu'une application déployée soit disponible pour l'analyse.

Selon la complexité de l'application cible, plusieurs options sont disponibles pour déployer et configurer le modèle de test de sécurité des API.

#### Environnements éphémères {#review-apps}

Les environnements éphémères constituent la méthode la plus impliquée pour déployer votre application cible DAST. Pour faciliter le processus, GitLab a créé un déploiement d'environnement éphémère à l'aide de Google Kubernetes Engine (GKE). Cet exemple est disponible dans le projet [Review Apps - GKE](https://gitlab.com/gitlab-org/security-products/demos/dast/review-app-gke), avec des instructions détaillées pour configurer les environnements éphémères pour DAST dans le [README.md](https://gitlab.com/gitlab-org/security-products/demos/dast/review-app-gke/-/blob/master/README.md).

#### Services Docker {#docker-services}

Si votre application utilise des conteneurs Docker, vous disposez d'une autre option pour déployer et analyser avec DAST. Une fois que votre job de build Docker est terminé et que votre image est ajoutée à votre gistre de conteneurs, vous pouvez utiliser l'image en tant que [service](../../../ci/services/_index.md).

En utilisant des définitions de service dans votre `.gitlab-ci.yml`, vous pouvez analyser les services avec l'analyseur DAST.

Lors de l'ajout d'une section `services` au job, le champ `alias` est utilisé pour définir le nom d'hôte permettant d'accéder au service. Dans l'exemple suivant, la partie `alias: yourapp` de la définition du job `dast` signifie que l'URL de l'application déployée utilise `yourapp` comme nom d'hôte (`https://yourapp/`).

```yaml
stages:
  - build
  - dast

include:
  - template: API-Security.gitlab-ci.yml

# Deploys the container to the GitLab container registry
deploy:
  services:
  - name: docker:dind
    alias: dind
  image: docker:20.10.16
  stage: build
  script:
    - docker login -u gitlab-ci-token -p $CI_JOB_TOKEN $CI_REGISTRY
    - docker pull $CI_REGISTRY_IMAGE:latest || true
    - docker build --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA --tag $CI_REGISTRY_IMAGE:latest .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE:latest

api_security:
  services: # use services to link your app container to the dast job
    - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
      alias: yourapp

variables:
  APISEC_TARGET_URL: https://yourapp
```

La plupart des applications dépendent de plusieurs services tels que des bases de données ou des services de mise en cache. Par défaut, les services définis dans les champs services ne peuvent pas communiquer entre eux. Pour autoriser la communication entre les services, activez le feature flag `FF_NETWORK_PER_BUILD` [feature flag](https://docs.gitlab.com/runner/configuration/feature-flags/#available-feature-flags).

```yaml
variables:
  FF_NETWORK_PER_BUILD: "true" # enable network per build so all services can communicate on the same network

services: # use services to link the container to the dast job
  - name: mongo:latest
    alias: mongo
  - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    alias: yourapp
```

## Obtenir de l'aide ou demander une amélioration {#get-support-or-request-an-improvement}

Pour obtenir de l'aide concernant votre problème spécifique, utilisez les [canaux d'aide](https://about.gitlab.com/get-help/).

Le [système de suivi des tickets GitLab sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues) est l'endroit approprié pour les bogues et les propositions de fonctionnalités concernant le test de sécurité des API. Utilisez le label `~"Category:API Security"` lors de l'ouverture d'un nouveau ticket concernant le test de sécurité des API pour vous assurer qu'il est rapidement examiné par les bonnes personnes.

[Recherchez dans le système de suivi des tickets](https://gitlab.com/gitlab-org/gitlab/-/issues) des entrées similaires avant de soumettre la vôtre, il y a de bonnes chances que quelqu'un d'autre ait eu le même problème ou la même proposition de fonctionnalité. Montrez votre soutien avec une réaction emoji ou participez à la discussion.

Lorsque vous rencontrez un comportement qui ne fonctionne pas comme prévu, envisagez de fournir des informations contextuelles :

- Version de GitLab si vous utilisez une instance GitLab Self-Managed.
- Définition du job `.gitlab-ci.yml`.
- Sortie complète de la console du job.
- Fichier journal de l'analyseur disponible en tant qu'artefact de job nommé `gl-api-security-scanner.log`.

> [!warning]
> **Anonymiser les données jointes à un ticket d'assistance**. Supprimez les informations sensibles, notamment : les identifiants, les mots de passe, les jetons, les clés et les secrets.

## Glossaire {#glossary}

- Assert : Les assertions sont des modules de détection utilisés par les vérifications pour déclencher une vulnérabilité. De nombreuses assertions ont des configurations. Une vérification peut utiliser plusieurs assertions. Par exemple, l'analyse des journaux, l'analyse des réponses et le code de statut sont des assertions courantes utilisées conjointement par les vérifications. Les vérifications avec plusieurs assertions permettent de les activer et de les désactiver.
- Vérification (Check) : Effectue un type de test spécifique ou vérifie un type de vulnérabilité. Par exemple, la vérification d'injection SQL effectue des tests DAST pour les vulnérabilités d'injection SQL. L'analyseur de test de sécurité des API est composé de plusieurs vérifications. Les vérifications peuvent être activées et désactivées dans un profil.
- Profil : Un fichier de configuration comporte un ou plusieurs profils de test, ou sous-configurations. Vous pouvez avoir un profil pour les branches de fonctionnalités et un autre avec des tests supplémentaires pour une branche principale.
