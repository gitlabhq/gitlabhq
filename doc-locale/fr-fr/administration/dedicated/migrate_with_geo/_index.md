---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Migrer de GitLab Self-Managed vers GitLab Dedicated avec Geo.
title: Migrer vers GitLab Dedicated avec Geo
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

Geo réplique votre instance GitLab Self-Managed vers GitLab Dedicated, puis la promeut en tant que site principal. Cette méthode migre l'ensemble de données le plus complet, incluant les dépôts, les enregistrements de base de données et le contenu du stockage d'objets.

Votre instance reste en service tout au long de la réplication. La migration elle-même nécessite une interruption de service uniquement pendant la fenêtre de basculement. Cependant, la préparation de votre instance source au préalable peut nécessiter une interruption de service séparée.

GitLab Professional Services exécute la migration avec vous. Geo s'applique uniquement lorsque votre source est une instance GitLab Self-Managed. Pour migrer depuis GitLab.com ou depuis un autre système de gestion du code source, ou pour migrer des groupes et des projets individuels plutôt qu'une instance entière, consultez [migrer vers GitLab Dedicated](../../../subscriptions/gitlab_dedicated/_index.md#migrate-to-gitlab-dedicated).

## Phases de migration {#migration-phases}

Une migration Geo se déroule selon les phases suivantes :

| Phase | Ce qui se passe | Qui agit |
|-------|--------------|----------|
| Découverte et planification | Avant de finaliser votre achat de GitLab Dedicated, votre architecte de solutions ou votre chargé de compte vous aide à collecter des informations sur votre environnement. GitLab utilise ces informations pour évaluer la faisabilité de la migration, le dimensionnement et le calendrier. | Vous et GitLab |
| Création de l'instance | Une fois votre achat finalisé, vous créez vous-même votre instance GitLab Dedicated, ou GitLab Professional Services la crée avec vous si vous le préférez. | Vous |
| Préparation | Vous déplacez les données vers le stockage d'objets, alignez les noms de stockage des dépôts, établissez la connectivité de migration et créez des réplicas de lecture de la base de données. Vous pouvez effectuer ce travail vous-même ou avec GitLab. Pour plus d'informations, consultez [les exigences de migration Geo](requirements.md) et [la collecte des secrets de migration Geo](secrets.md). | Vous, ou vous et GitLab |
| Réplication Geo | Pendant que GitLab réplique vos données vers votre nouvelle instance GitLab Dedicated, votre instance existante reste en service. Pour plus d'informations, consultez [le processus de migration Geo](process.md). | GitLab |
| Basculement et tests | Vous répétez le processus avec un basculement en pré-production, testez le résultat, puis finalisez la migration avec le basculement en production. | Vous et GitLab |
| Activités post-migration | GitLab applique les mises à niveau restantes et active des fonctionnalités telles que la recherche avancée, selon un calendrier convenu avec vous. Vous ajoutez votre licence GitLab Dedicated. Pour plus d'informations, consultez [les activités post-migration](post_cutover.md). | Vous et GitLab |

GitLab Professional Services utilise le [kit de livraison de migration Geo](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md) pour les procédures techniques et les scripts étape par étape tout au long de ces phases.

Prévoyez plusieurs mois entre la découverte et le basculement en production. GitLab confirme le calendrier avec vous, car il dépend de la quantité de données que vous possédez et de la quantité de travail de préparation que nécessite votre environnement.

> [!note]
> Vous n'avez besoin que d'un seul environnement qui vous appartient. Vous migrez depuis votre unique instance de production. GitLab provisionne à la fois un tenant de pré-production et un tenant de production, et le tenant de pré-production n'existe que pendant la fenêtre de migration afin qu'une répétition complète du basculement puisse être effectuée. Vous n'avez pas à le créer ni à le maintenir.

## Sujets connexes {#related-topics}

- [Architecture de GitLab Dedicated](../architecture.md)
- [Créer votre instance GitLab Dedicated](../create_instance/_index.md)
- [Geo](../../geo/_index.md)
