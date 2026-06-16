---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Versions de PostgreSQL livrées avec le package Linux
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

> [!note]
> Ce tableau répertorie uniquement les versions de GitLab où un changement significatif s'est produit dans le package concernant les versions de PostgreSQL, pas toutes.

En général, les versions de PostgreSQL changent avec les releases majeures ou mineures de GitLab. Cependant, les versions de correctifs du package Linux mettent parfois à jour le niveau de correctif de PostgreSQL. Nous avons établi une cadence annuelle pour les mises à niveau de PostgreSQL et déclenchons des mises à niveau automatiques de la base de données dans la release précédant celle pour laquelle la nouvelle version est requise.

Par exemple :

- Le package Linux 12.7.6 était livré avec PostgreSQL 9.6.14 et 10.9.
- Le package Linux 12.7.7 était livré avec PostgreSQL 9.6.17 et 10.12.

Découvrez [quelles versions de PostgreSQL (et d'autres composants) sont livrées](https://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html) avec chaque release du package Linux.

Les versions minimales de PostgreSQL prises en charge sont répertoriées dans les [prérequis d'installation](../../install/requirements.md#postgresql).

Pour en savoir plus sur les politiques de mise à jour et les avertissements, consultez la [documentation de mise à niveau](https://docs.gitlab.com/omnibus/settings/database/#upgrade-packaged-postgresql-server) de PostgreSQL.

| Première version de GitLab | Versions de PostgreSQL | Version par défaut pour les nouvelles installations | Version par défaut pour les mises à niveau | Notes |
| -------------- | ------------------- | ---------------------------------- | ---------------------------- | ----- |
| 18.11.0 | 16.11, 17.7 | 17.7 | 17.7 | Les nouvelles installations utilisent PostgreSQL 17 par défaut. Sauf [désactivation](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades), les mises à niveau des instances du package Linux effectuent automatiquement une mise à niveau vers PostgreSQL 17 pour les nœuds qui ne font pas partie d'un cluster Geo ou HA. |
| 18.4.1, 18.3.3, 18.2.7 | 16.10 | 16.10 | 16.10 | |
| 18.0.0 | 16.8 | 16.8 | 16.8 | Les mises à niveau du package sont abandonnées si PostgreSQL n'a pas déjà été mis à niveau vers la version 16. |
| 17.11.0 | 14.17, 16.8 | 16.8 | 16.8 | Les mises à niveau du package effectuent automatiquement une mise à niveau vers PostgreSQL 16 pour les nœuds qui ne font pas partie d'un cluster Geo ou HA, sauf [désactivation](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades). |
| 17.10.0 | 14.17, 16.8 | 16.8 | 16.8 | Les nouvelles installations utilisent désormais PostgreSQL 16 par défaut. |
| 17.9.2, 17.8.5, 17.7.7 | 14.17, 16.8 | 14.17 | 16.8 | |
| 17.8.0 | 14.15, 16.6 | 14.15 | 16.6 | |
| 17.5.0 | 14.11, 16.4 | 14.11 | 16.4 | Les mises à niveau de nœuds uniques de PostgreSQL 14 vers PostgreSQL 16 sont désormais prises en charge. À partir de GitLab 17.5.0, PostgreSQL 16 est entièrement pris en charge pour les nouvelles installations et les mises à niveau dans les déploiements Geo (la restriction de la version 17.4.0 ne s'applique plus). |
| 17.4.0 | 14.11, 16.4 | 14.11 | 14.11 | PostgreSQL 16 est disponible pour les nouvelles installations si vous n'utilisez pas [Geo](../geo/_index.md#requirements-for-running-geo) ni [Patroni](../postgresql/_index.md#postgresql-replication-and-failover-for-linux-package-installations). |
| 17.0.0 | 14.11 | 14.11 | 14.11 | Les mises à niveau du package sont abandonnées si PostgreSQL n'a pas déjà été mis à niveau vers la version 14. |
| 16.10.1, 16.9.3, 16.8.5 | 13.14, 14.11 | 14.11 | 14.11 | |
| 16.6.7, 16.7.5, 16.8.2 | 13.13, 14.10 | 14.10 | 14.10 | |
| 16.7.0 | 13.12, 14.9 | 14.9 | 14.9 | |
| 16.4.3, 16.5.3, 16.6.1 | 13.12, 14.9 | 13.12 | 13.12 | Pour les mises à niveau, vous pouvez mettre à niveau manuellement vers la version 14.9 en suivant la [documentation de mise à niveau](../../update/versions/gitlab_16_changes.md#linux-package-installations-2). |
| 16.2.0 | 13.11, 14.8 | 13.11 | 13.11 | Pour les mises à niveau, vous pouvez mettre à niveau manuellement vers la version 14.8 en suivant la [documentation de mise à niveau](../../update/versions/gitlab_16_changes.md#linux-package-installations-2). |
| 16.0.2 | 13.11 | 13.11 | 13.11 | |
| 16.0.0 | 13.8  | 13.8  | 13.8  | |
| 15.11.7 | 13.11 | 13.11 | 12.12 | |
| 15.10.8 | 13.11 | 13.11 | 12.12 | |
| 15.6 | 12.12, 13.8 | 13.8 | 12.12 | Pour les mises à niveau, vous pouvez mettre à niveau manuellement vers la version 13.8 en suivant la [documentation de mise à niveau](../../update/versions/gitlab_15_changes.md#linux-package-installations-2). |
| 15.0 | 12.10, 13.6 | 13.6 | 12.10 | Pour les mises à niveau, vous pouvez mettre à niveau manuellement vers la version 13.6 en suivant la [documentation de mise à niveau](../../update/versions/gitlab_15_changes.md#linux-package-installations-2). |
| 14.1 | 12.7, 13.3 | 12.7 | 12.7 | PostgreSQL 13 est disponible pour les nouvelles installations si vous n'utilisez pas [Geo](../geo/_index.md#requirements-for-running-geo) ni [Patroni](../postgresql/_index.md#postgresql-replication-and-failover-for-linux-package-installations). |
| 14.0 | 12.7       | 12.7 | 12.7 | Les installations HA avec repmgr ne sont plus prises en charge et ne peuvent pas être mises à niveau vers le package Linux 14.0 |
| 13.8 | 11.9, 12.4 | 12.4 | 12.4 | Les mises à niveau du package ont automatiquement effectué la mise à niveau de PostgreSQL pour les nœuds qui ne font pas partie d'un cluster Geo ou HA. |
| 13.7 | 11.9, 12.4 | 12.4 | 11.9 | Pour les mises à niveau, les utilisateurs peuvent mettre à niveau manuellement vers la version 12.4 en suivant la [documentation de mise à niveau](https://docs.gitlab.com/omnibus/settings/database/#upgrade-packaged-postgresql-server). |
| 13.4 | 11.9, 12.4 | 11.9 | 11.9 | Les mises à niveau du package sont abandonnées si les utilisateurs n'utilisent pas déjà PostgreSQL 11 |
| 13.3 | 11.7, 12.3 | 11.7 | 11.7 | Les mises à niveau du package sont abandonnées si les utilisateurs n'utilisent pas déjà PostgreSQL 11 |
| 13.0 | 11.7 | 11.7 | 11.7 | Les mises à niveau du package sont abandonnées si les utilisateurs n'utilisent pas déjà PostgreSQL 11 |
| 12.10 | 9.6.17, 10.12 et 11.7 | 11.7 | 11.7 | Les mises à niveau du package ont automatiquement effectué la mise à niveau de PostgreSQL pour les nœuds qui ne font pas partie d'un cluster Geo ou repmgr. |
| 12.8 | 9.6.17, 10.12 et 11.7 | 10.12 | 10.12 | Les utilisateurs peuvent mettre à niveau manuellement vers la version 11.7 en suivant la documentation de mise à niveau. |
| 12.0 | 9.6.11 et 10.7 | 10.7 | 10.7 | Les mises à niveau du package ont automatiquement effectué la mise à niveau de PostgreSQL. |
| 11.11 | 9.6.11 et 10.7 | 9.6.11 | 9.6.11 | Les utilisateurs peuvent mettre à niveau manuellement vers la version 10.7 en suivant la documentation de mise à niveau. |
| 10.0 | 9.6.3 | 9.6.3 | 9.6.3 | Les mises à niveau du package sont abandonnées si les utilisateurs utilisent encore la version 9.2. |
| 9.0 | 9.2.18 et 9.6.1 | 9.6.1 | 9.6.1 | Les mises à niveau du package ont automatiquement effectué la mise à niveau de PostgreSQL. |
| 8.14 | 9.2.18 et 9.6.1 | 9.2.18 | 9.2.18 | Les utilisateurs peuvent mettre à niveau manuellement vers la version 9.6 en suivant la documentation de mise à niveau. |
