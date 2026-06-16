---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: Types de données Geo pris en charge
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Un type de données Geo est une classe spécifique de données requise par une ou plusieurs fonctionnalités GitLab pour stocker des informations pertinentes.

Pour répliquer les données produites par ces fonctionnalités avec Geo, nous utilisons plusieurs stratégies pour y accéder, les transférer et les vérifier.

## Types de données {#data-types}

Nous distinguons les différents types de données suivants :

- [Dépôts Git](#git-repositories)
- [Dépôts de conteneurs](#container-repositories)
- [Blobs](#blobs)
- [Bases de données](#databases)

Consultez la liste ci-dessous de chaque fonctionnalité ou composant que nous répliquons, son type de données correspondant, ainsi que les méthodes de réplication et de vérification :

| Type                 | Fonctionnalité / composant                             | Méthode de réplication                           | Méthode de vérification           |
|:---------------------|:------------------------------------------------|:---------------------------------------------|:------------------------------|
| Base de données             | Données d'application dans PostgreSQL                  | Natif                                       | Natif                        |
| Base de données             | Redis                                           | Non applicable <sup>1</sup>                  | Non applicable                |
| Base de données             | Recherche avancée (Elasticsearch ou OpenSearch)   | Natif                                       | Natif                        |
| Base de données             | Recherche de code exacte (Zoekt)                       | Natif                                       | Natif                        |
| Base de données             | Clés publiques SSH                                 | Réplication PostgreSQL                       | Réplication PostgreSQL        |
| Git                  | Dépôt de projet                              | Geo avec Gitaly                              | Checksum Gitaly               |
| Git                  | Dépôt wiki du projet                         | Geo avec Gitaly                              | Checksum Gitaly               |
| Git                  | Dépôt de designs du projet                      | Geo avec Gitaly                              | Checksum Gitaly               |
| Git                  | Snippets du projet                                | Geo avec Gitaly                              | Checksum Gitaly               |
| Git                  | Snippets personnels                               | Geo avec Gitaly                              | Checksum Gitaly               |
| Git                  | Dépôt wiki du groupe                           | Geo avec Gitaly                              | Checksum Gitaly               |
| Blob                 | Téléversements utilisateur _(système de fichiers)_                    | Geo avec API                                 | Checksum SHA256               |
| Blob                 | Téléversements utilisateur _(stockage d'objets)_                 | Geo avec API/Managed <sup>2</sup>            | Checksum SHA256 <sup>3</sup>  |
| Blob                 | Objets LFS _(système de fichiers)_                     | Geo avec API                                 | Checksum SHA256               |
| Blob                 | Objets LFS _(stockage d'objets)_                  | Geo avec API/Managed <sup>2</sup>            | Checksum SHA256 <sup>3</sup>  |
| Blob                 | Artefacts de job CI _(système de fichiers)_                | Geo avec API                                 | Checksum SHA256               |
| Blob                 | Artefacts de job CI _(stockage d'objets)_             | Geo avec API/Managed <sup>2</sup>            | Checksum SHA256 <sup>3</sup>  |
| Blob                 | Traces de build CI archivées _(système de fichiers)_        | Geo avec API                                 | Non implémenté             |
| Blob                 | Traces de build CI archivées _(stockage d'objets)_     | Geo avec API/Managed <sup>2</sup>            | Checksum SHA256 <sup>3</sup>  |
| Blob                 | Registre de conteneurs _(système de fichiers)_              | Geo avec API/Docker API                      | Checksum SHA256               |
| Blob                 | Registre de conteneurs _(stockage d'objets)_           | Geo avec API/Managed/Docker API <sup>2</sup> | Checksum SHA256 <sup>3</sup>  |
| Blob                 | Registre de paquets _(système de fichiers)_                | Geo avec API                                 | Checksum SHA256               |
| Blob                 | Registre de paquets _(stockage d'objets)_             | Geo avec API/Managed <sup>2</sup>            | Checksum SHA256 <sup>3</sup>  |
| Blob                 | Cache de métadonnées Helm des paquets _(système de fichiers)_    | Geo avec API                                 | Checksum SHA256               |
| Blob                 | Cache de métadonnées Helm des paquets _(stockage d'objets)_ | Geo avec API/Managed <sup>2</sup>            | Checksum SHA256 <sup>3</sup>  |
| Blob                 | Registre de modules Terraform _(système de fichiers)_       | Geo avec API                                 | Checksum SHA256               |
| Blob                 | Registre de modules Terraform _(stockage d'objets)_    | Geo avec API/Managed <sup>2</sup>            | Checksum SHA256 <sup>3</sup>  |
| Blob                 | État Terraform versionné _(système de fichiers)_       | Geo avec API                                 | Checksum SHA256               |
| Blob                 | État Terraform versionné _(stockage d'objets)_    | Geo avec API/Managed <sup>2</sup>            | Checksum SHA256 <sup>3</sup>  |
| Blob                 | Diffs de merge request externes _(système de fichiers)_    | Geo avec API                                 | Checksum SHA256               |
| Blob                 | Diffs de merge request externes _(stockage d'objets)_ | Geo avec API/Managed <sup>2</sup>            | Checksum SHA256 <sup>3</sup>  |
| Blob                 | Artefacts de pipeline _(système de fichiers)_              | Geo avec API                                 | Checksum SHA256               |
| Blob                 | Artefacts de pipeline _(stockage d'objets)_           | Geo avec API/Managed <sup>2</sup>            | Checksum SHA256 <sup>3</sup>  |
| Blob                 | Pages _(système de fichiers)_                           | Geo avec API                                 | Checksum SHA256               |
| Blob                 | Pages _(stockage d'objets)_                        | Geo avec API/Managed <sup>2</sup>            | Checksum SHA256 <sup>3</sup>  |
| Blob                 | Fichiers sécurisés CI _(système de fichiers)_                 | Geo avec API                                 | Checksum SHA256               |
| Blob                 | Fichiers sécurisés CI _(stockage d'objets)_              | Geo avec API/Managed <sup>2</sup>            | Checksum SHA256 <sup>3</sup>  |
| Blob                 | Images de métriques d'incidents _(système de fichiers)_          | Geo avec API/Managed                         | Checksum SHA256               |
| Blob                 | Images de métriques d'incidents _(stockage d'objets)_       | Geo avec API/Managed <sup>2</sup>            | Checksum SHA256 <sup>3</sup>  |
| Blob                 | Images de métriques d'alertes _(système de fichiers)_             | Geo avec API                                 | Checksum SHA256               |
| Blob                 | Images de métriques d'alertes _(stockage d'objets)_          | Geo avec API/Managed <sup>2</sup>            | Checksum SHA256 <sup>3</sup>  |
| Blob                 | Images du proxy de dépendances _(système de fichiers)_         | Geo avec API                                 | Checksum SHA256               |
| Blob                 | Images du proxy de dépendances _(stockage d'objets)_      | Geo avec API/managed <sup>2</sup>            | Checksum SHA256 <sup>3</sup>  |
| Blob                 | Symboles NuGet des paquets _(système de fichiers)_      |  Geo avec API                                   | Checksum SHA256 |
| Blob                 | Symboles NuGet des paquets _(stockage d'objets)_              |  Geo avec API/Docker API                           | Checksum SHA256 <sup>3</sup> |
| Dépôt de conteneurs | Registre de conteneurs _(système de fichiers)_              | Geo avec API/Docker API                      | Checksum SHA256               |
| Dépôt de conteneurs | Registre de conteneurs _(stockage d'objets)_           | Geo avec API/Managed/Docker API <sup>2</sup> | Checksum SHA256 <sup>3</sup>  |

**Footnotes** :

1. La réplication Redis peut être utilisée dans le cadre de la haute disponibilité avec Redis Sentinel. Elle n'est pas utilisée entre les sites Geo.
1. La réplication du stockage d'objets peut être effectuée par Geo ou par la fonctionnalité de réplication native de votre fournisseur/appliance de stockage d'objets.
1. La vérification du stockage d'objets est soumise à un [feature flag](../../feature_flags/_index.md), `geo_object_storage_verification`, [introduit dans la version 16.4](https://gitlab.com/groups/gitlab-org/-/epics/8056) et activé par défaut. Il utilise un checksum de la taille du fichier pour vérifier les fichiers.

### Dépôts Git {#git-repositories}

Une instance GitLab peut avoir un ou plusieurs fragments de dépôt (shards). Chaque fragment possède une instance Gitaly chargée d'autoriser l'accès et les opérations sur les dépôts Git stockés localement. Elle peut fonctionner sur une machine :

- Avec un seul disque.
- Avec plusieurs disques montés comme un seul point de montage (comme avec une baie RAID).
- Avec LVM.

GitLab ne requiert pas de système de fichiers particulier et peut fonctionner avec une appliance de stockage montée. Cependant, des limitations de performances et des problèmes de cohérence peuvent survenir lors de l'utilisation d'un système de fichiers distant.

Geo déclenche la collecte des déchets dans Gitaly pour dédupliquer les dépôts dupliqués sur les sites secondaires Geo.

L'API gRPC de Gitaly gère la communication, avec trois façons possibles de synchronisation :

- En utilisant le clone/fetch Git classique d'un site Geo à un autre (avec une authentification spéciale).
- En utilisant des instantanés de dépôt (pour les cas où la première méthode échoue ou où le dépôt est corrompu).
- Déclenchement manuel depuis la zone **Admin** (combine les autres façons possibles répertoriées).

Chaque projet peut avoir au maximum 3 dépôts différents :

- Un dépôt de projet, où le code source est stocké.
- Un dépôt wiki, où le contenu du wiki est stocké.
- Un dépôt de designs, où les artefacts de design sont indexés (les ressources sont en réalité dans LFS).

Ils résident tous dans le même fragment et partagent le même nom de base avec le suffixe `-wiki` et `-design` pour les cas du wiki et du dépôt de designs.

En outre, il existe des dépôts de snippets. Ils peuvent être connectés à un projet ou à un utilisateur spécifique. Les deux types sont synchronisés avec un site secondaire.

### Dépôts de conteneurs {#container-repositories}

Les dépôts de conteneurs sont stockés dans le registre de conteneurs. Il s'agit d'un concept propre à GitLab, construit sur un registre de conteneurs utilisé comme magasin de données.

### Blobs {#blobs}

GitLab stocke les fichiers et les blobs, tels que les pièces jointes de tickets ou les objets LFS, dans :

- Le système de fichiers à un emplacement spécifique.
- Une solution de [stockage d'objets](../../object_storage.md). Les solutions de stockage d'objets peuvent être :
  - Basées sur le cloud, comme Amazon S3 et Google Cloud Storage.
  - Un stockage d'objets auto-hébergé compatible S3.
  - Une appliance de stockage exposant une API compatible avec le stockage d'objets.

Lorsque vous utilisez le stockage par système de fichiers plutôt que le stockage d'objets, utilisez des systèmes de fichiers montés sur le réseau pour exécuter GitLab avec plusieurs nœuds.

En ce qui concerne la réplication et la vérification :

- Nous transférons les fichiers et les blobs via une requête API interne.
- Avec le stockage d'objets, vous pouvez :
  - Utiliser la fonctionnalité de réplication d'un fournisseur cloud.
  - Laisser GitLab effectuer la réplication pour vous.

### Bases de données {#databases}

GitLab s'appuie sur des données stockées dans plusieurs bases de données, pour différents cas d'utilisation. PostgreSQL est la source de vérité unique pour le contenu généré par les utilisateurs dans l'interface Web, comme le contenu des tickets, les commentaires, ainsi que les permissions et les identifiants.

PostgreSQL peut également contenir un certain niveau de données en cache, comme le Markdown rendu en HTML et les diffs de merge requests en cache. Ceci peut également être configuré pour être déchargé vers le stockage d'objets.

Nous utilisons la fonctionnalité de réplication propre à PostgreSQL pour répliquer les données du site **principal** vers les sites **secondaire**.

Nous utilisons Redis à la fois comme cache et pour conserver les données persistantes de notre système de jobs en arrière-plan. Étant donné que les deux cas d'utilisation ont des données exclusives au même site Geo, nous ne les répliquons pas entre les sites.

Elasticsearch est une base de données optionnelle pour la recherche avancée. Il peut améliorer la recherche au niveau du code source et dans le contenu généré par les utilisateurs dans les tickets, les merge requests et les discussions. Elasticsearch n'est pas pris en charge dans Geo.

## Types de données répliquées {#replicated-data-types}

### Types de données répliquées soumis à un feature flag {#replicated-data-types-behind-a-feature-flag}

{{< history >}}

- Ils sont déployés derrière un feature flag, activé par défaut.
- Ils sont activés sur GitLab.com.
- Ils ne peuvent pas être activés ou désactivés par projet.
- Ils sont recommandés pour une utilisation en production.
- Pour une instance GitLab Self-Managed, les administrateurs GitLab peuvent choisir de [les désactiver](#enable-or-disable-replication-for-some-data-types).

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

#### Activer ou désactiver la réplication (pour certains types de données) {#enable-or-disable-replication-for-some-data-types}

La réplication de certains types de données est publiée derrière des feature flags qui sont **enabled by default**. [Les administrateurs GitLab ayant accès à la console Rails de GitLab](../../feature_flags/_index.md) peuvent choisir de la désactiver pour votre instance. Vous pouvez trouver les noms des feature flags de chacun de ces types de données dans la colonne des notes du tableau ci-dessous.

Pour désactiver, par exemple pour la réplication des fichiers de paquets :

```ruby
Feature.disable(:geo_package_file_replication)
```

Pour activer, par exemple pour la réplication des fichiers de paquets :

```ruby
Feature.enable(:geo_package_file_replication)
```

> [!warning]
> Les fonctionnalités absentes de cette liste, ou avec **Non** dans la colonne **Replicated**, ne sont pas répliquées sur un site **secondaire**. Un basculement sans réplication manuelle des données de ces fonctionnalités entraîne la **lost** des données. Pour utiliser ces fonctionnalités sur un site **secondaire**, ou pour effectuer un basculement avec succès, vous devez répliquer leurs données par d'autres moyens.

| Fonctionnalité                                                                                                               | Répliqué (ajouté dans la version GitLab)                                          | Vérifié (ajouté dans la version GitLab)                                            | Réplication du stockage d'objets géré par GitLab (ajoutée dans la version GitLab)             | Vérification du stockage d'objets géré par GitLab (ajoutée dans la version GitLab)            | Notes |
|:----------------------------------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------|:------------------------------------------------------------------------------|:--------------------------------------------------------------------------------|:--------------------------------------------------------------------------------|:------|
| [Données d'application dans PostgreSQL](../../postgresql/_index.md)                                                           | **Oui** (10.2)                                                                | **Oui** (10.2)                                                                | Non applicable                                                                  | Non applicable                                                                  |       |
| [Dépôt de projet](../../../user/project/repository/_index.md)                                                       | **Oui** (10.2)                                                                | **Oui** (10.7)                                                                | Non applicable                                                                  | Non applicable                                                                  | Migré vers le framework en libre-service dans la version 16.2. Consultez le ticket GitLab [\#367925](https://gitlab.com/gitlab-org/gitlab/-/issues/367925) pour plus de détails.<br /><br />Soumis au feature flag `geo_project_repository_replication`, activé par défaut dans la version (16.3).<br /><br /> Tous les projets, y compris les [projets archivés](../../../user/project/working_with_projects.md#archive-a-project), sont répliqués. |
| [Dépôt wiki du projet](../../../user/project/wiki/_index.md)                                                        | **Oui** (10.2)<sup>2</sup>                                                    | **Oui** (10.7)<sup>2</sup>                                                    | Non applicable                                                                  | Non applicable                                                                  | Migré vers le framework en libre-service dans la version 15.11. Consultez le ticket GitLab [\#367925](https://gitlab.com/gitlab-org/gitlab/-/issues/367925) pour plus de détails.<br /><br />Soumis au feature flag `geo_project_wiki_repository_replication`, activé par défaut dans la version (15.11). |
| [Dépôt wiki du groupe](../../../user/project/wiki/group.md)                                                          | [**Oui** (13.10)](https://gitlab.com/gitlab-org/gitlab/-/issues/208147)       | [**Oui** (16.3)](https://gitlab.com/gitlab-org/gitlab/-/issues/323897)        | Non applicable                                                                  | Non applicable                                                                  | Soumis au feature flag `geo_group_wiki_repository_replication`, activé par défaut. |
| [Téléversements utilisateur](../../uploads.md)                                                                                           | **Oui** (10.2)                                                                | **Oui** (14.6)                                                                | [**Oui** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**Oui** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | La réplication est soumise au feature flag `geo_upload_replication`, activé par défaut. La vérification était soumise au feature flag `geo_upload_verification`, supprimé dans la version 14.8. |
| [Objets LFS](../../lfs/_index.md)                                                                                     | **Oui** (10.2)                                                                | **Oui** (14.6)                                                                | [**Oui** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**Oui** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | Les versions GitLab 11.11.x et 12.0.x sont affectées par [un bug empêchant la réplication de tout nouvel objet LFS](https://gitlab.com/gitlab-org/gitlab/-/issues/32696).<br /><br />La réplication est soumise au feature flag `geo_lfs_object_replication`, activé par défaut. La vérification était soumise au feature flag `geo_lfs_object_verification`, supprimé dans la version 14.7. |
| [Snippets personnels](../../../user/snippets.md)                                                                        | **Oui** (10.2)                                                                | **Oui** (10.2)                                                                | Non applicable                                                                  | Non applicable                                                                  |       |
| [Snippets du projet](../../../user/snippets.md)                                                                         | **Oui** (10.2)                                                                | **Oui** (10.2)                                                                | Non applicable                                                                  | Non applicable                                                                  |       |
| [Artefacts de job CI](../../../ci/jobs/job_artifacts.md)                                                                 | **Oui** (10.4)                                                                | **Oui** (14.10)                                                               | [**Oui** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**Oui** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | La vérification est soumise au feature flag `geo_job_artifact_replication`, activé par défaut dans la version 14.10. |
| [Artefacts de pipeline](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/ci/pipeline_artifact.rb)        | [**Oui** (13.11)](https://gitlab.com/gitlab-org/gitlab/-/issues/238464)       | [**Oui** (13.11)](https://gitlab.com/gitlab-org/gitlab/-/issues/238464)       | [**Oui** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**Oui** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | Conserve des artefacts supplémentaires après la fin d'un pipeline. |
| [Fichiers sécurisés CI](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/ci/secure_file.rb)                    | [**Oui** (15.3)](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91430) | [**Oui** (15.3)](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91430) | [**Oui** (15.3)](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91430)   | [**Oui** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | La vérification est soumise au feature flag `geo_ci_secure_file_replication`, activé par défaut dans la version 15.3. |
| [Registre de conteneurs](../../packages/container_registry.md)                                                            | **Oui** (12.3)<sup>1</sup>                                                    | **Oui** (15.10)                                                               | **Oui** (12.3)<sup>1</sup>                                                      | **Oui** (15.10)                                                                 | Consultez les [instructions](container_registry.md) pour configurer la réplication du registre de conteneurs. |
| [Registre de modules Terraform](../../../user/packages/terraform_module_registry/_index.md)                                | **Oui** (14.0)                                                                | **Oui** (14.0)                                                                | [**Oui** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**Oui** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | Soumis au feature flag `geo_package_file_replication`, activé par défaut. |
| [Dépôt de designs du projet](../../../user/project/issues/design_management.md)                                       | **Oui** (12.7)                                                                | **Oui** (16.1)                                                                | [**Oui** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | [**Oui** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | Les designs requièrent également la réplication des objets LFS et des téléversements. |
| [Registre de paquets](../../../user/packages/package_registry/_index.md)                                                  | **Oui** (13.2)                                                                | **Oui** (13.10)                                                               | [**Oui** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**Oui** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | Soumis au feature flag `geo_package_file_replication`, activé par défaut. |
| [Cache de métadonnées Helm des paquets](../../../user/packages/helm_repository/_index.md)                                      | [**Oui** (18.10)](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219409) | [**Oui** (18.10)](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219409) | [**Oui** (18.10)](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219409) | [**Oui** (18.10)](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219409) | Soumis au feature flag `geo_packages_helm_metadata_cache_replication`, activé par défaut dans la version 18.10. |
| [État Terraform versionné](../../terraform_state.md)                                                                 | **Oui** (13.5)                                                                | **Oui** (13.12)                                                               | [**Oui** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**Oui** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | La réplication est soumise au feature flag `geo_terraform_state_version_replication`, activé par défaut. La vérification était soumise au feature flag `geo_terraform_state_version_verification`, supprimé dans la version 14.0. |
| [Diffs de merge request externes](../../merge_request_diffs.md)                                                          | **Oui** (13.5)                                                                | **Oui** (14.6)                                                                | [**Oui** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**Oui** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | La réplication est soumise au feature flag `geo_merge_request_diff_replication`, activé par défaut. La vérification était soumise au feature flag `geo_merge_request_diff_verification`, supprimé dans la version 14.7. |
| [Snippets versionnés](../../../user/snippets.md#versioned-snippets)                                                    | [**Oui** (13.7)](https://gitlab.com/groups/gitlab-org/-/epics/2809)           | [**Oui** (14.2)](https://gitlab.com/groups/gitlab-org/-/epics/2810)           | [**Oui** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | [**Oui** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | La vérification a été implémentée derrière le feature flag `geo_snippet_repository_verification` dans la version 13.11, et le feature flag a été supprimé dans la version 14.2. |
| [Pages](../../pages/_index.md)                                                                                  | [**Oui** (14.3)](https://gitlab.com/groups/gitlab-org/-/epics/589)            | **Oui** (14.6)                                                                | [**Oui** (15.1)](https://gitlab.com/groups/gitlab-org/-/epics/5551)             | [**Oui** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | Soumis au feature flag `geo_pages_deployment_replication`, activé par défaut. La vérification était soumise au feature flag `geo_pages_deployment_verification`, supprimé dans la version 14.7. |
| [Fichiers sécurisés CI au niveau du projet](../../../ci/secure_files/_index.md)                                                       | **Oui** (15.3)                                                                | **Oui** (15.3)                                                                | **Oui** (15.3)                                                                  | [**Oui** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) |       |
| [Images de métriques d'incidents](../../../operations/incident_management/incidents.md#metrics)                                | **Oui** (15.5)                                                                | **Oui** (15.5)                                                                | **Oui** (15.5)                                                                  | [**Oui** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | La réplication/vérification est gérée via le type de données Uploads. |
| [Images de métriques d'alertes](../../../operations/incident_management/alerts.md#metrics-tab)                                  | **Oui** (15.5)                                                                | **Oui** (15.5)                                                                | **Oui** (15.5)                                                                  | [**Oui** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | La réplication/vérification est gérée via le type de données Uploads. |
| [Hooks Git côté serveur](../../server_hooks.md)                                                                        | [Non prévu](https://gitlab.com/groups/gitlab-org/-/epics/1867)              | Non                                                                            | Non applicable                                                                  | Non applicable                                                                  | Non prévu en raison de la complexité de l'implémentation actuelle, du faible intérêt des clients et de la disponibilité d'alternatives aux hooks. |
| [Elasticsearch](../../../integration/advanced_search/elasticsearch.md)                                    | [Non prévu](https://gitlab.com/gitlab-org/gitlab/-/issues/1186)             | Non                                                                            | Non                                                                              | Non                                                                              | Non prévu car une découverte produit supplémentaire est requise et les clusters Elasticsearch (ES) peuvent être reconstruits. Les sites secondaires utilisent le même cluster ES que le site principal. |
| [Images du proxy de dépendances](../../../user/packages/dependency_proxy/_index.md)                                           | [**Oui** (15.7)](https://gitlab.com/groups/gitlab-org/-/epics/8833)           | [**Oui** (15.7)](https://gitlab.com/groups/gitlab-org/-/epics/8833)           | [**Oui** (15.7)](https://gitlab.com/groups/gitlab-org/-/epics/8833)             | [**Oui** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) |       |
| [Symbole NuGet des paquets](../../../user/packages/nuget_repository/_index.md#symbol-packages)                                                                                                 | [**Oui** (18.10)](https://gitlab.com/gitlab-org/gitlab/-/issues/422929)           | [**Oui** (18.10)](https://gitlab.com/gitlab-org/gitlab/-/issues/422929)           | [**Oui** (15.7)](https://gitlab.com/groups/gitlab-org/-/epics/8833)             | [**Oui** (16.4)<sup>3</sup>](https://gitlab.com/groups/gitlab-org/-/epics/8056) | Soumis au feature flag `geo_packages_nuget_symbol_replication`, activé par défaut.   |
| [Export de vulnérabilité](../../../user/application_security/vulnerability_report/_index.md#exporting) | [Non prévu](https://gitlab.com/groups/gitlab-org/-/epics/3111)              | Non                                                                            | Non                                                                              | Non                                                                              | Non prévu car il s'agit d'informations éphémères et sensibles. Elles peuvent être régénérées à la demande. |
| Cache de métadonnées NPM des paquets                                                                                           | [Non prévu](https://gitlab.com/gitlab-org/gitlab/-/issues/408278)           | Non                                                                            | Non                                                                              | Non                                                                              | Non prévu car cela n'améliorerait pas notablement les capacités de reprise après sinistre ni les temps de réponse sur les sites secondaires. |
| Packages Debian GroupComponentFile                                                                                    | [Non prévu](https://gitlab.com/gitlab-org/gitlab/-/issues/556945)           | Non                                                                            | Non                                                                              | Non                                                                              |       |
| Packages Debian ProjectComponentFile                                                                                  | [**Oui** (19.1)](https://gitlab.com/gitlab-org/gitlab/-/issues/333611)       | [**Oui** (19.1)](https://gitlab.com/gitlab-org/gitlab/-/issues/333611)       | [**Oui** (19.1)](https://gitlab.com/gitlab-org/gitlab/-/issues/333611)         | [**Oui** (19.1)](https://gitlab.com/gitlab-org/gitlab/-/issues/333611)         | Soumis au feature flag `geo_packages_debian_project_component_file_replication`, désactivé par défaut. |
| Packages Debian GroupDistribution                                                                                     | [Non prévu](https://gitlab.com/gitlab-org/gitlab/-/issues/556947)           | Non                                                                            | Non                                                                              | Non                                                                              |       |
| Packages Debian ProjectDistribution                                                                                   | [Non prévu](https://gitlab.com/gitlab-org/gitlab/-/issues/556946)           | Non                                                                            | Non                                                                              | Non                                                                              |       |
| Packages RPM RepositoryFile                                                                                           | [Non prévu](https://gitlab.com/gitlab-org/gitlab/-/issues/379055)           | Non                                                                            | Non                                                                              | Non                                                                              |       |
| Entrée de cache Maven VirtualRegistries                                                                                   | [Non prévu](https://gitlab.com/gitlab-org/gitlab/-/issues/473033)           | Non                                                                            | Non                                                                              | Non                                                                              |       |
| Données de scan de vulnérabilité SBOM                                                                                           | [Non prévu](https://gitlab.com/gitlab-org/gitlab/-/issues/398199)           | Non                                                                            | Non                                                                              | Non                                                                              | Non prévu car les données sont temporaires et ont une courte durée de vie avec un impact limité sur les capacités de reprise après sinistre sur les sites secondaires. |

**Footnotes** :

1. Migré vers le framework en libre-service dans la version 15.5. Consultez le ticket GitLab [\#337436](https://gitlab.com/gitlab-org/gitlab/-/issues/337436) pour plus de détails.
1. Migré vers le framework en libre-service dans la version 15.11. Soumis au feature flag `geo_project_wiki_repository_replication`, activé par défaut. Consultez le ticket GitLab [\#367925](https://gitlab.com/gitlab-org/gitlab/-/issues/367925) pour plus de détails.
1. La vérification des fichiers stockés dans l'object storage a été [introduite](https://gitlab.com/groups/gitlab-org/-/epics/8056) dans GitLab 16.4 [avec un feature flag](../../feature_flags/_index.md) nommé `geo_object_storage_verification`, activé par défaut.
