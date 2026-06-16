---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Fenêtres de maintenance planifiées, procédures d'urgence et gestion des contacts pour les instances GitLab Dedicated."
title: Opérations de maintenance de GitLab Dedicated
---

{{< details >}}

- Niveau : Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

GitLab Dedicated assure une maintenance régulière de votre instance afin de garantir la sécurité, la fiabilité et des performances optimales pendant les fenêtres hebdomadaires planifiées.

## Fenêtres de maintenance {#maintenance-windows}

La maintenance est effectuée pendant des fenêtres hebdomadaires planifiées en dehors des heures ouvrables standard. Vous choisissez votre fenêtre de maintenance lors de l'intégration, et elle ne peut pas être modifiée une fois votre instance créée.

### Calendrier des fenêtres de maintenance {#maintenance-window-schedule}

Les fenêtres de maintenance suivantes sont répertoriées par ordre chronologique :

| Région                          | Jour           | Heure (UTC) |
| ------------------------------- | ------------- | ---------- |
| Europe, Moyen-Orient et Afrique | Mardi       | 1h00-5h00 |
| Amériques (Option 1)             | Mardi       | 7h00-11h00 |
| Asie-Pacifique                    | Mercredi     | 13h00-17h00 |
| Amériques (Option 2)             | Dimanche-Lundi | 21h00-1h00 |

Pour afficher votre fenêtre de maintenance assignée, accédez à [Switchboard](tenant_overview.md).

Pendant les fenêtres de maintenance planifiées, les tâches suivantes peuvent être effectuées :

- Correctifs et mises à niveau des logiciels d'application et du système d'exploitation
- Redémarrages du système d'exploitation
- Mises à niveau de l'infrastructure
- Améliorations de la sécurité et de la disponibilité
- Améliorations des fonctionnalités

### Accès pendant la maintenance {#access-during-maintenance}

Aucune interruption de service n'est prévue pour toute la durée de votre fenêtre de maintenance. Une brève interruption de service (moins d'une minute) peut survenir lors du redémarrage des ressources de calcul après les mises à niveau, généralement pendant la première moitié de la fenêtre de maintenance.

Les connexions de longue durée peuvent être interrompues pendant cette période. Pour minimiser les perturbations, vous pouvez mettre en œuvre des stratégies telles que la récupération automatique et les nouvelles tentatives.

Les interruptions de service prolongées sont rares. Si une interruption prolongée est prévue, vous en serez informé à l'avance.

> [!note]
> La dégradation des performances ou les interruptions de service pendant la fenêtre de maintenance planifiée ne sont pas comptabilisées dans la disponibilité du niveau de service système (SLA).

### Exceptions de planification {#scheduling-exceptions}

Un verrou de modification de production (PCL) est une pause complète de toutes les modifications de production pendant les périodes de disponibilité réduite de l'équipe, telles que les grands jours fériés. Un PCL garantit la stabilité du système lorsque les ressources de support sont limitées.

Pendant un PCL, les éléments suivants sont mis en pause :

- Modifications de configuration à l'aide de Switchboard
- Déploiements de code ou modifications d'infrastructure
- Maintenance automatisée
- Intégration de nouveaux clients

Si un PCL est actif pendant votre mise à niveau planifiée, la mise à niveau est reportée à la première fenêtre de maintenance après la fin du PCL.

Lorsqu'un PCL est actif, une bannière de notification s'affiche dans Switchboard.

## Mises à niveau sans interruption de service {#zero-downtime-upgrades}

GitLab Dedicated propose des mises à niveau sans interruption de service pour garantir la rétrocompatibilité de votre instance. Lorsqu'aucune modification d'infrastructure ni aucune tâche de maintenance ne nécessite d'interruption de service, vous pouvez continuer à utiliser votre instance en toute sécurité pendant les mises à niveau.

Pour garantir la disponibilité des ressources lors des mises à niveau de version :

1. Chaque ressource statique possède un nom unique qui change lorsque son contenu change.
1. Les navigateurs mettent en cache chaque ressource statique.
1. Chaque requête provenant du même navigateur est temporairement acheminée vers le même serveur.

Les mises à niveau sont généralement imperceptibles. Dans de rares cas, vous pourriez constater des incohérences d'interface temporaires lors d'une mise à niveau. Si cela se produit, actualisez la page pour résoudre toute incohérence visuelle.

> [!note]
> L'implémentation d'un proxy de mise en cache dans votre réseau réduit davantage le risque d'incohérences d'interface lors des mises à niveau.

## Maintenance d'urgence {#emergency-maintenance}

La maintenance d'urgence est déclenchée lorsque votre instance nécessite des actions urgentes. Cette maintenance peut avoir lieu en dehors de vos fenêtres de maintenance planifiées et ne peut pas être reportée.

Par exemple, lorsqu'une vulnérabilité de sécurité critique (S1) nécessite un correctif urgent, votre instance fait l'objet d'une maintenance d'urgence pour la mettre à niveau vers une version sécurisée.

Pendant la maintenance d'urgence, la stabilité et la sécurité sont prioritaires tout en minimisant l'impact sur votre service. Toutes les modifications suivent les processus internes et font l'objet d'une révision et d'une approbation internes appropriées avant d'être appliquées à votre instance.

Vous recevez un préavis lorsque cela est possible et des informations complètes une fois le ticket résolu. L'équipe GitLab :

- Envoie des notifications à vos contacts opérationnels via Switchboard.
- Met en copie votre Customer Success Manager (CSM) sur toutes les communications.

Pour vous assurer de recevoir ces notifications, [vérifiez vos coordonnées](configure_instance/users_notifications.md#manage-email-addresses-for-operational-contacts) dans Switchboard.

## Sujets connexes {#related-topics}

- [Versions et gestion des versions de GitLab Dedicated](releases.md)
- [Vue d'ensemble du locataire](tenant_overview.md)
- [Politique de release et de maintenance de GitLab](../../policy/maintenance.md)
- [Mises à niveau sans interruption de service](../../update/zero_downtime.md)
