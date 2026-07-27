---
stage: Verify
group: CI Functions Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Functions
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Statut : Version expérimentale

{{< /details >}}

GitLab Functions fournit des unités réutilisables de logique de job CI/CD qui remplacent le `script` dans un job GitLab CI/CD.

> [!note]
> GitLab Functions est une fonctionnalité expérimentale en cours de développement, susceptible de faire l'objet de changements non rétrocompatibles. Pour plus de détails, consultez le [changelog](https://gitlab.com/gitlab-org/step-runner/-/blob/main/CHANGELOG.md).

## Pourquoi utiliser les fonctions {#why-functions}

Lorsque les pipelines s'agrandissent, les blocs `script` deviennent difficiles à maintenir. La logique est dupliquée entre les jobs, les scripts sont récupérés depuis des sources externes au moment de l'exécution, et les modifications mineures nécessitent des mises à jour à de nombreux endroits. GitLab Functions est conçu pour résoudre ces problèmes.

Les avantages des fonctions incluent :

- Les fonctions sont autonomes et versionnées. Une fonction est une image OCI qui regroupe la logique, les scripts ou binaires de support, ainsi qu'une spécification décrivant ses entrées et sorties. Lorsqu'une étape s'exécute, GitLab récupère automatiquement la fonction. Vous n'avez pas besoin de récupérer des scripts au début d'un job ni de gérer manuellement les dépendances externes. Lorsque vous référencez une fonction avec un tag de version spécifique, vous obtenez exactement cette version à chaque fois.

- Les fonctions sont réutilisables entre les jobs et les projets. Après avoir publié une fonction dans un registre OCI, n'importe quel job peut l'utiliser avec une seule référence `func`, sans avoir à copier ni à maintenir des fichiers de script dans chaque dépôt.

- Les fonctions rendent le flux de données explicite. Dans un bloc `script`, les valeurs sont transmises entre les commandes via des variables shell, que vous pouvez définir, écraser ou lire dans n'importe quel ordre. Dans une liste `run`, chaque étape déclare ses entrées et sorties, et une étape ne peut accéder qu'aux sorties des étapes déjà exécutées.

- Les fonctions peuvent être testées indépendamment. Comme une fonction définit ses entrées et sorties, vous pouvez l'exécuter et la tester de manière isolée, sans exécuter l'ensemble du pipeline.

- L'exécution des fonctions est fiable sur toutes les plateformes. Un agent dédié gère l'exécution des fonctions sur l'hôte de build plutôt que d'interpréter un script envoyé via le réseau. Cela confère aux fonctions un contrôle de processus approprié, une cohérence multiplateforme et les bases pour des jobs reprennables. Ces capacités sont difficiles, voire impossibles à atteindre avec des scripts shell seuls.

Pour réutiliser des scripts shell existants, utilisez l'étape `script` pour les exécuter directement dans une liste `run` pendant que vous migrez progressivement. Vous pouvez utiliser des fonctions sans tout convertir en une seule fois.

## Comprendre les fonctions {#understand-functions}

Dans un job CI/CD traditionnel, le mot-clé `script` contient une liste de commandes shell. Le job possède chaque étape et la logique réside directement dans le YAML, qui décrit précisément comment atteindre un résultat. Lorsque les pipelines s'agrandissent, cette approche devient difficile à réutiliser, tester ou partager entre les projets.

Avec GitLab Functions, vous utilisez le mot-clé `run` pour déclarer une liste d'étapes. Chaque étape référence une fonction qui contient l'implémentation, et le job décrit ce qui doit se passer plutôt que comment. La logique existe dans les fonctions, pas dans le YAML.

Voici un exemple de `.gitlab-ci.yml` traditionnel pour un projet JavaScript :

```yaml
build_and_release:
  script:
    - npm run lint
    - npm test
    - npm run bundle
    - BUNDLE_PATH=$(find dist -name '*.js' | head -1)
    - npm run minify -- --input $BUNDLE_PATH
    - npm run deploy -- --artifact $MINIFIED_PATH --env production
```

Le même pipeline écrit avec GitLab Functions :

