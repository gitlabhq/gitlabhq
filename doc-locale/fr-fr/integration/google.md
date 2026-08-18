---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Utiliser Google OAuth 2.0 comme fournisseur d'authentification OAuth 2.0"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Pour activer le fournisseur OmniAuth Google OAuth 2.0, vous devez enregistrer votre application auprès de Google. Google génère un ID client et une clé secrète à votre intention.

Pour activer Google OAuth, vous devez configurer les éléments suivants :

- Google Cloud Resource Manager
- Google API Console
- Serveur GitLab

## Configurer Google Cloud Resource Manager {#configure-the-google-cloud-resource-manager}

1. Accédez au [Google Cloud Resource Manager](https://console.cloud.google.com/cloud-resource-manager).
1. Sélectionnez **CREATE PROJECT**.
1. Dans **Nom du projet**, saisissez `GitLab`.
1. Dans **ID du projet**, Google fournit par défaut un ID de projet généré de manière aléatoire. Vous pouvez utiliser cet ID généré aléatoirement ou en créer un nouveau. Si vous créez un nouvel ID, il doit être unique parmi toutes les applications enregistrées auprès de Google Developer.

Pour voir votre nouveau projet dans la liste, actualisez la page.

## Configurer Google API Console {#configure-the-google-api-console}

1. Accédez à la [Google API Console](https://console.developers.google.com/apis/dashboard).
1. Dans le coin supérieur gauche, sélectionnez le projet que vous avez précédemment créé.
1. Sélectionnez **OAuth consent screen** et remplissez les champs.
1. Sélectionnez **Identifiants** > **Create credentials** > **OAuth client ID**.
1. Remplissez les champs :
   - **Application type** : sélectionnez **Web application**.
   - **Nom** : utilisez le nom par défaut ou saisissez le vôtre.
   - **Authorized JavaScript origins** : saisissez `https://gitlab.example.com`.
   - **Authorized redirect URIs** : saisissez votre nom de domaine suivi des URI de callback, un à la fois :

     ```plaintext
     https://gitlab.example.com/users/auth/google_oauth2/callback
     https://gitlab.example.com/-/google_api/auth/callback
     ```

1. Vous devriez voir un ID client et un secret client. Notez-les ou gardez cette page ouverte, car vous en aurez besoin ultérieurement.
1. Pour permettre aux projets d'accéder à [Google Kubernetes Engine](../user/infrastructure/clusters/_index.md), vous devez également activer les éléments suivants :
   - Google Kubernetes Engine API
   - Cloud Resource Manager API
   - Cloud Billing API

   Pour ce faire :

   1. Accédez à la [Google API Console](https://console.developers.google.com/apis/dashboard).
   1. Sélectionnez **ENABLE APIS AND SERVICES** en haut de la page.
   1. Recherchez chacune des API mentionnées précédemment. Sur la page de l'API, sélectionnez **ENABLE**. L'activation complète de l'API peut prendre quelques minutes.

## Configurer le serveur GitLab {#configure-the-gitlab-server}

1. Ouvrez le fichier de configuration.

   Pour les installations de paquets Linux :

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   Pour les installations compilées manuellement :

   ```shell
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

1. Configurez les [paramètres communs](omniauth.md#configure-common-settings) pour ajouter `google_oauth2` comme fournisseur d'authentification unique. Cela active le provisionnement de compte Just-In-Time pour les utilisateurs qui ne disposent pas encore d'un compte GitLab.
1. Ajoutez la configuration du fournisseur.

   Pour les installations de paquets Linux :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "google_oauth2",
       # label: "Provider name", # optional label for login button, defaults to "Google"
       app_id: "<YOUR_APP_ID>",
       app_secret: "<YOUR_APP_SECRET>",
       args: { access_type: "offline", approval_prompt: "" }
     }
   ]
   ```

   Pour les installations compilées manuellement :

   ```yaml
   - { name: 'google_oauth2',
       # label: 'Provider name', # optional label for login button, defaults to "Google"
       app_id: 'YOUR_APP_ID',
       app_secret: 'YOUR_APP_SECRET',
       args: { access_type: 'offline', approval_prompt: '' } }
   ```

1. Remplacez `<YOUR_APP_ID>` par l'ID client figurant sur la page Google Developer.
1. Remplacez `<YOUR_APP_SECRET>` par le secret client figurant sur la page Google Developer.
1. Assurez-vous de configurer GitLab avec un nom de domaine pleinement qualifié, car Google n'accepte pas les adresses IP brutes.

   Pour les installations de paquets Linux :

   ```ruby
   external_url 'https://gitlab.example.com'
   ```

   Pour les installations compilées manuellement :

   ```yaml
   gitlab:
     host: https://gitlab.example.com
   ```

1. Enregistrez le fichier de configuration.
1. Pour que les modifications prennent effet :
   - Si vous avez effectué l'installation à l'aide du package Linux, [reconfigurez GitLab](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation).
   - Si vous avez compilé votre installation manuellement, [redémarrez GitLab](../administration/restart_gitlab.md#self-compiled-installations).

Sur la page de connexion, une icône Google devrait désormais apparaître sous le formulaire de connexion habituel. Sélectionnez l'icône pour lancer le processus d'authentification. Google demande à l'utilisateur de se connecter et d'autoriser l'application GitLab. Si tout se passe bien, l'utilisateur est redirigé vers GitLab et est connecté.
