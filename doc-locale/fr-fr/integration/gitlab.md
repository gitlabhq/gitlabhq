---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Intégrer votre serveur à GitLab.com
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Importez des projets depuis GitLab.com et connectez-vous à votre instance GitLab avec votre compte GitLab.com.

Pour activer le fournisseur OmniAuth de GitLab.com, vous devez enregistrer votre application auprès de GitLab.com. GitLab.com génère un identifiant d'application et une clé secrète que vous pouvez utiliser.

1. Connectez-vous à GitLab.com.
1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la barre latérale gauche, sélectionnez **Accès** > **Applications**.
1. Renseignez les informations requises pour **Ajouter une nouvelle application**.
   - Nom : vous pouvez choisir n'importe quel nom. Pensez à quelque chose comme `<Organization>'s GitLab` ou `<Your Name>'s GitLab` ou tout autre nom descriptif.
   - URI de redirection :

     ```plaintext
     # You can also use a non-SSL URL, but you should use SSL URLs.
     https://your-gitlab.example.com/import/gitlab/callback
     https://your-gitlab.example.com/users/auth/gitlab/callback
     ```

   Le premier lien est requis pour l'importateur et le second pour l'authentification.

   Si vous :

   - Si vous prévoyez d'utiliser l'importateur, vous pouvez laisser les portées telles quelles.
   - Si vous souhaitez uniquement utiliser cette application pour l'authentification, vous devriez utiliser un ensemble de portées plus restreint. `read_user` est suffisant.

1. Sélectionnez **Enregistrer l'application**.
1. Vous devriez maintenant voir un **Identifiant de l'application** et un **Secret**. Gardez cette page ouverte pendant que vous poursuivez la configuration.
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

1. Configurez les [paramètres communs](omniauth.md#configure-common-settings) pour ajouter `gitlab` en tant que fournisseur d'authentification unique. Cela active le provisionnement de compte Just-In-Time pour les utilisateurs qui ne disposent pas encore d'un compte GitLab.
1. Ajoutez la configuration du fournisseur :

   Pour les installations avec le package Linux s'authentifiant auprès de **GitLab.com** :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "gitlab",
       # label: "Provider name", # optional label for login button, defaults to "GitLab.com"
       app_id: "YOUR_APP_ID",
       app_secret: "YOUR_APP_SECRET",
       args: { scope: "read_user" } # optional: defaults to the scopes of the application
     }
   ]
   ```

   Ou, pour les installations avec le package Linux s'authentifiant auprès d'une instance GitLab différente :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "gitlab",
       label: "Provider name", # optional label for login button, defaults to "GitLab.com"
       app_id: "YOUR_APP_ID",
       app_secret: "YOUR_APP_SECRET",
       args: { scope: "read_user", # optional: defaults to the scopes of the application
               client_options: { site: "https://gitlab.example.com" } }
     }
   ]
   ```

   Pour les installations compilées manuellement s'authentifiant auprès de **GitLab.com** :

   ```yaml
   - { name: 'gitlab',
       # label: 'Provider name', # optional label for login button, defaults to "GitLab.com"
       app_id: 'YOUR_APP_ID',
       app_secret: 'YOUR_APP_SECRET',
   ```

   Ou, pour les installations compilées manuellement s'authentifiant auprès d'une instance GitLab différente :

   ```yaml
   - { name: 'gitlab',
       label: 'Provider name', # optional label for login button, defaults to "GitLab.com"
       app_id: 'YOUR_APP_ID',
       app_secret: 'YOUR_APP_SECRET',
       args: { "client_options": { "site": 'https://gitlab.example.com' } }
   ```

   > [!note]
   > Dans GitLab 15.1 et versions antérieures, le paramètre `site` requiert un suffixe `/api/v4`. Vous devez supprimer ce suffixe après la mise à niveau vers GitLab 15.2 ou une version ultérieure.
1. Remplacez `'YOUR_APP_ID'` par l'identifiant d'application figurant sur la page de l'application GitLab.com.
1. Remplacez `'YOUR_APP_SECRET'` par le secret figurant sur la page de l'application GitLab.com.
1. Enregistrez le fichier de configuration.
1. Appliquez ces modifications en utilisant la méthode appropriée :
   - Pour les installations avec le package Linux, [reconfigurez GitLab](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation).
   - Pour les installations compilées manuellement, [redémarrez GitLab](../administration/restart_gitlab.md#self-compiled-installations).

Sur la page de connexion, une icône GitLab.com devrait désormais apparaître à la suite du formulaire de connexion habituel. Sélectionnez l'icône pour lancer le processus d'authentification. GitLab.com invite l'utilisateur à se connecter et à autoriser l'application GitLab. Si tout se passe bien, l'utilisateur est redirigé vers votre instance GitLab et est connecté.

## Réduire les privilèges d'accès lors de la connexion {#reduce-access-privileges-on-sign-in}

{{< history >}}

- Introduit dans GitLab 14.8 [avec un feature flag](../administration/feature_flags/_index.md) nommé `omniauth_login_minimal_scopes`. Désactivés par défaut.
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/351331) dans GitLab 14.9.
- [Feature flag `omniauth_login_minimal_scopes`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/83453) supprimé dans GitLab 15.2

{{< /history >}}

Si vous utilisez une instance GitLab pour l'authentification, vous pouvez réduire les droits d'accès lorsqu'une application OAuth est utilisée pour la connexion.

Toute application OAuth peut indiquer l'objectif de l'application avec le paramètre d'autorisation : `gl_auth_type=login`. Si l'application est configurée avec `api` ou `read_api`, le jeton d'accès est émis avec `read_user` pour la connexion, car aucune autorisation supérieure n'est nécessaire.

Le client OAuth GitLab est configuré pour transmettre ce paramètre, mais d'autres applications peuvent également le transmettre.
