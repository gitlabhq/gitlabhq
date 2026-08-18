---
stage: Verify
group: Pipeline Authoring
info: This page is maintained by Developer Relations, author @dnsmichi, see <https://handbook.gitlab.com/handbook/marketing/developer-relations/developer-advocacy/content/#maintained-documentation>
title: Exemples de composants CI/CD
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Tester un composant {#test-a-component}

Selon la fonctionnalité d'un composant, [tester le composant](_index.md#test-the-component) peut nécessiter des fichiers supplémentaires dans le dépôt. Par exemple, un composant qui effectue du linting, de la compilation et des tests de logiciels dans un langage de programmation spécifique nécessite des exemples de code source réels. Vous pouvez inclure des exemples de code source, des fichiers de configuration et des éléments similaires dans le même dépôt.

Par exemple, le composant CI/CD Code Quality dispose de plusieurs [exemples de code pour les tests](https://gitlab.com/components/code-quality/-/tree/main/src).

### Exemple : Tester un composant CI/CD pour le langage Rust {#example-test-a-rust-language-cicd-component}

Selon la fonctionnalité d'un composant, [tester le composant](_index.md#test-the-component) peut nécessiter des fichiers supplémentaires dans le dépôt.

L'exemple « hello world » suivant pour le langage de programmation Rust utilise la chaîne d'outils `cargo` pour plus de simplicité :

1. Accédez au répertoire racine du composant CI/CD.
1. Initialisez un nouveau projet Rust en utilisant la commande `cargo init`.

   ```shell
   cargo init
   ```

   La commande crée tous les fichiers de projet nécessaires, notamment un exemple « hello world » `src/main.rs`. Cette étape est suffisante pour compiler le code source Rust dans un job de composant avec `cargo build`.

   ```plaintext
   tree
   .
   ├── Cargo.toml
   ├── LICENSE.md
   ├── README.md
   ├── src
   │   └── main.rs
   └── templates
       └── build.yml
   ```

1. Assurez-vous que le composant dispose d'un job pour compiler le code source Rust, par exemple, dans `templates/build.yml` :

   ```yaml
   spec:
     inputs:
       stage:
         default: build
         description: 'Defines the build stage'
       rust_version:
         default: latest
         description: 'Specify the Rust version, use values from https://hub.docker.com/_/rust/tags Defaults to latest'
   ---

   "build-$[[ inputs.rust_version ]]":
     stage: $[[ inputs.stage ]]
     image: rust:$[[ inputs.rust_version ]]
     script:
       - cargo build --verbose
   ```

   Dans cet exemple :

   - Les entrées `stage` et `rust_version` peuvent être modifiées par rapport à leurs valeurs par défaut. Le job CI/CD commence par un préfixe `build-` et crée dynamiquement le nom en fonction de l'entrée `rust_version`. La commande `cargo build --verbose` compile le code source Rust.

1. Testez le modèle `build` du composant dans le fichier de configuration `.gitlab-ci.yml` du projet :

   ```yaml
   include:
     # include the component located in the current project from the current SHA
     - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/build@$CI_COMMIT_SHA
       inputs:
         stage: build

   stages: [build, test, release]
   ```

1. Pour exécuter des tests et plus encore, ajoutez des fonctions et des tests supplémentaires dans le code Rust, et ajoutez un modèle de composant et un job exécutant `cargo test` dans `templates/test.yml`.

   ```yaml
   spec:
     inputs:
       stage:
         default: test
         description: 'Defines the test stage'
       rust_version:
         default: latest
         description: 'Specify the Rust version, use values from https://hub.docker.com/_/rust/tags Defaults to latest'
   ---

   "test-$[[ inputs.rust_version ]]":
     stage: $[[ inputs.stage ]]
     image: rust:$[[ inputs.rust_version ]]
     script:
       - cargo test --verbose
   ```

1. Testez le job supplémentaire dans le pipeline en incluant le modèle de composant `test` :

   ```yaml
   include:
     # include the component located in the current project from the current SHA
     - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/build@$CI_COMMIT_SHA
       inputs:
         stage: build
     - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/test@$CI_COMMIT_SHA
       inputs:
         stage: test

   stages: [build, test, release]
   ```

## Modèles de composants CI/CD {#cicd-component-patterns}

Cette section fournit des exemples pratiques d'implémentation de modèles courants dans les composants CI/CD.

### Utiliser des entrées booléennes pour configurer conditionnellement des jobs {#use-boolean-inputs-to-conditionally-configure-jobs}

Vous pouvez composer des jobs avec deux conditions en combinant des entrées de type `boolean` et la fonctionnalité [`extends`](../yaml/_index.md#extends).

Par exemple, pour configurer un comportement de mise en cache complexe avec une entrée `boolean` :

```yaml
spec:
  inputs:
    enable_special_caching:
      description: 'If set to `true` configures a complex caching behavior'
      type: boolean
---

.my-component:enable_special_caching:false:
  extends: null

.my-component:enable_special_caching:true:
  cache:
    policy: pull-push
    key: $CI_COMMIT_SHA
    paths: [...]

my-job:
  extends: '.my-component:enable_special_caching:$[[ inputs.enable_special_caching ]]'
  script: ... # run some fancy tooling
```

Ce modèle fonctionne en transmettant l'entrée `enable_special_caching` dans le mot-clé `extends` du job. Selon que `enable_special_caching` est `true` ou `false`, la configuration appropriée est sélectionnée parmi les jobs masqués prédéfinis (`.my-component:enable_special_caching:true` ou `.my-component:enable_special_caching:false`).

### Utiliser `options` pour configurer conditionnellement des jobs {#use-options-to-conditionally-configure-jobs}

Vous pouvez composer des jobs avec plusieurs options, pour un comportement similaire aux conditions `if` et `elseif`. Utilisez [`extends`](../yaml/_index.md#extends) avec le type `string` et plusieurs `options` pour un nombre quelconque de conditions.

Par exemple, pour configurer un comportement de mise en cache complexe avec 3 options différentes :

```yaml
spec:
  inputs:
    cache_mode:
      description: Defines the caching mode to use for this component
      type: string
      options:
        - default
        - aggressive
        - relaxed
---

.my-component:cache_mode:default:
  extends: null

.my-component:cache_mode:aggressive:
  cache:
    policy: push
    key: $CI_COMMIT_SHA
    paths: ['*/**']

.my-component:cache_mode:relaxed:
  cache:
    policy: pull-push
    key: $CI_COMMIT_BRANCH
    paths: ['bin/*']

my-job:
  extends: '.my-component:cache_mode:$[[ inputs.cache_mode ]]'
  script: ... # run some fancy tooling
```

Dans cet exemple, l'entrée `cache_mode` propose les options `default`, `aggressive` et `relaxed`, chacune correspondant à un job masqué différent. En étendant le job du composant avec `extends: '.my-component:cache_mode:$[[ inputs.cache_mode ]]'`, le job hérite dynamiquement de la configuration de mise en cache correcte en fonction de l'option sélectionnée.

### Utiliser le contexte de composant pour référencer des ressources versionnées {#use-component-context-to-reference-versioned-resources}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/438275) dans GitLab 18.6 en tant que [bêta](../../policy/development_stages_support.md#beta) [avec un flag](../../administration/feature_flags/_index.md) nommé `ci_component_context_interpolation`. Activé par défaut.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/571986) dans GitLab 18.7. L'indicateur de fonctionnalité `ci_component_context_interpolation` a été supprimé.

{{< /history >}}

Utilisez les [expressions CI/CD](../yaml/expressions.md) du contexte de composant pour référencer les métadonnées du composant, comme la version et le SHA du commit. Un cas d'utilisation consiste à compiler et publier des ressources versionnées (comme des images Docker) avec votre composant, et à s'assurer que le composant utilise la version correspondante.

Par exemple, vous pouvez :

- Compiler une image Docker dans le pipeline de release du composant avec un tag correspondant à la version du composant.
- Faire en sorte que le composant référence cette même version d'image.

Dans le pipeline de release du projet de composant (`.gitlab-ci.yml`) :

```yaml
build-image:
  stage: build
  image: docker:latest
  script:
    - docker build -t $CI_REGISTRY_IMAGE/my-tool:$CI_COMMIT_TAG .
    - docker push $CI_REGISTRY_IMAGE/my-tool:$CI_COMMIT_TAG

create-release:
  stage: release
  image: registry.gitlab.com/gitlab-org/cli:latest
  script: echo "Creating release $CI_COMMIT_TAG"
  rules:
    - if: $CI_COMMIT_TAG
  release:
    tag_name: $CI_COMMIT_TAG
    description: "Release $CI_COMMIT_TAG"
```

Dans le modèle de composant (`templates/my-component/template.yml`) :

```yaml
spec:
  component: [version, reference]
  inputs:
    stage:
      default: test
---

run-tool:
  stage: $[[ inputs.stage ]]
  image: $CI_REGISTRY_IMAGE/my-tool:$[[ component.version ]]
  script:
    - echo "Running tool version $[[ component.version ]]"
    - echo "Component was included using reference: $[[ component.reference ]]"
    - my-tool --version
```

Dans cet exemple :

- Si vous incluez le composant avec `@1.0.0`, le job utilise l'image `my-tool:1.0.0`.
- Si vous l'incluez avec `@1.0`, il se résout vers la dernière version `1.0.x`, par exemple `1.0.3`, et utilise donc `my-tool:1.0.3`.
- Si vous l'incluez avec `@~latest`, il utilise la dernière version publiée.
- Le champ `component.reference` affiche la référence exacte que vous avez spécifiée, comme `1.0`, `~latest`, ou un SHA. La référence peut être utile pour la journalisation ou le débogage.

## Exemples de migration de composants CI/CD {#cicd-component-migration-examples}

Cette section présente des exemples pratiques de migration de modèles CI/CD et de configurations de pipeline vers des composants CI/CD réutilisables.

### Exemple de migration de composant CI/CD : Go {#cicd-component-migration-example-go}

Un pipeline complet pour le cycle de vie du développement logiciel peut être composé de plusieurs jobs et étapes. Les modèles CI/CD pour les langages de programmation peuvent fournir plusieurs jobs dans un seul fichier de modèle. À titre d'exercice, le modèle CI/CD Go suivant doit être migré.

```yaml
default:
  image: golang:latest

stages:
  - test
  - build
  - deploy

format:
  stage: test
  script:
    - go fmt $(go list ./... | grep -v /vendor/)
    - go vet $(go list ./... | grep -v /vendor/)
    - go test -race $(go list ./... | grep -v /vendor/)

compile:
  stage: build
  script:
    - mkdir -p mybinaries
    - go build -o mybinaries ./...
  artifacts:
    paths:
      - mybinaries
```

> [!note]
> Pour une approche plus incrémentale, migrez un job à la fois. Commencez par le job `build`, puis répétez les étapes pour les jobs `format` et `test`.

La migration du modèle CI/CD implique les étapes suivantes :

1. Analysez les jobs CI/CD et leurs dépendances, et définissez les actions de migration :
   - La configuration `image` est globale et [doit être déplacée dans les définitions de job](_index.md#avoid-using-global-keywords).
   - Le job `format` exécute plusieurs commandes `go` dans un seul job. La commande `go test` doit être déplacée dans un job séparé pour améliorer l'efficacité du pipeline.
   - Le job `compile` exécute `go build` et doit être renommé `build`.
1. Définissez des stratégies d'optimisation pour améliorer l'efficacité du pipeline.
   - L'attribut de job `stage` doit être configurable pour permettre à différents consommateurs de pipeline CI/CD de l'utiliser.
   - La clé `image` utilise un tag d'image codé en dur `latest`. Ajoutez [`golang_version` comme entrée](../inputs/_index.md) avec `latest` comme valeur par défaut pour des pipelines plus flexibles et réutilisables. L'entrée doit correspondre aux valeurs de tag d'image Docker Hub.
   - Le job `compile` compile les binaires dans un répertoire cible codé en dur `mybinaries`, qui peut être amélioré avec une [entrée](../inputs/_index.md) dynamique et la valeur par défaut `mybinaries`.
1. Créez une [structure de répertoires](_index.md#directory-structure) de modèle pour le nouveau composant, basée sur un modèle par job.

   - Le nom du modèle doit suivre la commande `go`, par exemple `format.yml`, `build.yml` et `test.yml`.
   - Créez un nouveau projet, initialisez un dépôt Git, ajoutez/commitez toutes les modifications, définissez une origine distante et effectuez un push. Modifiez l'URL pour le chemin de votre projet de composant CI/CD.
   - Créez des fichiers supplémentaires comme indiqué dans les instructions pour [écrire un composant](_index.md#write-a-component) : `README.md`, `LICENSE.md`, `.gitlab-ci.yml`, `.gitignore`. Les commandes shell suivantes initialisent la structure du composant Go :

   ```shell
   git init

   mkdir templates
   touch templates/{format,build,test}.yml

   touch README.md LICENSE.md .gitlab-ci.yml .gitignore

   git add -A
   git commit -avm "Initial component structure"

   git remote add origin https://gitlab.example.com/components/golang.git

   git push
   ```

1. Créez les jobs CI/CD en tant que modèle. Commencez par le job `build`.
   - Définissez les entrées suivantes dans la section `spec` : `stage`, `golang_version` et `binary_directory`.
   - Ajoutez une définition de nom de job dynamique, en accédant à `inputs.golang_version`.
   - Utilisez le même modèle pour les versions d'images Go dynamiques, en accédant à `inputs.golang_version`.
   - Assignez l'étape à la valeur `inputs.stage`.
   - Créez le répertoire de binaires à partir de `inputs.binary_directory` et ajoutez-le comme paramètre à `go build`.
   - Définissez le chemin des artefacts vers `inputs.binary_directory`.

     ```yaml
     spec:
       inputs:
         stage:
           default: 'build'
           description: 'Defines the build stage'
         golang_version:
           default: 'latest'
           description: 'Go image version tag'
         binary_directory:
           default: 'mybinaries'
           description: 'Output directory for created binary artifacts'
     ---

     "build-$[[ inputs.golang_version ]]":
       image: golang:$[[ inputs.golang_version ]]
       stage: $[[ inputs.stage ]]
       script:
         - mkdir -p $[[ inputs.binary_directory ]]
         - go build -o $[[ inputs.binary_directory ]] ./...
       artifacts:
         paths:
           - $[[ inputs.binary_directory ]]
     ```

   - Le modèle de job `format` suit les mêmes modèles, mais ne nécessite que les entrées `stage` et `golang_version`.

     ```yaml
     spec:
       inputs:
         stage:
           default: 'format'
           description: 'Defines the format stage'
         golang_version:
           default: 'latest'
           description: 'Golang image version tag'
     ---

     "format-$[[ inputs.golang_version ]]":
       image: golang:$[[ inputs.golang_version ]]
       stage: $[[ inputs.stage ]]
       script:
         - go fmt $(go list ./... | grep -v /vendor/)
         - go vet $(go list ./... | grep -v /vendor/)
     ```

   - Le modèle de job `test` suit les mêmes modèles, mais ne nécessite que les entrées `stage` et `golang_version`.

     ```yaml
     spec:
       inputs:
         stage:
           default: 'test'
           description: 'Defines the format stage'
         golang_version:
           default: 'latest'
           description: 'Golang image version tag'
     ---

     "test-$[[ inputs.golang_version ]]":
       image: golang:$[[ inputs.golang_version ]]
       stage: $[[ inputs.stage ]]
       script:
         - go test -race $(go list ./... | grep -v /vendor/)
     ```

1. Pour tester le composant, modifiez le fichier de configuration `.gitlab-ci.yml` et ajoutez des [tests](_index.md#test-the-component).

   - Spécifiez une valeur différente pour `golang_version` comme entrée pour le job `build`.
   - Modifiez l'URL pour le chemin de votre composant CI/CD.

     ```yaml
     stages: [format, build, test]

     include:
       - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/format@$CI_COMMIT_SHA
       - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/build@$CI_COMMIT_SHA
       - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/build@$CI_COMMIT_SHA
         inputs:
           golang_version: "1.21"
       - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/test@$CI_COMMIT_SHA
         inputs:
           golang_version: latest
     ```

1. Ajoutez du code source Go pour tester le composant CI/CD. Les commandes `go` attendent un projet Go avec `go.mod` et `main.go` dans le répertoire racine.

   - Initialisez les modules Go. Modifiez l'URL pour le chemin de votre composant CI/CD.

     ```shell
     go mod init example.gitlab.com/components/golang
     ```

   - Créez un fichier `main.go` avec une fonction principale affichant `Hello, CI/CD component` par exemple. Vous pouvez utiliser des commentaires de code pour générer du code Go à l'aide de GitLab Duo Code Suggestions.

     ```go
     // Specify the package, import required packages
     // Create a main function
     // Inside the main function, print "Hello, CI/CD Component"

     package main

     import "fmt"

     func main() {
       fmt.Println("Hello, CI/CD Component")
     }
     ```

   - L'arborescence du répertoire doit se présenter comme suit :

     ```plaintext
     tree
     .
     ├── LICENSE.md
     ├── README.md
     ├── go.mod
     ├── main.go
     └── templates
         ├── build.yml
         ├── format.yml
         └── test.yml
     ```

Suivez les étapes restantes dans la section [conversion d'un modèle CI/CD en composant](_index.md#convert-a-cicd-template-to-a-component) pour finaliser la migration :

1. Commitez et poussez les modifications, puis vérifiez les résultats du pipeline CI/CD.
1. Suivez les instructions sur [l'écriture d'un composant](_index.md#write-a-component) pour mettre à jour les fichiers `README.md` et `LICENSE.md`.
1. [Publiez le composant](_index.md#publish-a-new-release) et vérifiez-le dans le catalogue CI/CD.
1. Ajoutez le composant CI/CD dans votre environnement de staging/production.

Le [composant Go maintenu par GitLab](https://gitlab.com/components/go) fournit un exemple de migration réussie à partir d'un modèle CI/CD Go, enrichi d'entrées et des meilleures pratiques en matière de composants. Vous pouvez inspecter l'historique Git pour en savoir plus.
