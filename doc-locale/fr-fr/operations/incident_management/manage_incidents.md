---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Créez, assignez, mettez à jour et résolvez des incidents dans GitLab, et modifiez les politiques d'escalade."
title: Gérer les incidents
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Possibilité d'ajouter un [incident](_index.md) à une itération [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/347153) dans GitLab 17.0.

{{< /history >}}

Cette page regroupe les instructions pour toutes les actions que vous pouvez effectuer avec les [incidents](incidents.md) ou en relation avec eux.

## Créer un incident {#create-an-incident}

Vous pouvez créer un incident manuellement ou automatiquement.

## Ajouter un incident à une itération {#add-an-incident-to-an-iteration}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Pour ajouter un incident à une [itération](../../user/group/iterations/_index.md) :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Accédez à votre incident :
   - Pour les incidents dans la liste des tickets, sélectionnez **Forfait** > **Éléments de travail**, puis filtrez par **Type** = **Incident**.
   - Pour les incidents dans la liste de supervision, sélectionnez **Supervision** > **Incidents**.
1. Sélectionnez votre incident.
1. Dans la barre latérale droite, dans la section **Itération**, sélectionnez **Éditer**.
1. Dans la liste déroulante, sélectionnez l'itération à laquelle ajouter cet incident.
1. Sélectionnez n'importe quelle zone en dehors de la liste déroulante.

Vous pouvez également utiliser l'[action rapide `/iteration`](../../user/project/quick_actions.md#iteration).

### Depuis la page Incidents {#from-the-incidents-page}

Prérequis :

- Vous devez avoir le rôle Reporter, Developer, Maintainer ou Owner pour le projet.

Pour créer un incident depuis la page **Incidents** :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Supervision** > **Incidents**.
1. Sélectionnez **Créer un incident**.

### Depuis la page Éléments de travail {#from-the-work-items-page}

Prérequis :

- Vous devez avoir le rôle Reporter, Developer, Maintainer ou Owner pour le projet.

Pour créer un incident depuis la page **Éléments de travail** :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis sélectionnez **Nouvel élément**.
1. Dans la liste déroulante **Type**, sélectionnez **Incident**. Seuls les champs pertinents pour les incidents sont disponibles sur la page.
1. Sélectionnez **Créer un incident**.

### Depuis une alerte {#from-an-alert}

Créez un ticket d'incident lors de la consultation d'une [alerte](alerts.md). La description de l'incident est alimentée depuis l'alerte.

Prérequis :

- Vous devez avoir le rôle Developer, Maintainer ou Owner pour le projet.

Pour créer un incident depuis une alerte :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Supervision** > **Alertes**.
1. Sélectionnez l'alerte souhaitée.
1. Sélectionnez **Créer un incident**.

Une fois l'incident créé, pour le consulter depuis l'alerte, sélectionnez **Voir l'incident**.

