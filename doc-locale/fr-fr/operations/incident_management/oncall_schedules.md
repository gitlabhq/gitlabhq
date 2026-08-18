---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Gérer les calendriers et cycles d'astreinte pour les personnes en charge des réponses aux incidents, notamment la création, la modification et la suppression des calendriers et cycles pour la réponse aux incidents."
title: "Gestion des calendriers d'astreinte"
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez la gestion des calendriers d'astreinte pour créer des calendriers permettant aux personnes en charge des réponses de faire tourner les responsabilités d'astreinte. Maintenez la disponibilité de vos services logiciels en mettant vos équipes en astreinte. Grâce aux [politiques d'escalade](escalation_policies.md) et aux calendriers d'astreinte, votre équipe est immédiatement notifiée en cas de problème afin de pouvoir répondre rapidement aux pannes et perturbations de service.

Pour utiliser les calendriers d'astreinte :

1. [Créez un calendrier](#schedules).
1. [Ajoutez un cycle au calendrier](#rotations).

## Calendriers {#schedules}

Configurez un calendrier d'astreinte pour votre équipe afin d'y ajouter des cycles.

Prérequis :

- Vous devez disposer du rôle Chargé de maintenance ou Propriétaire.

Pour créer un calendrier d'astreinte :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Supervision** > **Calendriers des astreintes**.
1. Sélectionnez **Add a schedule**.
1. Saisissez le nom et la description du calendrier, puis sélectionnez un fuseau horaire.
1. Sélectionnez **Ajouter un calendrier**.

Vous disposez maintenant d'un calendrier vide sans cycle. Cela s'affiche sous la forme d'un état vide, vous invitant à créer des [cycles](#rotations) pour votre calendrier.

![Grille vide du calendrier](img/oncall_schedule_empty_grid_v13_10.png)

### Modifier un calendrier {#edit-a-schedule}

Pour mettre à jour un calendrier :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Supervision** > **Calendriers des astreintes**.
1. Sélectionnez **Modifier le calendrier** ({{< icon name="pencil" >}}).
1. Modifiez les informations.
1. Sélectionnez **Sauvegarder les modifications**.

Si vous modifiez le fuseau horaire du calendrier, GitLab met automatiquement à jour l'intervalle de temps restreint du cycle (si un est défini) avec les heures correspondantes dans le nouveau fuseau horaire.

### Supprimer un calendrier {#delete-a-schedule}

Pour supprimer un calendrier :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Supervision** > **Calendriers des astreintes**.
1. Sélectionnez **Supprimer la politique d'escalade** ({{< icon name="remove" >}}).
1. Dans la boîte de dialogue de confirmation, sélectionnez **Supprimer le calendrier**.

## Cycles {#rotations}

Ajoutez des cycles à un calendrier existant pour mettre les membres de votre équipe en astreinte.

Pour créer un cycle :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Supervision** > **Calendriers des astreintes**.
1. Sélectionnez le lien **Ajouter un cycle**.
1. Saisissez les informations suivantes :

   - **Nom** : Le nom de votre cycle.
   - **Participants** : Les personnes que vous souhaitez inclure dans le cycle.
   - **Durée de cycle** : La durée du cycle.
   - **Commence le** : La date et l'heure de début du cycle.
   - **Activer la date de fin** : Lorsque la bascule est activée, vous pouvez sélectionner la date et l'heure de fin de votre cycle.
   - **Restreindre à des intervalles de temps** : Lorsque la bascule est activée, vous pouvez restreindre votre cycle à la période de temps que vous sélectionnez.

### Modifier un cycle {#edit-a-rotation}

Pour modifier un cycle :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Supervision** > **Calendriers des astreintes**.
1. Dans la section **Cycles**, sélectionnez **Modifier le cycle** ({{< icon name="pencil" >}}).
1. Modifiez les informations.
1. Sélectionnez **Sauvegarder les modifications**.

### Supprimer un cycle {#delete-a-rotation}

Pour supprimer un cycle :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Supervision** > **Calendriers des astreintes**.
1. Dans la section **Cycles**, sélectionnez **Supprimer le cycle** ({{< icon name="remove" >}}).
1. Dans la boîte de dialogue de confirmation, sélectionnez **Supprimer le cycle**.

## Afficher les cycles du calendrier {#view-schedule-rotations}

Vous pouvez afficher les calendriers d'astreinte d'une seule journée ou de deux semaines. Pour basculer entre ces périodes, sélectionnez les boutons **1 jour** ou **2 semaines** sur le calendrier. Deux semaines est la vue par défaut.

Survolez les participants d'un shift de cycle dans le calendrier pour afficher les détails de leur shift individuel.

![Vue en grille sur 1 jour](img/oncall_schedule_day_grid_v13_10.png)

## Envoyer une alerte à une personne d'astreinte {#page-an-on-call-responder}

Consultez [Alertes](paging.md#paging) pour plus de détails.

## Suppression ou effacement d'un utilisateur d'astreinte {#removal-or-deletion-of-on-call-user}

Si un utilisateur d'astreinte est retiré du projet ou du groupe, ou que son compte est supprimé, la boîte de dialogue de confirmation affiche la liste des calendriers d'astreinte de cet utilisateur. Si la suppression ou l'effacement de l'utilisateur est confirmé, GitLab recalcule le cycle d'astreinte et envoie un e-mail aux propriétaires du projet ainsi qu'aux participants du cycle.
