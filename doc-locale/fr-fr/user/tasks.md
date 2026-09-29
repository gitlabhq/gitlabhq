---
stage: Plan
group: Work Items
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: Tâches
description: "Labels de tâche, tâches confidentielles, éléments liés et poids des tâches."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Une tâche dans GitLab est un élément de planification qui peut être créé dans un ticket. Utilisez les tâches pour décomposer les user stories capturées dans les [tickets](project/issues/_index.md) en éléments plus petits et traçables.

Lors de la planification d'un ticket, vous avez besoin d'un moyen de capturer et de décomposer les exigences techniques ou les étapes nécessaires à sa réalisation. Un ticket avec des tâches associées est mieux défini, ce qui vous permet de fournir un poids de ticket et des critères d'achèvement plus précis.

Pour les dernières mises à jour, consultez le [roadmap des tâches](https://gitlab.com/groups/gitlab-org/-/epics/7103).

Les tâches sont un type d'élément de travail, une étape vers les [types de tickets par défaut](https://gitlab.com/gitlab-org/gitlab/-/issues/323404) dans GitLab. Pour le roadmap de migration des tickets et des [epics](group/epics/_index.md) vers les éléments de travail et l'ajout de types d'éléments de travail personnalisés, consultez l'[epic 6033](https://gitlab.com/groups/gitlab-org/-/work_items/6033).

## Afficher les tâches {#view-tasks}

Affichez les tâches dans les tickets, dans la section **Éléments enfants**.

Vous pouvez également [filtrer la liste des éléments de travail](work_items/_index.md#filter-work-items) pour `Type = task`.

Lorsque vous sélectionnez une tâche à partir d'un ticket ou de la liste **Éléments de travail**, celle-ci s'ouvre dans un panneau de détails sur le côté droit de l'écran. Sur les écrans plus petits, ce panneau chevauche la page.

Pour ouvrir une tâche en vue plein écran :

- Ouvrez-la dans un nouvel onglet du navigateur en faisant un clic droit sur la tâche, ou en maintenant <kbd>Command</kbd> ou <kbd>Control</kbd> enfoncé et en la sélectionnant.
- Dans le coin supérieur droit du panneau de détails, sélectionnez **Ouvrir en plein écran** ({{< icon name="maximize" >}}).

## Créer une tâche {#create-a-task}

{{< history >}}

- Option permettant de sélectionner le projet dans lequel les tâches sont créées [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/436255) dans GitLab 17.1.

{{< /history >}}

Prérequis :

- Vous devez disposer du rôle Invité, Planificateur, Reporter, Developer, Maintainer ou Owner pour le projet, ou le projet doit être public.

Pour créer une tâche :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**.
1. Dans le coin supérieur droit, sélectionnez **Nouvel élément**.
1. Dans la liste déroulante **Type**, sélectionnez **Task** si cette option n'est pas déjà sélectionnée.
1. Complétez les champs suivants :
   - Saisissez le titre de la tâche.
   - Saisissez une description de la tâche.
   - Facultatif. Dans la barre latérale de la boîte de dialogue, sélectionnez un **Parent** [projet](project/organize_work_with_projects.md) pour la nouvelle tâche.
1. Sélectionnez **Créer une tâche**.

### À partir d'un élément de liste de tâches {#from-a-task-list-item}

Prérequis :

- Vous devez disposer du rôle Invité, Planificateur, Reporter, Developer, Maintainer ou Owner pour le projet.

Pour convertir un élément de liste de tâches dans une description de ticket en tâche :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Ticket** et sélectionnez votre ticket.
1. Dans la description du ticket, survolez l'élément de liste de tâches et sélectionnez le menu d'options ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Convertir en élément enfant**.
1. Facultatif. Modifiez le titre de la tâche et ajoutez une description.
1. Sélectionnez **Créer une tâche**.

L'élément de liste de tâches est supprimé de la description du ticket et ajouté à la section **Éléments enfants**. Les éléments de liste de tâches imbriqués sont remontés d'un niveau d'imbrication.

## Ajouter des tâches existantes à un ticket {#add-existing-tasks-to-an-issue}

Prérequis :

- Vous devez disposer du rôle Invité, Planificateur, Reporter, Developer, Maintainer ou Owner pour le projet, ou le projet doit être public.

Pour ajouter une tâche existante à un ticket :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Ticket** et sélectionnez votre ticket.
1. Dans la description du ticket, dans la section **Éléments enfants**, sélectionnez **Ajouter** ({{< icon name="plus" >}}).
1. Sélectionnez **Tâche existante**.
1. Recherchez des tâches par titre.
1. Sélectionnez une ou plusieurs tâches à ajouter au ticket.
1. Sélectionnez **Ajouter une tâche**.

## Modifier une tâche {#edit-a-task}

{{< history >}}

- Rôle utilisateur minimum [modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Developer, Maintainer ou Owner pour le projet.

Pour modifier une tâche :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Task** et sélectionnez votre tâche.
1. Dans le coin supérieur droit, sélectionnez **Éditer**.
1. Facultatif. Pour modifier le titre, saisissez du texte dans la zone de texte **Titre**.
1. Facultatif. Pour modifier la description, apportez vos modifications dans la zone de texte **Description**.
1. Sélectionnez **Enregistrer les modifications**.
1. Sélectionnez l'icône de fermeture ({{< icon name="close" >}}).

### Utilisation de l'éditeur de texte enrichi {#using-the-rich-text-editor}

{{< history >}}

- Rôle utilisateur minimum [modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Utilisez un éditeur de texte enrichi pour modifier la description d'une tâche.

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Developer, Maintainer ou Owner pour le projet.

Pour modifier la description d'une tâche :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Task** et sélectionnez votre tâche.
1. Dans le coin supérieur droit, sélectionnez **Éditer**.
1. En bas de la zone de texte **Description**, sélectionnez **Passer à l'édition en texte enrichi**. Si le contrôle affiche **Passer à l'édition en texte brut**, la zone de texte est déjà en mode texte enrichi.
1. Effectuez vos modifications, puis sélectionnez **Sauvegarder**.

## Promouvoir une tâche en ticket {#promote-a-task-to-an-issue}

{{< history >}}

- Rôle utilisateur minimum [modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Developer, Maintainer ou Owner pour le projet.

Pour promouvoir une tâche en ticket :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Task** et sélectionnez votre tâche.
1. Dissociez le ticket parent et promouvez la tâche : dans la fenêtre de la tâche, utilisez ces deux [actions rapides](project/quick_actions.md) dans des commentaires séparés :

   ```plaintext
   /remove_parent
   ```

   ```plaintext
   /promote_to issue
   ```

La tâche est convertie en ticket. L'URL précédente avec `/work_items/` fonctionne toujours.

## Convertir une tâche en un autre type d'élément {#convert-a-task-into-another-item-type}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/385131) dans GitLab 17.8 [avec un feature flag](../administration/feature_flags/_index.md) nommé `work_items_beta`. Fonctionnalité désactivée par défaut.
- [Déplacé](https://gitlab.com/gitlab-org/gitlab/-/issues/385131) [vers le flag](../administration/feature_flags/_index.md) nommé `okrs_mvc`. Pour connaître l'état actuel du flag, consultez le haut de cette page.

{{< /history >}}

Convertissez une tâche en un autre type d'élément, par exemple :

- Ticket
- Objectif
- Résultat clé

> [!warning]
> La modification du type peut entraîner une perte de données si le type cible ne prend pas en charge tous les champs du type d'origine.

Prérequis :

- La tâche que vous souhaitez convertir ne doit pas avoir d'élément parent assigné.

Pour convertir une tâche en un autre type d'élément :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Task** et sélectionnez votre tâche.
1. Facultatif. Si la tâche a un ticket parent assigné, supprimez-le. Ajoutez un commentaire à la tâche avec l'action rapide `/remove_parent`.
1. Dans le coin supérieur droit, sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}), puis sélectionnez **Changer de type**.
1. Sélectionnez le type d'élément souhaité.
1. Si toutes les conditions sont remplies, sélectionnez **Changer de type**.

Vous pouvez également utiliser l'[action rapide `/type`](project/quick_actions.md#type), suivie de `issue`, `objective`, ou `key result` dans un commentaire.

## Supprimer une tâche d'un ticket {#remove-a-task-from-an-issue}

{{< history >}}

- Rôle minimum requis [modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/404799) de Reporter à Invité dans GitLab 17.0.

{{< /history >}}

Prérequis :

- Vous devez disposer du rôle Invité, Planificateur, Reporter, Developer, Maintainer ou Owner pour le projet.

Vous pouvez supprimer une tâche d'un ticket sans la supprimer définitivement. Pour les reconnecter, consultez [Définir un ticket comme parent](#set-an-issue-as-a-parent).

Pour supprimer une tâche d'un ticket en utilisant la section **Éléments enfants** :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Ticket** et sélectionnez votre ticket.
1. Dans la description du ticket, dans la section **Éléments enfants**, sélectionnez le menu d'options ({{< icon name="ellipsis_v" >}}) en regard de la tâche que vous souhaitez supprimer.
1. Sélectionnez **Supprimer la tâche**.

Pour supprimer une tâche d'un ticket en utilisant le panneau de détails de la tâche :

1. Sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Task** et sélectionnez votre tâche.
1. Dans la barre latérale droite, en regard de **Parent**, sélectionnez **Modifier**.
1. Dans le coin supérieur droit de la liste déroulante, sélectionnez **Effacer**.

## Supprimer une tâche {#delete-a-task}

{{< history >}}

- Rôle utilisateur minimum [modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) de Owner à Planificateur dans GitLab 17.7.

{{< /history >}}

Prérequis :

- Vous devez soit :
  - Être l'auteur de la tâche et disposer du rôle Invité, Reporter, Developer ou Maintainer pour le projet.
  - Disposer du rôle Planificateur ou Owner pour le projet.

Pour supprimer une tâche :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Task** et sélectionnez votre tâche.
1. Sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Supprimer la tâche**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Supprimer la tâche**.

## Réorganiser les tâches {#reorder-tasks}

{{< history >}}

- Rôle utilisateur minimum [modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Developer, Maintainer ou Owner pour le projet.

Par défaut, les tâches sont triées par date de création. Pour les réorganiser dans la section **Éléments enfants** d'un ticket, faites-les glisser dans l'ordre souhaité.

Pour trier les tâches dans la liste **Éléments de travail** :

1. À droite de la barre de filtre, sélectionnez la liste déroulante **Date de création**.
1. Sélectionnez un critère de tri :

   - Priorité
   - Date de création
   - Date de mise à jour
   - Date de clôture
   - Date d'échéance du jalon
   - Date d'échéance
   - Popularité
   - Priorité du label
   - Manuel (faites glisser les éléments dans l'ordre de votre choix ; le sens du tri est ignoré)
   - Titre
   - Date de début

1. Pour basculer entre l'ordre croissant et décroissant, sélectionnez **Sens de tri** ({{< icon name="sort-lowest" >}} ou {{< icon name="sort-highest" >}}).

## Modifier le statut {#change-status}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/543862) dans GitLab 18.2 [avec un feature flag](../administration/feature_flags/_index.md) nommé `work_item_status_feature_flag`. Activés par défaut.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/521286) dans GitLab 18.4. Le feature flag `work_item_status_feature_flag` a été supprimé.

{{< /history >}}

<!-- Turn off the future tense test because of "won't do". -->
<!-- vale gitlab_base.FutureTense = NO -->

Vous pouvez attribuer un statut aux tâches pour suivre leur progression dans votre workflow. Le statut offre un suivi plus précis que les états ouverts/fermés de base, vous permettant d'utiliser des étapes spécifiques comme **En cours**, **Terminé** ou **Ne sera pas fait**.
<!-- vale gitlab_base.FutureTense = YES -->

Pour plus d'informations sur le statut, notamment sur la configuration de statuts personnalisés, consultez [Statut](work_items/status.md).

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Developer, Maintainer ou Owner pour le projet, être l'auteur de la tâche ou y être assigné.

Pour modifier le statut d'une tâche :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Task** et sélectionnez votre tâche.
1. Dans la barre latérale droite, dans la section **Statut**, sélectionnez **Modifier**.
1. Dans la liste déroulante, sélectionnez le statut.

Le statut de la tâche est mis à jour immédiatement.

Vous pouvez également définir le statut en utilisant l'[action rapide `/status`](project/quick_actions.md#status).

## Assigner des utilisateurs à une tâche {#assign-users-to-a-task}

{{< history >}}

- Rôle utilisateur minimum [modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Pour indiquer qui est responsable d'une tâche, vous pouvez y assigner des utilisateurs.

Les utilisateurs de GitLab Free peuvent assigner un seul utilisateur par tâche. Les utilisateurs de GitLab Premium et Ultimate peuvent assigner plusieurs utilisateurs à une même tâche. Consultez également [les personnes assignées multiples pour les tickets](project/issues/multiple_assignees_for_issues.md).

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Developer, Maintainer ou Owner pour le projet.

Pour modifier la personne assignée à une tâche :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Task** et sélectionnez votre tâche.
1. Dans la barre latérale droite, dans la section **Personne assignée** ou **Personnes assignées**, sélectionnez **Modifier**.
1. Dans la liste déroulante, sélectionnez les utilisateurs à assigner.
1. Sélectionnez **Appliquer**, ou cliquez en dehors de la liste déroulante.

## Assigner des labels à une tâche {#assign-labels-to-a-task}

{{< history >}}

- Rôle utilisateur minimum [modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Developer, Maintainer ou Owner pour le projet.

Pour ajouter des [labels](project/labels.md) à une tâche :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Task** et sélectionnez votre tâche.
1. Dans la barre latérale droite, dans la section **Labels**, sélectionnez **Modifier**.
1. Dans la liste déroulante, sélectionnez les labels à ajouter.
1. Cliquez en dehors de la liste déroulante.

## Définir une date de début et une date d'échéance {#set-a-start-and-due-date}

{{< history >}}

- Rôle utilisateur minimum [modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Vous pouvez définir une [date de début et une date d'échéance](project/issues/due_dates.md) sur une tâche.

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Developer, Maintainer ou Owner pour le projet.

Vous pouvez définir des dates de début et d'échéance sur une tâche pour indiquer quand le travail doit commencer et se terminer.

Pour définir une date de début ou d'échéance :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Task** et sélectionnez votre tâche.
1. Dans la barre latérale droite, dans la section **Dates**, sélectionnez **Modifier**.
1. Facultatif. Dans le sélecteur **Date de début**, sélectionnez une date.
1. Facultatif. Dans le sélecteur **Date d'échéance**, sélectionnez une date. La date d'échéance doit être identique ou postérieure à la date de début.
1. Sélectionnez **Appliquer**.

## Ajouter une tâche à un jalon {#add-a-task-to-a-milestone}

{{< history >}}

- Rôle utilisateur minimum [modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

Vous pouvez ajouter une tâche à un [jalon](project/milestones/_index.md). Vous pouvez voir le titre du jalon lorsque vous affichez une tâche. Si vous créez une tâche pour un ticket qui appartient déjà à un jalon, la nouvelle tâche hérite du jalon.

Prérequis :

- Vous devez disposer du rôle Planificateur, Reporter, Developer, Maintainer ou Owner pour le projet.

Pour ajouter une tâche à un jalon :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Task** et sélectionnez votre tâche.
1. Dans la barre latérale droite, dans la section **Jalon**, sélectionnez **Modifier**.
1. Dans la liste déroulante, sélectionnez le jalon. Si une tâche appartient déjà à un jalon, la liste déroulante affiche le jalon actuel.
1. Cliquez en dehors de la liste déroulante.

## Définir le poids d'une tâche {#set-task-weight}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prérequis :

- Vous devez disposer du rôle Reporter, Developer, Maintainer ou Owner pour le projet.

Vous pouvez définir un poids pour chaque tâche afin d'indiquer la quantité de travail qu'elle nécessite. Cette valeur n'est visible que lorsque vous affichez une tâche.

Pour définir le poids du ticket d'une tâche :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Task** et sélectionnez votre tâche.
1. Dans la barre latérale droite, dans la section **Poids**, sélectionnez **Modifier**.
1. Saisissez un nombre entier positif.
1. Sélectionnez **Appliquer** ou appuyez sur <kbd>Entrée</kbd>.

### Afficher le nombre et le poids des tâches dans le ticket parent {#view-count-and-weight-of-tasks-in-the-parent-issue}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/520886) dans GitLab 18.3 [avec un feature flag](../administration/feature_flags/_index.md) nommé `use_cached_rolled_up_weights`. Fonctionnalité désactivée par défaut.
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/520886) dans GitLab 18.4.
- [Disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/520886) dans GitLab 18.6. Le feature flag `use_cached_rolled_up_weights` a été supprimé.

{{< /history >}}

Le nombre de tâches descendantes et leur poids total sont affichés dans la description du ticket, dans l'en-tête de la section **Éléments enfants**.

Pour voir le nombre de tâches ouvertes et fermées :

- Dans l'en-tête de section, survolez le total.

Les chiffres reflètent toutes les tâches enfants associées au ticket, y compris celles que vous pourriez ne pas avoir la permission de consulter.

### Afficher la progression du ticket parent {#view-progress-of-the-parent-issue}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/520886) dans GitLab 18.3 [avec un feature flag](../administration/feature_flags/_index.md) nommé `use_cached_rolled_up_weights`. Fonctionnalité désactivée par défaut.
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/520886) dans GitLab 18.4.
- [Disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/520886) dans GitLab 18.6. Le feature flag `use_cached_rolled_up_weights` a été supprimé.

{{< /history >}}

Le pourcentage de progression du ticket est affiché dans la description du ticket, dans l'en-tête de la section **Éléments enfants**.

Pour voir le poids complété et le poids total des tâches enfants :

- Dans l'en-tête de section, survolez le pourcentage.

Les poids et la progression reflètent toutes les tâches associées au ticket, y compris celles que vous pourriez ne pas avoir la permission de consulter.

## Ajouter une tâche à une itération {#add-a-task-to-an-iteration}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate

{{< /details >}}

Vous pouvez ajouter une tâche à une [itération](group/iterations/_index.md). Vous pouvez voir le titre et la période de l'itération uniquement lorsque vous affichez une tâche.

Prérequis :

- Vous devez disposer du rôle Reporter, Developer, Maintainer ou Owner pour le projet.

Pour ajouter une tâche à une itération :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Task** et sélectionnez votre tâche.
1. Dans la barre latérale droite, dans la section **Itération**, sélectionnez **Modifier**.
1. Dans la liste déroulante, sélectionnez l'itération à associer à la tâche.
1. Cliquez en dehors de la liste déroulante.

## Estimer et suivre le temps passé {#estimate-and-track-spent-time}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/438577) dans GitLab 17.0.

{{< /history >}}

Vous pouvez estimer et suivre le temps que vous consacrez à une tâche.

Pour plus d'informations, consultez [Suivi du temps](project/time_tracking.md).

## Empêcher la troncature des descriptions avec **En savoir plus** {#prevent-truncating-descriptions-with-read-more}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181184) dans GitLab 17.10.

{{< /history >}}

Si la description d'une tâche est longue, GitLab n'en affiche qu'une partie. Pour voir la description complète, vous devez sélectionner **En savoir plus**. Cette troncature facilite la recherche d'autres éléments sur la page sans avoir à faire défiler un texte long.

Pour modifier la troncature des descriptions :

1. Sur une tâche, dans le coin supérieur droit, sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}).
1. Activez ou désactivez **Tronquer les descriptions** selon votre préférence.

Ce paramètre est mémorisé et s'applique à tous les tickets, tâches, epics, objectifs et résultats clés.

## Masquer la barre latérale droite {#hide-the-right-sidebar}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181184) dans GitLab 17.10.

{{< /history >}}

Les attributs de la tâche sont affichés dans une barre latérale à droite de la description lorsque l'espace le permet. Pour masquer la barre latérale et augmenter l'espace disponible pour la description :

1. Sur une tâche, dans le coin supérieur droit, sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Masquer la barre latérale**.

Ce paramètre est mémorisé et s'applique à tous les tickets, tâches, epics, objectifs et résultats clés.

Pour afficher à nouveau la barre latérale :

- Répétez les étapes précédentes et sélectionnez **Afficher la barre latérale**.

## Afficher les notes système de la tâche {#view-task-system-notes}

Vous pouvez afficher toutes les notes système relatives à la tâche. Par défaut, elles sont triées par **Plus ancien en premier**. Vous pouvez toujours modifier l'ordre de tri en **Plus récent en premier**, ce réglage étant mémorisé entre les sessions. Vous pouvez également filtrer l'activité par **Commentaires uniquement** et **Historique uniquement**, en plus de la valeur par défaut **Toute l'activité**, qui est mémorisée entre les sessions.

## Commentaires et fils de discussion {#comments-and-threads}

Vous pouvez ajouter des [commentaires](discussions/_index.md) et répondre aux fils de discussion dans les tâches.

## Copier la référence de la tâche {#copy-task-reference}

Pour faire référence à une tâche ailleurs dans GitLab, vous pouvez utiliser son URL complète ou une référence courte comme `namespace/project-name#123`, où `namespace` est un groupe ou un nom d'utilisateur.

Pour copier la référence de la tâche dans votre presse-papiers :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Task** et sélectionnez votre tâche.
1. Dans le coin supérieur droit, sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}), puis sélectionnez **Copier la référence**.

Vous pouvez maintenant coller la référence dans une autre description ou un commentaire.

Pour plus d'informations sur les références de tâches, consultez [GitLab Flavored Markdown](markdown.md#gitlab-specific-references).

## Copier l'adresse e-mail de la tâche {#copy-task-email-address}

Vous pouvez créer un commentaire dans une tâche en envoyant un e-mail. L'envoi d'un e-mail à cette adresse crée un commentaire contenant le corps de l'e-mail.

Pour plus d'informations sur la création de commentaires par e-mail et la configuration nécessaire, consultez [Répondre à un commentaire par e-mail](discussions/_index.md#reply-to-a-comment-by-sending-email).

Pour copier l'adresse e-mail de la tâche :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Task** et sélectionnez votre tâche.
1. Dans le coin supérieur droit, sélectionnez **Plus d'actions** ({{< icon name="ellipsis_v" >}}), puis sélectionnez **Copier l'adresse e-mail de la tâche**.

## Définir un ticket comme parent {#set-an-issue-as-a-parent}

Prérequis :

- Vous devez disposer du rôle Invité, Planificateur, Reporter, Developer, Maintainer ou Owner pour le projet.
- Le ticket et la tâche doivent appartenir au même projet.

Pour définir un ticket comme parent d'une tâche :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Task** et sélectionnez votre tâche.
1. Dans la barre latérale droite, dans la section **Parent**, sélectionnez **Modifier**.
1. Dans la liste déroulante, sélectionnez le parent à ajouter.
1. Cliquez en dehors de la liste déroulante.

Pour supprimer l'élément parent de la tâche :

1. Dans la section **Parent**, sélectionnez **Modifier**.
1. Dans le coin supérieur droit de la liste déroulante, sélectionnez **Effacer**.
1. Cliquez en dehors de la liste déroulante.

## Participants {#participants}

Les participants sont les utilisateurs qui ont interagi avec une tâche. Pour plus d'informations sur l'affichage des participants, consultez [Participants](participants.md).

## Tâches confidentielles {#confidential-tasks}

Les tâches confidentielles sont des tâches visibles uniquement par les membres d'un projet disposant des [permissions suffisantes](#who-can-see-confidential-tasks). Vous pouvez utiliser des tâches confidentielles pour garder les failles de sécurité privées ou empêcher des informations de fuiter.

### Rendre une tâche confidentielle {#make-a-task-confidential}

Par défaut, les tâches sont publiques. Vous pouvez rendre une tâche confidentielle lors de sa création ou de sa modification.

Prérequis :

- Vous devez disposer du rôle Reporter, Developer, Maintainer ou Owner pour le projet.
- Si la tâche a un ticket parent non confidentiel et que vous souhaitez rendre le ticket confidentiel, vous devez d'abord rendre toutes les tâches enfants confidentielles. Un [ticket confidentiel](project/issues/confidential_issues.md) ne peut avoir que des éléments enfants confidentiels.

#### Dans une nouvelle tâche {#in-a-new-task}

Lorsque vous créez une nouvelle tâche, une case à cocher juste en dessous de la zone de texte est disponible pour marquer la tâche comme confidentielle.

Cochez cette case et sélectionnez **Créer une tâche**.

#### Dans une tâche existante {#in-an-existing-task}

Pour modifier la confidentialité d'une tâche existante :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Task** et sélectionnez votre tâche.
1. Dans le coin supérieur droit, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Activer la confidentialité**.

### Qui peut voir les tâches confidentielles {#who-can-see-confidential-tasks}

Lorsqu'une tâche est rendue confidentielle, seuls les utilisateurs disposant du rôle Reporter, Developer, Maintainer ou Owner pour le projet peuvent y accéder. Les utilisateurs disposant du rôle Invité ou du rôle [Minimal](permissions.md#users-with-minimal-access) ne peuvent pas accéder à la tâche, même s'ils y participaient précédemment.

Un utilisateur avec le rôle Invité peut créer des tâches confidentielles, mais ne peut consulter que celles qu'il a créées.

Les utilisateurs avec le rôle Invité ou les non-membres peuvent consulter une tâche confidentielle s'ils y sont assignés. Lorsqu'un utilisateur Invité ou un non-membre est désassigné d'une tâche confidentielle, il ne peut plus la consulter.

Les tâches confidentielles sont masquées dans les résultats de recherche pour les utilisateurs ne disposant pas des permissions nécessaires.

### Indicateurs de tâche confidentielle {#confidential-task-indicators}

Les tâches confidentielles se distinguent visuellement des tâches normales de plusieurs façons. Partout où les tâches sont listées, vous pouvez voir l'icône confidentielle ({{< icon name="eye-slash" >}}) en regard des tâches marquées comme confidentielles.

Si vous ne disposez pas des [permissions suffisantes](#who-can-see-confidential-tasks), vous ne pouvez pas voir les tâches confidentielles.

De même, à l'intérieur de la tâche, vous pouvez voir l'icône confidentielle ({{< icon name="eye-slash" >}}) juste en regard du fil d'Ariane.

Chaque passage de normal à confidentiel et vice versa est indiqué par une note système dans les commentaires de la tâche, par exemple :

- {{< icon name="eye-slash" >}} Jo Garcia a rendu le ticket confidentiel il y a 5 minutes
- {{< icon name="eye" >}} Jo Garcia a rendu le ticket visible par tout le monde à l'instant

## Verrouiller la discussion {#lock-discussion}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/398649) dans GitLab 16.9 [avec un feature flag](../administration/feature_flags/_index.md) nommé `work_items_beta`. Fonctionnalité désactivée par défaut.
- Feature flag `work_items_beta` [supprimé](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17549) dans GitLab 18.6.

{{< /history >}}

Vous pouvez empêcher les commentaires publics dans une tâche. Dans ce cas, seuls les membres du projet peuvent ajouter et modifier des commentaires.

Prérequis :

- Vous devez disposer du rôle Rapporteur, Développeur, Chargé de maintenance ou Propriétaire.

Pour verrouiller une tâche :

1. Dans le coin supérieur droit, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Verrouiller la discussion**.

Une note système est ajoutée aux détails de la page.

Si une tâche est fermée avec une discussion verrouillée, vous ne pouvez pas la rouvrir tant que la discussion n'est pas déverrouillée.

## Éléments liés dans les tâches {#linked-items-in-tasks}

{{< history >}}

- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150148) dans GitLab 17.0. Le feature flag `linked_work_items` a été supprimé.
- Rôle minimum requis [modifié](https://gitlab.com/groups/gitlab-org/-/work_items/10267) de Reporter (si vrai) à Invité dans GitLab 17.0.

{{< /history >}}

Les éléments liés constituent une relation bidirectionnelle et apparaissent dans un bloc en dessous de la section des réactions emoji. Vous pouvez lier un objectif, un résultat clé ou une tâche du même projet les uns aux autres.

La relation n'apparaît dans l'interface que si l'utilisateur peut voir les deux éléments.

### Ajouter un élément lié {#add-a-linked-item}

Prérequis :

- Vous devez disposer du rôle Invité, Planificateur, Reporter, Developer, Maintainer ou Owner pour le projet.

Pour lier un élément à une tâche :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Task** et sélectionnez votre tâche.
1. Dans la section **Éléments liés** d'une tâche, sélectionnez **Ajouter** ({{< icon name="plus" >}}).
1. Sélectionnez la relation entre les deux éléments. L'une ou l'autre des options :
   - **en relation avec**
   - **bloque**
   - **est bloqué(e) par**
1. Saisissez le texte de recherche de l'élément, son URL ou son ID de référence.
1. Lorsque vous avez ajouté tous les éléments à lier, sélectionnez **Ajouter** sous la zone de recherche.

Une fois que vous avez terminé d'ajouter tous les éléments liés, vous pouvez les voir classés par catégorie pour mieux comprendre leurs relations visuellement.

![Éléments de travail liés regroupés en Bloque, Bloqué par et En relation avec dans la section Éléments liés.](img/linked_items_list_v16_5.png)

### Supprimer un élément lié {#remove-a-linked-item}

Prérequis :

- Vous devez disposer du rôle Invité, Planificateur, Reporter, Developer, Maintainer ou Owner pour le projet.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Task** et sélectionnez votre tâche.
1. Dans la section **Éléments liés** d'une tâche, en regard de chaque élément, sélectionnez les points de suspension verticaux ({{< icon name="ellipsis_v" >}}), puis sélectionnez **Supprimer**.

En raison de la relation bidirectionnelle, la relation n'apparaît plus dans aucun des deux éléments.

### Ajouter une merge request et fermer automatiquement les tâches {#add-a-merge-request-and-automatically-close-tasks}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/440851) dans GitLab 17.3.

{{< /history >}}

Vous pouvez configurer la fermeture automatique d'une tâche lors de la fusion d'une merge request.

Prérequis :

- Vous devez disposer du rôle Developer, Maintainer ou Owner pour le projet contenant la merge request.
- Vous devez disposer du rôle Reporter, Developer, Maintainer ou Owner pour le projet contenant la tâche.

1. Modifiez votre merge request.
1. Dans la zone de texte **Description**, trouvez et ajoutez la tâche.
   - Utilisez le [modèle de fermeture](project/issues/managing_issues.md#closing-issues-automatically) que vous utiliseriez pour ajouter une merge request à un ticket.
   - Si votre tâche est dans le même projet que votre merge request, vous pouvez rechercher votre tâche en saisissant <kbd>#</kbd> suivi de l'ID ou du titre de la tâche.
   - Si votre tâche est dans un projet différent, avec une tâche ouverte, copiez l'URL depuis le navigateur ou copiez la référence de la tâche en sélectionnant les points de suspension verticaux ({{< icon name="ellipsis_v" >}}) dans le coin supérieur droit, puis **Copier la référence**.

Les merge requests sont maintenant visibles dans le corps principal, dans la section **Développement**.

Utilisez le modèle de fermeture exact pour ajouter la merge request à la tâche.

Si la [fermeture automatique des tickets](project/issues/managing_issues.md#disable-automatic-issue-closing) est activée dans les paramètres de votre projet, la tâche est automatiquement fermée lorsque :

- La merge request ajoutée est fusionnée.
- Un commit référençant une tâche avec le modèle de fermeture est commis dans la branche par défaut de votre projet.

## Sujets connexes {#related-topics}

- [Créer une merge request à partir d'une tâche](project/merge_requests/creating_merge_requests.md#from-a-task)
