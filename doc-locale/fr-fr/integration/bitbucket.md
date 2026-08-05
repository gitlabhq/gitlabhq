---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Intégrer votre serveur GitLab à Bitbucket Cloud
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Vous pouvez configurer Bitbucket.org en tant que fournisseur OAuth 2.0 pour utiliser vos identifiants Bitbucket.org afin de vous connecter à GitLab. Vous pouvez également importer vos projets depuis Bitbucket.org.

- Pour utiliser Bitbucket.org comme fournisseur OmniAuth, suivez la section [Fournisseur OmniAuth Bitbucket](#use-bitbucket-as-an-oauth-20-authentication-provider).
- Pour importer des projets depuis Bitbucket, suivez à la fois les sections [Fournisseur OmniAuth Bitbucket](#use-bitbucket-as-an-oauth-20-authentication-provider) et [Importation de projets Bitbucket](#bitbucket-project-import).

## Utiliser Bitbucket comme fournisseur d'authentification OAuth 2.0 {#use-bitbucket-as-an-oauth-20-authentication-provider}

Pour activer le fournisseur OmniAuth Bitbucket, vous devez enregistrer votre application auprès de Bitbucket.org. Bitbucket génère un identifiant d'application et une clé secrète que vous pouvez utiliser.

1. Connectez-vous à [Bitbucket.org](https://bitbucket.org).
1. Accédez aux paramètres de votre compte utilisateur (**Bitbucket settings**) ou aux paramètres d'une équipe (**Manage team**), selon la façon dont vous souhaitez enregistrer l'application. Peu importe si l'application est enregistrée en tant qu'individu ou en tant qu'équipe, c'est entièrement à votre discrétion.
1. Dans le menu de gauche, sous **Access Management**, sélectionnez **OAuth**.
1. Sélectionnez **Add consumer**.
1. Renseignez les informations requises :

   - **Nom** : ce champ peut contenir n'importe quelle valeur. Pensez à quelque chose comme `<Organization>'s GitLab` ou `<Your Name>'s GitLab` ou autre chose de descriptif.
   - **Application description** : Facultatif. Remplissez ce champ si vous le souhaitez.
   - **URL de retour** : (Obligatoire dans les versions 8.15 et supérieures de GitLab) L'URL de votre installation GitLab, par exemple `https://gitlab.example.com/users/auth`. Laisser ce champ vide entraîne un message `Invalid redirect_uri`.

     > [!warning]
     > Pour contribuer à prévenir une attaque de type [redirection secrète OAuth 2](https://oauth.net/advisories/2014-1-covert-redirect/), ajoutez `/users/auth` à la fin de votre URL de retour d'autorisation Bitbucket. Vous devez inclure ce point de terminaison d'autorisation pour vous authentifier auprès de Bitbucket et importer des données depuis les dépôts Bitbucket.

   - **URL** : L'URL de votre installation GitLab, par exemple `https://gitlab.example.com`.

1. Accordez au moins les autorisations suivantes :

   - **Compte** : `Email`, `Read`
   - **Projets** : `Read`
   - **Dépôts** : `Read`
   - **Pull Requests** : `Read`
   - **Tickets** : `Read`
   - **Wikis** : `Read and write`

1. Sélectionnez **Enregistrer**.
1. Sélectionnez le consommateur OAuth que vous venez de créer. Vous devriez maintenant voir une **Clé** et un **Secret** dans la liste des consommateurs OAuth. Gardez cette page ouverte pendant que vous poursuivez la configuration.
1. Sur votre serveur GitLab, ouvrez le fichier de configuration :

   ```shell
   # For Omnibus packages
   sudo editor /etc/gitlab/gitlab.rb

   # For installations from source
   sudo -u git -H editor /home/git/gitlab/config/gitlab.yml
   ```

1. Ajoutez la configuration du fournisseur Bitbucket :

   Pour les installations de paquets Linux :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "bitbucket",
       # label: "Provider name", # optional label for login button, defaults to "Bitbucket"
       app_id: "<bitbucket_app_key>",
       app_secret: "<bitbucket_app_secret>",
       url: "https://bitbucket.org/"
     }
   ]
   ```

   Pour les installations compilées manuellement :

   ```yaml
   omniauth:
     enabled: true
     providers:
       - { name: 'bitbucket',
           # label: 'Provider name', # optional label for login button, defaults to "Bitbucket"
           app_id: '<bitbucket_app_key>',
           app_secret: '<bitbucket_app_secret>',
           url: 'https://bitbucket.org/'
         }
   ```

   Où `<bitbucket_app_key>` correspond à la **Clé** et `<bitbucket_app_secret>` au **Secret** de la page de l'application Bitbucket.
1. Enregistrez le fichier de configuration.
1. Pour que les modifications prennent effet, [reconfigurez GitLab](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation) si vous avez effectué l'installation à l'aide du package Linux, ou [redémarrez](../administration/restart_gitlab.md#self-compiled-installations) si vous avez compilé votre installation manuellement.

Sur la page de connexion, une icône Bitbucket devrait désormais apparaître sous le formulaire de connexion habituel. Sélectionnez l'icône pour lancer le processus d'authentification. Bitbucket demande à l'utilisateur de se connecter et d'autoriser l'application GitLab. En cas de succès, l'utilisateur est redirigé vers GitLab et connecté.

> [!note]
> Pour les architectures multi-nœuds, la configuration du fournisseur Bitbucket doit également être incluse sur les nœuds Sidekiq pour pouvoir importer des projets.

## Importation de projets Bitbucket {#bitbucket-project-import}

Une fois la configuration précédente effectuée, vous pouvez utiliser Bitbucket pour vous connecter à GitLab et [commencer à importer vos projets](../user/import/bitbucket_cloud.md).

Si vous souhaitez importer des projets depuis Bitbucket sans activer la connexion via Bitbucket, vous pouvez [désactiver les connexions dans la zone **Admin**](omniauth.md#enable-or-disable-sign-in-with-an-omniauth-provider-without-disabling-import-sources).
