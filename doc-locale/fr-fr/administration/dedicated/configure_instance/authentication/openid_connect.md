---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Configurer l'authentification par authentification unique (SSO) OpenID Connect pour GitLab Dedicated."
title: SSO OpenID Connect pour GitLab Dedicated
---

{{< details >}}

- Niveau : Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

Configurez l'authentification unique (SSO) OpenID Connect (OIDC) pour votre instance GitLab Dedicated afin d'authentifier les utilisateurs auprès de votre fournisseur d'identité.

Utilisez le SSO OIDC lorsque vous souhaitez :

- Centraliser l'authentification des utilisateurs via votre fournisseur d'identité existant.
- Réduire la charge de gestion des mots de passe pour les utilisateurs.
- Mettre en œuvre des contrôles d'accès cohérents dans les applications de votre organisation.
- Utiliser un protocole d'authentification moderne bénéficiant d'un large soutien industriel.

> [!note]
> Cette configuration concerne l'OIDC pour les utilisateurs finaux de votre instance GitLab Dedicated. Pour configurer le SSO pour les administrateurs Switchboard, consultez [configurer le SSO Switchboard](_index.md#configure-switchboard-sso).

## Configurer OpenID Connect {#configure-openid-connect}

Prérequis :

- Configurez votre fournisseur d'identité. Vous pouvez utiliser une URL de rappel temporaire, car GitLab fournit l'URL de rappel après la configuration.
- Assurez-vous que votre fournisseur d'identité prend en charge la spécification OpenID Connect.

Pour configurer l'OIDC pour votre instance GitLab Dedicated :

1. [Créez un ticket d'assistance](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650).
1. Dans votre ticket d'assistance, fournissez la configuration suivante :

   ```json
   {
     "label": "Login with OIDC",
     "issuer": "https://accounts.example.com",
     "discovery": true
   }
   ```

1. Fournissez votre identifiant client et votre secret client de manière sécurisée en utilisant un lien temporaire vers un gestionnaire de secrets auquel l'équipe d'assistance peut accéder.
1. Si votre fournisseur d'identité ne prend pas en charge la découverte automatique, incluez les options du point de terminaison client. Par exemple :

   ```json
   {
     "label": "Login with OIDC",
     "issuer": "https://example.com/accounts",
     "discovery": false,
     "client_options": {
       "end_session_endpoint": "https://example.com/logout",
       "authorization_endpoint": "https://example.com/authorize",
       "token_endpoint": "https://example.com/token",
       "userinfo_endpoint": "https://example.com/userinfo",
       "jwks_uri": "https://example.com/jwks"
     }
   }
   ```

Une fois que GitLab a configuré l'OIDC pour votre instance :

1. Vous recevez l'URL de rappel dans votre ticket d'assistance.
1. Mettez à jour votre fournisseur d'identité avec cette URL de rappel.
1. Vérifiez la configuration en recherchant le bouton de connexion SSO sur la page de connexion de votre instance.

## Configurer les utilisateurs en fonction de l'appartenance aux groupes OIDC {#configure-users-based-on-oidc-group-membership}

Vous pouvez configurer GitLab pour attribuer des rôles et des accès aux utilisateurs en fonction de leur appartenance aux groupes OIDC.

Prérequis :

- Votre fournisseur d'identité doit inclure les informations de groupe dans le point de terminaison `ID token` ou `userinfo`.
- Vous devez avoir déjà configuré l'authentification OIDC de base.

Pour configurer les utilisateurs en fonction de l'appartenance aux groupes OIDC :

1. Ajoutez le paramètre `groups_attribute` pour spécifier où GitLab doit rechercher les informations de groupe.
1. Configurez les tableaux de groupes appropriés selon vos besoins.
1. Dans votre ticket d'assistance, incluez la configuration de groupe dans votre bloc OIDC. Par exemple :

   ```json
   {
     "label": "Login with OIDC",
     "issuer": "https://accounts.example.com",
     "discovery": true,
     "groups_attribute": "groups",
     "required_groups": [
       "gitlab-users"
     ],
     "external_groups": [
       "external-contractors"
     ],
     "auditor_groups": [
       "auditors"
     ],
     "admin_groups": [
       "gitlab-admins"
     ]
   }
   ```

## Paramètres de configuration {#configuration-parameters}

Les paramètres suivants sont disponibles pour configurer l'OIDC pour les instances GitLab Dedicated. Pour plus d'informations, consultez [utiliser OpenID Connect comme fournisseur d'authentification](../../../auth/oidc.md).

### Paramètres requis {#required-parameters}

| Paramètre | Description |
|-----------|-------------|
| `issuer` | L'URL de l'émetteur OpenID Connect de votre fournisseur d'identité. |
| `label` | Nom d'affichage du bouton de connexion. |
| `discovery` | Indique si la découverte OpenID Connect doit être utilisée (recommandé : `true`). |

### Paramètres optionnels {#optional-parameters}

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|---------|
| `admin_groups` | Groupes disposant d'un accès administrateur. | `[]` |
| `auditor_groups` | Groupes disposant d'un accès auditeur. | `[]` |
| `client_auth_method` | Méthode d'authentification du client. | `"basic"` |
| `external_groups` | Groupes marqués comme utilisateurs externes. | `[]` |
| `groups_attribute` | Où rechercher les groupes dans la réponse OIDC. | Aucune |
| `pkce` | Activer PKCE (Proof Key for Code Exchange). | `false` |
| `required_groups` | Groupes requis pour l'accès. | `[]` |
| `response_mode` | Comment la réponse d'autorisation est transmise. | Aucune |
| `response_type` | Type de réponse OAuth 2.0. | `"code"` |
| `scope` | Portées OpenID Connect à demander. | `["openid"]` |
| `send_scope_to_token_endpoint` | Inclure le paramètre de portée dans les requêtes adressées au point de terminaison du jeton. | `true` |
| `uid_field` | Champ à utiliser comme identifiant unique. | `"sub"` |

### Exemples spécifiques aux fournisseurs {#provider-specific-examples}

#### Google {#google}

```json
{
  "label": "Google",
  "scope": ["openid", "profile", "email"],
  "response_type": "code",
  "issuer": "https://accounts.google.com",
  "client_auth_method": "query",
  "discovery": true,
  "uid_field": "preferred_username",
  "pkce": true
}
```

#### Microsoft Azure AD {#microsoft-azure-ad}

```json
{
  "label": "Azure AD",
  "scope": ["openid", "profile", "email"],
  "response_type": "code",
  "issuer": "https://login.microsoftonline.com/your-tenant-id/v2.0",
  "client_auth_method": "query",
  "discovery": true,
  "uid_field": "preferred_username",
  "pkce": true
}
```

#### Okta {#okta}

```json
{
  "label": "Okta",
  "scope": ["openid", "profile", "email", "groups"],
  "response_type": "code",
  "issuer": "https://your-domain.okta.com/oauth2/default",
  "client_auth_method": "query",
  "discovery": true,
  "uid_field": "preferred_username",
  "pkce": true
}
```

## Dépannage {#troubleshooting}

Si vous rencontrez des problèmes avec votre configuration OpenID Connect :

- Vérifiez que votre fournisseur d'identité est correctement configuré et accessible.
- Vérifiez que l'identifiant client et le secret fournis à l'assistance sont corrects.
- Assurez-vous que l'URI de redirection dans votre fournisseur d'identité correspond à celle fournie dans votre ticket d'assistance.
- Vérifiez que l'URL de l'émetteur est correcte et accessible.
