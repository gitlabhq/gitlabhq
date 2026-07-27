---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migrer un build Maven de Jenkins vers GitLab CI/CD
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Si vous disposez d'un build Maven dans Jenkins, vous pouvez utiliser un modèle de projet [Java Spring](https://gitlab.com/gitlab-org/project-templates/spring) pour migrer vers GitLab. Le modèle utilise Maven pour la gestion des dépendances sous-jacentes.

## Exemples de configurations Jenkins {#sample-jenkins-configurations}

Les trois exemples Jenkins suivants utilisent chacun des méthodes différentes pour tester, builder et installer un projet Maven dans un agent shell :

- Freestyle avec exécution shell
- Freestyle avec le plugin de tâche Maven
- Un pipeline déclaratif utilisant un Jenkinsfile

Les trois exemples exécutent les mêmes trois commandes dans l'ordre, en trois étapes différentes :

- `mvn test` :  Exécuter tous les tests trouvés dans la base de code
- `mvn package -DskipTests` :  Compiler le code en un type exécutable défini dans le POM et ignorer l'exécution des tests, car cela a été fait lors de la première étape.
- `mvn install -DskipTests` :  Installer l'exécutable compilé dans le dépôt Maven local `.m2` de l'agent et ignorer à nouveau l'exécution des tests.

