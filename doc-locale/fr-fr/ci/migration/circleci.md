---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migrer depuis CircleCI
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Si vous utilisez actuellement CircleCI, vous pouvez migrer vos pipelines CI/CD vers [GitLab CI/CD](../_index.md) et commencer à exploiter toutes ses fonctionnalités puissantes.

Nous avons rassemblé plusieurs ressources qui vous seront peut-être utiles avant de commencer la migration.

Le [Guide de démarrage rapide](../quick_start/_index.md) est une bonne vue d'ensemble du fonctionnement de GitLab CI/CD. Vous pourriez également être intéressé par [Auto DevOps](../../topics/autodevops/_index.md), qui peut être utilisé pour compiler, tester et déployer vos applications avec peu ou pas de configuration nécessaire.

Pour les équipes CI/CD avancées, les [modèles de projets personnalisés](../../administration/custom_project_templates.md) permettent de réutiliser les configurations de pipeline.

Si vous avez des questions auxquelles vous ne trouvez pas de réponse ici, le [forum de la communauté GitLab](https://forum.gitlab.com/) peut être une excellente ressource.

## `config.yml` vs `.gitlab-ci.yml` {#configyml-vs-gitlab-ciyml}

Le fichier de configuration `config.yml` de CircleCI définit des scripts, des jobs et des workflows (appelés « étapes » dans GitLab). Dans GitLab, une approche similaire est utilisée avec un fichier `.gitlab-ci.yml` dans le répertoire racine de votre dépôt.

### Jobs {#jobs}

Dans CircleCI, les jobs sont un ensemble d'étapes permettant d'effectuer une tâche spécifique. Dans GitLab, les [jobs](../jobs/_index.md) constituent également un élément fondamental du fichier de configuration. Le mot-clé `checkout` n'est pas nécessaire dans GitLab CI/CD, car le dépôt est automatiquement récupéré.

Exemple de définition de job CircleCI :

```yaml
jobs:
  job1:
    steps:
      - checkout
      - run: "execute-script-for-job1"
```

Exemple de la même définition de job dans GitLab CI/CD :

```yaml
job1:
  script: "execute-script-for-job1"
```

### Définition d'image Docker {#docker-image-definition}

CircleCI définit les images au niveau du job, ce qui est également pris en charge par GitLab CI/CD. De plus, GitLab CI/CD permet de définir ce paramètre globalement pour tous les jobs qui n'ont pas `image` défini.

Exemple de définition d'image CircleCI :

```yaml
jobs:
  job1:
    docker:
      - image: ruby:2.6
```

Exemple de la même définition d'image dans GitLab CI/CD :

```yaml
job1:
  image: ruby:2.6
```

### Workflows {#workflows}

CircleCI détermine l'ordre d'exécution des jobs avec `workflows`. Cela est également utilisé pour déterminer les exécutions simultanées, séquentielles, planifiées ou manuelles. La fonction équivalente dans GitLab CI/CD s'appelle [stages](../yaml/_index.md#stages). Les jobs d'une même étape s'exécutent en parallèle et ne s'exécutent qu'après la fin des étapes précédentes. Par défaut, l'exécution de l'étape suivante est ignorée lorsqu'un job échoue, mais il est possible de permettre la poursuite de l'exécution même [après l'échec d'un job](../yaml/_index.md#allow_failure).

Consultez [la vue d'ensemble de l'architecture des pipelines](../pipelines/pipeline_architectures.md) pour obtenir des conseils sur les différents types de pipelines que vous pouvez utiliser. Les pipelines peuvent être adaptés à vos besoins, par exemple pour un projet complexe de grande envergure ou un monorepo avec des composants indépendants définis.

#### Exécution des jobs en parallèle et en séquence {#parallel-and-sequential-job-execution}

Les exemples suivants montrent comment les jobs peuvent s'exécuter en parallèle ou de manière séquentielle :

1. `job1` et `job2` s'exécutent en parallèle (dans l'étape `build` pour GitLab CI/CD).
1. `job3` s'exécute uniquement après la fin de `job1` et `job2` avec succès (dans l'étape `test`).
1. `job4` s'exécute uniquement après la fin de `job3` avec succès (dans l'étape `deploy`).

Exemple CircleCI avec `workflows` :

```yaml
version: 2
jobs:
  job1:
    steps:
      - checkout
      - run: make build dependencies
  job2:
    steps:
      - run: make build artifacts
  job3:
    steps:
      - run: make test
  job4:
    steps:
      - run: make deploy

workflows:
  version: 2
  jobs:
    - job1
    - job2
    - job3:
        requires:
          - job1
          - job2
    - job4:
        requires:
          - job3
```

Exemple du même workflow sous forme de `stages` dans GitLab CI/CD :

```yaml
stages:
  - build
  - test
  - deploy

job1:
  stage: build
  script: make build dependencies

job2:
  stage: build
  script: make build artifacts

job3:
  stage: test
  script: make test

job4:
  stage: deploy
  script: make deploy
  environment: production
```

#### Exécution planifiée {#scheduled-run}

GitLab CI/CD dispose d'une interface utilisateur simple pour [planifier les pipelines](../pipelines/schedules.md). De plus, les [rules](../yaml/_index.md#rules) peuvent être utilisées pour déterminer si les jobs doivent être inclus ou exclus d'un pipeline planifié.

Exemple CircleCI d'un workflow planifié :

