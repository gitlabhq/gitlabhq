---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage des scripts et job logs
---

## `Syntax is incorrect` dans les scripts qui utilisent `:` {#syntax-is-incorrect-in-scripts-that-use-}

Si vous utilisez un deux-points (`:`) dans un script, GitLab peut afficher :

- `Syntax is incorrect`
- `script config should be a string or a nested array of strings up to 10 levels deep`

Par exemple, si vous utilisez `"PRIVATE-TOKEN: ${PRIVATE_TOKEN}"` dans le cadre d'une commande cURL :

```yaml
pages-job:
  stage: deploy
  script:
    - curl --header 'PRIVATE-TOKEN: ${PRIVATE_TOKEN}' "https://gitlab.example.com/api/v4/projects"
  environment: production
```

Le parseur YAML considère que `:` définit un mot-clé YAML et génère l'erreur `Syntax is incorrect`.

Pour utiliser des commandes contenant un deux-points, vous devez encapsuler la commande entière entre guillemets simples. Vous devrez peut-être remplacer les guillemets simples existants (`'`) par des guillemets doubles (`"`) :

```yaml
pages-job:
  stage: deploy
  script:
    - 'curl --header "PRIVATE-TOKEN: ${PRIVATE_TOKEN}" "https://gitlab.example.com/api/v4/projects"'
  environment: production
```

## Le job n'échoue pas lors de l'utilisation de `&&` dans un script {#job-does-not-fail-when-using--in-a-script}

Si vous utilisez `&&` pour combiner deux commandes dans une seule ligne de script, le job peut se terminer avec succès, même si l'une des commandes a échoué. Par exemple :

```yaml
job-does-not-fail:
  script:
    - invalid-command xyz && invalid-command abc
    - echo $?
    - echo "The job should have failed already, but this is executed unexpectedly."
```

L'opérateur `&&` retourne un code de sortie `0` même si les deux commandes ont échoué, et le job continue de s'exécuter. Pour forcer le script à se terminer lorsque l'une ou l'autre des commandes échoue, encapsulez la ligne entière entre parenthèses :

```yaml
job-fails:
  script:
    - (invalid-command xyz && invalid-command abc)
    - echo "The job failed already, and this is not executed."
```

## Les commandes multiligne ne sont pas préservées par le scalaire de bloc YAML multilignes replié {#multiline-commands-not-preserved-by-folded-yaml-multiline-block-scalar}

Si vous utilisez le scalaire de bloc YAML multilignes replié `- >` pour fractionner des commandes longues, une indentation supplémentaire entraîne le traitement des lignes comme des commandes individuelles.

Par exemple :

```yaml
script:
  - >
    RESULT=$(curl --silent
      --header
        "Authorization: Bearer $CI_JOB_TOKEN"
      "${CI_API_V4_URL}/job"
    )
```

Cela échoue car l'indentation entraîne la préservation des sauts de ligne :

```plaintext
$ RESULT=$(curl --silent # collapsed multi-line command
curl: no URL specified!
curl: try 'curl --help' or 'curl --manual' for more information
/bin/bash: line 149: --header: command not found
/bin/bash: line 150: https://gitlab.example.com/api/v4/job: No such file or directory
```

Pour résoudre ce problème, procédez de l'une des façons suivantes :

- Supprimez l'indentation supplémentaire :

  ```yaml
  script:
    - >
      RESULT=$(curl --silent
      --header
      "Authorization: Bearer $CI_JOB_TOKEN"
      "${CI_API_V4_URL}/job"
      )
  ```

- Modifiez le script pour gérer les sauts de ligne supplémentaires, par exemple en utilisant la continuation de ligne shell :

  ```yaml
  script:
    - >
      RESULT=$(curl --silent \
        --header \
          "Authorization: Bearer $CI_JOB_TOKEN" \
        "${CI_API_V4_URL}/job")
  ```

## La sortie du job log n'est pas formatée comme prévu ou contient des caractères inattendus {#job-log-output-is-not-formatted-as-expected-or-contains-unexpected-characters}

Parfois, le formatage dans le job log s'affiche incorrectement avec des outils qui dépendent de la variable d'environnement `TERM` pour la colorisation ou le formatage. Par exemple, avec la commande `mypy` :

![Exemple de sortie](img/incorrect_log_rendering_v16_5.png)

GitLab Runner exécute le shell du conteneur en mode non interactif, de sorte que la variable d'environnement `TERM` du shell est définie sur `dumb`. Pour corriger le formatage pour ces outils, vous pouvez :

- Ajoutez une ligne de script supplémentaire pour définir `TERM=ansi` dans l'environnement du shell avant d'exécuter la commande.
- Ajoutez une [variable CI/CD](../variables/_index.md) `TERM` avec la valeur `ansi`.

## L'exécution de la section `after_script` s'arrête prématurément et les valeurs `$CI_JOB_STATUS` sont incorrectes {#after_script-section-execution-stops-early-and-incorrect-ci_job_status-values}

Dans GitLab Runner 16.9.0 à 16.11.0 :

- L'exécution de la section `after_script` s'arrête parfois trop tôt.
- Le statut de la variable prédéfinie `$CI_JOB_STATUS` est [défini de manière incorrecte sur `failed` pendant l'annulation du job](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37485).
