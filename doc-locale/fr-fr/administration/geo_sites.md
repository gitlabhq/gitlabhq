---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: "Zone d'administration des sites Geo"
description: Configurer les sites Geo.
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Vous pouvez configurer différents paramètres pour les sites GitLab Geo. Pour plus d'informations, consultez la [documentation Geo](geo/_index.md).

Prérequis :

- Accès administrateur.

Sur le site principal ou secondaire :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites**.

## Paramètres communs {#common-settings}

Tous les sites Geo disposent des paramètres suivants :

| Paramètre | Description |
| --------| ----------- |
| Principal | Ceci marque un site Geo comme site **principal**. Il ne peut y avoir qu'un seul site **principal**. |
| Nom    | L'identifiant unique du site Geo. Il est fortement recommandé d'utiliser un emplacement physique comme nom. De bons exemples sont `London Office` ou `us-east-1`. Évitez les mots comme `primary`, `secondary`, `Geo` ou `DR`. Cela facilite le processus de basculement, car l'emplacement physique ne change pas, mais le rôle du site Geo peut changer. Tous les nœuds d'un même site Geo utilisent le même nom de site. Les nœuds utilisent le paramètre `gitlab_rails['geo_node_name']` dans `/etc/gitlab/gitlab.rb` pour rechercher leur enregistrement de site Geo dans la base de données PostgreSQL. Si `gitlab_rails['geo_node_name']` n'est pas défini, l'`external_url` du nœud avec barre oblique finale est utilisé comme solution de repli. La valeur de `Name` est sensible à la casse et la plupart des caractères sont autorisés. |
| URL     | L'URL exposée aux utilisateurs de l'instance. |

### IP Geo autorisée {#allowed-geo-ip}

Le paramètre **IP Geo autorisée** contrôle les adresses IP autorisées à effectuer des requêtes vers le site principal depuis les sites secondaires. Le site principal utilise ce paramètre pour valider :

- Les requêtes Git HTTP provenant des sites secondaires.
- Les requêtes API Geo provenant des sites secondaires.

Le paramètre **IP Geo autorisée** :

- N'a aucun effet sur les sites secondaires. Le paramètre est répliqué vers les sites secondaires dans la base de données, mais n'y est pas utilisé.
- Accepte une liste d'adresses IP et de blocs CIDR séparés par des virgules, comme `192.168.1.1, 10.0.0.0/8, 2001:db8::/32`.
- A une valeur par défaut de `0.0.0.0/0, ::/0`, ce qui autorise les requêtes depuis n'importe quelle adresse IP.
- Ne peut pas être modifié sur les sites secondaires, car leurs bases de données sont en lecture seule.

## Paramètres du site secondaire {#secondary-site-settings}

Les sites **Secondaire** disposent d'un certain nombre de paramètres supplémentaires :

| Paramètre                   | Description |
|---------------------------|-------------|
| Synchronisation sélective | Activer la [synchronisation sélective](geo/replication/selective_synchronization.md) Geo pour ce site **secondaire**. |
| Capacité de synchronisation des dépôts  | Nombre de requêtes simultanées que ce site **secondaire** envoie au site **principal** lors du remplissage des dépôts. |
| Capacité de synchronisation des fichiers        | Nombre de requêtes simultanées que ce site **secondaire** envoie au site **principal** lors du remplissage des fichiers. |

## Remplissage Geo {#geo-backfill}

Les sites **Secondaire** sont informés des modifications apportées aux dépôts et aux fichiers par le site **principal**, et tentent toujours de synchroniser ces modifications aussi rapidement que possible.

Le remplissage consiste à alimenter le site **secondaire** avec les dépôts et fichiers qui existaient avant l'ajout du site **secondaire** à la base de données. Étant donné que le nombre de dépôts et de fichiers peut être extrêmement élevé, il n'est pas réalisable de tenter de tous les télécharger en même temps ; par conséquent, GitLab impose une limite supérieure à la concurrence de ces opérations.

La durée du remplissage dépend de la concurrence maximale, mais des valeurs plus élevées exercent une pression plus importante sur le site **principal**. Les limites sont configurables. Si votre site **principal** dispose d'une capacité excédentaire importante, vous pouvez augmenter les valeurs pour achever le remplissage en moins de temps. Si le site est soumis à une charge importante et que le remplissage réduit sa disponibilité pour les requêtes standard, vous pouvez les diminuer.

## Configurer les URL internes {#set-up-the-internal-urls}

Vous pouvez configurer une URL différente pour la synchronisation entre le site principal et le site secondaire.

L'URL interne du site **principal** est utilisée par les sites **secondaire** pour le contacter. Par exemple, pour synchroniser des dépôts. Le nom URL interne la distingue de l'[URL externe](https://docs.gitlab.com/omnibus/settings/configuration/#configure-the-external-url-for-gitlab), qui est utilisée par les utilisateurs. L'URL interne n'a pas besoin d'être une adresse privée.

L'URL interne d'un site **secondaire** est utilisée par le site **principal** pour le contacter. Par exemple, pour récupérer les métadonnées de suivi de synchronisation ou de vérification à afficher dans la zone d'administration sous **Geo** > **Sites** > **Dépôts de projet**.

L'URL interne correspond par défaut à l'URL externe. Pour la modifier :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites**.
1. Sélectionnez **Éditer** sur le site que vous souhaitez personnaliser.
1. Modifiez l'URL interne.
1. Sélectionnez **Sauvegarder les modifications**.

Lorsqu'elle est activée, la zone **Admin** pour Geo affiche les détails de réplication pour chaque site directement depuis l'interface utilisateur du site principal, et via le proxy secondaire Geo, si activé.

> [!warning]
> Nous recommandons d'utiliser une connexion HTTPS lors de la configuration des sites Geo. Pour éviter d'interrompre la communication entre les sites **principal** et **secondaire** lors de l'utilisation de HTTPS, personnalisez votre URL interne pour qu'elle pointe vers un équilibreur de charge avec TLS terminé au niveau de l'équilibreur de charge.
