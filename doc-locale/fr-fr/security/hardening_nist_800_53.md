---
stage: GitLab Dedicated
group: US Public Sector Services
info: All material changes to this page must be approved by the [FedRAMP Compliance team](https://handbook.gitlab.com/handbook/security/security-assurance/security-compliance/fedramp-compliance/#gitlabs-fedramp-initiative). To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments.
title: Conformité NIST 800-53
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Cette page est une référence pour les administrateurs GitLab qui souhaitent configurer des instances GitLab Self-Managed afin de satisfaire aux contrôles NIST 800-53 applicables. GitLab ne fournit pas de conseils de configuration spécifiques en raison de la diversité des exigences qu'un administrateur peut avoir. Avant de déployer une instance GitLab conforme aux contrôles de sécurité NIST 800-53, vous devriez travailler avec un architecte de solutions client pour les détails techniques.

## Portée {#scope}

Cette page suit la structure des familles de contrôles NIST 800-53. Étant donné que la portée de la page se limite principalement aux configurations apportées à GitLab lui-même, toutes les familles de contrôles ne s'appliquent pas. Les détails de configuration sont destinés à être indépendants de la plateforme.

Les recommandations GitLab ne constituent pas un système entièrement conforme. Avant de traiter des données gouvernementales, vous devriez :

- Prévoir une configuration et un renforcement supplémentaires de l'ensemble de votre stack technologique.
- Envisager une évaluation indépendante des configurations de sécurité.
- Comprendre les différences de déploiement entre les [fournisseurs cloud pris en charge](../install/cloud_providers.md) et suivre les recommandations spécifiques disponibles.

## Fonctionnalités de conformité {#compliance-features}

GitLab propose plusieurs [fonctionnalités de conformité](../administration/compliance/compliance_features.md) que vous pouvez utiliser pour automatiser les contrôles critiques et les workflows dans GitLab. Avant d'effectuer des configurations alignées sur NIST 800-53, vous devriez activer ces fonctionnalités fondamentales.

## Configuration par famille de contrôles {#configuration-by-control-family}

### Acquisition de systèmes et de services (SA) {#system-and-service-acquisition-sa}

GitLab est une [plateforme DevSecOps](../devsecops.md) qui intègre la sécurité tout au long du cycle de vie de développement. En son cœur, vous pouvez utiliser GitLab pour couvrir un large éventail de contrôles dans la famille de contrôles SA.

#### Cycle de vie du développement des systèmes {#system-development-lifecycle}

Vous pouvez utiliser GitLab pour satisfaire au cœur de cette exigence. GitLab fournit une plateforme où le travail peut être [organisé](../user/project/organize_work_with_projects.md), [planifié et suivi](../topics/plan_and_track.md). NIST 800-53 exige que la sécurité soit intégrée dans le développement de l'application. Vous pouvez configurer des [pipelines CI/CD](../topics/build_your_application.md) pour tester en continu le code lors de sa livraison et appliquer simultanément des politiques de sécurité. GitLab inclut une suite d'outils de sécurité que vous pouvez intégrer dans le développement d'applications client, notamment :

- [Configuration de la sécurité](../user/application_security/detect/security_configuration.md)
- [Analyse des conteneurs](../user/application_security/container_scanning/_index.md)
- [Analyse des dépendances](../user/application_security/dependency_scanning/_index.md)
- [Test statique de sécurité des applications](../user/application_security/sast/_index.md)
- [Analyse Infrastructure as Code (IaC)](../user/application_security/iac_scanning/_index.md)
- [Détection des secrets](../user/application_security/secret_detection/_index.md)
- [Test dynamique de sécurité des applications (DAST)](../user/application_security/dast/_index.md)
- [Fuzzing d'API](../user/application_security/api_fuzzing/_index.md)
- [Test de fuzzing guidé par la couverture](../user/application_security/coverage_fuzzing/_index.md)

Au-delà du pipeline CI/CD, GitLab fournit des [recommandations détaillées sur la configuration des releases](../user/project/releases/_index.md). Les releases peuvent être créées avec un pipeline CI/CD et prendre un instantané de n'importe quelle branche du code source dans un dépôt. Les instructions de création de releases sont incluses dans [Créer une release](../user/project/releases/_index.md#create-a-release). Un point important à considérer pour la conformité NIST 800-53 ou FedRAMP est que le code publié peut nécessiter d'être signé pour vérifier l'authenticité du code et satisfaire aux exigences de la famille de contrôles Intégrité du système et des informations (SI).

### Contrôle d'accès (AC) et Identification et authentification (IA) {#access-control-ac-and-identification-and-authentication-ia}

La gestion des accès dans un déploiement GitLab est propre à chaque client. GitLab fournit une gamme de documentation couvrant les déploiements avec des fournisseurs d'identité et les configurations d'authentification natives de GitLab. Il est important de prendre en compte les exigences organisationnelles avant de déterminer la méthode d'authentification à une instance GitLab.

#### Fournisseurs d'identité {#identity-providers}

L'accès dans GitLab peut être géré via l'interface utilisateur ou en s'intégrant à un fournisseur d'identité existant. Pour satisfaire aux exigences FedRAMP, assurez-vous que le fournisseur d'identité existant est autorisé FedRAMP sur le [FedRAMP Marketplace](https://marketplace.fedramp.gov/products). Pour satisfaire à des exigences telles que PIV, vous devriez utiliser un fournisseur d'identité plutôt que d'utiliser l'authentification native dans GitLab Self-Managed.

GitLab fournit des ressources pour configurer divers fournisseurs d'identité et protocoles, notamment

- [LDAP](../administration/auth/ldap/_index.md)

- [SAML](../integration/saml.md)

- Pour plus d'informations sur les fournisseurs d'identité, consultez [Authentification et autorisation GitLab](../administration/auth/_index.md).

#### Configurations d'authentification utilisateur natives de GitLab {#native-gitlab-user-authentication-configurations}

**Account management and classification** \- GitLab permet aux administrateurs de suivre les utilisateurs avec différents niveaux de sensibilité et d'exigences d'accès. GitLab prend en charge le concept de moindre privilège et d'accès basé sur les rôles en proposant des options d'accès granulaire. Au niveau du projet, les rôles suivants sont pris en charge

- Invité

- Rapporteur

- Développeur

- Chargé de maintenance

- Propriétaire

Des détails supplémentaires sur les [permissions au niveau du projet](../user/permissions.md#project-permissions) sont disponibles dans la documentation. GitLab prend également en charge les [rôles personnalisés](../user/custom_roles/_index.md) pour les clients ayant des exigences d'autorisation uniques.

GitLab prend également en charge les types d'utilisateurs suivants pour des cas d'utilisation spécifiques :

- [Utilisateurs auditeurs](../administration/auditor_users.md) \- Le rôle d'auditeur fournit un accès en lecture seule à tous les groupes, projets et autres ressources, à l'exception de la zone **Admin** et des paramètres de projet/groupe. Vous pouvez utiliser le rôle d'auditeur lors d'interactions avec des auditeurs tiers qui nécessitent un accès à certains projets pour valider des processus.

- [Utilisateurs externes](../administration/external_users.md) \- Les utilisateurs externes peuvent être configurés pour fournir un accès limité aux utilisateurs qui ne font pas nécessairement partie de l'organisation. Généralement, cela peut être utilisé pour gérer les accès des prestataires ou d'autres tiers. Des contrôles tels que IA-4(4) exigent que les utilisateurs non organisationnels soient identifiés et gérés conformément à la politique de l'entreprise. La configuration d'utilisateurs externes peut réduire les risques pour une organisation en limitant par défaut l'accès aux projets et en aidant les administrateurs à identifier les utilisateurs qui ne sont pas employés par l'organisation.

- [Comptes de service](../user/profile/service_accounts.md) \- Des comptes de service peuvent être ajoutés pour prendre en charge des tâches automatisées. Les comptes de service n'utilisent pas de siège dans le cadre de la licence.

Zone **Admin** \- Dans la zone **Admin**, les administrateurs peuvent [exporter les permissions](../administration/admin_area.md#user-permission-export), [vérifier les identités des utilisateurs](../administration/admin_area.md#user-identities), [administrer les groupes](../administration/admin_area.md#administering-groups), et bien plus encore. Fonctions pouvant être utilisées pour satisfaire aux exigences FedRAMP / NIST 800-53 :

- [Réinitialiser le mot de passe utilisateur](reset_user_password.md) en cas de suspicion de compromission.

- [Déverrouiller les utilisateurs](unlock_user.md). Par défaut, GitLab verrouille les utilisateurs après 10 tentatives de connexion échouées. Les utilisateurs restent verrouillés pendant 10 minutes ou jusqu'à ce qu'un administrateur déverrouille l'utilisateur. Dans GitLab 16.5 et versions ultérieures, les administrateurs peuvent [utiliser l'API](../api/settings.md#available-settings) pour configurer le nombre maximal de tentatives de connexion et la durée de verrouillage. Conformément aux recommandations de AC-7, FedRAMP se réfère à NIST 800-63B pour définir les paramètres de verrouillage de compte, auxquels le paramètre par défaut répond.

- Examiner les [rapports d'abus](../administration/review_abuse_reports.md) ou les [journaux de spams](../administration/review_spam_logs.md). FedRAMP exige que les organisations surveillent les comptes pour détecter une utilisation atypique (AC-2(12)). GitLab permet aux utilisateurs de signaler des abus dans les rapports d'abus, où les administrateurs peuvent supprimer l'accès dans l'attente d'une investigation. Les journaux de spams sont regroupés dans la section **Journaux de spams** de la zone **Admin**. Les administrateurs peuvent supprimer, bloquer ou approuver les utilisateurs signalés dans cette zone.

- [Définir les paramètres de stockage des mots de passe](../user/profile/user_passwords.md). Les secrets stockés doivent satisfaire aux exigences FIPS 140-2 ou 140-3 comme indiqué dans SC-13. PBKDF2+SHA512 est pris en charge avec des chiffrements conformes FIPS lorsque le mode FIPS est activé.

- L'[inventaire des informations d'identification](../administration/credentials_inventory.md) permet aux administrateurs de vérifier tous les secrets utilisés dans une instance GitLab Self-Managed en un seul endroit. Une vue consolidée des informations d'identification, des jetons et des clés peut aider à satisfaire des exigences telles que la vérification des mots de passe ou la rotation des informations d'identification.

- [Modifier les exigences de complexité des mots de passe](../administration/settings/sign_up_restrictions.md#modify-password-complexity-requirements). FedRAMP se réfère à NIST 800-63B dans IA-5 pour établir les exigences de longueur de mot de passe. GitLab prend en charge des mots de passe de 8 à 128 caractères, avec 8 caractères définis par défaut.

- [Durées de session par défaut](../administration/settings/account_and_limit_settings.md#customize-the-default-session-duration) \- FedRAMP stipule que les utilisateurs inactifs pendant une période définie doivent être déconnectés. FedRAMP ne spécifie pas la période de temps, mais précise que pour les utilisateurs privilégiés, ils doivent être déconnectés à la fin de la période de travail standard. Les administrateurs peuvent établir des [durées de session par défaut](../administration/settings/account_and_limit_settings.md#customize-the-default-session-duration).

- [Provisionnement de nouveaux utilisateurs](../user/profile/account/create_accounts.md) \- Les administrateurs peuvent créer de nouveaux utilisateurs pour leur compte GitLab via l'interface utilisateur de la zone **Admin**. En conformité avec IA-5, GitLab exige des nouveaux utilisateurs qu'ils changent leur mot de passe lors de leur première connexion.

- Déprovisionnement des utilisateurs - Les administrateurs peuvent [supprimer des utilisateurs via l'interface utilisateur de la zone **Admin**](../user/profile/account/delete_account.md#delete-users-and-user-contributions). Une alternative à la suppression des utilisateurs est de [bloquer un utilisateur](../administration/moderate_users.md#block-a-user) et de supprimer tout accès. Le blocage d'un utilisateur conserve ses données dans les dépôts tout en supprimant tous les accès. Les utilisateurs bloqués n'ont aucun impact sur le nombre de sièges.

- Désactivation des utilisateurs - Les utilisateurs inactifs identifiés lors des revues de compte [peuvent être temporairement désactivés](../administration/moderate_users.md#deactivate-a-user). La désactivation est similaire au blocage, mais il existe quelques différences importantes. La désactivation d'un utilisateur ne l'empêche pas de se connecter à l'interface GitLab. Un utilisateur désactivé peut redevenir actif en se connectant. Un utilisateur désactivé :
  - Ne peut pas accéder aux dépôts ni à l'API.

  - Ne peut pas utiliser les commandes slash. Pour plus d'informations, consultez la documentation sur les commandes slash.

  - N'occupe pas de siège.

#### Méthodes d'identification supplémentaires {#additional-identification-methods}

**Authentification à deux facteurs** - [GitLab prend en charge les seconds facteurs suivants](../user/profile/account/two_factor_authentication.md) :

- Authentificateurs à mot de passe à usage unique

- Appareils WebAuthn

Les [instructions pour activer l'authentification à deux facteurs](../user/profile/account/two_factor_authentication.md#enable-two-factor-authentication) sont fournies dans la documentation. Les clients poursuivant la certification FedRAMP doivent prendre en compte les fournisseurs d'authentification à deux facteurs autorisés par FedRAMP et prenant en charge les exigences FIPS. Les fournisseurs autorisés FedRAMP sont disponibles sur le [FedRAMP Marketplace](https://marketplace.fedramp.gov/products). Lors du choix d'un second facteur, le NIST et FedRAMP indiquent désormais que l'authentification résistante au phishing, telle que WebAuthn, doit être utilisée (IA-2).

**Clés SSH**

- GitLab [fournit des instructions](../user/ssh.md) sur la façon de configurer des clés SSH pour s'authentifier et communiquer avec Git. Les commits [peuvent être signés](../user/project/repository/signed_commits/ssh.md), offrant une vérification supplémentaire pour toute personne disposant d'une clé publique.

- Les clés doivent être configurées pour satisfaire aux exigences applicables en matière de robustesse et de complexité, telles que l'utilisation de chiffrements validés FIPS 140-2 et FIPS 140-3. Les administrateurs peuvent [restreindre les technologies de clé minimales et les longueurs de clé](ssh_keys_restrictions.md). De plus, GitLab [bloque les clés compromises](../user/ssh.md#add-an-ssh-key-to-your-gitlab-account).

**Jetons d'accès personnels**

GitLab [fournit des instructions](../user/profile/personal_access_tokens.md) sur la façon de configurer et de gérer les jetons d'accès personnels. GitLab prend en charge des [permissions à granularité fine](../auth/tokens/fine_grained_access_tokens.md), qui peuvent être utilisées pour limiter la portée des jetons aux seules permissions requises pour le cas d'utilisation applicable.

#### Autres concepts de la famille Contrôle d'accès {#other-access-control-family-concepts}

**System Use Notifications**

Les exigences fédérales prévoient souvent la nécessité d'une bannière lors de la connexion. Cela peut être configuré via un fournisseur d'identité et via la [fonctionnalité de bannière GitLab](../administration/broadcast_messages.md).

**External Connections**

Il est important de documenter toutes les connexions externes et de s'assurer qu'elles satisfont aux exigences de conformité. Par exemple, la mise en place d'une intégration API avec un tiers peut violer les exigences de traitement des données, selon la façon dont ce tiers sécurise les données client. Il est important de vérifier toutes les connexions externes et de comprendre leurs impacts sur la sécurité avant de les activer. Pour les clients poursuivant la certification FedRAMP ou des certifications similaires, la connexion à d'autres services non autorisés par FedRAMP ou à des services d'un niveau d'impact sur les données inférieur peut violer le périmètre d'autorisation.

**Personal Identity Verification (PIV)**

Les cartes de vérification d'identification personnelle peuvent être une exigence pour les organisations soumises aux exigences fédérales. Pour satisfaire aux exigences PIV, GitLab demande aux clients de connecter des solutions d'identité compatibles PIV avec SAML. Un lien vers la documentation SAML est fourni plus haut dans ce guide.

### Audit et responsabilité (AU) {#audit-and-accountability-au}

NIST 800-53 exige que les organisations surveillent les événements pertinents pour la sécurité, analysent ces événements, génèrent des alertes et enquêtent sur ces alertes en fonction de leur criticité. GitLab fournit un large éventail d'événements de sécurité à des fins de surveillance pouvant être acheminés vers une solution de gestion des informations et des événements de sécurité (SIEM).

#### Types d'événements {#event-types}

GitLab décrit les [types de journaux d'événements d'audit configurables](../administration/compliance/audit_event_streaming.md), qui peuvent être diffusés en streaming et/ou sauvegardés dans une base de données. Les administrateurs peuvent configurer les événements qu'ils souhaitent capturer pour leur instance GitLab.

**Log System**

GitLab inclut un système de journalisation avancé où tout peut être enregistré. GitLab propose des [recommandations sur le système de journalisation](../administration/logs/_index.md#importerlog) et les types de journaux, qui incluent un large éventail de sorties. Consultez les recommandations liées pour plus de détails.

Événements en streaming

Les administrateurs GitLab peuvent diffuser en streaming les événements d'audit vers un SIEM ou un autre emplacement de stockage à l'aide de la [fonctionnalité de streaming d'événements](../user/compliance/audit_event_streaming.md). Les administrateurs peuvent configurer plusieurs destinations et définir des en-têtes d'événements. GitLab [fournit des exemples](../user/compliance/audit_event_schema.md) de streaming d'événements présentant les en-têtes, les charges utiles pour les événements HTTP et HTTPS, et bien plus encore.

Il est important que les administrateurs examinent les exigences FedRAMP ou NIST 800-53 AU-2 et mettent en œuvre des événements d'audit correspondant au type d'événement d'audit requis. AU-2 identifie les catégories d'événements suivantes :

- Événements de connexion réussis et échoués

- Événements de gestion de compte

- Accès aux objets

- Changement de politique

- Fonctions privilégiées

- Suivi des processus

- Événements système

- Pour les applications Web :

  - Toute l'activité administrateur

  - Vérifications d'authentification

  - Vérifications d'autorisation

  - Suppressions de données

  - Accès aux données

  - Modifications de données

  - Modifications de permissions

Les administrateurs doivent prendre en compte à la fois les types d'événements requis et toute exigence organisationnelle supplémentaire lors de l'activation des événements dans GitLab.

**Métriques**

En dehors des événements de sécurité, les administrateurs peuvent également souhaiter avoir une visibilité sur les performances de leur application pour assurer la disponibilité. GitLab fournit un [ensemble complet de documentation sur les métriques](../administration/monitoring/_index.md) prises en charge dans une instance GitLab.

**Stockage**

Les clients sont responsables de s'assurer que les journaux sont stockés dans une solution de stockage à long terme satisfaisant aux exigences de conformité. FedRAMP, par exemple, exige que les journaux soient conservés pendant 1 an. Les organisations clientes peuvent également avoir à respecter les exigences de la National Archives and Records Administration, selon l'impact des données collectées. Il est important d'évaluer l'impact des enregistrements collectés et de comprendre les exigences de conformité applicables.

### Réponse aux incidents (IR) {#incident-response-ir}

Une fois les événements d'audit configurés, ces événements doivent être surveillés. GitLab fournit une interface de gestion centralisée pour compiler les alertes système provenant d'un SIEM ou d'autres outils de sécurité, trier les alertes et les incidents, et informer les parties prenantes. La [documentation sur la gestion des incidents](../operations/incident_management/_index.md) décrit comment GitLab peut être utilisé pour mener les activités susmentionnées dans une organisation de réponse aux incidents de sécurité.

**Incident Response Lifecycle**

GitLab peut gérer l'intégralité du cycle de vie de la réponse aux incidents pour une organisation. Consultez les ressources suivantes, qui peuvent aider à satisfaire aux exigences de réponse aux incidents :

- [Alertes](../operations/incident_management/alerts.md)

- [Incidents](../operations/incident_management/incidents.md)

- [Plannings d'astreinte](../operations/incident_management/oncall_schedules.md)

- [Page de statut](../operations/incident_management/status_page.md)

### Gestion de la configuration (CM) {#configuration-management-cm}

**Change Control**

GitLab, en son cœur, peut satisfaire aux exigences de gestion de la configuration liées au contrôle des changements. Les tickets et les merge requests sont les principales méthodes de prise en charge des changements.

Les tickets sont une plateforme flexible pour capturer les métadonnées et les approbations avant de mettre en œuvre des changements. Consultez la documentation GitLab sur la [planification et le suivi du travail](../topics/plan_and_track.md) pour avoir une compréhension complète de la façon dont les fonctionnalités GitLab peuvent être utilisées pour satisfaire aux contrôles de gestion de la configuration.

Les merge requests offrent une méthode pour standardiser les changements d'une branche source vers une branche cible. Dans le contexte de NIST 800-53, il est important de déterminer comment les approbations doivent être collectées avant de fusionner le code et qui a la capacité de fusionner du code au sein de l'organisation. GitLab fournit des recommandations sur les [différents paramètres disponibles pour les approbations dans les merge requests](../user/project/merge_requests/approvals/_index.md). Envisagez d'attribuer les privilèges d'approbation et de fusion uniquement aux rôles appropriés, une fois les revues nécessaires effectuées. Paramètres de fusion supplémentaires à prendre en compte :

- Supprimer toutes les approbations lorsqu'un commit est ajouté - Garantit que les approbations ne sont pas reportées lorsque de nouveaux commits sont effectués dans une merge request.

- Restreindre les personnes qui peuvent ignorer les revues de modifications du code.

- Attribuer des [propriétaires du code](../user/project/codeowners/_index.md#codeowners-file) pour être notifiés lorsque du code ou des configurations sensibles sont modifiés via des merge requests.

- [S'assurer que tous les commentaires ouverts sont résolus avant d'autoriser la fusion des modifications du code](../user/project/merge_requests/_index.md#prevent-merge-unless-all-threads-are-resolved).

- [Configurer des règles de push](../user/project/repository/push_rules.md) \- Les règles de push peuvent être configurées pour satisfaire à des exigences telles que la vérification du code signé, la vérification des utilisateurs, et plus encore.

**Testing and Validation of Changes**

Les [pipelines CI/CD](../topics/build_your_application.md) sont un composant essentiel du test et de la validation des changements. Il est de la responsabilité du client de mettre en œuvre des pipelines de test et de validation suffisants pour des cas d'utilisation spécifiques. Lors du choix des services, tenez compte de l'endroit où ce pipeline s'exécute. La connexion à des services externes peut violer un périmètre d'autorisation établi où les données fédérales sont autorisées à être stockées et traitées. GitLab fournit des images de conteneurs de runners configurées pour s'exécuter sur des systèmes FIPS. GitLab fournit des recommandations de renforcement pour les pipelines, notamment comment [configurer des branches protégées](../user/project/repository/branches/protected.md) et [mettre en œuvre la sécurité des pipelines](../ci/pipelines/_index.md#pipeline-security-on-protected-branches). De plus, les clients peuvent envisager d'attribuer des [vérifications requises](../user/project/merge_requests/status_checks.md) avant de fusionner le code pour s'assurer que toutes les vérifications ont réussi avant de mettre à jour le code.

**Component Inventory**

NIST 800-53 exige que les fournisseurs de services cloud maintiennent des inventaires de composants. GitLab ne peut pas directement suivre le matériel sous-jacent, mais peut générer des inventaires logiciels via l'analyse des conteneurs et des dépendances. GitLab décrit les [dépendances que l'analyse des conteneurs et l'analyse des dépendances peuvent détecter](../user/application_security/comparison_dependency_and_container_scanning.md). GitLab propose une documentation supplémentaire sur la génération de listes de dépendances, qui peuvent être utilisées dans les [inventaires de composants logiciels](../user/application_security/dependency_list/_index.md). La prise en charge du Software Bill of Materials est traitée plus loin dans ce document, dans la section Gestion des risques de la chaîne d'approvisionnement.

**Container Registry**

GitLab fournit un registre de conteneurs intégré pour stocker les images de conteneurs des projets GitLab, qui peut être utilisé comme dépôt de référence pour le déploiement de conteneurs dans un environnement hautement virtualisé et évolutif. Les [recommandations d'administration du registre de conteneurs](../administration/packages/container_registry.md) sont disponibles pour consultation.

### Planification de la continuité (CP) {#contingency-planning-cp}

GitLab fournit des recommandations et des services pouvant aider à satisfaire aux exigences essentielles de planification de la continuité. Il est important de consulter la documentation incluse et de planifier en conséquence pour satisfaire aux exigences organisationnelles en matière d'activités de planification de la continuité. La planification de la continuité est propre à chaque organisation, il est donc important de prendre en compte les besoins organisationnels avant d'établir un plan de continuité.

**Selecting a GitLab Architecture**

GitLab fournit une documentation complète sur les architectures prises en charge dans une instance GitLab Self-Managed. GitLab prend en charge les fournisseurs de services cloud suivants :

- [Azure](../install/azure/_index.md)

- [Google Cloud Platform](../install/google_cloud_platform/_index.md)

- [Amazon Web Services](../install/aws/_index.md)

GitLab fournit un [arbre de décision pour aider les clients à sélectionner des architectures de référence et des modèles de disponibilité](../administration/reference_architectures/_index.md#decision-tree). La plupart des fournisseurs de services cloud assurent la résilience dans une région pour les services managés. Lors du choix d'une architecture, il est important de prendre en compte la tolérance de l'organisation aux temps d'arrêt et la criticité des données. GitLab Geo peut être envisagé pour des capacités supplémentaires de réplication et de basculement.

**Identify Critical Assets**

NIST 800-53 exige l'identification des actifs critiques pour assurer leur restauration prioritaire lors d'une interruption. Les actifs critiques à prendre en compte incluent les nœuds Gitaly et les bases de données PostgreSQL. Les clients doivent identifier les actifs supplémentaires nécessitant des sauvegardes ou une réplication selon les besoins.

**Backups**

La documentation décrit les stratégies de sauvegarde pour les composants critiques, notamment :

- [Bases de données PostgreSQL](../administration/backup_restore/backup_gitlab.md#postgresql-databases)

- [Dépôts Git](../administration/backup_restore/backup_gitlab.md#git-repositories)

- [Blobs](../administration/backup_restore/backup_gitlab.md#blobs)

- [Container Registry](../administration/backup_restore/backup_gitlab.md#container-registry)

- [Redis](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/#backing-up-redis-data)

- [Fichiers de configuration](../administration/backup_restore/backup_gitlab.md#storing-configuration-files)

- [Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshot-restore.html)

GitLab Geo

GitLab Geo est susceptible d'être un composant essentiel de toute implémentation visant la conformité NIST 800-53. Il est important de consulter [la documentation disponible](../administration/geo/_index.md) pour s'assurer que Geo est configuré de manière appropriée pour chaque cas d'utilisation.

L'implémentation de Geo offre les avantages suivants :

- Réduire de plusieurs minutes à quelques secondes le temps nécessaire aux développeurs distribués pour cloner et récupérer des dépôts et des projets volumineux.

- Permettre aux développeurs de contribuer des idées et de travailler en parallèle, entre différentes régions.

- Équilibrer la charge en lecture seule entre les sites primaires et secondaires.

- Peut être utilisé pour cloner et récupérer des projets, en plus de lire toutes les données disponibles dans l'interface web de GitLab (voir les limitations).

- Permet de surmonter les connexions lentes entre des bureaux distants, en gagnant du temps grâce à l'amélioration de la vitesse pour les équipes distribuées.

- Contribue à réduire le temps de chargement pour les tâches automatisées, les intégrations personnalisées et les workflows internes.

- Peut rapidement basculer vers un site secondaire dans un scénario de reprise après sinistre.

- Permet un basculement planifié vers un site secondaire.

Geo offre les fonctionnalités principales suivantes :

- Sites secondaires en lecture seule : maintenir un site GitLab primaire tout en permettant des sites secondaires en lecture seule pour les équipes distribuées.

- Hooks du système d'authentification : les sites secondaires reçoivent toutes les données d'authentification (comme les comptes utilisateurs et les connexions) depuis l'instance primaire.

- Une interface utilisateur intuitive : les sites secondaires utilisent la même interface web que le site primaire. De plus, des notifications visuelles bloquent les opérations d'écriture et indiquent clairement qu'un utilisateur se trouve sur un site secondaire.

Ressources Geo supplémentaires :

- [Configuration de Geo](../administration/geo/setup/_index.md)

- [Prérequis pour l'exécution de Geo](../administration/geo/_index.md#requirements-for-running-geo)

- [Limitations de Geo](../administration/geo/_index.md)

- [Étapes de reprise après sinistre avec Geo](../administration/geo/disaster_recovery/_index.md)

**PostgreSQL**

GitLab fournit des [recommandations sur la configuration de clusters PostgreSQL avec réplication et basculement](../administration/postgresql/replication_and_failover.md). En fonction de la criticité des données et du temps d'arrêt maximal tolérable pour l'instance GitLab, envisagez de configurer PostgreSQL avec la réplication et le basculement activés.

**Gitaly**

Lors de la configuration de Gitaly, tenez compte des compromis entre disponibilité, récupérabilité et résilience. GitLab fournit une documentation complète sur les [capacités de Gitaly](../administration/gitaly/gitaly_geo_capabilities.md) qui devrait aider à déterminer la configuration correcte pour satisfaire aux exigences NIST 800-53.

### Planification (PL) {#planning-pl}

La famille de contrôles de planification comprend la maintenance des politiques, des procédures et d'autres documents contrôlés. Envisagez d'utiliser GitLab pour gérer le cycle de vie des documents contrôlés. Par exemple, les documents contrôlés peuvent être stockés en [Markdown](../user/markdown.md) dans un état versionné. Toute modification des documents doit être effectuée via des merge requests, qui appliquent les règles d'approbation de l'organisation. Les merge requests fournissent un historique clair des modifications apportées à un document contrôlé, que vous pouvez utiliser lors d'un audit pour démontrer les revues annuelles et les approbations par le personnel approprié, comme les propriétaires de documents.

### Évaluation des risques et intégrité du système et des informations (RA) {#risk-assessment-and-system-and-information-integrity-ra}

#### Analyse {#scanning}

NIST 800-53 exige une surveillance continue des vulnérabilités et une remédiation des failles. En plus de l'analyse de l'infrastructure, des cadres de conformité comme FedRAMP ont intégré les conteneurs et les analyses DAST dans les exigences de reporting mensuel. GitLab fournit des [outils de sécurité prenant en charge l'analyse des conteneurs](../user/application_security/container_scanning/_index.md), notamment les scanners [Trivy](https://github.com/aquasecurity/trivy) et [Grype](https://github.com/anchore/grype). De plus, GitLab fournit des [fonctionnalités d'analyse des dépendances](../user/application_security/dependency_scanning/_index.md). Le DAST dans GitLab peut être utilisé pour satisfaire aux exigences d'analyse des applications web. [GitLab DAST](../user/application_security/dast/_index.md) peut être configuré pour s'exécuter dans un pipeline et produire des rapports de vulnérabilités pour les applications web en cours d'exécution.

Les fonctionnalités de sécurité supplémentaires pouvant être utilisées pour sécuriser et gérer le code d'application incluent :

- [Test statique de sécurité des applications (SAST)](../user/application_security/sast/_index.md)

- [Détection des secrets](../user/application_security/secret_detection/_index.md)

- [Sécurité des API](../user/application_security/api_security/_index.md)

#### Gestion des correctifs {#patch-management}

GitLab documente sa [politique de release et de maintenance](../policy/maintenance.md) dans la documentation. Avant de mettre à niveau une instance GitLab, consultez les recommandations disponibles, qui peuvent aider à la [planification d'une mise à niveau](../update/plan_your_upgrade.md), à la [mise à niveau sans temps d'arrêt](../update/zero_downtime.md), et à d'autres [chemins de mise à niveau](../update/upgrade_paths.md).

Les [tableaux de bord de sécurité](../user/application_security/security_dashboard/_index.md) peuvent être configurés pour suivre les données de vulnérabilités dans le temps, ce qui vous permet d'identifier les tendances dans les programmes de gestion des vulnérabilités.

### Gestion des risques de la chaîne d'approvisionnement (SR) {#supply-chain-risk-management-sr}

#### Software Bill of Materials {#software-bill-of-materials}

Les scanners de dépendances et de conteneurs GitLab prennent en charge la génération de SBOMs. L'activation des rapports SBOM dans l'analyse des conteneurs et des dépendances peut permettre aux organisations clientes de comprendre leur chaîne d'approvisionnement logicielle et les risques inhérents associés aux composants logiciels. Les scanners GitLab [prennent en charge les rapports au format CycloneDX](../ci/yaml/artifacts_reports.md#artifactsreportsdotenv).

### Protection des systèmes et des communications (SC) {#system-and-communication-protection-sc}

#### Conformité FIPS {#fips-compliance}

Les programmes de conformité basés sur NIST 800-53, tels que FedRAMP, exigent la conformité FIPS pour tous les modules cryptographiques applicables. GitLab a publié des versions FIPS de ses images de conteneurs et fournit des recommandations sur la façon de configurer GitLab pour satisfaire aux normes de conformité FIPS. Certaines fonctionnalités ne sont pas disponibles ou prises en charge en mode FIPS.

Bien que GitLab fournisse des images conformes FIPS, il est de la responsabilité du client de configurer l'infrastructure sous-jacente et d'évaluer l'environnement pour confirmer que les chiffrements validés FIPS sont appliqués.

### Intégrité du système et des informations (SI) {#system-and-information-integrity-si}

#### Alertes de sécurité, avis et directives {#security-alerts-advisories-and-directives}

GitLab maintient une [base de données d'avis](../user/application_security/gitlab_advisory_database/_index.md) pour le suivi des vulnérabilités de sécurité liées aux logiciels et aux dépendances. GitLab est une autorité de numérotation CVE (CNA). Consultez cette page pour générer des [demandes d'identifiant CVE](../user/application_security/cve_id_request.md).

#### E-mail {#email}

GitLab prend en charge l'[envoi de notifications par e-mail](../administration/email_from_gitlab.md#sending-emails-to-users-from-gitlab) aux utilisateurs depuis l'instance de l'application GitLab. Les recommandations DHS BOD 18-01 indiquent que l'authentification des messages basée sur le domaine, le reporting et la conformité (DMARC) doivent être configurés pour les messages sortants comme protection anti-spam. GitLab fournit des [recommandations de configuration pour SMTP](https://docs.gitlab.com/omnibus/settings/smtp/) pour un large éventail de fournisseurs de messagerie, qui peuvent être utilisées pour aider à satisfaire cette exigence.

### Autres services et concepts {#other-services-and-concepts}

#### Runners {#runners}

Les runners sont requis pour un large éventail de tâches et d'outils dans tout déploiement GitLab. Pour maintenir les exigences de périmètre des données, les clients peuvent avoir besoin de déployer des [runners auto-gérés](https://docs.gitlab.com/runner/) dans leur périmètre d'autorisation. GitLab fournit des informations détaillées sur la [configuration des runners](../ci/runners/configure_runners.md), qui comprend des concepts tels que :

- Délais d'expiration maximum des jobs

- Protection des informations sensibles

- Configuration du long polling

- Sécurité des jetons d'authentification et rotation des jetons

- Prévention de la divulgation d'informations sensibles

- Variables de runner

#### Utilisation des API {#leveraging-apis}

GitLab fournit un ensemble complet d'API pour prendre en charge l'application, notamment les API [REST](../api/rest/_index.md) et [GraphQL](../api/graphql/_index.md). La sécurisation des API commence par la configuration appropriée de l'authentification pour les utilisateurs et les jobs appelant les points de terminaison API. GitLab recommande de configurer des jetons d'accès (les jetons d'accès personnels ne sont pas pris en charge par FIPS) et des jetons OAuth 2.0 pour contrôler l'accès.

#### Extensions {#extensions}

Les [extensions](../editor_extensions/_index.md) peuvent satisfaire aux exigences NIST 800-53 selon les intégrations établies. Les extensions d'éditeur et d'IDE, par exemple, peuvent être admissibles, tandis que les intégrations avec des tiers peuvent violer les exigences de périmètre d'autorisation. Il est de la responsabilité du client de valider toutes les extensions pour comprendre où les données sont envoyées en dehors du périmètre d'autorisation du client.

### Ressources supplémentaires {#additional-resources}

GitLab fournit un [guide de renforcement](hardening.md) pour les clients GitLab Self-Managed couvrant des sujets tels que :

- [Recommandations de renforcement des applications](hardening_application_recommendations.md)

- [Recommandations de renforcement CI/CD](hardening_cicd_recommendations.md)

- [Recommandations de configuration](hardening_configuration_recommendations.md)

- [Recommandations relatives au système d'exploitation](hardening_operating_system_recommendations.md)

Guide CIS Benchmark GitLab - GitLab a publié un [CIS Benchmark](https://about.gitlab.com/blog/gitlab-introduces-new-cis-benchmark-for-improved-security/) pour guider les décisions de renforcement dans l'application. Il peut être utilisé conjointement avec ce guide pour renforcer l'environnement conformément aux contrôles NIST 800-53. Toutes les suggestions du CIS Benchmark ne correspondent pas directement aux contrôles NIST 800-53, mais elles servent de bonnes pratiques pour la maintenance d'une instance GitLab.
