---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Utiliser AliCloud comme fournisseur d'authentification OmniAuth"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed

{{< /details >}}

Vous pouvez activer le fournisseur OmniAuth AliCloud OAuth 2.0 et vous connecter à GitLab à l'aide de votre compte AliCloud.

## Créer une application AliCloud {#create-an-alicloud-application}

Connectez-vous à la plateforme AliCloud et créez-y une application. AliCloud génère un ID client et une clé secrète que vous pourrez utiliser.

1. Connectez-vous à la [plateforme AliCloud](https://account.aliyun.com/login/login.htm).
1. Accédez à la [page de gestion des applications OAuth](https://ram.console.aliyun.com/applications).
1. Sélectionnez **Create Application**.
1. Renseignez les détails de l'application :

   - **Application Name** : ce champ peut contenir n'importe quelle valeur.
   - **Display Name** : ce champ peut contenir n'importe quelle valeur.
   - **URL de retour** : cette URL doit être formatée comme suit : `'GitLab instance URL' + '/users/auth/alicloud/callback'`. Par exemple, `http://test.gitlab.com/users/auth/alicloud/callback`.

   Sélectionnez **Enregistrer**.
1. Ajoutez des portées OAuth dans la page des détails de l'application :

   1. Dans la colonne **Application Name**, sélectionnez le nom de l'application que vous avez créée. La page des détails de l'application s'ouvre.
   1. Sous l'onglet **Application OAuth Scopes**, sélectionnez **Add OAuth Scopes**.
   1. Cochez les cases **aliuid** et **profile**.
   1. Sélectionnez **OK**.

   ![Portée OAuth AliCloud](img/alicloud_scope_v14_10.png)
1. Créez un secret dans la page des détails de l'application :

   1. Sous l'onglet **App Secrets**, sélectionnez **Create Secret**.
   1. Copiez la valeur SecretValue générée.

## Activer AliCloud OAuth dans GitLab {#enable-alicloud-oauth-in-gitlab}

1. Sur votre serveur GitLab, ouvrez le fichier de configuration.

   - Pour les installations de paquets Linux :

     ```shell
     sudo editor /etc/gitlab/gitlab.rb
     ```

   - Pour les installations compilées manuellement :

     ```shell
     cd /home/git/gitlab

     sudo -u git -H editor config/gitlab.yml
     ```

1. Configurez les [paramètres communs](omniauth.md#configure-common-settings) pour ajouter `alicloud` comme fournisseur d'authentification unique. Cela active le provisionnement de compte Just-In-Time pour les utilisateurs qui ne possèdent pas encore de compte GitLab.
1. Ajoutez la configuration du fournisseur. Remplacez `YOUR_APP_ID` par l'ID indiqué sur la page des détails de l'application et `YOUR_APP_SECRET` par la valeur **SecretValue** obtenue lors de l'enregistrement de l'application AliCloud.

   - Pour les installations de paquets Linux :

     ```ruby
       gitlab_rails['omniauth_providers'] = [
         {
           name: "alicloud",
           app_id: "YOUR_APP_ID",
           app_secret: "YOUR_APP_SECRET"
         }
       ]
     ```

   - Pour les installations compilées manuellement :

     ```yaml
     - { name: 'alicloud',
         app_id: 'YOUR_APP_ID',
         app_secret: 'YOUR_APP_SECRET' }
     ```

1. Enregistrez le fichier de configuration.
1. [Reconfigurer GitLab](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation) si vous avez effectué l'installation à l'aide du package Linux, ou [redémarrer GitLab](../administration/restart_gitlab.md#self-compiled-installations) si vous avez effectué l'installation depuis les sources.
