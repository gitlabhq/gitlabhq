---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage des pipelines downstream
---

## Le job de déclenchement échoue et ne crée pas de pipeline multi-projets {#trigger-job-fails-and-does-not-create-multi-project-pipeline}

Avec les pipelines multi-projets, le job de déclenchement échoue et ne crée pas le pipeline downstream dans les cas suivants :

- Le projet downstream est introuvable.
- L'utilisateur qui crée le pipeline upstream ne dispose pas des [autorisations](../../user/permissions.md) nécessaires pour créer des pipelines dans le projet downstream.
- Le pipeline downstream cible une branche protégée et l'utilisateur n'est pas autorisé à exécuter des pipelines sur la branche protégée. Consultez [la sécurité des pipelines pour les branches protégées](_index.md#pipeline-security-on-protected-branches) pour plus d'informations.

Pour identifier l'utilisateur rencontrant des problèmes d'autorisations dans le projet downstream, vous pouvez vérifier le job de déclenchement à l'aide de la commande suivante dans la [console Rails](../../administration/operations/rails_console.md) et examiner l'attribut `user_id`.

```ruby
Ci::Bridge.find(<job_id>)
```

## Un job du pipeline enfant n'est pas créé lors de l'exécution du pipeline {#job-in-child-pipeline-is-not-created-when-the-pipeline-runs}

Si le pipeline parent est un [pipeline de merge request](merge_request_pipelines.md), le pipeline enfant doit [utiliser `workflow:rules` ou `rules` pour s'assurer que les jobs s'exécutent](downstream_pipelines.md#run-child-pipelines-with-merge-request-pipelines).

Si aucun job du pipeline enfant ne peut s'exécuter en raison d'une configuration `rules` manquante ou incorrecte :

- Le pipeline enfant ne parvient pas à démarrer.
- Le job de déclenchement du pipeline parent échoue avec : `downstream pipeline can not be created, the resulting pipeline would have been empty. Review the`[`rules`](../yaml/_index.md#rules)`configuration for the relevant jobs.`

## La variable avec le caractère `$` n'est pas transmise correctement à un pipeline downstream {#variable-with--character-does-not-get-passed-to-a-downstream-pipeline-properly}

Vous ne pouvez pas utiliser [`$$` pour échapper au caractère `$` dans une variable CI/CD](../variables/job_scripts.md#use-the--character-in-cicd-variables), lors du [passage d'une variable CI/CD à un pipeline downstream](downstream_pipelines.md#pass-cicd-variables-to-a-downstream-pipeline). Le pipeline downstream traite toujours le `$` comme le début d'une référence de variable.

Vous pouvez [empêcher l'expansion des variables CI/CD](../variables/_index.md#allow-cicd-variable-expansion) lors de la configuration d'une variable dans l'interface utilisateur, ou utiliser le [mot-clé `variables:expand`](../yaml/_index.md#variablesexpand) pour définir une valeur de variable qui ne sera pas développée. Cette variable peut ensuite être transmise au pipeline downstream sans que le `$` soit interprété comme une référence de variable.

## `Ref is ambiguous` {#ref-is-ambiguous}

Vous ne pouvez pas déclencher un pipeline multi-projets avec un tag lorsqu'une branche du même nom existe. La création du pipeline downstream échoue avec l'erreur : `downstream pipeline can not be created, Ref is ambiguous`.

Déclenchez uniquement des pipelines multi-projets avec des noms de tags qui ne correspondent pas à des noms de branches.

## Le job de déclenchement échoue avec `data integrity failure` {#trigger-job-fails-with-data-integrity-failure}

Cette erreur indique une exception inattendue lors du traitement du job. Pour en connaître les causes et les étapes de résolution, consultez [erreur : `data integrity failure`](../jobs/job_troubleshooting.md#error-data-integrity-failure).

## Erreur `403 Forbidden` lors du téléchargement d'un artefact de job depuis un pipeline upstream {#403-forbidden-error-when-downloading-a-job-artifact-from-an-upstream-pipeline}

Les tokens de job CI/CD ont une portée limitée au projet sous lequel le pipeline s'exécute. Par conséquent, le token de job d'un pipeline downstream ne peut pas être utilisé par défaut pour accéder à un projet upstream.

Pour résoudre ce problème, [ajoutez le projet downstream à la liste d'autorisation de la portée du token de job](../jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist).

## Erreur : `needs:need pipeline should be a string` {#error-needsneed-pipeline-should-be-a-string}

Lors de l'utilisation de [`needs:pipeline:job`](../yaml/_index.md#needspipelinejob) avec des pipelines enfants dynamiques, vous pourriez recevoir cette erreur :

```plaintext
Unable to run pipeline
- jobs:<job_name>:needs:need pipeline should be a string
```

Cette erreur se produit lorsqu'un identifiant de pipeline est analysé comme un entier au lieu d'une chaîne de caractères. Pour corriger ce problème, placez l'identifiant du pipeline entre guillemets :

```yaml
rspec:
  needs:
    - pipeline: "$UPSTREAM_PIPELINE_ID"
      job: dependency-job
      artifacts: true
```
