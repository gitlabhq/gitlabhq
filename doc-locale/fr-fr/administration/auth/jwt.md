---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Utiliser JWT comme fournisseur d'authentification"
description: "Configurer le SSO basé sur JWT dans GitLab avec le provisionnement d'utilisateurs Just-In-Time"
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Pour activer le fournisseur JWT OmniAuth, vous devez enregistrer votre application auprès de JWT. JWT vous fournit une clé secrète à utiliser.

1. Sur votre serveur GitLab, ouvrez le fichier de configuration.

   Pour les installations avec le package Linux :

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   Pour les installations compilées à partir des sources :

   ```shell
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

1. Configurez les [paramètres communs](../../integration/omniauth.md#configure-common-settings) pour ajouter `jwt` en tant que fournisseur d'authentification unique. Cela active le provisionnement de compte Just-In-Time pour les utilisateurs qui ne possèdent pas encore de compte GitLab.
1. Ajoutez la configuration du fournisseur.

   Pour les installations avec le package Linux :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: "jwt",
       label: "Provider name", # optional label for login button, defaults to "Jwt"
       args: {
         secret: "YOUR_APP_SECRET",
         algorithm: "HS256", # Supported algorithms: "RS256", "RS384", "RS512", "ES256", "ES384", "ES512", "HS256", "HS384", "HS512"
         uid_claim: "email",
         required_claims: ["name", "email"],
         info_map: { name: "name", email: "email" },
         auth_url: "https://example.com/",
         valid_within: 3600 # 1 hour
       }
     }
   ]
   ```

   Pour les installations compilées à partir des sources :

   ```yaml
   - { name: 'jwt',
       label: 'Provider name', # optional label for login button, defaults to "Jwt"
       args: {
         secret: 'YOUR_APP_SECRET',
         algorithm: 'HS256', # Supported algorithms: 'RS256', 'RS384', 'RS512', 'ES256', 'ES384', 'ES512', 'HS256', 'HS384', 'HS512'
         uid_claim: 'email',
         required_claims: ['name', 'email'],
         info_map: { name: 'name', email: 'email' },
         auth_url: 'https://example.com/',
         valid_within: 3600 # 1 hour
       }
     }
   ```

   Pour plus d'informations sur chaque option de configuration, consultez la [documentation d'utilisation d'OmniAuth JWT](https://github.com/mbleigh/omniauth-jwt#usage).

   > [!warning]
   > Une configuration incorrecte de ces paramètres peut entraîner une instance non sécurisée.

1. Remplacez `YOUR_APP_SECRET` par le secret client et définissez `auth_url` sur votre URL de redirection.
1. Enregistrez le fichier de configuration.
1. Pour que les modifications prennent effet, si vous avez :
   - Utilisé le package Linux pour installer GitLab, [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
   - Compilé votre installation GitLab à partir des sources, [redémarrez GitLab](../restart_gitlab.md#self-compiled-installations).

Sur la page de connexion, une icône JWT devrait maintenant apparaître sous le formulaire de connexion habituel. Sélectionnez l'icône pour démarrer le processus d'authentification. JWT demande à l'utilisateur de se connecter et d'autoriser l'application GitLab. Si tout se passe bien, l'utilisateur est redirigé vers GitLab et connecté.
