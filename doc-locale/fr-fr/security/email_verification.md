---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Vérification d'e-mail du compte"
description: "Confirmez l'identité des utilisateurs grâce à la vérification par e-mail."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Passage en disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/519123) dans GitLab 18.1. Suppression du feature flag `require_email_verification`.

{{< /history >}}

La vérification d'e-mail du compte fournit une couche de sécurité supplémentaire pour votre compte GitLab. La vérification par e-mail est requise dans les situations suivantes :

- Votre compte est [verrouillé](unlock_user.md) en raison de plusieurs tentatives de connexion échouées.
- Le mot de passe à usage unique (OTP) basé sur l'e-mail est [activé](../user/profile/account/two_factor_authentication.md#enable-email-otp) pour votre compte.
- Vous vous connectez depuis une adresse IP nouvelle ou non approuvée.

> [!note]
> Sur GitLab Self-Managed et GitLab Dedicated, cette fonctionnalité est désactivée par défaut. Utilisez l'[API des paramètres d'application](../api/settings.md) pour activer l'attribut `require_email_verification_on_account_locked`.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une démonstration, consultez [Require email verification - demo](https://www.youtube.com/watch?v=wU6BVEGB3Y0).

Pour effectuer la vérification par e-mail, connectez-vous à votre compte et saisissez le code de vérification à six chiffres envoyé à votre adresse e-mail principale. Si vous ne pouvez pas accéder à votre adresse e-mail principale, vous pouvez envoyer le code de vérification à l'une de vos adresses e-mail secondaires.

Les codes de vérification expirent après 60 minutes.

Sur GitLab.com, si vous ne recevez pas d'e-mail de vérification, sélectionnez **Resend Code** avant de contacter l'équipe d'assistance.
