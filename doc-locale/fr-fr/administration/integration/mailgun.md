---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: Mailgun
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Lorsque vous utilisez Mailgun pour envoyer des e-mails pour votre instance GitLab et que l'intégration [Mailgun](https://www.mailgun.com/) est activée et configurée dans GitLab, vous pouvez recevoir leur webhook pour le suivi des échecs de livraison. Pour configurer l'intégration, vous devez :

1. [Configurer votre domaine Mailgun](#configure-your-mailgun-domain).
1. [Activer l'intégration Mailgun](#enable-mailgun-integration).

Une fois l'intégration terminée, les webhooks Mailgun `temporary_failure` et `permanent_failure` sont envoyés à votre instance GitLab.

## Configurer votre domaine Mailgun {#configure-your-mailgun-domain}

{{< history >}}

- [Obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/359113) : l'URL `/-/members/mailgun/permanent_failures` dans GitLab 15.0.
- [Modification](https://gitlab.com/gitlab-org/gitlab/-/issues/359113) de l'URL pour gérer les échecs temporaires et permanents dans GitLab 15.0.

{{< /history >}}

Avant de pouvoir activer Mailgun dans GitLab, configurez vos propres endpoints Mailgun pour recevoir les webhooks.

En utilisant le [guide des webhooks Mailgun](https://www.mailgun.com/blog/product/a-guide-to-using-mailguns-webhooks/) :

1. Ajoutez un webhook avec le **Type d'événement** défini sur **Échec permanent**.
1. Saisissez l'URL de votre instance et incluez le chemin `/-/mailgun/webhooks`.

   Par exemple :

   ```plaintext
   https://myinstance.gitlab.com/-/mailgun/webhooks
   ```

1. Ajoutez un autre webhook avec le **Type d'événement** défini sur **Temporary Failure**.
1. Saisissez l'URL de votre instance et utilisez le même chemin `/-/mailgun/webhooks`.

## Activer l'intégration Mailgun {#enable-mailgun-integration}

Après avoir configuré votre domaine Mailgun pour les endpoints de webhook, vous êtes prêt à activer l'intégration Mailgun :

1. Connectez-vous à GitLab en tant qu'utilisateur [Administrateur](../../user/permissions.md).
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, accédez à **Paramètres** > **Général** et développez la section **Mailgun**.
1. Cochez la case **Activer Mailgun**.
1. Saisissez la clé de signature du webhook HTTP Mailgun comme décrit dans [la documentation Mailgun](https://documentation.mailgun.com/docs/mailgun/user-manual/get-started/) et indiqué dans la section Sécurité API (`https://app.mailgun.com/app/account/security/api_keys`) de votre compte Mailgun.
1. Sélectionnez **Sauvegarder les modifications**.
