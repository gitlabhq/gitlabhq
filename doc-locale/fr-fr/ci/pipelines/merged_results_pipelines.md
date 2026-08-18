---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Utilisez les pipelines de résultats fusionnés pour tester le code des branches source et cible combinées avant la fusion.
title: Pipelines de résultats fusionnés
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les pipelines de résultats fusionnés testent un commit fusionné temporaire qui combine le code des branches source et cible. Ce commit n'existe dans aucune branche, mais vous pouvez le consulter dans les détails du pipeline.

Cette approche permet de vérifier que les modifications fonctionnent avec le code de la dernière branche cible, de détecter les problèmes d'intégration avant la fusion et de s'assurer que les modifications apportées à différents fichiers fonctionnent ensemble.

Les pipelines de résultats fusionnés ne peuvent pas s'exécuter lorsque la branche cible comporte des modifications qui entrent en conflit avec les modifications de la branche source. Dans ce cas, GitLab exécute à la place un pipeline de merge request standard.

## Activer les pipelines de résultats fusionnés {#enable-merged-results-pipelines}

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.
- Votre fichier `.gitlab-ci.yml` doit être configuré pour les [pipelines de merge request](merge_request_pipelines.md#prerequisites).
- Votre projet doit être hébergé sur GitLab (et non sur un dépôt externe tel que GitHub ou Bitbucket).

Pour activer les pipelines de résultats fusionnés dans un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Requêtes de fusion**.
1. Sous **Options de fusion**, sélectionnez **Activer les pipelines de résultats fusionnés**.
1. Sélectionnez **Sauvegarder les modifications**.

> [!warning]
> Si vous activez ce paramètre sans configurer les pipelines de merge request dans votre fichier `.gitlab-ci.yml`, vos merge requests risquent de rester bloquées dans un état non résolu ou vos pipelines risquent d'être abandonnés.

## Dépannage {#troubleshooting}

Lorsque vous utilisez des pipelines de résultats fusionnés, vous pouvez rencontrer les problèmes suivants.

### Des jobs ou des pipelines s'exécutent de manière inattendue avec `rules:changes:compare_to` {#jobs-or-pipelines-run-unexpectedly-with-ruleschangescompare_to}

Il se peut que certains jobs ou pipelines s'exécutent de manière inattendue lors de l'utilisation de `rules:changes:compare_to` avec des pipelines de merge request.

Ce problème survient car les pipelines de résultats fusionnés utilisent le commit fusionné temporaire comme base de comparaison. Ce commit contient des modifications provenant à la fois de la branche de votre merge request et de la branche cible, ce qui peut entraîner un déclenchement inattendu des règles.

Par exemple, si votre merge request ajoute `src/feature.js` et que la branche cible contient `src/utils.js`, le commit fusionné temporaire inclut les deux fichiers. Une règle avec `rules:changes:compare_to: main` détecte les deux modifications, pas seulement votre fichier de fonctionnalité, et peut déclencher des jobs qui ne devraient s'exécuter que pour vos modifications.

Pour résoudre ce problème :

- Supprimez le paramètre `compare_to` pour utiliser le comportement de comparaison par défaut.
- Utilisez des modèles de chemin de fichier plus spécifiques dans vos règles de modifications.
- Envisagez d'utiliser `rules:changes` sans `compare_to`.

### Un pipeline de résultats fusionnés réussi remplace un pipeline de branche échoué {#successful-merged-results-pipeline-overrides-a-failed-branch-pipeline}

Vous pourriez rencontrer une situation où un pipeline de branche échoué est ignoré lorsque le [paramètre **Les pipelines doivent réussir**](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge) est activé.

Ce problème survient en raison de la priorisation de la logique de pipeline. La prise en charge des améliorations est proposée dans le [ticket 385841](https://gitlab.com/gitlab-org/gitlab/-/issues/385841).
