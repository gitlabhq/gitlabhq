---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Objectifs de reprise, processus de basculement et stratégies de sauvegarde régionale pour les instances GitLab Dedicated."
title: Reprise après sinistre pour GitLab Dedicated
---

{{< details >}}

- Niveau : Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

GitLab Dedicated assure une reprise après sinistre automatique pour restaurer votre instance si votre région principale devient indisponible. Pour être éligible aux objectifs de reprise complets :

- Configurez une région principale et une région secondaire lorsque vous [créez votre instance](create_instance/_index.md).
- Sélectionnez des régions [prises en charge par GitLab Dedicated](create_instance/data_residency_high_availability.md#supported-regions).

Si aucune région secondaire n'est configurée, la reprise est limitée à la restauration des sauvegardes.

## Objectifs de reprise {#recovery-objectives}

GitLab Dedicated assure la reprise après sinistre avec ces objectifs de reprise :

- Objectif de délai de reprise (RTO) :  Le service est restauré dans votre région secondaire en huit heures ou moins.
- Objectif de point de reprise (RPO) :  La perte de données est limitée à un maximum de quatre heures des modifications les plus récentes, selon le moment où le sinistre survient par rapport à la dernière sauvegarde.

## Réplication Geo {#geo-replication}

Lorsque vous créez votre instance, vous sélectionnez une région principale et une région secondaire pour votre environnement. Geo réplique en continu les données entre ces régions, notamment :

- Contenu de la base de données
- Stockage du dépôt
- Stockage d'objets

## Sauvegardes automatisées {#automated-backups}

GitLab effectue des sauvegardes automatisées de tous les magasins de données GitLab Dedicated (y compris les bases de données et les dépôts Git) toutes les quatre heures (six fois par jour) en créant des instantanés.

Les sauvegardes sont testées, conservées pendant 30 jours et stockées dans votre région secondaire choisie. Elles sont également répliquées géographiquement par AWS pour une protection supplémentaire.

Sauvegardes de bases de données :

- Utilisent des sauvegardes continues basées sur les journaux dans la région principale pour une reprise à un instant donné.
- Répliquent en flux continu vers la région secondaire pour fournir une copie quasi en temps réel.

Les sauvegardes de stockage d'objets utilisent la réplication géographique et la gestion des versions pour assurer la protection des sauvegardes.

La fréquence de sauvegarde de quatre heures prend en charge l'objectif de point de reprise (RPO) pour garantir que vous ne perdez pas plus de quatre heures de données.

## Couverture des sinistres {#disaster-coverage}

La reprise après sinistre couvre ces scénarios avec des objectifs de reprise garantis :

- Panne partielle de la région (par exemple, défaillance d'une zone de disponibilité)
- Panne complète de votre région principale

Ces scénarios sont couverts sur la base du meilleur effort, sans objectifs de reprise garantis :

- Perte des régions principale et secondaire
- Pannes mondiales d'Internet
- Problèmes de corruption des données

## Limitations du service {#service-limitations}

La reprise après sinistre présente ces limitations de service :

- Les index de recherche avancée ne sont pas répliqués en continu. Après le basculement, ces index sont reconstruits lorsque la région secondaire est promue. La recherche de base reste disponible pendant la reconstruction.
- ClickHouse Cloud est provisionné uniquement dans la région principale. Les fonctionnalités qui nécessitent ce service peuvent être indisponibles si la région principale est complètement hors ligne.
- Les environnements de prévisualisation de production n'ont pas d'instances secondaires.
- Les runners hébergés sont pris en charge uniquement dans la région principale et ne peuvent pas être reconstruits dans l'instance secondaire.
- Certaines régions ont une disponibilité de fonctionnalités limitée en raison des contraintes de service AWS. Pour plus d'informations, consultez [les régions prises en charge](create_instance/data_residency_high_availability.md#supported-regions). Ces limitations de fonctionnalités n'affectent pas les capacités de reprise après sinistre ni les cibles RTO et RPO.

GitLab ne fournit pas :

- Surveillance programmatique des événements de basculement
- Tests de reprise après sinistre initiés par le client

## Processus de basculement {#failover-process}

Lorsque votre instance devient indisponible en raison d'une défaillance complète de la région ou d'une défaillance d'un composant critique ne pouvant pas être rapidement récupéré, l'équipe GitLab Dedicated :

1. Est alertée par les systèmes de surveillance.
1. Examine si un basculement est nécessaire.
1. Si un basculement est nécessaire :
   1. Vous notifie que le basculement est en cours.
   1. Promeut la région secondaire en région principale.
   1. Met à jour les enregistrements DNS pour `<customer>.gitlab-dedicated.com` afin de pointer vers la région nouvellement promue.
   1. Vous notifie lorsque le basculement est terminé.

Si vous utilisez PrivateLink, vous devez mettre à jour votre configuration réseau interne pour cibler le point de terminaison PrivateLink de la région secondaire. Pour minimiser les temps d'arrêt, configurez des points de terminaison PrivateLink équivalents dans votre région secondaire avant qu'un sinistre ne survienne.

Le processus de basculement se termine généralement en 90 minutes ou moins. Tout au long du processus, GitLab communique avec vous via un ou plusieurs des canaux suivants :

- Vos informations de contact opérationnel dans Switchboard
- Slack
- Tickets de support

GitLab peut créer un canal Slack temporaire et un pont Zoom pour coordonner avec votre équipe tout au long du processus de reprise.

## Sujets connexes {#related-topics}

- [Résidence des données et haute disponibilité](create_instance/data_residency_high_availability.md)
- [Architecture de GitLab Dedicated](architecture.md)
