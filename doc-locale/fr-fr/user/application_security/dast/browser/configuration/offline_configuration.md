---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configuration hors ligne
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Pour les instances dans un environnement avec un accès limité, restreint ou intermittent aux ressources externes via Internet, certains ajustements sont nécessaires pour que le job DAST s'exécute correctement. Pour plus d'informations, consultez [Environnements hors ligne](../../../offline_deployments/_index.md).

## Prérequis pour la prise en charge de DAST hors ligne {#requirements-for-offline-dast-support}

Vous pouvez utiliser n'importe quelle version de DAST dans un environnement hors ligne. Pour ce faire, vous avez besoin :

- GitLab Runner avec l'exécuteur [`docker` ou `kubernetes`](../_index.md). Le runner doit disposer d'un accès réseau à l'application cible.
- Un registre de conteneurs Docker avec une copie locale disponible de l'[image de conteneur](https://gitlab.com/security-products/dast) DAST, disponible dans le [registre de conteneurs DAST](https://gitlab.com/security-products/dast/container_registry). Voir [Chargement des images Docker sur votre hôte hors ligne](../../../offline_deployments/_index.md#loading-docker-images-onto-your-offline-host).

GitLab Runner a une [valeur par défaut pour `pull policy` égale à `always`](https://docs.gitlab.com/runner/executors/docker/#using-the-always-pull-policy), ce qui signifie que le runner tente de télécharger des images Docker depuis le registre de conteneurs GitLab même si une copie locale est disponible. Le [`pull_policy` de GitLab Runner peut être défini sur `if-not-present`](https://docs.gitlab.com/runner/executors/docker/#using-the-if-not-present-pull-policy) dans un environnement hors ligne si vous préférez utiliser uniquement les images Docker disponibles localement. Cependant, vous devez conserver le paramètre de politique de récupération sur `always` si vous n'êtes pas dans un environnement hors ligne. Ce paramètre permet l'utilisation de scanners mis à jour dans vos pipelines CI/CD.

## Rendre les images de l'analyseur DAST GitLab disponibles dans votre registre Docker {#make-gitlab-dast-analyzer-images-available-inside-your-docker-registry}

Pour DAST, importez l'image d'analyseur DAST par défaut suivante depuis `registry.gitlab.com` vers votre [registre de conteneurs Docker local](../../../../packages/container_registry/_index.md) :

- `registry.gitlab.com/security-products/dast:latest`

Le processus d'importation des images Docker dans un registre de conteneurs Docker hors ligne local dépend de **votre politique de sécurité réseau**. Consultez votre service informatique pour trouver un processus accepté et approuvé par lequel les ressources externes peuvent être importées ou accessibles temporairement. Ces scanners sont [mis à jour périodiquement](../../../detect/vulnerability_scanner_maintenance.md) avec de nouvelles définitions, et vous pourrez peut-être effectuer des mises à jour occasionnelles par vous-même.

Pour plus d'informations sur l'enregistrement et le transport d'images Docker sous forme de fichier, consultez la documentation Docker sur [`docker save`](https://docs.docker.com/reference/cli/docker/image/save/), [`docker load`](https://docs.docker.com/reference/cli/docker/image/load/), [`docker export`](https://docs.docker.com/reference/cli/docker/container/export/) et [`docker import`](https://docs.docker.com/reference/cli/docker/image/import/).

## Définir les variables CI/CD du job DAST pour utiliser les analyseurs DAST locaux {#set-dast-cicd-job-variables-to-use-local-dast-analyzers}

Ajoutez la configuration suivante à votre fichier `.gitlab-ci.yml`. Vous devez remplacer `image` pour faire référence à l'image Docker DAST hébergée sur votre registre de conteneurs Docker local :

```yaml
include:
  - template: DAST.gitlab-ci.yml
dast:
  image: registry.example.com/namespace/dast:latest
```

Le job DAST devrait désormais utiliser des copies locales des analyseurs DAST pour analyser votre code et générer des rapports de sécurité sans nécessiter d'accès à Internet.

Vous pouvez également utiliser la variable CI/CD `SECURE_ANALYZERS_PREFIX` pour remplacer l'adresse du registre de base de l'image `dast`.
