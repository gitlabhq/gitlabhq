---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utiliser la base de données de métadonnées du registre de conteneurs GitLab avec Geo
description: Utiliser la base de données de métadonnées du registre de conteneurs GitLab avec Geo
---

Utilisez le registre de conteneurs GitLab avec Geo pour répliquer des images de conteneurs. La base de données de métadonnées du registre de conteneurs de chaque site est indépendante et n'utilise pas la réplication Postgres.

Chaque site secondaire doit avoir sa propre instance PostgreSQL distincte pour la base de données de métadonnées.

## Créer une instance GitLab avec le registre de conteneurs et Geo {#create-a-gitlab-instance-with-the-container-registry-and-geo}

Prérequis :

- Une nouvelle instance de GitLab.
- Un registre de conteneurs configuré pour l'instance sans données.

Pour configurer la prise en charge de Geo :

1. Configurez Geo pour un site principal et un site secondaire. Pour plus d'informations, consultez [Configurer Geo pour deux sites à nœud unique](../../geo/setup/two_single_node_sites.md).
1. Sur les sites principal et secondaire, configurez [la base de données de métadonnées](../container_registry_metadata_database_new_install.md) en utilisant une [base de données externe](../container_registry_metadata_database.md#using-an-external-database) distincte pour chaque site.
1. Configurez la [réplication du registre de conteneurs](../../geo/replication/container_registry.md#configure-container-registry-replication).

## Ajouter des registres de conteneurs à des sites Geo existants {#add-container-registries-to-existing-geo-sites}

Prérequis :

- Deux nouvelles instances de GitLab, configurées comme sites principal et secondaire.
- Un registre de conteneurs configuré pour le site principal sans données.

Pour ajouter des registres de conteneurs à des sites secondaires Geo existants :

1. Sur le site secondaire, [activez le registre de conteneurs](../container_registry.md).
1. Sur les sites principal et secondaire, configurez [la base de données de métadonnées](../container_registry_metadata_database_new_install.md) en utilisant une [base de données externe](../container_registry_metadata_database.md#using-an-external-database) distincte pour chaque site.
1. Configurez la [réplication du registre de conteneurs](../../geo/replication/container_registry.md#configure-container-registry-replication).

## Ajouter la prise en charge de Geo et le registre de conteneurs à une instance existante de GitLab {#add-geo-support-and-container-registry-to-an-existing-instance-of-gitlab}

Prérequis :

- Une instance existante de GitLab sans registre de conteneurs configuré.
- Aucun site Geo existant.

Pour ajouter la prise en charge de Geo à une instance existante et des registres de conteneurs aux deux sites Geo :

1. Configurez Geo pour l'instance existante (principale) et ajoutez un site secondaire. Pour plus d'informations, consultez [Configurer Geo pour deux sites à nœud unique](../../geo/setup/two_single_node_sites.md).
1. Sur les sites principal et secondaire :
   1. [Activez le registre de conteneurs](../container_registry.md#enable-the-container-registry).
   1. Configurez [la base de données de métadonnées](../container_registry_metadata_database_new_install.md) en utilisant une [base de données externe](../container_registry_metadata_database.md#using-an-external-database) distincte pour chaque site.
1. Configurez la [réplication du registre de conteneurs](../../geo/replication/container_registry.md#configure-container-registry-replication).

## Ajouter la prise en charge de Geo à une instance avec un registre de conteneurs configuré {#add-geo-support-to-an-instance-with-a-configured-container-registry}

Les sections suivantes fournissent des instructions pour ajouter la prise en charge de Geo à une instance existante de GitLab avec un registre de conteneurs configuré.

Vous pouvez configurer l'une ou l'autre des options suivantes :

- Une connexion à une base de données externe.
- La base de données de métadonnées du registre de conteneurs par défaut.

### Utiliser une base de données de métadonnées de registre de conteneurs externe {#use-an-external-container-registry-metadata-database}

Prérequis :

- Une instance existante de GitLab avec un registre de conteneurs configuré.
- Aucun site Geo existant.

Pour ajouter la prise en charge de Geo à une instance existante et le registre de conteneurs au site secondaire :

1. Configurez Geo pour l'instance existante (principale) et ajoutez un site secondaire. Pour plus d'informations, consultez [Configurer Geo pour deux sites à nœud unique](../../geo/setup/two_single_node_sites.md).
1. Sur le site secondaire :
   1. [activez le registre de conteneurs](../container_registry.md#enable-the-container-registry).
   1. Configurez [la base de données de métadonnées](../container_registry_metadata_database_new_install.md) en utilisant une [base de données externe](../container_registry_metadata_database.md#using-an-external-database) distincte.
1. Configurez la [réplication du registre de conteneurs](../../geo/replication/container_registry.md#configure-container-registry-replication).

### Utiliser la base de données de métadonnées du registre de conteneurs par défaut {#use-the-default-container-registry-metadata-database}

Prérequis :

- Une instance existante de GitLab avec un registre de conteneurs configuré.
- Une base de données de métadonnées de registre de conteneurs qui utilise l'instance PostgreSQL par défaut.
- Aucun site Geo existant.

Dans ce scénario, la base de données de métadonnées doit être déplacée vers une instance PostgreSQL externe.

1. Suivez les étapes ici pour [déplacer la base de données de métadonnées vers une instance PostgreSQL externe](../../postgresql/moving.md).
1. Poursuivez avec les étapes pour [Ajouter la prise en charge de Geo et le registre de conteneurs à une instance existante de GitLab](#add-geo-support-and-container-registry-to-an-existing-instance-of-gitlab).

## Migrer le registre de conteneurs depuis les métadonnées héritées {#migrate-the-container-registry-from-legacy-metadata}

Dans ce scénario, vous devez migrer le registre de conteneurs depuis les métadonnées héritées vers la base de données de métadonnées PostgreSQL externe sur un site Geo existant.

Prérequis :

- GitLab 17.3 ou version ultérieure (prise en charge des métadonnées de base de données)
- Geo configuré sur les sites principal et secondaire
- Registres de conteneurs sur les deux sites utilisant des métadonnées héritées
- Les deux registres doivent avoir des données existantes (images envoyées)

### Étapes de migration {#migration-steps}

L'interruption de service dépend de la méthode d'importation. Pour des recommandations sur les méthodes d'importation, consultez [choisir la bonne méthode d'importation](../container_registry_metadata_database.md#choose-the-right-import-method).

> [!note]
> Le registre en cours de migration est en lecture seule pendant l'importation.

Pendant la migration, le reste de la réplication Geo continue.

Pour migrer votre base de données de métadonnées :

1. Sur le site secondaire, [migrez les métadonnées héritées existantes vers la nouvelle base de données de métadonnées](../container_registry_metadata_database.md#enable-the-database-for-existing-registries).
1. Sur le site principal, [migrez les métadonnées héritées existantes vers la nouvelle base de données de métadonnées](../container_registry_metadata_database.md#enable-the-database-for-existing-registries).
1. Vérifiez que la réplication Geo continue de fonctionner.
