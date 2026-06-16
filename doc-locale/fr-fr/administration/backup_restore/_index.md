---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Vue d'ensemble de la sauvegarde et de la restauration"
description: Sauvegarder et restaurer une instance GitLab.
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Votre instance GitLab contient des données critiques pour votre développement logiciel ou votre organisation. Il est important de disposer d'un plan de reprise après sinistre qui inclut des sauvegardes régulières pour :

- Protection des données : Se prémunir contre la perte de données due à des pannes matérielles, des bogues logiciels ou des suppressions accidentelles.
- Reprise après sinistre : Restaurer les instances GitLab et les données en cas d'événements défavorables.
- Contrôle de version : Fournir des instantanés historiques permettant des retours arrière vers des états précédents.
- Conformité : Satisfaire aux exigences réglementaires de secteurs spécifiques.
- Migration : Faciliter le déplacement de GitLab vers de nouveaux serveurs ou environnements.
- Tests et développement : Créer des copies pour tester les mises à niveau ou les nouvelles fonctionnalités sans risque pour les données de production.

> [!note]
> Cette documentation s'applique à GitLab Community Edition et Enterprise Edition. Bien que la sécurité des données soit garantie pour GitLab.com, vous ne pouvez pas utiliser ces méthodes pour exporter ou sauvegarder vos données depuis GitLab.com.

## Sauvegarder GitLab {#back-up-gitlab}

Les procédures de sauvegarde de votre instance GitLab varient en fonction de la configuration spécifique et des modèles d'utilisation de votre déploiement. Des facteurs tels que les types de données, les emplacements de stockage et le volume influencent la méthode de sauvegarde, les options de stockage et le processus de restauration. Pour plus d'informations, consultez [Sauvegarder GitLab](backup_gitlab.md).

## Restaurer GitLab {#restore-gitlab}

Les procédures de sauvegarde de votre instance GitLab varient en fonction de la configuration spécifique et des modèles d'utilisation de votre déploiement. Des facteurs tels que les types de données, les emplacements de stockage et le volume influencent le processus de restauration.

Pour plus d'informations, consultez [Restaurer GitLab](restore_gitlab.md).

## Migrer vers un nouveau serveur {#migrate-to-a-new-server}

Utilisez les fonctionnalités de sauvegarde et de restauration de GitLab pour migrer votre instance vers un nouveau serveur. Pour les déploiements GitLab Geo, envisagez la [reprise après sinistre Geo pour un basculement planifié](../geo/disaster_recovery/planned_failover.md). Pour plus d'informations, consultez [Migrer vers un nouveau serveur](migrate_to_new_server.md).

## Sauvegarder et restaurer les grandes architectures de référence {#back-up-and-restore-large-reference-architectures}

Il est important de sauvegarder et de restaurer régulièrement les grandes architectures de référence. Pour savoir comment configurer et restaurer des sauvegardes pour les données de stockage d'objets, les données PostgreSQL et les dépôts Git, consultez [Sauvegarder et restaurer les grandes architectures de référence](backup_large_reference_architectures.md).

## Processus d'archivage de sauvegarde {#backup-archive-process}

Pour la préservation des données et l'intégrité du système, GitLab crée une archive de sauvegarde. Pour des informations détaillées sur la façon dont GitLab crée cette archive, consultez [Processus d'archivage de sauvegarde](backup_archive_process.md).

## Sujets connexes {#related-topics}

- [Geo](../geo/_index.md)
- [Reprise après sinistre (Geo)](../geo/disaster_recovery/_index.md)
- [Migration des groupes GitLab](../../user/group/import/_index.md)
- [Importer et migrer vers GitLab](../../user/import/_index.md)
- [Paquet Linux GitLab (Omnibus) - Sauvegarde et restauration](https://docs.gitlab.com/omnibus/settings/backups/)
- [Chart Helm GitLab - Sauvegarde et restauration](https://docs.gitlab.com/charts/backup-restore/)
- [Opérateur GitLab - Sauvegarde et restauration](https://docs.gitlab.com/operator/backup_and_restore/)