```yaml
build_and_release:
  run:
    - name: validate
      func: registry.gitlab.com/js/validate:1.0.0
    - name: release
      func: registry.gitlab.com/js/release:1.0.0
      inputs:
        environment: production
```

Chaque job déclare ce qui doit se passer via des étapes. Les fonctions elles-mêmes contiennent l'implémentation.

## Glossaire GitLab Functions {#gitlab-functions-glossary}

Ce glossaire fournit des définitions pour les termes liés à GitLab Functions.

Fonction : Un package réutilisable et autonome de logique CI/CD. Une fonction contient du code compilé spécifique à la plateforme, une spécification qui définit ses entrées et sorties, ainsi qu'une définition décrivant ce que fait la fonction. La fonction peut exécuter une commande ou composer d'autres fonctions.

Étape : Une invocation unique d'une fonction dans une liste `run`. Une étape comprend un nom, la référence de la fonction, toutes les entrées fournies et toutes les variables d'environnement définies pour cette invocation.

Entrées : Valeurs nommées que vous transmettez à une fonction lorsque vous l'invoquez en tant qu'étape. Les entrées sont déclarées dans la spécification de la fonction avec un type et une valeur par défaut facultative.

Sorties : Valeurs nommées qu'une fonction renvoie après son exécution. Les sorties sont déclarées dans la spécification de la fonction et écrites dans le fichier de sortie lors de l'exécution.

Variables d'environnement : Variables disponibles pour une fonction au moment de l'exécution. Les variables d'environnement peuvent provenir de l'environnement du processus du système d'exploitation, du runner, de la définition de la fonction, de l'invocation de l'étape, ou d'une fonction précédemment exécutée qui les a exportées.

## Renommer depuis CI/CD Steps {#rename-from-cicd-steps}

GitLab Functions s'appelait auparavant CI/CD Steps. La fonctionnalité et sa syntaxe ont été renommées.

| Ancien                                       | Nouveau                           |
|:------------------------------------------|:------------------------------|
| CI/CD Steps                               | GitLab Functions              |
| `step:` (obsolète)                      | `func:`                       |
| `step.yml` (obsolète)                   | `func.yml`                    |
| `${{ step_dir }}` (obsolète)            | `${{ func_dir }}`             |
| `${{ job.<variable_name> }}` (obsolète) | `${{ vars.<variable_name> }}` |

## Composants et fonctions {#components-and-functions}

Les composants et les fonctions opèrent à différents niveaux du pipeline et résolvent des problèmes différents.

Les [composants CI/CD](../components/_index.md) sont réutilisables au niveau du pipeline. GitLab inclut un composant avant l'exécution de tout job et contribue des jobs, des étapes et une configuration au pipeline. Les composants décrivent quels jobs existent dans un pipeline.

GitLab Functions est réutilisable au niveau du job. Elles s'exécutent à l'intérieur d'un job et remplacent le `script`.

Les composants et les fonctions opèrent à différents niveaux et se complètent bien. Un composant peut définir un job et utiliser des fonctions en interne pour l'implémenter. Lorsque vous incluez le composant, vous obtenez un job entièrement configuré sans avoir besoin de savoir comment il fonctionne. En tant qu'auteur du composant, vous utilisez des fonctions pour gérer la complexité de ce que fait le job.

### Syntaxe des expressions {#expression-syntax}

Les composants et les fonctions utilisent des syntaxes d'expression différentes car elles sont évaluées à des moments différents :

- Les expressions `$[[ ]]` sont évaluées lors de la création du pipeline, avant l'exécution de tout job. Utilisez cette syntaxe pour les [entrées CI/CD](../inputs/_index.md) et les entrées de composants.
- Les expressions `${{ }}` sont évaluées lors de l'exécution du job, juste avant l'exécution de chaque étape. Utilisez cette syntaxe pour les entrées de fonctions, les variables d'environnement et les valeurs qui dépendent de l'état d'exécution.

Les deux syntaxes peuvent apparaître dans un fichier de configuration YAML de composant CI/CD :

