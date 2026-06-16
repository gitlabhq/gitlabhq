---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Glossaire Geo
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

> [!note]
> Nous mettons à jour la documentation Geo, l'interface utilisateur et les commandes pour refléter ces modifications. Toutes les pages ne sont pas encore conformes à ces définitions.

Voici les termes définis pour décrire tous les aspects de Geo. L'utilisation d'un ensemble de termes clairement définis nous aide à communiquer efficacement et évite toute confusion. Le langage utilisé sur cette page vise à être universel et aussi simple que possible.

## Termes principaux {#main-terms}

Nous fournissons des [exemples de diagrammes et d'énoncés](#examples) pour illustrer l'utilisation correcte des termes.

| Terme                   | Définition                                                                                                                                                                                     | Portée        | Synonymes déconseillés                            |
|------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------|-------------------------------------------------|
| Nœud                   | Un serveur individuel qui exécute GitLab soit avec un rôle spécifique, soit dans son intégralité (par exemple, un nœud d'application Rails). Dans un contexte cloud, il peut s'agir d'un type de machine spécifique.                | GitLab       | instance, serveur                                |
| Site                   | Un ou plusieurs nœuds exécutant une seule application GitLab. Un site peut être à nœud unique ou à plusieurs nœuds.                                                                                     | GitLab       | déploiement, instance d'installation               |
| Site à nœud unique       | Une configuration spécifique de GitLab qui utilise exactement un seul nœud.                                                                                                                                 | GitLab       | single-server, single-instance                  |
| Site multi-nœuds        | Une configuration spécifique de GitLab qui utilise plus d'un nœud.                                                                                                                               | GitLab       | multi-server, multi-instance, haute disponibilité |
| Site principal           | Un site GitLab dont les données sont répliquées par au moins un site secondaire. Il ne peut y avoir qu'un seul site principal.                                                                          | Spécifique à Geo | Déploiement Geo, nœud principal                    |
| Site secondaire         | Un site GitLab configuré pour répliquer les données d'un site principal. Il peut y avoir un ou plusieurs sites secondaires.                                                                            | Spécifique à Geo | Déploiement Geo, nœud secondaire                  |
| Déploiement Geo         | Un ensemble de deux sites GitLab ou plus, avec exactement un site principal répliqué par un ou plusieurs sites secondaires.                                                                        | Spécifique à Geo |                                                 |
| Architecture de référence | Une [configuration spécifiée de GitLab basée sur le nombre de requêtes par seconde ou le nombre d'utilisateurs](../reference_architectures/_index.md), incluant éventuellement plusieurs nœuds et plusieurs sites.                  | GitLab       |                                                 |
| Promotion              | Modification du rôle d'un site, le faisant passer de secondaire à principal.                                                                                                                                         | Spécifique à Geo |                                                 |
| Rétrogradation               | Modification du rôle d'un site, le faisant passer de principal à secondaire.                                                                                                                                         | Spécifique à Geo |                                                 |
| Basculement               | L'ensemble du processus qui transfère les utilisateurs d'un site principal vers un site secondaire. Cela inclut la promotion d'un site secondaire, mais comporte également d'autres étapes. Par exemple, la planification d'une maintenance.      | Spécifique à Geo |                                                 |
| Réplication            | Également appelée « synchronisation ». Le processus unidirectionnel qui met à jour une ressource sur un site secondaire afin qu'elle corresponde à la ressource du site principal.                                              | Spécifique à Geo |                                                 |
| Slot de réplication       | La fonctionnalité de réplication PostgreSQL qui garantit un point de connexion persistant avec la base de données et suit les segments WAL encore nécessaires aux serveurs de secours. Il peut être utile de nommer les slots de réplication pour qu'ils correspondent à `geo_node_name` d'un site, mais cela n'est pas obligatoire. | PostgreSQL   |                                                 |
| Vérification           | Le processus de comparaison des données existant sur un site principal aux données répliquées sur un site secondaire. Utilisé pour garantir l'intégrité des données répliquées.                                        | Spécifique à Geo |                                                 |
| URL unifiée            | Une URL externe unique utilisée pour tous les sites Geo. Permet d'acheminer les requêtes vers le site Geo principal ou vers n'importe quel site Geo secondaire.                                                          | Spécifique à Geo |                                                 |
| Proxying Geo           | Un mécanisme par lequel les sites Geo secondaires transmettent de manière transparente les opérations au site principal, à l'exception de certaines opérations pouvant être traitées localement par les sites secondaires.                  | Spécifique à Geo |                                                 |
| Blob                   | Type de données lié à Geo pouvant être répliqué pour couvrir divers composants GitLab.                                                                                                              | Spécifique à Geo | fichier                                            |

## Termes des réplicateurs {#replicator-terms}

Geo utilise des réplicateurs pour répliquer les données des composants GitLab individuels entre les sites principal et secondaires. Ils définissent comment les [types de données](replication/datatypes.md#data-types) individuels de ces composants doivent être traités et vérifiés. Par exemple, les données du registre de conteneurs GitLab doivent être traitées différemment des artefacts de job CI. Certains composants peuvent avoir plus d'un réplicateur, potentiellement nommés différemment. Ainsi, le tableau suivant décrit les noms des réplicateurs et le composant GitLab auquel ils appartiennent.

Les mêmes noms de réplicateurs sont également visibles dans la section Geo de la zone d'administration ou lors de l'utilisation de commandes console liées à Geo.

| Nom du réplicateur Geo            | Nom du composant GitLab                  |
|--------------------------------|----------------------------------------|
| CI Secure Files                | CI Secure Files                        |
| Container Repositories         | Registre de conteneurs                     |
| Dependency Proxy Blobs         | Dependency Proxy Images                |
| Dependency Proxy Manifests     | Dependency Proxy Images                |
| Design Management Repositories | Dépôt de designs de projet             |
| Group Wiki Repositories        | Dépôt wiki de groupe                  |
| CI Job Artifacts               | Artefacts de job CI                       |
| LFS Objects                    | Objets LFS                            |
| Merge Request Diffs            | Différences de merge request externes           |
| Package Files                  | Registre de paquets                       |
| Pages Deployments              | Pages                                  |
| Pipeline Artifacts             | Artefacts de pipeline                     |
| Project Repositories           | Dépôt de projet                     |
| Project Wiki Repositories      | Dépôt wiki de projet                |
| Snippet Repositories           | Snippets personnels et snippets de projet |
| Terraform State Versions       | État Terraform versionné              |
| Uploads                        | Téléversements des utilisateurs                           |

## Exemples {#examples}

### Site à nœud unique {#single-node-site}

Un site avec un seul nœud exécutant GitLab :

- Nœud GitLab

### Site multi-nœuds {#multi-node-site}

Un site avec plusieurs nœuds exécutant différents composants GitLab :

- Nœud d'application
- Nœud de base de données
- Nœud Gitaly

### Déploiement Geo – Sites à nœud unique {#geo-deployment---single-node-sites}

Ce déploiement Geo comporte un site principal à nœud unique et un site secondaire à nœud unique :

Site principal (nœud unique) :

- Nœud GitLab

Site secondaire 1 (nœud unique) :

- Nœud GitLab

### Déploiement Geo – Sites multi-nœuds {#geo-deployment---multi-node-sites}

Ce déploiement Geo comporte un site principal multi-nœuds et un site secondaire multi-nœuds :

Site principal (multi-nœuds) :

- Nœud d'application
- Nœud de base de données

Site secondaire 1 (multi-nœuds) :

- Nœud d'application
- Nœud de base de données

### Déploiement Geo – Sites mixtes {#geo-deployment---mixed-sites}

Ce déploiement Geo comporte un site principal multi-nœuds, un site secondaire multi-nœuds et un site secondaire à nœud unique :

Site principal (multi-nœuds) :

- Nœud d'application
- Nœud de base de données
- Nœud Gitaly

Site secondaire 1 (multi-nœuds) :

- Nœud d'application
- Nœud de base de données

Site secondaire 2 (nœud unique) :

- Nœud GitLab unique
