---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utiliser Buildah pour créer des images multi-plateformes
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez Buildah pour créer des images pour plusieurs architectures de CPU. Les builds multi-plateformes créent des images qui fonctionnent sur différentes plateformes matérielles, et Docker sélectionne automatiquement l'image appropriée pour chaque cible de déploiement.

## Prérequis {#prerequisites}

- Un Dockerfile à partir duquel créer l'image
- (Facultatif) Des runners GitLab s'exécutant sur différentes architectures de CPU

## Créer des images multi-plateformes {#build-multi-platform-images}

Pour créer des images multi-plateformes avec Buildah :

1. Configurez des jobs de build distincts pour chaque architecture cible.
1. Créez un job de manifeste qui combine les images spécifiques à chaque architecture.
1. Configurez le job de manifeste pour pousser le manifeste combiné vers votre registre.

L'exécution des jobs sur leurs architectures respectives permet d'éviter les problèmes de performances liés à la traduction des instructions CPU. Cependant, vous pouvez exécuter les deux builds sur une seule architecture si nécessaire. La compilation pour une architecture non native peut entraîner des temps de build plus longs.

L'exemple suivant utilise deux [runners GitLab hébergés sur Linux](../runners/hosted_runners/linux.md) :

- `saas-linux-small-arm64`
- `saas-linux-small-amd64`

```yaml
stages:
  - build

variables:
  STORAGE_DRIVER: vfs
  BUILDAH_FORMAT: docker
  FQ_IMAGE_NAME: "$CI_REGISTRY_IMAGE:latest"

default:
  image: quay.io/buildah/stable
  before_script:
    - echo "$CI_REGISTRY_PASSWORD" | buildah login -u "$CI_REGISTRY_USER" --password-stdin $CI_REGISTRY

build-amd64:
  stage: build
  tags:
    - saas-linux-small-amd64
  script:
    - buildah build --platform=linux/amd64 -t $CI_REGISTRY_IMAGE:amd64 .
    - buildah push $CI_REGISTRY_IMAGE:amd64

build-arm64:
  stage: build
  tags:
    - saas-linux-small-arm64
  script:
    - buildah build --platform=linux/arm64/v8 -t $CI_REGISTRY_IMAGE:arm64 .
    - buildah push $CI_REGISTRY_IMAGE:arm64

create_manifest:
  stage: build
  needs: ["build-arm64", "build-amd64"]
  tags:
    - saas-linux-small-amd64
  script:
    - buildah manifest create $FQ_IMAGE_NAME
    - buildah manifest add $FQ_IMAGE_NAME docker://$CI_REGISTRY_IMAGE:amd64
    - buildah manifest add $FQ_IMAGE_NAME docker://$CI_REGISTRY_IMAGE:arm64
    - buildah manifest push --all $FQ_IMAGE_NAME
```

Ce pipeline crée des images spécifiques à chaque architecture, taguées avec `amd64` et `arm64`, puis les combine en un seul manifeste disponible sous le tag `latest`.

## Dépannage {#troubleshooting}

### Le build échoue avec des erreurs d'authentification {#build-fails-with-authentication-errors}

Si vous rencontrez des échecs d'authentification au registre :

- Vérifiez que les variables CI/CD `CI_REGISTRY_USER` et `CI_REGISTRY_PASSWORD` sont disponibles.
- Vérifiez que vous disposez des autorisations de push vers le registre cible.
- Pour les registres externes, assurez-vous que les identifiants d'authentification sont correctement configurés dans les variables CI/CD de votre projet.

### Les builds multi-plateformes échouent {#multi-platform-builds-fail}

Pour les problèmes de build multi-plateformes :

- Vérifiez que les images de base dans votre `Dockerfile` prennent en charge les architectures cibles.
- Vérifiez que les dépendances spécifiques à chaque architecture sont disponibles pour toutes les plateformes cibles.
- Envisagez d'utiliser des instructions conditionnelles dans votre `Dockerfile` pour la logique spécifique à chaque architecture.

### Erreur : `Error during unshare(CLONE_NEWUSER): Operation not permitted` {#error-error-during-unshareclone_newuser-operation-not-permitted}

Lorsque vous utilisez Buildah ou [Docker BuildKit](using_buildkit.md) en mode rootless pour créer des images Docker dans des jobs CI/CD, vous pourriez rencontrer une erreur `Error during unshare(CLONE_NEWUSER): Operation not permitted`.

Cette erreur se produit lorsque les options de sécurité requises ne sont pas définies pour les builds de conteneurs rootless.

Pour résoudre ce problème, configurez la section `[runners.docker]` dans le fichier `config.toml` du runner :

```toml
[runners.docker]
  security_opt = ["seccomp:unconfined", "apparmor:unconfined"]
```

Pour plus d'informations, consultez [Builds Docker rootless BuildKit et exigences de sécurité](https://github.com/moby/buildkit/blob/master/docs/rootless.md#docker).
