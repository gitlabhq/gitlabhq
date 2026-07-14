---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Utiliser la configuration CI/CD d'autres fichiers"
description: "Utilisez le mot-clé `include` pour étendre votre configuration CI/CD avec du contenu provenant d'autres fichiers YAML."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez utiliser [`include`](_index.md#include) pour inclure des fichiers YAML externes dans vos jobs CI/CD.

## Inclure un seul fichier de configuration {#include-a-single-configuration-file}

Pour inclure un seul fichier de configuration, utilisez `include` seul avec un fichier unique en utilisant l'une de ces options de syntaxe :

- Sur la même ligne :

  ```yaml
  include: 'my-config.yml'
  ```

- En tant qu'élément unique dans un tableau :

  ```yaml
  include:
    - 'my-config.yml'
  ```

Si le fichier est un fichier local, le comportement est identique à [`include:local`](_index.md#includelocal). Si le fichier est un fichier distant, c'est identique à [`include:remote`](_index.md#includeremote).

## Inclure un tableau de fichiers de configuration {#include-an-array-of-configuration-files}

Vous pouvez inclure un tableau de fichiers de configuration :

- Si vous ne spécifiez pas de type `include`, chaque élément du tableau prend par défaut la valeur [`include:local`](_index.md#includelocal) ou [`include:remote`](_index.md#includeremote), selon les besoins :

  ```yaml
  include:
    - 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
    - 'templates/.after-script-template.yml'
  ```

- Vous pouvez définir un tableau avec un seul élément :

  ```yaml
  include:
    - remote: 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
  ```

- Vous pouvez définir un tableau et spécifier explicitement plusieurs types `include` :

  ```yaml
  include:
    - remote: 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
    - local: 'templates/.after-script-template.yml'
    - template: Auto-DevOps.gitlab-ci.yml
  ```

- Vous pouvez définir un tableau qui combine des types `include` par défaut et spécifiques :

  ```yaml
  include:
    - 'https://gitlab.com/awesome-project/raw/main/.before-script-template.yml'
    - 'templates/.after-script-template.yml'
    - template: Auto-DevOps.gitlab-ci.yml
    - project: 'my-group/my-project'
      ref: main
      file: 'templates/.gitlab-ci-template.yml'
  ```

## Utiliser la configuration `default` d'un fichier de configuration inclus {#use-default-configuration-from-an-included-configuration-file}

Vous pouvez définir une section [`default`](_index.md#default) dans un fichier de configuration. Lorsque vous utilisez une section `default` avec le mot-clé `include`, les valeurs par défaut s'appliquent à tous les jobs du pipeline.

Par exemple, vous pouvez utiliser une section `default` avec [`before_script`](_index.md#before_script).

Contenu d'un fichier de configuration personnalisé nommé `/templates/.before-script-template.yml` :

```yaml
default:
  before_script:
    - apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs
    - gem install bundler --no-document
    - bundle install --jobs $(nproc)  "${FLAGS[@]}"
```

Contenu de `.gitlab-ci.yml` :

```yaml
include: 'templates/.before-script-template.yml'

rspec1:
  script:
    - bundle exec rspec

rspec2:
  script:
    - bundle exec rspec
```

Les commandes `before_script` par défaut s'exécutent dans les deux jobs `rspec`, avant les commandes `script`.

## Remplacer les valeurs de configuration incluses {#override-included-configuration-values}

Lorsque vous utilisez le mot-clé `include`, vous pouvez remplacer les valeurs de configuration incluses pour les adapter aux besoins de votre pipeline.

L'exemple suivant montre un fichier `include` personnalisé dans le fichier `.gitlab-ci.yml`. Les variables CI/CD définies en YAML et les détails du job `production` sont remplacés.

Contenu d'un fichier de configuration personnalisé nommé `autodevops-template.yml` :

```yaml
variables:
  POSTGRES_USER: user
  POSTGRES_PASSWORD: testing_password
  POSTGRES_DB: $CI_ENVIRONMENT_SLUG

production:
  stage: production
  script:
    - install_dependencies
    - deploy
  environment:
    name: production
    url: https://$CI_PROJECT_PATH_SLUG.$KUBE_INGRESS_BASE_DOMAIN
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

Contenu de `.gitlab-ci.yml` :

```yaml
include: 'https://company.com/autodevops-template.yml'

default:
  image: alpine:latest

variables:
  POSTGRES_USER: root
  POSTGRES_PASSWORD: secure_password

stages:
  - build
  - test
  - production

production:
  environment:
    url: https://domain.com
```

Les variables CI/CD `POSTGRES_USER` et `POSTGRES_PASSWORD` ainsi que `environment:url` du job `production` définis dans le fichier `.gitlab-ci.yml` remplacent les valeurs définies dans le fichier `autodevops-template.yml`. Les autres mots-clés ne changent pas. Cette méthode s'appelle la _fusion_.

### Méthode de fusion pour `include` {#merge-method-for-include}

La configuration `include` est fusionnée avec le fichier de configuration principal selon ce processus :

- Les fichiers inclus sont lus dans l'ordre défini dans le fichier de configuration, et la configuration incluse est fusionnée dans le même ordre.
- Si un fichier inclus utilise également `include`, cette configuration `include` imbriquée est fusionnée en premier (de manière récursive).
- Si des paramètres se chevauchent, le dernier fichier inclus a la priorité lors de la fusion de la configuration des fichiers inclus.
- Une fois toute la configuration ajoutée avec `include` fusionnée, la configuration principale est fusionnée avec la configuration incluse.

Cette méthode de fusion est une _fusion profonde_, où les tables de hachage sont fusionnées à n'importe quelle profondeur dans la configuration. Pour fusionner la table de hachage « A » (qui contient la configuration fusionnée jusqu'à présent) et « B » (la prochaine partie de la configuration), les clés et les valeurs sont traitées comme suit :

- Lorsque la clé n'existe que dans A, utilisez la clé et la valeur de A.
- Lorsque la clé existe dans A et dans B, et que leurs valeurs sont toutes deux des tables de hachage, fusionnez ces tables de hachage.
- Lorsque la clé existe dans A et dans B, et que l'une des valeurs n'est pas une table de hachage, utilisez la valeur de B.
- Sinon, utilisez la clé et la valeur de B.

Par exemple, avec une configuration composée de deux fichiers :

- Le fichier `.gitlab-ci.yml` :

  ```yaml
  include: 'common.yml'

  variables:
    POSTGRES_USER: username

  test:
    rules:
      - if: $CI_PIPELINE_SOURCE == "merge_request_event"
        when: manual
    artifacts:
      reports:
        junit: rspec.xml
  ```

- Le fichier `common.yml` :

  ```yaml
  variables:
    POSTGRES_USER: common_username
    POSTGRES_PASSWORD: testing_password

  test:
    rules:
      - when: never
    script:
      - echo LOGIN=${POSTGRES_USER} > deploy.env
      - rake spec
    artifacts:
      reports:
        dotenv: deploy.env
  ```

Le résultat fusionné est :

```yaml
variables:
  POSTGRES_USER: username
  POSTGRES_PASSWORD: testing_password

test:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: manual
  script:
    - echo LOGIN=${POSTGRES_USER} > deploy.env
    - rake spec
  artifacts:
    reports:
      junit: rspec.xml
      dotenv: deploy.env
```

Dans cet exemple :

- Les variables sont évaluées uniquement après la fusion de tous les fichiers. Un job dans un fichier inclus peut finir par utiliser une valeur de variable CI/CD définie dans un fichier différent.
- `rules` est un tableau et ne peut donc pas être fusionné. Le fichier de niveau supérieur a la priorité.
- `artifacts` est une table de hachage et peut donc faire l'objet d'une fusion profonde.

## Remplacer les tableaux de configuration inclus {#override-included-configuration-arrays}

Vous pouvez utiliser la fusion pour étendre et remplacer la configuration dans un modèle inclus, mais vous ne pouvez pas ajouter ni modifier des éléments individuels dans un tableau. Par exemple, pour ajouter une commande `notify_owner` supplémentaire au tableau `script` du job `production` étendu :

Contenu de `autodevops-template.yml` :

```yaml
production:
  stage: production
  script:
    - install_dependencies
    - deploy
```

Contenu de `.gitlab-ci.yml` :

```yaml
include: 'autodevops-template.yml'

stages:
  - production

production:
  script:
    - install_dependencies
    - deploy
    - notify_owner
```

Si `install_dependencies` et `deploy` ne sont pas répétés dans le fichier `.gitlab-ci.yml`, le job `production` n'aura que `notify_owner` dans le script.

## Utiliser des inclusions imbriquées {#use-nested-includes}

Vous pouvez imbriquer des sections `include` dans des fichiers de configuration qui sont ensuite inclus dans une autre configuration. Par exemple, pour des mots-clés `include` imbriqués sur trois niveaux :

Contenu de `.gitlab-ci.yml` :

```yaml
include:
  - local: /.gitlab-ci/another-config.yml
```

Contenu de `/.gitlab-ci/another-config.yml` :

```yaml
include:
  - local: /.gitlab-ci/config-defaults.yml
```

Contenu de `/.gitlab-ci/config-defaults.yml` :

```yaml
default:
  after_script:
    - echo "Job complete."
```

### Utiliser des inclusions imbriquées avec des entrées `include` en double {#use-nested-includes-with-duplicate-include-entries}

Vous pouvez inclure le même fichier de configuration plusieurs fois dans le fichier de configuration principal et dans les inclusions imbriquées.

Si un fichier modifie la configuration incluse à l'aide de [remplacements](#override-included-configuration-values), l'ordre des entrées `include` peut affecter la configuration finale. La dernière fois que la configuration est incluse remplace toutes les inclusions précédentes du fichier. Par exemple :

- Contenu d'un fichier `defaults.gitlab-ci.yml` :

  ```yaml
  default:
    before_script: echo "Default before script"
  ```

- Contenu d'un fichier `unit-tests.gitlab-ci.yml` :

  ```yaml
  include:
    - template: defaults.gitlab-ci.yml

  default:  # Override the included default
    before_script: echo "Unit test default override"

  unit-test-job:
    script: unit-test.sh
  ```

- Contenu d'un fichier `smoke-tests.gitlab-ci.yml` :

  ```yaml
  include:
    - template: defaults.gitlab-ci.yml

  default:  # Override the included default
    before_script: echo "Smoke test default override"

  smoke-test-job:
    script: smoke-test.sh
  ```

Avec ces trois fichiers, l'ordre dans lequel ils sont inclus modifie la configuration finale. Avec :

- `unit-tests` inclus en premier, le contenu du fichier `.gitlab-ci.yml` est :

  ```yaml
  include:
    - local: unit-tests.gitlab-ci.yml
    - local: smoke-tests.gitlab-ci.yml
  ```

  La configuration finale serait :

  ```yaml
  unit-test-job:
   before_script: echo "Smoke test default override"
   script: unit-test.sh

  smoke-test-job:
   before_script: echo "Smoke test default override"
   script: smoke-test.sh
  ```

- `unit-tests` inclus en dernier, le contenu du fichier `.gitlab-ci.yml` est :

  ```yaml
  include:
    - local: smoke-tests.gitlab-ci.yml
    - local: unit-tests.gitlab-ci.yml
  ```

- La configuration finale serait :

  ```yaml
  unit-test-job:
   before_script: echo "Unit test default override"
   script: unit-test.sh

  smoke-test-job:
   before_script: echo "Unit test default override"
   script: smoke-test.sh
  ```

Si aucun fichier ne remplace la configuration incluse, l'ordre des entrées `include` n'affecte pas la configuration finale

## Utiliser des variables avec `include` {#use-variables-with-include}

Dans les sections `include` de votre fichier `.gitlab-ci.yml`, vous pouvez utiliser :

- [Variables de projet](../variables/_index.md#for-a-project).
- [Variables de groupe](../variables/_index.md#for-a-group).
- [Variables d'instance](../variables/_index.md#for-an-instance).
- [Variables prédéfinies](../variables/predefined_variables.md) du projet (`CI_PROJECT_*`).
- [Variables de déclencheur](../triggers/_index.md#pass-cicd-variables-in-the-api-call).
- [Variables de pipeline planifié](../pipelines/schedules.md#create-a-pipeline-schedule).
- [Variables d'exécution manuelle de pipeline](../pipelines/_index.md#run-a-pipeline-manually).
- Les [variables prédéfinies](../variables/predefined_variables.md) `CI_PIPELINE_SOURCE` et `CI_PIPELINE_TRIGGERED`.
- La [variable prédéfinie](../variables/predefined_variables.md) `$CI_COMMIT_REF_NAME`.

Par exemple :

```yaml
include:
  project: '$CI_PROJECT_PATH'
  file: '.compliance-gitlab-ci.yml'
```

Vous ne pouvez pas utiliser des variables définies dans des jobs, ni dans une section globale [`variables`](_index.md#variables) qui définit les variables par défaut pour tous les jobs. Les inclusions sont évaluées avant les jobs, donc ces variables ne peuvent pas être utilisées avec `include`.

Pour un exemple illustrant comment inclure des variables prédéfinies et leur impact sur les jobs CI/CD, consultez cette [démonstration des variables CI/CD](https://youtu.be/4XR8gw3Pkos).

Vous ne pouvez pas utiliser des variables CI/CD dans une section `include` dans la configuration d'un pipeline enfant dynamique. [Le ticket 378717](https://gitlab.com/gitlab-org/gitlab/-/issues/378717) propose de résoudre ce problème.

## Utiliser `rules` avec `include` {#use-rules-with-include}

Vous pouvez utiliser [`rules`](_index.md#rules) avec `include` pour inclure conditionnellement d'autres fichiers de configuration.

Vous ne pouvez utiliser `rules` qu'avec [certaines variables](#use-variables-with-include), et ces mots-clés :

- [`rules:if`](_index.md#rulesif).
- [`rules:exists`](_index.md#rulesexists).
- [`rules:changes`](_index.md#ruleschanges).

### `include` avec `rules:if` {#include-with-rulesif}

Utilisez [`rules:if`](_index.md#rulesif) pour inclure conditionnellement d'autres fichiers de configuration en fonction du statut des variables CI/CD. Par exemple :

```yaml
include:
  - local: builds.yml
    rules:
      - if: $DONT_INCLUDE_BUILDS == "true"
        when: never
  - local: builds.yml
    rules:
      - if: $ALWAYS_INCLUDE_BUILDS == "true"
        when: always
  - local: builds.yml
    rules:
      - if: $INCLUDE_BUILDS == "true"
  - local: deploys.yml
    rules:
      - if: $CI_COMMIT_BRANCH == "main"

test:
  stage: test
  script: exit 0
```

### `include` avec `rules:exists` {#include-with-rulesexists}

Utilisez [`rules:exists`](_index.md#rulesexists) pour inclure conditionnellement d'autres fichiers de configuration en fonction de l'existence de fichiers. Par exemple :

```yaml
include:
  - local: builds.yml
    rules:
      - exists:
          - exception-file.md
        when: never
  - local: builds.yml
    rules:
      - exists:
          - important-file.md
        when: always
  - local: builds.yml
    rules:
      - exists:
          - file.md

test:
  stage: test
  script: exit 0
```

Dans cet exemple, GitLab vérifie l'existence de `file.md` dans le projet actuel.

Vérifiez attentivement votre configuration si vous utilisez `include` avec `rules:exists` dans un fichier d'inclusion provenant d'un projet différent. GitLab vérifie l'existence du fichier dans l'autre projet. Par exemple :

```yaml
# Pipeline configuration in my-group/my-project
include:
  - project: my-group/other-project
    ref: other_branch
    file: other-file.yml

test:
  script: exit 0

# other-file.yml in my-group/other-project on ref other_branch
include:
  - project: my-group/my-project
    ref: main
    file: my-file.yml
    rules:
      - exists:
          - file.md
```

Dans cet exemple, GitLab recherche l'existence de `file.md` dans `my-group/other-project` sur le commit ref `other_branch`, et non dans le projet/ref dans lequel le pipeline s'exécute.

Pour modifier le contexte de recherche, vous pouvez utiliser [`rules:exists:paths`](_index.md#rulesexistspaths) avec [`rules:exists:project`](_index.md#rulesexistsproject). Par exemple :

```yaml
include:
  - project: my-group/my-project
    ref: main
    file: my-file.yml
    rules:
      - exists:
          paths:
            - file.md
          project: my-group/my-project
          ref: main
```

### `include` avec `rules:changes` {#include-with-ruleschanges}

Utilisez [`rules:changes`](_index.md#ruleschanges) pour inclure conditionnellement d'autres fichiers de configuration en fonction des fichiers modifiés. Par exemple :

```yaml
include:
  - local: builds1.yml
    rules:
      - changes:
        - Dockerfile
  - local: builds2.yml
    rules:
      - changes:
          paths:
            - Dockerfile
          compare_to: 'refs/heads/branch1'
        when: always
  - local: builds3.yml
    rules:
      - if: $CI_PIPELINE_SOURCE == "merge_request_event"
        changes:
          paths:
            - Dockerfile

test:
  stage: test
  script: exit 0
```

Dans cet exemple :

- `builds1.yml` est inclus lorsque `Dockerfile` a été modifié.
- `builds2.yml` est inclus lorsque `Dockerfile` a été modifié par rapport à `refs/heads/branch1`.
- `builds3.yml` est inclus lorsque `Dockerfile` a été modifié et que la source du pipeline est un événement de merge request. Les jobs dans `builds3.yml` doivent également être configurés pour s'exécuter pour les [pipelines de merge request](../pipelines/merge_request_pipelines.md#configure-merge-request-pipelines).

## Utiliser `include:local` avec des chemins de fichiers génériques {#use-includelocal-with-wildcard-file-paths}

Vous pouvez utiliser des chemins génériques (`*` et `**`) avec `include:local`.

Exemple :

```yaml
include: 'configs/*.yml'
```

Lors de l'exécution du pipeline, GitLab :

- Ajoute tous les fichiers `.yml` du répertoire `configs` dans la configuration du pipeline.
- N'ajoute pas les fichiers `.yml` dans les sous-dossiers du répertoire `configs`. Pour autoriser cela, ajoutez la configuration suivante :

  ```yaml
  # This matches all `.yml` files in `configs` and any subfolder in it.
  include: 'configs/**.yml'

  # This matches all `.yml` files only in subfolders of `configs`.
  include: 'configs/**/*.yml'
  ```

## Dépannage {#troubleshooting}

### Erreur `Maximum of 150 nested includes are allowed!` {#maximum-of-150-nested-includes-are-allowed-error}

Le nombre maximum de [fichiers inclus imbriqués](#use-nested-includes) pour un pipeline est de 150. Si vous recevez le message d'erreur `Maximum 150 includes are allowed` dans votre pipeline, il est probable que :

- Certaines configurations imbriquées incluent un nombre excessivement élevé de configurations `include` imbriquées supplémentaires.
- Il existe une boucle accidentelle dans les inclusions imbriquées. Par exemple, `include1.yml` inclut `include2.yml` qui inclut `include1.yml`, créant ainsi une boucle récursive.

Pour réduire le risque que cela se produise, modifiez le fichier de configuration du pipeline avec l'[éditeur de pipeline](../pipeline_editor/_index.md), qui valide si la limite est atteinte. Vous pouvez supprimer un fichier inclus à la fois pour essayer d'identifier quel fichier de configuration est à l'origine de la boucle ou des fichiers inclus en excès.

Les utilisateurs de GitLab Self-Managed peuvent modifier la valeur du [nombre maximum d'inclusions](../../administration/cicd/limits.md#maximum-number-of-includes).

### Erreur : `Local file <file> does not exist!` avec `include:local` {#error-local-file-file-does-not-exist-with-includelocal}

Vous pouvez recevoir une erreur `Local file <file> does not exist!` lors de l'utilisation de [`include:local`](_index.md#includelocal), même si le fichier existe dans le dépôt.

Cette erreur est un problème connu au niveau du système, et non un problème de configuration CI/CD. Elle a été observée de manière intermittente dans des configurations Gitaly ou Praefect distribuées. Si vous rencontrez cette erreur, relancez le pipeline.

Pour plus d'informations, consultez le [ticket 336789](https://gitlab.com/gitlab-org/gitlab/-/issues/336789).

### `SSL_connect SYSCALL returned=5 errno=0 state=SSLv3/TLS write client hello` et autres défaillances réseau {#ssl_connect-syscall-returned5-errno0-statesslv3tls-write-client-hello-and-other-network-failures}

Lors de l'utilisation de [`include:remote`](_index.md#includeremote), GitLab tente de récupérer le fichier distant via HTTP(S). Ce processus peut échouer en raison de divers problèmes de connectivité.

L'erreur `SSL_connect SYSCALL returned=5 errno=0 state=SSLv3/TLS write client hello` se produit lorsque GitLab ne parvient pas à établir une connexion HTTPS avec l'hôte distant. Ce problème peut survenir si l'hôte distant applique des limites de débit pour éviter de surcharger le serveur de requêtes.

Par exemple, le serveur [GitLab Pages](../../user/project/pages/_index.md) pour GitLab.com est soumis à des limites de débit. Des tentatives répétées de récupération de fichiers de configuration CI/CD hébergés sur GitLab Pages peuvent entraîner l'atteinte de la limite de débit et provoquer l'erreur. Vous devriez éviter d'héberger des fichiers de configuration CI/CD sur un site GitLab Pages.

Dans la mesure du possible, utilisez [`include:project`](_index.md#includeproject) pour récupérer des fichiers de configuration d'autres projets au sein de l'instance GitLab sans effectuer de requêtes HTTP(S) externes.
