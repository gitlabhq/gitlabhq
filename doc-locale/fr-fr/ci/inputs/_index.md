---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisez des paramètres d'entrée typés et validés pour personnaliser les modèles et composants CI/CD réutilisables."
title: Entrées CI/CD
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/391331) dans GitLab 15.11 en tant que fonctionnalité bêta.
- [Rendu disponible en général](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/134062) dans GitLab 17.0.

{{< /history >}}

Utilisez les entrées CI/CD pour augmenter la flexibilité de la configuration CI/CD. Les entrées et les [variables CI/CD](../variables/_index.md) peuvent être utilisées de manière similaire, mais présentent des avantages différents :

- Les entrées fournissent des paramètres typés pour les modèles réutilisables avec une validation intégrée au moment de la création du pipeline. Pour définir des valeurs spécifiques lors de l'exécution du pipeline, utilisez des entrées plutôt que des variables CI/CD.
- Les variables CI/CD offrent des valeurs flexibles qui peuvent être définies à plusieurs niveaux, mais peuvent être modifiées tout au long de l'exécution du pipeline. Utilisez des variables pour les valeurs qui doivent être accessibles dans l'environnement d'exécution du job. Vous pouvez également utiliser des [variables prédéfinies](../variables/predefined_variables.md) avec `rules` pour une configuration de pipeline dynamique.

## Comparaison entre les entrées CI/CD et les variables {#cicd-inputs-and-variables-comparison}

Entrées :

- **Purpose** :  Défini dans les configurations CI (modèles, composants ou `.gitlab-ci.yml`) et dont les valeurs sont assignées lorsqu'un pipeline est déclenché, permettant aux utilisateurs de personnaliser les configurations CI réutilisables.
- **Modification** :  Une fois transmises lors de l'initialisation du pipeline, les valeurs d'entrée sont interpolées dans la configuration CI/CD et restent fixes pour l'ensemble de l'exécution du pipeline.
- **Portée** :  Disponible uniquement dans le fichier où elles sont définies, que ce soit dans `.gitlab-ci.yml` ou dans un fichier inclus avec `include`d. Vous pouvez les transmettre explicitement à d'autres fichiers — en utilisant `include:inputs` — ou au pipeline en utilisant `trigger:inputs`.
- **Validation** :  Fournit de solides capacités de validation, notamment la vérification des types, les modèles regex, les listes d'options prédéfinies et des descriptions utiles pour les utilisateurs.

Variables CI/CD :

- **Purpose** :  Valeurs pouvant être définies comme variables d'environnement lors de l'exécution d'un job et dans diverses parties du pipeline pour transmettre des données entre les jobs.
- **Modification** :  Peuvent être générées ou modifiées dynamiquement pendant l'exécution du pipeline via des artefacts dotenv, des règles conditionnelles, ou directement dans les scripts de job.
- **Portée** :  Peuvent être définies globalement (affectant tous les jobs), au niveau du job (affectant uniquement des jobs spécifiques), ou pour l'ensemble du projet ou du groupe via l'interface utilisateur GitLab.
- **Validation** :  Simples paires clé-valeur avec une validation intégrée minimale, bien que vous puissiez ajouter quelques contrôles via l'interface utilisateur GitLab pour les variables de projet.

## Définir des paramètres d'entrée avec `spec:inputs` {#define-input-parameters-with-specinputs}

Utilisez `spec:inputs` dans l'[en-tête](../yaml/_index.md#header-keywords) de configuration CI/CD pour définir les paramètres d'entrée qui peuvent être transmis au fichier de configuration.

Utilisez le format d'interpolation `$[[ inputs.input-id ]]` en dehors de la section d'en-tête pour déclarer où utiliser les entrées.

Par exemple :

```yaml
spec:
  inputs:
    job-stage:
      default: test
    environment:
      default: production
---
scan-website:
  stage: $[[ inputs.job-stage ]]
  script: ./scan-website $[[ inputs.environment ]]
```

Dans cet exemple, les entrées sont `job-stage` et `environment`.

Vous ne pouvez utiliser les valeurs d'entrée que dans le fichier comportant la section `spec`. Pour utiliser une valeur d'entrée provenant d'un fichier différent ajouté avec `include`, [transmettez-la explicitement au fichier inclus](#for-configuration-added-with-include).

Avec `spec:inputs` :

