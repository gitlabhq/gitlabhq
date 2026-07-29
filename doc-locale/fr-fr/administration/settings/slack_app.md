---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Administration de l'application GitLab pour Slack"
description: "Administrez, configurez et dépannez l'application GitLab pour Slack sur les instances GitLab Self-Managed."
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/358872) pour GitLab Self-Managed dans GitLab 16.2.

{{< /history >}}

> [!note]
> Cette page contient la documentation administrateur pour l'application GitLab pour Slack. Pour la documentation utilisateur, voir [Application GitLab pour Slack](../../user/project/integrations/gitlab_slack_application.md).

L'application GitLab pour Slack distribuée via le répertoire d'applications Slack fonctionne uniquement avec GitLab.com. Sur GitLab Self-Managed, vous pouvez créer votre propre copie de l'application GitLab pour Slack à partir d'un [fichier manifeste](https://api.slack.com/reference/manifests#creating_apps) et configurer votre instance.

L'application est une copie privée à usage unique installée uniquement dans votre workspace Slack et non distribuée via le répertoire d'applications Slack. Pour disposer de l'[application GitLab pour Slack](../../user/project/integrations/gitlab_slack_application.md) sur votre instance GitLab Self-Managed, vous devez activer l'intégration.

## Créer une application GitLab pour Slack {#create-a-gitlab-for-slack-app}

Prérequis :

- Vous devez être au moins [administrateur du workspace Slack](https://slack.com/help/articles/360018112273-Types-of-roles-in-Slack).

Pour créer une application GitLab pour Slack :

- **Dans GitLab** :

  1. Dans le coin supérieur droit, sélectionnez **Admin**.
  1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
  1. Développez **Application GitLab pour Slack**.
  1. Sélectionnez **Créer une application Slack**.

Vous êtes ensuite redirigé vers Slack pour les étapes suivantes.

- **In Slack** :

  1. Sélectionnez le workspace Slack dans lequel créer l'application, puis sélectionnez **Suivant**.
  1. Slack affiche un résumé de l'application pour révision. Pour afficher le manifeste complet, sélectionnez **Edit Configurations**. Pour revenir au résumé de révision, sélectionnez **Suivant**.
  1. Sélectionnez **Créer**.
  1. Sélectionnez **Compris** pour fermer la boîte de dialogue.
  1. Sélectionnez **Install to Workspace**.

## Configurer les paramètres {#configure-the-settings}

Après avoir [créé une application GitLab pour Slack](#create-a-gitlab-for-slack-app), vous pouvez configurer les paramètres dans GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Application GitLab pour Slack**.
1. Cochez la case **Activer GitLab pour l'application Slack**.
1. Saisissez les détails de votre application GitLab pour Slack :
   1. Accédez à [Slack API](https://api.slack.com/apps).
   1. Recherchez et sélectionnez **GitLab (`<your host name>`)**.
   1. Faites défiler jusqu'à **App Credentials**.
1. Sélectionnez **Sauvegarder les modifications**.

## Installer l'application GitLab pour Slack {#install-the-gitlab-for-slack-app}

{{< history >}}

- L'installation pour une instance spécifique a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/391526) dans GitLab 16.10 [avec un indicateur de fonctionnalité](../feature_flags/_index.md) nommé `gitlab_for_slack_app_instance_and_group_level`. Désactivé par défaut.
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147820) dans GitLab 16.11.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175803) dans GitLab 17.8. Indicateur de feature flag `gitlab_for_slack_app_instance_and_group_level` supprimé.

{{< /history >}}

Prérequis :

- Vous devez disposer des [autorisations appropriées pour ajouter des applications à votre workspace Slack](https://slack.com/help/articles/202035138-Add-apps-to-your-Slack-workspace).
- Vous devez [créer une application GitLab pour Slack](#create-a-gitlab-for-slack-app) et [configurer les paramètres de l'application](#configure-the-settings).

Pour installer l'application GitLab pour Slack à partir des paramètres de l'instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Intégrations**.
1. Sélectionnez **Application GitLab pour Slack**.
1. Sélectionnez **Installer l'application GitLab pour Slack.**.
1. Sur la page de confirmation Slack, sélectionnez **Autoriser**.

### Tester votre configuration {#test-your-configuration}

Pour tester la configuration de votre application GitLab pour Slack :

1. Saisissez la commande slash `/gitlab help` dans un canal de votre workspace Slack.
1. Appuyez sur <kbd>Entrée</kbd>.

Vous devriez voir une liste des commandes slash disponibles.

Pour utiliser des commandes slash pour un projet, configurez l'[application GitLab pour Slack](../../user/project/integrations/gitlab_slack_application.md) pour le projet.

## Mettre à jour l'application GitLab pour Slack {#update-the-gitlab-for-slack-app}

Prérequis :

- Vous devez être au moins [administrateur du workspace Slack](https://slack.com/help/articles/360018112273-Types-of-roles-in-Slack).

Lorsque GitLab publie de nouvelles fonctionnalités pour l'application GitLab pour Slack, vous devrez peut-être mettre à jour manuellement votre copie pour utiliser les nouvelles fonctionnalités.

Pour mettre à jour votre copie de l'application GitLab pour Slack :

- **Dans GitLab** :
  1. Dans le coin supérieur droit, sélectionnez **Admin**.
  1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
  1. Développez **Application GitLab pour Slack**.
  1. Sélectionnez **Télécharger le dernier fichier manifeste** pour télécharger `slack_manifest.json`.
- **In Slack** :
  1. Accédez à [Slack API](https://api.slack.com/apps).
  1. Recherchez et sélectionnez **GitLab (`<your host name>`)**.
  1. Dans la barre latérale gauche, sélectionnez **App Manifest**.
  1. Sélectionnez l'onglet **JSON** pour passer à une vue JSON du manifeste.
  1. Copiez le contenu du fichier `slack_manifest.json` que vous avez téléchargé depuis GitLab.
  1. Collez le contenu dans le visualiseur JSON pour remplacer tout contenu existant.
  1. Sélectionnez **Enregistrer les modifications**.

## Exigences de connectivité {#connectivity-requirements}

Pour activer les fonctionnalités de l'application GitLab pour Slack, votre réseau doit autoriser les connexions entrantes et sortantes entre GitLab et Slack.

- Pour les [notifications Slack](../../user/project/integrations/gitlab_slack_application.md#slack-notifications), l'instance GitLab doit être en mesure d'envoyer des requêtes à `https://slack.com`.
- Pour les [commandes slash](../../user/project/integrations/gitlab_slack_application.md#slash-commands) et autres fonctionnalités, l'instance GitLab doit être en mesure de recevoir des requêtes depuis `https://slack.com`.

## Activer la prise en charge de plusieurs workspaces {#enable-support-for-multiple-workspaces}

Par défaut, vous pouvez [installer l'application GitLab pour Slack](../../user/project/integrations/gitlab_slack_application.md#install-the-gitlab-for-slack-app) dans un seul workspace Slack. Un administrateur sélectionne ce workspace lors de la [création d'une application GitLab pour Slack](#create-a-gitlab-for-slack-app).

Pour activer la prise en charge de plusieurs workspaces Slack, vous devez configurer l'application GitLab pour Slack en tant qu'[application distribuée non répertoriée](https://api.slack.com/distribution#unlisted-distributed-apps). Une application distribuée non répertoriée :

- N'est pas publiée dans le répertoire d'applications Slack.
- Ne peut être utilisée qu'avec votre instance GitLab et non par d'autres sites.

Pour configurer l'application GitLab pour Slack en tant qu'application distribuée non répertoriée :

1. Accédez à la page [**Your Apps**](https://api.slack.com/apps) sur Slack et sélectionnez votre application GitLab pour Slack.
1. Sélectionnez **Manage Distribution**.
1. Dans la section **Share Your App with Other Workspaces**, développez **Remove Hard Coded Information**.
1. Cochez la case **I've reviewed and removed any hard-coded information**.
1. Sélectionnez **Activate Public Distribution**.

## Dépannage {#troubleshooting}

Lors de l'administration de l'application GitLab pour Slack, vous pourriez rencontrer les problèmes suivants.

Pour la documentation utilisateur, voir [Application GitLab pour Slack](../../user/project/integrations/gitlab_slack_app_troubleshooting.md).

### Les commandes slash retournent `dispatch_failed` dans Slack {#slash-commands-return-dispatch_failed-in-slack}

Les commandes slash peuvent retourner `/gitlab failed with the error "dispatch_failed"` dans Slack.

Pour résoudre ce problème, assurez-vous que :

- L'application GitLab pour Slack est correctement [configurée](#configure-the-settings) et la case **Activer GitLab pour l'application Slack** est cochée.
- Votre instance GitLab [autorise les requêtes vers et depuis Slack](#connectivity-requirements).
