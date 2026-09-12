---
stage: GitLab Dedicated
group: US Public Sector Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>.
title: Guide de configuration sécurisée de GitLab Dedicated for Government
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Dedicated for Government

{{< /details >}}

FedRAMP exige des fournisseurs de services cloud qu'ils créent, maintiennent et publient un [guide de configuration sécurisée](https://www.fedramp.gov/docs/rev5/balance/secure-configuration-guide/). Le mandat inclut des critères obligatoires et des critères recommandés. Utilisez cette page pour renforcer la sécurité de votre instance Dedicated for Government et vous aligner sur les dernières directives FedRAMP.

Critères obligatoires :

- Instructions sur la manière d'accéder, de configurer, d'exploiter et de désaffecter de manière sécurisée les comptes d'administrateur de niveau supérieur qui contrôlent l'accès de l'entreprise à l'ensemble de l'offre de services cloud.
- Explications des paramètres de sécurité qui ne peuvent être gérés que par les comptes d'administrateur de niveau supérieur et leurs implications en matière de sécurité.

Critères recommandés :

- Explications des paramètres de sécurité qui ne peuvent être gérés que par des comptes privilégiés et leurs implications en matière de sécurité.
- Valeurs par défaut sécurisées pour les comptes d'administrateur de niveau supérieur et les comptes privilégiés lors de leur provisionnement initial.

GitLab dispose d'un ensemble étendu de directives de configuration disponibles pour les agences fédérales américaines et les organisations au service du secteur public. Avec [la transparence comme valeur fondamentale](https://handbook.gitlab.com/handbook/values/#transparency), la [documentation GitLab](https://docs.gitlab.com) aborde déjà en détail les éléments obligatoires du guide de configuration sécurisée.

## Architecture {#architecture}