```yaml
spec:
  inputs:
    go_version:
      default: "1.22"
---

my-format-job:
  run:
    - name: install_go
      func: ./languages/go/install
      inputs:
        version: $[[ inputs.go_version ]]                      # resolved at pipeline creation
    - name: format
      func: ./languages/go/go-fmt
      inputs:
        go_binary: ${{ steps.install_go.outputs.go_binary }}   # resolved during job execution
```

## Modèle d'exécution des fonctions {#function-execution-model}

Les fonctions sont des packages autonomes qui peuvent accepter des entrées, retourner des sorties et exporter des variables d'environnement. Les fonctions s'exécutent dans l'environnement de votre job CI, que l'instance soit une machine hôte ou un conteneur. Vous pouvez héberger des fonctions localement sur le système de fichiers, dans des registres OCI ou dans des dépôts Git.

Chaque étape d'une liste `run` s'exécute en séquence. Les étapes communiquent entre elles via des entrées, des sorties et des variables d'environnement exportées, plutôt que via un état shell partagé.

Les sorties d'une étape sont disponibles pour les étapes suivantes via l'expression `${{ steps.<step-name>.outputs.<output-name> }}`. Les variables d'environnement exportées par une étape sont disponibles pour toutes les étapes suivantes. Les sorties et les variables d'environnement ne deviennent disponibles qu'après la fin de l'étape.

Lorsqu'un runner récupère un job avec une liste `run`, il invoque le step runner pour gérer l'exécution. Pour chaque étape de la liste, le step runner :

1. Résout la référence de la fonction et récupère le package de la fonction depuis le système de fichiers, le dépôt OCI ou le dépôt Git.
1. Évalue toutes les expressions dans les entrées et les variables d'environnement de l'étape.
1. Exécute la fonction et transmet les entrées et l'environnement résolus.
1. Lit toutes les sorties que la fonction a écrites dans le fichier de sortie et les met à disposition des étapes suivantes.
1. Lit toutes les variables d'environnement exportées par la fonction et les ajoute à l'environnement global.
1. Passe à l'étape suivante ou s'arrête si l'étape a échoué.

## Prérequis des fonctions {#function-requirements}

