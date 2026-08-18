---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utiliser des variables CI/CD dans les scripts de job
description: "Configuration, utilisation et sécurité."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Toutes les variables CI/CD sont définies en tant que variables d'environnement dans l'environnement du job. Vous pouvez utiliser des variables dans les scripts de job avec le formatage standard du shell de chaque environnement.

Pour accéder aux variables d'environnement, utilisez la syntaxe correspondant au shell de l'[exécuteur de votre runner](https://docs.gitlab.com/runner/executors/).

## Avec Bash et `sh` {#with-bash-and-sh}

Pour accéder aux variables d'environnement dans Bash, `sh` et les shells similaires, préfixez la variable CI/CD avec `$` :

```yaml
job_name:
  script:
    - echo "$CI_JOB_ID"
```

## Avec PowerShell {#with-powershell}

Pour accéder aux variables dans un environnement Windows PowerShell, y compris les variables d'environnement définies par le système, préfixez le nom de la variable avec `$env:` ou `$` :

```yaml
job_name:
  script:
    - echo $env:CI_JOB_ID
    - echo $CI_JOB_ID
    - echo $env:PATH
```

## Avec Windows Batch {#with-windows-batch}

Pour accéder aux variables CI/CD dans Windows Batch, entourez la variable avec `%` :

```yaml
job_name:
  script:
    - echo %CI_JOB_ID%
```

Vous pouvez également entourer la variable avec `!` pour l'[expansion différée](https://ss64.com/nt/delayedexpansion.html). L'expansion différée peut être nécessaire pour les variables contenant des espaces blancs ou des sauts de ligne :

```yaml
job_name:
  script:
    - echo !ERROR_MESSAGE!
```

## Dans les conteneurs de service {#in-service-containers}

Les [conteneurs de service](../docker/using_docker_images.md) peuvent utiliser des variables CI/CD, mais par défaut, ils ne peuvent accéder qu'aux [variables enregistrées dans le fichier `.gitlab-ci.yml`](_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file). Les variables [ajoutées dans l'interface utilisateur GitLab](_index.md#define-a-cicd-variable-in-the-ui) ne sont pas disponibles pour les conteneurs de service, car ces derniers ne sont pas approuvés par défaut.

Pour rendre disponible une variable définie dans l'interface utilisateur dans un conteneur de service, vous pouvez la réaffecter à une autre variable dans votre `.gitlab-ci.yml` :

```yaml
variables:
  SA_PASSWORD_YAML_FILE: $SA_PASSWORD_UI
```

La variable réaffectée ne peut pas avoir le même nom que la variable d'origine. Dans le cas contraire, elle ne sera pas développée.

## Prévenir les erreurs d'analyse {#prevent-parsing-errors}

Mettez entre guillemets les commandes de script et les valeurs de variables pour éviter les erreurs d'analyse YAML et shell :

- Mettez entre guillemets les commandes entières lorsqu'elles contiennent des deux-points (`:`) pour éviter que YAML ne les interprète comme des paires clé-valeur :

  ```yaml
  job_name:
    script:
      - 'echo "Status: Complete"'  # Single quotes prevent YAML colon parsing
  ```

- Mettez les variables entre guillemets lorsque leurs valeurs peuvent contenir des espaces ou des caractères spéciaux :

  ```yaml
  job_name:
    script:
      - echo "$FILE_PATH"          # Quote if FILE_PATH might have spaces
  ```

- Évitez les guillemets lorsque vous souhaitez que les variables se développent en arguments shell distincts :

  ```yaml
  job_name:
    variables:
      COMPILE_FLAGS: "-Wall -Werror -O2"
    script:
      - gcc $COMPILE_FLAGS main.c  # Expands to: gcc -Wall -Werror -O2 main.c
  ```

## Passer une variable d'environnement de la section `script` vers `artifacts` ou `cache` {#pass-an-environment-variable-from-the-script-section-to-artifacts-or-cache}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29391) dans GitLab 16.4.

{{< /history >}}

Utilisez `$GITLAB_ENV` pour utiliser les variables d'environnement définies dans la section `script` dans les mots-clés `artifacts` ou `cache`. Par exemple :

```yaml
build-job:
  stage: build
  script:
    - echo "ARCH=$(arch)" >> $GITLAB_ENV
    - touch some-file-$(arch)
  artifacts:
    paths:
      - some-file-$ARCH
```

## Stocker plusieurs valeurs dans une seule variable {#store-multiple-values-in-one-variable}

Vous ne pouvez pas créer une variable CI/CD qui soit un tableau de valeurs, mais vous pouvez utiliser des techniques de script shell pour un comportement similaire.

Par exemple, vous pouvez stocker plusieurs valeurs séparées par un espace dans une variable, puis itérer sur ces valeurs avec un script :

```yaml
job1:
  variables:
    FOLDERS: src test docs
  script:
    - |
      for FOLDER in $FOLDERS
        do
          echo "The path is root/${FOLDER}"
        done
```

## Utiliser des variables CI/CD dans d'autres variables {#use-cicd-variables-in-other-variables}

Vous pouvez utiliser des variables à l'intérieur d'autres variables :

```yaml
job:
  variables:
    FLAGS: '-al'
    LS_CMD: 'ls "$FLAGS"'
  script:
    - 'eval "$LS_CMD"'  # Executes 'ls -al'
```

### Dans le cadre d'une chaîne {#as-part-of-a-string}

Vous pouvez utiliser des variables dans le cadre d'une chaîne. Vous pouvez entourer les variables avec des accolades (`{}`) pour mieux distinguer le nom de la variable du texte environnant. Sans accolades, le texte adjacent est interprété comme faisant partie du nom de la variable. Par exemple :

```yaml
job:
  variables:
    FLAGS: '-al'
    DIR: 'path/to/directory'
    LS_CMD: 'ls "$FLAGS"'
    CD_CMD: 'cd "${DIR}_files"'
  script:
    - 'eval "$LS_CMD"'  # Executes 'ls -al'
    - 'eval "$CD_CMD"'  # Executes 'cd path/to/directory_files'
```

### Utiliser le caractère `$` dans les variables CI/CD {#use-the--character-in-cicd-variables}

Si vous ne souhaitez pas que le caractère `$` soit interprété comme le début d'une autre variable, utilisez `$$` à la place :

```yaml
job:
  variables:
    FLAGS: '-al'
    LS_CMD: 'ls "$FLAGS" $$TMP_DIR'
  script:
    - 'eval "$LS_CMD"'  # Executes 'ls -al $TMP_DIR'
```

Cela ne fonctionne pas lors du [passage d'une variable CI/CD à un pipeline downstream](../pipelines/downstream_pipelines_troubleshooting.md#variable-with--character-does-not-get-passed-to-a-downstream-pipeline-properly).

## Sujets connexes {#related-topics}

- [Passer des variables d'environnement aux jobs ultérieurs avec dotenv](dotenv_variables.md#pass-variables-to-later-jobs)
