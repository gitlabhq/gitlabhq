---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Les scénarios de test dans GitLab peuvent aider vos équipes à créer des scénarios de test dans leur plateforme de développement existante.
title: Scénarios de test
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les scénarios de test intègrent la planification des tests directement dans vos workflows GitLab. Les équipes peuvent :

- Documenter les scénarios de test dans la même plateforme où elles gèrent le code.
- Suivre les exigences de test en parallèle des tâches de développement.
- Partager les plans de test entre les équipes d'implémentation et de test.
- Gérer la visibilité des scénarios de test grâce aux paramètres de confidentialité.
- Archiver et rouvrir les scénarios de test selon les besoins.

Les équipes utilisent les scénarios de test pour optimiser la collaboration entre les équipes de développement et de test, ce qui élimine le besoin d'outils externes de planification des tests.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour apprendre à utiliser les tickets et les epics afin de gérer vos exigences et vos besoins en matière de test tout en vous intégrant à vos workflows de développement, voir [Streamline Software Development : Integrating Requirements, Testing, and Development Workflows](https://www.youtube.com/watch?v=wbfWM4y2VmM).
<!-- Video published on 2024-02-21 -->

## Créer un scénario de test {#create-a-test-case}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Developer, Maintainer ou Owner.

Pour créer un scénario de test dans un projet GitLab :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Scénarios de test**.
1. Sélectionnez **Nouveau scénario de test**. Vous accédez au formulaire du nouveau scénario de test. Vous pouvez y saisir le titre du nouveau scénario, sa [description](../../user/markdown.md), joindre un fichier et attribuer des [labels](../../user/project/labels.md).
1. Sélectionnez **Envoyer un scénario de test**. Vous accédez à la vue du nouveau scénario de test.

## Afficher un scénario de test {#view-a-test-case}

Vous pouvez afficher tous les scénarios de test du projet dans la liste des scénarios de test. Filtrez la liste des tickets avec une requête de recherche, notamment par labels ou par titre du scénario de test.

Prérequis :

- Scénario de test non confidentiel dans un projet public : Vous n'avez pas besoin d'être membre du projet.
- Scénario de test non confidentiel dans un projet privé : Vous devez disposer du rôle Guest, Planificateur, Reporter, Developer, Maintainer ou Owner pour le projet.
- Scénario de test confidentiel (quelle que soit la visibilité du projet) : Vous devez disposer du rôle Planificateur, Reporter, Developer, Maintainer ou Owner pour le projet.

Pour afficher un scénario de test :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Scénarios de test**.
1. Sélectionnez le titre du scénario de test que vous souhaitez afficher. Vous accédez à la page du scénario de test.

![Page d'un scénario de test affichant le titre, la description, les labels et les options de la barre latérale.](img/test_case_show_v13_10.png)

## Modifier un scénario de test {#edit-a-test-case}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Vous pouvez modifier le titre et la description d'un scénario de test.

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Developer, Maintainer ou Owner.
- Les utilisateurs rétrogradés au rôle Guest peuvent continuer à modifier les scénarios de test qu'ils ont créés lorsqu'ils avaient un rôle supérieur.

Pour modifier un scénario de test :

1. [Affichez un scénario de test](#view-a-test-case).
1. Dans le coin supérieur droit, sélectionnez **Éditer**.
1. Modifiez le titre ou la description du scénario de test.
1. Sélectionnez **Sauvegarder les modifications**.

## Rendre un scénario de test confidentiel {#make-a-test-case-confidential}

{{< history >}}

- Introduit pour les scénarios de test [nouveaux](https://gitlab.com/gitlab-org/gitlab/-/issues/422121) et [existants](https://gitlab.com/gitlab-org/gitlab/-/issues/422120) dans GitLab 16.5.
- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Si vous travaillez sur un scénario de test contenant des informations privées, vous pouvez le rendre confidentiel.

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Developer, Maintainer ou Owner.

Pour rendre un scénario de test confidentiel :

- Lorsque vous [créez un scénario de test](#create-a-test-case) : sous **Confidentialité**, cochez la case **This test case is confidential**.
- Lorsque vous [modifiez un scénario de test](#edit-a-test-case) : dans la barre latérale droite, à côté de **Confidentialité**, sélectionnez **Éditer**, puis sélectionnez **Activer**.

Vous pouvez également utiliser [l'action rapide `/confidential`](../../user/project/quick_actions.md#confidential) aussi bien lors de la création d'un nouveau scénario de test que lors de la modification d'un scénario existant.

## Archiver un scénario de test {#archive-a-test-case}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Lorsque vous souhaitez arrêter d'utiliser un scénario de test, vous pouvez l'archiver. Vous pouvez [rouvrir un scénario de test archivé](#reopen-an-archived-test-case) ultérieurement.

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Developer, Maintainer ou Owner.

Pour archiver un scénario de test, sur la page du scénario de test, sélectionnez **Archive test case**.

Pour afficher les scénarios de test archivés :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Scénarios de test**.
1. Sélectionnez **Archivées**.

## Rouvrir un scénario de test archivé {#reopen-an-archived-test-case}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Si vous décidez de recommencer à utiliser un scénario de test archivé, vous pouvez le rouvrir.

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Developer, Maintainer ou Owner.

Pour rouvrir un scénario de test archivé :

1. [Affichez un scénario de test](#view-a-test-case).
1. Sélectionnez **Reopen test case**.
