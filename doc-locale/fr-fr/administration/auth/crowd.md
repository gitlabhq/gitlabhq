---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Utiliser Atlassian Crowd comme fournisseur d'authentification"
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Authentifiez-vous à GitLab en utilisant le fournisseur OmniAuth Atlassian Crowd. L'activation de ce fournisseur permet également l'authentification Crowd pour les requêtes Git-over-https.

## Configurer une nouvelle application Crowd {#configure-a-new-crowd-application}

1. Dans le menu supérieur, sélectionnez **Applications** > **Add application**.
1. Suivez les étapes de **Add application** en saisissant les informations appropriées.
1. Une fois terminé, sélectionnez **Add application**.

## Configurer GitLab {#configure-gitlab}

1. Sur votre serveur GitLab, ouvrez le fichier de configuration.

   - Installations avec le package Linux :

     ```shell
     sudo editor /etc/gitlab/gitlab.rb
     ```

   - Installations compilées depuis les sources :

     ```shell
     cd /home/git/gitlab

     sudo -u git -H editor config/gitlab.yml
     ```

1. Configurez les [paramètres communs](../../integration/omniauth.md#configure-common-settings) pour ajouter `crowd` en tant que fournisseur d'authentification unique. Cela active le provisionnement de compte juste-à-temps pour les utilisateurs qui ne possèdent pas encore de compte GitLab.

1. Ajoutez la configuration du fournisseur :

   - Installations avec le package Linux :

     ```ruby
       gitlab_rails['omniauth_providers'] = [
         {
           name: "crowd",
           args: {
             crowd_server_url: "CROWD_SERVER_URL",
             application_name: "YOUR_APP_NAME",
             application_password: "YOUR_APP_PASSWORD"
           }
         }
       ]
     ```

   - Installations compilées depuis les sources :

     ```yaml
        - { name: 'crowd',
            args: {
              crowd_server_url: 'CROWD_SERVER_URL',
              application_name: 'YOUR_APP_NAME',
              application_password: 'YOUR_APP_PASSWORD' } }
     ```

1. Remplacez `CROWD_SERVER_URL` par l'[URL de base de votre serveur Crowd](https://confluence.atlassian.com/crowdkb/how-to-change-the-crowd-base-url-245827278.html).
1. Remplacez `YOUR_APP_NAME` par le nom de l'application figurant sur la page des applications Crowd.
1. Remplacez `YOUR_APP_PASSWORD` par le mot de passe d'application que vous avez défini.
1. Enregistrez le fichier de configuration.
1. [Reconfigurez](../restart_gitlab.md#reconfigure-a-linux-package-installation) (installations avec le package Linux) ou [redémarrez](../restart_gitlab.md#self-compiled-installations) (installations compilées depuis les sources) pour que les modifications prennent effet.

Un onglet Crowd devrait maintenant apparaître dans le formulaire de connexion sur la page de connexion.

## Dépannage {#troubleshooting}

### Erreur : `could not authorize you from Crowd because invalid credentials` {#error-could-not-authorize-you-from-crowd-because-invalid-credentials}

Cette erreur se produit parfois lorsqu'un utilisateur tente de s'authentifier avec Crowd. L'administrateur Crowd doit consulter le fichier journal de Crowd pour connaître la cause exacte de ce message d'erreur.

Assurez-vous que les utilisateurs Crowd qui doivent se connecter à GitLab sont autorisés à accéder à l'[application](#configure-a-new-crowd-application) à l'**Authorization** Authorization. Cela peut être vérifié en essayant le « test d'authentification » pour Crowd (depuis la version 2.11).

![Paramètres d'étape d'autorisation dans Crowd](img/crowd_application_authorisation_v10_4.png)
