---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 'Tutoriel : Créer un pipeline complexe'
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Ce tutoriel vous guide dans la configuration d'un pipeline CI/CD progressivement plus complexe, en procédant par petites étapes itératives. Le pipeline est toujours entièrement fonctionnel, mais il gagne en fonctionnalités à chaque étape. L'objectif est de compiler, tester et déployer un site de documentation.

À l'issue de ce tutoriel, vous disposerez d'un nouveau projet sur GitLab.com et d'un site de documentation fonctionnel utilisant [Docusaurus](https://docusaurus.io/).

Pour suivre ce tutoriel, vous devrez :

1. Créer un projet pour héberger les fichiers Docusaurus
1. Créer le fichier de configuration initial du pipeline
1. Ajouter un job pour compiler le site
1. Ajouter un job pour déployer le site
1. Ajouter des jobs de test
1. Commencer à utiliser les pipelines de merge request
1. Réduire la configuration dupliquée

## Prérequis {#prerequisites}

- Vous devez disposer d'un compte sur GitLab.com.
- Vous devez être familiarisé avec Git.
- Node.js doit être installé sur votre machine locale. Par exemple, sur macOS, vous pouvez [installer node](https://formulae.brew.sh/formula/node) avec `brew install node`.

## Créer un projet pour héberger les fichiers Docusaurus {#create-a-project-to-hold-the-docusaurus-files}

Avant d'ajouter la configuration du pipeline, vous devez d'abord configurer un projet Docusaurus sur GitLab.com :

1. Créez un nouveau projet sous votre nom d'utilisateur (pas sous un groupe) :
   1. Dans le coin supérieur droit, sélectionnez **Créer un nouveau** ({{< icon name="plus" >}}) et **Nouveau projet/dépôt**.
   1. Sélectionnez **Créer un projet vide**.
   1. Saisissez les détails du projet :
      - Dans le champ **Nom du projet**, saisissez le nom de votre projet, par exemple `My Pipeline Tutorial Project`.
      - Sélectionnez **Initialiser le dépôt avec un README**.
   1. Sélectionnez **Créer le projet**.
1. Sur la page de présentation du projet, dans le coin supérieur droit, sélectionnez **Code** pour trouver les chemins de clonage de votre projet. Copiez le chemin SSH ou HTTP et utilisez-le pour cloner le projet localement.

   Par exemple, pour cloner via SSH dans un répertoire `pipeline-tutorial` sur votre ordinateur :

   ```shell
   git clone git@gitlab.com:my-username/my-pipeline-tutorial-project.git pipeline-tutorial
   ```

1. Accédez au répertoire du projet, puis générez un nouveau site Docusaurus :

   ```shell
   cd pipeline-tutorial
   npm init docusaurus
   ```

   L'assistant d'initialisation de Docusaurus vous pose des questions sur le site. Utilisez toutes les options par défaut.

1. L'assistant d'initialisation configure le site dans `website/`, mais le site doit se trouver à la racine du projet. Déplacez les fichiers vers la racine et supprimez l'ancien répertoire :

   ```shell
   mv website/* .
   rm -r website
   ```

1. Mettez à jour le fichier de configuration Docusaurus avec les détails de votre projet GitLab. Dans `docusaurus.config.js` :

   - Définissez `url:` sur un chemin avec ce format : `https://<my-username>.gitlab.io/`.
   - Définissez `baseUrl:` sur le nom de votre projet, par exemple `/my-pipeline-tutorial-project/`.

1. Commitez les modifications et poussez-les vers GitLab :

   ```shell
   git add .
   git commit -m "Add simple generated Docusaurus site"
   git push origin
   ```

## Créer le fichier de configuration CI/CD initial {#create-the-initial-cicd-configuration-file}

Commencez par le fichier de configuration de pipeline le plus simple possible pour vous assurer que CI/CD est activé dans le projet et que des runners sont disponibles pour exécuter les jobs.

Cette étape présente :

- [Jobs](../jobs/_index.md) : Il s'agit de parties autonomes d'un pipeline qui exécutent vos commandes. Les jobs s'exécutent sur des [runners](../runners/_index.md), séparément de l'instance GitLab.
- [`script`](../yaml/_index.md#script) : Cette section de la configuration d'un job est l'endroit où vous définissez les commandes des jobs. S'il y a plusieurs commandes (dans un tableau), elles s'exécutent dans l'ordre. Chaque commande s'exécute comme si elle était lancée en tant que commande CLI. Par défaut, si une commande échoue ou renvoie une erreur, le job est signalé comme ayant échoué et aucune autre commande ne s'exécute.

Dans cette étape, créez un fichier `.gitlab-ci.yml` à la racine du projet avec cette configuration :

```yaml
test-job:
  script:
    - echo "This is my first job!"
    - date
```

Commitez et poussez cette modification vers GitLab, puis :

1. Accédez à **Version** > **Pipelines** et assurez-vous qu'un pipeline s'exécute dans GitLab avec ce seul job.
1. Sélectionnez le pipeline, puis sélectionnez le job pour afficher le job log du job et voir le message `This is my first job!` suivi de la date.

Maintenant que vous avez un fichier `.gitlab-ci.yml` dans votre projet, vous pouvez apporter toutes les modifications futures à la configuration du pipeline avec l'[éditeur de pipeline](../pipeline_editor/_index.md).

## Ajouter un job pour compiler le site {#add-a-job-to-build-the-site}

Une tâche courante pour un pipeline CI/CD consiste à compiler le code du projet, puis à le déployer. Commencez par ajouter un job qui compile le site.

Cette étape présente :

- [`image`](../yaml/_index.md#image) : Indiquez au runner quel conteneur Docker utiliser pour exécuter le job. Le runner :
  1. Télécharge l'image de conteneur et la démarre.
  1. Clone votre projet GitLab dans le conteneur en cours d'exécution.
  1. Exécute les commandes `script`, une à la fois.
- [`artifacts`](../yaml/_index.md#artifacts) : Les jobs sont autonomes et ne partagent pas de ressources entre eux. Si vous souhaitez que des fichiers générés dans un job soient utilisés dans un autre job, vous devez d'abord les enregistrer en tant qu'artefacts. Les jobs ultérieurs peuvent ensuite récupérer les artefacts et utiliser les fichiers générés.

Dans cette étape, remplacez `test-job` par `build-job` :

- Utilisez `image` pour configurer le job afin qu'il s'exécute avec la dernière image `node`. Docusaurus est un projet Node.js et l'image `node` intègre les commandes `npm` nécessaires.
- Exécutez `npm install` pour installer Docusaurus dans le conteneur `node` en cours d'exécution, puis exécutez `npm run build` pour compiler le site.
- Docusaurus enregistre le site compilé dans `build/`, donc enregistrez ces fichiers avec `artifacts`.

```yaml
build-job:
  image: node
  script:
    - npm install
    - npm run build
  artifacts:
    paths:
      - "build/"
```

Utilisez l'éditeur de pipeline pour commiter cette configuration de pipeline sur la branche par défaut, et vérifiez le job log. Vous pouvez :

- Observez les commandes `npm` s'exécuter et compiler le site.
- Vérifiez que les artefacts sont enregistrés à la fin.
- Parcourez le contenu du fichier d'artefacts en sélectionnant **Parcourir** à droite du job log une fois le job terminé.

## Ajouter un job pour déployer le site {#add-a-job-to-deploy-the-site}

Après avoir vérifié que le site Docusaurus se compile dans `build-job`, vous pouvez ajouter un job qui le déploie.

Cette étape présente :

- [`stage`](../yaml/_index.md#stage) et [`stages`](../yaml/_index.md#stage) : Les configurations de pipeline les plus courantes regroupent les jobs en étapes. Les jobs d'une même étape peuvent s'exécuter en parallèle, tandis que les jobs des étapes suivantes attendent que les jobs des étapes précédentes se terminent. Si un job échoue, l'étape entière est considérée comme ayant échoué et les jobs des étapes suivantes ne démarrent pas.
- [GitLab Pages](../../user/project/pages/_index.md) : Pour héberger votre site statique, vous utiliserez GitLab Pages.

Dans cette étape :

- Ajoutez un job qui récupère le site compilé et le déploie. Lors de l'utilisation de GitLab Pages, le job est toujours nommé `pages`. Les artefacts du `build-job` sont récupérés automatiquement et extraits dans le job. Pages recherche le site dans le répertoire `public/`, donc ajoutez une commande `script` pour déplacer le site vers ce répertoire.
- Ajoutez une section `stages` et définissez les étapes pour chaque job. `build-job` s'exécute en premier dans l'étape `build`, et `pages` s'exécute ensuite dans l'étape `deploy`.

```yaml
stages:          # List of stages for jobs and their order of execution
  - build
  - deploy

build-job:
  stage: build   # Set this job to run in the `build` stage
  image: node
  script:
    - npm install
    - npm run build
  artifacts:
    paths:
      - "build/"

pages:
  stage: deploy  # Set this new job to run in the `deploy` stage
  script:
    - mv build/ public/
  artifacts:
    paths:
      - "public/"
```

Utilisez l'éditeur de pipeline pour commiter cette configuration de pipeline sur la branche par défaut, et consultez les détails du pipeline depuis la liste **Pipelines**. Vérifiez que :

- Les deux jobs s'exécutent dans des étapes différentes, `build` et `deploy`.
- Une fois le job `pages` terminé, un job `pages:deploy` apparaît, qui est le processus GitLab qui déploie le site Pages. Lorsque ce job est terminé, vous pouvez visiter votre nouveau site Docusaurus.

Pour afficher votre site :

- Dans la barre latérale gauche, sélectionnez **Déploiement** > **Pages**.
- Assurez-vous que **Utiliser un domaine unique** est désactivé.
- Sous **Accès aux pages**, sélectionnez le lien. Le format de l'URL doit être similaire à : `https://<my-username>.gitlab.io/<project-name>`. Pour plus d'informations, consultez [Noms de domaine par défaut de GitLab Pages](../../user/project/pages/getting_started_part_one.md#gitlab-pages-default-domain-names).

> [!note]
> Si vous devez [utiliser des domaines uniques](../../user/project/pages/_index.md#unique-domains), dans `docusaurus.config.js`, définissez `baseUrl` : sur `/`.

## Ajouter des jobs de test {#add-test-jobs}

Maintenant que le site se compile et se déploie comme prévu, vous pouvez ajouter des tests et du linting. Par exemple, un projet Ruby pourrait exécuter des jobs de test RSpec. Docusaurus est un site statique qui utilise Markdown et du HTML généré, donc ce tutoriel ajoute des jobs pour tester le Markdown et le HTML.

Cette étape présente :

- [`allow_failure`](../yaml/_index.md#allow_failure) : Les jobs qui échouent par intermittence, ou qui sont censés échouer, peuvent ralentir la productivité ou être difficiles à déboguer. Utilisez `allow_failure` pour laisser les jobs échouer sans interrompre l'exécution du pipeline.
- [`dependencies`](../yaml/_index.md#dependencies) : Utilisez `dependencies` pour contrôler les téléchargements d'artefacts dans les jobs individuels en listant les jobs à partir desquels récupérer les artefacts.

Dans cette étape :

- Ajoutez une nouvelle étape `test` qui s'exécute entre `build` et `deploy`. Ces trois étapes sont les étapes par défaut lorsque `stages` n'est pas défini dans la configuration.
- Ajoutez un job `lint-markdown` pour exécuter [markdownlint](https://github.com/DavidAnson/markdownlint) et vérifier le Markdown de votre projet. markdownlint est un outil d'analyse statique qui vérifie que vos fichiers Markdown respectent les normes de formatage.
  - Les exemples de fichiers Markdown générés par Docusaurus se trouvent dans `blog/` et `docs/`.
  - Cet outil analyse uniquement les fichiers Markdown d'origine et n'a pas besoin du HTML généré enregistré dans les artefacts de `build-job`. Accélérez le job avec `dependencies: []` afin qu'il ne récupère aucun artefact.
  - Quelques-uns des exemples de fichiers Markdown enfreignent les règles markdownlint par défaut, donc ajoutez `allow_failure: true` pour laisser le pipeline continuer malgré les violations de règles.
- Ajoutez un job `test-html` pour exécuter [HTMLHint](https://htmlhint.com/) et vérifier le HTML généré. HTMLHint est un outil d'analyse statique qui analyse le HTML généré pour détecter les problèmes connus.
- `test-html` et `pages` ont tous les deux besoin du HTML généré trouvé dans les artefacts de `build-job`. Les jobs récupèrent par défaut les artefacts de tous les jobs des étapes précédentes, mais ajoutez `dependencies:` pour vous assurer que les jobs ne téléchargent pas accidentellement d'autres artefacts après de futures modifications du pipeline.

```yaml
stages:
  - build
  - test               # Add a `test` stage for the test jobs
  - deploy

build-job:
  stage: build
  image: node
  script:
    - npm install
    - npm run build
  artifacts:
    paths:
      - "build/"

lint-markdown:
  stage: test
  image: node
  dependencies: []     # Don't fetch any artifacts
  script:
    - npm install markdownlint-cli2 --global           # Install markdownlint into the container
    - markdownlint-cli2 -v                             # Verify the version, useful for troubleshooting
    - markdownlint-cli2 "blog/**/*.md" "docs/**/*.md"  # Lint all markdown files in blog/ and docs/
  allow_failure: true  # This job fails right now, but don't let it stop the pipeline.

test-html:
  stage: test
  image: node
  dependencies:
    - build-job        # Only fetch artifacts from `build-job`
  script:
    - npm install --save-dev htmlhint                  # Install HTMLHint into the container
    - npx htmlhint --version                           # Verify the version, useful for troubleshooting
    - npx htmlhint build/                              # Lint all markdown files in blog/ and docs/

pages:
  stage: deploy
  dependencies:
    - build-job        # Only fetch artifacts from `build-job`
  script:
    - mv build/ public/
  artifacts:
    paths:
      - "public/"
```

Commitez cette configuration de pipeline sur la branche par défaut et consultez les détails du pipeline.

- Le job `lint-markdown` échoue car le Markdown d'exemple enfreint les règles markdownlint par défaut, mais il est autorisé à échouer. Vous pouvez :
  - Ignorez les violations pour le moment. Elles n'ont pas besoin d'être corrigées dans le cadre du tutoriel.
  - Corrigez les violations dans les fichiers Markdown. Vous pouvez ensuite remplacer `allow_failure` par `false`, ou supprimer complètement `allow_failure` car `allow_failure: false` est le comportement par défaut lorsqu'il n'est pas défini.
  - Ajoutez un fichier de configuration markdownlint pour limiter les violations de règles sur lesquelles alerter.
- Vous pouvez également apporter des modifications au contenu des fichiers Markdown et voir les changements sur le site après le prochain déploiement.

## Commencer à utiliser les pipelines de merge request {#start-using-merge-request-pipelines}

Avec les configurations de pipeline précédentes, le site se déploie chaque fois qu'un pipeline se termine avec succès, mais ce n'est pas un workflow de développement idéal. Il est préférable de travailler à partir de branches de fonctionnalités et de merge requests, et de ne déployer le site que lorsque les modifications sont fusionnées sur la branche par défaut.

Cette étape présente :

- [`rules`](../yaml/_index.md#rules) : Ajoutez des règles à chaque job pour configurer dans quels pipelines ils s'exécutent. Vous pouvez configurer des jobs pour s'exécuter dans des [pipelines de merge request](../pipelines/merge_request_pipelines.md), des [planifications de pipeline](../pipelines/schedules.md), ou d'autres situations spécifiques. Les règles sont évaluées de haut en bas, et si une règle correspond, le job est ajouté au pipeline.
- [Variables CI/CD](../variables/_index.md) : utilisez ces variables d'environnement pour configurer le comportement des jobs dans le fichier de configuration et dans les commandes de script. Les [variables CI/CD prédéfinies](../variables/predefined_variables.md) sont des variables CI/CD que vous n'avez pas besoin de définir manuellement. Elles sont automatiquement injectées dans les pipelines afin que vous puissiez les utiliser pour configurer votre pipeline. Les variables sont généralement formatées comme `$VARIABLE_NAME`. et les variables prédéfinies sont généralement préfixées par `$CI_`.

Dans cette étape :

- Créez une nouvelle branche de fonctionnalité et effectuez les modifications dans cette branche plutôt que dans la branche par défaut.
- Ajoutez `rules` à chaque job :
  - Le site ne doit se déployer que pour les modifications apportées à la branche par défaut.
  - Les autres jobs doivent s'exécuter pour toutes les modifications dans les merge requests ou la branche par défaut.
- Avec cette configuration de pipeline, vous pouvez travailler à partir d'une branche de fonctionnalité sans exécuter de jobs, ce qui économise des ressources. Lorsque vous êtes prêt à valider vos modifications, créez une merge request et un pipeline s'exécute avec les jobs configurés pour s'exécuter dans les merge requests.
- Lorsque votre merge request est acceptée et que les modifications sont fusionnées sur la branche par défaut, un nouveau pipeline s'exécute, qui contient également le job de déploiement `pages`. Le site se déploie si aucun job n'échoue.

```yaml
stages:
  - build
  - test
  - deploy

build-job:
  stage: build
  image: node
  script:
    - npm install
    - npm run build
  artifacts:
    paths:
      - "build/"
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'  # Run for all changes to a merge request's source branch
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH       # Run for all changes to the default branch

lint-markdown:
  stage: test
  image: node
  dependencies: []
  script:
    - npm install markdownlint-cli2 --global
    - markdownlint-cli2 -v
    - markdownlint-cli2 "blog/**/*.md" "docs/**/*.md"
  allow_failure: true
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'  # Run for all changes to a merge request's source branch
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH       # Run for all changes to the default branch

test-html:
  stage: test
  image: node
  dependencies:
    - build-job
  script:
    - npm install --save-dev htmlhint
    - npx htmlhint --version
    - npx htmlhint build/
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'  # Run for all changes to a merge request's source branch
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH       # Run for all changes to the default branch

pages:
  stage: deploy
  dependencies:
    - build-job
  script:
    - mv build/ public/
  artifacts:
    paths:
      - "public/"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH      # Run for all changes to the default branch only
```

Fusionnez les modifications de votre merge request. Cette action met à jour la branche par défaut. Vérifiez que le nouveau pipeline contient le job `pages` qui déploie le site.

Veillez à utiliser des branches de fonctionnalités et des merge requests pour toutes les futures modifications de la configuration du pipeline. Les autres modifications du projet, comme la création d'un tag Git ou l'ajout d'une planification de pipeline, ne déclenchent pas de pipelines sauf si vous ajoutez également des règles pour ces cas.

## Réduire la configuration dupliquée {#reduce-duplicated-configuration}

Le pipeline contient maintenant trois jobs qui ont tous une configuration `rules` et `image` identique. Au lieu de répéter ces règles, utilisez `extends` et `default` pour créer des sources de vérité uniques.

Cette étape présente :

- [Jobs masqués](../jobs/_index.md#hide-a-job) : Les jobs commençant par `.` ne sont jamais ajoutés à un pipeline. Utilisez-les pour stocker la configuration que vous souhaitez réutiliser.
- [`extends`](../yaml/_index.md#extends) : Utilisez extends pour répéter la configuration à plusieurs endroits, souvent à partir de jobs masqués. Si vous mettez à jour la configuration du job masqué, tous les jobs qui étendent le job masqué utilisent la configuration mise à jour.
- [`default`](../yaml/_index.md#default) : Définissez des valeurs par défaut de mots-clés qui s'appliquent à tous les jobs lorsqu'ils ne sont pas définis.
- Remplacement YAML : Lors de la réutilisation de la configuration avec `extends` ou `default`, vous pouvez définir explicitement un mot-clé dans le job pour remplacer la configuration `extends` ou `default`.

Dans cette étape :

- Ajoutez un job masqué `.standard-rules` pour stocker les règles répétées dans `build-job`, `lint-markdown` et `test-html`.
- Utilisez `extends` pour réutiliser la configuration `.standard-rules` dans les trois jobs.
- Ajoutez une section `default` pour définir la valeur par défaut de `image` comme `node`.
- Le job de déploiement `pages` n'a pas besoin de l'image `node` par défaut, donc utilisez explicitement [`busybox`](https://hub.docker.com/_/busybox), une image extrêmement légère et rapide.

```yaml
stages:
  - build
  - test
  - deploy

default:               # Add a default section to define the `image` keyword's default value
  image: node

.standard-rules:       # Make a hidden job to hold the common rules
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

build-job:
  extends:
    - .standard-rules  # Reuse the configuration in `.standard-rules` here
  stage: build
  script:
    - npm install
    - npm run build
  artifacts:
    paths:
      - "build/"

lint-markdown:
  stage: test
  extends:
    - .standard-rules  # Reuse the configuration in `.standard-rules` here
  dependencies: []
  script:
    - npm install markdownlint-cli2 --global
    - markdownlint-cli2 -v
    - markdownlint-cli2 "blog/**/*.md" "docs/**/*.md"
  allow_failure: true

test-html:
  stage: test
  extends:
    - .standard-rules  # Reuse the configuration in `.standard-rules` here
  dependencies:
    - build-job
  script:
    - npm install --save-dev htmlhint
    - npx htmlhint --version
    - npx htmlhint build/

pages:
  stage: deploy
  image: busybox       # Override the default `image` value with `busybox`
  dependencies:
    - build-job
  script:
    - mv build/ public/
  artifacts:
    paths:
      - "public/"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

Utilisez une merge request pour commiter cette configuration de pipeline sur la branche par défaut. Le fichier est plus simple, mais il doit avoir le même comportement que l'étape précédente.

Vous venez de créer un pipeline complet et de l'optimiser pour le rendre plus efficace. Excellent travail ! Vous pouvez maintenant mettre à profit ces connaissances, en apprendre davantage sur les autres mots-clés de `.gitlab-ci.yml` dans la [référence de syntaxe YAML CI/CD](../yaml/_index.md), et créer vos propres pipelines.
