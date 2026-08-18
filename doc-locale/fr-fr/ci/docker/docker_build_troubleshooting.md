---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Résolution des problèmes de Docker Build
---

## Erreur : `docker: Cannot connect to the Docker daemon at tcp://docker:2375` {#error-docker-cannot-connect-to-the-docker-daemon-at-tcpdocker2375}

Cette erreur est courante lorsque vous utilisez [Docker-in-Docker](using_docker_build.md#use-docker-in-docker) v19.03 ou une version ultérieure :

```plaintext
docker: Cannot connect to the Docker daemon at tcp://docker:2375. Is the docker daemon running?
```

Cette erreur se produit parce que Docker démarre automatiquement sur TLS.

- Si vous effectuez cette configuration pour la première fois, consultez [utiliser l'exécuteur Docker avec l'image Docker](using_docker_build.md#use-docker-in-docker).
- Si vous effectuez une mise à niveau depuis la version v18.09 ou une version antérieure, consultez le [guide de mise à niveau](https://about.gitlab.com/blog/docker-in-docker-with-docker-19-dot-03/).

Cette erreur peut également se produire avec l'[exécuteur Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/#using-dockerdind) lorsque des tentatives d'accès au service Docker-in-Docker sont effectuées avant que celui-ci ne soit complètement démarré. Pour une explication plus détaillée, consultez le [ticket 27215](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27215).

## Erreur Docker `no such host` {#docker-no-such-host-error}

Vous pourriez obtenir une erreur indiquant `docker: error during connect: Post https://docker:2376/v1.40/containers/create: dial tcp: lookup docker on x.x.x.x:53: no such host`.

Ce problème peut se produire lorsque le nom d'image du service [inclut un nom d'hôte de registre](../services/_index.md#available-settings-for-services). Par exemple :

```yaml
default:
  image: docker:24.0.5-cli
  services:
    - registry.hub.docker.com/library/docker:24.0.5-dind
```

Le nom d'hôte d'un service est [dérivé du nom d'image complet](../services/_index.md#accessing-the-services). Cependant, le nom d'hôte de service abrégé `docker` est attendu. Pour permettre la résolution et l'accès au service, ajoutez un alias explicite pour le nom de service `docker` :

```yaml
default:
  image: docker:24.0.5-cli
  services:
    - name: registry.hub.docker.com/library/docker:24.0.5-dind
      alias: docker
```

## Erreur : `Cannot connect to the Docker daemon at unix:///var/run/docker.sock` {#error-cannot-connect-to-the-docker-daemon-at-unixvarrundockersock}

Vous pourriez obtenir l'erreur suivante en tentant d'exécuter une commande `docker` pour accéder à un service `dind` :

```shell
$ docker ps
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
```

Assurez-vous que votre job a défini ces variables d'environnement :

- `DOCKER_HOST`
- `DOCKER_TLS_CERTDIR` (facultatif)
- `DOCKER_TLS_VERIFY` (facultatif)

Vous pouvez également mettre à jour l'image qui fournit le client Docker. Par exemple, les [images `docker/compose` sont obsolètes](https://hub.docker.com/r/docker/compose) et doivent être remplacées par [`docker`](https://hub.docker.com/_/docker).

Comme décrit dans le [ticket de runner 30944](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30944#note_1514250909), cette erreur peut se produire si votre job reposait précédemment sur des variables d'environnement dérivées du paramètre Docker [`--link` obsolète](https://docs.docker.com/network/links/#environment-variables), telles que `DOCKER_PORT_2375_TCP`. Votre job échoue avec cette erreur si :

- Votre image CI/CD repose sur une variable héritée, telle que `DOCKER_PORT_2375_TCP`.
- Le [feature flag de runner `FF_NETWORK_PER_BUILD`](https://docs.gitlab.com/runner/configuration/feature-flags/) est défini sur `true`.
- `DOCKER_HOST` n'est pas défini explicitement.

## Erreur : `unauthorized: incorrect username or password` {#error-unauthorized-incorrect-username-or-password}

Cette erreur apparaît lorsque vous utilisez la variable obsolète `CI_BUILD_TOKEN` :

```plaintext
Error response from daemon: Get "https://registry-1.docker.io/v2/": unauthorized: incorrect username or password
```

Pour éviter que les utilisateurs reçoivent cette erreur, vous devez :

- Utiliser [CI_JOB_TOKEN](../jobs/ci_job_token.md) à la place.
- Passer de `gitlab-ci-token/CI_BUILD_TOKEN` à `$CI_REGISTRY_USER/$CI_REGISTRY_PASSWORD`.

## Erreur lors de la connexion : `no such host` {#error-during-connect-no-such-host}

Cette erreur apparaît lorsque le service `dind` n'a pas réussi à démarrer :

```plaintext
error during connect: Post "https://docker:2376/v1.24/auth": dial tcp: lookup docker on 127.0.0.11:53: no such host
```

Consultez le job log pour vérifier si `mount: permission denied (are you root?)` apparaît. Par exemple :

```plaintext
Service container logs:
2023-08-01T16:04:09.541703572Z Certificate request self-signature ok
2023-08-01T16:04:09.541770852Z subject=CN = docker:dind server
2023-08-01T16:04:09.556183222Z /certs/server/cert.pem: OK
2023-08-01T16:04:10.641128729Z Certificate request self-signature ok
2023-08-01T16:04:10.641173149Z subject=CN = docker:dind client
2023-08-01T16:04:10.656089908Z /certs/client/cert.pem: OK
2023-08-01T16:04:10.659571093Z ip: can't find device 'ip_tables'
2023-08-01T16:04:10.660872131Z modprobe: can't change directory to '/lib/modules': No such file or directory
2023-08-01T16:04:10.664620455Z mount: permission denied (are you root?)
2023-08-01T16:04:10.664692175Z Could not mount /sys/kernel/security.
2023-08-01T16:04:10.664703615Z AppArmor detection and --privileged mode might break.
2023-08-01T16:04:10.665952353Z mount: permission denied (are you root?)
```

Cela indique que GitLab Runner ne dispose pas des autorisations nécessaires pour démarrer le service `dind` :

1. Vérifiez que `privileged = true` est défini dans le fichier `config.toml`.
1. Assurez-vous que le job CI dispose des bons tags de runner pour utiliser ces runners privilégiés.

## Erreur : `cgroups: cgroup mountpoint does not exist: unknown` {#error-cgroups-cgroup-mountpoint-does-not-exist-unknown}

Il existe une incompatibilité connue introduite par Docker Engine 20.10.

Lorsque l'hôte utilise Docker Engine 20.10 ou une version ultérieure, le service `docker:dind` dans une version antérieure à 20.10 ne fonctionne pas comme prévu.

Bien que le service lui-même démarre sans problème, toute tentative de build de l'image de conteneur génère l'erreur :

```plaintext
cgroups: cgroup mountpoint does not exist: unknown
```

Pour résoudre ce problème, mettez à jour le conteneur `docker:dind` vers la version 20.10.x au minimum, par exemple `docker:24.0.5-dind`.

La configuration inverse (service `docker:24.0.5-dind` et Docker Engine sur l'hôte en version 19.06.x ou antérieure) fonctionne sans problème. Pour adopter la meilleure stratégie, vous devez tester et mettre à jour fréquemment les versions de l'environnement de job vers les plus récentes. Cela apporte de nouvelles fonctionnalités, une sécurité améliorée et — dans ce cas précis — rend la mise à niveau du Docker Engine sous-jacent sur l'hôte du runner transparente pour le job.

## Erreur : `failed to verify certificate: x509: certificate signed by unknown authority` {#error-failed-to-verify-certificate-x509-certificate-signed-by-unknown-authority}

Cette erreur peut apparaître lorsque des commandes Docker telles que `docker build` ou `docker pull` sont exécutées dans un environnement Docker-in-Docker où des certificats personnalisés ou privés sont utilisés (par exemple, des certificats Zscaler) :

```plaintext
error pulling image configuration: download failed after attempts=6: tls: failed to verify certificate: x509: certificate signed by unknown authority
```

Cette erreur se produit parce que les commandes Docker dans un environnement Docker-in-Docker utilisent deux conteneurs distincts :

- Le **build container** exécute le client Docker (`/usr/bin/docker`) et les commandes de script de votre job.
- Le **service container** (souvent nommé `svc`) exécute le démon Docker qui traite la plupart des commandes Docker.

Lorsque votre organisation utilise des certificats personnalisés, les deux conteneurs ont besoin de ces certificats. Sans configuration de certificat appropriée dans les deux conteneurs, les opérations Docker qui se connectent à des registres ou services externes échoueront avec des erreurs de certificat.

Pour résoudre ce problème :

1. Stockez votre certificat racine en tant que [variable CI/CD](../variables/_index.md#define-a-cicd-variable-in-the-ui) nommée `CA_CERTIFICATE`. Le certificat doit être au format suivant :

   ```plaintext
   -----BEGIN CERTIFICATE-----
   (certificate content)
   -----END CERTIFICATE-----
   ```

1. Configurez votre pipeline pour installer le certificat dans le conteneur de service avant de démarrer le démon Docker. Par exemple :

   ```yaml
   image_build:
     stage: build
     image:
       name: docker:19.03
     variables:
       DOCKER_HOST: tcp://localhost:2375
       DOCKER_TLS_CERTDIR: ""
       CA_CERTIFICATE: "$CA_CERTIFICATE"
     services:
       - name: docker:19.03-dind
         command:
           - /bin/sh
           - -c
           - |
             echo "$CA_CERTIFICATE" > /usr/local/share/ca-certificates/custom-ca.crt && \
             update-ca-certificates && \
             dockerd-entrypoint.sh || exit
     script:
       - docker info
       - docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD $DOCKER_REGISTRY
       - docker build -t "${DOCKER_REGISTRY}/my-app:${CI_COMMIT_REF_NAME}" .
       - docker push "${DOCKER_REGISTRY}/my-app:${CI_COMMIT_REF_NAME}"
   ```
