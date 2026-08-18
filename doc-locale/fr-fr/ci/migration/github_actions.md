---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migrer depuis GitHub Actions
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Si vous migrez de GitHub Actions vers GitLab CI/CD, vous pouvez créer des pipelines CI/CD qui répliquent et améliorent vos workflows GitHub Actions.

Vous pouvez effectuer cette opération manuellement, ou utiliser l'agent de votre choix avec la [compétence d'agent GitHub Actions vers GitLab CI/CD](https://about.gitlab.com/github-actions-to-gitlab-ci/)

## Similitudes et différences clés {#key-similarities-and-differences}

GitHub Actions et GitLab CI/CD sont tous deux utilisés pour générer des pipelines afin d'automatiser la compilation, les tests et le déploiement de votre code. Ils partagent notamment les similitudes suivantes :

- La fonctionnalité CI/CD dispose d'un accès direct au code stocké dans le dépôt du projet.
- Les configurations de pipeline sont écrites en YAML et stockées dans le dépôt du projet.
- Les pipelines sont configurables et peuvent s'exécuter en différentes étapes.
- Chaque job peut utiliser une image de conteneur différente.

De plus, il existe certaines différences importantes entre les deux :

- GitHub dispose d'une marketplace pour télécharger des actions tierces, qui peuvent nécessiter une assistance ou des licences supplémentaires.
- GitLab Self-Managed prend en charge la mise à l'échelle horizontale et verticale, tandis que GitHub Enterprise Server ne prend en charge que la mise à l'échelle verticale.
- GitLab assure la maintenance et le support de toutes les fonctionnalités en interne, et certaines intégrations tierces sont accessibles via des templates.
- GitLab fournit un registre de conteneurs intégré.
- GitLab dispose d'une prise en charge native du déploiement Kubernetes.
- GitLab fournit des politiques de sécurité granulaires.

## Comparaison des fonctionnalités et des concepts {#comparison-of-features-and-concepts}

De nombreuses fonctionnalités et concepts GitHub ont des équivalents dans GitLab offrant les mêmes fonctionnalités.

### Fichier de configuration {#configuration-file}

GitHub Actions peut être configuré avec un [fichier YAML de workflow](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions#understanding-the-workflow-file). GitLab CI/CD utilise par défaut un fichier YAML `.gitlab-ci.yml`.

Par exemple, dans un fichier `workflow` GitHub Actions :

```yaml
on: [push]
jobs:
  hello:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Hello World"
```

Le fichier `.gitlab-ci.yml` GitLab CI/CD équivalent serait :

```yaml
stages:
  - hello

hello:
  stage: hello
  script:
    - echo "Hello World"
```

### Syntaxe de workflow GitHub Actions {#github-actions-workflow-syntax}

Une configuration GitHub Actions est définie dans un fichier YAML `workflow` à l'aide de mots-clés spécifiques. GitLab CI/CD dispose d'une fonctionnalité similaire, également configurée avec des mots-clés YAML.

| GitHub    | GitLab         | Explication |
|-----------|----------------|-------------|
| `env`     | `variables`    | `env` définit les variables définies dans un workflow, un job ou une étape. GitLab utilise `variables` pour définir les [variables CI/CD](../variables/_index.md) au niveau global ou du job. Les variables peuvent également être ajoutées via l'interface utilisateur. |
| `jobs`    | `stages`       | `jobs` regroupe tous les jobs qui s'exécutent dans le workflow. GitLab utilise `stages` pour regrouper les jobs. |
| `on`      | Sans objet | `on` définit le moment où un workflow est déclenché. GitLab est étroitement intégré à Git, de sorte que les options d'interrogation SCM pour les déclencheurs ne sont pas nécessaires, mais peuvent être configurées par job si besoin. |
| `run`     | Sans objet | La commande à exécuter dans le job. GitLab utilise un tableau YAML sous le mot-clé `script`, avec une entrée par commande à exécuter. |
| `runs-on` | `tags`         | `runs-on` définit le runner GitHub sur lequel un job doit s'exécuter. GitLab utilise `tags` pour sélectionner un runner. |
| `steps`   | `script`       | `steps` regroupe toutes les étapes qui s'exécutent dans un job. GitLab utilise `script` pour regrouper toutes les commandes exécutées dans un job. |
| `uses`    | `include`      | `uses` définit l'action GitHub Action à ajouter à un `step`. GitLab utilise `include` pour ajouter la configuration d'autres fichiers à un job. |

### Configurations courantes {#common-configurations}

Cette section passe en revue les configurations CI/CD couramment utilisées et montre comment les convertir de GitHub Actions vers GitLab CI/CD.

Les [workflows GitHub Actions](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions#workflows) génèrent des jobs CI/CD automatisés déclenchés lors de certains événements, par exemple lors du push d'un nouveau commit. Un workflow GitHub Actions est un fichier YAML défini dans le répertoire `.github/workflows` situé à la racine du dépôt. L'équivalent GitLab est le fichier de configuration `.gitlab-ci.yml`, qui réside également dans le répertoire racine du dépôt.

#### Jobs {#jobs}

Les jobs sont un ensemble de commandes qui s'exécutent dans une séquence définie pour atteindre un résultat particulier, par exemple la compilation d'un conteneur ou le déploiement en production.

Par exemple, ce `workflow` GitHub Actions compile un conteneur puis le déploie en production. Les jobs s'exécutent de manière séquentielle, car le job `deploy` dépend du job `build` :

```yaml
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    container: golang:alpine
    steps:
      - run: apk update
      - run: go build -o bin/hello
      - uses: actions/upload-artifact@v3
        with:
          name: hello
          path: bin/hello
          retention-days: 7
  deploy:
    if: contains( github.ref, 'staging')
    runs-on: ubuntu-latest
    container: golang:alpine
    steps:
      - uses: actions/download-artifact@v3
        with:
          name: hello
      - run: echo "Deploying to Staging"
      - run: scp bin/hello remoteuser@remotehost:/remote/directory
```

Cet exemple :

- Utilise l'image de conteneur `golang:alpine`.
- Exécute un job pour la compilation du code.
  - Stocke l'exécutable compilé en tant qu'artefact.
- Exécute un second job pour déployer vers `staging`, qui :
  - Nécessite que le job de compilation réussisse avant de s'exécuter.
  - Nécessite que la branche cible du commit soit `staging`.
  - Utilise l'artefact exécutable compilé.

Le fichier `.gitlab-ci.yml` GitLab CI/CD équivalent serait :

```yaml
default:
  image: golang:alpine

stages:
  - build
  - deploy

build-job:
  stage: build
  script:
    - apk update
    - go build -o bin/hello
  artifacts:
    paths:
      - bin/hello
    expire_in: 1 week

deploy-job:
  stage: deploy
  script:
    - echo "Deploying to Staging"
    - scp bin/hello remoteuser@remotehost:/remote/directory
  rules:
    - if: $CI_COMMIT_BRANCH == 'staging'
```

##### Parallèle {#parallel}

Dans GitHub et GitLab, les jobs s'exécutent en parallèle par défaut.

Par exemple, dans un fichier `workflow` GitHub Actions :

```yaml
on: [push]
jobs:
  python-version:
    runs-on: ubuntu-latest
    container: python:latest
    steps:
      - run: python --version
  java-version:
    if: contains( github.ref, 'staging')
    runs-on: ubuntu-latest
    container: openjdk:latest
    steps:
      - run: java -version
```

Cet exemple exécute un job Python et un job Java en parallèle, en utilisant des images de conteneur différentes. Le job Java ne s'exécute que lorsque la branche `staging` est modifiée.

Le fichier `.gitlab-ci.yml` GitLab CI/CD équivalent serait :

```yaml
python-version:
  image: python:latest
  script:
    - python --version

java-version:
  image: openjdk:latest
  rules:
    - if: $CI_COMMIT_BRANCH == 'staging'
  script:
    - java -version
```

Dans ce cas, aucune configuration supplémentaire n'est nécessaire pour que les jobs s'exécutent en parallèle. Les jobs s'exécutent en parallèle par défaut, chacun sur un runner différent, à condition qu'il y ait suffisamment de runners pour tous les jobs. Le job Java est configuré pour ne s'exécuter que lorsque la branche `staging` est modifiée.

##### Matrice {#matrix}

Dans GitLab et GitHub, vous pouvez utiliser une matrice pour exécuter un job plusieurs fois en parallèle dans un seul pipeline, mais avec des valeurs de variables différentes pour chaque instance du job.

Par exemple, dans un fichier `workflow` GitHub Actions :

```yaml
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Building $PLATFORM for $ARCH"
    strategy:
      matrix:
        platform: [linux, mac, windows]
        arch: [x64, x86]
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Testing $PLATFORM for $ARCH"
    strategy:
      matrix:
        platform: [linux, mac, windows]
        arch: [x64, x86]
  deploy:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying $PLATFORM for $ARCH"
    strategy:
      matrix:
        platform: [linux, mac, windows]
        arch: [x64, x86]
```

Le fichier `.gitlab-ci.yml` GitLab CI/CD équivalent serait :

```yaml
stages:
  - build
  - test
  - deploy

.parallel-hidden-job:
  parallel:
    matrix:
      - PLATFORM: [linux, mac, windows]
        ARCH: [x64, x86]

build-job:
  extends: .parallel-hidden-job
  stage: build
  script:
    - echo "Building $PLATFORM for $ARCH"

test-job:
  extends: .parallel-hidden-job
  stage: test
  script:
    - echo "Testing $PLATFORM for $ARCH"

deploy-job:
  extends: .parallel-hidden-job
  stage: deploy
  script:
    - echo "Deploying $PLATFORM for $ARCH"
```

#### Déclencheur {#trigger}

GitHub Actions nécessite l'ajout d'un déclencheur pour votre workflow. GitLab est étroitement intégré à Git, de sorte que les options d'interrogation SCM pour les déclencheurs ne sont pas nécessaires, mais peuvent être configurées par job si besoin.

Exemple de configuration GitHub Actions :

```yaml
on:
  push:
    branches:
      - main
```

La configuration GitLab CI/CD équivalente serait :

```yaml
rules:
  - if: '$CI_COMMIT_BRANCH == main'
```

Les pipelines peuvent également être [planifiés à l'aide de la syntaxe Cron](../pipelines/schedules.md).

#### Images de conteneur {#container-images}

Avec GitLab, vous pouvez [exécuter vos jobs CI/CD dans des conteneurs Docker séparés et isolés](../docker/using_docker_images.md) en utilisant le mot-clé [`image`](../yaml/_index.md#image).

Par exemple, dans un fichier `workflow` GitHub Actions :

```yaml
jobs:
  update:
    runs-on: ubuntu-latest
    container: alpine:latest
    steps:
      - run: apk update
```

Dans cet exemple, la commande `apk update` s'exécute dans un conteneur `alpine:latest`.

Le fichier `.gitlab-ci.yml` GitLab CI/CD équivalent serait :

```yaml
update-job:
  image: alpine:latest
  script:
    - apk update
```

GitLab fournit à chaque projet un [registre de conteneurs](../../user/packages/container_registry/_index.md) pour héberger les images de conteneur. Les images de conteneur peuvent être compilées et stockées directement depuis les pipelines CI/CD GitLab.

Par exemple :

```yaml
stages:
  - build

build-image:
  stage: build
  variables:
    IMAGE: $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $IMAGE .
    - docker push $IMAGE
```

#### Variables {#variables}

Vous pouvez utiliser le mot-clé `variables` pour définir différentes [variables CI/CD](../variables/_index.md) au moment de l'exécution. Utilisez des variables lorsque vous avez besoin de réutiliser des données de configuration dans un pipeline. Vous pouvez définir des variables globalement ou par job.

Par exemple, dans un fichier `workflow` GitHub Actions :

```yaml
env:
  NAME: "fern"

jobs:
  english:
    runs-on: ubuntu-latest
    env:
      Greeting: "hello"
    steps:
      - run: echo "$GREETING $NAME"
  spanish:
    runs-on: ubuntu-latest
    env:
      Greeting: "hola"
    steps:
      - run: echo "$GREETING $NAME"
```

Dans cet exemple, les variables fournissent des sorties différentes pour les jobs.

Le fichier `.gitlab-ci.yml` GitLab CI/CD équivalent serait :

```yaml
default:
  image: ubuntu-latest

variables:
  NAME: "fern"

english:
  variables:
    GREETING: "hello"
  script:
    - echo "$GREETING $NAME"

spanish:
  variables:
    GREETING: "hola"
  script:
    - echo "$GREETING $NAME"
```

Les variables peuvent également être configurées via l'interface utilisateur GitLab, dans les paramètres CI/CD, où vous pouvez [protéger](../variables/_index.md#protect-a-cicd-variable) ou [masquer](../variables/_index.md#mask-a-cicd-variable) les variables. Les variables masquées sont cachées dans les job logs, tandis que les variables protégées ne sont accessibles que dans les pipelines pour les branches ou tags protégés.

Par exemple, dans un fichier `workflow` GitHub Actions :

```yaml
jobs:
  login:
    runs-on: ubuntu-latest
    env:
      AWS_ACCESS_KEY: ${{ secrets.AWS_ACCESS_KEY }}
    steps:
      - run: my-login-script.sh "$AWS_ACCESS_KEY"
```

Si la variable `AWS_ACCESS_KEY` est définie dans les paramètres du projet GitLab, le fichier `.gitlab-ci.yml` GitLab CI/CD équivalent serait :

```yaml
login:
  script:
    - my-login-script.sh $AWS_ACCESS_KEY
```

De plus, [GitHub Actions](https://docs.github.com/en/actions/learn-github-actions/contexts) et [GitLab CI/CD](../variables/predefined_variables.md) fournissent des variables intégrées contenant des données pertinentes pour le pipeline et le dépôt.

#### Conditions {#conditionals}

Lorsqu'un nouveau pipeline démarre, GitLab vérifie la configuration du pipeline pour déterminer quels jobs doivent s'exécuter dans ce pipeline. Vous pouvez utiliser le [mot-clé `rules`](../yaml/_index.md#rules) pour configurer les jobs à exécuter en fonction de conditions telles que le statut des variables ou le type de pipeline.

Par exemple, dans un fichier `workflow` GitHub Actions :

```yaml
jobs:
  deploy_staging:
    if: contains( github.ref, 'staging')
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploy to staging server"
```

Le fichier `.gitlab-ci.yml` GitLab CI/CD équivalent serait :

```yaml
deploy_staging:
  stage: deploy
  script:
    - echo "Deploy to staging server"
  rules:
    - if: '$CI_COMMIT_BRANCH == staging'
```

#### Runners {#runners}

Les runners sont les services qui exécutent les jobs. Si vous utilisez GitLab.com, vous pouvez utiliser la [flotte de runners d'instance](../runners/_index.md) pour exécuter des jobs sans provisionner vos propres runners auto-gérés.

Quelques informations clés sur les runners :

- Les runners peuvent être [configurés](../runners/runners_scope.md) pour être partagés à l'échelle d'une instance, d'un groupe, ou dédiés à un seul projet.
- Vous pouvez utiliser le [mot-clé `tags`](../runners/configure_runners.md#control-jobs-that-a-runner-can-run) pour un contrôle plus précis et associer les runners à des jobs spécifiques. Par exemple, vous pouvez utiliser un tag pour les jobs nécessitant du matériel dédié, plus puissant ou spécifique.
- GitLab dispose de la [mise à l'échelle automatique pour les runners](https://docs.gitlab.com/runner/configuration/autoscale/). Utilisez la mise à l'échelle automatique pour provisionner les runners uniquement lorsque nécessaire et les réduire lorsqu'ils ne sont pas utilisés.

Par exemple, dans un fichier `workflow` GitHub Actions :

```yaml
linux_job:
  runs-on: ubuntu-latest
  steps:
    - run: echo "Hello, $USER"

windows_job:
  runs-on: windows-latest
  steps:
    - run: echo "Hello, %USERNAME%"
```

Le fichier `.gitlab-ci.yml` GitLab CI/CD équivalent serait :

```yaml
linux_job:
  stage: build
  tags:
    - linux-runners
  script:
    - echo "Hello, $USER"

windows_job:
  stage: build
  tags:
    - windows-runners
  script:
    - echo "Hello, %USERNAME%"
```

#### Artefacts {#artifacts}

Dans GitLab, tout job peut utiliser le mot-clé [artifacts](../yaml/_index.md#artifacts) pour définir un ensemble d'artefacts à stocker à la fin du job. Les [artefacts](../jobs/job_artifacts.md) sont des fichiers qui peuvent être utilisés dans des jobs ultérieurs.

Par exemple, dans un fichier `workflow` GitHub Actions :

```yaml
on: [push]
jobs:
  generate_cat:
    steps:
      - run: touch cat.txt
      - run: echo "meow" > cat.txt
      - uses: actions/upload-artifact@v3
        with:
          name: cat
          path: cat.txt
          retention-days: 7
  use_cat:
    needs: [generate_cat]
    steps:
      - uses: actions/download-artifact@v3
        with:
          name: cat
      - run: cat cat.txt
```

Le fichier `.gitlab-ci.yml` GitLab CI/CD équivalent serait :

```yaml
stage:
  - generate
  - use

generate_cat:
  stage: generate
  script:
    - touch cat.txt
    - echo "meow" > cat.txt
  artifacts:
    paths:
      - cat.txt
    expire_in: 1 week

use_cat:
  stage: use
  script:
    - cat cat.txt
```

#### Mise en cache {#caching}

Un [cache](../caching/_index.md) est créé lorsqu'un job télécharge un ou plusieurs fichiers et les enregistre pour y accéder plus rapidement à l'avenir. Les jobs suivants utilisant le même cache n'ont pas à télécharger les fichiers à nouveau et s'exécutent donc plus rapidement. Le cache est stocké sur le runner et chargé vers S3 si le [cache distribué est activé](https://docs.gitlab.com/runner/configuration/autoscale/#distributed-runners-caching).

Par exemple, dans un fichier `workflow` GitHub Actions :

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - run: echo "This job uses a cache."
    - uses: actions/cache@v3
      with:
        path: binaries/
        key: binaries-cache-$CI_COMMIT_REF_SLUG
```

Le fichier `.gitlab-ci.yml` GitLab CI/CD équivalent serait :

```yaml
cache-job:
  script:
    - echo "This job uses a cache."
  cache:
    key: binaries-cache-$CI_COMMIT_REF_SLUG
    paths:
      - binaries/
```

#### Templates {#templates}

Dans GitHub, une action est un ensemble de tâches complexes devant être fréquemment répétées et enregistrées pour permettre leur réutilisation sans avoir à redéfinir un pipeline CI/CD. Dans GitLab, l'équivalent d'une action serait le [mot-clé `include`](../yaml/includes.md), qui vous permet d'[ajouter des pipelines CI/CD depuis d'autres fichiers](../yaml/includes.md), y compris des fichiers de template intégrés à GitLab.

Exemple de configuration GitHub Actions :

```yaml
- uses: hashicorp/setup-terraform@v2.0.3
```

La configuration GitLab CI/CD équivalente serait :

```yaml
include:
  - template: Terraform.gitlab-ci.yml
```

Dans ces exemples, l'action GitHub `setup-terraform` et le template GitLab `Terraform.gitlab-ci.yml` ne sont pas des équivalents exacts. Ces deux exemples servent uniquement à montrer comment une configuration complexe peut être réutilisée.

### Fonctionnalités d'analyse de sécurité {#security-scanning-features}

GitLab fournit une variété de [scanners de sécurité](../../user/application_security/_index.md) prêts à l'emploi pour détecter les vulnérabilités dans toutes les parties du SLDC. Vous pouvez ajouter ces fonctionnalités à votre pipeline CI/CD GitLab en utilisant des templates.

Par exemple, pour ajouter l'analyse SAST à votre pipeline, ajoutez ce qui suit à votre `.gitlab-ci.yml` :

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml
```

Vous pouvez personnaliser le comportement des scanners de sécurité à l'aide de variables CI/CD, par exemple avec les [scanners SAST](../../user/application_security/sast/_index.md#available-cicd-variables).

### Gestion des secrets {#secrets-management}

Les informations privilégiées, souvent appelées « secrets », sont des informations sensibles ou des identifiants dont vous avez besoin dans votre workflow CI/CD. Vous pouvez utiliser des secrets pour déverrouiller des ressources protégées ou des informations sensibles dans des outils, des applications, des conteneurs et des environnements cloud natifs.

Pour la gestion des secrets dans GitLab, vous pouvez utiliser l'une des [intégrations prises en charge](../secrets/_index.md) pour un service externe. Ces services stockent les secrets de manière sécurisée en dehors de votre projet GitLab, bien que vous deviez disposer d'un abonnement au service.

GitLab prend également en charge l'[authentification OIDC](../secrets/id_token_authentication.md) pour d'autres services tiers qui prennent en charge OIDC.

De plus, vous pouvez rendre les identifiants disponibles pour les jobs en les stockant dans des variables CI/CD, bien que les secrets stockés en texte clair soient susceptibles d'être exposés accidentellement. Vous devez toujours stocker les informations sensibles dans des variables [masquées](../variables/_index.md#mask-a-cicd-variable) et [protégées](../variables/_index.md#protect-a-cicd-variable), ce qui atténue une partie du risque.

De plus, ne stockez jamais des secrets en tant que variables dans votre fichier `.gitlab-ci.yml`, qui est public pour tous les utilisateurs ayant accès au projet. Le stockage d'informations sensibles dans des variables ne doit être effectué que dans [les paramètres du projet, du groupe ou de l'instance](../variables/_index.md#define-a-cicd-variable-in-the-ui).

Consultez les [recommandations de sécurité](../variables/_index.md#cicd-variable-security) pour améliorer la sécurité de vos variables CI/CD.

## Planification et réalisation d'une migration {#planning-and-performing-a-migration}

La liste de recommandations suivante a été établie après observation des organisations ayant réussi à effectuer rapidement cette migration.

### Créer un plan de migration {#create-a-migration-plan}

Avant de démarrer une migration, vous devez créer un [plan de migration](plan_a_migration.md) afin de préparer la migration.

### Prérequis {#prerequisites}

Avant d'effectuer tout travail de migration, vous devez d'abord :

1. Vous familiariser avec GitLab.
   - Lire la documentation sur les [fonctionnalités clés de GitLab CI/CD](../_index.md).
   - Suivre des tutoriels pour créer [votre premier pipeline GitLab](../quick_start/_index.md) et des [pipelines plus complexes](../quick_start/tutorial.md) qui compilent, testent et déploient un site statique.
   - Consulter la [référence de la syntaxe YAML CI/CD](../yaml/_index.md).
1. Configurer GitLab.
1. Tester votre instance GitLab.
   - S'assurer que des [runners](../runners/_index.md) sont disponibles, soit en utilisant les runners partagés de GitLab.com, soit en installant de nouveaux runners.

### Étapes de migration {#migration-steps}

1. Migrer les projets de GitHub vers GitLab :
   - (Recommandé) Vous pouvez utiliser l'[importateur GitHub](../../user/project/import/github.md) pour automatiser les imports en masse depuis des fournisseurs SCM externes.
   - Vous pouvez [importer des dépôts par URL](../../user/import/third_party_systems/repo_by_url.md).
1. Créer un fichier `.gitlab-ci.yml` dans chaque projet.
1. Migrer les jobs GitHub Actions vers des jobs GitLab CI/CD et les configurer pour afficher les résultats directement dans les merge requests. Cette opération peut être automatisée à l'aide de la [compétence d'agent fournie](https://gitlab.com/gitlab-org/ci-cd/github-actions-to-gitlab-ci).
1. Migrer les jobs de déploiement en utilisant les [templates de déploiement cloud](../cloud_deployment/_index.md), les [environnements](../environments/_index.md) et l'[agent GitLab pour Kubernetes](../../user/clusters/agent/_index.md).
1. Vérifier si une configuration CI/CD peut être réutilisée entre différents projets, puis créer et partager des [composants CI/CD](../components/_index.md).
1. Consulter la [documentation sur l'efficacité des pipelines](../pipelines/pipeline_efficiency.md) pour apprendre à rendre vos pipelines CI/CD GitLab plus rapides et plus efficaces.

### Ressources supplémentaires {#additional-resources}

- [Vidéo : Comment migrer de GitHub vers GitLab, y compris les Actions](https://youtu.be/0Id5oMl1Kqs?feature=shared)
- [Blog : Migration de GitHub vers GitLab, la méthode simple](https://about.gitlab.com/blog/github-to-gitlab-migration-made-easy/)

Si vous avez des questions auxquelles vous ne trouvez pas de réponse ici, le [forum de la communauté GitLab](https://forum.gitlab.com/) peut être une excellente ressource.
