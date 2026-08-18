---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Expressions CI/CD
---

Les expressions CI/CD permettent une configuration dynamique dans vos pipelines CI/CD en référençant des variables et des entrées CI/CD dans des contextes spécialisés. GitLab évalue les expressions dans la configuration du pipeline avant la création du pipeline.

## Expressions de configuration {#configuration-expressions}

Les expressions de configuration utilisent la syntaxe `$[[ ]]` et sont évaluées au moment de la création du pipeline (au moment de la compilation). Elles permettent une configuration dynamique basée sur différents contextes.

Toutes les expressions de configuration partagent ces caractéristiques :

- **Compile-time evaluation** : Les valeurs sont résolues lors de la création de la configuration du pipeline, et non pendant l'exécution du job. Un grand nombre d'expressions peut augmenter le temps de création du pipeline, mais n'affecte pas le temps d'exécution du job.
- **Static resolution** : Ne peut pas exécuter de logique dynamique ni accéder à l'état du job au moment de l'exécution.

Les expressions de configuration prennent en charge différents contextes pour accéder aux valeurs :

| Contexte                                 | Syntaxe                        | Disponibilité       | Objectif |
|-----------------------------------------|-------------------------------|--------------------|---------|
| [Contexte des entrées](#inputs-context)       | `$[[ inputs.INPUT_NAME ]]`    | GitLab 17.0        | Référencer les entrées CI/CD dans les configurations réutilisables. |
| [Contexte matrix](#matrix-context)       | `$[[ matrix.IDENTIFIER ]]`    | GitLab 18.6 (Beta) | Référencer les identifiants `parallel:matrix` dans les dépendances de job. |
| [Contexte component](#component-context) | `$[[ component.FIELD_NAME ]]` | GitLab 18.6 (Beta) | Référencer les métadonnées de composant dans les modèles de composant. |

### Contexte des entrées {#inputs-context}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/391331) dans GitLab 15.11 en tant que fonctionnalité bêta.
- [En disponibilité générale](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/134062) dans GitLab 17.0.

{{< /history >}}

Utilisez le contexte `inputs.` pour référencer les [entrées CI/CD](../inputs/_index.md) dans les configurations réutilisables à l'aide de la syntaxe `$[[ inputs.INPUT_NAME ]]`.

Par exemple :

```yaml
spec:
  inputs:
    environment:
      default: production
    job-stage:
      default: test
---
scan-website:
  stage: $[[ inputs.job-stage ]]
  script: ./scan-website $[[ inputs.environment ]]
```

Les expressions `input.` présentent les caractéristiques suivantes :

- Validation de type : Prend en charge les types `string`, `number`, `boolean` et `array` avec validation. La validation des entrées empêche la création du pipeline avec des valeurs non valides.
- Prise en charge des fonctions : Les fonctions prédéfinies telles que `expand_vars` et `truncate` permettent de manipuler les valeurs.
- Portée : Disponible dans le fichier où elle est définie, ou transmise explicitement avec `include:inputs`.

### Contexte matrix {#matrix-context}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/423553) dans GitLab 18.6. Cette fonctionnalité est en [bêta](../../policy/development_stages_support.md#beta).

{{< /history >}}

Utilisez le [contexte `matrix.`](matrix_expressions.md) pour référencer les valeurs [`parallel:matrix`](_index.md#parallelmatrix) à l'aide d'une syntaxe `$[[ matrix.IDENTIFIER ]]`. Utilisez-le dans les dépendances de job pour activer des mappages dynamiques 1:1 entre les jobs `parallel:matrix`.

Par exemple :

```yaml
.os-arch-matrix:
  parallel:
    matrix:
      - OS: [ubuntu, alpine]
        ARCH: [amd64, arm64]

build:
  script: echo "Testing $OS on $ARCH"
  parallel: !reference [.os-arch-matrix, parallel]

test:
  script: echo "Testing $OS on $ARCH"
  parallel: !reference [.os-arch-matrix, parallel]
  needs:
    - job: build
      parallel:
        matrix:
          - OS: ['$[[ matrix.OS ]]']
            ARCH: ['$[[ matrix.ARCH ]]']
```

Les expressions `matrix.` présentent les caractéristiques suivantes :

- Portée limitée à `parallel:matrix` au niveau du job : Seules les valeurs du job en cours peuvent être référencées.
- Mappage automatique : Crée des dépendances 1:1 entre les jobs matrix entre les étapes

### Contexte component {#component-context}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/438275) dans GitLab 18.6 en tant que [bêta](../../policy/development_stages_support.md#beta) [avec un flag](../../administration/feature_flags/_index.md) nommé `ci_component_context_interpolation`. Activé par défaut.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/571986) dans GitLab 18.7. L'indicateur de fonctionnalité `ci_component_context_interpolation` a été supprimé.

{{< /history >}}

Utilisez le contexte `component.` pour référencer les métadonnées du [composant CI/CD](../components/_index.md) dans les modèles de composant à l'aide de la syntaxe `$[[ component.FIELD_NAME ]]`.

Le contexte component fournit des métadonnées sur le composant lui-même, telles que son nom, sa version et le SHA du commit. Cela permet aux modèles de composant de référencer dynamiquement leurs propres métadonnées.

Pour utiliser le contexte component, déclarez les champs nécessaires dans l'en-tête [`spec:component`](_index.md#speccomponent), puis référencez-les dans le modèle de composant.

Par exemple :

```yaml
spec:
  component: [name, version]
  inputs:
    stage:
      default: build
---

build-job:
  stage: $[[ inputs.stage ]]
  image: registry.example.com/$[[ component.name ]]:$[[ component.version ]]
  script:
    - echo "Building with component version $[[ component.version ]]"
```

## Sujets connexes {#related-topics}

- [Langage d'expression Moa](../functions/moa.md)
- [Entrées CI/CD](../inputs/_index.md)
- [Composants CI/CD](../components/_index.md)
- [Expressions matrix](matrix_expressions.md)
- [Optimisation YAML](yaml_optimization.md)
