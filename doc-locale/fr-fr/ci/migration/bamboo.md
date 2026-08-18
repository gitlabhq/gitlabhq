---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migrer depuis Bamboo
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez migrer d'Atlassian Bamboo vers GitLab CI/CD en convertissant les configurations YAML Bamboo Specs exportées depuis l'interface Bamboo ou stockées dans des dépôts Spec.

## Considérations clés pour la migration {#key-migration-considerations}

| Aspect de configuration  | Bamboo                             | GitLab CI/CD                         | Tâches de migration |
| --------------------- | ---------------------------------- | ------------------------------------ | --------------- |
| Fichiers de configuration   | Bamboo Specs (Java ou YAML)        | Fichier `.gitlab-ci.yml`                | Convertir les Specs en syntaxe YAML GitLab |
| Syntaxe des variables       | `${bamboo.variableName}`           | `$VARIABLE_NAME`                     | Mettre à jour toutes les références de variables dans les scripts |
| Environnement d'exécution | Agents (locaux ou distants)           | Runners avec exécuteurs               | Installer et configurer les runners |
| Partage d'artefacts      | Artefacts nommés avec abonnements | Héritage automatique entre les étapes | Simplifier la configuration des artefacts |
| Déploiements           | Projets de déploiement séparés       | Jobs de déploiement avec des environnements    | Combiner la compilation et le déploiement dans un seul pipeline |

## Exemples de configuration {#configuration-examples}

### Export Bamboo Specs {#bamboo-specs-export}

Les exemples suivants montrent un export YAML Bamboo Specs depuis l'interface et son équivalent GitLab CI/CD.

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bamboo organise les compilations selon une hiérarchie imbriquée où les projets contiennent plusieurs plans, les plans définissent des étapes et des jobs, et les jobs exécutent des tâches individuelles. Les projets servent de conteneurs pour les ressources partagées telles que les variables, les identifiants et les connexions aux dépôts auxquels plusieurs plans peuvent accéder.

Les exports Bamboo Specs depuis l'interface incluent cette hiérarchie complète ainsi que des métadonnées administratives telles que les permissions, les notifications et les paramètres du projet.

Lors de l'examen de votre export, concentrez-vous sur ces éléments critiques pour la migration :

- Jobs et tâches : Les commandes de compilation et les scripts réels
- Définitions des étapes : Ordre d'exécution séquentiel et dépendances
- Variables et artefacts : Données et fichiers partagés entre les jobs
- Déclencheurs et conditions : Règles qui déterminent quand les compilations s'exécutent

```yaml
version: 2
plan:
  project-key: AB
  key: TP
  name: test plan
stages:
  - Default Stage:
      manual: false
      final: false
      jobs:
        - Default Job
Default Job:
  key: JOB1
  tasks:
  - checkout:
      force-clean-build: false
      description: Checkout Default Repository
  - script:
      interpreter: SHELL
      scripts:
        - |-
          ruby -v  # Print out ruby version for debugging
          bundle config set --local deployment true  # Install dependencies into ./vendor/ruby
          bundle install -j $(nproc)
          rubocop
          rspec spec
      description: run bundler
  artifact-subscriptions: []
repositories:
  - Demo Project:
      scope: global
triggers:
  - polling:
      period: '180'
branches:
  create: manually
  delete: never
  link-to-jira: true
notifications: []
labels: []
dependencies:
  require-all-stages-passing: false
  enabled-for-branches: true
  block-strategy: none
  plans: []
other:
  concurrent-build-plugin: system-default

---

version: 2
plan:
  key: AB-TP
plan-permissions:
  - users:
    - root
    permissions:
    - view
    - edit
    - build
    - clone
    - admin
    - view-configuration
  - roles:
    - logged-in
    - anonymous
    permissions:
    - view
...
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

GitLab CI/CD élimine la complexité des imbrications. À la place, chaque dépôt contient un seul fichier `.gitlab-ci.yml` qui définit toutes les étapes et les jobs.

```yaml
default:
  image: ruby:latest

