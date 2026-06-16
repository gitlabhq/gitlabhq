---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Découvrez l'architecture de GitLab Dedicated à travers une série de diagrammes."
title: Architecture de GitLab Dedicated
---

{{< details >}}

- Niveau : Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

Cette page fournit un ensemble de documents architecturaux et de diagrammes pour GitLab Dedicated.

## Vue d'ensemble de haut niveau {#high-level-overview}

Le diagramme suivant présente une vue d'ensemble de haut niveau de l'architecture de GitLab Dedicated, où divers comptes AWS gérés par GitLab et par les clients sont contrôlés par l'application Switchboard.

![Diagramme d'une vue d'ensemble de haut niveau de l'architecture de GitLab Dedicated.](img/high_level_architecture_diagram_v18_0.png)

Lors de la gestion des instances de locataires GitLab Dedicated :

- Switchboard est responsable de la gestion de la configuration globale partagée entre les fournisseurs cloud AWS, accessible par les locataires.
- Amp est responsable de l'interaction avec les comptes des locataires clients, notamment la configuration des rôles et des politiques attendus, l'activation des services requis et le provisionnement des environnements.

Les membres de l'équipe GitLab disposant d'un accès en modification peuvent mettre à jour les fichiers [source](https://lucid.app/lucidchart/e0b6661c-6c10-43d9-8afa-1fe0677e060c/edit?page=0_0#) du diagramme dans Lucidchart.

## Réseau du locataire {#tenant-network}

Le compte du locataire client est un compte unique de fournisseur cloud AWS. Le compte unique assure une isolation complète de la location, dans son propre VPC, et avec ses propres quotas de ressources.

Le compte du fournisseur cloud est l'endroit où réside une installation GitLab hautement résiliente, dans son propre VPC isolé. Lors du provisionnement, le locataire client obtient accès à un site principal GitLab en haute disponibilité (HA) et à un site secondaire GitLab Geo.

![Diagramme des comptes AWS gérés par GitLab dans un VPC isolé contenant une installation GitLab hautement résiliente.](img/tenant_network_diagram_v18_0.png)

Les membres de l'équipe GitLab disposant d'un accès en modification peuvent mettre à jour les fichiers [source](https://lucid.app/lucidchart/0815dd58-b926-454e-8354-c33fe3e7bff0/edit?invitationId=inv_a6b618ff-6c18-4571-806a-bfb3fe97cb12) du diagramme dans Lucidchart.

### Configuration de Gitaly {#gitaly-setup}

GitLab Dedicated déploie Gitaly [dans une configuration fragmentée (sharded)](../gitaly/praefect/_index.md#before-deploying-gitaly-cluster-praefect), et non dans une configuration Gitaly Cluster (Praefect).

- Les référentiels des clients sont répartis sur plusieurs machines virtuelles.
- GitLab gère les poids de stockage au nom du client.

### Configuration de Geo {#geo-setup}

GitLab Dedicated exploite Geo pour la [reprise après sinistre](disaster_recovery.md).

Geo n'utilise pas de configuration de basculement actif-actif. Pour plus d'informations, consultez [Geo](../geo/_index.md).

### Connexion AWS PrivateLink {#aws-privatelink-connection}

> [!note]
> Obligatoire pour les migrations Geo vers Dedicated. Sinon, facultatif.

En option, une connectivité privée est disponible pour votre instance GitLab Dedicated, en utilisant [AWS PrivateLink](https://aws.amazon.com/privatelink/) comme passerelle de connexion.

Les connexions PrivateLink [entrantes](configure_instance/network_security.md#inbound-privatelink-connections) et [sortantes](configure_instance/network_security.md#outbound-privatelink-connections) sont toutes deux prises en charge.

#### Entrante {#inbound}

![Diagramme d'un VPC AWS géré par GitLab utilisant AWS PrivateLink entrant pour se connecter à un VPC AWS géré par le client.](img/privatelink_inbound_v18_0.png)

Les membres de l'équipe GitLab disposant d'un accès en modification peuvent mettre à jour les fichiers [source](https://lucid.app/lucidchart/933b958b-bfad-4898-a8ae-182815f159ca/edit?invitationId=inv_38b9a265-dff2-4db6-abdb-369ea1e92f5f) du diagramme dans Lucidchart.

#### Sortante {#outbound}

![Diagramme d'un VPC AWS géré par GitLab utilisant AWS PrivateLink sortant pour se connecter à un VPC AWS géré par le client.](img/privatelink_outbound_v18_0.png)

Les membres de l'équipe GitLab disposant d'un accès en modification peuvent mettre à jour les fichiers [source](https://lucid.app/lucidchart/5aeae97e-a3c4-43e3-8b9d-27900d944147/edit?invitationId=inv_0e4fee9f-cf63-439c-9bf9-71ecbfbd8979&page=F5pcfQybsAYU8#) du diagramme dans Lucidchart.

#### AWS PrivateLink pour la migration {#aws-privatelink-for-migration}

De plus, AWS PrivateLink est également utilisé à des fins de migration. L'instance GitLab Dedicated du client peut utiliser AWS PrivateLink pour extraire des données en vue d'une migration vers GitLab Dedicated.

![Diagramme d'une configuration Geo Dedicated simplifiée.](img/dedicated_geo_simplified_v18_0.png)

Les membres de l'équipe GitLab disposant d'un accès en modification peuvent mettre à jour les fichiers [source](https://lucid.app/lucidchart/1e83e102-37b3-48a9-885d-e72122683bce/edit?view_items=AzvnMfovRJe3p&invitationId=inv_c02140dd-416b-41b5-b14a-7288b54bb9b5) du diagramme dans Lucidchart.

## Runners hébergés pour GitLab Dedicated {#hosted-runners-for-gitlab-dedicated}

Le diagramme suivant illustre un compte AWS géré par GitLab qui contient des runners GitLab, interconnectés à une instance GitLab Dedicated, à l'internet public et, en option, à un compte AWS client utilisant AWS PrivateLink.

![Diagramme de l'architecture des Runners hébergés pour GitLab Dedicated.](img/hosted-runners-architecture_v17_3.png)

Pour plus d'informations sur la façon dont les runners s'authentifient et exécutent la charge utile du job, consultez le [flux d'exécution du runner](https://docs.gitlab.com/runner/#runner-execution-flow).

Les membres de l'équipe GitLab disposant d'un accès en modification peuvent mettre à jour les fichiers [source](https://lucid.app/lucidchart/0fb12de8-5236-4d80-9a9c-61c08b714e6f/edit?invitationId=inv_4a12e347-49e8-438e-a28f-3930f936defd) du diagramme dans Lucidchart.
