---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Configurer l'analyse de la qualité du code basée sur CodeClimate (obsolète)"
---

<!--- start_remove The following content will be removed on remove_date: '2026-08-15' -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> Cette fonctionnalité a été [dépréciée](../../update/deprecations.md#codeclimate-based-code-quality-scanning-will-be-removed) dans GitLab 17.3 et sa suppression est prévue dans la version 19.0. [Intégrez directement les résultats d'un outil pris en charge](code_quality.md#import-code-quality-results-from-a-cicd-job) à la place. Ce changement est un changement radical.

Code Quality inclut un modèle CI/CD intégré, `Code-Quality.gitlab-ci.yaml`. Ce template exécute une analyse basée sur le moteur d'analyse open source CodeClimate.

Le moteur CodeClimate exécute :

- Des vérifications de maintenabilité de base pour un [ensemble de langages pris en charge](https://docs.codeclimate.com/docs/supported-languages-for-maintainability).
- Un ensemble configurable de [plugins](https://docs.codeclimate.com/docs/list-of-engines), qui encapsulent des scanners open source, pour analyser votre code source.

## Activer l'analyse basée sur CodeClimate {#enable-codeclimate-based-scanning}

Prérequis :

- La configuration GitLab CI/CD (`.gitlab-ci.yml`) doit inclure l'étape `test`.
- Si vous utilisez des runners d'instance, le job Code Quality doit être configuré pour le [workflow Docker-in-Docker](../docker/using_docker_build.md#use-docker-in-docker). Lorsque vous utilisez ce workflow, le volume `/builds` doit être mappé pour permettre l'enregistrement des rapports.
- Si vous utilisez des runners privés, vous devriez utiliser une [configuration alternative](#use-private-runners) recommandée pour exécuter l'analyse Code Quality plus efficacement.
- Le runner doit disposer de suffisamment d'espace disque pour stocker les fichiers Code Quality générés. Par exemple, sur le [projet GitLab](https://gitlab.com/gitlab-org/gitlab), les fichiers représentent environ 7 Go.

Pour activer Code Quality, au choix :

- Activez [Auto DevOps](../../topics/autodevops/_index.md), qui inclut [Auto Code Quality](../../topics/autodevops/stages.md#auto-code-quality).

- Incluez le [modèle Code Quality](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Code-Quality.gitlab-ci.yml) dans votre fichier `.gitlab-ci.yml`.

  Exemple :

  ```yaml
     include:
     - template: Jobs/Code-Quality.gitlab-ci.yml
  ```

  Code Quality s'exécute maintenant dans les pipelines.

> [!warning]
> Sur GitLab Self-Managed, si un acteur malveillant compromet la définition du job Code Quality, il pourrait exécuter des commandes Docker privilégiées sur l'hôte du runner. La mise en place de politiques de contrôle d'accès appropriées atténue ce vecteur d'attaque en n'autorisant l'accès qu'aux acteurs de confiance.

## Désactiver l'analyse basée sur CodeClimate {#disable-codeclimate-based-scanning}

Le job `code_quality` ne s'exécute pas si la variable CI/CD `$CODE_QUALITY_DISABLED` est présente. Pour plus d'informations sur la définition d'une variable, consultez [les variables CI/CD GitLab](../variables/_index.md).

Pour désactiver Code Quality, créez une variable CI/CD personnalisée nommée `CODE_QUALITY_DISABLED`, pour :

- [L'ensemble du projet](../variables/_index.md#for-a-project).
- [Un seul pipeline](../pipelines/_index.md#run-a-pipeline-manually).

## Configurer les plugins d'analyse CodeClimate {#configure-codeclimate-analysis-plugins}

Par défaut, le job `code_quality` configure CodeClimate pour :

- Utiliser [un ensemble spécifique de plugins](https://gitlab.com/gitlab-org/ci-cd/codequality/-/blob/master/codeclimate_defaults/.codeclimate.yml.template?ref_type=heads).
- Utiliser [les configurations par défaut](https://gitlab.com/gitlab-org/ci-cd/codequality/-/tree/master/codeclimate_defaults?ref_type=heads) pour ces plugins.

Pour analyser davantage de langages, vous pouvez activer davantage de [plugins](https://docs.codeclimate.com/docs/list-of-engines). Vous pouvez également désactiver les plugins que le job `code_quality` active par défaut.

Par exemple, pour utiliser l'[analyseur SonarJava](https://docs.codeclimate.com/docs/sonar-java) :

1. Ajoutez un fichier nommé `.codeclimate.yml` à la racine de votre dépôt
1. Ajoutez le [code d'activation](https://docs.codeclimate.com/docs/sonar-java#enable-the-plugin) du plugin à la racine de votre dépôt dans le fichier `.codeclimate.yml` :

   ```yaml
   version: "2"
   plugins:
     sonar-java:
       enabled: true
   ```

Cela ajoute SonarJava à la section `plugins:` du [`.codeclimate.yml` par défaut](https://gitlab.com/gitlab-org/ci-cd/codequality/-/blob/master/codeclimate_defaults/.codeclimate.yml.template) inclus dans votre projet.

Les modifications apportées à la section `plugins:` n'affectent pas la section `exclude_patterns` du fichier `.codeclimate.yml` par défaut. Consultez la documentation Code Climate sur l'[exclusion de fichiers et de dossiers](https://docs.codeclimate.com/docs/excluding-files-and-folders) pour plus de détails.

## Personnaliser les paramètres du job d'analyse {#customize-scan-job-settings}

Vous pouvez modifier le comportement du job d'analyse `code_quality` en définissant des [variables CI/CD](#available-cicd-variables) dans votre YAML GitLab CI/CD.

Pour configurer le job Code Quality :

1. Déclarez un job portant le même nom que le job Code Quality, après l'inclusion du modèle.
1. Spécifiez des clés supplémentaires dans la strophe du job.

Pour un exemple, consultez [Télécharger la sortie au format HTML](#output-in-only-html-format).

### Variables CI/CD disponibles {#available-cicd-variables}

Code Quality peut être personnalisé en définissant les variables CI/CD disponibles :

| Variable CI/CD                  | Description |
|---------------------------------|-------------|
| `CODECLIMATE_DEBUG`             | Définir pour activer le [mode débogage Code Climate](https://github.com/codeclimate/codeclimate#environment-variables). |
| `CODECLIMATE_DEV`               | Définir pour activer le mode `--dev` qui vous permet d'exécuter des moteurs non connus de la CLI. |
| `CODECLIMATE_PREFIX`            | Définir un préfixe à utiliser avec toutes les commandes `docker pull` dans les moteurs CodeClimate. Utile pour l'[analyse hors ligne](https://github.com/codeclimate/codeclimate/pull/948). Pour plus d'informations, consultez [Utiliser un registre de conteneurs privé](#use-a-private-container-image-registry). |
| `CODECLIMATE_REGISTRY_USERNAME` | Définir pour spécifier le nom d'utilisateur du domaine de registre extrait de `CODECLIMATE_PREFIX`. |
| `CODECLIMATE_REGISTRY_PASSWORD` | Définir pour spécifier le mot de passe du domaine de registre extrait de `CODECLIMATE_PREFIX`. |
| `CODE_QUALITY_DISABLED`         | Empêche l'exécution du job Code Quality. |
| `CODE_QUALITY_IMAGE`            | Définir un nom d'image entièrement préfixé. L'image doit être accessible depuis l'environnement de votre job. |
| `ENGINE_MEMORY_LIMIT_BYTES`     | Définir la limite de mémoire pour les moteurs. Par défaut : 1 024 000 000 octets. |
| `REPORT_STDOUT`                 | Définir pour imprimer le rapport dans `STDOUT` au lieu de générer le fichier de rapport habituel. |
| `REPORT_FORMAT`                 | Définir pour contrôler le format du fichier de rapport généré. `json` ou `html`. |
| `SOURCE_CODE`                   | Chemin vers le code source à analyser. Doit être le chemin absolu vers un répertoire où les sources clonées sont stockées. |
| `TIMEOUT_SECONDS`               | Délai d'expiration personnalisé par conteneur de moteur pour la commande `codeclimate analyze`. Par défaut : 900 secondes (15 minutes) |

### Sortie {#output}

Code Quality génère un rapport contenant les détails des problèmes détectés. Le contenu de ce rapport est traité en interne et les résultats sont affichés dans l'interface utilisateur. Le rapport est également généré en tant qu'artefact de job du job `code_quality`, nommé `gl-code-quality-report.json`. Vous pouvez éventuellement générer le rapport au format HTML. Par exemple, vous pourriez publier le fichier au format HTML sur GitLab Pages pour faciliter encore davantage la révision.

#### Sortie au format JSON et HTML {#output-in-json-and-html-format}

Pour générer le rapport Code Quality au format JSON et HTML, vous créez un job supplémentaire. Cela nécessite d'exécuter Code Quality deux fois, une fois pour chaque format de fichier.

Pour générer le rapport Code Quality au format HTML, ajoutez un autre job à votre modèle en utilisant `extends: code_quality` :

```yaml
include:
  - template: Jobs/Code-Quality.gitlab-ci.yml

code_quality_html:
  extends: code_quality
  variables:
    REPORT_FORMAT: html
  artifacts:
    paths: [gl-code-quality-report.html]
```

Les fichiers JSON et HTML sont tous deux générés en tant qu'artefacts de job. Le fichier HTML est contenu dans l'artefact de job `artifacts.zip`.

#### Sortie au format HTML uniquement {#output-in-only-html-format}

Pour télécharger le rapport Code Quality au format HTML uniquement, définissez `REPORT_FORMAT` sur `html`, en remplaçant la définition par défaut du job `code_quality`.

> [!note]
> Cette opération ne crée pas de fichier au format JSON ; les résultats de Code Quality ne sont donc pas affichés dans le widget de merge request, le rapport de pipeline ou la vue des modifications.

```yaml
include:
  - template: Jobs/Code-Quality.gitlab-ci.yml

code_quality:
  variables:
    REPORT_FORMAT: html
  artifacts:
    paths: [gl-code-quality-report.html]
```

Le fichier HTML est généré en tant qu'artefact de job.

## Utiliser Code Quality avec les pipelines de merge request {#use-code-quality-with-merge-request-pipelines}

La configuration Code Quality par défaut n'autorise pas l'exécution du job `code_quality` sur les [pipelines de merge request](../pipelines/merge_request_pipelines.md).

Pour permettre à Code Quality de s'exécuter sur les pipelines de merge request, remplacez les `rules` de qualité du code, ou [`workflow: rules`](../yaml/_index.md#workflow), afin qu'ils correspondent à vos `rules` actuels.

Par exemple :

```yaml
include:
  - template: Jobs/Code-Quality.gitlab-ci.yml

code_quality:
  rules:
    - if: $CODE_QUALITY_DISABLED
      when: never
    - if: $CI_PIPELINE_SOURCE == "merge_request_event" # Run code quality job in merge request pipelines
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH      # Run code quality job in pipelines on the default branch (but not in other branch pipelines)
    - if: $CI_COMMIT_TAG                               # Run code quality job in pipelines for tags
```

## Modifier le mode de téléchargement des images CodeClimate {#change-how-codeclimate-images-are-downloaded}

Le moteur CodeClimate télécharge des images de conteneurs pour exécuter chacun de ses plugins. Par défaut, les images sont téléchargées depuis Docker Hub. Vous pouvez modifier la source des images pour améliorer les performances, contourner les limites de débit de Docker Hub ou utiliser un registre privé.

### Utiliser le proxy de dépendances pour télécharger les images {#use-the-dependency-proxy-to-download-images}

Vous pouvez utiliser un proxy de dépendances pour réduire le temps de téléchargement des dépendances.

Prérequis :

- [Proxy de dépendances](../../user/packages/dependency_proxy/_index.md) activé dans le groupe du projet.

Pour référencer le proxy de dépendances, configurez les variables suivantes dans le fichier `.gitlab-ci.yml` :

- `CODE_QUALITY_IMAGE`
- `CODECLIMATE_PREFIX`
- `CODECLIMATE_REGISTRY_USERNAME`
- `CODECLIMATE_REGISTRY_PASSWORD`

Par exemple :

```yaml
include:
  - template: Jobs/Code-Quality.gitlab-ci.yml

code_quality:
  variables:
    ## You must add a trailing slash to `$CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX`.
    CODECLIMATE_PREFIX: $CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX/
    CODECLIMATE_REGISTRY_USERNAME: $CI_DEPENDENCY_PROXY_USER
    CODECLIMATE_REGISTRY_PASSWORD: $CI_DEPENDENCY_PROXY_PASSWORD
```

### Utiliser Docker Hub avec authentification {#use-docker-hub-with-authentication}

Vous pouvez utiliser Docker Hub comme source alternative des images Code Quality.

Prérequis :

- Ajoutez le nom d'utilisateur et le mot de passe en tant que [variables CI/CD protégées](../variables/_index.md#for-a-project) dans le projet.

Pour utiliser DockerHub, configurez les variables suivantes dans le fichier `.gitlab-ci.yml` :

- `CODECLIMATE_PREFIX`
- `CODECLIMATE_REGISTRY_USERNAME`
- `CODECLIMATE_REGISTRY_PASSWORD`

Exemple :

```yaml
include:
  - template: Jobs/Code-Quality.gitlab-ci.yml

code_quality:
  variables:
    CODECLIMATE_PREFIX: "registry-1.docker.io/"
    CODECLIMATE_REGISTRY_USERNAME: $DOCKERHUB_USERNAME
    CODECLIMATE_REGISTRY_PASSWORD: $DOCKERHUB_PASSWORD
```

### Utiliser un registre de conteneurs d'images privé {#use-a-private-container-image-registry}

L'utilisation d'un registre de conteneurs d'images privé peut réduire le temps de téléchargement des images et réduire les dépendances externes. Vous devez configurer le préfixe du registre pour qu'il soit transmis aux commandes `docker pull` ultérieures de CodeClimate pour les moteurs individuels, en raison de la méthode imbriquée d'exécution des conteneurs.

Les variables suivantes permettent de gérer tous les téléchargements d'images requis :

- `CODE_QUALITY_IMAGE` : Un nom d'image entièrement préfixé pouvant être localisé n'importe où et accessible depuis l'environnement de votre job. Le registre de conteneurs GitLab peut être utilisé ici pour héberger votre propre copie.
- `CODECLIMATE_PREFIX` : Le domaine de votre registre de conteneurs d'images cible. Il s'agit d'une option de configuration prise en charge par [CodeClimate CLI](https://github.com/codeclimate/codeclimate/pull/948). Vous devez :
  - Inclure une barre oblique de fin (`/`).
  - Ne pas inclure de préfixe de protocole, tel que `https://`.
- `CODECLIMATE_REGISTRY_USERNAME` : Une variable facultative pour spécifier le nom d'utilisateur du domaine de registre extrait de `CODECLIMATE_PREFIX`.
- `CODECLIMATE_REGISTRY_PASSWORD` : Une variable facultative pour spécifier le mot de passe du domaine de registre extrait de `CODECLIMATE_PREFIX`.

```yaml
include:
  - template: Jobs/Code-Quality.gitlab-ci.yml

code_quality:
  variables:
    CODE_QUALITY_IMAGE: "my-private-registry.local:12345/codequality:0.85.24"
    CODECLIMATE_PREFIX: "my-private-registry.local:12345/"
```

Cet exemple est spécifique à GitLab Code Quality. Pour des instructions plus générales sur la configuration de DinD avec un miroir de registre, consultez [Activer le miroir de registre pour le service Docker-in-Docker](../docker/using_docker_build.md#enable-registry-mirror-for-dockerdind-service).

#### Images requises {#required-images}

Les images suivantes sont requises pour le [`.codeclimate.yml` par défaut](https://gitlab.com/gitlab-org/ci-cd/codequality/-/blob/master/codeclimate_defaults/.codeclimate.yml.template) :

- `codeclimate/codeclimate-structure:latest`
- `codeclimate/codeclimate-csslint:latest`
- `codeclimate/codeclimate-coffeelint:latest`
- `codeclimate/codeclimate-duplication:latest`
- `codeclimate/codeclimate-eslint:latest`
- `codeclimate/codeclimate-fixme:latest`
- `codeclimate/codeclimate-rubocop:rubocop-0-92`

Si vous utilisez un fichier de configuration `.codeclimate.yml` personnalisé, vous devez ajouter les plugins spécifiés dans votre registre de conteneurs privé.

## Modifier la configuration du Runner {#change-runner-configuration}

CodeClimate exécute des conteneurs distincts pour chacune de ses étapes d'analyse. Vous devrez peut-être ajuster la configuration de votre Runner pour que les analyses basées sur CodeClimate puissent s'exécuter, ou pour qu'elles s'exécutent plus rapidement.

### Utiliser des runners privés {#use-private-runners}

Si vous disposez de runners privés, vous devriez utiliser cette configuration pour améliorer les performances de Code Quality, car :

- Le mode privilégié n'est pas utilisé.
- Docker-in-Docker n'est pas utilisé.
- Les images Docker, y compris toutes les images CodeClimate, sont mises en cache et ne sont pas récupérées à nouveau pour les jobs suivants.

Cette configuration alternative utilise la liaison de socket pour partager le démon Docker du Runner avec l'environnement du job. Avant d'implémenter cette configuration, tenez compte de ses [limitations](../docker/using_docker_build.md#use-docker-socket-binding).

Pour utiliser des runners privés :

1. Enregistrez un nouveau runner :

   ```shell
   $ gitlab-runner register --executor "docker" \
     --docker-image="docker:cli" \
     --url "https://gitlab.com/" \
     --description "cq-sans-dind" \
     --docker-volumes "/cache"\
     --docker-volumes "/builds:/builds"\
     --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
     --registration-token="<project_token>" \
     --non-interactive
   ```

1. **Facultatif, mais recommandé** : Définissez le répertoire de builds sur `/tmp/builds`, afin que les artefacts de job soient périodiquement purgés de l'hôte du runner. Si vous ignorez cette étape, vous devrez nettoyer vous-même le répertoire de builds par défaut (`/builds`). Vous pouvez le faire en ajoutant les deux indicateurs suivants à `gitlab-runner register` à l'étape précédente.

   ```shell
   --builds-dir "/tmp/builds"
   --docker-volumes "/tmp/builds:/tmp/builds" # Use this instead of --docker-volumes "/builds:/builds"
   ```

   La configuration résultante :

   ```toml
   [[runners]]
     name = "cq-sans-dind"
     url = "https://gitlab.com/"
     token = "<project_token>"
     executor = "docker"
     builds_dir = "/tmp/builds"
     [runners.docker]
       tls_verify = false
       image = "docker:cli"
       privileged = false
       disable_entrypoint_overwrite = false
       oom_kill_disable = false
       disable_cache = false
       volumes = ["/cache", "/var/run/docker.sock:/var/run/docker.sock", "/tmp/builds:/tmp/builds"]
       shm_size = 0
     [runners.cache]
       [runners.cache.s3]
       [runners.cache.gcs]
   ```

1. Appliquez deux remplacements au job `code_quality` créé par le modèle :

   ```yaml
   include:
     - template: Jobs/Code-Quality.gitlab-ci.yml

   code_quality:
     services:            # Shut off Docker-in-Docker
     tags:
       - cq-sans-dind     # Set this job to only run on our new specialized runner
   ```

Code Quality s'exécute maintenant en mode Docker standard.

### Exécuter CodeClimate sans privilèges root avec des runners privés {#run-codeclimate-rootless-with-private-runners}

Si vous utilisez des runners privés et souhaitez exécuter les analyses Code Quality [en mode Docker sans privilèges root](https://docs.docker.com/engine/security/rootless/), Code Quality nécessite quelques modifications particulières pour fonctionner correctement. Cela peut nécessiter un runner dédié exclusivement aux jobs de qualité du code, car les modifications de liaison de socket peuvent causer des problèmes dans d'autres jobs.

Pour utiliser un runner privé sans privilèges root :

1. Enregistrez un nouveau runner :

   Remplacez `/run/user/<gitlab-runner-user>/docker.sock` par le chemin vers le fichier `docker.sock` local pour l'utilisateur `gitlab-runner`.

   ```shell
   $ gitlab-runner register --executor "docker" \
     --docker-image="docker:cli" \
     --url "https://gitlab.com/" \
     --description "cq-rootless" \
     --tag-list "cq-rootless" \
     --locked="false" \
     --access-level="not_protected" \
     --docker-volumes "/cache" \
     --docker-volumes "/tmp/builds:/tmp/builds" \
     --docker-volumes "/run/user/<gitlab-runner-user>/docker.sock:/run/user/<gitlab-runner-user>/docker.sock" \
     --token "<project_token>" \
     --non-interactive \
     --builds-dir "/tmp/builds" \
     --env "DOCKER_HOST=unix:///run/user/<gitlab-runner-user>/docker.sock" \
     --docker-host "unix:///run/user/<gitlab-runner-user>/docker.sock"
   ```

   La configuration résultante :

   ```toml
   [[runners]]
     name = "cq-rootless"
     url = "https://gitlab.com/"
     token = "<project_token>"
     executor = "docker"
     builds_dir = "/tmp/builds"
     environment = ["DOCKER_HOST=unix:///run/user/<gitlab-runner-user>/docker.sock"]
     [runners.docker]
       tls_verify = false
       image = "docker:cli"
       privileged = false
       disable_entrypoint_overwrite = false
       oom_kill_disable = false
       disable_cache = false
       volumes = ["/cache", "/run/user/<gitlab-runner-user>/docker.sock:/run/user/<gitlab-runner-user>/docker.sock", "/tmp/builds:/tmp/builds"]
       shm_size = 0
       host = "unix:///run/user/<gitlab-runner-user>/docker.sock"
     [runners.cache]
       [runners.cache.s3]
       [runners.cache.gcs]
   ```

1. Appliquez les remplacements suivants au job `code_quality` créé par le modèle :

   ```yaml
   code_quality:
     services:
     variables:
       DOCKER_SOCKET_PATH: /run/user/997/docker.sock
     tags:
       - cq-rootless
   ```

Code Quality s'exécute maintenant en mode Docker standard et sans privilèges root.

La même configuration est requise si votre objectif est d'[utiliser Podman sans privilèges root pour exécuter Docker](https://docs.gitlab.com/runner/executors/docker/#use-podman-to-run-docker-commands) avec Code Quality. Veillez à remplacer `/run/user/<gitlab-runner-user>/docker.sock` par le chemin `podman.sock` correct sur votre système, par exemple : `/run/user/<gitlab-runner-user>/podman/podman.sock`.

### Configurer les runners Kubernetes ou OpenShift {#configure-kubernetes-or-openshift-runners}

Vous devez configurer Docker dans un conteneur Docker (Docker-in-Docker) pour utiliser Code Quality. L'exécuteur Kubernetes [prend en charge Docker-in-Docker](https://docs.gitlab.com/runner/executors/kubernetes/#using-dockerdind).

Pour s'assurer que les jobs Code Quality peuvent s'exécuter sur un exécuteur Kubernetes :

- Si vous utilisez TLS pour communiquer avec le démon Docker, l'exécuteur [doit s'exécuter en mode privilégié](https://docs.gitlab.com/runner/executors/kubernetes/#other-configtoml-settings). De plus, le répertoire des certificats doit être [spécifié en tant que montage de volume](../docker/using_docker_build.md#docker-in-docker-with-tls-enabled-in-kubernetes).
- Il est possible que le service DinD ne démarre pas complètement avant le démarrage du job Code Quality. Il s'agit d'une limitation documentée dans [Dépannage de l'exécuteur Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/troubleshooting/#docker-cannot-connect-to-the-docker-daemon-at-tcpdocker2375-is-the-docker-daemon-running). Pour résoudre le problème, utilisez `before_script` pour attendre que le démon Docker démarre complètement. Pour un exemple, consultez la configuration dans le fichier `.gitlab-ci.yml` décrit dans la section suivante.

#### Kubernetes {#kubernetes}

Pour exécuter Code Quality dans Kubernetes :

- Le service Docker in Docker doit être ajouté en tant que conteneur de service dans le fichier `config.toml`.
- Le démon Docker dans le conteneur de service doit écouter sur un socket TCP et UNIX, car les deux sockets sont requis par Code Quality.
- Le socket Docker doit être partagé avec un volume.

En raison d'une [exigence Docker](https://docs.docker.com/reference/cli/docker/container/run/#privileged), l'indicateur de privilège doit être activé pour le conteneur de service.

```toml
[runners.kubernetes]

[runners.kubernetes.service_container_security_context]
privileged = true
allow_privilege_escalation = true

[runners.kubernetes.volumes]

[[runners.kubernetes.volumes.empty_dir]]
mount_path = "/var/run/"
name = "docker-sock"

[[runners.kubernetes.services]]
alias = "dind"
command = [
    "--host=tcp://0.0.0.0:2375",
    "--host=unix://var/run/docker.sock",
    "--storage-driver=overlay2"
]
entrypoint = ["dockerd"]
name = "docker:29.1.4-dind"
```

> [!note]
> Si vous utilisez le [GitLab Runner Helm Chart](https://docs.gitlab.com/runner/install/kubernetes/), vous pouvez utiliser la configuration Kubernetes précédente dans le [champ `config`](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration/) du fichier `values.yaml`.

Pour vous assurer d'utiliser le [pilote de stockage](https://docs.docker.com/storage/storagedriver/select-storage-driver/) `overlay2`, qui offre les meilleures performances globales :

- Spécifiez le `DOCKER_HOST` avec lequel la CLI Docker communique.
- Définissez la variable `DOCKER_DRIVER` sur une valeur vide.

Utilisez la section `before_script` pour attendre que le démon Docker démarre complètement. Depuis GitLab Runner v16.9, cela peut également être effectué [en définissant simplement la variable `HEALTHCHECK_TCP_PORT`](https://docs.gitlab.com/runner/executors/kubernetes/#define-a-list-of-services).

```yaml
include:
  - template: Code-Quality.gitlab-ci.yml

code_quality:
  services: []
  variables:
    DOCKER_HOST: tcp://dind:2375
    DOCKER_DRIVER: ""
  before_script:
    - while ! docker info > /dev/null 2>&1; do sleep 1; done
```

#### OpenShift {#openshift}

Pour OpenShift, vous devriez utiliser le [GitLab Runner Operator](https://docs.gitlab.com/runner/install/operator/). Pour accorder au démon Docker dans le conteneur de service les autorisations nécessaires à l'initialisation de son stockage, vous devez monter le répertoire `/var/lib` en tant que montage de volume.

> [!note]
> Si vous ne pouvez pas monter le répertoire `/var/lib` en tant que montage de volume, vous pouvez définir `--storage-driver` sur `vfs` à la place. Si vous optez pour la valeur `vfs`, cela peut avoir un impact négatif sur les [performances](https://docs.docker.com/storage/storagedriver/select-storage-driver/).

Pour configurer les autorisations du démon Docker :

1. Créez un fichier `config.toml` avec ce modèle de configuration pour personnaliser la configuration du runner :

```toml
[[runners]]

[runners.kubernetes]

[runners.kubernetes.service_container_security_context]
privileged = true
allow_privilege_escalation = true

[runners.kubernetes.volumes]

[[runners.kubernetes.volumes.empty_dir]]
mount_path = "/var/run/"
name = "docker-sock"

[[runners.kubernetes.volumes.empty_dir]]
mount_path = "/var/lib/"
name = "docker-data"

[[runners.kubernetes.services]]
alias = "dind"
command = [
    "--host=tcp://0.0.0.0:2375",
    "--host=unix://var/run/docker.sock",
    "--storage-driver=overlay2"
]
entrypoint = ["dockerd"]
name = "docker:29.1.4-dind"
```

1. [Définissez la configuration personnalisée sur votre runner](https://docs.gitlab.com/runner/configuration/configuring_runner_operator/#customize-configtoml-with-a-configuration-template).
1. Facultatif. Associez un [compte de service `privileged`](https://docs.openshift.com/container-platform/3.11/admin_guide/manage_scc.html) au Pod de build. Cela dépend de la configuration de votre cluster OpenShift :

   ```shell
   oc create sa dind-sa
   oc adm policy add-scc-to-user anyuid -z dind-sa
   oc adm policy add-scc-to-user -z dind-sa privileged
   ```

1. Définissez les autorisations dans la [section `[runners.kubernetes]`](https://docs.gitlab.com/runner/executors/kubernetes/#other-configtoml-settings).
1. Définissez la définition du job de la même manière que dans le cas Kubernetes :

   ```yaml
   include:
   - template: Code-Quality.gitlab-ci.yml

   code_quality:
   services: []
   variables:
     DOCKER_HOST: tcp://dind:2375
     DOCKER_DRIVER: ""
   before_script:
     - while ! docker info > /dev/null 2>&1; do sleep 1; done
   ```

#### Volumes et stockage Docker {#volumes-and-docker-storage}

Docker stocke toutes ses données dans le volume `/var/lib`, ce qui peut entraîner un volume important. Pour réutiliser le stockage Docker-in-Docker dans l'ensemble du cluster, vous pouvez utiliser des [volumes persistants](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) comme alternative.
<!--- end_remove -->
