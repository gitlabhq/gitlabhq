---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Autorisation tierce pour GitLab.
title: "API du fournisseur d'identité OAuth 2.0"
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour permettre à des services tiers d'accéder aux ressources GitLab pour un utilisateur avec le protocole [OAuth 2.0](https://oauth.net/2/). Pour plus d'informations, voir [Configurer GitLab en tant que fournisseur d'identité d'authentification OAuth 2.0](../integration/oauth_provider.md).

Cette fonctionnalité est basée sur le [gem Ruby doorkeeper](https://github.com/doorkeeper-gem/doorkeeper).

## Partage des ressources entre origines multiples {#cross-origin-resource-sharing}

{{< history >}}

- Prise en charge des requêtes de pré-vérification CORS [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/364680) dans GitLab 15.1.

{{< /history >}}

De nombreux points de terminaison `/oauth` prennent en charge le partage des ressources entre origines multiples (CORS). Depuis GitLab 15.1, les points de terminaison suivants prennent également en charge les [requêtes de pré-vérification CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) :

- `/oauth/revoke`
- `/oauth/token`
- `/oauth/userinfo`

Seuls certains en-têtes peuvent être utilisés pour les requêtes de pré-vérification :

- Les en-têtes répertoriés pour les [requêtes simples](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#simple_requests).
- L'en-tête `Authorization`.

Par exemple, l'en-tête `X-Requested-With` ne peut pas être utilisé pour les requêtes de pré-vérification.

## Flux OAuth 2.0 pris en charge {#supported-oauth-20-flows}

GitLab prend en charge les flux d'autorisation suivants :

- **Code d'autorisation avec [Proof Key for Code Exchange (PKCE)](https://www.rfc-editor.org/rfc/rfc7636)** :  Le plus sécurisé. Sans PKCE, vous devriez inclure les secrets client sur les clients mobiles, et il est recommandé pour les applications client et serveur.
- **Authorization code** :  Flux sécurisé et courant. Option recommandée pour les applications côté serveur sécurisées.
- **Device Authorization Grant** (GitLab 17.1 et versions ultérieures) Flux sécurisé orienté vers les appareils sans accès au navigateur. Nécessite un appareil secondaire pour terminer le flux d'autorisation.

La spécification préliminaire d'[OAuth 2.1](https://oauth.net/2.1/) omet spécifiquement les flux Implicit grant et Resource Owner Password Credentials.

Consultez le [RFC OAuth](https://www.rfc-editor.org/rfc/rfc6749) pour savoir comment fonctionnent tous ces flux et choisir celui qui convient à votre cas d'utilisation.

Le flux de code d'autorisation (avec ou sans PKCE) nécessite que l'`application` soit d'abord enregistré via la page `/user_settings/applications` dans le compte de votre utilisateur. Lors de l'enregistrement, en activant les portées appropriées, vous pouvez limiter la plage de ressources à laquelle l'`application` peut accéder. Lors de la création, vous obtenez les identifiants de l'`application` :  _Application ID_ et _Client Secret_. Le _Client Secret_ **must be kept secure**. Il est également avantageux de garder secret l'_Application ID_ lorsque l'architecture de votre application le permet.

Pour obtenir la liste des portées dans GitLab, voir [la documentation du fournisseur](../integration/oauth_provider.md#view-all-authorized-applications).

### Prévenir les attaques CSRF {#prevent-csrf-attacks}

Pour [protéger les flux basés sur les redirections](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics-13#section-3.1), la spécification OAuth recommande l'utilisation de « jetons CSRF à usage unique transmis dans le paramètre state, liés de manière sécurisée à l'agent utilisateur », avec chaque requête au point de terminaison `/oauth/authorize`. Cela peut prévenir les [attaques CSRF](https://wiki.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)).

### Utiliser HTTPS en production {#use-https-in-production}

Pour la production, utilisez HTTPS pour votre `redirect_uri`. Pour le développement, GitLab autorise les URI de redirection HTTP non sécurisées.

Étant donné qu'OAuth 2.0 fonde entièrement sa sécurité sur la couche de transport, vous ne devez pas utiliser des URI non protégées. Pour plus d'informations, voir le [RFC OAuth 2.0](https://www.rfc-editor.org/rfc/rfc6749#section-3.1.2.1) et le [RFC du modèle de menace OAuth 2.0](https://www.rfc-editor.org/rfc/rfc6819#section-4.4.2.1).

Dans les sections suivantes, vous trouverez des instructions détaillées sur la manière d'obtenir une autorisation avec chaque flux.

### Code d'autorisation avec Proof Key for Code Exchange (PKCE) {#authorization-code-with-proof-key-for-code-exchange-pkce}

{{< history >}}

- Prise en charge de SAML SSO de groupe pour les applications OAuth [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/461212) dans GitLab 18.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `ff_oauth_redirect_to_sso_login`. Désactivé par défaut.
- Prise en charge de SAML SSO de groupe pour les applications OAuth [activée sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200682) dans GitLab 18.3.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/561778) dans GitLab 18.5. L'indicateur de fonctionnalité `ff_oauth_redirect_to_sso_login` a été supprimé.

{{< /history >}}

Le [RFC PKCE](https://www.rfc-editor.org/rfc/rfc7636#section-1.1) inclut une description détaillée du flux, de la demande d'autorisation jusqu'au jeton d'accès. Les étapes suivantes décrivent notre implémentation du flux.

Le flux de code d'autorisation avec PKCE, PKCE en abrégé, permet d'effectuer en toute sécurité l'échange OAuth des identifiants client contre des jetons d'accès sur des clients publics sans nécessiter d'accès au _Client Secret_. Cela rend le flux PKCE avantageux pour les applications JavaScript à page unique ou d'autres applications côté client où garder des secrets à l'utilisateur est techniquement impossible.

Avant de démarrer le flux, générez le `STATE`, le `CODE_VERIFIER` et le `CODE_CHALLENGE`.

- Le `STATE` est une valeur imprévisible utilisée par le client pour maintenir l'état entre la requête et le rappel. Il doit également être utilisé comme jeton CSRF.
- Le `CODE_VERIFIER` est une chaîne aléatoire, d'une longueur comprise entre 43 et 128 caractères, qui utilise les caractères `A-Z`, `a-z`, `0-9`, `-`, `.`, `_` et `~`.
- Le `CODE_CHALLENGE` est une chaîne encodée en base64 sécurisée pour les URL du hachage SHA256 du `CODE_VERIFIER` :
  - Le hachage SHA256 doit être au format binaire avant l'encodage.
  - En Ruby, vous pouvez le configurer avec `Base64.urlsafe_encode64(Digest::SHA256.digest(CODE_VERIFIER), padding: false)`.
  - À titre de référence, une chaîne `CODE_VERIFIER` de `ks02i3jdikdo2k0dkfodf3m39rjfjsdk0wk349rj3jrhf` lorsqu'elle est hachée et encodée à l'aide du précédent extrait Ruby produit une chaîne `CODE_CHALLENGE` de `2i0WFA-0AerkjQm4X4oDEhqA17QIAKNjXpagHBXmO_U`.

1. Demandez le code d'autorisation. Pour ce faire, vous devez rediriger l'utilisateur vers la page `/oauth/authorize` avec les paramètres de requête suivants :

   ```plaintext
   https://gitlab.example.com/oauth/authorize?client_id=APP_ID&redirect_uri=REDIRECT_URI&response_type=code&state=STATE&scope=REQUESTED_SCOPES&code_challenge=CODE_CHALLENGE&code_challenge_method=S256&root_namespace_id=ROOT_NAMESPACE_ID
   ```

   Cette page demande à l'utilisateur d'approuver la demande de l'application pour accéder à son compte en fonction des portées spécifiées dans `REQUESTED_SCOPES`. L'utilisateur est ensuite redirigé vers l'`REDIRECT_URI` spécifié. Le [paramètre de portée](../integration/oauth_provider.md#view-all-authorized-applications) est une liste de portées associées à l'utilisateur, séparées par des espaces. Par exemple, `scope=read_user+profile` demande les portées `read_user` et `profile`. Le `root_namespace_id` est l'ID d'espace de nommage racine associé au projet. Ce paramètre facultatif doit être utilisé lorsque [SAML SSO](../user/group/saml_sso/_index.md) est configuré pour le groupe associé. La redirection inclut le `code` d'autorisation, par exemple :

   ```plaintext
   https://example.com/oauth/redirect?code=1234567890&state=STATE
   ```

1. Avec le `code` d'autorisation renvoyé par la requête précédente (désigné comme `RETURNED_CODE` dans l'exemple suivant), vous pouvez demander un `access_token`, avec n'importe quel client HTTP. L'exemple suivant utilise `rest-client` de Ruby :

   ```ruby
   parameters = 'client_id=APP_ID&code=RETURNED_CODE&grant_type=authorization_code&redirect_uri=REDIRECT_URI&code_verifier=CODE_VERIFIER'
   RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

   Exemple de réponse :

   ```json
   {
    "access_token": "de6780bc506a0446309bd9362820ba8aed28aa506c71eedbe1c5c4f9dd350e54",
    "token_type": "bearer",
    "expires_in": 7200,
    "refresh_token": "8257e65c97202ed1726cf9571600918f3bffb2544b26e00a61df9897668c33a1",
    "created_at": 1607635748
   }
   ```

1. Pour récupérer un nouveau `access_token`, utilisez le paramètre `refresh_token`. Les jetons d'actualisation peuvent être utilisés même après l'expiration de l'`access_token` lui-même. Cette requête :
   - Invalide l'`access_token` et le `refresh_token` existants.
   - Envoie de nouveaux jetons dans la réponse.

   ```ruby
     parameters = 'client_id=APP_ID&refresh_token=REFRESH_TOKEN&grant_type=refresh_token&redirect_uri=REDIRECT_URI'
     RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

   Exemple de réponse :

   ```json
   {
     "access_token": "c97d1fe52119f38c7f67f0a14db68d60caa35ddc86fd12401718b649dcfa9c68",
     "token_type": "bearer",
     "expires_in": 7200,
     "refresh_token": "803c1fd487fec35562c205dac93e9d8e08f9d3652a24079d704df3039df1158f",
     "created_at": 1628711391
   }
   ```

> [!note]
> Le `redirect_uri` doit correspondre au `redirect_uri` utilisé dans la requête d'autorisation originale.

Vous pouvez maintenant effectuer des requêtes vers l'API avec le jeton d'accès.

### Flux de code d'autorisation {#authorization-code-flow}

{{< history >}}

- Prise en charge de SAML SSO de groupe pour les applications OAuth [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/461212) dans GitLab 18.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `ff_oauth_redirect_to_sso_login`. Désactivé par défaut.
- Prise en charge de SAML SSO de groupe pour les applications OAuth [activée sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200682) dans GitLab 18.3.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/561778) dans GitLab 18.5. L'indicateur de fonctionnalité `ff_oauth_redirect_to_sso_login` a été supprimé.

{{< /history >}}

> [!note]
> Consultez la [spécification RFC](https://www.rfc-editor.org/rfc/rfc6749#section-4.1) pour une description détaillée du flux.

Le flux de code d'autorisation est essentiellement identique au [flux de code d'autorisation avec PKCE](#authorization-code-with-proof-key-for-code-exchange-pkce),

Avant de démarrer le flux, générez le `STATE`. Il s'agit d'une valeur imprévisible utilisée par le client pour maintenir l'état entre la requête et le rappel. Il doit également être utilisé comme jeton CSRF.

1. Demandez le code d'autorisation. Pour ce faire, vous devez rediriger l'utilisateur vers la page `/oauth/authorize` avec les paramètres de requête suivants :

   ```plaintext
   https://gitlab.example.com/oauth/authorize?client_id=APP_ID&redirect_uri=REDIRECT_URI&response_type=code&state=STATE&scope=REQUESTED_SCOPES&root_namespace_id=ROOT_NAMESPACE_ID
   ```

   Cette page demande à l'utilisateur d'approuver la demande de l'application pour accéder à son compte en fonction des portées spécifiées dans `REQUESTED_SCOPES`. L'utilisateur est ensuite redirigé vers l'`REDIRECT_URI` spécifié. Le [paramètre de portée](../integration/oauth_provider.md#view-all-authorized-applications) est une liste de portées associées à l'utilisateur, séparées par des espaces. Par exemple, `scope=read_user+profile` demande les portées `read_user` et `profile`. Le `root_namespace_id` est l'ID d'espace de nommage racine associé au projet. Ce paramètre facultatif doit être utilisé lorsque [SAML SSO](../user/group/saml_sso/_index.md) est configuré pour le groupe associé. La redirection inclut le `code` d'autorisation, par exemple :

   ```plaintext
   https://example.com/oauth/redirect?code=1234567890&state=STATE
   ```

1. Avec le `code` d'autorisation renvoyé par la requête précédente (indiqué comme `RETURNED_CODE` dans l'exemple suivant), vous pouvez demander un `access_token`, avec n'importe quel client HTTP. L'exemple suivant utilise `rest-client` de Ruby :

   ```ruby
   parameters = 'client_id=APP_ID&client_secret=APP_SECRET&code=RETURNED_CODE&grant_type=authorization_code&redirect_uri=REDIRECT_URI'
   RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

   Exemple de réponse :

   ```json
   {
    "access_token": "de6780bc506a0446309bd9362820ba8aed28aa506c71eedbe1c5c4f9dd350e54",
    "token_type": "bearer",
    "expires_in": 7200,
    "refresh_token": "8257e65c97202ed1726cf9571600918f3bffb2544b26e00a61df9897668c33a1",
    "created_at": 1607635748
   }
   ```

1. Pour récupérer un nouveau `access_token`, utilisez le paramètre `refresh_token`. Les jetons d'actualisation peuvent être utilisés même après l'expiration de l'`access_token` lui-même. Cette requête :
   - Invalide l'`access_token` et le `refresh_token` existants.
   - Envoie de nouveaux jetons dans la réponse.

   ```ruby
     parameters = 'client_id=APP_ID&client_secret=APP_SECRET&refresh_token=REFRESH_TOKEN&grant_type=refresh_token&redirect_uri=REDIRECT_URI'
     RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

   Exemple de réponse :

   ```json
   {
     "access_token": "c97d1fe52119f38c7f67f0a14db68d60caa35ddc86fd12401718b649dcfa9c68",
     "token_type": "bearer",
     "expires_in": 7200,
     "refresh_token": "803c1fd487fec35562c205dac93e9d8e08f9d3652a24079d704df3039df1158f",
     "created_at": 1628711391
   }
   ```

> [!note]
> Le `redirect_uri` doit correspondre au `redirect_uri` utilisé dans la requête d'autorisation originale.

Vous pouvez maintenant effectuer des requêtes vers l'API avec le jeton d'accès renvoyé.

### Flux d'octroi d'autorisation d'appareil {#device-authorization-grant-flow}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/332682) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `oauth2_device_grant_flow`.
- [Activé](https://gitlab.com/gitlab-org/gitlab/-/issues/468479) par défaut dans la version 17.3.
- [Disponible de manière générale](https://gitlab.com/gitlab-org/gitlab/-/issues/505557) dans GitLab 17.9. L'indicateur de fonctionnalité `oauth2_device_grant_flow` a été supprimé.

{{< /history >}}

> [!note]
> Consultez la [spécification RFC](https://datatracker.ietf.org/doc/html/rfc8628#section-3.1) pour une description détaillée du flux d'octroi d'autorisation d'appareil, de la demande d'autorisation d'appareil à la réponse de jeton depuis la connexion au navigateur.

Le flux d'octroi d'autorisation d'appareil permet d'authentifier en toute sécurité votre identité GitLab depuis des appareils à saisie limitée où les interactions avec le navigateur ne sont pas envisageables.

Cela rend le flux d'octroi d'autorisation d'appareil idéal pour les utilisateurs qui tentent d'utiliser les services GitLab depuis des serveurs sans interface graphique ou d'autres appareils avec une interface utilisateur inexistante ou limitée.

1. Pour demander l'autorisation d'un appareil, une requête est envoyée depuis le client de l'appareil à saisie limitée vers `https://gitlab.example.com/oauth/authorize_device`. Par exemple :

   ```ruby
     parameters = 'client_id=UID&scope=read'
     RestClient.post 'https://gitlab.example.com/oauth/authorize_device', parameters
   ```

   Après une requête réussie, une réponse contenant un `verification_uri` est renvoyée à l'utilisateur. Par exemple :

   ```json
   {
       "device_code": "GmRhmhcxhwAzkoEqiMEg_DnyEysNkuNhszIySk9eS",
       "user_code": "0A44L90H",
       "verification_uri": "https://gitlab.example.com/oauth/device",
       "verification_uri_complete": "https://gitlab.example.com/oauth/device?user_code=0A44L90H",
       "expires_in": 300,
       "interval": 5
   }
   ```

1. Le client de l'appareil affiche le `user_code` et le `verification_uri` de la réponse à l'utilisateur demandeur. Cet utilisateur, sur un appareil secondaire avec accès au navigateur :
   1. Accède à l'URI fournie.
   1. Saisit le code utilisateur.
   1. Effectue une authentification comme demandé.

1. Immédiatement après avoir affiché le `verification_uri` et le `user_code`, le client de l'appareil commence à interroger le point de terminaison de jeton avec le `device_code` associé renvoyé dans la réponse initiale :

   ```ruby
   parameters = 'grant_type=urn:ietf:params:oauth:grant-type:device_code
   &device_code=GmRhmhcxhwAzkoEqiMEg_DnyEysNkuNhszIySk9eS
   &client_id=1406020730'
   RestClient.post 'https://gitlab.example.com/oauth/token', parameters
   ```

1. Le client de l'appareil reçoit une réponse du point de terminaison de jeton. Si l'autorisation a réussi, une réponse de succès est renvoyée ; sinon, une réponse d'erreur est renvoyée. Les réponses d'erreur potentielles sont catégorisées par l'une des situations suivantes :

   - Celles définies par les réponses d'erreur de jeton d'accès du cadre d'autorisation OAuth.
   - Celles spécifiques au flux d'octroi d'autorisation d'appareil décrit ici.

   Ces réponses d'erreur spécifiques au flux d'appareil sont décrites dans le contenu suivant. Pour plus d'informations sur chaque réponse potentielle, voir la [spécification RFC pour l'octroi d'autorisation d'appareil](https://datatracker.ietf.org/doc/html/rfc8628#section-3.5) et la [spécification RFC pour les jetons d'autorisation](https://datatracker.ietf.org/doc/html/rfc6749#section-5.2).

   Exemple de réponse :

   ```json
   {
     "error": "authorization_pending",
     "error_description": "..."
   }
   ```

   À la réception de cette réponse, le client de l'appareil continue d'interroger.

   Si l'intervalle d'interrogation est trop court, une réponse d'erreur de ralentissement est renvoyée. Par exemple :

    ```json
    {
      "error": "slow_down",
      "error_description": "..."
    }
    ```

   À la réception de cette réponse, le client de l'appareil réduit son taux d'interrogation et continue d'interroger au nouveau taux.

   Si le code de l'appareil expire avant la fin de l'authentification, une réponse d'erreur de jeton expiré est renvoyée. Par exemple :

   ```json
   {
     "error": "expired_token",
     "error_description": "..."
   }
   ```

   À ce stade, le client de l'appareil doit s'arrêter et initier une nouvelle demande d'autorisation d'appareil.

   Si la demande d'autorisation a été refusée, une réponse d'erreur d'accès refusé est renvoyée. Par exemple :

   ```json
   {
     "error": "access_denied",
     "error_description": "..."
   }
   ```

   La demande d'authentification a été rejetée. L'utilisateur doit vérifier ses identifiants ou contacter son administrateur système.

1. Une fois que l'utilisateur s'est authentifié avec succès, une réponse de succès est renvoyée :

   ```json
   {
       "access_token": "TOKEN",
       "token_type": "Bearer",
       "expires_in": 7200,
       "scope": "read",
       "created_at": 1593096829
   }
   ```

À ce stade, le flux d'authentification de l'appareil est terminé. L'`access_token` renvoyé peut être fourni à GitLab pour authentifier l'identité de l'utilisateur lors de l'accès aux ressources GitLab, par exemple lors d'un clonage via HTTPS ou de l'accès à l'API.

Un exemple d'application implémentant le flux d'appareil côté client est disponible à l'adresse : <https://gitlab.com/johnwparent/git-auth-over-https>.

## Accéder à l'API GitLab avec `access token` {#access-gitlab-api-with-access-token}

L'`access token` vous permet d'effectuer des requêtes vers l'API au nom d'un utilisateur. Vous pouvez transmettre le jeton soit en tant que paramètre GET :

```plaintext
GET https://gitlab.example.com/api/v4/user?access_token=<OAUTH-TOKEN>
```

ou vous pouvez placer le jeton dans l'en-tête Authorization :

```shell
curl --header "Authorization: Bearer <OAUTH-TOKEN>" \
  --url "https://gitlab.example.com/api/v4/user"
```

## Accéder à Git via HTTPS avec `access token` {#access-git-over-https-with-access-token}

Un jeton avec la [portée](../integration/oauth_provider.md#view-all-authorized-applications) `read_repository` ou `write_repository` peut accéder à Git via HTTPS. Utilisez le jeton comme mot de passe. Vous pouvez définir le nom d'utilisateur sur n'importe quelle valeur de chaîne. Vous devez utiliser `oauth2` :

```plaintext
https://oauth2:<your_access_token>@gitlab.example.com/project_path/project_name.git
```

Vous pouvez également utiliser un [assistant d'identifiants Git](../user/profile/account/two_factor_authentication.md#oauth-credential-helpers) pour vous authentifier auprès de GitLab avec OAuth. Cela gère automatiquement l'actualisation du jeton OAuth.

## Récupérer les informations sur le jeton {#retrieve-the-token-information}

Pour vérifier les détails d'un jeton, utilisez le point de terminaison `token/info` fourni par le gem Doorkeeper. Pour plus d'informations, consultez [`/oauth/token/info`](https://github.com/doorkeeper-gem/doorkeeper/wiki/API-endpoint-descriptions-and-examples#get----oauthtokeninfo).

Vous devez fournir le jeton d'accès, soit :

- En tant que paramètre :

  ```plaintext
  GET https://gitlab.example.com/oauth/token/info?access_token=<OAUTH-TOKEN>
  ```

- Dans l'en-tête Authorization :

  ```shell
  curl --header "Authorization: Bearer <OAUTH-TOKEN>" \
    --url "https://gitlab.example.com/oauth/token/info"
  ```

Voici un exemple de réponse :

```json
{
    "resource_owner_id": 1,
    "scope": ["api"],
    "expires_in": null,
    "application": {"uid": "1cb242f495280beb4291e64bee2a17f330902e499882fe8e1e2aa875519cab33"},
    "created_at": 1575890427
}
```

### Champs obsolètes {#deprecated-fields}

Les champs `scopes` et `expires_in_seconds` sont inclus dans la réponse mais sont désormais obsolètes. Le champ `scopes` est un alias pour `scope`, et le champ `expires_in_seconds` est un alias pour `expires_in`. Pour plus d'informations, voir [Modifications de l'API Doorkeeper](https://github.com/doorkeeper-gem/doorkeeper/wiki/Migration-from-old-versions#api-changes-5).

## Révoquer un jeton {#revoke-a-token}

Pour révoquer un jeton, utilisez le point de terminaison `revoke`. L'API renvoie un code de réponse 200 et un hash JSON vide pour indiquer le succès.

```ruby
parameters = 'client_id=APP_ID&client_secret=APP_SECRET&token=TOKEN'
RestClient.post 'https://gitlab.example.com/oauth/revoke', parameters
```

## Jetons OAuth 2.0 et registres GitLab {#oauth-20-tokens-and-gitlab-registries}

Les jetons OAuth 2.0 standard prennent en charge différents niveaux d'accès aux registres GitLab, car ils :

- Ne permettent pas aux utilisateurs de s'authentifier auprès de :
  - Le [registre de conteneurs](../user/packages/container_registry/authenticate_with_container_registry.md) GitLab.
  - Les paquets répertoriés dans le [registre de paquets](../user/packages/package_registry/_index.md) GitLab.
  - [Registres virtuels](../user/packages/virtual_registry/_index.md).
- Permettent aux utilisateurs d'obtenir, de lister et de supprimer des registres via l'[API du registre de conteneurs](container_registry.md).
- Permettent aux utilisateurs d'obtenir, de lister et de supprimer des objets de registre via l'[API du registre virtuel Maven](maven_virtual_registries.md).
