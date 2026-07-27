---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Contrôlez l'exécution des jobs à l'aide de règles, de conditions et d'expressions de variables."
title: "Spécifier quand les jobs s'exécutent avec `rules`"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez le mot-clé [`rules`](../yaml/_index.md#rules) pour inclure ou exclure des jobs dans les pipelines.

Les règles sont évaluées dans l'ordre jusqu'à la première correspondance. Lorsqu'une correspondance est trouvée, le job est inclus ou exclu du pipeline, selon la configuration.

Vous ne pouvez pas utiliser des variables dotenv créées dans des scripts de job dans les règles, car les règles sont évaluées avant l'exécution de tout job.

## Exemples `rules` {#rules-examples}

L'exemple suivant utilise `if` pour définir que le job s'exécute uniquement dans deux cas spécifiques :

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: manual
      allow_failure: true
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

- Si le pipeline est destiné à un merge request, la première règle correspond et le job est ajouté au pipeline de merge request avec les attributs suivants :
  - `when: manual` (job manuel)
  - `allow_failure: true` (le pipeline continue de s'exécuter même si le job manuel n'est pas exécuté)
- Si le pipeline n'est pas destiné à un merge request, la première règle ne correspond pas et la deuxième règle est évaluée.
- Si le pipeline est un pipeline planifié, la deuxième règle correspond et le job est ajouté au pipeline planifié. Aucun attribut n'a été défini, il est donc ajouté avec :
  - `when: on_success` (par défaut)
  - `allow_failure: false` (par défaut)
- Dans tous les autres cas, aucune règle ne correspond, donc le job n'est ajouté à aucun autre pipeline.

Vous pouvez également définir un ensemble de règles pour exclure des jobs dans certains cas, mais les exécuter dans tous les autres cas :

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: never
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: never
    - when: on_success
```

- Si le pipeline est destiné à un merge request, le job n'est pas ajouté au pipeline.
- Si le pipeline est un pipeline planifié, le job n'est pas ajouté au pipeline.
- Dans tous les autres cas, le job est ajouté au pipeline, avec `when: on_success`.

> [!warning]
> Si vous utilisez une clause `when` comme règle finale (sans inclure `when: never`), deux pipelines simultanés peuvent démarrer. Les pipelines push et les pipelines de merge request peuvent être déclenchés par le même événement (un push vers la branche source d'un merge request ouvert). Consultez comment [éviter les pipelines en double](#avoid-duplicate-pipelines) pour plus de détails.

### Exécuter des jobs pour les pipelines planifiés {#run-jobs-for-scheduled-pipelines}

Vous pouvez configurer un job pour qu'il ne soit exécuté que lorsque le pipeline a été planifié. Par exemple :

```yaml
job:on-schedule:
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
  script:
    - make world

job:
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"
  script:
    - make build
```

Dans cet exemple, `make world` s'exécute dans les pipelines planifiés, et `make build` s'exécute dans les pipelines de branche et de tag.

### Ignorer les jobs si la branche est vide {#skip-jobs-if-the-branch-is-empty}

Utilisez [`rules:changes:compare_to`](../yaml/_index.md#ruleschangescompare_to) pour ignorer un job lorsque la branche est vide, ce qui économise des ressources CI/CD. La configuration compare la branche à la branche par défaut, et si la branche :

- Ne comporte pas de fichiers modifiés, le job ne s'exécute pas.
- Comporte des fichiers modifiés, le job s'exécute.

Par exemple, dans un projet avec `main` comme branche par défaut :

```yaml
job:
  script:
    - echo "This job only runs for branches that are not empty"
  rules:
    - if: $CI_COMMIT_BRANCH
      changes:
        compare_to: 'refs/heads/main'
        paths:
          - '**/*'
```

La règle pour ce job compare récursivement tous les fichiers et chemins de la branche courante (`**/*`) par rapport à la branche `main`. La règle correspond et le job s'exécute uniquement lorsque des modifications ont été apportées aux fichiers de la branche.

Pour les jobs `parallel:matrix`, vous pouvez [utiliser des variables de matrice dans les chemins `rules:changes`](job_control.md#use-matrix-variables-in-rules) pour exécuter chaque instance de job uniquement lorsque les fichiers pertinents pour cette valeur de matrice ont été modifiés.

## Exécuter un job lorsqu'un fichier n'est pas présent {#run-a-job-when-a-file-is-not-present}

Vous pouvez utiliser `rules: exists` pour configurer un job à exécuter uniquement lorsqu'un fichier spécifique n'existe pas.

Par exemple, pour exécuter un job dans un pipeline de merge request lorsque le fichier `example.yml` n'existe pas :

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - exists:
      - "example_dir/example.yml"
      when: never
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

Dans cet exemple, si le fichier `example_dir/example.yml` existe dans la branche, le job ne s'exécute pas. Si le fichier n'existe pas, le job peut s'exécuter dans les pipelines de merge request.

Pour les jobs `parallel:matrix`, vous pouvez [utiliser des variables de matrice dans les chemins `rules:exists`](job_control.md#use-matrix-variables-in-rules) pour inclure une instance de job uniquement lorsqu'un fichier spécifique existe.

## Clauses `if` courantes avec des variables prédéfinies {#common-if-clauses-with-predefined-variables}

Les clauses `rules:if` sont couramment utilisées avec les [variables CI/CD prédéfinies](../variables/predefined_variables.md), notamment `CI_PIPELINE_SOURCE`.

L'exemple suivant exécute le job en tant que job manuel dans les pipelines planifiés ou dans les pipelines push (vers des branches ou des tags), avec `when: on_success` (par défaut). Le job n'est pas ajouté aux autres types de pipeline.

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: manual
      allow_failure: true
    - if: $CI_PIPELINE_SOURCE == "push"
```

L'exemple suivant exécute le job en tant que job `when: on_success` dans les pipelines de merge request et les pipelines planifiés. Il ne s'exécute dans aucun autre type de pipeline.

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

Autres clauses `if` couramment utilisées :

- `if: $CI_COMMIT_TAG` :  Si des modifications sont poussées pour un tag.
- `if: $CI_COMMIT_BRANCH` :  Si des modifications sont poussées vers n'importe quelle branche.
- `if: $CI_COMMIT_BRANCH == "main"` :  Si des modifications sont poussées vers `main`.
- `if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH` :  Si des modifications sont poussées vers la branche par défaut.
- `if: $CI_COMMIT_BRANCH =~ /regex-expression/` :  Si la branche du commit correspond à une expression régulière.
- `if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH && $CI_COMMIT_TITLE =~ /Merge branch.*/` :  Si la branche du commit est la branche par défaut et que le titre du message de commit correspond à une expression régulière.
- `if: $CUSTOM_VARIABLE == "value1"` :  Si la variable CI/CD personnalisée `CUSTOM_VARIABLE` est exactement `value1`.

### Exécuter des jobs uniquement dans des types de pipeline spécifiques {#run-jobs-only-in-specific-pipeline-types}

Vous pouvez utiliser des variables CI/CD prédéfinies avec `rules` pour choisir les types de pipeline pour lesquels les jobs doivent s'exécuter.

Le tableau suivant liste certaines des variables que vous pouvez utiliser, ainsi que les types de pipeline que ces variables peuvent contrôler :

- Pipelines de branche qui s'exécutent pour les événements Git `push` vers une branche, comme les nouveaux commits ou les tags.
- Pipelines de tag qui s'exécutent uniquement lorsqu'un nouveau tag Git est poussé vers une branche.
- Pipelines de merge request qui s'exécutent pour les modifications apportées à un merge request, comme les nouveaux commits ou en sélectionnant **Exécuter le pipeline** dans l'onglet des pipelines d'un merge request.
- Pipelines planifiés.

| Variables                                  | Branche | Tag | Merge request | Planifié |
|--------------------------------------------|--------|-----|---------------|-----------|
| `CI_COMMIT_BRANCH`                         | Oui    |     |               | Oui       |
| `CI_COMMIT_TAG`                            |        | Oui |               | Oui, si le pipeline planifié est configuré pour s'exécuter sur un tag. |
| `CI_PIPELINE_SOURCE = push`                | Oui    | Oui |               |           |
| `CI_PIPELINE_SOURCE = schedule`            |        |     |               | Oui       |
| `CI_PIPELINE_SOURCE = merge_request_event` |        |     | Oui           |           |
| `CI_MERGE_REQUEST_IID`                     |        |     | Oui           |           |

Par exemple, pour configurer un job à exécuter pour les pipelines de merge request et les pipelines planifiés, mais pas pour les pipelines de branche ou de tag :

```yaml
job1:
  script:
    - echo
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_PIPELINE_SOURCE == "schedule"
    - if: $CI_PIPELINE_SOURCE == "push"
      when: never
```

### Variable prédéfinie `CI_PIPELINE_SOURCE` {#ci_pipeline_source-predefined-variable}

Utilisez la variable `CI_PIPELINE_SOURCE` pour contrôler quand ajouter des jobs pour ces types de pipeline :

| Valeur                           | Description |
|---------------------------------|-------------|
| `api`                           | Pour les pipelines déclenchés par l'[API pipelines](../../api/pipelines.md#create-a-new-pipeline). |
| `chat`                          | Pour les pipelines créés à l'aide d'une commande [GitLab ChatOps](../chatops/_index.md). |
| `external`                      | Lorsque vous utilisez des services CI autres que GitLab. |
| `external_pull_request_event`   | Lorsqu'une [pull request externe sur GitHub](../ci_cd_for_external_repos/_index.md#pipelines-for-external-pull-requests) est créée ou mise à jour. |
| `merge_request_event`           | Pour les pipelines créés lorsqu'un merge request est créé ou mis à jour. Requis pour activer les [pipelines de merge request](../pipelines/merge_request_pipelines.md), les [pipelines de résultats fusionnés](../pipelines/merged_results_pipelines.md) et les [merge trains](../pipelines/merge_trains.md). |
| `ondemand_dast_scan`            | Pour les pipelines de [scan DAST à la demande](../../user/application_security/dast/on-demand_scan.md). |
| `ondemand_dast_validation`      | Pour les pipelines de [validation DAST à la demande](../../user/application_security/dast/profiles.md#site-profile-validation) |
| `parent_pipeline`               | Pour les pipelines enfants déclenchés par un [pipeline parent](../pipelines/downstream_pipelines.md#parent-child-pipelines). Utilisez cette source de pipeline dans la configuration du pipeline enfant afin qu'il puisse être déclenché par le pipeline parent. |
| `pipeline`                      | Pour les [pipelines multi-projets](../pipelines/downstream_pipelines.md#multi-project-pipelines). |
| `push`                          | Pour les pipelines déclenchés par un événement Git push, notamment pour les branches et les tags. |
| `schedule`                      | Pour les [pipelines planifiés](../pipelines/schedules.md). |
| `security_orchestration_policy` | Pour les pipelines de [politiques d'exécution de scan planifiées](../../user/application_security/policies/scan_execution_policies.md). |
| `trigger`                       | Pour les pipelines créés à l'aide d'un [jeton de déclenchement](../triggers/_index.md#configure-cicd-jobs-to-run-in-triggered-pipelines). |
| `web`                           | Pour les pipelines créés en sélectionnant **Nouveau pipeline** dans l'interface utilisateur GitLab, depuis la section **Version** > **Pipelines** du projet. |
| `webide`                        | Pour les pipelines créés à l'aide du [Web IDE](../../user/project/web_ide/_index.md). |

Ces valeurs sont les mêmes que celles renvoyées pour le paramètre `source` lors de l'utilisation du [point de terminaison de l'API pipelines](../../api/pipelines.md#list-project-pipelines).

## Règles complexes {#complex-rules}

Vous pouvez utiliser tous les mots-clés `rules`, comme `if`, `changes` et `exists`, dans la même règle. La règle est évaluée à true uniquement lorsque tous les mots-clés inclus sont évalués à true.

Par exemple :

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $VAR == "string value"
      changes:  # Include the job and set to when:manual if any of the follow paths match a modified file.
        - Dockerfile
        - docker/scripts/**/*
      when: manual
      allow_failure: true
```

Si le fichier `Dockerfile` ou tout fichier dans `/docker/scripts` a été modifié et que `$VAR == "string value"`, alors le job s'exécute manuellement et est autorisé à échouer.

Vous pouvez utiliser des parenthèses avec `&&` et `||` pour créer des expressions de variables plus complexes.

```yaml
job1:
  script:
    - echo This rule uses parentheses.
  rules:
    - if: ($CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH || $CI_COMMIT_BRANCH == "develop") && $MY_VARIABLE
```

## Éviter les pipelines en double {#avoid-duplicate-pipelines}

Si un job utilise `rules`, une seule action, comme pousser un commit vers une branche, peut déclencher plusieurs pipelines. Il n'est pas nécessaire de configurer explicitement des règles pour plusieurs types de pipeline afin de les déclencher accidentellement.

Par exemple :

```yaml
job:
  script: echo "This job creates double pipelines!"
  rules:
    - if: $CUSTOM_VARIABLE == "false"
      when: never
    - when: always
```

Ce job ne s'exécute pas lorsque `$CUSTOM_VARIABLE` est false, mais il s'exécute dans tous les autres pipelines, y compris les pipelines push (branche) et les pipelines de merge request. Avec cette configuration, chaque push vers la branche source d'un merge request ouvert entraîne des pipelines en double.

Pour éviter les pipelines en double, vous pouvez :

- Utiliser [`workflow`](../yaml/_index.md#workflow) pour spécifier les types de pipelines pouvant s'exécuter.
- Réécrire les règles pour exécuter le job uniquement dans des cas très spécifiques, et éviter une règle `when` finale :

  ```yaml
  job:
    script: echo "This job does NOT create double pipelines!"
    rules:
      - if: $CUSTOM_VARIABLE == "true" && $CI_PIPELINE_SOURCE == "merge_request_event"
  ```

Vous pouvez également éviter les pipelines en double en modifiant les règles du job pour éviter soit les pipelines push (branche), soit les pipelines de merge request. Cependant, si vous utilisez une règle `- when: always` sans `workflow: rules`, GitLab affiche un [avertissement de pipeline](../debugging.md#pipeline-warnings).

Par exemple, ce qui suit ne provoque pas de pipelines en double, mais n'est pas recommandé sans `workflow: rules` :

```yaml
job:
  script: echo "This job does NOT create double pipelines!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"
      when: never
    - when: always
```

Vous ne devez pas inclure à la fois des pipelines push et des pipelines de merge request dans le même job sans [`workflow:rules` qui empêchent les pipelines en double](../yaml/workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines) :

```yaml
job:
  script: echo "This job creates double pipelines!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

De plus, ne mélangez pas les jobs `only/except` avec les jobs `rules` dans le même pipeline. Cela peut ne pas provoquer d'erreurs YAML, mais les différents comportements par défaut de `only/except` et `rules` peuvent entraîner des problèmes difficiles à résoudre :

```yaml
job-with-no-rules:
  script: echo "This job runs in branch pipelines."

job-with-rules:
  script: echo "This job runs in merge request pipelines."
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

Pour chaque modification poussée vers la branche avec un merge request ouvert, des pipelines en double s'exécutent. Un pipeline de branche exécute un seul job (`job-with-no-rules`), et un pipeline de merge request exécute l'autre job (`job-with-rules`). Les jobs sans règles utilisent par défaut [`except: merge_requests`](../yaml/deprecated_keywords.md#only--except), donc `job-with-no-rules` s'exécute dans tous les cas sauf les merge requests.

## Réutiliser des règles dans différents jobs {#reuse-rules-in-different-jobs}

Utilisez les [balises `!reference`](../yaml/yaml_optimization.md#reference-tags) pour réutiliser des règles dans différents jobs. Vous pouvez combiner des règles `!reference` avec des règles définies dans le job. Par exemple :

```yaml
.default_rules:
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: never
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

job1:
  rules:
    - !reference [.default_rules, rules]
  script:
    - echo "This job runs for the default branch, but not schedules."

job2:
  rules:
    - !reference [.default_rules, rules]
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  script:
    - echo "This job runs for the default branch, but not schedules."
    - echo "It also runs for merge requests."
```

## Expressions de variables CI/CD {#cicd-variable-expressions}

Utilisez des expressions de variables avec [`rules:if`](../yaml/_index.md#rulesif) pour contrôler quand les jobs doivent être ajoutés à un pipeline.

Vous pouvez utiliser les opérateurs d'égalité `==` et `!=` pour comparer une variable avec une chaîne. Les guillemets simples et les guillemets doubles sont tous deux valides. La variable doit se trouver à gauche de la comparaison. Par exemple :

- `if: $VARIABLE == "some value"`
- `if: $VARIABLE != "some value"`

Vous pouvez comparer les valeurs de deux variables. Par exemple :

- `if: $VARIABLE_1 == $VARIABLE_2`
- `if: $VARIABLE_1 != $VARIABLE_2`

Vous pouvez comparer une variable au mot-clé `null` pour vérifier si elle est définie. Par exemple :

- `if: $VARIABLE == null`
- `if: $VARIABLE != null`

Vous pouvez vérifier si une variable est définie mais vide. Par exemple :

- `if: $VARIABLE == ""`
- `if: $VARIABLE != ""`

Vous pouvez vérifier si une variable est à la fois définie et non vide en utilisant uniquement le nom de la variable dans l'expression. Par exemple :

- `if: $VARIABLE`

Vous pouvez également :

- [Utiliser des entrées CI/CD dans les expressions de variables](../inputs/examples.md#use-cicd-inputs-in-variable-expressions).
- [Utiliser les variables `parallel:matrix` dans les expressions `rules:if`](job_control.md#use-matrix-variables-in-rules).

### Comparer une variable à une expression régulière {#compare-a-variable-to-a-regular-expression}

Vous pouvez effectuer des correspondances d'expressions régulières sur les valeurs de variables avec les opérateurs `=~` et `!~`.

Les expressions sont évaluées à `true` si :

- Des correspondances sont trouvées lors de l'utilisation de `=~`.
- Aucune correspondance n'est trouvée lors de l'utilisation de `!~`.

Par exemple :

- `if: $VARIABLE =~ /^content.*/`
- `if: $VARIABLE !~ /^content.*/`

De plus :

- Les expressions régulières à un seul caractère, comme `/./`, ne sont pas prises en charge et produisent une erreur `invalid expression syntax`.
- La correspondance de motifs est sensible à la casse par défaut. Utilisez le modificateur de drapeau `i` pour rendre un motif insensible à la casse. Par exemple : `/pattern/i`.
- Seul le nom du tag ou de la branche peut être mis en correspondance par une expression régulière. Le chemin du dépôt, s'il est fourni, est toujours mis en correspondance littéralement.
- Le motif entier doit être entouré de `/`. Par exemple, vous ne pouvez pas utiliser `issue-/.*/` pour faire correspondre tous les noms de tags ou de branches commençant par `issue-`, mais vous pouvez utiliser `/issue-.*/`.
- Le symbole `@` désigne le début du chemin du dépôt d'une référence. Pour faire correspondre un nom de référence contenant le caractère `@` dans une expression régulière, vous devez utiliser le code hexadécimal `\x40`.
- Utilisez les ancres `^` et `$` pour éviter que l'expression régulière ne corresponde qu'à une sous-chaîne du nom du tag ou de la branche. Par exemple, `/^issue-.*$/` est équivalent à `/^issue-/`, tandis que `/issue/` seul correspondrait également à une branche appelée `severe-issues`.
- La correspondance de motifs de variables avec des expressions régulières utilise la [syntaxe des expressions régulières RE2](https://github.com/google/re2/wiki/Syntax).

### Stocker une expression régulière dans une variable {#store-a-regular-expression-in-a-variable}

Les variables situées à droite des expressions `=~` et `!~` sont évaluées comme des expressions régulières. L'expression régulière doit être entourée de barres obliques (`/`). Par exemple :

```yaml
variables:
  pattern: '/^ab.*/'

regex-job1:
  variables:
    teststring: 'abcde'
  script: echo "This job will run, because 'abcde' matches the /^ab.*/ pattern."
  rules:
    - if: '$teststring =~ $pattern'

regex-job2:
  variables:
    teststring: 'fghij'
  script: echo "This job will not run, because 'fghi' does not match the /^ab.*/ pattern."
  rules:
    - if: '$teststring =~ $pattern'
```

Les variables dans une expression régulière ne sont pas développées. Par exemple :

```yaml
variables:
  string1: 'regex-job1'
  string2: 'regex-job2'
  pattern: '/$string2/'

regex-job1:
  script: echo "This job will NOT run, because the 'string1' variable inside the regex pattern is not expanded."
  rules:
    - if: '$CI_JOB_NAME =~ /$string1/'

regex-job2:
  script: echo "This job will NOT run, because the 'string2' variable inside the 'pattern' variable is not expanded."
  rules:
    - if: '$CI_JOB_NAME =~ $pattern'
```

### Combiner des expressions de variables {#join-variable-expressions-together}

Vous pouvez combiner plusieurs expressions à l'aide de `&&` (et) ou `||` (ou), par exemple :

- `$VARIABLE1 =~ /^content.*/ && $VARIABLE2 == "something"`
- `$VARIABLE1 =~ /^content.*/ && $VARIABLE2 =~ /thing$/ && $VARIABLE3`
- `$VARIABLE1 =~ /^content.*/ || $VARIABLE2 =~ /thing$/ && $VARIABLE3`

Vous pouvez utiliser des parenthèses pour regrouper des expressions. Les parenthèses ont la priorité sur `&&` et `||`, donc les expressions entre parenthèses sont évaluées en premier, et le résultat est utilisé pour le reste de l'expression. Pour la priorité des opérateurs, `&&` est évalué avant `||`.

Imbriquez des parenthèses pour créer des conditions complexes : les expressions les plus internes entre parenthèses sont évaluées en premier. Par exemple :

- `($VARIABLE1 =~ /^content.*/ || $VARIABLE2) && ($VARIABLE3 =~ /thing$/ || $VARIABLE4)`
- `($VARIABLE1 =~ /^content.*/ || $VARIABLE2 =~ /thing$/) && $VARIABLE3`
- `$CI_COMMIT_BRANCH == "my-branch" || (($VARIABLE1 == "thing" || $VARIABLE2 == "thing") && $VARIABLE3)`

### Nier des expressions {#negate-expressions}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219430) dans GitLab 18.11.

{{< /history >}}

Vous pouvez utiliser l'opérateur `!` pour nier une expression ou une partie d'une expression. Par exemple :

- `if: "!$VAR1"` :  Vrai lorsque la variable est vide ou non définie.
- `if: !($VAR1 == "my variable")` :  Vrai lorsque la valeur de la variable ne correspond pas à `my variable`.
- `if: $VAR1 && !$VAR2` :  Vrai lorsque `VAR1` existe et n'est pas vide, et que `VAR2` n'existe pas ou est vide.
- `if: !($VAR1 || $VAR2)` :  Vrai uniquement lorsque les deux variables n'existent pas ou sont vides.
- `if: !($VAR1 && $VAR2)` :  Vrai lorsque l'une ou l'autre des variables n'existe pas ou est vide.

> [!warning]
> L'opérateur `!` vérifie si une variable est vide ou non définie, et non si sa valeur est `false` ou `0`. Par exemple :
>
> - `!"false"` est évalué à `false` car la chaîne `"false"` n'est pas vide (les chaînes non vides sont considérées comme vraies).
> - `!"0"` est également évalué à `false` car la chaîne n'est pas vide.
> - `!""` est évalué à `true` car la chaîne est vide (les chaînes vides sont considérées comme fausses).
>
> Pour vérifier des valeurs spécifiques, utilisez des opérateurs de comparaison, par exemple `!($VAR == "false")` ou `!($VAR == "0")`.

## Migrer de `only` ou `except` vers `rules` {#migrate-from-only-or-except-to-rules}

Utilisez `rules` et des expressions de variables CI/CD pour reproduire le même comportement que les mots-clés dépréciés [`only` et `except`](../yaml/deprecated_keywords.md#only--except).

Par exemple, en partant de cette configuration dépréciée :

```yaml
job1:
  script: echo
  only:
    - main
    - /^stable-branch.*$/
    - schedules

job2:
  script: echo
  except:
    - main
    - /^issue-.*$/
    - merge_requests
```

Dans cet exemple :

- `job1` utilise `only` pour s'exécuter dans les pipelines lorsque :
  - La branche est la branche par défaut (`main`).
  - Le nom de la branche correspond au motif `/^stable-branch.*$/`.
  - Le pipeline s'exécute selon une planification.
- `job2` utilise `except` pour ignorer les pipelines lorsque :
  - La branche est la branche par défaut (`main`).
  - Le nom de la branche correspond au motif `/^issue-.*$/`.
  - Le pipeline est un pipeline de merge request.

Pour créer une configuration de pipeline similaire avec `rules`, utilisez des expressions de variables CI/CD. Par exemple, pour une migration directe de `only` et `except` vers `rules` :

```yaml
job1:
  script: echo
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_BRANCH =~ /^stable-branch.*$/
    - if: $CI_PIPELINE_SOURCE == "schedule"

job2:
  script: echo
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: never
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: never
    - if: $CI_COMMIT_BRANCH =~ /^issue-.*$/
      when: never
    - when: on_success
```

Les deux jobs se comportent de la même manière avec `rules` qu'avec `only` et `except`. Cependant, vous pouvez simplifier `job2` pour éviter les règles `when: never`.

Définissez des règles pour quand `job2` doit s'exécuter plutôt que pour quand il ne doit pas s'exécuter. Par exemple, si `job2` doit s'exécuter pour toutes les branches sauf la branche par défaut, et également pour les tags :

```yaml
job2:
  script: echo
  rules:
    - if: $CI_COMMIT_BRANCH != $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_TAG
```

Dans cet exemple, `job2` s'exécute lorsque la branche n'est pas la branche par défaut et lorsqu'un nouveau tag Git est créé. Sinon, le job ne s'exécute pas.

## Dépannage {#troubleshooting}

### Comportement inattendu lors de la correspondance d'expressions régulières avec `=~` {#unexpected-behavior-from-regular-expression-matching-with-}

Lors de l'utilisation du caractère `=~`, assurez-vous que le côté droit de la comparaison contient toujours une expression régulière valide.

Si le côté droit de la comparaison n'est pas une expression régulière valide entourée de caractères `/`, l'expression est évaluée de manière inattendue. Dans ce cas, la comparaison vérifie si le côté gauche est une sous-chaîne du côté droit. Par exemple, `"23" =~ "1234"` est évalué à true, ce qui est l'opposé de `"23" =~ /1234/`, qui est évalué à false.

Vous ne devez pas configurer votre pipeline pour qu'il s'appuie sur ce comportement.
