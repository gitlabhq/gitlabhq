---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Utiliser AWS Cognito comme fournisseur d'authentification OAuth 2.0"
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Amazon Web Services (AWS) Cognito vous permet d'autoriser les nouveaux utilisateurs à créer des comptes, à se connecter et à accéder à votre instance GitLab. La documentation suivante permet d'activer AWS Cognito en tant que fournisseur OAuth 2.0.

## Configurer AWS Cognito {#configure-aws-cognito}

Pour activer le fournisseur OmniAuth OAuth 2.0 [AWS Cognito](https://aws.amazon.com/cognito/), enregistrez votre application auprès de Cognito. Ce processus génère un ID client et un secret client pour votre application. Pour activer AWS Cognito en tant que fournisseur d'authentification, effectuez les étapes suivantes. Vous pouvez modifier ultérieurement les paramètres que vous configurez.

1. Connectez-vous à la [console AWS](https://console.aws.amazon.com/console/home).
1. Dans le menu **Services**, sélectionnez **Cognito**.
1. Sélectionnez **Manage User Pools**, puis dans le coin supérieur droit, sélectionnez **Create a user pool**.
1. Saisissez le nom du groupe d'utilisateurs, puis sélectionnez **Step through settings**.
1. Sous **How do you want your end users to sign in?**, sélectionnez **Email address or phone number** et **Allow email addresses**.
1. Sous **Which standard attributes do you want to require?**, sélectionnez **email**.
1. Configurez les paramètres restants selon vos besoins. Dans la configuration de base, ces paramètres n'affectent pas la configuration de GitLab.
1. Dans les paramètres **App clients** :
   1. Sélectionnez **Add an app client**.
   1. Ajoutez le **App client name**.
   1. Cochez la case **Enable username password based authentication**.
1. Sélectionnez **Create app client**.
1. Configurez les fonctions AWS Lambda pour l'envoi d'e-mails et terminez la création du groupe d'utilisateurs.
1. Après avoir créé le groupe d'utilisateurs, accédez à **App client settings** et fournissez les informations requises :

   - **Enabled Identity Providers** \- sélectionnez tout
   - **URL de retour** - `https://<your_gitlab_instance_url>/users/auth/cognito/callback`
   - **Allowed OAuth Flows** \- Authorization code grant
   - **Allowed OAuth 2.0 Scopes** - `email`, `openid` et `profile`

1. Enregistrez les modifications apportées aux paramètres du client d'application.
1. Sous **Domain name**, indiquez le nom de domaine AWS pour votre application AWS Cognito.
1. Sous **App Clients**, recherchez l'ID de votre client d'application. Sélectionnez **Afficher les détails** pour afficher le secret du client d'application. Ces valeurs correspondent à l'ID client et au secret client OAuth 2.0. Enregistrez ces valeurs.

## Configurer GitLab {#configure-gitlab}

1. Configurez les [paramètres communs](../../integration/omniauth.md#configure-common-settings) pour ajouter `cognito` en tant que fournisseur d'authentification unique. Cela active le provisionnement de compte juste-à-temps pour les utilisateurs qui ne disposent pas d'un compte GitLab existant.
1. Sur votre serveur GitLab, ouvrez le fichier de configuration. Pour les installations avec le package Linux :

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

1. Dans le bloc de code suivant, saisissez les informations de votre application AWS Cognito dans les paramètres suivants :

   - `app_id` :  Votre ID client.
   - `app_secret` :  Votre secret client.
   - `site` :  Votre domaine et région Amazon.

   Incluez le bloc de code dans le fichier `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_allow_single_sign_on'] = ['cognito']
   gitlab_rails['omniauth_providers'] = [
     {
       name: "cognito",
       label: "Provider name", # optional label for login button, defaults to "Cognito"
       icon: nil,   # Optional icon URL
       app_id: "<client_id>",
       app_secret: "<client_secret>",
       args: {
         scope: "openid profile email",
         client_options: {
           site: "https://<your_domain>.auth.<your_region>.amazoncognito.com",
           authorize_url: "/oauth2/authorize",
           token_url: "/oauth2/token",
           user_info_url: "/oauth2/userInfo"
         },
         user_response_structure: {
           root_path: [],
           id_path: ["sub"],
           attributes: { nickname: "email", name: "email", email: "email" }
         },
         name: "cognito",
         strategy_class: "OmniAuth::Strategies::OAuth2Generic"
       }
     }
   ]
   ```

1. Enregistrez le fichier de configuration.
1. Enregistrez le fichier et [reconfigurez](../restart_gitlab.md#reconfigure-a-linux-package-installation) GitLab pour que les modifications prennent effet.

Votre page de connexion devrait maintenant afficher une option Cognito sous le formulaire de connexion habituel. Sélectionnez cette option pour commencer le processus d'authentification. AWS Cognito vous demande alors de vous connecter et d'autoriser l'application GitLab. Si l'autorisation réussit, vous êtes redirigé et connecté à votre instance GitLab.

Pour plus d'informations, consultez [Configurer les paramètres communs](../../integration/omniauth.md#configure-common-settings).
