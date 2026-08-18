---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Présentation de l'administration."
title: Commencer à administrer GitLab
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Commencez à utiliser l'administration GitLab. Configurez votre organisation et son authentification, puis sécurisez, surveillez et sauvegardez GitLab.

## Authentification {#authentication}

L'authentification est la première étape pour sécuriser votre installation.

- [Appliquer l'authentification à deux facteurs (2FA) pour tous les utilisateurs](../security/two_factor_authentication.md).
- Assurez-vous que les utilisateurs effectuent les opérations suivantes :
  - Choisissez un mot de passe fort et sécurisé. Si possible, stockez-le dans un système de gestion des mots de passe.
  - Si elle n'est pas configurée pour tout le monde, activez la [authentification à deux facteurs (2FA)](../user/profile/account/two_factor_authentication.md) pour votre compte. Ce code secret à usage unique est une mesure de protection supplémentaire qui empêche les intrus d'accéder à votre compte, même s'ils possèdent votre mot de passe.
  - Ajoutez une adresse e-mail de sauvegarde. Si vous perdez l'accès à votre compte, l'équipe d'assistance GitLab peut vous aider plus rapidement.
  - Enregistrez ou imprimez vos codes de récupération. Si vous ne pouvez pas accéder à votre appareil d'authentification, vous pouvez utiliser ces codes de récupération pour vous connecter à votre compte GitLab.
  - Ajoutez [une clé SSH](../user/ssh.md) à votre profil. Vous pouvez générer des codes de récupération selon vos besoins avec SSH.
  - Créez des [jetons d'accès personnels](../user/profile/personal_access_tokens.md). Lorsque vous utilisez la 2FA, vous pouvez utiliser ces jetons pour accéder à l'API GitLab.

## Projets et groupes {#projects-and-groups}

Organisez votre environnement en configurant vos groupes et vos projets.

- [Projets](../user/project/working_with_projects.md) : Désignez un emplacement pour vos fichiers et votre code, ou suivez et organisez les tickets dans une catégorie métier.
- [Groupes](../user/group/_index.md) : Organisez un ensemble d'utilisateurs ou de projets. Utilisez ces groupes pour affecter rapidement des personnes et des projets.
- [Rôles](../user/permissions.md) : Définissez l'accès des utilisateurs et la visibilité pour vos projets et groupes.

<i class="fa-youtube-play" aria-hidden="true"></i> Regardez une présentation des [groupes et projets](https://www.youtube.com/watch?v=cqb2m41At6s).

Commencer :

- Créez un [projet](../user/project/_index.md).
- Créez un [groupe](../user/group/_index.md#create-a-group).
- [Ajoutez des membres](../user/group/_index.md#add-users-to-a-group) au groupe.
- Créez un [sous-groupe](../user/group/subgroups/_index.md#create-a-subgroup).
- [Ajoutez des membres](../user/group/subgroups/_index.md#subgroup-membership) au sous-groupe.
- Activez le [contrôle d'autorisation externe](settings/external_authorization.md#configuration).

**Plus de ressources**

- [Exécutez plusieurs équipes Agile](https://www.youtube.com/watch?v=VR2r1TJCDew).
- [Synchronisez les appartenances aux groupes à l'aide de LDAP](auth/ldap/ldap_synchronization.md#group-sync).
- Gérez l'accès des utilisateurs avec des permissions héritées. Utilisez jusqu'à 20 niveaux de sous-groupes pour organiser à la fois les équipes et les projets.
  - [Appartenance héritée](../user/project/members/_index.md#membership-types).
  - [Exemple](../user/group/subgroups/_index.md).

## Importer des projets {#import-projects}

Il peut arriver que vous deviez importer des projets depuis des sources externes telles que GitHub, Bitbucket ou une autre instance de GitLab. De nombreuses sources externes peuvent être importées dans GitLab.

- Consultez la [documentation des projets GitLab](../user/project/_index.md).
- Envisagez le [mirroring de dépôt](../user/project/repository/mirror/_index.md), une [alternative aux migrations de projets](../ci/ci_cd_for_external_repos/_index.md).
- Consultez [importer et migrer vers GitLab](../user/import/_index.md) pour obtenir de la documentation sur les chemins de migration courants.
- Planifiez vos exports de projet avec notre [API d'import/export](../api/project_import_export.md#export-a-project).

### Importations de projets populaires {#popular-project-imports}

- [GitHub Enterprise vers GitLab Self-Managed](../integration/github.md)
- [Bitbucket Server](../user/import/bitbucket_server.md)

Pour obtenir de l'aide concernant ces types de données, contactez votre responsable de compte GitLab ou l'assistance GitLab au sujet de nos services de migration professionnels.

## Sécurité de l'instance GitLab {#gitlab-instance-security}

La sécurité est une partie importante du processus d'intégration. La sécurisation de votre instance protège votre travail et votre organisation.

Bien que cette liste ne soit pas exhaustive, suivre ces étapes vous donne un bon point de départ pour sécuriser votre instance.

- Utilisez un mot de passe root long, stocké dans un coffre-fort.
- Installez un certificat SSL de confiance et établissez un processus de renouvellement et de révocation.
- [Configurez les restrictions des clés SSH](../security/ssh_keys_restrictions.md) conformément aux directives de votre organisation.
- [Désactivez la création de nouveaux comptes utilisateur](settings/sign_up_restrictions.md#disable-new-user-account-creation).
- Exigez une confirmation par e-mail.
- Définissez une limite de longueur de mot de passe, configurez la gestion des utilisateurs SSO ou SAML.
- Limitez les domaines de messagerie si vous permettez aux nouveaux utilisateurs de créer des comptes.
- Exigez l'authentification à deux facteurs (2FA).
- Désactivez [l'authentification par mot de passe pour Git via HTTPS](settings/sign_in_restrictions.md#allow-password-authentication-for-git-over-https).
- Configurez les [notifications par e-mail pour les connexions inconnues](settings/sign_in_restrictions.md#email-notification-for-unknown-sign-ins).
- Configurez les [limites de débit par utilisateur et par IP](https://about.gitlab.com/blog/gitlab-instance-security-best-practices/#user-and-ip-rate-limits).
- Limitez [l'accès local aux webhooks](https://about.gitlab.com/blog/gitlab-instance-security-best-practices/#webhooks).
- Définissez des [limites de débit pour les chemins protégés](settings/protected_paths.md).
- Abonnez-vous aux [alertes de sécurité](https://about.gitlab.com/company/preference-center/) depuis le Centre de préférences de communication.
- Suivez les meilleures pratiques de sécurité sur notre [page de blog](https://about.gitlab.com/blog/gitlab-instance-security-best-practices/).

## Surveiller les performances de GitLab {#monitor-gitlab-performance}

Une fois que vous avez établi votre configuration de base, vous êtes prêt à examiner les services de surveillance de GitLab. Prometheus est notre outil principal de surveillance des performances. Contrairement à d'autres solutions de surveillance (par exemple, Zabbix ou New Relic), Prometheus est étroitement intégré à GitLab et bénéficie d'un vaste soutien de la communauté.

- [Prometheus](monitoring/prometheus/_index.md) capture [ces métriques GitLab](monitoring/prometheus/gitlab_metrics.md#metrics-available).
- En savoir plus sur les [métriques des logiciels intégrés](monitoring/prometheus/_index.md#bundled-software-metrics) de GitLab.
- Prometheus et ses exportateurs sont activés par défaut. Cependant, vous devez [configurer le service](monitoring/prometheus/_index.md#configuring-prometheus).
- Découvrez pourquoi les [métriques de performance des applications](https://about.gitlab.com/blog/working-with-performance-metrics/) sont importantes.
- Intégrez Grafana pour [créer des tableaux de bord visuels](https://youtu.be/f4R7s0An1qE) basés sur les métriques de performance.

### Composants de la surveillance {#components-of-monitoring}

- [Serveurs web](monitoring/prometheus/gitlab_metrics.md#puma-metrics) : Gère les requêtes serveur et facilite les autres transactions de services back-end. Surveillez le trafic CPU, mémoire et E/S réseau pour suivre l'état de santé de ce nœud.
- [Workhorse](monitoring/prometheus/gitlab_metrics.md#metrics-available) : Allège la congestion du trafic web provenant du serveur principal. Surveillez les pics de latence pour suivre l'état de santé de ce nœud.
- [Sidekiq](monitoring/prometheus/gitlab_metrics.md#sidekiq-metrics) : Gère les opérations en arrière-plan qui permettent à GitLab de fonctionner correctement. Surveillez les files d'attente de tâches longues non traitées pour suivre l'état de santé de ce nœud.

## Sauvegarder vos données GitLab {#back-up-your-gitlab-data}

GitLab fournit des méthodes de sauvegarde pour maintenir vos données en sécurité et récupérables.

- Choisissez une stratégie de sauvegarde.
- Envisagez d'écrire un job cron pour effectuer des sauvegardes quotidiennes.
- Sauvegardez séparément les fichiers de configuration.
- Décidez de ce qui doit être exclu de la sauvegarde.
- Décidez où téléverser les sauvegardes.
- Limitez la durée de vie des sauvegardes.
- Effectuez un test de sauvegarde et de restauration.
- Mettez en place un moyen de vérifier périodiquement les sauvegardes.

### Sauvegarder une instance {#back-up-an-instance}

La procédure diffère selon que vous avez déployé avec le package Linux ou le chart Helm.

Pour sauvegarder une installation à nœud unique utilisant le package Linux, vous pouvez utiliser une seule tâche Rake.

Découvrez comment [sauvegarder les variantes de package Linux ou Helm](backup_restore/_index.md). Ce processus sauvegarde l'intégralité de votre instance, mais ne sauvegarde pas les fichiers de configuration. Assurez-vous que ceux-ci sont sauvegardés séparément. Conservez vos fichiers de configuration et archives de sauvegarde dans un emplacement séparé pour vous assurer que les clés de chiffrement ne sont pas stockées avec les données chiffrées.

#### Restaurer une sauvegarde {#restore-a-backup}

Vous pouvez restaurer une sauvegarde uniquement sur la même version et le même type (Community Edition ou Enterprise Edition) de GitLab sur lequel elle a été créée.

- Consultez la [documentation de sauvegarde et restauration du package Linux (Omnibus)](https://docs.gitlab.com/omnibus/settings/backups).
- Consultez la [documentation de sauvegarde et restauration du chart Helm](https://docs.gitlab.com/charts/backup-restore/).

### Stratégies de sauvegarde alternatives {#alternative-backup-strategies}

Dans certaines situations, la tâche Rake pour les sauvegardes peut ne pas être la solution la plus optimale. Voici quelques [alternatives](backup_restore/_index.md) à considérer si la tâche Rake ne fonctionne pas pour vous.

#### Instantané du système de fichiers {#file-system-snapshot}

Si votre serveur GitLab contient une grande quantité de données de dépôt Git, le script de sauvegarde GitLab risque d'être trop lent. Il peut être particulièrement lent lors d'une sauvegarde vers un emplacement hors site.

La lenteur commence généralement à partir d'une taille de données de dépôt Git d'environ 200 Go. Dans ce cas, vous pourriez envisager d'utiliser des instantanés du système de fichiers dans le cadre de votre stratégie de sauvegarde. Par exemple, considérez un serveur GitLab avec les composants suivants :

- Utilisation du package Linux.
- Hébergé sur AWS avec un lecteur EBS contenant un système de fichiers ext4 monté sur `/var/opt/gitlab`.

L'instance EC2 répond aux exigences d'une sauvegarde de données d'application en prenant un instantané EBS. La sauvegarde inclut tous les dépôts, les téléversements et les données PostgreSQL.

Si vous exécutez GitLab sur un serveur virtualisé, vous pouvez créer des instantanés de VM de l'intégralité du serveur GitLab. Il est courant qu'un instantané de VM nécessite que vous éteigniez le serveur.

#### GitLab Geo {#gitlab-geo}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate

{{< /details >}}

Geo fournit des instances locales en lecture seule de vos instances GitLab.

Bien que GitLab Geo aide les équipes distantes à travailler plus efficacement en utilisant un nœud GitLab local, il peut également être utilisé comme solution de reprise après sinistre. En savoir plus sur l'utilisation de [Geo comme solution de reprise après sinistre](geo/disaster_recovery/_index.md).

Geo réplique votre base de données, vos dépôts Git et quelques autres ressources. En savoir plus sur les [types de données que Geo réplique](geo/replication/datatypes.md#replicated-data-types).

## Obtenir de l'aide avec l'assistance GitLab {#get-help-with-gitlab-support}

GitLab fournit une assistance pour GitLab Self-Managed via différents canaux.

- Assistance prioritaire : Les clients GitLab Self-Managed [Premium et Ultimate](https://about.gitlab.com/pricing/) bénéficient d'une assistance prioritaire avec des délais de réponse échelonnés. En savoir plus sur la [mise à niveau vers l'assistance prioritaire](https://about.gitlab.com/support/#upgrading-to-priority-support).
- Assistance à la mise à niveau en direct : Bénéficiez d'un accompagnement expert individuel lors d'une mise à niveau en production. Grâce à votre **formule d'assistance prioritaire**, vous êtes éligible à une session de partage d'écran en direct et planifiée avec un membre de notre équipe d'assistance.

Pour obtenir de l'aide :

- Utilisez la documentation GitLab pour un support en libre-service.
- Rejoignez le [Forum GitLab](https://forum.gitlab.com/) pour bénéficier du soutien de la communauté.
- Rassemblez [vos informations d'abonnement](https://about.gitlab.com/support/#for-self-managed-users) avant de soumettre un ticket.
- [Soumettez un ticket d'assistance](https://support.gitlab.com/hc/en-us/requests/new).

## API et limites de débit {#api-and-rate-limits}

Les limites de débit préviennent les attaques par déni de service ou par force brute. Dans la plupart des cas, vous pouvez réduire la charge sur votre application et votre infrastructure en limitant le taux de requêtes provenant d'une seule adresse IP.

Les limites de débit améliorent également la sécurité de votre application.

### Configurer les limites de débit {#configure-rate-limits}

Vous pouvez modifier vos limites de débit par défaut depuis la zone **Admin**. Pour plus d'informations sur la configuration, consultez la [page de la zone **Admin**](../security/rate_limits.md#configurable-limits).

- Définissez des [limites de débit sur les tickets](settings/rate_limit_on_issues_creation.md) pour définir un nombre maximum de requêtes de création de tickets par minute et par utilisateur.
- Appliquez des [limites de débit par utilisateur et par IP](settings/user_and_ip_rate_limits.md) pour les requêtes web non authentifiées.
- Vérifiez la [limite de débit sur les points de terminaison bruts](settings/rate_limits_on_raw_endpoints.md). Le paramètre par défaut est de 300 requêtes par minute pour l'accès aux fichiers bruts.
- Vérifiez les [limites de débit d'import/export](settings/import_export_rate_limits.md) des six valeurs actives par défaut.

Pour plus d'informations sur l'API et les limites de débit, consultez notre [page API](../api/rest/_index.md).

## Ressources de formation GitLab {#gitlab-training-resources}

Vous pouvez en apprendre davantage sur la façon d'administrer GitLab.

- Participez au [Forum GitLab](https://forum.gitlab.com/) pour échanger des conseils avec notre talentueuse communauté.
- Consultez [notre blog](https://about.gitlab.com/blog/) pour des mises à jour régulières sur :
  - Releases
  - Applications
  - Contributions
  - Actualités
  - Événements

### Formation GitLab payante {#paid-gitlab-training}

- Services de formation GitLab : Apprenez-en davantage sur les [meilleures pratiques GitLab et DevOps](https://about.gitlab.com/services/education/) grâce à nos cours de formation spécialisés. Consultez notre catalogue de cours complet.

### Formation GitLab gratuite {#free-gitlab-training}

- Bases de GitLab : Découvrez des guides en libre-service sur [les bases de Git et GitLab](../tutorials/_index.md).
- GitLab University : Apprenez de nouvelles compétences GitLab dans un cours structuré à [GitLab University](https://university.gitlab.com/learn/dashboard).

### Formation par des tiers {#third-party-training}

- Udemy : Pour une option de formation guidée plus abordable, envisagez [GitLab CI : Pipelines, CI/CD et DevOps pour les débutants](https://www.udemy.com/course/gitlab-ci-pipelines-ci-cd-and-devops-for-beginners/) sur Udemy.
- LinkedIn Learning : Consultez [Continuous Delivery with GitLab](https://www.linkedin.com/learning/continuous-integration-and-continuous-delivery-with-gitlab?replacementOf=continuous-delivery-with-gitlab) sur LinkedIn Learning pour une autre option de formation guidée à faible coût.