Lorsque vous [clôturez un incident](#close-an-incident) lié à une alerte, GitLab [modifie le statut de l'alerte](alerts.md#change-an-alerts-status) en **Résolue**. Le changement de statut de l'alerte vous est alors attribué.

### Automatiquement, lorsqu'une alerte est déclenchée {#automatically-when-an-alert-is-triggered}

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Dans les paramètres du projet, vous pouvez activer la [création automatique d'un incident](alerts.md#trigger-actions-from-alerts) à chaque déclenchement d'une alerte.

### Utilisation du webhook PagerDuty {#using-the-pagerduty-webhook}

{{< history >}}

- Prise en charge du [webhook PagerDuty V3](https://support.pagerduty.com/docs/webhooks) [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/383029) dans GitLab 15.7.

{{< /history >}}

Vous pouvez configurer un webhook avec PagerDuty pour créer automatiquement un incident GitLab pour chaque incident PagerDuty. Cette configuration nécessite d'apporter des modifications à la fois dans PagerDuty et dans GitLab.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.

Pour configurer un webhook avec PagerDuty :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Supervision**
1. Développez **Incidents**.
1. Sélectionnez l'onglet **Intégration de PagerDuty**.
1. Activez le bouton bascule **Actif**.
1. Sélectionnez **Enregistrer l'intégration**.
1. Copiez la valeur de **URL du crochet Web** pour l'utiliser dans une étape ultérieure.
1. Pour ajouter l'URL du webhook à une intégration de webhook PagerDuty, suivez les étapes décrites dans la [documentation PagerDuty](https://support.pagerduty.com/docs/webhooks#manage-v3-webhook-subscriptions).

Pour confirmer que l'intégration est réussie, déclenchez un incident de test depuis PagerDuty pour vérifier si un incident GitLab est créé à partir de l'incident.

## Afficher une liste des incidents {#view-a-list-of-incidents}

Pour afficher une liste des [incidents](incidents.md#incidents-list) :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Supervision** > **Incidents**.

Pour afficher la [page de détails](incidents.md#incident-details) d'un incident, sélectionnez-le dans la liste.

### Qui peut voir un incident {#who-can-view-an-incident}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256) du rôle utilisateur minimum de Reporter à Planificateur dans GitLab 17.7.

{{< /history >}}

La possibilité de voir un incident dépend du [niveau de visibilité du projet](../../user/public_access.md) et du statut de confidentialité de l'incident :

- Projet public et incident non confidentiel : Tout le monde peut voir l'incident.
- Projet privé et incident non confidentiel : Vous devez avoir le rôle Invité, Planificateur, Reporter, Developer, Maintainer ou Owner pour le projet.
- Incident confidentiel (quelle que soit la visibilité du projet) : Vous devez avoir le rôle Planificateur, Reporter, Developer, Maintainer ou Owner pour le projet.

## Assigner à un utilisateur {#assign-to-a-user}

Assignez les incidents aux utilisateurs qui répondent activement.

Prérequis :

- Vous devez avoir le rôle Reporter, Developer, Maintainer ou Owner pour le projet.

Pour assigner un utilisateur :

1. Dans un incident, dans la barre latérale droite, à côté de **Personnes assignées**, sélectionnez **Éditer**.
1. Dans la liste déroulante, sélectionnez un ou [plusieurs utilisateurs](../../user/project/issues/multiple_assignees_for_issues.md) à ajouter en tant que **assignees**.
1. Sélectionnez n'importe quelle zone en dehors de la liste déroulante.

## Modifier la gravité {#change-severity}

Consultez la rubrique [liste des incidents](incidents.md#incidents-list) pour une description complète des niveaux de gravité disponibles.

Prérequis :

- Vous devez avoir le rôle Reporter, Developer, Maintainer ou Owner pour le projet.

Pour modifier la gravité d'un incident :

1. Dans un incident, dans la barre latérale droite, à côté de **Gravité**, sélectionnez **Éditer**.
1. Dans la liste déroulante, sélectionnez la nouvelle gravité.

Vous pouvez également modifier la gravité à l'aide de l'[action rapide `/severity`](../../user/project/quick_actions.md#severity).

## Modifier le statut {#change-status}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/5716) dans GitLab 14.9 [avec un flag](../../administration/feature_flags/_index.md) nommé `incident_escalations`. Désactivé par défaut.
- [Activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/345769) dans GitLab 14.10.
- [Feature flag `incident_escalations`](https://gitlab.com/gitlab-org/gitlab/-/issues/345769) supprimé dans GitLab 15.1.

{{< /history >}}

Prérequis :

- Vous devez avoir le rôle Developer, Maintainer ou Owner pour le projet.

Pour modifier le statut d'un incident :

1. Dans un incident, dans la barre latérale droite, à côté de **Statut**, sélectionnez **Éditer**.
1. Dans la liste déroulante, sélectionnez la nouvelle gravité.

**Déclenchée** est le statut par défaut pour les nouveaux incidents.

### En tant qu'intervenant d'astreinte {#as-an-on-call-responder}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les intervenants d'astreinte peuvent répondre aux [pages d'incident](paging.md#escalating-an-incident) en modifiant le statut.

La modification du statut a les effets suivants :

- Vers **Acquittée** : limite les pages d'astreinte en fonction de la [politique d'escalade](escalation_policies.md) du projet.
- Vers **Résolue** : met en sourdine toutes les pages d'astreinte pour l'incident.
- De **Résolue** à **Déclenchée** : relance l'escalade de l'incident.

Dans GitLab 15.1 et versions antérieures, la modification du statut d'un [incident créé depuis une alerte](#from-an-alert) modifie également le statut de l'alerte. Dans [GitLab 15.2 et versions ultérieures](https://gitlab.com/gitlab-org/gitlab/-/issues/356057), le statut de l'alerte est indépendant et ne change pas lorsque le statut de l'incident change.

## Modifier la politique d'escalade {#change-escalation-policy}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prérequis :

- Vous devez avoir le rôle Developer, Maintainer ou Owner pour le projet.

Pour modifier la politique d'escalade d'un incident :

1. Dans un incident, dans la barre latérale droite, à côté de **Politique d'escalade**, sélectionnez **Éditer**.
1. Dans la liste déroulante, sélectionnez la politique d'escalade.

Par défaut, aucune politique d'escalade n'est sélectionnée pour les nouveaux incidents.

La sélection d'une politique d'escalade [modifie le statut de l'incident](#change-status) en **Déclenchée** et commence à [escalader l'incident vers les intervenants d'astreinte](paging.md#escalating-an-incident).

Dans GitLab 15.1 et versions antérieures, la politique d'escalade pour les [incidents créés depuis des alertes](#from-an-alert) reflète la politique d'escalade de l'alerte et ne peut pas être modifiée. Dans [GitLab 15.2 et versions ultérieures](https://gitlab.com/gitlab-org/gitlab/-/issues/356057), la politique d'escalade de l'incident est indépendante et peut être modifiée.

## Clôturer un incident {#close-an-incident}

Prérequis :

- Vous devez avoir le rôle Reporter, Developer, Maintainer ou Owner pour le projet.

Pour clôturer un incident, dans le coin supérieur droit, sélectionnez **Incident actions** ({{< icon name="ellipsis_v" >}}) puis **Close incident**.

Lorsque vous clôturez un incident lié à une [alerte](alerts.md), le statut de l'alerte liée passe à **Résolue**. Le changement de statut de l'alerte vous est alors attribué.

### Clôturer automatiquement les incidents via des alertes de récupération {#automatically-close-incidents-via-recovery-alerts}

Activez la clôture automatique d'un incident lorsque GitLab reçoit une alerte de récupération provenant d'un webhook HTTP ou Prometheus.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.

Pour configurer le paramètre :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Supervision**.
1. Développez la section **Incidents**.
1. Cochez la case **Automatically close associated incident**.
1. Sélectionnez **Sauvegarder les modifications**.

Lorsque GitLab reçoit une [alerte de récupération](integrations.md#recovery-alerts), il clôture l'incident associé. Cette action est enregistrée sous forme de note système sur l'incident, indiquant qu'il a été clôturé automatiquement par le bot d'alertes GitLab.

## Supprimer un incident {#delete-an-incident}

Prérequis :

- Vous devez avoir le rôle Owner pour un projet.

Pour supprimer un incident :

1. Dans un incident, sélectionnez **Incident actions** ({{< icon name="ellipsis_v" >}}).
1. Sélectionnez **Delete incident**.

Vous pouvez également :

1. Dans un incident, sélectionnez **Éditer**.
1. Sélectionnez **Delete incident**.

## Autres actions {#other-actions}

Les incidents dans GitLab étant construits sur la base des [tickets](../../user/project/issues/_index.md), ils partagent les actions suivantes :

- [Ajouter un élément de la liste de tâches](../../user/todos.md#create-a-to-do-item)
- [Ajouter des labels](../../user/project/labels.md#assign-and-unassign-labels)
- [Assigner un jalon](../../user/project/milestones/_index.md#assign-a-milestone-to-an-item)
- [Rendre un incident confidentiel](../../user/project/issues/confidential_issues.md)
- [Définir une date d'échéance](../../user/project/issues/due_dates.md)
- [Activer/désactiver les notifications](../../user/profile/notifications.md#subscribe-to-notifications-for-a-specific-issue-merge-request-or-epic)
- [Suivre le temps passé](../../user/project/time_tracking.md)
