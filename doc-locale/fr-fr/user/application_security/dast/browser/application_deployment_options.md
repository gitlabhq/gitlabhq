---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Options de déploiement d'applications"
---

Le DAST nécessite qu'une application déployée soit disponible pour être analysée.

En fonction de la complexité de l'application cible, plusieurs options sont disponibles pour déployer et configurer le template DAST. Un ensemble d'exemples d'applications avec leurs configurations est disponible dans le projet [Démonstrations DAST](https://gitlab.com/gitlab-org/security-products/demos/dast/).

## Environnements éphémères {#review-apps}

Les environnements éphémères constituent la méthode la plus complexe pour déployer votre application cible DAST. Pour faciliter ce processus, GitLab a créé un déploiement d'environnement éphémère utilisant Google Kubernetes Engine (GKE). Cet exemple est disponible dans le projet [Review apps - GKE](https://gitlab.com/gitlab-org/security-products/demos/dast/review-app-gke), accompagné d'instructions détaillées pour configurer les environnements éphémères pour le DAST dans le [README](https://gitlab.com/gitlab-org/security-products/demos/dast/review-app-gke/-/blob/master/README.md).

## Services Docker {#docker-services}

Si votre application utilise des conteneurs Docker, vous disposez d'une autre option pour le déploiement et l'analyse avec le DAST. Une fois que votre job de build Docker est terminé et que votre image est ajoutée à votre registre de conteneurs, vous pouvez utiliser l'image en tant que [service](../../../../ci/services/_index.md).

En utilisant des définitions de service dans votre `.gitlab-ci.yml`, vous pouvez analyser des services avec l'analyseur DAST.

Lors de l'ajout d'une section `services` au job, la valeur `alias` est utilisée pour définir le nom d'hôte permettant d'accéder au service. Dans l'exemple suivant, la partie `alias: yourapp` de la définition du job `dast` signifie que l'URL vers l'application déployée utilise `yourapp` comme nom d'hôte (`https://yourapp/`).

```yaml
stages:
  - build
  - dast

include:
  - template: DAST.gitlab-ci.yml

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

dast:
  services: # use services to link your app container to the dast job
    - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
      alias: yourapp

variables:
  DAST_TARGET_URL: https://yourapp
  DAST_FULL_SCAN: "true" # do a full scan
  DAST_BROWSER_SCAN: "true" # use the browser-based GitLab DAST crawler
```

La plupart des applications dépendent de plusieurs services, tels que des bases de données ou des services de mise en cache. Par défaut, les services définis dans les champs de services ne peuvent pas communiquer entre eux. Pour autoriser la communication entre les services, activez le feature flag `FF_NETWORK_PER_BUILD` [feature flag](https://docs.gitlab.com/runner/configuration/feature-flags/#available-feature-flags).

```yaml
variables:
  FF_NETWORK_PER_BUILD: "true" # enable network per build so all services can communicate on the same network

services: # use services to link the container to the dast job
  - name: mongo:latest
    alias: mongo
  - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    alias: yourapp
```
