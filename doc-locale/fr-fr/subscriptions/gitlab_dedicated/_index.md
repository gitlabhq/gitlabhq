---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Découvrez les fonctionnalités disponibles et les avantages d'une solution SaaS à locataire unique."
title: GitLab Dedicated
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

GitLab Dedicated est une solution SaaS à locataire unique qui est :

- Entièrement isolée.
- Déployée dans la région AWS de votre choix.
- Hébergée et maintenue par GitLab.

Chaque instance fournit :

- [Haute disponibilité](../../administration/dedicated/create_instance/data_residency_high_availability.md) avec reprise après sinistre.
- [Mises à jour régulières](../../administration/dedicated/maintenance.md) avec les dernières fonctionnalités.
- Mesures de sécurité de niveau professionnel.

Avec GitLab Dedicated, vous pouvez :

- Améliorer l'efficacité opérationnelle.
- Réduire la charge de gestion de l'infrastructure.
- Améliorer l'agilité organisationnelle.
- Répondre à des exigences de conformité strictes.

## URL par défaut {#default-urls}

GitLab Dedicated attribue à chaque locataire un ensemble d'URL par défaut en fonction du type d'environnement. Remplacez `tenant_name` par le nom de votre locataire.

| Composant                          | Production                              | Pré-production                                |
|------------------------------------|-----------------------------------------|-----------------------------------------------|
| Instance GitLab                    | `tenant_name.gitlab-dedicated.com`      | `tenant_name.gitlab-dedicated.systems`        |
| GitLab Pages                       | `tenant_name.gitlab-dedicated.site`     | `tenant_name.gitlab-dedicated-pages.systems`  |
| Switchboard (console de gestion)   | `console.gitlab-dedicated.com`          | `console.gitlab-dedicated.systems`            |

