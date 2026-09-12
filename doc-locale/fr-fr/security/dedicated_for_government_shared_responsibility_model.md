---
stage: GitLab Dedicated
group: US Public Sector Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>.
title: Modèle de responsabilité partagée de GitLab Dedicated for Government
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Dedicated for Government

{{< /details >}}

GitLab Dedicated for Government maintient une autorisation FedRAMP Moderate qui englobe un modèle de responsabilité partagée avec les agences fédérales. Les agences fédérales doivent comprendre leurs responsabilités lorsqu'elles exploitent une instance GitLab Dedicated for Government, ainsi que les responsabilités qu'elles peuvent hériter de l'autorisation GitLab. Ce document vous aide à comprendre :

- Le périmètre d'autorisation et les composants de haut niveau.
- Vos responsabilités en matière de gestion de la sécurité et de la conformité au sein de votre instance GitLab.
- Les fonctionnalités optionnelles qui pourraient affecter le modèle de responsabilité partagée.

## Ressources {#resources}

Pour une présentation détaillée des responsabilités des clients liées aux contrôles NIST 800-53, demandez le package FedRAMP de GitLab Dedicated for Government en utilisant le [formulaire de demande de package FedRAMP](https://www.fedramp.gov/resources/documents/Agency_Package_Request_Form.pdf). L'identifiant du package GitLab est `FR2411959145`. Le modèle Excel Control Implementation Summary/Customer Responsibility Matrix, disponible dans le package FedRAMP sur Connect.gov, est indispensable pour toute agence fédérale qui doit comprendre ses responsabilités.

Le [guide de configuration sécurisée de GitLab Dedicated for Government](dedicated_for_government_secure_config_guide.md) s'appuie sur ce guide des responsabilités en fournissant des conseils de configuration spécifiques et des correspondances avec la documentation GitLab.

## Périmètre d'autorisation {#authorization-boundary}

![Ressources gérées par GitLab et ressources gérées par le client de part et d'autre du périmètre.](img/gdg_boundary_diagram_v19_3.png)

## Vue d'ensemble des responsabilités {#responsibility-overview}

Les sections suivantes ont pour but d'aider les agences fédérales à comprendre les grandes responsabilités couvertes par les clients et GitLab dans un déploiement standard de GitLab Dedicated for Government. Les sections seront divisées en sections fonctionnelles qui décrivent les responsabilités des clients et celles de GitLab. Il est important que les agences fédérales travaillent avec leurs partenaires GitLab pour valider les responsabilités applicables à leur déploiement spécifique. Fonctionnalités et personnalisations optionnelles pouvant avoir un impact sur les responsabilités des clients :

1. [Domaines personnalisés](../subscriptions/gitlab_dedicated/_index.md#custom-domains) \- Les clients peuvent configurer un domaine personnalisé plutôt que d'utiliser le domaine par défaut.
1. [Runners autogérés](../subscriptions/gitlab_dedicated/_index.md#self-managed-runners) \- Les clients peuvent connecter des runners pour prendre en charge les charges de travail CI/CD.
1. Fournisseur d'identité de l'agence fédérale - GitLab prend en charge l'utilisation de fournisseurs SAML et OpenID Connect (OIDC) pour l'authentification unique (Single Sign-On). Pour prendre en charge l'authentification PIV/CAC, les clients doivent apporter leur propre fournisseur d'identité.
1. [Connectivité réseau améliorée](../subscriptions/gitlab_dedicated/_index.md#secure-networking) \- Les clients peuvent choisir de configurer des listes d'autorisation IP avec l'assistance des ingénieurs GitLab, soit via des configurations d'application, soit via des paramètres d'infrastructure. La connectivité privée est prise en charge via PrivateLink pour les connexions entrantes et sortantes.
1. [Chiffrement géré par le client](../administration/dedicated/encryption.md#customer-managed-encryption) \- Les clients peuvent choisir de fournir leurs propres clés de chiffrement.

### Gestion de l'infrastructure {#infrastructure-management}

GitLab est responsable des éléments suivants :

- Correctifs des machines virtuelles et de K8s - Les ingénieurs Dedicated for Government gèrent l'infrastructure sous-jacente sur AWS pour chaque tenant client. La maintenance est planifiée chaque semaine pour maintenir l'infrastructure sous-jacente à jour avec les derniers correctifs de sécurité.
- Durcissement de l'infrastructure, y compris l'application des benchmarks STIG/CIS.
- Chiffrement des données au repos et en transit avec des chiffrements validés FIPS.
- Disponibilité de la plateforme - Dedicated for Government est responsable de la gestion des sauvegardes, des basculements et de tout test de validation des RTO et RPO pour l'environnement.
- Maintenance des listes d'autorisation IP au sein de l'infrastructure réseau AWS. Les clients peuvent fournir des domaines et des listes d'adresses IP clients qui doivent être explicitement autorisés à se connecter à leur instance GitLab. GitLab est responsable de la configuration de ces listes d'autorisation, une fois la demande effectuée.
- Maintenance du pare-feu d'application web Cloudflare et du DNS.
- En cas d'utilisation de BYOK, GitLab doit fournir un identifiant de compte AWS.
- Configuration des protections DMARC et anti-spam pour les e-mails sortants générés par l'application GitLab.

Les clients sont responsables des éléments suivants :

- Maintenance de toute infrastructure connectée au périmètre Dedicated for Government.
- Configuration des listes d'autorisation IP au sein de l'application.
- En cas d'utilisation de la fonctionnalité Bring Your Own Domain, le domaine doit être configuré en conformité avec les exigences FedRAMP, telles que DNSSEC.
- En cas d'utilisation de BYOK, création et gestion des clés KMS et des politiques de clés, et octroi d'accès à l'identifiant de compte AWS fourni par GitLab.
- Demande de configurations d'infrastructure spécifiques via des tickets de support, telles que :
  - Architecture de référence
  - Capacité totale du dépôt
  - Nom du tenant
  - Zones de disponibilité
  - Clés de licence

## Responsabilités {#responsibilities}

Les sections suivantes aident les agences fédérales à comprendre les grandes responsabilités couvertes par les clients et GitLab dans un déploiement standard de GitLab Dedicated for Government. Chaque section est organisée par domaine fonctionnel et présente les responsabilités des clients et celles de GitLab. Travaillez avec vos partenaires GitLab pour valider les responsabilités applicables à votre déploiement spécifique.

Fonctionnalités et personnalisations optionnelles pouvant affecter les responsabilités des clients :

- [Domaines personnalisés](../subscriptions/gitlab_dedicated/_index.md#custom-domains) : configurez un domaine personnalisé plutôt que d'utiliser le domaine par défaut.
- [Runners autogérés](../subscriptions/gitlab_dedicated/_index.md#self-managed-runners) : connectez des runners pour prendre en charge les charges de travail CI/CD.
- Fournisseur d'identité de l'agence fédérale : GitLab prend en charge SAML et OpenID Connect (OIDC) pour l'authentification unique (single sign-on). Pour prendre en charge l'authentification PIV/CAC, vous devez apporter votre propre fournisseur d'identité.
- [Connectivité réseau améliorée](../subscriptions/gitlab_dedicated/_index.md#secure-networking) : configurez des listes d'autorisation IP avec l'assistance des ingénieurs GitLab, soit via des configurations d'application, soit via des paramètres d'infrastructure. La connectivité privée est prise en charge via PrivateLink pour les connexions entrantes et sortantes.
- [Chiffrement géré par le client](../administration/dedicated/encryption.md#customer-managed-encryption) : fournissez vos propres clés de chiffrement.
- [Visibilité publique](#public-visibility-and-open-source-code-sharing) : activez la visibilité publique pour l'instance, puis configurez la visibilité pour des groupes ou des projets spécifiques.
- [GitLab Duo](#gitlab-duo-and-the-ai-gateway) : nécessite GitLab Duo Self-Hosted. Vous installez et maintenez la passerelle d'IA.

### Gestion de l'infrastructure {#infrastructure-management-1}

GitLab est responsable des éléments suivants :

- Les ingénieurs Dedicated for Government gèrent les correctifs des machines virtuelles et de Kubernetes pour chaque tenant client sur AWS. La maintenance est planifiée chaque semaine pour maintenir l'infrastructure sous-jacente à jour avec les derniers correctifs de sécurité.
- L'infrastructure est durcie avec les benchmarks STIG et CIS appliqués.
- Les données au repos et en transit sont chiffrées avec des chiffrements validés FIPS.
- Dedicated for Government gère les sauvegardes, les basculements et les tests de validation des RTO et RPO pour l'environnement.
- Les listes d'autorisation IP sont maintenues au sein de l'infrastructure réseau AWS. Vous pouvez fournir des domaines et des listes d'adresses IP à autoriser explicitement à se connecter à votre instance GitLab. GitLab configure ces listes d'autorisation après votre demande.
- Le pare-feu d'application web Cloudflare et le DNS sont maintenus par GitLab.
- Si vous choisissez d'utiliser BYOK, GitLab fournit un identifiant de compte AWS.
- Les protections DMARC et anti-spam sont configurées pour les e-mails sortants générés par l'application GitLab.

Les clients sont responsables des éléments suivants :

- Maintenance de toute infrastructure connectée au périmètre Dedicated for Government.
- Configuration des listes d'autorisation IP au sein de l'application.
- Si vous utilisez la fonctionnalité Bring Your Own Domain, configurez le domaine en conformité avec les exigences FedRAMP, telles que DNSSEC.
- Si vous utilisez BYOK, créez et gérez les clés KMS et les politiques de clés, et accordez l'accès à l'identifiant de compte AWS fourni par GitLab.
- Demande de configurations d'infrastructure spécifiques via des tickets de support, telles que :
  - Architecture de référence
  - Capacité totale du dépôt
  - Nom du tenant
  - Zones de disponibilité
  - Clés de licence
  - Mots de passe de l'utilisateur root
  - Planning de déploiement des releases et de maintenance

### Application GitLab {#gitlab-application}

GitLab est responsable des éléments suivants :

- L'application GitLab est mise à niveau lors des fenêtres de maintenance hebdomadaires.

Les clients sont responsables des éléments suivants :

- Configuration de l'application GitLab, y compris les paramètres CI/CD et les paramètres au niveau des groupes et des projets.
- Récupération des derniers conteneurs fournis par GitLab, qui peuvent s'exécuter dans des charges de travail gérées par le client.

### Surveillance {#monitoring}

GitLab est responsable des éléments suivants :

- Les événements de sécurité générés par l'infrastructure AWS et les outils de sécurité sont surveillés par GitLab.
- Les métriques d'infrastructure, y compris les métriques de disponibilité et de stabilité de la plateforme, sont surveillées par GitLab.
- Les journaux d'audit sont conservés en conformité avec les exigences réglementaires.
- GitLab répond aux incidents de sécurité provenant des composants d'infrastructure sous-jacents au sein du périmètre d'autorisation, y compris en signalant les incidents aux clients concernés et à l'US-CERT en conformité avec le NIST 800-61.

Les clients sont responsables des éléments suivants :

- Consommation des journaux d'application. Demandez l'accès aux journaux dans S3 via des tickets GitLab Support.
- Surveillance de toute infrastructure autogérée.
- Conservation de tous les journaux d'audit générés par l'infrastructure autogérée connectée à l'instance client.
- Signalement des incidents détectés dans les journaux d'application GitLab ou l'infrastructure autogérée qui pourraient affecter le périmètre FedRAMP.

### Gestion des vulnérabilités {#vulnerability-management}

GitLab est responsable de l'analyse et de l'application des correctifs des éléments suivants :

- Application web. GitLab analyse une application web représentative avec GitLab DAST et applique des correctifs aux vulnérabilités identifiées.
- Conteneurs. GitLab analyse et applique des correctifs à toutes les images de conteneurs dans AWS Elastic Container Registry, qui sont utilisées pour construire les conteneurs en cours d'exécution dans les charges de travail de production. GitLab analyse et applique également des correctifs aux images de conteneurs suivantes, que vous pouvez récupérer depuis GitLab et exécuter dans votre propre infrastructure et vos charges de travail CI/CD :
  - Image GitLab Dynamic Application Security Testing
  - Image GitLab Container Scanner
  - Image GitLab API Security
  - Image GitLab Static Application Security Testing
  - Image GitLab Infrastructure as Code Analyzer
  - Image GitLab Secrets Detection
  - Images GitLab Runner et Runner Helper
  - Image GitLab Dependency Scanning
- Infrastructure. GitLab analyse toutes les VM et AMI utilisées au sein du périmètre d'autorisation Dedicated for Government.

Les clients sont responsables des éléments suivants :

- Analyse et application de correctifs aux ressources déployées en dehors du périmètre d'autorisation, mais connectées à celui-ci.
- Mise en place d'un processus de détection et de remédiation des vulnérabilités dans les images déployées.
- Triage et remédiation des vulnérabilités spécifiques au code géré au sein de votre instance GitLab ou générées par vos charges de travail CI/CD.
- Analyse de toutes les images fournies par GitLab que vous récupérez et exécutez dans votre propre infrastructure.
- Coordination avec GitLab lorsque vous trouvez des vulnérabilités dans les images fournies par GitLab afin de déterminer les calendriers d'application des correctifs.

### Gestion des identités et des accès {#identity-and-access-management}

GitLab est responsable des éléments suivants :

- Prise en charge des intégrations via SAML et OIDC.
- Approvisionnement du premier administrateur pour votre instance GitLab.
- Gestion des accès à l'infrastructure au sein du périmètre d'autorisation.

Les clients sont responsables des éléments suivants :

- Gestion de votre solution de gestion des identités et des accès.
- Distribution des authentificateurs aux employés, y compris les seconds facteurs conformes aux normes FIPS et résistants au phishing.
- Gestion des accès utilisateurs au sein de votre instance GitLab.

### Conformité {#compliance}

GitLab est responsable des éléments suivants :

- Réalisation d'audits annuels et de tests de pénétration du périmètre d'autorisation.
- Soumission des demandes de changements significatifs.
- Maintenance des artefacts de surveillance continue, y compris le Plan of Actions and Milestones.
- Maintenance du Plan de sécurité du système et de ses annexes.

Les clients sont responsables des éléments suivants :

- Soumission des documents et matériaux d'autorisation de l'agence, y compris toute infrastructure connectée au périmètre d'autorisation Dedicated for Government.
- Examen des soumissions mensuelles de surveillance continue avec le Responsable de la sécurité des systèmes d'information GitLab (ISSO).

### Visibilité publique et partage de code open source {#public-visibility-and-open-source-code-sharing}

Les agences fédérales peuvent être tenues de partager publiquement leur code, par exemple en vertu du SHARE IT Act. Par défaut, GitLab Dedicated for Government restreint le niveau de visibilité publique pour l'instance. Un administrateur de niveau supérieur doit activer la visibilité publique avant que tout groupe ou projet puisse être rendu public. Pour les étapes de configuration, consultez [restreindre les niveaux de visibilité](../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels) et [la visibilité des projets et des groupes](../user/public_access.md).

GitLab est responsable des éléments suivants :

- Maintenance de l'infrastructure et des contrôles du périmètre FedRAMP, qui restent inchangés quels que soient les paramètres de visibilité des projets ou des groupes.

Les clients sont responsables des éléments suivants :

- Activation de la visibilité publique pour l'instance, puis configuration de la visibilité pour des groupes ou des projets spécifiques.
- Détermination et documentation de toute dérogation aux exigences de divulgation publique. GitLab n'applique pas et ne valide pas ces dérogations.
- Vérification que les groupes et projets publics n'exposent pas d'informations non classifiées contrôlées (CUI), d'informations personnellement identifiables (PII) ou d'autres données contrôlées. Consultez [les rôles et les autorisations](../user/permissions.md).
- Activation de la [détection des secrets](../user/application_security/secret_detection/_index.md) et examen de [l'inventaire des identifiants](../administration/credentials_inventory.md) avant de rendre un dépôt public. Les utilisateurs non authentifiés peuvent cloner des dépôts publics.
- Vérification que les job logs CI/CD, les résultats d'analyse et les tokens des runners ne sont pas exposés. Consultez [la sécurité des pipelines](../ci/pipeline_security/_index.md).
- Limitation des fonctionnalités individuelles d'un projet public, telles que les tickets, le registre de conteneurs et les pipelines, aux seuls membres lorsque cela est nécessaire. Consultez [modifier la visibilité du projet](../user/public_access.md#change-project-visibility) et [modifier la visibilité des fonctionnalités individuelles d'un projet](../user/public_access.md#change-the-visibility-of-individual-features-in-a-project).

### GitLab Duo et la passerelle d'IA {#gitlab-duo-and-the-ai-gateway}

GitLab Dedicated for Government nécessite une [passerelle d'IA autohébergée](../administration/gitlab_duo/configure/gitlab_dedicated_for_government.md) plutôt que la passerelle d'IA et les modèles gérés par GitLab.

GitLab est responsable des éléments suivants :

- Activation de la connectivité réseau entre votre instance et votre passerelle d'IA autohébergée après votre demande d'accès.

Les clients sont responsables des éléments suivants :

- Installation et maintenance de la [passerelle d'IA](../install/install_ai_gateway.md) dans votre environnement AWS GovCloud, y compris l'application des mises à jour de sécurité et la vérification des images.
- Sélection, hébergement et maintenance des grands modèles de langage utilisés avec GitLab Duo.
- Configuration de l'accès réseau entre la passerelle d'IA, votre instance et les modèles sélectionnés.
