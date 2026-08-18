---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Langage d'expression Moa"
---

Moa est un langage d'expression permettant de construire dynamiquement des valeurs lors de l'exécution d'un job. Les expressions sont délimitées par `${{ }}` et sont utilisées dans les GitLab Functions et les entrées de job.

Moa prend en charge la manipulation de chaînes, l'arithmétique, les comparaisons, les opérations logiques, l'accès aux propriétés et les appels de fonctions.

## Différences par rapport aux expressions CI/CD {#differences-from-cicd-expressions}

GitLab dispose de trois syntaxes d'expression qui servent des objectifs différents à différentes étapes du cycle de vie du pipeline.

- [Rules](../yaml/_index.md#rules) utilisent leur propre syntaxe d'expression dans les mots-clés `rules:` pour contrôler l'inclusion des jobs. Elles sont évaluées lors de la création du pipeline et prennent en charge les comparaisons et la correspondance de motifs avec les variables CI/CD, mais ne peuvent pas effectuer d'arithmétique ni accéder à l'état d'exécution.
- Les expressions CI/CD utilisent la syntaxe `$[[ ]]` et sont évaluées lors de la création du pipeline, avant l'exécution des jobs. Ces expressions effectuent la substitution de valeurs pour les [entrées CI/CD](../inputs/_index.md), les [valeurs de matrice](../yaml/matrix_expressions.md) et les [entrées de composant](../components/_index.md). Elles ne peuvent pas effectuer d'arithmétique, de comparaisons ou de logique, et n'ont pas accès à l'état d'exécution. Pour plus d'informations, consultez [les expressions CI/CD](../yaml/expressions.md).
- Moa utilise la syntaxe `${{ }}` et est évalué lors de l'exécution du job par le runner. Moa est un langage d'expression complet avec des opérateurs, des structures de données et des appels de fonctions.

Les trois syntaxes peuvent coexister dans le même pipeline. Un composant CI/CD contenant des GitLab Functions peut utiliser les trois :

```yaml
spec:
  inputs:
    echo_version:
      type: string
---

hi-job:
  # rules expression - evaluated when the pipeline is created
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  run:
    - name: say_hi
      # $[[ ]] - resolved when the pipeline is created
      step: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo@$[[ inputs.echo_version ]]
      inputs:
        # ${{ }} - resolved when the job runs
        message: "Hello, ${{ vars.CI_PROJECT_NAME }}"
```

Moa existe en tant que langage distinct car les GitLab Functions ont besoin de capacités non disponibles lors de la création du pipeline :

- Évaluation à l'exécution : Les sorties de step n'existent pas tant que la fonction n'a pas été exécutée. Les expressions telles que `${{ steps.build.outputs.image_ref }}` ne peuvent être évaluées que lors de l'exécution.
- Valeurs typées : Moa préserve les types natifs (nombres, booléens, tableaux et objets) et les transmet entre les fonctions sans les convertir en chaîne.
- Opérateurs et logique : Les GitLab Functions ont besoin de l'arithmétique (`major_version + 1`), des comparaisons (`vulnerabilities == 0`) et de la logique en court-circuit (`inputs.tag || "latest"`) pour construire les entrées de step à partir de variables et de sorties.
- Suivi des valeurs sensibles : Moa propage les valeurs sensibles à travers les opérations. Si vous concaténez une valeur sensible dans une chaîne ou la transmettez via un appel de fonction, le résultat est également traité comme sensible. Cela empêche la divulgation accidentelle de secrets dans les journaux et les sorties.

## Référence de contexte {#context-reference}

Les valeurs disponibles dans les expressions dépendent de l'endroit où l'expression est utilisée.

| Contexte       | Disponible dans                                                                                             | Type   | Évalué                        | Description                                                                                                                             |
|---------------|----------------------------------------------------------------------------------------------------------|--------|----------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| `job.inputs`  | Configuration du job : `script`, `before_script`, `after_script`, `artifacts`, `cache`, `image`, `services`  | Objet | Lorsque le Runner reçoit le job | Valeurs d'entrée définies pour le job. Accédez aux variables individuelles avec `job.inputs.<name>`.                                                 |
| `env`         | GitLab Functions                                                                                         | Objet | Avant l'exécution de la fonction         | Variables d'environnement disponibles pour la fonction. Accédez aux variables individuelles avec `env.<name>`.                                         |
| `inputs`      | GitLab Functions                                                                                         | Objet | Avant l'exécution de la fonction         | Valeurs d'entrée transmises à la fonction. Accédez aux entrées individuelles avec `inputs.<name>`.                                                     |
| `vars`        | GitLab Functions                                                                                         | Objet | Avant l'exécution de la fonction         | Variables du job transmises depuis le job CI. Accédez aux variables individuelles avec `vars.<name>`.                                                   |
| `steps`       | GitLab Functions                                                                                         | Objet | Avant l'exécution de la fonction         | Résultats des steps précédemment exécutés dans la fonction actuelle. Accédez aux sorties d'un step avec `steps.<step_name>.outputs.<output_name>`. |
| `export_file` | GitLab Functions                                                                                         | Chaîne | Avant l'exécution de la fonction         | Chemin vers le fichier dans lequel la fonction peut écrire des variables d'environnement à exporter vers les steps suivants.                                      |
| `output_file` | GitLab Functions                                                                                         | Chaîne | Avant l'exécution de la fonction         | Chemin vers le fichier dans lequel la fonction écrit ses valeurs de sortie.                                                                           |
| `func_dir`    | GitLab Functions                                                                                         | Chaîne | Avant l'exécution de la fonction         | Chemin vers le répertoire contenant le fichier de définition de la fonction. À utiliser pour référencer des fichiers intégrés à la fonction.                      |
| `work_dir`    | GitLab Functions                                                                                         | Chaîne | Avant l'exécution de la fonction         | Chemin vers le répertoire de travail pour l'exécution en cours.                                                                                |

## Syntaxe de template {#template-syntax}

### Interpolation {#interpolation}

Placez les expressions dans `${{ }}` pour les évaluer :

```yaml
script:
  - echo "Hello, ${{ job.inputs.name }}"
```

Lorsque du texte entoure l'expression, le résultat est toujours converti en chaîne. Plusieurs expressions peuvent apparaître dans une seule valeur :

```yaml
script:
  - echo "${{ job.inputs.greeting }}, ${{ job.inputs.name }}!"
```

### Passage de type natif {#native-type-passthrough}

Lorsque `${{ expression }}` constitue la valeur entière sans texte environnant, l'expression renvoie son type natif. Utilisez des expressions de type natif pour transmettre des valeurs non-chaînes telles que des nombres, des booléens, des tableaux et des objets entre les steps sans les convertir en chaînes.

```yaml
inputs:
  count: ${{ steps.previous.outputs.total }}
```

Dans cet exemple, si `total` est un nombre, `count` reçoit un nombre, et non la représentation sous forme de chaîne.

### Échapper les expressions Moa {#escape-moa-expressions}

Pour inclure un littéral `${{` dans votre texte sans déclencher l'interpolation, faites-le précéder d'une barre oblique inverse :

```yaml
script:
  - echo "Use \${{ to start an expression"
```

Cette commande affiche le texte `Use ${{ to start an expression` sans évaluation.

## Littéraux {#literals}

### Null {#null}

Le mot-clé `null` représente l'absence de valeur.

```yaml
${{ null }}
```

### Booléens {#booleans}

Les mots-clés `true` et `false` représentent des valeurs booléennes.

```yaml
${{ true }}
${{ false }}
```

### Nombres {#numbers}

Les nombres sont des valeurs en virgule flottante double précision IEEE 754 avec 53 bits de précision de mantisse. Les entiers, les décimaux et la notation scientifique sont pris en charge.

```yaml
${{ 42 }}
${{ 3.14 }}
${{ 1.5e3 }}
${{ 2E-4 }}
```

### Chaînes {#strings}

Placez les chaînes entre guillemets doubles ou guillemets simples. Les deux types de guillemets gèrent différemment les séquences d'échappement et les expressions de template.

Les chaînes entre guillemets doubles prennent en charge les expressions de template et un ensemble complet de séquences d'échappement :

| Séquence  | Signification                                 |
|-----------|-----------------------------------------|
| `\\`      | Barre oblique inverse                               |
| `\"`      | Guillemet double                            |
| `\n`      | Nouvelle ligne                                 |
| `\r`      | Retour chariot                         |
| `\t`      | Tabulation                                     |
| `\a`      | Alerte (sonnerie)                            |
| `\b`      | Retour arrière                               |
| `\f`      | Saut de page                               |
| `\v`      | Tabulation verticale                            |
| `\/`      | Barre oblique                           |
| `\uXXXX`  | Point de code Unicode                      |
| `\${{`    | Littéral `${{` (empêche l'interpolation)  |

Les expressions de template (`${{ }}`) à l'intérieur des chaînes entre guillemets doubles sont évaluées et interpolées dans la chaîne.

Les chaînes entre guillemets simples sont des littéraux de chaîne bruts avec une interprétation minimale. Les expressions de template à l'intérieur des chaînes entre guillemets simples ne sont pas évaluées. Seules deux séquences d'échappement sont prises en charge :

| Séquence | Signification      |
|----------|--------------|
| `\\`     | Barre oblique inverse    |
| `\'`     | Guillemet simple |

```yaml
${{ "Hello\nWorld" }}
${{ 'It\'s a string' }}
${{ 'Literal ${{ not evaluated }}' }}
```

## Identifiants {#identifiers}

Les identifiants font référence à des valeurs du contexte d'expression. Un identifiant commence par une lettre ou un trait de soulignement et peut contenir des lettres, des chiffres et des traits de soulignement. Les identifiants sont sensibles à la casse : `foo`, `Foo` et `FOO` sont trois identifiants différents.

```yaml
${{ env }}
${{ my_variable }}
```

Les identifiants sont résolus par rapport au contexte disponible. Pour les valeurs disponibles dans chaque contexte, consultez [la référence de contexte](#context-reference).

Lorsqu'un identifiant fait référence à un objet de contexte, l'objet entier est renvoyé. Par exemple, `${{ vars }}` renvoie toutes les variables du job sous forme d'objet.

## Opérateurs {#operators}

### Opérateurs arithmétiques {#arithmetic-operators}

Les opérateurs arithmétiques fonctionnent sur des nombres. L'opérateur `+` concatène également des chaînes. Les opérateurs n'effectuent pas de conversion de type implicite, donc `"hello" + 42` génère une erreur.

| Opérateur | Description                 | Exemple             | Résultat     |
|----------|-----------------------------|---------------------|------------|
| `+`      | Addition                    | `${{ 2 + 3 }}`      | `5`        |
| `+`      | Concaténation               | `${{ "a" + "b" }}`  | `"ab"`     |
| `-`      | Soustraction                 | `${{ 10 - 4 }}`     | `6`        |
| `*`      | Multiplication              | `${{ 3 * 4 }}`      | `12`       |
| `/`      | Division                    | `${{ 10 / 3 }}`     | `3.333...` |
| `%`      | Modulo (division tronquée) | `${{ 10 % 3 }}`     | `1`        |

La division par zéro génère une erreur.

### Opérateurs de comparaison {#comparison-operators}

Les opérateurs de comparaison renvoient une valeur booléenne.

| Opérateur | Description           | Exemple            | Résultat  |
|----------|-----------------------|--------------------|---------|
| `==`     | Égal                 | `${{ 1 == 1 }}`    | `true`  |
| `!=`     | Différent             | `${{ 1 != 2 }}`    | `true`  |
| `<`      | Inférieur à             | `${{ 1 < 2 }}`     | `true`  |
| `<=`     | Inférieur ou égal à    | `${{ 2 <= 2 }}`    | `true`  |
| `>`      | Supérieur à          | `${{ 3 > 2 }}`     | `true`  |
| `>=`     | Supérieur ou égal à | `${{ 3 >= 3 }}`    | `true`  |

Les valeurs de types différents sont comparées par type, donc `1 == "1"` est évalué à `false`. Les valeurs du même type suivent ces règles de comparaison :

- Nombres : Comparaison numérique.
- Chaînes : Comparaison lexicographique (ordre des octets UTF-8).
- Booléens : `false` est inférieur à `true`.
- Tableaux : Comparaison élément par élément.
- Objets : Comparés par longueur, puis par clés, puis par valeurs. L'ordre des clés n'a pas d'importance.
- Null : `null` est égal à `null`.

### Opérateurs logiques {#logical-operators}

Les opérateurs logiques utilisent l'évaluation en court-circuit et renvoient l'un de leurs opérandes, pas nécessairement un booléen. Ce comportement est similaire aux opérateurs JavaScript `&&` et `||`.

| Opérateur   | Description | Comportement                                                                                      |
|------------|-------------|-----------------------------------------------------------------------------------------------|
| `\|\|`     | OU logique  | Renvoie l'opérande gauche s'il est vrai (truthy), sinon évalue et renvoie l'opérande droit.  |
| `&&`       | ET logique | Renvoie l'opérande gauche s'il est faux (falsy), sinon évalue et renvoie l'opérande droit.   |
| `!`        | NON logique | Renvoie `true` si l'opérande est faux (falsy), `false` s'il est vrai (truthy).                                    |

L'opérateur `||` est utilisé pour fournir des valeurs par défaut :

```yaml
${{ inputs.name || "default" }}
```

Si `inputs.name` est une chaîne non vide, elle est renvoyée telle quelle. Si elle est vide ou nulle, `"default"` est renvoyée.

### Opérateurs unaires {#unary-operators}

| Opérateur | Description    | Exemple          | Résultat  |
|----------|----------------|------------------|---------|
| `+`      | Plus unaire     | `${{ +5 }}`      | `5`     |
| `-`      | Négation unaire | `${{ -5 }}`      | `-5`    |
| `!`      | NON logique    | `${{ !true }}`   | `false` |

### Priorité des opérateurs {#operator-precedence}

Les opérateurs sont répertoriés de la priorité la plus haute à la plus basse. Les opérateurs sur la même ligne ont une priorité égale. Tous les opérateurs binaires sont associatifs à gauche.

| Priorité  | Opérateurs                        |
|-------------|----------------------------------|
| 7 (la plus haute) | `.`, `[]`, `()`                  |
| 6           | `+`, `-`, `!`                    |
| 5           | `*`, `/`, `%`                    |
| 4           | `+`, `-`                         |
| 3           | `==`, `!=`, `<`, `<=`, `>`, `>=` |
| 2           | `&&`                             |
| 1 (la plus basse)  | `\|\|`                           |

Utilisez des parenthèses pour remplacer la priorité :

```yaml
${{ (1 + 2) * 3 }}
```

## Structures de données {#data-structures}

### Tableaux {#arrays}

Créez des tableaux avec la notation entre crochets. Les éléments peuvent être de n'importe quel type et vous pouvez mélanger les types. Vous pouvez utiliser des virgules finales.

```yaml
${{ [1, 2, 3] }}
${{ ["a", 1, true, null] }}
${{ [] }}
```

### Objets {#objects}

Créez des objets avec la notation entre accolades. Les clés doivent être évaluées en chaînes. Les valeurs peuvent être de n'importe quel type. Les virgules finales sont autorisées.

```yaml
${{ {name: "runner", version: 1} }}
${{ {"string-key": true} }}
${{ {} }}
```

Les identifiants nus utilisés comme clés d'objet sont traités comme des littéraux de chaîne, et non comme des références à des variables. Pour utiliser une variable comme clé, placez-la entre parenthèses :

```yaml
${{ {name: "Alice"} }}           # "name" is the string "name", not a variable reference
${{ {(obj.prop): "value"} }}     # key is the value of obj.prop, which must be a string
```

## Accès aux propriétés {#property-access}

### Notation par point {#dot-notation}

Accédez aux propriétés d'un objet avec la notation par point :

```yaml
${{ env.HOME }}
${{ steps.build.outputs.artifact_path }}
```

### Notation par crochets {#bracket-notation}

Accédez aux éléments d'un tableau par index, ou aux propriétés d'un objet par clé de chaîne :

```yaml
${{ my_array[0] }}
${{ my_object["property-name"] }}
```

La notation par crochets est requise lorsqu'un nom de propriété contient des caractères spéciaux tels que des traits d'union.

### Chaînage {#chaining}

Chaînez les accès aux propriétés et les appels de fonctions :

```yaml
${{ steps.build.outputs.items[0] }}
```

## Appels de fonctions {#function-calls}

Appelez les fonctions par nom avec des parenthèses :

```yaml
${{ str(42) }}
${{ num("3.14") }}
```

## Véracité {#truthiness}

Les opérateurs logiques et l'opérateur `!` utilisent les règles de véracité suivantes :

| Type    | Vrai (truthy) quand             | Faux (falsy) quand        |
|---------|-------------------------|-------------------|
| Booléen | `true`                  | `false`           |
| Chaîne  | Longueur supérieure à `0` | Chaîne vide `""` |
| Nombre  | Différent de `0`                 | `0`               |
| Tableau   | Longueur supérieure à `0` | Tableau vide `[]`  |
| Objet  | Longueur supérieure à `0` | Objet vide `{}` |
| Null    | Jamais                   | Toujours            |

## Fonctions intégrées {#built-in-functions}

### `str(value)` {#strvalue}

Convertit n'importe quelle valeur en sa représentation sous forme de chaîne.

```yaml
${{ str(42) }}       # "42"
${{ str(true) }}     # "true"
${{ str(null) }}     # "<null>"
```

### `num(value)` {#numvalue}

Convertit une chaîne en nombre. La chaîne doit être une représentation numérique valide.

```yaml
${{ num("42") }}     # 42
${{ num("3.14") }}   # 3.14
```

### `bool(value)` {#boolvalue}

Convertit n'importe quelle valeur en booléen en fonction de sa [véracité](#truthiness).

```yaml
${{ bool("hello") }}  # true
${{ bool("") }}       # false
${{ bool(0) }}        # false
${{ bool(1) }}        # true
```

## Mots réservés {#reserved-words}

Les mots suivants sont réservés et ne peuvent pas être utilisés comme identifiants. Ils sont réservés pour de potentielles fonctionnalités futures du langage.

`array`, `as`, `break`, `case`, `const`, `continue`, `default`, `else`, `fallthrough`, `float`, `for`, `func`, `function`, `goto`, `if`, `import`, `in`, `int`, `let`, `loop`, `map`, `namespace`, `number`, `object`, `package`, `range`, `return`, `string`, `struct`, `switch`, `type`, `var`, `void`, `while`

Les mots-clés `null`, `true` et `false` sont également réservés en tant que valeurs littérales.

## Exemples {#examples}

### Déploiement avec sélection de stratégie {#deploy-with-strategy-selection}

```yaml
deploy job:
  when: manual
  inputs:
    environment:
      default: staging
      options: [staging, production]
      description: Target deployment environment
    strategy:
      default: rolling
      options: [rolling, blue-green, canary]
      description: Deployment strategy
    replicas:
      type: number
      default: 3
      description: Number of replicas to deploy
  image: ${{ job.inputs.environment == "production" && "deploy-tools:stable" || "deploy-tools:latest" }}
  script:
    - 'echo "Deploying to ${{ job.inputs.environment }} using ${{ job.inputs.strategy }}"'
    - deploy
        --env ${{ job.inputs.environment }}
        --strategy ${{ job.inputs.strategy }}
        --replicas ${{ str(job.inputs.replicas) }}
```

### Indicateurs conditionnels depuis les entrées booléennes de job {#conditional-flags-from-boolean-job-inputs}

```yaml
test_job:
  inputs:
    coverage:
      type: boolean
      default: false
    verbose:
      type: boolean
      default: false
  script:
    - pytest ${{ job.inputs.verbose && "-v" || "" }} ${{ job.inputs.coverage && "--cov=src" || "" }}
```

### Création d'une référence d'image à partir de variables de job {#building-an-image-reference-from-job-variables}

```yaml
build_job:
  run:
    - name: build
      func: ./docker-build
      inputs:
        image: ${{ vars.CI_REGISTRY + "/" + vars.CI_PROJECT_PATH + ":" + vars.CI_PIPELINE_IID }}
```

### Porte de continuation {#continue-gate}

```yaml
security_scan_job:
  run:
    - name: scan
      func: ./security-scan
    - name: gate
      func: ./quality-gate
      inputs:
        should_proceed: ${{ steps.scan.outputs.critical == 0 && steps.scan.outputs.high < 5 }}
```

### Gestion des versions {#version-management}

```yaml
increment_version_job:
  run:
    - name: current
      func: ./find-version
    - name: bump
      func: ./bump-version
      inputs:
        new_version: ${{ str(steps.current.outputs.major + 1) + ".0.0" }}
```

### Configuration spécifique à l'environnement {#environment-specific-configuration}

```yaml
deploy_job:
  run:
    - name: deploy
      func: ./deploy
      inputs:
        registry: ${{ (vars.CI_COMMIT_REF_NAME == "main" && "prod.registry.com") || "staging.registry.com" }}
        replicas: ${{ (vars.CI_COMMIT_REF_NAME == "main" && 5) || 2 }}
```

### Configurer les tests A/B {#configure-ab-testing}

```yaml
configure_job:
  run:
    - name: configure_ab
      func: ./traffic-split
      inputs:
        variants: |
          ${{ [
            {name: "control", use_new_feature: false, weight: 90},
            {name: "experiment", use_new_feature: true, weight: 10}
          ] }}
```
