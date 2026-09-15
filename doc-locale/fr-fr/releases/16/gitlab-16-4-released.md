---
stage: Release Notes
group: Monthly Release
date: 2023-09-22
title: "Notes de release de GitLab 16.4"
description: "GitLab 16.4 est disponible avec des rôles personnalisables"
---

<!-- markdownlint-disable -->
<!-- vale off -->

Le 22 septembre 2023, GitLab 16.4 a été publié avec les fonctionnalités suivantes.

Nous souhaitons également remercier tous nos contributeurs, dont le contributeur remarquable de ce mois-ci.

## Contributeur notable du mois : Kik {#this-months-notable-contributor-kik}

Kik a joué un rôle déterminant dans la conception et le lancement de l'implémentation de la prise en charge d'ActivityPub dans GitLab. Son plan d'architecture original, extrêmement détaillé, a été adopté par notre équipe produit et existe désormais [sous la forme d'un epic](https://gitlab.com/groups/gitlab-org/-/epics/11247) dans le projet GitLab. La [première merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127023) implémentant ce code a récemment été fusionnée, suivie d'un [ajout à la documentation](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130960).

À mesure que le soutien à cette grande fonctionnalité se développe, Kik s'est révélé être une incarnation des [valeurs GitLab](https://handbook.gitlab.com/handbook/values/) que sont la collaboration, l'itération et la transparence !

Kik fait partie de la communauté GitLab depuis de nombreuses années, ayant soumis son [premier ticket](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/4037#note_4651432) il y a plus de 7 ans. Il a choisi de devenir un peu plus actif au cours des derniers mois. Interrogé sur ses contributions, il a déclaré :

> S'il y a quelque chose à souligner, c'est probablement à quel point GitLab est habilitant : il permet de voir son code source et de l'explorer, tout en étant ouvert aux contributions, quelle que soit leur ambition. :)

Il a également choisi de contribuer à nos efforts en matière de durabilité en optant pour la [plantation d'arbres](https://tree-nation.com/trees/view/5119567) en son nom plutôt que pour des goodies. 🌳

Merci, Kik, d'avoir choisi de contribuer à la construction de GitLab et de faire partie de notre formidable communauté ! 🙌

## Fonctionnalités principales {#primary-features}

### Rôles personnalisables {#customizable-roles}

<!-- categories: User Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/permissions.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/393235)

{{< /details >}}

Les propriétaires de groupe ou les administrateurs peuvent désormais créer et supprimer des rôles personnalisés via l'interface utilisateur, dans le menu Rôles et autorisations. Pour créer un rôle personnalisé, vous ajoutez des [autorisations](../../user/permissions.md) par-dessus un [rôle par défaut](../../user/permissions.md#roles) existant. Actuellement, le nombre d'autorisations pouvant être ajoutées à un rôle par défaut est limité, notamment les [autorisations de sécurité granulaires](https://docs.gitlab.com/#granular-security-permissions), la capacité d'approuver des merge requests et de consulter le code. À chaque jalon, de nouvelles autorisations seront publiées, qui pourront ensuite être ajoutées aux autorisations existantes pour créer des rôles personnalisés.

### Créer des workspaces pour des projets privés {#create-workspaces-for-private-projects}

<!-- categories: Workspaces -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/workspace/_index.md#personal-access-token)

{{< /details >}}

Auparavant, il n'était pas possible de [créer un workspace](../../user/workspace/configuration.md) pour un projet privé. Pour cloner un projet privé, vous ne pouviez vous authentifier qu'après avoir créé le workspace.

Avec GitLab 16.4, vous pouvez créer un workspace pour n'importe quel projet public ou privé. Lorsque vous créez un workspace, vous obtenez un jeton d'accès personnel à utiliser avec le workspace. Avec ce jeton, vous pouvez cloner des projets privés et effectuer des opérations Git sans configuration ni authentification supplémentaire.

### Accéder aux clusters localement en utilisant votre identité d'utilisateur GitLab {#access-clusters-locally-using-your-gitlab-user-identity}

<!-- categories: Environment Management, User Profile -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/clusters/agent/user_access.md#access-a-cluster-with-the-kubernetes-api) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/11235)

{{< /details >}}

Accorder aux équipes de développement l'accès aux clusters Kubernetes nécessite soit des comptes cloud de développement, soit des outils d'authentification tiers. Cela accroît la complexité de la gestion des identités et des accès dans le cloud. Désormais, vous pouvez accorder aux équipes de développement l'accès aux clusters Kubernetes en utilisant uniquement leurs identités GitLab et l'agent pour Kubernetes. Utilisez le RBAC Kubernetes standard pour gérer les autorisations au sein de votre cluster.

Conjointement avec l'offre d'[authentification cloud OIDC](../../ci/cloud_services/_index.md) dans les pipelines GitLab, ces fonctionnalités permettent aux utilisateurs GitLab d'accéder aux ressources cloud sans comptes cloud dédiés, sans compromettre la sécurité et la conformité.

Dans cette première itération d'accès aux clusters, vous devez [gérer votre configuration Kubernetes manuellement](../../user/clusters/agent/user_access.md). L'[epic 11455](https://gitlab.com/groups/gitlab-org/-/epics/11455) propose de simplifier la configuration en étendant la CLI GitLab avec des commandes associées.

### Liste des dépendances au niveau groupe/sous-groupe {#groupsub-group-level-dependency-list}

<!-- categories: Dependency Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dependency_list/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/8090)

{{< /details >}}

Lors de la revue d'une liste de dépendances, il est important d'avoir une vue d'ensemble. La gestion des dépendances au niveau projet est problématique pour les grandes organisations qui souhaitent auditer leurs dépendances sur l'ensemble de leurs projets. Avec cette release, vous pouvez voir toutes les dépendances au niveau projet ou groupe, y compris les sous-groupes. Cette fonctionnalité est désormais disponible par défaut.

### Mises à jour groupées du statut des vulnérabilités {#vulnerability-bulk-status-updates}

<!-- categories: Vulnerability Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/vulnerability_report/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/4649)

{{< /details >}}

Certaines vulnérabilités doivent être traitées en masse. Qu'il s'agisse de faux positifs ou de vulnérabilités qui ne sont plus détectées, il est important de réduire le bruit et de trier les vulnérabilités facilement. Avec cette release, vous pouvez modifier le statut en masse et ajouter un commentaire pour plusieurs vulnérabilités depuis un rapport de vulnérabilités de groupe ou de projet.

### Autorisations de sécurité granulaires {#granular-security-permissions}

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/permissions.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/10684)

{{< /details >}}

Certaines organisations souhaitent accorder à leurs équipes de sécurité le niveau d'accès minimum nécessaire afin de respecter le [principe du moindre privilège](https://en.wikipedia.org/wiki/Principle_of_least_privilege). Les équipes de sécurité ne doivent pas avoir accès à l'écriture de mises à jour de code, mais elles doivent pouvoir approuver les merge requests, consulter les vulnérabilités et mettre à jour le statut d'une vulnérabilité.

GitLab permet désormais aux utilisateurs de [créer un rôle personnalisé](../../user/permissions.md) basé sur l'accès du rôle [Reporter](../../user/permissions.md), mais avec les autorisations supplémentaires suivantes :

- Consultation de la liste des dépendances (`read_dependency`).
- Consultation du tableau de bord de sécurité et du rapport de vulnérabilités (`read_vulnerability`).
- Approbation d'une merge request (`admin_merge_request`).
- Modification du statut d'une vulnérabilité (`admin_vulnerability`).

Nous prévoyons de supprimer la capacité de modifier le statut d'une vulnérabilité depuis le rôle Developer pour toutes les éditions dans la version 17.0, comme indiqué dans cette [entrée de dépréciation](../../update/deprecations.md#deprecate-change-vulnerability-status-from-the-developer-role). Les retours sur ce changement proposé peuvent être partagés dans le [ticket 424688](https://gitlab.com/gitlab-org/gitlab/-/issues/424668).

### Prise en charge du fast-forward merge pour les merge trains {#fast-forward-merge-support-for-merge-trains}

<!-- categories: Merge Trains -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/pipelines/merge_trains.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/4911)