stages:
  - default-stage

job1:
  stage: default-stage
  script:
    - ruby -v  # Print out ruby version for debugging
    - bundle config set --local deployment true  # Install dependencies into ./vendor/ruby
    - bundle install -j $(nproc)
    - rubocop
    - rspec spec
```

{{< /tab >}}

{{< /tabs >}}

### Jobs et tâches {#jobs-and-tasks}

Dans GitLab et Bamboo, les jobs d'une même étape s'exécutent en parallèle, sauf lorsqu'une dépendance doit être satisfaite avant qu'un job ne s'exécute.

Le nombre de jobs pouvant s'exécuter dans Bamboo dépend de la disponibilité des agents Bamboo et de la taille de la licence Bamboo.

Avec GitLab CI/CD, le nombre de jobs parallèles dépend du nombre de runners intégrés à l'instance GitLab et de la simultanéité définie dans les runners.

{{< tabs >}}

{{< tab title="Bamboo" >}}

Dans Bamboo, les jobs sont composés de tâches, qui peuvent être un ensemble de commandes exécutées sous forme de script ou des tâches prédéfinies comme l'extraction du code source, le téléchargement d'artefacts et d'autres tâches disponibles dans le marketplace de tâches Atlassian.

```yaml
version: 2
#...

Default Job:
  key: JOB1
  tasks:
  - checkout:
      force-clean-build: false
      description: Checkout Default Repository
  - script:
      interpreter: SHELL
      scripts:
        - |-
          ruby -v
          bundle config set --local deployment true
          bundle install -j $(nproc)
      description: run bundler
other:
  concurrent-build-plugin: system-default
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

L'équivalent des tâches dans GitLab est `script`, qui spécifie les commandes à exécuter par le runner. Vous pouvez utiliser des templates CI/CD et des composants CI/CD pour composer vos pipelines sans avoir à tout écrire vous-même.

```yaml
job1:
  script: "bundle exec rspec"

job2:
  script:
    - ruby -v
    - bundle config set --local deployment true
    - bundle install -j $(nproc)
```

{{< /tab >}}

{{< /tabs >}}

### Images de conteneur {#container-images}

Les exemples suivants montrent comment le mot-clé `docker` de Bamboo se traduit par le mot-clé `image` de GitLab.

{{< tabs >}}

{{< tab title="Bamboo" >}}

Les compilations et les déploiements s'exécutent par défaut sur le système d'exploitation natif de l'agent Bamboo, mais peuvent être configurés pour s'exécuter dans des conteneurs à l'aide du mot-clé `docker`.

```yaml
version: 2
plan:
  project-key: SAMPLE
  name: Build Ruby App
  key: BUILD-APP

docker: alpine:latest

stages:
  - Build App:
      jobs:
        - Build Application

Build Application:
  tasks:
    - script:
        - # Run builds
  docker:
    image: alpine:edge
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

Dans GitLab CI/CD, vous n'avez besoin que du mot-clé `image`.

```yaml
default:
  image: alpine:latest

stages:
  - build

build-application:
  stage: build
  script:
    - # Run builds
  image:
    name: alpine:edge
```

{{< /tab >}}

{{< /tabs >}}

### Variables {#variables}

Les exemples suivants montrent les différences de syntaxe pour définir et accéder aux variables.

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bamboo dispose de différents types de variables avec différents modes d'accès. Les variables système utilisent `${system.variableName}` et les autres variables utilisent `${bamboo.variableName}`.

Dans les tâches de script, les points sont convertis en underscores. Par exemple, `${bamboo.variableName}` devient `$bamboo_variableName`.

```yaml
variables:
  username: admin
  releaseType: milestone

Default job:
  tasks:
    - script: echo '$bamboo_username is the DRI for $bamboo_releaseType'
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

