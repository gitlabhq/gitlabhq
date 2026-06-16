---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Vérifiez l'état de l'instance et trouvez les fenêtres de maintenance pour votre instance GitLab Dedicated dans Switchboard."
title: "Détails de l'instance GitLab Dedicated"
---

{{< details >}}

- Niveau : Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

La page **Vue d'ensemble** de Switchboard affiche l'état actuel de votre instance GitLab Dedicated, notamment son statut et son planning de maintenance. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com/) pour consulter les détails de votre instance.

La page affiche :

- Statut de l'instance
- URL du tenant
- Version de GitLab
- Architecture de référence
- [Total du stockage acheté](create_instance/storage_types.md#total-purchased-storage)
- Fenêtre de maintenance
- Région AWS principale et ID de zones de disponibilité
- Région AWS secondaire et ID de zones de disponibilité
- Région AWS de sauvegarde
- ID de compte AWS du tenant
- Runners hébergés (si configurés)

## Indicateurs de statut d'instance {#instance-status-indicators}

| Statut                   | Gravité | Impact                                                      | Description |
| ------------------------ | -------- | ----------------------------------------------------------- | ----------- |
| **Normal**               | Aucune     | Aucun incident actif.                                        | Aucun problème connu avec votre instance GitLab. |
| **Degraded performance** | S2       | Les fonctionnalités principales de GitLab sont significativement impactées.        | Les services GitLab peuvent être lents ou ne pas répondre. |
| **Service disruption**   | S1       | Un ou plusieurs services nécessaires à l'exécution de GitLab sont totalement hors service. | Les services GitLab peuvent être indisponibles. |
| **Under maintenance**    | S/O      | La maintenance est en cours.                                 | Les services GitLab peuvent être perturbés. |

Switchboard n'affiche pas :

- Les incidents S3 et S4, qui ont un impact minimal sur votre instance.
- Les incidents dans les cycles de vie non impactants, tels que les incidents en cours de révision, de documentation ou annulés.
- Les incidents fusionnés, où seul l'incident principal s'affiche lorsque plusieurs alertes sont consolidées.

Les indicateurs de statut sont fournis à titre informatif uniquement et ne sont pas pris en compte dans les calculs de SLA. Les mises à jour de statut apparaissent généralement dans un délai d'une à deux minutes après un changement d'état d'incident.

Si vous voyez un statut **Degraded performance** ou **Service disruption**, l'équipe GitLab est déjà informée et travaille à la résolution du problème. Vous n'avez pas besoin d'ouvrir un ticket d'assistance, sauf si vos workflows nécessitent une aide spécifique. Les statuts se mettent automatiquement à jour à mesure que l'incident progresse.

Si vous rencontrez des problèmes mais que le statut affiche **Normal**, le problème peut être spécifique à votre configuration ou à vos schémas d'utilisation. Ouvrez un [ticket d'assistance](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) et incluez des détails sur ce que vous rencontrez et sur la date à laquelle le comportement a commencé.

## Maintenance {#maintenance}

Switchboard affiche un indicateur de maintenance lorsque votre instance est en cours de maintenance. Les deux types de maintenance affichent le statut **Under maintenance**.

| Type de maintenance          | Quand il apparaît |
| ------------------------- | --------------- |
| **Scheduled maintenance** | Pendant votre fenêtre de maintenance planifiée. Pour plus d'informations, voir [accès pendant la maintenance](maintenance.md#access-during-maintenance). |
| **Emergency maintenance** | Pendant une maintenance non planifiée et urgente en dehors de votre fenêtre planifiée. Pour plus d'informations, voir [maintenance d'urgence](maintenance.md#emergency-maintenance). |

Si un incident survient pendant la maintenance, l'indicateur de maintenance et l'indicateur de statut de l'instance s'affichent tous les deux.

La page **Vue d'ensemble** affiche également :

- Prochaine fenêtre de maintenance planifiée et prochaine mise à niveau de la version de GitLab
- Fenêtre de maintenance la plus récemment complétée
- Fenêtre de maintenance d'urgence la plus récente (le cas échéant)

Chaque vendredi matin en UTC, Switchboard se met à jour pour afficher les mises à niveau de version de GitLab prévues pour les fenêtres de maintenance de la semaine à venir. Pour plus d'informations, voir [fenêtres de maintenance](maintenance.md#maintenance-windows).

## Sujets connexes {#related-topics}

- [Opérations de maintenance GitLab Dedicated](maintenance.md)
- [Runners hébergés pour GitLab Dedicated](hosted_runners.md)
- [Accès réseau et sécurité de GitLab Dedicated](configure_instance/network_security.md)