- Les entrées sont obligatoires si `default` n'est pas spécifié.
- Les entrées sont évaluées et renseignées lorsque la configuration est récupérée lors de la création du pipeline.
- Une chaîne contenant une entrée doit être inférieure à 1 Mo.
- Une chaîne dans une entrée doit être inférieure à 1 Ko.
- Les entrées peuvent utiliser des variables CI/CD, mais présentent les mêmes [limitations de variables que le mot-clé `include`](../yaml/includes.md#use-variables-with-include).
- Si le fichier qui définit `spec:inputs` contient également des définitions de job, ajoutez un séparateur de document YAML (`---`) après l'en-tête.

Ensuite, vous définissez les valeurs des entrées lorsque vous :

- [Exécutez un nouveau pipeline](#for-a-pipeline) à l'aide de ce fichier de configuration. Vous devriez toujours définir des valeurs par défaut lorsque vous utilisez des entrées pour configurer de nouveaux pipelines avec toute méthode autre que `include`. Sinon, le pipeline pourrait ne pas démarrer si un nouveau pipeline se déclenche automatiquement, notamment dans :
  - Pipelines de merge request
  - Pipelines de branche
  - Pipelines de tag
- [Inclure la configuration](#for-configuration-added-with-include) dans votre pipeline. Toutes les entrées obligatoires doivent être ajoutées à la section `include:inputs` et sont utilisées à chaque fois que la configuration est incluse.

### Configuration des entrées {#input-configuration}

Pour configurer les entrées, utilisez :

- [`spec:inputs:default`](../yaml/_index.md#specinputsdefault) pour définir les valeurs par défaut des entrées lorsqu'elles ne sont pas spécifiées. Lorsque vous spécifiez une valeur par défaut, les entrées ne sont plus obligatoires.
- [`spec:inputs:description`](../yaml/_index.md#specinputsdescription) pour donner une description à une entrée spécifique. La description n'affecte pas l'entrée, mais peut aider les utilisateurs à comprendre les détails de l'entrée ou les valeurs attendues.
- [`spec:inputs:options`](../yaml/_index.md#specinputsoptions) pour spécifier une liste de valeurs autorisées pour une entrée.
- [`spec:inputs:regex`](../yaml/_index.md#specinputsregex) pour spécifier une expression régulière à laquelle l'entrée doit correspondre.
- [`spec:inputs:type`](../yaml/_index.md#specinputstype) pour forcer un type d'entrée spécifique, qui peut être `string` (par défaut si non spécifié), `array`, `number`, ou `boolean`.
- [`spec:inputs:rules`](../yaml/_index.md#specinputsrules) pour définir des valeurs `options` et `default` conditionnelles basées sur les valeurs d'autres entrées.

Vous pouvez définir plusieurs entrées par fichier de configuration CI/CD, et chaque entrée peut avoir plusieurs paramètres de configuration.

Par exemple, dans un fichier nommé `scan-website-job.yml` :

```yaml
spec:
  inputs:
    job-prefix:     # Mandatory string input
      description: "Define a prefix for the job name"
    job-stage:      # Optional string input with a default value when not provided
      default: test
    environment:    # Mandatory input that must match one of the options
      options: ['test', 'staging', 'production']
    concurrency:
      type: number  # Optional numeric input with a default value when not provided
      default: 1
    version:        # Mandatory string input that must match the regular expression
      type: string
      regex: ^v\d\.\d+(\.\d+)$
    export_results: # Optional boolean input with a default value when not provided
      type: boolean
      default: true
---

"$[[ inputs.job-prefix ]]-scan-website":
  stage: $[[ inputs.job-stage ]]
  script:
    - echo "scanning website -e $[[ inputs.environment ]] -c $[[ inputs.concurrency ]] -v $[[ inputs.version ]]"
    - if $[[ inputs.export_results ]]; then echo "export results"; fi
```

Dans cet exemple :

- `job-prefix` est une entrée de type chaîne obligatoire et doit être définie.
- `job-stage` est facultatif. Si non défini, la valeur est `test`.
- `environment` est une entrée de type chaîne obligatoire qui doit correspondre à l'une des options définies.
- `concurrency` est une entrée numérique facultative. Si non spécifié, la valeur par défaut est `1`.
- `version` est une entrée de type chaîne obligatoire qui doit correspondre à l'expression régulière spécifiée.
- `export_results` est une entrée booléenne facultative. Si non spécifié, la valeur par défaut est `true`.

### Types d'entrée {#input-types}

Vous pouvez spécifier qu'une entrée doit utiliser un type spécifique avec le mot-clé facultatif `spec:inputs:type`.

Les types d'entrée sont :

- [`array`](#array-type)
- `boolean`
- `number`
- `string` (par défaut si non spécifié)

Lorsqu'une entrée remplace une valeur YAML entière dans la configuration CI/CD, elle est interpolée dans la configuration selon son type spécifié. Par exemple :

```yaml
spec:
  inputs:
    array_input:
      type: array
    boolean_input:
      type: boolean
    number_input:
      type: number
    string_input:
      type: string
---

test_job:
  allow_failure: $[[ inputs.boolean_input ]]
  needs: $[[ inputs.array_input ]]
  parallel: $[[ inputs.number_input ]]
  script: $[[ inputs.string_input ]]
```

Lorsqu'une entrée est insérée dans une valeur YAML dans le cadre d'une chaîne plus longue, l'entrée est toujours interpolée en tant que chaîne. Par exemple :

```yaml
spec:
  inputs:
    port:
      type: number
---

test_job:
  script: curl "https://gitlab.com:$[[ inputs.port ]]"
```

#### Type tableau {#array-type}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/407176) dans GitLab 16.11.

{{< /history >}}

Le contenu des éléments d'un type tableau peut être n'importe quelle carte YAML valide, séquence ou scalaire. Les fonctionnalités YAML plus complexes comme [`!reference`](../yaml/yaml_optimization.md#reference-tags) ne peuvent pas être utilisées. Lors de l'utilisation de la valeur d'une entrée de type tableau dans une chaîne (par exemple `echo "My rules: $[[ inputs.rules-config ]]"` dans votre section `script:`), vous pourriez obtenir des résultats inattendus. L'entrée de type tableau est convertie en sa représentation sous forme de chaîne, qui pourrait ne pas correspondre à vos attentes pour des structures YAML complexes telles que les cartes.

```yaml
spec:
  inputs:
    rules-config:
      type: array
      default:
        - if: $CI_PIPELINE_SOURCE == "merge_request_event"
          when: manual
        - if: $CI_PIPELINE_SOURCE == "schedule"
---

test_job:
  rules: $[[ inputs.rules-config ]]
  script: ls
```

Les entrées de type tableau doivent être formatées en JSON, par exemple `["array-input-1", "array-input-2"]`, lors de la transmission manuelle d'entrées pour :

- [Pipelines exécutés manuellement](../pipelines/_index.md#run-a-pipeline-manually).
- L'[API de déclenchement de pipeline](../../api/pipeline_triggers.md#trigger-a-pipeline-with-a-token).
- L'[API des pipelines](../../api/pipelines.md#create-a-new-pipeline).
- Les [options push](../../topics/git/commit.md#push-options-for-gitlab-cicd) Git
- [Planifications de pipeline](../pipelines/schedules.md#create-a-pipeline-schedule)

##### Entrées de type tableau avec options {#array-inputs-with-options}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/566155) dans GitLab 19.0.

{{< /history >}}

Vous pouvez définir une liste d'options pour restreindre les valeurs autorisées pour les entrées de type tableau. Lorsque vous exécutez un pipeline manuellement, l'interface utilisateur affiche une liste déroulante à sélection multiple au lieu d'un champ de texte. Par exemple :

```yaml
spec:
  inputs:
    runner_tags:
      type: array
      default: ["docker"]
      options:
        - docker
        - linux
        - gpu
        - macos
---

test:
  script:
    - run_tests.sh
  tags: $[[ inputs.runner_tags ]]
```

Le pipeline ne démarre pas si une valeur de l'entrée de type tableau ne correspond pas à une option listée.

##### Accéder aux éléments individuels d'un tableau {#access-individual-array-elements}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/587657) dans GitLab 18.10 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `ci_inputs_array_index_operator`. Désactivé par défaut.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/work_items/587657) dans GitLab 18.11. Indicateur de feature flag `ci_inputs_array_index_operator` supprimé.

{{< /history >}}

Utilisez la notation entre crochets avec un numéro d'index pour accéder aux éléments individuels d'une entrée de type tableau. Les éléments du tableau sont indexés dans l'ordre où ils sont définis dans le tableau YAML, avec des nombres positifs, et l'élément d'index `[0]` est le premier élément du tableau.

Par exemple :

```yaml
spec:
  inputs:
    supported_versions:
      type: array
      default:
        - '2.0'
        - '1.0'
        - '0.1'
---

job:
  script:
    # Outputs: 'Latest version is 2.0'
    - echo 'Latest version is $[[ inputs.supported_versions[0] ]]'
```

Vous pouvez chaîner l'indexation de tableau avec la notation par points pour accéder aux valeurs imbriquées :

```yaml
spec:
  inputs:
    servers:
      type: array
      default:
        - host: server1.example.com
          port: 8080
---

job:
  script:
    - curl "https://$[[ inputs.servers[0].host ]]:$[[ inputs.servers[0].port ]]"
```

Pour les tableaux multidimensionnels, utilisez plusieurs indices à la suite. Par exemple, vous pouvez utiliser `[0][1]` pour un tableau à 2 dimensions :

```yaml
spec:
  inputs:
    matrix:
      type: array
      default:
        - ['a', 'b']
        - ['c', 'd']
---

job:
  script:
    # Outputs: 'b'
    - echo $[[ inputs.matrix[0][1] ]]
```

Vous pouvez chaîner un maximum de 5 indices par segment, par exemple `arr[0][1][2][3][4]`.

#### Valeurs de chaînes d'entrée multi-lignes {#multi-line-input-string-values}

Les entrées prennent en charge différents types de valeurs. Vous pouvez transmettre des valeurs de chaînes multiples en utilisant le format suivant :

```yaml
spec:
  inputs:
    closed_message:
      description: Message to announce when an issue is closed.
      default: 'Hi {{author}} :wave:,

        Based on the policy for inactive issues, this is now being closed.

        If this issue requires further attention, reopen this issue.'
---
```

### Définir des options d'entrée conditionnelles avec `spec:inputs:rules` {#define-conditional-input-options-with-specinputsrules}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/18546) dans GitLab 18.7.

{{< /history >}}

Utilisez [`spec:inputs:rules`](../yaml/_index.md#specinputsrules) pour définir différentes valeurs `options` et `default` pour une entrée en fonction des valeurs d'autres entrées. Vous pouvez utiliser cette configuration lorsqu'une entrée doit avoir différentes valeurs autorisées selon le contexte fourni par d'autres entrées.

Chaque règle dans la liste `rules` peut avoir :

- `if` :  Une expression qui vérifie les valeurs d'une ou plusieurs entrées pour déterminer quand cette règle s'applique. Utilise la même syntaxe que [l'interpolation `$[[ inputs.input-id ]]`](#define-input-parameters-with-specinputs).
- `options` :  Une liste de valeurs autorisées pour l'entrée lorsque cette règle correspond.
- `default` :  La valeur par défaut à utiliser lorsque cette règle correspond.

Les règles sont évaluées dans l'ordre. La première règle avec une condition `if` correspondante est utilisée. La dernière règle sans condition `if` agit comme solution de repli lorsqu'aucune autre règle ne correspond.

Par exemple, pour définir des types d'instances qui varient selon le fournisseur cloud et l'environnement :

```yaml
spec:
  inputs:
    cloud_provider:
      options: ['aws', 'gcp', 'azure']
      default: 'aws'
      description: 'Cloud provider'

    environment:
      options: ['development', 'staging', 'production']
      default: 'development'
      description: 'Target environment'

    instance_type:
      description: 'VM instance type'
      rules:
        - if: $[[ inputs.cloud_provider ]] == 'aws' && $[[ inputs.environment ]] == 'development'
          options: ['t3.micro', 't3.small']
          default: 't3.micro'
        - if: $[[ inputs.cloud_provider ]] == 'aws' && $[[ inputs.environment ]] == 'production'
          options: ['t3.xlarge', 't3.2xlarge', 'm5.xlarge']
          default: 't3.xlarge'
        - if: $[[ inputs.cloud_provider ]] == 'gcp'
          options: ['e2-micro', 'e2-small', 'e2-standard-4']
          default: 'e2-micro'
        - if: $[[ inputs.cloud_provider ]] == 'azure'
          options: ['Standard_B1s', 'Standard_B2s', 'Standard_D2s_v3']
          default: 'Standard_B1s'
        - options: ['small', 'medium', 'large']  # Fallback for any other case
          default: 'small'
---

deploy:
  script: |
    echo "Deploying to $[[ inputs.cloud_provider ]]"
    echo "Environment: $[[ inputs.environment ]]"
    echo "Instance: $[[ inputs.instance_type ]]"
```

Dans cet exemple :

- Lorsque `cloud_provider` est `aws` et `environment` est `development`, l'utilisateur peut sélectionner parmi les types d'instances `t3.micro` ou `t3.small`, avec `t3.micro` comme valeur par défaut.
- Lorsque `cloud_provider` est `aws` et `environment` est `production`, différents types d'instances sont disponibles (`t3.xlarge`, `t3.2xlarge`, `m5.xlarge`).
- Lorsque `cloud_provider` est `gcp`, les types d'instances spécifiques à GCP sont disponibles quel que soit l'environnement.
- Si aucune des conditions ne correspond, la règle de repli fournit des options de taille génériques.

Vous pouvez également utiliser l'opérateur `||` (OR) pour faire correspondre plusieurs conditions. Par exemple :

```yaml
spec:
  inputs:
    deployment_type:
      options: ['canary', 'blue-green', 'rolling', 'recreate']
      default: 'rolling'

    requires_approval:
      description: 'Whether deployment requires manual approval'
      rules:
        - if: $[[ inputs.deployment_type ]] == 'canary' || $[[ inputs.deployment_type ]] == 'blue-green'
          options: ['true']
          default: 'true'
        - options: ['true', 'false']
          default: 'false'
---

deploy:
  script: echo "Deploying with $[[ inputs.deployment_type ]] strategy"
```

Dans cet exemple, l'entrée `requires_approval` est définie sur `true` lorsque `deployment_type` est soit `canary` soit `blue-green`. Dans tous les autres cas, la valeur par défaut est `false` et `true` ou `false` sont tous les deux des options autorisées.

### Autoriser les valeurs saisies par l'utilisateur avec `default: null` {#allow-user-entered-values-with-default-null}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218804) dans GitLab 18.9.

{{< /history >}}

Utilisez `spec:inputs:rules` avec `default: null` et sans `options` pour permettre aux utilisateurs de saisir leur propre valeur pour une entrée. Ceci est utile pour les valeurs spécifiques au flux de travail, comme les noms d'environnements ou les configurations de test.

Par exemple :

```yaml
spec:
  inputs:
    deployment_type:
      options: ['standard', 'custom']
      default: 'standard'

    custom_config:
      description: 'Custom configuration value'
      rules:
        - if: $[[ inputs.deployment_type ]] == 'custom'
          default: null
---

deploy:
  script: echo "Config: $[[ inputs.custom_config ]]"
```

Dans cet exemple, lorsque `deployment_type` est `custom`, l'entrée `custom_config` est répertoriée sur la page d'exécution du pipeline et les utilisateurs doivent saisir une valeur pour l'entrée.

### Utiliser des entrées booléennes avec `spec:inputs:rules` {#use-boolean-inputs-with-specinputsrules}

Vous pouvez utiliser des entrées booléennes dans les conditions de règle. Les valeurs booléennes peuvent être comparées à l'aide de littéraux booléens (`true`/`false`) :

```yaml
spec:
  inputs:
    publish:
      type: boolean
      default: true

    publish_stage:
      rules:
        - if: $[[ inputs.publish ]] == true
          default: 'publish'
        - if: $[[ inputs.publish ]] == false
          default: 'test'
---

job:
  stage: $[[ inputs.publish_stage ]]
  script: echo "Publishing is $[[ inputs.publish ]]"
```

Dans cet exemple, lorsque `publish` est `true`, `publish_stage` prend par défaut la valeur `publish`. Lorsque `publish` est `false`, la valeur par défaut est `test`.

## Définir les valeurs d'entrée {#set-input-values}

Vous pouvez définir les valeurs d'entrée dans la configuration de votre pipeline ou lors du déclenchement d'un pipeline.

Une fois le pipeline démarré, vous ne pouvez pas récupérer les valeurs d'entrée utilisées. Si une valeur est sûre à exposer, vous pouvez l'afficher dans un job log pour référence future, ou la sauvegarder dans un artefact.

### Pour la configuration ajoutée avec `include` {#for-configuration-added-with-include}

{{< history >}}

- `include:with` [renommé en `include:inputs`](https://gitlab.com/gitlab-org/gitlab/-/issues/406780) dans GitLab 16.0.

{{< /history >}}

Utilisez [`include:inputs`](../yaml/_index.md#includeinputs) pour définir les valeurs des entrées lorsque la configuration incluse est ajoutée au pipeline, notamment pour :

- [Composants CI/CD](../components/_index.md)
- Toute autre configuration ajoutée avec `include`.

Par exemple, pour inclure et définir les valeurs d'entrée pour `scan-website-job.yml` à partir de l'[exemple de configuration d'entrée](#input-configuration) :

```yaml
include:
  - local: 'scan-website-job.yml'
    inputs:
      job-prefix: 'some-service-'
      environment: 'staging'
      concurrency: 2
      version: 'v1.3.2'
      export_results: false
```

Dans cet exemple, les entrées pour la configuration incluse sont :

| Entrée            | Valeur           | Détails |
|------------------|-----------------|---------|
| `job-prefix`     | `some-service-` | Doit être explicitement défini. |
| `job-stage`      | `test`          | Non défini dans `include:inputs`, donc la valeur provient de `spec:inputs:default` dans la configuration incluse. |
| `environment`    | `staging`       | Doit être explicitement défini et doit correspondre à l'une des valeurs dans `spec:inputs:options` de la configuration incluse. |
| `concurrency`    | `2`             | Doit être une valeur numérique pour correspondre au `spec:inputs:type` défini sur `number` dans la configuration incluse. Remplace la valeur par défaut. |
| `version`        | `v1.3.2`        | Doit être explicitement défini et doit correspondre à l'expression régulière dans `spec:inputs:regex` de la configuration incluse. |
| `export_results` | `false`         | Doit être soit `true` soit `false` pour correspondre au `spec:inputs:type` défini sur `boolean` dans la configuration incluse. Remplace la valeur par défaut. |

Les valeurs d'entrée sont uniquement disponibles dans le même fichier que la section `spec` qui les définit. Un fichier ajouté avec `include` ne peut pas accéder aux entrées définies dans d'autres fichiers, ni dans le fichier qui l'inclut. Pour utiliser une valeur d'un fichier inclus, transmettez-la explicitement avec `include:inputs`.

#### Avec plusieurs entrées `include` {#with-multiple-include-entries}

Les entrées doivent être spécifiées séparément pour chaque entrée include. Par exemple :

```yaml
include:
  - component: $CI_SERVER_FQDN/the-namespace/the-project/the-component@1.0
    inputs:
      stage: my-stage
  - local: path/to/file.yml
    inputs:
      stage: my-stage
```

### Pour un pipeline {#for-a-pipeline}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/16321) dans GitLab 17.11.

{{< /history >}}

Les entrées offrent des avantages par rapport aux variables, notamment la vérification des types, la validation et un contrat clair. Les entrées inattendues sont rejetées. Les entrées pour les pipelines doivent être définies dans l'[en-tête `spec:inputs`](#define-input-parameters-with-specinputs) du fichier principal `.gitlab-ci.yml`. Vous ne pouvez pas utiliser des entrées définies dans des fichiers inclus pour la configuration au niveau du pipeline.

> [!note]
> Dans [GitLab 17.7](../../update/deprecations.md#increased-default-security-for-use-of-pipeline-variables) et versions ultérieures, les entrées de pipeline sont recommandées plutôt que la transmission de [variables de pipeline](../variables/_index.md#use-pipeline-variables). Pour une sécurité renforcée, vous devriez [désactiver les variables de pipeline](../variables/_index.md#restrict-pipeline-variables) lors de l'utilisation d'entrées.

Vous devriez toujours définir des valeurs par défaut lors de la définition des entrées pour les pipelines. Si une entrée n'a pas de valeur par défaut, le pipeline échoue lorsqu'il se déclenche automatiquement. Par exemple, les pipelines de pipeline de merge request peuvent se déclencher pour des modifications apportées à la branche source d'une merge request. Vous ne pouvez pas définir manuellement des entrées pour les pipelines de merge request, donc si une entrée n'a pas de valeur par défaut, le pipeline échoue. Cela peut également se produire pour les pipelines de branche, les pipelines de tag et les autres pipelines déclenchés automatiquement.

Vous pouvez définir les valeurs d'entrée avec :

- [Pipelines downstream](../pipelines/downstream_pipelines.md#pass-inputs-to-a-downstream-pipeline)
- [Pipelines exécutés manuellement](../pipelines/_index.md#run-a-pipeline-manually).
- L'[API de déclenchement de pipeline](../../api/pipeline_triggers.md#trigger-a-pipeline-with-a-token)
- L'[API des pipelines](../../api/pipelines.md#create-a-new-pipeline)
- Les [options push](../../topics/git/commit.md#push-options-for-gitlab-cicd) Git
- [Planifications de pipeline](../pipelines/schedules.md#create-a-pipeline-schedule)
- Le [mot-clé `trigger`](../pipelines/downstream_pipelines.md#pass-inputs-to-a-downstream-pipeline)

Un pipeline peut accepter jusqu'à 20 entrées.

Les retours sont les bienvenus sur [ce ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/533802).

Vous pouvez transmettre des entrées aux [pipelines downstream](../pipelines/downstream_pipelines.md), si le fichier de configuration du pipeline downstream utilise [`spec:inputs`](#define-input-parameters-with-specinputs).

Par exemple, avec [`trigger:inputs`](../yaml/_index.md#triggerinputs) :

{{< tabs >}}

{{< tab title="Pipeline parent-enfant" >}}

```yaml
trigger-job:
  trigger:
    strategy: mirror
    include:
      - local: path/to/child-pipeline.yml
        inputs:
          job-name: "defined"
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
```

{{< /tab >}}

{{< tab title="Pipeline multi-projets" >}}

```yaml
trigger-job:
  trigger:
    strategy: mirror
    project: project-group/my-downstream-project
    inputs:
      job-name: "defined"
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
```

{{< /tab >}}

{{< /tabs >}}

#### Définir des entrées de pipeline dans des fichiers externes {#define-pipeline-inputs-in-external-files}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206931) dans GitLab 18.6 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `ci_file_inputs`. Désactivé par défaut.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/579240) dans GitLab 18.9. Indicateur de feature flag `ci_file_inputs` supprimé.

{{< /history >}}

Vous pouvez réutiliser les définitions d'entrée de pipeline dans plusieurs configurations CI/CD en les définissant dans des fichiers externes et en les incluant dans la configuration de pipeline d'un projet avec [`spec:include`](../yaml/_index.md#specinclude).

Créez un fichier avec des définitions d'entrée, par exemple dans un fichier nommé `shared-inputs.yml` :

```yaml
inputs:
  environment:
    description: "Deployment environment"
    options: ['staging', 'production']
  region:
    default: 'us-east-1'
```

Vous pouvez ensuite inclure les entrées externes dans votre `.gitlab-ci.yml` avec `local` :

```yaml
spec:
  include:
    - local: /shared-inputs.yml
---

deploy:
  script: echo "Deploying to $[[ inputs.environment ]] in $[[ inputs.region ]]"
```

Si le fichier est stocké en dehors de votre projet, vous pouvez utiliser :

- `project` pour les fichiers dans un autre projet GitLab. Utilisez le chemin complet du projet et définissez le nom de fichier avec `file`. Vous pouvez également définir la `ref` à partir de laquelle récupérer le fichier.
- `remote` pour les fichiers sur un autre serveur. Utilisez l'URL complète vers le fichier.

Vous pouvez également inclure plusieurs fichiers d'entrée en même temps, par exemple :

```yaml
spec:
  include:
    - local: /shared-inputs.yml
    - project: 'my-group/shared-configs'
      ref: main
      file: '/ci/common-inputs.yml'
    - remote: 'https://example.com/ci/shared-inputs.yml'
---
```

> [!note]
> Vous ne pouvez pas utiliser `spec:include` pour les entrées de [composant CI/CD](../components/_index.md#component-spec-section).

#### Remplacer les entrées d'un fichier externe {#override-inputs-from-an-external-file}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/557867) dans GitLab 18.9.

{{< /history >}}

Les clés d'entrée doivent être uniques dans tous les fichiers inclus et les spécifications en ligne. Si vous définissez une entrée avec la même clé dans plusieurs fichiers inclus, ou à la fois dans un fichier inclus et la section `inputs:` dans la configuration `.gitlab-ci.yml`, l'erreur suivante est retournée :

```plaintext
Duplicate input keys found: environment. Input keys must be unique across all included files and inline specifications.
```

Pour corriger cette erreur, assurez-vous que chaque clé d'entrée est définie une seule fois, soit dans un fichier inclus, soit dans la section `inputs:` en ligne, mais pas les deux.

## Spécifier des fonctions pour manipuler les valeurs d'entrée {#specify-functions-to-manipulate-input-values}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/409462) dans GitLab 16.3.

{{< /history >}}

Vous pouvez spécifier des fonctions prédéfinies dans le bloc d'interpolation pour manipuler la valeur d'entrée. Le format pris en charge est le suivant :

```yaml
$[[ input.input-id | <function1> | <function2> | ... <functionN> ]]
```

Avec les fonctions :

- Seules les [fonctions d'interpolation prédéfinies](#predefined-interpolation-functions) sont autorisées.
- Un maximum de 3 fonctions peut être spécifié dans un seul bloc d'interpolation.
- Les fonctions sont exécutées dans l'ordre où elles sont spécifiées.

```yaml
spec:
  inputs:
    test:
      default: 'test $MY_VAR'
---

test-job:
  script: echo $[[ inputs.test | expand_vars | truncate(5,8) ]]
```

Dans cet exemple, en supposant que l'entrée utilise la valeur par défaut et que `$MY_VAR` est une variable de projet non masquée avec la valeur `my value` :

1. D'abord, la fonction [`expand_vars`](#expand_vars) développe la valeur en `test my value`.
1. Ensuite, [`truncate`](#truncate) s'applique à `test my value` avec un décalage de caractères de `5` et une longueur de `8`.
1. La sortie de `script` serait `echo my value`.

### Fonctions d'interpolation prédéfinies {#predefined-interpolation-functions}

#### `expand_vars` {#expand_vars}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/387632) dans GitLab 16.5.

{{< /history >}}

Utilisez `expand_vars` pour développer les [variables CI/CD](../variables/_index.md) dans la valeur d'entrée.

Seules les variables que vous pouvez [utiliser avec le mot-clé `include`](../yaml/includes.md#use-variables-with-include) et qui ne sont **pas** [masquées](../variables/_index.md#mask-a-cicd-variable) peuvent être développées. L'[expansion de variables imbriquées](../variables/where_variables_can_be_used.md#nested-variable-expansion) n'est pas prise en charge.

Exemple :

```yaml
spec:
  inputs:
    test:
      default: 'test $MY_VAR'
---

test-job:
  script: echo $[[ inputs.test | expand_vars ]]
```

Dans cet exemple, si `$MY_VAR` n'est pas masquée (exposée dans les job logs) avec une valeur de `my value`, alors l'entrée se développerait en `test my value`.

#### `truncate` {#truncate}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/409462) dans GitLab 16.3.

{{< /history >}}

Utilisez `truncate` pour raccourcir la valeur interpolée. Par exemple :

- `truncate(<offset>,<length>)`

| Nom | Type | Description |
| ---- | ---- | ----------- |
| `offset` | Entier | Nombre de caractères de décalage. |
| `length` | Entier | Nombre de caractères à retourner après le décalage. |

Exemple :

```yaml
$[[ inputs.test | truncate(3,5) ]]
```

En supposant que la valeur de `inputs.test` est `0123456789`, la sortie serait `34567`.

#### `posix_escape` {#posix_escape}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/568289) dans GitLab 18.6.

{{< /history >}}

Utilisez `posix_escape` pour échapper les caractères de contrôle ou métacaractères _Bourne shell_ POSIX dans les valeurs d'entrée. `posix_escape` échappe les caractères en insérant ` \ ` avant les caractères concernés dans l'entrée.

Exemple :

```yaml
spec:
  inputs:
    test:
      default: |
        A string with single ' and double " quotes and   blanks
---

test-job:
  script: printf '%s\n' $[[ inputs.test | posix_escape ]]
```

Dans cet exemple, `posix_escape` échappe les caractères qui pourraient être des caractères de contrôle shell ou des métacaractères :

```console
$ printf '%s\n' A\ string\ with\ single\ \'\ and\ double\ \"\ quotes\ and\ \ \ blanks
A string with single ' and double " quotes and   blanks
```

L'entrée échappée préserve les caractères spéciaux et l'espacement tels que fournis.

> [!warning]
> Ne pas utiliser `posix_escape` à des fins de sécurité avec des valeurs d'entrée non fiables.

`posix_escape` tente du mieux possible de préserver exactement la valeur d'entrée, mais certaines combinaisons de caractères peuvent toujours provoquer des résultats indésirables. Même lors de l'utilisation de `posix_escape`, il est possible que :

- Du code shell inclus dans la chaîne puisse être exécuté.
- Des guillemets simples ou doubles puissent être utilisés pour échapper les guillemets environnants.
- Des références de variables puissent être utilisées pour accéder aux variables protégées.
- Des redirections d'entrée ou de sortie puissent être utilisées pour lire ou écrire dans des fichiers locaux.
- Les espaces non échappés sont utilisés par les shells pour diviser une chaîne en plusieurs arguments.

Pour des raisons de sécurité, vous devriez vous assurer que vos entrées sont fiables. Vous pouvez utiliser :

- Le [`spec:input:type`](../yaml/_index.md#specinputstype) `number` ou `boolean`, qui ne peuvent pas contenir de caractères problématiques.
- Le mot-clé [`spec:input:regex`](../yaml/_index.md#specinputsregex) pour empêcher les entrées problématiques.
- Le mot-clé [`spec:input:options`](../yaml/_index.md#specinputsoptions) pour définir une liste prédéfinie d'options d'entrée.

Si vous combinez `posix_escape` avec `expand_vars`, vous devez d'abord définir `expand_vars`. Sinon, `posix_escape` échapperait le `$` dans la variable, empêchant l'expansion. Par exemple :

```yaml
test-job:
  script: echo $[[ inputs.test | expand_vars | posix_escape ]]
```

## Dépannage {#troubleshooting}

### Erreurs de syntaxe YAML lors de l'utilisation de `inputs` dans `rules` {#yaml-syntax-errors-when-using-inputs-in-rules}

Lorsque vous utilisez une entrée pour modifier des expressions `rules:if`, vous pourriez obtenir l'une [des nombreuses erreurs de syntaxe](../jobs/job_troubleshooting.md#this-gitlab-ci-configuration-is-invalid-for-variable-expressions).

Ces erreurs sont souvent liées à la façon dont les chaînes sont gérées dans les [expressions de variables CI/CD](../jobs/job_rules.md#cicd-variable-expressions). Les expressions dans `rules:if` attendent une variable CI/CD comparée à une chaîne entre guillemets (`'` ou `"`) ou à une autre variable. Lorsque les valeurs d'entrée sont insérées dans la configuration `rules` lors de l'exécution du pipeline, la valeur résultante pourrait ne pas être une chaîne entre guillemets ou une variable, ce qui provoque l'erreur.

Par exemple, dans la configuration à inclure :

```yaml
spec:
  inputs:
    branch:
      default: $CI_DEFAULT_BRANCH
    branch2:
      default: $CI_DEFAULT_BRANCH
---

job-name:
  rules:
    - if: $CI_COMMIT_REF_NAME == $[[ inputs.branch ]]
    - if: $CI_COMMIT_REF_NAME == $[[ inputs.branch2 ]]
```

Ensuite, dans le fichier de configuration principal :

```yaml
include:
  inputs:
    branch: $CI_DEFAULT_BRANCH  # Valid
    branch2: main               # Invalid
```

Dans cet exemple :

- L'utilisation de `branch: $CI_DEFAULT_BRANCH` est valide. La clause `if:` évalue à `if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH`, ce qui est une expression de variable valide. La variable n'a pas besoin d'être entre guillemets.
- L'utilisation de `branch2: main` est invalide. La clause `if:` évalue à `if: $CI_COMMIT_REF_NAME == main`, ce qui est invalide car `main` est une chaîne mais n'est pas entre guillemets.

Pour résoudre ce problème, assurez-vous que les expressions restent correctement formatées après l'insertion des valeurs d'entrée dans la configuration. Cela peut nécessiter des guillemets supplémentaires. Par exemple, ajoutez des guillemets aux règles qui utilisent des valeurs de type chaîne :

```yaml
rules:
  if: $CI_COMMIT_REF_NAME == "$[[ inputs.branch2 ]]"
```

Pour les fonctions d'interpolation comme [`expand_vars`](#expand_vars), vous pourriez également avoir besoin de mettre entre guillemets l'expression `if:` entière. Par exemple :

```yaml
spec:
  inputs:
    environment:
      default: "$ENVIRONMENT"
---

$[[ inputs.environment | expand_vars ]] job:
  script: echo
  rules:
    - if: '"$[[ inputs.environment | expand_vars ]]" == "production"'
```

Dans cet exemple, mettre entre guillemets à la fois l'entrée et l'expression `if:` entière garantit une syntaxe valide après l'évaluation de l'entrée. Lorsque les guillemets sont imbriqués, utilisez `"` pour les guillemets internes et `'` pour les guillemets externes, ou l'inverse.

Les noms de job n'ont pas besoin d'être entre guillemets.
