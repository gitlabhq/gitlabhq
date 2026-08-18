---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Configurer GitLab en tant que fournisseur d'identité d'authentification OAuth 2.0"
---

{{< history >}}

- La prise en charge du SSO SAML de groupe pour les applications OAuth a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/461212) dans GitLab 18.2 [avec un feature flag](../administration/feature_flags/_index.md) nommé `ff_oauth_redirect_to_sso_login`. Désactivés par défaut.
- La prise en charge du SSO SAML de groupe pour les applications OAuth a été [activée sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200682) dans GitLab 18.3.
- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/561778) dans GitLab 18.5. Feature flag `ff_oauth_redirect_to_sso_login` supprimé.

{{< /history >}}

[OAuth 2.0](https://oauth.net/2/) fournit un accès délégué et sécurisé aux ressources du serveur aux applications clientes au nom d'un propriétaire de ressource. OAuth 2 permet aux serveurs d'autorisation d'émettre des jetons d'accès à des clients tiers avec l'approbation du propriétaire de la ressource ou de l'utilisateur final.

Vous pouvez utiliser GitLab en tant que fournisseur d'identité d'authentification OAuth 2 en ajoutant les types d'applications OAuth 2 suivants à une instance :

- [Applications appartenant à l'utilisateur](#create-a-user-owned-application)
- [Applications appartenant à un groupe](#create-a-group-owned-application)
- [Applications à l'échelle de l'instance](#create-an-instance-wide-application)

Ces méthodes ne diffèrent que par le [niveau d'autorisation](../user/permissions.md). L'URL de rappel par défaut est l'URL SSL `https://your-gitlab.example.com/users/auth/gitlab/callback`. Vous pouvez utiliser une URL non SSL à la place, mais il est recommandé d'utiliser une URL SSL.

Après avoir ajouté une application OAuth 2 à une instance, vous pouvez utiliser OAuth 2 pour :

- Permettre aux utilisateurs de se connecter à votre application avec leur compte GitLab.com.
- Permettre aux utilisateurs de se connecter à votre application via [SSO SAML](../user/group/saml_sso/_index.md) lorsque SAML est configuré pour le groupe associé.
- Configurer GitLab.com pour l'authentification auprès de votre instance GitLab. Pour plus d'informations, consultez [l'intégration de votre serveur avec GitLab.com](gitlab.md).
- Une fois l'application créée, les services externes peuvent gérer les jetons d'accès via l'[API OAuth 2](../api/oauth2.md).

## Créer une application appartenant à l'utilisateur {#create-a-user-owned-application}

Pour créer une nouvelle application pour votre utilisateur :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la barre latérale gauche, sélectionnez **Accès** > **Applications**.
1. Sélectionnez **Ajouter une nouvelle application**.
1. Saisissez un **Nom** et un **Redirect URI**.
1. Sélectionnez le **Périmètre d'accès** OAuth 2 tel que défini dans [Applications autorisées](#view-all-authorized-applications).
1. Dans le champ **Redirect URI**, saisissez l'URL vers laquelle les utilisateurs sont redirigés après avoir autorisé GitLab.
1. Sélectionnez **Enregistrer l'application**. GitLab fournit :

   - L'ID client OAuth 2 dans le champ **Identifiant de l'application**.
   - Le secret client OAuth 2, accessible en sélectionnant **Copier** dans le champ **Secret**.
   - La fonction **Renouveler le secret**. Utilisez cette fonction pour générer et copier un nouveau secret pour cette application. Le renouvellement d'un secret empêche l'application existante de fonctionner jusqu'à ce que les identifiants soient mis à jour.

## Créer une application appartenant à un groupe {#create-a-group-owned-application}

Pour créer une nouvelle application pour un groupe :

1. Accédez au groupe souhaité.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Applications**.
1. Saisissez un **Nom** et un **Redirect URI**.
1. Sélectionnez les portées OAuth 2 telles que définies dans [Applications autorisées](#view-all-authorized-applications).
1. Dans le champ **Redirect URI**, saisissez l'URL vers laquelle les utilisateurs sont redirigés après avoir autorisé GitLab.
1. Sélectionnez **Enregistrer l'application**. GitLab fournit :

   - L'ID client OAuth 2 dans le champ **Identifiant de l'application**.
   - Le secret client OAuth 2, accessible en sélectionnant **Copier** dans le champ **Secret**.
   - La fonction **Renouveler le secret**. Utilisez cette fonction pour générer et copier un nouveau secret pour cette application. Le renouvellement d'un secret empêche l'application existante de fonctionner jusqu'à ce que les identifiants soient mis à jour.

## Créer une application à l'échelle de l'instance {#create-an-instance-wide-application}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Prérequis :

- Disposer d'un accès administrateur.

Pour créer une application pour votre instance GitLab :

1. dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Applications**.
1. Sélectionnez **Nouvelle application**.

Lors de la création d'une application dans la zone **Admin**, marquez-la comme **trusted**. L'étape d'autorisation de l'utilisateur est automatiquement ignorée pour cette application.

## Afficher toutes les applications autorisées {#view-all-authorized-applications}

{{< history >}}

- `k8s_proxy` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/422408) dans GitLab 16.4 [avec un feature flag](../administration/feature_flags/_index.md) nommé `k8s_proxy_pat`. Activé par défaut.
- Le feature flag `k8s_proxy_pat` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131518) dans GitLab 16.5.

{{< /history >}}

Pour consulter toutes les applications que vous avez autorisées avec vos identifiants GitLab :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la barre latérale gauche, sélectionnez **Accès** > **Applications**.
1. Consultez la section **Applications autorisées**.

Les applications OAuth 2 de GitLab prennent en charge les portées, qui permettent aux applications d'effectuer différentes actions. Consultez le tableau suivant pour connaître toutes les portées disponibles.

| Portée                    | Description |
|--------------------------|-------------|
| `api`                    | Accorde un accès complet en lecture/écriture à l'API, y compris tous les groupes et projets, le registre de conteneurs, le proxy de dépendances et le registre de paquets. |
| `read_api`               | Accorde un accès en lecture à l'API, y compris tous les groupes et projets, le registre de conteneurs et le registre de paquets. |
| `read_user`              | Accorde un accès en lecture seule au profil de l'utilisateur authentifié via le point de terminaison API `/user`, qui inclut le nom d'utilisateur, l'adresse e-mail publique et le nom complet. Accorde également l'accès aux points de terminaison API en lecture seule sous `/users`. |
| `create_runner`          | Accorde un accès de création aux runners. |
| `manage_runner`          | Accorde un accès pour gérer les runners. |
| `k8s_proxy`              | Accorde l'autorisation d'effectuer des appels API Kubernetes à l'aide de l'agent pour Kubernetes. |
| `read_repository`        | Accorde un accès en lecture seule aux dépôts des projets privés via Git-over-HTTP ou l'API Repository Files. |
| `write_repository`       | Accorde un accès en lecture-écriture aux dépôts des projets privés via Git-over-HTTP (sans utiliser l'API). |
| `read_registry`          | Accorde un accès en lecture seule aux images du registre de conteneurs sur les projets privés. |
| `write_registry`         | Accorde un accès en écriture aux images du registre de conteneurs sur les projets privés. Vous avez besoin d'un accès en lecture et en écriture pour pousser des images. |
| `read_virtual_registry`  | Accorde un accès en lecture seule aux images de conteneurs via le proxy de dépendances dans les projets privés et les registres virtuels. |
| `write_virtual_registry` | Accorde un accès en lecture, en écriture et en suppression aux images de conteneurs via le proxy de dépendances dans les projets privés. |
| `read_observability`     | Accorde un accès en lecture seule à GitLab Observability. |
| `write_observability`    | Accorde un accès en écriture à GitLab Observability. |
| `ai_features`            | Accorde l'accès aux points de terminaison API liés à GitLab Duo. |
| `sudo`                   | Accorde l'autorisation d'effectuer des actions API en tant que n'importe quel utilisateur du système, lorsque l'on est authentifié en tant qu'administrateur. |
| `admin_mode`             | Accorde l'autorisation d'effectuer des actions API en tant qu'administrateur, lorsque le mode Admin est activé. |
| `read_service_ping`      | Accorde l'accès au téléchargement des charges utiles Service Ping via l'API lorsque l'on est authentifié en tant qu'administrateur. |
| `openid`                 | Accorde l'autorisation de s'authentifier auprès de GitLab via [OpenID Connect](openid_connect_provider.md). Accorde également un accès en lecture seule au profil de l'utilisateur et aux appartenances aux groupes. |
| `profile`                | Accorde un accès en lecture seule aux données de profil de l'utilisateur via [OpenID Connect](openid_connect_provider.md). |
| `email`                  | Accorde un accès en lecture seule à l'adresse e-mail principale de l'utilisateur via [OpenID Connect](openid_connect_provider.md). |

À tout moment, vous pouvez révoquer tout accès en sélectionnant **Révoquer**.

## Expiration des jetons d'accès {#access-token-expiration}

{{< history >}}

- La durée d'expiration des jetons d'accès OAuth configurable par les administrateurs d'instance a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237354) dans GitLab 19.1.

{{< /history >}}

Par défaut, les jetons d'accès expirent après deux heures (7 200 secondes). Les intégrations qui utilisent des jetons d'accès doivent générer un nouveau jeton avec l'attribut `refresh_token`. Les jetons d'actualisation peuvent être utilisés même après l'expiration du jeton d'accès. Pour en savoir plus sur l'actualisation des jetons d'accès expirés, consultez la [documentation sur les jetons OAuth 2.0](../api/oauth2.md).

Sur GitLab Self-Managed et GitLab Dedicated, les administrateurs peuvent configurer la durée de vie des jetons. Pour plus d'informations, consultez [Modifier la durée de vie maximale des jetons d'accès OAuth](../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-oauth-access-tokens).

Lorsque des applications sont supprimées, toutes les autorisations et tous les jetons associés à l'application sont également supprimés.

## Secrets d'application OAuth hachés {#hashed-oauth-application-secrets}

Par défaut, GitLab stocke les secrets des applications OAuth dans la base de données au format haché. Ces secrets ne sont disponibles pour les utilisateurs qu'immédiatement après la création des applications OAuth. Dans les versions antérieures de GitLab, les secrets des applications sont stockés en texte brut dans la base de données.

## Autres façons d'utiliser OAuth 2 dans GitLab {#other-ways-to-use-oauth-2-in-gitlab}

Vous pouvez :

- Créer et gérer des applications OAuth 2 à l'aide de l'[API Applications](../api/applications.md).
- Permettre aux utilisateurs de se connecter à GitLab à l'aide de fournisseurs OAuth 2 tiers. Pour plus d'informations, consultez la [documentation OmniAuth](omniauth.md).
- Utilisez le GitLab Importer avec OAuth 2 pour accorder l'accès aux dépôts sans partager les identifiants de l'utilisateur de votre compte GitLab.com.
