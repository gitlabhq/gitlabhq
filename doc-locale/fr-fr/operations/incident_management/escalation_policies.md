---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Découvrez comment créer, modifier et supprimer des politiques d'escalade dans GitLab pour garantir que les alertes critiques sont correctement traitées et acheminées vers les personnes d'astreinte."
title: "Politiques d'escalade"
---

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les politiques d'escalade protègent votre entreprise contre les alertes critiques manquées. Les politiques d'escalade contiennent des étapes limitées dans le temps qui contactent automatiquement le prochain intervenant à l'étape d'escalade si l'intervenant de l'étape précédente n'a pas répondu. Vous pouvez créer une politique d'escalade dans le projet GitLab où vous gérez les [calendriers d'astreinte](oncall_schedules.md).

## Ajouter une politique d'escalade {#add-an-escalation-policy}

Prérequis :

- Vous devez disposer du rôle Chargé de maintenance ou Propriétaire.
- Vous devez disposer d'un [calendrier d'astreinte](oncall_schedules.md).

Pour créer une politique d'escalade :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Supervision** > **Politiques d'escalade**.
1. Sélectionnez **Ajouter une politique d'escalade**.
1. Saisissez le nom et la description de la politique, ainsi que les règles d'escalade à suivre lorsqu'un intervenant principal manque une alerte.
1. Sélectionnez **Ajouter une politique d'escalade**.

![Politique d'escalade](img/escalation_policy_v14_1.png)

### Sélectionner l'intervenant d'une règle d'escalade {#select-the-responder-of-an-escalation-rule}

Lors de la configuration d'une règle d'escalade, vous pouvez désigner qui contacter :

- **Envoyer un courriel à l'utilisateur d'astreinte dans le calendrier** : notifie les utilisateurs en astreinte lorsque la règle est déclenchée, couvrant toutes les rotations du [calendrier d'astreinte](oncall_schedules.md) spécifié.
- **Envoyer un courriel à un utilisateur** : notifie directement l'utilisateur spécifié.

Lorsqu'une notification est envoyée à un utilisateur via un calendrier d'astreinte ou directement, une note système répertoriant les utilisateurs contactés est créée sur l'alerte.

La durée spécifiée pour une règle d'escalade doit être comprise entre 0 et 1 440 minutes.

## Modifier une politique d'escalade {#edit-an-escalation-policy}

Pour mettre à jour une politique d'escalade :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Supervision** > **Politiques d'escalade**.
1. Sélectionnez **Modifier la politique d'escalade** ({{< icon name="pencil" >}}).
1. Modifiez les informations.
1. Sélectionnez **Sauvegarder les modifications**.

## Supprimer une politique d'escalade {#delete-an-escalation-policy}

Pour supprimer une politique d'escalade :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Supervision** > **Politiques d'escalade**.
1. Sélectionnez **Supprimer la politique d'escalade** ({{< icon name="remove" >}}).
1. Dans la boîte de dialogue de confirmation, sélectionnez **Supprimer la politique d'escalade**.
