---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Utiliser GitHub comme fournisseur d'authentification OAuth 2.0"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Vous pouvez intégrer votre instance GitLab à GitHub.com et GitHub Enterprise. Vous pouvez importer des projets depuis GitHub ou vous connecter à GitLab avec vos identifiants GitHub.

## Créer une application OAuth dans GitHub {#create-an-oauth-app-in-github}

Pour activer le fournisseur GitHub OmniAuth, vous avez besoin d'un identifiant client OAuth 2.0 et d'un secret client provenant de GitHub :

1. Connectez-vous à GitHub.
1. [Créez une application OAuth](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/creating-an-oauth-app) et fournissez les informations suivantes :
   - L'URL de votre instance GitLab, telle que `https://gitlab.example.com`.
   - L'URL de rappel d'autorisation, telle que `https://gitlab.example.com/users/auth`. Indiquez le numéro de port si votre instance GitLab utilise un port non standard.

### Vérifier les failles de sécurité {#check-for-security-vulnerabilities}

Pour certaines intégrations, la [redirection secrète OAuth 2](https://oauth.net/advisories/2014-1-covert-redirect/) peut compromettre les comptes GitLab. Pour atténuer cette vulnérabilité, ajoutez `/users/auth` à l'URL de rappel d'autorisation.

Cependant, GitHub ne valide pas la partie sous-domaine du `redirect_uri`. Par conséquent, une prise de contrôle de sous-domaine, une attaque XSS ou une redirection ouverte sur n'importe quel sous-domaine de votre site web pourrait permettre l'attaque par redirection secrète.

## Activer GitHub OAuth dans GitLab {#enable-github-oauth-in-gitlab}

1. Configurez les [paramètres communs](omniauth.md#configure-common-settings) pour ajouter `github` en tant que fournisseur d'authentification unique. Cela active le provisionnement de compte Just-In-Time pour les utilisateurs qui ne disposent pas d'un compte GitLab existant.
1. Modifiez le fichier de configuration GitLab en utilisant les informations suivantes :

   | Paramètre GitHub | Valeur dans le fichier de configuration GitLab | Description             |
   |----------------|----------------------------------------|-------------------------|
   | ID client      | `YOUR_APP_ID`                          | ID client OAuth 2.0     |
   | Secret client  | `YOUR_APP_SECRET`                      | Secret client OAuth 2.0 |
   | URL            | `https://github.example.com/`          | URL de déploiement GitHub   |

   - Pour les installations de paquets Linux :

     1. Ouvrez le fichier `/etc/gitlab/gitlab.rb`.

        Pour GitHub.com, mettez à jour la section suivante :

        ```ruby
        gitlab_rails['omniauth_providers'] = [
          {
            name: "github",
            # label: "Provider name", # optional label for login button, defaults to "GitHub"
            app_id: "YOUR_APP_ID",
            app_secret: "YOUR_APP_SECRET",
            args: { scope: "user:email" }
          }
        ]
        ```

        Pour GitHub Enterprise, mettez à jour la section suivante et remplacez `https://github.example.com/` par votre URL GitHub :

        ```ruby
        gitlab_rails['omniauth_providers'] = [
          {
            name: "github",
            # label: "Provider name", # optional label for login button, defaults to "GitHub"
            app_id: "YOUR_APP_ID",
            app_secret: "YOUR_APP_SECRET",
            url: "https://github.example.com/",
            args: { scope: "user:email" }
          }
        ]
        ```

     1. Enregistrez le fichier et [reconfigurez](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation) GitLab.

   - Pour les installations compilées manuellement :

     1. Ouvrez le fichier `config/gitlab.yml`.

        Pour GitHub.com, mettez à jour la section suivante :

        ```yaml
        - { name: 'github',
            # label: 'Provider name', # optional label for login button, defaults to "GitHub"
            app_id: 'YOUR_APP_ID',
            app_secret: 'YOUR_APP_SECRET',
            args: { scope: 'user:email' } }
        ```

        Pour GitHub Enterprise, mettez à jour la section suivante et remplacez `https://github.example.com/` par votre URL GitHub :

        ```yaml
        - { name: 'github',
            # label: 'Provider name', # optional label for login button, defaults to "GitHub"
            app_id: 'YOUR_APP_ID',
            app_secret: 'YOUR_APP_SECRET',
            url: "https://github.example.com/",
            args: { scope: 'user:email' } }
        ```

     1. Enregistrez le fichier et [redémarrez](../administration/restart_gitlab.md#self-compiled-installations) GitLab.

1. Actualisez la page de connexion de GitLab. Une icône GitHub devrait s'afficher sous le formulaire de connexion.
1. Sélectionnez l'icône. Connectez-vous à GitHub et autorisez l'application GitLab.

## Dépannage {#troubleshooting}

### Les imports depuis GitHub Enterprise avec un certificat auto-signé échouent {#imports-from-github-enterprise-with-a-self-signed-certificate-fail}

Lorsque vous importez des projets depuis GitHub Enterprise à l'aide d'un certificat auto-signé, les imports échouent.

Pour résoudre ce problème, vous devez désactiver la vérification SSL :

1. Définissez `verify_ssl` sur `false` dans le fichier de configuration.

   - Pour les installations de paquets Linux :

     ```ruby
     gitlab_rails['omniauth_providers'] = [
       {
         name: "github",
         # label: "Provider name", # optional label for login button, defaults to "GitHub"
         app_id: "YOUR_APP_ID",
         app_secret: "YOUR_APP_SECRET",
         url: "https://github.example.com/",
         verify_ssl: false,
         args: { scope: "user:email" }
       }
     ]
     ```

   - Pour les installations compilées manuellement :

     ```yaml
     - { name: 'github',
         # label: 'Provider name', # optional label for login button, defaults to "GitHub"
         app_id: 'YOUR_APP_ID',
         app_secret: 'YOUR_APP_SECRET',
         url: "https://github.example.com/",
         verify_ssl: false,
         args: { scope: 'user:email' } }
     ```

1. Remplacez l'option Git globale `sslVerify` par `false` sur le serveur GitLab.

   - Pour les installations du package Linux exécutant [GitLab 15.3](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6800) et versions ultérieures :

     ```ruby
     gitaly['gitconfig'] = [
        {key: "http.sslVerify", value: "false"},
     ]
     ```

   - Pour les installations du package Linux exécutant GitLab 15.2 et versions antérieures (méthode héritée) :

     ```ruby
     omnibus_gitconfig['system'] = { "http" => ["sslVerify = false"] }
     ```

   - Pour les installations compilées manuellement exécutant [GitLab 15.3](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6800) et versions ultérieures, modifiez la configuration de Gitaly (`gitaly.toml`) :

     ```toml
     [[git.config]]
     key = "http.sslVerify"
     value = "false"
     ```

   - Pour les installations compilées manuellement exécutant GitLab 15.2 et versions antérieures (méthode héritée) :

     ```shell
     git config --global http.sslVerify false
     ```

1. [Reconfigurez GitLab](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation) si vous avez installé GitLab à l'aide du package Linux, ou [redémarrez GitLab](../administration/restart_gitlab.md#self-compiled-installations) si vous avez compilé votre installation manuellement.

### La connexion via GitHub Enterprise renvoie une erreur 500 {#signing-in-using-github-enterprise-returns-a-500-error}

Cette erreur peut survenir en raison d'un problème de connectivité réseau entre votre instance GitLab et GitHub Enterprise.

Pour vérifier l'existence d'un problème de connectivité :

1. Accédez au [`production.log`](../administration/logs/_index.md#productionlog) sur votre serveur GitLab et recherchez l'erreur suivante :

   ``` plaintext
   Faraday::ConnectionFailed (execution expired)
   ```

1. [Démarrez la console Rails](../administration/operations/rails_console.md#starting-a-rails-console-session) et exécutez les commandes suivantes. Remplacez `<github_url>` par l'URL de votre instance GitHub Enterprise :

   ```ruby
   uri = URI.parse("https://<github_url>") # replace `GitHub-URL` with the real one here
   http = Net::HTTP.new(uri.host, uri.port)
   http.use_ssl = true
   http.verify_mode = 1
   response = http.request(Net::HTTP::Get.new(uri.request_uri))
   ```

1. Si une erreur `execution expired` similaire est renvoyée, cela confirme que l'erreur est due à un problème de connectivité. Assurez-vous que le serveur GitLab peut accéder à votre instance GitHub Enterprise.

### La connexion avec votre compte GitHub sans compte GitLab préexistant n'est pas autorisée {#signing-in-using-your-github-account-without-a-pre-existing-gitlab-account-is-not-allowed}

Lorsque vous vous connectez à GitLab, vous obtenez l'erreur suivante :

```plaintext
Signing in using your GitHub account without a pre-existing
GitLab account is not allowed. Create a GitLab account first,
and then connect it to your GitHub account
```

Pour résoudre ce problème, vous devez activer la connexion via GitHub dans GitLab :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la barre latérale gauche, sélectionnez **Accès** > **Mot de passe et authentification**.
1. Dans la section **Connexion via un service tiers**, sélectionnez **Se connecter à GitHub**.