Dans GitLab CI/CD, les variables sont accessibles comme des variables CI/CD Shell classiques à l'aide de `$VARIABLE_NAME`. Comme les variables système et globales dans Bamboo, GitLab dispose de variables CI/CD prédéfinies disponibles pour chaque job.

```yaml
variables:
  DEFAULT_VAR: "A default variable"

job1:
  variables:
    JOB_VAR: "A job variable"
  script:
    - echo "Variables are '$DEFAULT_VAR' and '$JOB_VAR'"
```

{{< /tab >}}

{{< /tabs >}}

### Conditions et déclencheurs {#conditions-and-triggers}

Ces exemples montrent comment les conditions et les déclencheurs Bamboo se convertissent en règles GitLab.

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bamboo propose diverses options pour déclencher des compilations, qui peuvent être basées sur des modifications de code, une planification, les résultats d'autres plans ou à la demande. Un plan peut être configuré pour interroger périodiquement un projet afin de détecter de nouvelles modifications.

```yaml
tasks:
  - script:
      scripts:
        - echo "Hello"
      conditions:
        - variable:
            equals:
              planRepository.branch: development

triggers:
  - polling:
      period: '180'
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

Les pipelines CI/CD GitLab sont déclenchés par des modifications de code, des planifications ou des appels API. Les pipelines n'utilisent pas d'interrogation.

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_COMMIT_REF_NAME == "development"

workflow:
  rules:
    - changes:
        - .gitlab/**/**.md
      when: never
```

{{< /tab >}}

{{< /tabs >}}

### Artefacts {#artifacts}

Vous pouvez définir des artefacts de job à l'aide du mot-clé `artifacts` dans GitLab et dans Bamboo.

{{< tabs >}}

{{< tab title="Bamboo" >}}

Dans Bamboo, les artefacts sont définis avec un nom, un emplacement et un modèle. Vous pouvez partager les artefacts avec d'autres jobs et plans, ou définir des jobs qui s'abonnent à l'artefact.

`artifact-subscriptions` est utilisé pour accéder aux artefacts d'un autre job dans le même plan, et `artifact-download` est utilisé pour accéder aux artefacts de jobs dans un plan différent.

```yaml
version: 2
# ...
Build:
  # ...
  artifacts:
    - name: Test Reports
      location: target/reports
      pattern: '*.xml'
      required: false
      shared: false
    - name: Special Reports
      location: target/reports
      pattern: 'special/*.xml'
      shared: true

Test app:
  artifact-subscriptions:
    - artifact: Test Reports
      destination: deploy

# ...
Build:
  # ...
  tasks:
    - artifact-download:
        source-plan: PROJECTKEY-PLANKEY
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

Dans GitLab, tous les artefacts des jobs terminés dans les étapes précédentes sont téléchargés par défaut.

```yaml
stages:
  - build

pdf:
  stage: build
  script: #generate XML reports
  artifacts:
    name: "test-report-files"
    untracked: true
    paths:
      - target/reports
```

Dans cet exemple :

- Le nom de l'artefact est spécifié explicitement, mais vous pouvez le rendre dynamique en utilisant une variable CI/CD.
- Le mot-clé `untracked` configure l'artefact pour inclure également les fichiers non suivis par Git, ainsi que ceux spécifiés explicitement avec `paths`.

{{< /tab >}}

{{< /tabs >}}

### Mise en cache {#caching}

Dans Bamboo, les caches Git peuvent être utilisés pour accélérer les compilations. Les caches Git sont configurés dans les paramètres d'administration de Bamboo et sont stockés sur le serveur Bamboo ou sur des agents distants.

GitLab prend en charge les caches Git et le cache de job. Les caches sont définis pour chaque job à l'aide du mot-clé `cache` :

```yaml
test-job:
  stage: build
  cache:
    - key:
        files:
          - Gemfile.lock
      paths:
        - vendor/ruby
    - key:
        files:
          - yarn.lock
      paths:
        - .yarn-cache/
  script:
    - bundle config set --local path 'vendor/ruby'
    - bundle install
    - yarn install --cache-folder .yarn-cache
    - echo Run tests...
