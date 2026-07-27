---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Exemples d'entrées CI/CD"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les [entrées CI/CD](_index.md) augmentent la flexibilité de votre configuration CI/CD. Utilisez ces exemples comme guide pour configurer votre pipeline avec des entrées.

## Inclure le même fichier plusieurs fois {#include-the-same-file-multiple-times}

Vous pouvez inclure le même fichier plusieurs fois, avec différentes entrées. Cependant, si plusieurs jobs portant le même nom sont ajoutés à un pipeline, chaque job supplémentaire écrase le job précédent portant le même nom. Vous devez vous assurer que la configuration empêche les noms de jobs en double.

Par exemple, en incluant la même configuration plusieurs fois avec différentes entrées :

```yaml
include:
  - local: path/to/my-super-linter.yml
    inputs:
      linter: docs
      lint-path: "doc/"
  - local: path/to/my-super-linter.yml
    inputs:
      linter: yaml
      lint-path: "data/yaml/"
```

La configuration dans `path/to/my-super-linter.yml` garantit que le job a un nom unique à chaque fois qu'il est inclus :

```yaml
spec:
  inputs:
    linter:
    lint-path:
---
"run-$[[ inputs.linter ]]-lint":
  script: ./lint --$[[ inputs.linter ]] --path=$[[ inputs.lint-path ]]
```

## Réutiliser la configuration dans `inputs` {#reuse-configuration-in-inputs}

Pour réutiliser la configuration avec `inputs`, vous pouvez utiliser les [ancres YAML](../yaml/yaml_optimization.md#anchors).

Par exemple, pour réutiliser la même configuration `rules` avec plusieurs composants CI/CD qui prennent en charge les tableaux `rules` dans les entrées :

```yaml
.my-job-rules: &my-job-rules
  - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

include:
  - component: $CI_SERVER_FQDN/project/path/component1@main
    inputs:
      job-rules: *my-job-rules
  - component: $CI_SERVER_FQDN/project/path/component2@main
    inputs:
      job-rules: *my-job-rules
```

Vous ne pouvez pas utiliser les [balises `!reference`](../yaml/yaml_optimization.md#reference-tags) dans les entrées, mais le [ticket 424481](https://gitlab.com/gitlab-org/gitlab/-/issues/424481) propose l'ajout de cette fonctionnalité.

## Utiliser `inputs` avec `needs` {#use-inputs-with-needs}

Vous pouvez utiliser des entrées de type tableau avec [`needs`](../yaml/_index.md#needs) pour des dépendances de jobs complexes.

Par exemple, dans un fichier nommé `component.yml` :

```yaml
spec:
  inputs:
    first_needs:
      type: array
    second_needs:
      type: array
---

test_job:
  script: echo "this job has needs"
  needs:
    - $[[ inputs.first_needs ]]
    - $[[ inputs.second_needs ]]
```

Dans cet exemple, les entrées sont `first_needs` et `second_needs`, toutes deux des [entrées de type tableau](_index.md#array-type). Ensuite, dans un fichier `.gitlab-ci.yml`, vous pouvez ajouter cette configuration et définir les valeurs des entrées :

```yaml
include:
  - local: 'component.yml'
    inputs:
      first_needs:
        - build1
      second_needs:
        - build2
```

Lorsque le pipeline démarre, les éléments du tableau `needs` pour `test_job` sont concaténés en :

```yaml
test_job:
  script: echo "this job has needs"
  needs:
  - build1
  - build2
```

### Autoriser l'extension de `needs` lors de l'inclusion {#allow-needs-to-be-expanded-when-included}

Vous pouvez avoir [`needs`](../yaml/_index.md#needs) dans un job inclus, mais aussi ajouter des jobs supplémentaires au tableau `needs` avec `spec:inputs`.

Par exemple :

```yaml
spec:
  inputs:
    test_job_needs:
      type: array
      default: []
---

build-job:
  script:
    - echo "My build job"

test-job:
  script:
    - echo "My test job"
  needs:
    - build-job
    - $[[ inputs.test_job_needs ]]
```

Dans cet exemple :

- Le job `test-job` a toujours besoin de `build-job`.
- Par défaut, le job de test n'a besoin d'aucun autre job, car le tableau d'entrées `test_job_needs:` est vide par défaut.

Pour que `test-job` nécessite un autre job dans votre configuration, ajoutez-le à l'entrée `test_needs` lorsque vous incluez le fichier. Par exemple :

```yaml
include:
  - component: $CI_SERVER_FQDN/project/path/component@1.0.0
    inputs:
      test_job_needs: [my-other-job]

my-other-job:
  script:
    - echo "I want build-job` in the component to need this job too"
```

### Ajouter `needs` à un job inclus qui n'a pas de `needs` {#add-needs-to-an-included-job-that-doesnt-have-needs}

Vous pouvez ajouter [`needs`](../yaml/_index.md#needs) à un job inclus qui n'a pas encore `needs` de défini. Par exemple, dans la configuration d'un composant CI/CD :

```yaml
spec:
  inputs:
    test_job:
      default: test-job
---

build-job:
  script:
    - echo "My build job"

"$[[ inputs.test_job ]]":
  script:
    - echo "My test job"
```

Dans cet exemple, la section `spec:inputs` permet de personnaliser le nom du job.

Ensuite, après avoir inclus le composant CI/CD, vous pouvez étendre le job avec la configuration `needs` supplémentaire. Par exemple :

```yaml
include:
  - component: $CI_SERVER_FQDN/project/path/component@1.0.0
    inputs:
      test_job: my-test-job

my-test-job:
  needs: [my-other-job]

my-other-job:
  script:
    - echo "I want `my-test-job` to need this job"
```

## Utiliser `inputs` avec `include` pour des pipelines plus dynamiques {#use-inputs-with-include-for-more-dynamic-pipelines}

Vous pouvez utiliser `inputs` avec `include` pour sélectionner les fichiers de configuration de pipeline supplémentaires à inclure.

Par exemple :

```yaml
spec:
  inputs:
    pipeline-type:
      type: string
      default: development
      options: ['development', 'canary', 'production']
      description: "The pipeline type, which determines which set of jobs to include."
---

include:
  - local: .gitlab/ci/$[[ inputs.pipeline-type ]].gitlab-ci.yml
```

Dans cet exemple, le fichier `.gitlab/ci/development.gitlab-ci.yml` est inclus par défaut. Mais si une option d'entrée `pipeline-type` différente est utilisée, un fichier de configuration différent est inclus.

### Utiliser les entrées CI/CD dans les expressions de variables {#use-cicd-inputs-in-variable-expressions}

Vous pouvez utiliser les [entrées CI/CD](_index.md) pour personnaliser les expressions de variables. Par exemple :

```yaml
example-job:
  script: echo "Testing"
  rules:
    - if: '"$[[ inputs.some_example ]]" == "test-branch"'
```

L'expression est évaluée en deux étapes :

1. Interpolation des entrées : Avant la création du pipeline, les entrées sont remplacées par la valeur d'entrée. Dans cet exemple, l'entrée `$[[ inputs.some_example ]]` est remplacée par la [valeur définie](_index.md#set-input-values). Par exemple, si la valeur est :

   - `test-branch`, l'expression devient `if: '"test-branch" == "test-branch"'`.
   - `$CI_COMMIT_BRANCH`, l'expression devient `if: '"$CI_COMMIT_BRANCH" == "test-branch"'`.

1. Évaluation de l'expression : Une fois les entrées interpolées, GitLab tente de créer le pipeline. Lors de la création du pipeline, les expressions sont évaluées pour déterminer quels jobs ajouter au pipeline.
