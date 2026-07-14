---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Test de fuzzing d'API Web"
description: "Tests, sécurité, vulnérabilités, automatisation et erreurs."
---

{{< details >}}

- Édition : Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Le test de fuzzing d'API Web transmet des valeurs inattendues aux paramètres des opérations d'API pour provoquer des comportements inattendus et des erreurs dans le backend. Utilisez le test de fuzzing pour détecter des bugs et des vulnérabilités potentielles que d'autres processus d'assurance qualité pourraient manquer.

Vous devriez utiliser le test de fuzzing en complément des autres scanners de sécurité de [GitLab Secure](../_index.md) et de vos propres processus de test. Si vous utilisez [GitLab CI/CD](../../../ci/_index.md), vous pouvez exécuter des tests de fuzzing dans le cadre de votre flux de travail CI/CD.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une vue d'ensemble, consultez [Web API fuzzing - Advanced Security Testing](https://www.youtube.com/watch?v=oUHsfvLGhDk).

## Premiers pas {#getting-started}

Commencez avec le fuzzing d'API en modifiant votre configuration CI/CD.

Prérequis :

- Une API Web utilisant l'un des types d'API pris en charge :
  - API REST
  - SOAP
  - GraphQL
  - Corps de formulaire, JSON ou XML
- Une spécification d'API dans l'un des formats suivants :
  - Spécification OpenAPI v2 ou v3
  - Schéma GraphQL
  - HTTP Archive (HAR)
  - Postman Collection v2.0 ou v2.1
- Un GitLab Runner disponible avec l'exécuteur `docker` sur Linux/amd64.
- Une application cible déployée.
- L'étape `fuzz` est ajoutée à la définition de votre pipeline CI/CD, après l'étape `deploy` :

  ```yaml
  stages:
    - build
    - test
    - deploy
    - fuzz
  ```

Pour activer le fuzzing d'API :