```

### Déploiements {#deployments}

Les exemples suivants montrent comment convertir les projets de déploiement Bamboo en jobs de déploiement GitLab.

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bamboo dispose de projets de déploiement, qui sont liés à des plans de compilation pour suivre, récupérer et déployer des artefacts vers des environnements de déploiement. Lors de la création d'un projet, vous le liez à un plan de compilation, spécifiez l'environnement de déploiement et les tâches pour effectuer les déploiements.

```yaml
deployment:
  name: Deploy ruby app
  source-plan: build-app

release-naming: release-1.0

environments:
  - Production

Production:
  tasks:
    - # scripts to deploy app to production
    - ./.ci/deploy_prod.sh
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

Dans GitLab CI/CD, vous pouvez créer un job de déploiement qui déploie vers un environnement ou crée une release.

```yaml
deploy-to-production:
  stage: deploy
  script:
    - # Run Deployment script
    - ./.ci/deploy_prod.sh
  environment:
    name: production
```

Pour créer une release à la place, utilisez le mot-clé `release` avec l'outil CLI `glab` pour créer des releases pour les tags Git :

```yaml
release_job:
  stage: release
  image: registry.gitlab.com/gitlab-org/cli:latest
  rules:
    - if: $CI_COMMIT_TAG                  # Run this job when a tag is created manually
  script:
    - echo "Building release version"
  release:
    tag_name: $CI_COMMIT_TAG
    name: 'Release $CI_COMMIT_TAG'
    description: 'Release created using the CLI.'
```

{{< /tab >}}

{{< /tabs >}}

## Analyse de sécurité {#security-scanning}

Bamboo s'appuie sur des tâches tierces fournies dans l'Atlassian Marketplace pour exécuter des analyses de sécurité.