Vous pouvez remplacer l'URL par défaut de l'instance GitLab par un [domaine personnalisé](#custom-domains). Les domaines personnalisés ne sont pas pris en charge pour GitLab Pages, et les URL Switchboard ne peuvent pas être personnalisées.

## Fonctionnalités disponibles {#available-features}

Cette section répertorie les fonctionnalités clés disponibles pour GitLab Dedicated.

### Sécurité {#security}

GitLab Dedicated fournit les fonctionnalités de sécurité suivantes pour protéger vos données et contrôler l'accès à votre instance.

#### Authentification et autorisation {#authentication-and-authorization}

GitLab Dedicated prend en charge les fournisseurs [SAML](../../administration/dedicated/configure_instance/authentication/saml.md) et [OpenID Connect (OIDC)](../../administration/dedicated/configure_instance/authentication/openid_connect.md) pour l'authentification unique (SSO).

Vous pouvez configurer l'authentification unique (SSO) à l'aide des fournisseurs pris en charge pour l'authentification. Votre instance agit en tant que fournisseur de services, et vous fournissez la configuration nécessaire pour que GitLab communique avec vos fournisseurs d'identité (IdPs).

#### Réseau sécurisé {#secure-networking}

Deux options de connectivité sont disponibles :

- Connectivité publique avec listes d'autorisation d'IP : par défaut, votre instance est accessible publiquement. Vous pouvez [configurer une liste d'autorisation d'IP](../../administration/dedicated/configure_instance/network_security.md#ip-allowlist) pour restreindre l'accès à des adresses IP spécifiées.
- Connectivité privée avec AWS PrivateLink : vous pouvez configurer [AWS PrivateLink](https://aws.amazon.com/privatelink/) pour les connexions PrivateLink [entrantes](../../administration/dedicated/configure_instance/network_security.md#inbound-privatelink-connections) et [sortantes](../../administration/dedicated/configure_instance/network_security.md#outbound-privatelink-connections).

Pour les connexions privées aux ressources internes utilisant des certificats non publics, vous pouvez également [spécifier des certificats de confiance](../../administration/dedicated/configure_instance/network_security.md#custom-certificate-authorities-for-external-services).

##### Connectivité privée pour les webhooks et les intégrations {#private-connectivity-for-webhooks-and-integrations}

Si vos webhooks et intégrations doivent se connecter à des services non accessibles depuis l'internet public, vous pouvez utiliser AWS PrivateLink pour la connectivité privée. Étant donné que GitLab Dedicated est un service SaaS, il ne peut pas se connecter directement aux adresses IP locales de votre réseau.

Pour configurer la connectivité privée pour vos services internes :

1. Attribuez des noms d'hôte à vos services internes.
1. Configurez vos enregistrements Private Hosted Zone (PHZ) pour router vers ces noms d'hôte via des connexions PrivateLink sortantes.
1. Planifiez en tenant compte de la limite de 10 endpoints pour les connexions PrivateLink sortantes.

Si vous avez besoin de vous connecter à plus de 10 endpoints, vous pouvez utiliser le module Terraform [`terraform-outbound-proxy`](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-outbound-proxy) pour déployer un proxy inverse dans votre VPC. Cette approche achemine plusieurs services via moins de connexions PrivateLink.

#### Chiffrement des données {#data-encryption}

Les données sont chiffrées au repos et en transit à l'aide des dernières normes de chiffrement.

Vous pouvez également utiliser votre propre clé de chiffrement AWS Key Management Service (KMS) pour les données au repos. Cette option vous donne un contrôle total sur les données que vous stockez dans GitLab.

Pour plus d'informations, consultez [Chiffrement de GitLab Dedicated](../../administration/dedicated/encryption.md).

#### Service de messagerie {#email-service}

Par défaut, [Amazon Simple Email Service (Amazon SES)](https://aws.amazon.com/ses/) est utilisé pour envoyer des e-mails de façon sécurisée. Vous pouvez également [configurer votre propre service de messagerie](../../administration/dedicated/configure_instance/users_notifications.md#smtp-email-service) via SMTP.

#### Pare-feu d'application web {#web-application-firewall}

{{< details >}}

- Statut : disponibilité limitée

{{< /details >}}

Cloudflare est mis en œuvre en tant que pare-feu d'application web (WAF) pour la protection contre les attaques par déni de service distribué (DDoS) et les fonctionnalités de sécurité associées. La mise en œuvre et la configuration du WAF sont gérées par l'équipe SRE de GitLab. L'accès direct à la configuration ou aux journaux du WAF n'est pas disponible.

### Conformité {#compliance}

GitLab Dedicated respecte diverses réglementations, certifications et cadres de conformité pour garantir la sécurité et la fiabilité de vos données.

#### Consulter les détails de conformité et de certification {#view-compliance-and-certification-details}

Vous pouvez consulter les détails de conformité et de certification, et télécharger les artefacts de conformité depuis le [GitLab Dedicated Trust Center](https://trust.gitlab.com/?product=gitlab-dedicated).

#### Contrôles d'accès {#access-controls}

GitLab Dedicated met en œuvre des contrôles d'accès stricts pour protéger votre environnement :

- Suit le principe du moindre privilège, qui accorde uniquement les autorisations minimales nécessaires.
- Restreint l'accès à l'organisation AWS à certains membres de l'équipe GitLab.
- Met en œuvre des politiques de sécurité complètes et des demandes d'accès pour les comptes utilisateurs.
- Utilise un seul compte Hub pour les actions automatisées et l'accès d'urgence.
- Les ingénieurs de GitLab Dedicated n'ont pas d'accès direct aux environnements des clients.

Dans les [situations d'urgence](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/incident-management/-/blob/main/procedures/break-glass.md#break-glass-procedure), les ingénieurs GitLab doivent :

1. Utiliser le compte Hub pour accéder aux ressources du client.
1. Demander l'accès via un processus d'approbation.
1. Assumer un rôle IAM temporaire via le compte Hub.

Toutes les actions dans les comptes Hub et locataires sont enregistrées dans CloudTrail.

#### Surveillance {#monitoring}

Dans les comptes locataires, GitLab Dedicated utilise :

- AWS GuardDuty pour la détection d'intrusion et l'analyse des logiciels malveillants.
- La surveillance des journaux d'infrastructure par l'équipe GitLab Security Incident Response Team pour détecter les événements anormaux.

#### Audit et observabilité {#audit-and-observability}

Vous pouvez accéder aux [journaux d'application](../../administration/dedicated/monitor.md) à des fins d'audit et d'observabilité. Ces journaux fournissent des informations sur les activités système et les actions des utilisateurs, vous aidant à surveiller votre instance et à maintenir les exigences de conformité.

### Domaines personnalisés {#custom-domains}

Par défaut, votre instance GitLab Dedicated est accessible à son [URL par défaut](#default-urls). Vous pouvez configurer un domaine personnalisé pour utiliser votre propre nom de domaine, tel que `gitlab.company.com`.

Utilisez des domaines personnalisés pour :

- Conserver vos URL existantes lors de la migration depuis GitLab Self-Managed.
- Maintenir le domaine de votre organisation dans tous les outils.
- S'intégrer aux politiques de gestion de certificats ou de domaines existantes.

Vous pouvez configurer des domaines personnalisés pour :

- Votre instance GitLab principale
- Le registre de conteneurs (par exemple, `registry.company.com`)
- Le serveur d'agent GitLab pour Kubernetes (par exemple, `kas.company.com`)

Pour plus d'informations, consultez [les domaines personnalisés](../../administration/dedicated/configure_instance/network_security.md#custom-domains).

> [!note]
> GitLab Pages ne prend pas en charge les domaines personnalisés. Les sites Pages sont accessibles uniquement à l'URL Pages par défaut, quelle que soit la configuration d'un domaine personnalisé pour votre instance GitLab Dedicated.

### Téléchargements depuis le stockage d'objets {#object-storage-downloads}

Par défaut, GitLab Dedicated active les téléchargements directs depuis S3 pour des performances optimales (`proxy_download = false`). Les téléchargements via proxy ne sont pas pris en charge. Les paramètres suivants ne peuvent pas être définis sur `true` :

- `proxy_download` dans la configuration de stockage d'objets consolidée
- `dependency_proxy_object_store_proxy_download` dans la configuration de stockage d'objets du proxy de dépendances

Les types d'objets qui prennent en charge les téléchargements directs incluent :

- [Artefacts de job CI/CD](../../administration/cicd/job_artifacts.md)
- [Fichiers du proxy de dépendances](../../administration/packages/dependency_proxy.md)
- [Diffs de merge request](../../administration/merge_request_diffs.md)
- [Objets Git Large File Storage (LFS)](../../administration/lfs/_index.md)
- [Packages de projet (par exemple, PyPI, Maven ou NuGet)](../../administration/packages/_index.md)
- [Conteneurs du registre de conteneurs](../../administration/packages/container_registry.md)
- [Téléversements d'utilisateurs](../../administration/uploads.md)

Lorsque vous téléchargez l'un des types d'objets ci-dessus, votre navigateur ou client se connecte directement à Amazon S3 plutôt que de passer par l'infrastructure GitLab.

### Application {#application}

GitLab Dedicated est fourni avec le [jeu de fonctionnalités Ultimate](https://about.gitlab.com/pricing/feature-comparison/) en mode self-managed, avec quelques exceptions. Pour plus d'informations, consultez [Fonctionnalités non disponibles](#unavailable-features).

#### Recherche avancée {#advanced-search}

GitLab Dedicated utilise les [fonctionnalités de recherche avancée](../../integration/advanced_search/elasticsearch.md).

#### ClickHouse Cloud {#clickhouse-cloud}

Vous pouvez accéder aux [fonctionnalités analytiques avancées](../../integration/clickhouse.md) via l'intégration ClickHouse Cloud, qui est activée par défaut pour les clients éligibles. Vous êtes éligible si :

- Votre locataire GitLab Dedicated est déployé dans une région AWS commerciale. GitLab Dedicated for Government n'est pas pris en charge.
- ClickHouse Cloud n'est disponible que dans les régions prises en charge. Pour plus d'informations, consultez [les régions prises en charge](../../administration/dedicated/create_instance/data_residency_high_availability.md#supported-regions).

#### GitLab Pages {#gitlab-pages}

Vous pouvez utiliser [GitLab Pages](../../user/project/pages/_index.md) sur GitLab Dedicated pour héberger votre site web statique. Pages est activé par défaut.

Votre site web utilise l'URL Pages par défaut.

> [!note]
> Les domaines personnalisés ne sont pas pris en charge. Si vous ajoutez un domaine personnalisé tel que `gitlab.my-company.com`, vous accédez quand même à votre site web à l'URL Pages par défaut.

Si vous migrez depuis GitLab Self-Managed et souhaitez conserver un domaine générique existant (par exemple, `*.gitlab-pages.company.com`), vous pouvez utiliser le module Terraform [`terraform-gitlab-pages-redirect`](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/customer-tools/terraform-gitlab-pages-redirect) pour émettre des redirections 301 depuis votre domaine générique existant vers votre URL Pages par défaut.

Contrôlez l'accès à votre site web avec :

- [Contrôle d'accès GitLab Pages](../../user/project/pages/pages_access_control.md)
- [Listes d'autorisation d'IP](../../administration/dedicated/configure_instance/network_security.md#ip-allowlist)

Vos listes d'autorisation d'IP existantes sont appliquées à vos sites web Pages.

En cas de basculement lors d'une reprise après sinistre, votre site continue de fonctionner depuis la région secondaire.

#### Runners hébergés {#hosted-runners}

[Les runners hébergés pour GitLab Dedicated](../../administration/dedicated/hosted_runners.md) vous permettent de faire évoluer vos charges de travail CI/CD sans aucune charge de maintenance.

#### Runners auto-gérés {#self-managed-runners}

Comme alternative à l'utilisation des runners hébergés, vous pouvez utiliser vos propres runners pour votre instance GitLab Dedicated.

Pour utiliser des runners self-managed, installez [GitLab Runner](https://docs.gitlab.com/runner/install/) sur une infrastructure que vous possédez ou gérez.

#### OpenID Connect et SCIM {#openid-connect-and-scim}

Vous pouvez utiliser [SCIM pour la gestion des utilisateurs](../../api/scim.md) ou [GitLab en tant que fournisseur d'identité OpenID Connect](../../integration/openid_connect_provider.md) tout en maintenant les restrictions IP de votre instance.

Pour utiliser ces fonctionnalités avec des listes d'autorisation d'IP :

- [Activer le provisionnement SCIM pour votre liste d'autorisation d'IP](../../administration/dedicated/configure_instance/network_security.md#enable-scim-provisioning-for-your-ip-allowlist)
- [Activer OpenID Connect pour votre liste d'autorisation d'IP](../../administration/dedicated/configure_instance/network_security.md#enable-openid-connect-for-your-ip-allowlist)

### Environnements de pré-production {#pre-production-environments}

GitLab Dedicated prend en charge les environnements de pré-production qui correspondent à la configuration des environnements de production. Vous pouvez utiliser les environnements de pré-production pour :

- Tester les nouvelles fonctionnalités avant de les mettre en œuvre en production.
- Tester les modifications de configuration avant de les appliquer en production.

Les environnements de pré-production doivent être achetés en tant qu'extension à votre abonnement GitLab Dedicated, sans licences supplémentaires requises.

Les capacités suivantes sont disponibles :

- Dimensionnement flexible : correspond à la taille de votre environnement de production ou utilise une architecture de référence plus petite.
- Cohérence des versions : exécute la même version de GitLab que votre environnement de production.

Limitations :

- Déploiement dans une seule région uniquement.
- Aucun engagement de SLA.
- Impossible d'exécuter des versions plus récentes que la production.

## Paramètres gérés par GitLab {#settings-managed-by-gitlab}

Bien que vous puissiez modifier la plupart des paramètres via la zone d'administration, GitLab gère automatiquement certains paramètres pour garantir la stabilité et la sécurité du système.

### Limites de débit {#rate-limits}

GitLab configure les limites de débit en fonction de la taille de votre instance et les réinitialise automatiquement à ces valeurs par défaut lors des fenêtres de maintenance pour garantir des performances optimales. Ces limites empêchent tout utilisateur ou toute automatisation de dégrader les performances pour les autres utilisateurs de votre instance.

Pour plus d'informations sur le fonctionnement des limites de débit dans GitLab Dedicated, consultez [les limites de débit des utilisateurs authentifiés](../../administration/dedicated/user_rate_limits.md).

### Poids de stockage Gitaly {#gitaly-storage-weights}

GitLab configure les poids de stockage pour distribuer uniformément les nouveaux dépôts sur les nœuds Gitaly. Si vous modifiez les poids de stockage dans la zone d'administration, GitLab écrase vos modifications lors du prochain déploiement.

## Fonctionnalités non disponibles {#unavailable-features}

Cette section répertorie les fonctionnalités qui ne sont pas disponibles pour GitLab Dedicated.

### Authentification, sécurité et réseau {#authentication-security-and-networking}

| Fonctionnalité                                       | Description                                                           | Impact                                                       |
| --------------------------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------ |
| Authentification LDAP                           | Authentification à l'aide des identifiants LDAP/Active Directory d'entreprise.     | Vous devez utiliser des mots de passe spécifiques à GitLab ou des jetons d'accès à la place. |
| Authentification par carte à puce                     | Authentification à l'aide de cartes à puce pour une sécurité renforcée.               | Impossible d'utiliser l'infrastructure de carte à puce existante.               |
| Authentification Kerberos                       | Authentification unique à l'aide du protocole Kerberos.                | Vous devez vous authentifier séparément auprès de GitLab.                      |
| FortiAuthenticator/FortiToken 2FA             | Authentification à deux facteurs à l'aide des solutions de sécurité Fortinet.          | Impossible d'intégrer l'infrastructure Fortinet 2FA existante.       |
| Clone Git via HTTPS avec nom d'utilisateur/mot de passe  | Opérations Git utilisant l'authentification par nom d'utilisateur et mot de passe via HTTPS. | Vous devez utiliser des jetons d'accès pour les opérations Git.                   |
| Authentification par certificat SSH                   | Authentification SSH à l'aide de certificats émis par une autorité de certification (CA).                      | Vous devez utiliser une autre méthode d'authentification SSH, telle que les clés SSH.    |
| [Sigstore](../../ci/yaml/signing_examples.md) | Signature et vérification sans clé pour la sécurité de la chaîne d'approvisionnement logicielle.  | Vous devez utiliser des méthodes de signature de code traditionnelles.                   |
| Remappage de port                                | Remapper des ports tels que SSH (22) vers différents ports entrants.                 | GitLab Dedicated utilise uniquement les ports de communication par défaut.      |

### Communication et collaboration {#communication-and-collaboration}

| Fonctionnalité        | Description                                                         | Impact                                                     |
| -------------- | ------------------------------------------------------------------- | ---------------------------------------------------------- |
| Répondre par e-mail | Répondre aux notifications et discussions GitLab par e-mail.      | Vous devez utiliser l'interface web GitLab pour répondre.                  |
| Service Desk   | Système de tickets permettant aux utilisateurs externes de créer des tickets par e-mail. | Les utilisateurs externes doivent avoir des comptes GitLab pour créer des tickets. |

### Fonctionnalités de développement et d'IA {#development-and-ai-features}

| Fonctionnalité                                | Description                                                       | Impact                                       |
|----------------------------------------|-------------------------------------------------------------------|----------------------------------------------|
| Certaines fonctionnalités IA de GitLab Duo        | Fonctionnalités basées sur l'IA pour la détection des vulnérabilités et la productivité. | Assistance IA limitée pour les tâches de développement. |
| Fonctionnalités masquées par des feature flags désactivés | Fonctionnalités en version expérimentale et en version bêta en cours de développement.                   | Aucun accès aux fonctionnalités en version expérimentale ou en version bêta.  |

Pour plus d'informations sur les fonctionnalités d'IA, consultez [GitLab Duo](../../user/gitlab_duo/_index.md).

#### Feature flags {#feature-flags}

Les feature flags sont utilisés pour prendre en charge le développement et le déploiement des nouvelles fonctionnalités, [en version expérimentale et bêta](../../development/documentation/experiment_beta.md). Dans GitLab Dedicated :

- Vous ne pouvez pas modifier les feature flags.
- Les fonctionnalités activées par défaut sont disponibles.
- Les fonctionnalités désactivées par défaut ne sont pas disponibles et ne peuvent pas être activées.

Lorsqu'une fonctionnalité devient généralement disponible, elle l'est dans la même version conformément au [calendrier des releases](../../administration/dedicated/maintenance.md) pour les déploiements.

### GitLab Pages {#gitlab-pages-1}

| Fonctionnalité                | Description                                                     | Impact |
| ---------------------- | --------------------------------------------------------------- | ------ |
| Domaines personnalisés         | Héberger des sites GitLab Pages sur des noms de domaine personnalisés.                 | Sites Pages accessibles uniquement via l'URL Pages par défaut. |
| Espaces de nommage dans le chemin URL | Organiser les sites Pages avec une structure d'URL basée sur les espaces de nommage.        | Options d'organisation des URL limitées. |

### Fonctionnalités opérationnelles {#operational-features}

Les fonctionnalités opérationnelles suivantes ne sont pas disponibles :

- Plusieurs régions secondaires pour la réplication Geo au-delà de la région secondaire par défaut
- [Proxy Geo](../../administration/geo/secondary_proxy/_index.md) et utilisation d'une URL unifiée
- Achat et configuration en libre-service
- Prise en charge du déploiement vers des fournisseurs de cloud non-AWS, tels que GCP ou Azure
- Tableaux de bord d'observabilité dans Switchboard, tels que Grafana et OpenSearch

### Fonctionnalités nécessitant un accès au serveur {#features-that-require-server-access}

Les fonctionnalités suivantes nécessitent un accès direct au serveur et ne peuvent pas être configurées :

| Fonctionnalité                                                       | Description                                                        | Impact                                                                                                                    |
| ------------------------------------------------------------- | ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------- |
| [Hooks Git côté serveur](../../administration/server_hooks.md) | Scripts personnalisés qui s'exécutent lors des événements Git (pre-receive, post-receive). | Utilisez des [règles de push](../../user/project/repository/push_rules.md) ou des [webhooks](../../user/project/integrations/webhooks.md). |

> [!note]
> Les hooks Git côté serveur ne sont pas pris en charge pour des raisons de sécurité et de performance. À la place, utilisez des [règles de push](../../user/project/repository/push_rules.md) pour appliquer des politiques de dépôt ou des [webhooks](../../user/project/integrations/webhooks.md) pour déclencher des actions externes lors d'événements Git.

## Disponibilité du niveau de service {#service-level-availability}

GitLab Dedicated maintient un objectif de niveau de service mensuel de disponibilité à 99,9 %.

La disponibilité du niveau de service mesure le pourcentage de temps pendant lequel GitLab Dedicated est disponible au cours d'un mois calendaire. GitLab calcule la disponibilité sur la base des services principaux suivants :

| Zone de service       | Fonctionnalités incluses                                                                 |
| ------------------ | --------------------------------------------------------------------------------- |
| Interface web      | Tickets GitLab, merge requests, API GitLab, opérations Git via HTTPS |
| Registre de conteneurs | Requêtes HTTPS au registre                                                           |
| Opérations Git     | Opérations Git push, pull et clone via SSH                                     |

### Exclusions du niveau de service {#service-level-exclusions}

Les éléments suivants ne sont pas inclus dans les calculs de disponibilité du niveau de service :

- Interruptions de service causées par des erreurs de configuration du client
- Problèmes liés à l'infrastructure du client ou du fournisseur cloud en dehors du contrôle de GitLab
- Fenêtres de maintenance planifiées
- Maintenance d'urgence pour les problèmes critiques de sécurité ou de données
- Interruptions de service causées par des catastrophes naturelles, des pannes internet généralisées, des défaillances de centres de données ou d'autres événements en dehors du contrôle de GitLab.

### Reprise après sinistre {#disaster-recovery}

Pour plus d'informations sur la reprise après sinistre, y compris les objectifs de récupération, consultez [la reprise après sinistre pour GitLab Dedicated](../../administration/dedicated/disaster_recovery.md).

## Migrer vers GitLab Dedicated {#migrate-to-gitlab-dedicated}

Pour migrer vos données vers GitLab Dedicated :

- Depuis une autre instance GitLab :
  - Utilisez le [transfert direct](../../user/group/import/_index.md).
  - Utilisez l'[API de transfert direct](../../api/bulk_imports.md).
- Depuis des services tiers :
  - Utilisez les [sources d'importation](../../user/import/_index.md) (outils de migration).
- Pour les migrations complexes :
  - Faites appel aux [Services Professionnels](../../user/import/_index.md#migrate-by-engaging-professional-services).

## Abonnements expirés {#expired-subscriptions}

Avant l'expiration de votre abonnement, vous recevez une notification indiquant que la date de fin approche.

Lorsque votre abonnement expire, vous pouvez accéder à votre instance pendant 30 jours.

Pour préserver vos données, contactez votre équipe de compte ou envoyez un e-mail au Support dans les 15 jours suivant l'expiration pour demander la conservation des données.

Durant cette période de 30 jours, vous pouvez :

- Envoyer un e-mail au Support pour demander un délai supplémentaire pour récupérer vos données.
- Faire appel aux Services Professionnels pour une assistance à la migration ou à l'offboarding.

Après 30 jours, si vos données ne sont pas archivées ou migrées vers une autre instance, votre instance est résiliée et tout le contenu client est supprimé. Cela inclut tous les projets, dépôts, tickets, merge requests et autres données.

Vous pouvez demander une confirmation de suppression de compte 90 jours après la résiliation de l'instance. La confirmation est fournie sous la forme d'un e-mail d'AWS indiquant que votre compte est fermé.

## Premiers pas {#get-started}

Pour plus d'informations sur GitLab Dedicated ou pour demander une démonstration, consultez [GitLab Dedicated](https://about.gitlab.com/dedicated/).

Pour plus d'informations sur la configuration de votre instance GitLab Dedicated, consultez [Créer votre instance GitLab Dedicated](../../administration/dedicated/create_instance/_index.md).