- Utilisez le [formulaire de configuration du fuzzing d'API Web](configuration/enabling_the_analyzer.md#web-api-fuzzing-configuration-form).

  Le formulaire vous permet de choisir des valeurs pour les options de fuzzing d'API les plus courantes et génère un extrait YAML que vous pouvez coller dans votre configuration GitLab CI/CD.

## Comprendre les résultats {#understanding-the-results}

Pour afficher la sortie d'un scan de sécurité :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Pipelines**.
1. Sélectionnez le pipeline.
1. Sélectionnez l'onglet **Sécurité**.
1. Sélectionnez une vulnérabilité pour afficher ses détails, notamment :
   - Statut :  Indique si la vulnérabilité a été triée ou résolue.
   - Description :  Explique la cause de la vulnérabilité, son impact potentiel et les étapes de remédiation recommandées.
   - Gravité :  Classifiée en six niveaux selon l'impact. Pour plus d'informations, consultez [les niveaux de gravité](../vulnerabilities/severities.md).
   - Analyseur :  Identifie quel analyseur a détecté la vulnérabilité.
   - Méthode :  Établit le type d'interaction avec le serveur vulnérable.
   - URL :  Affiche l'emplacement de la vulnérabilité.
   - Preuve :  Décrit le cas de test pour prouver la présence d'une vulnérabilité donnée
   - Identifiants :  Une liste de références utilisées pour classifier la vulnérabilité, comme les identifiants CWE.

Vous pouvez également télécharger les résultats du scan de sécurité :

- Dans l'onglet **Sécurité** du pipeline, sélectionnez **Télécharger les résultats**.

Pour plus de détails, consultez le [rapport de sécurité du pipeline](../detect/security_scanning_results.md).

> [!note]
> Les résultats sont générés sur les branches de fonctionnalité. Lorsqu'ils sont fusionnés dans la branche par défaut, ils deviennent des vulnérabilités. Cette distinction est importante lors de l'évaluation de votre posture de sécurité.

## Optimisation {#optimization}

Pour tirer le meilleur parti du fuzzing d'API, suivez ces recommandations :

- Pour exécuter les dernières versions des analyseurs, configurez les runners pour utiliser `pull_policy: always`.
- Par défaut, le fuzzing d'API télécharge tous les artefacts définis par les jobs précédents dans le pipeline. Si votre job de fuzzing d'API ne dépend pas de `environment_url.txt` pour définir l'URL testée ou d'autres fichiers créés lors des jobs précédents, vous ne devriez pas télécharger les artefacts.

  Pour éviter de télécharger des artefacts, étendez le job CI/CD de l'analyseur afin de ne spécifier aucune dépendance. Par exemple, pour l'analyseur de fuzzing d'API, ajoutez ce qui suit à votre fichier `.gitlab-ci.yml` :

  ```yaml
  apifuzzer_fuzz:
    dependencies: []
  ```

### Options de déploiement d'application {#application-deployment-options}

Le fuzzing d'API nécessite qu'une application déployée soit disponible pour le scan.

Selon la complexité de l'application cible, plusieurs options sont disponibles pour déployer et configurer le modèle de fuzzing d'API.

#### Environnements éphémères {#review-apps}

Les environnements éphémères constituent la méthode la plus complexe pour déployer votre application cible de fuzzing d'API. Pour faciliter le processus, GitLab a créé un déploiement d'environnement éphémère à l'aide de Google Kubernetes Engine (GKE). Cet exemple se trouve dans le projet [Review apps - GKE](https://gitlab.com/gitlab-org/security-products/demos/dast/review-app-gke), accompagné d'instructions détaillées pour configurer les environnements éphémères dans DAST.

#### Services Docker {#docker-services}

Si votre application utilise des conteneurs Docker, vous disposez d'une autre option pour le déploiement et le scan avec le fuzzing d'API. Une fois que votre job de build Docker est terminé et que votre image est ajoutée à votre registre de conteneurs, vous pouvez utiliser l'image comme service.

En utilisant des définitions de service dans votre `.gitlab-ci.yml`, vous pouvez scanner des services avec l'analyseur DAST.

Lors de l'ajout d'une section `services` au job, le `alias` est utilisé pour définir le nom d'hôte permettant d'accéder au service. Dans l'exemple suivant, la partie `alias: yourapp` de la définition du job `dast` signifie que l'URL de l'application déployée utilise `yourapp` comme nom d'hôte : `https://yourapp/`.

```yaml
stages:
  - build
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

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

apifuzzer_fuzz:
  services: # use services to link your app container to the dast job
    - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
      alias: yourapp

variables:
  FUZZAPI_TARGET_URL: https://yourapp
```

La plupart des applications dépendent de plusieurs services, tels que des bases de données ou des services de mise en cache. Par défaut, les services définis dans les champs services ne peuvent pas communiquer entre eux. Pour permettre la communication entre services, activez le feature flag `FF_NETWORK_PER_BUILD`.

```yaml
variables:
  FF_NETWORK_PER_BUILD: "true" # enable network per build so all services can communicate on the same network

services: # use services to link the container to the dast job
  - name: mongo:latest
    alias: mongo
  - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    alias: yourapp
```

## Déploiement {#roll-out}

Le fuzzing d'API Web s'exécute dans l'étape `fuzz` du pipeline CI/CD. Pour s'assurer que le fuzzing d'API scanne le code le plus récent, votre pipeline CI/CD doit déployer les modifications dans un environnement de test lors d'une des étapes précédant l'étape `fuzz`.

Si votre pipeline est configuré pour déployer sur le même serveur web à chaque exécution, l'exécution d'un pipeline pendant qu'un autre est encore en cours pourrait provoquer une condition de concurrence dans laquelle un pipeline écrase le code d'un autre. L'API à scanner doit être exclue des modifications pendant toute la durée d'un scan de fuzzing. Les seules modifications apportées à l'API doivent provenir du scanner de fuzzing. Toute modification apportée à l'API (par exemple, par des utilisateurs, des tâches planifiées, des modifications de base de données, des modifications de code, d'autres pipelines ou d'autres scanners) pendant un scan pourrait entraîner des résultats inexacts.

Vous pouvez exécuter un scan de fuzzing d'API Web en utilisant les méthodes suivantes :

- Spécification OpenAPI (versions 2 et 3)
- Schéma GraphQL
- Archive HTTP (HAR)
- Collection Postman (versions 2.0 et 2.1)

### Exemples de projets de fuzzing d'API {#example-api-fuzzing-projects}

- [Exemple de projet de spécification OpenAPI v2](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing-example/-/tree/openapi)
- [Exemple de projet HTTP Archive (HAR)](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing-example/-/tree/har)
- [Exemple de projet Postman Collection](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/postman-api-fuzzing-example)
- [Exemple de projet GraphQL](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/graphql-api-fuzzing-example)
- [Exemple de projet SOAP](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/soap-api-fuzzing-example)
- [Token d'authentification avec Selenium](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/auth-token-selenium)

## Obtenir de l'aide ou demander une amélioration {#get-support-or-request-an-improvement}

Pour obtenir de l'aide concernant votre problème spécifique, utilisez les [canaux d'aide](https://about.gitlab.com/get-help/).

Le [système de suivi des tickets GitLab sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues) est l'endroit approprié pour signaler des bugs et proposer des fonctionnalités concernant la sécurité des API et le fuzzing d'API. Utilisez le label `~"Category:API Security"` lors de l'ouverture d'un nouveau ticket concernant le fuzzing d'API pour vous assurer qu'il est rapidement examiné par les bonnes personnes.

Recherchez dans le système de suivi des tickets les entrées similaires avant de soumettre la vôtre, il y a de bonnes chances que quelqu'un d'autre ait eu le même problème ou la même proposition de fonctionnalité. Montrez votre soutien avec une réaction emoji ou rejoignez la discussion.

Lorsque vous rencontrez un comportement qui ne fonctionne pas comme prévu, pensez à fournir des informations contextuelles :

- Version de GitLab si vous utilisez une instance GitLab Self-Managed.
- Définition du job `.gitlab-ci.yml`.
- Sortie complète de la console du job.
- Fichier journal du scanner disponible en tant qu'artefact de job nommé `gl-api-security-scanner.log`.

> [!warning]
> N'incluez pas d'informations sensibles lorsque vous soumettez un ticket. Supprimez les identifiants tels que les mots de passe, les tokens et les clés.

## Glossaire {#glossary}

- Assertion :  Les assertions sont des modules de détection utilisés par les vérifications pour déclencher un défaut. De nombreuses assertions ont des configurations. Une vérification peut utiliser plusieurs assertions. Par exemple, l'analyse de journaux, l'analyse de réponses et le code de statut sont des assertions couramment utilisées ensemble par les vérifications. Les vérifications avec plusieurs assertions permettent de les activer et de les désactiver.
- Vérification :  Effectue un type de test spécifique ou vérifie un type de vulnérabilité. Par exemple, la vérification de fuzzing JSON effectue des tests de fuzzing sur des charges utiles JSON. Le fuzzer d'API est composé de plusieurs vérifications. Les vérifications peuvent être activées et désactivées dans un profil.
- Défaut :  Lors du fuzzing, un échec identifié par une assertion est appelé un défaut. Les défauts sont examinés pour déterminer s'il s'agit d'une vulnérabilité de sécurité, d'un problème non lié à la sécurité ou d'un faux positif. Les défauts n'ont pas de type de vulnérabilité connu tant qu'ils n'ont pas été examinés. Les types de vulnérabilité courants sont l'injection SQL et le déni de service.
- Profil :  Un fichier de configuration contient un ou plusieurs profils de test, ou sous-configurations. Vous pouvez avoir un profil pour les branches de fonctionnalité et un autre avec des tests supplémentaires pour une branche principale.
