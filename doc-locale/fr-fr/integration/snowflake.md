---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Snowflake
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/451328) pour les événements d'audit dans GitLab 17.1.

{{< /history >}}

Le [GitLab Data Connector](https://app.snowflake.com/marketplace/listing/GZTYZXESENG/gitlab-gitlab-data-connector) Snowflake extrait des données dans [Snowflake](https://www.snowflake.com/en/).

Dans Snowflake, vous pouvez ensuite afficher, combiner, manipuler et générer des rapports sur toutes les données. Le GitLab Data Connector est basé sur les [API REST GitLab](../api/rest/_index.md) et nécessite une configuration Snowflake et GitLab.

## Prérequis {#prerequisites}

1. Si vous ne possédez pas de jeton d'accès personnel GitLab :
   1. Connectez-vous à GitLab.
   1. Suivez les étapes décrites pour [créer un jeton d'accès personnel](../user/profile/personal_access_tokens.md#create-a-personal-access-token).
1. Créez une [external access integration](https://docs.snowflake.com/en/developer-guide/external-network-access/creating-using-external-network-access) dans Snowflake. Pour plus d'informations, consultez la [documentation de configuration](https://gitlab.com/gitlab-org/software-supply-chain-security/compliance/engineering/snowflake-connector#setup) dans le projet `snowflake-connector`.
1. Créez un [warehouse](https://docs.snowflake.com/en/user-guide/warehouses-tasks#creating-a-warehouse) dans Snowflake.

## Configurer le GitLab Data Connector {#configure-the-gitlab-data-connector}

1. Connectez-vous à Snowflake.
1. Sélectionnez **Data Products** > **Marketplace**.
1. Recherchez **GitLab Data Connector**.
1. Sélectionnez **Data Products** > **Apps**.
1. Sélectionnez **GitLab Data Connector**.
1. Sélectionnez un [warehouse](https://docs.snowflake.com/en/user-guide/warehouses) sur lequel le GitLab Data Connector s'exécute.
1. Sélectionnez **Start Configuration**.
1. Sélectionnez **Grant privileges**.
1. Saisissez un warehouse et un schéma de destination. Il peut s'agir de n'importe quel warehouse et schéma de votre choix.
1. Sélectionnez **Configurer**.
1. Saisissez une External access integration.
1. Saisissez le chemin où le secret du jeton d'accès personnel GitLab est stocké.
1. Saisissez le domaine de votre instance GitLab. Par exemple, `gitlab.com`.
1. Sélectionnez **Connecter**.
1. Saisissez un nom de groupe. Par exemple, `my-group`.
1. Sélectionnez **Finalize configurator**.
1. Sélectionnez **Configurer**.

## Activer les projets et les groupes {#enable-projects-and-groups}

Après avoir configuré le GitLab Data Connector, vous devez spécifier quels projets ou groupes verront leurs événements d'audit ingérés dans Snowflake. Si vous n'ajoutez pas au moins un projet ou un groupe, aucune donnée n'est ingérée.

### Activer les projets {#enable-projects}

Pour ajouter des projets dont vous souhaitez ingérer les événements d'audit :

1. Connectez-vous à Snowflake.
1. Sélectionnez **Data Products** > **Apps**.
1. Sélectionnez **GitLab Data Connector**.
1. Sélectionnez l'onglet **Enabled Projects**.
1. Saisissez le chemin du projet que vous souhaitez activer. Par exemple, `my-group/my-project`.
1. Sélectionnez **Ajouter**.
1. Répétez l'opération pour chaque projet supplémentaire.

### Activer les groupes {#enable-groups}

Pour ajouter des groupes dont vous souhaitez ingérer les événements d'audit :

1. Connectez-vous à Snowflake.
1. Sélectionnez **Data Products** > **Apps**.
1. Sélectionnez **GitLab Data Connector**.
1. Sélectionnez l'onglet **Enabled Groups**.
1. Saisissez le chemin du groupe que vous souhaitez activer. Par exemple, `my-group`.
1. Sélectionnez **Ajouter**.
1. Répétez l'opération pour chaque groupe supplémentaire.

## Afficher les données dans Snowflake {#view-data-in-snowflake}

1. Connectez-vous à Snowflake.
1. Sélectionnez **Data** > **Bases de données**.
1. Sélectionnez le warehouse précédemment configuré.

## Dépannage {#troubleshooting}

### Aucune donnée n'apparaît dans Snowflake {#no-data-appearing-in-snowflake}

Si aucune donnée n'apparaît dans Snowflake, vérifiez les points suivants :

- Vous n'avez pas ajouté au moins un projet ou un groupe dans l'onglet **Enabled Projects** ou **Enabled Groups**. Pour plus d'informations, consultez [Activer les projets et les groupes](#enable-projects-and-groups).
- Le jeton d'accès personnel GitLab ne dispose pas des portées requises pour lire les événements d'audit.
- Le warehouse Snowflake configuré pour le GitLab Data Connector est suspendu.
