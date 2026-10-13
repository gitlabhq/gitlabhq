---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Environnements de cluster (obsolète)
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!flag]
> Cette fonctionnalité n'est pas disponible par défaut sur GitLab Self-Managed. Pour rendre cette fonctionnalité disponible, un administrateur peut [activer le feature flag](../../administration/feature_flags/_index.md) `certificate_based_clusters`.

Les environnements de cluster offrent une vue consolidée des [environnements](../../ci/environments/_index.md) CI déployés sur le cluster Kubernetes. Cette vue :

- Affiche le projet et l'environnement concerné par le déploiement.
- Affiche le statut des pods pour cet environnement.

Grâce aux environnements de cluster, vous pouvez obtenir des informations sur :

- Les projets déployés sur le cluster.
- Le nombre de pods utilisés pour l'environnement de chaque projet.
- Le job CI utilisé pour effectuer le déploiement dans cet environnement.

![La page des environnements de cluster affichant une liste de projets, leurs environnements et le statut des pods.](img/cluster_environments_table_v12_3.png)

L'accès aux environnements de cluster est réservé aux [mainteneurs et propriétaires de groupe](../permissions.md#group-permissions).

## Utilisation {#usage}

Pour :

- Suivre les environnements pour le cluster, vous devez [déployer sur un cluster Kubernetes](../project/clusters/deploy_to_cluster.md) avec succès.
- Afficher correctement l'utilisation des pods, vous devez [activer les tableaux de déploiement](../project/deploy_boards.md#enabling-deploy-boards).

Après avoir effectué des déploiements réussis sur votre cluster de groupe ou de niveau instance :

1. Accédez à la page **Kubernetes** de votre groupe.
1. Sélectionnez l'onglet **Environnements**.

Seuls les déploiements réussis sur le cluster sont inclus dans cette page. Les environnements hors cluster ne sont pas inclus.
