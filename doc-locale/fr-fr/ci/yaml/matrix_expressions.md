---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Expressions de matrice dans GitLab CI/CD
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/423553) dans GitLab 18.6.

{{< /history >}}

Les expressions de matrice permettent des dépendances de job dynamiques basées sur les identifiants [`parallel:matrix`](_index.md#parallelmatrix), afin de créer des mappages 1:1 entre les jobs `parallel:matrix`.

Les expressions de matrice présentent certaines limitations par rapport aux [expressions d'entrées](expressions.md#inputs-context) :

- Compilation uniquement : Les identifiants sont résolus lors de la création du pipeline, et non pendant l'exécution du job.
- Remplacement de chaîne uniquement : Aucune logique complexe ni transformation.
- Identifiants de matrice uniquement : Impossible de référencer des variables CI/CD ou des entrées.

## Syntaxe {#syntax}

Les expressions de matrice utilisent la syntaxe `$[[ matrix.IDENTIFIER ]]` pour référencer un identifiant `parallel:matrix` dans les dépendances de job. Par exemple :

```yaml
needs:
  - job: build
    parallel:
      matrix:
        - OS: ['$[[ matrix.OS ]]']
          ARCH: ['$[[ matrix.ARCH ]]']
```

### Expressions de matrice dans `needs:parallel:matrix` {#matrix-expressions-in-needsparallelmatrix}

Vous pouvez utiliser des expressions de matrice pour référencer dynamiquement des identifiants de matrice dans les dépendances de job, ce qui permet des mappages 1:1 entre les jobs de matrice sans spécifier manuellement toutes les combinaisons.

Par exemple :

```yaml
linux:build:
  stage: build
  script: echo "Building linux..."
  parallel:
    matrix:
      - PROVIDER: [aws, gcp]
        STACK: [monitoring, app1, app2]

linux:test:
  stage: test
  script: echo "Testing linux..."
  parallel:
    matrix:
      - PROVIDER: [aws, gcp]
        STACK: [monitoring, app1, app2]
  needs:
    - job: linux:build
      parallel:
        matrix:
          - PROVIDER: ['$[[ matrix.PROVIDER ]]']
            STACK: ['$[[ matrix.STACK ]]']
```

Cet exemple crée un mappage de dépendances 1:1 entre tous les jobs `linux:build` et `linux:test` :

- `linux:test: [aws, monitoring]` dépend de `linux:build: [aws, monitoring]`
- `linux:test: [aws, app1]` dépend de `linux:build: [aws, app1]`
- La même logique s'applique aux 6 combinaisons de valeurs `parallel:matrix`.

Avec les expressions `matrix.`, vous n'avez pas besoin de spécifier manuellement chaque combinaison de matrice.

Les expressions de matrice référencent uniquement les identifiants de la configuration de matrice du job actuel.

### Utiliser des ancres YAML pour réutiliser la configuration `parallel:matrix` {#use-yaml-anchors-to-reuse-parallelmatrix-configuration}

Vous pouvez utiliser des [ancres YAML](yaml_optimization.md#anchors) pour réutiliser la configuration `parallel:matrix` sur plusieurs jobs avec des configurations `parallel:matrix` et des dépendances complexes.

Par exemple :

```yaml
stages:
  - compile
  - test
  - deploy

.build_matrix: &build_matrix
  parallel:
    matrix:
      - OS: ["ubuntu", "alpine"]
        ARCH: ["amd64", "arm64"]
        VARIANT: ["slim", "full"]

compile_binary:
  stage: compile
  script:
    - echo "Compiling for $OS-$ARCH-$VARIANT"
  <<: *build_matrix

integration_test:
  stage: test
  script:
    - echo "Testing $OS-$ARCH-$VARIANT"
  <<: *build_matrix
  needs:
    - job: compile_binary
      parallel:
        matrix:
          - OS: ['$[[ matrix.OS ]]']
            ARCH: ['$[[ matrix.ARCH ]]']
            VARIANT: ['$[[ matrix.VARIANT ]]']

deploy_artifact:
  stage: deploy
  script:
    - echo "Deploying $OS-$ARCH-$VARIANT"
  <<: *build_matrix
  needs:
    - job: integration_test
      parallel:
        matrix:
          - OS: ['$[[ matrix.OS ]]']
            ARCH: ['$[[ matrix.ARCH ]]']
            VARIANT: ['$[[ matrix.VARIANT ]]']
```

Cette configuration crée 24 jobs : 8 jobs par étape (2 `OS` × 2 `ARCH` × 2 `VARIANT` combinaisons), avec des dépendances 1:1 entre les étapes.

### Utiliser un sous-ensemble de valeurs {#use-a-subset-of-values}

Vous pouvez combiner des expressions de matrice avec des valeurs spécifiques pour créer un sous-ensemble sélectif de dépendances :

```yaml
stages:
  - prepare
  - build
  - test

.full_matrix: &full_matrix
  parallel:
    matrix:
      - PLATFORM: ["linux", "windows", "macos"]
        VERSION: ["16", "18", "20"]

.platform_only: &platform_only
  parallel:
    matrix:
      - PLATFORM: ["linux", "windows", "macos"]

prepare_env:
  stage: prepare
  script:
    - echo "Preparing $PLATFORM with Node.js $VERSION"
  <<: *full_matrix

build_project:
  stage: build
  script:
    - echo "Building on $PLATFORM"
  needs:
    - job: prepare_env
      parallel:
        matrix:
          - PLATFORM: ['$[[ matrix.PLATFORM ]]']
            VERSION: ["18"]  # Only depend on Node.js 18 preparations
  <<: *platform_only
```

Dans cet exemple :

- `prepare_env` utilise `parallel:matrix` pour créer 9 jobs : 3 `PLATFORM` × 3 `VERSIONS`.
- `build_project` utilise `parallel:matrix` pour créer 3 jobs : 3 valeurs `PLATFORM` uniquement.
- Chaque job `build_project` dépend uniquement de Node.js `18` (`VERSION`) pour toutes les plateformes (`PLATFORM`).

Vous pouvez également [configurer toutes les dépendances manuellement](../jobs/job_control.md#specify-a-parallelized-job-using-needs-with-multiple-parallelized-jobs).

## Sujets connexes {#related-topics}

- [Jobs parallèles avec matrice](../jobs/job_control.md#parallelize-large-jobs)
- [Dépendances de job avec `needs`](needs.md)
- [Vue d'ensemble des expressions CI](expressions.md)
- [Optimisation YAML](yaml_optimization.md)
