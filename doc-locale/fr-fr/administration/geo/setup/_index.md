---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer Geo
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

## Prérequis {#prerequisites}

- Deux sites GitLab (ou plus) fonctionnant de manière indépendante :
  - Un site GitLab sert de site Geo **principal**. Utilisez la [documentation sur les architectures de référence GitLab](../../reference_architectures/_index.md) pour effectuer cette configuration. Vous pouvez utiliser différentes tailles d'architecture de référence pour chaque site Geo. Si vous disposez déjà d'une instance GitLab fonctionnelle en cours d'utilisation, elle peut servir de site **principal**.
  - Le second site GitLab sert de site Geo **secondaire**. Utilisez la [documentation sur les architectures de référence GitLab](../../reference_architectures/_index.md) pour effectuer cette configuration. Il est recommandé de vous connecter et de le tester. Sachez toutefois que **all of the data on the secondary are lost** dans le cadre du processus de réplication depuis le site **principal**.

    > [!note]
    > Geo prend en charge plusieurs sites secondaires. Vous pouvez suivre les mêmes étapes et apporter les modifications nécessaires.

- Accès administrateur pour les deux sites. De nombreuses tâches de configuration nécessitent un accès root aux sites et un accès à la zone **Admin** dans l'interface utilisateur GitLab.
- Assurez-vous que le site **principal** dispose d'un abonnement [GitLab Premium ou Ultimate](https://about.gitlab.com/pricing/) pour déverrouiller Geo. Une seule licence suffit pour tous les sites.
- Confirmez que les [exigences pour l'exécution de Geo](../_index.md#requirements-for-running-geo) sont satisfaites par tous les sites. Par exemple, les sites doivent utiliser la même version de GitLab et doivent pouvoir communiquer entre eux via certains ports.
- Vérifiez que les configurations de stockage des sites **principal** et **secondaire** correspondent. Si le site Geo principal utilise le stockage objet, le site Geo secondaire doit également l'utiliser. Pour plus d'informations, consultez [Geo avec le stockage objet](../replication/object_storage.md).
- Assurez-vous que les horloges sont synchronisées entre le site **principal** et le site **secondaire**. La synchronisation des horloges est nécessaire au bon fonctionnement de Geo. Par exemple, si la dérive d'horloge entre les sites **principal** et **secondaire** dépasse 1 minute, la réplication échoue.

## Utilisation des installations de packages Linux {#using-linux-package-installations}

Si vous avez installé GitLab à l'aide du package Linux (vivement recommandé), le processus de configuration de Geo dépend de si vous devez configurer un site Geo à nœud unique ou un site Geo multi-nœuds.

### Sites Geo à nœud unique {#single-node-geo-sites}

Si les deux sites Geo sont basés sur l'[architecture de référence 1K](../../reference_architectures/1k_users.md), suivez [Configurer Geo pour deux sites à nœud unique](two_single_node_sites.md).

Si vous utilisez des services PostgreSQL externes, par exemple Amazon RDS, suivez [Configurer Geo pour deux sites à nœud unique (avec des services PostgreSQL externes)](two_single_node_external_services.md).

Selon votre déploiement GitLab, une [configuration supplémentaire](#additional-configuration) pour LDAP, le stockage objet et le registre de conteneurs peut être requise.

### Sites Geo multi-nœuds {#multi-node-geo-sites}

Si un ou plusieurs de vos sites utilisent l'[architecture de référence 40 RPS / 2 000 utilisateurs](../../reference_architectures/2k_users.md) ou une architecture plus grande, consultez [Configurer Geo pour plusieurs nœuds](../replication/multiple_servers.md).

Selon votre déploiement GitLab, une [configuration supplémentaire](#additional-configuration) pour LDAP, le stockage objet et le registre de conteneurs peut être requise.

### Étapes générales à titre de référence {#general-steps-for-reference}

1. Configurez la réplication de la base de données en fonction de votre choix d'instances PostgreSQL (topologie `primary (read-write) <-> secondary (read-only)`) :
   - [Utilisation des instances PostgreSQL du package Linux](database.md).
   - [Utilisation d'instances PostgreSQL externes](external_database.md)
1. [Configurez GitLab](../replication/configuration.md) pour définir les sites **principal** et **secondaire**.
1. Suivez le guide [Utilisation d'un site Geo](../replication/usage.md).

Selon votre déploiement GitLab, une [configuration supplémentaire](#additional-configuration) pour LDAP, le stockage objet et le registre de conteneurs peut être requise.

### Configuration supplémentaire {#additional-configuration}

Selon la façon dont vous utilisez GitLab, la configuration suivante peut être requise :

- Si le site **principal** utilise le stockage objet, [configurez la réplication du stockage objet](../replication/object_storage.md) pour les sites **secondaire**.
- Si vous utilisez LDAP, [configurez un serveur LDAP secondaire](../../auth/ldap/_index.md) pour les sites **secondaire**. Pour plus d'informations, consultez [LDAP avec Geo](../replication/single_sign_on.md#ldap).
- Si vous utilisez le registre de conteneurs, [configurez le registre de conteneurs pour la réplication](../replication/container_registry.md) sur les sites **principal** et **secondaire**.
- Pour accélérer la résolution des problèmes, [configurez la propagation des ID de corrélation](../replication/troubleshooting/common.md#tracing-requests-across-geo-sites).

Vous devriez [configurer des URL unifiées](../secondary_proxy/_index.md#set-up-a-unified-url-for-geo-sites) pour utiliser une URL unique et unifiée pour tous les sites Geo.

## Utilisation des Charts GitLab {#using-gitlab-charts}

[Configurez le chart GitLab avec GitLab Geo](https://docs.gitlab.com/charts/advanced/geo/).

## Geo et les installations compilées manuellement {#geo-and-self-compiled-installations}

Geo n'est pas pris en charge lorsque vous utilisez une [installation GitLab compilée manuellement](../../../install/self_compiled/_index.md).

## Documentation post-installation {#post-installation-documentation}

Après avoir installé GitLab sur les sites **secondaire** et effectué la configuration initiale, consultez la [documentation suivante pour les informations post-installation](../_index.md#post-installation-documentation).