Pour utiliser des fonctions, vous devrez peut-être installer un step runner sur l'exécuteur de runner que vous utilisez. Pour plus d'informations, consultez [installer le step runner manuellement](https://docs.gitlab.com/runner/install/step-runner).

## Utiliser les fonctions {#use-functions}

Configurez un job GitLab CI/CD pour utiliser des fonctions avec le mot-clé `run`. Vous ne pouvez pas utiliser `before_script`, `after_script` ni `script` dans un job lorsque vous exécutez des fonctions.

### Exécuter une fonction avec une étape {#run-a-function-with-a-step}

Le mot-clé `run` accepte une liste d'étapes à exécuter. Les étapes sont exécutées une par une dans l'ordre où elles sont définies dans la liste. Chaque étape possède un `name`, soit `func` soit `script`, et optionnellement, `inputs` et `env`.

Le nom doit uniquement être composé de caractères alphanumériques et de tirets bas, et ne peut pas commencer par un chiffre.

#### Invoquer une fonction {#invoke-a-function}

Une étape peut invoquer une fonction en fournissant la [référence de la fonction](#function-reference) avec le mot-clé `func`. Transmettez les entrées à la fonction avec le mot-clé `inputs`, et remplacez les valeurs d'environnement avec le mot-clé `env`. Utilisez des [expressions](#expressions) dans la valeur `func` et dans les clés et valeurs de `inputs` et `env`.

Les fonctions s'exécutent dans le répertoire `CI_PROJECT_DIR`, sauf si la fonction invoquée remplace le répertoire de travail.

Par exemple, l'exécution de la fonction echo ci-dessous affiche le message `Hi Sally!` dans le job log.

```yaml
my-job:
  variables:
    FRIEND: "Sally"
  run:
    - name: say_hi
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo:1
      inputs:
        message: "Hi ${{ vars.FRIEND }}!"
```

#### Exécuter un script {#run-a-script}

Une étape peut invoquer un script avec le mot-clé `script`. Les variables d'environnement transmises aux scripts via `env` sont définies dans le shell. Les étapes de script utilisent le shell `bash`, avec repli sur `sh` si bash n'est pas trouvé. Les [expressions](#expressions) peuvent être utilisées dans la valeur `script` et dans les clés et valeurs de `env`. Les étapes de script s'exécutent dans le répertoire `CI_PROJECT_DIR`.

Utilisez l'étape de script lorsque vous avez besoin de quelque chose de personnalisé et de simple en parallèle des fonctions. En interne, les fonctions convertissent le script en une invocation de fonction et transmettent le script en tant qu'entrée.

Par exemple, l'étape de script suivante affiche le message `Hi Sally!` dans le job log :

```yaml
my-job:
  variables:
    FRIEND: "Sally"
  run:
    - name: say_hi
      script: echo 'Hi ${{ vars.FRIEND }}!'
```

### Référence de fonction {#function-reference}

Les fonctions sont chargées depuis le système de fichiers ou un dépôt OCI. Le chargement depuis un dépôt Git est pris en charge, mais est obsolète.

#### Charger depuis un dépôt OCI {#load-from-an-oci-repository}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/6351) dans GitLab Runner 18.9.

{{< /history >}}

Pour charger une fonction depuis un dépôt OCI, fournissez le registre, le dépôt et la version (tag). Cette méthode est la façon recommandée pour distribuer et consommer des fonctions.

Les images OCI de fonctions prennent en charge plusieurs plateformes. Le step runner télécharge l'image correspondant à la plateforme en cours d'exécution. Si aucune correspondance n'est trouvée, l'étape échoue.

```yaml
# prints 'Hi from GitLab Functions'
my-job:
  run:
    - name: echo
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo:1
      inputs:
        message: "Hi from GitLab Functions"
```

Vous pouvez également spécifier un sous-répertoire et un nom de fichier dans l'image si la fonction ne se trouve pas à la racine :

```yaml
# prints 'snoitcnuF baLtiG morf iH'
my-job:
  run:
    - name: echo
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo:1 reverse/func.yml
      inputs:
        message: "Hi from GitLab Functions"
```

Pour vous authentifier auprès de dépôts OCI privés, définissez la variable d'environnement `DOCKER_AUTH_CONFIG` avec une valeur au format du fichier de configuration Docker. Pour un exemple fonctionnel d'authentification en tant que fonction, consultez la fonction [Docker Auth](https://gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/docker-auth).

#### Charger depuis le système de fichiers {#load-from-the-file-system}

Pour charger une fonction depuis le système de fichiers en utilisant un chemin relatif, commencez la référence de la fonction par `.`. Les chemins sont relatifs au répertoire de la fonction appelante. Lorsque vous appelez la fonction directement depuis le job, le chemin est relatif à `CI_PROJECT_DIR`.

Commencez la référence de la fonction par `/` pour charger une fonction depuis le système de fichiers en utilisant un chemin absolu.

Le chemin devient le répertoire de la fonction lorsque l'étape s'exécute. Le fichier YAML de définition de la fonction doit exister dans ce répertoire. Vous pouvez éventuellement fournir le nom du fichier YAML de définition de la fonction s'il n'est pas standard.

Les séparateurs de chemin doivent utiliser des barres obliques `/`, quel que soit le système d'exploitation.

Par exemple :

- Charger depuis un répertoire relatif :

  ```yaml
  - name: my_step
    func: ./path/to/my-function
  ```

- Charger depuis un répertoire absolu :

  ```yaml
  - name: my_step
    func: /opt/gitlab-functions/my-function
  ```

- Charger en utilisant un fichier de définition de fonction personnalisé :

  ```yaml
  - name: my_step
    func: ./funcs/release/dry-run.yml
  ```

#### Charger depuis un dépôt Git (obsolète) {#load-from-a-git-repository-deprecated}

> [!warning]
> GitLab prévoit de supprimer la prise en charge du chargement de fonctions depuis des dépôts Git dans une prochaine version. Chargez plutôt les fonctions depuis un dépôt OCI.

Pour charger une fonction depuis un dépôt Git, fournissez l'URL et la révision (commit, branche ou tag) du dépôt. Pour vous authentifier auprès du dépôt, ajoutez un nom d'utilisateur et un mot de passe à l'URL.

Les fonctions doivent exister dans le sous-répertoire `steps` lorsque vous fournissez la référence de la fonction Git sous forme de texte dans `func`. Les fonctions doivent exister dans le répertoire `dir` lorsque vous utilisez la référence de fonction Git sous forme longue, `git`.

Les dépôts Git contiennent le code source, et non du code compilé. Dans la mesure du possible, chargez les fonctions depuis un dépôt OCI.

Par exemple :

- Spécifier la fonction avec un tag :

  ```yaml
  - name: my_step
    func: gitlab.com/funcs/my-git-repo@v1.0.0
  ```

- Spécifier la fonction avec une branche :

  ```yaml
  - name: my_step
    func: gitlab.com/funcs/my-git-repo@main
  ```

- Spécifier la fonction avec un répertoire, un nom de fichier et un commit Git :

  ```yaml
  - name: my_step
    func: gitlab.com/funcs/my-git-repo/-/reverse/my-func.yml@3c63f399ace12061db4b8b9a29f522f41a3d7f25
  ```

- S'authentifier auprès de Git lors de la récupération :

  ```yaml
  - name: my_step
    func: gitlab-ci-token:${{ vars.CI_JOB_TOKEN }}@gitlab.com/funcs/my-git-repo@v2.0.0
  ```

Pour spécifier un répertoire ou un fichier en dehors du dossier `steps`, utilisez la syntaxe étendue de `func` :

```yaml
my-job:
  run:
    - name: my_step
      func:
        git:
          url: gitlab.com/funcs/my-git-repo
          rev: main
          dir: my-functions/sub-directory  # optional, defaults to the repository root
          file: my-func.yml                # optional, defaults to `func.yml`
```

### Expressions {#expressions}

Utilisez des expressions lorsque vous avez besoin d'une valeur qui n'est pas connue avant l'exécution du job, telle qu'une sortie d'une étape précédente, une variable de job ou une valeur calculée.

Les expressions utilisent la syntaxe `${{ }}` et sont évaluées avant l'exécution de chaque fonction. Pour la référence complète du langage d'expression, incluant les opérateurs, les structures de données et les fonctions intégrées, consultez [le langage d'expression Moa](moa.md).

Les expressions peuvent être utilisées dans :

- Les valeurs d'entrée (`inputs`)
- Les valeurs des variables d'environnement (`env`)
- La référence de la fonction (`func`)
- Le contenu du script (`script`)

#### Contexte disponible {#available-context}

Utilisez les variables de contexte suivantes avec GitLab Functions. Pour la référence de contexte complète, consultez [le langage d'expression Moa](moa.md#context-reference).

| Variable                                  | Type   | Description                                                                                                                                                                                                   |
|:------------------------------------------|:-------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `env.<name>`                              | Chaîne | L'environnement lors de l'exécution de la fonction. Inclut les variables d'environnement définies par le système d'exploitation, le runner, et toutes les variables d'environnement exportées par les étapes précédemment exécutées. `env` ne contient pas les variables de job CI/CD. |
| `vars.<name>`                             | Chaîne | Variables de job CI/CD transmises depuis le runner. Contrairement à `env`, cette variable n'est pas affectée par les exports d'étapes.                                                                                                      |
| `inputs.<name>`                           | Quelconque    | Les valeurs d'entrée transmises à la fonction courante.                                                                                                                                                              |
| `steps.<step_name>.outputs.<output_name>` | Quelconque    | Les valeurs de sortie d'une étape précédemment terminée dans la liste `run` courante.                                                                                                                                     |
| `func_dir`                                | Chaîne | Chemin vers le répertoire contenant le fichier de définition de la fonction. Utilisez-le pour référencer des fichiers fournis avec la fonction.                                                                                            |
| `work_dir`                                | Chaîne | Chemin vers le répertoire de travail pour l'exécution courante.                                                                                                                                                      |

#### Exemples {#examples}

- Référencer une sortie d'une étape précédente :

  ```yaml
  my-job:
    run:
      - name: generate_rand
        func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/random:1
      - name: echo
        func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo:1
        inputs:
          message: "The random value is: ${{ steps.generate_rand.outputs.random_value }}"
  ```

- Utiliser une variable de job avec une valeur par défaut de repli :

  ```yaml
  run:
    - name: deploy
      func: ./deploy
      inputs:
        environment: ${{ vars.CI_COMMIT_REF_NAME == "main" && "production" || "staging" }}
  ```

### Variables d'environnement {#environment-variables}

Les variables d'environnement se déplacent entre les étapes de deux façons : vous les définissez avec `env`, ou vous les exportez via une fonction. La différence est importante car elles ont des portées différentes.

Les variables de job CI/CD ne sont pas disponibles en tant que variables d'environnement. Accédez aux variables de job en utilisant `${{ vars.<name> }}` à la place.

#### Définir des variables d'environnement pour une étape {#set-environment-variables-for-a-step}

Utilisez le mot-clé `env` sur une étape pour définir des variables d'environnement pour cette étape et toutes les fonctions qu'elle appelle en interne. Les variables définies avec `env` sont disponibles pour cette étape en plus de toutes les variables déjà présentes dans l'environnement. Si une variable existe déjà, la valeur définie par `env` est prioritaire. Les variables définies de cette façon ne sont pas disponibles pour les étapes suivantes dans la même liste `run`.

```yaml
run:
  - name: build
    func: ./build
    env:
      BUILD_TARGET: release   # available to build and its child steps only
  - name: test
    func: ./test              # BUILD_TARGET is not available here
```

Utilisez des [expressions](#expressions) dans les clés et les valeurs de `env`.

#### Variables d'environnement exportées {#exported-environment-variables}

Lorsqu'une fonction écrit dans `${{ export_file }}`, les variables qu'elle écrit sont exportées vers toutes les étapes suivantes dans la liste `run`. Les fonctions utilisent cette méthode pour partager l'état avec les étapes ultérieures.

Les variables exportées sont disponibles via `env` dans les expressions :

```yaml
run:
  - name: setup
    func: ./setup             # exports INSTALL_PATH during execution
  - name: build
    func: ./build
    inputs:
      path: ${{ env.INSTALL_PATH }}   # available because setup exported it
```

#### Précédence {#precedence}

Lorsque la même variable est définie à plusieurs endroits, l'ordre suivant s'applique, du plus élevé au plus bas :

1. `env` défini dans la définition de la fonction (`func.yml`)
1. `env` défini sur l'étape dans la liste `run`
1. Exporté par une étape précédemment exécutée
1. Défini par le runner
1. Défini par l'environnement du processus du système d'exploitation

## Créer votre propre fonction {#create-your-own-function}

Pour créer une fonction, consultez [créer une GitLab Function](create.md).

Pour des exemples de fonctions, consultez [les exemples GitLab Functions](examples.md).

## Dépannage {#troubleshooting}

### Récupérer des fonctions depuis une URL HTTPS {#fetch-functions-from-an-https-url}

Un message d'erreur tel que `tls: failed to verify certificate: x509: certificate signed by unknown authority` indique que le système d'exploitation ne reconnaît pas ou ne fait pas confiance au serveur hébergeant la fonction.

Une cause fréquente est une image Docker ne disposant pas de certificats racines de confiance installés. Résolvez le problème en installant des certificats dans le conteneur ou en les intégrant dans l'`image` du job.

Vous pouvez utiliser une étape `script` pour installer des dépendances avant de récupérer des fonctions :

```yaml
ubuntu_job:
  image: ubuntu:24.04
  run:
    - name: install_certs
      script: apt update && apt install --assume-yes --no-install-recommends ca-certificates
    - name: echo_step
      func: registry.gitlab.com/user/my_functions/hello_world:1.0.0
```
