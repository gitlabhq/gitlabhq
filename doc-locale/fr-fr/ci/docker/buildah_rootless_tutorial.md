---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 'Tutoriel : Utiliser Buildah dans un conteneur sans privilèges root avec GitLab Runner Operator sur OpenShift'
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Ce tutoriel vous explique comment créer des images à l'aide de l'outil `buildah`, avec GitLab Runner déployé via [GitLab Runner Operator](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator) sur un cluster OpenShift.

Ce guide est une adaptation de la documentation [using Buildah to build images in a rootless OpenShift container](https://github.com/containers/buildah/blob/main/docs/tutorials/05-openshift-rootless-build.md) pour GitLab Runner Operator.

Pour suivre ce tutoriel, vous devrez :

1. Configurer l'image Buildah.
1. Configurer le compte de service.
1. Configurer le job.

## Avant de commencer {#before-you-begin}

Assurez-vous de disposer des éléments suivants avant de commencer ce tutoriel :

- Un runner déjà déployé dans un espace de nommage `gitlab-runner`.

## Configurer l'image Buildah {#configure-the-buildah-image}

Commencez par préparer une image personnalisée basée sur l'image `quay.io/buildah/stable:v1.23.1`.

1. Créez le fichier `Containerfile-buildah` :

   ```shell
   cat > Containerfile-buildah <<EOF
   FROM quay.io/buildah/stable:v1.23.1

   RUN touch /etc/subgid /etc/subuid \
   && chmod g=u /etc/subgid /etc/subuid /etc/passwd \
   && echo build:10000:65536 > /etc/subuid \
   && echo build:10000:65536 > /etc/subgid

   # Use chroot because the default runc does not work when running rootless
   RUN echo "export BUILDAH_ISOLATION=chroot" >> /home/build/.bashrc

   # Use VFS because fuse does not work
   RUN mkdir -p /home/build/.config/containers \
   && (echo '[storage]';echo 'driver = "vfs"') > /home/build/.config/containers/storage.conf

   # The buildah container will run as `build` user
   USER build
   WORKDIR /home/build
   EOF
   ```

1. Créez et envoyez l'image Buildah vers un registre de conteneurs. Envoyons-la vers le [registre de conteneurs GitLab](../../user/packages/container_registry/_index.md) :

   ```shell
   docker build -f Containerfile-buildah -t registry.example.com/group/project/buildah:1.23.1 .
   docker push registry.example.com/group/project/buildah:1.23.1
   ```

## Configurer le compte de service {#configure-the-service-account}

Pour ces étapes, vous devez exécuter les commandes dans un terminal connecté au cluster OpenShift.

1. Exécutez cette commande pour créer un compte de service nommé `buildah-sa` :

   ```shell
   oc create -f - <<EOF
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: buildah-sa
     namespace: gitlab-runner
   EOF
   ```

1. Accordez au compte de service créé la capacité de s'exécuter avec le [SCC](https://docs.openshift.com/container-platform/4.3/authentication/managing-security-context-constraints.html) `anyuid` :

   ```shell
   oc adm policy add-scc-to-user anyuid -z buildah-sa -n gitlab-runner
   ```

1. Utilisez un [modèle de configuration de runner](https://docs.gitlab.com/runner/configuration/configuring_runner_operator/#customize-configtoml-with-a-configuration-template) pour configurer Operator afin d'utiliser le nouveau compte de service. Créez un fichier `custom-config.toml` contenant :

   ```toml
   [[runners]]
     [runners.kubernetes]
         service_account_overwrite_allowed = "buildah-*"
   ```

1. Créez un `ConfigMap` nommé `custom-config-toml` à partir du fichier `custom-config.toml` :

   ```shell
   oc create configmap custom-config-toml --from-file config.toml=custom-config.toml -n gitlab-runner
   ```

1. Définissez la propriété `config` du `Runner` en mettant à jour son [fichier Custom Resource Definition (CRD)](https://docs.gitlab.com/runner/install/operator/#install-gitlab-runner) :

   ```yaml
   apiVersion: apps.gitlab.com/v1beta2
   kind: Runner
   metadata:
     name: buildah-runner
   spec:
     gitlabUrl: https://gitlab.example.com
     token: gitlab-runner-secret
     config: custom-config-toml
   ```

## Configurer le job {#configure-the-job}

La dernière étape consiste à configurer un fichier de configuration GitLab CI/CD dans votre projet pour utiliser la nouvelle image Buildah et le compte de service configuré :

```yaml
build:
  stage: build
  image: registry.example.com/group/project/buildah:1.23.1
  variables:
    STORAGE_DRIVER: vfs
    BUILDAH_FORMAT: docker
    BUILDAH_ISOLATION: chroot
    FQ_IMAGE_NAME: "$CI_REGISTRY_IMAGE/test"
    KUBERNETES_SERVICE_ACCOUNT_OVERWRITE: "buildah-sa"
  before_script:
    # Log in to the GitLab container registry
    - buildah login -u "$CI_REGISTRY_USER" --password $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - buildah images
    - buildah build -t $FQ_IMAGE_NAME
    - buildah images
    - buildah push $FQ_IMAGE_NAME
```

Le job doit utiliser l'image que vous avez créée comme valeur du mot-clé `image`.

La variable `KUBERNETES_SERVICE_ACCOUNT_OVERWRITE` doit avoir pour valeur le nom du compte de service que vous avez créé.

Félicitations, vous avez créé avec succès une image avec Buildah dans un conteneur sans privilèges root !

## Dépannage {#troubleshooting}

Il existe un [problème connu](https://github.com/containers/buildah/issues/4049) lors de l'exécution en tant que non-root. Vous devrez peut-être utiliser un [contournement](https://docs.gitlab.com/runner/configuration/configuring_runner_operator/#configure-setfcap) si vous utilisez un runner OpenShift.
