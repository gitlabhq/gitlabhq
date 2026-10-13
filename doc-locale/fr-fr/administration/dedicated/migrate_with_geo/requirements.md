---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Prérequis et décisions à compléter avant le démarrage de la réplication Geo.
title: Conditions requises pour la migration Geo
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

Vous devez satisfaire les conditions suivantes avant que la réplication Geo de votre instance GitLab Self-Managed vers GitLab Dedicated puisse démarrer. Votre équipe de migration GitLab confirme chaque condition avec vous lors de la phase de découverte.

Chaque condition ci-dessous indique ce qui doit être vérifié et comment la satisfaire. Pour l'ordre dans lequel les compléter et leur place dans la migration, consultez [preparation](process.md#preparation). Certaines conditions prennent plusieurs semaines à satisfaire, alors commencez-y dès que possible.

## Décisions relatives à l'instance {#instance-decisions}

Vous prenez les décisions standard relatives à l'instance lorsque vous [créez votre instance GitLab Dedicated](../create_instance/_index.md), qui documente chaque champ et les valeurs qu'il accepte. Deux de ces décisions ont un poids particulier dans une migration Geo :

- Régions AWS. Si votre instance source s'exécute déjà dans AWS, placez la région principale dans la même région AWS que la source, ce qui simplifie la connectivité de migration.
- Méthode d'accès continu. Si vous utilisez AWS PrivateLink pour la connectivité, sélectionnez deux ID de zone de disponibilité correspondant à votre infrastructure AWS existante. Un VPN IPsec site à site n'est pas pris en charge pour l'accès continu, bien que vous puissiez en utiliser un pendant la fenêtre de migration. Pour plus d'informations, consultez [network security](../configure_instance/network_security.md).

> [!warning]
> Vous ne pouvez pas modifier les régions AWS, les ID de zone de disponibilité ni la configuration de clé de chiffrement gérée par le client après que GitLab a provisionné votre instance. Confirmez ces décisions avant le début du provisionnement.

## Stratégie de domaine {#domain-strategy}

Décidez si vous souhaitez utiliser un domaine personnalisé ou un domaine fourni par GitLab :

- Si vous utilisez un domaine personnalisé, vos utilisateurs continuent d'utiliser le même nom d'hôte après la migration. Les références existantes à ce nom d'hôte continuent de se résoudre, notamment les descriptions de tickets et de merge requests, les commentaires, la configuration des runners, les scripts et les remotes Git que vos utilisateurs ont configurés. Les endpoints disposant de leur propre nom d'hôte, tels que KAS et GitLab Pages, changent tout de même.
- Si vous utilisez un domaine fourni par GitLab, le nom d'hôte change et les références à l'ancien nom d'hôte ne se résolvent plus après le basculement. Prévoyez de les mettre à jour.
- Un domaine personnalisé exige que votre domaine soit résolvable publiquement afin que les certificats puissent être émis. Vous pouvez toujours restreindre l'accès à l'aide d'une liste d'adresses IP autorisées. Un enregistrement DNS public n'accorde pas lui-même l'accès.
- Si vous utilisez un domaine personnalisé pour l'instance GitLab, utilisez-le également pour le registre de conteneurs et le serveur d'agent GitLab pour Kubernetes (KAS), afin que les noms d'hôte restent cohérents.
- GitLab Pages ne prend pas en charge les domaines personnalisés. Le contenu de Pages est servi depuis le domaine GitLab Dedicated Pages.

Pour plus d'informations, consultez [custom domains](../configure_instance/network_security.md#custom-domains) et le kit de livraison [DNS requirements for custom domains](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#321-dns-requirements-around-byod).

## Conditions requises pour l'instance source {#source-instance-requirements}

Configurez votre instance en tant que site principal Geo avant que la réplication vers GitLab Dedicated ne commence. La vérification génère des sommes de contrôle pour vos données existantes, ce qui permet de détecter les problèmes de données tôt, alors démarrez-la dès que possible.

Pour plus d'informations, consultez [Geo](../../geo/_index.md) et le kit de livraison [Geo activation on the customer primary instance](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#41-geo-activation-on-customer-primary-instance).

## Réplicas en lecture de la base de données {#database-read-replicas}

GitLab Dedicated doit accéder à un réplica en lecture PostgreSQL de votre base de données source. Vous fournissez deux réplicas, un pour le chemin de production et un pour le chemin de pré-production, car Geo synchronise en parallèle vers un tenant de pré-production GitLab Dedicated et un tenant de production.

Chaque réplica doit être accessible depuis GitLab Dedicated via la connectivité de migration et doit streamer depuis une source saine.

La manière dont vous fournissez les réplicas dépend de l'endroit où s'exécute votre base de données source. Si votre source est dans AWS, le [module Terraform PrivateLink de migration](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-migration-privatelink) public crée les deux réplicas en lecture et y fournit l'accès via PrivateLink, ce qui en fait l'option la plus simple.

Pour plus d'informations, consultez le kit de livraison [outbound PrivateLinks to RDS read replica and GitLab](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#451-outbound-privatelinks-to-rds-read-replica-and-gitlab).

