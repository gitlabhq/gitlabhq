---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Application GitLab pour Jira Cloud
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> Pour la documentation administrateur, consultez [Administration de l'application GitLab pour Jira Cloud](../../administration/settings/jira_cloud_app.md).

Avec l'application [GitLab pour Jira Cloud](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?tab=overview&hosting=cloud), vous pouvez connecter GitLab et Jira Cloud pour synchroniser les informations de développement en temps réel. Vous pouvez consulter ces informations dans le [panneau de développement Jira](development_panel.md).

Vous pouvez utiliser l'application GitLab pour Jira Cloud pour associer des groupes principaux ou des sous-groupes. Il n'est pas possible d'associer directement des projets ou des espaces de nommage personnels.

Pour configurer l'application GitLab pour Jira Cloud sur GitLab.com, [installez l'application GitLab pour Jira Cloud](#install-the-gitlab-for-jira-cloud-app).

Après avoir configuré l'application, vous pouvez utiliser la [chaîne d'outils de projet](https://support.atlassian.com/jira-software-cloud/docs/what-is-the-connections-feature/) développée et maintenue par Atlassian pour [associer des dépôts GitLab à des projets Jira](https://support.atlassian.com/jira-software-cloud/docs/link-repositories-to-a-project/#Link-repositories-using-the-toolchain-feature). La chaîne d'outils de projet n'affecte pas la façon dont les informations de développement sont synchronisées entre GitLab et Jira Cloud.

Pour Jira Data Center ou Jira Server, utilisez le [connecteur Jira DVCS](dvcs/_index.md) développé et maintenu par Atlassian.

## Données GitLab synchronisées avec Jira {#gitlab-data-synced-to-jira}

Après avoir associé un groupe, les données GitLab suivantes sont synchronisées avec Jira pour tous les projets de ce groupe lorsque vous [mentionnez un ID de ticket Jira](development_panel.md#information-displayed-in-the-development-panel) :

- Données de projet existantes (avant l'association du groupe) :
  - Les 400 dernières merge requests
  - Les 400 dernières branches et le dernier commit pour chacune de ces branches (GitLab 15.11 et versions ultérieures)
- Nouvelles données de projet (après l'association du groupe) :
  - Merge requests
    - Auteur de la merge request
  - Branches
  - Commits
    - Auteur du commit
  - Pipelines
  - Déploiements
  - Feature flags

## Installer l'application GitLab pour Jira Cloud {#install-the-gitlab-for-jira-cloud-app}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com

{{< /details >}}

Prérequis :

- Votre réseau doit autoriser les connexions entrantes et sortantes entre GitLab et Jira.
- Vous devez satisfaire à certaines [exigences utilisateur Jira](../../administration/settings/jira_cloud_app.md#jira-user-requirements).

Pour installer l'application GitLab pour Jira Cloud :

1. Dans Jira, dans la barre supérieure, sélectionnez **Apps** > **Explore more apps** et recherchez `GitLab for Jira Cloud`.
1. Sélectionnez **GitLab for Jira Cloud**, puis sélectionnez **Get it now**.

Vous pouvez également [obtenir l'application directement sur l'Atlassian Marketplace](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?tab=overview&hosting=cloud).

Vous pouvez maintenant [configurer l'application GitLab pour Jira Cloud](#configure-the-gitlab-for-jira-cloud-app).

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une vue d'ensemble, consultez [l'installation de l'application GitLab pour Jira Cloud depuis l'Atlassian Marketplace pour GitLab.com](https://youtu.be/52rB586_rs8?list=PL05JrBw4t0Koazgli_PmMQCER2pVH7vUT).
<!-- Video published on 2024-10-30 -->

La vidéo ci-dessus présente l'ancienne [interface Universal Plugin Manager](https://community.atlassian.com/forums/Community-Announcements-articles/Cloud-admins-we-re-making-app-management-easier/ba-p/2806285) qui peut ne pas être disponible sur les instances Jira Cloud plus récentes. Les instructions suivantes couvrent à la fois les anciennes et nouvelles interfaces de gestion des applications.

## Configurer l'application GitLab pour Jira Cloud {#configure-the-gitlab-for-jira-cloud-app}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com

{{< /details >}}

{{< history >}}

- **Ajouter un espace de nommage** [renommé](https://gitlab.com/gitlab-org/gitlab/-/issues/331432) en **Associer des groupes** dans GitLab 16.1.

{{< /history >}}

Prérequis :

- Vous devez disposer du rôle Maintainer ou Owner pour le groupe GitLab.
- Vous devez satisfaire à certaines [exigences utilisateur Jira](../../administration/settings/jira_cloud_app.md#jira-user-requirements).

Vous pouvez synchroniser des données de GitLab vers Jira en associant l'application GitLab pour Jira Cloud à un ou plusieurs groupes GitLab. Pour configurer l'application GitLab pour Jira Cloud :

<!-- markdownlint-disable MD044 -->

1. Dans Jira, sélectionnez les points de suspension horizontaux ({{< icon name="ellipsis_h" >}}) à côté de **Apps** et sélectionnez **Manage your apps**.
1. Accédez à l'application en utilisant l'une de ces méthodes :

   - Pour les instances avec gestion centralisée des applications :

     1. Si le message « App management has moved to Administration » s'affiche, sélectionnez **Take me there**. Sinon, suivez les instructions **For instances with legacy app management** ci-dessous.
     1. Dans l'onglet **Installed apps**, localisez **GitLab for Jira**. Selon la manière dont vous avez installé l'application, son nom est :
        - **GitLab for Jira (gitlab.com)** si vous avez [installé l'application depuis l'Atlassian Marketplace](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?tab=overview&hosting=cloud).
        - **GitLab for Jira (`<gitlab.example.com>`)** si vous avez [installé l'application manuellement](../../administration/settings/jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually).
     1. Sélectionnez les points de suspension horizontaux ({{< icon name="ellipsis_h" >}}) puis sélectionnez **Get started** pour configurer l'intégration.

   - Pour les instances avec gestion d'applications héritée :

     1. Développez **GitLab for Jira**. Selon la manière dont vous avez installé l'application, son nom est :
        - **GitLab for Jira (gitlab.com)** si vous avez [installé l'application depuis l'Atlassian Marketplace](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?tab=overview&hosting=cloud).
        - **GitLab for Jira (`<gitlab.example.com>`)** si vous avez [installé l'application manuellement](../../administration/settings/jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually).
     1. Sélectionnez **Démarrer** pour configurer l'intégration.

1. Facultatif. Pour associer GitLab Self-Managed à Jira, sélectionnez **Change GitLab version**.
   1. Cochez toutes les cases, puis sélectionnez **Next**.
   1. Saisissez votre **URL de l'instance GitLab**, puis sélectionnez **Save**.
1. Sélectionnez **Sign in to GitLab**.

   > [!note]
   > Les [utilisateurs Enterprise](../../user/enterprise_user/_index.md) dont l'[authentification par mot de passe est désactivée pour leur groupe](../../user/group/saml_sso/_index.md#disable-password-and-passkey-authentication-for-enterprise-users) doivent d'abord se connecter à GitLab avec l'URL d'authentification unique de leur groupe.

   GitLab vous demande de vous connecter pour associer des groupes, mais ne lie pas la configuration à un utilisateur spécifique. L'instance GitLab reçoit un jeton de Jira qui est utilisé pour mettre à jour les informations dans Jira. Pour plus d'informations, consultez [Accès de GitLab à Jira](#gitlab-access-to-jira).
1. Sélectionnez **Autoriser**. Une liste de groupes est maintenant visible.
1. Sélectionnez **Associer des groupes**.
1. Pour associer un groupe, sélectionnez **Lien**.

<!-- markdownlint-enable MD044 -->

Après avoir associé un groupe GitLab :

- Les données sont synchronisées avec Jira pour tous les projets de ce groupe. La synchronisation initiale des données s'effectue par lots de 20 projets par minute. Pour les groupes comportant de nombreux projets, la synchronisation des données de certains projets peut être retardée.
- Une intégration de l'application GitLab pour Jira Cloud est automatiquement activée pour le groupe, ainsi que pour tous les sous-groupes ou projets de ce groupe. L'intégration vous permet de [configurer Jira Service Management](#configure-jira-service-management).

## Configurer Jira Service Management {#configure-jira-service-management}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/460663) dans GitLab 17.2 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `enable_jira_connect_configuration`. Désactivés par défaut.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/467117) dans GitLab 17.4. Feature flag `enable_jira_connect_configuration` supprimé.

{{< /history >}}

> [!note]
> Cette fonctionnalité a été ajoutée en tant que contribution de la communauté et est développée et maintenue uniquement par la communauté GitLab.

Prérequis :

- L'application GitLab pour Jira Cloud doit être [installée](#install-the-gitlab-for-jira-cloud-app).
- Un [groupe GitLab doit être associé](#configure-the-gitlab-for-jira-cloud-app) dans la configuration de l'application GitLab pour Jira Cloud.

Vous pouvez connecter GitLab à votre projet de service informatique pour suivre vos déploiements.

La configuration s'effectue dans GitLab, dans l'intégration de l'application GitLab pour Jira Cloud. L'intégration est activée pour un groupe, ses sous-groupes et ses projets dans GitLab après qu'un [groupe GitLab a été associé](#configure-the-gitlab-for-jira-cloud-app).

L'activation et la désactivation de l'intégration de l'application GitLab pour Jira Cloud s'effectuent entièrement de manière automatique via l'association de groupes, et non via le formulaire d'intégrations GitLab ou l'API.

Dans Jira Service Management :

1. Dans votre projet de service, accédez à **Project settings** > **Change management**.
1. Sélectionnez **Connect Pipeline** > **GitLab**, puis copiez l'**ID de service** à la fin du processus de configuration.

Dans GitLab :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Intégrations**.
1. Sélectionnez **Application GitLab pour Jira Cloud**. Si l'intégration est désactivée, commencez par [associer un groupe GitLab](#configure-the-gitlab-for-jira-cloud-app) afin d'activer l'intégration de l'application GitLab pour Jira Cloud pour le groupe, ses sous-groupes et ses projets.
1. Dans le champ **ID de service**, saisissez l'ID de service que vous souhaitez mapper dans ce projet. Pour utiliser plusieurs ID de service, ajoutez une virgule entre chaque ID de service.

Vous pouvez mapper jusqu'à 100 services.

Pour plus d'informations sur le suivi des déploiements dans Jira, consultez [configurer le suivi des déploiements](https://support.atlassian.com/jira-service-management-cloud/docs/set-up-deployment-tracking/).

### Configurer le contrôle d'accès aux déploiements avec GitLab {#set-up-deployment-gating-with-gitlab}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/473774) dans GitLab 17.6.

{{< /history >}}

> [!note]
> Cette fonctionnalité a été ajoutée en tant que contribution de la communauté et est développée et maintenue uniquement par la communauté GitLab.

Vous pouvez configurer le contrôle d'accès aux déploiements pour transmettre les demandes de changement de GitLab à Jira Service Management pour approbation. Grâce au contrôle d'accès aux déploiements, tout déploiement GitLab vers vos environnements sélectionnés est automatiquement envoyé à Jira Service Management et n'est déployé que s'il est approuvé.

#### Créer le jeton de compte de service {#create-the-service-account-token}

Pour créer un jeton de compte de service dans GitLab, vous devez d'abord créer un jeton d'accès personnel. Ce jeton authentifie le jeton de compte de service utilisé pour gérer les déploiements GitLab dans Jira Service Management.

Pour créer le jeton de compte de service :

1. [Créez un utilisateur de compte de service](../../api/service_accounts.md#create-an-instance-service-account).
1. [Ajoutez le compte de service à un groupe ou un projet](../../api/group_members.md#add-a-group-member) en utilisant votre jeton d'accès personnel.
1. [Ajoutez le compte de service aux environnements protégés](../../ci/environments/protected_environments.md#protecting-environments).
1. [Générez un jeton de compte de service](../../api/service_accounts.md#create-a-personal-access-token-for-a-group-service-account) en utilisant votre jeton d'accès personnel.
1. Copiez la valeur du jeton de compte de service.

#### Activer le contrôle d'accès aux déploiements {#enable-deployment-gating}

Pour activer le contrôle d'accès aux déploiements :

- Dans GitLab :

  1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
  1. Sélectionnez **Paramètres** > **Intégrations**.
  1. Sélectionnez **Application GitLab pour Jira Cloud**.
  1. Sous **Deployment gating**, cochez la case **Enable deployment gating**.
  1. Dans le champ de texte **Environment tiers**, saisissez les noms des environnements pour lesquels vous souhaitez activer le contrôle d'accès aux déploiements. Vous pouvez saisir plusieurs noms d'environnements séparés par des virgules (par exemple, `production, staging, testing, development`). Utilisez uniquement des lettres minuscules.
  1. Sélectionnez **Enregistrer les modifications**.
- Dans Jira Service Management :

  1. [Configurez le contrôle d'accès aux déploiements](https://support.atlassian.com/jira-service-management-cloud/docs/set-up-deployment-gating/).
  1. Dans le champ de texte **Jeton de compte de service**, [collez la valeur du jeton de compte de service que vous avez copiée depuis GitLab](#create-the-service-account-token).

#### Ajouter le compte de service aux environnements protégés {#add-the-service-account-to-protected-environments}

Pour ajouter le compte de service à vos environnements protégés dans GitLab :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **CI/CD**.
1. Développez **Environnements protégés** et sélectionnez **Protéger un environnement**.
1. Dans la liste déroulante **Sélectionner un environnement**, sélectionnez un environnement à protéger (par exemple, **préproduction**).
1. Dans la liste déroulante **Autorisés à déployer**, sélectionnez qui peut déployer vers cet environnement (par exemple, **Développeurs + Chargés de maintenance**).
1. Dans la liste déroulante **Approbateurs**, sélectionnez le [compte de service que vous avez créé](#create-the-service-account-token).
1. Sélectionnez **Protéger**.

#### Exemples de requêtes API {#example-api-requests}

- Créer un utilisateur de compte de service :

  ```shell
  curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --data "name=<name_of_your_choice>&username=<username_of_your_choice>"  "<https://gitlab.com/api/v4/groups/<group_id>/service_accounts"
  ```

- Ajouter le compte de service à un groupe ou un projet en utilisant votre jeton d'accès personnel :

  ```shell
  curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
       --data "user_id=<service_account_id>&access_level=30" "https://gitlab.com/api/v4/groups/<group_id>/members"
  curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
       --data "user_id=<service_account_id>&access_level=30" "https://gitlab.com/api/v4/projects/<project_id>/members"
  ```

- Générer un jeton de compte de service en utilisant votre jeton d'accès personnel :

  ```shell
  curl --request POST --header "PRIVATE-TOKEN: <your_access_token>"
  "https://gitlab.com/api/v4/groups/<group_id>/service_accounts/<service_account_id>/personal_access_tokens" --data "scopes[]=api,read_user,read_repository" --data "name=service_accounts_token"
  ```

## Mettre à jour l'application GitLab pour Jira Cloud {#update-the-gitlab-for-jira-cloud-app}

La plupart des mises à jour de l'application sont automatiques. Pour plus d'informations, consultez la [documentation Atlassian](https://developer.atlassian.com/platform/marketplace/upgrading-and-versioning-cloud-apps/).

Si l'application nécessite des autorisations supplémentaires, [vous devez approuver manuellement la mise à jour dans Jira](https://developer.atlassian.com/platform/marketplace/upgrading-and-versioning-cloud-apps/#changes-that-require-manual-customer-approval).

## Migration d'Atlassian Connect vers Forge {#migration-from-atlassian-connect-to-forge}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/592890) dans GitLab 18.10.

{{< /history >}}

L'application GitLab pour Jira Cloud a été migrée d'[Atlassian Connect](https://developer.atlassian.com/cloud/jira/platform/getting-started-with-connect/) vers [Atlassian Forge](https://developer.atlassian.com/platform/forge/). Ce changement fait suite à l'[annonce de fin de support des applications Connect](https://www.atlassian.com/blog/developer/announcing-connect-end-of-support-timeline-and-next-steps) par Atlassian.

Toutes les fonctionnalités existantes continuent de fonctionner, notamment :

- La synchronisation des branches, des commits, des merge requests, des pipelines, des déploiements et des feature flags vers le panneau de développement Jira.
- La création de branches GitLab à partir de tickets Jira.
- L'utilisation de Smart Commits pour le suivi du temps et les transitions de tickets.
- La prise en charge des instances GitLab.com et GitLab Self-Managed.

Si vous avez installé l'application GitLab pour Jira Cloud depuis l'[Atlassian Marketplace](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud) :

- La version Forge apparaît comme une [mise à niveau majeure](https://developer.atlassian.com/platform/marketplace/upgrading-and-versioning-cloud-apps/#changes-that-require-manual-customer-approval) de l'application existante.
- Un administrateur Jira doit approuver la mise à niveau.
- Toutes les données de développement précédemment synchronisées sont conservées automatiquement. L'application Forge utilise le même identifiant d'application, vous n'avez donc pas à migrer de données.
- Vous n'avez pas à modifier votre configuration GitLab.

Si vous avez précédemment installé l'application GitLab pour Jira Cloud manuellement avec le workflow Connect basé sur l'**App descriptor URL**, vous devez migrer vers la méthode basée sur Forge. Atlassian a [désactivé les installations privées basées sur Connect le 31 mars 2026](https://www.atlassian.com/blog/developer/announcing-connect-end-of-support-timeline-and-next-steps), donc l'ancien workflow ne fonctionne plus.

Pour migrer et conserver vos données existantes :

1. [Convertissez le descripteur de votre application Connect en manifeste Forge](https://developer.atlassian.com/platform/adopting-forge-from-connect/how-to-adopt/#part-2--convert-your-descriptor-to-a-manifest).
1. [Enregistrez la nouvelle application Forge](https://developer.atlassian.com/platform/adopting-forge-from-connect/how-to-adopt/#part-3--register-and-deploy-your-app-to-your-forge-development-site) en utilisant le manifeste converti.

Ces étapes garantissent que la nouvelle application Forge conserve le `connect.app.key` d'origine. Jira utilise cette clé, conjointement avec le nouvel ID d'application Forge, pour reconnaître les deux installations comme liées, afin que vos données de développement précédemment synchronisées restent intactes.

Après la conversion, suivez les [instructions d'installation manuelle basée sur Forge](../../administration/settings/jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually) pour publier une copie privée de l'[application Forge GitLab pour Jira Cloud](https://gitlab.com/gitlab-org/gitlab-jira-forge) sous votre propre compte développeur Atlassian.

Pour plus d'informations sur la transition de Connect vers Forge, consultez [le guide Atlassian sur l'adoption de Forge](https://developer.atlassian.com/platform/adopting-forge-from-connect/how-to-adopt/).

## Considérations de sécurité {#security-considerations}

L'application GitLab pour Jira Cloud connecte GitLab et Jira. Les données doivent être partagées entre les deux applications, et l'accès doit être accordé dans les deux sens.

### Accès de GitLab à Jira {#gitlab-access-to-jira}

Lorsque vous [configurez l'application GitLab pour Jira Cloud](#configure-the-gitlab-for-jira-cloud-app), GitLab reçoit un **shared secret token** de la part de Jira. Le jeton accorde à GitLab les [portées d'application](https://developer.atlassian.com/cloud/jira/software/scopes-for-connect-apps/#scopes-for-atlassian-connect-apps) `READ`, `WRITE` et `DELETE` pour le projet Jira. Ces portées sont nécessaires pour mettre à jour les informations dans le panneau de développement du projet Jira. Le jeton n'accorde pas à GitLab l'accès à d'autres produits Atlassian en dehors du projet Jira dans lequel l'application a été installée.

Le jeton est chiffré avec `AES256-GCM` et stocké sur GitLab. Lorsque l'application GitLab pour Jira Cloud est désinstallée de votre projet Jira, GitLab supprime le jeton.

### Accès de Jira à GitLab {#jira-access-to-gitlab}

Jira n'obtient aucun accès à GitLab.

### Données envoyées de GitLab à Jira {#data-sent-from-gitlab-to-jira}

Pour toutes les données envoyées à Jira, consultez [Données GitLab synchronisées avec Jira](#gitlab-data-synced-to-jira).

Pour plus d'informations sur les propriétés de données spécifiques envoyées à Jira, consultez les [classes de sérialisation](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/atlassian/jira_connect/serializers) impliquées dans la synchronisation des données.

### Données envoyées de Jira à GitLab {#data-sent-from-jira-to-gitlab}

GitLab reçoit un [événement de cycle de vie](https://developer.atlassian.com/cloud/jira/platform/connect-app-descriptor/#lifecycle) de Jira lorsque l'application GitLab pour Jira Cloud est installée ou désinstallée. L'événement inclut un [jeton](#gitlab-access-to-jira) pour vérifier les événements de cycle de vie ultérieurs et pour s'authentifier lors de l'[envoi de données à Jira](#data-sent-from-gitlab-to-jira). Les requêtes d'événements de cycle de vie provenant de Jira sont [vérifiées](https://developer.atlassian.com/cloud/jira/platform/security-for-connect-apps/#validating-installation-lifecycle-requests).

Pour les instances GitLab Self-Managed qui utilisent l'application GitLab pour Jira Cloud depuis l'Atlassian Marketplace, GitLab.com gère les événements de cycle de vie et les transfère à l'instance GitLab Self-Managed. Pour plus d'informations, consultez [Gestion des événements de cycle de vie de l'application par GitLab.com](../../administration/settings/jira_cloud_app.md#gitlabcom-handling-of-app-lifecycle-events).

### Données stockées par Jira {#data-stored-by-jira}

Les [données envoyées à Jira](#data-sent-from-gitlab-to-jira) sont stockées par Jira et affichées dans le [panneau de développement Jira](development_panel.md).

Lorsque l'application GitLab pour Jira Cloud est désinstallée, Jira supprime définitivement ces données. Ce processus s'effectue de manière asynchrone et peut prendre jusqu'à plusieurs heures.

### Détails sur la confidentialité et la sécurité dans l'Atlassian Marketplace {#privacy-and-security-details-in-the-atlassian-marketplace}

Pour plus d'informations, consultez les [détails sur la confidentialité et la sécurité de la fiche Atlassian Marketplace](https://marketplace.atlassian.com/apps/1221011/gitlab-for-jira-cloud?tab=privacy-and-security&hosting=cloud).

## Dépannage {#troubleshooting}

Lorsque vous utilisez l'application GitLab pour Jira Cloud, vous pouvez rencontrer les problèmes suivants.

Pour le dépannage administrateur, consultez [Administration de l'application GitLab pour Jira Cloud](../../administration/settings/jira_cloud_app_troubleshooting.md).

### Erreur : `Failed to link group` {#error-failed-to-link-group}

Lorsque vous connectez l'application GitLab pour Jira Cloud, vous pouvez obtenir cette erreur :

```plaintext
Failed to link group. Please try again.
```

Un `403 Forbidden` est renvoyé si les informations utilisateur ne peuvent pas être récupérées depuis Jira en raison de permissions insuffisantes.

Pour résoudre ce problème, assurez-vous de satisfaire à certaines [exigences utilisateur Jira](../../administration/settings/jira_cloud_app.md#jira-user-requirements).

Si l'utilisateur Jira possède des privilèges d'administrateur mais n'est pas explicitement membre du groupe `site-admins` ou `org-admins`, consultez [Erreur : l'utilisateur Jira n'est pas un administrateur de site ou d'organisation](../../administration/settings/jira_cloud_app_troubleshooting.md#error-the-jira-user-is-not-a-site-or-organization-administrator).

### Jira Code ne fonctionne pas après l'association à un groupe GitLab {#jira-code-does-not-work-after-linking-to-a-gitlab-group}

[Jira Code](https://support.atlassian.com/jira-software-cloud/docs/enable-code/) peut ne pas fonctionner après que vous avez [associé l'application GitLab pour Jira Cloud à un groupe GitLab](#configure-the-gitlab-for-jira-cloud-app). Pour résoudre ce problème, vous devez configurer à la fois Bitbucket et Jira.

Dans Bitbucket :

1. Connectez-vous à votre compte Atlassian.
1. Créez un workspace et saisissez un nom pour celui-ci.

Dans Jira :

1. Dans **Projects**, sélectionnez votre projet.
1. Sélectionnez **Development** > **Code**.
1. Sélectionnez **Connect Bitbucket** > **Link Bitbucket Cloud workspace**.
1. Sélectionnez le workspace que vous avez créé dans Bitbucket.
1. Sélectionnez **Grant access**.

Vos dépôts devraient maintenant apparaître dans Jira Code.

Pour plus d'informations, consultez [le ticket JRACLOUD-95847](https://jira.atlassian.com/browse/JRACLOUD-95847).
