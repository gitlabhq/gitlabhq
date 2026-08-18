---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Utiliser le gem Generic OAuth2 comme fournisseur d'authentification OAuth 2.0"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

> [!note]
> Si votre fournisseur prend en charge la spécification OpenID, vous devez utiliser [`omniauth-openid-connect`](../administration/auth/oidc.md) comme fournisseur d'authentification.

Le [gem `omniauth-oauth2-generic`](https://gitlab.com/satorix/omniauth-oauth2-generic) permet l'authentification unique (SSO) entre GitLab et votre fournisseur OAuth 2.0, ou tout fournisseur OAuth 2.0 compatible avec ce gem.

Cette stratégie permet la configuration du processus SSO OmniAuth suivant :

1. La stratégie dirige le client vers votre URL d'autorisation (**configurable**), avec l'identifiant et la clé spécifiés.
1. Le fournisseur OAuth 2.0 gère l'authentification de la requête, de l'utilisateur et (optionnellement) l'autorisation d'accès au profil de l'utilisateur.
1. Le fournisseur OAuth 2.0 redirige le client vers GitLab où la stratégie récupère le jeton d'accès.
1. La stratégie demande les informations utilisateur depuis une URL de « profil utilisateur » **configurable** en utilisant le jeton d'accès.
1. La stratégie analyse les informations utilisateur de la réponse en utilisant un format **configurable**.
1. GitLab trouve ou crée l'utilisateur retourné et l'authentifie.

Cette stratégie :

- Ne peut être utilisée que pour l'authentification unique et ne fournit pas d'autre accès accordé par un fournisseur OAuth 2.0. Par exemple, l'importation de projets ou d'utilisateurs.
- Ne prend en charge que le flow Authorization Grant, qui est le plus courant pour les applications client-serveur comme GitLab.
- Ne peut pas récupérer les informations utilisateur depuis plus d'une URL.
- Ne peut pas récupérer les informations utilisateur depuis le jeton d'accès au format JWT.
- N'a pas été testé avec des formats d'informations utilisateur autres que JSON.

## Configurer le fournisseur OAuth 2.0 {#configure-the-oauth-20-provider}

Pour configurer le fournisseur :

1. Enregistrez votre application auprès du fournisseur OAuth 2.0 avec lequel vous souhaitez vous authentifier.

   L'URI de redirection que vous fournissez lors de l'enregistrement de l'application doit être :

   ```plaintext
   http://your-gitlab.host.com/users/auth/oauth2_generic/callback
   ```

   Vous devriez maintenant pouvoir obtenir un ID client et un secret client. L'emplacement de ces informations varie selon le fournisseur. Cela peut également être appelé ID d'application et secret d'application.
1. Sur votre serveur GitLab, effectuez les étapes suivantes.

   {{< tabs >}}

   {{< tab title="Paquet Linux (Omnibus)" >}}

   1. Configurez les [paramètres communs](omniauth.md#configure-common-settings) pour ajouter `oauth2_generic` comme fournisseur d'authentification unique. Cela active le provisionnement de compte Just-In-Time pour les utilisateurs qui n'ont pas de compte GitLab existant.
   1. Modifiez `/etc/gitlab/gitlab.rb` pour ajouter la configuration de votre fournisseur. Par exemple :

      ```ruby
      gitlab_rails['omniauth_providers'] = [
        {
          name: "oauth2_generic",
          label: "Provider name", # optional label for login button, defaults to "Oauth2 Generic"
          app_id: "<your_app_client_id>",
          app_secret: "<your_app_client_secret>",
          args: {
            client_options: {
              site: "<your_auth_server_url>",
              user_info_url: "/oauth2/v1/userinfo",
              authorize_url: "/oauth2/v1/authorize",
              token_url: "/oauth2/v1/token"
            },
            user_response_structure: {
              root_path: [],
              id_path: ["sub"],
              attributes: {
                email: "email",
                name: "name"
              }
            },
            authorize_params: {
              scope: "openid profile email"
            },
            strategy_class: "OmniAuth::Strategies::OAuth2Generic"
          }
        }
      ]
      ```

   1. Enregistrez le fichier et reconfigurez GitLab :

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   {{< /tab >}}

   {{< tab title="Chart Helm (Kubernetes)" >}}

   1. Configurez les [paramètres communs](omniauth.md#configure-common-settings) pour ajouter `oauth2_generic` comme fournisseur d'authentification unique. Cela active le provisionnement de compte Just-In-Time pour les utilisateurs qui n'ont pas de compte GitLab existant.
   1. Exportez les valeurs Helm :

      ```shell
      helm get values gitlab > gitlab_values.yaml
      ```

   1. Placez le contenu suivant dans un fichier nommé `oauth2_generic.yaml` à utiliser comme [Secret Kubernetes](https://docs.gitlab.com/charts/charts/globals/#providers) :

      ```yaml
      name: "oauth2_generic"
      label: "Provider name" # optional label for login button defaults to "Oauth2 Generic"
      app_id: "<your_app_client_id>"
      app_secret: "<your_app_client_secret>"
      args:
        client_options:
          site: "<your_auth_server_url>"
          user_info_url: "/oauth2/v1/userinfo"
          authorize_url: "/oauth2/v1/authorize"
          token_url: "/oauth2/v1/token"
        user_response_structure:
          root_path: []
          id_path: ["sub"]
          attributes:
            email: "email"
            name: "name"
        authorize_params:
          scope: "openid profile email"
        strategy_class: "OmniAuth::Strategies::OAuth2Generic"
      ```

   1. Créez le Secret Kubernetes :

      ```shell
      kubectl create secret generic -n <namespace> gitlab-oauth2-generic --from-file=provider=oauth2_generic.yaml
      ```

   1. Modifiez `gitlab_values.yaml` et ajoutez la configuration du fournisseur :

      ```yaml
      global:
        appConfig:
          omniauth:
            providers:
              - secret: gitlab-oauth2-generic
      ```

   1. Enregistrez le fichier et appliquez les nouvelles valeurs :

      ```shell
      helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
      ```

   {{< /tab >}}

   {{< tab title="Auto-compilée (source)" >}}

   1. Configurez les [paramètres communs](omniauth.md#configure-common-settings) pour ajouter `oauth2_generic` comme fournisseur d'authentification unique. Cela active le provisionnement de compte Just-In-Time pour les utilisateurs qui n'ont pas de compte GitLab existant.
   1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

      ```yaml
      production: &base
        omniauth:
          providers:
            - { name: "oauth2_generic",
                label: "Provider name", # optional label for login button, defaults to "Oauth2 Generic"
                app_id: "<your_app_client_id>",
                app_secret: "<your_app_client_secret>",
                args: {
                  client_options: {
                    site: "<your_auth_server_url>",
                    user_info_url: "/oauth2/v1/userinfo",
                    authorize_url: "/oauth2/v1/authorize",
                    token_url: "/oauth2/v1/token"
                  },
                  user_response_structure: {
                    root_path: [],
                    id_path: ["sub"],
                    attributes: {
                      email: "email",
                      name: "name"
                    }
                  },
                  authorize_params: {
                    scope: "openid profile email"
                  },
                  strategy_class: "OmniAuth::Strategies::OAuth2Generic"
                }
              }
      ```

   1. Enregistrez le fichier et redémarrez GitLab :

      ```shell
      # For systems running systemd
      sudo systemctl restart gitlab.target

      # For systems running SysV init
      sudo service gitlab restart
      ```

   {{< /tab >}}

   {{< /tabs >}}

Sur la page de connexion, une nouvelle icône devrait maintenant apparaître sous le formulaire de connexion habituel. Sélectionnez cette icône pour démarrer le processus d'authentification de votre fournisseur. Cela redirige le navigateur vers la page d'authentification de votre fournisseur OAuth 2.0. Si tout se passe bien, vous êtes redirigé vers votre instance GitLab et connecté.
