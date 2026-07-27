---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Résolution des problèmes liés aux artefacts de job
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque vous travaillez avec des [artefacts de job](job_artifacts.md), vous pouvez rencontrer les problèmes suivants.

## Le job ne récupère pas certains artefacts {#job-does-not-retrieve-certain-artifacts}

Par défaut, les jobs récupèrent tous les artefacts des étapes précédentes, mais les jobs utilisant `dependencies` ou `needs` ne récupèrent pas par défaut les artefacts de tous les jobs.

Si vous utilisez ces mots-clés, les artefacts ne sont récupérés que depuis un sous-ensemble de jobs. Consultez la référence des mots-clés pour savoir comment récupérer des artefacts avec ces mots-clés :

- [`dependencies`](../yaml/_index.md#dependencies)
- [`needs`](../yaml/_index.md#needs)
- [`needs:artifacts`](../yaml/_index.md#needsartifacts)

## Les artefacts de job utilisent trop d'espace disque {#job-artifacts-use-too-much-disk-space}

Si les artefacts de job utilisent trop d'espace disque, consultez la [documentation d'administration des artefacts de job](../../administration/cicd/job_artifacts_troubleshooting.md#job-artifacts-using-too-much-disk-space).

## Message d'erreur `No files to upload` {#error-message-no-files-to-upload}

Ce message apparaît dans les job logs lorsque le runner ne trouve pas le fichier à télécharger. Soit le chemin d'accès au fichier est incorrect, soit le fichier n'a pas été créé. Vous pouvez consulter le job log pour trouver d'autres erreurs ou avertissements précisant le nom du fichier et la raison pour laquelle il n'a pas été généré.

Pour des job logs plus détaillés, vous pouvez [activer la journalisation de débogage CI/CD](../variables/variables_troubleshooting.md#enable-debug-logging) et relancer le job. Cette journalisation peut fournir davantage d'informations sur la raison pour laquelle le fichier n'a pas été créé.

## Message d'erreur `FATAL: invalid argument` lors du téléchargement d'un artefact dotenv sur un runner Windows {#error-message-fatal-invalid-argument-when-uploading-a-dotenv-artifact-on-a-windows-runner}

La commande PowerShell `echo` écrit des fichiers avec l'encodage UCS-2 LE BOM (Byte Order Mark), mais seul UTF-8 est pris en charge. Si vous essayez de créer un artefact [`dotenv`](../yaml/artifacts_reports.md) avec `echo`, cela provoque une erreur `FATAL: invalid argument`.

Utilisez plutôt PowerShell `Add-Content`, qui utilise UTF-8 :

```yaml
test-job:
  stage: test
  tags:
    - windows
  script:
    - echo "test job"
    - Add-Content -Path build.env -Value "MY_ENV_VAR=true"
  artifacts:
    reports:
      dotenv: build.env
```

## Les artefacts de job n'expirent pas {#job-artifacts-do-not-expire}

Si certains artefacts de job n'expirent pas comme prévu, vérifiez si le paramètre [**Conserver les artéfacts des jobs réussis les plus récents**](job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs) est activé.

Lorsque ce paramètre est activé, les artefacts de job issus du dernier pipeline réussi de chaque référence n'expirent pas et ne sont pas supprimés.

## Message d'erreur `This job could not start because it could not retrieve the needed artifacts.` {#error-message-this-job-could-not-start-because-it-could-not-retrieve-the-needed-artifacts}

Un job échoue au démarrage et renvoie ce message d'erreur s'il ne peut pas récupérer les artefacts attendus. Cette erreur est renvoyée dans les cas suivants :

- Les dépendances du job sont introuvables. Par défaut, les jobs des étapes ultérieures récupèrent les artefacts des jobs de toutes les étapes précédentes, de sorte que tous les jobs précédents sont considérés comme dépendants. Si le job utilise le mot-clé [`dependencies`](../yaml/_index.md#dependencies), seuls les jobs listés sont dépendants.
- Les artefacts ont déjà expiré. Vous pouvez définir une expiration plus longue avec [`artifacts:expire_in`](../yaml/_index.md#artifactsexpire_in).
- Le job ne peut pas accéder aux ressources concernées en raison d'autorisations insuffisantes.

Consultez ces étapes de résolution supplémentaires si le job utilise le mot-clé [`needs:artifacts`](../yaml/_index.md#needsartifacts) avec :

- [`needs:project`](#for-a-job-configured-with-needsproject)
- [`needs:pipeline:job`](#for-a-job-configured-with-needspipelinejob)

### Pour un job configuré avec `needs:project` {#for-a-job-configured-with-needsproject}

L'erreur `could not retrieve the needed artifacts.` peut se produire pour un job utilisant [`needs:project`](../yaml/_index.md#needsproject) avec une configuration similaire à :

```yaml
rspec:
  needs:
    - project: my-group/my-project
      job: dependency-job
      ref: master
      artifacts: true
```

Pour résoudre cette erreur, vérifiez que :

- Le projet `my-group/my-project` fait partie d'un groupe disposant d'un plan d'abonnement Premium.
- L'utilisateur qui exécute le job peut accéder aux ressources dans `my-group/my-project`.
- La combinaison `project`, `job` et `ref` existe et aboutit à la dépendance souhaitée.
- Toutes les variables utilisées sont évaluées avec les valeurs correctes.

Si vous utilisez le `CI_JOB_TOKEN`, ajoutez le jeton à la [liste d'autorisation](ci_job_token.md#control-job-token-access-to-your-project) du projet pour extraire des artefacts d'un autre projet.

### Pour un job configuré avec `needs:pipeline:job` {#for-a-job-configured-with-needspipelinejob}

L'erreur `could not retrieve the needed artifacts.` peut se produire pour un job utilisant [`needs:pipeline:job`](../yaml/_index.md#needspipelinejob) avec une configuration similaire à :

```yaml
rspec:
  needs:
    - pipeline: $UPSTREAM_PIPELINE_ID
      job: dependency-job
      artifacts: true
```

Pour résoudre cette erreur, vérifiez que :

- La variable CI/CD `$UPSTREAM_PIPELINE_ID` est disponible dans la hiérarchie de pipeline parent-enfant du pipeline actuel.
- La combinaison `pipeline` et `job` existe et se résout en un pipeline existant.
- `dependency-job` a été exécuté et s'est terminé avec succès.

## Les jobs affichent `UnlockPipelinesInQueueWorker` après une mise à niveau {#jobs-show-unlockpipelinesinqueueworker-after-an-upgrade}

Les jobs peuvent se bloquer et afficher une erreur indiquant `UnlockPipelinesInQueueWorker`.

Ce problème survient après une mise à niveau.

La solution de contournement consiste à activer le feature flag `ci_unlock_pipelines_extra_low`. Pour activer ou désactiver les feature flags, vous devez être administrateur.

Sur GitLab.com :

- Exécutez la commande [ChatOps](../chatops/_index.md) suivante :

  ```ruby
  /chatops gitlab run feature set ci_unlock_pipelines_extra_low true
  ```

Sur GitLab Self-Managed :

- [Activez le feature flag](../../administration/feature_flags/_index.md) nommé `ci_unlock_pipelines_extra_low`.

Pour plus d'informations, consultez le commentaire dans la [merge request 140318](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140318#note_1718600424).
