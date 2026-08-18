---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migrer depuis Jenkins
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Si vous migrez de Jenkins vers GitLab CI/CD, vous pouvez créer des pipelines CI/CD qui répliquent et améliorent vos workflows Jenkins.

## Principales similitudes et différences {#key-similarities-and-differences}

GitLab CI/CD et Jenkins sont des outils CI/CD présentant certaines similitudes. GitLab et Jenkins utilisent tous deux :

- Des étapes pour regrouper des collections de jobs.
- La prise en charge des builds basés sur des conteneurs.

Par ailleurs, il existe quelques différences importantes entre les deux :

- Les pipelines CI/CD GitLab sont tous configurés dans un fichier de configuration au format YAML. Jenkins utilise soit un fichier de configuration au format Groovy (pipelines déclaratifs), soit Jenkins DSL (pipelines scriptés).
- GitLab propose [GitLab.com](../../subscriptions/manage_seats.md#gitlabcom-billing-and-usage), un service SaaS multi-locataire, et [GitLab Dedicated](../../subscriptions/gitlab_dedicated/_index.md), un service mono-locataire totalement isolé. Vous pouvez également exécuter votre propre instance [GitLab Self-Managed](../../subscriptions/manage_subscription.md). Les déploiements Jenkins doivent être auto-hébergés.
- GitLab fournit la gestion du code source (SCM) nativement. Jenkins nécessite une solution SCM distincte pour stocker le code.
- GitLab fournit un registre de conteneurs intégré. Jenkins nécessite une solution distincte pour stocker les images de conteneurs.
- GitLab fournit des modèles intégrés pour l'analyse du code. Jenkins nécessite des plugins tiers pour l'analyse du code.

## Comparaison des fonctionnalités et des concepts {#comparison-of-features-and-concepts}

De nombreuses fonctionnalités et de nombreux concepts Jenkins ont des équivalents dans GitLab offrant les mêmes fonctionnalités.

### Fichier de configuration {#configuration-file}

Jenkins peut être configuré avec un [`Jenkinsfile` au format Groovy](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/). GitLab CI/CD utilise un fichier `.gitlab-ci.yml` par défaut.

Exemple de `Jenkinsfile` :

```groovy
pipeline {
    agent any

    stages {
        stage('hello') {
            steps {
                echo "Hello World"
            }
        }
    }
}
```

Le fichier `.gitlab-ci.yml` GitLab CI/CD équivalent serait :

```yaml
stages:
  - hello

hello-job:
  stage: hello
  script:
    - echo "Hello World"
```

### Syntaxe de pipeline Jenkins {#jenkins-pipeline-syntax}

Une configuration Jenkins est composée d'un bloc `pipeline` avec des sections et des directives. GitLab CI/CD dispose d'une fonctionnalité similaire, configurée avec des mots-clés YAML.

#### Sections {#sections}

| Jenkins  | GitLab         | Explication |
|----------|----------------|-------------|
| `agent`  | `image`        | Les pipelines CI/CD Jenkins s'exécutent sur des agents, et la section `agent` définit comment le pipeline s'exécute, ainsi que le conteneur Docker à utiliser. Les jobs GitLab s'exécutent sur des runners, et le mot-clé `image` définit le conteneur à utiliser. Vous pouvez configurer vos propres runners dans Kubernetes ou sur n'importe quel hôte. |
| `post`   | `after_script` ou `stage` | La section Jenkins `post` définit les actions à effectuer à la fin d'une étape ou d'un pipeline. Dans GitLab, utilisez `after_script` pour les commandes à exécuter à la fin d'un job, et `before_script` pour les actions à exécuter avant les autres commandes d'un job. Utilisez `stage` pour sélectionner l'étape exacte dans laquelle un job doit s'exécuter. GitLab prend en charge les étapes `.pre` et `.post`, qui s'exécutent toujours avant ou après toutes les autres étapes définies. |
| `stages` | `stages`       | Les étapes Jenkins sont des groupes de jobs. GitLab CI/CD utilise également des étapes, mais offre plus de flexibilité. Vous pouvez avoir plusieurs étapes, chacune avec plusieurs jobs indépendants. Utilisez `stages` au niveau supérieur pour définir les étapes et leur ordre d'exécution, et utilisez `stage` au niveau du job pour définir l'étape de ce job. |
| `steps`  | `script`       | Les `steps` Jenkins définissent ce qui doit être exécuté. GitLab CI/CD utilise une section `script` similaire. La section `script` est un tableau YAML avec des entrées distinctes pour chaque commande à exécuter en séquence. |

#### Directives {#directives}

| Jenkins       | GitLab         | Explication |
|---------------|----------------|-------------|
| `environment` | `variables`    | Jenkins utilise `environment` pour les variables d'environnement. GitLab CI/CD utilise le mot-clé `variables` pour définir les variables CI/CD pouvant être utilisées lors de l'exécution d'un job, mais aussi pour une configuration de pipeline plus dynamique. Ces variables peuvent également être définies dans l'interface GitLab, sous les paramètres CI/CD. |
| `options`     | Non applicable | Jenkins utilise `options` pour la configuration supplémentaire, notamment les délais d'expiration et les valeurs de nouvelle tentative. GitLab n'a pas besoin d'une section distincte pour les options ; toute la configuration est ajoutée en tant que mots-clés CI/CD au niveau du job ou du pipeline, par exemple `timeout` ou `retry`. |
| `parameters`  | Non applicable | Dans Jenkins, des paramètres peuvent être requis lors du déclenchement d'un pipeline. Les paramètres sont gérés dans GitLab avec des variables CI/CD, qui peuvent être définies à de nombreux endroits, notamment dans la configuration du pipeline, les paramètres du projet, au moment de l'exécution manuellement via l'interface utilisateur, ou via l'API. |
| `triggers`    | `rules`        | Dans Jenkins, `triggers` définit quand un pipeline doit s'exécuter à nouveau, par exemple via la notation cron. GitLab CI/CD peut exécuter des pipelines automatiquement pour de nombreuses raisons, notamment les modifications Git et les mises à jour de merge requests. Utilisez le mot-clé `rules` pour contrôler les événements pour lesquels exécuter des jobs. Les pipelines planifiés sont définis dans les paramètres du projet. |
| `tools`       | Non applicable | Dans Jenkins, `tools` définit les outils supplémentaires à installer dans l'environnement. GitLab ne dispose pas d'un mot-clé similaire, car il est recommandé d'utiliser des images de conteneurs préconstruites avec les outils exacts requis pour vos jobs. Ces images peuvent être mises en cache et peuvent être construites pour contenir déjà les outils dont vous avez besoin pour vos pipelines. Si un job nécessite des outils supplémentaires, ils peuvent être installés dans le cadre d'une section `before_script`. |
| `input`       | Non applicable | Dans Jenkins, `input` ajoute une invite pour la saisie utilisateur. Comme pour `parameters`, les entrées sont gérées dans GitLab via des variables CI/CD. |
| `when`        | `rules`        | Dans Jenkins, `when` définit quand une étape doit être exécutée. GitLab dispose également d'un mot-clé `when`, qui définit si un job doit démarrer en fonction du statut des jobs précédents, par exemple si les jobs ont réussi ou échoué. Pour contrôler quand ajouter des jobs à des pipelines spécifiques, utilisez `rules`. |

### Configurations courantes {#common-configurations}

Cette section passe en revue les configurations CI/CD couramment utilisées, en montrant comment elles peuvent être converties de Jenkins vers GitLab CI/CD.

[Les pipelines Jenkins](https://www.jenkins.io/doc/book/pipeline/) génèrent des jobs CI/CD automatisés déclenchés lorsque certains événements se produisent, comme le push d'un nouveau commit. Un pipeline Jenkins est défini dans un `Jenkinsfile`. L'équivalent GitLab est le [fichier de configuration `.gitlab-ci.yml`](../yaml/_index.md).

Jenkins ne fournit pas d'emplacement pour stocker le code source, de sorte que le `Jenkinsfile` doit être stocké dans un dépôt de contrôle de source distinct.

#### Jobs {#jobs}

Les jobs sont un ensemble de commandes qui s'exécutent dans une séquence définie pour atteindre un résultat particulier.

Par exemple, construire un conteneur puis le déployer en production, dans un `Jenkinsfile` :

```groovy
pipeline {
    agent any
    stages {
        stage('build') {
            agent { docker 'golang:alpine' }
            steps {
                apk update
                go build -o bin/hello
            }
            post {
              always {
                archiveArtifacts artifacts: 'bin/hello'
                onlyIfSuccessful: true
              }
            }
        }
        stage('deploy') {
            agent { docker 'golang:alpine' }
            when {
              branch 'staging'
            }
            steps {
                echo "Deploying to staging"
                scp bin/hello remoteuser@remotehost:/remote/directory
            }
        }
    }
}
```

Cet exemple :

- Utilise l'image de conteneur `golang:alpine`.
- Exécute un job pour construire le code.
  - Stocke l'exécutable construit en tant qu'artefact.
- Ajoute un second job pour déployer sur `staging`, qui :
  - N'existe que si le commit cible la branche `staging`.
  - Démarre une fois que l'étape de build réussit.
  - Utilise l'artefact exécutable construit par le job précédent.

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
  artifacts:
    paths:
      - bin/hello
```

##### Parallèle {#parallel}

Dans Jenkins, les jobs qui ne dépendent pas des jobs précédents peuvent s'exécuter en parallèle lorsqu'ils sont ajoutés à une section `parallel`.

Par exemple, dans un `Jenkinsfile` :

```groovy
pipeline {
    agent any
    stages {
        stage('Parallel') {
            parallel {
                stage('Python') {
                    agent { docker 'python:latest' }
                    steps {
                        sh "python --version"
                    }
                }
                stage('Java') {
                    agent { docker 'openjdk:latest' }
                    when {
                        branch 'staging'
                    }
                    steps {
                        sh "java -version"
                    }
                }
            }
        }
    }
}
```

Cet exemple exécute un job Python et un job Java en parallèle, en utilisant différentes images de conteneurs. Le job Java ne s'exécute que lorsque la branche `staging` est modifiée.

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

Dans ce cas, aucune configuration supplémentaire n'est nécessaire pour que les jobs s'exécutent en parallèle. Les jobs s'exécutent en parallèle par défaut, chacun sur un runner différent, en supposant qu'il y ait suffisamment de runners pour tous les jobs. Le job Java est configuré pour ne s'exécuter que lorsque la branche `staging` est modifiée.

##### Matrice {#matrix}

Dans GitLab, vous pouvez utiliser une matrice pour exécuter un job plusieurs fois en parallèle dans un seul pipeline, mais avec des valeurs de variables différentes pour chaque instance du job. Jenkins exécute la matrice de manière séquentielle.

Par exemple, dans un `Jenkinsfile` :

```groovy
matrix {
    axes {
        axis {
            name 'PLATFORM'
            values 'linux', 'mac', 'windows'
        }
        axis {
            name 'ARCH'
            values 'x64', 'x86'
        }
    }
    stages {
        stage('build') {
            echo "Building $PLATFORM for $ARCH"
        }
        stage('test') {
            echo "Building $PLATFORM for $ARCH"
        }
        stage('deploy') {
            echo "Building $PLATFORM for $ARCH"
        }
    }
}
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
    - echo "Testing $PLATFORM for $ARCH"
```

#### Images de conteneurs {#container-images}

Dans GitLab, vous pouvez [exécuter vos jobs CI/CD dans des conteneurs Docker séparés et isolés](../docker/using_docker_images.md) en utilisant le mot-clé [image](../yaml/_index.md#image).

Par exemple, dans un `Jenkinsfile` :

```groovy
stage('Version') {
    agent { docker 'python:latest' }
    steps {
        echo 'Hello Python'
        sh 'python --version'
    }
}
```

Cet exemple montre des commandes s'exécutant dans un conteneur `python:latest`.

Le fichier `.gitlab-ci.yml` GitLab CI/CD équivalent serait :

```yaml
version-job:
  image: python:latest
  script:
    - echo "Hello Python"
    - python --version
```

#### Variables {#variables}

Dans GitLab, utilisez le mot-clé `variables` pour définir des [variables CI/CD](../variables/_index.md). Utilisez des variables pour réutiliser des données de configuration, disposer d'une configuration plus dynamique ou stocker des valeurs importantes. Les variables peuvent être définies globalement ou par job.

Par exemple, dans un `Jenkinsfile` :

```groovy
pipeline {
    agent any
    environment {
        NAME = 'Fern'
    }
    stages {
        stage('English') {
            environment {
                GREETING = 'Hello'
            }
            steps {
                sh 'echo "$GREETING $NAME"'
            }
        }
        stage('Spanish') {
            environment {
                GREETING = 'Hola'
            }
            steps {
                sh 'echo "$GREETING $NAME"'
            }
        }
    }
}
```

Cet exemple montre comment les variables peuvent être utilisées pour transmettre des valeurs aux commandes dans les jobs.

Le fichier `.gitlab-ci.yml` GitLab CI/CD équivalent serait :

```yaml
default:
  image: alpine:latest

stages:
  - greet

variables:
  NAME: "Fern"

english:
  stage: greet
  variables:
    GREETING: "Hello"
  script:
    - echo "$GREETING $NAME"

spanish:
  stage: greet
  variables:
    GREETING: "Hola"
  script:
    - echo "$GREETING $NAME"
```

Les variables peuvent également être [définies dans l'interface GitLab, dans les paramètres CI/CD](../variables/_index.md#define-a-cicd-variable-in-the-ui). Dans certains cas, vous pouvez utiliser des variables [protégées](../variables/_index.md#protect-a-cicd-variable) et [masquées](../variables/_index.md#mask-a-cicd-variable) pour les valeurs secrètes. Ces variables sont accessibles dans les jobs de pipeline de la même manière que les variables définies dans le fichier de configuration.

Par exemple, dans un `Jenkinsfile` :

```groovy
pipeline {
    agent any
    stages {
        stage('Example Username/Password') {
            environment {
                AWS_ACCESS_KEY = credentials('aws-access-key')
            }
            steps {
                sh 'my-login-script.sh $AWS_ACCESS_KEY'
            }
        }
    }
}
```

Le fichier `.gitlab-ci.yml` GitLab CI/CD équivalent serait :

```yaml
login-job:
  script:
    - my-login-script.sh $AWS_ACCESS_KEY
```

De plus, GitLab CI/CD met à disposition des [variables prédéfinies](../variables/predefined_variables.md) pour chaque pipeline et job, contenant des valeurs pertinentes pour le pipeline et le dépôt.

#### Expressions et conditionnelles {#expressions-and-conditionals}

Lorsqu'un nouveau pipeline démarre, GitLab vérifie quels jobs doivent s'exécuter dans ce pipeline. Vous pouvez configurer des jobs pour qu'ils s'exécutent en fonction de facteurs tels que le statut des variables ou le type de pipeline.

Par exemple, dans un `Jenkinsfile` :

```groovy
stage('deploy_staging') {
    agent { docker 'alpine:latest' }
    when {
        branch 'staging'
    }
    steps {
        echo "Deploying to staging"
    }
}
```

Dans cet exemple, le job ne s'exécute que lorsque la branche sur laquelle vous effectuez un commit est nommée `staging`.

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

Comme les agents Jenkins, les runners GitLab sont les hôtes qui exécutent les jobs. Si vous utilisez GitLab.com, vous pouvez utiliser la [flotte de runners d'instance](../runners/_index.md) pour exécuter des jobs sans provisionner vos propres runners.

Pour convertir un agent Jenkins en vue d'une utilisation avec GitLab CI/CD, désinstallez l'agent, puis [installez et enregistrez un runner](../runners/_index.md). Les runners ne nécessitent pas beaucoup de surcharge, vous pourrez donc peut-être utiliser un provisionnement similaire à celui des agents Jenkins que vous utilisiez.

Quelques informations clés sur les runners :

- Les runners peuvent être [configurés](../runners/runners_scope.md) pour être partagés entre une instance, un groupe, ou dédiés à un seul projet.
- Vous pouvez utiliser le [mot-clé `tags`](../runners/configure_runners.md#control-jobs-that-a-runner-can-run) pour un contrôle plus précis et associer des runners à des jobs spécifiques. Par exemple, vous pouvez utiliser un tag pour les jobs nécessitant du matériel dédié, plus puissant ou spécifique.
- GitLab dispose de la [mise à l'échelle automatique pour les runners](https://docs.gitlab.com/runner/configuration/autoscale/). Utilisez la mise à l'échelle automatique pour provisionner des runners uniquement lorsque c'est nécessaire et les réduire lorsqu'ils ne le sont plus.

Par exemple, dans un `Jenkinsfile` :

```groovy
pipeline {
    agent none
    stages {
        stage('Linux') {
            agent {
                label 'linux'
            }
            steps {
                echo "Hello, $USER"
            }
        }
        stage('Windows') {
            agent {
                label 'windows'
            }
            steps {
                echo "Hello, %USERNAME%"
            }
        }
    }
}
```

Le fichier `.gitlab-ci.yml` GitLab CI/CD équivalent serait :

```yaml
linux_job:
  stage: build
  tags:
    - linux
  script:
    - echo "Hello, $USER"

windows_job:
  stage: build
  tags:
    - windows
  script:
    - echo "Hello, %USERNAME%"
```

#### Artefacts {#artifacts}

Dans GitLab, tout job peut utiliser le mot-clé [`artifacts`](../yaml/_index.md#artifacts) pour définir un ensemble d'artefacts à stocker à la fin d'un job. [Les artefacts](../jobs/job_artifacts.md) sont des fichiers pouvant être utilisés dans des jobs ultérieurs, par exemple à des fins de test ou de déploiement.

Par exemple, dans un `Jenkinsfile` :

```groovy
stages {
    stage('Generate Cat') {
        steps {
            sh 'touch cat.txt'
            sh 'echo "meow" > cat.txt'
        }
        post {
            always {
                archiveArtifacts artifacts: 'cat.txt'
                onlyIfSuccessful: true
            }
        }
    }
    stage('Use Cat') {
        steps {
            sh 'cat cat.txt'
        }
    }
  }
```

Le fichier `.gitlab-ci.yml` GitLab CI/CD équivalent serait :

```yaml
stages:
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
  artifacts:
    paths:
      - cat.txt
```

#### Mise en cache {#caching}

Un [cache](../caching/_index.md) est créé lorsqu'un job télécharge un ou plusieurs fichiers et les enregistre pour un accès plus rapide ultérieurement. Les jobs suivants utilisant le même cache n'ont pas à télécharger à nouveau les fichiers, ce qui leur permet de s'exécuter plus rapidement. Le cache est stocké sur le runner et téléchargé vers S3 si le [cache distribué est activé](https://docs.gitlab.com/runner/configuration/autoscale/#distributed-runners-caching). Jenkins core ne fournit pas de mise en cache.

Par exemple, dans un fichier `.gitlab-ci.yml` :

```yaml
cache-job:
  script:
    - echo "This job uses a cache."
  cache:
    key: binaries-cache-$CI_COMMIT_REF_SLUG
    paths:
      - binaries/
```

### Plugins Jenkins {#jenkins-plugins}

Certaines fonctionnalités de Jenkins activées via des plugins sont prises en charge nativement dans GitLab avec des mots-clés et des fonctionnalités offrant des fonctionnalités similaires. Par exemple :

| Plugin Jenkins                                                                    | Fonctionnalité GitLab |
|-----------------------------------------------------------------------------------|----------------|
| [Build Timeout](https://plugins.jenkins.io/build-timeout/)                        | [mot-clé `timeout`](../yaml/_index.md#timeout) |
| [Cobertura](https://plugins.jenkins.io/cobertura/)                                | [Artefacts de rapport de couverture](../yaml/artifacts_reports.md#artifactsreportscoverage_report) et [Couverture du code](../testing/code_coverage/_index.md) |
| [Code coverage API](https://plugins.jenkins.io/code-coverage-api/)                | [Couverture du code](../testing/code_coverage/_index.md) et [Visualisation de la couverture](../testing/code_coverage/_index.md#coverage-visualization) |
| [Embeddable Build Status](https://plugins.jenkins.io/embeddable-build-status/)    | [Badges de statut de pipeline](../../user/project/badges.md#pipeline-status-badges) |
| [JUnit](https://plugins.jenkins.io/junit/)                                        | [Artefacts de rapport de test JUnit](../yaml/artifacts_reports.md#artifactsreportsjunit) et [Rapports de tests unitaires](../testing/unit_test_reports.md) |
| [Mailer](https://plugins.jenkins.io/mailer/)                                      | [E-mails de notification](../../user/profile/notifications.md) |
| [Parameterized Trigger Plugin](https://plugins.jenkins.io/parameterized-trigger/) | [mot-clé `trigger`](../yaml/_index.md#trigger) et [pipelines downstream](../pipelines/downstream_pipelines.md) |
| [Role-based Authorization Strategy](https://plugins.jenkins.io/role-strategy/)    | GitLab [permissions et rôles](../../user/permissions.md) |
| [Timestamper](https://plugins.jenkins.io/timestamper/)                            | Les job logs de [Job](../jobs/_index.md) sont horodatés par défaut |

### Fonctionnalités d'analyse de sécurité {#security-scanning-features}

Vous avez peut-être utilisé des plugins pour des choses comme la qualité du code, la sécurité ou l'analyse statique des applications dans Jenkins. GitLab fournit des [scanners de sécurité](../../user/application_security/_index.md) nativement pour détecter les vulnérabilités dans toutes les parties du SDLC. Vous pouvez ajouter ces plugins dans GitLab à l'aide de modèles. Par exemple, pour ajouter l'analyse SAST à votre pipeline, ajoutez ce qui suit à votre `.gitlab-ci.yml` :

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml
```

Vous pouvez personnaliser le comportement des scanners de sécurité en utilisant des variables CI/CD, par exemple avec les [scanners SAST](../../user/application_security/sast/_index.md#available-cicd-variables).

### Gestion des secrets {#secrets-management}

Les informations privilégiées, souvent appelées « secrets », sont des informations sensibles ou des identifiants dont vous avez besoin dans votre workflow CI/CD. Vous pouvez utiliser des secrets pour déverrouiller des ressources protégées ou des informations sensibles dans des outils, des applications, des conteneurs et des environnements cloud natifs.

La gestion des secrets dans Jenkins est généralement gérée avec le champ de type `Secret` ou le plugin Credentials. Les identifiants stockés dans les paramètres Jenkins peuvent être exposés aux jobs en tant que variables d'environnement à l'aide du plugin Credentials Binding.

Pour la gestion des secrets dans GitLab, vous pouvez utiliser l'une des [intégrations prises en charge](../secrets/_index.md) pour un service externe. Ces services stockent les secrets de manière sécurisée en dehors de votre projet GitLab, mais vous devez disposer d'un abonnement au service.

GitLab prend également en charge l'[authentification OIDC](../secrets/id_token_authentication.md) pour d'autres services tiers qui prennent en charge OIDC.

De plus, vous pouvez mettre des identifiants à la disposition des jobs en les stockant dans des variables CI/CD, bien que les secrets stockés en texte brut soient susceptibles d'être exposés accidentellement, [comme dans Jenkins](https://www.jenkins.io/doc/developer/security/secrets/#storing-secrets). Vous devez toujours stocker les informations sensibles dans des variables [masquées](../variables/_index.md#mask-a-cicd-variable) et [protégées](../variables/_index.md#protect-a-cicd-variable), ce qui atténue une partie du risque.

De plus, ne stockez jamais de secrets en tant que variables dans votre fichier `.gitlab-ci.yml`, qui est public pour tous les utilisateurs ayant accès au projet. Le stockage d'informations sensibles dans des variables ne doit être effectué que dans [les paramètres du projet, du groupe ou de l'instance](../variables/_index.md#define-a-cicd-variable-in-the-ui).

Consultez les [consignes de sécurité](../variables/_index.md#cicd-variable-security) pour améliorer la sécurité de vos variables CI/CD.

## Planification et réalisation d'une migration {#planning-and-performing-a-migration}

La liste suivante d'étapes recommandées a été créée après observation d'organisations ayant réussi à réaliser rapidement cette migration.

### Créer un plan de migration {#create-a-migration-plan}

Avant de démarrer une migration, vous devez créer un [plan de migration](plan_a_migration.md) pour préparer la migration. Pour une migration depuis Jenkins, posez-vous les questions suivantes en préparation :

- Quels plugins sont utilisés par les jobs dans Jenkins aujourd'hui ?
  - Savez-vous exactement ce que font ces plugins ?
  - Certains plugins encapsulent-ils un outil de build courant ? Par exemple, Maven, Gradle ou NPM ?
- Qu'est-ce qui est installé sur les agents Jenkins ?
- Y a-t-il des bibliothèques partagées en cours d'utilisation ?
- Comment vous authentifiez-vous depuis Jenkins ? Utilisez-vous des clés SSH, des tokens API ou d'autres secrets ?
- Y a-t-il d'autres projets auxquels vous devez accéder depuis votre pipeline ?
- Y a-t-il des identifiants dans Jenkins pour accéder à des services externes ? Par exemple Ansible Tower, Artifactory ou d'autres fournisseurs Cloud ou cibles de déploiement ?

### Prérequis {#prerequisites}

Avant de commencer tout travail de migration, vous devez d'abord :

1. Vous familiariser avec GitLab.
   - Lire les informations sur les [principales fonctionnalités de GitLab CI/CD](../_index.md).
   - Suivre des tutoriels pour créer [votre premier pipeline GitLab](../quick_start/_index.md) et des [pipelines plus complexes](../quick_start/tutorial.md) qui construisent, testent et déploient un site statique.
   - Consulter la [référence de syntaxe YAML CI/CD](../yaml/_index.md).
1. Installer et configurer GitLab.
1. Tester votre instance GitLab.
   - S'assurer que des [runners](../runners/_index.md) sont disponibles, soit en utilisant les runners GitLab.com partagés, soit en installant de nouveaux runners.

### Étapes de migration {#migration-steps}

1. Migrer les projets de votre solution SCM vers GitLab.
   - (Recommandé) Vous pouvez utiliser les [importateurs](../../user/import/_index.md) disponibles pour automatiser les importations en masse depuis des fournisseurs SCM externes.
   - Vous pouvez [importer des dépôts par URL](../../user/import/third_party_systems/repo_by_url.md).
1. Créer un fichier `.gitlab-ci.yml` dans chaque projet.
1. Migrer la configuration Jenkins vers des jobs GitLab CI/CD et les configurer pour afficher les résultats directement dans les merge requests.
1. Migrer les jobs de déploiement en utilisant les [modèles de déploiement cloud](../cloud_deployment/_index.md), les [environnements](../environments/_index.md) et l'[agent GitLab pour Kubernetes](../../user/clusters/agent/_index.md).
1. Vérifier si des configurations CI/CD peuvent être réutilisées dans différents projets, puis créer et partager des modèles CI/CD.
1. Consulter la [documentation sur l'efficacité des pipelines](../pipelines/pipeline_efficiency.md) pour apprendre à rendre vos pipelines GitLab CI/CD plus rapides et plus efficaces.

### Ressources supplémentaires {#additional-resources}

- Vous pouvez utiliser le [JenkinsFile Wrapper](https://gitlab.com/gitlab-org/jfr-container-builder/) pour exécuter une instance Jenkins complète dans un job GitLab CI/CD, y compris les plugins. Utilisez cet outil pour faciliter la transition vers GitLab CI/CD, en retardant la migration des pipelines moins urgents.

  > [!note]
  > Le JenkinsFile Wrapper n'est pas inclus dans GitLab et ne relève pas du périmètre du support. Pour plus d'informations, consultez la [déclaration de support](https://about.gitlab.com/support/statement-of-support/).

Si vous avez des questions auxquelles cette page ne répond pas, le [forum de la communauté GitLab](https://forum.gitlab.com/) peut être une excellente ressource.
