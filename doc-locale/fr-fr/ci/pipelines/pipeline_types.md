---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Types de pipelines
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Plusieurs types de pipelines peuvent s'exécuter dans un projet, notamment :

- Pipelines de branche
- Pipelines de tag
- Pipelines de merge request
- Pipelines de résultats fusionnés
- Merge trains
- Pipelines de charge de travail (pour GitLab Duo Agent Platform uniquement)

Ces types de pipelines apparaissent tous dans l'onglet **Pipelines** d'une merge request.

## Pipeline de branche {#branch-pipeline}

Votre pipeline peut s'exécuter chaque fois que vous commitez des modifications sur une branche.

Ce type de pipeline est appelé *pipeline de branche*. Ils affichent un label `branch` dans les listes de pipelines.

Ce pipeline s'exécute par défaut. Aucune configuration n'est requise.

Les pipelines de branche :

- S'exécutent lorsque vous poussez un nouveau commit sur une branche.
- Ont accès à [certaines variables prédéfinies](../variables/predefined_variables.md).
- Ont accès aux [variables protégées](../variables/_index.md#protect-a-cicd-variable) et aux [runners protégés](../runners/configure_runners.md#prevent-runners-from-revealing-sensitive-information) lorsque la branche est une [branche protégée](../../user/project/repository/branches/protected.md).

## Pipeline de tag {#tag-pipeline}

Un pipeline peut s'exécuter chaque fois que vous créez ou poussez un nouveau [tag](../../user/project/repository/tags/_index.md).

Ce type de pipeline est appelé *pipeline de tag*. Ils affichent un label `tag` dans les listes de pipelines.

Ce pipeline s'exécute par défaut. Aucune configuration n'est requise.

Les pipelines de tag :

- S'exécutent lorsque vous créez ou poussez un nouveau tag vers votre dépôt.
- Ont accès à [certaines variables prédéfinies](../variables/predefined_variables.md).
- Ont accès aux [variables protégées](../variables/_index.md#protect-a-cicd-variable) et aux [runners protégés](../runners/configure_runners.md#prevent-runners-from-revealing-sensitive-information) lorsque le tag est un [tag protégé](../../user/project/protected_tags.md).

## Pipeline de merge request {#merge-request-pipeline}

Au lieu d'un pipeline de branche, vous pouvez configurer votre pipeline pour qu'il s'exécute chaque fois que vous apportez des modifications à la branche source dans une merge request.

Ce type de pipeline est appelé *pipeline de merge request*. Ils affichent un label `merge request` dans les listes de pipelines.

Les pipelines de merge request ne s'exécutent pas par défaut. Vous devez configurer les jobs dans le fichier `.gitlab-ci.yml` pour qu'ils s'exécutent en tant que pipelines de merge request.

Pour plus d'informations, voir [les pipelines de merge request](merge_request_pipelines.md).

## Pipeline de résultats fusionnés {#merged-results-pipeline}

Un *pipeline de résultats fusionnés* s'exécute sur le résultat de la branche source et de la branche cible fusionnées ensemble. Il s'agit d'un type de pipeline de merge request.

Ces pipelines ne s'exécutent pas par défaut. Vous devez configurer les jobs dans le fichier `.gitlab-ci.yml` pour qu'ils s'exécutent en tant que pipeline de merge request, et activer les pipelines de résultats fusionnés.

Ces pipelines affichent un label `merged results` dans les listes de pipelines.

Pour plus d'informations, voir [le pipeline de résultats fusionnés](merged_results_pipelines.md).

## Merge trains {#merge-trains}

Dans les projets avec de nombreuses fusions vers la branche par défaut, les modifications apportées dans différentes merge requests peuvent être en conflit les unes avec les autres. Utilisez les *merge trains* pour placer les merge requests dans une file d'attente. Chaque merge request est comparée aux autres merge requests antérieures afin de s'assurer qu'elles fonctionnent toutes ensemble.

Les merge trains diffèrent des pipelines de résultats fusionnés, car les pipelines de résultats fusionnés garantissent que les modifications fonctionnent avec le contenu de la branche par défaut, mais pas avec le contenu que d'autres personnes fusionnent en même temps.

Ces pipelines ne s'exécutent pas par défaut. Vous devez configurer les jobs dans le fichier `.gitlab-ci.yml` pour qu'ils s'exécutent en tant que pipeline de merge request, activer les pipelines de résultats fusionnés et activer les merge trains.

Ces pipelines affichent un label `merge train` dans les listes de pipelines.

Pour plus d'informations, voir [les merge trains](merge_trains.md).

## Pipeline de charge de travail {#workload-pipeline}

Les pipelines de charge de travail constituent l'environnement d'exécution des charges de travail de GitLab Duo Agent Platform.

Les pipelines de charge de travail :

- S'exécutent sur des références Git éphémères qui suivent cette convention de nommage : `refs/workloads/<identifier>`.
- Ont la source `duo_workflow` dans les listes de pipelines.
- Les références de charge de travail sont automatiquement supprimées lorsque le job du pipeline se termine ou échoue.

Un lien vers le pipeline de charge de travail est disponible depuis la session de l'agent ou de la plateforme.
