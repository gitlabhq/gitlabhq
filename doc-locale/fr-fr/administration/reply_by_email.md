---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Répondre par e-mail
description: Configurez les commentaires sur les tickets et les merge requests avec des réponses par e-mail.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab peut être configuré pour permettre aux utilisateurs de commenter les tickets et les merge requests en répondant aux e-mails de notification.

## Prérequis {#prerequisite}

Assurez-vous que [les e-mails entrants](incoming_email.md) sont configurés.

## Fonctionnement des réponses par e-mail {#how-replying-by-email-works}

La réponse par e-mail se déroule en trois étapes :

1. GitLab envoie un e-mail de notification.
1. Vous répondez à l'e-mail de notification.
1. GitLab reçoit votre réponse à l'e-mail de notification.

### GitLab envoie un e-mail de notification {#gitlab-sends-a-notification-email}

Lorsque GitLab envoie un e-mail de notification :

- L'en-tête `Reply-To` est défini sur votre adresse e-mail configurée.
- Si l'adresse contient un espace réservé `%{key}`, il est remplacé par une clé de réponse spécifique.
- La clé de réponse est ajoutée à l'en-tête `References`.

### Vous répondez à l'e-mail de notification {#you-reply-to-the-notification-email}

Lorsque vous répondez à l'e-mail de notification, votre client de messagerie :

- Envoie l'e-mail à l'adresse `Reply-To` obtenue à partir de l'e-mail de notification.
- Définit l'en-tête `In-Reply-To` sur la valeur de l'en-tête `Message-ID` provenant de l'e-mail de notification.
- Définit l'en-tête `References` sur la valeur de `Message-ID` plus la valeur de l'en-tête `References` de l'e-mail de notification.

### GitLab reçoit votre réponse à l'e-mail de notification {#gitlab-receives-your-reply-to-the-notification-email}

Lorsque GitLab reçoit votre réponse, il recherche la clé de réponse dans la [liste des en-têtes acceptés](incoming_email.md#accepted-headers).

Si une clé de réponse est trouvée, votre réponse apparaît sous forme de commentaire sur le ticket, la merge request, le commit ou tout autre élément concerné qui a déclenché la notification.

Pour plus d'informations sur les en-têtes `Message-ID`, `In-Reply-To` et `References`, consultez [RFC 5322](https://www.rfc-editor.org/rfc/rfc5322#section-3.6.4).

## Politique de conservation des notifications {#retention-policy-for-notifications}

Certaines fonctionnalités d'e-mails entrants nécessitent que GitLab stocke des métadonnées sur les e-mails de notification envoyés. Nous conservons ces enregistrements pendant deux ans. Si un e-mail de notification est plus ancien que deux ans, vous ne pouvez pas y répondre par e-mail. Cela inclut les réponses par e-mail aux fils de discussion des tickets et des merge requests.
