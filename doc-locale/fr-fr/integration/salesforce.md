---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: "Utiliser Salesforce comme fournisseur d'authentification OAuth 2.0"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Vous pouvez intégrer votre instance GitLab à [Salesforce](https://www.salesforce.com/) pour permettre aux utilisateurs de se connecter à votre instance GitLab avec leur compte Salesforce.

## Créer une application connectée Salesforce {#create-a-salesforce-connected-app}

Pour activer le fournisseur OmniAuth Salesforce, vous devez utiliser les identifiants Salesforce de votre instance GitLab. Pour obtenir les identifiants (une paire composée d'un ID client et d'un secret client), vous devez [créer une application connectée](https://help.salesforce.com/s/articleView?language=en_US&id=sf.connected_app_create.htm&type=5) dans Salesforce.

1. Connectez-vous à [Salesforce](https://login.salesforce.com/).
1. Dans Setup, saisissez `App Manager` dans la zone Quick Find, sélectionnez **App Manager**, puis sélectionnez **New Connected App**.
1. Renseignez les détails de l'application dans les champs suivants :
   - **Connected App Name** et **API Name** : définissez n'importe quelle valeur, mais envisagez quelque chose comme `<Organization>'s GitLab`, `<Your Name>'s GitLab`, ou une autre valeur descriptive.
   - **Contact Email** : saisissez l'adresse e-mail de contact que Salesforce utilisera pour vous contacter ou contacter votre équipe d'assistance.
   - **Description** : Description de l'application.

   ![Salesforce App Details](img/salesforce_app_details_v11_11.png)
1. Sélectionnez **API (Enable OAuth Settings)** et sélectionnez **Enable OAuth Settings**.
1. Renseignez les détails de l'application dans les champs suivants :
   - **URL de retour** : L'URL de retour de votre installation GitLab. Par exemple, `https://gitlab.example.com/users/auth/salesforce/callback`.
   - **Selected OAuth Scopes** : déplacez `Access your basic information (id, profile, email, address, phone)` et `Allow access to your unique identifier (openid)` vers la colonne de droite.

   ![Salesforce OAuth App Details](img/salesforce_oauth_app_details_v11_11.png)
1. Sélectionnez **Enregistrer**.
1. Sur votre serveur GitLab, ouvrez le fichier de configuration.

   Pour les installations de paquets Linux :

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   Pour les installations compilées manuellement :

   ```shell
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

1. Configurez les [paramètres communs](omniauth.md#configure-common-settings) pour ajouter `salesforce` en tant que fournisseur d'authentification unique. Cela active le provisionnement de compte Just-In-Time pour les utilisateurs qui ne disposent pas encore d'un compte GitLab.
1. Ajoutez la configuration du fournisseur. Pour les installations de paquets Linux :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "salesforce",
       # label: "Provider name", # optional label for login button, defaults to "Salesforce"
       app_id: "SALESFORCE_CLIENT_ID",
       app_secret: "SALESFORCE_CLIENT_SECRET"
     }
   ]
   ```

   Pour les installations compilées manuellement :

   ```yaml
   - { name: 'salesforce',
       # label: 'Provider name', # optional label for login button, defaults to "Salesforce"
       app_id: 'SALESFORCE_CLIENT_ID',
       app_secret: 'SALESFORCE_CLIENT_SECRET'
   }
   ```

1. Remplacez `SALESFORCE_CLIENT_ID` par la Consumer Key de la page de l'application connectée Salesforce.
1. Remplacez `SALESFORCE_CLIENT_SECRET` par le Consumer Secret de la page de l'application connectée Salesforce.

   ![Salesforce App Secret Details](img/salesforce_app_secret_details_v11_11.png)
1. Enregistrez le fichier de configuration.
1. Pour que les modifications prennent effet :
   - Si vous avez effectué l'installation à l'aide du package Linux, [reconfigurez GitLab](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation).
   - Si vous avez compilé votre installation manuellement, [redémarrez GitLab](../administration/restart_gitlab.md#self-compiled-installations).

Sur la page de connexion, une icône Salesforce doit maintenant apparaître sous le formulaire de connexion habituel. Sélectionnez l'icône pour lancer le processus d'authentification. Salesforce demande à l'utilisateur de se connecter et d'autoriser l'application GitLab. Si tout se passe bien, l'utilisateur est renvoyé vers GitLab et est connecté.

> [!note]
> GitLab requiert l'adresse e-mail de chaque nouvel utilisateur. Une fois l'utilisateur connecté via Salesforce, GitLab le redirige vers la page de profil où il doit fournir son adresse e-mail et la vérifier.