GitLab fournit des scanners de sécurité pour détecter les vulnérabilités dans toutes les parties du SDLC. Vous pouvez ajouter ces scanners dans GitLab en utilisant des templates, par exemple pour ajouter l'analyse SAST à votre pipeline :

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml
```

Vous pouvez personnaliser le comportement des scanners de sécurité en utilisant des variables CI/CD.

## Gestion des secrets {#secrets-management}

La gestion des secrets dans Bamboo est assurée à l'aide d'identifiants partagés ou d'applications tierces du marketplace Atlassian.

Pour la gestion des secrets dans GitLab, vous pouvez utiliser des intégrations prises en charge pour les services externes. Ces services stockent les secrets de manière sécurisée en dehors de votre projet GitLab, bien que vous deviez disposer d'un abonnement au service.

GitLab prend également en charge l'authentification OIDC pour d'autres services tiers qui prennent en charge OIDC.

De plus, vous pouvez rendre les identifiants disponibles pour les jobs en les stockant dans des variables CI/CD, bien que les secrets stockés en texte clair soient susceptibles d'être exposés accidentellement. Vous devez toujours stocker les informations sensibles dans des variables masquées et protégées, ce qui atténue une partie du risque.

> [!note]
> Ne stockez jamais les secrets en tant que variables dans votre fichier `.gitlab-ci.yml`, qui est accessible à tous les utilisateurs ayant accès au projet. Le stockage d'informations sensibles dans des variables ne doit être effectué que dans les paramètres du projet, du groupe ou de l'instance.

## Créer un plan de migration {#create-a-migration-plan}

Avant de commencer votre migration, créez un [plan de migration](plan_a_migration.md) et répondez à ces questions :

- Quelles tâches Bamboo sont utilisées par les jobs aujourd'hui et que font-elles ?
- Des tâches encapsulent-elles des outils de compilation courants tels que Maven, Gradle ou NPM ?
- Quels logiciels sont installés sur les agents Bamboo ?
- Comment vous authentifiez-vous depuis Bamboo (clés SSH, jetons API ou autres secrets) ?
- Y a-t-il des identifiants dans Bamboo pour accéder à des services externes ?
- Des bibliothèques ou des templates partagés sont-ils utilisés ?

## Migrer depuis Bamboo vers GitLab CI/CD {#migrate-from-bamboo-to-gitlab-cicd}

Prérequis :

- Vous devez disposer d'une instance GitLab configurée et opérationnelle.
- Vous devez disposer de [runners](../runners/_index.md) disponibles.

Pour migrer depuis Bamboo :

1. Auditez votre configuration Bamboo :
   - Exportez vos projets/plans Bamboo sous forme de Spec YAML depuis l'interface Bamboo.
   - Listez toutes les tâches Bamboo utilisées dans vos jobs (par exemple, Maven, Docker, SCP).
   - Documentez les versions des logiciels installés sur chaque agent Bamboo.
   - Identifiez tous les identifiants partagés et leur utilisation.

1. Migrez vos dépôts de code source vers GitLab :
   - Utilisez les [importeurs](../../user/import/_index.md) disponibles pour automatiser les imports en masse depuis des fournisseurs SCM externes.
   - [Importer des dépôts par URL](../../user/import/third_party_systems/repo_by_url.md) pour les dépôts individuels.

1. Configurez les runners GitLab avec les logiciels équivalents :
   - Installez les mêmes versions de logiciels que celles présentes sur vos agents Bamboo.
   - Pour les configurations d'agents complexes, créez des images Docker personnalisées avec vos outils requis.
   - Vérifiez que les runners peuvent exécuter vos commandes de compilation avec succès.

1. Convertissez les Bamboo Specs en fichiers `.gitlab-ci.yml` :
   - Remplacez la structure du plan Bamboo par des étapes et des jobs GitLab.
   - Convertissez la syntaxe `${bamboo.variableName}` en `$VARIABLE_NAME`.
   - Remplacez les variables spécifiques à Bamboo telles que `${bamboo.planKey}` par leurs équivalents GitLab tels que `$CI_PIPELINE_ID`.
   - Supprimez les tâches de checkout Bamboo. GitLab extrait automatiquement votre code source au début de chaque job.

1. Migrez la gestion des artefacts :
   - Supprimez les configurations Bamboo `artifact-subscriptions` et `artifact-download`.
   - Utilisez l'héritage automatique des artefacts entre les étapes.
   - Mettez à jour les chemins des artefacts pour correspondre à la structure de vos jobs GitLab.

1. Convertissez les projets de déploiement Bamboo :
   - Déplacez les tâches de déploiement des projets de déploiement Bamboo séparés vers votre fichier `.gitlab-ci.yml` principal.
   - Remplacez les environnements Bamboo par les [environnements](../environments/_index.md) GitLab.
   - Utilisez les [templates de déploiement cloud](../cloud_deployment/_index.md) pour les schémas de déploiement courants.
   - Configurez l'[agent GitLab pour Kubernetes](../../user/clusters/agent/_index.md) si vous déployez sur Kubernetes.

1. Migrez les secrets et les identifiants :
   - Utilisez les [intégrations de secrets externes](../secrets/_index.md) ou stockez les identifiants en tant que variables CI/CD masquées et protégées.

1. Testez et optimisez vos pipelines migrés :
   - Exécutez des pipelines de test pour vérifier le bon fonctionnement.
   - Ajoutez l'intégration des merge requests pour afficher les résultats des pipelines.
   - Optimisez les performances des pipelines et créez des templates réutilisables.

## Sujets connexes {#related-topics}

- [Guide de démarrage](../_index.md)
- [Référence de syntaxe YAML CI/CD](../yaml/_index.md)
- [Variables GitLab CI/CD](../variables/_index.md)
- [Efficacité des pipelines](../pipelines/pipeline_efficiency.md)
