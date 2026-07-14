---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Créer des images Docker avec BuildKit
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[BuildKit](https://docs.docker.com/build/buildkit/) est le moteur de build utilisé par Docker et fournit des builds multi-plateformes ainsi que la mise en cache des builds.

## Méthodes BuildKit {#buildkit-methods}

BuildKit propose les méthodes suivantes pour créer des images Docker :

| Méthode            | Exigence de sécurité     | Commandes                 | À utiliser quand vous avez besoin de |
| ----------------- | ------------------------ | ------------------------ | ----------------- |
| BuildKit rootless | Aucun conteneur privilégié | `buildctl-daemonless.sh` | Une sécurité maximale ou un remplacement de Kaniko |
| Docker Buildx     | Nécessite `docker:dind`   | `docker buildx`          | Workflow Docker familier |
| BuildKit natif   | Nécessite `docker:dind`   | `buildctl`               | Contrôle avancé de BuildKit |

## Prérequis {#prerequisites}

- GitLab Runner avec exécuteur Docker
- Docker 19.03 ou version ultérieure pour utiliser Docker Buildx
- Un projet avec un `Dockerfile`

## BuildKit rootless {#buildkit-rootless}

BuildKit en mode standalone fournit des builds d'images rootless sans dépendance au démon Docker. Cette méthode élimine entièrement les conteneurs privilégiés et constitue un remplacement direct pour les builds Kaniko.

Différences clés par rapport aux autres méthodes :

- Utilise l'image `moby/buildkit:rootless`
- Inclut `BUILDKITD_FLAGS: --oci-worker-no-process-sandbox` pour le fonctionnement rootless
- Utilise `buildctl-daemonless.sh` pour gérer le démon BuildKit automatiquement
- Aucune dépendance au démon Docker ou aux conteneurs privilégiés
- Nécessite une configuration manuelle de l'authentification au registre

### S'authentifier auprès des registres de conteneurs {#authenticate-with-container-registries}

GitLab CI/CD fournit une authentification automatique pour le registre de conteneurs GitLab via des variables prédéfinies. Pour BuildKit rootless, vous devez créer manuellement le fichier de configuration Docker.

#### S'authentifier auprès du registre de conteneurs GitLab {#authenticate-with-the-gitlab-container-registry}

GitLab fournit automatiquement ces variables prédéfinies :

- `CI_REGISTRY` : URL du registre
- `CI_REGISTRY_USER` : Nom d'utilisateur du registre
- `CI_REGISTRY_PASSWORD` : Mot de passe du registre

Pour configurer l'authentification pour les builds rootless, ajoutez une configuration `before_script` à vos jobs. Par exemple :

```yaml
before_script:
  - mkdir -p ~/.docker
  - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
```

#### S'authentifier auprès de plusieurs registres de conteneurs {#authenticate-with-multiple-registries}

Pour vous authentifier auprès d'autres registres de conteneurs, combinez les entrées d'authentification dans votre section `before_script`. Par exemple :

```yaml
before_script:
  - mkdir -p ~/.docker
  - |
    echo "{
      \"auths\": {
        \"${CI_REGISTRY}\": {
          \"auth\": \"$(printf "%s:%s" "${CI_REGISTRY_USER}" "${CI_REGISTRY_PASSWORD}" | base64 | tr -d '\n')\"
        },
        \"docker.io\": {
          \"auth\": \"$(printf "%s:%s" "${DOCKER_HUB_USER}" "${DOCKER_HUB_PASSWORD}" | base64 | tr -d '\n')\"
        }
      }
    }" > ~/.docker/config.json
```

#### S'authentifier auprès du proxy de dépendances {#authenticate-with-the-dependency-proxy}

Pour extraire des images via le proxy de dépendances GitLab, configurez l'authentification dans votre section `before_script`. Par exemple :

```yaml
before_script:
  - mkdir -p ~/.docker
  - |
    echo "{
      \"auths\": {
        \"${CI_REGISTRY}\": {
          \"auth\": \"$(printf "%s:%s" "${CI_REGISTRY_USER}" "${CI_REGISTRY_PASSWORD}" | base64 | tr -d '\n')\"
        },
        \"$(echo -n $CI_DEPENDENCY_PROXY_SERVER | awk -F[:] '{print $1}')\": {
          \"auth\": \"$(printf "%s:%s" ${CI_DEPENDENCY_PROXY_USER} "${CI_DEPENDENCY_PROXY_PASSWORD}" | base64 | tr -d '\n')\"
        }
      }
    }" > ~/.docker/config.json
```

Pour plus d'informations, voir [s'authentifier dans CI/CD](../../user/packages/dependency_proxy/_index.md#authenticate-within-cicd).

### Créer des images en mode rootless {#build-images-in-rootless-mode}

Pour créer des images sans dépendance au démon Docker, ajoutez un job similaire à cet exemple :

```yaml
build-rootless:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

### Créer des images multi-plateformes en mode rootless {#build-multi-platform-images-in-rootless-mode}

Pour créer des images pour plusieurs architectures en mode rootless, configurez votre job afin de spécifier les plateformes cibles. Par exemple :

```yaml
build-multiarch-rootless:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --opt platform=linux/amd64,linux/arm64 \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

### Utiliser la mise en cache en mode rootless {#use-caching-in-rootless-mode}

Pour activer la mise en cache basée sur le registre afin d'accélérer les builds ultérieurs, configurez l'import et l'export du cache dans votre job de build. Par exemple :

```yaml
build-cached-rootless:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
    CACHE_IMAGE: $CI_REGISTRY_IMAGE:cache
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --export-cache type=registry,ref=$CACHE_IMAGE \
        --import-cache type=registry,ref=$CACHE_IMAGE \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

### Utiliser un miroir de registre en mode rootless {#use-a-registry-mirror-in-rootless-mode}

Les miroirs de registre permettent des extractions d'images plus rapides et peuvent aider en cas de limite de débit ou de restrictions réseau.

Pour configurer des miroirs de registre, créez un fichier `buildkit.toml` qui spécifie les points de terminaison du miroir. Par exemple :

```yaml
build-mirror-rootless:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox --config /tmp/buildkit.toml
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
    - cat <<'EOF' > /tmp/buildkit.toml
      [registry."docker.io"]
        mirrors = ["mirror.example.com"]
      EOF
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

Dans cet exemple, remplacez `mirror.example.com` par l'URL de votre miroir de registre.

### Configurer les paramètres de proxy {#configure-proxy-settings}

Si votre GitLab Runner fonctionne derrière un proxy HTTP(S), configurez les paramètres de proxy en tant que variables dans votre job. Par exemple :

```yaml
build-behind-proxy:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
    http_proxy: <your-proxy>
    https_proxy: <your-proxy>
    no_proxy: <your-no-proxy>
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --build-arg http_proxy=$http_proxy \
        --build-arg https_proxy=$https_proxy \
        --build-arg no_proxy=$no_proxy \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

Dans cet exemple, remplacez `<your-proxy>` et `<your-no-proxy>` par votre configuration de proxy.

### Ajouter des certificats personnalisés {#add-custom-certificates}

Pour envoyer vers un registre en utilisant des certificats CA personnalisés, ajoutez le certificat au magasin de certificats du conteneur avant le build. Par exemple :

```yaml
build-with-custom-certs:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
  before_script:
    - export SSL_CERT_FILE="$HOME/ca_chain.pem"
    - cat /etc/ssl/certs/ca-certificates.crt > "$SSL_CERT_FILE"
    - echo "$MY_CA_CERT" >> "$SSL_CERT_FILE"
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

Dans cet exemple, renseignez la variable `MY_CA_CERT` avec le contenu complet de votre certificat CA, incluant à la fois le certificat racine et tout certificat intermédiaire.

## Migrer de Kaniko vers BuildKit {#migrate-from-kaniko-to-buildkit}

BuildKit rootless est une alternative sécurisée à Kaniko. Il offre des performances améliorées, une meilleure mise en cache et des fonctionnalités de sécurité renforcées tout en maintenant le fonctionnement rootless.

### Mettre à jour votre configuration {#update-your-configuration}

Mettez à jour votre configuration Kaniko existante pour utiliser la méthode BuildKit rootless. Par exemple :

Avant, avec Kaniko :

```yaml
build:
  image:
    name: gcr.io/kaniko-project/executor:debug
    entrypoint: [""]
  script:
    - /kaniko/executor
      --context $CI_PROJECT_DIR
      --dockerfile $CI_PROJECT_DIR/Dockerfile
      --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
```

Après, avec BuildKit rootless :

```yaml
build:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

## Méthodes BuildKit alternatives {#alternative-buildkit-methods}

Si vous n'avez pas besoin de builds rootless, BuildKit propose des méthodes supplémentaires qui nécessitent le service `docker:dind` mais offrent des workflows familiers ou des fonctionnalités avancées.

### Docker Buildx {#docker-buildx}

Docker Buildx étend les capacités de build Docker avec les fonctionnalités de BuildKit tout en conservant une syntaxe de commande familière. Cette méthode nécessite le service `docker:dind`.

#### Créer des images de base {#build-basic-images}

Pour créer des images Docker avec Buildx, configurez votre job avec le service `docker:dind` et créez un builder `buildx`. Par exemple :

```yaml
variables:
  DOCKER_TLS_CERTDIR: "/certs"

build-image:
  image: docker:cli
  services:
    - docker:dind
  stage: build
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker buildx create --use --driver docker-container --name builder
    - docker buildx inspect --bootstrap
  script:
    - docker buildx build --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA --push .
  after_script:
    - docker buildx rm builder
```

#### Créer des images multi-plateformes {#build-multi-platform-images}

Les builds multi-plateformes créent des images pour différentes architectures en une seule commande de build. Le manifeste résultant prend en charge plusieurs architectures, et Docker sélectionne automatiquement l'image appropriée pour chaque cible de déploiement.

Pour créer des images pour plusieurs architectures, ajoutez le flag `--platform` pour spécifier les architectures cibles. Par exemple :

```yaml
variables:
  DOCKER_TLS_CERTDIR: "/certs"

build-multiplatform:
  image: docker:cli
  services:
    - docker:dind
  stage: build
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker buildx create --use --driver docker-container --name multibuilder
    - docker buildx inspect --bootstrap
  script:
    - docker buildx build
        --platform linux/amd64,linux/arm64
        --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
        --push .
  after_script:
    - docker buildx rm multibuilder
```

#### Utiliser la mise en cache de build {#use-build-caching}

La mise en cache basée sur le registre stocke les couches de build dans un registre de conteneurs pour les réutiliser entre les builds.

L'option `mode=max` exporte toutes les couches vers le cache et offre un potentiel de réutilisation maximal pour les builds ultérieurs.

Pour utiliser la mise en cache de build, ajoutez des options de cache à votre commande de build. Par exemple :

```yaml
variables:
  DOCKER_TLS_CERTDIR: "/certs"
  CACHE_IMAGE: $CI_REGISTRY_IMAGE:cache

build-with-cache:
  image: docker:cli
  services:
    - docker:dind
  stage: build
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker buildx create --use --driver docker-container --name cached-builder
    - docker buildx inspect --bootstrap
  script:
    - docker buildx build
        --cache-from type=registry,ref=$CACHE_IMAGE
        --cache-to type=registry,ref=$CACHE_IMAGE,mode=max
        --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
        --push .
  after_script:
    - docker buildx rm cached-builder
```

### BuildKit natif {#native-buildkit}

Utilisez les commandes BuildKit natives `buildctl` pour un meilleur contrôle du processus de build. Cette méthode nécessite le service `docker:dind`.

Pour utiliser BuildKit directement, configurez votre job avec l'image BuildKit et le service `docker:dind`. Par exemple :

```yaml
variables:
  DOCKER_TLS_CERTDIR: "/certs"

build-with-buildkit:
  image: moby/buildkit:latest
  services:
    - docker:dind
  stage: build
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

## Dépannage {#troubleshooting}

### Échec du build avec des erreurs d'authentification {#build-fails-with-authentication-errors}

Si vous rencontrez des échecs d'authentification au registre :

- Vérifiez que les variables `CI_REGISTRY_USER` et `CI_REGISTRY_PASSWORD` sont disponibles.
- Vérifiez que vous disposez des autorisations de push vers le registre cible.
- Pour les registres externes, assurez-vous que les identifiants d'authentification sont correctement configurés dans les variables CI/CD de votre projet.

### Échec du build rootless avec des erreurs de permission {#rootless-build-fails-with-permission-errors}

Pour les problèmes liés aux permissions en mode rootless :

- Assurez-vous que `BUILDKITD_FLAGS: --oci-worker-no-process-sandbox` est défini.
- Vérifiez que le GitLab Runner dispose de ressources suffisantes allouées.
- Vérifiez qu'aucune opération privilégiée n'est tentée dans votre `Dockerfile`.

Si vous recevez `[rootlesskit:child ] error: failed to share mount point: /: permission denied` sur un runner Kubernetes, AppArmor bloque l'appel système de montage requis par BuildKit.

Pour résoudre ce problème, ajoutez ce qui suit à la configuration de votre runner :

```toml
[runners.kubernetes.pod_annotations]
  "container.apparmor.security.beta.kubernetes.io/build" = "unconfined"
```

### Erreur : `invalid local: stat path/to/image/Dockerfile: not a directory` {#error-invalid-local-stat-pathtoimagedockerfile-not-a-directory}

Vous pourriez recevoir une erreur indiquant `invalid local: stat path/to/image/Dockerfile: not a directory`.

Ce problème survient lorsque vous spécifiez un chemin de fichier au lieu d'un chemin de répertoire pour le paramètre `--local dockerfile=`. BuildKit attend un chemin de répertoire contenant un fichier nommé `Dockerfile`.

Pour résoudre ce problème, utilisez le chemin du répertoire au lieu du chemin complet du fichier. Par exemple :

- Utilisez : `--local dockerfile=path/to/image`
- Au lieu de : `--local dockerfile=path/to/image/Dockerfile`

### Échec des builds multi-plateformes {#multi-platform-builds-fail}

Pour les problèmes de build multi-plateformes :

- Vérifiez que les images de base dans votre `Dockerfile` prennent en charge les architectures cibles.
- Vérifiez que les dépendances spécifiques à l'architecture sont disponibles pour toutes les plateformes cibles.
- Envisagez d'utiliser des instructions conditionnelles dans votre `Dockerfile` pour la logique spécifique à l'architecture.
