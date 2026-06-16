---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Configurer les méthodes d'authentification pour GitLab Dedicated."
title: Authentification pour GitLab Dedicated
---

{{< details >}}

- Niveau : Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

GitLab Dedicated dispose de deux contextes d'authentification distincts :

- Authentification Switchboard :  Comment les administrateurs se connectent pour gérer les instances GitLab Dedicated.
- Authentification de l'instance :  Comment les utilisateurs finaux se connectent à votre instance GitLab Dedicated.

Switchboard est la console de gestion de votre instance GitLab Dedicated, distincte de l'instance elle-même.

## Authentification Switchboard {#switchboard-authentication}

Les administrateurs utilisent Switchboard pour gérer les instances, les utilisateurs et la configuration.

Switchboard prend en charge les méthodes d'authentification suivantes :

- Authentification unique (SSO) avec SAML ou OIDC
- E-mail et mot de passe

### Configurer le SSO Switchboard {#configure-switchboard-sso}

Activez l'authentification unique (SSO) pour Switchboard afin de l'intégrer au fournisseur d'identité de votre organisation. Switchboard prend en charge les protocoles SAML et OIDC.

> [!note]
> Ceci configure le SSO pour les administrateurs Switchboard qui gèrent votre instance GitLab Dedicated.

Pour configurer le SSO pour Switchboard :

1. Rassemblez les informations requises pour le protocole de votre choix :
   - [Paramètres SAML](#saml-parameters-for-switchboard)
   - [Paramètres OIDC](#oidc-parameters-for-switchboard)
1. [Soumettez un ticket de support](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) avec les informations.
1. Configurez votre fournisseur d'identité avec les informations fournies par GitLab.

#### Paramètres SAML pour Switchboard {#saml-parameters-for-switchboard}

Lors de la demande de configuration SAML, vous devez fournir :

| Paramètre                 | Description |
| ------------------------- | ----------- |
| URL des métadonnées              | L'URL qui pointe vers le document de métadonnées SAML de votre fournisseur d'identité. Elle se termine généralement par `/saml/metadata.xml` ou est disponible dans la section de configuration SSO de votre fournisseur d'identité. |
| Mappage des attributs d'e-mail   | Le format utilisé par votre fournisseur d'identité pour représenter les adresses e-mail. Par exemple, dans Auth0, il peut s'agir de `http://schemas.auth0.com/email`. |
| Méthode de requête des attributs | La méthode HTTP (GET ou POST) à utiliser lors de la demande d'attributs auprès de votre fournisseur d'identité. Consultez la documentation de votre fournisseur d'identité pour connaître la méthode recommandée. |
| Domaine de messagerie des utilisateurs         | La partie domaine des adresses e-mail de vos utilisateurs (par exemple, `gitlab.com`). |

GitLab fournit les informations suivantes pour que vous les configuriez dans votre fournisseur d'identité :

| Paramètre           | Description |
| ------------------- | ----------- |
| URL de rappel/ACS    | L'URL vers laquelle votre fournisseur d'identité doit envoyer les réponses SAML après authentification. |
| Attributs requis | Les attributs qui doivent être inclus dans la réponse SAML. Au minimum, un attribut mappé à `email` est requis. |

Lors de la configuration de votre fournisseur d'identité, veillez à chiffrer les assertions SAML. GitLab peut fournir des certificats de chiffrement et de signature si nécessaire.

Reportez-vous à la documentation de votre fournisseur d'identité pour les étapes d'importation des certificats. Pour Entra ID (Azure AD), voir :

- [Configure Microsoft Entra SAML token encryption](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/howto-saml-token-encryption?tabs=azure-portal)
- [Enforce signed SAML authentication requests](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/howto-enforce-signed-saml-authentication)

> [!note]
> GitLab Dedicated ne prend pas en charge le SAML initié par le fournisseur d'identité (IdP).

#### Paramètres OIDC pour Switchboard {#oidc-parameters-for-switchboard}

Lors de la demande de configuration OIDC, vous devez fournir :

| Paramètre       | Description |
| --------------- | ----------- |
| URL de l'émetteur      | L'URL de base qui identifie de manière unique votre fournisseur OIDC. Cette URL pointe généralement vers le document de découverte de votre fournisseur situé à `https://[your-idp-domain]/.well-known/openid-configuration`. |
| Points de terminaison de jeton | Les URL spécifiques de votre fournisseur d'identité utilisées pour obtenir et valider les jetons d'authentification. Ces points de terminaison sont généralement répertoriés dans la documentation de configuration OpenID Connect de votre fournisseur. |
| Portées          | Les niveaux d'autorisation demandés lors de l'authentification qui déterminent quelles informations utilisateur sont partagées. Les portées standard comprennent `openid`, `email` et `profile`. |
| ID client       | L'identifiant unique attribué à Switchboard lorsque vous l'enregistrez en tant qu'application auprès de votre fournisseur d'identité. Vous devez d'abord créer cet enregistrement dans le tableau de bord de votre fournisseur d'identité. |
| Secret client   | La clé de sécurité confidentielle générée lors de l'enregistrement de Switchboard auprès de votre fournisseur d'identité. Ce secret authentifie Switchboard auprès de votre fournisseur d'identité (IdP) et doit être conservé en sécurité. |

GitLab fournit les informations suivantes pour que vous les configuriez dans votre fournisseur d'identité :

| Paramètre              | Description |
| ---------------------- | ----------- |
| URL de redirection/rappel | Les URL vers lesquelles votre fournisseur d'identité doit rediriger les utilisateurs après une authentification réussie. Ces URL doivent être ajoutées à la liste des URL de redirection autorisées de votre fournisseur d'identité. |
| Revendications requises        | Les informations utilisateur spécifiques qui doivent être incluses dans le contenu du jeton d'authentification. Au minimum, une revendication mappée à l'adresse e-mail de l'utilisateur est requise. |

Des détails de configuration supplémentaires peuvent être nécessaires en fonction de votre fournisseur OIDC.

### Dépannage {#troubleshooting}

Lors de la configuration du SSO SAML pour Switchboard, vous pouvez rencontrer les problèmes suivants.

#### Erreur : `Invalid SAML response received...` {#error-invalid-saml-response-received}

Cette erreur se produit car Switchboard attend des assertions SAML chiffrées, mais votre fournisseur d'identité n'est pas configuré pour les chiffrer :

```plaintext
Invalid SAML response received: Responses must contain exactly one Encrypted Assertion
```

Pour résoudre ce problème, assurez-vous que le certificat de chiffrement fourni par GitLab est importé et activé dans les paramètres de votre application IdP.

## Authentification de l'instance {#instance-authentication}

Configurez la façon dont les utilisateurs de votre organisation s'authentifient auprès de votre instance GitLab Dedicated.

Votre instance GitLab Dedicated prend en charge les méthodes d'authentification suivantes :

- [Configurer le SSO SAML](saml.md)
- [Configurer OIDC](openid_connect.md)
