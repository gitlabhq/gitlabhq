---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migrer depuis TeamCity
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Si vous migrez de TeamCity vers GitLab CI/CD, vous pouvez créer des pipelines CI/CD qui répliquent et améliorent vos workflows TeamCity.

## Similarités et différences clés {#key-similarities-and-differences}

GitLab CI/CD et TeamCity sont des outils CI/CD présentant certaines similarités. GitLab et TeamCity :

- Sont suffisamment flexibles pour exécuter des jobs pour la plupart des langages.
- Peuvent être déployés sur site ou dans le cloud.

Par ailleurs, il existe quelques différences importantes entre les deux :

- Les pipelines CI/CD GitLab sont configurés dans un fichier de configuration au format YAML, que vous pouvez modifier manuellement ou avec l'[éditeur de pipeline](../pipeline_editor/_index.md). Les pipelines TeamCity peuvent être configurés depuis l'interface utilisateur ou à l'aide de Kotlin DSL.
- GitLab est une plateforme DevSecOps avec SCM intégré, registre de conteneurs, analyse de sécurité et bien plus encore. TeamCity nécessite des solutions distinctes pour ces fonctionnalités, généralement fournies par des intégrations.

### Fichier de configuration {#configuration-file}

TeamCity peut être [configuré depuis l'interface utilisateur](https://www.jetbrains.com/help/teamcity/creating-and-editing-build-configurations.html) ou dans le [`Teamcity Configuration` fichier au format Kotlin DSL](https://www.jetbrains.com/help/teamcity/kotlin-dsl.html). Une configuration de build TeamCity est un ensemble d'instructions qui définit comment un projet logiciel doit être compilé, testé et déployé. La configuration inclut les paramètres et les réglages nécessaires à l'automatisation du processus CI/CD dans TeamCity.

Dans GitLab, l'équivalent d'une configuration de build TeamCity est le fichier `.gitlab-ci.yml`. Ce fichier définit le pipeline CI/CD d'un projet, en spécifiant les étapes, les jobs et les commandes nécessaires pour compiler, tester et déployer le projet.

## Comparaison des fonctionnalités et des concepts {#comparison-of-features-and-concepts}

De nombreuses fonctionnalités et de nombreux concepts de TeamCity ont des équivalents dans GitLab offrant les mêmes fonctionnalités.

### Jobs {#jobs}

TeamCity utilise des configurations de build, qui se composent de plusieurs étapes de build dans lesquelles vous définissez des commandes ou des scripts pour exécuter des tâches telles que la compilation du code, l'exécution de tests et la mise en package d'artefacts.

Voici un exemple de configuration de projet TeamCity au format Kotlin DSL qui compile un fichier Docker et exécute des tests unitaires :

```kotlin
package _Self.buildTypes

import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.perfmon
import jetbrains.buildServer.configs.kotlin.buildSteps.dockerCommand
import jetbrains.buildServer.configs.kotlin.buildSteps.nodeJS
import jetbrains.buildServer.configs.kotlin.triggers.vcs

object BuildTest : BuildType({
    name = "Build & Test"

    vcs {
        root(HttpsGitlabComRutshahCicdDemoGitRefsHeadsMain)
    }

    steps {
        dockerCommand {
            id = "DockerCommand"
            commandType = build {
                source = file {
                    path = "Dockerfile"
                }
            }
        }
        nodeJS {
            id = "nodejs_runner"
            workingDir = "app"
            shellScript = """
                npm install jest-teamcity --no-save
                npm run test -- --reporters=jest-teamcity
            """.trimIndent()
        }
    }

    triggers {
        vcs {
        }
    }

    features {
        perfmon {
        }
    }
})
```

Dans GitLab CI/CD, vous définissez des jobs avec les tâches à exécuter dans le cadre du pipeline. Chaque job peut comporter une ou plusieurs étapes de build.

Le fichier `.gitlab-ci.yml` GitLab CI/CD équivalent pour l'exemple précédent serait :

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_BRANCH != "main" || $CI_PIPELINE_SOURCE != "merge_request_event"
      when: never
    - when: always

stages:
  - build
  - test

build-job:
  image: docker:20.10.16
  stage: build
  services:
    - docker:20.10.16-dind
  script:
    - docker build -t cicd-demo:0.1 .

run_unit_tests:
  image: node:17-alpine3.14
  stage: test
  before_script:
    - cd app
    - npm install
  script:
    - npm test
  artifacts:
    when: always
    reports:
      junit: app/junit.xml
```

### Déclencheurs de pipeline {#pipeline-triggers}

Les [déclencheurs TeamCity](https://www.jetbrains.com/help/teamcity/configuring-build-triggers.html) définissent les conditions qui initient un build, notamment les modifications VCS, les déclencheurs planifiés ou les builds déclenchés par d'autres builds.

Dans GitLab CI/CD, les pipelines peuvent être déclenchés automatiquement pour divers événements, comme des modifications apportées aux branches ou aux merge requests et les nouveaux tags. Les pipelines peuvent également être déclenchés manuellement, à l'aide d'une [API](../triggers/_index.md), ou avec des [pipelines planifiés](../pipelines/schedules.md). Pour plus d'informations, consultez [Pipelines CI/CD](../pipelines/_index.md).

### Variables {#variables}

Dans TeamCity, vous [définissez les paramètres de build et les variables d'environnement](https://www.jetbrains.com/help/teamcity/using-build-parameters.html) dans les paramètres de configuration de build.

Dans GitLab, utilisez le mot-clé `variables` pour définir des [variables CI/CD](../variables/_index.md). Utilisez des variables pour réutiliser des données de configuration, disposer d'une configuration plus dynamique ou stocker des valeurs importantes. Les variables peuvent être définies de manière globale ou par job.

Par exemple, un fichier `.gitlab-ci.yml` GitLab CI/CD utilisant des variables :

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

### Artefacts {#artifacts}

Les configurations de build dans TeamCity vous permettent de définir des [artefacts](https://www.jetbrains.com/help/teamcity/build-artifact.html) générés pendant le processus de build.

Dans GitLab, tout job peut utiliser le mot-clé [`artifacts`](../yaml/_index.md#artifacts) pour définir un ensemble d'artefacts à stocker lorsqu'un job se termine. Les [artefacts](../jobs/job_artifacts.md) sont des fichiers qui peuvent être utilisés dans des jobs ultérieurs, à des fins de test ou de déploiement.

Par exemple, un fichier `.gitlab-ci.yml` GitLab CI/CD utilisant des artefacts :

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

### Runners {#runners}

L'équivalent des [agents TeamCity](https://www.jetbrains.com/help/teamcity/build-agent.html) dans GitLab sont les runners.

Dans GitLab CI/CD, les runners sont les services qui exécutent les jobs. Si vous utilisez GitLab.com, vous pouvez utiliser la [flotte de runners d'instance](../runners/_index.md) pour exécuter des jobs sans provisionner vos propres runners autogérés.

Quelques informations importantes sur les runners :

- Les runners peuvent être [configurés](../runners/runners_scope.md) pour être partagés sur une instance, un groupe, ou dédiés à un seul projet.
- Vous pouvez utiliser le [mot-clé `tags`](../runners/configure_runners.md#control-jobs-that-a-runner-can-run) pour un contrôle plus précis et associer des runners à des jobs spécifiques. Par exemple, vous pouvez utiliser un tag pour les jobs nécessitant du matériel dédié, plus puissant ou spécifique.
- GitLab dispose de la [mise à l'échelle automatique pour les runners](https://docs.gitlab.com/runner/runner_autoscale/). Utilisez la mise à l'échelle automatique pour provisionner des runners uniquement lorsque nécessaire et les réduire lorsqu'ils ne le sont pas.

### Fonctionnalités de build et plugins TeamCity {#teamcity-build-features--plugins}

Certaines fonctionnalités de TeamCity activées via les fonctionnalités de build et les plugins sont prises en charge nativement dans GitLab CI/CD avec des mots-clés et des fonctionnalités CI/CD.

| Plugin TeamCity                                                                                                                    | Fonctionnalité GitLab |
|------------------------------------------------------------------------------------------------------------------------------------|----------------|
| [Couverture du code](https://www.jetbrains.com/help/teamcity/configuring-test-reports-and-code-coverage.html#Code+Coverage+in+TeamCity) | [Couverture du code](../testing/code_coverage/_index.md) et [Visualisation de la couverture des tests](../testing/code_coverage/_index.md#coverage-visualization) |
| [Rapport de tests unitaires](https://www.jetbrains.com/help/teamcity/configuring-test-reports-and-code-coverage.html)                        | [Artefacts de rapport de test JUnit](../yaml/artifacts_reports.md#artifactsreportsjunit) et [Rapports de tests unitaires](../testing/unit_test_reports.md) |
| [Notifications](https://www.jetbrains.com/help/teamcity/configuring-notifications.html)                                            | [E-mails de notification](../../user/profile/notifications.md) et [Slack](../../user/project/integrations/gitlab_slack_application.md) |

## Planification et réalisation d'une migration {#planning-and-performing-a-migration}

La liste de recommandations suivante a été élaborée après observation d'organisations ayant réussi à effectuer rapidement une migration vers GitLab CI/CD.

### Créer un plan de migration {#create-a-migration-plan}

Avant de commencer une migration, vous devez créer un [plan de migration](plan_a_migration.md) afin de vous préparer à la migration.

Pour une migration depuis TeamCity, posez-vous les questions suivantes en préparation :

- Quels plugins sont utilisés par les jobs dans TeamCity aujourd'hui ?
  - Savez-vous exactement ce que font ces plugins ?
- Qu'est-ce qui est installé sur les agents TeamCity ?
- Y a-t-il des bibliothèques partagées utilisées ?
- Comment vous authentifiez-vous depuis TeamCity ? Utilisez-vous des clés SSH, des jetons API ou d'autres secrets ?
- Y a-t-il d'autres projets auxquels vous devez accéder depuis votre pipeline ?
- Existe-t-il des identifiants dans TeamCity pour accéder à des services externes ? Par exemple Ansible Tower, Artifactory, ou d'autres fournisseurs cloud ou cibles de déploiement ?

### Prérequis {#prerequisites}

Avant d'effectuer tout travail de migration, vous devez d'abord :

1. Vous familiariser avec GitLab.
   - Consultez la documentation sur les [fonctionnalités clés de GitLab CI/CD](../_index.md).
   - Suivez des tutoriels pour créer [votre premier pipeline GitLab](../quick_start/_index.md) et des [pipelines plus complexes](../quick_start/tutorial.md) qui compilent, testent et déploient un site statique.
   - Consultez la [référence de syntaxe YAML CI/CD](../yaml/_index.md).
1. Installer et configurer GitLab.
1. Tester votre instance GitLab.
   - Vérifiez que des [runners](../runners/_index.md) sont disponibles, soit en utilisant des runners GitLab.com partagés, soit en installant de nouveaux runners.

### Étapes de migration {#migration-steps}

1. Migrer les projets depuis votre solution SCM vers GitLab.
   - (Recommandé) Vous pouvez utiliser les [importateurs](../../user/import/_index.md) disponibles pour automatiser les imports en masse depuis des fournisseurs SCM externes.
   - Vous pouvez [importer des dépôts par URL](../../user/import/third_party_systems/repo_by_url.md).
1. Créer un fichier `.gitlab-ci.yml` dans chaque projet.
1. Migrer la configuration TeamCity vers des jobs GitLab CI/CD et les configurer pour afficher les résultats directement dans les merge requests.
1. Migrer les jobs de déploiement à l'aide des [modèles de déploiement cloud](../cloud_deployment/_index.md), des [environnements](../environments/_index.md) et de l'[agent GitLab pour Kubernetes](../../user/clusters/agent/_index.md).
1. Vérifiez si des configurations CI/CD peuvent être réutilisées dans différents projets, puis créez et partagez des [composants CI/CD](../components/_index.md).
1. Consultez [l'efficacité des pipelines](../pipelines/pipeline_efficiency.md) pour savoir comment rendre vos pipelines CI/CD GitLab plus rapides et plus efficaces.

Si vous avez des questions sans réponse ici, le [forum de la communauté GitLab](https://forum.gitlab.com/) peut être une excellente ressource.
