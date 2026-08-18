---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "GitLab en tant que fournisseur d'identité OpenID Connect"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez utiliser GitLab comme fournisseur d'identité [OpenID Connect](https://openid.net/developers/how-connect-works/) (OIDC) pour accéder à d'autres services. OIDC est une couche d'identité qui effectue de nombreuses tâches identiques à OpenID 2.0, mais est compatible avec les API et utilisable par les applications natives et mobiles.

Les clients peuvent utiliser OIDC pour :

- Vérifier l'identité d'un utilisateur final sur la base de l'authentification effectuée par GitLab.
- Obtenir des informations de profil de base sur l'utilisateur final de manière interopérable et similaire à REST.

Vous pouvez utiliser [OmniAuth::OpenIDConnect](https://github.com/omniauth/omniauth_openid_connect) pour les applications Rails et de nombreuses autres [implémentations clientes](https://openid.net/developers/certified-openid-connect-implementations/) sont disponibles.

GitLab utilise le gem `doorkeeper-openid_connect` pour fournir le service OIDC. Pour plus d'informations, consultez le [dépôt `doorkeeper-openid_connect`](https://github.com/doorkeeper-gem/doorkeeper-openid_connect "Doorkeeper::OpenidConnect repository").

Si certains utilisateurs utilisent GitLab uniquement comme fournisseur OIDC et n'ont pas besoin d'accéder aux projets ou groupes GitLab, envisagez de leur attribuer le rôle [accès minimum](../user/permissions.md#users-with-minimal-access) dans leur groupe principal. Les utilisateurs avec un accès minimum ne consomment pas de sièges dans l'abonnement et conservent l'accès lorsque l'[accès restreint](../subscriptions/manage_seats.md#restricted-access) est actif et qu'aucun siège n'est disponible.

## Activer OIDC pour les applications OAuth {#enable-oidc-for-oauth-applications}

Pour activer OIDC pour une application OAuth, vous devez sélectionner la portée `openid` dans les paramètres de l'application. Pour plus d'informations, consultez [Configurer GitLab en tant que fournisseur d'identité d'authentification OAuth 2.0](oauth_provider.md).

## Découverte des paramètres {#settings-discovery}

Si votre client peut importer des paramètres OIDC depuis une URL de découverte, GitLab fournit des endpoints pour accéder à ces informations :

- Pour GitLab.com, utilisez `https://gitlab.com/.well-known/openid-configuration`.
- Pour GitLab Self-Managed, utilisez `https://<your-gitlab-instance>/.well-known/openid-configuration`

## Informations partagées {#shared-information}

Les informations utilisateur suivantes sont partagées avec les clients :

| Réclamation                | Type      | Description | Inclus dans le jeton d'ID | Inclus dans l'endpoint `userinfo` |
|:---------------------|:----------|:------------|:---------------------|:------------------------------|
| `sub`                | `string`  | L'identifiant de l'utilisateur | {{< yes >}} | {{< yes >}} |
| `auth_time`          | `integer` | L'horodatage de la dernière authentification de l'utilisateur | {{< yes >}} | {{< no >}} |
| `name`               | `string`  | Le nom complet de l'utilisateur | {{< yes >}} | {{< yes >}} |
| `nickname`           | `string`  | Le nom d'utilisateur GitLab de l'utilisateur | {{< yes >}}| {{< yes >}} |
| `preferred_username` | `string`  | Le nom d'utilisateur GitLab de l'utilisateur | {{< yes >}} | {{< yes >}} |
| `given_name`         | `string`  | Le prénom de l'utilisateur | {{< yes >}} | {{< yes >}} |
| `family_name`        | `string`  | Le nom de famille de l'utilisateur | {{< yes >}} | {{< yes >}} |
| `email`              | `string`  | L'adresse e-mail principale de l'utilisateur | {{< yes >}} | {{< yes >}} |
| `email_verified`     | `boolean` | Indique si l'adresse e-mail de l'utilisateur est vérifiée | {{< yes >}} | {{< yes >}} |
| `website`            | `string`  | URL du site web de l'utilisateur | {{< yes >}} | {{< yes >}} |
| `profile`            | `string`  | URL du profil GitLab de l'utilisateur | {{< yes >}} | {{< yes >}}|
| `picture`            | `string`  | URL de l'avatar GitLab de l'utilisateur | {{< yes >}}| {{< yes >}} |
| `groups`             | `array`   | Chemins des groupes dont l'utilisateur est membre, directement ou via un groupe ancêtre. | {{< no >}} | {{< yes >}} |
| `groups_direct`      | `array`   | Chemins des groupes dont l'utilisateur est membre direct. | {{< yes >}} | {{< no >}} |
| `https://gitlab.org/claims/groups/owner`      | `array`   | Noms des groupes dont l'utilisateur est membre direct avec le rôle Owner | {{< no >}} | {{< yes >}} |
| `https://gitlab.org/claims/groups/maintainer` | `array`   | Noms des groupes dont l'utilisateur est membre direct avec le rôle Maintainer | {{< no >}} | {{< yes >}} |
| `https://gitlab.org/claims/groups/developer`  | `array`   | Noms des groupes dont l'utilisateur est membre direct avec le rôle Developer | {{< no >}} | {{< yes >}} |

Les réclamations `email` et `email_verified` ne sont incluses que si l'application a accès à la portée `email` et à l'adresse e-mail publique de l'utilisateur. Toutes les autres réclamations sont disponibles depuis l'endpoint `/oauth/userinfo` utilisé par les clients OIDC.
