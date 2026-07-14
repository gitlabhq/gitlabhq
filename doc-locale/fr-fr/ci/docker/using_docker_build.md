---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utiliser Docker pour créer des images Docker
description: "Créez et publiez des images de conteneurs dans GitLab CI/CD à l'aide de l'exécuteur shell, Docker-in-Docker, la liaison de socket ou la liaison de pipe."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez utiliser GitLab CI/CD avec Docker pour créer des images Docker. Par exemple, vous pouvez créer une image Docker de votre application, la tester et la publier dans un registre de conteneurs.

Pour exécuter des commandes Docker dans vos jobs CI/CD, vous devez configurer GitLab Runner pour prendre en charge les commandes `docker`. Cette méthode requiert le mode `privileged`.

Si vous souhaitez créer des images Docker sans activer le mode `privileged` sur le runner, vous pouvez utiliser une [alternative à Docker](#docker-alternatives).

## Activer les commandes Docker dans vos jobs CI/CD {#enable-docker-commands-in-your-cicd-jobs}

Pour activer les commandes Docker dans vos jobs CI/CD, vous pouvez utiliser :

- [L'exécuteur shell](#use-the-shell-executor)
- [Docker-in-Docker](#use-docker-in-docker)
- [Liaison de socket Docker](#use-docker-socket-binding)
- [Liaison de pipe Docker](#use-docker-pipe-binding)

### Utiliser l'exécuteur shell {#use-the-shell-executor}

Pour inclure des commandes Docker dans vos jobs CI/CD, vous pouvez configurer votre runner pour utiliser l'exécuteur `shell`. Dans cette configuration, l'utilisateur `gitlab-runner` exécute les commandes Docker, mais doit disposer des autorisations nécessaires.

1. [Installez](https://gitlab.com/gitlab-org/gitlab-runner/#installation) GitLab Runner.
1. [Enregistrez](https://docs.gitlab.com/runner/register/) un runner. Sélectionnez l'exécuteur `shell`. Par exemple :

   ```shell
   sudo gitlab-runner register -n \
     --url "https://gitlab.com/" \
     --registration-token REGISTRATION_TOKEN \
     --executor shell \
     --description "My Runner"
   ```

1. Sur le serveur où GitLab Runner est installé, installez Docker Engine. Consultez la liste des [plateformes prises en charge](https://docs.docker.com/engine/install/).

1. Ajoutez l'utilisateur `gitlab-runner` au groupe `docker` :

   ```shell
   sudo usermod -aG docker gitlab-runner
   ```

1. Vérifiez que `gitlab-runner` a accès à Docker :

   ```shell
   sudo -u gitlab-runner -H docker info
   ```

1. Dans GitLab, ajoutez `docker info` à `.gitlab-ci.yml` pour vérifier que Docker fonctionne :

   ```yaml
   default:
     before_script:
       - docker info
   build_image:
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

Vous pouvez désormais utiliser les commandes `docker` (et installer Docker Compose si nécessaire).

Lorsque vous ajoutez `gitlab-runner` au groupe `docker`, vous accordez effectivement à `gitlab-runner` des permissions root complètes. Pour plus d'informations, voir [sécurité du groupe `docker`](https://blog.zopyx.com/on-docker-security-docker-group-considered-harmful/).

### Utiliser Docker-in-Docker {#use-docker-in-docker}

« Docker-in-Docker » (`dind`) signifie :

- Votre runner enregistré utilise l'[exécuteur Docker](https://docs.gitlab.com/runner/executors/docker/) ou l'[exécuteur Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/).
- L'exécuteur utilise une [image de conteneur Docker](https://hub.docker.com/_/docker/), fournie par Docker, pour exécuter vos jobs CI/CD.

L'image Docker inclut tous les outils `docker` et peut exécuter le script du job dans le contexte de l'image en mode privilégié.

Vous devriez utiliser Docker-in-Docker avec TLS activé, ce qui est pris en charge par les [runners d'instance GitLab.com](../runners/_index.md).

Vous devriez toujours épingler une version spécifique de l'image, comme `docker:24.0.5`. Si vous utilisez un tag comme `docker:latest`, vous n'avez aucun contrôle sur la version utilisée. Cela peut provoquer des problèmes d'incompatibilité lors de la publication de nouvelles versions.

#### Utiliser l'exécuteur Docker avec Docker-in-Docker {#use-the-docker-executor-with-docker-in-docker}

Vous pouvez utiliser l'exécuteur Docker pour exécuter des jobs dans un conteneur Docker.

##### Docker-in-Docker avec TLS activé dans l'exécuteur Docker {#docker-in-docker-with-tls-enabled-in-the-docker-executor}

Le démon Docker prend en charge les connexions via TLS. TLS est la valeur par défaut dans Docker 19.03.12 et versions ultérieures.

> [!warning]
> Cette tâche active `--docker-privileged`, ce qui désactive effectivement les mécanismes de sécurité du conteneur et expose votre hôte à une élévation de privilèges. Cette action peut provoquer une évasion de conteneur. Pour plus d'informations, voir [les privilèges d'exécution et les capacités Linux](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities).

Pour utiliser Docker-in-Docker avec TLS activé :

1. Installez [GitLab Runner](https://docs.gitlab.com/runner/install/).
1. Enregistrez GitLab Runner depuis la ligne de commande. Utilisez le mode `docker` et `privileged` :

   ```shell
   sudo gitlab-runner register -n \
     --url "https://gitlab.com/" \
     --registration-token REGISTRATION_TOKEN \
     --executor docker \
     --description "My Docker Runner" \
     --tag-list "tls-docker-runner" \
     --docker-image "docker:24.0.5-cli" \
     --docker-privileged \
     --docker-volumes "/certs/client"
   ```

   - Cette commande enregistre un nouveau runner pour utiliser l'image `docker:24.0.5-cli` (si aucune n'est spécifiée au niveau du job). Pour démarrer les conteneurs de build et de service, elle utilise le mode `privileged`. Si vous souhaitez utiliser Docker-in-Docker, vous devez toujours utiliser `privileged = true` dans vos conteneurs Docker.
   - Cette commande monte `/certs/client` pour le conteneur de service et de build, ce qui est nécessaire pour que le client Docker utilise les certificats dans ce répertoire. Pour plus d'informations, voir [la documentation de l'image Docker](https://hub.docker.com/_/docker/).

   La commande précédente crée une entrée `config.toml` similaire à l'exemple suivant :

   ```toml
   [[runners]]
     url = "https://gitlab.com/"
     token = TOKEN
     executor = "docker"
     [runners.docker]
       tls_verify = false
       image = "docker:24.0.5-cli"
       privileged = true
       disable_cache = false
       volumes = ["/certs/client", "/cache"]
     [runners.cache]
       [runners.cache.s3]
       [runners.cache.gcs]
   ```

1. Vous pouvez désormais utiliser `docker` dans le script du job. Vous devriez inclure le service `docker:24.0.5-dind` :

   ```yaml
   default:
     image: docker:24.0.5-cli
     services:
       - docker:24.0.5-dind
     before_script:
       - docker info

   variables:
     # When you use the dind service, you must instruct Docker to talk with
     # the daemon started inside of the service. The daemon is available
     # with a network connection instead of the default
     # /var/run/docker.sock socket. Docker 19.03 does this automatically
     # by setting the DOCKER_HOST in
     # https://github.com/docker-library/docker/blob/d45051476babc297257df490d22cbd806f1b11e4/19.03/docker-entrypoint.sh#L23-L29
     #
     # The 'docker' hostname is the alias of the service container as described at
     # https://docs.gitlab.com/ci/services/#accessing-the-services.
     #
     # Specify to Docker where to create the certificates. Docker
     # creates them automatically on boot, and creates
     # `/certs/client` to share between the service and job
     # container, thanks to volume mount from config.toml
     DOCKER_TLS_CERTDIR: "/certs"

   build:
     stage: build
     tags:
       - tls-docker-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

##### Utiliser un socket Unix sur un volume partagé entre Docker-in-Docker et le conteneur de build {#use-a-unix-socket-on-a-shared-volume-between-docker-in-docker-and-build-container}

Les répertoires définis dans `volumes = ["/certs/client", "/cache"]` dans l'approche [Docker-in-Docker avec TLS activé dans l'exécuteur Docker](#docker-in-docker-with-tls-enabled-in-the-docker-executor) sont [persistants entre les builds](https://docs.gitlab.com/runner/executors/docker/#persistent-storage). Si plusieurs jobs CI/CD utilisant un runner avec l'exécuteur Docker ont les services Docker-in-Docker activés, chaque job écrit dans le chemin de répertoire. Cette approche peut entraîner un conflit.

Pour résoudre ce conflit, utilisez un socket Unix sur un volume partagé entre le service Docker-in-Docker et le conteneur de build. Cette approche améliore les performances et établit une connexion sécurisée entre le service et le client.

Voici un exemple de `config.toml` avec un volume temporaire partagé entre les conteneurs de build et de service :

```toml
[[runners]]
  url = "https://gitlab.com/"
  token = TOKEN
  executor = "docker"
  [runners.docker]
    image = "docker:24.0.5-cli"
    privileged = true
    volumes = ["/runner/services/docker"] # Temporary volume shared between build and service containers.
```

Le service Docker-in-Docker crée un `docker.sock`. Le client Docker se connecte à `docker.sock` via un volume de socket Unix Docker.

```yaml
job:
  variables:
    # This variable is shared by both the DinD service and Docker client.
    # For the service, it will instruct DinD to create `docker.sock` here.
    # For the client, it tells the Docker client which Docker Unix socket to connect to.
    DOCKER_HOST: "unix:///runner/services/docker/docker.sock"
  services:
    - docker:24.0.5-dind
  image: docker:24.0.5-cli
  script:
    - docker version
```

##### Docker-in-Docker avec TLS désactivé dans l'exécuteur Docker {#docker-in-docker-with-tls-disabled-in-the-docker-executor}

Il existe parfois des raisons légitimes de désactiver TLS. Par exemple, vous n'avez aucun contrôle sur la configuration de GitLab Runner que vous utilisez.

1. Enregistrez GitLab Runner depuis la ligne de commande. Utilisez le mode `docker` et `privileged` :

   ```shell
   sudo gitlab-runner register -n \
     --url "https://gitlab.com/" \
     --registration-token REGISTRATION_TOKEN \
     --executor docker \
     --description "My Docker Runner" \
     --tag-list "no-tls-docker-runner" \
     --docker-image "docker:24.0.5-cli" \
     --docker-privileged
   ```

   La commande précédente crée une entrée `config.toml` similaire à l'exemple suivant :

   ```toml
   [[runners]]
     url = "https://gitlab.com/"
     token = TOKEN
     executor = "docker"
     [runners.docker]
       tls_verify = false
       image = "docker:24.0.5-cli"
       privileged = true
       disable_cache = false
       volumes = ["/cache"]
     [runners.cache]
       [runners.cache.s3]
       [runners.cache.gcs]
   ```

1. Incluez le service `docker:24.0.5-dind` dans le script du job :

   ```yaml
   default:
     image: docker:24.0.5-cli
     services:
       - docker:24.0.5-dind
     before_script:
       - docker info

   variables:
     # When using dind service, you must instruct docker to talk with the
     # daemon started inside of the service. The daemon is available with
     # a network connection instead of the default /var/run/docker.sock socket.
     #
     # The 'docker' hostname is the alias of the service container as described at
     # https://docs.gitlab.com/ci/services/#accessing-the-services
     #
     DOCKER_HOST: tcp://docker:2375
     #
     # This instructs Docker not to start over TLS.
     DOCKER_TLS_CERTDIR: ""

   build:
     stage: build
     tags:
       - no-tls-docker-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

##### Docker-in-Docker avec proxy activé dans l'exécuteur Docker {#docker-in-docker-with-proxy-enabled-in-the-docker-executor}

Vous devrez peut-être configurer les paramètres de proxy pour utiliser la commande `docker push`.

Pour plus d'informations, voir [Paramètres de proxy lors de l'utilisation du service dind](https://docs.gitlab.com/runner/configuration/proxy/#proxy-settings-when-using-dind-service).

#### Utiliser l'exécuteur Kubernetes avec Docker-in-Docker {#use-the-kubernetes-executor-with-docker-in-docker}

Vous pouvez utiliser l'[exécuteur Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/) pour exécuter des jobs dans un conteneur Docker.

##### Docker-in-Docker avec TLS activé dans Kubernetes {#docker-in-docker-with-tls-enabled-in-kubernetes}

Pour utiliser Docker-in-Docker avec TLS activé dans Kubernetes :

1. À l'aide du [chart Helm](https://docs.gitlab.com/runner/install/kubernetes/), mettez à jour le [fichier `values.yml`](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/00c1a2098f303dffb910714752e9a981e119f5b5/values.yaml#L133-137) pour spécifier un montage de volume.

   ```yaml
   runners:
     tags: "tls-dind-kubernetes-runner"
     config: |
       [[runners]]
         [runners.kubernetes]
           image = "ubuntu:20.04"
           privileged = true
         [[runners.kubernetes.volumes.empty_dir]]
           name = "docker-certs"
           mount_path = "/certs/client"
           medium = "Memory"
   ```

1. Incluez le service `docker:24.0.5-dind` dans le job :

   ```yaml
   default:
     image: docker:24.0.5-cli
     services:
       - name: docker:24.0.5-dind
         variables:
           HEALTHCHECK_TCP_PORT: "2376"
     before_script:
       - docker info

   variables:
     # When using dind service, you must instruct Docker to talk with
     # the daemon started inside of the service. The daemon is available
     # with a network connection instead of the default
     # /var/run/docker.sock socket.
     DOCKER_HOST: tcp://docker:2376
     #
     # The 'docker' hostname is the alias of the service container as described at
     # https://docs.gitlab.com/ci/services/#accessing-the-services.
     #
     # Specify to Docker where to create the certificates. Docker
     # creates them automatically on boot, and creates
     # `/certs/client` to share between the service and job
     # container, thanks to volume mount from config.toml
     DOCKER_TLS_CERTDIR: "/certs"
     # These are usually specified by the entrypoint, however the
     # Kubernetes executor doesn't run entrypoints
     # https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4125
     DOCKER_TLS_VERIFY: 1
     DOCKER_CERT_PATH: "$DOCKER_TLS_CERTDIR/client"

   build:
     stage: build
     tags:
       - tls-dind-kubernetes-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

##### Docker-in-Docker avec TLS désactivé dans Kubernetes {#docker-in-docker-with-tls-disabled-in-kubernetes}

Pour utiliser Docker-in-Docker avec TLS désactivé dans Kubernetes, vous devez adapter l'exemple précédent pour :

- Supprimer la section `[[runners.kubernetes.volumes.empty_dir]]` du fichier `values.yml`.
- Changer le port de `2376` à `2375` avec `DOCKER_HOST: tcp://docker:2375`.
- Demander à Docker de démarrer avec TLS désactivé avec `DOCKER_TLS_CERTDIR: ""`.

Par exemple :

1. À l'aide du [chart Helm](https://docs.gitlab.com/runner/install/kubernetes/), mettez à jour le [fichier `values.yml`](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/00c1a2098f303dffb910714752e9a981e119f5b5/values.yaml#L133-137) :

   ```yaml
   runners:
     tags: "no-tls-dind-kubernetes-runner"
     config: |
       [[runners]]
         [runners.kubernetes]
           image = "ubuntu:20.04"
           privileged = true
   ```

1. Vous pouvez désormais utiliser `docker` dans le script du job. Vous devriez inclure le service `docker:24.0.5-dind` :

   ```yaml
   default:
     image: docker:24.0.5-cli
     services:
       - name: docker:24.0.5-dind
         variables:
           HEALTHCHECK_TCP_PORT: "2375"
     before_script:
       - docker info

   variables:
     # When using dind service, you must instruct Docker to talk with
     # the daemon started inside of the service. The daemon is available
     # with a network connection instead of the default
     # /var/run/docker.sock socket.
     DOCKER_HOST: tcp://docker:2375
     #
     # The 'docker' hostname is the alias of the service container as described at
     # https://docs.gitlab.com/ci/services/#accessing-the-services.
     #
     # This instructs Docker not to start over TLS.
     DOCKER_TLS_CERTDIR: ""
   build:
     stage: build
     tags:
       - no-tls-dind-kubernetes-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

#### Problèmes connus avec Docker-in-Docker {#known-issues-with-docker-in-docker}

Docker-in-Docker est la configuration recommandée, mais vous devez être conscient des problèmes suivants :

- **La commande `docker-compose`** : Cette commande n'est pas disponible dans cette configuration par défaut. Pour utiliser `docker-compose` dans vos scripts de jobs, suivez les [instructions d'installation](https://docs.docker.com/compose/install/) de Docker Compose.
- **Cache** : Chaque job s'exécute dans un nouvel environnement. Étant donné que chaque build obtient sa propre instance du moteur Docker, les jobs simultanés ne provoquent pas de conflits. Cependant, les jobs peuvent être plus lents car il n'y a pas de mise en cache des couches. Voir [la mise en cache des couches Docker](#docker-layer-caching).
- **Pilotes de stockage** : Par défaut, les versions antérieures de Docker utilisent le pilote de stockage `vfs`, qui copie le système de fichiers pour chaque job. Docker 17.09 et versions ultérieures utilisent `--storage-driver overlay2`, qui est le pilote de stockage recommandé. Voir [Utilisation du pilote OverlayFS](#use-the-overlayfs-driver) pour plus de détails.
- **Système de fichiers racine** : Étant donné que le conteneur `docker:24.0.5-dind` et le conteneur du runner ne partagent pas leur système de fichiers racine, vous pouvez utiliser le répertoire de travail du job comme point de montage pour les conteneurs enfants. Par exemple, si vous avez des fichiers à partager avec un conteneur enfant, vous pouvez créer un sous-répertoire sous `/builds/$CI_PROJECT_PATH` et l'utiliser comme point de montage. Pour une explication plus détaillée, voir le [ticket #41227](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/41227).

  ```yaml
  variables:
    MOUNT_POINT: /builds/$CI_PROJECT_PATH/mnt
  script:
    - mkdir -p "$MOUNT_POINT"
    - docker run -v "$MOUNT_POINT:/mnt" my-docker-image
  ```

### Utiliser la liaison de socket Docker {#use-docker-socket-binding}

Pour utiliser des commandes Docker dans vos jobs CI/CD, vous pouvez monter `/var/run/docker.sock` en liaison dans le conteneur de build. Docker est alors disponible dans le contexte de l'image.

Si vous liez le socket Docker, vous ne pouvez pas utiliser `docker:24.0.5-dind` comme service. Les liaisons de volumes affectent également les services, les rendant incompatibles.

#### Utiliser l'exécuteur Docker avec la liaison de socket Docker {#use-the-docker-executor-with-docker-socket-binding}

Pour monter le socket Docker avec l'exécuteur Docker, ajoutez `"/var/run/docker.sock:/var/run/docker.sock"` aux [volumes dans la section `[runners.docker]`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#volumes-in-the-runnersdocker-section).

1. Pour monter `/var/run/docker.sock` lors de l'enregistrement de votre runner, incluez les options suivantes :

   ```shell
   sudo gitlab-runner register \
     --non-interactive \
     --url "https://gitlab.com/" \
     --registration-token REGISTRATION_TOKEN \
     --executor "docker" \
     --description "docker-runner" \
     --tag-list "socket-binding-docker-runner" \
     --docker-image "docker:24.0.5-cli" \
     --docker-volumes "/var/run/docker.sock:/var/run/docker.sock"
   ```

   La commande précédente crée une entrée `config.toml` similaire à l'exemple suivant :

   ```toml
   [[runners]]
     url = "https://gitlab.com/"
     token = RUNNER_TOKEN
     executor = "docker"
     [runners.docker]
       tls_verify = false
       image = "docker:24.0.5-cli"
       privileged = false
       disable_cache = false
       volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]
     [runners.cache]
       Insecure = false
   ```

1. Utilisez Docker dans le script du job :

   ```yaml
   default:
     image: docker:24.0.5-cli
     before_script:
       - docker info

   build:
     stage: build
     tags:
       - socket-binding-docker-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

#### Utiliser l'exécuteur Kubernetes avec la liaison de socket Docker {#use-the-kubernetes-executor-with-docker-socket-binding}

Pour monter le socket Docker avec l'exécuteur Kubernetes, ajoutez `"/var/run/docker.sock"` aux [volumes dans la section `[[runners.kubernetes.volumes.host_path]]`](https://docs.gitlab.com/runner/executors/kubernetes/index/#hostpath-volume).

1. Pour spécifier un montage de volume, mettez à jour le [fichier `values.yml`](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/00c1a2098f303dffb910714752e9a981e119f5b5/values.yaml#L133-137) en utilisant le [chart Helm](https://docs.gitlab.com/runner/install/kubernetes/).

   ```yaml
   runners:
     tags: "socket-binding-kubernetes-runner"
     config: |
       [[runners]]
         [runners.kubernetes]
           image = "ubuntu:20.04"
           privileged = false
         [runners.kubernetes]
           [[runners.kubernetes.volumes.host_path]]
             host_path = '/var/run/docker.sock'
             mount_path = '/var/run/docker.sock'
             name = 'docker-sock'
             read_only = true
   ```

1. Utilisez Docker dans le script du job :

   ```yaml
   default:
     image: docker:24.0.5-cli
     before_script:
       - docker info
   build:
     stage: build
     tags:
       - socket-binding-kubernetes-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

#### Problèmes connus avec la liaison de socket Docker {#known-issues-with-docker-socket-binding}

Lorsque vous utilisez la liaison de socket Docker, vous évitez d'exécuter Docker en mode privilégié. Cependant, les implications de cette méthode sont les suivantes :

- Lorsque vous partagez le démon Docker, vous désactivez effectivement les mécanismes de sécurité du conteneur et exposez votre hôte à une élévation de privilèges. Cela peut provoquer une évasion de conteneur. Par exemple, si vous exécutez `docker rm -f $(docker ps -a -q)` dans un projet, cela supprime les conteneurs GitLab Runner.
- Les jobs simultanés peuvent ne pas fonctionner. Si vos tests créent des conteneurs avec des noms spécifiques, ils peuvent entrer en conflit les uns avec les autres.
- Tous les conteneurs créés par des commandes Docker sont des frères du runner, plutôt que des enfants du runner. Cela peut entraîner des complications dans votre workflow.
- Le partage de fichiers et de répertoires du dépôt source vers des conteneurs peut ne pas fonctionner comme prévu. Le montage de volumes s'effectue dans le contexte de la machine hôte, et non dans celui du conteneur de build. Par exemple :

  ```shell
  docker run --rm -t -i -v $(pwd)/src:/home/app/src test-image:latest run_app_tests
  ```

Vous n'avez pas besoin d'inclure le service `docker:24.0.5-dind`, comme vous le faites lorsque vous utilisez l'exécuteur Docker-in-Docker :

```yaml
default:
  image: docker:24.0.5-cli
  before_script:
    - docker info

build:
  stage: build
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

Pour les configurations Docker-in-Docker complexes telles que [l'analyse de la qualité du code avec CodeClimate](../testing/code_quality_codeclimate_scanning.md), vous devez faire correspondre les chemins de l'hôte et du conteneur pour une exécution correcte. Pour plus de détails, voir [Utiliser des runners privés pour l'analyse basée sur CodeClimate](../testing/code_quality_codeclimate_scanning.md#use-private-runners).

### Utiliser la liaison de pipe Docker {#use-docker-pipe-binding}

Les conteneurs Windows exécutent des exécutables Windows compilés pour le noyau et l'espace utilisateur de Windows Server (windowsservercore ou nanoserver). Pour créer et exécuter des conteneurs Windows, un système Windows avec prise en charge des conteneurs est requis. Pour plus d'informations, voir [Windows Containers](https://learn.microsoft.com/en-us/virtualization/windowscontainers/).

Étant donné que les conteneurs Windows [ne prennent pas en charge l'approche Docker-in-Docker](https://github.com/docker-library/docker/issues/49), vous ne pouvez pas exécuter un moteur Docker imbriqué dans un conteneur. Pour créer ou gérer des images Docker depuis un conteneur Windows, utilisez la liaison de pipe Docker (également connue sous le nom de Docker-outside-of-Docker ou DooD).

> [!warning]
> La liaison de pipe Docker a des implications en matière de sécurité. Lorsque vous montez `\\\\.\\pipe\\docker_engine` en liaison, le conteneur bénéficie d'un accès administratif complet au démon Docker de l'hôte. Les processus à l'intérieur du conteneur peuvent démarrer ou arrêter d'autres conteneurs, gérer des images et potentiellement obtenir des privilèges élevés sur le système hôte.

Pour utiliser la liaison de pipe Docker, vous devez installer et exécuter un moteur Docker sur le système d'exploitation Windows Server hôte. Pour plus d'informations, voir [Install Docker Community Edition (CE) on Windows Server](https://learn.microsoft.com/en-us/virtualization/windowscontainers/quick-start/set-up-environment?tabs=dockerce#windows-server-1).

Pour utiliser des commandes Docker dans vos jobs CI/CD basés sur des conteneurs Windows, vous pouvez monter `\\\\.\\pipe\\docker_engine` en liaison dans le conteneur d'exécuteur lancé. Docker est alors disponible dans le contexte de l'image.

La [liaison de pipe Docker sous Windows](#use-docker-pipe-binding) est similaire à la [liaison de socket Docker sous Linux](#use-docker-socket-binding) et présente des [problèmes connus](#known-issues-with-docker-pipe-binding) similaires aux [problèmes connus avec la liaison de socket Docker](#known-issues-with-docker-socket-binding).

Un prérequis obligatoire pour l'utilisation de la liaison de pipe Docker est un moteur Docker installé et en cours d'exécution sur le système d'exploitation Windows Server hôte. Voir : [Install Docker Community Edition (CE) on Windows Server](https://learn.microsoft.com/en-us/virtualization/windowscontainers/quick-start/set-up-environment?tabs=dockerce#windows-server-2)

#### Utiliser l'exécuteur Docker avec la liaison de pipe Docker {#use-the-docker-executor-with-docker-pipe-binding}

Vous pouvez utiliser l'[exécuteur Docker](https://docs.gitlab.com/runner/executors/docker/) pour exécuter des jobs dans un conteneur Windows.

Pour monter le pipe Docker avec l'exécuteur Docker, ajoutez `"\\\\.\\pipe\\docker_engine:\\\\.\\pipe\\docker_engine"` aux [volumes dans la section `[runners.docker]`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#volumes-in-the-runnersdocker-section).

1. Pour monter `\\\\.\\pipe\\docker_engine` lors de l'enregistrement de votre runner, incluez les options suivantes :

   ```powershell
   .\gitlab-runner.exe register \
     --non-interactive \
     --url "https://gitlab.com/" \
     --registration-token REGISTRATION_TOKEN \
     --executor "docker-windows" \
     --description "docker-windows-runner"
     --tag-list "docker-windows-runner" \
     --docker-image "docker:25-windowsservercore-ltsc2022" \
     --docker-volumes "\\\\.\\pipe\\docker_engine:\\\\.\\pipe\\docker_engine"
   ```

   La commande précédente crée une entrée `config.toml` similaire à l'exemple suivant :

   ```toml
   [[runners]]
     url = "https://gitlab.com/"
     token = RUNNER_TOKEN
     executor = "docker-windows"
     [runners.docker]
       tls_verify = false
       image = "docker:25-windowsservercore-ltsc2022"
       privileged = false
       disable_cache = false
       volumes = ["\\\\.\\pipe\\docker_engine:\\\\.\\pipe\\docker_engine"]
   ```

1. Utilisez Docker dans le script du job :

   ```yaml
   default:
     image: docker:25-windowsservercore-ltsc2022
     before_script:
       - docker version
       - docker info

   build:
     stage: build
     tags:
       - docker-windows-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

#### Utiliser l'exécuteur Kubernetes avec la liaison de pipe Docker {#use-the-kubernetes-executor-with-docker-pipe-binding}

Vous pouvez utiliser l'[exécuteur Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/) pour exécuter des jobs dans un conteneur Windows.

Pour utiliser l'exécuteur Kubernetes pour les conteneurs Windows, vous devez inclure des nœuds Windows dans votre cluster Kubernetes. Pour plus d'informations, voir [Conteneurs Windows dans Kubernetes](https://kubernetes.io/docs/concepts/windows/intro/).

Vous pouvez utiliser un [Runner fonctionnant dans un environnement Linux mais ciblant des nœuds Windows](https://docs.gitlab.com/runner/executors/kubernetes/#example-for-windowsamd64)

Pour monter le pipe Docker avec l'exécuteur Kubernetes, ajoutez `"\\.\pipe\docker_engine"` aux [volumes dans la section `[[runners.kubernetes.volumes.host_path]]`](https://docs.gitlab.com/runner/executors/kubernetes/index/#hostpath-volume).

1. Pour spécifier un montage de volume, mettez à jour le [fichier `values.yml`](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/00c1a2098f303dffb910714752e9a981e119f5b5/values.yaml#L133-137) en utilisant le [chart Helm](https://docs.gitlab.com/runner/install/kubernetes/).

   ```yaml
   runners:
     tags: "kubernetes-windows-runner"
     config: |
       [[runners]]
         executor = "kubernetes"

         # The FF_USE_POWERSHELL_PATH_RESOLVER feature flag has to be enabled for PowerShell
         # to resolve paths for Windows correctly when Runner is operating in a Linux environment
         # but targeting Windows nodes.
         [runners.feature_flags]
           FF_USE_POWERSHELL_PATH_RESOLVER = true

         [runners.kubernetes]
           [[runners.kubernetes.volumes.host_path]]
             host_path = '\\\\.\\pipe\\docker_engine'
             mount_path = '\\\\.\\pipe\\docker_engine'
             name = 'docker-pipe'
             read_only = true

           [runners.kubernetes.node_selector]
             "kubernetes.io/arch" = "amd64"
             "kubernetes.io/os" = "windows"
             "node.kubernetes.io/windows-build" = "10.0.20348"
   ```

1. Utilisez Docker dans le script du job :

   ```yaml
   default:
     image: docker:25-windowsservercore-ltsc2022
     before_script:
       - docker version
       - docker info

   build:
     stage: build
     tags:
       - kubernetes-windows-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

##### Problèmes connus avec le cluster Kubernetes AWS EKS {#known-issues-with-aws-eks-kubernetes-cluster}

Lorsque vous migrez de `dockerd` vers `containerd`, le script de démarrage AWS EKS `Start-EKSBootstrap.ps1` arrête et désactive le service Docker. Pour contourner ce problème, renommez le service Docker après avoir [installé Docker Community Edition (CE) sur Windows Server](https://learn.microsoft.com/en-us/virtualization/windowscontainers/quick-start/set-up-environment?tabs=dockerce#windows-server-1) avec ce script :

```powershell
Write-Output "Rename the just installed Docker Engine Service from docker to dockerd"
Write-Output "because the Start-EKSBootstrap.ps1 stops and disables the docker Service as part of migration from dockerd to containerd"
Stop-Service -Name docker
dockerd --register-service --service-name dockerd
Start-Service -Name dockerd
Write-Output "Ready to do Docker pipe binding on Windows EKS Node! :-)"
```

#### Problèmes connus avec la liaison de pipe Docker {#known-issues-with-docker-pipe-binding}

La liaison de pipe Docker présente le même ensemble de problèmes de sécurité et d'isolation que les [problèmes connus avec la liaison de socket Docker](#known-issues-with-docker-socket-binding).

## Activer le miroir de registre pour le service `docker:dind` {#enable-registry-mirror-for-dockerdind-service}

Lorsque le démon Docker démarre à l'intérieur du conteneur de service, il utilise la configuration par défaut. Vous pouvez configurer un [miroir de registre](https://docs.docker.com/docker-hub/mirror/) pour améliorer les performances et vous assurer de ne pas dépasser les limites de débit de Docker Hub.

### Le service dans le fichier `.gitlab-ci.yml` {#the-service-in-the-gitlab-ciyml-file}

Vous pouvez ajouter des indicateurs CLI supplémentaires au service `dind` pour définir le miroir de registre :

```yaml
services:
  - name: docker:24.0.5-dind
    command: ["--registry-mirror", "https://registry-mirror.example.com"]  # Specify the registry mirror to use
```

### Le service dans le fichier de configuration GitLab Runner {#the-service-in-the-gitlab-runner-configuration-file}

Si vous êtes administrateur GitLab Runner, vous pouvez spécifier la `command` pour configurer le miroir de registre pour le démon Docker. Le service `dind` doit être défini pour l'[exécuteur Docker](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runnersdockerservices-section) ou l'[exécuteur Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/#define-a-list-of-services).

Docker :

```toml
[[runners]]
  ...
  executor = "docker"
  [runners.docker]
    ...
    privileged = true
    [[runners.docker.services]]
      name = "docker:24.0.5-dind"
      command = ["--registry-mirror", "https://registry-mirror.example.com"]
```

Kubernetes :

```toml
[[runners]]
  ...
  name = "kubernetes"
  [runners.kubernetes]
    ...
    privileged = true
    [[runners.kubernetes.services]]
      name = "docker:24.0.5-dind"
      command = ["--registry-mirror", "https://registry-mirror.example.com"]
```

### L'exécuteur Docker dans le fichier de configuration GitLab Runner {#the-docker-executor-in-the-gitlab-runner-configuration-file}

Si vous êtes administrateur GitLab Runner, vous pouvez utiliser le miroir pour chaque service `dind`. Mettez à jour la [configuration](https://docs.gitlab.com/runner/configuration/advanced-configuration/) pour spécifier un [montage de volume](https://docs.gitlab.com/runner/configuration/advanced-configuration/#volumes-in-the-runnersdocker-section).

Par exemple, si vous disposez d'un fichier `/opt/docker/daemon.json` avec le contenu suivant :

```json
{
  "registry-mirrors": [
    "https://registry-mirror.example.com"
  ]
}
```

Mettez à jour le fichier `config.toml` pour monter le fichier vers `/etc/docker/daemon.json`. Cela monte le fichier pour **chaque** conteneur créé par GitLab Runner. La configuration est détectée par le service `dind`.

```toml
[[runners]]
  ...
  executor = "docker"
  [runners.docker]
    image = "alpine:3.12"
    privileged = true
    volumes = ["/opt/docker/daemon.json:/etc/docker/daemon.json:ro"]
```

### L'exécuteur Kubernetes dans le fichier de configuration GitLab Runner {#the-kubernetes-executor-in-the-gitlab-runner-configuration-file}

Si vous êtes administrateur GitLab Runner, vous pouvez utiliser le miroir pour chaque service `dind`. Mettez à jour la [configuration](https://docs.gitlab.com/runner/configuration/advanced-configuration/) pour spécifier un [montage de volume ConfigMap](https://docs.gitlab.com/runner/executors/kubernetes/#configmap-volume).

Par exemple, si vous disposez d'un fichier `/tmp/daemon.json` avec le contenu suivant :

```json
{
  "registry-mirrors": [
    "https://registry-mirror.example.com"
  ]
}
```

Créez un [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) avec le contenu de ce fichier. Vous pouvez le faire avec une commande telle que :

```shell
kubectl create configmap docker-daemon --namespace gitlab-runner --from-file /tmp/daemon.json
```

> [!note]
> Vous devez utiliser l'espace de nommage que l'exécuteur Kubernetes pour GitLab Runner utilise pour créer les pods de jobs.

Une fois le ConfigMap créé, vous pouvez mettre à jour le fichier `config.toml` pour monter le fichier vers `/etc/docker/daemon.json`. Cette mise à jour monte le fichier pour **chaque** conteneur créé par GitLab Runner. Le service `dind` détecte cette configuration.

```toml
[[runners]]
  ...
  executor = "kubernetes"
  [runners.kubernetes]
    image = "alpine:3.12"
    privileged = true
    [[runners.kubernetes.volumes.config_map]]
      name = "docker-daemon"
      mount_path = "/etc/docker/daemon.json"
      sub_path = "daemon.json"
```

## S'authentifier auprès du registre dans Docker-in-Docker {#authenticate-with-registry-in-docker-in-docker}

Lorsque vous utilisez Docker-in-Docker, les [méthodes d'authentification standard](using_docker_images.md#access-an-image-from-a-private-container-registry) ne fonctionnent pas, car un nouveau démon Docker est démarré avec le service. Vous devriez [vous authentifier auprès du registre](authenticate_registry.md).

## Mise en cache des couches Docker {#docker-layer-caching}

Vous pouvez mettre en cache les couches Docker pour accélérer vos builds. Pour plus d'informations, voir [Mettre en cache les couches Docker dans les builds Docker-in-Docker](docker_layer_caching.md).

## Utiliser le pilote OverlayFS {#use-the-overlayfs-driver}

> [!note]
> Les runners d'instance sur GitLab.com utilisent le pilote `overlay2` par défaut.

Par défaut, lors de l'utilisation de `docker:dind`, Docker utilise le pilote de stockage `vfs`, qui copie le système de fichiers à chaque exécution. Vous pouvez éviter cette opération intensive en termes d'E/S disque en utilisant un pilote différent, par exemple `overlay2`.

### Prérequis {#requirements}

1. Assurez-vous qu'un noyau récent est utilisé, de préférence `>= 4.2`.
1. Vérifiez si le module `overlay` est chargé :

   ```shell
   sudo lsmod | grep overlay
   ```

   Si vous ne voyez aucun résultat, le module n'est pas chargé. Pour charger le module, utilisez :

   ```shell
   sudo modprobe overlay
   ```

   Si le module est chargé, vous devez vous assurer qu'il se charge au redémarrage. Sur les systèmes Ubuntu, faites-le en ajoutant la ligne suivante à `/etc/modules` :

   ```plaintext
   overlay
   ```

### Utiliser le pilote OverlayFS par projet {#use-the-overlayfs-driver-per-project}

Vous pouvez activer le pilote pour chaque projet individuellement en utilisant la [variable CI/CD](../yaml/_index.md#variables) `DOCKER_DRIVER` dans `.gitlab-ci.yml` :

```yaml
variables:
  DOCKER_DRIVER: overlay2
```

### Utiliser le pilote OverlayFS pour chaque projet {#use-the-overlayfs-driver-for-every-project}

Si vous utilisez vos propres [runners](https://docs.gitlab.com/runner/), vous pouvez activer le pilote pour chaque projet en définissant la variable CI/CD d'environnement `DOCKER_DRIVER` dans la [section `[[runners]]` du fichier `config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section) :

```toml
environment = ["DOCKER_DRIVER=overlay2"]
```

Si vous exécutez plusieurs runners, vous devez modifier tous les fichiers de configuration.

En savoir plus sur la [configuration des runners](https://docs.gitlab.com/runner/configuration/) et l'[utilisation du pilote de stockage OverlayFS](https://docs.docker.com/storage/storagedriver/overlayfs-driver/).

## Alternatives à Docker {#docker-alternatives}

Vous pouvez créer des images de conteneurs sans activer le mode privilégié sur votre runner :

- [BuildKit](using_buildkit.md) : Inclut des options BuildKit sans root qui éliminent la dépendance au démon Docker.
- [Buildah](#buildah-example) : Créez des images conformes OCI sans avoir besoin d'un démon Docker.

### Exemple Buildah {#buildah-example}

Pour utiliser Buildah avec GitLab CI/CD, vous avez besoin d'[un runner](https://docs.gitlab.com/runner/) avec l'un des exécuteurs suivants :

- [Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/).
- [Docker](https://docs.gitlab.com/runner/executors/docker/).
- [Docker Machine](https://docs.gitlab.com/runner/executors/docker_machine/).

Dans cet exemple, vous utilisez Buildah pour :

1. Créer une image Docker.
1. La publier dans le [registre de conteneurs GitLab](../../user/packages/container_registry/_index.md).

Dans la dernière étape, Buildah utilise le `Dockerfile` situé dans le répertoire racine du projet pour créer l'image Docker. Enfin, il publie l'image dans le registre de conteneurs du projet :

```yaml
build:
  stage: build
  image: quay.io/buildah/stable
  variables:
    # Use vfs with buildah. Docker offers overlayfs as a default, but Buildah
    # cannot stack overlayfs on top of another overlayfs filesystem.
    STORAGE_DRIVER: vfs
    # Write all image metadata in the docker format, not the standard OCI format.
    # Newer versions of docker can handle the OCI format, but older versions, like
    # the one shipped with Fedora 30, cannot handle the format.
    BUILDAH_FORMAT: docker
    FQ_IMAGE_NAME: "$CI_REGISTRY_IMAGE/test"
  before_script:
    # GitLab container registry credentials taken from the
    # [predefined CI/CD variables](../variables/_index.md#predefined-cicd-variables)
    # to authenticate to the registry.
    - echo "$CI_REGISTRY_PASSWORD" | buildah login -u "$CI_REGISTRY_USER" --password-stdin $CI_REGISTRY
  script:
    - buildah images
    - buildah build -t $FQ_IMAGE_NAME
    - buildah images
    - buildah push $FQ_IMAGE_NAME
```

Si vous utilisez GitLab Runner Operator déployé sur un cluster OpenShift, essayez le [tutoriel d'utilisation de Buildah pour créer des images dans un conteneur sans root](buildah_rootless_tutorial.md).

## Utiliser le registre de conteneurs GitLab {#use-the-gitlab-container-registry}

Après avoir créé une image Docker, vous pouvez la publier dans le [registre de conteneurs GitLab](../../user/packages/container_registry/build_and_push_images.md#use-gitlab-cicd).

## Dépannage {#troubleshooting}

### `open //./pipe/docker_engine: The system cannot find the file specified` {#open-pipedocker_engine-the-system-cannot-find-the-file-specified}

L'erreur suivante peut apparaître lorsque vous exécutez une commande `docker` dans le script PowerShell pour accéder au pipe Docker monté :

```powershell
PS C:\> docker version
Client:
 Version:           25.0.5
 API version:       1.44
 Go version:        go1.21.8
 Git commit:        5dc9bcc
 Built:             Tue Mar 19 15:06:12 2024
 OS/Arch:           windows/amd64
 Context:           default
error during connect: this error may indicate that the docker daemon is not running: Get "http://%2F%2F.%2Fpipe%2Fdocker_engine/v1.44/version": open //./pipe/docker_engine: The system cannot find the file specified.
```

L'erreur indique que le moteur Docker n'est pas en cours d'exécution sur le nœud Windows EKS et que la liaison de pipe Docker n'a pas pu être utilisée dans le conteneur d'exécuteur Windows.

Pour résoudre le problème, utilisez la solution de contournement décrite dans [Utiliser l'exécuteur Kubernetes avec la liaison de pipe Docker](#use-the-kubernetes-executor-with-docker-pipe-binding).
