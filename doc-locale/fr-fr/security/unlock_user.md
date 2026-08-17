---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Déverrouillez les comptes bloqués après des tentatives d'authentification échouées."
title: Comptes utilisateurs verrouillés
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Politique de verrouillage des utilisateurs configurable [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/27048) dans GitLab 16.5.

{{< /history >}}

GitLab verrouille un compte utilisateur après plusieurs tentatives d'authentification échouées. Pour déverrouiller un compte, attendez la fin de la période de déverrouillage automatique ou [réinitialisez votre mot de passe](https://gitlab.com/users/password/new).

Les situations suivantes peuvent entraîner une tentative d'authentification échouée :

- Mot de passe incorrect lors de la connexion.
- Clé d'accès incorrecte lors de la connexion.
- Mot de passe à usage unique (OTP) ou code de clé d'accès incorrect lors d'un défi d'authentification à deux facteurs (2FA).
- Mot de passe incorrect lors de la mise à jour des paramètres du profil.
- Mot de passe actuel incorrect lors du changement de mot de passe.
- Code 2FA incorrect lors de l'activation du mode administrateur.

Le comportement de verrouillage et de déverrouillage dépend de l'offre et du statut 2FA de l'utilisateur :

- Sur GitLab.com ou les instances GitLab qui utilisent la [vérification par e-mail du compte](email_verification.md) :
  - Les comptes avec la 2FA ou des identités externes (SAML, OAuth) se verrouillent après 10 tentatives échouées ou plus. Ces comptes se déverrouillent automatiquement après 10 minutes.
  - Les comptes sans 2FA ni identités externes se verrouillent après trois tentatives échouées ou plus en 24 heures. Ces comptes se déverrouillent automatiquement après 24 heures ou en confirmant l'identité par vérification par e-mail.
- Sur les instances GitLab sans vérification par e-mail du compte :
  - Tous les comptes se verrouillent après 10 tentatives échouées ou plus. Ces comptes se déverrouillent automatiquement après 10 minutes.

Sur GitLab Self-Managed et GitLab Dedicated, utilisez l'[API des paramètres d'application](../api/settings.md#update-application-settings) pour configurer les limites de verrouillage `max_login_attempts` et `failed_login_attempts_unlock_period_in_minutes`.

## Déverrouiller manuellement des comptes utilisateurs {#manually-unlock-user-accounts}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prérequis

- Accès administrateur sur l'instance.

Sur les instances GitLab Self-Managed et GitLab Dedicated, les administrateurs peuvent déverrouiller manuellement un compte avant la fin de la période de déverrouillage.

{{< tabs >}}

{{< tab title="Admin area" >}}

Pour déverrouiller un compte depuis la zone d'administration :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Utilisez la barre de recherche pour trouver l'utilisateur verrouillé.
1. Dans la liste déroulante **Administration des utilisateurs**, sélectionnez **Déverrouiller**.

L'utilisateur peut maintenant se connecter.

{{< /tab >}}

{{< tab title="Rails console" >}}

Pour déverrouiller un compte utilisateur depuis une console Rails :

1. Démarrez une [session de console Rails](../administration/operations/rails_console.md#starting-a-rails-console-session).
1. Trouvez l'utilisateur à déverrouiller :

   - Par nom d'utilisateur :

     ```ruby
     user = User.find_by_username('exampleuser')
     ```

   - Par identifiant utilisateur :

     ```ruby
     user = User.find(123)
     ```

   - Par adresse e-mail :

     ```ruby
     user = User.find_by(email: 'user@example.com')
     ```

1. Déverrouillez l'utilisateur :

   ```ruby
   user.unlock_access!
   ```

1. Quittez la console :

   ```ruby
   exit
   ```

L'utilisateur peut maintenant se connecter.

{{< /tab >}}

{{< /tabs >}}
