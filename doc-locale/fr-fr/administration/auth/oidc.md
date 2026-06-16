---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Utiliser OpenID Connect comme fournisseur d'authentification"
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Vous pouvez utiliser GitLab comme application cliente avec [OpenID Connect](https://openid.net/specs/openid-connect-core-1_0.html) en tant que fournisseur OmniAuth.

Pour activer le fournisseur OmniAuth OpenID Connect, vous devez enregistrer votre application auprès d'un fournisseur OpenID Connect. Le fournisseur OpenID Connect vous fournit les informations et le secret du client à utiliser.

1. Sur votre serveur GitLab, ouvrez le fichier de configuration.

   Pour les installations de packages Linux :

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   Pour les installations compilées manuellement :

   ```shell
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

1. Configurez les [paramètres communs](../../integration/omniauth.md#configure-common-settings) pour ajouter `openid_connect` comme fournisseur d'authentification unique. Cela active le provisionnement de compte juste-à-temps pour les utilisateurs qui n'ont pas de compte GitLab existant.

1. Ajoutez la configuration du fournisseur.

   Pour les installations de packages Linux :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "openid_connect", # do not change this parameter
       label: "Provider name", # optional label for login button, defaults to "Openid Connect"
       icon: "<custom_provider_icon>",
       args: {
         name: "openid_connect",
         scope: ["openid","profile","email"],
         response_type: "code",
         issuer: "<your_oidc_url>",
         discovery: true,
         client_auth_method: "query",
         uid_field: "<uid_field>",
         send_scope_to_token_endpoint: "false",
         pkce: true,
         client_options: {
           identifier: "<your_oidc_client_id>",
           secret: "<your_oidc_client_secret>",
           redirect_uri: "<your_gitlab_url>/users/auth/openid_connect/callback"
         }
       }
     }
   ]
   ```

   Pour les installations de packages Linux avec plusieurs fournisseurs d'identité :

   ```ruby
   { 'name' => 'openid_connect',
     'label' => '...',
     'icon' => '...',
     'args' => {
       'name' => 'openid_connect',
       'strategy_class': 'OmniAuth::Strategies::OpenIDConnect',
       'scope' => ['openid', 'profile', 'email'],
       'discovery' => true,
       'response_type' => 'code',
       'issuer' => 'https://...',
       'client_auth_method' => 'query',
       'uid_field' => '...',
       'client_options' => {
         `identifier`: "<your_oidc_client_id>",
         `secret`: "<your_oidc_client_secret>",
         'redirect_uri' => 'https://.../users/auth/openid_connect/callback'
      }
    }
   },
   { 'name' => 'openid_connect_2fa',
     'label' => '...',
     'icon' => '...',
     'args' => {
       'name' => 'openid_connect_2fa',
       'strategy_class': 'OmniAuth::Strategies::OpenIDConnect',
       'scope' => ['openid', 'profile', 'email'],
       'discovery' => true,
       'response_type' => 'code',
       'issuer' => 'https://...',
       'client_auth_method' => 'query',
       'uid_field' => '...',
       'client_options' => {
        ...
        'redirect_uri' => 'https://.../users/auth/openid_connect_2fa/callback'
      }
    }
   }
   ```

   Pour les installations compilées manuellement :

   ```yaml
     - { name: 'openid_connect', # do not change this parameter
         label: 'Provider name', # optional label for login button, defaults to "Openid Connect"
         icon: '<custom_provider_icon>',
         args: {
           name: 'openid_connect',
           scope: ['openid','profile','email'],
           response_type: 'code',
           issuer: '<your_oidc_url>',
           discovery: true,
           client_auth_method: 'query',
           uid_field: '<uid_field>',
           send_scope_to_token_endpoint: false,
           pkce: true,
           client_options: {
             identifier: '<your_oidc_client_id>',
             secret: '<your_oidc_client_secret>',
             redirect_uri: '<your_gitlab_url>/users/auth/openid_connect/callback'
           }
         }
       }
   ```

   > [!note]
   > Pour plus d'informations sur chaque option de configuration, reportez-vous à la [documentation d'utilisation d'OmniAuth OpenID Connect](https://github.com/omniauth/omniauth_openid_connect#usage) et à la [spécification OpenID Connect Core 1.0](https://openid.net/specs/openid-connect-core-1_0.html).

1. Pour la configuration du fournisseur, modifiez les valeurs du fournisseur pour les adapter à votre configuration client OpenID Connect. Utilisez les éléments suivants comme guide :

   - `<your_oidc_label>` est le label qui apparaît sur la page de connexion.
   - `<custom_provider_icon>` (facultatif) est l'icône qui apparaît sur la page de connexion. Les icônes des principales plateformes de connexion sociale sont intégrées dans GitLab, mais vous pouvez remplacer ces icônes en spécifiant ce paramètre. GitLab accepte les chemins locaux et les URL absolues. GitLab inclut des icônes pour la plupart des principales plateformes de connexion sociale, mais vous pouvez remplacer ces icônes en spécifiant une URL externe ou un chemin absolu ou relatif vers votre propre fichier d'icône.
     - Pour les chemins absolus locaux, configurez les paramètres du fournisseur sous la forme `icon: <path>/<to>/<your-icon>`.
       - Stockez le fichier d'icône dans `/opt/gitlab/embedded/service/gitlab-rails/public/<path>/<to>/<your-icon>`.
       - Accédez au fichier d'icône à l'adresse `https://gitlab.example/<path>/<to>/<your-icon>`.
     - Pour les chemins relatifs locaux, configurez les paramètres du fournisseur sous la forme `icon: <your-icon>`.
       - Stockez le fichier d'icône dans `/opt/gitlab/embedded/service/gitlab-rails/public/images/<your-icon>`.
       - Accédez au fichier d'icône à l'adresse `https://gitlab.example.com/images/<your-icon>`.
   - `<your_oidc_url>` (facultatif) est l'URL qui pointe vers le fournisseur OpenID Connect (par exemple, `https://example.com/auth/realms/your-realm`). Si cette valeur n'est pas fournie, l'URL est construite à partir de `client_options` dans le format suivant : `<client_options.scheme>://<client_options.host>:<client_options.port>`.
   - Si `discovery` est défini sur `true`, le fournisseur OpenID Connect tente de découvrir automatiquement les options client en utilisant `<your_oidc_url>/.well-known/openid-configuration`. La valeur par défaut est `false`.
   - `client_auth_method` (facultatif) spécifie la méthode utilisée pour authentifier le client auprès du fournisseur OpenID Connect.
     - Les valeurs prises en charge sont :
       - `basic` - Authentification HTTP de base.
       - `jwt_bearer` - Authentification basée sur JWT (signature par clé privée et secret client).
       - `mtls` - Validation par TLS mutuel ou certificat X.509.
       - Toute autre valeur envoie l'identifiant et le secret du client dans le corps de la requête.
     - Si non spécifié, cette valeur est par défaut `basic`.
   - `<uid_field>` (facultatif) est le nom de champ issu de `user_info.raw_attributes` qui définit la valeur de `uid` (par exemple, `preferred_username`). Si vous ne fournissez pas cette valeur, ou si le champ avec la valeur configurée est manquant dans les détails de `user_info.raw_attributes`, `uid` utilise le champ `sub`.
   - `send_scope_to_token_endpoint` est `true` par défaut, donc le paramètre `scope` est généralement inclus dans les requêtes adressées au point de terminaison du jeton. Cependant, si votre fournisseur OpenID Connect n'accepte pas le paramètre `scope` dans ces requêtes, définissez cette valeur sur `false`.
   - `pkce` (facultatif) :  Activer [Proof Key for Code Exchange](https://www.rfc-editor.org/rfc/rfc7636).
   - `client_options` sont les options spécifiques au client OpenID Connect. En particulier :
     - `identifier` est l'identifiant client tel que configuré dans le fournisseur de services OpenID Connect.
     - `secret` est le secret client tel que configuré dans le fournisseur de services OpenID Connect. Par exemple, [OmniAuth OpenID Connect](https://github.com/omniauth/omniauth_openid_connect) l'exige. Si le fournisseur de services ne nécessite pas de secret, fournissez n'importe quelle valeur, elle sera ignorée.
     - `redirect_uri` est l'URL GitLab vers laquelle rediriger l'utilisateur après une connexion réussie (par exemple, `http://example.com/users/auth/openid_connect/callback`).
     - Les `client_options` suivantes sont facultatives, sauf si la découverte automatique est désactivée ou échoue :
       - `authorization_endpoint` est l'URL du point de terminaison qui autorise l'utilisateur final.
       - `token_endpoint` est l'URL du point de terminaison qui fournit le jeton d'accès.
       - `userinfo_endpoint` est l'URL du point de terminaison qui fournit les informations de l'utilisateur.
       - `jwks_uri` est l'URL du point de terminaison où le signataire de jeton publie ses clés.

1. Enregistrez le fichier de configuration.
1. Pour que les modifications prennent effet, si vous :

   - Avez utilisé le package Linux pour installer GitLab, [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
   - Avez compilé manuellement votre installation GitLab, [redémarrez GitLab](../restart_gitlab.md#self-compiled-installations).

Sur la page de connexion, une option OpenID Connect est disponible sous le formulaire de connexion habituel. Sélectionnez cette option pour commencer le processus d'authentification. Le fournisseur OpenID Connect vous demande de vous connecter et d'autoriser l'application GitLab si une confirmation est requise par le client. Vous êtes redirigé vers GitLab et connecté.

## Exemples de configurations {#example-configurations}

Les configurations suivantes illustrent comment configurer OpenID avec différents fournisseurs lors de l'utilisation de l'installation de package Linux.

### Configurer Google {#configure-google}

Consultez la [documentation Google](https://developers.google.com/identity/openid-connect/openid-connect) pour plus de détails :

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "openid_connect", # do not change this parameter
    label: "Google OpenID", # optional label for login button, defaults to "Openid Connect"
    args: {
      name: "openid_connect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer: "https://accounts.google.com",
      client_auth_method: "query",
      discovery: true,
      uid_field: "preferred_username",
      pkce: true,
      client_options: {
        identifier: "<YOUR PROJECT CLIENT ID>",
        secret: "<YOUR PROJECT CLIENT SECRET>",
        redirect_uri: "https://example.com/users/auth/openid_connect/callback",
       }
     }
  }
]
```

### Configurer Microsoft Azure {#configure-microsoft-azure}

Le protocole OpenID Connect (OIDC) pour Microsoft Azure utilise les [points de terminaison de la plateforme d'identité Microsoft (v2)](https://learn.microsoft.com/en-us/previous-versions/azure/active-directory/azuread-dev/azure-ad-endpoint-comparison). Pour commencer, connectez-vous au [portail Azure](https://portal.azure.com). Pour votre application, vous avez besoin des informations suivantes :

- Un identifiant de locataire (tenant ID). Vous en avez peut-être déjà un. Pour plus d'informations, consultez la documentation [Microsoft Azure Tenant](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-create-new-tenant).
- Un identifiant client et un secret client. Suivez les instructions de la documentation [Microsoft Quickstart Register an Application](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app) pour obtenir l'identifiant de locataire, l'identifiant client et le secret client de votre application.

Lorsque vous enregistrez une application Microsoft Azure, vous devez accorder des autorisations d'API pour permettre à GitLab de récupérer les informations requises. Vous devez fournir au minimum les autorisations `openid`, `profile` et `email`. Pour plus d'informations, consultez la [documentation Microsoft sur la configuration des autorisations d'application pour une API web](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-configure-app-access-web-apis#add-permissions-to-access-microsoft-graph).

> [!note]
> Tous les comptes provisionnés par Azure doivent avoir une adresse e-mail définie. Si une adresse e-mail n'est pas définie, Azure attribue une adresse générée aléatoirement. Si vous avez configuré des [restrictions de domaine pour les nouveaux utilisateurs](../settings/sign_up_restrictions.md#allow-or-deny-account-creation-by-using-specific-email-domains), cette adresse aléatoire pourrait empêcher la création du compte.

Exemple de bloc de configuration pour les installations de packages Linux :

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "openid_connect", # do not change this parameter
    label: "Azure OIDC", # optional label for login button, defaults to "Openid Connect"
    args: {
      name: "openid_connect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer:  "https://login.microsoftonline.com/<YOUR-TENANT-ID>/v2.0",
      client_auth_method: "query",
      discovery: true,
      uid_field: "preferred_username",
      pkce: true,
      client_options: {
        identifier: "<YOUR APP CLIENT ID>",
        secret: "<YOUR APP CLIENT SECRET>",
        redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback"
      }
    }
  }
]
```

Microsoft a documenté le fonctionnement de sa plateforme avec [le protocole OIDC](https://learn.microsoft.com/en-us/entra/identity-platform/v2-protocols-oidc).

#### Clés de signature personnalisées Microsoft Entra {#microsoft-entra-custom-signing-keys}

Si votre application possède des clés de signature personnalisées parce que vous utilisez la [fonctionnalité de mappage des revendications SAML](https://learn.microsoft.com/en-us/entra/identity-platform/saml-claims-customization), vous devez configurer le fournisseur OpenID de la manière suivante :

- Désactivez la découverte OpenID Connect en omettant `args.discovery` ou en le définissant sur `false`.
- Dans `client_options`, spécifiez les éléments suivants :
  - Un `jwks_uri` avec le paramètre de requête `appid` : `https://login.microsoftonline.com/<YOUR-TENANT-ID>/discovery/v2.0/keys?appid=<YOUR APP CLIENT ID>`.
  - `end_session_endpoint`.
  - `authorization_endpoint`.
  - `userinfo_endpoint`.

Exemple de configuration pour les installations de packages Linux :

```ruby
gitlab_rails['omniauth_providers'] = [
 {
    name: "openid_connect", # do not change this parameter
    label: "Azure OIDC", # optional label for login button, defaults to "Openid Connect"
    args: {
      name: "openid_connect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer:  "https://login.microsoftonline.com/<YOUR-TENANT-ID>/v2.0",
      client_auth_method: "basic",
      discovery: false,
      uid_field: "preferred_username",
      pkce: true,
      client_options: {
        identifier: "<YOUR APP CLIENT ID>",
        secret: "<YOUR APP CLIENT SECRET>",
        redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback",
        end_session_endpoint: "https://login.microsoftonline.com/<YOUR-TENANT-ID>/oauth2/v2.0/logout",
        authorization_endpoint: "https://login.microsoftonline.com/<YOUR-TENANT-ID>/oauth2/v2.0/authorize",
        token_endpoint: "https://login.microsoftonline.com/<YOUR-TENANT-ID>/oauth2/v2.0/token",
        userinfo_endpoint: "https://graph.microsoft.com/oidc/userinfo",
        jwks_uri: "https://login.microsoftonline.com/<YOUR-TENANT-ID>/discovery/v2.0/keys?appid=<YOUR APP CLIENT ID>"
      }
    }
  }
]
```

Si vous voyez des échecs d'authentification avec un message `KidNotFound`, c'est probablement en raison d'un paramètre de requête `appid` manquant ou incorrect. GitLab génère cette erreur si le jeton d'identité renvoyé par Microsoft ne peut pas être validé avec les clés fournies par le point de terminaison `jwks_uri`.

Pour plus d'informations, consultez la [documentation Microsoft Entra sur la validation des jetons](https://learn.microsoft.com/en-us/entra/identity-platform/access-tokens#validate-tokens).

#### Migrer vers la configuration générique OpenID Connect {#migrate-to-generic-openid-connect-configuration}

Vous pouvez migrer vers la configuration générique OpenID Connect depuis `azure_activedirectory_v2` et `azure_oauth2`.

Tout d'abord, définissez le `uid_field`. Le `uid_field` et la revendication `sub` que vous pouvez sélectionner comme `uid_field` varient selon le fournisseur. La connexion sans définir le `uid_field` entraîne la création d'identités supplémentaires dans GitLab qui doivent être modifiées manuellement :

| Fournisseur                                                                                                        | `uid_field` | Informations complémentaires  |
|-----------------------------------------------------------------------------------------------------------------|-------|-----------------------------------------------------------------------|
| [`omniauth-azure-oauth2`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/vendor/gems/omniauth-azure-oauth2) | `sub` | Les attributs supplémentaires `oid` et `tid` sont proposés dans l'objet `info`. |
| [`omniauth-azure-activedirectory-v2`](https://github.com/RIPAGlobal/omniauth-azure-activedirectory-v2/)         | `oid` | Vous devez configurer `oid` comme `uid_field` lors de la migration. |
| [`omniauth_openid_connect`](https://github.com/omniauth/omniauth_openid_connect/)                               | `sub` | Spécifiez `uid_field` pour utiliser un autre champ. |

Pour migrer vers la configuration générique OpenID Connect, vous devez mettre à jour la configuration.

Pour les installations de packages Linux, mettez à jour la configuration comme suit :

{{< tabs >}}

{{< tab title="Azure OAuth 2.0" >}}

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "azure_oauth2",
    label: "Azure OIDC", # optional label for login button, defaults to "Openid Connect"
    args: {
      name: "azure_oauth2", # this matches the existing azure_oauth2 provider name, and only the strategy_class immediately below configures OpenID Connect
      strategy_class: "OmniAuth::Strategies::OpenIDConnect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer:  "https://login.microsoftonline.com/<YOUR-TENANT-ID>/v2.0",
      client_auth_method: "query",
      discovery: true,
      uid_field: "sub",
      send_scope_to_token_endpoint: "false",
      client_options: {
        identifier: "<YOUR APP CLIENT ID>",
        secret: "<YOUR APP CLIENT SECRET>",
        redirect_uri: "https://gitlab.example.com/users/auth/azure_oauth2/callback"
      }
    }
  }
]
```

{{< /tab >}}

{{< tab title="Azure Active Directory v2" >}}

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "azure_activedirectory_v2",
    label: "Azure OIDC", # optional label for login button, defaults to "Openid Connect"
    args: {
      name: "azure_activedirectory_v2",
      strategy_class: "OmniAuth::Strategies::OpenIDConnect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer:  "https://login.microsoftonline.com/<YOUR-TENANT-ID>/v2.0",
      client_auth_method: "query",
      discovery: true,
      uid_field: "oid",
      send_scope_to_token_endpoint: "false",
      client_options: {
        identifier: "<YOUR APP CLIENT ID>",
        secret: "<YOUR APP CLIENT SECRET>",
        redirect_uri: "https://gitlab.example.com/users/auth/azure_activedirectory_v2/callback"
      }
    }
  }
]
```

{{< /tab >}}

{{< /tabs >}}

Pour les installations Helm :

Ajoutez la [configuration du fournisseur](https://docs.gitlab.com/charts/charts/globals/#providers) dans un fichier YAML (par exemple, `provider.yaml`) :

{{< tabs >}}

{{< tab title="Azure OAuth 2.0" >}}

```ruby
{
  "name": "azure_oauth2",
  "args": {
    "name": "azure_oauth2",
    "strategy_class": "OmniAuth::Strategies::OpenIDConnect",
    "scope": [
      "openid",
      "profile",
      "email"
    ],
    "response_type": "code",
    "issuer": "https://login.microsoftonline.com/<YOUR-TENANT-ID>/v2.0",
    "client_auth_method": "query",
    "discovery": true,
    "uid_field": "sub",
    "send_scope_to_token_endpoint": false,
    "client_options": {
      "identifier": "<YOUR APP CLIENT ID>",
      "secret": "<YOUR APP CLIENT SECRET>",
      "redirect_uri": "https://gitlab.example.com/users/auth/azure_oauth2/callback"
    }
  }
}
```

{{< /tab >}}

{{< tab title="Azure Active Directory v2" >}}

```ruby
{
  "name": "azure_activedirectory_v2",
  "args": {
    "name": "azure_activedirectory_v2",
    "strategy_class": "OmniAuth::Strategies::OpenIDConnect",
    "scope": [
      "openid",
      "profile",
      "email"
    ],
    "response_type": "code",
    "issuer": "https://login.microsoftonline.com/<YOUR-TENANT-ID>/v2.0",
    "client_auth_method": "query",
    "discovery": true,
    "uid_field": "sub",
    "send_scope_to_token_endpoint": false,
    "client_options": {
      "identifier": "<YOUR APP CLIENT ID>",
      "secret": "<YOUR APP CLIENT SECRET>",
      "redirect_uri": "https://gitlab.example.com/users/auth/activedirectory_v2/callback"
    }
  }
}
```

{{< /tab >}}

{{< /tabs >}}

Lors de la migration de `azure_oauth2` vers `omniauth_openid_connect` dans le cadre d'une mise à niveau vers GitLab 17.0 ou une version ultérieure, la valeur de la revendication `sub` définie pour votre organisation peut varier. `azure_oauth2` utilise le point de terminaison Microsoft V1, tandis que `azure_activedirectory_v2` et `omniauth_openid_connect` utilisent tous deux le point de terminaison Microsoft V2 avec une valeur `sub` commune.

- **For users with an email address in Entra ID**, pour permettre le repli sur l'adresse e-mail et la mise à jour de l'identité de l'utilisateur, configurez les éléments suivants :
  - Dans une installation de package Linux, [`omniauth_auto_link_user`](../../integration/omniauth.md#link-existing-users-to-omniauth-users).
  - Dans une installation Helm, [`autoLinkUser`](https://docs.gitlab.com/charts/charts/globals/#omniauth).
- **For users with no email address**, les administrateurs doivent effectuer l'une des actions suivantes :
  - Configurez une autre méthode d'authentification ou activez la connexion avec le nom d'utilisateur et le mot de passe GitLab. L'utilisateur peut ensuite se connecter et lier manuellement son identité Azure via son profil.
  - Implémentez OpenID Connect comme nouveau fournisseur aux côtés du `azure_oauth2` existant afin que l'utilisateur puisse se connecter via OAuth 2.0 et lier son identité OpenID Connect (de manière similaire à la méthode précédente). Cette méthode fonctionnerait également pour les utilisateurs ayant des adresses e-mail, à condition que `auto_link_user` soit activé.
  - Mettez à jour `extern_uid` manuellement. Pour ce faire, utilisez l'[API ou la console Rails](../../integration/omniauth.md#change-apps-or-configuration) pour mettre à jour le `extern_uid` pour chaque utilisateur. Cette méthode peut être nécessaire si l'instance a déjà été mise à niveau vers la version 17.0 ou ultérieure et que les utilisateurs ont tenté de se connecter.

> [!note]
> `azure_oauth2` peut avoir utilisé la revendication `upn` d'Entra ID comme adresse e-mail, si la revendication `email` était manquante ou vide lors du provisionnement des comptes GitLab.

### Configurer Microsoft Azure Active Directory B2C {#configure-microsoft-azure-active-directory-b2c}

GitLab nécessite une configuration spéciale pour fonctionner avec [Azure Active Directory B2C](https://learn.microsoft.com/en-us/azure/active-directory-b2c/overview). Pour commencer, connectez-vous au [portail Azure](https://portal.azure.com). Pour votre application, vous avez besoin des informations suivantes provenant d'Azure :

- Un identifiant de locataire (tenant ID). Vous en avez peut-être déjà un. Pour plus d'informations, consultez la documentation [Microsoft Azure Tenant](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-create-new-tenant).
- Un identifiant client et un secret client. Suivez les instructions de la documentation du [tutoriel Microsoft](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-register-applications?tabs=app-reg-ga) pour obtenir l'identifiant client et le secret client de votre application.
- Le flux utilisateur ou le nom de la stratégie. Suivez les instructions du [tutoriel Microsoft](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-user-flow).

Configurez l'application :

1. Définissez l'`Redirect URI` de l'application. Par exemple, si votre domaine GitLab est `gitlab.example.com`, définissez l'`Redirect URI` de l'application sur `https://gitlab.example.com/users/auth/openid_connect/callback`.
1. [Activez les jetons d'identifiant](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-register-applications?tabs=app-reg-ga#enable-id-token-implicit-grant).
1. Ajoutez les autorisations d'API suivantes à l'application :

   - `openid`
   - `offline_access`

#### Configurer des stratégies personnalisées {#configure-custom-policies}

Azure B2C [propose deux façons de définir la logique métier pour la connexion d'un utilisateur](https://learn.microsoft.com/en-us/azure/active-directory-b2c/user-flow-overview) :

- [Flux utilisateurs](https://learn.microsoft.com/en-us/azure/active-directory-b2c/user-flow-overview#user-flows)
- [Stratégies personnalisées](https://learn.microsoft.com/en-us/azure/active-directory-b2c/user-flow-overview#custom-policies)

Les stratégies personnalisées sont requises car les flux utilisateurs Azure B2C standard n'envoient pas la revendication OpenID `email` dont GitLab a besoin pour créer ou lier des utilisateurs. Par conséquent, les flux utilisateurs standard ne fonctionnent pas avec les [paramètres `allow_single_sign_on` ou `auto_link_user`](../../integration/omniauth.md#configure-common-settings). Avec une stratégie Azure B2C standard, GitLab ne peut pas créer de nouveau compte ni établir un lien avec un compte existant via une adresse e-mail.

Pour plus d'informations sur la façon dont Azure AD B2C émet des jetons et des revendications dans les flux utilisateurs et les stratégies personnalisées, consultez la documentation Microsoft sur les [flux utilisateurs et les stratégies personnalisées](https://learn.microsoft.com/azure/active-directory-b2c/user-flow-overview) et la [configuration du schéma de revendications](https://learn.microsoft.com/azure/active-directory-b2c/claimsschema).

Tout d'abord, [créez une stratégie personnalisée](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy).

Les instructions Microsoft utilisent `SocialAndLocalAccounts` dans le [pack de démarrage de stratégie personnalisée](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy#custom-policy-starter-pack), mais `LocalAccounts` s'authentifie auprès des comptes Active Directory locaux. Avant de [charger les stratégies](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy#upload-the-policies), effectuez les opérations suivantes :

1. Pour exporter la revendication `email`, modifiez le fichier `SignUpOrSignin.xml`. Remplacez la ligne suivante :

   ```xml
   <OutputClaim ClaimTypeReferenceId="email" />
   ```

   par :

   ```xml
   <OutputClaim ClaimTypeReferenceId="signInNames.emailAddress" PartnerClaimType="email" />
   ```

1. Pour que la découverte OIDC fonctionne avec B2C, configurez la stratégie avec un émetteur compatible avec la [spécification OIDC](https://openid.net/specs/openid-connect-discovery-1_0.html#rfc.section.4.3). Consultez les [paramètres de compatibilité des jetons](https://learn.microsoft.com/en-us/azure/active-directory-b2c/configure-tokens?pivots=b2c-custom-policy#token-compatibility-settings). Dans `TrustFrameworkBase.xml` sous `JwtIssuer`, définissez `IssuanceClaimPattern` sur `AuthorityWithTfp` :

   ```xml
   <ClaimsProvider>
     <DisplayName>Token Issuer</DisplayName>
     <TechnicalProfiles>
       <TechnicalProfile Id="JwtIssuer">
         <DisplayName>JWT Issuer</DisplayName>
         <Protocol Name="None" />
         <OutputTokenFormat>JWT</OutputTokenFormat>
         <Metadata>
           <Item Key="IssuanceClaimPattern">AuthorityWithTfp</Item>
           ...
   ```

1. [Chargez la stratégie](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy#upload-the-policies). Écrasez les fichiers existants si vous mettez à jour une stratégie existante.

1. Pour déterminer l'URL de l'émetteur, utilisez la stratégie de connexion. L'URL de l'émetteur est de la forme :

   ```markdown
   https://<YOUR-DOMAIN>/tfp/<YOUR-TENANT-ID>/<YOUR-SIGN-IN-POLICY-NAME>/v2.0/
   ```

   Le nom de la stratégie est en minuscules dans l'URL. Par exemple, la stratégie `B2C_1A_signup_signin` apparaît sous la forme `b2c_1a_signup_sigin`.

   Veillez à inclure la barre oblique finale.

1. Vérifiez le fonctionnement de l'URL de découverte OIDC et de l'URL de l'émetteur, puis ajoutez `.well-known/openid-configuration` à l'URL de l'émetteur :

   ```markdown
   https://<YOUR-DOMAIN>/tfp/<YOUR-TENANT-ID>/<YOUR-SIGN-IN-POLICY-NAME>/v2.0/.well-known/openid-configuration
   ```

   Par exemple, si `domain` est `example.b2clogin.com` et que l'identifiant de locataire est `fc40c736-476c-4da1-b489-ee48cee84386`, vous pouvez utiliser `curl` et `jq` pour extraire l'émetteur :

   ```shell
   $ curl --silent "https://example.b2clogin.com/tfp/fc40c736-476c-4da1-b489-ee48cee84386/b2c_1a_signup_signin/v2.0/.well-known/openid-configuration" | jq .issuer
   "https://example.b2clogin.com/tfp/fc40c736-476c-4da1-b489-ee48cee84386/b2c_1a_signup_signin/v2.0/"
   ```

1. Configurez l'URL de l'émetteur avec la stratégie personnalisée utilisée pour `signup_signin`. Par exemple, voici la configuration avec une stratégie personnalisée pour `b2c_1a_signup_signin` pour les installations de packages Linux :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
   {
     name: "openid_connect", # do not change this parameter
     label: "Azure B2C OIDC", # optional label for login button, defaults to "Openid Connect"
     args: {
       name: "openid_connect",
       scope: ["openid"],
       response_mode: "query",
       response_type: "id_token",
       issuer:  "https://<YOUR-DOMAIN>/tfp/<YOUR-TENANT-ID>/b2c_1a_signup_signin/v2.0/",
       client_auth_method: "query",
       discovery: true,
       send_scope_to_token_endpoint: true,
       pkce: true,
       client_options: {
         identifier: "<YOUR APP CLIENT ID>",
         secret: "<YOUR APP CLIENT SECRET>",
         redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback"
       }
     }
   }]
   ```

#### Dépannage Azure B2C {#troubleshooting-azure-b2c}

- Assurez-vous que toutes les occurrences de `yourtenant.onmicrosoft.com`, `ProxyIdentityExperienceFrameworkAppId` et `IdentityExperienceFrameworkAppId` correspondent au nom d'hôte de votre locataire B2C et aux identifiants client respectifs dans les fichiers de stratégie XML.
- Ajoutez `https://jwt.ms` comme URI de redirection à l'application et utilisez le [testeur de stratégie personnalisée](https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-user-flows?pivots=b2c-custom-policy#test-the-custom-policy). Vérifiez que le payload inclut `email` correspondant à l'accès e-mail de l'utilisateur.
- Après avoir activé la stratégie personnalisée, les utilisateurs pourraient voir `Invalid username or password` après avoir tenté de se connecter. Cela peut être un problème de configuration avec l'application `IdentityExperienceFramework`. Consultez [ce commentaire Microsoft](https://learn.microsoft.com/en-us/answers/questions/50355/unable-to-sign-on-using-custom-policy?childtoview=122370#comment-122370) qui suggère de vérifier que le manifeste de l'application contient ces paramètres :

  - `"accessTokenAcceptedVersion": null`
  - `"signInAudience": "AzureADMyOrg"`

Cette configuration correspond au paramètre `Supported account types` utilisé lors de la création de l'application `IdentityExperienceFramework`.

### Configurer Keycloak {#configure-keycloak}

GitLab fonctionne avec les fournisseurs OpenID qui utilisent HTTPS. Bien que vous puissiez configurer un serveur Keycloak qui utilise HTTP, GitLab ne peut communiquer qu'avec un serveur Keycloak qui utilise HTTPS.

Configurez Keycloak pour utiliser des algorithmes à clé publique pour signer les jetons. Par exemple, utilisez RSA256 ou RSA512 au lieu de HS256 ou HS358. Les algorithmes de chiffrement à clé publique sont :

- Plus faciles à configurer.
- Plus sécurisés car la divulgation de la clé privée a de graves conséquences sur la sécurité.

1. Ouvrez la console d'administration Keycloak.
1. Sélectionnez **Realm Settings** > **Tokens** > **Default Signature Algorithm**.
1. Configurez l'algorithme de signature.

Exemple de bloc de configuration pour les installations de packages Linux :

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "openid_connect", # do not change this parameter
    label: "Keycloak", # optional label for login button, defaults to "Openid Connect"
    args: {
      name: "openid_connect",
      scope: ["openid", "profile", "email"],
      response_type: "code",
      issuer:  "https://keycloak.example.com/realms/myrealm",
      client_auth_method: "query",
      discovery: true,
      uid_field: "preferred_username",
      pkce: true,
      client_options: {
        identifier: "<YOUR CLIENT ID>",
        secret: "<YOUR CLIENT SECRET>",
        redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback"
      }
    }
  }
]
```

#### Configurer Keycloak avec un algorithme à clé symétrique {#configure-keycloak-with-a-symmetric-key-algorithm}

> [!warning]
> Les instructions suivantes sont incluses par souci d'exhaustivité, mais n'utilisez le chiffrement à clé symétrique que si cela est absolument nécessaire.

Pour utiliser le chiffrement à clé symétrique :

1. Extrayez la clé secrète de la base de données Keycloak. Keycloak n'expose pas cette valeur dans l'interface web. Le secret client visible dans l'interface web est le secret client OAuth 2.0, qui est différent du secret utilisé pour signer les JSON Web Tokens.

   Par exemple, si vous utilisez PostgreSQL comme base de données backend pour Keycloak :

   - Connectez-vous à la console de base de données.
   - Exécutez la requête SQL suivante pour extraire la clé :

     ```sql
     $ psql -U keycloak
     psql (13.3 (Debian 13.3-1.pgdg100+1))
     Type "help" for help.

     keycloak=# SELECT c.name, value FROM component_config CC INNER JOIN component C ON(CC.component_id = C.id) WHERE C.realm_id = 'master' and provider_id = 'hmac-generated' AND CC.name = 'secret';
     -[ RECORD 1 ]---------------------------------------------------------------------------------
     name  | hmac-generated
     value | lo6cqjD6Ika8pk7qc3fpFx9ysrhf7E62-sqGc8drp3XW-wr93zru8PFsQokHZZuJJbaUXvmiOftCZM3C4KW3-g
     -[ RECORD 2 ]---------------------------------------------------------------------------------
     name  | fallback-HS384
     value | UfVqmIs--U61UYsRH-NYBH3_mlluLONpg_zN7CXEwkJcO9xdRNlzZfmfDLPtf2xSTMvqu08R2VhLr-8G-oZ47A
     ```

     Dans cet exemple, il y a deux clés privées : une pour HS256 (`hmac-generated`) et une autre pour HS384 (`fallback-HS384`). Nous utilisons la première `value` pour configurer GitLab.

1. Convertissez `value` en base64 standard. Comme indiqué dans le [post « Invalid signature with HS256 token »](https://keycloak.discourse.group/t/invalid-signature-with-hs256-token/3228/9), `value` est encodé dans la [section « Base 64 Encoding with URL and Filename Safe Alphabet »](https://datatracker.ietf.org/doc/html/rfc4648#section-5) de la RFC 4648. Cela doit être converti en [base64 standard tel que défini dans la RFC 2045](https://datatracker.ietf.org/doc/html/rfc2045). Le script Ruby suivant effectue cette opération :

   ```ruby
   require 'base64'

   value = "lo6cqjD6Ika8pk7qc3fpFx9ysrhf7E62-sqGc8drp3XW-wr93zru8PFsQokHZZuJJbaUXvmiOftCZM3C4KW3-g"
   Base64.encode64(Base64.urlsafe_decode64(value))
   ```

   Cela donne la valeur suivante :

   ```markdown
   lo6cqjD6Ika8pk7qc3fpFx9ysrhf7E62+sqGc8drp3XW+wr93zru8PFsQokH\nZZuJJbaUXvmiOftCZM3C4KW3+g==\n
   ```

1. Spécifiez ce secret encodé en base64 dans `jwt_secret_base64`. Par exemple :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "openid_connect", # do not change this parameter
       label: "Keycloak", # optional label for login button, defaults to "Openid Connect"
       args: {
         name: "openid_connect",
         scope: ["openid", "profile", "email"],
         response_type: "code",
         issuer:  "https://keycloak.example.com/auth/realms/myrealm",
         client_auth_method: "query",
         discovery: true,
         uid_field: "preferred_username",
         jwt_secret_base64: "<YOUR BASE64-ENCODED SECRET>",
         pkce: true,
         client_options: {
           identifier: "<YOUR CLIENT ID>",
           secret: "<YOUR CLIENT SECRET>",
           redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback"
         }
       }
     }
   ]
   ```

Si vous voyez une erreur `JSON::JWS::VerificationFailed`, vous avez spécifié un secret incorrect.

### Casdoor {#casdoor}

GitLab fonctionne avec les fournisseurs OpenID qui utilisent HTTPS. Utilisez HTTPS pour vous connecter à GitLab via OpenID avec Casdoor.

Pour votre application, effectuez les étapes suivantes sur Casdoor :

1. Obtenez un identifiant client et un secret client.
1. Ajoutez votre URL de redirection GitLab. Par exemple, si votre domaine GitLab est `gitlab.example.com`, assurez-vous que l'application Casdoor possède le `Redirect URI` suivant : `https://gitlab.example.com/users/auth/openid_connect/callback`.

Consultez la [documentation Casdoor](https://casdoor.org/docs/integration/ruby/gitlab/) pour plus de détails.

Exemple de configuration pour les installations de packages Linux (chemin du fichier : `/etc/gitlab/gitlab.rb`) :

```ruby
gitlab_rails['omniauth_providers'] = [
    {
        name: "openid_connect", # do not change this parameter
        label: "Casdoor", # optional label for login button, defaults to "Openid Connect"
        args: {
            name: "openid_connect",
            scope: ["openid", "profile", "email"],
            response_type: "code",
            issuer:  "https://<CASDOOR_HOSTNAME>",
            client_auth_method: "query",
            discovery: true,
            uid_field: "sub",
            client_options: {
                identifier: "<YOUR CLIENT ID>",
                secret: "<YOUR CLIENT SECRET>",
                redirect_uri: "https://gitlab.example.com/users/auth/openid_connect/callback"
            }
        }
    }
]
```

Exemple de configuration pour les installations compilées manuellement (chemin du fichier : `config/gitlab.yml`) :

```yaml
  - { name: 'openid_connect', # do not change this parameter
      label: 'Casdoor', # optional label for login button, defaults to "Openid Connect"
      args: {
        name: 'openid_connect',
        scope: ['openid', 'profile', 'email'],
        response_type: 'code',
        issuer: 'https://<CASDOOR_HOSTNAME>',
        discovery: true,
        client_auth_method: 'query',
        uid_field: 'sub',
        client_options: {
          identifier: '<YOUR CLIENT ID>',
          secret: '<YOUR CLIENT SECRET>',
          redirect_uri: 'https://gitlab.example.com/users/auth/openid_connect/callback'
        }
      }
    }
```

## Configurer plusieurs fournisseurs OpenID Connect {#configure-multiple-openid-connect-providers}

Vous pouvez configurer votre application pour utiliser plusieurs fournisseurs OpenID Connect (OIDC). Pour ce faire, définissez explicitement le `strategy_class` dans votre fichier de configuration.

Vous devriez procéder ainsi dans l'un ou l'autre des scénarios suivants :

- [Migration vers le protocole OpenID Connect](#migrate-to-generic-openid-connect-configuration).
- Proposer différents niveaux d'authentification.

Les exemples de configurations suivants montrent comment proposer différents niveaux d'authentification, une option avec authentification à deux facteurs (2FA) et une sans 2FA.

Pour les installations de packages Linux :

```ruby
gitlab_rails['omniauth_providers'] = [
  {
    name: "openid_connect",
    label: "Provider name", # optional label for login button, defaults to "Openid Connect"
    icon: "<custom_provider_icon>",
    args: {
      name: "openid_connect",
      strategy_class: "OmniAuth::Strategies::OpenIDConnect",
      scope: ["openid","profile","email"],
      response_type: "code",
      issuer: "<your_oidc_url>",
      discovery: true,
      client_auth_method: "query",
      uid_field: "<uid_field>",
      send_scope_to_token_endpoint: "false",
      pkce: true,
      client_options: {
        identifier: "<your_oidc_client_id>",
        secret: "<your_oidc_client_secret>",
        redirect_uri: "<your_gitlab_url>/users/auth/openid_connect/callback"
      }
    }
  },
  {
    name: "openid_connect_2fa",
    label: "Provider name 2FA", # optional label for login button, defaults to "Openid Connect"
    icon: "<custom_provider_icon>",
    args: {
      name: "openid_connect_2fa",
      strategy_class: "OmniAuth::Strategies::OpenIDConnect",
      scope: ["openid","profile","email"],
      response_type: "code",
      issuer: "<your_oidc_url>",
      discovery: true,
      client_auth_method: "query",
      uid_field: "<uid_field>",
      send_scope_to_token_endpoint: "false",
      pkce: true,
      client_options: {
        identifier: "<your_oidc_client_id>",
        secret: "<your_oidc_client_secret>",
        redirect_uri: "<your_gitlab_url>/users/auth/openid_connect_2fa/callback"
      }
    }
  }
]
```

Pour les installations compilées manuellement :

```yaml
  - { name: 'openid_connect',
      label: 'Provider name', # optional label for login button, defaults to "Openid Connect"
      icon: '<custom_provider_icon>',
      args: {
        name: 'openid_connect',
        strategy_class: "OmniAuth::Strategies::OpenIDConnect",
        scope: ['openid', 'profile', 'email'],
        response_type: 'code',
        issuer: '<your_oidc_url>',
        discovery: true,
        client_auth_method: 'query',
        uid_field: '<uid_field>',
        send_scope_to_token_endpoint: false,
        pkce: true,
        client_options: {
          identifier: '<your_oidc_client_id>',
          secret: '<your_oidc_client_secret>',
          redirect_uri: '<your_gitlab_url>/users/auth/openid_connect/callback'
        }
      }
    }
  - { name: 'openid_connect_2fa',
      label: 'Provider name 2FA', # optional label for login button, defaults to "Openid Connect"
      icon: '<custom_provider_icon>',
      args: {
        name: 'openid_connect_2fa',
        strategy_class: "OmniAuth::Strategies::OpenIDConnect",
        scope: ['openid', 'profile', 'email'],
        response_type: 'code',
        issuer: '<your_oidc_url>',
        discovery: true,
        client_auth_method: 'query',
        uid_field: '<uid_field>',
        send_scope_to_token_endpoint: false,
        pkce: true,
        client_options: {
          identifier: '<your_oidc_client_id>',
          secret: '<your_oidc_client_secret>',
          redirect_uri: '<your_gitlab_url>/users/auth/openid_connect_2fa/callback'
        }
      }
    }
```

Dans ce cas d'utilisation, vous pourriez vouloir synchroniser le `extern_uid` entre les différents fournisseurs en vous basant sur un identifiant connu existant dans votre annuaire d'entreprise.

Pour ce faire, définissez le `uid_field`. L'exemple de code suivant montre comment procéder :

```python
def sync_missing_provider(self, user: User, extern_uid: str)
  existing_identities = []
  for identity in user.identities:
      existing_identities.append(identity.get("provider"))

  local_extern_uid = extern_uid.lower()
  for provider in ("openid_connect_2fa", "openid_connect"):
      identity = [
          identity
          for identity in user.identities
          if identity.get("provider") == provider
          and identity.get("extern_uid").lower() != local_extern_uid
      ]
      if provider not in existing_identities or identity:
          if identity and identity[0].get("extern_uid") != "":
              logger.error(f"Found different identity for provider {provider} for user {user.id}")
              continue
          else:
              logger.info(f"Add identity 'provider': {provider}, 'extern_uid': {extern_uid} for user {user.id}")
              user.provider = provider
              user.extern_uid = extern_uid
              user = self.save_user(user)
  return user
```

Pour plus d'informations, consultez la [documentation de la méthode utilisateur de l'API GitLab](https://python-gitlab.readthedocs.io/en/stable/gl_objects/users.html#examples).

## Configurer les utilisateurs en fonction de l'appartenance aux groupes OIDC {#configure-users-based-on-oidc-group-membership}

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez configurer l'appartenance aux groupes OIDC pour :

- Exiger que les utilisateurs soient membres d'un certain groupe.
- Attribuer aux utilisateurs des rôles [externes](../external_users.md) , d'administrateur ou d'[auditeur](../auditor_users.md) en fonction de l'appartenance au groupe.

GitLab vérifie ces groupes à chaque connexion et met à jour les attributs utilisateur si nécessaire. Cette fonctionnalité ne vous permet pas d'ajouter automatiquement des utilisateurs aux [groupes](../../user/group/_index.md) GitLab.

La valeur définie pour un groupe spécifique doit refléter la valeur renvoyée par le fournisseur d'identité. Par exemple, Microsoft Entra OIDC renvoie un GroupID, donc la configuration `required_groups` ressemblerait à `required_groups: ["55db8574-c392-4e8b-892d-1e086394be9c"]`.

### Groupes requis {#required-groups}

Votre fournisseur d'identité (IdP) doit transmettre les informations de groupe à GitLab dans la réponse OIDC. Pour utiliser cette réponse afin d'exiger que les utilisateurs soient membres d'un certain groupe, configurez GitLab pour identifier :

- Où rechercher les groupes dans la réponse OIDC, en utilisant le paramètre `groups_attribute`.
- L'appartenance au groupe requise pour se connecter, en utilisant le paramètre `required_groups`.

Si vous ne définissez pas `required_groups` ou laissez le paramètre vide, tout utilisateur authentifié par l'IdP via OIDC peut utiliser GitLab.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "openid_connect",
       label: "Provider name",
       args: {
         name: "openid_connect",
         scope: ["openid","profile","email"],
         response_type: "code",
         issuer: "<your_oidc_url>",
         discovery: true,
         client_auth_method: "query",
         uid_field: "<uid_field>",
         client_options: {
           identifier: "<your_oidc_client_id>",
           secret: "<your_oidc_client_secret>",
           redirect_uri: "<your_gitlab_url>/users/auth/openid_connect/callback",
           gitlab: {
             groups_attribute: "groups",
             required_groups: ["Developer"]
           }
         }
       }
     }
   ]
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     omniauth:
       providers:
        - { name: 'openid_connect',
            label: 'Provider name',
         args: {
           name: 'openid_connect',
           scope: ['openid','profile','email'],
           response_type: 'code',
           issuer: '<your_oidc_url>',
           discovery: true,
           client_auth_method: 'query',
           uid_field: '<uid_field>',
           client_options: {
             identifier: '<your_oidc_client_id>',
             secret: '<your_oidc_client_secret>',
             redirect_uri: '<your_gitlab_url>/users/auth/openid_connect/callback',
             gitlab: {
               groups_attribute: "groups",
               required_groups: ["Developer"]
             }
           }
         }
       }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

{{< /tab >}}

{{< /tabs >}}

### Groupes externes {#external-groups}

Votre IdP doit transmettre les informations de groupe à GitLab dans la réponse OIDC. Pour utiliser cette réponse afin d'identifier les utilisateurs comme des [utilisateurs externes](../external_users.md) en fonction de l'appartenance au groupe, configurez GitLab pour identifier :

- Où rechercher les groupes dans la réponse OIDC, en utilisant le paramètre `groups_attribute`.
- Les appartenances aux groupes devant identifier un utilisateur comme [utilisateur externe](../external_users.md), en utilisant le paramètre `external_groups`.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "openid_connect",
       label: "Provider name",
       args: {
         name: "openid_connect",
         scope: ["openid","profile","email"],
         response_type: "code",
         issuer: "<your_oidc_url>",
         discovery: true,
         client_auth_method: "query",
         uid_field: "<uid_field>",
         client_options: {
           identifier: "<your_oidc_client_id>",
           secret: "<your_oidc_client_secret>",
           redirect_uri: "<your_gitlab_url>/users/auth/openid_connect/callback",
           gitlab: {
             groups_attribute: "groups",
             external_groups: ["Freelancer"]
           }
         }
       }
     }
   ]
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     omniauth:
       providers:
        - { name: 'openid_connect',
            label: 'Provider name',
         args: {
           name: 'openid_connect',
           scope: ['openid','profile','email'],
           response_type: 'code',
           issuer: '<your_oidc_url>',
           discovery: true,
           client_auth_method: 'query',
           uid_field: '<uid_field>',
           client_options: {
             identifier: '<your_oidc_client_id>',
             secret: '<your_oidc_client_secret>',
             redirect_uri: '<your_gitlab_url>/users/auth/openid_connect/callback',
             gitlab: {
               groups_attribute: "groups",
               external_groups: ["Freelancer"]
             }
           }
         }
       }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

{{< /tab >}}

{{< /tabs >}}

### Groupes d'auditeurs {#auditor-groups}

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Votre IdP doit transmettre les informations de groupe à GitLab dans la réponse OIDC. Pour utiliser cette réponse afin d'affecter des utilisateurs en tant qu'auditeurs en fonction de l'appartenance au groupe, configurez GitLab pour identifier :

- Où rechercher les groupes dans la réponse OIDC, en utilisant le paramètre `groups_attribute`.
- Les appartenances aux groupes accordant à l'utilisateur l'accès auditeur, en utilisant le paramètre `auditor_groups`.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "openid_connect",
       label: "Provider name",
       args: {
         name: "openid_connect",
         scope: ["openid","profile","email","groups"],
         response_type: "code",
         issuer: "<your_oidc_url>",
         discovery: true,
         client_auth_method: "query",
         uid_field: "<uid_field>",
         client_options: {
           identifier: "<your_oidc_client_id>",
           secret: "<your_oidc_client_secret>",
           redirect_uri: "<your_gitlab_url>/users/auth/openid_connect/callback",
           gitlab: {
             groups_attribute: "groups",
             auditor_groups: ["Auditor"]
           }
         }
       }
     }
   ]
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     omniauth:
       providers:
        - { name: 'openid_connect',
            label: 'Provider name',
         args: {
           name: 'openid_connect',
           scope: ['openid','profile','email','groups'],
           response_type: 'code',
           issuer: '<your_oidc_url>',
           discovery: true,
           client_auth_method: 'query',
           uid_field: '<uid_field>',
           client_options: {
             identifier: '<your_oidc_client_id>',
             secret: '<your_oidc_client_secret>',
             redirect_uri: '<your_gitlab_url>/users/auth/openid_connect/callback',
             gitlab: {
               groups_attribute: "groups",
               auditor_groups: ["Auditor"]
             }
           }
         }
       }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

{{< /tab >}}

{{< /tabs >}}

### Groupes d'administrateurs {#administrator-groups}

Votre IdP doit transmettre les informations de groupe à GitLab dans la réponse OIDC. Pour utiliser cette réponse afin d'affecter des utilisateurs en tant qu'administrateurs en fonction de l'appartenance au groupe, configurez GitLab pour identifier :

- Où rechercher les groupes dans la réponse OIDC, en utilisant le paramètre `groups_attribute`.
- Les appartenances aux groupes accordant à l'utilisateur l'accès administrateur, en utilisant le paramètre `admin_groups`.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "openid_connect",
       label: "Provider name",
       args: {
         name: "openid_connect",
         scope: ["openid","profile","email"],
         response_type: "code",
         issuer: "<your_oidc_url>",
         discovery: true,
         client_auth_method: "query",
         uid_field: "<uid_field>",
         client_options: {
           identifier: "<your_oidc_client_id>",
           secret: "<your_oidc_client_secret>",
           redirect_uri: "<your_gitlab_url>/users/auth/openid_connect/callback",
           gitlab: {
             groups_attribute: "groups",
             admin_groups: ["Admin"]
           }
         }
       }
     }
   ]
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     omniauth:
       providers:
        - { name: 'openid_connect',
            label: 'Provider name',
         args: {
           name: 'openid_connect',
           scope: ['openid','profile','email'],
           response_type: 'code',
           issuer: '<your_oidc_url>',
           discovery: true,
           client_auth_method: 'query',
           uid_field: '<uid_field>',
           client_options: {
             identifier: '<your_oidc_client_id>',
             secret: '<your_oidc_client_secret>',
             redirect_uri: '<your_gitlab_url>/users/auth/openid_connect/callback',
             gitlab: {
               groups_attribute: "groups",
               admin_groups: ["Admin"]
             }
           }
         }
       }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

{{< /tab >}}

{{< /tabs >}}

### Configurer une durée personnalisée pour les jetons d'identifiant {#configure-a-custom-duration-for-id-tokens}

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/377654) dans GitLab 17.8.

{{< /history >}}

Par défaut, les jetons d'identifiant GitLab expirent après 120 secondes.

Pour configurer une durée personnalisée pour vos jetons d'identifiant :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['oidc_provider_openid_id_token_expire_in_seconds'] = 3600
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     oidc_provider:
      openid_id_token_expire_in_seconds: 3600
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

{{< /tab >}}

{{< /tabs >}}

## Authentification step-up {#step-up-authentication}

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed
- Statut :  Expérimental

{{< /details >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible pour les tests, mais n'est pas prête pour une utilisation en production.

Dans certains cas, les méthodes d'authentification par défaut ne protègent pas les ressources critiques ou les actions à haut risque. L'authentification step-up ajoute une couche supplémentaire pour les actions privilégiées ou les opérations sensibles. Par exemple, l'accès à la zone d'administration.

Avec l'authentification step-up, les utilisateurs doivent effectuer une authentification supplémentaire avec une [méthode d'authentification à deux facteurs](../../user/profile/account/two_factor_authentication.md) inscrite avant de pouvoir accéder à certaines fonctionnalités.

La norme OIDC inclut les références de classe de contexte d'authentification (`ACR`). Le concept `ACR` aide à configurer et à implémenter l'authentification step-up pour différents scénarios, tels que le mode administrateur.

Cette fonctionnalité est une [expérience](../../policy/development_stages_support.md) et est susceptible de changer sans préavis. Cette fonctionnalité n'est pas prête pour une utilisation en production. Si vous souhaitez utiliser cette fonctionnalité, vous devez d'abord la tester en dehors de la production.

### Activer l'authentification step-up pour le mode administrateur {#enable-step-up-authentication-for-admin-mode}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/474650) dans GitLab 17.11 [avec un flag](../feature_flags/_index.md) nommé `omniauth_step_up_auth_for_admin_mode`. Désactivé par défaut.

{{< /history >}} Pour activer l'authentification step-up pour le mode administrateur :

1. Modifiez votre fichier de configuration GitLab (`gitlab.yml` ou `/etc/gitlab/gitlab.rb`) pour activer l'authentification step-up pour un fournisseur OmniAuth spécifique.

   ```yaml
   production: &base
     omniauth:
       providers:
       - { name: 'openid_connect',
           label: 'Provider name',
           args: {
             name: 'openid_connect',
             # ...
             allow_authorize_params: ["claims"], # Match this to the parameters defined in `step_up_auth => admin_mode => params`
           },
           step_up_auth: {
             admin_mode: {
               # The `id_token` field defines the claims that must be included with the token.
               # You can specify claims in one or both of the `required` or `included` fields.
               # The token must include matching values for every claim you define in these fields.
               id_token: {
                 # The `required` field defines key-value pairs that must be included with the ID token.
                 # The values must match exactly what is defined.
                 # In this example, the 'acr' (Authentication Context Class Reference) claim
                 # must have the value 'gold' to pass the step-up authentication challenge.
                 # This ensures a specific level of authentication assurance.
                 required: {
                   acr: 'gold'
                 },
                 # The `included` field also defines key-value pairs that must be included with the ID token.
                 # Multiple accepted values can be defined in an array. If an array is not used, the value must match exactly.
                 # In this example, the 'amr' (Authentication Method References) claim
                 # must have a value of either 'mfa' or 'fpt' to pass the step-up authentication challenge.
                 # This is useful for scenarios where the user must provide additional authentication factors.
                 included: {
                   amr: ['mfa', 'fpt']
                 },
               },
               # The `params` field defines any additional parameters that are sent during the authentication process.
               # In this example, the `claims` parameter is added to the authorization request and instructs the
               # identity provider to include an 'acr' claim with the value 'gold' in the ID token.
               # The 'essential: true' indicates that this claim is required for successful authentication.
               params: {
                 claims: {
                   id_token: {
                     acr: {
                       essential: true,
                       values: ['gold']
                     }
                   }
                 }
               },
               # Optional: Provide a custom documentation link for users who fail step-up authentication
               # This link is displayed when step-up authentication fails, directing users to
               # organization-specific authentication documentation.
               documentation_link: 'https://internal.example.com/path/to/documentation'
             },
           }
         }
   ```

1. Enregistrez le fichier de configuration et redémarrez GitLab pour que les modifications prennent effet.

> [!note]
> Bien qu'OIDC soit standardisé, différents fournisseurs d'identité (IdP) peuvent avoir des exigences spécifiques. Le paramètre `params` permet un hash flexible pour définir les paramètres nécessaires à l'authentification step-up. Ces valeurs peuvent varier en fonction des exigences de chaque IdP.

### Exiger l'authentification step-up avec Keycloak {#require-step-up-authentication-with-keycloak}

Keycloak prend en charge l'authentification step-up en définissant des niveaux d'authentification et des flux de connexion de navigateur personnalisés.

Pour exiger l'authentification step-up pour le mode administrateur avec Keycloak :

1. [Configurez Keycloak](#configure-keycloak) dans GitLab.
1. Suivez les étapes de la documentation Keycloak pour [créer un flux de connexion de navigateur avec authentification step-up dans Keycloak](https://www.keycloak.org/docs/latest/server_admin/#_step-up-flow).
1. Modifiez votre fichier de configuration GitLab (`gitlab.yml` ou `/etc/gitlab/gitlab.rb`) pour activer l'authentification step-up dans la configuration du fournisseur OIDC Keycloak.

   Keycloak définit deux niveaux d'authentification différents : `silver` et `gold`. L'exemple suivant utilise `gold` pour représenter le niveau de sécurité accru.

   ```yaml
   production: &base
     omniauth:
       providers:
       - { name: 'openid_connect',
           label: 'Keycloak',
           args: {
             name: 'openid_connect',
             # ...
             allow_authorize_params: ["claims"] # Match this to the parameters defined in `step_up_auth => admin_mode => params`
           },
           step_up_auth: {
             admin_mode: {
               id_token: {
                 # In this example, the 'acr' claim must have the value 'gold' that is also defined in the Keycloak documentation.
                 required: {
                   acr: 'gold'
                 }
               },
               params: {
                 claims: {
                   id_token: {
                     acr: { essential: true, values: ['gold'] }
                   }
                 },
               },
               # Optional: Add a custom documentation link for Keycloak-specific step-up authentication help
               documentation_link: 'https://internal.example.com/path/to/documentation'
             },
           }
         }
   ```

1. Enregistrez le fichier de configuration et redémarrez GitLab pour que les modifications prennent effet.

### Exiger l'authentification step-up avec Microsoft Entra ID {#require-step-up-authentication-with-microsoft-entra-id}

Microsoft Entra ID (anciennement connu sous le nom d'Azure Active Directory) prend en charge l'authentification step-up via le [contexte d'authentification par accès conditionnel](https://learn.microsoft.com/en-us/entra/identity-platform/developer-guide-conditional-access-authentication-context). Vous devez travailler avec vos administrateurs Microsoft Entra ID pour définir la configuration correcte.

Tenez compte des aspects suivants :

- Les identifiants de contexte d'authentification sont demandés uniquement via la revendication `acrs`, et non via la revendication de jeton d'identifiant `acr` utilisée pour d'autres fournisseurs d'identité.
- Les identifiants de contexte d'authentification utilisent des valeurs fixes allant de `c1` à `c99`, chacun représentant un contexte d'authentification spécifique avec des stratégies d'accès conditionnel.
- Par défaut, Microsoft Entra ID n'inclut pas la revendication `acrs` dans le jeton d'identifiant. Pour activer cela, vous devez [configurer les revendications facultatives](https://learn.microsoft.com/en-us/entra/identity-platform/optional-claims?tabs=appui#configure-optional-claims-in-your-application).
- Lorsque l'authentification step-up réussit, la réponse renvoie la [revendication `acrs`](https://learn.microsoft.com/en-us/entra/identity-platform/access-token-claims-reference#payload-claims) sous forme de tableau JSON de chaînes. Par exemple : `acrs: ["c1", "c2", "c3"]`.

Pour exiger l'authentification step-up pour le mode administrateur avec Microsoft Entra ID :

1. [Configurez Microsoft Entra ID](#configure-microsoft-azure) dans GitLab.
1. Suivez les étapes de la documentation Microsoft Entra ID pour [définir les contextes d'authentification par accès conditionnel dans Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/identity-platform/developer-guide-conditional-access-authentication-context).
1. Dans Microsoft Entra ID, définissez [la revendication facultative `acrs` à inclure dans le jeton d'identifiant](https://openid.net/specs/openid-connect-core-1_0.html#IDToken).
1. Modifiez votre fichier de configuration GitLab (`gitlab.yml` ou `/etc/gitlab/gitlab.rb`) pour activer l'authentification step-up dans la configuration du fournisseur Microsoft Entra ID :

   ```yaml
   production: &base
     omniauth:
       providers:
       - { name: 'openid_connect',
         label: 'Azure OIDC',
         args: {
           name: 'openid_connect',
           # ...
           allow_authorize_params: ["claims"] # Match this to the parameters defined in `step_up_auth => admin_mode => params`
         },
         step_up_auth: {
           admin_mode: {
             id_token: {
               # In this example, the Microsoft Entra ID administrators have defined `c20`
               # as the authentication context ID with the desired security level and
               # an optional claim `acrs` to be included in the ID token.
               # The `included` field declares that the id token claim `acrs` must include the value `c20`.
               included: {
                 acrs: ["c20"],
               },
             },
             params: {
               claims: {
                 id_token: {
                   acrs: { essential: true, value: 'c20' }
                 }
               },
             },
             # Optional: Add a custom documentation link for Microsoft Entra ID step-up authentication
             documentation_link: 'https://internal.example.com/path/to/documentation'
           },
         }
       }
   ```

1. Enregistrez le fichier de configuration et redémarrez GitLab pour que les modifications prennent effet.

### Ajouter un fournisseur d'authentification step-up pour les groupes {#add-a-step-up-authentication-provider-for-groups}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/556943) dans GitLab 18.4 [avec un flag](../feature_flags/_index.md) nommé `omniauth_step_up_auth_for_namespace`. Désactivé par défaut.

{{< /history >}}

Vous pouvez également ajouter des fournisseurs d'authentification step-up disponibles pour tous les groupes de votre instance. Cela ne force pas les groupes à utiliser l'authentification step-up ; chaque groupe doit encore [configurer](#force-step-up-authentication-for-a-group) cette fonctionnalité individuellement.

Pour ajouter un fournisseur d'authentification step-up pour les groupes :

1. Modifiez votre fichier de configuration GitLab (`gitlab.yml` ou `/etc/gitlab/gitlab.rb`) pour activer l'authentification step-up pour un fournisseur OmniAuth spécifique.

   ```yaml
   production: &base
     omniauth:
       providers:
       - { name: 'openid_connect',
           label: 'Provider name',
           args: {
             name: 'openid_connect',
             # ...
             allow_authorize_params: ["claims"], # Match this to the parameters defined in `step_up_auth => admin_mode => params`
           },
           step_up_auth: {
             # Unlike step-up authentication configuration for Admin Mode, you use the `namespace`
             # object. This is because you're adding step-up authentication to access the entire
             # group, not just Admin Mode.
             namespace : {
               # The `id_token` field defines the claims that must be included with the token.
               # You can specify claims in one or both of the `required` or `included` fields.
               # The token must include matching values for every claim you define in these fields.
               id_token: {
                 # The `required` field defines key-value pairs that must be included with the ID token.
                 # The values must match exactly what is defined.
                 # In this example, the 'acr' (Authentication Context Class Reference) claim
                 # must have the value 'gold' to pass the step-up authentication challenge.
                 # This ensures a specific level of authentication assurance.
                 required: {
                   acr: 'gold'
                 },
                 # The `included` field also defines key-value pairs that must be included with the ID token.
                 # Multiple accepted values can be defined in an array. If an array is not used, the value must match exactly.
                 # In this example, the 'amr' (Authentication Method References) claim
                 # must have a value of either 'mfa' or 'fpt' to pass the step-up authentication challenge.
                 # This is useful for scenarios where the user must provide additional authentication factors.
                 included: {
                   amr: ['mfa', 'fpt']
                 },
               },
               # The `params` field defines any additional parameters that are sent during the authentication process.
               # In this example, the `claims` parameter is added to the authorization request and instructs the
               # identity provider to include an 'acr' claim with the value 'gold' in the ID token.
               # The 'essential: true' indicates that this claim is required for successful authentication.
               params: {
                 claims: {
                   id_token: {
                     acr: {
                       essential: true,
                       values: ['gold']
                     }
                   }
                 }
               }
             },
           }
         }
   ```

1. Enregistrez le fichier de configuration et redémarrez GitLab pour que les modifications prennent effet.

### Forcer l'authentification step-up pour un groupe {#force-step-up-authentication-for-a-group}

Vous pouvez forcer les utilisateurs à effectuer une authentification step-up avant d'accéder à un groupe. Ce paramètre est géré individuellement pour chaque groupe, mais nécessite un fournisseur d'authentification step-up préalablement ajouté pour l'ensemble de l'instance.

Prérequis :

- [Un fournisseur d'authentification step-up pour les groupes dans votre instance](#add-a-step-up-authentication-provider-for-groups).
- Vous devez disposer du rôle Propriétaire.

Pour forcer l'authentification step-up pour un groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez la section **Permissions et fonctionnalités du groupe**.
1. Sous Authentification step-up, sélectionnez un fournisseur d'authentification disponible.
1. Sélectionnez **Sauvegarder les modifications**.

### Ajouter des liens de documentation personnalisés pour l'authentification step-up {#add-custom-documentation-links-for-step-up-authentication}

Lorsque l'authentification step-up échoue, GitLab peut afficher des liens de documentation personnalisés pour aider les utilisateurs à comprendre les exigences d'authentification de votre organisation. Cette fonctionnalité permet aux administrateurs de fournir des conseils spécifiques à l'organisation qui dirigent les utilisateurs vers la documentation interne ou les ressources d'aide.

Pour ajouter des liens de documentation personnalisés :

1. Modifiez votre fichier de configuration GitLab (`gitlab.yml` ou `/etc/gitlab/gitlab.rb`) pour ajouter un champ `documentation_link` à `step_up_auth => admin_mode`

   ```yaml
   production: &base
     omniauth:
       providers:
       - { name: 'openid_connect',
           label: 'Corporate SSO',
           # ... other provider configuration ...
           step_up_auth: {
             admin_mode: {
               # ... id_token and params configuration ...
               documentation_link: 'https://internal.example.com/path/to/documentation'
             }
           }
         }
   ```

1. Enregistrez le fichier de configuration et redémarrez GitLab pour que les modifications prennent effet.

Lorsque les utilisateurs échouent à l'authentification step-up, ils voient un message d'erreur utile avec des liens vers la documentation pertinente pour les fournisseurs qui ont échoué. Les liens s'affichent uniquement pour les fournisseurs pour lesquels l'authentification step-up a réellement échoué, rendant les conseils plus pertinents et exploitables.

> [!note]
> Bonnes pratiques pour les liens de documentation :
>
> - Utilisez des URL HTTPS pour des raisons de sécurité.
> - Créez un lien vers la documentation interne qui explique les exigences d'authentification spécifiques à votre organisation.
> - Incluez des informations sur la façon d'activer `MFA` ou d'autres méthodes d'authentification requises.

### Désactiver l'expiration de session {#disable-session-expiration}

Par défaut, les sessions d'authentification step-up expirent en fonction du délai d'expiration du jeton du fournisseur d'identité (IdP), généralement environ 10 minutes.

Vous pouvez contrôler l'expiration de la session avec le paramètre `session_expiration_enabled` :

| Paramètre                                      | Comportement |
| -------------------------------------------- | -------- |
| `session_expiration_enabled: true` (par défaut) | L'authentification step-up expire en fonction de la revendication `exp` du jeton IdP. Cela représente généralement environ 10 minutes. |
| `session_expiration_enabled: false`          | L'authentification step-up reste valide pendant toute la session utilisateur jusqu'à la déconnexion de l'utilisateur. |

> [!warning]
> La désactivation de l'expiration de session signifie que les utilisateurs ne s'authentifient qu'une seule fois par session plutôt que de vérifier périodiquement leur identité. Ne désactivez ce paramètre que si vos exigences de sécurité autorisent une authentification step-up valable pour toute la durée de la session.

Pour désactiver l'expiration de session :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "openid_connect",
       label: "Provider name",
       args: {
         name: "openid_connect",
         # ... other args ...
       },
       step_up_auth: {
         session_expiration_enabled: false,  # Disable session expiration
         admin_mode: {
           # ... admin_mode config ...
         },
         namespace: {
           # ... namespace config ...
         }
       }
     }
   ]
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `config/gitlab.yml` :

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'openid_connect',
             label: 'Provider name',
             args: {
               name: 'openid_connect',
               # ... other args ...
             },
             step_up_auth: {
               session_expiration_enabled: false,
               admin_mode: {
                 # ... admin_mode config ...
               },
               namespace: {
                 # ... namespace config ...
               }
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

## Dépannage {#troubleshooting}

1. Vérifiez que `discovery` est défini sur `true`. Si vous le définissez sur `false`, vous devez spécifier toutes les URL et clés requises pour que OpenID fonctionne.
1. Vérifiez votre horloge système pour vous assurer que l'heure est correctement synchronisée.
1. Comme indiqué dans [la documentation OmniAuth OpenID Connect](https://github.com/omniauth/omniauth_openid_connect), assurez-vous que `issuer` correspond à l'URL de base de l'URL de découverte. Par exemple, `https://accounts.google.com` est utilisé pour l'URL `https://accounts.google.com/.well-known/openid-configuration`.
1. Le client OpenID Connect utilise l'authentification HTTP de base pour envoyer le jeton d'accès OAuth 2.0 si `client_auth_method` n'est pas défini ou s'il est défini sur `basic`. Si vous voyez des erreurs 401 lors de la récupération du point de terminaison `userinfo`, vérifiez la configuration de votre serveur web OpenID. Par exemple, pour [`oauth2-server-php`](https://github.com/bshaffer/oauth2-server-php) , vous devrez peut-être [ajouter un paramètre de configuration à Apache](https://github.com/bshaffer/oauth2-server-php/issues/926#issuecomment-387502778).
1. **Step-up authentication only** :  Vérifiez que tous les paramètres définis dans `step_up_auth => admin_mode => params` sont également définis dans `args => allow_authorize_params`. Cela inclut les paramètres dans les paramètres de requête de la requête utilisés pour la redirection vers le point de terminaison d'autorisation de l'IdP.