{{< /details >}}

Le [fast-forward merge](../../user/project/merge_requests/methods/_index.md#fast-forward-merge) est une méthode de fusion courante et populaire qui évite les commits de fusion, mais nécessite davantage de rebasage. Par ailleurs, les merge trains sont un outil puissant pour relever certains des défis majeurs liés aux fusions fréquentes dans la branche principale. Malheureusement, avant cette release, il n'était pas possible d'utiliser conjointement les merge trains et le fast-forward merge.

Dans cette release, les administrateurs self-managed peuvent désormais activer à la fois le fast-forward merge et les merge trains dans le même projet. Vous pouvez bénéficier de tous les avantages des merge trains, qui garantissent que tous vos commits fonctionnent ensemble avant la fusion, avec l'historique de commits plus propre des fast-forward merges !

Pour activer les merge trains avec fast-forward merge, localisez le feature flag `fast_forward_merge_trains_support`, qui est désactivé par défaut, et activez-le.

### Définir `id_token` globalement et éliminer la configuration pour les jobs individuels {#set-id_token-globally-and-eliminate-configuration-for-individual-jobs}

<!-- categories: Secrets Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/yaml/_index.md#id_tokens) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/419750)

{{< /details >}}

Dans GitLab 15.9, nous avons annoncé la [dépréciation des anciennes versions des jetons web JSON](../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated) au profit de `id_token`. Malheureusement, les jobs devaient être modifiés individuellement pour tenir compte de ce changement. Pour permettre une transition en douceur vers `id_token`, à partir de GitLab 16.4, vous pouvez définir `id_tokens` comme valeur par défaut globale dans `.gitlab-ci.yml`. Cette fonctionnalité configure automatiquement `id_token` pour chaque job. Les jobs utilisant l'authentification OpenID Connect (OIDC) ne nécessitent plus la configuration d'un `id_token` distinct.

[Utiliser `id_token` et OIDC pour s'authentifier auprès de services tiers](../../ci/secrets/id_token_authentication.md). Le sous-mot-clé obligatoire `aud` est utilisé pour configurer la revendication `aud` pour le JWT.

## Mise à l'échelle et déploiements {#scale-and-deployments}

### L'intégrité de l'index Elasticsearch est désormais en disponibilité générale {#elasticsearch-index-integrity-now-generally-available}

<!-- categories: Global Search -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../integration/advanced_search/elasticsearch.md#index-integrity) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/214601)

{{< /details >}}

Avec GitLab 16.4, l'intégrité de l'index Elasticsearch est en disponibilité générale pour tous les utilisateurs GitLab. L'intégrité de l'index permet de détecter et de corriger les données de dépôt manquantes. Cette fonctionnalité est automatiquement utilisée lorsque les recherches de code dont la portée est limitée à un groupe ou un projet ne retournent aucun résultat.

### Améliorations Omnibus {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- GitLab 16.4 inclut des paquets pour [OpenSUSE 15.5](https://en.opensuse.org/Release_announcement_15.5).

### Ajouter des webhooks pour les réactions emoji ajoutées ou révoquées {#add-webhooks-for-added-or-revoked-emoji-reactions}

<!-- categories: Notifications -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/integrations/webhook_events.md#emoji-events) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/290773)

{{< /details >}}

Afin d'offrir le plus grand nombre possible d'opportunités d'automatisation et d'intégration avec des systèmes tiers, nous avons ajouté la prise en charge de la création de webhooks qui se déclenchent lorsqu'un utilisateur ajoute ou révoque une réaction emoji.

Vous pourriez utiliser le nouveau webhook, par exemple, pour envoyer un e-mail lorsque des utilisateurs réagissent à des tickets ou des merge requests avec des emoji.

### Créer un nom et une description de rôle personnalisé via l'API {#create-custom-role-name-and-description-using-api}

<!-- categories: System Access -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/member_roles.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/416751)

{{< /details >}}

Lors de la création d'un rôle personnalisé, vous pouvez désormais utiliser l'API des rôles de membre pour ajouter un nom (obligatoire) et une description (facultative). Le nom `Custom` a été attribué à tous les rôles personnalisés existants, et vous pouvez utiliser l'API pour modifier le nom d'un rôle personnalisé selon votre choix.

### Déclencher des notifications Slack pour les mentions de groupe {#trigger-slack-notifications-for-group-mentions}

<!-- categories: Settings -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/integrations/gitlab_slack_application.md#trigger-notifications-for-group-mentions) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/417751)

{{< /details >}}

GitLab peut envoyer des messages aux canaux Slack pour certains événements GitLab. Avec cette release, vous pouvez désormais déclencher des [notifications Slack](../../user/project/integrations/gitlab_slack_application.md#notification-events) pour les mentions de groupe dans des contextes publics et privés dans :

- Descriptions des tickets et des merge requests
- Commentaires sur les tickets, les merge requests et les commits

### Étendre les limites d'importation configurables disponibles dans les paramètres de l'application {#expand-configurable-import-limits-available-in-application-settings}

<!-- categories: Importers -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/settings/import_and_export_settings.md#timeout-for-decompressing-archived-files) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/421432)

{{< /details >}}

Nous avons récemment transformé quelques limites d'importation codées en dur en paramètres d'application configurables afin de permettre aux administrateurs GitLab self-managed d'ajuster ces limites selon leurs besoins.

Dans cette release, nous avons ajouté le délai d'expiration pour la décompression des fichiers archivés en tant que paramètre d'application configurable.

Cette limite était codée en dur à 210 secondes. Sur GitLab.com, et pour les installations self-managed par défaut, nous avons défini cette limite à 210 secondes. Les administrateurs GitLab self-managed et GitLab.com peuvent ajuster cette limite selon leurs besoins.

### Adresse e-mail personnalisée pour Service Desk {#custom-email-address-for-service-desk}

<!-- categories: Service Desk -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/project/service_desk/configure.md#custom-email-address) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/329990)

{{< /details >}}

Service Desk est l'un des liens les plus importants entre votre entreprise et vos clients. Vous pouvez désormais utiliser votre propre adresse e-mail personnalisée pour envoyer et recevoir des e-mails via Service Desk. Grâce à ce changement, il est beaucoup plus facile de maintenir l'identité de marque et d'instaurer la confiance des clients quant à l'entité avec laquelle ils communiquent.

Cette fonctionnalité est en version bêta. Nous encourageons les utilisateurs à essayer les fonctionnalités en version bêta et à fournir leurs retours dans [le ticket de retours](https://gitlab.com/gitlab-org/gitlab/-/issues/416637).

### Geo prend en charge les URL unifiées sur les sites Cloud Native Hybrid {#geo-supports-unified-urls-on-cloud-native-hybrid-sites}

<!-- categories: Disaster Recovery, Geo Replication -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/geo/secondary_proxy/_index.md#set-up-a-unified-url-for-geo-sites) \| [Epic associé](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3522)

{{< /details >}}

Geo prend désormais en charge les URL unifiées sur les sites [Cloud Native Hybrid](../../administration/reference_architectures/_index.md#cloud-native-hybrid), ce qui signifie que les sites Cloud Native Hybrid peuvent partager une seule URL externe avec le site primaire. Cela offre une expérience GitLab UI et Git développeur fluide pour vos équipes distantes, qui peuvent être automatiquement dirigées vers le site secondaire Geo optimal en fonction de leur localisation, grâce à une seule URL commune. Avec cette mise à jour, les URL unifiées sont désormais prises en charge sur toutes les architectures de référence GitLab.

### Geo vérifie le stockage d'objets {#geo-verifies-object-storage}

<!-- categories: Geo Replication, Disaster Recovery -->

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../administration/geo/replication/object_storage.md) \| [Ticket associé](https://gitlab.com/groups/gitlab-org/-/epics/8056)

{{< /details >}}

Geo ajoute la capacité de vérifier le stockage d'objets lorsque la [réplication du stockage d'objets est gérée par GitLab](../../administration/geo/replication/object_storage.md#enabling-gitlab-managed-object-storage-replication). Pour protéger vos données de stockage d'objets contre la corruption, Geo compare la taille des fichiers entre les sites primaire et secondaires. Si Geo fait partie de votre stratégie de reprise après sinistre et que vous activez la réplication du stockage d'objets gérée par GitLab, cela vous protège contre la perte de données. De plus, cela réduit également la nécessité de copier des données pouvant déjà être présentes sur un site secondaire. Par exemple, lors de l'ajout d'un ancien site primaire en tant que site secondaire.

## DevOps et sécurité unifiés {#unified-devops-and-security}

### Prise en charge du mot-clé `environment` dans les pipelines downstream {#support-for-environment-keyword-in-downstream-pipelines}

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../ci/pipelines/downstream_pipelines.md#downstream-pipelines-for-deployments) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/369061)

{{< /details >}}

Si vous avez besoin de déclencher un pipeline downstream depuis un job de pipeline CI/CD, vous pouvez utiliser le mot-clé `trigger`. Pour améliorer la gestion de vos déploiements, vous pouvez désormais spécifier un environnement avec le mot-clé `environment` lorsque vous utilisez `trigger`. Par exemple, vous pourriez déclencher un pipeline downstream pour la branche `main` sur votre projet `/web-app` avec le nom d'environnement `dev` et une URL d'environnement spécifiée.

Auparavant, lorsque vous exécutiez des pipelines séparés pour la CI et la CD et utilisiez le mot-clé `trigger` pour démarrer le pipeline CD, il n'était pas possible de spécifier des détails d'environnement. Cela rendait difficile le suivi des déploiements depuis votre projet CI. L'ajout de la prise en charge des environnements simplifie le suivi des déploiements entre les projets.

### Autoriser les utilisateurs à définir des exceptions de branche aux politiques de sécurité appliquées {#allow-users-to-define-branch-exceptions-to-enforced-security-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/policies/_index.md) \| [Epic associé](https://gitlab.com/groups/gitlab-org/-/epics/9567)

{{< /details >}}

Les politiques de sécurité imposent l'exécution de scanners dans les projets GitLab, ainsi que des vérifications/approbations de merge requests pour garantir la sécurité et la conformité. Grâce aux exceptions de branche, vous pouvez appliquer les politiques de manière plus granulaire et exclure l'application pour toute branche hors portée. Si un développeur crée une branche de développement ou de test affectée involontairement par une application trop stricte, il peut collaborer avec les équipes de sécurité pour exempter la branche au sein de la politique de sécurité.

Pour les politiques d'exécution de scan, vous pouvez configurer des exceptions pour le type de règle [pipeline](../../user/application_security/policies/scan_execution_policies.md#pipeline-rule-type) ou [schedule](../../user/application_security/policies/scan_execution_policies.md#schedule-rule-type). Pour les politiques de résultat de scan, vous pouvez spécifier des exceptions de branche pour le type de règle [scan_finding](../../user/application_security/policies/merge_request_approval_policies.md#scan_finding-rule-type) ou [license_finding](../../user/application_security/policies/merge_request_approval_policies.md#license_finding-rule-type).

### Notifications pour les jetons d'accès arrivant à expiration {#notifications-for-expiring-access-tokens}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../security/tokens/_index.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/367705)

{{< /details >}}

Les jetons d'accès de groupe et de projet sont fréquemment utilisés pour l'automatisation. Il est important que les administrateurs et les propriétaires de groupe soient notifiés lorsque l'un de ces jetons est proche de son expiration, afin d'éviter toute interruption. Les administrateurs et les propriétaires de groupe reçoivent désormais un e-mail de notification lorsqu'un jeton expire dans sept jours ou moins.

### Notification par e-mail à l'expiration de l'accès {#email-notification-when-access-expires}

<!-- categories: System Access -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/group/_index.md#add-users-to-a-group) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/12704)

{{< /details >}}

Un utilisateur recevra une notification par e-mail sept jours avant l'expiration de son accès au groupe ou au projet. Cela ne s'applique que si une date d'expiration d'accès est définie. Auparavant, aucune notification n'était envoyée lorsque l'accès expirait. Un préavis vous permet de contacter votre administrateur GitLab pour garantir un accès continu.

### La vérification active 22.1 du DAST basé sur navigateur est activée par défaut {#browser-based-dast-active-check-221-is-enabled-by-default}

<!-- categories: DAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dast/browser/checks/_index.md#active-checks) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/392718)

{{< /details >}}

La vérification active 22.1 du DAST basé sur navigateur a été activée par défaut. Elle remplace la vérification ZAP 6, qui a été désactivée. La vérification 22.1 identifie la « Limitation incorrecte d'un chemin d'accès à un répertoire restreint (Path traversal) », qui peut être exploitée en insérant une charge utile dans un paramètre du point de terminaison URL, permettant ainsi la lecture de fichiers arbitraires.

### Prise en charge des registres privés pour l'analyse opérationnelle des conteneurs {#private-registry-support-for-operational-container-scanning}

<!-- categories: Container Scanning -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/clusters/agent/vulnerabilities.md#scanning-private-images) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/415451)

{{< /details >}}

L'[analyse opérationnelle des conteneurs](../../user/clusters/agent/vulnerabilities.md) peut désormais accéder et analyser les images provenant de registres de conteneurs privés. OCS utilise les secrets d'extraction d'images pour accéder aux conteneurs du registre privé.

### Prise en charge de l'analyse des dépendances et des licences pour le lockfile pnpm v6.1 {#dependency-and-license-scanning-support-for-pnpm-lockfile-v61}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/413903)

{{< /details >}}

Grâce à une contribution de la communauté de [Weyert de Boer](https://gitlab.com/weyert-tapico), l'analyse des dépendances et des licences GitLab prend désormais en charge l'analyse des projets pnpm utilisant le format de lockfile v6.1.

### Mises à jour des analyseurs SAST {#sast-analyzer-updates}

<!-- categories: SAST -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/analyzers.md) \| [Ticket associé](../../user/application_security/_index.md)

{{< /details >}}

Le SAST GitLab inclut [de nombreux analyseurs de sécurité](../../user/application_security/sast/_index.md#supported-languages-and-frameworks) que l'équipe d'analyse statique GitLab maintient, met à jour et prend en charge activement. Nous avons publié les mises à jour suivantes au cours du jalon de la release 16.4 :

- Mise à jour de l'analyseur basé sur KICS vers la version 1.7.7 du scanner KICS. Consultez le [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/kics/-/blob/main/CHANGELOG.md?ref_type=heads#v415) pour plus de détails.
- Mise à jour de l'analyseur basé sur Sobelow vers la version 0.13.0 du scanner Sobelow. Nous avons également mis à jour l'image de base de l'analyseur vers Elixir 1.13 afin d'améliorer la compatibilité avec les versions plus récentes d'Elixir. Consultez le [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow/-/blob/master/CHANGELOG.md?ref_type=heads#v421)
- Mise à jour de l'analyseur basé sur PMD Apex vers la version 6.55.0 du scanner PMD. Consultez le [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex/-/blob/master/CHANGELOG.md?ref_type=heads#v413) pour plus de détails.
- Modification de l'analyseur basé sur PHPCS Security Audit pour supprimer la règle `Security.Misc.IncludeMismatch`. Consultez le [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/phpcs-security-audit/-/blob/master/CHANGELOG.md?ref_type=heads#v411) pour plus de détails.
- Mise à jour des règles utilisées dans l'analyseur basé sur Semgrep pour corriger les erreurs de règles, réparer les liens brisés dans les descriptions de règles et résoudre les conflits entre les règles Java et Scala ayant les mêmes identifiants de règle. Nous avons également augmenté la taille maximale des fichiers de règles personnalisées à 10 Mo. Consultez le [CHANGELOG](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/CHANGELOG.md?ref_type=heads#v4412) pour plus de détails.

Si vous [incluez le modèle SAST géré par GitLab](../../user/application_security/sast/_index.md) ([`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)) et exécutez GitLab 16.0 ou une version supérieure, vous recevez automatiquement ces mises à jour. Pour rester sur une version spécifique d'un analyseur et empêcher les mises à jour automatiques, vous pouvez [épingler sa version](../../user/application_security/sast/_index.md).

Pour les modifications précédentes, consultez [les mises à jour du mois dernier](https://about.gitlab.com/releases/2023/08/22/gitlab-16-3-released/#sast-analyzer-updates).

### Amélioration du suivi des vulnérabilités SAST {#improved-sast-vulnerability-tracking}

<!-- categories: SAST -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/373921)

{{< /details >}}

Le [suivi avancé des vulnérabilités](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking) du SAST GitLab rend le triage plus efficace en assurant le suivi des résultats au fil des déplacements du code.

Dans GitLab 16.4, nous avons activé le suivi avancé des vulnérabilités pour de nouveaux langages et analyseurs. En plus de sa [couverture existante](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking), le suivi avancé est désormais disponible pour :

- Java, dans l'analyseur SAST basé sur SpotBugs.
- PHP, dans l'analyseur SAST basé sur PHPCS Security Audit.

Cela s'appuie sur les extensions et améliorations précédentes [publiées dans GitLab 16.3](https://about.gitlab.com/releases/2023/08/22/gitlab-16-3-released/#improved-sast-vulnerability-tracking). Nous suivons les améliorations supplémentaires dans l'[epic 5144](https://gitlab.com/groups/gitlab-org/-/epics/5144).

Ces modifications sont incluses dans les [versions mises à jour](https://docs.gitlab.com/#sast-analyzer-updates) des [analyseurs](../../user/application_security/sast/analyzers.md) SAST de GitLab. Les résultats de vulnérabilités de votre projet sont mis à jour avec de nouvelles signatures de suivi après que le projet a été scanné avec les analyseurs mis à jour. Vous n'avez pas à effectuer d'action pour recevoir cette mise à jour, sauf si vous avez [épinglé les analyseurs SAST à une version spécifique](../../user/application_security/sast/_index.md).

### Exports SBOM CycloneDX spécifiques aux pipelines {#pipeline-specific-cyclonedx-sbom-exports}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Liens : [Documentation](../../api/dependency_list_export.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/333463)

{{< /details >}}

Nous avons ajouté une API qui vous permet de télécharger un SBOM CycloneDX, qui répertorie tous les composants détectés dans un pipeline CI. Cela inclut à la fois les dépendances au niveau de l'application et les dépendances au niveau du système.

### Les utilisateurs avec le rôle Maintainer peuvent consulter les détails des runners {#users-with-the-maintainer-role-can-view-runner-details}

<!-- categories: Fleet Visibility -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](../../user/permissions.md) \| [Ticket associé](https://gitlab.com/gitlab-org/gitlab/-/issues/384179)

{{< /details >}}

Les utilisateurs disposant du rôle Maintainer pour un groupe peuvent désormais consulter les détails des runners de groupe. Les utilisateurs avec ce rôle peuvent consulter les runners de groupe pour déterminer rapidement quels runners sont disponibles, ou valider que les runners créés automatiquement ont bien été enregistrés dans l'espace de nommage du groupe.

### Image macOS 13 (Ventura) pour les runners SaaS sur macOS {#macos-13-ventura-image-for-saas-runners-on-macos}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- Édition : Silver, Gold
- Offre : GitLab.com
- Liens : [Documentation](../../ci/runners/hosted_runners/macos.md#supported-macos-images) \| [Ticket associé](https://gitlab.com/gitlab-org/ci-cd/shared-runners/infrastructure/-/issues/101)

{{< /details >}}

Les équipes peuvent désormais créer, tester et déployer en toute fluidité des applications pour l'écosystème Apple sur macOS 13.

Les runners SaaS sur macOS vous permettent d'accroître la vélocité de vos équipes de développement dans la création et le déploiement d'applications nécessitant macOS, dans un environnement de build GitLab Runner sécurisé et à la demande, intégré à GitLab CI/CD.

### GitLab Runner 16.4 {#gitlab-runner-164}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Liens : [Documentation](https://docs.gitlab.com/runner)

{{< /details >}}

Nous publions également GitLab Runner 16.4 aujourd'hui ! GitLab Runner est l'agent léger et hautement évolutif qui exécute vos jobs CI/CD et renvoie les résultats à une instance GitLab. GitLab Runner fonctionne en conjonction avec GitLab CI/CD, le service d'intégration continue open source inclus avec GitLab.

#### Nouveautés {#whats-new}

- [Ajout d'une métrique d'histogramme de durée de file d'attente au point de terminaison des métriques Prometheus du runner](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36627)

#### Corrections de bugs {#bug-fixes}

- [Les pods du runner Kubernetes ne sont pas nettoyés dans GitLab Runner 16.3.0](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36803)
- [`gitlab-runner-helper` interrompu pendant le téléchargement du cache](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27984)

La liste de toutes les modifications se trouve dans le [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-4-stable/CHANGELOG.md) de GitLab Runner.

## Sujets connexes {#related-topics}

- [Correctifs de bugs](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.4)
- [Améliorations des performances](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.4)
- [Améliorations de l'interface utilisateur](https://papercuts.gitlab.com/?milestone=16.4)
- [Dépréciations et suppressions](../../update/deprecations.md)
- [Notes de mise à niveau](../../update/versions/_index.md)
