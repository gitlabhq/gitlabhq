---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Utiliser Auth0 comme fournisseur d'authentification OAuth 2.0"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Pour activer le fournisseur Auth0 OmniAuth, vous devez créer un compte Auth0 et une application.

1. Connectez-vous à [Auth0 Console](https://auth0.com/auth/login). Vous pouvez également créer un compte en utilisant le même lien.
1. Sélectionnez **New App/API**.
1. Saisissez le **Application Name**. Par exemple, « GitLab ».
1. Après avoir créé l'application, vous devriez voir les options **Quick Start**. Ignorez ces options et sélectionnez plutôt **Paramètres**.
1. En haut de l'écran Paramètres, vous devriez voir votre **Domaine**, votre **ID du client** et votre **Client Secret** dans Auth0 Console. Notez ces paramètres pour compléter le fichier de configuration ultérieurement. Par exemple :
   - Domaine : `test1234.auth0.com`
   - ID du client : `t6X8L2465bNePWLOvt9yi41i`
   - Client Secret : `KbveM3nqfjwCbrhaUy_gDu2dss8TIlHIdzlyf33pB7dEK5u_NyQdp65O_o02hXs2`
1. Remplissez le champ **Allowed Callback URLs** :
   - `http://<your_gitlab_url>/users/auth/auth0/callback` (ou)
   - `https://<your_gitlab_url>/users/auth/auth0/callback`
1. Remplissez le champ **Allowed Origins (CORS)** :
   - `http://<your_gitlab_url>` (ou)
   - `https://<your_gitlab_url>`
1. Sur votre serveur GitLab, ouvrez le fichier de configuration.

   Pour les installations de paquets Linux :

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   Pour les installations compilées depuis les sources :

   ```shell
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

1. Configurez les [paramètres communs](omniauth.md#configure-common-settings) pour ajouter `auth0` en tant que fournisseur d'authentification unique (SSO). Cela active le provisionnement de compte Just-In-Time pour les utilisateurs qui ne disposent pas encore d'un compte GitLab.
1. Ajoutez la configuration du fournisseur :

   Pour les installations de paquets Linux :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "auth0",
       # label: "Provider name", # optional label for login button, defaults to "Auth0"
       args: {
         client_id: "<your_auth0_client_id>",
         client_secret: "<your_auth0_client_secret>",
         domain: "<your_auth0_domain>",
         scope: "openid profile email"
       }
     }
   ]
   ```

   Pour les installations compilées depuis les sources :

   ```yaml
   - { name: 'auth0',
       # label: 'Provider name', # optional label for login button, defaults to "Auth0"
       args: {
         client_id: '<your_auth0_client_id>',
         client_secret: '<your_auth0_client_secret>',
         domain: '<your_auth0_domain>',
         scope: 'openid profile email' }
     }
   ```

1. Remplacez `<your_auth0_client_id>` par l'ID du client figurant sur la page Auth0 Console.
1. Remplacez `<your_auth0_client_secret>` par le secret du client figurant sur la page Auth0 Console.
1. Remplacez `<your_auth0_domain>` par le domaine figurant sur la page Auth0 Console.
1. Reconfigurez ou redémarrez GitLab selon votre méthode d'installation :
   - Si vous avez effectué l'installation à l'aide du package Linux, [reconfigurez GitLab](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation).
   - Si vous avez compilé GitLab depuis les sources, [redémarrez GitLab](../administration/restart_gitlab.md#self-compiled-installations).

Sur la page de connexion, une icône Auth0 devrait désormais apparaître sous le formulaire de connexion habituel. Sélectionnez l'icône pour démarrer le processus d'authentification. Auth0 demande à l'utilisateur de se connecter et d'autoriser l'application GitLab. Si l'utilisateur s'authentifie correctement, il est redirigé vers GitLab et connecté.
