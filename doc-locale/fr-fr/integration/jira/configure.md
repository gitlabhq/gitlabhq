---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Intégration des tickets Jira
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Nom [mis à jour](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166555) vers Intégration des tickets Jira dans GitLab 17.6.

{{< /history >}}

L'intégration des tickets Jira connecte un ou plusieurs projets GitLab à une instance Jira. Vous pouvez héberger l'instance Jira vous-même ou dans [Jira Cloud](https://www.atlassian.com/migration/assess/why-cloud). Les versions Jira prises en charge sont `6.x`, `7.x`, `8.x`, `9.x` et `10.x`.

## Configurer l'intégration {#configure-the-integration}

{{< history >}}

- L'authentification avec les jetons d'accès personnels Jira a été [introduite](https://gitlab.com/groups/gitlab-org/-/epics/8222) dans GitLab 16.0.
- Les sections **Tickets Jira** et **Jira issues for vulnerabilities** ont été [introduites](https://gitlab.com/gitlab-org/gitlab/-/issues/440430) dans GitLab 16.10 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `jira_multiple_project_keys`. Désactivés par défaut.
- Les sections **Tickets Jira** et **Jira issues for vulnerabilities** sont [généralement disponibles](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151753) dans GitLab 17.0. Feature flag `jira_multiple_project_keys` supprimé.
- La case à cocher **Enable Jira issues** a été [renommée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149055) en **Afficher les tickets Jira** dans GitLab 17.0.
- La case à cocher **Enable Jira issue creation from vulnerabilities** a été [renommée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149055) en **Créer des tickets Jira pour les vulnérabilités** dans GitLab 17.0.
- Le paramètre **Personnaliser les tickets Jira** a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/478824) dans GitLab 17.5.
- L'authentification par **Compte de service Jira Cloud** a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/work_items/576326) dans GitLab 19.0.

{{< /history >}}

Prérequis :

- Votre installation GitLab ne doit pas utiliser d'[URL relative](https://docs.gitlab.com/omnibus/settings/configuration/#configure-a-relative-url-for-gitlab).
- **For Jira Cloud** :
  - Pour utiliser l'**Authentification de base** avec un jeton d'API classique (non limité), vous devez disposer d'un [jeton d'API Jira Cloud](#create-a-jira-cloud-api-token) et de l'adresse de courriel que vous avez utilisée pour créer le jeton.
  - Pour utiliser l'**Authentification de base** avec un jeton d'API limité, vous devez créer un jeton limité pour votre compte utilisateur et définir l'URL de l'API Jira sur la passerelle de l'API Jira Platform (`https://api.atlassian.com/ex/jira/{cloudId}`). Pour plus d'informations, consultez [gérer les jetons d'API pour votre compte Atlassian](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/).
  - Pour utiliser un **Compte de service Jira Cloud**, vous devez disposer d'un compte de service Jira Cloud et d'un jeton d'API limité pour ce compte de service. Pour plus d'informations, consultez [gérer les jetons d'API pour les comptes de service](https://support.atlassian.com/user-management/docs/manage-api-tokens-for-service-accounts/#Create-an-API-token-with-scopes).
  - Si vous avez activé les [listes d'adresses IP autorisées](https://support.atlassian.com/security-and-access-policies/docs/specify-ip-addresses-for-product-access/), ajoutez la [plage d'adresses IP de GitLab.com](../../user/gitlab_com/_index.md#ip-range) à la liste d'autorisation pour [afficher les tickets Jira](#view-jira-issues) dans GitLab.
- **For Jira Data Center or Jira Server**, vous devez disposer de l'un des éléments suivants :
  - [Nom d'utilisateur et mot de passe Jira](jira_server_configuration.md).
  - Jeton d'accès personnel Jira (GitLab 16.0 et versions ultérieures).

Vous pouvez activer l'intégration des tickets Jira en configurant les paramètres de votre projet dans GitLab. Vous pouvez également configurer l'intégration pour un [groupe](../../user/project/integrations/_index.md#manage-group-default-settings-for-a-project-integration) spécifique ou pour l'ensemble d'une [instance](../../administration/settings/project_integration_management.md#configure-default-settings-for-an-integration) sur GitLab Self-Managed.

Grâce à cette intégration, votre projet GitLab peut interagir avec tous les projets Jira de votre instance. Pour configurer les paramètres de votre projet dans GitLab :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Intégrations**.
1. Sélectionnez **Tickets Jira**.
1. Sous **Activer l'intégration**, cochez la case **Actif**.
1. Sous **Méthode d'authentification**, sélectionnez l'une des options suivantes :

   - **Authentification de base** : utilisez une adresse de courriel et un jeton d'API pour Jira Cloud, ou un nom d'utilisateur et un mot de passe pour Jira Data Center ou Jira Server.
     - **Adresse de courriel ou nom d'utilisateur** :
       - Pour Jira Cloud, saisissez une adresse de courriel.
       - Pour Jira Data Center ou Jira Server, saisissez un nom d'utilisateur.
     - **Jeton d'API ou mot de passe** :
       - Pour Jira Cloud, saisissez un jeton d'API.
       - Pour Jira Data Center ou Jira Server, saisissez un mot de passe.

   - **Jeton d'accès personnel** (Jira Data Center et Jira Server uniquement) : saisissez un jeton d'accès personnel Jira.

   - **Compte de service Jira Cloud** (Jira Cloud uniquement) :

     - **Jeton de compte de service** : saisissez un jeton d'API limité pour un compte de service Jira Cloud.
     - Assurez-vous que le compte de service dispose des autorisations suffisantes sur les projets Jira auxquels vous souhaitez que GitLab accède.
1. Renseignez les informations de connexion :

   - **URL Web** : URL de base de l'interface web de l'instance Jira que vous associez à ce projet GitLab (par exemple, `https://jira.example.com` ou `https://example.atlassian.net`).
   - **URL de l'API Jira** : URL de base de l'API de l'instance Jira. Si ce champ n'est pas renseigné, la valeur de l'**URL Web** est utilisée.
     - Pour Jira Cloud avec un jeton d'API classique (non limité), laissez ce champ vide.
     - Pour Jira Cloud avec un jeton d'API limité (compte utilisateur ou compte de service), saisissez la passerelle de l'API Jira Platform : `https://api.atlassian.com/ex/jira/{cloudId}`. Pour trouver votre Cloud ID, consultez les [instructions Atlassian](https://support.atlassian.com/jira/kb/retrieve-my-atlassian-sites-cloud-id/).
1. Renseignez les paramètres de déclenchement :
   - Sélectionnez **Commit**, **Requête de fusion**, ou les deux comme déclencheurs. Lorsque vous mentionnez l'identifiant d'un ticket Jira dans GitLab, GitLab crée un lien vers ce ticket.
   - Pour ajouter un commentaire au ticket Jira qui renvoie vers GitLab, cochez la case **Activer les commentaires**.
   - Pour [faire passer automatiquement les tickets Jira](../../user/project/issues/managing_issues.md#closing-issues-automatically) dans GitLab, cochez la case **Activer les transitions Jira**.
1. Dans la section **Tickets Jira correspondants** :
   - Pour **Expression rationnelle de ticket Jira**, [saisissez un modèle d'expression rationnelle](issues.md#define-a-regex-pattern).
   - Pour **Préfixe de ticket Jira**, [saisissez un préfixe](issues.md#define-a-prefix).
1. Facultatif. Pour [afficher les tickets Jira](#view-jira-issues) dans GitLab, dans la section **Tickets Jira** :
   1. Cochez la case **Afficher les tickets Jira**.

      > [!warning]
      > Tous les utilisateurs ayant accès à votre projet GitLab peuvent consulter tout ticket Jira accessible par le jeton d'API utilisé pour l'authentification. Les clés de projets Jira que vous saisissez ci-dessous filtrent la liste des tickets affichés dans GitLab. Elles ne restreignent pas l'accès du jeton d'API. Pour limiter les tickets que l'intégration peut lire, utilisez un compte Jira ayant accès uniquement aux projets Jira que vous souhaitez exposer, et générez le jeton d'API à partir de ce compte.

   1. Saisissez une ou plusieurs clés de projets Jira à afficher. Laissez ce champ vide pour afficher toutes les clés accessibles par le jeton d'API.
1. Facultatif. Pour [créer des tickets Jira pour les vulnérabilités](#create-a-jira-issue-for-a-vulnerability), dans la section **Jira issues for vulnerabilities** :
   1. Cochez la case **Créer des tickets Jira pour les vulnérabilités**.

      > [!note]
      > Vous pouvez activer ce paramètre uniquement pour des projets et des groupes individuels.

   1. Saisissez une clé de projet Jira.
   1. Sélectionnez **Récupérer les types de tickets de cette clé de projet** ({{< icon name="retry" >}}), puis sélectionnez le type de tickets Jira à créer.
   1. Facultatif. Cochez la case **Personnaliser les tickets Jira** pour pouvoir examiner, modifier ou ajouter des détails à un ticket Jira lors de sa création pour une vulnérabilité.
1. Facultatif. Sélectionnez **Tester les paramètres**.
1. Sélectionnez **Enregistrer les modifications**.

## Afficher les tickets Jira {#view-jira-issues}

{{< details >}}

- Édition : Premium, Ultimate

{{< /details >}}

{{< history >}}

- L'activation des tickets Jira pour un groupe a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/325715) dans GitLab 16.9.
- La consultation des tickets provenant de plusieurs projets Jira a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/440430) dans GitLab 16.10 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `jira_multiple_project_keys`. Désactivés par défaut.
- La consultation des tickets provenant de plusieurs projets Jira est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151753) dans GitLab 17.0. Feature flag `jira_multiple_project_keys` supprimé.

{{< /history >}}

Prérequis :

- Assurez-vous que l'intégration des tickets Jira est [configurée](#configure-the-integration) et que la case **Afficher les tickets Jira** est cochée.

Vous pouvez activer les tickets Jira pour un groupe ou un projet spécifique, mais vous pouvez uniquement consulter les tickets dans les projets GitLab. Pour consulter les tickets provenant d'un ou de plusieurs projets Jira dans un projet GitLab :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Tickets Jira**.

Par défaut, les tickets sont triés par **Date de création**. Les tickets créés le plus récemment apparaissent en haut de la liste. Vous pouvez [filtrer les tickets](#filter-jira-issues) et sélectionner un ticket pour le consulter dans GitLab.

Les tickets sont regroupés dans les onglets suivants en fonction de leur [statut Jira](https://confluence.atlassian.com/adminjiraserver070/defining-status-field-values-749382903.html) :

- **Ouvrir** : tickets avec tout statut Jira autre que **Terminé**.
- **Fermé** : tickets avec le statut Jira **Terminé**.
- **Tous** : tickets avec tout statut Jira.

### Filtrer les tickets Jira {#filter-jira-issues}

{{< details >}}

- Édition : Premium, Ultimate

{{< /details >}}

{{< history >}}

- Le filtrage des tickets Jira par projet a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/440430) dans GitLab 16.10 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `jira_multiple_project_keys`. Désactivés par défaut.
- Le filtrage des tickets Jira par projet est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151753) dans GitLab 17.0. Feature flag `jira_multiple_project_keys` supprimé.

{{< /history >}}

Prérequis :

- Assurez-vous que l'intégration des tickets Jira est [configurée](#configure-the-integration) et que la case **Afficher les tickets Jira** est cochée.

Lorsque vous [consultez les tickets Jira](#view-jira-issues) dans GitLab, vous pouvez filtrer les tickets par texte dans les résumés et les descriptions. Vous pouvez également filtrer les tickets par :

- **Label** : spécifiez un ou plusieurs labels de tickets Jira dans le paramètre `labels[]` de l'URL. Lorsque vous spécifiez plusieurs labels, seuls les tickets possédant tous les labels spécifiés s'affichent (par exemple, `/-/integrations/jira/issues?labels[]=backend&labels[]=feature&labels[]=QA`).
- **Statut** : spécifiez le statut du ticket Jira dans le paramètre `status` de l'URL (par exemple, `/-/integrations/jira/issues?status=In Progress`).
- **Rapporteur** : spécifiez le nom d'affichage Jira du paramètre `author_username` dans l'URL (par exemple, `/-/integrations/jira/issues?author_username=John Smith`).
- **Personne assignée** : spécifiez le nom d'affichage Jira du paramètre `assignee_username` dans l'URL (par exemple, `/-/integrations/jira/issues?assignee_username=John Smith`).
- **Projet** : spécifiez la clé de projet Jira dans le paramètre `project` de l'URL (par exemple, `/-/integrations/jira/issues?project=GTL`).

## Vérification de Jira {#jira-verification}

{{< details >}}

- Édition : Premium, Ultimate

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192795) dans GitLab 18.3.

{{< /history >}}

Prérequis :

- Assurez-vous que l'intégration des tickets Jira est [configurée](#configure-the-integration) et que la case **Afficher les tickets Jira** est cochée.

Vous pouvez configurer des règles de vérification pour vous assurer que les tickets Jira référencés dans les messages de commit répondent à des critères spécifiques avant d'autoriser les pushs. Cette fonctionnalité permet de maintenir des workflows cohérents entre GitLab et Jira.

Lorsque GitLab effectue des vérifications :

- Si un message de commit contient plusieurs clés de tickets Jira, seule la première est utilisée pour les vérifications.
- En raison d'un problème connu, la désactivation du paramètre **Vérifier que le ticket existe** n'empêche pas l'exécution de la vérification. La seule façon d'arrêter l'exécution de la vérification est de désactiver toutes les vérifications Jira.

Pour configurer la vérification Jira :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Intégrations**.
1. Sélectionnez **Tickets Jira**.
1. Accédez à la section **Vérification de Jira**.
1. Configurez les vérifications suivantes :
   - **Vérifier que le ticket existe** : vérifie que le ticket Jira référencé dans le message de commit existe dans Jira.
   - **Vérifier l'assigné•e** : vérifie que l'auteur du commit est la personne assignée au ticket Jira référencé dans le message de commit.
   - **Vérifier l'état du ticket** : vérifie que le ticket Jira référencé dans le message de commit possède l'un des statuts autorisés.
   - **États autorisés** : une liste séparée par des virgules des statuts de tickets Jira autorisés (par exemple, `Ready, In Progress, Review`). Ce champ n'est disponible que lorsque **Vérifier l'état du ticket** est activé.
1. Sélectionnez **Enregistrer les modifications**.

Lorsqu'un utilisateur tente de pousser des modifications qui ne répondent pas aux critères de vérification, GitLab affiche un message d'erreur indiquant pourquoi le push a été rejeté.

### Exemples de messages d'erreur {#example-error-messages}

- Si un ticket Jira référencé n'existe pas (lorsque **Vérifier que le ticket existe** est activé) :

  ```plaintext
  Jira issue PROJECT-123 does not exist.
  ```

- Si un ticket Jira référencé n'est pas assigné à l'auteur du commit (lorsque **Vérifier l'assigné•e** est activé) :

  ```plaintext
  Jira issue PROJECT-123 is not assigned to you. It is assigned to Jane Doe.
  ```

- Si un ticket Jira référencé a un statut qui ne figure pas dans la liste autorisée (lorsque **Vérifier l'état du ticket** est activé) :

  ```plaintext
  Jira issue PROJECT-123 has status 'Done', which is not in the list of allowed statuses: Ready, In Progress, Review.
  ```

### Cas d'usage pour les vérifications {#use-case-for-verification-checks}

Considérez cet exemple :

1. Votre équipe utilise un workflow où les tickets Jira doivent avoir un statut spécifique lorsqu'ils sont en cours de traitement.
1. Vous configurez la vérification Jira pour :
   - Vérifier que les tickets existent
   - Vérifier que les tickets ont le statut « In Progress » ou « Review »
1. Un développeur tente de pousser des modifications avec le message de commit « Fix PROJECT-123 by adding validation ».
1. GitLab vérifie que :
   - Le ticket Jira PROJECT-123 existe
   - Le ticket a le statut « In Progress » ou « Review »
1. Si toutes les vérifications réussissent, le push est autorisé. Si une vérification échoue, le push est rejeté avec un message d'erreur.

Cela garantit que votre équipe suit le workflow correct en empêchant les modifications de code d'être poussées lorsque le ticket Jira correspondant n'est pas dans le bon état.

## Créer un ticket Jira pour une vulnérabilité {#create-a-jira-issue-for-a-vulnerability}

{{< details >}}

- Édition : GitLab Ultimate

{{< /details >}}

Prérequis :

- Assurez-vous que l'intégration des tickets Jira est [configurée](#configure-the-integration) et que la case **Créer des tickets Jira pour les vulnérabilités** est cochée.
- Vous devez disposer d'un compte utilisateur Jira avec l'autorisation de créer des tickets dans le projet cible.

Vous pouvez créer un ticket Jira depuis GitLab pour suivre toute action prise pour résoudre ou atténuer une vulnérabilité. Pour créer un ticket Jira pour une vulnérabilité :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation** > **Rapport de vulnérabilités**.
1. Sélectionnez la description de la vulnérabilité.
1. Sélectionnez **Créer un ticket Jira**.

   Si le paramètre [**Personnaliser les tickets Jira**](#configure-the-integration) est sélectionné, vous serez redirigé vers le formulaire de création de ticket sur votre instance Jira, pré-rempli avec les données de la vulnérabilité. Vous pouvez examiner, modifier ou ajouter des détails avant de créer le ticket Jira.

Le ticket est créé dans le projet Jira cible avec les informations du rapport de vulnérabilité.

Pour créer un ticket GitLab, consultez [créer un ticket GitLab pour une vulnérabilité](../../user/application_security/vulnerabilities/_index.md#create-a-gitlab-issue-for-a-vulnerability).

## Créer un jeton d'API Jira Cloud {#create-a-jira-cloud-api-token}

Pour configurer l'intégration des tickets Jira pour Jira Cloud, vous devez disposer d'un jeton d'API.

### Pour un compte utilisateur {#for-a-user-account}

1. Connectez-vous à [Atlassian](https://id.atlassian.com/manage-profile/security/api-tokens) depuis un compte disposant d'un accès en écriture aux projets Jira.

   Le lien ouvre la page **API tokens**. Sinon, depuis votre profil Atlassian, sélectionnez **Account Settings** > **Sécurité** > **Create and manage API tokens**.
1. Sélectionnez **Create API token**.
1. Dans la boîte de dialogue, saisissez un label pour votre jeton et sélectionnez **Créer**.
1. Pour copier le jeton d'API, sélectionnez **Copier**.

### Pour un compte de service {#for-a-service-account}

1. Créez ou identifiez un compte de service Jira Cloud. Pour plus d'informations, consultez la [documentation sur les comptes de service Atlassian](https://support.atlassian.com/user-management/docs/understand-service-accounts/#Create-a-service-account).
1. Créez un jeton d'API limité pour le compte de service. Pour plus d'informations, consultez [gérer les jetons d'API pour les comptes de service](https://support.atlassian.com/user-management/docs/manage-api-tokens-for-service-accounts/#Create-an-API-token-with-scopes).
1. Assurez-vous que le jeton dispose au minimum des portées Jira classiques suivantes :

   - `read:jira-user`
   - `read:jira-work`
   - `write:jira-work`

## Migrer d'un site Jira vers un autre {#migrate-from-one-jira-site-to-another}

{{< history >}}

- Le nom de l'intégration a été [mis à jour](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166555) vers **Tickets Jira** dans GitLab 17.6.

{{< /history >}}

Pour migrer d'un site Jira vers un autre dans GitLab tout en conservant votre intégration des tickets Jira :

1. Suivez les étapes décrites dans [configurer l'intégration](#configure-the-integration).
1. Saisissez la nouvelle URL du site Jira (par exemple, `https://myjirasite.atlassian.net`).

Dans GitLab 18.6 et versions ultérieures, les références aux tickets Jira existants sont automatiquement mises à jour pour utiliser la nouvelle URL du site Jira.

Dans GitLab 18.5 et versions antérieures, vous devez [invalider le cache Markdown](../../administration/invalidate_markdown_cache.md#invalidate-the-cache) pour mettre à jour les références aux tickets Jira existants.
