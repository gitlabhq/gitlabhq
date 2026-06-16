---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Commencer avec GitLab Dedicated.
title: Administrer GitLab Dedicated
---

{{< details >}}

- Niveau : Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

Utilisez GitLab Dedicated pour exécuter GitLab sur une instance monolocataire entièrement gérée, hébergée sur AWS. Vous gardez le contrôle de la configuration de votre instance via Switchboard, le portail de gestion GitLab Dedicated, tandis que GitLab gère l'infrastructure sous-jacente.

Pour plus d'informations sur cette offre, consultez la [page d'abonnement](../../subscriptions/gitlab_dedicated/_index.md).

## Présentation de l'architecture {#architecture-overview}

GitLab Dedicated s'exécute sur une infrastructure sécurisée qui fournit :

- Un environnement de tenant entièrement isolé dans AWS
- Haute disponibilité avec basculement automatisé
- Reprise après sinistre géographique
- Mises à jour et maintenance régulières
- Contrôles de sécurité de niveau entreprise

Pour en savoir plus, consultez [l'architecture GitLab Dedicated](architecture.md).

## Configurer l'infrastructure {#configure-infrastructure}

| Fonctionnalité | Description | Configurer avec |
|------------|-------------|---------------------|
| [Régions de données AWS](create_instance/data_residency_high_availability.md#region-selection) | Vous choisissez les régions pour les opérations principales, la reprise après sinistre et la sauvegarde. GitLab réplique vos données dans ces régions. | Onboarding |
| [Fenêtres de maintenance](maintenance.md#maintenance-windows) | Vous sélectionnez une fenêtre de maintenance hebdomadaire de 4 heures. GitLab effectue les mises à jour, les changements de configuration et les correctifs de sécurité pendant cette période. | Onboarding |
| [Gestion des releases](releases.md#release-rollout-schedule) | GitLab met à jour votre instance mensuellement avec de nouvelles fonctionnalités et des correctifs de sécurité. | Disponible par <br>Par défaut |
| [Reprise après sinistre Geo](disaster_recovery.md) | Vous choisissez la région secondaire lors de l'onboarding. GitLab maintient un site secondaire répliqué dans la région choisie à l'aide de Geo. | Onboarding |
| [Sauvegardes automatisées](disaster_recovery.md#automated-backups) | GitLab sauvegarde vos données dans la région AWS de votre choix. | Disponible par <br>Par défaut |

## Sécuriser votre instance {#secure-your-instance}

| Fonctionnalité | Description | Configurer avec |
|------------|-------------|-----------------|
| [Chiffrement des données](encryption.md) | GitLab chiffre vos données au repos et en transit via l'infrastructure fournie par AWS. | Disponible par <br>Par défaut |
| [Clés de chiffrement gérées par le client](encryption.md#customer-managed-encryption) | Vous pouvez fournir vos propres clés AWS KMS pour le chiffrement au lieu d'utiliser les clés AWS KMS gérées par GitLab. GitLab intègre ces clés à votre instance pour chiffrer les données au repos. | Onboarding |
| [GitLab SAML SSO](configure_instance/authentication/saml.md) | Vous configurez la connexion à vos fournisseurs d'identité SAML. GitLab gère le flux d'authentification. | Switchboard |
| [Liste d'autorisation IP](configure_instance/network_security.md#ip-allowlist) | Vous spécifiez les adresses IP approuvées. GitLab bloque les tentatives d'accès non autorisées. | Switchboard |
| [Autorités de certification personnalisées](configure_instance/network_security.md#custom-certificate-authorities-for-external-services) | Vous importez vos certificats SSL. GitLab maintient des connexions sécurisées à vos services privés. | Switchboard |
| [Cadres de conformité](../../subscriptions/gitlab_dedicated/_index.md#monitoring) | GitLab maintient la conformité avec SOC 2, ISO 27001 et d'autres cadres. Vous pouvez accéder aux rapports via le [Trust Center](https://trust.gitlab.com/?product=gitlab-dedicated). | Disponible par <br>Par défaut |
| [Protocoles d'accès d'urgence](../../subscriptions/gitlab_dedicated/_index.md#access-controls) | GitLab fournit des procédures de break-glass contrôlées pour les situations urgentes. | Disponible par <br>Par défaut |

## Configurer le réseau {#set-up-networking}

| Fonctionnalité | Description | Configurer avec |
|------------|-------------|-----------------|
| [Domaines personnalisés](configure_instance/network_security.md#custom-domains) | Vous fournissez un nom de domaine et configurez les enregistrements DNS. GitLab gère les certificats SSL via Let's Encrypt. | Ticket de support |
| [Connexions PrivateLink entrantes](configure_instance/network_security.md#inbound-privatelink-connections) | GitLab crée un service de point de terminaison. Vous créez des points de terminaison VPC dans votre compte AWS pour vous connecter à votre instance GitLab. | Switchboard |
| [Connexions PrivateLink sortantes](configure_instance/network_security.md#outbound-privatelink-connections) | Vous créez un service de point de terminaison dans votre compte AWS. GitLab crée des points de terminaison VPC pour se connecter à vos services. | Switchboard |
| [Zones hébergées privées](configure_instance/network_security.md#private-hosted-zones) | Vous définissez les exigences DNS internes. GitLab configure la résolution DNS dans le réseau de votre instance. | Switchboard |

## Utiliser les outils de la plateforme {#use-platform-tools}

| Fonctionnalité | Description | Configurer avec |
|------------|-------------|-----------------|
| [GitLab Pages](../../subscriptions/gitlab_dedicated/_index.md#gitlab-pages) | GitLab héberge vos sites web statiques sur un domaine dédié. Vous pouvez publier des sites depuis vos dépôts. | Disponible par <br>Par défaut |
| [Recherche avancée](../../integration/advanced_search/elasticsearch.md) | GitLab maintient l'infrastructure de recherche. Vous pouvez effectuer des recherches dans votre code, vos tickets et vos merge requests. | Disponible par <br>Par défaut |
| [Runners hébergés (bêta)](hosted_runners.md) | Vous achetez un abonnement et configurez vos runners hébergés. GitLab gère l'infrastructure CI/CD à mise à l'échelle automatique. | Switchboard |
| [ClickHouse](../../integration/clickhouse.md) | GitLab maintient l'infrastructure et l'intégration ClickHouse. Vous pouvez accéder à toutes les fonctionnalités analytiques avancées telles que [GitLab Duo et les tendances SDLC](../../user/analytics/duo_and_sdlc_trends.md) et [les analyses CI/CD](../../ci/runners/runner_fleet_dashboard.md). | Disponible par <br>défaut pour les [clients éligibles](../../subscriptions/gitlab_dedicated/_index.md#clickhouse-cloud) |

## Gérer les opérations quotidiennes {#manage-daily-operations}

| Fonctionnalité | Description | Configurer avec |
|------------|-------------|-----------------|
| [Journaux d'application](monitor.md) | GitLab envoie les journaux à votre compartiment AWS S3 pour la surveillance et le dépannage. Vous gérez les utilisateurs et les rôles qui peuvent accéder aux journaux. | Switchboard |
| [Service de messagerie](configure_instance/users_notifications.md#smtp-email-service) | GitLab fournit AWS SES par défaut pour envoyer des e-mails depuis votre instance GitLab Dedicated. Vous pouvez également configurer votre propre service de messagerie SMTP. | Ticket de support pour <br/>service personnalisé  |
| [Accès à Switchboard et <br>notifications](configure_instance/users_notifications.md) | Vous gérez les autorisations Switchboard et les paramètres de notification. GitLab maintient l'infrastructure Switchboard. | Switchboard |
| [SSO Switchboard](configure_instance/authentication/_index.md#configure-switchboard-sso) | Vous configurez le fournisseur d'identité de votre organisation et fournissez à GitLab les informations nécessaires. GitLab configure l'authentification unique (SSO) pour Switchboard. | Ticket de support |

## Commencer {#get-started}

Pour commencer avec GitLab Dedicated :

1. [Créez votre instance GitLab Dedicated](create_instance/_index.md).
1. [Configurez votre instance GitLab Dedicated](configure_instance/_index.md).
1. [Créez un runner hébergé](hosted_runners.md).