[GitLab Dedicated for Government](../subscriptions/gitlab_dedicated_for_government/_index.md) est une solution SaaS à locataire unique conçue spécifiquement pour les agences gouvernementales. Elle détient une [autorisation d'exploitation FedRAMP Moderate (ATO)](https://marketplace.fedramp.gov/products/FR2411959145), fonctionne sur AWS GovCloud et offre une isolation complète au niveau de l'infrastructure. Chaque environnement client réside dans un compte AWS dédié, séparé des autres locataires.

L'architecture comporte deux couches administratives distinctes :

Couche de gestion de l'infrastructure : gérée par GitLab.

Couche d'administration des applications : contrôlée par les administrateurs clients.

Avant d'examiner les paramètres de configuration de ce guide, consultez le [modèle de responsabilité partagée](dedicated_for_government_shared_responsibility_model.md) pour GitLab Dedicated for Government. Le modèle de responsabilité partagée constitue le fondement permettant de comprendre quelles mesures de renforcement doivent être appliquées par les administrateurs des agences fédérales.

## Exigence 1 : cycle de vie des comptes d'administrateur de niveau supérieur {#requirement-1-top-level-administrator-account-lifecycle}

Cette section couvre l'intégralité du cycle de vie des comptes d'administrateur de niveau supérieur, de la configuration sécurisée et des opérations quotidiennes jusqu'à la désaffectation sécurisée.

Exigence FedRAMP : expliquer comment accéder, configurer, exploiter et désaffecter de manière sécurisée les comptes d'administrateur de niveau supérieur qui contrôlent l'accès de l'entreprise à l'ensemble de l'offre de services cloud.

### Cycle de vie des accès {#access-lifecycle}

Lorsque vous achetez une instance GitLab Dedicated for Government, l'équipe GitLab Dedicated provisionne votre compte d'administrateur de niveau supérieur initial. Les ingénieurs Dedicated vous aident ensuite à configurer une intégration avec une solution de gestion des identités. Une fois configurée, vous avez le contrôle total de l'administration des accès à votre instance.

GitLab Dedicated for Government prend en charge [SAML et OpenID Connect (OIDC)](../subscriptions/gitlab_dedicated_for_government/_index.md#authentication-and-authorization) pour l'authentification unique, ce qui vous permet d'acheminer l'authentification administrative via votre infrastructure d'identité gouvernementale existante. Vous êtes responsable de l'intégration d'un fournisseur d'identité afin de répondre à toutes les exigences PIV/CAC applicables à FedRAMP.

Pour le cycle de vie complet des accès, consultez :

- [Ajouter des utilisateurs](../user/profile/account/create_accounts.md#create-a-user-with-an-authentication-integration)
- [Supprimer ou désactiver des utilisateurs](../user/profile/account/delete_account.md#delete-users-and-user-contributions)

Les administrateurs peuvent ajouter et supprimer d'autres administrateurs selon les besoins. GitLab recommande de créer des comptes d'administrateur dédiés ou d'activer le [mode Admin](../administration/settings/sign_in_restrictions.md#admin-mode), un contrôle de sécurité intégré qui exige des administrateurs qu'ils élèvent explicitement leur session avant d'accéder à la zone d'administration. L'une ou l'autre approche garantit que les comptes privilégiés ne sont utilisés que pour leurs fonctions privilégiées correspondantes.

Une fois votre plateforme d'identité intégrée, l'administrateur de niveau supérieur peut provisionner des utilisateurs pour constituer la base initiale d'utilisateurs. Appliquez le principe du moindre privilège à tous les comptes utilisateurs. Une fois les projets établis, l'accès peut être attribué à des utilisateurs spécifiques via les rôles suivants au niveau du projet :

- Accès minimal
- Invité
- Planificateur
- Rapporteur
- Développeur
- Chargé de maintenance
- Propriétaire

GitLab prend également en charge les types d'utilisateurs suivants pour des cas d'usage particuliers :

- [Utilisateurs auditeurs](../administration/auditor_users.md) : fournit un accès en lecture seule à tous les groupes, projets et autres ressources, à l'exception de la zone d'administration et des paramètres de projet ou de groupe. Utilisez le rôle d'auditeur lors des missions avec des auditeurs tiers nécessitant un accès à certains projets pour valider les processus.
- [Utilisateurs externes](../administration/external_users.md) : fournit un accès limité aux utilisateurs extérieurs à votre organisation, tels que les sous-traitants ou autres tiers. Des contrôles tels que IA-4(4) exigent que les utilisateurs non organisationnels soient identifiés et gérés conformément à la politique de l'entreprise. La définition d'utilisateurs externes réduit les risques en limitant l'accès aux projets par défaut et en aidant les administrateurs à identifier les utilisateurs qui ne font pas partie de l'organisation.
- [Comptes de service](../user/profile/service_accounts.md) : prend en charge les tâches automatisées. Les comptes de service n'utilisent pas de siège dans le cadre de la licence.

GitLab prend en charge les [rôles personnalisés](../user/custom_roles/_index.md) pour des exigences de permissions spécifiques. Pour plus d'informations, consultez les [permissions des projets](../user/permissions.md#project-permissions) et les [permissions des groupes](../user/permissions.md#group-permissions).

Une fois qu'une structure utilisateur suffisante est établie avec les administrateurs provisionnés dans votre plateforme d'identité, traitez le compte d'administrateur de niveau supérieur comme un compte de secours (break-glass), toutes les autres activités administratives s'effectuant via votre fournisseur d'identité standard.

## Exigence 2 {#requirement-2}

Exigence FedRAMP : fournir des explications sur les paramètres de sécurité qui ne peuvent être gérés que par les comptes d'administrateur de niveau supérieur et leurs implications en matière de sécurité.

Cette section énumère les paramètres de configuration spécifiquement disponibles pour Dedicated for Government et oriente les clients vers la documentation étendue déjà disponible pour l'[administration de GitLab](../administration/_index.md).

### Configurations d'infrastructure par les administrateurs de niveau supérieur {#infrastructure-configurations-by-top-level-administrators}

GitLab Dedicated for Government permet aux administrateurs clients de niveau supérieur de demander des configurations de sécurité et d'architecture spécifiques au niveau de l'infrastructure, déclenchées via des demandes adressées à l'équipe de support GitLab.

Ces configurations incluent :

- Établissement de la connectivité réseau avec des ressources en dehors du locataire, par exemple via PrivateLink.
- Apport de clés fournies par le client (Bring-Your-Own-Key) : les clients peuvent demander que le locataire GitLab utilise des clés fournies par le client.
- Configuration de domaines personnalisés : les clients peuvent demander que le locataire GitLab utilise un domaine fourni par le client, plutôt que le domaine Dedicated for Government standard. Il incombe au client de s'assurer que le domaine fourni répond à toutes les exigences applicables en matière de DNSSEC.
- Sélection d'une architecture de référence
- Sélection d'une capacité totale de dépôt
- Sélection d'un nom de locataire
- Sélection des zones de disponibilité
- Réception des clés de licence
- Définition des mots de passe de l'utilisateur root
- Sélection d'un calendrier de déploiement de release/maintenance
- Configuration des listes d'autorisation IP/domaine entrantes et sortantes

## Recommandation 1 {#recommendation-1}

Recommandation FedRAMP : fournir des explications sur les paramètres de sécurité qui ne peuvent être gérés que par des comptes privilégiés et leurs implications en matière de sécurité.

## Exigence 2 : paramètres de sécurité pour les comptes d'administrateur de niveau supérieur {#requirement-2-security-settings-for-top-level-administrator-accounts}

Les paramètres de sécurité disponibles uniquement pour les administrateurs de niveau supérieur ont des implications directes sur la posture de sécurité de l'ensemble de votre instance.

Exigence FedRAMP : fournir des explications sur les paramètres de sécurité qui ne peuvent être gérés que par les comptes d'administrateur de niveau supérieur et leurs implications en matière de sécurité.

### Configurations d'infrastructure pour les administrateurs de niveau supérieur {#infrastructure-configurations-for-top-level-administrators}

GitLab Dedicated for Government prend en charge des configurations de sécurité et d'architecture spécifiques au niveau de l'infrastructure que vous pouvez demander via l'équipe de support GitLab.

Ces configurations incluent :

- Connectivité réseau avec des ressources en dehors du locataire, par exemple via PrivateLink
- Chiffrement géré par le client : demandez que le locataire GitLab utilise des clés de chiffrement fournies par le client. Vous êtes responsable de la création et de la gestion des clés KMS et des politiques de clés.
- Domaines personnalisés : demandez un domaine fourni par le client plutôt que le domaine Dedicated for Government standard. Vous êtes responsable de vous assurer que le domaine répond à toutes les exigences applicables en matière de DNSSEC.
- Sélection de l'architecture de référence
- Capacité totale du dépôt
- Nom du locataire
- Zones de disponibilité
- Clés de licence
- Mots de passe de l'utilisateur root
- Calendrier de déploiement de release et de maintenance
- Listes d'autorisation IP et domaine entrantes et sortantes

### Visibilité publique {#public-visibility}

Par défaut, GitLab restreint le niveau de visibilité publique de l'instance. Un administrateur de niveau supérieur peut activer la visibilité publique pour l'instance dans la zone d'administration, puis configurer la visibilité pour des groupes ou des projets spécifiques. Lorsque vous activez la visibilité publique, vos responsabilités s'élargissent. Pour plus d'informations, consultez [la visibilité publique et le partage de code open source](dedicated_for_government_shared_responsibility_model.md#public-visibility-and-open-source-code-sharing) dans le modèle de responsabilité partagée.

## Recommandation 1 : paramètres de sécurité pour les comptes privilégiés {#recommendation-1-security-settings-for-privileged-accounts}

Les comptes privilégiés situés en dessous de l'administrateur de niveau supérieur ont accès à des paramètres pouvant affecter significativement la sécurité de votre instance et de ses données.

Recommandation FedRAMP : fournir des explications sur les paramètres de sécurité qui ne peuvent être gérés que par des comptes privilégiés et leurs implications en matière de sécurité.

L'administrateur de niveau supérieur et les comptes d'administrateur provisionnés via votre fournisseur d'identité sont fonctionnellement équivalents. Utilisez le compte de niveau supérieur uniquement pour la configuration initiale. Utilisez les comptes d'administrateur provisionnés via votre fournisseur d'identité pour tous les paramètres de sécurité et configurations ultérieurs. Pour toutes les configurations disponibles, consultez [Administrer GitLab](../administration/_index.md).

### Cycle de vie du développement système et gestion des changements {#system-development-lifecycle-and-change-management}

Les administrateurs disposent d'une large gamme d'outils pour sécuriser le cycle de vie du développement logiciel (SDLC) et établir des pratiques de gestion des changements. Pour plus d'informations, consultez [créer et gérer du code avec CI/CD](../topics/build_your_application.md).

Consultez la documentation sur la [sécurité des pipelines](../ci/pipeline_security/_index.md) pour comprendre comment concevoir des pipelines CI/CD en intégrant la sécurité. Le [guide de conformité NIST 800-53](hardening_nist_800_53.md#configuration-management-cm) contient des détails sur la façon d'établir un contrôle des changements et de sécuriser les branches. Examinez les configurations de gestion des changements disponibles pour vous assurer que seules les modifications approuvées sont appliquées à votre base de code.

### Évaluation des risques et intégrité du système et des informations {#risk-assessment-and-system-and-information-integrity}

Vous êtes responsable de la mise en place d'outils pour sécuriser votre code. GitLab inclut une suite d'[outils de détection](../user/application_security/detect/_index.md) que vous pouvez intégrer dans le développement de vos applications, notamment :

- [Configuration de la sécurité](../user/application_security/detect/security_configuration.md)
- [Analyse des conteneurs](../user/application_security/container_scanning/_index.md)
- [Analyse des dépendances](../user/application_security/dependency_scanning/_index.md)
- [Test statique de sécurité des applications (SAST)](../user/application_security/sast/_index.md)
- [Analyse de l'Infrastructure as Code (IaC)](../user/application_security/iac_scanning/_index.md)
- [Détection des secrets](../user/application_security/secret_detection/_index.md)
- [Test dynamique de sécurité des applications (DAST)](../user/application_security/dast/_index.md)
- [Fuzzing d'API](../user/application_security/api_fuzzing/_index.md)
- [Tests de fuzzing guidés par la couverture](../user/application_security/coverage_fuzzing/_index.md)

Vous pouvez appliquer des jobs CI spécifiques pour vous assurer que tout le code est évalué pour les vulnérabilités avant d'être fusionné.

### Gestion des accès {#access-management}

Les rôles suivants disposent de fonctions privilégiées au-delà de l'accès utilisateur standard :

- Chargé de maintenance
- Propriétaire

Ces rôles disposent d'une [documentation étendue sur les permissions](../user/permissions.md) qui nécessite un examen attentif lors du provisionnement des utilisateurs vers des projets et des groupes.

#### Gestion des accès dans la zone d'administration {#access-management-in-the-admin-area}

Dans la zone d'administration, les administrateurs peuvent [exporter les permissions](../administration/admin_area.md#user-permission-export), [examiner les identités des utilisateurs](../administration/admin_area.md#user-identities), [administrer les groupes](../administration/admin_area.md#administering-groups) et bien plus encore. Les fonctions utiles pour répondre aux exigences FedRAMP et NIST 800-53 incluent :

- [Réinitialiser le mot de passe d'un utilisateur](reset_user_password.md) en cas de suspicion de compromission.
- [Déverrouiller des utilisateurs](unlock_user.md). Par défaut, GitLab verrouille les utilisateurs après 10 tentatives de connexion échouées. Les utilisateurs restent verrouillés pendant 10 minutes ou jusqu'à ce qu'un administrateur les déverrouille. Conformément aux directives AC-7, FedRAMP se réfère à NIST 800-63B pour définir les paramètres de verrouillage des comptes, ce que le paramètre par défaut satisfait.
- Consultez les [rapports d'abus](../administration/review_abuse_reports.md) ou les [journaux de spams](../administration/review_spam_logs.md). FedRAMP exige que les organisations surveillent les comptes pour détecter toute utilisation atypique (AC-2(12)). Les utilisateurs peuvent signaler des abus dans les rapports d'abus, où les administrateurs peuvent révoquer l'accès dans l'attente d'une enquête. Les journaux de spams sont consolidés dans la section **Journaux de spams** de la zone d'administration. Les administrateurs peuvent supprimer, bloquer ou approuver les utilisateurs signalés dans cette zone.
- [Inventaire des identifiants](../administration/credentials_inventory.md) : consultez tous les secrets utilisés dans une instance GitLab en un seul endroit. Une vue consolidée des identifiants, jetons et clés peut aider à satisfaire des exigences telles que l'examen des mots de passe ou la rotation des identifiants.
- [Durées de session par défaut](../administration/settings/account_and_limit_settings.md#customize-the-default-session-duration) : FedRAMP exige que les utilisateurs inactifs soient déconnectés après une période définie. FedRAMP ne spécifie pas la période, mais précise que les utilisateurs privilégiés doivent être déconnectés à la fin de la période de travail standard.
- [Provisionner de nouveaux utilisateurs](../user/profile/account/create_accounts.md) : créez des utilisateurs via l'interface utilisateur de la zone d'administration. Conformément à IA-5, GitLab exige que les nouveaux utilisateurs changent leur mot de passe lors de leur première connexion.
- Déprovisionner des utilisateurs : [Supprimez des utilisateurs via l'interface utilisateur de la zone d'administration](../user/profile/account/delete_account.md#delete-users-and-user-contributions). Vous pouvez également [bloquer un utilisateur](../administration/moderate_users.md#block-a-user) pour supprimer tout accès tout en conservant ses données dans les dépôts. Les utilisateurs bloqués n'ont pas d'incidence sur le nombre de sièges.
- Désactiver des utilisateurs : les utilisateurs inactifs identifiés lors des révisions de comptes [peuvent être temporairement désactivés](../administration/moderate_users.md#deactivate-a-user). Contrairement au blocage, la désactivation d'un utilisateur ne l'empêche pas de se connecter à l'interface GitLab. Un utilisateur désactivé peut redevenir actif en se connectant. Un utilisateur désactivé :
  - Ne peut pas accéder aux dépôts ni à l'API.
  - Ne peut pas utiliser les commandes slash.
  - N'occupe pas de siège.

### Clés SSH {#ssh-keys}

GitLab [fournit des instructions](../user/ssh.md) sur la façon de configurer les clés SSH pour s'authentifier et communiquer avec Git. Les commits [peuvent être signés](../user/project/repository/signed_commits/ssh.md), offrant une vérification supplémentaire pour toute personne disposant d'une clé publique. Les administrateurs peuvent [établir les technologies de clés minimales et les longueurs de clés](ssh_keys_restrictions.md).

Vous êtes responsable de vous assurer que les clés SSH sont générées avec des modules cryptographiques validés FIPS.

### Gestion des jetons {#token-management}

GitLab [fournit des instructions](../user/profile/personal_access_tokens.md) sur la façon de configurer et de gérer les jetons d'accès personnels. GitLab prend en charge les [permissions à granularité fine](../auth/tokens/fine_grained_access_tokens.md), qui peuvent être utilisées pour limiter la portée des jetons aux seules permissions requises pour le cas d'usage applicable. Provisionnez uniquement les privilèges minimum requis pour les jetons d'utilisateur et de compte de service afin de limiter l'impact d'un jeton compromis.

### Journalisation des audits et gestion des incidents {#audit-logging-and-incident-management}

Vous êtes responsable de la consommation de vos journaux d'application. Contactez l'équipe de support GitLab pour accéder à des journaux spécifiques dans les compartiments S3 de votre locataire. Les journaux d'infrastructure sous-jacente sont gérés par les ingénieurs Dedicated for Government et surveillés par GitLab Security.

### E-mail {#email}

GitLab prend en charge l'[envoi de notifications par e-mail](../administration/email_from_gitlab.md) et la [configuration des e-mails de notification d'application](../user/profile/notifications.md) pour votre instance. La directive opérationnelle contraignante DHS 18-01 exige que l'authentification, le reporting et la conformité des messages basés sur le domaine (DMARC) soient configurés pour les messages sortants à titre de protection contre le spam. GitLab Dedicated for Government fournit cette configuration par défaut. Vous pouvez désactiver les notifications par e-mail si vous n'avez pas besoin de cette fonctionnalité.

### Runners GitLab {#gitlab-runners}

Les clients Dedicated for Government doivent créer et gérer leurs propres [runners autogérés](../ci/runners/_index.md) en dehors de leur locataire. Pour des conseils de configuration, consultez [configurer les runners](../ci/runners/configure_runners.md). Créez vos runners à l'aide des versions FIPS fournies pour garantir la conformité aux exigences FedRAMP.

Les runners sont une extension de l'infrastructure critique connectée au périmètre FedRAMP. Des runners mal configurés ou compromis peuvent introduire des risques liés à la chaîne d'approvisionnement dans votre pipeline CI/CD et les artefacts en aval. Déployez les runners dans des environnements isolés et renforcés en dehors du périmètre Dedicated. Gérez l'accès aux jetons d'authentification des runners de manière sécurisée, en appliquant les principes du zero trust, et faites-les pivoter régulièrement. Configurez et surveillez la journalisation des audits pour l'activité des runners.

## Recommandation 2 : valeurs par défaut sécurisées pour les comptes d'administrateur {#recommendation-2-secure-defaults-for-administrator-accounts}

La configuration de valeurs par défaut sécurisées lors du provisionnement initial des comptes réduit le risque de mauvaise configuration et établit une base de sécurité solide dès le départ.

Recommandation FedRAMP : définissez tous les paramètres sur leurs valeurs par défaut sécurisées recommandées pour les comptes d'administrateur de niveau supérieur et les comptes privilégiés lors de leur provisionnement initial.

Le compte d'administrateur de niveau supérieur est provisionné de façon à vous permettre de configurer un mot de passe fort lors de la première connexion. Vous devez [enregistrer l'authentification à deux facteurs (2FA)](../user/profile/account/two_factor_authentication.md) pour l'utilisateur root conformément aux exigences FedRAMP. GitLab prend en charge une large gamme de facteurs, notamment les appareils WebAuthn conformes à la norme FIPS et résistants au phishing.

Pour s'aligner sur les principes de sécurité du zero trust, vous devriez :

- Exiger la 2FA pour tous les comptes privilégiés, et pas seulement pour l'utilisateur root.
- Mettre en œuvre des politiques d'accès conditionnel qui vérifient la posture des appareils et le contexte utilisateur avant d'accorder un accès administratif.
- Appliquer des délais d'expiration de session et exiger une ré-authentification pour les opérations sensibles.
- Utiliser des modules cryptographiques validés FIPS pour tous les mécanismes d'authentification.
- Auditer et valider régulièrement que seuls les privilèges administratifs nécessaires sont accordés.

Les administrateurs supplémentaires provisionnés via votre fournisseur d'identité intégré doivent satisfaire aux contrôles organisationnels tels que :

- Application de la longueur et de la complexité des mots de passe
- Verrouillages après échecs de connexion
- Authentification PIV/CAC
- Authentification à deux facteurs gérée par l'organisation
- Verrouillages des utilisateurs inactifs

## Ressources supplémentaires {#additional-resources}

GitLab a publié un [benchmark CIS](https://about.gitlab.com/blog/gitlab-introduces-new-cis-benchmark-for-improved-security/) pour guider les décisions de renforcement de la sécurité pour les administrateurs. Utilisez-le comme point de départ pour créer des projets sécurisés et des ressources d'application au sein de votre instance.
