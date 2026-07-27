---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page,
  see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Accélérez les builds Docker-in-Docker en mettant en cache les couches d'image entre les exécutions de pipeline avec des backends de cache inline ou de registre."
title: Mettre en cache les couches Docker dans les builds Docker-in-Docker
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque vous utilisez Docker-in-Docker, Docker télécharge toutes les couches de votre image à chaque build. Docker 1.13 et versions ultérieures peuvent utiliser une image préexistante comme cache lors de l'étape `docker build`, ce qui accélère considérablement le processus de build.

Lorsque Docker exécute `docker build`, chaque commande `Dockerfile` crée une couche. Docker conserve ces couches en tant que cache et les réutilise si rien n'a changé. Une modification d'une couche entraîne la reconstruction de toutes les couches suivantes. Pour utiliser une image taguée comme source de cache pour `docker build`, passez l'argument `--cache-from`. Pour spécifier plusieurs sources de cache, utilisez `--cache-from` plusieurs fois.

## Prérequis {#prerequisites}

Dans Docker 27.0.1 et versions ultérieures, le driver de build `docker` par défaut ne prend en charge les backends de cache que lorsque le stockage d'images `containerd` est activé. Effectuez l'une des opérations suivantes :

- Activez le stockage d'images `containerd` dans la configuration de votre daemon Docker.
- Sélectionnez un driver de build différent.

## Utiliser le cache inline {#use-inline-caching}

Utilisez le backend de cache `inline` avec la commande `docker build` par défaut. Il s'agit de la méthode la plus simple pour démarrer avec la mise en cache. Le cache est stocké dans l'image elle-même, sans image de cache séparée requise. Pour les flux de build complexes ou les builds multi-étapes, utilisez plutôt [le cache de registre](#use-registry-caching). Pour plus d'informations, consultez [les options de cache inline](https://docs.docker.com/build/cache/backends/inline/).

> [!note]
> L'argument `--build-arg BUILDKIT_INLINE_CACHE=1` est requis. Il indique à Docker d'intégrer les métadonnées de cache dans l'image afin que les builds ultérieurs puissent l'utiliser comme source de cache avec `--cache-from`. Sans cet argument, la mise en cache échoue silencieusement.

Pour utiliser le cache inline dans votre pipeline :

1. Ajoutez la configuration `.gitlab-ci.yml` suivante à votre projet :

   ```yaml
   default:
     image: docker:27.4.1-cli
     services:
       - docker:27.4.1-dind
     before_script:
       - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY

   variables:
     # Use TLS https://docs.gitlab.com/ci/docker/using_docker_build/#tls-enabled
     DOCKER_HOST: tcp://docker:2376
     DOCKER_TLS_CERTDIR: "/certs"

   build:
     stage: build
     script:
       - docker pull $CI_REGISTRY_IMAGE:latest || true
       - docker build --build-arg BUILDKIT_INLINE_CACHE=1 --cache-from $CI_REGISTRY_IMAGE:latest
         --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA --tag $CI_REGISTRY_IMAGE:latest .
       - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
       - docker push $CI_REGISTRY_IMAGE:latest
   ```

   Dans le job `build`, section `script` :

   - La première commande tente de récupérer (pull) l'image depuis le registre de conteneurs pour l'utiliser comme source de cache. Toute image utilisée avec `--cache-from` doit être récupérée avec `docker pull` avant de pouvoir être utilisée.
   - La deuxième commande construit une image Docker en utilisant l'image récupérée comme cache (via `--cache-from $CI_REGISTRY_IMAGE:latest`), puis lui applique un tag. Le flag `--build-arg BUILDKIT_INLINE_CACHE=1` intègre le cache de build dans l'image.
   - Les deux dernières commandes poussent (push) les deux images taguées vers le registre de conteneurs afin qu'elles puissent être utilisées comme cache lors de futurs builds.

## Utiliser le cache de registre {#use-registry-caching}

Utilisez le backend de cache `registry` avec `docker buildx build` pour stocker le cache de build dans une image de cache dédiée, séparée de votre image d'application. Cette approche est plus adaptée que le cache inline pour les builds multi-étapes et les flux de build complexes. Pour plus d'informations, consultez [les options de backend de cache](https://docs.docker.com/build/cache/backends/).

Pour utiliser le cache de registre dans votre pipeline :

1. Ajoutez la configuration `.gitlab-ci.yml` suivante à votre projet :

   ```yaml
   default:
     image: docker:27.4.1-cli
     services:
       - docker:27.4.1-dind
     before_script:
       - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY

   variables:
     # Use TLS https://docs.gitlab.com/ci/docker/using_docker_build/#tls-enabled
     DOCKER_HOST: tcp://docker:2376
     DOCKER_TLS_CERTDIR: "/certs"

   build:
     stage: build
     script:
       - docker context create my-builder
       - docker buildx create my-builder --driver docker-container --use
       - docker buildx build --push -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
         --cache-to type=registry,ref=$CI_REGISTRY_IMAGE/cache-image,mode=max
         --cache-from type=registry,ref=$CI_REGISTRY_IMAGE/cache-image .
   ```

   Dans le job `build`, section `script` :

   - Les deux premières commandes créent et configurent le driver BuildKit `docker-container`, qui prend en charge le backend de cache `registry`.
   - La troisième commande construit et pousse (push) l'image Docker. Elle lit depuis une image de cache dédiée avec `--cache-from`, et la met à jour avec `--cache-to`. Le mode `max` met en cache toutes les couches intermédiaires.
