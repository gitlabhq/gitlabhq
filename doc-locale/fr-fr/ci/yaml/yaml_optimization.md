---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Optimiser les fichiers de configuration GitLab CI/CD
description: "Utilisez les ancres YAML, les tags !reference et le mot-clé `extends` pour réduire la complexité des fichiers de configuration CI/CD."
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez réduire la complexité et la duplication de configuration dans vos fichiers de configuration GitLab CI/CD en utilisant :

- Les fonctionnalités spécifiques à YAML comme les [ancres (`&`)](#anchors), les alias (`*`), et la fusion de tables (`<<`). Pour en savoir plus sur les diverses [fonctionnalités YAML](https://learnxinyminutes.com/docs/yaml/).
- Le [mot-clé `extends`](#use-extends-to-reuse-configuration-sections), qui est plus flexible et lisible. Utilisez `extends` dès que possible.

Pour créer plusieurs jobs similaires, mais avec des valeurs de variables différentes, utilisez [parallel:matrix](../jobs/job_control.md#run-a-matrix-of-parallel-trigger-jobs).

## Ancres {#anchors}

YAML dispose d'une fonctionnalité appelée « ancres » que vous pouvez utiliser pour dupliquer du contenu dans votre document.

Vous pouvez utiliser les ancres pour dupliquer ou hériter des propriétés. Utilisez les ancres avec les [jobs masqués](../jobs/_index.md#hide-a-job) pour fournir des modèles à vos jobs.

Le caractère `&` marque le nom de l'ancre, et le caractère `*` est l'alias qui référence l'ancre. Vous devez définir l'ancre plus haut dans le fichier YAML que tous les alias qui la référencent.

En cas de clés dupliquées, la dernière clé incluse prend le dessus et remplace les autres clés.

Dans certains cas (voir [les ancres YAML pour les scripts](#yaml-anchors-for-scripts)), vous pouvez utiliser les ancres YAML pour construire des tableaux avec plusieurs composants définis ailleurs. Par exemple :

```yaml
.default_scripts: &default_scripts
  - ./default-script1.sh
  - ./default-script2.sh

job1:
  script:
    - *default_scripts
    - ./job-script.sh
```

Vous ne pouvez pas utiliser les ancres YAML dans plusieurs fichiers lorsque vous utilisez le mot-clé [`include`](_index.md#include). Les ancres ne sont valides que dans le fichier où elles ont été définies. Pour réutiliser la configuration de différents fichiers YAML, utilisez les [tags `!reference`](#reference-tags) ou le [mot-clé `extends`](#use-extends-to-reuse-configuration-sections).

L'exemple suivant utilise des ancres et la fusion de tables. Il crée deux jobs, `test1` et `test2`, qui héritent de la configuration `.job_template`, chacun avec son propre `script` personnalisé défini :

```yaml
.job_template: &job_configuration  # Hidden yaml configuration that defines an anchor named 'job_configuration'
  image: ruby:2.6
  services:
    - postgres
    - redis

test1:
  <<: *job_configuration           # Add the contents of the 'job_configuration' alias
  script:
    - test1 project

test2:
  <<: *job_configuration           # Add the contents of the 'job_configuration' alias
  script:
    - test2 project
```

`&` définit le nom de l'ancre (`job_configuration`), `<<` signifie « fusionner la table donnée dans la table courante », et `*` inclut l'ancre nommée (`job_configuration` à nouveau). La version [développée](../pipeline_editor/_index.md#view-full-configuration) de cet exemple est :

```yaml
.job_template:
  image: ruby:2.6
  services:
    - postgres
    - redis

test1:
  image: ruby:2.6
  services:
    - postgres
    - redis
  script:
    - test1 project

test2:
  image: ruby:2.6
  services:
    - postgres
    - redis
  script:
    - test2 project
```

Vous pouvez utiliser les ancres pour définir deux ensembles de services. Par exemple, `test:postgres` et `test:mysql` partagent le `script` défini dans `.job_template`, mais utilisent des `services` différents, définis dans `.postgres_services` et `.mysql_services` :

```yaml
.job_template: &job_configuration
  script:
    - test project
  tags:
    - dev

.postgres_services:
  services: &postgres_configuration
    - postgres
    - ruby

.mysql_services:
  services: &mysql_configuration
    - mysql
    - ruby

test:postgres:
  <<: *job_configuration
  services: *postgres_configuration
  tags:
    - postgres

test:mysql:
  <<: *job_configuration
  services: *mysql_configuration
```

La version [développée](../pipeline_editor/_index.md#view-full-configuration) est :

```yaml
.job_template:
  script:
    - test project
  tags:
    - dev

.postgres_services:
  services:
    - postgres
    - ruby

.mysql_services:
  services:
    - mysql
    - ruby

test:postgres:
  script:
    - test project
  services:
    - postgres
    - ruby
  tags:
    - postgres

test:mysql:
  script:
    - test project
  services:
    - mysql
    - ruby
  tags:
    - dev
```

Vous pouvez constater que les jobs masqués sont utilisés de manière pratique comme modèles, et que `tags: [postgres]` remplace `tags: [dev]`.

### Ancres YAML pour les scripts {#yaml-anchors-for-scripts}

Vous pouvez utiliser les [ancres YAML](#anchors) avec [script](_index.md#script), [`before_script`](_index.md#before_script) et [`after_script`](_index.md#after_script) pour utiliser des commandes prédéfinies dans plusieurs jobs :

```yaml
.some-script-before: &some-script-before
  - echo "Execute this script first"

.some-script: &some-script
  - echo "Execute this script second"
  - echo "Execute this script too"

.some-script-after: &some-script-after
  - echo "Execute this script last"

job1:
  before_script:
    - *some-script-before
  script:
    - *some-script
    - echo "Execute something, for this job only"
  after_script:
    - *some-script-after

job2:
  script:
    - *some-script-before
    - *some-script
    - echo "Execute something else, for this job only"
    - *some-script-after
```

## Utiliser `extends` pour réutiliser des sections de configuration {#use-extends-to-reuse-configuration-sections}

Vous pouvez utiliser le [mot-clé `extends`](_index.md#extends) pour réutiliser la configuration dans plusieurs jobs. Il est similaire aux [ancres YAML](#anchors), mais plus simple et vous pouvez [utiliser `extends` avec `includes`](#use-extends-and-include-together).

`extends` prend en charge l'héritage à plusieurs niveaux. Évitez d'utiliser plus de trois niveaux en raison de la complexité supplémentaire, mais vous pouvez en utiliser jusqu'à onze. L'exemple suivant comporte deux niveaux d'héritage :

```yaml
.tests:
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"

.rspec:
  extends: .tests
  script: rake rspec

rspec 1:
  variables:
    RSPEC_SUITE: '1'
  extends: .rspec

rspec 2:
  variables:
    RSPEC_SUITE: '2'
  extends: .rspec

spinach:
  extends: .tests
  script: rake spinach
```

### Exclure une clé de `extends` {#exclude-a-key-from-extends}

Pour exclure une clé du contenu étendu, vous devez lui affecter la valeur `null`, par exemple :

```yaml
.base:
  script: test
  variables:
    VAR1: base var 1

test1:
  extends: .base
  variables:
    VAR1: test1 var 1
    VAR2: test2 var 2

test2:
  extends: .base
  variables:
    VAR2: test2 var 2

test3:
  extends: .base
  variables: {}

test4:
  extends: .base
  variables: null
```

Configuration fusionnée :

```yaml
test1:
  script: test
  variables:
    VAR1: test1 var 1
    VAR2: test2 var 2

test2:
  script: test
  variables:
    VAR1: base var 1
    VAR2: test2 var 2

test3:
  script: test
  variables:
    VAR1: base var 1

test4:
  script: test
  variables: null
```

### Utiliser `extends` et `include` ensemble {#use-extends-and-include-together}

Pour réutiliser la configuration de différents fichiers de configuration, combinez `extends` et [`include`](_index.md#include).

Dans l'exemple suivant, un `script` est défini dans le fichier `included.yml`. Ensuite, dans le fichier `.gitlab-ci.yml`, `extends` fait référence au contenu du `script` :

- `included.yml` : 

  ```yaml
  .template:
    script:
      - echo Hello!
  ```

- `.gitlab-ci.yml` : 

  ```yaml
  include: included.yml

  useTemplate:
    image: alpine
    extends: .template
  ```

### Détails de la fusion {#merge-details}

Vous pouvez utiliser `extends` pour fusionner des tables, mais pas des tableaux. En cas de clés dupliquées, GitLab effectue une fusion profonde inverse basée sur les clés. Les clés du dernier membre remplacent toujours tout ce qui est défini aux autres niveaux. Par exemple :

```yaml
.only-important:
  variables:
    URL: "http://my-url.internal"
    IMPORTANT_VAR: "the details"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_BRANCH == "stable"
  tags:
    - production
  script:
    - echo "Hello world!"

.in-docker:
  variables:
    URL: "http://docker-url.internal"
  tags:
    - docker
  image: alpine

rspec:
  variables:
    GITLAB: "is-awesome"
  extends:
    - .only-important
    - .in-docker
  script:
    - rake rspec
```

Le résultat est ce job `rspec` :

```yaml
rspec:
  variables:
    URL: "http://docker-url.internal"
    IMPORTANT_VAR: "the details"
    GITLAB: "is-awesome"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_BRANCH == "stable"
  tags:
    - docker
  image: alpine
  script:
    - rake rspec
```

Dans cet exemple :

- Les sections `variables` fusionnent, mais `URL: "http://docker-url.internal"` remplace `URL: "http://my-url.internal"`.
- `tags: ['docker']` remplace `tags: ['production']`.
- `script` ne fusionne pas, mais `script: ['rake rspec']` remplace `script: ['echo "Hello world!"']`. Vous pouvez utiliser les [ancres YAML](yaml_optimization.md#anchors) pour fusionner des tableaux.

## Tags `!reference` {#reference-tags}

Utilisez le tag YAML personnalisé `!reference` pour sélectionner la configuration de mots-clés dans d'autres sections de job et la réutiliser dans la section courante. Contrairement aux [ancres YAML](#anchors), vous pouvez utiliser les tags `!reference` pour réutiliser la configuration de fichiers de configuration [inclus](_index.md#include) également.

Si vous utilisez des tags `!reference` pour remplacer la configuration de fichiers inclus, envisagez d'utiliser des [entrées CI/CD](../inputs/_index.md) à la place. Vous ne pouvez pas utiliser des entrées CI/CD dans les tags `!reference`, car les tags `!reference` sont évalués avant l'interpolation des entrées.

Dans l'exemple suivant, un `script` et un `after_script` provenant de deux emplacements différents sont réutilisés dans le job `test` :

- `configs.yml` : 

  ```yaml
  .setup:
    script:
      - echo creating environment
  ```

- `.gitlab-ci.yml` : 

  ```yaml
  include:
    - local: configs.yml

  .teardown:
    after_script:
      - echo deleting environment

  test:
    script:
      - !reference [.setup, script]
      - echo running my own command
    after_script:
      - !reference [.teardown, after_script]
  ```

Dans l'exemple suivant, `test-vars-1` réutilise toutes les variables de `.vars`, tandis que `test-vars-2` sélectionne une variable spécifique et la réutilise en tant que nouvelle variable `MY_VAR`.

```yaml
.vars:
  variables:
    URL: "http://my-url.internal"
    IMPORTANT_VAR: "the details"

test-vars-1:
  variables: !reference [.vars, variables]
  script:
    - printenv

test-vars-2:
  variables:
    MY_VAR: !reference [.vars, variables, IMPORTANT_VAR]
  script:
    - printenv
```

Vous pouvez utiliser plusieurs tags `!reference` pour construire un tableau avec `rules`, `script` ou des étapes. Par exemple :

```yaml
.rules_prod:
  - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  - if: $CI_PIPELINE_SOURCE == "schedule"

.rules_staging:
  - if: $CI_COMMIT_BRANCH =~ /^wip-.*/
  - if: $CI_PIPELINE_SOURCE == "push"

deploy_job:
  script: echo test
  rules:
    - !reference [.rules_prod]
    - !reference [.rules_staging]
```

Avec tous les autres mots-clés, vous obtenez une [erreur de validation `config should be an array of`](../debugging.md#config-should-be-an-array-of-hashes-error-message).

### Imbriquer des tags `!reference` dans `script`, `before_script` et `after_script` {#nest-reference-tags-in-script-before_script-and-after_script}

Vous pouvez imbriquer des tags `!reference` jusqu'à 10 niveaux de profondeur dans les sections `script`, `before_script` et `after_script`. Utilisez des tags imbriqués pour définir des sections réutilisables lors de la construction de scripts plus complexes. Par exemple :

```yaml
.snippets:
  one:
    - echo "ONE!"
  two:
    - !reference [.snippets, one]
    - echo "TWO!"
  three:
    - !reference [.snippets, two]
    - echo "THREE!"

nested-references:
  script:
    - !reference [.snippets, three]
```

Dans cet exemple, le job `nested-references` exécute les trois commandes `echo`.

### Configurer votre IDE pour prendre en charge les tags `!reference` {#configure-your-ide-to-support-reference-tags}

L'[éditeur de pipeline](../pipeline_editor/_index.md) prend en charge les tags `!reference`. Cependant, les règles de schéma pour les tags YAML personnalisés comme `!reference` peuvent être considérées comme non valides par votre éditeur par défaut. Vous pouvez configurer certains éditeurs pour accepter les tags `!reference`. Par exemple :

- Dans VS Code, vous pouvez configurer `vscode-yaml` pour analyser `customTags` dans votre fichier `settings.json` :

  ```json
  "yaml.customTags": [
     "!reference sequence"
  ]
  ```

- Dans Sublime Text, si vous utilisez le package `LSP-yaml`, vous pouvez définir `customTags` dans vos paramètres utilisateur `LSP-yaml` :

  ```json
  {
    "settings": {
      "yaml.customTags": ["!reference sequence"]
    }
  }
  ```
