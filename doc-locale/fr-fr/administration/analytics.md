---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: "Activer et configurer ClickHouse pour l'analyse de données dans GitLab."
title: "Utiliser ClickHouse pour les rapports d'analyse"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Le collecteur de données ClickHouse a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/414610) dans GitLab 16.3 [avec un flag](feature_flags/_index.md) nommé `clickhouse_data_collection`. Désactivé par défaut.
- Le feature flag `clickhouse_data_collection` a été supprimé dans GitLab 17.0 et remplacé par un paramètre d'application.

{{< /history >}}

Le rapport [d'analyse des contributions](../user/group/contribution_analytics/_index.md), le [tableau de bord CI/CD analytics](../user/analytics/ci_cd_analytics.md) et la métrique de comptage des contributeurs du [tableau de bord Value Streams](../user/analytics/value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports) peuvent utiliser ClickHouse comme source de données.

Prérequis :

- [ClickHouse configuré](../integration/clickhouse.md) sur votre instance.
- Accès administrateur.

Pour activer ClickHouse :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Dans la section **Données d'analyse**, cochez la case **Activer ClickHouse**.
