---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Contrôler l'exécution des jobs"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Avant le démarrage d'un nouveau pipeline, GitLab vérifie la configuration du pipeline pour déterminer quels jobs peuvent s'exécuter dans ce pipeline. Vous pouvez configurer des jobs pour qu'ils s'exécutent en fonction de conditions telles que la valeur de variables ou le type de pipeline avec [`rules`](job_rules.md). Lorsque vous utilisez des règles de job, découvrez comment [éviter les pipelines en double](job_rules.md#avoid-duplicate-pipelines). Pour contrôler la création de pipeline, utilisez [`workflow:rules`](../yaml/workflow.md).

## Créer un job devant être exécuté manuellement {#create-a-job-that-must-be-run-manually}

Vous pouvez exiger qu'un job ne s'exécute pas sans qu'un utilisateur le démarre. On appelle cela un **manual job**. Vous pourriez vouloir utiliser un job manuel pour des opérations telles que le déploiement en production.

Pour spécifier un job comme manuel, ajoutez [`when: manual`](../yaml/_index.md#when) au job dans le fichier `.gitlab-ci.yml`.

Par défaut, les jobs manuels s'affichent comme ignorés au démarrage du pipeline.

Vous pouvez utiliser des [branches protégées](../../user/project/repository/branches/protected.md) pour [protéger plus strictement les déploiements manuels](#protect-manual-jobs) contre toute exécution par des utilisateurs non autorisés.

Les jobs manuels qui sont [archivés](../../administration/settings/continuous_integration.md#archive-pipelines) ne s'exécutent pas.

### Types de jobs manuels {#types-of-manual-jobs}

Les jobs manuels peuvent être soit facultatifs, soit bloquants.

Dans les jobs manuels facultatifs :

- [`allow_failure`](../yaml/_index.md#allow_failure) est `true`, ce qui est le paramètre par défaut pour les jobs dont `when: manual` est défini en dehors de `rules`.
- Le statut ne contribue pas au statut global du pipeline. Un pipeline peut réussir même si tous ses jobs manuels échouent.

Dans les jobs manuels bloquants :

- `allow_failure` est `false`, ce qui est le paramètre par défaut pour les jobs dont `when: manual` est défini dans [`rules`](../yaml/_index.md#rules).
- Le pipeline s'arrête à l'étape où le job est défini. Pour permettre au pipeline de continuer à s'exécuter, [exécutez le job manuel](#run-a-manual-job).
- Les merge requests dans les projets dont l'option [**Les pipelines doivent réussir**](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge) est activée ne peuvent pas être fusionnées avec un pipeline bloqué.
- Le pipeline affiche un statut **blocked**.

Lors de l'utilisation de jobs manuels dans des pipelines downstream avec un [`trigger:strategy`](../yaml/_index.md#triggerstrategy), le type de job manuel peut affecter le statut du job déclencheur pendant l'exécution du pipeline.

### Exécuter un job manuel {#run-a-manual-job}

Pour exécuter un job manuel, vous devez avoir l'autorisation de fusionner dans la branche assignée :

1. Accédez à la vue du pipeline, du job, de l'[environnement](../environments/deployments.md#configure-manual-deployments) ou du déploiement.
1. En regard du job manuel, sélectionnez **Exécution** ({{< icon name="play" >}}).

### Spécifier des variables lors de l'exécution de jobs manuels {#specify-variables-when-running-manual-jobs}

Lors de l'exécution de jobs manuels, vous pouvez fournir des variables CI/CD supplémentaires spécifiques au job. Spécifiez des variables ici lorsque vous souhaitez modifier l'exécution d'un job qui utilise des [variables CI/CD](../variables/_index.md).

Pour les paramètres typés et validés pouvant être remplacés lors de l'exécution et de la réexécution de jobs manuels, utilisez plutôt les [entrées de job](job_inputs.md).

Pour exécuter un job manuel et spécifier des variables supplémentaires :

- Sélectionnez le **nom** du job manuel dans la vue du pipeline, et non **Exécution** ({{< icon name="play" >}}).
- Dans le formulaire, ajoutez des paires de clés et de valeurs de variables.
- Sélectionnez **Exécuter le job**.

> [!warning]
> Tout membre du projet autorisé à exécuter un job manuel peut relancer le job et consulter les variables qui ont été fournies lors de son exécution initiale. Cela inclut :
>
> - Dans les projets publics : Les utilisateurs disposant du rôle Developer, Maintainer ou Owner.
> - Dans les projets privés ou internes : Les utilisateurs disposant du rôle Invité, Planificateur, Reporter, Developer, Maintainer ou Owner.
>
> Tenez compte de cette visibilité lors de la saisie d'informations sensibles en tant que variables de job manuel.

Si vous ajoutez une variable déjà définie dans les paramètres CI/CD ou dans le fichier `.gitlab-ci.yml`, la [variable est remplacée](../variables/_index.md#use-pipeline-variables) par la nouvelle valeur. Toutes les variables remplacées par ce processus sont [développées](../variables/_index.md#allow-cicd-variable-expansion) et non [masquées](../variables/_index.md#mask-a-cicd-variable).

#### Réessayer un job manuel avec des variables mises à jour {#retry-a-manual-job-with-updated-variables}

Lorsque vous réessayez un job manuel qui a été précédemment exécuté avec des variables spécifiées manuellement, vous pouvez mettre à jour les variables ou utiliser les mêmes variables.

Pour réessayer des jobs manuels avec des paramètres typés et validés, utilisez plutôt les [entrées de job](job_inputs.md).

Pour réessayer un job manuel avec des variables précédemment spécifiées :

- Avec les mêmes variables :
  - Depuis la page de détails du job, sélectionnez **Réessayer** ({{< icon name="retry" >}}).
- Avec des variables mises à jour :
  - Depuis la page de détails du job, sélectionnez **Essayer à nouveau ce job avec d'autres valeurs** dans la liste déroulante.
  - Les variables spécifiées lors de l'exécution précédente sont préremplies dans le formulaire. Vous pouvez ajouter, modifier ou supprimer des variables CI/CD dans ce formulaire.
  - Sélectionnez **Exécuter de nouveau le job**.

### Demander une confirmation pour les jobs manuels {#require-confirmation-for-manual-jobs}

Utilisez [`manual_confirmation`](../yaml/_index.md#manual_confirmation) avec `when: manual` pour demander une confirmation pour les jobs manuels. Cela permet d'éviter les déploiements ou suppressions accidentels pour les jobs sensibles tels que ceux qui déploient en production.

Lorsque vous exécutez le job, vous devez confirmer l'action avant son exécution.

### Protéger les jobs manuels {#protect-manual-jobs}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez des [environnements protégés](../environments/protected_environments.md) pour définir une liste d'utilisateurs autorisés à exécuter un job manuel. Vous pouvez autoriser uniquement les utilisateurs associés à un environnement protégé à exécuter des jobs manuels, ce qui peut :

- Limiter plus précisément qui peut déployer dans un environnement.
- Bloquer un pipeline jusqu'à ce qu'un utilisateur approuvé l'« approuve ».

Pour protéger un job manuel :

1. Ajoutez un `environment` au job. Par exemple :

   ```yaml
   deploy_prod:
     stage: deploy
     script:
       - echo "Deploy to production server"
     environment:
       name: production
       url: https://example.com
     when: manual
     rules:
       - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
   ```

1. Dans les [paramètres des environnements protégés](../environments/protected_environments.md#protecting-environments), sélectionnez l'environnement (`production` dans cet exemple) et ajoutez les utilisateurs, rôles ou groupes autorisés à exécuter le job manuel dans la liste **Allowed to Deploy**. Seules les personnes figurant dans cette liste peuvent exécuter ce job manuel, ainsi que les administrateurs GitLab qui peuvent toujours utiliser les environnements protégés.

Vous pouvez utiliser des environnements protégés avec des jobs manuels bloquants pour disposer d'une liste d'utilisateurs autorisés à approuver les étapes ultérieures du pipeline. Ajoutez `allow_failure: false` au job manuel protégé et les étapes suivantes du pipeline ne s'exécutent qu'une fois que le job manuel est déclenché par des utilisateurs autorisés.

## Exécuter un job après un délai {#run-a-job-after-a-delay}

Utilisez [`when: delayed`](../yaml/_index.md#when) pour exécuter des scripts après une période d'attente, ou si vous souhaitez éviter que les jobs entrent immédiatement dans l'état `pending`.

Vous pouvez définir la durée avec le mot-clé `start_in`. La valeur de `start_in` est un temps écoulé en secondes, sauf si une unité est fournie. Le minimum est d'une seconde et le maximum est d'une semaine. Voici des exemples de valeurs valides :

- `'5'` (une valeur sans unité doit être entourée de guillemets simples)
- `5 seconds`
- `30 minutes`
- `1 day`
- `1 week`

Lorsqu'une étape inclut un job différé, le pipeline ne progresse pas tant que le job différé n'est pas terminé. Vous pouvez utiliser ce mot-clé pour insérer des délais entre différentes étapes.

Le minuteur d'un job différé démarre immédiatement après la fin de l'étape précédente. Comme pour les autres types de jobs, le minuteur d'un job différé ne démarre pas si l'étape précédente n'est pas réussie.

L'exemple suivant crée un job nommé `timed rollout 10%` qui est exécuté 30 minutes après la fin de l'étape précédente :

```yaml
timed rollout 10%:
  stage: deploy
  script: echo 'Rolling out 10% ...'
  when: delayed
  start_in: 30 minutes
  environment: production
```

Pour arrêter le minuteur actif d'un job différé, sélectionnez **Déprogrammer** ({{< icon name="time-out" >}}). Ce job ne peut plus être planifié pour s'exécuter automatiquement. Vous pouvez cependant exécuter le job manuellement.

Pour démarrer un job différé manuellement, sélectionnez **Déprogrammer** ({{< icon name="time-out" >}}) pour arrêter le minuteur de délai, puis sélectionnez **Exécution** ({{< icon name="play" >}}). GitLab Runner démarre bientôt le job.

Les jobs différés qui sont [archivés](../../administration/settings/continuous_integration.md#archive-pipelines) ne s'exécutent pas.

## Paralléliser les jobs volumineux {#parallelize-large-jobs}

Pour diviser un job volumineux en plusieurs jobs plus petits s'exécutant en parallèle, utilisez le mot-clé [`parallel`](../yaml/_index.md#parallel) dans votre fichier `.gitlab-ci.yml`.

Différents langages et suites de tests disposent de différentes méthodes pour activer la parallélisation. Par exemple, utilisez [Semaphore Test Boosters](https://github.com/renderedtext/test-boosters) et RSpec pour exécuter des tests Ruby en parallèle :

```ruby
# Gemfile
source 'https://rubygems.org'

gem 'rspec'
gem 'semaphore_test_boosters'
```

```yaml
test:
  parallel: 3
  script:
    - bundle
    - bundle exec rspec_booster --job $CI_NODE_INDEX/$CI_NODE_TOTAL
```

Vous pouvez ensuite accéder à l'onglet **Jobs** d'une nouvelle build de pipeline et voir votre job RSpec divisé en trois jobs distincts.

> [!warning]
> Test Boosters transmet des statistiques d'utilisation à l'auteur.

### Exécuter une matrice unidimensionnelle de jobs parallèles {#run-a-one-dimensional-matrix-of-parallel-jobs}

Pour exécuter un job plusieurs fois en parallèle dans un même pipeline, mais avec des valeurs différentes pour chaque instance du job, utilisez le mot-clé [`parallel:matrix`](../yaml/_index.md#parallelmatrix) :

```yaml
deploystacks:
  stage: deploy
  script:
    - bin/deploy
  parallel:
    matrix:
      - PROVIDER: [aws, ovh, gcp, vultr]
  environment: production/$PROVIDER
```

Dans cet exemple, 4 jobs `deploystacks` sont créés, et `PROVIDER` devient une variable CI/CD avec une valeur différente dans chacun :

- `deploystacks: [aws]`
- `deploystacks: [ovh]`
- `deploystacks: [gcp]`
- `deploystacks: [vultr]`

### Exécuter une matrice de jobs trigger parallèles {#run-a-matrix-of-parallel-trigger-jobs}

Vous pouvez exécuter un job [trigger](../yaml/_index.md#trigger) plusieurs fois en parallèle dans un même pipeline, mais avec des variables différentes disponibles pour chaque instance du job.

Par exemple :

```yaml
deploystacks:
  stage: deploy
  trigger:
    include: path/to/child-pipeline.yml
  parallel:
    matrix:
      - PROVIDER: aws
        STACK: [monitoring, app1]
      - PROVIDER: ovh
        STACK: [monitoring, backup]
      - PROVIDER: [gcp, vultr]
        STACK: [data]
```

Cet exemple génère 6 jobs trigger `deploystacks` parallèles, chacun avec des valeurs différentes pour `PROVIDER` et `STACK`, et ils créent 6 pipelines enfants différents avec ces variables.

```plaintext
deploystacks: [aws, monitoring]
deploystacks: [aws, app1]
deploystacks: [ovh, monitoring]
deploystacks: [ovh, backup]
deploystacks: [gcp, data]
deploystacks: [vultr, data]
```

### Sélectionner différents tags de runner pour chaque job de matrice parallèle {#select-different-runner-tags-for-each-parallel-matrix-job}

Vous pouvez utiliser les valeurs définies dans `parallel: matrix` avec le mot-clé [`tags`](../yaml/_index.md#tags) pour la sélection dynamique de runner :

```yaml
deploystacks:
  stage: deploy
  script:
    - bin/deploy
  parallel:
    matrix:
      - PROVIDER: aws
        STACK: [monitoring, app1]
      - PROVIDER: gcp
        STACK: [data]
  tags:
    - ${PROVIDER}-${STACK}
  environment: $PROVIDER/$STACK
```

### Utiliser des variables de matrice dans les règles {#use-matrix-variables-in-rules}

GitLab évalue les règles séparément pour chaque job de matrice individuel, en utilisant les valeurs de variables de ce job.

#### Utiliser des variables de matrice dans `rules:if` {#use-matrix-variables-in-rulesif}

Utilisez des variables de matrice dans les expressions [`rules:if`](../yaml/_index.md#rulesif) pour inclure ou exclure des jobs de matrice individuels en fonction de leurs valeurs de variables.

Par exemple, pour ignorer des jobs lorsque la variable de matrice `SKIP` est définie sur `"true"` :

```yaml
test:
  script: echo "Building $ARCH"
  parallel:
    matrix:
      - ARCH: [amd64, arm64]
        SKIP: ["false", "true"]
  rules:
    - if: $SKIP == "true"
      when: never
    - when: on_success
```

Seuls les jobs dont `SKIP` est `"false"` sont inclus dans le pipeline.

> [!note]
> Les variables de matrice dans `rules:if` ne prennent pas en charge l'expansion imbriquée. Si la valeur d'une variable de matrice fait référence à une autre variable CI/CD (par exemple, `FILE: $GLOBAL_FILE`), la référence n'est pas résolue. L'expression utilise la valeur de chaîne littérale, donc `$FILE` est évalué comme `"$GLOBAL_FILE"` plutôt que comme la valeur de `GLOBAL_FILE`.

#### Utiliser des variables de matrice dans `rules:changes` {#use-matrix-variables-in-ruleschanges}

Utilisez des variables de matrice dans les chemins [`rules:changes`](../yaml/_index.md#ruleschanges) pour inclure un job de matrice uniquement lorsque des fichiers pertinents pour ce job ont été modifiés. Ce modèle est utile dans les monodépôts où chaque valeur de matrice correspond à un composant ou un service disposant de son propre répertoire.

Par exemple, pour exécuter un job de test uniquement pour le composant dont les fichiers ont été modifiés :

```yaml
test:
  script: echo "Testing $COMPONENT"
  parallel:
    matrix:
      - COMPONENT: [frontend, backend, database]
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"
      changes:
        - components/$COMPONENT/**/*
```

Dans cet exemple :

- Trois jobs `test` sont évalués, un pour chaque valeur de `COMPONENT`.
- Chaque job vérifie `rules:changes` avec sa propre valeur de `$COMPONENT` substituée dans le chemin.
- Seuls les jobs pour lesquels des fichiers correspondants ont été modifiés sont ajoutés au pipeline.

Par exemple, si seul `components/frontend/npm.lock` a été modifié, seul le job `frontend` s'exécute.

Vous pouvez utiliser plusieurs variables de matrice dans le même chemin :

```yaml
test:
  script: echo "Testing $SERVICE in $ENV"
  parallel:
    matrix:
      - SERVICE: [api, web]
        ENV: [dev, prod]
  rules:
    - changes:
        - config/$SERVICE/$ENV/**/*
```

#### Utiliser des variables de matrice dans `rules:exists` {#use-matrix-variables-in-rulesexists}

Utilisez des variables de matrice dans les chemins [`rules:exists`](../yaml/_index.md#rulesexists) pour inclure un job de matrice uniquement lorsqu'un fichier spécifique existe.

Par exemple :

```yaml
test:
  script: echo "Testing $TYPE"
  parallel:
    matrix:
      - TYPE: [go, ruby, python]
  rules:
    - exists:
        - "**/*.$TYPE"
```

### Récupérer des artefacts depuis un job `parallel:matrix` {#fetch-artifacts-from-a-parallelmatrix-job}

Vous pouvez récupérer des artefacts depuis un job créé avec [`parallel:matrix`](../yaml/_index.md#parallelmatrix) en utilisant le mot-clé [`dependencies`](../yaml/_index.md#dependencies). Utilisez le nom du job comme valeur pour `dependencies` sous forme de chaîne de caractères au format suivant :

```plaintext
<job_name> [<matrix argument 1>, <matrix argument 2>, ... <matrix argument N>]
```

Par exemple, pour récupérer les artefacts du job avec un `RUBY_VERSION` de `2.7` et un `PROVIDER` de `aws` :

```yaml
ruby:
  image: ruby:${RUBY_VERSION}
  parallel:
    matrix:
      - RUBY_VERSION: ["2.5", "2.6", "2.7", "3.0", "3.1"]
        PROVIDER: [aws, gcp]
  script: bundle install

deploy:
  image: ruby:2.7
  stage: deploy
  dependencies:
    - "ruby: [2.7, aws]"
  script: echo hello
  environment: production
```

Des guillemets autour de l'entrée `dependencies` sont requis.

### Spécifier un job parallélisé à l'aide de needs avec plusieurs jobs parallélisés {#specify-a-parallelized-job-using-needs-with-multiple-parallelized-jobs}

Utilisez [`needs:parallel:matrix`](../yaml/_index.md#needsparallelmatrix) pour créer des [dépendances de jobs](../yaml/needs.md) entre plusieurs jobs parallélisés.

Vous pouvez utiliser deux techniques de configuration :

- Automatiquement avec des [expressions `matrix.`](../yaml/matrix_expressions.md).
- Manuellement, comme illustré ci-dessous.

Par exemple :

```yaml
linux:build:
  stage: build
  script: echo "Building linux..."
  parallel:
    matrix:
      - PROVIDER: aws
        STACK:
          - monitoring
          - app1
          - app2

mac:build:
  stage: build
  script: echo "Building mac..."
  parallel:
    matrix:
      - PROVIDER: [gcp, vultr]
        STACK: [data, processing]

linux:rspec:
  stage: test
  needs:
    - job: linux:build
      parallel:
        matrix:
          - PROVIDER: aws
            STACK: app1
  script: echo "Running rspec on linux..."

mac:rspec:
  stage: test
  needs:
    - job: mac:build
      parallel:
        matrix:
          - PROVIDER: [gcp, vultr]
            STACK: [data]
  script: echo "Running rspec on mac..."

production:
  stage: deploy
  script: echo "Running production..."
  environment: production
```

Cet exemple génère plusieurs jobs. Les jobs parallèles ont chacun des valeurs différentes pour `PROVIDER` et `STACK`.

- 3 jobs `linux:build` parallèles :
  - `linux:build: [aws, monitoring]`
  - `linux:build: [aws, app1]`
  - `linux:build: [aws, app2]`
- 4 jobs `mac:build` parallèles :
  - `mac:build: [gcp, data]`
  - `mac:build: [gcp, processing]`
  - `mac:build: [vultr, data]`
  - `mac:build: [vultr, processing]`
- Un job `linux:rspec`.
- Un job `production`.

Les jobs comportent trois chemins d'exécution :

- Chemin Linux : Le job `linux:rspec` s'exécute dès que le job `linux:build: [aws, app1]` est terminé, sans attendre la fin de `mac:build`.
- Chemin macOS : Le job `mac:rspec` s'exécute dès que les jobs `mac:build: [gcp, data]` et `mac:build: [vultr, data]` sont terminés, sans attendre la fin de `linux:build`.
- Le job `production` s'exécute dès que tous les jobs précédents sont terminés.

#### Spécifier les dépendances entre les jobs parallélisés {#specify-needs-between-parallelized-jobs}

Vous pouvez affiner l'ordre de chaque job de matrice parallèle en utilisant [`needs:parallel:matrix`](../yaml/_index.md#needsparallelmatrix).

Par exemple :

```yaml
build_job:
  stage: build
  script:
    # ensure that other parallel job other than build_job [1, A] runs longer
    - '[[ "$VERSION" == "1" && "$MODE" == "A" ]] || sleep 30'
    - echo build $VERSION $MODE
  parallel:
    matrix:
      - VERSION: [1,2]
        MODE: [A, B]

deploy_job:
  stage: deploy
  script: echo deploy $VERSION $MODE
  parallel:
    matrix:
      - VERSION: [3,4]
        MODE: [C, D]

'deploy_job: [3, D]':
  stage: deploy
  script: echo something
  needs:
  - 'build_job: [1, A]'
```

Cet exemple génère plusieurs jobs. Les jobs parallèles ont chacun des valeurs différentes pour `VERSION` et `MODE`.

- 4 jobs `build_job` parallèles :
  - `build_job: [1, A]`
  - `build_job: [1, B]`
  - `build_job: [2, A]`
  - `build_job: [2, B]`
- 4 jobs `deploy_job` parallèles :
  - `deploy_job: [3, C]`
  - `deploy_job: [3, D]`
  - `deploy_job: [4, C]`
  - `deploy_job: [4, D]`

Le job `deploy_job: [3, D]` s'exécute dès que le job `build_job: [1, A]` est terminé, sans attendre la fin des autres jobs `build_job`.

## Dépannage {#troubleshooting}

### Attribution incohérente des utilisateurs lors de l'exécution de jobs manuels {#inconsistent-user-assignment-when-running-manual-jobs}

Dans certains cas particuliers, l'utilisateur qui exécute un job manuel n'est pas assigné comme utilisateur pour les jobs ultérieurs qui dépendent du job manuel.

Si vous avez besoin d'une sécurité stricte concernant l'utilisateur assigné aux jobs qui dépendent d'un job manuel, vous devriez [protéger le job manuel](#protect-manual-jobs).
