---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Utiliser Atlassian comme fournisseur d'authentification OAuth 2.0"
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Pour activer le fournisseur OmniAuth Atlassian pour l'authentification sans mot de passe, vous devez enregistrer une application auprès d'Atlassian.

## Enregistrement de l'application Atlassian {#atlassian-application-registration}

1. Accédez à la [console développeur Atlassian](https://developer.atlassian.com/console/myapps/) et connectez-vous avec le compte Atlassian pour administrer l'application.
1. Sélectionnez **Create a new app**.
1. Choisissez un nom d'application, tel que « GitLab », et sélectionnez **Créer**.
1. Notez les valeurs `Client ID` et `Secret` pour les étapes de [configuration de GitLab](#gitlab-configuration).
1. Dans la barre latérale gauche, sous **APIS AND FEATURES**, sélectionnez **OAuth 2.0 (3LO)**.
1. Saisissez l'URL de rappel GitLab au format `https://gitlab.example.com/users/auth/atlassian_oauth2/callback` et sélectionnez **Sauvegarder les modifications**.
1. Sélectionnez **\+ Add** dans la barre latérale gauche sous **APIS AND FEATURES**.
1. Sélectionnez **Ajouter** pour **Jira platform REST API**, puis **Configurer**.
1. Sélectionnez **Ajouter** en regard des portées suivantes :
   - **View Jira issue data**
   - **View user profiles**
   - **Create and manage issues**

## Configuration de GitLab {#gitlab-configuration}

1. Sur votre serveur GitLab, ouvrez le fichier de configuration :

   Pour les installations avec le package Linux :

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   Pour les installations compilées manuellement :

   ```shell
   sudo -u git -H editor /home/git/gitlab/config/gitlab.yml
   ```

1. Configurez les [paramètres communs](../../integration/omniauth.md#configure-common-settings) pour ajouter `atlassian_oauth2` en tant que fournisseur d'authentification unique. Cela active le provisionnement de compte Just-In-Time pour les utilisateurs qui ne possèdent pas encore de compte GitLab.
1. Ajoutez la configuration du fournisseur pour Atlassian :

   Pour les installations avec le package Linux :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "atlassian_oauth2",
       # label: "Provider name", # optional label for login button, defaults to "Atlassian"
       app_id: "<your_client_id>",
       app_secret: "<your_client_secret>",
       args: { scope: "offline_access read:jira-user read:jira-work", prompt: "consent" }
     }
   ]
   ```

   Pour les installations compilées manuellement :

   ```yaml
   - { name: "atlassian_oauth2",
       # label: "Provider name", # optional label for login button, defaults to "Atlassian"
       app_id: "<your_client_id>",
       app_secret: "<your_client_secret>",
       args: { scope: "offline_access read:jira-user read:jira-work", prompt: "consent" }
    }
   ```

1. Remplacez `<your_client_id>` et `<your_client_secret>` par les identifiants client que vous avez reçus lors de l'[enregistrement de l'application](#atlassian-application-registration).
1. Enregistrez le fichier de configuration.
1. Pour que les modifications prennent effet :
   - Si vous avez effectué l'installation à l'aide du package Linux, [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
   - Si vous avez compilé votre installation manuellement, [redémarrez GitLab](../restart_gitlab.md#self-compiled-installations).

Sur la page de connexion, une icône Atlassian devrait maintenant apparaître sous le formulaire de connexion habituel. Sélectionnez l'icône pour démarrer le processus d'authentification.

Si tout se passe bien, l'utilisateur est connecté à GitLab à l'aide de ses identifiants Atlassian.
