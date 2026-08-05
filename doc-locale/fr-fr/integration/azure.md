---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Utiliser Microsoft Azure comme fournisseur d'authentification OAuth 2.0"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Vous pouvez activer le fournisseur OmniAuth Microsoft Azure OAuth 2.0 et vous connecter à GitLab avec vos identifiants Microsoft Azure.

> [!note]
> Si vous intégrez GitLab avec Azure/Entra ID pour la première fois, configurez le [protocole OpenID Connect](../administration/auth/oidc.md#configure-microsoft-azure), qui utilise le point de terminaison de la plateforme d'identité Microsoft (v2.0).

## Migrer vers la configuration OpenID Connect générique {#migrate-to-generic-openid-connect-configuration}

Dans GitLab 17.0 et versions ultérieures, les instances utilisant `azure_oauth2` doivent migrer vers la configuration OpenID Connect générique. Pour plus d'informations, consultez [Migration vers le protocole OpenID Connect](../administration/auth/oidc.md#migrate-to-generic-openid-connect-configuration).

## Enregistrer une application Azure {#register-an-azure-application}

Pour activer le fournisseur OmniAuth Microsoft Azure OAuth 2.0, vous devez enregistrer une application Azure et obtenir un ID client et une clé secrète.

1. Connectez-vous au [portail Azure](https://portal.azure.com).
1. Si vous avez plusieurs locataires Azure Active Directory, basculez vers le locataire souhaité. Notez l'ID du locataire.
1. [Enregistrez une application](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app) et fournissez les informations suivantes :
   - L'URI de redirection, qui nécessite l'URL du callback Azure OAuth de votre installation GitLab. `https://gitlab.example.com/users/auth/azure_activedirectory_v2/callback`.
   - Le type d'application, qui doit être défini sur **Web**.
1. Enregistrez l'ID client et le secret client. Le secret client n'est affiché qu'une seule fois.

   Si nécessaire, vous pouvez [créer un nouveau secret d'application](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal#option-3-create-a-new-client-secret).

`client ID` et `client secret` sont des termes associés à OAuth 2.0. Dans certaines documentations Microsoft, ces termes sont désignés par `Application ID` et `Application Secret`.

## Ajouter des autorisations d'API (portées) {#add-api-permissions-scopes}

Après avoir créé l'application, [configurez-la pour exposer une API web](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-configure-app-expose-web-apis). Ajoutez les autorisations déléguées suivantes sous l'API Microsoft Graph :

- `email`
- `openid`
- `profile`

Vous pouvez également ajouter l'autorisation d'application `User.Read.All`.

## Activer Microsoft OAuth dans GitLab {#enable-microsoft-oauth-in-gitlab}

> [!note]
> Pour les nouveaux projets, il est recommandé d'utiliser le [protocole OpenID Connect](../administration/auth/oidc.md#configure-microsoft-azure), qui utilise le point de terminaison de la plateforme d'identité Microsoft (v2.0).

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

1. Configurez les [paramètres communs](omniauth.md#configure-common-settings) pour ajouter `azure_activedirectory_v2` en tant que fournisseur d'authentification unique. Cela active le provisionnement de compte Just-In-Time pour les utilisateurs qui ne possèdent pas encore de compte GitLab.
1. Ajoutez la configuration du fournisseur. Remplacez `<client_id>`, `<client_secret>` et `<tenant_id>` par les valeurs obtenues lors de l'enregistrement de l'application Azure.

   - Pour les installations de paquets Linux :

     ```ruby
     gitlab_rails['omniauth_providers'] = [
       {
         "name" => "azure_activedirectory_v2",
         "label" => "Provider name", # optional label for login button, defaults to "Azure AD v2"
         "args" => {
           "client_id" => "<client_id>",
           "client_secret" => "<client_secret>",
           "tenant_id" => "<tenant_id>",
         }
       }
     ]

     ```

   - Pour les [clouds Azure alternatifs](https://learn.microsoft.com/en-us/entra/identity-platform/authentication-national-cloud), configurez `base_azure_url` dans la section `args`. Par exemple, pour Azure Government Community Cloud (GCC) :

     ```ruby
     gitlab_rails['omniauth_providers'] = [
       {
         "name" => "azure_activedirectory_v2",
         "label" => "Provider name", # optional label for login button, defaults to "Azure AD v2"
         "args" => {
           "client_id" => "<client_id>",
           "client_secret" => "<client_secret>",
           "tenant_id" => "<tenant_id>",
           "base_azure_url" => "https://login.microsoftonline.us"
         }
       }
     ]
     ```

   - Pour les installations compilées manuellement :

     Pour le point de terminaison v2.0 :

     ```yaml
     - { name: 'azure_activedirectory_v2',
         label: 'Provider name', # optional label for login button, defaults to "Azure AD v2"
         args: { client_id: "<client_id>",
                 client_secret: "<client_secret>",
                 tenant_id: "<tenant_id>" } }
     ```

     Pour les [clouds Azure alternatifs](https://learn.microsoft.com/en-us/entra/identity-platform/authentication-national-cloud), configurez `base_azure_url` dans la section `args`. Par exemple, pour Azure Government Community Cloud (GCC) :

     ```yaml
     - { name: 'azure_activedirectory_v2',
         label: 'Provider name', # optional label for login button, defaults to "Azure AD v2"
         args: { client_id: "<client_id>",
                 client_secret: "<client_secret>",
                 tenant_id: "<tenant_id>",
                 base_azure_url: "https://login.microsoftonline.us" } }
     ```

   Vous pouvez également ajouter facultativement le paramètre `scope` pour les [portées OAuth 2.0](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow) dans la section `args`. La valeur par défaut est `openid profile email`.

1. Enregistrez le fichier de configuration.
1. [Reconfigurez GitLab](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation) si vous avez effectué l'installation avec le package Linux, ou [redémarrez GitLab](../administration/restart_gitlab.md#self-compiled-installations) si vous avez compilé l'installation manuellement.
1. Actualisez la page de connexion de GitLab. Une icône Microsoft devrait s'afficher sous le formulaire de connexion.
1. Sélectionnez l'icône. Connectez-vous à Microsoft et autorisez l'application GitLab.

Consultez [Activer OmniAuth pour un utilisateur existant](omniauth.md#enable-omniauth-for-an-existing-user) pour obtenir des informations sur la façon dont les utilisateurs GitLab existants peuvent connecter leurs nouveaux comptes Azure AD.

## Dépannage {#troubleshooting}

### Message de bannière lors de la connexion : Extern UID has already been taken {#user-sign-in-banner-message-extern-uid-has-already-been-taken}

Lors de la connexion, vous pourriez obtenir une erreur indiquant `Extern UID has already been taken`.

Pour résoudre ce problème, utilisez la [console Rails](../administration/operations/rails_console.md#starting-a-rails-console-session) pour vérifier s'il existe un utilisateur lié au compte :

1. Trouvez le `extern_uid` :

   ```ruby
   id = Identity.where(extern_uid: '<extern_uid>')
   ```

1. Affichez le contenu pour trouver le nom d'utilisateur associé à ce `extern_uid` :

   ```ruby
   pp id
   ```

Si le `extern_uid` est associé à un compte, vous pouvez utiliser le nom d'utilisateur pour vous connecter.

Si le `extern_uid` n'est associé à aucun nom d'utilisateur, cela peut être dû à une erreur de suppression ayant généré un enregistrement fantôme.

Exécutez la commande suivante pour supprimer l'identité et libérer le `extern uid` :

```ruby
 Identity.find('<id>').delete
```
