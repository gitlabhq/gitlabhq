---
stage: Plan
group: Work Items
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Liste de tâches
description: "Gestion des tâches, actions et modifications d'accès."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Votre *liste de tâches* est une liste chronologique d'éléments en attente de votre intervention. Ces éléments sont appelés *éléments de la liste de tâches*.

Vous pouvez utiliser la liste de tâches pour suivre les actions liées à votre travail dans GitLab. Lorsque des personnes vous contactent ou que votre attention est requise, un élément de la liste de tâches apparaît dans votre liste de tâches.

## Accéder à la liste de tâches {#access-the-to-do-list}

Pour accéder à votre liste de tâches :

Dans le coin supérieur droit, sélectionnez **Tâches** ({{< icon name="task-done" >}}).

### Filtrer la liste de tâches {#filter-the-to-do-list}

Pour filtrer votre liste de tâches :

1. Au-dessus de la liste, placez votre curseur dans le champ de texte.
1. Sélectionnez l'un des filtres prédéfinis.
1. Appuyez sur <kbd>Entrée</kbd>.

### Trier la liste de tâches {#sort-the-to-do-list}

Pour trier la liste de tâches :

1. Dans l'onglet **À faire**, dans le coin supérieur droit, sélectionnez parmi les options :

   - **Recommandé** trie par combinaison de la date de création et des dates de report précédentes, avec les éléments précédemment reportés en tête de liste.
   - **Mis à jour** trie par date de la mise à jour la plus récente de l'élément.
   - **Priorité du label** trie [selon les priorités que vous avez définies](project/labels.md#set-label-priority).

1. Facultatif. Sélectionnez le sens du tri.

> [!note]
> Dans les onglets **Reportée** et **Terminé**, **Recommandé** trie les éléments par date de création uniquement.

## Actions qui créent des éléments de la liste de tâches {#actions-that-create-to-do-items}

{{< history >}}

- Plusieurs éléments de la liste de tâches [activés sur GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/28355) dans GitLab 17.8. Le feature flag `multiple_todos` est activé par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

De nombreux éléments de la liste de tâches sont créés automatiquement. Voici certaines des actions qui ajoutent un élément à votre liste de tâches :

- Un ticket ou une merge request vous est assigné(e).
- Une relecture de merge request est demandée.
- Vous êtes mentionné(e) dans la description ou un commentaire d'un ticket, d'une merge request ou d'un epic.
- Vous êtes mentionné(e) dans un commentaire sur un commit ou un design.
- Le pipeline CI/CD de votre merge request échoue.
- Une merge request ouverte ne peut pas être fusionnée en raison d'un conflit, et l'une des conditions suivantes est vraie :
  - Vous êtes l'auteur(e).
  - Vous êtes l'utilisateur ou l'utilisatrice qui a configuré la merge request pour fusionner automatiquement après la réussite d'un pipeline.
- Une merge request est retirée d'un [merge train](../ci/pipelines/merge_trains.md), et vous êtes l'utilisateur ou l'utilisatrice qui l'a ajoutée.
- Une demande d'accès de membre est soumise pour un groupe ou un projet dont vous êtes propriétaire.

Dans GitLab 17.8 et versions ultérieures, vous recevez une nouvelle notification de tâche chaque fois que quelqu'un vous mentionne, même dans le même ticket ou la même merge request.

Pour les autres actions qui créent des éléments de la liste de tâches, comme les assignations ou les demandes de relecture, vous ne recevez qu'une seule notification par type d'action, même si cette action se produit plusieurs fois dans le même ticket ou la même merge request.

Les éléments de la liste de tâches ne sont pas affectés par les [paramètres de notification par e-mail de GitLab](profile/notifications.md). La seule exception : si votre paramètre de notification est défini sur **Personnalisé** et que **Une requête de fusion que vous pouvez approuver a été créée** est sélectionné, vous recevez un élément de la liste de tâches lorsque vous êtes éligible à approuver une merge request.

## Créer un élément de la liste de tâches {#create-a-to-do-item}

Vous pouvez ajouter manuellement un élément à votre liste de tâches.

1. Accédez à votre :

   - Ticket
   - Demande de fusion
   - Epic
   - Design
   - Incident
   - Objectif ou résultat clé
   - Tâche

1. Dans le coin supérieur droit, sélectionnez **Ajouter une tâche à faire** ({{< icon name="todo-add" >}}).

### Créer un élément de la liste de tâches en mentionnant quelqu'un {#create-a-to-do-item-by-mentioning-someone}

Vous pouvez créer un élément de la liste de tâches en mentionnant quelqu'un n'importe où, sauf dans un bloc de code. Mentionner un utilisateur ou une utilisatrice plusieurs fois dans un même message ne crée qu'un seul élément de la liste de tâches.

Par exemple, dans le commentaire suivant, tous les utilisateurs sauf `frank` reçoivent un élément de la liste de tâches créé pour eux :

````markdown
@alice What do you think? cc: @bob

- @carol can you please have a look?

> @dan what do you think?

Hey @erin, this is what they said:

```
Hi, please message @frank :incoming_envelope:
```
````

## Actions qui marquent un élément de la liste de tâches comme terminé {#actions-that-mark-a-to-do-item-as-done}

Diverses actions effectuées sur l'objet d'un élément de la liste de tâches (comme un ticket, une merge request ou un epic) marquent l'élément de la liste de tâches correspondant comme terminé.

Les éléments de la liste de tâches sont marqués comme terminés si vous :

- Ajoutez une réaction emoji à la description ou à un commentaire.
- Ajoutez ou supprimez un label.
- Modifiez la personne assignée.
- Modifiez le jalon.
- Fermez l'objet de l'élément de la liste de tâches.
- Créez un commentaire.
- Modifiez la description.
- Résolvez un fil de discussion sur un design.
- Acceptez ou refusez une demande d'adhésion à un projet ou un groupe.

Les éléments de la liste de tâches ne sont pas marqués comme terminés si vous :

- Ajoutez un élément lié (comme un ticket lié).
- Ajoutez un élément enfant (comme un epic enfant ou une tâche).
- Ajoutez un suivi du temps.
- Vous assignez vous-même.
- Modifiez le statut de santé d'un ticket.

Si quelqu'un d'autre ferme un ticket ou un epic, ou effectue une action sur ces éléments, votre élément de la liste de tâches reste en attente.

Lorsqu'une merge request est fusionnée ou fermée, les éléments de la liste de tâches de tous les utilisateurs qui ont été assignés, ajoutés en tant que relecteurs ou approbateurs, ou tenus d'approuver sont marqués comme terminés. Cela inclut les éléments de la liste de tâches liés aux pipelines ayant échoué.

## Marquer un élément de la liste de tâches comme terminé {#mark-a-to-do-item-as-done}

Vous pouvez marquer manuellement un élément de la liste de tâches comme terminé.

Il existe deux façons de procéder :

- Dans la liste de tâches, à droite de l'élément de la liste de tâches, sélectionnez **Marquer comme terminée** ({{< icon name="check" >}}).
- Dans le coin supérieur droit de la ressource (par exemple, un ticket ou une merge request), sélectionnez **Marquer comme terminée** ({{< icon name="todo-done" >}}).

## Rajouter un élément de la liste de tâches terminé {#re-add-a-done-to-do-item}

Si vous avez marqué un élément de la liste de tâches comme terminé par erreur, vous pouvez le rajouter depuis l'onglet **Terminé** :

1. Dans le coin supérieur droit, sélectionnez **Tâches** ({{< icon name="task-done" >}}).
1. En haut, sélectionnez **Terminé**.
1. Recherchez l'élément de la liste de tâches que vous souhaitez rajouter.
1. À côté de cet élément de la liste de tâches, sélectionnez **Annuler** {{< icon name="redo" >}}.

L'élément de la liste de tâches est désormais visible dans l'onglet **À faire** de la liste de tâches.

## Reporter des éléments de la liste de tâches {#snooze-to-do-items}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/17712) dans GitLab 17.9.

{{< /history >}}

Vous pouvez reporter des éléments de la liste de tâches pour les masquer temporairement de votre liste de tâches principale. Vous pouvez ainsi vous concentrer sur des tâches plus urgentes et revenir aux éléments reportés ultérieurement.

Pour reporter un élément de la liste de tâches :

1. Dans votre liste de tâches, à côté de l'élément que vous souhaitez reporter, sélectionnez Reporter ({{< icon name="clock" >}}).
1. Si vous souhaitez reporter l'élément de la liste de tâches jusqu'à une date et une heure spécifiques, sélectionnez l'option `Until a specific time and date`. Sinon, choisissez l'une des durées de report prédéfinies :
   - Pendant une heure
   - Jusqu'à plus tard aujourd'hui (4 heures plus tard)
   - Jusqu'à demain (demain à 8 h, heure locale)

Les éléments de la liste de tâches reportés sont retirés de votre liste de tâches principale et apparaissent dans un onglet **Reportée** distinct.

Lorsque la période de report se termine, l'élément de la liste de tâches retourne automatiquement dans votre liste de tâches principale. Il apparaît avec un indicateur indiquant la date à laquelle il a été créé à l'origine.

## Afficher les éléments de la liste de tâches reportés {#view-snoozed-to-do-items}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/17712) dans GitLab 17.9.

{{< /history >}}

Pour afficher ou gérer vos éléments de la liste de tâches reportés :

1. Accédez à votre liste de tâches.
1. En haut de la liste, sélectionnez l'onglet Reportée.

Depuis l'onglet Reportée, vous pouvez :

- Afficher la date à laquelle un élément reporté est planifié pour retourner dans votre liste principale.
- Supprimer le report pour renvoyer immédiatement un élément dans votre liste de tâches principale.
- Marquer un élément reporté comme terminé.

## Modifier en masse les éléments de la liste de tâches {#bulk-edit-to-do-items}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/16564) dans GitLab 17.10.

{{< /history >}}

Vous pouvez modifier vos éléments de la liste de tâches en masse :

- Dans l'onglet **À faire** : marquez les éléments de la liste de tâches comme terminés ou reportez-les.
- Dans l'onglet **Reportée** : marquez les éléments de la liste de tâches comme terminés ou supprimez-les.
- Dans l'onglet **Terminé** : restaurez les éléments de la liste de tâches.

Pour modifier en masse les éléments de la liste de tâches :

1. Dans votre liste de tâches :
   - Pour sélectionner des éléments individuels, à gauche de chaque élément que vous souhaitez modifier, cochez la case.
   - Pour sélectionner tous les éléments de la page, dans le coin supérieur gauche, cochez la case **Tout sélectionner**.
1. Dans le coin supérieur droit, sélectionnez l'action souhaitée.

## Impact des modifications d'accès d'un utilisateur sur sa liste de tâches {#how-a-users-to-do-list-is-affected-when-their-access-changes}

Pour des raisons de sécurité, GitLab supprime les éléments de la liste de tâches lorsqu'un utilisateur n'a plus accès à une ressource associée. Par exemple, si l'utilisateur n'a plus accès à un ticket, une merge request, un epic, un projet ou un groupe, GitLab supprime les éléments de la liste de tâches associés.

Ce processus s'effectue dans l'heure suivant la modification de leur accès. La suppression est différée pour éviter toute perte de données, au cas où l'accès de l'utilisateur aurait été révoqué par erreur.

## Sujets connexes {#related-topics}

- [Les tickets](project/issues/_index.md)
- [Les merge requests](project/merge_requests/_index.md)
- [Les epics](group/epics/_index.md)
- [Designs](project/issues/design_management.md)
- [Incidents](../operations/incident_management/incidents.md)
- [Objectifs ou résultats clés](okrs.md)
- [Tâches](tasks.md)
