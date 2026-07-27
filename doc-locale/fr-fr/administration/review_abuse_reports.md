---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Afficher et résoudre les rapports d'abus soumis par les utilisateurs."
gitlab_dedicated: yes
title: "Examiner les rapports d'abus"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Afficher et résoudre les rapports d'abus des utilisateurs GitLab.

Les administrateurs GitLab peuvent afficher et [résoudre](#resolving-abuse-reports) les rapports d'abus dans la zone **Admin**.

## Recevoir des notifications de rapports d'abus par e-mail {#receive-notification-of-abuse-reports-by-email}

Pour recevoir des notifications de nouveaux rapports d'abus par e-mail :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rapports**.
1. Développez la section **Rapports d'abus**.
1. Indiquez une adresse e-mail et sélectionnez **Sauvegarder les modifications**.

L'adresse e-mail de notification peut également être définie et récupérée [via l'API](../api/settings.md#available-settings).

## Signaler un abus {#reporting-abuse}

Pour en savoir plus sur le signalement des abus, consultez la [documentation utilisateur sur les rapports d'abus](../user/report_abuse.md).

## Résolution des rapports d'abus {#resolving-abuse-reports}

{{< history >}}

- **Faire confiance à l'utilisateur** [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131102) dans GitLab 16.4.

{{< /history >}}

Pour accéder aux rapports d'abus :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Rapports d'abus**.

Il existe quatre façons de résoudre un rapport d'abus, avec un bouton pour chaque méthode :

- Supprimer l'utilisateur et le rapport. Ceci :
  - [Supprime l'utilisateur signalé](../user/profile/account/delete_account.md) de l'instance.
  - Supprime le rapport d'abus de la liste.
- [Bloquer l'utilisateur](#blocking-users).
- Supprimer le rapport. Ceci :
  - Supprime le rapport d'abus de la liste.
  - Supprime les restrictions d'accès pour l'utilisateur signalé.
- Faire confiance à l'utilisateur. Ceci :
  - Permet à l'utilisateur de créer des tickets, des notes, des extraits de code et des merge requests sans être bloqué pour spam.
  - Empêche la création de rapports d'abus pour cet utilisateur.

Voici un exemple de la page **Rapports d'abus** :

![Un tableau de bord affichant des exemples de rapports d'abus soumis pour un utilisateur.](img/abuse_reports_page_v18_6.png)

### Blocage des utilisateurs {#blocking-users}

Un utilisateur bloqué ne peut pas se connecter ni accéder à des dépôts, mais toutes ses données sont conservées.

Bloquer un utilisateur :

- Le laisse dans la liste des rapports d'abus.
- Remplace le bouton **Bloquer l'utilisateur** par un bouton désactivé **Déjà bloqué**.

L'utilisateur est notifié par le message suivant :

```plaintext
Your account has been blocked. If you believe this is in error, contact a staff member.
```

Après le blocage, vous pouvez toujours :

- Supprimer l'utilisateur et le rapport si nécessaire.
- Supprimer le rapport.

## Sujets connexes {#related-topics}

- [Modérer les utilisateurs (administration)](moderate_users.md)
- [Examiner les journaux de spam](review_spam_logs.md)
