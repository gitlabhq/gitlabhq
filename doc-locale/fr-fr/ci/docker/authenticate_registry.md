---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "S'authentifier auprès du registre dans Docker-in-Docker"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque vous utilisez Docker-in-Docker, les [méthodes d'authentification standard](using_docker_images.md#access-an-image-from-a-private-container-registry) ne fonctionnent pas, car un nouveau démon Docker est démarré avec le service.

## Option 1 : Exécuter `docker login` {#option-1-run-docker-login}

Dans [`before_script`](../yaml/_index.md#before_script), exécutez `docker login` :

```yaml
default:
  image: docker:24.0.5-cli
  services:
    - docker:24.0.5-dind

variables:
  DOCKER_TLS_CERTDIR: "/certs"

build:
  stage: build
  before_script:
    - echo "$DOCKER_REGISTRY_PASS" | docker login $DOCKER_REGISTRY --username $DOCKER_REGISTRY_USER --password-stdin
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

Pour vous connecter à Docker Hub, laissez `$DOCKER_REGISTRY` vide ou supprimez-le.

## Option 2 : Monter `~/.docker/config.json` sur chaque job {#option-2-mount-dockerconfigjson-on-each-job}

Si vous êtes administrateur de GitLab Runner, vous pouvez monter un fichier contenant la configuration d'authentification dans `~/.docker/config.json`. Ainsi, chaque job que le runner récupère est déjà authentifié. Si vous utilisez l'image officielle `docker:24.0.5`, le répertoire personnel se trouve sous `/root`.

Si vous montez le fichier de configuration, toute commande `docker` qui modifie le fichier `~/.docker/config.json` échoue. Par exemple, `docker login` échoue, car le fichier est monté en lecture seule. Ne le modifiez pas pour passer en lecture-écriture, car cela entraîne des problèmes.

Voici un exemple de `/opt/.docker/config.json` qui suit la documentation [`DOCKER_AUTH_CONFIG`](using_docker_images.md#determine-your-docker_auth_config-data) :

```json
{
    "auths": {
        "https://index.docker.io/v1/": {
            "auth": "bXlfdXNlcm5hbWU6bXlfcGFzc3dvcmQ="
        }
    }
}
```

### Docker {#docker}

Mettez à jour les [montages de volumes](https://docs.gitlab.com/runner/configuration/advanced-configuration/#volumes-in-the-runnersdocker-section) pour inclure le fichier.

```toml
[[runners]]
  ...
  executor = "docker"
  [runners.docker]
    ...
    privileged = true
    volumes = ["/opt/.docker/config.json:/root/.docker/config.json:ro"]
```

### Kubernetes {#kubernetes}

Créez une [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) avec le contenu de ce fichier. Vous pouvez effectuer cette opération à l'aide d'une commande telle que :

```shell
kubectl create configmap docker-client-config --namespace gitlab-runner --from-file /opt/.docker/config.json
```

Mettez à jour les [montages de volumes](https://docs.gitlab.com/runner/executors/kubernetes/#custom-volume-mount) pour inclure le fichier.

```toml
[[runners]]
  ...
  executor = "kubernetes"
  [runners.kubernetes]
    image = "alpine:3.12"
    privileged = true
    [[runners.kubernetes.volumes.config_map]]
      name = "docker-client-config"
      mount_path = "/root/.docker/config.json"
      sub_path = "config.json"
```

## Option 3 : Utiliser `DOCKER_AUTH_CONFIG` {#option-3-use-docker_auth_config}

Si vous avez déjà défini [`DOCKER_AUTH_CONFIG`](using_docker_images.md#determine-your-docker_auth_config-data), vous pouvez utiliser la variable et l'enregistrer dans `~/.docker/config.json`.

Vous pouvez définir cette authentification de plusieurs façons :

- Dans [`pre_build_script`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section) dans le fichier de configuration du runner.
- Dans [`before_script`](../yaml/_index.md#before_script).
- Dans [`script`](../yaml/_index.md#script).

L'exemple suivant illustre l'utilisation de [`before_script`](../yaml/_index.md#before_script). Les mêmes commandes s'appliquent pour toute solution que vous mettez en œuvre.

```yaml
default:
  image: docker:24.0.5-cli
  services:
    - docker:24.0.5-dind

variables:
  DOCKER_TLS_CERTDIR: "/certs"

build:
  stage: build
  before_script:
    - mkdir -p $HOME/.docker
    - echo $DOCKER_AUTH_CONFIG > $HOME/.docker/config.json
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```
