---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Gérer les utilisateurs de Switchboard et configurer les préférences de notification, y compris les paramètres du service de messagerie SMTP."
title: Utilisateurs et notifications GitLab Dedicated
---

{{< details >}}

- Niveau : Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

Gérez les utilisateurs qui peuvent accéder à Switchboard et configurez les notifications pour votre instance GitLab Dedicated.

Les utilisateurs de Switchboard sont distincts des utilisateurs de votre instance GitLab Dedicated.

Switchboard possède son propre système d'authentification, distinct de votre instance GitLab Dedicated. Pour plus d'informations sur la configuration de l'authentification pour les utilisateurs de votre instance GitLab Dedicated, consultez [l'authentification pour GitLab Dedicated](authentication/_index.md).

## Ajouter des utilisateurs Switchboard {#add-switchboard-users}

Les administrateurs peuvent ajouter deux types d'utilisateurs Switchboard pour gérer et consulter leur instance GitLab Dedicated :

- **Read only** :  Les utilisateurs peuvent uniquement consulter les données de l'instance.
- **Admin** :  Les utilisateurs peuvent modifier la configuration de l'instance et gérer les utilisateurs.

Pour ajouter un nouvel utilisateur à Switchboard pour votre instance GitLab Dedicated :

1. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com/).
1. En haut de la page, sélectionnez **Utilisateurs**.
1. Sélectionnez **Nouvel utilisateur**.
1. Saisissez le **Courriel** et sélectionnez un **Rôle** pour l'utilisateur.
1. Sélectionnez **Créer**.

Une invitation à utiliser Switchboard est envoyée à l'utilisateur.

## Réinitialiser votre mot de passe {#reset-your-password}

Pour réinitialiser votre mot de passe Switchboard :

1. Sur la page de connexion à Switchboard, saisissez votre adresse de courriel puis sélectionnez **Continuer**.
1. Sélectionnez **Mot de passe oublié ?**.
1. Sélectionnez **Send verification code**.
1. Vérifiez votre courriel pour obtenir le code de vérification.
1. Saisissez le code de vérification puis sélectionnez **Continuer**.
1. Saisissez et confirmez votre nouveau mot de passe.
1. Sélectionnez **Enregistrer le mot de passe**.

Une fois votre mot de passe réinitialisé, vous êtes automatiquement connecté à Switchboard. Si l'authentification multi-facteurs (MFA) est configurée pour votre compte, vous êtes invité à saisir votre code de vérification MFA.

## Réinitialiser l'authentification multi-facteurs {#reset-multi-factor-authentication}

Pour réinitialiser votre MFA pour Switchboard, [soumettez un ticket d'assistance](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650). L'équipe d'assistance vous aidera à récupérer l'accès à votre compte.

## Notifications {#notifications}

GitLab envoie des notifications concernant les incidents d'instance, la maintenance, les problèmes de performance et les mises à jour de sécurité via Switchboard.

Les notifications sont envoyées à :

- Utilisateurs Switchboard :  Utilisateurs pouvant accéder à Switchboard. Ils reçoivent des notifications en fonction de leurs paramètres de notification.
- Contacts opérationnels :  Personnes ou groupes désignés qui servent de point de communication principal pour les questions opérationnelles. Ils reçoivent des notifications pour les événements importants de l'instance et les mises à jour de service, quels que soient leurs paramètres de notification.

Les contacts opérationnels reçoivent des notifications, même si les destinataires :

- Ne sont pas des utilisateurs Switchboard.
- Ne se sont pas connectés à Switchboard.
- Désactivent les notifications.

### Gérer les adresses de courriel pour les contacts opérationnels {#manage-email-addresses-for-operational-contacts}

Ajoutez plusieurs adresses de courriel ou une liste de distribution comme contacts opérationnels.

Pour gérer les adresses de courriel pour les contacts opérationnels :

1. Connectez-vous à [Switchboard](https://console.gitlab-dedicated.com/).
1. En haut de la page, sélectionnez **Configuration**.
1. Développez **Contact information**.
1. Sous **Operational email addresses** :
   - Pour ajouter une nouvelle adresse :
     1. Sélectionnez **Ajouter une adresse de courriel**.
     1. Saisissez l'adresse de courriel.
     1. Sélectionnez **Enregistrer**.
   - Pour modifier une adresse existante :
     1. Sélectionnez le crayon ({{< icon name="pencil" >}}) en regard de l'adresse.
     1. Modifiez l'adresse de courriel.
     1. Sélectionnez **Enregistrer**.
   - Pour supprimer une adresse :
     1. Sélectionnez la corbeille ({{< icon name="remove" >}}) en regard de l'adresse.
     1. Dans la boîte de dialogue de confirmation, sélectionnez **Supprimer**.

### Gérer les paramètres de notification {#manage-notification-settings}

Les utilisateurs de Switchboard peuvent contrôler leurs paramètres de notification personnels.

Pour recevoir des notifications, vous devez d'abord :

- Recevoir une invitation et vous connecter à Switchboard.
- Configurer un mot de passe et l'authentification à deux facteurs (2FA).

Pour activer ou désactiver vos notifications personnelles :

1. Sélectionnez la liste déroulante en regard de votre nom d'utilisateur.
1. Sélectionnez **Toggle email notifications off** ou **Toggle email notifications on**.

## Service de messagerie SMTP {#smtp-email-service}

Vous pouvez configurer un service de messagerie [SMTP](../../../subscriptions/gitlab_dedicated/_index.md#email-service) pour votre instance GitLab Dedicated.

Pour configurer un service de messagerie SMTP, [soumettez un ticket d'assistance](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650) avec les identifiants et les paramètres de votre serveur SMTP.
