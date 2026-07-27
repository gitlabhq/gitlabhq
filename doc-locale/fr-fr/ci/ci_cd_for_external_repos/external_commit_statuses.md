---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Statuts de commit externes
description: "Comment les systèmes CI/CD externes s'intègrent aux pipelines GitLab à l'aide des statuts de commit."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les statuts de commit externes permettent aux systèmes CI/CD externes tels que Jenkins, CircleCI ou des outils de déploiement personnalisés de s'intégrer aux pipelines GitLab. Les systèmes externes publient les statuts de commit vers GitLab, et les résultats des statuts apparaissent aux côtés des jobs CI/CD dans les merge requests et les vues de commit.

Lorsque des systèmes externes publient des statuts de commit à l'aide de l'[API Commits](../../api/commits.md#set-commit-pipeline-status), GitLab gère ces statuts en les ajoutant aux pipelines existants ou en créant de nouveaux pipelines pour les contenir.

## Sélection du pipeline {#pipeline-selection}

Lorsque vous publiez un statut de commit depuis un système externe, une approche de type « rechercher ou créer » est utilisée :

1. GitLab recherche le pipeline CI le plus récent avec le statut `non-archived` pour le SHA de commit et la ref donnés. Vous pouvez également effectuer une recherche directe d'un pipeline en incluant le paramètre `pipeline_id`.
1. Si GitLab trouve un pipeline approprié, il ajoute le nouveau statut de job à ce pipeline. Pour les jobs ajoutés aux pipelines existants, `CI_PIPELINE_SOURCE` correspond à la source du pipeline (par exemple, `push` ou `merge_request_event`).
1. Si aucun pipeline approprié n'existe, GitLab crée un nouveau pipeline pour contenir le job. Pour les nouveaux pipelines, `CI_PIPELINE_SOURCE` est `external`.

Les statuts de jobs externes apparaissent dans une étape `external` du pipeline, séparée des autres étapes GitLab CI/CD.

> [!warning]
> Lorsque des pipelines en double existent pour le même commit, le placement du statut externe devient ambigu. GitLab sélectionne le dernier pipeline à l'aide de `newest_first`, mais en cas de création simultanée de pipelines, cela peut entraîner l'apparition de statuts externes dans des pipelines inattendus ou leur invisibilité dans les vues de merge request.
>
> Configurez les [règles de workflow](../yaml/workflow.md) pour éviter les pipelines en double ou ciblez directement un pipeline avec `pipeline_id`.

## Mises à jour et nouvelles tentatives de job {#job-updates-and-retries}

Lorsque vous publiez des statuts de commit depuis des systèmes externes :

- Si un job avec le statut `running` ou `pending` portant le même `name`, le même `user` et le même `sha` existe déjà dans le pipeline cible, GitLab met à jour son statut.
  - Si un utilisateur différent met à jour un job portant le même `name`, le job fait l'objet d'une nouvelle tentative. Cela crée un nouveau job et masque l'ancien job du pipeline actuel.
- Vous pouvez relancer un job qui n'est ni à l'état `running` ni à l'état `pending`, portant le même `name` mais un `status` différent (par exemple, envoyer `success` pour un job marqué `failed`). Cela crée un nouveau job et masque l'ancien job du pipeline actuel.
- Différents services externes peuvent ajouter des jobs au même SHA et pipeline en utilisant un `name` de job unique.

Si une mise à jour est déjà en cours pour une combinaison SHA/ref, une erreur `409` est renvoyée. Relancez la requête pour gérer cette erreur.

## Dépannage {#troubleshooting}

### Statuts externes non visibles dans les merge requests {#external-statuses-not-visible-in-merge-requests}

Si les statuts CI externes n'apparaissent pas dans les pipelines de merge request :

1. Vérifiez si vous avez à la fois des pipelines de merge request et des pipelines de branche en cours d'exécution pour le même commit.
1. Vérifiez que vos [règles de workflow](../yaml/workflow.md) empêchent les pipelines en double.
1. Confirmez que le système externe publie vers la bonne ref.
1. Si le commit est associé à une merge request, assurez-vous que l'appel API cible le commit dans la branche source de la merge request.

Pour plus d'informations, voir [éviter les pipelines en double](../jobs/job_rules.md#avoid-duplicate-pipelines).
