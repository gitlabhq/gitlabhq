---
stage: Plan
group: Work Items
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Utilisateurs ayant interagi avec les éléments de travail et les merge requests GitLab, notamment les auteurs, les personnes assignées et les utilisateurs qui ont commenté, ajouté des réactions ou été mentionnés."
title: Participants
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les participants sont des utilisateurs qui ont interagi avec des éléments de travail et des merge requests. Ils incluent les auteurs, les personnes assignées, les relecteurs (pour les merge requests) et les utilisateurs qui ont commenté, ajouté des réactions emoji ou été mentionnés dans des commentaires ou des descriptions.

Les participants sont disponibles pour les éléments de travail (tels que les tickets, les tâches, les epics) et les merge requests.

## Afficher les participants {#view-participants}

### Pour les éléments de travail {#for-work-items}

Pour afficher les participants d'un élément de travail :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet ou votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Forfait** > **Éléments de travail**, puis sélectionnez votre élément de travail.
1. Dans la barre latérale droite, dans la section **Participants**, affichez tous les utilisateurs qui ont participé à l'élément de travail.

### Pour les merge requests {#for-merge-requests}

Pour afficher les participants d'une merge request :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion** et repérez votre merge request.
1. Dans la barre latérale droite, dans la section **Participants**, affichez tous les utilisateurs qui ont participé à la merge request.

## Visibilité des participants et permissions {#participant-visibility-and-permissions}

La liste des participants affiche uniquement les utilisateurs disposant des permissions nécessaires pour accéder à l'élément de travail ou à la merge request :

- **Condition de base** : les utilisateurs doivent disposer de permissions de lecture sur l'élément de travail ou la merge request pour apparaître en tant que participants.
- **Notes internes** : les utilisateurs mentionnés dans des notes internes n'apparaissent en tant que participants que s'ils disposent de la permission de lire les notes internes.
- **Les mentions ajoutent des participants** : les utilisateurs mentionnés avec `@username` ou via des mentions de groupe comme `@team-name` sont ajoutés en tant que participants s'ils ont accès à l'élément de travail ou à la merge request.

> [!warning]
> Les mentions de groupe (comme `@team-name`) ajoutent tous les membres directs du groupe en tant que participants. Faites attention lors de l'utilisation de `@` avec des mots courants, car cela peut mentionner involontairement des groupes existants.

## Participants et notifications par e-mail {#participants-and-email-notifications}

Être participant à un élément de travail ou à une merge request affecte vos paramètres de notification par e-mail. Comprendre cette relation vous aide à gérer efficacement vos préférences de notification.

Lien entre le statut de participant et les notifications :

- Participation automatique : lorsque vous commentez, modifiez ou êtes mentionné dans un élément de travail ou une merge request, vous devenez automatiquement participant. Cela peut déclencher des notifications par e-mail en fonction de vos paramètres de niveau de notification.
- Niveaux de notification : votre [niveau de notification](profile/notifications.md#notification-levels) détermine les activités qui génèrent des notifications par e-mail.
- Participants abonnés : vous pouvez manuellement [vous abonner aux notifications](profile/notifications.md#subscribe-to-notifications-for-a-specific-issue-merge-request-or-epic) pour un élément de travail ou une merge request, même si vous n'y avez pas encore participé. Cela vous ajoute à la liste des participants et active les notifications en fonction de votre niveau de notification par défaut.
- Notifications de mention : lorsque quelqu'un vous mentionne avec `@username` dans un commentaire ou une description, vous recevez une notification et devenez participant, quel que soit votre paramètre de niveau de notification.
- Contenu confidentiel : pour les éléments de travail confidentiels, seuls les utilisateurs disposant des permissions appropriées apparaissent en tant que participants et reçoivent des notifications. Pour plus d'informations, consultez [visibilité des participants et permissions](#participant-visibility-and-permissions).

Pour plus d'informations sur la gestion de vos préférences de notification, consultez [les e-mails de notification](profile/notifications.md)
