---
stage: GitLab Dedicated
group: US Public Sector Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Solution SaaS monolocataire pour les agences gouvernementales et les industries réglementées.
title: GitLab Dedicated for Government
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Dedicated for Government

{{< /details >}}

GitLab Dedicated for Government est une solution SaaS monolocataire conçue pour les agences gouvernementales et les organisations dans les industries réglementées. GitLab gère l'ensemble de l'infrastructure, des opérations et des exigences de conformité, afin que vos équipes puissent se concentrer sur le développement.

Votre instance dispose des capacités suivantes :

- L'ensemble complet des fonctionnalités de GitLab Ultimate et la plateforme DevSecOps
- Infrastructure isolée dans un compte AWS dédié, déployée sur [AWS GovCloud](https://docs.aws.amazon.com/govcloud-us/latest/UserGuide/whatis.html) dans la région US-West
- Haute disponibilité et reprise après sinistre

## Certifications de conformité {#compliance-certifications}

GitLab Dedicated for Government est autorisé dans le cadre des programmes suivants, afin que votre agence puisse acheter et déployer sans révisions de conformité supplémentaires :

[FedRAMP Moderate](https://marketplace.fedramp.gov/products/FR2411959145?cache=true) : répond aux exigences fédérales de sécurité pour les services cloud, avec une autorisation d'exploitation (ATO).

[GovRAMP](https://govramp.org/product-list/) (Package ID : SR25098) : répond aux exigences de sécurité des gouvernements étatiques et locaux pour les services cloud.

[TX-RAMP](https://dir.texas.gov/information-security/texas-risk-and-authorization-management-program-tx-ramp) Level 2 (TX-RAMP ID : TX1549412) : répond aux exigences de sécurité de l'État du Texas pour les services cloud.

## Architecture de sécurité {#security-architecture}

Votre instance inclut les contrôles de sécurité suivants :

- Conformité FedRAMP Moderate et GovRAMP avec une surveillance continue alignée sur les exigences fédérales et étatiques
- Souveraineté des données garantie par l'infrastructure AWS GovCloud dans la région US-West
- Infrastructure isolée dans un compte AWS dédié, séparé de tous les autres locataires
- Normes de chiffrement répondant aux exigences FIPS pour les données au repos et en transit
- Contrôles d'accès appliquant le principe du moindre privilège avec des pistes d'audit complètes

Pour une description détaillée des responsabilités en matière de sécurité, consultez le [modèle de responsabilité partagée](../../security/dedicated_for_government_shared_responsibility_model.md) et le [guide de configuration sécurisée](../../security/dedicated_for_government_secure_config_guide.md).

### Résidence des données et isolation de l'infrastructure {#data-residency-and-infrastructure-isolation}

Pour répondre aux exigences de résidence des données aux États-Unis, votre instance est déployée sur [AWS GovCloud](https://docs.aws.amazon.com/govcloud-us/latest/UserGuide/whatis.html) dans la région US-West. L'instance GitLab s'exécute exclusivement sur AWS GovCloud. Vos propres charges de travail et systèmes adjacents peuvent s'exécuter sur n'importe quelle plateforme, y compris GCP ou Azure, et s'intégrer à votre instance.

Toutes les données client, y compris les dépôts, les bases de données, les artefacts et les sauvegardes, restent dans le périmètre AWS GovCloud. Votre environnement inclut toute l'infrastructure nécessaire pour héberger l'application GitLab, avec une isolation complète de GitLab.com.

Les données sont chiffrées au repos et en transit selon des normes de chiffrement conformes aux exigences FIPS.

### Contrôles d'accès {#access-controls}

Votre environnement est protégé par plusieurs couches de contrôles de sécurité :

- Les ingénieurs n'ont pas d'accès direct à votre environnement locataire et opèrent avec les autorisations minimales requises pour leur rôle.
- L'infrastructure est surveillée 24 heures sur 24, 7 jours sur 7, pour détecter les menaces de sécurité et les anomalies.
- Tous les accès et modifications sont consignés et examinés par l'équipe de réponse aux incidents de sécurité de GitLab.
- Les demandes d'accès suivent des politiques de sécurité formelles et des workflows d'approbation alignés sur les exigences de conformité gouvernementales.

## Fonctionnalités disponibles {#available-features}

GitLab Dedicated for Government fournit l'ensemble complet des fonctionnalités de GitLab Ultimate. Ces fonctionnalités sont conçues pour fonctionner dans le cadre des normes de conformité FedRAMP et GovRAMP et des frameworks de sécurité gouvernementaux.

### Disponibilité et scalabilité {#availability-and-scalability}

Votre instance exploite des versions modifiées des [architectures de référence hybrides cloud native](../../administration/reference_architectures/_index.md#cloud-native-hybrid) avec la haute disponibilité activée.

Lors de l'[intégration](../../administration/dedicated/create_instance/_index.md#create-your-instance), GitLab vous associe à la taille d'architecture de référence la plus proche en fonction de votre nombre d'utilisateurs.

> [!note]
> Les [architectures de référence](../../administration/reference_architectures/_index.md) publiées servent de base. GitLab Dedicated for Government les enrichit avec des services AWS supplémentaires pour une sécurité et une conformité renforcées, ce qui signifie que les coûts diffèrent des estimations standard des architectures de référence.

### Reprise après sinistre {#disaster-recovery}

GitLab sauvegarde tous vos entrepôts de données, y compris les bases de données et les dépôts Git. Ces sauvegardes sont testées et stockées de manière sécurisée dans une région cloud distincte par défaut, pour une redondance accrue.

### Authentification et autorisation {#authentication-and-authorization}

Vous pouvez configurer l'authentification unique (SSO) en utilisant :

- [SAML](../../administration/dedicated/configure_instance/authentication/saml.md)
- [OpenID Connect (OIDC)](../../administration/dedicated/configure_instance/authentication/openid_connect.md)

Votre instance joue le rôle de fournisseur de services, et vous fournissez la configuration nécessaire pour que GitLab communique avec votre fournisseur d'identité (IdP).

Vous pouvez configurer plusieurs fournisseurs d'identité pour votre instance.

### Distribution des e-mails {#email-delivery}

Les e-mails sont envoyés via [Amazon Simple Email Service (Amazon SES)](https://aws.amazon.com/ses/). La connexion à Amazon SES est chiffrée.

Pour envoyer des e-mails applicatifs via un serveur SMTP plutôt qu'Amazon SES, vous pouvez [configurer votre propre service de messagerie](../../administration/dedicated/configure_instance/users_notifications.md#smtp-email-service).

### Recherche avancée {#advanced-search}

Les fonctionnalités de [recherche avancée](../../user/search/advanced_search.md) sont incluses. Vous pouvez effectuer des recherches dans l'ensemble de votre instance GitLab, notamment dans le code, les éléments de travail, les merge requests et bien plus encore.

### GitLab Duo {#gitlab-duo}

Les fonctionnalités d'IA de [GitLab Duo](../../user/gitlab_duo/_index.md) sont autorisées dans le cadre de FedRAMP et GovRAMP et sont disponibles pour les agences fédérales, étatiques, locales et éducatives sans révision de conformité supplémentaire. Les fonctionnalités disponibles sont les suivantes :

- [Suggestions de code GitLab Duo](../../user/project/repository/code_suggestions/_index.md)
- [GitLab Duo Vulnerability Explanation](../../user/application_security/analyze/duo.md)
- [GitLab Duo Vulnerability Resolution](../../user/application_security/remediate/duo.md)
- [GitLab Duo Chat](../../user/gitlab_duo_chat/_index.md)

## Fonctionnalités non disponibles {#unavailable-features}

Pour maintenir la certification FedRAMP et GovRAMP et répondre aux exigences de sécurité gouvernementales, certaines fonctionnalités GitLab ne sont pas disponibles dans GitLab Dedicated for Government.

### Authentification, sécurité et mise en réseau {#authentication-security-and-networking}

| Fonctionnalité                              | Alternative |
| ------------------------------------ | ----------- |
| Authentification LDAP ou Kerberos      | Utiliser SAML ou OIDC avec votre fournisseur d'identité |
| FortiAuthenticator ou FortiToken 2FA | Utiliser le MFA du fournisseur d'identité |

### Communication et collaboration {#communication-and-collaboration}

| Fonctionnalité        | Alternative |
| -------------- | ----------- |
| Réponse par e-mail | Utiliser l'interface web |
| Service Desk   | Utiliser le suivi de tickets |
| Mattermost     | Utiliser des outils de messagerie externe |

### Fonctionnalités de développement et d'IA {#development-and-ai-features}

| Fonctionnalité                                                            | Alternative |
| ------------------------------------------------------------------ | ----------- |
| Certaines [fonctionnalités d'IA GitLab Duo](../../user/gitlab_duo/_index.md) | Voir les [fonctionnalités d'IA prises en charge](../../user/gitlab_duo/_index.md) |
| [Hooks Git côté serveur](../../administration/server_hooks.md)      | Utiliser les [règles de push](../../user/project/repository/push_rules.md) ou les [webhooks](../../user/project/integrations/webhooks.md) |
| Fonctionnalités configurées en dehors de l'interface utilisateur GitLab           | Contacter le support |

### Fonctionnalités applicatives {#application-features}

GitLab Pages n'est pas disponible lorsqu'un domaine personnalisé est configuré. Lorsque vous configurez un domaine personnalisé, le domaine d'origine `tenant_name.gitlab-dedicated.com` n'est plus disponible, ce qui empêche le fonctionnement de GitLab Pages.

### Fonctionnalités opérationnelles {#operational-features}

Les fonctionnalités opérationnelles suivantes ne sont pas disponibles :

- Geo
- Achat et configuration en libre-service

### Feature flags {#feature-flags}

Les feature flags contrôlent les fonctionnalités disponibles dans votre instance :

- Seules les fonctionnalités avec des flags activés par défaut sont disponibles
- Les fonctionnalités avec des flags désactivés par défaut ne sont pas disponibles
- Vous ne pouvez pas modifier les feature flags

## Opérations de service {#service-operations}

GitLab gère toute la maintenance, la surveillance et le support de votre instance en utilisant des processus opérationnels spécifiques au gouvernement. Ces processus accordent la priorité à la conformité, à la sécurité et à la stabilité dans l'ensemble des activités de maintenance et de support.

### Maintenance {#maintenance}

Votre instance fait l'objet d'une maintenance lors de fenêtres hebdomadaires fixes. Pour plus d'informations, consultez le [calendrier des fenêtres de maintenance](../../administration/dedicated/maintenance.md#maintenance-window-schedule).

### Releases et versions {#releases-and-versions}

Votre instance s'exécute avec une release de retard par rapport à la dernière version de GitLab. Par exemple, si la dernière version est la 16.8, votre instance exécute la version 16.7.

Cette approche assure la stabilité tout en vous permettant de recevoir les correctifs de sécurité critiques via une maintenance d'urgence. Pour plus d'informations, consultez le [calendrier de déploiement des releases](../../administration/dedicated/releases.md#release-rollout-schedule).

### Accord de niveau de service {#service-level-agreement}

Votre instance maintient un accord de niveau de service (SLA) de 99,9 % de disponibilité mensuelle. GitLab utilise des objectifs de niveau de service internes (SLO) pour soutenir la réalisation de cet engagement SLA.

Les objectifs suivants s'appliquent :

- Objectif de point de récupération (RPO) : fenêtre de perte de données maximale de 4 heures dans un scénario de reprise après sinistre
- Objectif de temps de récupération (RTO) : la restauration du service est priorisée en fonction de la gravité et de l'impact de l'incident

GitLab s'efforce de restaurer le service aussi rapidement que possible tout en garantissant l'intégrité et la sécurité des données.

## Contacter les équipes commerciales {#contact-sales}

Prêt à démarrer ? [Contactez notre équipe commerciale](https://about.gitlab.com/sales/) pour discuter de vos besoins et découvrir comment nous pouvons accompagner les exigences de conformité et de sécurité de votre organisation.
