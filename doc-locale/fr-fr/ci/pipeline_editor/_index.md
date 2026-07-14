---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Éditeur de pipeline
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

L'éditeur de pipeline est l'emplacement principal pour modifier la configuration GitLab CI/CD dans le fichier `.gitlab-ci.yml` à la racine de votre dépôt. Pour accéder à l'éditeur, rendez-vous dans **Version** > **Éditeur de pipeline**.

Depuis la page de l'éditeur de pipeline, vous pouvez :

- Sélectionner la branche sur laquelle travailler.
- [Valider](#validate-cicd-syntax) la syntaxe de votre configuration pendant la modification du fichier.
- Effectuer une [validation approfondie de votre configuration](#validate-cicd-configuration), qui la vérifie avec toute configuration ajoutée avec le mot-clé [`include`](../yaml/_index.md#include).
- Afficher une [liste de la configuration CI/CD ajoutée avec le mot-clé `include`](#view-included-cicd-configuration).
- Consulter une [visualisation](#visualize-ci-configuration) de la configuration actuelle.
- Afficher la [configuration complète](#view-full-configuration), qui présente la configuration avec toute configuration issue de `include` ajoutée.
- [Committer](#commit-changes-to-ci-configuration) les modifications dans une branche spécifique.

## Valider la syntaxe CI/CD {#validate-cicd-syntax}

Lorsque vous utilisez l'éditeur de pipeline, la syntaxe de configuration du pipeline est continuellement validée par rapport au schéma de pipeline CI/CD GitLab. La syntaxe de votre YAML CI/CD ainsi que certaines validations logiques de base sont vérifiées.

Le résultat de cette validation s'affiche en haut de la page de l'éditeur. Si la validation échoue, cette section affiche un conseil pour vous aider à résoudre le problème.

## Valider la configuration CI/CD {#validate-cicd-configuration}

{{< history >}}

- Option permettant de sélectionner différentes branches [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/482676) dans GitLab 18.4.

{{< /history >}}

Pour tester la validité de votre configuration GitLab CI/CD avant de committer les modifications, utilisez l'outil de validation de l'éditeur de pipeline. Cet outil simule la création d'un pipeline suite à un événement Git push, et peut aider à résoudre les problèmes de logique, notamment les dépendances de jobs incorrectes avec `rules` et `needs` :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Éditeur de pipeline**.
1. Sélectionnez l'onglet **Valider**.
1. Facultatif. Sélectionnez une autre branche à utiliser pour l'événement push simulé en utilisant la liste déroulante **Source d'exécution du pipeline**.
1. Sélectionnez **Valider le pipeline**.

Le pipeline simulé utilise la configuration de pipeline existante depuis l'onglet **Éditer**.

Pour valider un extrait YAML CI/CD sans l'ajouter à l'onglet **Éditer**, utilisez plutôt l'[outil CI Lint](../yaml/lint.md#simulate-a-pipeline).

## Afficher la configuration CI/CD incluse {#view-included-cicd-configuration}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/7064) dans GitLab 15.0 [avec un flag](../../administration/feature_flags/_index.md) nommé `pipeline_editor_file_tree`. Désactivé par défaut.
- [Feature flag supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/357219) dans GitLab 15.1.

{{< /history >}}

Vous pouvez consulter la configuration ajoutée avec le mot-clé [`include`](../yaml/_index.md#include) dans l'éditeur de pipeline. Dans le coin supérieur droit, sélectionnez l'arborescence de fichiers ({{< icon name="file-tree" >}}) pour afficher la liste de tous les fichiers de configuration inclus. Les fichiers sélectionnés s'ouvrent dans un nouvel onglet pour consultation.

## Visualiser la configuration CI {#visualize-ci-configuration}

Pour afficher une visualisation de votre configuration `.gitlab-ci.yml`, dans votre projet, rendez-vous dans **Version** > **Éditeur de pipeline**, puis sélectionnez l'onglet **Visualiser**. La visualisation affiche toutes les étapes et tous les jobs. Toutes les relations [`needs`](../yaml/_index.md#needs) sont représentées par des lignes reliant les jobs entre eux, montrant la hiérarchie d'exécution.

Survolez un job pour mettre en évidence ses relations `needs` :

![Visualisation de la configuration CI/CD au survol](img/ci_config_visualization_hover_v17_9.png)

Si la configuration ne comporte aucune relation `needs`, aucune ligne n'est tracée, car chaque job dépend uniquement de la réussite de l'étape précédente.

## Afficher la configuration complète {#view-full-configuration}

{{< history >}}

- L'onglet **Voir les fichiers YAML fusionnés** [renommé en **Configuration complète**](https://gitlab.com/gitlab-org/gitlab/-/issues/377404) dans GitLab 16.0.

{{< /history >}}

Pour afficher la configuration CI/CD entièrement développée sous la forme d'un fichier combiné, accédez à l'onglet **Configuration complète** de l'éditeur de pipeline. Cet onglet affiche une configuration développée où :

- La configuration importée avec [`include`](../yaml/_index.md#include) est copiée dans la vue.
- Les jobs qui utilisent [`extends`](../yaml/_index.md#extends) s'affichent avec la [configuration étendue fusionnée dans le job](../yaml/yaml_optimization.md#merge-details).
- Les [ancres YAML](../yaml/yaml_optimization.md#anchors) sont remplacées par la configuration liée.
- Les [tags YAML `!reference`](../yaml/yaml_optimization.md#reference-tags) sont également remplacés par la configuration liée.
- Les règles conditionnelles sont évaluées en supposant un événement push sur la branche par défaut.

L'utilisation des tags `!reference` peut entraîner une configuration imbriquée qui s'affiche avec plusieurs tirets (`-`) en début de ligne dans la vue développée. Ce comportement est attendu, et les tirets supplémentaires n'affectent pas l'exécution du job. Par exemple, cette configuration et sa version entièrement développée sont toutes deux valides :

- Fichier `.gitlab-ci.yml` :

  ```yaml
  .python-req:
    script:
      - pip install pyflakes

  .rule-01:
    rules:
      - if: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/
        when: manual
        allow_failure: true
      - if: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME

  .rule-02:
    rules:
      - if: $CI_COMMIT_BRANCH == "main"
        when: manual
        allow_failure: true

  lint-python:
    image: python:latest
    script:
      - !reference [.python-req, script]
      - pyflakes python/
    rules:
      - !reference [.rule-01, rules]
      - !reference [.rule-02, rules]
  ```

- Configuration développée dans l'onglet **Configuration complète** :

  ```yaml
  ".python-req":
    script:
    - pip install pyflakes
  ".rule-01":
    rules:
    - if: "$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/"
      when: manual
      allow_failure: true
    - if: "$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME"
  ".rule-02":
    rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: manual
      allow_failure: true
  lint-python:
    image: python:latest
    script:
    - - pip install pyflakes                                     # <- The extra hyphens do not affect the job's execution.
    - pyflakes python/
    rules:
    - - if: "$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/" # <- The extra hyphens do not affect the job's execution.
        when: manual
        allow_failure: true
      - if: "$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME"               # <- No extra hyphen but aligned with previous rule
    - - if: $CI_COMMIT_BRANCH == "main"                          # <- The extra hyphens do not affect the job's execution.
        when: manual
        allow_failure: true
  ```

## Committer les modifications dans la configuration CI {#commit-changes-to-ci-configuration}

Le formulaire de commit apparaît en bas de chaque onglet de l'éditeur, afin que vous puissiez committer vos modifications à tout moment.

Lorsque vous êtes satisfait de vos modifications, ajoutez un message de commit descriptif et saisissez une branche. Le champ de branche est défini par défaut sur la branche par défaut de votre projet.

Si vous saisissez un nouveau nom de branche, la case à cocher **Démarrer une nouvelle merge request avec ces modifications** apparaît. Sélectionnez-la pour démarrer un nouveau merge request après avoir commité les modifications.

![Le formulaire de commit, affichant un message de commit, une branche et la case à cocher de merge request.](img/pipeline_editor_commit_v18_8.png)

## Options d'accessibilité de l'éditeur {#editor-accessibility-options}

L'éditeur de pipeline est basé sur l'[éditeur Monaco](https://github.com/microsoft/monaco-editor), qui dispose de plusieurs [fonctionnalités d'accessibilité](https://github.com/microsoft/monaco-editor/wiki/Monaco-Editor-Accessibility-Guide), notamment :

| Fonctionnalité                          | Raccourci sur Windows ou Linux      | Raccourci sur macOS                                    | Détails |
|----------------------------------|-----------------------------------|------------------------------------------------------|---------|
| Liste des commandes de navigation au clavier | <kbd>F1</kbd>                     | <kbd>F1</kbd>                                        | Une [liste de commandes](https://github.com/microsoft/monaco-editor/wiki/Monaco-Editor-Accessibility-Guide#keyboard-navigation) qui facilitent l'utilisation de l'éditeur sans souris. |
| Capture de tabulation                     | <kbd>Control</kbd>+<kbd>m</kbd> | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>m</kbd> | Activez la [capture de tabulation](https://github.com/microsoft/monaco-editor/wiki/Monaco-Editor-Accessibility-Guide#tab-trapping) pour accéder à l'élément focalisable suivant sur la page au lieu d'insérer un caractère de tabulation. |

## Dépannage {#troubleshooting}

### Message `Unable to validate CI/CD configuration.` {#unable-to-validate-cicd-configuration-message}

Ce message est dû à un problème de validation de la syntaxe dans l'éditeur de pipeline. Cela peut se produire lorsque GitLab est incapable de communiquer avec le service qui valide la syntaxe.

Les informations contenues dans ces sections peuvent ne pas s'afficher correctement :

- Le statut de syntaxe dans l'onglet **Éditer** (valide ou invalide).
- L'onglet **Visualiser**.
- L'onglet **Lint**.
- L'onglet **Configuration complète**.

Vous pouvez continuer à travailler sur votre configuration CI/CD et committer les modifications effectuées sans aucun problème. Dès que le service redevient disponible, la validation de la syntaxe devrait s'afficher immédiatement.