Ces exemples utilisent un agent Jenkins unique et persistant, qui nécessite que Maven soit préinstallé sur l'agent. Cette méthode d'exécution est similaire à celle d'un GitLab Runner utilisant l'[exécuteur shell](https://docs.gitlab.com/runner/executors/shell/).

### Freestyle avec exécution shell {#freestyle-with-shell-execution}

Si vous utilisez l'option d'exécution shell intégrée à Jenkins pour appeler directement les commandes `mvn` depuis le shell sur l'agent, la configuration pourrait ressembler à ceci :

![Interface Jenkins montrant les étapes de build avec les commandes Maven définies en tant que commandes shell.](img/maven-freestyle-shell_v16_4.png)

### Freestyle avec le plugin de tâche Maven {#freestyle-with-maven-task-plugin}

Si vous utilisez le plugin Maven dans Jenkins pour déclarer et exécuter des objectifs spécifiques dans le [cycle de vie du build Maven](https://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html), la configuration pourrait ressembler à ceci :

![Interface Jenkins montrant les étapes de build avec les commandes Maven définies à l'aide du plugin Maven.](img/maven-freestyle-plugin_v16_4.png)

Ce plugin nécessite que Maven soit installé sur l'agent Jenkins et utilise un wrapper de script pour appeler les commandes Maven.

### Utiliser un pipeline déclaratif {#using-a-declarative-pipeline}

Si vous utilisez un pipeline déclaratif, la configuration pourrait ressembler à ceci :

```groovy
pipeline {
    agent any
    tools {
        maven 'maven-3.6.3'
        jdk 'jdk11'
    }
    stages {
        stage('Build') {
            steps {
                sh "mvn package -DskipTests"
            }
        }
        stage('Test') {
            steps {
                sh "mvn test"
            }
        }
        stage('Install') {
            steps {
                sh "mvn install -DskipTests"
            }
        }
    }
}
```

Cet exemple utilise des commandes d'exécution shell plutôt que des plugins.

Par défaut, une configuration de pipeline déclaratif est stockée soit dans la configuration du pipeline Jenkins, soit directement dans le dépôt Git dans un `Jenksinfile`.

## Convertir la configuration Jenkins en GitLab CI/CD {#convert-jenkins-configuration-to-gitlab-cicd}

Bien que les exemples précédents soient tous légèrement différents, ils peuvent tous être migrés vers GitLab CI/CD avec la même configuration de pipeline.

Prérequis :

- Un GitLab Runner avec un exécuteur Shell
- Maven 3.6.3 et Java 11 JDK installés sur le runner shell

Cet exemple reproduit le comportement et la syntaxe du build, des tests et de l'installation sur Jenkins.

Dans un pipeline CI/CD, les commandes s'exécutent dans des « jobs », qui sont regroupés en étapes. La configuration migrée dans le fichier de configuration `.gitlab-ci.yml` se compose de deux mots-clés globaux (`stages` et `variables`) suivis de 3 jobs :

```yaml
stages:
  - build
  - test
  - install

variables:
  MAVEN_OPTS: >-
    -Dhttps.protocols=TLSv1.2
    -Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository
  MAVEN_CLI_OPTS: >-
    -DskipTests

build-JAR:
  stage: build
  script:
    - mvn $MAVEN_CLI_OPTS package

test-code:
  stage: test
  script:
    - mvn test

install-JAR:
  stage: install
  script:
    - mvn $MAVEN_CLI_OPTS install
```

Dans cet exemple :

- `stages` définit trois étapes qui s'exécutent dans l'ordre. Comme dans les exemples Jenkins précédents, le job de test s'exécute en premier, suivi du job de build, puis du job d'installation.
- `variables` définit les variables CI/CD [CI/CD variables](../../variables/_index.md) utilisables par tous les jobs :
  - `MAVEN_OPTS` représente les variables d'environnement Maven nécessaires chaque fois que Maven est exécuté :
    - `-Dhttps.protocols=TLSv1.2` définit le protocole TLS à la version 1.2 pour toutes les requêtes HTTP dans le pipeline.
    - `-Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository` définit l'emplacement du dépôt Maven local sur le répertoire du projet GitLab sur le runner, afin que le job puisse accéder au dépôt et le modifier.
  - `MAVEN_CLI_OPTS` représente des arguments spécifiques à ajouter aux commandes `mvn` :
    - `-DskipTests` ignore l'étape `test` dans le cycle de vie du build Maven.
- `test-code`, `build-JAR` et `install-JAR` sont les noms définis par l'utilisateur pour les jobs à exécuter dans le pipeline :
  - `stage` définit l'étape dans laquelle le job s'exécute. Un pipeline contient une ou plusieurs étapes et une étape contient un ou plusieurs jobs. Cet exemple comporte trois étapes, chacune avec un seul job.
  - `script` définit les commandes à exécuter dans ce job, de manière similaire à `steps` dans un `Jenkinsfile`. Les jobs peuvent exécuter plusieurs commandes en séquence, qui s'exécutent dans le conteneur d'image, mais dans cet exemple les jobs n'exécutent qu'une seule commande chacun.

### Exécuter des jobs dans des conteneurs Docker {#run-jobs-in-docker-containers}

Plutôt que d'utiliser une machine persistante pour gérer ce processus de build comme dans les exemples Jenkins, cet exemple utilise un conteneur Docker éphémère pour gérer l'exécution. L'utilisation d'un conteneur supprime la nécessité de maintenir une machine virtuelle et la version de Maven qui y est installée. Cela augmente également la flexibilité pour développer et étendre les fonctionnalités du pipeline.

Prérequis :

- Un GitLab Runner avec l'exécuteur Docker pouvant être utilisé par le projet. Si vous utilisez GitLab.com, vous pouvez utiliser les runners d'instance publics.

Cette configuration de pipeline migrée se compose de trois mots-clés globaux (`stages`, `default` et `variables`) suivis de 3 jobs. Cette configuration utilise des fonctionnalités supplémentaires de GitLab CI/CD pour un pipeline amélioré par rapport à l'[exemple précédent](#convert-jenkins-configuration-to-gitlab-cicd) :

```yaml
stages:
  - build
  - test
  - install

default:
  image: maven:3.6.3-openjdk-11
  cache:
    key: $CI_COMMIT_REF_SLUG
    paths:
      - .m2/

variables:
  MAVEN_OPTS: >-
    -Dhttps.protocols=TLSv1.2
    -Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository
  MAVEN_CLI_OPTS: >-
    -DskipTests

build-JAR:
  stage: build
  script:
    - mvn $MAVEN_CLI_OPTS package

test-code:
  stage: test
  script:
    - mvn test

install-JAR:
  stage: install
  script:
    - mvn $MAVEN_CLI_OPTS install
```

Dans cet exemple :

- `stages` définit trois étapes qui s'exécutent dans l'ordre. Comme dans les exemples Jenkins précédents, le job de test s'exécute en premier, suivi du job de build, puis du job d'installation.
- `default` définit la configuration standard à réutiliser dans tous les jobs par défaut :
  - `image` définit le conteneur d'image Docker à utiliser et dans lequel exécuter les commandes. Dans cet exemple, il s'agit d'une image Docker Maven officielle avec tout ce qui est nécessaire déjà installé.
  - `cache` est utilisé pour mettre en cache et réutiliser les dépendances :
    - `key` est l'identifiant unique de l'archive de cache spécifique. Dans cet exemple, il s'agit d'une version abrégée de la référence du commit Git, générée automatiquement en tant que [variable CI/CD prédéfinie](../../variables/predefined_variables.md). Tout job s'exécutant pour la même référence de commit réutilise le même cache.
    - `paths` représente les répertoires ou fichiers à inclure dans le cache. Cet exemple met en cache le répertoire `.m2/` pour éviter de réinstaller les dépendances entre les exécutions de jobs.
- `variables` définit les variables CI/CD [CI/CD variables](../../variables/_index.md) utilisables par tous les jobs :
  - `MAVEN_OPTS` représente les variables d'environnement Maven nécessaires chaque fois que Maven est exécuté :
    - `-Dhttps.protocols=TLSv1.2` définit le protocole TLS à la version 1.2 pour toutes les requêtes HTTP dans le pipeline.
    - `-Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository` définit l'emplacement du dépôt Maven local sur le répertoire du projet GitLab sur le runner, afin que le job puisse accéder au dépôt et le modifier.
  - `MAVEN_CLI_OPTS` représente des arguments spécifiques à ajouter aux commandes `mvn` :
    - `-DskipTests` ignore l'étape `test` dans le cycle de vie du build Maven.
- `test-code`, `build-JAR` et `install-JAR` sont les noms définis par l'utilisateur pour les jobs à exécuter dans le pipeline :
  - `stage` définit l'étape dans laquelle le job s'exécute. Un pipeline contient une ou plusieurs étapes et une étape contient un ou plusieurs jobs. Cet exemple comporte trois étapes, chacune avec un seul job.
  - `script` définit les commandes à exécuter dans ce job, de manière similaire à `steps` dans un `Jenkinsfile`. Les jobs peuvent exécuter plusieurs commandes en séquence, qui s'exécutent dans le conteneur d'image, mais dans cet exemple les jobs n'exécutent qu'une seule commande chacun.
