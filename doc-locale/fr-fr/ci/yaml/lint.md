---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisez l'outil CI Lint de GitLab pour valider la configuration CI/CD et simuler des pipelines afin de détecter les erreurs avant l'exécution des jobs."
title: Valider la configuration CI/CD de GitLab
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez l'outil CI Lint pour vérifier la validité de la configuration CI/CD de GitLab. Vous pouvez valider la syntaxe à partir d'un fichier `.gitlab-ci.yml` ou de tout autre exemple de configuration CI/CD. Cet outil vérifie les erreurs de syntaxe et de logique, et peut simuler la création d'un pipeline pour tenter de détecter des problèmes de configuration plus complexes.

Si vous utilisez l'[éditeur de pipeline](../pipeline_editor/_index.md), celui-ci vérifie automatiquement la syntaxe de la configuration.

Vous pouvez également valider la configuration CI/CD avec :

- L'[extension GitLab pour VS Code](../../editor_extensions/visual_studio_code/_index.md)
- L'[interface de ligne de commande GitLab (`glab`)](https://docs.gitlab.com/cli/ci/lint/)
- L'[endpoint de l'API CI lint](../../api/lint.md)

## Vérifier la syntaxe CI/CD {#check-cicd-syntax}

L'outil CI lint vérifie la syntaxe de la configuration GitLab CI/CD, y compris la configuration ajoutée avec le [mot-clé `includes`](_index.md#include).

Pour vérifier la configuration CI/CD avec l'outil CI lint :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Éditeur de pipeline**.
1. Sélectionnez l'onglet **Valider**.
1. Sélectionnez **Lint CI/CD sample**.
1. Collez une copie de la configuration CI/CD que vous souhaitez vérifier dans la zone de texte.
1. Sélectionnez **Valider**.

## Simuler un pipeline {#simulate-a-pipeline}

Vous pouvez simuler la création d'un pipeline GitLab CI/CD pour détecter des problèmes plus complexes, notamment des problèmes liés à la configuration de [`needs`](_index.md#needs) et de [`rules`](_index.md#rules). Une simulation s'exécute en tant qu'événement Git `push` sur la branche par défaut.

Prérequis :

- Vous devez disposer des [autorisations](../../user/permissions.md#project-permissions) nécessaires pour créer des pipelines sur cette branche afin de valider avec une simulation.

Pour simuler un pipeline :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Éditeur de pipeline**.
1. Sélectionnez l'onglet **Valider**.
1. Sélectionnez **Lint CI/CD sample**.
1. Collez une copie de la configuration CI/CD que vous souhaitez vérifier dans la zone de texte.
1. Sélectionnez **Simulate pipeline creation for the default branch**.
1. Sélectionnez **Valider**.
