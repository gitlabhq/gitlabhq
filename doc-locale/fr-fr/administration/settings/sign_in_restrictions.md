---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: Restrictions de connexion
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez les restrictions de connexion pour personnaliser les restrictions d'authentification pour les interfaces Web et Git en HTTP(S).

Prérequis :

- Vous devez disposer d'un accès administrateur.

## Authentification par mot de passe et clé d'accès {#password-and-passkey-authentication}

### Autoriser l'authentification par mot de passe et clé d'accès pour l'interface Web {#allow-password-and-passkey-authentication-for-the-web-interface}

Ce paramètre est activé par défaut. Lorsqu'il est désactivé, les utilisateurs et utilisatrices ne peuvent pas utiliser l'écran de connexion standard et doivent utiliser un [fournisseur d'authentification externe](../auth/_index.md) à la place. Cela désactive également l'utilisation des clés d'accès pour l'authentification à deux facteurs.

Pour autoriser l'authentification par mot de passe et clé d'accès pour l'interface Web :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez la section **Restrictions de connexion**.
1. Cochez la case **Autoriser l'authentification par mot de passe et clé d'accès pour l'interface Web**.
1. Sélectionnez **Sauvegarder les modifications**.

> [!note]
> En cas de panne de votre fournisseur d'authentification externe, utilisez la [console GitLab Rails](../operations/rails_console.md) pour [réactiver le formulaire de connexion Web standard](#re-enable-standard-web-sign-in-form-in-rails-console). Vous pouvez également utiliser l'[API des paramètres d'application](../../api/settings.md#update-application-settings) pour configurer le paramètre `password_authentication_enabled_for_web`.

### Autoriser l'authentification par mot de passe pour Git en HTTP(S) {#allow-password-authentication-for-git-over-https}

Ce paramètre est activé par défaut. Lorsqu'il est désactivé, les utilisateurs et utilisatrices doivent s'authentifier avec un [jeton d'accès personnel](../../user/profile/personal_access_tokens.md) ou un mot de passe LDAP.

Pour autoriser l'authentification par mot de passe pour Git en HTTP(S) :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez la section **Restrictions de connexion**.
1. Cochez la case **Autoriser l'authentification par mot de passe pour Git en HTTP(S)**.
1. Sélectionnez **Sauvegarder les modifications**.

### Désactiver l'authentification par mot de passe et clé d'accès pour les utilisateurs et utilisatrices disposant d'une identité SSO {#disable-password-and-passkey-authentication-for-users-with-an-sso-identity}

Les organisations peuvent vouloir empêcher les utilisateurs et utilisatrices SSO de se connecter avec des mots de passe ou des clés d'accès, et les obliger à utiliser leur fournisseur d'authentification externe à la place. Cela restreint l'authentification par mot de passe pour l'interface Web et Git en HTTP(S), ainsi que l'authentification par clé d'accès pour l'interface Web. Les clés d'accès ne peuvent jamais être utilisées avec Git en HTTP(S).

Pour désactiver l'authentification par mot de passe et clé d'accès pour les utilisateurs et utilisatrices disposant d'une identité SSO :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez la section **Restrictions de connexion**.
1. Cochez la case **Désactiver l'authentification par mot de passe et clé d'accès pour les utilisateurs et utilisatrices disposant d'une identité SSO**.
1. Sélectionnez **Sauvegarder les modifications**.

## Authentification à deux facteurs {#two-factor-authentication}

Vous pouvez exiger que les utilisateurs et utilisatrices enregistrent une méthode d'authentification à deux facteurs (2FA) pour leur compte.

### Imposer l'authentification à deux facteurs pour tous les utilisateurs et utilisatrices {#enforce-two-factor-authentication-for-all-users}

Cela oblige tous les utilisateurs et utilisatrices, y compris les administrateurs et administratrices, à enregistrer une méthode 2FA.

Pour imposer l'authentification à deux facteurs à tous les utilisateurs et utilisatrices :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez la section **Restrictions de connexion**.
1. Cochez la case **Imposer l'authentification à deux facteurs**.
1. Facultatif. Dans **Délai de grâce des deux facteurs**, saisissez un nombre d'heures. Les utilisateurs et utilisatrices doivent enregistrer une méthode 2FA à la fin de ce délai. Définissez sur `0` pour imposer l'enregistrement à la prochaine connexion.
1. Sélectionnez **Sauvegarder les modifications**.

### Imposer l'authentification à deux facteurs pour les administrateurs et administratrices {#enforce-two-factor-authentication-for-administrators}

Cela oblige uniquement les administrateurs et administratrices à enregistrer une méthode 2FA. Cela inclut également les utilisateurs et utilisatrices disposant de [rôles d'administration personnalisés](../../user/custom_roles/_index.md).

Pour imposer l'authentification à deux facteurs aux administrateurs et administratrices :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez la section **Restrictions de connexion**.
1. Cochez la case **Imposer l'authentification à deux facteurs pour les admins**.
1. Facultatif. Dans **Délai de grâce des deux facteurs**, saisissez un nombre d'heures. Les utilisateurs et utilisatrices doivent enregistrer une méthode 2FA à la fin de ce délai. Définissez sur `0` pour imposer l'enregistrement à la prochaine connexion.
1. Sélectionnez **Sauvegarder les modifications**.

### Activer l'OTP par e-mail {#enable-email-otp}

Pour permettre aux utilisateurs et utilisatrices de configurer les [mots de passe à usage unique par e-mail](../../user/profile/account/two_factor_authentication.md#enable-email-otp) :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez la section **Restrictions de connexion**.
1. Cochez à la fois la case **Enable email-based one-time passwords** et la case **Require email verification when account is locked**.
1. Sélectionnez **Sauvegarder les modifications**.

## Mode administrateur {#admin-mode}

Si vous êtes administrateur ou administratrice, vous pourriez vouloir travailler dans GitLab sans accès administrateur. Vous pouvez soit créer un compte utilisateur distinct sans accès administrateur, soit utiliser le Mode administrateur.

Avec le Mode administrateur, votre compte ne dispose pas d'un accès administrateur par défaut. Vous pouvez continuer à accéder aux groupes et aux projets dont vous êtes membre. Cependant, pour les tâches administratives, vous devez vous authentifier (sauf pour [certaines fonctionnalités](#known-issues)).

Lorsque le Mode administrateur est activé, il s'applique à tous les administrateurs et administratrices de l'instance.

Lorsque le Mode administrateur est activé pour une instance, les administrateurs et administratrices :

- Sont autorisés à accéder aux groupes et aux projets dont ils sont membres.
- Ne peuvent pas accéder à la zone **Admin**.

### Activer le Mode administrateur pour votre instance {#enable-admin-mode-for-your-instance}

Les administrateurs et administratrices peuvent activer le Mode administrateur via l'API, la console Rails ou l'interface utilisateur.

#### Utiliser l'API pour activer le Mode administrateur {#use-the-api-to-enable-admin-mode}

Effectuez la requête suivante vers le point de terminaison de votre instance :

```shell
curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab.example.com>/api/v4/application/settings?admin_mode=true"
```

Remplacez `<gitlab.example.com>` par l'URL de votre instance.

Pour plus d'informations, consultez la [liste des paramètres accessibles via les appels API](../../api/settings.md).

#### Utiliser la console Rails pour activer le Mode administrateur {#use-the-rails-console-to-enable-admin-mode}

{{< details >}}

- Offre :  GitLab Self-Managed

{{< /details >}}

Ouvrez la [console Rails](../operations/rails_console.md) et exécutez la commande suivante :

```ruby
::Gitlab::CurrentSettings.update!(admin_mode: true)
```

#### Utiliser l'interface utilisateur pour activer le Mode administrateur {#use-the-ui-to-enable-admin-mode}

Pour activer le Mode administrateur via l'interface utilisateur :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Restrictions de connexion**.
1. Sélectionnez **Passer en mode Administrateur**.
1. Sélectionnez **Sauvegarder les modifications**.

### Activer le Mode administrateur pour votre session {#turn-on-admin-mode-for-your-session}

Pour activer le Mode administrateur pour votre session actuelle et accéder à des ressources potentiellement dangereuses :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Passer en mode administrateur**.
1. Essayez d'accéder à n'importe quelle partie de l'interface utilisateur avec `/admin` dans l'URL (ce qui nécessite un accès administrateur).

Lorsque le statut du Mode administrateur est désactivé ou éteint, les administrateurs et administratrices ne peuvent pas accéder aux ressources à moins qu'un accès leur ait été explicitement accordé. Par exemple, les administrateurs et administratrices reçoivent une erreur `404` s'ils tentent d'ouvrir un groupe ou un projet privé, à moins qu'ils n'en soient membres.

La 2FA doit être activée pour les administrateurs et administratrices. La 2FA, les fournisseurs OmniAuth et l'authentification LDAP sont pris en charge par le Mode administrateur. Le statut du Mode administrateur est stocké dans la session utilisateur actuelle et reste actif jusqu'à ce que l'une des conditions suivantes soit remplie :

- Il est explicitement désactivé.
- Il est désactivé automatiquement après six heures.

### Vérifier si votre session a le Mode administrateur activé {#check-if-your-session-has-admin-mode-enabled}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/438674) dans GitLab 16.10 [avec un indicateur](../feature_flags/_index.md) nommé `show_admin_mode_within_active_sessions`. Désactivé par défaut.
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/444188) dans GitLab 16.10.
- [Disponible de manière générale](https://gitlab.com/gitlab-org/gitlab/-/issues/438674) dans GitLab 17.0. Indicateur de feature flag `show_admin_mode_within_active_sessions` supprimé.

{{< /history >}}

Accédez à votre liste de sessions actives :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Modifier le profil**.
1. Dans la barre latérale gauche, sélectionnez **Accès** > **Sessions actives**.

Les sessions pour lesquelles le Mode administrateur est activé affichent le texte **Connecté(e) le `date of session` avec le Mode administrateur**.

### Désactiver le Mode administrateur pour votre session {#turn-off-admin-mode-for-your-session}

Pour désactiver le Mode administrateur pour votre session actuelle :

1. Dans le coin supérieur droit, sélectionnez votre avatar.
1. Sélectionnez **Quitter le mode administrateur**.

### Problèmes connus {#known-issues}

Le Mode administrateur expire après six heures et vous ne pouvez pas modifier cette limite de délai d'expiration.

Les méthodes d'accès suivantes ne sont pas protégées par le Mode administrateur :

- Accès client Git (SSH utilisant des clés publiques ou HTTPS utilisant des jetons d'accès personnels).

En d'autres termes, les administrateurs et administratrices autrement limités par le Mode administrateur peuvent tout de même utiliser les clients Git sans étapes d'authentification supplémentaires.

Pour utiliser l'API REST ou GraphQL de GitLab, les administrateurs et administratrices doivent [créer un jeton d'accès personnel](../../user/profile/personal_access_tokens.md#create-a-personal-access-token) ou un [jeton OAuth](../../api/oauth2.md) avec la [portée `admin_mode`](../../user/profile/personal_access_tokens.md#personal-access-token-scopes).

Si un administrateur ou une administratrice disposant d'un jeton d'accès personnel avec la portée `admin_mode` perd son accès administrateur, cet utilisateur ou cette utilisatrice ne peut pas accéder à l'API en tant qu'administrateur ou administratrice même s'il ou elle possède toujours le jeton avec la portée `admin_mode`. Pour plus d'informations, consultez l'[epic 2158](https://gitlab.com/groups/gitlab-org/-/epics/2158).

De plus, lorsque GitLab Geo est activé, vous ne pouvez pas afficher le statut de réplication des projets et des designs sur un nœud secondaire. Un correctif est proposé lorsque les projets ([ticket 367926](https://gitlab.com/gitlab-org/gitlab/-/issues/367926) ) et les designs ([ticket 355660](https://gitlab.com/gitlab-org/gitlab/-/issues/355660)) migrent vers le nouveau framework Geo.

### Dépannage du Mode administrateur {#troubleshooting-admin-mode}

Si nécessaire, vous pouvez désactiver le **Mode administrateur** en tant qu'administrateur ou administratrice en utilisant l'une de ces deux méthodes :

- API :

  ```shell
  curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab-url>/api/v4/application/settings?admin_mode=false"
  ```

- [Console Rails](../operations/rails_console.md#starting-a-rails-console-session) :

  ```ruby
  ::Gitlab::CurrentSettings.update!(admin_mode: false)
  ```

## Notification par e-mail pour les connexions inconnues {#email-notification-for-unknown-sign-ins}

Lorsqu'il est activé, GitLab notifie les utilisateurs et utilisatrices des connexions provenant d'adresses IP ou d'appareils inconnus. Pour plus d'informations, consultez [Notification par e-mail pour les connexions inconnues](../../user/profile/notifications.md#notifications-for-unknown-sign-ins).

![Notifications par e-mail activées pour les connexions inconnues.](img/email_notification_for_unknown_sign_ins_v13_2.png)

## Informations de connexion {#sign-in-information}

{{< history >}}

- Le paramètre **Sign-in text** est [obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/410885) dans GitLab 17.0.

{{< /history >}}

Tous les utilisateurs et utilisatrices non connectés sont redirigés vers la page représentée par l'**URL de la page d'accueil** configurée si la valeur n'est pas vide.

Tous les utilisateurs et utilisatrices sont redirigés vers la page représentée par l'**URL de la page de déconnexion** configurée après la déconnexion si la valeur n'est pas vide.

Pour ajouter un message d'aide à la page de connexion, [personnalisez vos pages de connexion et d'inscription](../appearance.md#customize-your-sign-in-and-register-pages).

## Dépannage {#troubleshooting}

### Réactiver le formulaire de connexion Web standard dans la console Rails {#re-enable-standard-web-sign-in-form-in-rails-console}

{{< details >}}

- Offre :  GitLab Self-Managed

{{< /details >}}

Réactivez le formulaire de connexion standard basé sur le nom d'utilisateur et le mot de passe s'il a été désactivé en tant que [restriction de connexion](#password-and-passkey-authentication).

Vous pouvez utiliser cette méthode via la [console Rails](../operations/rails_console.md#starting-a-rails-console-session) lorsqu'un fournisseur d'authentification externe configuré (via SSO ou une configuration LDAP) est confronté à une panne et qu'un accès direct à GitLab est requis.

```ruby
Gitlab::CurrentSettings.update!(password_authentication_enabled_for_web: true)
```
