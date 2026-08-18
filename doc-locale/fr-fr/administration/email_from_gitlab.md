---
stage: Facilitated functionality
group: Facilitated functionality
info: For more information, see <https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality>
description: Envoyez des notifications par e-mail à tous les utilisateurs ou à des groupes et projets spécifiques.
gitlab_dedicated: yes
title: E-mail depuis GitLab
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les administrateurs peuvent envoyer des e-mails à tous les utilisateurs, ou aux utilisateurs d'un groupe ou d'un projet choisi. Les utilisateurs reçoivent l'e-mail à leur adresse e-mail principale.

Vous pouvez utiliser cette fonctionnalité pour notifier vos utilisateurs :

- À propos d'un nouveau projet, d'une nouvelle fonctionnalité ou d'un nouveau lancement de produit.
- À propos d'un nouveau déploiement, ou du fait qu'une interruption de service est prévue.

Pour des informations sur les notifications par e-mail provenant de GitLab, consultez [les e-mails de notification GitLab](../user/profile/notifications.md).

## Envoi d'e-mails aux utilisateurs depuis GitLab {#sending-emails-to-users-from-gitlab}

Vous pouvez envoyer des notifications par e-mail à tous les utilisateurs, ou uniquement aux utilisateurs d'un groupe ou d'un projet spécifique. Vous pouvez envoyer des notifications par e-mail une fois toutes les 10 minutes.

Pour envoyer un e-mail :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Dans le coin supérieur droit, à côté du bouton **Nouvel utilisateur**, sélectionnez **Envoyer un courriel aux utilisateurs** ({{< icon name="mail" >}}).
1. Remplissez les champs. Le corps de l'e-mail ne prend en charge que le texte brut et ne prend pas en charge le HTML, Markdown ou d'autres formats de texte enrichi.
1. Dans la liste déroulante **Sélectionner un groupe ou un projet**, sélectionnez le destinataire.
1. Sélectionnez **Envoyer un message**.

## Se désabonner des e-mails {#unsubscribing-from-emails}

Les utilisateurs peuvent choisir de se désabonner des e-mails de GitLab en suivant le lien de désabonnement dans l'e-mail. Le désabonnement n'est pas authentifié afin de garder cette fonctionnalité simple.

Lors du désabonnement, les utilisateurs reçoivent une notification par e-mail indiquant que le désabonnement a eu lieu. Le point de terminaison qui fournit l'option de désabonnement est soumis à une limite de débit.