```yaml
commit-workflow:
  jobs:
    - build
scheduled-workflow:
  triggers:
    - schedule:
        cron: "0 1 * * *"
        filters:
          branches:
            only: try-schedule-workflow
  jobs:
    - build
```

Exemple du même pipeline planifié utilisant [`rules`](../yaml/_index.md#rules) dans GitLab CI/CD :

```yaml
job1:
  script:
    - make build
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule" && $CI_COMMIT_REF_NAME == "try-schedule-workflow"
```

Une fois la configuration du pipeline enregistrée, vous configurez la planification cron dans l'[interface GitLab](../pipelines/schedules.md#create-a-pipeline-schedule) et pouvez également activer ou désactiver les planifications depuis l'interface.

#### Exécution manuelle {#manual-run}

Exemple CircleCI d'un workflow manuel :

```yaml
release-branch-workflow:
  jobs:
    - build
    - testing:
        requires:
          - build
    - deploy:
        type: approval
        requires:
          - testing
```

Exemple du même workflow utilisant [`when: manual`](../jobs/job_control.md#create-a-job-that-must-be-run-manually) dans GitLab CI/CD :

```yaml
deploy_prod:
  stage: deploy
  script:
    - echo "Deploy to production server"
  when: manual
  environment: production
```

### Filtrer les jobs par branche {#filter-job-by-branch}

[Les rules](../yaml/_index.md#rules) sont un mécanisme permettant de déterminer si le job s'exécute pour une branche spécifique.

Exemple CircleCI d'un job filtré par branche :

```yaml
jobs:
  deploy:
    branches:
      only:
        - main
        - /rc-.*/
```

Exemple du même workflow utilisant `rules` dans GitLab CI/CD :

```yaml
deploy:
  stage: deploy
  script:
    - echo "Deploy job"
  rules:
    - if: $CI_COMMIT_BRANCH == "main" || $CI_COMMIT_BRANCH =~ /^rc-/
  environment: production
```

### Mise en cache {#caching}

GitLab fournit un mécanisme de mise en cache pour accélérer les temps de compilation de vos jobs en réutilisant des dépendances précédemment téléchargées. Il est important de connaître la différence entre [le cache et les artefacts](../caching/_index.md#how-cache-is-different-from-artifacts) pour tirer le meilleur parti de ces fonctionnalités.

Exemple CircleCI d'un job utilisant un cache :

```yaml
jobs:
  job1:
    steps:
      - restore_cache:
          key: source-v1-< .Revision >
      - checkout
      - run: npm install
      - save_cache:
          key: source-v1-< .Revision >
          paths:
            - "node_modules"
```

Exemple du même pipeline utilisant `cache` dans GitLab CI/CD :

```yaml
test_async:
  image: node:latest
  cache:  # Cache modules in between jobs
    key: $CI_COMMIT_REF_SLUG
    paths:
      - .npm/
  before_script:
    - npm ci --cache .npm --prefer-offline
  script:
    - node ./specs/start.js ./specs/async.spec.js
```

## Contextes et variables {#contexts-and-variables}

CircleCI fournit des [Contextes](https://circleci.com/docs/contexts/) pour transmettre de manière sécurisée des variables d'environnement à travers les pipelines de projets. Dans GitLab, un [Groupe](../../user/group/_index.md) peut être créé pour rassembler des projets connexes. Au niveau du groupe, des [variables CI/CD](../variables/_index.md#for-a-group) peuvent être stockées en dehors des projets individuels et transmises de manière sécurisée dans les pipelines de plusieurs projets.

## Orbs {#orbs}

Deux tickets GitLab sont ouverts concernant les Orbs de CircleCI et la façon dont GitLab peut offrir des fonctionnalités similaires.

- [ticket #1151](https://gitlab.com/gitlab-com/Product/-/issues/1151)
- [ticket #195173](https://gitlab.com/gitlab-org/gitlab/-/issues/195173)

## Environnements de compilation {#build-environments}

CircleCI propose `executors` comme technologie sous-jacente pour exécuter un job spécifique. Dans GitLab, cela est réalisé par des [runners](https://docs.gitlab.com/runner/).

Les environnements suivants sont pris en charge :

Runners autogérés :

- Linux
- Windows
- macOS

Runners d'instance GitLab.com :

- Linux
- [Windows](../runners/hosted_runners/windows.md) ([version bêta](../../policy/development_stages_support.md#beta)).
- [macOS](../runners/hosted_runners/macos.md) ([version bêta](../../policy/development_stages_support.md#beta)).

### Environnements de compilation spécifiques aux machines {#machine-and-specific-build-environments}

[Les tags](../yaml/_index.md#tags) peuvent être utilisés pour exécuter des jobs sur différentes plateformes, en indiquant à GitLab quels runners doivent exécuter les jobs.

Exemple CircleCI d'un job s'exécutant dans un environnement spécifique :

```yaml
jobs:
  ubuntuJob:
    machine:
      image: ubuntu-1604:201903-01
    steps:
      - checkout
      - run: echo "Hello, $USER!"
  osxJob:
    macos:
      xcode: 11.3.0
    steps:
      - checkout
      - run: echo "Hello, $USER!"
```

Exemple du même job utilisant `tags` dans GitLab CI/CD :

```yaml
windows job:
  stage: build
  tags:
    - windows
  script:
    - echo Hello, %USERNAME%!

osx job:
  stage: build
  tags:
    - osx
  script:
    - echo "Hello, $USER!"
```