### Source déjà sur AWS RDS {#source-already-on-aws-rds}

Créez directement les deux réplicas en lecture RDS.

### Source s'exécutant dans AWS sans RDS {#source-running-in-aws-without-rds}

GitLab recommande de sauvegarder la base de données source et de la restaurer dans AWS RDS pour PostgreSQL avant la migration, puis de créer les deux réplicas en lecture à cet endroit. Les réplicas en lecture natifs RDS sont plus simples à créer et à gérer.

Le passage à RDS nécessite une fenêtre de maintenance planifiée avec une interruption de service pendant l'exécution du dump et de la restauration. Dimensionnez cette fenêtre en fonction du volume de votre base de données.

### Source sur un autre cloud ou hors AWS {#source-on-another-cloud-or-not-in-aws}

AWS RDS n'est pas obligatoire. Fournissez deux réplicas en lecture accessibles dans votre propre environnement, par exemple Google Cloud SQL ou Azure Database pour PostgreSQL.

## Stockage d'objets {#object-storage}

Tous les types de données utilisés doivent être sur le stockage d'objets avant le démarrage de la réplication Geo. GitLab Dedicated utilise le stockage d'objets, et un site secondaire Geo doit utiliser la même méthode de stockage que son site principal, de sorte que les fichiers laissés sur le stockage local ne peuvent pas migrer. Pour plus d'informations, consultez [object storage with Geo](../../geo/replication/object_storage.md).

La migration vers le stockage d'objets ne nécessite pas d'interruption de service pour la plupart des types de données.

