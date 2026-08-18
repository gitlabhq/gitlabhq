---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Résolution des problèmes liés aux pipelines de merge request
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque vous travaillez avec des pipelines de merge request, vous pouvez rencontrer les problèmes suivants.

## Deux pipelines lors d'un push vers une branche {#two-pipelines-when-pushing-to-a-branch}

Si vous obtenez des pipelines en double dans des merge requests, votre pipeline est peut-être configuré pour s'exécuter à la fois pour les branches et les merge requests en même temps. Ajustez la configuration de votre pipeline pour [éviter les pipelines en double](../jobs/job_rules.md#avoid-duplicate-pipelines).

Vous pouvez ajouter `workflow:rules` pour [passer des pipelines de branche aux pipelines de merge request](../yaml/workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines). Lorsqu'une merge request est ouverte sur la branche, le pipeline bascule vers un pipeline de merge request.

## Deux pipelines lors du push d'un fichier de configuration CI/CD invalide {#two-pipelines-when-pushing-an-invalid-cicd-configuration-file}

Si vous poussez une configuration CI/CD invalide vers la branche d'une merge request, deux pipelines en échec apparaissent dans l'onglet des pipelines. L'un est un pipeline de branche en échec, l'autre est un pipeline de merge request en échec.

Lorsque la syntaxe de configuration est corrigée, aucun autre pipeline en échec ne devrait apparaître. Pour identifier et corriger le problème de configuration, vous pouvez utiliser :

- L'[éditeur de pipeline](../pipeline_editor/_index.md).
- L'[outil CI lint](../yaml/lint.md).

## Le pipeline de la merge request est marqué comme échoué mais le dernier pipeline a réussi {#the-merge-requests-pipeline-is-marked-as-failed-but-the-latest-pipeline-succeeded}

Il est possible d'avoir à la fois des pipelines de branche et des pipelines de merge request dans l'onglet **Pipelines** d'une même merge request. Cela peut être [intentionnel (par configuration)](../yaml/workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines) ou [accidentel](#two-pipelines-when-pushing-to-a-branch).

Lorsque le projet a l'option [**Les pipelines doivent réussir**](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge) activée et que les deux types de pipelines sont présents, les pipelines de merge request sont vérifiés, et non les pipelines de branche.

Par conséquent, le résultat du pipeline de la merge request est marqué comme non réussi si le **merge request pipeline** échoue, indépendamment du résultat du **branch pipeline**.

Cependant :

- Ces conditions ne sont pas appliquées.
- Une condition de concurrence détermine quel résultat de pipeline est utilisé pour bloquer ou autoriser les merge requests.

Ce bug est suivi dans le [ticket 384927](https://gitlab.com/gitlab-org/gitlab/-/issues/384927).

## `An error occurred while trying to run a new pipeline for this merge request.` {#an-error-occurred-while-trying-to-run-a-new-pipeline-for-this-merge-request}

Cette erreur peut survenir lorsque vous sélectionnez **Exécuter le pipeline** dans une merge request, mais que le projet n'a plus les pipelines de merge request activés.

Voici quelques raisons possibles pour ce message d'erreur :

- Le projet n'a pas les pipelines de merge request activés, ne liste aucun pipeline dans l'onglet **Pipelines**, et vous sélectionnez **Run pipelines**.
- Le projet avait auparavant les pipelines de merge request activés, mais la configuration a été supprimée. Par exemple :

  1. Le projet a les pipelines de merge request activés dans le fichier de configuration `.gitlab-ci.yml` au moment de la création de la merge request.
  1. L'option **Exécuter le pipeline** est disponible dans l'onglet **Pipelines** de la merge request, et sélectionner **Exécuter le pipeline** à ce stade ne génère probablement aucune erreur.
  1. Le fichier `.gitlab-ci.yml` du projet est modifié pour supprimer la configuration des pipelines de merge request.
  1. La branche est rebasée pour intégrer la configuration mise à jour dans la merge request.
  1. Désormais, la configuration du pipeline ne prend plus en charge les pipelines de merge request, mais vous sélectionnez **Exécuter le pipeline** pour exécuter un pipeline de merge request.

Si **Exécuter le pipeline** est disponible mais que le projet n'a pas les pipelines de merge request activés, n'utilisez pas cette option. Vous pouvez pousser un commit ou rebaser la branche pour déclencher de nouveaux pipelines de branche.

## Message `Merge blocked: pipeline must succeed. Push a new commit that fixes the failure` {#merge-blocked-pipeline-must-succeed-push-a-new-commit-that-fixes-the-failure-message}

Ce message s'affiche si le pipeline de merge request, le [pipeline de résultats fusionnés](merged_results_pipelines.md) ou le [pipeline de merge train](merge_trains.md) a échoué ou a été annulé. Cela ne se produit pas lorsqu'un pipeline de branche échoue.

Si un pipeline de merge request ou un pipeline de résultats fusionnés a été annulé ou a échoué, vous pouvez :

- Réexécuter l'intégralité du pipeline en sélectionnant **Exécuter le pipeline** dans l'onglet pipeline de la merge request.
- [Relancer uniquement les jobs ayant échoué](_index.md#view-pipelines). Si vous réexécutez l'intégralité du pipeline, cela n'est pas nécessaire.
- Pousser un nouveau commit pour corriger l'échec.

Si le pipeline de merge train a échoué, vous pouvez :

- Vérifier l'échec et déterminer si vous pouvez utiliser l'[action rapide `/merge`](../../user/project/quick_actions.md#merge) pour rajouter immédiatement la merge request au train.
- Réexécuter l'intégralité du pipeline en sélectionnant **Exécuter le pipeline** dans l'onglet pipeline de la merge request, puis rajouter la merge request au train.
- Pousser un commit pour corriger l'échec, puis rajouter la merge request au train.

Si le pipeline de merge train a été annulé avant que la merge request ne soit fusionnée, sans échec, vous pouvez :

- L'ajouter à nouveau au train.