Pour la procédure de migration de chaque type de données, consultez [migrate to object storage](../../object_storage.md#migrate-to-object-storage). Pour le séquençage de la migration, consultez le kit de livraison [object storage migration](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#48-object-storage-migration).

### Accès privé au stockage d'objets {#private-access-to-object-storage}

Si votre stockage d'objets utilise le téléchargement par proxy, vous pouvez utiliser les [outils d'accès privé au stockage d'objets](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/object-storage-private-access) publics pour configurer un endpoint d'interface Amazon S3 privé.

## Stockage des dépôts {#repository-storage}

GitLab Dedicated prend en charge trois noms de stockage Gitaly : `default`, `storage2` et `storage3`. Si votre instance utilise un autre nom de stockage, déplacez vos dépôts vers un nom pris en charge avant le basculement.

Pour plus d'informations, consultez [repository storage](../create_instance/storage_types.md#repository-storage) et le kit de livraison [Gitaly repository storage changes](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#47-gitaly-repository-storage-changes).

## Connectivité de migration {#migration-connectivity}

Durant la migration, GitLab Dedicated doit accéder à votre instance GitLab source et aux deux réplicas en lecture de la base de données.

Si votre source est dans AWS, connectez-vous via AWS PrivateLink plutôt que par l'internet public, et placez votre région principale GitLab Dedicated dans la même région AWS que la source. Vous configurez le chemin PrivateLink dans votre propre compte AWS. Le chemin comprend un Network Load Balancer et un service d'endpoint VPC, à la fois pour le chemin de production et pour le chemin de pré-production. Le [module Terraform PrivateLink entrant](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-inbound-privatelink) public crée le PrivateLink entrant, et le module Terraform PrivateLink de migration prépare la connectivité de migration.

Si votre source n'est pas dans AWS, vous pouvez :

- Vous connecter à un compte AWS que vous possédez et utiliser AWS PrivateLink depuis celui-ci.
- Utiliser un [VPN IPsec site à site](#ipsec-site-to-site-vpn) pour la fenêtre de migration.
- Fournir un accès internet à votre instance source et aux réplicas en lecture.

Confirmez la conception avec votre équipe de migration.

Pour plus d'informations, consultez le kit de livraison [Geo sync connectivity](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#45-geo-sync-connectivity).

### VPN IPsec site à site {#ipsec-site-to-site-vpn}

Si PrivateLink n'est pas envisageable, GitLab peut configurer un VPN AWS site à site entre votre réseau et votre tenant GitLab Dedicated pour la durée de la migration. Le VPN n'est pas pris en charge pour l'accès continu après la fin de la migration.

Le VPN utilise le routage statique. Le routage dynamique BGP n'est pas pris en charge, vous devez donc savoir à l'avance quels sous-réseaux nécessitent un accès, et les fournir avec les adresses IP publiques de votre endpoint VPN. GitLab crée le côté AWS de la connexion, qui comprend deux tunnels IPsec pour la redondance, puis vous envoie la configuration à appliquer sur votre propre équipement VPN.

Pour vous préparer, rassemblez les éléments suivants :

- Les adresses IP publiques de votre endpoint VPN
- Les sous-réseaux nécessitant un accès à GitLab Dedicated
- La marque et le modèle de votre équipement VPN, afin que GitLab puisse en générer la configuration

GitLab n'applique pas de traduction d'adresse réseau (NAT) côté GitLab Dedicated. GitLab partage la plage d'adresses IP depuis laquelle GitLab Dedicated se connecte, et vous pouvez la traduire dans votre propre réseau si votre plan d'adressage le nécessite. La migration nécessitant des connexions dans un seul sens, de GitLab Dedicated vers votre instance et vos réplicas en lecture, vous ne traduisez que les adresses source entrantes.

Pour la procédure de configuration, consultez le kit de livraison [IPsec VPN access](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#452-ipsec-vpn-access).

## Connectivité sortante pour les intégrations {#outbound-connectivity-for-integrations}

Préparez vos cibles sortantes comme suit :

- Configurez les webhooks et les intégrations pour cibler des noms d'hôte, et non des adresses IP.
- Passez en revue votre liste de cibles sortantes avant de supposer que chaque adresse privée nécessite une connectivité. Les adresses de bouclage, les auto-références et les adresses internes aux clusters ne sont souvent pas de véritables endpoints externes.

GitLab Dedicated prend en charge au maximum 10 endpoints PrivateLink sortants. Si davantage de cibles privées nécessitent une accessibilité, consolidez plusieurs backends derrière une seule connexion avec le [module Terraform de proxy sortant](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-outbound-proxy) public, qui déploie un proxy NGINX hautement disponible derrière un Network Load Balancer et peut consolider des backends HTTPS, HTTP et SMTP.

Pour inventorier vos cibles sortantes, utilisez le [kit de découverte GitLab](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/gitlab-discovery-toolkit) public.

Testez chaque cible sortante pendant la [période de test](process.md#testing-period). Les problèmes de connectivité sortante font partie des résultats les plus fréquents, et la période de test est le moment de les mettre en évidence.

Pour plus d'informations, consultez [outbound PrivateLink connections](../configure_instance/network_security.md#outbound-privatelink-connections) et le kit de livraison [webhooks and integrations](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#316-webhooks-and-integrations).

## Accès entrant pour les intégrations SaaS {#inbound-access-for-saas-integrations}

Si vous utilisez une liste d'adresses IP autorisées, ajoutez des exceptions pour tout service SaaS externe devant accéder à votre instance GitLab Dedicated, par exemple un système de ticketing, une intégration de messagerie instantanée ou un service CI/CD appelant l'API GitLab.

Inventoriez ces services avant le basculement. Les requêtes provenant d'un service ne figurant pas sur la liste d'adresses autorisées sont bloquées.

Pour plus d'informations, consultez [IP allowlist](../configure_instance/network_security.md#ip-allowlist).

## Fonctionnalités à corriger {#features-to-remediate}

Vérifiez votre instance par rapport à la liste des [fonctionnalités non disponibles](../../../subscriptions/gitlab_dedicated/_index.md#unavailable-features) et mettez en place un remplacement pour tout ce que vous utilisez avant le basculement. Pour obtenir des conseils sur la façon de parcourir la liste, consultez le kit de livraison [remaining unsupported features](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#3111-remaining-unsupported-features).

Deux éléments nécessitent plus de temps de planification que les autres, et GitLab fournit des outils ou une procédure pour chacun :

- Le passage de LDAP à un fournisseur d'identité SAML ou OpenID Connect (OIDC), qui constitue souvent l'élément de préparation le plus long. Pour plus d'informations, consultez [move from LDAP to SAML](#move-from-ldap-to-saml).
- Les domaines personnalisés GitLab Pages, que GitLab Dedicated ne prend pas en charge. Le contenu de Pages est servi depuis le domaine GitLab Dedicated Pages. Pour une transition temporaire, vous pouvez utiliser le [module Terraform de redirection Pages](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-gitlab-pages-redirect) public, qui conserve votre certificat et votre nom DNS existants et renvoie une redirection vers la nouvelle URL. Le module est une aide temporaire, pas une solution permanente.

Vous devez réenregistrer vos agents GitLab pour Kubernetes auprès de la nouvelle URL KAS, car le chemin par défaut `/-/kubernetes-agent` n'existe pas sur GitLab Dedicated.

### Migrer de LDAP vers SAML {#move-from-ldap-to-saml}

Le passage de LDAP est souvent l'élément de préparation le plus long, alors commencez-y tôt.

Pour configurer votre fournisseur d'identité sur GitLab Dedicated, consultez [SAML](../configure_instance/authentication/saml.md) ou [OpenID Connect](../configure_instance/authentication/openid_connect.md).

Si vous utilisez la synchronisation des groupes LDAP, vous pouvez conserver l'appartenance aux groupes en passant à la [synchronisation des groupes SAML](../../../user/group/saml_sso/group_sync.md). Pour la procédure de conversion et les scripts utilisés par GitLab Professional Services, consultez le kit de livraison [SSO configuration](https://gitlab.com/gitlab-org/professional-services-automation/delivery-kits/migration-delivery-kits/migration-delivery-kit/-/blob/main/Geo/dedicated.md#44-sso-configuration).

## Sujets connexes {#related-topics}

- [Migration Geo vers GitLab Dedicated](_index.md)
- [Collecter les secrets de migration Geo](secrets.md)
- [Processus de migration Geo](process.md)
- [Activités post-migration](post_cutover.md)
